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

/// A Dart source file of a script project (whole-file LWW).
abstract class ScriptFile
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  ScriptFile._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.projectId,
    this.project,
    required this.name,
    required this.sortKey,
    required this.source,
    required this.contentHash,
    required this.updatedBy,
    required this.updatedAt,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory ScriptFile({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    required String name,
    required String sortKey,
    required String source,
    required String contentHash,
    required _is.UuidValue updatedBy,
    required DateTime updatedAt,
    DateTime? createdAt,
  }) = _ScriptFileImpl;

  factory ScriptFile.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScriptFile(
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
      name: jsonSerialization['name'] as String,
      sortKey: jsonSerialization['sortKey'] as String,
      source: jsonSerialization['source'] as String,
      contentHash: jsonSerialization['contentHash'] as String,
      updatedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['updatedBy'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ScriptFileTable();

  static const db = ScriptFileRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue projectId;

  _itmevo3z.ScriptProject? project;

  String name;

  String sortKey;

  String source;

  /// sha256 hex of source.
  String contentHash;

  _is.UuidValue updatedBy;

  DateTime updatedAt;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [ScriptFile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScriptFile copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptFile$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedScriptFile$project(),
    String? name,
    String? sortKey,
    String? source,
    String? contentHash,
    _is.UuidValue? updatedBy,
    DateTime? updatedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScriptFile',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'projectId': projectId.toJson(),
      if (project != null) 'project': project?.toJson(),
      'name': name,
      'sortKey': sortKey,
      'source': source,
      'contentHash': contentHash,
      'updatedBy': updatedBy.toJson(),
      'updatedAt': updatedAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ScriptFileInclude include({
    _imcki4bb.RevFileInclude? file,
    _itmevo3z.ScriptProjectInclude? project,
  }) {
    return ScriptFileInclude._(
      file: file,
      project: project,
    );
  }

  static ScriptFileIncludeList includeList({
    _is.WhereExpressionBuilder<ScriptFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptFileTable>? orderBy,
    _is.OrderByListBuilder<ScriptFileTable>? orderByList,
    ScriptFileInclude? include,
  }) {
    return ScriptFileIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptFile.t),
      orderByList: orderByList?.call(ScriptFile.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedScriptFile$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedScriptFile$file();
}

class _UndefinedScriptFile$project extends _is.UndefinedSentinel
    implements _itmevo3z.ScriptProject {
  const _UndefinedScriptFile$project();
}

class _ScriptFileImpl extends ScriptFile {
  _ScriptFileImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    required String name,
    required String sortKey,
    required String source,
    required String contentHash,
    required _is.UuidValue updatedBy,
    required DateTime updatedAt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         projectId: projectId,
         project: project,
         name: name,
         sortKey: sortKey,
         source: source,
         contentHash: contentHash,
         updatedBy: updatedBy,
         updatedAt: updatedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ScriptFile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ScriptFile copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptFile$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedScriptFile$project(),
    String? name,
    String? sortKey,
    String? source,
    String? contentHash,
    _is.UuidValue? updatedBy,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return ScriptFile(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      projectId: projectId ?? this.projectId,
      project: project is _is.UndefinedSentinel
          ? this.project?.copyWith()
          : project,
      name: name ?? this.name,
      sortKey: sortKey ?? this.sortKey,
      source: source ?? this.source,
      contentHash: contentHash ?? this.contentHash,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ScriptFileUpdateTable extends _is.UpdateTable<ScriptFileTable> {
  ScriptFileUpdateTable(super.table);

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

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> sortKey(String value) => _is.ColumnValue(
    table.sortKey,
    value,
  );

  _is.ColumnValue<String, String> source(String value) => _is.ColumnValue(
    table.source,
    value,
  );

  _is.ColumnValue<String, String> contentHash(String value) => _is.ColumnValue(
    table.contentHash,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> updatedBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.updatedBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ScriptFileTable extends _is.Table<_is.UuidValue> {
  ScriptFileTable({super.tableRelation}) : super(tableName: 'script_file') {
    updateTable = ScriptFileUpdateTable(this);
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
    name = _is.ColumnString(
      'name',
      this,
    );
    sortKey = _is.ColumnString(
      'sortKey',
      this,
    );
    source = _is.ColumnString(
      'source',
      this,
    );
    contentHash = _is.ColumnString(
      'contentHash',
      this,
    );
    updatedBy = _is.ColumnUuid(
      'updatedBy',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ScriptFileUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid projectId;

  _itmevo3z.ScriptProjectTable? _project;

  late final _is.ColumnString name;

  late final _is.ColumnString sortKey;

  late final _is.ColumnString source;

  /// sha256 hex of source.
  late final _is.ColumnString contentHash;

  late final _is.ColumnUuid updatedBy;

  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: ScriptFile.t.fileId,
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
      field: ScriptFile.t.projectId,
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
    name,
    sortKey,
    source,
    contentHash,
    updatedBy,
    updatedAt,
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

class ScriptFileInclude extends _is.IncludeObject {
  ScriptFileInclude._({
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
  _is.Table<_is.UuidValue> get table => ScriptFile.t;
}

class ScriptFileIncludeList extends _is.IncludeList {
  ScriptFileIncludeList._({
    _is.WhereExpressionBuilder<ScriptFileTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ScriptFile.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => ScriptFile.t;
}

class ScriptFileRepository {
  const ScriptFileRepository._();

  final attachRow = const ScriptFileAttachRowRepository._();

  /// Returns a list of [ScriptFile]s matching the given query parameters.
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
  Future<List<ScriptFile>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptFileTable>? orderBy,
    _is.OrderByListBuilder<ScriptFileTable>? orderByList,
    _is.Transaction? transaction,
    ScriptFileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ScriptFile>(
      where: where?.call(ScriptFile.t),
      orderBy: orderBy?.call(ScriptFile.t),
      orderByList: orderByList?.call(ScriptFile.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ScriptFile]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ScriptFile.t`.
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
  _ida.Stream<List<ScriptFile>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptFileTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptFileTable>? orderBy,
    _is.OrderByListBuilder<ScriptFileTable>? orderByList,
    ScriptFileInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ScriptFile>(
      where: where?.call(ScriptFile.t),
      orderBy: orderBy?.call(ScriptFile.t),
      orderByList: orderByList?.call(ScriptFile.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ScriptFile] matching the given query parameters.
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
  Future<ScriptFile?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptFileTable>? where,
    int? offset,
    _is.OrderByBuilder<ScriptFileTable>? orderBy,
    _is.OrderByListBuilder<ScriptFileTable>? orderByList,
    _is.Transaction? transaction,
    ScriptFileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ScriptFile>(
      where: where?.call(ScriptFile.t),
      orderBy: orderBy?.call(ScriptFile.t),
      orderByList: orderByList?.call(ScriptFile.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ScriptFile] by its [id] or null if no such row exists.
  Future<ScriptFile?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ScriptFileInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ScriptFile>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ScriptFile]s in the list and returns the inserted rows.
  ///
  /// The returned [ScriptFile]s will have their `id` fields set.
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
  Future<List<ScriptFile>> insert(
    _is.DatabaseSession session,
    List<ScriptFile> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ScriptFile>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ScriptFile] and returns the inserted row.
  ///
  /// The returned [ScriptFile] will have its `id` field set.
  Future<ScriptFile> insertRow(
    _is.DatabaseSession session,
    ScriptFile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ScriptFile>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ScriptFile]s in the list and returns the resulting rows.
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
  /// The returned [ScriptFile]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptFile>> upsert(
    _is.DatabaseSession session,
    List<ScriptFile> rows, {
    required _is.ColumnSelections<ScriptFileTable> conflictColumns,
    _is.ColumnSelections<ScriptFileTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptFileTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ScriptFile>(
      rows,
      conflictColumns: conflictColumns(ScriptFile.t),
      updateColumns: updateColumns?.call(ScriptFile.t),
      updateWhere: updateWhere?.call(ScriptFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ScriptFile] and returns the resulting row.
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
  /// The returned [ScriptFile] will have its `id` field set.
  Future<ScriptFile?> upsertRow(
    _is.DatabaseSession session,
    ScriptFile row, {
    required _is.ColumnSelections<ScriptFileTable> conflictColumns,
    _is.ColumnSelections<ScriptFileTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptFileTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ScriptFile>(
      row,
      conflictColumns: conflictColumns(ScriptFile.t),
      updateColumns: updateColumns?.call(ScriptFile.t),
      updateWhere: updateWhere?.call(ScriptFile.t),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptFile]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptFile>> update(
    _is.DatabaseSession session,
    List<ScriptFile> rows, {
    _is.ColumnSelections<ScriptFileTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ScriptFile>(
      rows,
      columns: columns?.call(ScriptFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ScriptFile]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ScriptFile> updateRow(
    _is.DatabaseSession session,
    ScriptFile row, {
    _is.ColumnSelections<ScriptFileTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ScriptFile>(
      row,
      columns: columns?.call(ScriptFile.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ScriptFile] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ScriptFile?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ScriptFileUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ScriptFile>(
      id,
      columnValues: columnValues(ScriptFile.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptFile]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptFile>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ScriptFileUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ScriptFileTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptFileTable>? orderBy,
    _is.OrderByListBuilder<ScriptFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ScriptFile>(
      columnValues: columnValues(ScriptFile.t.updateTable),
      where: where(ScriptFile.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptFile.t),
      orderByList: orderByList?.call(ScriptFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ScriptFile]s in the list and returns the deleted rows.
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
  Future<List<ScriptFile>> delete(
    _is.DatabaseSession session,
    List<ScriptFile> rows, {
    _is.OrderByBuilder<ScriptFileTable>? orderBy,
    _is.OrderByListBuilder<ScriptFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ScriptFile>(
      rows,
      orderBy: orderBy?.call(ScriptFile.t),
      orderByList: orderByList?.call(ScriptFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ScriptFile].
  Future<ScriptFile> deleteRow(
    _is.DatabaseSession session,
    ScriptFile row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ScriptFile>(
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
  Future<List<ScriptFile>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptFileTable> where,
    _is.OrderByBuilder<ScriptFileTable>? orderBy,
    _is.OrderByListBuilder<ScriptFileTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ScriptFile>(
      where: where(ScriptFile.t),
      orderBy: orderBy?.call(ScriptFile.t),
      orderByList: orderByList?.call(ScriptFile.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptFileTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ScriptFile>(
      where: where?.call(ScriptFile.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ScriptFile] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptFileTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ScriptFile>(
      where: where(ScriptFile.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ScriptFileAttachRowRepository {
  const ScriptFileAttachRowRepository._();

  /// Creates a relation between the given [ScriptFile] and [RevFile]
  /// by setting the [ScriptFile]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    ScriptFile scriptFile,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (scriptFile.id == null) {
      throw ArgumentError.notNull('scriptFile.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $scriptFile = scriptFile.copyWith(fileId: file.id);
    await session.db.updateRow<ScriptFile>(
      $scriptFile,
      columns: [ScriptFile.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ScriptFile] and [ScriptProject]
  /// by setting the [ScriptFile]'s foreign key `projectId` to refer to the [ScriptProject].
  Future<void> project(
    _is.DatabaseSession session,
    ScriptFile scriptFile,
    _itmevo3z.ScriptProject project, {
    _is.Transaction? transaction,
  }) async {
    if (scriptFile.id == null) {
      throw ArgumentError.notNull('scriptFile.id');
    }
    if (project.id == null) {
      throw ArgumentError.notNull('project.id');
    }

    var $scriptFile = scriptFile.copyWith(projectId: project.id);
    await session.db.updateRow<ScriptFile>(
      $scriptFile,
      columns: [ScriptFile.t.projectId],
      transaction: transaction,
    );
  }
}
