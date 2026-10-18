import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/testing.dart';

/// A drive whose `markOpened` waits for [gate] (a slow network).
class _SlowOpenDrive extends FakeDriveRepository {
  // Replaced in each test body (pumpEditor): a completer made in setUp completes in
  // the real zone, outside the fake async of testWidgets.
  Completer<void> gate = Completer<void>();

  @override
  Future<DriveItemView> markOpened(UuidValue uuid) async {
    await gate.future;
    return super.markOpened(uuid);
  }
}

/// H-3: presence and comments start only for a live editor.
void main() {
  late _SlowOpenDrive drive;
  late CommandTestHarness h;

  setUp(() {
    drive = _SlowOpenDrive();
    h = CommandTestHarness(drive: drive);
  });
  tearDown(() => h.dispose());

  Future<String> pumpEditor(WidgetTester tester) async {
    final doc = h.drive.seed(name: 'Plan');
    drive.gate = Completer<void>();
    await pumpWonky(
      tester,
      EditorScaffold(
        services: h.services,
        itemUuid: doc.uuid.uuid,
        body: (context, item) => const SizedBox.expand(),
        commentsButton: false,
        historyPanel: false,
        showStatusBar: false,
      ),
      size: const Size(1280, 800),
      extraDelegates: const [WonkyAppLocalizations.delegate],
      wrap: (context, child) =>
          Provider<ShellServices>.value(value: h.services, child: child!),
    );
    await tester.pump();
    return doc.uuid.uuid;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('Given an editor that is left before the item loaded when the '
      'item arrives then presence and comments do not start', (tester) async {
    final uuid = await pumpEditor(tester);
    await unmount(tester);

    drive.gate.complete();
    await tester.pump();
    await tester.pump();

    expect(h.services.supervisor.isActive('presence:$uuid'), isFalse);
    expect(h.services.supervisor.isActive('comments:$uuid'), isFalse);
  });

  testWidgets('Given an open editor when the item arrives then presence and '
      'comments start', (tester) async {
    final uuid = await pumpEditor(tester);

    drive.gate.complete();
    await tester.pump();
    await tester.pump();

    expect(h.services.supervisor.isActive("presence:$uuid"), isTrue);
    expect(h.services.supervisor.isActive('comments:$uuid'), isTrue);
    await unmount(tester);
    expect(h.services.supervisor.isActive('presence:$uuid'), isFalse);
  });

  group('Given disposed sessions', () {
    final uuid = UuidValue.fromString('0199f000-0000-7000-8000-000000000001');

    test('when presence is started then it does not join the roster', () {
      final session = PresenceSession(services: h.services, itemUuid: uuid)
        ..dispose();

      session.start();

      expect(h.services.supervisor.isActive('presence:${uuid.uuid}'), isFalse);
      expect(session.isStarted, isFalse);
    });

    test('when comments are started then no stream is watched', () async {
      final comments = CommentsController(services: h.services, itemUuid: uuid)
        ..dispose();

      await comments.start();

      expect(h.services.supervisor.isActive('comments:${uuid.uuid}'), isFalse);
    });

    test('when a never-started session is disposed then a live session of '
        'the same file keeps its stream', () {
      final live = PresenceSession(services: h.services, itemUuid: uuid);
      addTearDown(live.dispose);
      live.start();

      PresenceSession(services: h.services, itemUuid: uuid).dispose();

      expect(h.services.supervisor.isActive('presence:${uuid.uuid}'), isTrue);
    });
  });
}
