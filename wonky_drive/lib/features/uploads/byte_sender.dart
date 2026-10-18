import 'dart:convert';
import 'dart:typed_data';

import 'byte_sender_io.dart'
    if (dart.library.js_interop) 'byte_sender_web.dart'
    as platform;

/// Cancels a running byte transfer.
class UploadAbort {
  bool _aborted = false;
  void Function()? _onAbort;

  bool get aborted => _aborted;

  /// Aborts the transfer (the sender throws [UploadAborted]).
  void abort() {
    if (_aborted) return;
    _aborted = true;
    _onAbort?.call();
  }

  /// The sender's abort hook (one at a time).
  set onAbort(void Function()? f) => _onAbort = f;
}

/// The transfer was aborted ([UploadAbort.abort]).
class UploadAborted implements Exception {
  const UploadAborted();

  @override
  String toString() => 'UploadAborted';
}

/// The storage answered with an error status.
class UploadTransferException implements Exception {
  const UploadTransferException(this.message, {this.status});

  final String message;
  final int? status;

  @override
  String toString() => 'UploadTransferException: $message';
}

/// A parsed Serverpod upload description (`FileUploader`'s format):
/// `binary` (a `PUT`/`POST` of the raw bytes with headers) or `multipart`
/// (a presigned POST form with request fields).
class UploadDescription {
  UploadDescription._({
    required this.multipart,
    required this.url,
    required this.method,
    required this.headers,
    required this.field,
    required this.fileName,
    required this.fields,
  });

  factory UploadDescription.parse(String description) {
    final data = jsonDecode(description);
    if (data is! Map) {
      throw const FormatException('The upload description is not an object');
    }
    final type = data['type'];
    if (type != 'binary' && type != 'multipart') {
      throw FormatException('Unknown upload type $type');
    }
    final url = data['url'];
    if (url is! String) {
      throw const FormatException('The upload description has no url');
    }
    final multipart = type == 'multipart';
    return UploadDescription._(
      multipart: multipart,
      url: Uri.parse(url),
      method: multipart ? 'POST' : (data['method'] as String?) ?? 'POST',
      headers: {
        if (!multipart) 'Content-Type': 'application/octet-stream',
        ...((data['headers'] as Map?) ?? const {}).cast<String, String>(),
      },
      field: data['field'] as String?,
      fileName: data['file-name'] as String?,
      fields: ((data['request-fields'] as Map?) ?? const {})
          .cast<String, String>(),
    );
  }

  final bool multipart;
  final Uri url;
  final String method;
  final Map<String, String> headers;

  /// Multipart: the file's form field and file name.
  final String? field;
  final String? fileName;

  /// Multipart: the presigned form fields.
  final Map<String, String> fields;

  /// Whether [status] means success for this kind of upload.
  bool succeeded(int status) => status >= 200 && status < 300;
}

/// Sends upload bytes with progress: an `XMLHttpRequest` on the web (upload
/// progress events), Serverpod's `FileUploader` elsewhere.
class ByteSender {
  const ByteSender();

  Future<void> send(
    String uploadDescription,
    Uint8List bytes, {
    required void Function(int sent) onProgress,
    required UploadAbort abort,
  }) {
    if (abort.aborted) throw const UploadAborted();
    return platform.sendBytes(
      uploadDescription,
      bytes,
      onProgress: onProgress,
      abort: abort,
    );
  }
}
