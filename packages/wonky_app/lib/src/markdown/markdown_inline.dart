import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyTheme;

/// Creates the tap recognizer of a link to [url] (already checked with
/// [MarkdownInline.safeUrl]); null renders links styled but inert.
typedef MarkdownLinkRecognizer = GestureRecognizer? Function(String url);

/// Inline Markdown → spans (specs/16 §7.3): bold, italic, strike, code,
/// links, autolinks and backslash escapes. Images render as links (to the
/// image), raw HTML as text, and links whose scheme is not http(s) or
/// mailto as their source text.
abstract final class MarkdownInline {
  // Emphasis and link text read backslash escapes as one unit (`\*`, `\]`),
  // so an escaped delimiter never closes a span (CQ-50: the composer writes
  // `*2 \**` for an italic "2 *").
  static const _unit = r'(?:\\[\s\S]|[^\\])';

  static final _inline = RegExp(
    // 1 escape
    r'\\([!-/:-@\[-`{-~])'
    // 2 ticks, 3 code
    r'|(`+)(?!`)([\s\S]+?)(?<!`)\2(?!`)'
    // entity (&amp;, &#96;, &#x20;)
    r'|(?<ent>&(?:#[0-9]{1,7}|#[xX][0-9a-fA-F]{1,6}|[A-Za-z][A-Za-z0-9]{1,31});)'
    // HTML comment (invisible; the composer separates code spans with
    // `<!-- -->`)
    r'|(?<cmt><!--[\s\S]*?-->)'
    // image ![alt](src)
    r'|!\[(?<alt>[^\]\n]*)\]\((?:\s*<(?<src1>[^>\n]+)>|\s*(?<src2>[^)\s]+))(?:\s+"[^"\n]*")?\s*\)'
    // link [label](href)
    r'|\[(?<label>(?:\[(?:\\[\s\S]|[^\]\n\\])*\]|\\[\s\S]|[^\]\n\\])+)\]\((?:\s*<(?<href1>[^>\n]+)>|\s*(?<href2>[^)\s]+))(?:\s+"[^"\n]*")?\s*\)'
    // autolink <https://…>
    r'|<(?<auto>(?:[A-Za-z][A-Za-z0-9+.\-]*):[^>\s]+)>'
    // bare http(s) URL
    r'|(?<bare>(?<![\w/])https?://[^\s<]*[^\s<.,:;"'
    "'"
    r')\]!?*_~])'
    // bold
    // (a closing `**` followed by another `*` closes an inner italic
    // first: `***x***`, `**a *b***`)
    '|\\*\\*(?=\\S)(?<b1>$_unit+?)(?<=\\S)\\*\\*(?!\\*)'
    '|(?<![A-Za-z0-9])__(?=\\S)(?<b2>$_unit+?)(?<=\\S)__(?![A-Za-z0-9_])'
    // strike
    '|~~(?=\\S)(?<s>$_unit+?)(?<=\\S)~~'
    // italic
    '|\\*(?=[^\\s*])(?<i1>$_unit*?(?:\\\\[\\s\\S]|[^\\s*\\\\]))\\*'
    '|(?<![A-Za-z0-9])_(?=[^\\s_])(?<i2>$_unit*?(?:\\\\[\\s\\S]|[^\\s_\\\\]))_(?![A-Za-z0-9])',
  );

