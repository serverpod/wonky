import 'dart:async';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/sharing/access_service.dart';
import '../sheets_service.dart';

import 'script_authorizations.dart';
import 'script_service.dart';

/// The execution log of Sheets scripts (Sheets 09 §13.3): listing,
/// reporting and pruning executions.
abstract final class ScriptExecutions {
  /// The executions of a spreadsheet, newest first (09 §13.3): editors see
  /// all, others their own.
  static Future<List<ScriptExecution>> executions(
    Session session,
    Actor actor,
    UuidValue uuid, {
    String? functionName,
    ScriptExecutionStatus? status,
    DateTime? before,
    int limit = 50,
  }) async {
    final item = await SheetsService.byItemOrSpace(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final role = await AccessService.effectiveRole(
      session,
      actor.userId,
      item,
    );
    final space = item.contentRef!;
    final all = role != null && role >= Role.editor;
    return ScriptExecution.db.find(
      session,
      where: (t) {
        Expression<Object?> e = t.spreadsheetUuid.equals(space);
        if (!all) e = e & t.userId.equals(actor.userId);
        if (functionName != null) e = e & t.functionName.equals(functionName);
        if (status != null) e = e & t.status.equals(status);
        if (before != null) e = e & (t.startedAt < before);
        return e;
      },
      orderBy: (t) => t.startedAt.desc(),
      limit: limit.clamp(1, 200),
    );
  }

  /// Client executions uploaded in batches (09 §13.1). The server owns the
  /// user and the runtime fields; client runtime counts toward the (soft)
  /// client quota.
  static Future<int> reportExecutions(
    Session session,
    Actor actor,
    UuidValue uuid,
    List<ScriptExecution> executions,
  ) async {
    ScriptService.requireEnabled();
    if (executions.length > 1000) {
      throw Errors.invalid('At most 1,000 executions per report.');
    }
    final item = await SheetsService.byItemOrSpace(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final space = item.contentRef!;
    var clientMs = 0;
    final rows = [
      for (final e in executions)
        e.copyWith(
          id: null,
          spreadsheetUuid: space,
          userId: actor.userId,
          runAsUserId: actor.userId,
          runtime: e.runtime == ScriptRuntimeKind.server
              ? ScriptRuntimeKind.clientDesktop
              : e.runtime,
          logs: ScriptService.truncateLogs(e.logs),
          changeId: null,
        ),
    ];
    for (final r in rows) {
      clientMs += r.durationMs.clamp(0, 6 * 3600 * 1000);
    }
    await ScriptExecution.db.insert(session, rows);
    await ScriptAuthorizations.addUsage(
      session,
      actor.userId,
      clientMs: clientMs,
    );
    return rows.length;
  }

  /// Daily pruning: executions older than 30 days and beyond 10,000 per
  /// spreadsheet.
  static Future<int> pruneExecutions(Session session) async {
    final cutoff = clock.now().toUtc().subtract(
      ScriptService.executionRetention,
    );
    final old = await ScriptExecution.db.deleteWhere(
      session,
      where: (t) => t.startedAt < cutoff,
    );
    final extra = await session.db.unsafeExecute(
      'DELETE FROM "script_execution" WHERE "id" IN ('
      'SELECT "id" FROM (SELECT "id", row_number() OVER '
      '(PARTITION BY "spreadsheetUuid" ORDER BY "startedAt" DESC) AS n '
      'FROM "script_execution") ranked WHERE n > ${ScriptService.maxExecutionsPerSpreadsheet})',
    );
    return old.length + extra;
  }
}
