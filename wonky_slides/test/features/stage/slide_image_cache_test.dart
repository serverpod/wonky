import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/stage/slide_image_cache.dart';
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/scene.dart';

/// A resolver whose answers tests script: bytes, null (gone) or a
/// transient failure, plus a retry signal.
class _Resolver implements RetryingSlideImageResolver {
  final Map<String, Object?> answers = {};
  final StreamController<void> signal = StreamController.broadcast();
  int calls = 0;

  @override
  Uint8List? cachedBytes(SlideImageRef ref) => null;

  @override
  Future<Uint8List?> bytes(SlideImageRef ref) async {
    calls++;
    final a = answers[ref.src];
    if (a is Exception) throw a;
    return a as Uint8List?;
  }

  @override
  Future<Uri?> url(SlideImageRef ref) async => null;

  @override
  Stream<void> get retries => signal.stream;
}

const _ref = SlideImageRef('wonky-file://photo');
final _bytes = Uint8List.fromList([1, 2, 3]);

/// A decoder that makes [width] × [width/2] images (or the target width).
SlideImageDecoder _decoder(int width, List<int?> targets) =>
    (bytes, {targetWidth}) {
      targets.add(targetWidth);
      final w = targetWidth == null || targetWidth > width
          ? width
          : targetWidth;
      return createTestImage(width: w, height: w ~/ 2);
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Given an image drawn smaller than its natural size when it '
      'loads then it decodes at the next power-of-two width', () async {
    final targets = <int?>[];
    final r = _Resolver()..answers[_ref.src] = _bytes;
    final cache = SlideImageCache(r, decode: _decoder(3000, targets));
    addTearDown(cache.dispose);

    expect(cache.imageOf(_ref, width: 600), isNull);
    await cache.load(_ref, width: 600);

    expect(targets, [1024]);
    expect(cache.imageOf(_ref, width: 600)!.width, 1024);
    expect(cache.bytes, 1024 * 512 * 4);
    // A smaller drawing reuses it; a larger one loads a larger version and
    // shows the cached one meanwhile.
    expect(cache.imageOf(_ref, width: 300)!.width, 1024);
    expect(cache.imageOf(_ref, width: 1500)!.width, 1024);
    await cache.load(_ref, width: 1500);
    expect(cache.imageOf(_ref, width: 1500)!.width, 2048);
  });

  test('Given a byte budget when more images decode than fit then the '
      'least recently used are dropped', () async {
    final r = _Resolver();
    for (final s in ['a', 'b', 'c']) {
      r.answers['wonky-file://$s'] = _bytes;
    }
    final cache = SlideImageCache(
      r,
      maxBytes: 2 * 100 * 50 * 4,
      decode: _decoder(100, []),
    );
    addTearDown(cache.dispose);

    for (final s in ['a', 'b', 'c']) {
      await cache.load(SlideImageRef('wonky-file://$s'));
    }

    expect(cache.length, 2);
    expect(cache.bytes, 2 * 100 * 50 * 4);
  });

  test('Given a transient failure (offline) when the backoff passes '
      'then the image loads again', () async {
    final r = _Resolver()
      ..answers[_ref.src] = const SlideImageTransientException('offline');
    final cache = SlideImageCache(
      r,
      decode: _decoder(100, []),
      retryDelay: const Duration(milliseconds: 20),
    );
    addTearDown(cache.dispose);
    var notified = 0;
    cache.addListener(() => notified++);

    await cache.load(_ref);
    expect(cache.hasFailed(_ref), isFalse);
    expect(cache.imageOf(_ref), isNull);
    expect(r.calls, 1, reason: 'no new attempt before the backoff');

    r.answers[_ref.src] = _bytes;
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(notified, greaterThan(0), reason: 'painters ask again');
    expect(cache.imageOf(_ref), isNull);
    await Future<void>.delayed(Duration.zero);
    await cache.load(_ref);
    expect(cache.imageOf(_ref), isNotNull);
  });

  test('Given a missing image when the connection comes back then it '
      'is tried again', () async {
    final r = _Resolver(); // null: gone
    final cache = SlideImageCache(r, decode: _decoder(100, []));
    addTearDown(cache.dispose);

    await cache.load(_ref);
    expect(cache.hasFailed(_ref), isTrue);
    cache.imageOf(_ref);
    expect(r.calls, 1);

    r.answers[_ref.src] = _bytes;
    r.signal.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(cache.hasFailed(_ref), isFalse);
    await cache.load(_ref);
    expect(cache.imageOf(_ref), isNotNull);
  });

  test('Given renderers over one resolver when sharing the cache then it is '
      'one instance, disposed with the last release', () {
    final r = _Resolver();
    final a = SlideImageCache.shared(r);
    final b = SlideImageCache.shared(r);

    expect(identical(a, b), isTrue);
    a.release();
    expect(() => b.addListener(() {}), returnsNormally);
    b.release();
    final c = SlideImageCache.shared(r);
    expect(identical(c, a), isFalse);
    c.release();
  });

  test('Given drawn widths when bucketing then widths round up to powers of '
      'two from 64', () {
    expect(SlideImageCache.bucketFor(null), isNull);
    expect(SlideImageCache.bucketFor(10), 64);
    expect(SlideImageCache.bucketFor(600), 1024);
    expect(SlideImageCache.bucketFor(1024), 1024);
    expect(SlideImageCache.bucketFor(1e9), isNull);
  });

  test('Given a decoded image when disposing the cache then its '
      'images are released', () async {
    final r = _Resolver()..answers[_ref.src] = _bytes;
    final cache = SlideImageCache(r, decode: _decoder(100, []));
    await cache.load(_ref);
    final ui.Image image = cache.imageOf(_ref)!;

    cache.dispose();

    expect(image.debugDisposed, isTrue);
  });
}
