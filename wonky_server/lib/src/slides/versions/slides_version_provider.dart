import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/history.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/schema.dart' show SlidesTables;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/files/file_service.dart';
import '../../platform/revlog/rev_sql.dart';
import '../../platform/presence/presence_service.dart';
import '../../platform/users/user_service.dart';
import '../../platform/versions/version_service.dart';
import '../revlog/slides_rev_binding.dart';
import '../revlog/slides_server_writes.dart';

/// Slides versions (Slides 09 §4.1, §4.4): a gzip NDJSON snapshot of every
/// deck row in cloud storage (`snapshot.wsd.gz`, not counted toward the
/// quota), taken at a file revision (`ItemVersion.revision`), with a
/// `SlidesSnapshotIndex` (slide list, who changed what: the summaries of
/// the RevLog ops between two captures); a restore applies the row diff as
/// a RevLog server change recorded as a `ServerChangeRecord`
/// (`slides.serverChange` undo; RevLog spec 08 §7).
class SlidesVersionProvider implements VersionProvider {
  const SlidesVersionProvider();

  /// Max ops read for one version's attribution.
  static const maxLogRows = 20000;

  @override
  DriveItemKind get kind => DriveItemKind.presentation;

  /// Every row of the deck [space] (admin read) by table and id.
  static Future<DeckRowsByTable> readSpace(
    Session session,
    UuidValue space,
  ) async => (await readAt(session, space)).$2;

