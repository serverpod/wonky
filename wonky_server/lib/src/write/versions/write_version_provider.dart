import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/versions/version_service.dart';
import '../ot/document_cache.dart';
import '../ot/document_store.dart';
import '../ot/ot_service.dart';

/// Write versions (Write 08 §4.1): a version is an op-log revision with a
/// snapshot at that revision, so op-log pruning never breaks
/// materialization.
class WriteVersionProvider implements VersionProvider {
  const WriteVersionProvider();

  @override
  DriveItemKind get kind => DriveItemKind.document;

  /// Writes this instance's batched edit bookkeeping of the document, so
  /// the capture sees its authors (Write 03 §2 step 8).
  @override
  Future<void> beforeCapture(Session session, DriveItem item) async {
    final uuid = item.contentRef;
    if (uuid != null) await DocumentCache.settle(uuid);
  }

  @override
  Future<CapturedVersion> capture(Session session, DriveItem item) async {
    final doc = await DocumentStore.requireByItem(session, item.id!);
    final content = await DocumentStore.head(session, doc);
    await DocumentStore.writeSnapshot(session, doc, doc.headRevision, content);
    final size = DocumentStore.encodeContent(content, compress: false).length;
    return CapturedVersion(
      storageKind: VersionStorage.writeRevision,
      revision: doc.headRevision,
      sizeBytes: size,
    );
  }

  @override
  Future<RestoredVersion> restore(
    Session session,
    Actor actor,
    DriveItem item,
    ItemVersion version,
  ) async {
    final doc = await DocumentStore.requireByItem(session, item.id!);
    final revision = version.revision;
    if (revision == null) throw Errors.invalid('The version has no revision.');
    final target = DeltaUtils.stripOverlays(
      await DocumentStore.contentAt(session, doc, revision),
    );
    final committed = await OtService.submitServerChange(
      session,
      actor: actor,
      document: doc,
      item: item,
      kind: DocumentOpKind.restore,
      // R = strip(C).diff(strip(V)) keeps anchors on surviving text.
      build: (head) => DeltaUtils.stripOverlays(head).diff(target),
    );
    return RestoredVersion(revision: committed.revision);
  }

  /// Deletes the snapshot of a thinned version unless another version
  /// shows the same revision or the snapshot is still needed: the newest
  /// one (fast loads) and the newest one at or below the oldest kept op
  /// (the base later revisions are materialized from, Write 02 §3).
  @override
  Future<void> discard(Session session, ItemVersion version) async {
    final revision = version.revision;
    if (revision == null) return;
    final doc = await DocumentStore.byItem(session, version.itemId);
    if (doc == null) return;
    await session.db.unsafeExecute(
      r'''
      DELETE FROM document_snapshot s
      WHERE s."documentId" = @doc AND s.revision = @rev
        AND NOT EXISTS (
          SELECT 1 FROM item_version v
          WHERE v."itemId" = @item AND v.revision = @rev AND v.id <> @version)
        AND s.revision < (
          SELECT max(revision) FROM document_snapshot WHERE "documentId" = @doc)
        AND s.revision IS DISTINCT FROM (
          SELECT max(revision) FROM document_snapshot
          WHERE "documentId" = @doc AND revision <= COALESCE(
            (SELECT min(revision) - 1 FROM document_op
             WHERE "documentId" = @doc),
            @head))
      ''',
      parameters: QueryParameters.named({
        'doc': doc.id!,
        'rev': revision,
        'item': version.itemId,
        'version': version.id!,
        'head': doc.headRevision,
      }),
    );
  }

  @override
  Future<void> afterCapture(
    Session session,
    DriveItem item,
    ItemVersion version,
    CapturedVersion captured,
  ) async {}
}
