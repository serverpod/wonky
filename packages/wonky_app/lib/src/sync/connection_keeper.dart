import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import '../core/connectivity_service.dart';
import '../core/stream_supervisor.dart';

/// Keeps a long-lived stream connected (Write 03 §3.1): opens it, re-opens it
/// with backoff after it ends or fails, and immediately when connectivity
/// returns.
///
/// [ShellConnectionKeeper] delegates to the shell's `StreamSupervisor` and
/// `ConnectivityService`; [SimpleConnectionKeeper] is a self-contained
/// implementation (tests, headless use).
abstract interface class ConnectionKeeper {
  /// Starts keeping [key] connected. [open] is called for every attempt;
  /// [onData] receives every event of the current connection.
  void keep<T>(
    String key,
    Stream<T> Function() open,
    void Function(T event) onData, {
    void Function(Object error)? onError,
  });

  /// Reconnects [key] now (the sync status "Retry" button).
  void reconnectNow(String key);

  /// Stops keeping [key] connected and closes the connection.
  Future<void> stop(String key);

  /// Whether the server is believed to be reachable.
  bool get online;

  /// Notifies when [online] changes.
  Listenable get connectivity;

  /// When the next reconnect attempt is due (offline only).
  DateTime? get nextAttemptAt;
}

class _Kept {
  _Kept(this.restart);

  /// Re-supervises the stream (captures its type).
  final void Function() restart;
}

/// [ConnectionKeeper] on top of the shell's stream supervisor.
class ShellConnectionKeeper implements ConnectionKeeper {
  ShellConnectionKeeper(this.supervisor, this.connectivityService);

  final StreamSupervisor supervisor;
  final ConnectivityService connectivityService;
  final Map<String, _Kept> _kept = {};

  @override
  void keep<T>(
    String key,
    Stream<T> Function() open,
    void Function(T event) onData, {
    void Function(Object error)? onError,
  }) {
    void start() =>
        supervisor.supervise<T>(key, open, onData, onError: onError);
    _kept[key] = _Kept(start);
    start();
  }

  @override
  void reconnectNow(String key) {
    final k = _kept[key];
    if (k == null) return;
    unawaited(connectivityService.reconnect());
    k.restart();
  }

  @override
  Future<void> stop(String key) async {
    _kept.remove(key);
    await supervisor.cancel(key);
  }

  @override
  bool get online => connectivityService.online;

  @override
  Listenable get connectivity => connectivityService;

  @override
  DateTime? get nextAttemptAt => connectivityService.nextAttemptAt;
}

/// A self-contained [ConnectionKeeper]: reconnects with exponential backoff
/// ([minDelay] → [maxDelay], ±20 % jitter). Setting [online] to false drops
/// the connection and pauses reconnects (simulated network loss).
class SimpleConnectionKeeper extends ChangeNotifier
    implements ConnectionKeeper {
  SimpleConnectionKeeper({
    this.minDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    Random? random,
  }) : _random = random ?? Random();

  final Duration minDelay;
  final Duration maxDelay;
  final Random _random;
  final Map<String, _SimpleEntry<dynamic>> _entries = {};
  bool _online = true;
  DateTime? _nextAttemptAt;

  @override
  void keep<T>(
    String key,
    Stream<T> Function() open,
    void Function(T event) onData, {
    void Function(Object error)? onError,
  }) {
    _entries.remove(key)?.dispose();
    final e = _SimpleEntry<T>(open, onData, onError);
    _entries[key] = e;
    _connect(key, e);
  }

  void _connect<T>(String key, _SimpleEntry<T> e) {
    e.retry?.cancel();
    if (!_online || _entries[key] != e) return;
    try {
      e.listen(onError: () => _retry(key, e), onDone: () => _retry(key, e));
    } catch (error) {
      e.onError?.call(error);
      _retry(key, e);
    }
  }

  void _retry<T>(String key, _SimpleEntry<T> e) {
    if (_entries[key] != e) return;
    e.failures++;
    final base = min(
      maxDelay.inMilliseconds,
      minDelay.inMilliseconds * pow(2, e.failures - 1).toInt(),
    );
    final ms = (base * (0.8 + _random.nextDouble() * 0.4)).round();
    _nextAttemptAt = DateTime.now().add(Duration(milliseconds: ms));
    e.retry?.cancel();
    e.retry = Timer(Duration(milliseconds: ms), () => _connect(key, e));
  }

  @override
  void reconnectNow(String key) {
    final e = _entries[key];
    if (e == null) return;
    e.failures = 0;
    _connect(key, e);
  }

  @override
  Future<void> stop(String key) async => _entries.remove(key)?.dispose();

  @override
  bool get online => _online;

  set online(bool value) {
    if (value == _online) return;
    _online = value;
    if (!value) {
      for (final e in _entries.values) {
        e.retry?.cancel();
        unawaited(e.sub?.cancel());
        e.sub = null;
      }
    } else {
      for (final entry in _entries.entries) {
        entry.value.failures = 0;
        _connect(entry.key, entry.value);
      }
    }
    notifyListeners();
  }

  @override
  Listenable get connectivity => this;

  @override
  DateTime? get nextAttemptAt => _online ? null : _nextAttemptAt;

  @override
  void dispose() {
    for (final e in _entries.values) {
      e.dispose();
    }
    _entries.clear();
    super.dispose();
  }
}

class _SimpleEntry<T> {
  _SimpleEntry(this.open, this.onData, this.onError);

  final Stream<T> Function() open;
  final void Function(T event) onData;
  final void Function(Object error)? onError;
  StreamSubscription<T>? sub;
  Timer? retry;
  int failures = 0;

  void listen({
    required void Function() onError,
    required void Function() onDone,
  }) {
    unawaited(sub?.cancel());
    sub = open().listen(
      (data) {
        failures = 0;
        onData(data);
      },
      onError: (Object error) {
        this.onError?.call(error);
        onError();
      },
      onDone: onDone,
      cancelOnError: true,
    );
  }

  void dispose() {
    retry?.cancel();
    unawaited(sub?.cancel());
  }
}
