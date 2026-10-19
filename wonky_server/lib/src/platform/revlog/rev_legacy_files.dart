import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../common/actor.dart';
import '../common/models.dart';
import '../drive/drive_trash.dart';
import '../sharing/access_service.dart';
import 'rev_binding.dart';

/// Spreadsheets and decks from before RevLog (17 §As built #26): their drive
/// items survived the migration, their data did not, so they can't be
/// opened. Opening one removes it.
abstract final class RevLegacyFiles {
  /// When [fileUuid] has no `rev_file` but names a drive item of
  /// [binding]'s kind that [actor] can see, deletes that item (and its
  /// shares, stars and stored files) for everyone. Returns whether it did.
  ///
  /// New items are inserted in the same transaction as their `rev_file`
  /// (`DriveService.createSheetsFile`, `SlidesDecks.createFile`), so an
  /// item without one is always a pre-RevLog leftover.
  static Future<bool> removeIfLegacy(
    Session session,
    RevBinding binding,
    Actor actor,
    UuidValue fileUuid,
  ) async {
    // Decks without a content ref use the item uuid as file uuid (Slides
    // 02 §9.3).
    final item = await DriveItem.db.findFirstRow(
      session,
      where: (t) =>
          t.kind.equals(binding.itemKind) &
          (t.contentRef.equals(fileUuid) |
              (t.contentRef.equals(null) & t.uuid.equals(fileUuid))),
    );
    if (item == null) return false;
    final files = await RevFile.db.count(
      session,
      where: (t) => t.itemId.equals(item.id!),
    );
    if (files > 0) return false;
    try {
      await AccessService.requireRole(session, actor, item, Role.viewer);
    } on Object {
      // Not for this user to see, let alone remove.
      return false;
    }
    await DriveTrash.purge(session, item);
    session.log(
      'Removed the pre-RevLog ${item.kind.name} ${item.uuid} on open.',
      level: LogLevel.info,
    );
    return true;
  }
}
