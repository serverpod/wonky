import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show AccessRole, UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/apply.dart' show RevRejectReason;
import 'package:wonky_revlog/rows.dart' show CurrentRowReader, RowChange, RowOp;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';
import 'package:wonky_slides_core/interfaces.dart' show SlideImageResolver;
import 'package:wonky_slides_core/maintenance.dart' show DeckMaintenance;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;

import '../model/deck_session.dart';
import '../model/memory_deck_session.dart';

/// The user-facing messages of a [LoggedDeckSession]'s load states
/// (localized by `openDeckSession` from the Slides ARB files; English
/// defaults for tests).
@immutable
class DeckLoadStrings {
  const DeckLoadStrings({
    this.downloading = 'Downloading presentation…',
    this.notAvailableOffline = 'This presentation isn’t available offline.',
    this.noAccess = 'You don’t have access to this presentation.',
    this.openFailed = 'This presentation could not be opened.',
    this.accessRemoved = 'You no longer have access to this presentation.',
    this.stillOpening = 'The presentation is still opening.',
  });

  /// [DeckLoading] message while the deck loads from the server.
  final String downloading;
  final String notAvailableOffline;
  final String noAccess;
  final String openFailed;
  final String accessRemoved;

  /// `PlanException` message for writes before the deck is ready.
  final String stillOpening;
}

/// A [DeckSession] on RevLog (RevLog spec 08 §2, 06 §1.2): the model holds
/// the server state (cached on the device, or loaded with one structure
/// page — decks are small) with this tab's unacknowledged changes on top;
/// writes go into the outbox and are sent as ops; remote ops arrive in
/// revision order as remote batches.
///
/// Maintenance: [DeckMaintenance] repairs (Slides 02 §10) are written by
/// editors one second after remote batches and after ready
/// ([runMaintenance]), as a `"repair": true` op that is not undoable.
class LoggedDeckSession extends DeckSessionBase {
  LoggedDeckSession._(
    this.client, {
    required super.itemUuid,
    required super.userId,
    required super.model,
    required super.planner,
    required this.fileUuid,
    required this.strings,
    super.role,
    super.images,
  });

  /// Opens the deck [fileUuid] of drive item [itemUuid]. Returns at once;
  /// follow [loadState] (or await [opened]).
  static LoggedDeckSession open(
    RevLogClient client, {
    required UuidValue itemUuid,
    required UuidValue fileUuid,
    required String userId,
    required SlidesMutationPlanner planner,
    Role role = Role.viewer,
    SlideImageResolver? images,
    DeckLoadStrings strings = const DeckLoadStrings(),
    Duration maintenanceDelay = const Duration(seconds: 1),
  }) {
    final s = LoggedDeckSession._(
      client,
      itemUuid: itemUuid,
      userId: userId,
      model: DeckModel(deckId: fileUuid.uuid),
      planner: planner,
      fileUuid: fileUuid,
      strings: strings,
      role: role,
      images: images,
    ).._maintenanceDelay = maintenanceDelay;
    s.loadStateNotifier.value = DeckLoading(message: strings.downloading);
    s._opened = s._open();
    return s;
  }

  final RevLogClient client;

  /// The deck (= file uuid = deck row id).
  final UuidValue fileUuid;

  /// Load-state messages.
  final DeckLoadStrings strings;

  late final RevFileSync sync;
  late Duration _maintenanceDelay;
  Timer? _maintenanceTimer;
  Future<void> _opened = Future.value();
  bool _disposed = false;
  final List<FutureOr<void> Function()> _onDispose = [];
  final _rejected = StreamController<RevGroupRejection>.broadcast();
  final Expando<String> _groups = Expando('revGroup');

  /// Repairs written by [runMaintenance] (tests, diagnostics).
  int repairs = 0;

  /// Completes when the open attempt finished.
  Future<void> get opened => _opened;

  bool get isDisposed => _disposed;

  bool get _ready => loadStateNotifier.value is DeckReady;

  // ------------------------------------------------------------------ open

