import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show AccessRole, UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/apply.dart' show RevRejectReason;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart' show SyncStatus;

import '../model/loading_gate.dart';
import '../model/memory_workbook_session.dart';
import '../model/row_loading.dart';
import '../model/workbook_session.dart';

/// Where the user looks first (restored view state, `?gid=`): those rows
/// load before [WorkbookReady].
class ViewportHint {
  const ViewportHint({this.sheetId, this.topRow = 0});

  final String? sheetId;
  final int topRow;
}

/// A [WorkbookSession] on RevLog (RevLog spec 06 §1.1): the model holds
/// the server state (cached locally, or loaded page by page) with this
/// tab's unacknowledged changes on top; writes go into the outbox and are
/// sent as ops; remote ops arrive in revision order.
class LoggedWorkbookSession extends WorkbookSessionBase {
  LoggedWorkbookSession._(
    this.client, {
    required super.itemUuid,
    required super.userId,
    required super.model,
    required this.fileUuid,
    super.role,
    super.maxCells,
    this.viewportHint,
  });

  /// Opens the spreadsheet [fileUuid] of drive item [itemUuid]. Returns at
  /// once; follow [loadState].
  static LoggedWorkbookSession open(
    RevLogClient client, {
    required UuidValue itemUuid,
    required UuidValue fileUuid,
    required String userId,
    Role role = Role.viewer,
    int maxCells = 1000000,
    ViewportHint? viewport,
    Duration maintenanceDelay = const Duration(seconds: 1),
  }) {
    final s = LoggedWorkbookSession._(
      client,
      itemUuid: itemUuid,
      userId: userId,
      model: WorkbookModel(spreadsheetId: fileUuid.uuid),
      fileUuid: fileUuid,
      role: role,
      maxCells: maxCells,
      viewportHint: viewport,
    );
    s._maintenanceDelay = maintenanceDelay;
    s._opened = s._open();
    return s;
  }

  final RevLogClient client;

  /// The spreadsheet (= file uuid = root row id).
  final UuidValue fileUuid;

  /// The first rows to load (settable until the structure is loaded:
  /// `?gid=`).
  ViewportHint? viewportHint;

  late final RevFileSync sync;
  late final _SheetsPlan _plan = _SheetsPlan(this);
  Future<void> _opened = Future.value();
  bool _disposed = false;
  final List<FutureOr<void> Function()> _onDispose = [];

  /// Files with at most this many rows load completely before ready.
  static const smallFileRows = 2000;

  /// Rows per sheet loaded before ready.
  static const viewportRows = 200;

  final RowLoadTracker _rows = RowLoadTracker();
  bool _rowsComplete = true;

  @override
  WorkbookRowLoading get rowLoading =>
      _rowsComplete ? WorkbookRowLoading.loaded : _rows;

  /// Completes when the open attempt finished.
  Future<void> get opened => _opened;

  /// Whether [dispose] ran.
  bool get isDisposed => _disposed;

  Future<void> _open() async {
    sync = client.openFile(fileUuid.uuid, port: _Port(this), plan: _plan);
    sync.status.addListener(_onStatus);
    sync.role.addListener(_onRole);
    sync.fatal.addListener(_onFatal);
    sync.rejections.listen(_onRejected);
    sync.history.listen(_onOp);
    final loaded = await sync.open();
    if (_disposed) return;
    // A cache reopened viewport-first turns ready through the plan (small
    // files once every row is loaded).
    if (loaded && model.sheets.isNotEmpty && !sync.bootstrapping) {
      _setLoad(const WorkbookReady());
    } else if (!client.keeper.online) {
      // The screen shows the localized offline title and hint.
      loadStateNotifier.value = const WorkbookUnavailable('', offline: true);
    }
    _onStatus();
  }

  void _onStatus() {
    if (_disposed) return;
    syncStatusNotifier.value = sync.status.value;
    final state = loadStateNotifier.value;
    if (state is WorkbookUnavailable &&
        state.offline &&
        client.keeper.online &&
        model.sheets.isEmpty) {
      loadStateNotifier.value = const WorkbookLoading();
    }
  }

  void _onRole() {
    final r = sync.role.value;
    if (r != null) roleValue = _roleOf(r);
  }

