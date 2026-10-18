import 'dart:convert';

import 'package:wonky_sync_models/ids.dart';

import '../../addressing/grid_geometry.dart';
import '../../engine_bridge/formula_hooks.dart';
import '../../engine_bridge/stored_formula.dart';
import '../../model/events.dart';
import '../../model/grid_range.dart';
import '../../model/records.dart';
import '../../model/schema.dart';
import '../../model/sheet_model.dart';
import '../operations.dart';
import '../plan_builder.dart';
import '../row_change.dart';
import 'helpers.dart';

const Set<String> _cellDataColumns = {
  CellCols.content,
  CellCols.note,
  CellCols.numberFormat,
  CellCols.fontFamily,
  CellCols.fontSize,
  CellCols.bold,
  CellCols.italic,
  CellCols.underline,
  CellCols.strikethrough,
  CellCols.textColor,
  CellCols.fillColor,
  CellCols.hAlign,
  CellCols.vAlign,
  CellCols.wrap,
  CellCols.rotation,
  CellCols.borderTop,
  CellCols.borderRight,
  CellCols.borderBottom,
  CellCols.borderLeft,
  CellCols.linkUrl,
};

/// The data columns of a cell (content, note, formats) with nulls for unset.
Map<String, Object?> cellData(Map<String, Object?>? cell) => {
  for (final k in _cellDataColumns) k: cell?[k],
};

/// Ensures [s] has at least [rows] × [cols]; returns `(rowIdAt, colIdAt)`.
(String Function(int), String Function(int)) ensureGridSize(
  PlanBuilder b,
  SheetModel s,
  int rows,
  int cols,
) {
  final needRows = rows - s.rows.length;
  final needCols = cols - s.columns.length;
  final extraRows = <String>[];
  final extraCols = <String>[];
  if (needRows > 0 || needCols > 0) {
    b.checkCellLimit(
      b.gridCellsWith(
        s.id,
        rows > s.rows.length ? rows : s.rows.length,
        cols > s.columns.length ? cols : s.columns.length,
      ),
    );
    extraRows.addAll(b.appendDimension(s, Dimension.rows, needRows));
    extraCols.addAll(b.appendDimension(s, Dimension.columns, needCols));
  }
  return (
    (i) => i < s.rows.length ? s.rows.idAt(i) : extraRows[i - s.rows.length],
    (i) => i < s.columns.length
        ? s.columns.idAt(i)
        : extraCols[i - s.columns.length],
  );
}

/// Refuses writes that would break apart merges in [dest] of [s], ignoring
/// merges in [ignore].
void checkMergesNotSplit(
  SheetModel s,
  GridRect dest, {
  Set<String> ignore = const {},
}) {
  for (final (id, m) in s.mergesIntersecting(dest)) {
    if (ignore.contains(id)) continue;
    if (!dest.containsRect(m)) {
      throw const PlanException(
        'merge_conflict',
        "You can't paste here because it would break apart a merged cell",
      );
    }
  }
}

/// [MoveRange]: move (cut/paste, drag) or copy a block (03 §11, §12.6).
MutationPlan planMoveRange(PlanBuilder b, MoveRange op) {
  applyMoveRange(b, op);
  return b.build(
    op.copy ? 'Copy' : 'Move',
    kinds: [ChangeKinds.values, ChangeKinds.format],
  );
}

