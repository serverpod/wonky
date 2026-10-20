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
import '../../platform/common/access_role.dart' as _iv7g6vuy;

/// A role grant on a drive item (specs/06 §2). Grants on folders are
/// materialized on every descendant with [inheritedFromId].
abstract class DriveItemPermission
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  DriveItemPermission._({
    this.id,
    required this.itemId,
    this.userId,
    this.invitedEmail,
    required this.role,
    this.inheritedFromId,
    required this.grantedById,
    required this.grantedAt,
    this.expiresAt,
    this.viaPublicationId,
  });

  factory DriveItemPermission({
    int? id,
    required int itemId,
    int? userId,
    String? invitedEmail,
    required _iv7g6vuy.AccessRole role,
    int? inheritedFromId,
    required int grantedById,
    required DateTime grantedAt,
    DateTime? expiresAt,
    int? viaPublicationId,
  }) = _DriveItemPermissionImpl;

  factory DriveItemPermission.fromJson(Map<String, dynamic> jsonSerialization) {
    return DriveItemPermission(
      id: jsonSerialization['id'] as int?,
      itemId: jsonSerialization['itemId'] as int,
      userId: jsonSerialization['userId'] as int?,
      invitedEmail: jsonSerialization['invitedEmail'] as String?,
      role: _iv7g6vuy.AccessRole.fromJson(
        (jsonSerialization['role'] as String),
      ),
      inheritedFromId: jsonSerialization['inheritedFromId'] as int?,
      grantedById: jsonSerialization['grantedById'] as int,
      grantedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['grantedAt'],
      ),
      expiresAt: jsonSerialization['expiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['expiresAt']),
      viaPublicationId: jsonSerialization['viaPublicationId'] as int?,
    );
  }

  static final t = DriveItemPermissionTable();

  static const db = DriveItemPermissionRepository._();

  @override
  int? id;

  int itemId;

  /// Null while the invite is pending (no account yet).
  int? userId;

  String? invitedEmail;

  _iv7g6vuy.AccessRole role;

  /// The folder item the grant was inherited from (null = direct).
  int? inheritedFromId;

  int grantedById;

  DateTime grantedAt;

  DateTime? expiresAt;

  /// (M14) Moderator grant of a submission (specs/18 §5.1); removed with it.
  int? viaPublicationId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [DriveItemPermission]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DriveItemPermission copyWith({
    int? id,
    int? itemId,
    int? userId,
    String? invitedEmail,
    _iv7g6vuy.AccessRole? role,
    int? inheritedFromId,
    int? grantedById,
    DateTime? grantedAt,
    DateTime? expiresAt = const _is.$UndefinedDateTime(),
    int? viaPublicationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DriveItemPermission',
      if (id != null) 'id': id,
      'itemId': itemId,
      if (userId != null) 'userId': userId,
      if (invitedEmail != null) 'invitedEmail': invitedEmail,
      'role': role.toJson(),
      if (inheritedFromId != null) 'inheritedFromId': inheritedFromId,
      'grantedById': grantedById,
      'grantedAt': grantedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (viaPublicationId != null) 'viaPublicationId': viaPublicationId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'DriveItemPermission',
      if (id != null) 'id': id,
      'itemId': itemId,
      if (userId != null) 'userId': userId,
      if (invitedEmail != null) 'invitedEmail': invitedEmail,
      'role': role.toJson(),
      if (inheritedFromId != null) 'inheritedFromId': inheritedFromId,
      'grantedById': grantedById,
      'grantedAt': grantedAt.toJson(),
      if (expiresAt != null) 'expiresAt': expiresAt?.toJson(),
      if (viaPublicationId != null) 'viaPublicationId': viaPublicationId,
    };
  }

  static DriveItemPermissionInclude include() {
    return DriveItemPermissionInclude._();
  }

  static DriveItemPermissionIncludeList includeList({
    _is.WhereExpressionBuilder<DriveItemPermissionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DriveItemPermissionTable>? orderBy,
    _is.OrderByListBuilder<DriveItemPermissionTable>? orderByList,
    DriveItemPermissionInclude? include,
  }) {
    return DriveItemPermissionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DriveItemPermission.t),
      orderByList: orderByList?.call(DriveItemPermission.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DriveItemPermissionImpl extends DriveItemPermission {
  _DriveItemPermissionImpl({
    int? id,
    required int itemId,
    int? userId,
    String? invitedEmail,
    required _iv7g6vuy.AccessRole role,
    int? inheritedFromId,
    required int grantedById,
    required DateTime grantedAt,
    DateTime? expiresAt,
    int? viaPublicationId,
  }) : super._(
         id: id,
         itemId: itemId,
         userId: userId,
         invitedEmail: invitedEmail,
         role: role,
         inheritedFromId: inheritedFromId,
         grantedById: grantedById,
         grantedAt: grantedAt,
         expiresAt: expiresAt,
         viaPublicationId: viaPublicationId,
       );

  /// Returns a shallow copy of this [DriveItemPermission]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DriveItemPermission copyWith({
    Object? id = _Undefined,
    int? itemId,
    Object? userId = _Undefined,
    Object? invitedEmail = _Undefined,
    _iv7g6vuy.AccessRole? role,
    Object? inheritedFromId = _Undefined,
    int? grantedById,
    DateTime? grantedAt,
    DateTime? expiresAt = const _is.$UndefinedDateTime(),
    Object? viaPublicationId = _Undefined,
  }) {
    return DriveItemPermission(
      id: id is int? ? id : this.id,
      itemId: itemId ?? this.itemId,
      userId: userId is int? ? userId : this.userId,
      invitedEmail: invitedEmail is String? ? invitedEmail : this.invitedEmail,
      role: role ?? this.role,
      inheritedFromId: inheritedFromId is int?
          ? inheritedFromId
          : this.inheritedFromId,
      grantedById: grantedById ?? this.grantedById,
      grantedAt: grantedAt ?? this.grantedAt,
      expiresAt: expiresAt is _is.UndefinedSentinel
          ? this.expiresAt
          : expiresAt,
      viaPublicationId: viaPublicationId is int?
          ? viaPublicationId
          : this.viaPublicationId,
    );
  }
}

