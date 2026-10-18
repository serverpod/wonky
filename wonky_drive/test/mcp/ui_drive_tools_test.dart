import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show UiDriveTools;
import 'package:wonky_drive/config/drive_app_config.dart';
import 'package:wonky_drive/features/uploads/upload_host.dart';
import 'package:wonky_drive/features/uploads/upload_queue.dart';
import 'package:wonky_drive/features/uploads/upload_store.dart';
import 'package:wonky_drive/features/uploads/upload_task.dart';
import 'package:wonky_drive/mcp/ui_drive_tools.dart';

import '../support/preview_fakes.dart';
import '../support/storage_fakes.dart';
import '../support/upload_fakes.dart';

/// The window-side `ui.drive.*` tools (Drive 04 §13): selection of the
/// shown list (home or Storage page), the upload queue and the preview.
void main() {
  UiToolContext ctx(ShellServices s) => UiToolContext(
    services: s,
    boundaryKey: GlobalKey(),
    events: UiEventLog(),
    agentName: 'Claude Code (MCP)',
  );

  // Tools await a frame (uiSettle), so widget tests run them in real time.
  Future<UiToolResult> call(
    WidgetTester? tester,
    ShellServices s,
    String name, [
    Map<String, Object?> args = const {},
  ]) async {
    final tool = UiDriveToolHandlers.all(s)[name]!;
    if (tester == null) return tool(ctx(s), args);
    Object? error;
    final r = await tester.runAsync(() async {
      try {
        return await tool(ctx(s), args);
      } catch (e) {
        error = e;
        return null;
      }
    });
    await tester.pumpAndSettle();
    if (error != null) throw error!;
    return r!;
  }

  test('every ui.drive.* definition has a handler and vice versa', () {
    final h = CommandTestHarness(config: const DriveAppConfig());
    addTearDown(h.dispose);

    expect(UiDriveToolHandlers.all(h.services).keys.toSet(), {
      for (final d in UiDriveTools.all) d.name,
    });
  });

  group('Given the Storage page', () {
    late StorageTestbed t;
    late DriveItemView big;
    late DriveItemView small;

    setUp(() {
      t = StorageTestbed();
      big = t.seed('big.mov', bytes: 9 * mb, category: FileCategory.video);
      small = t.seed('Notes', kind: DriveItemKind.document, bytes: 20 * kb);
    });
    tearDown(() => t.dispose());

    testWidgets('when items are selected through the bridge then the page '
        'selects them and get_selection reports the storage view', (
      tester,
    ) async {
      await t.pump(tester);

      final r = await call(tester, t.services, 'ui.drive.select_items', {
        'uuids': [big.uuid.uuid, '00000000-0000-7000-8000-00000000abcd'],
      });

      expect((r.result['selected']! as List).single, {
        'uuid': big.uuid.uuid,
        'name': 'big.mov',
        'kind': 'file',
        'file_category': 'video',
        'size_bytes': 9 * mb,
        'trashed': false,
      });
      expect(r.result['not_found'], ['00000000-0000-7000-8000-00000000abcd']);
      expect(t.page!.selection.single.uuid, big.uuid);

      final sel = await call(tester, t.services, 'ui.drive.get_selection');
      expect(sel.result['view'], 'storage');
      expect(sel.result['filter'], 'all');
      expect(sel.result['listed'], 2);
      expect(
        (sel.result['items']! as List).single,
        containsPair('uuid', big.uuid.uuid),
      );
      expect(small.name, 'Notes');
    });
  });

  group('Given the Drive home', () {
    late StorageTestbed t;
    late DriveItemView folder;
    late DriveItemView doc;

    setUp(() {
      t = StorageTestbed();
      folder = t.h.drive.seed(name: 'Team', kind: DriveItemKind.folder);
      doc = t.h.drive.seed(name: 'Plan', parentUuid: folder.uuid);
    });
    tearDown(() => t.dispose());

    testWidgets('when an item of the listing is selected then the home '
        'selects it and get_selection names the view', (tester) async {
      await t.pump(tester, location: '/my-drive');
      final list = t.services.driveView.value!;
      await tester.runAsync(() => list.reload());
      await tester.pumpAndSettle();

      final r = await call(tester, t.services, 'ui.drive.select_items', {
        'uuids': [folder.uuid.uuid, doc.uuid.uuid],
      });

      final listed = {for (final i in list.items) i.uuid.uuid};
      expect(listed, contains(folder.uuid.uuid));
      expect(r.result['not_found'], [
        for (final u in [folder.uuid.uuid, doc.uuid.uuid])
          if (!listed.contains(u)) u,
      ]);
      expect(
        t.services.driveSelection.value.map((i) => i.uuid.uuid).toSet(),
        listed.intersection({folder.uuid.uuid, doc.uuid.uuid}),
      );

      final sel = await call(tester, t.services, 'ui.drive.get_selection');
      expect(sel.result['view'], 'my_drive');
      expect(sel.result['folder'], isNull);
    });
  });

  test('Given no list is shown when items are selected then the tool says '
      'what to do', () async {
    final h = CommandTestHarness(config: const DriveAppConfig());
    addTearDown(h.dispose);

    await expectLater(
      call(null, h.services, 'ui.drive.select_items', {
        'uuids': ['00000000-0000-7000-8000-000000000001'],
      }),
      throwsA(
        isA<UiToolException>().having((e) => e.code, 'code', 'unavailable'),
      ),
    );
  });

  group('Given uploads waiting for the connection', () {
    late CommandTestHarness h;
    late UploadHost host;
    late UploadQueue q;

    setUp(() async {
      h = CommandTestHarness(config: const DriveAppConfig());
      host = UploadHost.of(h.services)..api = FakeUploadApi();
      q = UploadQueue(
        api: host.api,
        store: MemoryUploadStore(),
        connectivity: h.services.connectivity,
        newId: sequentialIds(),
      );
      host.attach(q);
      await q.start();
    });
    tearDown(() async {
      h.services.connectivity.forceOffline(false);
      await host.stop();
      await h.dispose();
    });

    test('when the queue is read then every upload has its state and the '
        'totals add up', () async {
      h.services.connectivity.forceOffline(true);
      final tasks = await q.enqueue([
        textFile('a.txt', 10),
        textFile('b.pdf', 30),
      ]);
      tasks[1]
        ..status = UploadStatus.failed
        ..failure = UploadFailure.outOfStorage;

      final r = await call(null, h.services, 'ui.drive.get_upload_queue');

      final uploads = (r.result['uploads']! as List)
          .cast<Map<Object?, Object?>>();
      expect(uploads.map((u) => u['name']), ['a.txt', 'b.pdf']);
      expect(uploads[0]['state'], 'waitingForNetwork');
      expect(uploads[0]['size_bytes'], 10);
      expect(uploads[1]['state'], 'failed');
      expect(uploads[1]['error'], 'outOfStorage');
      expect(r.result['totals'], containsPair('count', 2));
      expect(r.result['totals'], containsPair('failed', 1));
      expect(r.result['available'], isTrue);
    });
  });

  test('Given a signed-out window when the upload queue is read then it is '
      'empty and not available', () async {
    final h = CommandTestHarness(config: const DriveAppConfig());
    addTearDown(h.dispose);

    final r = await call(null, h.services, 'ui.drive.get_upload_queue');

    expect(r.result['available'], isFalse);
    expect(r.result['uploads'], isEmpty);
  });

  group('Given a file preview', () {
    late PreviewTestbed t;

    setUp(() => t = PreviewTestbed());
    tearDown(() => t.dispose());

    testWidgets('when a preview is opened through the bridge then its state '
        'reports the viewer and zoom', (tester) async {
      final pdf = t.api.addFile(
        'report.pdf',
        mimeType: 'application/pdf',
        category: FileCategory.pdf,
        content: PreviewFixtures.pdf,
      );
      final png = t.api.addFile(
        'holiday.png',
        mimeType: 'image/png',
        category: FileCategory.image,
        content: PreviewFixtures.png,
      );
      await t.pump(tester, png);

      final image = await call(
        tester,
        t.services,
        'ui.drive.get_preview_state',
      );
      expect(image.result['type'], 'image');
      expect(image.result['uuid'], png.uuid.uuid);
      expect(image.result['zoom'], isA<int>());
      expect(image.result['rotation'], 0);

      final opened = await call(tester, t.services, 'ui.drive.open_preview', {
        'uuid': pdf.uuid.uuid,
      });
      await t.settleImages(tester);
      expect(opened.result['route'], '/file/${pdf.uuid.uuid}');

      final state = await call(
        tester,
        t.services,
        'ui.drive.get_preview_state',
      );
      expect(state.result['type'], 'unsupported');
      expect(state.result['zoom'], isNull);

      final sel = await call(tester, t.services, 'ui.drive.get_selection');
      expect(sel.result['view'], 'preview');
      expect(
        (sel.result['items']! as List).single,
        containsPair('name', 'report.pdf'),
      );
    });

    test('when no preview is open then get_preview_state is unavailable and '
        'a bad uuid is refused', () async {
      await expectLater(
        call(null, t.services, 'ui.drive.get_preview_state'),
        throwsA(isA<UiToolException>()),
      );
      await expectLater(
        call(null, t.services, 'ui.drive.open_preview', {'uuid': 'nope'}),
        throwsA(
          isA<UiToolException>().having(
            (e) => e.code,
            'code',
            'invalid_argument',
          ),
        ),
      );
    });
  });
}
