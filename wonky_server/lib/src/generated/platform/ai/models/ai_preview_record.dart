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

/// A Suggest-mode AI changes preview persisted in the database (Sheets 12
/// §6.3, Slides 11 §6.3), so any server instance can show, apply or
/// discard it until it expires (30 min). `fileUuid` is the RevLog file uuid
/// of the spreadsheet or deck; `previewJson` is a `SheetsAiPreview` or a
/// `SlidesAiPreview`.
abstract class AiPreviewRecord
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AiPreviewRecord._({
    this.id,
    required this.previewId,
    required this.userId,
    required this.fileUuid,
    required this.previewJson,
    required this.changesJson,
    required this.createdAt,
    required this.expiresAt,
  });

  factory AiPreviewRecord({
    int? id,
    required String previewId,
    required int userId,
    required _is.UuidValue fileUuid,
    required String previewJson,
    required String changesJson,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) = _AiPreviewRecordImpl;

  factory AiPreviewRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiPreviewRecord(
      id: jsonSerialization['id'] as int?,
      previewId: jsonSerialization['previewId'] as String,
      userId: jsonSerialization['userId'] as int,
      fileUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['fileUuid'],
      ),
      previewJson: jsonSerialization['previewJson'] as String,
      changesJson: jsonSerialization['changesJson'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
    );
  }

  static final t = AiPreviewRecordTable();

  static const db = AiPreviewRecordRepository._();

  @override
  int? id;

  String previewId;

  int userId;

  _is.UuidValue fileUuid;

  /// The preview shown by the dialog (JSON).
  String previewJson;

  /// gzip+base64 JSON of the recorded row changes per call.
  String changesJson;

  DateTime createdAt;

  DateTime expiresAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AiPreviewRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AiPreviewRecord copyWith({
    int? id,
    String? previewId,
    int? userId,
    _is.UuidValue? fileUuid,
    String? previewJson,
    String? changesJson,
    DateTime? createdAt,
    DateTime? expiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiPreviewRecord',
      if (id != null) 'id': id,
      'previewId': previewId,
      'userId': userId,
      'fileUuid': fileUuid.toJson(),
      'previewJson': previewJson,
      'changesJson': changesJson,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AiPreviewRecordInclude include() {
    return AiPreviewRecordInclude._();
  }

  static AiPreviewRecordIncludeList includeList({
    _is.WhereExpressionBuilder<AiPreviewRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiPreviewRecordTable>? orderBy,
    _is.OrderByListBuilder<AiPreviewRecordTable>? orderByList,
    AiPreviewRecordInclude? include,
  }) {
    return AiPreviewRecordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiPreviewRecord.t),
      orderByList: orderByList?.call(AiPreviewRecord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiPreviewRecordImpl extends AiPreviewRecord {
  _AiPreviewRecordImpl({
    int? id,
    required String previewId,
    required int userId,
    required _is.UuidValue fileUuid,
    required String previewJson,
    required String changesJson,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) : super._(
         id: id,
         previewId: previewId,
         userId: userId,
         fileUuid: fileUuid,
         previewJson: previewJson,
         changesJson: changesJson,
         createdAt: createdAt,
         expiresAt: expiresAt,
       );

  /// Returns a shallow copy of this [AiPreviewRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AiPreviewRecord copyWith({
    Object? id = _Undefined,
    String? previewId,
    int? userId,
    _is.UuidValue? fileUuid,
    String? previewJson,
    String? changesJson,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return AiPreviewRecord(
      id: id is int? ? id : this.id,
      previewId: previewId ?? this.previewId,
      userId: userId ?? this.userId,
      fileUuid: fileUuid ?? this.fileUuid,
      previewJson: previewJson ?? this.previewJson,
      changesJson: changesJson ?? this.changesJson,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class AiPreviewRecordUpdateTable extends _is.UpdateTable<AiPreviewRecordTable> {
  AiPreviewRecordUpdateTable(super.table);

  _is.ColumnValue<String, String> previewId(String value) => _is.ColumnValue(
    table.previewId,
    value,
  );

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> fileUuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.fileUuid,
        value,
      );

  _is.ColumnValue<String, String> previewJson(String value) => _is.ColumnValue(
    table.previewJson,
    value,
  );

  _is.ColumnValue<String, String> changesJson(String value) => _is.ColumnValue(
    table.changesJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );
}

class AiPreviewRecordTable extends _is.Table<int?> {
  AiPreviewRecordTable({super.tableRelation})
    : super(tableName: 'ai_preview_record') {
    updateTable = AiPreviewRecordUpdateTable(this);
    previewId = _is.ColumnString(
      'previewId',
      this,
    );
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    fileUuid = _is.ColumnUuid(
      'fileUuid',
      this,
    );
    previewJson = _is.ColumnString(
      'previewJson',
      this,
    );
    changesJson = _is.ColumnString(
      'changesJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
  }

  late final AiPreviewRecordUpdateTable updateTable;

  late final _is.ColumnString previewId;

  late final _is.ColumnInt userId;

  late final _is.ColumnUuid fileUuid;

  /// The preview shown by the dialog (JSON).
  late final _is.ColumnString previewJson;

  /// gzip+base64 JSON of the recorded row changes per call.
  late final _is.ColumnString changesJson;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime expiresAt;

  @override
  List<_is.Column> get columns => [
    id,
    previewId,
    userId,
    fileUuid,
    previewJson,
    changesJson,
    createdAt,
    expiresAt,
  ];
}

class AiPreviewRecordInclude extends _is.IncludeObject {
  AiPreviewRecordInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AiPreviewRecord.t;
}

class AiPreviewRecordIncludeList extends _is.IncludeList {
  AiPreviewRecordIncludeList._({
    _is.WhereExpressionBuilder<AiPreviewRecordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AiPreviewRecord.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AiPreviewRecord.t;
}

class AiPreviewRecordRepository {
  const AiPreviewRecordRepository._();

  /// Returns a list of [AiPreviewRecord]s matching the given query parameters.
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
  Future<List<AiPreviewRecord>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiPreviewRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiPreviewRecordTable>? orderBy,
    _is.OrderByListBuilder<AiPreviewRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AiPreviewRecord>(
      where: where?.call(AiPreviewRecord.t),
      orderBy: orderBy?.call(AiPreviewRecord.t),
      orderByList: orderByList?.call(AiPreviewRecord.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [AiPreviewRecord]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `AiPreviewRecord.t`.
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
  _ida.Stream<List<AiPreviewRecord>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiPreviewRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiPreviewRecordTable>? orderBy,
    _is.OrderByListBuilder<AiPreviewRecordTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<AiPreviewRecord>(
      where: where?.call(AiPreviewRecord.t),
      orderBy: orderBy?.call(AiPreviewRecord.t),
      orderByList: orderByList?.call(AiPreviewRecord.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [AiPreviewRecord] matching the given query parameters.
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
  Future<AiPreviewRecord?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiPreviewRecordTable>? where,
    int? offset,
    _is.OrderByBuilder<AiPreviewRecordTable>? orderBy,
    _is.OrderByListBuilder<AiPreviewRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AiPreviewRecord>(
      where: where?.call(AiPreviewRecord.t),
      orderBy: orderBy?.call(AiPreviewRecord.t),
      orderByList: orderByList?.call(AiPreviewRecord.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AiPreviewRecord] by its [id] or null if no such row exists.
  Future<AiPreviewRecord?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AiPreviewRecord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AiPreviewRecord]s in the list and returns the inserted rows.
  ///
  /// The returned [AiPreviewRecord]s will have their `id` fields set.
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
  Future<List<AiPreviewRecord>> insert(
    _is.DatabaseSession session,
    List<AiPreviewRecord> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AiPreviewRecord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AiPreviewRecord] and returns the inserted row.
  ///
  /// The returned [AiPreviewRecord] will have its `id` field set.
  Future<AiPreviewRecord> insertRow(
    _is.DatabaseSession session,
    AiPreviewRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AiPreviewRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AiPreviewRecord]s in the list and returns the resulting rows.
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
  /// The returned [AiPreviewRecord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiPreviewRecord>> upsert(
    _is.DatabaseSession session,
    List<AiPreviewRecord> rows, {
    required _is.ColumnSelections<AiPreviewRecordTable> conflictColumns,
    _is.ColumnSelections<AiPreviewRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<AiPreviewRecordTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AiPreviewRecord>(
      rows,
      conflictColumns: conflictColumns(AiPreviewRecord.t),
      updateColumns: updateColumns?.call(AiPreviewRecord.t),
      updateWhere: updateWhere?.call(AiPreviewRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AiPreviewRecord] and returns the resulting row.
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
  /// The returned [AiPreviewRecord] will have its `id` field set.
  Future<AiPreviewRecord?> upsertRow(
    _is.DatabaseSession session,
    AiPreviewRecord row, {
    required _is.ColumnSelections<AiPreviewRecordTable> conflictColumns,
    _is.ColumnSelections<AiPreviewRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<AiPreviewRecordTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AiPreviewRecord>(
      row,
      conflictColumns: conflictColumns(AiPreviewRecord.t),
      updateColumns: updateColumns?.call(AiPreviewRecord.t),
      updateWhere: updateWhere?.call(AiPreviewRecord.t),
      transaction: transaction,
    );
  }

  /// Updates all [AiPreviewRecord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiPreviewRecord>> update(
    _is.DatabaseSession session,
    List<AiPreviewRecord> rows, {
    _is.ColumnSelections<AiPreviewRecordTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AiPreviewRecord>(
      rows,
      columns: columns?.call(AiPreviewRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AiPreviewRecord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AiPreviewRecord> updateRow(
    _is.DatabaseSession session,
    AiPreviewRecord row, {
    _is.ColumnSelections<AiPreviewRecordTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AiPreviewRecord>(
      row,
      columns: columns?.call(AiPreviewRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AiPreviewRecord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AiPreviewRecord?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AiPreviewRecordUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AiPreviewRecord>(
      id,
      columnValues: columnValues(AiPreviewRecord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AiPreviewRecord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiPreviewRecord>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AiPreviewRecordUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<AiPreviewRecordTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiPreviewRecordTable>? orderBy,
    _is.OrderByListBuilder<AiPreviewRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AiPreviewRecord>(
      columnValues: columnValues(AiPreviewRecord.t.updateTable),
      where: where(AiPreviewRecord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiPreviewRecord.t),
      orderByList: orderByList?.call(AiPreviewRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AiPreviewRecord]s in the list and returns the deleted rows.
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
  Future<List<AiPreviewRecord>> delete(
    _is.DatabaseSession session,
    List<AiPreviewRecord> rows, {
    _is.OrderByBuilder<AiPreviewRecordTable>? orderBy,
    _is.OrderByListBuilder<AiPreviewRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AiPreviewRecord>(
      rows,
      orderBy: orderBy?.call(AiPreviewRecord.t),
      orderByList: orderByList?.call(AiPreviewRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AiPreviewRecord].
  Future<AiPreviewRecord> deleteRow(
    _is.DatabaseSession session,
    AiPreviewRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AiPreviewRecord>(
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
  Future<List<AiPreviewRecord>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AiPreviewRecordTable> where,
    _is.OrderByBuilder<AiPreviewRecordTable>? orderBy,
    _is.OrderByListBuilder<AiPreviewRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AiPreviewRecord>(
      where: where(AiPreviewRecord.t),
      orderBy: orderBy?.call(AiPreviewRecord.t),
      orderByList: orderByList?.call(AiPreviewRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiPreviewRecordTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AiPreviewRecord>(
      where: where?.call(AiPreviewRecord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AiPreviewRecord] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AiPreviewRecordTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AiPreviewRecord>(
      where: where(AiPreviewRecord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
