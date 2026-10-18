import 'dart:math' as math;

import '../../eval/args.dart';
import '../../eval/eval_context.dart';
import '../../values/compare.dart';
import '../../values/errors.dart';
import '../../values/format_hint.dart';
import '../../values/fvalue.dart';
import '../../values/numeric.dart';
import '../criteria.dart';
import '../helpers.dart';
import '../registry.dart';

/// Criteria aggregates: SUMIF(S), COUNTIF(S), AVERAGEIF(S), MAXIFS, MINIFS (05 §15.1, §15.2,
/// §15.14) with cached per-range indexes (05 §11.2).
void registerConditional(FunctionRegistryBuilder b) {
  b.category = FunctionCategory.math;
  b.fn(
    'SUMIF',
    'Returns a conditional sum across a range.',
    [
      P.range('range', 'The range which is tested against criterion.'),
      P.scalar('criterion', 'The pattern or test to apply to range.'),
      P.range(
        'sum_range',
        'The range to be summed, if different from range.',
        true,
      ),
    ],
    (a) => _single(a, _Agg.sum, sumIndex: a.has(2) ? 2 : 0),
    liftable: true,
    priority: Priority.p0,
    examples: ['SUMIF(A1:A10, ">20")', 'SUMIF(A1:A10, "Paid", B1:B10)'],
    seeAlso: ['SUMIFS', 'COUNTIF'],
  );
  b.fn(
    'SUMIFS',
    'Returns the sum of a range depending on multiple criteria.',
    [
      P.range('sum_range', 'The range to sum.'),
      P.range('criteria_range1', 'The range to check against criterion1.'),
      P.scalar(
        'criterion1',
        'The pattern or test to apply to criteria_range1.',
      ),
      P.rep('criteria_range2', ArgKind.range, 'Additional ranges to check.'),
      P.rep('criterion2', ArgKind.scalar, 'Additional criteria to check.'),
    ],
    (a) => _multi(a, _Agg.sum, valueIndex: 0, first: 1),
    liftable: true,
    priority: Priority.p0,
    examples: ['SUMIFS(C1:C10, A1:A10, "East", B1:B10, ">100")'],
    seeAlso: ['SUMIF', 'COUNTIFS'],
  );
  b.category = FunctionCategory.statistical;
  b.fn(
    'COUNTIF',
    'Returns a conditional count across a range.',
    [
      P.range('range', 'The range that is tested against criterion.'),
      P.scalar('criterion', 'The pattern or test to apply to range.'),
    ],
    (a) => _single(a, _Agg.count),
    liftable: true,
    priority: Priority.p0,
    examples: ['COUNTIF(A1:A10, ">20")', 'COUNTIF(A1:A10, "Paid")'],
    seeAlso: ['COUNTIFS', 'SUMIF'],
  );
  b.fn(
    'COUNTIFS',
    'Returns the count of a range depending on multiple criteria.',
    [
      P.range('criteria_range1', 'The range to check against criterion1.'),
      P.scalar(
        'criterion1',
        'The pattern or test to apply to criteria_range1.',
      ),
      P.rep('criteria_range2', ArgKind.range, 'Additional ranges to check.'),
      P.rep('criterion2', ArgKind.scalar, 'Additional criteria to check.'),
    ],
    (a) => _multi(a, _Agg.count, valueIndex: -1, first: 0),
    liftable: true,
    priority: Priority.p0,
    examples: ['COUNTIFS(A1:A10, ">20", B1:B10, "<30")'],
  );
  b.fn(
    'AVERAGEIF',
    'Returns the average of a range depending on criteria.',
    [
      P.range('criteria_range', 'The range to check against criterion.'),
      P.scalar('criterion', 'The pattern or test to apply to criteria_range.'),
      P.range(
        'average_range',
        'The range to average. If not included, criteria_range is used for the average instead.',
        true,
      ),
    ],
    (a) => _single(a, _Agg.average, sumIndex: a.has(2) ? 2 : 0),
    liftable: true,
    priority: Priority.p0,
    examples: ['AVERAGEIF(A1:A10, ">20")', 'AVERAGEIF(A1:A10, "East", B1:B10)'],
  );
  b.fn(
    'AVERAGEIFS',
    'Returns the average of a range depending on multiple criteria.',
    [
      P.range('average_range', 'The range to average.'),
      P.range('criteria_range1', 'The range to check against criterion1.'),
      P.scalar(
        'criterion1',
        'The pattern or test to apply to criteria_range1.',
      ),
      P.rep('criteria_range2', ArgKind.range, 'Additional ranges to check.'),
      P.rep('criterion2', ArgKind.scalar, 'Additional criteria to check.'),
    ],
    (a) => _multi(a, _Agg.average, valueIndex: 0, first: 1),
    liftable: true,
    priority: Priority.p0,
    examples: ['AVERAGEIFS(C1:C10, A1:A10, "East", B1:B10, ">100")'],
  );
  b.fn(
    'MAXIFS',
    'Returns the maximum value in a range of cells, filtered by a set of criteria.',
    [
      P.range(
        'range',
        'The range of cells from which the maximum will be determined.',
      ),
      P.range(
        'criteria_range1',
        'The range of cells over which to evaluate criterion1.',
      ),
      P.scalar(
        'criterion1',
        'The pattern or test to apply to criteria_range1.',
      ),
      P.rep('criteria_range2', ArgKind.range, 'Additional ranges to evaluate.'),
      P.rep('criterion2', ArgKind.scalar, 'Additional criteria.'),
    ],
    (a) => _multi(a, _Agg.max, valueIndex: 0, first: 1),
    liftable: true,
    priority: Priority.p0,
    examples: ['MAXIFS(B1:B10, A1:A10, "East")'],
  );
  b.fn(
    'MINIFS',
    'Returns the minimum value in a range of cells, filtered by a set of criteria.',
    [
      P.range(
        'range',
        'The range of cells from which the minimum will be determined.',
      ),
      P.range(
        'criteria_range1',
        'The range of cells over which to evaluate criterion1.',
      ),
      P.scalar(
        'criterion1',
        'The pattern or test to apply to criteria_range1.',
      ),
      P.rep('criteria_range2', ArgKind.range, 'Additional ranges to evaluate.'),
      P.rep('criterion2', ArgKind.scalar, 'Additional criteria.'),
    ],
    (a) => _multi(a, _Agg.min, valueIndex: 0, first: 1),
    liftable: true,
    priority: Priority.p0,
    examples: ['MINIFS(B1:B10, A1:A10, "East")'],
  );
}

