import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/themes.dart' show ResolvedImageFill;

/// Decodes [bytes], downscaled to at most [targetWidth] pixels wide (null =
/// full size; never upscaled).
typedef SlideImageDecoder =
    Future<ui.Image> Function(Uint8List bytes, {int? targetWidth});

/// Decoded slide images (03 §6.5, 02 §6.4) for the stage, thumbnails and
/// presenting: bytes come from the [SlideImageResolver] (pending uploads,
/// the file cache, the server) and are decoded at the size they are drawn
/// at (power-of-two width buckets, never above the natural size) into an
/// LRU bounded by bytes ([maxBytes], CQ-43). Listeners are notified when an
/// image finished decoding, so painters repaint.
///
/// Every renderer of one open deck shares one cache ([SlideImageCache.
/// shared], refcounted). A missing image (null bytes: deleted, no access)
/// or an undecodable one stays failed; a transient failure
/// ([SlideImageTransientException]: offline, a server error) is retried
/// with backoff, and every failure is retried when a
/// [RetryingSlideImageResolver] says the connection came back.
class SlideImageCache extends ChangeNotifier {
  /// Creates a cache over [resolver] keeping up to [maxBytes] of decoded
  /// pixels.
  SlideImageCache(
    this.resolver, {
    int? maxBytes,
    SlideImageDecoder? decode,
    this.retryDelay = const Duration(seconds: 2),
  }) : maxBytes = maxBytes ?? defaultMaxBytes,
       _decode = decode ?? _defaultDecode {
    final r = resolver;
    if (r is RetryingSlideImageResolver) {
      _retries = r.retries.listen((_) => retryFailed());
    }
  }

  /// The cache shared by every renderer over [resolver] (one per open
  /// deck: canvas, navigator, previews, presenting). Call [release] when
  /// done.
  factory SlideImageCache.shared(SlideImageResolver resolver) {
    final hit = _shared[resolver];
    if (hit != null && !hit._disposed) {
      hit._refs++;
      return hit;
    }
    final c = SlideImageCache(resolver).._refs = 1;
    _shared[resolver] = c;
    return c;
  }

  static final Expando<SlideImageCache> _shared = Expando(
    'sharedSlideImageCache',
  );

  /// The default budget of decoded pixels (RGBA bytes).
  static int get defaultMaxBytes =>
      kIsWeb ? 160 * 1024 * 1024 : 256 * 1024 * 1024;

  /// The smallest decode bucket (px).
  static const minBucket = 64;

  /// The image bytes source.
  final SlideImageResolver resolver;

  /// Budget of decoded pixels in bytes (4 per pixel). At least one image
  /// is always kept.
  final int maxBytes;

  /// First backoff after a transient failure (doubles, up to a minute).
  final Duration retryDelay;

  final SlideImageDecoder _decode;
  final LinkedHashMap<String, _Decoded> _images = LinkedHashMap();
  final Map<String, Set<String>> _variants = {};
  final Map<String, Future<void>> _loading = {};
  final Set<String> _failed = {};
  final Map<String, _Transient> _transient = {};
  StreamSubscription<void>? _retries;
  int _bytes = 0;
  int _refs = 0;
  bool _disposed = false;

  /// Bumped every time an image becomes available.
  int get generation => _generation;
  int _generation = 0;

  /// Bytes of decoded pixels held.
  int get bytes => _bytes;

  /// Decoded images held (all sizes).
  int get length => _images.length;

