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
import '../../platform/activity/activity_type.dart' as _ib69qjv6;
import '../../platform/common/actor_kind.dart' as _ipbpecg8;

/// Activity log of an item (specs/05 §5). Edits are aggregated to one event
/// per (user, item) per 10 minutes.
abstract class ActivityEvent
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ActivityEvent._({
    this.id,
    required this.itemId,
    this.actorId,
    required this.actorKind,
    required this.type,
    required this.summary,
    required this.at,
  });

  factory ActivityEvent({
    int? id,
    required int itemId,
    int? actorId,
    required _ipbpecg8.ActorKind actorKind,
    required _ib69qjv6.ActivityType type,
    required String summary,
    required DateTime at,
  }) = _ActivityEventImpl;

  factory ActivityEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return ActivityEvent(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      actorId: jsonSerialization['actorId'] as int?,
      actorKind: _ipbpecg8.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      type: _ib69qjv6.ActivityType.fromJson(
        (jsonSerialization['type'] as String),
      ),
      summary: jsonSerialization['summary'] as String,
      at: _is.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
    );
  }

  static final t = ActivityEventTable();

  static const db = ActivityEventRepository._();

  @override
  int? id;

  int itemId;

  int? actorId;

  _ipbpecg8.ActorKind actorKind;

  _ib69qjv6.ActivityType type;

  /// JSON payload for rendering.
  String summary;

  DateTime at;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ActivityEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ActivityEvent copyWith({
    int? id,
    int? itemId,
    int? actorId,
    _ipbpecg8.ActorKind? actorKind,
    _ib69qjv6.ActivityType? type,
    String? summary,
    DateTime? at,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ActivityEvent',
      if (id != null) 'id': id,
      'itemId': itemId,
      if (actorId != null) 'actorId': actorId,
      'actorKind': actorKind.toJson(),
      'type': type.toJson(),
      'summary': summary,
      'at': at.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ActivityEvent',
      if (id != null) 'id': id,
      'itemId': itemId,
      if (actorId != null) 'actorId': actorId,
      'actorKind': actorKind.toJson(),
      'type': type.toJson(),
      'summary': summary,
      'at': at.toJson(),
    };
  }

  static ActivityEventInclude include() {
    return ActivityEventInclude._();
  }

  static ActivityEventIncludeList includeList({
    _is.WhereExpressionBuilder<ActivityEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActivityEventTable>? orderBy,
    _is.OrderByListBuilder<ActivityEventTable>? orderByList,
    ActivityEventInclude? include,
  }) {
    return ActivityEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActivityEvent.t),
      orderByList: orderByList?.call(ActivityEvent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ActivityEventImpl extends ActivityEvent {
  _ActivityEventImpl({
    int? id,
    required int itemId,
    int? actorId,
    required _ipbpecg8.ActorKind actorKind,
    required _ib69qjv6.ActivityType type,
    required String summary,
    required DateTime at,
  }) : super._(
         id: id,
         itemId: itemId,
         actorId: actorId,
         actorKind: actorKind,
         type: type,
         summary: summary,
         at: at,
       );

  /// Returns a shallow copy of this [ActivityEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ActivityEvent copyWith({
    Object? id = _Undefined,
    int? itemId,
    Object? actorId = _Undefined,
    _ipbpecg8.ActorKind? actorKind,
    _ib69qjv6.ActivityType? type,
    String? summary,
    DateTime? at,
  }) {
    return ActivityEvent(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      actorId: actorId is int? ? actorId : this.actorId,
      actorKind: actorKind ?? this.actorKind,
      type: type ?? this.type,
      summary: summary ?? this.summary,
      at: at ?? this.at,
    );
  }
}

class ActivityEventUpdateTable extends _is.UpdateTable<ActivityEventTable> {
  ActivityEventUpdateTable(super.table);