enum _Agg { sum, count, average, max, min }

/// Dense values of a criteria/value range clamped to the used extent, plus the logical size.
final class _Grid {
  final int rows;
  final int cols;
  final int logicalRows;
  final int logicalCols;
  final List<FValue> cells;
  _Grid(this.rows, this.cols, this.logicalRows, this.logicalCols, this.cells);
  int get logicalCount => logicalRows * logicalCols;
  FValue at(int r, int c) =>
      (r < rows && c < cols) ? cells[r * cols + c] : FEmpty.instance;
}

/// A criteria or value range argument: a reference, or an array (Sheets accepts arrays such
/// as `COUNTIF({1,2,3}, ">1")` or `COUNTIF(SPLIT(A1, ","), "x")`).
FValue _rangeArg(Args a, int i) {
  var v = a[i];
  if (v is FError) throw FormulaError(v);
  if (v is FRich) v = v.scalar;
  if (v is! FRef && v is! FArray) {
    fail(ErrorKind.value, ErrorMessages.argumentMustBeRange);
  }
  return v;
}

/// (rows, cols) of a range argument.
(int, int) _shapeOf(FValue v) =>
    v is FRef ? (v.area.rows, v.area.cols) : ((v as FArray).rows, v.cols);

/// Materializes [src] resized to (rows × cols) from its top-left; references are clamped to
/// the used extent.
_Grid _grid(Args a, FValue src, int rows, int cols) {
  if (src is FArray) {
    final cr = math.min(rows, src.rows), cc = math.min(cols, src.cols);
    final cells = List<FValue>.generate(cr * cc, (i) {
      final v = src.at(i ~/ cc, i % cc);
      return v is FRich ? v.scalar : v;
    });
    return _Grid(cr, cc, rows, cols, cells);
  }
  final ref = src as FRef;
  final ctx = a.ctx;
  final area = ref.area;
  final s = a.sheetOfRef(ref);
  if (ref.dynamic) ctx.deps.areas.add(area);
  final ur = ctx.host.usedRows(s), uc = ctx.host.usedColumns(s);
  final cr = math.max(0, math.min(rows, ur - area.top));
  final cc = math.max(0, math.min(cols, uc - area.left));
  final key = 'G|${area.sheetId}|${area.top}|${area.left}|$cr|$cc';
  final stamp = ctx.host.lookupCache.stampOf(
    ResolvedArea(
      area.sheetId,
      area.top,
      area.left,
      area.top + math.max<int>(cr, 1) - 1,
      area.left + math.max<int>(cc, 1) - 1,
    ),
  );
  final cached = ctx.host.lookupCache.get<_Grid>(key, stamp);
  if (cached != null) {
    return _Grid(cached.rows, cached.cols, rows, cols, cached.cells);
  }
  final cells = List<FValue>.filled(cr * cc, FEmpty.instance);
  if (cr > 0 && cc > 0) {
    ctx.host.forEachValue(
      s,
      ResolvedArea(
        area.sheetId,
        area.top,
        area.left,
        area.top + cr - 1,
        area.left + cc - 1,
      ).rect,
      (r, c, v) => cells[(r - area.top) * cc + (c - area.left)] = v is FRich
          ? v.scalar
          : v,
    );
  }
  final g = _Grid(cr, cc, rows, cols, cells);
  if (cr * cc >= 64) ctx.host.lookupCache.put(key, stamp, g);
  return g;
}

