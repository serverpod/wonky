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

/// Cell value history kept after ChangeLog pruning (Sheets 10 §6), latest
/// 100 per cell.
abstract class CellHistory
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  CellHistory._({
    this.id,
    required this.fileUuid,
    required this.sheetId,
    required this.rowId,
    required this.colId,
    required this.revision,
    required this.userUuid,
    required this.actorKind,
    required this.label,
    required this.at,
    this.before,
    this.after,
  });

  factory CellHistory({
    int? id,
    required _is.UuidValue fileUuid,
    required _is.UuidValue sheetId,
    required _is.UuidValue rowId,
    required _is.UuidValue colId,
    required int revision,
    required _is.UuidValue userUuid,
    required _ipbpecg8.ActorKind actorKind,
    required String label,
    required DateTime at,
    String? before,
    String? after,
  }) = _CellHistoryImpl;

  factory CellHistory.fromJson(Map<String, dynamic> jsonSerialization) {
    return CellHistory(
      id: jsonSerialization['id'] as int?,
      fileUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['fileUuid'],
      ),
      sheetId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['sheetId'],
      ),
      rowId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['rowId']),
      colId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['colId']),
      revision: jsonSerialization['revision'] as int,
      userUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['userUuid'],
      ),
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      label: jsonSerialization['label'] as String,
      at: _is.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
      before: jsonSerialization['before'] as String?,
      after: jsonSerialization['after'] as String?,
    );
  }

  static final t = CellHistoryTable();

  static const db = CellHistoryRepository._();

  @override
  int? id;

  _is.UuidValue fileUuid;

  _is.UuidValue sheetId;

  _is.UuidValue rowId;

  _is.UuidValue colId;

  /// The op that wrote the value.
  int revision;

  _is.UuidValue userUuid;

  _ipbpecg8.ActorKind actorKind;

  String label;

  DateTime at;

  String? before;

  String? after;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [CellHistory]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CellHistory copyWith({
    int? id,
    _is.UuidValue? fileUuid,
    _is.UuidValue? sheetId,
    _is.UuidValue? rowId,
    _is.UuidValue? colId,
    int? revision,
    _is.UuidValue? userUuid,
    _ipbpecg8.ActorKind? actorKind,
    String? label,
    DateTime? at,
    String? before,
    String? after,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CellHistory',
      if (id != null) 'id': id,
      'fileUuid': fileUuid.toJson(),
      'sheetId': sheetId.toJson(),
      'rowId': rowId.toJson(),
      'colId': colId.toJson(),
      'revision': revision,
      'userUuid': userUuid.toJson(),
      'actorKind': actorKind.toJson(),
      'label': label,
      'at': at.toJson(),
      if (before != null) 'before': before,
      if (after != null) 'after': after,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static CellHistoryInclude include() {
    return CellHistoryInclude._();
  }

  static CellHistoryIncludeList includeList({
    _is.WhereExpressionBuilder<CellHistoryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CellHistoryTable>? orderBy,
    _is.OrderByListBuilder<CellHistoryTable>? orderByList,
    CellHistoryInclude? include,
  }) {
    return CellHistoryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CellHistory.t),
      orderByList: orderByList?.call(CellHistory.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CellHistoryImpl extends CellHistory {
  _CellHistoryImpl({
    int? id,
    required _is.UuidValue fileUuid,
    required _is.UuidValue sheetId,
    required _is.UuidValue rowId,
    required _is.UuidValue colId,
    required int revision,
    required _is.UuidValue userUuid,
    required _ipbpecg8.ActorKind actorKind,
    required String label,
    required DateTime at,
    String? before,
    String? after,
  }) : super._(
         id: id,
         fileUuid: fileUuid,
         sheetId: sheetId,
         rowId: rowId,
         colId: colId,
         revision: revision,
         userUuid: userUuid,
         actorKind: actorKind,
         label: label,
         at: at,
         before: before,
         after: after,
       );

  /// Returns a shallow copy of this [CellHistory]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CellHistory copyWith({
    Object? id = _Undefined,
    _is.UuidValue? fileUuid,
    _is.UuidValue? sheetId,
    _is.UuidValue? rowId,
    _is.UuidValue? colId,
    int? revision,
    _is.UuidValue? userUuid,
    _ipbpecg8.ActorKind? actorKind,
    String? label,
    DateTime? at,
    Object? before = _Undefined,
    Object? after = _Undefined,
  }) {
    return CellHistory(
      id: id is int? ? id : this.id,
      fileUuid: fileUuid ?? this.fileUuid,
      sheetId: sheetId ?? this.sheetId,
      rowId: rowId ?? this.rowId,
      colId: colId ?? this.colId,
      revision: revision ?? this.revision,
      userUuid: userUuid ?? this.userUuid,
      actorKind: actorKind ?? this.actorKind,
      label: label ?? this.label,
      at: at ?? this.at,
      before: before is String? ? before : this.before,
      after: after is String? ? after : this.after,
    );
  }
}

class CellHistoryUpdateTable extends _is.UpdateTable<CellHistoryTable> {
  CellHistoryUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> fileUuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.fileUuid,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> sheetId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.sheetId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> rowId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.rowId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> colId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.colId,
        value,
      );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> userUuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.userUuid,
        value,
      );

  _is.ColumnValue<_ipbpecg8.ActorKind, _ipbpecg8.ActorKind> actorKind(
    _ipbpecg8.ActorKind value,
  ) => _is.ColumnValue(
    table.actorKind,
    value,
  );

  _is.ColumnValue<String, String> label(String value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> at(DateTime value) => _is.ColumnValue(
    table.at,
    value,
  );

  _is.ColumnValue<String, String> before(String? value) => _is.ColumnValue(
    table.before,
    value,
  );

  _is.ColumnValue<String, String> after(String? value) => _is.ColumnValue(
    table.after,
    value,
  );
}

