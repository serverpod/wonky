import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/testing.dart';
import 'package:wonky_write/config/write_app_config.dart';
import 'package:wonky_write/config/write_menus.dart';

/// Write settings (D-12, Write 05 §13.3, suite 04 §4): J-D6 for Write
/// (left menu → Write settings, account menu → Wonky Work settings, the v1
/// `/settings/write` link), the four sections in light and dark at 360 px,
/// and every setting as a command (MCP `ui.invoke_command`).
void main() {
  late CommandTestHarness h;

  setUp(() {
    h = CommandTestHarness(config: const WriteAppConfig());
    Page<void> page(GoRouterState st, Widget child) =>
        NoTransitionPage<void>(key: st.pageKey, child: child);
    h.services.router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (c, st) => page(
            st,
            DriveHomeScreen(
              services: h.services,
              location: const DriveLocation.myDrive(),
            ),
          ),
        ),
        ...settingsRoutes(h.services, page),
      ],
    );
  });
  tearDown(() => h.dispose());

  Finder key(String k) => find.byKey(ValueKey<String>(k));
  String location() => h.services.router.state.uri.toString();

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1280, 900),
    Brightness brightness = Brightness.light,
  }) async {
    await pumpWonky(
      tester,
      Router.withConfig(config: h.services.router),
      size: size,
      brightness: brightness,
      extraDelegates: const [WonkyAppLocalizations.delegate],
      wrap: (context, child) =>
          Provider<ShellServices>.value(value: h.services, child: child!),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  testWidgets('J-D6: Given the Write home when Write settings open from the '
      'left menu and Wonky Work settings from the account menu then each '
      'shows its sections, and /settings/write redirects', (tester) async {
    await pump(tester);

    await tester.tap(key('home.footer.appSettings'));
    await tester.pumpAndSettle();
    expect(location(), '/settings/app/editor');
    expect(find.text('Write settings'), findsWidgets);
    for (final id in ['editor', 'page', 'themes', 'spelling']) {
      expect(key('settings.nav.app.$id'), findsOneWidget, reason: id);
    }
    expect(key('settings.section.app.editor'), findsOneWidget);

    await tester.tap(find.byType(AccountMenuButton));
    await tester.pumpAndSettle();
    await tester.tap(key('account.settings'));
    await tester.pumpAndSettle();
    expect(location(), '/settings/account');
    expect(find.text('Wonky Work settings'), findsWidgets);
    for (final id in workSettingsSectionIds) {
      expect(key('settings.nav.$id'), findsOneWidget, reason: id);
    }

    h.services.router.go('/settings/write');
    await tester.pumpAndSettle();
    expect(location(), '/settings/app/editor');
    h.services.router.go('/settings/themes');
    await tester.pumpAndSettle();
    expect(location(), '/settings/app/themes');
    await settleTooltips(tester);
  });

  for (final b in Brightness.values) {
    testWidgets('Given each Write settings section at 360 px in ${b.name} '
        'when it shows then nothing overflows and it is accessible', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await h.services.prefs.setWriteDefault('personalDictionary', [
        'Wonky',
        'serverpod',
      ]);
      await pump(tester, size: const Size(360, 780), brightness: b);
      for (final id in ['editor', 'page', 'themes', 'spelling']) {
        h.services.router.go('/settings/app/$id');
        await tester.pumpAndSettle();
        expect(key('settings.section.app.$id'), findsOneWidget, reason: id);
        await expectAccessible(tester);
      }
      semantics.dispose();
      await settleTooltips(tester);
    });
  }

  testWidgets('Given Write settings › Editor when a switch is toggled then '
      'its command changes the preference', (tester) async {
    await pump(tester);
    h.services.router.go('/settings/app/editor');
    await tester.pumpAndSettle();

    await tester.tap(key('settings.write.markdownShortcuts'));
    await tester.pumpAndSettle();
    expect(h.services.prefs.writeDefaults['markdownShortcuts'], false);
    await tester.tap(key('settings.write.spellcheck'));
    await tester.pumpAndSettle();
    expect(h.services.prefs.writeDefaults['spellcheck'], false);
    await settleTooltips(tester);
  });

  testWidgets('Given Write settings › Spelling when a word is removed then '
      'the personal dictionary no longer has it', (tester) async {
    await h.services.prefs.setWriteDefault('personalDictionary', [
      'Wonky',
      'serverpod',
    ]);
    await pump(tester);
    h.services.router.go('/settings/app/spelling');
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Remove Wonky'));
    await tester.pumpAndSettle();
    expect(h.services.prefs.writeDefaults['personalDictionary'], ['serverpod']);
    expect(key('settings.write.dictionary.Wonky'), findsNothing);
    await settleTooltips(tester);
  });

  group('Given every Write setting as a command (MCP)', () {
    test('when the editor preferences are invoked with arguments then they '
        'are stored', () async {
      for (final (id, key) in [
        ('write.prefs.setMarkdownShortcuts', 'markdownShortcuts'),
        ('write.prefs.setSmartTypography', 'smartQuotes'),
        ('write.prefs.setAutoPair', 'autoPairBrackets'),
        ('write.prefs.setAutolink', 'autolink'),
        ('write.prefs.setCopyAsMarkdown', 'copyAsMarkdown'),
        ('write.prefs.setSelectionToolbar', 'selectionToolbar'),
        ('write.spell.toggle', 'spellcheck'),
      ]) {
        final r = await h.invoke(id, {'enabled': false});
        expect(r.isOk, isTrue, reason: id);
        expect(h.services.prefs.writeDefaults[key], false, reason: id);
      }
      expect((await h.invoke('write.spell.toggleIgnoreUppercase')).isOk, true);
      expect(
        h.services.prefs.writeDefaults['spellcheckIgnoreUppercase'],
        false,
      );
      await h.invoke('write.prefs.setDefaultMode', {'mode': 'suggesting'});
      expect(h.services.prefs.writeDefaults['defaultMode'], 'suggesting');
    });

    test('when the page and export defaults are invoked then they are '
        'stored, and invalid values fail', () async {
      // Unset: new documents are Pageless (T-1).
      expect(
        h.services.dispatcher.stateOf('write.prefs.setDefaultLayout', {
          'layout': 'pageless',
        }).checked,
        isTrue,
      );
      await h.invoke('write.prefs.setDefaultLayout', {'layout': 'pages'});
      expect(h.services.prefs.writeDefaults['pageless'], false);
      await h.invoke('write.prefs.setDefaultLayout', {'layout': 'pageless'});
      expect(h.services.prefs.writeDefaults['pageless'], true);
      await h.invoke('write.prefs.setExportFormat', {'format': 'docx'});
      expect(h.services.prefs.writeDefaults['exportFormat'], 'docx');
      // Schema validation refuses unknown formats (invalid_args).
      await expectLater(
        h.invoke('write.prefs.setExportFormat', {'format': 'exe'}),
        throwsA(anything),
      );
      expect(h.services.prefs.writeDefaults['exportFormat'], 'docx');

      await h.services.prefs.setWriteDefault('pageSetup', {'layout': 'pages'});
      await h.invoke('write.prefs.resetPageSetup');
      expect(h.services.prefs.writeDefaults['pageSetup'], isNull);
    });

    test('when a dictionary word is removed then it is gone; an unknown '
        'word fails', () async {
      await h.services.prefs.setWriteDefault('personalDictionary', ['a', 'b']);
      await h.invoke('write.prefs.removeDictionaryWord', {'word': 'a'});
      expect(h.services.prefs.writeDefaults['personalDictionary'], ['b']);
      final r = await h.invoke('write.prefs.removeDictionaryWord', {
        'word': 'zzz',
      });
      expect(r.isOk, isFalse);
    });

    test('when the menus are built then Tools › Preferences offers Write '
        'settings and Wonky Work settings', () {
      final menus = writeMenus(
        ShellMenus(lookupWonkyAppLocalizations(const Locale('en'))),
      );
      final byId = {for (final c in menus.commands) c.effectiveId: c};
      expect(byId['tools.writePrefs.all']?.commandId, 'shell.settings.openApp');
      expect(byId['tools.writePrefs.work']?.commandId, 'shell.settings.open');
      expect(byId['tools.writePrefs.work']?.args, {'section': 'account'});
      expect(byId.containsKey(ShellMenuIds.toolsAppSettings), isFalse);
      expect(byId.containsKey(ShellMenuIds.toolsWorkSettings), isFalse);
    });
  });
}
