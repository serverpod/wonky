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
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/presence/participant.dart' as _i4jhhr2a;

/// Internal payload on `rev:<fileUuid>` (RevLog spec 05 §5).
abstract class RevBusMessage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevBusMessage._({
    required this.type,
    this.revision,
    this.opJson,
    this.originSessionId,
    this.userId,
    this.participant,
    this.sessionId,
    this.headRevision,
  });

  factory RevBusMessage({
    required String type,
    int? revision,
    String? opJson,
    String? originSessionId,
    int? userId,
    _i4jhhr2a.Participant? participant,
    String? sessionId,
    int? headRevision,
  }) = _RevBusMessageImpl;

  factory RevBusMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevBusMessage(
      type: jsonSerialization['type'] as String,
      revision: jsonSerialization['revision'] as int?,
      opJson: jsonSerialization['opJson'] as String?,
      originSessionId: jsonSerialization['originSessionId'] as String?,
      userId: jsonSerialization['userId'] as int?,
      participant: jsonSerialization['participant'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_i4jhhr2a.Participant>(
              jsonSerialization['participant'],
            ),
      sessionId: jsonSerialization['sessionId'] as String?,
      headRevision: jsonSerialization['headRevision'] as int?,
    );
  }

  /// op, role, hello, here, beat, left, purged.
  String type;

  int? revision;

  /// The RevOpView JSON when its payload is ≤ 64 KiB.
  String? opJson;

  String? originSessionId;

  /// Role re-checks: the affected user (null = everyone).
  int? userId;

  _i4jhhr2a.Participant? participant;

  /// `here`: the session the reply is for.
  String? sessionId;

  int? headRevision;

  /// Returns a shallow copy of this [RevBusMessage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RevBusMessage copyWith({
    String? type,
    int? revision,
    String? opJson,
    String? originSessionId,
    int? userId,
    _i4jhhr2a.Participant? participant =
        const _UndefinedRevBusMessage$participant(),
    String? sessionId,
    int? headRevision,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevBusMessage',
      'type': type,
      if (revision != null) 'revision': revision,
      if (opJson != null) 'opJson': opJson,
      if (originSessionId != null) 'originSessionId': originSessionId,
      if (userId != null) 'userId': userId,
      if (participant != null) 'participant': participant?.toJson(),
      if (sessionId != null) 'sessionId': sessionId,
      if (headRevision != null) 'headRevision': headRevision,
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

class _UndefinedRevBusMessage$participant extends _is.UndefinedSentinel
    implements _i4jhhr2a.Participant {
  const _UndefinedRevBusMessage$participant();
}

class _RevBusMessageImpl extends RevBusMessage {
  _RevBusMessageImpl({
    required String type,
    int? revision,
    String? opJson,
    String? originSessionId,
    int? userId,
    _i4jhhr2a.Participant? participant,
    String? sessionId,
    int? headRevision,
  }) : super._(
         type: type,
         revision: revision,
         opJson: opJson,
         originSessionId: originSessionId,
         userId: userId,
         participant: participant,
         sessionId: sessionId,
         headRevision: headRevision,
       );

  /// Returns a shallow copy of this [RevBusMessage]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevBusMessage copyWith({
    String? type,
    Object? revision = _Undefined,
    Object? opJson = _Undefined,
    Object? originSessionId = _Undefined,
    Object? userId = _Undefined,
    _i4jhhr2a.Participant? participant =
        const _UndefinedRevBusMessage$participant(),
    Object? sessionId = _Undefined,
    Object? headRevision = _Undefined,
  }) {
    return RevBusMessage(
      type: type ?? this.type,
      revision: revision is int? ? revision : this.revision,
      opJson: opJson is String? ? opJson : this.opJson,
      originSessionId: originSessionId is String?
          ? originSessionId
          : this.originSessionId,
      userId: userId is int? ? userId : this.userId,
      participant: participant is _is.UndefinedSentinel
          ? this.participant?.copyWith()
          : participant,
      sessionId: sessionId is String? ? sessionId : this.sessionId,
      headRevision: headRevision is int? ? headRevision : this.headRevision,
    );
  }
}
