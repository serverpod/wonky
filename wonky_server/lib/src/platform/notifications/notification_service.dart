import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../common/actor.dart';
import '../config/wonky_config.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/json.dart';
import '../common/time.dart';
import '../users/user_service.dart';
import '../../generated/future_calls.dart';
import 'email/email_sender.dart';
import 'email/notification_emails.dart';
import '../cluster/cluster_bus.dart';

/// In-app notifications (specs/07 §4).
abstract final class NotificationService {
  static EmailSender? _emailSender;

  /// Delivers notification emails; [EmailSenders.fromServer] by default
  /// (logs in development). Tests install a fake.
  static EmailSender get emailSender =>
      _emailSender ??= EmailSenders.fromServer();
  static set emailSender(EmailSender? sender) => _emailSender = sender;

  /// Schedules the immediate email of a notification. By default a future
  /// call without delay ([NotificationEmailFutureCall]); tests replace it to
  /// run [sendImmediate] inline.
  static Future<void> Function(Session session, int notificationId)
  scheduleImmediateEmail = _scheduleViaFutureCall;

  static Future<void> _scheduleViaFutureCall(
    Session session,
    int notificationId,
  ) => session.serverpod.futureCalls
      .callWithDelay(Duration.zero)
      .notificationEmail
      .send(notificationId);

  /// The public web origin used for links in emails.
  static Uri webOrigin() {
    try {
      return WonkyConfig.current.webOrigin(Serverpod.instance.config);
    } on Object {
      return Uri.parse('http://localhost:8082');
    }
  }

  static NotificationEmails get _emails =>
      NotificationEmails(webOrigin: webOrigin());

  /// Kinds that are emailed right away instead of in the digest.
  static const immediateKinds = {
    NotificationKind.mention,
    NotificationKind.assigned,
  };

  static String channel(int userId) => 'notifications:$userId';

  /// The preference key (notificationSettings) of a [kind].
  static String settingKey(NotificationKind kind) => switch (kind) {
    NotificationKind.mention => 'mentions',
    NotificationKind.assigned => 'mentions',
    NotificationKind.reply => 'replies',
    NotificationKind.shared => 'shares',
    NotificationKind.ownershipTransfer => 'shares',
    NotificationKind.accessRequest => 'accessRequests',
    NotificationKind.suggestion => 'suggestions',
    NotificationKind.suggestionDecided => 'suggestions',
    NotificationKind.scriptFailure => 'scripts',
    NotificationKind.storage => 'storage',
    NotificationKind.boardReply => 'board',
    NotificationKind.boardStatus => 'board',
    NotificationKind.boardClaim => 'board',
  };

  /// Older settings stored access requests under `shares`.
  static const _fallbackKeys = {'accessRequests': 'shares'};

  /// The channel (`inApp`, `email` or `off`) for [kind] in the decoded
  /// notificationSettings [settings].
  static String channelOf(
    Map<String, Object?> settings,
    NotificationKind kind,
  ) {
    final key = settingKey(kind);
    final value = settings[key] ?? settings[_fallbackKeys[key]];
    return value == 'email' || value == 'off' ? value as String : 'inApp';
  }

  /// Whether non-mention emails are batched in the digest (`digest`,
  /// default true) or sent one by one.
  static bool digestOf(Map<String, Object?> settings) =>
      settings['digest'] != false;

  static Future<Map<String, Object?>> _settings(
    Session session,
    int userId,
  ) async {
    final prefs = await UserPreferences.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    return decodeObject(prefs?.notificationSettings);
  }

