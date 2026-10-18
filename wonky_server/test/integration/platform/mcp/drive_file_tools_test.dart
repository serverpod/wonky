@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope;
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_routes.dart';
import 'package:wonky_server/src/platform/mcp/drive_file_tool_handlers.dart';
import 'package:wonky_server/src/platform/mcp/drive_mcp_content.dart';
import 'package:wonky_server/src/platform/mcp/mcp_config.dart';
import 'package:wonky_server/src/platform/mcp/mcp_http.dart';
import 'package:wonky_server/src/platform/mcp/mcp_route.dart';
import 'package:wonky_server/src/platform/storage/storage_maintenance.dart';
import 'package:wonky_server/src/platform/storage/storage_service.dart';

import '../../../support/file_fixtures.dart';
import '../../../support/mcp_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_files.dart';
import '../../../support/test_storage.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// A raw HTTP response.
class _Reply {
  _Reply(this.status, this.bytes);
  final int status;
  final List<int> bytes;
}

Map<String, dynamic> _item(Map<String, dynamic> r) =>
    (r['item'] as Map).cast<String, dynamic>();

/// `drive.*` file tools (suite 09 §4, Drive 02/03, D-15).
void main() {
  withWonkyServerpod('Given the drive file tools', (sessionBuilder, endpoints) {
    late int port;
    late McpHttpHandler handler;
    final http = HttpClient();
    late TestUser anna;
    late McpHarness mcpAnna;

    setUpAll(() async {
      final pod = sessionBuilder.build().serverpod;
      FileRoutes.register(pod.webServer, pod: pod);
      handler = McpHttpHandler(
        config: McpConfig(
          allowedHosts: {'localhost', '127.0.0.1'},
          allowedOrigins: {'http://localhost:8082'},
        ),
      );
      pod.webServer.addRoute(McpRoute(handler: handler, pod: pod), '/mcp');
      if (!pod.webServer.running) await pod.webServer.start();
      port = pod.webServer.port!;
    });
    tearDownAll(() async {
      await handler.closeAll();
      http.close(force: true);
    });
    setUp(() async {
      TestFiles.skipPreviews();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcpAnna = await McpHarness.forUser(anna);
    });
    tearDown(() {
      DriveFileToolHandlers.inlineUploadMaxBytes = 10 * 1024 * 1024;
      DriveFileToolHandlers.textMaxBytes = 1024 * 1024;
      DriveFileToolHandlers.base64MaxBytes = 2 * 1024 * 1024;
    });

    /// Sends [method] to the path and query of [url] on the test server.
    Future<_Reply> send(String method, String url, {List<int>? body}) async {
      final u = Uri.parse(url);
      final req = await http.openUrl(
        method,
        Uri.parse('http://localhost:$port${u.path}?${u.query}'),
      );
      if (body != null) {
        req.contentLength = body.length;
        req.add(body);
      }
      final res = await req.close();
      final bytes = await res.fold<List<int>>([], (a, b) => a..addAll(b));
      return _Reply(res.statusCode, bytes);
    }

    /// Asserts that the maintained counters of [user] equal a full
    /// recomputation (specs/15 §6, Drive 03 §4.3).
    Future<void> expectNoDrift(TestUser user) async {
      final drifts = await StorageMaintenance.reconcileUser(
        user.session,
        user.id,
      );
      expect(drifts, isEmpty);
    }

    Future<Map<String, dynamic>> uploadText(
      McpHarness h,
      String name,
      String text, {
      String? parent,
    }) async => _item(
      await h.call('drive.upload_file', {
        'name': name,
        'text': text,
        'parent_uuid': ?parent,
      }),
    );

    group('upload_file and download_file', () {
      test('when uploading text then a ready text file is stored and the '
          'result carries the storage', () async {
        final before = await TestStorage.usage(anna);

        final r = await mcpAnna.call('drive.upload_file', {
          'name': 'notes.txt',
          'text': 'Hello, Drive!\nLine 2\n',
        });

        final item = _item(r);
        expect(item['kind'], 'file');
        expect(item['name'], 'notes.txt');
        expect(item['mime_type'], 'text/plain');
        expect(item['file_category'], 'text');
        expect(item['upload_state'], 'ready');
        expect(item['size_bytes'], 21);
        expect(item['url'], endsWith('/drive/file/${item['uuid']}'));
        expect(
          (r['storage'] as Map)['used_bytes'],
          before.bytesUsed + 21,
        );
        expect((item['file_meta'] as Map)['lines'], 2);
        await expectNoDrift(anna);
      });

      test('when downloading a text file without as then the text is '
          'returned', () async {
        final item = await uploadText(mcpAnna, 'a.md', '# Ünïcödé\n');

        final r = await mcpAnna.call('drive.download_file', {
          'uuid': item['uuid'],
        });

        expect(r['text'], '# Ünïcödé\n');
        expect(r['encoding'], 'utf-8');
        expect(r['file_name'], 'a.md');
        expect(r.containsKey('content_base64'), isFalse);
      });

      test('when uploading a PNG as base64 then the type is sniffed and the '
          'download returns the same bytes', () async {
        final png = FileFixtures.bytes('image.png');

        final item = _item(
          await mcpAnna.call('drive.upload_file', {
            'name': 'picture.bin',
            'content_base64': base64Encode(png),
            'mime_type': 'application/x-whatever',
          }),
        );
        final r = await mcpAnna.call('drive.download_file', {
          'uuid': item['uuid'],
        });

        expect(item['mime_type'], 'image/png');
        expect(item['file_category'], 'image');
        expect(r['mime_type'], 'image/png');
        expect(base64Decode(r['content_base64'] as String), png);
      });

      test('when downloading as url then the signed route serves the '
          'bytes', () async {
        final item = await uploadText(mcpAnna, 'b.txt', 'via url');

        final r = await mcpAnna.call('drive.download_file', {
          'uuid': item['uuid'],
          'as': 'url',
        });
        final reply = await send('GET', r['download_url'] as String);

        expect(r['download_url'], contains('/files/d/'));
        expect(r['expires_at'], isA<String>());
        expect(reply.status, 200);
        expect(utf8.decode(reply.bytes), 'via url');
      });

      test('when a Latin-1 file is downloaded as text then it is decoded '
          'with its encoding', () async {
        final bytes = FileFixtures.bytes('latin1.txt');
        final item = _item(
          await mcpAnna.call('drive.upload_file', {
            'name': 'latin1.txt',
            'content_base64': base64Encode(bytes),
          }),
        );

        final r = await mcpAnna.call('drive.download_file', {
          'uuid': item['uuid'],
          'as': 'text',
        });

        expect(r['encoding'], 'latin1');
        expect(r['text'], latin1.decode(bytes));
      });

      test('when files exceed the text and base64 limits then the defaults '
          'step down to base64 and url', () async {
        DriveFileToolHandlers.textMaxBytes = 4;
        DriveFileToolHandlers.base64MaxBytes = 8;
        final small = await uploadText(mcpAnna, 's.txt', 'abcde');
        final large = await uploadText(mcpAnna, 'l.txt', 'abcdefghij');

        final s = await mcpAnna.call('drive.download_file', {
          'uuid': small['uuid'],
        });
        final l = await mcpAnna.call('drive.download_file', {
          'uuid': large['uuid'],
        });
        final tooLarge = await mcpAnna.error('drive.download_file', {
          'uuid': large['uuid'],
          'as': 'text',
        });

        expect(
          utf8.decode(base64Decode(s['content_base64'] as String)),
          'abcde',
        );
        expect(l['download_url'], isA<String>());
        expect(tooLarge['code'], 'too_large');
      });

      test(
        'when a binary file is requested as text then it is refused',
        () async {
          final item = _item(
            await mcpAnna.call('drive.upload_file', {
              'name': 'image.png',
              'content_base64': base64Encode(FileFixtures.bytes('image.png')),
            }),
          );

          final e = await mcpAnna.error('drive.download_file', {
            'uuid': item['uuid'],
            'as': 'text',
          });

          expect(e['code'], 'invalid_args');
        },
      );

      test('when downloading a document then the agent is sent to '
          'drive.export', () async {
        final doc = await TestDrive.document(endpoints, anna);

        final e = await mcpAnna.error('drive.download_file', {
          'uuid': doc.uuid.uuid,
        });

        expect(e['code'], 'invalid_args');
        expect(e['message'], contains('drive.export'));
      });

      for (final (label, args) in [
        ('both text and base64', {'text': 'a', 'content_base64': 'YQ=='}),
        ('no content', <String, Object?>{}),
        ('invalid base64', {'content_base64': '***'}),
      ]) {
        test(
          'when uploading with $label then invalid_args is returned',
          () async {
            final e = await mcpAnna.error('drive.upload_file', {
              'name': 'x.txt',
              ...args,
            });

            expect(e['code'], 'invalid_args');
          },
        );
      }

      test('when the inline content is larger than the limit then it is '
          'refused before anything is stored', () async {
        DriveFileToolHandlers.inlineUploadMaxBytes = 4;

        final text = await mcpAnna.error('drive.upload_file', {
          'name': 'x.txt',
          'text': 'abcde',
        });
        final b64 = await mcpAnna.error('drive.upload_file', {
          'name': 'x.bin',
          'content_base64': base64Encode(List.filled(64, 7)),
        });
        final listing = await mcpAnna.call('drive.list_folder');

        expect(text['code'], 'too_large');
        expect(text['message'], contains('drive.create_upload'));
        expect(b64['code'], 'too_large');
        expect(listing['items'], isEmpty);
      });

      test(
        'when the name exists in the folder then the upload is numbered',
        () async {
          final folder = await TestDrive.folder(endpoints, anna);
          await uploadText(
            mcpAnna,
            'notes.txt',
            'one',
            parent: folder.uuid.uuid,
          );

          final second = await uploadText(
            mcpAnna,
            'notes.txt',
            'two',
            parent: folder.uuid.uuid,
          );

          expect(second['name'], 'notes (1).txt');
          expect(second['parent_uuid'], folder.uuid.uuid);
        },
      );
    });

    group('quota (Drive 03 §6.6)', () {
      test('when an upload does not fit then quota_exceeded carries the '
          'details and nothing is left behind', () async {
        final used = (await TestStorage.row(anna)).usedBytes;
        await TestStorage.setQuota(anna, used + 3);

        final e = await mcpAnna.error('drive.upload_file', {
          'name': 'big.txt',
          'text': '0123456789',
        });
        final listing = await mcpAnna.call('drive.list_folder');

        expect(e['code'], 'quota_exceeded');
        expect(e['details'], {
          'needed_bytes': 10,
          'available_bytes': 3,
          'quota_bytes': used + 3,
          'charged_user': {'id': anna.id, 'name': 'Anna'},
          'is_caller': true,
          'reason': QuotaReason.upload,
        });
        expect(listing['items'], isEmpty);
        expect((await TestStorage.usage(anna)).reservedBytes, 0);
        await expectNoDrift(anna);
      });

      test(
        'when a large upload does not fit then create_upload is refused',
        () async {
          await TestStorage.setQuota(anna, 100);

          final e = await mcpAnna.error('drive.create_upload', {
            'name': 'video.mp4',
            'size_bytes': 5000,
          });

          expect(e['code'], 'quota_exceeded');
          expect((e['details'] as Map)['needed_bytes'], 5000);
        },
      );

      test('when the declared size is above the upload limit then it is '
          'too_large', () async {
        final e = await mcpAnna.error('drive.create_upload', {
          'name': 'huge.bin',
          'size_bytes': 50 * 1024 * 1024 + 1,
        });

        expect(e['code'], 'too_large');
      });

      test('when converting does not fit then quota_exceeded names the '
          'convert reason', () async {
        final item = await uploadText(mcpAnna, 'n.md', '# Notes');
        await TestStorage.setQuota(
          anna,
          (await TestStorage.row(anna)).usedBytes,
        );

        final e = await mcpAnna.error('drive.convert_file', {
          'uuid': item['uuid'],
          'target': 'document',
        });

        expect(e['code'], 'quota_exceeded');
        expect((e['details'] as Map)['reason'], QuotaReason.convert);
      });
    });

    group('create_upload and complete_upload', () {
      test('when the bytes are PUT to the upload URL then complete_upload '
          'makes the file ready', () async {
        final bytes = FileFixtures.bytes('report.pdf');
        final start = await mcpAnna.call('drive.create_upload', {
          'name': 'report.pdf',
          'size_bytes': bytes.length,
        });

        final put = await send(
          'PUT',
          start['upload_url'] as String,
          body: bytes,
        );
        final done = await mcpAnna.call('drive.complete_upload', {
          'item_uuid': start['item_uuid'],
        });
        final download = await mcpAnna.call('drive.download_file', {
          'uuid': start['item_uuid'],
          'as': 'base64',
        });

        expect(start['method'], 'PUT');
        expect(start['headers'], {'Content-Type': 'application/octet-stream'});
        expect(start['upload_url'], contains('/files/upload/'));
        expect((start['storage'] as Map)['available_bytes'], isA<int>());
        expect(put.status, 200);
        expect(_item(done)['mime_type'], 'application/pdf');
        expect(_item(done)['file_category'], 'pdf');
        expect(_item(done)['upload_state'], 'ready');
        expect(done['storage'], isA<Map<Object?, Object?>>());
        expect(base64Decode(download['content_base64'] as String), bytes);
        await expectNoDrift(anna);
      });

      test('when completing before the PUT then it is a conflict and the '
          'upload stays open', () async {
        final start = await mcpAnna.call('drive.create_upload', {
          'name': 'later.txt',
          'size_bytes': 5,
        });

        final early = await mcpAnna.error('drive.complete_upload', {
          'item_uuid': start['item_uuid'],
        });
        await send(
          'PUT',
          start['upload_url'] as String,
          body: utf8.encode('later'),
        );
        final done = await mcpAnna.call('drive.complete_upload', {
          'item_uuid': start['item_uuid'],
        });

        expect(early['code'], 'conflict');
        expect((early['details'] as Map)['expected_bytes'], 5);
        expect(_item(done)['upload_state'], 'ready');
      });

      test('when completing twice then the second call returns the same '
          'item', () async {
        final start = await mcpAnna.call('drive.create_upload', {
          'name': 'twice.txt',
          'size_bytes': 2,
        });
        await send('PUT', start['upload_url'] as String, body: [104, 105]);

        final first = await mcpAnna.call('drive.complete_upload', {
          'item_uuid': start['item_uuid'],
        });
        final second = await mcpAnna.call('drive.complete_upload', {
          'item_uuid': start['item_uuid'],
        });

        expect(_item(second)['uuid'], _item(first)['uuid']);
        expect(_item(second)['size_bytes'], 2);
      });

      test(
        'when another user completes the upload then it is not found',
        () async {
          final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
          final mcpBo = await McpHarness.forUser(bo);
          final start = await mcpAnna.call('drive.create_upload', {
            'name': 'mine.txt',
            'size_bytes': 1,
          });

          final e = await mcpBo.error('drive.complete_upload', {
            'item_uuid': start['item_uuid'],
          });

          expect(e['code'], 'not_found');
        },
      );

      test(
        'when an upload is in progress then others cannot download it',
        () async {
          final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
          final folder = await TestDrive.folder(endpoints, anna);
          await TestDrive.share(endpoints, folder, anna, bo, AccessRole.editor);
          final start = await mcpAnna.call('drive.create_upload', {
            'name': 'pending.txt',
            'size_bytes': 3,
            'parent_uuid': folder.uuid.uuid,
          });

          final own = await mcpAnna.error('drive.download_file', {
            'uuid': start['item_uuid'],
          });
          final other = await (await McpHarness.forUser(
            bo,
          )).error('drive.download_file', {'uuid': start['item_uuid']});

          expect(own['code'], 'conflict');
          expect(other['code'], 'not_found');
        },
      );
    });

    group('convert_file', () {
      test('when converting Markdown to a document then the document has '
          'the content and the file stays', () async {
        final folder = await TestDrive.folder(endpoints, anna);
        final file = await uploadText(
          mcpAnna,
          'meeting.md',
          '# Meeting\n\n- Decide the plan\n',
          parent: folder.uuid.uuid,
        );

        final r = await mcpAnna.call('drive.convert_file', {
          'uuid': file['uuid'],
          'target': 'document',
        });
        final item = _item(r);
        final doc = await mcpAnna.call('write.get_document', {
          'document_uuid': item['uuid'],
        });
        final listing = await mcpAnna.call('drive.list_folder', {
          'folder_uuid': folder.uuid.uuid,
        });

        expect(item['kind'], 'document');
        expect(item['name'], 'meeting');
        expect(item['parent_uuid'], folder.uuid.uuid);
        expect(doc['content'], contains('Decide the plan'));
        expect(r['storage'], isA<Map<Object?, Object?>>());
        expect(
          (listing['items'] as List).map((i) => (i as Map)['kind']).toSet(),
          {'file', 'document'},
        );
        await expectNoDrift(anna);
      });

      test('when converting a CSV to a spreadsheet with a name then a '
          'spreadsheet is created', () async {
        final file = _item(
          await mcpAnna.call('drive.upload_file', {
            'name': 'data.csv',
            'content_base64': base64Encode(FileFixtures.bytes('data.csv')),
          }),
        );

        final r = await mcpAnna.call('drive.convert_file', {
          'uuid': file['uuid'],
          'target': 'spreadsheet',
          'name': 'Imported data',
        });

        expect(_item(r)['kind'], 'spreadsheet');
        expect(_item(r)['name'], 'Imported data');
      });

      test('when converting an image then it is refused', () async {
        final file = _item(
          await mcpAnna.call('drive.upload_file', {
            'name': 'image.png',
            'content_base64': base64Encode(FileFixtures.bytes('image.png')),
          }),
        );

        final e = await mcpAnna.error('drive.convert_file', {
          'uuid': file['uuid'],
          'target': 'document',
        });

        expect(e['code'], 'invalid_args');
      });
    });

    group('get_storage', () {
      test(
        'when files are uploaded then usage and the file breakdown grow',
        () async {
          final before = await mcpAnna.call('drive.get_storage');

          await uploadText(mcpAnna, 'x.txt', '12345678');
          final after = await mcpAnna.call('drive.get_storage');

          expect(
            before['quota_bytes'],
            (await TestStorage.usage(anna)).quotaBytes,
          );
          expect(after['used_bytes'], (before['used_bytes'] as int) + 8);
          expect((after['by_kind'] as Map)['files'], 8);
          expect((after['counts'] as Map)['files'], 1);
          expect(
            after['available_bytes'],
            (after['quota_bytes'] as int) - (after['used_bytes'] as int),
          );
          expect(after['over_quota'], isFalse);
          expect(
            after.keys,
            containsAll(['reserved_bytes', 'max_file_upload_bytes']),
          );
        },
      );
    });

    group('kinds and file_category filters', () {
      test('when listing a folder by kinds and category then only matching '
          'items are returned', () async {
        final folder = await TestDrive.folder(endpoints, anna);
        final f = folder.uuid.uuid;
        await TestDrive.document(endpoints, anna, parentUuid: folder.uuid);
        await uploadText(mcpAnna, 'readme.txt', 'text', parent: f);
        await mcpAnna.call('drive.upload_file', {
          'name': 'photo.png',
          'content_base64': base64Encode(FileFixtures.bytes('image.png')),
          'parent_uuid': f,
        });

        final files = await mcpAnna.call('drive.list_folder', {
          'folder_uuid': f,
          'kinds': ['file'],
        });
        final images = await mcpAnna.call('drive.list_folder', {
          'folder_uuid': f,
          'kinds': ['file'],
          'file_category': 'image',
        });
        final docs = await mcpAnna.call('drive.list_folder', {
          'folder_uuid': f,
          'kinds': ['document'],
        });

        List<Object?> names(Map<String, dynamic> r) =>
            [for (final i in r['items'] as List) (i as Map)['name']]..sort();
        expect(names(files), ['photo.png', 'readme.txt']);
        expect(names(images), ['photo.png']);
        expect(names(docs), ['Doc']);
      });

      test(
        'when searching for a file kind then documents are skipped',
        () async {
          await TestDrive.document(endpoints, anna, name: 'Budget plan');
          await uploadText(mcpAnna, 'budget.csv', 'a,b\n1,2\n');

          final r = await mcpAnna.call('drive.search', {
            'query': 'budget',
            'kind': 'file',
          });

          expect(
            [for (final i in r['items'] as List) (i as Map)['name']],
            [
              'budget.csv',
            ],
          );
        },
      );
    });

    group('storage in byte-adding results (suite 09 §4)', () {
      test('when copying, creating and importing then each result carries '
          'the caller\'s storage', () async {
        final doc = await mcpAnna.call('drive.create_document', {
          'name': 'Doc',
          'markdown': 'Hello',
        });
        final copy = await mcpAnna.call('drive.copy', {
          'uuid': _item(doc)['uuid'],
        });
        final imported = await mcpAnna.call('drive.import', {
          'name': 'Imported',
          'kind': 'document',
          'format': 'md',
          'text': '# Hi',
        });
        final sheet = await mcpAnna.call('drive.create_spreadsheet', {
          'name': 'S',
        });
        final usage = await TestStorage.usage(anna);

        for (final r in [doc, copy, imported, sheet]) {
          expect(r['storage'], {
            'used_bytes': isA<int>(),
            'quota_bytes': usage.quotaBytes,
            'available_bytes': isA<int>(),
            'over_quota': false,
          });
        }
        expect((sheet['storage'] as Map)['used_bytes'], usage.bytesUsed);
      });

      test('when an image is inserted into a document then the result '
          'carries storage', () async {
        final doc = await TestDrive.document(endpoints, anna, markdown: 'A.');

        final r = await mcpAnna.call('write.insert_image', {
          'document_uuid': doc.uuid.uuid,
          'at': {'type': 'end'},
          'source': {
            'base64': base64Encode(FileFixtures.bytes('image.png')),
            'mime': 'image/png',
          },
          'alt': 'Dot',
        });

        expect(r['storage'], isA<Map<Object?, Object?>>());
        expect((r['storage'] as Map)['used_bytes'], isA<int>());
      });
    });

    group('permissions', () {
      Future<(TestUser, McpHarness)> caller(
        DriveItemView item,
        AccessRole? role,
      ) async {
        if (role == AccessRole.owner) return (anna, mcpAnna);
        final user = await TestUsers.create(sessionBuilder, name: 'Caller');
        if (role != null) {
          await TestDrive.share(endpoints, item, anna, user, role);
        }
        return (user, await McpHarness.forUser(user));
      }

      Future<DriveItemView> fileItem({bool exportable = true}) async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'notes.md',
          bytes: utf8.encode('# Shared notes'),
        );
        if (!exportable) {
          await DriveItem.db.updateWhere(
            anna.session,
            columnValues: (t) => [t.nonEditorsCanExport(false)],
            where: (t) => t.uuid.equals(item.uuid),
          );
        }
        return item;
      }

      final readers = {
        AccessRole.owner,
        AccessRole.editor,
        AccessRole.commenter,
        AccessRole.viewer,
      };
      const editors = {AccessRole.owner, AccessRole.editor};

      for (final (label, allowed, setup, tool, args) in [
        (
          'download_file',
          readers,
          () => fileItem(),
          'drive.download_file',
          (DriveItemView i) => {'uuid': i.uuid.uuid},
        ),
        (
          'download_file with downloads off for viewers',
          editors,
          () => fileItem(exportable: false),
          'drive.download_file',
          (DriveItemView i) => {'uuid': i.uuid.uuid},
        ),
        (
          'convert_file',
          readers,
          () => fileItem(),
          'drive.convert_file',
          (DriveItemView i) => {'uuid': i.uuid.uuid, 'target': 'document'},
        ),
        (
          'upload_file into a shared folder',
          editors,
          () => TestDrive.folder(endpoints, anna),
          'drive.upload_file',
          (DriveItemView i) => {
            'name': 'x.txt',
            'text': 'x',
            'parent_uuid': i.uuid.uuid,
          },
        ),
        (
          'create_upload into a shared folder',
          editors,
          () => TestDrive.folder(endpoints, anna),
          'drive.create_upload',
          (DriveItemView i) => {
            'name': 'x.txt',
            'size_bytes': 1,
            'parent_uuid': i.uuid.uuid,
          },
        ),
      ]) {
        for (final role in allRoles) {
          final ok = allowed.contains(role);
          test('when $label is called with '
              '${role?.name ?? 'no access'} then it '
              '${ok ? 'succeeds' : 'is refused'}', () async {
            final item = await setup();
            final (_, h) = await caller(item, role);

            final outcome = ok
                ? await h.call(tool, args(item))
                : await h.error(tool, args(item));

            if (ok) {
              expect(outcome, isNot(contains('code')));
            } else {
              expect(outcome['code'], anyOf('forbidden', 'not_found'));
            }
          });
        }
      }

      test('when a viewer converts a file then the copy goes to their own '
          'drive', () async {
        final folder = await TestDrive.folder(endpoints, anna);
        final file = await TestFiles.upload(
          endpoints,
          anna,
          name: 'n.md',
          bytes: utf8.encode('# N'),
          parentUuid: folder.uuid,
        );
        final (_, viewer) = await caller(folder, AccessRole.viewer);

        final r = await viewer.call('drive.convert_file', {
          'uuid': file.uuid.uuid,
          'target': 'document',
        });

        expect(_item(r)['parent_uuid'], isNull);
        expect(_item(r)['role'], 'owner');
      });

      test('when the token only has drive:read then reads work and uploads '
          'are forbidden', () async {
        final file = await fileItem();
        final reader = await McpHarness.forUser(
          anna,
          scopes: [McpScope.driveRead],
        );

        final read = await reader.call('drive.download_file', {
          'uuid': file.uuid.uuid,
        });
        final storage = await reader.call('drive.get_storage');
        final upload = await reader.error('drive.upload_file', {
          'name': 'x.txt',
          'text': 'x',
        });

        expect(read['text'], '# Shared notes');
        expect(storage['quota_bytes'], isA<int>());
        expect(upload['code'], 'forbidden');
      });
    });

    group('resources (suite 09 §5)', () {
      test(
        'when reading wonky://file for a text file then it is text',
        () async {
          final item = await uploadText(mcpAnna, 'r.md', '# Resource');
          final uri = Uri.parse('wonky://file/${item['uuid']}');

          final r = await DriveMcpContent.readFile(
            mcpAnna.ctx,
            uri,
            item['uuid'] as String,
          );

          final c = r.contents.single as mcp.TextResourceContents;
          expect(c.text, '# Resource');
          expect(c.mimeType, 'text/markdown');
        },
      );

      test(
        'when reading wonky://file for an image then it is a blob',
        () async {
          final png = FileFixtures.bytes('image.png');
          final item = _item(
            await mcpAnna.call('drive.upload_file', {
              'name': 'i.png',
              'content_base64': base64Encode(png),
            }),
          );

          final r = await DriveMcpContent.readFile(
            mcpAnna.ctx,
            Uri.parse('wonky://file/${item['uuid']}'),
            item['uuid'] as String,
          );

          final c = r.contents.single as mcp.BlobResourceContents;
          expect(base64Decode(c.blob), png);
          expect(c.mimeType, 'image/png');
        },
      );

      test(
        'when another user reads wonky://file then it is not found',
        () async {
          final item = await uploadText(mcpAnna, 'private.txt', 'secret');
          final bo = await McpHarness.forUser(
            await TestUsers.create(sessionBuilder, name: 'Bo'),
          );

          await expectLater(
            DriveMcpContent.readFile(
              bo.ctx,
              Uri.parse('wonky://file/${item['uuid']}'),
              item['uuid'] as String,
            ),
            throwsA(
              isA<mcp.McpError>().having(
                (e) => e.code,
                'code',
                mcp.ErrorCode.resourceNotFound.value,
              ),
            ),
          );
        },
      );

      test(
        'when reading wonky://drive/storage then it is the usage JSON',
        () async {
          final r = await DriveMcpContent.readStorage(
            mcpAnna.ctx,
            Uri.parse('wonky://drive/storage'),
          );

          final json =
              jsonDecode(
                    (r.contents.single as mcp.TextResourceContents).text,
                  )
                  as Map;
          expect(
            json['quota_bytes'],
            (await TestStorage.usage(anna)).quotaBytes,
          );
          expect(json['by_kind'], isA<Map<Object?, Object?>>());
        },
      );
    });

    group('ui.drive tools', () {
      test('when no Drive window is connected then ui.drive calls answer '
          'no_session', () async {
        final e = await mcpAnna.error('ui.drive.get_selection');

        expect(e['code'], 'no_session');
      });
    });

    group('J-D9 through /mcp', () {
      test('when an MCP client uploads, reads storage, downloads, converts '
          'and overflows the quota then each step works end to end', () async {
        final client = mcp.McpClient(
          const mcp.Implementation(name: 'jd9', version: '1.0.0'),
          options: const mcp.McpClientOptions(
            protocol: mcp.McpProtocol.stable,
          ),
        );
        await client.connect(
          mcp.StreamableHttpClientTransport(
            Uri.parse('http://localhost:$port/mcp'),
            opts: mcp.StreamableHttpClientTransportOptions(
              requestInit: {
                'headers': {'Authorization': 'Bearer ${mcpAnna.secret}'},
              },
            ),
          ),
        );
        Future<mcp.CallToolResult> call(String name, Map<String, dynamic> a) =>
            client.callTool(mcp.CallToolRequest(name: name, arguments: a));
        Map<String, dynamic> json(mcp.CallToolResult r) =>
            r.structuredContent!.cast<String, dynamic>();

        final tools = await client.listTools();
        final uploaded = await call('drive.upload_file', {
          'name': 'plan.md',
          'text': '# Plan\n\nShip Drive.\n',
        });
        final uuid = (json(uploaded)['item'] as Map)['uuid'] as String;
        final storage = await call('drive.get_storage', {});
        final downloaded = await call('drive.download_file', {'uuid': uuid});
        final converted = await call('drive.convert_file', {
          'uuid': uuid,
          'target': 'document',
        });
        final resource = await client.readResource(
          mcp.ReadResourceRequest(uri: 'wonky://file/$uuid'),
        );
        await TestStorage.setQuota(anna, json(storage)['used_bytes'] as int);
        final refused = await call('drive.upload_file', {
          'name': 'big.txt',
          'text': 'x' * 100,
        });
        await client.close();

        expect(
          tools.tools.map((t) => t.name),
          containsAll([
            'drive.upload_file',
            'drive.create_upload',
            'drive.complete_upload',
            'drive.download_file',
            'drive.convert_file',
            'drive.get_storage',
          ]),
        );
        expect(uploaded.isError, isNot(true));
        expect(json(uploaded)['storage'], isA<Map<Object?, Object?>>());
        expect(json(storage)['used_bytes'], greaterThanOrEqualTo(20));
        expect(json(downloaded)['text'], '# Plan\n\nShip Drive.\n');
        expect((json(converted)['item'] as Map)['kind'], 'document');
        expect(
          (resource.contents.single as mcp.TextResourceContents).text,
          contains('Ship Drive.'),
        );
        expect(refused.isError, isTrue);
        final payload =
            jsonDecode((refused.content.first as mcp.TextContent).text) as Map;
        expect(payload['code'], 'quota_exceeded');
        expect((payload['details'] as Map)['needed_bytes'], 100);
      });
    });
  });
}
