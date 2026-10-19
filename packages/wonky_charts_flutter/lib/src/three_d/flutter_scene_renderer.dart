import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_scene/scene.dart' as fs;
import 'package:vector_math/vector_math.dart' as vm;
import 'package:wonky_charts/wonky_charts.dart';

import 'chart3d_gpu.dart';
import 'mesh_winding.dart';

/// The `flutter_scene` backend of 3D charts (08 §23.7): meshes built at
/// runtime from the core [Chart3DScene] faces (no asset import), physically
/// based materials from the chart palette, a soft shadow-casting key light
/// that follows the view, and the core camera, so the GPU image lines up
/// with the labels painted on top.
///
/// The core world is right-handed (+z toward the default viewer); Flutter
/// Scene's is left-handed, so z is mirrored on the way in, and triangles are
/// re-wound against their outward normals (`mesh_winding.dart`): Flutter
/// Scene lights back faces of double-sided materials with the reversed
/// normal.
class FlutterSceneChart3DRenderer implements Chart3DGpuRenderer {
  FlutterSceneChart3DRenderer._();

  /// Starts Flutter Scene; null when Flutter GPU isn't available (no
  /// Impeller, Flutter GPU not enabled, or a failing shader bundle).
  static Future<FlutterSceneChart3DRenderer?> create() async {
    try {
      await fs.Scene.initializeStaticResources();
      // One line in the console tells which backend 3D charts use.
      debugPrint('3D charts: GPU backend ready (flutter_scene)');
      return FlutterSceneChart3DRenderer._();
    } catch (e) {
      debugPrint('3D charts: Flutter GPU unavailable, using software: $e');
      return null;
    }
  }

  /// Charts kept on the GPU (least recently painted first).
  static const int maxCharts = 12;

  final LinkedHashMap<Object, _GpuChart> _charts = LinkedHashMap();

  @override
  bool paint(
    Canvas canvas,
    Chart3DScene scene, {
    required Object key,
    required double pixelRatio,
  }) {
    try {
      var chart = _charts.remove(key);
      chart ??= _GpuChart();
      _charts[key] = chart;
      while (_charts.length > maxCharts) {
        final old = _charts.keys.first;
        _charts.remove(old)?.dispose();
      }
      chart.sync(scene);
      final cam = scene.camera;
      final vp = cam.gpuViewport;
      final camera = fs.PerspectiveCamera(
        fovRadiansY: cam.gpuFovY,
        position: _v(cam.eye),
        target: _v(cam.target),
        up: _n(cam.up),
        fovNear: math.max(0.01, (cam.eye - cam.target).length * 0.05),
        fovFar: (cam.eye - cam.target).length * 4 + 10,
      );
      final c = scene.viewport.inflate(scene.viewport.width * 0.25);
      final clip = Rect.fromLTWH(c.left, c.top, c.width, c.height);
      final viewport = Rect.fromLTWH(vp.left, vp.top, vp.width, vp.height);
      if (!kIsWeb) {
        canvas.save();
        canvas.clipRect(clip);
        chart.scene.render(
          camera,
          canvas,
          viewport: viewport,
          pixelRatio: pixelRatio,
        );
        canvas.restore();
        return true;
      }
      // On the web, Flutter Scene hands each frame over as an image made
      // from a transferred ImageBitmap, which is only good for the frame it
      // was recorded in: when the engine rasterizes the chart's picture
      // again (a dialog's backdrop blur, the side sheet's scrim) the chart
      // came out blank. Snapshot it into an engine-owned image instead.
      final w = (clip.width * pixelRatio).ceil();
      final h = (clip.height * pixelRatio).ceil();
      if (w < 1 || h < 1) return true;
      final recorder = PictureRecorder();
      final pc = Canvas(recorder)
        ..scale(pixelRatio)
        ..translate(-clip.left, -clip.top);
      chart.scene.render(
        camera,
        pc,
        viewport: viewport,
        pixelRatio: pixelRatio,
      );
      final picture = recorder.endRecording();
      final image = picture.toImageSync(w, h);
      picture.dispose();
      chart.setImage(image);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        clip,
        Paint()..filterQuality = FilterQuality.medium,
      );
      return true;
    } catch (e, st) {
      debugPrint('3D charts: GPU rendering failed: $e\n$st');
      return false;
    }
  }

  @override
  void release(Object key) => _charts.remove(key)?.dispose();
}

