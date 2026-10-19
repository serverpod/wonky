import 'dart:math' as math;

import 'package:serverpod/serverpod.dart' show Uuid;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/mcp/tool_support.dart';
import '../headless/sheets_core_internal.dart';
import 'sheets_changes.dart';
import 'sheets_mcp_support.dart';
import 'sheets_value_handlers.dart';
import 'sheets_writes.dart';

/// Formatting, rows/columns, sheets and merges (Sheets 12 §3.3–3.6).
abstract final class SheetsStructureHandlers {
  static ToolResult _result(
    SheetsWriteOutcome o,
    String summary, [
    Map<String, Object?> extra = const {},
  ]) {
    final id = o.changeId?.uuid;
    return ToolResult(
      {...extra, ...o.toJson(), 'summary': summary},
      text:
          '$summary'
          '${o.preview ? ' (suggested, not applied)' : ''}'
          '${id == null ? '' : ' · change_id $id'}'
          '${o.warnings.isEmpty ? '' : '\nWarnings: ${o.warnings.join(' ')}'}',
    );
  }

  static SheetsPlanStep _op(SheetsOperation Function() op) =>
      (model, pctx) => SheetsWrites.planner.plan(op(), model, pctx);

  // ------------------------------------------------------------ formats

  static final _color = RegExp(r'^(#[0-9a-fA-F]{6}|theme:[a-zA-Z0-9_]+)$');

  /// Validates a color argument (`#RRGGBB` or `theme:…`).
  static String color(Object? v, String name) {
    if (v is String && _color.hasMatch(v)) {
      return v.startsWith('#') ? v.toUpperCase() : v;
    }
    throw McpToolException(
      McpErrorCode.invalidArgs,
      '"$name" must be "#RRGGBB" or "theme:accent1"…"theme:accent6" (got '
      '"$v").',
    );
  }

  /// A number format preset name or pattern → stored format.
  static String? numberFormat(String? v) => switch (v) {
    null => null,
    'automatic' => NumberFormatPresets.automatic,
    'number' => NumberFormatPresets.number,
    'percent' => NumberFormatPresets.percent,
    'currency' => NumberFormatPresets.currency,
    'accounting' => NumberFormatPresets.accounting,
    'date' => NumberFormatPresets.date,
    'time' => NumberFormatPresets.time,
    'datetime' => NumberFormatPresets.dateTime,
    'duration' => NumberFormatPresets.duration,
    'scientific' => NumberFormatPresets.scientific,
    'text' => NumberFormatPresets.plainText,
    _ => v,
  };

  /// The format attribute values of a `format` argument.
  static Map<FormatAttr, Object?> formatValues(Map<String, dynamic> f) {
    final out = <FormatAttr, Object?>{};
    void put(String key, FormatAttr attr, Object? Function(Object? v) map) {
      if (f.containsKey(key)) out[attr] = f[key] == null ? null : map(f[key]);
    }

    put('number_format', FormatAttr.numberFormat, (v) => numberFormat('$v'));
    put('bold', FormatAttr.bold, (v) => v);
    put('italic', FormatAttr.italic, (v) => v);
    put('underline', FormatAttr.underline, (v) => v);
    put('strikethrough', FormatAttr.strikethrough, (v) => v);
    put('font_family', FormatAttr.fontFamily, (v) => v);
    put('font_size', FormatAttr.fontSize, (v) => (v as num).toDouble());
    put('text_color', FormatAttr.textColor, (v) => color(v, 'text_color'));
    put('fill_color', FormatAttr.fillColor, (v) => color(v, 'fill_color'));
    put(
      'h_align',
      FormatAttr.hAlign,
      (v) => v == 'general' ? null : enumByName(HorizontalAlign.values, v),
    );
    put(
      'v_align',
      FormatAttr.vAlign,
      (v) => enumByName(VerticalAlign.values, v),
    );
    put('wrap', FormatAttr.wrap, (v) => enumByName(WrapStrategy.values, v));
    put('rotation', FormatAttr.rotation, (v) => (v as num).toInt());
    put('link_url', FormatAttr.linkUrl, (v) => v);
    return out;
  }

