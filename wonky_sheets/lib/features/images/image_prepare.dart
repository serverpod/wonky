import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter_svg/flutter_svg.dart';

import 'image_service.dart';

/// An image ready for upload: the bytes to store and the natural size the
/// object spec records.
@immutable
class PreparedImage {
  const PreparedImage(this.image, this.size, {this.frameCount = 1});

  final PickedImage image;

  /// Natural size in logical px (an SVG's own size; a downscaled bitmap's
  /// new size).
  final Size size;

  /// Frames of an animated GIF/WebP (1 for still images).
  final int frameCount;
}

/// Client-side processing of inserted images (08 §10.1): SVGs are
/// rasterized to PNG (at 2× their size for crisp zooming, ≤ 4000 px), and
/// images above 25 megapixels are downscaled to fit (PNG) before the
/// upload. Animated GIFs are kept as they are.
abstract final class SheetsImagePrep {
  /// Longest side of a rasterized SVG.
  static const maxSvgSide = 4000;

  /// Bitmaps above this many pixels are downscaled (25 MP; lowered in
  /// tests).
  static int maxPixels = SheetsImageRules.maxPixels;

  /// Size of SVGs without width/height/viewBox.
  static const defaultSvgSize = Size(300, 150);

  /// Prepares [img]; throws [ImageRejected] when it can't be decoded.
  static Future<PreparedImage> prepare(PickedImage img) async {
    if (img.mimeType == SheetsImageRules.svgMime) return _svg(img);
    final ui.Codec codec;
    try {
      codec = await ui.instantiateImageCodec(img.bytes);
    } catch (_) {
      throw const ImageRejected(ImageRejectReason.unsupportedFormat);
    }
    final frames = codec.frameCount;
    final frame = await codec.getNextFrame();
    codec.dispose();
    final w = frame.image.width;
    final h = frame.image.height;
    final pixels = w * h;
    if (pixels > maxPixels) {
      frame.image.dispose();
      final f = math.sqrt(maxPixels / pixels);
      final tw = math.max(1, (w * f).floor());
      final th = math.max(1, (h * f).floor());
      final png = await _encode(img.bytes, tw, th);
      return PreparedImage(
        PickedImage(name: _png(img.name), bytes: png, mimeType: 'image/png'),
        Size(tw.toDouble(), th.toDouble()),
      );
    }
    frame.image.dispose();
    return PreparedImage(
      img,
      Size(w.toDouble(), h.toDouble()),
      frameCount: frames,
    );
  }

  static Future<PreparedImage> _svg(PickedImage img) async {
    final PictureInfo info;
    try {
      info = await vg.loadPicture(SvgBytesLoader(img.bytes), null);
    } catch (_) {
      throw const ImageRejected(ImageRejectReason.unsupportedFormat);
    }
    var size = info.size;
    if (size.width <= 0 || size.height <= 0) size = defaultSvgSize;
    final scale = math.min(2.0, maxSvgSide / math.max(size.width, size.height));
    final w = math.max(1, (size.width * scale).round());
    final h = math.max(1, (size.height * scale).round());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(
      w / info.size.width.clamp(1, double.infinity),
      h / info.size.height.clamp(1, double.infinity),
    );
    canvas.drawPicture(info.picture);
    info.picture.dispose();
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    picture.dispose();
    final png = await _pngOf(image);
    image.dispose();
    return PreparedImage(
      PickedImage(name: _png(img.name), bytes: png, mimeType: 'image/png'),
      size,
    );
  }

  static Future<Uint8List> _encode(Uint8List bytes, int w, int h) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: w,
      targetHeight: h,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    final png = await _pngOf(frame.image);
    frame.image.dispose();
    return png;
  }

  static Future<Uint8List> _pngOf(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw const ImageRejected(ImageRejectReason.unsupportedFormat);
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static String _png(String name) {
    final dot = name.lastIndexOf('.');
    return '${dot > 0 ? name.substring(0, dot) : name}.png';
  }
}
