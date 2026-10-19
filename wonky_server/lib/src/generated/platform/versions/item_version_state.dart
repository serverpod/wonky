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

/// Capture-policy state per item (specs/07 §5): written on edits, read by the
/// capture job. Serves both apps (replaces Sheets' SheetsVersionState).
abstract class ItemVersionState
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ItemVersionState._({
    this.id,
    required this.itemId,
    required this.lastEditAt,
    this.dirtySince,
    this.lastVersionAt,
    required this.editorsSinceLastVersion,
    this.lastRevision,
    this.capturingSince,
  });

  factory ItemVersionState({
    int? id,
    required int itemId,
    required DateTime lastEditAt,
    DateTime? dirtySince,
    DateTime? lastVersionAt,
    required List<int> editorsSinceLastVersion,
    int? lastRevision,
    DateTime? capturingSince,
  }) = _ItemVersionStateImpl;

  factory ItemVersionState.fromJson(Map<String, dynamic> jsonSerialization) {
    return ItemVersionState(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      lastEditAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastEditAt'],
      ),
      dirtySince: jsonSerialization['dirtySince'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['dirtySince']),
      lastVersionAt: jsonSerialization['lastVersionAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastVersionAt'],
            ),
      editorsSinceLastVersion: _il4umwa0.Protocol().deserialize<List<int>>(
        jsonSerialization['editorsSinceLastVersion'],
      ),
      lastRevision: jsonSerialization['lastRevision'] as int?,
      capturingSince: jsonSerialization['capturingSince'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['capturingSince'],
            ),
    );
  }

  static final t = ItemVersionStateTable();

  static const db = ItemVersionStateRepository._();

  @override
  int? id;

  int itemId;

  /// Last edit seen.
  DateTime lastEditAt;

  /// First edit after the last captured version (null = clean).
  DateTime? dirtySince;

  DateTime? lastVersionAt;

  List<int> editorsSinceLastVersion;

  /// Write: head revision at the last edit.
  int? lastRevision;

  /// When a capture run claimed the item (`VersionService.captureDue`):
  /// overlapping runs skip it; a claim older than 10 minutes is taken over.
  DateTime? capturingSince;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ItemVersionState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ItemVersionState copyWith({
    int? id,
    int? itemId,
    DateTime? lastEditAt,
    DateTime? dirtySince = const _is.$UndefinedDateTime(),
    DateTime? lastVersionAt = const _is.$UndefinedDateTime(),
    List<int>? editorsSinceLastVersion,
    int? lastRevision,
    DateTime? capturingSince = const _is.$UndefinedDateTime(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ItemVersionState',
      if (id != null) 'id': id,
      'itemId': itemId,
      'lastEditAt': lastEditAt.toJson(),
      if (dirtySince != null) 'dirtySince': dirtySince?.toJson(),
      if (lastVersionAt != null) 'lastVersionAt': lastVersionAt?.toJson(),
      'editorsSinceLastVersion': editorsSinceLastVersion.toJson(),
      if (lastRevision != null) 'lastRevision': lastRevision,
      if (capturingSince != null) 'capturingSince': capturingSince?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ItemVersionStateInclude include() {
    return ItemVersionStateInclude._();
  }

  static ItemVersionStateIncludeList includeList({
    _is.WhereExpressionBuilder<ItemVersionStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ItemVersionStateTable>? orderBy,
    _is.OrderByListBuilder<ItemVersionStateTable>? orderByList,
    ItemVersionStateInclude? include,
  }) {
    return ItemVersionStateIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ItemVersionState.t),
      orderByList: orderByList?.call(ItemVersionState.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ItemVersionStateImpl extends ItemVersionState {
  _ItemVersionStateImpl({
    int? id,
    required int itemId,
    required DateTime lastEditAt,
    DateTime? dirtySince,
    DateTime? lastVersionAt,
    required List<int> editorsSinceLastVersion,
    int? lastRevision,
    DateTime? capturingSince,
  }) : super._(
         id: id,
         itemId: itemId,
         lastEditAt: lastEditAt,
         dirtySince: dirtySince,
         lastVersionAt: lastVersionAt,
         editorsSinceLastVersion: editorsSinceLastVersion,
         lastRevision: lastRevision,
         capturingSince: capturingSince,
       );

  /// Returns a shallow copy of this [ItemVersionState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ItemVersionState copyWith({
    Object? id = _Undefined,
    int? itemId,
    DateTime? lastEditAt,
    DateTime? dirtySince = const _is.$UndefinedDateTime(),
    DateTime? lastVersionAt = const _is.$UndefinedDateTime(),
    List<int>? editorsSinceLastVersion,
    Object? lastRevision = _Undefined,
    DateTime? capturingSince = const _is.$UndefinedDateTime(),
  }) {
    return ItemVersionState(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      lastEditAt: lastEditAt ?? this.lastEditAt,
      dirtySince: dirtySince is _is.UndefinedSentinel
          ? this.dirtySince
          : dirtySince,
      lastVersionAt: lastVersionAt is _is.UndefinedSentinel
          ? this.lastVersionAt
          : lastVersionAt,
      editorsSinceLastVersion:
          editorsSinceLastVersion ??
          this.editorsSinceLastVersion.map((e0) => e0).toList(),
      lastRevision: lastRevision is int? ? lastRevision : this.lastRevision,
      capturingSince: capturingSince is _is.UndefinedSentinel
          ? this.capturingSince
          : capturingSince,
    );
  }
}

class ItemVersionStateUpdateTable
    extends _is.UpdateTable<ItemVersionStateTable> {
  ItemVersionStateUpdateTable(super.table);

  _is.ColumnValue<int, int> itemId(int value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> lastEditAt(DateTime value) =>
      _is.ColumnValue(
        table.lastEditAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> dirtySince(DateTime? value) =>
      _is.ColumnValue(
        table.dirtySince,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> lastVersionAt(DateTime? value) =>
      _is.ColumnValue(
        table.lastVersionAt,
        value,
      );

  _is.ColumnValue<List<int>, List<int>> editorsSinceLastVersion(
    List<int> value,
  ) => _is.ColumnValue(
    table.editorsSinceLastVersion,
    value,
  );

  _is.ColumnValue<int, int> lastRevision(int? value) => _is.ColumnValue(
    table.lastRevision,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> capturingSince(DateTime? value) =>
      _is.ColumnValue(
        table.capturingSince,
        value,
      );
}

class ItemVersionStateTable extends _is.Table<int?> {
  ItemVersionStateTable({super.tableRelation})
    : super(tableName: 'item_version_state') {
    updateTable = ItemVersionStateUpdateTable(this);
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    lastEditAt = _is.ColumnDateTime(
      'lastEditAt',
      this,
    );
    dirtySince = _is.ColumnDateTime(
      'dirtySince',
      this,
    );
    lastVersionAt = _is.ColumnDateTime(
      'lastVersionAt',
      this,
    );
    editorsSinceLastVersion = _is.ColumnSerializable<List<int>>(
      'editorsSinceLastVersion',
      this,
    );
    lastRevision = _is.ColumnInt(
      'lastRevision',
      this,
    );
    capturingSince = _is.ColumnDateTime(
      'capturingSince',
      this,
    );
  }

  late final ItemVersionStateUpdateTable updateTable;

  late final _is.ColumnInt itemId;

  /// Last edit seen.
  late final _is.ColumnDateTime lastEditAt;

  /// First edit after the last captured version (null = clean).
  late final _is.ColumnDateTime dirtySince;

  late final _is.ColumnDateTime lastVersionAt;

  late final _is.ColumnSerializable<List<int>> editorsSinceLastVersion;

  /// Write: head revision at the last edit.
  late final _is.ColumnInt lastRevision;

  /// When a capture run claimed the item (`VersionService.captureDue`):
  /// overlapping runs skip it; a claim older than 10 minutes is taken over.
  late final _is.ColumnDateTime capturingSince;

  @override
  List<_is.Column> get columns => [
    id,
    itemId,
    lastEditAt,
    dirtySince,
    lastVersionAt,
    editorsSinceLastVersion,
    lastRevision,
    capturingSince,
  ];
}

class ItemVersionStateInclude extends _is.IncludeObject {
  ItemVersionStateInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ItemVersionState.t;
}

class ItemVersionStateIncludeList extends _is.IncludeList {
  ItemVersionStateIncludeList._({
    _is.WhereExpressionBuilder<ItemVersionStateTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ItemVersionState.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ItemVersionState.t;
}

class ItemVersionStateRepository {
  const ItemVersionStateRepository._();

  /// Returns a list of [ItemVersionState]s matching the given query parameters.
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
  Future<List<ItemVersionState>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ItemVersionStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ItemVersionStateTable>? orderBy,
    _is.OrderByListBuilder<ItemVersionStateTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ItemVersionState>(
      where: where?.call(ItemVersionState.t),
      orderBy: orderBy?.call(ItemVersionState.t),
      orderByList: orderByList?.call(ItemVersionState.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ItemVersionState]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ItemVersionState.t`.
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
  _ida.Stream<List<ItemVersionState>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ItemVersionStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ItemVersionStateTable>? orderBy,
    _is.OrderByListBuilder<ItemVersionStateTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ItemVersionState>(
      where: where?.call(ItemVersionState.t),
      orderBy: orderBy?.call(ItemVersionState.t),
      orderByList: orderByList?.call(ItemVersionState.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ItemVersionState] matching the given query parameters.
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
  Future<ItemVersionState?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ItemVersionStateTable>? where,
    int? offset,
    _is.OrderByBuilder<ItemVersionStateTable>? orderBy,
    _is.OrderByListBuilder<ItemVersionStateTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ItemVersionState>(
      where: where?.call(ItemVersionState.t),
      orderBy: orderBy?.call(ItemVersionState.t),
      orderByList: orderByList?.call(ItemVersionState.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ItemVersionState] by its [id] or null if no such row exists.
  Future<ItemVersionState?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ItemVersionState>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ItemVersionState]s in the list and returns the inserted rows.
  ///
  /// The returned [ItemVersionState]s will have their `id` fields set.
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
  Future<List<ItemVersionState>> insert(
    _is.DatabaseSession session,
    List<ItemVersionState> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ItemVersionState>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ItemVersionState] and returns the inserted row.
  ///
  /// The returned [ItemVersionState] will have its `id` field set.
  Future<ItemVersionState> insertRow(
    _is.DatabaseSession session,
    ItemVersionState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ItemVersionState>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ItemVersionState]s in the list and returns the resulting rows.
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
  /// The returned [ItemVersionState]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ItemVersionState>> upsert(
    _is.DatabaseSession session,
    List<ItemVersionState> rows, {
    required _is.ColumnSelections<ItemVersionStateTable> conflictColumns,
    _is.ColumnSelections<ItemVersionStateTable>? updateColumns,
    _is.WhereExpressionBuilder<ItemVersionStateTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ItemVersionState>(
      rows,
      conflictColumns: conflictColumns(ItemVersionState.t),
      updateColumns: updateColumns?.call(ItemVersionState.t),
      updateWhere: updateWhere?.call(ItemVersionState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ItemVersionState] and returns the resulting row.
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
  /// The returned [ItemVersionState] will have its `id` field set.
  Future<ItemVersionState?> upsertRow(
    _is.DatabaseSession session,
    ItemVersionState row, {
    required _is.ColumnSelections<ItemVersionStateTable> conflictColumns,
    _is.ColumnSelections<ItemVersionStateTable>? updateColumns,
    _is.WhereExpressionBuilder<ItemVersionStateTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ItemVersionState>(
      row,
      conflictColumns: conflictColumns(ItemVersionState.t),
      updateColumns: updateColumns?.call(ItemVersionState.t),
      updateWhere: updateWhere?.call(ItemVersionState.t),
      transaction: transaction,
    );
  }

  /// Updates all [ItemVersionState]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ItemVersionState>> update(
    _is.DatabaseSession session,
    List<ItemVersionState> rows, {
    _is.ColumnSelections<ItemVersionStateTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ItemVersionState>(
      rows,
      columns: columns?.call(ItemVersionState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ItemVersionState]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ItemVersionState> updateRow(
    _is.DatabaseSession session,
    ItemVersionState row, {
    _is.ColumnSelections<ItemVersionStateTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ItemVersionState>(
      row,
      columns: columns?.call(ItemVersionState.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ItemVersionState] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ItemVersionState?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ItemVersionStateUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ItemVersionState>(
      id,
      columnValues: columnValues(ItemVersionState.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ItemVersionState]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ItemVersionState>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ItemVersionStateUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ItemVersionStateTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ItemVersionStateTable>? orderBy,
    _is.OrderByListBuilder<ItemVersionStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ItemVersionState>(
      columnValues: columnValues(ItemVersionState.t.updateTable),
      where: where(ItemVersionState.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ItemVersionState.t),
      orderByList: orderByList?.call(ItemVersionState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ItemVersionState]s in the list and returns the deleted rows.
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
  Future<List<ItemVersionState>> delete(
    _is.DatabaseSession session,
    List<ItemVersionState> rows, {
    _is.OrderByBuilder<ItemVersionStateTable>? orderBy,
    _is.OrderByListBuilder<ItemVersionStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ItemVersionState>(
      rows,
      orderBy: orderBy?.call(ItemVersionState.t),
      orderByList: orderByList?.call(ItemVersionState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ItemVersionState].
  Future<ItemVersionState> deleteRow(
    _is.DatabaseSession session,
    ItemVersionState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ItemVersionState>(
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
  Future<List<ItemVersionState>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ItemVersionStateTable> where,
    _is.OrderByBuilder<ItemVersionStateTable>? orderBy,
    _is.OrderByListBuilder<ItemVersionStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ItemVersionState>(
      where: where(ItemVersionState.t),
      orderBy: orderBy?.call(ItemVersionState.t),
      orderByList: orderByList?.call(ItemVersionState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ItemVersionStateTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ItemVersionState>(
      where: where?.call(ItemVersionState.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ItemVersionState] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ItemVersionStateTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ItemVersionState>(
      where: where(ItemVersionState.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
