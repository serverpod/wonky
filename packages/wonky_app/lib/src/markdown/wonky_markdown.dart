import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyTheme;

import '../l10n/wonky_app_localizations.dart';
import '../shell/dialogs.dart';
import '../shell/shell_scope.dart';
import 'markdown_blocks.dart';
import 'markdown_inline.dart';

/// What a [WonkyMarkdown] renders (specs/16 §7.3). Blocks a profile does not
/// allow render as their source text; inline styles, links and fenced code
/// are allowed everywhere.
enum MarkdownProfile {
  /// Board post bodies: headings (at most at h3 size), lists, fenced code,
  /// quotes, rules, tables, links and inline styles. Line breaks are kept.
  post(
    headings: true,
    quotes: true,
    tables: true,
    rules: true,
    openLinks: true,
    hardBreaks: true,
    codeCopyKey: 'markdown.code.copy',
  ),

  /// Comments (documents and the board): inline styles, links, lists and
  /// fenced code. Line breaks are kept.
  comment(
    headings: false,
    quotes: false,
    tables: false,
    rules: false,
    openLinks: true,
    hardBreaks: true,
  ),

  /// Assistant replies (streamed): every block, tables as aligned text,
  /// soft line breaks, links styled but not opened.
  assistant(
    headings: true,
    quotes: true,
    tables: true,
    rules: true,
    openLinks: false,
    hardBreaks: false,
    codeCopyKey: 'assistant.code.copy',
  );

  const MarkdownProfile({
    required this.headings,
    required this.quotes,
    required this.tables,
    required this.rules,
    required this.openLinks,
    required this.hardBreaks,
    this.codeCopyKey,
  });

  final bool headings;
  final bool quotes;
  final bool tables;
  final bool rules;

  /// Whether links (http(s) and mailto only) open through the shell's
  /// external-link confirmation.
  final bool openLinks;

  /// Whether the lines of a paragraph stay separate lines.
  final bool hardBreaks;

  /// The key of the copy button of code blocks; null = no copy button.
  final String? codeCopyKey;

  bool allows(MdKind kind) => switch (kind) {
    MdKind.heading => headings,
    MdKind.quote => quotes,
    MdKind.table => tables,
    MdKind.rule => rules,
    MdKind.paragraph || MdKind.listItem || MdKind.code => true,
  };
}

/// The suite's Markdown renderer (specs/16 §7.3): headings, paragraphs,
/// lists, quotes, fenced code, rules, tables and inline bold / italic /
/// strike / code / links, restricted by [profile]. Partial (streamed) input
/// renders. Links open through [confirmExternalLink] and only for http(s)
/// and mailto; other schemes, images and raw HTML render as text.
class WonkyMarkdown extends StatefulWidget {
  const WonkyMarkdown(
    this.text, {
    super.key,
    this.profile = MarkdownProfile.post,
    this.style,
    this.onOpenLink,
    this.onCopyCode,
  });

  final String text;
  final MarkdownProfile profile;

  /// The body text style (defaults to the theme's small text, regular).
  final TextStyle? style;

  /// Opens a link (an http(s) or mailto URL). Defaults to the shell's
  /// external-link confirmation; ignored when the profile does not open
  /// links.
  final void Function(String url)? onOpenLink;

  /// Copies a code block (defaults to the clipboard).
  final void Function(String code)? onCopyCode;

  /// Inline Markdown as spans (links styled, not tappable).
  static TextSpan inlineSpans(
    String text,
    TextStyle base,
    ShadColorScheme cs,
  ) => MarkdownInline.spans(text, base, cs);

  @override
  State<WonkyMarkdown> createState() => _WonkyMarkdownState();
}

class _WonkyMarkdownState extends State<WonkyMarkdown> {
  final List<TapGestureRecognizer> _recognizers = [];

  // The parsed blocks of the last text (parsing is skipped while the text
  // is unchanged, e.g. when a streamed reply rebuilds its neighbours).
  List<MdBlock> _blocks = const [];
  String? _parsedText;
  bool? _parsedHardBreaks;

