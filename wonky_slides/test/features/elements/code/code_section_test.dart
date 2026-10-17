import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/elements/code/code_blocks.dart';
import 'package:wonky_slides/features/elements/code/code_canvas_mode.dart';
import 'package:wonky_slides/features/elements/code/code_section.dart';
import 'package:wonky_slides_core/model.dart' show ElementKind;
import 'package:wonky_slides_core/testing.dart' show DeckBuilder;
import 'package:wonky_ui/testing.dart';

import '../../../support/deck_screen.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey<String>(k));

  late String slide, code;

  DeckBuilder deck() {
    final b = DeckBuilder(title: 'Code');
    slide = b.slide(layoutKey: 'blank');
    (code, _) = b.codeBlock(
      slide,
      states: [
        'void main() {\n  print(1);\n}',
        'void main() {\n  final x = 2;\n  print(x);\n}',
      ],
      highlights: ['2|1-3', '9'],
      annotations: [
        jsonEncode({
          'v': 1,
          'steps': {
            '1': {'text': 'Prints **one**'},
          },
        }),
      ],
      data: {'v': 1, 'language': 'dart', 'title': 'lib/main.dart'},
    );
    return b;
  }

  for (final (size, brightness) in [
    (const Size(1440, 900), Brightness.light),
    (const Size(1440, 900), Brightness.dark),
    (const Size(640, 800), Brightness.dark),
  ]) {
    testWidgets('Given a selected code block at ${size.width.toInt()} px '
        '(${brightness.name}) when the inspector shows the Code section then '
        'the options, the state strip and the line steps render', (
      tester,
    ) async {
      final r = await pumpDeckScreen(
        tester,
        fixture: deck(),
        initialSlideId: slide,
        size: size,
        brightness: brightness,
      );
      r.editor.selectElements([code]);
      if (size.width < 768) r.editor.setInspectorVisible(true);
      await tester.pump();

      expect(key('slides.inspector.section.code'), findsOneWidget);
      expect(find.byKey(CodeSectionKeys.chip(0)), findsOneWidget);
      expect(find.byKey(CodeSectionKeys.chip(1)), findsOneWidget);
      expect(find.byKey(CodeSectionKeys.step(1)), findsOneWidget);
      expect(find.textContaining('Prints **one**'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given the state strip when state 2 is chosen then the canvas '
      'shows it, its steps are listed and a step previews on the canvas', (
    tester,
  ) async {
    final r = await pumpDeckScreen(
      tester,
      fixture: deck(),
      initialSlideId: slide,
    );
    r.editor.selectElements([code]);
    await tester.pump();
    await tester.ensureVisible(find.byKey(CodeSectionKeys.chip(1)));
    await tester.tap(find.byKey(CodeSectionKeys.chip(1)));
    await tester.pump();

    final view = CodeBlockView.of(r.editor);
    expect(view.stateIndexOf(code), 1);
    // State 2's step points past the end: the issue shows inline.
    expect(find.textContaining('points past the end'), findsOneWidget);

    await r.run('slides.code.selectState', {'index': 0});
    await tester.pump();
    await tester.ensureVisible(find.byKey(CodeSectionKeys.step(0)));
    await tester.tap(find.byKey(CodeSectionKeys.step(0)));
    await tester.pump();
    expect(view.stepOf(code), 0);
    final scene = CodeCanvasMode.of(r.editor)!.sceneOf(code)!;
    expect(scene.step, 0);
    expect(scene.lines.where((l) => l.highlighted).map((l) => l.index), [1]);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the state strip when + is pressed then a state is added '
      'after the selected one and undo removes it', (tester) async {
    final r = await pumpDeckScreen(
      tester,
      fixture: deck(),
      initialSlideId: slide,
    );
    r.editor.selectElements([code]);
    await tester.pump();
    await tester.ensureVisible(find.byKey(CodeSectionKeys.of('addState')));
    await tester.tap(find.byKey(CodeSectionKeys.of('addState')));
    await tester.pump();

    expect(r.editor.model.codeStatesOf(code), hasLength(3));
    expect(find.byKey(CodeSectionKeys.chip(2)), findsOneWidget);
    await r.run('shell.edit.undo');
    await tester.pump();
    expect(r.editor.model.codeStatesOf(code), hasLength(2));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a code block from MCP without states when selected '
      'then the section still renders', (tester) async {
    final b = DeckBuilder(title: 'Bare');
    final s = b.slide(layoutKey: 'blank');
    final bare = b.element(s, ElementKind.code);
    final r = await pumpDeckScreen(tester, fixture: b, initialSlideId: s);
    r.editor.selectElements([bare]);
    await tester.pump();

    expect(key('slides.inspector.section.code'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });
}
