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

abstract class ShareEmailFutureCallSharedModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  ShareEmailFutureCallSharedModel._({required this.notificationId});

  factory ShareEmailFutureCallSharedModel({required int notificationId}) =
      _ShareEmailFutureCallSharedModelImpl;

  factory ShareEmailFutureCallSharedModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ShareEmailFutureCallSharedModel(
      notificationId: jsonSerialization['notificationId'] as int,
    );
  }

  int notificationId;

  /// Returns a shallow copy of this [ShareEmailFutureCallSharedModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ShareEmailFutureCallSharedModel copyWith({int? notificationId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ShareEmailFutureCallSharedModel',
      'notificationId': notificationId,
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

class _ShareEmailFutureCallSharedModelImpl
    extends ShareEmailFutureCallSharedModel {
  _ShareEmailFutureCallSharedModelImpl({required int notificationId})
    : super._(notificationId: notificationId);

  /// Returns a shallow copy of this [ShareEmailFutureCallSharedModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ShareEmailFutureCallSharedModel copyWith({int? notificationId}) {
    return ShareEmailFutureCallSharedModel(
      notificationId: notificationId ?? this.notificationId,
    );
  }
}
