import 'package:test/test.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

MemoryDeck _deck(DeckModel model) => MemoryDeck(
  model: model,
  userId: testUserId,
  planner: const FakeSlidesPlanner(),
  ids: SequentialIdGenerator(1000),
);

void main() {
  group('Given an empty memory deck', () {
    late MemoryDeck deck;
    setUp(() => deck = _deck(DeckModel(deckId: testDeckId)));

    test('when creating the deck then the deck, the theme copy and a title '
        'slide exist and the write is persisted once', () {
      final plan = deck.execute(
        const CreateDeck(deckId: testDeckId, title: 'Pitch'),
      );

      expect(plan.label, 'Create presentation');
      expect(deck.model.deck?.title, 'Pitch');
      expect(deck.model.themes, hasLength(1));
      expect(deck.model.slides, hasLength(1));
      expect(deck.model.elementsOf(deck.model.slides.single.id), isNotEmpty);
      expect(deck.writes.single.plan, same(plan));
      expect(deck.writes.single.summary.kinds, contains('structure'));
    });
  });

  group('Given a memory deck with one slide', () {
    late MemoryDeck deck;
    late String slide;

    setUp(() {
      final b = DeckBuilder();
      slide = b.slide();
      deck = _deck(b.build());
    });

    test('when an operation changes nothing then the plan is empty and '
        'nothing is persisted', () {
      final plan = deck.execute(const SetDeckProps(title: 'Test deck'));

      expect(plan.isEmpty, isTrue);
      expect(deck.writes, isEmpty);
    });

    test('when the planner refuses then the model is unchanged', () {
      final before = deck.model.dump();

      expect(
        () => deck.execute(const DeleteSlides(['missing'])),
        throwsA(
          isA<PlanException>().having((e) => e.code, 'code', 'not_found'),
        ),
      );
      expect(deck.model.dump(), before);
      expect(deck.writes, isEmpty);
    });

    test('when an unsupported operation is planned then it is refused as '
        'unsupported', () {
      expect(
        () => deck.execute(const Ungroup('g')),
        throwsA(
          isA<PlanException>().having((e) => e.code, 'code', 'unsupported'),
        ),
      );
    });

    test('when adding slides then the plan applies at once and returns the '
        'new ids', () {
      final plan = deck.execute(AddSlides(afterSlideId: slide, count: 2));

      expect(deck.model.slides, hasLength(3));
      expect(plan.result['slideIds'], hasLength(2));
      expect(deck.model.slides.first.id, slide);
    });

    test('when changes come from elsewhere then only they are on '
        'remoteBatches and nothing is persisted', () async {
      final remote = <DeckChangeBatch>[];
      deck.remoteBatches.listen(remote.add);

      deck.execute(const SetDeckProps(title: 'Local'));
      deck.applyRemote([
        ...deck.model.slides.map((s) => RowChangeHelpers.skip(s.id, s.skipped)),
      ]);

      expect(remote, hasLength(1));
      expect(remote.single.event<SlidesChanged>()!.slideIds, {slide});
      expect(deck.writes, hasLength(1));
    });

    test('when applying precomputed changes then they are applied and '
        'persisted with the label', () {
      deck.applyChanges([
        RowChangeHelpers.skip(slide, false),
      ], label: 'Undo Skip slide');

      expect(deck.model.slide(slide)!.skipped, isTrue);
      expect(deck.writes.single.label, 'Undo Skip slide');
      expect(deck.writes.single.plan, isNull);
    });

    test('when reading the plan context then it carries the user, ids and '
        'limits', () {
      final ctx = deck.planContext();

      expect(ctx.userId, testUserId);
      expect(ctx.limits.maxSlidesPerDeck, 1000);
      expect(ctx.ids.newId(), isNotEmpty);
      expect(deck.currentRows, same(deck.model));
    });
  });
}

abstract final class RowChangeHelpers {
  /// Toggles `skipped` of slide [id] from [before].
  static RowChange skip(String id, bool before) => RowChange.update(
    SlidesTables.slide,
    id,
    {SlidesCols.skipped: before},
    {SlidesCols.skipped: !before},
  );
}
