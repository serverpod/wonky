import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:wonky_slides_core/pdf.dart';

Uint8List _png(int w, int h) {
  final image = img.Image(width: w, height: h, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(200, 40, 40, 255));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  final job = SlidesPdfImageJob(_png(400, 200), const [
    SlidesPdfImageVariant(widthSu: 400, maxPx: 200),
    SlidesPdfImageVariant(
      widthSu: 400,
      maxPx: 1000,
      // Grayscale.
      matrix: [
        0.33, 0.33, 0.33, 0, 0, //
        0.33, 0.33, 0.33, 0, 0, //
        0.33, 0.33, 0.33, 0, 0, //
        0, 0, 0, 1, 0, //
      ],
    ),
    SlidesPdfImageVariant(widthSu: 400, maxPx: 1000, blur: 4),
  ], compact: false);

  test('Given a source with three variants when preparing then each is '
      'downscaled, adjusted and blurred as asked', () {
    final out = SlidesPdfImagePrep.runSync(job);

    expect(out, hasLength(3));
    expect((out[0]!.width, out[0]!.height), (200, 100));
    expect(out[0]!.rgba, hasLength(200 * 100 * 4));
    expect((out[1]!.width, out[1]!.height), (400, 200));
    final gray = out[1]!.rgba!;
    expect(gray[0], gray[1]);
    expect(gray[1], gray[2]);
    expect(out[2]!.width, 400);
  });

  test('Given the time-sliced path when preparing then it yields between '
      'steps and gives the same pixels', () async {
    var turns = 0;
    final out = await SlidesPdfImagePrep.run(
      job,
      yieldNow: () async => turns++,
    );
    final sync = SlidesPdfImagePrep.runSync(job);

    expect(turns, greaterThan(3));
    for (var i = 0; i < 3; i++) {
      expect(out[i]!.rgba, sync[i]!.rgba);
    }
  });

  test('Given bytes that are not an image when preparing then every variant '
      'is null', () {
    final out = SlidesPdfImagePrep.runSync(
      SlidesPdfImageJob(Uint8List.fromList([1, 2, 3]), const [
        SlidesPdfImageVariant(widthSu: 10, maxPx: 64),
        SlidesPdfImageVariant(widthSu: 10, maxPx: 64, blur: 1),
      ], compact: true),
    );

    expect(out, [null, null]);
  });

  test('Given a compact export of an opaque image when preparing then it is '
      'a JPEG', () {
    final out = SlidesPdfImagePrep.runSync(
      SlidesPdfImageJob(
        Uint8List.fromList(img.encodePng(img.Image(width: 64, height: 32))),
        const [SlidesPdfImageVariant(widthSu: 64, maxPx: 64)],
        compact: true,
      ),
    );

    expect(out.single!.jpeg, isNotNull);
  });
}
