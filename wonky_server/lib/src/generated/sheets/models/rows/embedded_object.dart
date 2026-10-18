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
import '../../../sheets/models/rows/enums/embedded_object_kind.dart'
    as _ivwhse05;
import '../../../sheets/models/rows/sheet.dart' as _ij40k88n;

/// A chart, image or slicer floating over the grid (Sheets 08).
abstract class EmbeddedObject
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  EmbeddedObject._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.kind,
    required this.anchorJson,
    required this.specJson,
    int? zIndex,
    this.title,
    this.altText,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       zIndex = zIndex ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory EmbeddedObject({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required _ivwhse05.EmbeddedObjectKind kind,
    required String anchorJson,
    required String specJson,
    int? zIndex,
    String? title,
    String? altText,
    DateTime? createdAt,
  }) = _EmbeddedObjectImpl;

  factory EmbeddedObject.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmbeddedObject(
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
      sheetId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['sheetId'],
      ),
      sheet: jsonSerialization['sheet'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_ij40k88n.Sheet>(
              jsonSerialization['sheet'],
            ),
      kind: _ivwhse05.EmbeddedObjectKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      anchorJson: jsonSerialization['anchorJson'] as String,
      specJson: jsonSerialization['specJson'] as String,
      zIndex: jsonSerialization['zIndex'] as int?,
      title: jsonSerialization['title'] as String?,
      altText: jsonSerialization['altText'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = EmbeddedObjectTable();

  static const db = EmbeddedObjectRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  _ivwhse05.EmbeddedObjectKind kind;

  /// {v, rowId, colId, dx, dy, width, height, lockAspect} or {"ownSheet": true}.
  String anchorJson;

  /// ChartSpec / ImageSpec / SlicerSpec, always with "v".
  String specJson;

  int zIndex;

  String? title;

  String? altText;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [EmbeddedObject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  EmbeddedObject copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedEmbeddedObject$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedEmbeddedObject$sheet(),
    _ivwhse05.EmbeddedObjectKind? kind,
    String? anchorJson,
    String? specJson,
    int? zIndex,
    String? title,
    String? altText,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EmbeddedObject',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'kind': kind.toJson(),
      'anchorJson': anchorJson,
      'specJson': specJson,
      'zIndex': zIndex,
      if (title != null) 'title': title,
      if (altText != null) 'altText': altText,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static EmbeddedObjectInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return EmbeddedObjectInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static EmbeddedObjectIncludeList includeList({
    _is.WhereExpressionBuilder<EmbeddedObjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EmbeddedObjectTable>? orderBy,
    _is.OrderByListBuilder<EmbeddedObjectTable>? orderByList,
    EmbeddedObjectInclude? include,
  }) {
    return EmbeddedObjectIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EmbeddedObject.t),
      orderByList: orderByList?.call(EmbeddedObject.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedEmbeddedObject$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedEmbeddedObject$file();
}

class _UndefinedEmbeddedObject$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedEmbeddedObject$sheet();
}

class _EmbeddedObjectImpl extends EmbeddedObject {
  _EmbeddedObjectImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required _ivwhse05.EmbeddedObjectKind kind,
    required String anchorJson,
    required String specJson,
    int? zIndex,
    String? title,
    String? altText,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         kind: kind,
         anchorJson: anchorJson,
         specJson: specJson,
         zIndex: zIndex,
         title: title,
         altText: altText,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [EmbeddedObject]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  EmbeddedObject copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedEmbeddedObject$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedEmbeddedObject$sheet(),
    _ivwhse05.EmbeddedObjectKind? kind,
    String? anchorJson,
    String? specJson,
    int? zIndex,
    Object? title = _Undefined,
    Object? altText = _Undefined,
    DateTime? createdAt,
  }) {
    return EmbeddedObject(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      kind: kind ?? this.kind,
      anchorJson: anchorJson ?? this.anchorJson,
      specJson: specJson ?? this.specJson,
      zIndex: zIndex ?? this.zIndex,
      title: title is String? ? title : this.title,
      altText: altText is String? ? altText : this.altText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class EmbeddedObjectUpdateTable extends _is.UpdateTable<EmbeddedObjectTable> {
  EmbeddedObjectUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> sheetId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.sheetId,
        value,
      );

  _is.ColumnValue<_ivwhse05.EmbeddedObjectKind, _ivwhse05.EmbeddedObjectKind>
  kind(_ivwhse05.EmbeddedObjectKind value) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<String, String> anchorJson(String value) => _is.ColumnValue(
    table.anchorJson,
    value,
  );

  _is.ColumnValue<String, String> specJson(String value) => _is.ColumnValue(
    table.specJson,
    value,
  );

  _is.ColumnValue<int, int> zIndex(int value) => _is.ColumnValue(
    table.zIndex,
    value,
  );

  _is.ColumnValue<String, String> title(String? value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> altText(String? value) => _is.ColumnValue(
    table.altText,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class EmbeddedObjectTable extends _is.Table<_is.UuidValue> {
  EmbeddedObjectTable({super.tableRelation})
    : super(tableName: 'embedded_object') {
    updateTable = EmbeddedObjectUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    sheetId = _is.ColumnUuid(
      'sheetId',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
    );
    anchorJson = _is.ColumnString(
      'anchorJson',
      this,
    );
    specJson = _is.ColumnString(
      'specJson',
      this,
    );
    zIndex = _is.ColumnInt(
      'zIndex',
      this,
      hasDefault: true,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    altText = _is.ColumnString(
      'altText',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final EmbeddedObjectUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  late final _is.ColumnEnum<_ivwhse05.EmbeddedObjectKind> kind;

  /// {v, rowId, colId, dx, dy, width, height, lockAspect} or {"ownSheet": true}.
  late final _is.ColumnString anchorJson;

  /// ChartSpec / ImageSpec / SlicerSpec, always with "v".
  late final _is.ColumnString specJson;

  late final _is.ColumnInt zIndex;

  late final _is.ColumnString title;

  late final _is.ColumnString altText;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: EmbeddedObject.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _ij40k88n.SheetTable get sheet {
    if (_sheet != null) return _sheet!;
    _sheet = _is.createRelationTable(
      relationFieldName: 'sheet',
      field: EmbeddedObject.t.sheetId,
      foreignField: _ij40k88n.Sheet.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ij40k88n.SheetTable(tableRelation: foreignTableRelation),
    );
    return _sheet!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    sheetId,
    kind,
    anchorJson,
    specJson,
    zIndex,
    title,
    altText,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'sheet') {
      return sheet;
    }
    return null;
  }
}

class EmbeddedObjectInclude extends _is.IncludeObject {
  EmbeddedObjectInclude._({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    _file = file;
    _sheet = sheet;
  }

  _imcki4bb.RevFileInclude? _file;

  _ij40k88n.SheetInclude? _sheet;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'sheet': _sheet,
  };

  @override
  _is.Table<_is.UuidValue> get table => EmbeddedObject.t;
}

class EmbeddedObjectIncludeList extends _is.IncludeList {
  EmbeddedObjectIncludeList._({
    _is.WhereExpressionBuilder<EmbeddedObjectTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EmbeddedObject.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => EmbeddedObject.t;
}

class EmbeddedObjectRepository {
  const EmbeddedObjectRepository._();

  final attachRow = const EmbeddedObjectAttachRowRepository._();

  /// Returns a list of [EmbeddedObject]s matching the given query parameters.
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
  Future<List<EmbeddedObject>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EmbeddedObjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EmbeddedObjectTable>? orderBy,
    _is.OrderByListBuilder<EmbeddedObjectTable>? orderByList,
    _is.Transaction? transaction,
    EmbeddedObjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EmbeddedObject>(
      where: where?.call(EmbeddedObject.t),
      orderBy: orderBy?.call(EmbeddedObject.t),
      orderByList: orderByList?.call(EmbeddedObject.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [EmbeddedObject]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `EmbeddedObject.t`.
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
  _ida.Stream<List<EmbeddedObject>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EmbeddedObjectTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EmbeddedObjectTable>? orderBy,
    _is.OrderByListBuilder<EmbeddedObjectTable>? orderByList,
    EmbeddedObjectInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<EmbeddedObject>(
      where: where?.call(EmbeddedObject.t),
      orderBy: orderBy?.call(EmbeddedObject.t),
      orderByList: orderByList?.call(EmbeddedObject.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [EmbeddedObject] matching the given query parameters.
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
  Future<EmbeddedObject?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EmbeddedObjectTable>? where,
    int? offset,
    _is.OrderByBuilder<EmbeddedObjectTable>? orderBy,
    _is.OrderByListBuilder<EmbeddedObjectTable>? orderByList,
    _is.Transaction? transaction,
    EmbeddedObjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EmbeddedObject>(
      where: where?.call(EmbeddedObject.t),
      orderBy: orderBy?.call(EmbeddedObject.t),
      orderByList: orderByList?.call(EmbeddedObject.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EmbeddedObject] by its [id] or null if no such row exists.
  Future<EmbeddedObject?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    EmbeddedObjectInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EmbeddedObject>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EmbeddedObject]s in the list and returns the inserted rows.
  ///
  /// The returned [EmbeddedObject]s will have their `id` fields set.
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
  Future<List<EmbeddedObject>> insert(
    _is.DatabaseSession session,
    List<EmbeddedObject> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<EmbeddedObject>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [EmbeddedObject] and returns the inserted row.
  ///
  /// The returned [EmbeddedObject] will have its `id` field set.
  Future<EmbeddedObject> insertRow(
    _is.DatabaseSession session,
    EmbeddedObject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<EmbeddedObject>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [EmbeddedObject]s in the list and returns the resulting rows.
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
  /// The returned [EmbeddedObject]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EmbeddedObject>> upsert(
    _is.DatabaseSession session,
    List<EmbeddedObject> rows, {
    required _is.ColumnSelections<EmbeddedObjectTable> conflictColumns,
    _is.ColumnSelections<EmbeddedObjectTable>? updateColumns,
    _is.WhereExpressionBuilder<EmbeddedObjectTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<EmbeddedObject>(
      rows,
      conflictColumns: conflictColumns(EmbeddedObject.t),
      updateColumns: updateColumns?.call(EmbeddedObject.t),
      updateWhere: updateWhere?.call(EmbeddedObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [EmbeddedObject] and returns the resulting row.
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
  /// The returned [EmbeddedObject] will have its `id` field set.
  Future<EmbeddedObject?> upsertRow(
    _is.DatabaseSession session,
    EmbeddedObject row, {
    required _is.ColumnSelections<EmbeddedObjectTable> conflictColumns,
    _is.ColumnSelections<EmbeddedObjectTable>? updateColumns,
    _is.WhereExpressionBuilder<EmbeddedObjectTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<EmbeddedObject>(
      row,
      conflictColumns: conflictColumns(EmbeddedObject.t),
      updateColumns: updateColumns?.call(EmbeddedObject.t),
      updateWhere: updateWhere?.call(EmbeddedObject.t),
      transaction: transaction,
    );
  }

  /// Updates all [EmbeddedObject]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EmbeddedObject>> update(
    _is.DatabaseSession session,
    List<EmbeddedObject> rows, {
    _is.ColumnSelections<EmbeddedObjectTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<EmbeddedObject>(
      rows,
      columns: columns?.call(EmbeddedObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [EmbeddedObject]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EmbeddedObject> updateRow(
    _is.DatabaseSession session,
    EmbeddedObject row, {
    _is.ColumnSelections<EmbeddedObjectTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<EmbeddedObject>(
      row,
      columns: columns?.call(EmbeddedObject.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EmbeddedObject] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EmbeddedObject?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<EmbeddedObjectUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<EmbeddedObject>(
      id,
      columnValues: columnValues(EmbeddedObject.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EmbeddedObject]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<EmbeddedObject>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<EmbeddedObjectUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<EmbeddedObjectTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<EmbeddedObjectTable>? orderBy,
    _is.OrderByListBuilder<EmbeddedObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<EmbeddedObject>(
      columnValues: columnValues(EmbeddedObject.t.updateTable),
      where: where(EmbeddedObject.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EmbeddedObject.t),
      orderByList: orderByList?.call(EmbeddedObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [EmbeddedObject]s in the list and returns the deleted rows.
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
  Future<List<EmbeddedObject>> delete(
    _is.DatabaseSession session,
    List<EmbeddedObject> rows, {
    _is.OrderByBuilder<EmbeddedObjectTable>? orderBy,
    _is.OrderByListBuilder<EmbeddedObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<EmbeddedObject>(
      rows,
      orderBy: orderBy?.call(EmbeddedObject.t),
      orderByList: orderByList?.call(EmbeddedObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [EmbeddedObject].
  Future<EmbeddedObject> deleteRow(
    _is.DatabaseSession session,
    EmbeddedObject row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EmbeddedObject>(
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
  Future<List<EmbeddedObject>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EmbeddedObjectTable> where,
    _is.OrderByBuilder<EmbeddedObjectTable>? orderBy,
    _is.OrderByListBuilder<EmbeddedObjectTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<EmbeddedObject>(
      where: where(EmbeddedObject.t),
      orderBy: orderBy?.call(EmbeddedObject.t),
      orderByList: orderByList?.call(EmbeddedObject.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<EmbeddedObjectTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<EmbeddedObject>(
      where: where?.call(EmbeddedObject.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EmbeddedObject] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<EmbeddedObjectTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EmbeddedObject>(
      where: where(EmbeddedObject.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class EmbeddedObjectAttachRowRepository {
  const EmbeddedObjectAttachRowRepository._();

  /// Creates a relation between the given [EmbeddedObject] and [RevFile]
  /// by setting the [EmbeddedObject]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    EmbeddedObject embeddedObject,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (embeddedObject.id == null) {
      throw ArgumentError.notNull('embeddedObject.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $embeddedObject = embeddedObject.copyWith(fileId: file.id);
    await session.db.updateRow<EmbeddedObject>(
      $embeddedObject,
      columns: [EmbeddedObject.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [EmbeddedObject] and [Sheet]
  /// by setting the [EmbeddedObject]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    EmbeddedObject embeddedObject,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (embeddedObject.id == null) {
      throw ArgumentError.notNull('embeddedObject.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $embeddedObject = embeddedObject.copyWith(sheetId: sheet.id);
    await session.db.updateRow<EmbeddedObject>(
      $embeddedObject,
      columns: [EmbeddedObject.t.sheetId],
      transaction: transaction,
    );
  }
}
