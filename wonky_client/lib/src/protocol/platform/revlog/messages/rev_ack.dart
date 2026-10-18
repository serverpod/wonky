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

/// The op was committed as [revision] (RevLog spec 04 §2.2).
abstract class RevAck extends _i26f4ubs.RevServerMessage
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  RevAck._({
    required this.clientOpId,
    required this.revision,
    required this.duplicate,
    this.applied,
    this.appliedGz,
    this.outcome,
  });

  factory RevAck({
    required _isc.UuidValue clientOpId,
    required int revision,
    required bool duplicate,
    String? applied,
    _idt.ByteData? appliedGz,
    String? outcome,
  }) = _RevAckImpl;

  factory RevAck.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevAck(
      clientOpId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientOpId'],
      ),
      revision: jsonSerialization['revision'] as int,
      duplicate: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['duplicate'],
      ),
      applied: jsonSerialization['applied'] as String?,
      appliedGz: jsonSerialization['appliedGz'] == null
          ? null
          : _isc.ByteDataJsonExtension.fromJson(jsonSerialization['appliedGz']),
      outcome: jsonSerialization['outcome'] as String?,
    );
  }

  _isc.UuidValue clientOpId;

  int revision;

  bool duplicate;

  /// The applied form (no before) when it differs from the submitted
  /// changes (exactly one of applied/appliedGz, or neither).
  String? applied;

  _idt.ByteData? appliedGz;

  /// Outcome JSON for the UI; absent when empty.
  String? outcome;

  /// Returns a shallow copy of this [RevAck]
  /// with some or all fields replaced by the given arguments.
  @override
  @_isc.useResult
  RevAck copyWith({
    _isc.UuidValue? clientOpId,
    int? revision,
    bool? duplicate,
    String? applied,
    _idt.ByteData? appliedGz,
    String? outcome,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevAck',
      'clientOpId': clientOpId.toJson(),
      'revision': revision,
      'duplicate': duplicate,
      if (applied != null) 'applied': applied,
      if (appliedGz != null) 'appliedGz': appliedGz?.toJson(),
      if (outcome != null) 'outcome': outcome,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevAck',
      'clientOpId': clientOpId.toJson(),
      'revision': revision,
      'duplicate': duplicate,
      if (applied != null) 'applied': applied,
      if (appliedGz != null) 'appliedGz': appliedGz?.toJson(),
      if (outcome != null) 'outcome': outcome,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _RevAckImpl extends RevAck {
  _RevAckImpl({
    required _isc.UuidValue clientOpId,
    required int revision,
    required bool duplicate,
    String? applied,
    _idt.ByteData? appliedGz,
    String? outcome,
  }) : super._(
         clientOpId: clientOpId,
         revision: revision,
         duplicate: duplicate,
         applied: applied,
         appliedGz: appliedGz,
         outcome: outcome,
       );

  /// Returns a shallow copy of this [RevAck]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  RevAck copyWith({
    _isc.UuidValue? clientOpId,
    int? revision,
    bool? duplicate,
    Object? applied = _Undefined,
    Object? appliedGz = _Undefined,
    Object? outcome = _Undefined,
  }) {
    return RevAck(
      clientOpId: clientOpId ?? this.clientOpId,
      revision: revision ?? this.revision,
      duplicate: duplicate ?? this.duplicate,
      applied: applied is String? ? applied : this.applied,
      appliedGz: appliedGz is _idt.ByteData?
          ? appliedGz
          : this.appliedGz?.clone(),
      outcome: outcome is String? ? outcome : this.outcome,
    );
  }
}
