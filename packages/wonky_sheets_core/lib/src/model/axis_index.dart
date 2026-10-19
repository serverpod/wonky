import 'dart:collection';
import 'dart:typed_data';

import 'package:wonky_sync_models/ids.dart';

/// Ordered row or column entities of one sheet (02 §6).
///
/// Entries are sorted by `(sortKey, id)`. Holds an id → index map and a Fenwick
/// tree of effective sizes (hidden = 0 px) for O(log n) pixel ↔ index lookups.
///
/// Mutations ([upsert], [remove]) are buffered and merged on the next read, so
/// bulk ingestion (loading 1M rows, applying a 5,000-row chunk) costs
/// O(n + k log k) instead of O(n·k).
final class AxisIndex {
  /// Creates an empty axis whose rows/columns are [_defaultSize] px by default.
  AxisIndex({this._defaultSize = 21});

  double _defaultSize;

  final List<String> _ids = [];
  final List<String> _keys = [];
  final List<double?> _sizes = [];
  final List<bool> _userHidden = [];

  // Pending mutations.
  final Map<String, _Entry> _pendingUpserts = {};
  final Set<String> _pendingRemoves = {};

  // Index: every id has a stable handle; [_positions] maps handles to indexes.
  // A small insert or remove only rewrites the positions after it (typed
  // array writes, no hashing). Null until first needed after a rebuild.
  Map<String, int>? _handleOf;
  final List<int> _handles = [];
  Int32List _positions = Int32List(0);
  final List<int> _freeHandles = [];
  int _nextHandle = 0;
  Float64List? _fenwick;
  Float64List? _effective;

  final Map<String, Set<String>> _hiddenLayers = {};
  Set<String>? _computedHidden;
  final Map<String, double> _autoSizes = {};
  Int32List? _visiblePrefix;

  int _generation = 0;

  /// Incremented on every structural change (insert/remove/reorder).
  int get generation {
    _flush();
    return _generation;
  }

  /// Default size in px (sheet `defaultRowHeight` / `defaultColumnWidth`).
  double get defaultSize => _defaultSize;

  set defaultSize(double v) {
    if (v == _defaultSize) return;
    _defaultSize = v;
    _fenwick = null;
    _effective = null;
  }

  /// Number of entries.
  int get length {
    _flush();
    return _ids.length;
  }

  /// Ids in order (read-only view).
  List<String> get ids {
    _flush();
    return UnmodifiableListView(_ids);
  }

  /// Id at [index].
  String idAt(int index) {
    _flush();
    return _ids[index];
  }

  /// Id at [index] or null when out of range.
  String? tryIdAt(int index) {
    _flush();
    return index >= 0 && index < _ids.length ? _ids[index] : null;
  }

  /// Sort key at [index].
  String sortKeyAt(int index) {
    _flush();
    return _keys[index];
  }

  /// Sort key of [id] or null.
  String? sortKeyOf(String id) {
    final i = indexOf(id);
    return i < 0 ? null : _keys[i];
  }

  /// Index of [id], or -1.
  int indexOf(String id) {
    _flush();
    return _positionOf(id);
  }

  int _positionOf(String id) {
    final h = (_handleOf ?? _buildIndex())[id];
    return h == null ? -1 : _positions[h];
  }

  Map<String, int> _buildIndex() {
    final n = _ids.length;
    _handles
      ..clear()
      ..addAll(List<int>.generate(n, (i) => i));
    _positions = Int32List(n < 16 ? 16 : n);
    for (var i = 0; i < n; i++) {
      _positions[i] = i;
    }
    _freeHandles.clear();
    _nextHandle = n;
    return _handleOf = {for (var i = 0; i < n; i++) _ids[i]: i};
  }

  int _newHandle() {
    if (_freeHandles.isNotEmpty) return _freeHandles.removeLast();
    final h = _nextHandle++;
    if (h >= _positions.length) {
      _positions = Int32List(_positions.length * 2)..setAll(0, _positions);
    }
    return h;
  }

  /// Whether [id] exists.
  bool contains(String id) => indexOf(id) >= 0;

  /// Explicit size at [index] (null = default/auto).
  double? explicitSizeAt(int index) {
    _flush();
    return _sizes[index];
  }

  /// Whether the entry at [index] is hidden by the user (`hidden` column).
  bool isUserHidden(int index) {
    _flush();
    return _userHidden[index];
  }

