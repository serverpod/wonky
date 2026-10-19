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
import '../../../sheets/models/rows/sheet.dart' as _ij40k88n;

/// A pivot table; its output is computed locally, never stored as cells.
abstract class PivotTable
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  PivotTable._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.anchorRowId,
    required this.anchorColId,
    required this.sourceRangeJson,
    required this.specJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory PivotTable({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required _is.UuidValue anchorRowId,
    required _is.UuidValue anchorColId,
    required String sourceRangeJson,
    required String specJson,
    DateTime? createdAt,
  }) = _PivotTableImpl;

  factory PivotTable.fromJson(Map<String, dynamic> jsonSerialization) {
    return PivotTable(
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
      anchorRowId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['anchorRowId'],
      ),
      anchorColId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['anchorColId'],
      ),
      sourceRangeJson: jsonSerialization['sourceRangeJson'] as String,
      specJson: jsonSerialization['specJson'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = PivotTableTable();

  static const db = PivotTableRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  /// Sheet that displays the pivot.
  _ij40k88n.Sheet? sheet;

  _is.UuidValue anchorRowId;

  _is.UuidValue anchorColId;

  String sourceRangeJson;

  /// PivotSpec v1 (Sheets 07 §7.1).
  String specJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [PivotTable]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  PivotTable copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedPivotTable$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedPivotTable$sheet(),
    _is.UuidValue? anchorRowId,
    _is.UuidValue? anchorColId,
    String? sourceRangeJson,
    String? specJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PivotTable',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'anchorRowId': anchorRowId.toJson(),
      'anchorColId': anchorColId.toJson(),
      'sourceRangeJson': sourceRangeJson,
      'specJson': specJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static PivotTableInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return PivotTableInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static PivotTableIncludeList includeList({
    _is.WhereExpressionBuilder<PivotTableTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PivotTableTable>? orderBy,
    _is.OrderByListBuilder<PivotTableTable>? orderByList,
    PivotTableInclude? include,
  }) {
    return PivotTableIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PivotTable.t),
      orderByList: orderByList?.call(PivotTable.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedPivotTable$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedPivotTable$file();
}

class _UndefinedPivotTable$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedPivotTable$sheet();
}

