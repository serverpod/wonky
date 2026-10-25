import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:wonky_write_core/src/import/import_support.dart';

void main() {
  group('Given images embedded in an imported file', () {
    test('when an image is PNG, JPEG, GIF or WebP then it is kept', () {
      final png = img.encodePng(img.Image(width: 2, height: 2));

      final (bytes, mime) = embeddableImage(png, 'image/png')!;

      expect(mime, 'image/png');
      expect(bytes, same(png));
    });

    test('when an image is a BMP then it becomes a PNG', () {
      final bmp = img.encodeBmp(img.Image(width: 3, height: 2));

      final (bytes, mime) = embeddableImage(bmp, ImageMime.sniff(bmp)!)!;

      expect(mime, 'image/png');
      final png = img.decodePng(bytes)!;
      expect((png.width, png.height), (3, 2));
    });

    test('when a BMP is unreadable then it is dropped', () {
      final broken = Uint8List.fromList(ascii.encode('BM not a bitmap'));

      expect(embeddableImage(broken, 'image/bmp'), isNull);
    });
  });
}
