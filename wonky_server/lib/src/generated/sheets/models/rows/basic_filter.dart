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

/// The basic filter of a sheet; id = SheetsIds.basicFilterId(sheetId).
abstract class BasicFilter
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  BasicFilter._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.rangeJson,
    required this.criteriaJson,
    this.sortJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory BasicFilter({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String rangeJson,
    required String criteriaJson,
    String? sortJson,
    DateTime? createdAt,
  }) = _BasicFilterImpl;

  factory BasicFilter.fromJson(Map<String, dynamic> jsonSerialization) {
    return BasicFilter(
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
      criteriaJson: jsonSerialization['criteriaJson'] as String,
      sortJson: jsonSerialization['sortJson'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = BasicFilterTable();

  static const db = BasicFilterRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  String rangeJson;

  /// {colId: criteria}.
  String criteriaJson;

  /// [{colId, ascending}].
  String? sortJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [BasicFilter]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BasicFilter copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedBasicFilter$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedBasicFilter$sheet(),
    String? rangeJson,
    String? criteriaJson,
    String? sortJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BasicFilter',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'rangeJson': rangeJson,
      'criteriaJson': criteriaJson,
      if (sortJson != null) 'sortJson': sortJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static BasicFilterInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return BasicFilterInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static BasicFilterIncludeList includeList({
    _is.WhereExpressionBuilder<BasicFilterTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BasicFilterTable>? orderBy,
    _is.OrderByListBuilder<BasicFilterTable>? orderByList,
    BasicFilterInclude? include,
  }) {
    return BasicFilterIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BasicFilter.t),
      orderByList: orderByList?.call(BasicFilter.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedBasicFilter$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedBasicFilter$file();
}

class _UndefinedBasicFilter$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedBasicFilter$sheet();
}

class _BasicFilterImpl extends BasicFilter {
  _BasicFilterImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String rangeJson,
    required String criteriaJson,
    String? sortJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         rangeJson: rangeJson,
         criteriaJson: criteriaJson,
         sortJson: sortJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [BasicFilter]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BasicFilter copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedBasicFilter$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedBasicFilter$sheet(),
    String? rangeJson,
    String? criteriaJson,
    Object? sortJson = _Undefined,
    DateTime? createdAt,
  }) {
    return BasicFilter(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      rangeJson: rangeJson ?? this.rangeJson,
      criteriaJson: criteriaJson ?? this.criteriaJson,
      sortJson: sortJson is String? ? sortJson : this.sortJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BasicFilterUpdateTable extends _is.UpdateTable<BasicFilterTable> {
  BasicFilterUpdateTable(super.table);

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

  _is.ColumnValue<String, String> criteriaJson(String value) => _is.ColumnValue(
    table.criteriaJson,
    value,
  );

  _is.ColumnValue<String, String> sortJson(String? value) => _is.ColumnValue(
    table.sortJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class BasicFilterTable extends _is.Table<_is.UuidValue> {
  BasicFilterTable({super.tableRelation}) : super(tableName: 'basic_filter') {
    updateTable = BasicFilterUpdateTable(this);
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
    criteriaJson = _is.ColumnString(
      'criteriaJson',
      this,
    );
    sortJson = _is.ColumnString(
      'sortJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final BasicFilterUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  late final _is.ColumnString rangeJson;

  /// {colId: criteria}.
  late final _is.ColumnString criteriaJson;

  /// [{colId, ascending}].
  late final _is.ColumnString sortJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: BasicFilter.t.fileId,
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
      field: BasicFilter.t.sheetId,
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
    criteriaJson,
    sortJson,
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

class BasicFilterInclude extends _is.IncludeObject {
  BasicFilterInclude._({
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
  _is.Table<_is.UuidValue> get table => BasicFilter.t;
}

class BasicFilterIncludeList extends _is.IncludeList {
  BasicFilterIncludeList._({
    _is.WhereExpressionBuilder<BasicFilterTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(BasicFilter.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => BasicFilter.t;
}

class BasicFilterRepository {
  const BasicFilterRepository._();

  final attachRow = const BasicFilterAttachRowRepository._();

  /// Returns a list of [BasicFilter]s matching the given query parameters.
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
  Future<List<BasicFilter>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BasicFilterTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BasicFilterTable>? orderBy,
    _is.OrderByListBuilder<BasicFilterTable>? orderByList,
    _is.Transaction? transaction,
    BasicFilterInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<BasicFilter>(
      where: where?.call(BasicFilter.t),
      orderBy: orderBy?.call(BasicFilter.t),
      orderByList: orderByList?.call(BasicFilter.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [BasicFilter]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `BasicFilter.t`.
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
  _ida.Stream<List<BasicFilter>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BasicFilterTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BasicFilterTable>? orderBy,
    _is.OrderByListBuilder<BasicFilterTable>? orderByList,
    BasicFilterInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<BasicFilter>(
      where: where?.call(BasicFilter.t),
      orderBy: orderBy?.call(BasicFilter.t),
      orderByList: orderByList?.call(BasicFilter.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [BasicFilter] matching the given query parameters.
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
  Future<BasicFilter?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BasicFilterTable>? where,
    int? offset,
    _is.OrderByBuilder<BasicFilterTable>? orderBy,
    _is.OrderByListBuilder<BasicFilterTable>? orderByList,
    _is.Transaction? transaction,
    BasicFilterInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<BasicFilter>(
      where: where?.call(BasicFilter.t),
      orderBy: orderBy?.call(BasicFilter.t),
      orderByList: orderByList?.call(BasicFilter.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [BasicFilter] by its [id] or null if no such row exists.
  Future<BasicFilter?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    BasicFilterInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<BasicFilter>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [BasicFilter]s in the list and returns the inserted rows.
  ///
  /// The returned [BasicFilter]s will have their `id` fields set.
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
  Future<List<BasicFilter>> insert(
    _is.DatabaseSession session,
    List<BasicFilter> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<BasicFilter>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [BasicFilter] and returns the inserted row.
  ///
  /// The returned [BasicFilter] will have its `id` field set.
  Future<BasicFilter> insertRow(
    _is.DatabaseSession session,
    BasicFilter row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<BasicFilter>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [BasicFilter]s in the list and returns the resulting rows.
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
  /// The returned [BasicFilter]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BasicFilter>> upsert(
    _is.DatabaseSession session,
    List<BasicFilter> rows, {
    required _is.ColumnSelections<BasicFilterTable> conflictColumns,
    _is.ColumnSelections<BasicFilterTable>? updateColumns,
    _is.WhereExpressionBuilder<BasicFilterTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<BasicFilter>(
      rows,
      conflictColumns: conflictColumns(BasicFilter.t),
      updateColumns: updateColumns?.call(BasicFilter.t),
      updateWhere: updateWhere?.call(BasicFilter.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [BasicFilter] and returns the resulting row.
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
  /// The returned [BasicFilter] will have its `id` field set.
  Future<BasicFilter?> upsertRow(
    _is.DatabaseSession session,
    BasicFilter row, {
    required _is.ColumnSelections<BasicFilterTable> conflictColumns,
    _is.ColumnSelections<BasicFilterTable>? updateColumns,
    _is.WhereExpressionBuilder<BasicFilterTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<BasicFilter>(
      row,
      conflictColumns: conflictColumns(BasicFilter.t),
      updateColumns: updateColumns?.call(BasicFilter.t),
      updateWhere: updateWhere?.call(BasicFilter.t),
      transaction: transaction,
    );
  }

  /// Updates all [BasicFilter]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BasicFilter>> update(
    _is.DatabaseSession session,
    List<BasicFilter> rows, {
    _is.ColumnSelections<BasicFilterTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<BasicFilter>(
      rows,
      columns: columns?.call(BasicFilter.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [BasicFilter]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<BasicFilter> updateRow(
    _is.DatabaseSession session,
    BasicFilter row, {
    _is.ColumnSelections<BasicFilterTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<BasicFilter>(
      row,
      columns: columns?.call(BasicFilter.t),
      transaction: transaction,
    );
  }

  /// Updates a single [BasicFilter] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<BasicFilter?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<BasicFilterUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<BasicFilter>(
      id,
      columnValues: columnValues(BasicFilter.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [BasicFilter]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<BasicFilter>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BasicFilterUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<BasicFilterTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BasicFilterTable>? orderBy,
    _is.OrderByListBuilder<BasicFilterTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<BasicFilter>(
      columnValues: columnValues(BasicFilter.t.updateTable),
      where: where(BasicFilter.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(BasicFilter.t),
      orderByList: orderByList?.call(BasicFilter.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [BasicFilter]s in the list and returns the deleted rows.
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
  Future<List<BasicFilter>> delete(
    _is.DatabaseSession session,
    List<BasicFilter> rows, {
    _is.OrderByBuilder<BasicFilterTable>? orderBy,
    _is.OrderByListBuilder<BasicFilterTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<BasicFilter>(
      rows,
      orderBy: orderBy?.call(BasicFilter.t),
      orderByList: orderByList?.call(BasicFilter.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [BasicFilter].
  Future<BasicFilter> deleteRow(
    _is.DatabaseSession session,
    BasicFilter row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<BasicFilter>(
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
  Future<List<BasicFilter>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BasicFilterTable> where,
    _is.OrderByBuilder<BasicFilterTable>? orderBy,
    _is.OrderByListBuilder<BasicFilterTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<BasicFilter>(
      where: where(BasicFilter.t),
      orderBy: orderBy?.call(BasicFilter.t),
      orderByList: orderByList?.call(BasicFilter.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BasicFilterTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<BasicFilter>(
      where: where?.call(BasicFilter.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [BasicFilter] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BasicFilterTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<BasicFilter>(
      where: where(BasicFilter.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class BasicFilterAttachRowRepository {
  const BasicFilterAttachRowRepository._();

  /// Creates a relation between the given [BasicFilter] and [RevFile]
  /// by setting the [BasicFilter]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    BasicFilter basicFilter,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (basicFilter.id == null) {
      throw ArgumentError.notNull('basicFilter.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $basicFilter = basicFilter.copyWith(fileId: file.id);
    await session.db.updateRow<BasicFilter>(
      $basicFilter,
      columns: [BasicFilter.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [BasicFilter] and [Sheet]
  /// by setting the [BasicFilter]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    BasicFilter basicFilter,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (basicFilter.id == null) {
      throw ArgumentError.notNull('basicFilter.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $basicFilter = basicFilter.copyWith(sheetId: sheet.id);
    await session.db.updateRow<BasicFilter>(
      $basicFilter,
      columns: [BasicFilter.t.sheetId],
      transaction: transaction,
    );
  }
}
