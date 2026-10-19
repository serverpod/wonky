/// Slides invalidation and render perf suite (CQ-38, Slides 03 §18): what
/// one edit costs on a 40-slide deck through the real editor screen (the
/// canvas, the navigator thumbnails), scene builds on a 100-slide deck,
/// thumbnail churn while typing, and pointer moves of a drag.
///
/// Counted per edit: scene nodes built (`SlideSceneBuilder.debugNodeBuilds`),
/// element layers painted (`SlideStage.debugNodePaints`), stage builds and
/// thumbnails recorded. Times are medians of debug JIT widget tests: only
/// comparable with each other on one machine (before/after a change), not
/// with the profile-mode budgets of 03 §18. The count budgets (after
/// CQ-43; numbers before/after in 03 §18) fail the
/// test on a regression. Tagged `perf` (skipped by default):
///
/// ```sh
/// flutter test -t perf --run-skipped test/perf
/// ```
@Tags(['perf'])
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_slides/features/canvas/slide_canvas.dart';
import 'package:wonky_slides/features/canvas/slide_canvas_controller.dart';
import 'package:wonky_slides/features/stage/slide_renderer.dart';
import 'package:wonky_slides/features/stage/slide_stage.dart';
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';

import '../features/stage/stage_fixture.dart' show RecordingFontRegistry;
import '../support/deck_screen.dart';

/// Median and p95 of samples (µs), printed in ms.
class PerfStats {
  PerfStats(this.name, List<int> micros) : samples = [...micros]..sort();

  final String name;
  final List<int> samples;

  double _at(double q) =>
      samples[math.min(samples.length - 1, (samples.length * q).floor())] /
      1000;

  double get median => _at(0.5);
  double get p95 => _at(0.95);

  @override
  String toString() =>
      '[perf] $name: median ${median.toStringAsFixed(2)} ms, '
      'p95 ${p95.toStringAsFixed(2)} ms (n=${samples.length})';
}

/// Counters of one measured action.
class Counts {
  Counts.start()
    : _nodes = SlideSceneBuilder.debugNodeBuilds,
      _paints = SlideStage.debugNodePaints,
      _stages = SlideStage.debugBuilds;

  final int _nodes, _paints, _stages;
  int nodes = 0, paints = 0, stages = 0;

  void stop() {
    nodes = SlideSceneBuilder.debugNodeBuilds - _nodes;
    paints = SlideStage.debugNodePaints - _paints;
    stages = SlideStage.debugBuilds - _stages;
  }

  @override
  String toString() =>
      'nodes built $nodes, layers painted $paints, stage builds $stages';
}

String _solid(String c) => jsonEncode({'v': 1, 'type': 'solid', 'color': c});

/// [slides] slides with a title, a body and [shapes] filled shapes with
/// text, two text boxes and a 3 × 3 table each.
DeckBuilder benchDeck({int slides = 40, int shapes = 20}) {
  final b = DeckBuilder(title: 'Bench');
  for (var s = 0; s < slides; s++) {
    final id = b.slide(title: 'Slide $s', body: 'Body of slide $s');
    for (var i = 0; i < shapes; i++) {
      b.shape(
        id,
        x: 60.0 + (i % 5) * 360,
        y: 260.0 + (i ~/ 5) * 190,
        width: 300,
        height: 150,
        text: 'Shape $i',
        fillJson: _solid(i.isEven ? '#3366FF' : '#22C55E'),
      );
    }
    b.textBox(id, 'A text box with a sentence or two of text on it.');
    b.textBox(id, 'Another text box.', y: 900);
    final (t, rows, cols) = b.table(
      id,
      rows: 3,
      cols: 3,
      x: 1300,
      y: 700,
      width: 500,
      height: 240,
    );
    for (final r in rows) {
      for (final c in cols) {
        b.cell(t, r, c, 'Cell');
      }
    }
  }
  return b;
}

RowChange _update(
  String table,
  String id,
  Map<String, Object?> before,
  Map<String, Object?> after,
) => RowChange.update(table, id, before, after);

