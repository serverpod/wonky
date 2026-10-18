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
import '../../../platform/common/access_role.dart' as _iadb9hqu;

/// Head revision, role and stats of a file (RevLog spec 04 §2.3).
abstract class RevFileInfo
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevFileInfo._({
    required this.fileUuid,
    required this.revision,
    required this.role,
    required this.schemaHash,
    required this.stats,
  });

  factory RevFileInfo({
    required _is.UuidValue fileUuid,
    required int revision,
    required _iadb9hqu.AccessRole role,
    required String schemaHash,
    required String stats,
  }) = _RevFileInfoImpl;

  factory RevFileInfo.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevFileInfo(
      fileUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['fileUuid'],
      ),
      revision: jsonSerialization['revision'] as int,
      role: _iadb9hqu.AccessRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      schemaHash: jsonSerialization['schemaHash'] as String,
      stats: jsonSerialization['stats'] as String,
    );
  }

  _is.UuidValue fileUuid;

  int revision;

  _iadb9hqu.AccessRole role;

  String schemaHash;

  String stats;

  /// Returns a shallow copy of this [RevFileInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RevFileInfo copyWith({
    _is.UuidValue? fileUuid,
    int? revision,
    _iadb9hqu.AccessRole? role,
    String? schemaHash,
    String? stats,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevFileInfo',
      'fileUuid': fileUuid.toJson(),
      'revision': revision,
      'role': role.toJson(),
      'schemaHash': schemaHash,
      'stats': stats,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevFileInfo',
      'fileUuid': fileUuid.toJson(),
      'revision': revision,
      'role': role.toJson(),
      'schemaHash': schemaHash,
      'stats': stats,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RevFileInfoImpl extends RevFileInfo {
  _RevFileInfoImpl({
    required _is.UuidValue fileUuid,
    required int revision,
    required _iadb9hqu.AccessRole role,
    required String schemaHash,
    required String stats,
  }) : super._(
         fileUuid: fileUuid,
         revision: revision,
         role: role,
         schemaHash: schemaHash,
         stats: stats,
       );

  /// Returns a shallow copy of this [RevFileInfo]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevFileInfo copyWith({
    _is.UuidValue? fileUuid,
    int? revision,
    _iadb9hqu.AccessRole? role,
    String? schemaHash,
    String? stats,
  }) {
    return RevFileInfo(
      fileUuid: fileUuid ?? this.fileUuid,
      revision: revision ?? this.revision,
      role: role ?? this.role,
      schemaHash: schemaHash ?? this.schemaHash,
      stats: stats ?? this.stats,
    );
  }
}
