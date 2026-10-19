@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/print/pdf_image_isolate.dart';
import 'package:wonky_slides_core/pdf.dart';

Future<Uint8List> _png(int w, int h) async {
  final image = await createTestImage(width: w, height: h, cache: false);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// The native image runner of client PDF exports (CQ-44): plain tests with
/// real async, since another isolate can't be awaited under fake async.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Given an image job when it runs in an isolate then it returns the '
      'same results as on this isolate', () async {
    final job = SlidesPdfImageJob(await _png(300, 150), const [
      SlidesPdfImageVariant(widthSu: 300, maxPx: 100),
      SlidesPdfImageVariant(widthSu: 300, maxPx: 1000, blur: 2),
    ], compact: false);

    final out = await isolateImageRunner(null)!(job);
    final here = SlidesPdfImagePrep.runSync(job);

    expect(out.map((p) => (p!.width, p.height)), [(100, 50), (300, 150)]);
    expect(out[1]!.rgba, here[1]!.rgba);
  });

  test('Given a running image job when the export is cancelled then it ends '
      'with a cancellation', () async {
    var cancelled = false;
    final big = SlidesPdfImageJob(await _png(2000, 2000), const [
      SlidesPdfImageVariant(widthSu: 2000, maxPx: 2000, blur: 30),
    ], compact: false);
    final run = isolateImageRunner(() => cancelled)!(big);
    cancelled = true;

    await expectLater(run, throwsA(isA<SlidesPdfCancelledException>()));
  });
}
