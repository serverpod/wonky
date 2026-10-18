import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:wonky_app/wonky_app.dart' show OfflineException;

import 'byte_sender.dart';

/// How long a transfer may go without the HTTP client taking the next chunk
/// or, after the last one, without the storage answering (DR-5).
const uploadStallTimeout = Duration(seconds: 60);

/// Desktop/tests: the bytes as a counted stream that the HTTP client pulls
/// chunk by chunk (progress = bytes handed to the client).
///
/// Not Serverpod's `FileUploader`: it pipes the body into a request sink
/// while the client connects, so a connection that fails before the body is
/// read (refused, DNS) never completes, and it reports every failure as
/// `false`. Here a failed connection is an [OfflineException], an error
/// status an [UploadTransferException], and [UploadAbort.abort] or a stall
/// of [uploadStallTimeout] ends the transfer at any point.
Future<void> sendBytes(
  String uploadDescription,
  Uint8List bytes, {
  required void Function(int sent) onProgress,
  required UploadAbort abort,
}) async {
  final d = UploadDescription.parse(uploadDescription);
  final client = http.Client();
  // Completes with the reason the transfer was cut short (abort or stall).
  final cut = Completer<Never>();
  Timer? watchdog;
  var finished = false;
  void stop(Object reason) {
    if (!cut.isCompleted) cut.completeError(reason);
    // Closing an `IOClient` tears down the connection in flight.
    client.close();
  }

  void arm() {
    watchdog?.cancel();
    if (finished) return;
    watchdog = Timer(
      uploadStallTimeout,
      () => stop(const OfflineException('The storage stopped answering')),
    );
  }

  const chunk = 64 * 1024;
  var sent = 0;
  Stream<List<int>> body() async* {
    for (var i = 0; i < bytes.length; i += chunk) {
      if (abort.aborted) throw const UploadAborted();
      final part = Uint8List.sublistView(
        bytes,
        i,
        min(i + chunk, bytes.length),
      );
      sent += part.length;
      onProgress(sent);
      arm();
      yield part;
    }
  }

  final http.BaseRequest request;
  if (d.multipart) {
    request = http.MultipartRequest('POST', d.url)
      ..fields.addAll(d.fields)
      ..files.add(
        http.MultipartFile(
          d.field ?? 'file',
          body(),
          bytes.length,
          filename: d.fileName,
        ),
      );
  } else {
    request = _StreamRequest(d.method, d.url, body())
      ..headers.addAll(d.headers)
      ..contentLength = bytes.length;
  }

  abort.onAbort = () => stop(const UploadAborted());
  arm();
  final sending = client.send(request);
  try {
    final response = await Future.any([sending, cut.future]);
    await Future.any([response.stream.drain<void>(), cut.future]);
    if (abort.aborted) throw const UploadAborted();
    if (!d.succeeded(response.statusCode)) {
      throw UploadTransferException(
        'HTTP ${response.statusCode}',
        status: response.statusCode,
      );
    }
  } on http.ClientException catch (e) {
    if (abort.aborted) throw const UploadAborted();
    throw OfflineException(e);
  } finally {
    // A send cut short still fails later; nobody waits for it.
    sending.ignore();
    finished = true;
    watchdog?.cancel();
    abort.onAbort = null;
    client.close();
  }
}

/// A request whose body is [_body], handed to the client as is (no sink to
/// pipe into, so nothing waits for a client that never reads it).
class _StreamRequest extends http.BaseRequest {
  _StreamRequest(super.method, super.url, this._body);

  final Stream<List<int>> _body;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_body);
  }
}