  /// Whether the entry at [index] is hidden (user-hidden, or by a computed
  /// layer such as filters or collapsed groups when [includeComputed]).
  bool isHidden(int index, {bool includeComputed = true}) {
    _flush();
    if (_userHidden[index]) return true;
    if (!includeComputed) return false;
    return _computed().contains(_ids[index]);
  }

  /// Whether the entry is hidden by computed layer [layer].
  bool isHiddenBy(String layer, int index) {
    _flush();
    return _hiddenLayers[layer]?.contains(_ids[index]) ?? false;
  }

  /// Replaces the ids hidden by computed layer [layer] (`filter`, `groups`, …).
  /// An empty set removes the layer.
  void setHiddenLayer(String layer, Set<String> ids) {
    if (ids.isEmpty) {
      if (_hiddenLayers.remove(layer) == null) return;
    } else {
      _hiddenLayers[layer] = Set.of(ids);
    }
    _computedHidden = null;
    _fenwick = null;
    _effective = null;
    _visiblePrefix = null;
  }

  /// Ids hidden by [layer].
  Set<String> hiddenLayer(String layer) => _hiddenLayers[layer] ?? const {};

  final Set<String> _suppressed = {};

  /// Suppresses (or restores) computed layer [layer] in the effective
  /// visibility ([isHidden], sizes) while keeping its ids: [isHiddenBy] and
  /// [hiddenLayer] still report them (an active filter view replaces the
  /// basic filter on screen while `SUBTOTAL` keeps using it, 07 §4.3).
  void setLayerSuppressed(String layer, bool suppressed) {
    final changed = suppressed
        ? _suppressed.add(layer)
        : _suppressed.remove(layer);
    if (!changed) return;
    _computedHidden = null;
    _fenwick = null;
    _effective = null;
    _visiblePrefix = null;
  }

  /// Whether computed layer [layer] is suppressed.
  bool isLayerSuppressed(String layer) => _suppressed.contains(layer);

  /// Sets the measured automatic size of [id] (rows with automatic height).
  void setAutoSize(String id, double? px) {
    if (px == null) {
      if (_autoSizes.remove(id) == null) return;
    } else {
      if (_autoSizes[id] == px) return;
      _autoSizes[id] = px;
    }
    final i = indexOf(id);
    if (i >= 0) _pointUpdate(i);
  }

  /// Effective size at [index] (0 when hidden).
  double sizeAt(int index) {
    _flush();
    return _effectiveSizes()[index];
  }

  /// Size at [index] ignoring hidden flags.
  double naturalSizeAt(int index) {
    _flush();
    return _sizes[index] ?? _autoSizes[_ids[index]] ?? _defaultSize;
  }

  /// Pixel offset of the start of [index] (sum of sizes before it).
  double offsetOf(int index) {
    _flush();
    final f = _tree();
    var i = index.clamp(0, _ids.length);
    var sum = 0.0;
    while (i > 0) {
      sum += f[i];
      i -= i & -i;
    }
    return sum;
  }

  /// Total size in px.
  double get totalSize => offsetOf(length);

  /// Index whose span contains [px] (clamped to `[0, length-1]`); hidden
  /// entries are skipped. Returns -1 when empty.
  int indexAtOffset(double px) {
    _flush();
    final n = _ids.length;
    if (n == 0) return -1;
    if (px <= 0) return nextVisible(0, 1) ?? 0;
    final f = _tree();
    var pos = 0;
    var rem = px;
    var step = 1;
    while (step * 2 <= n) {
      step *= 2;
    }
    for (; step > 0; step >>= 1) {
      final next = pos + step;
      if (next <= n && f[next] <= rem) {
        pos = next;
        rem -= f[next];
      }
    }
    // pos = number of entries fully before px.
    if (pos >= n) return nextVisible(n - 1, -1) ?? n - 1;
    return nextVisible(pos, 1) ?? nextVisible(pos, -1) ?? pos;
  }

  /// The first visible index at or after [from] (dir 1) / at or before (dir −1).
  int? nextVisible(int from, int dir) {
    _flush();
    var i = from;
    while (i >= 0 && i < _ids.length) {
      if (!isHidden(i)) return i;
      i += dir;
    }
    return null;
  }

