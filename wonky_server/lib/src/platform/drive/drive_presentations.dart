import 'package:serverpod/serverpod.dart';

import '../../slides/decks/slides_decks.dart';
import '../common/actor.dart';
import '../common/models.dart';

/// (v2) Drive items of Wonky Slides decks (Slides 02 §9.3, RevLog spec
/// 04 §5).
abstract final class DrivePresentations {
  /// Registers a deck created on a device (idempotent; queued offline
  /// creations): `createPresentation(fileUuid, initialize: false)`, whose
  /// first client op creates the rows. The item uuid is the file uuid.
  /// Never refused for quota (Drive 03 §7.2). A parent folder that is gone
  /// or no longer editable puts the deck in My Drive.
  static Future<DriveItemView> register(
    Session session,
    Actor actor, {
    required UuidValue spaceUuid,
    UuidValue? parentUuid,
    required String name,
  }) async {
    try {
      return await create(
        session,
        actor,
        parentUuid: parentUuid,
        name: name,
        fileUuid: spaceUuid,
        initialize: false,
      );
    } on WonkyException catch (e) {
      // The folder was deleted or unshared while offline: use the root.
      if (parentUuid == null || e.code == WonkyErrorCode.conflict) rethrow;
      if (e.code == WonkyErrorCode.forbidden &&
          await DriveItem.db.findFirstRow(
                session,
                where: (t) => t.contentRef.equals(spaceUuid),
              ) !=
              null) {
        rethrow;
      }
      return create(
        session,
        actor,
        name: name,
        fileUuid: spaceUuid,
        initialize: false,
      );
    }
  }

  /// Creates a deck server-side (`drive.createPresentation`, Slides 02
  /// §9.3, RevLog spec 04 §5).
  static Future<DriveItemView> create(
    Session session,
    Actor actor, {
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
    String? themeKey,
    UuidValue? fileUuid,
    bool initialize = true,
  }) => SlidesDecks.create(
    session,
    actor,
    parentUuid: parentUuid,
    name: name,
    templateUuid: templateUuid,
    themeKey: themeKey,
    fileUuid: fileUuid,
    initialize: initialize,
  );
}
