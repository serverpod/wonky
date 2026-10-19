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
import '../../../platform/common/actor_kind.dart' as _iqucl2d4;

/// A server-side change on a spreadsheet or deck that can be
/// reverted/reapplied (Sheets 12 §2.5, Slides 11 §1.4; undo domains
/// sheets.serverChange, slides.serverChange). `fileUuid` is the RevLog file
/// uuid (the item's `contentRef`) of either app.
abstract class ServerChangeRecord
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  ServerChangeRecord._({
    this.id,
    required this.changeId,
    required this.fileUuid,
    required this.userId,
    required this.actorKind,
    required this.label,
    this.inverseJson,
    this.inverseFileId,
    this.forwardFileId,
    this.recordId,
    required this.cellsAffected,
    required this.createdAt,
    required this.expiresAt,
    this.revertedAt,
    this.revertChangeId,
  });

  factory ServerChangeRecord({
    int? id,
    required _is.UuidValue changeId,
    required _is.UuidValue fileUuid,
    required int userId,
    required _iqucl2d4.ActorKind actorKind,
    required String label,
    String? inverseJson,
    _is.UuidValue? inverseFileId,
    _is.UuidValue? forwardFileId,
    _is.UuidValue? recordId,
    required int cellsAffected,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revertedAt,
    _is.UuidValue? revertChangeId,
  }) = _ServerChangeRecordImpl;

  factory ServerChangeRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return ServerChangeRecord(
      id: jsonSerialization['id'] as int?,
      changeId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['changeId'],
      ),
      fileUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['fileUuid'],
      ),
      userId: jsonSerialization['userId'] as int,
      actorKind: _iqucl2d4.ActorKind.fromJson(
        (jsonSerialization['actorKind'] as String),
      ),
      label: jsonSerialization['label'] as String,
      inverseJson: jsonSerialization['inverseJson'] as String?,
      inverseFileId: jsonSerialization['inverseFileId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['inverseFileId'],
            ),
      forwardFileId: jsonSerialization['forwardFileId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['forwardFileId'],
            ),
      recordId: jsonSerialization['recordId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['recordId']),
      cellsAffected: jsonSerialization['cellsAffected'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      expiresAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      revertedAt: jsonSerialization['revertedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['revertedAt']),
      revertChangeId: jsonSerialization['revertChangeId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['revertChangeId'],
            ),
    );
  }

  static final t = ServerChangeRecordTable();

  static const db = ServerChangeRecordRepository._();

  @override
  int? id;

  _is.UuidValue changeId;

  _is.UuidValue fileUuid;

  int userId;

  _iqucl2d4.ActorKind actorKind;

  String label;

  /// gzip+base64 JSON list of row changes with before/after columns.
  String? inverseJson;

  _is.UuidValue? inverseFileId;

  _is.UuidValue? forwardFileId;

  /// RevLog files: the ops of the change are the rev_op rows with this
  /// recordId; revert/reapply read their applied forms (RevLog spec 05
  /// §8.2) and the inverse fields stay null (legacy records only).
  _is.UuidValue? recordId;

  int cellsAffected;

  DateTime createdAt;

  DateTime expiresAt;

  DateTime? revertedAt;

  _is.UuidValue? revertChangeId;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [ServerChangeRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ServerChangeRecord copyWith({
    int? id,
    _is.UuidValue? changeId,
    _is.UuidValue? fileUuid,
    int? userId,
    _iqucl2d4.ActorKind? actorKind,
    String? label,
    String? inverseJson,
    _is.UuidValue? inverseFileId = const _is.$UndefinedUuidValue(),
    _is.UuidValue? forwardFileId = const _is.$UndefinedUuidValue(),
    _is.UuidValue? recordId = const _is.$UndefinedUuidValue(),
    int? cellsAffected,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? revertedAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? revertChangeId = const _is.$UndefinedUuidValue(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ServerChangeRecord',
      if (id != null) 'id': id,
      'changeId': changeId.toJson(),
      'fileUuid': fileUuid.toJson(),
      'userId': userId,
      'actorKind': actorKind.toJson(),
      'label': label,
      if (inverseJson != null) 'inverseJson': inverseJson,
      if (inverseFileId != null) 'inverseFileId': inverseFileId?.toJson(),
      if (forwardFileId != null) 'forwardFileId': forwardFileId?.toJson(),
      if (recordId != null) 'recordId': recordId?.toJson(),
      'cellsAffected': cellsAffected,
      'createdAt': createdAt.toJson(),
      'expiresAt': expiresAt.toJson(),
      if (revertedAt != null) 'revertedAt': revertedAt?.toJson(),
      if (revertChangeId != null) 'revertChangeId': revertChangeId?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ServerChangeRecordInclude include() {
    return ServerChangeRecordInclude._();
  }

  static ServerChangeRecordIncludeList includeList({
    _is.WhereExpressionBuilder<ServerChangeRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ServerChangeRecordTable>? orderBy,
    _is.OrderByListBuilder<ServerChangeRecordTable>? orderByList,
    ServerChangeRecordInclude? include,
  }) {
    return ServerChangeRecordIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ServerChangeRecord.t),
      orderByList: orderByList?.call(ServerChangeRecord.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ServerChangeRecordImpl extends ServerChangeRecord {
  _ServerChangeRecordImpl({
    int? id,
    required _is.UuidValue changeId,
    required _is.UuidValue fileUuid,
    required int userId,
    required _iqucl2d4.ActorKind actorKind,
    required String label,
    String? inverseJson,
    _is.UuidValue? inverseFileId,
    _is.UuidValue? forwardFileId,
    _is.UuidValue? recordId,
    required int cellsAffected,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? revertedAt,
    _is.UuidValue? revertChangeId,
  }) : super._(
         id: id,
         changeId: changeId,
         fileUuid: fileUuid,
         userId: userId,
         actorKind: actorKind,
         label: label,
         inverseJson: inverseJson,
         inverseFileId: inverseFileId,
         forwardFileId: forwardFileId,
         recordId: recordId,
         cellsAffected: cellsAffected,
         createdAt: createdAt,
         expiresAt: expiresAt,
         revertedAt: revertedAt,
         revertChangeId: revertChangeId,
       );

  /// Returns a shallow copy of this [ServerChangeRecord]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ServerChangeRecord copyWith({
    Object? id = _Undefined,
    _is.UuidValue? changeId,
    _is.UuidValue? fileUuid,
    int? userId,
    _iqucl2d4.ActorKind? actorKind,
    String? label,
    Object? inverseJson = _Undefined,
    _is.UuidValue? inverseFileId = const _is.$UndefinedUuidValue(),
    _is.UuidValue? forwardFileId = const _is.$UndefinedUuidValue(),
    _is.UuidValue? recordId = const _is.$UndefinedUuidValue(),
    int? cellsAffected,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? revertedAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? revertChangeId = const _is.$UndefinedUuidValue(),
  }) {
    return ServerChangeRecord(
      id: id is int? ? id : this.id,
      changeId: changeId ?? this.changeId,
      fileUuid: fileUuid ?? this.fileUuid,
      userId: userId ?? this.userId,
      actorKind: actorKind ?? this.actorKind,
      label: label ?? this.label,
      inverseJson: inverseJson is String? ? inverseJson : this.inverseJson,
      inverseFileId: inverseFileId is _is.UndefinedSentinel
          ? this.inverseFileId
          : inverseFileId,
      forwardFileId: forwardFileId is _is.UndefinedSentinel
          ? this.forwardFileId
          : forwardFileId,
      recordId: recordId is _is.UndefinedSentinel ? this.recordId : recordId,
      cellsAffected: cellsAffected ?? this.cellsAffected,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      revertedAt: revertedAt is _is.UndefinedSentinel
          ? this.revertedAt
          : revertedAt,
      revertChangeId: revertChangeId is _is.UndefinedSentinel
          ? this.revertChangeId
          : revertChangeId,
    );
  }
}

class ServerChangeRecordUpdateTable
    extends _is.UpdateTable<ServerChangeRecordTable> {
  ServerChangeRecordUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> changeId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.changeId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> fileUuid(_is.UuidValue value) =>
      _is.ColumnValue(
        table.fileUuid,
        value,
      );

  _is.ColumnValue<int, int> userId(int value) => _is.ColumnValue(
    table.userId,
    value,
  );

  _is.ColumnValue<_iqucl2d4.ActorKind, _iqucl2d4.ActorKind> actorKind(
    _iqucl2d4.ActorKind value,
  ) => _is.ColumnValue(
    table.actorKind,
    value,
  );

  _is.ColumnValue<String, String> label(String value) => _is.ColumnValue(
    table.label,
    value,
  );

  _is.ColumnValue<String, String> inverseJson(String? value) => _is.ColumnValue(
    table.inverseJson,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> inverseFileId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.inverseFileId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> forwardFileId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.forwardFileId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> recordId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.recordId,
    value,
  );

  _is.ColumnValue<int, int> cellsAffected(int value) => _is.ColumnValue(
    table.cellsAffected,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _is.ColumnValue(
        table.expiresAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> revertedAt(DateTime? value) =>
      _is.ColumnValue(
        table.revertedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> revertChangeId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.revertChangeId,
    value,
  );
}

class ServerChangeRecordTable extends _is.Table<int?> {
  ServerChangeRecordTable({super.tableRelation})
    : super(tableName: 'server_change_record') {
    updateTable = ServerChangeRecordUpdateTable(this);
    changeId = _is.ColumnUuid(
      'changeId',
      this,
    );
    fileUuid = _is.ColumnUuid(
      'fileUuid',
      this,
    );
    userId = _is.ColumnInt(
      'userId',
      this,
    );
    actorKind = _is.ColumnEnum(
      'actorKind',
      this,
      _is.EnumSerialization.byName,
    );
    label = _is.ColumnString(
      'label',
      this,
    );
    inverseJson = _is.ColumnString(
      'inverseJson',
      this,
    );
    inverseFileId = _is.ColumnUuid(
      'inverseFileId',
      this,
    );
    forwardFileId = _is.ColumnUuid(
      'forwardFileId',
      this,
    );
    recordId = _is.ColumnUuid(
      'recordId',
      this,
    );
    cellsAffected = _is.ColumnInt(
      'cellsAffected',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    expiresAt = _is.ColumnDateTime(
      'expiresAt',
      this,
    );
    revertedAt = _is.ColumnDateTime(
      'revertedAt',
      this,
    );
    revertChangeId = _is.ColumnUuid(
      'revertChangeId',
      this,
    );
  }

  late final ServerChangeRecordUpdateTable updateTable;

  late final _is.ColumnUuid changeId;

  late final _is.ColumnUuid fileUuid;

  late final _is.ColumnInt userId;

  late final _is.ColumnEnum<_iqucl2d4.ActorKind> actorKind;

  late final _is.ColumnString label;

  /// gzip+base64 JSON list of row changes with before/after columns.
  late final _is.ColumnString inverseJson;

  late final _is.ColumnUuid inverseFileId;

  late final _is.ColumnUuid forwardFileId;

  /// RevLog files: the ops of the change are the rev_op rows with this
  /// recordId; revert/reapply read their applied forms (RevLog spec 05
  /// §8.2) and the inverse fields stay null (legacy records only).
  late final _is.ColumnUuid recordId;

  late final _is.ColumnInt cellsAffected;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime expiresAt;

  late final _is.ColumnDateTime revertedAt;

  late final _is.ColumnUuid revertChangeId;

  @override
  List<_is.Column> get columns => [
    id,
    changeId,
    fileUuid,
    userId,
    actorKind,
    label,
    inverseJson,
    inverseFileId,
    forwardFileId,
    recordId,
    cellsAffected,
    createdAt,
    expiresAt,
    revertedAt,
    revertChangeId,
  ];
}

class ServerChangeRecordInclude extends _is.IncludeObject {
  ServerChangeRecordInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => ServerChangeRecord.t;
}

class ServerChangeRecordIncludeList extends _is.IncludeList {
  ServerChangeRecordIncludeList._({
    _is.WhereExpressionBuilder<ServerChangeRecordTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ServerChangeRecord.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => ServerChangeRecord.t;
}

class ServerChangeRecordRepository {
  const ServerChangeRecordRepository._();

  /// Returns a list of [ServerChangeRecord]s matching the given query parameters.
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
  Future<List<ServerChangeRecord>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ServerChangeRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ServerChangeRecordTable>? orderBy,
    _is.OrderByListBuilder<ServerChangeRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ServerChangeRecord>(
      where: where?.call(ServerChangeRecord.t),
      orderBy: orderBy?.call(ServerChangeRecord.t),
      orderByList: orderByList?.call(ServerChangeRecord.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ServerChangeRecord]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ServerChangeRecord.t`.
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
  _ida.Stream<List<ServerChangeRecord>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ServerChangeRecordTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ServerChangeRecordTable>? orderBy,
    _is.OrderByListBuilder<ServerChangeRecordTable>? orderByList,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ServerChangeRecord>(
      where: where?.call(ServerChangeRecord.t),
      orderBy: orderBy?.call(ServerChangeRecord.t),
      orderByList: orderByList?.call(ServerChangeRecord.t),
      limit: limit,
      offset: offset,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ServerChangeRecord] matching the given query parameters.
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
  Future<ServerChangeRecord?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ServerChangeRecordTable>? where,
    int? offset,
    _is.OrderByBuilder<ServerChangeRecordTable>? orderBy,
    _is.OrderByListBuilder<ServerChangeRecordTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ServerChangeRecord>(
      where: where?.call(ServerChangeRecord.t),
      orderBy: orderBy?.call(ServerChangeRecord.t),
      orderByList: orderByList?.call(ServerChangeRecord.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ServerChangeRecord] by its [id] or null if no such row exists.
  Future<ServerChangeRecord?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ServerChangeRecord>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ServerChangeRecord]s in the list and returns the inserted rows.
  ///
  /// The returned [ServerChangeRecord]s will have their `id` fields set.
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
  Future<List<ServerChangeRecord>> insert(
    _is.DatabaseSession session,
    List<ServerChangeRecord> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ServerChangeRecord>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ServerChangeRecord] and returns the inserted row.
  ///
  /// The returned [ServerChangeRecord] will have its `id` field set.
  Future<ServerChangeRecord> insertRow(
    _is.DatabaseSession session,
    ServerChangeRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ServerChangeRecord>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ServerChangeRecord]s in the list and returns the resulting rows.
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
  /// The returned [ServerChangeRecord]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ServerChangeRecord>> upsert(
    _is.DatabaseSession session,
    List<ServerChangeRecord> rows, {
    required _is.ColumnSelections<ServerChangeRecordTable> conflictColumns,
    _is.ColumnSelections<ServerChangeRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<ServerChangeRecordTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ServerChangeRecord>(
      rows,
      conflictColumns: conflictColumns(ServerChangeRecord.t),
      updateColumns: updateColumns?.call(ServerChangeRecord.t),
      updateWhere: updateWhere?.call(ServerChangeRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ServerChangeRecord] and returns the resulting row.
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
  /// The returned [ServerChangeRecord] will have its `id` field set.
  Future<ServerChangeRecord?> upsertRow(
    _is.DatabaseSession session,
    ServerChangeRecord row, {
    required _is.ColumnSelections<ServerChangeRecordTable> conflictColumns,
    _is.ColumnSelections<ServerChangeRecordTable>? updateColumns,
    _is.WhereExpressionBuilder<ServerChangeRecordTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ServerChangeRecord>(
      row,
      conflictColumns: conflictColumns(ServerChangeRecord.t),
      updateColumns: updateColumns?.call(ServerChangeRecord.t),
      updateWhere: updateWhere?.call(ServerChangeRecord.t),
      transaction: transaction,
    );
  }

  /// Updates all [ServerChangeRecord]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ServerChangeRecord>> update(
    _is.DatabaseSession session,
    List<ServerChangeRecord> rows, {
    _is.ColumnSelections<ServerChangeRecordTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ServerChangeRecord>(
      rows,
      columns: columns?.call(ServerChangeRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ServerChangeRecord]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ServerChangeRecord> updateRow(
    _is.DatabaseSession session,
    ServerChangeRecord row, {
    _is.ColumnSelections<ServerChangeRecordTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ServerChangeRecord>(
      row,
      columns: columns?.call(ServerChangeRecord.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ServerChangeRecord] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ServerChangeRecord?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ServerChangeRecordUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ServerChangeRecord>(
      id,
      columnValues: columnValues(ServerChangeRecord.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ServerChangeRecord]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ServerChangeRecord>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ServerChangeRecordUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ServerChangeRecordTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ServerChangeRecordTable>? orderBy,
    _is.OrderByListBuilder<ServerChangeRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ServerChangeRecord>(
      columnValues: columnValues(ServerChangeRecord.t.updateTable),
      where: where(ServerChangeRecord.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ServerChangeRecord.t),
      orderByList: orderByList?.call(ServerChangeRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ServerChangeRecord]s in the list and returns the deleted rows.
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
  Future<List<ServerChangeRecord>> delete(
    _is.DatabaseSession session,
    List<ServerChangeRecord> rows, {
    _is.OrderByBuilder<ServerChangeRecordTable>? orderBy,
    _is.OrderByListBuilder<ServerChangeRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ServerChangeRecord>(
      rows,
      orderBy: orderBy?.call(ServerChangeRecord.t),
      orderByList: orderByList?.call(ServerChangeRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ServerChangeRecord].
  Future<ServerChangeRecord> deleteRow(
    _is.DatabaseSession session,
    ServerChangeRecord row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ServerChangeRecord>(
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
  Future<List<ServerChangeRecord>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ServerChangeRecordTable> where,
    _is.OrderByBuilder<ServerChangeRecordTable>? orderBy,
    _is.OrderByListBuilder<ServerChangeRecordTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ServerChangeRecord>(
      where: where(ServerChangeRecord.t),
      orderBy: orderBy?.call(ServerChangeRecord.t),
      orderByList: orderByList?.call(ServerChangeRecord.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ServerChangeRecordTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ServerChangeRecord>(
      where: where?.call(ServerChangeRecord.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ServerChangeRecord] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ServerChangeRecordTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ServerChangeRecord>(
      where: where(ServerChangeRecord.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
