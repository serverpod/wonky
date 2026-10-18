import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/maintenance.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;
import 'package:wonky_revlog/rows.dart' show composeRowChanges;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/sharing/access_service.dart';
import '../revlog/slides_revlog.dart';
import '../revlog/slides_server_writes.dart';
import 'deck_text_claims.dart';

/// The server's request context of the headless contracts
/// (`HeadlessDeckProvider<C>`, Slides 12 §5.7): the session and the acting
/// user (MCP token, AI assistant, server job).
class HeadlessDeckContext {
  const HeadlessDeckContext(this.session, this.actor);

  final Session session;
  final Actor actor;
}

/// The result of [ServerHeadlessDeck.write] (11 §2.2).
class HeadlessDeckWrite {
  HeadlessDeckWrite({
    required this.plan,
    required this.changeId,
    required this.syncVersion,
    required this.repaired,
  });

  final SlidesPlan plan;

  /// `change_id` for `changes.revert` (24 h); null when nothing changed.
  final UuidValue? changeId;

  /// `sync_version`: the deck revision of the write (RevLog spec 08 §7).
  final String? syncVersion;

  /// Whether a maintenance plan ("Repair presentation") ran first.
  final bool repaired;
}

/// A deck opened on the server for one caller (Slides 11 §2.1): reads come
/// from the headless [DeckModel] (RevLog spec 05 §9: it follows the deck's
/// ops); writes plan with the shared `SlidesPlanner`, run the deck's
/// maintenance first (02 §10, not recorded), refuse bodies other users are
/// editing (`being_edited`) unless forced, and are committed with
/// [SlidesServerWrites.applyRecorded] (RevLog server change with a
/// `ServerChangeRecord` for revert). Planning on one deck is serialized
/// per instance.
class ServerHeadlessDeck implements HeadlessDeck {
  ServerHeadlessDeck(this.context, this.item, this.role, this._model);

  final HeadlessDeckContext context;

  /// The deck's drive item.
  final DriveItem item;

  /// The caller's role when opened.
  final Role role;

  DeckModel _model;

  /// A copy-on-write overlay (AI Suggest mode, 11 §6.3): reads see it and
  /// writes are recorded there instead of being written to the deck.
  DeckOverlay? overlay;

  /// The deck's file (= item uuid).
  UuidValue get space => item.contentRef!;

  @override
  DeckModel get model => overlay?.model ?? _model;

  @override
  Future<SlidesPlan> execute(
    SlidesOperation op, {
    String actorKind = 'mcp',
  }) async => (await write(op, actorKind: actorKind)).plan;

  /// Plans and writes [op] (see the class comment). [force] writes bodies
  /// others are editing. [label] overrides the plan's label.
  Future<HeadlessDeckWrite> write(
    SlidesOperation op, {
    String? actorKind,
    bool force = false,
    String? label,
  }) => writeSteps(
    (steps) => steps.run(op),
    actorKind: actorKind,
    force: force,
    label: label,
    singleStep: true,
  );

