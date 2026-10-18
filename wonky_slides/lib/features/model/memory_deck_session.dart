import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role, UuidV7Generator;
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_sync_models/ids.dart' show IdGenerator, UuidV7IdGenerator;
import 'package:wonky_ui/wonky_ui.dart' show SyncStatus;

import 'deck_session.dart';

/// Shared implementation of [DeckSession]: listenables, planning and
/// applying through the core `DeckWritePath`. Subclasses persist (the
/// synced replica in `features/sync`, SL-9) by overriding [persist] and
/// [flush], drive [loadStateNotifier]/[syncStatusNotifier], and apply sync
/// merges with `applyRemote`.
abstract class DeckSessionBase extends DeckSession with DeckWritePath {
  DeckSessionBase({
    required this.itemUuid,
    required this.userId,
    required this.model,
    required this.planner,
    Role role = Role.owner,
    SlideImageResolver? images,
    IdGenerator? ids,
    this.limits = SlidesLimits.defaults,
  }) : _role = ValueNotifier(role),
       images = images ?? MemorySlideImageResolver(),
       ids = ids ?? const UuidV7IdGenerator();

  @override
  final UuidValue itemUuid;

  @override
  final String userId;

  @override
  final DeckModel model;

  @override
  final SlidesMutationPlanner planner;

  @override
  final SlideImageResolver images;

  @override
  final IdGenerator ids;

  @override
  final SlidesLimits limits;

  final ValueNotifier<Role> _role;

  @override
  ValueListenable<Role> get role => _role;

  set roleValue(Role value) => _role.value = value;

  @override
  bool get isOwner => role.value == Role.owner;

  @protected
  final ValueNotifier<DeckLoadState> loadStateNotifier = ValueNotifier(
    const DeckLoading(),
  );

  @protected
  final ValueNotifier<SyncStatus> syncStatusNotifier = ValueNotifier(
    SyncStatus.saved,
  );

  @override
  String get deckId => model.deckId;

  @override
  ValueListenable<DeckLoadState> get loadState => loadStateNotifier;

  @override
  ValueListenable<SyncStatus> get syncStatus => syncStatusNotifier;

  @override
  Stream<DeckChangeBatch> get remoteBatches =>
      model.changes.where((b) => b.isRemote);

  /// Viewers and commenters can't write (commands check the role first;
  /// this guards MCP UI tools and AI).
  @override
  void checkPlan(SlidesOperation op, SlidesPlan plan) {
    if (!canEdit) {
      throw const PlanException(
        PlanException.permission,
        'You can only view this presentation.',
      );
    }
  }

  @override
  Future<void> dispose() async {
    await flush();
    await model.dispose();
    loadStateNotifier.dispose();
    syncStatusNotifier.dispose();
    _role.dispose();
  }
}

/// A session that only lives in memory: command and widget tests, version
/// views, previews and AI suggest mode.
class MemoryDeckSession extends DeckSessionBase {
  MemoryDeckSession({
    required super.itemUuid,
    required super.userId,
    required super.model,
    required super.planner,
    super.role,
    super.images,
    super.ids,
    super.limits,
  }) {
    loadStateNotifier.value = const DeckReady();
  }

  /// A new deck created with `CreateDeck` (theme [themeKey], one title
  /// slide) through [planner] (default: the core `SlidesPlanner`).
  factory MemoryDeckSession.blank({
    SlidesMutationPlanner planner = const SlidesPlanner(),
    UuidValue? itemUuid,
    String userId = '00000000-0000-7000-8000-000000000001',
    String title = 'Untitled presentation',
    String themeKey = 'wonky',
    Role role = Role.owner,
    IdGenerator? ids,
  }) {
    final id = itemUuid ?? UuidV7Generator().next();
    final session = MemoryDeckSession(
      itemUuid: id,
      userId: userId,
      model: DeckModel(deckId: id.uuid),
      planner: planner,
      role: Role.owner,
      ids: ids,
    );
    session.execute(
      CreateDeck(deckId: id.uuid, title: title, themeKey: themeKey),
    );
    session.persisted.clear();
    session.persistedLabels.clear();
    session.roleValue = role;
    return session;
  }

  /// Every change persisted so far (tests).
  final List<RowChange> persisted = [];

  /// Labels of the persisted writes, in order (tests).
  final List<String> persistedLabels = [];

  @override
  void persist(
    List<RowChange> changes, {
    SlidesPlan? plan,
    required String label,
    required String actorKind,
  }) {
    persisted.addAll(changes);
    persistedLabels.add(label);
  }

  @override
  Future<void> flush() async {}
}
