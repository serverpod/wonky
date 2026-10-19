import 'package:flutter/services.dart';

import 'system_clipboard.dart';

WonkyClipboard createWonkyClipboard() => const _FlutterClipboard();

/// Plain text through Flutter's `Clipboard`; the last write (HTML, image)
/// is returned while the plain text still matches.
class _FlutterClipboard extends WonkyClipboard {
  const _FlutterClipboard();

  @override
  Future<void> write(WonkyClipboardData data) async {
    lastClipboardWrite = data;
    try {
      await Clipboard.setData(ClipboardData(text: data.plainText ?? ''));
    } catch (_) {
      // No platform clipboard (tests).
    }
  }

  @override
  Future<WonkyClipboardData?> read() async {
    final ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } catch (_) {
      return lastClipboardWrite;
    }
    final text = data?.text;
    if (text == null) return null;
    return withLastWrite(WonkyClipboardData(plainText: text));
  }
}