class CellHistoryTable extends _is.Table<int?> {
  CellHistoryTable({super.tableRelation}) : super(tableName: 'cell_history') {
    updateTable = CellHistoryUpdateTable(this);
    fileUuid = _is.ColumnUuid(
      'fileUuid',
      this,
    );
    sheetId = _is.ColumnUuid(
      'sheetId',
      this,
    );
    rowId = _is.ColumnUuid(
      'rowId',
      this,
    );
    colId = _is.ColumnUuid(
      'colId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
    );
    userUuid = _is.ColumnUuid(
      'userUuid',
      this,
    );
    actorKind = _is.ColumnEnum(
      'actorKind',
      this,
      _is.EnumSerialization.byName,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    at = _is.ColumnDateTime(
      'at',
      this,
    );
    before = _is.ColumnString(
      'before',
      this,
    );
    after = _is.ColumnString(
      'after',
      this,
    );
  }

  late final CellHistoryUpdateTable updateTable;

  late final _is.ColumnUuid fileUuid;

  late final _is.ColumnUuid sheetId;

  late final _is.ColumnUuid rowId;

  late final _is.ColumnUuid colId;

  /// The op that wrote the value.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid userUuid;

  late final _is.ColumnEnum<_ipbpecg8.ActorKind> actorKind;

  late final _is.ColumnString label;

  late final _is.ColumnDateTime at;

  late final _is.ColumnString before;

  late final _is.ColumnString after;

  @override
  List<_is.Column> get columns => [
    id,
    fileUuid,
    sheetId,
    rowId,
    colId,
    revision,
    userUuid,
    actorKind,
    label,
    at,
    before,
    after,
  ];
}

class CellHistoryInclude extends _is.IncludeObject {
  CellHistoryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => CellHistory.t;
}

class CellHistoryIncludeList extends _is.IncludeList {
  CellHistoryIncludeList._({
    _is.WhereExpressionBuilder<CellHistoryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(CellHistory.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => CellHistory.t;
}

class CellHistoryRepository {
  const CellHistoryRepository._();

  /// Returns a list of [CellHistory]s matching the given query parameters.
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
  Future<List<CellHistory>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CellHistoryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CellHistoryTable>? orderBy,
    _is.OrderByListBuilder<CellHistoryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<CellHistory>(
      where: where?.call(CellHistory.t),
      orderBy: orderBy?.call(CellHistory.t),
      orderByList: orderByList?.call(CellHistory.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [CellHistory]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `CellHistory.t`.
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
  _ida.Stream<List<CellHistory>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CellHistoryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CellHistoryTable>? orderBy,
    _is.OrderByListBuilder<CellHistoryTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<CellHistory>(
      where: where?.call(CellHistory.t),
      orderBy: orderBy?.call(CellHistory.t),
      orderByList: orderByList?.call(CellHistory.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [CellHistory] matching the given query parameters.
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
  Future<CellHistory?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CellHistoryTable>? where,
    int? offset,
    _is.OrderByBuilder<CellHistoryTable>? orderBy,
    _is.OrderByListBuilder<CellHistoryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<CellHistory>(
      where: where?.call(CellHistory.t),
      orderBy: orderBy?.call(CellHistory.t),
      orderByList: orderByList?.call(CellHistory.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [CellHistory] by its [id] or null if no such row exists.
  Future<CellHistory?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<CellHistory>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [CellHistory]s in the list and returns the inserted rows.
  ///
  /// The returned [CellHistory]s will have their `id` fields set.
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
  Future<List<CellHistory>> insert(
    _is.DatabaseSession session,
    List<CellHistory> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<CellHistory>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [CellHistory] and returns the inserted row.
  ///
  /// The returned [CellHistory] will have its `id` field set.
  Future<CellHistory> insertRow(
    _is.DatabaseSession session,
    CellHistory row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<CellHistory>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [CellHistory]s in the list and returns the resulting rows.
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
  /// The returned [CellHistory]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CellHistory>> upsert(
    _is.DatabaseSession session,
    List<CellHistory> rows, {
    required _is.ColumnSelections<CellHistoryTable> conflictColumns,
    _is.ColumnSelections<CellHistoryTable>? updateColumns,
    _is.WhereExpressionBuilder<CellHistoryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<CellHistory>(
      rows,
      conflictColumns: conflictColumns(CellHistory.t),
      updateColumns: updateColumns?.call(CellHistory.t),
      updateWhere: updateWhere?.call(CellHistory.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [CellHistory] and returns the resulting row.
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
  /// The returned [CellHistory] will have its `id` field set.
  Future<CellHistory?> upsertRow(
    _is.DatabaseSession session,
    CellHistory row, {
    required _is.ColumnSelections<CellHistoryTable> conflictColumns,
    _is.ColumnSelections<CellHistoryTable>? updateColumns,
    _is.WhereExpressionBuilder<CellHistoryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<CellHistory>(
      row,
      conflictColumns: conflictColumns(CellHistory.t),
      updateColumns: updateColumns?.call(CellHistory.t),
      updateWhere: updateWhere?.call(CellHistory.t),
      transaction: transaction,
    );
  }

  /// Updates all [CellHistory]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CellHistory>> update(
    _is.DatabaseSession session,
    List<CellHistory> rows, {
    _is.ColumnSelections<CellHistoryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<CellHistory>(
      rows,
      columns: columns?.call(CellHistory.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [CellHistory]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<CellHistory> updateRow(
    _is.DatabaseSession session,
    CellHistory row, {
    _is.ColumnSelections<CellHistoryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<CellHistory>(
      row,
      columns: columns?.call(CellHistory.t),
      transaction: transaction,
    );
  }

  /// Updates a single [CellHistory] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<CellHistory?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<CellHistoryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<CellHistory>(
      id,
      columnValues: columnValues(CellHistory.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [CellHistory]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<CellHistory>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CellHistoryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CellHistoryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CellHistoryTable>? orderBy,
    _is.OrderByListBuilder<CellHistoryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<CellHistory>(
      columnValues: columnValues(CellHistory.t.updateTable),
      where: where(CellHistory.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(CellHistory.t),
      orderByList: orderByList?.call(CellHistory.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [CellHistory]s in the list and returns the deleted rows.
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
  Future<List<CellHistory>> delete(
    _is.DatabaseSession session,
    List<CellHistory> rows, {
    _is.OrderByBuilder<CellHistoryTable>? orderBy,
    _is.OrderByListBuilder<CellHistoryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<CellHistory>(
      rows,
      orderBy: orderBy?.call(CellHistory.t),
      orderByList: orderByList?.call(CellHistory.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [CellHistory].
  Future<CellHistory> deleteRow(
    _is.DatabaseSession session,
    CellHistory row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<CellHistory>(
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
  Future<List<CellHistory>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CellHistoryTable> where,
    _is.OrderByBuilder<CellHistoryTable>? orderBy,
    _is.OrderByListBuilder<CellHistoryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<CellHistory>(
      where: where(CellHistory.t),
      orderBy: orderBy?.call(CellHistory.t),
      orderByList: orderByList?.call(CellHistory.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CellHistoryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<CellHistory>(
      where: where?.call(CellHistory.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [CellHistory] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CellHistoryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<CellHistory>(
      where: where(CellHistory.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
