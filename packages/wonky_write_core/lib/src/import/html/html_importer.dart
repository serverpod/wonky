/// HTML import (07 §3.5): files and clipboard HTML, with Google Docs,
/// Microsoft Word and Wonky source normalizers.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../../delta/embeds.dart';
import '../../delta/links.dart';
import '../../ir/doc_tree.dart';
import '../../markdown/inline_reader.dart' show mentionTitlePrefix;
import '../encoding.dart';
import '../import_api.dart';
import '../import_support.dart';
import 'css_styles.dart';
import 'html_sources.dart';

/// Imports HTML documents and clipboard fragments.
///
/// The DOM (package `html`, HTML5 tree construction) is walked with a block
/// context stack (lists, list items, quotes, headings, table cells) and an
/// inherited inline format (bold, italic, strike, code, link, mention,
/// white-space mode). Whitespace collapses like in browsers (CSS
/// `white-space` in inline styles and simple class rules is honored).
///
/// Mapping (07 §3.5): `h1`–`h6` → headings; `p`/`div`/`section`/… →
/// paragraph boundaries (no empty paragraphs from wrappers; `<p><br></p>`
/// and `&nbsp;`-only blocks → empty paragraph); `br` → U+2028; `b`/`strong`,
/// `em`/`i`/`cite`, `s`/`del`/`strike`, `code`/`kbd`/`samp`/`tt` and the
/// equivalent `font-weight`/`font-style`/`text-decoration`/monospace
/// `font-family` styles → inline attributes; `pre` → code block with
/// language (`language-x`, `lang-x`, `data-lang`); `a[href]` → link
/// (absolute or resolved against `<base>`/[ImportOptions.baseUrl]); `img` →
/// image embed (`data:` URIs become [ImportedImage]s); nested `ul`/`ol` →
/// lists with indent; checkboxes / ☐☑☒ → tasks; `blockquote` → quote
/// (flattened); `hr` → divider; `table` → table embed (spans flattened);
/// `figure > img + figcaption` → image with title. Underline, colors,
/// highlights, sizes, sub/superscript and alignment are removed with one
/// aggregated warning; scripts, styles, frames, media, form controls and
/// comments are dropped.
final class HtmlImporter implements DocumentImporter {
  /// Creates the importer.
  const HtmlImporter();

  @override
  ImportFormat get format => ImportFormat.html;

  @override
  Future<ImportResult> import(Uint8List bytes, ImportOptions options) async {
    final decoded = ImportTextDecoder.decode(
      bytes,
      declaredCharset: sniffCharset(bytes),
    );
    return importHtml(decoded.text, options, extraWarnings: [?decoded.warning]);
  }

  /// Imports a complete HTML document ([html] already decoded). The title
  /// comes from `<title>`, else the first H1, else the file name; the
  /// language from `<html lang>`.
  ImportResult importHtml(
    String html,
    ImportOptions options, {
    List<ImportWarning> extraWarnings = const [],
  }) => _HtmlWalker(
    options,
    detectHtmlSource(html),
    fragment: false,
  ).run(html, extraWarnings);

  /// Imports clipboard HTML (paste, 07 §3.9). A Windows `CF_HTML` header is
  /// stripped; `<title>` is ignored.
  ImportResult importFragment(String html, {ImportOptions? options}) {
    final body = stripClipboardHeader(html);
    return _HtmlWalker(
      options ?? ImportOptions(),
      detectHtmlSource(body),
      fragment: true,
    ).run(body, const []);
  }

  /// Removes the `Version:…StartHTML:…` header of Windows clipboard HTML.
  static String stripClipboardHeader(String html) {
    if (!html.startsWith('Version:')) return html;
    final lt = html.indexOf('<');
    return lt < 0 ? '' : html.substring(lt);
  }

  /// The charset declared in a `<meta>` within the first 2 KB, or `null`.
  static String? sniffCharset(Uint8List bytes) {
    final head = latin1.decode(
      bytes.length > 2048 ? bytes.sublist(0, 2048) : bytes,
    );
    final m =
        RegExp(
          r'''<meta[^>]+charset\s*=\s*["']?\s*([A-Za-z0-9_.:\-]+)''',
          caseSensitive: false,
        ).firstMatch(head) ??
        RegExp(
          r'''<\?xml[^>]+encoding\s*=\s*["']([A-Za-z0-9_.:\-]+)''',
          caseSensitive: false,
        ).firstMatch(head);
    return m?.group(1);
  }
}

// ---------------------------------------------------------------------------
// Inline formatting and buffer

enum _Ws { normal, pre, preLine }

final class _Fmt {
  const _Fmt({
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.code = false,
    this.link,
    this.mention,
    this.ws = _Ws.normal,
  });

  static const plain = _Fmt();

  final bool bold;
  final bool italic;
  final bool strike;
  final bool code;
  final String? link;
  final String? mention;
  final _Ws ws;

  _Fmt copyWith({
    bool? bold,
    bool? italic,
    bool? strike,
    bool? code,
    _Ws? ws,
  }) => _Fmt(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    strike: strike ?? this.strike,
    code: code ?? this.code,
    link: link,
    mention: mention,
    ws: ws ?? this.ws,
  );

  _Fmt withLink(String? link, String? mention) => _Fmt(
    bold: bold,
    italic: italic,
    strike: strike,
    code: code,
    link: link,
    mention: link == null ? null : mention,
    ws: ws,
  );

  InlineRun run(String text) {
    final l = link;
    return InlineRun(
      text,
      bold: bold,
      italic: italic,
      strike: strike,
      code: code,
      link: l,
      mentionUserUuid: l != null && LinkPolicy.isMailto(l) ? mention : null,
    );
  }
}

