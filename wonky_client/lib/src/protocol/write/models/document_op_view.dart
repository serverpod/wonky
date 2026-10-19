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
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;
import '../../write/models/document_op_kind.dart' as _iymqng84;

abstract class DocumentOpView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DocumentOpView._({
    required this.revision,
    required this.deltaJson,
    required this.clientOpId,
    this.authorId,
    this.authorUuid,
    required this.actorKind,
    required this.kind,
    this.sessionId,
    required this.createdAt,
  });

  factory DocumentOpView({
    required int revision,
    required String deltaJson,
    required _isc.UuidValue clientOpId,
    int? authorId,
    _isc.UuidValue? authorUuid,
    required _ipbpecg8.ActorKind actorKind,
    required _iymqng84.DocumentOpKind kind,
    String? sessionId,
    required DateTime createdAt,
  }) = _DocumentOpViewImpl;

  factory DocumentOpView.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentOpView(
      revision: jsonSerialization['revision'] as int,
      deltaJson: jsonSerialization['deltaJson'] as String,
      clientOpId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientOpId'],
      ),
      authorId: jsonSerialization['authorId'] as int?,
      authorUuid: jsonSerialization['authorUuid'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(
              jsonSerialization['authorUuid'],
            ),
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      kind: _iymqng84.DocumentOpKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      sessionId: jsonSerialization['sessionId'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int revision;

  String deltaJson;

  _isc.UuidValue clientOpId;

  int? authorId;

  _isc.UuidValue? authorUuid;

  _ipbpecg8.ActorKind actorKind;

  _iymqng84.DocumentOpKind kind;

  String? sessionId;

  DateTime createdAt;

  /// Returns a shallow copy of this [DocumentOpView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DocumentOpView copyWith({
    int? revision,
    String? deltaJson,
    _isc.UuidValue? clientOpId,
    int? authorId,
    _isc.UuidValue? authorUuid = const _isc.$UndefinedUuidValue(),
    _ipbpecg8.ActorKind? actorKind,
    _iymqng84.DocumentOpKind? kind,
    String? sessionId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentOpView',
      'revision': revision,
      'deltaJson': deltaJson,
      'clientOpId': clientOpId.toJson(),
      if (authorId != null) 'authorId': authorId,
      if (authorUuid != null) 'authorUuid': authorUuid?.toJson(),
      'actorKind': actorKind.toJson(),
      'kind': kind.toJson(),
      if (sessionId != null) 'sessionId': sessionId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentOpView',
      'revision': revision,
      'deltaJson': deltaJson,
      'clientOpId': clientOpId.toJson(),
      if (authorId != null) 'authorId': authorId,
      if (authorUuid != null) 'authorUuid': authorUuid?.toJson(),
      'actorKind': actorKind.toJson(),
      'kind': kind.toJson(),
      if (sessionId != null) 'sessionId': sessionId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentOpViewImpl extends DocumentOpView {
  _DocumentOpViewImpl({
    required int revision,
    required String deltaJson,
    required _isc.UuidValue clientOpId,
    int? authorId,
    _isc.UuidValue? authorUuid,
    required _ipbpecg8.ActorKind actorKind,
    required _iymqng84.DocumentOpKind kind,
    String? sessionId,
    required DateTime createdAt,
  }) : super._(
         revision: revision,
         deltaJson: deltaJson,
         clientOpId: clientOpId,
         authorId: authorId,
         authorUuid: authorUuid,
         actorKind: actorKind,
         kind: kind,
         sessionId: sessionId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DocumentOpView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DocumentOpView copyWith({
    int? revision,
    String? deltaJson,
    _isc.UuidValue? clientOpId,
    Object? authorId = _Undefined,
    _isc.UuidValue? authorUuid = const _isc.$UndefinedUuidValue(),
    _ipbpecg8.ActorKind? actorKind,
    _iymqng84.DocumentOpKind? kind,
    Object? sessionId = _Undefined,
    DateTime? createdAt,
  }) {
    return DocumentOpView(
      revision: revision ?? this.revision,
      deltaJson: deltaJson ?? this.deltaJson,
      clientOpId: clientOpId ?? this.clientOpId,
      authorId: authorId is int? ? authorId : this.authorId,
      authorUuid: authorUuid is _isc.UndefinedSentinel
          ? this.authorUuid
          : authorUuid,
      actorKind: actorKind ?? this.actorKind,
      kind: kind ?? this.kind,
      sessionId: sessionId is String? ? sessionId : this.sessionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
