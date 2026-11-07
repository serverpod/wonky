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
import '../../../platform/ai/models/ai_provider.dart' as _i1k6plh5;

/// An organization's shared AI provider API key (suite 10 §1 "Keys"):
/// used for the requests of every member of the organization (verified
/// email domain, specs/04 §6) who has no key of their own, while the
/// server has no key. Any member may add, replace or remove it.
/// Server-only: the key is never sent to a client (clients see
/// `AiOrgKeyView`).
abstract class AiOrgKey
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AiOrgKey._({
    this.id,
    required this.orgKey,
    required this.provider,
    required this.apiKey,
    this.addedById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiOrgKey({
    int? id,
    required String orgKey,
    required _i1k6plh5.AiProvider provider,
    required String apiKey,
    int? addedById,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AiOrgKeyImpl;

  factory AiOrgKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiOrgKey(
      id: jsonSerialization['id'] as int?,
      orgKey: jsonSerialization['orgKey'] as String,
      provider: _i1k6plh5.AiProvider.fromJson(
        (jsonSerialization['provider'] as String),
      ),
      apiKey: jsonSerialization['apiKey'] as String,
      addedById: jsonSerialization['addedById'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = AiOrgKeyTable();

  static const db = AiOrgKeyRepository._();

  @override
  int? id;

  /// The organization's key (its first domain, `OrganizationService`).
  String orgKey;

  _i1k6plh5.AiProvider provider;

  String apiKey;

  /// Who added or last replaced it.
  int? addedById;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AiOrgKey]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AiOrgKey copyWith({
    int? id,
    String? orgKey,
    _i1k6plh5.AiProvider? provider,
    String? apiKey,
    int? addedById,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiOrgKey',
      if (id != null) 'id': id,
      'orgKey': orgKey,
      'provider': provider.toJson(),
      'apiKey': apiKey,
      if (addedById != null) 'addedById': addedById,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AiOrgKeyInclude include() {
    return AiOrgKeyInclude._();
  }

  static AiOrgKeyIncludeList includeList({
    _is.WhereExpressionBuilder<AiOrgKeyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiOrgKeyTable>? orderBy,
    _is.OrderByListBuilder<AiOrgKeyTable>? orderByList,
    AiOrgKeyInclude? include,
  }) {
    return AiOrgKeyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiOrgKey.t),
      orderByList: orderByList?.call(AiOrgKey.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiOrgKeyImpl extends AiOrgKey {
  _AiOrgKeyImpl({
    int? id,
    required String orgKey,
    required _i1k6plh5.AiProvider provider,
    required String apiKey,
    int? addedById,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         orgKey: orgKey,
         provider: provider,
         apiKey: apiKey,
         addedById: addedById,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [AiOrgKey]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AiOrgKey copyWith({
    Object? id = _Undefined,
    String? orgKey,
    _i1k6plh5.AiProvider? provider,
    String? apiKey,
    Object? addedById = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiOrgKey(
      id: id is int? ? id : this.id,
      orgKey: orgKey ?? this.orgKey,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      addedById: addedById is int? ? addedById : this.addedById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AiOrgKeyUpdateTable extends _is.UpdateTable<AiOrgKeyTable> {
  AiOrgKeyUpdateTable(super.table);

  _is.ColumnValue<String, String> orgKey(String value) => _is.ColumnValue(
    table.orgKey,
    value,
  );

  _is.ColumnValue<_i1k6plh5.AiProvider, _i1k6plh5.AiProvider> provider(
    _i1k6plh5.AiProvider value,
  ) => _is.ColumnValue(
    table.provider,
    value,
  );

  _is.ColumnValue<String, String> apiKey(String value) => _is.ColumnValue(
    table.apiKey,
    value,
  );

  _is.ColumnValue<int, int> addedById(int? value) => _is.ColumnValue(
    table.addedById,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class AiOrgKeyTable extends _is.Table<int?> {
  AiOrgKeyTable({super.tableRelation}) : super(tableName: 'ai_org_key') {
    updateTable = AiOrgKeyUpdateTable(this);
    orgKey = _is.ColumnString(
      'orgKey',
      this,
    );
    provider = _is.ColumnEnum(
      'provider',
      this,
      _is.EnumSerialization.byName,
    );
    apiKey = _is.ColumnString(
      'apiKey',
      this,
    );
    addedById = _is.ColumnInt(
      'addedById',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final AiOrgKeyUpdateTable updateTable;

  /// The organization's key (its first domain, `OrganizationService`).
  late final _is.ColumnString orgKey;

  late final _is.ColumnEnum<_i1k6plh5.AiProvider> provider;

  late final _is.ColumnString apiKey;

  /// Who added or last replaced it.
  late final _is.ColumnInt addedById;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [
    id,
    orgKey,
    provider,
    apiKey,
    addedById,
    createdAt,
    updatedAt,
  ];
}

class AiOrgKeyInclude extends _is.IncludeObject {
  AiOrgKeyInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AiOrgKey.t;
}

class AiOrgKeyIncludeList extends _is.IncludeList {
  AiOrgKeyIncludeList._({
    _is.WhereExpressionBuilder<AiOrgKeyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AiOrgKey.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AiOrgKey.t;
}

class AiOrgKeyRepository {
  const AiOrgKeyRepository._();

  /// Returns a list of [AiOrgKey]s matching the given query parameters.
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
  Future<List<AiOrgKey>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiOrgKeyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiOrgKeyTable>? orderBy,
    _is.OrderByListBuilder<AiOrgKeyTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AiOrgKey>(
      where: where?.call(AiOrgKey.t),
      orderBy: orderBy?.call(AiOrgKey.t),
      orderByList: orderByList?.call(AiOrgKey.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [AiOrgKey]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `AiOrgKey.t`.
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
  _ida.Stream<List<AiOrgKey>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiOrgKeyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiOrgKeyTable>? orderBy,
    _is.OrderByListBuilder<AiOrgKeyTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<AiOrgKey>(
      where: where?.call(AiOrgKey.t),
      orderBy: orderBy?.call(AiOrgKey.t),
      orderByList: orderByList?.call(AiOrgKey.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [AiOrgKey] matching the given query parameters.
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
  Future<AiOrgKey?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiOrgKeyTable>? where,
    int? offset,
    _is.OrderByBuilder<AiOrgKeyTable>? orderBy,
    _is.OrderByListBuilder<AiOrgKeyTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AiOrgKey>(
      where: where?.call(AiOrgKey.t),
      orderBy: orderBy?.call(AiOrgKey.t),
      orderByList: orderByList?.call(AiOrgKey.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AiOrgKey] by its [id] or null if no such row exists.
  Future<AiOrgKey?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AiOrgKey>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AiOrgKey]s in the list and returns the inserted rows.
  ///
  /// The returned [AiOrgKey]s will have their `id` fields set.
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
  Future<List<AiOrgKey>> insert(
    _is.DatabaseSession session,
    List<AiOrgKey> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AiOrgKey>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AiOrgKey] and returns the inserted row.
  ///
  /// The returned [AiOrgKey] will have its `id` field set.
  Future<AiOrgKey> insertRow(
    _is.DatabaseSession session,
    AiOrgKey row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AiOrgKey>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AiOrgKey]s in the list and returns the resulting rows.
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
  /// The returned [AiOrgKey]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiOrgKey>> upsert(
    _is.DatabaseSession session,
    List<AiOrgKey> rows, {
    required _is.ColumnSelections<AiOrgKeyTable> conflictColumns,
    _is.ColumnSelections<AiOrgKeyTable>? updateColumns,
    _is.WhereExpressionBuilder<AiOrgKeyTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AiOrgKey>(
      rows,
      conflictColumns: conflictColumns(AiOrgKey.t),
      updateColumns: updateColumns?.call(AiOrgKey.t),
      updateWhere: updateWhere?.call(AiOrgKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AiOrgKey] and returns the resulting row.
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
  /// The returned [AiOrgKey] will have its `id` field set.
  Future<AiOrgKey?> upsertRow(
    _is.DatabaseSession session,
    AiOrgKey row, {
    required _is.ColumnSelections<AiOrgKeyTable> conflictColumns,
    _is.ColumnSelections<AiOrgKeyTable>? updateColumns,
    _is.WhereExpressionBuilder<AiOrgKeyTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AiOrgKey>(
      row,
      conflictColumns: conflictColumns(AiOrgKey.t),
      updateColumns: updateColumns?.call(AiOrgKey.t),
      updateWhere: updateWhere?.call(AiOrgKey.t),
      transaction: transaction,
    );
  }

  /// Updates all [AiOrgKey]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiOrgKey>> update(
    _is.DatabaseSession session,
    List<AiOrgKey> rows, {
    _is.ColumnSelections<AiOrgKeyTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AiOrgKey>(
      rows,
      columns: columns?.call(AiOrgKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AiOrgKey]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AiOrgKey> updateRow(
    _is.DatabaseSession session,
    AiOrgKey row, {
    _is.ColumnSelections<AiOrgKeyTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AiOrgKey>(
      row,
      columns: columns?.call(AiOrgKey.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AiOrgKey] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AiOrgKey?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AiOrgKeyUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AiOrgKey>(
      id,
      columnValues: columnValues(AiOrgKey.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AiOrgKey]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AiOrgKey>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AiOrgKeyUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AiOrgKeyTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AiOrgKeyTable>? orderBy,
    _is.OrderByListBuilder<AiOrgKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AiOrgKey>(
      columnValues: columnValues(AiOrgKey.t.updateTable),
      where: where(AiOrgKey.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiOrgKey.t),
      orderByList: orderByList?.call(AiOrgKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AiOrgKey]s in the list and returns the deleted rows.
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
  Future<List<AiOrgKey>> delete(
    _is.DatabaseSession session,
    List<AiOrgKey> rows, {
    _is.OrderByBuilder<AiOrgKeyTable>? orderBy,
    _is.OrderByListBuilder<AiOrgKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AiOrgKey>(
      rows,
      orderBy: orderBy?.call(AiOrgKey.t),
      orderByList: orderByList?.call(AiOrgKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AiOrgKey].
  Future<AiOrgKey> deleteRow(
    _is.DatabaseSession session,
    AiOrgKey row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AiOrgKey>(
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
  Future<List<AiOrgKey>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AiOrgKeyTable> where,
    _is.OrderByBuilder<AiOrgKeyTable>? orderBy,
    _is.OrderByListBuilder<AiOrgKeyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AiOrgKey>(
      where: where(AiOrgKey.t),
      orderBy: orderBy?.call(AiOrgKey.t),
      orderByList: orderByList?.call(AiOrgKey.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AiOrgKeyTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AiOrgKey>(
      where: where?.call(AiOrgKey.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AiOrgKey] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AiOrgKeyTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AiOrgKey>(
      where: where(AiOrgKey.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
