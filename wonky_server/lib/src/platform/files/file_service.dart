import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../config/wonky_config.dart';
import '../sharing/access_service.dart';
import '../storage/storage_service.dart';
import 'image_optimizer.dart';
import 'storage_reads.dart';

/// Files in cloud storage (suite 12 §1.1, specs/13 §1): upload descriptions
/// for client uploads with a client-chosen, idempotent [StoredFile.fileUuid],
/// type and size checks, signed download URLs and server-written files.
/// Images of documents, avatars and board screenshots are re-encoded as
/// WebP when they arrive ([ImageOptimizer], specs/12 §1.1 *Image
/// optimization*).
abstract final class FileService {
  static const signedUrlLifetime = Duration(minutes: 15);
  static const importLifetime = Duration(hours: 24);

  /// (specs/16 §5.3) An unattached board screenshot is deleted after this.
  static const boardScreenshotLifetime = Duration(days: 1);

  /// Board screenshots are PNG or JPEG only (specs/16 §5.3).
  static const boardScreenshotMimeTypes = {'image/png', 'image/jpeg'};

  static const imageMimeTypes = {
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  };

  static const importMimeTypes = {
    'text/markdown',
    'text/x-markdown',
    'text/plain',
    'text/html',
    'text/csv',
    'text/tab-separated-values',
    'application/rtf',
    'text/rtf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.oasis.opendocument.text',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-excel',
    'application/vnd.oasis.opendocument.spreadsheet',
    'application/octet-stream',
  };

  static int maxBytes(StoredFileKind kind) => switch (kind) {
    StoredFileKind.image => WonkyConfig.current.maxImageUploadBytes,
    StoredFileKind.avatar => 5 * 1024 * 1024,
    StoredFileKind.thumbnail => 2 * 1024 * 1024,
    StoredFileKind.importSource => WonkyConfig.current.maxImportUploadBytes,
    StoredFileKind.boardScreenshot => 5 * 1024 * 1024,
    _ => 0,
  };

  static String _storageFor(StoredFileKind kind) =>
      kind == StoredFileKind.avatar ? 'public' : 'private';

  static String _safeName(String name) {
    final base = name.split(RegExp(r'[\\/]')).last.trim();
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
    final short = cleaned.length > 120
        ? cleaned.substring(cleaned.length - 120)
        : cleaned;
    return short.isEmpty ? 'file' : short;
  }

  static Future<StoredFile?> byUuid(Session session, UuidValue fileUuid) =>
      StoredFile.db.findFirstRow(
        session,
        where: (t) => t.fileUuid.equals(fileUuid),
      );

  // --------------------------------------------------------------- upload

