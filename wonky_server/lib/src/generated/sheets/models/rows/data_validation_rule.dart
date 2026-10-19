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

/// A data validation rule (Sheets 07 §6).
abstract class DataValidationRule
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  DataValidationRule._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.rangesJson,
    required this.criteriaJson,
    bool? strict,
    bool? showDropdown,
    this.displayStyle,
    this.helpText,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       strict = strict ?? false,
       showDropdown = showDropdown ?? true,
       createdAt = createdAt ?? DateTime.now();

  factory DataValidationRule({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String rangesJson,
    required String criteriaJson,
    bool? strict,
    bool? showDropdown,
    String? displayStyle,
    String? helpText,
    DateTime? createdAt,
  }) = _DataValidationRuleImpl;

  factory DataValidationRule.fromJson(Map<String, dynamic> jsonSerialization) {
    return DataValidationRule(
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
      rangesJson: jsonSerialization['rangesJson'] as String,
      criteriaJson: jsonSerialization['criteriaJson'] as String,
      strict: jsonSerialization['strict'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['strict']),
      showDropdown: jsonSerialization['showDropdown'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['showDropdown']),
      displayStyle: jsonSerialization['displayStyle'] as String?,
      helpText: jsonSerialization['helpText'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = DataValidationRuleTable();

  static const db = DataValidationRuleRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  String rangesJson;

  String criteriaJson;

  /// Reject invalid input instead of warning.
  bool strict;

  bool showDropdown;

  /// chip, arrow or plainText.
  String? displayStyle;

  String? helpText;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [DataValidationRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  DataValidationRule copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedDataValidationRule$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedDataValidationRule$sheet(),
    String? rangesJson,
    String? criteriaJson,
    bool? strict,
    bool? showDropdown,
    String? displayStyle,
    String? helpText,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DataValidationRule',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'rangesJson': rangesJson,
      'criteriaJson': criteriaJson,
      'strict': strict,
      'showDropdown': showDropdown,
      if (displayStyle != null) 'displayStyle': displayStyle,
      if (helpText != null) 'helpText': helpText,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static DataValidationRuleInclude include({
    _imcki4bb.RevFileInclude? file,
    _ij40k88n.SheetInclude? sheet,
  }) {
    return DataValidationRuleInclude._(
      file: file,
      sheet: sheet,
    );
  }

  static DataValidationRuleIncludeList includeList({
    _is.WhereExpressionBuilder<DataValidationRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DataValidationRuleTable>? orderBy,
    _is.OrderByListBuilder<DataValidationRuleTable>? orderByList,
    DataValidationRuleInclude? include,
  }) {
    return DataValidationRuleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DataValidationRule.t),
      orderByList: orderByList?.call(DataValidationRule.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedDataValidationRule$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedDataValidationRule$file();
}

class _UndefinedDataValidationRule$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedDataValidationRule$sheet();
}

class _DataValidationRuleImpl extends DataValidationRule {
  _DataValidationRuleImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required String rangesJson,
    required String criteriaJson,
    bool? strict,
    bool? showDropdown,
    String? displayStyle,
    String? helpText,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         rangesJson: rangesJson,
         criteriaJson: criteriaJson,
         strict: strict,
         showDropdown: showDropdown,
         displayStyle: displayStyle,
         helpText: helpText,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DataValidationRule]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  DataValidationRule copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedDataValidationRule$file(),
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedDataValidationRule$sheet(),
    String? rangesJson,
    String? criteriaJson,
    bool? strict,
    bool? showDropdown,
    Object? displayStyle = _Undefined,
    Object? helpText = _Undefined,
    DateTime? createdAt,
  }) {
    return DataValidationRule(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      rangesJson: rangesJson ?? this.rangesJson,
      criteriaJson: criteriaJson ?? this.criteriaJson,
      strict: strict ?? this.strict,
      showDropdown: showDropdown ?? this.showDropdown,
      displayStyle: displayStyle is String? ? displayStyle : this.displayStyle,
      helpText: helpText is String? ? helpText : this.helpText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DataValidationRuleUpdateTable
    extends _is.UpdateTable<DataValidationRuleTable> {
  DataValidationRuleUpdateTable(super.table);

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

  _is.ColumnValue<String, String> rangesJson(String value) => _is.ColumnValue(
    table.rangesJson,
    value,
  );

  _is.ColumnValue<String, String> criteriaJson(String value) => _is.ColumnValue(
    table.criteriaJson,
    value,
  );

  _is.ColumnValue<bool, bool> strict(bool value) => _is.ColumnValue(
    table.strict,
    value,
  );

  _is.ColumnValue<bool, bool> showDropdown(bool value) => _is.ColumnValue(
    table.showDropdown,
    value,
  );

  _is.ColumnValue<String, String> displayStyle(String? value) =>
      _is.ColumnValue(
        table.displayStyle,
        value,
      );

  _is.ColumnValue<String, String> helpText(String? value) => _is.ColumnValue(
    table.helpText,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class DataValidationRuleTable extends _is.Table<_is.UuidValue> {
  DataValidationRuleTable({super.tableRelation})
    : super(tableName: 'data_validation_rule') {
    updateTable = DataValidationRuleUpdateTable(this);
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
    rangesJson = _is.ColumnString(
      'rangesJson',
      this,
    );
    criteriaJson = _is.ColumnString(
      'criteriaJson',
      this,
    );
    strict = _is.ColumnBool(
      'strict',
      this,
      hasDefault: true,
    );
    showDropdown = _is.ColumnBool(
      'showDropdown',
      this,
      hasDefault: true,
    );
    displayStyle = _is.ColumnString(
      'displayStyle',
      this,
    );
    helpText = _is.ColumnString(
      'helpText',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final DataValidationRuleUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  late final _is.ColumnString rangesJson;

  late final _is.ColumnString criteriaJson;

  /// Reject invalid input instead of warning.
  late final _is.ColumnBool strict;

  late final _is.ColumnBool showDropdown;

  /// chip, arrow or plainText.
  late final _is.ColumnString displayStyle;

  late final _is.ColumnString helpText;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: DataValidationRule.t.fileId,
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
      field: DataValidationRule.t.sheetId,
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
    rangesJson,
    criteriaJson,
    strict,
    showDropdown,
    displayStyle,
    helpText,
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

class DataValidationRuleInclude extends _is.IncludeObject {
  DataValidationRuleInclude._({
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
  _is.Table<_is.UuidValue> get table => DataValidationRule.t;
}

class DataValidationRuleIncludeList extends _is.IncludeList {
  DataValidationRuleIncludeList._({
    _is.WhereExpressionBuilder<DataValidationRuleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(DataValidationRule.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => DataValidationRule.t;
}

class DataValidationRuleRepository {
  const DataValidationRuleRepository._();

  final attachRow = const DataValidationRuleAttachRowRepository._();

  /// Returns a list of [DataValidationRule]s matching the given query parameters.
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
  Future<List<DataValidationRule>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DataValidationRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DataValidationRuleTable>? orderBy,
    _is.OrderByListBuilder<DataValidationRuleTable>? orderByList,
    _is.Transaction? transaction,
    DataValidationRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<DataValidationRule>(
      where: where?.call(DataValidationRule.t),
      orderBy: orderBy?.call(DataValidationRule.t),
      orderByList: orderByList?.call(DataValidationRule.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [DataValidationRule]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `DataValidationRule.t`.
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
  _ida.Stream<List<DataValidationRule>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DataValidationRuleTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DataValidationRuleTable>? orderBy,
    _is.OrderByListBuilder<DataValidationRuleTable>? orderByList,
    DataValidationRuleInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<DataValidationRule>(
      where: where?.call(DataValidationRule.t),
      orderBy: orderBy?.call(DataValidationRule.t),
      orderByList: orderByList?.call(DataValidationRule.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [DataValidationRule] matching the given query parameters.
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
  Future<DataValidationRule?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DataValidationRuleTable>? where,
    int? offset,
    _is.OrderByBuilder<DataValidationRuleTable>? orderBy,
    _is.OrderByListBuilder<DataValidationRuleTable>? orderByList,
    _is.Transaction? transaction,
    DataValidationRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<DataValidationRule>(
      where: where?.call(DataValidationRule.t),
      orderBy: orderBy?.call(DataValidationRule.t),
      orderByList: orderByList?.call(DataValidationRule.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [DataValidationRule] by its [id] or null if no such row exists.
  Future<DataValidationRule?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    DataValidationRuleInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<DataValidationRule>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [DataValidationRule]s in the list and returns the inserted rows.
  ///
  /// The returned [DataValidationRule]s will have their `id` fields set.
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
  Future<List<DataValidationRule>> insert(
    _is.DatabaseSession session,
    List<DataValidationRule> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<DataValidationRule>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [DataValidationRule] and returns the inserted row.
  ///
  /// The returned [DataValidationRule] will have its `id` field set.
  Future<DataValidationRule> insertRow(
    _is.DatabaseSession session,
    DataValidationRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<DataValidationRule>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [DataValidationRule]s in the list and returns the resulting rows.
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
  /// The returned [DataValidationRule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DataValidationRule>> upsert(
    _is.DatabaseSession session,
    List<DataValidationRule> rows, {
    required _is.ColumnSelections<DataValidationRuleTable> conflictColumns,
    _is.ColumnSelections<DataValidationRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<DataValidationRuleTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<DataValidationRule>(
      rows,
      conflictColumns: conflictColumns(DataValidationRule.t),
      updateColumns: updateColumns?.call(DataValidationRule.t),
      updateWhere: updateWhere?.call(DataValidationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [DataValidationRule] and returns the resulting row.
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
  /// The returned [DataValidationRule] will have its `id` field set.
  Future<DataValidationRule?> upsertRow(
    _is.DatabaseSession session,
    DataValidationRule row, {
    required _is.ColumnSelections<DataValidationRuleTable> conflictColumns,
    _is.ColumnSelections<DataValidationRuleTable>? updateColumns,
    _is.WhereExpressionBuilder<DataValidationRuleTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<DataValidationRule>(
      row,
      conflictColumns: conflictColumns(DataValidationRule.t),
      updateColumns: updateColumns?.call(DataValidationRule.t),
      updateWhere: updateWhere?.call(DataValidationRule.t),
      transaction: transaction,
    );
  }

  /// Updates all [DataValidationRule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DataValidationRule>> update(
    _is.DatabaseSession session,
    List<DataValidationRule> rows, {
    _is.ColumnSelections<DataValidationRuleTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<DataValidationRule>(
      rows,
      columns: columns?.call(DataValidationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [DataValidationRule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<DataValidationRule> updateRow(
    _is.DatabaseSession session,
    DataValidationRule row, {
    _is.ColumnSelections<DataValidationRuleTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<DataValidationRule>(
      row,
      columns: columns?.call(DataValidationRule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [DataValidationRule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<DataValidationRule?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<DataValidationRuleUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<DataValidationRule>(
      id,
      columnValues: columnValues(DataValidationRule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [DataValidationRule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<DataValidationRule>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DataValidationRuleUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<DataValidationRuleTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DataValidationRuleTable>? orderBy,
    _is.OrderByListBuilder<DataValidationRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<DataValidationRule>(
      columnValues: columnValues(DataValidationRule.t.updateTable),
      where: where(DataValidationRule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(DataValidationRule.t),
      orderByList: orderByList?.call(DataValidationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [DataValidationRule]s in the list and returns the deleted rows.
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
  Future<List<DataValidationRule>> delete(
    _is.DatabaseSession session,
    List<DataValidationRule> rows, {
    _is.OrderByBuilder<DataValidationRuleTable>? orderBy,
    _is.OrderByListBuilder<DataValidationRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<DataValidationRule>(
      rows,
      orderBy: orderBy?.call(DataValidationRule.t),
      orderByList: orderByList?.call(DataValidationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [DataValidationRule].
  Future<DataValidationRule> deleteRow(
    _is.DatabaseSession session,
    DataValidationRule row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<DataValidationRule>(
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
  Future<List<DataValidationRule>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DataValidationRuleTable> where,
    _is.OrderByBuilder<DataValidationRuleTable>? orderBy,
    _is.OrderByListBuilder<DataValidationRuleTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<DataValidationRule>(
      where: where(DataValidationRule.t),
      orderBy: orderBy?.call(DataValidationRule.t),
      orderByList: orderByList?.call(DataValidationRule.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DataValidationRuleTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<DataValidationRule>(
      where: where?.call(DataValidationRule.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [DataValidationRule] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DataValidationRuleTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<DataValidationRule>(
      where: where(DataValidationRule.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class DataValidationRuleAttachRowRepository {
  const DataValidationRuleAttachRowRepository._();

  /// Creates a relation between the given [DataValidationRule] and [RevFile]
  /// by setting the [DataValidationRule]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    DataValidationRule dataValidationRule,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (dataValidationRule.id == null) {
      throw ArgumentError.notNull('dataValidationRule.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $dataValidationRule = dataValidationRule.copyWith(fileId: file.id);
    await session.db.updateRow<DataValidationRule>(
      $dataValidationRule,
      columns: [DataValidationRule.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [DataValidationRule] and [Sheet]
  /// by setting the [DataValidationRule]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    DataValidationRule dataValidationRule,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (dataValidationRule.id == null) {
      throw ArgumentError.notNull('dataValidationRule.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $dataValidationRule = dataValidationRule.copyWith(sheetId: sheet.id);
    await session.db.updateRow<DataValidationRule>(
      $dataValidationRule,
      columns: [DataValidationRule.t.sheetId],
      transaction: transaction,
    );
  }
}