  /// Plans several operations as **one** change (SL-40: one MCP call = one
  /// change, 11 §1.4): [build] runs operations through [DeckSteps.run],
  /// each planned against the state the previous ones left (a scratch copy
  /// of the model); their row changes are composed into one plan, checked
  /// for soft locks and written with one change record. A
  /// `PlanException` thrown by [build] writes nothing. With [singleStep]
  /// [build] runs one operation planned against the deck itself (no
  /// scratch copy, CQ-35; [write] does this).
  Future<HeadlessDeckWrite> writeSteps(
    FutureOr<void> Function(DeckSteps steps) build, {
    String? actorKind,
    bool force = false,
    String? label,
    bool singleStep = false,
  }) {
    final session = context.session;
    final actor = context.actor.copyWith(
      kind: ActorKind.values.asNameMap()[actorKind] ?? context.actor.kind,
    );
    final shadow = overlay;
    if (shadow != null) {
      return _writeOverlay(
        shadow,
        build,
        actor: actor,
        label: label,
        singleStep: singleStep,
      );
    }
    return SlidesServerWrites.withWriteLock(space, () async {
      await AccessService.requireRole(session, actor, item, Role.editor);
      _model = await SlidesRevlog.model(session, space);
      var repaired = false;
      final repair = DeckMaintenance.repairOp(model);
      if (repair != null) {
        final fix = const SlidesPlanner().plan(repair, model, _context(actor));
        if (fix.changes.isNotEmpty) {
          // Not part of the change record (11 §2.1; 08 §4).
          await SlidesServerWrites.apply(
            session,
            actor: actor.copyWith(kind: ActorKind.user),
            fileUuid: space,
            changes: fix.changes,
            label: DeckMaintenance.label,
            summary: fix.summary,
            repair: true,
          );
          _model = await SlidesRevlog.model(session, space);
          repaired = true;
        }
      }
      final steps = DeckSteps(
        model,
        _context(actor),
        singleStep: singleStep,
      );
      await build(steps);
      final plan = steps.plan(label: label);
      if (!force) {
        await DeckTextClaims.watch(session, item.uuid);
        final hits = DeckTextClaims.conflicts(
          item.uuid,
          plan.changes,
          actingUser: actor.authUserId,
        );
        if (hits.isNotEmpty) throw beingEdited(hits);
      }
      if (plan.changes.isEmpty) {
        return HeadlessDeckWrite(
          plan: plan,
          changeId: null,
          syncVersion: null,
          repaired: repaired,
        );
      }
      final written = await SlidesServerWrites.applyRecorded(
        session,
        actor: actor,
        item: item,
        changes: plan.changes,
        label: label ?? plan.label,
        summary: plan.summary,
        detail: plan.detail,
      );
      // The live model follows the committed ops.
      _model = await SlidesRevlog.model(session, space);
      return HeadlessDeckWrite(
        plan: plan,
        changeId: written.changeId,
        syncVersion: written.syncVersion,
        repaired: repaired,
      );
    });
  }

  /// [writeSteps] into [shadow]: planned against the overlay's model and
  /// recorded there (no change record, no soft-lock check: nothing is
  /// written until the user applies the preview).
  Future<HeadlessDeckWrite> _writeOverlay(
    DeckOverlay shadow,
    FutureOr<void> Function(DeckSteps steps) build, {
    required Actor actor,
    String? label,
    bool singleStep = false,
  }) async {
    await AccessService.requireRole(
      context.session,
      actor,
      item,
      Role.editor,
    );
    final steps = DeckSteps(
      shadow.model,
      _context(actor),
      singleStep: singleStep,
    );
    await build(steps);
    final plan = steps.plan(label: label);
    if (plan.changes.isNotEmpty) {
      shadow.record(plan, label: label ?? plan.label);
    }
    return HeadlessDeckWrite(
      plan: plan,
      changeId: null,
      syncVersion: null,
      repaired: false,
    );
  }

  SlidesPlanContext _context(Actor actor) => SlidesPlanContext(
    userId: actor.authUserId.uuid,
    now: clock.now().toUtc(),
    isOwner: item.ownerId == actor.userId,
  );

  /// The `being_edited` error (11 §2.3): code `conflict` with details
  /// `{"code": "being_edited", "targets": [...]}` (the MCP layer maps it).
  static WonkyException beingEdited(List<DeckTextClaim> claims) {
    final names = {for (final c in claims) c.displayName}.join(', ');
    return WonkyException(
      code: WonkyErrorCode.conflict,
      message:
          '$names ${claims.length == 1 ? 'is' : 'are'} editing this text. '
          'Pass force to write anyway.',
      detailsJson: jsonEncode({
        'code': beingEditedCode,
        'targets': [for (final c in claims) c.toJson()],
      }),
    );
  }

  /// `details.code` of [beingEdited].
  static const beingEditedCode = 'being_edited';
}

/// A copy-on-write overlay over a deck (AI Suggest mode, Slides 11 §6.3):
/// tool calls of an assistant run read [model] and their writes are
/// [record]ed (applied to [model]) instead of being written.
abstract interface class DeckOverlay {
  /// The deck with the recorded writes.
  DeckModel get model;

  /// Records one write (one tool call) and applies it to [model].
  void record(SlidesPlan plan, {required String label});
}

