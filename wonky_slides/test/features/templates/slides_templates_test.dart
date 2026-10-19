import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart' show DriveHomeScreen, DriveLocation;
import 'package:wonky_ui/testing.dart';
import 'package:wonky_client/wonky_client.dart'
    show DriveItemKind, TemplateCategory, TemplateView, UuidValue;
import 'package:wonky_slides/config/slides_app_config.dart';
import 'package:wonky_slides/features/accessibility/accessibility_checker.dart';
import 'package:wonky_slides/features/stage/slide_renderer.dart';
import 'package:wonky_slides/features/revlog/slides_rev_log.dart';
import 'package:wonky_slides/features/thumbnails/slide_thumbnail.dart';
import 'package:wonky_slides_core/templates.dart';
import 'package:wonky_slides_core/themes.dart' show SlideAppearance;
import 'package:wonky_sync_models/ids.dart' show SequentialIdGenerator;

import '../../revlog/support/deck_harness.dart';
import '../../support/slides_harness.dart';
import '../text_editing/text_edit_fixture.dart' show realFonts;

TemplateView _view(SlidesTemplate t, {bool builtin = true}) => TemplateView(
  uuid: UuidValue.fromString(t.uuid),
  key: t.key,
  kind: DriveItemKind.presentation,
  name: t.name,
  description: t.description,
  category: TemplateCategory.values.byName(t.category),
  builtin: builtin,
  previewText: '# ${t.name}\n${t.subtitle}',
);

