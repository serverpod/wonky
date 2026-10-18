@Timeout(Duration(minutes: 1))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/rows.dart' show RowChange, RowOp;
import 'package:wonky_slides/features/model/deck_session.dart';
import 'package:wonky_slides/features/revlog/logged_deck_session.dart';
import 'package:wonky_slides_core/maintenance.dart' show DeckMaintenance;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show SlidesTables;

import 'support/deck_harness.dart';

final anna = UuidValue.fromString('0190a000-0000-7000-8000-0000000000a1');
final bo = UuidValue.fromString('0190a000-0000-7000-8000-0000000000b2');
final deck = UuidValue.fromString('0190a000-0000-7000-8000-0000000000d1');

void main() {
  late FakeRevHub hub;

  setUp(() => hub = slidesHub());

  group('Given a deck created on Anna\'s device', () {
    test('when Bo opens it, then he sees the same deck and their edits '
        'reach each other', () async {
      final a = await DeckDevice.start(hub, anna);
      final sa = await a.create(deck);
      expect(sa.loadState.value, isA<DeckReady>());
      await sa.whenSynced(timeout: const Duration(seconds: 10));
      expect(hub.file(deck.uuid).head, 1);

      final b = await DeckDevice.start(hub, bo);
      final sb = await b.openFile(deck);
      expect(sb.model.dump(), sa.model.dump());

      sb.execute(const AddSlides());
      await sb.whenSynced(timeout: const Duration(seconds: 10));
      await eventually(() => sa.model.slides.length == 2);
      final batches = <DeckChangeBatch>[];
      final sub = sb.remoteBatches.listen(batches.add);
      addTearDown(sub.cancel);
      sa.execute(const SetDeckProps(title: 'Renamed'));
      await eventually(() => sb.model.deck?.title == 'Renamed');
      expect(batches.last.isRemote, isTrue);
      expect(sb.model.dump(), sa.model.dump());
    });

    test(
      'when Anna reopens it offline, then it is ready from the cache',
      () async {
        final a = await DeckDevice.start(hub, anna);
        final sa = await a.create(deck);
        sa.execute(const AddSlides());
        await sa.whenSynced(timeout: const Duration(seconds: 10));
        await sa.dispose();

        a.online = false;
        final again = await a.openFile(deck, role: Role.owner);
        expect(again.model.slides, hasLength(2));
      },
    );

    test('when it is created offline, then it reaches the server once '
        'online', () async {
      final a = await DeckDevice.start(hub, anna);
      a.online = false;
      final sa = await a.create(deck);
      sa.execute(const AddSlides());
      await sa.flush();
      expect(hub.hasFile(deck.uuid), isFalse);

      a.online = true;
      await sa.whenSynced(timeout: const Duration(seconds: 10));
      expect(hub.file(deck.uuid).head, greaterThanOrEqualTo(2));
      final b = await DeckDevice.start(hub, bo);
      final sb = await b.openFile(deck);
      expect(sb.model.slides, hasLength(2));
    });
  });

  group('Given a deck that is not on the device', () {
    setUp(() => commitChanges(hub, deck, anna, deckCreation(deck, anna)));

    test('when opened offline, then it is unavailable offline and opens by '
        'itself when the connection returns', () async {
      final b = await DeckDevice.start(hub, bo);
      b.online = false;
      final s = await b.openFile(deck, waitReady: false);
      final state = s.loadState.value;
      expect(state, isA<DeckUnavailable>());
      expect((state as DeckUnavailable).offline, isTrue);

      b.online = true;
      await whenReady(s);
      expect(s.model.deck, isNotNull);
    });

    test('when a viewer edits, then the server rejects it and the edit '
        'rolls back', () async {
      hub.file(deck.uuid).setReadOnly(bo.uuid);
      final b = await DeckDevice.start(hub, bo);
      final s = await b.openFile(deck);
      final slides = s.model.slides.length;
      s.execute(const AddSlides());
      await eventually(() => s.model.slides.length == slides);
      expect(s.role.value, Role.viewer);
    });
  });

  group('Given a remote op that leaves a slide in a deleted group', () {
    late String slide;

    setUp(() {
      commitChanges(hub, deck, anna, deckCreation(deck, anna));
    });

    Future<void> deleteGroupRow(DeckSession s) async {
      final group = s.model.groups.single;
      commitChanges(hub, deck, anna, [
        RowChange(
          table: SlidesTables.slideGroup,
          rowId: group.id,
          op: RowOp.delete,
        ),
      ], label: 'Delete group');
    }

    Future<LoggedDeckSession> openGrouped(Role role) async {
      final b = await DeckDevice.start(hub, bo);
      final s = await b.openFile(deck, role: Role.editor);
      s.execute(const AddSlides());
      s.execute(CreateGroup([s.model.slides.last.id], title: 'Appendix'));
      slide = s.model.slides.last.id;
      await s.whenSynced(timeout: const Duration(seconds: 10));
      if (role != Role.editor) {
        hub.file(deck.uuid).setReadOnly(bo.uuid);
        s.updateRole(role);
      }
      return s;
    }

    test('when an editor has it open, then the orphan is repaired and the '
        'repair is sent', () async {
      final s = await openGrouped(Role.editor);
      await deleteGroupRow(s);
      await eventually(() => s.model.slide(slide)?.groupId == null);
      await eventually(
        () => hub.file(deck.uuid).log.last.label == DeckMaintenance.label,
      );
    });

    test('when a viewer has it open, then nothing is written', () async {
      final s = await openGrouped(Role.viewer);
      final head = hub.file(deck.uuid).head;
      await deleteGroupRow(s);
      await eventually(() => s.model.groups.isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(hub.file(deck.uuid).head, head + 1);
    });
  });
}
