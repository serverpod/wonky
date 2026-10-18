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

/// A recorded or written macro bound to a function.
abstract class Macro
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  Macro._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.projectId,
    this.project,
    required this.name,
    required this.functionName,
    this.shortcutSlot,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory Macro({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    required String name,
    required String functionName,
    int? shortcutSlot,
    DateTime? createdAt,
  }) = _MacroImpl;

  factory Macro.fromJson(Map<String, dynamic> jsonSerialization) {
    return Macro(
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
      functionName: jsonSerialization['functionName'] as String,
      shortcutSlot: jsonSerialization['shortcutSlot'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = MacroTable();

  static const db = MacroRepository._();

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

  String functionName;

  /// 1..10 → Mod+Alt+Shift+<n>.
  int? shortcutSlot;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [Macro]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Macro copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedMacro$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedMacro$project(),
    String? name,
    String? functionName,
    int? shortcutSlot,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Macro',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'projectId': projectId.toJson(),
      if (project != null) 'project': project?.toJson(),
      'name': name,
      'functionName': functionName,
      if (shortcutSlot != null) 'shortcutSlot': shortcutSlot,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static MacroInclude include({
    _imcki4bb.RevFileInclude? file,
    _itmevo3z.ScriptProjectInclude? project,
  }) {
    return MacroInclude._(
      file: file,
      project: project,
    );
  }

  static MacroIncludeList includeList({
    _is.WhereExpressionBuilder<MacroTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MacroTable>? orderBy,
    _is.OrderByListBuilder<MacroTable>? orderByList,
    MacroInclude? include,
  }) {
    return MacroIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Macro.t),
      orderByList: orderByList?.call(Macro.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedMacro$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedMacro$file();
}

class _UndefinedMacro$project extends _is.UndefinedSentinel
    implements _itmevo3z.ScriptProject {
  const _UndefinedMacro$project();
}

class _MacroImpl extends Macro {
  _MacroImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    required String name,
    required String functionName,
    int? shortcutSlot,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         projectId: projectId,
         project: project,
         name: name,
         functionName: functionName,
         shortcutSlot: shortcutSlot,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Macro]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Macro copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedMacro$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedMacro$project(),
    String? name,
    String? functionName,
    Object? shortcutSlot = _Undefined,
    DateTime? createdAt,
  }) {
    return Macro(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      projectId: projectId ?? this.projectId,
      project: project is _is.UndefinedSentinel
          ? this.project?.copyWith()
          : project,
      name: name ?? this.name,
      functionName: functionName ?? this.functionName,
      shortcutSlot: shortcutSlot is int? ? shortcutSlot : this.shortcutSlot,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MacroUpdateTable extends _is.UpdateTable<MacroTable> {
  MacroUpdateTable(super.table);

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

  _is.ColumnValue<String, String> functionName(String value) => _is.ColumnValue(
    table.functionName,
    value,
  );

  _is.ColumnValue<int, int> shortcutSlot(int? value) => _is.ColumnValue(
    table.shortcutSlot,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class MacroTable extends _is.Table<_is.UuidValue> {
  MacroTable({super.tableRelation}) : super(tableName: 'macro') {
    updateTable = MacroUpdateTable(this);
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
    functionName = _is.ColumnString(
      'functionName',
      this,
    );
    shortcutSlot = _is.ColumnInt(
      'shortcutSlot',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final MacroUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid projectId;

  _itmevo3z.ScriptProjectTable? _project;

  late final _is.ColumnString name;

  late final _is.ColumnString functionName;

  /// 1..10 → Mod+Alt+Shift+<n>.
  late final _is.ColumnInt shortcutSlot;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: Macro.t.fileId,
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
      field: Macro.t.projectId,
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
    functionName,
    shortcutSlot,
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

class MacroInclude extends _is.IncludeObject {
  MacroInclude._({
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
  _is.Table<_is.UuidValue> get table => Macro.t;
}

class MacroIncludeList extends _is.IncludeList {
  MacroIncludeList._({
    _is.WhereExpressionBuilder<MacroTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Macro.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => Macro.t;
}

class MacroRepository {
  const MacroRepository._();

  final attachRow = const MacroAttachRowRepository._();

  /// Returns a list of [Macro]s matching the given query parameters.
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
  Future<List<Macro>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MacroTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MacroTable>? orderBy,
    _is.OrderByListBuilder<MacroTable>? orderByList,
    _is.Transaction? transaction,
    MacroInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Macro>(
      where: where?.call(Macro.t),
      orderBy: orderBy?.call(Macro.t),
      orderByList: orderByList?.call(Macro.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Macro]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Macro.t`.
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
  _ida.Stream<List<Macro>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MacroTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MacroTable>? orderBy,
    _is.OrderByListBuilder<MacroTable>? orderByList,
    MacroInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Macro>(
      where: where?.call(Macro.t),
      orderBy: orderBy?.call(Macro.t),
      orderByList: orderByList?.call(Macro.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Macro] matching the given query parameters.
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
  Future<Macro?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MacroTable>? where,
    int? offset,
    _is.OrderByBuilder<MacroTable>? orderBy,
    _is.OrderByListBuilder<MacroTable>? orderByList,
    _is.Transaction? transaction,
    MacroInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Macro>(
      where: where?.call(Macro.t),
      orderBy: orderBy?.call(Macro.t),
      orderByList: orderByList?.call(Macro.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Macro] by its [id] or null if no such row exists.
  Future<Macro?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    MacroInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Macro>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Macro]s in the list and returns the inserted rows.
  ///
  /// The returned [Macro]s will have their `id` fields set.
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
  Future<List<Macro>> insert(
    _is.DatabaseSession session,
    List<Macro> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Macro>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Macro] and returns the inserted row.
  ///
  /// The returned [Macro] will have its `id` field set.
  Future<Macro> insertRow(
    _is.DatabaseSession session,
    Macro row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Macro>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Macro]s in the list and returns the resulting rows.
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
  /// The returned [Macro]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Macro>> upsert(
    _is.DatabaseSession session,
    List<Macro> rows, {
    required _is.ColumnSelections<MacroTable> conflictColumns,
    _is.ColumnSelections<MacroTable>? updateColumns,
    _is.WhereExpressionBuilder<MacroTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Macro>(
      rows,
      conflictColumns: conflictColumns(Macro.t),
      updateColumns: updateColumns?.call(Macro.t),
      updateWhere: updateWhere?.call(Macro.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Macro] and returns the resulting row.
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
  /// The returned [Macro] will have its `id` field set.
  Future<Macro?> upsertRow(
    _is.DatabaseSession session,
    Macro row, {
    required _is.ColumnSelections<MacroTable> conflictColumns,
    _is.ColumnSelections<MacroTable>? updateColumns,
    _is.WhereExpressionBuilder<MacroTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Macro>(
      row,
      conflictColumns: conflictColumns(Macro.t),
      updateColumns: updateColumns?.call(Macro.t),
      updateWhere: updateWhere?.call(Macro.t),
      transaction: transaction,
    );
  }

  /// Updates all [Macro]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Macro>> update(
    _is.DatabaseSession session,
    List<Macro> rows, {
    _is.ColumnSelections<MacroTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Macro>(
      rows,
      columns: columns?.call(Macro.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Macro]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Macro> updateRow(
    _is.DatabaseSession session,
    Macro row, {
    _is.ColumnSelections<MacroTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Macro>(
      row,
      columns: columns?.call(Macro.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Macro] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Macro?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<MacroUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Macro>(
      id,
      columnValues: columnValues(Macro.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Macro]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Macro>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MacroUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MacroTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MacroTable>? orderBy,
    _is.OrderByListBuilder<MacroTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Macro>(
      columnValues: columnValues(Macro.t.updateTable),
      where: where(Macro.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Macro.t),
      orderByList: orderByList?.call(Macro.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Macro]s in the list and returns the deleted rows.
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
  Future<List<Macro>> delete(
    _is.DatabaseSession session,
    List<Macro> rows, {
    _is.OrderByBuilder<MacroTable>? orderBy,
    _is.OrderByListBuilder<MacroTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Macro>(
      rows,
      orderBy: orderBy?.call(Macro.t),
      orderByList: orderByList?.call(Macro.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Macro].
  Future<Macro> deleteRow(
    _is.DatabaseSession session,
    Macro row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Macro>(
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
  Future<List<Macro>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MacroTable> where,
    _is.OrderByBuilder<MacroTable>? orderBy,
    _is.OrderByListBuilder<MacroTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Macro>(
      where: where(Macro.t),
      orderBy: orderBy?.call(Macro.t),
      orderByList: orderByList?.call(Macro.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MacroTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Macro>(
      where: where?.call(Macro.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Macro] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MacroTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Macro>(
      where: where(Macro.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class MacroAttachRowRepository {
  const MacroAttachRowRepository._();

  /// Creates a relation between the given [Macro] and [RevFile]
  /// by setting the [Macro]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    Macro macro,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (macro.id == null) {
      throw ArgumentError.notNull('macro.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $macro = macro.copyWith(fileId: file.id);
    await session.db.updateRow<Macro>(
      $macro,
      columns: [Macro.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Macro] and [ScriptProject]
  /// by setting the [Macro]'s foreign key `projectId` to refer to the [ScriptProject].
  Future<void> project(
    _is.DatabaseSession session,
    Macro macro,
    _itmevo3z.ScriptProject project, {
    _is.Transaction? transaction,
  }) async {
    if (macro.id == null) {
      throw ArgumentError.notNull('macro.id');
    }
    if (project.id == null) {
      throw ArgumentError.notNull('project.id');
    }

    var $macro = macro.copyWith(projectId: project.id);
    await session.db.updateRow<Macro>(
      $macro,
      columns: [Macro.t.projectId],
      transaction: transaction,
    );
  }
}
