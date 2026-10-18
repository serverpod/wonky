import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/controller/write_editor_controller.dart';
import 'package:wonky_write/features/outline/outline_panel.dart';
import 'package:wonky_write/features/screen/document_insights.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

Delta sample() => const MarkdownCodec()
    .importMarkdown(
      '# Plan\n\nOne two three.\n\n## Budget\n\nFour five.\n\n# Next\n',
    )
    .delta;

void main() {
  group('Given a document with three headings', () {
    late WriteEditorController editor;
    late DocumentInsights insights;

    setUp(() {
      editor = WriteEditorController(initialDelta: sample());
      insights = DocumentInsights(editor, debounce: Duration.zero);
    });

    tearDown(() {
      insights.dispose();
      editor.dispose();
    });

    test('when computing the outline then it lists the headings in order', () {
      expect(insights.outline.map((e) => (e.level, e.text)), [
        (1, 'Plan'),
        (2, 'Budget'),
        (1, 'Next'),
      ]);
    });

    test('when counting then words include headings and body text', () {
      expect(insights.stats.words, 8);
    });

    test('when the caret is in the Budget section then it is current', () {
      final budget = insights.outline[1];

      editor.select(DeltaSelection.collapsed(budget.deltaOffset + 3));

      expect(insights.currentHeading, 1);
    });

    test('when selecting text then the selection is counted separately', () {
      final text = DeltaUtils.text(editor.delta);
      final start = text.indexOf('One');

      editor.select(DeltaSelection(start, start + 'One two'.length));

      expect(insights.selectionStats?.words, 2);
    });

    test(
      'when outline levels are limited to 1 then subheadings are hidden',
      () {
        final view = OutlineViewState()..maxLevel = 1;

        final rows = visibleOutlineRows(insights.outline, view);

        expect(rows.map((r) => r.entry.text), ['Plan', 'Next']);
      },
    );

    test('when a section is collapsed then its subheadings are hidden', () {
      final view = OutlineViewState()..toggle(insights.outline.first);

      final rows = visibleOutlineRows(insights.outline, view);

      expect(rows.map((r) => (r.entry.text, r.depth)), [
        ('Plan', 0),
        ('Next', 0),
      ]);
    });
  });
}
