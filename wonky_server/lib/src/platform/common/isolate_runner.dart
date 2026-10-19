import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'errors.dart';

/// Runs CPU-heavy work — exports, imports, previews, script compiles,
/// version diffs — in its own isolate (specs/13 §3 "Heavy work", code-
/// quality theme T4):
///
/// - **Killed on timeout.** Unlike `Isolate.run(...).timeout(...)`, which
///   only stops waiting, the isolate is killed, so runaway work really stops
///   and frees its memory. The caller gets a [TimeoutException].
/// - **Cancellable.** [IsolateCancelToken.cancel] (a closed progress stream,
///   a disconnected client) kills the isolate; the caller gets an
///   [IsolateCancelledException].
/// - **A global semaphore.** At most [maxConcurrent] isolates run at once
///   per server instance; later work waits in FIFO order for up to
///   [maxQueueWait] and then fails with `Errors.busy`. Per-user limits stay
///   with the services.
/// - **A channel back.** [runWithChannel]'s work can ask the calling
///   isolate for things only it has (a database session: images from
///   storage) and post progress.
///
/// The work closure and what it captures are copied into the new isolate:
/// capture plain data (bytes, models, options), never a `Session`. Errors
/// thrown by the work are rethrown with their type when they can be sent,
/// else as a [RemoteError].
abstract final class IsolateRunner {
  /// Isolates running at once (per instance).
  static int maxConcurrent = math.max(
    2,
    math.min(8, Platform.numberOfProcessors ~/ 2),
  );

  /// How long work waits for a free slot before it fails with
  /// `Errors.busy`.
  static Duration maxQueueWait = const Duration(seconds: 30);

  static int _running = 0;
  static final Queue<_Waiter> _queue = Queue();

  /// Isolates running now (metrics, tests).
  static int get running => _running;

  /// Work waiting for a slot (metrics, tests).
  static int get queued => _queue.length;

  /// Runs [work] in a new isolate (see the class comment).
  static Future<R> run<R>(
    FutureOr<R> Function() work, {
    required String name,
    required Duration timeout,
    IsolateCancelToken? cancel,
  }) => runWithChannel<R>(
    (_) => work(),
    name: name,
    timeout: timeout,
    cancel: cancel,
  );

  /// Runs [work] in a new isolate with an [IsolateChannel]: its
  /// `request`s are answered by [onRequest] and its `post`s delivered to
  /// [onMessage], both on the calling isolate.
  static Future<R> runWithChannel<R>(
    FutureOr<R> Function(IsolateChannel channel) work, {
    required String name,
    required Duration timeout,
    IsolateCancelToken? cancel,
    Future<Object?> Function(Object? request)? onRequest,
    void Function(Object? message)? onMessage,
  }) async {
    await _acquire(cancel);
    try {
      return await _spawn(
        work,
        name: name,
        timeout: timeout,
        cancel: cancel,
        onRequest: onRequest,
        onMessage: onMessage,
      );
    } finally {
      _release();
    }
  }

  static Future<void> _acquire(IsolateCancelToken? cancel) async {
    if (cancel?.isCancelled ?? false) throw const IsolateCancelledException();
    if (_running < maxConcurrent && _queue.isEmpty) {
      _running++;
      return;
    }
    final waiter = _Waiter();
    _queue.add(waiter);
    void giveUp(Object error) {
      if (waiter.completer.isCompleted) return;
      _queue.remove(waiter);
      waiter.completer.completeError(error);
    }

    final timer = Timer(
      maxQueueWait,
      () => giveUp(
        Errors.busy('The server is busy. Try again in a moment.'),
      ),
    );
    final unlisten = cancel?._listen(
      () => giveUp(const IsolateCancelledException()),
    );
    try {
      // Completed by _release with the slot already counted.
      await waiter.completer.future;
    } finally {
      timer.cancel();
      unlisten?.call();
    }
  }

  static void _release() {
    if (_queue.isNotEmpty) {
      // Hand the slot over (the count stays).
      _queue.removeFirst().completer.complete();
      return;
    }
    _running--;
  }

