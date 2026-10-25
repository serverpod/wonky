import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter_svg/flutter_svg.dart';

/// Picked, pasted, dropped or fetched image bytes.
@immutable
class PickedImage {
  const PickedImage({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String mimeType;
}

/// Why an image file was rejected.
enum ImageRejectReason { unsupportedFormat, tooLarge }

class ImageRejected implements Exception {
  const ImageRejected(this.reason);
  final ImageRejectReason reason;

  @override
  String toString() => 'ImageRejected(${reason.name})';
}

/// Image formats and limits of Slides images (03 §6.5.1).
abstract final class SlidesImageRules {
  /// 50 MB (the per-file upload cap of the suite).
  static const maxBytes = 50 * 1024 * 1024;

  /// Bitmaps above 40 megapixels are downscaled to 40 MP.
  static const maxPixels = 40 * 1000 * 1000;

  static const extensions = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'];

  static const svgMime = 'image/svg+xml';

  /// The MIME type of [bytes] (sniffed, else by [name]'s extension); throws
  /// [ImageRejected].
  static String validate(String name, Uint8List bytes) {
    final ext = name.contains('.')
        ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
        : '';
    final mime = sniff(bytes) ?? byExtension(ext);
    if (mime == null) {
      throw const ImageRejected(ImageRejectReason.unsupportedFormat);
    }
    if (bytes.length > maxBytes) {
      throw const ImageRejected(ImageRejectReason.tooLarge);
    }
    return mime;
  }

  static String? byExtension(String ext) => switch (ext) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'gif' => 'image/gif',
    'webp' => 'image/webp',
    'svg' => svgMime,
    _ => null,
  };

  static bool _startsWith(Uint8List b, String s) {
    if (b.length < s.length) return false;
    for (var i = 0; i < s.length; i++) {
      if (b[i] != s.codeUnitAt(i)) return false;
    }
    return true;
  }

  /// Sniffs PNG, JPEG, GIF, WebP and SVG (BMP isn't supported).
  static String? sniff(Uint8List b) {
    if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e) {
      return 'image/png';
    }
    if (b.length >= 3 && b[0] == 0xff && b[1] == 0xd8 && b[2] == 0xff) {
      return 'image/jpeg';
    }
    if (_startsWith(b, 'GIF8')) return 'image/gif';
    if (b.length >= 12 &&
        _startsWith(b, 'RIFF') &&
        String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
      return 'image/webp';
    }
    final n = b.length < 2048 ? b.length : 2048;
    final head = String.fromCharCodes(b.sublist(0, n)).trimLeft();
    final start = head.startsWith('﻿') ? head.substring(1) : head;
    if (start.startsWith('<') && start.contains('<svg')) return svgMime;
    return null;
  }
}

/// An image ready for upload: the bytes to store and the natural size the
/// element records (`naturalWidth`/`naturalHeight`, 02 §6.4).
@immutable
class PreparedImage {
  const PreparedImage(this.image, this.width, this.height);

  final PickedImage image;

  /// Natural size in pixels (a downscaled bitmap's new size; an SVG's own
  /// size, rasterized at 2×).
  final int width;
  final int height;

  Size get size => Size(width.toDouble(), height.toDouble());
}

/// Client-side processing of inserted images (03 §6.5.1): SVGs are
/// rasterized at 2× their intrinsic size (≤ 4,096 px) to PNG, bitmaps above
/// 40 MP are downscaled to 40 MP (PNG). Animated GIFs
/// are kept as they are (the stage draws their first frame).
abstract final class SlidesImagePrep {
  /// Longest side of a rasterized SVG.
  static const maxSvgSide = 4096;

  /// Bitmaps above this many pixels are downscaled (lowered in tests).
  static int maxPixels = SlidesImageRules.maxPixels;

  /// Size of SVGs without width/height/viewBox.
  static const defaultSvgSize = Size(300, 150);

  /// Prepares [img]; throws [ImageRejected] when it can't be decoded.
  static Future<PreparedImage> prepare(PickedImage img) async {
    if (img.mimeType == SlidesImageRules.svgMime) return _svg(img);
    final ui.Codec codec;
    try {
      codec = await ui.instantiateImageCodec(img.bytes);
    } catch (_) {
      throw const ImageRejected(ImageRejectReason.unsupportedFormat);
    }
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
        tw,
        th,
      );
    }
    frame.image.dispose();
    return PreparedImage(img, w, h);
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
      w,
      h,
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

/// Platform file I/O of images, replaceable in tests.
abstract final class SlidesImageIo {
  /// Picks one or more images (empty when cancelled). Unsupported files
  /// are returned with their bytes; validation happens on insert.
  static Future<List<PickedImage>> Function({
    required String title,
    bool multiple,
  })
  pick = _pick;

  /// Saves [bytes] as [fileName] (web: a download in the same tab).
  static Future<bool> Function(
    String fileName,
    Uint8List bytes,
    String mimeType,
    String title,
  )
  save = _save;

  static Future<List<PickedImage>> _pick({
    required String title,
    bool multiple = false,
  }) async {
    final files = multiple
        ? await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: SlidesImageRules.extensions,
            dialogTitle: title,
          )
        : [
            ?await FilePicker.pickFile(
              type: FileType.custom,
              allowedExtensions: SlidesImageRules.extensions,
              dialogTitle: title,
            ),
          ];
    return [
      for (final f in files)
        PickedImage(name: f.name, bytes: await f.readAsBytes(), mimeType: ''),
    ];
  }

  static Future<bool> _save(
    String fileName,
    Uint8List bytes,
    String mimeType,
    String title,
  ) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      dialogTitle: title,
    );
    return kIsWeb || uri != null;
  }
}
