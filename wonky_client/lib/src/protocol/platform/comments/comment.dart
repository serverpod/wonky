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
import 'package:wonky_client/src/protocol/protocol.dart' as _i8pkqg1o;
import '../../platform/comments/comment_system_event.dart' as _ikzs0dm0;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;

abstract class Comment
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Comment._({
    this.id,
    required this.threadId,
    this.uuid,
    this.authorId,
    required this.authorKind,
    required this.body,
    required this.mentions,
    String? reactions,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.systemEvent,
    this.publicationId,
  }) : reactions = reactions ?? '{}';

  factory Comment({
    int? id,
    required int threadId,
    _isc.UuidValue? uuid,
    int? authorId,
    required _ipbpecg8.ActorKind authorKind,
    required String body,
    required List<int> mentions,
    String? reactions,
    required DateTime createdAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    _ikzs0dm0.CommentSystemEvent? systemEvent,
    int? publicationId,
  }) = _CommentImpl;

  factory Comment.fromJson(Map<String, dynamic> jsonSerialization) {
    return Comment(
      id: jsonSerialization['id'] as int?,
      threadId: jsonSerialization['threadId'] as int,
      uuid: jsonSerialization['uuid'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      authorId: jsonSerialization['authorId'] as int?,
      authorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['authorKind'] as String),
      ),
      body: jsonSerialization['body'] as String,
      mentions: _i8pkqg1o.Protocol().deserialize<List<int>>(
        jsonSerialization['mentions'],
      ),
      reactions: jsonSerialization['reactions'] as String?,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      editedAt: jsonSerialization['editedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['editedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      systemEvent: jsonSerialization['systemEvent'] == null
          ? null
          : _ikzs0dm0.CommentSystemEvent.fromJson(
              (jsonSerialization['systemEvent'] as String),
            ),
      publicationId: jsonSerialization['publicationId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int threadId;

  /// Client-supplied id for idempotent replies (optional).
  _isc.UuidValue? uuid;

  /// Null for system comments.
  int? authorId;

  _ipbpecg8.ActorKind authorKind;

  /// Markdown (inline subset).
  String body;

  /// UserProfile ids mentioned in [body].
  List<int> mentions;

  /// JSON {emoji: [userId]}.
  String reactions;

  DateTime createdAt;

  DateTime? editedAt;

  /// Soft delete: shown as "Comment deleted".
  DateTime? deletedAt;

  _ikzs0dm0.CommentSystemEvent? systemEvent;

  /// (M14) A publication's message (authorKind system), specs/18 §5.2.
  int? publicationId;

  /// Returns a shallow copy of this [Comment]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Comment copyWith({
    int? id,
    int? threadId,
    _isc.UuidValue? uuid = const _isc.$UndefinedUuidValue(),
    int? authorId,
    _ipbpecg8.ActorKind? authorKind,
    String? body,
    List<int>? mentions,
    String? reactions,
    DateTime? createdAt,
    DateTime? editedAt = const _isc.$UndefinedDateTime(),
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
    _ikzs0dm0.CommentSystemEvent? systemEvent,
    int? publicationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Comment',
      if (id != null) 'id': id,
      'threadId': threadId,
      if (uuid != null) 'uuid': uuid?.toJson(),
      if (authorId != null) 'authorId': authorId,
      'authorKind': authorKind.toJson(),
      'body': body,
      'mentions': mentions.toJson(),
      'reactions': reactions,
      'createdAt': createdAt.toJson(),
      if (editedAt != null) 'editedAt': editedAt?.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      if (systemEvent != null) 'systemEvent': systemEvent?.toJson(),
      if (publicationId != null) 'publicationId': publicationId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Comment',
      if (id != null) 'id': id,
      'threadId': threadId,
      if (uuid != null) 'uuid': uuid?.toJson(),
      if (authorId != null) 'authorId': authorId,
      'authorKind': authorKind.toJson(),
      'body': body,
      'mentions': mentions.toJson(),
      'reactions': reactions,
      'createdAt': createdAt.toJson(),
      if (editedAt != null) 'editedAt': editedAt?.toJson(),
      if (deletedAt != null) 'deletedAt': deletedAt?.toJson(),
      if (systemEvent != null) 'systemEvent': systemEvent?.toJson(),
      if (publicationId != null) 'publicationId': publicationId,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CommentImpl extends Comment {
  _CommentImpl({
    int? id,
    required int threadId,
    _isc.UuidValue? uuid,
    int? authorId,
    required _ipbpecg8.ActorKind authorKind,
    required String body,
    required List<int> mentions,
    String? reactions,
    required DateTime createdAt,
    DateTime? editedAt,
    DateTime? deletedAt,
    _ikzs0dm0.CommentSystemEvent? systemEvent,
    int? publicationId,
  }) : super._(
         id: id,
         threadId: threadId,
         uuid: uuid,
         authorId: authorId,
         authorKind: authorKind,
         body: body,
         mentions: mentions,
         reactions: reactions,
         createdAt: createdAt,
         editedAt: editedAt,
         deletedAt: deletedAt,
         systemEvent: systemEvent,
         publicationId: publicationId,
       );

  /// Returns a shallow copy of this [Comment]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Comment copyWith({
    Object? id = _Undefined,
    int? threadId,
    _isc.UuidValue? uuid = const _isc.$UndefinedUuidValue(),
    Object? authorId = _Undefined,
    _ipbpecg8.ActorKind? authorKind,
    String? body,
    List<int>? mentions,
    String? reactions,
    DateTime? createdAt,
    DateTime? editedAt = const _isc.$UndefinedDateTime(),
    DateTime? deletedAt = const _isc.$UndefinedDateTime(),
    Object? systemEvent = _Undefined,
    Object? publicationId = _Undefined,
  }) {
    return Comment(
      id: id is int? ? id : this.id,
      threadId: threadId ?? this.threadId,
      uuid: uuid is _isc.UndefinedSentinel ? this.uuid : uuid,
      authorId: authorId is int? ? authorId : this.authorId,
      authorKind: authorKind ?? this.authorKind,
      body: body ?? this.body,
      mentions: mentions ?? this.mentions.map((e0) => e0).toList(),
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt is _isc.UndefinedSentinel ? this.editedAt : editedAt,
      deletedAt: deletedAt is _isc.UndefinedSentinel
          ? this.deletedAt
          : deletedAt,
      systemEvent: systemEvent is _ikzs0dm0.CommentSystemEvent?
          ? systemEvent
          : this.systemEvent,
      publicationId: publicationId is int? ? publicationId : this.publicationId,
    );
  }
}
