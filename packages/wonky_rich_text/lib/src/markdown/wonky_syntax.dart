/// The Wonky Markdown directives (Write 11 §4) as `package:markdown`
/// syntaxes: the grammar of the Serverpod blog's renderer
/// (`serverpod_website_server/lib/src/markdown/markdown_renderer.dart`),
/// producing AST elements the Write importer maps to Delta attributes.
library;

import 'package:markdown/markdown.dart' as md;

/// The Markdown flavor of a document (Write 11 §1 WM1).
enum MarkdownFlavor {
  /// GitHub-Flavored Markdown (the default).
  gfm('gfm'),

  /// GFM plus the Wonky Markdown directives.
  wonky('wonky');

  const MarkdownFlavor(this.value);

  /// The stored value.
  final String value;

  /// Parses a stored value; unknown values and `null` are [gfm].
  static MarkdownFlavor parse(Object? value) =>
      value == wonky.value ? wonky : gfm;
}

/// AST tags and attribute names of the Wonky directive elements.
abstract final class WonkyMdTags {
  /// `:button[label](url){variant=secondary}` — attributes [href],
  /// [variant]; one text child (the label, HTML-encoded).
  static const button = 'wonky-button';

  /// `:link[label](url)` — attribute [href]; one text child.
  static const arrowLink = 'wonky-link';

  /// `:chip[label]{icon=name}` — attribute [icon]; one text child.
  static const chip = 'wonky-chip';

  /// A container (`:::callout`, `:::details`, `:::card`) — attributes
  /// [type], [variant], [title]; block children. A details element's
  /// summary heading comes first and has the [summary] attribute.
  static const box = 'wonky-box';

  /// `:::grid{columns=n bullets=b}` — attributes [columns], [bullets],
  /// [dropped] (lines that were not items); [gridItem] children.
  static const grid = 'wonky-grid';

  /// One grid item; inline children.
  static const gridItem = 'wonky-grid-item';

  /// Attribute: link destination (raw, not normalized).
  static const href = 'href';

  /// Attribute: button variant (`primary` or `secondary`).
  static const variant = 'variant';

  /// Attribute: chip icon name.
  static const icon = 'icon';

  /// Attribute: container type (`callout`, `details`, `card`).
  static const type = 'type';

  /// Attribute: callout title.
  static const title = 'title';

  /// Attribute on the summary heading of a details container.
  static const summary = 'wonky-summary';

  /// Attribute: grid columns (raw option value).
  static const columns = 'columns';

  /// Attribute: grid bullets (raw option value).
  static const bullets = 'bullets';

  /// Attribute: number of lines a grid dropped (not items).
  static const dropped = 'dropped';

  /// Attribute on a container or grid that ran to the end of its parent
  /// without a closing `:::`.
  static const unterminated = 'unterminated';

  /// Attribute on an `h2`/`h3` element: the step number of a numbered
  /// heading.
  static const step = 'wonky-step';

  /// `::youtube[title]{id=… start=…}` — attributes [videoId], [start],
  /// [title] (raw), [raw] (the whole line, kept when the id is invalid).
  static const youtube = 'wonky-youtube';

  /// Attribute: the YouTube video id (raw `id` option).
  static const videoId = 'videoId';

  /// Attribute: the start time (raw `start` option).
  static const start = 'start';

  /// Attribute: the source line of a leaf directive.
  static const raw = 'raw';
}

/// The callout types of `:::<type>` (Write 11 §2.2).
const wonkyCalloutVariants = [
  'info',
  'tip',
  'note',
  'warning',
  'caution',
  'danger',
];

/// The block syntaxes of the Wonky flavor.
const List<md.BlockSyntax> wonkyBlockSyntaxes = [
  _YouTubeSyntax(),
  _NumberedHeadingSyntax(),
  _CalloutSyntax(),
  _DetailsSyntax(),
  _GridSyntax(),
  _CardSyntax(),
];

/// The inline syntaxes of the Wonky flavor.
final List<md.InlineSyntax> wonkyInlineSyntaxes = [
  _ButtonSyntax(),
  _ArrowLinkSyntax(),
  _ChipSyntax(),
];

/// Parses `{key=value key2=value2}` options (the blog's `_parseOptions`).
Map<String, String> parseWonkyOptions(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const {};
  final options = <String, String>{};
  for (final token in raw.trim().split(RegExp(r'\s+'))) {
    final eq = token.indexOf('=');
    if (eq > 0) options[token.substring(0, eq)] = token.substring(eq + 1);
  }
  return options;
}

