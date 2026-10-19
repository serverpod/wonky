import 'package:flutter/foundation.dart';

import 'system_clipboard_io.dart'
    if (dart.library.js_interop) 'system_clipboard_web.dart'
    as platform;

/// What the system clipboard holds: plain text, HTML and the first image.
@immutable
class WonkyClipboardData {
  const WonkyClipboardData({
    this.plainText,
    this.html,
    this.image,
    this.imageType,
  });

  final String? plainText;
  final String? html;

  /// Image bytes (`image/png` and other image types) and their type.
  final Uint8List? image;
  final String? imageType;

  bool get isEmpty =>
      (plainText == null || plainText!.isEmpty) &&
      (html == null || html!.isEmpty) &&
      image == null;
}

/// The system clipboard shared by the apps (Write 04 §23, Sheets 07,
/// Slides 03 §12.1; CQ-53).
///
/// On the web, the async Clipboard API writes `text/plain`, `text/html` and
/// optionally `image/png` in one item (falling back to fewer types, then to
/// `writeText`) and reads text, HTML and the first image. Desktop builds use
/// plain text through Flutter's `Clipboard`. Everywhere the last write is
/// kept in memory and returned while the clipboard's plain text still
/// matches it, so copy and paste within the app stay lossless (the HTML and
/// image survive a plain-text-only platform clipboard).
abstract class WonkyClipboard {
  const WonkyClipboard();

  /// The platform clipboard.
  factory WonkyClipboard.platform() => platform.createWonkyClipboard();

  Future<void> write(WonkyClipboardData data);

  /// The clipboard content, or null when it is empty, unavailable or
  /// denied ([readBlocked]).
  Future<WonkyClipboardData?> read();

  /// Whether the last [read] was refused by the platform (the browser's
  /// clipboard permission), as opposed to an empty clipboard.
  bool get readBlocked => false;
}

/// The last write, returned by a read whose plain text still matches it.
WonkyClipboardData? lastClipboardWrite;

/// [read] with the last write substituted when their (non-empty) plain text
/// matches: never for an empty text, which can't tell an image copied
/// elsewhere from the last write.
WonkyClipboardData? withLastWrite(WonkyClipboardData? read) {
  final last = lastClipboardWrite;
  final text = read?.plainText;
  if (read == null || last == null || text == null || text.isEmpty) {
    return read;
  }
  return last.plainText == text ? last : read;
}
