import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:wonky_sheets_core/formula.dart' show CellSource, RecalcBatch;
import 'package:wonky_sheets_core/model.dart';

/// Per-cell render data of the visible window (03 §2.5 `CellRenderResolver`,
/// backed by the core `CellDisplayResolver`): formatted value, effective
/// format, colors, widget and resolved border edges. Cached per cell and
/// dropped on any model change or recalculation.
class CellRenderCache {
  CellRenderCache(this.model, this.source, {this.conditional});

  final WorkbookModel model;
  final CellSource source;

  /// Conditional formatting hook (06 §15; filled in by the CF feature).
  ConditionalOverlayProvider? conditional;

  CellSource get _source => source;

  /// Whether conditional formatting may apply at a cell (a rule or the
  /// panel's draft covers it); other empty cells keep the fast path.
  bool Function(String sheetId, int row, int col)? conditionalAt;

  /// The data validation panel's draft rule, previewed in the grid (chips,
  /// checkboxes; 07 §6.3). Call [invalidate] after changing it.
  DvDraftPreview? dvDraft;

  /// Computed default formats of overlay output (pivot headers and totals
  /// bold, 07 §7.5). Below conditional formatting; the provider leaves out
  /// attributes the user set explicitly.
  ConditionalOverlayProvider? computedFormat;

  CellDisplayResolver? _resolver;
  final Map<String, Map<int, CellDisplay?>> _cells = {};

  /// Keys of cached cells without a constant value (formulas, empty cells),
  /// per sheet: dropped on any content change ([invalidateBatch]).
  final Map<String, Set<int>> _computed = {};
  final Map<String, Map<int, CellEdges>> _edges = {};
  int _version = 0;

  /// Incremented by [invalidate].
  int get version => _version;

  CellDisplayResolver get resolver => _resolver ??= CellDisplayResolver(
    model,
    _source,
    conditional: _combinedConditional(),
    dvDraft: dvDraft,
  );

  ConditionalOverlayProvider? _combinedConditional() {
    final cf = conditional;
    final computed = computedFormat;
    if (computed == null) return cf;
    return (sheetId, row, col) {
      final a = computed(sheetId, row, col);
      final b = cf?.call(sheetId, row, col);
      if (a == null) return b;
      if (b == null) return a;
      final af = a.format;
      final bf = b.format;
      return ConditionalOverlay(
        format: af == null ? bf : (bf == null ? af : af.overlay(bf)),
        dataBarFraction: b.dataBarFraction,
        dataBarColor: b.dataBarColor,
        dataBarStart: b.dataBarStart,
      );
    };
  }

  static int _key(int row, int col) => row * 32768 + col;

  /// Cells of [sheetId] with cached display data (tests).
  @visibleForTesting
  int cachedCount(String sheetId) => _cells[sheetId]?.length ?? 0;

  /// Whether the display of a cell is cached (tests).
  @visibleForTesting
  bool isCached(String sheetId, int row, int col) =>
      _cells[sheetId]?.containsKey(_key(row, col)) ?? false;

  /// Cached cells per sheet before the cache starts over.
  static const maxEntries = 60000;

  /// Drops everything (theme, locale, rules, loading; model batches and
  /// recalculations go through [invalidateBatch] and [invalidateRecalc]).
  void invalidate() {
    _cells.clear();
    _computed.clear();
    _edges.clear();
    _resolver = null;
    _version++;
  }

  /// Above this many changed cells a batch drops everything (cheaper than
  /// mapping each one).
  static const maxFineInvalidation = 20000;

