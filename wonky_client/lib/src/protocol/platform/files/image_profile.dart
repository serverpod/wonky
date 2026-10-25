/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// How an uploaded image is re-encoded when its upload completes
/// (specs/12 §1.1 *Image optimization*): always WebP.
enum ImageProfile implements _isc.SerializableModel {
  /// Images in documents, over cells and on slides, and screenshots of
  /// Bugs & improvements posts: fit within 2048 × 2048 (never upscaled).
  content,

  /// A story's cover image (specs/18 §4.2): 1200 × 630, cropped to fill.
  cover,

  /// A profile picture: 256 × 256, cropped to fill.
  avatar;

  static ImageProfile fromJson(String name) {
    switch (name) {
      case 'content':
        return ImageProfile.content;
      case 'cover':
        return ImageProfile.cover;
      case 'avatar':
        return ImageProfile.avatar;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ImageProfile"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