  /// Creates a notification for [userId] unless they turned this kind off.
  /// Notifications about one's own actions are never created.
  static Future<UserNotification?> notify(
    Session session, {
    required int userId,
    required NotificationKind kind,
    DriveItem? item,
    Actor? actor,
    Map<String, Object?> payload = const {},
  }) async {
    if (actor != null && actor.userId == userId) return null;
    final settings = await _settings(session, userId);
    final channelSetting = channelOf(settings, kind);
    if (channelSetting == 'off') return null;
    final row = await UserNotification.db.insertRow(
      session,
      UserNotification(
        userId: userId,
        kind: kind,
        itemId: item?.id,
        actorId: actor?.userId,
        payload: jsonEncode({
          ...payload,
          if (item != null) 'itemName': item.name,
          if (actor != null) 'actorKind': actor.kind.name,
        }),
        createdAt: nowUtc(),
        emailPending: channelSetting == 'email',
      ),
    );
    await ClusterBus.post(
      session,
      channel(userId),
      NotificationSignal(notificationId: row.id),
    );
    if (channelSetting == 'email' &&
        (immediateKinds.contains(kind) || !digestOf(settings))) {
      try {
        await scheduleImmediateEmail(session, row.id!);
      } on Object catch (e) {
        // The digest job picks it up.
        session.log(
          'Could not schedule the email of notification ${row.id}: $e',
          level: LogLevel.warning,
        );
      }
    }
    return row;
  }

  static Future<List<NotificationView>> _views(
    Session session,
    List<UserNotification> rows,
  ) async {
    final itemIds = {for (final r in rows) ?r.itemId};
    final items = itemIds.isEmpty
        ? <DriveItem>[]
        : await DriveItem.db.find(session, where: (t) => t.id.inSet(itemIds));
    final itemById = {for (final i in items) i.id!: i};
    final users = await UserService.summaries(session, [
      for (final r in rows) r.actorId,
    ]);
    return [
      for (final r in rows)
        NotificationView(
          id: r.id!,
          kind: r.kind,
          itemUuid: itemById[r.itemId]?.uuid,
          itemName: itemById[r.itemId]?.name,
          itemKind: itemById[r.itemId]?.kind,
          actor: r.actorId == null ? null : users[r.actorId],
          payload: r.payload,
          createdAt: r.createdAt,
          readAt: r.readAt,
        ),
    ];
  }

  static Future<int> unreadCount(Session session, int userId) =>
      UserNotification.db.count(
        session,
        where: (t) => t.userId.equals(userId) & t.readAt.equals(null),
      );

  static Future<NotificationPage> list(
    Session session,
    Actor actor, {
    String? cursor,
    int limit = 30,
    bool unreadOnly = false,
  }) async {
    final beforeId = int.tryParse(cursor ?? '');
    final rows = await UserNotification.db.find(
      session,
      where: (t) =>
          t.userId.equals(actor.userId) &
          (unreadOnly ? t.readAt.equals(null) : Constant.bool(true)) &
          (beforeId == null ? Constant.bool(true) : t.id < beforeId),
      orderBy: (t) => t.id.desc(),
      limit: limit.clamp(1, 100),
    );
    return NotificationPage(
      items: await _views(session, rows),
      nextCursor: rows.length == limit.clamp(1, 100) ? '${rows.last.id}' : null,
      unreadCount: await unreadCount(session, actor.userId),
    );
  }

  static Future<int> markRead(
    Session session,
    Actor actor,
    List<int> ids,
  ) async {
    if (ids.isNotEmpty) {
      await UserNotification.db.updateWhere(
        session,
        columnValues: (t) => [t.readAt(nowUtc())],
        where: (t) =>
            t.userId.equals(actor.userId) &
            t.id.inSet(ids.toSet()) &
            t.readAt.equals(null),
      );
    }
    await ClusterBus.post(
      session,
      channel(actor.userId),
      NotificationSignal(),
    );
    return unreadCount(session, actor.userId);
  }

  static Future<int> markAllRead(Session session, Actor actor) async {
    await UserNotification.db.updateWhere(
      session,
      columnValues: (t) => [t.readAt(nowUtc())],
      where: (t) => t.userId.equals(actor.userId) & t.readAt.equals(null),
    );
    await ClusterBus.post(
      session,
      channel(actor.userId),
      NotificationSignal(),
    );
    return 0;
  }

