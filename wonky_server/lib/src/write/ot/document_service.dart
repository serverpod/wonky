import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/drive/drive_views.dart';
import '../../platform/sharing/access_service.dart';
import '../../platform/users/user_service.dart';
import '../themes/theme_service.dart';
import 'document_bus.dart';
import 'document_store.dart';

/// Non-streaming document operations (Write 03 §1, §6).
abstract final class DocumentService {
  static const metaFields = {'themeId', 'pageSetup', 'language', 'frontMatter'};
  static const maxOpsPerRequest = 1000;
  static const opRetention = Duration(days: 30);

  /// Below Editor, only the ops of the last this many revisions can be
  /// read (catching up); older ops are history (Editor+).
  static const recentOpWindow = 1000;

  /// The oldest revision whose op [role] may read at [headRevision].
  static int oldestOpFor(Role role, int headRevision) {
    if (role >= Role.editor) return 1;
    final oldest = headRevision - recentOpWindow + 1;
    return oldest < 1 ? 1 : oldest;
  }

  static Future<(Document, DriveItem, Role)> require(
    Session session,
    Actor actor,
    UuidValue documentUuid, {
    Role min = Role.viewer,
  }) async {
    final doc = await DocumentStore.byUuid(session, documentUuid);
    if (doc == null) throw Errors.notFound('Document');
    final item = await DriveItem.db.findById(session, doc.itemId);
    if (item == null) throw Errors.notFound('Document');
    final role = await AccessService.requireRole(session, actor, item, min);
    return (doc, item, role);
  }

  static Future<DocumentInfo> getInfo(
    Session session,
    Actor actor,
    UuidValue documentUuid,
  ) async {
    final (doc, item, role) = await require(session, actor, documentUuid);
    final report = await DocumentImportReport.db.findFirstRow(
      session,
      where: (t) =>
          t.documentId.equals(doc.id!) &
          t.userId.equals(actor.userId) &
          t.seenAt.equals(null),
    );
    List<ImportWarningView>? warnings;
    if (report != null) {
      warnings = [
        for (final w in jsonDecode(report.warningsJson) as List<dynamic>)
          ImportWarningView.fromJson((w as Map).cast<String, dynamic>()),
      ];
      await DocumentImportReport.db.updateRow(
        session,
        report.copyWith(seenAt: nowUtc()),
      );
    }
    return DocumentInfo(
      documentUuid: doc.uuid,
      item: await DriveViews.one(session, actor.userId, item, role: role),
      headRevision: doc.headRevision,
      meta: DocumentMetaView(
        themeId: doc.themeId,
        pageSetupJson: doc.pageSetupJson,
        language: doc.language,
        frontMatter: doc.frontMatter,
      ),
      charCount: doc.charCount,
      wordCount: doc.wordCount,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
      importWarnings: warnings,
    );
  }

  static Future<List<DocumentOpView>> getOps(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    int fromRevision,
    int toRevision,
  ) async {
    final (doc, _, role) = await require(session, actor, documentUuid);
    if (toRevision < fromRevision) return const [];
    if ((fromRevision < 1 ? 1 : fromRevision) <
        oldestOpFor(role, doc.headRevision)) {
      throw Errors.forbidden('Viewing history requires edit access.');
    }
    final to = toRevision.clamp(0, fromRevision + maxOpsPerRequest - 1);
    final ops = await DocumentOp.db.find(
      session,
      where: (t) =>
          t.documentId.equals(doc.id!) &
          (t.revision >= fromRevision) &
          (t.revision <= to),
      orderBy: (t) => t.revision,
    );
    final users = await UserService.summaries(session, [
      for (final o in ops) o.authorId,
    ]);
    return [
      for (final o in ops)
        DocumentOpView(
          revision: o.revision,
          deltaJson: o.deltaJson,
          clientOpId: o.clientOpId,
          authorId: o.authorId,
          authorUuid: users[o.authorId]?.uuid,
          actorKind: o.actorKind,
          kind: o.kind,
          sessionId: o.sessionId,
          createdAt: o.createdAt,
        ),
    ];
  }