/// Mirrors z (right-handed core world → Flutter Scene).
vm.Vector3 _v(Vec3 p) => vm.Vector3(p.x, p.y, -p.z);
vm.Vector3 _n(Vec3 n) => vm.Vector3(n.x, n.y, -n.z);

double _lin(int c) => math.pow(c / 255, 2.2).toDouble();

vm.Vector4 _linear(int argb) => vm.Vector4(
  _lin(Argb.red(argb)),
  _lin(Argb.green(argb)),
  _lin(Argb.blue(argb)),
  Argb.alpha(argb) / 255,
);

/// One chart's Flutter Scene and the hash of the model its meshes show.
///
/// Meshes are grouped by (color, part). A model change rebuilds them all; a
/// hover change (the hovered data is drawn lighter, so it moves to another
/// color group) rebuilds only the groups whose chunks changed and keeps the
/// others and the gridlines (CQ-47).
class _GpuChart {
  final fs.Scene scene = fs.Scene()..maxGpuFramesInFlight = 0;
  int? _contentHash;
  int? _hash;
  Chart3DLighting? _lighting;
  double? _span;

  /// Mesh nodes by (color, part) with the indices (into
  /// [Chart3DScene.chunks]) of the chunks they hold.
  final Map<(int, Chart3DPart), (List<int>, fs.Node)> _groups = {};

  void sync(Chart3DScene s) {
    final model = s.model;
    final content = model.contentHash;
    if (content != _contentHash) {
      _contentHash = content;
      _hash = s.meshHash;
      _rebuild(s);
    }
    final hash = s.meshHash;
    if (hash != _hash) {
      _hash = hash;
      _syncGroups(s);
    }
    if (_lighting != model.lighting) {
      _lighting = model.lighting;
      _applyLook(model.lighting);
    }
    // The key light follows the view (like the software shading).
    final light = scene.directionalLight;
    if (light != null) {
      final l = s.lightDirection;
      light.direction = vm.Vector3(-l.x, -l.y, l.z);
      final distance = (s.camera.eye - s.camera.target).length;
      light.shadowMaxDistance = distance + (_span ?? 4) * 2;
    }
  }

  void _applyLook(Chart3DLighting lighting) {
    final (direct, env, shadow) = switch (lighting) {
      Chart3DLighting.soft => (2.4, 0.9, true),
      Chart3DLighting.bright => (3.6, 0.8, true),
      Chart3DLighting.flat => (1.0, 1.6, false),
    };
    scene.environmentSettings = fs.EnvironmentSettings(
      toneMapping: fs.ToneMappingMode.pbrNeutral,
      environmentIntensity: env,
      ambientOcclusionEnabled: lighting != Chart3DLighting.flat,
      ambientOcclusionIntensity: 0.7,
      ambientOcclusionHalfResolution: true,
    );
    scene.directionalLight = fs.DirectionalLight(
      intensity: direct,
      castsShadow: shadow,
      shadowSoftness: 0.12,
      shadowCascadeCount: 1,
      shadowMapResolution: 2048,
    );
  }

  /// Everything (the model changed): meshes first, then the gridlines.
  void _rebuild(Chart3DScene s) {
    scene.removeAll();
    _groups.clear();
    final model = s.model;
    _span = (model.bounds.max - model.bounds.min).length;
    _syncGroups(s);
    _addLines(s);
  }

