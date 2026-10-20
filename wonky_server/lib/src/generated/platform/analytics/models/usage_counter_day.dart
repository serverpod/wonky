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

/// A daily counter of the usage analytics (specs/19 §2), e.g. `mcp.calls`.
abstract class UsageCounterDay
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  UsageCounterDay._({
    this.id,
    required this.day,
    required this.name,
    int? value,
  }) : value = value ?? 0;

  factory UsageCounterDay({
    int? id,
    required DateTime day,
    required String name,
    int? value,
  }) = _UsageCounterDayImpl;

  factory UsageCounterDay.fromJson(Map<String, dynamic> jsonSerialization) {
    return UsageCounterDay(
      id: jsonSerialization['id'] as int?,
      day: _is.DateTimeJsonExtension.fromJson(jsonSerialization['day']),
      name: jsonSerialization['name'] as String,
      value: jsonSerialization['value'] as int?,
    );
  }

  static final t = UsageCounterDayTable();

  static const db = UsageCounterDayRepository._();

  @override
  int? id;

  /// UTC midnight of the day.
  DateTime day;

  String name;

  int value;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [UsageCounterDay]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  UsageCounterDay copyWith({
    int? id,
    DateTime? day,
    String? name,
    int? value,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UsageCounterDay',
      if (id != null) 'id': id,
      'day': day.toJson(),
      'name': name,
      'value': value,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static UsageCounterDayInclude include() {
    return UsageCounterDayInclude._();
  }

  static UsageCounterDayIncludeList includeList({
    _is.WhereExpressionBuilder<UsageCounterDayTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UsageCounterDayTable>? orderBy,
    _is.OrderByListBuilder<UsageCounterDayTable>? orderByList,
    UsageCounterDayInclude? include,
  }) {
    return UsageCounterDayIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UsageCounterDay.t),
      orderByList: orderByList?.call(UsageCounterDay.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UsageCounterDayImpl extends UsageCounterDay {
  _UsageCounterDayImpl({
    int? id,
    required DateTime day,
    required String name,
    int? value,
  }) : super._(
         id: id,
         day: day,
         name: name,
         value: value,
       );

  /// Returns a shallow copy of this [UsageCounterDay]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  UsageCounterDay copyWith({
    Object? id = _Undefined,
    DateTime? day,
    String? name,
    int? value,
  }) {
    return UsageCounterDay(
      id: id is int? ? id : this.id,
      day: day ?? this.day,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

class UsageCounterDayUpdateTable extends _is.UpdateTable<UsageCounterDayTable> {
  UsageCounterDayUpdateTable(super.table);

  _is.ColumnValue<DateTime, DateTime> day(DateTime value) => _is.ColumnValue(
    table.day,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<int, int> value(int value) => _is.ColumnValue(
    table.value,
    value,
  );
}

class UsageCounterDayTable extends _is.Table<int?> {
  UsageCounterDayTable({super.tableRelation})
    : super(tableName: 'usage_counter_day') {
    updateTable = UsageCounterDayUpdateTable(this);
    day = _is.ColumnDateTime(
      'day',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    value = _is.ColumnInt(
      'value',
      this,
      hasDefault: true,
    );
  }

  late final UsageCounterDayUpdateTable updateTable;

  /// UTC midnight of the day.
  late final _is.ColumnDateTime day;

  late final _is.ColumnString name;

  late final _is.ColumnInt value;

  @override
  List<_is.Column> get columns => [
    id,
    day,
    name,
    value,
  ];
}

class UsageCounterDayInclude extends _is.IncludeObject {
  UsageCounterDayInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => UsageCounterDay.t;
}

class UsageCounterDayIncludeList extends _is.IncludeList {
  UsageCounterDayIncludeList._({
    _is.WhereExpressionBuilder<UsageCounterDayTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UsageCounterDay.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => UsageCounterDay.t;
}

class UsageCounterDayRepository {
  const UsageCounterDayRepository._();

  /// Returns a list of [UsageCounterDay]s matching the given query parameters.
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
  Future<List<UsageCounterDay>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UsageCounterDayTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UsageCounterDayTable>? orderBy,
    _is.OrderByListBuilder<UsageCounterDayTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UsageCounterDay>(
      where: where?.call(UsageCounterDay.t),
      orderBy: orderBy?.call(UsageCounterDay.t),
      orderByList: orderByList?.call(UsageCounterDay.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [UsageCounterDay]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `UsageCounterDay.t`.
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
  _ida.Stream<List<UsageCounterDay>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UsageCounterDayTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UsageCounterDayTable>? orderBy,
    _is.OrderByListBuilder<UsageCounterDayTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<UsageCounterDay>(
      where: where?.call(UsageCounterDay.t),
      orderBy: orderBy?.call(UsageCounterDay.t),
      orderByList: orderByList?.call(UsageCounterDay.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [UsageCounterDay] matching the given query parameters.
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
  Future<UsageCounterDay?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UsageCounterDayTable>? where,
    int? offset,
    _is.OrderByBuilder<UsageCounterDayTable>? orderBy,
    _is.OrderByListBuilder<UsageCounterDayTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UsageCounterDay>(
      where: where?.call(UsageCounterDay.t),
      orderBy: orderBy?.call(UsageCounterDay.t),
      orderByList: orderByList?.call(UsageCounterDay.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UsageCounterDay] by its [id] or null if no such row exists.
  Future<UsageCounterDay?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UsageCounterDay>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UsageCounterDay]s in the list and returns the inserted rows.
  ///
  /// The returned [UsageCounterDay]s will have their `id` fields set.
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
  Future<List<UsageCounterDay>> insert(
    _is.DatabaseSession session,
    List<UsageCounterDay> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<UsageCounterDay>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [UsageCounterDay] and returns the inserted row.
  ///
  /// The returned [UsageCounterDay] will have its `id` field set.
  Future<UsageCounterDay> insertRow(
    _is.DatabaseSession session,
    UsageCounterDay row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<UsageCounterDay>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [UsageCounterDay]s in the list and returns the resulting rows.
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
  /// The returned [UsageCounterDay]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UsageCounterDay>> upsert(
    _is.DatabaseSession session,
    List<UsageCounterDay> rows, {
    required _is.ColumnSelections<UsageCounterDayTable> conflictColumns,
    _is.ColumnSelections<UsageCounterDayTable>? updateColumns,
    _is.WhereExpressionBuilder<UsageCounterDayTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<UsageCounterDay>(
      rows,
      conflictColumns: conflictColumns(UsageCounterDay.t),
      updateColumns: updateColumns?.call(UsageCounterDay.t),
      updateWhere: updateWhere?.call(UsageCounterDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [UsageCounterDay] and returns the resulting row.
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
  /// The returned [UsageCounterDay] will have its `id` field set.
  Future<UsageCounterDay?> upsertRow(
    _is.DatabaseSession session,
    UsageCounterDay row, {
    required _is.ColumnSelections<UsageCounterDayTable> conflictColumns,
    _is.ColumnSelections<UsageCounterDayTable>? updateColumns,
    _is.WhereExpressionBuilder<UsageCounterDayTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<UsageCounterDay>(
      row,
      conflictColumns: conflictColumns(UsageCounterDay.t),
      updateColumns: updateColumns?.call(UsageCounterDay.t),
      updateWhere: updateWhere?.call(UsageCounterDay.t),
      transaction: transaction,
    );
  }

  /// Updates all [UsageCounterDay]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UsageCounterDay>> update(
    _is.DatabaseSession session,
    List<UsageCounterDay> rows, {
    _is.ColumnSelections<UsageCounterDayTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<UsageCounterDay>(
      rows,
      columns: columns?.call(UsageCounterDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [UsageCounterDay]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UsageCounterDay> updateRow(
    _is.DatabaseSession session,
    UsageCounterDay row, {
    _is.ColumnSelections<UsageCounterDayTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<UsageCounterDay>(
      row,
      columns: columns?.call(UsageCounterDay.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UsageCounterDay] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UsageCounterDay?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<UsageCounterDayUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<UsageCounterDay>(
      id,
      columnValues: columnValues(UsageCounterDay.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UsageCounterDay]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UsageCounterDay>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<UsageCounterDayUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<UsageCounterDayTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UsageCounterDayTable>? orderBy,
    _is.OrderByListBuilder<UsageCounterDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<UsageCounterDay>(
      columnValues: columnValues(UsageCounterDay.t.updateTable),
      where: where(UsageCounterDay.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UsageCounterDay.t),
      orderByList: orderByList?.call(UsageCounterDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [UsageCounterDay]s in the list and returns the deleted rows.
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
  Future<List<UsageCounterDay>> delete(
    _is.DatabaseSession session,
    List<UsageCounterDay> rows, {
    _is.OrderByBuilder<UsageCounterDayTable>? orderBy,
    _is.OrderByListBuilder<UsageCounterDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<UsageCounterDay>(
      rows,
      orderBy: orderBy?.call(UsageCounterDay.t),
      orderByList: orderByList?.call(UsageCounterDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [UsageCounterDay].
  Future<UsageCounterDay> deleteRow(
    _is.DatabaseSession session,
    UsageCounterDay row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UsageCounterDay>(
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
  Future<List<UsageCounterDay>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UsageCounterDayTable> where,
    _is.OrderByBuilder<UsageCounterDayTable>? orderBy,
    _is.OrderByListBuilder<UsageCounterDayTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<UsageCounterDay>(
      where: where(UsageCounterDay.t),
      orderBy: orderBy?.call(UsageCounterDay.t),
      orderByList: orderByList?.call(UsageCounterDay.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UsageCounterDayTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<UsageCounterDay>(
      where: where?.call(UsageCounterDay.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UsageCounterDay] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UsageCounterDayTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UsageCounterDay>(
      where: where(UsageCounterDay.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
