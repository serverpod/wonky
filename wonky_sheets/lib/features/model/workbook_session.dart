import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart' show SyncStatus;

import 'row_loading.dart';

export 'row_loading.dart' show WorkbookRowLoading;

/// Loading state of a [WorkbookSession] (suite 12 §2.3: "Downloading
/// spreadsheet… 42%").
@immutable
sealed class WorkbookLoadState {
  const WorkbookLoadState();
}

/// The spreadsheet is being opened or downloaded. [progress] is 0..1 when
/// known.
final class WorkbookLoading extends WorkbookLoadState {
  const WorkbookLoading({this.progress, this.message});

  final double? progress;
  final String? message;
}

/// The model is usable and editable (subject to [WorkbookSession.canEdit]).
/// Big spreadsheets turn ready once the first visible window is in memory
/// and stream the remaining rows in afterwards
/// ([WorkbookSession.rowLoading]).
final class WorkbookReady extends WorkbookLoadState {
  const WorkbookReady();
}

/// The spreadsheet can't be shown: not on the device while offline, access
/// revoked, deleted …
final class WorkbookUnavailable extends WorkbookLoadState {
  const WorkbookUnavailable(this.reason, {this.offline = false});

  final String reason;

  /// True when the spreadsheet isn't on the device and the app is offline
  /// (it re-opens by itself when the connection returns).
  final bool offline;
}

/// One open spreadsheet: the in-memory [WorkbookModel] built from the local
/// replica, the formula engine bound to it, and the write path
/// (02 §6–7, 13 §4.1).
///
/// The contract between the data layer (`features/sync`, `features/model`)
/// and everything above it (grid, commands, panels, MCP UI tools):
/// - [execute] plans an operation with the shared `SheetsMutationPlanner`,
///   applies the plan to [model] synchronously (the UI repaints at once) and
///   persists it asynchronously (one writer transaction per ≤ 5,000 changes,
///   plus the `ChangeLog` row). It does not record undo: the editor
///   controller pushes a `sheets.rows` undo step with the returned plan.
/// - [applyChanges] persists already-computed changes (undo/redo, AI).
/// - Remote changes (sync merges) are applied to [model] by the session and
///   arrive through `model.changes` like local ones; [remoteBatches] carries
///   only the remote ones.
abstract class WorkbookSession {
  /// The spreadsheet id (= sync space UUID = drive item's `spaceUuid`).
  String get spreadsheetId;

  /// The drive item.
  UuidValue get itemUuid;

  /// Acting user (auth user UUID string).
  String get userId;

  WorkbookModel get model;

  /// The formula engine bound to [model].
  ModelEngineBinding get engine;

  ValueListenable<WorkbookLoadState> get loadState;

  /// Which rows are in memory after [WorkbookReady] (viewport-first
  /// loading, 02 §6). Complete for small spreadsheets and memory sessions.
  WorkbookRowLoading get rowLoading => WorkbookRowLoading.loaded;

  /// For the header's sync indicator.
  ValueListenable<SyncStatus> get syncStatus;

  /// The user's role on the spreadsheet (viewers/commenters can't edit).
  ValueListenable<Role> get role;

  bool get canEdit => role.value >= Role.editor;

  /// A planning context for [op]s built outside [execute] (previews).
  PlanContext planContext();

  /// Plans [op], applies it to [model] and persists it. Throws
  /// `PlanException` (nothing is applied then). Returns the plan (empty
  /// plans are not persisted).
  MutationPlan execute(SheetsOperation op, {String actorKind = 'user'});

  /// Applies and persists precomputed [changes] (undo/redo).
  void applyChanges(
    List<RowChange> changes, {
    required String label,
    String actorKind = 'user',
  });

  /// Completes when everything applied so far is stored locally.
  Future<void> flush();

  /// The sync group [plan] was sent in (RevLog spec 06 §4.6); null when the
  /// session doesn't sync.
  String? groupOf(MutationPlan plan) => null;

  /// Batches that came from other devices or the server.
  Stream<WorkbookChangeBatch> get remoteBatches;

  /// Closes the session (flushes first).
  Future<void> dispose();
}
