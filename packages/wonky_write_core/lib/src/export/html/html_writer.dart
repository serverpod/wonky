/// IR → HTML/XHTML body markup shared by the HTML and EPUB exporters
/// (07 §5.3, §5.8).
library;

import '../../delta/delta_utils.dart';
import '../../highlight/syntax_highlighter.dart';
import '../../ir/doc_tree.dart';
import '../../markdown/inline_reader.dart' show mentionTitlePrefix;
import '../export_api.dart';

/// Options of [HtmlBodyWriter].
final class HtmlBodyOptions {
  /// Creates options.
  const HtmlBodyOptions({
    this.xhtml = false,
    this.imageSource,
    this.links = const IdentityLinkResolver(),
    this.includeToc = false,
    this.tocDepth = 3,
    this.anchorHref,
  });

  /// XHTML syntax (EPUB): self-closed void elements, boolean attributes with
  /// values.
  final bool xhtml;

  /// Image `src` rewriting (data URIs, zip-relative paths); `null` keeps the
  /// stored source; returning `null` renders a placeholder.
  final String? Function(ImageBlock image)? imageSource;

  /// Link rewriting.
  final LinkResolver links;

  /// Emit `<nav class="wonky-toc">`.
  final bool includeToc;

  /// TOC depth.
  final int tocDepth;

  /// Href for an anchor id (EPUB: `chapter-003.xhtml#id`); default `#id`.
  final String Function(String anchorId)? anchorHref;
}

/// Writes HTML for IR blocks.
final class HtmlBodyWriter {
  /// Creates a writer.
  const HtmlBodyWriter({this.options = const HtmlBodyOptions()});

  /// Options.
  final HtmlBodyOptions options;

  /// Escapes text content.
  static String escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// Escapes attribute values.
  static String attr(String s) => escape(s).replaceAll('"', '&quot;');

  String get _br => options.xhtml ? '<br/>' : '<br>';

  /// `<article class="wonky-doc">…</article>` for [tree] (all blocks).
  String article(DocTree tree) {
    final b = StringBuffer('<article class="wonky-doc">\n');
    if (options.includeToc) b.write(toc(tree.headings.toList()));
    b.write(blocks(tree.blocks));
    b.write('</article>');
    return b.toString();
  }

  /// A `<nav class="wonky-toc">` for [headings].
  String toc(List<HeadingBlock> headings) {
    final items = headings.where((h) => h.level <= options.tocDepth).toList();
    if (items.isEmpty) return '';
    final b = StringBuffer('<nav class="wonky-toc"><ol>');
    var level = items.first.level;
    var open = 0;
    for (var i = 0; i < items.length; i++) {
      final h = items[i];
      if (i > 0) {
        if (h.level > level) {
          for (var l = level; l < h.level; l++) {
            b.write('<ol>');
            open++;
          }
        } else {
          b.write('</li>');
          for (var l = h.level; l < level && open > 0; l++) {
            b.write('</ol></li>');
            open--;
          }
        }
      }
      level = h.level;
      final href = options.anchorHref?.call(h.anchorId) ?? '#${h.anchorId}';
      b.write(
        '<li><a href="${attr(href)}">${escape(InlineRun.plainText(h.runs).replaceAll(softBreak, ' '))}</a>',
      );
    }
    b.write('</li>');
    for (; open > 0; open--) {
      b.write('</ol></li>');
    }
    b.write('</ol></nav>\n');
    return b.toString();
  }

  /// HTML for a sequence of blocks (lists are nested from indents; quote
  /// lines and the quoted list items next to them share one `<blockquote>`).
  String blocks(List<DocBlock> blocks) => _blocks(blocks, quoteBody: false);

