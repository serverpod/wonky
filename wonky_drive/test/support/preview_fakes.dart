import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/config/drive_app_config.dart';
import 'package:wonky_drive/features/preview/file_downloader.dart';
import 'package:wonky_drive/features/preview/file_preview_screen.dart';
import 'package:wonky_drive/features/preview/preview_api.dart';
import 'package:wonky_drive/features/preview/preview_host.dart';
import 'package:wonky_ui/wonky_ui.dart';

/// File fixtures for the preview tests (Drive 05 D-14): a valid and a
/// malformed file per viewer.
abstract final class PreviewFixtures {
  /// A 4 × 3 red RGBA PNG.
  static final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAYAAAC09K7GAAAAEklEQVR4nGM4oaHxHxkz'
    'EBQAAHvxGRUahnOJAAAAAElFTkSuQmCC',
  );

  /// The PNG cut in the middle of its pixel data.
  static Uint8List get truncatedPng => Uint8List.sublistView(png, 0, 45);

  /// Bytes that are no image at all, named `.png`.
  static final notAnImage = Uint8List.fromList(utf8.encode('hello, not a png'));

  /// A minimal PDF (never previewed in v2: Drive 02 §6.3).
  static final pdf = Uint8List.fromList(utf8.encode('%PDF-1.7\n%%EOF'));

  static final dart = Uint8List.fromList(
    utf8.encode(
      "import 'dart:math';\n\n/// Rolls a die.\nint roll() => Random().nextInt(6) + 1;\n",
    ),
  );

  /// Binary data (NUL bytes) named `.txt`.
  static final binaryText = Uint8List.fromList([
    0x00, 0x01, 0x02, 0xff, 0xfe, 0x00, 0x10, 0x20, //
    0x7f, 0x00, 0x00, 0x00, 0x03, 0x04, 0x05, 0x06,
  ]);

  /// "café" in Latin-1 (not UTF-8).
  static final latin1Text = Uint8List.fromList([
    0x63, 0x61, 0x66, 0xe9, 0x0a, 0x6e, 0x61, 0xef, 0x76, 0x65, //
  ]);

  static final csv = Uint8List.fromList(
    utf8.encode('Name;City;Score\nAnna;Malmö;12\n"Bo, Jr.";Oslo;007\n'),
  );

  static final html = Uint8List.fromList(
    utf8.encode('<!doctype html><script>alert(1)</script><h1>Hi</h1>\n'),
  );
}

/// In-memory [FilePreviewApi]: items, folders and bytes by URL.
class FakePreviewApi implements FilePreviewApi {
  FakePreviewApi({this.owner});

  final UserSummary? owner;
  final Map<UuidValue, DriveItemView> items = {};
  final Map<UuidValue, Uint8List> bytes = {};
  final Map<UuidValue, Uint8List> previewBytes = {};
  final List<String> calls = [];

  /// Thrown by every call when set (e.g. `OfflineException`).
  Object? failWith;

  /// Thrown by [fetch] only.
  Object? fetchFailsWith;

  /// Completes [fetch] only when completed (loading state tests).
  Completer<void>? fetchGate;

  FileUploadProgress status = FileUploadProgress(
    uploadState: FileUploadState.uploading,
  );

  int _n = 0;

  /// Adds a file item with [content]; returns it.
  DriveItemView addFile(
    String name, {
    required String mimeType,
    required FileCategory category,
    Uint8List? content,
    UuidValue? parentUuid,
    AccessRole role = AccessRole.owner,
    FileUploadState uploadState = FileUploadState.ready,
    int? sizeBytes,
    String? fileMetaJson,
    Uint8List? preview,
    bool nonEditorsCanExport = true,
    DateTime? trashedAt,
  }) {
    _n++;
    final uuid = UuidValue.fromString(
      '00000000-0000-7000-8000-${_n.toString().padLeft(12, '0')}',
    );
    final contentRef = UuidValue.fromString(
      '00000000-0000-7000-9000-${_n.toString().padLeft(12, '0')}',
    );
    UuidValue? previewId;
    if (preview != null) {
      previewId = UuidValue.fromString(
        '00000000-0000-7000-a000-${_n.toString().padLeft(12, '0')}',
      );
      previewBytes[previewId] = preview;
    }
    final now = DateTime.utc(2026, 10, 1, 12);
    final v = DriveItemView(
      uuid: uuid,
      kind: DriveItemKind.file,
      name: name,
      contentRef: contentRef,
      parentUuid: parentUuid,
      owner: owner ?? TestUsers.anna,
      role: role,
      shared: false,
      sizeBytes: sizeBytes ?? content?.length ?? 0,
      createdAt: now,
      modifiedAt: now,
      trashedAt: trashedAt,
      starred: false,
      pinnedOffline: false,
      editorsCanShare: true,
      nonEditorsCanExport: nonEditorsCanExport,
      viewersSeeComments: true,
      mimeType: mimeType,
      fileCategory: category,
      uploadState: uploadState,
      fileMetaJson: fileMetaJson,
      previewFileId: previewId,
    );
    items[uuid] = v;
    if (content != null) bytes[uuid] = content;
    return v;
  }

  /// Adds a folder; returns it.
  DriveItemView addFolder(String name) {
    _n++;
    final uuid = UuidValue.fromString(
      '00000000-0000-7000-8000-${_n.toString().padLeft(12, '0')}',
    );
    final now = DateTime.utc(2026, 10, 1, 12);
    final v = DriveItemView(
      uuid: uuid,
      kind: DriveItemKind.folder,
      name: name,
      owner: owner ?? TestUsers.anna,
      role: AccessRole.owner,
      shared: false,
      sizeBytes: 0,
      createdAt: now,
      modifiedAt: now,
      starred: false,
      pinnedOffline: false,
      editorsCanShare: true,
      nonEditorsCanExport: true,
      viewersSeeComments: true,
    );
    items[uuid] = v;
    return v;
  }

