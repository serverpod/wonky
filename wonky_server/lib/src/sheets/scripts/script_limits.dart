import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

/// Sliding-window rate limits of the script endpoints (Sheets 09 §9.5,
/// §10): at most [max] events per [window] and key. In-memory per server
/// instance (a user hitting several instances gets the limit per
/// instance).
final class ScriptRateLimiter {
  ScriptRateLimiter({required this.max, required this.window});

  /// Compiles per project and hour (09 §10).
  static final compiles = ScriptRateLimiter(
    max: 20,
    window: const Duration(hours: 1),
  );

  /// Live analyses per user and minute (09 §9.5).
  static final analyses = ScriptRateLimiter(
    max: 30,
    window: const Duration(minutes: 1),
  );

  final int max;
  final Duration window;
  final Map<String, Queue<DateTime>> _events = {};

  /// Records an event for [key]; returns false (and records nothing) when
  /// the limit is reached.
  bool tryAcquire(String key) {
    final now = clock.now();
    final q = _events.putIfAbsent(key, Queue.new);
    while (q.isNotEmpty && now.difference(q.first) >= window) {
      q.removeFirst();
    }
    if (q.length >= max) return false;
    q.addLast(now);
    if (_events.length > 10000) _prune(now);
    return true;
  }

  /// When [key] may run again (null = now).
  Duration? retryAfter(String key) {
    final q = _events[key];
    if (q == null || q.length < max) return null;
    return window - clock.now().difference(q.first);
  }

  void _prune(DateTime now) => _events.removeWhere(
    (_, q) => q.isEmpty || now.difference(q.last) >= window,
  );

  /// Forgets every event (tests).
  void reset() => _events.clear();
}

/// "Latest wins" coalescing of compiles per project (09 §9.2): while a
/// compile of a project runs, further requests wait for one follow-up
/// compile of the latest sources instead of queueing one each.
final class CompileCoalescer {
  CompileCoalescer._();

  static final instance = CompileCoalescer._();

  final Map<String, Future<Object?>> _running = {};
  final Map<String, Future<Object?>> _next = {};

  /// Runs [compile] for [key], or joins the pending follow-up.
  Future<T> run<T>(String key, Future<T> Function() compile) {
    final running = _running[key];
    if (running == null) {
      final f = compile();
      _running[key] = f;
      f.whenComplete(() {
        if (identical(_running[key], f)) unawaited(_running.remove(key));
      }).ignore();
      return f;
    }
    final next = _next[key];
    if (next != null) return next as Future<T>;
    final follow = running.catchError((Object _) => null).then((_) {
      unawaited(_next.remove(key));
      return run<T>(key, compile);
    });
    _next[key] = follow;
    return follow;
  }
}

/// Server-side cache of custom-function URL fetches (09 §8.3 step 8):
/// successful responses for 1 hour, keyed by method, URL, headers and
/// body. Bodies over 1 MB are not cached.
final class ScriptFetchCache {
  ScriptFetchCache({
    this.maxEntries = 2000,
    this.ttl = const Duration(hours: 1),
  });

  static final instance = ScriptFetchCache();

  static const maxBodyBytes = 1024 * 1024;

  final int maxEntries;
  final Duration ttl;

  // ignore: prefer_collection_literals
  final LinkedHashMap<String, (FetchResponseData, DateTime)> _entries =
      LinkedHashMap();

  static String keyOf(FetchRequestData r) {
    final headers =
        (r.headers.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
            .map((e) => '${e.key.toLowerCase()}:${e.value}')
            .join('\n');
    final digest = sha256.convert(
      utf8.encode('${r.method}\n${r.url}\n$headers\n${r.payload ?? ''}'),
    );
    return '$digest';
  }

  FetchResponseData? get(FetchRequestData r) {
    final key = keyOf(r);
    final e = _entries[key];
    if (e == null) return null;
    if (!clock.now().isBefore(e.$2)) {
      _entries.remove(key);
      return null;
    }
    return e.$1;
  }

  void put(FetchRequestData r, FetchResponseData response) {
    if (response.statusCode < 200 || response.statusCode >= 300) return;
    if (response.bytes.length > maxBodyBytes) return;
    final key = keyOf(r);
    _entries.remove(key);
    _entries[key] = (response, clock.now().add(ttl));
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  int get length => _entries.length;

  void clear() => _entries.clear();
}
