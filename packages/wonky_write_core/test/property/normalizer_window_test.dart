import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';

/// `normalizedChange` (the touched lines only) gives the change that
/// `normalizeChange` (the whole document) gives (CQ-49).
void main() {
  const normalizer = WonkyDeltaNormalizer();

  for (final overlays in [false, true]) {
    propertyTest('Given random normalized documents and random changes'
        '${overlays ? ' with overlays' : ''} when normalizing the change on '
        'its lines then it equals normalizing it on the whole document', (
      random,
      _,
    ) {
      final gen = DeltaGen(
        random,
        options: DeltaGenOptions(overlays: overlays),
      );
      final edits = EditGen(random, deltaGen: gen);
      final doc = gen.document();
      final change = edits.change(doc, overlays: overlays);

      expect(
        normalizer.normalizedChange(doc, change),
        normalizer.normalizeChange(doc, change).change,
        reason: 'doc: ${doc.toJson()}\nchange: ${change.toJson()}',
      );
    }, runs: 300);
  }

  group('Given a list whose second item is indented', () {
    final doc = Delta()
      ..insert('one')
      ..insert('\n', {'list': 'bullet'})
      ..insert('two')
      ..insert('\n', {'list': 'bullet', 'indent': 1})
      ..insert('three\n');

    test('when typing in the indented item then its indent is kept', () {
      final change = Delta()
        ..retain(5)
        ..insert('x');

      expect(normalizer.normalizedChange(doc, change), change);
    });

    test('when turning the last line into an item indented twice then the '
        'indent is clamped as on the whole document', () {
      final change = Delta()
        ..retain(13)
        ..retain(1, {'list': 'bullet', 'indent': 3});

      expect(
        normalizer.normalizedChange(doc, change),
        normalizer.normalizeChange(doc, change).change,
      );
    });
  });
}