  static Role _roleOf(AccessRole r) => switch (r) {
    AccessRole.owner => Role.owner,
    AccessRole.editor => Role.editor,
    AccessRole.commenter => Role.commenter,
    AccessRole.viewer => Role.viewer,
  };

  void _onFatal() {
    final f = sync.fatal.value;
    if (f == null || _disposed) return;
    if (model.sheets.isEmpty) {
      loadStateNotifier.value = WorkbookUnavailable(f.message);
    } else {
      roleValue = Role.viewer;
    }
  }

  void _onRejected(RevGroupRejection r) {
    _rejected.add(r);
    if (r.rejection.reason == RevRejectReason.forbiddenForRole) {
      roleValue = Role.viewer;
    }
  }

  final _rejected = StreamController<RevGroupRejection>.broadcast();

  // ---------------------------------------------------------- maintenance

  late Duration _maintenanceDelay;
  Timer? _maintenanceTimer;

  /// Repairs written by [runMaintenance] (tests, diagnostics).
  int repairs = 0;

  /// Whether another connection's op group is half applied (its last op
  /// hasn't arrived): repairs wait for it (RevLog spec 06 §1.2).
  bool _remoteGroupOpen = false;

  void _onOp(RevOpMeta op) {
    if (op.sessionId == 'tab:${sync.tabId}') return;
    _remoteGroupOpen = op.groupId != null && !op.groupLast;
  }

  /// Concurrent edits can leave a spreadsheet violating an invariant
  /// (Sheets 02 §8: overlapping merges, frozen counts beyond the grid,
  /// dangling filters and pivot anchors, duplicate names). Editors repair
  /// them [_maintenanceDelay] after the last remote batch; the repairs are
  /// deterministic, so concurrent fixers converge.
  void _scheduleMaintenance() {
    if (_disposed) return;
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer(_maintenanceDelay, () => runMaintenance());
  }

  /// Writes the `WorkbookMaintenance` repairs ("Repair spreadsheet", a
  /// `"repair": true` op that is not undoable) when the spreadsheet is
  /// settled: every row loaded, no remote group half applied and this
  /// tab's outbox empty (06 §1.2). Returns the plan, or null.
  MutationPlan? runMaintenance() {
    if (_disposed || !_isReady || role.value < Role.editor) return null;
    if (!rowLoading.complete ||
        _remoteGroupOpen ||
        sync.core.pendingChanges > 0) {
      _scheduleMaintenance();
      return null;
    }
    final plan = WorkbookMaintenance.plan(model, planContext());
    if (plan.isEmpty) return null;
    beforeApply(plan.changes);
    model.applyPlan(plan);
    sync.submit(
      plan.changes,
      label: plan.label,
      summary: {...plan.summary.toJson(), 'repair': true},
    );
    repairs++;
    return plan;
  }

  /// Rejected groups (the editor shows the message, 06 §4.6).
  Stream<RevGroupRejection> get groupRejected => _rejected.stream;

  /// Op metadata of every op this session applies (06 §1.1).
  Stream<RevOpMeta> get history => sync.history;

  /// Outcomes of this tab's acked ops (06 §6).
  Stream<RevOutcome> get outcomes => sync.outcomes;

  /// Recent op metadata of the file (30 days, 06 §3.3).
  Future<List<RevOpMeta>> recentOps(Duration window) => client.store.recentOps(
    fileUuid.uuid,
    DateTime.now().toUtc().subtract(window),
  );

  /// Changes of this tab not acknowledged by the server.
  int get pendingChanges => sync.core.pendingChanges;

  /// Completes when every change is acknowledged (06 §1.1).
  Future<void> whenSynced({Duration? timeout}) =>
      sync.whenSynced(timeout: timeout);

  /// Called on dispose (drive watch subscriptions).
  void addDisposeCallback(FutureOr<void> Function() callback) =>
      _onDispose.add(callback);

  /// The role from the drive watch (sharing changes).
  void updateRole(Role value) {
    if (_disposed) return;
    roleValue = value;
  }

  /// Retries the connection now.
  void retry() => sync.retry();

  void _emit(WorkbookChangeBatch batch) {
    if (!batch.isEmpty && !remoteController.isClosed) {
      remoteController.add(batch);
    }
  }

