import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show UndoConflict;
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/undo.dart';

import '../support/rows.dart';

const _domain = 'test.rows';

class _Entry extends RowsUndoEntry {
  _Entry(List<RowChange> changes, {String label = ''})
    : super(_domain, changes, label: label);

  @override
  _Entry withChanges(List<RowChange> changes) => _Entry(changes, label: label);
}

class _Target implements RowsUndoTarget {
  final MemoryRows rows = MemoryRows();
  final List<String> labels = [];

  @override
  CurrentRowReader get currentRows => rows;

  @override
  void applyChanges(
    List<RowChange> changes, {
    required String label,
    String actorKind = 'user',
  }) {
    labels.add(label);
    rows.apply(changes);
  }
}

class _Handler extends RowsUndoHandler<_Entry> {
  _Handler(this.target, {super.onPartial});

  @override
  final _Target target;

  @override
  String get domain => _domain;

  @override
  _Entry entryFor(_Entry from, List<RowChange> changes) =>
      _Entry(changes, label: from.label);

  @override
  _Entry? decode(Map<String, Object?> json) =>
      switch (RowsUndoEntry.decode(json)) {
        (final changes, final label) => _Entry(changes, label: label),
        null => null,
      };
}

void main() {
  group('Given an applied rename of a slide', () {
    late _Target target;
    late _Handler handler;
    var partial = 0;
    final rename = RowChange.update(
      'slide',
      's1',
      {'title': 'A', 'note': 'x'},
      {'title': 'B', 'note': 'y'},
    );
    setUp(() {
      partial = 0;
      target = _Target();
      target.rows.apply([
        RowChange.insert('slide', 's1', {'title': 'B', 'note': 'y'}),
      ]);
      handler = _Handler(target, onPartial: () => partial++);
    });

    test('when undone and redone then the title goes back and forth with '
        'labeled change-log entries', () async {
      final redo = await handler.undo(_Entry([rename], label: 'Rename'));
      expect(target.rows.rows['slide']!['s1']!['title'], 'A');

      await handler.redo(redo);

      expect(target.rows.rows['slide']!['s1']!['title'], 'B');
      expect(target.labels, ['Undo Rename', 'Redo Rename']);
    });

    test('when someone else changed the note then only the title is undone '
        'and the partial callback fires', () async {
      target.rows.apply([
        RowChange.update('slide', 's1', {'note': 'y'}, {'note': 'z'}),
      ]);

      await handler.undo(_Entry([rename]));

      expect(target.rows.rows['slide']!['s1'], containsPair('title', 'A'));
      expect(target.rows.rows['slide']!['s1'], containsPair('note', 'z'));
      expect(partial, 1);
    });

    test('when the slide was deleted meanwhile then undo is a conflict', () {
      target.rows.apply([RowChange.delete('slide', 's1', const {})]);

      expect(handler.undo(_Entry([rename])), throwsA(isA<UndoConflict>()));
    });
  });

  group('Given two entries of one step', () {
    final a = _Entry([
      RowChange.insert('slide', 's1', {'n': 1}),
    ], label: 'Add');
    final b = _Entry([
      RowChange.insert('slide', 's2', {'n': 2}),
    ]);

    test('when coalesced then the changes are merged in order', () {
      final merged = a.coalesce(b);

      expect(merged, isA<_Entry>());
      expect((merged! as _Entry).changes.map((c) => c.rowId), ['s1', 's2']);
    });

    test('when persisted and decoded then the entry is equal', () {
      final handler = _Handler(_Target());

      final decoded = handler.decoder!(a.toJson())! as _Entry;

      expect(decoded.changes, a.changes);
      expect(decoded.label, 'Add');
      expect(handler.decoder!({'changes': 'nope'}), isNull);
    });
  });

  group('Given two coalesced typing writes of the same column', () {
    test('when undone then the column returns to its value before the first '
        'write', () async {
      final target = _Target();
      target.rows.apply([
        RowChange.insert('slide', 's1', {'title': 'A'}),
      ]);
      final first = RowChange.update(
        'slide',
        's1',
        {'title': 'A'},
        {'title': 'AB'},
      );
      final second = RowChange.update(
        'slide',
        's1',
        {'title': 'AB'},
        {'title': 'ABC'},
      );
      target.rows.apply([first, second]);

      final merged = _Entry([first]).coalesce(_Entry([second]))! as _Entry;
      await _Handler(target).undo(merged);

      expect(merged.changes, hasLength(1));
      expect(target.rows.rows['slide']!['s1']!['title'], 'A');
    });
  });

  group('Given sequential changes of one row', () {
    test('when an insert is followed by an update then one insert remains', () {
      final out = composeRowChanges([
        RowChange.insert('slide', 's1', {'n': 1, 't': 'a'}),
        RowChange.update('slide', 's1', {'t': 'a'}, {'t': 'b'}),
      ]);

      expect(out.single.op, RowOp.insert);
      expect(out.single.columnsAfter, containsPair('t', 'b'));
    });

    test('when an insert is followed by a delete then nothing remains', () {
      final out = composeRowChanges([
        RowChange.insert('slide', 's1', {'n': 1}),
        RowChange.insert('slide', 's2', {'n': 2}),
        RowChange.delete('slide', 's1', {'n': 1}),
      ]);

      expect(out.map((c) => c.rowId), ['s2']);
    });

    test('when an update is followed by a delete then the delete keeps the '
        'original values', () {
      final out = composeRowChanges([
        RowChange.update('slide', 's1', {'t': 'a'}, {'t': 'b'}),
        RowChange.delete('slide', 's1', {'t': 'b', 'n': 1}),
      ]);

      expect(out.single.op, RowOp.delete);
      expect(out.single.columnsBefore, containsPair('t', 'a'));
      expect(out.single.columnsBefore, containsPair('n', 1));
    });
  });
}