/// The overlays of running assistant runs, by run (`ToolContext.groupId`)
/// and deck space (registered by `SlidesShadows`).
abstract final class DeckOverlays {
  static final Map<String, DeckOverlay> _all = {};

  static String _key(String runId, UuidValue space) => '$runId|${space.uuid}';

  static void put(String runId, UuidValue space, DeckOverlay overlay) =>
      _all[_key(runId, space)] = overlay;

  static DeckOverlay? of(String? runId, UuidValue space) =>
      runId == null ? null : _all[_key(runId, space)];

  static void remove(String runId, UuidValue space) =>
      _all.remove(_key(runId, space));

  /// Forgets every overlay (tests).
  static void clear() => _all.clear();
}

/// The operations of one composite write ([ServerHeadlessDeck.writeSteps]):
/// each [run] plans against a scratch copy of the deck that holds the
/// previous steps' changes, so later steps can address rows earlier ones
/// created ([model] is that copy, the same object for the whole write).
///
/// A single-operation write ([ServerHeadlessDeck.write], [singleStep])
/// plans directly against the deck and never copies it (CQ-35); it takes
/// exactly one [run].
class DeckSteps {
  DeckSteps(DeckModel source, this.context, {this.singleStep = false})
    : model = singleStep ? source : _copy(source);

  /// Whether this write has one step planned against the deck itself.
  final bool singleStep;

  /// The scratch model (the deck with the steps so far); the deck itself
  /// for a [singleStep] write.
  final DeckModel model;

  /// Scratch copies made (tests).
  int get copies => singleStep ? 0 : 1;

  static DeckModel _copy(DeckModel source) =>
      DeckModel.fromRows(source.deckId, [
        for (final t in SlidesTables.dependencyOrder)
          for (final r in source.records(t)) (t, r.toColumns()),
      ]);

  /// The planning context.
  final SlidesPlanContext context;

  /// The plans of the steps so far.
  final List<SlidesPlan> plans = [];

  /// Plans [op] against [model], applies it there (not for a [singleStep]
  /// write: the deck itself follows the committed op) and records it.
  /// Throws `PlanException`.
  SlidesPlan run(SlidesOperation op) {
    if (singleStep && plans.isNotEmpty) {
      throw StateError('A single-step write takes one operation.');
    }
    final plan = const SlidesPlanner().plan(op, model, context);
    if (!singleStep && plan.changes.isNotEmpty) model.applyPlan(plan);
    plans.add(plan);
    return plan;
  }

  /// The composed plan of every step (the single step's plan as is).
  SlidesPlan plan({String? label}) {
    if (plans.length == 1) return plans.single;
    final changes = composeRowChanges([for (final p in plans) ...p.changes]);
    return SlidesPlan(
      label: label ?? (plans.isEmpty ? '' : plans.first.label),
      summary: SlidesChangeSummary.of(changes, current: model),
      changes: changes,
      detail: plans.isEmpty ? null : plans.first.detail,
      warnings: [for (final p in plans) ...p.warnings],
      result: {for (final p in plans) ...p.result},
    );
  }
}

/// Opens headless decks (Slides 12 §5.7, 11 §2.1) by deck id (= space =
/// item uuid) for the context's user: Viewer+ reads, Editor+ writes.
class SlidesHeadlessProvider
    implements HeadlessDeckProvider<HeadlessDeckContext> {
  const SlidesHeadlessProvider();

  @override
  Future<ServerHeadlessDeck> open(
    HeadlessDeckContext context,
    String deckId,
  ) async {
    final space = UuidValue.withValidation(deckId);
    final item = await DriveItem.db.findFirstRow(
      context.session,
      where: (t) =>
          t.contentRef.equals(space) &
          t.kind.equals(DriveItemKind.presentation),
    );
    if (item == null) {
      throw Errors.notFound('Presentation');
    }
    final role = await AccessService.requireRole(
      context.session,
      context.actor,
      item,
      Role.viewer,
    );
    final model = await SlidesRevlog.model(context.session, space);
    return ServerHeadlessDeck(context, item, role, model);
  }
}
