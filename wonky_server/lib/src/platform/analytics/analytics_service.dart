import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';

import '../activity/activity_service.dart';
import '../ai/ai_usage_service.dart';
import '../board/board_admins.dart';
import '../board/board_config.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../users/user_service.dart';
import 'usage_tracker.dart';

/// The usage analytics of Wonky Drive's admin dashboard (specs/19 §3):
/// accounts, active users, content, collaboration, AI and MCP use, sign-up
/// cohorts. Admins only (the board's admin rule,
/// specs/16 §9.1); aggregates are computed in SQL and cached briefly.
abstract final class AnalyticsService {
  /// Periods the dashboard offers.
  static const periods = {7, 30, 90, 365};

  /// Weekly sign-up cohorts shown (the current week included).
  static const cohortWeeks = 12;

  /// How long an overview is reused.
  static const cacheLifetime = Duration(minutes: 1);

  /// Throws `forbidden` unless the caller is an admin.
  static Future<void> requireAdmin(Session session) async {
    final actor = await UserService.actorOf(session);
    if (!await BoardAdmins.isAdminUser(session, actor.userId)) {
      throw Errors.forbidden('Usage analytics are for admins.');
    }
  }

  /// SQL that is true for the profile [alias] unless admins are left out
  /// and it is an admin; a missing profile (deleted account) counts.
  static String _keep(String alias) =>
      '(@all OR NOT COALESCE($alias.email = ANY(@ae) OR '
      "split_part($alias.email, '@', 2) = ANY(@ad), false))";

  /// The entries of [all] that [sql] uses (`@name`): the driver rejects
  /// unused parameters.
  static QueryParameters _params(String sql, Map<String, Object?> all) =>
      QueryParameters.named({
        for (final e in all.entries)
          if (RegExp('@${e.key}\\b').hasMatch(sql)) e.key: e.value,
      });

  static Map<String, Object?> _adminParams(bool includeAdmins) {
    final c = BoardConfig.current;
    return {
      'all': includeAdmins,
      'ae': [for (final e in c.adminEmails) e.toLowerCase()],
      'ad': [for (final d in c.adminEmailDomains) d.toLowerCase()],
    };
  }

  /// The dashboard for the last [days] days (one of [periods]), ending
  /// today (UTC).
  static Future<AnalyticsOverview> overview(
    Session session, {
    required int days,
    required bool includeAdmins,
  }) async {
    if (!periods.contains(days)) {
      throw Errors.invalid('The period must be one of $periods days.');
    }
    final key = 'analytics.overview.$days.$includeAdmins';
    final cached = await session.caches.local.get<AnalyticsOverview>(key);
    if (cached != null) return cached;
    final result = await _compute(session, days, includeAdmins);
    await session.caches.local.put(key, result, lifetime: cacheLifetime);
    return result;
  }

  /// Drops the cached overviews (tests, and after a config change).
  static Future<void> clearCache(Session session) async {
    for (final days in periods) {
      for (final admins in const [false, true]) {
        await session.caches.local.invalidateKey(
          'analytics.overview.$days.$admins',
        );
      }
    }
  }

