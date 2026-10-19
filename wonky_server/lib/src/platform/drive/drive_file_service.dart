import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/files.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../sheets/imports/sheets_import_service.dart';
import '../../write/export/write_import_service.dart';
import '../activity/activity_service.dart';
import '../cluster/cluster.dart';
import '../cluster/cluster_bus.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../config/wonky_config.dart';
import '../files/file_names.dart';
import '../files/file_preview_service.dart';
import '../files/file_type_sniffer.dart';
import '../files/storage_reads.dart';
import '../files/file_url_tokens.dart';
import '../sharing/access_service.dart';
import '../storage/storage_service.dart';
import 'drive_events.dart';
import 'drive_file_filters.dart';
import 'drive_service.dart';
import 'drive_views.dart';
import 'kind_masks.dart';

/// (v2) Uploaded files as drive items (Drive 02): the upload lifecycle
/// (`createFileUpload` → bytes → `completeFileUpload`, cancel, status,
/// 24 h expiry), sniffing, content and download URLs, client metadata,
/// *Open with* conversions and server-side copies. Quota goes through
/// [StorageService] (reserve / commit / release, Drive 03 §5).
abstract final class DriveFileService {
  /// Uploads still `uploading` after this are deleted (`drive.expireUploads`).
  static const uploadLifetime = Duration(hours: 24);

  /// Lifetime of a Serverpod upload description.
  static const uploadDescriptionLifetime = Duration(minutes: 30);

  /// The storage of uploaded files.
  static const storageId = 'private';

  /// Largest `fileMetaJson` accepted from clients.
  static const maxMetaJsonChars = 4096;

  /// Keys a client may set with `updateFileMeta` (Drive 02 §1.1).
  static const clientMetaKeys = {
    'width',
    'height',
    'pages',
    'lines',
    'encoding',
    'durationMs',
    'encrypted',
  };

  static String _path(Actor actor, UuidValue fileUuid, String name) =>
      'drive/${actor.authUserId.uuid}/${fileUuid.uuid}/${FileNames.ascii(name)}';

  // --------------------------------------------------------------- create

