import 'package:test/test.dart';
import 'package:wonky_revlog/rows.dart';

void main() {
  group('Given row changes of each kind', () {
    final at = DateTime.utc(2026, 10, 15, 12);
    final insert = RowChange.insert('slide', 's1', {'title': 'A', 'at': at});
    final update = RowChange.update(
      'slide',
      's1',
      {'title': 'A'},
      {'title': 'B'},
    );
    final delete = RowChange.delete('slide', 's1', {'title': 'B'});

    test('when inserting then the id column is part of the new row', () {
      expect(insert.columnsAfter, {'title': 'A', 'at': at, 'id': 's1'});
      expect(insert.touchedColumns, {'title', 'at', 'id'});
    });

    test('when inverting then insert and delete swap and an update swaps '
        'its columns', () {
      expect(insert.inverse().op, RowOp.delete);
      expect(insert.inverse().columnsBefore, insert.columnsAfter);
      expect(delete.inverse().op, RowOp.insert);
      expect(update.inverse().columnsAfter, {'title': 'A'});
      expect(update.inverse().columnsBefore, {'title': 'B'});
    });

    test('when encoded as JSON and decoded then the change is equal, times '
        'included', () {
      for (final c in [insert, update, delete]) {
        expect(RowChange.fromJson(c.toJson()), c);
      }
      expect(RowChange.fromJson(insert.toJson()).columnsAfter['at'], at);
    });
  });
}
