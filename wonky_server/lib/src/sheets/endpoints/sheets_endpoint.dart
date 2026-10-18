import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/users/user_service.dart';
import '../images/sheets_image_proxy.dart';
import '../sheets_service.dart';
import '../scripts/script_user_properties.dart';

/// Online-only Sheets operations (suite 12 §2, Sheets 10, 12 §2.5).
class SheetsEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The caller's script user properties of a spreadsheet (RevLog spec
  /// 02 §2.4, Sheets 09 §6.9). Viewer+; private per user.
  Future<Map<String, String>> getUserProperties(
    Session session,
    UuidValue fileUuid,
  ) async => ScriptUserProperties.read(
    session,
    await UserService.actorOf(session),
    fileUuid,
  );

  /// Writes the caller's script user properties (null = delete). Viewer+.
  Future<void> setUserProperties(
    Session session,
    UuidValue fileUuid,
    Map<String, String?> changes,
  ) async => ScriptUserProperties.write(
    session,
    await UserService.actorOf(session),
    fileUuid,
    changes,
  );

  /// Named functions of another spreadsheet for *Import function*
  /// (Sheets 07 §9.4): JSON list of `{name, formula, comment, metaJson}`.
  Future<String> namedFunctions(Session session, UuidValue itemUuid) async =>
      SheetsService.namedFunctions(
        session,
        await UserService.actorOf(session),
        itemUuid,
      );

  /// The theme JSON of another spreadsheet for *Import theme* (Sheets 06
  /// §13).
  Future<String> spreadsheetTheme(Session session, UuidValue itemUuid) async =>
      SheetsService.spreadsheetTheme(
        session,
        await UserService.actorOf(session),
        itemUuid,
      );

  /// Undo of a server-side change (`sheets.serverChange`).
  Future<RevertResult> revertChange(
    Session session,
    UuidValue changeId,
  ) async => SheetsService.revertChange(
    session,
    await UserService.actorOf(session),
    changeId,
  );

  /// Redo of a reverted server-side change ([changeId] of the original or of
  /// its revert).
  Future<RevertResult> reapplyChange(
    Session session,
    UuidValue changeId,
  ) async => SheetsService.reapplyChange(
    session,
    await UserService.actorOf(session),
    changeId,
  );

  Future<CellHistoryPage> cellHistory(
    Session session,
    UuidValue spreadsheetUuid,
    UuidValue sheetId,
    UuidValue rowId,
    UuidValue colId,
    String? cursor,
  ) async => SheetsService.cellHistory(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
    sheetId,
    rowId,
    colId,
    cursor: cursor,
  );

  Future<SheetsActivitySummary> activitySummary(
    Session session,
    UuidValue spreadsheetUuid,
    int days,
  ) async => SheetsService.activitySummary(
    session,
    await UserService.actorOf(session),
    spreadsheetUuid,
    days,
  );

  /// Image proxy for `IMAGE("https://…")` cells and images inserted by URL
  /// (08 §10): the bytes of the https image [url] (private addresses are
  /// refused).
  Future<ByteData> fetchImage(
    Session session,
    UuidValue itemUuid,
    String url,
  ) async => SheetsImageProxy.fetch(
    session,
    await UserService.actorOf(session),
    itemUuid,
    url,
  );
}
