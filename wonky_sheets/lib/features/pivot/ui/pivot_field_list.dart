import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../../l10n/sheets_l10n.dart';
import '../pivot_spec_edit.dart';

/// The icon of a source field kind (number, date, text, boolean).
IconData pivotFieldIcon(PivotFieldKind kind) => switch (kind) {
  PivotFieldKind.number => LucideIcons.hash,
  PivotFieldKind.date => LucideIcons.calendar,
  PivotFieldKind.boolean => LucideIcons.squareCheck,
  PivotFieldKind.text || PivotFieldKind.empty => LucideIcons.type,
};

/// The *Add ▾* button of an editor section: a popover with a search input
/// and the source fields (07 §7.3 `PivotFieldList`); Values also offers
/// *Calculated field*. ↑/↓ move, Enter picks, Esc closes.
class PivotAddFieldButton extends StatefulWidget {
  const PivotAddFieldButton({
    super.key,
    required this.area,
    required this.areaLabel,
    required this.fields,
    required this.onPick,
    this.onCalculated,
    this.enabled = true,
  });

  final PivotArea area;
  final String areaLabel;
  final List<PivotSourceField> fields;
  final ValueChanged<PivotSourceField> onPick;

  /// Adds a calculated field (Values only).
  final VoidCallback? onCalculated;
  final bool enabled;

  @override
  State<PivotAddFieldButton> createState() => _PivotAddFieldButtonState();
}

class _PivotAddFieldButtonState extends State<PivotAddFieldButton> {
  final _popover = ShadPopoverController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  int _highlight = 0;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _highlight = 0));
    _popover.addListener(_onPopover);
  }

  void _onPopover() {
    if (_popover.isOpen) {
      _search.clear();
      _highlight = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _popover.removeListener(_onPopover);
    _popover.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<PivotSourceField> get _matches {
    final q = _search.text.trim().toLowerCase();
    return [
      for (final f in widget.fields)
        if (q.isEmpty || f.header.toLowerCase().contains(q)) f,
    ];
  }

  int get _count => _matches.length + (widget.onCalculated == null ? 0 : 1);

  void _pickIndex(int i) {
    final m = _matches;
    _popover.hide();
    if (i < m.length) {
      widget.onPick(m[i]);
    } else {
      widget.onCalculated?.call();
    }
  }

  KeyEventResult _keys(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = _count;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        if (n > 0) setState(() => _highlight = (_highlight + 1) % n);
      case LogicalKeyboardKey.arrowUp:
        if (n > 0) setState(() => _highlight = (_highlight - 1 + n) % n);
      case LogicalKeyboardKey.enter:
        if (n > 0) _pickIndex(_highlight.clamp(0, n - 1));
      case LogicalKeyboardKey.escape:
        _popover.hide();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    return ShadPopover(
      controller: _popover,
      anchor: WonkyMenuPlacement.onScreen(
        const ShadAnchor(
          childAlignment: AlignmentDirectional.bottomEnd,
          overlayAlignment: AlignmentDirectional.topEnd,
          offset: Offset(0, 4),
        ),
      ),
      padding: const EdgeInsets.all(6),
      popover: (context) => _list(context, l),
      child: ShadButton.outline(
        key: ValueKey<String>('pivot.add.${widget.area.name}'),
        size: ShadButtonSize.sm,
        height: 28,
        enabled: widget.enabled,
        leading: const Icon(LucideIcons.plus, size: 14),
        onPressed: _popover.toggle,
        child: Semantics(
          label: l.pivotAddTo(widget.areaLabel),
          excludeSemantics: true,
          child: Text(l.pivotAdd),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, SheetsLocalizations l) {
    final theme = ShadTheme.of(context);
    final m = _matches;
    final calc = widget.onCalculated != null;
    Widget row(int i, IconData icon, String label, {bool italic = false}) {
      final hi = i == _highlight;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _highlight = i),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _pickIndex(i),
          child: Container(
            key: ValueKey<String>('pivot.addField.${widget.area.name}.$i'),
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: hi ? theme.colorScheme.accent : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.mutedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      fontSize: 13,
                      fontStyle: italic ? FontStyle.italic : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 240,
      child: Focus(
        onKeyEvent: _keys,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShadInput(
              key: ValueKey<String>(
                'pivot.addField.search.${widget.area.name}',
              ),
              controller: _search,
              focusNode: _searchFocus,
              placeholder: Text(l.pivotSearchFields),
              leading: const Icon(LucideIcons.search, size: 14),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i < m.length; i++)
                    row(i, pivotFieldIcon(m[i].kind), m[i].header),
                  if (m.isEmpty && !calc)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        l.pivotNoFields,
                        style: theme.textTheme.muted,
                      ),
                    ),
                  if (calc)
                    row(
                      m.length,
                      LucideIcons.squareFunction,
                      l.pivotCalculatedField,
                      italic: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
