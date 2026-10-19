import 'package:flutter/foundation.dart';

import 'image_clipboard_io.dart'
    if (dart.library.js_interop) 'image_clipboard_web.dart'
    as platform;

/// An image read from the system clipboard.
@immutable
class ClipboardImage {
  const ClipboardImage({
    required this.bytes,
    required this.mimeType,
    this.hasText = false,
  });

  final Uint8List bytes;
  final String mimeType;

  /// The clipboard also holds non-empty plain text (a copied web page with
  /// an image: in Sheets the text wins when pasting into cells).
  final bool hasText;
}

/// Images on the system clipboard (Sheets 08 §9.5, §10.1; Slides 03
/// §6.5.1, §12.5; CQ-53): pasting screenshots and copied images, *Copy
/// chart as image* and the PNG representation of copied objects for other
/// apps.
///
/// Web: the async Clipboard API (`image/png` items). macOS: a method
/// channel of the app's runner (NSPasteboard, PNG/TIFF) when the app names
/// one ([ImageClipboard.platform]'s `macOsChannel`; Sheets has
/// `wonky.sheets/clipboard`). Other platforms report no image support.
abstract class ImageClipboard {
  const ImageClipboard();

  /// The platform clipboard of this platform.
  factory ImageClipboard.platform({String? macOsChannel}) =>
      platform.createImageClipboard(macOsChannel: macOsChannel);

  /// The clipboard the apps use (replaceable in tests; an app with a macOS
  /// channel installs `ImageClipboard.platform(macOsChannel: …)` at start).
  static ImageClipboard instance = ImageClipboard.platform();

  /// Whether images can be read and written here.
  bool get supported;

  /// The clipboard image, or null when there is none (or no permission).
  Future<ClipboardImage?> readImage();

  /// Puts [png] on the clipboard, with [text] as the plain-text
  /// representation when given. Returns whether it worked.
  Future<bool> writePng(Uint8List png, {String? text});
}

/// An in-memory image clipboard (tests).
class MemoryImageClipboard extends ImageClipboard {
  MemoryImageClipboard();

  ClipboardImage? image;
  Uint8List? lastPng;
  String? lastText;

  @override
  bool get supported => true;

  @override
  Future<ClipboardImage?> readImage() async => image;

  @override
  Future<bool> writePng(Uint8List png, {String? text}) async {
    lastPng = png;
    lastText = text;
    return true;
  }
}
