import 'dart:typed_data';

import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/schema.dart';

import 'rev_page_decoder_io.dart'
    if (dart.library.js_interop) 'rev_page_decoder_web.dart'
    as platform;

/// Decodes bootstrap page bodies (RevLog spec 04 §3.1) off the UI thread:
/// on desktop and mobile in a short-lived isolate per page (the rows come
/// back without a copy), on the web in slices that yield to the event
/// loop between them. Small bodies are decoded inline.
abstract final class RevPageDecoder {
  /// Bodies up to this size are decoded inline (an isolate costs more).
  static int inlineBelow = 32 * 1024;

  /// Decodes [body].
  static Future<List<RevPageRow>> decode(RevSchema schema, Uint8List body) {
    if (body.length < inlineBelow) {
      return Future.value(RevPageCodec.decode(schema, body));
    }
    return platform.decodePage(schema, body);
  }
}
