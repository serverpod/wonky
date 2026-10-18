import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_drive/features/preview/preview_api.dart';

/// DR-3 (CQ-48): text previews request only the start of the file.
void main() {
  late CommandTestHarness h;

  setUp(() => h = CommandTestHarness());
  tearDown(() => h.dispose());

  final body = Uint8List.fromList(List<int>.filled(5000, 97));

  ServerFilePreviewApi apiAnswering(
    List<http.BaseRequest> seen, {
    required bool honorsRange,
  }) => ServerFilePreviewApi(
    h.services,
    httpClient: MockClient.streaming((request, _) async {
      seen.add(request);
      final range = request.headers['Range'];
      if (honorsRange && range != null) {
        final end = int.parse(range.split('-').last);
        return http.StreamedResponse(
          Stream.value(body.sublist(0, end + 1)),
          206,
        );
      }
      return http.StreamedResponse(
        Stream.fromIterable([
          for (var i = 0; i < 5; i++) body.sublist(0, 1000),
        ]),
        200,
        contentLength: body.length,
      );
    }),
  );

  group('Given a 5,000-byte file', () {
    test('when its first 100 bytes are fetched then a Range is sent and 100 '
        'bytes come back', () async {
      final seen = <http.BaseRequest>[];
      final api = apiAnswering(seen, honorsRange: true);

      final bytes = await api.fetch('https://store.test/f', firstBytes: 100);

      expect(seen.single.headers['Range'], 'bytes=0-99');
      expect(bytes.length, 100);
    });

    test('when the server ignores the Range then only 100 bytes are kept and '
        'the size limit does not apply', () async {
      final seen = <http.BaseRequest>[];
      final api = apiAnswering(seen, honorsRange: false);

      final bytes = await api.fetch(
        'https://store.test/f',
        firstBytes: 100,
        maxBytes: 50,
      );

      expect(bytes.length, 100);
    });

    test('when the storage host refuses the Range header then it is fetched '
        'without it and cut', () async {
      final seen = <http.BaseRequest>[];
      final api = ServerFilePreviewApi(
        h.services,
        httpClient: MockClient.streaming((request, _) async {
          seen.add(request);
          if (request.headers.containsKey('Range')) {
            throw http.ClientException('CORS');
          }
          return http.StreamedResponse(Stream.value(body), 200);
        }),
      );

      final bytes = await api.fetch('https://store.test/f', firstBytes: 100);

      expect(seen, hasLength(2));
      expect(bytes.length, 100);
    });

    test('when it is fetched whole above maxBytes then it is too large', () {
      final api = apiAnswering([], honorsRange: false);

      expect(
        api.fetch('https://store.test/f', maxBytes: 50),
        throwsA(
          isA<PreviewFetchException>().having(
            (e) => e.tooLarge,
            'tooLarge',
            true,
          ),
        ),
      );
    });
  });
}
