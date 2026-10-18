import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

import '../support/planner_fixture.dart';

RowChange _change(SlidesPlan p, String table, String id) =>
    p.changes.firstWhere((c) => c.table == table && c.rowId == id);

SlideElementRec _instance(DeckModel m, String slide, SlidePlaceholderType t) =>
    m.elementsOf(slide).firstWhere((e) => e.placeholderType == t);

void main() {
  final f = PlannerFixture();
  late MemoryDeck deck;
  setUp(() => deck = f.session());

  group('Given an empty model', () {
    test('when creating a 4:3 deck then the theme copy has deterministic ids, '
        'the geometry of the size and a title slide with its instances', () {
      final d = MemoryDeck(
        model: DeckModel(deckId: testDeckId),
        userId: testUserId,
        planner: const SlidesPlanner(),
        ids: SequentialIdGenerator(1),
      );

      final plan = d.execute(
        const CreateDeck(
          deckId: testDeckId,
          title: '  Pitch ',
          size: SlideSize(SlideSizeKind.standard4x3, 1440, 1080),
        ),
      );

      final m = d.model;
      final def = BuiltInThemes.defaultTheme;
      final themeId = SlidesIds.themeCopyId(
        testDeckId,
        SlidesIds.builtinThemeSourceKey(def.key, def.version),
      );
      expect(m.deck!.title, 'Pitch');
      expect(m.deck!.themeId, themeId);
      expect((m.deck!.width, m.deck!.height), (1440.0, 1080.0));
      final slide = m.slides.single;
      expect(m.layout(slide.layoutId!)!.key, 'title');
      final instances = m.elementsOf(slide.id);
      expect(instances, isNotEmpty);
      for (final e in instances) {
        expect(
          e.id,
          SlidesIds.placeholderInstanceId(slide.id, e.placeholderOf!),
        );
        expect(e.frame, isNull);
      }
      final layoutTitle = m.element(
        _instance(m, slide.id, SlidePlaceholderType.title).placeholderOf!,
      )!;
      expect(layoutTitle.frame!.right, lessThanOrEqualTo(1440));
      expect(plan.label, 'Create presentation');
      expect(plan.result['slideIds'], [slide.id]);
    });

    test('when the deck exists then creating it again is refused', () {
      expect(
        () => deck.execute(const CreateDeck(deckId: testDeckId, title: 'X')),
        throwsA(
          isA<PlanException>().having(
            (e) => e.code,
            'code',
            'invalid_argument',
          ),
        ),
      );
    });
  });

  group('Given slides and groups', () {
    test('when adding a slide after a grouped slide then it lands in the '
        'group right after it with the layout of that slide', () {
      final plan = deck.execute(AddSlides(afterSlideId: f.g1));

      final id = (plan.result['slideIds']! as List).single as String;
      final s = deck.model.slide(id)!;
      expect(s.groupId, f.group);
      expect(deck.model.slidesInGroup(f.group).map((x) => x.id), [
        f.g1,
        id,
        f.g2,
      ]);
      expect(s.layoutId, deck.model.slide(f.g1)!.layoutId);
    });

    test('when adding after the title slide then the new slide uses Title '
        'and content', () {
      final plan = deck.execute(AddSlides(afterSlideId: f.title));

      final id = (plan.result['slideIds']! as List).single as String;
      expect(
        deck.model.layout(deck.model.slide(id)!.layoutId!)!.key,
        'titleBody',
      );
    });

    test('when the slide limit would be exceeded then nothing is planned', () {
      final small = MemoryDeck(
        model: deck.model,
        userId: testUserId,
        planner: const SlidesPlanner(),
        limits: const SlidesLimits(maxSlidesPerDeck: 6),
      );

      expect(
        () => small.execute(const AddSlides(count: 2)),
        throwsA(
          isA<PlanException>()
              .having((e) => e.code, 'code', PlanException.limit)
              .having(
                (e) => e.message,
                'message',
                'A presentation can have at most 6 slides.',
              ),
        ),
      );
    });

    test('when moving a slide within its key space then groupId and sortKey '
        'are written together (02 P4)', () {
      final plan = deck.execute(MoveSlides([f.title], TopLevel(afterId: f.s3)));

      final c = _change(plan, SlidesTables.slide, f.title);
      expect(c.columnsAfter.keys.toSet(), {
        SlideCols.groupId,
        SlidesCols.sortKey,
      });
      expect(deck.model.slides.map((s) => s.id).take(3), [f.s2, f.s3, f.title]);
    });

    test('when duplicating a slide then the copy follows it with fresh ids, '
        'recomputed deterministic ids and the same match keys', () {
      final plan = deck.execute(DuplicateSlides([f.s2]));

      final copy = (plan.result['slideIds']! as List).single as String;
      final m = deck.model;
      expect(
        m.slides.map((s) => s.id).toList().indexOf(copy),
        m.slides.map((s) => s.id).toList().indexOf(f.s2) + 1,
      );
      final src = {for (final e in m.allElementsOf(f.s2)) e.matchKey};
      final dst = m.allElementsOf(copy).toList();
      expect({for (final e in dst) e.matchKey}, src);
      for (final e in dst.where((e) => e.placeholderOf != null)) {
        expect(e.id, SlidesIds.placeholderInstanceId(copy, e.placeholderOf!));
      }
      final table = dst.firstWhere((e) => e.kind == ElementKind.table);
      for (final c in m.cellsOf(table.id)) {
        expect(c.id, SlidesIds.tableCellId(table.id, c.rowId!, c.columnId!));
      }
      final chart = dst.firstWhere((e) => e.kind == ElementKind.chart);
      expect(m.chartLinkOf(chart.id)!.id, SlidesIds.chartLinkId(chart.id));
      final code = dst.firstWhere((e) => e.kind == ElementKind.code);
      expect(m.codeStatesOf(code.id), hasLength(2));
    });

    test('when deleting a slide then its elements and every dependent row '
        'are listed in the plan', () {
      final plan = deck.execute(DeleteSlides([f.s2]));

      final deleted = {
        for (final c in plan.changes)
          if (c.op == RowOp.delete) c.table,
      };
      expect(
        deleted,
        containsAll([
          SlidesTables.slide,
          SlidesTables.slideElement,
          SlidesTables.slideTableAxis,
          SlidesTables.slideTableCell,
          SlidesTables.codeState,
          SlidesTables.chartLink,
        ]),
      );
      expect(plan.summary.deleted['slides'], {f.s2});
    });

    test('when grouping two slides then the group takes the first slide\'s '
        'place and holds them in order', () {
      final plan = deck.execute(CreateGroup([f.s3, f.s2], title: 'Intro'));

      final g = plan.result['groupId']! as String;
      expect(deck.model.slidesInGroup(g).map((s) => s.id), [f.s2, f.s3]);
      expect(deck.model.slides.map((s) => s.id).take(3), [f.title, f.s2, f.s3]);
    });

    test('when grouping a slide of a group at a target then the new group '
        'goes right after that group (one level, 04 §5.6)', () {
      final plan = deck.execute(CreateGroup([f.g1], target: InGroup(f.group)));

      final g = plan.result['groupId']! as String;
      final top = deck.model.indexes.order.topLevel.map((t) => t.id).toList();
      expect(top.indexOf(g), top.indexOf(f.group) + 1);
      expect(deck.model.slidesInGroup(g).map((s) => s.id), [f.g1]);
    });

    test('when creating an empty group at the end then it has no slides and '
        'the lowest free default title', () {
      final plan = deck.execute(const CreateGroup([], target: TopLevel()));

      final g = deck.model.group(plan.result['groupId']! as String)!;
      expect(deck.model.slidesInGroup(g.id), isEmpty);
      expect(deck.model.indexes.order.topLevel.last.id, g.id);
      expect(g.title, startsWith('Group '));
    });

    test(
      'when ungrouping then the slides keep their place in the top level',
      () {
        deck.execute(Ungroup(f.group));

        expect(deck.model.slides.map((s) => s.id), [
          f.title,
          f.s2,
          f.s3,
          f.g1,
          f.g2,
        ]);
        expect(deck.model.group(f.group), isNull);
      },
    );

    test(
      'when skipping a group then its slides are skipped and unnumbered',
      () {
        deck.execute(SetGroupProps([f.group], skipped: true));

        final order = deck.model.indexes.order;
        expect(order.entry(f.g1)!.skipped, isTrue);
        expect(order.entry(f.g1)!.number, isNull);
        expect(order.entry(f.s3)!.number, 3);
      },
    );
  });

  group('Given a Title and content slide', () {
    test('when applying the Title layout then title is re-pointed, the body '
        'with content is materialized and a subtitle instance is created', () {
      final before = deck.model;
      final body = _instance(before, f.s2, SlidePlaceholderType.body);
      final title = _instance(before, f.s2, SlidePlaceholderType.title);

      deck.execute(SetSlideProps([f.s2], layoutId: f.layout('title')));

      final m = deck.model;
      final t = m.element(title.id)!;
      expect(m.element(t.placeholderOf!)!.layoutId, f.layout('title'));
      final b = m.element(body.id)!;
      expect(b.placeholderType, isNull);
      expect(b.placeholderOf, isNull);
      expect(b.frame, isNotNull);
      expect(b.text, body.text);
      final sub = _instance(m, f.s2, SlidePlaceholderType.subtitle);
      expect(sub.id, SlidesIds.placeholderInstanceId(f.s2, sub.placeholderOf!));
    });

    test('when resetting the slide then the moved title inherits again', () {
      final title = _instance(deck.model, f.s2, SlidePlaceholderType.title);
      expect(title.frame, isNotNull);

      deck.execute(ResetSlideToLayout([f.s2]));

      expect(deck.model.element(title.id)!.frame, isNull);
    });
  });

  group('Given elements on a slide', () {
    test('when moving an element then x and y are written together and the '
        'rest of the frame is untouched', () {
      final plan = deck.execute(UpdateFrames([FrameUpdate(f.shape, x: 250)]));

      final c = _change(plan, SlidesTables.slideElement, f.shape);
      expect(c.columnsAfter, {ElementCols.x: 250.0, ElementCols.y: 100.0});
      expect(plan.label, 'Move');
    });

    test('when moving a placeholder instance then all four frame columns are '
        'materialized (05 §5.2)', () {
      final body = _instance(deck.model, f.g1, SlidePlaceholderType.body);
      final plan = deck.execute(UpdateFrames([FrameUpdate(body.id, y: 300)]));

      final c = _change(plan, SlidesTables.slideElement, body.id);
      expect(c.columnsAfter.keys.toSet(), {...ElementCols.frame});
      expect(c.columnsAfter[ElementCols.y], 300.0);
    });

    test('when rotating past 360° then the rotation is normalized', () {
      deck.execute(UpdateFrames([FrameUpdate(f.shape, rotation: -30)]));

      expect(deck.model.element(f.shape)!.rotation, 330.0);
    });

    test('when moving a locked element then the plan is refused', () {
      deck.execute(SetElementProps([f.shape], locked: true));

      expect(
        () => deck.execute(UpdateFrames([FrameUpdate(f.shape, x: 1)])),
        throwsA(
          isA<PlanException>().having(
            (e) => e.code,
            'code',
            PlanException.locked,
          ),
        ),
      );
    });

    test('when bringing a shape to front then it is the last sibling and '
        'only its zKey is written', () {
      final plan = deck.execute(ReorderZ([f.shape], ZOrderOp.toFront));

      expect(deck.model.elementsOf(f.s3).last.id, f.shape);
      expect(
        _change(plan, SlidesTables.slideElement, f.shape).columnsAfter.keys,
        [ElementCols.zKey],
      );
    });

    test('when bringing a shape forward then it passes the next overlapping '
        'sibling above it', () {
      // shape (100..400) overlaps nothing above but text box (y 500) — the
      // adjacent sibling is used then.
      final order = deck.model.elementsOf(f.s3).map((e) => e.id).toList();
      final next = order[order.indexOf(f.shape) + 1];

      deck.execute(ReorderZ([f.shape], ZOrderOp.forward));

      final after = deck.model.elementsOf(f.s3).map((e) => e.id).toList();
      expect(after.indexOf(f.shape), after.indexOf(next) + 1);
    });

    test(
      'when aligning left then every box starts at the selection\'s left',
      () {
        deck.execute(
          AlignDistribute([f.shape, f.shape2, f.text], AlignMode.left),
        );

        for (final id in [f.shape, f.shape2, f.text]) {
          expect(deck.model.element(id)!.x, 100.0);
        }
      },
    );

    test('when distributing horizontally then the gaps are equal', () {
      deck.execute(UpdateFrames([FrameUpdate(f.text, x: 1500, y: 500)]));
      deck.execute(
        AlignDistribute([f.shape, f.shape2, f.text], AlignMode.distributeH),
      );

      final m = deck.model;
      final a = m.element(f.shape)!,
          b = m.element(f.shape2)!,
          c = m.element(f.text)!;
      final gap1 = b.x! - (a.x! + a.width!);
      final gap2 = c.x! - (b.x! + b.width!);
      expect(gap1, closeTo(gap2, 1e-9));
    });

    test('when grouping two shapes then the group spans their union and the '
        'resolved frames are unchanged', () {
      deck.execute(UpdateFrames([FrameUpdate(f.shape2, rotation: 30)]));
      final resolver = SlideResolver(deck.model);
      final before = {
        for (final id in [f.shape, f.shape2])
          id: resolver.resolve(f.s3)!.element(id)!.frame,
      };

      final plan = deck.execute(GroupElements([f.shape, f.shape2]));

      final g = deck.model.element(plan.result['groupId']! as String)!;
      expect(g.kind, ElementKind.group);
      expect(deck.model.element(f.shape)!.parentId, g.id);
      final after = SlideResolver(deck.model).resolve(f.s3)!;
      for (final id in [f.shape, f.shape2]) {
        _expectRect(after.element(id)!.frame, before[id]!);
      }
    });

    test('when ungrouping a scaled, rotated group then each child keeps its '
        'resolved frame', () {
      deck.execute(
        UpdateFrames([
          FrameUpdate(
            f.grp,
            x: 900,
            y: 50,
            width: 600,
            height: 300,
            rotation: 90,
          ),
        ]),
      );
      final before = SlideResolver(deck.model).resolve(f.s3)!;
      final expected = {
        for (final id in [f.child1, f.child2]) id: before.element(id)!,
      };

      deck.execute(UngroupElements([f.grp]));

      final m = deck.model;
      expect(m.element(f.grp), isNull);
      for (final id in [f.child1, f.child2]) {
        final e = m.element(id)!;
        expect(e.parentId, isNull);
        _expectRect(e.frame!, expected[id]!.frame);
        expect(e.rotation, closeTo(expected[id]!.rotation, 1e-6));
      }
    });

    test('when deleting both children of a group then the group goes too', () {
      deck.execute(DeleteElements([f.child1, f.child2]));

      expect(deck.model.element(f.grp), isNull);
    });

    test('when ungrouping a group with builds then the builds are removed '
        'with a warning', () {
      deck.execute(
        AddBuilds(f.s3, [
          BuildSpec(
            elementId: f.grp,
            kind: SlideBuildKind.buildIn,
            effect: 'fade',
            durationMs: 300,
          ),
        ]),
      );

      final plan = deck.execute(UngroupElements([f.grp]));

      expect(plan.warnings, ['Ungrouping removed 1 animation']);
      expect(
        deck.model.buildsOf(f.s3).where((b) => b.elementId == f.grp),
        isEmpty,
      );
    });

    test('when the elements per slide limit would be exceeded then insert is '
        'refused', () {
      final small = MemoryDeck(
        model: deck.model,
        userId: testUserId,
        planner: const SlidesPlanner(),
        limits: const SlidesLimits(maxElementsPerOwner: 6),
      );

      expect(
        () => small.execute(
          InsertElements(f.s3, const [
            ElementSpec(
              kind: ElementKind.shape,
              x: 0,
              y: 0,
              width: 1,
              height: 1,
            ),
          ]),
        ),
        throwsA(
          isA<PlanException>().having(
            (e) => e.message,
            'message',
            "This slide can't hold more than 6 objects.",
          ),
        ),
      );
    });
  });

  group('Given text bodies', () {
    test('when setting text then it is normalized to the Slides schema', () {
      deck.execute(
        SetText(
          ElementText(f.text),
          jsonEncode([
            {
              'insert': 'Hi',
              'attributes': {'bold': true, 'unknown': 1, 'size': 2000},
            },
            {'insert': '\tthere'},
          ]),
        ),
      );

      expect(jsonDecode(deck.model.element(f.text)!.text!), [
        {
          'insert': 'Hi',
          'attributes': {'bold': true, 'size': 800},
        },
        {'insert': '    there\n'},
      ]);
    });

    test('when setting notes then only the notes subset survives', () {
      deck.execute(
        SetText(
          NotesText(f.s3),
          jsonEncode([
            {
              'insert': 'A',
              'attributes': {'bold': true, 'size': 40},
            },
            {
              'insert': '\n',
              'attributes': {'list': 'bullet', 'align': 'center'},
            },
          ]),
        ),
      );

      expect(jsonDecode(deck.model.slide(f.s3)!.notes!), [
        {
          'insert': 'A',
          'attributes': {'bold': true},
        },
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
      ]);
    });

    test('when text is too long then the plan is refused', () {
      expect(
        () => deck.execute(SetText(ElementText(f.text), deltaOf('x' * 20001))),
        throwsA(
          isA<PlanException>().having(
            (e) => e.code,
            'code',
            PlanException.limit,
          ),
        ),
      );
    });

    test('when formatting a range then inline attributes cover the range and '
        'block attributes the paragraph', () {
      deck.execute(
        FormatText(
          [ElementText(f.text)],
          const {'bold': true, 'align': 'center'},
          start: 0,
          length: 3,
        ),
      );

      expect(jsonDecode(deck.model.element(f.text)!.text!), [
        {
          'insert': 'Cap',
          'attributes': {'bold': true},
        },
        {'insert': 'tion'},
        {
          'insert': '\n',
          'attributes': {'align': 'center'},
        },
      ]);
    });

    test('when typing then the change log detail holds before and after', () {
      final plan = deck.execute(SetText(ElementText(f.text), deltaOf('New')));

      final texts = plan.detail!['texts']! as List;
      expect(texts.single, containsPair('after', deltaOf('New')));
      expect(texts.single, containsPair('before', deltaOf('Caption')));
    });
  });

  group('Given a 3 × 3 table with a 2 × 2 merge at B2', () {
    final merge = SlidesIds.tableCellId(f.table, f.rows[1], f.cols[1]);

    test('when inserting a row inside the merge then the merge grows', () {
      deck.execute(InsertTableAxes(f.table, TableAxisDimension.row, 2));

      final c =
          deck.model.record(SlidesTables.slideTableCell, merge)!
              as SlideTableCellRec;
      expect((c.rowSpan, c.colSpan), (3, 2));
    });

    test('when deleting a column of the merge then the merge shrinks', () {
      deck.execute(DeleteTableAxes(f.table, [f.cols[2]]));

      final c =
          deck.model.record(SlidesTables.slideTableCell, merge)!
              as SlideTableCellRec;
      expect((c.rowSpan, c.colSpan), (2, 1));
    });

    test('when clearing every value of a cell then its row is deleted', () {
      final a1 = SlidesIds.tableCellId(f.table, f.rows[0], f.cols[0]);

      deck.execute(SetText(CellText(f.table, f.rows[0], f.cols[0]), null));

      expect(deck.model.record(SlidesTables.slideTableCell, a1), isNull);
    });

    test(
      'when merging over an existing merge then the old one is dissolved',
      () {
        deck.execute(
          MergeCells(
            f.table,
            rowId: f.rows[0],
            columnId: f.cols[0],
            rowSpan: 2,
            colSpan: 2,
          ),
        );

        final t = deck.model.indexes.table(f.table);
        expect(
          t.merges.single.origin.id,
          SlidesIds.tableCellId(f.table, f.rows[0], f.cols[0]),
        );
        expect(t.overlapping, isEmpty);
      },
    );

    test(
      'when the table would exceed 20 columns then the insert is refused',
      () {
        expect(
          () => deck.execute(
            InsertTableAxes(f.table, TableAxisDimension.column, 0, count: 18),
          ),
          throwsA(
            isA<PlanException>().having(
              (e) => e.code,
              'code',
              PlanException.limit,
            ),
          ),
        );
      },
    );
  });

  group('Given themes', () {
    test('when importing the same built-in theme twice then the second import '
        'changes nothing (deterministic copy)', () {
      deck.execute(const ImportTheme(builtInKey: 'swiss'));

      final again = deck.execute(const ImportTheme(builtInKey: 'swiss'));

      expect(again.isEmpty, isTrue);
    });

    test('when applying a theme to one slide then its layout is matched by '
        'key and the deck default stays', () {
      final swiss =
          deck
                  .execute(const ImportTheme(builtInKey: 'swiss'))
                  .result['themeId']!
              as String;

      deck.execute(ApplyThemeToSlides(swiss, [f.s2]));

      final m = deck.model;
      final l = m.layout(m.slide(f.s2)!.layoutId!)!;
      expect(l.key, 'titleBody');
      expect(m.indexes.themes.themeOfLayout(l)!.id, swiss);
      expect(m.deck!.themeId, f.themeId);
    });

    test('when removing a theme in use then it is refused with the usage', () {
      expect(
        () => deck.execute(DeleteTheme(f.themeId)),
        throwsA(
          isA<PlanException>().having(
            (e) => e.message,
            'message',
            startsWith('Used by 5 slides'),
          ),
        ),
      );
    });

    test('when deleting a layout in use then it is refused', () {
      expect(
        () => deck.execute(DeleteMastersOrLayouts([f.layout('title')])),
        throwsA(
          isA<PlanException>().having(
            (e) => e.message,
            'message',
            startsWith('Used by 1 slide '),
          ),
        ),
      );
    });

    test('when an invalid theme column is written then the validator errors '
        'are returned', () {
      expect(
        () => deck.execute(
          UpdateTheme(f.themeId, columns: const {'colorsJson': '{"v":1}'}),
        ),
        throwsA(
          isA<PlanException>().having(
            (e) => e.details['column'],
            'column',
            'colorsJson',
          ),
        ),
      );
    });
  });

  group('Given clipboard payloads', () {
    test('when pasting elements onto their own slide then they are offset by '
        '32 su with new match keys', () {
      final payload = clipboardOf(
        deck.model,
        kind: 'elements',
        elementIds: [f.shape],
        sourceSlideId: f.s3,
      );

      final plan = deck.execute(PasteElements(payload, f.s3));

      final copy = deck.model.element(
        (plan.result['elementIds']! as List).single as String,
      )!;
      expect((copy.x, copy.y), (132.0, 132.0));
      expect(copy.matchKey, isNot(deck.model.element(f.shape)!.matchKey));
      expect(deck.model.elementsOf(f.s3).last.id, copy.id);
    });

    test('when pasting a shape onto a layout (master mode, SL-28) then the '
        'copy is owned by the layout and builds are dropped', () {
      final layout = f.layout('titleBody');
      final payload = clipboardOf(
        deck.model,
        kind: 'elements',
        elementIds: [f.shape],
        sourceSlideId: f.s3,
      );

      final plan = deck.execute(
        PasteElements(payload, layout, ownerKind: ElementOwnerKind.layout),
      );

      final copy = deck.model.element(
        (plan.result['elementIds']! as List).single as String,
      )!;
      expect(copy.layoutId, layout);
      expect(copy.slideId, isNull);
      expect(deck.model.buildsOf(layout), isEmpty);
    });

    test('when pasting slides from another deck then layouts map to the '
        'destination theme by key', () {
      final payload = clipboardOf(
        deck.model,
        kind: 'slides',
        slideIds: [f.s2],
        sourceDeckId: '00000000-0000-4000-8000-00000000dddd',
      );
      payload['slides'] = [
        {
          ...(payload['slides']! as List).single as Map<String, Object?>,
          'layoutId': '00000000-0000-4000-8000-00000000eeee',
        },
      ];

      final plan = deck.execute(PasteSlides(payload, afterSlideId: f.title));

      final id = (plan.result['slideIds']! as List).single as String;
      final s = deck.model.slide(id)!;
      expect(deck.model.layout(s.layoutId!)!.key, 'titleBody');
      expect(deck.model.slides[1].id, id);
      for (final e
          in deck.model.elementsOf(id).where((e) => e.placeholderOf != null)) {
        expect(deck.model.element(e.placeholderOf!)!.layoutId, s.layoutId);
      }
    });

    test('when pasting with Keep source formatting then the source theme is '
        'copied with deterministic ids once', () {
      final source = '00000000-0000-4000-8000-00000000dddd';
      Map<String, Object?> payload() => clipboardOf(
        deck.model,
        kind: 'slides',
        slideIds: [f.s2],
        withThemes: true,
        sourceDeckId: source,
      );

      deck.execute(
        PasteSlides(payload(), themeMode: PasteThemeMode.keepSource),
      );
      final themes = deck.model.themes.length;
      deck.execute(
        PasteSlides(payload(), themeMode: PasteThemeMode.keepSource),
      );

      final copy = SlidesIds.themeCopyId(
        testDeckId,
        SlidesIds.deckThemeSourceKey(source, f.themeId),
      );
      expect(deck.model.theme(copy), isNotNull);
      expect(deck.model.themes.length, themes);
    });
  });
}

void _expectRect(SuRect a, SuRect b) {
  expect(a.x, closeTo(b.x, 1e-6));
  expect(a.y, closeTo(b.y, 1e-6));
  expect(a.width, closeTo(b.width, 1e-6));
  expect(a.height, closeTo(b.height, 1e-6));
}
