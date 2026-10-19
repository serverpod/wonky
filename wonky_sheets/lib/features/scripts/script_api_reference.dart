import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';

/// *Help › Script API reference* (09 §14.4): the Wonky Script API rendered
/// from the same `api_index.json` as autocomplete — a searchable class
/// list and the selected class's members with signatures and docs. Narrow
/// widths stack the list above the details. MCP-operable (`search`,
/// `class`, `close`).
Future<void> showScriptApiReference(BuildContext context, {String? initial}) =>
    showShadDialog<void>(
      context: context,
      builder: (_) => _ApiReferenceDialog(initial: initial),
    );

class _ApiReferenceDialog extends StatefulWidget {
  const _ApiReferenceDialog({this.initial});

  final String? initial;

  @override
  State<_ApiReferenceDialog> createState() => _ApiReferenceDialogState();
}

class _ApiReferenceDialogState extends State<_ApiReferenceDialog>
    implements McpDescribableDialog {
  final _search = TextEditingController();
  final _details = ScrollController();
  ShellServices? _registeredIn;
  late String _selected;

  ApiIndex get _index => ApiIndex.standard;

  @override
  void initState() {
    super.initState();
    final first =
        _index.classNamed('SpreadsheetApp')?.name ?? _index.classes.first.name;
    _selected = _index.classNamed(widget.initial ?? '')?.name ?? first;
    _search.addListener(() => setState(() {}));
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
    _search.dispose();
    _details.dispose();
    super.dispose();
  }

  /// Classes matching the search (by class or member name).
  List<ApiClass> get _visible {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _index.classes;
    return [
      for (final c in _index.classes)
        if (c.name.toLowerCase().contains(q) ||
            c.members.any((m) => m.name.toLowerCase().contains(q)))
          c,
    ];
  }

  void _select(String name) {
    setState(() => _selected = name);
    if (_details.hasClients) _details.jumpTo(0);
  }

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': l.scriptApiReferenceTitle,
      'fields': [
        {
          'id': 'search',
          'label': l.scriptApiSearch,
          'type': 'text',
          'value': _search.text,
        },
        {
          'id': 'class',
          'label': l.scriptApiClass,
          'type': 'select',
          'value': _selected,
          'options': {for (final c in _visible) c.name: c.name},
        },
      ],
      'content': _classText(_index.classNamed(_selected)!),
      'buttons': [
        {'id': 'close', 'label': WonkyAppLocalizations.of(context).actionClose},
      ],
    };
  }

  String _classText(ApiClass c) => [
    'class ${c.name}${c.superclass == null ? '' : ' extends ${c.superclass}'}',
    if (c.doc.isNotEmpty) c.doc,
    for (final m in c.members)
      '${m.signature(c.name)}${m.summary.isEmpty ? '' : ' — ${m.summary}'}',
  ].join('\n');

  @override
  bool setField(String id, Object? value) {
    switch (id) {
      case 'search':
        _search.text = '${value ?? ''}';
        return true;
      case 'class':
        final c = _index.classNamed('$value');
        if (c == null) return false;
        _select(c.name);
        return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    if (buttonId != 'close' && buttonId != 'cancel') return false;
    Navigator.of(context).pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 96).clamp(240.0, 960.0);
    final height = (size.height * 0.7).clamp(300.0, 720.0);
    final narrow = width < 600;
    final list = _list(context);
    final details = _detailsView(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => press('close'),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.scriptApiReference'),
        closeIcon: const WonkyDialogCloseButton(),
        constraints: BoxConstraints(maxWidth: width + 48),
        title: Text(l.scriptApiReferenceTitle),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.scriptApiReference.close'),
            onPressed: () => press('close'),
            child: Text(WonkyAppLocalizations.of(context).actionClose),
          ),
        ],
        child: SizedBox(
          width: width,
          height: height,
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: height * 0.35, child: list),
                    const SizedBox(height: 8),
                    Expanded(child: details),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 230, child: list),
                    const SizedBox(width: 12),
                    Expanded(child: details),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final visible = _visible;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadInput(
          key: const ValueKey<String>('script.api.search'),
          controller: _search,
          placeholder: Text(l.scriptApiSearch),
          leading: const Icon(LucideIcons.search, size: 14),
          autofocus: true,
          onSubmitted: (_) {
            if (visible.isNotEmpty) _select(visible.first.name);
          },
        ),
        const SizedBox(height: 6),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    l.scriptApiNoMatches,
                    style: theme.textTheme.muted,
                  ),
                )
              : ListView(
                  key: const ValueKey<String>('script.api.classes'),
                  children: [
                    for (final c in visible)
                      GestureDetector(
                        key: ValueKey<String>('script.api.class.${c.name}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _select(c.name),
                        child: Container(
                          color: c.name == _selected ? cs.accent : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Text(
                            c.name,
                            style: theme.textTheme.small.copyWith(
                              fontFamily: WonkyTheme.monoFamily,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _detailsView(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final c = _index.classNamed(_selected)!;
    final q = _search.text.trim().toLowerCase();
    final mono = TextStyle(
      fontFamily: WonkyTheme.monoFamily,
      fontSize: 12.5,
      color: cs.foreground,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: cs.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListView(
        key: const ValueKey<String>('script.api.details'),
        controller: _details,
        padding: const EdgeInsets.all(12),
        children: [
          SelectableText(
            'class ${c.name}'
            '${c.superclass == null ? '' : ' extends ${c.superclass}'}',
            style: mono.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (c.doc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(c.doc, style: theme.textTheme.small),
          ],
          const SizedBox(height: 10),
          for (final m in c.members)
            Container(
              key: ValueKey<String>('script.api.member.${c.name}.${m.name}'),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: q.isNotEmpty && m.name.toLowerCase().contains(q)
                    ? cs.accent
                    : cs.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(m.signature(c.name), style: mono),
                  if (m.doc.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(m.doc, style: theme.textTheme.muted),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
