import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/sharing/access_service.dart';

/// Per-user script properties of a spreadsheet (RevLog spec 02 §2.4,
/// Sheets 09 §6.9): a server table, private per user, read and written by
/// the user's scripts on the client (`sheets.getUserProperties` /
/// `setUserProperties`) and on the server ([ServerUserProperties]).
abstract final class ScriptUserProperties {
  /// Max properties per user and spreadsheet.
  static const maxEntries = 500;

  /// Max bytes of one value.
  static const maxValueLength = 9 * 1024;

  static Future<void> _requireViewer(
    Session session,
    Actor actor,
    UuidValue fileUuid,
  ) async {
    final item = await DriveItem.db.findFirstRow(
      session,
      where: (t) =>
          t.contentRef.equals(fileUuid) &
          t.kind.equals(DriveItemKind.spreadsheet),
    );
    if (item == null) throw Errors.notFound('Spreadsheet');
    await AccessService.requireRole(session, actor, item, Role.viewer);
  }

  /// The properties of [actor] for [fileUuid].
  static Future<Map<String, String>> read(
    Session session,
    Actor actor,
    UuidValue fileUuid,
  ) async {
    await _requireViewer(session, actor, fileUuid);
    return load(session, userId: actor.userId, fileUuid: fileUuid);
  }

  /// The stored properties of [userId] for [fileUuid] (no access check).
  static Future<Map<String, String>> load(
    Session session, {
    required int userId,
    required UuidValue fileUuid,
  }) async {
    final rows = await ScriptUserProperty.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.fileUuid.equals(fileUuid),
      orderBy: (t) => t.key,
    );
    return {for (final r in rows) r.key: r.value};
  }

  /// Applies [changes] (null = delete) for [actor].
  static Future<void> write(
    Session session,
    Actor actor,
    UuidValue fileUuid,
    Map<String, String?> changes,
  ) async {
    await _requireViewer(session, actor, fileUuid);
    await apply(
      session,
      userId: actor.userId,
      fileUuid: fileUuid,
      changes: changes,
    );
  }

  /// Applies [changes] for [userId] in one transaction (no access check).
  static Future<void> apply(
    Session session, {
    required int userId,
    required UuidValue fileUuid,
    required Map<String, String?> changes,
  }) async {
    if (changes.isEmpty) return;
    for (final e in changes.entries) {
      if (e.key.isEmpty || e.key.length > 256) {
        throw Errors.invalid('Property names are 1 to 256 characters.');
      }
      if ((e.value?.length ?? 0) > maxValueLength) {
        throw Errors.tooLarge('A property value is limited to 9 KB.');
      }
    }
    await session.db.transaction((tx) async {
      final now = clock.now().toUtc();
      for (final e in changes.entries) {
        final value = e.value;
        if (value == null) {
          await ScriptUserProperty.db.deleteWhere(
            session,
            where: (t) =>
                t.userId.equals(userId) &
                t.fileUuid.equals(fileUuid) &
                t.key.equals(e.key),
            transaction: tx,
          );
          continue;
        }
        await session.db.unsafeExecute(
          'INSERT INTO script_user_property ("userId", "fileUuid", key, value, '
          '"updatedAt") VALUES (@u, @f::uuid, @k, @v, @at) '
          'ON CONFLICT ("userId", "fileUuid", key) DO UPDATE '
          'SET value = EXCLUDED.value, "updatedAt" = EXCLUDED."updatedAt"',
          parameters: QueryParameters.named({
            'u': userId,
            'f': fileUuid.uuid,
            'k': e.key,
            'v': value,
            'at': now,
          }),
          transaction: tx,
        );
      }
      final count = await ScriptUserProperty.db.count(
        session,
        where: (t) => t.userId.equals(userId) & t.fileUuid.equals(fileUuid),
        transaction: tx,
      );
      if (count > maxEntries) {
        throw Errors.limit(
          'A script can store at most $maxEntries properties.',
        );
      }
    });
  }
}
