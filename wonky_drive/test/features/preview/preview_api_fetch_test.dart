import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_drive/features/preview/preview_api.dart';

/// `ServerFilePreviewApi.fetch` of whole files (Drive 02 §6.1, DR-5): the
/// size limit on a declared or a streamed body, HTTP errors and an
/// unreachable host. The `firstBytes` (Range) path is covered by
/// `preview_api_test.dart`.
void main() {
  late CommandTestHarness h;

  setUp(() => h = CommandTestHarness());
  tearDown(() async {
    Api.simulatedOffline = false;
    await h.dispose();
  });

  /// A body of [chunks] chunks of [chunkSize] bytes of `a`.
  List<Uint8List> body(int chunks, int chunkSize) => [
    for (var i = 0; i < chunks; i++)
      Uint8List.fromList(List<int>.filled(chunkSize, 97)),
  ];

  /// An API whose storage answers every GET with [status] and [chunks]
  /// (declaring [contentLength] when given); [sent] counts the requests and
  /// [read] the chunks the API pulled from the body.
  ServerFilePreviewApi apiAnswering(
    List<Uint8List> chunks, {
    int status = 200,
    int? contentLength,
    List<http.BaseRequest>? sent,
    List<int>? read,
  }) => ServerFilePreviewApi(
    h.services,
    httpClient: MockClient.streaming((request, _) async {
      sent?.add(request);
      Stream<List<int>> stream() async* {
        for (final (i, c) in chunks.indexed) {
          read?.add(i);
          yield c;
        }
      }

      return http.StreamedResponse(
        stream(),
        status,
        contentLength: contentLength,
      );
    }),
  );

  final tooLarge = throwsA(
    isA<PreviewFetchException>().having((e) => e.tooLarge, 'tooLarge', true),
  );

  group('Given a 3,000-byte file in three chunks', () {
    test('when it is fetched without a limit then every byte comes back '
        'and no Range is sent', () async {
      final sent = <http.BaseRequest>[];
      final api = apiAnswering(body(3, 1000), contentLength: 3000, sent: sent);

      final bytes = await api.fetch('https://store.test/f');

      expect(bytes, hasLength(3000));
      expect(sent.single.method, 'GET');
      expect(sent.single.headers, isNot(contains('Range')));
    });

    test('when it is fetched with a limit of exactly its size then every '
        'byte comes back', () async {
      final api = apiAnswering(body(3, 1000), contentLength: 3000);

      final bytes = await api.fetch('https://store.test/f', maxBytes: 3000);

      expect(bytes, hasLength(3000));
    });

    test('when the body has no declared length and grows past the limit '
        'then it is too large and reading stops at the chunk that crossed '
        'it', () async {
      final read = <int>[];
      final api = apiAnswering(body(3, 1000), read: read);

      await expectLater(
        api.fetch('https://store.test/f', maxBytes: 1500),
        tooLarge,
      );
      expect(read, [0, 1]);
    });

    test('when it declares a length within the limit but sends more then '
        'it is too large', () async {
      final api = apiAnswering(body(3, 1000), contentLength: 1000);

      await expectLater(
        api.fetch('https://store.test/f', maxBytes: 1500),
        tooLarge,
      );
    });
  });

  group('Given a storage that answers with an error status', () {
    for (final status in [403, 404, 500]) {
      test('when a file is fetched and the status is $status then it fails '
          'with the status and is not too large', () async {
        final api = apiAnswering(body(1, 10), status: status);

        await expectLater(
          api.fetch('https://store.test/f', maxBytes: 1 << 20),
          throwsA(
            isA<PreviewFetchException>()
                .having((e) => e.message, 'message', 'HTTP $status')
                .having((e) => e.tooLarge, 'tooLarge', false),
          ),
        );
      });
    }

    test('when the first bytes are requested and the status is 404 then it '
        'fails with the status', () async {
      final api = apiAnswering(body(1, 10), status: 404);

      await expectLater(
        api.fetch('https://store.test/f', firstBytes: 100),
        throwsA(
          isA<PreviewFetchException>().having(
            (e) => e.message,
            'message',
            'HTTP 404',
          ),
        ),
      );
    });
  });

  group('Given an unreachable storage', () {
    test('when a file is fetched then it fails as offline', () async {
      final api = ServerFilePreviewApi(
        h.services,
        httpClient: MockClient.streaming(
          (_, _) async => throw http.ClientException('Connection refused'),
        ),
      );

      await expectLater(
        api.fetch('https://store.test/f'),
        throwsA(isA<OfflineException>()),
      );
    });

    test('when the app simulates being offline then it fails as offline '
        'without a request', () async {
      final sent = <http.BaseRequest>[];
      final api = apiAnswering(body(1, 10), sent: sent);
      Api.simulatedOffline = true;

      await expectLater(
        api.fetch('https://store.test/f'),
        throwsA(isA<OfflineException>()),
      );
      expect(sent, isEmpty);
    });
  });
}
