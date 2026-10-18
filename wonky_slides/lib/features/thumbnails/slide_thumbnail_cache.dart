import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:wonky_slides_core/scene.dart';

import '../stage/slide_image_cache.dart';
import '../stage/slide_stage.dart';

/// A recorded thumbnail.
class SlideThumbnailPicture {
  SlideThumbnailPicture(this.picture, this.size, {required this.complete});

  /// The slide drawn at [size] (logical px).
  final ui.Picture picture;

  /// Logical size of the picture.
  final ui.Size size;

  /// Whether every image was decoded when it was recorded (incomplete
  /// thumbnails are re-recorded once more images are available).
  final bool complete;

  /// Whether [picture] was disposed (replaced or evicted): painters that
  /// still hold it draw nothing until they rebuild with the new one.
  bool get disposed => _disposed;
  bool _disposed = false;

  void _dispose() {
    if (_disposed) return;
    _disposed = true;
    picture.dispose();
  }
}

/// Thumbnails of slides as recorded pictures (03 §18: ≤ 8 ms each, off the
/// critical path), LRU-bounded. One entry per key (the caller's slide id,
/// width and appearance) holding the render revision it was recorded at: a
/// changed slide replaces its entry in place instead of adding one, so
/// typing on one slide doesn't evict the thumbnails of others (CQ-43).
/// Replaced and evicted pictures are disposed after the current frame.
class SlideThumbnailCache {
  SlideThumbnailCache({this.capacity = 400});

  /// Maximum pictures kept.
  final int capacity;

  final LinkedHashMap<String, _Entry> _entries = LinkedHashMap();
  List<SlideThumbnailPicture>? _retired;

  /// Pictures recorded so far (tests, benchmarks).
  @visibleForTesting
  int debugRecords = 0;

  /// Cached entries.
  int get length => _entries.length;

  /// The cached picture of [key], or null.
  SlideThumbnailPicture? lookup(String key) => _entries[key]?.picture;

  /// The picture of [key] at [revision]: cached, or recorded from [scene]
  /// at [width] logical px. An entry recorded while images were missing is
  /// recorded again once [images] has decoded more.
  SlideThumbnailPicture? picture(
    String key,
    SlideScene? Function() scene, {
    required double width,
    String revision = '',
    SlideImageCache? images,
  }) {
    final hit = _entries.remove(key);
    final gen = images?.generation ?? 0;
    if (hit != null &&
        hit.revision == revision &&
        (hit.picture.complete || hit.generation == gen)) {
      _entries[key] = hit;
      return hit.picture;
    }
    final s = scene();
    if (s == null || s.width <= 0) {
      if (hit != null) _retire(hit.picture);
      return null;
    }
    final scale = width / s.width;
    debugRecords++;
    final picture = recordScene(s, scale: scale, images: images);
    final entry = SlideThumbnailPicture(
      picture,
      ui.Size(width, s.height * scale),
      complete: images == null || images.isComplete(s),
    );
    if (hit != null) _retire(hit.picture);
    _entries[key] = _Entry(entry, revision, gen);
    while (_entries.length > capacity) {
      _retire(_entries.remove(_entries.keys.first)!.picture);
    }
    return entry;
  }

  /// Drops every entry whose key starts with `<slideId>|`.
  void invalidate(String slideId) => _entries.removeWhere((k, e) {
    if (!k.startsWith('$slideId|')) return false;
    _retire(e.picture);
    return true;
  });

  /// Drops everything.
  void clear() {
    for (final e in _entries.values) {
      _retire(e.picture);
    }
    _entries.clear();
  }

  /// Disposes [p] once the current frame (whose painters may still draw
  /// it) is done.
  void _retire(SlideThumbnailPicture p) {
    final retired = _retired;
    if (retired != null) {
      retired.add(p);
      return;
    }
    _retired = [p];
    scheduleMicrotask(() {
      final list = _retired!;
      _retired = null;
      for (final r in list) {
        r._dispose();
      }
    });
  }
}

class _Entry {
  _Entry(this.picture, this.revision, this.generation);

  final SlideThumbnailPicture picture;
  final String revision;
  final int generation;
}
