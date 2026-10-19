import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_app/uploads.dart' show MemoryPendingUploadStore;
import 'package:wonky_core/wonky_core.dart' show CommandStatus;
import 'package:wonky_slides/features/canvas/slide_canvas.dart';
import 'package:wonky_slides/features/canvas/slide_canvas_controller.dart';
import 'package:wonky_slides/features/editor_screen/canvas_region.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_slides/features/elements/image/crop_mode.dart';
import 'package:wonky_slides/features/elements/image/image_geometry.dart';
import 'package:wonky_slides/features/elements/table/table_cells.dart';
import 'package:wonky_slides/features/inspector/deck_inspector.dart';
import 'package:wonky_slides/features/stage/slide_renderer.dart';
import 'package:wonky_slides/features/text_editing/text_editing_host.dart';
import 'package:wonky_slides/features/uploads/slides_image_service.dart';
import 'package:wonky_slides/features/uploads/slides_pending_uploads.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';

import '../../commands/image_commands_test.dart' show FakeFiles;
import '../../harness/deck_harness.dart';
import '../../support/slides_harness.dart';
import '../stage/stage_fixture.dart' show RecordingFontRegistry;

const _file = '0190a000-0000-7000-8000-0000000000cc';

/// A blank slide with an image `photo` (400,100 600×300, natural 1200×600)
/// and a 3 × 3 table `table` (300,600 900×240).
class _Fixture {
  _Fixture() {
    slide = b.slide(layoutKey: 'blank');
    photo = b.element(
      slide,
      ElementKind.image,
      x: 400,
      y: 100,
      width: 600,
      height: 300,
      columns: {
        ElementCols.dataJson: jsonEncode({
          'v': 1,
          'src': 'wonky-file://$_file',
          'naturalWidth': 1200,
          'naturalHeight': 600,
        }),
      },
    );
    final t = b.table(
      slide,
      rows: 3,
      cols: 3,
      x: 300,
      y: 600,
      width: 900,
      height: 240,
    );
    table = t.$1;
    rows = t.$2;
    cols = t.$3;
    b.cell(table, rows[0], cols[0], 'Head');
  }

  final DeckBuilder b = DeckBuilder(title: 'Images and tables');
  late final String slide, photo, table;
  late final List<String> rows, cols;
}

class _Rig {
  _Rig(this.d, this.f, this.c);

  final DeckHarness d;
  final _Fixture f;
  final SlideCanvasController c;

  DeckModel get model => d.model;
  DeckEditorController get ed => d.editor;

  static Future<_Rig> pump(
    WidgetTester tester, {
    Size size = const Size(1000, 600),
    Brightness brightness = Brightness.light,
  }) async {
    final f = _Fixture();
    final d = DeckHarness.open(fixture: f.b);
    d.editor.setCurrentSlide(f.slide);
    final renderer = SlideRenderer(
      model: d.session.model,
      fonts: RecordingFontRegistry(),
    );
    final c = SlideCanvasController.attach(d.editor, renderer: renderer);
    addTearDown(() async {
      textEditingOf(d.editor).dispose();
      c.dispose();
      renderer.dispose();
      await d.dispose();
    });
    await pumpSlides(
      tester,
      d.h,
      CanvasRegion(
        services: d.services,
        editor: d.editor,
        onContextMenu: (_, _) {},
      ),
      size: size,
      brightness: brightness,
    );
    return _Rig(d, f, c);
  }

  Offset at(WidgetTester tester, double x, double y) =>
      tester.getTopLeft(find.byType(SlideCanvas)) +
      c.viewport.toViewport(Offset(x, y));

  int _time = 1000;
  Duration _next([int ms = 1000]) => Duration(milliseconds: _time += ms);

  Future<void> click(WidgetTester tester, double x, double y) async {
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.down(at(tester, x, y), timeStamp: _next());
    await g.up(timeStamp: _next(10));
    await tester.pump();
    await tester.pump();
  }

  Future<void> doubleClick(WidgetTester tester, double x, double y) async {
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    final p = at(tester, x, y);
    await g.down(p, timeStamp: _next());
    await g.up(timeStamp: _next(20));
    await g.down(p, timeStamp: _next(80));
    await g.up(timeStamp: _next(20));
    await tester.pump();
    await tester.pump();
  }