  String _blocks(List<DocBlock> blocks, {required bool quoteBody}) {
    final b = StringBuffer();
    // Open list stack: (tag, kind key).
    final stack = <(String tag, String key)>[];
    void closeTo(int depth) {
      while (stack.length > depth) {
        b.write('</li></${stack.removeLast().$1}>\n');
      }
    }

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (!quoteBody && isInQuote(block)) {
        closeTo(0);
        var end = i;
        while (end < blocks.length && isInQuote(blocks[end])) {
          end++;
        }
        b
          ..write('<blockquote>')
          ..write(_blocks(blocks.sublist(i, end), quoteBody: true))
          ..write('</blockquote>\n');
        i = end - 1;
        continue;
      }
      if (quoteBody && block is QuoteBlock) {
        closeTo(0);
        b.write(_quoteLines(block.lines));
        continue;
      }
      if (block is ListItemBlock || block is TaskBlock) {
        final (indent, tag, key, item) = switch (block) {
          ListItemBlock(:final indent, :final kind, :final runs) => (
            indent,
            kind == ListKindIr.ordered ? 'ol' : 'ul',
            kind.name,
            '<li>${inline(runs)}',
          ),
          TaskBlock(:final indent, :final checked, :final runs) => (
            indent,
            'ul',
            'task',
            '<li class="wonky-task${checked ? ' wonky-task-checked' : ''}">'
                '<input type="checkbox"${options.xhtml ? ' disabled="disabled"' : ' disabled'}'
                '${checked ? (options.xhtml ? ' checked="checked"' : ' checked') : ''}${options.xhtml ? '/>' : '>'} '
                '${inline(runs)}',
          ),
          _ => throw StateError('unreachable'),
        };
        final depth = indent + 1;
        if (stack.length > depth) closeTo(depth);
        if (stack.length == depth) {
          if (stack.last.$2 != key) {
            closeTo(depth - 1);
          } else {
            b.write('</li>\n');
          }
        }
        while (stack.length < depth) {
          final level = stack.length + 1;
          final open = level == depth ? (tag, key) : ('ul', 'bullet');
          b.write(
            '<${open.$1}${open.$2 == 'task' ? ' class="wonky-tasks"' : ''}>\n',
          );
          if (level < depth) b.write('<li class="wonky-list-gap">');
          stack.add(open);
        }
        b.write(item);
        continue;
      }
      closeTo(0);
      b.write(this.block(block));
      b.write('\n');
    }
    closeTo(0);
    return b.toString();
  }

  /// The `<p>`s of quote lines (inside a `<blockquote>`).
  String _quoteLines(List<List<InlineRun>> lines) => lines
      .map((l) => l.isEmpty ? '<p>$_br</p>' : '<p>${inline(l)}</p>')
      .join();

  /// HTML of one non-list block.
  String block(DocBlock block) {
    switch (block) {
      case ParagraphBlock(:final runs):
        return runs.isEmpty ? '<p>$_br</p>' : '<p>${inline(runs)}</p>';
      case HeadingBlock(:final level, :final runs, :final anchorId):
        return '<h$level id="${attr(anchorId)}">${runs.isEmpty ? _br : inline(runs)}</h$level>';
      case QuoteBlock(:final lines):
        return '<blockquote>${_quoteLines(lines)}</blockquote>';
      case CodeBlock(:final language, :final text):
        final cls = language.isEmpty
            ? ''
            : ' class="language-${attr(language)}"';
        final label = language.isEmpty
            ? ''
            : ' data-language="${attr(language)}"';
        return '<pre class="wonky-code"$label><code$cls>${highlighted(text, language)}\n</code></pre>';
      case ImageBlock():
        final src = options.imageSource == null
            ? block.src
            : options.imageSource!(block);
        if (src == null) {
          return '<p class="wonky-image-missing">[Image: ${escape(block.alt)}]</p>';
        }
        final title = block.title;
        final close = options.xhtml ? '/>' : '>';
        return '<figure class="wonky-image"><img src="${attr(src)}" alt="${attr(block.alt)}"'
            '${title == null ? '' : ' title="${attr(title)}"'}$close'
            '${title == null ? '' : '<figcaption>${escape(title)}</figcaption>'}</figure>';
      case RuleBlock():
        return options.xhtml ? '<hr/>' : '<hr>';
      case TableBlock(:final rows, :final align):
        final b = StringBuffer('<table class="wonky-table">');
        String cellTag(String tag, int c, List<InlineRun> runs) {
          final a = c < align.length ? align[c] : null;
          final style = a == null ? '' : ' style="text-align: ${a.value}"';
          return '<$tag$style>${inline(runs)}</$tag>';
        }

        b.write('<thead><tr>');
        for (var c = 0; c < rows.first.length; c++) {
          b.write(cellTag('th', c, rows.first[c]));
        }
        b.write('</tr></thead>');
        if (rows.length > 1) {
          b.write('<tbody>');
          for (final r in rows.skip(1)) {
            b.write('<tr>');
            for (var c = 0; c < r.length; c++) {
              b.write(cellTag('td', c, r[c]));
            }
            b.write('</tr>');
          }
          b.write('</tbody>');
        }
        b.write('</table>');
        return b.toString();
      case ListItemBlock() || TaskBlock():
        return blocks([block]);
    }
  }

  /// Code text with `<span class="tok-…">` syntax tokens.
  String highlighted(String text, String language) {
    final spans = SyntaxHighlighter.instance.tokenize(text, language);
    if (spans.isEmpty) return escape(text);
    final b = StringBuffer();
    var pos = 0;
    for (final s in spans) {
      if (s.start > pos) b.write(escape(text.substring(pos, s.start)));
      b.write(
        '<span class="tok-${s.token.name}">${escape(text.substring(s.start, s.end))}</span>',
      );
      pos = s.end;
    }
    if (pos < text.length) b.write(escape(text.substring(pos)));
    return b.toString();
  }

  /// Inline HTML for [runs].
  String inline(List<InlineRun> runs) {
    final b = StringBuffer();
    var i = 0;
    while (i < runs.length) {
      final r = runs[i];
      if (r.link != null) {
        var j = i;
        while (j < runs.length &&
            runs[j].link == r.link &&
            runs[j].mentionUserUuid == r.mentionUserUuid) {
          j++;
        }
        final inner = runs.sublist(i, j).map(_run).join();
        if (r.mentionUserUuid != null) {
          b.write(
            '<a class="wonky-mention" href="${attr(r.link!)}" title="${attr('$mentionTitlePrefix${r.mentionUserUuid}')}">'
            '$inner</a>',
          );
        } else {
          b.write(
            '<a href="${attr(options.links.resolve(r.link!))}" rel="noopener noreferrer">$inner</a>',
          );
        }
        i = j;
        continue;
      }
      b.write(_run(r));
      i++;
    }
    // A trailing line break is invisible in HTML; double it (importers and
    // browsers drop one).
    final all = InlineRun.plainText(runs);
    final lastBreak = all.lastIndexOf(softBreak);
    if (lastBreak >= 0 && all.substring(lastBreak + 1).trim().isEmpty) {
      b.write(_br);
    }
    return b.toString();
  }

  String _run(InlineRun r) {
    var s = escape(r.text).replaceAll(softBreak, _br);
    if (r.code) s = '<code>$s</code>';
    if (r.strike) s = '<del>$s</del>';
    if (r.italic) s = '<em>$s</em>';
    if (r.bold) s = '<strong>$s</strong>';
    return s;
  }
}
