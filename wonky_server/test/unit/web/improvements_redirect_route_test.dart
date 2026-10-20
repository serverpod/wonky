import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/web/routes/improvements_redirect_route.dart';

/// The redirect reads the session only through the screenshot lookup,
/// which the tests replace.
class _NoSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('ImprovementsRedirectRoute must not use it');
}

void main() {
  group(
    'Given the /improvements links served by ImprovementsRedirectRoute',
    () {
      late RelicServer server;
      late HttpClient client;
      final lookups = <int>[];

      setUpAll(() async {
        final route = ImprovementsRedirectRoute(
          screenshotUrl: (session, n) async {
            lookups.add(n);
            return n == 412
                ? 'https://storage.example.test/s/412.png?sig=1'
                : null;
          },
          markdown: (session, n) async =>
              n == 14 ? '# #14 Improvements to the board\n' : null,
        );
        final app = RelicApp()
          ..get('/improvements', (req) => route.handleCall(_NoSession(), req))
          ..get(
            '/improvements/**',
            (req) => route.handleCall(_NoSession(), req),
          );
        server = await app.serve(port: 0);
        client = HttpClient();
      });

      tearDownAll(() async {
        client.close(force: true);
        await server.close();
      });

      Future<HttpClientResponse> get(String path) async {
        final request = await client.get('localhost', server.port, path);
        request.followRedirects = false;
        final response = await request.close();
        await response.drain<void>();
        return response;
      }

      test(
        'when GET /improvements then it answers 302 to /drive/improvements',
        () async {
          final r = await get('/improvements');

          expect(r.statusCode, HttpStatus.found);
          expect(
            r.headers.value(HttpHeaders.locationHeader),
            '/drive/improvements',
          );
        },
      );

      test(
        'when GET a post link with a query then the path and query are kept',
        () async {
          final r = await get('/improvements/p/12?merged=3');

          expect(r.statusCode, HttpStatus.found);
          expect(
            r.headers.value(HttpHeaders.locationHeader),
            '/drive/improvements/p/12?merged=3',
          );
        },
      );

      test(
        'when GET a post screenshot then it redirects to the signed URL',
        () async {
          final r = await get('/improvements/p/412/screenshot');

          expect(r.statusCode, HttpStatus.found);
          expect(
            r.headers.value(HttpHeaders.locationHeader),
            'https://storage.example.test/s/412.png?sig=1',
          );
          expect(lookups, contains(412));
        },
      );

      test('when the post has no screenshot then it answers 404', () async {
        final r = await get('/improvements/p/7/screenshot');

        expect(r.statusCode, HttpStatus.notFound);
      });

      test('when GET a post with .md then it answers its Markdown', () async {
        final request = await client.get(
          'localhost',
          server.port,
          '/improvements/p/14.md',
        );
        request.followRedirects = false;
        final r = await request.close();
        final body = await r.transform(utf8.decoder).join();

        expect(r.statusCode, HttpStatus.ok);
        expect(r.headers.contentType?.mimeType, 'text/markdown');
        expect(r.headers.value(HttpHeaders.cacheControlHeader), 'no-cache');
        expect(body, '# #14 Improvements to the board\n');
      });

      test(
        'when the post is not public then the .md link answers 404',
        () async {
          final r = await get('/improvements/p/7.md');

          expect(r.statusCode, HttpStatus.notFound);
        },
      );
    },
  );

  test('improvementsTarget keeps nested paths', () {
    expect(
      improvementsTarget(Uri.parse('/improvements/t/3')),
      '/drive/improvements/t/3',
    );
  });
}