  static Stream<NotificationEvent> watch(Session session, Actor actor) async* {
    final signals = session.messages.createStream<NotificationSignal>(
      channel(actor.userId),
    );
    await for (final signal in signals) {
      NotificationView? view;
      if (signal.notificationId != null) {
        final row = await UserNotification.db.findById(
          session,
          signal.notificationId!,
        );
        if (row != null && row.userId == actor.userId) {
          view = (await _views(session, [row])).single;
        }
      }
      yield NotificationEvent(
        notification: view,
        unreadCount: await unreadCount(session, actor.userId),
      );
    }
  }

  /// Notifications are emailed within this window after their creation.
  static const emailWindow = Duration(days: 2);

  /// Read notifications are deleted after [readRetention], all of them
  /// after [retention] ([purgeOld]).
  static const readRetention = Duration(days: 90);
  static const retention = Duration(days: 365);

  /// Claims [ids] for an email: only rows still pending, unread and not
  /// emailed are claimed (and marked emailed at [at]), so the immediate
  /// email and the digest never send the same notification twice. Returns
  /// the claimed ids.
  static Future<Set<int>> _claim(
    Session session,
    Set<int> ids,
    DateTime at,
  ) async {
    if (ids.isEmpty) return const {};
    final claimed = await UserNotification.db.updateWhere(
      session,
      columnValues: (t) => [t.emailPending(false), t.emailedAt(at)],
      where: (t) =>
          t.id.inSet(ids) &
          t.emailPending.equals(true) &
          t.emailedAt.equals(null) &
          t.readAt.equals(null),
    );
    return {for (final n in claimed) n.id!};
  }

  /// Gives claimed [ids] back after a failed send (the digest retries
  /// them within [emailWindow]).
  static Future<void> _unclaim(Session session, Set<int> ids) async {
    if (ids.isEmpty) return;
    await UserNotification.db.updateWhere(
      session,
      columnValues: (t) => [t.emailPending(true), t.emailedAt(null)],
      where: (t) => t.id.inSet(ids),
    );
  }

  /// Ends the pending state of [ids] without an email (the kind is no
  /// longer set to email).
  static Future<void> _skip(Session session, Set<int> ids) async {
    if (ids.isEmpty) return;
    await UserNotification.db.updateWhere(
      session,
      columnValues: (t) => [t.emailPending(false)],
      where: (t) => t.id.inSet(ids),
    );
  }

  /// Sends the email of one notification (mentions and assignments, or
  /// every kind when the user turned the digest off). Idempotent: skips
  /// notifications that were read, already emailed (or claimed by a
  /// digest), or whose kind is no longer set to email. Returns whether an
  /// email was sent.
  static Future<bool> sendImmediate(
    Session session,
    int notificationId, {
    DateTime? now,
  }) async {
    final row = await UserNotification.db.findById(session, notificationId);
    if (row == null ||
        row.readAt != null ||
        row.emailedAt != null ||
        row.emailPending != true) {
      return false;
    }
    final settings = await _settings(session, row.userId);
    if (channelOf(settings, row.kind) != 'email') {
      await _skip(session, {notificationId});
      return false;
    }
    final profile = await UserProfile.db.findById(session, row.userId);
    if (profile == null) return false;
    final view = (await _views(session, [row])).single;
    final claimed = await _claim(session, {notificationId}, now ?? nowUtc());
    if (claimed.isEmpty) return false;
    try {
      await emailSender.send(
        session,
        _emails.single(
          to: profile.email,
          displayName: profile.displayName,
          notification: view,
        ),
      );
    } on Object catch (e) {
      // Given back: the next digest retries it.
      await _unclaim(session, claimed);
      session.log(
        'Email of notification $notificationId failed: $e',
        level: LogLevel.warning,
      );
      return false;
    }
    return true;
  }

  /// Pending notifications read per [sendDigests] round.
  static int digestBatch = 5000;

