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
import '../../platform/notifications/notification_kind.dart' as _ike46sel;

/// An in-app notification (specs/07 §4). Named UserNotification so it does
/// not clash with Flutter's `Notification`.
abstract class UserNotification
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  UserNotification._({
    this.id,
    required this.userId,
    required this.kind,
    this.itemId,
    this.actorId,
    required this.payload,
    required this.createdAt,
    this.readAt,
    this.emailedAt,
    bool? emailPending,
  }) : emailPending = emailPending ?? false;

  factory UserNotification({
    int? id,
    required int userId,
    required _ike46sel.NotificationKind kind,
    int? itemId,
    int? actorId,
    required String payload,
    required DateTime createdAt,
    DateTime? readAt,
    DateTime? emailedAt,
    bool? emailPending,
  }) = _UserNotificationImpl;

  factory UserNotification.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserNotification(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      kind: _ike46sel.NotificationKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      itemId: jsonSerialization['itemId'] as int?,
      actorId: jsonSerialization['actorId'] as int?,
      payload: jsonSerialization['payload'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      readAt: jsonSerialization['readAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['readAt']),
      emailedAt: jsonSerialization['emailedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['emailedAt']),
      emailPending: jsonSerialization['emailPending'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['emailPending']),
    );
  }

  static final t = UserNotificationTable();

  static const db = UserNotificationRepository._();

  @override
  int? id;

  int userId;

  _ike46sel.NotificationKind kind;

  int? itemId;

  int? actorId;

  /// JSON payload for rendering (names, quoted text, links).
  String payload;

  DateTime createdAt;

  DateTime? readAt;

  /// When it was included in an email digest.
  DateTime? emailedAt;

  /// Waiting to be emailed: set when its kind was set to email at creation,
  /// cleared when an email claims it (before sending), when it was read, or
  /// after the 2-day email window. Keeps the digest scan to the rows that
  /// still need an email.
  bool? emailPending;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [UserNotification]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  UserNotification copyWith({
    int? id,
    int? userId,
    _ike46sel.NotificationKind? kind,
    int? itemId,
    int? actorId,
    String? payload,
    DateTime? createdAt,
    DateTime? readAt = const _is.$UndefinedDateTime(),
    DateTime? emailedAt = const _is.$UndefinedDateTime(),
    bool? emailPending,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserNotification',
      if (id != null) 'id': id,
      'userId': userId,
      'kind': kind.toJson(),
      if (itemId != null) 'itemId': itemId,
      if (actorId != null) 'actorId': actorId,
      'payload': payload,
      'createdAt': createdAt.toJson(),
      if (readAt != null) 'readAt': readAt?.toJson(),
      if (emailedAt != null) 'emailedAt': emailedAt?.toJson(),
      if (emailPending != null) 'emailPending': emailPending,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserNotification',
      if (id != null) 'id': id,
      'userId': userId,
      'kind': kind.toJson(),
      if (itemId != null) 'itemId': itemId,
      if (actorId != null) 'actorId': actorId,
      'payload': payload,
      'createdAt': createdAt.toJson(),
      if (readAt != null) 'readAt': readAt?.toJson(),
    };
  }

  static UserNotificationInclude include() {
    return UserNotificationInclude._();
  }

  static UserNotificationIncludeList includeList({
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    UserNotificationInclude? include,
  }) {
    return UserNotificationIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserNotificationImpl extends UserNotification {
  _UserNotificationImpl({
    int? id,
    required int userId,
    required _ike46sel.NotificationKind kind,
    int? itemId,
    int? actorId,
    required String payload,
    required DateTime createdAt,
    DateTime? readAt,
    DateTime? emailedAt,
    bool? emailPending,
  }) : super._(
         id: id,
         userId: userId,
         kind: kind,
         itemId: itemId,
         actorId: actorId,
         payload: payload,
         createdAt: createdAt,
         readAt: readAt,
         emailedAt: emailedAt,
         emailPending: emailPending,
       );

  /// Returns a shallow copy of this [UserNotification]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  UserNotification copyWith({
    Object? id = _Undefined,
    int? userId,
    _ike46sel.NotificationKind? kind,
    Object? itemId = _Undefined,
    Object? actorId = _Undefined,
    String? payload,
    DateTime? createdAt,
    DateTime? readAt = const _is.$UndefinedDateTime(),
    DateTime? emailedAt = const _is.$UndefinedDateTime(),
    Object? emailPending = _Undefined,
  }) {
    return UserNotification(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      kind: kind ?? this.kind,
      itemId: itemId is int? ? itemId : this.itemId,
      actorId: actorId is int? ? actorId : this.actorId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt is _is.UndefinedSentinel ? this.readAt : readAt,
      emailedAt: emailedAt is _is.UndefinedSentinel
          ? this.emailedAt
          : emailedAt,
      emailPending: emailPending is bool? ? emailPending : this.emailPending,
    );
  }
}

class UserNotificationUpdateTable
    extends _is.UpdateTable<UserNotificationTable> {
  UserNotificationUpdateTable(super.table);

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<_ike46sel.NotificationKind, _ike46sel.NotificationKind> kind(
    _ike46sel.NotificationKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<int, int> itemId(int? value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<int, int> actorId(int? value) => _is.ColumnValue(
    table.actorId,
    value,
  );

  _is.ColumnValue<String, String> payload(String value) => _is.ColumnValue(
    table.payload,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> readAt(DateTime? value) =>
      _is.ColumnValue(
        table.readAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> emailedAt(DateTime? value) =>
      _is.ColumnValue(
        table.emailedAt,
        value,
      );

  _is.ColumnValue<bool, bool> emailPending(bool? value) => _is.ColumnValue(
    table.emailPending,
    value,
  );
}

class UserNotificationTable extends _is.Table<int?> {
  UserNotificationTable({super.tableRelation})
    : super(tableName: 'notification') {
    updateTable = UserNotificationUpdateTable(this);
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    actorId = _is.ColumnInt(
      'actorId',
      this,
    );
    payload = _is.ColumnString(
      'payload',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    readAt = _is.ColumnDateTime(
      'readAt',
      this,
    );
    emailedAt = _is.ColumnDateTime(
      'emailedAt',
      this,
    );
    emailPending = _is.ColumnBool(
      'emailPending',
      this,
      hasDefault: true,
    );
  }

  late final UserNotificationUpdateTable updateTable;

  late final _is.ColumnInt userId;

  late final _is.ColumnEnum<_ike46sel.NotificationKind> kind;

  late final _is.ColumnInt itemId;

  late final _is.ColumnInt actorId;

  /// JSON payload for rendering (names, quoted text, links).
  late final _is.ColumnString payload;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime readAt;

  /// When it was included in an email digest.
  late final _is.ColumnDateTime emailedAt;

  /// Waiting to be emailed: set when its kind was set to email at creation,
  /// cleared when an email claims it (before sending), when it was read, or
  /// after the 2-day email window. Keeps the digest scan to the rows that
  /// still need an email.
  late final _is.ColumnBool emailPending;

  @override
  List<_is.Column> get columns => [
    id,
    userId,
    kind,
    itemId,
    actorId,
    payload,
    createdAt,
    readAt,
    emailedAt,
    emailPending,
  ];
}

class UserNotificationInclude extends _is.IncludeObject {
  UserNotificationInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => UserNotification.t;
}

class UserNotificationIncludeList extends _is.IncludeList {
  UserNotificationIncludeList._({
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(UserNotification.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => UserNotification.t;
}

class UserNotificationRepository {
  const UserNotificationRepository._();

  /// Returns a list of [UserNotification]s matching the given query parameters.
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
  Future<List<UserNotification>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<UserNotification>(
      where: where?.call(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [UserNotification]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `UserNotification.t`.
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
  _ida.Stream<List<UserNotification>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<UserNotification>(
      where: where?.call(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [UserNotification] matching the given query parameters.
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
  Future<UserNotification?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<UserNotification>(
      where: where?.call(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [UserNotification] by its [id] or null if no such row exists.
  Future<UserNotification?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<UserNotification>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [UserNotification]s in the list and returns the inserted rows.
  ///
  /// The returned [UserNotification]s will have their `id` fields set.
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
  Future<List<UserNotification>> insert(
    _is.DatabaseSession session,
    List<UserNotification> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<UserNotification>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [UserNotification] and returns the inserted row.
  ///
  /// The returned [UserNotification] will have its `id` field set.
  Future<UserNotification> insertRow(
    _is.DatabaseSession session,
    UserNotification row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<UserNotification>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [UserNotification]s in the list and returns the resulting rows.
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
  /// The returned [UserNotification]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UserNotification>> upsert(
    _is.DatabaseSession session,
    List<UserNotification> rows, {
    required _is.ColumnSelections<UserNotificationTable> conflictColumns,
    _is.ColumnSelections<UserNotificationTable>? updateColumns,
    _is.WhereExpressionBuilder<UserNotificationTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<UserNotification>(
      rows,
      conflictColumns: conflictColumns(UserNotification.t),
      updateColumns: updateColumns?.call(UserNotification.t),
      updateWhere: updateWhere?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [UserNotification] and returns the resulting row.
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
  /// The returned [UserNotification] will have its `id` field set.
  Future<UserNotification?> upsertRow(
    _is.DatabaseSession session,
    UserNotification row, {
    required _is.ColumnSelections<UserNotificationTable> conflictColumns,
    _is.ColumnSelections<UserNotificationTable>? updateColumns,
    _is.WhereExpressionBuilder<UserNotificationTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<UserNotification>(
      row,
      conflictColumns: conflictColumns(UserNotification.t),
      updateColumns: updateColumns?.call(UserNotification.t),
      updateWhere: updateWhere?.call(UserNotification.t),
      transaction: transaction,
    );
  }

  /// Updates all [UserNotification]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UserNotification>> update(
    _is.DatabaseSession session,
    List<UserNotification> rows, {
    _is.ColumnSelections<UserNotificationTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<UserNotification>(
      rows,
      columns: columns?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [UserNotification]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<UserNotification> updateRow(
    _is.DatabaseSession session,
    UserNotification row, {
    _is.ColumnSelections<UserNotificationTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<UserNotification>(
      row,
      columns: columns?.call(UserNotification.t),
      transaction: transaction,
    );
  }

  /// Updates a single [UserNotification] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<UserNotification?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<UserNotificationUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<UserNotification>(
      id,
      columnValues: columnValues(UserNotification.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [UserNotification]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<UserNotification>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<UserNotificationUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<UserNotificationTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<UserNotification>(
      columnValues: columnValues(UserNotification.t.updateTable),
      where: where(UserNotification.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [UserNotification]s in the list and returns the deleted rows.
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
  Future<List<UserNotification>> delete(
    _is.DatabaseSession session,
    List<UserNotification> rows, {
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<UserNotification>(
      rows,
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [UserNotification].
  Future<UserNotification> deleteRow(
    _is.DatabaseSession session,
    UserNotification row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<UserNotification>(
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
  Future<List<UserNotification>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UserNotificationTable> where,
    _is.OrderByBuilder<UserNotificationTable>? orderBy,
    _is.OrderByListBuilder<UserNotificationTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<UserNotification>(
      where: where(UserNotification.t),
      orderBy: orderBy?.call(UserNotification.t),
      orderByList: orderByList?.call(UserNotification.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<UserNotificationTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<UserNotification>(
      where: where?.call(UserNotification.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [UserNotification] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<UserNotificationTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<UserNotification>(
      where: where(UserNotification.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
