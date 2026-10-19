import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/model.dart'
    show ChangeKinds, ChangeSummary, RowOp, SheetsTables, SpreadsheetCols;

import '../../platform/activity/activity_service.dart';
import '../../platform/comments/comment_service.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/drive/drive_events.dart';
import '../../platform/drive/drive_service.dart';
import '../../platform/drive/drive_user_state.dart';
import '../../platform/revlog/rev_hooks.dart';
import '../../platform/sharing/access_service.dart';
import '../../platform/storage/content_sizes.dart';
import '../../platform/versions/version_service.dart';
import '../scripts/script_service.dart';
import '../scripts/script_triggers.dart';

/// The durable post-commit hooks of spreadsheets (RevLog spec 05 §6.2),
/// replacing `ChangeLogConsumer` and its plugins.
abstract final class SheetsHooks {
  /// In run order.
  static final List<RevHook> all = [
    _Activity(),
    _Versions(),
    _DriveEdit(),
    _Title(),
    _Modified(),
    _CellHistory(),
    _Comments(),
    _Scripts(),
    _ContentSize(),
  ];

  /// Cell history entries kept per cell.
  static const maxHistoryPerCell = 100;
}

/// Ops by author (user_profile id), skipping system ops without one.
Map<int, List<RevOpRecord>> _byAuthor(List<RevOpRecord> ops) {
  final out = <int, List<RevOpRecord>>{};
  for (final o in ops) {
    final id = o.op.authorId;
    if (id != null) (out[id] ??= []).add(o);
  }
  return out;
}

List<Map<String, Object?>> _detailCells(String? json) {
  if (json == null) return const [];
  try {
    final value = jsonDecode(json);
    if (value is Map && value['cells'] is List) {
      return [
        for (final c in value['cells'] as List)
          if (c is Map) c.cast<String, Object?>(),
      ];
    }
  } on FormatException {
    // Ignore malformed details.
  }
  return const [];
}

final class _Activity extends RevHook {
  @override
  String get id => 'activity';

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    for (final MapEntry(key: userId, value: mine) in _byAuthor(ops).entries) {
      final last = mine.last.op;
      await ActivityService.logEdit(
        ctx.session,
        item.id!,
        Actor(
          userId: userId,
          authUserId: last.authorUuid!,
          kind: last.actorKind,
          sessionId: last.sessionId,
        ),
        counters: {
          'changes': mine.length,
          'cells': mine.fold(
            0,
            (n, o) => n + _detailCells(o.op.detailJson).length,
          ),
        },
      );
    }
  }
}

final class _Versions extends RevHook {
  @override
  String get id => 'versions';

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    for (final userId in _byAuthor(ops).keys) {
      await VersionService.recordEdit(ctx.session, item, userId);
    }
  }
}

final class _DriveEdit extends RevHook {
  @override
  String get id => 'driveEdit';

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    for (final userId in _byAuthor(ops).keys) {
      await DriveUserStates.recordEdit(ctx.session, userId, item);
    }
  }
}

/// `spreadsheet.title` → `DriveItem.name` when an op wrote the title.
final class _Title extends RevHook {
  @override
  String get id => 'title';

  @override
  bool wants(RevOpRecord op) =>
      op.op.actorKind != ActorKind.system &&
      op.applied.any(
        (c) =>
            c.table == SheetsTables.spreadsheet &&
            c.op != RowOp.delete &&
            c.columnsAfter.containsKey(SpreadsheetCols.title),
      );

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    String? title;
    for (final o in ops) {
      for (final c in o.applied) {
        if (c.table == SheetsTables.spreadsheet &&
            c.columnsAfter.containsKey(SpreadsheetCols.title)) {
          title = c.columnsAfter[SpreadsheetCols.title] as String?;
        }
      }
    }
    title = title?.trim();
    if (title == null ||
        title.isEmpty ||
        title.length > 255 ||
        title.contains('/')) {
      return;
    }
    final current = await DriveItem.db.findById(ctx.session, item.id!);
    if (current == null || current.name == title) return;
    final updated = await DriveItem.db.updateRow(
      ctx.session,
      current.copyWith(name: title),
      columns: (t) => [t.name],
    );
    await DriveEvents.notify(ctx.session, updated, DriveChangeKind.updated);
  }
}

