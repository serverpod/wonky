import 'dart:typed_data';

import '../../content/cell_content.dart';
import '../../formula/values/collation.dart';

/// Sort ordering of Google Sheets (07 §2.3), stable when combined with the
/// original index:
///
/// 1. numbers (dates/times included) ascending;
/// 2. text by a collation key (NFKD-like decomposition, combining marks
///    stripped, simple case folding), then the original string ordinal;
/// 3. booleans FALSE < TRUE;
/// 4. errors by `ERROR.TYPE` code;
/// 5. blanks (and `""`) always last, in both directions.
///
/// Descending reverses groups 1–4.
abstract final class SortKeys {
  /// Type groups.
  static const int number = 0;
  static const int text = 1;
  static const int boolean = 2;
  static const int error = 3;
  static const int blank = 4;

  /// The type group of [v].
  static int groupOf(CellValue v) => switch (v) {
    NumberValue() => number,
    TextValue(:final text) => text.isEmpty ? blank : SortKeys.text,
    BoolValue() => boolean,
    ErrorValue() => error,
    EmptyValue() => blank,
  };

  /// Compares two values; blanks sort last regardless of [ascending].
  static int compare(CellValue a, CellValue b, {bool ascending = true}) {
    final ga = groupOf(a);
    final gb = groupOf(b);
    if (ga == blank || gb == blank) {
      if (ga == gb) return 0;
      return ga == blank ? 1 : -1;
    }
    int c;
    if (ga != gb) {
      c = ga < gb ? -1 : 1;
    } else {
      switch (a) {
        case NumberValue(:final number):
          c = number.compareTo((b as NumberValue).number);
        case TextValue(text: final x):
          c = Collation.compare(x, (b as TextValue).text);
        case BoolValue(:final value):
          final w = (b as BoolValue).value;
          c = value == w ? 0 : (value ? 1 : -1);
        case ErrorValue(:final kind):
          c = kind.code.compareTo((b as ErrorValue).kind.code);
        case EmptyValue():
          c = 0;
      }
    }
    return ascending ? c : -c;
  }
}

/// A typed snapshot of one sort key column (07 §2.7 step 1): per row the
/// group, a number (numbers, booleans 0/1, error codes) and the text.
final class SortKeyColumn {
  /// Builds the snapshot from values (one per row).
  factory SortKeyColumn.fromValues(List<CellValue> values) {
    final n = values.length;
    final groups = Uint8List(n);
    final numbers = Float64List(n);
    final texts = List<String?>.filled(n, null);
    final keys = List<String?>.filled(n, null);
    for (var i = 0; i < n; i++) {
      final v = values[i];
      final g = SortKeys.groupOf(v);
      groups[i] = g;
      switch (v) {
        case NumberValue(:final number):
          numbers[i] = number;
        case BoolValue(:final value):
          numbers[i] = value ? 1 : 0;
        case ErrorValue(:final kind):
          numbers[i] = kind.code.toDouble();
        case TextValue(:final text):
          if (g == SortKeys.text) {
            texts[i] = text;
            keys[i] = Collation.key(text);
          }
        case EmptyValue():
          break;
      }
    }
    return SortKeyColumn._(groups, numbers, texts, keys);
  }

  SortKeyColumn._(this.groups, this.numbers, this.texts, this._keys);

  /// Type group per row ([SortKeys.number] …).
  final Uint8List groups;

  /// Numeric key per row.
  final Float64List numbers;

  /// Text per row (text group only).
  final List<String?> texts;
  final List<String?> _keys;

  /// Number of rows.
  int get length => groups.length;

  /// Compares rows [i] and [j] (blanks last in both directions).
  int compare(int i, int j, {bool ascending = true}) {
    final ga = groups[i];
    final gb = groups[j];
    if (ga == SortKeys.blank || gb == SortKeys.blank) {
      if (ga == gb) return 0;
      return ga == SortKeys.blank ? 1 : -1;
    }
    int c;
    if (ga != gb) {
      c = ga < gb ? -1 : 1;
    } else if (ga == SortKeys.text) {
      c = _keys[i]!.compareTo(_keys[j]!);
      if (c == 0) c = texts[i]!.compareTo(texts[j]!);
    } else {
      c = numbers[i].compareTo(numbers[j]);
    }
    return ascending ? c : -c;
  }
}
