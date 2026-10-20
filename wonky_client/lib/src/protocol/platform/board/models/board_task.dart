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
import '../../../platform/board/models/board_area.dart' as _iknrpzcb;
import '../../../platform/board/models/board_size.dart' as _ibr3u4cf;
import '../../../platform/board/models/board_task_status.dart' as _isr33h3v;

/// A unit of work selected by admins: one post or a bundle (specs/16 §8).
/// The public number (T-12) is the row id.
abstract class BoardTask
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BoardTask._({
    this.id,
    required this.title,
    required this.area,
    required this.size,
    required this.status,
    required this.promptBody,
    this.promptGeneratedAt,
    this.promptRequestedAt,
    this.promptNote,
    this.promptExcludedCommentIds,
    this.promptEditedById,
    this.promptEditedAt,
    required this.createdById,
    this.publishedAt,
    this.claimedById,
    this.claimedAt,
    this.claimExpiresAt,
    this.claimWarnedAt,
    this.claimCode,
    this.pullRequestUrl,
    this.prNumber,
    this.prAuthorLogin,
    this.mergeCommitSha,
    this.doneAt,
    this.shippedDeploySha,
    this.shippedAt,
    required this.createdAt,
  });

  factory BoardTask({
    int? id,
    required String title,
    required _iknrpzcb.BoardArea area,
    required _ibr3u4cf.BoardSize size,
    required _isr33h3v.BoardTaskStatus status,
    required String promptBody,
    DateTime? promptGeneratedAt,
    DateTime? promptRequestedAt,
    String? promptNote,
    List<int>? promptExcludedCommentIds,
    int? promptEditedById,
    DateTime? promptEditedAt,
    required int createdById,
    DateTime? publishedAt,
    int? claimedById,
    DateTime? claimedAt,
    DateTime? claimExpiresAt,
    DateTime? claimWarnedAt,
    String? claimCode,
    String? pullRequestUrl,
    int? prNumber,
    String? prAuthorLogin,
    String? mergeCommitSha,
    DateTime? doneAt,
    String? shippedDeploySha,
    DateTime? shippedAt,
    required DateTime createdAt,
  }) = _BoardTaskImpl;

  factory BoardTask.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardTask(
      id: jsonSerialization['id'] as int?,
      title: jsonSerialization['title'] as String,
      area: _iknrpzcb.BoardArea.fromJson((jsonSerialization['area'] as String)),
      size: _ibr3u4cf.BoardSize.fromJson((jsonSerialization['size'] as String)),
      status: _isr33h3v.BoardTaskStatus.fromJson(
        (jsonSerialization['status'] as String),
      ),
      promptBody: jsonSerialization['promptBody'] as String,
      promptGeneratedAt: jsonSerialization['promptGeneratedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['promptGeneratedAt'],
            ),
      promptRequestedAt: jsonSerialization['promptRequestedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['promptRequestedAt'],
            ),
      promptNote: jsonSerialization['promptNote'] as String?,
      promptExcludedCommentIds:
          jsonSerialization['promptExcludedCommentIds'] == null
          ? null
          : _i8pkqg1o.Protocol().deserialize<List<int>>(
              jsonSerialization['promptExcludedCommentIds'],
            ),
      promptEditedById: jsonSerialization['promptEditedById'] as int?,
      promptEditedAt: jsonSerialization['promptEditedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['promptEditedAt'],
            ),
      createdById: jsonSerialization['createdById'] as int,
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
      claimedById: jsonSerialization['claimedById'] as int?,
      claimedAt: jsonSerialization['claimedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['claimedAt']),
      claimExpiresAt: jsonSerialization['claimExpiresAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['claimExpiresAt'],
            ),
      claimWarnedAt: jsonSerialization['claimWarnedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['claimWarnedAt'],
            ),
      claimCode: jsonSerialization['claimCode'] as String?,
      pullRequestUrl: jsonSerialization['pullRequestUrl'] as String?,
      prNumber: jsonSerialization['prNumber'] as int?,
      prAuthorLogin: jsonSerialization['prAuthorLogin'] as String?,
      mergeCommitSha: jsonSerialization['mergeCommitSha'] as String?,
      doneAt: jsonSerialization['doneAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['doneAt']),
      shippedDeploySha: jsonSerialization['shippedDeploySha'] as String?,
      shippedAt: jsonSerialization['shippedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['shippedAt']),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String title;

  _iknrpzcb.BoardArea area;

  _ibr3u4cf.BoardSize size;

  _isr33h3v.BoardTaskStatus status;

  /// The contributor prompt body (AI-written, admin-edited).
  String promptBody;

  DateTime? promptGeneratedAt;

  /// Set while the AI writes the prompt body (a `BoardFutureCall.writePrompt`
  /// is scheduled); cleared when it is done or the admin sets the prompt.
  DateTime? promptRequestedAt;

  /// Why the last AI writing pass left the prompt as it was (budget used
  /// up, provider error); shown to admins.
  String? promptNote;

  /// Comments of the task's issues the admin left out of the prompt's
  /// context (specs/16 §9.3); every other visible comment is included.
  List<int>? promptExcludedCommentIds;

  int? promptEditedById;

  DateTime? promptEditedAt;

  int createdById;

  DateTime? publishedAt;

  int? claimedById;

  DateTime? claimedAt;

  DateTime? claimExpiresAt;

  DateTime? claimWarnedAt;

  /// Per-claim code for the PR description (specs/16 §13.7).
  String? claimCode;

  String? pullRequestUrl;

  int? prNumber;

  String? prAuthorLogin;

  String? mergeCommitSha;

  DateTime? doneAt;

  String? shippedDeploySha;

  DateTime? shippedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [BoardTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BoardTask copyWith({
    int? id,
    String? title,
    _iknrpzcb.BoardArea? area,
    _ibr3u4cf.BoardSize? size,
    _isr33h3v.BoardTaskStatus? status,
    String? promptBody,
    DateTime? promptGeneratedAt = const _isc.$UndefinedDateTime(),
    DateTime? promptRequestedAt = const _isc.$UndefinedDateTime(),
    String? promptNote,
    List<int>? promptExcludedCommentIds = const _isc.$UndefinedList<int>(),
    int? promptEditedById,
    DateTime? promptEditedAt = const _isc.$UndefinedDateTime(),
    int? createdById,
    DateTime? publishedAt = const _isc.$UndefinedDateTime(),
    int? claimedById,
    DateTime? claimedAt = const _isc.$UndefinedDateTime(),
    DateTime? claimExpiresAt = const _isc.$UndefinedDateTime(),
    DateTime? claimWarnedAt = const _isc.$UndefinedDateTime(),
    String? claimCode,
    String? pullRequestUrl,
    int? prNumber,
    String? prAuthorLogin,
    String? mergeCommitSha,
    DateTime? doneAt = const _isc.$UndefinedDateTime(),
    String? shippedDeploySha,
    DateTime? shippedAt = const _isc.$UndefinedDateTime(),
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardTask',
      if (id != null) 'id': id,
      'title': title,
      'area': area.toJson(),
      'size': size.toJson(),
      'status': status.toJson(),
      'promptBody': promptBody,
      if (promptGeneratedAt != null)
        'promptGeneratedAt': promptGeneratedAt?.toJson(),
      if (promptRequestedAt != null)
        'promptRequestedAt': promptRequestedAt?.toJson(),
      if (promptNote != null) 'promptNote': promptNote,
      if (promptExcludedCommentIds != null)
        'promptExcludedCommentIds': promptExcludedCommentIds?.toJson(),
      if (promptEditedById != null) 'promptEditedById': promptEditedById,
      if (promptEditedAt != null) 'promptEditedAt': promptEditedAt?.toJson(),
      'createdById': createdById,
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      if (claimedById != null) 'claimedById': claimedById,
      if (claimedAt != null) 'claimedAt': claimedAt?.toJson(),
      if (claimExpiresAt != null) 'claimExpiresAt': claimExpiresAt?.toJson(),
      if (claimWarnedAt != null) 'claimWarnedAt': claimWarnedAt?.toJson(),
      if (claimCode != null) 'claimCode': claimCode,
      if (pullRequestUrl != null) 'pullRequestUrl': pullRequestUrl,
      if (prNumber != null) 'prNumber': prNumber,
      if (prAuthorLogin != null) 'prAuthorLogin': prAuthorLogin,
      if (mergeCommitSha != null) 'mergeCommitSha': mergeCommitSha,
      if (doneAt != null) 'doneAt': doneAt?.toJson(),
      if (shippedDeploySha != null) 'shippedDeploySha': shippedDeploySha,
      if (shippedAt != null) 'shippedAt': shippedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BoardTask',
      if (id != null) 'id': id,
      'title': title,
      'area': area.toJson(),
      'size': size.toJson(),
      'status': status.toJson(),
      'promptBody': promptBody,
      if (promptGeneratedAt != null)
        'promptGeneratedAt': promptGeneratedAt?.toJson(),
      if (promptRequestedAt != null)
        'promptRequestedAt': promptRequestedAt?.toJson(),
      if (promptNote != null) 'promptNote': promptNote,
      if (promptExcludedCommentIds != null)
        'promptExcludedCommentIds': promptExcludedCommentIds?.toJson(),
      if (promptEditedById != null) 'promptEditedById': promptEditedById,
      if (promptEditedAt != null) 'promptEditedAt': promptEditedAt?.toJson(),
      'createdById': createdById,
      if (publishedAt != null) 'publishedAt': publishedAt?.toJson(),
      if (claimedById != null) 'claimedById': claimedById,
      if (claimedAt != null) 'claimedAt': claimedAt?.toJson(),
      if (claimExpiresAt != null) 'claimExpiresAt': claimExpiresAt?.toJson(),
      if (claimWarnedAt != null) 'claimWarnedAt': claimWarnedAt?.toJson(),
      if (claimCode != null) 'claimCode': claimCode,
      if (pullRequestUrl != null) 'pullRequestUrl': pullRequestUrl,
      if (prNumber != null) 'prNumber': prNumber,
      if (prAuthorLogin != null) 'prAuthorLogin': prAuthorLogin,
      if (mergeCommitSha != null) 'mergeCommitSha': mergeCommitSha,
      if (doneAt != null) 'doneAt': doneAt?.toJson(),
      if (shippedDeploySha != null) 'shippedDeploySha': shippedDeploySha,
      if (shippedAt != null) 'shippedAt': shippedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BoardTaskImpl extends BoardTask {
  _BoardTaskImpl({
    int? id,
    required String title,
    required _iknrpzcb.BoardArea area,
    required _ibr3u4cf.BoardSize size,
    required _isr33h3v.BoardTaskStatus status,
    required String promptBody,
    DateTime? promptGeneratedAt,
    DateTime? promptRequestedAt,
    String? promptNote,
    List<int>? promptExcludedCommentIds,
    int? promptEditedById,
    DateTime? promptEditedAt,
    required int createdById,
    DateTime? publishedAt,
    int? claimedById,
    DateTime? claimedAt,
    DateTime? claimExpiresAt,
    DateTime? claimWarnedAt,
    String? claimCode,
    String? pullRequestUrl,
    int? prNumber,
    String? prAuthorLogin,
    String? mergeCommitSha,
    DateTime? doneAt,
    String? shippedDeploySha,
    DateTime? shippedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         title: title,
         area: area,
         size: size,
         status: status,
         promptBody: promptBody,
         promptGeneratedAt: promptGeneratedAt,
         promptRequestedAt: promptRequestedAt,
         promptNote: promptNote,
         promptExcludedCommentIds: promptExcludedCommentIds,
         promptEditedById: promptEditedById,
         promptEditedAt: promptEditedAt,
         createdById: createdById,
         publishedAt: publishedAt,
         claimedById: claimedById,
         claimedAt: claimedAt,
         claimExpiresAt: claimExpiresAt,
         claimWarnedAt: claimWarnedAt,
         claimCode: claimCode,
         pullRequestUrl: pullRequestUrl,
         prNumber: prNumber,
         prAuthorLogin: prAuthorLogin,
         mergeCommitSha: mergeCommitSha,
         doneAt: doneAt,
         shippedDeploySha: shippedDeploySha,
         shippedAt: shippedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [BoardTask]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BoardTask copyWith({
    Object? id = _Undefined,
    String? title,
    _iknrpzcb.BoardArea? area,
    _ibr3u4cf.BoardSize? size,
    _isr33h3v.BoardTaskStatus? status,
    String? promptBody,
    DateTime? promptGeneratedAt = const _isc.$UndefinedDateTime(),
    DateTime? promptRequestedAt = const _isc.$UndefinedDateTime(),
    Object? promptNote = _Undefined,
    List<int>? promptExcludedCommentIds = const _isc.$UndefinedList<int>(),
    Object? promptEditedById = _Undefined,
    DateTime? promptEditedAt = const _isc.$UndefinedDateTime(),
    int? createdById,
    DateTime? publishedAt = const _isc.$UndefinedDateTime(),
    Object? claimedById = _Undefined,
    DateTime? claimedAt = const _isc.$UndefinedDateTime(),
    DateTime? claimExpiresAt = const _isc.$UndefinedDateTime(),
    DateTime? claimWarnedAt = const _isc.$UndefinedDateTime(),
    Object? claimCode = _Undefined,
    Object? pullRequestUrl = _Undefined,
    Object? prNumber = _Undefined,
    Object? prAuthorLogin = _Undefined,
    Object? mergeCommitSha = _Undefined,
    DateTime? doneAt = const _isc.$UndefinedDateTime(),
    Object? shippedDeploySha = _Undefined,
    DateTime? shippedAt = const _isc.$UndefinedDateTime(),
    DateTime? createdAt,
  }) {
    return BoardTask(
      id: id is int? ? id : this.id,
      title: title ?? this.title,
      area: area ?? this.area,
      size: size ?? this.size,
      status: status ?? this.status,
      promptBody: promptBody ?? this.promptBody,
      promptGeneratedAt: promptGeneratedAt is _isc.UndefinedSentinel
          ? this.promptGeneratedAt
          : promptGeneratedAt,
      promptRequestedAt: promptRequestedAt is _isc.UndefinedSentinel
          ? this.promptRequestedAt
          : promptRequestedAt,
      promptNote: promptNote is String? ? promptNote : this.promptNote,
      promptExcludedCommentIds:
          promptExcludedCommentIds is _isc.UndefinedSentinel
          ? this.promptExcludedCommentIds?.map((e0) => e0).toList()
          : promptExcludedCommentIds,
      promptEditedById: promptEditedById is int?
          ? promptEditedById
          : this.promptEditedById,
      promptEditedAt: promptEditedAt is _isc.UndefinedSentinel
          ? this.promptEditedAt
          : promptEditedAt,
      createdById: createdById ?? this.createdById,
      publishedAt: publishedAt is _isc.UndefinedSentinel
          ? this.publishedAt
          : publishedAt,
      claimedById: claimedById is int? ? claimedById : this.claimedById,
      claimedAt: claimedAt is _isc.UndefinedSentinel
          ? this.claimedAt
          : claimedAt,
      claimExpiresAt: claimExpiresAt is _isc.UndefinedSentinel
          ? this.claimExpiresAt
          : claimExpiresAt,
      claimWarnedAt: claimWarnedAt is _isc.UndefinedSentinel
          ? this.claimWarnedAt
          : claimWarnedAt,
      claimCode: claimCode is String? ? claimCode : this.claimCode,
      pullRequestUrl: pullRequestUrl is String?
          ? pullRequestUrl
          : this.pullRequestUrl,
      prNumber: prNumber is int? ? prNumber : this.prNumber,
      prAuthorLogin: prAuthorLogin is String?
          ? prAuthorLogin
          : this.prAuthorLogin,
      mergeCommitSha: mergeCommitSha is String?
          ? mergeCommitSha
          : this.mergeCommitSha,
      doneAt: doneAt is _isc.UndefinedSentinel ? this.doneAt : doneAt,
      shippedDeploySha: shippedDeploySha is String?
          ? shippedDeploySha
          : this.shippedDeploySha,
      shippedAt: shippedAt is _isc.UndefinedSentinel
          ? this.shippedAt
          : shippedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
