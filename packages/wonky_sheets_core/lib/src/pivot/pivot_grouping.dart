import '../content/cell_content.dart';
import '../formula/parser/formula_locale.dart';
import '../formula/values/dates.dart';
import '../formula/values/numeric.dart';
import '../data_tools/sort/sort_keys.dart';
import '../formula/values/collation.dart';
import 'pivot_spec.dart';
import 'source_table.dart';

/// A normalized group key (07 §7.4 step 2) with its display label.
final class PivotKey {
  PivotKey._(
    this.rank,
    this.number,
    this.text,
    this.label, {
    this.inheritsFormat = false,
  });

  /// A number group (raw numbers, date units, histogram buckets).
  factory PivotKey.number(
    double n,
    CellValue label, {
    bool inheritsFormat = false,
  }) => PivotKey._(
    SortKeys.number,
    n == 0 ? 0.0 : n,
    '',
    label,
    inheritsFormat: inheritsFormat,
  );

  /// A text group (case-insensitive; [label] = first-seen casing).
  factory PivotKey.text(String text) =>
      PivotKey._(SortKeys.text, 0, text.toLowerCase(), TextValue(text));

  /// A named group (manual groups, `(non-date)`), compared by name.
  factory PivotKey.named(String name) => PivotKey.text(name);

  /// Boolean group.
  factory PivotKey.boolean(bool b) =>
      PivotKey._(SortKeys.boolean, b ? 1 : 0, '', BoolValue(b));

  /// Error group.
  factory PivotKey.error(CellErrorKind k) =>
      PivotKey._(SortKeys.error, k.code.toDouble(), '', ErrorValue(k));

  /// The blank group (empty label, sorted last).
  static final PivotKey blank = PivotKey._(
    SortKeys.blank,
    0,
    '',
    CellValue.empty,
  );

  /// Type group ([SortKeys] constants).
  final int rank;

  /// Numeric key (numbers, booleans, error codes).
  final double number;

  /// Case-folded text key (text groups).
  final String text;

  /// The label shown in the output.
  final CellValue label;

  /// Whether the label cell inherits the source column's number format.
  final bool inheritsFormat;

  /// Hashable identity.
  Object get identity => switch (rank) {
    SortKeys.number => number,
    SortKeys.text => 't:$text',
    SortKeys.boolean => number == 1,
    SortKeys.error => 'e:$number',
    _ => const _Blank(),
  };

  /// Label as text (for GETPIVOTDATA matching).
  String get labelText => switch (label) {
    TextValue(text: final t) => t,
    NumberValue(:final number) => Numeric.toText(number),
    BoolValue(:final value) => value ? 'TRUE' : 'FALSE',
    ErrorValue(:final kind) => kind.literal,
    EmptyValue() => '',
  };

  /// Label order (07 §2.3): numbers < text < booleans < errors; blanks last (also descending).
  static int compare(PivotKey a, PivotKey b, {bool ascending = true}) {
    if (a.rank == SortKeys.blank || b.rank == SortKeys.blank) {
      if (a.rank == b.rank) return 0;
      return a.rank == SortKeys.blank ? 1 : -1;
    }
    int c;
    if (a.rank != b.rank) {
      c = a.rank < b.rank ? -1 : 1;
    } else if (a.rank == SortKeys.text) {
      c = Collation.compare(a.text, b.text);
      if (c == 0) c = a.labelText.compareTo(b.labelText);
    } else {
      c = a.number.compareTo(b.number);
    }
    return ascending ? c : -c;
  }

  @override
  String toString() => 'PivotKey($labelText)';
}

final class _Blank {
  const _Blank();
}

/// Computes the group key of a source row for one row/column group.
final class PivotGrouper {
  /// Creates the grouper for [spec] over [column]. [histogramMin]/[histogramMax]
  /// default the bucket bounds to the data range.
  PivotGrouper(
    this.spec,
    this.column, {
    String locale = 'en_US',
    double? histogramMin,
    double? histogramMax,
  }) : _locale = FormulaLocale.forId(locale),
       _hMin = histogramMin,
       _hMax = histogramMax {
    final g = spec.group;
    if (g is PivotManualGrouping) {
      for (final group in g.groups) {
        for (final item in group.items) {
          _manual[item.toLowerCase()] = group.name;
        }
      }
    }
  }

  final PivotGroupSpec spec;
  final SourceColumn column;
  final FormulaLocale _locale;
  final double? _hMin;
  final double? _hMax;
  final Map<String, String> _manual = {};

  /// Canonical keys by identity: the first-seen label wins for text.
  final Map<Object, PivotKey> _canon = {};

