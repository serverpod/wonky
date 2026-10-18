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
import '../../../platform/revlog/models/rev_file.dart' as _imcki4bb;

/// Cursors and lease of the durable post-commit hooks of a file (RevLog
/// spec 05 §6).
abstract class RevHookState
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  RevHookState._({
    this.id,
    required this.fileId,
    this.file,
    required this.cursorsJson,
    this.leaseOwner,
    this.leaseUntil,
    int? attempts,
    this.lastError,
    this.nextAttemptAt,
    required this.updatedAt,
  }) : attempts = attempts ?? 0;

  factory RevHookState({
    int? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    required String cursorsJson,
    String? leaseOwner,
    DateTime? leaseUntil,
    int? attempts,
    String? lastError,
    DateTime? nextAttemptAt,
    required DateTime updatedAt,
  }) = _RevHookStateImpl;

  factory RevHookState.fromJson(Map<String, dynamic> jsonSerialization) {
    return RevHookState(
      id: jsonSerialization['id'] as int?,
      fileId: jsonSerialization['fileId'] as int,
      file: jsonSerialization['file'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_imcki4bb.RevFile>(
              jsonSerialization['file'],
            ),
      cursorsJson: jsonSerialization['cursorsJson'] as String,
      leaseOwner: jsonSerialization['leaseOwner'] as String?,
      leaseUntil: jsonSerialization['leaseUntil'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['leaseUntil']),
      attempts: jsonSerialization['attempts'] as int?,
      lastError: jsonSerialization['lastError'] as String?,
      nextAttemptAt: jsonSerialization['nextAttemptAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['nextAttemptAt'],
            ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = RevHookStateTable();

  static const db = RevHookStateRepository._();

  @override
  int? id;

  int fileId;

  _imcki4bb.RevFile? file;

  /// {"<hookId>": <last processed revision>, …}
  String cursorsJson;

  /// Instance id draining this file.
  String? leaseOwner;

  DateTime? leaseUntil;

  int attempts;

  String? lastError;

  DateTime? nextAttemptAt;

  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [RevHookState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RevHookState copyWith({
    int? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedRevHookState$file(),
    String? cursorsJson,
    String? leaseOwner,
    DateTime? leaseUntil = const _is.$UndefinedDateTime(),
    int? attempts,
    String? lastError,
    DateTime? nextAttemptAt = const _is.$UndefinedDateTime(),
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RevHookState',
      if (id != null) 'id': id,
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'cursorsJson': cursorsJson,
      if (leaseOwner != null) 'leaseOwner': leaseOwner,
      if (leaseUntil != null) 'leaseUntil': leaseUntil?.toJson(),
      'attempts': attempts,
      if (lastError != null) 'lastError': lastError,
      if (nextAttemptAt != null) 'nextAttemptAt': nextAttemptAt?.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static RevHookStateInclude include({_imcki4bb.RevFileInclude? file}) {
    return RevHookStateInclude._(file: file);
  }

  static RevHookStateIncludeList includeList({
    _is.WhereExpressionBuilder<RevHookStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevHookStateTable>? orderBy,
    _is.OrderByListBuilder<RevHookStateTable>? orderByList,
    RevHookStateInclude? include,
  }) {
    return RevHookStateIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RevHookState.t),
      orderByList: orderByList?.call(RevHookState.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedRevHookState$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedRevHookState$file();
}

class _RevHookStateImpl extends RevHookState {
  _RevHookStateImpl({
    int? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    required String cursorsJson,
    String? leaseOwner,
    DateTime? leaseUntil,
    int? attempts,
    String? lastError,
    DateTime? nextAttemptAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         cursorsJson: cursorsJson,
         leaseOwner: leaseOwner,
         leaseUntil: leaseUntil,
         attempts: attempts,
         lastError: lastError,
         nextAttemptAt: nextAttemptAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [RevHookState]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RevHookState copyWith({
    Object? id = _Undefined,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedRevHookState$file(),
    String? cursorsJson,
    Object? leaseOwner = _Undefined,
    DateTime? leaseUntil = const _is.$UndefinedDateTime(),
    int? attempts,
    Object? lastError = _Undefined,
    DateTime? nextAttemptAt = const _is.$UndefinedDateTime(),
    DateTime? updatedAt,
  }) {
    return RevHookState(
      id: id is int? ? id : this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      cursorsJson: cursorsJson ?? this.cursorsJson,
      leaseOwner: leaseOwner is String? ? leaseOwner : this.leaseOwner,
      leaseUntil: leaseUntil is _is.UndefinedSentinel
          ? this.leaseUntil
          : leaseUntil,
      attempts: attempts ?? this.attempts,
      lastError: lastError is String? ? lastError : this.lastError,
      nextAttemptAt: nextAttemptAt is _is.UndefinedSentinel
          ? this.nextAttemptAt
          : nextAttemptAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RevHookStateUpdateTable extends _is.UpdateTable<RevHookStateTable> {
  RevHookStateUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<String, String> cursorsJson(String value) => _is.ColumnValue(
    table.cursorsJson,
    value,
  );

  _is.ColumnValue<String, String> leaseOwner(String? value) => _is.ColumnValue(
    table.leaseOwner,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> leaseUntil(DateTime? value) =>
      _is.ColumnValue(
        table.leaseUntil,
        value,
      );

  _is.ColumnValue<int, int> attempts(int value) => _is.ColumnValue(
    table.attempts,
    value,
  );

  _is.ColumnValue<String, String> lastError(String? value) => _is.ColumnValue(
    table.lastError,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> nextAttemptAt(DateTime? value) =>
      _is.ColumnValue(
        table.nextAttemptAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );
}

class RevHookStateTable extends _is.Table<int?> {
  RevHookStateTable({super.tableRelation})
    : super(tableName: 'rev_hook_state') {
    updateTable = RevHookStateUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    cursorsJson = _is.ColumnString(
      'cursorsJson',
      this,
    );
    leaseOwner = _is.ColumnString(
      'leaseOwner',
      this,
    );
    leaseUntil = _is.ColumnDateTime(
      'leaseUntil',
      this,
    );
    attempts = _is.ColumnInt(
      'attempts',
      this,
      hasDefault: true,
    );
    lastError = _is.ColumnString(
      'lastError',
      this,
    );
    nextAttemptAt = _is.ColumnDateTime(
      'nextAttemptAt',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final RevHookStateUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  _imcki4bb.RevFileTable? _file;

  /// {"<hookId>": <last processed revision>, …}
  late final _is.ColumnString cursorsJson;

  /// Instance id draining this file.
  late final _is.ColumnString leaseOwner;

  late final _is.ColumnDateTime leaseUntil;

  late final _is.ColumnInt attempts;

  late final _is.ColumnString lastError;

  late final _is.ColumnDateTime nextAttemptAt;

  late final _is.ColumnDateTime updatedAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: RevHookState.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    cursorsJson,
    leaseOwner,
    leaseUntil,
    attempts,
    lastError,
    nextAttemptAt,
    updatedAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    return null;
  }
}

class RevHookStateInclude extends _is.IncludeObject {
  RevHookStateInclude._({_imcki4bb.RevFileInclude? file}) {
    _file = file;
  }

  _imcki4bb.RevFileInclude? _file;

  @override
  Map<String, _is.Include?> get includes => {'file': _file};

  @override
  _is.Table<int?> get table => RevHookState.t;
}

class RevHookStateIncludeList extends _is.IncludeList {
  RevHookStateIncludeList._({
    _is.WhereExpressionBuilder<RevHookStateTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(RevHookState.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => RevHookState.t;
}

class RevHookStateRepository {
  const RevHookStateRepository._();

  final attachRow = const RevHookStateAttachRowRepository._();

  /// Returns a list of [RevHookState]s matching the given query parameters.
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
  Future<List<RevHookState>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevHookStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevHookStateTable>? orderBy,
    _is.OrderByListBuilder<RevHookStateTable>? orderByList,
    _is.Transaction? transaction,
    RevHookStateInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<RevHookState>(
      where: where?.call(RevHookState.t),
      orderBy: orderBy?.call(RevHookState.t),
      orderByList: orderByList?.call(RevHookState.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [RevHookState]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `RevHookState.t`.
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
  _ida.Stream<List<RevHookState>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevHookStateTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevHookStateTable>? orderBy,
    _is.OrderByListBuilder<RevHookStateTable>? orderByList,
    RevHookStateInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<RevHookState>(
      where: where?.call(RevHookState.t),
      orderBy: orderBy?.call(RevHookState.t),
      orderByList: orderByList?.call(RevHookState.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [RevHookState] matching the given query parameters.
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
  Future<RevHookState?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevHookStateTable>? where,
    int? offset,
    _is.OrderByBuilder<RevHookStateTable>? orderBy,
    _is.OrderByListBuilder<RevHookStateTable>? orderByList,
    _is.Transaction? transaction,
    RevHookStateInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<RevHookState>(
      where: where?.call(RevHookState.t),
      orderBy: orderBy?.call(RevHookState.t),
      orderByList: orderByList?.call(RevHookState.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [RevHookState] by its [id] or null if no such row exists.
  Future<RevHookState?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    RevHookStateInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<RevHookState>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [RevHookState]s in the list and returns the inserted rows.
  ///
  /// The returned [RevHookState]s will have their `id` fields set.
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
  Future<List<RevHookState>> insert(
    _is.DatabaseSession session,
    List<RevHookState> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<RevHookState>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [RevHookState] and returns the inserted row.
  ///
  /// The returned [RevHookState] will have its `id` field set.
  Future<RevHookState> insertRow(
    _is.DatabaseSession session,
    RevHookState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<RevHookState>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [RevHookState]s in the list and returns the resulting rows.
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
  /// The returned [RevHookState]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevHookState>> upsert(
    _is.DatabaseSession session,
    List<RevHookState> rows, {
    required _is.ColumnSelections<RevHookStateTable> conflictColumns,
    _is.ColumnSelections<RevHookStateTable>? updateColumns,
    _is.WhereExpressionBuilder<RevHookStateTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<RevHookState>(
      rows,
      conflictColumns: conflictColumns(RevHookState.t),
      updateColumns: updateColumns?.call(RevHookState.t),
      updateWhere: updateWhere?.call(RevHookState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [RevHookState] and returns the resulting row.
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
  /// The returned [RevHookState] will have its `id` field set.
  Future<RevHookState?> upsertRow(
    _is.DatabaseSession session,
    RevHookState row, {
    required _is.ColumnSelections<RevHookStateTable> conflictColumns,
    _is.ColumnSelections<RevHookStateTable>? updateColumns,
    _is.WhereExpressionBuilder<RevHookStateTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<RevHookState>(
      row,
      conflictColumns: conflictColumns(RevHookState.t),
      updateColumns: updateColumns?.call(RevHookState.t),
      updateWhere: updateWhere?.call(RevHookState.t),
      transaction: transaction,
    );
  }

  /// Updates all [RevHookState]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevHookState>> update(
    _is.DatabaseSession session,
    List<RevHookState> rows, {
    _is.ColumnSelections<RevHookStateTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<RevHookState>(
      rows,
      columns: columns?.call(RevHookState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [RevHookState]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<RevHookState> updateRow(
    _is.DatabaseSession session,
    RevHookState row, {
    _is.ColumnSelections<RevHookStateTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<RevHookState>(
      row,
      columns: columns?.call(RevHookState.t),
      transaction: transaction,
    );
  }

  /// Updates a single [RevHookState] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<RevHookState?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<RevHookStateUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<RevHookState>(
      id,
      columnValues: columnValues(RevHookState.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [RevHookState]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<RevHookState>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RevHookStateUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RevHookStateTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RevHookStateTable>? orderBy,
    _is.OrderByListBuilder<RevHookStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<RevHookState>(
      columnValues: columnValues(RevHookState.t.updateTable),
      where: where(RevHookState.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(RevHookState.t),
      orderByList: orderByList?.call(RevHookState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [RevHookState]s in the list and returns the deleted rows.
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
  Future<List<RevHookState>> delete(
    _is.DatabaseSession session,
    List<RevHookState> rows, {
    _is.OrderByBuilder<RevHookStateTable>? orderBy,
    _is.OrderByListBuilder<RevHookStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<RevHookState>(
      rows,
      orderBy: orderBy?.call(RevHookState.t),
      orderByList: orderByList?.call(RevHookState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [RevHookState].
  Future<RevHookState> deleteRow(
    _is.DatabaseSession session,
    RevHookState row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<RevHookState>(
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
  Future<List<RevHookState>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RevHookStateTable> where,
    _is.OrderByBuilder<RevHookStateTable>? orderBy,
    _is.OrderByListBuilder<RevHookStateTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<RevHookState>(
      where: where(RevHookState.t),
      orderBy: orderBy?.call(RevHookState.t),
      orderByList: orderByList?.call(RevHookState.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RevHookStateTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<RevHookState>(
      where: where?.call(RevHookState.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [RevHookState] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RevHookStateTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<RevHookState>(
      where: where(RevHookState.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class RevHookStateAttachRowRepository {
  const RevHookStateAttachRowRepository._();

  /// Creates a relation between the given [RevHookState] and [RevFile]
  /// by setting the [RevHookState]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    RevHookState revHookState,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (revHookState.id == null) {
      throw ArgumentError.notNull('revHookState.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $revHookState = revHookState.copyWith(fileId: file.id);
    await session.db.updateRow<RevHookState>(
      $revHookState,
      columns: [RevHookState.t.fileId],
      transaction: transaction,
    );
  }
}
