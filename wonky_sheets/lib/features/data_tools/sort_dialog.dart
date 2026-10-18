import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../../l10n/sheets_l10n.dart';

/// One sort key of the dialog.
@immutable
class SortDialogKey {
  const SortDialogKey(this.colId, {this.ascending = true});

  final String colId;
  final bool ascending;

  Map<String, Object?> toJson() => {'colId': colId, 'ascending': ascending};
}

/// The result of [showSortRangeDialog].
@immutable
class SortDialogResult {
  const SortDialogResult(this.keys, {required this.hasHeader});

  final List<SortDialogKey> keys;
  final bool hasHeader;
}

/// Sort range (advanced) (04 §11.5): *Data has header row*, a list of
/// `{column, A→Z / Z→A}` rows with ✕ and "+ Add another sort column".
/// [columns] maps column ids to their letter; [headers] to the header text
/// (shown when *Data has header row* is checked).
Future<SortDialogResult?> showSortRangeDialog(
  BuildContext context, {
  required String rangeA1,
  required Map<String, String> columns,
  required Map<String, String> headers,
  required bool hasHeader,
}) => showShadDialog<SortDialogResult>(
  context: context,
  builder: (_) => SortRangeDialog(
    rangeA1: rangeA1,
    columns: columns,
    headers: headers,
    hasHeader: hasHeader,
  ),
);

class SortRangeDialog extends StatefulWidget {
  const SortRangeDialog({
    super.key,
    required this.rangeA1,
    required this.columns,
    required this.headers,
    required this.hasHeader,
  });

  final String rangeA1;
  final Map<String, String> columns;
  final Map<String, String> headers;
  final bool hasHeader;

  @override
  State<SortRangeDialog> createState() => _SortRangeDialogState();
}

