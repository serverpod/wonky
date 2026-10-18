import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_slides_core/history.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart' show FractionalIndex;

/// Two copies of one deck: [before] stays, [after] gets the edits.
class _Versions {
  _Versions(this.b) : before = b.build(), after = b.build();

  final DeckBuilder b;
  final DeckModel before;
  final DeckModel after;

  void update(String table, String id, Map<String, Object?> cols) =>
      after.applyChanges([
        RowChange.update(table, id, {
          for (final k in cols.keys) k: after.currentColumns(table, id)![k],
        }, cols),
      ]);

  void insert(String table, Map<String, Object?> cols) => after.applyChanges([
    RowChange.insert(table, cols[SlidesCols.id]! as String, cols),
  ]);

  void delete(String table, String id) => after.applyChanges([
    RowChange.delete(table, id, after.currentColumns(table, id)!),
  ]);

  DeckDiff diff() => DeckDiff.compute(before, after);
}

void main() {
  late DeckBuilder b;
  late String s1, s2, s3, box, g;

  setUp(() {
    b = DeckBuilder();
    g = b.group('Intro');
    s1 = b.slide(groupId: g, title: 'One');
    s2 = b.slide(title: 'Two');
    s3 = b.slide(title: 'Three');
    box = b.shape(s2, x: 100, y: 300, text: 'Box');
  });

  group('Given two identical versions', () {
    test('when diffed then nothing differs', () {
      final v = _Versions(b);
      expect(v.diff().isEmpty, isTrue);
      expect(v.diff().stops, isEmpty);
    });
  });

  group('Given a shape edited between two versions', () {
    test('when its text changes then slide 2 changed with a text change', () {
      final v = _Versions(b)
        ..update(SlidesTables.slideElement, box, {
          SlidesCols.text: deltaOf('Box!'),
        });

      final d = v.diff();

      expect(d.slides.keys, [s2]);
      final c = d.slide(s2)!;
      expect(c.status, DiffStatus.changed);
      expect(c.contentChanged, isTrue);
      expect(c.elements.single.id, box);
      expect(c.elements.single.kinds, {ElementChangeKind.text});
    });

    for (final (cols, kind) in <(Map<String, Object?>, ElementChangeKind)>[
      ({ElementCols.x: 500.0}, ElementChangeKind.frame),
      (
        {ElementCols.fillJson: '{"type":"solid","color":"red"}'},
        ElementChangeKind.style,
      ),
      ({ElementCols.zKey: 'zz'}, ElementChangeKind.order),
      ({SlidesCols.hidden: true}, ElementChangeKind.visibility),
      ({ElementCols.altText: 'A box'}, ElementChangeKind.data),
    ]) {
      test(
        'when ${cols.keys.single} changes then the kind is ${kind.name}',
        () {
          final v = _Versions(b)..update(SlidesTables.slideElement, box, cols);

          expect(v.diff().slide(s2)!.elements.single.kinds, {kind});
        },
      );
    }

    test(
      'when JSON columns only differ in formatting then nothing changed',
      () {
        final v = _Versions(b);
        final data = v.after.element(box)!.dataJson!;
        v.update(SlidesTables.slideElement, box, {
          ElementCols.dataJson: const JsonEncoder.withIndent(
            '  ',
          ).convert(jsonDecode(data)),
        });

        expect(v.diff().isEmpty, isTrue);
      },
    );
  });

  group('Given elements added and removed', () {
    test('when a shape is added to slide 3 then it is listed as added', () {
      final before = b.build();
      final added = b.shape(s3, x: 10, y: 10);

      final c = DeckDiff.compute(before, b.build()).slide(s3)!;

      expect(c.elements.single.id, added);
      expect(c.elements.single.status, DiffStatus.added);
    });

    test('when the shape is deleted then it is listed as removed with its '
        'older row (ghost frame)', () {
      final v = _Versions(b)..delete(SlidesTables.slideElement, box);

      final e = v.diff().slide(s2)!.elements.single;

      expect(e.status, DiffStatus.removed);
      expect(e.before!.y, 300);
      expect(v.diff().stops, [(slideId: s2, elementId: null)]);
    });
  });

  group('Given an element group', () {
    late String grp, child;
    setUp(() {
      grp = b.ids.newId();
      child = b.shape(s3, text: 'Child', parentId: grp);
      b.elementGroup(s3, groupId: grp);
    });

    test('when only the child changes then it keeps its entry and outlines '
        'the group', () {
      final v = _Versions(b)
        ..update(SlidesTables.slideElement, child, {
          SlidesCols.text: deltaOf('Kid'),
        });

      final e = v.diff().slide(s3)!.elements.single;

      expect(e.id, child);
      expect(e.topId, grp);
    });

    test('when the group and the child change then the child rolls up into '
        'the group', () {
      final v = _Versions(b)
        ..update(SlidesTables.slideElement, grp, {ElementCols.x: 50.0})
        ..update(SlidesTables.slideElement, child, {
          SlidesCols.text: deltaOf('Kid'),
        });

      final e = v.diff().slide(s3)!.elements.single;

      expect(e.id, grp);
      expect(e.kinds, {ElementChangeKind.frame, ElementChangeKind.text});
    });
  });

  group('Given slides reordered, added, removed and skipped', () {
    test('when slide 3 moves before slide 2 then it is moved, not changed', () {
      final v = _Versions(b);
      v.update(SlidesTables.slide, s3, {
        SlidesCols.sortKey: FractionalIndex.between(
          v.after.group(g)!.sortKey,
          v.after.slide(s2)!.sortKey,
        ),
      });

      final c = v.diff().slide(s3)!;

      expect(c.moved, isTrue);
      expect(c.contentChanged, isFalse);
      expect(v.after.indexes.order.indexOf(s3), 1);
    });

    test('when a slide is added then it is new and every element is added', () {
      final before = b.build();
      final s4 = b.slide(title: 'Four');
      final d = DeckDiff.compute(before, b.build());

      expect(d.slide(s4)!.status, DiffStatus.added);
      expect(d.slide(s4)!.elements, isNotEmpty);
      expect(d.stops.first, (slideId: s4, elementId: null));
    });

    test(
      'when slide 2 is deleted then it is a removed slide after slide 1',
      () {
        final v = _Versions(b);
        for (final e in v.after.allElementsOf(s2).toList()) {
          v.delete(SlidesTables.slideElement, e.id);
        }
        v.delete(SlidesTables.slide, s2);

        final d = v.diff();

        expect(d.slides, isEmpty);
        expect(d.removedSlides.single.change.slideId, s2);
        expect(d.removedSlides.single.afterSlideId, s1);
        expect(d.changedSlideCount, 1);
      },
    );

    test('when slide 1 is skipped and its notes edited then both show', () {
      final v = _Versions(b)
        ..update(SlidesTables.slide, s1, {
          SlidesCols.skipped: true,
          SlideCols.notes: deltaOf('New notes'),
        });

      final c = v.diff().slide(s1)!;

      expect(c.skipToggled, isTrue);
      expect(c.own, {SlideOwnChange.notes});
    });
  });

  group('Given builds, tables and the theme', () {
    test('when a build is added then the slide counts it and the element '
        'has an animation change', () {
      final before = b.build();
      b.build_(s2, box);
      final c = DeckDiff.compute(before, b.build()).slide(s2)!;

      expect(c.builds.added, 1);
      expect(c.elements.single.kinds, {ElementChangeKind.animation});
    });

    test('when a table cell text changes then the table has a text change', () {
      final (t, rows, cols) = b.table(s1);
      final cell = b.cell(t, rows.first, cols.first, 'A');
      final v = _Versions(b)
        ..update(SlidesTables.slideTableCell, cell, {
          SlidesCols.text: deltaOf('B'),
        });

      final e = v.diff().slide(s1)!.elements.single;

      expect(e.id, t);
      expect(e.kinds, {ElementChangeKind.text});
    });

    test('when the theme is renamed then the theme changed and no slide', () {
      final v = _Versions(b);
      final theme = v.after.themes.first;
      v.update(SlidesTables.deckTheme, theme.id, {SlidesCols.name: 'Mine'});

      final d = v.diff();

      expect(d.themeChanged, isTrue);
      expect(d.slides, isEmpty);
    });

    test('when the group is renamed and recolored then both kinds show', () {
      final v = _Versions(b)
        ..update(SlidesTables.slideGroup, g, {
          SlidesCols.title: 'Start',
          SlideGroupCols.color: 'red',
        });

      expect(v.diff().groups[g]!.kinds, {
        GroupChangeKind.renamed,
        GroupChangeKind.recolored,
      });
    });

    test('when the deck is renamed then the deck title changed', () {
      final v = _Versions(b)
        ..update(SlidesTables.deck, b.deckId, {DeckCols.title: 'Renamed'});

      expect(v.diff().deckChanged, {DeckCols.title});
    });
  });

  group('Given no previous version', () {
    test('when diffed then every slide is new', () {
      final d = DeckDiff.compute(null, b.build());

      expect(d.slides.keys, unorderedEquals([s1, s2, s3]));
      expect(
        d.slides.values.every((s) => s.status == DiffStatus.added),
        isTrue,
      );
    });
  });

  group('Given values of different types', () {
    for (final (a, c, same) in <(Object?, Object?, bool)>[
      (1, 1.0, true),
      (true, 1, true),
      ('2026-10-15T09:00:00.000Z', DateTime.utc(2026, 10, 15, 9), true),
      ('{"a":1,"b":2}', '{"b":2,"a":1}', false),
      ('{"a":1}', '{ "a": 1 }', true),
      (null, '', false),
    ]) {
      test('when comparing $a and $c then same is $same', () {
        expect(DeckDiff.sameValue(a, c), same);
      });
    }
  });
}
