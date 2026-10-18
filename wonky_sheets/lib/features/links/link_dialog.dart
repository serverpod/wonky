import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';

/// A place inside the spreadsheet a link can point to (03 §14.4).
@immutable
class LinkTarget {
  const LinkTarget({required this.url, required this.label, this.detail});

  /// The internal link (`#sheet=<id>`, `#range=<name>`,
  /// `#sheet=<id>&range=A1:B2`).
  final String url;

  /// What the link field shows ("Sheet2", "Budget").
  final String label;

  /// Secondary text (the named range's address, "Range").
  final String? detail;

  @override
  bool operator ==(Object other) => other is LinkTarget && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

/// Internal link targets of [model] matching [query]: sheets, named ranges
/// and — when [query] is a range (`B2:C9`, `Sheet2!A1`) — that range.
List<LinkTarget> linkTargets(
  WorkbookModel model,
  String query, {
  required String activeSheetId,
  int limit = 8,
}) {
  final q = query.trim().toLowerCase();
  final out = <LinkTarget>[];
  if (q.isNotEmpty && !q.contains('://') && !q.startsWith('#')) {
    try {
      final r = model.parseA1(query.trim(), contextSheetId: activeSheetId);
      final sheet = model.sheet(r.sheetId);
      final isName = model.namedRange(query.trim()) != null;
      if (sheet != null && !isName) {
        final a1 = r.rect.a1;
        out.add(
          LinkTarget(
            url: '#sheet=${sheet.id}&range=$a1',
            label: '${sheet.name}!$a1',
          ),
        );
      }
    } on Object {
      // Not a range.
    }
  }
  for (final s in model.visibleSheets) {
    if (q.isEmpty || s.name.toLowerCase().contains(q)) {
      out.add(LinkTarget(url: '#sheet=${s.id}', label: s.name));
    }
  }
  final names = model.namedRanges.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  for (final n in names) {
    if (n.rangeJson == null) continue;
    if (q.isNotEmpty && !n.name.toLowerCase().contains(q)) continue;
    String? where;
    final g = GridRange.tryParse(n.rangeJson);
    final r = g == null ? null : model.resolve(g);
    final sheet = r == null ? null : model.sheet(r.sheetId);
    if (r != null && sheet != null) where = '${sheet.name}!${r.rect.a1}';
    out.add(
      LinkTarget(
        url: '#range=${Uri.encodeQueryComponent(n.name)}',
        label: n.name,
        detail: where,
      ),
    );
  }
  return out.take(limit).toList();
}

/// The label of an internal [url] (sheet name, named range, `Sheet!A1`), or
/// null for external links and unknown targets.
String? linkTargetLabel(WorkbookModel model, String url) {
  if (!url.startsWith('#')) return null;
  final p = Uri.splitQueryString(url.substring(1));
  final sheet = model.sheet(p['sheet'] ?? p['gid'] ?? '');
  final range = p['range'];
  if (sheet == null) return range;
  return range == null ? sheet.name : '${sheet.name}!$range';
}

/// Insert/edit link (03 §14.4, Mod+K): *Text* and *Link*; typing in *Link*
/// searches the spreadsheet's sheets and named ranges (and offers a typed
/// range) for an internal link. MCP-describable like a `WonkyDialogSpec`
/// (`dialog.link`, fields `text`/`url`, buttons `cancel`/`ok`). Returns
/// `(text, url)` or null.
Future<(String, String)?> showLinkEditorDialog(
  BuildContext context, {
  required WorkbookModel model,
  required String activeSheetId,
  String text = '',
  String url = '',
}) => showShadDialog<(String, String)>(
  context: context,
  builder: (_) => LinkEditorDialog(
    model: model,
    activeSheetId: activeSheetId,
    text: text,
    url: url,
  ),
);

class LinkEditorDialog extends StatefulWidget {
  const LinkEditorDialog({
    super.key,
    required this.model,
    required this.activeSheetId,
    this.text = '',
    this.url = '',
  });

  final WorkbookModel model;
  final String activeSheetId;
  final String text;
  final String url;

