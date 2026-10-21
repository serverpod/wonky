/// Seeded random generators for documents and edits (WS-W0, specs/15 §8).
library;

import 'dart:math';

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/delta_utils.dart';
import '../delta/document.dart';
import '../delta/embeds.dart';
import '../delta/normalizer.dart';

/// Options for [DeltaGen].
final class DeltaGenOptions {
  /// Creates options.
  const DeltaGenOptions({
    this.maxLines = 12,
    this.maxRunsPerLine = 4,
    this.maxRunLength = 8,
    this.embeds = true,
    this.tables = true,
    this.overlays = false,
    this.softBreaks = true,
    this.mentions = true,
    this.unicode = true,
    this.markdownSpecials = true,
    this.emptyLines = true,
  });

  /// Maximum number of lines.
  final int maxLines;

  /// Maximum inline runs per line.
  final int maxRunsPerLine;

  /// Maximum characters per run.
  final int maxRunLength;

  /// Generate image/divider embeds.
  final bool embeds;

  /// Generate table embeds.
  final bool tables;

  /// Generate `cmt_*`/`sug_*` overlays.
  final bool overlays;

  /// Generate U+2028 soft breaks.
  final bool softBreaks;

  /// Generate mentions.
  final bool mentions;

  /// Generate non-ASCII text (accents, CJK, emoji with surrogate pairs).
  final bool unicode;

  /// Generate Markdown-significant characters in text.
  final bool markdownSpecials;

  /// Generate empty lines.
  final bool emptyLines;
}

/// Generates random, valid (normalized) Wonky documents from a seed.
final class DeltaGen {
  /// Creates a generator with [random] (seed it for reproducibility).
  DeltaGen(this.random, {this.options = const DeltaGenOptions()});

  /// Seeded random source.
  final Random random;

  /// Generation options.
  final DeltaGenOptions options;

  var _ids = 0;

  static const _plain = 'abcdefghijklmnopqrstuvwxyz  ABCXYZ0123456789';
  static const _specials =
      r'\*_`#+-.!()[]<>|~&:@/=;"'
      "'";
  static const _unicode = [
    'é',
    'ß',
    'ø',
    'Ж',
    '中',
    '文',
    'ア',
    '😀',
    '👍🏽',
    '\u00A0',
    'ﬁ',
  ];
  static const _links = [
    'https://example.com',
    'https://example.com/a_b/c?x=1&y=2#frag',
    'http://wonky.test/(paren)',
    'mailto:someone@example.com',
    'wonky://doc/0192f1a2-0000-7000-8000-000000000001#h-intro-1',
    'https://ex.com/%C3%A9t%C3%A9',
  ];
  static const _languages = ['', 'dart', 'js', 'python', 'c++', 'objective-c'];

  /// A fresh deterministic id.
  String nextId() {
    _ids++;
    final r = (random.nextInt(0x10000) * 0x10000 + random.nextInt(0x10000))
        .toRadixString(16)
        .padLeft(8, '0');
    return '0192${_ids.toRadixString(16).padLeft(4, '0')}-$r-7000-8000-000000000000';
  }

  /// Random text of 1..[max] characters.
  String text(int max) {
    final n = 1 + random.nextInt(max);
    final b = StringBuffer();
    for (var i = 0; i < n; i++) {
      final p = random.nextInt(100);
      if (options.markdownSpecials && p < 18) {
        b.write(_specials[random.nextInt(_specials.length)]);
      } else if (options.unicode && p < 26) {
        b.write(_unicode[random.nextInt(_unicode.length)]);
      } else if (options.softBreaks && p < 28) {
        b.write(softBreak);
      } else {
        b.write(_plain[random.nextInt(_plain.length)]);
      }
    }
    return b.toString();
  }