  PivotKey _intern(PivotKey k) => _canon.putIfAbsent(k.identity, () => k);

  /// The key of data row [i].
  PivotKey keyOfRow(int i) => keyOf(column.values[i], column.displayText(i));

  /// The key of a value with display text [display].
  PivotKey keyOf(CellValue v, String display) => _intern(_rawKey(v, display));

  PivotKey _plain(CellValue v) => switch (v) {
    _ when v.isBlank() => PivotKey.blank,
    NumberValue(:final number) => PivotKey.number(
      number,
      v,
      inheritsFormat: true,
    ),
    TextValue(:final text) => PivotKey.text(text),
    BoolValue(:final value) => PivotKey.boolean(value),
    ErrorValue(:final kind) => PivotKey.error(kind),
    EmptyValue() => PivotKey.blank,
  };

  PivotKey _rawKey(CellValue v, String display) {
    final g = spec.group;
    switch (g) {
      case null:
        return _plain(v);
      case PivotManualGrouping():
        if (v.isBlank()) return PivotKey.blank;
        final name = _manual[display.toLowerCase()];
        if (name != null) return PivotKey.named(name);
        if (g.ungrouped != null) return PivotKey.named(g.ungrouped!);
        return _plain(v);
      case PivotDateGrouping(:final unit):
        if (v.isBlank()) return PivotKey.blank;
        if (v is! NumberValue) return PivotKey.named('(non-date)');
        return _dateKey(v.number, unit);
      case PivotHistogramGrouping(:final size):
        if (v is! NumberValue) return _plain(v);
        final x = v.number;
        final min = g.min ?? _hMin ?? x;
        final max = g.max ?? _hMax ?? x;
        if (x < min) {
          return PivotKey.number(
            double.negativeInfinity,
            TextValue('< ${Numeric.toText(min)}'),
          );
        }
        if (x > max) {
          return PivotKey.number(
            double.infinity,
            TextValue('> ${Numeric.toText(max)}'),
          );
        }
        final b = ((x - min) / size).floor();
        final lo = min + b * size;
        return PivotKey.number(
          b.toDouble(),
          TextValue(
            '${Numeric.toText(Numeric.stabilize(lo))}–${Numeric.toText(Numeric.stabilize(lo + size))}',
          ),
        );
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  PivotKey _dateKey(double serial, PivotDateUnit unit) {
    final d = DateSerial.toYmd(serial);
    final t = DateSerial.timeOf(serial);
    final q = (d.month - 1) ~/ 3 + 1;
    final mon = _locale.shortMonths[d.month - 1];
    PivotKey k(num key, String label) =>
        PivotKey.number(key.toDouble(), TextValue(label));
    switch (unit) {
      case PivotDateUnit.second:
        return k(t.second, '${t.second}');
      case PivotDateUnit.minute:
        return k(t.minute, '${t.minute}');
      case PivotDateUnit.hour:
        return k(t.hour, '${t.hour}');
      case PivotDateUnit.hourMinute:
        return k(t.hour * 60 + t.minute, '${t.hour}:${_two(t.minute)}');
      case PivotDateUnit.hourMinuteAmPm:
        final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
        final ampm = _locale.amPm.length == 2
            ? _locale.amPm[t.hour < 12 ? 0 : 1]
            : (t.hour < 12 ? 'AM' : 'PM');
        return k(t.hour * 60 + t.minute, '$h12:${_two(t.minute)} $ampm');
      case PivotDateUnit.dayOfWeek:
        final w = DateSerial.weekday(serial);
        return k(w, _locale.shortWeekdays[w]);
      case PivotDateUnit.dayOfYear:
        final doy = serial.floor() - DateSerial.fromYmd(d.year, 1, 1) + 1;
        return k(doy, '$doy');
      case PivotDateUnit.dayOfMonth:
        return k(d.day, '${d.day}');
      case PivotDateUnit.dayMonth:
        return k(d.month * 100 + d.day, '${d.day}-$mon');
      case PivotDateUnit.month:
        return k(d.month, mon);
      case PivotDateUnit.quarter:
        return k(q, 'Q$q');
      case PivotDateUnit.year:
        return k(d.year, '${d.year}');
      case PivotDateUnit.yearMonth:
        return k(d.year * 100 + d.month, '${d.year}-$mon');
      case PivotDateUnit.yearQuarter:
        return k(d.year * 10 + q, '${d.year}-Q$q');
      case PivotDateUnit.yearMonthDay:
        return k(
          serial.floorToDouble(),
          '${d.year}-${_two(d.month)}-${_two(d.day)}',
        );
    }
  }
}
