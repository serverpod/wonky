import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets/config/sheets_app_config.dart';
import 'package:wonky_sheets/features/formatting/sheets_user_defaults.dart';
import 'package:wonky_sheets/features/settings/sheets_settings.dart';
import 'package:wonky_ui/testing.dart';

/// Sheets settings (D-12, Sheets 04 §11.24, suite 04 §4): J-D6 for Sheets
/// (left menu → Sheets settings › Defaults, account menu → Wonky Work
/// settings, the v1 `/settings/sheets` link and Write's v1 links handed to
/// Write), Defaults in light and dark at 360 px, and `sheets.prefs.set`.
void main() {
  late CommandTestHarness h;

  setUp(() {
    h = CommandTestHarness(config: const SheetsAppConfig());
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
  SheetsUserDefaults defaults() => SheetsUserDefaults.of(h.services);

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

  testWidgets('J-D6: Given the Sheets home when Sheets settings open from '
      'the left menu and the account menu then the page shows the app\'s and '
      'the Wonky Work sections, and the v1 links redirect', (tester) async {
    await pump(tester);

    await tester.tap(key('home.footer.appSettings'));
    await tester.pumpAndSettle();
    expect(location(), '/settings/app/defaults');
    expect(find.text('Sheets settings'), findsWidgets);
    expect(key('settings.nav.app.defaults'), findsOneWidget);
    expect(key('settings.sheets.locale'), findsOneWidget);

    await tester.tap(find.byType(AccountMenuButton));
    await tester.pumpAndSettle();
    // The account menu's one *Settings* entry opens the same page: the
    // app's sections and the Wonky Work sections (suite 04 §4.2).
    await tester.tap(key('account.settings'));
    await tester.pumpAndSettle();
    expect(location(), '/settings/app/defaults');
    for (final id in workSettingsSectionIds) {
      expect(key('settings.nav.$id'), findsOneWidget, reason: id);
    }

    h.services.router.go('/settings/sheets');
    await tester.pumpAndSettle();
    expect(location(), '/settings/app/defaults');

    // Write's v1 sections open Write settings in Write.
    h.services.router.go('/settings/themes');
    await tester.pumpAndSettle();
    expect(h.crossApp.opened, [(WonkyAppKind.write, '/settings/app/themes')]);
    await settleTooltips(tester);
  });

  for (final b in Brightness.values) {
    testWidgets('Given Sheets settings › Defaults at 360 px in ${b.name} '
        'when it shows then nothing overflows and it is accessible', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, size: const Size(360, 780), brightness: b);
      h.services.router.go('/settings/app/defaults');
      await tester.pumpAndSettle();

      expect(key('settings.nav.select.app:defaults'), findsOneWidget);
      expect(key('settings.section.app.defaults'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
      await settleTooltips(tester);
    });
  }

  testWidgets('Given Defaults when a switch is toggled then sheets.prefs.set '
      'stores it', (tester) async {
    await pump(tester);
    h.services.router.go('/settings/app/defaults');
    await tester.pumpAndSettle();

    expect(defaults().enterStartsEditing, isFalse);
    await tester.tap(key('settings.sheets.enterStartsEditing'));
    await tester.pumpAndSettle();
    expect(defaults().enterStartsEditing, isTrue);
    await settleTooltips(tester);
  });

  group('Given sheets.prefs.set (MCP)', () {
    test('when every key is set to a valid value then it is stored', () async {
      final values = <String, Object?>{
        SheetsUserDefaults.keyLocale: 'de_DE',
        SheetsUserDefaults.keyTimeZone: 'Europe/Berlin',
        SheetsUserDefaults.keyFontFamily: 'Lato',
        SheetsUserDefaults.keyFontSize: 12,
        SheetsUserDefaults.keyEnterStartsEditing: true,
        SheetsUserDefaults.keyFormulaAutocomplete: false,
        SheetsUserDefaults.keyFormulaHelp: false,
        SheetsUserDefaults.keyColumnAutocomplete: false,
        SheetsUserDefaults.keyShowEditorMode: false,
        SheetsUserDefaults.keyReduceAnimations: true,
        SheetsUserDefaults.keyScriptsEnabled: false,
        SheetsUserDefaults.keyChartSeriesByPattern: true,
        SheetsUserDefaults.keyCustomFillLists: [
          ['Low', 'High'],
        ],
      };
      expect(values.keys.toSet(), sheetsSettingKeys.keys.toSet());
      for (final e in values.entries) {
        final r = await h.invoke('sheets.prefs.set', {
          'key': e.key,
          'value': e.value,
        });
        expect(r.isOk, isTrue, reason: e.key);
        expect(h.services.prefs.sheetsDefaults[e.key], e.value, reason: e.key);
      }
      expect(defaults().locale, 'de_DE');
      expect(defaults().customFillLists, [
        ['Low', 'High'],
      ]);
    });

    test('when the value has the wrong type then it fails and nothing '
        'changes', () async {
      final r = await h.invoke('sheets.prefs.set', {
        'key': SheetsUserDefaults.keyFontSize,
        'value': 'big',
      });
      expect(r.isOk, isFalse);
      expect(defaults().fontSize, isNull);
    });

    test('when the key is unknown then it is refused', () async {
      await expectLater(
        h.invoke('sheets.prefs.set', {'key': 'nope', 'value': true}),
        throwsA(anything),
      );
    });
  });
}
