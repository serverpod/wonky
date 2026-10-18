import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/formatting/rich_text_paint.dart';
import 'package:wonky_sheets/features/grid/paint/text_layout_cache.dart';
import 'package:wonky_sheets_core/model.dart';

/// S-09 (CQ-41): the rich-text layout cache keys on the theme its run
/// colors were resolved with.
void main() {
  group('Given a rich text with a theme-colored run', () {
    final rich = RichText('Hello world', [
      RichRun(0, 5, {RichRunKeys.textColor: 'theme:accent1'}),
    ]);
    const base = GridTextStyle(
      fontFamily: 'Inter',
      fontSize: 13,
      color: Color(0xFF000000),
    );
    final first = SpreadsheetTheme.presets[0];
    final second = SpreadsheetTheme.presets[1];

    test('when it is laid out with another theme then a new paragraph is '
        'built', () {
      final cache = RichTextLayoutCache();

      final a = cache.layout(
        rich,
        base,
        pxPerPoint: 4 / 3,
        linkColor: const Color(0xFF0000FF),
        resolveColor: first.resolveColor,
        theme: first,
      );
      final b = cache.layout(
        rich,
        base,
        pxPerPoint: 4 / 3,
        linkColor: const Color(0xFF0000FF),
        resolveColor: second.resolveColor,
        theme: second,
      );

      expect(identical(a, b), isFalse);
    });

    test('when it is laid out again with the same theme then the paragraph '
        'is reused', () {
      final cache = RichTextLayoutCache();

      final a = cache.layout(
        rich,
        base,
        pxPerPoint: 4 / 3,
        linkColor: const Color(0xFF0000FF),
        resolveColor: first.resolveColor,
        theme: first,
      );
      final b = cache.layout(
        rich,
        base,
        pxPerPoint: 4 / 3,
        linkColor: const Color(0xFF0000FF),
        resolveColor: first.resolveColor,
        theme: SpreadsheetTheme.parse(first.toJson()),
      );

      expect(identical(a, b), isTrue);
    });
  });
}
