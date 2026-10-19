import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show DriveItemKind;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/testing.dart';

/// CQ-39 (shell rebuild counters, CQ-38): document changes (typing,
/// selection moves) must not rebuild the keymap, the document body or the
/// toolbar from the scaffold, and command-state signals are coalesced to
/// one per frame.
void main() {
  late CommandTestHarness h;

  setUp(() => h = CommandTestHarness());
  tearDown(() => h.dispose());

  group('Given an open editor', () {
    late BasicDocumentController doc;
    late int bodyBuilds;
    late int toolbarBuilds;
    late int commandWidgetBuilds;
    late int keymapRebuilds;

    Future<void> pumpEditor(WidgetTester tester) async {
      final item = h.drive.seed(name: 'Plan');
      doc = BasicDocumentController(
        itemUuid: item.uuid,
        kind: DriveItemKind.document,
        role: Role.owner,
      );
      bodyBuilds = 0;
      toolbarBuilds = 0;
      commandWidgetBuilds = 0;
      keymapRebuilds = 0;
      h.services.keymap.addListener(() => keymapRebuilds++);
      await pumpWonky(
        tester,
        EditorScaffold(
          services: h.services,
          itemUuid: item.uuid.uuid,
          controller: doc,
          toolbar: (context) {
            toolbarBuilds++;
            // A command widget: listens to the registry itself.
            return ListenableBuilder(
              listenable: h.services.registry,
              builder: (context, _) {
                commandWidgetBuilds++;
                return const SizedBox(height: 32);
              },
            );
          },
          body: (context, item) {
            bodyBuilds++;
            return const SizedBox.expand();
          },
          commentsButton: false,
          historyPanel: false,
          showStatusBar: false,
        ),
        size: const Size(1280, 800),
        extraDelegates: const [WonkyAppLocalizations.delegate],
        wrap: (context, child) =>
            Provider<ShellServices>.value(value: h.services, child: child!),
      );
      // Item loaded, document activated.
      await tester.pump();
      await tester.pump();
      expect(h.services.activeDocument.value, same(doc));
      bodyBuilds = 0;
      toolbarBuilds = 0;
      commandWidgetBuilds = 0;
      keymapRebuilds = 0;
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    }

    testWidgets('when the document changes 20 times in one frame then the '
        'body, the toolbar builder and the keymap are not rebuilt and command '
        'widgets rebuild once', (tester) async {
      await pumpEditor(tester);

      for (var i = 0; i < 20; i++) {
        doc.update(title: 'Plan $i');
      }
      await tester.pump();

      expect(bodyBuilds, 0);
      expect(toolbarBuilds, 0);
      expect(keymapRebuilds, 0);
      expect(commandWidgetBuilds, 1);
      await unmount(tester);
    });

    testWidgets('when the document changes once per frame for 10 frames then '
        'command widgets rebuild once per frame and the body never', (
      tester,
    ) async {
      await pumpEditor(tester);

      for (var i = 0; i < 10; i++) {
        doc.update(title: 'Plan $i');
        await tester.pump();
      }

      expect(commandWidgetBuilds, 10);
      expect(bodyBuilds, 0);
      expect(keymapRebuilds, 0);
      await unmount(tester);
    });
  });

  group('Given a command registry', () {
    testWidgets('when the state changes several times before a frame then '
        'listeners run once, at the frame', (tester) async {
      final registry = CommandRegistry();
      addTearDown(registry.dispose);
      var notified = 0;
      registry.addListener(() => notified++);

      registry
        ..notifyStateChanged()
        ..notifyStateChanged()
        ..notifyStateChanged();
      final before = notified;
      await tester.pump();

      expect(before, 0);
      expect(notified, 1);
    });

    testWidgets('when the state changes then registration listeners are not '
        'notified', (tester) async {
      final registry = CommandRegistry();
      addTearDown(registry.dispose);
      var registrations = 0;
      registry.registrations.addListener(() => registrations++);

      registry.notifyStateChanged();
      await tester.pump();

      expect(registrations, 0);
    });

    testWidgets('when a command is registered then both signals notify '
        'synchronously', (tester) async {
      final registry = CommandRegistry();
      addTearDown(registry.dispose);
      var registrations = 0;
      var changes = 0;
      registry.registrations.addListener(() => registrations++);
      registry.addListener(() => changes++);

      registry.register(
        CallbackCommand(
          id: 'test.thing.run',
          title: (_) => 'Run',
          run: (_, _) async => const CommandResult.ok(),
        ),
      );

      expect(registrations, 1);
      expect(changes, 1);
    });

    testWidgets('when commands are registered then the keymap rebuilds, and '
        'on state changes it does not', (tester) async {
      var keymapRebuilds = 0;
      h.services.keymap.addListener(() => keymapRebuilds++);

      h.services.registry.notifyStateChanged();
      await tester.pump();
      final afterState = keymapRebuilds;
      h.services.registry.register(
        CallbackCommand(
          id: 'test.thing.run',
          title: (_) => 'Run',
          run: (_, _) async => const CommandResult.ok(),
        ),
      );

      expect(afterState, 0);
      expect(keymapRebuilds, 1);
    });
  });
}