/// `modifiedAt` and search text (sheet names, text and numbers of up to
/// 10,000 cells, read sheet by sheet), at most every 10 s per file.
final class _Modified extends RevHook {
  @override
  String get id => 'modified';

  @override
  Duration get minInterval => const Duration(seconds: 10);

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    final userId = ops.reversed
        .map((o) => o.op.authorId)
        .firstWhere((id) => id != null, orElse: () => null);
    final s = ctx.session;
    final sheets = await s.db.unsafeQuery(
      'SELECT id::text, name FROM sheet WHERE "fileId" = @f ORDER BY "sortKey"',
      parameters: QueryParameters.named({'f': ctx.file.id}),
    );
    final text = StringBuffer()..writeAll(sheets.map((r) => r[1]), ' ');
    var left = 10000;
    for (final sheet in sheets) {
      if (left <= 0) break;
      final cells = await s.db.unsafeQuery(
        'SELECT content FROM cell WHERE "sheetId" = @s::uuid '
        "AND (content LIKE 's:%' OR content LIKE 'n:%') LIMIT @n",
        parameters: QueryParameters.named({'s': sheet[0], 'n': left}),
      );
      left -= cells.length;
      for (final c in cells) {
        text
          ..write(' ')
          ..write((c[0]! as String).substring(2));
      }
    }
    final searchText = text.toString();
    final fresh = await DriveItem.db.findById(s, item.id!);
    if (fresh == null) return;
    await DriveService.touchModified(
      s,
      fresh,
      userId ?? fresh.ownerId,
      searchText: searchText.length > 100000
          ? searchText.substring(0, 100000)
          : searchText,
    );
  }
}

/// Cell value history from the ops' detail (one insert per op, one trim).
final class _CellHistory extends RevHook {
  @override
  String get id => 'cellHistory';

  @override
  bool wants(RevOpRecord op) => op.op.detailJson != null;

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final fileUuid = ctx.file.fileUuid.uuid;
    final touched = <(String, String, String)>{};
    for (final o in ops) {
      final cells = _detailCells(o.op.detailJson);
      final author = o.op.authorUuid;
      if (cells.isEmpty || author == null) continue;
      final rows = <Map<String, Object?>>[];
      for (final c in cells) {
        final s = c['s'] ?? c['sheetId'];
        final r = c['r'] ?? c['rowId'];
        final col = c['c'] ?? c['colId'];
        if (s is! String || r is! String || col is! String) continue;
        if (!_isUuid(s) || !_isUuid(r) || !_isUuid(col)) continue;
        rows.add({
          's': s,
          'r': r,
          'c': col,
          'b': c['b'] ?? c['before'],
          'a': c['a'] ?? c['after'],
        });
        touched.add((s, r, col));
      }
      if (rows.isEmpty) continue;
      await ctx.session.db.unsafeExecute(
        r'''
        INSERT INTO cell_history ("fileUuid", "sheetId", "rowId", "colId",
          revision, "userUuid", "actorKind", label, at, before, after)
        SELECT @f::uuid, x.s, x.r, x.c, @rev, @u::uuid, @k, @l, @at, x.b, x.a
        FROM jsonb_to_recordset(@rows::jsonb) AS x(s uuid, r uuid, c uuid, b text, a text)
        ON CONFLICT ("fileUuid", revision, "rowId", "colId") DO NOTHING
        ''',
        parameters: QueryParameters.named({
          'f': fileUuid,
          'rev': o.revision,
          'u': author.uuid,
          'k': o.op.actorKind.name,
          'l': o.op.label,
          'at': o.op.committedAt,
          'rows': jsonEncode(rows),
        }),
      );
    }
    if (touched.isEmpty) return;
    // Keep the latest entries per touched cell, in one statement.
    await ctx.session.db.unsafeExecute(
      r'''
      DELETE FROM cell_history h USING (
        SELECT id FROM (
          SELECT ch.id, row_number() OVER (
            PARTITION BY ch."sheetId", ch."rowId", ch."colId" ORDER BY ch.at DESC
          ) AS n
          FROM cell_history ch
          JOIN jsonb_to_recordset(@cells::jsonb) AS x(s uuid, r uuid, c uuid)
            ON ch."sheetId" = x.s AND ch."rowId" = x.r AND ch."colId" = x.c
          WHERE ch."fileUuid" = @f::uuid
        ) ranked WHERE n > @keep
      ) old WHERE h.id = old.id
      ''',
      parameters: QueryParameters.named({
        'f': fileUuid,
        'keep': SheetsHooks.maxHistoryPerCell,
        'cells': jsonEncode([
          for (final (s, r, c) in touched) {'s': s, 'r': r, 'c': c},
        ]),
      }),
    );
  }

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool _isUuid(String s) => _uuid.hasMatch(s);
}

