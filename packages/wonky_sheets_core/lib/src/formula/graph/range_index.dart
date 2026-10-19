import '../../addressing/grid_geometry.dart';

/// Resolves an id-bounded range key to its current rectangle (null when unresolvable).
typedef RangeResolver<K> = GridRect? Function(K key);

/// Interval index over id-bounded ranges of one sheet (05 §8.3).
///
/// Keys (id-based ranges) are resolved to current indices when the index is (re)built.
/// Inserting or deleting rows preserves the relative order of ids, but rectangles in indices
/// change, so structural changes call [invalidate] and the next query rebuilds lazily
/// (O(n log n)). Identical keys share one entry, so fill-down formulas over the same table cost
/// one entry. Stab and intersect queries are O(log n + k).
final class RangeIndex<K, N> {
  final RangeResolver<K> resolve;
  final Map<K, Set<N>> _sets = {};

  // Built structure (sorted by top).
  List<GridRect> _rects = const [];
  List<Set<N>> _entrySets = const [];
  List<int> _maxBottom = const [];
  bool _built = false;
  final List<(GridRect, Set<N>)> _pending = [];

  /// [_pending] by block of [_blockRows] rows (entries spanning at most
  /// [_maxBlocks] blocks are listed in each); wider entries in
  /// [_pendingWide]. A stab looks at one block instead of every pending
  /// entry: a bulk load adds thousands of keys while it stabs the index for
  /// every cell it writes.
  final Map<int, List<(GridRect, Set<N>)>> _pendingByBlock = {};
  final List<(GridRect, Set<N>)> _pendingWide = [];
  static const _blockRows = 16;
  static const _maxBlocks = 8;

  RangeIndex(this.resolve);

  int get keyCount => _sets.length;

  void add(K key, N node) {
    final existing = _sets[key];
    if (existing != null) {
      existing.add(node);
      return;
    }
    final set = <N>{node};
    _sets[key] = set;
    if (_built) {
      final r = resolve(key);
      if (r != null) _addPending(r, set);
      if (_pending.length > 64 + _rects.length ~/ 8) _built = false;
    }
  }

  void remove(K key, N node) {
    final s = _sets[key];
    if (s == null) return;
    s.remove(node);
    if (s.isEmpty) {
      _sets.remove(key);
      // the (now empty) set may still be referenced by the built structure; it is skipped
    }
  }

  void _addPending(GridRect r, Set<N> set) {
    _pending.add((r, set));
    final first = _blockOf(r.top), last = _blockOf(r.bottom);
    if (last - first >= _maxBlocks) {
      _pendingWide.add((r, set));
      return;
    }
    for (var b = first; b <= last; b++) {
      (_pendingByBlock[b] ??= []).add((r, set));
    }
  }

  static int _blockOf(int row) => row < 0 ? 0 : row ~/ _blockRows;

  /// Marks the resolved rectangles stale (axis inserts/deletes/moves).
  void invalidate() => _built = false;

  void _build() {
    final entries = <(GridRect, Set<N>)>[];
    _sets.forEach((k, s) {
      final r = resolve(k);
      if (r != null) entries.add((r, s));
    });
    entries.sort((a, b) => a.$1.top - b.$1.top);
    _rects = [for (final e in entries) e.$1];
    _entrySets = [for (final e in entries) e.$2];
    _maxBottom = List<int>.filled(_rects.length, 0);
    _buildMax(0, _rects.length - 1);
    _pending.clear();
    _pendingByBlock.clear();
    _pendingWide.clear();
    _built = true;
  }

  int _buildMax(int lo, int hi) {
    if (lo > hi) return -1;
    final mid = (lo + hi) >> 1;
    var m = _rects[mid].bottom;
    final l = _buildMax(lo, mid - 1);
    final r = _buildMax(mid + 1, hi);
    if (l > m) m = l;
    if (r > m) m = r;
    _maxBottom[mid] = m;
    return m;
  }

  /// All nodes whose range contains (row, col).
  void stab(int row, int col, void Function(N node) sink) =>
      intersect(GridRect(row, col, row, col), sink);

  /// All nodes whose range intersects [rect].
  void intersect(GridRect rect, void Function(N node) sink) {
    if (!_built) _build();
    _query(0, _rects.length - 1, rect, sink);
    if (_pending.isEmpty) return;
    final first = _blockOf(rect.top), last = _blockOf(rect.bottom);
    if (last - first >= 4 * _maxBlocks) {
      for (final (r, s) in _pending) {
        if (r.intersects(rect)) s.forEach(sink);
      }
      return;
    }
    for (var b = first; b <= last; b++) {
      final entries = _pendingByBlock[b];
      if (entries == null) continue;
      for (final (r, s) in entries) {
        // Each entry once: in the first block it shares with the query.
        final from = _blockOf(r.top);
        if ((from > first ? from : first) != b) continue;
        if (r.intersects(rect)) s.forEach(sink);
      }
    }
    for (final (r, s) in _pendingWide) {
      if (r.intersects(rect)) s.forEach(sink);
    }
  }

  void _query(int lo, int hi, GridRect q, void Function(N) sink) {
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_maxBottom[mid] < q.top) return;
      _query(lo, mid - 1, q, sink);
      final r = _rects[mid];
      if (r.top > q.bottom) return;
      if (r.bottom >= q.top && r.left <= q.right && r.right >= q.left) {
        _entrySets[mid].forEach(sink);
      }
      lo = mid + 1;
    }
  }

  /// Keys for which [test] holds (used for endpoint queries on deletes).
  Iterable<K> keysWhere(bool Function(K key) test) => _sets.keys.where(test);

  /// Nodes registered for [key].
  Set<N>? nodesOf(K key) => _sets[key];
}