  bool get _isReady => loadStateNotifier.value is WorkbookReady;

  void _setLoad(WorkbookLoadState state) {
    if (_disposed) return;
    loadStateNotifier.value = state;
    if (state is WorkbookReady) _scheduleMaintenance();
  }

  // -------------------------------------------------------------- writes

  @override
  void beforeApply(List<RowChange> changes) => sync.beforeLocal(changes);

  @override
  void checkPlan(SheetsOperation op, MutationPlan plan) =>
      LoadingGate.check(op, plan, model, rowLoading);

  @override
  void persist(
    List<RowChange> changes, {
    MutationPlan? plan,
    required String label,
    required String actorKind,
  }) {
    final ops = sync.submit(
      changes,
      label: label,
      actorKind: actorKind,
      summary: (plan?.summary ?? ChangeSummary.ofChanges(changes)).toJson(),
      detail: plan?.detail,
    );
    if (plan != null && ops.isNotEmpty) {
      _groups[plan] = ops.first.groupId ?? ops.first.clientOpId;
    }
  }

  final Expando<String> _groups = Expando('revGroup');

  /// The op group [plan] was sent in (a rejection of the group removes the
  /// plan's undo step, 06 §4.6).
  @override
  String? groupOf(MutationPlan plan) => _groups[plan];

  @override
  Future<void> flush() => sync.whenStored();

  @override
  ValueListenable<SyncStatus> get syncStatus => syncStatusNotifier;

  // -------------------------------------------------------------- dispose

  Future<void>? _disposing;

  @override
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    _maintenanceTimer?.cancel();
    for (final c in _onDispose) {
      await c();
    }
    await _opened.catchError((Object _) {});
    sync.status.removeListener(_onStatus);
    sync.role.removeListener(_onRole);
    sync.fatal.removeListener(_onFatal);
    await client.closeFile(fileUuid.uuid, sync);
    await _rejected.close();
    _rows.dispose();
    await super.dispose();
  }
}

/// The model port of a [LoggedWorkbookSession].
final class _Port implements RevModelPort {
  _Port(this.s);

  final LoggedWorkbookSession s;

  @override
  CurrentRowReader get reader => s.model;

  @override
  void apply(List<RowChange> changes, {required bool remote}) {
    if (s._disposed || changes.isEmpty) return;
    final batch = s.model.applyChanges(changes);
    s._emit(batch);
    if (remote && s._isReady) s._scheduleMaintenance();
    if (!s._isReady && s.model.sheets.isNotEmpty && !s.sync.bootstrapping) {
      // Created elsewhere: the first ops arrived (06 §5.1).
      s._setLoad(const WorkbookReady());
    }
  }

  @override
  void reset() {
    final rows = s.model.allRows().toList();
    final order = SheetsTables.dependencyOrder.reversed.toList();
    rows.sort((a, b) => order.indexOf(a.$1).compareTo(order.indexOf(b.$1)));
    s.model.applyChanges([
      for (final (t, r) in rows)
        RowChange(table: t, rowId: '${r[Cols.id]}', op: RowOp.delete),
    ]);
  }
}

/// Viewport-first cell loading (06 §5.2, Sheets 02 §6).
final class _SheetsPlan implements RevBootstrapPlan {
  _SheetsPlan(this.s);

  final LoggedWorkbookSession s;
  bool _small = false;
  bool _viewportDone = false;
  List<String> _order = const [];

  /// Per sheet: rows handed out (loaded or loading; a loader may run
  /// several blocks at once, so a row is handed out once) and the index
  /// the sheet's walk in row order continues from.
  final Map<String, Set<String>> _handed = {};
  final Map<String, int> _cursor = {};

  Set<String> _handedOf(String sheetId) => _handed[sheetId] ??= {};

  RowLoadTracker get _rows => s._rows;

  @override
  void structureLoaded(List<(String, Map<String, Object?>)> structure) {
    s._rowsComplete = false;
    final sheets = s.model.sheets;
    var total = 0;
    for (final sheet in sheets) {
      _rows.track(sheet.id, sheet.rows.ids);
      total += sheet.rows.length;
    }
    _small = total <= LoggedWorkbookSession.smallFileRows;
    _handed.clear();
    _cursor.clear();
    final first = _viewportSheet();
    _order = [?first?.id, for (final sheet in sheets) sheet.id];
    if (!s._isReady) {
      s._setLoad(const WorkbookLoading());
    }
  }

