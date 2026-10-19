import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../common/models.dart';
import '../sharing/access_service.dart';
import '../storage/storage_listing.dart';
import '../storage/storage_service.dart';
import '../users/user_service.dart';
import 'drive_events.dart';
import 'drive_file_service.dart';
import 'drive_presentations.dart';
import 'drive_service.dart';
import 'drive_templates.dart';
import 'drive_trash.dart';
import 'drive_user_state.dart';
import 'drive_copies.dart';
import 'import_service.dart';

/// Wonky Drive (specs/05 §2).
class DriveEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Children of a folder (null = My Drive root) or a virtual view.
  Future<DriveListPage> list(
    Session session,
    UuidValue? folderUuid,
    DriveListFilter filter,
    DriveSort sort,
    String? cursor,
    int limit,
  ) async => DriveService.list(
    session,
    await UserService.actorOf(session),
    folderUuid: folderUuid,
    filter: filter,
    sort: sort,
    cursor: cursor,
    limit: limit,
  );

  Future<DriveItemView> get(Session session, UuidValue uuid) async =>
      DriveService.get(session, await UserService.actorOf(session), uuid);

  /// Breadcrumb ancestors visible to the caller, root first.
  Future<List<DriveItemView>> path(Session session, UuidValue uuid) async =>
      DriveService.path(session, await UserService.actorOf(session), uuid);

  Future<DriveListPage> search(
    Session session,
    String query,
    DriveSearchFilters filters,
    String? cursor,
    int limit,
  ) async => DriveService.search(
    session,
    await UserService.actorOf(session),
    query,
    filters: filters,
    cursor: cursor,
    limit: limit,
  );

  Future<DriveItemView> createFolder(
    Session session,
    UuidValue? parentUuid,
    String name,
  ) async => DriveService.createFolder(
    session,
    await UserService.actorOf(session),
    parentUuid: parentUuid,
    name: name,
  );

  /// Creates a document; idempotent on the client-generated [documentUuid]
  /// and [itemUuid] (offline creation).
  Future<DriveItemView> createDocument(
    Session session,
    UuidValue? parentUuid,
    String name,
    UuidValue? templateUuid,
    String? initialMarkdown, {
    UuidValue? documentUuid,
    UuidValue? itemUuid,
  }) async => DriveService.createDocument(
    session,
    await UserService.actorOf(session),
    parentUuid: parentUuid,
    name: name,
    templateUuid: templateUuid,
    initialMarkdown: initialMarkdown,
    documentUuid: documentUuid,
    itemUuid: itemUuid,
  );

  /// Registers a spreadsheet created locally in a reserved space
  /// (idempotent).
  Future<DriveItemView> registerSpreadsheet(
    Session session,
    UuidValue spaceUuid,
    UuidValue? parentUuid,
    String name,
  ) async => DriveService.registerSpreadsheet(
    session,
    await UserService.actorOf(session),
    spaceUuid: spaceUuid,
    parentUuid: parentUuid,
    name: name,
  );

  /// Creates a spreadsheet server-side (space + rows).
  Future<DriveItemView> createSpreadsheet(
    Session session,
    UuidValue? parentUuid,
    String name,
    UuidValue? templateUuid, {
    String? locale,
    String? timeZone,
  }) async => DriveService.createSpreadsheet(
    session,
    await UserService.actorOf(session),
    parentUuid: parentUuid,
    name: name,
    templateUuid: templateUuid,
    locale: locale,
    timeZone: timeZone,
  );

  Future<DriveItemView> rename(
    Session session,
    UuidValue uuid,
    String name,
  ) async => DriveService.rename(
    session,
    await UserService.actorOf(session),
    uuid,
    name,
  );

  Future<DriveItemView> updateDescription(
    Session session,
    UuidValue uuid,
    String? description,
  ) async => DriveService.updateDescription(
    session,
    await UserService.actorOf(session),
    uuid,
    description,
  );

  /// Moves items into [newParentUuid] (null = My Drive root, owners only).
  Future<List<DriveItemView>> move(
    Session session,
    List<UuidValue> uuids,
    UuidValue? newParentUuid,
  ) async => DriveService.move(
    session,
    await UserService.actorOf(session),
    uuids,
    newParentUuid,
  );

  Future<DriveItemView> copy(
    Session session,
    UuidValue uuid,
    String newName,
    UuidValue? parentUuid,
    bool copyComments,
    bool copySharing,
  ) async => DriveCopies.copy(
    session,
    await UserService.actorOf(session),
    uuid,
    newName: newName,
    parentUuid: parentUuid,
    copyComments: copyComments,
    copySharing: copySharing,
  );

  Future<DriveItemView> setStarred(
    Session session,
    UuidValue uuid,
    bool starred,
  ) async => DriveUserStates.setStarred(
    session,
    await UserService.actorOf(session),
    uuid,
    starred,
  );

  Future<DriveItemView> setPinnedOffline(
    Session session,
    UuidValue uuid,
    bool pinned,
  ) async => DriveUserStates.setPinnedOffline(
    session,
    await UserService.actorOf(session),
    uuid,
    pinned,
  );

  /// Records that the caller opened the item (Recent; link visits appear in
  /// Shared with me).
  Future<DriveItemView> markOpened(Session session, UuidValue uuid) async =>
      DriveUserStates.markOpened(
        session,
        await UserService.actorOf(session),
        uuid,
      );

  /// "Add shortcut to My Drive" ([parentUuid] null = root).
  Future<DriveItemView> addShortcut(
    Session session,
    UuidValue uuid,
    UuidValue? parentUuid,
  ) async => DriveUserStates.addShortcut(
    session,
    await UserService.actorOf(session),
    uuid,
    parentUuid,
  );

  Future<void> removeShortcut(Session session, UuidValue uuid) async =>
      DriveUserStates.removeShortcut(
        session,
        await UserService.actorOf(session),
        uuid,
      );

  Future<void> trash(Session session, List<UuidValue> uuids) async =>
      DriveTrash.trash(session, await UserService.actorOf(session), uuids);

  Future<void> restore(Session session, List<UuidValue> uuids) async =>
      DriveTrash.restore(session, await UserService.actorOf(session), uuids);

  Future<void> deletePermanently(
    Session session,
    List<UuidValue> uuids,
  ) async => DriveTrash.deletePermanently(
    session,
    await UserService.actorOf(session),
    uuids,
  );

  /// Deletes all owned items in the trash; returns how many.
  Future<int> emptyTrash(Session session) async =>
      DriveTrash.emptyTrash(session, await UserService.actorOf(session));

  /// Live changes of items visible to the caller.
  Stream<DriveChange> watch(Session session) async* {
    final actor = await UserService.actorOf(session);
    yield* DriveEvents.watch(session, actor);
  }

  /// Template gallery ([kind] null = all kinds).
  Future<List<TemplateView>> listTemplates(
    Session session,
    DriveItemKind? kind,
  ) async => DriveTemplates.listTemplates(
    session,
    await UserService.actorOf(session),
    kind,
  );

  /// Publishes an owned item as a template ([category] null = unpublish).
  Future<DriveItemView> setTemplate(
    Session session,
    UuidValue uuid,
    TemplateCategory? category,
  ) async => DriveTemplates.setTemplate(
    session,
    await UserService.actorOf(session),
    uuid,
    category,
  );

  /// Imports an uploaded file (`file.createUpload` with kind importSource)
  /// as a new item.
  Future<ImportReportView> import(
    Session session,
    UuidValue uploadId,
    DriveItemKind kind,
    DriveImportOptions options,
  ) async => ImportService.import(
    session,
    await UserService.actorOf(session),
    uploadId,
    kind,
    options,
  );

  // ---------------------------------------------------------------- v2 (M8)
  // Drive 02 §3.3 (files, D-8), Slides 02 §9.3 (presentations, D-8) and
  // 03 §7.2 (quota, D-9).

  /// Registers a deck created on a device (idempotent; Slides 02 §9.3):
  /// `createPresentation(fileUuid: spaceUuid, initialize: false)`; the
  /// client's first op creates the rows (RevLog spec 04 §5). The item uuid
  /// is the file uuid. Never refused for quota.
  Future<DriveItemView> registerPresentation(
    Session session,
    UuidValue spaceUuid,
    UuidValue? parentUuid,
    String name,
  ) async => DrivePresentations.register(
    session,
    await UserService.actorOf(session),
    spaceUuid: spaceUuid,
    parentUuid: parentUuid,
    name: name,
  );

  /// Creates a presentation server-side (online; Slides 02 §9.3): a blank
  /// deck with the default theme and a title slide, or with [templateUuid]
  /// a copy of that presentation (SL-8; built-in presentation templates:
  /// SL-22). With [fileUuid] the call is idempotent; [initialize] false
  /// (default true) leaves the file at revision 0 for the client's creation op (RevLog
  /// spec 04 §5).
  Future<DriveItemView> createPresentation(
    Session session,
    UuidValue? parentUuid,
    String name,
    UuidValue? templateUuid, {
    UuidValue? fileUuid,
    bool? initialize,
  }) async => DrivePresentations.create(
    session,
    await UserService.actorOf(session),
    parentUuid: parentUuid,
    name: name,
    templateUuid: templateUuid,
    fileUuid: fileUuid,
    initialize: initialize ?? true,
  );

  /// Starts the upload of a `file` item (Drive 02 §3.3): checks the role on
  /// the parent (Editor+), name, size ≤ `maxFileUploadBytes` and reserves
  /// quota; inserts the item (`uploading`) and its `driveFile` StoredFile.
  /// Idempotent on (itemUuid, fileUuid). Errors: forbidden, notFound,
  /// invalidArgument, tooLarge, quotaExceeded, limitExceeded, conflict.
  Future<FileUploadStart> createFileUpload(
    Session session,
    FileUploadRequest request,
  ) async => DriveFileService.createUpload(
    session,
    await UserService.actorOf(session),
    request,
  );

  /// Verifies the stored bytes (size, sniffing), marks the item `ready` and
  /// turns the reservation into usage (Drive 02 §3.3).
  Future<DriveItemView> completeFileUpload(
    Session session,
    UuidValue itemUuid,
  ) async => DriveFileService.completeUpload(
    session,
    await UserService.actorOf(session),
    itemUuid,
  );

  /// Cancels an upload: deletes the item and partial bytes, releases the
  /// reservation.
  Future<void> cancelFileUpload(Session session, UuidValue itemUuid) async =>
      DriveFileService.cancelUpload(
        session,
        await UserService.actorOf(session),
        itemUuid,
      );

  /// Upload state for resuming (Drive 02 §4.3).
  Future<FileUploadProgress> fileUploadStatus(
    Session session,
    UuidValue itemUuid,
  ) async => DriveFileService.status(
    session,
    await UserService.actorOf(session),
    itemUuid,
  );

  /// *Open with* on the server (Drive 02 §7.2): imports a `file` item's
  /// bytes as a [target] item (document or spreadsheet). Viewer+ on the
  /// file, Editor+ on the target folder (else My Drive); quota checked
  /// before and after (Drive 03 §7.2).
  Future<ImportReportView> convertFile(
    Session session,
    UuidValue fileItemUuid,
    DriveItemKind target,
    DriveImportOptions options,
  ) async => DriveFileService.convert(
    session,
    await UserService.actorOf(session),
    fileItemUuid,
    target,
    options,
  );

  /// A signed URL (15 min) of a file item's bytes for previews, or with
  /// [download] the `GET /files/d/…` download route (Drive 02 §6.1, §8).
  Future<FileUrlView> fileContentUrl(
    Session session,
    UuidValue itemUuid, {
    bool download = false,
  }) async => DriveFileService.contentUrl(
    session,
    await UserService.actorOf(session),
    itemUuid,
    download: download,
  );

  /// Client-measured metadata of a file item (e.g. PDF `{pages}`), Editor+
  /// (Drive 02 §6.3).
  Future<DriveItemView> updateFileMeta(
    Session session,
    UuidValue itemUuid,
    String fileMetaJson,
  ) async => DriveFileService.updateMeta(
    session,
    await UserService.actorOf(session),
    itemUuid,
    fileMetaJson,
  );

  /// Quota pre-check without reserving (Drive 03 §7.2): throws
  /// `quotaExceeded` when [bytes] don't fit. With [itemUuid], the item's
  /// owner is charged (images added to someone else's item); else the
  /// caller.
  Future<void> checkRoom(
    Session session,
    int bytes,
    UuidValue? itemUuid,
  ) async {
    final actor = await UserService.actorOf(session);
    var userId = actor.userId;
    if (itemUuid != null) {
      final (item, _) = await AccessService.require(
        session,
        actor,
        itemUuid,
        Role.viewer,
      );
      userId = item.ownerId;
    }
    await StorageService.instance.checkRoom(
      session,
      userId: userId,
      bytes: bytes,
      reason: itemUuid == null ? QuotaReason.import : QuotaReason.image,
      callerUserId: actor.userId,
    );
  }

  /// The caller's owned items (incl. trashed) by counted size, descending
  /// (Storage page, Drive 03 §6.4). Pass `nextCursor` for the next page.
  Future<DriveListPage> listByStorage(
    Session session,
    StorageListFilter filter,
    String? cursor,
    int limit,
  ) async => StorageListing.list(
    session,
    await UserService.actorOf(session),
    filter,
    cursor: cursor,
    limit: limit,
  );

  Future<StorageUsage> storageUsage(Session session) async =>
      DriveService.storageUsage(session, await UserService.actorOf(session));

  /// Sets a client-rendered thumbnail (uploaded with kind thumbnail).
  Future<DriveItemView> setThumbnail(
    Session session,
    UuidValue uuid,
    UuidValue uploadedFileUuid,
  ) async => DriveService.setThumbnail(
    session,
    await UserService.actorOf(session),
    uuid,
    uploadedFileUuid,
  );

  /// The activity feed of an item, newest first.
  Future<List<ActivityEventView>> activity(
    Session session,
    UuidValue uuid,
    int? beforeId,
    int limit,
  ) async => DriveService.activity(
    session,
    await UserService.actorOf(session),
    uuid,
    beforeId: beforeId,
    limit: limit,
  );
}