  static Future<R> _spawn<R>(
    FutureOr<R> Function(IsolateChannel channel) work, {
    required String name,
    required Duration timeout,
    IsolateCancelToken? cancel,
    Future<Object?> Function(Object? request)? onRequest,
    void Function(Object? message)? onMessage,
  }) async {
    final result = Completer<R>();
    final port = RawReceivePort();
    final channelPort = RawReceivePort();
    Isolate? isolate;
    Timer? timer;
    void Function()? unlisten;
    void finish(void Function() complete) {
      if (result.isCompleted) return;
      timer?.cancel();
      unlisten?.call();
      port.close();
      channelPort.close();
      complete();
    }

    void kill(Object error) => finish(() {
      isolate?.kill(priority: Isolate.immediate);
      result.completeError(error);
    });

    port.handler = (Object? message) => finish(() {
      switch (message) {
        case _IsolateValue<R>(:final value):
          result.complete(value);
        case _IsolateError(:final error, :final stackTrace):
          result.completeError(error, stackTrace);
        case [final Object? error, final Object? stack]:
          // `onError`: an uncaught asynchronous error.
          result.completeError(RemoteError('$error', '$stack'));
        default:
          // `onExit` without a result (killed elsewhere, out of memory).
          result.completeError(
            RemoteError('$name stopped without a result.', ''),
          );
      }
    });
    channelPort.handler = (Object? message) {
      switch (message) {
        case _ChannelPost(:final message):
          onMessage?.call(message);
        case _ChannelRequest(:final id, :final message, :final reply):
          unawaited(() async {
            _ChannelReply answer;
            try {
              final handler = onRequest;
              answer = _ChannelReply(
                id,
                handler == null ? null : await handler(message),
              );
            } on Object catch (e) {
              answer = _ChannelReply(id, null, error: '$e');
            }
            if (result.isCompleted) return;
            try {
              reply.send(answer);
            } on Object catch (e) {
              reply.send(_ChannelReply(id, null, error: 'Not sendable: $e'));
            }
          }());
      }
    };
    try {
      isolate = await Isolate.spawn(
        _entry<R>,
        _Start<R>(port.sendPort, channelPort.sendPort, work),
        onExit: port.sendPort,
        onError: port.sendPort,
        debugName: name,
      );
    } on Object {
      port.close();
      channelPort.close();
      rethrow;
    }
    if (!result.isCompleted) {
      timer = Timer(
        timeout,
        () => kill(TimeoutException('$name took too long.', timeout)),
      );
      unlisten = cancel?._listen(
        () => kill(const IsolateCancelledException()),
      );
    }
    return result.future;
  }
}

/// Cancels [IsolateRunner] work: a waiting run leaves the queue, a running
/// one is killed.
final class IsolateCancelToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled;

  /// Cancels the work (idempotent).
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final listeners = List.of(_listeners);
    _listeners.clear();
    for (final l in listeners) {
      l();
    }
  }

  void Function() _listen(void Function() listener) {
    if (_cancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }
}

/// Thrown by [IsolateRunner] when its work was cancelled.
final class IsolateCancelledException implements Exception {
  const IsolateCancelledException();

  @override
  String toString() => 'IsolateCancelledException';
}

/// The worker side of [IsolateRunner.runWithChannel].
abstract interface class IsolateChannel {
  /// Asks the calling isolate; completes with `onRequest`'s answer, or
  /// throws a [RemoteError] when it failed.
  Future<Object?> request(Object? message);

  /// Sends [message] to `onMessage` without waiting (progress).
  void post(Object? message);
}

final class _Waiter {
  final Completer<void> completer = Completer();
}

final class _Start<R> {
  const _Start(this.result, this.channel, this.work);
  final SendPort result;
  final SendPort channel;
  final FutureOr<R> Function(IsolateChannel channel) work;
}

final class _IsolateValue<R> {
  const _IsolateValue(this.value);
  final R value;
}

final class _IsolateError {
  const _IsolateError(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}

final class _ChannelPost {
  const _ChannelPost(this.message);
  final Object? message;
}

final class _ChannelRequest {
  const _ChannelRequest(this.id, this.message, this.reply);
  final int id;
  final Object? message;
  final SendPort reply;
}

final class _ChannelReply {
  const _ChannelReply(this.id, this.value, {this.error});
  final int id;
  final Object? value;
  final String? error;
}

final class _WorkerChannel implements IsolateChannel {
  _WorkerChannel(this._out) {
    _in.handler = (Object? message) {
      if (message is! _ChannelReply) return;
      final c = _pending.remove(message.id);
      if (c == null) return;
      final error = message.error;
      if (error != null) {
        c.completeError(RemoteError(error, ''));
      } else {
        c.complete(message.value);
      }
    };
  }

  final SendPort _out;
  final RawReceivePort _in = RawReceivePort();
  final Map<int, Completer<Object?>> _pending = {};
  int _next = 0;

  @override
  Future<Object?> request(Object? message) {
    final id = _next++;
    final c = Completer<Object?>();
    _pending[id] = c;
    _out.send(_ChannelRequest(id, message, _in.sendPort));
    return c.future;
  }

  @override
  void post(Object? message) => _out.send(_ChannelPost(message));

  void close() => _in.close();
}

Future<void> _entry<R>(_Start<R> start) async {
  final channel = _WorkerChannel(start.channel);
  Object message;
  try {
    message = _IsolateValue<R>(await start.work(channel));
  } catch (e, s) {
    message = _IsolateError(e, s);
  }
  channel.close();
  try {
    Isolate.exit(start.result, message);
  } on Object catch (e) {
    // Not sendable: report it as text.
    final original = message is _IsolateError ? message.error : e;
    Isolate.exit(
      start.result,
      _IsolateError(RemoteError('$original', ''), StackTrace.empty),
    );
  }
}
