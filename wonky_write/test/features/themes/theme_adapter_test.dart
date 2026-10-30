import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/themes/document_theme.dart';
import 'package:wonky_write/features/themes/theme_adapter.dart';
import 'package:wonky_write/features/themes/write_fonts.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Given the built-in themes', () {
    for (final b in BuiltinThemes.all) {
      for (final v in ThemeVariant.values) {
        test('when adapting ${b.key} (${v.name}) then sizes are in px and '
            'colors match the resolved theme', () {
          final resolved = ThemeResolver.instance.resolve(b.theme, v);

          final t = const EditorThemeAdapter().adapt(resolved);

          expect(
            t.body.fontSize,
            closeTo(resolved.body.style.fontSize * pxPerPt, 0.001),
          );
          expect(t.paperColor, Color(resolved.page.paperColor));
          expect(t.headings, hasLength(6));
          expect(t.bullets, hasLength(9));
          expect(
            t.brightness,
            v == ThemeVariant.dark ? Brightness.dark : Brightness.light,
          );
        });
      }
    }
  });

  group('Given font families', () {
    test('when a bundled family is used then it renders with its own face', () {
      expect(WriteFonts.screenFamilyFor('EB Garamond'), 'EB Garamond');
      expect(WriteFonts.exportFamilyFor('Open Sans'), 'Open Sans');
    });

    test('when an unbundled serif is used then EB Garamond substitutes', () {
      expect(WriteFonts.screenFamilyFor('Source Serif 4'), 'EB Garamond');
      expect(WriteFonts.exportFamilyFor('Lora'), 'EB Garamond');
    });

    test('when Inter is used then the shad-bundled face renders on screen', () {
      expect(WriteFonts.screenFamilyFor('Inter'), WriteFonts.inter);
      expect(WriteFonts.exportFamilyFor('Inter'), 'Open Sans');
    });

    test('when a mono family is used then JetBrains Mono substitutes', () {
      expect(WriteFonts.exportFamilyFor('IBM Plex Mono'), 'JetBrains Mono');
    });
  });

  group('Given the theme catalog', () {
    test('when looking up a built-in by key or uuid then it is found', () {
      final catalog = WriteThemeCatalog();
      final b = BuiltinThemes.byKey('classic-serif')!;

      expect(catalog.lookup('classic-serif')?.uuid, b.uuid);
      expect(catalog.lookup(b.uuid)?.name, b.name);
    });

    test('when the document references an unknown theme then Wonky Default '
        'is used and the theme is reported missing', () async {
      final catalog = WriteThemeCatalog(
        fetch: (_, {viaDocumentUuid}) async => null,
      );
      final c = DocumentThemeController(catalog);

      c.themeUuid = '00000000-0000-7000-8000-00000000ffff';
      await pumpEventQueue();

      expect(c.option.builtinKey, BuiltinThemes.defaultKey);
      expect(c.missing, isTrue);
      c.dispose();
    });
  });

  group('Given a document using a custom theme', () {
    ThemeOption option(String uuid, int version, String accent) => ThemeOption(
      uuid: uuid,
      name: 'Report',
      version: version,
      data: WriteThemeData.fromJson({
        ...BuiltinThemes.wonkyDefault.json,
        'name': 'Report',
        'palette': {
          ...(BuiltinThemes.wonkyDefault.json['palette'] as Map),
          'accent': accent,
        },
      }),
    );

    const uuid = '00000000-0000-7000-8000-00000000abcd';

    test(
      'when the theme is saved then the document shows the new version',
      () async {
        var server = option(uuid, 1, '#112233');
        String? via;
        final catalog = WriteThemeCatalog(
          fetch: (u, {viaDocumentUuid}) async {
            via = viaDocumentUuid;
            return server;
          },
        );
        final c = DocumentThemeController(catalog)..documentUuid = 'doc-1';
        c.themeUuid = uuid;
        await pumpEventQueue();
        expect(c.option.version, 1);
        expect(via, 'doc-1');

        server = option(uuid, 2, '#445566');
        await catalog.refresh(uuid, version: 2);

        expect(c.option.version, 2);
        expect(
          c.resolved(ThemeVariant.light).palette[PaletteKey.accent],
          0xff445566,
        );
        c.dispose();
      },
    );

    test(
      'when a refresh names an older version then nothing is fetched',
      () async {
        var fetches = 0;
        final catalog = WriteThemeCatalog(
          fetch: (u, {viaDocumentUuid}) async {
            fetches++;
            return option(uuid, 3, '#000000');
          },
        );
        await catalog.load(uuid);

        await catalog.refresh(uuid, version: 2);

        expect(fetches, 1);
      },
    );

    test(
      'when a theme is put into the catalog then it is listed in my themes',
      () {
        final catalog = WriteThemeCatalog();

        catalog.put(option(uuid, 1, '#112233'));
        expect(catalog.mine.map((t) => t.uuid), [uuid]);
        catalog.markDeleted(uuid);

        expect(catalog.mine, isEmpty);
        expect(catalog.lookup(uuid)?.deleted, isTrue);
      },
    );
  });
}
