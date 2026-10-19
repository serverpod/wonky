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

enum DocRejectCode implements _isc.SerializableModel {
  /// The base revision is older than the retained op log.
  rebaseTooOld,

  /// The op is malformed, does not apply, or the result violates the schema.
  invalidOp,

  /// The op shape is not allowed for the caller's role (Write 03 §5).
  forbiddenForRole,

  /// The document would exceed write.maxDocumentChars.
  tooLarge,

  /// The base revision is ahead of the server head.
  unknownBase,

  /// Unexpected server error: retry with the same clientOpId.
  internal;

  static DocRejectCode fromJson(String name) {
    switch (name) {
      case 'rebaseTooOld':
        return DocRejectCode.rebaseTooOld;
      case 'invalidOp':
        return DocRejectCode.invalidOp;
      case 'forbiddenForRole':
        return DocRejectCode.forbiddenForRole;
      case 'tooLarge':
        return DocRejectCode.tooLarge;
      case 'unknownBase':
        return DocRejectCode.unknownBase;
      case 'internal':
        return DocRejectCode.internal;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "DocRejectCode"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
