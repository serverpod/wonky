/// Seeded random generators for documents and edits (WS-W0, specs/15 §8).
library;

import 'dart:math';

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/boxes.dart';
import '../delta/cells.dart';
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
    this.wonky = false,
  });

  /// Maximum number of lines.
  final int maxLines;

  /// Maximum inline runs per line.
  final int maxRunsPerLine;

  /// Maximum characters per run.
  final int maxRunLength;

  /// Generate image/divider embeds.
  final bool embeds;

  /// Generate tables (and grids in Wonky documents) as cell lines.
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

  /// Generate Wonky Markdown elements (Write 11 §2): containers (nested),
  /// grids, numbered headings, styled links and chips, within the limits
  /// of the round-trip guarantee (§5.4): labels without `]`, line breaks or
  /// edge whitespace, styled link URLs without parentheses, details that
  /// start with their summary, no code line starting with a fence.
  final bool wonky;
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
  static const _styledLinks = [
    'https://example.com',
    'https://example.com/a_b/c?x=1&y=2#frag',
    'mailto:someone@example.com',
    'wonky://doc/0192f1a2-0000-7000-8000-000000000001#h-intro-1',
  ];

  /// A chip or styled link label: plain text without `]`, line breaks or
  /// edge whitespace.
  String _label() {
    final t = text(options.maxRunLength)
        .replaceAll(']', ')')
        .replaceAll(softBreak, ' ')
        .replaceAll('\u00A0', ' ')
        .trim();
    return t.isEmpty ? 'x' : t;
  }

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
    if (options.wonky && random.nextInt(8) == 0) {
      // A styled run; its text comes from [_label].
      if (random.nextBool()) {
        attrs[WonkyAttr.chip] = random.nextInt(3) == 0 ? 'google' : true;
      } else {
        attrs[WonkyAttr.link] =
            _styledLinks[random.nextInt(_styledLinks.length)];
        attrs[WonkyAttr.linkStyle] = WonkyAttr.linkStyles.elementAt(
          random.nextInt(WonkyAttr.linkStyles.length),
        );
      }
      return attrs;
    }
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

  /// A random embed (image, divider; YouTube videos in Wonky documents).
  WonkyEmbed embed() {
    switch (random.nextInt(options.wonky ? 3 : 2)) {
      case 2:
        const ids = ['AGAQ_N56wCs', 'dQw4w9WgXcQ', 'o3kP3dT2C5k'];
        return YouTubeEmbed(
          id: nextId(),
          videoId: ids[random.nextInt(ids.length)],
          start: random.nextBool() ? null : random.nextInt(4000),
          title: random.nextBool()
              ? null
              : YouTubeEmbed.canonicalTitle(_singleLine(text(5))),
        );
      case 0:
        return ImageEmbed(
          id: nextId(),
          src: random.nextBool()
              ? 'wonky-file://${nextId()}'
              : 'https://img.example.com/p${random.nextInt(9)}.png',
          alt: random.nextBool() ? '' : _singleLine(text(6)),
          title: random.nextInt(3) == 0 ? _singleLine(text(5)) : null,
        );
      default:
        return DividerEmbed(id: nextId());
    }
  }

  /// The lines of a random table (sometimes ragged) or, in Wonky
  /// documents, grid (Write 12 §1.1–1.2), with [box] on every line.
  Delta cells({Object? box}) {
    if (options.wonky && random.nextInt(3) == 0) {
      return CellLines.grid(
        id: nextId(),
        items: [
          for (var i = 0, n = 1 + random.nextInt(4); i < n; i++) _cellContent(),
        ],
        columns: 1 + random.nextInt(4),
        bullets: GridBullets.values[random.nextInt(GridBullets.values.length)],
        box: box,
      );
    }
    final cols = 1 + random.nextInt(3);
    final ragged = random.nextInt(6) == 0;
    final d = CellLines.table(
      id: nextId(),
      rows: [
        for (var r = 0, n = 1 + random.nextInt(3); r < n; r++)
          [
            for (
              var c = 0, m = ragged ? 1 + random.nextInt(cols) : cols;
              c < m;
              c++
            )
              _cellContent(),
          ],
      ],
      align: [
        for (var c = 0; c < cols; c++)
          [null, ...CellAlign.values][random.nextInt(4)],
      ],
      box: box,
      rowId: () => CellIds.row(random),
    );
    if (!ragged) return d;
    // Drops the padding of short rows: a ragged table as an old or remote
    // edit can leave it.
    final out = Delta();
    for (final line in WonkyDocument(d).lines) {
      if (line.isEmpty && random.nextBool()) continue;
      for (final s in line.segments) {
        out.insert(s.data, s.attributes);
      }
      out.insert('\n', line.attributes);
    }
    return out;
  }

  /// A random legacy table embed (for the upgrade, Write 12 §1.5).
  TableEmbed legacyTable() {
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
              switch (random.nextInt(5)) {
                0 => '',
                1 => '**c${r}x$c** ${_plainWord()}',
                2 => ':chip[${_plainWord()}]',
                _ => 'c${r}x$c ${_plainWord()}',
              },
          ],
      ],
    );
  }

  /// A random legacy grid embed (for the upgrade, Write 12 §1.5).
  GridEmbed legacyGrid() => GridEmbed(
    id: nextId(),
    columns: 1 + random.nextInt(4),
    bullets: GridBullets.values[random.nextInt(GridBullets.values.length)],
    items: [
      for (var i = 0, n = 1 + random.nextInt(4); i < n; i++)
        switch (random.nextInt(5)) {
          0 => '',
          1 => ':chip[${_plainWord()}]',
          2 => '**${_plainWord()}** ${_plainWord()}',
          _ => 'item ${_plainWord()}',
        },
    ],
  );

  /// The inline content of a random cell or grid item (may be empty).
  Delta _cellContent() {
    final d = Delta();
    if (random.nextInt(5) == 0) return d;
    for (var r = 0, n = 1 + random.nextInt(2); r < n; r++) {
      final attrs = _inlineAttributes();
      final styled =
          attrs != null &&
          (attrs.containsKey(WonkyAttr.chip) ||
              attrs.containsKey(WonkyAttr.linkStyle));
      d.insert(styled ? _label() : _singleLine(text(4)), attrs);
    }
    return d;
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
    var boxes = <BoxFrame>[];
    for (var l = 0; l < lines; l++) {
      // Containers: pop some, maybe push one (Write 11 §2.2).
      var opensDetails = false;
      if (options.wonky) {
        final previous = boxes;
        if (boxes.isNotEmpty && random.nextInt(4) == 0) {
          boxes = boxes.sublist(0, random.nextInt(boxes.length));
        }
        if (boxes.length < BoxFrame.maxDepth && random.nextInt(5) == 0) {
          final frame = _frame();
          opensDetails = frame.type == BoxType.details;
          boxes = [...boxes, frame];
        }
        if (!Boxes.samePath(previous, boxes)) {
          prevListIndent = null;
          prevInQuote = false;
        }
      }
      Map<String, dynamic>? withBox(Map<String, dynamic>? attrs) =>
          boxes.isEmpty
          ? attrs
          : {...?attrs, WonkyAttr.box: Boxes.toValue(boxes)};
      if (!opensDetails &&
          options.embeds &&
          options.tables &&
          random.nextInt(12) == 0) {
        for (final op in cells(
          box: boxes.isEmpty ? null : Boxes.toValue(boxes),
        ).toList()) {
          d.push(op);
        }
        prevListIndent = null;
        prevInQuote = false;
        continue;
      }
      if (!opensDetails && options.embeds && random.nextInt(8) == 0) {
        final e = embed();
        final attrs = options.overlays && random.nextInt(4) == 0
            ? {WonkyAttr.commentKey('t${random.nextInt(3)}'): true}
            : null;
        d.insert(e.toInsert(), attrs);
        d.insert('\n', withBox(null));
        prevListIndent = null;
        prevInQuote = false;
        continue;
      }
      var block = opensDetails
          ? {WonkyAttr.header: 3}
          : _blockAttributes(
              prevListIndent,
              prevInQuote: prevInQuote,
              prevListQuoted: prevListQuoted,
            );
      final level = block?[WonkyAttr.header];
      // A details summary is never numbered (the blog reads `(n)` in it as
      // text).
      if (options.wonky &&
          !opensDetails &&
          (level == 2 || level == 3) &&
          random.nextInt(3) == 0) {
        block = {...block!, WonkyAttr.step: random.nextInt(20)};
      }
      final isCode = block?.containsKey(WonkyAttr.codeBlock) ?? false;
      final runs = options.emptyLines && random.nextInt(8) == 0
          ? 0
          : 1 + random.nextInt(options.maxRunsPerLine);
      for (var r = 0; r < runs; r++) {
        final attrs = _inlineAttributes();
        final styled =
            attrs != null &&
            (attrs.containsKey(WonkyAttr.chip) ||
                attrs.containsKey(WonkyAttr.linkStyle));
        var t = styled ? _label() : text(options.maxRunLength);
        if (options.wonky && attrs?[WonkyAttr.code] == true) {
          // An inline code span opening a line with three backticks reads
          // as a fence to the blog's directive parser (a known limit).
          t = t.replaceAll('`', "'");
        }
        if (options.wonky && isCode && r == 0) {
          // A code line starting with a fence ends the blog's fence
          // tracking (a known limit of the syntax).
          t = t.replaceAll('`', "'");
        }
        d.insert(t, attrs);
      }
      d.insert('\n', withBox(block));
      final f = BlockFormat.fromAttributes(block);
      prevListIndent = f.isList ? f.indent : null;
      prevInQuote = f.inQuote;
      prevListQuoted = f.quoted;
    }
    return d;
  }

  /// A random container frame.
  BoxFrame _frame() {
    final type = BoxType.values[random.nextInt(BoxType.values.length)];
    if (type != BoxType.callout) return BoxFrame(id: nextId(), type: type);
    return BoxFrame.callout(
      id: nextId(),
      variant:
          CalloutVariant.values[random.nextInt(CalloutVariant.values.length)],
      title: random.nextBool() ? null : BoxFrame.canonicalTitle(_label()),
    );
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
