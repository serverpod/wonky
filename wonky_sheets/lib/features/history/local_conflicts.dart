import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart' show RevOpMeta;
import 'package:wonky_sheets_core/formula.dart' show CellPos;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sync_models/ids.dart' show SheetsIds;

import '../sheet_editor/sheet_editor_controller.dart';
import '../revlog/logged_workbook_session.dart';

/// Why an offline edit didn't survive the merge.
enum LocalConflictKind {
  /// Someone wrote a newer value into the cell.
  overwritten,

  /// The cell's row, column or sheet was deleted.
  rowDeleted,
  columnDeleted,
  sheetDeleted,
}

/// An offline edit replaced by a newer edit from someone else (Sheets 10
/// §9, Additions A-10-4 `LocalConflict`). Kept in the user's local store
/// for [SheetsConflicts.lifetime].
@immutable
class LocalConflict {
  const LocalConflict({
    required this.id,
    required this.kind,
    required this.sheetId,
    required this.rowId,
    required this.colId,
    required this.myValue,
    required this.theirValue,
    required this.detectedAt,
    this.theirUserId,
    this.theirName,
    this.changeLogId,
    this.label,
    this.dismissed = false,
  });

  final String id;
  final LocalConflictKind kind;
  final String sheetId;
  final String rowId;
  final String colId;

  /// Stored contents (null = empty).
  final String? myValue;
  final String? theirValue;

  /// Auth user uuid and name of the winning writer (null when unknown).
  final String? theirUserId;
  final String? theirName;
  final String? changeLogId;

  /// "Sheet1!B4" when detected (the live reference is computed from ids).
  final String? label;
  final DateTime detectedAt;
  final bool dismissed;

  bool get canApply => kind == LocalConflictKind.overwritten;

  LocalConflict dismiss() => LocalConflict(
    id: id,
    kind: kind,
    sheetId: sheetId,
    rowId: rowId,
    colId: colId,
    myValue: myValue,
    theirValue: theirValue,
    detectedAt: detectedAt,
    theirUserId: theirUserId,
    theirName: theirName,
    changeLogId: changeLogId,
    label: label,
    dismissed: true,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'k': kind.name,
    's': sheetId,
    'r': rowId,
    'c': colId,
    'mine': myValue,
    'theirs': theirValue,
    'u': theirUserId,
    'n': theirName,
    'cl': changeLogId,
    'l': label,
    'at': detectedAt.toUtc().toIso8601String(),
    if (dismissed) 'd': true,
  };

  static LocalConflict? fromJson(Object? j) {
    if (j is! Map) return null;
    final kind = LocalConflictKind.values
        .where((k) => k.name == j['k'])
        .firstOrNull;
    final at = DateTime.tryParse('${j['at']}');
    if (kind == null || at == null || j['id'] is! String) return null;
    return LocalConflict(
      id: j['id'] as String,
      kind: kind,
      sheetId: '${j['s']}',
      rowId: '${j['r']}',
      colId: '${j['c']}',
      myValue: j['mine'] as String?,
      theirValue: j['theirs'] as String?,
      theirUserId: j['u'] as String?,
      theirName: j['n'] as String?,
      changeLogId: j['cl'] as String?,
      label: j['l'] as String?,
      detectedAt: at,
      dismissed: j['d'] == true,
    );
  }
}

/// A cell written while offline.
typedef _OfflineCell = ({
  String sheetId,
  String rowId,
  String colId,
  String? content,
  DateTime at,
});

/// Overwritten offline edits (Sheets 10 §9, P1) and "your sort was
/// replaced" (§10 #8): records the cells (and sorts) written while offline,
/// and after the next sync compares them with the merged state. Cells whose
/// value now differs because someone else wrote later — or whose row,
/// column or sheet was deleted — become [LocalConflict]s; the toast offers
/// the review dialog (`sheets.conflicts.review`), where *Apply mine again*
/// (`sheets.conflicts.applyMine`) writes the user's values back.
class SheetsConflicts extends ChangeNotifier {
  SheetsConflicts(
    this.editor, {
    LocalStore? store,
    this.changeLogs,
    this.isOffline,
    this.names,
  }) : store = store ?? editor.services.userStore {
    editor.applyListeners.add(_onApply);
    editor.model.addListener(_onBatch);
    editor.services.connectivity.addListener(_onConnectivity);
    _wasOnline = !_offline;
    unawaited(_load());
  }

