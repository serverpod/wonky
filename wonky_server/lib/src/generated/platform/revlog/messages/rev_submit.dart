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

/// One op (RevLog spec 03 §2), sent once it is durable in the outbox.
abstract class RevSubmit extends _i26f4ubs.RevClientMessage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevSubmit._({
    required this.clientOpId,
    required this.baseRevision,
    this.payload,
    this.payloadGz,
    required this.label,
    required this.actorKind,
    this.groupId,
    required this.groupIndex,
    required this.groupLast,
    required this.offline,
    required this.createdAt,
  });

  factory RevSubmit({
    required _is.UuidValue clientOpId,
    required int baseRevision,
    String? payload,
    _idt.ByteData? payloadGz,
    required String label,
    required _ie1mzgmy.ActorKind actorKind,
    String? groupId,
    required int groupIndex,
    required bool groupLast,
    required bool offline,
    required DateTime createdAt,
  }) = _RevSubmitImpl;

  factory RevSubmit.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevSubmit(
      clientOpId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientOpId'],
      ),
      baseRevision: jsonSerialization['baseRevision'] as int,
      payload: jsonSerialization['payload'] as String?,
      payloadGz: jsonSerialization['payloadGz'] == null
          ? null
          : _is.ByteDataJsonExtension.fromJson(jsonSerialization['payloadGz']),
      label: jsonSerialization['label'] as String,
      actorKind: _ie1mzgmy.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      groupId: jsonSerialization['groupId'] as String?,
      groupIndex: jsonSerialization['groupIndex'] as int,
      groupLast: _is.BoolJsonExtension.fromJson(jsonSerialization['groupLast']),
      offline: _is.BoolJsonExtension.fromJson(jsonSerialization['offline']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// Idempotency key (the same on every resend).
  _is.UuidValue clientOpId;

  int baseRevision;

  /// Codec JSON incl. "sum"/"det" (exactly one of payload/payloadGz).
  String? payload;

  _idt.ByteData? payloadGz;

  String label;

  _ie1mzgmy.ActorKind actorKind;

  String? groupId;

  int groupIndex;

  bool groupLast;

  bool offline;

  /// Client clock, display only.
  DateTime createdAt;

  /// Returns a shallow copy of this [RevSubmit]
  /// with some or all fields replaced by the given arguments.
  @override
  @_is.useResult
  RevSubmit copyWith({
    _is.UuidValue? clientOpId,
    int? baseRevision,
    String? payload,
    _idt.ByteData? payloadGz,
    String? label,
    _ie1mzgmy.ActorKind? actorKind,
    String? groupId,
    int? groupIndex,
    bool? groupLast,
    bool? offline,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevSubmit',
      'clientOpId': clientOpId.toJson(),
      'baseRevision': baseRevision,
      if (payload != null) 'payload': payload,
      if (payloadGz != null) 'payloadGz': payloadGz?.toJson(),
      'label': label,
      'actorKind': actorKind.toJson(),
      if (groupId != null) 'groupId': groupId,
      'groupIndex': groupIndex,
      'groupLast': groupLast,
      'offline': offline,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevSubmit',
      'clientOpId': clientOpId.toJson(),
      'baseRevision': baseRevision,
      if (payload != null) 'payload': payload,
      if (payloadGz != null) 'payloadGz': payloadGz?.toJson(),
      'label': label,
      'actorKind': actorKind.toJson(),
      if (groupId != null) 'groupId': groupId,
      'groupIndex': groupIndex,
      'groupLast': groupLast,
      'offline': offline,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _RevSubmitImpl extends RevSubmit {
  _RevSubmitImpl({
    required _is.UuidValue clientOpId,
    required int baseRevision,
    String? payload,
    _idt.ByteData? payloadGz,
    required String label,
    required _ie1mzgmy.ActorKind actorKind,
    String? groupId,
    required int groupIndex,
    required bool groupLast,
    required bool offline,
    required DateTime createdAt,
  }) : super._(
         clientOpId: clientOpId,
         baseRevision: baseRevision,
         payload: payload,
         payloadGz: payloadGz,
         label: label,
         actorKind: actorKind,
         groupId: groupId,
         groupIndex: groupIndex,
         groupLast: groupLast,
         offline: offline,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [RevSubmit]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevSubmit copyWith({
    _is.UuidValue? clientOpId,
    int? baseRevision,
    Object? payload = _Undefined,
    Object? payloadGz = _Undefined,
    String? label,
    _ie1mzgmy.ActorKind? actorKind,
    Object? groupId = _Undefined,
    int? groupIndex,
    bool? groupLast,
    bool? offline,
    DateTime? createdAt,
  }) {
    return RevSubmit(
      clientOpId: clientOpId ?? this.clientOpId,
      baseRevision: baseRevision ?? this.baseRevision,
      payload: payload is String? ? payload : this.payload,
      payloadGz: payloadGz is _idt.ByteData?
          ? payloadGz
          : this.payloadGz?.clone(),
      label: label ?? this.label,
      actorKind: actorKind ?? this.actorKind,
      groupId: groupId is String? ? groupId : this.groupId,
      groupIndex: groupIndex ?? this.groupIndex,
      groupLast: groupLast ?? this.groupLast,
      offline: offline ?? this.offline,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
