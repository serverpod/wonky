import '../../eval/args.dart';
import '../../eval/eval_context.dart' show FormulaError, fail;
import '../../values/collation.dart';
import '../../values/compare.dart';
import '../../values/errors.dart';
import '../../values/fvalue.dart';
import '../registry.dart';

/// Dynamic-array filter & sort functions (05 §15.10).
void registerFilter(FunctionRegistryBuilder b) {
  b.category = FunctionCategory.filter;
  b.fn(
    'FILTER',
    'Returns a filtered version of the source range, returning only rows or columns that meet the specified conditions.',
    [
      P.array('range', 'The data to be filtered.'),
      P.array(
        'condition1',
        'A column or row containing true or false values corresponding to the first column or row of range, or an array formula evaluating to true or false.',
      ),
      P.rep(
        'condition2',
        ArgKind.array,
        'Additional rows or columns containing boolean values.',
      ),
    ],
    _filter,
    returns: ReturnKind.array,
    priority: Priority.p0,
    cost: FunctionCost.heavy,
    examples: [
      'FILTER(A2:B26, A2:A26 > 5, D2:D26 < 10)',
      'FILTER(A2:C, B2:B = "East")',
    ],
    seeAlso: ['SORT', 'UNIQUE', 'QUERY'],
  );
  b.fn(
    'SORT',
    'Sorts the rows of a given array or range by the values in one or more columns.',
    [
      P.array('range', 'The data to be sorted.'),
      P.array(
        'sort_column',
        'The index of the column in range or a range outside of range containing the values by which to sort.',
        true,
      ),
      P.bool_(
        'is_ascending',
        'TRUE or FALSE indicating whether to sort sort_column in ascending order.',
        true,
        true,
      ),
      P.rep('sort_column2', ArgKind.array, 'Additional columns.'),
      P.rep('is_ascending2', ArgKind.boolean, 'Additional sort orders.'),
    ],
    _sort,
    returns: ReturnKind.array,
    priority: Priority.p0,
    cost: FunctionCost.heavy,
    examples: ['SORT(A2:B26, 1, TRUE)', 'SORT(A2:C, 2, FALSE, 1, TRUE)'],
    seeAlso: ['SORTN', 'FILTER'],
  );
  b.fn(
    'SORTN',
    'Returns the first n items in a data set after performing a sort.',
    [
      P.array('range', 'The data to be sorted to find the first n items.'),
      P.num(
        'n',
        'The number of items to return. Must be greater than 0.',
        true,
        1,
      ),
      P.num(
        'display_ties_mode',
        '0 (default) at most n rows; 1 n rows plus ties of the nth; 2 at most n rows after removing duplicate rows; 3 at most n unique sort keys with all their duplicates.',
        true,
        0,
      ),
      P.rep(
        'sort_column1',
        ArgKind.array,
        'The index of the column or a range with the values by which to sort.',
      ),
      P.rep(
        'is_ascending1',
        ArgKind.boolean,
        'TRUE or FALSE indicating whether to sort in ascending order.',
      ),
    ],
    _sortn,
    returns: ReturnKind.array,
    cost: FunctionCost.heavy,
    examples: ['SORTN(A2:B10, 3, 0, 2, FALSE)'],
  );
  b.fn(
    'SORTBY',
    'Sorts the contents of a range or array based on the values in a corresponding range or array.',
    [
      P.array('array', 'The array or range to sort.'),
      P.array('by_array1', 'The array or range to sort on.'),
      P.num('sort_order1', '1 ascending (default), -1 descending.', true, 1),
      P.rep('by_array2', ArgKind.array, 'Additional arrays to sort on.'),
      P.rep('sort_order2', ArgKind.number, 'Additional sort orders.'),
    ],
    _sortby,
    returns: ReturnKind.array,
    priority: Priority.p2,
    cost: FunctionCost.heavy,
    examples: ['SORTBY(A2:B10, B2:B10, -1)'],
  );
  b.fn(
    'UNIQUE',
    'Returns unique rows in the provided source range, discarding duplicates. Rows are returned in the order in which they first appear in the source range.',
    [
      P.array('range', 'The data to filter by unique entries.'),
      P.bool_(
        'by_column',
        'Whether to filter the data by columns or by rows.',
        true,
        false,
      ),
      P.bool_(
        'exactly_once',
        'Whether to return only entries with no duplicates.',
        true,
        false,
      ),
    ],
    _unique,
    returns: ReturnKind.array,
    priority: Priority.p0,
    cost: FunctionCost.heavy,
    examples: ['UNIQUE(A2:B26)', 'UNIQUE(A2:A, FALSE, TRUE)'],
  );
}

