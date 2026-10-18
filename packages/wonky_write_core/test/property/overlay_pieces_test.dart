import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';

/// The document split into its lines, each with its start offset.
List<(int, Delta)> _lines(Delta document) {
  final out = <(int, Delta)>[];
  var offset = 0;
  for (final line in WonkyDocument(document).lines) {
    out.add((offset, document.slice(line.start, line.end)));
    offset = line.end;
  }
  return out;
}

void main() {
  const options = DeltaGenOptions(overlays: true);

  propertyTest(
    'Given random documents with overlays when collecting comment pieces per '
    'line then the anchors equal those of the whole document',
    (random, _) {
      final doc = DeltaGen(random, options: options).document();

      final pieces = [
        for (final (offset, line) in _lines(doc))
          for (final p in CommentAnchors.pieces(line))
            (
              threadUuid: p.threadUuid,
              start: p.start + offset,
              length: p.length,
              text: p.text,
            ),
      ];
      final split = CommentAnchors.fromPieces(pieces);
      final whole = CommentAnchors.anchors(doc);

      expect(split.keys, whole.keys);
      for (final id in whole.keys) {
        expect(split[id]!.ranges, whole[id]!.ranges, reason: id);
        expect(split[id]!.quote, whole[id]!.quote, reason: id);
      }
    },
    runs: 200,
  );

  propertyTest(
    'Given random documents with overlays when collecting suggestion pieces '
    'per line then the suggestions equal those of the whole document',
    (random, _) {
      final doc = DeltaGen(random, options: options).document();

      final pieces = [
        for (final (offset, line) in _lines(doc))
          for (final p in SuggestionIndex.pieces(line))
            (id: p.id, mark: p.mark, part: p.part.shifted(offset)),
      ];
      final split = SuggestionIndex.fromPieces(pieces);
      final whole = SuggestionIndex.list(doc);

      expect(
        [for (final s in split) s.toJson()],
        [for (final s in whole) s.toJson()],
      );
    },
    runs: 200,
  );
}
