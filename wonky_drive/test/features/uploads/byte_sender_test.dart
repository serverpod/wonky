import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_drive/features/uploads/byte_sender.dart';

/// The parsed Serverpod upload description and the platform-independent
/// part of `ByteSender` (Drive 02 §3.3, DR-5). The transfer itself:
/// `byte_sender_io_test.dart` (the web XHR sender needs a browser).
void main() {
  group('Given a binary upload description', () {
    test('when it names a method and headers then they are used next to '
        'the octet-stream content type', () {
      final d = UploadDescription.parse(
        jsonEncode({
          'type': 'binary',
          'url': 'https://store.test/up/1?sig=x',
          'method': 'PUT',
          'headers': {'x-amz-acl': 'private'},
        }),
      );

      expect(d.multipart, isFalse);
      expect(d.url, Uri.parse('https://store.test/up/1?sig=x'));
      expect(d.method, 'PUT');
      expect(d.headers, {
        'Content-Type': 'application/octet-stream',
        'x-amz-acl': 'private',
      });
      expect(d.fields, isEmpty);
      expect(d.field, isNull);
    });

    test('when it names no method then it is a POST', () {
      final d = UploadDescription.parse(
        jsonEncode({'type': 'binary', 'url': 'https://store.test/up/1'}),
      );

      expect(d.method, 'POST');
      expect(d.headers, {'Content-Type': 'application/octet-stream'});
    });

    test('when its headers set a content type then that one wins', () {
      final d = UploadDescription.parse(
        jsonEncode({
          'type': 'binary',
          'url': 'https://store.test/up/1',
          'headers': {'Content-Type': 'image/png'},
        }),
      );

      expect(d.headers, {'Content-Type': 'image/png'});
    });
  });

  group('Given a multipart upload description', () {
    test('when it is parsed then it is a POST of the form fields with the '
        'file field and name, without a content type header', () {
      final d = UploadDescription.parse(
        jsonEncode({
          'type': 'multipart',
          'url': 'https://bucket.test/',
          'method': 'PUT',
          'field': 'file',
          'file-name': 'photo.png',
          'request-fields': {'key': 'u/1/photo.png', 'policy': 'abc'},
        }),
      );

      expect(d.multipart, isTrue);
      expect(d.method, 'POST');
      expect(d.headers, isEmpty);
      expect(d.field, 'file');
      expect(d.fileName, 'photo.png');
      expect(d.fields, {'key': 'u/1/photo.png', 'policy': 'abc'});
    });
  });

  group('Given an invalid upload description', () {
    for (final (what, description) in [
      ('not JSON', 'binary https://store.test'),
      ('a JSON list', '["binary"]'),
      ('of an unknown type', '{"type":"ftp","url":"ftp://store.test"}'),
      ('without a type', '{"url":"https://store.test"}'),
      ('without a url', '{"type":"binary"}'),
    ]) {
      test('when it is $what then parsing fails with a FormatException', () {
        expect(
          () => UploadDescription.parse(description),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });

  group('Given a parsed upload description', () {
    final d = UploadDescription.parse(
      jsonEncode({'type': 'binary', 'url': 'https://store.test/up/1'}),
    );

    for (final (status, ok) in [
      (199, false),
      (200, true),
      (201, true),
      (204, true),
      (299, true),
      (300, false),
      (403, false),
      (500, false),
    ]) {
      test('when the storage answers $status then succeeded is $ok', () {
        expect(d.succeeded(status), ok);
      });
    }
  });

  group('Given an aborted transfer', () {
    test('when bytes are sent then it fails with UploadAborted and reports '
        'no progress', () {
      final abort = UploadAbort()..abort();
      final progress = <int>[];

      expect(
        () => const ByteSender().send(
          jsonEncode({'type': 'binary', 'url': 'https://store.test/up/1'}),
          Uint8List(10),
          onProgress: progress.add,
          abort: abort,
        ),
        throwsA(isA<UploadAborted>()),
      );
      expect(progress, isEmpty);
    });

    test('when it is aborted again then the hook is not called twice', () {
      var calls = 0;
      final abort = UploadAbort()..onAbort = () => calls++;

      abort
        ..abort()
        ..abort();

      expect(abort.aborted, isTrue);
      expect(calls, 1);
    });
  });
}
