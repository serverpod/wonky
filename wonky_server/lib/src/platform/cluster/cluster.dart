import 'package:serverpod/serverpod.dart';

import '../common/models.dart';

/// Coordination between the server instances of one deployment
/// (specs/13 §4). Several instances behind a load balancer share Postgres
/// and, when enabled, Redis: `session.messages` is then global, so every
/// bus channel (document ops, presence, drive/comment/notification
/// signals) already reaches all instances. This class adds what the
/// in-memory services need on top of that:
///
/// - [instanceId], to tell this instance's own messages apart;
/// - [signal]/[on]: fire-and-forget [ClusterSignal]s for unary calls that
///   must reach the instance holding some in-memory state (assistant
///   runs) and for cache invalidations;
/// - [withLock]: a cluster-wide mutex (Postgres advisory lock).
abstract final class Cluster {
  /// A random id of this server process.
  static final String instanceId = const Uuid().v4();

  /// The channel of [ClusterSignal]s.
  static const signalChannel = 'wonky:cluster';

  /// Overrides [distributed] (tests simulate a cluster on the local bus).
  static bool? debugDistributed;

  /// Whether other instances can exist: messages are global (Redis is
  /// enabled). Without Redis the deployment must run a single instance.
  static bool get distributed =>
      debugDistributed ?? Serverpod.instance.redisController != null;

  static final Map<String, void Function(ClusterSignal)> _handlers = {};
  static Serverpod? _listeningOn;
  static Future<void>? _listening;

  /// Handles signals of [kind] posted by other instances. Registering again
  /// replaces the handler. Completes once this instance listens.
  static Future<void> on(
    Session session,
    String kind,
    void Function(ClusterSignal signal) handler,
  ) {
    _handlers[kind] = handler;
    return _ensureListening(session.serverpod);
  }

  /// Posts [signal] to the other instances; a no-op on a single instance.
  /// Delivery is best effort (Redis pub/sub).
  static Future<void> signal(Session session, ClusterSignal signal) async {
    if (!distributed) return;
    await _ensureListening(session.serverpod);
    await session.messages.postMessage(signalChannel, signal);
  }

  /// Builds a signal of [kind] originating here.
  static ClusterSignal build(
    String kind, {
    int? userId,
    UuidValue? authUserId,
    String? runId,
    int? threadId,
    String? confirmationId,
    bool? allow,
  }) => ClusterSignal(
    kind: kind,
    originInstance: instanceId,
    userId: userId,
    authUserId: authUserId,
    runId: runId,
    threadId: threadId,
    confirmationId: confirmationId,
    allow: allow,
  );

  /// Listens on [signalChannel] with a session that stays open for the
  /// lifetime of the server (once per [Serverpod], tests start several).
  static Future<void> _ensureListening(Serverpod pod) {
    if (identical(_listeningOn, pod) && _listening != null) return _listening!;
    _listeningOn = pod;
    return _listening = () async {
      final session = await pod.createSession(enableLogging: false);
      session.messages.addListener(signalChannel, _onSignal);
    }();
  }

  static void _onSignal(SerializableModel message) {
    if (message is! ClusterSignal) return;
    if (message.originInstance == instanceId) return;
    _handlers[message.kind]?.call(message);
  }

  /// Runs [action] while holding the cluster-wide lock [name]: a Postgres
  /// transaction-level advisory lock held by an otherwise idle transaction,
  /// so [action] itself runs on other pool connections.
  /// Takes the cluster-wide lock [name] inside [transaction] (released
  /// with it): check-then-act decisions made after it are serialized.
  static Future<void> lockIn(
    Session session,
    String name,
    Transaction transaction,
  ) => session.db.unsafeQuery(
    'SELECT pg_advisory_xact_lock(hashtext(@name))',
    parameters: QueryParameters.named({'name': name}),
    transaction: transaction,
  );

  static Future<T> withLock<T>(
    Session session,
    String name,
    Future<T> Function() action,
  ) => session.db.transaction((tx) async {
    await session.db.unsafeQuery(
      'SELECT pg_advisory_xact_lock(hashtext(@name))',
      parameters: QueryParameters.named({'name': name}),
      transaction: tx,
    );
    return action();
  });
}
