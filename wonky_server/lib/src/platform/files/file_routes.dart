// Named parameters can't initialize private fields directly.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/files.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../common/models.dart';
import '../sharing/access_service.dart';
import '../config/wonky_config.dart';
import 'download_budget.dart';
import 'file_names.dart';
import 'file_url_tokens.dart';
import 'storage_reads.dart';

/// The byte routes of uploaded files on the web server (Drive 02 §3.3, §8;
/// suite 13 §6). Both authenticate with the short-lived, user-bound token
/// of [FileUrlTokens] (never with the auth cookie or a bearer token) and
/// run on an internal session, like `/mcp`.
abstract final class FileRoutes {
  static const downloadPath = '/files/d/:fileUuid/:name';
  static const uploadPath = '/files/upload/:fileUuid';

  /// Adds both routes to [webServer].
  static void register(WebServer webServer, {Serverpod? pod}) {
    webServer.addRoute(FileDownloadRoute(pod: pod), downloadPath);
    webServer.addRoute(FileUploadRoute(pod: pod), uploadPath);
  }

  /// Forced headers of every file response (suite 13 §6).
  static const securityHeaders = {
    'x-content-type-options': 'nosniff',
    'content-security-policy': "sandbox; default-src 'none'",
    'cross-origin-resource-policy': 'same-origin',
    'cache-control': 'private, no-store',
    'referrer-policy': 'no-referrer',
  };

  static Response text(int status, String message) => Response(
    status,
    headers: Headers.build((h) {
      for (final e in securityHeaders.entries) {
        h[e.key] = [e.value];
      }
    }),
    body: Body.fromString(message, mimeType: MimeType.plainText),
  );

  static UuidValue? uuidOf(String? s) {
    if (s == null) return null;
    try {
      return UuidValue.withValidation(s);
    } on FormatException {
      return null;
    }
  }
}

abstract class _InternalSessionRoute extends Route {
  _InternalSessionRoute({Serverpod? pod, required super.methods}) : _pod = pod;

  final Serverpod? _pod;

  @override
  Future<Result> call(Request req) async {
    final session = await (_pod ?? Serverpod.instance).createSession(
      enableLogging: false,
    );
    try {
      return await handleCall(session, req);
    } finally {
      await session.close();
    }
  }
}

/// `GET /files/d/:fileUuid/:name?t=<token>`: streams a ready `driveFile`
/// as an attachment with forced headers. The token binds file, user and
/// expiry (15 min); the user's access is checked again on every request.
class FileDownloadRoute extends _InternalSessionRoute {
  FileDownloadRoute({super.pod}) : super(methods: {Method.get, Method.head});

  static const _fileUuid = PathParam<String>(#fileUuid, _id);
  static String _id(String s) => s;

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final fileUuid = FileRoutes.uuidOf(request.pathParameters.get(_fileUuid));
    if (fileUuid == null) return FileRoutes.text(404, 'Not found');
    final grant = FileUrlTokens.verify(
      request.url.queryParameters['t'],
      purpose: FileUrlPurpose.download,
      fileUuid: fileUuid,
    );
    if (grant == null) {
      return FileRoutes.text(403, 'This download link has expired.');
    }
    final file = await StoredFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    if (file == null ||
        file.kind != StoredFileKind.driveFile ||
        file.status != StoredFileStatus.ready ||
        file.itemId == null) {
      return FileRoutes.text(404, 'Not found');
    }
    final item = await DriveItem.db.findById(session, file.itemId!);
    if (item == null || item.uploadState != FileUploadState.ready) {
      return FileRoutes.text(404, 'Not found');
    }
    final role = await AccessService.effectiveRole(
      session,
      grant.userId,
      item,
    );
    if (role == null) return FileRoutes.text(404, 'Not found');
    if (role < Role.editor && !item.nonEditorsCanExport) {
      return FileRoutes.text(403, 'Downloads are turned off for this file.');
    }
    final isHead = request.method == Method.head;
    if (!isHead &&
        !DownloadBudget.tryCharge(
          grant.userId,
          file.sizeBytes,
          limit: WonkyConfig.current.downloadBytesPerDay,
        )) {
      return FileRoutes.text(
        429,
        "You've downloaded a lot today. Try again tomorrow.",
      );
    }
    final type = item.mimeType ?? FileTypes.octetStream;
    final headers = Headers.build((h) {
      for (final e in FileRoutes.securityHeaders.entries) {
        h[e.key] = [e.value];
      }
      h['content-disposition'] = [FileNames.contentDisposition(item.name)];
    });
    MimeType mime;
    try {
      mime = MimeType.parse(type);
    } on Object {
      mime = MimeType.octetStream;
    }
    // Streamed from storage in 1 MB pieces (never the whole file in
    // memory, CQ-30); the stream opens its own session.
    return Response(
      200,
      headers: headers,
      body: isHead
          ? Body.empty()
          : Body.fromDataStream(
              StorageReads.stream(session.serverpod, file),
              mimeType: mime,
              contentLength: file.sizeBytes,
            ),
    );
  }
}

/// `PUT /files/upload/:fileUuid?t=<token>`: stores the whole body of a
/// pending upload (MCP agents and other non-Serverpod clients, suite 09
/// §4). Bodies larger than the declared size are refused with `413`.
/// Answers `{"receivedBytes": n}`; the client then calls
/// `drive.completeFileUpload`. Chunked `Content-Range` uploads are P1
/// (Drive 02 §4.3).
class FileUploadRoute extends _InternalSessionRoute {
  FileUploadRoute({super.pod}) : super(methods: {Method.put});

  static const _fileUuid = PathParam<String>(#fileUuid, _id);
  static String _id(String s) => s;

  @override
  Future<Result> handleCall(Session session, Request request) async {
    final fileUuid = FileRoutes.uuidOf(request.pathParameters.get(_fileUuid));
    if (fileUuid == null) return FileRoutes.text(404, 'Not found');
    final grant = FileUrlTokens.verify(
      request.url.queryParameters['t'],
      purpose: FileUrlPurpose.upload,
      fileUuid: fileUuid,
    );
    if (grant == null) {
      return FileRoutes.text(403, 'This upload link has expired.');
    }
    if (request.headers['content-range'] != null) {
      return FileRoutes.text(501, 'Chunked uploads are not supported yet.');
    }
    final file = await StoredFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    if (file == null ||
        file.kind != StoredFileKind.driveFile ||
        file.ownerId != grant.userId ||
        file.itemId == null) {
      return FileRoutes.text(404, 'Not found');
    }
    if (file.status != StoredFileStatus.pending) {
      return FileRoutes.text(409, 'This upload has already finished.');
    }
    final builder = BytesBuilder(copy: false);
    try {
      await for (final chunk in request.read(maxLength: file.sizeBytes)) {
        builder.add(chunk);
      }
    } on MaxBodySizeExceeded {
      return FileRoutes.text(413, 'The body is larger than the declared size.');
    }
    final bytes = builder.takeBytes();
    if (bytes.length > file.sizeBytes) {
      return FileRoutes.text(413, 'The body is larger than the declared size.');
    }
    await session.storage.storeFile(
      storageId: file.storageId,
      path: file.path,
      byteData: ByteData.sublistView(bytes),
    );
    return Response(
      200,
      headers: Headers.build((h) {
        for (final e in FileRoutes.securityHeaders.entries) {
          h[e.key] = [e.value];
        }
      }),
      body: Body.fromString(
        jsonEncode({'receivedBytes': bytes.length}),
        mimeType: MimeType.json,
      ),
    );
  }
}