  static const _sides = {
    'top': BorderPreset.top,
    'bottom': BorderPreset.bottom,
    'left': BorderPreset.left,
    'right': BorderPreset.right,
    'inner_horizontal': BorderPreset.horizontal,
    'inner_vertical': BorderPreset.vertical,
    'outer': BorderPreset.outer,
  };

  /// Border steps of a `borders` argument.
  static List<SheetsPlanStep> borderSteps(
    List<ResolvedRange> ranges,
    Map<String, dynamic> borders,
  ) {
    final steps = <SheetsPlanStep>[];
    for (final e in borders.entries) {
      final preset = _sides[e.key];
      final side = (e.value as Map).cast<String, dynamic>();
      if (preset == null) continue;
      final styleName = side['style'] as String? ?? 'thin';
      if (styleName == 'none') {
        steps.add(_clearSide(ranges, e.key));
        continue;
      }
      final style =
          enumByName(BorderStyle.values, styleName) ?? BorderStyle.thin;
      final c = side['color'] == null
          ? '#000000'
          : color(side['color'], 'borders.${e.key}.color');
      steps.add(_op(() => SetBorders(ranges, preset, style: style, color: c)));
    }
    return steps;
  }

  /// Removes one side of the borders of [ranges].
  static SheetsPlanStep _clearSide(List<ResolvedRange> ranges, String side) =>
      (model, pctx) {
        final targets = <(ResolvedRange, List<FormatAttr>)>[];
        for (final r in ranges) {
          final rect = r.rect;
          ResolvedRange sub(GridRect g) => ResolvedRange(r.sheetId, g);
          switch (side) {
            case 'top':
              targets.add((
                sub(GridRect(rect.top, rect.left, rect.top, rect.right)),
                [FormatAttr.borderTop],
              ));
            case 'bottom':
              targets.add((
                sub(GridRect(rect.bottom, rect.left, rect.bottom, rect.right)),
                [FormatAttr.borderBottom],
              ));
            case 'left':
              targets.add((
                sub(GridRect(rect.top, rect.left, rect.bottom, rect.left)),
                [FormatAttr.borderLeft],
              ));
            case 'right':
              targets.add((
                sub(GridRect(rect.top, rect.right, rect.bottom, rect.right)),
                [FormatAttr.borderRight],
              ));
            case 'inner_horizontal':
              targets.add((r, [FormatAttr.borderTop, FormatAttr.borderBottom]));
            case 'inner_vertical':
              targets.add((r, [FormatAttr.borderLeft, FormatAttr.borderRight]));
            default:
              targets.add((r, FormatAttr.borders));
          }
        }
        final b = PlanBuilder(model, pctx);
        for (final (range, attrs) in targets) {
          final s = b.sheetOf(range.sheetId);
          for (final (r, c, _) in s.cellsIn(range.rect).toList()) {
            final rowId = s.rows.idAt(r), colId = s.columns.idAt(c);
            b.writeCell(s.id, rowId, colId, {
              for (final a in attrs) a.column: null,
            });
          }
        }
        return b.build('Borders', kinds: [ChangeKinds.format]);
      };

