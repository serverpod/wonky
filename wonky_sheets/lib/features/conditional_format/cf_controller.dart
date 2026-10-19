import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:wonky_sheets_core/formula.dart'
    show FNumber, GridRect, RecalcBatch;
import 'package:wonky_sheets_core/model.dart';

import '../grid/paint/grid_layer.dart';
import '../sheet_editor/sheet_editor_controller.dart';

/// Conditional formatting of an open spreadsheet (06 §15.8–15.10): owns the
/// core [CfEvaluator], plugs it into the grid's `CellRenderCache.conditional`
/// hook, keeps its caches valid (model batches, recalculations, the midnight
/// tick of relative dates), previews the rule being edited (draft) and the
/// ranges of a hovered rule.
class CfController extends ChangeNotifier {
  CfController(this.editor) {
    _evaluator = _create();
    editor.cells.conditional = _overlay;
    editor.cells.conditionalAt = _appliesAt;
    editor.cells.invalidate();
    editor.model.addListener(_onBatch);
    _recalc = editor.engine.changes.listen(_onRecalc);
    _scheduleMidnight();
  }

  final SheetEditorController editor;
  late CfEvaluator _evaluator;
  StreamSubscription<Object?>? _recalc;
  Timer? _midnight;
  String _locale = '';
  String _timeZone = '';

  /// Ranges of the rule hovered in the panel list (painted on the grid).
  final ValueNotifier<List<GridRect>?> highlight = ValueNotifier(null);

  /// The rules panel's draft (previewed, never persisted).
  CfDraft? get draft => _evaluator.draft;

  /// The evaluator (tests, MCP `formatted` reads).
  CfEvaluator get evaluator => _evaluator;

  WorkbookModel get model => editor.model;

  CfEvaluator _create() {
    final s = model.spreadsheet;
    _locale = s.locale;
    _timeZone = s.timeZone;
    return CfEvaluator(
        model,
        editor.engine,
        FormatterDisplayText(locale: s.locale),
        editor.hooks,
        dates: SpreadsheetDates(timeZone: s.timeZone),
        locale: s.locale,
      )
      ..asyncStats = _bigStats
      ..asyncStatsCells = bigStatsCells;
  }

  // ---------------------------------------------------------------------------
  // Statistics of large ranges (06 §15.10).

  /// Rules covering more cells than this get their statistics in the
  /// background (values read in chunks between frames, sorted in an
  /// isolate; web: same thread, chunked).
  static int bigStatsCells = 100000;

  /// Cells read per chunk.
  static const _chunk = 20000;

  final Map<String, _BigStats> _big = {};
  final Map<String, int> _contentGen = {};
  final Set<String> _computing = {};
  bool _disposed = false;

  /// Whether background statistics are being computed (tests).
  bool get computingStats => _computing.isNotEmpty;

