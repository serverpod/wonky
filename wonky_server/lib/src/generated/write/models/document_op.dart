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
import '../../platform/common/actor_kind.dart' as _ipbpecg8;
import '../../write/models/document_op_kind.dart' as _iymqng84;

/// One applied operation (Write 02 §3).
abstract class DocumentOp
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DocumentOp._({
    this.id,
    required this.documentId,
    required this.revision,
    required this.clientOpId,
    this.authorId,
    required this.actorKind,
    this.sessionId,
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
    required _is.UuidValue clientOpId,
    int? authorId,
    required _ipbpecg8.ActorKind actorKind,
    String? sessionId,
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
      clientOpId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['clientOpId'],
      ),
      authorId: jsonSerialization['authorId'] as int?,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      sessionId: jsonSerialization['sessionId'] as String?,
      kind: _iymqng84.DocumentOpKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      baseRevision: jsonSerialization['baseRevision'] as int,
      deltaJson: jsonSerialization['deltaJson'] as String,
      inverseJson: jsonSerialization['inverseJson'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = DocumentOpTable();

  static const db = DocumentOpRepository._();

  @override
  int? id;

  int documentId;

  /// Head after applying this op (1-based).
  int revision;

  _is.UuidValue clientOpId;

  int? authorId;

  _ipbpecg8.ActorKind actorKind;

  String? sessionId;

  _iymqng84.DocumentOpKind kind;

  int baseRevision;

  /// The transformed op as applied.
  String deltaJson;

  /// Inverse against the pre-op document.
  String inverseJson;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DocumentOp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DocumentOp copyWith({
    int? id,
    int? documentId,
    int? revision,
    _is.UuidValue? clientOpId,
    int? authorId,
    _ipbpecg8.ActorKind? actorKind,
    String? sessionId,
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
      'kind': kind.toJson(),
      'baseRevision': baseRevision,
      'deltaJson': deltaJson,
      'inverseJson': inverseJson,
      'createdAt': createdAt.toJson(),
    };
  }

  static DocumentOpInclude include() {
    return DocumentOpInclude._();
  }

  static DocumentOpIncludeList includeList({
    _is.WhereExpressionBuilder<DocumentOpTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentOpTable>? orderBy,
    _is.OrderByListBuilder<DocumentOpTable>? orderByList,
    DocumentOpInclude? include,
  }) {
    return DocumentOpIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentOp.t),
      orderByList: orderByList?.call(DocumentOp.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentOpImpl extends DocumentOp {
  _DocumentOpImpl({
    int? id,
    required int documentId,
    required int revision,
    required _is.UuidValue clientOpId,
    int? authorId,
    required _ipbpecg8.ActorKind actorKind,
    String? sessionId,
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
         kind: kind,
         baseRevision: baseRevision,
         deltaJson: deltaJson,
         inverseJson: inverseJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DocumentOp]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DocumentOp copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? revision,
    _is.UuidValue? clientOpId,
    Object? authorId = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    Object? sessionId = _Undefined,
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
      kind: kind ?? this.kind,
      baseRevision: baseRevision ?? this.baseRevision,
      deltaJson: deltaJson ?? this.deltaJson,
      inverseJson: inverseJson ?? this.inverseJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DocumentOpUpdateTable extends _is.UpdateTable<DocumentOpTable> {
  DocumentOpUpdateTable(super.table);

  _is.ColumnValue<int, int> documentId(int value) => _is.ColumnValue(
    table.documentId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> clientOpId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.clientOpId,
    value,
  );

  _is.ColumnValue<int, int> authorId(int? value) => _is.ColumnValue(
    table.authorId,
    value,
  );

  _is.ColumnValue<_ipbpecg8.ActorKind, _ipbpecg8.ActorKind> actorKind(
    _ipbpecg8.ActorKind value,
  ) => _is.ColumnValue(
    table.actorKind,
    value,
  );

  _is.ColumnValue<String, String> sessionId(String? value) => _is.ColumnValue(
    table.sessionId,
    value,
  );

  _is.ColumnValue<_iymqng84.DocumentOpKind, _iymqng84.DocumentOpKind> kind(
    _iymqng84.DocumentOpKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<int, int> baseRevision(int value) => _is.ColumnValue(
    table.baseRevision,
    value,
  );

  _is.ColumnValue<String, String> deltaJson(String value) => _is.ColumnValue(
    table.deltaJson,
    value,
  );

  _is.ColumnValue<String, String> inverseJson(String value) => _is.ColumnValue(
    table.inverseJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DocumentOpTable extends _is.Table<int?> {
  DocumentOpTable({super.tableRelation}) : super(tableName: 'document_op') {
    updateTable = DocumentOpUpdateTable(this);
    documentId = _is.ColumnInt(
      'documentId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    clientOpId = _is.ColumnUuid(
      'clientOpId',
      this,
    );
    authorId = _is.ColumnInt(
      'authorId',
      this,
    );
    actorKind = _is.ColumnEnum(
      'actorKind',
      this,
      _is.EnumSerialization.byName,
    );
    sessionId = _is.ColumnString(
      'sessionId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    baseRevision = _is.ColumnInt(
      'baseRevision',
      this,
    );
    deltaJson = _is.ColumnString(
      'deltaJson',
      this,
    );
    inverseJson = _is.ColumnString(
      'inverseJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DocumentOpUpdateTable updateTable;

  late final _is.ColumnInt documentId;

  /// Head after applying this op (1-based).
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid clientOpId;

  late final _is.ColumnInt authorId;

  late final _is.ColumnEnum<_ipbpecg8.ActorKind> actorKind;

  late final _is.ColumnString sessionId;

  late final _is.ColumnEnum<_iymqng84.DocumentOpKind> kind;

  late final _is.ColumnInt baseRevision;

  /// The transformed op as applied.
  late final _is.ColumnString deltaJson;

  /// Inverse against the pre-op document.
  late final _is.ColumnString inverseJson;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    documentId,
    revision,
    clientOpId,
    authorId,
    actorKind,
    sessionId,
    kind,
    baseRevision,
    deltaJson,
    inverseJson,
    createdAt,
  ];
}

class DocumentOpInclude extends _is.IncludeObject {
  DocumentOpInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DocumentOp.t;
}

class DocumentOpIncludeList extends _is.IncludeList {
  DocumentOpIncludeList._({
    _is.WhereExpressionBuilder<DocumentOpTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DocumentOp.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DocumentOp.t;
}

class DocumentOpRepository {
  const DocumentOpRepository._();

  /// Returns a list of [DocumentOp]s matching the given query parameters.
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
  Future<List<DocumentOp>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentOpTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentOpTable>? orderBy,
    _is.OrderByListBuilder<DocumentOpTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DocumentOp>(
      where: where?.call(DocumentOp.t),
      orderBy: orderBy?.call(DocumentOp.t),
      orderByList: orderByList?.call(DocumentOp.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DocumentOp]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DocumentOp.t`.
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
  _ida.Stream<List<DocumentOp>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentOpTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentOpTable>? orderBy,
    _is.OrderByListBuilder<DocumentOpTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DocumentOp>(
      where: where?.call(DocumentOp.t),
      orderBy: orderBy?.call(DocumentOp.t),
      orderByList: orderByList?.call(DocumentOp.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DocumentOp] matching the given query parameters.
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
  Future<DocumentOp?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentOpTable>? where,
    int? offset,
    _is.OrderByBuilder<DocumentOpTable>? orderBy,
    _is.OrderByListBuilder<DocumentOpTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DocumentOp>(
      where: where?.call(DocumentOp.t),
      orderBy: orderBy?.call(DocumentOp.t),
      orderByList: orderByList?.call(DocumentOp.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DocumentOp] by its [id] or null if no such row exists.
  Future<DocumentOp?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DocumentOp>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DocumentOp]s in the list and returns the inserted rows.
  ///
  /// The returned [DocumentOp]s will have their `id` fields set.
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
  Future<List<DocumentOp>> insert(
    _is.DatabaseSession session,
    List<DocumentOp> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DocumentOp>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DocumentOp] and returns the inserted row.
  ///
  /// The returned [DocumentOp] will have its `id` field set.
  Future<DocumentOp> insertRow(
    _is.DatabaseSession session,
    DocumentOp row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DocumentOp>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DocumentOp]s in the list and returns the resulting rows.
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
  /// The returned [DocumentOp]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentOp>> upsert(
    _is.DatabaseSession session,
    List<DocumentOp> rows, {
    required _is.ColumnSelections<DocumentOpTable> conflictColumns,
    _is.ColumnSelections<DocumentOpTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentOpTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DocumentOp>(
      rows,
      conflictColumns: conflictColumns(DocumentOp.t),
      updateColumns: updateColumns?.call(DocumentOp.t),
      updateWhere: updateWhere?.call(DocumentOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DocumentOp] and returns the resulting row.
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
  /// The returned [DocumentOp] will have its `id` field set.
  Future<DocumentOp?> upsertRow(
    _is.DatabaseSession session,
    DocumentOp row, {
    required _is.ColumnSelections<DocumentOpTable> conflictColumns,
    _is.ColumnSelections<DocumentOpTable>? updateColumns,
    _is.WhereExpressionBuilder<DocumentOpTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DocumentOp>(
      row,
      conflictColumns: conflictColumns(DocumentOp.t),
      updateColumns: updateColumns?.call(DocumentOp.t),
      updateWhere: updateWhere?.call(DocumentOp.t),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentOp]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentOp>> update(
    _is.DatabaseSession session,
    List<DocumentOp> rows, {
    _is.ColumnSelections<DocumentOpTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DocumentOp>(
      rows,
      columns: columns?.call(DocumentOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DocumentOp]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DocumentOp> updateRow(
    _is.DatabaseSession session,
    DocumentOp row, {
    _is.ColumnSelections<DocumentOpTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DocumentOp>(
      row,
      columns: columns?.call(DocumentOp.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DocumentOp] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DocumentOp?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DocumentOpUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DocumentOp>(
      id,
      columnValues: columnValues(DocumentOp.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DocumentOp]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DocumentOp>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DocumentOpUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DocumentOpTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DocumentOpTable>? orderBy,
    _is.OrderByListBuilder<DocumentOpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DocumentOp>(
      columnValues: columnValues(DocumentOp.t.updateTable),
      where: where(DocumentOp.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DocumentOp.t),
      orderByList: orderByList?.call(DocumentOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DocumentOp]s in the list and returns the deleted rows.
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
  Future<List<DocumentOp>> delete(
    _is.DatabaseSession session,
    List<DocumentOp> rows, {
    _is.OrderByBuilder<DocumentOpTable>? orderBy,
    _is.OrderByListBuilder<DocumentOpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DocumentOp>(
      rows,
      orderBy: orderBy?.call(DocumentOp.t),
      orderByList: orderByList?.call(DocumentOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DocumentOp].
  Future<DocumentOp> deleteRow(
    _is.DatabaseSession session,
    DocumentOp row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DocumentOp>(
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
  Future<List<DocumentOp>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentOpTable> where,
    _is.OrderByBuilder<DocumentOpTable>? orderBy,
    _is.OrderByListBuilder<DocumentOpTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DocumentOp>(
      where: where(DocumentOp.t),
      orderBy: orderBy?.call(DocumentOp.t),
      orderByList: orderByList?.call(DocumentOp.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DocumentOpTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DocumentOp>(
      where: where?.call(DocumentOp.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DocumentOp] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DocumentOpTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DocumentOp>(
      where: where(DocumentOp.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
