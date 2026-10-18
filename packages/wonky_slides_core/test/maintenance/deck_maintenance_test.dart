import 'package:test/test.dart';
import 'package:wonky_slides_core/maintenance.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

import '../support/planner_fixture.dart';

/// Two clients on the planner fixture, connected and in sync.
final class _Pair {
  _Pair(PlannerFixture f) {
    a = relay.connect('A', f.session(seed: 100000));
    b = relay.connect('B', f.session(seed: 200000, userId: testUserId2));
    relay.sync();
  }

  final relay = LwwSyncRelay();
  late final RelayClient a, b;

  /// Runs [opA] on A and [opB] on B while both are offline, then syncs.
  void concurrently(SlidesOperation opA, SlidesOperation opB) {
    a.online = b.online = false;
    a.deck.execute(opA);
    b.deck.execute(opB);
    a.online = b.online = true;
    relay.sync();
  }

  /// Both clients repair what they detect (while offline from each other),
  /// then sync.
  void repairBoth() {
    a.online = b.online = false;
    for (final c in [a, b]) {
      final op = DeckMaintenance.repairOp(c.deck.model);
      if (op != null) c.deck.execute(op);
    }
    a.online = b.online = true;
    relay.sync();
  }

  Set<String> rules(RelayClient c) => {
    for (final v in DeckMaintenance.detect(c.deck.model)) v.rule,
  };
}

