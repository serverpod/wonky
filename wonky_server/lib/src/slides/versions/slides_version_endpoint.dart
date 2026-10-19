import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../platform/comments/comment_copier.dart';
import '../../platform/common/models.dart';
import '../../platform/common/names.dart';
import '../../platform/drive/drive_copies.dart';
import '../../platform/users/user_service.dart';
import '../../platform/versions/version_service.dart';
import '../decks/deck_copies.dart';
import 'slides_version_provider.dart';

/// Slides extensions of version history (Slides 09 §4.2, §4.5): who changed
/// what in a version (author attribution of the diff) and *Make a copy*
/// of a version. Editors+ (suite 07 §5).
class SlidesVersionEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The `SlidesVersionChanges` JSON of a version (`{v, slides: {id:
  /// [userIds]}, elements, groups, theme, deck, agents, approx}`; latest
  /// author last). Versions captured before the index existed are computed
  /// from the change log on the fly.
  Future<String> changes(
    Session session,
    UuidValue itemUuid,
    int versionId,
  ) async {
    final actor = await UserService.actorOf(session);
    final (item, version) = await VersionService.requireVersion(
      session,
      actor,
      itemUuid,
      versionId,
      min: Role.editor,
    );
    final index = await SlidesSnapshotIndex.db.findFirstRow(
      session,
      where: (t) => t.itemVersionId.equals(version.id!),
    );
    final stored = index?.changesJson;
    if (stored != null && stored.startsWith('{')) return stored;
    return (await SlidesVersionProvider.changesOf(
      session,
      item,
      version,
    )).encode();
  }

  /// *Make a copy* of a version (09 §4.5): a new presentation with the
  /// version's content (new ids, uploaded images re-homed, the caller
  /// pays), in [folderUuid] (default: the deck's folder when the caller
  /// can edit it, else My Drive); optionally with the deck's comment
  /// threads (anchors remapped) and its sharing.
  Future<DriveItemView> makeCopy(
    Session session,
    UuidValue itemUuid,
    int versionId,
    String name,
    UuidValue? folderUuid,
    bool copyComments,
    bool copySharing,
  ) async {
    final actor = await UserService.actorOf(session);
    final (item, version) = await VersionService.requireVersion(
      session,
      actor,
      itemUuid,
      versionId,
      min: Role.editor,
    );
    final model = (await SlidesVersionProvider.snapshotOf(
      session,
      version,
    )).toModel();
    final copied = await DeckCopies.copy(
      session,
      actor,
      item,
      name: normalizeItemName(name),
      parentUuid:
          folderUuid ??
          await DriveCopies.defaultCopyParent(session, actor, item),
      description: item.description,
      sourceModel: model,
    );
    if (copyComments) {
      await CommentCopier.copyThreads(
        session,
        from: item,
        to: copied.item,
        anchorIdMap: copied.ids,
      );
    }
    return DriveCopies.finishCopy(
      session,
      actor,
      item,
      copied.item,
      copySharing,
    );
  }
}