  Future<void> _open() async {
    sync = client.openFile(
      fileUuid.uuid,
      port: _Port(this),
      plan: _DeckPlan(this),
    );
    sync.status.addListener(_onStatus);
    sync.role.addListener(_onRole);
    sync.fatal.addListener(_onFatal);
    sync.rejections.listen(_onRejected);
    sync.history.listen(_onOp);
    try {
      final loaded = await sync.open();
      if (_disposed) return;
      if (loaded && model.deck != null) {
        _setReady();
      } else if (!client.keeper.online) {
        loadStateNotifier.value = DeckUnavailable(
          strings.notAvailableOffline,
          offline: true,
        );
      }
    } catch (e, st) {
      debugPrint('Opening presentation $fileUuid failed: $e\n$st');
      if (!_disposed) {
        loadStateNotifier.value = DeckUnavailable(strings.openFailed);
      }
    }
    _onStatus();
  }

  void _setUnavailable(String reason) {
    if (!_disposed) loadStateNotifier.value = DeckUnavailable(reason);
  }

  void _setReady() {
    if (_disposed || _ready) return;
    loadStateNotifier.value = const DeckReady();
    _scheduleMaintenance();
  }

  void _onStatus() {
    if (_disposed) return;
    syncStatusNotifier.value = sync.status.value;
    final state = loadStateNotifier.value;
    if (state is DeckUnavailable &&
        state.offline &&
        client.keeper.online &&
        model.deck == null) {
      loadStateNotifier.value = DeckLoading(message: strings.downloading);
    }
  }

  void _onRole() {
    final r = sync.role.value;
    if (r != null && !_disposed) roleValue = _roleOf(r);
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
    loadStateNotifier.value = DeckUnavailable(
      model.deck == null ? strings.noAccess : strings.accessRemoved,
    );
  }

  void _onRejected(RevGroupRejection r) {
    if (_disposed) return;
    _rejected.add(r);
    if (r.rejection.reason == RevRejectReason.forbiddenForRole) {
      roleValue = Role.viewer;
    }
  }

  /// Whether another connection's op group is half applied (its last op
  /// hasn't arrived): repairs wait for it (06 §1.2).
  bool _remoteGroupOpen = false;

  void _onOp(RevOpMeta op) {
    if (op.sessionId == 'tab:${sync.tabId}') return;
    _remoteGroupOpen = op.groupId != null && !op.groupLast;
  }

  /// Rejected groups (the editor shows the message, 06 §4.6).
  Stream<RevGroupRejection> get groupRejected => _rejected.stream;

  /// Op metadata of every op this session applies (06 §1.2).
  Stream<RevOpMeta> get history => sync.history;

  /// Outcomes of this tab's acked ops (06 §6).
  Stream<RevOutcome> get outcomes => sync.outcomes;

  /// Recent op metadata of the deck (30 days, 06 §3.3).
  Future<List<RevOpMeta>> recentOps(Duration window) => client.store.recentOps(
    fileUuid.uuid,
    DateTime.now().toUtc().subtract(window),
  );

  /// Changes of this tab not acknowledged by the server.
  int get pendingChanges => sync.core.pendingChanges;

  /// Completes when every change is acknowledged.
  Future<void> whenSynced({Duration? timeout}) =>
      sync.whenSynced(timeout: timeout);

  /// The op group [plan] was sent in (a rejection of the group removes the
  /// plan's undo step, 06 §4.6).
  @override
  String? groupOf(SlidesPlan plan) => _groups[plan];

  /// Runs [callback] when the session is disposed.
  void addDisposeCallback(FutureOr<void> Function() callback) =>
      _onDispose.add(callback);

  /// Applies a role learned elsewhere (drive item, sharing dialog).
  void updateRole(Role value) {
    if (!_disposed) roleValue = value;
  }

  /// Retries the connection now.
  void retry() => sync.retry();

  // ---------------------------------------------------------- maintenance

  /// Concurrent edits can leave a deck violating an invariant (02 §10:
  /// orphan slides, duplicate or dangling placeholders, group cycles, …).
  /// Editors repair them [_maintenanceDelay] (1 s) after the last remote
  /// batch; every rule is deterministic, so concurrent repairs converge.
  void _scheduleMaintenance() {
    if (_disposed) return;
    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer(_maintenanceDelay, () => runMaintenance());
  }

