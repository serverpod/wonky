/// Markdown → Delta (02 §2.1, 07 §3.3).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:markdown/markdown.dart' as md;

import '../delta/delta_utils.dart';
import '../delta/embeds.dart';
import '../delta/links.dart';
import '../import/import_api.dart';
import '../ir/doc_tree.dart';
import '../ir/doc_tree_builder.dart';
import 'front_matter.dart';
import 'inline_reader.dart';
import 'inline_writer.dart';
import 'md_syntax.dart';

/// Resolves an image source that is not an absolute URL (relative path,
/// `data:` URI). Returns the imported image, or `null` when unavailable.
typedef RelativeImageResolver = ImportedImage? Function(String src);

/// Parses Markdown into the IR and the Wonky Delta.
final class MarkdownImporter {
  /// Creates an importer.
  MarkdownImporter(this.options, {this.resolveImage});

  /// Import options (id generation, file name for the title fallback).
  final ImportOptions options;

  /// Resolver for relative/data image sources (zip imports).
  final RelativeImageResolver? resolveImage;

  final _warnings = <ImportWarning>[];
  final _images = <ImportedImage>[];
  final _blocks = <DocBlock>[];
  late final _reader = InlineReader(_warnings);
  var _warnedQuote = false;
  var _warnedStart = false;
  var _warnedFlatten = false;
  var _imageCounter = 0;

  /// Imports [markdown].
  ImportResult import(String markdown) {
    final source = normalizeLineEndings(markdown);
    final split = FrontMatter.split(source);
    final tree = parseTree(split.body);
    final delta = const DocTreeToDelta().convert(tree);
    final title =
        FrontMatter.title(split.frontMatter) ??
        tree.titleHeading?.runs
            .map((r) => r.text)
            .join()
            .replaceAll(softBreak, ' ')
            .trim() ??
        _fileTitle(options.fileName);
    return ImportResult(
      delta: delta,
      warnings: List.unmodifiable(_dedupe(_warnings)),
      title: (title == null || title.isEmpty) ? null : title,
      frontMatter: split.frontMatter,
      language:
          FrontMatter.field(split.frontMatter, 'lang') ??
          FrontMatter.field(split.frontMatter, 'language'),
      images: List.unmodifiable(_images),
    );
  }

  /// Parses [body] (no front matter) into the IR.
  DocTree parseTree(String body) {
    _blocks.clear();
    for (final node in parseMarkdownAst(_protectFootnotes(body))) {
      _topBlock(node);
    }
    return DocTree(List.of(_blocks));
  }

  /// Footnotes are kept as literal text (02 §2.1): `[^…]` would otherwise be
  /// read as reference links/definitions. Escapes `[^` outside code.
  static String _protectFootnotes(String body) {
    if (!body.contains('[^')) return body;
    final out = StringBuffer();
    String? fence;
    for (final line in body.split('\n')) {
      final m = RegExp(r'^ {0,3}(`{3,}|~{3,})').firstMatch(line);
      if (fence == null && m != null) {
        fence = m.group(1);
      } else if (fence != null &&
          m != null &&
          m.group(1)!.startsWith(fence[0]) &&
          m.group(1)!.length >= fence.length) {
        fence = null;
      } else if (fence == null && !line.startsWith('    ')) {
        // Outside code spans.
        final parts = line.split('`');
        for (var i = 0; i < parts.length; i += 2) {
          parts[i] = parts[i].replaceAllMapped(
            RegExp(r'(?<!\\)\[\^'),
            (_) => r'\[^',
          );
        }
        out.writeln(parts.join('`'));
        continue;
      }
      out.writeln(line);
    }
    final s = out.toString();
    return body.endsWith('\n') ? s : s.substring(0, s.length - 1);
  }

  /// Warnings collected so far.
  List<ImportWarning> get warnings => _warnings;

  static String? _fileTitle(String? fileName) {
    if (fileName == null) return null;
    final base = fileName.split(RegExp(r'[/\\]')).last;
    final dot = base.lastIndexOf('.');
    return dot > 0 ? base.substring(0, dot) : base;
  }

  /// CRLF/CR → LF, BOM stripped.
  static String normalizeLineEndings(String s) {
    var t = s.startsWith('\uFEFF') ? s.substring(1) : s;
    t = t.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return t;
  }

  static List<ImportWarning> _dedupe(List<ImportWarning> ws) {
    final seen = <String>{};
    return [
      for (final w in ws)
        if (seen.add('${w.kind}|${w.message}')) w,
    ];
  }

