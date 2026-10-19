import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:wonky_server/src/slides/ai/slides_ai_service.dart';

/// A small JPEG whose SOF0 header declares [width] × [height] (the scan
/// data stays 8 × 8: only the header is read for the limit).
Uint8List _jpegDeclaring(int width, int height) {
  final bytes = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 8, height: 8)),
  );
  for (var i = 0; i + 8 < bytes.length; i++) {
    if (bytes[i] == 0xFF && bytes[i + 1] == 0xC0) {
      // FFC0, length (2), precision (1), height (2), width (2).
      bytes[i + 5] = height >> 8;
      bytes[i + 6] = height & 0xFF;
      bytes[i + 7] = width >> 8;
      bytes[i + 8] = width & 0xFF;
      return bytes;
    }
  }
  throw StateError('No SOF0 marker');
}

void main() {
  group('Given images sent to the Slides AI', () {
    test('when an image is small then it is re-encoded as a JPEG', () {
      final jpeg = SlidesAiService.aiJpeg(_jpegDeclaring(8, 8));

      expect(jpeg, isNotNull);
      expect(img.decodeJpg(jpeg!)?.width, 8);
    });

    test('when the header declares more than the pixel limit then it is '
        'refused without decoding', () {
      final huge = _jpegDeclaring(10000, 10000);

      expect(SlidesAiService.imageWithinLimit(huge), isFalse);
      expect(SlidesAiService.aiJpeg(huge), isNull);
    });

    test('when the bytes are not an image then it is refused', () {
      expect(
        SlidesAiService.imageWithinLimit(Uint8List.fromList([1, 2, 3, 4])),
        isFalse,
      );
    });
  });
}