  /// The rows of [space] as [readSpace] with the file revision they show:
  /// one repeatable-read transaction, so rows and revision agree while ops
  /// commit. Revision 0 and no rows when the file is missing.
  static Future<(int, DeckRowsByTable)> readAt(
    Session session,
    UuidValue space,
  ) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(space),
    );
    final result = <String, Map<String, Map<String, Object?>>>{};
    if (file == null) return (0, result);
    final sql = RevSql(SlidesRevBinding.instance.schema);
    final (revision, rows) = await session.db.transaction(
      (tx) async {
        final head = await session.db.unsafeQuery(
          'SELECT "headRevision" FROM rev_file WHERE id = @f',
          parameters: QueryParameters.named({'f': file.id}),
          transaction: tx,
        );
        final list = await sql
            .allRows(
              session,
              file.id!,
              scopes: () async => const {},
              transaction: tx,
            )
            .toList();
        return (head.first[0]! as int, list);
      },
      settings: TransactionSettings(
        isolationLevel: IsolationLevel.repeatableRead,
      ),
    );
    for (final (table, row) in rows) {
      (result[table] ??= {})[row['id']! as String] = row;
    }
    return (revision, result);
  }

  /// The rows of [rows] as `(table, columns)` in dependency order.
  static List<(String, Map<String, Object?>)> listOf(DeckRowsByTable rows) => [
    for (final t in SlidesTables.dependencyOrder)
      for (final r in rows[t]?.values ?? const <Map<String, Object?>>[]) (t, r),
  ];

  @override
  Future<CapturedVersion> capture(Session session, DriveItem item) async {
    final space = item.contentRef!;
    final (revision, rows) = await readAt(session, space);
    if (rows[SlidesTables.deck]?.isEmpty ?? true) {
      throw Errors.notFound('Presentation');
    }
    final bytes = SlidesSnapshotCodec.encode(
      listOf(rows),
      deckId: space.uuid,
      capturedAt: nowUtc(),
    );
    final file = await FileService.storeServerFile(
      session,
      ownerId: item.ownerId,
      itemId: item.id,
      kind: StoredFileKind.snapshot,
      fileName: 'snapshot.wsd.gz',
      mimeType: 'application/gzip',
      bytes: bytes,
    );
    return CapturedVersion(
      storageKind: VersionStorage.snapshotFile,
      revision: revision,
      snapshotFileId: file.fileUuid,
      sizeBytes: bytes.length,
      // The slide list of the index, from the rows in memory: afterCapture
      // never downloads and decodes the snapshot it just stored.
      index: SnapshotSlideEntry.encodeList(
        DeckModel.fromRows(space.uuid, listOf(rows)),
      ),
    );
  }

  @override
  Future<void> beforeCapture(Session session, DriveItem item) async {}

  /// The decoded snapshot of [version].
  static Future<SlidesSnapshot> snapshotOf(
    Session session,
    ItemVersion version,
  ) async {
    final fileId = version.snapshotFileId;
    if (fileId == null) throw Errors.invalid('The version has no snapshot.');
    final file = await FileService.byUuid(session, fileId);
    if (file == null) throw Errors.expired('The snapshot is no longer stored.');
    final bytes = await FileService.readBytes(session, file);
    try {
      return SlidesSnapshotCodec.decode(
        Uint8List.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } on FormatException catch (e) {
      throw Errors.invalid('The snapshot is damaged (${e.message}).');
    }
  }

  @override
  Future<void> afterCapture(
    Session session,
    DriveItem item,
    ItemVersion version,
    CapturedVersion captured,
  ) async {
    final slides =
        captured.index as String? ??
        SnapshotSlideEntry.encodeList(
          (await snapshotOf(session, version)).toModel(),
        );
    final changes = await changesOf(session, item, version);
    await SlidesSnapshotIndex.db.insertRow(
      session,
      SlidesSnapshotIndex(
        itemVersionId: version.id!,
        slidesJson: slides,
        changesJson: changes.encode(),
        authorIds: version.authors,
      ),
    );
  }

  /// Who changed what in [version]'s window: the ops committed after the
  /// previous capture's revision up to this capture's (by commit time for
  /// versions without a revision), oldest first; offline edits that synced
  /// later belong to the version whose window contains their commit (09
  /// §4.1). Empty on errors.
  static Future<SlidesVersionChanges> changesOf(
    Session session,
    DriveItem item,
    ItemVersion version,
  ) async {
    try {
      final file = await RevFile.db.findFirstRow(
        session,
        where: (t) => t.fileUuid.equals(item.contentRef!),
      );
      final builder = SlidesVersionChangesBuilder();
      if (file == null) return builder.build();
      final prev = await ItemVersion.db.findFirstRow(
        session,
        where: (t) => t.itemId.equals(version.itemId) & (t.id < version.id!),
        orderBy: (t) => t.id.desc(),
      );
      final to = version.revision;
      final from = prev?.revision;
      final byRevision = to != null && (prev == null || from != null);
      final ops = await RevOp.db.find(
        session,
        where: (t) => byRevision
            ? t.fileId.equals(file.id!) &
                  (from == null ? Constant.bool(true) : t.revision > from) &
                  (t.revision <= to)
            : t.fileId.equals(file.id!) &
                  (prev == null
                      ? Constant.bool(true)
                      : t.committedAt > prev.createdAt) &
                  (t.committedAt <= version.createdAt),
        orderBy: (t) => t.revision,
        limit: maxLogRows,
      );
      if (ops.length >= maxLogRows) builder.markApprox();
      for (final o in ops) {
        final user = o.authorId;
        final summary = o.summaryJson;
        if (user == null) continue;
        if (summary == null) {
          // Pruned (older than the op retention).
          builder.markApprox();
          continue;
        }
        builder.add(summary, user, actorKind: o.actorKind.name);
      }
      return builder.build();
    } on Exception catch (e) {
      session.log('Version changes failed: $e', level: LogLevel.warning);
      return const SlidesVersionChanges(approx: true);
    }
  }

  @override
  Future<RestoredVersion> restore(
    Session session,
    Actor actor,
    DriveItem item,
    ItemVersion version,
  ) async {
    final target = (await snapshotOf(session, version)).byTable();
    final current = await readSpace(session, item.contentRef!);
    final changes = SlidesRestoreChanges.between(current, target);
    final label =
        'Restore version "${version.name ?? version.createdAt.toIso8601String()}"';
    final write = await SlidesServerWrites.withWriteLock(
      item.contentRef!,
      () => SlidesServerWrites.applyRecorded(
        session,
        actor: actor,
        item: item,
        changes: changes,
        label: label,
        // Slides and elements deleted since the version come back.
        revives: true,
        lifetime: const Duration(days: 7),
      ),
    );
    try {
      final profile = await UserService.requireProfile(session, actor.userId);
      final who = await UserService.summaryOf(session, profile);
      await PresenceService.notice(session, item.uuid, 'versionRestored', {
        'userId': actor.userId,
        'name': who.displayName,
        'versionId': version.id,
      });
    } on Exception catch (e) {
      session.log('Restore notice failed: $e', level: LogLevel.warning);
    }
    return RestoredVersion(changeId: write.changeId);
  }

  @override
  Future<void> discard(Session session, ItemVersion version) async {
    if (version.snapshotFileId != null) {
      await FileService.deleteFile(session, version.snapshotFileId!);
    }
  }
}
