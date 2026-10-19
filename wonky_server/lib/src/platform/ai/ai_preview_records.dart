import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';

import '../common/models.dart';

/// The stored Suggest-mode AI changes previews of Sheets and Slides
/// ([AiPreviewRecord], Sheets 12 §6.3, Slides 11 §6.3; CQ-52): any server
/// instance can show, apply or discard a preview until it expires. The apps
/// keep their own preview JSON and recorded changes; this class stores,
/// loads and deletes them.
abstract final class AiPreviewRecords {
  /// Previews whose encoded changes are larger are not stored (the
  /// in-memory shadow of the instance that ran the assistant still has
  /// them).
  static const maxBytes = 8 * 1024 * 1024;

  /// gzip+base64 of [json] (the `changesJson` column).
  static String encode(Object? json) =>
      base64Encode(gzip.encode(utf8.encode(jsonEncode(json))));

  /// The JSON of an [encode]d value.
  static Object? decode(String data) =>
      jsonDecode(utf8.decode(gzip.decode(base64Decode(data))));

  /// Stores a preview (replacing an earlier one with the same id) and
  /// purges expired ones. Returns false, storing nothing, when
  /// [changesJson] is larger than [maxBytes].
  static Future<bool> save(
    Session session, {
    required String previewId,
    required int userId,
    required UuidValue fileUuid,
    required String previewJson,
    required String changesJson,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) async {
    final now = clock.now().toUtc();
    await AiPreviewRecord.db.deleteWhere(
      session,
      where: (t) => t.expiresAt < now,
    );
    if (changesJson.length > maxBytes) return false;
    await delete(session, previewId);
    await AiPreviewRecord.db.insertRow(
      session,
      AiPreviewRecord(
        previewId: previewId,
        userId: userId,
        fileUuid: fileUuid,
        previewJson: previewJson,
        changesJson: changesJson,
        createdAt: createdAt.toUtc(),
        expiresAt: expiresAt.toUtc(),
      ),
    );
    return true;
  }

  /// The stored preview [previewId]; null when unknown or expired (an
  /// expired row is deleted).
  static Future<AiPreviewRecord?> load(
    Session session,
    String previewId,
  ) async {
    final row = await AiPreviewRecord.db.findFirstRow(
      session,
      where: (t) => t.previewId.equals(previewId),
    );
    if (row == null) return null;
    if (row.expiresAt.isBefore(clock.now().toUtc())) {
      await AiPreviewRecord.db.deleteRow(session, row);
      return null;
    }
    return row;
  }

  /// Deletes the stored preview [previewId].
  static Future<void> delete(Session session, String previewId) async {
    await AiPreviewRecord.db.deleteWhere(
      session,
      where: (t) => t.previewId.equals(previewId),
    );
  }
}
