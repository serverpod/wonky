import 'dart:async';

/// Mutual exclusion per key within one server instance, first come first
/// served, with a bounded wait: the planning locks of the headless
/// spreadsheet and deck writes (Sheets 12 §2.3, Slides 11 §2.1), shared by
/// both apps (CQ-52).
///
/// A caller that gives up waiting (after [timeout]) keeps its place in the
/// queue until the holder ahead of it is done, so the next caller is never
/// let in while that holder still runs (CQ-8).
final class KeyedLock {
  KeyedLock({this.timeout = const Duration(seconds: 30)});

  /// How long [run] waits for the lock before it fails.
  Duration timeout;

  final Map<String, Future<void>> _tails = {};

  /// Keys that are held or waited for (tests).
  int get length => _tails.length;

  /// Whether [key] is held or waited for.
  bool isLocked(String key) => _tails.containsKey(key);

  /// Runs [body] holding the lock of [key]. When the lock is not free
  /// within [timeout], throws `busy()` without running [body].
  Future<T> run<T>(
    String key,
    Future<T> Function() body, {
    required Object Function() busy,
  }) async {
    final previous = _tails[key];
    final done = Completer<void>();
    final mine = done.future;
    _tails[key] = mine;
    void release() {
      done.complete();
      if (identical(_tails[key], mine)) unawaited(_tails.remove(key));
    }

    if (previous != null) {
      try {
        await previous.timeout(timeout);
      } on TimeoutException {
        // Pass the turn on only once the holder ahead is done.
        unawaited(previous.whenComplete(release));
        throw busy();
      }
    }
    try {
      return await body();
    } finally {
      release();
    }
  }
}
