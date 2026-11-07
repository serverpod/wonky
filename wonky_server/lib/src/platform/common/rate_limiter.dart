import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';

/// A counter shared by all instances (specs/13 §4).
abstract interface class RateCounter {
  /// Increments [key] by [by] and returns the new count; the key expires
  /// after [ttl] (set when it is created). Throws when unreachable.
  Future<int> increment(String key, Duration ttl, {int by = 1});
}

/// [RateCounter] in Redis (`INCR` + `PEXPIRE`).
class RedisRateCounter implements RateCounter {
  RedisRateCounter(this.redis);

  final RedisController redis;

  @override
  Future<int> increment(String key, Duration ttl, {int by = 1}) async {
    final command = await redis.getConnection();
    if (command == null) throw StateError('Redis is unreachable.');
    try {
      final count = await command.send_object(['INCRBY', key, '$by']);
      if (count is! int) throw StateError('Unexpected INCRBY reply: $count');
      if (count == by) {
        await command.send_object(['PEXPIRE', key, '${ttl.inMilliseconds}']);
      }
      return count;
    } on Object {
      // Lets the controller drop a broken connection and reconnect.
      await redis.ping();
      rethrow;
    }
  }
}

/// A generic rate limit: at most [limit] calls per key within [window].
///
/// On a single instance a sliding window in memory; with several instances
/// (Redis enabled, specs/13 §4) a fixed window counted in Redis under
/// `wonky:<name>:rate:<key>:<slot>`, so the limit holds across instances (at
/// a window boundary up to twice the limit can pass within one window).
/// When the counter cannot be reached the in-memory window applies.
///
/// Used by MCP (per token, specs/09 §2) and the board (per user,
/// specs/16 §11).
class RateLimiter {
  RateLimiter({
    required this.name,
    this.limit = 600,
    this.window = const Duration(minutes: 1),
    RateCounter? counter,
    // ignore: prefer_initializing_formals
  }) : _counter = counter;

  /// Namespace of the shared keys.
  final String name;
  final int limit;
  final Duration window;
  final Map<Object, List<DateTime>> _calls = {};
  final RateCounter? _counter;
  RedisRateCounter? _redisCounter;

  RateCounter? get counter {
    if (_counter != null) return _counter;
    RedisController? redis;
    try {
      redis = Serverpod.instance.redisController;
    } on Object {
      return null;
    }
    if (redis == null) return null;
    if (_redisCounter?.redis != redis) _redisCounter = RedisRateCounter(redis);
    return _redisCounter;
  }

  /// Records a call for [key]; returns the retry delay when over the limit
  /// ([limit] overrides the configured one, e.g. from a reloaded config).
  /// [cost] counts the call as that many (a batch of invite emails); a
  /// refused call is not counted in memory, while the shared counter keeps
  /// it (errs on the side of the limit).
  Future<Duration?> check(Object key, {int? limit, int cost = 1}) async {
    final max = limit ?? this.limit;
    final shared = counter;
    if (shared == null) return hit(key, limit: max, cost: cost);
    final now = clock.now();
    final ms = window.inMilliseconds;
    final slot = now.millisecondsSinceEpoch ~/ ms;
    try {
      final count = await shared.increment(
        'wonky:$name:rate:$key:$slot',
        window * 2,
        by: cost,
      );
      if (count <= max) return null;
      return Duration(
        milliseconds: (slot + 1) * ms - now.millisecondsSinceEpoch,
      );
    } on Object {
      return hit(key, limit: max, cost: cost);
    }
  }

  /// Records a call for [key] in this instance's sliding window; returns
  /// the retry delay when over the limit ([cost]: see [check]).
  Duration? hit(Object key, {int? limit, int cost = 1}) {
    final max = limit ?? this.limit;
    final now = clock.now();
    _sweepIfDue(now);
    final list = _calls.putIfAbsent(key, () => []);
    list.removeWhere((t) => now.difference(t) >= window);
    if (list.length + cost > max) {
      // The call fits once enough of the oldest calls left the window.
      if (cost > max) return window;
      return window - now.difference(list[list.length + cost - max - 1]);
    }
    for (var i = 0; i < cost; i++) {
      list.add(now);
    }
    return null;
  }

  /// Most keys kept in memory; beyond it the least recently used go
  /// (their windows restart, which errs on the side of letting calls in).
  static const maxKeys = 10000;

  DateTime? _lastSweep;

  /// Drops the keys whose newest call is outside the window, at most once
  /// per window (or when over [maxKeys]), so the map holds only keys
  /// active within the last window.
  void _sweepIfDue(DateTime now) {
    final last = _lastSweep;
    if (last != null &&
        now.difference(last) < window &&
        _calls.length < maxKeys) {
      return;
    }
    _lastSweep = now;
    _calls.removeWhere((_, v) => v.isEmpty || now.difference(v.last) >= window);
    if (_calls.length < maxKeys) return;
    // Still full: keep the most recently used three quarters.
    final keys = _calls.keys.toList()
      ..sort((a, b) => _calls[a]!.last.compareTo(_calls[b]!.last));
    for (final k in keys.take(_calls.length - maxKeys * 3 ~/ 4)) {
      _calls.remove(k);
    }
  }

  /// The number of keys held in memory (tests).
  int get trackedKeys => _calls.length;

  void reset() {
    _calls.clear();
    _lastSweep = null;
  }
}
