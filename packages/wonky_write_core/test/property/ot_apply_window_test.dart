import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';

/// `WonkyOt.applyToCanonical` (only the ops around the change) gives what
/// `WonkyOt.apply` (the whole document) gives (CQ-49).
void main() {
  for (final overlays in [false, true]) {
    propertyTest('Given random canonical documents and random changes'
        '${overlays ? ' with overlays' : ''} when applying a change around '
        'its ops then the document equals applying it to the whole document', (
      random,
      _,
    ) {
      final gen = DeltaGen(
        random,
        options: DeltaGenOptions(overlays: overlays),
      );
      final edits = EditGen(random, deltaGen: gen);
      var doc = gen.document();
      for (var step = 0; step < 4; step++) {
        final change = edits.change(doc, overlays: overlays);

        final expected = WonkyOt.apply(doc, change);
        expect(
          WonkyOt.applyToCanonical(doc, change),
          expected,
          reason: 'doc: ${doc.toJson()}\nchange: ${change.toJson()}',
        );
        doc = expected;
      }
    }, runs: 300);
  }

  test('Given a document when a change retains past its end then '
      'applying it throws like apply', () {
    final doc = Delta()..insert('ab\n');

    expect(
      () => WonkyOt.applyToCanonical(
        doc,
        Delta()
          ..retain(5)
          ..insert('x'),
      ),
      throwsA(isA<DeltaApplyException>()),
    );
  });
}
