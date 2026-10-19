import 'dart:async';

import 'package:async/async.dart';

import 'wonky_serverpod.dart';

/// Listens to [stream] and returns its queue once the server side is
/// subscribed: [probe] posts a harmless event until one arrives (the probe
/// events are consumed). Deterministic replacement for "wait until the
/// endpoint registered its listener".
Future<StreamQueue<T>> subscribed<T>(
  Stream<T> stream,
  Future<void> Function() probe, {
  int maxAttempts = 200,
}) async {
  final queue = StreamQueue<T>(stream);
  for (var i = 0; i < maxAttempts; i++) {
    await probe();
    await flushEventQueue();
    final hasEvent = await queue.hasNext.timeout(
      const Duration(milliseconds: 25),
      onTimeout: () => false,
    );
    if (hasEvent) {
      await queue.next;
      // Drain further probe events that are already buffered.
      while (await queue.hasNext.timeout(
        const Duration(milliseconds: 25),
        onTimeout: () => false,
      )) {
        await queue.next;
      }
      return queue;
    }
  }
  throw StateError('The stream never subscribed.');
}

/// The next event of [queue] matching [test] (others are skipped).
Future<T> nextWhere<T>(
  StreamQueue<T> queue,
  bool Function(T event) test, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final watch = Stopwatch()..start();
  while (true) {
    final remaining = timeout - watch.elapsed;
    if (remaining.isNegative) throw TimeoutException('No matching event');
    final event = await queue.next.timeout(remaining);
    if (test(event)) return event;
  }
}
