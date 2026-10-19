@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart' show Uuid;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/drive_file_service.dart';
import 'package:wonky_server/src/platform/files/file_routes.dart';
import 'package:wonky_server/src/platform/files/file_url_tokens.dart';
import 'package:wonky_server/src/platform/files/download_budget.dart';
import 'package:wonky_server/src/platform/files/storage_reads.dart';
import 'package:wonky_server/src/platform/config/wonky_config.dart';

import '../../support/file_fixtures.dart';
import '../../support/test_drive.dart';
import '../../support/test_files.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

class _Reply {
  _Reply(this.status, this.headers, this.bytes);
  final int status;
  final HttpHeaders headers;
  final List<int> bytes;
  String get text => utf8.decode(bytes, allowMalformed: true);
}

void main() {
  withWonkyServerpod('Given the file routes on the web server', (
    sessionBuilder,
    endpoints,
  ) {
    late int port;
    final http = HttpClient();
    late TestUser anna;

    setUpAll(() async {
      final pod = sessionBuilder.build().serverpod;
      FileRoutes.register(pod.webServer, pod: pod);
      if (!pod.webServer.running) await pod.webServer.start();
      port = pod.webServer.port!;
    });
    tearDownAll(() => http.close(force: true));
    setUp(() async {
      TestFiles.skipPreviews();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });

    Future<_Reply> send(
      String method,
      String pathAndQuery, {
      List<int>? body,
    }) async {
      final uri = Uri.parse('http://localhost:$port$pathAndQuery');
      final req = await http.openUrl(method, uri);
      if (body != null) {
        req.contentLength = body.length;
        req.add(body);
      }
      final res = await req.close();
      final bytes = await res.fold<List<int>>([], (a, b) => a..addAll(b));
      return _Reply(res.statusCode, res.headers, bytes);
    }

    String local(String url) {
      final u = Uri.parse(url);
      return '${u.path}?${u.query}';
    }

    Future<String> downloadPath(TestUser user, DriveItemView item) async =>
        local(
          (await endpoints.drive.fileContentUrl(
            user.endpointSession,
            item.uuid,
            download: true,
          )).url!,
        );

    group('with small stream pieces', () {
      setUp(() => StorageReads.chunkSize = 1000);
      tearDown(() {
        StorageReads.chunkSize = 1024 * 1024;
        StorageReads.forceWholeReads = false;
      });

      for (final whole in [false, true]) {
        test('when downloading a file of several pieces'
            '${whole ? ' with whole reads' : ''} then every byte arrives '
            'once', () async {
          StorageReads.forceWholeReads = whole;
          final bytes = [for (var i = 0; i < 4321; i++) i % 251];
          final item = await TestFiles.upload(
            endpoints,
            anna,
            name: 'data.bin',
            bytes: bytes,
          );

          final reply = await send('GET', await downloadPath(anna, item));

          expect(reply.status, 200);
          expect(reply.bytes, bytes);
          expect(reply.headers.contentLength, bytes.length);
        });
      }

      test('when a text file larger than a sample completes then its lines '
          'are counted while streaming', () async {
        final text = List.filled(30000, 'line').join('\n');
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'big.txt',
          bytes: utf8.encode(text),
        );

        expect(item.mimeType, startsWith('text/plain'));
        expect(jsonDecode(item.fileMetaJson!)['lines'], 30000);
      });
    });

    test('when the daily download allowance is used up then the download '
        'is refused with 429', () async {
      final saved = WonkyConfig.current;
      WonkyConfig.current = WonkyConfig(downloadBytesPerDay: 100);
      addTearDown(() {
        WonkyConfig.current = saved;
        DownloadBudget.clear();
      });
      final item = await TestFiles.upload(
        endpoints,
        anna,
        name: 'a.txt',
        bytes: List.filled(60, 0x61),
      );
      final path = await downloadPath(anna, item);

      final first = await send('GET', path);
      final head = await send('HEAD', path);
      final second = await send('GET', path);

      expect(first.status, 200);
      expect(head.status, 200);
      expect(second.status, 429);
      expect(DownloadBudget.usedToday(anna.id), 60);
    });

    test(
      'when downloading then the bytes come as an attachment with forced headers',
      () async {
        final bytes = FileFixtures.bytes('report.pdf');
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'Résumé "final".pdf',
          bytes: bytes,
        );

        final reply = await send('GET', await downloadPath(anna, item));

        expect(reply.status, 200);
        expect(reply.bytes, bytes);
        expect(reply.headers.contentType?.mimeType, 'application/pdf');
        expect(
          reply.headers.value('content-disposition'),
          'attachment; filename="R_sum_ _final_.pdf"; '
          "filename*=UTF-8''R%C3%A9sum%C3%A9%20%22final%22.pdf",
        );
        expect(reply.headers.value('x-content-type-options'), 'nosniff');
        expect(
          reply.headers.value('content-security-policy'),
          "sandbox; default-src 'none'",
        );
        expect(
          reply.headers.value('cross-origin-resource-policy'),
          'same-origin',
        );
        expect(reply.headers.value('cache-control'), 'private, no-store');
      },
    );

    test(
      'when downloading HTML named .jpg then it is never inline (AC-D2.4)',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'photo.jpg',
          bytes: FileFixtures.bytes('html_page.html'),
        );

        final reply = await send('GET', await downloadPath(anna, item));

        expect(reply.headers.contentType?.mimeType, 'text/html');
        expect(
          reply.headers.value('content-disposition'),
          startsWith('attachment;'),
        );
        expect(reply.headers.value('x-content-type-options'), 'nosniff');
        expect(
          reply.headers.value('content-security-policy'),
          startsWith('sandbox'),
        );
      },
    );

    test('when the token is forged or missing then it is refused', () async {
      final item = await TestFiles.upload(endpoints, anna, name: 'a.txt');
      final path = await downloadPath(anna, item);
      final noToken = path.substring(0, path.indexOf('?'));

      expect(
        (await send(
          'GET',
          '$path'
              'x',
        )).status,
        403,
      );
      expect((await send('GET', noToken)).status, 403);
    });

    test('when the token is for another file then it is refused', () async {
      final a = await TestFiles.upload(endpoints, anna, name: 'a.txt');
      final b = await TestFiles.upload(endpoints, anna, name: 'b.txt');
      final token = Uri.parse(
        'http://x${await downloadPath(anna, a)}',
      ).queryParameters['t']!;

      final reply = await send(
        'GET',
        '/files/d/${b.contentRef!.uuid}/b.txt?t=${Uri.encodeQueryComponent(token)}',
      );

      expect(reply.status, 403);
    });

    test(
      'when the user lost access after the URL was issued then it is not found',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final item = await TestFiles.upload(endpoints, anna, name: 'a.txt');
        await TestDrive.share(endpoints, item, anna, bo, AccessRole.viewer);
        final path = await downloadPath(bo, item);
        await endpoints.sharing.remove(anna.endpointSession, item.uuid, bo.id);

        final reply = await send('GET', path);

        expect(reply.status, 404);
      },
    );

    test(
      'when the owner turned off exports then a viewer token is refused',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final item = await TestFiles.upload(endpoints, anna, name: 'a.txt');
        await TestDrive.share(endpoints, item, anna, bo, AccessRole.viewer);
        final path = await downloadPath(bo, item);
        await DriveItem.db.updateWhere(
          anna.session,
          columnValues: (t) => [t.nonEditorsCanExport(false)],
          where: (t) => t.uuid.equals(item.uuid),
        );

        expect((await send('GET', path)).status, 403);
      },
    );

    test(
      'when PUTting the body with the upload URL then completion makes it ready',
      () async {
        final bytes = FileFixtures.bytes('image.png');
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'image.png',
          bytes: bytes,
        );
        final upload = await DriveFileService.uploadUrl(
          anna.session,
          anna.actor,
          start.item.uuid,
        );

        final reply = await send('PUT', local(upload.url), body: bytes);
        final item = await endpoints.drive.completeFileUpload(
          anna.endpointSession,
          start.item.uuid,
        );

        expect(reply.status, 200);
        expect(jsonDecode(reply.text), {'receivedBytes': bytes.length});
        expect(item.uploadState, FileUploadState.ready);
        expect(item.mimeType, 'image/png');
      },
    );

    test('when the body is larger than declared then it is 413', () async {
      final start = await TestFiles.start(
        endpoints,
        anna,
        name: 'a.txt',
        bytes: [1, 2, 3],
      );
      final upload = await DriveFileService.uploadUrl(
        anna.session,
        anna.actor,
        start.item.uuid,
      );

      final reply = await send('PUT', local(upload.url), body: [1, 2, 3, 4]);

      expect(reply.status, 413);
    });

    test(
      'when the upload token is for another user then it is not found',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: [1],
        );
        final token = FileUrlTokens.issue(
          purpose: FileUrlPurpose.upload,
          fileUuid: start.ticket.fileUuid,
          userId: bo.id,
          sizeBytes: 1,
        );

        final reply = await send(
          'PUT',
          '/files/upload/${start.ticket.fileUuid.uuid}?t=${Uri.encodeQueryComponent(token)}',
          body: [1],
        );

        expect(reply.status, 404);
      },
    );

    test(
      'when a download token is used to upload then it is refused',
      () async {
        final fileUuid = const Uuid().v7obj();
        final token = FileUrlTokens.issue(
          purpose: FileUrlPurpose.download,
          fileUuid: fileUuid,
          userId: anna.id,
        );

        final reply = await send(
          'PUT',
          '/files/upload/${fileUuid.uuid}?t=${Uri.encodeQueryComponent(token)}',
          body: [1],
        );

        expect(reply.status, 403);
      },
    );
  });
}