  /// Completes when no background statistics are pending (tests).
  Future<void> statsIdle() async {
    while (_computing.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  RangeStats? _bigStats(String sheetId, String ruleId, List<GridRect> rects) {
    final key = rects.map((r) => r.a1).join(',');
    final gen = _contentGen[sheetId] ?? 0;
    final e = _big[ruleId];
    final fresh = e != null && e.key == key && e.gen == gen;
    if (!fresh && !_computing.contains(ruleId)) {
      unawaited(_computeBig(sheetId, ruleId, rects, key, gen));
    }
    // Stale stats keep the scale steady until the new ones are ready.
    return e != null && e.key == key ? e.stats : null;
  }

  Future<void> _computeBig(
    String sheetId,
    String ruleId,
    List<GridRect> rects,
    String key,
    int gen,
  ) async {
    _computing.add(ruleId);
    try {
      final values = <double>[];
      final seen = rects.length > 1 ? <int>{} : null;
      var n = 0;
      for (final rect in rects) {
        for (var r = rect.top; r <= rect.bottom; r++) {
          for (var c = rect.left; c <= rect.right; c++) {
            if (seen != null && !seen.add(r * 0x100000 + c)) continue;
            final v = editor.engine.valueAt(sheetId, r, c);
            if (v is FNumber && v.v.isFinite) values.add(v.v);
            if (++n % _chunk == 0) {
              await Future<void>.delayed(Duration.zero);
              if (_disposed) return;
            }
          }
        }
      }
      final sorted = await compute(_sortValues, Float64List.fromList(values));
      if (_disposed) return;
      _big[ruleId] = _BigStats(key, gen, RangeStats.fromSorted(sorted));
      _evaluator.invalidateRule(ruleId);
      _repaint();
    } finally {
      _computing.remove(ruleId);
    }
    // Data changed meanwhile: refresh with the newer values.
    if (!_disposed && (_contentGen[sheetId] ?? 0) != gen) {
      _evaluator.invalidateRule(ruleId);
      _repaint();
    }
  }

  void _bumpContent(String sheetId) =>
      _contentGen[sheetId] = (_contentGen[sheetId] ?? 0) + 1;

  /// The overlay of one cell, from the evaluator (cached per rule and cell).
  ConditionalOverlay? _overlay(String sheetId, int row, int col) {
    final r = _evaluator.evaluate(sheetId, row, col);
    if (r.isEmpty) return null;
    return overlayOf(r);
  }

  /// Adapts a core [CfResult] to the display overlay of `CellDisplay`.
  static ConditionalOverlay overlayOf(CfResult r) {
    final bar = r.dataBar;
    final icon = r.icon;
    return ConditionalOverlay(
      format: r.overlay.isEmpty ? null : r.overlay,
      dataBarFraction: bar == null ? null : (bar.end - bar.start),
      dataBarStart: bar?.start ?? 0,
      dataBarColor: bar?.color,
      dataBarGradient: bar?.gradient ?? false,
      dataBarAxis: bar?.axis,
      dataBarRightToLeft: bar?.rightToLeft ?? false,
      iconSet: icon?.set.id,
      iconIndex: icon?.index,
      showValue: (bar?.showValue ?? true) && (icon?.showValue ?? true),
    );
  }

  /// Whether a rule (or the draft) covers the cell: cells outside every rule
  /// keep the grid's fast path for empty cells.
  bool _appliesAt(String sheetId, int row, int col) {
    final d = _evaluator.draft;
    if (d != null &&
        d.sheetId == sheetId &&
        d.ranges.any((r) => r.contains(row, col))) {
      return true;
    }
    final sheet = model.sheet(sheetId);
    if (sheet == null || sheet.cfRules.isEmpty) return false;
    return sheet.rulesAt(RuleKind.conditionalFormat, row, col).isNotEmpty;
  }

  /// Previews [d] (null clears the preview).
  void setDraft(CfDraft? d) {
    _evaluator.setDraft(d);
    _repaint();
  }

  void _repaint() {
    editor.cells.invalidate();
    editor.contentSignal.fire();
  }

  // ---------------------------------------------------------------------------
  // Invalidation (06 §15.10).

  void _onBatch(WorkbookChangeBatch batch) {
    var all = false;
    for (final e in batch.events) {
      switch (e) {
        case SpreadsheetChanged(:final columns):
          final s = model.spreadsheet;
          if (s.locale != _locale || s.timeZone != _timeZone) {
            final d = _evaluator.draft;
            _evaluator = _create();
            _evaluator.setDraft(d);
          } else if (columns.contains('themeJson')) {
            all = true;
          }
        case StructureChanged() || SheetsChanged() || NamesChanged():
          all = true;
        case RulesChanged(:final kind, :final ruleIds):
          if (kind == RuleKind.conditionalFormat) {
            for (final id in ruleIds) {
              _evaluator.invalidateRule(id);
            }
          }
        case CellsChanged(:final sheetId, :final contentKeys):
          if (contentKeys.isEmpty) continue;
          _bumpContent(sheetId);
          _invalidateFormulaRules(sheetId);
          _evaluator.invalidateCells(sheetId, contentKeys);
        case OtherRowsChanged():
          break;
      }
    }
    if (all) _evaluator.invalidateAll();
    // A previewed draft may read the changed cells on a sheet without rules
    // (the render cache drops only sheets with rules, CQ-41).
    if (draft != null) editor.cells.invalidate();
    if (highlight.value != null) _refreshHighlight();
    notifyListeners();
  }

  /// Whether a rule's result may depend on cells other than its own.
  static bool _readsOtherCells(String ruleJson) => ruleJson.contains('"=');

  /// Whether a rule's formulas may read another sheet.
  static bool _readsOtherSheets(String ruleJson) =>
      _readsOtherCells(ruleJson) && ruleJson.contains('!');

  /// Drops the rules whose formulas (custom formulas, `=` values, formula
  /// thresholds) may read cells of [sheetId]: formula rules of that sheet
  /// and cross-sheet formula rules of the others.
  void _invalidateFormulaRules(String sheetId) {
    for (final sheet in model.sheets) {
      final same = sheet.id == sheetId;
      for (final rec in sheet.cfRules.values) {
        if (same
            ? _readsOtherCells(rec.ruleJson)
            : _readsOtherSheets(rec.ruleJson)) {
          _evaluator.invalidateRule(rec.id);
        }
      }
    }
    if (_evaluator.draft case final CfDraft d) {
      final json = d.rule.encode();
      if (d.sheetId == sheetId
          ? _readsOtherCells(json)
          : _readsOtherSheets(json)) {
        _evaluator.invalidateRule(d.ruleId);
      }
    }
  }

  /// Above this many changed cells a recalculation drops every cache.
  static const _maxFineInvalidation = 20000;

  void _onRecalc(RecalcBatch batch) {
    // Only what the changed formula results can affect (06 §15.10): the
    // cached results of those cells, rules with range statistics over them
    // (invalidateCells) and formula rules that may read them.
    if (batch.cells.length > _maxFineInvalidation) {
      _evaluator.invalidateAll();
      _repaint();
      return;
    }
    final bySheet = <String, List<CellKey>>{};
    for (final c in batch.cells) {
      final sheet = model.sheet(c.sheetId);
      final rowId = sheet?.rows.tryIdAt(c.row);
      final colId = sheet?.columns.tryIdAt(c.col);
      if (rowId == null || colId == null) continue;
      (bySheet[c.sheetId] ??= []).add((rowId: rowId, colId: colId));
    }
    for (final e in batch.spillRects.entries) {
      final sheet = model.sheet(e.key);
      if (sheet == null) continue;
      final keys = bySheet[e.key] ??= [];
      for (final r in e.value) {
        // Spill areas are bounded by the engine; cap to stay cheap.
        if (r.rowCount * r.colCount > _maxFineInvalidation) {
          _evaluator.invalidateAll();
          _repaint();
          return;
        }
        for (var row = r.top; row <= r.bottom; row++) {
          final rowId = sheet.rows.tryIdAt(row);
          if (rowId == null) continue;
          for (var col = r.left; col <= r.right; col++) {
            final colId = sheet.columns.tryIdAt(col);
            if (colId != null) keys.add((rowId: rowId, colId: colId));
          }
        }
      }
    }
    if (bySheet.isEmpty) return;
    for (final e in bySheet.entries) {
      _bumpContent(e.key);
      _invalidateFormulaRules(e.key);
      _evaluator.invalidateCells(e.key, e.value);
    }
    // The editor's render cache already dropped the sheets with rules
    // (CellRenderCache.invalidateRecalc); a previewed draft may sit on a
    // sheet without rules.
    if (draft != null) {
      _repaint();
    } else {
      editor.contentSignal.fire();
    }
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = clock.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), () {
      _evaluator.invalidateAll();
      _repaint();
      _scheduleMidnight();
    });
  }

