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
import '../../../sheets/models/rows/enums/dimension.dart' as _iqedopzp;
import '../../../sheets/models/rows/sheet.dart' as _ij40k88n;

/// Row/column grouping (outline).
abstract class DimensionGroup
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  DimensionGroup._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.dimension,
    required this.startId,
    required this.endId,
    required this.depth,
    bool? collapsed,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       collapsed = collapsed ?? false,
       createdAt = createdAt ?? DateTime.now();

  factory DimensionGroup({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required _iqedopzp.Dimension dimension,
    required _is.UuidValue startId,
    required _is.UuidValue endId,
    required int depth,
    bool? collapsed,
    DateTime? createdAt,
  }) = _DimensionGroupImpl;

  factory DimensionGroup.fromJson(Map<String, dynamic> jsonSerialization) {
    return DimensionGroup(
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
      dimension: _iqedopzp.Dimension.fromJson(
        (jsonSerialization['dimension'] as String),
      ),
      startId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['startId'],
      ),
      endId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['endId']),
      depth: jsonSerialization['depth'] as int,
      collapsed: jsonSerialization['collapsed'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['collapsed']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = DimensionGroupTable();

  static const db = DimensionGroupRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  _iqedopzp.Dimension dimension;

  _is.UuidValue startId;

  _is.UuidValue endId;

  /// 1..8.
  int depth;

  bool collapsed;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [DimensionGroup]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DimensionGroup copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedDimensionGroup$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedDimensionGroup$sheet(),
    _iqedopzp.Dimension? dimension,
    _is.UuidValue? startId,
    _is.UuidValue? endId,
    int? depth,
    bool? collapsed,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DimensionGroup',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'dimension': dimension.toJson(),
      'startId': startId.toJson(),
      'endId': endId.toJson(),
      'depth': depth,
      'collapsed': collapsed,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DimensionGroupInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return DimensionGroupInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static DimensionGroupIncludeList includeList({
    _is.WhereExpressionBuilder<DimensionGroupTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DimensionGroupTable>? orderBy,
    _is.OrderByListBuilder<DimensionGroupTable>? orderByList,
    DimensionGroupInclude? include,
  }) {
    return DimensionGroupIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DimensionGroup.t),
      orderByList: orderByList?.call(DimensionGroup.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedDimensionGroup$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedDimensionGroup$file();
}

class _UndefinedDimensionGroup$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedDimensionGroup$sheet();
}

