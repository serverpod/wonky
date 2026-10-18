import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';

/// Reads stored objects without holding them in memory (Drive 02 §8, suite
/// 13 §6, CQ-30): downloads stream in [chunkSize] pieces and upload checks
/// read only a head and a tail.
///
/// Serverpod's `CloudStorage` API has no ranged or streaming read, so:
/// - the database storage (development, tests, the fallback) is read in
///   chunks with `substring("byteData" …)` straight from its table;
/// - other storages (Serverpod Cloud, S3, GCS) are read over their
///   temporary download URL with HTTP (`Range` for samples);
/// - when neither works the whole object is read (`retrieveFile`).
abstract final class StorageReads {
  /// Bytes per streamed piece.
  static int chunkSize = 1024 * 1024;

  /// Test hook: forces the whole-object fallback.
  static bool forceWholeReads = false;

  static bool _inDatabase(Serverpod pod, String storageId) =>
      !forceWholeReads && pod.storage[storageId] is DatabaseCloudStorage;

  /// The object of [file] as a stream of [chunkSize] pieces. The stream
  /// opens its own session (the request's session may be closed before
  /// the body is sent) and closes it when done or cancelled.
  static Stream<Uint8List> stream(Serverpod pod, StoredFile file) async* {
    final session = await pod.createSession(enableLogging: false);
    try {
      if (_inDatabase(pod, file.storageId)) {
        final length = await _dbLength(session, file);
        for (var offset = 0; offset < length; offset += chunkSize) {
          yield await _dbRange(session, file, offset, chunkSize);
        }
        return;
      }
      final url = await _url(session, file);
      if (url != null) {
        final client = HttpClient();
        try {
          final request = await client.getUrl(url);
          final response = await request.close();
          if (response.statusCode == HttpStatus.ok) {
            var pending = BytesBuilder(copy: false);
            await for (final part in response) {
              pending.add(part);
              if (pending.length >= chunkSize) {
                yield pending.takeBytes();
                pending = BytesBuilder(copy: false);
              }
            }
            if (pending.length > 0) yield pending.takeBytes();
            return;
          }
          await response.drain<void>();
        } finally {
          client.close(force: true);
        }
      }
      final data = await session.storage.retrieveFile(
        storageId: file.storageId,
        path: file.path,
      );
      final all = Uint8List.sublistView(data);
      for (var offset = 0; offset < all.length; offset += chunkSize) {
        yield Uint8List.sublistView(
          all,
          offset,
          offset + chunkSize > all.length ? all.length : offset + chunkSize,
        );
      }
    } finally {
      await session.close();
    }
  }

  /// The stored length of [file]'s object (null when it is missing).
  static Future<int?> length(Session session, StoredFile file) async {
    if (_inDatabase(session.serverpod, file.storageId)) {
      final rows = await session.db.unsafeQuery(
        'SELECT octet_length("byteData") FROM serverpod_cloud_storage '
        'WHERE "storageId" = @s AND path = @p',
        parameters: QueryParameters.named({
          's': file.storageId,
          'p': file.path,
        }),
      );
      return rows.isEmpty ? null : rows.first[0] as int;
    }
    try {
      final stat = await session.storage.statFile(
        storageId: file.storageId,
        path: file.path,
      );
      return stat.size;
    } on Object {
      return null;
    }
  }

  /// The first [head] bytes of [file]'s object and, when it is longer than
  /// [head] + [tail], its last [tail] bytes. [size] is the object's
  /// length.
  static Future<(Uint8List head, Uint8List? tail)> sample(
    Session session,
    StoredFile file, {
    required int size,
    required int head,
    required int tail,
  }) async {
    final whole = size <= head + tail;
    if (_inDatabase(session.serverpod, file.storageId)) {
      if (whole) return (await _dbRange(session, file, 0, size), null);
      return (
        await _dbRange(session, file, 0, head),
        tail > 0 ? await _dbRange(session, file, size - tail, tail) : null,
      );
    }
    final url = await _url(session, file);
    if (url != null) {
      try {
        if (whole) return (await _http(url, 0, size), null);
        return (
          await _http(url, 0, head),
          tail > 0 ? await _http(url, size - tail, tail) : null,
        );
      } on Object catch (e) {
        session.log(
          'Ranged read of ${file.path} failed ($e); reading it whole.',
          level: LogLevel.debug,
        );
      }
    }
    final data = Uint8List.sublistView(
      await session.storage.retrieveFile(
        storageId: file.storageId,
        path: file.path,
      ),
    );
    if (whole) return (data, null);
    return (
      Uint8List.sublistView(data, 0, head),
      tail > 0 ? Uint8List.sublistView(data, data.length - tail) : null,
    );
  }

  static Future<int> _dbLength(Session session, StoredFile file) async =>
      await length(session, file) ?? 0;

  static Future<Uint8List> _dbRange(
    Session session,
    StoredFile file,
    int offset,
    int count,
  ) async {
    final rows = await session.db.unsafeQuery(
      'SELECT substring("byteData" FROM @from FOR @count) '
      'FROM serverpod_cloud_storage WHERE "storageId" = @s AND path = @p',
      parameters: QueryParameters.named({
        'from': offset + 1,
        'count': count,
        's': file.storageId,
        'p': file.path,
      }),
    );
    if (rows.isEmpty) {
      throw CloudStorageFileNotFoundException(
        storageId: file.storageId,
        path: file.path,
      );
    }
    final v = rows.first[0];
    return v is Uint8List ? v : Uint8List.fromList(v! as List<int>);
  }

  static Future<Uri?> _url(Session session, StoredFile file) async {
    try {
      return await session.storage.temporaryDownloadUrl(
        storageId: file.storageId,
        path: file.path,
      );
    } on Object {
      return null;
    }
  }

  static Future<Uint8List> _http(Uri url, int offset, int count) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(url);
      request.headers.set(
        HttpHeaders.rangeHeader,
        'bytes=$offset-${offset + count - 1}',
      );
      final response = await request.close();
      if (response.statusCode != HttpStatus.partialContent &&
          response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException('status ${response.statusCode}', uri: url);
      }
      final builder = BytesBuilder(copy: false);
      var skipped = 0;
      await for (final part in response) {
        // A server ignoring Range answers 200 with the whole object.
        if (response.statusCode == HttpStatus.ok) {
          final start = offset - skipped;
          skipped += part.length;
          if (skipped <= offset) continue;
          builder.add(start > 0 ? part.sublist(start) : part);
        } else {
          builder.add(part);
        }
        if (builder.length >= count) break;
      }
      final bytes = builder.takeBytes();
      return bytes.length > count
          ? Uint8List.sublistView(bytes, 0, count)
          : bytes;
    } finally {
      client.close(force: true);
    }
  }
}
