import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets/features/clipboard/system_clipboard.dart';
import 'package:wonky_sheets/features/objects/objects_controller.dart';
import 'package:wonky_sheets_core/model.dart';

import '../support/sheets_harness.dart';

void main() {
  late SheetsHarness s;

  ObjectsController objects() => ObjectsController.of(s.editor);

  List<EmbeddedObjectRecord> charts() => objects().activeObjects;

  EmbeddedObjectRecord fresh(String id) => objects().record(id)!;

  ObjectAnchor anchorOf(EmbeddedObjectRecord o) =>
      ObjectAnchor.tryParse(fresh(o.id).anchorJson)!;

  ChartSpec specOf(String id) => ChartSpec.fromJson(fresh(id).specJson);

  Future<void> seedTable() async {
    await s.type('A1', 'Region');
    await s.type('B1', 'Q1');
    await s.type('C1', 'Q2');
    final rows = [
      ['North', '10', '12'],
      ['South', '7', '9'],
      ['East', '4', '6'],
      ['West', '8', '3'],
    ];
    for (var i = 0; i < rows.length; i++) {
      await s.type('A${i + 2}', rows[i][0]);
      await s.type('B${i + 2}', rows[i][1]);
      await s.type('C${i + 2}', rows[i][2]);
    }
  }

  Future<String> insertChart([Map<String, Object?> args = const {}]) async {
    final r = await s.run('sheets.chart.insert', args);
    expect(r.isOk, isTrue, reason: '${r.message}');
    return (r.data! as Map)['objectId']! as String;
  }

  setUp(() => s = SheetsHarness.open());
  tearDown(() async {
    ObjectsController.maybeOf(s.editor)?.dispose();
    await s.dispose();
  });

  group('Given a table of regions with two quarters', () {
    setUp(seedTable);

    test('when inserting a chart for A1:C5 then a recommended column chart '
        'with two series is placed right of the data and one undo removes '
        'it (08 AC 1)', () async {
      await s.select('A1:C5');
      final steps = s.h.undoLabels.length;

      final id = await insertChart();

      final spec = specOf(id);
      expect(spec.type, ChartType.column);
      expect(spec.data.headerCount, 1);
      final data = objects().chartOf(fresh(id)).data;
      expect([for (final x in data.series) x.name], ['Q1', 'Q2']);
      final a = anchorOf(fresh(id));
      expect(s.sheet.columns.indexOf(a.colId!), 3, reason: 'column D');
      expect(a.dx, ObjectPlacement.chartGap);
      expect(objects().selectedId, id);
      expect(s.h.undoLabels.length, steps + 1);

      await s.undo();
      expect(charts(), isEmpty);
      await s.redo();
      expect(charts(), hasLength(1));
    });

    test(
      'when a source cell changes then the chart data re-resolves',
      () async {
        await s.select('A1:C5');
        final id = await insertChart();
        final c = objects().chartOf(fresh(id));
        expect(c.data.series.first.values.first, 10);

        await s.type('B2', '42');
        objects().flushData();

        expect(c.data.series.first.values.first, 42);
      },
    );

    test('when a single cell is selected then the contiguous region is '
        'charted', () async {
      await s.select('B3');
      final id = await insertChart();
      final rr = s.sheet.resolve(specOf(id).data.gridRanges.single)!;
      expect(rr.rect.a1, 'A1:C5');
    });

    test('when updating the title with a merge patch then it is one undo '
        'step', () async {
      await s.select('A1:C5');
      final id = await insertChart();

      await s.run('sheets.chart.update', {
        'objectId': id,
        'patch': {
          'title': {'text': 'Revenue'},
        },
      });

      expect(specOf(id).title.text, 'Revenue');
      await s.undo();
      expect(specOf(id).title.text, '');
    });

    test('when a field changes repeatedly with a coalesce key then the '
        'burst is one undo step', () async {
      await s.select('A1:C5');
      final id = await insertChart();
      final steps = s.h.undoLabels.length;

      for (final size in [14, 16, 18]) {
        await s.run('sheets.chart.update', {
          'objectId': id,
          'patch': {
            'title': {
              'font': {'size': size},
            },
          },
          'coalesceKey': 'title.size',
        });
      }

      expect(specOf(id).title.font.size, 18);
      expect(s.h.undoLabels.length, steps + 1);
      await s.undo();
      expect(specOf(id).title.font.size, isNull);
    });

    test('when an invalid patch is sent then the command fails and nothing '
        'changes', () async {
      await s.select('A1:C5');
      final id = await insertChart();
      final before = fresh(id).specJson;

      final r = await s.run('sheets.chart.update', {
        'objectId': id,
        'patch': {'stacking': 'sideways'},
      });

      expect(r.isOk, isFalse);
      expect(fresh(id).specJson, before);
    });

    test('when changing the type to doughnut then a pie with a hole is '
        'stored and undo restores the previous type', () async {
      await s.select('A1:B5');
      final id = await insertChart();
      final before = specOf(id).type;

      await s.run('sheets.chart.setType', {
        'objectId': id,
        'type': 'pie',
        'pieHole': 0.5,
      });
      expect(specOf(id).type, ChartType.pie);
      expect(specOf(id).pieOptions.pieHole, 0.5);

      await s.undo();
      expect(specOf(id).type, before);
    });

    test('when setting data ranges then series are re-detected', () async {
      await s.select('A1:C5');
      final id = await insertChart();

      await s.run('sheets.chart.setDataRanges', {
        'objectId': id,
        'ranges': ['A1:B5'],
      });

      final data = objects().chartOf(fresh(id)).data;
      expect([for (final x in data.series) x.name], ['Q1']);
    });

    test('when moving, resizing and nudging then each gesture is one undo '
        'step and a nudge burst coalesces (08 AC 5)', () async {
      await s.select('A1:C5');
      final id = await insertChart();
      final start = objects().rectOf(fresh(id))!;

      await s.run('sheets.object.move', {
        'objectId': id,
        'to': {'x': 300, 'y': 100},
      });
      var r = objects().rectOf(fresh(id))!;
      expect((r.left, r.top), (300.0, 100.0));

      await s.run('sheets.object.resize', {
        'objectId': id,
        'width': 400,
        'height': 250,
      });
      r = objects().rectOf(fresh(id))!;
      expect((r.width, r.height), (400.0, 250.0));

      final steps = s.h.undoLabels.length;
      for (var i = 0; i < 5; i++) {
        await s.run('sheets.object.nudge', {'dx': 1, 'dy': 0});
      }
      await s.run('sheets.object.nudge', {'dx': 0, 'dy': 10});
      r = objects().rectOf(fresh(id))!;
      expect((r.left, r.top), (305.0, 110.0));
      expect(s.h.undoLabels.length, steps + 1);

      await s.undo();
      r = objects().rectOf(fresh(id))!;
      expect((r.left, r.top), (300.0, 100.0));
      await s.undo();
      await s.undo();
      r = objects().rectOf(fresh(id))!;
      expect((r.left, r.top, r.width), (start.left, start.top, start.width));
    });

    test('when rows are inserted above the anchor then the chart moves down '
        'and keeps its size (08 AC 4)', () async {
      await s.select('A1:C5');
      final id = await insertChart();
      final before = objects().rectOf(fresh(id))!;

      await s.select('A1:A3');
      await s.run('sheets.rows.insertAbove');

      final after = objects().rectOf(fresh(id))!;
      expect(after.top, greaterThan(before.top));
      expect((after.width, after.height), (before.width, before.height));
    });

    test('when duplicating, ordering and deleting then z-order and undo '
        'follow', () async {
      await s.select('A1:C5');
      final a = await insertChart();
      await s.run('sheets.object.duplicate', {
        'objectIds': [a],
      });
      expect(charts(), hasLength(2));
      final b = objects().selectedId!;
      expect(b, isNot(a));
      final ra = objects().rectOf(fresh(a))!;
      final rb = objects().rectOf(fresh(b))!;
      expect(rb.left - ra.left, ObjectAnchor.duplicateOffset);

      await s.run('sheets.object.order', {'objectId': a, 'op': 'front'});
      expect(charts().last.id, a);

      await s.run('sheets.object.delete', {
        'objectIds': [a],
      });
      expect(charts().map((o) => o.id), [b]);
      await s.undo();
      expect(charts(), hasLength(2));
    });

    test('when copying a chart and pasting at another cell then a new chart '
        'with the same data ranges appears there', () async {
      await s.select('A1:C5');
      final id = await insertChart();
      await s.run('sheets.object.copy', {
        'objectIds': [id],
      });
      expect(s.clip.data?.plainText, startsWith('wonky-sheets-objects:'));

      await s.select('H20');
      final r = await s.run('sheets.object.paste');
      expect(r.isOk, isTrue);

      expect(charts(), hasLength(2));
      final pasted = objects().selectedId!;
      expect(objects().anchorCell(fresh(pasted)), (19, 7));
      expect(
        s.sheet.resolve(specOf(pasted).data.gridRanges.single)!.rect.a1,
        'A1:C5',
      );
    });

    test('when another app replaced the clipboard then object paste pastes '
        'its text into cells instead', () async {
      await s.select('A1:C5');
      final id = await insertChart();
      await s.run('sheets.object.copy', {
        'objectIds': [id],
      });
      s.clip.data = const SystemClipboardData(plainText: 'hello');

      await s.select('E10');
      await s.run('sheets.object.paste');

      expect(charts(), hasLength(1));
      expect(s.text('E10'), 'hello');
    });

    test('when editing alt text with arguments then it is stored and undo '
        'reverts it', () async {
      await s.select('A1:C5');
      final id = await insertChart();

      await s.run('sheets.object.editAltText', {
        'objectId': id,
        'title': 'Sales',
        'description': 'Sales per region',
      });

      expect(fresh(id).title, 'Sales');
      expect(fresh(id).altText, 'Sales per region');
      await s.undo();
      expect(fresh(id).altText ?? '', '');
    });

    test('when moving a chart to its own sheet and back then the original '
        'anchor is restored (08 AC 12)', () async {
      await s.select('A1:C5');
      final id = await insertChart();
      final grid = s.sheetId;
      final before = anchorOf(fresh(id));

      final r = await s.run('sheets.chart.moveToOwnSheet', {'objectId': id});
      final chartSheet = (r.data! as Map)['sheetId']! as String;
      expect(s.model.sheet(chartSheet)!.record!.kind, SheetKind.chart);
      expect(fresh(id).sheetId, chartSheet);
      expect(anchorOf(fresh(id)).ownSheet, isTrue);
      expect(s.editor.activeSheetId, chartSheet);

      await s.run('sheets.chart.moveToSheet', {
        'objectId': id,
        'sheetId': grid,
      });
      expect(s.model.sheet(chartSheet), isNull);
      final back = anchorOf(fresh(id));
      expect(
        (back.rowId, back.colId, back.dx),
        (before.rowId, before.colId, before.dx),
      );
      expect(specOf(id).extras.containsKey('previousAnchor'), isFalse);

      await s.undo();
      expect(s.model.sheet(chartSheet), isNotNull);
      await s.undo();
      expect(fresh(id).sheetId, grid);
    });

    test(
      'when listing objects then charts report type, ranges and anchor',
      () async {
        await s.select('A1:C5');
        await insertChart();

        final r = await s.run('sheets.object.list');
        final list = ((r.data! as Map)['objects']! as List)
            .cast<Map<Object?, Object?>>();
        expect(list.single['type'], 'column');
        expect(list.single['anchorCell'], 'D1');
        expect(list.single['ranges'], ['Sheet1!A1:C5']);
      },
    );

    test('when viewing the data table headlessly then headers and rows come '
        'back', () async {
      await s.select('A1:C5');
      final id = await insertChart();
      final r = await s.h.invoke('sheets.chart.viewDataTable', {
        'objectId': id,
      }, InvocationSource.mcp);
      final m = r.data! as Map;
      expect(m['headers'], ['Region', 'Q1', 'Q2']);
      expect((m['rows'] as List).first, ['North', '10', '12']);
    });

    test('when selecting next objects then they cycle in z-order', () async {
      await s.select('A1:C5');
      final a = await insertChart();
      await s.select('A1:B5');
      final b = await insertChart();
      objects().select(null);

      await s.run('sheets.object.selectNext');
      expect(objects().selectedId, b);
      await s.run('sheets.object.selectNext');
      expect(objects().selectedId, a);
    });
  });

  group('Given a viewer', () {
    setUp(() async {
      await s.dispose();
      s = SheetsHarness.open(role: Role.viewer);
    });

    test('when checking chart insert then it is disabled', () {
      final st = s.services.dispatcher.stateOf('sheets.chart.insert', const {});
      expect(st.enabled, isFalse);
    });
  });

  test('when inserting with an explicit type then the spec uses it', () async {
    await s.type('A1', '1');
    await s.type('A2', '2');
    await s.select('A1:A2');
    final id = await insertChart({'type': 'line'});
    expect(jsonDecode(fresh(id).specJson)['type'], 'line');
  });
}
