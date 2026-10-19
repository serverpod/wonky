import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../platform/common/models.dart';
import '../../platform/common/rate_limiter.dart';
import '../../platform/users/user_service.dart';
import '../sheets_service.dart';
import 'script_service.dart';
import 'script_executions.dart';
import 'script_authorizations.dart';
import 'script_triggers.dart';

/// Scripts of a spreadsheet (Sheets 09): build, run on server, executions
/// log, authorization and the URL fetch proxy. `spreadsheetUuid` is the
/// drive item uuid or the space uuid.
class ScriptEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Builds the project's current sources (09 §9.1); returns diagnostics.
  Future<ScriptCompileResponse> compile(
    Session session,
    UuidValue spreadsheetUuid,
  ) async => ScriptService.compile(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
  );

  /// Diagnostics for unsaved editor content (09 §9.5); JSON list.
  Future<String> analyze(
    Session session,
    UuidValue spreadsheetUuid,
    String fileName,
    String source,
  ) async => ScriptService.analyze(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
    fileName,
    source,
  );

  /// EVC bytecode of the last good build (clients cache it by build hash).
  Future<ByteData> bytecode(Session session, UuidValue spreadsheetUuid) async =>
      ScriptService.bytecode(
        session,
        await UserService.actorOf(session),
        spreadsheetUuid,
      );

  /// *Run on server* (09 §14.5): [argsJson] is a JSON list.
  Future<ScriptRunResponse> run(
    Session session,
    UuidValue spreadsheetUuid,
    String functionName,
    String? argsJson,
  ) async => ScriptService.run(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
    functionName,
    args: argsJson == null
        ? const []
        : (jsonDecode(argsJson) as List).cast<Object?>(),
  );

  /// *Run on server* with live logs (09 §14.5): JSON events, first
  /// `{"log": {t, level, msg}}` per log line while the function runs, then
  /// `{"result": ScriptRunResponse}`.
  Stream<String> runLive(
    Session session,
    UuidValue spreadsheetUuid,
    String functionName,
    String? argsJson,
  ) async* {
    final actor = await UserService.actorOf(session);
    final events = StreamController<String>();
    unawaited(
      ScriptService.run(
            session,
            actor,
            spreadsheetUuid,
            functionName,
            args: argsJson == null
                ? const []
                : (jsonDecode(argsJson) as List).cast<Object?>(),
            onLog: (e) {
              if (!events.isClosed) {
                events.add(jsonEncode({'log': e.toJson()}));
              }
            },
          )
          .then(
            (r) => events.add(jsonEncode({'result': r.toJson()})),
            onError: events.addError,
          )
          .whenComplete(events.close),
    );
    yield* events.stream;
  }

  /// The executions log, newest first (09 §13.3).
  Future<List<ScriptExecution>> executions(
    Session session,
    UuidValue spreadsheetUuid, {
    String? functionName,
    ScriptExecutionStatus? status,
    DateTime? before,
    int limit = 50,
  }) async => ScriptExecutions.executions(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
    functionName: functionName,
    status: status,
    before: before,
    limit: limit,
  );

  /// Uploads client executions (batched, 09 §13.1).
  Future<int> reportExecutions(
    Session session,
    UuidValue spreadsheetUuid,
    List<ScriptExecution> executions,
  ) async => ScriptExecutions.reportExecutions(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
    executions,
  );

  /// `UrlFetchApp` of client executions (09 §8.3): [requestJson] is a
  /// `FetchRequestData` JSON object.
  Future<ScriptFetchResponse> urlFetch(
    Session session,
    UuidValue spreadsheetUuid,
    String requestJson, {
    bool customFunction = false,
  }) async => ScriptService.urlFetch(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
    requestJson,
    customFunction: customFunction,
  );

  /// The caller's granted scopes.
  Future<ScriptAuthorizationView> authorization(
    Session session,
    UuidValue spreadsheetUuid,
  ) async => ScriptAuthorizations.authorization(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
  );

  /// The authorization dialog's *Allow* (09 §11.2).
  Future<ScriptAuthorizationView> authorize(
    Session session,
    UuidValue spreadsheetUuid,
    List<String> scopes,
  ) async => ScriptAuthorizations.authorize(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
    scopes,
  );

  /// *Revoke my authorization* (09 §11.2).
  Future<void> revokeAuthorization(
    Session session,
    UuidValue spreadsheetUuid,
  ) async => ScriptAuthorizations.revokeAuthorization(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
  );

  /// The app opened the spreadsheet online: runs installable onOpen
  /// triggers (09 §8.7.3). Returns the number of runs.
  ///
  /// Opens beyond [openLimiter] (per user and spreadsheet) and
  /// [openLimiterAll] (per spreadsheet, all users) run nothing and return
  /// 0: the triggers run with their installer's authorization and quota.
  Future<int> notifyOpen(Session session, UuidValue spreadsheetUuid) async {
    ScriptService.requireEnabled();
    final actor = await UserService.actorOf(session);
    final item = await SheetsService.byItemOrSpace(
      session,
      actor,
      spreadsheetUuid,
      Role.viewer,
    );
    if (await openLimiter.check('${actor.userId}:${item.id}') != null ||
        await openLimiterAll.check('${item.id}') != null) {
      return 0;
    }
    return ScriptTriggerService.fireOpen(session, item);
  }

  /// onOpen runs per user and spreadsheet.
  static final openLimiter = RateLimiter(
    name: 'script:notifyOpen',
    limit: 10,
    window: const Duration(minutes: 1),
  );

  /// onOpen runs per spreadsheet (all users together).
  static final openLimiterAll = RateLimiter(
    name: 'script:notifyOpenAll',
    limit: 120,
    window: const Duration(minutes: 1),
  );
}
