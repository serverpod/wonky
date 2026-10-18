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

/// The last 50 saved versions of a theme.
abstract class WriteThemeRevision
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WriteThemeRevision._({
    this.id,
    required this.themeId,
    required this.version,
    required this.json,
    this.savedById,
    required this.actorKind,
    required this.createdAt,
  });

  factory WriteThemeRevision({
    int? id,
    required int themeId,
    required int version,
    required String json,
    int? savedById,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) = _WriteThemeRevisionImpl;

  factory WriteThemeRevision.fromJson(Map<String, dynamic> jsonSerialization) {
    return WriteThemeRevision(
      id: jsonSerialization['id'] as int?,
      themeId: jsonSerialization['themeId'] as int,
      version: jsonSerialization['version'] as int,
      json: jsonSerialization['json'] as String,
      savedById: jsonSerialization['savedById'] as int?,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = WriteThemeRevisionTable();

  static const db = WriteThemeRevisionRepository._();

  @override
  int? id;

  int themeId;

  int version;

  String json;

  int? savedById;

  _ipbpecg8.ActorKind actorKind;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WriteThemeRevision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WriteThemeRevision copyWith({
    int? id,
    int? themeId,
    int? version,
    String? json,
    int? savedById,
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WriteThemeRevision',
      if (id != null) 'id': id,
      'themeId': themeId,
      'version': version,
      'json': json,
      if (savedById != null) 'savedById': savedById,
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WriteThemeRevision',
      if (id != null) 'id': id,
      'themeId': themeId,
      'version': version,
      'json': json,
      if (savedById != null) 'savedById': savedById,
      'actorKind': actorKind.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static WriteThemeRevisionInclude include() {
    return WriteThemeRevisionInclude._();
  }

  static WriteThemeRevisionIncludeList includeList({
    _is.WhereExpressionBuilder<WriteThemeRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WriteThemeRevisionTable>? orderBy,
    _is.OrderByListBuilder<WriteThemeRevisionTable>? orderByList,
    WriteThemeRevisionInclude? include,
  }) {
    return WriteThemeRevisionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WriteThemeRevision.t),
      orderByList: orderByList?.call(WriteThemeRevision.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WriteThemeRevisionImpl extends WriteThemeRevision {
  _WriteThemeRevisionImpl({
    int? id,
    required int themeId,
    required int version,
    required String json,
    int? savedById,
    required _ipbpecg8.ActorKind actorKind,
    required DateTime createdAt,
  }) : super._(
         id: id,
         themeId: themeId,
         version: version,
         json: json,
         savedById: savedById,
         actorKind: actorKind,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WriteThemeRevision]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WriteThemeRevision copyWith({
    Object? id = _Undefined,
    int? themeId,
    int? version,
    String? json,
    Object? savedById = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    DateTime? createdAt,
  }) {
    return WriteThemeRevision(
      id: id is int? ? id : this.id,
      themeId: themeId ?? this.themeId,
      version: version ?? this.version,
      json: json ?? this.json,
      savedById: savedById is int? ? savedById : this.savedById,
      actorKind: actorKind ?? this.actorKind,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WriteThemeRevisionUpdateTable
    extends _is.UpdateTable<WriteThemeRevisionTable> {
  WriteThemeRevisionUpdateTable(super.table);

  _is.ColumnValue<int, int> themeId(int value) => _is.ColumnValue(
    table.themeId,
    value,
  );

  _is.ColumnValue<int, int> version(int value) => _is.ColumnValue(
    table.version,
    value,
  );

  _is.ColumnValue<String, String> json(String value) => _is.ColumnValue(
    table.json,
    value,
  );

  _is.ColumnValue<int, int> savedById(int? value) => _is.ColumnValue(
    table.savedById,
    value,
  );

  _is.ColumnValue<_ipbpecg8.ActorKind, _ipbpecg8.ActorKind> actorKind(
    _ipbpecg8.ActorKind value,
  ) => _is.ColumnValue(
    table.actorKind,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class WriteThemeRevisionTable extends _is.Table<int?> {
  WriteThemeRevisionTable({super.tableRelation})
    : super(tableName: 'write_theme_revision') {
    updateTable = WriteThemeRevisionUpdateTable(this);
    themeId = _is.ColumnInt(
      'themeId',
      this,
    );
    version = _is.ColumnInt(
      'version',
      this,
    );
    json = _is.ColumnString(
      'json',
      this,
    );
    savedById = _is.ColumnInt(
      'savedById',
      this,
    );
    actorKind = _is.ColumnEnum(
      'actorKind',
      this,
      _is.EnumSerialization.byName,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final WriteThemeRevisionUpdateTable updateTable;

  late final _is.ColumnInt themeId;

  late final _is.ColumnInt version;

  late final _is.ColumnString json;

  late final _is.ColumnInt savedById;

  late final _is.ColumnEnum<_ipbpecg8.ActorKind> actorKind;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    themeId,
    version,
    json,
    savedById,
    actorKind,
    createdAt,
  ];
}

class WriteThemeRevisionInclude extends _is.IncludeObject {
  WriteThemeRevisionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WriteThemeRevision.t;
}

class WriteThemeRevisionIncludeList extends _is.IncludeList {
  WriteThemeRevisionIncludeList._({
    _is.WhereExpressionBuilder<WriteThemeRevisionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WriteThemeRevision.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WriteThemeRevision.t;
}

class WriteThemeRevisionRepository {
  const WriteThemeRevisionRepository._();

  /// Returns a list of [WriteThemeRevision]s matching the given query parameters.
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
  Future<List<WriteThemeRevision>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WriteThemeRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WriteThemeRevisionTable>? orderBy,
    _is.OrderByListBuilder<WriteThemeRevisionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WriteThemeRevision>(
      where: where?.call(WriteThemeRevision.t),
      orderBy: orderBy?.call(WriteThemeRevision.t),
      orderByList: orderByList?.call(WriteThemeRevision.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [WriteThemeRevision]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `WriteThemeRevision.t`.
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
  _ida.Stream<List<WriteThemeRevision>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WriteThemeRevisionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WriteThemeRevisionTable>? orderBy,
    _is.OrderByListBuilder<WriteThemeRevisionTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<WriteThemeRevision>(
      where: where?.call(WriteThemeRevision.t),
      orderBy: orderBy?.call(WriteThemeRevision.t),
      orderByList: orderByList?.call(WriteThemeRevision.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [WriteThemeRevision] matching the given query parameters.
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
  Future<WriteThemeRevision?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WriteThemeRevisionTable>? where,
    int? offset,
    _is.OrderByBuilder<WriteThemeRevisionTable>? orderBy,
    _is.OrderByListBuilder<WriteThemeRevisionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WriteThemeRevision>(
      where: where?.call(WriteThemeRevision.t),
      orderBy: orderBy?.call(WriteThemeRevision.t),
      orderByList: orderByList?.call(WriteThemeRevision.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WriteThemeRevision] by its [id] or null if no such row exists.
  Future<WriteThemeRevision?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WriteThemeRevision>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WriteThemeRevision]s in the list and returns the inserted rows.
  ///
  /// The returned [WriteThemeRevision]s will have their `id` fields set.
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
  Future<List<WriteThemeRevision>> insert(
    _is.DatabaseSession session,
    List<WriteThemeRevision> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WriteThemeRevision>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WriteThemeRevision] and returns the inserted row.
  ///
  /// The returned [WriteThemeRevision] will have its `id` field set.
  Future<WriteThemeRevision> insertRow(
    _is.DatabaseSession session,
    WriteThemeRevision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WriteThemeRevision>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WriteThemeRevision]s in the list and returns the resulting rows.
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
  /// The returned [WriteThemeRevision]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WriteThemeRevision>> upsert(
    _is.DatabaseSession session,
    List<WriteThemeRevision> rows, {
    required _is.ColumnSelections<WriteThemeRevisionTable> conflictColumns,
    _is.ColumnSelections<WriteThemeRevisionTable>? updateColumns,
    _is.WhereExpressionBuilder<WriteThemeRevisionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WriteThemeRevision>(
      rows,
      conflictColumns: conflictColumns(WriteThemeRevision.t),
      updateColumns: updateColumns?.call(WriteThemeRevision.t),
      updateWhere: updateWhere?.call(WriteThemeRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WriteThemeRevision] and returns the resulting row.
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
  /// The returned [WriteThemeRevision] will have its `id` field set.
  Future<WriteThemeRevision?> upsertRow(
    _is.DatabaseSession session,
    WriteThemeRevision row, {
    required _is.ColumnSelections<WriteThemeRevisionTable> conflictColumns,
    _is.ColumnSelections<WriteThemeRevisionTable>? updateColumns,
    _is.WhereExpressionBuilder<WriteThemeRevisionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WriteThemeRevision>(
      row,
      conflictColumns: conflictColumns(WriteThemeRevision.t),
      updateColumns: updateColumns?.call(WriteThemeRevision.t),
      updateWhere: updateWhere?.call(WriteThemeRevision.t),
      transaction: transaction,
    );
  }

  /// Updates all [WriteThemeRevision]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WriteThemeRevision>> update(
    _is.DatabaseSession session,
    List<WriteThemeRevision> rows, {
    _is.ColumnSelections<WriteThemeRevisionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WriteThemeRevision>(
      rows,
      columns: columns?.call(WriteThemeRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WriteThemeRevision]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WriteThemeRevision> updateRow(
    _is.DatabaseSession session,
    WriteThemeRevision row, {
    _is.ColumnSelections<WriteThemeRevisionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WriteThemeRevision>(
      row,
      columns: columns?.call(WriteThemeRevision.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WriteThemeRevision] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WriteThemeRevision?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WriteThemeRevisionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WriteThemeRevision>(
      id,
      columnValues: columnValues(WriteThemeRevision.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WriteThemeRevision]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WriteThemeRevision>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WriteThemeRevisionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<WriteThemeRevisionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WriteThemeRevisionTable>? orderBy,
    _is.OrderByListBuilder<WriteThemeRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WriteThemeRevision>(
      columnValues: columnValues(WriteThemeRevision.t.updateTable),
      where: where(WriteThemeRevision.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WriteThemeRevision.t),
      orderByList: orderByList?.call(WriteThemeRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WriteThemeRevision]s in the list and returns the deleted rows.
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
  Future<List<WriteThemeRevision>> delete(
    _is.DatabaseSession session,
    List<WriteThemeRevision> rows, {
    _is.OrderByBuilder<WriteThemeRevisionTable>? orderBy,
    _is.OrderByListBuilder<WriteThemeRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WriteThemeRevision>(
      rows,
      orderBy: orderBy?.call(WriteThemeRevision.t),
      orderByList: orderByList?.call(WriteThemeRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WriteThemeRevision].
  Future<WriteThemeRevision> deleteRow(
    _is.DatabaseSession session,
    WriteThemeRevision row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WriteThemeRevision>(
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
  Future<List<WriteThemeRevision>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WriteThemeRevisionTable> where,
    _is.OrderByBuilder<WriteThemeRevisionTable>? orderBy,
    _is.OrderByListBuilder<WriteThemeRevisionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WriteThemeRevision>(
      where: where(WriteThemeRevision.t),
      orderBy: orderBy?.call(WriteThemeRevision.t),
      orderByList: orderByList?.call(WriteThemeRevision.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WriteThemeRevisionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WriteThemeRevision>(
      where: where?.call(WriteThemeRevision.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WriteThemeRevision] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WriteThemeRevisionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WriteThemeRevision>(
      where: where(WriteThemeRevision.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