/// Adds the writes of [op] to [b].
void applyMoveRange(PlanBuilder b, MoveRange op) {
  final src = b.sheetOf(op.source.sheetId);
  final dst = b.sheetOf(op.destSheetId);
  final s = op.source.rect;
  b.checkRect(src, s);
  final d = GridRect(
    op.destRow,
    op.destCol,
    op.destRow + s.rowCount - 1,
    op.destCol + s.colCount - 1,
  );
  if (d.top < 0 || d.left < 0) {
    throw const PlanException('invalid_range', 'Destination outside the grid');
  }
  if (!op.copy) {
    applyBlockMove(b, src, dst, [(s, d)]);
    return;
  }
  final (rowIdAt, colIdAt) = ensureGridSize(b, dst, d.bottom + 1, d.right + 1);
  final srcMerges = _mergesInside(src, [s]);
  if (d.bottom < dst.rows.length && d.right < dst.columns.length) {
    checkMergesNotSplit(dst, d);
  }
  // Snapshot source cells.
  final snapshot = <(int, int), Map<String, Object?>>{};
  for (final (r, c, _, _, cur) in b.cellsIn(src, s)) {
    snapshot[(r - s.top, c - s.left)] = cellData(cur);
  }
  final hooks = b.ctx.formulas;
  // Write the destination.
  for (var r = 0; r < s.rowCount; r++) {
    for (var c = 0; c < s.colCount; c++) {
      final rowId = rowIdAt(d.top + r);
      final colId = colIdAt(d.left + c);
      final data = snapshot[(r, c)];
      if (data == null) {
        b.deleteCell(dst.id, rowId, colId);
        continue;
      }
      final out = Map<String, Object?>.of(data);
      final content = out[CellCols.content] as String?;
      if (content != null && content.startsWith('=') && hooks != null) {
        out[CellCols.content] = hooks.translate(
          content,
          fromSheetId: src.id,
          fromRow: s.top + r,
          fromCol: s.left + c,
          toSheetId: dst.id,
          toRow: d.top + r,
          toCol: d.left + c,
        );
      }
      b.writeCell(dst.id, rowId, colId, out);
    }
  }
  // Destination merges overwritten.
  if (d.bottom < dst.rows.length && d.right < dst.columns.length) {
    for (final (id, m) in dst.mergesIntersecting(d)) {
      if (d.containsRect(m) && !srcMerges.any((e) => e.$1 == id)) {
        b.delete(SheetsTables.mergedRange, id);
      }
    }
  }
  for (final (_, m) in srcMerges) {
    final moved = m.shift(d.top - s.top, d.left - s.left);
    b.insert(SheetsTables.mergedRange, b.ctx.ids.newId(), {
      Cols.sheetId: dst.id,
      Cols.rangeJson: _rangeJson(dst.id, moved, rowIdAt, colIdAt),
    });
  }
  _moveValidation(b, src, s, dst, d, rowIdAt, colIdAt, copy: true);
  b.addResolvedRange(ResolvedRange(src.id, s));
  if (d.bottom < dst.rows.length && d.right < dst.columns.length) {
    b.addResolvedRange(ResolvedRange(dst.id, d));
  }
}

/// Moves the source rectangles of [blocks] (disjoint, on [src]) to their
/// destination rectangles (same sizes, on [dst]) as one move (03 §11,
/// §12.6): cells (content, note, formats), whole merges and validation travel;
/// formulas inside moved cells and everywhere else follow references (single
/// cells and ranges entirely inside one block) to the destination. Cells of
/// the source not in a block (hidden rows of a compacted cut) are untouched,
/// except where a destination covers them.
void applyBlockMove(
  PlanBuilder b,
  SheetModel src,
  SheetModel dst,
  List<(GridRect source, GridRect dest)> blocks,
) {
  if (blocks.isEmpty) return;
  if (dst.id == src.id && blocks.every((e) => e.$1 == e.$2)) return;
  var bottom = 0;
  var right = 0;
  for (final (s, d) in blocks) {
    b.checkRect(src, s);
    if (d.top < 0 || d.left < 0) {
      throw const PlanException(
        'invalid_range',
        'Destination outside the grid',
      );
    }
    if (d.bottom > bottom) bottom = d.bottom;
    if (d.right > right) right = d.right;
  }
  final (rowIdAt, colIdAt) = ensureGridSize(b, dst, bottom + 1, right + 1);
  final sources = [for (final (s, _) in blocks) s];
  final srcMerges = _mergesInside(src, sources);
  for (final s in sources) {
    for (final (_, m) in src.mergesIntersecting(s)) {
      if (!s.containsRect(m)) {
        throw const PlanException(
          'merge_conflict',
          "You can't move only part of a merged cell",
        );
      }
    }
  }
  final ignore = {
    if (dst.id == src.id)
      for (final (id, _) in srcMerges) id,
  };
  for (final (_, d) in blocks) {
    if (d.bottom < dst.rows.length && d.right < dst.columns.length) {
      checkMergesNotSplit(dst, d, ignore: ignore);
    }
  }
  // Snapshot source cells.
  final snapshot = <(int, int), Map<String, Object?>>{};
  for (final s in sources) {
    for (final (r, c, _, _, cur) in b.cellsIn(src, s)) {
      snapshot[(r, c)] = cellData(cur);
    }
  }
  final hooks = b.ctx.formulas;
  // Clear the sources; destinations are written below.
  for (final s in sources) {
    for (final (_, _, rowId, colId, _) in b.cellsIn(src, s).toList()) {
      b.deleteCell(src.id, rowId, colId);
    }
  }
  for (final (s, d) in blocks) {
    for (var r = 0; r < s.rowCount; r++) {
      for (var c = 0; c < s.colCount; c++) {
        final rowId = rowIdAt(d.top + r);
        final colId = colIdAt(d.left + c);
        final data = snapshot[(s.top + r, s.left + c)];
        if (data == null) {
          b.deleteCell(dst.id, rowId, colId);
          continue;
        }
        final out = Map<String, Object?>.of(data);
        final content = out[CellCols.content] as String?;
        if (content != null && content.startsWith('=') && hooks != null) {
          // Same-sheet references are pinned to the source sheet first so
          // they keep their target when the cell lands on another sheet.
          final pinned = dst.id == src.id
              ? content
              : _pinSheet(content, src.id);
          out[CellCols.content] =
              remapBlocks(hooks, pinned, dst.id, src.id, dst.id, blocks) ??
              pinned;
        }
        b.writeCell(dst.id, rowId, colId, out);
      }
    }
  }
  // Destination merges overwritten.
  for (final (_, d) in blocks) {
    if (d.bottom >= dst.rows.length || d.right >= dst.columns.length) continue;
    for (final (id, m) in dst.mergesIntersecting(d)) {
      if (d.containsRect(m) && !ignore.contains(id)) {
        b.delete(SheetsTables.mergedRange, id);
      }
    }
  }
  for (final (id, m) in srcMerges) {
    final (s, d) = blocks.firstWhere((e) => e.$1.containsRect(m));
    final json = _rangeJson(
      dst.id,
      m.shift(d.top - s.top, d.left - s.left),
      rowIdAt,
      colIdAt,
    );
    if (dst.id == src.id) {
      b.update(SheetsTables.mergedRange, id, {Cols.rangeJson: json});
    } else {
      b.delete(SheetsTables.mergedRange, id);
      b.insert(SheetsTables.mergedRange, b.ctx.ids.newId(), {
        Cols.sheetId: dst.id,
        Cols.rangeJson: json,
      });
    }
  }
  for (final (s, d) in blocks) {
    _moveValidation(
      b,
      src,
      s,
      dst,
      d,
      rowIdAt,
      colIdAt,
      copy: false,
      blocks: blocks,
    );
  }
  if (hooks != null) _remapReferences(b, src, dst, blocks);
  for (final (s, d) in blocks) {
    b.addResolvedRange(ResolvedRange(src.id, s));
    if (d.bottom < dst.rows.length && d.right < dst.columns.length) {
      b.addResolvedRange(ResolvedRange(dst.id, d));
    }
  }
}

