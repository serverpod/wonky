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

/// One applied operation (Write 02 §3).
abstract class DocumentOp
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  DocumentOp._({
    this.id,
    required this.documentId,
    required this.revision,
    required this.clientOpId,
    this.authorId,
    required this.actorKind,
    this.sessionId,
    this.onBehalfOfSessionId,
    this.groupId,
    required this.kind,
    required this.baseRevision,
    required this.deltaJson,
    required this.inverseJson,
    required this.createdAt,
  });

  factory DocumentOp({
    int? id,
    required int documentId,
    required int revision,
    required _isc.UuidValue clientOpId,
    int? authorId,
    required _ipbpecg8.ActorKind actorKind,
    String? sessionId,
    String? onBehalfOfSessionId,
    String? groupId,
    required _iymqng84.DocumentOpKind kind,
    required int baseRevision,
    required String deltaJson,
    required String inverseJson,
    required DateTime createdAt,
  }) = _DocumentOpImpl;

  factory DocumentOp.fromJson(Map<String, dynamic> jsonSerialization) {
    return DocumentOp(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      revision: jsonSerialization['revision'] as int,
      clientOpId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientOpId'],
      ),
      authorId: jsonSerialization['authorId'] as int?,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      sessionId: jsonSerialization['sessionId'] as String?,
      onBehalfOfSessionId: jsonSerialization['onBehalfOfSessionId'] as String?,
      groupId: jsonSerialization['groupId'] as String?,
      kind: _iymqng84.DocumentOpKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      baseRevision: jsonSerialization['baseRevision'] as int,
      deltaJson: jsonSerialization['deltaJson'] as String,
      inverseJson: jsonSerialization['inverseJson'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int documentId;

  /// Head after applying this op (1-based).
  int revision;

  _isc.UuidValue clientOpId;

  int? authorId;

  _ipbpecg8.ActorKind actorKind;

  String? sessionId;

  /// The app session an assistant run acted for and the run (its ops are
  /// one undo step there, Write 09 §5.2); also on ops sent to fill a gap
  /// or after a reconnect.
  String? onBehalfOfSessionId;

  String? groupId;

  _iymqng84.DocumentOpKind kind;

  int baseRevision;

  /// The transformed op as applied.
  String deltaJson;

  /// Inverse against the pre-op document.
  String inverseJson;

  DateTime createdAt;

  /// Returns a shallow copy of this [DocumentOp]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  DocumentOp copyWith({
    int? id,
    int? documentId,
    int? revision,
    _isc.UuidValue? clientOpId,
    int? authorId,
    _ipbpecg8.ActorKind? actorKind,
    String? sessionId,
    String? onBehalfOfSessionId,
    String? groupId,
    _iymqng84.DocumentOpKind? kind,
    int? baseRevision,
    String? deltaJson,
    String? inverseJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DocumentOp',
      if (id != null) 'id': id,
      'documentId': documentId,
      'revision': revision,
      'clientOpId': clientOpId.toJson(),
      if (authorId != null) 'authorId': authorId,
      'actorKind': actorKind.toJson(),
      if (sessionId != null) 'sessionId': sessionId,
      if (onBehalfOfSessionId != null)
        'onBehalfOfSessionId': onBehalfOfSessionId,
      if (groupId != null) 'groupId': groupId,
      'kind': kind.toJson(),
      'baseRevision': baseRevision,
      'deltaJson': deltaJson,
      'inverseJson': inverseJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DocumentOp',
      if (id != null) 'id': id,
      'documentId': documentId,
      'revision': revision,
      'clientOpId': clientOpId.toJson(),
      if (authorId != null) 'authorId': authorId,
      'actorKind': actorKind.toJson(),
      if (sessionId != null) 'sessionId': sessionId,
      if (onBehalfOfSessionId != null)
        'onBehalfOfSessionId': onBehalfOfSessionId,
      if (groupId != null) 'groupId': groupId,
      'kind': kind.toJson(),
      'baseRevision': baseRevision,
      'deltaJson': deltaJson,
      'inverseJson': inverseJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentOpImpl extends DocumentOp {
  _DocumentOpImpl({
    int? id,
    required int documentId,
    required int revision,
    required _isc.UuidValue clientOpId,
    int? authorId,
    required _ipbpecg8.ActorKind actorKind,
    String? sessionId,
    String? onBehalfOfSessionId,
    String? groupId,
    required _iymqng84.DocumentOpKind kind,
    required int baseRevision,
    required String deltaJson,
    required String inverseJson,
    required DateTime createdAt,
  }) : super._(
         id: id,
         documentId: documentId,
         revision: revision,
         clientOpId: clientOpId,
         authorId: authorId,
         actorKind: actorKind,
         sessionId: sessionId,
         onBehalfOfSessionId: onBehalfOfSessionId,
         groupId: groupId,
         kind: kind,
         baseRevision: baseRevision,
         deltaJson: deltaJson,
         inverseJson: inverseJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DocumentOp]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  DocumentOp copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? revision,
    _isc.UuidValue? clientOpId,
    Object? authorId = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    Object? sessionId = _Undefined,
    Object? onBehalfOfSessionId = _Undefined,
    Object? groupId = _Undefined,
    _iymqng84.DocumentOpKind? kind,
    int? baseRevision,
    String? deltaJson,
    String? inverseJson,
    DateTime? createdAt,
  }) {
    return DocumentOp(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      revision: revision ?? this.revision,
      clientOpId: clientOpId ?? this.clientOpId,
      authorId: authorId is int? ? authorId : this.authorId,
      actorKind: actorKind ?? this.actorKind,
      sessionId: sessionId is String? ? sessionId : this.sessionId,
      onBehalfOfSessionId: onBehalfOfSessionId is String?
          ? onBehalfOfSessionId
          : this.onBehalfOfSessionId,
      groupId: groupId is String? ? groupId : this.groupId,
      kind: kind ?? this.kind,
      baseRevision: baseRevision ?? this.baseRevision,
      deltaJson: deltaJson ?? this.deltaJson,
      inverseJson: inverseJson ?? this.inverseJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
