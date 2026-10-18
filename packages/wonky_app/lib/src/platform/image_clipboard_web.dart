import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'image_clipboard.dart';

ImageClipboard createImageClipboard({String? macOsChannel}) =>
    const _WebImageClipboard();

/// The async Clipboard API.
class _WebImageClipboard extends ImageClipboard {
  const _WebImageClipboard();

  @override
  bool get supported => true;

  @override
  Future<ClipboardImage?> readImage() async {
    try {
      final items = (await web.window.navigator.clipboard.read().toDart).toDart;
      String? imageType;
      web.ClipboardItem? imageItem;
      var hasText = false;
      for (final item in items) {
        final types = item.types.toDart.map((t) => t.toDart).toList();
        if (imageItem == null) {
          for (final t in types) {
            if (t.startsWith('image/')) {
              imageType = t;
              imageItem = item;
              break;
            }
          }
        }
        if (!hasText && types.contains('text/plain')) {
          final blob = await item.getType('text/plain').toDart;
          final text = (await blob.text().toDart).toDart;
          hasText = text.trim().isNotEmpty;
        }
      }
      if (imageItem == null || imageType == null) return null;
      final blob = await imageItem.getType(imageType).toDart;
      final buffer = (await blob.arrayBuffer().toDart).toDart;
      return ClipboardImage(
        bytes: buffer.asUint8List(),
        mimeType: imageType,
        hasText: hasText,
      );
    } catch (e) {
      debugPrint('Reading a clipboard image failed: $e');
      return null;
    }
  }

  @override
  Future<bool> writePng(Uint8List png, {String? text}) async {
    try {
      final items = <String, JSAny>{
        'image/png': web.Blob(
          [png.toJS].toJS,
          web.BlobPropertyBag(type: 'image/png'),
        ),
        if (text != null)
          'text/plain': web.Blob(
            [text.toJS].toJS,
            web.BlobPropertyBag(type: 'text/plain'),
          ),
      };
      await web.window.navigator.clipboard
          .write([web.ClipboardItem(items.jsify() as JSObject)].toJS)
          .toDart;
      return true;
    } catch (e) {
      debugPrint('Writing a clipboard image failed: $e');
      return false;
    }
  }
}