/// HTML-encodes a label like `package:markdown` does with `encodeHtml`, so
/// the reader's entity decoding gives it back exactly.
String _encode(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

// ---------------------------------------------------------------------------
// Inline directives.

class _ButtonSyntax extends md.InlineSyntax {
  _ButtonSyntax()
    : super(
        r':button\[([^\]]*)\]\(([^)]*)\)(?:\{([^}]*)\})?',
        startCharacter: 0x3A,
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final variant = parseWonkyOptions(match[3])['variant'] == 'secondary'
        ? 'secondary'
        : 'primary';
    parser.addNode(
      md.Element(WonkyMdTags.button, [md.Text(_encode(match[1]!))])
        ..attributes[WonkyMdTags.href] = match[2]!
        ..attributes[WonkyMdTags.variant] = variant,
    );
    return true;
  }
}

class _ArrowLinkSyntax extends md.InlineSyntax {
  _ArrowLinkSyntax()
    : super(r':link\[([^\]]*)\]\(([^)]*)\)', startCharacter: 0x3A);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(
      md.Element(WonkyMdTags.arrowLink, [md.Text(_encode(match[1]!))])
        ..attributes[WonkyMdTags.href] = match[2]!,
    );
    return true;
  }
}

class _ChipSyntax extends md.InlineSyntax {
  _ChipSyntax()
    : super(r':chip\[([^\]]*)\](?:\{([^}]*)\})?', startCharacter: 0x3A);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final icon = parseWonkyOptions(match[2])['icon'];
    final element = md.Element(WonkyMdTags.chip, [md.Text(_encode(match[1]!))]);
    if (icon != null && icon.isNotEmpty) {
      element.attributes[WonkyMdTags.icon] = icon;
    }
    parser.addNode(element);
    return true;
  }
}

// ---------------------------------------------------------------------------
// Block directives.

/// A `::youtube[title]{id=… start=…}` leaf directive on its own line
/// (Write 11 §4). The title is plain text.
class _YouTubeSyntax extends md.BlockSyntax {
  const _YouTubeSyntax();

  @override
  RegExp get pattern =>
      RegExp(r'^::youtube(?:\[([^\]]*)\])?(?:\s*\{([^}]*)\})?\s*$');

  @override
  md.Node parse(md.BlockParser parser) {
    final line = parser.current.content.trim();
    final match = pattern.firstMatch(parser.current.content)!;
    final options = parseWonkyOptions(match[2]);
    parser.advance();
    final element = md.Element.empty(WonkyMdTags.youtube)
      ..attributes[WonkyMdTags.videoId] = options['id'] ?? ''
      ..attributes[WonkyMdTags.raw] = line;
    final start = options['start'];
    if (start != null) element.attributes[WonkyMdTags.start] = start;
    final title = match[1]?.trim();
    if (title != null && title.isNotEmpty) {
      element.attributes[WonkyMdTags.title] = title;
    }
    return element;
  }
}

/// A `##` or `###` heading with a leading `(n)`.
class _NumberedHeadingSyntax extends md.BlockSyntax {
  const _NumberedHeadingSyntax();

  @override
  RegExp get pattern => RegExp(r'^(#{2,3})\s+\((\d+)\)\s+(.*)$');

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final level = match[1]!.length;
    parser.advance();
    return md.Element('h$level', [md.UnparsedContent(match[3]!.trim())])
      ..attributes[WonkyMdTags.step] = match[2]!;
  }
}

class _CalloutSyntax extends md.BlockSyntax {
  const _CalloutSyntax();

  @override
  RegExp get pattern => RegExp(
    r'^:::(info|tip|note|warning|caution|danger)\b(?:\[([^\]]*)\])?\s*$',
  );

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final title = match[2]?.trim();
    parser.advance();
    final body = _collectLines(parser);
    final element =
        md.Element(
            WonkyMdTags.box,
            md.BlockParser(body.lines, parser.document).parseLines(),
          )
          ..attributes[WonkyMdTags.type] = 'callout'
          ..attributes[WonkyMdTags.variant] = match[1]!.toLowerCase();
    if (title != null && title.isNotEmpty) {
      element.attributes[WonkyMdTags.title] = title;
    }
    if (!body.terminated) element.attributes[WonkyMdTags.unterminated] = '1';
    return element;
  }
}

final _summaryHeading = RegExp(r'^###\s+(.*)$');

/// A `:::details` disclosure: its first own `###` is the summary.
class _DetailsSyntax extends md.BlockSyntax {
  const _DetailsSyntax();

  @override
  RegExp get pattern => RegExp(r'^:::details\s*$');

  @override
  md.Node parse(md.BlockParser parser) {
    parser.advance();
    final body = _collectLines(parser);
    final lines = body.lines;
    final index = _ownLines(lines).firstWhere(
      (i) => _summaryHeading.hasMatch(lines[i].content.trim()),
      orElse: () => -1,
    );
    final children = <md.Node>[];
    var rest = lines;
    if (index != -1) {
      final summary = _summaryHeading
          .firstMatch(lines[index].content.trim())![1]!
          .trim();
      children.add(
        md.Element('h3', [md.UnparsedContent(summary)])
          ..attributes[WonkyMdTags.summary] = '1',
      );
      rest = [...lines.take(index), ...lines.skip(index + 1)];
    }
    children.addAll(md.BlockParser(rest, parser.document).parseLines());
    final element = md.Element(WonkyMdTags.box, children)
      ..attributes[WonkyMdTags.type] = 'details';
    if (!body.terminated) element.attributes[WonkyMdTags.unterminated] = '1';
    return element;
  }
}