  /// Visible indices in `[from, to]`.
  Iterable<int> visibleIndices(int from, int to) sync* {
    _flush();
    final hi = to < _ids.length - 1 ? to : _ids.length - 1;
    for (var i = from < 0 ? 0 : from; i <= hi; i++) {
      if (!isHidden(i)) yield i;
    }
  }

  /// Number of visible entries with index < [index].
  int visibleCountBefore(int index) {
    _flush();
    var p = _visiblePrefix;
    if (p == null) {
      final computed = _computed();
      p = Int32List(_ids.length + 1);
      for (var i = 0; i < _ids.length; i++) {
        p[i + 1] =
            p[i] + (_userHidden[i] || computed.contains(_ids[i]) ? 0 : 1);
      }
      _visiblePrefix = p;
    }
    return p[index.clamp(0, _ids.length)];
  }

  /// Number of visible entries in `[from, to]`.
  int visibleCount(int from, int to) =>
      to < from ? 0 : visibleCountBefore(to + 1) - visibleCountBefore(from);

  /// The index at which an entry with `(sortKey, id)` would be inserted, i.e.
  /// the number of entries ordered before it. Used to resolve deleted range
  /// endpoints from their `K:` hints (05 §5.4).
  int insertionIndex(String sortKey, String id) {
    _flush();
    var lo = 0;
    var hi = _ids.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (FractionalIndex.compare(_keys[mid], _ids[mid], sortKey, id) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Inserts or updates an entry.
  void upsert(String id, String sortKey, {double? size, bool hidden = false}) {
    _pendingRemoves.remove(id);
    _pendingUpserts[id] = _Entry(id, sortKey, size, hidden);
  }

  /// Removes an entry (no-op if missing).
  void remove(String id) {
    _pendingUpserts.remove(id);
    _pendingRemoves.add(id);
  }

  /// Replaces all entries (bulk load).
  void load(
    Iterable<(String id, String sortKey, double? size, bool hidden)> entries,
  ) {
    _pendingUpserts.clear();
    _pendingRemoves.clear();
    final list = [for (final e in entries) _Entry(e.$1, e.$2, e.$3, e.$4)]
      ..sort((a, b) => FractionalIndex.compare(a.key, a.id, b.key, b.id));
    _ids
      ..clear()
      ..addAll(list.map((e) => e.id));
    _keys
      ..clear()
      ..addAll(list.map((e) => e.key));
    _sizes
      ..clear()
      ..addAll(list.map((e) => e.size));
    _userHidden
      ..clear()
      ..addAll(list.map((e) => e.hidden));
    _structuralChange();
  }

  void _flush() {
    if (_pendingUpserts.isEmpty && _pendingRemoves.isEmpty) return;
    final upserts = Map.of(_pendingUpserts);
    final removes = Set.of(_pendingRemoves);
    _pendingUpserts.clear();
    _pendingRemoves.clear();

    // Fast path: only attribute updates of existing entries with unchanged keys.
    if (removes.isEmpty) {
      var allInPlace = true;
      for (final e in upserts.values) {
        final i = _positionOf(e.id);
        if (i < 0 || _keys[i] != e.key) {
          allInPlace = false;
          break;
        }
      }
      if (allInPlace) {
        for (final e in upserts.values) {
          final i = _positionOf(e.id);
          _sizes[i] = e.size;
          _userHidden[i] = e.hidden;
          _pointUpdate(i);
        }
        return;
      }
    }

    if (upserts.length + removes.length <= _incrementalLimit) {
      _flushInPlace(upserts, removes);
      return;
    }

    // General path: rebuild by merging.
    final keep = <_Entry>[];
    for (var i = 0; i < _ids.length; i++) {
      final id = _ids[i];
      if (removes.contains(id) || upserts.containsKey(id)) continue;
      keep.add(_Entry(id, _keys[i], _sizes[i], _userHidden[i]));
    }
    final added = upserts.values.toList()
      ..sort((a, b) => FractionalIndex.compare(a.key, a.id, b.key, b.id));
    final merged = <_Entry>[];
    var i = 0;
    var j = 0;
    while (i < keep.length || j < added.length) {
      if (j >= added.length ||
          (i < keep.length &&
              FractionalIndex.compare(
                    keep[i].key,
                    keep[i].id,
                    added[j].key,
                    added[j].id,
                  ) <=
                  0)) {
        merged.add(keep[i++]);
      } else {
        merged.add(added[j++]);
      }
    }
    _ids
      ..clear()
      ..addAll(merged.map((e) => e.id));
    _keys
      ..clear()
      ..addAll(merged.map((e) => e.key));
    _sizes
      ..clear()
      ..addAll(merged.map((e) => e.size));
    _userHidden
      ..clear()
      ..addAll(merged.map((e) => e.hidden));
    for (final id in removes) {
      _autoSizes.remove(id);
    }
    _structuralChange();
  }

  /// Batches up to this many entries are applied in place.
  static const int _incrementalLimit = 64;

  /// Applies a small batch in place: removes and inserts at their sorted
  /// positions (same order as the merge); only the positions after the first
  /// change are rewritten.
  void _flushInPlace(Map<String, _Entry> upserts, Set<String> removes) {
    final handleOf = _handleOf ?? _buildIndex();
    var low = _ids.length;
    final drop = <int>[
      for (final id in [...removes, ...upserts.keys])
        if (_positionOf(id) case final i when i >= 0) i,
    ]..sort();
    for (var k = drop.length - 1; k >= 0; k--) {
      final i = drop[k];
      _freeHandles.add(handleOf.remove(_ids[i])!);
      _handles.removeAt(i);
      _ids.removeAt(i);
      _keys.removeAt(i);
      _sizes.removeAt(i);
      _userHidden.removeAt(i);
      if (i < low) low = i;
    }
    final added = upserts.values.toList()
      ..sort((a, b) => FractionalIndex.compare(a.key, a.id, b.key, b.id));
    for (final e in added) {
      final i = insertionIndex(e.key, e.id);
      final h = _newHandle();
      handleOf[e.id] = h;
      _handles.insert(i, h);
      _ids.insert(i, e.id);
      _keys.insert(i, e.key);
      _sizes.insert(i, e.size);
      _userHidden.insert(i, e.hidden);
      if (i < low) low = i;
    }
    for (final id in removes) {
      _autoSizes.remove(id);
    }
    _fenwick = null;
    _effective = null;
    _visiblePrefix = null;
    _generation++;
    for (var i = low; i < _ids.length; i++) {
      _positions[_handles[i]] = i;
    }
  }

  void _structuralChange() {
    _handleOf = null;
    _fenwick = null;
    _effective = null;
    _visiblePrefix = null;
    _generation++;
  }

  Set<String> _computed() {
    final c = _computedHidden;
    if (c != null) return c;
    final layers = [
      for (final e in _hiddenLayers.entries)
        if (!_suppressed.contains(e.key)) e.value,
    ];
    if (layers.isEmpty) return _computedHidden = const {};
    if (layers.length == 1) return _computedHidden = layers.first;
    return _computedHidden = {for (final s in layers) ...s};
  }

  double _sizeOf(int i, Set<String> computed) {
    if (_userHidden[i] || computed.contains(_ids[i])) return 0;
    return _sizes[i] ?? _autoSizes[_ids[i]] ?? _defaultSize;
  }

  Float64List _effectiveSizes() {
    final e = _effective;
    if (e != null) return e;
    final computed = _computed();
    final out = Float64List(_ids.length);
    for (var i = 0; i < out.length; i++) {
      out[i] = _sizeOf(i, computed);
    }
    return _effective = out;
  }

  Float64List _tree() {
    final f = _fenwick;
    if (f != null) return f;
    final sizes = _effectiveSizes();
    final n = sizes.length;
    final t = Float64List(n + 1);
    for (var i = 0; i < n; i++) {
      t[i + 1] += sizes[i];
      final parent = (i + 1) + ((i + 1) & -(i + 1));
      if (parent <= n) t[parent] += t[i + 1];
    }
    return _fenwick = t;
  }

  void _pointUpdate(int i) {
    _visiblePrefix = null;
    final eff = _effective;
    if (eff == null) {
      _fenwick = null;
      return;
    }
    final next = _sizeOf(i, _computed());
    final delta = next - eff[i];
    if (delta == 0) return;
    eff[i] = next;
    final f = _fenwick;
    if (f == null) return;
    var k = i + 1;
    while (k < f.length) {
      f[k] += delta;
      k += k & -k;
    }
  }
}

final class _Entry {
  const _Entry(this.id, this.key, this.size, this.hidden);
  final String id;
  final String key;
  final double? size;
  final bool hidden;
}