  static Future<ui.Image> _defaultDecode(
    Uint8List bytes, {
    int? targetWidth,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (w, h) => targetWidth == null || w <= targetWidth
          ? ui.TargetImageSize(width: w, height: h)
          : ui.TargetImageSize(width: targetWidth),
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// The decode bucket for drawing an image [width] device pixels wide
  /// (null = full size).
  static int? bucketFor(double? width) {
    if (width == null || !width.isFinite || width <= 0) return null;
    final w = math.max(width, minBucket.toDouble());
    final b = 1 << (math.log(w) / math.ln2).ceil();
    return b > 16384 ? null : b;
  }

  static String _key(String src, int? bucket) => '$src@${bucket ?? 'full'}';

  /// The decoded image of [ref], or null while it loads (a load starts) or
  /// when it is unavailable. [width] is the drawn width of the whole image
  /// in device pixels (null = full size): a version at least that wide is
  /// returned when one is cached, else the largest cached one while the
  /// needed size decodes.
  ui.Image? imageOf(SlideImageRef ref, {double? width}) {
    final src = ref.src;
    final bucket = bucketFor(width);
    final exact = _touch(_key(src, bucket));
    if (exact != null) return exact.image;
    // Another size: the smallest that is large enough, else the largest.
    _Decoded? fit, largest;
    for (final k in _variants[src] ?? const <String>{}) {
      final d = _images[k];
      if (d == null) continue;
      final enough = d.full || (bucket != null && d.image.width >= bucket);
      if (enough && (fit == null || d.image.width < fit.image.width)) fit = d;
      if (largest == null || d.image.width > largest.image.width) {
        largest = d;
      }
    }
    if (fit != null) return _touch(fit.key)!.image;
    if (_canLoad(src)) unawaited(load(ref, width: width));
    return largest?.image;
  }

  _Decoded? _touch(String key) {
    final hit = _images.remove(key);
    if (hit != null) _images[key] = hit;
    return hit;
  }

  bool _canLoad(String src) {
    if (_failed.contains(src)) return false;
    final t = _transient[src];
    return t == null || !DateTime.now().isBefore(t.retryAt);
  }

  /// Whether [ref] failed to load for good (missing, no access, corrupt).
  bool hasFailed(SlideImageRef ref) => _failed.contains(ref.src);

  /// Loads [ref] at [width] device pixels (null = full size; idempotent
  /// while loading).
  Future<void> load(SlideImageRef ref, {double? width}) {
    final bucket = bucketFor(width);
    final key = _key(ref.src, bucket);
    return _loading[key] ??= _load(ref, bucket, key).whenComplete(() {
      // A block body: returning the removed future would make the
      // completion wait for itself.
      _loading.remove(key);
    });
  }

  /// Loads every image of [scene] at full size (prefetch before
  /// presenting, 06 §14; exports).
  Future<void> preload(SlideScene scene) =>
      Future.wait([for (final ref in imagesOf(scene)) load(ref)]);

  /// Whether every image of [scene] is decoded (at some size) or failed
  /// for good (thumbnails are cached only when complete).
  bool isComplete(SlideScene scene) => imagesOf(scene).every(
    (r) => (_variants[r.src]?.isNotEmpty ?? false) || _failed.contains(r.src),
  );

  /// The image references of [scene] (image nodes and image fills).
  static Iterable<SlideImageRef> imagesOf(SlideScene scene) sync* {
    final bg = scene.background;
    for (final f in [bg.fill, bg.overlay]) {
      if (f is ResolvedImageFill) {
        yield SlideImageRef('${SlideImageRef.fileScheme}${f.fileUuid}');
      }
    }
    Iterable<SlideImageRef> walk(List<SceneNode> nodes) sync* {
      for (final n in nodes) {
        switch (n) {
          case ImageNode(:final image):
            yield image;
          case PathNode(fill: ResolvedImageFill(:final fileUuid)):
            yield SlideImageRef('${SlideImageRef.fileScheme}$fileUuid');
          case GroupNode(:final children):
            yield* walk(children);
          default:
            break;
        }
      }
    }

    yield* walk(scene.nodes);
  }

  Future<void> _load(SlideImageRef ref, int? bucket, String key) async {
    final src = ref.src;
    Uint8List? bytes;
    try {
      bytes = resolver.cachedBytes(ref) ?? await resolver.bytes(ref);
    } catch (e) {
      _transientFailure(src, e);
      return;
    }
    if (_disposed) return;
    if (bytes == null) {
      _failed.add(src);
      return;
    }
    final ui.Image image;
    try {
      image = await _decode(bytes, targetWidth: bucket);
    } catch (e) {
      debugPrint('Decoding slide image $src failed: $e');
      _failed.add(src);
      return;
    }
    if (_disposed) {
      image.dispose();
      return;
    }
    _transient.remove(src)?.timer?.cancel();
    // A full decode no larger than the bucket stands for every size.
    final full = bucket == null || image.width < bucket;
    final k = full ? _key(src, null) : key;
    _images.remove(k)?.dispose(this);
    final d = _Decoded(k, src, image, full: full);
    _images[k] = d;
    (_variants[src] ??= {}).add(k);
    _bytes += d.bytes;
    while (_bytes > maxBytes && _images.length > 1) {
      _images.remove(_images.keys.first)!.dispose(this);
    }
    _generation++;
    notifyListeners();
  }

  void _transientFailure(String src, Object error) {
    debugPrint('Loading slide image $src failed (will retry): $error');
    if (_disposed) return;
    final attempts = (_transient[src]?.attempts ?? 0) + 1;
    final delay = retryDelay * math.min(1 << (attempts - 1), 30);
    _transient[src]?.timer?.cancel();
    _transient[src] = _Transient(
      attempts,
      DateTime.now().add(delay),
      // Painters ask again (and load) once the backoff has passed.
      Timer(delay, () {
        if (!_disposed) notifyListeners();
      }),
    );
  }

  /// Forgets a failure so the image is fetched again.
  void retry(SlideImageRef ref) {
    _failed.remove(ref.src);
    _transient.remove(ref.src)?.timer?.cancel();
  }

  /// Forgets every failure and repaints, so missing images load again (the
  /// connection came back).
  void retryFailed() {
    if (_disposed || (_failed.isEmpty && _transient.isEmpty)) return;
    _failed.clear();
    for (final t in _transient.values) {
      t.timer?.cancel();
    }
    _transient.clear();
    notifyListeners();
  }

  /// Gives up one reference of a [SlideImageCache.shared] cache (disposes
  /// it with the last one; a cache made with the constructor is disposed
  /// at once).
  void release() {
    if (--_refs <= 0) dispose();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_retries?.cancel());
    for (final t in _transient.values) {
      t.timer?.cancel();
    }
    for (final i in _images.values) {
      i.image.dispose();
    }
    _images.clear();
    _variants.clear();
    _bytes = 0;
    if (identical(_shared[resolver], this)) _shared[resolver] = null;
    super.dispose();
  }
}

class _Decoded {
  _Decoded(this.key, this.src, this.image, {required this.full});

  final String key;
  final String src;
  final ui.Image image;
  final bool full;

  int get bytes => image.width * image.height * 4;

  void dispose(SlideImageCache cache) {
    cache._bytes -= bytes;
    final v = cache._variants[src];
    if (v != null) {
      v.remove(key);
      if (v.isEmpty) cache._variants.remove(src);
    }
    image.dispose();
  }
}

class _Transient {
  _Transient(this.attempts, this.retryAt, this.timer);

  final int attempts;
  final DateTime retryAt;
  final Timer? timer;
}
