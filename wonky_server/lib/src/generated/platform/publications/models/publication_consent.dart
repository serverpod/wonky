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

/// A user's consent to write for a publication (specs/18 §3). Asked again
/// when the site host, webhook host or terms URL change ([consentKey]).
abstract class PublicationConsent
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  PublicationConsent._({
    this.id,
    required this.publicationId,
    required this.userId,
    required this.consentKey,
    required this.at,
  });

  factory PublicationConsent({
    int? id,
    required int publicationId,
    required int userId,
    required String consentKey,
    required DateTime at,
  }) = _PublicationConsentImpl;

  factory PublicationConsent.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicationConsent(
      id: jsonSerialization['id'] as int?,
      publicationId: jsonSerialization['publicationId'] as int,
      userId: jsonSerialization['userId'] as int,
      consentKey: jsonSerialization['consentKey'] as String,
      at: _is.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
    );
  }

  static final t = PublicationConsentTable();

  static const db = PublicationConsentRepository._();

  @override
  int? id;

  int publicationId;

  int userId;

  /// Hash of what was agreed to (shown host, webhook host, terms URL).
  String consentKey;

  DateTime at;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [PublicationConsent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PublicationConsent copyWith({
    int? id,
    int? publicationId,
    int? userId,
    String? consentKey,
    DateTime? at,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicationConsent',
      if (id != null) 'id': id,
      'publicationId': publicationId,
      'userId': userId,
      'consentKey': consentKey,
      'at': at.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PublicationConsentInclude include() {
    return PublicationConsentInclude._();
  }

  static PublicationConsentIncludeList includeList({
    _is.WhereExpressionBuilder<PublicationConsentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationConsentTable>? orderBy,
    _is.OrderByListBuilder<PublicationConsentTable>? orderByList,
    PublicationConsentInclude? include,
  }) {
    return PublicationConsentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PublicationConsent.t),
      orderByList: orderByList?.call(PublicationConsent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicationConsentImpl extends PublicationConsent {
  _PublicationConsentImpl({
    int? id,
    required int publicationId,
    required int userId,
    required String consentKey,
    required DateTime at,
  }) : super._(
         id: id,
         publicationId: publicationId,
         userId: userId,
         consentKey: consentKey,
         at: at,
       );

  /// Returns a shallow copy of this [PublicationConsent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PublicationConsent copyWith({
    Object? id = _Undefined,
    int? publicationId,
    int? userId,
    String? consentKey,
    DateTime? at,
  }) {
    return PublicationConsent(
      id: id is int? ? id : this.id,
      publicationId: publicationId ?? this.publicationId,
      userId: userId ?? this.userId,
      consentKey: consentKey ?? this.consentKey,
      at: at ?? this.at,
    );
  }
}

class PublicationConsentUpdateTable
    extends _is.UpdateTable<PublicationConsentTable> {
  PublicationConsentUpdateTable(super.table);

  _is.ColumnValue<int, int> publicationId(int value) => _is.ColumnValue(
    table.publicationId,
    value,
  );

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> consentKey(String value) => _is.ColumnValue(
    table.consentKey,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> at(DateTime value) => _is.ColumnValue(
    table.at,
    value,
  );
}

class PublicationConsentTable extends _is.Table<int?> {
  PublicationConsentTable({super.tableRelation})
    : super(tableName: 'publication_consent') {
    updateTable = PublicationConsentUpdateTable(this);
    publicationId = _is.ColumnInt(
      'publicationId',
      this,
    );
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    consentKey = _is.ColumnString(
      'consentKey',
      this,
    );
    at = _is.ColumnDateTime(
      'at',
      this,
    );
  }

  late final PublicationConsentUpdateTable updateTable;

  late final _is.ColumnInt publicationId;

  late final _is.ColumnInt userId;

  /// Hash of what was agreed to (shown host, webhook host, terms URL).
  late final _is.ColumnString consentKey;

  late final _is.ColumnDateTime at;

  @override
  List<_is.Column> get columns => [
    id,
    publicationId,
    userId,
    consentKey,
    at,
  ];
}

class PublicationConsentInclude extends _is.IncludeObject {
  PublicationConsentInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => PublicationConsent.t;
}

class PublicationConsentIncludeList extends _is.IncludeList {
  PublicationConsentIncludeList._({
    _is.WhereExpressionBuilder<PublicationConsentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PublicationConsent.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => PublicationConsent.t;
}

class PublicationConsentRepository {
  const PublicationConsentRepository._();

  /// Returns a list of [PublicationConsent]s matching the given query parameters.
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
  Future<List<PublicationConsent>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationConsentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationConsentTable>? orderBy,
    _is.OrderByListBuilder<PublicationConsentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PublicationConsent>(
      where: where?.call(PublicationConsent.t),
      orderBy: orderBy?.call(PublicationConsent.t),
      orderByList: orderByList?.call(PublicationConsent.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [PublicationConsent]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `PublicationConsent.t`.
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
  _ida.Stream<List<PublicationConsent>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationConsentTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationConsentTable>? orderBy,
    _is.OrderByListBuilder<PublicationConsentTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<PublicationConsent>(
      where: where?.call(PublicationConsent.t),
      orderBy: orderBy?.call(PublicationConsent.t),
      orderByList: orderByList?.call(PublicationConsent.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [PublicationConsent] matching the given query parameters.
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
  Future<PublicationConsent?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationConsentTable>? where,
    int? offset,
    _is.OrderByBuilder<PublicationConsentTable>? orderBy,
    _is.OrderByListBuilder<PublicationConsentTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PublicationConsent>(
      where: where?.call(PublicationConsent.t),
      orderBy: orderBy?.call(PublicationConsent.t),
      orderByList: orderByList?.call(PublicationConsent.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PublicationConsent] by its [id] or null if no such row exists.
  Future<PublicationConsent?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PublicationConsent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PublicationConsent]s in the list and returns the inserted rows.
  ///
  /// The returned [PublicationConsent]s will have their `id` fields set.
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
  Future<List<PublicationConsent>> insert(
    _is.DatabaseSession session,
    List<PublicationConsent> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PublicationConsent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PublicationConsent] and returns the inserted row.
  ///
  /// The returned [PublicationConsent] will have its `id` field set.
  Future<PublicationConsent> insertRow(
    _is.DatabaseSession session,
    PublicationConsent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PublicationConsent>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PublicationConsent]s in the list and returns the resulting rows.
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
  /// The returned [PublicationConsent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationConsent>> upsert(
    _is.DatabaseSession session,
    List<PublicationConsent> rows, {
    required _is.ColumnSelections<PublicationConsentTable> conflictColumns,
    _is.ColumnSelections<PublicationConsentTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationConsentTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PublicationConsent>(
      rows,
      conflictColumns: conflictColumns(PublicationConsent.t),
      updateColumns: updateColumns?.call(PublicationConsent.t),
      updateWhere: updateWhere?.call(PublicationConsent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PublicationConsent] and returns the resulting row.
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
  /// The returned [PublicationConsent] will have its `id` field set.
  Future<PublicationConsent?> upsertRow(
    _is.DatabaseSession session,
    PublicationConsent row, {
    required _is.ColumnSelections<PublicationConsentTable> conflictColumns,
    _is.ColumnSelections<PublicationConsentTable>? updateColumns,
    _is.WhereExpressionBuilder<PublicationConsentTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PublicationConsent>(
      row,
      conflictColumns: conflictColumns(PublicationConsent.t),
      updateColumns: updateColumns?.call(PublicationConsent.t),
      updateWhere: updateWhere?.call(PublicationConsent.t),
      transaction: transaction,
    );
  }

  /// Updates all [PublicationConsent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationConsent>> update(
    _is.DatabaseSession session,
    List<PublicationConsent> rows, {
    _is.ColumnSelections<PublicationConsentTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PublicationConsent>(
      rows,
      columns: columns?.call(PublicationConsent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PublicationConsent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PublicationConsent> updateRow(
    _is.DatabaseSession session,
    PublicationConsent row, {
    _is.ColumnSelections<PublicationConsentTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PublicationConsent>(
      row,
      columns: columns?.call(PublicationConsent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PublicationConsent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PublicationConsent?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<PublicationConsentUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PublicationConsent>(
      id,
      columnValues: columnValues(PublicationConsent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PublicationConsent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PublicationConsent>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PublicationConsentUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<PublicationConsentTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PublicationConsentTable>? orderBy,
    _is.OrderByListBuilder<PublicationConsentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PublicationConsent>(
      columnValues: columnValues(PublicationConsent.t.updateTable),
      where: where(PublicationConsent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PublicationConsent.t),
      orderByList: orderByList?.call(PublicationConsent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PublicationConsent]s in the list and returns the deleted rows.
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
  Future<List<PublicationConsent>> delete(
    _is.DatabaseSession session,
    List<PublicationConsent> rows, {
    _is.OrderByBuilder<PublicationConsentTable>? orderBy,
    _is.OrderByListBuilder<PublicationConsentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PublicationConsent>(
      rows,
      orderBy: orderBy?.call(PublicationConsent.t),
      orderByList: orderByList?.call(PublicationConsent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PublicationConsent].
  Future<PublicationConsent> deleteRow(
    _is.DatabaseSession session,
    PublicationConsent row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PublicationConsent>(
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
  Future<List<PublicationConsent>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationConsentTable> where,
    _is.OrderByBuilder<PublicationConsentTable>? orderBy,
    _is.OrderByListBuilder<PublicationConsentTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PublicationConsent>(
      where: where(PublicationConsent.t),
      orderBy: orderBy?.call(PublicationConsent.t),
      orderByList: orderByList?.call(PublicationConsent.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PublicationConsentTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PublicationConsent>(
      where: where?.call(PublicationConsent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PublicationConsent] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PublicationConsentTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PublicationConsent>(
      where: where(PublicationConsent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