  SheetModel? _viewportSheet() {
    final hinted = s.viewportHint?.sheetId;
    final sheet = hinted == null ? null : s.model.sheet(hinted);
    if (sheet != null) return sheet;
    final visible = s.model.visibleSheets;
    if (visible.isNotEmpty) return visible.first;
    return s.model.sheets.firstOrNull;
  }

  @override
  (String, List<String>)? nextCells() {
    if (!_viewportDone) {
      _viewportDone = true;
      final sheet = _viewportSheet();
      if (sheet != null) {
        final ids = _viewportRows(sheet);
        _handedOf(sheet.id).addAll(ids);
        if (ids.isNotEmpty) return (sheet.id, ids);
      }
    }
    while (true) {
      final req = _rows.takeRequest();
      if (req == null) break;
      final (sheetId, first, last) = req;
      final sheet = s.model.sheet(sheetId);
      if (sheet == null || _rows.isSheetLoaded(sheetId)) continue;
      final n = sheet.rows.length;
      final handed = _handedOf(sheetId);
      final ids = <String>[];
      for (
        var r = (first - 50).clamp(0, n);
        r < n && r <= last + 50 && ids.length < 500;
        r++
      ) {
        final id = sheet.rows.idAt(r);
        if (!_rows.isRowLoaded(sheetId, id) && handed.add(id)) ids.add(id);
      }
      if (ids.isNotEmpty) return (sheetId, ids);
    }
    // The sheets in order, each walked once in row order (O(rows) for the
    // whole load, not per block).
    for (final sheetId in _order) {
      if (_rows.isSheetLoaded(sheetId)) continue;
      final sheet = s.model.sheet(sheetId);
      final handed = _handedOf(sheetId);
      final ids = <String>[];
      if (sheet != null) {
        final n = sheet.rows.length;
        var i = _cursor[sheetId] ?? 0;
        while (i < n && ids.length < 500) {
          final id = sheet.rows.idAt(i++);
          if (!_rows.isRowLoaded(sheetId, id) && handed.add(id)) ids.add(id);
        }
        _cursor[sheetId] = i;
      }
      if (ids.isNotEmpty) return (sheetId, ids);
      // Walked to the end: missing rows not handed out moved behind the
      // walk (sorts, moves) or are gone (deleted meanwhile).
      final rest = [
        for (final id in _rows.missingOf(sheetId))
          if (!handed.contains(id)) id,
      ];
      final present = [
        if (sheet != null)
          for (final id in rest)
            if (sheet.rows.contains(id)) id,
      ];
      final keep = present.toSet();
      _rows.markLoaded(sheetId, rest.where((id) => !keep.contains(id)));

      if (present.isNotEmpty) {
        final block = present.take(500).toList();
        handed.addAll(block);
        return (sheetId, block);
      }
      // What is left is loading (handed out to a block in flight).
    }
    return null;
  }

  List<String> _viewportRows(SheetModel sheet) {
    final n = sheet.rows.length;
    final frozen = (sheet.record?.frozenRows ?? 0).clamp(0, n);
    final hint = s.viewportHint;
    final top = hint != null && hint.sheetId == sheet.id
        ? hint.topRow.clamp(0, n)
        : 0;
    final from = (top - 20).clamp(0, n);
    final to = (top + LoggedWorkbookSession.viewportRows).clamp(0, n);
    return [
      for (var r = 0; r < frozen; r++) sheet.rows.idAt(r),
      for (var r = from < frozen ? frozen : from; r < to; r++)
        sheet.rows.idAt(r),
    ];
  }

  @override
  void cellsLoaded(String scope, List<String> rowKeys) {
    _rows.markLoaded(scope, rowKeys);
    _rows.changed();
  }

  @override
  void ready() {
    if (_small) return;
    if (!s._isReady) {
      s._setLoad(const WorkbookReady());
    }
  }

  @override
  void complete() {
    _rows.finish();
    s._rowsComplete = true;
    if (!s._isReady) {
      s._setLoad(const WorkbookReady());
    }
  }
}
