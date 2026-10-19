import 'dart:math' as math;

import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../sheet_editor/sheet_editor_controller.dart';

/// The aggregates of the selection stats button (04 §7).
enum SelectionStat { sum, average, min, max, count, countNumbers }

/// Aggregates of the current selection.
class SelectionStats {
  const SelectionStats({
    required this.sum,
    required this.min,
    required this.max,
    required this.count,
    required this.countNumbers,
    this.numberFormat,
  });

  static const empty = SelectionStats(
    sum: 0,
    min: 0,
    max: 0,
    count: 0,
    countNumbers: 0,
  );

  final double sum;
  final double min;
  final double max;

  /// Non-empty cells.
  final int count;
  final int countNumbers;

  /// The shared number format of the numbers (null when mixed).
  final String? numberFormat;

  double get average => countNumbers == 0 ? 0 : sum / countNumbers;

  double valueOf(SelectionStat s) => switch (s) {
    SelectionStat.sum => sum,
    SelectionStat.average => average,
    SelectionStat.min => min,
    SelectionStat.max => max,
    SelectionStat.count => count.toDouble(),
    SelectionStat.countNumbers => countNumbers.toDouble(),
  };

  /// The default shown aggregate: Sum with numbers, else Count.
  SelectionStat get defaultStat =>
      countNumbers > 0 ? SelectionStat.sum : SelectionStat.count;

  /// Computes the stats of [ed]'s selection (stored cells only; at most
  /// [cap] cells are visited) synchronously. The status bar computes large
  /// selections in slices instead ([SelectionStatsAccumulator]).
  static SelectionStats of(SheetEditorController ed, {int cap = 5000000}) {
    final acc = SelectionStatsAccumulator(ed, cap: cap);
    while (!acc.step(1 << 30)) {}
    return acc.result;
  }
}

/// Computes [SelectionStats] in steps of a bounded number of cells (S-03,
/// CQ-41), so a whole-column or whole-sheet selection doesn't block a frame.
/// Reads values and number formats from the engine, never through the
/// grid's render cache. The model must not change between steps (callers
/// drop the accumulator when it does).
class SelectionStatsAccumulator {
  SelectionStatsAccumulator(this.ed, {this.cap = 5000000}) {
    final sheet = ed.activeSheet;
    final grid = sheet?.gridRect;
    if (sheet == null || grid == null) {
      _done = true;
      return;
    }
    _sheet = sheet;
    final ranges = ed.selection.resolved.ranges;
    _multiRange = ranges.length > 1;
    _rects = [
      for (final range in ranges) ?range.rect.intersection(grid),
    ].iterator;
  }

  final SheetEditorController ed;

  /// The most cells visited in total (the rest is ignored).
  final int cap;

  late final SheetModel _sheet;
  late final Iterator<GridRect> _rects;
  Iterator<(int, int, CellRecord)>? _cells;
  bool _multiRange = false;
  bool _done = false;

  var _sum = 0.0;
  var _min = double.infinity;
  var _max = double.negativeInfinity;
  var _count = 0;
  var _numbers = 0;
  var _visited = 0;
  String? _format;
  var _mixed = false;
  final _seen = <(int, int)>{};

  /// Whether every cell has been visited.
  bool get isDone => _done;

  /// Visits at most [maxCells] more cells; returns whether it finished.
  bool step(int maxCells) {
    var budget = maxCells;
    while (!_done && budget > 0) {
      final cells = _cells;
      if (cells == null || !cells.moveNext()) {
        if (!_rects.moveNext()) {
          _done = true;
          break;
        }
        _cells = _sheet.cellsIn(_rects.current, contentOnly: true).iterator;
        continue;
      }
      budget--;
      if (++_visited > cap) {
        _done = true;
        break;
      }
      final (r, c, _) = cells.current;
      if (_multiRange && !_seen.add((r, c))) continue;
      _visit(r, c);
    }
    return _done;
  }

  void _visit(int r, int c) {
    final v = ed.engine.valueAt(_sheet.id, r, c).toCellValue();
    if (v.isBlank()) return;
    _count++;
    if (v is! NumberValue) return;
    _numbers++;
    _sum += v.number;
    _min = math.min(_min, v.number);
    _max = math.max(_max, v.number);
    if (_mixed) return;
    // The effective pattern (explicit chain, then the formula's hint), as
    // the grid shows it, without resolving the whole display.
    final f =
        ed.cells.source.numberFormatAt(_sheet.id, r, c) ??
        kAutomaticNumberFormat;
    if (_format == null) {
      _format = f;
    } else if (f != _format) {
      _mixed = true;
    }
  }

  /// The stats of the cells visited so far.
  SelectionStats get result => SelectionStats(
    sum: _sum,
    min: _numbers == 0 ? 0 : _min,
    max: _numbers == 0 ? 0 : _max,
    count: _count,
    countNumbers: _numbers,
    numberFormat: _mixed ? null : _format,
  );
}

/// Whether the selection is more than one cell (the button is hidden for a
/// single cell).
bool selectionIsMulti(SheetEditorController ed) {
  final r = ed.selection.resolved;
  if (r.ranges.length > 1) return true;
  final rect = r.ranges.first.rect;
  final m = ed.activeSheet?.mergeAt(rect.top, rect.left);
  return rect.cellCount > 1 && rect != m;
}

/// A cell rectangle helper for tests.
GridRect statsRect(int r1, int c1, int r2, int c2) => GridRect(r1, c1, r2, c2);
