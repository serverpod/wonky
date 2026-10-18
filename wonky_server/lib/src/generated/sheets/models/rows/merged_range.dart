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

/// A merged block of cells.
abstract class MergedRange
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  MergedRange._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.rangeJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory MergedRange({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String rangeJson,
    DateTime? createdAt,
  }) = _MergedRangeImpl;

  factory MergedRange.fromJson(Map<String, dynamic> jsonSerialization) {
    return MergedRange(
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
      rangeJson: jsonSerialization['rangeJson'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = MergedRangeTable();

  static const db = MergedRangeRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  /// GridRange with all four bounds.
  String rangeJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [MergedRange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  MergedRange copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedMergedRange$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedMergedRange$sheet(),
    String? rangeJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MergedRange',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'rangeJson': rangeJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static MergedRangeInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return MergedRangeInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static MergedRangeIncludeList includeList({
    _is.WhereExpressionBuilder<MergedRangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MergedRangeTable>? orderBy,
    _is.OrderByListBuilder<MergedRangeTable>? orderByList,
    MergedRangeInclude? include,
  }) {
    return MergedRangeIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MergedRange.t),
      orderByList: orderByList?.call(MergedRange.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedMergedRange$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedMergedRange$file();
}

class _UndefinedMergedRange$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedMergedRange$sheet();
}

class _MergedRangeImpl extends MergedRange {
  _MergedRangeImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String rangeJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         rangeJson: rangeJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MergedRange]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  MergedRange copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedMergedRange$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedMergedRange$sheet(),
    String? rangeJson,
    DateTime? createdAt,
  }) {
    return MergedRange(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      rangeJson: rangeJson ?? this.rangeJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MergedRangeUpdateTable extends _is.UpdateTable<MergedRangeTable> {
  MergedRangeUpdateTable(super.table);

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

  _is.ColumnValue<String, String> rangeJson(String value) => _is.ColumnValue(
    table.rangeJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class MergedRangeTable extends _is.Table<_is.UuidValue> {
  MergedRangeTable({super.tableRelation}) : super(tableName: 'merged_range') {
    updateTable = MergedRangeUpdateTable(this);
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
    rangeJson = _is.ColumnString(
      'rangeJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final MergedRangeUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  /// GridRange with all four bounds.
  late final _is.ColumnString rangeJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: MergedRange.t.fileId,
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
      field: MergedRange.t.sheetId,
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
    rangeJson,
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

class MergedRangeInclude extends _is.IncludeObject {
  MergedRangeInclude._({
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
  _is.Table<_is.UuidValue> get table => MergedRange.t;
}

class MergedRangeIncludeList extends _is.IncludeList {
  MergedRangeIncludeList._({
    _is.WhereExpressionBuilder<MergedRangeTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MergedRange.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => MergedRange.t;
}

class MergedRangeRepository {
  const MergedRangeRepository._();

  final attachRow = const MergedRangeAttachRowRepository._();

  /// Returns a list of [MergedRange]s matching the given query parameters.
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
  Future<List<MergedRange>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MergedRangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MergedRangeTable>? orderBy,
    _is.OrderByListBuilder<MergedRangeTable>? orderByList,
    _is.Transaction? transaction,
    MergedRangeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<MergedRange>(
      where: where?.call(MergedRange.t),
      orderBy: orderBy?.call(MergedRange.t),
      orderByList: orderByList?.call(MergedRange.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [MergedRange]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `MergedRange.t`.
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
  _ida.Stream<List<MergedRange>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MergedRangeTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MergedRangeTable>? orderBy,
    _is.OrderByListBuilder<MergedRangeTable>? orderByList,
    MergedRangeInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<MergedRange>(
      where: where?.call(MergedRange.t),
      orderBy: orderBy?.call(MergedRange.t),
      orderByList: orderByList?.call(MergedRange.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [MergedRange] matching the given query parameters.
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
  Future<MergedRange?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MergedRangeTable>? where,
    int? offset,
    _is.OrderByBuilder<MergedRangeTable>? orderBy,
    _is.OrderByListBuilder<MergedRangeTable>? orderByList,
    _is.Transaction? transaction,
    MergedRangeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<MergedRange>(
      where: where?.call(MergedRange.t),
      orderBy: orderBy?.call(MergedRange.t),
      orderByList: orderByList?.call(MergedRange.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [MergedRange] by its [id] or null if no such row exists.
  Future<MergedRange?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    MergedRangeInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<MergedRange>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [MergedRange]s in the list and returns the inserted rows.
  ///
  /// The returned [MergedRange]s will have their `id` fields set.
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
  Future<List<MergedRange>> insert(
    _is.DatabaseSession session,
    List<MergedRange> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<MergedRange>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [MergedRange] and returns the inserted row.
  ///
  /// The returned [MergedRange] will have its `id` field set.
  Future<MergedRange> insertRow(
    _is.DatabaseSession session,
    MergedRange row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<MergedRange>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [MergedRange]s in the list and returns the resulting rows.
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
  /// The returned [MergedRange]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MergedRange>> upsert(
    _is.DatabaseSession session,
    List<MergedRange> rows, {
    required _is.ColumnSelections<MergedRangeTable> conflictColumns,
    _is.ColumnSelections<MergedRangeTable>? updateColumns,
    _is.WhereExpressionBuilder<MergedRangeTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<MergedRange>(
      rows,
      conflictColumns: conflictColumns(MergedRange.t),
      updateColumns: updateColumns?.call(MergedRange.t),
      updateWhere: updateWhere?.call(MergedRange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [MergedRange] and returns the resulting row.
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
  /// The returned [MergedRange] will have its `id` field set.
  Future<MergedRange?> upsertRow(
    _is.DatabaseSession session,
    MergedRange row, {
    required _is.ColumnSelections<MergedRangeTable> conflictColumns,
    _is.ColumnSelections<MergedRangeTable>? updateColumns,
    _is.WhereExpressionBuilder<MergedRangeTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<MergedRange>(
      row,
      conflictColumns: conflictColumns(MergedRange.t),
      updateColumns: updateColumns?.call(MergedRange.t),
      updateWhere: updateWhere?.call(MergedRange.t),
      transaction: transaction,
    );
  }

  /// Updates all [MergedRange]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MergedRange>> update(
    _is.DatabaseSession session,
    List<MergedRange> rows, {
    _is.ColumnSelections<MergedRangeTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<MergedRange>(
      rows,
      columns: columns?.call(MergedRange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [MergedRange]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MergedRange> updateRow(
    _is.DatabaseSession session,
    MergedRange row, {
    _is.ColumnSelections<MergedRangeTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<MergedRange>(
      row,
      columns: columns?.call(MergedRange.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MergedRange] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MergedRange?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<MergedRangeUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<MergedRange>(
      id,
      columnValues: columnValues(MergedRange.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MergedRange]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<MergedRange>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<MergedRangeUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<MergedRangeTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<MergedRangeTable>? orderBy,
    _is.OrderByListBuilder<MergedRangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<MergedRange>(
      columnValues: columnValues(MergedRange.t.updateTable),
      where: where(MergedRange.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MergedRange.t),
      orderByList: orderByList?.call(MergedRange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [MergedRange]s in the list and returns the deleted rows.
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
  Future<List<MergedRange>> delete(
    _is.DatabaseSession session,
    List<MergedRange> rows, {
    _is.OrderByBuilder<MergedRangeTable>? orderBy,
    _is.OrderByListBuilder<MergedRangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<MergedRange>(
      rows,
      orderBy: orderBy?.call(MergedRange.t),
      orderByList: orderByList?.call(MergedRange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [MergedRange].
  Future<MergedRange> deleteRow(
    _is.DatabaseSession session,
    MergedRange row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MergedRange>(
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
  Future<List<MergedRange>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MergedRangeTable> where,
    _is.OrderByBuilder<MergedRangeTable>? orderBy,
    _is.OrderByListBuilder<MergedRangeTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<MergedRange>(
      where: where(MergedRange.t),
      orderBy: orderBy?.call(MergedRange.t),
      orderByList: orderByList?.call(MergedRange.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<MergedRangeTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<MergedRange>(
      where: where?.call(MergedRange.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [MergedRange] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<MergedRangeTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<MergedRange>(
      where: where(MergedRange.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class MergedRangeAttachRowRepository {
  const MergedRangeAttachRowRepository._();

  /// Creates a relation between the given [MergedRange] and [RevFile]
  /// by setting the [MergedRange]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    MergedRange mergedRange,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (mergedRange.id == null) {
      throw ArgumentError.notNull('mergedRange.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $mergedRange = mergedRange.copyWith(fileId: file.id);
    await session.db.updateRow<MergedRange>(
      $mergedRange,
      columns: [MergedRange.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [MergedRange] and [Sheet]
  /// by setting the [MergedRange]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    MergedRange mergedRange,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (mergedRange.id == null) {
      throw ArgumentError.notNull('mergedRange.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $mergedRange = mergedRange.copyWith(sheetId: sheet.id);
    await session.db.updateRow<MergedRange>(
      $mergedRange,
      columns: [MergedRange.t.sheetId],
      transaction: transaction,
    );
  }
}