  /// Writes `DeckMaintenance.repairOp` ("Repair presentation") when the
  /// deck violates an invariant and the user can edit. Not undoable (the
  /// plan is not pushed on the undo stack). Returns the plan, or null.
  SlidesPlan? runMaintenance() {
    if (_disposed || !_ready || !canEdit) return null;
    // Only on a settled deck (06 §1.2): a half-applied remote group or our
    // own unacknowledged changes can look like violations that the rest of
    // the group (or the server's answer) resolves.
    if (_remoteGroupOpen || sync.core.pendingChanges > 0) {
      _scheduleMaintenance();
      return null;
    }
    final op = DeckMaintenance.repairOp(model);
    if (op == null) return null;
    try {
      final plan = execute(op);
      if (!plan.isEmpty) repairs++;
      return plan;
    } on PlanException catch (e) {
      debugPrint('Repairing presentation $fileUuid failed: $e');
      return null;
    }
  }

  // --------------------------------------------------------------- writes

  /// Refuses writes while the deck is opening (the model is incomplete)
  /// and, through the base class, writes of viewers and commenters.
  @override
  void checkPlan(SlidesOperation op, SlidesPlan plan) {
    if (!_ready) {
      throw PlanException(PlanException.locked, strings.stillOpening);
    }
    super.checkPlan(op, plan);
  }

  @override
  void beforeApply(List<RowChange> changes) => sync.beforeLocal(changes);

  @override
  void persist(
    List<RowChange> changes, {
    SlidesPlan? plan,
    required String label,
    required String actorKind,
  }) {
    if (_disposed || changes.isEmpty) return;
    // Without a plan (undo/redo, AI, recovery) inserts re-create rows that
    // existed before, so they count as revived (comment threads come back).
    final summary =
        plan?.summary ??
        SlidesChangeSummary.of(changes, wasDeleted: (_, _) => true);
    final ops = sync.submit(
      changes,
      label: label,
      actorKind: actorKind,
      summary: summary.toJson(),
      detail: plan?.detail,
    );
    if (plan != null && ops.isNotEmpty) {
      _groups[plan] = ops.first.groupId ?? ops.first.clientOpId;
    }
  }

  @override
  Future<void> flush() => sync.whenStored();

  // -------------------------------------------------------------- dispose

  Future<void>? _disposing;

  @override
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    _maintenanceTimer?.cancel();
    await _opened.catchError((Object _) {});
    await flush();
    _disposed = true;
    _maintenanceTimer?.cancel();
    for (final c in _onDispose) {
      await c();
    }
    sync.status.removeListener(_onStatus);
    sync.role.removeListener(_onRole);
    sync.fatal.removeListener(_onFatal);
    await client.closeFile(fileUuid.uuid, sync);
    await _rejected.close();
    await super.dispose();
  }
}

/// The model port of a [LoggedDeckSession].
final class _Port implements RevModelPort {
  _Port(this.s);

  final LoggedDeckSession s;

  @override
  CurrentRowReader get reader => s.model;

  @override
  void apply(List<RowChange> changes, {required bool remote}) {
    if (s._disposed || changes.isEmpty) return;
    if (remote) {
      s.applyRemote(changes);
      if (s._ready) s._scheduleMaintenance();
    } else {
      s.model.applyChanges(changes, origin: DeckChangeOrigin.load);
    }
    if (!s._ready && s.model.deck != null && !s.sync.bootstrapping) {
      // Created elsewhere: the first ops arrived (06 §5.1).
      s._setReady();
    }
  }

  @override
  void reset() {
    final dump = s.model.dump();
    final order = SlidesTables.dependencyOrder.reversed.toList();
    final tables = dump.keys.toList()
      ..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    s.model.applyChanges([
      for (final t in tables)
        for (final id in dump[t]!.keys)
          RowChange(table: t, rowId: id, op: RowOp.delete),
    ], origin: DeckChangeOrigin.load);
  }
}

/// Decks load in one structure page (no cell coverage, 08 §2).
final class _DeckPlan implements RevBootstrapPlan {
  _DeckPlan(this.s);

  final LoggedDeckSession s;

  @override
  void structureLoaded(List<(String, Map<String, Object?>)> structure) {}

  @override
  (String, List<String>)? nextCells() => null;

  @override
  void cellsLoaded(String scope, List<String> rowKeys) {}

  @override
  void ready() {
    if (s.model.deck != null) {
      s._setReady();
    } else {
      s._setUnavailable(s.strings.noAccess);
    }
  }

  @override
  void complete() {}
}
