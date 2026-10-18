import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/testing.dart';
import 'package:wonky_write/features/outline/outline_panel.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show DeltaSelection;

import '../screen/support/screen_harness.dart';
import '../screen/support/screen_pump.dart';
import '../screen/support/shad_fonts.dart';

const _markdown =
    '# Plan\n\nIntro\n\n## Budget\n\nText\n\n### Costs\n\nMore\n\n# Next\n';

ValueKey<String> _item(int index) => ValueKey<String>('outline.item.$index');

/// Pumps the outline panel of [h]'s document, 280 px wide.
Future<void> _pumpPanel(
  WidgetTester tester,
  ScreenHarness h, {
  Brightness brightness = Brightness.light,
  VoidCallback? onClose,
}) async {
  h.doc.insights.refresh();
  await pumpScreen(
    tester,
    h,
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 280,
        height: 600,
        child: OutlinePanel(
          insights: h.doc.insights,
          view: h.doc.outlineView,
          onClose: onClose,
        ),
      ),
    ),
    brightness: brightness,
  );
}

/// Focuses the heading list (as Tab would) for keyboard tests.
Future<void> _focusList(WidgetTester tester) async {
  tester
      .widget<Focus>(
        find.byWidgetPredicate(
          (w) => w is Focus && w.focusNode?.debugLabel == 'outline',
        ),
      )
      .focusNode!
      .requestFocus();
  await tester.pump();
}

/// The expand/collapse chevron of the row of heading [index].
Finder _chevron(int index, IconData icon) =>
    find.descendant(of: find.byKey(_item(index)), matching: find.byIcon(icon));

List<String> _visible(WidgetTester tester) => [
  for (final i in [0, 1, 2, 3])
    if (find.byKey(_item(i)).evaluate().isNotEmpty) '$i',
];

void main() {
  setUpAll(loadShadFonts);

  for (final brightness in Brightness.values) {
    testWidgets('Given four headings (${brightness.name}) when the outline '
        'shows then every heading is listed with the count', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpPanel(tester, h, brightness: brightness);

      expect(find.text('4 headings'), findsOneWidget);
      expect(_visible(tester), ['0', '1', '2', '3']);
      expect(find.text('Costs'), findsOneWidget);
      expect(_chevron(0, LucideIcons.chevronDown), findsOneWidget);
      expect(_chevron(1, LucideIcons.chevronDown), findsOneWidget);
      expect(_chevron(3, LucideIcons.chevronDown), findsNothing);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await h.dispose(tester);
    });
  }

  group('Given the outline of a document with nested headings', () {
    testWidgets('when collapsing "Plan" then its subheadings hide and '
        'expanding shows them again', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpPanel(tester, h);

      await tester.tap(_chevron(0, LucideIcons.chevronDown));
      await tester.pump();
      expect(_visible(tester), ['0', '3']);
      expect(h.invoked, isNot(contains('write.nav.goToHeading')));

      await tester.tap(_chevron(0, LucideIcons.chevronRight));
      await tester.pump();
      expect(_visible(tester), ['0', '1', '2', '3']);
      await h.dispose(tester);
    });

    testWidgets(
      'when read by assistive tech then the collapse toggle is its own button',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final h = await ScreenHarness.open(tester, markdown: _markdown);
        await _pumpPanel(tester, h);

        expect(
          tester.getSemantics(find.bySemanticsLabel('Collapse “Plan”')),
          matchesSemantics(
            label: 'Collapse “Plan”',
            isButton: true,
            hasExpandedState: true,
            isExpanded: true,
            hasTapAction: true,
          ),
        );
        semantics.dispose();
        await h.dispose(tester);
      },
    );

    testWidgets('when moving down with the arrow keys and pressing Enter '
        'then the caret goes to that heading', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpPanel(tester, h);
      await _focusList(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleCommand(tester);

      expect(h.invoked, contains('write.nav.goToHeading'));
      expect(h.doc.insights.currentHeading, 2);
      await h.dispose(tester);
    });

    testWidgets('when pressing End and Enter then the caret goes to the last '
        'heading', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpPanel(tester, h);
      await _focusList(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleCommand(tester);

      expect(h.doc.insights.currentHeading, 3);
      await h.dispose(tester);
    });

    testWidgets('when pressing Left then Right on "Plan" then its section '
        'collapses and expands', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpPanel(tester, h);
      await _focusList(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(_visible(tester), ['0', '3']);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_visible(tester), ['0', '1', '2', '3']);
      await h.dispose(tester);
    });

    testWidgets('when pressing Escape then the panel asks to close', (
      tester,
    ) async {
      var closed = 0;
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpPanel(tester, h, onClose: () => closed++);
      await _focusList(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      expect(closed, 1);
      await h.dispose(tester);
    });

    testWidgets('when choosing Collapse all and then Expand all in the '
        'options then every section collapses and expands', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpPanel(tester, h);

      await tester.tap(find.byKey(const ValueKey('outline.menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Collapse all'));
      await tester.pumpAndSettle();
      expect(_visible(tester), ['0', '3']);

      await tester.tap(find.byKey(const ValueKey('outline.menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expand all'));
      await tester.pumpAndSettle();
      expect(_visible(tester), ['0', '1', '2', '3']);
      await settleTooltips(tester);
      await h.dispose(tester);
    });

    testWidgets('when showing heading 1 only then subheadings hide through '
        'write.outline.setMaxLevel without an undo step', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpPanel(tester, h);
      final steps = h.session.undo
          .undoStepsOf(h.session.session.undoStackKey)
          .length;

      await tester.tap(find.byKey(const ValueKey('outline.menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show levels'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('outline.levels.1')));
      await settleCommand(tester);
      await tester.pumpAndSettle();

      expect(h.invoked, contains('write.outline.setMaxLevel'));
      expect(h.doc.outlineView.maxLevel, 1);
      expect(_visible(tester), ['0', '3']);
      expect(
        h.session.undo.undoStepsOf(h.session.session.undoStackKey),
        hasLength(steps),
      );
      await settleTooltips(tester);
      await h.dispose(tester);
    });
  });

  group('Given the outline of a document without headings', () {
    testWidgets('when pressing "Turn this line into a heading" then the line '
        'becomes a heading and undo restores the empty state', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: 'Just text\n');
      h.doc.editor.select(const DeltaSelection.collapsed(0));
      await _pumpPanel(tester, h);
      expect(find.byKey(const ValueKey('outline.empty')), findsOneWidget);

      await tester.tap(find.text('Turn this line into a heading'));
      await settleCommand(tester);
      h.doc.insights.refresh();
      await tester.pump();

      expect(h.invoked, contains('write.format.blockType'));
      expect(find.byKey(_item(0)), findsOneWidget);
      expect(find.text('Just text'), findsOneWidget);

      await tester.runAsync(h.session.undo.undo);
      h.doc.insights.refresh();
      await tester.pump();
      expect(find.byKey(const ValueKey('outline.empty')), findsOneWidget);
      await h.dispose(tester);
    });
  });
}