void main() {
  const config = SlidesAppConfig();

  group('Given a signed-in user with the Slides data layer', () {
    late CommandTestHarness h;

    setUp(() async {
      final hub = slidesHub();
      h = CommandTestHarness(config: config);
      addTearDown(h.dispose);
      final me = h.services.me!.uuid;
      final dir = await Directory.systemTemp.createTemp('wonky_slides_tpl_');
      addTearDown(() async {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      });
      SlidesRevLog.directoryOverride = dir.path;
      addTearDown(() => SlidesRevLog.directoryOverride = null);
      SlidesRevLog.install(h.services, transport: () => hub.transport(me.uuid));
      addTearDown(() => SlidesRevLog.uninstall(h.services));
    });

    test('when a built-in template is chosen offline then its deck is '
        'created locally, registered with the space as item uuid and opens '
        'with every slide', () async {
      final c = (await SlidesRevLog.ready(h.services))!;
      h.services.connectivity.forceOffline(true);
      await eventually(() => !c.keeper.online);
      final t = SlidesTemplates.byKey('slides.lesson')!;

      final uuid = await config.createItem(
        h.services,
        templateUuid: UuidValue.fromString(t.uuid),
        name: t.name,
      );

      expect(uuid, isNotNull);
      expect(h.drive.calls, contains('registerPresentation'));
      expect(h.drive.calls, isNot(contains('createPresentation')));
      expect(h.drive.item(uuid!).name, 'Lesson');
      expect(await c.store.outbox(uuid.uuid), isNotEmpty);
      final s = await openDeckSession(h.services, uuid);
      addTearDown(s.dispose);
      await (s as LoggedDeckSession).opened;
      await whenReady(s);
      final expected = SlidesTemplateDecksForTest.of(t);
      expect(s.model.deck?.title, 'Lesson');
      expect(s.model.slides, hasLength(expected.model.slides.length));
      expect(s.model.groups, hasLength(expected.model.groups.length));
    });

    test('when a template that is not built in is chosen then the server '
        'copies it', () async {
      await SlidesRevLog.ready(h.services);

      await config.createItem(
        h.services,
        templateUuid: UuidValue.fromString(
          '0192f0a0-0000-7000-8000-00000000beef',
        ),
        name: 'Team template',
      );

      expect(h.drive.calls, contains('createPresentation'));
      expect(h.drive.calls, isNot(contains('registerPresentation')));
    });
  });

  for (final brightness in Brightness.values) {
    group('Given the Slides home with the built-in templates '
        '(${brightness.name})', () {
      late CommandTestHarness h;
      setUp(() {
        h = slidesHarness();
        h.drive.templates = [
          for (final t in SlidesTemplates.all) _view(t),
          _view(SlidesTemplates.byKey('slides.lesson')!, builtin: false),
        ];
      });
      tearDown(() => h.dispose());

      testWidgets('when the template strip shows then built-in cards render '
          'the first slide of their deck, slide-shaped, and a published '
          'template gets the shell\'s miniature', (tester) async {
        await pumpSlides(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.home(),
          ),
          brightness: brightness,
        );
        await tester.pump();

        final thumbs = tester
            .widgetList<SlideThumbnail>(find.byType(SlideThumbnail))
            .toList();
        // The strip shows six templates: five built-ins render slides.
        expect(thumbs, hasLength(5));
        for (final thumb in thumbs) {
          expect(thumb.slideId, thumb.renderer.model.slides.first.id);
          final size = tester.getSize(find.byWidget(thumb));
          expect(size.width / size.height, closeTo(16 / 9, 0.01));
          expect(
            thumb.renderer.thumbnail(thumb.slideId, width: size.width),
            isNotNull,
          );
        }
        expect(
          find.byKey(
            ValueKey<String>('drive.template.${SlidesTemplates.all.first.key}'),
          ),
          findsOneWidget,
        );
        await settleTooltips(tester);
      });
    });
  }

  // The accessibility checker (03 §17.4) on every template: no errors
  // (missing alt text, low contrast); warnings are allowed (the Magic Move
  // pairs repeat their slide's title on purpose, big numbers and quotes
  // have no title).
  for (final t in SlidesTemplates.all) {
    test('Given template ${t.key} when the accessibility checker runs then '
        'it reports no error', () {
      final report = AccessibilityChecker.check(
        SlidesTemplateDecksForTest.of(t).model,
      );

      expect([
        for (final i in report.issues)
          if (i.severity == A11ySeverity.error) i.toJson(),
      ], isEmpty);
    });
  }

  // Gallery screenshots (12 §4 SL-22): a contact sheet of every template's
  // slides in both appearances, with the real fonts. Set
  // WONKY_TEMPLATE_PNG_DIR to write them.
  final pngDir = Platform.environment['WONKY_TEMPLATE_PNG_DIR'];
  testWidgets('when rendering every template slide then each has a picture '
      '(contact sheets with WONKY_TEMPLATE_PNG_DIR)', (tester) async {
    await tester.runAsync(() => realFonts.ensureAll(realFontFamilies));
    for (final t in SlidesTemplates.all) {
      final renderer = SlideRenderer(
        model: SlidesTemplateDecksForTest.of(t).model,
        fonts: realFonts,
      );
      addTearDown(renderer.dispose);
      for (final appearance in SlideAppearance.values) {
        const w = 480.0, h = 270.0, gap = 16.0, cols = 3;
        final slides = renderer.model.slides;
        final rows = (slides.length + cols - 1) ~/ cols;
        final sheet = ui.PictureRecorder();
        final canvas = Canvas(sheet)
          ..drawColor(const Color(0xff808080), BlendMode.src);
        for (final (i, s) in slides.indexed) {
          final pic = renderer.thumbnail(
            s.id,
            width: w,
            appearance: appearance,
          );
          expect(pic, isNotNull, reason: '${t.key} slide ${i + 1}');
          canvas
            ..save()
            ..translate(
              gap + (i % cols) * (w + gap),
              gap + (i ~/ cols) * (h + gap),
            )
            ..clipRect(const Rect.fromLTWH(0, 0, w, h))
            ..drawPicture(pic!.picture)
            ..restore();
        }
        final picture = sheet.endRecording();
        if (pngDir == null) continue;
        // Contact sheet: every slide of the template, 3 per row.
        await tester.runAsync(() async {
          final image = await picture.toImage(
            (gap + cols * (w + gap)).round(),
            (gap + rows * (h + gap)).round(),
          );
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$pngDir/${t.key}-${appearance.name}.png');
          await file.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
        });
      }
    }
  });
}

/// The families the built-in themes use.
final List<String> realFontFamilies = const [
  'Open Sans',
  'EB Garamond',
  'JetBrains Mono',
  'Roboto',
  'Lato',
  'Source Sans 3',
  'Nunito',
  'Montserrat',
  'Merriweather',
  'Roboto Mono',
];

/// Template decks built with fixed ids (like the gallery previews).
abstract final class SlidesTemplateDecksForTest {
  static final Map<String, SlidesTemplateDeck> _decks = {};

  static SlidesTemplateDeck of(SlidesTemplate t) => _decks[t.key] ??= t.build(
    deckId: '00000000-0000-4000-8000-00000000c0de',
    userId: '00000000-0000-4000-8000-000000000001',
    now: DateTime.utc(2026),
    ids: SequentialIdGenerator(1),
  );
}