  Map<String, dynamic>? _inlineAttributes() {
    final attrs = <String, dynamic>{};
    if (random.nextInt(4) == 0) {
      attrs[WonkyAttr.code] = true;
    } else {
      if (random.nextInt(4) == 0) attrs[WonkyAttr.bold] = true;
      if (random.nextInt(4) == 0) attrs[WonkyAttr.italic] = true;
      if (random.nextInt(6) == 0) attrs[WonkyAttr.strike] = true;
    }
    if (random.nextInt(6) == 0) {
      if (options.mentions && random.nextInt(3) == 0) {
        attrs[WonkyAttr.mention] = nextId();
        attrs[WonkyAttr.link] = 'mailto:user${random.nextInt(9)}@example.com';
      } else {
        attrs[WonkyAttr.link] = _links[random.nextInt(_links.length)];
      }
    }
    if (options.overlays) {
      if (random.nextInt(5) == 0) {
        attrs[WonkyAttr.commentKey('t${random.nextInt(3)}')] = true;
      }
      if (random.nextInt(6) == 0) {
        attrs[WonkyAttr.suggestionKey(
          's${random.nextInt(3)}',
        )] = SuggestionMark(
          kind: SuggestionKind.values[random.nextInt(2)],
          by: 'u${random.nextInt(2)}',
          at: 1000 + random.nextInt(10),
        ).toJson();
      }
    }
    return attrs.isEmpty ? null : attrs;
  }

  Map<String, dynamic>? _blockAttributes(
    int? prevListIndent, {
    bool prevInQuote = false,
    bool prevListQuoted = false,
  }) {
    final p = random.nextInt(100);
    if (p < 40) return null;
    if (p < 52) return {WonkyAttr.header: 1 + random.nextInt(6)};
    if (p < 60) return {WonkyAttr.blockquote: true};
    if (p < 70) {
      return {
        WonkyAttr.codeBlock: _languages[random.nextInt(_languages.length)],
      };
    }
    final kinds = ListKind.values;
    // Lists inside quotes: mostly right after a quote line or quoted item.
    final quoted = random.nextInt(prevInQuote ? 2 : 8) == 0;
    final maxIndent = prevListIndent == null || prevListQuoted != quoted
        ? 0
        : (prevListIndent + 1).clamp(0, 8);
    final indent = random.nextInt(maxIndent + 1);
    return {
      WonkyAttr.list: kinds[random.nextInt(kinds.length)].value,
      if (indent > 0) WonkyAttr.indent: indent,
      if (quoted) WonkyAttr.blockquote: true,
    };
  }

  /// A random embed.
  WonkyEmbed embed() {
    final p = random.nextInt(options.tables ? 3 : 2);
    switch (p) {
      case 0:
        return ImageEmbed(
          id: nextId(),
          src: random.nextBool()
              ? 'wonky-file://${nextId()}'
              : 'https://img.example.com/p${random.nextInt(9)}.png',
          alt: random.nextBool() ? '' : _singleLine(text(6)),
          title: random.nextInt(3) == 0 ? _singleLine(text(5)) : null,
        );
      case 1:
        return DividerEmbed(id: nextId());
      default:
        final cols = 1 + random.nextInt(3);
        final rows = 1 + random.nextInt(3);
        return TableEmbed(
          id: nextId(),
          align: [
            for (var c = 0; c < cols; c++)
              [null, ...CellAlign.values][random.nextInt(4)],
          ],
          rows: [
            for (var r = 0; r < rows; r++)
              [
                for (var c = 0; c < cols; c++)
                  random.nextInt(4) == 0 ? '' : 'c${r}x$c ${_plainWord()}',
              ],
          ],
        );
    }
  }

  String _plainWord() {
    final n = 1 + random.nextInt(5);
    return String.fromCharCodes([
      for (var i = 0; i < n; i++) 0x61 + random.nextInt(26),
    ]);
  }

