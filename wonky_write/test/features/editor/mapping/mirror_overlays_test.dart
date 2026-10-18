import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show
        CommentAnchors,
        SuggestionIndex,
        SuggestionKind,
        SuggestionMark,
        WonkyAttr;

import '../support/editor_harness.dart';

Map<String, dynamic> _sug(String id) => {
  WonkyAttr.suggestionKey(id): const SuggestionMark(
    kind: SuggestionKind.ins,
    by: 'u1',
    at: 1000,
  ).toJson(),
};

/// Three paragraphs: a comment over the end of the first and the start of
/// the second, a suggested insertion in the third.
Delta _document() => Delta()
  ..insert('Hello ')
  ..insert('wor', {WonkyAttr.commentKey('t1'): true})
  ..insert('\n', {WonkyAttr.commentKey('t1'): true})
  ..insert('ld', {WonkyAttr.commentKey('t1'): true})
  ..insert(' again\nThird ')
  ..insert('new ', _sug('s1'))
  ..insert('line\n');

void main() {
  group('Given a document with a comment over two blocks and a suggestion', () {
    late EditorHarness h;
    setUp(() => h = EditorHarness(_document()));
    tearDown(() => h.dispose());

    void expectSameAsWholeDocument() {
      final anchors = h.controller.overlays.anchors();
      final whole = CommentAnchors.anchors(h.delta);
      expect(anchors.keys, whole.keys);
      for (final id in whole.keys) {
        expect(anchors[id]!.ranges, whole[id]!.ranges);
        expect(anchors[id]!.quote, whole[id]!.quote);
      }
      expect(
        [for (final s in h.controller.overlays.suggestions()) s.toJson()],
        [for (final s in SuggestionIndex.list(h.delta)) s.toJson()],
      );
    }

    test('when reading the overlays then they equal those of the whole '
        'document', () {
      expect(h.controller.overlays.anchors()['t1']!.quote, 'wor ld');
      expect(h.controller.overlays.suggestions().single.start, 25);
      expectSameAsWholeDocument();
    });

    test('when typing in the first block then the anchors and suggestions '
        'after it move with the text', () {
      h.controller.overlays.anchors();
      h.select(0);

      h.type('Oh, ');

      expect(h.controller.overlays.anchors()['t1']!.start, 10);
      expect(h.controller.overlays.suggestions().single.start, 29);
      expectSameAsWholeDocument();
    });

    test('when typing inside the anchored text then the quote follows', () {
      h.controller.overlays.anchors();
      h.select(7);

      h.type('x');

      expectSameAsWholeDocument();
    });

    test('when deleting the line break between the commented blocks then '
        'the overlays equal those of the whole document', () {
      h.controller.overlays.suggestions();
      h.select(10);

      h.delete();

      expectSameAsWholeDocument();
    });
  });
}
