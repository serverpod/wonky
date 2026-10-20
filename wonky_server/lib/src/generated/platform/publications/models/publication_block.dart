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

/// A user the publication doesn't take stories from (specs/18 §7.3).
abstract class PublicationBlock
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PublicationBlock._({
    this.id,
    required this.publicationId,
    required this.userId,
    required this.at,
  });

  factory PublicationBlock({
    int? id,
    required int publicationId,
    required int userId,
    required DateTime at,
  }) = _PublicationBlockImpl;

  factory PublicationBlock.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationBlock(
      id: jsonSerialization['id'] as int?,
      publicationId: jsonSerialization['publicationId'] as int,
      userId: jsonSerialization['userId'] as int,
      at: _is.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
    );
  }

  static final t = PublicationBlockTable();

  static const db = PublicationBlockRepository._();

  @override
  int? id;

  int publicationId;

  int userId;

  DateTime at;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PublicationBlock]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationBlock copyWith({
    int? id,
    int? publicationId,
    int? userId,
    DateTime? at,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationBlock',
      if (id != null) 'id': id,
      'publicationId': publicationId,
      'userId': userId,
      'at': at.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PublicationBlockInclude include() {
    return PublicationBlockInclude._();
  }

  static PublicationBlockIncludeList includeList({
    _is.WhereExpressionBuilder<PublicationBlockTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationBlockTable>? orderBy,
    _is.OrderByListBuilder<PublicationBlockTable>? orderByList,
    PublicationBlockInclude? include,
  }) {
    return PublicationBlockIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PublicationBlock.t),
      orderByList: orderByList?.call(PublicationBlock.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationBlockImpl extends PublicationBlock {
  _PublicationBlockImpl({
    int? id,
    required int publicationId,
    required int userId,
    required DateTime at,
  }) : super._(
         id: id,
         publicationId: publicationId,
         userId: userId,
         at: at,
       );

  /// Returns a shallow copy of this [PublicationBlock]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationBlock copyWith({
    Object? id = _Undefined,
    int? publicationId,
    int? userId,
    DateTime? at,
  }) {
    return PublicationBlock(
      id: id is int? ? id : this.id,
      publicationId: publicationId ?? this.publicationId,
      userId: userId ?? this.userId,
      at: at ?? this.at,
    );
  }
}

class PublicationBlockUpdateTable
    extends _is.UpdateTable<PublicationBlockTable> {
  PublicationBlockUpdateTable(super.table);

  _is.ColumnValue<int, int> publicationId(int value) => _is.ColumnValue(
    table.publicationId,
    value,
  );

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> at(DateTime value) => _is.ColumnValue(
    table.at,
    value,
  );
}

class PublicationBlockTable extends _is.Table<int?> {
  PublicationBlockTable({super.tableRelation})
    : super(tableName: 'publication_block') {
    updateTable = PublicationBlockUpdateTable(this);
    publicationId = _is.ColumnInt(
      'publicationId',
      this,
    );
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    at = _is.ColumnDateTime(
      'at',
      this,
    );
  }

  late final PublicationBlockUpdateTable updateTable;

  late final _is.ColumnInt publicationId;

  late final _is.ColumnInt userId;

  late final _is.ColumnDateTime at;

  @override
  List<_is.Column> get columns => [
    id,
    publicationId,
    userId,
    at,
  ];
}

class PublicationBlockInclude extends _is.IncludeObject {
  PublicationBlockInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PublicationBlock.t;
}

class PublicationBlockIncludeList extends _is.IncludeList {
  PublicationBlockIncludeList._({
    _is.WhereExpressionBuilder<PublicationBlockTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PublicationBlock.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PublicationBlock.t;
}

class PublicationBlockRepository {
  const PublicationBlockRepository._();

  /// Returns a list of [PublicationBlock]s matching the given query parameters.
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
  Future<List<PublicationBlock>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationBlockTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationBlockTable>? orderBy,
    _is.OrderByListBuilder<PublicationBlockTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PublicationBlock>(
      where: where?.call(PublicationBlock.t),
      orderBy: orderBy?.call(PublicationBlock.t),
      orderByList: orderByList?.call(PublicationBlock.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [PublicationBlock]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `PublicationBlock.t`.
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
  _ida.Stream<List<PublicationBlock>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationBlockTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationBlockTable>? orderBy,
    _is.OrderByListBuilder<PublicationBlockTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<PublicationBlock>(
      where: where?.call(PublicationBlock.t),
      orderBy: orderBy?.call(PublicationBlock.t),
      orderByList: orderByList?.call(PublicationBlock.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [PublicationBlock] matching the given query parameters.
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
  Future<PublicationBlock?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationBlockTable>? where,
    int? offset,
    _is.OrderByBuilder<PublicationBlockTable>? orderBy,
    _is.OrderByListBuilder<PublicationBlockTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PublicationBlock>(
      where: where?.call(PublicationBlock.t),
      orderBy: orderBy?.call(PublicationBlock.t),
      orderByList: orderByList?.call(PublicationBlock.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PublicationBlock] by its [id] or null if no such row exists.
  Future<PublicationBlock?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PublicationBlock>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PublicationBlock]s in the list and returns the inserted rows.
  ///
  /// The returned [PublicationBlock]s will have their `id` fields set.
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
  Future<List<PublicationBlock>> insert(
    _is.DatabaseSession session,
    List<PublicationBlock> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PublicationBlock>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PublicationBlock] and returns the inserted row.
  ///
  /// The returned [PublicationBlock] will have its `id` field set.
  Future<PublicationBlock> insertRow(
    _is.DatabaseSession session,
    PublicationBlock row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PublicationBlock>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PublicationBlock]s in the list and returns the resulting rows.
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
  /// The returned [PublicationBlock]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationBlock>> upsert(
    _is.DatabaseSession session,
    List<PublicationBlock> rows, {
    required _is.ColumnSelections<PublicationBlockTable> conflictColumns,
    _is.ColumnSelections<PublicationBlockTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationBlockTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PublicationBlock>(
      rows,
      conflictColumns: conflictColumns(PublicationBlock.t),
      updateColumns: updateColumns?.call(PublicationBlock.t),
      updateWhere: updateWhere?.call(PublicationBlock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PublicationBlock] and returns the resulting row.
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
  /// The returned [PublicationBlock] will have its `id` field set.
  Future<PublicationBlock?> upsertRow(
    _is.DatabaseSession session,
    PublicationBlock row, {
    required _is.ColumnSelections<PublicationBlockTable> conflictColumns,
    _is.ColumnSelections<PublicationBlockTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationBlockTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PublicationBlock>(
      row,
      conflictColumns: conflictColumns(PublicationBlock.t),
      updateColumns: updateColumns?.call(PublicationBlock.t),
      updateWhere: updateWhere?.call(PublicationBlock.t),
      transaction: transaction,
    );
  }

  /// Updates all [PublicationBlock]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationBlock>> update(
    _is.DatabaseSession session,
    List<PublicationBlock> rows, {
    _is.ColumnSelections<PublicationBlockTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PublicationBlock>(
      rows,
      columns: columns?.call(PublicationBlock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PublicationBlock]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PublicationBlock> updateRow(
    _is.DatabaseSession session,
    PublicationBlock row, {
    _is.ColumnSelections<PublicationBlockTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PublicationBlock>(
      row,
      columns: columns?.call(PublicationBlock.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PublicationBlock] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PublicationBlock?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PublicationBlockUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PublicationBlock>(
      id,
      columnValues: columnValues(PublicationBlock.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PublicationBlock]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationBlock>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PublicationBlockUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PublicationBlockTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationBlockTable>? orderBy,
    _is.OrderByListBuilder<PublicationBlockTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PublicationBlock>(
      columnValues: columnValues(PublicationBlock.t.updateTable),
      where: where(PublicationBlock.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PublicationBlock.t),
      orderByList: orderByList?.call(PublicationBlock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PublicationBlock]s in the list and returns the deleted rows.
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
  Future<List<PublicationBlock>> delete(
    _is.DatabaseSession session,
    List<PublicationBlock> rows, {
    _is.OrderByBuilder<PublicationBlockTable>? orderBy,
    _is.OrderByListBuilder<PublicationBlockTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PublicationBlock>(
      rows,
      orderBy: orderBy?.call(PublicationBlock.t),
      orderByList: orderByList?.call(PublicationBlock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PublicationBlock].
  Future<PublicationBlock> deleteRow(
    _is.DatabaseSession session,
    PublicationBlock row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PublicationBlock>(
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
  Future<List<PublicationBlock>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationBlockTable> where,
    _is.OrderByBuilder<PublicationBlockTable>? orderBy,
    _is.OrderByListBuilder<PublicationBlockTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PublicationBlock>(
      where: where(PublicationBlock.t),
      orderBy: orderBy?.call(PublicationBlock.t),
      orderByList: orderByList?.call(PublicationBlock.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationBlockTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PublicationBlock>(
      where: where?.call(PublicationBlock.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PublicationBlock] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationBlockTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PublicationBlock>(
      where: where(PublicationBlock.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