class _PivotTableImpl extends PivotTable {
  _PivotTableImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required _is.UuidValue anchorRowId,
    required _is.UuidValue anchorColId,
    required String sourceRangeJson,
    required String specJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         anchorRowId: anchorRowId,
         anchorColId: anchorColId,
         sourceRangeJson: sourceRangeJson,
         specJson: specJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PivotTable]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  PivotTable copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedPivotTable$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedPivotTable$sheet(),
    _is.UuidValue? anchorRowId,
    _is.UuidValue? anchorColId,
    String? sourceRangeJson,
    String? specJson,
    DateTime? createdAt,
  }) {
    return PivotTable(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      anchorRowId: anchorRowId ?? this.anchorRowId,
      anchorColId: anchorColId ?? this.anchorColId,
      sourceRangeJson: sourceRangeJson ?? this.sourceRangeJson,
      specJson: specJson ?? this.specJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PivotTableUpdateTable extends _is.UpdateTable<PivotTableTable> {
  PivotTableUpdateTable(super.table);

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

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> anchorRowId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.anchorRowId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> anchorColId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.anchorColId,
    value,
  );

  _is.ColumnValue<String, String> sourceRangeJson(String value) =>
      _is.ColumnValue(
        table.sourceRangeJson,
        value,
      );

  _is.ColumnValue<String, String> specJson(String value) => _is.ColumnValue(
    table.specJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class PivotTableTable extends _is.Table<_is.UuidValue> {
  PivotTableTable({super.tableRelation}) : super(tableName: 'pivot_table') {
    updateTable = PivotTableUpdateTable(this);
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
    anchorRowId = _is.ColumnUuid(
      'anchorRowId',
      this,
    );
    anchorColId = _is.ColumnUuid(
      'anchorColId',
      this,
    );
    sourceRangeJson = _is.ColumnString(
      'sourceRangeJson',
      this,
    );
    specJson = _is.ColumnString(
      'specJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final PivotTableUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  /// Sheet that displays the pivot.
  _ij40k88n.SheetTable? _sheet;

  late final _is.ColumnUuid anchorRowId;

  late final _is.ColumnUuid anchorColId;

  late final _is.ColumnString sourceRangeJson;

  /// PivotSpec v1 (Sheets 07 §7.1).
  late final _is.ColumnString specJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: PivotTable.t.fileId,
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
      field: PivotTable.t.sheetId,
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
    anchorRowId,
    anchorColId,
    sourceRangeJson,
    specJson,
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

class PivotTableInclude extends _is.IncludeObject {
  PivotTableInclude._({
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
  _is.Table<_is.UuidValue> get table => PivotTable.t;
}

class PivotTableIncludeList extends _is.IncludeList {
  PivotTableIncludeList._({
    _is.WhereExpressionBuilder<PivotTableTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(PivotTable.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => PivotTable.t;
}

class PivotTableRepository {
  const PivotTableRepository._();

  final attachRow = const PivotTableAttachRowRepository._();

  /// Returns a list of [PivotTable]s matching the given query parameters.
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
  Future<List<PivotTable>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PivotTableTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PivotTableTable>? orderBy,
    _is.OrderByListBuilder<PivotTableTable>? orderByList,
    _is.Transaction? transaction,
    PivotTableInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<PivotTable>(
      where: where?.call(PivotTable.t),
      orderBy: orderBy?.call(PivotTable.t),
      orderByList: orderByList?.call(PivotTable.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [PivotTable]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `PivotTable.t`.
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
  _ida.Stream<List<PivotTable>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PivotTableTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PivotTableTable>? orderBy,
    _is.OrderByListBuilder<PivotTableTable>? orderByList,
    PivotTableInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<PivotTable>(
      where: where?.call(PivotTable.t),
      orderBy: orderBy?.call(PivotTable.t),
      orderByList: orderByList?.call(PivotTable.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [PivotTable] matching the given query parameters.
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
  Future<PivotTable?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PivotTableTable>? where,
    int? offset,
    _is.OrderByBuilder<PivotTableTable>? orderBy,
    _is.OrderByListBuilder<PivotTableTable>? orderByList,
    _is.Transaction? transaction,
    PivotTableInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<PivotTable>(
      where: where?.call(PivotTable.t),
      orderBy: orderBy?.call(PivotTable.t),
      orderByList: orderByList?.call(PivotTable.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [PivotTable] by its [id] or null if no such row exists.
  Future<PivotTable?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    PivotTableInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<PivotTable>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [PivotTable]s in the list and returns the inserted rows.
  ///
  /// The returned [PivotTable]s will have their `id` fields set.
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
  Future<List<PivotTable>> insert(
    _is.DatabaseSession session,
    List<PivotTable> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<PivotTable>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [PivotTable] and returns the inserted row.
  ///
  /// The returned [PivotTable] will have its `id` field set.
  Future<PivotTable> insertRow(
    _is.DatabaseSession session,
    PivotTable row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<PivotTable>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [PivotTable]s in the list and returns the resulting rows.
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
  /// The returned [PivotTable]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PivotTable>> upsert(
    _is.DatabaseSession session,
    List<PivotTable> rows, {
    required _is.ColumnSelections<PivotTableTable> conflictColumns,
    _is.ColumnSelections<PivotTableTable>? updateColumns,
    _is.WhereExpressionBuilder<PivotTableTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<PivotTable>(
      rows,
      conflictColumns: conflictColumns(PivotTable.t),
      updateColumns: updateColumns?.call(PivotTable.t),
      updateWhere: updateWhere?.call(PivotTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [PivotTable] and returns the resulting row.
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
  /// The returned [PivotTable] will have its `id` field set.
  Future<PivotTable?> upsertRow(
    _is.DatabaseSession session,
    PivotTable row, {
    required _is.ColumnSelections<PivotTableTable> conflictColumns,
    _is.ColumnSelections<PivotTableTable>? updateColumns,
    _is.WhereExpressionBuilder<PivotTableTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<PivotTable>(
      row,
      conflictColumns: conflictColumns(PivotTable.t),
      updateColumns: updateColumns?.call(PivotTable.t),
      updateWhere: updateWhere?.call(PivotTable.t),
      transaction: transaction,
    );
  }

  /// Updates all [PivotTable]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PivotTable>> update(
    _is.DatabaseSession session,
    List<PivotTable> rows, {
    _is.ColumnSelections<PivotTableTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<PivotTable>(
      rows,
      columns: columns?.call(PivotTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [PivotTable]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<PivotTable> updateRow(
    _is.DatabaseSession session,
    PivotTable row, {
    _is.ColumnSelections<PivotTableTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<PivotTable>(
      row,
      columns: columns?.call(PivotTable.t),
      transaction: transaction,
    );
  }

  /// Updates a single [PivotTable] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<PivotTable?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<PivotTableUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<PivotTable>(
      id,
      columnValues: columnValues(PivotTable.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [PivotTable]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<PivotTable>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<PivotTableUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<PivotTableTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<PivotTableTable>? orderBy,
    _is.OrderByListBuilder<PivotTableTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<PivotTable>(
      columnValues: columnValues(PivotTable.t.updateTable),
      where: where(PivotTable.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(PivotTable.t),
      orderByList: orderByList?.call(PivotTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [PivotTable]s in the list and returns the deleted rows.
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
  Future<List<PivotTable>> delete(
    _is.DatabaseSession session,
    List<PivotTable> rows, {
    _is.OrderByBuilder<PivotTableTable>? orderBy,
    _is.OrderByListBuilder<PivotTableTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<PivotTable>(
      rows,
      orderBy: orderBy?.call(PivotTable.t),
      orderByList: orderByList?.call(PivotTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [PivotTable].
  Future<PivotTable> deleteRow(
    _is.DatabaseSession session,
    PivotTable row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<PivotTable>(
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
  Future<List<PivotTable>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PivotTableTable> where,
    _is.OrderByBuilder<PivotTableTable>? orderBy,
    _is.OrderByListBuilder<PivotTableTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<PivotTable>(
      where: where(PivotTable.t),
      orderBy: orderBy?.call(PivotTable.t),
      orderByList: orderByList?.call(PivotTable.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<PivotTableTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<PivotTable>(
      where: where?.call(PivotTable.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [PivotTable] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<PivotTableTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<PivotTable>(
      where: where(PivotTable.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class PivotTableAttachRowRepository {
  const PivotTableAttachRowRepository._();

  /// Creates a relation between the given [PivotTable] and [RevFile]
  /// by setting the [PivotTable]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    PivotTable pivotTable,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (pivotTable.id == null) {
      throw ArgumentError.notNull('pivotTable.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $pivotTable = pivotTable.copyWith(fileId: file.id);
    await session.db.updateRow<PivotTable>(
      $pivotTable,
      columns: [PivotTable.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [PivotTable] and [Sheet]
  /// by setting the [PivotTable]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    PivotTable pivotTable,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (pivotTable.id == null) {
      throw ArgumentError.notNull('pivotTable.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $pivotTable = pivotTable.copyWith(sheetId: sheet.id);
    await session.db.updateRow<PivotTable>(
      $pivotTable,
      columns: [PivotTable.t.sheetId],
      transaction: transaction,
    );
  }
}
