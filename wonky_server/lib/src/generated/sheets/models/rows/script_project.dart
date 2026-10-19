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
import '../../../sheets/models/rows/spreadsheet.dart' as _iy65bbp5;

/// The bound script project of a spreadsheet (one per spreadsheet).
abstract class ScriptProject
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  ScriptProject._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.spreadsheetId,
    this.spreadsheet,
    required this.name,
    required this.settingsJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory ScriptProject({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue spreadsheetId,
    _iy65bbp5.Spreadsheet? spreadsheet,
    required String name,
    required String settingsJson,
    DateTime? createdAt,
  }) = _ScriptProjectImpl;

  factory ScriptProject.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScriptProject(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      fileId: jsonSerialization['fileId'] as int,
      file: jsonSerialization['file'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_imcki4bb.RevFile>(
              jsonSerialization['file'],
            ),
      revision: jsonSerialization['revision'] as int?,
      spreadsheetId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['spreadsheetId'],
      ),
      spreadsheet: jsonSerialization['spreadsheet'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_iy65bbp5.Spreadsheet>(
              jsonSerialization['spreadsheet'],
            ),
      name: jsonSerialization['name'] as String,
      settingsJson: jsonSerialization['settingsJson'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ScriptProjectTable();

  static const db = ScriptProjectRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue spreadsheetId;

  _iy65bbp5.Spreadsheet? spreadsheet;

  String name;

  String settingsJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [ScriptProject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScriptProject copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptProject$file(),
    int? revision,
    _is.UuidValue? spreadsheetId,
    _iy65bbp5.Spreadsheet? spreadsheet =
        const _UndefinedScriptProject$spreadsheet(),
    String? name,
    String? settingsJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScriptProject',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'spreadsheetId': spreadsheetId.toJson(),
      if (spreadsheet != null) 'spreadsheet': spreadsheet?.toJson(),
      'name': name,
      'settingsJson': settingsJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ScriptProjectInclude include({
    _imcki4bb.RevFileInclude? file,
    _iy65bbp5.SpreadsheetInclude? spreadsheet,
  }) {
    return ScriptProjectInclude._(
      file: file,
      spreadsheet: spreadsheet,
    );
  }

  static ScriptProjectIncludeList includeList({
    _is.WhereExpressionBuilder<ScriptProjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptProjectTable>? orderBy,
    _is.OrderByListBuilder<ScriptProjectTable>? orderByList,
    ScriptProjectInclude? include,
  }) {
    return ScriptProjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptProject.t),
      orderByList: orderByList?.call(ScriptProject.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedScriptProject$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedScriptProject$file();
}

class _UndefinedScriptProject$spreadsheet extends _is.UndefinedSentinel
    implements _iy65bbp5.Spreadsheet {
  const _UndefinedScriptProject$spreadsheet();
}

class _ScriptProjectImpl extends ScriptProject {
  _ScriptProjectImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue spreadsheetId,
    _iy65bbp5.Spreadsheet? spreadsheet,
    required String name,
    required String settingsJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         spreadsheetId: spreadsheetId,
         spreadsheet: spreadsheet,
         name: name,
         settingsJson: settingsJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ScriptProject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ScriptProject copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptProject$file(),
    int? revision,
    _is.UuidValue? spreadsheetId,
    _iy65bbp5.Spreadsheet? spreadsheet =
        const _UndefinedScriptProject$spreadsheet(),
    String? name,
    String? settingsJson,
    DateTime? createdAt,
  }) {
    return ScriptProject(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      spreadsheetId: spreadsheetId ?? this.spreadsheetId,
      spreadsheet: spreadsheet is _is.UndefinedSentinel
          ? this.spreadsheet?.copyWith()
          : spreadsheet,
      name: name ?? this.name,
      settingsJson: settingsJson ?? this.settingsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ScriptProjectUpdateTable extends _is.UpdateTable<ScriptProjectTable> {
  ScriptProjectUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> spreadsheetId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.spreadsheetId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> settingsJson(String value) => _is.ColumnValue(
    table.settingsJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ScriptProjectTable extends _is.Table<_is.UuidValue> {
  ScriptProjectTable({super.tableRelation})
    : super(tableName: 'script_project') {
    updateTable = ScriptProjectUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    spreadsheetId = _is.ColumnUuid(
      'spreadsheetId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    settingsJson = _is.ColumnString(
      'settingsJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ScriptProjectUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid spreadsheetId;

  _iy65bbp5.SpreadsheetTable? _spreadsheet;

  late final _is.ColumnString name;

  late final _is.ColumnString settingsJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: ScriptProject.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _iy65bbp5.SpreadsheetTable get spreadsheet {
    if (_spreadsheet != null) return _spreadsheet!;
    _spreadsheet = _is.createRelationTable(
      relationFieldName: 'spreadsheet',
      field: ScriptProject.t.spreadsheetId,
      foreignField: _iy65bbp5.Spreadsheet.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iy65bbp5.SpreadsheetTable(tableRelation: foreignTableRelation),
    );
    return _spreadsheet!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    spreadsheetId,
    name,
    settingsJson,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'spreadsheet') {
      return spreadsheet;
    }
    return null;
  }
}

class ScriptProjectInclude extends _is.IncludeObject {
  ScriptProjectInclude._({
    _imcki4bb.RevFileInclude? file,
    _iy65bbp5.SpreadsheetInclude? spreadsheet,
  }) {
    _file = file;
    _spreadsheet = spreadsheet;
  }

  _imcki4bb.RevFileInclude? _file;

  _iy65bbp5.SpreadsheetInclude? _spreadsheet;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'spreadsheet': _spreadsheet,
  };

  @override
  _is.Table<_is.UuidValue> get table => ScriptProject.t;
}

class ScriptProjectIncludeList extends _is.IncludeList {
  ScriptProjectIncludeList._({
    _is.WhereExpressionBuilder<ScriptProjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ScriptProject.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => ScriptProject.t;
}

class ScriptProjectRepository {
  const ScriptProjectRepository._();

  final attachRow = const ScriptProjectAttachRowRepository._();

  /// Returns a list of [ScriptProject]s matching the given query parameters.
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
  Future<List<ScriptProject>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptProjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptProjectTable>? orderBy,
    _is.OrderByListBuilder<ScriptProjectTable>? orderByList,
    _is.Transaction? transaction,
    ScriptProjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ScriptProject>(
      where: where?.call(ScriptProject.t),
      orderBy: orderBy?.call(ScriptProject.t),
      orderByList: orderByList?.call(ScriptProject.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ScriptProject]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ScriptProject.t`.
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
  _ida.Stream<List<ScriptProject>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptProjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptProjectTable>? orderBy,
    _is.OrderByListBuilder<ScriptProjectTable>? orderByList,
    ScriptProjectInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ScriptProject>(
      where: where?.call(ScriptProject.t),
      orderBy: orderBy?.call(ScriptProject.t),
      orderByList: orderByList?.call(ScriptProject.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ScriptProject] matching the given query parameters.
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
  Future<ScriptProject?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptProjectTable>? where,
    int? offset,
    _is.OrderByBuilder<ScriptProjectTable>? orderBy,
    _is.OrderByListBuilder<ScriptProjectTable>? orderByList,
    _is.Transaction? transaction,
    ScriptProjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ScriptProject>(
      where: where?.call(ScriptProject.t),
      orderBy: orderBy?.call(ScriptProject.t),
      orderByList: orderByList?.call(ScriptProject.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ScriptProject] by its [id] or null if no such row exists.
  Future<ScriptProject?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ScriptProjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ScriptProject>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ScriptProject]s in the list and returns the inserted rows.
  ///
  /// The returned [ScriptProject]s will have their `id` fields set.
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
  Future<List<ScriptProject>> insert(
    _is.DatabaseSession session,
    List<ScriptProject> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ScriptProject>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ScriptProject] and returns the inserted row.
  ///
  /// The returned [ScriptProject] will have its `id` field set.
  Future<ScriptProject> insertRow(
    _is.DatabaseSession session,
    ScriptProject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ScriptProject>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ScriptProject]s in the list and returns the resulting rows.
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
  /// The returned [ScriptProject]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptProject>> upsert(
    _is.DatabaseSession session,
    List<ScriptProject> rows, {
    required _is.ColumnSelections<ScriptProjectTable> conflictColumns,
    _is.ColumnSelections<ScriptProjectTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptProjectTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ScriptProject>(
      rows,
      conflictColumns: conflictColumns(ScriptProject.t),
      updateColumns: updateColumns?.call(ScriptProject.t),
      updateWhere: updateWhere?.call(ScriptProject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ScriptProject] and returns the resulting row.
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
  /// The returned [ScriptProject] will have its `id` field set.
  Future<ScriptProject?> upsertRow(
    _is.DatabaseSession session,
    ScriptProject row, {
    required _is.ColumnSelections<ScriptProjectTable> conflictColumns,
    _is.ColumnSelections<ScriptProjectTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptProjectTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ScriptProject>(
      row,
      conflictColumns: conflictColumns(ScriptProject.t),
      updateColumns: updateColumns?.call(ScriptProject.t),
      updateWhere: updateWhere?.call(ScriptProject.t),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptProject]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptProject>> update(
    _is.DatabaseSession session,
    List<ScriptProject> rows, {
    _is.ColumnSelections<ScriptProjectTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ScriptProject>(
      rows,
      columns: columns?.call(ScriptProject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ScriptProject]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ScriptProject> updateRow(
    _is.DatabaseSession session,
    ScriptProject row, {
    _is.ColumnSelections<ScriptProjectTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ScriptProject>(
      row,
      columns: columns?.call(ScriptProject.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ScriptProject] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ScriptProject?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ScriptProjectUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ScriptProject>(
      id,
      columnValues: columnValues(ScriptProject.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptProject]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptProject>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ScriptProjectUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ScriptProjectTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptProjectTable>? orderBy,
    _is.OrderByListBuilder<ScriptProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ScriptProject>(
      columnValues: columnValues(ScriptProject.t.updateTable),
      where: where(ScriptProject.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptProject.t),
      orderByList: orderByList?.call(ScriptProject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ScriptProject]s in the list and returns the deleted rows.
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
  Future<List<ScriptProject>> delete(
    _is.DatabaseSession session,
    List<ScriptProject> rows, {
    _is.OrderByBuilder<ScriptProjectTable>? orderBy,
    _is.OrderByListBuilder<ScriptProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ScriptProject>(
      rows,
      orderBy: orderBy?.call(ScriptProject.t),
      orderByList: orderByList?.call(ScriptProject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ScriptProject].
  Future<ScriptProject> deleteRow(
    _is.DatabaseSession session,
    ScriptProject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ScriptProject>(
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
  Future<List<ScriptProject>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptProjectTable> where,
    _is.OrderByBuilder<ScriptProjectTable>? orderBy,
    _is.OrderByListBuilder<ScriptProjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ScriptProject>(
      where: where(ScriptProject.t),
      orderBy: orderBy?.call(ScriptProject.t),
      orderByList: orderByList?.call(ScriptProject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptProjectTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ScriptProject>(
      where: where?.call(ScriptProject.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ScriptProject] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptProjectTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ScriptProject>(
      where: where(ScriptProject.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ScriptProjectAttachRowRepository {
  const ScriptProjectAttachRowRepository._();

  /// Creates a relation between the given [ScriptProject] and [RevFile]
  /// by setting the [ScriptProject]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    ScriptProject scriptProject,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (scriptProject.id == null) {
      throw ArgumentError.notNull('scriptProject.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $scriptProject = scriptProject.copyWith(fileId: file.id);
    await session.db.updateRow<ScriptProject>(
      $scriptProject,
      columns: [ScriptProject.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ScriptProject] and [Spreadsheet]
  /// by setting the [ScriptProject]'s foreign key `spreadsheetId` to refer to the [Spreadsheet].
  Future<void> spreadsheet(
    _is.DatabaseSession session,
    ScriptProject scriptProject,
    _iy65bbp5.Spreadsheet spreadsheet, {
    _is.Transaction? transaction,
  }) async {
    if (scriptProject.id == null) {
      throw ArgumentError.notNull('scriptProject.id');
    }
    if (spreadsheet.id == null) {
      throw ArgumentError.notNull('spreadsheet.id');
    }

    var $scriptProject = scriptProject.copyWith(spreadsheetId: spreadsheet.id);
    await session.db.updateRow<ScriptProject>(
      $scriptProject,
      columns: [ScriptProject.t.spreadsheetId],
      transaction: transaction,
    );
  }
}
