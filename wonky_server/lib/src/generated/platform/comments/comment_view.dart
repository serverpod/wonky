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
import '../../platform/comments/comment_system_event.dart' as _ikzs0dm0;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;
import '../../platform/users/user_summary.dart' as _itg9e9ms;

abstract class CommentView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CommentView._({
    required this.id,
    this.uuid,
    required this.threadUuid,
    this.author,
    required this.authorKind,
    required this.body,
    required this.mentions,
    required this.reactions,
    required this.createdAt,
    this.editedAt,
    required this.deleted,
    this.systemEvent,
    this.authorLabel,
  });

  factory CommentView({
    required int id,
    _is.UuidValue? uuid,
    required _is.UuidValue threadUuid,
    _itg9e9ms.UserSummary? author,
    required _ipbpecg8.ActorKind authorKind,
    required String body,
    required List<_itg9e9ms.UserSummary> mentions,
    required Map<String, List<int>> reactions,
    required DateTime createdAt,
    DateTime? editedAt,
    required bool deleted,
    _ikzs0dm0.CommentSystemEvent? systemEvent,
    String? authorLabel,
  }) = _CommentViewImpl;

  factory CommentView.fromJson(Map<String, dynamic> jsonSerialization) {
    return CommentView(
      id: jsonSerialization['id'] as int,
      uuid: jsonSerialization['uuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      threadUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['threadUuid'],
      ),
      author: jsonSerialization['author'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_itg9e9ms.UserSummary>(
              jsonSerialization['author'],
            ),
      authorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['authorKind'] as String),
      ),
      body: jsonSerialization['body'] as String,
      mentions: _il4umwa0.Protocol().deserialize<List<_itg9e9ms.UserSummary>>(
        jsonSerialization['mentions'],
      ),
      reactions: _il4umwa0.Protocol().deserialize<Map<String, List<int>>>(
        jsonSerialization['reactions'],
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      editedAt: jsonSerialization['editedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['editedAt']),
      deleted: _is.BoolJsonExtension.fromJson(jsonSerialization['deleted']),
      systemEvent: jsonSerialization['systemEvent'] == null
          ? null
          : _ikzs0dm0.CommentSystemEvent.fromJson(
              (jsonSerialization['systemEvent'] as String),
            ),
      authorLabel: jsonSerialization['authorLabel'] as String?,
    );
  }

  int id;

  _is.UuidValue? uuid;

  _is.UuidValue threadUuid;

  _itg9e9ms.UserSummary? author;

  _ipbpecg8.ActorKind authorKind;

  /// Empty when deleted.
  String body;

  List<_itg9e9ms.UserSummary> mentions;

  /// emoji → user ids.
  Map<String, List<int>> reactions;

  DateTime createdAt;

  DateTime? editedAt;

  bool deleted;

  _ikzs0dm0.CommentSystemEvent? systemEvent;

  /// (M14) Name shown instead of a user: the publication of a message
  /// (specs/18 §5.2).
  String? authorLabel;

  /// Returns a shallow copy of this [CommentView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CommentView copyWith({
    int? id,
    _is.UuidValue? uuid = const _is.$UndefinedUuidValue(),
    _is.UuidValue? threadUuid,
    _itg9e9ms.UserSummary? author = const _UndefinedCommentView$author(),
    _ipbpecg8.ActorKind? authorKind,
    String? body,
    List<_itg9e9ms.UserSummary>? mentions,
    Map<String, List<int>>? reactions,
    DateTime? createdAt,
    DateTime? editedAt = const _is.$UndefinedDateTime(),
    bool? deleted,
    _ikzs0dm0.CommentSystemEvent? systemEvent,
    String? authorLabel,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CommentView',
      'id': id,
      if (uuid != null) 'uuid': uuid?.toJson(),
      'threadUuid': threadUuid.toJson(),
      if (author != null) 'author': author?.toJson(),
      'authorKind': authorKind.toJson(),
      'body': body,
      'mentions': mentions.toJson(valueToJson: (v) => v.toJson()),
      'reactions': reactions.toJson(valueToJson: (v) => v.toJson()),
      'createdAt': createdAt.toJson(),
      if (editedAt != null) 'editedAt': editedAt?.toJson(),
      'deleted': deleted,
      if (systemEvent != null) 'systemEvent': systemEvent?.toJson(),
      if (authorLabel != null) 'authorLabel': authorLabel,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CommentView',
      'id': id,
      if (uuid != null) 'uuid': uuid?.toJson(),
      'threadUuid': threadUuid.toJson(),
      if (author != null) 'author': author?.toJsonForProtocol(),
      'authorKind': authorKind.toJson(),
      'body': body,
      'mentions': mentions.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'reactions': reactions.toJson(valueToJson: (v) => v.toJson()),
      'createdAt': createdAt.toJson(),
      if (editedAt != null) 'editedAt': editedAt?.toJson(),
      'deleted': deleted,
      if (systemEvent != null) 'systemEvent': systemEvent?.toJson(),
      if (authorLabel != null) 'authorLabel': authorLabel,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedCommentView$author extends _is.UndefinedSentinel
    implements _itg9e9ms.UserSummary {
  const _UndefinedCommentView$author();
}

class _CommentViewImpl extends CommentView {
  _CommentViewImpl({
    required int id,
    _is.UuidValue? uuid,
    required _is.UuidValue threadUuid,
    _itg9e9ms.UserSummary? author,
    required _ipbpecg8.ActorKind authorKind,
    required String body,
    required List<_itg9e9ms.UserSummary> mentions,
    required Map<String, List<int>> reactions,
    required DateTime createdAt,
    DateTime? editedAt,
    required bool deleted,
    _ikzs0dm0.CommentSystemEvent? systemEvent,
    String? authorLabel,
  }) : super._(
         id: id,
         uuid: uuid,
         threadUuid: threadUuid,
         author: author,
         authorKind: authorKind,
         body: body,
         mentions: mentions,
         reactions: reactions,
         createdAt: createdAt,
         editedAt: editedAt,
         deleted: deleted,
         systemEvent: systemEvent,
         authorLabel: authorLabel,
       );

  /// Returns a shallow copy of this [CommentView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CommentView copyWith({
    int? id,
    _is.UuidValue? uuid = const _is.$UndefinedUuidValue(),
    _is.UuidValue? threadUuid,
    _itg9e9ms.UserSummary? author = const _UndefinedCommentView$author(),
    _ipbpecg8.ActorKind? authorKind,
    String? body,
    List<_itg9e9ms.UserSummary>? mentions,
    Map<String, List<int>>? reactions,
    DateTime? createdAt,
    DateTime? editedAt = const _is.$UndefinedDateTime(),
    bool? deleted,
    Object? systemEvent = _Undefined,
    Object? authorLabel = _Undefined,
  }) {
    return CommentView(
      id: id ?? this.id,
      uuid: uuid is _is.UndefinedSentinel ? this.uuid : uuid,
      threadUuid: threadUuid ?? this.threadUuid,
      author: author is _is.UndefinedSentinel
          ? this.author?.copyWith()
          : author,
      authorKind: authorKind ?? this.authorKind,
      body: body ?? this.body,
      mentions: mentions ?? this.mentions.map((e0) => e0.copyWith()).toList(),
      reactions:
          reactions ??
          this.reactions.map(
            (
              key0,
              value0,
            ) => MapEntry(
              key0,
              value0.map((e1) => e1).toList(),
            ),
          ),
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt is _is.UndefinedSentinel ? this.editedAt : editedAt,
      deleted: deleted ?? this.deleted,
      systemEvent: systemEvent is _ikzs0dm0.CommentSystemEvent?
          ? systemEvent
          : this.systemEvent,
      authorLabel: authorLabel is String? ? authorLabel : this.authorLabel,
    );
  }
}
