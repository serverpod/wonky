import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

/// A deck-like schema whose elements nest (`parentId` → element).
final _schema = RevSchema('nest', const [
  RevTable('deck', [RevColumn('title', RevColumnType.string)], isRoot: true),
  RevTable(
    'element',
    [
      RevColumn('deckId', RevColumnType.uuid, immutable: true),
      RevColumn('parentId', RevColumnType.uuid, nullable: true),
      RevColumn('name', RevColumnType.string),
    ],
    parents: [
      RevParent('deckId', 'deck'),
      RevParent('parentId', 'element', optional: true),
    ],
    rank: 1,
  ),
]);

const _deck = '0190f0b0-0000-7000-8000-000000000001';
String _id(int n) =>
    '0190f0b0-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';

RowChange _el(int n, {int? parent}) => RowChange.insert('element', _id(n), {
  'deckId': _deck,
  'parentId': parent == null ? null : _id(parent),
  'name': 'e$n',
});

void main() {
  late MapRowStore store;
  setUp(() {
    store = MapRowStore();
    applyChanges(_schema, store, [
      RowChange.insert('deck', _deck, {'title': 'D'}),
    ]);
  });

  group('Given an op that creates nested elements', () {
    test(
      'when children come before their group then the group is moved before the first child',
      () {
        final changes = [
          _el(1, parent: 3),
          _el(2, parent: 3),
          _el(3, parent: 4),
          _el(4),
          _el(5),
        ];
        final ordered = parentsFirst(_schema, changes);
        expect(ordered.map((c) => c.rowId), [
          _id(4),
          _id(3),
          _id(1),
          _id(2),
          _id(5),
        ]);
        final r = applyChanges(_schema, store, ordered);
        expect(r.dropped, isEmpty);
        // Without the ordering, the sequencer drops the children.
        final raw = applyChanges(_schema, MapRowStore(), [
          RowChange.insert('deck', _deck, {'title': 'D'}),
          ...changes,
        ]);
        expect(raw.dropped, isNotEmpty);
      },
    );

    test(
      'when an update regroups into a new group then the group comes first',
      () {
        applyChanges(_schema, store, [_el(1)]);
        final changes = [
          RowChange.update(
            'element',
            _id(1),
            {'parentId': null},
            {'parentId': _id(9)},
          ),
          _el(9),
        ];
        final ordered = parentsFirst(_schema, changes);
        expect(ordered.first.rowId, _id(9));
        expect(applyChanges(_schema, store, ordered).dropped, isEmpty);
      },
    );

    test('when the order is already right then the same list is returned', () {
      final changes = [_el(4), _el(3, parent: 4), _el(1, parent: 3)];
      expect(identical(parentsFirst(_schema, changes), changes), isTrue);
    });
  });
}