class _DimensionGroupImpl extends DimensionGroup {
  _DimensionGroupImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required _iqedopzp.Dimension dimension,
    required _is.UuidValue startId,
    required _is.UuidValue endId,
    required int depth,
    bool? collapsed,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         dimension: dimension,
         startId: startId,
         endId: endId,
         depth: depth,
         collapsed: collapsed,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DimensionGroup]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DimensionGroup copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedDimensionGroup$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedDimensionGroup$sheet(),
    _iqedopzp.Dimension? dimension,
    _is.UuidValue? startId,
    _is.UuidValue? endId,
    int? depth,
    bool? collapsed,
    DateTime? createdAt,
  }) {
    return DimensionGroup(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      dimension: dimension ?? this.dimension,
      startId: startId ?? this.startId,
      endId: endId ?? this.endId,
      depth: depth ?? this.depth,
      collapsed: collapsed ?? this.collapsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DimensionGroupUpdateTable extends _is.UpdateTable<DimensionGroupTable> {
  DimensionGroupUpdateTable(super.table);

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

  _is.ColumnValue<_iqedopzp.Dimension, _iqedopzp.Dimension> dimension(
    _iqedopzp.Dimension value,
  ) => _is.ColumnValue(
    table.dimension,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> startId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.startId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> endId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.endId,
        value,
      );

  _is.ColumnValue<int, int> depth(int value) => _is.ColumnValue(
    table.depth,
    value,
  );

  _is.ColumnValue<bool, bool> collapsed(bool value) => _is.ColumnValue(
    table.collapsed,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DimensionGroupTable extends _is.Table<_is.UuidValue> {
  DimensionGroupTable({super.tableRelation})
    : super(tableName: 'dimension_group') {
    updateTable = DimensionGroupUpdateTable(this);
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
    dimension = _is.ColumnEnum(
      'dimension',
      this,
      _is.EnumSerialization.byName,
    );
    startId = _is.ColumnUuid(
      'startId',
      this,
    );
    endId = _is.ColumnUuid(
      'endId',
      this,
    );
    depth = _is.ColumnInt(
      'depth',
      this,
    );
    collapsed = _is.ColumnBool(
      'collapsed',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DimensionGroupUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  late final _is.ColumnEnum<_iqedopzp.Dimension> dimension;

  late final _is.ColumnUuid startId;

  late final _is.ColumnUuid endId;

  /// 1..8.
  late final _is.ColumnInt depth;

  late final _is.ColumnBool collapsed;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: DimensionGroup.t.fileId,
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
      field: DimensionGroup.t.sheetId,
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
    dimension,
    startId,
    endId,
    depth,
    collapsed,
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

class DimensionGroupInclude extends _is.IncludeObject {
  DimensionGroupInclude._({
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
  _is.Table<_is.UuidValue> get table => DimensionGroup.t;
}

class DimensionGroupIncludeList extends _is.IncludeList {
  DimensionGroupIncludeList._({
    _is.WhereExpressionBuilder<DimensionGroupTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DimensionGroup.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => DimensionGroup.t;
}

class DimensionGroupRepository {
  const DimensionGroupRepository._();

  final attachRow = const DimensionGroupAttachRowRepository._();

  /// Returns a list of [DimensionGroup]s matching the given query parameters.
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
  Future<List<DimensionGroup>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DimensionGroupTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DimensionGroupTable>? orderBy,
    _is.OrderByListBuilder<DimensionGroupTable>? orderByList,
    _is.Transaction? transaction,
    DimensionGroupInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DimensionGroup>(
      where: where?.call(DimensionGroup.t),
      orderBy: orderBy?.call(DimensionGroup.t),
      orderByList: orderByList?.call(DimensionGroup.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DimensionGroup]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DimensionGroup.t`.
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
  _ida.Stream<List<DimensionGroup>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DimensionGroupTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DimensionGroupTable>? orderBy,
    _is.OrderByListBuilder<DimensionGroupTable>? orderByList,
    DimensionGroupInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DimensionGroup>(
      where: where?.call(DimensionGroup.t),
      orderBy: orderBy?.call(DimensionGroup.t),
      orderByList: orderByList?.call(DimensionGroup.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DimensionGroup] matching the given query parameters.
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
  Future<DimensionGroup?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DimensionGroupTable>? where,
    int? offset,
    _is.OrderByBuilder<DimensionGroupTable>? orderBy,
    _is.OrderByListBuilder<DimensionGroupTable>? orderByList,
    _is.Transaction? transaction,
    DimensionGroupInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DimensionGroup>(
      where: where?.call(DimensionGroup.t),
      orderBy: orderBy?.call(DimensionGroup.t),
      orderByList: orderByList?.call(DimensionGroup.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DimensionGroup] by its [id] or null if no such row exists.
  Future<DimensionGroup?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    DimensionGroupInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DimensionGroup>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DimensionGroup]s in the list and returns the inserted rows.
  ///
  /// The returned [DimensionGroup]s will have their `id` fields set.
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
  Future<List<DimensionGroup>> insert(
    _is.DatabaseSession session,
    List<DimensionGroup> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DimensionGroup>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DimensionGroup] and returns the inserted row.
  ///
  /// The returned [DimensionGroup] will have its `id` field set.
  Future<DimensionGroup> insertRow(
    _is.DatabaseSession session,
    DimensionGroup row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DimensionGroup>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DimensionGroup]s in the list and returns the resulting rows.
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
  /// The returned [DimensionGroup]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DimensionGroup>> upsert(
    _is.DatabaseSession session,
    List<DimensionGroup> rows, {
    required _is.ColumnSelections<DimensionGroupTable> conflictColumns,
    _is.ColumnSelections<DimensionGroupTable>? updateColumns,
    _is.WhereExpressionBuilder<DimensionGroupTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DimensionGroup>(
      rows,
      conflictColumns: conflictColumns(DimensionGroup.t),
      updateColumns: updateColumns?.call(DimensionGroup.t),
      updateWhere: updateWhere?.call(DimensionGroup.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DimensionGroup] and returns the resulting row.
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
  /// The returned [DimensionGroup] will have its `id` field set.
  Future<DimensionGroup?> upsertRow(
    _is.DatabaseSession session,
    DimensionGroup row, {
    required _is.ColumnSelections<DimensionGroupTable> conflictColumns,
    _is.ColumnSelections<DimensionGroupTable>? updateColumns,
    _is.WhereExpressionBuilder<DimensionGroupTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DimensionGroup>(
      row,
      conflictColumns: conflictColumns(DimensionGroup.t),
      updateColumns: updateColumns?.call(DimensionGroup.t),
      updateWhere: updateWhere?.call(DimensionGroup.t),
      transaction: transaction,
    );
  }

  /// Updates all [DimensionGroup]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DimensionGroup>> update(
    _is.DatabaseSession session,
    List<DimensionGroup> rows, {
    _is.ColumnSelections<DimensionGroupTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DimensionGroup>(
      rows,
      columns: columns?.call(DimensionGroup.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DimensionGroup]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DimensionGroup> updateRow(
    _is.DatabaseSession session,
    DimensionGroup row, {
    _is.ColumnSelections<DimensionGroupTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DimensionGroup>(
      row,
      columns: columns?.call(DimensionGroup.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DimensionGroup] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DimensionGroup?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<DimensionGroupUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DimensionGroup>(
      id,
      columnValues: columnValues(DimensionGroup.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DimensionGroup]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DimensionGroup>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DimensionGroupUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DimensionGroupTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DimensionGroupTable>? orderBy,
    _is.OrderByListBuilder<DimensionGroupTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DimensionGroup>(
      columnValues: columnValues(DimensionGroup.t.updateTable),
      where: where(DimensionGroup.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DimensionGroup.t),
      orderByList: orderByList?.call(DimensionGroup.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DimensionGroup]s in the list and returns the deleted rows.
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
  Future<List<DimensionGroup>> delete(
    _is.DatabaseSession session,
    List<DimensionGroup> rows, {
    _is.OrderByBuilder<DimensionGroupTable>? orderBy,
    _is.OrderByListBuilder<DimensionGroupTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DimensionGroup>(
      rows,
      orderBy: orderBy?.call(DimensionGroup.t),
      orderByList: orderByList?.call(DimensionGroup.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DimensionGroup].
  Future<DimensionGroup> deleteRow(
    _is.DatabaseSession session,
    DimensionGroup row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DimensionGroup>(
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
  Future<List<DimensionGroup>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DimensionGroupTable> where,
    _is.OrderByBuilder<DimensionGroupTable>? orderBy,
    _is.OrderByListBuilder<DimensionGroupTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DimensionGroup>(
      where: where(DimensionGroup.t),
      orderBy: orderBy?.call(DimensionGroup.t),
      orderByList: orderByList?.call(DimensionGroup.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DimensionGroupTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DimensionGroup>(
      where: where?.call(DimensionGroup.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DimensionGroup] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DimensionGroupTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DimensionGroup>(
      where: where(DimensionGroup.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class DimensionGroupAttachRowRepository {
  const DimensionGroupAttachRowRepository._();

  /// Creates a relation between the given [DimensionGroup] and [RevFile]
  /// by setting the [DimensionGroup]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    DimensionGroup dimensionGroup,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (dimensionGroup.id == null) {
      throw ArgumentError.notNull('dimensionGroup.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $dimensionGroup = dimensionGroup.copyWith(fileId: file.id);
    await session.db.updateRow<DimensionGroup>(
      $dimensionGroup,
      columns: [DimensionGroup.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [DimensionGroup] and [Sheet]
  /// by setting the [DimensionGroup]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    DimensionGroup dimensionGroup,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (dimensionGroup.id == null) {
      throw ArgumentError.notNull('dimensionGroup.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $dimensionGroup = dimensionGroup.copyWith(sheetId: sheet.id);
    await session.db.updateRow<DimensionGroup>(
      $dimensionGroup,
      columns: [DimensionGroup.t.sheetId],
      transaction: transaction,
    );
  }
}
