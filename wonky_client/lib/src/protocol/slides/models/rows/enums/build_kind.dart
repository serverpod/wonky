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

/// Kind of an animation step (Slides 02 §3.11, 06 §2). Append-only (A-06-2).
enum BuildKind implements _isc.SerializableModel {
  buildIn,
  buildOut,
  emphasis,
  motion;

  static BuildKind fromJson(String name) {
    switch (name) {
      case 'buildIn':
        return BuildKind.buildIn;
      case 'buildOut':
        return BuildKind.buildOut;
      case 'emphasis':
        return BuildKind.emphasis;
      case 'motion':
        return BuildKind.motion;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "BuildKind"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