const _kText = 0;
const _kSpace = 1; // collapsible space
const _kBreak = 2;

/// Inline content of the block being built, with browser-like collapsing.
final class _InlineBuffer {
  final _runs = <InlineRun>[];
  final _kinds = <int>[];
  var _breaks = 0;

  static final _asciiWs = RegExp(r'[ \t\n\r\f]+');

  bool get isEmpty => _runs.isEmpty;

  void text(String s, _Fmt f) {
    if (s.isEmpty) return;
    _runs.add(f.run(s));
    _kinds.add(_kText);
  }

  void space(_Fmt f) {
    if (_runs.isEmpty || _kinds.last != _kText) return;
    _runs.add(f.run(' '));
    _kinds.add(_kSpace);
  }

  void lineBreak(_Fmt f) {
    _dropTrailingSpaces();
    _runs.add(f.run(importSoftBreak));
    _kinds.add(_kBreak);
    _breaks++;
  }

  void appendNormal(String data, _Fmt f) {
    if (data.isEmpty) return;
    final s = ImportText.inline(data.replaceAll(_asciiWs, ' '));
    if (s.isEmpty) return;
    var start = 0;
    var end = s.length;
    while (start < end && s.codeUnitAt(start) == 0x20) {
      start++;
    }
    while (end > start && s.codeUnitAt(end - 1) == 0x20) {
      end--;
    }
    if (start > 0) space(f);
    if (end > start) {
      text(s.substring(start, end), f);
      if (end < s.length) space(f);
    }
  }

  void appendPreserved(
    String data,
    _Fmt f, {
    required bool collapseSpaces,
    required bool inCell,
  }) {
    final parts = data
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        if (inCell) {
          text(' ', f);
        } else {
          lineBreak(f);
        }
      }
      if (collapseSpaces) {
        appendNormal(parts[i], f);
      } else {
        text(ImportText.inline(parts[i]), f);
      }
    }
  }

  void _dropTrailingSpaces() {
    while (_kinds.isNotEmpty && _kinds.last == _kSpace) {
      _kinds.removeLast();
      _runs.removeLast();
    }
  }

  /// Takes the content: trailing collapsible spaces and one trailing break
  /// removed (a trailing `<br>` does not create a line in browsers).
  (List<InlineRun>, bool) take() {
    _dropTrailingSpaces();
    final hadBreak = _breaks > 0;
    if (_kinds.isNotEmpty && _kinds.last == _kBreak) {
      _kinds.removeLast();
      _runs.removeLast();
    }
    final runs = InlineRun.merge(_runs);
    _runs.clear();
    _kinds.clear();
    _breaks = 0;
    return (runs, hadBreak);
  }
}

// ---------------------------------------------------------------------------
// Block contexts

sealed class _Ctx {}

final class _ListCtx extends _Ctx {
  _ListCtx(this.ordered, this.level);
  final bool ordered;
  final int? level;
}

final class _ItemCtx extends _Ctx {
  _ItemCtx(this.kind, this.indent, this.checked, this.startBlocks);
  final ListKindIr kind;
  final int indent;
  final bool? checked;
  final int startBlocks;
  var emitted = false;
  var blockIndex = -1;
  bool? emittedChecked;
}

final class _QuoteCtx extends _Ctx {}

final class _HeadingCtx extends _Ctx {
  _HeadingCtx(this.level);
  final int level;
}

const _silentDrop = {
  'script',
  'style',
  'template',
  'noscript',
  'head',
  'meta',
  'link',
  'title',
  'base',
  'param',
  'source',
  'track',
  'datalist',
  'area',
  'map',
  'rp',
  'colgroup',
  'col',
  'wbr',
};

const _warnDrop = {
  'iframe',
  'frame',
  'frameset',
  'object',
  'embed',
  'applet',
  'svg',
  'canvas',
  'video',
  'audio',
  'button',
  'select',
  'textarea',
  'dialog',
  'portal',
};

const _blockTags = {
  'p',
  'div',
  'section',
  'article',
  'header',
  'footer',
  'main',
  'aside',
  'nav',
  'address',
  'center',
  'dl',
  'dt',
  'dd',
  'details',
  'summary',
  'fieldset',
  'legend',
  'hgroup',
  'figcaption',
  'caption',
  'body',
  'html',
  'form',
  'search',
  'tr',
  'td',
  'th',
  'thead',
  'tbody',
  'tfoot',
  'option',
  'optgroup',
};

const _otherBlockLevel = {
  'ul',
  'ol',
  'menu',
  'dir',
  'li',
  'table',
  'pre',
  'listing',
  'xmp',
  'plaintext',
  'blockquote',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'hr',
  'figure',
  'img',
};

bool _isBlockLevel(dom.Element e) {
  final t = e.localName ?? '';
  return _blockTags.contains(t) || _otherBlockLevel.contains(t);
}

const _maxDepth = 400;

// ---------------------------------------------------------------------------
// Walker

final class _HtmlWalker {
  _HtmlWalker(this.options, this.source, {required this.fragment});

  final ImportOptions options;
  final HtmlSource source;
  final bool fragment;

  final _warnings = WarningCollector();
  final _images = ImageCollector();
  final _blocks = <DocBlock>[];
  var _buf = _InlineBuffer();
  var _stack = <_Ctx>[];
  var _cellDepth = 0;
  var _depth = 0;
  var _css = CssClassRules.empty;
  Uri? _base;
  String? _pendingCaption;
  dom.Node? _skip;

  bool get _isOffice =>
      source == HtmlSource.googleDocs || source == HtmlSource.msWord;

