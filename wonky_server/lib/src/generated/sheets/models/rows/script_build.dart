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
import '../../../sheets/models/rows/enums/script_build_status.dart'
    as _iqjo2sys;
import '../../../sheets/models/rows/script_project.dart' as _itmevo3z;

/// Compilation result, written by the server; id = SheetsIds.scriptBuildId(projectId).
abstract class ScriptBuild
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  ScriptBuild._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.projectId,
    this.project,
    _iqjo2sys.ScriptBuildStatus? status,
    required this.sourceHash,
    this.bytecodeFileUuid,
    required this.diagnosticsJson,
    required this.exportsJson,
    int? apiVersion,
    String? compilerVersion,
    this.requestedBy,
    this.lastGoodSourceHash,
    this.lastGoodBytecodeFileUuid,
    this.lastGoodExportsJson,
    this.lastGoodBuiltAt,
    this.positionsFileUuid,
    required this.builtAt,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       status = status ?? _iqjo2sys.ScriptBuildStatus.ok,
       apiVersion = apiVersion ?? 1,
       compilerVersion = compilerVersion ?? '',
       createdAt = createdAt ?? DateTime.now();

  factory ScriptBuild({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    _iqjo2sys.ScriptBuildStatus? status,
    required String sourceHash,
    _is.UuidValue? bytecodeFileUuid,
    required String diagnosticsJson,
    required String exportsJson,
    int? apiVersion,
    String? compilerVersion,
    _is.UuidValue? requestedBy,
    String? lastGoodSourceHash,
    _is.UuidValue? lastGoodBytecodeFileUuid,
    String? lastGoodExportsJson,
    DateTime? lastGoodBuiltAt,
    _is.UuidValue? positionsFileUuid,
    required DateTime builtAt,
    DateTime? createdAt,
  }) = _ScriptBuildImpl;

  factory ScriptBuild.fromJson(Map<String, dynamic> jsonSerialization) {
    return ScriptBuild(
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
      status: jsonSerialization['status'] == null
          ? null
          : _iqjo2sys.ScriptBuildStatus.fromJson(
              (jsonSerialization['status'] as String),
            ),
      sourceHash: jsonSerialization['sourceHash'] as String,
      bytecodeFileUuid: jsonSerialization['bytecodeFileUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['bytecodeFileUuid'],
            ),
      diagnosticsJson: jsonSerialization['diagnosticsJson'] as String,
      exportsJson: jsonSerialization['exportsJson'] as String,
      apiVersion: jsonSerialization['apiVersion'] as int?,
      compilerVersion: jsonSerialization['compilerVersion'] as String?,
      requestedBy: jsonSerialization['requestedBy'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['requestedBy'],
            ),
      lastGoodSourceHash: jsonSerialization['lastGoodSourceHash'] as String?,
      lastGoodBytecodeFileUuid:
          jsonSerialization['lastGoodBytecodeFileUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['lastGoodBytecodeFileUuid'],
            ),
      lastGoodExportsJson: jsonSerialization['lastGoodExportsJson'] as String?,
      lastGoodBuiltAt: jsonSerialization['lastGoodBuiltAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastGoodBuiltAt'],
            ),
      positionsFileUuid: jsonSerialization['positionsFileUuid'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['positionsFileUuid'],
            ),
      builtAt: _is.DateTimeJsonExtension.fromJson(jsonSerialization['builtAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ScriptBuildTable();

  static const db = ScriptBuildRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue projectId;

  _itmevo3z.ScriptProject? project;

  _iqjo2sys.ScriptBuildStatus status;

  String sourceHash;

  /// EVC bytecode in cloud storage (null if errors).
  _is.UuidValue? bytecodeFileUuid;

  String diagnosticsJson;

  String exportsJson;

  int apiVersion;

  String compilerVersion;

  _is.UuidValue? requestedBy;

  String? lastGoodSourceHash;

  _is.UuidValue? lastGoodBytecodeFileUuid;

  String? lastGoodExportsJson;

  DateTime? lastGoodBuiltAt;

  _is.UuidValue? positionsFileUuid;

  DateTime builtAt;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [ScriptBuild]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ScriptBuild copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptBuild$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedScriptBuild$project(),
    _iqjo2sys.ScriptBuildStatus? status,
    String? sourceHash,
    _is.UuidValue? bytecodeFileUuid = const _is.$UndefinedUuidValue(),
    String? diagnosticsJson,
    String? exportsJson,
    int? apiVersion,
    String? compilerVersion,
    _is.UuidValue? requestedBy = const _is.$UndefinedUuidValue(),
    String? lastGoodSourceHash,
    _is.UuidValue? lastGoodBytecodeFileUuid = const _is.$UndefinedUuidValue(),
    String? lastGoodExportsJson,
    DateTime? lastGoodBuiltAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? positionsFileUuid = const _is.$UndefinedUuidValue(),
    DateTime? builtAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ScriptBuild',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'projectId': projectId.toJson(),
      if (project != null) 'project': project?.toJson(),
      'status': status.toJson(),
      'sourceHash': sourceHash,
      if (bytecodeFileUuid != null)
        'bytecodeFileUuid': bytecodeFileUuid?.toJson(),
      'diagnosticsJson': diagnosticsJson,
      'exportsJson': exportsJson,
      'apiVersion': apiVersion,
      'compilerVersion': compilerVersion,
      if (requestedBy != null) 'requestedBy': requestedBy?.toJson(),
      if (lastGoodSourceHash != null) 'lastGoodSourceHash': lastGoodSourceHash,
      if (lastGoodBytecodeFileUuid != null)
        'lastGoodBytecodeFileUuid': lastGoodBytecodeFileUuid?.toJson(),
      if (lastGoodExportsJson != null)
        'lastGoodExportsJson': lastGoodExportsJson,
      if (lastGoodBuiltAt != null) 'lastGoodBuiltAt': lastGoodBuiltAt?.toJson(),
      if (positionsFileUuid != null)
        'positionsFileUuid': positionsFileUuid?.toJson(),
      'builtAt': builtAt.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ScriptBuildInclude include({
    _imcki4bb.RevFileInclude? file,
    _itmevo3z.ScriptProjectInclude? project,
  }) {
    return ScriptBuildInclude._(
      file: file,
      project: project,
    );
  }

  static ScriptBuildIncludeList includeList({
    _is.WhereExpressionBuilder<ScriptBuildTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptBuildTable>? orderBy,
    _is.OrderByListBuilder<ScriptBuildTable>? orderByList,
    ScriptBuildInclude? include,
  }) {
    return ScriptBuildIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptBuild.t),
      orderByList: orderByList?.call(ScriptBuild.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedScriptBuild$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedScriptBuild$file();
}

class _UndefinedScriptBuild$project extends _is.UndefinedSentinel
    implements _itmevo3z.ScriptProject {
  const _UndefinedScriptBuild$project();
}

class _ScriptBuildImpl extends ScriptBuild {
  _ScriptBuildImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue projectId,
    _itmevo3z.ScriptProject? project,
    _iqjo2sys.ScriptBuildStatus? status,
    required String sourceHash,
    _is.UuidValue? bytecodeFileUuid,
    required String diagnosticsJson,
    required String exportsJson,
    int? apiVersion,
    String? compilerVersion,
    _is.UuidValue? requestedBy,
    String? lastGoodSourceHash,
    _is.UuidValue? lastGoodBytecodeFileUuid,
    String? lastGoodExportsJson,
    DateTime? lastGoodBuiltAt,
    _is.UuidValue? positionsFileUuid,
    required DateTime builtAt,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         projectId: projectId,
         project: project,
         status: status,
         sourceHash: sourceHash,
         bytecodeFileUuid: bytecodeFileUuid,
         diagnosticsJson: diagnosticsJson,
         exportsJson: exportsJson,
         apiVersion: apiVersion,
         compilerVersion: compilerVersion,
         requestedBy: requestedBy,
         lastGoodSourceHash: lastGoodSourceHash,
         lastGoodBytecodeFileUuid: lastGoodBytecodeFileUuid,
         lastGoodExportsJson: lastGoodExportsJson,
         lastGoodBuiltAt: lastGoodBuiltAt,
         positionsFileUuid: positionsFileUuid,
         builtAt: builtAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ScriptBuild]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ScriptBuild copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedScriptBuild$file(),
    int? revision,
    _is.UuidValue? projectId,
    _itmevo3z.ScriptProject? project = const _UndefinedScriptBuild$project(),
    _iqjo2sys.ScriptBuildStatus? status,
    String? sourceHash,
    _is.UuidValue? bytecodeFileUuid = const _is.$UndefinedUuidValue(),
    String? diagnosticsJson,
    String? exportsJson,
    int? apiVersion,
    String? compilerVersion,
    _is.UuidValue? requestedBy = const _is.$UndefinedUuidValue(),
    Object? lastGoodSourceHash = _Undefined,
    _is.UuidValue? lastGoodBytecodeFileUuid = const _is.$UndefinedUuidValue(),
    Object? lastGoodExportsJson = _Undefined,
    DateTime? lastGoodBuiltAt = const _is.$UndefinedDateTime(),
    _is.UuidValue? positionsFileUuid = const _is.$UndefinedUuidValue(),
    DateTime? builtAt,
    DateTime? createdAt,
  }) {
    return ScriptBuild(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      projectId: projectId ?? this.projectId,
      project: project is _is.UndefinedSentinel
          ? this.project?.copyWith()
          : project,
      status: status ?? this.status,
      sourceHash: sourceHash ?? this.sourceHash,
      bytecodeFileUuid: bytecodeFileUuid is _is.UndefinedSentinel
          ? this.bytecodeFileUuid
          : bytecodeFileUuid,
      diagnosticsJson: diagnosticsJson ?? this.diagnosticsJson,
      exportsJson: exportsJson ?? this.exportsJson,
      apiVersion: apiVersion ?? this.apiVersion,
      compilerVersion: compilerVersion ?? this.compilerVersion,
      requestedBy: requestedBy is _is.UndefinedSentinel
          ? this.requestedBy
          : requestedBy,
      lastGoodSourceHash: lastGoodSourceHash is String?
          ? lastGoodSourceHash
          : this.lastGoodSourceHash,
      lastGoodBytecodeFileUuid:
          lastGoodBytecodeFileUuid is _is.UndefinedSentinel
          ? this.lastGoodBytecodeFileUuid
          : lastGoodBytecodeFileUuid,
      lastGoodExportsJson: lastGoodExportsJson is String?
          ? lastGoodExportsJson
          : this.lastGoodExportsJson,
      lastGoodBuiltAt: lastGoodBuiltAt is _is.UndefinedSentinel
          ? this.lastGoodBuiltAt
          : lastGoodBuiltAt,
      positionsFileUuid: positionsFileUuid is _is.UndefinedSentinel
          ? this.positionsFileUuid
          : positionsFileUuid,
      builtAt: builtAt ?? this.builtAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ScriptBuildUpdateTable extends _is.UpdateTable<ScriptBuildTable> {
  ScriptBuildUpdateTable(super.table);

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

  _is.ColumnValue<_iqjo2sys.ScriptBuildStatus, _iqjo2sys.ScriptBuildStatus>
  status(_iqjo2sys.ScriptBuildStatus value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> sourceHash(String value) => _is.ColumnValue(
    table.sourceHash,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> bytecodeFileUuid(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.bytecodeFileUuid,
    value,
  );

  _is.ColumnValue<String, String> diagnosticsJson(String value) =>
      _is.ColumnValue(
        table.diagnosticsJson,
        value,
      );

  _is.ColumnValue<String, String> exportsJson(String value) => _is.ColumnValue(
    table.exportsJson,
    value,
  );

  _is.ColumnValue<int, int> apiVersion(int value) => _is.ColumnValue(
    table.apiVersion,
    value,
  );

  _is.ColumnValue<String, String> compilerVersion(String value) =>
      _is.ColumnValue(
        table.compilerVersion,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> requestedBy(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.requestedBy,
    value,
  );

  _is.ColumnValue<String, String> lastGoodSourceHash(String? value) =>
      _is.ColumnValue(
        table.lastGoodSourceHash,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> lastGoodBytecodeFileUuid(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.lastGoodBytecodeFileUuid,
    value,
  );

  _is.ColumnValue<String, String> lastGoodExportsJson(String? value) =>
      _is.ColumnValue(
        table.lastGoodExportsJson,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> lastGoodBuiltAt(DateTime? value) =>
      _is.ColumnValue(
        table.lastGoodBuiltAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> positionsFileUuid(
    _is.UuidValue? value,
  ) => _is.ColumnValue(
    table.positionsFileUuid,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> builtAt(DateTime value) =>
      _is.ColumnValue(
        table.builtAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ScriptBuildTable extends _is.Table<_is.UuidValue> {
  ScriptBuildTable({super.tableRelation}) : super(tableName: 'script_build') {
    updateTable = ScriptBuildUpdateTable(this);
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
    status = _is.ColumnEnum(
      'status',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    sourceHash = _is.ColumnString(
      'sourceHash',
      this,
    );
    bytecodeFileUuid = _is.ColumnUuid(
      'bytecodeFileUuid',
      this,
    );
    diagnosticsJson = _is.ColumnString(
      'diagnosticsJson',
      this,
    );
    exportsJson = _is.ColumnString(
      'exportsJson',
      this,
    );
    apiVersion = _is.ColumnInt(
      'apiVersion',
      this,
      hasDefault: true,
    );
    compilerVersion = _is.ColumnString(
      'compilerVersion',
      this,
      hasDefault: true,
    );
    requestedBy = _is.ColumnUuid(
      'requestedBy',
      this,
    );
    lastGoodSourceHash = _is.ColumnString(
      'lastGoodSourceHash',
      this,
    );
    lastGoodBytecodeFileUuid = _is.ColumnUuid(
      'lastGoodBytecodeFileUuid',
      this,
    );
    lastGoodExportsJson = _is.ColumnString(
      'lastGoodExportsJson',
      this,
    );
    lastGoodBuiltAt = _is.ColumnDateTime(
      'lastGoodBuiltAt',
      this,
    );
    positionsFileUuid = _is.ColumnUuid(
      'positionsFileUuid',
      this,
    );
    builtAt = _is.ColumnDateTime(
      'builtAt',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ScriptBuildUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid projectId;

  _itmevo3z.ScriptProjectTable? _project;

  late final _is.ColumnEnum<_iqjo2sys.ScriptBuildStatus> status;

  late final _is.ColumnString sourceHash;

  /// EVC bytecode in cloud storage (null if errors).
  late final _is.ColumnUuid bytecodeFileUuid;

  late final _is.ColumnString diagnosticsJson;

  late final _is.ColumnString exportsJson;

  late final _is.ColumnInt apiVersion;

  late final _is.ColumnString compilerVersion;

  late final _is.ColumnUuid requestedBy;

  late final _is.ColumnString lastGoodSourceHash;

  late final _is.ColumnUuid lastGoodBytecodeFileUuid;

  late final _is.ColumnString lastGoodExportsJson;

  late final _is.ColumnDateTime lastGoodBuiltAt;

  late final _is.ColumnUuid positionsFileUuid;

  late final _is.ColumnDateTime builtAt;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: ScriptBuild.t.fileId,
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
      field: ScriptBuild.t.projectId,
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
    status,
    sourceHash,
    bytecodeFileUuid,
    diagnosticsJson,
    exportsJson,
    apiVersion,
    compilerVersion,
    requestedBy,
    lastGoodSourceHash,
    lastGoodBytecodeFileUuid,
    lastGoodExportsJson,
    lastGoodBuiltAt,
    positionsFileUuid,
    builtAt,
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

class ScriptBuildInclude extends _is.IncludeObject {
  ScriptBuildInclude._({
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
  _is.Table<_is.UuidValue> get table => ScriptBuild.t;
}

class ScriptBuildIncludeList extends _is.IncludeList {
  ScriptBuildIncludeList._({
    _is.WhereExpressionBuilder<ScriptBuildTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ScriptBuild.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => ScriptBuild.t;
}

class ScriptBuildRepository {
  const ScriptBuildRepository._();

  final attachRow = const ScriptBuildAttachRowRepository._();

  /// Returns a list of [ScriptBuild]s matching the given query parameters.
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
  Future<List<ScriptBuild>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptBuildTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptBuildTable>? orderBy,
    _is.OrderByListBuilder<ScriptBuildTable>? orderByList,
    _is.Transaction? transaction,
    ScriptBuildInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ScriptBuild>(
      where: where?.call(ScriptBuild.t),
      orderBy: orderBy?.call(ScriptBuild.t),
      orderByList: orderByList?.call(ScriptBuild.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ScriptBuild]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ScriptBuild.t`.
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
  _ida.Stream<List<ScriptBuild>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptBuildTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptBuildTable>? orderBy,
    _is.OrderByListBuilder<ScriptBuildTable>? orderByList,
    ScriptBuildInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ScriptBuild>(
      where: where?.call(ScriptBuild.t),
      orderBy: orderBy?.call(ScriptBuild.t),
      orderByList: orderByList?.call(ScriptBuild.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ScriptBuild] matching the given query parameters.
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
  Future<ScriptBuild?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptBuildTable>? where,
    int? offset,
    _is.OrderByBuilder<ScriptBuildTable>? orderBy,
    _is.OrderByListBuilder<ScriptBuildTable>? orderByList,
    _is.Transaction? transaction,
    ScriptBuildInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ScriptBuild>(
      where: where?.call(ScriptBuild.t),
      orderBy: orderBy?.call(ScriptBuild.t),
      orderByList: orderByList?.call(ScriptBuild.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ScriptBuild] by its [id] or null if no such row exists.
  Future<ScriptBuild?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ScriptBuildInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ScriptBuild>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ScriptBuild]s in the list and returns the inserted rows.
  ///
  /// The returned [ScriptBuild]s will have their `id` fields set.
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
  Future<List<ScriptBuild>> insert(
    _is.DatabaseSession session,
    List<ScriptBuild> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ScriptBuild>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ScriptBuild] and returns the inserted row.
  ///
  /// The returned [ScriptBuild] will have its `id` field set.
  Future<ScriptBuild> insertRow(
    _is.DatabaseSession session,
    ScriptBuild row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ScriptBuild>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ScriptBuild]s in the list and returns the resulting rows.
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
  /// The returned [ScriptBuild]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptBuild>> upsert(
    _is.DatabaseSession session,
    List<ScriptBuild> rows, {
    required _is.ColumnSelections<ScriptBuildTable> conflictColumns,
    _is.ColumnSelections<ScriptBuildTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptBuildTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ScriptBuild>(
      rows,
      conflictColumns: conflictColumns(ScriptBuild.t),
      updateColumns: updateColumns?.call(ScriptBuild.t),
      updateWhere: updateWhere?.call(ScriptBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ScriptBuild] and returns the resulting row.
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
  /// The returned [ScriptBuild] will have its `id` field set.
  Future<ScriptBuild?> upsertRow(
    _is.DatabaseSession session,
    ScriptBuild row, {
    required _is.ColumnSelections<ScriptBuildTable> conflictColumns,
    _is.ColumnSelections<ScriptBuildTable>? updateColumns,
    _is.WhereExpressionBuilder<ScriptBuildTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ScriptBuild>(
      row,
      conflictColumns: conflictColumns(ScriptBuild.t),
      updateColumns: updateColumns?.call(ScriptBuild.t),
      updateWhere: updateWhere?.call(ScriptBuild.t),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptBuild]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptBuild>> update(
    _is.DatabaseSession session,
    List<ScriptBuild> rows, {
    _is.ColumnSelections<ScriptBuildTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ScriptBuild>(
      rows,
      columns: columns?.call(ScriptBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ScriptBuild]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ScriptBuild> updateRow(
    _is.DatabaseSession session,
    ScriptBuild row, {
    _is.ColumnSelections<ScriptBuildTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ScriptBuild>(
      row,
      columns: columns?.call(ScriptBuild.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ScriptBuild] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ScriptBuild?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ScriptBuildUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ScriptBuild>(
      id,
      columnValues: columnValues(ScriptBuild.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ScriptBuild]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ScriptBuild>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ScriptBuildUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ScriptBuildTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ScriptBuildTable>? orderBy,
    _is.OrderByListBuilder<ScriptBuildTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ScriptBuild>(
      columnValues: columnValues(ScriptBuild.t.updateTable),
      where: where(ScriptBuild.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ScriptBuild.t),
      orderByList: orderByList?.call(ScriptBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ScriptBuild]s in the list and returns the deleted rows.
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
  Future<List<ScriptBuild>> delete(
    _is.DatabaseSession session,
    List<ScriptBuild> rows, {
    _is.OrderByBuilder<ScriptBuildTable>? orderBy,
    _is.OrderByListBuilder<ScriptBuildTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ScriptBuild>(
      rows,
      orderBy: orderBy?.call(ScriptBuild.t),
      orderByList: orderByList?.call(ScriptBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ScriptBuild].
  Future<ScriptBuild> deleteRow(
    _is.DatabaseSession session,
    ScriptBuild row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ScriptBuild>(
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
  Future<List<ScriptBuild>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptBuildTable> where,
    _is.OrderByBuilder<ScriptBuildTable>? orderBy,
    _is.OrderByListBuilder<ScriptBuildTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ScriptBuild>(
      where: where(ScriptBuild.t),
      orderBy: orderBy?.call(ScriptBuild.t),
      orderByList: orderByList?.call(ScriptBuild.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ScriptBuildTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ScriptBuild>(
      where: where?.call(ScriptBuild.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ScriptBuild] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ScriptBuildTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ScriptBuild>(
      where: where(ScriptBuild.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ScriptBuildAttachRowRepository {
  const ScriptBuildAttachRowRepository._();

  /// Creates a relation between the given [ScriptBuild] and [RevFile]
  /// by setting the [ScriptBuild]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    ScriptBuild scriptBuild,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (scriptBuild.id == null) {
      throw ArgumentError.notNull('scriptBuild.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $scriptBuild = scriptBuild.copyWith(fileId: file.id);
    await session.db.updateRow<ScriptBuild>(
      $scriptBuild,
      columns: [ScriptBuild.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ScriptBuild] and [ScriptProject]
  /// by setting the [ScriptBuild]'s foreign key `projectId` to refer to the [ScriptProject].
  Future<void> project(
    _is.DatabaseSession session,
    ScriptBuild scriptBuild,
    _itmevo3z.ScriptProject project, {
    _is.Transaction? transaction,
  }) async {
    if (scriptBuild.id == null) {
      throw ArgumentError.notNull('scriptBuild.id');
    }
    if (project.id == null) {
      throw ArgumentError.notNull('project.id');
    }

    var $scriptBuild = scriptBuild.copyWith(projectId: project.id);
    await session.db.updateRow<ScriptBuild>(
      $scriptBuild,
      columns: [ScriptBuild.t.projectId],
      transaction: transaction,
    );
  }
}
