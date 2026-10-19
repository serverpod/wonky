import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_slides/config/slides_app_config.dart';
import 'package:wonky_slides/features/settings/slides_settings.dart';
import 'package:wonky_slides/features/settings/slides_user_defaults.dart';
import 'package:wonky_slides/features/revlog/slides_rev_log.dart'
    show newPresentationDefaults;
import 'package:wonky_slides_core/themes.dart'
    show SlideAppearance, SlideSizeKind;
import 'package:wonky_slides/l10n/slides_l10n.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/slides_harness.dart';

/// Slides settings (Slides 04 §13.16): the app settings sections at
/// `/settings/app/<section>`, every control through `slides.prefs.set` /
/// `slides.presenter.set`.
void main() {
  final l = slidesL10nEnglish;
  late CommandTestHarness h;

  setUp(() => h = slidesHarness());
  tearDown(() => h.dispose());

  test('Given the Slides app config when its settings are listed then the '
      'sections are presentations, editing, animations & code (the Code '
      'group since SL-31) and presenting', () {
    final sections = const SlidesAppConfig().appSettingsSections(h.services);
    expect(
      [for (final s in sections) s.id],
      ['presentations', 'editing', 'animations', 'presenting'],
    );
  });

  for (final page in SlidesSettingsPage.values) {
    for (final (size, brightness) in [
      (const Size(1280, 900), Brightness.light),
      (const Size(360, 900), Brightness.dark),
    ]) {
      testWidgets('Given the ${page.name} settings at ${size.width.toInt()} px '
          '(${brightness.name}) when shown then they render without '
          'overflow', (tester) async {
        await pumpSlides(
          tester,
          h,
          SingleChildScrollView(
            child: SlidesSettingsSection(services: h.services, section: page),
          ),
          size: size,
          brightness: brightness,
        );

        expect(
          find.byKey(ValueKey<String>('settings.slides.${page.name}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await settleTooltips(tester);
      });
    }
  }

  testWidgets('Given the Editing settings when a switch is flipped then the '
      'synced Slides setting changes through slides.prefs.set', (tester) async {
    await pumpSlides(
      tester,
      h,
      SingleChildScrollView(
        child: SlidesSettingsSection(
          services: h.services,
          section: SlidesSettingsPage.editing,
        ),
      ),
    );
    final d = SlidesUserDefaults.of(h.services);
    expect(d.flag(SlidesUserDefaults.keySmartGuides), isTrue);

    await tester.tap(
      find.byKey(const ValueKey<String>('settings.slides.smartGuides')),
    );
    await tester.pumpAndSettle();

    expect(d.flag(SlidesUserDefaults.keySmartGuides), isFalse);
    expect(h.services.prefs.slidesDefaults['smartGuides'], false);
    // Settings of features that are not built are hidden (SL-23).
    for (final hidden in [
      l.settingsSmartQuotes,
      l.settingsAutoformatLists,
      l.settingsUnits,
      l.settingsScrollChangesSlides,
    ]) {
      expect(find.text(hidden), findsNothing, reason: hidden);
    }
    // Spelling ships with SL-44: *Underline spelling errors*.
    expect(find.text(l.settingsSpelling), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('settings.slides.underlineSpelling')),
    );
    await tester.pumpAndSettle();
    expect(d.flag(SlidesUserDefaults.keyUnderlineSpelling), isFalse);
    await settleTooltips(tester);
  });

  testWidgets('Given the Presenting settings when a switch is flipped then '
      'the presenter preference changes', (tester) async {
    await pumpSlides(
      tester,
      h,
      SingleChildScrollView(
        child: SlidesSettingsSection(
          services: h.services,
          section: SlidesSettingsPage.presenting,
        ),
      ),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('settings.slides.startWithPresenterView'),
      ),
    );
    await tester.pumpAndSettle();

    expect(h.services.prefs.slidesPresenter['startWithPresenterView'], true);
    await settleTooltips(tester);
  });

  test('Given the settings command when MCP reads its schema then only '
      'settings of built features are advertised (SL-23)', () {
    final schema =
        '${h.services.registry.byId('slides.prefs.set')!.argsSchema.toJson()}';
    expect(schema, contains(SlidesUserDefaults.keySmartGuides));
    expect(schema, contains(SlidesUserDefaults.keyDefaultThemeKey));
    // Code blocks ship with SL-31; key clicks while typing (P2) don't.
    expect(schema, contains(SlidesUserDefaults.keyCodeFontSize));
    // Linked charts ship with SL-32.
    expect(schema, contains(SlidesUserDefaults.keyChartsAutoUpdate));
    // Animations ship with SL-29 + SL-30.
    expect(schema, contains(SlidesUserDefaults.keyDefaultTransition));
    // Spelling and the presentation language ship with SL-44.
    expect(schema, contains(SlidesUserDefaults.keyUnderlineSpelling));
    expect(schema, contains(SlidesUserDefaults.keyDefaultLanguage));
    for (final hidden in [
      SlidesUserDefaults.keySmartQuotes,
      SlidesUserDefaults.keyTypeInSound,
    ]) {
      expect(schema, isNot(contains(hidden)), reason: hidden);
      expect(offersDefaultsKey(hidden), isFalse, reason: hidden);
    }
  });

  test('Given New presentations settings when a blank deck is created then '
      'it takes the default theme and size, and the appearance only when '
      'chosen', () async {
    var d = newPresentationDefaults(h.services);
    expect(d.appearance, isNull);
    final defaults = SlidesUserDefaults.of(h.services);
    await defaults.set(SlidesUserDefaults.keyDefaultThemeKey, 'swiss');
    await defaults.set(SlidesUserDefaults.keyDefaultSize, 'standard4x3');
    await defaults.set(SlidesUserDefaults.keyDefaultAppearance, 'dark');
    d = newPresentationDefaults(h.services);
    expect(d.themeKey, 'swiss');
    expect(d.size?.kind, SlideSizeKind.standard4x3);
    expect(d.appearance, SlideAppearance.dark);
  });
}
