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

/// What starts an animation step (Slides 02 §3.11, 06 §4.1). Append-only.
/// `onElementClick` (S-2, 06 A-06-2) is reserved for interactive decks (P2):
/// clients of S-2 and later read it, the timeline skips such builds and the
/// planner refuses to write it until the feature exists.
enum BuildTrigger implements _isc.SerializableModel {
  onClick,
  withPrevious,
  afterPrevious,
  onElementClick;

  static BuildTrigger fromJson(String name) {
    switch (name) {
      case 'onClick':
        return BuildTrigger.onClick;
      case 'withPrevious':
        return BuildTrigger.withPrevious;
      case 'afterPrevious':
        return BuildTrigger.afterPrevious;
      case 'onElementClick':
        return BuildTrigger.onElementClick;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "BuildTrigger"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
