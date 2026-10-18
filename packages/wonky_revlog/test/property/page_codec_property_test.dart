@Tags(['property'])
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wonky_revlog/codec.dart';

import '../support/page_rows.dart';

void main() {
  for (var seed = 0; seed < 30; seed++) {
    test('Given random rows (seed $seed) when encoded as a page and decoded '
        'then they round-trip', () {
      final r = Random(seed);
      final rows = randomItems(
        r,
        r.nextInt(4) == 0 ? r.nextInt(3) : r.nextInt(700),
        nullRate: r.nextDouble(),
        repeatRate: r.nextDouble(),
      );
      final body = RevPageCodec.encode(
        pageSchema,
        rows,
        compress: r.nextBool(),
      );

      final back = RevPageCodec.decode(pageSchema, body);

      expect(flat(back), flat(decodedForm(pageSchema, rows)));
    });
  }

  for (var seed = 0; seed < 30; seed++) {
    test('Given a damaged page (seed $seed) when decoded then it fails with '
        'a codec error or decodes rows', () {
      final r = Random(1000 + seed);
      final body = Uint8List.fromList(
        RevPageCodec.encode(pageSchema, randomItems(r, 50 + r.nextInt(200))),
      );
      final damaged = r.nextBool()
          ? Uint8List.sublistView(body, 0, r.nextInt(body.length))
          : (body..[4 + r.nextInt(body.length - 4)] ^= 1 + r.nextInt(255));

      expect(
        () => RevPageCodec.decode(pageSchema, damaged),
        anyOf(returnsNormally, throwsA(isA<RevCodecException>())),
      );
    });
  }
}
