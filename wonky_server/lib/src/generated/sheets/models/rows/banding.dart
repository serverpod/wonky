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

/// Alternating colors over a range.
abstract class Banding
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  Banding._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.rangeJson,
    required this.styleJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory Banding({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String rangeJson,
    required String styleJson,
    DateTime? createdAt,
  }) = _BandingImpl;

  factory Banding.fromJson(Map<String, dynamic> jsonSerialization) {
    return Banding(
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
      styleJson: jsonSerialization['styleJson'] as String,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = BandingTable();

  static const db = BandingRepository._();

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

  String styleJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [Banding]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Banding copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedBanding$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedBanding$sheet(),
    String? rangeJson,
    String? styleJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Banding',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'rangeJson': rangeJson,
      'styleJson': styleJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static BandingInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return BandingInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static BandingIncludeList includeList({
    _is.WhereExpressionBuilder<BandingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BandingTable>? orderBy,
    _is.OrderByListBuilder<BandingTable>? orderByList,
    BandingInclude? include,
  }) {
    return BandingIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Banding.t),
      orderByList: orderByList?.call(Banding.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedBanding$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedBanding$file();
}

class _UndefinedBanding$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedBanding$sheet();
}

class _BandingImpl extends Banding {
  _BandingImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String rangeJson,
    required String styleJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         rangeJson: rangeJson,
         styleJson: styleJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Banding]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Banding copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedBanding$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedBanding$sheet(),
    String? rangeJson,
    String? styleJson,
    DateTime? createdAt,
  }) {
    return Banding(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      rangeJson: rangeJson ?? this.rangeJson,
      styleJson: styleJson ?? this.styleJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BandingUpdateTable extends _is.UpdateTable<BandingTable> {
  BandingUpdateTable(super.table);

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

  _is.ColumnValue<String, String> styleJson(String value) => _is.ColumnValue(
    table.styleJson,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class BandingTable extends _is.Table<_is.UuidValue> {
  BandingTable({super.tableRelation}) : super(tableName: 'banding') {
    updateTable = BandingUpdateTable(this);
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
    styleJson = _is.ColumnString(
      'styleJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final BandingUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  late final _is.ColumnString rangeJson;

  late final _is.ColumnString styleJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: Banding.t.fileId,
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
      field: Banding.t.sheetId,
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
    styleJson,
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

class BandingInclude extends _is.IncludeObject {
  BandingInclude._({
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
  _is.Table<_is.UuidValue> get table => Banding.t;
}

class BandingIncludeList extends _is.IncludeList {
  BandingIncludeList._({
    _is.WhereExpressionBuilder<BandingTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Banding.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => Banding.t;
}

class BandingRepository {
  const BandingRepository._();

  final attachRow = const BandingAttachRowRepository._();

  /// Returns a list of [Banding]s matching the given query parameters.
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
  Future<List<Banding>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BandingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BandingTable>? orderBy,
    _is.OrderByListBuilder<BandingTable>? orderByList,
    _is.Transaction? transaction,
    BandingInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Banding>(
      where: where?.call(Banding.t),
      orderBy: orderBy?.call(Banding.t),
      orderByList: orderByList?.call(Banding.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Banding]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Banding.t`.
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
  _ida.Stream<List<Banding>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BandingTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BandingTable>? orderBy,
    _is.OrderByListBuilder<BandingTable>? orderByList,
    BandingInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Banding>(
      where: where?.call(Banding.t),
      orderBy: orderBy?.call(Banding.t),
      orderByList: orderByList?.call(Banding.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Banding] matching the given query parameters.
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
  Future<Banding?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BandingTable>? where,
    int? offset,
    _is.OrderByBuilder<BandingTable>? orderBy,
    _is.OrderByListBuilder<BandingTable>? orderByList,
    _is.Transaction? transaction,
    BandingInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Banding>(
      where: where?.call(Banding.t),
      orderBy: orderBy?.call(Banding.t),
      orderByList: orderByList?.call(Banding.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Banding] by its [id] or null if no such row exists.
  Future<Banding?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    BandingInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Banding>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Banding]s in the list and returns the inserted rows.
  ///
  /// The returned [Banding]s will have their `id` fields set.
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
  Future<List<Banding>> insert(
    _is.DatabaseSession session,
    List<Banding> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Banding>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Banding] and returns the inserted row.
  ///
  /// The returned [Banding] will have its `id` field set.
  Future<Banding> insertRow(
    _is.DatabaseSession session,
    Banding row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Banding>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Banding]s in the list and returns the resulting rows.
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
  /// The returned [Banding]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Banding>> upsert(
    _is.DatabaseSession session,
    List<Banding> rows, {
    required _is.ColumnSelections<BandingTable> conflictColumns,
    _is.ColumnSelections<BandingTable>? updateColumns,
    _is.WhereExpressionBuilder<BandingTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Banding>(
      rows,
      conflictColumns: conflictColumns(Banding.t),
      updateColumns: updateColumns?.call(Banding.t),
      updateWhere: updateWhere?.call(Banding.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Banding] and returns the resulting row.
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
  /// The returned [Banding] will have its `id` field set.
  Future<Banding?> upsertRow(
    _is.DatabaseSession session,
    Banding row, {
    required _is.ColumnSelections<BandingTable> conflictColumns,
    _is.ColumnSelections<BandingTable>? updateColumns,
    _is.WhereExpressionBuilder<BandingTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Banding>(
      row,
      conflictColumns: conflictColumns(Banding.t),
      updateColumns: updateColumns?.call(Banding.t),
      updateWhere: updateWhere?.call(Banding.t),
      transaction: transaction,
    );
  }

  /// Updates all [Banding]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Banding>> update(
    _is.DatabaseSession session,
    List<Banding> rows, {
    _is.ColumnSelections<BandingTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Banding>(
      rows,
      columns: columns?.call(Banding.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Banding]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Banding> updateRow(
    _is.DatabaseSession session,
    Banding row, {
    _is.ColumnSelections<BandingTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Banding>(
      row,
      columns: columns?.call(Banding.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Banding] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Banding?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<BandingUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Banding>(
      id,
      columnValues: columnValues(Banding.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Banding]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Banding>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<BandingUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<BandingTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<BandingTable>? orderBy,
    _is.OrderByListBuilder<BandingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Banding>(
      columnValues: columnValues(Banding.t.updateTable),
      where: where(Banding.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Banding.t),
      orderByList: orderByList?.call(Banding.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Banding]s in the list and returns the deleted rows.
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
  Future<List<Banding>> delete(
    _is.DatabaseSession session,
    List<Banding> rows, {
    _is.OrderByBuilder<BandingTable>? orderBy,
    _is.OrderByListBuilder<BandingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Banding>(
      rows,
      orderBy: orderBy?.call(Banding.t),
      orderByList: orderByList?.call(Banding.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Banding].
  Future<Banding> deleteRow(
    _is.DatabaseSession session,
    Banding row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Banding>(
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
  Future<List<Banding>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BandingTable> where,
    _is.OrderByBuilder<BandingTable>? orderBy,
    _is.OrderByListBuilder<BandingTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Banding>(
      where: where(Banding.t),
      orderBy: orderBy?.call(Banding.t),
      orderByList: orderByList?.call(Banding.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<BandingTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Banding>(
      where: where?.call(Banding.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Banding] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<BandingTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Banding>(
      where: where(Banding.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class BandingAttachRowRepository {
  const BandingAttachRowRepository._();

  /// Creates a relation between the given [Banding] and [RevFile]
  /// by setting the [Banding]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    Banding banding,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (banding.id == null) {
      throw ArgumentError.notNull('banding.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $banding = banding.copyWith(fileId: file.id);
    await session.db.updateRow<Banding>(
      $banding,
      columns: [Banding.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Banding] and [Sheet]
  /// by setting the [Banding]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    Banding banding,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (banding.id == null) {
      throw ArgumentError.notNull('banding.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $banding = banding.copyWith(sheetId: sheet.id);
    await session.db.updateRow<Banding>(
      $banding,
      columns: [Banding.t.sheetId],
      transaction: transaction,
    );
  }
}
