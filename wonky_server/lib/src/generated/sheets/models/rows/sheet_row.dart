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

/// A row entity with a stable id, ordered by sortKey (Sheets 02 §3.2).
abstract class SheetRow
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  SheetRow._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.sortKey,
    this.height,
    bool? hidden,
    this.formatJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       hidden = hidden ?? false,
       createdAt = createdAt ?? DateTime.now();

  factory SheetRow({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String sortKey,
    double? height,
    bool? hidden,
    String? formatJson,
    DateTime? createdAt,
  }) = _SheetRowImpl;

  factory SheetRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return SheetRow(
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
      sortKey: jsonSerialization['sortKey'] as String,
      height: (jsonSerialization['height'] as num?)?.toDouble(),
      hidden: jsonSerialization['hidden'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['hidden']),
      formatJson: jsonSerialization['formatJson'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = SheetRowTable();

  static const db = SheetRowRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  String sortKey;

  /// Null = default/auto-fit.
  double? height;

  /// User-hidden; filter-hidden is computed.
  bool hidden;

  /// Row default format.
  String? formatJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [SheetRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SheetRow copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSheetRow$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedSheetRow$sheet(),
    String? sortKey,
    double? height,
    bool? hidden,
    String? formatJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SheetRow',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'sortKey': sortKey,
      if (height != null) 'height': height,
      'hidden': hidden,
      if (formatJson != null) 'formatJson': formatJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SheetRowInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return SheetRowInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static SheetRowIncludeList includeList({
    _is.WhereExpressionBuilder<SheetRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SheetRowTable>? orderBy,
    _is.OrderByListBuilder<SheetRowTable>? orderByList,
    SheetRowInclude? include,
  }) {
    return SheetRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SheetRow.t),
      orderByList: orderByList?.call(SheetRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedSheetRow$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedSheetRow$file();
}

class _UndefinedSheetRow$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedSheetRow$sheet();
}

class _SheetRowImpl extends SheetRow {
  _SheetRowImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String sortKey,
    double? height,
    bool? hidden,
    String? formatJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         sortKey: sortKey,
         height: height,
         hidden: hidden,
         formatJson: formatJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SheetRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SheetRow copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSheetRow$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedSheetRow$sheet(),
    String? sortKey,
    Object? height = _Undefined,
    bool? hidden,
    Object? formatJson = _Undefined,
    DateTime? createdAt,
  }) {
    return SheetRow(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      sortKey: sortKey ?? this.sortKey,
      height: height is double? ? height : this.height,
      hidden: hidden ?? this.hidden,
      formatJson: formatJson is String? ? formatJson : this.formatJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SheetRowUpdateTable extends _is.UpdateTable<SheetRowTable> {
  SheetRowUpdateTable(super.table);

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

  _is.ColumnValue<String, String> sortKey(String value) => _is.ColumnValue(
    table.sortKey,
    value,
  );

  _is.ColumnValue<double, double> height(double? value) => _is.ColumnValue(
    table.height,
    value,
  );

  _is.ColumnValue<bool, bool> hidden(bool value) => _is.ColumnValue(
    table.hidden,
    value,
  );

  _is.ColumnValue<String, String> formatJson(String? value) => _is.ColumnValue(
    table.formatJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class SheetRowTable extends _is.Table<_is.UuidValue> {
  SheetRowTable({super.tableRelation}) : super(tableName: 'sheet_row') {
    updateTable = SheetRowUpdateTable(this);
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
    sortKey = _is.ColumnString(
      'sortKey',
      this,
    );
    height = _is.ColumnDouble(
      'height',
      this,
    );
    hidden = _is.ColumnBool(
      'hidden',
      this,
      hasDefault: true,
    );
    formatJson = _is.ColumnString(
      'formatJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final SheetRowUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  late final _is.ColumnString sortKey;

  /// Null = default/auto-fit.
  late final _is.ColumnDouble height;

  /// User-hidden; filter-hidden is computed.
  late final _is.ColumnBool hidden;

  /// Row default format.
  late final _is.ColumnString formatJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: SheetRow.t.fileId,
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
      field: SheetRow.t.sheetId,
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
    sortKey,
    height,
    hidden,
    formatJson,
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

class SheetRowInclude extends _is.IncludeObject {
  SheetRowInclude._({
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
  _is.Table<_is.UuidValue> get table => SheetRow.t;
}

class SheetRowIncludeList extends _is.IncludeList {
  SheetRowIncludeList._({
    _is.WhereExpressionBuilder<SheetRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SheetRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => SheetRow.t;
}

class SheetRowRepository {
  const SheetRowRepository._();

  final attachRow = const SheetRowAttachRowRepository._();

  /// Returns a list of [SheetRow]s matching the given query parameters.
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
  Future<List<SheetRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SheetRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SheetRowTable>? orderBy,
    _is.OrderByListBuilder<SheetRowTable>? orderByList,
    _is.Transaction? transaction,
    SheetRowInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SheetRow>(
      where: where?.call(SheetRow.t),
      orderBy: orderBy?.call(SheetRow.t),
      orderByList: orderByList?.call(SheetRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [SheetRow]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `SheetRow.t`.
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
  _ida.Stream<List<SheetRow>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SheetRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SheetRowTable>? orderBy,
    _is.OrderByListBuilder<SheetRowTable>? orderByList,
    SheetRowInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<SheetRow>(
      where: where?.call(SheetRow.t),
      orderBy: orderBy?.call(SheetRow.t),
      orderByList: orderByList?.call(SheetRow.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [SheetRow] matching the given query parameters.
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
  Future<SheetRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SheetRowTable>? where,
    int? offset,
    _is.OrderByBuilder<SheetRowTable>? orderBy,
    _is.OrderByListBuilder<SheetRowTable>? orderByList,
    _is.Transaction? transaction,
    SheetRowInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SheetRow>(
      where: where?.call(SheetRow.t),
      orderBy: orderBy?.call(SheetRow.t),
      orderByList: orderByList?.call(SheetRow.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SheetRow] by its [id] or null if no such row exists.
  Future<SheetRow?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    SheetRowInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SheetRow>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SheetRow]s in the list and returns the inserted rows.
  ///
  /// The returned [SheetRow]s will have their `id` fields set.
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
  Future<List<SheetRow>> insert(
    _is.DatabaseSession session,
    List<SheetRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SheetRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SheetRow] and returns the inserted row.
  ///
  /// The returned [SheetRow] will have its `id` field set.
  Future<SheetRow> insertRow(
    _is.DatabaseSession session,
    SheetRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SheetRow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SheetRow]s in the list and returns the resulting rows.
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
  /// The returned [SheetRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SheetRow>> upsert(
    _is.DatabaseSession session,
    List<SheetRow> rows, {
    required _is.ColumnSelections<SheetRowTable> conflictColumns,
    _is.ColumnSelections<SheetRowTable>? updateColumns,
    _is.WhereExpressionBuilder<SheetRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SheetRow>(
      rows,
      conflictColumns: conflictColumns(SheetRow.t),
      updateColumns: updateColumns?.call(SheetRow.t),
      updateWhere: updateWhere?.call(SheetRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SheetRow] and returns the resulting row.
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
  /// The returned [SheetRow] will have its `id` field set.
  Future<SheetRow?> upsertRow(
    _is.DatabaseSession session,
    SheetRow row, {
    required _is.ColumnSelections<SheetRowTable> conflictColumns,
    _is.ColumnSelections<SheetRowTable>? updateColumns,
    _is.WhereExpressionBuilder<SheetRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SheetRow>(
      row,
      conflictColumns: conflictColumns(SheetRow.t),
      updateColumns: updateColumns?.call(SheetRow.t),
      updateWhere: updateWhere?.call(SheetRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [SheetRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SheetRow>> update(
    _is.DatabaseSession session,
    List<SheetRow> rows, {
    _is.ColumnSelections<SheetRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SheetRow>(
      rows,
      columns: columns?.call(SheetRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SheetRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SheetRow> updateRow(
    _is.DatabaseSession session,
    SheetRow row, {
    _is.ColumnSelections<SheetRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SheetRow>(
      row,
      columns: columns?.call(SheetRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SheetRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SheetRow?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<SheetRowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SheetRow>(
      id,
      columnValues: columnValues(SheetRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SheetRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SheetRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SheetRowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SheetRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SheetRowTable>? orderBy,
    _is.OrderByListBuilder<SheetRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SheetRow>(
      columnValues: columnValues(SheetRow.t.updateTable),
      where: where(SheetRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SheetRow.t),
      orderByList: orderByList?.call(SheetRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SheetRow]s in the list and returns the deleted rows.
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
  Future<List<SheetRow>> delete(
    _is.DatabaseSession session,
    List<SheetRow> rows, {
    _is.OrderByBuilder<SheetRowTable>? orderBy,
    _is.OrderByListBuilder<SheetRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SheetRow>(
      rows,
      orderBy: orderBy?.call(SheetRow.t),
      orderByList: orderByList?.call(SheetRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SheetRow].
  Future<SheetRow> deleteRow(
    _is.DatabaseSession session,
    SheetRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SheetRow>(
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
  Future<List<SheetRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SheetRowTable> where,
    _is.OrderByBuilder<SheetRowTable>? orderBy,
    _is.OrderByListBuilder<SheetRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SheetRow>(
      where: where(SheetRow.t),
      orderBy: orderBy?.call(SheetRow.t),
      orderByList: orderByList?.call(SheetRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SheetRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SheetRow>(
      where: where?.call(SheetRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SheetRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SheetRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SheetRow>(
      where: where(SheetRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SheetRowAttachRowRepository {
  const SheetRowAttachRowRepository._();

  /// Creates a relation between the given [SheetRow] and [RevFile]
  /// by setting the [SheetRow]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    SheetRow sheetRow,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (sheetRow.id == null) {
      throw ArgumentError.notNull('sheetRow.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $sheetRow = sheetRow.copyWith(fileId: file.id);
    await session.db.updateRow<SheetRow>(
      $sheetRow,
      columns: [SheetRow.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SheetRow] and [Sheet]
  /// by setting the [SheetRow]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    SheetRow sheetRow,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (sheetRow.id == null) {
      throw ArgumentError.notNull('sheetRow.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $sheetRow = sheetRow.copyWith(sheetId: sheet.id);
    await session.db.updateRow<SheetRow>(
      $sheetRow,
      columns: [SheetRow.t.sheetId],
      transaction: transaction,
    );
  }
}