  /// Drops what a model [batch] may have changed (03 §2.7, CQ-41). A
  /// content or note edit drops the changed cells and every cached cell
  /// whose value is computed (formulas, spill and pivot output, empty
  /// cells a spill may reach: the engine is pull-based, so dependents are
  /// only known when they are read again); cells with a constant value
  /// stay. Sheets whose display reads other cells (conditional formatting,
  /// validation, pivots) are dropped whole. Format, structure, sheet, rule,
  /// name and spreadsheet changes drop everything.
  void invalidateBatch(WorkbookChangeBatch batch) {
    var all = false;
    final changed = <String, List<(int, int)>>{};
    var count = 0;
    for (final e in batch.events) {
      switch (e) {
        case CellsChanged(:final sheetId, :final formatKeys):
          _noteBorders(sheetId, formatKeys);
          if (formatKeys.isNotEmpty) {
            all = true;
            continue;
          }
          final sheet = model.sheet(sheetId);
          if (sheet == null) continue;
          final list = changed[sheetId] ??= [];
          for (final k in e.contentKeys.followedBy(e.noteKeys)) {
            if (++count > maxFineInvalidation) {
              all = true;
              break;
            }
            final r = sheet.rows.indexOf(k.rowId);
            final c = sheet.columns.indexOf(k.colId);
            if (r >= 0 && c >= 0) list.add((r, c));
          }
        case StructureChanged(:final sheetId):
          _borders.remove(sheetId);
          all = true;
        case SheetsChanged(:final sheetIds):
          sheetIds.forEach(_borders.remove);
          all = true;
        case RulesChanged() ||
            NamesChanged() ||
            SpreadsheetChanged() ||
            OtherRowsChanged():
          all = true;
      }
    }
    if (all) {
      invalidate();
      return;
    }
    if (changed.isEmpty) return;
    for (final e in changed.entries) {
      _dropCells(e.key, e.value);
    }
    _dropComputed();
    _dropValueDependentSheets();
    _version++;
  }

  /// Drops the cached cells without a constant value, in every sheet.
  void _dropComputed() {
    for (final e in _computed.entries) {
      final map = _cells[e.key];
      if (map != null) e.value.forEach(map.remove);
    }
    _computed.clear();
  }

  /// Drops the cells whose computed values changed in [batch] (formula
  /// results, spills), or everything for a very large batch (the engine
  /// caps the cells it reports).
  void invalidateRecalc(RecalcBatch batch) {
    var area = batch.cells.length;
    for (final rects in batch.spillRects.values) {
      for (final r in rects) {
        area += r.rowCount * r.colCount;
      }
    }
    if (area > maxFineInvalidation) {
      invalidate();
      return;
    }
    final bySheet = <String, List<(int, int)>>{};
    for (final c in batch.cells) {
      (bySheet[c.sheetId] ??= []).add((c.row, c.col));
    }
    for (final e in batch.spillRects.entries) {
      final list = bySheet[e.key] ??= [];
      for (final r in e.value) {
        for (var row = r.top; row <= r.bottom; row++) {
          for (var col = r.left; col <= r.right; col++) {
            list.add((row, col));
          }
        }
      }
    }
    for (final e in bySheet.entries) {
      _dropCells(e.key, e.value);
    }
    _dropValueDependentSheets();
    _version++;
  }

  void _dropCells(String sheetId, List<(int, int)> cells) {
    final map = _cells[sheetId];
    if (map == null) return;
    for (final (r, c) in cells) {
      map.remove(_key(r, c));
    }
  }

  /// Drops the sheets whose cells' display may depend on other cells'
  /// values: conditional formatting (formulas, color scales, data bars),
  /// data validation and pivot output, also across sheets.
  void _dropValueDependentSheets() {
    for (final s in model.sheets) {
      if (s.cfRules.isNotEmpty ||
          s.dvRules.isNotEmpty ||
          s.pivots.isNotEmpty ||
          dvDraft?.sheetId == s.id) {
        _cells.remove(s.id);
        _computed.remove(s.id);
      }
    }
  }