bool _truthy(FValue v) => switch (v) {
  FBool(:final v) => v,
  FNumber(:final v) => v != 0,
  _ => false,
};

FValue _filter(Args a) {
  final data = a.array(0);
  bool? byRows;
  final keep = <bool>[];
  for (var i = 1; i < a.length; i++) {
    final c = a.array(i);
    bool rows;
    if (c.cols == 1 && c.rows == data.rows && (byRows ?? true)) {
      rows = true;
    } else if (c.rows == 1 && c.cols == data.cols && !(byRows ?? false)) {
      rows = false;
    } else {
      fail(
        ErrorKind.value,
        'FILTER has mismatched range sizes. Expected row count: ${data.rows}. column count: 1. Actual row count: ${c.rows}, column count: ${c.cols}.',
      );
    }
    byRows ??= rows;
    final n = rows ? c.rows : c.cols;
    if (keep.isEmpty) keep.addAll(List.filled(n, true));
    for (var k = 0; k < n; k++) {
      final v = c.atIndex(k);
      if (v is FError) throw FormulaError(v);
      if (!_truthy(v)) keep[k] = false;
    }
  }
  final idx = [
    for (var k = 0; k < keep.length; k++)
      if (keep[k]) k,
  ];
  if (idx.isEmpty) {
    return const FError(ErrorKind.na, ErrorMessages.noMatchFilter);
  }
  if (byRows ?? true) {
    return FArray.generate(idx.length, data.cols, (r, c) => data.at(idx[r], c));
  }
  return FArray.generate(data.rows, idx.length, (r, c) => data.at(r, idx[c]));
}

/// Sort keys: (column values per row, ascending).
typedef _Key = (List<FValue> values, bool ascending);

_Key _keyOf(Args a, FArray data, FValue spec, bool ascending) {
  if (spec is FArray && spec.length > 1) {
    if (spec.cols == 1 && spec.rows == data.rows) {
      return (spec.column(0), ascending);
    }
    if (spec.rows == 1 && spec.cols == data.rows) {
      return (spec.row(0), ascending);
    }
    fail(ErrorKind.value, '${a.fn} has mismatched range sizes.');
  }
  final s = spec is FArray ? spec.topLeft : spec;
  if (s is FError) throw FormulaError(s);
  final col = switch (s) {
    FNumber(:final v) => v.truncate(),
    FBool(:final v) => v ? 1 : 0,
    _ => fail(
      ErrorKind.value,
      '${a.fn} sort column must be a number or a range.',
    ),
  };
  if (col < 1 || col > data.cols) {
    fail(ErrorKind.value, 'Sort column index for ${a.fn} out of range: $col.');
  }
  return (data.column(col - 1), ascending);
}

List<int> _order(int n, List<_Key> keys) {
  // Collation keys once per row and key column, not per comparison.
  final textKeys = [
    for (final (values, _) in keys)
      [
        for (var i = 0; i < n; i++)
          switch (values[i]) {
            FText(:final v) ||
            FRich(scalar: FText(:final v)) => Collation.key(v),
            _ => null,
          },
      ],
  ];
  final order = List<int>.generate(n, (i) => i);
  order.sort((x, y) {
    for (var k = 0; k < keys.length; k++) {
      final (values, asc) = keys[k];
      final c = Compare.sortCompare(
        values[x],
        values[y],
        ascending: asc,
        keyA: textKeys[k][x],
        keyB: textKeys[k][y],
      );
      if (c != 0) return c;
    }
    return x - y;
  });
  return order;
}

FValue _sort(Args a) {
  final data = a.array(0);
  final keys = <_Key>[];
  if (a.length == 1) {
    keys.add((data.column(0), true));
  } else {
    for (var i = 1; i < a.length; i += 2) {
      final spec = a[i];
      if (spec is FOmitted) {
        keys.add((
          data.column(0),
          i + 1 < a.length ? a.boolOr(i + 1, true) : true,
        ));
        continue;
      }
      final asc = i + 1 < a.length ? a.boolOr(i + 1, true) : true;
      keys.add(_keyOf(a, data, spec, asc));
    }
  }
  final order = _order(data.rows, keys);
  return FArray.generate(data.rows, data.cols, (r, c) => data.at(order[r], c));
}

