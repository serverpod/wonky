/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

part of 'rev_client_message.dart';

/// Gap fill: ops in [fromRevision, toRevision].
abstract class RevRequestOps extends _i26f4ubs.RevClientMessage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevRequestOps._({
    required this.fromRevision,
    required this.toRevision,
  });

  factory RevRequestOps({
    required int fromRevision,
    required int toRevision,
  }) = _RevRequestOpsImpl;

  factory RevRequestOps.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevRequestOps(
      fromRevision: jsonSerialization['fromRevision'] as int,
      toRevision: jsonSerialization['toRevision'] as int,
    );
  }

  int fromRevision;

  int toRevision;

  /// Returns a shallow copy of this [RevRequestOps]
  /// with some or all fields replaced by the given arguments.
  @override
  @_is.useResult
  RevRequestOps copyWith({
    int? fromRevision,
    int? toRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevRequestOps',
      'fromRevision': fromRevision,
      'toRevision': toRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevRequestOps',
      'fromRevision': fromRevision,
      'toRevision': toRevision,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RevRequestOpsImpl extends RevRequestOps {
  _RevRequestOpsImpl({
    required int fromRevision,
    required int toRevision,
  }) : super._(
         fromRevision: fromRevision,
         toRevision: toRevision,
       );

  /// Returns a shallow copy of this [RevRequestOps]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevRequestOps copyWith({
    int? fromRevision,
    int? toRevision,
  }) {
    return RevRequestOps(
      fromRevision: fromRevision ?? this.fromRevision,
      toRevision: toRevision ?? this.toRevision,
    );
  }
}
