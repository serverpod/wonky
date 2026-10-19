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
import 'dart:typed_data' as _idt;
import 'package:serverpod/serverpod.dart' as _is;
import '../../../platform/common/actor_kind.dart' as _iqucl2d4;

/// A committed op as clients see it (RevLog spec 04 §2.3).
abstract class RevOpView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RevOpView._({
    required this.revision,
    required this.clientOpId,
    this.payload,
    this.payloadGz,
    this.authorUuid,
    this.authorSessionId,
    required this.actorKind,
    required this.label,
    this.summaryJson,
    this.detailJson,
    required this.offline,
    this.groupId,
    required this.groupIndex,
    required this.groupLast,
    this.recordId,
    this.onBehalfOfSessionId,
    this.outcomeJson,
    required this.committedAt,
  });

  factory RevOpView({
    required int revision,
    required _is.UuidValue clientOpId,
    String? payload,
    _idt.ByteData? payloadGz,
    _is.UuidValue? authorUuid,
    String? authorSessionId,
    required _iqucl2d4.ActorKind actorKind,
    required String label,
    String? summaryJson,
    String? detailJson,
    required bool offline,
    String? groupId,
    required int groupIndex,
    required bool groupLast,
    _is.UuidValue? recordId,
    String? onBehalfOfSessionId,
    String? outcomeJson,
    required DateTime committedAt,
  }) = _RevOpViewImpl;

  factory RevOpView.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevOpView(
      revision: jsonSerialization['revision'] as int,
      clientOpId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientOpId'],
      ),
      payload: jsonSerialization['payload'] as String?,
      payloadGz: jsonSerialization['payloadGz'] == null
          ? null
          : _is.ByteDataJsonExtension.fromJson(jsonSerialization['payloadGz']),
      authorUuid: jsonSerialization['authorUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['authorUuid'],
            ),
      authorSessionId: jsonSerialization['authorSessionId'] as String?,
      actorKind: _iqucl2d4.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      label: jsonSerialization['label'] as String,
      summaryJson: jsonSerialization['summaryJson'] as String?,
      detailJson: jsonSerialization['detailJson'] as String?,
      offline: _is.BoolJsonExtension.fromJson(jsonSerialization['offline']),
      groupId: jsonSerialization['groupId'] as String?,
      groupIndex: jsonSerialization['groupIndex'] as int,
      groupLast: _is.BoolJsonExtension.fromJson(jsonSerialization['groupLast']),
      recordId: jsonSerialization['recordId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['recordId']),
      onBehalfOfSessionId: jsonSerialization['onBehalfOfSessionId'] as String?,
      outcomeJson: jsonSerialization['outcomeJson'] as String?,
      committedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['committedAt'],
      ),
    );
  }

  int revision;

  _is.UuidValue clientOpId;

  /// Codec JSON of the applied form without before.
  String? payload;

  _idt.ByteData? payloadGz;

  _is.UuidValue? authorUuid;

  String? authorSessionId;

  _iqucl2d4.ActorKind actorKind;

  String label;

  String? summaryJson;

  String? detailJson;

  bool offline;

  String? groupId;

  int groupIndex;

  bool groupLast;

  _is.UuidValue? recordId;

  String? onBehalfOfSessionId;

  /// Lets the author recover a lost ack's outcome.
  String? outcomeJson;

  DateTime committedAt;

  /// Returns a shallow copy of this [RevOpView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RevOpView copyWith({
    int? revision,
    _is.UuidValue? clientOpId,
    String? payload,
    _idt.ByteData? payloadGz,
    _is.UuidValue? authorUuid = const _is.$UndefinedUuidValue(),
    String? authorSessionId,
    _iqucl2d4.ActorKind? actorKind,
    String? label,
    String? summaryJson,
    String? detailJson,
    bool? offline,
    String? groupId,
    int? groupIndex,
    bool? groupLast,
    _is.UuidValue? recordId = const _is.$UndefinedUuidValue(),
    String? onBehalfOfSessionId,
    String? outcomeJson,
    DateTime? committedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevOpView',
      'revision': revision,
      'clientOpId': clientOpId.toJson(),
      if (payload != null) 'payload': payload,
      if (payloadGz != null) 'payloadGz': payloadGz?.toJson(),
      if (authorUuid != null) 'authorUuid': authorUuid?.toJson(),
      if (authorSessionId != null) 'authorSessionId': authorSessionId,
      'actorKind': actorKind.toJson(),
      'label': label,
      if (summaryJson != null) 'summaryJson': summaryJson,
      if (detailJson != null) 'detailJson': detailJson,
      'offline': offline,
      if (groupId != null) 'groupId': groupId,
      'groupIndex': groupIndex,
      'groupLast': groupLast,
      if (recordId != null) 'recordId': recordId?.toJson(),
      if (onBehalfOfSessionId != null)
        'onBehalfOfSessionId': onBehalfOfSessionId,
      if (outcomeJson != null) 'outcomeJson': outcomeJson,
      'committedAt': committedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RevOpView',
      'revision': revision,
      'clientOpId': clientOpId.toJson(),
      if (payload != null) 'payload': payload,
      if (payloadGz != null) 'payloadGz': payloadGz?.toJson(),
      if (authorUuid != null) 'authorUuid': authorUuid?.toJson(),
      if (authorSessionId != null) 'authorSessionId': authorSessionId,
      'actorKind': actorKind.toJson(),
      'label': label,
      if (summaryJson != null) 'summaryJson': summaryJson,
      if (detailJson != null) 'detailJson': detailJson,
      'offline': offline,
      if (groupId != null) 'groupId': groupId,
      'groupIndex': groupIndex,
      'groupLast': groupLast,
      if (recordId != null) 'recordId': recordId?.toJson(),
      if (onBehalfOfSessionId != null)
        'onBehalfOfSessionId': onBehalfOfSessionId,
      if (outcomeJson != null) 'outcomeJson': outcomeJson,
      'committedAt': committedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RevOpViewImpl extends RevOpView {
  _RevOpViewImpl({
    required int revision,
    required _is.UuidValue clientOpId,
    String? payload,
    _idt.ByteData? payloadGz,
    _is.UuidValue? authorUuid,
    String? authorSessionId,
    required _iqucl2d4.ActorKind actorKind,
    required String label,
    String? summaryJson,
    String? detailJson,
    required bool offline,
    String? groupId,
    required int groupIndex,
    required bool groupLast,
    _is.UuidValue? recordId,
    String? onBehalfOfSessionId,
    String? outcomeJson,
    required DateTime committedAt,
  }) : super._(
         revision: revision,
         clientOpId: clientOpId,
         payload: payload,
         payloadGz: payloadGz,
         authorUuid: authorUuid,
         authorSessionId: authorSessionId,
         actorKind: actorKind,
         label: label,
         summaryJson: summaryJson,
         detailJson: detailJson,
         offline: offline,
         groupId: groupId,
         groupIndex: groupIndex,
         groupLast: groupLast,
         recordId: recordId,
         onBehalfOfSessionId: onBehalfOfSessionId,
         outcomeJson: outcomeJson,
         committedAt: committedAt,
       );

  /// Returns a shallow copy of this [RevOpView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevOpView copyWith({
    int? revision,
    _is.UuidValue? clientOpId,
    Object? payload = _Undefined,
    Object? payloadGz = _Undefined,
    _is.UuidValue? authorUuid = const _is.$UndefinedUuidValue(),
    Object? authorSessionId = _Undefined,
    _iqucl2d4.ActorKind? actorKind,
    String? label,
    Object? summaryJson = _Undefined,
    Object? detailJson = _Undefined,
    bool? offline,
    Object? groupId = _Undefined,
    int? groupIndex,
    bool? groupLast,
    _is.UuidValue? recordId = const _is.$UndefinedUuidValue(),
    Object? onBehalfOfSessionId = _Undefined,
    Object? outcomeJson = _Undefined,
    DateTime? committedAt,
  }) {
    return RevOpView(
      revision: revision ?? this.revision,
      clientOpId: clientOpId ?? this.clientOpId,
      payload: payload is String? ? payload : this.payload,
      payloadGz: payloadGz is _idt.ByteData?
          ? payloadGz
          : this.payloadGz?.clone(),
      authorUuid: authorUuid is _is.UndefinedSentinel
          ? this.authorUuid
          : authorUuid,
      authorSessionId: authorSessionId is String?
          ? authorSessionId
          : this.authorSessionId,
      actorKind: actorKind ?? this.actorKind,
      label: label ?? this.label,
      summaryJson: summaryJson is String? ? summaryJson : this.summaryJson,
      detailJson: detailJson is String? ? detailJson : this.detailJson,
      offline: offline ?? this.offline,
      groupId: groupId is String? ? groupId : this.groupId,
      groupIndex: groupIndex ?? this.groupIndex,
      groupLast: groupLast ?? this.groupLast,
      recordId: recordId is _is.UndefinedSentinel ? this.recordId : recordId,
      onBehalfOfSessionId: onBehalfOfSessionId is String?
          ? onBehalfOfSessionId
          : this.onBehalfOfSessionId,
      outcomeJson: outcomeJson is String? ? outcomeJson : this.outcomeJson,
      committedAt: committedAt ?? this.committedAt,
    );
  }
}