/// Per-range index: equality buckets (text, logical) and sorted numbers (05 §11.2
/// `CriteriaCount`). It answers exactly what [Criterion.test] would: numbers compare with
/// [Numeric.compare]'s tolerance, and positions come in grid order (as a scan visits them,
/// so sums and format hints do not depend on whether the index exists).
final class _Index {
  final Map<Object, List<int>> eq = {};

  /// Text cells with surrounding blanks, by their trimmed folded text: a number criterion
  /// matches text cells trimmed ("5" matches " 5 "), a text criterion does not.
  final Map<String, List<int>> padded = {};
  final List<int> sortedPos = [];
  final List<double> sortedNum = [];
  _Index(_Grid g) {
    final n = g.rows * g.cols;
    for (var i = 0; i < n; i++) {
      final v = g.cells[i];
      if (v is FNumber) {
        sortedPos.add(i);
        continue;
      }
      final k = Compare.matchKey(v);
      if (k != null) (eq[k] ??= []).add(i);
      if (v is FText) {
        final t = v.v.trim();
        if (t.length != v.v.length) (padded[Compare.fold(t)] ??= []).add(i);
      }
    }
    sortedPos.sort(
      (x, y) => (g.cells[x] as FNumber).v.compareTo((g.cells[y] as FNumber).v),
    );
    for (final p in sortedPos) {
      sortedNum.add((g.cells[p] as FNumber).v);
    }
  }

  /// Matching positions (inside the clamped grid) or null when the index can't answer.
  Iterable<int>? positions(Criterion c) {
    final o = c.operand;
    if (c.hasWildcard) return null;
    switch (c.op) {
      case CriterionOp.eq:
        if (o is FNumber) {
          // Text cells match the criterion's text form, trimmed (as Criterion.test).
          final a = _numbers(o.v, c.op);
          final tf = Compare.fold(c.textForm ?? Numeric.toText(o.v));
          final b = eq['s:$tf'] ?? const <int>[];
          final p = padded[tf] ?? const <int>[];
          if (b.isEmpty && p.isEmpty) return a;
          return ([...a, ...b, ...p]..sort());
        }
        if (o is FText && o.v.isNotEmpty) {
          return eq['s:${Compare.fold(o.v)}'] ?? const <int>[];
        }
        if (o is FBool) return eq[o.v] ?? const <int>[];
        return null;
      case CriterionOp.lt:
      case CriterionOp.le:
      case CriterionOp.gt:
      case CriterionOp.ge:
        if (o is! FNumber) return null;
        return _numbers(o.v, c.op);
      default:
        return null;
    }
  }

