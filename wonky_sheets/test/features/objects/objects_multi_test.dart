import 'dart:convert';

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show KeyScope;
import 'package:wonky_sheets/features/formula_bar/formula_bar.dart';
import 'package:wonky_sheets/l10n/sheets_l10n.dart';
import 'package:wonky_client/wonky_client.dart' show PresenceRoster;
import 'package:wonky_sheets/features/collab/presence/presence_cursor.dart';
import 'package:wonky_sheets/features/grid/grid_area.dart';
import 'package:wonky_sheets/features/objects/objects_controller.dart';
import 'package:wonky_sheets/features/objects/objects_layer.dart';
import 'package:wonky_sheets/features/toolbar/sheets_toolbar.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';
import '../collab/support/collab_harness.dart';

void main() {
  group('Given three charts on a sheet', () {
    late SheetsHarness s;
    late List<String> ids;

    ObjectsController objects() => ObjectsController.of(s.editor);

    ChartRect rectOf(String id) =>
        objects().rectOf(objects().record(id)!, ghost: false)!;

    Future<String> insert(String cell, {double w = 200, double h = 120}) async {
      final r = await s.run('sheets.chart.insert', {
        'ranges': ['A1:B3'],
        'anchor': {'cell': cell, 'width': w, 'height': h},
      });
      expect(r.isOk, isTrue, reason: r.message);
      return (r.data! as Map)['objectId']! as String;
    }

    setUp(() async {
      s = SheetsHarness.open();
      await s.type('A1', 'Region');
      await s.type('B1', 'Sales');
      await s.type('A2', 'North');
      await s.type('B2', '10');
      await s.type('A3', 'South');
      await s.type('B3', '7');
      ids = [await insert('D2'), await insert('H5'), await insert('E12')];
    });
    tearDown(() async {
      ObjectsController.maybeOf(s.editor)?.dispose();
      await s.dispose();
    });

    test('when two are selected and nudged then both move and one undo '
        'restores both', () async {
      await s.run('sheets.object.select', {
        'objectIds': [ids[0], ids[1]],
      });
      expect(objects().selectedIds, [ids[0], ids[1]]);
      expect(objects().isMultiSelection, isTrue);
      final a0 = rectOf(ids[0]);
      final b0 = rectOf(ids[1]);
      final steps = s.h.undoLabels.length;

      await s.run('sheets.object.nudge', {'dx': 10, 'dy': 0});
      await s.run('sheets.object.nudge', {'dx': 10, 'dy': 0});

      expect(rectOf(ids[0]).left, a0.left + 20);
      expect(rectOf(ids[1]).left, b0.left + 20);
      expect(rectOf(ids[2]).left, isNot(a0.left + 20));
      expect(s.h.undoLabels.length, steps + 1, reason: 'bursts coalesce');
      await s.undo();
      expect(rectOf(ids[0]).left, a0.left);
      expect(rectOf(ids[1]).left, b0.left);
    });

    test('when aligned left then every selected chart shares the leftmost '
        'edge in one undo step', () async {
      await s.run('sheets.object.select', {'objectIds': ids});
      final left = ids
          .map((i) => rectOf(i).left)
          .reduce((a, b) => a < b ? a : b);
      final steps = s.h.undoLabels.length;

      final r = await s.run('sheets.object.align', {'op': 'left'});

      expect(r.isOk, isTrue);
      for (final id in ids) {
        expect(rectOf(id).left, closeTo(left, 0.01));
      }
      expect(s.h.undoLabels.length, steps + 1);
      await s.undo();
      expect(rectOf(ids[1]).left, isNot(closeTo(left, 0.01)));
    });

    test('when distributed vertically then the gaps between them are '
        'equal', () async {
      await s.run('sheets.object.select', {'objectIds': ids});
      await s.run('sheets.object.align', {'op': 'distributeVertically'});
      final rects = [for (final id in ids) rectOf(id)]
        ..sort((a, b) => a.top.compareTo(b.top));
      final g1 = rects[1].top - rects[0].bottom;
      final g2 = rects[2].top - rects[1].bottom;
      expect(g1, closeTo(g2, 0.01));
    });

    test('when distributing only two objects then the command is '
        'disabled', () async {
      await s.run('sheets.object.select', {
        'objectIds': [ids[0], ids[1]],
      });
      final st = s.services.dispatcher.stateOf('sheets.object.align', {
        'op': 'distributeHorizontally',
      });
      expect(st.enabled, isFalse);
      expect(
        s.services.dispatcher.stateOf('sheets.object.align', {
          'op': 'left',
        }).enabled,
        isTrue,
      );
    });

    test('when a multi-selection is deleted then all its charts go in one '
        'undo step', () async {
      await s.run('sheets.object.select', {
        'objectIds': [ids[0], ids[2]],
      });
      final steps = s.h.undoLabels.length;
      await s.run('sheets.object.delete');
      expect([for (final o in objects().activeObjects) o.id], [ids[1]]);
      expect(s.h.undoLabels.length, steps + 1);
      await s.undo();
      expect(objects().activeObjects, hasLength(3));
    });

    test('when a multi-selection is brought to front then it keeps its '
        'relative order above the others', () async {
      await s.run('sheets.object.select', {
        'objectIds': [ids[0], ids[1]],
      });
      await s.run('sheets.object.order', {'op': 'front'});
      final order = [for (final o in objects().activeObjects) o.id];
      expect(order, [ids[2], ids[0], ids[1]]);
    });

    test('when a group is moved by an offset then every object moves the '
        'same distance in one undo step', () async {
      final a0 = rectOf(ids[0]);
      final c0 = rectOf(ids[2]);
      final steps = s.h.undoLabels.length;
      await s.run('sheets.object.move', {
        'objectIds': [ids[0], ids[2]],
        'by': {'x': 30, 'y': 40},
      });
      expect(rectOf(ids[0]).left, closeTo(a0.left + 30, 0.01));
      expect(rectOf(ids[2]).top, closeTo(c0.top + 40, 0.01));
      expect(s.h.undoLabels.length, steps + 1);
    });

    test('when toggling a chart then it joins or leaves the selection', () {
      objects().select(ids[0]);
      objects().toggleSelect(ids[1]);
      expect(objects().selectedIds, [ids[0], ids[1]]);
      objects().toggleSelect(ids[0]);
      expect(objects().selectedIds, [ids[1]]);
      expect(objects().isMultiSelection, isFalse);
    });

    test('when an anchor row is missing after a merge then maintenance '
        're-anchors the chart to a surviving row with dx = dy = 0', () async {
      final o = objects().record(ids[0])!;
      final map = (jsonDecode(o.anchorJson) as Map).cast<String, Object?>();
      map['rowId'] = '0000000000000000000001';
      map['dy'] = 7;
      s.session.applyChanges([
        RowChange.update(
          SheetsTables.embeddedObject,
          o.id,
          {'anchorJson': o.anchorJson},
          {'anchorJson': jsonEncode(map)},
        ),
      ], label: 'remote');
      expect(objects().anchorCell(objects().record(ids[0])!), isNull);

      expect(objects().runMaintenance(), 1);

      final a = ObjectAnchor.tryParse(objects().record(ids[0])!.anchorJson)!;
      expect(s.sheet.rows.contains(a.rowId!), isTrue);
      expect(a.dy, 0);
      expect(objects().runMaintenance(), 0, reason: 'idempotent');
    });
  });

  group('Given a spreadsheet with frozen rows', () {
    late SheetsHarness s;
    setUp(() => s = SheetsHarness.open());
    tearDown(() async {
      ObjectsController.maybeOf(s.editor)?.dispose();
      await s.dispose();
    });

    test('when a chart is inserted for data in the frozen rows then it is '
        'anchored in the scrolling pane', () async {
      await s.type('A1', 'Region');
      await s.type('B1', 'Sales');
      await s.type('A2', 'North');
      await s.type('B2', '10');
      await s.run('sheets.view.freezeRows', {'count': 2});
      expect(s.sheet.record!.frozenRows, 2);
      await s.select('A1:B2');

      final r = await s.run('sheets.chart.insert');

      final id = (r.data! as Map)['objectId']! as String;
      final o = ObjectsController.of(s.editor).record(id)!;
      final cell = ObjectsController.of(s.editor).anchorCell(o)!;
      expect(cell.$1, greaterThanOrEqualTo(2));
    });
  });

  group('Given a chart moved to its own sheet', () {
    late SheetsHarness s;
    setUp(() async {
      s = SheetsHarness.open();
      await s.type('A1', 'Region');
      await s.type('B1', 'Sales');
      await s.type('A2', 'North');
      await s.type('B2', '10');
      final r = await s.run('sheets.chart.insert', {
        'ranges': ['A1:B2'],
      });
      final id = (r.data! as Map)['objectId']! as String;
      await s.run('sheets.chart.moveToOwnSheet', {'objectId': id});
    });
    tearDown(() async {
      ObjectsController.maybeOf(s.editor)?.dispose();
      await s.dispose();
    });

    test('when the chart sheet is active then grid commands are disabled '
        'with a reason and chart commands stay available', () async {
      expect(s.sheet.record!.kind, SheetKind.chart);
      final d = s.services.dispatcher;
      for (final id in [
        'sheets.format.bold',
        'sheets.edit.copy',
        'sheets.edit.paste',
        'sheets.view.freezeRows',
        'sheets.chart.insert',
        'sheets.cell.edit',
      ]) {
        expect(d.stateOf(id).enabled, isFalse, reason: id);
      }
      expect(
        d.stateOf('sheets.format.bold').disabledReason,
        'Not available on chart sheets',
      );
      expect(d.stateOf('sheets.chart.edit').enabled, isTrue);
      expect(d.stateOf('sheets.chart.download').enabled, isTrue);
      expect(d.stateOf('sheets.sheet.add').enabled, isTrue);
    });

    for (final dark in [false, true]) {
      testWidgets('when the toolbar is shown then the format dropdowns are '
          'disabled too (${dark ? 'dark' : 'light'})', (tester) async {
        await pumpSheets(
          tester,
          s,
          dark: dark,
          child: SheetsToolbar(services: s.services, editor: s.editor),
        );
        final bar = tester.widget<WonkyToolbar>(find.byType(WonkyToolbar));
        final items = {
          for (final g in bar.groups)
            for (final i in g.items) i.id: i,
        };
        for (final id in [
          'sheets.toolbar.font',
          'sheets.toolbar.fontSize',
          'sheets.toolbar.textColor',
          'sheets.toolbar.fillColor',
          'sheets.toolbar.borders',
          'sheets.toolbar.hAlign',
          'sheets.toolbar.moreFormats',
        ]) {
          final item = items[id];
          final enabled = switch (item) {
            ToolbarDropdownButton(:final enabled) => enabled,
            ToolbarSplitButton(:final enabled) => enabled,
            ToolbarNumberField(:final enabled) => enabled,
            _ => null,
          };
          expect(enabled, isFalse, reason: id);
        }
      });
    }

    testWidgets('when the formula bar is shown then it is disabled', (
      tester,
    ) async {
      await pumpSheets(tester, s, child: FormulaBar(controller: s.editor));
      expect(
        find.byKey(const ValueKey('sheets.formulaBar.disabled')),
        findsOneWidget,
      );
    });
  });

  group('Given collaborators', () {
    late CollabHarness s;
    setUp(() async => s = await CollabHarness.open());
    tearDown(() async {
      ObjectsController.maybeOf(s.editor)?.dispose();
      await s.dispose();
    });

    Future<String> chart() async {
      await s.type('A1', 'Region');
      await s.type('B1', 'Sales');
      await s.type('A2', 'North');
      await s.type('B2', '10');
      final r = await s.run('sheets.chart.insert', {
        'ranges': ['A1:B2'],
        'anchor': {'cell': 'D2', 'width': 300, 'height': 200},
      });
      return (r.data! as Map)['objectId']! as String;
    }

    test(
      'when a chart is selected then the published cursor names it',
      () async {
        final id = await chart();
        ObjectsController.of(s.editor).select(id);
        // Cursor updates are throttled to one per 100 ms: the update may
        // wait for the window of the one sent on attach (timing-dependent
        // before: it passed only when the setup took over 100 ms).
        await Future<void>.delayed(const Duration(milliseconds: 150));
        final sent = SheetsPresenceCursor.tryParse(
          s.presenceRepo.updates.last.cursorJson,
        );
        expect(sent?.objectId, id);
        ObjectsController.of(s.editor).select(null);
        // Cursor updates are throttled to one per 100 ms.
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(
          SheetsPresenceCursor.tryParse(
            s.presenceRepo.updates.last.cursorJson,
          )?.objectId,
          isNull,
        );
      },
    );

    for (final dark in [false, true]) {
      testWidgets('when a collaborator selects a chart then it is outlined '
          'with their name (${dark ? 'dark' : 'light'})', (tester) async {
        final id = await tester.runAsync(chart);
        await _pumpCollab(
          tester,
          s,
          dark: dark,
          child: WonkyPopupMenuHost(
            child: SheetObjectsHost(
              editor: s.editor,
              services: s.services,
              child: GridArea(controller: s.editor, services: s.services),
            ),
          ),
        );
        s.presenceRepo.emit(
          PresenceRoster(
            sessionId: 'me',
            participants: [
              participant('me', userId: 1, name: 'Anna'),
              participant(
                'bo',
                cursorJson: SheetsPresenceCursor(
                  sheetId: s.sheetId,
                  objectId: id,
                ).encode(),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(
          find.byKey(ValueKey('sheets.object.remote.$id.0')),
          findsOneWidget,
        );
        expect(find.text('Bo Stone'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('Given two charts in the grid', () {
    late SheetsHarness s;
    setUp(() => s = SheetsHarness.open());
    tearDown(() => s.dispose());

    testWidgets('when shift-clicking the second one then both are outlined '
        'and dragging one moves both in one undo step', (tester) async {
      await s.type('A1', 'Region');
      await s.type('B1', 'Sales');
      await s.type('A2', 'North');
      await s.type('B2', '10');
      await pumpSheets(
        tester,
        s,
        child: WonkyPopupMenuHost(
          child: SheetObjectsHost(
            editor: s.editor,
            services: s.services,
            child: GridArea(controller: s.editor, services: s.services),
          ),
        ),
      );
      Future<String> insert(String cell) async {
        final r = await s.run('sheets.chart.insert', {
          'ranges': ['A1:B2'],
          'anchor': {'cell': cell, 'width': 200, 'height': 120},
        });
        return (r.data! as Map)['objectId']! as String;
      }

      final a = await insert('D2');
      final b = await insert('H12');
      final objects = ObjectsController.of(s.editor);
      objects.select(a);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.tapAt(
        tester.getCenter(find.byKey(ValueKey('sheets.object.$b'))),
      );
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump(const Duration(milliseconds: 500));
      expect(objects.selectedIds, [a, b]);
      expect(find.byKey(ValueKey('sheets.object.outline.$a')), findsOneWidget);
      expect(find.byKey(const ValueKey('sheets.object.frame')), findsNothing);

      final ra = objects.rectOf(objects.record(a)!, ghost: false)!;
      final rb = objects.rectOf(objects.record(b)!, ghost: false)!;
      final steps = s.h.undoLabels.length;
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey('sheets.object.$a'))),
      );
      await g.moveBy(const Offset(20, 0));
      await g.moveBy(const Offset(20, 10));
      await tester.pump();
      await g.up();
      await tester.pump(const Duration(milliseconds: 500));

      final ra2 = objects.rectOf(objects.record(a)!, ghost: false)!;
      final rb2 = objects.rectOf(objects.record(b)!, ghost: false)!;
      expect(ra2.left - ra.left, closeTo(rb2.left - rb.left, 0.5));
      expect(ra2.top - ra.top, closeTo(rb2.top - rb.top, 0.5));
      expect(ra2.left, isNot(ra.left));
      expect(s.h.undoLabels.length, steps + 1);
      expect(objects.selectedIds, [a, b], reason: 'a drag keeps the group');

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });
}

/// [pumpSheets] for a [CollabHarness].
Future<void> _pumpCollab(
  WidgetTester tester,
  CollabHarness s, {
  required bool dark,
  required Widget child,
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    Provider<ShellServices>.value(
      value: s.services,
      child: ShadApp(
        theme: dark ? WonkyTheme.dark() : WonkyTheme.light(),
        localizationsDelegates: const [
          WonkyAppLocalizations.delegate,
          WonkyUiLocalizations.delegate,
          SheetsLocalizations.delegate,
        ],
        home: Material(
          type: MaterialType.transparency,
          child: WonkyThemeScope(
            data: const WonkyThemeExtension(),
            child: KeymapScope(
              scope: KeyScope.global,
              keymap: s.services.keymap,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}
