@Tags(['integration'])
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:wonky_server/src/cache_busting.dart';
import 'package:wonky_server/src/web/routes/flutter_app_route.dart';

import '../../support/wonky_serverpod.dart';

/// The app shell rendered as a template (specs/01 §2.4): its
/// `{{{@/web/…}}}` URLs carry the asset's content hash, the build's own
/// files are served as they are.
void main() {
  withWonkyServerpod('Given a Flutter app served by FlutterAppRoute', (
    sessionBuilder,
    endpoints,
  ) {
    final client = HttpClient();
    late Directory build;
    late int port;
    late String image;

    setUpAll(() async {
      build = Directory.systemTemp.createTempSync('wonky_app_');
      File('${build.path}/index.html').writeAsStringSync(
        '<!DOCTYPE html><html><head><base href="/testapp/">'
        '<meta property="og:image" '
        'content="https://wonky.work{{{@/web/images/og-1.jpg}}}">'
        '</head><body><script src="main.dart.js"></script></body></html>',
      );
      File('${build.path}/main.dart.js').writeAsStringSync('// app');
      File('${build.path}/assets/icon@2x.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync([1, 2, 3]);
      image = await cacheBustingConfig.assetPath('/web/images/og-1.jpg');

      final pod = sessionBuilder.build().serverpod;
      pod.webServer.addRoute(FlutterAppRoute(build), '/testapp');
      if (!pod.webServer.running) await pod.webServer.start();
      port = pod.webServer.port!;
    });
    tearDownAll(() {
      client.close(force: true);
      build.deleteSync(recursive: true);
    });

    Future<(HttpClientResponse, String)> fetch(
      String path, {
      String method = 'GET',
    }) async {
      final request = await client.open(method, 'localhost', port, path);
      final response = await request.close();
      final body = await response
          .transform(const SystemEncoding().decoder)
          .join();
      return (response, body);
    }

    for (final path in const [
      '/testapp/',
      '/testapp/index.html',
      '/testapp/d/0192a3b4-1111-7000-8000-000000000001',
    ]) {
      test('when GET $path then the shell links the image by its '
          'cache-busted URL', () async {
        final (response, body) = await fetch(path);

        expect(response.statusCode, HttpStatus.ok);
        expect(response.headers.contentType?.mimeType, 'text/html');
        expect(image, matches(RegExp(r'^/web/images/og-1@[0-9a-f]+\.jpg$')));
        expect(body, contains('content="https://wonky.work$image"'));
        expect(body, isNot(contains('{{')));
        expect(
          response.headers.value('cross-origin-embedder-policy'),
          'require-corp',
        );
      });
    }

    test('when HEAD the shell then it answers 200 without a body', () async {
      final (response, body) = await fetch('/testapp/', method: 'HEAD');

      expect(response.statusCode, HttpStatus.ok);
      expect(body, isEmpty);
    });

    test('when GET a build file then it is served as it is', () async {
      final (response, body) = await fetch('/testapp/main.dart.js');

      expect(response.statusCode, HttpStatus.ok);
      expect(body, '// app');
    });

    test('when GET an asset with @ in its name then it is not stripped as a '
        'cache-busting hash', () async {
      final request = await client.get(
        'localhost',
        port,
        '/testapp/assets/icon@2x.png',
      );
      final response = await request.close();
      final bytes = await response.expand((b) => b).toList();

      expect(response.statusCode, HttpStatus.ok);
      expect(bytes, [1, 2, 3]);
    });
  });
}
