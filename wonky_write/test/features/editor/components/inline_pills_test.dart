import 'dart:ui' show BoxHeightStyle;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_write/features/editor/commands/write_editor_commands.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show MarkdownFlavor;

import '../ui/wonky_editor_test.dart' show pumpEditor;

DocumentPosition _at(String nodeId, int offset) => DocumentPosition(
  nodeId: nodeId,
  nodePosition: TextNodePosition(offset: offset),
);

/// The global left edge of the character at [offset] in [nodeId].
double _charLeft(String nodeId, int offset) {
  final layout = SuperEditorInspector.findDocumentLayout();
  final rect = layout.getRectForSelection(
    _at(nodeId, offset),
    _at(nodeId, offset + 1),
  )!;
  return layout.getGlobalOffsetFromDocumentOffset(rect.topLeft).dx;
}

/// The global rectangles of the pills the pill layer paints (Write 11 §7.2).
List<Rect> _pills(WidgetTester tester) {
  final rects = <Rect>[];
  final painters = find.byWidgetPredicate(
    (w) =>
        w is CustomPaint && w.painter.runtimeType.toString() == '_PillPainter',
  );
  for (final element in painters.evaluate()) {
    final box = element.renderObject! as RenderBox;
    expect(
      box,
      paints..everything((method, arguments) {
        if (method == #drawRRect) {
          final r = (arguments.first as RRect).outerRect;
          rects.add(
            Rect.fromPoints(
              box.localToGlobal(r.topLeft),
              box.localToGlobal(r.bottomRight),
            ),
          );
        }
        return true;
      }),
    );
  }
  return rects;
}

/// The global box the selection highlight paints for `[from, to)` in the
/// first paragraph: the text layout's `BoxHeightStyle.max` box, as
/// super_text_layout paints it.
Rect _highlightRect(WidgetTester tester, int from, int to) {
  final component = find.byType(TextComponent).first;
  final state = tester.state<TextComponentState>(component);
  final box = state.textLayout
      .getBoxesForSelection(
        TextSelection(baseOffset: from, extentOffset: to),
        boxHeightStyle: BoxHeightStyle.max,
      )
      .first
      .toRect();
  final text = tester.renderObject<RenderBox>(
    find
        .descendant(
          of: component,
          matching: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'SuperText',
          ),
        )
        .first,
  );
  return Rect.fromPoints(
    text.localToGlobal(box.topLeft),
    text.localToGlobal(box.bottomRight),
  );
}

/// The render box of the pill layer.
RenderBox _pillLayer() =>
    find
            .byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_PillPainter',
            )
            .evaluate()
            .single
            .renderObject!
        as RenderBox;

void main() {
  final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);

  for (final brightness in Brightness.values) {
    for (final (name, attributes) in [
      ('button', {'link': 'https://x.dev', 'linkStyle': 'button'}),
      (
        'secondary button',
        {'link': 'https://x.dev', 'linkStyle': 'buttonSecondary'},
      ),
      ('chip', {'chip': true}),
    ]) {
      testWidgets(
        'Given a $name at the start of a line (${brightness.name}) then its '
        'pill starts at the text margin and its label is inset (T-24)',
        (tester) async {
          final h = await pumpEditor(
            tester,
            Delta()
              ..insert('Docs', attributes)
              ..insert(' and more\nPlain line\n'),
            brightness: brightness,
          );
          final pillLine = h.controller.document.getNodeAt(0)!.id;
          final plain = h.controller.document.getNodeAt(1)!.id;
          final margin = _charLeft(plain, 0);

          final pill = _pills(tester).single;

          expect(pill.left, moreOrLessEquals(margin, epsilon: 0.5));
          expect(_charLeft(pillLine, 0), greaterThan(margin + 5));
        },
        variant: macOS,
      );
    }
  }

  testWidgets(
    'Given a button in the middle of a line then the line\'s text stays at '
    'the margin and the pill sits in the space before it',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('See ')
          ..insert('Docs', {'link': 'https://x.dev', 'linkStyle': 'button'})
          ..insert('\nPlain line\n'),
      );
      final pillLine = h.controller.document.getNodeAt(0)!.id;
      final plain = h.controller.document.getNodeAt(1)!.id;
      final margin = _charLeft(plain, 0);

      final pill = _pills(tester).single;

      expect(_charLeft(pillLine, 0), moreOrLessEquals(margin, epsilon: 0.5));
      expect(pill.left, greaterThan(_charLeft(pillLine, 3)));
      expect(pill.left, lessThan(_charLeft(pillLine, 4)));
    },
    variant: macOS,
  );

  testWidgets(
    'Given a link at the start of a line when it becomes a button, is undone '
    'and redone then the line is at the margin without the pill and the pill '
    'at the margin with it',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Docs', {'link': 'https://x.dev'})
          ..insert(' and more\nPlain line\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      final commands = WriteEditorCommands(h.controller);
      final line = h.controller.document.getNodeAt(0)!.id;
      final plain = h.controller.document.getNodeAt(1)!.id;
      final margin = _charLeft(plain, 0);
      Future<void> expectButton(bool button) async {
        await tester.pumpAndSettle();
        final pills = _pills(tester);
        if (button) {
          expect(pills.single.left, moreOrLessEquals(margin, epsilon: 0.5));
          expect(_charLeft(line, 0), greaterThan(margin + 5));
        } else {
          expect(pills, isEmpty);
          expect(_charLeft(line, 0), moreOrLessEquals(margin, epsilon: 0.5));
        }
      }

      h.select(1);
      expect(commands.setLinkStyle('button'), isTrue);
      await expectButton(true);

      final change = h.changes.last;
      h.undo(change);
      await expectButton(false);

      h.controller.applyLocal(
        change.delta,
        label: 'Redo',
        source: LocalChangeSource.undo,
      );
      await expectButton(true);
    },
    variant: macOS,
  );
  testWidgets(
    'Given a button and a chip when text in them is selected then the '
    'selection box is centered on the pill, not riding above it',
    (tester) async {
      await pumpEditor(
        tester,
        Delta()
          ..insert('Before ')
          ..insert('Docs link', {
            'link': 'https://x.dev',
            'linkStyle': 'button',
          })
          ..insert(' after and ')
          ..insert('chip text', {'chip': true})
          ..insert(' end\nPlain line\n'),
      );
      final pills = _pills(tester)..sort((a, b) => a.left.compareTo(b.left));
      expect(pills, hasLength(2));

      for (final (pill, from, to) in [(pills[0], 9, 13), (pills[1], 29, 33)]) {
        final selection = _highlightRect(tester, from, to);
        final above = pill.top - selection.top;
        final below = selection.bottom - pill.bottom;
        expect(above, greaterThanOrEqualTo(-0.5), reason: '$from');
        expect((above - below).abs(), lessThan(1.5), reason: '$from');
      }
    },
    variant: macOS,
  );

  testWidgets(
    'Given a button when text in it is selected then the selected part is '
    'lightened (the accent highlight does not show on the accent fill)',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('See ')
          ..insert('Docs link', {
            'link': 'https://x.dev',
            'linkStyle': 'button',
          })
          ..insert(' here\nPlain line\n'),
      );
      const lighten = Color(0x59FFFFFF);
      expect(_pillLayer(), isNot(paints..rect(color: lighten)));

      h.select(6, 10);
      await tester.pumpAndSettle();

      expect(_pillLayer(), paints..rect(color: lighten));
    },
    variant: macOS,
  );
}