/// Retargets the references of [stored] (hosted on [hostSheetId]) that lie
/// entirely inside one source rectangle of [blocks] to its destination. Each
/// reference is mapped at most once, even when a destination overlaps
/// another block's source. Null when nothing changes.
String? remapBlocks(
  FormulaHooks hooks,
  String stored,
  String hostSheetId,
  String sourceSheetId,
  String destSheetId,
  List<(GridRect source, GridRect dest)> blocks,
) {
  final results = <String>[];
  for (final (s, d) in blocks) {
    final r = hooks.remap(
      stored,
      hostSheetId: hostSheetId,
      sourceSheetId: sourceSheetId,
      source: s,
      destSheetId: destSheetId,
      dest: d,
    );
    if (r != null && r != stored) results.add(r);
  }
  if (results.isEmpty) return null;
  if (results.length == 1) return results.single;
  final base = StoredFormula.tokens(stored);
  final mapped = [for (final r in results) StoredFormula.tokens(r)];
  if (mapped.any((m) => m.length != base.length)) {
    // A reference became #REF!: token positions no longer align; map
    // sequentially (only possible when a destination leaves the grid).
    var out = stored;
    for (final (s, d) in blocks) {
      out =
          hooks.remap(
            out,
            hostSheetId: hostSheetId,
            sourceSheetId: sourceSheetId,
            source: s,
            destSheetId: destSheetId,
            dest: d,
          ) ??
          out;
    }
    return out;
  }
  final merged = [
    for (var i = 0; i < base.length; i++)
      mapped
              .map((m) => m[i])
              .where((t) => t.encode() != base[i].encode())
              .firstOrNull ??
          base[i],
  ];
  var i = 0;
  return StoredFormula.mapTokens(stored, (_) => merged[i++]);
}

List<(String, GridRect)> _mergesInside(SheetModel s, List<GridRect> rects) => [
  for (final r in rects)
    for (final (id, m) in s.mergesIntersecting(r))
      if (r.containsRect(m)) (id, m),
];