  static Future<FileUploadStart> createUpload(
    Session session,
    Actor actor,
    FileUploadRequest request,
  ) async {
    final config = WonkyConfig.current;
    if (request.sizeBytes < 0) throw Errors.invalid('The size is invalid.');
    if (request.sizeBytes > config.maxFileUploadBytes) {
      throw Errors.tooLarge(
        'Files can be at most '
        '${formatStorageBytes(config.maxFileUploadBytes)}.',
      );
    }
    final existing = await AccessService.findItem(session, request.itemUuid);
    if (existing != null) return _retry(session, actor, existing, request);
    final reused = await StoredFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(request.fileUuid),
    );
    if (reused != null) {
      throw Errors.conflict('This file id is already in use.');
    }
    var name = FileNames.sanitize(request.name);
    if (request.conflict == UploadConflictMode.replace) {
      throw Errors.unavailable('Replacing files is not available yet.');
    }
    final path = _path(actor, request.fileUuid, name);
    final (item, file) = await session.db.transaction((tx) async {
      // The limits are checked under a per-user lock in the transaction
      // that inserts the upload (CQ-34): two parallel starts can't both
      // pass the last free slot.
      await Cluster.lockIn(session, 'uploads:${actor.userId}', tx);
      await _checkRates(session, actor, request.sizeBytes, tx);
      final parent = await DriveService.parentFor(
        session,
        actor,
        request.parentUuid,
        transaction: tx,
      );
      name = await _resolveName(
        session,
        actor,
        parent,
        name,
        request.conflict,
        tx,
      );
      final item = await DriveService.insertItem(
        session,
        actor,
        kind: DriveItemKind.file,
        name: name,
        parent: parent,
        uuid: request.itemUuid,
        contentRef: request.fileUuid,
        uploadState: FileUploadState.uploading,
        mimeType: FileTypes.octetStream,
        fileCategory: FileCategory.other,
        transaction: tx,
      );
      final file = await StoredFile.db.insertRow(
        session,
        StoredFile(
          fileUuid: request.fileUuid,
          ownerId: actor.userId,
          itemId: item.id,
          kind: StoredFileKind.driveFile,
          storageId: storageId,
          path: path,
          fileName: FileNames.ascii(name),
          mimeType: FileTypes.octetStream,
          sizeBytes: request.sizeBytes,
          status: StoredFileStatus.pending,
          createdAt: nowUtc(),
        ),
        transaction: tx,
      );
      await StorageService.instance.reserve(
        session,
        userId: actor.userId,
        fileUuid: request.fileUuid,
        itemId: item.id,
        bytes: request.sizeBytes,
        reason: QuotaReason.upload,
        transaction: tx,
      );
      return (item, file);
    });
    // Empty files need no transfer.
    if (request.sizeBytes == 0) {
      await session.storage.storeFile(
        storageId: storageId,
        path: path,
        byteData: ByteData(0),
      );
    }
    // Only the uploader sees the item while it uploads (Drive 02 §2).
    await _notifyUploader(session, item, DriveChangeKind.created);
    return FileUploadStart(
      item: await DriveViews.one(session, actor.userId, item, role: Role.owner),
      ticket: FileUploadTicket(
        fileUuid: file.fileUuid,
        uploadDescription: request.sizeBytes == 0
            ? null
            : await _description(session, file),
        status: StoredFileStatus.pending,
      ),
      storage: await StorageService.instance.usage(session, actor.userId),
    );
  }

  /// Idempotent retry of `createFileUpload` on an existing item uuid.
  static Future<FileUploadStart> _retry(
    Session session,
    Actor actor,
    DriveItem item,
    FileUploadRequest request,
  ) async {
    final file = item.contentRef == null
        ? null
        : await _storedFile(session, item);
    if (item.kind != DriveItemKind.file ||
        item.ownerId != actor.userId ||
        item.contentRef != request.fileUuid ||
        file == null ||
        file.sizeBytes != request.sizeBytes) {
      throw Errors.conflict('This item id is already in use.');
    }
    if (item.uploadState == FileUploadState.failed) {
      throw Errors.conflict('This upload failed. Start a new one.');
    }
    final pending = item.uploadState == FileUploadState.uploading;
    final stored = pending && await _hasObject(session, file);
    return FileUploadStart(
      item: await DriveViews.one(session, actor.userId, item, role: Role.owner),
      ticket: FileUploadTicket(
        fileUuid: file.fileUuid,
        uploadDescription: pending && !stored
            ? await _description(session, file)
            : null,
        status: file.status,
      ),
      storage: await StorageService.instance.usage(session, actor.userId),
    );
  }

  static Future<String> _description(Session session, StoredFile file) =>
      session.storage.createUploadDescription(
        storageId: file.storageId,
        path: file.path,
        options: UploadOptions(
          maxFileSize: file.sizeBytes,
          contentLength: file.sizeBytes,
          expirationDuration: uploadDescriptionLifetime,
        ),
      );

  /// "Keep both" numbering, or `conflict` for [UploadConflictMode.fail].
  static Future<String> _resolveName(
    Session session,
    Actor actor,
    DriveItem? parent,
    String name,
    UploadConflictMode mode,
    Transaction tx,
  ) async {
    final rows = await session.db.unsafeQuery(
      'SELECT lower(name) FROM drive_item WHERE '
      '${parent == null ? '"parentId" IS NULL AND "ownerId" = @me' : '"parentId" = @p'} '
      'AND "trashedAt" IS NULL '
      "AND (\"uploadState\" IS NULL OR \"uploadState\" = 'ready')",
      parameters: QueryParameters.named(
        parent == null ? {'me': actor.userId} : {'p': parent.id},
      ),
      transaction: tx,
    );
    final taken = {for (final r in rows) r[0] as String};
    if (!taken.contains(name.toLowerCase())) return name;
    if (mode == UploadConflictMode.fail) {
      throw Errors.conflict('A file named "$name" already exists here.');
    }
    for (var n = 1; n < 10000; n++) {
      final candidate = FileNames.numbered(name, n);
      if (candidate.length <= 255 && !taken.contains(candidate.toLowerCase())) {
        return candidate;
      }
    }
    throw Errors.conflict('A file named "$name" already exists here.');
  }

  /// Pending uploads and the upload rate limits (suite 13 §6). Failed and
  /// cancelled uploads keep their `StoredFile` row for a day, so they
  /// count too.
  static Future<void> _checkRates(
    Session session,
    Actor actor,
    int bytes,
    Transaction transaction,
  ) async {
    final config = WonkyConfig.current;
    final pending = await DriveItem.db.count(
      session,
      where: (t) =>
          t.ownerId.equals(actor.userId) &
          t.uploadState.equals(FileUploadState.uploading),
      transaction: transaction,
    );
    if (pending >= config.maxPendingUploadsPerUser) {
      throw Errors.limit('Too many uploads at once. Wait for some to finish.');
    }
    final now = clock.now().toUtc();
    final rows = await session.db.unsafeQuery(
      '''
      SELECT
        count(*) FILTER (WHERE "createdAt" > @hour),
        coalesce(sum("sizeBytes"), 0)::bigint
      FROM stored_file
      WHERE "ownerId" = @me AND kind = 'driveFile' AND "createdAt" > @day
      ''',
      parameters: QueryParameters.named({
        'me': actor.userId,
        'hour': now.subtract(const Duration(hours: 1)),
        'day': now.subtract(const Duration(days: 1)),
      }),
      transaction: transaction,
    );
    final perHour = rows.first[0] as int;
    final perDay = rows.first[1] as int;
    if (perHour >= config.uploadsPerHour ||
        perDay + bytes > config.uploadBytesPerDay) {
      throw Errors.limit("You've uploaded a lot recently. Try again later.");
    }
  }

  // ------------------------------------------------------------- complete

  static Future<DriveItemView> completeUpload(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final item = await _uploaderItem(session, actor, itemUuid);
    if (item.uploadState == FileUploadState.ready) {
      return DriveViews.one(session, actor.userId, item, role: Role.owner);
    }
    if (item.uploadState == FileUploadState.failed) {
      throw Errors.invalid('The upload was incomplete. Try again.');
    }
    final file = await _storedFile(session, item);
    if (file == null || !await _hasObject(session, file, verify: true)) {
      await _fail(session, item, file, notify: true);
      throw Errors.invalid('The upload was incomplete. Try again.');
    }
    // Only the head and the tail are read (CQ-30): the sniffer needs the
    // first 4 KB and a ZIP's central directory at the end.
    final size = await StorageReads.length(session, file);
    if (size == null || size != file.sizeBytes) {
      await _fail(session, item, file, notify: true);
      throw Errors.invalid('The upload was incomplete. Try again.');
    }
    final Uint8List head;
    final Uint8List? tail;
    try {
      (head, tail) = await StorageReads.sample(
        session,
        file,
        size: size,
        head: FileTypeSniffer.sampleSize,
        tail: FileTypeSniffer.tailSize,
      );
    } on Object {
      await _fail(session, item, file, notify: true);
      throw Errors.invalid('The upload was incomplete. Try again.');
    }
    final sniffed = FileTypeSniffer.sniff(
      head,
      fileName: item.name,
      tail: tail,
    );
    final category = FileCategory.values.byName(
      sniffed.categoryFor(item.name).name,
    );
    final meta = <String, Object?>{
      ..._decodeMeta(item.fileMetaJson),
      if (sniffed.isText) ...{
        'encoding': sniffed.encoding,
        'lines': tail == null
            ? _lineCount(head)
            : await _streamedLineCount(session, file),
      },
    };
    final now = nowUtc();
    try {
      await session.db.transaction((tx) async {
        await StorageService.instance.commitReservation(
          session,
          file.fileUuid,
          size,
          transaction: tx,
        );
        await DriveItem.db.updateWhere(
          session,
          columnValues: (t) => [
            t.uploadState(FileUploadState.ready),
            t.mimeType(sniffed.mimeType),
            t.fileCategory(category),
            t.sizeBytes(size),
            t.fileMetaJson(meta.isEmpty ? null : jsonEncode(meta)),
            t.modifiedAt(now),
            t.modifiedById(actor.userId),
          ],
          where: (t) => t.id.equals(item.id!),
          transaction: tx,
        );
        await StoredFile.db.updateWhere(
          session,
          columnValues: (t) => [
            t.status(StoredFileStatus.ready),
            t.mimeType(sniffed.mimeType),
            t.completedAt(now),
          ],
          where: (t) => t.id.equals(file.id!),
          transaction: tx,
        );
        await KindMasks.refreshChain(session, item.parentId, transaction: tx);
        await ActivityService.log(
          session,
          item.id!,
          actor,
          ActivityType.uploaded,
          summary: {
            'name': item.name,
            'sizeBytes': size,
            'mimeType': sniffed.mimeType,
          },
          transaction: tx,
        );
      });
    } on WonkyException catch (e) {
      if (e.code == WonkyErrorCode.quotaExceeded) {
        await _fail(session, item, file, notify: true);
      }
      rethrow;
    }
    final ready = (await DriveItem.db.findById(session, item.id!))!;
    // Now everyone with access sees it (Drive 02 §3.3).
    await DriveEvents.notify(session, ready, DriveChangeKind.created);
    if (FilePreviewService.wantsPreview(ready)) {
      await FilePreviewService.schedule(session, ready.id!);
    }
    return DriveViews.one(session, actor.userId, ready, role: Role.owner);
  }

  /// Lines of a text object larger than a sample, counted while it
  /// streams (never held whole).
  static Future<int> _streamedLineCount(
    Session session,
    StoredFile file,
  ) async {
    var lines = 1;
    var last = 0;
    var any = false;
    await for (final chunk in StorageReads.stream(session.serverpod, file)) {
      for (final b in chunk) {
        if (b == 0x0A) lines++;
      }
      if (chunk.isNotEmpty) {
        any = true;
        last = chunk.last;
      }
    }
    if (!any) return 0;
    return last == 0x0A ? lines - 1 : lines;
  }

  static int _lineCount(Uint8List bytes) {
    if (bytes.isEmpty) return 0;
    var lines = 1;
    for (final b in bytes) {
      if (b == 0x0A) lines++;
    }
    if (bytes.last == 0x0A) lines--;
    return lines;
  }

  // --------------------------------------------------------------- cancel

  static Future<void> cancelUpload(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final item = await AccessService.findItem(session, itemUuid);
    if (item == null) return; // expired or already cancelled
    if (item.kind != DriveItemKind.file || item.ownerId != actor.userId) {
      throw Errors.notFound();
    }
    if (item.uploadState == FileUploadState.ready) {
      throw Errors.invalid('The upload has already finished.');
    }
    await _fail(session, item, await _storedFile(session, item), notify: true);
  }

  /// Deletes an unfinished upload: bytes, reservation and item. The
  /// `StoredFile` row is kept (detached, `failed`) for a day so the upload
  /// still counts for the rate limits; `files.cleanup` removes it.
  static Future<void> _fail(
    Session session,
    DriveItem item,
    StoredFile? file, {
    required bool notify,
  }) async {
    if (file != null) {
      try {
        await session.storage.deleteFile(
          storageId: file.storageId,
          path: file.path,
        );
      } on Exception catch (e) {
        session.log(
          'Could not delete ${file.path}: $e',
          level: LogLevel.warning,
        );
      }
    }
    await session.db.transaction((tx) async {
      if (file != null) {
        await StoredFile.db.updateWhere(
          session,
          columnValues: (t) => [
            t.itemId(null),
            t.status(StoredFileStatus.failed),
            t.expiresAt(nowUtc().add(const Duration(days: 1))),
          ],
          where: (t) => t.id.equals(file.id!),
          transaction: tx,
        );
      }
      if (item.contentRef != null) {
        await StorageService.instance.releaseReservation(
          session,
          item.contentRef!,
          transaction: tx,
        );
      }
      await DriveItem.db.deleteWhere(
        session,
        where: (t) => t.id.equals(item.id!),
        transaction: tx,
      );
    });
    if (notify) await _notifyUploader(session, item, DriveChangeKind.removed);
  }

  // --------------------------------------------------------------- status

  static Future<FileUploadProgress> status(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final item = await _uploaderItem(session, actor, itemUuid);
    if (item.uploadState != FileUploadState.uploading) {
      return FileUploadProgress(
        uploadState: item.uploadState ?? FileUploadState.ready,
        receivedBytes: item.sizeBytes,
      );
    }
    final file = await _storedFile(session, item);
    final stored = file != null && await _hasObject(session, file);
    return FileUploadProgress(
      uploadState: FileUploadState.uploading,
      receivedBytes: stored ? file.sizeBytes : 0,
    );
  }

  // ----------------------------------------------------------------- read

  /// A signed URL of the bytes (previews; served as an
  /// `application/octet-stream` attachment), or with [download] the
  /// `GET /files/d/…` route URL (Drive 02 §6.1, §8).
  static Future<FileUrlView> contentUrl(
    Session session,
    Actor actor,
    UuidValue itemUuid, {
    bool download = false,
  }) async {
    final (item, role) = await _readableFile(session, actor, itemUuid);
    final file = await _storedFile(session, item);
    if (file == null) throw Errors.notFound('File');
    final mime = item.mimeType ?? FileTypes.octetStream;
    if (item.uploadState != FileUploadState.ready) {
      return FileUrlView(
        fileUuid: file.fileUuid,
        status: StoredFileStatus.pending,
        fileName: item.name,
        mimeType: mime,
        sizeBytes: file.sizeBytes,
      );
    }
    if (download && role < Role.editor && !item.nonEditorsCanExport) {
      throw Errors.forbidden('The owner has disabled downloads for viewers.');
    }
    final expires = clock.now().toUtc().add(FileUrlTokens.lifetime);
    final String url;
    if (download) {
      url = downloadUrl(file.fileUuid, item.name, actor.userId, expires);
    } else {
      url = (await session.storage.temporaryDownloadUrl(
        storageId: file.storageId,
        path: file.path,
        options: TemporaryDownloadUrlOptions(
          expirationDuration: FileUrlTokens.lifetime,
          downloadFileName: FileNames.ascii(item.name),
          contentType: FileTypes.octetStream,
        ),
      )).toString();
    }
    return FileUrlView(
      fileUuid: file.fileUuid,
      status: StoredFileStatus.ready,
      url: url,
      expiresAt: expires,
      fileName: item.name,
      mimeType: mime,
      sizeBytes: file.sizeBytes,
    );
  }

  /// The public origin of the web server routes.
  static Uri webOrigin() {
    try {
      return WonkyConfig.current.webOrigin(Serverpod.instance.config);
    } on Object {
      return Uri.parse('http://localhost:8082/');
    }
  }

  /// `GET /files/d/<fileUuid>/<name>?t=<token>` for [userId].
  static String downloadUrl(
    UuidValue fileUuid,
    String name,
    int userId,
    DateTime expiresAt,
  ) {
    final token = FileUrlTokens.issue(
      purpose: FileUrlPurpose.download,
      fileUuid: fileUuid,
      userId: userId,
      expiresAt: expiresAt,
    );
    return webOrigin()
        .replace(
          pathSegments: ['files', 'd', fileUuid.uuid, name],
          queryParameters: {'t': token},
        )
        .toString();
  }

  /// The `PUT /files/upload/<fileUuid>?t=<token>` URL of an upload in
  /// progress (MCP `drive.create_upload`, suite 09 §4): accepts the whole
  /// body (at most the declared size) in one request.
  static Future<({String url, DateTime expiresAt})> uploadUrl(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final item = await _uploaderItem(session, actor, itemUuid);
    if (item.uploadState != FileUploadState.uploading) {
      throw Errors.invalid('The upload has already finished.');
    }
    final file = await _storedFile(session, item);
    if (file == null) throw Errors.notFound('File');
    final expires = clock.now().toUtc().add(FileUrlTokens.lifetime);
    final token = FileUrlTokens.issue(
      purpose: FileUrlPurpose.upload,
      fileUuid: file.fileUuid,
      userId: actor.userId,
      sizeBytes: file.sizeBytes,
      expiresAt: expires,
    );
    final url = webOrigin().replace(
      pathSegments: ['files', 'upload', file.fileUuid.uuid],
      queryParameters: {'t': token},
    );
    return (url: url.toString(), expiresAt: expires);
  }

  // ----------------------------------------------------------------- meta

  /// Merges client-measured metadata (PDF `{pages}`) into `fileMetaJson`
  /// (Drive 02 §6.3). Editor+.
  static Future<DriveItemView> updateMeta(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String fileMetaJson,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.editor,
    );
    if (item.kind != DriveItemKind.file ||
        item.uploadState != FileUploadState.ready) {
      throw Errors.invalid('Only uploaded files have file metadata.');
    }
    if (fileMetaJson.length > maxMetaJsonChars) {
      throw Errors.invalid('The metadata is too large.');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(fileMetaJson);
    } on FormatException {
      throw Errors.invalid('The metadata is not valid JSON.');
    }
    if (decoded is! Map<String, Object?>) {
      throw Errors.invalid('The metadata must be a JSON object.');
    }
    for (final e in decoded.entries) {
      final v = e.value;
      if (!clientMetaKeys.contains(e.key) ||
          !(v == null || v is num || v is String || v is bool) ||
          (v is String && v.length > 64)) {
        throw Errors.invalid('Unsupported metadata "${e.key}".');
      }
    }
    final merged = {..._decodeMeta(item.fileMetaJson), ...decoded}
      ..removeWhere((_, v) => v == null);
    await DriveItem.db.updateWhere(
      session,
      columnValues: (t) => [
        t.fileMetaJson(merged.isEmpty ? null : jsonEncode(merged)),
      ],
      where: (t) => t.id.equals(item.id!),
    );
    final updated = (await DriveItem.db.findById(session, item.id!))!;
    await DriveEvents.notify(session, updated, DriveChangeKind.updated);
    return DriveViews.one(session, actor.userId, updated, role: role);
  }

  static Map<String, Object?> _decodeMeta(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, Object?> ? {...decoded} : {};
    } on FormatException {
      return {};
    }
  }

  /// Merges server-measured metadata (image `{width, height}`).
  static Future<void> mergeServerMeta(
    Session session,
    int itemId,
    Map<String, Object?> values,
  ) async {
    final item = await DriveItem.db.findById(session, itemId);
    if (item == null) return;
    final merged = {..._decodeMeta(item.fileMetaJson), ...values};
    await DriveItem.db.updateWhere(
      session,
      columnValues: (t) => [t.fileMetaJson(jsonEncode(merged))],
      where: (t) => t.id.equals(itemId),
    );
  }

  // -------------------------------------------------------------- convert

  /// *Open with* on the server (Drive 02 §7.2): imports the file's bytes as
  /// a document or spreadsheet into the file's folder (or My Drive when the
  /// caller can't edit it).
  static Future<ImportReportView> convert(
    Session session,
    Actor actor,
    UuidValue fileItemUuid,
    DriveItemKind target,
    DriveImportOptions options,
  ) async {
    final (item, role) = await _readableFile(session, actor, fileItemUuid);
    if (item.uploadState != FileUploadState.ready) {
      throw Errors.invalid('The file is still uploading.');
    }
    if (role < Role.editor && !item.nonEditorsCanExport) {
      throw Errors.forbidden('The owner has disabled copying for viewers.');
    }
    final explicit = options.format?.toLowerCase().trim();
    final format = explicit != null && explicit.isNotEmpty && explicit != 'auto'
        ? explicit
        : _formatOf(item);
    final file = await _storedFile(session, item);
    if (file == null) throw Errors.notFound('File');
    switch (target) {
      case DriveItemKind.document:
        if (!WriteImportService.formats.contains(format)) {
          throw Errors.invalid(
            'Files of type "$format" cannot be opened with Wonky Write.',
          );
        }
      case DriveItemKind.spreadsheet:
        if (!SheetsImportService.formats.contains(format)) {
          throw Errors.invalid(
            'Files of type "$format" cannot be opened with Wonky Sheets.',
          );
        }
      case DriveItemKind.folder:
      case DriveItemKind.presentation:
      case DriveItemKind.file:
        throw Errors.invalid('Files can be opened with Write or Sheets only.');
    }
    await StorageService.instance.checkRoom(
      session,
      userId: actor.userId,
      bytes: file.sizeBytes,
      reason: QuotaReason.convert,
    );
    final parentUuid =
        options.parentUuid ?? await _editableParent(session, actor, item);
    final name = options.name ?? FileNames.withoutExtension(item.name);
    final data = await session.storage.retrieveFile(
      storageId: file.storageId,
      path: file.path,
    );
    final bytes = Uint8List.sublistView(data);
    if (target == DriveItemKind.document) {
      return WriteImportService.importDocument(
        session,
        actor,
        file.copyWith(fileName: item.name),
        bytes,
        format,
        DriveImportOptions(
          format: format,
          name: name,
          parentUuid: parentUuid,
          optionsJson: options.optionsJson,
        ),
      );
    }
    return SheetsImportService.importNew(
      session,
      actor,
      bytes,
      fileName: item.name,
      format: format,
      options: SheetsImportService.optionsOf(options.optionsJson),
      name: name,
      parentUuid: parentUuid,
    );
  }

  static String _formatOf(DriveItem item) {
    final ext = FileTypes.extensionOf(item.name);
    if (ext.isNotEmpty) return ext == 'markdown' ? 'md' : ext;
    return switch (item.mimeType) {
      'text/csv' => 'csv',
      'text/tab-separated-values' => 'tsv',
      'text/markdown' => 'md',
      'text/html' => 'html',
      _ => 'txt',
    };
  }

  /// The file's folder when [actor] can edit it, else null (My Drive).
  static Future<UuidValue?> _editableParent(
    Session session,
    Actor actor,
    DriveItem item,
  ) async {
    if (item.parentId == null) return null;
    final parent = await DriveItem.db.findById(session, item.parentId!);
    if (parent == null || parent.trashedAt != null) return null;
    final role = await AccessService.effectiveRole(
      session,
      actor.userId,
      parent,
    );
    return role != null && role >= Role.editor ? parent.uuid : null;
  }

  // ----------------------------------------------------------------- copy

  /// Copies a ready file's bytes server-side into a new item owned by
  /// [actor] (Drive 02 §10); the copy counts for its owner.
  static Future<DriveItem> copyFile(
    Session session,
    Actor actor,
    DriveItem source, {
    required String newName,
    UuidValue? parentUuid,
  }) async {
    if (source.uploadState != FileUploadState.ready) {
      throw Errors.invalid('The file is still uploading.');
    }
    final file = await _storedFile(session, source);
    if (file == null) throw Errors.notFound('File');
    final name = FileNames.sanitize(newName);
    // The target folder is checked before any bytes are stored, so a
    // refused copy leaves nothing behind (it is checked again in the
    // transaction below).
    await DriveService.parentFor(session, actor, parentUuid);
    await StorageService.instance.checkRoom(
      session,
      userId: actor.userId,
      bytes: file.sizeBytes,
      reason: QuotaReason.copy,
    );
    final data = await session.storage.retrieveFile(
      storageId: file.storageId,
      path: file.path,
    );
    final fileUuid = const Uuid().v7obj();
    final path = _path(actor, fileUuid, name);
    await session.storage.storeFile(
      storageId: storageId,
      path: path,
      byteData: data,
    );
    final now = nowUtc();
    final DriveItem item;
    try {
      item = await _insertCopy(
        session,
        actor,
        source,
        file,
        name: name,
        parentUuid: parentUuid,
        fileUuid: fileUuid,
        path: path,
        size: data.lengthInBytes,
        now: now,
      );
    } on Object {
      // The bytes would be untracked without their rows.
      try {
        await session.storage.deleteFile(storageId: storageId, path: path);
      } on Object catch (e) {
        session.log('Copy cleanup failed: $e', level: LogLevel.warning);
      }
      rethrow;
    }
    final copy = (await DriveItem.db.findById(session, item.id!))!;
    if (FilePreviewService.wantsPreview(copy)) {
      await FilePreviewService.schedule(session, copy.id!);
    }
    return copy;
  }

  static Future<DriveItem> _insertCopy(
    Session session,
    Actor actor,
    DriveItem source,
    StoredFile file, {
    required String name,
    required UuidValue? parentUuid,
    required UuidValue fileUuid,
    required String path,
    required int size,
    required DateTime now,
  }) async {
    return session.db.transaction((tx) async {
      final parent = await DriveService.parentFor(
        session,
        actor,
        parentUuid,
        transaction: tx,
      );
      final item = await DriveService.insertItem(
        session,
        actor,
        kind: DriveItemKind.file,
        name: name,
        parent: parent,
        contentRef: fileUuid,
        description: source.description,
        uploadState: FileUploadState.ready,
        mimeType: source.mimeType,
        fileCategory: source.fileCategory,
        fileMetaJson: source.fileMetaJson,
        transaction: tx,
      );
      await StoredFile.db.insertRow(
        session,
        StoredFile(
          fileUuid: fileUuid,
          ownerId: actor.userId,
          itemId: item.id,
          kind: StoredFileKind.driveFile,
          storageId: storageId,
          path: path,
          fileName: FileNames.ascii(name),
          mimeType: file.mimeType,
          sizeBytes: size,
          status: StoredFileStatus.ready,
          createdAt: now,
          completedAt: now,
        ),
        transaction: tx,
      );
      await StorageService.instance.setItemSize(
        session,
        item,
        size,
        transaction: tx,
      );
      return item;
    });
  }

  // --------------------------------------------------------------- expiry

  /// Daily job (`drive.expireUploads`): deletes files still uploading after
  /// [uploadLifetime], their partial bytes and reservations. Returns the
  /// count.
  static Future<int> expireUploads(Session session, {DateTime? now}) async {
    final cutoff = (now ?? clock.now().toUtc()).subtract(uploadLifetime);
    final stale = await DriveItem.db.find(
      session,
      where: (t) =>
          t.uploadState.equals(FileUploadState.uploading) &
          (t.createdAt < cutoff),
      limit: 1000,
    );
    for (final item in stale) {
      await _fail(
        session,
        item,
        await _storedFile(session, item),
        notify: true,
      );
    }
    return stale.length;
  }

  // -------------------------------------------------------------- helpers

  static Future<StoredFile?> _storedFile(Session session, DriveItem item) =>
      item.contentRef == null
      ? Future.value(null)
      : StoredFile.db.findFirstRow(
          session,
          where: (t) => t.fileUuid.equals(item.contentRef!),
        );

  /// Whether the object exists ([verify]: marks a Serverpod upload
  /// verified first; our `PUT` route stores verified objects).
  static Future<bool> _hasObject(
    Session session,
    StoredFile file, {
    bool verify = false,
  }) async {
    try {
      if (verify &&
          await session.storage.verifyUpload(
            storageId: file.storageId,
            path: file.path,
          )) {
        return true;
      }
      return await session.storage.fileExists(
        storageId: file.storageId,
        path: file.path,
      );
    } on Exception {
      return false;
    }
  }

  /// The uploader's own file item (uploads are private until ready).
  static Future<DriveItem> _uploaderItem(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final item = await AccessService.findItem(session, itemUuid);
    if (item == null ||
        item.kind != DriveItemKind.file ||
        item.ownerId != actor.userId) {
      throw Errors.notFound();
    }
    return item;
  }

  /// A file item [actor] may read (Viewer+); uploads in progress only for
  /// their uploader.
  static Future<(DriveItem, Role)> _readableFile(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    if (item.kind != DriveItemKind.file) {
      throw Errors.invalid('The item is not an uploaded file.');
    }
    if (!DriveFileFilters.listable(item, actor.userId)) {
      throw Errors.notFound();
    }
    return (item, role);
  }

  static Future<void> _notifyUploader(
    Session session,
    DriveItem item,
    DriveChangeKind kind,
  ) => ClusterBus.post(
    session,
    DriveEvents.channel(item.ownerId),
    DriveChangeSignal(kind: kind, itemUuid: item.uuid),
  );
}
