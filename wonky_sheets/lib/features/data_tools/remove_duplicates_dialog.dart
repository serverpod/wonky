import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import 'mcp_dialog.dart';

/// Result of [showRemoveDuplicatesDialog].
@immutable
class RemoveDuplicatesChoice {
  const RemoveDuplicatesChoice(this.colIds, {required this.hasHeader});

  final List<String> colIds;
  final bool hasHeader;
}

/// Remove duplicates (04 §11.12): *Data has header row* and the columns to
/// analyze (with *Select all*). [letters] maps column ids to letters,
/// [headers] to header texts.
Future<RemoveDuplicatesChoice?> showRemoveDuplicatesDialog(
  BuildContext context, {
  required String rangeA1,
  required Map<String, String> letters,
  required Map<String, String> headers,
  required bool hasHeader,
}) => showShadDialog<RemoveDuplicatesChoice>(
  context: context,
  builder: (_) => RemoveDuplicatesDialog(
    rangeA1: rangeA1,
    letters: letters,
    headers: headers,
    hasHeader: hasHeader,
  ),
);

class RemoveDuplicatesDialog extends StatefulWidget {
  const RemoveDuplicatesDialog({
    super.key,
    required this.rangeA1,
    required this.letters,
    required this.headers,
    required this.hasHeader,
  });

  final String rangeA1;
  final Map<String, String> letters;
  final Map<String, String> headers;
  final bool hasHeader;

  @override
  State<RemoveDuplicatesDialog> createState() => _RemoveDuplicatesDialogState();
}

class _RemoveDuplicatesDialogState extends State<RemoveDuplicatesDialog>
    with McpDialogState<RemoveDuplicatesDialog> {
  late bool _hasHeader = widget.hasHeader;
  late final Set<String> _selected = {...widget.letters.keys};
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _all => _selected.length == widget.letters.length;

  String _label(String colId) {
    final l = sheetsL10n(context);
    final letter = widget.letters[colId]!;
    final h = widget.headers[colId] ?? '';
    return _hasHeader && h.isNotEmpty ? h : l.sortColumnLabel(letter);
  }

  void _toggleAll(bool v) => setState(() {
    _selected.clear();
    if (v) _selected.addAll(widget.letters.keys);
  });

  void _ok() {
    if (_selected.isEmpty) return;
    Navigator.of(context).pop(
      RemoveDuplicatesChoice([
        for (final c in widget.letters.keys)
          if (_selected.contains(c)) c,
      ], hasHeader: _hasHeader),
    );
  }

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': l.dedupeTitle,
      'description': l.dedupeRange(widget.rangeA1),
      'fields': [
        {
          'id': 'hasHeader',
          'label': l.sortDialogHasHeader,
          'type': 'checkbox',
          'value': _hasHeader,
        },
        {
          'id': 'selectAll',
          'label': l.dedupeSelectAll,
          'type': 'checkbox',
          'value': _all,
        },
        for (final c in widget.letters.keys)
          {
            'id': 'columns.$c',
            'label': _label(c),
            'type': 'checkbox',
            'value': _selected.contains(c),
          },
      ],
      'buttons': [
        {
          'id': 'cancel',
          'label': WonkyAppLocalizations.of(context).actionCancel,
        },
        {'id': 'remove', 'label': l.dedupeRemove},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (value is! bool) return false;
    if (id == 'hasHeader') {
      setState(() => _hasHeader = value);
      return true;
    }
    if (id == 'selectAll') {
      _toggleAll(value);
      return true;
    }
    if (id.startsWith('columns.')) {
      final c = id.substring(8);
      if (!widget.letters.containsKey(c)) return false;
      setState(() => value ? _selected.add(c) : _selected.remove(c));
      return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'cancel':
        Navigator.of(context).pop();
      case 'remove':
        _ok();
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.removeDuplicates'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.dedupeTitle),
        description: Text(l.dedupeRange(widget.rangeA1)),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.removeDuplicates.cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.removeDuplicates.remove'),
            onPressed: _selected.isEmpty ? null : _ok,
            child: Text(l.dedupeRemove),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              ShadCheckbox(
                key: const ValueKey<String>(
                  'dialog.removeDuplicates.hasHeader',
                ),
                value: _hasHeader,
                onChanged: (v) => setState(() => _hasHeader = v),
                label: Text(l.sortDialogHasHeader),
              ),
              const SizedBox(height: 14),
              Text(l.dedupeColumns, style: theme.textTheme.small),
              const SizedBox(height: 8),
              ShadCheckbox(
                key: const ValueKey<String>(
                  'dialog.removeDuplicates.selectAll',
                ),
                value: _all,
                onChanged: _toggleAll,
                label: Text(l.dedupeSelectAll),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: WonkyScrollArea(
                  controller: _scroll,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final c in widget.letters.keys)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: ShadCheckbox(
                              key: ValueKey<String>(
                                'dialog.removeDuplicates.col.$c',
                              ),
                              value: _selected.contains(c),
                              onChanged: (v) => setState(
                                () =>
                                    v ? _selected.add(c) : _selected.remove(c),
                              ),
                              label: Text(
                                _label(c),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
