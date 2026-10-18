import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../l10n/wonky_app_localizations.dart';
import '../shell/form_dialog.dart';
import '../shell/shell_services.dart';

/// Keyboard shortcuts help (`Mod+/`, suite 08 §1.2): categorized, searchable,
/// read-only. MCP-operable (`ui.get_dialog`: the `query` field, the listed
/// shortcuts and a `close` button; Slides 04 AC-9).
Future<void> showShortcutsHelp(BuildContext context, ShellServices s) =>
    showShadDialog<void>(
      context: context,
      builder: (context) => ShadDialog(
        key: const ValueKey<String>('shortcutsHelp'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(WonkyAppLocalizations.of(context).shortcutsTitle),
        constraints: const BoxConstraints(maxWidth: 720),
        child: SizedBox(
          width: 680,
          height: 480,
          child: _ShortcutsHelp(services: s),
        ),
      ),
    );

class _ShortcutsHelp extends StatefulWidget {
  const _ShortcutsHelp({required this.services});

  final ShellServices services;

  @override
  State<_ShortcutsHelp> createState() => _ShortcutsHelpState();
}

class _ShortcutsHelpState extends State<_ShortcutsHelp>
    with McpDialogRegistration<_ShortcutsHelp> {
  final _query = TextEditingController();

  String get _q => _query.text;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// The shortcuts matching the query by category.
  Map<String, List<(String, List<String>)>> _byCategory(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final s = widget.services;
    final byCategory = <String, List<(String, List<String>)>>{};
    for (final c in s.registry.all) {
      final labels = s.keymap.labelsOf(c.id.value);
      if (labels == null) continue;
      final title = c.title(context);
      if (_q.isNotEmpty && !title.toLowerCase().contains(_q.toLowerCase())) {
        continue;
      }
      byCategory
          .putIfAbsent(c.category(context) ?? l.categoryOther, () => [])
          .add((title, labels));
    }
    return byCategory;
  }

  @override
  Map<String, Object?> describe() {
    final l = WonkyAppLocalizations.of(context);
    final byCategory = _byCategory(context);
    final shortcuts = <Map<String, Object?>>[
      for (final cat in byCategory.keys.toList()..sort())
        for (final (title, keys) in byCategory[cat]!)
          {'category': cat, 'title': title, 'keys': keys},
    ];
    return {
      'title': l.shortcutsTitle,
      'kind': 'shortcuts',
      'fields': [
        {
          'id': 'query',
          'label': l.shortcutsSearch,
          'type': 'text',
          'value': _q,
        },
      ],
      'shortcuts': shortcuts.take(500).toList(),
      if (shortcuts.length > 500) 'truncated': true,
      'buttons': [
        {'id': 'close', 'label': l.actionClose},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id != 'query') return false;
    setState(() => _query.text = '${value ?? ''}');
    return true;
  }

  @override
  bool press(String buttonId) {
    if (buttonId != 'close' && buttonId != 'cancel') return false;
    Navigator.of(context).pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final byCategory = _byCategory(context);
    final cats = byCategory.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadInput(
          controller: _query,
          autofocus: true,
          placeholder: Text(l.shortcutsSearch),
          leading: const Icon(LucideIcons.search, size: 16),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: cats.isEmpty
              ? Center(
                  child: Text(l.paletteEmpty, style: theme.textTheme.muted),
                )
              : ListView(
                  children: [
                    for (final cat in cats) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          cat,
                          style: theme.textTheme.small.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      for (final (title, keys)
                          in byCategory[cat]!
                            ..sort((a, b) => a.$1.compareTo(b.$1)))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: theme.textTheme.small.copyWith(
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              ShadKbd.group(keys, height: 22),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