void main() {
  final f = PlannerFixture();

  test('Given the fixture when detecting then there is nothing to repair', () {
    expect(DeckMaintenance.detect(f.session().model), isEmpty);
    expect(DeckMaintenance.repairOp(f.session().model), isNull);
  });

  group('Given two replicas with concurrent edits', () {
    late _Pair p;
    setUp(() => p = _Pair(f));

    void expectConverged({required String rule}) {
      expect(p.rules(p.a), contains(rule), reason: 'A detects $rule');
      expect(p.rules(p.b), contains(rule), reason: 'B detects $rule');

      p.repairBoth();

      expect(p.a.deck.model.dump(), p.b.deck.model.dump());
      expect(p.a.deck.model.dump(), p.relay.dump());
      expect(DeckMaintenance.detect(p.a.deck.model), isEmpty);
      // Repairing again changes nothing (idempotent).
      final again = DeckMaintenance.repairOp(p.a.deck.model);
      expect(again, isNull);
    }

    test('when A moves a slide into a group B deletes then the orphan goes to '
        'the end of the top level on both', () {
      p.concurrently(
        MoveSlides([f.title], InGroup(f.group)),
        DeleteGroups([f.group]),
      );

      expectConverged(rule: DeckMaintenance.orphanSlide);
      final m = p.a.deck.model;
      expect(m.slide(f.title)!.groupId, isNull);
      expect(m.slides.last.id, f.title);
    });

    test('when A and B delete the two children of a group then the empty '
        'group is deleted', () {
      p.concurrently(DeleteElements([f.child1]), DeleteElements([f.child2]));

      expectConverged(rule: DeckMaintenance.emptyGroup);
      expect(p.a.deck.model.element(f.grp), isNull);
    });

    test('when A and B merge overlapping ranges then the merge with the '
        'larger origin id is cleared', () {
      final a1 = SlidesIds.tableCellId(f.table, f.rows[0], f.cols[0]);
      final b2 = SlidesIds.tableCellId(f.table, f.rows[1], f.cols[1]);
      p.concurrently(UnmergeCells(f.table, [b2]), UnmergeCells(f.table, [b2]));
      p.concurrently(
        MergeCells(
          f.table,
          rowId: f.rows[0],
          columnId: f.cols[0],
          rowSpan: 2,
          colSpan: 2,
        ),
        MergeCells(
          f.table,
          rowId: f.rows[1],
          columnId: f.cols[1],
          rowSpan: 2,
          colSpan: 2,
        ),
      );

      expectConverged(rule: DeckMaintenance.mergeOverlap);
      final t = p.a.deck.model.indexes.table(f.table);
      final winner = a1.compareTo(b2) < 0 ? a1 : b2;
      expect(t.merges.single.origin.id, winner);
    });

    test('when A and B each delete one of two code states then an empty '
        'state with a deterministic id is inserted', () {
      p.concurrently(
        DeleteCodeStates([f.states[0]]),
        DeleteCodeStates([f.states[1]]),
      );

      expectConverged(rule: DeckMaintenance.codeWithoutState);
      final states = p.a.deck.model.codeStatesOf(f.code);
      expect(states.single.id, DeckMaintenance.repairCodeStateId(f.code));
      expect(states.single.code, '');
    });

    test(
      'when A deletes a shape B animates then the orphan build is deleted',
      () {
        p.concurrently(
          DeleteElements([f.shape2]),
          AddBuilds(f.s3, [
            BuildSpec(
              elementId: f.shape2,
              kind: SlideBuildKind.buildIn,
              effect: 'fade',
              durationMs: 300,
            ),
          ]),
        );

        expectConverged(rule: DeckMaintenance.orphanBuild);
        expect(
          p.a.deck.model.buildsOf(f.s3).where((b) => b.elementId == f.shape2),
          isEmpty,
        );
      },
    );

    test('when A deletes a layout B applies then the instances are '
        'materialized and re-pointed where possible', () {
      final quote = f.layout('quote');
      p.concurrently(
        DeleteMastersOrLayouts([quote]),
        SetSlideProps([f.s3], layoutId: quote),
      );

      expect(p.rules(p.a), contains(DeckMaintenance.danglingPlaceholder));
      p.repairBoth();

      expect(p.a.deck.model.dump(), p.b.deck.model.dump());
      expect(DeckMaintenance.detect(p.a.deck.model), isEmpty);
      final m = p.a.deck.model;
      for (final e in m.elementsOf(f.s3)) {
        if (e.placeholderType == null) continue;
        expect(e.frame, isNotNull);
        expect(m.indexes.placeholders.isDangling(e), isFalse);
      }
    });
  });

  group('Given rows a merge could leave behind', () {
    late MemoryDeck deck;
    setUp(() => deck = f.session());

    void raw(List<RowChange> changes) => deck.applyRemote(changes);

    void repair() {
      final op = DeckMaintenance.repairOp(deck.model);
      if (op != null) deck.execute(op);
    }

    test('when two instances point at one layout placeholder then the '
        'deterministic one keeps the link and the other keeps its content', () {
      final title = deck.model
          .elementsOf(f.g1)
          .firstWhere((e) => e.placeholderType?.name == 'title');
      const extra = '00000000-0000-4000-8000-00000000abcd';
      raw([
        RowChange.insert(SlidesTables.slideElement, extra, {
          ...title.toColumns(),
          SlidesCols.id: extra,
          SlidesCols.text: deltaOf('Mine'),
          ElementCols.zKey: 'a9',
        }),
      ]);
      expect(DeckMaintenance.detect(deck.model).map((v) => v.rule), [
        DeckMaintenance.dupPlaceholder,
      ]);

      repair();

      final m = deck.model;
      expect(m.element(title.id)!.placeholderOf, title.placeholderOf);
      expect(m.element(extra)!.placeholderOf, isNull);
      expect(m.element(extra)!.frame, isNotNull);
      expect(m.element(extra)!.text, deltaOf('Mine'));
      expect(DeckMaintenance.detect(m), isEmpty);
    });

    test('when an element group cycle exists then the member with the '
        'smallest id becomes top-level', () {
      const inner = '00000000-0000-4000-8000-00000000fff2';
      raw([
        RowChange.insert(SlidesTables.slideElement, inner, {
          ...deck.model.element(f.grp)!.toColumns(),
          SlidesCols.id: inner,
          SlidesCols.parentId: f.grp,
        }),
        RowChange.update(
          SlidesTables.slideElement,
          f.grp,
          {SlidesCols.parentId: null},
          {SlidesCols.parentId: inner},
        ),
      ]);
      final tree = deck.model.indexes.tree(f.s3);
      expect(tree.cycleBreakers, {f.grp});
      expect(tree.roots.map((e) => e.id), contains(f.grp));

      repair();

      expect(deck.model.element(f.grp)!.parentId, isNull);
      expect(DeckMaintenance.detect(deck.model), isEmpty);
    });

    test('when a child points at a group of another slide then it is '
        're-parented to the top level', () {
      final shape = deck.model
          .elementsOf(f.s2)
          .firstWhere((e) => e.kind == ElementKind.image);
      raw([
        RowChange.update(
          SlidesTables.slideElement,
          shape.id,
          {SlidesCols.parentId: null},
          {SlidesCols.parentId: f.grp},
        ),
      ]);
      expect(deck.model.indexes.tree(f.s2).foreignParent, {shape.id});

      repair();

      expect(deck.model.element(shape.id)!.parentId, isNull);
    });

    test('when Deck.themeId is missing then it is written to the smallest '
        'theme id', () {
      raw([
        RowChange.update(
          SlidesTables.deck,
          testDeckId,
          {DeckCols.themeId: f.themeId},
          {DeckCols.themeId: null},
        ),
      ]);

      repair();

      final ids = [for (final t in deck.model.themes) t.id]..sort();
      expect(deck.model.deck!.themeId, ids.first);
    });

    test('when every layout is gone then the built-in default is copied back '
        'with deterministic ids', () {
      raw([
        for (final r in deck.model.records(SlidesTables.slideLayout))
          RowChange.delete(SlidesTables.slideLayout, r.id, r.toColumns()),
      ]);
      expect(
        DeckMaintenance.detect(deck.model).first.rule,
        DeckMaintenance.noTheme,
      );

      repair();

      final m = deck.model;
      expect(m.indexes.themes.layoutsOfTheme(m.deck!.themeId!), isNotEmpty);
      expect(
        DeckMaintenance.detect(m).map((v) => v.rule),
        isNot(contains(DeckMaintenance.noTheme)),
      );
    });
  });
}