  static Future<AnalyticsOverview> _compute(
    Session session,
    int days,
    bool includeAdmins,
  ) async {
    final now = nowUtc();
    final today = ActivityService.dayOf(now);
    final from = today.subtract(Duration(days: days - 1));
    final to = today.add(const Duration(days: 1));
    // Stickiness needs the last 30 days even for a shorter period.
    final activityFrom = from.isBefore(today.subtract(const Duration(days: 29)))
        ? from
        : today.subtract(const Duration(days: 29));
    final p = {
      ..._adminParams(includeAdmins),
      'from': from,
      'to': to,
      'welcome': UsageTracker.welcomeTemplates.toList(),
    };
    final dayKeys = [
      for (var i = 0; i < days; i++) from.add(Duration(days: i)),
    ];

    Future<List<List<Object?>>> q(String sql) async =>
        (await session.db.unsafeQuery(
          sql,
          parameters: _params(sql, p),
        )).map((r) => r.toList()).toList();

    // Active users per day and app, and the rolling 7/30-day counts:
    // finished days from the rollup, today live.
    final activity = await _activity(
      session,
      activityFrom,
      today,
      includeAdmins,
    );

    // Accounts.
    final signups = await _perDay(
      q,
      'SELECT date_trunc(\'day\', p."createdAt"), count(*) FROM user_profile p '
      'WHERE p."createdAt" >= @from AND ${_keep('p')} GROUP BY 1',
    );
    final before = _int(
      (await q(
        'SELECT count(*) FROM user_profile p '
        'WHERE p."createdAt" < @from AND ${_keep('p')}',
      )).first[0],
    );

    // Items created per day and kind (from the activity log: creations and
    // uploads by people, the assistant and MCP; not the welcome content).
    final created = <DateTime, Map<String, int>>{};
    for (final r in await q(
      'SELECT date_trunc(\'day\', e.at), i.kind, count(*) '
      'FROM activity_event e JOIN drive_item i ON i.id = e."itemId" '
      'LEFT JOIN user_profile p ON p.id = e."actorId" '
      "WHERE e.type IN ('created', 'uploaded') "
      "AND e.\"actorKind\" IN ('user', 'ai', 'mcp') "
      'AND e.at >= @from AND i."templateOf" IS NULL '
      "AND COALESCE(e.summary::jsonb ->> 'template', '') <> ALL(@welcome) "
      'AND ${_keep('p')} GROUP BY 1, 2',
    )) {
      created.putIfAbsent(_day(r[0]), () => {})['${r[1]}'] = _int(r[2]);
    }

    final comments = await _perDay(
      q,
      'SELECT date_trunc(\'day\', c."createdAt"), count(*) FROM comment c '
      'LEFT JOIN user_profile p ON p.id = c."authorId" '
      'WHERE c."authorId" IS NOT NULL AND c."systemEvent" IS NULL '
      "AND c.\"authorKind\" = 'user' AND c.\"createdAt\" >= @from "
      'AND ${_keep('p')} GROUP BY 1',
    );
    final shares = await _perDay(
      q,
      'SELECT date_trunc(\'day\', g."grantedAt"), count(*) '
      'FROM drive_item_permission g '
      'LEFT JOIN user_profile p ON p.id = g."grantedById" '
      'WHERE g."inheritedFromId" IS NULL AND g."viaPublicationId" IS NULL '
      "AND g.role <> 'owner' AND g.\"grantedAt\" >= @from "
      'AND (g."userId" IS NULL OR g."userId" <> g."grantedById") '
      'AND ${_keep('p')} GROUP BY 1',
    );
    final ai = <DateTime, (int, int)>{};
    for (final r in await q(
      'SELECT date_trunc(\'day\', u.at), count(*), '
      'COALESCE(sum(u."inputTokens" + u."outputTokens"), 0)::bigint '
      'FROM ai_usage u LEFT JOIN user_profile p ON p.id = u."userId" '
      'WHERE u.at >= @from AND ${_keep('p')} GROUP BY 1',
    )) {
      ai[_day(r[0])] = (_int(r[1]), _int(r[2]));
    }
    final mcpCalls = await _perDay(
      q,
      'SELECT c.day, c.value FROM usage_counter_day c '
      "WHERE c.day >= @from AND c.name = '${UsageTracker.mcpCalls}'",
    );

    var accounts = before;
    final series = <AnalyticsDay>[];
    for (final d in dayKeys) {
      final a = activity[d] ?? _noActivity;
      final c = created[d] ?? const {};
      accounts += signups[d] ?? 0;
      series.add(
        AnalyticsDay(
          day: d,
          active: a[0],
          editors: a[1],
          drive: a[2],
          write: a[3],
          sheets: a[4],
          slides: a[5],
          mcp: a[6],
          weekly: a[7],
          monthly: a[8],
          signups: signups[d] ?? 0,
          accounts: accounts,
          documents: c['document'] ?? 0,
          spreadsheets: c['spreadsheet'] ?? 0,
          presentations: c['presentation'] ?? 0,
          files: c['file'] ?? 0,
          folders: c['folder'] ?? 0,
          comments: comments[d] ?? 0,
          shares: shares[d] ?? 0,
          aiRequests: ai[d]?.$1 ?? 0,
          aiTokens: ai[d]?.$2 ?? 0,
          mcpCalls: mcpCalls[d] ?? 0,
        ),
      );
    }

    final last30 = [
      for (var i = 0; i < 30; i++)
        activity[today.subtract(Duration(days: i))]?[0] ?? 0,
    ];
    final monthly = series.last.monthly;
    final stickiness = monthly == 0
        ? 0.0
        : math.min(1.0, last30.reduce((a, b) => a + b) / 30 / monthly);

    final trackingRow = await q('SELECT min(day) FROM user_activity_day');
    final trackingSince = trackingRow.first[0] == null
        ? null
        : _day(trackingRow.first[0]);

    return AnalyticsOverview(
      days: days,
      includeAdmins: includeAdmins,
      generatedAt: now,
      trackingSince: trackingSince,
      accounts: accounts,
      newAccounts: accounts - before,
      activeToday: series.last.active,
      weekly: series.last.weekly,
      monthly: monthly,
      stickiness: stickiness,
      series: series,
      itemTotals: await _counts(
        q,
        'SELECT i.kind, count(*), '
        'COALESCE(sum(i."sizeBytes" + i."attachmentBytes"), 0)::bigint '
        'FROM drive_item i LEFT JOIN user_profile p ON p.id = i."ownerId" '
        'WHERE i."trashedAt" IS NULL AND i."templateOf" IS NULL '
        'AND ${_keep('p')} GROUP BY 1 ORDER BY 2 DESC',
      ),
      storageBytes: _int(
        (await q(
          'SELECT COALESCE(sum(s."usedBytes"), 0)::bigint FROM user_storage s '
          'LEFT JOIN user_profile p ON p.id = s."userId" WHERE ${_keep('p')}',
        )).first[0],
      ),
      signInMethods: await _counts(
        q,
        "SELECT 'email', count(DISTINCT p.id), 0 FROM user_profile p "
        'JOIN serverpod_auth_idp_email_account e '
        'ON e."authUserId" = p."authUserId" WHERE ${_keep('p')} '
        "UNION ALL SELECT 'google', count(DISTINCT p.id), 0 FROM user_profile p "
        'JOIN serverpod_auth_idp_google_account g '
        'ON g."authUserId" = p."authUserId" WHERE ${_keep('p')}',
      ),
      aiFeatures: await _counts(q, _aiBy('feature')),
      aiModels: await _counts(q, _aiBy('model')),
      aiRetentionDays: AiUsageService.retentionDays,
      sharedItems: _int(
        (await q(
          'SELECT count(DISTINCT g."itemId") FROM drive_item_permission g '
          'JOIN drive_item i ON i.id = g."itemId" '
          'LEFT JOIN user_profile p ON p.id = i."ownerId" '
          'WHERE g."inheritedFromId" IS NULL AND g."viaPublicationId" IS NULL '
          "AND g.role <> 'owner' AND i.\"trashedAt\" IS NULL "
          'AND (g."userId" IS NULL OR g."userId" <> i."ownerId") '
          'AND ${_keep('p')}',
        )).first[0],
      ),
      coEditedItems: _int(
        (await q(
          'SELECT count(*) FROM (SELECT e."itemId" FROM activity_event e '
          'LEFT JOIN user_profile p ON p.id = e."actorId" '
          "WHERE e.type = 'edited' AND e.\"actorId\" IS NOT NULL "
          "AND e.\"actorKind\" IN ('user', 'ai', 'mcp') AND e.at >= @from "
          'AND ${_keep('p')} GROUP BY e."itemId" '
          'HAVING count(DISTINCT e."actorId") >= 2) x',
        )).first[0],
      ),
      commenters: _int(
        (await q(
          'SELECT count(DISTINCT c."authorId") FROM comment c '
          'LEFT JOIN user_profile p ON p.id = c."authorId" '
          'WHERE c."authorId" IS NOT NULL AND c."systemEvent" IS NULL '
          "AND c.\"authorKind\" = 'user' AND c.\"createdAt\" >= @from "
          'AND ${_keep('p')}',
        )).first[0],
      ),
      cohorts: await _cohorts(session, today, trackingSince, includeAdmins),
    );
  }