  void _check(String call) {
    calls.add(call);
    final f = failWith;
    if (f != null) throw f;
  }

  DriveItemView _item(UuidValue uuid) =>
      items[uuid] ??
      (throw WonkyException(code: WonkyErrorCode.notFound, message: 'No file'));

  @override
  Future<DriveItemView> item(UuidValue uuid) async {
    _check('item');
    return _item(uuid);
  }

  @override
  Future<DriveItemView> folder(UuidValue uuid) async {
    _check('folder');
    return _item(uuid);
  }

  @override
  Future<List<DriveItemView>> filesIn(UuidValue parentUuid) async {
    _check('filesIn');
    return [
      for (final i in items.values)
        if (i.parentUuid == parentUuid && i.kind == DriveItemKind.file) i,
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<FileUrlView> contentUrl(
    UuidValue itemUuid, {
    bool download = false,
  }) async {
    _check(download ? 'downloadUrl' : 'contentUrl');
    final i = _item(itemUuid);
    return FileUrlView(
      fileUuid: i.contentRef!,
      status: StoredFileStatus.ready,
      url: download
          ? 'https://files.test/d/${itemUuid.uuid}/${i.name}'
          : 'https://files.test/p/${itemUuid.uuid}',
      fileName: i.name,
      mimeType: i.mimeType!,
      sizeBytes: i.sizeBytes,
    );
  }

  @override
  Future<FileUrlView> storedFileUrl(UuidValue fileUuid) async {
    _check('storedFileUrl');
    return FileUrlView(
      fileUuid: fileUuid,
      status: StoredFileStatus.ready,
      url: 'https://files.test/s/${fileUuid.uuid}',
      fileName: 'preview.png',
      mimeType: 'image/png',
      sizeBytes: previewBytes[fileUuid]?.length ?? 0,
    );
  }

  @override
  Future<Uint8List> fetch(String url, {int? maxBytes, int? firstBytes}) async {
    _check('fetch');
    if (firstBytes != null) calls.add('fetch.firstBytes:$firstBytes');
    await fetchGate?.future;
    final f = fetchFailsWith;
    if (f != null) throw f;
    final u = Uri.parse(url);
    final id = UuidValue.fromString(u.pathSegments.last);
    final data = u.pathSegments.first == 's' ? previewBytes[id] : bytes[id];
    if (data == null) throw const PreviewFetchException('HTTP 404');
    if (firstBytes != null && data.length > firstBytes) {
      return Uint8List.sublistView(data, 0, firstBytes);
    }
    return data;
  }

  @override
  Future<FileUploadProgress> uploadStatus(UuidValue itemUuid) async {
    _check('uploadStatus');
    return status;
  }
}

/// Records downloads.
class FakeDownloader implements FileDownloader {
  FakeDownloader({this.works = true});

  bool works;
  final List<(String, String)> downloads = [];

  @override
  Future<bool> download(String url, String fileName) async {
    downloads.add((url, fileName));
    return works;
  }
}

/// A shell with the Drive config, the fakes and a router with `/`,
/// `/f/:uuid` and `/file/:uuid` (the preview).
class PreviewTestbed {
  PreviewTestbed({FakePreviewApi? api})
    : api = api ?? FakePreviewApi(),
      h = CommandTestHarness(
        config: const DriveAppConfig(),
        activity: FakeActivityRepository(),
      ) {
    host = FilePreviewHost.of(h.services)
      ..api = this.api
      ..downloader = downloader;
  }

  final CommandTestHarness h;
  final FakePreviewApi api;
  final downloader = FakeDownloader();
  late final FilePreviewHost host;
  late GoRouter router;

  ShellServices get services => h.services;

  /// Pumps the preview of [item] at [size] in [brightness].
  Future<void> pump(
    WidgetTester tester,
    DriveItemView item, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1280, 800),
    bool settle = true,
  }) => pumpAt(
    tester,
    '/file/${item.uuid.uuid}',
    brightness: brightness,
    size: size,
    settle: settle,
  );

  Future<void> pumpAt(
    WidgetTester tester,
    String location, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1280, 800),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    router = GoRouter(
      navigatorKey: services.navigatorKey,
      initialLocation: location,
      routes: [
        GoRoute(path: '/', builder: (c, s) => const Text('home')),
        GoRoute(
          path: '/f/:uuid',
          builder: (c, s) => Text('folder ${s.pathParameters['uuid']}'),
        ),
        GoRoute(
          path: '/file/:uuid',
          builder: (c, s) => FilePreviewScreen(
            key: ValueKey<String>('drive.file.${s.pathParameters['uuid']}'),
            services: services,
            itemUuid: s.pathParameters['uuid']!,
          ),
        ),
      ],
    );
    router.routerDelegate.addListener(
      () => services.recordLocation(router.state.uri.toString()),
    );
    services.recordLocation(location);
    services.router = router;
    final config = const DriveAppConfig();
    await tester.pumpWidget(
      ShadApp.router(
        theme: brightness == Brightness.dark
            ? WonkyTheme.dark()
            : WonkyTheme.light(),
        routerConfig: router,
        localizationsDelegates: [
          WonkyAppLocalizations.delegate,
          WonkyUiLocalizations.delegate,
          ...config.localizationsDelegates,
        ],
        builder: (context, child) =>
            Material(type: MaterialType.transparency, child: child),
      ),
    );
    if (settle) await settleImages(tester);
  }

  /// Lets real image decoding (engine codecs) finish, then settles.
  Future<void> settleImages(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> dispose() => h.dispose();
}
