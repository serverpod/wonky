import 'package:wonky_app/platform.dart';

import 'clipboard_codec.dart';

/// Reads and writes the system clipboard with multiple representations
/// (Write 04 §23) through the shell's [WonkyClipboard] (web: the async
/// Clipboard API with `text/html` + `text/plain`; elsewhere plain text).
abstract class SystemClipboard {
  const SystemClipboard();

  /// The platform clipboard.
  factory SystemClipboard.platform() =>
      _PlatformClipboard(WonkyClipboard.platform());

  Future<void> write(ClipboardContent content);

  /// The current clipboard content, or `null` when unavailable or denied.
  Future<ClipboardContent?> read();
}

/// [ClipboardContent] over the shell clipboard. The last copy (with its
/// Wonky Delta) is returned while the clipboard's plain text still matches,
/// so copy/paste within the app is lossless.
class _PlatformClipboard extends SystemClipboard {
  _PlatformClipboard(this.clipboard);

  final WonkyClipboard clipboard;
  static ClipboardContent? _lastWrite;

  @override
  Future<void> write(ClipboardContent content) async {
    _lastWrite = content;
    await clipboard.write(
      WonkyClipboardData(plainText: content.plainText, html: content.html),
    );
  }

  @override
  Future<ClipboardContent?> read() async {
    final data = await clipboard.read();
    if (data == null || (data.plainText == null && data.html == null)) {
      return null;
    }
    final last = _lastWrite;
    if (last != null && last.plainText == data.plainText) return last;
    return ClipboardContent(plainText: data.plainText ?? '', html: data.html);
  }
}

/// An in-memory clipboard (tests, headless use).
class MemoryClipboard extends SystemClipboard {
  MemoryClipboard();

  ClipboardContent? content;

  @override
  Future<void> write(ClipboardContent content) async => this.content = content;

  @override
  Future<ClipboardContent?> read() async => content;
}
