import 'package:test/test.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';

const _noRows = {
  'slides': <String>[],
  'elements': <String>[],
  'groups': <String>[],
  'themes': <String>[],
};

void main() {
  group('Given a deck with a shape', () {
    late DeckModel model;
    late String slide, shape;

    setUp(() {
      final b = DeckBuilder();
      slide = b.slide(layoutKey: 'blank');
      shape = b.shape(slide);
      model = b.build();
    });

    test('when summarizing a move then kinds is frame and the element and '
        'its slide are listed', () {
      final s = SlidesChangeSummary.of([
        RowChange.update(
          SlidesTables.slideElement,
          shape,
          {'x': 100.0},
          {'x': 120.0},
        ),
      ], current: model);

      expect(s.toJson(), {
        'v': 1,
        'kinds': ['frame'],
        'slides': [slide],
        'elements': [shape],
        'deleted': _noRows,
        'revived': _noRows,
        'chartLinks': <String>[],
      });
    });

    test('when summarizing a delete and a revival then both are recorded', () {
      final row = model.element(shape)!.toColumns();
      final s = SlidesChangeSummary.of(
        [
          RowChange.delete(SlidesTables.slideElement, shape, row),
          RowChange.insert(SlidesTables.slide, 'revived-slide', {
            'sortKey': 'a9',
          }),
        ],
        current: model,
        wasDeleted: (t, id) => id == 'revived-slide',
      );

      final json = s.toJson();
      expect(json['kinds'], ['structure']);
      expect((json['deleted']! as Map)['elements'], [shape]);
      expect((json['revived']! as Map)['slides'], ['revived-slide']);
    });

    test('when summarizing text, notes, order and deck changes then each '
        'kind appears once in the canonical order', () {
      final s = SlidesChangeSummary.of([
        RowChange.update(SlidesTables.deck, testDeckId, {}, {'title': 'x'}),
        RowChange.update(SlidesTables.slide, slide, {}, {
          'groupId': null,
          'sortKey': 'b0',
        }),
        RowChange.update(SlidesTables.slide, slide, {}, {'notes': '[]'}),
        RowChange.update(SlidesTables.slideElement, shape, {}, {'text': '[]'}),
      ], current: model);

      expect(s.toJson()['kinds'], ['text', 'order', 'notes', 'deck']);
    });

    test('when more elements than the limit are touched then the list is '
        'capped and flagged', () {
      final s = SlidesChangeSummary();
      for (var i = 0; i < SlidesChangeSummary.maxElements + 1; i++) {
        s.elements.add('e${i.toString().padLeft(5, '0')}');
      }

      final json = s.toJson();
      expect(json['elements'], hasLength(SlidesChangeSummary.maxElements));
      expect(json['elementsOverflow'], isTrue);
    });
  });
}
