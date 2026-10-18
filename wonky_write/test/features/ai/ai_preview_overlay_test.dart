import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write/config/write_app_config.dart';
import 'package:wonky_write/features/ai/write_ai_controller.dart';
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/screen/write_document_screen.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

void main() {
  late FakeDocumentServer server;
  late CommandTestHarness h;
  late WriteDocumentSession session;
  late SimpleConnectionKeeper keeper;
  late FakeAssistantApi api;

  Future<void> settle(WidgetTester tester, [int rounds = 8]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> pumpScreen(WidgetTester tester, {bool dark = false}) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      Provider<ShellServices>.value(
        value: h.services,
        child: ShadApp(
          theme: dark ? WonkyTheme.dark() : WonkyTheme.light(),
          localizationsDelegates: const [
            WonkyAppLocalizations.delegate,
            WonkyUiLocalizations.delegate,
          ],
          home: Material(
            type: MaterialType.transparency,
            child: WonkyThemeScope(
              data: const WonkyThemeExtension(),
              child: WriteDocumentScreen(
                services: h.services,
                itemUuid: itemUuid,
                themes: WriteThemeCatalog(),
                sessionFactory: (s, uuid) => session,
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(pumpEventQueue);
      await tester.pump(const Duration(milliseconds: 50));
      if (session.phase.value == WriteSessionPhase.ready && i > 10) break;
    }
  }

  setUp(() async {
    server = FakeDocumentServer(
      initial: const MarkdownCodec()
          .importMarkdown('# Plan\n\nTeh old plan is fine.\n')
          .delta,
    );
    h = CommandTestHarness(
      config: const WriteAppConfig(),
      comments: FakeComments(),
    );
    h.drive.seed(name: 'Plan', uuid: UuidValue.fromString(itemUuid));
    api = FakeAssistantApi();
    final assistant = ShellAssistant.install(h.services, api: api);
    await assistant.refreshStatus();
    keeper = SimpleConnectionKeeper(minDelay: Duration.zero);
    session = WriteDocumentSession(
      services: h.services,
      itemUuid: itemUuid,
      api: FakeWriteApi(server),
      keeper: keeper,
    );
  });

  tearDown(() async {
    await pumpEventQueue();
    ShellAssistant.uninstall(h.services);
    keeper.dispose();
    await pumpEventQueue();
    await h.dispose();
  });

  for (final dark in [false, true]) {
    testWidgets(
      'Given a selection in ${dark ? 'dark' : 'light'} mode when an AI '
      'rewrite streams then the preview card shows it and Replace applies it',
      (tester) async {
        await pumpScreen(tester, dark: dark);
        api.inlineScripts.add([
          InlineAiEvent(type: InlineAiEventType.textDelta, text: 'The '),
          InlineAiEvent(
            type: InlineAiEventType.done,
            markdown: 'The new plan is fine.',
          ),
        ]);
        final ai = WriteAiController.forItem(UuidValue.fromString(itemUuid))!;
        session.editor.select(const DeltaSelection(5, 26));
        await tester.runAsync(
          () => h.invoke('write.ai.rewriteSelection', const {
            'mode': 'improve',
          }, InvocationSource.ui),
        );
        await settle(tester);

        expect(find.byKey(const ValueKey('write.ai.preview')), findsOneWidget);
        expect(
          find.textContaining('The new plan is fine.', findRichText: true),
          findsWidgets,
        );
        expect(ai.preview!.canApply, isTrue);

        await tester.tap(find.byKey(const ValueKey('write.ai.preview.diff')));
        await settle(tester, 2);
        expect(
          find.byKey(const ValueKey('write.ai.preview.diffText')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey('write.ai.preview.replace')),
        );
        await settle(tester);
        expect(find.byKey(const ValueKey('write.ai.preview')), findsNothing);
        expect(DeltaUtils.text(session.editor.delta), contains('The new plan'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      },
    );
  }

  testWidgets('Given a preview when Escape is pressed then it is discarded', (
    tester,
  ) async {
    await pumpScreen(tester);
    api.inlineScripts.add([
      InlineAiEvent(type: InlineAiEventType.done, markdown: 'Shorter.'),
    ]);
    session.editor.select(const DeltaSelection(5, 26));
    await tester.runAsync(
      () => h.invoke('write.ai.rewriteSelection', const {
        'mode': 'shorter',
      }, InvocationSource.ui),
    );
    await settle(tester);
    expect(find.byKey(const ValueKey('write.ai.preview')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester, 2);
    expect(find.byKey(const ValueKey('write.ai.preview')), findsNothing);
    expect(DeltaUtils.text(session.editor.delta), contains('Teh old plan'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'Given the screen when the assistant panel is toggled then the shared '
    'panel shows with the privacy notice',
    (tester) async {
      await pumpScreen(tester);
      await tester.runAsync(
        () => h.invoke('shell.ai.togglePanel', const {}, InvocationSource.ui),
      );
      await settle(tester);
      expect(find.byKey(const ValueKey('assistant.panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('assistant.notice')), findsOneWidget);
      expect(find.text('Summarize'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