  static String _aiBy(String column) =>
      'SELECT u."$column", count(*), '
      'COALESCE(sum(u."inputTokens" + u."outputTokens"), 0)::bigint '
      'FROM ai_usage u LEFT JOIN user_profile p ON p.id = u."userId" '
      'WHERE u.at >= @from AND ${_keep('p')} GROUP BY 1 ORDER BY 2 DESC '
      'LIMIT 12';

  /// Weekly sign-up cohorts of the last [cohortWeeks] weeks (Monday, UTC):
  /// size and active users per week since sign-up.
  static Future<List<AnalyticsCohort>> _cohorts(
    Session session,
    DateTime today,
    DateTime? trackingSince,
    bool includeAdmins,
  ) async {
    final thisWeek = weekOf(today);
    final first = thisWeek.subtract(
      const Duration(days: 7 * (cohortWeeks - 1)),
    );
    final params = {..._adminParams(includeAdmins), 'first': first};
    Future<DatabaseResult> q(String sql) =>
        session.db.unsafeQuery(sql, parameters: _params(sql, params));
    final sizes = <DateTime, int>{};
    for (final r in await q(
      'SELECT date_trunc(\'week\', p."createdAt"), count(*) FROM user_profile p '
      'WHERE p."createdAt" >= @first AND ${_keep('p')} GROUP BY 1',
    )) {
      sizes[_day(r[0])] = _int(r[1]);
    }
    final active = <(DateTime, int), int>{};
    for (final r in await q(
      'WITH c AS (SELECT p.id, date_trunc(\'week\', p."createdAt") AS w '
      'FROM user_profile p WHERE p."createdAt" >= @first AND ${_keep('p')}) '
      "SELECT c.w, floor(extract(epoch FROM date_trunc('week', a.day) - c.w) "
      '/ 604800)::int, count(DISTINCT a."userId") FROM c '
      'JOIN user_activity_day a ON a."userId" = c.id AND a.day >= c.w '
      'GROUP BY 1, 2',
    )) {
      active[(_day(r[0]), _int(r[1]))] = _int(r[2]);
    }
    final tracked = trackingSince == null ? null : weekOf(trackingSince);
    return [
      for (var i = 0; i < cohortWeeks; i++)
        if (first.add(Duration(days: 7 * i)) case final week)
          AnalyticsCohort(
            week: week,
            size: sizes[week] ?? 0,
            active: [
              for (var k = 0; k < cohortWeeks - i; k++)
                if (week.add(Duration(days: 7 * k)) case final w)
                  tracked == null || w.isBefore(tracked)
                      ? null
                      : active[(week, k)] ?? 0,
            ],
          ),
    ];
  }

