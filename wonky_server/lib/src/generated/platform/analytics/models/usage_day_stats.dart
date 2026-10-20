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

/// The activity of one finished UTC day (usage analytics, specs/19 §2.1):
/// computed once by the overview, then read. A finished day never changes,
/// because activity is only written for the current day. One row with and
/// one without admins (the admin rule of the time it was computed). Kept
/// after `user_activity_day` is purged.
abstract class UsageDayStats
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  UsageDayStats._({
    this.id,
    required this.day,
    required this.includeAdmins,
    required this.active,
    required this.editors,
    required this.drive,
    required this.write,
    required this.sheets,
    required this.slides,
    required this.mcp,
    required this.weekly,
    required this.monthly,
    required this.computedAt,
  });

  factory UsageDayStats({
    int? id,
    required DateTime day,
    required bool includeAdmins,
    required int active,
    required int editors,
    required int drive,
    required int write,
    required int sheets,
    required int slides,
    required int mcp,
    required int weekly,
    required int monthly,
    required DateTime computedAt,
  }) = _UsageDayStatsImpl;

  factory UsageDayStats.fromJson(Map<String, dynamic> jsonSerialization) {
    return UsageDayStats(
      id: jsonSerialization['id'] as int?,
      day: _is.DateTimeJsonExtension.fromJson(jsonSerialization['day']),
      includeAdmins: _is.BoolJsonExtension.fromJson(
        jsonSerialization['includeAdmins'],
      ),
      active: jsonSerialization['active'] as int,
      editors: jsonSerialization['editors'] as int,
      drive: jsonSerialization['drive'] as int,
      write: jsonSerialization['write'] as int,
      sheets: jsonSerialization['sheets'] as int,
      slides: jsonSerialization['slides'] as int,
      mcp: jsonSerialization['mcp'] as int,
      weekly: jsonSerialization['weekly'] as int,
      monthly: jsonSerialization['monthly'] as int,
      computedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['computedAt'],
      ),
    );
  }

  static final t = UsageDayStatsTable();

  static const db = UsageDayStatsRepository._();

  @override
  int? id;

  /// UTC midnight of the day.
  DateTime day;

  bool includeAdmins;

  int active;

  int editors;

  int drive;

  int write;

  int sheets;

  int slides;

  int mcp;

  /// Distinct users in the 7 and the 30 days ending with [day].
  int weekly;

  int monthly;

  DateTime computedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [UsageDayStats]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  UsageDayStats copyWith({
    int? id,
    DateTime? day,
    bool? includeAdmins,
    int? active,
    int? editors,
    int? drive,
    int? write,
    int? sheets,
    int? slides,
    int? mcp,
    int? weekly,
    int? monthly,
    DateTime? computedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UsageDayStats',
      if (id != null) 'id': id,
      'day': day.toJson(),
      'includeAdmins': includeAdmins,
      'active': active,
      'editors': editors,
      'drive': drive,
      'write': write,
      'sheets': sheets,
      'slides': slides,
      'mcp': mcp,
      'weekly': weekly,
      'monthly': monthly,
      'computedAt': computedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static UsageDayStatsInclude include() {
    return UsageDayStatsInclude._();
  }

  static UsageDayStatsIncludeList includeList({
    _is.WhereExpressionBuilder<UsageDayStatsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UsageDayStatsTable>? orderBy,
    _is.OrderByListBuilder<UsageDayStatsTable>? orderByList,
    UsageDayStatsInclude? include,
  }) {
    return UsageDayStatsIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UsageDayStats.t),
      orderByList: orderByList?.call(UsageDayStats.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UsageDayStatsImpl extends UsageDayStats {
  _UsageDayStatsImpl({
    int? id,
    required DateTime day,
    required bool includeAdmins,
    required int active,
    required int editors,
    required int drive,
    required int write,
    required int sheets,
    required int slides,
    required int mcp,
    required int weekly,
    required int monthly,
    required DateTime computedAt,
  }) : super._(
         id: id,
         day: day,
         includeAdmins: includeAdmins,
         active: active,
         editors: editors,
         drive: drive,
         write: write,
         sheets: sheets,
         slides: slides,
         mcp: mcp,
         weekly: weekly,
         monthly: monthly,
         computedAt: computedAt,
       );

  /// Returns a shallow copy of this [UsageDayStats]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  UsageDayStats copyWith({
    Object? id = _Undefined,
    DateTime? day,
    bool? includeAdmins,
    int? active,
    int? editors,
    int? drive,
    int? write,
    int? sheets,
    int? slides,
    int? mcp,
    int? weekly,
    int? monthly,
    DateTime? computedAt,
  }) {
    return UsageDayStats(
      id: id is int? ? id : this.id,
      day: day ?? this.day,
      includeAdmins: includeAdmins ?? this.includeAdmins,
      active: active ?? this.active,
      editors: editors ?? this.editors,
      drive: drive ?? this.drive,
      write: write ?? this.write,
      sheets: sheets ?? this.sheets,
      slides: slides ?? this.slides,
      mcp: mcp ?? this.mcp,
      weekly: weekly ?? this.weekly,
      monthly: monthly ?? this.monthly,
      computedAt: computedAt ?? this.computedAt,
    );
  }
}

class UsageDayStatsUpdateTable extends _is.UpdateTable<UsageDayStatsTable> {
  UsageDayStatsUpdateTable(super.table);

  _is.ColumnValue<DateTime, DateTime> day(DateTime value) => _is.ColumnValue(
    table.day,
    value,
  );

  _is.ColumnValue<bool, bool> includeAdmins(bool value) => _is.ColumnValue(
    table.includeAdmins,
    value,
  );

  _is.ColumnValue<int, int> active(int value) => _is.ColumnValue(
    table.active,
    value,
  );

  _is.ColumnValue<int, int> editors(int value) => _is.ColumnValue(
    table.editors,
    value,
  );

  _is.ColumnValue<int, int> drive(int value) => _is.ColumnValue(
    table.drive,
    value,
  );

  _is.ColumnValue<int, int> write(int value) => _is.ColumnValue(
    table.write,
    value,
  );

  _is.ColumnValue<int, int> sheets(int value) => _is.ColumnValue(
    table.sheets,
    value,
  );

  _is.ColumnValue<int, int> slides(int value) => _is.ColumnValue(
    table.slides,
    value,
  );

  _is.ColumnValue<int, int> mcp(int value) => _is.ColumnValue(
    table.mcp,
    value,
  );

  _is.ColumnValue<int, int> weekly(int value) => _is.ColumnValue(
    table.weekly,
    value,
  );

  _is.ColumnValue<int, int> monthly(int value) => _is.ColumnValue(
    table.monthly,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> computedAt(DateTime value) =>
      _is.ColumnValue(
        table.computedAt,
        value,
      );
}

class UsageDayStatsTable extends _is.Table<int?> {
  UsageDayStatsTable({super.tableRelation})
    : super(tableName: 'usage_day_stats') {
    updateTable = UsageDayStatsUpdateTable(this);
    day = _is.ColumnDateTime(
      'day',
      this,
    );
    includeAdmins = _is.ColumnBool(
      'includeAdmins',
      this,
    );
    active = _is.ColumnInt(
      'active',
      this,
    );
    editors = _is.ColumnInt(
      'editors',
      this,
    );
    drive = _is.ColumnInt(
      'drive',
      this,
    );
    write = _is.ColumnInt(
      'write',
      this,
    );
    sheets = _is.ColumnInt(
      'sheets',
      this,
    );
    slides = _is.ColumnInt(
      'slides',
      this,
    );
    mcp = _is.ColumnInt(
      'mcp',
      this,
    );
    weekly = _is.ColumnInt(
      'weekly',
      this,
    );
    monthly = _is.ColumnInt(
      'monthly',
      this,
    );
    computedAt = _is.ColumnDateTime(
      'computedAt',
      this,
    );
  }

  late final UsageDayStatsUpdateTable updateTable;

  /// UTC midnight of the day.
  late final _is.ColumnDateTime day;

  late final _is.ColumnBool includeAdmins;

  late final _is.ColumnInt active;

  late final _is.ColumnInt editors;

  late final _is.ColumnInt drive;

  late final _is.ColumnInt write;

  late final _is.ColumnInt sheets;

  late final _is.ColumnInt slides;

  late final _is.ColumnInt mcp;

  /// Distinct users in the 7 and the 30 days ending with [day].
  late final _is.ColumnInt weekly;

  late final _is.ColumnInt monthly;

  late final _is.ColumnDateTime computedAt;

  @override
  List<_is.Column> get columns => [
    id,
    day,
    includeAdmins,
    active,
    editors,
    drive,
    write,
    sheets,
    slides,
    mcp,
    weekly,
    monthly,
    computedAt,
  ];
}

class UsageDayStatsInclude extends _is.IncludeObject {
  UsageDayStatsInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => UsageDayStats.t;
}

class UsageDayStatsIncludeList extends _is.IncludeList {
  UsageDayStatsIncludeList._({
    _is.WhereExpressionBuilder<UsageDayStatsTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UsageDayStats.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => UsageDayStats.t;
}

class UsageDayStatsRepository {
  const UsageDayStatsRepository._();

  /// Returns a list of [UsageDayStats]s matching the given query parameters.
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
  Future<List<UsageDayStats>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UsageDayStatsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UsageDayStatsTable>? orderBy,
    _is.OrderByListBuilder<UsageDayStatsTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UsageDayStats>(
      where: where?.call(UsageDayStats.t),
      orderBy: orderBy?.call(UsageDayStats.t),
      orderByList: orderByList?.call(UsageDayStats.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [UsageDayStats]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `UsageDayStats.t`.
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
  _ida.Stream<List<UsageDayStats>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UsageDayStatsTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UsageDayStatsTable>? orderBy,
    _is.OrderByListBuilder<UsageDayStatsTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<UsageDayStats>(
      where: where?.call(UsageDayStats.t),
      orderBy: orderBy?.call(UsageDayStats.t),
      orderByList: orderByList?.call(UsageDayStats.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [UsageDayStats] matching the given query parameters.
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
  Future<UsageDayStats?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UsageDayStatsTable>? where,
    int? offset,
    _is.OrderByBuilder<UsageDayStatsTable>? orderBy,
    _is.OrderByListBuilder<UsageDayStatsTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UsageDayStats>(
      where: where?.call(UsageDayStats.t),
      orderBy: orderBy?.call(UsageDayStats.t),
      orderByList: orderByList?.call(UsageDayStats.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UsageDayStats] by its [id] or null if no such row exists.
  Future<UsageDayStats?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UsageDayStats>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UsageDayStats]s in the list and returns the inserted rows.
  ///
  /// The returned [UsageDayStats]s will have their `id` fields set.
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
  Future<List<UsageDayStats>> insert(
    _is.DatabaseSession session,
    List<UsageDayStats> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<UsageDayStats>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [UsageDayStats] and returns the inserted row.
  ///
  /// The returned [UsageDayStats] will have its `id` field set.
  Future<UsageDayStats> insertRow(
    _is.DatabaseSession session,
    UsageDayStats row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<UsageDayStats>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [UsageDayStats]s in the list and returns the resulting rows.
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
  /// The returned [UsageDayStats]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UsageDayStats>> upsert(
    _is.DatabaseSession session,
    List<UsageDayStats> rows, {
    required _is.ColumnSelections<UsageDayStatsTable> conflictColumns,
    _is.ColumnSelections<UsageDayStatsTable>? updateColumns,
    _is.WhereExpressionBuilder<UsageDayStatsTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<UsageDayStats>(
      rows,
      conflictColumns: conflictColumns(UsageDayStats.t),
      updateColumns: updateColumns?.call(UsageDayStats.t),
      updateWhere: updateWhere?.call(UsageDayStats.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [UsageDayStats] and returns the resulting row.
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
  /// The returned [UsageDayStats] will have its `id` field set.
  Future<UsageDayStats?> upsertRow(
    _is.DatabaseSession session,
    UsageDayStats row, {
    required _is.ColumnSelections<UsageDayStatsTable> conflictColumns,
    _is.ColumnSelections<UsageDayStatsTable>? updateColumns,
    _is.WhereExpressionBuilder<UsageDayStatsTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<UsageDayStats>(
      row,
      conflictColumns: conflictColumns(UsageDayStats.t),
      updateColumns: updateColumns?.call(UsageDayStats.t),
      updateWhere: updateWhere?.call(UsageDayStats.t),
      transaction: transaction,
    );
  }

  /// Updates all [UsageDayStats]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UsageDayStats>> update(
    _is.DatabaseSession session,
    List<UsageDayStats> rows, {
    _is.ColumnSelections<UsageDayStatsTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<UsageDayStats>(
      rows,
      columns: columns?.call(UsageDayStats.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [UsageDayStats]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UsageDayStats> updateRow(
    _is.DatabaseSession session,
    UsageDayStats row, {
    _is.ColumnSelections<UsageDayStatsTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<UsageDayStats>(
      row,
      columns: columns?.call(UsageDayStats.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UsageDayStats] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UsageDayStats?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<UsageDayStatsUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<UsageDayStats>(
      id,
      columnValues: columnValues(UsageDayStats.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UsageDayStats]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UsageDayStats>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<UsageDayStatsUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<UsageDayStatsTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UsageDayStatsTable>? orderBy,
    _is.OrderByListBuilder<UsageDayStatsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<UsageDayStats>(
      columnValues: columnValues(UsageDayStats.t.updateTable),
      where: where(UsageDayStats.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UsageDayStats.t),
      orderByList: orderByList?.call(UsageDayStats.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [UsageDayStats]s in the list and returns the deleted rows.
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
  Future<List<UsageDayStats>> delete(
    _is.DatabaseSession session,
    List<UsageDayStats> rows, {
    _is.OrderByBuilder<UsageDayStatsTable>? orderBy,
    _is.OrderByListBuilder<UsageDayStatsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<UsageDayStats>(
      rows,
      orderBy: orderBy?.call(UsageDayStats.t),
      orderByList: orderByList?.call(UsageDayStats.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [UsageDayStats].
  Future<UsageDayStats> deleteRow(
    _is.DatabaseSession session,
    UsageDayStats row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UsageDayStats>(
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
  Future<List<UsageDayStats>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UsageDayStatsTable> where,
    _is.OrderByBuilder<UsageDayStatsTable>? orderBy,
    _is.OrderByListBuilder<UsageDayStatsTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<UsageDayStats>(
      where: where(UsageDayStats.t),
      orderBy: orderBy?.call(UsageDayStats.t),
      orderByList: orderByList?.call(UsageDayStats.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UsageDayStatsTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<UsageDayStats>(
      where: where?.call(UsageDayStats.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UsageDayStats] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UsageDayStatsTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UsageDayStats>(
      where: where(UsageDayStats.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
