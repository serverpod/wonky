import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wonky_write_core/src/export/office/office_support.dart';

/// 3 × 2 WebPs as the server stores images (suite 12 §1.1).
final _lossy = base64Decode(
  'UklGRiQAAABXRUJQVlA4IBgAAAAwAQCdASoDAAIAAUAmJaQAA3AA/v02aAA=',
);
final _lossless = base64Decode(
  'UklGRhoAAABXRUJQVlA4TA4AAAAvAkAAAAcQEf0PRET/Aw==',
);
final _lossyWithAlpha = base64Decode(
  'UklGRkYAAABXRUJQVlA4WAoAAAAQAAAAAgAAAQAAQUxQSAcAAAAAgICAgICAAFZQOCAYAAAAMAEAnQEqAwACAAFAJiWkAANwAP79NmgA',
);

void main() {
  group('Given WebP images in a DOCX/ODT/RTF/EPUB export', () {
    OfficeImage prepare(List<int> bytes) =>
        prepareOfficeImage(describeExportImage(Uint8List.fromList(bytes))!)!;

    test(
      'when a WebP is lossy and opaque (a photo) then it becomes a JPEG',
      () {
        final o = prepare(_lossy);

        expect(o.mime, 'image/jpeg');
        expect((o.widthPx, o.heightPx), (3, 2));
      },
    );

    test('when a WebP is lossless then it becomes a PNG', () {
      expect(prepare(_lossless).mime, 'image/png');
    });

    test('when a WebP has transparency then it becomes a PNG', () {
      expect(prepare(_lossyWithAlpha).mime, 'image/png');
    });
  });
}
