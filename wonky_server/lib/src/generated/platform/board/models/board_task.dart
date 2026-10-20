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
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../../platform/board/models/board_area.dart' as _iknrpzcb;
import '../../../platform/board/models/board_size.dart' as _ibr3u4cf;
import '../../../platform/board/models/board_task_status.dart' as _isr33h3v;

/// A unit of work selected by admins: one post or a bundle (specs/16 §8).
/// The public number (T-12) is the row id.
abstract class BoardTask
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['promptGeneratedAt'],
            ),
      promptRequestedAt: jsonSerialization['promptRequestedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['promptRequestedAt'],
            ),
      promptNote: jsonSerialization['promptNote'] as String?,
      promptExcludedCommentIds:
          jsonSerialization['promptExcludedCommentIds'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<List<int>>(
              jsonSerialization['promptExcludedCommentIds'],
            ),
      promptEditedById: jsonSerialization['promptEditedById'] as int?,
      promptEditedAt: jsonSerialization['promptEditedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['promptEditedAt'],
            ),
      createdById: jsonSerialization['createdById'] as int,
      publishedAt: jsonSerialization['publishedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['publishedAt'],
            ),
      claimedById: jsonSerialization['claimedById'] as int?,
      claimedAt: jsonSerialization['claimedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['claimedAt']),
      claimExpiresAt: jsonSerialization['claimExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['claimExpiresAt'],
            ),
      claimWarnedAt: jsonSerialization['claimWarnedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['claimWarnedAt'],
            ),
      claimCode: jsonSerialization['claimCode'] as String?,
      pullRequestUrl: jsonSerialization['pullRequestUrl'] as String?,
      prNumber: jsonSerialization['prNumber'] as int?,
      prAuthorLogin: jsonSerialization['prAuthorLogin'] as String?,
      mergeCommitSha: jsonSerialization['mergeCommitSha'] as String?,
      doneAt: jsonSerialization['doneAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['doneAt']),
      shippedDeploySha: jsonSerialization['shippedDeploySha'] as String?,
      shippedAt: jsonSerialization['shippedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['shippedAt']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = BoardTaskTable();

  static const db = BoardTaskRepository._();

  @override
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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [BoardTask]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BoardTask copyWith({
    int? id,
    String? title,
    _iknrpzcb.BoardArea? area,
    _ibr3u4cf.BoardSize? size,
    _isr33h3v.BoardTaskStatus? status,
    String? promptBody,
    DateTime? promptGeneratedAt = const _is.$UndefinedDateTime(),
    DateTime? promptRequestedAt = const _is.$UndefinedDateTime(),
    String? promptNote,
    List<int>? promptExcludedCommentIds = const _is.$UndefinedList<int>(),
    int? promptEditedById,
    DateTime? promptEditedAt = const _is.$UndefinedDateTime(),
    int? createdById,
    DateTime? publishedAt = const _is.$UndefinedDateTime(),
    int? claimedById,
    DateTime? claimedAt = const _is.$UndefinedDateTime(),
    DateTime? claimExpiresAt = const _is.$UndefinedDateTime(),
    DateTime? claimWarnedAt = const _is.$UndefinedDateTime(),
    String? claimCode,
    String? pullRequestUrl,
    int? prNumber,
    String? prAuthorLogin,
    String? mergeCommitSha,
    DateTime? doneAt = const _is.$UndefinedDateTime(),
    String? shippedDeploySha,
    DateTime? shippedAt = const _is.$UndefinedDateTime(),
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

  static BoardTaskInclude include() {
    return BoardTaskInclude._();
  }

  static BoardTaskIncludeList includeList({
    _is.WhereExpressionBuilder<BoardTaskTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BoardTaskTable>? orderBy,
    _is.OrderByListBuilder<BoardTaskTable>? orderByList,
    BoardTaskInclude? include,
  }) {
    return BoardTaskIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BoardTask.t),
      orderByList: orderByList?.call(BoardTask.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
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
  @_is.useResult
  @override
  BoardTask copyWith({
    Object? id = _Undefined,
    String? title,
    _iknrpzcb.BoardArea? area,
    _ibr3u4cf.BoardSize? size,
    _isr33h3v.BoardTaskStatus? status,
    String? promptBody,
    DateTime? promptGeneratedAt = const _is.$UndefinedDateTime(),
    DateTime? promptRequestedAt = const _is.$UndefinedDateTime(),
    Object? promptNote = _Undefined,
    List<int>? promptExcludedCommentIds = const _is.$UndefinedList<int>(),
    Object? promptEditedById = _Undefined,
    DateTime? promptEditedAt = const _is.$UndefinedDateTime(),
    int? createdById,
    DateTime? publishedAt = const _is.$UndefinedDateTime(),
    Object? claimedById = _Undefined,
    DateTime? claimedAt = const _is.$UndefinedDateTime(),
    DateTime? claimExpiresAt = const _is.$UndefinedDateTime(),
    DateTime? claimWarnedAt = const _is.$UndefinedDateTime(),
    Object? claimCode = _Undefined,
    Object? pullRequestUrl = _Undefined,
    Object? prNumber = _Undefined,
    Object? prAuthorLogin = _Undefined,
    Object? mergeCommitSha = _Undefined,
    DateTime? doneAt = const _is.$UndefinedDateTime(),
    Object? shippedDeploySha = _Undefined,
    DateTime? shippedAt = const _is.$UndefinedDateTime(),
    DateTime? createdAt,
  }) {
    return BoardTask(
      id: id is int? ? id : this.id,
      title: title ?? this.title,
      area: area ?? this.area,
      size: size ?? this.size,
      status: status ?? this.status,
      promptBody: promptBody ?? this.promptBody,
      promptGeneratedAt: promptGeneratedAt is _is.UndefinedSentinel
          ? this.promptGeneratedAt
          : promptGeneratedAt,
      promptRequestedAt: promptRequestedAt is _is.UndefinedSentinel
          ? this.promptRequestedAt
          : promptRequestedAt,
      promptNote: promptNote is String? ? promptNote : this.promptNote,
      promptExcludedCommentIds:
          promptExcludedCommentIds is _is.UndefinedSentinel
          ? this.promptExcludedCommentIds?.map((e0) => e0).toList()
          : promptExcludedCommentIds,
      promptEditedById: promptEditedById is int?
          ? promptEditedById
          : this.promptEditedById,
      promptEditedAt: promptEditedAt is _is.UndefinedSentinel
          ? this.promptEditedAt
          : promptEditedAt,
      createdById: createdById ?? this.createdById,
      publishedAt: publishedAt is _is.UndefinedSentinel
          ? this.publishedAt
          : publishedAt,
      claimedById: claimedById is int? ? claimedById : this.claimedById,
      claimedAt: claimedAt is _is.UndefinedSentinel
          ? this.claimedAt
          : claimedAt,
      claimExpiresAt: claimExpiresAt is _is.UndefinedSentinel
          ? this.claimExpiresAt
          : claimExpiresAt,
      claimWarnedAt: claimWarnedAt is _is.UndefinedSentinel
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
      doneAt: doneAt is _is.UndefinedSentinel ? this.doneAt : doneAt,
      shippedDeploySha: shippedDeploySha is String?
          ? shippedDeploySha
          : this.shippedDeploySha,
      shippedAt: shippedAt is _is.UndefinedSentinel
          ? this.shippedAt
          : shippedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BoardTaskUpdateTable extends _is.UpdateTable<BoardTaskTable> {
  BoardTaskUpdateTable(super.table);

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<_iknrpzcb.BoardArea, _iknrpzcb.BoardArea> area(
    _iknrpzcb.BoardArea value,
  ) => _is.ColumnValue(
    table.area,
    value,
  );

  _is.ColumnValue<_ibr3u4cf.BoardSize, _ibr3u4cf.BoardSize> size(
    _ibr3u4cf.BoardSize value,
  ) => _is.ColumnValue(
    table.size,
    value,
  );

  _is.ColumnValue<_isr33h3v.BoardTaskStatus, _isr33h3v.BoardTaskStatus> status(
    _isr33h3v.BoardTaskStatus value,
  ) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> promptBody(String value) => _is.ColumnValue(
    table.promptBody,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> promptGeneratedAt(DateTime? value) =>
      _is.ColumnValue(
        table.promptGeneratedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> promptRequestedAt(DateTime? value) =>
      _is.ColumnValue(
        table.promptRequestedAt,
        value,
      );

  _is.ColumnValue<String, String> promptNote(String? value) => _is.ColumnValue(
    table.promptNote,
    value,
  );

  _is.ColumnValue<List<int>, List<int>> promptExcludedCommentIds(
    List<int>? value,
  ) => _is.ColumnValue(
    table.promptExcludedCommentIds,
    value,
  );

  _is.ColumnValue<int, int> promptEditedById(int? value) => _is.ColumnValue(
    table.promptEditedById,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> promptEditedAt(DateTime? value) =>
      _is.ColumnValue(
        table.promptEditedAt,
        value,
      );

  _is.ColumnValue<int, int> createdById(int value) => _is.ColumnValue(
    table.createdById,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> publishedAt(DateTime? value) =>
      _is.ColumnValue(
        table.publishedAt,
        value,
      );

  _is.ColumnValue<int, int> claimedById(int? value) => _is.ColumnValue(
    table.claimedById,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> claimedAt(DateTime? value) =>
      _is.ColumnValue(
        table.claimedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> claimExpiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.claimExpiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> claimWarnedAt(DateTime? value) =>
      _is.ColumnValue(
        table.claimWarnedAt,
        value,
      );

  _is.ColumnValue<String, String> claimCode(String? value) => _is.ColumnValue(
    table.claimCode,
    value,
  );

  _is.ColumnValue<String, String> pullRequestUrl(String? value) =>
      _is.ColumnValue(
        table.pullRequestUrl,
        value,
      );

  _is.ColumnValue<int, int> prNumber(int? value) => _is.ColumnValue(
    table.prNumber,
    value,
  );

  _is.ColumnValue<String, String> prAuthorLogin(String? value) =>
      _is.ColumnValue(
        table.prAuthorLogin,
        value,
      );

  _is.ColumnValue<String, String> mergeCommitSha(String? value) =>
      _is.ColumnValue(
        table.mergeCommitSha,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> doneAt(DateTime? value) =>
      _is.ColumnValue(
        table.doneAt,
        value,
      );

  _is.ColumnValue<String, String> shippedDeploySha(String? value) =>
      _is.ColumnValue(
        table.shippedDeploySha,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> shippedAt(DateTime? value) =>
      _is.ColumnValue(
        table.shippedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class BoardTaskTable extends _is.Table<int?> {
  BoardTaskTable({super.tableRelation}) : super(tableName: 'board_task') {
    updateTable = BoardTaskUpdateTable(this);
    title = _is.ColumnString(
      'title',
      this,
    );
    area = _is.ColumnEnum(
      'area',
      this,
      _is.EnumSerialization.byName,
    );
    size = _is.ColumnEnum(
      'size',
      this,
      _is.EnumSerialization.byName,
    );
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
    );
    promptBody = _is.ColumnString(
      'promptBody',
      this,
    );
    promptGeneratedAt = _is.ColumnDateTime(
      'promptGeneratedAt',
      this,
    );
    promptRequestedAt = _is.ColumnDateTime(
      'promptRequestedAt',
      this,
    );
    promptNote = _is.ColumnString(
      'promptNote',
      this,
    );
    promptExcludedCommentIds = _is.ColumnSerializable<List<int>>(
      'promptExcludedCommentIds',
      this,
    );
    promptEditedById = _is.ColumnInt(
      'promptEditedById',
      this,
    );
    promptEditedAt = _is.ColumnDateTime(
      'promptEditedAt',
      this,
    );
    createdById = _is.ColumnInt(
      'createdById',
      this,
    );
    publishedAt = _is.ColumnDateTime(
      'publishedAt',
      this,
    );
    claimedById = _is.ColumnInt(
      'claimedById',
      this,
    );
    claimedAt = _is.ColumnDateTime(
      'claimedAt',
      this,
    );
    claimExpiresAt = _is.ColumnDateTime(
      'claimExpiresAt',
      this,
    );
    claimWarnedAt = _is.ColumnDateTime(
      'claimWarnedAt',
      this,
    );
    claimCode = _is.ColumnString(
      'claimCode',
      this,
    );
    pullRequestUrl = _is.ColumnString(
      'pullRequestUrl',
      this,
    );
    prNumber = _is.ColumnInt(
      'prNumber',
      this,
    );
    prAuthorLogin = _is.ColumnString(
      'prAuthorLogin',
      this,
    );
    mergeCommitSha = _is.ColumnString(
      'mergeCommitSha',
      this,
    );
    doneAt = _is.ColumnDateTime(
      'doneAt',
      this,
    );
    shippedDeploySha = _is.ColumnString(
      'shippedDeploySha',
      this,
    );
    shippedAt = _is.ColumnDateTime(
      'shippedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final BoardTaskUpdateTable updateTable;

  late final _is.ColumnString title;

  late final _is.ColumnEnum<_iknrpzcb.BoardArea> area;

  late final _is.ColumnEnum<_ibr3u4cf.BoardSize> size;

  late final _is.ColumnEnum<_isr33h3v.BoardTaskStatus> status;

  /// The contributor prompt body (AI-written, admin-edited).
  late final _is.ColumnString promptBody;

  late final _is.ColumnDateTime promptGeneratedAt;

  /// Set while the AI writes the prompt body (a `BoardFutureCall.writePrompt`
  /// is scheduled); cleared when it is done or the admin sets the prompt.
  late final _is.ColumnDateTime promptRequestedAt;

  /// Why the last AI writing pass left the prompt as it was (budget used
  /// up, provider error); shown to admins.
  late final _is.ColumnString promptNote;

  /// Comments of the task's issues the admin left out of the prompt's
  /// context (specs/16 §9.3); every other visible comment is included.
  late final _is.ColumnSerializable<List<int>> promptExcludedCommentIds;

  late final _is.ColumnInt promptEditedById;

  late final _is.ColumnDateTime promptEditedAt;

  late final _is.ColumnInt createdById;

  late final _is.ColumnDateTime publishedAt;

  late final _is.ColumnInt claimedById;

  late final _is.ColumnDateTime claimedAt;

  late final _is.ColumnDateTime claimExpiresAt;

  late final _is.ColumnDateTime claimWarnedAt;

  /// Per-claim code for the PR description (specs/16 §13.7).
  late final _is.ColumnString claimCode;

  late final _is.ColumnString pullRequestUrl;

  late final _is.ColumnInt prNumber;

  late final _is.ColumnString prAuthorLogin;

  late final _is.ColumnString mergeCommitSha;

  late final _is.ColumnDateTime doneAt;

  late final _is.ColumnString shippedDeploySha;

  late final _is.ColumnDateTime shippedAt;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    title,
    area,
    size,
    status,
    promptBody,
    promptGeneratedAt,
    promptRequestedAt,
    promptNote,
    promptExcludedCommentIds,
    promptEditedById,
    promptEditedAt,
    createdById,
    publishedAt,
    claimedById,
    claimedAt,
    claimExpiresAt,
    claimWarnedAt,
    claimCode,
    pullRequestUrl,
    prNumber,
    prAuthorLogin,
    mergeCommitSha,
    doneAt,
    shippedDeploySha,
    shippedAt,
    createdAt,
  ];
}

class BoardTaskInclude extends _is.IncludeObject {
  BoardTaskInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => BoardTask.t;
}

class BoardTaskIncludeList extends _is.IncludeList {
  BoardTaskIncludeList._({
    _is.WhereExpressionBuilder<BoardTaskTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BoardTask.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => BoardTask.t;
}

class BoardTaskRepository {
  const BoardTaskRepository._();

  /// Returns a list of [BoardTask]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<BoardTask>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BoardTaskTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BoardTaskTable>? orderBy,
    _is.OrderByListBuilder<BoardTaskTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BoardTask>(
      where: where?.call(BoardTask.t),
      orderBy: orderBy?.call(BoardTask.t),
      orderByList: orderByList?.call(BoardTask.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [BoardTask]s matching the given query parameters every time the
  /// source tables are modified.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// Use [throttle] to specify the minimum interval between queries. It can
  /// also be set to `null`, in which case the stream will only be throttled
  /// when its subscription is paused.
  ///
  /// Source tables are collected from the queried table, [where], [orderBy],
  /// [orderByList], and the [include] graph. [alsoTriggerOnTables] is added
  /// to that set. Pass [Table] instances such as `BoardTask.t`.
  ///
  /// Raw [Expression] SQL is not inspected. Tables referenced only in raw
  /// SQL must be passed via [alsoTriggerOnTables].
  ///
  /// The stream always reads committed state and never joins an ambient
  /// [Transaction]. Emissions for a write fire after that write commits.
  ///
  /// Currently only supported on SQLite. Calling this method on PostgreSQL
  /// throws an [UnsupportedError].
  ///
  /// ```dart
  /// var subscription = Persons.db.watch(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// ).listen((persons) {
  ///   // Handle the latest matching rows.
  /// });
  /// ```
  _ida.Stream<List<BoardTask>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BoardTaskTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BoardTaskTable>? orderBy,
    _is.OrderByListBuilder<BoardTaskTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<BoardTask>(
      where: where?.call(BoardTask.t),
      orderBy: orderBy?.call(BoardTask.t),
      orderByList: orderByList?.call(BoardTask.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [BoardTask] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<BoardTask?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BoardTaskTable>? where,
    int? offset,
    _is.OrderByBuilder<BoardTaskTable>? orderBy,
    _is.OrderByListBuilder<BoardTaskTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BoardTask>(
      where: where?.call(BoardTask.t),
      orderBy: orderBy?.call(BoardTask.t),
      orderByList: orderByList?.call(BoardTask.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BoardTask] by its [id] or null if no such row exists.
  Future<BoardTask?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BoardTask>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BoardTask]s in the list and returns the inserted rows.
  ///
  /// The returned [BoardTask]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardTask>> insert(
    _is.DatabaseSession session,
    List<BoardTask> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BoardTask>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BoardTask] and returns the inserted row.
  ///
  /// The returned [BoardTask] will have its `id` field set.
  Future<BoardTask> insertRow(
    _is.DatabaseSession session,
    BoardTask row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BoardTask>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BoardTask]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [BoardTask]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardTask>> upsert(
    _is.DatabaseSession session,
    List<BoardTask> rows, {
    required _is.ColumnSelections<BoardTaskTable> conflictColumns,
    _is.ColumnSelections<BoardTaskTable>? updateColumns,
    _is.WhereExpressionBuilder<BoardTaskTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BoardTask>(
      rows,
      conflictColumns: conflictColumns(BoardTask.t),
      updateColumns: updateColumns?.call(BoardTask.t),
      updateWhere: updateWhere?.call(BoardTask.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BoardTask] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [BoardTask] will have its `id` field set.
  Future<BoardTask?> upsertRow(
    _is.DatabaseSession session,
    BoardTask row, {
    required _is.ColumnSelections<BoardTaskTable> conflictColumns,
    _is.ColumnSelections<BoardTaskTable>? updateColumns,
    _is.WhereExpressionBuilder<BoardTaskTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BoardTask>(
      row,
      conflictColumns: conflictColumns(BoardTask.t),
      updateColumns: updateColumns?.call(BoardTask.t),
      updateWhere: updateWhere?.call(BoardTask.t),
      transaction: transaction,
    );
  }

  /// Updates all [BoardTask]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardTask>> update(
    _is.DatabaseSession session,
    List<BoardTask> rows, {
    _is.ColumnSelections<BoardTaskTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BoardTask>(
      rows,
      columns: columns?.call(BoardTask.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BoardTask]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BoardTask> updateRow(
    _is.DatabaseSession session,
    BoardTask row, {
    _is.ColumnSelections<BoardTaskTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BoardTask>(
      row,
      columns: columns?.call(BoardTask.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BoardTask] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BoardTask?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<BoardTaskUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BoardTask>(
      id,
      columnValues: columnValues(BoardTask.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BoardTask]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardTask>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BoardTaskUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<BoardTaskTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BoardTaskTable>? orderBy,
    _is.OrderByListBuilder<BoardTaskTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BoardTask>(
      columnValues: columnValues(BoardTask.t.updateTable),
      where: where(BoardTask.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BoardTask.t),
      orderByList: orderByList?.call(BoardTask.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BoardTask]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardTask>> delete(
    _is.DatabaseSession session,
    List<BoardTask> rows, {
    _is.OrderByBuilder<BoardTaskTable>? orderBy,
    _is.OrderByListBuilder<BoardTaskTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BoardTask>(
      rows,
      orderBy: orderBy?.call(BoardTask.t),
      orderByList: orderByList?.call(BoardTask.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BoardTask].
  Future<BoardTask> deleteRow(
    _is.DatabaseSession session,
    BoardTask row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BoardTask>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BoardTask>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BoardTaskTable> where,
    _is.OrderByBuilder<BoardTaskTable>? orderBy,
    _is.OrderByListBuilder<BoardTaskTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BoardTask>(
      where: where(BoardTask.t),
      orderBy: orderBy?.call(BoardTask.t),
      orderByList: orderByList?.call(BoardTask.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BoardTaskTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BoardTask>(
      where: where?.call(BoardTask.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BoardTask] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BoardTaskTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BoardTask>(
      where: where(BoardTask.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
