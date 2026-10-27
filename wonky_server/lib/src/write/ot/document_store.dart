import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';

/// Persistence of Write documents: rows, op log, snapshots and
/// materialization (Write 02 §3).
abstract final class DocumentStore {
  /// Snapshots larger than this are stored gzip+base64.
  static const compressThreshold = 64 * 1024;

  /// The content of a new, blank document.
  static Delta emptyDocument() => Delta()..insert('\n');

  static Future<Document?> byUuid(
    Session session,
    UuidValue uuid, {
    Transaction? transaction,
  }) => Document.db.findFirstRow(
    session,
    where: (t) => t.uuid.equals(uuid),
    transaction: transaction,
  );

  static Future<Document?> byItem(
    Session session,
    int itemId, {
    Transaction? transaction,
  }) => Document.db.findFirstRow(
    session,
    where: (t) => t.itemId.equals(itemId),
    transaction: transaction,
  );

  static Future<Document> requireByItem(Session session, int itemId) async {
    final doc = await byItem(session, itemId);
    if (doc == null) throw Errors.notFound('Document');
    return doc;
  }

  /// Creates the document row of [item]. A non-empty [initial] content is
  /// stored as revision 1 (op of [kind]) with a snapshot at revision 1.
  static Future<Document> create(
    Session session, {
    required DriveItem item,
    required UuidValue documentUuid,
    required Actor actor,
    Delta? initial,
    DocumentOpKind kind = DocumentOpKind.imported,
    String? frontMatter,
    String? language,
    UuidValue? themeId,
    String pageSetupJson = '{}',
    MarkdownFlavor markdownFlavor = MarkdownFlavor.gfm,
    required Transaction transaction,
  }) async {
    final now = nowUtc();
    final content = initial == null
        ? null
        : const WonkyDeltaNormalizer().normalize(initial).document;
    final hasContent =
        content != null && !DeltaUtils.equals(content, emptyDocument());
    final text = hasContent ? DeltaUtils.text(content) : '';
    final doc = await Document.db.insertRow(
      session,
      Document(
        uuid: documentUuid,
        itemId: item.id!,
        headRevision: hasContent ? 1 : 0,
        latestSnapshotRevision: hasContent ? 1 : 0,
        themeId: themeId,
        pageSetupJson: pageSetupJson,
        language: language,
        frontMatter: frontMatter,
        markdownFlavor: markdownFlavor.value,
        charCount: text.length,
        wordCount: wordCount(text),
        createdAt: now,
        updatedAt: now,
      ),
      transaction: transaction,
    );
    if (hasContent) {
      final change = DeltaUtils.canonical(
        emptyDocument().diff(content),
      );
      await DocumentOp.db.insertRow(
        session,
        DocumentOp(
          documentId: doc.id!,
          revision: 1,
          clientOpId: const Uuid().v7obj(),
          authorId: actor.userId,
          actorKind: actor.kind,
          sessionId: actor.sessionId,
          kind: kind,
          baseRevision: 0,
          deltaJson: jsonEncode(change.toJson()),
          inverseJson: jsonEncode(
            WonkyOt.invert(change, emptyDocument()).toJson(),
          ),
          createdAt: now,
        ),
        transaction: transaction,
      );
      await writeSnapshot(session, doc, 1, content, transaction: transaction);
    }
    return doc;
  }

  // ----------------------------------------------------------- snapshots

  static String encodeContent(Delta content, {required bool compress}) {
    final json = jsonEncode(content.toJson());
    if (!compress) return json;
    return base64Encode(gzip.encode(utf8.encode(json)));
  }

  static Delta decodeSnapshot(DocumentSnapshot snapshot) {
    final json = snapshot.compressed
        ? utf8.decode(gzip.decode(base64Decode(snapshot.deltaJson)))
        : snapshot.deltaJson;
    return decodeDelta(json);
  }

  static Delta decodeDelta(String json) {
    final value = jsonDecode(json);
    if (value is! List) throw const FormatException('Delta must be a list');
    return Delta.fromJson(value);
  }

  static Future<void> writeSnapshot(
    Session session,
    Document doc,
    int revision,
    Delta content, {
    Transaction? transaction,
  }) async {
    final json = jsonEncode(content.toJson());
    final compress = json.length > compressThreshold;
    final existing = await DocumentSnapshot.db.findFirstRow(
      session,
      where: (t) => t.documentId.equals(doc.id!) & t.revision.equals(revision),
      transaction: transaction,
    );
    if (existing != null) return;
    await DocumentSnapshot.db.insertRow(
      session,
      DocumentSnapshot(
        documentId: doc.id!,
        revision: revision,
        deltaJson: compress ? encodeContent(content, compress: true) : json,
        compressed: compress,
        createdAt: nowUtc(),
      ),
      transaction: transaction,
    );
    if (revision > doc.latestSnapshotRevision) {
      await Document.db.updateWhere(
        session,
        columnValues: (t) => [t.latestSnapshotRevision(revision)],
        where: (t) =>
            t.id.equals(doc.id!) & (t.latestSnapshotRevision < revision),
        transaction: transaction,
      );
    }
  }

  /// The document content at [revision] (nearest snapshot ≤ revision plus
  /// the ops after it). Throws `notFound` when the ops were pruned.
  static Future<Delta> contentAt(
    Session session,
    Document doc,
    int revision, {
    Transaction? transaction,
  }) async {
    if (revision < 0 || revision > doc.headRevision) {
      throw Errors.invalid('Revision $revision does not exist.');
    }
    final snapshot = await DocumentSnapshot.db.findFirstRow(
      session,
      where: (t) => t.documentId.equals(doc.id!) & (t.revision <= revision),
      orderBy: (t) => t.revision.desc(),
      transaction: transaction,
    );
    var content = snapshot == null ? emptyDocument() : decodeSnapshot(snapshot);
    final from = snapshot?.revision ?? 0;
    if (from == revision) return content;
    final ops = await DocumentOp.db.find(
      session,
      where: (t) =>
          t.documentId.equals(doc.id!) &
          (t.revision > from) &
          (t.revision <= revision),
      orderBy: (t) => t.revision,
      transaction: transaction,
    );
    if (ops.length != revision - from) {
      throw Errors.notFound('Revision $revision');
    }
    for (final op in ops) {
      content = content.compose(decodeDelta(op.deltaJson));
    }
    return DeltaUtils.canonical(content);
  }

  static Future<Delta> head(
    Session session,
    Document doc, {
    Transaction? transaction,
  }) => contentAt(session, doc, doc.headRevision, transaction: transaction);

  static int wordCount(String text) =>
      RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(text).length;

  /// Plain text for search (embeds rendered as text, Write 02 §5).
  static String searchText(Delta content) {
    final text = DeltaUtils.text(content);
    return text.length > 100000 ? text.substring(0, 100000) : text;
  }
}
