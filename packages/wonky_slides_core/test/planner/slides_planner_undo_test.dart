import 'package:test/test.dart';
import 'package:wonky_slides_core/maintenance.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart';

import '../support/planner_fixture.dart';

/// Every operation of 02 §12.1 against the planner fixture.
List<(String, SlidesOperation)> _cases(PlannerFixture f, DeckModel m) {
  final layoutTitle = f.layout('title');
  final layoutTwo = f.layouts.entries.firstWhere(
    (e) => e.key != 'title' && e.key != 'titleBody' && e.key != 'blank',
  );
  final merge = SlidesIds.tableCellId(f.table, f.rows[1], f.cols[1]);
  return [
    // Deck.
    ('rename the deck', const SetDeckProps(title: 'Renamed')),
    (
      'change numbering, footer and appearance',
      const SetDeckProps(
        showSlideNumbers: true,
        firstSlideNumber: 3,
        footerText: Patch('Confidential'),
        appearance: SlideAppearance.dark,
        language: Patch('de'),
      ),
    ),
    (
      'resize the deck scaling content',
      const SetDeckProps(
        size: DeckSizeChange(SlideSize(SlideSizeKind.standard4x3, 1440, 1080)),
      ),
    ),
    (
      'resize the deck keeping frames',
      const SetDeckProps(
        size: DeckSizeChange(
          SlideSize(SlideSizeKind.square, 1080, 1080),
          mode: SizeScaleMode.keep,
        ),
      ),
    ),
    ('set the default theme', SetDeckTheme(f.theme2)),
    // Slides.
    ('add two slides after a slide', AddSlides(afterSlideId: f.s2, count: 2)),
    (
      'add a slide in a group',
      AddSlides(target: InGroup(f.group), layoutId: layoutTitle),
    ),
    ('duplicate slides', DuplicateSlides([f.s2, f.s3, f.g1])),
    ('delete slides with dependents', DeleteSlides([f.s2, f.s3])),
    (
      'move slides into a group',
      MoveSlides([f.title, f.s3], InGroup(f.group, afterId: f.g1)),
    ),
    (
      'move a grouped slide to the top',
      MoveSlides([f.g2], TopLevel(beforeId: f.title)),
    ),
    ('skip slides', SetSlideProps([f.s2, f.s3], skipped: true)),
    (
      'edit notes',
      SetSlideProps([f.title], notes: Patch(deltaOf('New notes'))),
    ),
    (
      'set a background and transition',
      SetSlideProps(
        [f.s3],
        backgroundJson: const Patch(
          '{"v":1,"fill":{"v":1,"type":"solid","color":"theme:accent1"}}',
        ),
        transitionJson: const Patch('{"v":1,"type":"fade"}'),
        hideMasterElements: const Patch(true),
      ),
    ),
    ('apply a layout with remap', SetSlideProps([f.s2], layoutId: layoutTitle)),
    (
      'apply another layout',
      SetSlideProps([f.title, f.g1], layoutId: layoutTwo.value),
    ),
    ('reset slides to their layout', ResetSlideToLayout([f.s2, f.title])),
    // Groups.
    ('group slides', CreateGroup([f.s2, f.s3], title: 'Part 0', color: 'red')),
    ('ungroup', Ungroup(f.group)),
    ('move a group', MoveGroups([f.group], beforeId: f.title)),
    (
      'rename and skip a group',
      SetGroupProps([f.group], title: 'Intro', skipped: true),
    ),
    ('delete a group keeping slides', DeleteGroups([f.group])),
    ('delete a group with slides', DeleteGroups([f.group], withSlides: true)),
    ('duplicate a group', DuplicateGroups([f.group])),
    // Clipboard.
    (
      'paste slides from this deck',
      PasteSlides(
        clipboardOf(m, kind: 'slides', slideIds: [f.s2, f.s3]),
        afterSlideId: f.title,
      ),
    ),
    (
      'paste slides from another deck keeping the source theme',
      PasteSlides(
        clipboardOf(
          m,
          kind: 'slides',
          slideIds: [f.s2],
          withThemes: true,
          sourceDeckId: '00000000-0000-4000-8000-00000000dddd',
        ),
        themeMode: PasteThemeMode.keepSource,
      ),
    ),
    (
      'paste elements on their slide',
      PasteElements(
        clipboardOf(
          m,
          kind: 'elements',
          elementIds: [f.shape, f.grp],
          sourceSlideId: f.s3,
        ),
        f.s3,
      ),
    ),
    (
      'paste elements on a master (SL-28)',
      PasteElements(
        clipboardOf(m, kind: 'elements', elementIds: [f.shape, f.grp]),
        f.masterId,
        ownerKind: ElementOwnerKind.master,
      ),
    ),
    (
      'paste elements at a point',
      PasteElements(
        clipboardOf(
          m,
          kind: 'elements',
          elementIds: [f.table, f.code, f.chart],
        ),
        f.g2,
        atX: 10,
        atY: 20,
      ),
    ),
    // Elements.
    (
      'insert elements of every kind',
      InsertElements(f.s3, const [
        ElementSpec(
          kind: ElementKind.text,
          x: 1,
          y: 2,
          width: 300,
          height: 80,
          columns: {'text': '[{"insert":"Hi\\n"}]'},
        ),
        ElementSpec(
          kind: ElementKind.table,
          x: 1,
          y: 2,
          width: 300,
          height: 80,
          tableRows: 2,
          tableColumns: 3,
        ),
        ElementSpec(kind: ElementKind.code, x: 1, y: 2, width: 300, height: 80),
        ElementSpec(
          kind: ElementKind.group,
          x: 0,
          y: 0,
          width: 10,
          height: 10,
          children: [
            ElementSpec(
              kind: ElementKind.shape,
              x: 1,
              y: 1,
              width: 2,
              height: 2,
            ),
          ],
        ),
      ]),
    ),
    (
      'insert on a layout',
      InsertElements(layoutTitle, const [
        ElementSpec(kind: ElementKind.shape, x: 0, y: 0, width: 50, height: 50),
      ], ownerKind: ElementOwnerKind.layout),
    ),
    (
      'insert into a group',
      InsertElements(f.s3, const [
        ElementSpec(kind: ElementKind.shape, x: 0, y: 0, width: 50, height: 50),
      ], parentId: '00000000-0000-4000-8000-00000000fff1'),
    ),
    (
      'move and resize',
      UpdateFrames([
        FrameUpdate(f.shape, x: 5, y: 6, width: 70, height: 80),
        FrameUpdate(f.text, rotation: 370, flipH: true),
      ]),
    ),
    (
      'move a placeholder instance',
      UpdateFrames([FrameUpdate(m.elementsOf(f.s2).first.id, x: 40)]),
    ),
    (
      'recolor, lock and rename',
      SetElementProps(
        [f.shape, f.text],
        fillJson: const Patch('{"v":1,"type":"solid","color":"#ff0000"}'),
        locked: true,
        elementName: const Patch('Box'),
        opacity: const Patch(0.5),
        matchKey: 'hero',
      ),
    ),
    (
      'delete elements with dependents',
      DeleteElements([f.table, f.code, f.chart, f.grp]),
    ),
    (
      'delete the last children of a group',
      DeleteElements([f.child1, f.child2]),
    ),
    ('bring to front', ReorderZ([f.shape], ZOrderOp.toFront)),
    ('send to back', ReorderZ([f.text], ZOrderOp.toBack)),
    ('bring forward', ReorderZ([f.shape], ZOrderOp.forward)),
    ('send backward', ReorderZ([f.grp], ZOrderOp.backward)),
    (
      'align left',
      AlignDistribute([f.shape, f.shape2, f.text], AlignMode.left),
    ),
    ('align to the slide', AlignDistribute([f.shape], AlignMode.middleV)),
    (
      'distribute horizontally',
      AlignDistribute([f.shape, f.shape2, f.grp], AlignMode.distributeH),
    ),
    ('group elements', GroupElements([f.shape, f.shape2])),
    ('ungroup elements', UngroupElements([f.grp])),
    (
      'replace an image',
      ReplaceImage(
        f.image,
        src: 'wonky-file://00000000-0000-4000-8000-0000000000f2',
        naturalWidth: 10,
        naturalHeight: 20,
      ),
    ),
    (
      'replace an image keeping a cover crop',
      ReplaceImage(
        f.image,
        src: 'wonky-file://00000000-0000-4000-8000-0000000000f3',
        naturalWidth: 40,
        naturalHeight: 20,
        crop: const {'l': 0.25, 't': 0, 'r': 0.25, 'b': 0},
      ),
    ),
    (
      'set element data',
      SetElementData(f.shape, '{"v":1,"geometry":"ellipse"}'),
    ),
    // Text.
    ('type into a text box', SetText(ElementText(f.text), deltaOf('New'))),
    ('edit notes as text', SetText(NotesText(f.s3), deltaOf('Notes'))),
    (
      'type into an empty cell',
      SetText(CellText(f.table, f.rows[2], f.cols[2]), deltaOf('C3')),
    ),
    ('clear a cell', SetText(CellText(f.table, f.rows[0], f.cols[0]), null)),
    (
      'format a range',
      FormatText(
        [ElementText(f.text)],
        const {'bold': true, 'align': 'center'},
        start: 0,
        length: 3,
      ),
    ),
    (
      'format several bodies',
      FormatText(
        [
          ElementText(f.shape),
          CellText(f.table, f.rows[1], f.cols[1]),
          NotesText(f.title),
        ],
        const {'italic': true},
      ),
    ),
    (
      'set text box style',
      SetTextBoxStyle(
        [f.text, f.shape],
        const {'anchor': 'middle', 'autofit': 'shrink'},
      ),
    ),
    // Tables.
    (
      'insert table rows',
      InsertTableAxes(f.table, TableAxisDimension.row, 2, count: 2),
    ),
    ('insert a column', InsertTableAxes(f.table, TableAxisDimension.column, 0)),
    ('delete table axes', DeleteTableAxes(f.table, [f.rows[2], f.cols[0]])),
    ('move table rows', MoveTableAxes(f.table, [f.rows[0]], 3)),
    (
      'resize table axes',
      ResizeTableAxes(f.table, {f.rows[0]: 120, f.cols[1]: 300}),
    ),
    (
      'format cells',
      SetCells(f.table, [
        CellWrite(f.rows[0], f.cols[0], const {'fill': '#00ff00'}),
        CellWrite(f.rows[2], f.cols[0], const {'vAlign': 'middle'}),
      ]),
    ),
    (
      'merge cells',
      MergeCells(
        f.table,
        rowId: f.rows[0],
        columnId: f.cols[0],
        rowSpan: 2,
        colSpan: 2,
      ),
    ),
    ('unmerge cells', UnmergeCells(f.table, [merge])),
    (
      'set table options',
      SetTableOptions(f.table, const {
        'options': {'headerRow': false},
      }),
    ),
    // Builds.
    (
      'add builds',
      AddBuilds(f.s3, [
        BuildSpec(
          elementId: f.shape2,
          kind: SlideBuildKind.buildIn,
          effect: 'fade',
          durationMs: 400,
        ),
      ], afterBuildId: f.build1),
    ),
    (
      'update builds',
      UpdateBuilds({
        f.build1: const {'effect': 'zoom', 'durationMs': 800},
      }),
    ),
    ('move builds', MoveBuilds([f.build2], beforeId: f.build1)),
    ('delete builds', DeleteBuilds([f.build1])),
    // Code.
    ('set code', SetCode(f.states.first, 'print(2);')),
    (
      'add code states',
      AddCodeStates(f.code, const [
        {'code': 'a', 'label': 'A'},
      ], afterStateId: f.states.first),
    ),
    (
      'update a code state',
      UpdateCodeState(f.states.last, const {
        'highlight': '1-2',
        'label': 'Two',
      }),
    ),
    (
      'move code states',
      MoveCodeStates([f.states.last], beforeId: f.states.first),
    ),
    ('delete a code state', DeleteCodeStates([f.states.first])),
    // Charts.
    (
      'update a chart link',
      UpdateChartLink(f.chart, PlannerFixture.snapshot('2')),
    ),
    ('turn on auto-update', SetChartAutoUpdate(f.chart, true)),
    ('unlink a chart', UnlinkChart(f.chart)),
    (
      'style a chart',
      SetChartStyle(f.chart, const {
        'style': {'useDeckTheme': false},
      }),
    ),
    (
      'link a chart again',
      LinkChart(
        f.chart,
        spreadsheetItemUuid: '00000000-0000-4000-8000-0000000000e9',
        chartObjectId: '00000000-0000-4000-8000-0000000000ea',
        snapshot: PlannerFixture.snapshot('9'),
        autoUpdate: true,
      ),
    ),
    // Themes.
    ('import a built-in theme', const ImportTheme(builtInKey: 'studio')),
    (
      'import a theme package',
      ImportTheme(
        packageJson: themePackageJson('paper'),
        sourceKey:
            'deck:00000000-0000-4000-8000-0000000000c1:00000000-0000-4000-8000-0000000000c2',
      ),
    ),
    (
      'rename and recolor a theme',
      UpdateTheme(
        f.themeId,
        themeName: 'Mine',
        columns: {
          'fontsJson': BuiltInThemes.package(
            'swiss',
          )!.theme.toColumns()['fontsJson']!,
        },
      ),
    ),
    ('add a master', AddMaster(f.themeId)),
    ('duplicate a master', AddMaster(f.themeId, duplicateOf: f.masterId)),
    ('add a layout', AddLayout(f.masterId, layoutName: 'Mine')),
    ('duplicate a layout', AddLayout(f.masterId, duplicateOf: layoutTitle)),
    (
      'update a layout',
      UpdateMasterOrLayout(layoutTitle, const {
        'name': 'Cover',
        'hidden': true,
      }),
    ),
    (
      'move a layout (SL-28)',
      UpdateMasterOrLayout(f.layout('quote'), const {'sortKey': 'a0V'}),
    ),
    ('delete an unused layout', DeleteMastersOrLayouts([f.layout('quote')])),
    // Layers and reading order (SL-34).
    (
      'move an object into an element group',
      MoveElementsZ([f.shape2], intoGroupId: f.grp),
    ),
    (
      'move an object out of its group in front of a shape',
      MoveElementsZ([f.child1], aboveId: f.shape),
    ),
    ('reorder objects', MoveElementsZ([f.text], belowId: f.shape)),
    ('set a reading order', SetReadingOrder(f.s3, [f.text, f.shape])),
    // Cells by id.
    (
      'clear a cell by write',
      SetCells(f.table, [
        CellWrite(f.rows[0], f.cols[0], const {'text': null}),
      ]),
    ),
    (
      'touch the A1 cell',
      SetCells(f.table, [
        CellWrite(f.rows[0], f.cols[0], const {'padding': '1,2,3,4'}),
      ]),
    ),
  ];
}

