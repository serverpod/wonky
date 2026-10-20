import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../analytics/usage_tracker.dart';
import '../common/actor.dart';
import '../common/json.dart';
import '../common/models.dart';
import '../common/roles.dart';
import '../common/time.dart';
import '../sharing/access_service.dart';
import '../users/user_service.dart';

/// The activity log of drive items (specs/05 §5).
abstract final class ActivityService {
  /// Window in which consecutive edits by one user are merged into one event.
  static const editWindow = Duration(minutes: 10);

  static Future<void> log(
    Session session,
    int itemId,
    Actor? actor,
    ActivityType type, {
    Map<String, Object?> summary = const {},
    Transaction? transaction,
  }) async {
    await ActivityEvent.db.insertRow(
      session,
      ActivityEvent(
        itemId: itemId,
        actorId: actor?.userId,
        actorKind: actor?.kind ?? ActorKind.system,
        type: type,
        summary: jsonEncode(summary),
        at: nowUtc(),
      ),
      transaction: transaction,
    );
    if (_contributions.contains(type)) {
      await UsageTracker.edited(
        session,
        actor,
        itemId,
        template: summary['template'],
      );
    }
  }

  /// Events that make their actor an editor of the day (specs/19 §2).
  static const _contributions = {
    ActivityType.created,
    ActivityType.uploaded,
    ActivityType.restoredVersion,
  };