  /// The content at [revision] (head when null). Older revisions require
  /// Editor+ (history).
  static Future<DocumentSnapshotView> getSnapshot(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    int? revision,
  ) async {
    final (doc, _, role) = await require(session, actor, documentUuid);
    final rev = revision ?? doc.headRevision;
    if (rev != doc.headRevision && role < Role.editor) {
      throw Errors.forbidden('Viewing history requires edit access.');
    }
    final content = await DocumentStore.contentAt(session, doc, rev);
    return DocumentSnapshotView(
      revision: rev,
      deltaJson: jsonEncode(content.toJson()),
    );
  }

  /// LWW metadata change (Write 03 §6); idempotent on [clientOpId].
  static Future<void> updateMeta(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    DocumentMetaPatch patch,
    UuidValue clientOpId,
  ) async {
    final (doc, _, _) = await require(
      session,
      actor,
      documentUuid,
      min: Role.editor,
    );
    if (!metaFields.contains(patch.field)) {
      throw Errors.invalid('Unknown document property "${patch.field}".');
    }
    final duplicate = await DocumentMetaChange.db.findFirstRow(
      session,
      where: (t) =>
          t.documentId.equals(doc.id!) & t.clientOpId.equals(clientOpId),
    );
    if (duplicate != null) return;
    final Object? value;
    try {
      value = jsonDecode(patch.valueJson);
    } on FormatException {
      throw Errors.invalid('The value is not valid JSON.');
    }
    late String beforeJson;
    late String afterJson;
    UuidValue? themeId;
    switch (patch.field) {
      case 'themeId':
        if (value != null) {
          if (value is! String) throw Errors.invalid('themeId must be a UUID.');
          themeId = UuidValue.withValidation(value);
          final theme = await ThemeService.requireAssignable(
            session,
            actor,
            themeId,
            doc,
          );
          afterJson = jsonEncode({
            'themeId': themeId.uuid,
            'version': theme.version,
            'hash': theme.contentHash,
          });
        } else {
          afterJson = jsonEncode({'themeId': null});
        }
        beforeJson = jsonEncode({'themeId': doc.themeId?.uuid});
      case 'pageSetup':
        if (value is! Map) throw Errors.invalid('pageSetup must be an object.');
        beforeJson = doc.pageSetupJson;
        afterJson = canonicalJsonEncode(value);
      case 'language':
        if (value != null &&
            (value is! String ||
                !RegExp(
                  r'^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})*$',
                ).hasMatch(value))) {
          throw Errors.invalid('language must be a BCP-47 tag.');
        }
        beforeJson = jsonEncode(doc.language);
        afterJson = jsonEncode(value);
      case 'frontMatter':
        if (value != null && value is! String) {
          throw Errors.invalid('frontMatter must be a string.');
        }
        if (value is String && value.length > 64 * 1024) {
          throw Errors.tooLarge('The front matter is too long.');
        }
        beforeJson = jsonEncode(doc.frontMatter);
        afterJson = jsonEncode(value);
    }
    final now = nowUtc();
    try {
      await session.db.transaction((tx) async {
        // Only the changed column: the row read above is stale as soon as
        // an op commits (a full-row write would roll back headRevision).
        await Document.db.updateWhere(
          session,
          columnValues: (t) => [
            switch (patch.field) {
              'themeId' => t.themeId(themeId),
              'pageSetup' => t.pageSetupJson(afterJson),
              'language' => t.language(value as String?),
              _ => t.frontMatter(value as String?),
            },
            t.updatedAt(now),
          ],
          where: (t) => t.id.equals(doc.id!),
          transaction: tx,
        );
        await DocumentMetaChange.db.insertRow(
          session,
          DocumentMetaChange(
            documentId: doc.id!,
            field: patch.field,
            clientOpId: clientOpId,
            beforeJson: beforeJson,
            afterJson: afterJson,
            authorId: actor.userId,
            actorKind: actor.kind,
            createdAt: now,
          ),
          transaction: tx,
        );
      });
    } on DatabaseQueryException catch (e) {
      // A concurrent resend of the same change won the race.
      if (e.code == '23505' &&
          (e.constraintName == 'document_meta_change_client_idx' ||
              e.message.contains('document_meta_change_client_idx'))) {
        return;
      }
      rethrow;
    }
    await DocumentBus.metaChanged(
      session,
      doc.uuid,
      DocMetaChanged(
        field: patch.field,
        valueJson: patch.valueJson,
        authorId: actor.userId,
      ),
    );
  }

