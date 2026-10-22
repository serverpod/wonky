import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/cache_busting.dart';
import 'package:wonky_server/src/web/routes/legal_page_route.dart';

/// The legal pages never read the session.
class _NoSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('LegalPageRoute must not use the session');
}

void main() {
  group('Given the legal pages and the cache-busted /web/ route', () {
    late RelicServer server;
    late HttpClient client;

    setUpAll(() async {
      await templates.loadAll(Directory('web/templates'));
      final app = RelicApp();
      for (final page in const ['privacy', 'terms']) {
        final route = LegalPageRoute(page);
        app.anyOf(
          route.methods,
          '/$page',
          (req) => route.handleCall(_NoSession(), req),
        );
      }
      final static = StaticRoute.withCacheBusting(cacheBustingConfig);
      app.anyOf(
        static.methods,
        '/web/**',
        (req) => static.handleCall(_NoSession(), req),
      );
      server = await app.serve(port: 0);
      client = HttpClient();
    });

    tearDownAll(() async {
      client.close(force: true);
      await server.close();
    });

    Future<(HttpClientResponse, String)> get(
      String path, {
      String method = 'GET',
    }) async {
      final request = await client.open(method, 'localhost', server.port, path);
      final response = await request.close();
      final body = await response
          .transform(const SystemEncoding().decoder)
          .join();
      return (response, body);
    }

    for (final page in const ['privacy', 'terms']) {
      test('when GET /$page then the preview image URL carries the image\'s '
          'content hash', () async {
        final image = await cacheBustingConfig.assetPath(
          '/web/images/og-1.jpg',
        );

        final (response, body) = await get('/$page');

        expect(response.statusCode, HttpStatus.ok);
        expect(image, matches(RegExp(r'^/web/images/og-1@[0-9a-f]+\.jpg$')));
        expect(
          body,
          contains(
            '<meta property="og:image" content="https://wonky.work$image">',
          ),
        );
        expect(body, isNot(contains('{{')));
        expect(body, isNot(contains('/web/images/og-1.jpg')));
        expect(body, isNot(contains('/web/images/wonky-work.webp')));
      });
    }

    test('when GET the cache-busted image URL then it serves the JPEG as '
        'immutable', () async {
      final image = await cacheBustingConfig.assetPath('/web/images/og-1.jpg');

      final request = await client.get('localhost', server.port, image);
      final response = await request.close();
      final bytes = await response.fold<int>(0, (n, b) => n + b.length);

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'image/jpeg');
      expect(
        response.headers.value(HttpHeaders.cacheControlHeader),
        allOf(contains('immutable'), contains('max-age=31536000')),
      );
      expect(bytes, File('web/static/images/og-1.jpg').lengthSync());
    });

    test('when HEAD /privacy then it answers 200 without a body', () async {
      final (response, body) = await get('/privacy', method: 'HEAD');

      expect(response.statusCode, HttpStatus.ok);
      expect(body, isEmpty);
    });
  });
}