  static const _namedEntities = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': '\u00a0',
  };

  /// The text of the entity [entity] (`&amp;`, `&#96;`, `&#x20;`), or the
  /// entity itself when it is unknown or invalid.
  static String _decodeEntity(String entity) {
    final body = entity.substring(1, entity.length - 1);
    if (!body.startsWith('#')) return _namedEntities[body] ?? entity;
    final hex = body.length > 1 && (body[1] == 'x' || body[1] == 'X');
    final code = int.tryParse(
      body.substring(hex ? 2 : 1),
      radix: hex ? 16 : 10,
    );
    if (code == null || code == 0 || code > 0x10ffff) return '\ufffd';
    if (code >= 0xd800 && code <= 0xdfff) return '\ufffd';
    return String.fromCharCode(code);
  }

  /// The URL of a link when it may be opened: http(s) with a host, or
  /// mailto. Null for every other scheme (`javascript:`, `data:`, `file:`,
  /// relative URLs …).
  static String? safeUrl(String raw) {
    final t = raw.trim();
    final uri = Uri.tryParse(t);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if ((scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty) {
      return t;
    }
    if (scheme == 'mailto' && uri.path.isNotEmpty) return t;
    return null;
  }

  /// [text] as a span in [base] (the root span carries [base]).
  static TextSpan spans(
    String text,
    TextStyle base,
    ShadColorScheme cs, {
    MarkdownLinkRecognizer? link,
  }) => TextSpan(
    style: base.copyWith(color: base.color ?? cs.foreground),
    children: _parse(text, base, cs, link),
  );

  static List<InlineSpan> _parse(
    String text,
    TextStyle base,
    ShadColorScheme cs,
    MarkdownLinkRecognizer? link,
  ) {
    final out = <InlineSpan>[];
    final plain = StringBuffer();
    void flush() {
      if (plain.isEmpty) return;
      out.add(TextSpan(text: plain.toString()));
      plain.clear();
    }

    var i = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > i) plain.write(text.substring(i, m.start));
      i = m.end;
      final escaped = m.group(1);
      if (escaped != null) {
        plain.write(escaped);
        continue;
      }
      final entity = m.namedGroup('ent');
      if (entity != null) {
        plain.write(_decodeEntity(entity));
        continue;
      }
      if (m.namedGroup('cmt') != null) continue;
      final code = m.group(3);
      if (code != null) {
        flush();
        var c = code;
        if (c.length > 2 && c.startsWith(' ') && c.endsWith(' ')) {
          c = c.substring(1, c.length - 1);
        }
        out.add(
          TextSpan(
            text: c,
            style: TextStyle(
              fontFamily: WonkyTheme.monoFamily,
              fontSize: (base.fontSize ?? 14) - 1,
              backgroundColor: cs.muted,
            ),
          ),
        );
        continue;
      }
      final src = m.namedGroup('src1') ?? m.namedGroup('src2');
      if (src != null) {
        // Images are not rendered: a link to the image (16 §7.3).
        final url = safeUrl(src);
        if (url == null) {
          plain.write(m.group(0));
          continue;
        }
        flush();
        final alt = m.namedGroup('alt')!.trim();
        out.add(
          _link(url, [TextSpan(text: alt.isEmpty ? url : alt)], cs, link),
        );
        continue;
      }
      final href = m.namedGroup('href1') ?? m.namedGroup('href2');
      if (href != null) {
        final url = safeUrl(href);
        if (url == null) {
          // Other schemes are shown as text, never as a link.
          plain.write(m.group(0));
          continue;
        }
        flush();
        out.add(
          _link(url, _parse(m.namedGroup('label')!, base, cs, null), cs, link),
        );
        continue;
      }
      final auto = m.namedGroup('auto') ?? m.namedGroup('bare');
      if (auto != null) {
        final url = safeUrl(auto);
        if (url == null) {
          plain.write(m.group(0));
          continue;
        }
        flush();
        out.add(_link(url, [TextSpan(text: auto)], cs, link));
        continue;
      }
      flush();
      final bold = m.namedGroup('b1') ?? m.namedGroup('b2');
      if (bold != null) {
        out.add(
          TextSpan(
            style: const TextStyle(fontWeight: FontWeight.w600),
            children: _parse(bold, base, cs, link),
          ),
        );
        continue;
      }
      final strike = m.namedGroup('s');
      if (strike != null) {
        out.add(
          TextSpan(
            style: const TextStyle(decoration: TextDecoration.lineThrough),
            children: _parse(strike, base, cs, link),
          ),
        );
        continue;
      }
      out.add(
        TextSpan(
          style: const TextStyle(fontStyle: FontStyle.italic),
          children: _parse(
            m.namedGroup('i1') ?? m.namedGroup('i2')!,
            base,
            cs,
            link,
          ),
        ),
      );
    }
    if (i < text.length) plain.write(text.substring(i));
    flush();
    return out;
  }

  /// A link: [children] styled as a link, every leaf carrying the
  /// recognizer (hit testing only finds leaf spans).
  static InlineSpan _link(
    String url,
    List<InlineSpan> children,
    ShadColorScheme cs,
    MarkdownLinkRecognizer? link,
  ) {
    final recognizer = link?.call(url);
    InlineSpan leaf(InlineSpan s) {
      if (s is! TextSpan) return s;
      return TextSpan(
        text: s.text,
        style: s.style,
        children: s.children?.map(leaf).toList(),
        recognizer: recognizer,
        mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
        semanticsLabel: s.semanticsLabel,
      );
    }

    return TextSpan(
      style: TextStyle(
        color: cs.primary,
        decoration: TextDecoration.underline,
        decorationColor: cs.primary,
      ),
      children: children.map(leaf).toList(),
      recognizer: recognizer,
      mouseCursor: recognizer == null ? null : SystemMouseCursors.click,
    );
  }
}
