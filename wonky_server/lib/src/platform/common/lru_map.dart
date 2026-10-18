import 'dart:collection';

/// A map with at most [maxEntries] entries that evicts the least recently
/// used one (code-quality theme T5: per-instance maps keyed by users,
/// files or results must not grow without bound). Reads with [get] and
/// writes with [put] count as uses.
///
/// For values that are loaded from the database and may be shared across
/// instances, prefer `session.caches.local`; this is for process-local
/// state (throttles, in-flight results, rate windows).
final class LruMap<K, V> {
  LruMap(this.maxEntries) : assert(maxEntries > 0);

  /// The capacity.
  final int maxEntries;

  final LinkedHashMap<K, V> _map = LinkedHashMap();

  /// The value of [key] (marks it as recently used), or null.
  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    final v = _map.remove(key) as V;
    _map[key] = v;
    return v;
  }

  /// The value of [key] without marking it as used, or null.
  V? peek(K key) => _map[key];

  /// Sets [key] (as the most recently used) and evicts the oldest entries
  /// past [maxEntries].
  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    while (_map.length > maxEntries) {
      _map.remove(_map.keys.first);
    }
  }

  /// Removes [key]; returns its value.
  V? remove(K key) => _map.remove(key);

  /// Removes the entries [test] matches.
  void removeWhere(bool Function(K key, V value) test) =>
      _map.removeWhere(test);

  /// Whether [key] is present.
  bool containsKey(K key) => _map.containsKey(key);

  /// The number of entries.
  int get length => _map.length;

  /// The keys, least recently used first.
  Iterable<K> get keys => _map.keys;

  /// Removes everything.
  void clear() => _map.clear();
}