  @override
  State<LinkEditorDialog> createState() => _LinkEditorDialogState();
}

class _LinkEditorDialogState extends State<LinkEditorDialog>
    implements McpDescribableDialog {
  static const _key = 'dialog.link';
  late final TextEditingController _text = TextEditingController(
    text: widget.text,
  );
  late final TextEditingController _link;
  final FocusNode _linkFocus = FocusNode();

  /// The chosen internal target (the link field shows its label).
  LinkTarget? _picked;
  int _highlight = 0;
  ShellServices? _registeredIn;

  @override
  void initState() {
    super.initState();
    final label = linkTargetLabel(widget.model, widget.url);
    if (label != null) {
      _picked = LinkTarget(url: widget.url, label: label);
    }
    _link = TextEditingController(text: label ?? widget.url);
    _link.addListener(_onLink);
  }

  void _onLink() {
    final p = _picked;
    if (p != null && _link.text != p.label) _picked = null;
    setState(() => _highlight = 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = ShellScope.maybeOf(context);
    _registeredIn = s;
    if (s != null && !s.openDialogs.contains(this)) s.openDialogs.add(this);
  }

  @override
  void dispose() {
    _registeredIn?.openDialogs.remove(this);
    _text.dispose();
    _link.dispose();
    _linkFocus.dispose();
    super.dispose();
  }

  List<LinkTarget> get _matches => _picked != null
      ? const []
      : linkTargets(
          widget.model,
          _link.text,
          activeSheetId: widget.activeSheetId,
        );

  void _pick(LinkTarget t) {
    setState(() {
      _picked = t;
      _link.text = t.label;
      _link.selection = TextSelection.collapsed(offset: t.label.length);
      _picked = t;
    });
  }

  void _ok() {
    final url = _picked?.url ?? _link.text.trim();
    Navigator.of(context).pop((_text.text, url));
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Map<String, Object?> describe() => {
    'title': sheetsL10n(context).dialogLinkTitle,
    'fields': [
      {'id': 'text', 'label': 'Text', 'type': 'text', 'value': _text.text},
      {
        'id': 'url',
        'label': 'Link',
        'type': 'text',
        'value': _picked?.url ?? _link.text,
      },
    ],
    'suggestions': [
      for (final t in _matches) {'url': t.url, 'label': t.label},
    ],
    'buttons': [
      {'id': 'cancel', 'label': 'Cancel'},
      {'id': 'ok', 'label': 'Apply'},
    ],
  };

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'text':
        _text.text = '${value ?? ''}';
      case 'url':
        final v = '${value ?? ''}';
        final label = linkTargetLabel(widget.model, v);
        if (label != null) {
          _pick(LinkTarget(url: v, label: label));
        } else {
          _link.text = v;
        }
      default:
        return false;
    }
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'ok':
        _ok();
      case 'cancel':
        _cancel();
      default:
        return false;
    }
    return true;
  }

  KeyEventResult _onLinkKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final m = _matches;
    if (m.isEmpty) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlight = (_highlight + 1) % m.length);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlight = (_highlight - 1 + m.length) % m.length);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter && _link.text.isNotEmpty) {
      // Enter takes the highlighted target unless the text is a URL.
      final t = _link.text.trim();
      if (!t.contains('.') && !t.contains(':') && !t.contains('@')) {
        _pick(m[_highlight.clamp(0, m.length - 1)]);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final matches = _matches;
    final picked = _picked;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
      child: ShadDialog(
        key: const ValueKey<String>(_key),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.dialogLinkTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('$_key.cancel'),
            onPressed: _cancel,
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('$_key.ok'),
            onPressed: _ok,
            child: Text(l.dialogApply),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.dialogLinkText, style: theme.textTheme.small),
                const SizedBox(height: 6),
                ShadInput(
                  key: const ValueKey<String>('$_key.text'),
                  controller: _text,
                  onSubmitted: (_) => _linkFocus.requestFocus(),
                ),
                const SizedBox(height: 14),
                Text(l.dialogLinkUrl, style: theme.textTheme.small),
                const SizedBox(height: 6),
                Focus(
                  onKeyEvent: _onLinkKey,
                  skipTraversal: true,
                  child: ShadInput(
                    key: const ValueKey<String>('$_key.url'),
                    controller: _link,
                    focusNode: _linkFocus,
                    autofocus: true,
                    placeholder: Text(l.linkSearchPlaceholder),
                    leading: Icon(
                      picked == null ? LucideIcons.link : LucideIcons.sheet,
                      size: 15,
                      color: cs.mutedForeground,
                    ),
                    onSubmitted: (_) => _ok(),
                  ),
                ),
                if (picked != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l.linkInternalHint,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                ],
                if (matches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l.linkSearchHeading,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  for (final (i, t) in matches.indexed)
                    _Suggestion(
                      key: ValueKey<String>('$_key.suggestion.$i'),
                      target: t,
                      selected: i == _highlight,
                      onTap: () => _pick(t),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({
    super.key,
    required this.target,
    required this.selected,
    required this.onTap,
  });

  final LinkTarget target;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final isName = target.url.startsWith('#range=');
    return Semantics(
      button: true,
      selected: selected,
      label: target.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? cs.accent : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  isName ? LucideIcons.tag : LucideIcons.sheet,
                  size: 15,
                  color: cs.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    target.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small,
                  ),
                ),
                if (target.detail != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      target.detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.muted.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
