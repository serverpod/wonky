import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'external_drop_io.dart'
    if (dart.library.js_interop) 'external_drop_web.dart'
    as platform;

/// A file dropped from the operating system.
@immutable
class DroppedFile {
  const DroppedFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;

  /// The browser's MIME type (may be empty).
  final String mimeType;
  final Uint8List bytes;

  /// The lower-case file extension without the dot ('' when none).
  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 || dot == name.length - 1
        ? ''
        : name.substring(dot + 1).toLowerCase();
  }
}

/// What is being dragged over the window from another application.
enum ExternalDragKind {
  /// One or more files.
  files,

  /// Text or HTML (from another app or browser tab).
  text,
}

/// Something dropped onto the window from another application (Write 04 §24,
/// Slides 03 §6.5.1).
@immutable
class ExternalDrop {
  const ExternalDrop({
    required this.globalPosition,
    this.files = const [],
    this.plainText,
    this.html,
  });

  /// Where it was dropped (logical pixels, global).
  final Offset globalPosition;
  final List<DroppedFile> files;
  final String? plainText;
  final String? html;

  bool get hasFiles => files.isNotEmpty;
}

/// Receives drags and drops from other applications over the whole window.
///
/// On the web it listens to the browser's `dragover` / `drop` events and
/// always prevents the browser default (which would navigate away to the
/// dropped file). Native desktop OS drops are not available yet (no
/// platform drop plugin), so there [ExternalDropSource.platform] never
/// reports anything.
abstract class ExternalDropSource {
  /// The platform implementation.
  factory ExternalDropSource.platform() => platform.createExternalDropSource();

  /// Starts listening. [onOver] gets the pointer and the dragged kind while a
  /// drag hovers the window (and `null` when it leaves); it returns whether a
  /// drop at that position would be accepted. [onDrop] gets the dropped data.
  void attach({
    required bool Function(Offset globalPosition, ExternalDragKind kind) onOver,
    required VoidCallback onLeave,
    required void Function(ExternalDrop drop) onDrop,
  });

  /// Stops listening.
  void detach();
}