  static Future<FileUploadTicket> createUpload(
    Session session,
    Actor actor, {
    required UuidValue fileUuid,
    UuidValue? itemUuid,
    required String fileName,
    required String mimeType,
    required int size,
    StoredFileKind kind = StoredFileKind.image,
    ImageProfile? imageProfile,
  }) async {
    final mime = mimeType.toLowerCase().split(';').first.trim();
    if (imageProfile != null && kind != StoredFileKind.image) {
      throw Errors.invalid('Only images of documents have an image profile.');
    }
    switch (kind) {
      case StoredFileKind.image:
      case StoredFileKind.avatar:
      case StoredFileKind.thumbnail:
        if (!imageMimeTypes.contains(mime)) {
          throw Errors.invalid('Unsupported image type "$mime".');
        }
      case StoredFileKind.importSource:
        if (!importMimeTypes.contains(mime)) {
          throw Errors.invalid('Unsupported file type "$mime".');
        }
      case StoredFileKind.boardScreenshot:
        // No item, private storage, owner only until a post attaches it
        // (specs/16 §5.3); not counted toward the quota (Drive 03).
        if (!boardScreenshotMimeTypes.contains(mime)) {
          throw Errors.invalid('Screenshots must be PNG or JPEG.');
        }
        if (itemUuid != null) {
          throw Errors.invalid('Screenshots do not belong to an item.');
        }
      default:
        throw Errors.invalid('Files of this kind cannot be uploaded.');
    }
    final limit = maxBytes(kind);
    if (size <= 0) throw Errors.invalid('The file is empty.');
    if (size > limit) {
      throw Errors.tooLarge(
        'The file is too large (max ${limit ~/ (1024 * 1024)} MB).',
      );
    }
    DriveItem? item;
    if (itemUuid != null) {
      final (found, _) = await AccessService.require(
        session,
        actor,
        itemUuid,
        Role.editor,
      );
      item = found;
    } else if (kind == StoredFileKind.image ||
        kind == StoredFileKind.thumbnail) {
      throw Errors.invalid('Images and thumbnails belong to an item.');
    }

    final existing = await byUuid(session, fileUuid);
    if (existing != null) {
      if (existing.ownerId != actor.userId) {
        throw Errors.conflict('This file id is already in use.');
      }
      if (existing.status == StoredFileStatus.ready) {
        return FileUploadTicket(
          fileUuid: fileUuid,
          status: StoredFileStatus.ready,
        );
      }
      return FileUploadTicket(
        fileUuid: fileUuid,
        uploadDescription: await _description(session, existing),
        status: existing.status,
      );
    }
    final storageId = _storageFor(kind);
    final file = await session.db.transaction((tx) async {
      final row = await StoredFile.db.insertRow(
        session,
        StoredFile(
          fileUuid: fileUuid,
          ownerId: actor.userId,
          itemId: item?.id,
          kind: kind,
          storageId: storageId,
          path: 'files/${kind.name}/${fileUuid.uuid}/${_safeName(fileName)}',
          fileName: _safeName(fileName),
          mimeType: mime,
          sizeBytes: size,
          status: StoredFileStatus.pending,
          imageProfile: switch (kind) {
            StoredFileKind.image => imageProfile ?? ImageProfile.content,
            StoredFileKind.avatar => ImageProfile.avatar,
            StoredFileKind.boardScreenshot => ImageProfile.content,
            _ => null,
          },
          createdAt: nowUtc(),
          expiresAt: switch (kind) {
            StoredFileKind.importSource => nowUtc().add(importLifetime),
            StoredFileKind.boardScreenshot => nowUtc().add(
              boardScreenshotLifetime,
            ),
            _ => null,
          },
        ),
        transaction: tx,
      );
      // (v2) Images count for the item's owner, reserved before any byte
      // is sent (Drive 03 §5, §7.2).
      if (kind == StoredFileKind.image && item != null) {
        await StorageService.instance.reserve(
          session,
          userId: item.ownerId,
          fileUuid: fileUuid,
          itemId: item.id,
          bytes: size,
          reason: QuotaReason.image,
          callerUserId: actor.userId,
          transaction: tx,
        );
      }
      return row;
    });
    return FileUploadTicket(
      fileUuid: fileUuid,
      uploadDescription: await _description(session, file),
      status: StoredFileStatus.pending,
    );
  }

  static Future<String> _description(Session session, StoredFile file) =>
      session.storage.createUploadDescription(
        storageId: file.storageId,
        path: file.path,
        options: UploadOptions(
          maxFileSize: file.sizeBytes,
          expirationDuration: const Duration(minutes: 30),
        ),
      );

  /// Verifies the upload and marks the file ready (idempotent). Images
  /// with a [StoredFile.imageProfile] (and images of documents created
  /// before profiles existed) are re-encoded for it first:
  /// the file then points at the WebP (path, name, type and size) and the
  /// upload is deleted.
  static Future<FileUrlView> completeUpload(
    Session session,
    Actor actor,
    UuidValue fileUuid,
  ) async {
    final file = await byUuid(session, fileUuid);
    if (file == null || file.ownerId != actor.userId) {
      throw Errors.notFound('File');
    }
    if (file.status == StoredFileStatus.ready) {
      return _view(session, file);
    }
    final verified = await session.storage.verifyUpload(
      storageId: file.storageId,
      path: file.path,
    );
    if (!verified) {
      throw Errors.invalid('The upload has not finished yet.');
    }
    var status = StoredFileStatus.ready;
    var failure = 'The file content does not match its type.';
    if (imageMimeTypes.contains(file.mimeType)) {
      // The magic bytes only (CQ-30): never the whole object.
      final size = await StorageReads.length(session, file) ?? 0;
      final (head, _) = await StorageReads.sample(
        session,
        file,
        size: size,
        head: size < 64 ? size : 64,
        tail: 0,
      );
      if (sniffImage(head) != file.mimeType) {
        status = StoredFileStatus.failed;
        await session.storage.deleteFile(
          storageId: file.storageId,
          path: file.path,
        );
      }
    }
    var done = file;
    // Images of documents created before profiles existed are content.
    final profile =
        file.imageProfile ??
        (file.kind == StoredFileKind.image ? ImageProfile.content : null);
    if (status == StoredFileStatus.ready && profile != null) {
      try {
        final optimized = await ImageOptimizer.optimize(
          session,
          storageId: file.storageId,
          path: file.path,
          mimeType: file.mimeType,
          profile: profile,
        );
        if (optimized != null) {
          done = file.copyWith(
            path: optimized.path,
            fileName: optimized.fileName,
            mimeType: 'image/webp',
            sizeBytes: optimized.sizeBytes,
          );
        }
      } on UnreadableImageException catch (e) {
        session.log('Unreadable image ${file.fileUuid}: $e');
        status = StoredFileStatus.failed;
        failure = 'The image could not be read.';
        await session.storage.deleteFile(
          storageId: file.storageId,
          path: file.path,
        );
      }
    }
    final updated = await session.db.transaction((tx) async {
      final row = await StoredFile.db.updateRow(
        session,
        done.copyWith(status: status, completedAt: nowUtc()),
        columns: (t) => [
          t.status,
          t.completedAt,
          t.path,
          t.fileName,
          t.mimeType,
          t.sizeBytes,
        ],
        transaction: tx,
      );
      // (v2) Reserved → used (images, at their re-encoded size), or
      // released (Drive 03 §5).
      if (status == StoredFileStatus.ready) {
        await StorageService.instance.commitReservation(
          session,
          file.fileUuid,
          done.sizeBytes,
          transaction: tx,
        );
      } else {
        await StorageService.instance.releaseReservation(
          session,
          file.fileUuid,
          transaction: tx,
        );
      }
      return row;
    });
    if (done.path != file.path) {
      // Only now: the row no longer points at the upload.
      await _deleteObject(session, file.storageId, file.path);
    }
    if (status == StoredFileStatus.failed) {
      throw Errors.invalid(failure);
    }
    return _view(session, updated);
  }

