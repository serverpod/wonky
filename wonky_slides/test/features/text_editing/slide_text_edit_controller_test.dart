import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_slides/features/text_editing/slide_text_editor.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;

import 'text_edit_fixture.dart';

String _text(TextEditFixture f, String id) =>
    SlidesText.plainText(f.session.model.element(id)!.text);

String _docText(SlideTextEditController c) =>
    [for (final n in c.document) (n as TextNode).text.toPlainText()].join('\n');

/// Runs [body] with a fixed clock (undo coalescing window, 15 §4).
Future<void> _fixed(Future<void> Function() body) =>
    withClock(Clock.fixed(DateTime.utc(2026, 10, 15, 12)), body);

void main() {
  group('Given a text box being edited', () {
    late TextEditFixture f;
    late String id;
    late SlideTextEditController c;

    Future<void> open(
      WidgetTester tester, {
      List<Map<String, Object?>>? ops,
      ElementKind kind = ElementKind.text,
      Map<String, Object?>? textStyle,
      Map<String, Object?>? data,
      double h = 200,
    }) async {
      f = TextEditFixture();
      id = f.element(
        ops ??
            [
              {'insert': 'Hello\n'},
            ],
        kind: kind,
        textStyle: textStyle,
        data: data,
        h: h,
      );
      await f.loadFonts(tester);
      c = f.controller(id);
      addTearDown(c.dispose);
      await pumpEditing(tester, f, c);
    }

    testWidgets('when a burst is typed then it is written once after 300 ms '
        'of idle time as one "Typing" step', (tester) async {
      await _fixed(() async {
        await open(tester);

        await tester.typeImeText(' world');
        await tester.pump(const Duration(milliseconds: 100));
        final before = _text(f, id);
        await tester.pump(const Duration(milliseconds: 300));

        expect(before, 'Hello\n');
        expect(_text(f, id), 'Hello world\n');
        expect(f.undo.undoLabel.value, 'Typing');
        expect(f.undo.history(), hasLength(1));
        expect(f.session.persistedLabels, hasLength(1));
      });
    });

    testWidgets('when two bursts are typed then undo removes both (one '
        'step) and the editor shows the original text', (tester) async {
      await _fixed(() async {
        await open(tester);

        await tester.typeImeText(' brave');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.typeImeText(' world');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.runAsync(f.undo.undo);
        await tester.pump();

        expect(f.undo.history(), isEmpty);
        expect(_text(f, id), 'Hello\n');
        expect(_docText(c), 'Hello');
        expectOverlayMatchesStatic(tester, c);
      });
    });

    testWidgets('when undone and redone then the editor follows the model', (
      tester,
    ) async {
      await _fixed(() async {
        await open(tester);
        await tester.typeImeText('!');
        await tester.pump(const Duration(milliseconds: 400));

        await tester.runAsync(f.undo.undo);
        await tester.runAsync(f.undo.redo);
        await tester.pump();

        expect(_text(f, id), 'Hello!\n');
        expect(_docText(c), 'Hello!');
      });
    });

    testWidgets('when Mod+Z is pressed mid-burst then the burst is written '
        'first and the host undo runs', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      var undos = 0;
      f = TextEditFixture();
      id = f.element([
        {'insert': 'Hello\n'},
      ]);
      await f.loadFonts(tester);
      c = f.controller(id);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => Stack(
                  children: [
                    Positioned.fill(
                      child: SlideTextEditorOverlay(
                        controller: c,
                        zoom: 0.5,
                        onUndo: () => undos++,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.typeImeText('X');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

      debugDefaultTargetPlatformOverride = null;

      expect(undos, 1);
      expect(_text(f, id), 'HelloX\n');
      expect(c.hasPendingEdits, isFalse);
    });

    testWidgets('when a collaborator changes the body then the document is '
        'patched and the caret stays in range', (tester) async {
      await open(tester);
      final before = f.session.model.element(id)!.text;

      f.session.model.applyChanges([
        RowChange.update(
          SlidesTables.slideElement,
          id,
          {SlidesCols.text: before},
          {
            SlidesCols.text: jsonEncode([
              {'insert': 'Hi\nthere\n'},
            ]),
          },
        ),
      ]);
      await tester.pump();

      expect(_docText(c), 'Hi\nthere');
      final sel = c.composer.selection!;
      final node = c.document.getNodeById(sel.extent.nodeId)! as TextNode;
      expect(
        (sel.extent.nodePosition as TextNodePosition).offset,
        lessThanOrEqualTo(node.text.length),
      );
      expectOverlayMatchesStatic(tester, c);
    });

    testWidgets('when Enter is pressed at the end of a heading then the new '
        'paragraph keeps the paragraph attributes', (tester) async {
      await open(
        tester,
        ops: [
          {'insert': 'Heading'},
          {
            'insert': '\n',
            'attributes': {'style': 'heading', 'align': 'center'},
          },
        ],
      );

      await tester.pressEnter();
      await tester.typeImeText('Next');
      c.commit();

      expect(jsonDecode(f.session.model.element(id)!.text!), [
        {'insert': 'Heading'},
        {
          'insert': '\n',
          'attributes': {'style': 'heading', 'align': 'center'},
        },
        {'insert': 'Next'},
        {
          'insert': '\n',
          'attributes': {'style': 'heading', 'align': 'center'},
        },
      ]);
    });

    testWidgets('when text is typed into a growing box then the geometry '
        'follows and the overlay still equals the static layout', (
      tester,
    ) async {
      await open(tester, h: 80);
      final height = c.geometry.contentHeight;

      await tester.typeImeText(
        ' and a lot more words so that the text box has to grow downwards '
        'because its auto-fit mode is resize',
      );
      await tester.pump();

      expect(c.geometry.contentHeight, greaterThan(height));
      expectOverlayMatchesStatic(tester, c);
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('when a shape that shrinks text gets more text then the '
        'live auto-fit scale drops and the overlay follows', (tester) async {
      await open(
        tester,
        kind: ElementKind.shape,
        data: {'geometry': 'ellipse'},
        textStyle: {'autofit': 'shrink'},
        h: 220,
      );
      expect(c.geometry.spec.scale, 1);

      for (var i = 0; i < 6; i++) {
        await tester.typeImeText(' more words to make it overflow');
      }
      await tester.pump();

      expect(c.geometry.spec.scale, lessThan(1));
      expectOverlayMatchesStatic(tester, c);
      await tester.pump(const Duration(milliseconds: 400));
    });

    testWidgets('when the session closes then pending edits are written', (
      tester,
    ) async {
      await open(tester);

      await tester.typeImeText('?');
      final plan = c.close();

      expect(plan, isNotNull);
      expect(_text(f, id), 'Hello?\n');
    });

    testWidgets('when the caret is shown then it is in the overlay', (
      tester,
    ) async {
      await open(tester);

      expect(c.composer.selection, isNotNull);
      expect(
        find.descendant(
          of: find.byType(SlideTextEditorOverlay),
          matching: find.byType(SuperEditor),
        ),
        findsOneWidget,
      );
    });
  });

  group('Given a rotated text box being edited', () {
    for (final rotation in [0.0, 90.0, 30.0]) {
      testWidgets('when a glyph is clicked at $rotation° then the caret goes '
          'before it, and a drag selects up to the glyph under the pointer', (
        tester,
      ) async {
        final f = TextEditFixture();
        final id = f.element(
          [
            {'insert': 'Click into rotated text\n'},
          ],
          x: 600,
          y: 300,
          w: 700,
          rotation: rotation,
        );
        await f.loadFonts(tester);
        final c = f.controller(id);
        addTearDown(c.dispose);
        await pumpEditing(tester, f, c);
        final toScreen = Matrix4.diagonal3Values(0.5, 0.5, 1)
          ..multiply(c.geometry.textToSlide);
        final para = staticParagraphs(c).first;
        Offset glyph(int i, {double at = 0.25}) {
          final b = para.paragraph.getBoxesForRange(i, i + 1).first;
          return MatrixUtils.transformPoint(
            toScreen,
            Offset(
              para.dx + b.left + (b.right - b.left) * at,
              para.dy + (b.top + b.bottom) / 2,
            ),
          );
        }

        await tester.tapAt(glyph(6), kind: PointerDeviceKind.mouse);
        await tester.pump(kDoubleTapTimeout);
        final caret = c.composer.selection!;

        final gesture = await tester.startGesture(
          glyph(0),
          kind: PointerDeviceKind.mouse,
        );
        // A small first move (pan slop) so the drag starts at glyph 0.
        await gesture.moveBy(const Offset(0, 3));
        await gesture.moveTo(glyph(4, at: 0.75));
        await gesture.moveTo(glyph(10, at: 0.75));
        await gesture.up();
        await tester.pump(kDoubleTapTimeout);
        final range = c.composer.selection!;

        expect(caret.isCollapsed, isTrue);
        expect((caret.extent.nodePosition as TextNodePosition).offset, 6);
        expect((range.base.nodePosition as TextNodePosition).offset, 0);
        expect((range.extent.nodePosition as TextNodePosition).offset, 11);
      });
    }
  });

  group('Given the web IME (hidden textarea)', () {
    tearDown(() => debugIsWebOverride = null);

    for (final rotation in [0.0, 90.0]) {
      testWidgets('when a box rotated by $rotation° is edited then the IME '
          'gets the transform of the edited paragraph (zoom and rotation)', (
        tester,
      ) async {
        debugIsWebOverride = WebPlatformOverride.web;
        final f = TextEditFixture();
        final id = f.element(
          [
            {'insert': 'Rotated\n'},
          ],
          x: 600,
          y: 300,
          w: 600,
          rotation: rotation,
        );
        await f.loadFonts(tester);
        final c = f.controller(id);
        addTearDown(c.dispose);
        tester.testTextInput.log.clear();

        await pumpEditing(tester, f, c);
        await tester.typeImeText('!');
        await tester.pump();

        final calls = tester.testTextInput.log
            .where((m) => m.method == 'TextInput.setEditableSizeAndTransform')
            .toList();
        expect(calls, isNotEmpty);
        final args = (calls.last.arguments as Map).cast<String, Object?>();
        final m = (args['transform']! as List).cast<num>();
        final expected = Matrix4.diagonal3Values(0.5, 0.5, 1)
          ..multiply(c.geometry.textToSlide);
        // The 2×2 linear part: zoom × rotation.
        expect(m[0], moreOrLessEquals(expected.storage[0], epsilon: 1e-6));
        expect(m[1], moreOrLessEquals(expected.storage[1], epsilon: 1e-6));
        expect(m[4], moreOrLessEquals(expected.storage[4], epsilon: 1e-6));
        expect(m[5], moreOrLessEquals(expected.storage[5], epsilon: 1e-6));
        expect(_text(f, id), 'Rotated\n');
        expect(c.json, contains('Rotated!'));
        await tester.pump(const Duration(milliseconds: 400));
      });
    }
  });
}