class _SortRangeDialogState extends State<SortRangeDialog>
    implements McpDescribableDialog {
  ShellServices? _registeredIn;
  late bool _hasHeader = widget.hasHeader;
  late final List<SortDialogKey> _keys = [
    SortDialogKey(widget.columns.keys.first),
  ];

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
    super.dispose();
  }

  String _label(String colId) {
    final letter = widget.columns[colId] ?? colId;
    if (!_hasHeader) return sheetsL10n(context).sortColumnLabel(letter);
    final h = widget.headers[colId] ?? '';
    return h.isEmpty ? sheetsL10n(context).sortColumnLabel(letter) : h;
  }

  bool get _canAdd => _keys.length < widget.columns.length;

  void _add() {
    if (!_canAdd) return;
    final used = {for (final k in _keys) k.colId};
    final next = widget.columns.keys.firstWhere(
      (c) => !used.contains(c),
      orElse: () => widget.columns.keys.first,
    );
    setState(() => _keys.add(SortDialogKey(next)));
  }

  void _sort() => Navigator.of(
    context,
  ).pop(SortDialogResult(List.of(_keys), hasHeader: _hasHeader));

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': l.sortDialogTitle(widget.rangeA1),
      'fields': [
        {
          'id': 'hasHeader',
          'label': l.sortDialogHasHeader,
          'type': 'checkbox',
          'value': _hasHeader,
        },
        for (var i = 0; i < _keys.length; i++) ...[
          {
            'id': 'sortBy.$i.column',
            'label': i == 0 ? l.sortDialogSortBy : l.sortDialogThenBy,
            'type': 'select',
            'value': _keys[i].colId,
            'options': widget.columns.keys.toList(),
          },
          {
            'id': 'sortBy.$i.order',
            'label': l.sortDialogOrder,
            'type': 'select',
            'value': _keys[i].ascending ? 'asc' : 'desc',
            'options': ['asc', 'desc'],
          },
        ],
      ],
      'buttons': [
        if (_canAdd) {'id': 'add', 'label': l.sortDialogAddColumn},
        for (var i = 1; i < _keys.length; i++)
          {'id': 'remove.$i', 'label': l.sortDialogRemoveColumn},
        {
          'id': 'cancel',
          'label': WonkyAppLocalizations.of(context).actionCancel,
        },
        {'id': 'sort', 'label': l.sortDialogSort},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id == 'hasHeader') {
      if (value is! bool) return false;
      setState(() => _hasHeader = value);
      return true;
    }
    final m = RegExp(r'^sortBy\.(\d+)\.(column|order)$').firstMatch(id);
    if (m == null) return false;
    final i = int.parse(m.group(1)!);
    if (i >= _keys.length) return false;
    final k = _keys[i];
    if (m.group(2) == 'column') {
      if (value is! String || !widget.columns.containsKey(value)) return false;
      setState(() => _keys[i] = SortDialogKey(value, ascending: k.ascending));
    } else {
      if (value != 'asc' && value != 'desc') return false;
      setState(
        () => _keys[i] = SortDialogKey(k.colId, ascending: value == 'asc'),
      );
    }
    return true;
  }

  @override
  bool press(String buttonId) {
    switch (buttonId) {
      case 'add':
        _add();
      case 'cancel':
        Navigator.of(context).pop();
      case 'sort':
        _sort();
      default:
        final m = RegExp(r'^remove\.(\d+)$').firstMatch(buttonId);
        final i = m == null ? -1 : int.parse(m.group(1)!);
        if (i < 1 || i >= _keys.length) return false;
        setState(() => _keys.removeAt(i));
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
        key: const ValueKey<String>('dialog.sortRange'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.sortDialogTitle(widget.rangeA1)),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.sortRange.cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(la.actionCancel),
          ),
          ShadButton(
            key: const ValueKey<String>('dialog.sortRange.sort'),
            onPressed: _sort,
            child: Text(l.sortDialogSort),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadCheckbox(
                  key: const ValueKey<String>('dialog.sortRange.hasHeader'),
                  value: _hasHeader,
                  onChanged: (v) => setState(() => _hasHeader = v),
                  label: Text(l.sortDialogHasHeader),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _keys.length; i++) ...[
                  Text(
                    i == 0 ? l.sortDialogSortBy : l.sortDialogThenBy,
                    style: theme.textTheme.small,
                  ),
                  const SizedBox(height: 6),
                  _row(context, i),
                  const SizedBox(height: 10),
                ],
                if (_canAdd)
                  ShadButton.ghost(
                    key: const ValueKey<String>('dialog.sortRange.add'),
                    size: ShadButtonSize.sm,
                    width: double.infinity,
                    mainAxisAlignment: MainAxisAlignment.start,
                    leading: const Icon(LucideIcons.plus, size: 16),
                    onPressed: _add,
                    child: Expanded(
                      child: Text(
                        l.sortDialogAddColumn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int i) {
    final l = sheetsL10n(context);
    final k = _keys[i];
    final select = ShadSelect<String>(
      key: ValueKey<String>('dialog.sortRange.$i.${k.colId}.$_hasHeader'),
      initialValue: k.colId,
      minWidth: 120,
      options: [
        for (final c in widget.columns.keys)
          ShadOption(value: c, child: Text(_label(c))),
      ],
      selectedOptionBuilder: (context, v) =>
          Text(_label(v), overflow: TextOverflow.ellipsis),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _keys[i] = SortDialogKey(v, ascending: k.ascending));
      },
    );
    final order = ShadRadioGroup<bool>(
      key: ValueKey<String>('dialog.sortRange.$i.order.${k.ascending}'),
      initialValue: k.ascending,
      axis: Axis.horizontal,
      spacing: 8,
      onChanged: (v) {
        if (v == null) return;
        setState(() => _keys[i] = SortDialogKey(k.colId, ascending: v));
      },
      items: [
        ShadRadio(value: true, label: Text(l.sortAtoZ)),
        ShadRadio(value: false, label: Text(l.sortZtoA)),
      ],
    );
    final remove = SizedBox(
      width: 32,
      child: i == 0
          ? null
          : ShadIconButton.ghost(
              key: ValueKey<String>('dialog.sortRange.$i.remove'),
              icon: const Icon(LucideIcons.x, size: 16),
              onPressed: () => setState(() => _keys.removeAt(i)),
            ),
    );
    // Narrow dialogs (phones, 360 px) put the order under the column.
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < 400
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: select),
                    remove,
                  ],
                ),
                const SizedBox(height: 6),
                order,
              ],
            )
          : Row(
              children: [
                Expanded(child: select),
                const SizedBox(width: 8),
                order,
                remove,
              ],
            ),
    );
  }
}