  // ---------------------------------------------------------------------------
  // Queries for the panel.

  /// Rules of [sheetId] in priority order (`(sortKey, id)`).
  List<CfRuleRecord> rulesOf(String sheetId) {
    final sheet = model.sheet(sheetId);
    if (sheet == null) return const [];
    return sheet.cfRules.values.toList()..sort((a, b) {
      final c = a.sortKey.compareTo(b.sortKey);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  }

  /// The resolved rectangles of a rule.
  List<GridRect> rectsOf(String sheetId, String ruleId) {
    final sheet = model.sheet(sheetId);
    if (sheet == null) return const [];
    return sheet.ruleRects(RuleKind.conditionalFormat, ruleId);
  }

  String? _highlightRule;
  String? _highlightSheet;

  /// Highlights the ranges of [ruleId] (null clears).
  void hoverRule(String sheetId, String? ruleId) {
    _highlightRule = ruleId;
    _highlightSheet = sheetId;
    _refreshHighlight();
  }

  void _refreshHighlight() {
    final id = _highlightRule;
    final sid = _highlightSheet;
    highlight.value = id == null || sid == null || sid != editor.activeSheetId
        ? null
        : rectsOf(sid, id);
  }

  @override
  void dispose() {
    _disposed = true;
    editor.model.removeListener(_onBatch);
    unawaited(_recalc?.cancel());
    _midnight?.cancel();
    if (identical(editor.cells.conditionalAt, _appliesAt)) {
      editor.cells.conditional = null;
      editor.cells.conditionalAt = null;
      editor.cells.invalidate();
    }
    highlight.dispose();
    super.dispose();
  }
}

/// Outlines the ranges of the rule hovered in the CF/banding panels.
class RangeHighlightLayer extends GridLayer {
  RangeHighlightLayer(this.ranges);

  final ValueListenable<List<GridRect>?> ranges;

  @override
  int get zOrder => GridZ.presence + 20;

  @override
  Listenable? get repaint => ranges;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final list = ranges.value;
    if (list == null || list.isEmpty) return;
    final color = ctx.tokens.selectionBorder;
    final fill = Paint()..color = color.withValues(alpha: 0.08);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    ctx.forEachPane(canvas, (pane) {
      if (pane.isEmpty) return;
      for (final r in list) {
        final rect = pane.rangeRect(r);
        if (rect.isEmpty) continue;
        canvas.drawRect(rect, fill);
        _dashed(canvas, rect.deflate(1), stroke);
      }
    });
  }

  static void _dashed(Canvas canvas, Rect r, Paint p) {
    const dash = 6.0;
    const gap = 4.0;
    void line(Offset a, Offset b) {
      final len = (b - a).distance;
      if (len <= 0) return;
      final dir = (b - a) / len;
      for (var t = 0.0; t < len; t += dash + gap) {
        canvas.drawLine(
          a + dir * t,
          a + dir * (t + dash > len ? len : t + dash),
          p,
        );
      }
    }

    line(r.topLeft, r.topRight);
    line(r.topRight, r.bottomRight);
    line(r.bottomRight, r.bottomLeft);
    line(r.bottomLeft, r.topLeft);
  }
}

/// Background statistics of one rule.
class _BigStats {
  _BigStats(this.key, this.gen, this.stats);

  /// The rule's ranges (A1) and the content generation they were read at.
  final String key;
  final int gen;
  final RangeStats stats;
}

/// Sorts numbers ascending (runs in an isolate on native).
Float64List _sortValues(Float64List v) => v..sort();