  /// Activity of no one: [_activity]'s columns.
  static const _noActivity = [0, 0, 0, 0, 0, 0, 0, 0, 0];

  /// Activity per day from [from] to [today]: active, editors, drive,
  /// write, sheets, slides, mcp, weekly (7 days ending that day) and
  /// monthly (30 days). Finished days come from `usage_day_stats` and are
  /// computed and stored once when missing (a finished day never changes:
  /// activity is only written for the current UTC day); today is live.
  static Future<Map<DateTime, List<int>>> _activity(
    Session session,
    DateTime from,
    DateTime today,
    bool includeAdmins,
  ) async {
    final out = <DateTime, List<int>>{};
    final stored = await UsageDayStats.db.find(
      session,
      where: (t) =>
          (t.day >= from) &
          (t.day < today) &
          t.includeAdmins.equals(includeAdmins),
    );
    for (final r in stored) {
      out[_day(r.day)] = [
        r.active,
        r.editors,
        r.drive,
        r.write,
        r.sheets,
        r.slides,
        r.mcp,
        r.weekly,
        r.monthly,
      ];
    }
    DateTime? firstMissing;
    for (var d = from; d.isBefore(today); d = d.add(const Duration(days: 1))) {
      if (!out.containsKey(d)) {
        firstMissing = d;
        break;
      }
    }
    final computeFrom = firstMissing ?? today;
    final computed = await _computeActivity(
      session,
      computeFrom,
      today,
      includeAdmins,
    );
    final now = nowUtc();
    for (
      var d = computeFrom;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))
    ) {
      final a = computed[d] ?? _noActivity;
      if (d.isBefore(today) && !out.containsKey(d)) {
        await session.db.unsafeExecute(
          'INSERT INTO usage_day_stats ("day", "includeAdmins", "active", '
          '"editors", "drive", "write", "sheets", "slides", "mcp", "weekly", '
          '"monthly", "computedAt") VALUES (@day, @all, @a0, @a1, @a2, @a3, '
          '@a4, @a5, @a6, @a7, @a8, @now) '
          'ON CONFLICT ("day", "includeAdmins") DO NOTHING',
          parameters: QueryParameters.named({
            'day': d,
            'all': includeAdmins,
            for (var i = 0; i < a.length; i++) 'a$i': a[i],
            'now': now,
          }),
        );
      }
      out[d] = a;
    }
    return out;
  }

  /// [_activity]'s columns computed from `user_activity_day` for the days
  /// [from] … [today].
  static Future<Map<DateTime, List<int>>> _computeActivity(
    Session session,
    DateTime from,
    DateTime today,
    bool includeAdmins,
  ) async {
    final p = {
      ..._adminParams(includeAdmins),
      'from': from,
      'to': today.add(const Duration(days: 1)),
    };
    Future<DatabaseResult> q(String sql) =>
        session.db.unsafeQuery(sql, parameters: _params(sql, p));
    final out = <DateTime, List<int>>{};
    for (final r in await q(
      'SELECT a.day, count(DISTINCT a."userId"), '
      'count(DISTINCT a."userId") FILTER (WHERE a.edited), '
      "count(DISTINCT a.\"userId\") FILTER (WHERE a.app = 'drive'), "
      "count(DISTINCT a.\"userId\") FILTER (WHERE a.app = 'write'), "
      "count(DISTINCT a.\"userId\") FILTER (WHERE a.app = 'sheets'), "
      "count(DISTINCT a.\"userId\") FILTER (WHERE a.app = 'slides'), "
      "count(DISTINCT a.\"userId\") FILTER (WHERE a.app = 'mcp') "
      'FROM user_activity_day a LEFT JOIN user_profile p ON p.id = a."userId" '
      'WHERE a.day >= @from AND a.day < @to AND ${_keep('p')} '
      'GROUP BY a.day',
    )) {
      out[_day(r[0])] = [for (final v in r.skip(1)) _int(v), 0, 0];
    }
    // Distinct users in the 7 and 30 days ending with each day.
    for (final r in await q(
      'SELECT g.d, '
      "count(DISTINCT a.\"userId\") FILTER (WHERE a.day > g.d - interval '7 days'), "
      'count(DISTINCT a."userId") '
      "FROM generate_series(@from::timestamp, @to::timestamp - interval '1 day', "
      "interval '1 day') AS g(d) "
      "JOIN user_activity_day a ON a.day > g.d - interval '30 days' "
      'AND a.day <= g.d '
      'LEFT JOIN user_profile p ON p.id = a."userId" '
      'WHERE ${_keep('p')} GROUP BY g.d',
    )) {
      final row = out.putIfAbsent(_day(r[0]), () => [..._noActivity]);
      row[7] = _int(r[1]);
      row[8] = _int(r[2]);
    }
    return out;
  }

  /// The Monday (UTC midnight) of [day]'s week.
  static DateTime weekOf(DateTime day) {
    final d = ActivityService.dayOf(day);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  static Future<Map<DateTime, int>> _perDay(
    Future<List<List<Object?>>> Function(String sql) q,
    String sql,
  ) async => {for (final r in await q(sql)) _day(r[0]): _int(r[1])};

  static Future<List<AnalyticsCount>> _counts(
    Future<List<List<Object?>>> Function(String sql) q,
    String sql,
  ) async => [
    for (final r in await q(sql))
      AnalyticsCount(key: '${r[0]}', count: _int(r[1]), amount: _int(r[2])),
  ];

  static DateTime _day(Object? v) => ActivityService.dayOf(_utc(v as DateTime));

  /// Postgres returns `timestamp without time zone` as a local-looking
  /// DateTime; reinterpret its fields as UTC.
  static DateTime _utc(DateTime d) => d.isUtc
      ? d
      : DateTime.utc(
          d.year,
          d.month,
          d.day,
          d.hour,
          d.minute,
          d.second,
          d.millisecond,
        );

  static int _int(Object? v) => switch (v) {
    null => 0,
    final int i => i,
    final num n => n.toInt(),
    final BigInt b => b.toInt(),
    _ => int.parse('$v'),
  };
}
