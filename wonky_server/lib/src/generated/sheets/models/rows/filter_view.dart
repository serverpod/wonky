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

/// A saved, named filter view.
abstract class FilterView
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  FilterView._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.name,
    required this.rangeJson,
    required this.criteriaJson,
    this.sortJson,
    required this.createdBy,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory FilterView({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String name,
    required String rangeJson,
    required String criteriaJson,
    String? sortJson,
    required _is.UuidValue createdBy,
    DateTime? createdAt,
  }) = _FilterViewImpl;

  factory FilterView.fromJson(Map<String, dynamic> jsonSerialization) {
    return FilterView(
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
      name: jsonSerialization['name'] as String,
      rangeJson: jsonSerialization['rangeJson'] as String,
      criteriaJson: jsonSerialization['criteriaJson'] as String,
      sortJson: jsonSerialization['sortJson'] as String?,
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = FilterViewTable();

  static const db = FilterViewRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  String name;

  String rangeJson;

  String criteriaJson;

  String? sortJson;

  _is.UuidValue createdBy;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [FilterView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  FilterView copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedFilterView$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedFilterView$sheet(),
    String? name,
    String? rangeJson,
    String? criteriaJson,
    String? sortJson,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FilterView',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'name': name,
      'rangeJson': rangeJson,
      'criteriaJson': criteriaJson,
      if (sortJson != null) 'sortJson': sortJson,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static FilterViewInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return FilterViewInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static FilterViewIncludeList includeList({
    _is.WhereExpressionBuilder<FilterViewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FilterViewTable>? orderBy,
    _is.OrderByListBuilder<FilterViewTable>? orderByList,
    FilterViewInclude? include,
  }) {
    return FilterViewIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FilterView.t),
      orderByList: orderByList?.call(FilterView.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedFilterView$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedFilterView$file();
}

class _UndefinedFilterView$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedFilterView$sheet();
}

class _FilterViewImpl extends FilterView {
  _FilterViewImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String name,
    required String rangeJson,
    required String criteriaJson,
    String? sortJson,
    required _is.UuidValue createdBy,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         name: name,
         rangeJson: rangeJson,
         criteriaJson: criteriaJson,
         sortJson: sortJson,
         createdBy: createdBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [FilterView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  FilterView copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedFilterView$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedFilterView$sheet(),
    String? name,
    String? rangeJson,
    String? criteriaJson,
    Object? sortJson = _Undefined,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
  }) {
    return FilterView(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      name: name ?? this.name,
      rangeJson: rangeJson ?? this.rangeJson,
      criteriaJson: criteriaJson ?? this.criteriaJson,
      sortJson: sortJson is String? ? sortJson : this.sortJson,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FilterViewUpdateTable extends _is.UpdateTable<FilterViewTable> {
  FilterViewUpdateTable(super.table);

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

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
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

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> createdBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.createdBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class FilterViewTable extends _is.Table<_is.UuidValue> {
  FilterViewTable({super.tableRelation}) : super(tableName: 'filter_view') {
    updateTable = FilterViewUpdateTable(this);
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
    name = _is.ColumnString(
      'name',
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
    createdBy = _is.ColumnUuid(
      'createdBy',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final FilterViewUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  late final _is.ColumnString name;

  late final _is.ColumnString rangeJson;

  late final _is.ColumnString criteriaJson;

  late final _is.ColumnString sortJson;

  late final _is.ColumnUuid createdBy;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: FilterView.t.fileId,
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
      field: FilterView.t.sheetId,
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
    name,
    rangeJson,
    criteriaJson,
    sortJson,
    createdBy,
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

class FilterViewInclude extends _is.IncludeObject {
  FilterViewInclude._({
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
  _is.Table<_is.UuidValue> get table => FilterView.t;
}

class FilterViewIncludeList extends _is.IncludeList {
  FilterViewIncludeList._({
    _is.WhereExpressionBuilder<FilterViewTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FilterView.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => FilterView.t;
}

class FilterViewRepository {
  const FilterViewRepository._();

  final attachRow = const FilterViewAttachRowRepository._();

  /// Returns a list of [FilterView]s matching the given query parameters.
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
  Future<List<FilterView>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FilterViewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FilterViewTable>? orderBy,
    _is.OrderByListBuilder<FilterViewTable>? orderByList,
    _is.Transaction? transaction,
    FilterViewInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<FilterView>(
      where: where?.call(FilterView.t),
      orderBy: orderBy?.call(FilterView.t),
      orderByList: orderByList?.call(FilterView.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [FilterView]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `FilterView.t`.
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
  _ida.Stream<List<FilterView>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FilterViewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FilterViewTable>? orderBy,
    _is.OrderByListBuilder<FilterViewTable>? orderByList,
    FilterViewInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<FilterView>(
      where: where?.call(FilterView.t),
      orderBy: orderBy?.call(FilterView.t),
      orderByList: orderByList?.call(FilterView.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [FilterView] matching the given query parameters.
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
  Future<FilterView?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FilterViewTable>? where,
    int? offset,
    _is.OrderByBuilder<FilterViewTable>? orderBy,
    _is.OrderByListBuilder<FilterViewTable>? orderByList,
    _is.Transaction? transaction,
    FilterViewInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<FilterView>(
      where: where?.call(FilterView.t),
      orderBy: orderBy?.call(FilterView.t),
      orderByList: orderByList?.call(FilterView.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [FilterView] by its [id] or null if no such row exists.
  Future<FilterView?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    FilterViewInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<FilterView>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [FilterView]s in the list and returns the inserted rows.
  ///
  /// The returned [FilterView]s will have their `id` fields set.
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
  Future<List<FilterView>> insert(
    _is.DatabaseSession session,
    List<FilterView> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<FilterView>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [FilterView] and returns the inserted row.
  ///
  /// The returned [FilterView] will have its `id` field set.
  Future<FilterView> insertRow(
    _is.DatabaseSession session,
    FilterView row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<FilterView>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [FilterView]s in the list and returns the resulting rows.
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
  /// The returned [FilterView]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FilterView>> upsert(
    _is.DatabaseSession session,
    List<FilterView> rows, {
    required _is.ColumnSelections<FilterViewTable> conflictColumns,
    _is.ColumnSelections<FilterViewTable>? updateColumns,
    _is.WhereExpressionBuilder<FilterViewTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<FilterView>(
      rows,
      conflictColumns: conflictColumns(FilterView.t),
      updateColumns: updateColumns?.call(FilterView.t),
      updateWhere: updateWhere?.call(FilterView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [FilterView] and returns the resulting row.
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
  /// The returned [FilterView] will have its `id` field set.
  Future<FilterView?> upsertRow(
    _is.DatabaseSession session,
    FilterView row, {
    required _is.ColumnSelections<FilterViewTable> conflictColumns,
    _is.ColumnSelections<FilterViewTable>? updateColumns,
    _is.WhereExpressionBuilder<FilterViewTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<FilterView>(
      row,
      conflictColumns: conflictColumns(FilterView.t),
      updateColumns: updateColumns?.call(FilterView.t),
      updateWhere: updateWhere?.call(FilterView.t),
      transaction: transaction,
    );
  }

  /// Updates all [FilterView]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FilterView>> update(
    _is.DatabaseSession session,
    List<FilterView> rows, {
    _is.ColumnSelections<FilterViewTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<FilterView>(
      rows,
      columns: columns?.call(FilterView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [FilterView]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FilterView> updateRow(
    _is.DatabaseSession session,
    FilterView row, {
    _is.ColumnSelections<FilterViewTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<FilterView>(
      row,
      columns: columns?.call(FilterView.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FilterView] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FilterView?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<FilterViewUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<FilterView>(
      id,
      columnValues: columnValues(FilterView.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FilterView]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<FilterView>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<FilterViewUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<FilterViewTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<FilterViewTable>? orderBy,
    _is.OrderByListBuilder<FilterViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<FilterView>(
      columnValues: columnValues(FilterView.t.updateTable),
      where: where(FilterView.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FilterView.t),
      orderByList: orderByList?.call(FilterView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [FilterView]s in the list and returns the deleted rows.
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
  Future<List<FilterView>> delete(
    _is.DatabaseSession session,
    List<FilterView> rows, {
    _is.OrderByBuilder<FilterViewTable>? orderBy,
    _is.OrderByListBuilder<FilterViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<FilterView>(
      rows,
      orderBy: orderBy?.call(FilterView.t),
      orderByList: orderByList?.call(FilterView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [FilterView].
  Future<FilterView> deleteRow(
    _is.DatabaseSession session,
    FilterView row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FilterView>(
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
  Future<List<FilterView>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FilterViewTable> where,
    _is.OrderByBuilder<FilterViewTable>? orderBy,
    _is.OrderByListBuilder<FilterViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<FilterView>(
      where: where(FilterView.t),
      orderBy: orderBy?.call(FilterView.t),
      orderByList: orderByList?.call(FilterView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<FilterViewTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<FilterView>(
      where: where?.call(FilterView.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [FilterView] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<FilterViewTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<FilterView>(
      where: where(FilterView.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class FilterViewAttachRowRepository {
  const FilterViewAttachRowRepository._();

  /// Creates a relation between the given [FilterView] and [RevFile]
  /// by setting the [FilterView]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    FilterView filterView,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (filterView.id == null) {
      throw ArgumentError.notNull('filterView.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $filterView = filterView.copyWith(fileId: file.id);
    await session.db.updateRow<FilterView>(
      $filterView,
      columns: [FilterView.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [FilterView] and [Sheet]
  /// by setting the [FilterView]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    FilterView filterView,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (filterView.id == null) {
      throw ArgumentError.notNull('filterView.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $filterView = filterView.copyWith(sheetId: sheet.id);
    await session.db.updateRow<FilterView>(
      $filterView,
      columns: [FilterView.t.sheetId],
      transaction: transaction,
    );
  }
}
