import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'external_drop.dart';

ExternalDropSource createExternalDropSource() => _NoExternalDrops();

/// Native desktop builds have no OS drop channel yet.
class _NoExternalDrops implements ExternalDropSource {
  @override
  void attach({
    required bool Function(Offset globalPosition, ExternalDragKind kind) onOver,
    required VoidCallback onLeave,
    required void Function(ExternalDrop drop) onDrop,
  }) {}

  @override
  void detach() {}
}