void main() {
  final f = PlannerFixture();

  group('Given the planner fixture and the slides.rows handler', () {
    for (final (what, op) in _cases(f, f.session().model)) {
      test('when I $what, undo and redo then the deck returns to the state '
          'before and after', () async {
        final deck = f.session();
        final handler = SlidesRowsUndoHandler(() => deck);
        final before = deck.model.dump();

        final plan = deck.execute(op);
        final after = deck.model.dump();
        final undone = await handler.undo(
          SlidesRowsUndoEntry(plan.changes, label: plan.label),
        );
        final afterUndo = deck.model.dump();
        await handler.redo(undone);

        expect(plan.isEmpty, isFalse, reason: 'the plan changes something');
        expect(_onePerRow(plan.changes), isTrue);
        expect(afterUndo, before);
        expect(deck.model.dump(), after);
        expect(DeckMaintenance.detect(deck.model), isEmpty);
      });
    }

    test('when every operation class is covered then none is missing', () {
      final names = {
        for (final (_, op) in _cases(f, f.session().model)) op.name,
      };
      expect(
        names,
        containsAll([
          'SetDeckProps',
          'SetDeckTheme',
          'AddSlides',
          'DuplicateSlides',
          'DeleteSlides',
          'MoveSlides',
          'SetSlideProps',
          'ResetSlideToLayout',
          'CreateGroup',
          'Ungroup',
          'MoveGroups',
          'SetGroupProps',
          'DeleteGroups',
          'DuplicateGroups',
          'PasteSlides',
          'PasteElements',
          'InsertElements',
          'UpdateFrames',
          'SetElementProps',
          'DeleteElements',
          'ReorderZ',
          'MoveElementsZ',
          'SetReadingOrder',
          'AlignDistribute',
          'GroupElements',
          'UngroupElements',
          'ReplaceImage',
          'SetElementData',
          'SetText',
          'FormatText',
          'SetTextBoxStyle',
          'InsertTableAxes',
          'DeleteTableAxes',
          'MoveTableAxes',
          'ResizeTableAxes',
          'SetCells',
          'MergeCells',
          'UnmergeCells',
          'SetTableOptions',
          'AddBuilds',
          'UpdateBuilds',
          'MoveBuilds',
          'DeleteBuilds',
          'SetCode',
          'AddCodeStates',
          'UpdateCodeState',
          'MoveCodeStates',
          'DeleteCodeStates',
          'LinkChart',
          'UpdateChartLink',
          'SetChartAutoUpdate',
          'UnlinkChart',
          'SetChartStyle',
          'ImportTheme',
          'UpdateTheme',
          'AddMaster',
          'AddLayout',
          'UpdateMasterOrLayout',
          'DeleteMastersOrLayouts',
        ]),
      );
    });
  });

  group('Given an empty deck model', () {
    test('when creating the deck, undoing and redoing then it is gone and '
        'back with the same rows', () async {
      final deck = MemoryDeck(
        model: DeckModel(deckId: testDeckId),
        userId: testUserId,
        planner: const SlidesPlanner(),
        ids: SequentialIdGenerator(10),
      );
      final handler = SlidesRowsUndoHandler(() => deck);

      final plan = deck.execute(
        const CreateDeck(deckId: testDeckId, title: 'Pitch', themeKey: 'paper'),
      );
      final after = deck.model.dump();
      final undone = await handler.undo(
        SlidesRowsUndoEntry(plan.changes, label: plan.label),
      );
      final empty = deck.model.dump();
      await handler.redo(undone);

      expect(empty, isEmpty);
      expect(deck.model.dump(), after);
      expect(deck.model.slides, hasLength(1));
      expect(DeckMaintenance.detect(deck.model), isEmpty);
    });
  });

  group('Given a deck with a theme applied to all slides', () {
    test('when applying another theme to every slide, undoing and redoing '
        'then the deck returns to each state', () async {
      final deck = f.session();
      final imported = deck.execute(const ImportTheme(builtInKey: 'swiss'));
      final themeId = imported.result['themeId']! as String;
      final handler = SlidesRowsUndoHandler(() => deck);
      final before = deck.model.dump();

      final plan = deck.execute(ApplyThemeToSlides(themeId, const []));
      final after = deck.model.dump();
      final undone = await handler.undo(
        SlidesRowsUndoEntry(plan.changes, label: plan.label),
      );
      final afterUndo = deck.model.dump();
      await handler.redo(undone);

      expect(afterUndo, before);
      expect(deck.model.dump(), after);
      expect(deck.model.deck!.themeId, themeId);
      for (final s in deck.model.slides) {
        final l = deck.model.indexes.themes.effectiveLayout(s)!;
        expect(deck.model.indexes.themes.themeOfLayout(l)!.id, themeId);
      }
      expect(DeckMaintenance.detect(deck.model), isEmpty);
    });

    test('when removing the now unused old theme, undoing and redoing then '
        'the theme tree returns', () async {
      final deck = f.session();
      final themeId =
          deck
                  .execute(const ImportTheme(builtInKey: 'swiss'))
                  .result['themeId']!
              as String;
      deck.execute(ApplyThemeToSlides(themeId, const []));
      final handler = SlidesRowsUndoHandler(() => deck);
      final before = deck.model.dump();

      final plan = deck.execute(DeleteTheme(f.themeId));
      final undone = await handler.undo(
        SlidesRowsUndoEntry(plan.changes, label: plan.label),
      );

      expect(deck.model.dump(), before);
      await handler.redo(undone);
      expect(deck.model.theme(f.themeId), isNull);
      expect(deck.model.themes, hasLength(2));
    });
  });
}

/// Whether every row appears at most once in [changes].
bool _onePerRow(List<RowChange> changes) {
  final seen = <String>{};
  for (final c in changes) {
    if (!seen.add('${c.table}|${c.rowId}')) return false;
  }
  return true;
}
