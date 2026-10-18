import 'package:collection/collection.dart';

/// Base of the chart spec value classes: value equality over the canonical JSON.
///
/// Nodes are immutable, so the hash is computed once per instance (CQ-47:
/// views key their scene caches on the spec, and hashing used to serialize
/// it on every hover move).
abstract base class SpecNode {
  /// Const base constructor.
  const SpecNode();

  /// Canonical JSON (defaults omitted, unknown keys preserved).
  Map<String, Object?> toJson();

  static const _eq = DeepCollectionEquality();
  static final Expando<int> _hashes = Expando('SpecNode.hashCode');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          hashCode == other.hashCode &&
          _eq.equals(toJson(), (other as SpecNode).toJson()));

  @override
  int get hashCode => _hashes[this] ??= _eq.hash(toJson());

  @override
  String toString() => '$runtimeType(${toJson()})';
}

/// Lenient typed reads over a decoded JSON object. Wrong types read as the default, so old or
/// partially invalid specs still render (strict checks live in `ChartSpecValidator`).
final class JsonReader {
  /// Wraps [json] (non-maps read as empty).
  JsonReader(Object? json)
    : map = json is Map
          ? json.map((k, v) => MapEntry('$k', v))
          : const <String, Object?>{};

  /// The underlying map.
  final Map<String, Object?> map;

  /// Whether [key] is present (even when null).
  bool has(String key) => map.containsKey(key);

  /// A string or null.
  String? str(String key) {
    final v = map[key];
    return v is String ? v : null;
  }

  /// A string or [def].
  String strOr(String key, String def) => str(key) ?? def;

  /// A finite double or null.
  double? dbl(String key) {
    final v = map[key];
    if (v is num && v.isFinite) return v.toDouble();
    return null;
  }

  /// A finite double or [def].
  double dblOr(String key, double def) => dbl(key) ?? def;

  /// An integer (integral doubles accepted) or null.
  int? integer(String key) {
    final v = map[key];
    if (v is int) return v;
    if (v is double && v.isFinite && v == v.truncateToDouble()) {
      return v.toInt();
    }
    return null;
  }

  /// An integer or [def].
  int intOr(String key, int def) => integer(key) ?? def;

  /// A bool or [def].
  bool boolOr(String key, bool def) {
    final v = map[key];
    return v is bool ? v : def;
  }

  /// A bool or null.
  bool? boolean(String key) {
    final v = map[key];
    return v is bool ? v : null;
  }

  /// A nested object (null when absent or not an object).
  Map<String, Object?>? obj(String key) {
    final v = map[key];
    return v is Map ? v.map((k, x) => MapEntry('$k', x)) : null;
  }

  /// A list (null when absent or not a list).
  List<Object?>? list(String key) {
    final v = map[key];
    return v is List ? v.cast<Object?>() : null;
  }

  /// An enum value by name, else [def].
  T enumOr<T extends Enum>(String key, List<T> values, T def) =>
      enumOrNull(key, values) ?? def;

  /// An enum value by name, else null.
  T? enumOrNull<T extends Enum>(String key, List<T> values) {
    final v = map[key];
    if (v is! String) return null;
    for (final e in values) {
      if (e.name == v) return e;
    }
    return null;
  }

  /// Entries whose keys are not in [known] (deep-copied).
  Map<String, Object?> extras(Set<String> known) => {
    for (final e in map.entries)
      if (!known.contains(e.key)) e.key: deepCopyJson(e.value),
  };
}

/// Deep copy of a JSON value (maps get `String` keys).
Object? deepCopyJson(Object? v) {
  if (v is Map) {
    return {for (final e in v.entries) '${e.key}': deepCopyJson(e.value)};
  }
  if (v is List) return [for (final x in v) deepCopyJson(x)];
  return v;
}

/// Builds canonical JSON: extras first, then known keys; defaults omitted.
final class JsonWriter {
  /// Starts with [extras].
  JsonWriter([Map<String, Object?> extras = const {}])
    : _m = {for (final e in extras.entries) e.key: deepCopyJson(e.value)};

  final Map<String, Object?> _m;

  /// Writes [value] unconditionally.
  void put(String key, Object? value) => _m[key] = value;

  /// Writes [value] unless it is null.
  void opt(String key, Object? value) {
    if (value != null) {
      _m[key] = value;
    } else {
      _m.remove(key);
    }
  }

  /// Writes [value] unless it equals [def].
  void unlessDefault(String key, Object? value, Object? def) {
    if (value != def) {
      _m[key] = value;
    } else {
      _m.remove(key);
    }
  }

  /// Writes a nested object unless it is empty.
  void nested(String key, Map<String, Object?> value) {
    if (value.isNotEmpty) {
      _m[key] = value;
    } else {
      _m.remove(key);
    }
  }

  /// The result.
  Map<String, Object?> get json => _m;
}

/// Numbers in JSON: integral doubles become ints.
Object jsonNum(double v) =>
    v == v.truncateToDouble() && v.abs() < 1e15 ? v.toInt() : v;

/// Deep equality of JSON maps.
bool jsonEquals(Object? a, Object? b) =>
    const DeepCollectionEquality().equals(a, b);
