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

/// An op committed by another connection (RevLog spec 04 §2.2).
abstract class RevRemoteOp extends _i26f4ubs.RevServerMessage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevRemoteOp._({required this.op});

  factory RevRemoteOp({required _irs0bkik.RevOpView op}) = _RevRemoteOpImpl;

  factory RevRemoteOp.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevRemoteOp(
      op: _il4umwa0.Protocol().deserialize<_irs0bkik.RevOpView>(
        jsonSerialization['op'],
      ),
    );
  }

  _irs0bkik.RevOpView op;

  /// Returns a shallow copy of this [RevRemoteOp]
  /// with some or all fields replaced by the given arguments.
  @override
  @_is.useResult
  RevRemoteOp copyWith({_irs0bkik.RevOpView? op});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevRemoteOp',
      'op': op.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevRemoteOp',
      'op': op.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RevRemoteOpImpl extends RevRemoteOp {
  _RevRemoteOpImpl({required _irs0bkik.RevOpView op}) : super._(op: op);

  /// Returns a shallow copy of this [RevRemoteOp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevRemoteOp copyWith({_irs0bkik.RevOpView? op}) {
    return RevRemoteOp(op: op ?? this.op.copyWith());
  }
}
