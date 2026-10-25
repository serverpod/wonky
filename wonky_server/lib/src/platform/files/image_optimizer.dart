import 'package:pixtronaut/pixtronaut.dart' as px;
import 'package:serverpod/serverpod.dart';

import '../common/models.dart';

/// The WebP file an [ImageOptimizer.optimize] call wrote next to its
/// source.
typedef OptimizedImage = ({String path, String fileName, int sizeBytes});

/// The source of an [ImageOptimizer.optimize] call is not a readable image
/// (corrupt, an unsupported variant of its type, or over the pixel limits).
class UnreadableImageException implements Exception {
  UnreadableImageException(this.message);

  final String message;

  @override
  String toString() => 'UnreadableImageException: $message';
}

/// Re-encodes uploaded images (images of documents, avatars, board
/// screenshots) as WebP with Pixtronaut (specs/12 §1.1
/// *Image optimization*): by the hosted service in production (signed URLs
/// of the Serverpod Cloud bucket, the `pixtronautAccessKey` password), by
/// libvips in this process in development and tests
/// (`Pixtronaut.fromServerpod`). EXIF rotation is applied, colours become
/// sRGB and all metadata (EXIF incl. GPS) is stripped; animated GIFs and
/// WebPs stay animated; images are never upscaled.
///
/// The WebP is written to `<dir>/web/<name>.webp` beside the source; the
/// caller points the [StoredFile] at it and deletes the source.
abstract final class ImageOptimizer {
  /// The types Pixtronaut reads (all image types of documents,
  /// [FileService.imageMimeTypes]).
  static const sourceMimeTypes = {
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  };

  /// Longest side of [ImageProfile.content].
  static const maxContentSide = 2048;

  /// Size of [ImageProfile.cover] (the Open Graph image size).
  static const coverWidth = 1200;
  static const coverHeight = 630;

  /// Side of [ImageProfile.avatar] (avatars are shown at ≤ 56 px).
  static const avatarSide = 256;

  static const _keyTemplate = '{dir}/web/{name}.webp';

  /// Writes one variant of the image at [sourcePath] (tests may replace it).
  static Future<px.VariantResult> Function(
    Session session, {
    required String storageId,
    required String sourcePath,
    required px.Variant variant,
  })
  transform = pixtronautTransform;

  static px.Pixtronaut? _pixtronaut;

  static bool supports(String mimeType) => sourceMimeTypes.contains(mimeType);

  /// The variant of [profile] for a [mimeType] source: lossless for PNGs
  /// and GIFs (screenshots, diagrams and flat art, whose text lossy WebP
  /// blurs), quality 80 for photos.
  static px.Variant variantFor(ImageProfile profile, String mimeType) {
    final webp = mimeType == 'image/png' || mimeType == 'image/gif'
        ? const px.WebpOptions(lossless: true)
        : const px.WebpOptions();
    return switch (profile) {
      ImageProfile.content => px.FitVariant(
        name: 'content',
        width: maxContentSide,
        height: maxContentSide,
        webp: webp,
      ),
      ImageProfile.cover => px.CoverVariant(
        name: 'cover',
        width: coverWidth,
        height: coverHeight,
        crop: const px.Crop.attention(),
        webp: webp,
      ),
      ImageProfile.avatar => px.CoverVariant(
        name: 'avatar',
        width: avatarSide,
        height: avatarSide,
        crop: const px.Crop.attention(),
        webp: webp,
      ),
    };
  }

  /// Re-encodes the image at [path] in [storageId] for [profile]. Null
  /// when the type isn't supported or Pixtronaut failed (quota, outage,
  /// configuration): the image then stays as it is, and the failure is
  /// logged as an error. Throws [UnreadableImageException] when the source
  /// is not a readable image.
  static Future<OptimizedImage?> optimize(
    Session session, {
    required String storageId,
    required String path,
    required String mimeType,
    required ImageProfile profile,
  }) async {
    if (!supports(mimeType)) return null;
    try {
      final r = await transform(
        session,
        storageId: storageId,
        sourcePath: path,
        variant: variantFor(profile, mimeType),
      );
      return (
        path: r.path,
        fileName: r.path.split('/').last,
        sizeBytes: r.bytes,
      );
    } on px.SourceException catch (e) {
      throw UnreadableImageException('${e.code}: ${e.message}');
    } on Object catch (e, st) {
      session.log(
        'Optimizing the image $path failed; it is kept as uploaded: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// [transform] with Pixtronaut.
  static Future<px.VariantResult> pixtronautTransform(
    Session session, {
    required String storageId,
    required String sourcePath,
    required px.Variant variant,
  }) async {
    final pixtronaut = _pixtronaut ??= px.Pixtronaut.fromServerpod(
      session.serverpod,
    );
    final result = await pixtronaut.process(
      session: session,
      storageId: storageId,
      sourcePath: sourcePath,
      variants: [variant],
      keyTemplate: _keyTemplate,
    );
    return result.variants.single;
  }
}
