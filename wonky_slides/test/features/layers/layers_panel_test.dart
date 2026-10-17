import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/layers/layers_panel.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart';

/// The Layers panel (Slides 03 §8.1, §17.2; SL-34).
void main() {
  late String slide, back, front, grp, c1, c2;

  DeckBuilder fixture() {
    final b = DeckBuilder(title: 'Layers');
    slide = b.slide(layoutKey: 'blank');
    back = b.shape(slide, x: 100, y: 300, text: 'Back');
    grp = '00000000-0000-4000-8000-00000000cc01';
    c1 = b.shape(slide, x: 900, y: 300, width: 100, height: 100, parentId: grp);
    c2 = b.shape(
      slide,
      x: 1100,
      y: 500,
      width: 100,
      height: 100,
      parentId: grp,
    );
    b.elementGroup(
      slide,
      groupId: grp,
      x: 900,
      y: 300,
      width: 300,
      height: 300,
    );
    front = b.shape(slide, x: 400, y: 700, text: 'Front');
    return b;
  }

  Finder row(String id) => find.byKey(LayersPanelKeys.row(id));

  Future<DeckScreenRig> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1440, 900),
  }) async {
    final r = await pumpDeckScreen(
      tester,
      fixture: fixture(),
      brightness: brightness,
      size: size,
    );
    await r.run('slides.panel.layers', {'tab': 'layers'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return r;
  }

  for (final brightness in Brightness.values) {
    testWidgets('Given a slide (${brightness.name}) when the Layers panel '
        'opens then the elements are listed front-most first with the '
        'group children nested, and a click selects on the canvas', (
      tester,
    ) async {
      final r = await open(tester, brightness: brightness);

      expect(find.byKey(LayersPanelKeys.panel), findsOneWidget);
      final ys = [
        for (final id in [front, grp, c2, c1, back])
          tester.getTopLeft(row(id)).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(
        tester.getTopLeft(row(c1)).dx,
        greaterThanOrEqualTo(tester.getTopLeft(row(grp)).dx),
      );

      await tester.tap(find.byKey(LayersPanelKeys.name(back)));
      await tester.pump();
      expect(r.editor.selectedElementIds, [back]);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given the panel when the eye and lock of a row are clicked '
      'then the element is hidden and locked, one undo step each', (
    tester,
  ) async {
    final r = await open(tester);

    await tester.tap(find.byKey(LayersPanelKeys.hide(back)));
    await tester.pump();
    await tester.tap(find.byKey(LayersPanelKeys.lock(back)));
    await tester.pump();

    final e = r.editor.model.element(back)!;
    expect(e.hidden, isTrue);
    expect(e.locked, isTrue);
    expect(r.h.undoLabels, hasLength(2));
    // Locked and hidden elements stay selectable from the panel.
    await tester.tap(find.byKey(LayersPanelKeys.name(back)));
    await tester.pump();
    expect(r.editor.selectedElementIds, [back]);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the panel when a name is double-clicked and edited then '
      'the element is renamed', (tester) async {
    final r = await open(tester);

    final name = find.byKey(LayersPanelKeys.name(front));
    await tester.tap(name);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(name);
    await tester.pumpAndSettle();
    expect(find.byKey(LayersPanelKeys.renameField), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(LayersPanelKeys.renameField),
        matching: find.byType(EditableText),
      ),
      'Call to action',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(r.editor.model.element(front)!.name, 'Call to action');
    expect(find.text('Call to action'), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the panel when a row is dragged onto the top half of '
      'another then it moves in front of it (one step); dropped on a group '
      'it joins the group', (tester) async {
    final r = await open(tester);

    Future<void> drag(String id, Offset to) async {
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(LayersPanelKeys.name(id))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      for (var i = 1; i <= 8; i++) {
        final from = tester.getCenter(find.byKey(LayersPanelKeys.name(id)));
        await g.moveTo(Offset.lerp(from, to, i / 8)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump();
    }

    // Back to the top: onto the upper quarter of the front row.
    final frontTop = tester.getTopLeft(row(front)) + const Offset(80, 6);
    await drag(back, frontTop);
    final roots = r.editor.model.indexes.tree(slide).roots;
    expect(roots.last.id, back);
    expect(r.h.undoLabels, hasLength(1));

    // Front into the group: onto the middle of the group row.
    await drag(front, tester.getCenter(row(grp)));
    expect(r.editor.model.element(front)!.parentId, grp);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the panel when the arrows and Alt+Shift+↑ are used then '
      'the selection moves between rows and the element moves up a row', (
    tester,
  ) async {
    final r = await open(tester);
    await tester.tap(find.byKey(LayersPanelKeys.name(back)));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(r.editor.selectedElementIds, [c1]);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(r.editor.selectedElementIds, [back]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    final roots = [
      for (final e in r.editor.model.indexes.tree(slide).roots) e.id,
    ];
    // Back is now in front of the group (rows: front, back, group).
    expect(roots.indexOf(back), greaterThan(roots.indexOf(grp)));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the reading order tab when a row moves down then the '
      'custom order is written, and Reset to automatic clears it', (
    tester,
  ) async {
    final r = await open(tester);
    await tester.tap(find.byKey(LayersPanelKeys.tabReadingOrder));
    await tester.pump();

    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(
            'slides.layers.order.',
          ) &&
          !(w.key! as ValueKey<String>).value.endsWith('.up') &&
          !(w.key! as ValueKey<String>).value.endsWith('.down'),
    );
    expect(rows, findsWidgets);
    final firstId = (tester.widget(rows.first).key! as ValueKey<String>).value
        .split('.')
        .last;
    await tester.tap(find.byKey(LayersPanelKeys.orderDown(firstId)));
    await tester.pump();

    final keyed = r.editor.model
        .allElementsOf(slide)
        .where((e) => e.readingKey != null);
    expect(keyed, isNotEmpty);

    await tester.tap(find.byKey(LayersPanelKeys.resetOrder));
    await tester.pump();
    expect(
      r.editor.model.allElementsOf(slide).where((e) => e.readingKey != null),
      isEmpty,
    );
    expect(r.h.undoLabels, hasLength(2));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a 640 px window when the Layers panel opens then '
      'nothing overflows', (tester) async {
    final r = await open(tester, size: const Size(640, 780));

    expect(find.byKey(LayersPanelKeys.panel), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(LayersPanelKeys.tabReadingOrder));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a slide with a layout when From layout is opened then '
      'Edit layout switches to masters mode on that layout', (tester) async {
    final r = await open(tester);

    await tester.tap(find.byKey(LayersPanelKeys.fromLayout));
    await tester.pump();
    await tester.tap(find.byKey(LayersPanelKeys.editLayout));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(r.editor.mode.name, 'masters');
    expect(
      r.editor.surfaceId,
      r.editor.model.slide(slide)!.layoutId,
      reason: 'the slide layout is edited',
    );
    // In masters mode the panel lists the layout's elements.
    expect(find.byKey(LayersPanelKeys.panel), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });
}
