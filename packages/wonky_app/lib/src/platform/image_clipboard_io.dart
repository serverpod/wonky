import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'image_clipboard.dart';

ImageClipboard createImageClipboard({String? macOsChannel}) =>
    macOsChannel == null
    ? const _NoImageClipboard()
    : _ChannelImageClipboard(MethodChannel(macOsChannel));

/// Desktop builds without a runner channel: no image clipboard (v2 is web
/// only, suite 01 A13).
class _NoImageClipboard extends ImageClipboard {
  const _NoImageClipboard();

  @override
  bool get supported => false;

  @override
  Future<ClipboardImage?> readImage() async => null;

  @override
  Future<bool> writePng(Uint8List png, {String? text}) async => false;
}

/// macOS: the runner's [channel] (`readImage` → `{png, hasText}`,
/// `writeImage {png, text?}`, NSPasteboard). Elsewhere: unsupported.
class _ChannelImageClipboard extends ImageClipboard {
  const _ChannelImageClipboard(this.channel);

  final MethodChannel channel;

  @override
  bool get supported => !kIsWeb && Platform.isMacOS;

  @override
  Future<ClipboardImage?> readImage() async {
    if (!supported) return null;
    try {
      final r = await channel.invokeMapMethod<String, Object?>('readImage');
      final bytes = r?['png'];
      if (bytes is! Uint8List || bytes.isEmpty) return null;
      return ClipboardImage(
        bytes: bytes,
        mimeType: 'image/png',
        hasText: r?['hasText'] == true,
      );
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint('Reading a clipboard image failed: $e');
      return null;
    }
  }

  @override
  Future<bool> writePng(Uint8List png, {String? text}) async {
    if (!supported) return false;
    try {
      return await channel.invokeMethod<bool>('writeImage', {
            'png': png,
            'text': ?text,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('Writing a clipboard image failed: $e');
      return false;
    }
  }
}