  /// Email digest job (every 15 min, specs/07 §4): per user, one email with
  /// the unread notifications of the last two days whose kind is set to
  /// email and that were not emailed yet (including immediate emails that
  /// failed). Returns the number of digests sent.
  ///
  /// Only rows waiting for an email (`emailPending`) are read, so
  /// notifications of in-app kinds never fill the batch (they starved later
  /// users before); each user's rows are claimed before the email goes
  /// out.
  static Future<int> sendDigests(Session session, {DateTime? now}) async {
    final at = now ?? nowUtc();
    final windowStart = at.subtract(emailWindow);
    // Read or too old: no email any more.
    await UserNotification.db.updateWhere(
      session,
      columnValues: (t) => [t.emailPending(false)],
      where: (t) =>
          t.emailPending.equals(true) &
          (t.readAt.notEquals(null) | (t.createdAt <= windowStart)),
    );
    var sent = 0;
    // Users whose rows are done this run (sent, skipped or failed).
    final done = <int>{};
    while (true) {
      final pending = await UserNotification.db.find(
        session,
        where: (t) =>
            t.emailPending.equals(true) &
            t.readAt.equals(null) &
            t.emailedAt.equals(null) &
            (t.createdAt > windowStart) &
            t.userId.notInSet(done),
        orderBy: (t) => t.userId,
        limit: digestBatch,
      );
      if (pending.isEmpty) break;
      final byUser = <int, List<UserNotification>>{};
      for (final n in pending) {
        byUser.putIfAbsent(n.userId, () => []).add(n);
      }
      for (final entry in byUser.entries) {
        done.add(entry.key);
        if (await _sendDigest(session, entry.key, entry.value, at)) sent++;
      }
    }
    return sent;
  }

  /// Sends [rows]' digest to [userId]; returns whether one was sent.
  static Future<bool> _sendDigest(
    Session session,
    int userId,
    List<UserNotification> rows,
    DateTime at,
  ) async {
    final settings = await _settings(session, userId);
    final wanted = [
      for (final n in rows)
        if (channelOf(settings, n.kind) == 'email') n,
    ];
    await _skip(session, {
      for (final n in rows)
        if (!wanted.contains(n)) n.id!,
    });
    final profile = await UserProfile.db.findById(session, userId);
    if (wanted.isEmpty || profile == null) return false;
    final claimed = await _claim(session, {for (final n in wanted) n.id!}, at);
    if (claimed.isEmpty) return false;
    try {
      await emailSender.send(
        session,
        _emails.digest(
          to: profile.email,
          displayName: profile.displayName,
          notifications: await _views(session, [
            for (final n in wanted)
              if (claimed.contains(n.id)) n,
          ]),
        ),
      );
    } on Object catch (e) {
      await _unclaim(session, claimed);
      session.log('Digest for $userId failed: $e', level: LogLevel.warning);
      return false;
    }
    return true;
  }

  /// Notifications deleted per round of [purgeOld].
  static const purgeBatch = 5000;

  /// Daily retention (specs/07 §4): read notifications older than
  /// [readRetention] and all older than [retention], in batches until none
  /// are left or [budget] is spent. Returns the number deleted.
  static Future<int> purgeOld(
    Session session, {
    DateTime? now,
    Duration budget = const Duration(minutes: 5),
  }) async {
    final at = now ?? nowUtc();
    final watch = Stopwatch()..start();
    var deleted = 0;
    while (watch.elapsed < budget) {
      final n = await session.db.unsafeExecute(
        '''
        DELETE FROM notification WHERE id IN (
          SELECT id FROM notification
          WHERE "createdAt" < @read
            AND ("readAt" IS NOT NULL OR "createdAt" < @all)
          LIMIT $purgeBatch)
        ''',
        parameters: QueryParameters.named({
          'read': at.subtract(readRetention),
          'all': at.subtract(retention),
        }),
      );
      deleted += n;
      if (n < purgeBatch) break;
    }
    return deleted;
  }

  static Never notFound() => throw Errors.notFound('Notification');
}