String _rangeJson(
  String sheetId,
  GridRect r,
  String Function(int) rowIdAt,
  String Function(int) colIdAt,
) => GridRange(
  sheetId: sheetId,
  r1: rowIdAt(r.top),
  r2: rowIdAt(r.bottom),
  c1: colIdAt(r.left),
  c2: colIdAt(r.right),
).encode();

String _pinSheet(String stored, String sheetId) => StoredFormula.mapTokens(
  stored,
  (t) => t.sheetId == null && !t.isUnbound ? t.copyWith(sheetId: sheetId) : t,
);

void _moveValidation(
  PlanBuilder b,
  SheetModel src,
  GridRect s,
  SheetModel dst,
  GridRect d,
  String Function(int) rowIdAt,
  String Function(int) colIdAt, {
  required bool copy,
  List<(GridRect source, GridRect dest)>? blocks,
}) {
  final hooks = b.ctx.formulas;
  final moved =
      <
        (
          String criteria,
          bool strict,
          String? style,
          String? help,
          List<GridRect> rects,
        )
      >[];
  for (final rule in src.dvRules.values) {
    final rects = src.ruleRects(RuleKind.dataValidation, rule.id);
    final inside = [
      for (final r in rects)
        if (r.intersection(s) case final GridRect i) i,
    ];
    if (inside.isEmpty) continue;
    var criteria = rule.criteriaJson;
    if (hooks != null && criteria.contains('=')) {
      // Formulas are written for the rule's anchor (the top-left of its
      // first range, 06 §15.3); the moved piece gets its own anchor.
      final a = rects.first;
      final p = inside.first;
      final q = p.shift(d.top - s.top, d.left - s.left);
      criteria = mapRuleFormulas(criteria, (f) {
        if (copy) {
          return hooks.translate(
            f,
            fromSheetId: src.id,
            fromRow: a.top,
            fromCol: a.left,
            toSheetId: dst.id,
            toRow: q.top,
            toCol: q.left,
          );
        }
        // A move keeps every reference (cut semantics, like the cells'
        // formulas) except those into the moved cells, which follow them.
        var g = a.top == p.top && a.left == p.left
            ? f
            : hooks.translate(
                f,
                fromSheetId: src.id,
                fromRow: a.top,
                fromCol: a.left,
                toSheetId: src.id,
                toRow: p.top,
                toCol: p.left,
              );
        if (dst.id != src.id) g = _pinSheet(g, src.id);
        return remapBlocks(
              hooks,
              g,
              dst.id,
              src.id,
              dst.id,
              blocks ?? [(s, d)],
            ) ??
            g;
      });
    }
    moved.add((
      criteria,
      rule.strict,
      rule.displayStyle,
      rule.helpText,
      [for (final i in inside) i.shift(d.top - s.top, d.left - s.left)],
    ));
  }
  if (moved.isEmpty) return;
  // Remove validation from the moved-out source (move) and the destination.
  if (!copy) _subtractDv(b, src, [s]);
  if (d.bottom < dst.rows.length && d.right < dst.columns.length) {
    _subtractDv(b, dst, [d]);
  }
  for (final (criteria, strict, style, help, rects) in moved) {
    final ranges = [
      for (final r in rects)
        GridRange(
          sheetId: dst.id,
          r1: rowIdAt(r.top),
          r2: rowIdAt(r.bottom),
          c1: colIdAt(r.left),
          c2: colIdAt(r.right),
        ),
    ];
    b.insert(SheetsTables.dataValidationRule, b.ctx.ids.newId(), {
      Cols.sheetId: dst.id,
      Cols.rangesJson: GridRange.encodeList(ranges),
      'criteriaJson': criteria,
      'strict': strict,
      'showDropdown': style != 'plainText',
      'displayStyle': style,
      'helpText': help,
    });
  }
}

/// The rule JSON [json] (formulas written for the anchor [from]) rewritten
/// for the anchor [to] on [s], keeping what every cell evaluates; null when
/// nothing changes.
String? _reanchored(
  PlanBuilder b,
  SheetModel s,
  String? json,
  GridRect from,
  GridRect to,
) {
  final hooks = b.ctx.formulas;
  if (json == null ||
      hooks == null ||
      !json.contains('=') ||
      (from.top == to.top && from.left == to.left)) {
    return null;
  }
  final out = mapRuleFormulas(
    json,
    (f) => hooks.translate(
      f,
      fromSheetId: s.id,
      fromRow: from.top,
      fromCol: from.left,
      toSheetId: s.id,
      toRow: to.top,
      toCol: to.left,
    ),
  );
  return out == json ? null : out;
}

