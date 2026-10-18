import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_slides/features/model/deck_session.dart';
import 'package:wonky_slides/features/model/memory_deck_session.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart' show SequentialIdGenerator;

MemoryDeckSession _blank({Role role = Role.owner}) => MemoryDeckSession.blank(
  planner: const FakeSlidesPlanner(),
  itemUuid: UuidValue.fromString(testDeckId),
  title: 'Pitch',
  role: role,
  ids: SequentialIdGenerator(),
);

void main() {
  group('Given a blank memory deck session', () {
    late MemoryDeckSession session;
    setUp(() => session = _blank());
    tearDown(() => session.dispose());

    test('when it opens then it is ready, saved, editable and holds the new '
        'deck with one slide', () {
      expect(session.loadState.value, isA<DeckReady>());
      expect(session.canEdit, isTrue);
      expect(session.deckId, testDeckId);
      expect(session.model.deck!.title, 'Pitch');
      expect(session.model.slides, hasLength(1));
      expect(session.persisted, isEmpty);
      expect(session.currentRows, same(session.model));
    });

    test('when an operation executes then the model changes at once and the '
        'write is persisted with its label', () {
      final slide = session.model.slides.single.id;

      final plan = session.execute(AddSlides(afterSlideId: slide));

      expect(session.model.slides, hasLength(2));
      expect(session.persisted, plan.changes);
      expect(session.persistedLabels, ['New slide']);
    });

    test('when the undo handler undoes a plan through the session then the '
        'model returns and the undo is persisted', () async {
      final before = session.model.dump();
      final plan = session.execute(const SetDeckProps(title: 'Renamed'));
      final handler = SlidesRowsUndoHandler(() => session);

      await handler.undo(SlidesRowsUndoEntry(plan.changes, label: plan.label));

      expect(session.model.dump(), before);
      expect(session.persistedLabels.last, 'Undo Rename presentation');
    });

    test(
      'when remote changes arrive then only they are on remoteBatches',
      () async {
        final batches = <DeckChangeBatch>[];
        final sub = session.remoteBatches.listen(batches.add);

        session.execute(const SetDeckProps(title: 'Local'));
        session.applyRemote([
          RowChange.update(SlidesTables.deck, testDeckId, {}, {
            'title': 'Remote',
          }),
        ]);
        await sub.cancel();

        expect(batches, hasLength(1));
        expect(batches.single.isRemote, isTrue);
        expect(session.model.deck!.title, 'Remote');
      },
    );
  });

  group('Given a viewer', () {
    test('when an operation executes then it is refused before anything is '
        'applied', () async {
      final session = _blank(role: Role.viewer);
      final before = session.model.dump();

      expect(session.canEdit, isFalse);
      expect(
        () => session.execute(const SetDeckProps(title: 'x')),
        throwsA(
          isA<PlanException>().having((e) => e.code, 'code', 'permission'),
        ),
      );
      expect(session.model.dump(), before);
      await session.dispose();
    });
  });
}
