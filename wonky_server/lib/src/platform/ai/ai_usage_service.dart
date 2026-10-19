import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import 'ai_config.dart';
import 'ai_keys.dart';
import 'llm/ai_client.dart';

/// Availability, settings, budgets and concurrency of the AI features
/// (suite 10 §1 "Limits & cost control", "Privacy").
abstract final class AiUsageService {
  /// Status reasons.
  static const notConfigured = 'notConfigured';
  static const disabled = 'disabled';
  static const optedOut = 'optedOut';

  static const notConfiguredMessage = "AI isn't configured on this server.";
  static const addKeyMessage =
      "AI isn't set up on this server. Add your own OpenAI, Anthropic or "
      'Gemini API key in Settings › AI providers to use it.';
  static const disabledMessage = 'AI is turned off on this server.';
  static const optedOutMessage =
      'The assistant is turned off in your settings (Settings › AI).';
  static const budgetMessage =
      "You've reached today's AI usage limit. It resets at midnight UTC.";

  /// The user's AI quality setting.
  static Future<AiQuality> quality(Session session, int userId) async {
    final row = await AiUserSetting.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    return row?.quality ?? AiQuality.best;
  }

  static Future<void> setQuality(
    Session session,
    int userId,
    AiQuality quality,
  ) async {
    final row = await AiUserSetting.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (row == null) {
      await AiUserSetting.db.insertRow(
        session,
        AiUserSetting(userId: userId, quality: quality, updatedAt: nowUtc()),
      );
    } else {
      await AiUserSetting.db.updateRow(
        session,
        row.copyWith(quality: quality, updatedAt: nowUtc()),
      );
    }
  }

  /// Start of the current budget day (UTC).
  static DateTime dayStart() {
    final n = nowUtc();
    return DateTime.utc(n.year, n.month, n.day);
  }

  /// Budget tokens of [u]: input, cache writes and output count fully,
  /// cache reads a tenth (they cost a tenth or less).
  static int budgetTokens(AiTokenUsage u) =>
      u.inputTokens +
      u.cacheWriteTokens +
      u.outputTokens +
      u.cacheReadTokens ~/ 10;

  /// Budget tokens used today: [budgetTokens] summed over today's rows in
  /// one query (the `ai_usage_user_at_idx` range), not row by row in Dart.
  static Future<int> usedToday(Session session, int userId) async {
    final result = await session.db.unsafeQuery(
      'SELECT COALESCE(SUM("inputTokens" + "cacheWriteTokens" + '
      '"outputTokens" + "cacheReadTokens" / 10), 0)::bigint '
      'FROM ai_usage WHERE "userId" = @user AND "at" >= @from',
      parameters: QueryParameters.named({'user': userId, 'from': dayStart()}),
    );
    final value = result.isEmpty ? null : result.first.first;
    return value is int ? value : int.tryParse('$value') ?? 0;
  }

  /// Records one response's usage and logs cache hits (to verify caching).
  static Future<void> record(
    Session session, {
    required int userId,
    required String model,
    required String feature,
    required AiTokenUsage usage,
  }) async {
    session.log(
      'AI $feature $model: $usage',
      level: LogLevel.debug,
    );
    await AiUsage.db.insertRow(
      session,
      AiUsage(
        userId: userId,
        model: model,
        feature: feature,
        inputTokens: usage.inputTokens,
        outputTokens: usage.outputTokens,
        cacheReadTokens: usage.cacheReadTokens,
        cacheWriteTokens: usage.cacheWriteTokens,
        at: nowUtc(),
      ),
    );
  }

  /// Deletes usage older than 90 days (the daily job); returns the count.
  static Future<int> purge(Session session, {DateTime? now}) async {
    final cutoff = (now ?? nowUtc()).subtract(const Duration(days: 90));
    final deleted = await AiUsage.db.deleteWhere(
      session,
      where: (t) => t.at < cutoff,
    );
    return deleted.length;
  }

  /// The status shown in the panel and settings: availability, the
  /// provider and whose key is used, whether the user may add a key.
  static Future<AssistantStatus> status(Session session, int userId) async {
    final config = AiConfig.current;
    final q = await quality(session, userId);
    final used = await usedToday(session, userId);
    final userKey = config.configured
        ? null
        : await AiKeys.userKey(session, userId);
    final credentials = AiKeys.resolve(config, userKey: userKey);
    String? reason;
    String? message;
    if (!config.enabled) {
      reason = disabled;
      message = disabledMessage;
    } else if (credentials == null) {
      reason = notConfigured;
      message = config.userKeysAllowed ? addKeyMessage : notConfiguredMessage;
    } else {
      final prefs = await UserPreferences.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userId),
      );
      if (prefs != null && !prefs.aiEnabled) {
        reason = optedOut;
        message = optedOutMessage;
      }
    }
    return AssistantStatus(
      available: reason == null,
      reason: reason,
      message: message,
      quality: q,
      tokensUsedToday: used,
      dailyTokenBudget: config.dailyTokenBudget,
      provider: config.enabled ? credentials?.provider : null,
      keySource: config.enabled ? credentials?.source.name : null,
      userKeysAllowed: config.userKeysAllowed,
      userKey: userKey == null ? null : AiKeys.view(userKey),
    );
  }

  /// Throws a [WonkyException] (`unavailable`) when AI can't be used by
  /// [userId], or (`limitExceeded`) when the daily budget is spent.
  static Future<void> requireAvailable(Session session, int userId) async {
    final s = await status(session, userId);
    if (!s.available) {
      throw WonkyException(
        code: WonkyErrorCode.unavailable,
        message: s.message ?? notConfiguredMessage,
        detailsJson: '{"reason":"${s.reason}"}',
      );
    }
    // The status already summed today's usage: one query, not two.
    _checkBudget(s.tokensUsedToday);
  }

  static void _checkBudget(int used) {
    final budget = AiConfig.current.dailyTokenBudget;
    if (budget > 0 && used >= budget) {
      throw Errors.limit(budgetMessage, detailsJson: '{"reason":"budget"}');
    }
  }

  static Future<void> requireBudget(Session session, int userId) async {
    if (AiConfig.current.dailyTokenBudget <= 0) return;
    _checkBudget(await usedToday(session, userId));
  }

  // ------------------------------------------------------------ concurrency

  static final Map<int, int> _running = {};

  /// Reserves one of the user's concurrent request slots; the returned
  /// function releases it. Throws `busy` when all are in use.
  static void Function() acquire(int userId) {
    final max = AiConfig.current.maxConcurrentRequests;
    final n = _running[userId] ?? 0;
    if (max > 0 && n >= max) {
      throw Errors.busy(
        'The assistant is already working on $n requests. Wait for one to '
        'finish or stop it.',
      );
    }
    _running[userId] = n + 1;
    var released = false;
    return () {
      if (released) return;
      released = true;
      final left = (_running[userId] ?? 1) - 1;
      if (left <= 0) {
        _running.remove(userId);
      } else {
        _running[userId] = left;
      }
    };
  }

  /// Requests in flight for [userId] (tests).
  static int running(int userId) => _running[userId] ?? 0;
}
