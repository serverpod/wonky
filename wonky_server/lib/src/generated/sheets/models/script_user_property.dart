/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:wonky_server/src/generated/protocol.dart' as _il4umwa0;
import '../../platform/users/user_profile.dart' as _iydvq9l3;

/// Per-user script properties of a spreadsheet (RevLog spec 02 §2.4,
/// Sheets 09 §6.9): private to the user, read and written by the user's
/// scripts through `sheets.getUserProperties`/`setUserProperties`.
abstract class ScriptUserProperty
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ScriptUserProperty._({
    this.id,
    required this.userId,
    this.user,
    required this.fileUuid,
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  factory ScriptUserProperty({
    int? id,
    required int userId,
    _iydvq9l3.UserProfile? user,
    required _is.UuidValue fileUuid,
    required String key,
    required String value,
    required DateTime updatedAt,
  }) = _ScriptUserPropertyImpl;

  factory ScriptUserProperty.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScriptUserProperty(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      user: jsonSerialization['user'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_iydvq9l3.UserProfile>(
              jsonSerialization['user'],
            ),
      fileUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['fileUuid'],
      ),
      key: jsonSerialization['key'] as String,
      value: jsonSerialization['value'] as String,
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ScriptUserPropertyTable();

  static const db = ScriptUserPropertyRepository._();

  @override
  int? id;

  int userId;

  _iydvq9l3.UserProfile? user;

  _is.UuidValue fileUuid;

  String key;

  String value;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ScriptUserProperty]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScriptUserProperty copyWith({
    int? id,
    int? userId,
    _iydvq9l3.UserProfile? user = const _UndefinedScriptUserProperty$user(),
    _is.UuidValue? fileUuid,
    String? key,
    String? value,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScriptUserProperty',
      if (id != null) 'id': id,
      'userId': userId,
      if (user != null) 'user': user?.toJson(),
      'fileUuid': fileUuid.toJson(),
      'key': key,
      'value': value,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ScriptUserPropertyInclude include({
    _iydvq9l3.UserProfileInclude? user,
  }) {
    return ScriptUserPropertyInclude._(user: user);
  }

  static ScriptUserPropertyIncludeList includeList({
    _is.WhereExpressionBuilder<ScriptUserPropertyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptUserPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptUserPropertyTable>? orderByList,
    ScriptUserPropertyInclude? include,
  }) {
    return ScriptUserPropertyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptUserProperty.t),
      orderByList: orderByList?.call(ScriptUserProperty.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedScriptUserProperty$user extends _is.UndefinedSentinel
    implements _iydvq9l3.UserProfile {
  const _UndefinedScriptUserProperty$user();
}

class _ScriptUserPropertyImpl extends ScriptUserProperty {
  _ScriptUserPropertyImpl({
    int? id,
    required int userId,
    _iydvq9l3.UserProfile? user,
    required _is.UuidValue fileUuid,
    required String key,
    required String value,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         user: user,
         fileUuid: fileUuid,
         key: key,
         value: value,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ScriptUserProperty]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ScriptUserProperty copyWith({
    Object? id = _Undefined,
    int? userId,
    _iydvq9l3.UserProfile? user = const _UndefinedScriptUserProperty$user(),
    _is.UuidValue? fileUuid,
    String? key,
    String? value,
    DateTime? updatedAt,
  }) {
    return ScriptUserProperty(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      user: user is _is.UndefinedSentinel ? this.user?.copyWith() : user,
      fileUuid: fileUuid ?? this.fileUuid,
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ScriptUserPropertyUpdateTable
    extends _is.UpdateTable<ScriptUserPropertyTable> {
  ScriptUserPropertyUpdateTable(super.table);

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> fileUuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.fileUuid,
        value,
      );

  _is.ColumnValue<String, String> key(String value) => _is.ColumnValue(
    table.key,
    value,
  );

  _is.ColumnValue<String, String> value(String value) => _is.ColumnValue(
    table.value,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class ScriptUserPropertyTable extends _is.Table<int?> {
  ScriptUserPropertyTable({super.tableRelation})
    : super(tableName: 'script_user_property') {
    updateTable = ScriptUserPropertyUpdateTable(this);
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    fileUuid = _is.ColumnUuid(
      'fileUuid',
      this,
    );
    key = _is.ColumnString(
      'key',
      this,
    );
    value = _is.ColumnString(
      'value',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final ScriptUserPropertyUpdateTable updateTable;

  late final _is.ColumnInt userId;

  _iydvq9l3.UserProfileTable? _user;

  late final _is.ColumnUuid fileUuid;

  late final _is.ColumnString key;

  late final _is.ColumnString value;

  late final _is.ColumnDateTime updatedAt;

  _iydvq9l3.UserProfileTable get user {
    if (_user != null) return _user!;
    _user = _is.createRelationTable(
      relationFieldName: 'user',
      field: ScriptUserProperty.t.userId,
      foreignField: _iydvq9l3.UserProfile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iydvq9l3.UserProfileTable(tableRelation: foreignTableRelation),
    );
    return _user!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    fileUuid,
    key,
    value,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'user') {
      return user;
    }
    return null;
  }
}

class ScriptUserPropertyInclude extends _is.IncludeObject {
  ScriptUserPropertyInclude._({_iydvq9l3.UserProfileInclude? user}) {
    _user = user;
  }

  _iydvq9l3.UserProfileInclude? _user;

  @override
  Map<String, _is.Include?> get includes => {'user': _user};

  @override
  _is.Table<int?> get table => ScriptUserProperty.t;
}

class ScriptUserPropertyIncludeList extends _is.IncludeList {
  ScriptUserPropertyIncludeList._({
    _is.WhereExpressionBuilder<ScriptUserPropertyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ScriptUserProperty.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ScriptUserProperty.t;
}

class ScriptUserPropertyRepository {
  const ScriptUserPropertyRepository._();

  final attachRow = const ScriptUserPropertyAttachRowRepository._();

  /// Returns a list of [ScriptUserProperty]s matching the given query parameters.
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
  Future<List<ScriptUserProperty>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptUserPropertyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptUserPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptUserPropertyTable>? orderByList,
    _is.Transaction? transaction,
    ScriptUserPropertyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ScriptUserProperty>(
      where: where?.call(ScriptUserProperty.t),
      orderBy: orderBy?.call(ScriptUserProperty.t),
      orderByList: orderByList?.call(ScriptUserProperty.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ScriptUserProperty]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ScriptUserProperty.t`.
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
  _ida.Stream<List<ScriptUserProperty>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptUserPropertyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptUserPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptUserPropertyTable>? orderByList,
    ScriptUserPropertyInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ScriptUserProperty>(
      where: where?.call(ScriptUserProperty.t),
      orderBy: orderBy?.call(ScriptUserProperty.t),
      orderByList: orderByList?.call(ScriptUserProperty.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ScriptUserProperty] matching the given query parameters.
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
  Future<ScriptUserProperty?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptUserPropertyTable>? where,
    int? offset,
    _is.OrderByBuilder<ScriptUserPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptUserPropertyTable>? orderByList,
    _is.Transaction? transaction,
    ScriptUserPropertyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ScriptUserProperty>(
      where: where?.call(ScriptUserProperty.t),
      orderBy: orderBy?.call(ScriptUserProperty.t),
      orderByList: orderByList?.call(ScriptUserProperty.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ScriptUserProperty] by its [id] or null if no such row exists.
  Future<ScriptUserProperty?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    ScriptUserPropertyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ScriptUserProperty>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ScriptUserProperty]s in the list and returns the inserted rows.
  ///
  /// The returned [ScriptUserProperty]s will have their `id` fields set.
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
  Future<List<ScriptUserProperty>> insert(
    _is.DatabaseSession session,
    List<ScriptUserProperty> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ScriptUserProperty>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ScriptUserProperty] and returns the inserted row.
  ///
  /// The returned [ScriptUserProperty] will have its `id` field set.
  Future<ScriptUserProperty> insertRow(
    _is.DatabaseSession session,
    ScriptUserProperty row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ScriptUserProperty>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ScriptUserProperty]s in the list and returns the resulting rows.
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
  /// The returned [ScriptUserProperty]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptUserProperty>> upsert(
    _is.DatabaseSession session,
    List<ScriptUserProperty> rows, {
    required _is.ColumnSelections<ScriptUserPropertyTable> conflictColumns,
    _is.ColumnSelections<ScriptUserPropertyTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptUserPropertyTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ScriptUserProperty>(
      rows,
      conflictColumns: conflictColumns(ScriptUserProperty.t),
      updateColumns: updateColumns?.call(ScriptUserProperty.t),
      updateWhere: updateWhere?.call(ScriptUserProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ScriptUserProperty] and returns the resulting row.
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
  /// The returned [ScriptUserProperty] will have its `id` field set.
  Future<ScriptUserProperty?> upsertRow(
    _is.DatabaseSession session,
    ScriptUserProperty row, {
    required _is.ColumnSelections<ScriptUserPropertyTable> conflictColumns,
    _is.ColumnSelections<ScriptUserPropertyTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptUserPropertyTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ScriptUserProperty>(
      row,
      conflictColumns: conflictColumns(ScriptUserProperty.t),
      updateColumns: updateColumns?.call(ScriptUserProperty.t),
      updateWhere: updateWhere?.call(ScriptUserProperty.t),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptUserProperty]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptUserProperty>> update(
    _is.DatabaseSession session,
    List<ScriptUserProperty> rows, {
    _is.ColumnSelections<ScriptUserPropertyTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ScriptUserProperty>(
      rows,
      columns: columns?.call(ScriptUserProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ScriptUserProperty]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ScriptUserProperty> updateRow(
    _is.DatabaseSession session,
    ScriptUserProperty row, {
    _is.ColumnSelections<ScriptUserPropertyTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ScriptUserProperty>(
      row,
      columns: columns?.call(ScriptUserProperty.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ScriptUserProperty] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ScriptUserProperty?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ScriptUserPropertyUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ScriptUserProperty>(
      id,
      columnValues: columnValues(ScriptUserProperty.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptUserProperty]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptUserProperty>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ScriptUserPropertyUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ScriptUserPropertyTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptUserPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptUserPropertyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ScriptUserProperty>(
      columnValues: columnValues(ScriptUserProperty.t.updateTable),
      where: where(ScriptUserProperty.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptUserProperty.t),
      orderByList: orderByList?.call(ScriptUserProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ScriptUserProperty]s in the list and returns the deleted rows.
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
  Future<List<ScriptUserProperty>> delete(
    _is.DatabaseSession session,
    List<ScriptUserProperty> rows, {
    _is.OrderByBuilder<ScriptUserPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptUserPropertyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ScriptUserProperty>(
      rows,
      orderBy: orderBy?.call(ScriptUserProperty.t),
      orderByList: orderByList?.call(ScriptUserProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ScriptUserProperty].
  Future<ScriptUserProperty> deleteRow(
    _is.DatabaseSession session,
    ScriptUserProperty row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ScriptUserProperty>(
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
  Future<List<ScriptUserProperty>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptUserPropertyTable> where,
    _is.OrderByBuilder<ScriptUserPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptUserPropertyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ScriptUserProperty>(
      where: where(ScriptUserProperty.t),
      orderBy: orderBy?.call(ScriptUserProperty.t),
      orderByList: orderByList?.call(ScriptUserProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptUserPropertyTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ScriptUserProperty>(
      where: where?.call(ScriptUserProperty.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ScriptUserProperty] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptUserPropertyTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ScriptUserProperty>(
      where: where(ScriptUserProperty.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ScriptUserPropertyAttachRowRepository {
  const ScriptUserPropertyAttachRowRepository._();

  /// Creates a relation between the given [ScriptUserProperty] and [UserProfile]
  /// by setting the [ScriptUserProperty]'s foreign key `userId` to refer to the [UserProfile].
  Future<void> user(
    _is.DatabaseSession session,
    ScriptUserProperty scriptUserProperty,
    _iydvq9l3.UserProfile user, {
    _is.Transaction? transaction,
  }) async {
    if (scriptUserProperty.id == null) {
      throw ArgumentError.notNull('scriptUserProperty.id');
    }
    if (user.id == null) {
      throw ArgumentError.notNull('user.id');
    }

    var $scriptUserProperty = scriptUserProperty.copyWith(userId: user.id);
    await session.db.updateRow<ScriptUserProperty>(
      $scriptUserProperty,
      columns: [ScriptUserProperty.t.userId],
      transaction: transaction,
    );
  }
}
