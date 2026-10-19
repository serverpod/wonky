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

enum DriveItemKind implements _is.SerializableModel {
  folder,
  document,
  spreadsheet,

  /// (v2) A Wonky Slides deck: one RevLog file (specs/17).
  presentation,

  /// (v2) An uploaded file (Drive 02 §1): bytes in a `driveFile` StoredFile.
  file;

  static DriveItemKind fromJson(String name) {
    switch (name) {
      case 'folder':
        return DriveItemKind.folder;
      case 'document':
        return DriveItemKind.document;
      case 'spreadsheet':
        return DriveItemKind.spreadsheet;
      case 'presentation':
        return DriveItemKind.presentation;
      case 'file':
        return DriveItemKind.file;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "DriveItemKind"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
