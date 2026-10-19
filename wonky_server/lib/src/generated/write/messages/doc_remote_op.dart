/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

part of 'doc_server_message.dart';

/// Someone else's op, transformed to apply on revision - 1.
abstract class DocRemoteOp extends _iototaiw.DocServerMessage
    implements _is.SerializableModel, _is.ProtocolSerialization {
  DocRemoteOp._({
    required this.revision,
    required this.deltaJson,
    this.authorId,
    this.authorUuid,
    this.authorSessionId,
    required this.actorKind,
    required this.kind,
    this.onBehalfOfSessionId,
    this.groupId,
  });

  factory DocRemoteOp({
    required int revision,
    required String deltaJson,
    int? authorId,
    _is.UuidValue? authorUuid,
    String? authorSessionId,
    required _ipbpecg8.ActorKind actorKind,
    required _idnphvog.DocumentOpKind kind,
    String? onBehalfOfSessionId,
    String? groupId,
  }) = _DocRemoteOpImpl;

  factory DocRemoteOp.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocRemoteOp(
      revision: jsonSerialization['revision'] as int,
      deltaJson: jsonSerialization['deltaJson'] as String,
      authorId: jsonSerialization['authorId'] as int?,
      authorUuid: jsonSerialization['authorUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['authorUuid'],
            ),
      authorSessionId: jsonSerialization['authorSessionId'] as String?,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      kind: _idnphvog.DocumentOpKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      onBehalfOfSessionId: jsonSerialization['onBehalfOfSessionId'] as String?,
      groupId: jsonSerialization['groupId'] as String?,
    );
  }

  int revision;

  String deltaJson;

  int? authorId;

  _is.UuidValue? authorUuid;

  String? authorSessionId;

  _ipbpecg8.ActorKind actorKind;

  _idnphvog.DocumentOpKind kind;

  String? onBehalfOfSessionId;

  String? groupId;

  /// Returns a shallow copy of this [DocRemoteOp]
  /// with some or all fields replaced by the given arguments.
  @override
  @_is.useResult
  DocRemoteOp copyWith({
    int? revision,
    String? deltaJson,
    int? authorId,
    _is.UuidValue? authorUuid = const _is.$UndefinedUuidValue(),
    String? authorSessionId,
    _ipbpecg8.ActorKind? actorKind,
    _idnphvog.DocumentOpKind? kind,
    String? onBehalfOfSessionId,
    String? groupId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocRemoteOp',
      'revision': revision,
      'deltaJson': deltaJson,
      if (authorId != null) 'authorId': authorId,
      if (authorUuid != null) 'authorUuid': authorUuid?.toJson(),
      if (authorSessionId != null) 'authorSessionId': authorSessionId,
      'actorKind': actorKind.toJson(),
      'kind': kind.toJson(),
      if (onBehalfOfSessionId != null)
        'onBehalfOfSessionId': onBehalfOfSessionId,
      if (groupId != null) 'groupId': groupId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocRemoteOp',
      'revision': revision,
      'deltaJson': deltaJson,
      if (authorId != null) 'authorId': authorId,
      if (authorUuid != null) 'authorUuid': authorUuid?.toJson(),
      if (authorSessionId != null) 'authorSessionId': authorSessionId,
      'actorKind': actorKind.toJson(),
      'kind': kind.toJson(),
      if (onBehalfOfSessionId != null)
        'onBehalfOfSessionId': onBehalfOfSessionId,
      if (groupId != null) 'groupId': groupId,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _DocRemoteOpImpl extends DocRemoteOp {
  _DocRemoteOpImpl({
    required int revision,
    required String deltaJson,
    int? authorId,
    _is.UuidValue? authorUuid,
    String? authorSessionId,
    required _ipbpecg8.ActorKind actorKind,
    required _idnphvog.DocumentOpKind kind,
    String? onBehalfOfSessionId,
    String? groupId,
  }) : super._(
         revision: revision,
         deltaJson: deltaJson,
         authorId: authorId,
         authorUuid: authorUuid,
         authorSessionId: authorSessionId,
         actorKind: actorKind,
         kind: kind,
         onBehalfOfSessionId: onBehalfOfSessionId,
         groupId: groupId,
       );

  /// Returns a shallow copy of this [DocRemoteOp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocRemoteOp copyWith({
    int? revision,
    String? deltaJson,
    Object? authorId = _Undefined,
    _is.UuidValue? authorUuid = const _is.$UndefinedUuidValue(),
    Object? authorSessionId = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    _idnphvog.DocumentOpKind? kind,
    Object? onBehalfOfSessionId = _Undefined,
    Object? groupId = _Undefined,
  }) {
    return DocRemoteOp(
      revision: revision ?? this.revision,
      deltaJson: deltaJson ?? this.deltaJson,
      authorId: authorId is int? ? authorId : this.authorId,
      authorUuid: authorUuid is _is.UndefinedSentinel
          ? this.authorUuid
          : authorUuid,
      authorSessionId: authorSessionId is String?
          ? authorSessionId
          : this.authorSessionId,
      actorKind: actorKind ?? this.actorKind,
      kind: kind ?? this.kind,
      onBehalfOfSessionId: onBehalfOfSessionId is String?
          ? onBehalfOfSessionId
          : this.onBehalfOfSessionId,
      groupId: groupId is String? ? groupId : this.groupId,
    );
  }
}
