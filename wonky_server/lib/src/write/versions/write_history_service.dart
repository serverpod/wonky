import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/isolate_runner.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/drive/drive_service.dart';
import '../../platform/users/user_service.dart';
import '../../platform/versions/version_service.dart';
import '../ot/document_service.dart';
import '../ot/document_store.dart';
import '../../platform/storage/storage_service.dart';

/// Write version history (Write 08 §4.3).
abstract final class WriteHistoryService {
  /// Attributed replay is used up to this many ops.
  static int maxReplayOps = 20000;
  static const diffCacheRetention = Duration(days: 7);

  static Future<WriteVersionDocument> getVersionDocument(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    int revision,
  ) async {
    final (doc, _, _) = await DocumentService.require(
      session,
      actor,
      documentUuid,
      min: Role.editor,
    );
    final content = await DocumentStore.contentAt(session, doc, revision);
    return WriteVersionDocument(
      revision: revision,
      deltaJson: jsonEncode(DeltaUtils.stripOverlays(content).toJson()),
    );
  }

  static Future<WriteDiffView> diff(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    int fromRevision,
    int toRevision,
  ) async {
    final (doc, _, _) = await DocumentService.require(
      session,
      actor,
      documentUuid,
      min: Role.editor,
    );
    var a = fromRevision;
    var b = toRevision;
    if (a > b) (a, b) = (b, a);
    if (a < 0 || b > doc.headRevision) {
      throw Errors.invalid('The revisions are out of range.');
    }
    final cached = await WriteDiffCache.db.findFirstRow(
      session,
      where: (t) =>
          t.documentId.equals(doc.id!) &
          t.fromRevision.equals(a) &
          t.toRevision.equals(b),
    );
    if (cached != null) {
      return WriteDiffView.fromJson(
        (jsonDecode(cached.json) as Map).cast<String, dynamic>(),
      );
    }
    final docA = await DocumentStore.contentAt(session, doc, a);
    // Bounded: past maxReplayOps the diff compares snapshots, so the ops
    // are not loaded at all (at most maxReplayOps + 1 otherwise).
    final ops = b - a > maxReplayOps
        ? const <DocumentOp>[]
        : await DocumentOp.db.find(
            session,
            where: (t) =>
                t.documentId.equals(doc.id!) &
                (t.revision > a) &
                (t.revision <= b),
            orderBy: (t) => t.revision,
            limit: maxReplayOps + 1,
          );
    final users = await UserService.summaries(session, [
      for (final o in ops) o.authorId,
    ]);
    final WriteDiff result;
    try {
      if (ops.length == b - a && ops.length <= maxReplayOps) {
        result = await _diffIn(docA, [
          for (final o in ops)
            AuthoredOp(
              DocumentStore.decodeDelta(o.deltaJson),
              authorUuid: users[o.authorId]?.uuid.uuid,
              actorKind: o.actorKind.name,
            ),
        ], null);
      } else {
        final docB = await DocumentStore.contentAt(session, doc, b);
        result = await _diffIn(docA, null, docB);
      }
    } on TimeoutException {
      throw Errors.unavailable(
        'Comparing these versions took too long. Pick versions closer '
        'together.',
      );
    }
    final byUuid = {for (final u in users.values) u.uuid.uuid: u};
    final view = WriteDiffView(
      fromRevision: a,
      toRevision: b,
      exact: result.exact,
      deltaJson: jsonEncode(result.delta.toJson()),
      authors: [
        for (final s in result.authors)
          WriteDiffAuthor(
            userUuid: s.userUuid == null ? null : byUuid[s.userUuid]?.uuid,
            name: byUuid[s.userUuid]?.displayName ?? 'Multiple people',
            colorIndex: byUuid[s.userUuid]?.colorIndex ?? 0,
            actorKind: ActorKind.values.firstWhere(
              (k) => k.name == s.actorKind,
              orElse: () => ActorKind.user,
            ),
            inserted: s.inserted,
            deleted: s.deleted,
            formatted: s.formatted,
          ),
      ],
      changeCount: result.changeCount,
    );
    try {
      await WriteDiffCache.db.insertRow(
        session,
        WriteDiffCache(
          documentId: doc.id!,
          fromRevision: a,
          toRevision: b,
          json: jsonEncode(view.toJson()),
          createdAt: nowUtc(),
        ),
      );
    } on DatabaseException {
      // Computed concurrently.
    }
    return view;
  }

  /// Time limit of one diff (the worker isolate is killed after it).
  static const diffTimeout = Duration(seconds: 60);

  /// The attributed diff of [ops] from [docA], or of the snapshots [docA]
  /// and [docB], in a worker isolate (the shared `IsolateRunner`).
  static Future<WriteDiff> _diffIn(
    Delta docA,
    List<AuthoredOp>? ops,
    Delta? docB,
  ) => IsolateRunner.run(
    () => ops != null
        ? AttributedDiff.diff(docA, ops)
        : AttributedDiff.diffSnapshots(docA, docB!),
    name: 'write-diff',
    timeout: diffTimeout,
  );

  static Future<ItemVersionView> createRestorePoint(
    Session session,
    Actor actor,
    UuidValue documentUuid,
  ) async {
    final (_, item, _) = await DocumentService.require(
      session,
      actor,
      documentUuid,
      min: Role.editor,
    );
    final version = await VersionService.capture(
      session,
      item,
      kind: VersionKind.restorePoint,
      name: 'Restore point',
      createdById: actor.userId,
    );
    return (await VersionService.viewsOf(session, item, [version])).single;
  }

  static Future<VersionRestoreResult> restore(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    int versionId,
  ) async {
    final (_, item, _) = await DocumentService.require(
      session,
      actor,
      documentUuid,
      min: Role.editor,
    );
    return VersionService.restore(session, actor, item.uuid, versionId);
  }

  /// A new document from a version (overlays stripped).
  static Future<DriveItemView> copyVersion(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    int versionId,
    String name, {
    UuidValue? parentUuid,
  }) async {
    final (doc, item, _) = await DocumentService.require(
      session,
      actor,
      documentUuid,
      min: Role.editor,
    );
    final version = await ItemVersion.db.findById(session, versionId);
    if (version == null ||
        version.itemId != item.id ||
        version.revision == null) {
      throw Errors.notFound('Version');
    }
    final content = DeltaUtils.stripOverlays(
      await DocumentStore.contentAt(session, doc, version.revision!),
    );
    return DriveService.createDocumentFromContent(
      session,
      actor,
      name: name,
      parentUuid: parentUuid,
      content: content,
      source: doc,
      quotaReason: QuotaReason.restoreVersionCopy,
    );
  }

  static Future<int> purgeDiffCache(Session session, {DateTime? now}) async {
    final cutoff = (now ?? nowUtc()).subtract(diffCacheRetention);
    // A count, not the deleted rows (their JSON can be large).
    return session.db.unsafeExecute(
      'DELETE FROM write_diff_cache WHERE "createdAt" < @cutoff',
      parameters: QueryParameters.named({'cutoff': cutoff}),
    );
  }
}
