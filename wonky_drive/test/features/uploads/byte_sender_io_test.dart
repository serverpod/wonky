@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wonky_app/wonky_app.dart' show OfflineException;
import 'package:wonky_drive/features/uploads/byte_sender.dart';
import 'package:wonky_drive/features/uploads/byte_sender_io.dart';

/// The non-web byte sender (a counted stream on `http`, Drive 02 §3.3,
/// DR-5): progress, completion, storage errors, unreachable or silent
/// storage and abort. The sender creates its own `http.Client()`, so the
/// storage is a [MockClient] installed with [http.runWithClient] (no
/// network). The web XHR sender (`byte_sender_web.dart`) needs `flutter
/// test --platform chrome` and is not covered here.
///
/// A request the storage received, with its body bytes.
final class Received {
  Received(this.request, this.body);
  final http.BaseRequest request;
  final Uint8List body;
}

void main() {
  const chunk = 64 * 1024;

  String binary({String method = 'PUT'}) => jsonEncode({
    'type': 'binary',
    'url': 'https://store.test/up/1',
    'method': method,
    'headers': {'x-test': 'yes'},
  });

  /// Sends [bytes] for [description] to a storage answering [status];
  /// [onChunk] runs for each body chunk the storage receives.
  Future<void> sendTo(
    String description,
    Uint8List bytes, {
    int status = 200,
    List<Received>? received,
    List<int>? progress,
    UploadAbort? abort,
    void Function(int index)? onChunk,
  }) => http.runWithClient(
    () => sendBytes(
      description,
      bytes,
      onProgress: (sent) => progress?.add(sent),
      abort: abort ?? UploadAbort(),
    ),
    () => MockClient.streaming((request, body) async {
      final b = BytesBuilder(copy: false);
      var i = 0;
      await for (final c in body) {
        b.add(c);
        onChunk?.call(i++);
      }
      received?.add(Received(request, b.takeBytes()));
      return http.StreamedResponse(const Stream.empty(), status);
    }),
  );

  Uint8List bytesOf(int n) =>
      Uint8List.fromList([for (var i = 0; i < n; i++) i % 251]);

  group('Given a binary upload of 150,000 bytes', () {
    final bytes = bytesOf(150000);

    test('when the storage accepts it then every byte arrives with the '
        'description\'s method and headers', () async {
      final received = <Received>[];

      await sendTo(binary(), bytes, received: received);

      final r = received.single;
      expect(r.request.method, 'PUT');
      expect(r.request.url, Uri.parse('https://store.test/up/1'));
      expect(r.request.headers['x-test'], 'yes');
      expect(r.request.headers['Content-Type'], 'application/octet-stream');
      expect(r.request.contentLength, 150000);
      expect(r.body, bytes);
    });

    test('when it is sent then progress grows per 64 KiB chunk up to the '
        'whole size', () async {
      final progress = <int>[];

      await sendTo(binary(), bytes, progress: progress);

      expect(progress, [chunk, 2 * chunk, 150000]);
    });

    test('when the storage answers 204 then it succeeds', () async {
      await expectLater(sendTo(binary(), bytes, status: 204), completes);
    });

    for (final status in [403, 500]) {
      test('when the storage answers $status then it fails with '
          'UploadTransferException', () async {
        await expectLater(
          sendTo(binary(), bytes, status: status),
          throwsA(isA<UploadTransferException>()),
        );
      });
    }

    /// Sends to a storage whose connection fails before the body is read
    /// (refused, DNS).
    Future<void> sendUnreachable(UploadAbort abort) => http.runWithClient(
      () => sendBytes(binary(), bytes, onProgress: (_) {}, abort: abort),
      () => MockClient.streaming(
        (_, _) async => throw http.ClientException('Connection refused'),
      ),
    );

    /// Sends to a storage that accepts the connection but never reads the
    /// body nor answers.
    Future<void> sendSilent(UploadAbort abort) => http.runWithClient(
      () => sendBytes(binary(), bytes, onProgress: (_) {}, abort: abort),
      () => MockClient.streaming(
        (_, _) => Completer<http.StreamedResponse>().future,
      ),
    );

    test('when the storage is unreachable then it fails with '
        'OfflineException', () async {
      await expectLater(
        sendUnreachable(UploadAbort()),
        throwsA(isA<OfflineException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('when the storage does not answer and the transfer is aborted '
        'then it fails with UploadAborted', () async {
      final abort = UploadAbort();
      final sent = sendSilent(abort);
      await pumpEventQueue();

      abort.abort();

      await expectLater(sent, throwsA(isA<UploadAborted>()));
    }, timeout: const Timeout(Duration(seconds: 5)));

    testWidgets('when the storage stops answering then it fails with '
        'OfflineException after the stall timeout', (tester) async {
      Object? error;
      unawaited(sendSilent(UploadAbort()).catchError((Object e) => error = e));

      await tester.pump(uploadStallTimeout - const Duration(seconds: 1));
      expect(error, isNull);
      await tester.pump(const Duration(seconds: 2));

      expect(error, isA<OfflineException>());
    });

    test('when it is aborted after the first chunk arrived then it fails '
        'with UploadAborted and the last chunk is never handed over', () async {
      final abort = UploadAbort();
      final progress = <int>[];

      await expectLater(
        sendTo(
          binary(),
          bytes,
          abort: abort,
          progress: progress,
          onChunk: (i) {
            if (i == 0) abort.abort();
          },
        ),
        throwsA(isA<UploadAborted>()),
      );
      expect(progress, isNot(contains(150000)));
    });
  });

  group('Given a multipart upload', () {
    final description = jsonEncode({
      'type': 'multipart',
      'url': 'https://bucket.test/',
      'field': 'file',
      'file-name': 'a.txt',
      'request-fields': {'key': 'u/1/a.txt'},
    });

    test('when the storage answers 204 then the form with the file and its '
        'fields is posted', () async {
      final received = <Received>[];

      await sendTo(
        description,
        Uint8List.fromList(utf8.encode('hello')),
        received: received,
        status: 204,
      );

      final r = received.single;
      final form = latin1.decode(r.body);
      expect(r.request.method, 'POST');
      expect(r.request.headers['content-type'], startsWith('multipart/'));
      expect(form, contains('name="key"'));
      expect(form, contains('u/1/a.txt'));
      expect(form, contains('name="file"; filename="a.txt"'));
      expect(form, contains('hello'));
    });
  });
}
