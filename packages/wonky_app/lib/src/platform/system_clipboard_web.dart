import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'system_clipboard.dart';

WonkyClipboard createWonkyClipboard() => _WebClipboard();

/// The async Clipboard API: writes `text/plain`, `text/html` and
/// `image/png` in one item (falling back to fewer types), reads text, HTML
/// and the first image.
class _WebClipboard extends WonkyClipboard {
  static bool _readBlocked = false;

  @override
  bool get readBlocked => _readBlocked;

  static web.Blob _blob(JSAny part, String type) =>
      web.Blob([part].toJS, web.BlobPropertyBag(type: type));

  Future<bool> _write(Map<String, JSAny> items) async {
    try {
      await web.window.navigator.clipboard
          .write([web.ClipboardItem(items.jsify() as JSObject)].toJS)
          .toDart;
      return true;
    } catch (e) {
      debugPrint('Clipboard write (${items.keys.join(', ')}) failed: $e');
      return false;
    }
  }

  @override
  Future<void> write(WonkyClipboardData data) async {
    lastClipboardWrite = data;
    final text = data.plainText ?? '';
    final base = <String, JSAny>{
      'text/plain': _blob(text.toJS, 'text/plain'),
      if (data.html != null) 'text/html': _blob(data.html!.toJS, 'text/html'),
    };
    final png = data.image;
    if (png != null &&
        await _write({...base, 'image/png': _blob(png.toJS, 'image/png')})) {
      return;
    }
    if (await _write(base)) return;
    try {
      await web.window.navigator.clipboard.writeText(text).toDart;
    } catch (_) {}
  }

  @override
  Future<WonkyClipboardData?> read() async {
    final clipboard = web.window.navigator.clipboard;
    _readBlocked = false;
    try {
      final items = (await clipboard.read().toDart).toDart;
      String? plain;
      String? html;
      Uint8List? image;
      String? imageType;
      for (final item in items) {
        final types = item.types.toDart.map((t) => t.toDart).toList();
        if (html == null && types.contains('text/html')) {
          final blob = await item.getType('text/html').toDart;
          html = (await blob.text().toDart).toDart;
        }
        if (plain == null && types.contains('text/plain')) {
          final blob = await item.getType('text/plain').toDart;
          plain = (await blob.text().toDart).toDart;
        }
        if (image == null) {
          for (final t in types) {
            if (!t.startsWith('image/')) continue;
            final blob = await item.getType(t).toDart;
            image = (await blob.arrayBuffer().toDart).toDart.asUint8List();
            imageType = t;
            break;
          }
        }
      }
      final out = WonkyClipboardData(
        plainText: plain,
        html: html,
        image: image,
        imageType: imageType,
      );
      return out.isEmpty ? null : withLastWrite(out);
    } catch (_) {
      try {
        final text = (await clipboard.readText().toDart).toDart;
        return withLastWrite(WonkyClipboardData(plainText: text));
      } catch (_) {
        // Both APIs refused: the browser denied clipboard access.
        _readBlocked = true;
        return null;
      }
    }
  }
}
