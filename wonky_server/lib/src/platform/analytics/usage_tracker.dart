import 'package:serverpod/serverpod.dart';

import '../activity/activity_service.dart';
import '../common/actor.dart';
import '../common/lru_map.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../drive/templates/builtin_templates.dart';

/// Records who was active where, for the usage analytics (specs/19 §2):
/// one `user_activity_day` row per user, UTC day and app, and daily
/// counters (`usage_counter_day`). Ids and counts only, never content.
///
/// Sources: the apps' ping at start and on resume (`analytics.ping`),
/// opening an item (`DriveUserStates.recordOpen`), creating and editing
/// (`ActivityService`), and MCP tool calls (`McpToolExecutor`). Each
/// instance writes a (user, day, app) key at most once (twice when an edit
/// follows an open), so the hot paths cost a map lookup. Tracking never
/// fails the request that triggers it.
abstract final class UsageTracker {
  /// Daily counter of MCP tool calls by people's tokens.
  static const mcpCalls = 'mcp.calls';

  /// (user, day, app) → whether an edit was recorded.
  static final _seen = LruMap<(int, int, UsageApp), bool>(50000);

  /// Item id → kind (kinds never change).
  static final _kinds = LruMap<int, DriveItemKind>(20000);

  /// User id → when `lastSeenAt` was last written by this instance.
  static final _lastSeen = LruMap<int, DateTime>(20000);

  /// How often `user_profile.lastSeenAt` is refreshed per user.
  static const lastSeenInterval = Duration(minutes: 15);

  /// The app that edits items of [kind]; folders and files are Drive's.
  static UsageApp appOf(DriveItemKind kind) => switch (kind) {
    DriveItemKind.document => UsageApp.write,
    DriveItemKind.spreadsheet => UsageApp.sheets,
    DriveItemKind.presentation => UsageApp.slides,
    DriveItemKind.folder || DriveItemKind.file => UsageApp.drive,
  };

  /// Records that [userId] was active in [app] (and, with [edited],
  /// created or edited something there).
  static Future<void> active(
    Session session,
    int userId,
    UsageApp app, {
    bool edited = false,
  }) async {
    final now = nowUtc();
    final day = ActivityService.dayOf(now);
    final key = (userId, day.millisecondsSinceEpoch, app);
    final prev = _seen.get(key);
    final write = prev == null || (edited && !prev);
    // Edits may run inside a transaction that locks the profile row; the
    // pings, opens and MCP calls keep `lastSeenAt` fresh.
    final seen = !edited && _touchLastSeen(userId, now);
    if (!write && !seen) return;
    try {
      if (write) {
        await session.db.unsafeExecute(
          'INSERT INTO user_activity_day ("userId", "day", "app", "edited") '
          'VALUES (@user, @day, @app, @edited) '
          'ON CONFLICT ("userId", "day", "app") DO UPDATE SET '
          '"edited" = user_activity_day."edited" OR EXCLUDED."edited"',
          parameters: QueryParameters.named({
            'user': userId,
            'day': day,
            'app': app.name,
            'edited': edited,
          }),
        );
        _seen.put(key, edited || (prev ?? false));
      }
      if (seen) {
        await session.db.unsafeExecute(
          'UPDATE user_profile SET "lastSeenAt" = @now WHERE id = @user',
          parameters: QueryParameters.named({'user': userId, 'now': now}),
        );
      }
    } on Exception catch (e) {
      session.log('Usage tracking failed: $e', level: LogLevel.warning);
    }
  }

  /// Whether `lastSeenAt` of [userId] is due a write (and marks it).
  static bool _touchLastSeen(int userId, DateTime now) {
    final last = _lastSeen.get(userId);
    if (last != null && now.difference(last) < lastSeenInterval) return false;
    _lastSeen.put(userId, now);
    return true;
  }

  /// [actor] opened [item] (a document stream, a deck, a file preview).
  static Future<void> opened(Session session, Actor actor, DriveItem item) {
    _kinds.put(item.id!, item.kind);
    final app = _appOfActor(actor, item.kind);
    if (app == null) return Future.value();
    return active(session, actor.userId, app);
  }

  /// The built-in templates of the welcome content every account gets
  /// (not counted as created by the user).
  static const welcomeTemplates = {
    BuiltinTemplates.welcomeDocumentKey,
    BuiltinTemplates.welcomeSpreadsheetKey,
  };

  /// [actor] created or edited the item [itemId] ([template]: the template
  /// it was created from). Scripts and the system are not people at work
  /// and are left out, as is the welcome content; the assistant's edits
  /// count for the person who asked.
  static Future<void> edited(
    Session session,
    Actor? actor,
    int itemId, {
    Object? template,
  }) async {
    if (actor == null || welcomeTemplates.contains(template)) return;
    if (actor.kind == ActorKind.script || actor.kind == ActorKind.system) {
      return;
    }
    var kind = _kinds.get(itemId);
    if (kind == null) {
      try {
        kind = (await DriveItem.db.findById(session, itemId))?.kind;
      } on Exception catch (e) {
        session.log('Usage tracking failed: $e', level: LogLevel.warning);
      }
      if (kind == null) return;
      _kinds.put(itemId, kind);
    }
    final app = _appOfActor(actor, kind);
    if (app == null) return;
    await active(session, actor.userId, app, edited: true);
  }

  /// A tool call by an MCP client with [userId]'s token.
  static Future<void> mcpCall(Session session, int userId) async {
    await active(session, userId, UsageApp.mcp);
    await increment(session, mcpCalls);
  }

  /// Adds [by] to today's counter [name].
  static Future<void> increment(
    Session session,
    String name, [
    int by = 1,
  ]) async {
    try {
      await session.db.unsafeExecute(
        'INSERT INTO usage_counter_day ("day", "name", "value") '
        'VALUES (@day, @name, @by) '
        'ON CONFLICT ("day", "name") DO UPDATE SET '
        '"value" = usage_counter_day."value" + EXCLUDED."value"',
        parameters: QueryParameters.named({
          'day': ActivityService.dayOf(nowUtc()),
          'name': name,
          'by': by,
        }),
      );
    } on Exception catch (e) {
      session.log('Usage tracking failed: $e', level: LogLevel.warning);
    }
  }

  static UsageApp? _appOfActor(Actor actor, DriveItemKind kind) =>
      switch (actor.kind) {
        ActorKind.user || ActorKind.ai => appOf(kind),
        ActorKind.mcp => UsageApp.mcp,
        ActorKind.script || ActorKind.system => null,
      };

  /// Keeps activity rows for 400 days (a year-over-year view of the last
  /// 30 days) and counters as long; returns the deleted count.
  static Future<int> purge(Session session, {DateTime? now}) async {
    final cutoff = ActivityService.dayOf(
      now ?? nowUtc(),
    ).subtract(const Duration(days: retentionDays));
    final days = await UserActivityDay.db.deleteWhere(
      session,
      where: (t) => t.day < cutoff,
    );
    final counters = await UsageCounterDay.db.deleteWhere(
      session,
      where: (t) => t.day < cutoff,
    );
    return days.length + counters.length;
  }

  /// How long activity is kept.
  static const retentionDays = 400;

  /// Forgets what this instance wrote (for tests that move the clock).
  static void reset() {
    _seen.clear();
    _kinds.clear();
    _lastSeen.clear();
  }
}