  void _warn(ImportWarningKind kind, String message) =>
      _warnings.add(ImportWarning(kind, message, blockIndex: _blocks.length));

  // ---------------------------------------------------------------------
  // Blocks

  void _topBlock(md.Node node) {
    if (node is md.Text) {
      _htmlBlock(node.text, (runs) => _blocks.add(ParagraphBlock(runs)));
      return;
    }
    if (node is! md.Element) return;
    switch (node.tag) {
      case 'p':
        _inlineBlock(node.children ?? const [], (runs) => ParagraphBlock(runs));
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        final level = int.parse(node.tag.substring(1));
        _inlineBlock(
          node.children ?? const [],
          (runs) => HeadingBlock(level, runs),
        );
      case 'blockquote':
        _quote(node, depth: 0);
      case 'ul' || 'ol':
        _list(node, 0);
      case 'pre':
        _code(node);
      case 'hr':
        _blocks.add(RuleBlock(options.idGenerator()));
      case 'table':
        _table(node);
      default:
        // Unknown container: import its children.
        for (final c in node.children ?? const <md.Node>[]) {
          _topBlock(c);
        }
    }
  }

  /// Applies the empty-line rule: content consisting only of `m` plain soft
  /// breaks (written as `m` `<br>` tags) means `m − 1` soft breaks.
  static List<InlineRun> _brRule(List<InlineRun> runs) {
    if (runs.isEmpty) return runs;
    if (runs.every(
      (r) => r.isPlain && r.text.split('').every((c) => c == softBreak),
    )) {
      final m = runs.fold(0, (n, r) => n + r.text.length);
      return m <= 1 ? const [] : [InlineRun(softBreak * (m - 1))];
    }
    return runs;
  }

  /// Emits inline content, splitting at inline images.
  void _inlineBlock(
    List<md.Node> children,
    DocBlock Function(List<InlineRun>) make,
  ) {
    final pieces = _reader.read(children);
    final runs = <InlineRun>[];
    var emitted = false;
    void flush({required bool force}) {
      final trimmed = _trimRuns(runs);
      if (trimmed.isNotEmpty || force) {
        _blocks.add(make(_brRule(trimmed)));
        emitted = true;
      }
      runs.clear();
    }

    for (final p in pieces) {
      switch (p) {
        case RunPiece(:final run):
          runs.add(run);
        case ImagePiece():
          flush(force: false);
          _image(p);
          emitted = true;
      }
    }
    flush(force: !emitted);
  }

  /// Drops whitespace-only runs at the edges that come from splitting at
  /// images (`text ![](x) text`).
  static List<InlineRun> _trimRuns(List<InlineRun> runs) =>
      InlineRun.merge(runs);

  void _image(ImagePiece p) {
    if (p.insideLink) {
      _warn(
        ImportWarningKind.imageFlattened,
        'Link around an image was removed',
      );
    }
    var src = LinkPolicy.normalizeImageSource(p.src);
    if (src == null || src.startsWith(ImageEmbed.importImageScheme)) {
      final resolved = _resolveRelative(p.src, p.alt);
      if (resolved == null) {
        _warn(
          ImportWarningKind.unresolvedImage,
          'Image "${p.src}" could not be imported',
        );
        _blocks.add(
          ParagraphBlock([
            InlineRun(
              '[image: ${p.alt.isEmpty ? '' : '${p.alt} '}(${p.src})]'
                  .replaceAll(': (', ': ('),
            ),
          ]),
        );
        return;
      }
      src = resolved.src;
    }
    _blocks.add(
      ImageBlock(
        options.idGenerator(),
        src,
        p.alt.replaceAll(RegExp(r'\s+'), ' ').trim(),
        title: (p.title == null || p.title!.trim().isEmpty)
            ? null
            : p.title!.replaceAll(RegExp(r'\s+'), ' ').trim(),
      ),
    );
  }

  ImportedImage? _resolveRelative(String src, String alt) {
    if (src.startsWith('data:')) {
      final m = RegExp(
        r'^data:(image/[A-Za-z0-9.+-]+);base64,(.*)$',
        dotAll: true,
      ).firstMatch(src);
      if (m == null) return null;
      try {
        final bytes = base64Decode(m.group(2)!.replaceAll(RegExp(r'\s'), ''));
        final img = ImportedImage(
          tempId: 'img${_imageCounter++}',
          bytes: Uint8List.fromList(bytes),
          mime: m.group(1)!,
          alt: alt,
        );
        _images.add(img);
        return img;
      } on FormatException {
        return null;
      }
    }
    final resolved = resolveImage?.call(src);
    if (resolved != null) _images.add(resolved);
    return resolved;
  }