final _gridItem = RegExp(r'^[-*]\s+(.*)$');

/// A `:::grid{columns=n bullets=b}` of bullet items.
class _GridSyntax extends md.BlockSyntax {
  const _GridSyntax();

  @override
  RegExp get pattern => RegExp(r'^:::grid(?:\s*\{([^}]*)\})?\s*$');

  @override
  md.Node parse(md.BlockParser parser) {
    final options = parseWonkyOptions(
      pattern.firstMatch(parser.current.content)![1],
    );
    parser.advance();
    final body = _collectLines(parser);
    final lines = body.lines;
    final items = <md.Node>[];
    final own = _ownLines(lines).toSet();
    var dropped = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].isBlankLine) continue;
      final item = own.contains(i)
          ? _gridItem.firstMatch(lines[i].content.trim())
          : null;
      if (item == null) {
        // Not an item, or inside a code fence or a nested directive.
        dropped++;
        continue;
      }
      items.add(
        md.Element(WonkyMdTags.gridItem, [md.UnparsedContent(item[1]!.trim())]),
      );
    }
    final element = md.Element(WonkyMdTags.grid, items)
      ..attributes[WonkyMdTags.columns] = options['columns'] ?? ''
      ..attributes[WonkyMdTags.bullets] = options['bullets'] ?? '';
    if (dropped > 0) element.attributes[WonkyMdTags.dropped] = '$dropped';
    if (!body.terminated) element.attributes[WonkyMdTags.unterminated] = '1';
    return element;
  }
}

/// A `:::card` container.
class _CardSyntax extends md.BlockSyntax {
  const _CardSyntax();

  @override
  RegExp get pattern => RegExp(r'^:::card\s*$');

  @override
  md.Node parse(md.BlockParser parser) {
    parser.advance();
    final body = _collectLines(parser);
    final element = md.Element(
      WonkyMdTags.box,
      md.BlockParser(body.lines, parser.document).parseLines(),
    )..attributes[WonkyMdTags.type] = 'card';
    if (!body.terminated) element.attributes[WonkyMdTags.unterminated] = '1';
    return element;
  }
}

final _directiveOpen = RegExp(r'^:::[a-zA-Z]');

/// Consumes the lines up to the matching closing `:::` (nested directives
/// are tracked, fenced code is skipped).
({List<md.Line> lines, bool terminated}) _collectLines(md.BlockParser parser) {
  final lines = <md.Line>[];
  var depth = 1;
  var inFence = false;
  while (!parser.isDone) {
    final trimmed = parser.current.content.trim();
    if (trimmed.startsWith('```')) inFence = !inFence;
    if (!inFence) {
      if (trimmed == ':::') {
        if (--depth == 0) {
          parser.advance();
          return (lines: lines, terminated: true);
        }
      } else if (_directiveOpen.hasMatch(trimmed)) {
        depth++;
      }
    }
    lines.add(parser.current);
    parser.advance();
  }
  return (lines: lines, terminated: false);
}

/// The indices of the lines a directive owns (not inside a code fence or a
/// nested directive).
Iterable<int> _ownLines(List<md.Line> lines) sync* {
  var depth = 0;
  var inFence = false;
  for (var i = 0; i < lines.length; i++) {
    final content = lines[i].content.trim();
    if (content.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (_directiveOpen.hasMatch(content)) {
      depth++;
    } else if (content == ':::') {
      if (depth > 0) depth--;
    } else if (depth == 0) {
      yield i;
    }
  }
}

final _directiveLine = RegExp(
  // A container line (`:::type`) or a YouTube video (`::youtube`).
  r'^(?::::(?:info|tip|note|warning|caution|danger|details|card|grid)'
  r'|::youtube)\b',
);
final _inlineDirective = RegExp(
  r':(?:button|link)\[[^\]]*\]\([^)]*\)|:chip\[[^\]]*\]',
);

/// Whether [markdown] uses Wonky directives (a directive line or an inline
/// button, link or chip outside code), so a new document imported from it
/// should be Wonky Markdown (Write 11 §5.1).
bool looksLikeWonkyMarkdown(String markdown) {
  var inFence = false;
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('```') || line.startsWith('~~~')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    if (_directiveLine.hasMatch(line)) return true;
    final withoutCode = line.replaceAll(RegExp(r'`[^`]*`'), '');
    if (_inlineDirective.hasMatch(withoutCode)) return true;
  }
  return false;
}
