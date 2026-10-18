/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

part of 'rev_server_message.dart';

abstract class RevRoleChanged extends _i26f4ubs.RevServerMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RevRoleChanged._({required this.role});

  factory RevRoleChanged({required _iyf5alod.AccessRole role}) =
      _RevRoleChangedImpl;

  factory RevRoleChanged.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevRoleChanged(
      role: _iyf5alod.AccessRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
    );
  }

  _iyf5alod.AccessRole role;

  /// Returns a shallow copy of this [RevRoleChanged]
  /// with some or all fields replaced by the given arguments.
  @override
  @_isc.useResult
  RevRoleChanged copyWith({_iyf5alod.AccessRole? role});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevRoleChanged',
      'role': role.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevRoleChanged',
      'role': role.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _RevRoleChangedImpl extends RevRoleChanged {
  _RevRoleChangedImpl({required _iyf5alod.AccessRole role})
    : super._(role: role);

  /// Returns a shallow copy of this [RevRoleChanged]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RevRoleChanged copyWith({_iyf5alod.AccessRole? role}) {
    return RevRoleChanged(role: role ?? this.role);
  }
}