  ImportResult run(String html, List<ImportWarning> extra) {
    extra.forEach(_warnings.addWarning);
    _base = options.baseUrl;
    String? title;
    String? language;
    try {
      final doc = html_parser.parse(html);
      final root = doc.documentElement;
      title = _readHead(doc);
      language = _language(doc);
      _css = CssClassRules.parse(
        doc.querySelectorAll('style').map((e) => e.text),
      );
      dom.Element? start;
      if (source == HtmlSource.wonky) {
        start = doc.querySelector('article.wonky-doc');
      }
      start ??= doc.body ?? root;
      if (start != null) _element(start, _Fmt.plain);
      _flush();
    } on Object {
      // The HTML5 parser recovers from nearly everything; keep any content
      // built so far and fall back to the tag-stripped text otherwise.
      if (_blocks.isEmpty) {
        final text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
        _buf = _InlineBuffer()..appendNormal(text, _Fmt.plain);
        _stack = [];
        _cellDepth = 0;
        _flush();
      }
      _warnings.add(
        ImportWarningKind.contentDropped,
        'Parts of the HTML could not be read.',
      );
    }
    if (_blocks.isEmpty) _blocks.add(const ParagraphBlock([]));
    return buildImportResult(
      _blocks,
      options: options,
      warnings: _warnings,
      images: _images,
      title: fragment ? null : title,
      language: language,
    );
  }