  void _htmlBlock(String raw, void Function(List<InlineRun>) emit) {
    final trimmed = raw.trim();
    if (RegExp(r'^(?:<!--[\s\S]*?-->\s*)+$').hasMatch(trimmed)) {
      // Comment-only HTML block (the nested empty list item marker).
      emit(const []);
      return;
    }
    final brOnly = RegExp(r'^(?:<br\s*/?>\s*)+$', caseSensitive: false);
    if (brOnly.hasMatch(trimmed)) {
      final m = RegExp(r'<br', caseSensitive: false).allMatches(trimmed).length;
      emit(m <= 1 ? const [] : [InlineRun(softBreak * (m - 1))]);
      return;
    }
    _warn(ImportWarningKind.htmlBlock, 'HTML block converted to text');
    final text = decodeMdEntities(trimmed.replaceAll(RegExp(r'<[^>]*>'), ''));
    for (final para in text.split(RegExp(r'\n\s*\n'))) {
      final t = para.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (t.isNotEmpty) emit([InlineRun(t)]);
    }
  }

  void _code(md.Element pre) {
    final code = (pre.children ?? const [])
        .whereType<md.Element>()
        .where((e) => e.tag == 'code')
        .firstOrNull;
    final cls = code?.attributes['class'] ?? '';
    final lang = RegExp(r'language-(\S+)').firstMatch(cls)?.group(1) ?? '';
    var text = decodeMdEntities(code?.textContent ?? pre.textContent);
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
    _blocks.add(CodeBlock(_sanitizeLanguage(lang), text));
  }

  static String _sanitizeLanguage(String v) {
    final cleaned = v.replaceAll(RegExp(r'[^A-Za-z0-9_+#.\-]'), '');
    return cleaned.length > 32 ? cleaned.substring(0, 32) : cleaned;
  }

  void _quote(md.Element quote, {required int depth}) {
    if (depth > 0 && !_warnedQuote) {
      _warn(
        ImportWarningKind.nestedQuoteFlattened,
        'Nested blockquote flattened',
      );
      _warnedQuote = true;
    }
    void line(List<InlineRun> runs) => _blocks.add(QuoteBlock([runs]));
    for (final c in quote.children ?? const <md.Node>[]) {
      if (c is md.Text) {
        _htmlBlock(c.text, line);
        continue;
      }
      if (c is! md.Element) continue;
      switch (c.tag) {
        case 'p':
          _inlineBlock(c.children ?? const [], (runs) => QuoteBlock([runs]));
        case 'blockquote':
          _quote(c, depth: depth + 1);
        case 'ul' || 'ol':
          _list(c, 0, inQuote: true);
        case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
          _flattenWarn();
          _inlineBlock(c.children ?? const [], (runs) => QuoteBlock([runs]));
        case 'pre':
          _flattenWarn();
          var text = decodeMdEntities(c.textContent);
          if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
          for (final l in text.split('\n')) {
            line(
              l.isEmpty
                  ? const []
                  : [InlineRun(l.replaceAll('\t', '    '), code: true)],
            );
          }
        default:
          _flattenWarn();
          _topBlock(c);
      }
    }
  }

  void _flattenWarn() {
    if (_warnedFlatten) return;
    _warnedFlatten = true;
    _warn(
      ImportWarningKind.blockFlattened,
      'Block inside a quote or list item flattened',
    );
  }

