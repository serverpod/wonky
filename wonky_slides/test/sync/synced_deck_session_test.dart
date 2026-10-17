import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart'
    show AccessRole, DeckChangeLog, Slide, UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides/features/model/deck_session.dart';
import 'package:wonky_slides/features/model/synced_deck_session.dart';
import 'package:wonky_slides/features/sync/slides_writer.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/maintenance.dart' show DeckMaintenance;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;
import 'package:wonky_sync_kit/rows.dart' show RowChange, RowOp;
import 'package:wonky_ui/wonky_ui.dart' show SyncState;

import 'support/slides_sync_harness.dart';

final space = UuidValue.fromString('0190a000-0000-7000-8000-0000000000c1');

void main() {
  group('Given a deck on the device', () {
    late FakeSessionHost host;

    setUp(() async {
      final replica = await openTestReplica();
      host = FakeSessionHost(replica);
      await createDeck(replica, space, title: 'Roadmap');
    });

    Future<SyncedDeckSession> open({Role role = Role.editor}) async {
      final s = SyncedDeckSession.open(
        host,
        itemUuid: space,
        spaceUuid: space,
        planner: planner,
        role: role,
      );
      addTearDown(s.dispose);
      await s.opened;
      return s;
    }

    test('when opened offline then it is ready from the replica', () async {
      final s = await open();

      expect(s.loadState.value, isA<DeckReady>());
      expect(s.deckId, space.uuid);
      expect(s.model.deck?.title, 'Roadmap');
      expect(s.model.slides, hasLength(1));
      expect(s.syncStatus.value.state, SyncState.offline);
      expect(host.subscribeCalls, 0);
      expect(s.fullReloads, 1);
    });

    test('when opened online then it subscribes and takes the role from the '
        'result', () async {
      host.online.value = true;
      host.subscribeResult = subscribed(space, role: AccessRole.owner);

      final s = await open(role: Role.viewer);

      expect(host.subscribeCalls, 1);
      expect(s.role.value, Role.owner);
      expect(s.loadState.value, isA<DeckReady>());
    });

    test('when the load batch is emitted then it says load and is not '
        'remote', () async {
      final s = SyncedDeckSession.open(
        host,
        itemUuid: space,
        spaceUuid: space,
        planner: planner,
        role: Role.editor,
      );
      addTearDown(s.dispose);
      final origins = <DeckChangeOrigin>[];
      s.model.addListener((b) => origins.add(b.origin));
      final remote = <DeckChangeBatch>[];
      s.remoteBatches.listen(remote.add);
      await s.opened;

      expect(origins, [DeckChangeOrigin.load]);
      expect(remote, isEmpty);
    });

    test('when a slide is added then the model updates at once and the rows '
        'and the change-log row are stored after flush', () async {
      final s = await open();

      final plan = s.execute(const AddSlides());
      expect(s.model.slides, hasLength(2));
      expect(s.syncStatus.value.state, SyncState.saving);
      await s.flush();

      final added = s.model.slides.last;
      expect(
        await Slide.db.findById(
          host.replica.session,
          UuidValue.fromString(added.id),
        ),
        isNotNull,
      );
      final logs = await DeckChangeLog.db.find(host.replica.session);
      expect(logs.map((l) => l.label), contains(plan.label));
      expect(logs.last.sessionId, 'test-session');
      expect(s.syncStatus.value.state, SyncState.offline);
      expect(host.kicks, greaterThan(0));
    });

    test('when undo changes are applied then they are stored without a '
        'plan', () async {
      final s = await open();
      final plan = s.execute(const AddSlides());

      s.applyChanges(plan.inverse().changes, label: 'Undo');
      await s.flush();

      expect(s.model.slides, hasLength(1));
      expect(
        canonical(await reloadModel(host.replica, space)),
        canonical(s.model),
      );
    });

    test('when another device adds a slide then the merge patches the model '
        'and emits a remote batch', () async {
      final s = await open();
      final batches = <DeckChangeBatch>[];
      s.remoteBatches.listen(batches.add);

      await writeOp(host.replica, space, (_) => const AddSlides(count: 2));
      host.mergesController.add(space);
      await eventually(() => s.model.slides.length == 3);

      expect(batches, isNotEmpty);
      expect(batches.last.isRemote, isTrue);
      expect(batches.last.event<SlidesChanged>(), isNotNull);
      expect(s.patches, greaterThan(0));
      expect(s.fullReloads, 1);
    });

    test('when a merge arrives while a local write is queued then the '
        'optimistic edit survives', () async {
      final s = await open();
      final slide = s.model.slides.single.id;

      s.execute(SetSlideProps([slide], skipped: true));
      // The queued write isn't stored yet; another device's merge lands.
      await writeOp(
        host.replica,
        space,
        (_) => const SetDeckProps(title: 'Renamed'),
      );
      host.mergesController.add(space);
      await s.ingestRemote();

      expect(s.model.slide(slide)?.skipped, isTrue);
      await eventually(() => s.model.deck?.title == 'Renamed');
      await s.flush();
      expect(
        canonical(await reloadModel(host.replica, space)),
        canonical(s.model),
      );
    });

    test('when the membership is removed then the open deck becomes '
        'unavailable', () async {
      final s = await open();

      await revokeLocally(host.replica, space);
      host.mergesController.add(space);

      await eventually(() => s.loadState.value is DeckUnavailable);
    });

    test('when the membership returns while the deck is open then it '
        'reloads and turns ready again', () async {
      final s = await open();
      final reloads = s.fullReloads;
      // A change that only the membership read filter hid and showed:
      // stored in the replica, but without journal entries.
      await writeOp(
        host.replica,
        space,
        (_) => const SetDeckProps(title: 'Renamed while unshared'),
      );
      await host.replica.db.unsafeExecute(
        'DELETE FROM "sheets_row_journal" WHERE "id" > ${s.cursor}',
      );
      await revokeLocally(host.replica, space);
      host.mergesController.add(space);
      await eventually(() => s.loadState.value is DeckUnavailable);

      await grantLocally(host.replica, space);
      host.mergesController.add(space);

      await eventually(() => s.loadState.value is DeckReady);
      expect(s.fullReloads, greaterThan(reloads));
      expect(s.model.deck?.title, 'Renamed while unshared');
      expect(s.canEdit, isTrue);
      expect(
        canonical(await reloadModel(host.replica, space)),
        canonical(s.model),
      );
    });

    test('when the membership turns read-only then an editor becomes a '
        'viewer and can no longer write', () async {
      final s = await open();
      expect(s.canEdit, isTrue);

      await grantLocally(host.replica, space, role: 'readOnly');
      host.mergesController.add(space);
      // Open and a viewer: the refusal is about the role, not the opening.
      await eventually(
        () => s.role.value == Role.viewer && s.loadState.value is DeckReady,
      );

      expect(
        () => s.execute(const AddSlides()),
        throwsA(
          isA<PlanException>().having(
            (e) => e.code,
            'code',
            PlanException.permission,
          ),
        ),
      );
    });

    test('when the role is updated from the drive then it applies', () async {
      final s = await open(role: Role.viewer);

      s.updateRole(Role.editor);

      expect(s.role.value, Role.editor);
    });
  });

  group('Given a merge that leaves a slide in a deleted group', () {
    late FakeSessionHost host;

    setUp(() async {
      final replica = await openTestReplica();
      host = FakeSessionHost(replica);
      await createDeck(replica, space);
      await writeOp(replica, space, (_) => const AddSlides());
      await writeOp(
        replica,
        space,
        (m) => CreateGroup([m.slides.last.id], title: 'Appendix'),
      );
    });

    Future<SyncedDeckSession> openAs(Role role) async {
      final s = SyncedDeckSession.open(
        host,
        itemUuid: space,
        spaceUuid: space,
        planner: planner,
        role: role,
        maintenanceDelay: const Duration(milliseconds: 20),
      );
      addTearDown(s.dispose);
      await s.opened;
      return s;
    }

    /// Another device deletes only the group row (a concurrent ungroup and
    /// move): the slide's `groupId` dangles.
    Future<void> deleteGroupRow(
      SyncedDeckSession s, {
      bool readOnly = false,
    }) async {
      final group = s.model.groups.single;
      // The writing device has write access; this one may not.
      if (readOnly) await grantLocally(host.replica, space);
      await SlidesWriter(host.replica).write(
        spaceId: space,
        changes: [
          RowChange(
            table: SlidesTables.slideGroup,
            rowId: group.id,
            op: RowOp.delete,
          ),
        ],
        label: 'Delete group',
        actorKind: 'user',
        sessionId: 'remote',
      );
      if (readOnly) {
        await grantLocally(host.replica, space, role: 'readOnly');
      }
      host.mergesController.add(space);
    }

    test('when an editor has it open then the orphan is repaired after the '
        'merge and the repair is stored', () async {
      final s = await openAs(Role.editor);
      final slide = s.model.slides.last.id;

      await deleteGroupRow(s);

      await eventually(() => s.repairs == 1);
      expect(s.model.slide(slide)?.groupId, isNull);
      await s.flush();
      final stored = await reloadModel(host.replica, space);
      expect(stored.slide(slide)?.groupId, isNull);
      final logs = await DeckChangeLog.db.find(host.replica.session);
      expect(logs.last.label, DeckMaintenance.label);
    });

    test('when a viewer has it open then nothing is written', () async {
      await grantLocally(host.replica, space, role: 'readOnly');
      final s = await openAs(Role.viewer);

      await deleteGroupRow(s, readOnly: true);
      await eventually(() => s.model.groups.isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(s.repairs, 0);
      expect(s.runMaintenance(), isNull);
    });
  });

  group('Given a deck that is not on the device', () {
    late FakeSessionHost host;

    setUp(() async {
      host = FakeSessionHost(await openTestReplica());
    });

    SyncedDeckSession open() {
      final s = SyncedDeckSession.open(
        host,
        itemUuid: space,
        spaceUuid: space,
        planner: planner,
        settleTimeout: const Duration(milliseconds: 300),
      );
      addTearDown(s.dispose);
      return s;
    }

    test('when opened offline then it is unavailable offline, and opens by '
        'itself once online', () async {
      final s = open();
      await s.opened;
      expect(s.loadState.value, isA<DeckUnavailable>());
      expect((s.loadState.value as DeckUnavailable).offline, isTrue);
      expect(() => s.execute(const AddSlides()), throwsA(isA<PlanException>()));

      // Online: subscribe succeeds and the deck arrives with the next sync.
      await createDeck(host.replica, space, title: 'Arrived');
      host.subscribeResult = subscribed(space, alreadyMember: false);
      host.online.value = true;

      await eventually(() => s.loadState.value is DeckReady);
      expect(s.model.deck?.title, 'Arrived');
    });

    test(
      'when it downloads then the progress is reported until ready',
      () async {
        host.online.value = true;
        host.subscribeResult = subscribed(
          space,
          alreadyMember: false,
          totalRows: 100000,
        );
        final states = <DeckLoadState>[];
        final s = open();
        s.loadState.addListener(() => states.add(s.loadState.value));

        await Future<void>.delayed(const Duration(milliseconds: 50));
        await createDeck(host.replica, space, title: 'Big');
        host.mergesController.add(space);
        await s.opened;

        expect(s.loadState.value, isA<DeckReady>());
        expect(
          states.whereType<DeckLoading>().where((l) => l.progress != null),
          isNotEmpty,
        );
        expect(host.kicks, greaterThan(0));
      },
    );

    test('when the server refuses access then it is unavailable', () async {
      host.online.value = true;
      host.subscribeError = Exception('forbidden');

      final s = open();
      await s.opened;

      final state = s.loadState.value as DeckUnavailable;
      expect(state.offline, isFalse);
      expect(state.reason, const SyncedDeckStrings().noAccess);
    });
  });
}