  /// Records an edit, merged with the user's previous edit event on the item
  /// when it is less than [editWindow] old. Numeric [counters] are summed;
  /// [sets] (ids, e.g. the slides a deck edit touched) are merged as sorted
  /// lists of at most [maxSetSize]; actor kinds are collected in
  /// `actorKinds`. The event is read and merged under its row lock, so
  /// concurrent recorders (instances, hooks) don't lose each other's counts.
  static Future<void> logEdit(
    Session session,
    int itemId,
    Actor actor, {
    Map<String, num> counters = const {},
    Map<String, Iterable<String>> sets = const {},
    Transaction? transaction,
  }) async {
    if (transaction == null) {
      return session.db.transaction(
        (tx) => logEdit(
          session,
          itemId,
          actor,
          counters: counters,
          sets: sets,
          transaction: tx,
        ),
      );
    }
    final now = nowUtc();
    final recent = await ActivityEvent.db.findFirstRow(
      session,
      where: (t) =>
          t.itemId.equals(itemId) &
          t.actorId.equals(actor.userId) &
          t.type.equals(ActivityType.edited) &
          (t.at > now.subtract(editWindow)),
      orderBy: (t) => t.at.desc(),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (recent == null) {
      await ActivityEvent.db.insertRow(
        session,
        ActivityEvent(
          itemId: itemId,
          actorId: actor.userId,
          actorKind: actor.kind,
          type: ActivityType.edited,
          summary: jsonEncode({
            ...counters,
            for (final e in sets.entries) e.key: _set(const [], e.value),
            'actorKinds': [actor.kind.name],
          }),
          at: now,
        ),
        transaction: transaction,
      );
      await UsageTracker.edited(session, actor, itemId);
      return;
    }
    final summary = decodeObject(recent.summary);
    counters.forEach((key, value) {
      final prev = summary[key];
      summary[key] = (prev is num ? prev : 0) + value;
    });
    sets.forEach((key, value) {
      final prev = summary[key];
      summary[key] = _set(prev is List ? prev : const [], value);
    });
    final kinds = {
      ...((summary['actorKinds'] as List<Object?>?) ?? const []).map(
        (k) => '$k',
      ),
      actor.kind.name,
    };
    summary['actorKinds'] = kinds.toList()..sort();
    await ActivityEvent.db.updateRow(
      session,
      recent.copyWith(summary: jsonEncode(summary)),
      columns: (t) => [t.summary],
      transaction: transaction,
    );
    await UsageTracker.edited(session, actor, itemId);
  }

  /// Max ids kept per set of an edit event ([logEdit]).
  static const maxSetSize = 200;

  static List<String> _set(List<Object?> prev, Iterable<String> add) {
    final all = {for (final p in prev) '$p', ...add}.toList()..sort();
    return all.length > maxSetSize ? all.sublist(0, maxSetSize) : all;
  }

  static Future<List<ActivityEventView>> list(
    Session session,
    int itemId, {
    int? beforeId,
    int limit = 50,
  }) async {
    final events = await ActivityEvent.db.find(
      session,
      where: (t) =>
          t.itemId.equals(itemId) &
          (beforeId == null ? Constant.bool(true) : t.id < beforeId),
      orderBy: (t) => t.id.desc(),
      limit: limit.clamp(1, 200),
    );
    final users = await UserService.summaries(session, [
      for (final e in events) e.actorId,
    ]);
    return [
      for (final e in events)
        ActivityEventView(
          id: e.id!,
          type: e.type,
          actor: e.actorId == null ? null : users[e.actorId],
          actorKind: e.actorKind,
          summary: e.summary,
          at: e.at,
        ),
    ];
  }

  // ------------------------------------------------------ views (07 §6)

  /// The UTC midnight of [at].
  static DateTime dayOf(DateTime at) {
    final u = at.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  /// Records that [userId] opened [itemId] (one row per user and UTC day).
  static Future<void> recordView(
    Session session,
    int itemId,
    int userId, {
    DateTime? at,
  }) async {
    final now = at ?? nowUtc();
    await session.db.unsafeExecute(
      'INSERT INTO item_view_day ("itemId", "userId", "day", "views", '
      '"lastViewedAt") VALUES (@item, @user, @day, 1, @now) '
      'ON CONFLICT ("itemId", "userId", "day") DO UPDATE SET '
      '"views" = item_view_day."views" + 1, "lastViewedAt" = @now',
      parameters: QueryParameters.named({
        'item': itemId,
        'user': userId,
        'day': dayOf(now),
        'now': now,
      }),
    );
  }

  /// The "Show my view history" setting of [userId] (default on).
  static Future<bool> showViewHistory(Session session, int userId) async {
    final row = await UserActivitySettings.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    return row?.showViewHistory ?? true;
  }

  static Future<bool> setShowViewHistory(
    Session session,
    int userId,
    bool show,
  ) async {
    final row = await UserActivitySettings.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (row == null) {
      await UserActivitySettings.db.insertRow(
        session,
        UserActivitySettings(
          userId: userId,
          showViewHistory: show,
          updatedAt: nowUtc(),
        ),
      );
    } else {
      await UserActivitySettings.db.updateRow(
        session,
        row.copyWith(showViewHistory: show, updatedAt: nowUtc()),
      );
    }
    return show;
  }

  /// The activity dashboard of [uuid] for the last [days] days (07 §6).
  /// Any role may see the trends; viewers are listed for Editors+ only, and
  /// only people in the item's share set (owner and grantees, not link
  /// visitors) who did not turn "Show my view history" off.
  static Future<ActivityDashboard> dashboard(
    Session session,
    Actor actor,
    UuidValue uuid, {
    int days = 28,
  }) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final period = days.clamp(1, 365);
    final today = dayOf(nowUtc());
    final from = today.subtract(Duration(days: period - 1));
    final rows = await ItemViewDay.db.find(
      session,
      where: (t) => t.itemId.equals(item.id!) & (t.day >= from),
    );

    final viewsByDay = <DateTime, Set<int>>{};
    for (final r in rows) {
      viewsByDay.putIfAbsent(r.day.toUtc(), () => {}).add(r.userId);
    }
    final commentsByDay = await _commentsPerDay(session, item.id!, from);
    List<ActivityTrendPoint> trend(int Function(DateTime day) count) => [
      for (var i = 0; i < period; i++)
        ActivityTrendPoint(
          day: from.add(Duration(days: i)),
          count: count(from.add(Duration(days: i))),
        ),
    ];

    final canSeeViewers = role >= Role.editor;
    var viewers = <ActivityViewer>[];
    var hidden = 0;
    if (canSeeViewers) {
      final shareSet = await AccessService.grantedUsers(session, item);
      final perUser = <int, (DateTime, int)>{};
      for (final r in rows) {
        if (!shareSet.contains(r.userId)) continue;
        final prev = perUser[r.userId];
        final last = prev == null || r.lastViewedAt.isAfter(prev.$1)
            ? r.lastViewedAt
            : prev.$1;
        perUser[r.userId] = (last, (prev?.$2 ?? 0) + r.views);
      }
      final optedOut = perUser.isEmpty
          ? <int>{}
          : {
              for (final s in await UserActivitySettings.db.find(
                session,
                where: (t) =>
                    t.userId.inSet(perUser.keys.toSet()) &
                    t.showViewHistory.equals(false),
              ))
                s.userId,
            };
      hidden = optedOut.length;
      final visible = [
        for (final id in perUser.keys)
          if (!optedOut.contains(id)) id,
      ];
      final summaries = await UserService.summaries(session, visible);
      final roles = <int, Role?>{
        for (final id in visible)
          id: await AccessService.effectiveRole(session, id, item),
      };
      viewers = [
        for (final id in visible)
          if (summaries[id] != null)
            ActivityViewer(
              user: summaries[id]!,
              role: roles[id]?.access,
              lastViewedAt: perUser[id]!.$1,
              views: perUser[id]!.$2,
            ),
      ]..sort((a, b) => b.lastViewedAt.compareTo(a.lastViewedAt));
    }

    return ActivityDashboard(
      days: period,
      canSeeViewers: canSeeViewers,
      viewers: viewers,
      hiddenViewers: hidden,
      viewTrend: trend((d) => viewsByDay[d]?.length ?? 0),
      commentTrend: trend((d) => commentsByDay[d] ?? 0),
      showMyViewHistory: await showViewHistory(session, actor.userId),
    );
  }

  /// Comments and replies (not system events) per UTC day since [from].
  static Future<Map<DateTime, int>> _commentsPerDay(
    Session session,
    int itemId,
    DateTime from,
  ) async {
    final result = await session.db.unsafeQuery(
      'SELECT date_trunc(\'day\', c."createdAt") AS d, '
      'count(*) FROM comment c JOIN comment_thread t ON t.id = c."threadId" '
      'WHERE t."itemId" = @item AND c."authorId" IS NOT NULL '
      'AND c."createdAt" >= @from GROUP BY d',
      parameters: QueryParameters.named({'item': itemId, 'from': from}),
    );
    return {
      for (final row in result)
        dayOf(_asUtc(row[0] as DateTime)): (row[1] as int),
    };
  }

  /// Postgres returns `timestamp without time zone` as a local-looking
  /// DateTime; reinterpret its fields as UTC.
  static DateTime _asUtc(DateTime d) => d.isUtc
      ? d
      : DateTime.utc(d.year, d.month, d.day, d.hour, d.minute, d.second);
}
