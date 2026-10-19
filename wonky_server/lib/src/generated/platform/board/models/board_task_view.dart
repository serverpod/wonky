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
import '../../../platform/board/models/board_area.dart' as _iknrpzcb;
import '../../../platform/board/models/board_author.dart' as _imhv5g8m;
import '../../../platform/board/models/board_post_list_item.dart' as _i20hkddq;
import '../../../platform/board/models/board_size.dart' as _ibr3u4cf;
import '../../../platform/board/models/board_task_status.dart' as _isr33h3v;

/// A task as the task page shows it (specs/16 §4.6).
abstract class BoardTaskView
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BoardTaskView._({
    required this.number,
    required this.title,
    required this.area,
    required this.size,
    required this.status,
    required this.promptBody,
    required this.prompt,
    this.promptGeneratedAt,
    required this.promptPending,
    this.promptNote,
    this.promptEditedAt,
    this.promptEditedBy,
    required this.posts,
    this.claimedBy,
    this.claimedAt,
    this.claimExpiresAt,
    this.claimCode,
    required this.isMine,
    this.pullRequestUrl,
    this.prNumber,
    this.prAuthorLogin,
    this.reviewJson,
    this.mergedInto,
    this.publishedAt,
    this.doneAt,
    this.shippedAt,
    required this.createdAt,
  });

  factory BoardTaskView({
    required int number,
    required String title,
    required _iknrpzcb.BoardArea area,
    required _ibr3u4cf.BoardSize size,
    required _isr33h3v.BoardTaskStatus status,
    required String promptBody,
    required String prompt,
    DateTime? promptGeneratedAt,
    required bool promptPending,
    String? promptNote,
    DateTime? promptEditedAt,
    _imhv5g8m.BoardAuthor? promptEditedBy,
    required List<_i20hkddq.BoardPostListItem> posts,
    _imhv5g8m.BoardAuthor? claimedBy,
    DateTime? claimedAt,
    DateTime? claimExpiresAt,
    String? claimCode,
    required bool isMine,
    String? pullRequestUrl,
    int? prNumber,
    String? prAuthorLogin,
    String? reviewJson,
    int? mergedInto,
    DateTime? publishedAt,
    DateTime? doneAt,
    DateTime? shippedAt,
    required DateTime createdAt,
  }) = _BoardTaskViewImpl;

  factory BoardTaskView.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardTaskView(
      number: jsonSerialization['number'] as int,
      title: jsonSerialization['title'] as String,
      area: _iknrpzcb.BoardArea.fromJson((jsonSerialization['area'] as String)),
      size: _ibr3u4cf.BoardSize.fromJson((jsonSerialization['size'] as String)),
      status: _isr33h3v.BoardTaskStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      promptBody: jsonSerialization['promptBody'] as String,
      prompt: jsonSerialization['prompt'] as String,
      promptGeneratedAt: jsonSerialization['promptGeneratedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['promptGeneratedAt'],
            ),
      promptPending: _is.BoolJsonExtension.fromJson(
        jsonSerialization['promptPending'],
      ),
      promptNote: jsonSerialization['promptNote'] as String?,
      promptEditedAt: jsonSerialization['promptEditedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['promptEditedAt'],
            ),
      promptEditedBy: jsonSerialization['promptEditedBy'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_imhv5g8m.BoardAuthor>(
              jsonSerialization['promptEditedBy'],
            ),
      posts: _il4umwa0.Protocol()
          .deserialize<List<_i20hkddq.BoardPostListItem>>(
            jsonSerialization['posts'],
          ),
      claimedBy: jsonSerialization['claimedBy'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_imhv5g8m.BoardAuthor>(
              jsonSerialization['claimedBy'],
            ),
      claimedAt: jsonSerialization['claimedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['claimedAt']),
      claimExpiresAt: jsonSerialization['claimExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['claimExpiresAt'],
            ),
      claimCode: jsonSerialization['claimCode'] as String?,
      isMine: _is.BoolJsonExtension.fromJson(jsonSerialization['isMine']),
      pullRequestUrl: jsonSerialization['pullRequestUrl'] as String?,
      prNumber: jsonSerialization['prNumber'] as int?,
      prAuthorLogin: jsonSerialization['prAuthorLogin'] as String?,
      reviewJson: jsonSerialization['reviewJson'] as String?,
      mergedInto: jsonSerialization['mergedInto'] as int?,
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
      doneAt: jsonSerialization['doneAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['doneAt']),
      shippedAt: jsonSerialization['shippedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['shippedAt']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int number;

  String title;

  _iknrpzcb.BoardArea area;

  _ibr3u4cf.BoardSize size;

  _isr33h3v.BoardTaskStatus status;

  /// The AI-written (admin-reviewed) part of the prompt. Empty for
  /// everyone but the claimant and admins (specs/16 §4.6).
  String promptBody;

  /// The full contributor prompt: the fixed frame around [promptBody]
  /// (specs/16 §10.1), its PR lines filled in with the claimant's claim
  /// code. Empty for everyone but the claimant and admins (admins see the
  /// placeholder instead of a claim code).
  String prompt;

  DateTime? promptGeneratedAt;

  /// The AI is writing the prompt body (specs/16 §10.1); it arrives
  /// through `watchTasks`.
  bool promptPending;

  /// Why the last AI pass left the prompt as it was (admins only).
  String? promptNote;

  DateTime? promptEditedAt;

  _imhv5g8m.BoardAuthor? promptEditedBy;

  List<_i20hkddq.BoardPostListItem> posts;

  _imhv5g8m.BoardAuthor? claimedBy;

  DateTime? claimedAt;

  DateTime? claimExpiresAt;

  /// Only for the claimant.
  String? claimCode;

  bool isMine;

  String? pullRequestUrl;

  int? prNumber;

  String? prAuthorLogin;

  /// The latest PR review (specs/16 §13.5), JSON.
  String? reviewJson;

  /// The task this cancelled task was merged into (specs/16 §9.3).
  int? mergedInto;

  DateTime? publishedAt;

  DateTime? doneAt;

  DateTime? shippedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [BoardTaskView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BoardTaskView copyWith({
    int? number,
    String? title,
    _iknrpzcb.BoardArea? area,
    _ibr3u4cf.BoardSize? size,
    _isr33h3v.BoardTaskStatus? status,
    String? promptBody,
    String? prompt,
    DateTime? promptGeneratedAt = const _is.$UndefinedDateTime(),
    bool? promptPending,
    String? promptNote,
    DateTime? promptEditedAt = const _is.$UndefinedDateTime(),
    _imhv5g8m.BoardAuthor? promptEditedBy =
        const _UndefinedBoardTaskView$promptEditedBy(),
    List<_i20hkddq.BoardPostListItem>? posts,
    _imhv5g8m.BoardAuthor? claimedBy =
        const _UndefinedBoardTaskView$promptEditedBy(),
    DateTime? claimedAt = const _is.$UndefinedDateTime(),
    DateTime? claimExpiresAt = const _is.$UndefinedDateTime(),
    String? claimCode,
    bool? isMine,
    String? pullRequestUrl,
    int? prNumber,
    String? prAuthorLogin,
    String? reviewJson,
    int? mergedInto,
    DateTime? publishedAt = const _is.$UndefinedDateTime(),
    DateTime? doneAt = const _is.$UndefinedDateTime(),
    DateTime? shippedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardTaskView',
      'number': number,
      'title': title,
      'area': area.toJson(),
      'size': size.toJson(),
      'status': status.toJson(),
      'promptBody': promptBody,
      'prompt': prompt,
      if (promptGeneratedAt != null)
        'promptGeneratedAt': promptGeneratedAt?.toJson(),
      'promptPending': promptPending,
      if (promptNote != null) 'promptNote': promptNote,
      if (promptEditedAt != null) 'promptEditedAt': promptEditedAt?.toJson(),
      if (promptEditedBy != null) 'promptEditedBy': promptEditedBy?.toJson(),
      'posts': posts.toJson(valueToJson: (v) => v.toJson()),
      if (claimedBy != null) 'claimedBy': claimedBy?.toJson(),
      if (claimedAt != null) 'claimedAt': claimedAt?.toJson(),
      if (claimExpiresAt != null) 'claimExpiresAt': claimExpiresAt?.toJson(),
      if (claimCode != null) 'claimCode': claimCode,
      'isMine': isMine,
      if (pullRequestUrl != null) 'pullRequestUrl': pullRequestUrl,
      if (prNumber != null) 'prNumber': prNumber,
      if (prAuthorLogin != null) 'prAuthorLogin': prAuthorLogin,
      if (reviewJson != null) 'reviewJson': reviewJson,
      if (mergedInto != null) 'mergedInto': mergedInto,
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      if (doneAt != null) 'doneAt': doneAt?.toJson(),
      if (shippedAt != null) 'shippedAt': shippedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BoardTaskView',
      'number': number,
      'title': title,
      'area': area.toJson(),
      'size': size.toJson(),
      'status': status.toJson(),
      'promptBody': promptBody,
      'prompt': prompt,
      if (promptGeneratedAt != null)
        'promptGeneratedAt': promptGeneratedAt?.toJson(),
      'promptPending': promptPending,
      if (promptNote != null) 'promptNote': promptNote,
      if (promptEditedAt != null) 'promptEditedAt': promptEditedAt?.toJson(),
      if (promptEditedBy != null)
        'promptEditedBy': promptEditedBy?.toJsonForProtocol(),
      'posts': posts.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (claimedBy != null) 'claimedBy': claimedBy?.toJsonForProtocol(),
      if (claimedAt != null) 'claimedAt': claimedAt?.toJson(),
      if (claimExpiresAt != null) 'claimExpiresAt': claimExpiresAt?.toJson(),
      if (claimCode != null) 'claimCode': claimCode,
      'isMine': isMine,
      if (pullRequestUrl != null) 'pullRequestUrl': pullRequestUrl,
      if (prNumber != null) 'prNumber': prNumber,
      if (prAuthorLogin != null) 'prAuthorLogin': prAuthorLogin,
      if (reviewJson != null) 'reviewJson': reviewJson,
      if (mergedInto != null) 'mergedInto': mergedInto,
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      if (doneAt != null) 'doneAt': doneAt?.toJson(),
      if (shippedAt != null) 'shippedAt': shippedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedBoardTaskView$promptEditedBy extends _is.UndefinedSentinel
    implements _imhv5g8m.BoardAuthor {
  const _UndefinedBoardTaskView$promptEditedBy();
}

class _BoardTaskViewImpl extends BoardTaskView {
  _BoardTaskViewImpl({
    required int number,
    required String title,
    required _iknrpzcb.BoardArea area,
    required _ibr3u4cf.BoardSize size,
    required _isr33h3v.BoardTaskStatus status,
    required String promptBody,
    required String prompt,
    DateTime? promptGeneratedAt,
    required bool promptPending,
    String? promptNote,
    DateTime? promptEditedAt,
    _imhv5g8m.BoardAuthor? promptEditedBy,
    required List<_i20hkddq.BoardPostListItem> posts,
    _imhv5g8m.BoardAuthor? claimedBy,
    DateTime? claimedAt,
    DateTime? claimExpiresAt,
    String? claimCode,
    required bool isMine,
    String? pullRequestUrl,
    int? prNumber,
    String? prAuthorLogin,
    String? reviewJson,
    int? mergedInto,
    DateTime? publishedAt,
    DateTime? doneAt,
    DateTime? shippedAt,
    required DateTime createdAt,
  }) : super._(
         number: number,
         title: title,
         area: area,
         size: size,
         status: status,
         promptBody: promptBody,
         prompt: prompt,
         promptGeneratedAt: promptGeneratedAt,
         promptPending: promptPending,
         promptNote: promptNote,
         promptEditedAt: promptEditedAt,
         promptEditedBy: promptEditedBy,
         posts: posts,
         claimedBy: claimedBy,
         claimedAt: claimedAt,
         claimExpiresAt: claimExpiresAt,
         claimCode: claimCode,
         isMine: isMine,
         pullRequestUrl: pullRequestUrl,
         prNumber: prNumber,
         prAuthorLogin: prAuthorLogin,
         reviewJson: reviewJson,
         mergedInto: mergedInto,
         publishedAt: publishedAt,
         doneAt: doneAt,
         shippedAt: shippedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [BoardTaskView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BoardTaskView copyWith({
    int? number,
    String? title,
    _iknrpzcb.BoardArea? area,
    _ibr3u4cf.BoardSize? size,
    _isr33h3v.BoardTaskStatus? status,
    String? promptBody,
    String? prompt,
    DateTime? promptGeneratedAt = const _is.$UndefinedDateTime(),
    bool? promptPending,
    Object? promptNote = _Undefined,
    DateTime? promptEditedAt = const _is.$UndefinedDateTime(),
    _imhv5g8m.BoardAuthor? promptEditedBy =
        const _UndefinedBoardTaskView$promptEditedBy(),
    List<_i20hkddq.BoardPostListItem>? posts,
    _imhv5g8m.BoardAuthor? claimedBy =
        const _UndefinedBoardTaskView$promptEditedBy(),
    DateTime? claimedAt = const _is.$UndefinedDateTime(),
    DateTime? claimExpiresAt = const _is.$UndefinedDateTime(),
    Object? claimCode = _Undefined,
    bool? isMine,
    Object? pullRequestUrl = _Undefined,
    Object? prNumber = _Undefined,
    Object? prAuthorLogin = _Undefined,
    Object? reviewJson = _Undefined,
    Object? mergedInto = _Undefined,
    DateTime? publishedAt = const _is.$UndefinedDateTime(),
    DateTime? doneAt = const _is.$UndefinedDateTime(),
    DateTime? shippedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
  }) {
    return BoardTaskView(
      number: number ?? this.number,
      title: title ?? this.title,
      area: area ?? this.area,
      size: size ?? this.size,
      status: status ?? this.status,
      promptBody: promptBody ?? this.promptBody,
      prompt: prompt ?? this.prompt,
      promptGeneratedAt: promptGeneratedAt is _is.UndefinedSentinel
          ? this.promptGeneratedAt
          : promptGeneratedAt,
      promptPending: promptPending ?? this.promptPending,
      promptNote: promptNote is String? ? promptNote : this.promptNote,
      promptEditedAt: promptEditedAt is _is.UndefinedSentinel
          ? this.promptEditedAt
          : promptEditedAt,
      promptEditedBy: promptEditedBy is _is.UndefinedSentinel
          ? this.promptEditedBy?.copyWith()
          : promptEditedBy,
      posts: posts ?? this.posts.map((e0) => e0.copyWith()).toList(),
      claimedBy: claimedBy is _is.UndefinedSentinel
          ? this.claimedBy?.copyWith()
          : claimedBy,
      claimedAt: claimedAt is _is.UndefinedSentinel
          ? this.claimedAt
          : claimedAt,
      claimExpiresAt: claimExpiresAt is _is.UndefinedSentinel
          ? this.claimExpiresAt
          : claimExpiresAt,
      claimCode: claimCode is String? ? claimCode : this.claimCode,
      isMine: isMine ?? this.isMine,
      pullRequestUrl: pullRequestUrl is String?
          ? pullRequestUrl
          : this.pullRequestUrl,
      prNumber: prNumber is int? ? prNumber : this.prNumber,
      prAuthorLogin: prAuthorLogin is String?
          ? prAuthorLogin
          : this.prAuthorLogin,
      reviewJson: reviewJson is String? ? reviewJson : this.reviewJson,
      mergedInto: mergedInto is int? ? mergedInto : this.mergedInto,
      publishedAt: publishedAt is _is.UndefinedSentinel
          ? this.publishedAt
          : publishedAt,
      doneAt: doneAt is _is.UndefinedSentinel ? this.doneAt : doneAt,
      shippedAt: shippedAt is _is.UndefinedSentinel
          ? this.shippedAt
          : shippedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
