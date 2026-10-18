import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../activity/activity_service.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../sharing/access_service.dart';
import '../users/user_service.dart';

/// What a [VersionProvider] stored for a captured version.
class CapturedVersion {
  const CapturedVersion({
    required this.storageKind,
    this.revision,
    this.snapshotFileId,
    this.sizeBytes = 0,
    this.index,
  });

  final VersionStorage storageKind;
  final int? revision;
  final UuidValue? snapshotFileId;
  final int sizeBytes;

  /// Provider data computed during the capture for
  /// [VersionProvider.afterCapture] (e.g. per-sheet counts), so it never
  /// re-reads what it just stored.
  final Object? index;
}

/// Result of a provider restore.
class RestoredVersion {
  const RestoredVersion({this.revision, this.changeId});
  final int? revision;
  final UuidValue? changeId;
}

/// Per-app version support (specs/07 §5): capture, restore, discard.
abstract interface class VersionProvider {
  DriveItemKind get kind;

  /// Called before the capture state is read: writes edit bookkeeping that
  /// is still pending (Write batches it), so the version's authors and the
  /// dirty flag match what [capture] stores.
  Future<void> beforeCapture(Session session, DriveItem item);

  /// Captures the current state of [item].
  Future<CapturedVersion> capture(Session session, DriveItem item);

  /// Applies [version] to [item] as a normal forward edit by [actor].
  Future<RestoredVersion> restore(
    Session session,
    Actor actor,
    DriveItem item,
    ItemVersion version,
  );

  /// Called when a version is deleted by thinning (free storage).
  Future<void> discard(Session session, ItemVersion version);

  /// Called after a version row was inserted (indexes, snapshots), with
  /// what [capture] returned.
  Future<void> afterCapture(
    Session session,
    DriveItem item,
    ItemVersion version,
    CapturedVersion captured,
  );
}

/// The version framework shared by both apps (specs/07 §5).
abstract final class VersionService {
  /// Auto version after this much inactivity following edits.
  static const idleBeforeCapture = Duration(minutes: 5);

  /// At most one auto version per this period of continuous editing.
  static const maxContinuous = Duration(minutes: 30);

  /// A capture claim older than this is taken over (a crashed run); a
  /// failed capture is retried after it.
  static const claimTimeout = Duration(minutes: 10);

  /// Captures per [captureDue] run.
  static const maxCapturesPerRun = 200;

  static final Map<DriveItemKind, VersionProvider> _providers = {};

  static void register(VersionProvider provider) =>
      _providers[provider.kind] = provider;

  static VersionProvider providerFor(DriveItem item) {
    final provider = _providers[item.kind];
    if (provider == null) {
      throw Errors.invalid('This item has no version history.');
    }
    return provider;
  }

  /// Records an edit for the capture policy.
  static Future<void> recordEdit(
    Session session,
    DriveItem item,
    int userId, {
    int? revision,
  }) => recordEdits(session, item, {userId}, revision: revision);

  /// Records edits by [userIds] for the capture policy in one atomic
  /// upsert: concurrent recorders (instances, hooks, a capture clearing the
  /// state) never lose an editor or revert the dirty flag.
  static Future<void> recordEdits(
    Session session,
    DriveItem item,
    Set<int> userIds, {
    int? revision,
  }) async {
    if (userIds.isEmpty) return;
    await session.db.unsafeExecute(
      r'''
      INSERT INTO item_version_state
        ("itemId", "lastEditAt", "dirtySince", "editorsSinceLastVersion",
         "lastRevision")
      VALUES (@item, @now, @now, @editors::json, @revision)
      ON CONFLICT ("itemId") DO UPDATE SET
        "lastEditAt" = GREATEST(item_version_state."lastEditAt",
                                EXCLUDED."lastEditAt"),
        "dirtySince" = COALESCE(item_version_state."dirtySince",
                                EXCLUDED."dirtySince"),
        "editorsSinceLastVersion" = (
          SELECT COALESCE(json_agg(u.e ORDER BY u.o), '[]'::json) FROM (
            SELECT x.e, min(x.o) AS o FROM (
              SELECT a.v::bigint AS e, a.n AS o
              FROM json_array_elements_text(
                item_version_state."editorsSinceLastVersion")
                WITH ORDINALITY AS a(v, n)
              UNION ALL
              SELECT b.v::bigint, 1000000 + b.n
              FROM json_array_elements_text(
                EXCLUDED."editorsSinceLastVersion")
                WITH ORDINALITY AS b(v, n)
            ) x GROUP BY x.e
          ) u),
        "lastRevision" = COALESCE(EXCLUDED."lastRevision",
                                  item_version_state."lastRevision")
      ''',
      parameters: QueryParameters.named({
        'item': item.id!,
        'now': nowUtc(),
        'editors': jsonEncode(userIds.toList()),
        'revision': revision,
      }),
    );
  }

