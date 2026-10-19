import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import 'cluster.dart';

/// The bus channels (`doc:`, `presence:`, drive, comments, notifications,
/// themes, `sheets:merged:`) with batched relaying between instances
/// (specs/13 §4).
///
/// A message is delivered to this instance's listeners at once. For the
/// other instances it is queued and sent with everything else queued in
/// one Redis publish on [channel] every [flushInterval] (or sooner when the
/// batch reaches [maxBatchBytes]). Messages with a coalesce key (cursors,
/// presence updates, heartbeats) replace their queued predecessor, so a
/// batch only carries the latest. Without Redis the bus is local only.
abstract final class ClusterBus {
  /// The channel all batches are published on.
  static const channel = 'wonky:bus';

  /// How long messages wait for other instances (`cluster.busFlushMs`).
  static Duration flushInterval = const Duration(seconds: 1);

  /// A queued batch this large is sent at once.
  static const maxBatchBytes = 256 * 1024;

  /// Replaces the Redis publish (tests run without Redis).
  static Future<void> Function(ClusterBusBatch batch)? debugPublish;

  static final _outboxes = Expando<_Outbox>('clusterBusOutbox');
  static final _listening = Expando<Future<void>>('clusterBusListening');

  /// Posts [message] on [channelName]. [coalesceKey] (unique within the
  /// channel) lets a later message replace this one while both are queued.
  /// With [immediate], the queue (this message and everything before it, so
  /// the order holds) is published now instead of after [flushInterval]: ops
  /// that other instances must apply without a second of delay.
  static Future<void> post(
    Session session,
    String channelName,
    SerializableModel message, {
    String? coalesceKey,
    bool immediate = false,
  }) => postOn(
    session.serverpod,
    channelName,
    message,
    coalesceKey: coalesceKey,
    immediate: immediate,
  );

  /// [post] without a session (timers).
  static Future<void> postOn(
    Serverpod pod,
    String channelName,
    SerializableModel message, {
    String? coalesceKey,
    bool immediate = false,
  }) async {
    await pod.server.messageCentral.postMessage(
      channelName,
      message,
      scope: MessageScope.local,
    );
    if (!_remote(pod)) return;
    unawaited(listen(pod));
    (_outboxes[pod] ??= _Outbox(pod)).add(
      channelName,
      message,
      coalesceKey,
      immediate: immediate,
    );
  }

  static bool _remote(Serverpod pod) =>
      debugPublish != null || pod.redisController != null;

  /// Receives the other instances' batches. Called at start; idempotent.
  static Future<void> listen(Serverpod pod) {
    if (pod.redisController == null) return Future.value();
    return _listening[pod] ??= () async {
      final session = await pod.createSession(enableLogging: false);
      session.messages.addListener(channel, (m) => receive(pod, m));
    }();
  }

  /// Delivers a batch of another instance to this instance's listeners.
  static void receive(Serverpod pod, SerializableModel message) {
    if (message is! ClusterBusBatch) return;
    if (message.originInstance == Cluster.instanceId) return;
    final central = pod.server.messageCentral;
    final count = message.channels.length;
    for (var i = 0; i < count && i < message.messages.length; i++) {
      final decoded = pod.serializationManager.decodeWithType(
        message.messages[i],
      );
      if (decoded is! SerializableModel) continue;
      unawaited(
        central.postMessage(
          message.channels[i],
          decoded,
          scope: MessageScope.local,
        ),
      );
    }
  }

  /// Sends the queued messages now (tests, shutdown).
  static Future<void> flush(Serverpod pod) =>
      _outboxes[pod]?.flush() ?? Future.value();
}

class _Outbox {
  _Outbox(this.pod);

  final Serverpod pod;
  final _queue = <Object, (String, String)>{};
  var _bytes = 0;
  var _seq = 0;
  Timer? _timer;
  var _warned = false;

  void add(
    String channel,
    SerializableModel message,
    String? coalesceKey, {
    bool immediate = false,
  }) {
    final data = pod.serializationManager.encodeWithType(message);
    final Object key = coalesceKey == null ? _seq++ : '$channel\n$coalesceKey';
    // Re-adding moves a coalesced message to the end: it stays behind the
    // ops it may refer to.
    final old = _queue.remove(key);
    if (old != null) _bytes -= old.$2.length;
    _queue[key] = (channel, data);
    _bytes += data.length;
    if (immediate || _bytes >= ClusterBus.maxBatchBytes) {
      unawaited(flush());
    } else {
      _timer ??= Timer(ClusterBus.flushInterval, () => unawaited(flush()));
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final entries = _queue.values.toList();
    _queue.clear();
    _bytes = 0;
    final batch = ClusterBusBatch(
      originInstance: Cluster.instanceId,
      channels: [for (final e in entries) e.$1],
      messages: [for (final e in entries) e.$2],
    );
    try {
      final publish = ClusterBus.debugPublish;
      if (publish != null) {
        await publish(batch);
      } else {
        await pod.server.messageCentral.postMessage(
          ClusterBus.channel,
          batch,
          scope: MessageScope.global,
        );
      }
      _warned = false;
    } catch (e) {
      // Best effort, like Redis pub/sub itself; warn once per outage.
      if (!_warned) {
        _warned = true;
        stderr.writeln('WARNING: Relaying bus messages to Redis failed: $e');
      }
    }
  }
}
