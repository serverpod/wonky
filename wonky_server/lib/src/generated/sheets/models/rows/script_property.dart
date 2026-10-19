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
import '../../../sheets/models/rows/script_project.dart' as _itmevo3z;

/// A script property shared by all users of the spreadsheet.
abstract class ScriptProperty
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  ScriptProperty._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.projectId,
    this.project,
    required this.key,
    required this.value,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory ScriptProperty({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    required String key,
    required String value,
    DateTime? createdAt,
  }) = _ScriptPropertyImpl;

  factory ScriptProperty.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScriptProperty(
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
      projectId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['projectId'],
      ),
      project: jsonSerialization['project'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_itmevo3z.ScriptProject>(
              jsonSerialization['project'],
            ),
      key: jsonSerialization['key'] as String,
      value: jsonSerialization['value'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ScriptPropertyTable();

  static const db = ScriptPropertyRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue projectId;

  _itmevo3z.ScriptProject? project;

  String key;

  String value;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [ScriptProperty]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScriptProperty copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptProperty$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedScriptProperty$project(),
    String? key,
    String? value,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScriptProperty',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'projectId': projectId.toJson(),
      if (project != null) 'project': project?.toJson(),
      'key': key,
      'value': value,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ScriptPropertyInclude include({
    _imcki4bb.RevFileInclude? file,
    _itmevo3z.ScriptProjectInclude? project,
  }) {
    return ScriptPropertyInclude._(
      file: file,
      project: project,
    );
  }

  static ScriptPropertyIncludeList includeList({
    _is.WhereExpressionBuilder<ScriptPropertyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptPropertyTable>? orderByList,
    ScriptPropertyInclude? include,
  }) {
    return ScriptPropertyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptProperty.t),
      orderByList: orderByList?.call(ScriptProperty.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedScriptProperty$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedScriptProperty$file();
}

class _UndefinedScriptProperty$project extends _is.UndefinedSentinel
    implements _itmevo3z.ScriptProject {
  const _UndefinedScriptProperty$project();
}

class _ScriptPropertyImpl extends ScriptProperty {
  _ScriptPropertyImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    required String key,
    required String value,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         projectId: projectId,
         project: project,
         key: key,
         value: value,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ScriptProperty]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ScriptProperty copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptProperty$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedScriptProperty$project(),
    String? key,
    String? value,
    DateTime? createdAt,
  }) {
    return ScriptProperty(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      projectId: projectId ?? this.projectId,
      project: project is _is.UndefinedSentinel
          ? this.project?.copyWith()
          : project,
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ScriptPropertyUpdateTable extends _is.UpdateTable<ScriptPropertyTable> {
  ScriptPropertyUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> projectId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.projectId,
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

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ScriptPropertyTable extends _is.Table<_is.UuidValue> {
  ScriptPropertyTable({super.tableRelation})
    : super(tableName: 'script_property') {
    updateTable = ScriptPropertyUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    projectId = _is.ColumnUuid(
      'projectId',
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
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ScriptPropertyUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid projectId;

  _itmevo3z.ScriptProjectTable? _project;

  late final _is.ColumnString key;

  late final _is.ColumnString value;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: ScriptProperty.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _itmevo3z.ScriptProjectTable get project {
    if (_project != null) return _project!;
    _project = _is.createRelationTable(
      relationFieldName: 'project',
      field: ScriptProperty.t.projectId,
      foreignField: _itmevo3z.ScriptProject.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _itmevo3z.ScriptProjectTable(tableRelation: foreignTableRelation),
    );
    return _project!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    projectId,
    key,
    value,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'project') {
      return project;
    }
    return null;
  }
}

class ScriptPropertyInclude extends _is.IncludeObject {
  ScriptPropertyInclude._({
    _imcki4bb.RevFileInclude? file,
    _itmevo3z.ScriptProjectInclude? project,
  }) {
    _file = file;
    _project = project;
  }

  _imcki4bb.RevFileInclude? _file;

  _itmevo3z.ScriptProjectInclude? _project;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'project': _project,
  };

  @override
  _is.Table<_is.UuidValue> get table => ScriptProperty.t;
}

class ScriptPropertyIncludeList extends _is.IncludeList {
  ScriptPropertyIncludeList._({
    _is.WhereExpressionBuilder<ScriptPropertyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ScriptProperty.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => ScriptProperty.t;
}

class ScriptPropertyRepository {
  const ScriptPropertyRepository._();

  final attachRow = const ScriptPropertyAttachRowRepository._();

  /// Returns a list of [ScriptProperty]s matching the given query parameters.
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
  Future<List<ScriptProperty>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptPropertyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptPropertyTable>? orderByList,
    _is.Transaction? transaction,
    ScriptPropertyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ScriptProperty>(
      where: where?.call(ScriptProperty.t),
      orderBy: orderBy?.call(ScriptProperty.t),
      orderByList: orderByList?.call(ScriptProperty.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ScriptProperty]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ScriptProperty.t`.
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
  _ida.Stream<List<ScriptProperty>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptPropertyTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptPropertyTable>? orderByList,
    ScriptPropertyInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ScriptProperty>(
      where: where?.call(ScriptProperty.t),
      orderBy: orderBy?.call(ScriptProperty.t),
      orderByList: orderByList?.call(ScriptProperty.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ScriptProperty] matching the given query parameters.
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
  Future<ScriptProperty?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptPropertyTable>? where,
    int? offset,
    _is.OrderByBuilder<ScriptPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptPropertyTable>? orderByList,
    _is.Transaction? transaction,
    ScriptPropertyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ScriptProperty>(
      where: where?.call(ScriptProperty.t),
      orderBy: orderBy?.call(ScriptProperty.t),
      orderByList: orderByList?.call(ScriptProperty.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ScriptProperty] by its [id] or null if no such row exists.
  Future<ScriptProperty?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ScriptPropertyInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ScriptProperty>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ScriptProperty]s in the list and returns the inserted rows.
  ///
  /// The returned [ScriptProperty]s will have their `id` fields set.
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
  Future<List<ScriptProperty>> insert(
    _is.DatabaseSession session,
    List<ScriptProperty> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ScriptProperty>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ScriptProperty] and returns the inserted row.
  ///
  /// The returned [ScriptProperty] will have its `id` field set.
  Future<ScriptProperty> insertRow(
    _is.DatabaseSession session,
    ScriptProperty row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ScriptProperty>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ScriptProperty]s in the list and returns the resulting rows.
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
  /// The returned [ScriptProperty]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptProperty>> upsert(
    _is.DatabaseSession session,
    List<ScriptProperty> rows, {
    required _is.ColumnSelections<ScriptPropertyTable> conflictColumns,
    _is.ColumnSelections<ScriptPropertyTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptPropertyTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ScriptProperty>(
      rows,
      conflictColumns: conflictColumns(ScriptProperty.t),
      updateColumns: updateColumns?.call(ScriptProperty.t),
      updateWhere: updateWhere?.call(ScriptProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ScriptProperty] and returns the resulting row.
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
  /// The returned [ScriptProperty] will have its `id` field set.
  Future<ScriptProperty?> upsertRow(
    _is.DatabaseSession session,
    ScriptProperty row, {
    required _is.ColumnSelections<ScriptPropertyTable> conflictColumns,
    _is.ColumnSelections<ScriptPropertyTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptPropertyTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ScriptProperty>(
      row,
      conflictColumns: conflictColumns(ScriptProperty.t),
      updateColumns: updateColumns?.call(ScriptProperty.t),
      updateWhere: updateWhere?.call(ScriptProperty.t),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptProperty]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptProperty>> update(
    _is.DatabaseSession session,
    List<ScriptProperty> rows, {
    _is.ColumnSelections<ScriptPropertyTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ScriptProperty>(
      rows,
      columns: columns?.call(ScriptProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ScriptProperty]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ScriptProperty> updateRow(
    _is.DatabaseSession session,
    ScriptProperty row, {
    _is.ColumnSelections<ScriptPropertyTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ScriptProperty>(
      row,
      columns: columns?.call(ScriptProperty.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ScriptProperty] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ScriptProperty?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ScriptPropertyUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ScriptProperty>(
      id,
      columnValues: columnValues(ScriptProperty.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptProperty]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptProperty>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ScriptPropertyUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ScriptPropertyTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptPropertyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ScriptProperty>(
      columnValues: columnValues(ScriptProperty.t.updateTable),
      where: where(ScriptProperty.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptProperty.t),
      orderByList: orderByList?.call(ScriptProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ScriptProperty]s in the list and returns the deleted rows.
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
  Future<List<ScriptProperty>> delete(
    _is.DatabaseSession session,
    List<ScriptProperty> rows, {
    _is.OrderByBuilder<ScriptPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptPropertyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ScriptProperty>(
      rows,
      orderBy: orderBy?.call(ScriptProperty.t),
      orderByList: orderByList?.call(ScriptProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ScriptProperty].
  Future<ScriptProperty> deleteRow(
    _is.DatabaseSession session,
    ScriptProperty row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ScriptProperty>(
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
  Future<List<ScriptProperty>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptPropertyTable> where,
    _is.OrderByBuilder<ScriptPropertyTable>? orderBy,
    _is.OrderByListBuilder<ScriptPropertyTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ScriptProperty>(
      where: where(ScriptProperty.t),
      orderBy: orderBy?.call(ScriptProperty.t),
      orderByList: orderByList?.call(ScriptProperty.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptPropertyTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ScriptProperty>(
      where: where?.call(ScriptProperty.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ScriptProperty] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptPropertyTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ScriptProperty>(
      where: where(ScriptProperty.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ScriptPropertyAttachRowRepository {
  const ScriptPropertyAttachRowRepository._();

  /// Creates a relation between the given [ScriptProperty] and [RevFile]
  /// by setting the [ScriptProperty]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    ScriptProperty scriptProperty,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (scriptProperty.id == null) {
      throw ArgumentError.notNull('scriptProperty.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $scriptProperty = scriptProperty.copyWith(fileId: file.id);
    await session.db.updateRow<ScriptProperty>(
      $scriptProperty,
      columns: [ScriptProperty.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ScriptProperty] and [ScriptProject]
  /// by setting the [ScriptProperty]'s foreign key `projectId` to refer to the [ScriptProject].
  Future<void> project(
    _is.DatabaseSession session,
    ScriptProperty scriptProperty,
    _itmevo3z.ScriptProject project, {
    _is.Transaction? transaction,
  }) async {
    if (scriptProperty.id == null) {
      throw ArgumentError.notNull('scriptProperty.id');
    }
    if (project.id == null) {
      throw ArgumentError.notNull('project.id');
    }

    var $scriptProperty = scriptProperty.copyWith(projectId: project.id);
    await session.db.updateRow<ScriptProperty>(
      $scriptProperty,
      columns: [ScriptProperty.t.projectId],
      transaction: transaction,
    );
  }
}