  /// Captures a version of [item] now.
  ///
  /// The capture state is read before the provider captures, and the dirty
  /// flag is cleared only when no edit was recorded meanwhile (`lastEditAt`
  /// unchanged); otherwise the item stays dirty from the capture's start,
  /// so those edits get their own version.
  static Future<ItemVersion> capture(
    Session session,
    DriveItem item, {
    required VersionKind kind,
    String? name,
    int? createdById,
  }) async {
    final provider = providerFor(item);
    await provider.beforeCapture(session, item);
    final started = nowUtc();
    final state = await ItemVersionState.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(item.id!),
    );
    final captured = await provider.capture(session, item);
    final now = nowUtc();
    final version = await ItemVersion.db.insertRow(
      session,
      ItemVersion(
        itemId: item.id!,
        kind: kind,
        name: name,
        createdAt: now,
        createdById: createdById,
        authors: state?.editorsSinceLastVersion ?? const [],
        storageKind: captured.storageKind,
        revision: captured.revision,
        snapshotFileId: captured.snapshotFileId,
        sizeBytes: captured.sizeBytes,
      ),
    );
    if (state != null) {
      final cleared = await ItemVersionState.db.updateWhere(
        session,
        columnValues: (t) => [
          t.dirtySince(null),
          t.editorsSinceLastVersion(const []),
          t.lastVersionAt(now),
          t.capturingSince(null),
        ],
        where: (t) =>
            t.id.equals(state.id!) & t.lastEditAt.equals(state.lastEditAt),
      );
      if (cleared.isEmpty) {
        // Edited during the capture: still dirty, counted from its start.
        await ItemVersionState.db.updateWhere(
          session,
          columnValues: (t) => [
            t.dirtySince(started),
            t.lastVersionAt(now),
            t.capturingSince(null),
          ],
          where: (t) => t.id.equals(state.id!),
        );
      }
    } else {
      try {
        await ItemVersionState.db.insertRow(
          session,
          ItemVersionState(
            itemId: item.id!,
            lastEditAt: now,
            lastVersionAt: now,
            editorsSinceLastVersion: const [],
          ),
        );
      } on DatabaseException {
        // Edited meanwhile: the recorded edit keeps the item dirty.
      }
    }
    await provider.afterCapture(session, item, version, captured);
    return version;
  }

  // ---------------------------------------------------------------- views

  static Future<List<ItemVersionView>> viewsOf(
    Session session,
    DriveItem item,
    List<ItemVersion> versions,
  ) async {
    final users = await UserService.summaries(session, [
      for (final v in versions) ...v.authors,
    ]);
    return [
      for (final v in versions)
        ItemVersionView(
          id: v.id!,
          itemUuid: item.uuid,
          kind: v.kind,
          name: v.name,
          createdAt: v.createdAt,
          authors: [
            for (final a in v.authors)
              if (users[a] != null) users[a]!,
          ],
          storageKind: v.storageKind,
          revision: v.revision,
          sizeBytes: v.sizeBytes,
        ),
    ];
  }

  static Future<(DriveItem, ItemVersion)> requireVersion(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    int versionId, {
    Role min = Role.editor,
  }) async {
    final (item, _) = await AccessService.require(
      session,
      actor,
      itemUuid,
      min,
    );
    final version = await ItemVersion.db.findById(session, versionId);
    if (version == null || version.itemId != item.id) {
      throw Errors.notFound('Version');
    }
    return (item, version);
  }

  static Future<List<ItemVersionView>> list(
    Session session,
    Actor actor,
    UuidValue itemUuid, {
    bool namedOnly = false,
    int? beforeId,
    int limit = 100,
  }) async {
    final (item, _) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.editor,
    );
    final versions = await ItemVersion.db.find(
      session,
      where: (t) =>
          t.itemId.equals(item.id!) &
          (namedOnly ? t.kind.equals(VersionKind.named) : Constant.bool(true)) &
          (beforeId == null ? Constant.bool(true) : t.id < beforeId),
      orderBy: (t) => t.id.desc(),
      limit: limit.clamp(1, 500),
    );
    return viewsOf(session, item, versions);
  }

  static Future<ItemVersionView> nameCurrent(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String name,
  ) async {
    final (item, _) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.editor,
    );
    final version = await capture(
      session,
      item,
      kind: VersionKind.named,
      name: _cleanName(name),
      createdById: actor.userId,
    );
    return (await viewsOf(session, item, [version])).single;
  }

  static String _cleanName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw Errors.invalid('The name cannot be empty.');
    return trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;
  }

  /// Names a version (or removes the name with null, making it auto again).
  static Future<ItemVersionView> rename(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    int versionId,
    String? name,
  ) async {
    final (item, version) = await requireVersion(
      session,
      actor,
      itemUuid,
      versionId,
    );
    final clean = name == null || name.trim().isEmpty ? null : _cleanName(name);
    final updated = await ItemVersion.db.updateRow(
      session,
      version.copyWith(
        kind: clean == null
            ? (version.kind == VersionKind.named
                  ? VersionKind.auto
                  : version.kind)
            : VersionKind.named,
        name: clean,
      ),
      columns: (t) => [t.kind, t.name],
    );
    return (await viewsOf(session, item, [updated])).single;
  }

  /// Restores [versionId]: captures a restore point, then applies the
  /// version as a forward edit (specs/07 §5).
  static Future<VersionRestoreResult> restore(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    int versionId,
  ) async {
    final (item, version) = await requireVersion(
      session,
      actor,
      itemUuid,
      versionId,
    );
    // Unnamed versions give an unnamed restore point: clients show it with
    // its localized time and a "Restore point" label (a server-formatted
    // timestamp would be neither readable nor localized).
    final source = version.name;
    final restorePoint = await capture(
      session,
      item,
      kind: VersionKind.restorePoint,
      name: source == null ? null : _restorePointName(source),
      createdById: actor.userId,
    );
    final restored = await providerFor(item).restore(
      session,
      actor,
      item,
      version,
    );
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.restoredVersion,
      summary: {'versionId': version.id, 'name': version.name},
    );
    return VersionRestoreResult(
      restorePoint: (await viewsOf(session, item, [restorePoint])).single,
      revision: restored.revision,
      changeId: restored.changeId,
    );
  }

  /// `Before restoring "<name>"`, shortened to the version name limit.
  static String _restorePointName(String source) {
    const max = 200;
    const prefix = 'Before restoring "';
    final room = max - prefix.length - 1;
    final name = source.length <= room
        ? source
        : '${source.substring(0, room - 1)}…';
    return '$prefix$name"';
  }

  // ---------------------------------------------------------------- jobs

  /// Capture policy job (every minute): an auto version after
  /// [idleBeforeCapture] of inactivity following edits, and at most every
  /// [maxContinuous] during continuous editing.
  ///
  /// Items are claimed one at a time (`capturingSince`, `SKIP LOCKED`), so
  /// overlapping runs (a run longer than a minute, several instances)
  /// never capture the same item twice. The claim of a failed capture
  /// expires after [claimTimeout], which is when it is retried.
  static Future<int> captureDue(
    Session session, {
    DateTime? now,
    Duration budget = const Duration(seconds: 50),
  }) async {
    final at = now ?? nowUtc();
    final watch = Stopwatch()..start();
    var captured = 0;
    for (var i = 0; i < maxCapturesPerRun && watch.elapsed < budget; i++) {
      final itemId = await _claimDue(session, at);
      if (itemId == null) break;
      final item = await DriveItem.db.findById(session, itemId);
      if (item == null || !_providers.containsKey(item.kind)) {
        // Nothing to capture: clean, so it isn't claimed again.
        await ItemVersionState.db.updateWhere(
          session,
          columnValues: (t) => [t.dirtySince(null), t.capturingSince(null)],
          where: (t) => t.itemId.equals(itemId),
        );
        continue;
      }
      try {
        await capture(session, item, kind: VersionKind.auto);
        captured++;
      } on Object catch (e, st) {
        session.log(
          'Version capture of ${item.uuid} failed: $e',
          level: LogLevel.error,
          stackTrace: st,
        );
      }
    }
    return captured;
  }

  /// Claims the item that is due longest, or null when none is.
  static Future<int?> _claimDue(Session session, DateTime at) async {
    final claimed = await session.db.unsafeQuery(
      r'''
      UPDATE item_version_state SET "capturingSince" = @at
      WHERE id = (
        SELECT id FROM item_version_state
        WHERE "dirtySince" IS NOT NULL
          AND ("lastEditAt" <= @idle OR "dirtySince" <= @continuous)
          AND ("capturingSince" IS NULL OR "capturingSince" < @stale)
        ORDER BY "dirtySince"
        LIMIT 1
        FOR UPDATE SKIP LOCKED)
      RETURNING "itemId"
      ''',
      parameters: QueryParameters.named({
        'at': at,
        'idle': at.subtract(idleBeforeCapture),
        'continuous': at.subtract(maxContinuous),
        'stale': at.subtract(claimTimeout),
      }),
    );
    return claimed.isEmpty ? null : claimed.first[0]! as int;
  }

  /// Items whose versions [thin] looks at per round.
  static const thinBatch = 100;

  /// Nightly thinning of auto versions and restore points: keep everything
  /// for 7 days, then one per hour up to 30 days, then one per day. Named
  /// versions are never thinned. Works through the items in rounds of
  /// [thinBatch] (keyset on the item id) until done or [budget] is spent.
  static Future<int> thin(
    Session session, {
    DateTime? now,
    Duration budget = const Duration(minutes: 5),
  }) async {
    final at = now ?? nowUtc();
    final cutoff = at.subtract(const Duration(days: 7));
    final watch = Stopwatch()..start();
    var afterItemId = 0;
    var removed = 0;
    while (watch.elapsed < budget) {
      final rows = await session.db.unsafeQuery(
        r'''
        SELECT DISTINCT "itemId" FROM item_version
        WHERE kind <> @named AND "createdAt" < @cutoff AND "itemId" > @after
        ORDER BY "itemId"
        LIMIT @limit
        ''',
        parameters: QueryParameters.named({
          'named': VersionKind.named.name,
          'cutoff': cutoff,
          'after': afterItemId,
          'limit': thinBatch,
        }),
      );
      if (rows.isEmpty) break;
      final itemIds = {for (final r in rows) r[0]! as int};
      afterItemId = rows.last[0]! as int;
      final candidates = await ItemVersion.db.find(
        session,
        where: (t) =>
            t.itemId.inSet(itemIds) &
            t.kind.notEquals(VersionKind.named) &
            (t.createdAt < cutoff),
        orderBy: (t) => t.createdAt.desc(),
      );
      final keep = <String>{};
      final remove = <ItemVersion>[];
      for (final v in candidates) {
        final c = v.createdAt;
        final age = at.difference(c);
        final bucket = age > const Duration(days: 30)
            ? '${v.itemId}|d|${c.year}-${c.month}-${c.day}'
            : '${v.itemId}|h|${c.year}-${c.month}-${c.day}-${c.hour}';
        if (keep.add(bucket)) continue; // newest of the bucket is kept
        remove.add(v);
      }
      if (remove.isEmpty) continue;
      final items = await DriveItem.db.find(
        session,
        where: (t) => t.id.inSet(<int>{for (final v in remove) v.itemId}),
      );
      final kindOf = {for (final i in items) i.id!: i.kind};
      for (final v in remove) {
        final provider = _providers[kindOf[v.itemId]];
        if (provider == null) continue;
        try {
          await provider.discard(session, v);
        } on Object catch (e, st) {
          session.log(
            'Discarding version ${v.id} failed: $e',
            level: LogLevel.warning,
            stackTrace: st,
          );
        }
      }
      await ItemVersion.db.deleteWhere(
        session,
        where: (t) => t.id.inSet(<int>{for (final v in remove) v.id!}),
      );
      removed += remove.length;
    }
    return removed;
  }
}