/// Orphans comment threads anchored to deleted rows/columns/sheets and
/// revives them when the ids come back (Sheets 10 §3.2).
final class _Comments extends RevHook {
  @override
  String get id => 'comments';

  @override
  bool wants(RevOpRecord op) {
    final s = op.summary;
    return s['deleted'] != null || s['revived'] != null;
  }

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    final threads = await CommentThread.db.find(
      ctx.session,
      where: (t) => t.itemId.equals(item.id!),
    );
    if (threads.isEmpty) return;
    for (final o in ops) {
      final summary = ChangeSummary.parse(o.op.summaryJson ?? '{}');
      final deleted = {
        for (final kind in const ['rows', 'cols', 'sheets'])
          for (final id in summary.deleted[kind] ?? const <String>[]) id: kind,
      };
      final revived = {
        for (final kind in const ['rows', 'cols', 'sheets'])
          ...?summary.revived[kind],
      };
      for (final thread in threads) {
        final anchor = thread.anchorJson;
        if (thread.status == CommentStatus.orphaned) {
          final reason = thread.orphanReasonJson ?? '';
          if (revived.any(reason.contains)) {
            await CommentService.revive(ctx.session, thread, item);
          }
          continue;
        }
        for (final entry in deleted.entries) {
          if (!anchor.contains(entry.key)) continue;
          await CommentService.orphan(
            ctx.session,
            thread,
            item,
            reason: {
              'kind': switch (entry.value) {
                'rows' => 'row',
                'cols' => 'column',
                _ => 'sheet',
              },
              'id': entry.key,
              'revision': o.revision,
            },
          );
          break;
        }
      }
    }
  }
}

/// Compiles projects whose files changed and fires installable edit/change
/// triggers (09 §8.7.3, §9.1), skipping script and system ops.
final class _Scripts extends RevHook {
  @override
  String get id => 'scripts';

  @override
  bool wants(RevOpRecord op) =>
      ScriptTriggerService.enabled &&
      op.op.actorKind != ActorKind.system &&
      op.op.actorKind != ActorKind.script;

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    final s = ctx.session;
    for (final o in ops) {
      final summary = ChangeSummary.parse(o.op.summaryJson ?? '{}');
      final authorId = o.op.authorId;
      if (summary.kinds.contains(ChangeKinds.scripts) && authorId != null) {
        try {
          final role = await AccessService.effectiveRole(s, authorId, item);
          if (role != null && role >= Role.editor) {
            await ScriptService.compile(
              s,
              Actor(userId: authorId, authUserId: o.op.authorUuid!),
              item.uuid,
            );
          }
        } on Exception catch (e) {
          s.log(
            'Script compile after an edit failed: $e',
            level: LogLevel.info,
          );
        }
      }
      await ScriptTriggerService.fireForChange(
        s,
        item,
        summaryJson: o.op.summaryJson ?? '{}',
        actorKind: o.op.actorKind,
        offline: o.op.offline,
      );
    }
  }
}

final class _ContentSize extends RevHook {
  @override
  String get id => 'contentSize';

  @override
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops) async {
    final item = ctx.item;
    if (item == null) return;
    await ContentSizes.onSpaceChanged(ctx.session, item);
  }
}