  static Future<ToolResult> formatRange(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final ranges = [
      for (final r in a.list('ranges')!.cast<String>()) SheetsMcp.range(t, r),
    ];
    final format = a.object('format')!;
    final values = formatValues(format);
    var cells = 0;
    for (final r in ranges) {
      cells += r.wholeRows
          ? r.rect.rowCount
          : r.wholeColumns
          ? r.rect.colCount
          : r.rect.cellCount;
    }
    SheetsValueHandlers.checkWriteLimit(cells);
    final borders = (format['borders'] as Map?)?.cast<String, dynamic>();
    final a1s = [for (final r in ranges) t.model.a1Of(r)];
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.format_range',
      label: SheetsMcp.label(ctx, 'sheets.format_range', a1s.join(', ')),
      ranges: a1s,
      steps: [
        if (values.isNotEmpty) _op(() => SetFormat(ranges, values)),
        if (borders != null) ...borderSteps(ranges, borders),
      ],
    );
    return _result(o, 'Formatted ${a1s.join(', ')}');
  }

  static Future<ToolResult> clearFormats(ToolContext ctx, ToolArgs a) =>
      SheetsValueHandlers.clearRange(
        ctx,
        a,
        forceWhat: 'formats',
        tool: 'sheets.clear_formats',
      );

  static Future<ToolResult> applyBanding(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final r = SheetsMcp.range(t, a.requireString('range'));
    final s = t.model.sheet(r.sheetId)!;
    final rect = SheetsMcp.clipToUsed(s, r);
    final style = a.string('style');
    var banding = const BandingStyle();
    if (style != null) {
      final c = color(style, 'style');
      final hex = c.startsWith('#')
          ? c
          : t.model.theme.resolveColor(c) ?? '#4285F4';
      banding = BandingStyle(
        header: c,
        secondBand: ColorUtil.lighten(hex, 0.85),
        footer: ColorUtil.lighten(hex, 0.6),
      );
    }
    banding = banding.copyWith(
      showHeader: a.boolean('header') ?? true,
      showFooter: a.boolean('footer') ?? false,
    );
    final a1 = SheetsMcp.a1(t.model, s.id, rect);
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.apply_banding',
      label: SheetsMcp.label(ctx, 'sheets.apply_banding', a1),
      ranges: [a1],
      steps: [_op(() => AddBanding(s.id, rect, banding.toJson()))],
    );
    return _result(o, 'Applied alternating colors to $a1', {
      'banding_id': o.result['bandingId'] ?? o.result['id'],
    });
  }

  // ---------------------------------------------------- rows and columns

  static Dimension _dimension(String? v) =>
      v == 'columns' ? Dimension.columns : Dimension.rows;

  static (SheetModel, int, int) _span(
    SheetsTarget t,
    ToolArgs a,
    Dimension d, {
    String startKey = 'start',
  }) {
    final s = SheetsMcp.sheet(t, a.requireString('sheet'));
    final start = SheetsMcp.index(a.values[startKey], name: startKey);
    final count = a.integer('count') ?? 1;
    final axis = s.axis(d);
    if (start >= axis.length) {
      throw SheetsMcp.invalidRange(
        '${d == Dimension.rows ? 'Row' : 'Column'} ${_label(d, start)} is '
        'outside the grid of "${s.name}" (${axis.length} '
        '${d == Dimension.rows ? 'rows' : 'columns'}).',
      );
    }
    return (s, start, math.min(count, axis.length - start));
  }

  static String _label(Dimension d, int i) =>
      d == Dimension.rows ? '${i + 1}' : SheetsMcp.letter(i);

  static String _spanA1(Dimension d, int start, int count) =>
      '${_label(d, start)}:${_label(d, start + count - 1)}';

  static Future<ToolResult> insertDimension(
    ToolContext ctx,
    ToolArgs a,
    Dimension d,
  ) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final s = SheetsMcp.sheet(t, a.requireString('sheet'));
    final at = SheetsMcp.index(a.values['at'], name: 'at');
    final count = a.integer('count') ?? 1;
    final max = d == Dimension.rows
        ? SheetsLimits.rowsInsertedPerCall
        : SheetsLimits.columnsInsertedPerCall;
    if (count > max) {
      throw McpToolException.limit(
        'At most $max ${d.name} can be inserted per call.',
        limit: 'inserted_${d.name}',
        max: max,
      );
    }
    final length = s.axis(d).length;
    final pos = math.min(at, length);
    final inherit = switch (a.string('inherit_from')) {
      'after' => InheritFrom.after,
      'none' => InheritFrom.none,
      _ => InheritFrom.before,
    };
    final span = _spanA1(d, pos, count);
    final tool = d == Dimension.rows
        ? 'sheets.insert_rows'
        : 'sheets.insert_columns';
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: tool,
      label: SheetsMcp.label(ctx, tool, '${s.name}!$span'),
      structural: 'Insert $count ${d.name} at $span',
      intents: (model) => [
        Structural(s.id, d, [
          if (pos > 0) pos - 1,
          if (pos < length) pos,
        ], StructuralOp.insert),
      ],
      steps: [
        _op(() => InsertDimension(s.id, d, pos, count, inheritFrom: inherit)),
      ],
    );
    return _result(o, 'Inserted $count ${d.name} at ${s.name}!$span', {
      'inserted_range': span,
    });
  }

  static Future<ToolResult> deleteDimension(
    ToolContext ctx,
    ToolArgs a,
    Dimension d,
  ) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final (s, start, count) = _span(t, a, d);
    final axis = s.axis(d);
    if (count >= axis.length) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'A sheet must keep at least one ${d == Dimension.rows ? 'row' : 'column'}.',
      );
    }
    final ids = [for (var i = start; i < start + count; i++) axis.idAt(i)];
    final span = _spanA1(d, start, count);
    final tool = d == Dimension.rows
        ? 'sheets.delete_rows'
        : 'sheets.delete_columns';
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: tool,
      label: SheetsMcp.label(ctx, tool, '${s.name}!$span'),
      structural: 'Delete $count ${d.name} ($span)',
      intents: (model) => [
        Structural(s.id, d, [
          for (var i = start; i < start + count; i++) i,
        ], StructuralOp.delete),
      ],
      confirmIf: (plans, model) => count >= SheetsLimits.aiDeleteDimension
          ? 'The assistant wants to delete $count ${d.name} ($span) of '
                '"${s.name}".'
          : null,
      steps: [_op(() => DeleteDimension(s.id, d, ids))],
    );
    return _result(o, 'Deleted $count ${d.name} (${s.name}!$span)', {
      'deleted': count,
    });
  }

  static Future<ToolResult> moveDimension(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final d = _dimension(a.string('dimension'));
    final (s, start, count) = _span(t, a, d);
    final dest = SheetsMcp.index(a.values['destination'], name: 'destination');
    final axis = s.axis(d);
    if (dest >= start && dest <= start + count) {
      return _result(
        SheetsWriteOutcome(
          plans: const [],
          cellsAffected: 0,
          warnings: const [],
        ),
        'Nothing to move',
      );
    }
    final ids = [for (var i = start; i < start + count; i++) axis.idAt(i)];
    final beforeId = dest >= axis.length ? null : axis.idAt(dest);
    final span = _spanA1(d, start, count);
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.move_dimension',
      label: SheetsMcp.label(ctx, 'sheets.move_dimension', '${s.name}!$span'),
      structural: 'Move ${d.name} $span',
      intents: (model) => [
        Structural(s.id, d, [
          for (var i = start; i < start + count; i++) i,
        ], StructuralOp.move),
      ],
      steps: [_op(() => MoveDimension(s.id, d, ids, beforeId))],
    );
    return _result(o, 'Moved ${d.name} $span of "${s.name}"');
  }

  static Future<ToolResult> resizeDimension(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final d = _dimension(a.string('dimension'));
    final (s, start, count) = _span(t, a, d);
    final axis = s.axis(d);
    final ids = [for (var i = start; i < start + count; i++) axis.idAt(i)];
    final sizePx = a.number('size_px')?.toDouble();
    final autoFit = a.boolean('auto_fit') ?? false;
    final reset = a.boolean('reset') ?? false;
    if (sizePx == null && !autoFit && !reset) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'Pass size_px, auto_fit: true or reset: true.',
      );
    }
    final steps = <SheetsPlanStep>[];
    if (autoFit && d == Dimension.columns) {
      // Headless auto-fit estimates text widths (≈7 px per character).
      for (var i = start; i < start + count; i++) {
        var chars = 0;
        final rect = GridRect(0, i, s.rows.length - 1, i);
        for (final (r, c, _) in s.cellsIn(rect, contentOnly: true)) {
          chars = math.max(chars, t.wb.displayAt(s.id, r, c).length);
        }
        final width = chars == 0 ? null : (chars * 7 + 16).clamp(30, 600);
        final id = axis.idAt(i);
        steps.add(
          _op(() => ResizeDimension(s.id, d, [id], width?.toDouble())),
        );
      }
    } else {
      steps.add(
        _op(
          () => ResizeDimension(s.id, d, ids, reset || autoFit ? null : sizePx),
        ),
      );
    }
    final span = _spanA1(d, start, count);
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.resize_dimension',
      label: SheetsMcp.label(ctx, 'sheets.resize_dimension', '${s.name}!$span'),
      structural: 'Resize ${d.name} $span',
      steps: steps,
    );
    return _result(o, 'Resized ${d.name} $span of "${s.name}"');
  }

  static Future<ToolResult> hideDimension(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final d = _dimension(a.string('dimension'));
    final (s, start, count) = _span(t, a, d);
    final axis = s.axis(d);
    final ids = [for (var i = start; i < start + count; i++) axis.idAt(i)];
    final hidden = a.boolean('hidden') ?? true;
    final span = _spanA1(d, start, count);
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.hide_dimension',
      label: SheetsMcp.label(ctx, 'sheets.hide_dimension', '${s.name}!$span'),
      structural: '${hidden ? 'Hide' : 'Show'} ${d.name} $span',
      steps: [_op(() => SetDimensionHidden(s.id, d, ids, hidden: hidden))],
    );
    return _result(
      o,
      '${hidden ? 'Hid' : 'Showed'} ${d.name} $span of "${s.name}"',
    );
  }

  /// `sheets.group_dimension` (Sheets 12 §3.4, P2): groups [start, start +
  /// count) `depth` times (nested), ungroups it, or collapses/expands the
  /// groups spanning exactly those rows/columns.
  static Future<ToolResult> groupDimension(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final d = _dimension(a.string('dimension'));
    final (s, start, count) = _span(t, a, d);
    final end = start + count - 1;
    final action = a.string('action') ?? 'group';
    final depth = (a.integer('depth') ?? 1).clamp(1, 8);
    final collapsed = a.boolean('collapsed');
    final span = _spanA1(d, start, count);
    final axis = s.axis(d);
    final startId = axis.idAt(start);
    final endId = axis.idAt(end);
    List<String> exact(WorkbookModel m) => [
      for (final g
          in m.sheet(s.id)?.groups.values ?? const <DimensionGroupRecord>[])
        if (g.dimension == d && g.startId == startId && g.endId == endId) g.id,
    ];
    final steps = <SheetsPlanStep>[];
    final created = <String>[];
    switch (action) {
      case 'group':
        for (var i = 0; i < depth; i++) {
          steps.add((model, pctx) {
            final plan = SheetsWrites.planner.plan(
              GroupOperation(
                s.id,
                d,
                GroupAction.group,
                start: start,
                end: end,
              ),
              model,
              pctx,
            );
            final id = plan.result['groupId'];
            if (id is String) created.add(id);
            return plan;
          });
        }
      case 'ungroup':
        steps.add(
          _op(
            () => GroupOperation(
              s.id,
              d,
              GroupAction.ungroup,
              start: start,
              end: end,
            ),
          ),
        );
      case 'collapse' || 'expand':
        final ids = exact(t.model);
        if (ids.isEmpty) {
          throw McpToolException(
            McpErrorCode.notFound,
            'No group spans exactly $span of "${s.name}"; group it first.',
          );
        }
        for (final id in ids) {
          steps.add(
            _op(
              () => GroupOperation(
                s.id,
                d,
                action == 'collapse'
                    ? GroupAction.collapse
                    : GroupAction.expand,
                groupId: id,
              ),
            ),
          );
        }
      default:
        throw McpToolException.invalidArgs('Unknown action "$action".');
    }
    final label = SheetsMcp.label(
      ctx,
      'sheets.group_dimension',
      '${s.name}!$span',
    );
    var o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.group_dimension',
      label: label,
      structural:
          '${action[0].toUpperCase()}${action.substring(1)} ${d.name} $span',
      steps: steps,
    );
    if (action == 'group' && collapsed == true && created.isNotEmpty) {
      // Collapsing a group created by this call updates a row inserted in
      // the same change, which the batched writer applies as a separate
      // write; both become one composite change (one change_id).
      final first = o;
      final second = await SheetsWrites.run(
        ctx,
        t,
        tool: 'sheets.group_dimension',
        label: label,
        structural: 'Collapse ${d.name} $span',
        steps: [
          _op(
            () => GroupOperation(
              s.id,
              d,
              GroupAction.collapse,
              groupId: created.first,
            ),
          ),
        ],
      );
      final ids = [
        for (final x in [first, second])
          if (x.changeId != null) x.changeId!.uuid,
      ];
      final combined = ids.length < 2
          ? null
          : await SheetsChanges.composite(
              ctx.session,
              actor: ctx.actor,
              item: t.item,
              changeIds: ids,
              label: label,
            );
      o = SheetsWriteOutcome(
        changeId: combined ?? second.changeId ?? first.changeId,
        plans: [...first.plans, ...second.plans],
        cellsAffected: first.cellsAffected,
        warnings: [...first.warnings, ...second.warnings],
        preview: first.preview,
        callId: first.callId,
      );
    }
    final verb = switch (action) {
      'group' => depth > 1 ? 'Grouped ($depth levels)' : 'Grouped',
      'ungroup' => 'Ungrouped',
      'collapse' => 'Collapsed the group of',
      _ => 'Expanded the group of',
    };
    return _result(o, '$verb ${d.name} $span of "${s.name}"', {
      'range': SheetsMcp.a1(
        t.model,
        s.id,
        d == Dimension.rows
            ? GridRect(start, 0, end, math.max(0, s.columns.length - 1))
            : GridRect(0, start, math.max(0, s.rows.length - 1), end),
      ),
      if (created.isNotEmpty) 'group_ids': created,
    });
  }

  static Future<ToolResult> setFrozen(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final s = SheetsMcp.sheet(t, a.requireString('sheet'));
    final rows = a.integer('rows');
    final cols = a.integer('columns');
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.set_frozen',
      label: SheetsMcp.label(ctx, 'sheets.set_frozen', s.name),
      structural: 'Freeze ${rows ?? '-'} rows, ${cols ?? '-'} columns',
      steps: [_op(() => SetFrozen(s.id, rows: rows, columns: cols))],
    );
    return _result(o, 'Updated frozen rows/columns of "${s.name}"');
  }

  // --------------------------------------------------------------- sheets

  static Map<String, Object?> _sheetJson(WorkbookModel m, String id) {
    final s = m.sheet(id);
    if (s == null) return {'id': id};
    return {
      'name': s.name,
      'id': s.id,
      'index': m.sheets.indexWhere((x) => x.id == id) + 1,
    };
  }

  static void _checkSheetName(SheetsTarget t, String name, {String? except}) {
    final existing = t.model.sheetByName(name);
    if (existing != null && existing.id != except) {
      throw McpToolException(
        SheetsErrorCode.duplicateName,
        'A sheet named "${existing.name}" already exists.',
      );
    }
  }

  static Future<ToolResult> addSheet(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final name = a.string('name')?.trim();
    if (name != null) _checkSheetName(t, name);
    final values = a.list('values');
    final raw = false;
    if (values != null) {
      SheetsValueHandlers.checkWriteLimit(
        values.fold(0, (n, r) => n + (r as List).length),
      );
      SheetsValueHandlers.checkFormulas(values, raw: raw);
    }
    final id = const Uuid().v7();
    final rows = a.integer('rows') ?? 1000;
    final cols = a.integer('columns') ?? 26;
    final index = a.integer('index');
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.add_sheet',
      label: SheetsMcp.label(ctx, 'sheets.add_sheet', name),
      structural: 'Add sheet${name == null ? '' : ' "$name"'}',
      steps: [
        _op(
          () => AddSheet(
            name: name,
            index: index == null ? null : index - 1,
            rows: rows,
            columns: cols,
            sheetId: id,
          ),
        ),
        if (values != null && values.isNotEmpty)
          (model, pctx) => SheetsWrites.planner.plan(
            SetCellInputs(
              sheetId: id,
              row: 0,
              col: 0,
              inputs: SheetsValueHandlers.inputs(
                t.wb,
                id,
                0,
                0,
                values,
                raw: raw,
              ),
              growGrid: true,
            ),
            model,
            pctx,
          ),
      ],
    );
    final sheet = _sheetJson(SheetsWrites.modelAfter(ctx, t), id);
    return _result(o, 'Added sheet "${sheet['name'] ?? name}"', {
      'sheet': sheet,
    });
  }

  static Future<ToolResult> renameSheet(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final s = SheetsMcp.sheet(t, a.requireString('sheet'));
    final name = a.requireString('new_name').trim();
    _checkSheetName(t, name, except: s.id);
    final old = s.name;
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.rename_sheet',
      label: SheetsMcp.label(ctx, 'sheets.rename_sheet', '"$old" → "$name"'),
      structural: 'Rename sheet "$old" to "$name"',
      intents: (model) => [SheetOp(s.id, 'rename')],
      steps: [_op(() => RenameSheet(s.id, name))],
    );
    return _result(o, 'Renamed "$old" to "$name"', {
      'sheet': {'name': name, 'id': s.id},
    });
  }

  static Future<ToolResult> deleteSheet(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final s = SheetsMcp.sheet(t, a.requireString('sheet'));
    final visible = t.model.visibleSheets;
    if (visible.length == 1 && visible.first.id == s.id) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'The last visible sheet cannot be deleted.',
      );
    }
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.delete_sheet',
      label: SheetsMcp.label(ctx, 'sheets.delete_sheet', '"${s.name}"'),
      structural: 'Delete sheet "${s.name}"',
      intents: (model) => [SheetOp(s.id, 'delete')],
      confirmIf: (plans, model) =>
          'The assistant wants to delete the sheet "${s.name}" with all its '
          'data.',
      steps: [_op(() => DeleteSheet(s.id))],
    );
    return _result(o, 'Deleted sheet "${s.name}"');
  }

  static Future<ToolResult> duplicateSheet(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final s = SheetsMcp.sheet(t, a.requireString('sheet'));
    final name = a.string('new_name')?.trim();
    if (name != null) _checkSheetName(t, name);
    final index = a.integer('index');
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.duplicate_sheet',
      label: SheetsMcp.label(ctx, 'sheets.duplicate_sheet', '"${s.name}"'),
      structural: 'Duplicate sheet "${s.name}"',
      steps: [
        _op(
          () => DuplicateSheet(
            s.id,
            name: name,
            index: index == null ? null : index - 1,
          ),
        ),
      ],
    );
    final id = o.result['sheetId'] as String?;
    return _result(o, 'Duplicated "${s.name}"', {
      if (id != null) 'sheet': _sheetJson(SheetsWrites.modelAfter(ctx, t), id),
    });
  }

  static Future<ToolResult> reorderSheet(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final s = SheetsMcp.sheet(t, a.requireString('sheet'));
    final index = a.integer('index')!;
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.reorder_sheet',
      label: SheetsMcp.label(ctx, 'sheets.reorder_sheet', '"${s.name}"'),
      structural: 'Move sheet "${s.name}" to position $index',
      intents: (model) => [SheetOp(s.id, 'move')],
      steps: [_op(() => MoveSheet(s.id, index - 1))],
    );
    return _result(o, 'Moved "${s.name}" to position $index');
  }

  static Future<ToolResult> setSheetProperties(
    ToolContext ctx,
    ToolArgs a,
  ) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final s = SheetsMcp.sheet(t, a.requireString('sheet'));
    final clearTab = a.present('tab_color') && a.values['tab_color'] == null;
    final tab = a.has('tab_color')
        ? color(a.string('tab_color'), 'tab_color')
        : null;
    final hidden = a.boolean('hidden');
    if (hidden == true) {
      final visible = t.model.visibleSheets;
      if (visible.length == 1 && visible.first.id == s.id) {
        throw McpToolException(
          McpErrorCode.invalidArgs,
          'The last visible sheet cannot be hidden.',
        );
      }
    }
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.set_sheet_properties',
      label: SheetsMcp.label(ctx, 'sheets.set_sheet_properties', '"${s.name}"'),
      structural: 'Change properties of "${s.name}"',
      intents: (model) => [SheetOp(s.id, 'properties')],
      steps: [
        _op(
          () => SetSheetProperties(
            s.id,
            tabColor: tab,
            clearTabColor: clearTab,
            hidden: hidden,
            showGridlines: a.boolean('show_gridlines'),
            rightToLeft: a.boolean('right_to_left'),
          ),
        ),
      ],
    );
    return _result(o, 'Updated "${s.name}"');
  }

  // --------------------------------------------------------------- merges

  static Future<ToolResult> mergeCells(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final r = SheetsMcp.range(t, a.requireString('range'));
    if (r.rect.isSingleCell) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'Select more than one cell to merge.',
      );
    }
    final mode = switch (a.string('type')) {
      'horizontal' => MergeMode.horizontal,
      'vertical' => MergeMode.vertical,
      _ => MergeMode.all,
    };
    final a1 = t.model.a1Of(r);
    var dropped = 0;
    final s = t.model.sheet(r.sheetId)!;
    for (final (row, col, cell) in s.cellsIn(r.rect, contentOnly: true)) {
      final keep = switch (mode) {
        MergeMode.all => row == r.rect.top && col == r.rect.left,
        MergeMode.horizontal => col == r.rect.left,
        MergeMode.vertical => row == r.rect.top,
      };
      if (!keep && cell.content != null) dropped++;
    }
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.merge_cells',
      label: SheetsMcp.label(ctx, 'sheets.merge_cells', a1),
      ranges: [a1],
      intents: (model) => [
        RuleWrite(r.sheetId, RuleKind.merge, [r.rect]),
      ],
      steps: [
        _op(() => MergeCells([r], mode: mode, force: true)),
      ],
    );
    return _result(o, 'Merged $a1', {
      'merged': [a1],
      if (dropped > 0)
        'warnings': [...o.warnings, 'Only the top-left value was kept'],
    });
  }

  static Future<ToolResult> unmergeCells(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final r = SheetsMcp.range(t, a.requireString('range'));
    final a1 = t.model.a1Of(r);
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.unmerge_cells',
      label: SheetsMcp.label(ctx, 'sheets.unmerge_cells', a1),
      ranges: [a1],
      intents: (model) => [
        RuleWrite(r.sheetId, RuleKind.merge, [r.rect]),
      ],
      steps: [
        _op(() => UnmergeCells([r])),
      ],
    );
    return _result(o, 'Unmerged $a1');
  }
}
