import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/ai/proofread_service.dart';
import 'package:wonky_server/src/write/ai/write_context_builder.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

WriteDocContext _ctx(String markdown, {int revision = 7}) =>
    WriteContextBuilder.fromContent(
      title: 'Plan "Q4"',
      revision: revision,
      content: const MarkdownCodec().importMarkdown(markdown).delta,
    );

void main() {
  group('Given a small document', () {
    final c = _ctx('# Plan\n\nThe old plan.\n\n## Budget\n\nTen euros.\n');

    test('when snapshotted then outline and full Markdown are included', () {
      final s = WriteContextBuilder.snapshot(c);
      expect(s, contains('<document_outline>'));
      expect(s, contains('"text":"Budget"'));
      expect(s, contains('title="Plan &quot;Q4&quot;" revision="7"'));
      expect(s, contains('Ten euros.'));
    });

    test(
      'when the selection text repeats then the occurrence nearest the '
      'client offset is used',
      () {
        final twice = _ctx('Alpha beta.\n\nAlpha beta.\n');
        final second = twice.doc.text.lastIndexOf('Alpha');
        final sel = WriteContextBuilder.selection(
          twice,
          start: second,
          length: 5,
          text: 'Alpha',
        );
        expect(sel!.occurrence, 2);
        expect(sel.start, second);
      },
    );

    test(
      'when the volatile context is built then suggestions, role and the '
      'style guide are stated',
      () {
        final v = WriteContextBuilder.volatile(
          c: c,
          applyMode: AiApplyMode.suggest,
          role: 'commenter',
          styleGuide: '<style_guide name="Plain">x</style_guide>',
        );
        expect(v, contains('Your edits become tracked suggestions.'));
        expect(v, contains('<style_guide name="Plain">'));
        expect(v, contains('User role: commenter'));
        expect(v, contains('No text is selected.'));
      },
    );

    test('when a section changed then only it is in the update', () {
      final now = _ctx(
        '# Plan\n\nThe old plan.\n\n## Budget\n\nTwelve euros.\n',
        revision: 9,
      );
      final u = WriteContextBuilder.update(
        previousMarkdown: c.markdown,
        previousRevision: 7,
        now: now,
      )!;
      expect(u, contains('revision="9"'));
      expect(u, contains('Twelve euros.'));
      expect(u, isNot(contains('The old plan.')));
    });

    test('when nothing changed then there is no update', () {
      expect(
        WriteContextBuilder.update(
          previousMarkdown: c.markdown,
          previousRevision: 7,
          now: c,
        ),
        isNull,
      );
    });

    test('when asking for the heading path then nested headings join', () {
      final offset = c.doc.text.indexOf('Ten');
      expect(WriteContextBuilder.headingPath(c, offset), 'Plan › Budget');
    });
  });

  group('Given a large document', () {
    final body = StringBuffer('Intro text.\n\n');
    for (var i = 0; i < 40; i++) {
      body.write('# Chapter $i\n\n${'Lorem ipsum dolor sit amet. ' * 600}\n\n');
    }
    final c = _ctx(body.toString());

    test('when snapshotted then only the outline and parts are sent', () {
      expect(c.isLarge, isTrue);
      final focus = c.doc.text.indexOf('Chapter 20');
      final s = WriteContextBuilder.snapshot(c, focusOffset: focus);
      expect(s, contains('<document_excerpt'));
      expect(s, contains('Chapter 20'));
      expect(s.length, lessThan(c.markdown.length ~/ 5));
    });

    test('when proofreading then sections stay under the word limit', () {
      final sections = ProofreadService.split(c);
      expect(sections.length, greaterThan(1));
      for (final s in sections) {
        expect(
          RegExp(r'\S+').allMatches(s.text).length,
          lessThanOrEqualTo(ProofreadService.maxWords + 4000),
        );
      }
    });
  });
}