void main() {
  group('Editor screen (40 slides × 25 elements)', () {
    late DeckScreenRig rig;
    late DeckModel model;
    late String slide0, slide5;
    late List<String> shapes0, shapes5;

    Future<void> open(WidgetTester tester) async {
      final b = benchDeck();
      rig = await pumpDeckScreen(tester, fixture: b);
      model = rig.session.model;
      slide0 = model.slides[0].id;
      slide5 = model.slides[5].id;
      List<String> shapesOf(String s) => [
        for (final e in model.elementsOf(s))
          if (e.kind == ElementKind.shape && e.placeholderType == null) e.id,
      ];
      shapes0 = shapesOf(slide0);
      shapes5 = shapesOf(slide5);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    /// Runs [edit] [n] times, each followed by one frame; prints the
    /// counts of the last sample and the median time.
    Future<Counts> measure(
      WidgetTester tester,
      String name,
      void Function(int i) edit, {
      int n = 12,
    }) async {
      final micros = <int>[];
      var last = Counts.start();
      final thumbs = rig.editor;
      final renderer = SlideCanvasController.of(thumbs)!.renderer;
      var recorded = 0;
      for (var i = 0; i < n; i++) {
        final r0 = renderer.thumbnails.debugRecords;
        final c = Counts.start();
        final sw = Stopwatch()..start();
        edit(i);
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        c.stop();
        recorded = renderer.thumbnails.debugRecords - r0;
        micros.add(sw.elapsedMicroseconds);
        last = c;
      }
      // ignore: avoid_print
      print(
        '${PerfStats(name, micros)} — $last, thumbnails recorded '
        '$recorded, thumbnail cache ${renderer.thumbnails.length}',
      );
      return last;
    }

    testWidgets('one element moves on the current slide', (tester) async {
      await open(tester);
      final id = shapes0[3];
      final c = await measure(tester, 'element edit (current slide)', (i) {
        final x = model.element(id)!.x!;
        model.applyChanges([
          _update(
            SlidesTables.slideElement,
            id,
            {ElementCols.x: x},
            {ElementCols.x: x + 1},
          ),
        ]);
      });
      // Only the moved element: its canvas node and thumbnail node.
      expect(c.nodes, lessThanOrEqualTo(2));
      expect(c.paints, lessThanOrEqualTo(1));
      await rig.close(tester);
    });

    testWidgets('speaker notes commit on the current slide', (tester) async {
      await open(tester);
      final c = await measure(tester, 'notes commit', (i) {
        final before = model.slide(slide0)!.notes;
        model.applyChanges([
          _update(
            SlidesTables.slide,
            slide0,
            {SlideCols.notes: before},
            {SlideCols.notes: deltaOf('Notes typed $i')},
          ),
        ]);
      });
      expect((c.nodes, c.paints, c.stages), (0, 0, 0));
      await rig.close(tester);
    });

    testWidgets('deck rename and guide move', (tester) async {
      await open(tester);
      await measure(tester, 'deck rename', (i) {
        final before = model.deck!.title;
        model.applyChanges([
          _update(
            SlidesTables.deck,
            model.deck!.id,
            {DeckCols.title: before},
            {DeckCols.title: 'Bench $i'},
          ),
        ]);
      });
      await measure(tester, 'guide move', (i) {
        final before = model.deck!.guidesJson;
        model.applyChanges([
          _update(
            SlidesTables.deck,
            model.deck!.id,
            {DeckCols.guidesJson: before},
            {
              DeckCols.guidesJson: jsonEncode({
                'v': 1,
                'vertical': [100 + i],
                'horizontal': <num>[],
              }),
            },
          ),
        ]);
      });
      await rig.close(tester);
    });

    testWidgets('a collaborator edits another slide', (tester) async {
      await open(tester);
      final id = shapes5[0];
      await measure(tester, 'element edit (other slide)', (i) {
        final x = model.element(id)!.x!;
        model.applyChanges([
          _update(
            SlidesTables.slideElement,
            id,
            {ElementCols.x: x},
            {ElementCols.x: x + 1},
          ),
        ]);
      });
      await rig.close(tester);
    });

    testWidgets('pointer moves while dragging a shape', (tester) async {
      await open(tester);
      final c = SlideCanvasController.of(rig.editor)!;
      final e = model.element(shapes0[6])!;
      Offset at(double x, double y) =>
          tester.getTopLeft(find.byType(SlideCanvas)) +
          c.viewport.toViewport(Offset(x, y));
      final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
      final x0 = e.x! + e.width! / 2, y0 = e.y! + e.height! / 2;
      await g.down(at(x0, y0));
      await tester.pump();
      // Past the drag threshold.
      await g.moveTo(at(x0 + 20, y0 + 10));
      await tester.pump();
      final micros = <int>[];
      final counts = Counts.start();
      const moves = 30;
      for (var i = 0; i < moves; i++) {
        final sw = Stopwatch()..start();
        await g.moveTo(at(x0 + 20 + i * 4, y0 + 10 + i * 2));
        await tester.pump(const Duration(milliseconds: 16));
        sw.stop();
        micros.add(sw.elapsedMicroseconds);
      }
      counts.stop();
      expect((counts.paints, counts.stages), (0, 0));
      // ignore: avoid_print
      print(
        '${PerfStats('drag pointer move', micros)} — per move: '
        'layers painted ${(counts.paints / moves).toStringAsFixed(1)}, '
        'stage builds ${(counts.stages / moves).toStringAsFixed(1)}, '
        'nodes built ${(counts.nodes / moves).toStringAsFixed(1)}',
      );
      await g.up();
      await tester.pump(const Duration(milliseconds: 400));
      await rig.close(tester);
    });
  });

  group('Scenes (100 slides × 30 elements)', () {
    test('cold scenes, one edit, theme and deck changes', () {
      final b = benchDeck(slides: 100, shapes: 25);
      final model = b.build();
      final renderer = SlideRenderer(
        model: model,
        fonts: RecordingFontRegistry(),
      );
      addTearDown(renderer.dispose);
      final ids = [for (final s in model.slides) s.id];

      var sw = Stopwatch()..start();
      var n0 = SlideSceneBuilder.debugNodeBuilds;
      for (final id in ids) {
        renderer.scene(id);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        '[perf] cold scenes of ${ids.length} slides: '
        '${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)} ms, '
        'nodes built ${SlideSceneBuilder.debugNodeBuilds - n0}',
      );

      // One element of slide 0 moves: its scene again.
      final el = model.elementsOf(ids.first).last;
      final micros = <int>[];
      var nodes = 0;
      for (var i = 0; i < 20; i++) {
        final x = model.element(el.id)!.x!;
        model.applyChanges([
          _update(
            SlidesTables.slideElement,
            el.id,
            {ElementCols.x: x},
            {ElementCols.x: x + 1},
          ),
        ]);
        n0 = SlideSceneBuilder.debugNodeBuilds;
        sw = Stopwatch()..start();
        renderer.scene(ids.first);
        sw.stop();
        nodes = SlideSceneBuilder.debugNodeBuilds - n0;
        micros.add(sw.elapsedMicroseconds);
      }
      // ignore: avoid_print
      print(
        '${PerfStats('scene after one edit', micros)} — nodes built $nodes',
      );

      int changedRevisions(void Function() change) {
        final before = {for (final id in ids) id: renderer.revision(id)};
        change();
        return ids.where((id) => renderer.revision(id) != before[id]).length;
      }

      final deckId = model.deck!.id;
      final renamed = changedRevisions(
        () => model.applyChanges([
          _update(
            SlidesTables.deck,
            deckId,
            {DeckCols.title: model.deck!.title},
            {DeckCols.title: 'Renamed'},
          ),
        ]),
      );
      final notes = changedRevisions(
        () => model.applyChanges([
          _update(
            SlidesTables.slide,
            ids.first,
            {SlideCols.notes: null},
            {SlideCols.notes: deltaOf('Notes')},
          ),
        ]),
      );
      // A layout no slide uses changes (masters mode).
      final used = {for (final s in model.slides) s.layoutId};
      final unused =
          [
            for (final t in model.themes)
              for (final m in model.mastersOf(t.id)) ...model.layoutsOf(m.id),
          ].firstWhere(
            (l) => !used.contains(l.id) && model.elementsOf(l.id).isNotEmpty,
          );
      final layoutEl = model.elementsOf(unused.id).first;
      final layout = changedRevisions(
        () => model.applyChanges([
          _update(
            SlidesTables.slideElement,
            layoutEl.id,
            {ElementCols.x: layoutEl.x},
            {ElementCols.x: (layoutEl.x ?? 0) + 5},
          ),
        ]),
      );
      // ignore: avoid_print
      print(
        '[perf] slides re-rendered of ${ids.length}: deck rename $renamed, '
        'notes of one slide $notes, unused layout edit $layout',
      );

      // Re-render everything after a rename (thumbnail pass).
      sw = Stopwatch()..start();
      n0 = SlideSceneBuilder.debugNodeBuilds;
      for (final id in ids) {
        renderer.scene(id);
      }
      sw.stop();
      // ignore: avoid_print
      print(
        '[perf] scenes of ${ids.length} slides after the changes: '
        '${(sw.elapsedMicroseconds / 1000).toStringAsFixed(1)} ms, '
        'nodes built ${SlideSceneBuilder.debugNodeBuilds - n0}',
      );
    });

    testWidgets('a 3000 × 2000 photo drawn 640 px wide', (tester) async {
      late Uint8List png;
      await tester.runAsync(() async {
        final rec = ui.PictureRecorder();
        Canvas(rec).drawRect(
          const Rect.fromLTWH(0, 0, 3000, 2000),
          Paint()..color = const Color(0xFF3366FF),
        );
        final img = await rec.endRecording().toImage(3000, 2000);
        png = (await img.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        img.dispose();
      });
      final b = DeckBuilder();
      final slide = b.slide(layoutKey: 'blank');
      b.element(
        slide,
        ElementKind.image,
        x: 0,
        y: 0,
        width: 960,
        height: 640,
        columns: {
          ElementCols.dataJson: jsonEncode({
            'v': 1,
            'src': 'wonky-file://big',
            'naturalWidth': 3000,
            'naturalHeight': 2000,
          }),
        },
      );
      final renderer = SlideRenderer(
        model: b.build(),
        images: MemorySlideImageResolver({'wonky-file://big': png}),
        fonts: RecordingFontRegistry(),
      );
      addTearDown(renderer.dispose);
      final scene = renderer.scene(slide)!;
      Future<void> pump() => tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 1280,
              height: 720,
              child: SlideStage(scene: scene, images: renderer.images),
            ),
          ),
        ),
      );
      await pump();
      for (var i = 0; i < 20 && renderer.images.length == 0; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await pump();
      }
      // ignore: avoid_print
      print(
        '[perf] decoded pixels of a 3000 × 2000 photo drawn 640 px wide: '
        '${(renderer.images.bytes / (1 << 20)).toStringAsFixed(1)} MB',
      );
    });

    testWidgets('thumbnail churn while typing on one slide', (tester) async {
      final b = benchDeck(slides: 10, shapes: 10);
      final model = b.build();
      final renderer = SlideRenderer(
        model: model,
        fonts: RecordingFontRegistry(),
      );
      addTearDown(renderer.dispose);
      final ids = [for (final s in model.slides) s.id];
      for (final id in ids) {
        renderer.thumbnail(id, width: 240);
      }
      final el = model.elementsOf(ids.first).firstWhere((e) => e.text != null);
      for (var i = 0; i < 20; i++) {
        model.applyChanges([
          _update(
            SlidesTables.slideElement,
            el.id,
            {SlidesCols.text: model.element(el.id)!.text},
            {SlidesCols.text: deltaOf('Typed ${'x' * i}')},
          ),
        ]);
        renderer.thumbnail(ids.first, width: 240);
      }
      // ignore: avoid_print
      print(
        '[perf] thumbnail cache after 20 commits on 1 of ${ids.length} '
        'slides: ${renderer.thumbnails.length} entries',
      );
    });
  });
}
