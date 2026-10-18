import 'package:flutter/material.dart' show Material, MaterialType, ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write/config/write_app_config.dart';
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/screen/write_document_screen.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write/l10n/write_l10n.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../document/support/session_harness.dart';
import '../sync/support/fake_document_server.dart';

/// The pseudo-locale of specs/11 §4.
const pseudoLocale = Locale('en', 'XA');

/// Every control on the Write screen, shared ones included, carries a
/// label on its tap target.
Future<void> expectLabeledTapTargets(WidgetTester tester) =>
    expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

/// Screen-level accessibility and localization checks for the Write
/// document screen (specs/15 §7, specs/11 §3–4).
void main() {
  late FakeDocumentServer server;
  late CommandTestHarness h;
  late WriteDocumentSession session;
  late SimpleConnectionKeeper keeper;

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Provider<ShellServices>.value(
        value: h.services,
        child: ShadApp(
          theme: WonkyTheme.light(),
          darkTheme: WonkyTheme.dark(),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: locale,
          supportedLocales: const [Locale('en'), pseudoLocale],
          localizationsDelegates: const [
            WonkyAppLocalizations.delegate,
            WonkyUiLocalizations.delegate,
            WriteLocalizations.delegate,
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
    // Derived data (word count) is debounced.
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  setUp(() {
    server = FakeDocumentServer(
      initial: const MarkdownCodec()
          .importMarkdown('# Plan\n\nHello world\n\n## Budget\n\nMoney\n')
          .delta,
    );
    h = CommandTestHarness(
      config: const WriteAppConfig(),
      comments: FakeComments(),
    );
    h.drive.seed(name: 'Plan', uuid: UuidValue.fromString(itemUuid));
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
    keeper.dispose();
    await pumpEventQueue();
    await h.dispose();
  });

  for (final b in Brightness.values) {
    testWidgets('Given the document screen in ${b.name} mode when it renders '
        'then text contrast and labeled tap targets meet the guidelines', (
      tester,
    ) async {
      await pumpScreen(tester, brightness: b);

      expect(session.phase.value, WriteSessionPhase.ready);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLabeledTapTargets(tester);
      await unmount(tester);
    });
  }

  testWidgets('Given the document screen when it renders then every '
      'toolbar button has a semantics label', (tester) async {
    await pumpScreen(tester);

    var checked = 0;
    for (final id in [
      'format.bold',
      'format.italic',
      'list.toggleBulleted',
      'link',
      'image',
      'table',
    ]) {
      final f = find.byKey(ValueKey<String>('write.toolbar.$id'));
      if (f.evaluate().isEmpty) continue;
      checked++;
      // The keyed widget or one of its descendants carries the label (split
      // buttons label their action part).
      final labels = [
        tester.getSemantics(f.first).label,
        for (final e
            in find
                .descendant(of: f.first, matching: find.byType(Semantics))
                .evaluate())
          tester.getSemantics(find.byWidget(e.widget).first).label,
      ];
      expect(
        labels.any((l) => l.isNotEmpty),
        isTrue,
        reason: 'write.toolbar.$id',
      );
    }
    expect(checked, greaterThan(2));
    await unmount(tester);
  });

  for (final width in [1280.0, 1440.0]) {
    testWidgets('Given the en_XA pseudo-locale in a ${width.toInt()} px window '
        'when the screen renders then the Write strings are pseudo-localized '
        'and nothing overflows', (tester) async {
      await pumpScreen(tester, size: Size(width, 900), locale: pseudoLocale);

      expect(session.phase.value, WriteSessionPhase.ready);
      final l = lookupWriteLocalizations(pseudoLocale);
      expect(l.cmdFormatBold, isNot(writeL10nEnglish.cmdFormatBold));
      final context = tester.element(find.byType(WriteDocumentScreen));
      expect(writeL10n(context).localeName, 'en_XA');
      expect(tester.takeException(), isNull);
      await unmount(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