  final SheetEditorController editor;
  final LocalStore store;

  /// The local op metadata (overrides the session's; tests).
  final Future<List<RevOpMeta>> Function()? changeLogs;

  /// Whether writes count as offline (overrides connectivity; tests).
  final bool Function()? isOffline;

  /// Names of auth user uuids (collaborators present).
  final String? Function(String userUuid)? names;

  /// Conflicts expire after this long (Sheets 10 §9).
  static const lifetime = Duration(days: 7);

  /// Max tracked offline cells per spreadsheet.
  static const maxTracked = 20000;

  /// Max tracked rows of an offline sort.
  static const maxSortRows = 5000;

  final Map<String, _OfflineCell> _cells = {};

  /// Offline sorts: sheet id → row id → the sortKey we wrote.
  final Map<String, Map<String, String>> _sorts = {};
  List<LocalConflict> _all = const [];
  bool _wasOnline = true;
  bool _disposed = false;
  Timer? _save;
  Timer? _settle;

  ShellServices get services => editor.services;
  String get _item => editor.session.itemUuid.uuid;
  String get _trackKey => 'sheets.offlineEdits.$_item';
  String get _conflictKey => 'sheets.conflicts.$_item';

  bool get _offline =>
      isOffline?.call() ??
      (!services.connectivity.online || Api.simulatedOffline);

