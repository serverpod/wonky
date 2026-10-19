import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/features/uploads/upload_api.dart';

import '../../support/upload_fakes.dart';

/// The parts of [ShellServices] that [ServerUploadApi] uses: the generated
/// client, the drive repository and connectivity.
class _Services implements ShellServices {
  _Services({required this.client, required this.drive})
    : connectivity = testConnectivity();

  @override
  final Client? client;

  @override
  final DriveRepository drive;

  @override
  final ConnectivityService connectivity;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The fake drive with scripted list pages (by cursor) and an optional
/// failure of `deletePermanently`.
class _Drive extends FakeDriveRepository {
  /// Pages of [list] by cursor (`null` = the first page).
  final Map<String?, DriveListPage> pages = {};

  /// Every page that never ends (each answers with a next cursor).
  bool endless = false;

  /// `(folder, cursor, limit, view)` of every [list] call.
  final List<(UuidValue?, String?, int, DriveView)> listed = [];

  bool failDelete = false;

  @override
  Future<DriveListPage> list({
    UuidValue? folderUuid,
    required DriveListFilter filter,
    required DriveSort sort,
    String? cursor,
    int limit = 100,
  }) async {
    listed.add((folderUuid, cursor, limit, filter.view));
    if (endless) {
      return DriveListPage(
        items: [fileView(sequentialIds(listed.length)(), 'f${listed.length}')],
        nextCursor: 'c${listed.length}',
      );
    }
    return pages[cursor]!;
  }

  @override
  Future<void> deletePermanently(List<UuidValue> uuids) async {
    if (failDelete) throw StateError('delete failed');
    await super.deletePermanently(uuids);
  }
}

/// `ServerUploadApi` (Drive 02 §3.3, §7.3, DR-5): converting an upload
/// (convert, then trash and delete the original), the name-conflict
/// listing with paging, and the offline checks. The server is a
/// [MockClient] behind the real generated client.
void main() {
  late _Drive drive;
  late List<http.Request> requests;
  late _Services services;
  late ServerUploadApi api;

  final folder = UuidValue.fromString('00000000-0000-7000-a000-000000000001');
  final upload = UuidValue.fromString('00000000-0000-7000-a000-000000000002');
  final converted = fileView(
    UuidValue.fromString('00000000-0000-7000-a000-000000000003'),
    'notes',
    parentUuid: folder,
  ).copyWith(kind: DriveItemKind.document, mimeType: null, fileCategory: null);

  setUp(() {
    drive = _Drive();
    requests = [];
    services = _Services(
      drive: drive,
      client: Client(
        'http://api.test/',
        httpClientOverride: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/drive/convertFile') {
            final report = ImportReportView(item: converted, warnings: []);
            return http.Response(jsonEncode(report), 200);
          }
          return http.Response('', 404);
        }),
      ),
    );
    api = ServerUploadApi(services);
  });

  tearDown(() async {
    services.connectivity.forceOffline(false);
    Api.simulatedOffline = false;
    services.client?.close();
    await drive.dispose();
  });

  group('Given an uploaded Markdown file', () {
    setUp(() {
      drive.seed(
        name: 'notes.md',
        kind: DriveItemKind.file,
        uuid: upload,
        parentUuid: folder,
      );
    });

    test('when it is converted to a document then the server converts it, '
        'the upload is trashed and then deleted, and the new item is '
        'returned', () async {
      final item = await api.convert(upload, DriveItemKind.document);

      expect(item.uuid, converted.uuid);
      expect(item.kind, DriveItemKind.document);
      final call = requests.single;
      expect(call.url.path, '/drive/convertFile');
      final args = jsonDecode(call.body) as Map<String, Object?>;
      expect(args['fileItemUuid'], upload.uuid);
      expect(drive.calls, ['trash', 'deletePermanently']);
      expect(drive.items.where((i) => i.uuid == upload), isEmpty);
    });

    test('when deleting the converted upload fails then the new item is '
        'still returned and the upload stays in the trash', () async {
      drive.failDelete = true;

      final item = await api.convert(upload, DriveItemKind.document);

      expect(item.uuid, converted.uuid);
      expect(drive.calls, ['trash']);
      expect(drive.item(upload).trashedAt, isNotNull);
    });
  });

  test('Given an upload that is already gone when it is converted then the '
      'new item is returned and nothing is deleted', () async {
    final item = await api.convert(upload, DriveItemKind.spreadsheet);

    expect(item.uuid, converted.uuid);
    expect(drive.calls, isEmpty);
  });

  group('Given a folder listed in two pages', () {
    setUp(() {
      drive.pages
        ..[null] = DriveListPage(
          items: [
            fileView(sequentialIds(10)(), 'Report.PDF', parentUuid: folder),
            fileView(
              sequentialIds(11)(),
              'pending.txt',
              parentUuid: folder,
              state: FileUploadState.uploading,
            ),
          ],
          nextCursor: 'p2',
        )
        ..['p2'] = DriveListPage(
          items: [
            fileView(
              sequentialIds(12)(),
              'broken.txt',
              parentUuid: folder,
              state: FileUploadState.failed,
            ),
            converted.copyWith(name: 'Plan', uploadState: null),
          ],
        );
    });

    test('when its names are read then both pages are listed and the ready '
        'names come back in lower case', () async {
      final names = await api.namesIn(folder);

      expect(names, {'report.pdf', 'plan'});
      expect(drive.listed, [
        (folder, null, 200, DriveView.folder),
        (folder, 'p2', 200, DriveView.folder),
      ]);
    });
  });

  test('Given a folder whose listing never ends when its names are read '
      'then it stops after 10 pages', () async {
    drive.endless = true;

    final names = await api.namesIn(null);

    expect(names, hasLength(10));
    expect(drive.listed, hasLength(10));
    expect(drive.listed.first.$1, isNull);
  });

  group('Given the app is offline', () {
    setUp(() => services.connectivity.forceOffline(true));

    test('when an upload is converted then it fails as offline without a '
        'request', () async {
      await expectLater(
        api.convert(upload, DriveItemKind.document),
        throwsA(isA<OfflineException>()),
      );
      expect(requests, isEmpty);
      expect(drive.calls, isEmpty);
    });

    test('when an upload is cancelled then it fails as offline without a '
        'request', () async {
      expect(() => api.cancel(upload), throwsA(isA<OfflineException>()));
      expect(requests, isEmpty);
    });
  });

  test('Given no server client when an upload is completed then it fails as '
      'offline', () async {
    final offline = ServerUploadApi(_Services(client: null, drive: drive));

    expect(() => offline.complete(upload), throwsA(isA<OfflineException>()));
  });
}
