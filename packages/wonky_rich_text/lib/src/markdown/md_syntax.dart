/// The `package:markdown` configuration used by the codec.
library;

import 'package:markdown/markdown.dart' as md;

import 'wonky_syntax.dart';

/// GFM block/inline syntaxes without footnotes (kept as literal text, 02 §2.1).
final md.ExtensionSet wonkyGfm = md.ExtensionSet(
  const <md.BlockSyntax>[
    md.FencedCodeBlockSyntax(),
    md.TableSyntax(),
    md.UnorderedListWithCheckboxSyntax(),
    md.OrderedListWithCheckboxSyntax(),
  ],
  <md.InlineSyntax>[
    md.InlineHtmlSyntax(),
    md.StrikethroughSyntax(),
    md.AutolinkExtensionSyntax(),
  ],
);

/// Parses [source] into an AST with HTML encoding on, so literal `<`/`&`
/// arrive as entities and raw inline HTML stays raw. The [MarkdownFlavor.wonky]
/// flavor adds the Wonky directives (Write 11 §4, [WonkyMdTags]); without
/// [blocks] only the inline ones.
List<md.Node> parseMarkdownAst(
  String source, {
  MarkdownFlavor flavor = MarkdownFlavor.gfm,
  bool blocks = true,
}) {
  final wonky = flavor == MarkdownFlavor.wonky;
  final doc = md.Document(
    extensionSet: wonkyGfm,
    encodeHtml: true,
    blockSyntaxes: wonky && blocks ? wonkyBlockSyntaxes : const [],
    inlineSyntaxes: wonky ? wonkyInlineSyntaxes : const [],
  );
  return doc.parseLines(source.split('\n'));
}

/// Decodes the HTML escapes produced by `package:markdown` with
/// `encodeHtml: true` (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`) plus
/// numeric references.
String decodeMdEntities(String s) {
  if (!s.contains('&')) return s;
  return s.replaceAllMapped(
    RegExp(
      r'&(?:(amp|lt|gt|quot|apos|nbsp)|#(\d{1,7})|#[xX]([0-9A-Fa-f]{1,6}));',
    ),
    (m) {
      final named = m.group(1);
      if (named != null) {
        return const {
          'amp': '&',
          'lt': '<',
          'gt': '>',
          'quot': '"',
          'apos': "'",
          'nbsp': '\u00A0',
        }[named]!;
      }
      final dec = m.group(2);
      final code = dec != null
          ? int.parse(dec)
          : int.parse(m.group(3)!, radix: 16);
      if (code == 0 || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF)) {
        return '\uFFFD';
      }
      return String.fromCharCode(code);
    },
  );
}
