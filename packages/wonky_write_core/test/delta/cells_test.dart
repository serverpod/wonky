import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';

Map<String, dynamic> cell(String row, {String table = 't', String? align}) => {
  'cell': {'table': table, 'row': row, 'align': ?align},
};

Map<String, dynamic> grid(String id, {int columns = 3, String b = 'check'}) => {
  'grid': {'id': id, 'columns': columns, 'bullets': b},
};

void main() {
  const normalizer = WonkyDeltaNormalizer();
  const validator = WonkyDeltaValidator();

  group('Given cell and grid attribute values', () {
    test('when parsing then non-canonical parts are dropped', () {
      expect(
        CellAttr.tryParse({
          'table': 't',
          'row': 'r',
          'align': 'middle',
          'x': 1,
        }),
        const CellAttr(table: 't', row: 'r'),
      );
      expect(CellAttr.tryParse({'table': '', 'row': 'r'}), isNull);
      expect(CellAttr.tryParse('t'), isNull);
      expect(
        GridItemAttr.tryParse({'id': 'g', 'columns': 7, 'bullets': 'stars'}),
        const GridItemAttr(id: 'g', columns: 3, bullets: GridBullets.none),
      );
    });

    test('when checking canonical form then only exact shapes pass', () {
      expect(CellAttr.isCanonical({'table': 't', 'row': 'r'}), isTrue);
      expect(
        CellAttr.isCanonical({'table': 't', 'row': 'r', 'align': 'right'}),
        isTrue,
      );
      expect(
        CellAttr.isCanonical({'table': 't', 'row': 'r', 'align': null}),
        isFalse,
      );
      expect(
        GridItemAttr.isCanonical({'id': 'g', 'columns': 2, 'bullets': 'none'}),
        isTrue,
      );
      expect(GridItemAttr.isCanonical({'id': 'g', 'columns': 3}), isFalse);
    });

    test('when making ids then row ids are 8 base-36 characters', () {
      final ids = {for (var i = 0; i < 50; i++) CellIds.row()};
      expect(ids, hasLength(50));
      expect(ids.every(RegExp(r'^[0-9a-z]{8}$').hasMatch), isTrue);
      expect(CellIds.group(), hasLength(36));
    });
  });

  group('Given a document with two tables and a grid', () {
    final doc = WonkyDocument(
      normalizer
          .normalize(
            Delta()
              ..insert('Intro\n')
              ..insert('A\n', cell('r1'))
              ..insert('B\n', cell('r1', align: 'right'))
              ..insert('1\n', cell('r2'))
              ..insert('Between\n')
              ..insert('X\n', cell('a', table: 'u'))
              ..insert('One\n', grid('g'))
              ..insert('Two\n', grid('g'))
              ..insert('Outro\n'),
          )
          .document,
    );

    test('when finding runs then each table and grid is one run', () {
      final runs = CellRuns.of(doc);
      expect(runs, hasLength(3));
      final t = runs[0] as CellTable;
      expect(t.id, 't');
      expect(t.rows.map((r) => r.cells.length), [2, 1]);
      expect(t.columnCount, 2);
      expect(t.isRagged, isTrue);
      expect(t.align, [null, CellAlign.right]);
      expect(t.cellOf(t.rows[1].cells[0].start), (1, 0));
      expect((runs[1] as CellTable).id, 'u');
      final g = runs[2] as CellGrid;
      expect(g.items.map((l) => l.text), ['One', 'Two']);
      expect(g.columns, 3);
    });

    test(
      'when asking for the run at a line then any of its lines finds it',
      () {
        expect((CellRuns.at(doc, 3) as CellTable).id, 't');
        expect((CellRuns.at(doc, 7) as CellGrid).id, 'g');
        expect(CellRuns.at(doc, 4), isNull);
        expect(CellRuns.table(doc, 'u')!.rows.single.cells.single.text, 'X');
        expect(CellRuns.grid(doc, 'nope'), isNull);
      },
    );

    test('when rendering plain text then rows are tab separated', () {
      expect(
        PlainTextRenderer.render(doc.delta),
        'Intro\nA\tB\n1\nBetween\nX\nOne\nTwo\nOutro',
      );
    });

    test('when counting stats then each table counts once and cells are not '
        'paragraphs', () {
      final stats = const DocumentStatsCalculator().statsOf(doc);
      expect(stats.tables, 2);
      expect(stats.paragraphs, 3);
      expect(stats.words, 3 + 4 + 2);
    });

    test('when building the DocTree then tables are padded and grids keep '
        'their items', () {
      final tree = const DocTreeBuilder().fromDelta(doc.delta);
      final t = tree.blocks[1] as TableBlock;
      expect(t.id, 't');
      expect(t.align, [null, CellAlign.right]);
      expect(t.cellMarkdown, [
        ['A', 'B'],
        ['1', ''],
      ]);
      expect(t.rowIds, ['r1', 'r2']);
      expect(t.deltaStart, 'Intro\n'.length);
      expect(t.deltaLength, 'A\nB\n1\n'.length);
      final g = tree.blocks[4] as GridBlock;
      expect(g.itemMarkdown, ['One', 'Two']);
    });

    test('when converting the DocTree back then the lines return with their '
        'row ids (rows completed)', () {
      final tree = const DocTreeBuilder().fromDelta(doc.delta);
      final back = const DocTreeToDelta().convert(tree);
      expect(
        CellCanon.canonical(back).toJson(),
        CellCanon.canonical(doc.delta).toJson(),
      );
      final t = CellRuns.table(WonkyDocument(back), 't')!;
      expect(t.rows.map((r) => r.id), ['r1', 'r2']);
    });
  });

  group('Given invalid cell lines', () {
    test('when validating then other block attributes are rejected', () {
      final d = Delta()
        ..insert('A\n', {...cell('r'), 'header': 2})
        ..insert('B\n', {...cell('r'), ...grid('g')})
        ..insert('C D\n', cell('r'));
      final codes = validator.validate(d).issues.map((i) => i.code).toList();
      expect(codes.where((c) => c == ValidationCode.invalidCell), hasLength(3));
    });

    test('when normalizing then the lines become valid cells', () {
      final d = Delta()
        ..insert('A\n', {
          ...cell('r'),
          'header': 2,
          'box': [
            {'id': 'b', 'type': 'card'},
          ],
        })
        ..insert('B\n', {...cell('r'), ...grid('g')})
        ..insert('C D\n', {
          'cell': {'table': 't', 'row': 'r', 'align': 'middle', 'x': 1},
        });
      final out = normalizer.normalize(d).document;
      expect(validator.validate(out).isValid, isTrue);
      final lines = WonkyDocument(out).lines;
      expect(lines[0].attributes.keys.toSet(), {'cell', 'box'});
      expect(lines[1].attributes.keys.toSet(), {'cell'});
      expect(lines[2].text, 'C D');
      expect(lines[2].attributes, cell('r'));
    });
  });

  group('Given legacy table and grid embeds', () {
    final box = [
      {'id': 'b', 'type': 'card'},
    ];
    final legacy = Delta()
      ..insert('Intro\n')
      ..insert(
        const TableEmbed(
          id: 't1',
          align: [null, CellAlign.center],
          rows: [
            ['**Name**', 'Qty'],
            ['Apples'],
          ],
        ).toInsert(),
        {'cmt_c1': true},
      )
      ..insert('\n', {'box': box})
      ..insert(
        const GridEmbed(
          id: 'g1',
          columns: 2,
          bullets: GridBullets.circle,
          items: [':chip[Fast]', 'Reliable'],
        ).toInsert(),
      )
      ..insert('\n')
      ..insert('Outro\n');

    test('when detecting then they are found', () {
      expect(CellUpgrade.hasLegacy(legacy), isTrue);
      expect(CellUpgrade.hasLegacy(Delta()..insert('x\n')), isFalse);
      expect(CellUpgrade.upgradeChange(Delta()..insert('x\n')), isNull);
    });

    test('when upgrading then they become lines with their ids, box and '
        'inline Markdown as formatting; comments are dropped', () {
      var n = 0;
      final out = normalizer
          .normalize(CellUpgrade.upgrade(legacy, rowId: () => 'r${n++}'))
          .document;
      expect(validator.validate(out).isValid, isTrue);
      expect(CellUpgrade.hasLegacy(out), isFalse);
      final doc = WonkyDocument(out);
      final t = CellRuns.table(doc, 't1')!;
      expect(t.rows.map((r) => r.id), ['r0', 'r1']);
      expect(
        [
          for (final r in t.rows) [for (final c in r.cells) c.text],
        ],
        [
          ['Name', 'Qty'],
          ['Apples', ''],
        ],
      );
      expect(t.rows[0].cells[0].segments.single.attributes, {'bold': true});
      expect(t.align, [null, CellAlign.center]);
      expect(t.box, box);
      for (final line in t.lines) {
        expect(line.attributes['box'], box);
        expect(
          line.segments.every((s) => s.attributes?['cmt_c1'] == null),
          isTrue,
        );
      }
      final g = CellRuns.grid(doc, 'g1')!;
      expect(g.items.map((l) => l.text), ['Fast', 'Reliable']);
      expect(g.items.first.segments.single.attributes, {'chip': true});
      expect(g.columns, 2);
      expect(g.bullets, GridBullets.circle);
      expect(doc.lines.first.text, 'Intro');
      expect(doc.lines.last.text, 'Outro');
    });

    test('when upgrading then the Markdown export is unchanged (AC-12.5)', () {
      const codec = MarkdownCodec();
      const options = MarkdownExportOptions(flavor: MarkdownFlavor.wonky);
      expect(
        codec.exportMarkdown(CellUpgrade.upgrade(legacy), options: options),
        codec.exportMarkdown(legacy, options: options),
      );
    });

    test('when building the DocTree then both forms give the same blocks', () {
      String md(Delta d) => const MarkdownCodec().exportMarkdown(
        d,
        options: const MarkdownExportOptions(flavor: MarkdownFlavor.wonky),
      );
      final legacyTree = const DocTreeBuilder().fromDelta(legacy);
      final upgradedTree = const DocTreeBuilder().fromDelta(
        CellUpgrade.upgrade(legacy),
      );
      final a = legacyTree.blocks.whereType<ContainerBlock>().single;
      final b = upgradedTree.blocks.whereType<ContainerBlock>().single;
      final ta = a.children.single as TableBlock;
      final tb = b.children.single as TableBlock;
      expect(tb.cellMarkdown, ta.cellMarkdown);
      expect(tb.align, ta.align);
      expect(md(CellUpgrade.upgrade(legacy)), md(legacy));
    });
  });

  group('Given random documents with legacy embeds', () {
    propertyTest('when upgrading then the result is valid, has no legacy '
        'embeds, and upgrading again changes nothing', (random, _) {
      final gen = DeltaGen(
        random,
        options: const DeltaGenOptions(wonky: true, overlays: true),
      );
      final doc = gen.document();
      // Replace some lines with legacy embeds.
      final d = Delta();
      for (final line in WonkyDocument(doc).lines) {
        if (random.nextInt(6) == 0) {
          d
            ..insert(
              (random.nextBool() ? gen.legacyTable() : gen.legacyGrid())
                  .toInsert(),
            )
            ..insert('\n', {'box': ?line.attributes['box']});
        }
        for (final s in line.segments) {
          d.insert(s.data, s.attributes);
        }
        d.insert('\n', line.attributes.isEmpty ? null : line.attributes);
      }
      final legacy = normalizer.normalize(d).document;
      final change = CellUpgrade.upgradeChange(legacy);
      final out = normalizer
          .normalize(change == null ? legacy : legacy.compose(change))
          .document;

      expect(validator.validate(out).issues, isEmpty);
      expect(CellUpgrade.hasLegacy(out), isFalse);
      expect(CellUpgrade.upgradeChange(out), isNull);
      expect(
        PlainTextRenderer.render(out).replaceAll('\t', ' '),
        PlainTextRenderer.render(legacy).replaceAll('\t', ' '),
      );
    }, runs: 200);
  });
}
