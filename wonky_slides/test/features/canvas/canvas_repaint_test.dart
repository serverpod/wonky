import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/canvas/slide_canvas.dart';
import 'package:wonky_slides/features/stage/slide_stage.dart';

import 'canvas_rig.dart';

/// Repaint behaviour of the canvas (CQ-43, 03 §2.4): a drag moves the
/// element's cached layer instead of repainting it or rebuilding the stage.
void main() {
  testWidgets('Given a shape inside the slide when dragging it then pointer '
      'moves composite its layer without repainting or rebuilding the '
      'stage', (tester) async {
    final rig = await CanvasRig.pump(tester);
    final a = rig.fixture.a; // 100,100 400×200
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.down(rig.at(tester, 300, 200));
    await tester.pump();
    await g.moveTo(rig.at(tester, 320, 210));
    await tester.pump();
    await g.moveTo(rig.at(tester, 330, 215));
    await tester.pump();

    final paints = SlideStage.debugNodePaints;
    final builds = SlideStage.debugBuilds;
    for (var i = 1; i <= 5; i++) {
      await g.moveTo(rig.at(tester, 330.0 + i * 10, 215.0 + i * 5));
      await tester.pump();
    }

    expect(SlideStage.debugNodePaints - paints, 0);
    expect(SlideStage.debugBuilds - builds, 0);
    final layer = find.descendant(
      of: find.byKey(ValueKey(a)),
      matching: find.byType(Transform),
    );
    expect(layer, findsOneWidget);
    final t = tester.widget<Transform>(layer).transform;
    final s = rig.controller.viewport.scale;
    // 80 su right of the start of the drag, in layer pixels.
    expect(t.getTranslation().x, closeTo(80 * s, 0.01));

    await g.up();
    await tester.pumpAndSettle();
    expect(rig.frame(a).x, closeTo(180, 0.01));
    expect(find.byType(SlideCanvas), findsOneWidget);
  });

  testWidgets('Given a shape dragged across the slide edge when moving then '
      'it is painted through the frame (dimmed outside the slide)', (
    tester,
  ) async {
    final rig = await CanvasRig.pump(tester);
    final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await g.down(rig.at(tester, 300, 200));
    await tester.pump();
    await g.moveTo(rig.at(tester, 200, 200));
    await tester.pump();
    final paints = SlideStage.debugNodePaints;

    await g.moveTo(rig.at(tester, 150, 200)); // a's left edge at -50
    await tester.pump();

    expect(SlideStage.debugNodePaints - paints, greaterThan(0));
    expect(
      find.descendant(
        of: find.byKey(ValueKey(rig.fixture.a)),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    await g.up();
    await tester.pumpAndSettle();
  });
}
