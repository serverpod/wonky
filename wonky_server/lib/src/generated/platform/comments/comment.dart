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
import '../../platform/comments/comment_system_event.dart' as _ikzs0dm0;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;

abstract class Comment
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
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
    _is.UuidValue? uuid,
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
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['uuid']),
      authorId: jsonSerialization['authorId'] as int?,
      authorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['authorKind'] as String),
      ),
      body: jsonSerialization['body'] as String,
      mentions: _il4umwa0.Protocol().deserialize<List<int>>(
        jsonSerialization['mentions'],
      ),
      reactions: jsonSerialization['reactions'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      editedAt: jsonSerialization['editedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['editedAt']),
      deletedAt: jsonSerialization['deletedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['deletedAt']),
      systemEvent: jsonSerialization['systemEvent'] == null
          ? null
          : _ikzs0dm0.CommentSystemEvent.fromJson(
              (jsonSerialization['systemEvent'] as String),
            ),
      publicationId: jsonSerialization['publicationId'] as int?,
    );
  }

  static final t = CommentTable();

  static const db = CommentRepository._();

  @override
  int? id;

  int threadId;

  /// Client-supplied id for idempotent replies (optional).
  _is.UuidValue? uuid;

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

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Comment]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Comment copyWith({
    int? id,
    int? threadId,
    _is.UuidValue? uuid = const _is.$UndefinedUuidValue(),
    int? authorId,
    _ipbpecg8.ActorKind? authorKind,
    String? body,
    List<int>? mentions,
    String? reactions,
    DateTime? createdAt,
    DateTime? editedAt = const _is.$UndefinedDateTime(),
    DateTime? deletedAt = const _is.$UndefinedDateTime(),
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

  static CommentInclude include() {
    return CommentInclude._();
  }

  static CommentIncludeList includeList({
    _is.WhereExpressionBuilder<CommentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CommentTable>? orderBy,
    _is.OrderByListBuilder<CommentTable>? orderByList,
    CommentInclude? include,
  }) {
    return CommentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Comment.t),
      orderByList: orderByList?.call(Comment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CommentImpl extends Comment {
  _CommentImpl({
    int? id,
    required int threadId,
    _is.UuidValue? uuid,
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
  @_is.useResult
  @override
  Comment copyWith({
    Object? id = _Undefined,
    int? threadId,
    _is.UuidValue? uuid = const _is.$UndefinedUuidValue(),
    Object? authorId = _Undefined,
    _ipbpecg8.ActorKind? authorKind,
    String? body,
    List<int>? mentions,
    String? reactions,
    DateTime? createdAt,
    DateTime? editedAt = const _is.$UndefinedDateTime(),
    DateTime? deletedAt = const _is.$UndefinedDateTime(),
    Object? systemEvent = _Undefined,
    Object? publicationId = _Undefined,
  }) {
    return Comment(
      id: id is int? ? id : this.id,
      threadId: threadId ?? this.threadId,
      uuid: uuid is _is.UndefinedSentinel ? this.uuid : uuid,
      authorId: authorId is int? ? authorId : this.authorId,
      authorKind: authorKind ?? this.authorKind,
      body: body ?? this.body,
      mentions: mentions ?? this.mentions.map((e0) => e0).toList(),
      reactions: reactions ?? this.reactions,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt is _is.UndefinedSentinel ? this.editedAt : editedAt,
      deletedAt: deletedAt is _is.UndefinedSentinel
          ? this.deletedAt
          : deletedAt,
      systemEvent: systemEvent is _ikzs0dm0.CommentSystemEvent?
          ? systemEvent
          : this.systemEvent,
      publicationId: publicationId is int? ? publicationId : this.publicationId,
    );
  }
}

class CommentUpdateTable extends _is.UpdateTable<CommentTable> {
  CommentUpdateTable(super.table);

  _is.ColumnValue<int, int> threadId(int value) => _is.ColumnValue(
    table.threadId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> uuid(_is.UuidValue? value) =>
      _is.ColumnValue(
        table.uuid,
        value,
      );

  _is.ColumnValue<int, int> authorId(int? value) => _is.ColumnValue(
    table.authorId,
    value,
  );

  _is.ColumnValue<_ipbpecg8.ActorKind, _ipbpecg8.ActorKind> authorKind(
    _ipbpecg8.ActorKind value,
  ) => _is.ColumnValue(
    table.authorKind,
    value,
  );

  _is.ColumnValue<String, String> body(String value) => _is.ColumnValue(
    table.body,
    value,
  );

  _is.ColumnValue<List<int>, List<int>> mentions(List<int> value) =>
      _is.ColumnValue(
        table.mentions,
        value,
      );

  _is.ColumnValue<String, String> reactions(String value) => _is.ColumnValue(
    table.reactions,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> editedAt(DateTime? value) =>
      _is.ColumnValue(
        table.editedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> deletedAt(DateTime? value) =>
      _is.ColumnValue(
        table.deletedAt,
        value,
      );

  _is.ColumnValue<_ikzs0dm0.CommentSystemEvent, _ikzs0dm0.CommentSystemEvent>
  systemEvent(_ikzs0dm0.CommentSystemEvent? value) => _is.ColumnValue(
    table.systemEvent,
    value,
  );

  _is.ColumnValue<int, int> publicationId(int? value) => _is.ColumnValue(
    table.publicationId,
    value,
  );
}

class CommentTable extends _is.Table<int?> {
  CommentTable({super.tableRelation}) : super(tableName: 'comment') {
    updateTable = CommentUpdateTable(this);
    threadId = _is.ColumnInt(
      'threadId',
      this,
    );
    uuid = _is.ColumnUuid(
      'uuid',
      this,
    );
    authorId = _is.ColumnInt(
      'authorId',
      this,
    );
    authorKind = _is.ColumnEnum(
      'authorKind',
      this,
      _is.EnumSerialization.byName,
    );
    body = _is.ColumnString(
      'body',
      this,
    );
    mentions = _is.ColumnSerializable<List<int>>(
      'mentions',
      this,
    );
    reactions = _is.ColumnString(
      'reactions',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    editedAt = _is.ColumnDateTime(
      'editedAt',
      this,
    );
    deletedAt = _is.ColumnDateTime(
      'deletedAt',
      this,
    );
    systemEvent = _is.ColumnEnum(
      'systemEvent',
      this,
      _is.EnumSerialization.byName,
    );
    publicationId = _is.ColumnInt(
      'publicationId',
      this,
    );
  }

  late final CommentUpdateTable updateTable;

  late final _is.ColumnInt threadId;

  /// Client-supplied id for idempotent replies (optional).
  late final _is.ColumnUuid uuid;

  /// Null for system comments.
  late final _is.ColumnInt authorId;

  late final _is.ColumnEnum<_ipbpecg8.ActorKind> authorKind;

  /// Markdown (inline subset).
  late final _is.ColumnString body;

  /// UserProfile ids mentioned in [body].
  late final _is.ColumnSerializable<List<int>> mentions;

  /// JSON {emoji: [userId]}.
  late final _is.ColumnString reactions;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime editedAt;

  /// Soft delete: shown as "Comment deleted".
  late final _is.ColumnDateTime deletedAt;

  late final _is.ColumnEnum<_ikzs0dm0.CommentSystemEvent> systemEvent;

  /// (M14) A publication's message (authorKind system), specs/18 §5.2.
  late final _is.ColumnInt publicationId;

  @override
  List<_is.Column> get columns => [
    id,
    threadId,
    uuid,
    authorId,
    authorKind,
    body,
    mentions,
    reactions,
    createdAt,
    editedAt,
    deletedAt,
    systemEvent,
    publicationId,
  ];
}

class CommentInclude extends _is.IncludeObject {
  CommentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Comment.t;
}

class CommentIncludeList extends _is.IncludeList {
  CommentIncludeList._({
    _is.WhereExpressionBuilder<CommentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Comment.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Comment.t;
}

class CommentRepository {
  const CommentRepository._();

  /// Returns a list of [Comment]s matching the given query parameters.
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
  Future<List<Comment>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CommentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CommentTable>? orderBy,
    _is.OrderByListBuilder<CommentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Comment>(
      where: where?.call(Comment.t),
      orderBy: orderBy?.call(Comment.t),
      orderByList: orderByList?.call(Comment.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Comment]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Comment.t`.
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
  _ida.Stream<List<Comment>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CommentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CommentTable>? orderBy,
    _is.OrderByListBuilder<CommentTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Comment>(
      where: where?.call(Comment.t),
      orderBy: orderBy?.call(Comment.t),
      orderByList: orderByList?.call(Comment.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Comment] matching the given query parameters.
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
  Future<Comment?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CommentTable>? where,
    int? offset,
    _is.OrderByBuilder<CommentTable>? orderBy,
    _is.OrderByListBuilder<CommentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Comment>(
      where: where?.call(Comment.t),
      orderBy: orderBy?.call(Comment.t),
      orderByList: orderByList?.call(Comment.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Comment] by its [id] or null if no such row exists.
  Future<Comment?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Comment>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Comment]s in the list and returns the inserted rows.
  ///
  /// The returned [Comment]s will have their `id` fields set.
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
  Future<List<Comment>> insert(
    _is.DatabaseSession session,
    List<Comment> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Comment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Comment] and returns the inserted row.
  ///
  /// The returned [Comment] will have its `id` field set.
  Future<Comment> insertRow(
    _is.DatabaseSession session,
    Comment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Comment>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Comment]s in the list and returns the resulting rows.
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
  /// The returned [Comment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Comment>> upsert(
    _is.DatabaseSession session,
    List<Comment> rows, {
    required _is.ColumnSelections<CommentTable> conflictColumns,
    _is.ColumnSelections<CommentTable>? updateColumns,
    _is.WhereExpressionBuilder<CommentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Comment>(
      rows,
      conflictColumns: conflictColumns(Comment.t),
      updateColumns: updateColumns?.call(Comment.t),
      updateWhere: updateWhere?.call(Comment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Comment] and returns the resulting row.
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
  /// The returned [Comment] will have its `id` field set.
  Future<Comment?> upsertRow(
    _is.DatabaseSession session,
    Comment row, {
    required _is.ColumnSelections<CommentTable> conflictColumns,
    _is.ColumnSelections<CommentTable>? updateColumns,
    _is.WhereExpressionBuilder<CommentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Comment>(
      row,
      conflictColumns: conflictColumns(Comment.t),
      updateColumns: updateColumns?.call(Comment.t),
      updateWhere: updateWhere?.call(Comment.t),
      transaction: transaction,
    );
  }

  /// Updates all [Comment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Comment>> update(
    _is.DatabaseSession session,
    List<Comment> rows, {
    _is.ColumnSelections<CommentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Comment>(
      rows,
      columns: columns?.call(Comment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Comment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Comment> updateRow(
    _is.DatabaseSession session,
    Comment row, {
    _is.ColumnSelections<CommentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Comment>(
      row,
      columns: columns?.call(Comment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Comment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Comment?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CommentUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Comment>(
      id,
      columnValues: columnValues(Comment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Comment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Comment>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CommentUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CommentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CommentTable>? orderBy,
    _is.OrderByListBuilder<CommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Comment>(
      columnValues: columnValues(Comment.t.updateTable),
      where: where(Comment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Comment.t),
      orderByList: orderByList?.call(Comment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Comment]s in the list and returns the deleted rows.
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
  Future<List<Comment>> delete(
    _is.DatabaseSession session,
    List<Comment> rows, {
    _is.OrderByBuilder<CommentTable>? orderBy,
    _is.OrderByListBuilder<CommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Comment>(
      rows,
      orderBy: orderBy?.call(Comment.t),
      orderByList: orderByList?.call(Comment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Comment].
  Future<Comment> deleteRow(
    _is.DatabaseSession session,
    Comment row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Comment>(
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
  Future<List<Comment>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CommentTable> where,
    _is.OrderByBuilder<CommentTable>? orderBy,
    _is.OrderByListBuilder<CommentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Comment>(
      where: where(Comment.t),
      orderBy: orderBy?.call(Comment.t),
      orderByList: orderByList?.call(Comment.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CommentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Comment>(
      where: where?.call(Comment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Comment] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CommentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Comment>(
      where: where(Comment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
