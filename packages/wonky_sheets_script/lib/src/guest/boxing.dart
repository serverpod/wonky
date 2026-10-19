import 'dart:collection';
import 'dart:typed_data';

import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:dart_eval/stdlib/core.dart';
import 'package:dart_eval/dart_eval_internals.dart' show $InstanceImpl;

import '../protocol/values.dart';
import 'cell_error_binding.dart';

/// Thrown when a guest value cannot cross the bridge (an object of a class
/// declared in the script, a closure, …).
final class UnsupportedValueError implements Exception {
  /// Creates the error.
  const UnsupportedValueError(this.description);

  /// What was found.
  final String description;

  @override
  String toString() =>
      'Only null, numbers, strings, booleans, DateTime, CellError, lists and '
      'maps can be passed to the spreadsheet (got $description).';
}

/// Converts host values to dart_eval boxed values and back (09 §8.2.4).
///
/// 2-D arrays are boxed lazily: the outer list is a [_LazyBoxedList] that
/// boxes each row when the script first touches it, so reading a large
/// range does not allocate every box up front.
final class GuestBoxing {
  /// Creates a converter that counts boxed values in [onBoxed].
  GuestBoxing({this.onBoxed});

  /// Called with the number of values boxed (bridged-value limit, 09 §10).
  final void Function(int count)? onBoxed;

  /// Boxes [v].
  $Value box(Object? v) {
    switch (v) {
      case null:
        return const $null();
      case bool b:
        onBoxed?.call(1);
        return $bool(b);
      case int i:
        onBoxed?.call(1);
        return $int(i);
      case double d:
        onBoxed?.call(1);
        return $double(d);
      case String s:
        onBoxed?.call(1);
        return $String(s);
      case DateTime d:
        onBoxed?.call(1);
        return $DateTime.wrap(d);
      case CellError e:
        onBoxed?.call(1);
        return $CellError.wrap(e);
      case Uint8List b:
        onBoxed?.call(b.length);
        return $List.wrap(<$Value>[for (final x in b) $int(x)]);
      case List<Object?> l:
        onBoxed?.call(1);
        if (l.length > 16 && l.first is List) {
          return $List.wrap(_LazyBoxedList(l, this));
        }
        return $List.wrap(<$Value>[for (final e in l) box(e)]);
      case Map<Object?, Object?> m:
        onBoxed?.call(m.length);
        return $Map.wrap(<$Value, $Value>{
          for (final e in m.entries) box(e.key): box(e.value),
        });
      default:
        throw UnsupportedValueError('${v.runtimeType}');
    }
  }

  /// Unboxes a guest value into a plain host value.
  static Object? unbox(Object? v) {
    if (v == null) return null;
    if (v is $null) return null;
    if (v is $CellError) return v.$value;
    if (v is $List) return [for (final e in v.$value) unbox(e)];
    if (v is $Map) {
      final m = v.$value;
      return <String, Object?>{
        for (final e in m.entries) '${unbox(e.key)}': unbox(e.value),
      };
    }
    if (v is $Set) return [for (final e in v.$value) unbox(e)];
    if (v is $DateTime) return v.$value;
    if (v is $String || v is $num || v is $bool) {
      return (v as $Value).$value;
    }
    if (v is $InstanceImpl || v is EvalFunction) {
      throw const UnsupportedValueError('an object of a script class');
    }
    if (v is $Value) {
      final raw = v.$value;
      if (raw is $Value || raw is List || raw is Map) return unbox(raw);
      if (raw == null ||
          raw is num ||
          raw is String ||
          raw is bool ||
          raw is DateTime) {
        return raw;
      }
      throw UnsupportedValueError('${raw.runtimeType}');
    }
    if (v is List) return [for (final e in v) unbox(e)];
    if (v is Map) {
      return <String, Object?>{
        for (final e in v.entries) '${unbox(e.key)}': unbox(e.value),
      };
    }
    if (v is num || v is String || v is bool || v is DateTime) return v;
    if (v is CellError) return v;
    throw UnsupportedValueError('${v.runtimeType}');
  }
}

/// A list of host rows boxed on first access.
final class _LazyBoxedList extends ListBase<$Value> {
  _LazyBoxedList(List<Object?> rows, this._boxing)
    : _rows = rows,
      _boxed = List<$Value?>.filled(rows.length, null, growable: true);

  final List<Object?> _rows;
  final List<$Value?> _boxed;
  final GuestBoxing _boxing;

  @override
  int get length => _boxed.length;

  @override
  set length(int n) {
    _boxed.length = n;
    if (n > _rows.length) {
      _rows.length = n;
    } else {
      _rows.removeRange(n, _rows.length);
    }
  }

  @override
  $Value operator [](int index) => _boxed[index] ??= _boxing.box(_rows[index]);

  @override
  void operator []=(int index, $Value value) {
    _boxed[index] = value;
  }

  @override
  void add($Value element) {
    _rows.add(null);
    _boxed.add(element);
  }
}
