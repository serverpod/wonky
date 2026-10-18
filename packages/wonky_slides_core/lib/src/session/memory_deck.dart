import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart' show IdGenerator, UuidV7IdGenerator;

import '../model/api/deck_model.dart';
import '../model/api/events.dart';
import '../ops/change_summary.dart';
import '../ops/plan_context.dart';
import '../ops/planner.dart';
import 'deck_write_path.dart';

/// One persisted write of a [MemoryDeck] (what a writer would store: the
/// changes plus the `DeckChangeLog` fields).
final class PersistedWrite {
  /// Creates a write.
  const PersistedWrite({
    required this.changes,
    required this.label,
    required this.actorKind,
    this.plan,
  });

  final List<RowChange> changes;
  final String label;
  final String actorKind;

  /// The plan of an `execute` (null for `applyChanges`).
  final SlidesPlan? plan;

  /// The change-log summary (the plan's, else derived from the changes).
  SlidesChangeSummary get summary =>
      plan?.summary ?? SlidesChangeSummary.of(changes);
}

/// A pure-Dart deck session that only lives in memory: core and server
/// tests, AI suggest mode, previews. The app's `MemoryDeckSession` is the
/// same over Flutter listenables.
class MemoryDeck with DeckWritePath {
  /// Creates a session over [model].
  MemoryDeck({
    required this.model,
    required this.userId,
    required this.planner,
    IdGenerator? ids,
    this.limits = SlidesLimits.defaults,
    this.isOwner = true,
  }) : ids = ids ?? const UuidV7IdGenerator();

  @override
  final DeckModel model;

  @override
  final String userId;

  @override
  final SlidesMutationPlanner planner;

  @override
  final IdGenerator ids;

  @override
  final SlidesLimits limits;

  @override
  final bool isOwner;

  /// Every write persisted so far, in order.
  final List<PersistedWrite> writes = [];

  /// Called after each persisted write (sync relays in tests).
  void Function(PersistedWrite write)? onPersist;

  /// Every change persisted so far.
  List<RowChange> get persisted => [for (final w in writes) ...w.changes];

  /// Batches that came from other devices ([applyRemote]).
  Stream<DeckChangeBatch> get remoteBatches =>
      model.changes.where((b) => b.isRemote);

  @override
  void persist(
    List<RowChange> changes, {
    SlidesPlan? plan,
    required String label,
    required String actorKind,
  }) {
    final w = PersistedWrite(
      changes: changes,
      label: label,
      actorKind: actorKind,
      plan: plan,
    );
    writes.add(w);
    onPersist?.call(w);
  }

  /// Completes when everything applied so far is stored (always, here).
  Future<void> flush() async {}

  /// Releases the model.
  Future<void> dispose() => model.dispose();
}
