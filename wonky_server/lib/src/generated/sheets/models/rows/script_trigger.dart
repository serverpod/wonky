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
import '../../../sheets/models/rows/enums/trigger_kind.dart' as _iw3ssuit;
import '../../../sheets/models/rows/script_project.dart' as _itmevo3z;

/// An installable script trigger.
abstract class ScriptTrigger
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  ScriptTrigger._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.projectId,
    this.project,
    required this.kind,
    required this.functionName,
    this.scheduleJson,
    required this.runAsUserId,
    bool? enabled,
    this.optionsJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       enabled = enabled ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory ScriptTrigger({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    required _iw3ssuit.TriggerKind kind,
    required String functionName,
    String? scheduleJson,
    required _is.UuidValue runAsUserId,
    bool? enabled,
    String? optionsJson,
    DateTime? createdAt,
  }) = _ScriptTriggerImpl;

  factory ScriptTrigger.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScriptTrigger(
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
      kind: _iw3ssuit.TriggerKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      functionName: jsonSerialization['functionName'] as String,
      scheduleJson: jsonSerialization['scheduleJson'] as String?,
      runAsUserId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['runAsUserId'],
      ),
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      optionsJson: jsonSerialization['optionsJson'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ScriptTriggerTable();

  static const db = ScriptTriggerRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue projectId;

  _itmevo3z.ScriptProject? project;

  _iw3ssuit.TriggerKind kind;

  String functionName;

  String? scheduleJson;

  /// Installer; must keep edit access.
  _is.UuidValue runAsUserId;

  bool enabled;

  /// {fireForMcp, notify}.
  String? optionsJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [ScriptTrigger]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScriptTrigger copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptTrigger$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedScriptTrigger$project(),
    _iw3ssuit.TriggerKind? kind,
    String? functionName,
    String? scheduleJson,
    _is.UuidValue? runAsUserId,
    bool? enabled,
    String? optionsJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScriptTrigger',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'projectId': projectId.toJson(),
      if (project != null) 'project': project?.toJson(),
      'kind': kind.toJson(),
      'functionName': functionName,
      if (scheduleJson != null) 'scheduleJson': scheduleJson,
      'runAsUserId': runAsUserId.toJson(),
      'enabled': enabled,
      if (optionsJson != null) 'optionsJson': optionsJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ScriptTriggerInclude include({
    _imcki4bb.RevFileInclude? file,
    _itmevo3z.ScriptProjectInclude? project,
  }) {
    return ScriptTriggerInclude._(
      file: file,
      project: project,
    );
  }

  static ScriptTriggerIncludeList includeList({
    _is.WhereExpressionBuilder<ScriptTriggerTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptTriggerTable>? orderBy,
    _is.OrderByListBuilder<ScriptTriggerTable>? orderByList,
    ScriptTriggerInclude? include,
  }) {
    return ScriptTriggerIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptTrigger.t),
      orderByList: orderByList?.call(ScriptTrigger.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedScriptTrigger$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedScriptTrigger$file();
}

class _UndefinedScriptTrigger$project extends _is.UndefinedSentinel
    implements _itmevo3z.ScriptProject {
  const _UndefinedScriptTrigger$project();
}

class _ScriptTriggerImpl extends ScriptTrigger {
  _ScriptTriggerImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    required _iw3ssuit.TriggerKind kind,
    required String functionName,
    String? scheduleJson,
    required _is.UuidValue runAsUserId,
    bool? enabled,
    String? optionsJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         projectId: projectId,
         project: project,
         kind: kind,
         functionName: functionName,
         scheduleJson: scheduleJson,
         runAsUserId: runAsUserId,
         enabled: enabled,
         optionsJson: optionsJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ScriptTrigger]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ScriptTrigger copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptTrigger$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedScriptTrigger$project(),
    _iw3ssuit.TriggerKind? kind,
    String? functionName,
    Object? scheduleJson = _Undefined,
    _is.UuidValue? runAsUserId,
    bool? enabled,
    Object? optionsJson = _Undefined,
    DateTime? createdAt,
  }) {
    return ScriptTrigger(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      projectId: projectId ?? this.projectId,
      project: project is _is.UndefinedSentinel
          ? this.project?.copyWith()
          : project,
      kind: kind ?? this.kind,
      functionName: functionName ?? this.functionName,
      scheduleJson: scheduleJson is String? ? scheduleJson : this.scheduleJson,
      runAsUserId: runAsUserId ?? this.runAsUserId,
      enabled: enabled ?? this.enabled,
      optionsJson: optionsJson is String? ? optionsJson : this.optionsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ScriptTriggerUpdateTable extends _is.UpdateTable<ScriptTriggerTable> {
  ScriptTriggerUpdateTable(super.table);

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

  _is.ColumnValue<_iw3ssuit.TriggerKind, _iw3ssuit.TriggerKind> kind(
    _iw3ssuit.TriggerKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> functionName(String value) => _is.ColumnValue(
    table.functionName,
    value,
  );

  _is.ColumnValue<String, String> scheduleJson(String? value) =>
      _is.ColumnValue(
        table.scheduleJson,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> runAsUserId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.runAsUserId,
    value,
  );

  _is.ColumnValue<bool, bool> enabled(bool value) => _is.ColumnValue(
    table.enabled,
    value,
  );

  _is.ColumnValue<String, String> optionsJson(String? value) => _is.ColumnValue(
    table.optionsJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ScriptTriggerTable extends _is.Table<_is.UuidValue> {
  ScriptTriggerTable({super.tableRelation})
    : super(tableName: 'script_trigger') {
    updateTable = ScriptTriggerUpdateTable(this);
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
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    functionName = _is.ColumnString(
      'functionName',
      this,
    );
    scheduleJson = _is.ColumnString(
      'scheduleJson',
      this,
    );
    runAsUserId = _is.ColumnUuid(
      'runAsUserId',
      this,
    );
    enabled = _is.ColumnBool(
      'enabled',
      this,
      hasDefault: true,
    );
    optionsJson = _is.ColumnString(
      'optionsJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ScriptTriggerUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid projectId;

  _itmevo3z.ScriptProjectTable? _project;

  late final _is.ColumnEnum<_iw3ssuit.TriggerKind> kind;

  late final _is.ColumnString functionName;

  late final _is.ColumnString scheduleJson;

  /// Installer; must keep edit access.
  late final _is.ColumnUuid runAsUserId;

  late final _is.ColumnBool enabled;

  /// {fireForMcp, notify}.
  late final _is.ColumnString optionsJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: ScriptTrigger.t.fileId,
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
      field: ScriptTrigger.t.projectId,
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
    kind,
    functionName,
    scheduleJson,
    runAsUserId,
    enabled,
    optionsJson,
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

class ScriptTriggerInclude extends _is.IncludeObject {
  ScriptTriggerInclude._({
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
  _is.Table<_is.UuidValue> get table => ScriptTrigger.t;
}

class ScriptTriggerIncludeList extends _is.IncludeList {
  ScriptTriggerIncludeList._({
    _is.WhereExpressionBuilder<ScriptTriggerTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ScriptTrigger.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => ScriptTrigger.t;
}

class ScriptTriggerRepository {
  const ScriptTriggerRepository._();

  final attachRow = const ScriptTriggerAttachRowRepository._();

  /// Returns a list of [ScriptTrigger]s matching the given query parameters.
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
  Future<List<ScriptTrigger>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptTriggerTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptTriggerTable>? orderBy,
    _is.OrderByListBuilder<ScriptTriggerTable>? orderByList,
    _is.Transaction? transaction,
    ScriptTriggerInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ScriptTrigger>(
      where: where?.call(ScriptTrigger.t),
      orderBy: orderBy?.call(ScriptTrigger.t),
      orderByList: orderByList?.call(ScriptTrigger.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ScriptTrigger]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ScriptTrigger.t`.
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
  _ida.Stream<List<ScriptTrigger>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptTriggerTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptTriggerTable>? orderBy,
    _is.OrderByListBuilder<ScriptTriggerTable>? orderByList,
    ScriptTriggerInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ScriptTrigger>(
      where: where?.call(ScriptTrigger.t),
      orderBy: orderBy?.call(ScriptTrigger.t),
      orderByList: orderByList?.call(ScriptTrigger.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ScriptTrigger] matching the given query parameters.
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
  Future<ScriptTrigger?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptTriggerTable>? where,
    int? offset,
    _is.OrderByBuilder<ScriptTriggerTable>? orderBy,
    _is.OrderByListBuilder<ScriptTriggerTable>? orderByList,
    _is.Transaction? transaction,
    ScriptTriggerInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ScriptTrigger>(
      where: where?.call(ScriptTrigger.t),
      orderBy: orderBy?.call(ScriptTrigger.t),
      orderByList: orderByList?.call(ScriptTrigger.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ScriptTrigger] by its [id] or null if no such row exists.
  Future<ScriptTrigger?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ScriptTriggerInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ScriptTrigger>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ScriptTrigger]s in the list and returns the inserted rows.
  ///
  /// The returned [ScriptTrigger]s will have their `id` fields set.
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
  Future<List<ScriptTrigger>> insert(
    _is.DatabaseSession session,
    List<ScriptTrigger> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ScriptTrigger>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ScriptTrigger] and returns the inserted row.
  ///
  /// The returned [ScriptTrigger] will have its `id` field set.
  Future<ScriptTrigger> insertRow(
    _is.DatabaseSession session,
    ScriptTrigger row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ScriptTrigger>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ScriptTrigger]s in the list and returns the resulting rows.
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
  /// The returned [ScriptTrigger]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptTrigger>> upsert(
    _is.DatabaseSession session,
    List<ScriptTrigger> rows, {
    required _is.ColumnSelections<ScriptTriggerTable> conflictColumns,
    _is.ColumnSelections<ScriptTriggerTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptTriggerTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ScriptTrigger>(
      rows,
      conflictColumns: conflictColumns(ScriptTrigger.t),
      updateColumns: updateColumns?.call(ScriptTrigger.t),
      updateWhere: updateWhere?.call(ScriptTrigger.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ScriptTrigger] and returns the resulting row.
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
  /// The returned [ScriptTrigger] will have its `id` field set.
  Future<ScriptTrigger?> upsertRow(
    _is.DatabaseSession session,
    ScriptTrigger row, {
    required _is.ColumnSelections<ScriptTriggerTable> conflictColumns,
    _is.ColumnSelections<ScriptTriggerTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptTriggerTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ScriptTrigger>(
      row,
      conflictColumns: conflictColumns(ScriptTrigger.t),
      updateColumns: updateColumns?.call(ScriptTrigger.t),
      updateWhere: updateWhere?.call(ScriptTrigger.t),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptTrigger]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptTrigger>> update(
    _is.DatabaseSession session,
    List<ScriptTrigger> rows, {
    _is.ColumnSelections<ScriptTriggerTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ScriptTrigger>(
      rows,
      columns: columns?.call(ScriptTrigger.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ScriptTrigger]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ScriptTrigger> updateRow(
    _is.DatabaseSession session,
    ScriptTrigger row, {
    _is.ColumnSelections<ScriptTriggerTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ScriptTrigger>(
      row,
      columns: columns?.call(ScriptTrigger.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ScriptTrigger] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ScriptTrigger?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ScriptTriggerUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ScriptTrigger>(
      id,
      columnValues: columnValues(ScriptTrigger.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptTrigger]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptTrigger>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ScriptTriggerUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ScriptTriggerTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptTriggerTable>? orderBy,
    _is.OrderByListBuilder<ScriptTriggerTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ScriptTrigger>(
      columnValues: columnValues(ScriptTrigger.t.updateTable),
      where: where(ScriptTrigger.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptTrigger.t),
      orderByList: orderByList?.call(ScriptTrigger.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ScriptTrigger]s in the list and returns the deleted rows.
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
  Future<List<ScriptTrigger>> delete(
    _is.DatabaseSession session,
    List<ScriptTrigger> rows, {
    _is.OrderByBuilder<ScriptTriggerTable>? orderBy,
    _is.OrderByListBuilder<ScriptTriggerTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ScriptTrigger>(
      rows,
      orderBy: orderBy?.call(ScriptTrigger.t),
      orderByList: orderByList?.call(ScriptTrigger.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ScriptTrigger].
  Future<ScriptTrigger> deleteRow(
    _is.DatabaseSession session,
    ScriptTrigger row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ScriptTrigger>(
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
  Future<List<ScriptTrigger>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptTriggerTable> where,
    _is.OrderByBuilder<ScriptTriggerTable>? orderBy,
    _is.OrderByListBuilder<ScriptTriggerTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ScriptTrigger>(
      where: where(ScriptTrigger.t),
      orderBy: orderBy?.call(ScriptTrigger.t),
      orderByList: orderByList?.call(ScriptTrigger.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptTriggerTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ScriptTrigger>(
      where: where?.call(ScriptTrigger.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ScriptTrigger] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptTriggerTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ScriptTrigger>(
      where: where(ScriptTrigger.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ScriptTriggerAttachRowRepository {
  const ScriptTriggerAttachRowRepository._();

  /// Creates a relation between the given [ScriptTrigger] and [RevFile]
  /// by setting the [ScriptTrigger]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    ScriptTrigger scriptTrigger,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (scriptTrigger.id == null) {
      throw ArgumentError.notNull('scriptTrigger.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $scriptTrigger = scriptTrigger.copyWith(fileId: file.id);
    await session.db.updateRow<ScriptTrigger>(
      $scriptTrigger,
      columns: [ScriptTrigger.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ScriptTrigger] and [ScriptProject]
  /// by setting the [ScriptTrigger]'s foreign key `projectId` to refer to the [ScriptProject].
  Future<void> project(
    _is.DatabaseSession session,
    ScriptTrigger scriptTrigger,
    _itmevo3z.ScriptProject project, {
    _is.Transaction? transaction,
  }) async {
    if (scriptTrigger.id == null) {
      throw ArgumentError.notNull('scriptTrigger.id');
    }
    if (project.id == null) {
      throw ArgumentError.notNull('project.id');
    }

    var $scriptTrigger = scriptTrigger.copyWith(projectId: project.id);
    await session.db.updateRow<ScriptTrigger>(
      $scriptTrigger,
      columns: [ScriptTrigger.t.projectId],
      transaction: transaction,
    );
  }
}
