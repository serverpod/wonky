import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';

/// `import(export(D)) == normalize(D)` (02 §2.2), embed, table and grid ids
/// replayed, tables compared in their canonical form (Write 12 §5.1).
void checkRoundTrip(Delta d) {
  const codec = MarkdownCodec();
  final normalized = const WonkyDeltaNormalizer().normalize(d).document;
  final ids = CellCanon.blockIds(normalized);
  var next = 0;

  final markdown = codec.exportMarkdown(normalized);
  final back = codec.importMarkdown(
    markdown,
    options: ImportOptions(
      idGenerator: () => next < ids.length ? ids[next++] : 'extra-${next++}',
    ),
  );

  expect(
    CellCanon.canonical(back.delta).toJson(),
    equals(CellCanon.canonical(normalized).toJson()),
    reason: 'Markdown:\n$markdown',
  );
}

void main() {
  propertyTest(
    'Given random documents when exporting and importing Markdown then the delta round-trips',
    (random, _) {
      checkRoundTrip(DeltaGen(random).document());
    },
    runs: 400,
  );
}
