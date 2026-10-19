import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart'
    show CellHistoryEntry, CellHistoryPage, UserSummary, UuidValue;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart' show RevOpMeta;
import 'package:wonky_sheets_core/model.dart';

import '../sheet_editor/sheet_editor_controller.dart';
import '../revlog/logged_workbook_session.dart';

/// The cell whose history is shown (ids; merged cells use the top-left).
@immutable
class CellHistoryTarget {
  const CellHistoryTarget(this.sheetId, this.rowId, this.colId);

  final String sheetId;
  final String rowId;
  final String colId;

  @override
  bool operator ==(Object other) =>
      other is CellHistoryTarget &&
      other.sheetId == sheetId &&
      other.rowId == rowId &&
      other.colId == colId;

  @override
  int get hashCode => Object.hash(sheetId, rowId, colId);
}

/// One entry of a cell's value history (Sheets 10 §6).
@immutable
class CellHistoryItem {
  const CellHistoryItem({
    required this.changeLogId,
    required this.at,
    required this.actorKind,
    required this.label,
    this.userUuid,
    this.user,
    this.before,
    this.after,
    this.bulk = false,
  });

  final String changeLogId;
  final DateTime at;

  /// Auth user uuid (local entries) — names come from [user] when known.
  final String? userUuid;
  final UserSummary? user;
  final String actorKind;

  /// Change label ("Paste", "Fill down", "Restore version …").
  final String label;
  final String? before;
  final String? after;

  /// A bulk change without per-cell details ("Changed as part of 'Paste'").
  final bool bulk;

  CellHistoryItem withUser(UserSummary? u) => CellHistoryItem(
    changeLogId: changeLogId,
    at: at,
    actorKind: actorKind,
    label: label,
    userUuid: userUuid,
    user: u ?? user,
    before: before,
    after: after,
    bulk: bulk,
  );
}

/// Reads the local op metadata (last 30 days) of a spreadsheet (RevLog spec
/// 06 §3.3).
typedef LocalChangeLogSource = Future<List<RevOpMeta>> Function();

/// Reads a page of server `CellHistory` (older entries; online only).
typedef ServerCellHistorySource =
    Future<CellHistoryPage> Function(CellHistoryTarget target, String? cursor);

/// Loads and merges a cell's history from the local change log (offline,
/// 30 days) and the server's `CellHistory` (older, up to 100), newest
/// first, de-duplicated by change log id (Sheets 10 §6).
class CellHistoryController extends ChangeNotifier {
  CellHistoryController({
    required this.target,
    required this.model,
    this.local,
    this.server,
  });

  final CellHistoryTarget target;
  final WorkbookModel model;
  final LocalChangeLogSource? local;
  final ServerCellHistorySource? server;

  List<CellHistoryItem> _local = const [];
  List<CellHistoryItem> _server = const [];
  List<CellHistoryItem> items = const [];
  String? _cursor;
  bool loading = true;
  bool hasMore = false;
  bool offline = false;
  int index = 0;
  bool _disposed = false;

  /// Local change log window.
  static const localWindow = Duration(days: 30);

  CellHistoryItem? get current =>
      items.isEmpty ? null : items[index.clamp(0, items.length - 1)];

  Future<void> load() async {
    loading = true;
    _notify();
    if (local != null) {
      try {
        _local = localItems(await local!(), target, model);
      } catch (e) {
        debugPrint('Local cell history failed: $e');
      }
    }
    items = merge(_local, _server);
    _notify();
    await _loadServer();
    loading = false;
    _notify();
  }

  Future<void> _loadServer() async {
    final s = server;
    if (s == null) return;
    try {
      final page = await s(target, _cursor);
      _server = [..._server, for (final e in page.entries) fromServer(e)];
      _cursor = page.nextCursor;
      hasMore = page.nextCursor != null;
      offline = false;
    } catch (e) {
      offline = true;
      hasMore = false;
    }
    items = merge(_local, _server);
  }

  /// Loads older server entries.
  Future<void> loadMore() async {
    if (!hasMore) return;
    loading = true;
    _notify();
    await _loadServer();
    loading = false;
    _notify();
  }

  void next() {
    if (index < items.length - 1) {
      index++;
      _notify();
      if (index >= items.length - 2 && hasMore) loadMore();
    }
  }