  /// Documents handled per round of [pruneOps].
  static const pruneBatch = 100;

  /// Daily job: deletes ops older than [opRetention], after making sure a
  /// snapshot exists at the newest pruned revision (materialization of later
  /// revisions and versions keeps working), and the snapshots below that
  /// revision except those of versions (Write 02 §3). Works in rounds of
  /// [pruneBatch] documents until nothing is left or [budget] is spent.
  static Future<int> pruneOps(
    Session session, {
    DateTime? now,
    Duration budget = const Duration(minutes: 5),
  }) async {
    final cutoff = (now ?? nowUtc()).subtract(opRetention);
    final watch = Stopwatch()..start();
    // Documents that failed this run (not offered again).
    final skip = <int>{};
    var pruned = 0;
    while (watch.elapsed < budget) {
      final rows = await session.db.unsafeQuery(
        '''
        SELECT "documentId", max(revision) FROM document_op
        WHERE "createdAt" < @cutoff
        ${skip.isEmpty ? '' : 'AND "documentId" NOT IN (${skip.join(',')})'}
        GROUP BY "documentId" LIMIT $pruneBatch
        ''',
        parameters: QueryParameters.named({'cutoff': cutoff}),
      );
      if (rows.isEmpty) break;
      for (final row in rows) {
        final documentId = row[0] as int;
        try {
          final count = await _pruneDocument(
            session,
            documentId,
            row[1] as int,
          );
          if (count == 0) skip.add(documentId);
          pruned += count;
        } on Object catch (e, st) {
          skip.add(documentId);
          session.log(
            'Pruning the ops of document $documentId failed: $e',
            level: LogLevel.error,
            stackTrace: st,
          );
        }
        if (watch.elapsed >= budget) break;
      }
    }
    return pruned;
  }

  /// Prunes the ops of one document up to [upTo]; returns their number.
  static Future<int> _pruneDocument(
    Session session,
    int documentId,
    int upTo,
  ) async {
    final doc = await Document.db.findById(session, documentId);
    if (doc == null) return 0;
    final content = await DocumentStore.contentAt(session, doc, upTo);
    await DocumentStore.writeSnapshot(session, doc, upTo, content);
    return session.db.transaction((tx) async {
      final count = await session.db.unsafeExecute(
        r'''
        DELETE FROM document_op
        WHERE "documentId" = @doc AND revision <= @upTo
        ''',
        parameters: QueryParameters.named({'doc': documentId, 'upTo': upTo}),
        transaction: tx,
      );
      // Below upTo a snapshot only serves its own revision: keep those of
      // versions (restores, diffs), drop the rest.
      await session.db.unsafeExecute(
        r'''
        DELETE FROM document_snapshot s
        WHERE s."documentId" = @doc AND s.revision < @upTo
          AND NOT EXISTS (
            SELECT 1 FROM item_version v
            WHERE v."itemId" = @item AND v.revision = s.revision
          )
        ''',
        parameters: QueryParameters.named({
          'doc': documentId,
          'upTo': upTo,
          'item': doc.itemId,
        }),
        transaction: tx,
      );
      return count;
    });
  }
}
