import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../cell_editor/cell_editor_overlay.dart' show editorModeLabel;
import '../formatting/sheets_user_defaults.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'selection_stats.dart';

String statLabel(SheetsLocalizations l, SelectionStat s) => switch (s) {
  SelectionStat.sum => l.statSum,
  SelectionStat.average => l.statAverage,
  SelectionStat.min => l.statMin,
  SelectionStat.max => l.statMax,
  SelectionStat.count => l.statCount,
  SelectionStat.countNumbers => l.statCountNumbers,
};

/// "Sum: 1,234" (04 §7): one aggregate of the selection; the menu lists all.
class SelectionStatsButton extends StatefulWidget {
  const SelectionStatsButton({super.key, required this.controller});

  final SheetEditorController controller;

  @override
  State<SelectionStatsButton> createState() => _SelectionStatsButtonState();
}

class _SelectionStatsButtonState extends State<SelectionStatsButton> {
  Timer? _debounce;
  SelectionStats _stats = SelectionStats.empty;
  bool _multi = false;

  SheetEditorController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.selection.addListener(_schedule);
    c.contentSignal.addListener(_schedule);
    _compute();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    c.selection.removeListener(_schedule);
    c.contentSignal.removeListener(_schedule);
    super.dispose();
  }

  /// Cells visited per step: the first step runs right after the debounce,
  /// further steps in later event-loop turns (S-03, CQ-41).
  static const stepCells = 50000;

  /// Increments on every selection or content change: a running
  /// computation stops (the model may have changed under it).
  int _generation = 0;

  void _schedule() {
    _generation++;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), _compute);
  }

  void _compute() {
    if (!mounted) return;
    final generation = ++_generation;
    final multi = selectionIsMulti(c);
    if (!multi) {
      setState(() {
        _multi = false;
        _stats = SelectionStats.empty;
      });
      return;
    }
    final acc = SelectionStatsAccumulator(c);
    if (acc.step(stepCells)) {
      setState(() {
        _multi = true;
        _stats = acc.result;
      });
      return;
    }
    // A large selection: the shown value stays until the new one is
    // complete.
    unawaited(_continue(acc, generation));
  }

  Future<void> _continue(SelectionStatsAccumulator acc, int generation) async {
    while (true) {
      await Future<void>(() {});
      if (!mounted || generation != _generation) return;
      if (acc.step(stepCells)) break;
    }
    setState(() {
      _multi = true;
      _stats = acc.result;
    });
  }

  String _format(SelectionStat s) {
    final v = _stats.valueOf(s);
    if (s == SelectionStat.count || s == SelectionStat.countNumbers) {
      return NumberFormatter.instance.formatText(
        NumberValue(v),
        '#,##0',
        locale: c.locale,
      );
    }
    return NumberFormatter.instance.formatText(
      NumberValue(v),
      _stats.numberFormat ?? '#,##0.##',
      locale: c.locale,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_multi || _stats.count == 0) return const SizedBox.shrink();
    final l = sheetsL10n(context);
    final shown = c.shownStat ?? _stats.defaultStat;
    final theme = ShadTheme.of(context);
    return WonkyDropdownMenu(
      entries: () => [
        for (final s in SelectionStat.values)
          WonkyMenuRadioItem(
            key: ValueKey<String>('menu.stats.${s.name}'),
            label: '${statLabel(l, s)}: ${_format(s)}',
            selected: s == shown,
            onSelected: () => unawaited(
              c.invokeCommand('sheets.stats.setShown', {
                'fn': s.name,
              }, InvocationSource.menu),
            ),
          ),
      ],
      builder: (context, menu) => ShadButton.ghost(
        key: const ValueKey<String>('sheets.stats'),
        size: ShadButtonSize.sm,
        onPressed: menu.toggle,
        trailing: const Icon(LucideIcons.chevronDown, size: 12),
        child: Text(
          '${statLabel(l, shown)}: ${_format(shown)}',
          style: theme.textTheme.small,
        ),
      ),
    );
  }
}

/// Left status bar items (04 §8): editor mode, sheet size and cell count.
class SheetsStatusLeft extends StatelessWidget {
  const SheetsStatusLeft({super.key, required this.controller});

  final SheetEditorController controller;

  static const maxCells = 1000000;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([c, c.editor, c.services.prefs]),
      builder: (context, _) {
        final s = c.activeSheet;
        final cells = c.model.gridCellCount;
        final ratio = cells / maxCells;
        final color = ratio >= 0.95
            ? theme.colorScheme.destructive
            : ratio >= 0.8
            ? theme.colorScheme.warning
            : theme.colorScheme.mutedForeground;
        final style = theme.textTheme.muted.copyWith(fontSize: 12);
        // Settings › Sheets › Show editor mode in status bar.
        final showMode = SheetsUserDefaults.of(c.services).showEditorMode;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showMode) ...[
              Text(
                editorModeLabel(l, c.editor),
                key: const ValueKey<String>('sheets.status.mode'),
                style: style,
              ),
              Text('  ·  ', style: style),
            ],
            if (s != null)
              Flexible(
                child: Text(
                  l.statusSheetSize(s.name, s.rows.length, s.columns.length),
                  key: const ValueKey<String>('sheets.status.size'),
                  style: style,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Text('  ·  ', style: style),
            Flexible(
              child: ShadTooltip(
                builder: (_) => Text(l.statusCellLimitTooltip),
                child: Text(
                  l.statusCellCount(cells, maxCells),
                  key: const ValueKey<String>('sheets.status.cells'),
                  style: style.copyWith(color: color),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Right status bar items (04 §8): zoom and view toggles.
class SheetsStatusRight extends StatelessWidget {
  const SheetsStatusRight({super.key, required this.controller});

  final SheetEditorController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final zoom = (c.scroll.zoom * 100).round();
        Widget icon(String key, IconData i, String label, String id) =>
            ShadTooltip(
              builder: (_) => Text(label),
              child: ShadIconButton.ghost(
                key: ValueKey<String>(key),
                width: 24,
                height: 22,
                iconSize: 14,
                icon: Icon(i),
                semanticLabel: label,
                onPressed: () => unawaited(c.invokeCommand(id)),
              ),
            );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon(
              'sheets.status.zoomOut',
              LucideIcons.minus,
              l.cmdViewZoomOut,
              'sheets.view.zoomOut',
            ),
            Text(
              '$zoom%',
              key: const ValueKey<String>('sheets.status.zoom'),
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
            icon(
              'sheets.status.zoomIn',
              LucideIcons.plus,
              l.cmdViewZoomIn,
              'sheets.view.zoomIn',
            ),
            const SizedBox(width: 8),
            icon(
              'sheets.status.gridlines',
              LucideIcons.grid3x3,
              l.cmdViewToggleGridlines,
              'sheets.view.toggleGridlines',
            ),
            icon(
              'sheets.status.formulas',
              LucideIcons.squareFunction,
              l.cmdViewToggleFormulas,
              'sheets.view.toggleFormulas',
            ),
          ],
        );
      },
    );
  }
}
