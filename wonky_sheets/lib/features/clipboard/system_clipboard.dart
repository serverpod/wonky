import 'package:wonky_app/platform.dart';

/// What the system clipboard holds: plain text and optional HTML.
class SystemClipboardData {
  const SystemClipboardData({required this.plainText, this.html});

  final String plainText;
  final String? html;
}

/// Reads and writes the system clipboard with `text/plain` + `text/html`
/// through the shell's [WonkyClipboard] (same approach as Wonky Write): the
/// async Clipboard API on web, plain text through Flutter elsewhere (the
/// last written HTML is kept in memory so copy/paste within the app stays
/// lossless).
abstract class SystemClipboard {
  const SystemClipboard();

  factory SystemClipboard.platform() =>
      _PlatformClipboard(WonkyClipboard.platform());

  Future<void> write(SystemClipboardData data);

  /// The clipboard content, or null when unavailable or denied.
  Future<SystemClipboardData?> read();

  /// Whether the last [read] was refused by the platform (the browser's
  /// clipboard permission), as opposed to an empty clipboard.
  bool get readBlocked => false;
}

/// [SystemClipboardData] over the shell clipboard; an empty or refused read
/// gives the last write (the app's own copy).
class _PlatformClipboard extends SystemClipboard {
  _PlatformClipboard(this.clipboard);

  final WonkyClipboard clipboard;
  static SystemClipboardData? _lastWrite;

  @override
  bool get readBlocked => clipboard.readBlocked;

  @override
  Future<void> write(SystemClipboardData data) async {
    _lastWrite = data;
    await clipboard.write(
      WonkyClipboardData(plainText: data.plainText, html: data.html),
    );
  }

  @override
  Future<SystemClipboardData?> read() async {
    final data = await clipboard.read();
    if (data == null || (data.plainText == null && data.html == null)) {
      return _lastWrite;
    }
    final last = _lastWrite;
    if (last != null && data.plainText == last.plainText) return last;
    return SystemClipboardData(
      plainText: data.plainText ?? '',
      html: data.html,
    );
  }
}

/// An in-memory clipboard (tests, headless use).
class MemoryClipboard extends SystemClipboard {
  MemoryClipboard();

  SystemClipboardData? data;

  @override
  bool readBlocked = false;

  @override
  Future<void> write(SystemClipboardData data) async => this.data = data;

  @override
  Future<SystemClipboardData?> read() async => data;
}
