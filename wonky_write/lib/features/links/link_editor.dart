import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show DriveItemKind, DriveItemView, DriveSearchFilters;
import 'package:wonky_write_core/wonky_write_core.dart' show OutlineEntry;

import '../../l10n/write_l10n.dart';
import '../editor/model/link_url_policy.dart';

/// What the link editor returns.
sealed class LinkEdit {
  const LinkEdit();
}

/// Apply [url] (and replace the text with [text] when given).
class ApplyLink extends LinkEdit {
  const ApplyLink(this.url, {this.text});
  final String url;
  final String? text;
}

/// Remove the link.
class RemoveLink extends LinkEdit {
  const RemoveLink();
}

/// A link suggestion row.
class _Suggestion {
  const _Suggestion(this.url, this.title, this.subtitle, this.icon);
  final String url;
  final String title;
  final String subtitle;
  final IconData icon;
}

/// The link editor popover (`LinkEditorPopover`, Write 05 §9.1, 04 §11.2):
/// text + link fields, suggestions (headings in this document, documents
/// from the drive), inline validation, Apply / Remove.
class LinkEditor extends StatefulWidget {
  const LinkEditor({
    super.key,
    required this.policy,
    required this.headings,
    this.initialUrl,
    this.initialText,
    this.showText = true,
    this.searchDocuments,
  });

  final LinkUrlPolicy policy;
  final List<OutlineEntry> headings;
  final String? initialUrl;

  /// The selected text (editable when [showText]).
  final String? initialText;
  final bool showText;

  /// Drive search for documents.
  final Future<List<DriveItemView>> Function(String query)? searchDocuments;

  /// Searches Write documents through the shell's drive repository.
  static Future<List<DriveItemView>> Function(String) driveSearch(
    ShellServices s,
  ) => (query) async {
    final page = await s.drive.search(
      query,
      filters: DriveSearchFilters(kinds: const [DriveItemKind.document]),
      limit: 6,
    );
    return page.items;
  };

  @override
  State<LinkEditor> createState() => _LinkEditorState();
}

class _LinkEditorState extends State<LinkEditor> {
  late final _text = TextEditingController(text: widget.initialText ?? '');
  late final _url = TextEditingController(text: _display(widget.initialUrl));
  final _urlFocus = FocusNode();
  String? _error;
  List<DriveItemView> _docs = const [];
  int _highlight = -1;
  Timer? _debounce;
  int _request = 0;

  bool get _editing => widget.initialUrl != null;

