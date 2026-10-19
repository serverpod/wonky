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

abstract class RevPing extends _i26f4ubs.RevClientMessage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevPing._({required this.t});

  factory RevPing({required int t}) = _RevPingImpl;

  factory RevPing.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevPing(t: jsonSerialization['t'] as int);
  }

  int t;

  /// Returns a shallow copy of this [RevPing]
  /// with some or all fields replaced by the given arguments.
  @override
  @_is.useResult
  RevPing copyWith({int? t});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevPing',
      't': t,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevPing',
      't': t,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RevPingImpl extends RevPing {
  _RevPingImpl({required int t}) : super._(t: t);

  /// Returns a shallow copy of this [RevPing]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevPing copyWith({int? t}) {
    return RevPing(t: t ?? this.t);
  }
}
