import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:wonky_charts/wonky_charts.dart';

/// A GPU backend for 3D charts (08 §23.7): draws the meshes of a
/// [Chart3DScene] into a canvas with the same camera as the software
/// rendering, so labels and hit-testing line up.
///
/// The `flutter_scene` backend (`gpu/flutter_scene_renderer.dart`: Flutter
/// GPU on native platforms, its WebGL2 backend on the web) is registered by
/// the app's entry point and started with the first 3D chart; exports,
/// print, tests and devices without GPU support use the software rendering.
abstract class Chart3DGpuRenderer {
  /// Draws [scene]'s geometry into [canvas] (scene px; the canvas may be
  /// scaled by the zoom) at [pixelRatio] physical px per scene px. [key]
  /// identifies the chart so its GPU buffers are reused between frames.
  /// Returns false when nothing was drawn (the caller paints the software
  /// rendering instead).
  bool paint(
    Canvas canvas,
    Chart3DScene scene, {
    required Object key,
    required double pixelRatio,
  });

  /// Releases the buffers of the chart [key].
  void release(Object key);
}

/// The installed GPU backend of 3D charts.
abstract final class Chart3DBackends {
  static final ValueNotifier<Chart3DGpuRenderer?> _gpu = ValueNotifier(null);

  /// The ready GPU renderer, or null (software rendering). Listen to repaint
  /// charts when it becomes available.
  static ValueListenable<Chart3DGpuRenderer?> get gpu => _gpu;

  /// Whether 3D charts may use the GPU (Settings, tests).
  static bool enabled = true;

  /// Starts the GPU backend; registered by the app's entry point (tests
  /// don't, so they never load `flutter_scene`).
  static Future<void> Function()? starter;
  static bool _started = false;

  /// Starts the backend once, the first time a 3D chart is shown, so
  /// spreadsheets without 3D charts never load the GPU shaders.
  static void ensureStarted() {
    final s = starter;
    if (_started || s == null) return;
    _started = true;
    unawaited(
      s().catchError((Object e) {
        debugPrint('3D charts: GPU backend failed to start: $e');
      }),
    );
  }

  /// Installs [renderer] (null uninstalls it).
  static void install(Chart3DGpuRenderer? renderer) => _gpu.value = renderer;

  /// The renderer to use now, if any.
  static Chart3DGpuRenderer? get active => enabled ? _gpu.value : null;
}