void _subtractDv(PlanBuilder b, SheetModel s, List<GridRect> rects) {
  for (final rule in s.dvRules.values.toList()) {
    final cur = b.current(SheetsTables.dataValidationRule, rule.id);
    if (cur == null) continue;
    final current = [
      for (final g in GridRange.parseList(cur[Cols.rangesJson] as String?))
        if (s.resolve(g) case final ResolvedRange r) r.rect,
    ];
    var remaining = current;
    for (final q in rects) {
      remaining = RectSet.subtractAll(remaining, q);
    }
    if (RectSet.sameCells(remaining, current)) continue;
    if (remaining.isEmpty) {
      b.delete(SheetsTables.dataValidationRule, rule.id);
    } else {
      b.update(SheetsTables.dataValidationRule, rule.id, {
        Cols.rangesJson: b.rangesJson(s, remaining),
        // A new first range moves the formulas' anchor.
        if (_reanchored(
              b,
              s,
              cur['criteriaJson'] as String?,
              current.first,
              remaining.first,
            )
            case final String json)
          'criteriaJson': json,
      });
    }
  }
}

/// Retargets formulas (outside the moved blocks) and id ranges fully inside
/// one moved block to its destination (05 §5.5).
void _remapReferences(
  PlanBuilder b,
  SheetModel src,
  SheetModel dst,
  List<(GridRect source, GridRect dest)> blocks,
) {
  final hooks = b.formulas;
  final srcRowIds = <String>{
    for (final (s, _) in blocks)
      for (var r = s.top; r <= s.bottom; r++) src.rows.idAt(r),
  };
  final srcTokens = StoredFormula.idTokens(srcRowIds);
  for (final sheet in b.model.sheets) {
    for (final cell in sheet.cells.formulaCells) {
      final content = cell.content;
      if (content == null || !content.startsWith('=')) continue;
      // Cells written by this plan were handled above.
      if (b.touched(SheetsTables.cell, cell.id)) continue;
      if (!StoredFormula.referencesAny(content, srcTokens)) continue;
      final r = remapBlocks(hooks, content, sheet.id, src.id, dst.id, blocks);
      if (r != null && r != content) {
        b.update(SheetsTables.cell, cell.id, {CellCols.content: r});
      }
    }
  }
  // Id ranges fully inside a source block (named ranges, CF, chart ranges).
  GridRange? remapRange(GridRange g) {
    if (g.sheetId != src.id) return null;
    final rr = src.resolve(g);
    if (rr == null || rr.wholeRows || rr.wholeColumns) return null;
    for (final (s, d) in blocks) {
      if (!s.containsRect(rr.rect)) continue;
      final m = rr.rect.shift(d.top - s.top, d.left - s.left);
      if (m.bottom >= dst.rows.length || m.right >= dst.columns.length) {
        return null;
      }
      return dst.gridRange(m);
    }
    return null;
  }

  for (final n in b.model.namedRanges) {
    final g = GridRange.tryParse(n.rangeJson);
    if (g == null) continue;
    final r = remapRange(g);
    if (r != null) {
      b.update(SheetsTables.namedRange, n.id, {Cols.rangeJson: r.encode()});
    }
  }
  _remapRules(b, src, dst, blocks, remapRange);
  for (final sheet in b.model.sheets) {
    for (final o in sheet.objects.values) {
      final spec = PlanBuilderHelpers.decodeMap(o.specJson);
      var changed = false;
      Object? walk(Object? v) {
        if (v is Map) {
          if (v['s'] is String &&
              (v.containsKey('r1') || v.containsKey('c1'))) {
            final g = GridRange.tryParse(v);
            final r = g == null ? null : remapRange(g);
            if (r != null) {
              changed = true;
              return r.toJson();
            }
            return v;
          }
          return {for (final e in v.entries) e.key: walk(e.value)};
        }
        if (v is List) return [for (final e in v) walk(e)];
        return v;
      }

      final out = walk(spec);
      if (changed) {
        b.update(SheetsTables.embeddedObject, o.id, {
          'specJson': jsonEncode(out),
        });
      }
    }
  }
}

