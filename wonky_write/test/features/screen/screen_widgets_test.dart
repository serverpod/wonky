import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write/features/find_replace/find_panel.dart';
import 'package:wonky_write/features/outline/outline_panel.dart';
import 'package:wonky_write/features/screen/write_toolbar.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'support/screen_harness.dart';

void main() {
  group('Given the find panel on "a colour, a colour"', () {
    testWidgets('when typing a query then matches are counted and '
        'Replace all replaces every match through the command', (tester) async {
      final h = await ScreenHarness.open(
        tester,
        markdown: 'A colour, a colour\n',
      );
      h.doc.find.open();
      await h.pump(
        tester,
        SizedBox(
          width: 340,
          height: 600,
          child: FindPanel(controller: h.doc.find, editable: true),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('find.query')),
        'colour',
      );
      await tester.pump();
      expect(find.text('1 of 2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('find.toggleReplace')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('find.replacement')),
        'color',
      );
      await tester.tap(find.byKey(const ValueKey('find.replaceAll')));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      expect(h.invoked, contains('write.find.replaceAll'));
      expect(DeltaUtils.text(h.doc.editor.delta), 'A color, a color\n');
      await h.dispose(tester);
    });

    testWidgets('when the query has no match then "No results" is shown', (
      tester,
    ) async {
      final h = await ScreenHarness.open(tester, markdown: 'Hello\n');
      h.doc.find.open();
      await h.pump(
        tester,
        SizedBox(
          width: 340,
          height: 600,
          child: FindPanel(controller: h.doc.find, editable: true),
        ),
      );

      await tester.enterText(find.byKey(const ValueKey('find.query')), 'xyz');
      await tester.pump();

      expect(find.byKey(const ValueKey('find.noResults')), findsOneWidget);
      await h.dispose(tester);
    });
  });

  group('Given the outline panel of a document with two headings', () {
    testWidgets('when clicking a heading then the caret moves to it', (
      tester,
    ) async {
      final h = await ScreenHarness.open(
        tester,
        markdown: '# One\n\nText\n\n## Two\n\nMore\n',
      );
      h.doc.insights.refresh();
      await h.pump(
        tester,
        SizedBox(
          width: 280,
          height: 600,
          child: OutlinePanel(
            insights: h.doc.insights,
            view: h.doc.outlineView,
          ),
        ),
      );

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);

      await tester.tap(find.text('Two'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      expect(h.invoked, contains('write.nav.goToHeading'));
      expect(h.doc.insights.currentHeading, 1);
      await h.dispose(tester);
    });

    testWidgets(
      'when the document has no headings then the empty state shows',
      (tester) async {
        final h = await ScreenHarness.open(tester, markdown: 'Just text\n');
        await h.pump(
          tester,
          SizedBox(
            width: 280,
            height: 600,
            child: OutlinePanel(
              insights: h.doc.insights,
              view: h.doc.outlineView,
            ),
          ),
        );

        expect(find.byKey(const ValueKey('outline.empty')), findsOneWidget);
        await h.dispose(tester);
      },
    );
  });

  group('Given the formatting toolbar', () {
    testWidgets('when the caret is in a word and Bold is pressed then the '
        'bold command runs and the toggle shows checked', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: 'Hello world\n');
      h.doc.editor.select(const DeltaSelection(0, 5));
      await h.pump(
        tester,
        SizedBox(
          width: 1400,
          height: 48,
          child: WriteToolbar(services: h.services, doc: h.doc),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('write.toolbar.format.bold')));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(h.invoked, contains('write.format.bold'));
      expect(h.doc.editor.delta.first.attributes, {'bold': true});
      await h.dispose(tester);
    });

    testWidgets('when in Viewing mode then formatting controls are hidden', (
      tester,
    ) async {
      final h = await ScreenHarness.open(tester, markdown: 'Hello\n');
      h.doc.session.setMode(EditorMode.viewing);
      await h.pump(
        tester,
        SizedBox(
          width: 1400,
          height: 48,
          child: WriteToolbar(services: h.services, doc: h.doc),
        ),
      );

      expect(
        find.byKey(const ValueKey('write.toolbar.format.bold')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('write.toolbar.modeSwitcher')),
        findsOneWidget,
      );
      await h.dispose(tester);
    });
  });
}