  /// One mesh per color and part; groups whose chunks are unchanged keep
  /// their node.
  void _syncGroups(Chart3DScene s) {
    final roughness = switch (s.model.lighting) {
      Chart3DLighting.soft => 0.45,
      Chart3DLighting.bright => 0.28,
      Chart3DLighting.flat => 0.9,
    };
    final chunks = s.chunks;
    final groups = <(int, Chart3DPart), List<int>>{};
    for (var i = 0; i < chunks.length; i++) {
      final c = chunks[i];
      (groups[(s.colorOf(c), c.item.part)] ??= []).add(i);
    }
    for (final key in _groups.keys.toList()) {
      final next = groups[key];
      if (next == null || !listEquals(next, _groups[key]!.$1)) {
        scene.remove(_groups.remove(key)!.$2);
      }
    }
    for (final MapEntry(key: key, value: indices) in groups.entries) {
      if (_groups.containsKey(key)) continue;
      final (color, part) = key;
      final geometry = _geometry([for (final i in indices) chunks[i]]);
      if (geometry == null) continue;
      final material = fs.PhysicallyBasedMaterial()
        ..baseColorFactor = _linear(color)
        ..metallicFactor = 0
        ..roughnessFactor = part == Chart3DPart.data ? roughness : 0.95
        ..doubleSided = true;
      final node = fs.Node(mesh: fs.Mesh(geometry, material));
      scene.add(node);
      _groups[key] = (indices, node);
    }
  }

  /// Gridlines: thin strips lifted off their wall.
  void _addLines(Chart3DScene s) {
    final width = _span! * 0.0025;
    final lines = <int, List<Chart3DLine>>{};
    for (final l in s.lines) {
      (lines[l.color] ??= []).add(l);
    }
    for (final MapEntry(key: color, value: list) in lines.entries) {
      final pos = <double>[];
      final idx = <int>[];
      for (final l in list) {
        final dir = (l.b - l.a).normalized;
        final side = dir.cross(l.normal).normalized * (width / 2);
        final lift = l.normal * (width * 0.6);
        final base = pos.length ~/ 3;
        for (final p in [
          l.a - side + lift,
          l.b - side + lift,
          l.b + side + lift,
          l.a + side + lift,
        ]) {
          pos.addAll([p.x, p.y, -p.z]);
        }
        idx.addAll([base, base + 1, base + 2, base, base + 2, base + 3]);
      }
      final material = fs.UnlitMaterial()
        ..baseColorFactor = _linear(color)
        ..doubleSided = true
        ..depthLayer = 1;
      scene.add(
        fs.Node(
          mesh: fs.Mesh(
            fs.MeshGeometry.fromArrays(
              positions: Float32List.fromList(pos),
              indices: idx,
            ),
            material,
          ),
        ),
      );
    }
  }

  static fs.MeshGeometry? _geometry(List<Chart3DChunk> chunks) {
    final pos = <double>[];
    final nrm = <double>[];
    final idx = <int>[];
    for (final c in chunks) {
      for (final f in c.faces) {
        final base = pos.length ~/ 3;
        for (var i = 0; i < f.points.length; i++) {
          final p = f.points[i];
          final n = f.normalAt(i);
          pos.addAll([p.x, p.y, -p.z]);
          nrm.addAll([n.x, n.y, -n.z]);
        }
        for (final t in gpuTriangleIndices(f)) {
          idx.add(base + t);
        }
      }
    }
    if (idx.isEmpty) return null;
    return fs.MeshGeometry.fromArrays(
      positions: Float32List.fromList(pos),
      normals: Float32List.fromList(nrm),
      indices: idx,
    );
  }

  /// The last frame on the web (see `paint`); disposed when replaced.
  Image? _image;

  void setImage(Image image) {
    _image?.dispose();
    _image = image;
  }

  void dispose() {
    _image?.dispose();
    _image = null;
    scene.dispose();
  }
}