class DriveItemPermissionUpdateTable
    extends _is.UpdateTable<DriveItemPermissionTable> {
  DriveItemPermissionUpdateTable(super.table);

  _is.ColumnValue<int, int> itemId(int value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<int, int> userId(int? value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<String, String> invitedEmail(String? value) =>
      _is.ColumnValue(
        table.invitedEmail,
        value,
      );

  _is.ColumnValue<_iv7g6vuy.AccessRole, _iv7g6vuy.AccessRole> role(
    _iv7g6vuy.AccessRole value,
  ) => _is.ColumnValue(
    table.role,
    value,
  );

  _is.ColumnValue<int, int> inheritedFromId(int? value) => _is.ColumnValue(
    table.inheritedFromId,
    value,
  );

  _is.ColumnValue<int, int> grantedById(int value) => _is.ColumnValue(
    table.grantedById,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> grantedAt(DateTime value) =>
      _is.ColumnValue(
        table.grantedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<int, int> viaPublicationId(int? value) => _is.ColumnValue(
    table.viaPublicationId,
    value,
  );
}

class DriveItemPermissionTable extends _is.Table<int?> {
  DriveItemPermissionTable({super.tableRelation})
    : super(tableName: 'drive_item_permission') {
    updateTable = DriveItemPermissionUpdateTable(this);
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    invitedEmail = _is.ColumnString(
      'invitedEmail',
      this,
    );
    role = _is.ColumnEnum(
      'role',
      this,
      _is.EnumSerialization.byName,
    );
    inheritedFromId = _is.ColumnInt(
      'inheritedFromId',
      this,
    );
    grantedById = _is.ColumnInt(
      'grantedById',
      this,
    );
    grantedAt = _is.ColumnDateTime(
      'grantedAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    viaPublicationId = _is.ColumnInt(
      'viaPublicationId',
      this,
    );
  }

  late final DriveItemPermissionUpdateTable updateTable;

  late final _is.ColumnInt itemId;

  /// Null while the invite is pending (no account yet).
  late final _is.ColumnInt userId;

  late final _is.ColumnString invitedEmail;

  late final _is.ColumnEnum<_iv7g6vuy.AccessRole> role;

  /// The folder item the grant was inherited from (null = direct).
  late final _is.ColumnInt inheritedFromId;

  late final _is.ColumnInt grantedById;

  late final _is.ColumnDateTime grantedAt;

  late final _is.ColumnDateTime expiresAt;

  /// (M14) Moderator grant of a submission (specs/18 §5.1); removed with it.
  late final _is.ColumnInt viaPublicationId;

  @override
  List<_is.Column> get columns => [
    id,
    itemId,
    userId,
    invitedEmail,
    role,
    inheritedFromId,
    grantedById,
    grantedAt,
    expiresAt,
    viaPublicationId,
  ];
}

class DriveItemPermissionInclude extends _is.IncludeObject {
  DriveItemPermissionInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => DriveItemPermission.t;
}

class DriveItemPermissionIncludeList extends _is.IncludeList {
  DriveItemPermissionIncludeList._({
    _is.WhereExpressionBuilder<DriveItemPermissionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DriveItemPermission.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => DriveItemPermission.t;
}

class DriveItemPermissionRepository {
  const DriveItemPermissionRepository._();

  /// Returns a list of [DriveItemPermission]s matching the given query parameters.
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
  Future<List<DriveItemPermission>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DriveItemPermissionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DriveItemPermissionTable>? orderBy,
    _is.OrderByListBuilder<DriveItemPermissionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DriveItemPermission>(
      where: where?.call(DriveItemPermission.t),
      orderBy: orderBy?.call(DriveItemPermission.t),
      orderByList: orderByList?.call(DriveItemPermission.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DriveItemPermission]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DriveItemPermission.t`.
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
  _ida.Stream<List<DriveItemPermission>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DriveItemPermissionTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DriveItemPermissionTable>? orderBy,
    _is.OrderByListBuilder<DriveItemPermissionTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DriveItemPermission>(
      where: where?.call(DriveItemPermission.t),
      orderBy: orderBy?.call(DriveItemPermission.t),
      orderByList: orderByList?.call(DriveItemPermission.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DriveItemPermission] matching the given query parameters.
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
  Future<DriveItemPermission?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DriveItemPermissionTable>? where,
    int? offset,
    _is.OrderByBuilder<DriveItemPermissionTable>? orderBy,
    _is.OrderByListBuilder<DriveItemPermissionTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DriveItemPermission>(
      where: where?.call(DriveItemPermission.t),
      orderBy: orderBy?.call(DriveItemPermission.t),
      orderByList: orderByList?.call(DriveItemPermission.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DriveItemPermission] by its [id] or null if no such row exists.
  Future<DriveItemPermission?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DriveItemPermission>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DriveItemPermission]s in the list and returns the inserted rows.
  ///
  /// The returned [DriveItemPermission]s will have their `id` fields set.
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
  Future<List<DriveItemPermission>> insert(
    _is.DatabaseSession session,
    List<DriveItemPermission> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DriveItemPermission>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DriveItemPermission] and returns the inserted row.
  ///
  /// The returned [DriveItemPermission] will have its `id` field set.
  Future<DriveItemPermission> insertRow(
    _is.DatabaseSession session,
    DriveItemPermission row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DriveItemPermission>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DriveItemPermission]s in the list and returns the resulting rows.
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
  /// The returned [DriveItemPermission]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DriveItemPermission>> upsert(
    _is.DatabaseSession session,
    List<DriveItemPermission> rows, {
    required _is.ColumnSelections<DriveItemPermissionTable> conflictColumns,
    _is.ColumnSelections<DriveItemPermissionTable>? updateColumns,
    _is.WhereExpressionBuilder<DriveItemPermissionTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DriveItemPermission>(
      rows,
      conflictColumns: conflictColumns(DriveItemPermission.t),
      updateColumns: updateColumns?.call(DriveItemPermission.t),
      updateWhere: updateWhere?.call(DriveItemPermission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DriveItemPermission] and returns the resulting row.
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
  /// The returned [DriveItemPermission] will have its `id` field set.
  Future<DriveItemPermission?> upsertRow(
    _is.DatabaseSession session,
    DriveItemPermission row, {
    required _is.ColumnSelections<DriveItemPermissionTable> conflictColumns,
    _is.ColumnSelections<DriveItemPermissionTable>? updateColumns,
    _is.WhereExpressionBuilder<DriveItemPermissionTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DriveItemPermission>(
      row,
      conflictColumns: conflictColumns(DriveItemPermission.t),
      updateColumns: updateColumns?.call(DriveItemPermission.t),
      updateWhere: updateWhere?.call(DriveItemPermission.t),
      transaction: transaction,
    );
  }

  /// Updates all [DriveItemPermission]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DriveItemPermission>> update(
    _is.DatabaseSession session,
    List<DriveItemPermission> rows, {
    _is.ColumnSelections<DriveItemPermissionTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DriveItemPermission>(
      rows,
      columns: columns?.call(DriveItemPermission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DriveItemPermission]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DriveItemPermission> updateRow(
    _is.DatabaseSession session,
    DriveItemPermission row, {
    _is.ColumnSelections<DriveItemPermissionTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DriveItemPermission>(
      row,
      columns: columns?.call(DriveItemPermission.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DriveItemPermission] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DriveItemPermission?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<DriveItemPermissionUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DriveItemPermission>(
      id,
      columnValues: columnValues(DriveItemPermission.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DriveItemPermission]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DriveItemPermission>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DriveItemPermissionUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<DriveItemPermissionTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DriveItemPermissionTable>? orderBy,
    _is.OrderByListBuilder<DriveItemPermissionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DriveItemPermission>(
      columnValues: columnValues(DriveItemPermission.t.updateTable),
      where: where(DriveItemPermission.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DriveItemPermission.t),
      orderByList: orderByList?.call(DriveItemPermission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DriveItemPermission]s in the list and returns the deleted rows.
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
  Future<List<DriveItemPermission>> delete(
    _is.DatabaseSession session,
    List<DriveItemPermission> rows, {
    _is.OrderByBuilder<DriveItemPermissionTable>? orderBy,
    _is.OrderByListBuilder<DriveItemPermissionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DriveItemPermission>(
      rows,
      orderBy: orderBy?.call(DriveItemPermission.t),
      orderByList: orderByList?.call(DriveItemPermission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DriveItemPermission].
  Future<DriveItemPermission> deleteRow(
    _is.DatabaseSession session,
    DriveItemPermission row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DriveItemPermission>(
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
  Future<List<DriveItemPermission>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DriveItemPermissionTable> where,
    _is.OrderByBuilder<DriveItemPermissionTable>? orderBy,
    _is.OrderByListBuilder<DriveItemPermissionTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DriveItemPermission>(
      where: where(DriveItemPermission.t),
      orderBy: orderBy?.call(DriveItemPermission.t),
      orderByList: orderByList?.call(DriveItemPermission.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DriveItemPermissionTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DriveItemPermission>(
      where: where?.call(DriveItemPermission.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DriveItemPermission] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DriveItemPermissionTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DriveItemPermission>(
      where: where(DriveItemPermission.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