  /// Display data of the cell, or null when it shows nothing (no value,
  /// fill, border or widget).
  CellDisplay? displayAt(String sheetId, int row, int col) {
    final map = _cells.putIfAbsent(sheetId, () => {});
    final k = _key(row, col);
    if (map.containsKey(k)) return map[k];
    // Bounded: long scrolls through huge sheets don't keep every cell.
    if (map.length > maxEntries) {
      map.clear();
      _computed.remove(sheetId);
    }
    final d = _compute(sheetId, row, col);
    map[k] = d;
    final content = model.sheet(sheetId)?.cellAt(row, col)?.content;
    if (content == null || content.startsWith('=')) {
      (_computed[sheetId] ??= {}).add(k);
    }
    return d;
  }

  CellDisplay? _compute(String sheetId, int row, int col) {
    final sheet = model.sheet(sheetId);
    if (sheet == null) return null;
    final rec = sheet.cellAt(row, col);
    if (rec == null &&
        sheet.bandings.isEmpty &&
        model.bandingPreview == null &&
        sheet.dvRules.isEmpty &&
        dvDraft?.sheetId != sheetId &&
        (conditional == null ||
            !(conditionalAt?.call(sheetId, row, col) ?? true)) &&
        computedFormat?.call(sheetId, row, col) == null) {
      final chain = model.explicitFormatChain(sheetId, row, col);
      final decorated =
          chain.has(FormatAttr.fillColor) || FormatAttr.borders.any(chain.has);
      if (!decorated) {
        final v = _source.valueAt(sheetId, row, col).toCellValue();
        if (v.isBlank()) return null;
      }
    }
    return resolver.display(sheetId, row, col);
  }

  /// Whether the cell holds or shows anything (overflow stops there).
  bool hasContent(String sheetId, int row, int col) {
    final d = displayAt(sheetId, row, col);
    if (d == null) return false;
    return d.text.isNotEmpty ||
        d.widget.kind != CellWidgetKind.none ||
        d.content != null;
  }

  /// Resolved border edges of a cell (shared-edge conflicts applied).
  CellEdges edgesAt(String sheetId, int row, int col) {
    final map = _edges.putIfAbsent(sheetId, () => {});
    if (map.length > maxEntries) map.clear();
    return map.putIfAbsent(
      _key(row, col),
      () => resolver.edges(sheetId, row, col),
    );
  }

  /// Whether the sheet may have any border at all (fast path, called on
  /// every content paint): O(1) once known. Kept up to date from model
  /// batches ([invalidateBatch]): a cell format change can only turn it on;
  /// structure and sheet changes rescan once. It may stay true after the
  /// last border is removed (it says "may").
  bool sheetHasBorders(String sheetId) =>
      _borders[sheetId] ??= _scanBorders(sheetId);

  static bool _hasBorder(CellFormat f) => FormatAttr.borders.any(f.has);

  bool _scanBorders(String sheetId) {
    final s = model.sheet(sheetId);
    if (s == null) return false;
    if (s.record != null && _hasBorder(s.record!.format)) return true;
    for (final r in s.rowRecords.values) {
      if (r.formatJson != null && _hasBorder(r.format)) return true;
    }
    for (final c in s.columnRecords.values) {
      if (c.formatJson != null && _hasBorder(c.format)) return true;
    }
    for (final c in s.cells.all) {
      if (_hasBorder(c.format)) return true;
    }
    return false;
  }

  /// A cell format change turns the flag on when a changed cell has a
  /// border (no rescan).
  void _noteBorders(String sheetId, Set<CellKey> formatKeys) {
    if (formatKeys.isEmpty || _borders[sheetId] != false) return;
    final s = model.sheet(sheetId);
    if (s == null) return;
    for (final k in formatKeys) {
      final c = s.cells.at(k.rowId, k.colId);
      if (c != null && _hasBorder(c.format)) {
        _borders[sheetId] = true;
        return;
      }
    }
  }

  /// Per sheet: whether it may have borders (absent: not known yet).
  final Map<String, bool> _borders = {};
}