  Future<void> drag(
    WidgetTester tester,
    Offset from,
    Offset to, {
    int steps = 4,
  }) async {
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.down(at(tester, from.dx, from.dy), timeStamp: _next());
    for (var i = 1; i <= steps; i++) {
      final p = Offset.lerp(from, to, i / steps)!;
      await g.moveTo(at(tester, p.dx, p.dy), timeStamp: _next(16));
      await tester.pump();
    }
    await g.up(timeStamp: _next(16));
    await tester.pump();
    await tester.pump();
  }

  Map<String, Object?> data(String id) =>
      jsonDecode(model.element(id)!.str(ElementCols.dataJson)!)
          as Map<String, Object?>;
}

void main() {
  group('Given crop mode (03 §6.5.4)', () {
    testWidgets('when an image is double-clicked, a side handle dragged and '
        'Enter pressed then crop and frame change in one undo step', (
      tester,
    ) async {
      final r = await _Rig.pump(tester);
      await r.doubleClick(tester, 700, 250);
      final mode = ImageCropMode.of(r.ed)!;
      expect(mode.active, isTrue);
      expect(mode.elementId, r.f.photo);
      expect(
        find.byKey(const ValueKey('slides.image.cropBar')),
        findsOneWidget,
      );

      // The right-middle handle moves left by 200 su.
      await r.drag(tester, const Offset(1000, 250), const Offset(800, 250));
      expect(mode.state!.box.width, closeTo(400, 0.5));
      expect(r.model.element(r.f.photo)!.width, 600, reason: 'not written');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(mode.active, isFalse);
      final e = r.model.element(r.f.photo)!;
      expect(e.width, closeTo(400, 0.5));
      expect(e.x, closeTo(400, 0.5));
      final crop = ImageCrop.fromJson(r.data(r.f.photo)['crop']);
      expect(crop.r, closeTo(1 / 3, 1e-3));
      expect(r.d.undoLabels, hasLength(1));

      await r.d.undo();
      expect(r.model.element(r.f.photo)!.width, 600);
      expect(r.data(r.f.photo)['crop'], isNull);
    });

    testWidgets('when the image is dragged inside the box and Esc pressed '
        'then nothing is written', (tester) async {
      final r = await _Rig.pump(tester);
      selectionOf(r.ed).select([r.f.photo]);
      await r.d.run('slides.image.crop');
      final mode = ImageCropMode.of(r.ed)!;
      expect(mode.active, isTrue);
      mode.setAspect('1:1');
      expect(mode.state!.box.width, closeTo(mode.state!.box.height, 1e-6));
      await r.drag(tester, const Offset(700, 250), const Offset(650, 250));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(mode.active, isFalse);
      expect(r.d.undoLabels, isEmpty);
      expect(r.data(r.f.photo)['crop'], isNull);
    });

    testWidgets('when Fit is pressed on the crop bar and Done then the whole '
        'image shows', (tester) async {
      final r = await _Rig.pump(tester);
      selectionOf(r.ed).select([r.f.photo]);
      await r.d.run('slides.image.crop', {
        'id': r.f.photo,
        'crop': {'l': 0.25, 't': 0, 'r': 0.25, 'b': 0},
        'width': 300,
        'x': 550,
      });
      await r.d.run('slides.image.crop');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('slides.image.cropFit')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('slides.image.cropDone')));
      await tester.pumpAndSettle();
      expect(ImageCrop.fromJson(r.data(r.f.photo)['crop']).isNone, isTrue);
      final e = r.model.element(r.f.photo)!;
      expect(e.width! / e.height!, closeTo(2, 1e-2));
    });
  });

  for (final brightness in Brightness.values) {
    testWidgets('when crop mode and a cell range show at 360 px in '
        '${brightness.name} mode then nothing overflows', (tester) async {
      final r = await _Rig.pump(
        tester,
        size: const Size(360, 640),
        brightness: brightness,
      );
      selectionOf(r.ed).select([r.f.photo]);
      await r.d.run('slides.image.crop');
      await tester.pump();
      expect(
        find.byKey(const ValueKey('slides.image.cropBar')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await r.d.run('slides.image.cropCancel');
      await r.d.run('slides.table.selectCells', {
        'id': r.f.table,
        'row': 0,
        'column': 0,
        'rowSpan': 2,
        'colSpan': 2,
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  group('Given a selected table (03 §6.6)', () {
    testWidgets('when a cell is clicked, text typed and Tab pressed then the '
        'cell is written and the next cell edits', (tester) async {
      final r = await _Rig.pump(tester);
      selectionOf(r.ed).select([r.f.table]);
      await tester.pump();
      // Row 1 (80 su high), column 1 (300 su wide).
      await r.click(tester, 750, 720);
      final host = textEditingOf(r.ed);
      expect(host.cell, (rowId: r.f.rows[1], columnId: r.f.cols[1]));

      host.active!.insertText('Mid');
      host.commit();
      final ix = r.model.indexes.table(r.f.table);
      expect(
        SlidesText.plainText(ix.cell(r.f.rows[1], r.f.cols[1])!.text).trim(),
        'Mid',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.pump();
      expect(host.cell, (rowId: r.f.rows[1], columnId: r.f.cols[2]));

      // Esc: the cell becomes the cell selection; arrows move it.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(host.isEditing, isFalse);
      final cells = TableCellSelection.of(r.ed);
      expect(cells.focus, (rowId: r.f.rows[1], columnId: r.f.cols[2]));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(cells.focus, (rowId: r.f.rows[2], columnId: r.f.cols[2]));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();
      expect(cells.range, TableRange(r.f.table, 2, 1, 2, 2));
      // Enter edits the active cell.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(host.cell, (rowId: r.f.rows[2], columnId: r.f.cols[1]));
    });

    testWidgets('when Tab is pressed in the last cell then a row is added', (
      tester,
    ) async {
      final r = await _Rig.pump(tester);
      selectionOf(r.ed).select([r.f.table]);
      await tester.pump();
      await r.click(tester, 1100, 800);
      final host = textEditingOf(r.ed);
      expect(host.cell, (rowId: r.f.rows[2], columnId: r.f.cols[2]));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final ix = r.model.indexes.table(r.f.table);
      expect(ix.rows, hasLength(4));
      expect(host.cell, (rowId: ix.rows[3].id, columnId: r.f.cols[0]));
    });

    testWidgets('when dragging across cells then a range is selected and '
        'highlighted; a merge from the context state works on it', (
      tester,
    ) async {
      final r = await _Rig.pump(tester);
      selectionOf(r.ed).select([r.f.table]);
      await tester.pump();
      await r.drag(tester, const Offset(400, 640), const Offset(700, 720));
      final cells = TableCellSelection.of(r.ed);
      expect(cells.range, TableRange(r.f.table, 0, 0, 1, 1));
      expect(textEditingOf(r.ed).isEditing, isFalse);
      await r.d.run('slides.table.mergeCells');
      final ix = r.model.indexes.table(r.f.table);
      expect(ix.merges.single.rowSpan, 2);
    });

    testWidgets('when an inner column border is dragged then the two columns '
        'are resized in one step', (tester) async {
      final r = await _Rig.pump(tester);
      selectionOf(r.ed).select([r.f.table]);
      await tester.pump();
      await r.drag(tester, const Offset(600, 700), const Offset(700, 700));
      await tester.pumpAndSettle();
      final ix = r.model.indexes.table(r.f.table);
      expect(ix.columns[0].size, closeTo(400, 1));
      expect(ix.columns[1].size, closeTo(200, 1));
      expect(ix.columns[2].size, closeTo(300, 1));
      expect(r.d.undoLabels, hasLength(1));
      expect(r.model.element(r.f.table)!.x, 300, reason: 'not moved');
    });

    testWidgets('when cells are selected and Bold runs then their whole '
        'text toggles (the theme makes the header bold, so it becomes '
        'regular; one step)', (tester) async {
      final r = await _Rig.pump(tester);
      selectionOf(r.ed).select([r.f.table]);
      TableCellSelection.of(r.ed).selectAt(r.f.table, 0, 0);
      await tester.pump();
      final res = await r.d.run('slides.format.bold');
      expect(res.status, CommandStatus.ok, reason: res.message);
      final text = r.model.indexes
          .table(r.f.table)
          .cell(r.f.rows[0], r.f.cols[0])!
          .text!;
      expect(text, contains('"weight":400'));
      expect(r.d.undoLabels, hasLength(1));
    });

    testWidgets(
      'when the table is double-clicked then the clicked cell edits',
      (tester) async {
        final r = await _Rig.pump(tester);
        await r.doubleClick(tester, 450, 640);
        expect(textEditingOf(r.ed).cell, (
          rowId: r.f.rows[0],
          columnId: r.f.cols[0],
        ));
      },
    );
  });

  group('Given an image whose upload was refused on quota', () {
    testWidgets('when the canvas shows it then it reads "Not uploaded — out '
        'of storage" with Retry and Remove', (tester) async {
      final r = await _Rig.pump(tester);
      final files = FakeFiles()..full = true;
      final net = ConnectivityService(ping: () async {});
      final queue = SlidesPendingUploads(
        store: MemoryPendingUploadStore(),
        files: files,
        connectivity: net,
      );
      addTearDown(queue.dispose);
      SlidesPendingUploads.installQueue(r.d.services, queue);
      await tester.runAsync(() async {
        await queue.start();
        await queue.add(
          fileUuid: _file,
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/png',
          fileName: 'a.png',
        );
        await queue.flush();
      });
      SlidesImageService.of(r.ed).notifyListeners();
      await tester.pump();
      expect(
        find.byKey(ValueKey('slides.image.outOfStorage.${r.f.photo}')),
        findsOneWidget,
      );
      expect(find.text('Not uploaded — out of storage'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(r.model.element(r.f.photo), isNull);
    });
  });

  group('Given the inspector', () {
    for (final brightness in Brightness.values) {
      for (final width in [300.0, 360.0]) {
        testWidgets('when an image or a table is selected at ${width.toInt()} '
            'px in ${brightness.name} mode then their sections show without '
            'overflow', (tester) async {
          final f = _Fixture();
          final d = DeckHarness.open(fixture: f.b);
          addTearDown(d.dispose);
          d.editor.setCurrentSlide(f.slide);
          d.editor.openInspector(InspectorTab.format);
          for (final (id, sections) in [
            (f.photo, ['image', 'border', 'effects', 'arrange']),
            (f.table, ['table', 'cell', 'text', 'arrange']),
          ]) {
            selectionOf(d.editor).select([id]);
            await pumpSlides(
              tester,
              d.h,
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  height: 1600,
                  child: DeckInspector(services: d.services, editor: d.editor),
                ),
              ),
              size: Size(width, 1600),
              brightness: brightness,
            );
            for (final s in sections) {
              expect(
                find.byKey(ValueKey<String>('slides.inspector.section.$s')),
                findsOneWidget,
                reason: '$id $s',
              );
            }
            expect(find.text('Not available yet'), findsNothing);
            expect(tester.takeException(), isNull);
          }
        });
      }
    }

    testWidgets('when a table border edge is pressed then the borders are '
        'written in one step', (tester) async {
      final f = _Fixture();
      final d = DeckHarness.open(fixture: f.b);
      addTearDown(d.dispose);
      d.editor.setCurrentSlide(f.slide);
      d.editor.openInspector(InspectorTab.format, section: 'cell');
      selectionOf(d.editor).select([f.table]);
      await pumpSlides(
        tester,
        d.h,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            height: 1600,
            child: DeckInspector(services: d.services, editor: d.editor),
          ),
        ),
        size: const Size(320, 1600),
      );
      final outer = find.byKey(const ValueKey('slides.table.border.outer'));
      await tester.ensureVisible(outer);
      await tester.tap(outer);
      await tester.pumpAndSettle();
      final ix = d.model.indexes.table(f.table);
      expect(
        ix.cell(f.rows[0], f.cols[0])!.str(TableCellCols.borderTop),
        '1|solid|theme:text1',
      );
      expect(d.undoLabels, hasLength(1));
    });
  });
}
