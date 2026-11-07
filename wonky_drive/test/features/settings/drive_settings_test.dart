import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_drive/config/drive_app_config.dart';
import 'package:wonky_drive/l10n/drive_l10n.dart';
import 'package:wonky_ui/testing.dart';

/// Drive settings (D-12 slot, D-17 settings, Drive 04 §8): J-D6 for Drive —
/// the left menu opens *Drive settings* at `/settings/app/drive`, the
/// account menu *Wonky Work settings* — the controls go through
/// `drive.prefs.set`, in light and dark, at 360 px and in the pseudo-locale.
void main() {
  late CommandTestHarness h;

  setUp(() {
    h = CommandTestHarness(config: const DriveAppConfig());
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
    Locale? locale,
  }) async {
    await pumpWonky(
      tester,
      Router.withConfig(config: h.services.router),
      size: size,
      brightness: brightness,
      wrap: locale == null
          ? null
          : (context, child) => Localizations.override(
              context: context,
              locale: locale,
              child: child,
            ),
      extraDelegates: const [
        WonkyAppLocalizations.delegate,
        DriveLocalizations.delegate,
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('J-D6: Given the Drive home when Drive settings open from the '
      'left menu and the account menu then the page shows the app\'s and the '
      'Wonky Work sections', (tester) async {
    await pump(tester);

    await tester.tap(key('home.footer.appSettings'));
    await tester.pumpAndSettle();
    expect(location(), '/settings/app/drive');
    expect(find.text('Drive settings'), findsWidgets);
    expect(key('settings.drive'), findsOneWidget);

    await tester.tap(find.byType(AccountMenuButton));
    await tester.pumpAndSettle();
    // The account menu's one *Settings* entry opens the same page: the
    // app's sections and the Wonky Work sections (suite 04 §4.2).
    await tester.tap(key('account.settings'));
    await tester.pumpAndSettle();
    expect(location(), '/settings/app/drive');
    for (final id in workSettingsSectionIds) {
      expect(key('settings.nav.$id'), findsOneWidget, reason: id);
    }

    // Write's and Sheets' v1 links hand over to their apps.
    h.services.router.go('/settings/sheets');
    await tester.pumpAndSettle();
    expect(h.crossApp.opened, [
      (WonkyAppKind.sheets, '/settings/app/defaults'),
    ]);
    await settleTooltips(tester);
  });

  testWidgets('Given Drive settings when the switches and selects are '
      'changed then each change is drive.prefs.set and is stored', (
    tester,
  ) async {
    final invoked = <Object?>[];
    h.services.dispatcher.events.listen((e) {
      if (e.id.value == 'drive.prefs.set') invoked.add(e.args['key']);
    });
    await pump(tester);
    h.services.router.go('/settings/app/drive');
    await tester.pumpAndSettle();

    expect(
      tester.widget<ShadSwitch>(key('settings.drive.convertUploads')).value,
      isFalse,
    );
    await tester.tap(key('settings.drive.showExtensions'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(key('settings.drive.convertUploads'));
    await tester.tap(key('settings.drive.convertUploads'));
    await tester.pumpAndSettle();
    await tester.tap(key('settings.drive.layout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(driveL10nEnglish.driveSettingsLayoutGrid).last);
    await tester.pumpAndSettle();

    expect(invoked, ['showExtensions', 'convertUploads', 'layout']);
    expect(h.services.prefs.driveDefaults, {
      'showExtensions': false,
      'convertUploads': true,
      'layout': 'grid',
    });
    expect(
      tester.widget<ShadSwitch>(key('settings.drive.convertUploads')).value,
      isTrue,
    );
    await settleTooltips(tester);
  });

  testWidgets('Given the pseudo-locale when Drive settings show at 360 px '
      'then nothing overflows', (tester) async {
    await pump(
      tester,
      size: const Size(360, 780),
      locale: const Locale('en', 'XA'),
    );
    h.services.router.go('/settings/app/drive');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ðéƒåûļţ ļåýöûţ'), findsOneWidget);
    await settleTooltips(tester);
  });

  for (final b in Brightness.values) {
    testWidgets('Given Drive settings at 360 px in ${b.name} when they show '
        'then nothing overflows and the page is accessible', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, size: const Size(360, 780), brightness: b);
      h.services.router.go('/settings/app');
      await tester.pumpAndSettle();

      expect(location(), '/settings/app/drive');
      expect(key('settings.nav.select.app:drive'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
      await settleTooltips(tester);
    });
  }
}
