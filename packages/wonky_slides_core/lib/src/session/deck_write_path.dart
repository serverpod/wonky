import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/undo.dart' show RowsUndoTarget;
import 'package:wonky_sync_models/ids.dart' show IdGenerator, UuidV7IdGenerator;

import '../model/api/deck_model.dart';
import '../model/api/events.dart';
import '../ops/change_summary.dart';
import '../ops/operations.dart';
import '../ops/plan_context.dart';
import '../ops/planner.dart';

/// The write path shared by every deck session (12 §5.3): the app's
/// `DeckSessionBase` (memory and synced sessions), the pure-Dart
/// `MemoryDeck` and server-side sessions mix it in.
///
/// - [execute] plans an operation with [planner], applies the plan to
///   [model] synchronously (the UI repaints at once) and hands it to
///   [persist] (the synced session writes ≤ 5,000 changes per transaction
///   plus the `DeckChangeLog` row asynchronously). It does **not** record
///   undo: the editor pushes a `slides.rows` step with the returned plan.
/// - [applyChanges] applies and persists precomputed changes (undo/redo,
///   AI, recovery).
/// - [applyRemote] patches the model with changes from other devices or
///   the server (never persisted; emitted with `DeckChangeOrigin.remote`).
mixin DeckWritePath implements RowsUndoTarget {
  /// The deck model.
  DeckModel get model;

  /// Acting user (auth user UUID string).
  String get userId;

  /// The planner (SL-7's in the apps and on the server).
  SlidesMutationPlanner get planner;

  /// Limits for the planner (02 §13; `ProtocolInfo` config in the apps).
  SlidesLimits get limits => SlidesLimits.defaults;

  /// Generator of new row ids.
  IdGenerator get ids => const UuidV7IdGenerator();

  /// Whether the acting user owns the deck.
  bool get isOwner => false;

  @override
  CurrentRowReader get currentRows => model;

  /// A planning context for operations built outside [execute] (previews).
  SlidesPlanContext planContext() => SlidesPlanContext(
    userId: userId,
    // Millisecond precision, as stored and synced (RevLog codec).
    now: DateTime.fromMillisecondsSinceEpoch(
      clock.now().millisecondsSinceEpoch,
      isUtc: true,
    ),
    ids: ids,
    limits: limits,
    isOwner: isOwner,
  );

  /// Plans [op], applies it to [model] and persists it. Throws
  /// `PlanException` (nothing is applied then). Returns the plan (empty
  /// plans are neither applied nor persisted).
  SlidesPlan execute(SlidesOperation op, {String actorKind = 'user'}) {
    final plan = planner.plan(op, model, planContext());
    if (plan.isEmpty) return plan;
    checkPlan(op, plan);
    beforeApply(plan.changes);
    model.applyPlan(plan);
    persist(plan.changes, plan: plan, label: plan.label, actorKind: actorKind);
    return plan;
  }

  @override
  void applyChanges(
    List<RowChange> changes, {
    required String label,
    String actorKind = 'user',
  }) {
    if (changes.isEmpty) return;
    beforeApply(changes);
    model.applyChanges(changes);
    persist(changes, label: label, actorKind: actorKind);
  }

  /// Applies changes that came from other devices or the server.
  DeckChangeBatch applyRemote(List<RowChange> changes) =>
      model.applyChanges(changes, origin: DeckChangeOrigin.remote);

  /// Refuses [plan] of [op] before it is applied by throwing
  /// `PlanException` (role checks, rows still loading).
  @protected
  void checkPlan(SlidesOperation op, SlidesPlan plan) {}

  /// Called with local [changes] just before they are applied to [model]
  /// (the RevLog session remembers the server version of the rows they
  /// touch, RevLog spec 06 §3.1).
  @protected
  void beforeApply(List<RowChange> changes) {}

  /// Stores [changes] (already applied to [model]). [plan] is set for
  /// planned operations (its summary/detail feed the `DeckChangeLog` row).
  @protected
  void persist(
    List<RowChange> changes, {
    SlidesPlan? plan,
    required String label,
    required String actorKind,
  });
}
