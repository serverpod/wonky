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

abstract class ShareEmailFutureCallInviteModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ShareEmailFutureCallInviteModel._({
    required this.permissionId,
    required this.message,
  });

  factory ShareEmailFutureCallInviteModel({
    required int permissionId,
    required String? message,
  }) = _ShareEmailFutureCallInviteModelImpl;

  factory ShareEmailFutureCallInviteModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ShareEmailFutureCallInviteModel(
      permissionId: jsonSerialization['permissionId'] as int,
      message: jsonSerialization['message'] as String?,
    );
  }

  int permissionId;

  String? message;

  /// Returns a shallow copy of this [ShareEmailFutureCallInviteModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ShareEmailFutureCallInviteModel copyWith({
    int? permissionId,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ShareEmailFutureCallInviteModel',
      'permissionId': permissionId,
      if (message != null) 'message': message,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ShareEmailFutureCallInviteModelImpl
    extends ShareEmailFutureCallInviteModel {
  _ShareEmailFutureCallInviteModelImpl({
    required int permissionId,
    required String? message,
  }) : super._(
         permissionId: permissionId,
         message: message,
       );

  /// Returns a shallow copy of this [ShareEmailFutureCallInviteModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ShareEmailFutureCallInviteModel copyWith({
    int? permissionId,
    Object? message = _Undefined,
  }) {
    return ShareEmailFutureCallInviteModel(
      permissionId: permissionId ?? this.permissionId,
      message: message is String? ? message : this.message,
    );
  }
}