  void previous() {
    if (index > 0) {
      index--;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ------------------------------------------------------------- parsing

  static CellHistoryItem fromServer(CellHistoryEntry e) => CellHistoryItem(
    changeLogId: '${e.revision}',
    at: e.at,
    actorKind: e.actorKind.name,
    label: e.label,
    user: e.user,
    before: e.before,
    after: e.after,
  );

  /// Entries of [target] in local change log [rows]: per-cell details, or
  /// bulk value changes whose ranges cover the cell.
  static List<CellHistoryItem> localItems(
    List<RevOpMeta> rows,
    CellHistoryTarget target,
    WorkbookModel model,
  ) {
    final cutoff = clock.now().subtract(localWindow);
    final out = <CellHistoryItem>[];
    for (final r in rows) {
      if (r.committedAt.isBefore(cutoff)) continue;
      final detail = r.detail == null ? null : jsonEncode(r.detail);
      if (detail != null) {
        final cell = _detailCell(detail, target);
        if (cell == null) continue;
        out.add(
          CellHistoryItem(
            changeLogId: '${r.revision}',
            at: r.committedAt,
            userUuid: r.authorUuid ?? '',
            actorKind: r.actorKind,
            label: r.label,
            before: cell.$1,
            after: cell.$2,
          ),
        );
        continue;
      }
      if (_bulkCovers(jsonEncode(r.summary ?? const {}), target, model)) {
        out.add(
          CellHistoryItem(
            changeLogId: '${r.revision}',
            at: r.committedAt,
            userUuid: r.authorUuid ?? '',
            actorKind: r.actorKind,
            label: r.label,
            bulk: true,
          ),
        );
      }
    }
    return out;
  }

  static (String?, String?)? _detailCell(String json, CellHistoryTarget t) {
    try {
      final j = jsonDecode(json);
      if (j is! Map || j['cells'] is! List) return null;
      for (final c in j['cells'] as List) {
        if (c is! Map) continue;
        if ((c['s'] ?? c['sheetId']) == t.sheetId &&
            (c['r'] ?? c['rowId']) == t.rowId &&
            (c['c'] ?? c['colId']) == t.colId) {
          return (
            (c['b'] ?? c['before']) as String?,
            (c['a'] ?? c['after']) as String?,
          );
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  static bool _bulkCovers(
    String summaryJson,
    CellHistoryTarget t,
    WorkbookModel model,
  ) {
    final ChangeSummary s;
    try {
      s = ChangeSummary.parse(summaryJson);
    } on Object {
      return false;
    }
    if (!s.kinds.contains(ChangeKinds.values) &&
        !s.kinds.contains(ChangeKinds.restore) &&
        !s.kinds.contains(ChangeKinds.import)) {
      return false;
    }
    final sheet = model.sheet(t.sheetId);
    if (sheet == null) return false;
    final row = sheet.rows.indexOf(t.rowId);
    final col = sheet.columns.indexOf(t.colId);
    if (row < 0 || col < 0) return false;
    for (final r in s.ranges) {
      final gr = GridRange.tryParse(r);
      if (gr == null || gr.sheetId != t.sheetId) continue;
      final rr = sheet.resolve(gr);
      if (rr != null && rr.rect.contains(row, col)) return true;
    }
    return false;
  }

  /// Local and server entries merged by change log id (server user info
  /// wins), newest first.
  static List<CellHistoryItem> merge(
    List<CellHistoryItem> local,
    List<CellHistoryItem> server,
  ) {
    final byId = <String, CellHistoryItem>{};
    for (final e in local) {
      byId[e.changeLogId] = e;
    }
    for (final e in server) {
      final l = byId[e.changeLogId];
      byId[e.changeLogId] = l == null ? e : l.withUser(e.user);
    }
    return byId.values.toList()..sort((a, b) => b.at.compareTo(a.at));
  }
}

/// Wires a [CellHistoryController] to the editor's replica and the server.
CellHistoryController cellHistoryFor(
  SheetEditorController editor,
  CellHistoryTarget target,
) {
  final session = editor.session;
  LocalChangeLogSource? local;
  if (session is LoggedWorkbookSession) {
    local = () => session.recentOps(CellHistoryController.localWindow);
  }
  final client = editor.services.client;
  ServerCellHistorySource? server;
  if (client != null) {
    server = (t, cursor) {
      if (Api.simulatedOffline) {
        throw const OfflineException('simulated offline');
      }
      return client.sheets.cellHistory(
        UuidValue.fromString(editor.session.spreadsheetId),
        UuidValue.fromString(t.sheetId),
        UuidValue.fromString(t.rowId),
        UuidValue.fromString(t.colId),
        cursor,
      );
    };
  }
  return CellHistoryController(
    target: target,
    model: editor.model,
    local: local,
    server: server,
  )..load();
}