  /// Imports a list; [inQuote] for a list inside a blockquote (its items
  /// are quoted, Write 02 §1.2).
  void _list(md.Element list, int depth, {bool inQuote = false}) {
    final ordered = list.tag == 'ol';
    final start = list.attributes['start'];
    if (ordered && start != null && start != '1' && !_warnedStart) {
      _warn(
        ImportWarningKind.orderedListStart,
        'Ordered list numbering restarts at 1',
      );
      _warnedStart = true;
    }
    var indent = depth;
    if (indent > 8) {
      indent = 8;
      _warn(
        ImportWarningKind.indentTooDeep,
        'List nesting deeper than 9 levels flattened',
      );
    }
    for (final li
        in (list.children ?? const <md.Node>[]).whereType<md.Element>()) {
      if (li.tag != 'li') continue;
      final children = li.children ?? const <md.Node>[];
      bool? checked;
      final inline = <md.Node>[];
      final nested = <md.Element>[];
      final others = <md.Node>[];
      var paragraphs = 0;
      for (final c in children) {
        if (c is md.Element &&
            c.tag == 'input' &&
            c.attributes['type'] == 'checkbox') {
          checked = c.attributes['checked'] == 'true';
        } else if (c is md.Element && (c.tag == 'ul' || c.tag == 'ol')) {
          nested.add(c);
        } else if (c is md.Element && c.tag == 'p') {
          final pc = c.children ?? const <md.Node>[];
          final first = pc.isNotEmpty ? pc.first : null;
          final rest = <md.Node>[];
          for (final n in pc) {
            if (n == first &&
                n is md.Element &&
                n.tag == 'input' &&
                n.attributes['type'] == 'checkbox') {
              checked = n.attributes['checked'] == 'true';
            } else {
              rest.add(n);
            }
          }
          if (paragraphs > 0) inline.add(md.Element.withTag('br'));
          inline.addAll(rest);
          paragraphs++;
        } else if (c is md.Element &&
            const {
              'pre',
              'blockquote',
              'table',
              'hr',
              'h1',
              'h2',
              'h3',
              'h4',
              'h5',
              'h6',
            }.contains(c.tag)) {
          others.add(c);
        } else if (c is md.Text && c.text.startsWith('\n')) {
          // An HTML block inside the item (e.g. the `<br>` empty-item marker).
          _htmlBlock(c.text, (runs) => inline.add(_RunsNode(runs)));
        } else {
          inline.add(c);
        }
      }
      if (paragraphs > 1) {
        _warn(
          ImportWarningKind.multiParagraphItem,
          'List item paragraphs joined',
        );
      }
      final runs = <InlineRun>[];
      final images = <ImagePiece>[];
      final pieces = <InlinePiece>[];
      final pending = <md.Node>[];
      for (final n in inline) {
        if (n is _RunsNode) {
          pieces.addAll(_reader.read(pending));
          pending.clear();
          pieces.addAll(n.runs.map(RunPiece.new));
        } else {
          pending.add(n);
        }
      }
      pieces.addAll(_reader.read(pending));
      for (final p in pieces) {
        switch (p) {
          case RunPiece(:final run):
            runs.add(run);
          case ImagePiece():
            images.add(p);
        }
      }
      final content = _brRule(InlineRun.merge(runs));
      if (checked != null) {
        _blocks.add(TaskBlock(checked, indent, content, inQuote: inQuote));
      } else {
        _blocks.add(
          ListItemBlock(
            ordered ? ListKindIr.ordered : ListKindIr.bullet,
            indent,
            content,
            inQuote: inQuote,
          ),
        );
      }
      for (final img in images) {
        _flattenWarn();
        _image(img);
      }
      for (final o in others) {
        _flattenWarn();
        _topBlock(o);
      }
      for (final n in nested) {
        _list(n, depth + 1, inQuote: inQuote);
      }
    }
  }

  void _table(md.Element table) {
    final rows = <List<List<InlineRun>>>[];
    final align = <CellAlign?>[];
    var first = true;
    for (final section
        in (table.children ?? const <md.Node>[]).whereType<md.Element>()) {
      for (final tr
          in (section.children ?? const <md.Node>[]).whereType<md.Element>()) {
        final cells = <List<InlineRun>>[];
        for (final cell
            in (tr.children ?? const <md.Node>[]).whereType<md.Element>()) {
          if (first) align.add(CellAlign.tryParse(cell.attributes['align']));
          cells.add(_reader.readRuns(cell.children ?? const []));
        }
        first = false;
        rows.add(cells);
      }
    }
    if (rows.isEmpty) return;
    final cols = rows.fold(align.length, (m, r) => r.length > m ? r.length : m);
    final markdown = [
      for (final r in rows)
        [
          for (var c = 0; c < cols; c++)
            c < r.length
                ? InlineMarkdownWriter.write([
                    for (final run in r[c])
                      run.copyWith(text: run.text.replaceAll(softBreak, ' ')),
                  ], context: InlineContext.tableCell)
                : '',
        ],
    ];
    _blocks.add(
      TableBlock(
        options.idGenerator(),
        [for (var c = 0; c < cols; c++) c < align.length ? align[c] : null],
        rows,
        cellMarkdown: markdown,
      ),
    );
  }
}

/// Pre-read runs placed among inline nodes of a list item.
final class _RunsNode extends md.Text {
  _RunsNode(this.runs) : super('');

  final List<InlineRun> runs;
}