String _rowKey(FArray data, int r) {
  final b = StringBuffer();
  for (var c = 0; c < data.cols; c++) {
    final v = data.at(r, c);
    b
      ..write(_valueKey(v))
      ..write('\u0001');
  }
  return b.toString();
}

/// Case-sensitive identity key (UNIQUE is case-sensitive, 05 §15.10).
String _valueKey(FValue v) => switch (v) {
  FNumber(:final v) => 'n$v',
  FText(:final v) => v.isEmpty ? 'e' : 't$v',
  FBool(:final v) => 'b$v',
  FError(:final kind) => 'x${kind.literal}',
  FEmpty() => 'e',
  _ => '?',
};

FValue _sortn(Args a) {
  final data = a.array(0);
  final n = a.has(1) ? a.integer(1) : 1;
  final mode = a.intOr(2, 0);
  if (n < 1) fail(ErrorKind.num, 'SORTN n must be greater than 0.');
  if (mode < 0 || mode > 3) {
    fail(ErrorKind.value, 'Invalid display_ties_mode $mode.');
  }
  final keys = <_Key>[];
  for (var i = 3; i < a.length; i += 2) {
    final asc = i + 1 < a.length ? a.boolOr(i + 1, true) : true;
    keys.add(_keyOf(a, data, a[i], asc));
  }
  if (keys.isEmpty) keys.add((data.column(0), true));
  final order = _order(data.rows, keys);
  String sortKey(int r) =>
      [for (final (v, _) in keys) _valueKey(v[r])].join('\u0001');
  final out = <int>[];
  switch (mode) {
    case 0:
      out.addAll(order.take(n));
    case 1:
      out.addAll(order.take(n));
      if (out.length == n) {
        final last = sortKey(out.last);
        for (final r in order.skip(n)) {
          if (sortKey(r) == last) out.add(r);
        }
      }
    case 2:
      final seen = <String>{};
      for (final r in order) {
        if (seen.add(_rowKey(data, r))) out.add(r);
        if (out.length == n) break;
      }
    case 3:
      final seen = <String>{};
      for (final r in order) {
        final k = sortKey(r);
        if (!seen.contains(k)) {
          if (seen.length == n) break;
          seen.add(k);
        }
        out.add(r);
      }
  }
  return FArray.generate(out.length, data.cols, (r, c) => data.at(out[r], c));
}

FValue _sortby(Args a) {
  final data = a.array(0);
  final keys = <_Key>[];
  for (var i = 1; i < a.length; i += 2) {
    final by = a.array(i);
    final order = i + 1 < a.length ? a.intOr(i + 1, 1) : 1;
    if (order != 1 && order != -1) {
      fail(ErrorKind.value, 'SORTBY sort_order must be 1 or -1.');
    }
    if (by.cols == 1 && by.rows == data.rows) {
      keys.add((by.column(0), order == 1));
    } else if (by.rows == 1 && by.cols == data.cols && data.rows == 1) {
      keys.add((by.row(0), order == 1));
    } else {
      fail(ErrorKind.value, 'SORTBY has mismatched range sizes.');
    }
  }
  final idx = _order(data.rows, keys);
  return FArray.generate(data.rows, data.cols, (r, c) => data.at(idx[r], c));
}

FValue _unique(Args a) {
  var data = a.array(0);
  final byCol = a.boolOr(1, false);
  final once = a.boolOr(2, false);
  if (byCol) {
    data = FArray.generate(data.cols, data.rows, (r, c) => data.at(c, r));
  }
  final counts = <String, int>{};
  final first = <String, int>{};
  for (var r = 0; r < data.rows; r++) {
    final k = _rowKey(data, r);
    counts[k] = (counts[k] ?? 0) + 1;
    first.putIfAbsent(k, () => r);
  }
  final rows = [
    for (final e in first.entries)
      if (!once || counts[e.key] == 1) e.value,
  ];
  if (rows.isEmpty) {
    return const FError(ErrorKind.na, 'No unique values found.');
  }
  final out = FArray.generate(
    rows.length,
    data.cols,
    (r, c) => data.at(rows[r], c),
  );
  if (byCol) return FArray.generate(out.cols, out.rows, (r, c) => out.at(c, r));
  return out;
}

/// Exposed so other modules can reuse the stable multi-key order.
List<int> stableOrder(int n, List<(List<FValue>, bool)> keys) =>
    _order(n, keys);
