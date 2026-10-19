import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/config/drive_app_config.dart';
import 'package:wonky_drive/features/uploads/upload_host.dart';
import 'package:wonky_drive/features/uploads/upload_queue.dart';
import 'package:wonky_drive/features/uploads/upload_store.dart';
import 'package:wonky_drive/features/uploads/upload_task.dart';
import 'package:wonky_drive/l10n/drive_l10n.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/upload_fakes.dart';

/// Files dragged from the OS onto Wonky Drive's home (Drive 04 §3.5,
/// AC-D4.4): the overlay names the target, a drop on a folder row uploads
/// into that folder, a drop on the list into the current folder. The OS
/// drag is simulated on `desktop_drop`'s platform channel.
void main() {
  late CommandTestHarness h;
  late FakeUploadApi api;
  late UploadHost host;
  late UploadQueue q;
  late DriveItemView designs;
  late Directory dir;

  setUp(() async {
    h = CommandTestHarness(
      config: const DriveAppConfig(),
      storage: FakeStorage.used(0),
    );
    h.services.router = GoRouter(
      routes: [
        for (final p in const ['/', '/my-drive', '/f/:uuid', '/storage'])
          GoRoute(path: p, builder: (_, _) => const SizedBox()),
      ],
    );
    designs = h.drive.seed(name: 'Designs', kind: DriveItemKind.folder);
    h.drive.seed(name: 'Plan');
    api = FakeUploadApi();
    host = UploadHost.of(h.services)..api = api;
    q = UploadQueue(
      api: api,
      store: MemoryUploadStore(),
      connectivity: h.services.connectivity,
      newId: sequentialIds(),
    );
    host.attach(q);
    await q.start();
    dir = Directory.systemTemp.createTempSync('drive_drop');
  });

  tearDown(() async {
    await host.stop();
    await h.dispose();
    dir.deleteSync(recursive: true);
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await pumpWonky(
      tester,
      DriveHomeScreen(
        services: h.services,
        location: const DriveLocation.myDrive(),
      ),
      size: const Size(1280, 800),
      extraDelegates: const [
        WonkyAppLocalizations.delegate,
        DriveLocalizations.delegate,
      ],
      wrap: (context, child) =>
          Provider<ShellServices>.value(value: h.services, child: child),
    );
    await tester.pumpAndSettle();
  }

  Future<void> channel(String method, Object? args) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            'desktop_drop',
            const StandardMethodCodec().encodeMethodCall(
              MethodCall(method, args),
            ),
            (_) {},
          );

  Future<void> dragTo(WidgetTester tester, Offset p) async {
    await channel('entered', [p.dx, p.dy]);
    await channel('updated', [p.dx, p.dy]);
    await tester.pump();
  }

  /// Drops [names] (small text files on disk) and waits until the queue
  /// has [expected] uploads.
  Future<void> drop(
    WidgetTester tester,
    List<String> names, {
    required int expected,
  }) async {
    final paths = [
      for (final n in names)
        (File(
          '${dir.path}${Platform.pathSeparator}$n',
        )..writeAsStringSync('content of $n')).path,
    ];
    await tester.runAsync(() async {
      await channel('performOperation', paths);
      for (var i = 0; i < 200 && q.tasks.length < expected; i++) {
        await pumpEventQueue();
      }
    });
    await tester.pumpAndSettle();
  }

  Finder overlay() => find.byKey(const ValueKey<String>('drive.dropOverlay'));

  testWidgets('Given My Drive when files are dragged over a folder row then '
      'the overlay says "Upload to Designs" and the drop uploads into it', (
    tester,
  ) async {
    await pumpHome(tester);

    await dragTo(tester, tester.getCenter(find.text('Designs')));

    expect(tester.widget<Text>(overlay()).data, 'Upload to Designs');

    await drop(tester, ['a.txt', 'b.txt'], expected: 2);

    expect(overlay(), findsNothing);
    expect(
      api.requests.map((r) => r.name),
      unorderedEquals(['a.txt', 'b.txt']),
    );
    expect(api.requests.map((r) => r.parentUuid), everyElement(designs.uuid));
    expect(q.tasks.map((t) => t.status), everyElement(UploadStatus.done));
    expect(host.panelVisible.value, isTrue);
  });

  testWidgets('Given My Drive when files are dragged over the list then the '
      'overlay names My Drive and the drop uploads into the root', (
    tester,
  ) async {
    await pumpHome(tester);

    await dragTo(tester, tester.getCenter(find.text('Plan')));

    expect(
      tester.widget<Text>(overlay()).data,
      'Drop files to upload to My Drive',
    );

    await drop(tester, ['notes.md'], expected: 1);

    expect(api.requests.single.parentUuid, isNull);
    expect(api.requests.single.name, 'notes.md');
  });

  testWidgets('Given a drag when it leaves the window then the overlay goes '
      'away and nothing uploads', (tester) async {
    await pumpHome(tester);
    await dragTo(tester, tester.getCenter(find.text('Designs')));

    await channel('exited', null);
    await tester.pump();

    expect(overlay(), findsNothing);
    expect(q.tasks, isEmpty);
  });
}
