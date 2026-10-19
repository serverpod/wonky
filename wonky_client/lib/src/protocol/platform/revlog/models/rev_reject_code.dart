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

/// Why an op was not committed (RevLog spec 04 §4).
enum RevRejectCode implements _isc.SerializableModel {
  /// Schema, type or limit violation, a foreign id, an immutable column.
  invalidChange,

  /// Op or message over the size limits.
  tooLarge,

  /// Cell cap, sheet count.
  limitExceeded,

  /// The op writes protected content the author may not edit.
  protectedRange,

  /// Role below Editor.
  forbiddenForRole,

  /// No access at all (session-level).
  forbidden,

  /// baseRevision is ahead of the server head.
  unknownBase,

  /// The payload's schema hash is not accepted.
  schemaMismatch,

  /// The file doesn't exist (yet).
  notFound,

  /// The file is trashed or being purged.
  fileReadOnly,

  /// Unexpected server error (retry with the same clientOpId).
  internal;

  static RevRejectCode fromJson(String name) {
    switch (name) {
      case 'invalidChange':
        return RevRejectCode.invalidChange;
      case 'tooLarge':
        return RevRejectCode.tooLarge;
      case 'limitExceeded':
        return RevRejectCode.limitExceeded;
      case 'protectedRange':
        return RevRejectCode.protectedRange;
      case 'forbiddenForRole':
        return RevRejectCode.forbiddenForRole;
      case 'forbidden':
        return RevRejectCode.forbidden;
      case 'unknownBase':
        return RevRejectCode.unknownBase;
      case 'schemaMismatch':
        return RevRejectCode.schemaMismatch;
      case 'notFound':
        return RevRejectCode.notFound;
      case 'fileReadOnly':
        return RevRejectCode.fileReadOnly;
      case 'internal':
        return RevRejectCode.internal;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "RevRejectCode"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
