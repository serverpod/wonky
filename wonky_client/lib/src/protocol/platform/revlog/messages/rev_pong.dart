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

abstract class RevPong extends _i26f4ubs.RevServerMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RevPong._({
    required this.t,
    required this.headRevision,
  });

  factory RevPong({
    required int t,
    required int headRevision,
  }) = _RevPongImpl;

  factory RevPong.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevPong(
      t: jsonSerialization['t'] as int,
      headRevision: jsonSerialization['headRevision'] as int,
    );
  }

  int t;

  int headRevision;

  /// Returns a shallow copy of this [RevPong]
  /// with some or all fields replaced by the given arguments.
  @override
  @_isc.useResult
  RevPong copyWith({
    int? t,
    int? headRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevPong',
      't': t,
      'headRevision': headRevision,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevPong',
      't': t,
      'headRevision': headRevision,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _RevPongImpl extends RevPong {
  _RevPongImpl({
    required int t,
    required int headRevision,
  }) : super._(
         t: t,
         headRevision: headRevision,
       );

  /// Returns a shallow copy of this [RevPong]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RevPong copyWith({
    int? t,
    int? headRevision,
  }) {
    return RevPong(
      t: t ?? this.t,
      headRevision: headRevision ?? this.headRevision,
    );
  }
}