  static String _singleLine(String s) =>
      s.replaceAll(softBreak, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  /// A random raw document (may violate the schema in ways the normalizer
  /// fixes, e.g. soft breaks in code). Use [document] for valid output.
  Delta rawDocument() {
    final d = Delta();
    final lines = 1 + random.nextInt(options.maxLines);
    int? prevListIndent;
    var prevInQuote = false;
    var prevListQuoted = false;
    for (var l = 0; l < lines; l++) {
      if (options.embeds && random.nextInt(8) == 0) {
        final e = embed();
        final attrs = options.overlays && random.nextInt(4) == 0
            ? {WonkyAttr.commentKey('t${random.nextInt(3)}'): true}
            : null;
        d.insert(e.toInsert(), attrs);
        d.insert('\n');
        prevListIndent = null;
        prevInQuote = false;
        continue;
      }
      final block = _blockAttributes(
        prevListIndent,
        prevInQuote: prevInQuote,
        prevListQuoted: prevListQuoted,
      );
      final runs = options.emptyLines && random.nextInt(8) == 0
          ? 0
          : 1 + random.nextInt(options.maxRunsPerLine);
      for (var r = 0; r < runs; r++) {
        d.insert(text(options.maxRunLength), _inlineAttributes());
      }
      d.insert('\n', block);
      final f = BlockFormat.fromAttributes(block);
      prevListIndent = f.isList ? f.indent : null;
      prevInQuote = f.inQuote;
      prevListQuoted = f.quoted;
    }
    return d;
  }

  /// A random valid, normalized document.
  Delta document() =>
      const WonkyDeltaNormalizer().normalize(rawDocument()).document;
}

/// Generates random change deltas for a document (for OT/undo fuzzing).
final class EditGen {
  /// Creates a generator.
  EditGen(this.random, {DeltaGen? deltaGen})
    : deltaGen = deltaGen ?? DeltaGen(random);

  /// Seeded random source.
  final Random random;

  /// Generator used for inserted content.
  final DeltaGen deltaGen;

  /// A random change applicable to [document] (1–3 components). The result
  /// is not necessarily schema-valid; normalize the composed document.
  Delta change(Delta document, {bool overlays = false}) {
    final len = DeltaUtils.documentLength(document);
    final doc = WonkyDocument(document);
    final text = doc.text;
    // Never split a surrogate pair (editors don't).
    int fit(int at, int n) {
      var k = n;
      while (k > 0 && DeltaUtils.isInsideSurrogatePair(text, at + k)) {
        k--;
      }
      return k;
    }

    final d = Delta();
    var pos = 0;
    final parts = 1 + random.nextInt(3);
    for (var i = 0; i < parts && pos < len; i++) {
      var skip = random.nextInt(len - pos);
      skip = fit(pos, skip);
      d.retain(skip);
      pos += skip;
      final remaining = len - 1 - pos; // keep the final newline
      switch (random.nextInt(5)) {
        case 0 || 1:
          final t = deltaGen.text(6);
          d.insert(t, random.nextInt(3) == 0 ? {WonkyAttr.bold: true} : null);
        case 2:
          if (remaining > 0) {
            final n = fit(pos, 1 + random.nextInt(remaining.clamp(1, 6)));
            d.delete(n);
            pos += n;
          }
        case 3:
          if (remaining > 0) {
            final n = fit(pos, 1 + random.nextInt(remaining.clamp(1, 8)));
            final key = overlays && random.nextBool()
                ? WonkyAttr.commentKey('c${random.nextInt(3)}')
                : [WonkyAttr.bold, WonkyAttr.italic, WonkyAttr.strike][random
                      .nextInt(3)];
            d.retain(n, {key: random.nextBool() ? true : null});
            pos += n;
          }
        default:
          final line = doc.lineAt(pos.clamp(0, len - 1));
          final to = line.newlineOffset;
          if (to >= pos) {
            d.retain(to - pos);
            pos = to;
            d.retain(1, {
              WonkyAttr.header: random.nextBool()
                  ? 1 + random.nextInt(3)
                  : null,
            });
            pos += 1;
          }
      }
    }
    return DeltaUtils.canonical(d);
  }
}
