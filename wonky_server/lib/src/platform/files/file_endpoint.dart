import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../users/user_service.dart';
import 'file_image_proxy.dart';
import 'file_service.dart';

/// Uploads and signed downloads (suite 12 §1.1). Idempotent on the
/// client-generated [fileUuid]; content may reference `wonky-file://<uuid>`
/// before the bytes arrive.
class FileEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Upload description for `FileUploader`. [kind] defaults to image;
  /// imports use `importSource` without an item. Images are re-encoded as
  /// WebP on completion for [imageProfile] (default `content`; a story's
  /// cover uses `cover`).
  Future<FileUploadTicket> createUpload(
    Session session,
    UuidValue fileUuid,
    UuidValue? itemUuid,
    String fileName,
    String mimeType,
    int size, {
    StoredFileKind? kind,
    ImageProfile? imageProfile,
  }) async => FileService.createUpload(
    session,
    await UserService.actorOf(session),
    fileUuid: fileUuid,
    itemUuid: itemUuid,
    fileName: fileName,
    mimeType: mimeType,
    size: size,
    kind: kind ?? StoredFileKind.image,
    imageProfile: imageProfile,
  );

  Future<FileUrlView> completeUpload(
    Session session,
    UuidValue fileUuid,
  ) async => FileService.completeUpload(
    session,
    await UserService.actorOf(session),
    fileUuid,
  );

  /// Status and signed URL (15 min) of a file.
  Future<FileUrlView> getUrl(Session session, UuidValue fileUuid) async =>
      FileService.getUrl(session, await UserService.actorOf(session), fileUuid);

  /// (v2, Slides 03 A-03-3) Copies an image the caller can read into
  /// [targetItemUuid] as [newFileUuid] (idempotent on [newFileUuid];
  /// quota of the target's owner). Errors: notFound, forbidden,
  /// quotaExceeded, conflict.
  Future<FileUrlView> copyToItem(
    Session session,
    UuidValue sourceFileUuid,
    UuidValue newFileUuid,
    UuidValue targetItemUuid,
  ) async => FileService.copyToItem(
    session,
    await UserService.actorOf(session),
    sourceFileUuid: sourceFileUuid,
    newFileUuid: newFileUuid,
    targetItemUuid: targetItemUuid,
  );

  /// (v2, Slides 03 A-03-4) Image proxy for images inserted by URL into
  /// drive item [itemUuid] (any app; caller needs viewer access): the bytes
  /// of the https image [url]. Private addresses, other ports, redirects
  /// and non-images are refused; ≤ 10 MB. The client stores the bytes as
  /// an ordinary (offline-first, quota-checked) upload.
  Future<ByteData> fetchImage(
    Session session,
    UuidValue itemUuid,
    String url,
  ) async => FileImageProxy.fetch(
    session,
    await UserService.actorOf(session),
    itemUuid,
    url,
  );

  Future<List<FileUrlView>> getUrls(
    Session session,
    List<UuidValue> fileUuids,
  ) async => FileService.getUrls(
    session,
    await UserService.actorOf(session),
    fileUuids,
  );
}