  /// Positions (ascending) of the numbers `y` for which `Numeric.compare(y, x)` satisfies
  /// [op]. Numbers outside `x ± 4ε|x|` compare as strictly less or greater (the tolerance
  /// is at most `ε·max(|x|, |y|)`); only the ones inside are compared one by one.
  List<int> _numbers(double x, CriterionOp op) {
    final tol = 4 * Numeric.epsilon * x.abs();
    final lo = _firstAtLeast(x - tol);
    final hi = _firstAbove(x + tol);
    final out = <int>[];
    if (op == CriterionOp.lt || op == CriterionOp.le) {
      out.addAll(sortedPos.getRange(0, lo));
    }
    for (var i = lo; i < hi; i++) {
      final cmp = Numeric.compare(sortedNum[i], x);
      final keep = switch (op) {
        CriterionOp.eq => cmp == 0,
        CriterionOp.lt => cmp < 0,
        CriterionOp.le => cmp <= 0,
        CriterionOp.gt => cmp > 0,
        CriterionOp.ge => cmp >= 0,
        _ => false,
      };
      if (keep) out.add(sortedPos[i]);
    }
    if (op == CriterionOp.gt || op == CriterionOp.ge) {
      out.addAll(sortedPos.getRange(hi, sortedPos.length));
    }
    return out..sort();
  }

  /// Index of the first sorted number `>= v`.
  int _firstAtLeast(double v) {
    var lo = 0, hi = sortedNum.length;
    while (lo < hi) {
      final m = (lo + hi) >> 1;
      if (sortedNum[m] < v) {
        lo = m + 1;
      } else {
        hi = m;
      }
    }
    return lo;
  }

  /// Index of the first sorted number `> v`.
  int _firstAbove(double v) {
    var lo = 0, hi = sortedNum.length;
    while (lo < hi) {
      final m = (lo + hi) >> 1;
      if (sortedNum[m] <= v) {
        lo = m + 1;
      } else {
        hi = m;
      }
    }
    return lo;
  }
}

_Index? _indexFor(Args a, FValue ref, _Grid g) {
  if (ref is! FRef || g.rows * g.cols < 256) return null;
  final area = ref.area;
  final key = 'I|${area.sheetId}|${area.top}|${area.left}|${g.rows}|${g.cols}';
  final stamp = a.ctx.host.lookupCache.stampOf(
    ResolvedArea(
      area.sheetId,
      area.top,
      area.left,
      area.top + g.rows - 1,
      area.left + g.cols - 1,
    ),
  );
  final cached = a.ctx.host.lookupCache.get<_Index>(key, stamp);
  if (cached != null) return cached;
  if (a.ctx.host.lookupCache.use('$key|$stamp') < 2) return null;
  final idx = _Index(g);
  a.ctx.host.lookupCache.put(key, stamp, idx);
  return idx;
}

final class _Acc {
  final _Agg agg;
  var count = 0;
  var sum = 0.0;
  var comp = 0.0;
  double? best;
  FError? error;
  FormatHint hint = FormatHint.none;
  bool hinted = false;
  _Acc(this.agg);

  void add(FValue v) {
    if (agg == _Agg.count) {
      count++;
      return;
    }
    if (v is FError) {
      error ??= v;
      return;
    }
    if (v is! FNumber) return;
    if (!hinted) {
      hinted = true;
      hint = v.hint;
    }
    count++;
    final t = sum + v.v;
    comp += sum.abs() >= v.v.abs() ? (sum - t) + v.v : (v.v - t) + sum;
    sum = t;
    final b = best;
    if (agg == _Agg.max) best = b == null || v.v > b ? v.v : b;
    if (agg == _Agg.min) best = b == null || v.v < b ? v.v : b;
  }

  FValue result(String fn) {
    if (error != null) return error!;
    switch (agg) {
      case _Agg.count:
        return FNumber(count.toDouble());
      case _Agg.sum:
        return numResult(sum + comp);
      case _Agg.average:
        if (count == 0) {
          return FError(ErrorKind.div0, ErrorMessages.divZeroEval(fn));
        }
        return numResult((sum + comp) / count);
      case _Agg.max:
      case _Agg.min:
        return FNumber(best ?? 0);
    }
  }
}

