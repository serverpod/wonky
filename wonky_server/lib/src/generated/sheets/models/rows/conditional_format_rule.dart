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

/// A conditional formatting rule (Sheets 06 §15).
abstract class ConditionalFormatRule
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  ConditionalFormatRule._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.sortKey,
    required this.rangesJson,
    required this.ruleJson,
    bool? enabled,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       enabled = enabled ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory ConditionalFormatRule({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String sortKey,
    required String rangesJson,
    required String ruleJson,
    bool? enabled,
    DateTime? createdAt,
  }) = _ConditionalFormatRuleImpl;

  factory ConditionalFormatRule.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ConditionalFormatRule(
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
      rangesJson: jsonSerialization['rangesJson'] as String,
      ruleJson: jsonSerialization['ruleJson'] as String,
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ConditionalFormatRuleTable();

  static const db = ConditionalFormatRuleRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  /// Priority, first = highest.
  String sortKey;

  /// List of GridRange.
  String rangesJson;

  String ruleJson;

  bool enabled;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [ConditionalFormatRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ConditionalFormatRule copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedConditionalFormatRule$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedConditionalFormatRule$sheet(),
    String? sortKey,
    String? rangesJson,
    String? ruleJson,
    bool? enabled,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConditionalFormatRule',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'sortKey': sortKey,
      'rangesJson': rangesJson,
      'ruleJson': ruleJson,
      'enabled': enabled,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ConditionalFormatRuleInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return ConditionalFormatRuleInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static ConditionalFormatRuleIncludeList includeList({
    _is.WhereExpressionBuilder<ConditionalFormatRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConditionalFormatRuleTable>? orderBy,
    _is.OrderByListBuilder<ConditionalFormatRuleTable>? orderByList,
    ConditionalFormatRuleInclude? include,
  }) {
    return ConditionalFormatRuleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConditionalFormatRule.t),
      orderByList: orderByList?.call(ConditionalFormatRule.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _UndefinedConditionalFormatRule$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedConditionalFormatRule$file();
}

class _UndefinedConditionalFormatRule$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedConditionalFormatRule$sheet();
}

class _ConditionalFormatRuleImpl extends ConditionalFormatRule {
  _ConditionalFormatRuleImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String sortKey,
    required String rangesJson,
    required String ruleJson,
    bool? enabled,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         sortKey: sortKey,
         rangesJson: rangesJson,
         ruleJson: ruleJson,
         enabled: enabled,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ConditionalFormatRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ConditionalFormatRule copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedConditionalFormatRule$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedConditionalFormatRule$sheet(),
    String? sortKey,
    String? rangesJson,
    String? ruleJson,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return ConditionalFormatRule(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      sortKey: sortKey ?? this.sortKey,
      rangesJson: rangesJson ?? this.rangesJson,
      ruleJson: ruleJson ?? this.ruleJson,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ConditionalFormatRuleUpdateTable
    extends _is.UpdateTable<ConditionalFormatRuleTable> {
  ConditionalFormatRuleUpdateTable(super.table);

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

  _is.ColumnValue<String, String> rangesJson(String value) => _is.ColumnValue(
    table.rangesJson,
    value,
  );

  _is.ColumnValue<String, String> ruleJson(String value) => _is.ColumnValue(
    table.ruleJson,
    value,
  );

  _is.ColumnValue<bool, bool> enabled(bool value) => _is.ColumnValue(
    table.enabled,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ConditionalFormatRuleTable extends _is.Table<_is.UuidValue> {
  ConditionalFormatRuleTable({super.tableRelation})
    : super(tableName: 'conditional_format_rule') {
    updateTable = ConditionalFormatRuleUpdateTable(this);
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
    rangesJson = _is.ColumnString(
      'rangesJson',
      this,
    );
    ruleJson = _is.ColumnString(
      'ruleJson',
      this,
    );
    enabled = _is.ColumnBool(
      'enabled',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ConditionalFormatRuleUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  /// Priority, first = highest.
  late final _is.ColumnString sortKey;

  /// List of GridRange.
  late final _is.ColumnString rangesJson;

  late final _is.ColumnString ruleJson;

  late final _is.ColumnBool enabled;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: ConditionalFormatRule.t.fileId,
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
      field: ConditionalFormatRule.t.sheetId,
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
    rangesJson,
    ruleJson,
    enabled,
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

class ConditionalFormatRuleInclude extends _is.IncludeObject {
  ConditionalFormatRuleInclude._({
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
  _is.Table<_is.UuidValue> get table => ConditionalFormatRule.t;
}

class ConditionalFormatRuleIncludeList extends _is.IncludeList {
  ConditionalFormatRuleIncludeList._({
    _is.WhereExpressionBuilder<ConditionalFormatRuleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ConditionalFormatRule.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => ConditionalFormatRule.t;
}

class ConditionalFormatRuleRepository {
  const ConditionalFormatRuleRepository._();

  final attachRow = const ConditionalFormatRuleAttachRowRepository._();

  /// Returns a list of [ConditionalFormatRule]s matching the given query parameters.
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
  Future<List<ConditionalFormatRule>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConditionalFormatRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConditionalFormatRuleTable>? orderBy,
    _is.OrderByListBuilder<ConditionalFormatRuleTable>? orderByList,
    _is.Transaction? transaction,
    ConditionalFormatRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ConditionalFormatRule>(
      where: where?.call(ConditionalFormatRule.t),
      orderBy: orderBy?.call(ConditionalFormatRule.t),
      orderByList: orderByList?.call(ConditionalFormatRule.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ConditionalFormatRule]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ConditionalFormatRule.t`.
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
  _ida.Stream<List<ConditionalFormatRule>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConditionalFormatRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConditionalFormatRuleTable>? orderBy,
    _is.OrderByListBuilder<ConditionalFormatRuleTable>? orderByList,
    ConditionalFormatRuleInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ConditionalFormatRule>(
      where: where?.call(ConditionalFormatRule.t),
      orderBy: orderBy?.call(ConditionalFormatRule.t),
      orderByList: orderByList?.call(ConditionalFormatRule.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ConditionalFormatRule] matching the given query parameters.
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
  Future<ConditionalFormatRule?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConditionalFormatRuleTable>? where,
    int? offset,
    _is.OrderByBuilder<ConditionalFormatRuleTable>? orderBy,
    _is.OrderByListBuilder<ConditionalFormatRuleTable>? orderByList,
    _is.Transaction? transaction,
    ConditionalFormatRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ConditionalFormatRule>(
      where: where?.call(ConditionalFormatRule.t),
      orderBy: orderBy?.call(ConditionalFormatRule.t),
      orderByList: orderByList?.call(ConditionalFormatRule.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ConditionalFormatRule] by its [id] or null if no such row exists.
  Future<ConditionalFormatRule?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ConditionalFormatRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ConditionalFormatRule>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ConditionalFormatRule]s in the list and returns the inserted rows.
  ///
  /// The returned [ConditionalFormatRule]s will have their `id` fields set.
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
  Future<List<ConditionalFormatRule>> insert(
    _is.DatabaseSession session,
    List<ConditionalFormatRule> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ConditionalFormatRule>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ConditionalFormatRule] and returns the inserted row.
  ///
  /// The returned [ConditionalFormatRule] will have its `id` field set.
  Future<ConditionalFormatRule> insertRow(
    _is.DatabaseSession session,
    ConditionalFormatRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ConditionalFormatRule>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ConditionalFormatRule]s in the list and returns the resulting rows.
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
  /// The returned [ConditionalFormatRule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConditionalFormatRule>> upsert(
    _is.DatabaseSession session,
    List<ConditionalFormatRule> rows, {
    required _is.ColumnSelections<ConditionalFormatRuleTable> conflictColumns,
    _is.ColumnSelections<ConditionalFormatRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<ConditionalFormatRuleTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ConditionalFormatRule>(
      rows,
      conflictColumns: conflictColumns(ConditionalFormatRule.t),
      updateColumns: updateColumns?.call(ConditionalFormatRule.t),
      updateWhere: updateWhere?.call(ConditionalFormatRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ConditionalFormatRule] and returns the resulting row.
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
  /// The returned [ConditionalFormatRule] will have its `id` field set.
  Future<ConditionalFormatRule?> upsertRow(
    _is.DatabaseSession session,
    ConditionalFormatRule row, {
    required _is.ColumnSelections<ConditionalFormatRuleTable> conflictColumns,
    _is.ColumnSelections<ConditionalFormatRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<ConditionalFormatRuleTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ConditionalFormatRule>(
      row,
      conflictColumns: conflictColumns(ConditionalFormatRule.t),
      updateColumns: updateColumns?.call(ConditionalFormatRule.t),
      updateWhere: updateWhere?.call(ConditionalFormatRule.t),
      transaction: transaction,
    );
  }

  /// Updates all [ConditionalFormatRule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConditionalFormatRule>> update(
    _is.DatabaseSession session,
    List<ConditionalFormatRule> rows, {
    _is.ColumnSelections<ConditionalFormatRuleTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ConditionalFormatRule>(
      rows,
      columns: columns?.call(ConditionalFormatRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ConditionalFormatRule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ConditionalFormatRule> updateRow(
    _is.DatabaseSession session,
    ConditionalFormatRule row, {
    _is.ColumnSelections<ConditionalFormatRuleTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ConditionalFormatRule>(
      row,
      columns: columns?.call(ConditionalFormatRule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ConditionalFormatRule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ConditionalFormatRule?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ConditionalFormatRuleUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ConditionalFormatRule>(
      id,
      columnValues: columnValues(ConditionalFormatRule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ConditionalFormatRule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ConditionalFormatRule>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ConditionalFormatRuleUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<ConditionalFormatRuleTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ConditionalFormatRuleTable>? orderBy,
    _is.OrderByListBuilder<ConditionalFormatRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ConditionalFormatRule>(
      columnValues: columnValues(ConditionalFormatRule.t.updateTable),
      where: where(ConditionalFormatRule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ConditionalFormatRule.t),
      orderByList: orderByList?.call(ConditionalFormatRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ConditionalFormatRule]s in the list and returns the deleted rows.
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
  Future<List<ConditionalFormatRule>> delete(
    _is.DatabaseSession session,
    List<ConditionalFormatRule> rows, {
    _is.OrderByBuilder<ConditionalFormatRuleTable>? orderBy,
    _is.OrderByListBuilder<ConditionalFormatRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ConditionalFormatRule>(
      rows,
      orderBy: orderBy?.call(ConditionalFormatRule.t),
      orderByList: orderByList?.call(ConditionalFormatRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ConditionalFormatRule].
  Future<ConditionalFormatRule> deleteRow(
    _is.DatabaseSession session,
    ConditionalFormatRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ConditionalFormatRule>(
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
  Future<List<ConditionalFormatRule>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConditionalFormatRuleTable> where,
    _is.OrderByBuilder<ConditionalFormatRuleTable>? orderBy,
    _is.OrderByListBuilder<ConditionalFormatRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ConditionalFormatRule>(
      where: where(ConditionalFormatRule.t),
      orderBy: orderBy?.call(ConditionalFormatRule.t),
      orderByList: orderByList?.call(ConditionalFormatRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ConditionalFormatRuleTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ConditionalFormatRule>(
      where: where?.call(ConditionalFormatRule.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ConditionalFormatRule] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ConditionalFormatRuleTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ConditionalFormatRule>(
      where: where(ConditionalFormatRule.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ConditionalFormatRuleAttachRowRepository {
  const ConditionalFormatRuleAttachRowRepository._();

  /// Creates a relation between the given [ConditionalFormatRule] and [RevFile]
  /// by setting the [ConditionalFormatRule]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    ConditionalFormatRule conditionalFormatRule,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (conditionalFormatRule.id == null) {
      throw ArgumentError.notNull('conditionalFormatRule.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $conditionalFormatRule = conditionalFormatRule.copyWith(
      fileId: file.id,
    );
    await session.db.updateRow<ConditionalFormatRule>(
      $conditionalFormatRule,
      columns: [ConditionalFormatRule.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ConditionalFormatRule] and [Sheet]
  /// by setting the [ConditionalFormatRule]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    ConditionalFormatRule conditionalFormatRule,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (conditionalFormatRule.id == null) {
      throw ArgumentError.notNull('conditionalFormatRule.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $conditionalFormatRule = conditionalFormatRule.copyWith(
      sheetId: sheet.id,
    );
    await session.db.updateRow<ConditionalFormatRule>(
      $conditionalFormatRule,
      columns: [ConditionalFormatRule.t.sheetId],
      transaction: transaction,
    );
  }
}
