/// `package:markdown` inline AST → [InlineRun]s.
library;

import 'package:markdown/markdown.dart' as md;

import '../delta_utils.dart';
import '../links.dart';
import '../import_warning.dart';
import '../inline_run.dart';
import 'md_syntax.dart';
import 'wonky_syntax.dart';

/// Title prefix that marks a mailto link as a mention:
/// `[@Anna](mailto:anna@x.com "wonky-mention:<userUuid>")`.
const mentionTitlePrefix = 'wonky-mention:';

/// A piece of inline content: a text run or an image found inline.
sealed class InlinePiece {
  const InlinePiece();
}

/// A text run piece.
final class RunPiece extends InlinePiece {
  /// Creates a run piece.
  const RunPiece(this.run);

  /// The run.
  final InlineRun run;
}

/// An inline image piece (split out into an image block by the importer).
final class ImagePiece extends InlinePiece {
  /// Creates an image piece.
  const ImagePiece(this.src, this.alt, this.title, {this.insideLink = false});

  /// Source as written (not yet resolved/validated).
  final String src;

  /// Alt text.
  final String alt;

  /// Title.
  final String? title;

  /// Whether the image was wrapped in a link (the link is dropped).
  final bool insideLink;
}

/// Converts inline AST nodes into pieces, tracking warnings.
final class InlineReader {
  /// Creates a reader that appends to [warnings].
  InlineReader(this.warnings);

  /// Collected warnings (shared with the block importer).
  final List<ImportWarning> warnings;

  final _pieces = <InlinePiece>[];
  var _bold = 0;
  var _italic = 0;
  var _strike = 0;
  var _code = 0;
  String? _link;
  String? _mention;
  String? _linkStyle;
  var _chip = false;
  String? _chipIcon;
  var _warnedHtml = false;
  var _warnedLink = false;

  static final _tag = RegExp(
    r'<(/?)([A-Za-z][A-Za-z0-9-]*)\b[^>]*?(/?)>|<!--[\s\S]*?-->|<\?[\s\S]*?\?>|<![A-Za-z][^>]*>|<!\[CDATA\[[\s\S]*?\]\]>',
  );

  /// Reads [nodes] and returns the pieces (adjacent equal runs merged).
  List<InlinePiece> read(List<md.Node> nodes) {
    _pieces.clear();
    for (final n in nodes) {
      _visit(n);
    }
    return _merged();
  }

  /// Reads [nodes] into runs only; images become their alt text.
  List<InlineRun> readRuns(List<md.Node> nodes) {
    final pieces = read(nodes);
    final runs = <InlineRun>[];
    for (final p in pieces) {
      switch (p) {
        case RunPiece(:final run):
          runs.add(run);
        case ImagePiece(:final alt):
          if (alt.isNotEmpty) runs.add(InlineRun(alt));
          warnings.add(
            const ImportWarning(
              ImportWarningKind.imageFlattened,
              'Image converted to text',
            ),
          );
      }
    }
    return InlineRun.merge(runs);
  }

  List<InlinePiece> _merged() {
    final out = <InlinePiece>[];
    for (final p in _pieces) {
      if (p is RunPiece && out.isNotEmpty && out.last is RunPiece) {
        final last = (out.last as RunPiece).run;
        if (last.sameFormat(p.run)) {
          out[out.length - 1] = RunPiece(
            last.copyWith(text: last.text + p.run.text),
          );
          continue;
        }
      }
      if (p is RunPiece && p.run.text.isEmpty) continue;
      out.add(p);
    }
    return out;
  }

  void _emit(String text) {
    if (text.isEmpty) return;
    final code = _code > 0;
    if (_chip) {
      _pieces.add(RunPiece(InlineRun(text, chip: true, chipIcon: _chipIcon)));
      return;
    }
    final styled = _linkStyle != null && _link != null;
    _pieces.add(
      RunPiece(
        InlineRun(
          text,
          bold: _bold > 0 && !code && !styled,
          italic: _italic > 0 && !code && !styled,
          strike: _strike > 0 && !code && !styled,
          code: code && !styled,
          link: _link,
          mentionUserUuid: _link != null && !styled ? _mention : null,
          linkStyle: styled ? _linkStyle : null,
        ),
      ),
    );
  }