  String _display(String? url) {
    if (url == null) return '';
    final prefix = 'wonky://doc/${widget.policy.documentUuid}#';
    if (widget.policy.documentUuid.isNotEmpty && url.startsWith(prefix)) {
      return '#${url.substring(prefix.length)}';
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    _url.addListener(_onUrl);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    _url.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  void _onUrl() {
    if (_error != null) setState(() => _error = null);
    _debounce?.cancel();
    final q = _url.text.trim();
    final search = widget.searchDocuments;
    if (search == null ||
        q.length < 2 ||
        q.contains('://') ||
        q.contains('.')) {
      // Drop a search still in flight, and rebuild anyway: the heading
      // suggestions and Apply follow the text.
      _request++;
      setState(() => _docs = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final request = ++_request;
      try {
        final docs = await search(q);
        if (mounted && request == _request) setState(() => _docs = docs);
      } catch (_) {
        // Offline: headings only.
      }
    });
    setState(() {});
  }

  List<_Suggestion> get _suggestions {
    final l = writeL10n(context);
    final q = _url.text.trim().toLowerCase();
    final query = q.startsWith('#') ? q.substring(1) : q;
    if (q.contains('://') || q.contains('@')) return const [];
    final headings = [
      for (final h in widget.headings)
        if (h.text.trim().isNotEmpty &&
            (query.isEmpty || h.text.toLowerCase().contains(query)))
          _Suggestion(
            '#${h.anchorId}',
            h.text,
            l.linkSuggestionHeading(h.level),
            LucideIcons.heading,
          ),
    ].take(6);
    return [
      ...headings,
      for (final d in _docs)
        _Suggestion(
          'wonky://doc/${d.uuid.uuid}',
          d.name,
          l.linkSuggestionDocument,
          LucideIcons.fileText,
        ),
    ];
  }

  void _apply([String? url]) {
    final raw = url ?? _url.text;
    final result = widget.policy.normalize(raw);
    switch (result) {
      case InvalidLinkUrl(:final reason):
        setState(() => _error = reason);
      case ValidLinkUrl(:final url):
        final text = widget.showText ? _text.text : null;
        Navigator.of(context).pop(
          ApplyLink(
            url,
            text: text != null && text != widget.initialText ? text : null,
          ),
        );
    }
  }

  KeyEventResult _keys(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final s = _suggestions;
    if (!_urlFocus.hasFocus || s.isEmpty) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlight = (_highlight + 1).clamp(0, s.length - 1));
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlight = (_highlight - 1).clamp(-1, s.length - 1));
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter && _highlight >= 0) {
      _apply(s[_highlight].url);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final suggestions = _suggestions;
    return Focus(
      onKeyEvent: _keys,
      child: Padding(
        key: const ValueKey<String>('write.popover.link'),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showText) ...[
              ExcludeSemantics(
                child: Text(l.linkText, style: theme.textTheme.small),
              ),
              const SizedBox(height: 4),
              Semantics(
                label: l.linkText,
                child: ShadInput(
                  key: const ValueKey<String>('write.popover.link.text'),
                  controller: _text,
                  placeholder: Text(l.linkTextPlaceholder),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            ExcludeSemantics(
              child: Text(l.linkUrl, style: theme.textTheme.small),
            ),
            const SizedBox(height: 4),
            Semantics(
              label: l.linkUrl,
              child: ShadInput(
                key: const ValueKey<String>('write.popover.link.url'),
                controller: _url,
                focusNode: _urlFocus,
                autofocus: true,
                placeholder: Text(l.linkUrlPlaceholder),
                leading: Icon(
                  LucideIcons.link,
                  size: 16,
                  color: cs.mutedForeground,
                ),
                onSubmitted: (_) => _highlight >= 0 && suggestions.isNotEmpty
                    ? _apply(suggestions[_highlight].url)
                    : _apply(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                key: const ValueKey<String>('write.popover.link.error'),
                style: theme.textTheme.small.copyWith(color: cs.destructive),
              ),
            ],
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < suggestions.length; i++)
                      _SuggestionRow(
                        suggestion: suggestions[i],
                        highlighted: i == _highlight,
                        onTap: () => _apply(suggestions[i].url),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (_editing)
                  ShadButton.ghost(
                    key: const ValueKey<String>('write.popover.link.remove'),
                    size: ShadButtonSize.sm,
                    leading: const Icon(LucideIcons.unlink, size: 14),
                    onPressed: () =>
                        Navigator.of(context).pop(const RemoveLink()),
                    child: Text(l.linkRemove),
                  ),
                const Spacer(),
                ShadButton.outline(
                  size: ShadButtonSize.sm,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.commonCancel),
                ),
                const SizedBox(width: 8),
                ListenableBuilder(
                  listenable: _url,
                  builder: (context, _) => ShadButton(
                    key: const ValueKey<String>('write.popover.link.apply'),
                    size: ShadButtonSize.sm,
                    enabled: _url.text.trim().isNotEmpty,
                    onPressed: () => _apply(),
                    child: Text(l.commonApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.suggestion,
    required this.highlighted,
    required this.onTap,
  });

  final _Suggestion suggestion;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: highlighted ? cs.accent : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(suggestion.icon, size: 16, color: cs.mutedForeground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                suggestion.subtitle,
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