FValue _single(Args a, _Agg agg, {int sumIndex = 0}) {
  final ref = _rangeArg(a, 0);
  final crit = Criterion.of(a.scalar(1), a.locale);
  final (rows, cols) = _shapeOf(ref);
  final g = _grid(a, ref, rows, cols);
  final _Grid values;
  if (agg == _Agg.count) {
    values = g;
  } else if (sumIndex == 0) {
    values = g;
  } else {
    values = _grid(a, _rangeArg(a, sumIndex), rows, cols);
  }
  final acc = _Acc(agg);
  final idx = _indexFor(a, ref, g);
  final pos = idx?.positions(crit);
  if (pos != null) {
    for (final p in pos) {
      final r = p ~/ g.cols, c = p % g.cols;
      acc.add(values.at(r, c));
    }
  } else {
    for (var r = 0; r < g.rows; r++) {
      for (var c = 0; c < g.cols; c++) {
        if (crit.test(g.cells[r * g.cols + c])) acc.add(values.at(r, c));
      }
    }
  }
  // positions beyond the used extent are blank
  if (agg == _Agg.count) {
    final tail = g.logicalCount - g.rows * g.cols;
    if (tail > 0 && crit.test(FEmpty.instance)) acc.count += tail;
  }
  final r = acc.result(a.fn);
  if (r is FNumber && agg != _Agg.count && !acc.hint.isNone) {
    return r.withHint(acc.hint);
  }
  return r;
}

FValue _multi(Args a, _Agg agg, {required int valueIndex, required int first}) {
  final pairs = (a.length - first) ~/ 2;
  if ((a.length - first).isOdd || pairs == 0) {
    return FError(
      ErrorKind.na,
      ErrorMessages.wrongArgCount(a.fn, first + 2, 255, a.length),
    );
  }
  final refs = <FValue>[];
  final crits = <Criterion>[];
  for (var k = 0; k < pairs; k++) {
    refs.add(_rangeArg(a, first + 2 * k));
    crits.add(Criterion.of(a.scalar(first + 2 * k + 1), a.locale));
  }
  final (rows, cols) = _shapeOf(refs.first);
  FValue? valueRef;
  if (valueIndex >= 0) {
    valueRef = _rangeArg(a, valueIndex);
    if (_shapeOf(valueRef) != (rows, cols)) {
      fail(ErrorKind.value, ErrorMessages.arraySizeMismatch(a.fn));
    }
  }
  for (final r in refs) {
    if (_shapeOf(r) != (rows, cols)) {
      fail(ErrorKind.value, ErrorMessages.arraySizeMismatch(a.fn));
    }
  }
  final grids = [for (final r in refs) _grid(a, r, rows, cols)];
  // common clamped extent
  var cr = 0, cc = 0;
  for (final g in grids) {
    cr = math.max(cr, g.rows);
    cc = math.max(cc, g.cols);
  }
  final values = valueRef == null ? null : _grid(a, valueRef, rows, cols);
  if (values != null) {
    cr = math.max(cr, values.rows);
    cc = math.max(cc, values.cols);
  }
  final acc = _Acc(agg);
  bool matchesAt(int r, int c, int skip) {
    for (var k = 0; k < grids.length; k++) {
      if (k == skip) continue;
      if (!crits[k].test(grids[k].at(r, c))) return false;
    }
    return true;
  }

  // use an equality index of one criteria range when available
  Iterable<int>? seed;
  var seedK = -1;
  for (var k = 0; k < grids.length && seed == null; k++) {
    final g = grids[k];
    if (g.rows != cr || g.cols != cc) continue;
    final idx = _indexFor(a, refs[k], g);
    final p = idx?.positions(crits[k]);
    if (p != null) {
      seed = p;
      seedK = k;
    }
  }
  if (seed != null) {
    for (final p in seed) {
      final r = p ~/ cc, c = p % cc;
      if (matchesAt(r, c, seedK)) acc.add(values?.at(r, c) ?? FEmpty.instance);
    }
  } else {
    for (var r = 0; r < cr; r++) {
      for (var c = 0; c < cc; c++) {
        if (matchesAt(r, c, -1)) acc.add(values?.at(r, c) ?? FEmpty.instance);
      }
    }
  }
  if (agg == _Agg.count) {
    final tail = rows * cols - cr * cc;
    if (tail > 0 && crits.every((c) => c.test(FEmpty.instance))) {
      acc.count += tail;
    }
  }
  final r = acc.result(a.fn);
  if (r is FNumber && agg != _Agg.count && !acc.hint.isNone) {
    return r.withHint(acc.hint);
  }
  return r;
}