/// Conditional formatting and data validation after a move (06 §15.3):
/// rule formulas are written for the rule's anchor, the top-left cell of its
/// first range. A CF rule whose ranges lie inside a moved block moves with
/// it (a rule moved only in part is split: the moved ranges become a new
/// rule right after it); every rule keeps its references like the cells'
/// formulas (cut semantics) except references into moved cells, which
/// follow them, and a rule whose first range changed is re-anchored.
void _remapRules(
  PlanBuilder b,
  SheetModel src,
  SheetModel dst,
  List<(GridRect source, GridRect dest)> blocks,
  GridRange? Function(GridRange) remapRange,
) {
  final hooks = b.formulas;
  String follow(String json, String host) => mapRuleFormulas(
    json,
    (f) => remapBlocks(hooks, f, host, src.id, dst.id, blocks) ?? f,
  );
  String translated(String json, GridRect from, GridRect to) =>
      _reanchored(b, src, json, from, to) ?? json;

  for (final sheet in b.model.sheets) {
    for (final rule in sheet.cfRules.values) {
      final cur = b.current(SheetsTables.conditionalFormatRule, rule.id);
      if (cur == null) continue;
      final json = cur['ruleJson'] as String;
      final ranges = GridRange.parseList(cur[Cols.rangesJson] as String?);
      final moved = <GridRange>[];
      final kept = <GridRange>[];
      GridRect? firstMovedSource;
      if (sheet.id == src.id && src.id == dst.id) {
        for (final g in ranges) {
          final rr = src.resolve(g);
          if (rr == null || rr.wholeRows || rr.wholeColumns) {
            kept.add(g);
            continue;
          }
          // The part of the range inside a block moves with it; the rest
          // stays.
          var rest = [rr.rect];
          for (final (bs, bd) in blocks) {
            final i = rr.rect.intersection(bs);
            if (i == null) continue;
            final m = i.shift(bd.top - bs.top, bd.left - bs.left);
            if (m.bottom < dst.rows.length && m.right < dst.columns.length) {
              moved.add(dst.gridRange(m));
              firstMovedSource ??= i;
            }
            rest = RectSet.subtractAll(rest, bs);
          }
          if (rest.length == 1 && rest.single == rr.rect) {
            kept.add(g);
          } else {
            kept.addAll([for (final r in rest) src.gridRange(r)]);
          }
        }
      }
      if (moved.isEmpty) {
        final out = follow(json, sheet.id);
        if (out != json) {
          b.update(SheetsTables.conditionalFormatRule, rule.id, {
            'ruleJson': out,
          });
        }
        continue;
      }
      final anchor = src.resolve(ranges.first)?.rect;
      if (anchor == null) continue;
      if (kept.isEmpty) {
        // The whole rule moves with its block.
        b.update(SheetsTables.conditionalFormatRule, rule.id, {
          Cols.rangesJson: GridRange.encodeList(moved),
          'ruleJson': follow(json, src.id),
        });
        continue;
      }
      // Split: the kept ranges stay on the rule (re-anchored when its first
      // range moved away), the moved ones become a rule of their own.
      final keptAnchor = src.resolve(kept.first)?.rect ?? anchor;
      b.update(SheetsTables.conditionalFormatRule, rule.id, {
        Cols.rangesJson: GridRange.encodeList(kept),
        'ruleJson': follow(translated(json, anchor, keptAnchor), src.id),
      });
      final keys = [
        for (final r in src.cfRules.values)
          if (b.current(SheetsTables.conditionalFormatRule, r.id)?[Cols.sortKey]
              case final String k)
            k,
      ]..sort();
      final key = cur[Cols.sortKey] as String;
      final next = keys.where((k) => k.compareTo(key) > 0).firstOrNull;
      b.insert(SheetsTables.conditionalFormatRule, b.ctx.ids.newId(), {
        Cols.sheetId: src.id,
        Cols.sortKey: FractionalIndex.between(key, next),
        Cols.rangesJson: GridRange.encodeList(moved),
        'ruleJson': follow(translated(json, anchor, firstMovedSource!), src.id),
        'enabled': cur['enabled'] ?? true,
      });
    }
    // Validation moved with the cells already (_moveValidation); the rules
    // left behind follow references into the moved cells.
    for (final rule in sheet.dvRules.values) {
      final cur = b.current(SheetsTables.dataValidationRule, rule.id);
      final json = cur?['criteriaJson'] as String?;
      if (json == null || !json.contains('=')) continue;
      final out = follow(json, sheet.id);
      if (out != json) {
        b.update(SheetsTables.dataValidationRule, rule.id, {
          'criteriaJson': out,
        });
      }
    }
  }
}

/// Re-exported for paste.
Map<String, Object?> cellDataOf(CellRecord? c) => cellData(c?.toColumns());
