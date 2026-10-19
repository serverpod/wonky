import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;

import '../../editor_screen/deck_editor_controller.dart';
import '../style/style_sections.dart';
import 'table_cells.dart';

ResolvedElement? _table(StyleScope s) {
  final t = [
    for (final e in s.targets)
      if (e.record.kind == ElementKind.table) e,
  ];
  return t.length == 1 ? t.single : null;
}

/// Inspector › Format › **Table** (04 §7.2, 03 §6.6): the table style
/// (theme or none), header row, first column, banded rows/columns, total
/// row, *Distribute rows/columns*.
Widget tableSection(
  BuildContext context,
  ShellServices services,
  DeckEditorController ed,
) {
  final s = StyleScope(context, services, ed);
  final e = _table(s);
  if (e == null) return const SizedBox.shrink();
  final data = e.data ?? const <String, Object?>{};
  final options = data['options'] is Map
      ? (data['options'] as Map).cast<String, Object?>()
      : const <String, Object?>{};
  bool opt(String k, bool d) => options[k] is bool ? options[k] as bool : d;
  final style = data['style'] == 'none' ? 'none' : 'theme';
  final on = s.enabled('slides.table.setOptions', const {'style': 'theme'});

  Widget toggle(String key, String label, bool fallback) => InspectorRow(
    label: label,
    child: ShadSwitch(
      key: ValueKey<String>('slides.table.option.$key'),
      value: opt(key, fallback),
      enabled: on,
      onChanged: (v) => s.run('slides.table.setOptions', {key: v}),
    ),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InspectorRow(
        label: s.l.tableStyle,
        child: StyleSelect<String>(
          keyName: 'table.style',
          value: style,
          options: const ['theme', 'none'],
          label: (v) => v == 'none' ? s.l.tableStyleNone : s.l.tableStyleTheme,
          enabled: on,
          onChanged: (v) => s.run('slides.table.setOptions', {'style': v}),
        ),
      ),
      toggle('headerRow', s.l.tableHeaderRow, true),
      toggle('firstColumn', s.l.tableFirstColumn, false),
      toggle('bandedRows', s.l.tableBandedRows, true),
      toggle('bandedColumns', s.l.tableBandedColumns, false),
      toggle('totalRow', s.l.tableTotalRow, false),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final id in [
            'slides.table.distributeRows',
            'slides.table.distributeColumns',
          ])
            ShadButton.outline(
              key: ValueKey<String>('slides.table.section.$id'),
              size: ShadButtonSize.sm,
              enabled: s.enabled(id),
              onPressed: () => s.run(id),
              child: Flexible(
                child: Text(
                  s.ui.title(id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

/// Inspector › Format › **Cell** (04 §7.2, 03 §6.6): the selected cells'
/// (else every cell's) fill, borders (`TableBorderPicker`), vertical
/// alignment and padding.
Widget cellSection(
  BuildContext context,
  ShellServices services,
  DeckEditorController ed,
) {
  final s = StyleScope(context, services, ed);
  final e = _table(s);
  if (e == null) return const SizedBox.shrink();
  final ix = ed.model.indexes.table(e.id);
  final sel = TableCellSelection.of(ed);
  final range = (sel.tableId == e.id ? sel.range : null) ?? TableRange.all(ix);
  final cells = range?.cells(ix) ?? const [];
  final recs = [for (final c in cells) ix.cell(c.rowId, c.columnId)];
  T? common<T>(T? Function(SlideTableCellRec? r) f) {
    final v = {for (final r in recs) f(r)};
    return v.length == 1 ? v.single : null;
  }

  final fill = common((r) => r?.fill);
  final vAlign = common((r) => r?.vAlign) ?? 'top';
  final theme = s.theme;
  final fillArgb = fill == null || theme == null
      ? null
      : theme.colorString(fill);
  final on = s.enabled('slides.table.setCellFill', const {'none': true});
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (sel.tableId == e.id && range != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            s.l.tableCellsSelected(cells.length),
            style: ShadTheme.of(context).textTheme.muted,
          ),
        ),
      InspectorRow(
        label: s.l.tableCellFill,
        child: StyleColorButton(
          keyName: 'cellFill',
          label: s.l.tableCellFill,
          value: fill,
          swatch: fillArgb == null ? null : Color(fillArgb),
          theme: theme,
          resetLabel: s.l.tableStyleFill,
          enabled: on,
          onChanged: (c) => s.run(
            'slides.table.setCellFill',
            c == null ? const {'none': true} : {'color': c},
          ),
        ),
      ),
      InspectorRow(
        label: s.l.tableVerticalAlign,
        child: StyleSelect<String>(
          keyName: 'table.vAlign',
          value: vAlign,
          options: const ['top', 'middle', 'bottom'],
          label: (v) => switch (v) {
            'middle' => s.l.anchorMiddle,
            'bottom' => s.l.anchorBottom,
            _ => s.l.anchorTop,
          },
          enabled: s.enabled('slides.table.setCellAlign', const {
            'vAlign': 'top',
          }),
          onChanged: (v) => s.run('slides.table.setCellAlign', {'vAlign': v}),
        ),
      ),
      InspectorRow(
        label: s.l.tableCellPadding,
        child: StyleSelect<double>(
          keyName: 'table.padding',
          value: null,
          placeholder: s.l.tableStyleDefault,
          options: const [0, 4, 8, 12, 16, 24, 32],
          label: (v) => '${v.toInt()}',
          enabled: s.enabled('slides.table.setCellPadding', const {'all': 8}),
          onChanged: (v) => s.run('slides.table.setCellPadding', {'all': v}),
        ),
      ),
      const SizedBox(height: 4),
      Text(s.l.tableBorders, style: ShadTheme.of(context).textTheme.small),
      const SizedBox(height: 8),
      TableBorderPicker(scope: s),
    ],
  );
}

/// The border picker of table cells (03 §6.6 `TableBorderPicker`): the
/// edges (all, outer, inner, horizontal, vertical, top, bottom, left,
/// right, none) with the width, style and color applied by a click on an
/// edge button (one undo step each).
class TableBorderPicker extends StatefulWidget {
  const TableBorderPicker({super.key, required this.scope});

  final StyleScope scope;

  @override
  State<TableBorderPicker> createState() => _TableBorderPickerState();
}

class _TableBorderPickerState extends State<TableBorderPicker> {
  double _width = 1;
  String _style = 'solid';
  String _color = 'theme:text1';

  static const _edges = <(String, IconData)>[
    ('all', LucideIcons.grid3x3),
    ('outer', LucideIcons.square),
    ('inner', LucideIcons.plus),
    ('horizontal', LucideIcons.separatorHorizontal),
    ('vertical', LucideIcons.separatorVertical),
    ('top', LucideIcons.panelTop),
    ('bottom', LucideIcons.panelBottom),
    ('left', LucideIcons.panelLeft),
    ('right', LucideIcons.panelRight),
    ('none', LucideIcons.ban),
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.scope;
    final on = s.enabled('slides.table.setBorders', const {'edges': 'all'});
    final theme = s.theme;
    final argb = theme?.colorString(_color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final (edge, icon) in _edges)
              ShadTooltip(
                builder: (_) => Text(s.l.tableBorderEdge(edge)),
                child: ShadIconButton.outline(
                  key: ValueKey<String>('slides.table.border.$edge'),
                  width: 32,
                  height: 32,
                  enabled: on,
                  icon: Icon(icon, size: 16),
                  onPressed: () => s.run('slides.table.setBorders', {
                    'edges': edge,
                    'width': _width,
                    'style': _style,
                    'color': _color,
                  }),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InspectorRow(
          label: s.l.styleLabelColor,
          child: StyleColorButton(
            keyName: 'tableBorder',
            label: s.l.tableBorders,
            value: _color,
            swatch: argb == null ? null : Color(argb),
            theme: theme,
            enabled: on,
            onChanged: (c) => setState(() => _color = c ?? 'theme:text1'),
          ),
        ),
        InspectorRow(
          label: s.l.styleLabelWeight,
          child: StyleSelect<double>(
            keyName: 'tableBorder.width',
            value: _width,
            options: const [0.5, 1, 2, 3, 4, 6],
            label: (v) => v == v.roundToDouble() ? '${v.toInt()}' : '$v',
            enabled: on,
            onChanged: (v) => setState(() => _width = v),
          ),
        ),
        InspectorRow(
          label: s.l.styleLabelDash,
          child: StyleSelect<String>(
            keyName: 'tableBorder.style',
            value: _style,
            options: const ['solid', 'dashed', 'dotted'],
            label: (v) => s.l.tableBorderStyle(v),
            enabled: on,
            onChanged: (v) => setState(() => _style = v),
          ),
        ),
      ],
    );
  }
}
