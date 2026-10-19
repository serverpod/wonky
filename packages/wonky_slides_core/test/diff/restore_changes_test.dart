import 'package:test/test.dart';
import 'package:wonky_slides_core/history.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';

DeckRowsByTable _rows(DeckModel m) => {
  for (final t in SlidesTables.dependencyOrder)
    t: {for (final r in m.records(t)) r.id: r.toColumns()},
};

void main() {
  group('Given a version and the current deck that moved on', () {
    late DeckBuilder b;
    late DeckModel version;
    late DeckModel current;
    late String s1, s2, box, grp, child;

    setUp(() {
      b = DeckBuilder();
      s1 = b.slide(title: 'One');
      s2 = b.slide(title: 'Two');
      box = b.shape(s1, text: 'Box');
      grp = b.ids.newId();
      child = b.shape(s2, text: 'Child', parentId: grp);
      b.elementGroup(s2, groupId: grp);
      version = b.build();
      // Since the version: the box was edited, slide 2 (with its group)
      // deleted and a new slide added.
      current = b.build();
      current.applyChanges([
        RowChange.update(
          SlidesTables.slideElement,
          box,
          {SlidesCols.text: version.element(box)!.text},
          {SlidesCols.text: deltaOf('Edited')},
        ),
        for (final e in current.allElementsOf(s2).toList().reversed)
          RowChange.delete(SlidesTables.slideElement, e.id, e.toColumns()),
        RowChange.delete(
          SlidesTables.slide,
          s2,
          current.slide(s2)!.toColumns(),
        ),
      ]);
      const later = '01923456-789a-7bcd-8ef0-00000000aaaa';
      current.applyChanges([
        RowChange.insert(SlidesTables.slide, later, {
          ...current.slide(s1)!.toColumns(),
          SlidesCols.id: later,
          SlidesCols.sortKey: 'zz',
        }),
      ]);
    });

    test('when the restore changes are applied then the deck equals the '
        'version', () {
      final changes = SlidesRestoreChanges.between(
        _rows(current),
        _rows(version),
      );

      current.applyChanges(changes);

      expect(current.dump(), version.dump());
    });

    test('when computed then updates name only the differing columns', () {
      final changes = SlidesRestoreChanges.between(
        _rows(current),
        _rows(version),
      );

      final update = changes.singleWhere(
        (c) => c.op == RowOp.update && c.rowId == box,
      );
      expect(update.columnsAfter.keys, [SlidesCols.text]);
    });

    test('when computed then deletes come first and the group element is '
        'inserted before its child', () {
      final changes = SlidesRestoreChanges.between(
        _rows(current),
        _rows(version),
      );

      final firstInsert = changes.indexWhere((c) => c.op == RowOp.insert);
      expect(
        changes.sublist(firstInsert).any((c) => c.op == RowOp.delete),
        isFalse,
      );
      final ids = [
        for (final c in changes)
          if (c.op == RowOp.insert) c.rowId,
      ];
      expect(ids.indexOf(s2), lessThan(ids.indexOf(grp)));
      expect(ids.indexOf(grp), lessThan(ids.indexOf(child)));
    });

    test('when the deck already equals the version then nothing changes', () {
      expect(
        SlidesRestoreChanges.between(_rows(version), _rows(version)),
        isEmpty,
      );
    });
  });
}
