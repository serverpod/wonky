import 'collation.dart';
import 'fvalue.dart';
import 'numeric.dart';

/// Sheets ordering and equality (05 §6.4) and the sort order of 07 §2.3.
abstract final class Compare {
  static int _typeRank(FValue v) => switch (v) {
    FNumber() => 0,
    FText() => 1,
    FBool() => 2,
    _ => 3,
  };

  /// Case folding used for case-insensitive comparisons.
  static String fold(String s) => s.toLowerCase();

  /// Compares two scalars for the comparison operators. Blank adopts the other operand's type
  /// (0, `""`, FALSE). Errors must be handled by the caller.
  static int compare(FValue a, FValue b, {bool caseSensitive = false}) {
    if (a is FRich) a = a.scalar;
    if (b is FRich) b = b.scalar;
    if (a is FEmpty || a is FOmitted) a = _blankAs(b);
    if (b is FEmpty || b is FOmitted) b = _blankAs(a);
    final ra = _typeRank(a);
    final rb = _typeRank(b);
    if (ra != rb) return ra < rb ? -1 : 1;
    switch (a) {
      case FNumber(:final v):
        return Numeric.compare(v, (b as FNumber).v);
      case FText(:final v):
        final w = (b as FText).v;
        if (caseSensitive) return v.compareTo(w).sign;
        return fold(v).compareTo(fold(w)).sign;
      case FBool(:final v):
        final w = (b as FBool).v;
        return v == w ? 0 : (v ? 1 : -1);
      default:
        return 0;
    }
  }

  static FValue _blankAs(FValue other) => switch (other) {
    FText() => FText.empty,
    FBool() => FBool.f,
    _ => FNumber.zero,
  };

  /// Equality for `=` and lookups (case-insensitive text, numeric tolerance).
  static bool equals(FValue a, FValue b) => compare(a, b) == 0;

  /// Exact-match key for hashing lookups: numbers by value, text folded, booleans; null for
  /// blanks/errors.
  static Object? matchKey(FValue v, {bool caseSensitive = false}) =>
      switch (v) {
        FNumber(:final v) => v == 0 ? 0.0 : v,
        FText(:final v) => caseSensitive ? 's:$v' : 's:${fold(v)}',
        FBool(:final v) => v,
        FRich(:final scalar) => matchKey(scalar, caseSensitive: caseSensitive),
        _ => null,
      };

  static int _sortRank(FValue v) => switch (v) {
    FNumber() => 0,
    FText(:final v) => v.isEmpty ? 5 : 1,
    FBool() => 2,
    FError() => 3,
    FRich(:final scalar) => _sortRank(scalar),
    _ => 5,
  };

  /// SORT / sort-range ordering: numbers < text < booleans < errors; blanks (and `""`) always
  /// last regardless of direction. Text compares by the shared [Collation] (key, then
  /// ordinal); [keyA]/[keyB] are the precomputed collation keys of text values, if any.
  static int sortCompare(
    FValue a,
    FValue b, {
    bool ascending = true,
    String? keyA,
    String? keyB,
  }) {
    if (a is FRich) a = a.scalar;
    if (b is FRich) b = b.scalar;
    final ra = _sortRank(a);
    final rb = _sortRank(b);
    if (ra == 5 || rb == 5) {
      if (ra == rb) return 0;
      return ra == 5 ? 1 : -1;
    }
    int c;
    if (ra != rb) {
      c = ra < rb ? -1 : 1;
    } else {
      switch (a) {
        case FNumber(:final v):
          c = v.compareTo((b as FNumber).v);
        case FText(:final v):
          final w = (b as FText).v;
          c = keyA != null && keyB != null
              ? Collation.compareKeyed(v, keyA, w, keyB)
              : Collation.compare(v, w);
        case FBool(:final v):
          final w = (b as FBool).v;
          c = v == w ? 0 : (v ? 1 : -1);
        case FError(:final kind):
          c = kind.typeCode.compareTo((b as FError).kind.typeCode);
        default:
          c = 0;
      }
    }
    return ascending ? c : -c;
  }
}
