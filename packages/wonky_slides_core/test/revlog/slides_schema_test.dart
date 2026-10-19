import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/revlog.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';

import '../support/planner_fixture.dart';

/// Schema guard (RevLog spec 02 §4, 08, 10 R1): the RevLog schema generated
/// from the `.spy.yaml` models accepts a full deck and the planner's output,
/// and the sequencer drops nothing once the op is ordered parents first.
void main() {
  group('Given the Slides RevLog schema', () {
    test(
      'when compared with the model tables then every synced table is in it',
      () {
        final expected = SlidesTables.dependencyOrder.toSet()
          ..remove(SlidesTables.deckChangeLog);
        expect(slidesSchema.tables.map((t) => t.name).toSet(), expected);
        expect(slidesSchema.root.name, SlidesTables.deck);
      },
    );

    test('when walking parents then parents of other tables rank lower', () {
      for (final t in slidesSchema.tables) {
        for (final p in t.parents) {
          expect(slidesSchema.tryTable(p.table), isNotNull);
          if (p.table == t.name) continue;
          expect(
            slidesSchema.rank(p.table),
            lessThan(slidesSchema.rank(t.name)),
            reason: '${t.name} → ${p.table}',
          );
        }
      }
    });
  });

  group('Given a full deck', () {
    late PlannerFixture f;
    late MapRowStore server;
    setUp(() {
      f = PlannerFixture();
      server = MapRowStore();
      final creation = parentsFirst(slidesSchema, [
        for (final (table, cols) in _ranked(f.rowsOf))
          RowChange.insert(table, cols['id']! as String, {
            for (final e in cols.entries)
              if (e.key != 'id') e.key: e.value,
          }),
      ]);
      validateChangeSet(
        slidesSchema,
        ChangeSet(clientOpId: _op, baseRevision: 0, changes: creation),
        fromClient: true,
        isCreation: true,
        fileUuid: testDeckId,
      );
      final r = applyChanges(slidesSchema, server, creation);
      expect(r.dropped, isEmpty, reason: 'the creation op keeps every row');
    });

    void validates(MemoryDeck deck, SlidesOperation op) {
      final before = deck.writes.length;
      deck.execute(op);
      final changes = parentsFirst(slidesSchema, [
        for (final w in deck.writes.skip(before)) ...w.changes,
      ]);
      final cs = ChangeSet(clientOpId: _op, baseRevision: 1, changes: changes);
      expect(
        () => validateChangeSet(
          slidesSchema,
          cs,
          fromClient: true,
          isCreation: false,
          fileUuid: testDeckId,
        ),
        returnsNormally,
        reason: op.name,
      );
      final codec = RevCodec(slidesSchema);
      // The wire form is stable (ids are row keys, date-times milliseconds).
      final wire = codec.encodeText(changes);
      expect(codec.encodeText(codec.decodeText(wire).changes), wire);
      final r = applyChangeSet(slidesSchema, server, cs);
      expect(r.dropped, isEmpty, reason: '${op.name}: ${r.dropped}');
    }

    test(
      'when running common operations then every op is valid and nothing is dropped',
      () {
        final deck = f.session();
        validates(deck, GroupElements([f.shape, f.shape2]));
        validates(deck, DuplicateSlides([f.s3]));
        validates(deck, DuplicateSlides([f.s2]));
        validates(
          deck,
          InsertElements(f.s2, const [
            ElementSpec(
              kind: ElementKind.shape,
              x: 10,
              y: 10,
              width: 50,
              height: 50,
            ),
          ]),
        );
      },
    );
  });
}

const _op = '0190f0b0-0000-7000-8000-0000000000aa';

/// [rows] in dependency order (parents first).
List<(String, Map<String, Object?>)> _ranked(
  List<(String, Map<String, Object?>)> rows,
) => [...rows]
  ..sort(
    (a, b) => SlidesTables.dependencyOrder
        .indexOf(a.$1)
        .compareTo(SlidesTables.dependencyOrder.indexOf(b.$1)),
  );
