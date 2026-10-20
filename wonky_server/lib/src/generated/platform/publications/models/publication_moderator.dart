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

/// A moderator of a publication (specs/18 §5.1): gets Commenter on the
/// publication's open submissions. Pending ([userId] null) until the
/// email signs up.
abstract class PublicationModerator
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PublicationModerator._({
    this.id,
    required this.publicationId,
    this.userId,
    required this.email,
  });

  factory PublicationModerator({
    int? id,
    required int publicationId,
    int? userId,
    required String email,
  }) = _PublicationModeratorImpl;

  factory PublicationModerator.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PublicationModerator(
      id: jsonSerialization['id'] as int?,
      publicationId: jsonSerialization['publicationId'] as int,
      userId: jsonSerialization['userId'] as int?,
      email: jsonSerialization['email'] as String,
    );
  }

  static final t = PublicationModeratorTable();

  static const db = PublicationModeratorRepository._();

  @override
  int? id;

  int publicationId;

  int? userId;

  /// Lower-case email; kept after sign-up for display.
  String email;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PublicationModerator]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationModerator copyWith({
    int? id,
    int? publicationId,
    int? userId,
    String? email,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationModerator',
      if (id != null) 'id': id,
      'publicationId': publicationId,
      if (userId != null) 'userId': userId,
      'email': email,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PublicationModeratorInclude include() {
    return PublicationModeratorInclude._();
  }

  static PublicationModeratorIncludeList includeList({
    _is.WhereExpressionBuilder<PublicationModeratorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationModeratorTable>? orderBy,
    _is.OrderByListBuilder<PublicationModeratorTable>? orderByList,
    PublicationModeratorInclude? include,
  }) {
    return PublicationModeratorIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PublicationModerator.t),
      orderByList: orderByList?.call(PublicationModerator.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationModeratorImpl extends PublicationModerator {
  _PublicationModeratorImpl({
    int? id,
    required int publicationId,
    int? userId,
    required String email,
  }) : super._(
         id: id,
         publicationId: publicationId,
         userId: userId,
         email: email,
       );

  /// Returns a shallow copy of this [PublicationModerator]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationModerator copyWith({
    Object? id = _Undefined,
    int? publicationId,
    Object? userId = _Undefined,
    String? email,
  }) {
    return PublicationModerator(
      id: id is int? ? id : this.id,
      publicationId: publicationId ?? this.publicationId,
      userId: userId is int? ? userId : this.userId,
      email: email ?? this.email,
    );
  }
}

class PublicationModeratorUpdateTable
    extends _is.UpdateTable<PublicationModeratorTable> {
  PublicationModeratorUpdateTable(super.table);

  _is.ColumnValue<int, int> publicationId(int value) => _is.ColumnValue(
    table.publicationId,
    value,
  );

  _is.ColumnValue<int, int> userId(int? value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> email(String value) => _is.ColumnValue(
    table.email,
    value,
  );
}

class PublicationModeratorTable extends _is.Table<int?> {
  PublicationModeratorTable({super.tableRelation})
    : super(tableName: 'publication_moderator') {
    updateTable = PublicationModeratorUpdateTable(this);
    publicationId = _is.ColumnInt(
      'publicationId',
      this,
    );
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    email = _is.ColumnString(
      'email',
      this,
    );
  }

  late final PublicationModeratorUpdateTable updateTable;

  late final _is.ColumnInt publicationId;

  late final _is.ColumnInt userId;

  /// Lower-case email; kept after sign-up for display.
  late final _is.ColumnString email;

  @override
  List<_is.Column> get columns => [
    id,
    publicationId,
    userId,
    email,
  ];
}

class PublicationModeratorInclude extends _is.IncludeObject {
  PublicationModeratorInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PublicationModerator.t;
}

class PublicationModeratorIncludeList extends _is.IncludeList {
  PublicationModeratorIncludeList._({
    _is.WhereExpressionBuilder<PublicationModeratorTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PublicationModerator.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PublicationModerator.t;
}

class PublicationModeratorRepository {
  const PublicationModeratorRepository._();

  /// Returns a list of [PublicationModerator]s matching the given query parameters.
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
  Future<List<PublicationModerator>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationModeratorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationModeratorTable>? orderBy,
    _is.OrderByListBuilder<PublicationModeratorTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PublicationModerator>(
      where: where?.call(PublicationModerator.t),
      orderBy: orderBy?.call(PublicationModerator.t),
      orderByList: orderByList?.call(PublicationModerator.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [PublicationModerator]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `PublicationModerator.t`.
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
  _ida.Stream<List<PublicationModerator>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationModeratorTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationModeratorTable>? orderBy,
    _is.OrderByListBuilder<PublicationModeratorTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<PublicationModerator>(
      where: where?.call(PublicationModerator.t),
      orderBy: orderBy?.call(PublicationModerator.t),
      orderByList: orderByList?.call(PublicationModerator.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [PublicationModerator] matching the given query parameters.
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
  Future<PublicationModerator?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationModeratorTable>? where,
    int? offset,
    _is.OrderByBuilder<PublicationModeratorTable>? orderBy,
    _is.OrderByListBuilder<PublicationModeratorTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PublicationModerator>(
      where: where?.call(PublicationModerator.t),
      orderBy: orderBy?.call(PublicationModerator.t),
      orderByList: orderByList?.call(PublicationModerator.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PublicationModerator] by its [id] or null if no such row exists.
  Future<PublicationModerator?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PublicationModerator>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PublicationModerator]s in the list and returns the inserted rows.
  ///
  /// The returned [PublicationModerator]s will have their `id` fields set.
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
  Future<List<PublicationModerator>> insert(
    _is.DatabaseSession session,
    List<PublicationModerator> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PublicationModerator>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PublicationModerator] and returns the inserted row.
  ///
  /// The returned [PublicationModerator] will have its `id` field set.
  Future<PublicationModerator> insertRow(
    _is.DatabaseSession session,
    PublicationModerator row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PublicationModerator>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PublicationModerator]s in the list and returns the resulting rows.
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
  /// The returned [PublicationModerator]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationModerator>> upsert(
    _is.DatabaseSession session,
    List<PublicationModerator> rows, {
    required _is.ColumnSelections<PublicationModeratorTable> conflictColumns,
    _is.ColumnSelections<PublicationModeratorTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationModeratorTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PublicationModerator>(
      rows,
      conflictColumns: conflictColumns(PublicationModerator.t),
      updateColumns: updateColumns?.call(PublicationModerator.t),
      updateWhere: updateWhere?.call(PublicationModerator.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PublicationModerator] and returns the resulting row.
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
  /// The returned [PublicationModerator] will have its `id` field set.
  Future<PublicationModerator?> upsertRow(
    _is.DatabaseSession session,
    PublicationModerator row, {
    required _is.ColumnSelections<PublicationModeratorTable> conflictColumns,
    _is.ColumnSelections<PublicationModeratorTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationModeratorTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PublicationModerator>(
      row,
      conflictColumns: conflictColumns(PublicationModerator.t),
      updateColumns: updateColumns?.call(PublicationModerator.t),
      updateWhere: updateWhere?.call(PublicationModerator.t),
      transaction: transaction,
    );
  }

  /// Updates all [PublicationModerator]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationModerator>> update(
    _is.DatabaseSession session,
    List<PublicationModerator> rows, {
    _is.ColumnSelections<PublicationModeratorTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PublicationModerator>(
      rows,
      columns: columns?.call(PublicationModerator.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PublicationModerator]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PublicationModerator> updateRow(
    _is.DatabaseSession session,
    PublicationModerator row, {
    _is.ColumnSelections<PublicationModeratorTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PublicationModerator>(
      row,
      columns: columns?.call(PublicationModerator.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PublicationModerator] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PublicationModerator?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PublicationModeratorUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PublicationModerator>(
      id,
      columnValues: columnValues(PublicationModerator.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PublicationModerator]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationModerator>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PublicationModeratorUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PublicationModeratorTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationModeratorTable>? orderBy,
    _is.OrderByListBuilder<PublicationModeratorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PublicationModerator>(
      columnValues: columnValues(PublicationModerator.t.updateTable),
      where: where(PublicationModerator.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PublicationModerator.t),
      orderByList: orderByList?.call(PublicationModerator.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PublicationModerator]s in the list and returns the deleted rows.
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
  Future<List<PublicationModerator>> delete(
    _is.DatabaseSession session,
    List<PublicationModerator> rows, {
    _is.OrderByBuilder<PublicationModeratorTable>? orderBy,
    _is.OrderByListBuilder<PublicationModeratorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PublicationModerator>(
      rows,
      orderBy: orderBy?.call(PublicationModerator.t),
      orderByList: orderByList?.call(PublicationModerator.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PublicationModerator].
  Future<PublicationModerator> deleteRow(
    _is.DatabaseSession session,
    PublicationModerator row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PublicationModerator>(
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
  Future<List<PublicationModerator>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationModeratorTable> where,
    _is.OrderByBuilder<PublicationModeratorTable>? orderBy,
    _is.OrderByListBuilder<PublicationModeratorTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PublicationModerator>(
      where: where(PublicationModerator.t),
      orderBy: orderBy?.call(PublicationModerator.t),
      orderByList: orderByList?.call(PublicationModerator.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationModeratorTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PublicationModerator>(
      where: where?.call(PublicationModerator.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PublicationModerator] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationModeratorTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PublicationModerator>(
      where: where(PublicationModerator.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