  /// Detects the image type of documents from magic bytes (PNG, JPEG, GIF,
  /// WebP; no BMP).
  static String? sniffImage(Uint8List b) {
    bool starts(List<int> sig, [int at = 0]) {
      if (b.length < at + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[at + i] != sig[i]) return false;
      }
      return true;
    }

    if (starts([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return 'image/png';
    }
    if (starts([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (starts([0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    if (starts([0x52, 0x49, 0x46, 0x46]) &&
        starts([0x57, 0x45, 0x42, 0x50], 8)) {
      return 'image/webp';
    }
    return null;
  }

  // -------------------------------------------------------------- download

  static Future<bool> canRead(
    Session session,
    Actor actor,
    StoredFile file,
  ) async {
    if (file.ownerId == actor.userId) return true;
    if (file.kind == StoredFileKind.avatar) return true;
    if (file.itemId == null) return false;
    final item = await DriveItem.db.findById(session, file.itemId!);
    if (item == null) return false;
    final role = await AccessService.effectiveRole(session, actor.userId, item);
    return role != null;
  }

  static Future<FileUrlView> getUrl(
    Session session,
    Actor actor,
    UuidValue fileUuid,
  ) async {
    final file = await byUuid(session, fileUuid);
    if (file == null || !await canRead(session, actor, file)) {
      throw Errors.notFound('File');
    }
    return _view(session, file);
  }

  static Future<List<FileUrlView>> getUrls(
    Session session,
    Actor actor,
    List<UuidValue> fileUuids,
  ) async {
    final result = <FileUrlView>[];
    for (final uuid in fileUuids.toSet().take(200)) {
      final file = await byUuid(session, uuid);
      if (file == null || !await canRead(session, actor, file)) continue;
      result.add(await _view(session, file));
    }
    return result;
  }

  /// Status and signed URL of [file] without an access check: callers
  /// check access themselves (board screenshots, specs/16 §5.3).
  static Future<FileUrlView> viewOf(Session session, StoredFile file) =>
      _view(session, file);

  static Future<FileUrlView> _view(Session session, StoredFile file) async {
    String? url;
    DateTime? expires;
    if (file.status == StoredFileStatus.ready) {
      if (file.storageId == 'public') {
        url = (await session.storage.publicDownloadUrl(
          storageId: file.storageId,
          path: file.path,
        )).toString();
      } else {
        expires = nowUtc().add(signedUrlLifetime);
        url = (await session.storage.temporaryDownloadUrl(
          storageId: file.storageId,
          path: file.path,
          options: TemporaryDownloadUrlOptions(
            expirationDuration: signedUrlLifetime,
            downloadFileName: file.fileName,
            contentType: file.mimeType,
          ),
        )).toString();
      }
    }
    return FileUrlView(
      fileUuid: file.fileUuid,
      status: file.status,
      url: url,
      expiresAt: expires,
      fileName: file.fileName,
      mimeType: file.mimeType,
      sizeBytes: file.sizeBytes,
    );
  }

  /// Bytes of a ready file.
  static Future<ByteData> readBytes(Session session, StoredFile file) =>
      session.storage.retrieveFile(storageId: file.storageId, path: file.path);

  // ------------------------------------------------------- server writes

  /// Stores bytes written by the server (exports, snapshots, bytecode).
  /// With [optimize], an image ([StoredFileKind.image]) that enters a
  /// document (imports, MCP inserts, copies of Drive image files) is
  /// re-encoded like an upload ([ImageOptimizer], content profile); it is
  /// kept as given when that fails or the bytes aren't a readable image.
  static Future<StoredFile> storeServerFile(
    Session session, {
    required int? ownerId,
    int? itemId,
    required StoredFileKind kind,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    DateTime? expiresAt,
    UuidValue? fileUuid,
    bool optimize = false,
  }) async {
    final uuid = fileUuid ?? const Uuid().v7obj();
    final path = 'files/${kind.name}/${uuid.uuid}/${_safeName(fileName)}';
    await session.storage.storeFile(
      storageId: 'private',
      path: path,
      byteData: ByteData.sublistView(bytes),
    );
    final profile = optimize && kind == StoredFileKind.image
        ? ImageProfile.content
        : null;
    OptimizedImage? optimized;
    if (profile != null) {
      try {
        optimized = await ImageOptimizer.optimize(
          session,
          storageId: 'private',
          path: path,
          mimeType: mimeType,
          profile: profile,
        );
      } on UnreadableImageException catch (e) {
        session.log('Unreadable image $uuid kept as given: $e');
      }
      if (optimized != null) await _deleteObject(session, 'private', path);
    }
    final now = nowUtc();
    return StoredFile.db.insertRow(
      session,
      StoredFile(
        fileUuid: uuid,
        ownerId: ownerId,
        itemId: itemId,
        kind: kind,
        storageId: 'private',
        path: optimized?.path ?? path,
        fileName: optimized?.fileName ?? _safeName(fileName),
        mimeType: optimized == null ? mimeType : 'image/webp',
        sizeBytes: optimized?.sizeBytes ?? bytes.length,
        status: StoredFileStatus.ready,
        imageProfile: profile,
        createdAt: now,
        completedAt: now,
        expiresAt: expiresAt,
      ),
    );
  }

  static Future<StoredFile> requireOwnReadyFile(
    Session session,
    Actor actor,
    UuidValue fileUuid, {
    StoredFileKind? kind,
  }) async {
    final file = await byUuid(session, fileUuid);
    if (file == null ||
        file.ownerId != actor.userId ||
        (kind != null && file.kind != kind)) {
      throw Errors.notFound('File');
    }
    if (file.status != StoredFileStatus.ready) {
      throw Errors.invalid('The upload is not complete.');
    }
    return file;
  }

  static Future<void> attachToItem(
    Session session,
    StoredFile file,
    DriveItem item,
  ) async {
    if (file.itemId == item.id) return;
    await StoredFile.db.updateRow(
      session,
      file.copyWith(itemId: item.id),
      columns: (t) => [t.itemId],
    );
  }

  /// (v2, Slides 03 A-03-3) Copies the stored image [sourceFileUuid] into
  /// [targetItemUuid] as [newFileUuid] (cross-deck paste, deck copies,
  /// *Insert image from Drive*): the caller must be able to read the
  /// source (its item or own upload) and edit the target; the bytes count
  /// against the target owner's quota (attachment bytes). Idempotent on
  /// [newFileUuid]: a copy that already exists for the same target is
  /// returned as is.
  static Future<FileUrlView> copyToItem(
    Session session,
    Actor actor, {
    required UuidValue sourceFileUuid,
    required UuidValue newFileUuid,
    required UuidValue targetItemUuid,
  }) async {
    final (target, _) = await AccessService.require(
      session,
      actor,
      targetItemUuid,
      Role.editor,
    );
    final existing = await byUuid(session, newFileUuid);
    if (existing != null) {
      if (existing.itemId != target.id) {
        throw Errors.conflict('This file id is already in use.');
      }
      return _view(session, existing);
    }
    final source = await byUuid(session, sourceFileUuid);
    // Images of documents, and image files of Wonky Drive (*Insert image
    // ▸ From Wonky Drive*, Slides 03 §6.5.1).
    final copyable =
        source != null &&
        (source.kind == StoredFileKind.image ||
            (source.kind == StoredFileKind.driveFile &&
                imageMimeTypes.contains(source.mimeType)));
    if (source == null || !copyable || !await canRead(session, actor, source)) {
      throw Errors.notFound('File');
    }
    if (source.status != StoredFileStatus.ready) {
      throw Errors.invalid('The file is not uploaded yet.');
    }
    await StorageService.instance.checkRoom(
      session,
      userId: target.ownerId,
      bytes: source.sizeBytes,
      reason: QuotaReason.copy,
      callerUserId: actor.userId,
    );
    final bytes = await readBytes(session, source);
    final copy = await storeServerFile(
      session,
      ownerId: actor.userId,
      itemId: target.id,
      kind: StoredFileKind.image,
      fileName: source.fileName,
      mimeType: source.mimeType,
      bytes: bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      fileUuid: newFileUuid,
      // Images of documents are WebP already; Drive files are as uploaded.
      optimize: source.kind == StoredFileKind.driveFile,
    );
    try {
      await StorageService.instance.addAttachment(
        session,
        target,
        copy.sizeBytes,
      );
    } on Object {
      // Not charged (CQ-34): the copy must not stay behind untracked.
      await _deleteStored(session, copy);
      rethrow;
    }
    return _view(session, copy);
  }

  static Future<void> deleteFile(Session session, UuidValue fileUuid) async {
    final file = await byUuid(session, fileUuid);
    if (file == null) return;
    await _deleteStored(session, file);
  }

  static Future<void> _deleteStored(Session session, StoredFile file) async {
    await _deleteObject(session, file.storageId, file.path);
    await StoredFile.db.deleteRow(session, file);
    // (v2) Abandoned uploads give their reserved quota back.
    await StorageService.instance.releaseReservation(session, file.fileUuid);
  }

  /// Deletes the object at [path] (logged when that fails).
  static Future<void> _deleteObject(
    Session session,
    String storageId,
    String path,
  ) async {
    try {
      await session.storage.deleteFile(storageId: storageId, path: path);
    } on Exception catch (e) {
      session.log('Could not delete $path: $e', level: LogLevel.warning);
    }
  }

  /// Deletes the stored files belonging to [itemIds] (before deleting the
  /// items, whose rows would cascade without removing the bytes).
  static Future<void> deleteFilesOfItems(
    Session session,
    Set<int> itemIds,
  ) async {
    if (itemIds.isEmpty) return;
    final files = await StoredFile.db.find(
      session,
      where: (t) => t.itemId.inSet(itemIds),
    );
    for (final f in files) {
      await _deleteStored(session, f);
    }
  }

  /// Files deleted per query of [cleanupExpired].
  static const cleanupBatch = 1000;

  /// Hourly job: deletes expired files (imports, exports) and abandoned
  /// pending uploads older than a day, in batches until none are left or
  /// [budget] is spent. Returns the count. The two conditions are separate
  /// queries, each on its own index (`stored_file_expiry_idx`,
  /// `stored_file_status_idx`): an OR of both could use neither.
  static Future<int> cleanupExpired(
    Session session, {
    DateTime? now,
    Duration budget = const Duration(minutes: 5),
  }) async {
    final at = now ?? nowUtc();
    final watch = Stopwatch()..start();
    final queries = <Future<List<StoredFile>> Function(Set<int> skip)>[
      (skip) => StoredFile.db.find(
        session,
        where: (t) => (t.expiresAt < at) & t.id.notInSet(skip),
        limit: cleanupBatch,
      ),
      (skip) => StoredFile.db.find(
        session,
        where: (t) =>
            t.status.equals(StoredFileStatus.pending) &
            (t.createdAt < at.subtract(const Duration(days: 1))) &
            t.id.notInSet(skip),
        limit: cleanupBatch,
      ),
    ];
    // Files whose deletion failed this run (not offered again).
    final failed = <int>{};
    var count = 0;
    for (final query in queries) {
      while (watch.elapsed < budget) {
        final batch = await query(failed);
        if (batch.isEmpty) break;
        for (final f in batch) {
          try {
            await _deleteStored(session, f);
            count++;
          } on Object catch (e, st) {
            failed.add(f.id!);
            session.log(
              'Deleting stored file ${f.fileUuid} failed: $e',
              level: LogLevel.warning,
              stackTrace: st,
            );
          }
        }
        if (batch.length < cleanupBatch) break;
      }
    }
    return count;
  }
}
