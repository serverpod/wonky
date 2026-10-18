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
import 'package:serverpod/serverpod.dart' as _is;

/// Slide size preset of a deck (Slides 02 §3.11, 05 §7). `custom` = any
/// other size within the limits of 02 §13.
enum SlideSizePreset implements _is.SerializableModel {
  widescreen16x9,
  standard4x3,
  wide16x10,
  square,
  portrait9x16,
  a4,
  letter,
  custom;

  static SlideSizePreset fromJson(String name) {
    switch (name) {
      case 'widescreen16x9':
        return SlideSizePreset.widescreen16x9;
      case 'standard4x3':
        return SlideSizePreset.standard4x3;
      case 'wide16x10':
        return SlideSizePreset.wide16x10;
      case 'square':
        return SlideSizePreset.square;
      case 'portrait9x16':
        return SlideSizePreset.portrait9x16;
      case 'a4':
        return SlideSizePreset.a4;
      case 'letter':
        return SlideSizePreset.letter;
      case 'custom':
        return SlideSizePreset.custom;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "SlideSizePreset"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
