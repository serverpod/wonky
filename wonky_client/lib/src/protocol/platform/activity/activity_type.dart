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

enum ActivityType implements _isc.SerializableModel {
  created,
  renamed,
  moved,
  edited,
  commented,
  shared,
  unshared,
  restoredVersion,
  trashed,
  restored,
  exported,

  /// (v2) A file was uploaded (Drive 02 §3.3).
  uploaded,

  /// (M14) Submitted to, withdrawn from or disconnected from a publication,
  /// or the publication changed the status (specs/18 §6; summary
  /// {publication, action, status?}).
  submission;

  static ActivityType fromJson(String name) {
    switch (name) {
      case 'created':
        return ActivityType.created;
      case 'renamed':
        return ActivityType.renamed;
      case 'moved':
        return ActivityType.moved;
      case 'edited':
        return ActivityType.edited;
      case 'commented':
        return ActivityType.commented;
      case 'shared':
        return ActivityType.shared;
      case 'unshared':
        return ActivityType.unshared;
      case 'restoredVersion':
        return ActivityType.restoredVersion;
      case 'trashed':
        return ActivityType.trashed;
      case 'restored':
        return ActivityType.restored;
      case 'exported':
        return ActivityType.exported;
      case 'uploaded':
        return ActivityType.uploaded;
      case 'submission':
        return ActivityType.submission;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ActivityType"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