  List<MdBlock> _parse() {
    final hard = widget.profile.hardBreaks;
    if (_parsedText != widget.text || _parsedHardBreaks != hard) {
      _blocks = MarkdownBlocks.parse(widget.text, hardBreaks: hard);
      _parsedText = widget.text;
      _parsedHardBreaks = hard;
    }
    return _blocks;
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  GestureRecognizer? _recognizer(String url) {
    if (!widget.profile.openLinks) return null;
    final r = TapGestureRecognizer()..onTap = () => _open(url);
    _recognizers.add(r);
    return r;
  }

  void _open(String url) {
    final open = widget.onOpenLink;
    if (open != null) {
      open(url);
      return;
    }
    final s = ShellScope.maybeOf(context);
    if (s == null) return;
    confirmExternalLink(context, s, url: url);
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final p = widget.profile;
    final blocks = _parse();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // The assistant's layout predates the profiles (it fills its slot).
      mainAxisSize: p == MarkdownProfile.assistant
          ? MainAxisSize.max
          : MainAxisSize.min,
      spacing: 6,
      children: [for (final b in blocks) _block(context, b)],
    );
  }

  TextSpan _spans(String text, TextStyle base, ShadColorScheme cs) =>
      MarkdownInline.spans(text, base, cs, link: _recognizer);

  Widget _block(BuildContext context, MdBlock b) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final base =
        widget.style ??
        theme.textTheme.small.copyWith(
          fontWeight: FontWeight.w400,
          height: 1.45,
        );
    final p = widget.profile;
    if (!p.allows(b.kind)) {
      return Text.rich(_spans(b.source.trim(), base, cs));
    }
    switch (b.kind) {
      case MdKind.heading:
        final size = p == MarkdownProfile.assistant
            ? switch (b.level) {
                1 => 17.0,
                2 => 15.5,
                _ => 14.0,
              }
            // Posts: headings at most at h3 size (16 §7.3).
            : (b.level <= 3 ? 15.5 : 14.0);
        return Semantics(
          header: true,
          child: Text.rich(
            _spans(
              b.text,
              base.copyWith(fontSize: size, fontWeight: FontWeight.w600),
              cs,
            ),
          ),
        );
      case MdKind.paragraph:
        return Text.rich(_spans(b.text, base, cs));
      case MdKind.listItem:
        return Padding(
          padding: EdgeInsets.only(left: 4.0 + 14.0 * b.level),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: b.marker.length > 2 ? 26 : 16,
                child: Text(
                  b.marker,
                  style: base.copyWith(color: cs.mutedForeground),
                ),
              ),
              Expanded(child: Text.rich(_spans(b.text, base, cs))),
            ],
          ),
        );
      case MdKind.quote:
        return Container(
          padding: const EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: cs.border, width: 3)),
          ),
          child: Text.rich(
            _spans(b.text, base.copyWith(color: cs.mutedForeground), cs),
          ),
        );
      case MdKind.table when p != MarkdownProfile.assistant:
        return _table(b, base, cs);
      case MdKind.code:
      case MdKind.table:
        final mono = base.copyWith(
          fontFamily: WonkyTheme.monoFamily,
          fontSize: 12,
        );
        final copyKey = b.kind == MdKind.code ? p.codeCopyKey : null;
        return Container(
          decoration: BoxDecoration(
            color: cs.muted,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.fromLTRB(
                  10,
                  8,
                  copyKey == null ? 10 : 34,
                  8,
                ),
                child: Text(b.text, style: mono),
              ),
              if (copyKey != null)
                Positioned(
                  top: 2,
                  right: 2,
                  child: ShadIconButton.ghost(
                    key: ValueKey<String>(copyKey),
                    width: 26,
                    height: 26,
                    iconSize: 13,
                    semanticLabel:
                        Localizations.of<WonkyAppLocalizations>(
                          context,
                          WonkyAppLocalizations,
                        )?.assistantCopyCode ??
                        'Copy code',
                    icon: const Icon(LucideIcons.copy),
                    onPressed: () {
                      final copy = widget.onCopyCode;
                      if (copy != null) {
                        copy(b.text);
                      } else {
                        Clipboard.setData(ClipboardData(text: b.text));
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      case MdKind.rule:
        return Container(height: 1, color: cs.border);
    }
  }

  Widget _table(MdBlock b, TextStyle base, ShadColorScheme cs) {
    final rows = b.rows;
    if (rows.isEmpty) return const SizedBox.shrink();
    final columns = rows.map((r) => r.length).reduce((a, c) => a > c ? a : c);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(
          color: cs.border,
          borderRadius: BorderRadius.circular(6),
        ),
        children: [
          for (var r = 0; r < rows.length; r++)
            TableRow(
              decoration: r == 0 ? BoxDecoration(color: cs.muted) : null,
              children: [
                for (var c = 0; c < columns; c++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text.rich(
                      _spans(
                        c < rows[r].length ? rows[r][c] : '',
                        r == 0
                            ? base.copyWith(fontWeight: FontWeight.w600)
                            : base,
                        cs,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
