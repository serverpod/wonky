import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides_core/interfaces.dart' show SlideImageResolver;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_revlog/rows.dart' show CurrentRowReader, RowChange;
import 'package:wonky_revlog/undo.dart' show RowsUndoTarget;
import 'package:wonky_ui/wonky_ui.dart' show SyncStatus;

/// Loading state of a [DeckSession] (suite 12 §2.3: "Downloading
/// presentation… 42%").
@immutable
sealed class DeckLoadState {
  const DeckLoadState();
}

/// The deck is being opened or downloaded; [progress] is 0..1 when known.
final class DeckLoading extends DeckLoadState {
  const DeckLoading({this.progress, this.message});

  final double? progress;
  final String? message;
}

/// The model is usable (and editable subject to [DeckSession.canEdit]).
final class DeckReady extends DeckLoadState {
  const DeckReady();
}

/// The deck can't be shown: not on the device while offline, access
/// revoked, deleted…
final class DeckUnavailable extends DeckLoadState {
  const DeckUnavailable(this.reason, {this.offline = false});

  final String reason;

  /// True when the deck isn't on the device and the app is offline (it
  /// re-opens by itself when the connection returns).
  final bool offline;
}

/// One open deck: the in-memory [DeckModel] built from the replica and the
/// write path (Slides 02 §11–12, 12 §5.3). Mirrors Sheets'
/// `WorkbookSession`.
///
/// The contract between the data layer (`features/revlog`, `features/model`)
/// and everything above it (stage, canvas, commands, panels, MCP UI tools):
/// - [execute] plans an operation with the shared `SlidesMutationPlanner`,
///   applies the plan to [model] synchronously (the UI repaints at once) and
///   sends it as ops (RevLog outbox). It does not record undo: the editor controller
///   pushes a `slides.rows` step (`SlidesRowsUndoEntry`) with the plan.
/// - [applyChanges] persists already-computed changes (undo/redo, AI); the
///   session is the `RowsUndoTarget` of `SlidesRowsUndoHandler`.
/// - Remote changes (sync merges) are applied to [model] by the session and
///   arrive through `model.changes` like local ones; [remoteBatches]
///   carries only the remote ones.
///
/// Implementations: `LoggedDeckSession` (RevLog, `features/revlog`)
/// and [MemoryDeckSession] (tests, version views, previews, AI suggest
/// mode); both extend `DeckSessionBase`, which mixes in the core
/// `DeckWritePath`.
abstract class DeckSession implements RowsUndoTarget {
  /// The deck id (= sync space UUID = drive item UUID).
  String get deckId;

  /// The drive item.
  UuidValue get itemUuid;

  /// Acting user (auth user UUID string).
  String get userId;

  DeckModel get model;

  ValueListenable<DeckLoadState> get loadState;

  /// For the header's sync indicator.
  ValueListenable<SyncStatus> get syncStatus;

  /// The user's role on the deck (viewers/commenters can't edit).
  ValueListenable<Role> get role;

  bool get canEdit => role.value >= Role.editor;

  /// A planning context for operations built outside [execute] (previews).
  SlidesPlanContext planContext();

  /// Plans [op], applies it to [model] and persists it. Throws
  /// `PlanException` (nothing is applied then). Returns the plan (empty
  /// plans are not persisted).
  SlidesPlan execute(SlidesOperation op, {String actorKind = 'user'});

  /// Applies and persists precomputed [changes] (undo/redo).
  @override
  void applyChanges(
    List<RowChange> changes, {
    required String label,
    String actorKind = 'user',
  });

  @override
  CurrentRowReader get currentRows => model;

  /// Completes when everything applied so far is stored locally.
  Future<void> flush();

  /// The sync group [plan] was sent in (RevLog spec 06 §4.6); null when the
  /// session doesn't sync.
  String? groupOf(SlidesPlan plan) => null;

  /// Batches that came from other devices or the server.
  Stream<DeckChangeBatch> get remoteBatches;

  /// Image bytes/URLs: local bytes for pending uploads, signed URLs
  /// otherwise (cached).
  SlideImageResolver get images;

  /// Closes the session (flushes first).
  Future<void> dispose();
}
