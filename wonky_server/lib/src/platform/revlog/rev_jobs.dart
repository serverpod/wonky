import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import 'rev_binding.dart';
import 'rev_hooks.dart';
import 'rev_sql.dart';

/// RevLog maintenance jobs (RevLog spec 05 §10).
abstract final class RevJobs {
  /// Ops keep their payload this long (`opRetentionDays`).
  static Duration opRetention = const Duration(days: 30);

  /// Slim op rows (idempotency) are kept this long (`opTombstoneDays`).
  static Duration opTombstone = const Duration(days: 365);

  /// Time budget of one prune run.
  static Duration pruneBudget = const Duration(seconds: 60);

  /// `revlog.hookSweep` (every 5 min): kicks files whose hook cursors lag
  /// the head or whose retry is due. Returns the number of files kicked.
  static Future<int> hookSweep(Session session) async {
    final rows = await session.db.unsafeQuery(
      r'''
      SELECT h."fileId", f."headRevision", h."cursorsJson", f.kind
      FROM rev_hook_state h JOIN rev_file f ON f.id = h."fileId"
      WHERE NOT f.purging
        AND (h."nextAttemptAt" IS NULL OR h."nextAttemptAt" <= now())
        AND (h."leaseUntil" IS NULL OR h."leaseUntil" < now())
        AND f."updatedAt" > now() - interval '30 days'
      LIMIT 2000
      ''',
    );
    var kicked = 0;
    for (final r in rows) {
      final binding =
          RevHooks.bindings[RevFileKind.values.byName(r[3]! as String)];
      if (binding == null) continue;
      final head = r[1]! as int;
      final cursors = (jsonDecode(r[2]! as String) as Map).values;
      final lowest = cursors.isEmpty
          ? head
          : cursors.map((v) => (v as num).toInt()).reduce(min);
      final known = {for (final h in binding.hooks) h.id};
      final missing = known.any(
        (id) => !(jsonDecode(r[2]! as String) as Map).containsKey(id),
      );
      if (lowest >= head && !missing) continue;
      RevHooks.kick(session.serverpod, binding, r[0]! as int);
      kicked++;
    }
    return kicked;
  }

  /// `revlog.pruneOps` (daily): drops the payloads of ops older than
  /// [opRetention] that no unexpired server change record references and
  /// advances `prunedBelow`; deletes slim rows older than [opTombstone].
  /// Batches of 10,000 within [pruneBudget].
  static Future<int> pruneOps(Session session) async {
    final started = clock.now();
    final cutoff = started.toUtc().subtract(opRetention);
    var pruned = 0;
    while (clock.now().difference(started) < pruneBudget) {
      final n = await session.db.unsafeExecute(
        r'''
        UPDATE rev_op SET payload = NULL, "summaryJson" = NULL,
          "detailJson" = NULL, "outcomeJson" = NULL
        WHERE id IN (
          SELECT o.id FROM rev_op o
          WHERE o."committedAt" < @cutoff AND o.payload IS NOT NULL
            AND (o."recordId" IS NULL OR NOT EXISTS (
              SELECT 1 FROM server_change_record r
              WHERE r."recordId" = o."recordId" AND r."expiresAt" > now()))
          LIMIT 10000)
        ''',
        parameters: QueryParameters.named({'cutoff': cutoff}),
      );
      pruned += n;
      if (n < 10000) break;
    }
    // The first revision of each file that still holds a payload.
    await session.db.unsafeExecute(r'''
      UPDATE rev_file f SET "prunedBelow" = x.first
      FROM (
        SELECT "fileId", min(revision) FILTER (WHERE payload IS NOT NULL) AS keep,
               max(revision) AS last
        FROM rev_op GROUP BY "fileId"
      ) y, LATERAL (SELECT coalesce(y.keep, y.last + 1) AS first) x
      WHERE f.id = y."fileId" AND f."prunedBelow" < x.first
      ''');
    final tombstone = started.toUtc().subtract(opTombstone);
    while (clock.now().difference(started) < pruneBudget) {
      final n = await session.db.unsafeExecute(
        'DELETE FROM rev_op WHERE id IN (SELECT id FROM rev_op '
        'WHERE "committedAt" < @t AND payload IS NULL LIMIT 10000)',
        parameters: QueryParameters.named({'t': tombstone}),
      );
      if (n < 10000) break;
    }
    return pruned;
  }

  /// `revlog.repairStats` (weekly): recomputes the per-table row counts of
  /// files changed in the last [since] (cells sheet by sheet). Returns the
  /// number of files repaired.
  static Future<int> repairStats(
    Session session, {
    Duration since = const Duration(days: 8),
  }) async {
    final files = await RevFile.db.find(
      session,
      where: (t) =>
          (t.updatedAt > clock.now().toUtc().subtract(since)) &
          t.purging.equals(false),
    );
    var repaired = 0;
    for (final f in files) {
      final binding = RevHooks.bindings[f.kind];
      if (binding == null) continue;
      final stats = RevStats.parse(f.stats);
      final counts = <String, int>{};
      for (final t in binding.schema.tables) {
        if (binding.perSheetTables.contains(t.name)) {
          final scopes = await binding.perSheetScopes(session, f.id!);
          var n = 0;
          for (final MapEntry(key: col, value: values) in scopes.entries) {
            if (values.isEmpty) continue;
            final r = await session.db.unsafeQuery(
              'SELECT count(*) FROM ${RevSql.q(t.name)} '
              'WHERE ${RevSql.q(col)} = ANY(@v::uuid[])',
              parameters: QueryParameters.named({'v': values}),
            );
            n += r.first[0]! as int;
          }
          counts[t.name] = n;
        } else {
          final r = await session.db.unsafeQuery(
            'SELECT count(*) FROM ${RevSql.q(t.name)} WHERE "fileId" = @f',
            parameters: QueryParameters.named({'f': f.id}),
          );
          counts[t.name] = r.first[0]! as int;
        }
      }
      if (const _MapEq().equals(counts, stats.tables)) continue;
      await session.db.unsafeExecute(
        'UPDATE rev_file SET stats = @s WHERE id = @f',
        parameters: QueryParameters.named({
          's': RevStats(tables: counts, extra: stats.extra).encode(),
          'f': f.id,
        }),
      );
      repaired++;
    }
    return repaired;
  }
}

final class _MapEq {
  const _MapEq();

  bool equals(Map<String, int> a, Map<String, int> b) {
    final keys = {...a.keys, ...b.keys};
    return keys.every((k) => (a[k] ?? 0) == (b[k] ?? 0));
  }
}