  /// Open conflicts (not dismissed, not expired), newest first.
  List<LocalConflict> get open {
    final cutoff = clock.now().subtract(lifetime);
    return [
      for (final c in _all)
        if (!c.dismissed && c.detectedAt.isAfter(cutoff)) c,
    ]..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  /// Who replaced an offline sort in the last [check] (tests).
  String? lastSortReplacedBy;

  /// Cells written offline and not yet checked (tests, diagnostics).
  int get trackedCells => _cells.length;

  // ------------------------------------------------------------- tracking

  /// Model batches since the last applied plan.
  final List<WorkbookChangeBatch> _batches = [];

  void _onBatch(WorkbookChangeBatch b) {
    if (_batches.length > 64) _batches.removeAt(0);
    _batches.add(b);
  }

  void _onApply(CommandContext? ctx, SheetsOperation op, MutationPlan plan) {
    if (_disposed || plan.isEmpty) return;
    final offline = _offline;
    final now = clock.now().toUtc();
    final sortRows = <String, Map<String, String>>{};
    var changed = false;
    // Cells: the content keys of the model batches this plan emitted (an
    // update names only its changed columns, not the cell's ids).
    final cellIds = {
      for (final c in plan.changes)
        if (c.table == SheetsTables.cell) c.rowId,
    };
    final batches = List.of(_batches);
    _batches.clear();
    for (final b in batches) {
      for (final e in b.whereType<CellsChanged>()) {
        for (final k in e.contentKeys) {
          final id = SheetsIds.cellId(e.sheetId, k.rowId, k.colId);
          if (!cellIds.contains(id)) continue;
          if (!offline) {
            // A later online edit of ours supersedes the offline one.
            changed |= _cells.remove(id) != null;
            continue;
          }
          if (_cells.length >= maxTracked && !_cells.containsKey(id)) {
            continue;
          }
          _cells[id] = (
            sheetId: e.sheetId,
            rowId: k.rowId,
            colId: k.colId,
            content: editor.model.cell(e.sheetId, k.rowId, k.colId)?.content,
            at: now,
          );
          changed = true;
        }
      }
    }
    for (final c in plan.changes) {
      if (offline &&
          c.table == SheetsTables.sheetRow &&
          c.op == RowOp.update &&
          c.columnsAfter.containsKey(Cols.sortKey)) {
        final sheetId =
            c.columnsAfter[Cols.sheetId] ?? c.columnsBefore[Cols.sheetId];
        final sheet = sheetId == null ? _sheetOfRow(c.rowId) : '$sheetId';
        if (sheet == null) continue;
        sortRows.putIfAbsent(sheet, () => {})[c.rowId] =
            '${c.columnsAfter[Cols.sortKey]}';
      }
    }
    // A sort rewrites many rows' keys at once (moving one row is not one).
    for (final e in sortRows.entries) {
      if (e.value.length < 2) continue;
      final m = _sorts.putIfAbsent(e.key, () => {});
      for (final r in e.value.entries) {
        if (m.length >= maxSortRows && !m.containsKey(r.key)) break;
        m[r.key] = r.value;
      }
      changed = true;
    }
    if (changed) _scheduleSave();
  }

  String? _sheetOfRow(String rowId) {
    for (final s in editor.model.sheets) {
      if (s.rows.contains(rowId)) return s.id;
    }
    return null;
  }

  void _scheduleSave() {
    _save?.cancel();
    _save = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_persist()),
    );
  }

  Future<void> _persist() async {
    try {
      if (_cells.isEmpty && _sorts.isEmpty) {
        await store.remove(_trackKey);
      } else {
        await store.write(_trackKey, {
          'cells': {
            for (final e in _cells.entries)
              e.key: {
                's': e.value.sheetId,
                'r': e.value.rowId,
                'c': e.value.colId,
                'v': e.value.content,
                'at': e.value.at.toIso8601String(),
              },
          },
          'sorts': _sorts,
        });
      }
    } catch (e) {
      debugPrint('Saving offline edits failed: $e');
    }
  }

  Future<void> _saveConflicts() async {
    try {
      final cutoff = clock.now().subtract(lifetime);
      _all = [
        for (final c in _all)
          if (c.detectedAt.isAfter(cutoff)) c,
      ];
      if (_all.isEmpty) {
        await store.remove(_conflictKey);
      } else {
        await store.write(_conflictKey, [for (final c in _all) c.toJson()]);
      }
    } catch (e) {
      debugPrint('Saving conflicts failed: $e');
    }
  }

  Future<void> _load() async {
    try {
      final raw = await store.read(_trackKey);
      if (raw is Map) {
        final cells = raw['cells'];
        if (cells is Map) {
          for (final e in cells.entries) {
            final v = e.value;
            if (v is! Map) continue;
            _cells.putIfAbsent(
              '${e.key}',
              () => (
                sheetId: '${v['s']}',
                rowId: '${v['r']}',
                colId: '${v['c']}',
                content: v['v'] as String?,
                at: DateTime.tryParse('${v['at']}') ?? clock.now().toUtc(),
              ),
            );
          }
        }
        final sorts = raw['sorts'];
        if (sorts is Map) {
          for (final e in sorts.entries) {
            if (e.value is! Map) continue;
            _sorts.putIfAbsent('${e.key}', () => {}).addAll({
              for (final r in (e.value as Map).entries)
                '${r.key}': '${r.value}',
            });
          }
        }
      }
      final list = await store.read(_conflictKey);
      if (list is List) {
        _all = [for (final j in list) ?LocalConflict.fromJson(j)];
      }
    } catch (e) {
      debugPrint('Reading offline edits failed: $e');
    }
    if (_disposed) return;
    notifyListeners();
    // Edits tracked in an earlier session: check once the replica settled.
    if (!_offline && (_cells.isNotEmpty || _sorts.isNotEmpty)) _afterSync();
  }

  // ------------------------------------------------------------ checking

  void _onConnectivity() {
    final online = !_offline;
    if (online && !_wasOnline) _afterSync();
    _wasOnline = online;
  }

  /// Waits until the outbox drained after reconnecting (our pending writes
  /// are committed and the remote ops before them applied), then [check]s.
  void _afterSync() {
    _settle?.cancel();
    final session = editor.session;
    if (session is! LoggedWorkbookSession) return;
    // A timer only marks that a check is pending (dispose cancels it).
    _settle = Timer(const Duration(days: 1), () {});
    unawaited(() async {
      try {
        await session.whenSynced(timeout: const Duration(seconds: 90));
      } catch (_) {
        // Check what arrived anyway.
      }
      if (_disposed || _offline || !(_settle?.isActive ?? false)) return;
      _settle?.cancel();
      if (!_disposed) await check();
    }());
  }

  Future<List<RevOpMeta>> _logs() async {
    final f = changeLogs;
    if (f != null) return f();
    final session = editor.session;
    if (session is! LoggedWorkbookSession) return const [];
    return session.recentOps(const Duration(days: 30));
  }

  /// Compares the cells written offline with the merged model and records
  /// the conflicts; shows the toasts. Returns the new conflicts.
  Future<List<LocalConflict>> check() async {
    if (_cells.isEmpty && _sorts.isEmpty) return const [];
    final me = editor.session.userId;
    List<RevOpMeta> logs;
    try {
      logs = await _logs();
    } catch (e) {
      debugPrint('Reading the change log failed: $e');
      logs = const [];
    }
    logs = [...logs]..sort((a, b) => b.revision.compareTo(a.revision));
    final model = editor.model;
    final found = <LocalConflict>[];
    final now = clock.now().toUtc();
    var n = 0;
    for (final e in _cells.entries) {
      final x = e.value;
      final sheet = model.sheet(x.sheetId);
      final row = sheet?.rows.indexOf(x.rowId) ?? -1;
      final col = sheet?.columns.indexOf(x.colId) ?? -1;
      LocalConflictKind kind;
      String? theirs;
      RevOpMeta? by;
      if (sheet == null || row < 0 || col < 0) {
        kind = sheet == null
            ? LocalConflictKind.sheetDeleted
            : row < 0
            ? LocalConflictKind.rowDeleted
            : LocalConflictKind.columnDeleted;
        final listKey = switch (kind) {
          LocalConflictKind.sheetDeleted => 'sheets',
          LocalConflictKind.rowDeleted => 'rows',
          _ => 'cols',
        };
        final id = switch (kind) {
          LocalConflictKind.sheetDeleted => x.sheetId,
          LocalConflictKind.rowDeleted => x.rowId,
          _ => x.colId,
        };
        by = _firstWhere(logs, (l) {
          final s = _summary(l);
          return (s?.deleted[listKey] ?? const []).contains(id);
        });
        if (by != null && by.authorUuid == me) continue;
      } else {
        theirs = sheet.cellAt(row, col)?.content;
        if (theirs == x.content) continue;
        kind = LocalConflictKind.overwritten;
        by = _firstWhere(logs, (l) => _wrote(l, x.sheetId, x.rowId, x.colId));
        if (by != null && by.authorUuid == me) continue;
      }
      final label = sheet == null || row < 0 || col < 0
          ? null
          : '${sheet.name}!${CellPos(row, col).a1}';
      found.add(
        LocalConflict(
          id: '${e.key}-${now.microsecondsSinceEpoch}-${n++}',
          kind: kind,
          sheetId: x.sheetId,
          rowId: x.rowId,
          colId: x.colId,
          myValue: x.content,
          theirValue: theirs,
          theirUserId: by?.authorUuid,
          theirName: by == null ? null : nameOf(by.authorUuid ?? ''),
          changeLogId: by == null ? null : '${by.revision}',
          label: label,
          detectedAt: now,
        ),
      );
    }
    // Sorts: most rows no longer carry our keys → a newer sort won.
    String? sortWinner;
    var sortReplaced = false;
    for (final e in _sorts.entries) {
      final sheet = model.sheet(e.key);
      if (sheet == null) continue;
      var differ = 0;
      var known = 0;
      for (final r in e.value.entries) {
        final key = sheet.rows.sortKeyOf(r.key);
        if (key == null) continue;
        known++;
        if (key != r.value) differ++;
      }
      if (known == 0 || differ * 2 < known) continue;
      // Sorts are labeled "Sort range" / "Sort sheet" (kinds: values).
      bool onSheet(RevOpMeta l) {
        if (l.authorUuid == me) return false;
        final s = _summary(l);
        return s != null && s.sheets.contains(e.key);
      }

      final by =
          _firstWhere(
            logs,
            (l) => onSheet(l) && l.label.toLowerCase().contains('sort'),
          ) ??
          _firstWhere(logs, onSheet);
      if (by == null) continue;
      sortReplaced = true;
      sortWinner = nameOf(by.authorUuid ?? '');
    }
    lastSortReplacedBy = sortReplaced ? sortWinner : null;
    _cells.clear();
    _sorts.clear();
    await _persist();
    if (found.isNotEmpty) {
      _all = [..._all, ...found];
      await _saveConflicts();
    }
    if (_disposed) return found;
    notifyListeners();
    _toast(found, sortReplaced ? sortWinner : null);
    return found;
  }

  static RevOpMeta? _firstWhere(List<RevOpMeta> l, bool Function(RevOpMeta) f) {
    for (final x in l) {
      if (f(x)) return x;
    }
    return null;
  }

  static ChangeSummary? _summary(RevOpMeta l) {
    final s = l.summary;
    if (s == null) return null;
    try {
      return ChangeSummary.fromJson(s);
    } catch (_) {
      return null;
    }
  }

  /// Whether [l] wrote the cell (its details, else its ranges).
  bool _wrote(RevOpMeta l, String sheetId, String rowId, String colId) {
    final cells = l.detail?['cells'];
    if (cells is List) {
      return cells.any(
        (c) =>
            c is Map && c['s'] == sheetId && c['r'] == rowId && c['c'] == colId,
      );
    }
    final s = _summary(l);
    if (s == null) return false;
    final sheet = editor.model.sheet(sheetId);
    if (sheet == null) return false;
    final row = sheet.rows.indexOf(rowId);
    final col = sheet.columns.indexOf(colId);
    for (final r in s.ranges) {
      if (r['s'] != sheetId) continue;
      int span(String? a, String? b, AxisIndex axis, int i) {
        final x = a == null ? 0 : axis.indexOf(a);
        final y = b == null ? axis.length - 1 : axis.indexOf(b);
        if (x < 0 || y < 0) return -1;
        return i >= (x < y ? x : y) && i <= (x < y ? y : x) ? 1 : 0;
      }

      if (span(r['r1'] as String?, r['r2'] as String?, sheet.rows, row) == 1 &&
          span(r['c1'] as String?, r['c2'] as String?, sheet.columns, col) ==
              1) {
        return true;
      }
    }
    return false;
  }

  /// The display name of an auth user uuid (collaborators present, me).
  String nameOf(String userUuid) {
    final me = services.me;
    if (me != null && me.uuid.uuid == userUuid) return me.displayName;
    return names?.call(userUuid) ?? editor.l10n.someone;
  }

  void _toast(List<LocalConflict> found, String? sortWinner) {
    final l = editor.l10n;
    if (sortWinner != null) {
      services.toasts.show(l.toastSortReplaced(sortWinner));
    }
    if (found.isEmpty) return;
    final who = {for (final c in found) c.theirName ?? l.someone};
    services.toasts.show(
      l.toastConflicts(
        found.length,
        who.length == 1 ? who.single : l.conflictsSeveralPeople,
      ),
      actionLabel: l.conflictsReview,
      onAction: () =>
          unawaited(editor.invokeCommand('sheets.conflicts.review')),
    );
  }

  // ------------------------------------------------------------- actions

  /// Marks [ids] (all open conflicts when null) as dismissed.
  Future<void> dismiss([Iterable<String>? ids]) async {
    final set = ids?.toSet();
    _all = [
      for (final c in _all)
        if (set == null || set.contains(c.id)) c.dismiss() else c,
    ];
    await _saveConflicts();
    if (!_disposed) notifyListeners();
  }

  /// The conflicts with [ids] that can be applied.
  List<LocalConflict> byIds(Iterable<String> ids) {
    final set = ids.toSet();
    return [
      for (final c in open)
        if (set.contains(c.id)) c,
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    _save?.cancel();
    _settle?.cancel();
    editor.applyListeners.remove(_onApply);
    editor.model.removeListener(_onBatch);
    services.connectivity.removeListener(_onConnectivity);
    super.dispose();
  }
}