  void _visit(md.Node node) {
    if (node is md.Text) {
      _text(node.text);
      return;
    }
    if (node is! md.Element) {
      _text(node.textContent);
      return;
    }
    switch (node.tag) {
      case 'strong':
        _bold++;
        _children(node);
        _bold--;
      case 'em':
        _italic++;
        _children(node);
        _italic--;
      case 'del':
        _strike++;
        _children(node);
        _strike--;
      case 'code':
        _code++;
        final text = decodeMdEntities(node.textContent).replaceAll('\n', ' ');
        _emit(text);
        _code--;
      case 'br':
        _emit(softBreak);
      case 'a':
        _anchor(node);
      case 'img':
        _pieces.add(
          ImagePiece(
            node.attributes['src'] ?? '',
            decodeMdEntities(node.attributes['alt'] ?? ''),
            node.attributes['title'] == null
                ? null
                : decodeMdEntities(node.attributes['title']!),
            insideLink: _link != null,
          ),
        );
      case 'input':
        // Task checkbox; handled by the block importer.
        break;
      case WonkyMdTags.button || WonkyMdTags.arrowLink:
        _styledLink(node);
      case WonkyMdTags.chip:
        final prevChip = _chip;
        final prevIcon = _chipIcon;
        _chip = true;
        final icon = node.attributes[WonkyMdTags.icon];
        _chipIcon = icon != null && _iconName.hasMatch(icon) ? icon : null;
        _children(node);
        _chip = prevChip;
        _chipIcon = prevIcon;
      default:
        _children(node);
    }
  }

  void _children(md.Element e) {
    for (final c in e.children ?? const <md.Node>[]) {
      _visit(c);
    }
  }

  static final _iconName = RegExp(r'^[a-z0-9-]{1,32}$');

  /// `:button[…](…)` / `:link[…](…)` (Write 11 §4): a link with a
  /// `linkStyle`; an unsupported URL keeps the label as text.
  void _styledLink(md.Element node) {
    final href = node.attributes[WonkyMdTags.href] ?? '';
    final normalized = LinkPolicy.normalizeLink(href);
    if (normalized == null) {
      if (!_warnedLink) {
        warnings.add(
          ImportWarning(
            ImportWarningKind.unsupportedLink,
            'Link "$href" is not supported; text kept',
          ),
        );
        _warnedLink = true;
      }
      _children(node);
      return;
    }
    final prevLink = _link;
    final prevMention = _mention;
    final prevStyle = _linkStyle;
    _link = normalized;
    _mention = null;
    _linkStyle = node.tag == WonkyMdTags.arrowLink
        ? 'arrow'
        : node.attributes[WonkyMdTags.variant] == 'secondary'
        ? 'buttonSecondary'
        : 'button';
    _children(node);
    _link = prevLink;
    _mention = prevMention;
    _linkStyle = prevStyle;
  }

  void _anchor(md.Element node) {
    final href = decodeMdEntities(node.attributes['href'] ?? '');
    final title = node.attributes['title'] == null
        ? null
        : decodeMdEntities(node.attributes['title']!);
    final normalized = LinkPolicy.normalizeLink(href);
    if (normalized == null) {
      if (!_warnedLink) {
        warnings.add(
          ImportWarning(
            ImportWarningKind.unsupportedLink,
            'Link "$href" is not supported; text kept',
          ),
        );
        _warnedLink = true;
      }
      _children(node);
      return;
    }
    final prevLink = _link;
    final prevMention = _mention;
    _link = normalized;
    _mention = null;
    if (title != null &&
        title.startsWith(mentionTitlePrefix) &&
        LinkPolicy.isMailto(normalized)) {
      final uuid = title.substring(mentionTitlePrefix.length);
      if (uuid.isNotEmpty) _mention = uuid;
    }
    _children(node);
    _link = prevLink;
    _mention = prevMention;
  }

  /// Handles a text node: raw inline HTML tags (kept raw because the AST is
  /// produced with `encodeHtml: true`) and HTML entities.
  void _text(String raw) {
    var last = 0;
    for (final m in _tag.allMatches(raw)) {
      if (m.start > last) _plain(raw.substring(last, m.start));
      last = m.end;
      final name = m.group(2)?.toLowerCase();
      if (name == null) continue; // comment, PI, declaration, CDATA
      final closing = m.group(1) == '/';
      switch (name) {
        case 'br':
          _emit(softBreak);
        case 'strong' || 'b':
          closing ? _bold = (_bold - 1).clamp(0, 99) : _bold++;
        case 'em' || 'i':
          closing ? _italic = (_italic - 1).clamp(0, 99) : _italic++;
        case 'del' || 's' || 'strike':
          closing ? _strike = (_strike - 1).clamp(0, 99) : _strike++;
        default:
          if (!_warnedHtml) {
            warnings.add(
              const ImportWarning(
                ImportWarningKind.htmlStripped,
                'Inline HTML stripped to text',
              ),
            );
            _warnedHtml = true;
          }
      }
    }
    if (last < raw.length) _plain(raw.substring(last));
  }

  void _plain(String encoded) {
    // Soft line breaks inside a paragraph render as spaces.
    final text = decodeMdEntities(encoded.replaceAll('\n', ' '));
    _emit(text);
  }
}
