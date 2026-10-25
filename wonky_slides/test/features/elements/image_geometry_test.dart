import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/elements/image/image_geometry.dart';
import 'package:wonky_slides/features/elements/image/image_rules.dart';
import 'package:wonky_slides_core/themes.dart' show SuRect;

void main() {
  group('Given image placement (03 §6.5.1)', () {
    test(
      'when a small image is placed then it keeps 1 px = 1 su, centered',
      () {
        final r = ImageGeometry.place(400, 300, slideW: 1920, slideH: 1080);
        expect((r.x, r.y, r.width, r.height), (760.0, 390.0, 400.0, 300.0));
      },
    );

    test('when a large image is placed then it fits 80 % of the slide', () {
      final r = ImageGeometry.place(4000, 3000, slideW: 1920, slideH: 1080);
      expect(r.height, closeTo(864, 0.01));
      expect(r.width, closeTo(1152, 0.01));
    });

    test('when it is dropped near an edge then it stays on the slide', () {
      final r = ImageGeometry.place(
        400,
        300,
        slideW: 1920,
        slideH: 1080,
        at: (x: 10, y: 1070),
      );
      expect((r.x, r.y), (0.0, 780.0));
    });
  });

  group('Given cover crops (03 §6.5.2)', () {
    test('when a wide image covers a square frame then the sides are cut', () {
      final c = ImageGeometry.cover(400, 200, 100, 100);
      expect(c, const ImageCrop(l: .25, r: .25));
    });

    test(
      'when a tall image covers a wide frame then top and bottom are cut',
      () {
        final c = ImageGeometry.cover(100, 400, 200, 100);
        expect(c.t, closeTo(0.4375, 1e-9));
        expect(c.b, closeTo(0.4375, 1e-9));
      },
    );

    test('when the aspect matches then nothing is cut', () {
      expect(ImageGeometry.cover(400, 200, 200, 100).isNone, isTrue);
    });

    test('when resetting then the height follows the natural aspect', () {
      expect(ImageGeometry.heightFor(400, 200, 300), 150);
      expect(
        ImageGeometry.heightFor(400, 200, 300, crop: const ImageCrop(l: .5)),
        300,
      );
    });
  });

  group('Given crop mode state (03 §6.5.4)', () {
    test('when built from a crop then the stored crop round-trips', () {
      const crop = ImageCrop(l: .1, t: .2, r: .05, b: .15);
      final s = CropState.of(crop, 300, 200);
      expect(s.box, const SuRect(0, 0, 300, 200));
      expect(s.crop, crop);
    });

    test(
      'when a corner handle drags out then the box stays inside the image',
      () {
        final s = CropState.of(const ImageCrop(l: .2, r: .2), 300, 200);
        final n = s.resizeBox(-1000, 0, 0, 0);
        expect(n.box.x, s.image.x);
        expect(n.crop.l, closeTo(0, 1e-9));
        expect(n.crop.r, closeTo(.2, 1e-9));
      },
    );

    test('when an aspect is locked then the box keeps it', () {
      final s = CropState.of(ImageCrop.none, 400, 200);
      final n = s.withAspect(1);
      expect(n.box.width, closeTo(n.box.height, 1e-9));
      expect(n.box.height, 200);
      final r = n.resizeBox(0, 0, -50, 0, aspect: 1);
      expect(r.box.width, closeTo(r.box.height, 1e-9));
    });

    test('when the image is dragged then it keeps covering the box', () {
      final s = CropState.of(const ImageCrop(l: .25, r: .25), 100, 100);
      final n = s.moveImage(1000, 0);
      expect(n.image.x, n.box.x);
      expect(n.crop.l, closeTo(0, 1e-9));
      expect(n.crop.r, closeTo(.5, 1e-9));
    });

    test('when Fit then Fill are chosen then the whole image shows, then '
        'covers the box', () {
      final s = CropState.of(const ImageCrop(l: .25, r: .25), 100, 100);
      final fit = s.fit();
      expect(fit.crop.isNone, isTrue);
      expect(fit.box.width / fit.box.height, closeTo(2, 1e-9));
      final fill = s.fill();
      expect(fill.image.height, closeTo(100, 1e-9));
      expect(fill.crop.l, closeTo(.25, 1e-9));
    });
  });

  group('Given image files', () {
    test('when sniffing then formats are recognized by their bytes', () {
      List<int> b(String s) => s.codeUnits;
      expect(
        SlidesImageRules.sniff(
          Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0, 0, 0, 0]),
        ),
        'image/png',
      );
      expect(
        SlidesImageRules.sniff(Uint8List.fromList(b('GIF89a'))),
        'image/gif',
      );
      expect(
        SlidesImageRules.sniff(Uint8List.fromList(b('<svg xmlns="x"/>'))),
        SlidesImageRules.svgMime,
      );
      expect(
        () => SlidesImageRules.validate('x.heic', Uint8List.fromList(b('x'))),
        throwsA(isA<ImageRejected>()),
      );
    });

    test('when a BMP is picked then it is refused', () {
      final bmp = Uint8List.fromList([0x42, 0x4D, 0, 0, 0, 0, 0, 0, 0, 0]);

      expect(SlidesImageRules.sniff(bmp), isNull);
      expect(
        () => SlidesImageRules.validate('scan.bmp', bmp),
        throwsA(isA<ImageRejected>()),
      );
      expect(SlidesImageRules.extensions, isNot(contains('bmp')));
    });
  });
}