  _is.ColumnValue<int, int> itemId(int value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<int, int> actorId(int? value) => _is.ColumnValue(
    table.actorId,
    value,
  );

  _is.ColumnValue<_ipbpecg8.ActorKind, _ipbpecg8.ActorKind> actorKind(
    _ipbpecg8.ActorKind value,
  ) => _is.ColumnValue(
    table.actorKind,
    value,
  );

  _is.ColumnValue<_ib69qjv6.ActivityType, _ib69qjv6.ActivityType> type(
    _ib69qjv6.ActivityType value,
  ) => _is.ColumnValue(
    table.type,
    value,
  );

  _is.ColumnValue<String, String> summary(String value) => _is.ColumnValue(
    table.summary,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> at(DateTime value) => _is.ColumnValue(
    table.at,
    value,
  );
}

class ActivityEventTable extends _is.Table<int?> {
  ActivityEventTable({super.tableRelation})
    : super(tableName: 'activity_event') {
    updateTable = ActivityEventUpdateTable(this);
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    actorId = _is.ColumnInt(
      'actorId',
      this,
    );
    actorKind = _is.ColumnEnum(
      'actorKind',
      this,
      _is.EnumSerialization.byName,
    );
    type = _is.ColumnEnum(
      'type',
      this,
      _is.EnumSerialization.byName,
    );
    summary = _is.ColumnString(
      'summary',
      this,
    );
    at = _is.ColumnDateTime(
      'at',
      this,
    );
  }

  late final ActivityEventUpdateTable updateTable;

  late final _is.ColumnInt itemId;

  late final _is.ColumnInt actorId;

  late final _is.ColumnEnum<_ipbpecg8.ActorKind> actorKind;

  late final _is.ColumnEnum<_ib69qjv6.ActivityType> type;

  /// JSON payload for rendering.
  late final _is.ColumnString summary;

  late final _is.ColumnDateTime at;

  @override
  List<_is.Column> get columns => [
    id,
    itemId,
    actorId,
    actorKind,
    type,
    summary,
    at,
  ];
}

class ActivityEventInclude extends _is.IncludeObject {
  ActivityEventInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ActivityEvent.t;
}

class ActivityEventIncludeList extends _is.IncludeList {
  ActivityEventIncludeList._({
    _is.WhereExpressionBuilder<ActivityEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ActivityEvent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ActivityEvent.t;
}

class ActivityEventRepository {
  const ActivityEventRepository._();

  /// Returns a list of [ActivityEvent]s matching the given query parameters.
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
  Future<List<ActivityEvent>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActivityEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActivityEventTable>? orderBy,
    _is.OrderByListBuilder<ActivityEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ActivityEvent>(
      where: where?.call(ActivityEvent.t),
      orderBy: orderBy?.call(ActivityEvent.t),
      orderByList: orderByList?.call(ActivityEvent.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ActivityEvent]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ActivityEvent.t`.
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
  _ida.Stream<List<ActivityEvent>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActivityEventTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActivityEventTable>? orderBy,
    _is.OrderByListBuilder<ActivityEventTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ActivityEvent>(
      where: where?.call(ActivityEvent.t),
      orderBy: orderBy?.call(ActivityEvent.t),
      orderByList: orderByList?.call(ActivityEvent.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ActivityEvent] matching the given query parameters.
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
  Future<ActivityEvent?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActivityEventTable>? where,
    int? offset,
    _is.OrderByBuilder<ActivityEventTable>? orderBy,
    _is.OrderByListBuilder<ActivityEventTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ActivityEvent>(
      where: where?.call(ActivityEvent.t),
      orderBy: orderBy?.call(ActivityEvent.t),
      orderByList: orderByList?.call(ActivityEvent.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ActivityEvent] by its [id] or null if no such row exists.
  Future<ActivityEvent?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ActivityEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ActivityEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [ActivityEvent]s will have their `id` fields set.
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
  Future<List<ActivityEvent>> insert(
    _is.DatabaseSession session,
    List<ActivityEvent> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ActivityEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ActivityEvent] and returns the inserted row.
  ///
  /// The returned [ActivityEvent] will have its `id` field set.
  Future<ActivityEvent> insertRow(
    _is.DatabaseSession session,
    ActivityEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ActivityEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ActivityEvent]s in the list and returns the resulting rows.
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
  /// The returned [ActivityEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActivityEvent>> upsert(
    _is.DatabaseSession session,
    List<ActivityEvent> rows, {
    required _is.ColumnSelections<ActivityEventTable> conflictColumns,
    _is.ColumnSelections<ActivityEventTable>? updateColumns,
    _is.WhereExpressionBuilder<ActivityEventTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ActivityEvent>(
      rows,
      conflictColumns: conflictColumns(ActivityEvent.t),
      updateColumns: updateColumns?.call(ActivityEvent.t),
      updateWhere: updateWhere?.call(ActivityEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ActivityEvent] and returns the resulting row.
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
  /// The returned [ActivityEvent] will have its `id` field set.
  Future<ActivityEvent?> upsertRow(
    _is.DatabaseSession session,
    ActivityEvent row, {
    required _is.ColumnSelections<ActivityEventTable> conflictColumns,
    _is.ColumnSelections<ActivityEventTable>? updateColumns,
    _is.WhereExpressionBuilder<ActivityEventTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ActivityEvent>(
      row,
      conflictColumns: conflictColumns(ActivityEvent.t),
      updateColumns: updateColumns?.call(ActivityEvent.t),
      updateWhere: updateWhere?.call(ActivityEvent.t),
      transaction: transaction,
    );
  }

  /// Updates all [ActivityEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActivityEvent>> update(
    _is.DatabaseSession session,
    List<ActivityEvent> rows, {
    _is.ColumnSelections<ActivityEventTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ActivityEvent>(
      rows,
      columns: columns?.call(ActivityEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ActivityEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ActivityEvent> updateRow(
    _is.DatabaseSession session,
    ActivityEvent row, {
    _is.ColumnSelections<ActivityEventTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ActivityEvent>(
      row,
      columns: columns?.call(ActivityEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ActivityEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ActivityEvent?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ActivityEventUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ActivityEvent>(
      id,
      columnValues: columnValues(ActivityEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ActivityEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ActivityEvent>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ActivityEventUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ActivityEventTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ActivityEventTable>? orderBy,
    _is.OrderByListBuilder<ActivityEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ActivityEvent>(
      columnValues: columnValues(ActivityEvent.t.updateTable),
      where: where(ActivityEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ActivityEvent.t),
      orderByList: orderByList?.call(ActivityEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ActivityEvent]s in the list and returns the deleted rows.
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
  Future<List<ActivityEvent>> delete(
    _is.DatabaseSession session,
    List<ActivityEvent> rows, {
    _is.OrderByBuilder<ActivityEventTable>? orderBy,
    _is.OrderByListBuilder<ActivityEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ActivityEvent>(
      rows,
      orderBy: orderBy?.call(ActivityEvent.t),
      orderByList: orderByList?.call(ActivityEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ActivityEvent].
  Future<ActivityEvent> deleteRow(
    _is.DatabaseSession session,
    ActivityEvent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ActivityEvent>(
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
  Future<List<ActivityEvent>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActivityEventTable> where,
    _is.OrderByBuilder<ActivityEventTable>? orderBy,
    _is.OrderByListBuilder<ActivityEventTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ActivityEvent>(
      where: where(ActivityEvent.t),
      orderBy: orderBy?.call(ActivityEvent.t),
      orderByList: orderByList?.call(ActivityEvent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ActivityEventTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ActivityEvent>(
      where: where?.call(ActivityEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ActivityEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ActivityEventTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ActivityEvent>(
      where: where(ActivityEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
