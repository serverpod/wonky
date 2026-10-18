import 'dart:async';

import 'package:async/async.dart';
import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:wonky_server/src/platform/common/models.dart';

import 'streams.dart';
import 'test_users.dart';
import 'wonky_serverpod.dart';

/// A user's presence session on an item for tests (CQ-58): [join] returns
/// once the server registered it (its roster arrived), and [send] returns
/// once a second session ([watcher]) has seen the update, so no test waits
/// a fixed time for presence to settle.
final class TestPresence {
  TestPresence._(this.updates, this.events, this.sessionId);

  /// Joins [user] to [item] and waits for the roster.
  static Future<TestPresence> join(
    TestEndpoints endpoints,
    TestUser user,
    UuidValue item,
  ) async {
    final updates = StreamController<PresenceUpdate>();
    final events = StreamQueue(
      endpoints.presence.join(user.endpointSession, item, updates.stream),
    );
    final roster =
        await nextWhere(events, (e) => e is PresenceRoster) as PresenceRoster;
    return TestPresence._(updates, events, roster.sessionId);
  }

  final StreamController<PresenceUpdate> updates;
  final StreamQueue<PresenceEvent?> events;
  final String sessionId;

  /// Sends [update] and waits until [watcher] receives it, i.e. until the
  /// server processed it and fanned it out.
  Future<void> send(
    PresenceUpdate update, {
    required TestPresence watcher,
  }) async {
    updates.add(update);
    await nextWhere<PresenceEvent?>(
      watcher.events,
      (e) =>
          e is PresenceUpdated &&
          e.sessionId == sessionId &&
          e.cursorJson == update.cursorJson,
    );
  }

  Future<void> close() async {
    await updates.close();
    await events.cancel(immediate: true);
  }
}
