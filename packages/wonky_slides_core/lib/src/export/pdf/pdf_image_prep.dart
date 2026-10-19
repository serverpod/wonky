import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// One way a PDF draws a source image (10 §11.3): its color matrix, blur,
/// the largest width it is drawn at (su) and the pixel width it is
/// downscaled to.
final class SlidesPdfImageVariant {
  /// Creates a variant.
  const SlidesPdfImageVariant({
    this.matrix,
    this.blur = 0,
    required this.widthSu,
    required this.maxPx,
  });

  /// 4×5 row-major color matrix, or null.
  final List<double>? matrix;

  /// Blur sigma (su), 0 = none.
  final double blur;

  /// Largest drawn width (su).
  final double widthSu;

  /// Maximum pixel width.
  final int maxPx;
}

/// The image work of one source for a PDF export: decode once, then
/// downscale, color-adjust, blur and encode each variant (CQ-44). Sendable
/// to an isolate.
final class SlidesPdfImageJob {
  /// Creates a job.
  const SlidesPdfImageJob(this.bytes, this.variants, {required this.compact});

  /// The encoded source image.
  final Uint8List bytes;

  /// The variants to prepare, in order.
  final List<SlidesPdfImageVariant> variants;

  /// Compact PDFs store opaque images as JPEG (quality 80).
  final bool compact;
}

/// A prepared variant: JPEG bytes, or RGBA pixels with an alpha channel
/// (what `PdfImage.fromImage` stores), or null when the source is not a
/// decodable image.
final class SlidesPdfPreparedImage {
  /// A JPEG.
  const SlidesPdfPreparedImage.jpeg(
    Uint8List this.jpeg,
    this.width,
    this.height,
  ) : rgba = null;

  /// RGBA pixels.
  const SlidesPdfPreparedImage.rgba(
    Uint8List this.rgba,
    this.width,
    this.height,
  ) : jpeg = null;

  /// JPEG bytes, or null.
  final Uint8List? jpeg;

  /// RGBA pixels (4 bytes each), or null.
  final Uint8List? rgba;

  /// Pixel size.
  final int width, height;
}

/// Runs [job]'s image work somewhere (an isolate on native platforms) and
/// returns one result per variant (null = not decodable). It throws when
/// the export was cancelled while it ran.
typedef SlidesPdfImageRunner =
    Future<List<SlidesPdfPreparedImage?>> Function(SlidesPdfImageJob job);

/// The image work of PDF exports, in pure Dart.
abstract final class SlidesPdfImagePrep {
  /// Prepares every variant of [job] synchronously (in an isolate).
  static List<SlidesPdfPreparedImage?> runSync(SlidesPdfImageJob job) {
    final out = <SlidesPdfPreparedImage?>[];
    final steps = _steps(job, out);
    while (steps.moveNext()) {}
    return out;
  }

  /// Prepares every variant of [job] on this isolate, awaiting [yieldNow]
  /// between steps (decode, resize, color matrix rows, blur, encode) so a
  /// web export keeps the page responsive and can be cancelled.
  static Future<List<SlidesPdfPreparedImage?>> run(
    SlidesPdfImageJob job, {
    required Future<void> Function() yieldNow,
  }) async {
    final out = <SlidesPdfPreparedImage?>[];
    final steps = _steps(job, out);
    while (steps.moveNext()) {
      await yieldNow();
    }
    return out;
  }

  /// The work of [job] as steps; results are added to [out].
  static Iterator<void> _steps(
    SlidesPdfImageJob job,
    List<SlidesPdfPreparedImage?> out,
  ) => _work(job, out).iterator;

  static Iterable<void> _work(
    SlidesPdfImageJob job,
    List<SlidesPdfPreparedImage?> out,
  ) sync* {
    img.Image? source;
    try {
      source = img.decodeImage(job.bytes);
    } on Object {
      source = null;
    }
    yield null;
    if (source == null) {
      out.addAll(List.filled(job.variants.length, null));
      return;
    }
    for (final v in job.variants) {
      var image = source;
      if (image.width > v.maxPx) {
        image = img.copyResize(
          image,
          width: v.maxPx,
          interpolation: img.Interpolation.average,
        );
        yield null;
      }
      final m = v.matrix;
      if (m != null) {
        final adjusted = image.convert(numChannels: 4);
        // Row bands, so the time-sliced path yields inside large images.
        const band = 64;
        for (var y = 0; y < adjusted.height; y += band) {
          _applyMatrix(adjusted, m, y, math.min(adjusted.height, y + band));
          yield null;
        }
        image = adjusted;
      }
      if (v.blur > 0) {
        final radius = (v.blur * image.width / math.max(1, v.widthSu)).round();
        if (radius > 0) {
          image = img.gaussianBlur(image, radius: radius);
          yield null;
        }
      }
      if (job.compact && !image.hasAlpha) {
        out.add(
          SlidesPdfPreparedImage.jpeg(
            Uint8List.fromList(img.encodeJpg(image, quality: 80)),
            image.width,
            image.height,
          ),
        );
      } else {
        out.add(
          SlidesPdfPreparedImage.rgba(
            image
                .convert(
                  format: img.Format.uint8,
                  numChannels: 4,
                  noAnimation: true,
                )
                .toUint8List(),
            image.width,
            image.height,
          ),
        );
      }
      yield null;
    }
  }

  /// Applies a 4×5 row-major color matrix (Flutter `ColorFilter.matrix`
  /// semantics: offsets in 0–255) to rows [from]..[to] of [image] in place.
  static void _applyMatrix(img.Image image, List<double> m, int from, int to) {
    final range = image.getRange(0, from, image.width, to - from);
    while (range.moveNext()) {
      final p = range.current;
      final r = p.r.toDouble(), g = p.g.toDouble();
      final b = p.b.toDouble(), a = p.a.toDouble();
      double row(int i) =>
          m[i * 5] * r +
          m[i * 5 + 1] * g +
          m[i * 5 + 2] * b +
          m[i * 5 + 3] * a +
          m[i * 5 + 4];
      p
        ..r = row(0).clamp(0, 255)
        ..g = row(1).clamp(0, 255)
        ..b = row(2).clamp(0, 255)
        ..a = row(3).clamp(0, 255);
    }
  }
}
