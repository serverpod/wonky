import 'dart:async';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../sheets_service.dart';

import 'script_service.dart';

/// Authorization and quotas of Sheets scripts (Sheets 09 §11–§12): the
/// run-as user's grant per project and the daily quota usage.
abstract final class ScriptAuthorizations {
  /// The stored authorization of [userId] for the project (null = none).
  static Future<ScriptAuthorization?> authorizationOf(
    Session session,
    int userId,
    UuidValue space,
  ) => ScriptAuthorization.db.findFirstRow(
    session,
    where: (t) =>
        t.userId.equals(userId) &
        t.spreadsheetUuid.equals(space) &
        t.revokedAt.equals(null),
  );

  /// The scopes [actor] granted for the spreadsheet.
  static Future<ScriptAuthorizationView> authorization(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final item = await SheetsService.byItemOrSpace(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final a = await authorizationOf(session, actor.userId, item.contentRef!);
    return ScriptAuthorizationView(
      scopes: a?.scopes ?? const [],
      grantedAt: a?.grantedAt,
    );
  }

  /// Grants [scopes] (the authorization dialog's *Allow*, 09 §11.2).
  static Future<ScriptAuthorizationView> authorize(
    Session session,
    Actor actor,
    UuidValue uuid,
    List<String> scopes,
  ) async {
    ScriptService.requireEnabled();
    if (actor.kind != ActorKind.user) {
      throw Errors.forbidden('Only people can authorize scripts.');
    }
    final item = await SheetsService.byItemOrSpace(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final unknown = scopes.where(
      (s) => !ScriptScopes.authorizable.contains(s),
    );
    if (unknown.isNotEmpty) {
      throw Errors.invalid('Unknown scope ${unknown.first}');
    }
    final space = item.contentRef!;
    final now = clock.now().toUtc();
    final existing = await ScriptAuthorization.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(actor.userId) & t.spreadsheetUuid.equals(space),
    );
    final merged = {
      if (existing != null && existing.revokedAt == null) ...existing.scopes,
      ...scopes,
    }.toList()..sort();
    if (existing == null) {
      await ScriptAuthorization.db.insertRow(
        session,
        ScriptAuthorization(
          userId: actor.userId,
          spreadsheetUuid: space,
          scopes: merged,
          grantedAt: now,
        ),
      );
    } else {
      await ScriptAuthorization.db.updateRow(
        session,
        existing.copyWith(scopes: merged, grantedAt: now, revokedAt: null),
      );
    }
    return ScriptAuthorizationView(scopes: merged, grantedAt: now);
  }

  /// *Revoke my authorization*: removes the grant and disables the user's
  /// installable triggers of the spreadsheet (09 §11.2).
  static Future<void> revokeAuthorization(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final item = await SheetsService.byItemOrSpace(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final space = item.contentRef!;
    final existing = await authorizationOf(session, actor.userId, space);
    if (existing != null) {
      await ScriptAuthorization.db.updateRow(
        session,
        existing.copyWith(revokedAt: clock.now().toUtc()),
      );
    }
    final p = await ScriptService.project(session, space);
    if (p == null) return;
    final triggers = await ScriptTrigger.db.find(
      session,
      where: (t) =>
          t.projectId.equals(p.id) & t.runAsUserId.equals(actor.authUserId),
    );
    for (final t in triggers) {
      await _disableTrigger(session, t.id, space, 'Authorization revoked.');
    }
  }

  static Future<void> _disableTrigger(
    Session session,
    UuidValue triggerId,
    UuidValue space,
    String reason,
  ) async {
    final state = await ScriptTriggerState.db.findFirstRow(
      session,
      where: (t) => t.triggerId.equals(triggerId),
    );
    if (state == null) {
      await ScriptTriggerState.db.insertRow(
        session,
        ScriptTriggerState(
          triggerId: triggerId,
          spreadsheetUuid: space,
          disabledReason: reason,
        ),
      );
    } else {
      await ScriptTriggerState.db.updateRow(
        session,
        state.copyWith(disabledReason: reason, nextRunAt: null),
      );
    }
  }

  // ---------------------------------------------------------------- quotas

  static DateTime _today() {
    final n = clock.now().toUtc();
    return DateTime.utc(n.year, n.month, n.day);
  }

  /// Today's usage of [userId] (created on demand).
  static Future<ScriptQuotaUsage> usage(Session session, int userId) async {
    final day = _today();
    final found = await ScriptQuotaUsage.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.day.equals(day),
    );
    if (found != null) return found;
    try {
      return await ScriptQuotaUsage.db.insertRow(
        session,
        ScriptQuotaUsage(userId: userId, day: day),
      );
    } on DatabaseQueryException {
      return (await ScriptQuotaUsage.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userId) & t.day.equals(day),
      ))!;
    }
  }

  /// Adds to the user's quota usage of today.
  static Future<void> addUsage(
    Session session,
    int userId, {
    int serverMs = 0,
    int clientMs = 0,
    int fetchCalls = 0,
    int fetchBytes = 0,
    int triggerRuns = 0,
  }) async {
    final u = await usage(session, userId);
    await session.db.unsafeExecute(
      'UPDATE "script_quota_usage" SET '
      '"serverRuntimeMs" = "serverRuntimeMs" + @server, '
      '"clientRuntimeMs" = "clientRuntimeMs" + @client, '
      '"urlFetchCalls" = "urlFetchCalls" + @calls, '
      '"urlFetchBytes" = "urlFetchBytes" + @bytes, '
      '"triggerRuns" = "triggerRuns" + @runs '
      'WHERE "id" = @id',
      parameters: QueryParameters.named({
        'server': serverMs,
        'client': clientMs,
        'calls': fetchCalls,
        'bytes': fetchBytes,
        'runs': triggerRuns,
        'id': u.id,
      }),
    );
  }
}