  String? _readHead(dom.Document doc) {
    final baseHref = doc.querySelector('base[href]')?.attributes['href'];
    if (baseHref != null && baseHref.trim().isNotEmpty) {
      final parsed = Uri.tryParse(baseHref.trim());
      if (parsed != null) {
        _base = parsed.hasScheme ? parsed : _base?.resolveUri(parsed);
      }
    }
    final t = doc.querySelector('title')?.text;
    if (t == null) return null;
    final cleaned = ImportText.inline(
      t.replaceAll(RegExp(r'[ \t\n\r\f]+'), ' '),
    ).trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String? _language(dom.Document doc) {
    final html = doc.documentElement;
    return normalizeLanguageTag(
      html?.attributes['lang'] ??
          html?.attributes['xml:lang'] ??
          doc.body?.attributes['lang'],
    );
  }

  // -------------------------------------------------------------------------
  // Dispatch

  void _children(dom.Node parent, _Fmt fmt) {
    for (final n in parent.nodes.toList()) {
      if (identical(n, _skip)) continue;
      if (n is dom.Element) {
        _element(n, fmt);
      } else if (n is dom.Text) {
        _text(n, parent, fmt);
      }
    }
  }

  CssDeclarations _decls(dom.Element e) {
    final classes = e.classes;
    final fromClasses = classes.isEmpty
        ? CssDeclarations.empty
        : _css.forClasses(classes);
    return fromClasses.merge(CssDeclarations.parse(e.attributes['style']));
  }

  static bool _hidden(CssDeclarations d) {
    final display = d['display']?.toLowerCase();
    if (display == 'none') return true;
    final vis = d['visibility']?.toLowerCase();
    if (vis == 'hidden' || vis == 'collapse') return true;
    final mso = d['mso-hide']?.toLowerCase();
    return mso == 'all';
  }

  void _element(dom.Element e, _Fmt fmt) {
    final tag = e.localName ?? '';
    if (_silentDrop.contains(tag)) return;
    if (_warnDrop.contains(tag)) {
      _warnings.add(
        ImportWarningKind.contentDropped,
        'Embedded content (frames, media, graphics, form controls) was '
        'removed.',
        blockIndex: _blocks.length,
      );
      return;
    }
    if (e.attributes.containsKey('hidden')) return;
    final classes = e.classes;
    if (classes.any(WonkyHtml.decorationClasses.contains)) return;
    if (source == HtmlSource.wonky && e.attributes['aria-hidden'] == 'true') {
      return;
    }
    if (source == HtmlSource.msWord && MsWordHtml.isListMarker(e)) return;
    final decls = _decls(e);
    if (_hidden(decls)) return;
    if (_depth >= _maxDepth) {
      _buf.appendNormal(e.text, fmt);
      return;
    }
    _depth++;
    try {
      final f = _applyFormatting(e, tag, decls, fmt);
      switch (tag) {
        case 'br':
          _br(f);
        case 'img':
          _image(e, f);
        case 'hr':
          _flush();
          if (_cellDepth == 0) _blocks.add(RuleBlock(options.idGenerator()));
        case 'pre' || 'listing' || 'xmp' || 'plaintext':
          _pre(e, f);
        case 'table':
          _table(e, f);
        case 'ul' || 'ol' || 'menu' || 'dir':
          _list(e, f, decls);
        case 'li':
          _li(e, f, decls);
        case 'blockquote':
          _quote(e, f);
        case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
          _heading(int.parse(tag.substring(1)), e, f);
        case 'figure':
          _figure(e, f);
        case 'a':
          _link(e, f);
        case 'input':
          if ((e.attributes['type'] ?? '').toLowerCase() != 'checkbox') {
            _warnings.add(
              ImportWarningKind.contentDropped,
              'Embedded content (frames, media, graphics, form controls) '
              'was removed.',
              blockIndex: _blocks.length,
            );
          }
        case 'math':
          _warnings.add(
            ImportWarningKind.placeholderInserted,
            'Equations were converted to plain text.',
            blockIndex: _blocks.length,
          );
          _children(e, f);
        case 'q':
          _buf.appendNormal('“', f);
          _children(e, f);
          _buf.appendNormal('”', f);
        default:
          if (_blockTags.contains(tag)) {
            _blockElement(e, tag, f, decls);
          } else {
            _children(e, f);
          }
      }
    } finally {
      _depth--;
    }
  }

  _Fmt _applyFormatting(
    dom.Element e,
    String tag,
    CssDeclarations d,
    _Fmt fmt,
  ) {
    var f = fmt;
    switch (tag) {
      case 'b' || 'strong':
        f = f.copyWith(bold: true);
      case 'i' || 'em' || 'cite':
        f = f.copyWith(italic: true);
      case 's' || 'del' || 'strike':
        f = f.copyWith(strike: true);
      case 'code' || 'kbd' || 'samp' || 'tt':
        f = f.copyWith(code: true);
      case 'u' || 'ins':
        _removed('underline');
      case 'mark':
        _removed('highlight');
      case 'sup' || 'sub':
        _removed('superscript and subscript');
      case 'small' || 'big':
        _removed('font sizes');
      case 'font':
        if (CssValues.isCustomColor(e.attributes['color'])) _removed('colors');
        if (MonospaceFonts.isMonospace(e.attributes['face'])) {
          f = f.copyWith(code: true);
        }
        if (e.attributes.containsKey('size')) _removed('font sizes');
    }
    if (d.isEmpty) return f;
    final bold = CssValues.fontWeightBold(d['font-weight']);
    if (bold != null) f = f.copyWith(bold: bold);
    final italic = CssValues.fontStyleItalic(d['font-style']);
    if (italic != null) f = f.copyWith(italic: italic);
    final deco = (d['text-decoration'] ?? d['text-decoration-line'])
        ?.toLowerCase();
    if (deco != null) {
      if (deco.contains('line-through')) f = f.copyWith(strike: true);
      if (deco.contains('underline')) _removed('underline');
    }
    if (MonospaceFonts.isMonospace(d['font-family'])) {
      f = f.copyWith(code: true);
    }
    if (CssValues.isCustomColor(d['color'])) _removed('colors');
    if (CssValues.isHighlight(d['background-color']) ||
        CssValues.isHighlight(d['background'])) {
      _removed('highlight');
    }
    final va = d['vertical-align']?.toLowerCase();
    if (va == 'super' || va == 'sub') _removed('superscript and subscript');
    final ta = d['text-align']?.toLowerCase();
    if ((ta == 'center' || ta == 'right' || ta == 'justify') &&
        tag != 'td' &&
        tag != 'th') {
      _removed('alignment');
    }
    final ws = d['white-space']?.toLowerCase();
    if (ws != null) {
      if (ws.startsWith('pre-line')) {
        f = f.copyWith(ws: _Ws.preLine);
      } else if (ws.startsWith('pre') || ws.startsWith('break-spaces')) {
        f = f.copyWith(ws: _Ws.pre);
      } else if (ws == 'normal' || ws == 'nowrap') {
        f = f.copyWith(ws: _Ws.normal);
      }
    }
    return f;
  }

  void _removed(String feature) =>
      _warnings.formattingRemoved(feature, blockIndex: _blocks.length);

  // -------------------------------------------------------------------------
  // Inline content

  void _text(dom.Text t, dom.Node parent, _Fmt fmt) {
    final data = t.data;
    if (data.isEmpty) return;
    if (fmt.ws == _Ws.normal) {
      _buf.appendNormal(data, fmt);
      return;
    }
    if (data.trim().isEmpty &&
        parent is dom.Element &&
        parent.children.any(_isBlockLevel)) {
      return; // formatting whitespace between blocks
    }
    _buf.appendPreserved(
      data,
      fmt,
      collapseSpaces: fmt.ws == _Ws.preLine,
      inCell: _cellDepth > 0,
    );
  }

  void _br(_Fmt f) {
    if (_cellDepth > 0) {
      _buf.space(f);
    } else {
      _buf.lineBreak(f);
    }
  }

  void _link(dom.Element e, _Fmt fmt) {
    final href = e.attributes['href'];
    if (href == null) {
      _children(e, fmt);
      return;
    }
    final link = _resolveLink(href);
    String? mention;
    if (link != null && LinkPolicy.isMailto(link)) {
      for (final a in WonkyHtml.mentionAttributes) {
        final v = e.attributes[a]?.trim();
        if (v != null && v.isNotEmpty) {
          mention = v;
          break;
        }
      }
      final title = e.attributes['title'];
      if (mention == null &&
          title != null &&
          title.startsWith(mentionTitlePrefix) &&
          title.length > mentionTitlePrefix.length) {
        mention = title.substring(mentionTitlePrefix.length).trim();
      }
    }
    _children(e, fmt.withLink(link, mention));
  }

  static final _scheme = RegExp(r'^([A-Za-z][A-Za-z0-9+.\-]*):');

  String? _resolveLink(String href) {
    final h = href.trim();
    if (h.isEmpty || h.startsWith('#')) return null;
    final m = _scheme.firstMatch(h);
    if (m != null) {
      final scheme = m.group(1)!.toLowerCase();
      if (scheme == 'javascript' ||
          scheme == 'vbscript' ||
          scheme == 'data' ||
          scheme == 'file' ||
          scheme == 'blob') {
        _unsupportedLink();
        return null;
      }
      final n = LinkPolicy.normalizeLink(h);
      if (n == null) _unsupportedLink();
      return n;
    }
    if (h.startsWith('//')) {
      final n = LinkPolicy.normalizeLink('https:$h');
      if (n == null) _unsupportedLink();
      return n;
    }
    final base = _base;
    if (base != null) {
      try {
        final n = LinkPolicy.normalizeLink(base.resolve(h).toString());
        if (n != null) return n;
      } on FormatException {
        // fall through
      }
    }
    _unsupportedLink();
    return null;
  }

  void _unsupportedLink() => _warnings.add(
    ImportWarningKind.unsupportedLink,
    'Links with relative or unsupported targets were removed (the text was '
    'kept).',
    blockIndex: _blocks.length,
  );

  // -------------------------------------------------------------------------
  // Images

  void _image(dom.Element e, _Fmt fmt) {
    final src = e.attributes['src']?.trim();
    if (src == null || src.isEmpty) return;
    final w = e.attributes['width']?.trim();
    final h = e.attributes['height']?.trim();
    if ((w == '0' || w == '1') && (h == '0' || h == '1')) return; // pixel
    final alt = ImportText.inline(
      (e.attributes['alt'] ?? '').replaceAll(RegExp(r'[ \t\n\r\f]+'), ' '),
    ).trim();
    final caption = _pendingCaption;
    _pendingCaption = null;
    final rawTitle = caption ?? e.attributes['title'];
    final title = rawTitle == null
        ? null
        : ImportText.inline(
            fmt.ws == _Ws.normal
                ? rawTitle.replaceAll(RegExp(r'[ \t\n\r\f]+'), ' ').trim()
                : rawTitle,
          );
    if (_cellDepth > 0) {
      if (alt.isNotEmpty) _buf.appendNormal(' $alt ', fmt.withLink(null, null));
      _warnings.add(
        ImportWarningKind.imageFlattened,
        'Images inside tables were replaced by their description.',
        blockIndex: _blocks.length,
      );
      return;
    }
    final resolved = _resolveImage(src, alt);
    _flush();
    if (resolved == null) {
      _blocks.add(imagePlaceholder(alt));
    } else {
      _blocks.add(
        ImageBlock(
          options.idGenerator(),
          resolved,
          alt,
          title: (title == null || title.isEmpty) ? null : title,
        ),
      );
    }
  }

  String? _resolveImage(String src, String alt) {
    final lower = src.toLowerCase();
    if (lower.startsWith('data:')) return _dataImage(src, alt);
    if (lower.startsWith('https://') ||
        lower.startsWith('http://') ||
        lower.startsWith(ImageEmbed.wonkyFileScheme)) {
      return _checkedSource(src);
    }
    if (lower.startsWith('//')) return _checkedSource('https:$src');
    if (_scheme.hasMatch(src)) {
      _unresolvedImage();
      return null;
    }
    final base = _base;
    if (base != null) {
      try {
        final r = base.resolve(src).toString();
        final rl = r.toLowerCase();
        if (rl.startsWith('https://') || rl.startsWith('http://')) {
          return _checkedSource(r);
        }
      } on FormatException {
        // fall through
      }
    }
    _unresolvedImage();
    return null;
  }

  String? _checkedSource(String src) {
    final n = LinkPolicy.normalizeImageSource(src);
    if (n == null) _unresolvedImage();
    return n;
  }

  String? _dataImage(String src, String alt) {
    try {
      final data = UriData.parse(src.replaceAll(RegExp(r'\s'), ''));
      final bytes = data.contentAsBytes();
      final mime = ImageMime.sniff(bytes) ?? data.mimeType.toLowerCase();
      final embeddable = embeddableImage(bytes, mime);
      if (embeddable == null) {
        _unresolvedImage();
        return null;
      }
      return _images.add(embeddable.$1, embeddable.$2, alt: alt).src;
    } on FormatException {
      _unresolvedImage();
      return null;
    }
  }

  void _unresolvedImage() => _warnings.add(
    ImportWarningKind.unresolvedImage,
    'Some images could not be imported (relative or unsupported sources); '
    'they were replaced by placeholders.',
    blockIndex: _blocks.length,
  );

  // -------------------------------------------------------------------------
  // Blocks

  void _blockElement(
    dom.Element e,
    String tag,
    _Fmt fmt,
    CssDeclarations decls,
  ) {
    if (source == HtmlSource.msWord) {
      final level = MsWordHtml.listLevel(decls);
      if (level != null) {
        _wordListItem(e, fmt, level);
        return;
      }
      final h = MsWordHtml.headingLevel(e.classes);
      if (h != null) {
        _heading(h, e, fmt);
        return;
      }
      if (MsWordHtml.isQuote(e.classes)) {
        _quote(e, fmt);
        return;
      }
    } else if (source == HtmlSource.googleDocs) {
      final h = GoogleDocsHtml.headingLevel(e.classes);
      if (h != null) {
        _heading(h, e, fmt);
        return;
      }
    }
    _flush();
    final start = _blocks.length;
    _children(e, fmt);
    _flush(
      explicitEmpty:
          source == HtmlSource.wonky && tag == 'p' && _blocks.length == start,
    );
  }

  void _heading(int level, dom.Element e, _Fmt fmt) {
    _flush();
    _stack.add(_HeadingCtx(level));
    final start = _blocks.length;
    _children(e, fmt);
    // A heading of only whitespace is still a (empty) heading line.
    _flush(explicitEmpty: _blocks.length == start);
    _stack.removeLast();
  }

  void _quote(dom.Element e, _Fmt fmt) {
    _flush();
    if (_stack.any((c) => c is _QuoteCtx)) {
      _warnings.add(
        ImportWarningKind.nestedQuoteFlattened,
        'Nested quotes were flattened to one level.',
        blockIndex: _blocks.length,
      );
    }
    _stack.add(_QuoteCtx());
    _children(e, fmt);
    _flush();
    _stack.removeLast();
  }

  void _figure(dom.Element e, _Fmt fmt) {
    _flush();
    final img = e.querySelector('img');
    final cap = e.children.firstWhereOrNull((c) => c.localName == 'figcaption');
    final prevSkip = _skip;
    if (img != null && cap != null) {
      _pendingCaption = cap.text;
      _skip = cap;
    }
    _children(e, fmt);
    _pendingCaption = null;
    _skip = prevSkip;
    _flush();
  }

  void _pre(dom.Element e, _Fmt fmt) {
    final b = StringBuffer();
    _preText(e, b);
    var text = b.toString().replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
    if (_cellDepth > 0) {
      _buf.appendNormal(' ', fmt);
      _buf.text(ImportText.inline(text), fmt.copyWith(code: true));
      _buf.space(fmt);
      return;
    }
    _flush();
    if (_stack.any((c) => c is _ItemCtx || c is _QuoteCtx)) {
      _warnings.add(
        ImportWarningKind.blockFlattened,
        'Code blocks inside lists or quotes were moved out of them.',
        blockIndex: _blocks.length,
      );
    }
    _blocks.add(
      CodeBlock(
        _codeLanguage(e),
        text.split('\n').map(ImportText.codeLine).join('\n'),
      ),
    );
  }

  void _preText(dom.Node n, StringBuffer b) {
    for (final c in n.nodes) {
      if (c is dom.Text) {
        b.write(c.data);
      } else if (c is dom.Element) {
        final tag = c.localName ?? '';
        if (_silentDrop.contains(tag) || _warnDrop.contains(tag)) continue;
        if (_hidden(_decls(c))) continue;
        if (c.classes.any(
          (k) => k.contains('line-number') || k.contains('lineno'),
        )) {
          continue;
        }
        if (tag == 'br') {
          b.write('\n');
          continue;
        }
        final block = _blockTags.contains(tag) || tag == 'li';
        if (block && b.isNotEmpty && !b.toString().endsWith('\n')) {
          b.write('\n');
        }
        _preText(c, b);
      }
    }
  }

  static String _codeLanguage(dom.Element pre) {
    final candidates = <dom.Element>[
      pre,
      ...pre.children.where((c) => c.localName == 'code').take(1),
    ];
    for (final el in candidates.reversed) {
      final attr = el.attributes['data-lang'] ?? el.attributes['data-language'];
      if (attr != null && attr.trim().isNotEmpty) {
        return ImportText.language(attr);
      }
      final classes = el.classes.toList();
      for (final c in classes) {
        if (c.startsWith('language-')) {
          return ImportText.language(c.substring(9));
        }
        if (c.startsWith('lang-')) return ImportText.language(c.substring(5));
      }
      if (classes.contains('sourceCode')) {
        final other = classes.firstWhereOrNull((c) => c != 'sourceCode');
        if (other != null) return ImportText.language(other);
      }
    }
    return '';
  }

  // -------------------------------------------------------------------------
  // Lists

  void _list(dom.Element e, _Fmt fmt, CssDeclarations decls) {
    _flush();
    final inner = _stack.lastOrNull;
    if (inner is _ItemCtx && !inner.emitted) {
      _emitItem(inner, const []);
    }
    var ordered = e.localName == 'ol';
    final style = _listStyleOrdered(decls['list-style-type']);
    if (style != null) ordered = style;
    final start = int.tryParse(e.attributes['start']?.trim() ?? '');
    if (ordered && start != null && start != 1) _orderedStart();
    final level = source == HtmlSource.googleDocs
        ? GoogleDocsHtml.exportListLevel(e.classes)
        : null;
    _stack.add(_ListCtx(ordered, level));
    _children(e, fmt);
    _flush();
    _stack.removeLast();
  }

  void _orderedStart() => _warnings.add(
    ImportWarningKind.orderedListStart,
    'Numbered lists that did not start at 1 now start at 1.',
    blockIndex: _blocks.length,
  );

  static bool? _listStyleOrdered(String? v) {
    if (v == null) return null;
    final s = v.trim().toLowerCase();
    if (s.isEmpty || s == 'inherit' || s == 'initial') return null;
    if (s == 'disc' || s == 'circle' || s == 'square' || s == 'none') {
      return false;
    }
    if (s.contains('decimal') ||
        s.contains('alpha') ||
        s.contains('roman') ||
        s.contains('latin') ||
        s.contains('greek') ||
        s.contains('numeric')) {
      return true;
    }
    return null;
  }

  static final _qlIndent = RegExp(r'^ql-indent-(\d+)$');

  void _li(dom.Element e, _Fmt fmt, CssDeclarations decls) {
    _flush();
    final lists = _stack.whereType<_ListCtx>().toList();
    final list = lists.lastOrNull;
    var indent = lists.isEmpty ? 0 : lists.length - 1;
    final aria = int.tryParse(e.attributes['aria-level']?.trim() ?? '');
    if (aria != null && aria >= 1) {
      indent = aria - 1;
    } else if (list?.level != null) {
      indent = list!.level!;
    }
    for (final c in e.classes) {
      final m = _qlIndent.firstMatch(c);
      if (m != null) indent = int.parse(m.group(1)!);
    }
    if (indent > 8) {
      _warnings.add(
        ImportWarningKind.indentTooDeep,
        'Lists nested deeper than 9 levels were flattened.',
        blockIndex: _blocks.length,
      );
      indent = 8;
    }
    var ordered = list?.ordered ?? false;
    final style = _listStyleOrdered(decls['list-style-type']);
    if (style != null) ordered = style;
    final value = int.tryParse(e.attributes['value']?.trim() ?? '');
    if (ordered && value != null && value != 1 && list != null) {
      final siblings = e.parent?.children.where((c) => c.localName == 'li');
      if (siblings != null && identical(siblings.firstOrNull, e)) {
        _orderedStart();
      }
    }
    bool? checked;
    if (e.attributes['role'] == 'checkbox') {
      checked = e.attributes['aria-checked'] == 'true';
    } else {
      checked = _leadingCheckbox(e);
    }
    final item = _ItemCtx(
      ordered ? ListKindIr.ordered : ListKindIr.bullet,
      indent,
      checked,
      _blocks.length,
    );
    _stack.add(item);
    _children(e, fmt);
    _flush();
    _closeItem(item);
    _stack.removeLast();
  }

  void _wordListItem(dom.Element e, _Fmt fmt, int level) {
    _flush();
    final ordered = MsWordHtml.isOrderedMarker(MsWordHtml.markerText(e));
    var indent = level - 1;
    if (indent < 0) indent = 0;
    if (indent > 8) {
      _warnings.add(
        ImportWarningKind.indentTooDeep,
        'Lists nested deeper than 9 levels were flattened.',
        blockIndex: _blocks.length,
      );
      indent = 8;
    }
    final item = _ItemCtx(
      ordered ? ListKindIr.ordered : ListKindIr.bullet,
      indent,
      null,
      _blocks.length,
    );
    _stack.add(item);
    _children(e, fmt);
    _flush();
    _closeItem(item);
    _stack.removeLast();
  }

  void _closeItem(_ItemCtx item) {
    if (!item.emitted && _blocks.length == item.startBlocks) {
      _emitItem(item, const []);
    }
  }

  static bool? _leadingCheckbox(dom.Element li) {
    bool? result;
    bool visit(dom.Node n) {
      for (final c in n.nodes) {
        if (c is dom.Text) {
          if (c.data.trim().isNotEmpty) return true;
        } else if (c is dom.Element) {
          final tag = c.localName;
          if (tag == 'input') {
            if ((c.attributes['type'] ?? '').toLowerCase() == 'checkbox') {
              result = c.attributes.containsKey('checked');
            }
            return true;
          }
          if (tag == 'ul' ||
              tag == 'ol' ||
              tag == 'table' ||
              tag == 'pre' ||
              tag == 'img') {
            return true;
          }
          if (visit(c)) return true;
        }
      }
      return false;
    }

    visit(li);
    return result;
  }

  // -------------------------------------------------------------------------
  // Tables

  void _table(dom.Element table, _Fmt fmt) {
    _flush();
    if (_cellDepth > 0) {
      _warnings.add(
        ImportWarningKind.tableFlattened,
        'Nested tables were converted to text.',
        blockIndex: _blocks.length,
      );
      _children(table, fmt);
      return;
    }
    final head = <dom.Element>[];
    final body = <dom.Element>[];
    final foot = <dom.Element>[];
    dom.Element? caption;
    for (final c in table.children) {
      switch (c.localName) {
        case 'thead':
          head.addAll(c.children.where((r) => r.localName == 'tr'));
        case 'tbody':
          body.addAll(c.children.where((r) => r.localName == 'tr'));
        case 'tfoot':
          foot.addAll(c.children.where((r) => r.localName == 'tr'));
        case 'tr':
          body.add(c);
        case 'caption':
          caption ??= c;
      }
    }
    final rows = [...head, ...body, ...foot];
    List<dom.Element> cells(dom.Element tr) => tr.children
        .where((c) => c.localName == 'td' || c.localName == 'th')
        .toList();
    final cellCount = rows.fold(0, (n, r) => n + cells(r).length);
    final role = table.attributes['role']?.toLowerCase();
    if (role == 'presentation' ||
        role == 'none' ||
        (cellCount <= 1 && source != HtmlSource.wonky)) {
      // Layout table: keep the content as blocks.
      if (caption != null) {
        _blockElement(caption, 'caption', fmt, CssDeclarations.empty);
      }
      for (final r in rows) {
        for (final c in cells(r)) {
          _blockElement(
            c,
            'td',
            _applyFormatting(c, 'td', _decls(c), fmt),
            _decls(c),
          );
        }
      }
      return;
    }
    if (rows.isEmpty) return;
    if (caption != null) {
      final runs = _cellRuns(caption, fmt);
      if (!RunTools.isBlank(runs)) _blocks.add(ParagraphBlock(runs));
    }
    final grid = <List<List<InlineRun>>>[];
    final align = <CellAlign?>[];
    final pending = <int, int>{};
    var spanned = false;
    for (final tr in rows) {
      final row = <List<InlineRun>>[];
      var col = 0;
      void fillPending() {
        while ((pending[col] ?? 0) > 0) {
          pending[col] = pending[col]! - 1;
          row.add(const []);
          col++;
        }
      }

      for (final cell in cells(tr)) {
        fillPending();
        final runs = _cellRuns(cell, fmt);
        final a = _cellAlign(cell);
        while (align.length <= col) {
          align.add(null);
        }
        if (align[col] == null && a != null) align[col] = a;
        row.add(runs);
        final colspan = (int.tryParse(cell.attributes['colspan'] ?? '') ?? 1)
            .clamp(1, 64);
        final rowspan = (int.tryParse(cell.attributes['rowspan'] ?? '') ?? 1)
            .clamp(1, 1000);
        for (var k = 1; k < colspan; k++) {
          row.add(const []);
        }
        if (colspan > 1 || rowspan > 1) spanned = true;
        if (rowspan > 1) {
          for (var k = 0; k < colspan; k++) {
            pending[col + k] = rowspan - 1;
          }
        }
        col += colspan;
      }
      final maxPending = pending.entries
          .where((en) => en.value > 0)
          .fold(-1, (m, en) => en.key > m ? en.key : m);
      while (col <= maxPending) {
        if ((pending[col] ?? 0) > 0) pending[col] = pending[col]! - 1;
        row.add(const []);
        col++;
      }
      if (row.isNotEmpty) grid.add(row);
    }
    if (grid.isEmpty) return;
    if (spanned) {
      _warnings.add(
        ImportWarningKind.tableFlattened,
        'Merged table cells were split; their content is in the first cell.',
        blockIndex: _blocks.length,
      );
    }
    _blocks.add(buildTable(options.idGenerator(), grid, align));
  }

  static CellAlign? _cellAlign(dom.Element cell) {
    final a =
        cell.attributes['align'] ??
        CssDeclarations.parse(cell.attributes['style'])['text-align'];
    return switch (a?.trim().toLowerCase()) {
      'left' || 'start' => CellAlign.left,
      'center' => CellAlign.center,
      'right' || 'end' => CellAlign.right,
      _ => null,
    };
  }

  List<InlineRun> _cellRuns(dom.Element cell, _Fmt fmt) {
    final saveBuf = _buf;
    final saveStack = _stack;
    _buf = _InlineBuffer();
    _stack = [];
    _cellDepth++;
    try {
      final d = _decls(cell);
      _children(cell, _applyFormatting(cell, cell.localName ?? 'td', d, fmt));
      final (runs, _) = _buf.take();
      return RunTools.trim(RunTools.singleLine(runs));
    } finally {
      _cellDepth--;
      _buf = saveBuf;
      _stack = saveStack;
    }
  }

  // -------------------------------------------------------------------------
  // Emission

  void _flush({bool explicitEmpty = false}) {
    if (_cellDepth > 0) {
      _buf.space(_Fmt.plain);
      return;
    }
    if (_buf.isEmpty && !explicitEmpty) return;
    var (runs, hadBreak) = _buf.take();
    if (runs.isNotEmpty && _onlyNbsp(runs)) runs = const [];
    if (runs.isEmpty && !hadBreak && !explicitEmpty) return;
    _emit(runs);
  }

  static bool _onlyNbsp(List<InlineRun> runs) {
    for (final r in runs) {
      for (final u in r.text.codeUnits) {
        if (u != 0xA0) return false;
      }
    }
    return true;
  }

  void _emit(List<InlineRun> runs) {
    var qi = -1;
    var ii = -1;
    var hi = -1;
    for (var i = _stack.length - 1; i >= 0; i--) {
      final c = _stack[i];
      if (c is _QuoteCtx && qi < 0) qi = i;
      if (c is _ItemCtx && ii < 0) ii = i;
      if (c is _HeadingCtx && hi < 0) hi = i;
    }
    if (qi >= 0) {
      if (ii > qi) {
        // A list inside the quote: quoted list items (Write 02 §1.2).
        if (hi > ii) _flattened();
        _emitItem(_stack[ii] as _ItemCtx, runs);
        return;
      }
      if (hi > qi || ii >= 0) _flattened();
      _blocks.add(QuoteBlock([runs]));
      return;
    }
    if (ii >= 0) {
      if (hi > ii) _flattened();
      _emitItem(_stack[ii] as _ItemCtx, runs);
      return;
    }
    if (hi >= 0) {
      _blocks.add(HeadingBlock((_stack[hi] as _HeadingCtx).level, runs));
      return;
    }
    if (_isOffice &&
        runs.any((r) => r.code) &&
        runs.every((r) => r.code || r.text.trim().isEmpty)) {
      final text = InlineRun.plainText(runs).replaceAll(importSoftBreak, '\n');
      _blocks.add(
        CodeBlock('', text.split('\n').map(ImportText.codeLine).join('\n')),
      );
      return;
    }
    _blocks.add(ParagraphBlock(runs));
  }

  void _flattened() => _warnings.add(
    ImportWarningKind.blockFlattened,
    'Headings, quotes or code inside lists or quotes were flattened.',
    blockIndex: _blocks.length,
  );

  DocBlock _itemBlock(_ItemCtx item, bool? checked, List<InlineRun> runs) {
    final quoted = _isQuoted(item);
    return checked != null
        ? TaskBlock(checked, item.indent, runs, inQuote: quoted)
        : ListItemBlock(item.kind, item.indent, runs, inQuote: quoted);
  }

  /// Whether [item]'s list is inside a blockquote.
  bool _isQuoted(_ItemCtx item) {
    final at = _stack.indexOf(item);
    return at > 0 && _stack.take(at).any((c) => c is _QuoteCtx);
  }

  void _emitItem(_ItemCtx item, List<InlineRun> runs) {
    if (!item.emitted) {
      var checked = item.checked;
      var content = runs;
      if (checked == null) {
        final stripped = TaskGlyphs.strip(runs);
        if (stripped != null) {
          checked = stripped.$1;
          content = stripped.$2;
        }
      }
      _blocks.add(_itemBlock(item, checked, content));
      item
        ..emitted = true
        ..emittedChecked = checked
        ..blockIndex = _blocks.length - 1;
      return;
    }
    final last = _blocks.lastOrNull;
    if (item.blockIndex == _blocks.length - 1 && last != null) {
      _warnings.add(
        ImportWarningKind.multiParagraphItem,
        'List items with several paragraphs were joined with line breaks.',
        blockIndex: _blocks.length - 1,
      );
      final previous = switch (last) {
        ListItemBlock(runs: final r) => r,
        TaskBlock(runs: final r) => r,
        _ => const <InlineRun>[],
      };
      _blocks[_blocks.length - 1] = _itemBlock(
        item,
        item.emittedChecked,
        InlineRun.merge([
          ...previous,
          const InlineRun(importSoftBreak),
          ...runs,
        ]),
      );
      return;
    }
    if (last is! ImageBlock) {
      _warnings.add(
        ImportWarningKind.multiParagraphItem,
        'List items with several paragraphs were joined with line breaks.',
        blockIndex: _blocks.length,
      );
    }
    _blocks.add(_itemBlock(item, item.emittedChecked, runs));
    item.blockIndex = _blocks.length - 1;
  }
}
