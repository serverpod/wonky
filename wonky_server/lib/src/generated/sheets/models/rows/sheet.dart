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
import '../../../sheets/models/rows/enums/sheet_kind.dart' as _io8wjp6c;
import '../../../sheets/models/rows/spreadsheet.dart' as _iy65bbp5;

/// A sheet (tab) of a spreadsheet.
abstract class Sheet
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  Sheet._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.spreadsheetId,
    this.spreadsheet,
    required this.name,
    required this.sortKey,
    _io8wjp6c.SheetKind? kind,
    bool? hidden,
    this.tabColor,
    bool? rightToLeft,
    bool? showGridlines,
    int? frozenRows,
    int? frozenColumns,
    double? defaultRowHeight,
    double? defaultColumnWidth,
    this.formatJson,
    this.printSettingsJson,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       kind = kind ?? _io8wjp6c.SheetKind.grid,
       hidden = hidden ?? false,
       rightToLeft = rightToLeft ?? false,
       showGridlines = showGridlines ?? true,
       frozenRows = frozenRows ?? 0,
       frozenColumns = frozenColumns ?? 0,
       defaultRowHeight = defaultRowHeight ?? 21.0,
       defaultColumnWidth = defaultColumnWidth ?? 100.0,
       createdAt = createdAt ?? DateTime.now();

  factory Sheet({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue spreadsheetId,
    _iy65bbp5.Spreadsheet? spreadsheet,
    required String name,
    required String sortKey,
    _io8wjp6c.SheetKind? kind,
    bool? hidden,
    String? tabColor,
    bool? rightToLeft,
    bool? showGridlines,
    int? frozenRows,
    int? frozenColumns,
    double? defaultRowHeight,
    double? defaultColumnWidth,
    String? formatJson,
    String? printSettingsJson,
    DateTime? createdAt,
  }) = _SheetImpl;

  factory Sheet.fromJson(Map<String, dynamic> jsonSerialization) {
    return Sheet(
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
      spreadsheetId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['spreadsheetId'],
      ),
      spreadsheet: jsonSerialization['spreadsheet'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_iy65bbp5.Spreadsheet>(
              jsonSerialization['spreadsheet'],
            ),
      name: jsonSerialization['name'] as String,
      sortKey: jsonSerialization['sortKey'] as String,
      kind: jsonSerialization['kind'] == null
          ? null
          : _io8wjp6c.SheetKind.fromJson((jsonSerialization['kind'] as String)),
      hidden: jsonSerialization['hidden'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['hidden']),
      tabColor: jsonSerialization['tabColor'] as String?,
      rightToLeft: jsonSerialization['rightToLeft'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['rightToLeft']),
      showGridlines: jsonSerialization['showGridlines'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['showGridlines']),
      frozenRows: jsonSerialization['frozenRows'] as int?,
      frozenColumns: jsonSerialization['frozenColumns'] as int?,
      defaultRowHeight: (jsonSerialization['defaultRowHeight'] as num?)
          ?.toDouble(),
      defaultColumnWidth: (jsonSerialization['defaultColumnWidth'] as num?)
          ?.toDouble(),
      formatJson: jsonSerialization['formatJson'] as String?,
      printSettingsJson: jsonSerialization['printSettingsJson'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = SheetTable();

  static const db = SheetRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue spreadsheetId;

  _iy65bbp5.Spreadsheet? spreadsheet;

  String name;

  /// Fractional index; ties sort by id.
  String sortKey;

  _io8wjp6c.SheetKind kind;

  bool hidden;

  String? tabColor;

  bool rightToLeft;

  bool showGridlines;

  /// Count from the top in the current order.
  int frozenRows;

  int frozenColumns;

  /// Pixels at 100% zoom.
  double defaultRowHeight;

  double defaultColumnWidth;

  /// Sheet-level default format.
  String? formatJson;

  /// Print settings (Sheets 11 §7.2); null = defaults.
  String? printSettingsJson;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [Sheet]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Sheet copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSheet$file(),
    int? revision,
    _is.UuidValue? spreadsheetId,
    _iy65bbp5.Spreadsheet? spreadsheet = const _UndefinedSheet$spreadsheet(),
    String? name,
    String? sortKey,
    _io8wjp6c.SheetKind? kind,
    bool? hidden,
    String? tabColor,
    bool? rightToLeft,
    bool? showGridlines,
    int? frozenRows,
    int? frozenColumns,
    double? defaultRowHeight,
    double? defaultColumnWidth,
    String? formatJson,
    String? printSettingsJson,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Sheet',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'spreadsheetId': spreadsheetId.toJson(),
      if (spreadsheet != null) 'spreadsheet': spreadsheet?.toJson(),
      'name': name,
      'sortKey': sortKey,
      'kind': kind.toJson(),
      'hidden': hidden,
      if (tabColor != null) 'tabColor': tabColor,
      'rightToLeft': rightToLeft,
      'showGridlines': showGridlines,
      'frozenRows': frozenRows,
      'frozenColumns': frozenColumns,
      'defaultRowHeight': defaultRowHeight,
      'defaultColumnWidth': defaultColumnWidth,
      if (formatJson != null) 'formatJson': formatJson,
      if (printSettingsJson != null) 'printSettingsJson': printSettingsJson,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SheetInclude include({
    _imcki4bb.RevFileInclude? file,
    _iy65bbp5.SpreadsheetInclude? spreadsheet,
  }) {
    return SheetInclude._(
      file: file,
      spreadsheet: spreadsheet,
    );
  }

  static SheetIncludeList includeList({
    _is.WhereExpressionBuilder<SheetTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SheetTable>? orderBy,
    _is.OrderByListBuilder<SheetTable>? orderByList,
    SheetInclude? include,
  }) {
    return SheetIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Sheet.t),
      orderByList: orderByList?.call(Sheet.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedSheet$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedSheet$file();
}

class _UndefinedSheet$spreadsheet extends _is.UndefinedSentinel
    implements _iy65bbp5.Spreadsheet {
  const _UndefinedSheet$spreadsheet();
}

class _SheetImpl extends Sheet {
  _SheetImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue spreadsheetId,
    _iy65bbp5.Spreadsheet? spreadsheet,
    required String name,
    required String sortKey,
    _io8wjp6c.SheetKind? kind,
    bool? hidden,
    String? tabColor,
    bool? rightToLeft,
    bool? showGridlines,
    int? frozenRows,
    int? frozenColumns,
    double? defaultRowHeight,
    double? defaultColumnWidth,
    String? formatJson,
    String? printSettingsJson,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         spreadsheetId: spreadsheetId,
         spreadsheet: spreadsheet,
         name: name,
         sortKey: sortKey,
         kind: kind,
         hidden: hidden,
         tabColor: tabColor,
         rightToLeft: rightToLeft,
         showGridlines: showGridlines,
         frozenRows: frozenRows,
         frozenColumns: frozenColumns,
         defaultRowHeight: defaultRowHeight,
         defaultColumnWidth: defaultColumnWidth,
         formatJson: formatJson,
         printSettingsJson: printSettingsJson,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Sheet]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Sheet copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSheet$file(),
    int? revision,
    _is.UuidValue? spreadsheetId,
    _iy65bbp5.Spreadsheet? spreadsheet = const _UndefinedSheet$spreadsheet(),
    String? name,
    String? sortKey,
    _io8wjp6c.SheetKind? kind,
    bool? hidden,
    Object? tabColor = _Undefined,
    bool? rightToLeft,
    bool? showGridlines,
    int? frozenRows,
    int? frozenColumns,
    double? defaultRowHeight,
    double? defaultColumnWidth,
    Object? formatJson = _Undefined,
    Object? printSettingsJson = _Undefined,
    DateTime? createdAt,
  }) {
    return Sheet(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      spreadsheetId: spreadsheetId ?? this.spreadsheetId,
      spreadsheet: spreadsheet is _is.UndefinedSentinel
          ? this.spreadsheet?.copyWith()
          : spreadsheet,
      name: name ?? this.name,
      sortKey: sortKey ?? this.sortKey,
      kind: kind ?? this.kind,
      hidden: hidden ?? this.hidden,
      tabColor: tabColor is String? ? tabColor : this.tabColor,
      rightToLeft: rightToLeft ?? this.rightToLeft,
      showGridlines: showGridlines ?? this.showGridlines,
      frozenRows: frozenRows ?? this.frozenRows,
      frozenColumns: frozenColumns ?? this.frozenColumns,
      defaultRowHeight: defaultRowHeight ?? this.defaultRowHeight,
      defaultColumnWidth: defaultColumnWidth ?? this.defaultColumnWidth,
      formatJson: formatJson is String? ? formatJson : this.formatJson,
      printSettingsJson: printSettingsJson is String?
          ? printSettingsJson
          : this.printSettingsJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SheetUpdateTable extends _is.UpdateTable<SheetTable> {
  SheetUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> spreadsheetId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.spreadsheetId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<String, String> sortKey(String value) => _is.ColumnValue(
    table.sortKey,
    value,
  );

  _is.ColumnValue<_io8wjp6c.SheetKind, _io8wjp6c.SheetKind> kind(
    _io8wjp6c.SheetKind value,
  ) => _is.ColumnValue(
    table.kind,
    value,
  );

  _is.ColumnValue<bool, bool> hidden(bool value) => _is.ColumnValue(
    table.hidden,
    value,
  );

  _is.ColumnValue<String, String> tabColor(String? value) => _is.ColumnValue(
    table.tabColor,
    value,
  );

  _is.ColumnValue<bool, bool> rightToLeft(bool value) => _is.ColumnValue(
    table.rightToLeft,
    value,
  );

  _is.ColumnValue<bool, bool> showGridlines(bool value) => _is.ColumnValue(
    table.showGridlines,
    value,
  );

  _is.ColumnValue<int, int> frozenRows(int value) => _is.ColumnValue(
    table.frozenRows,
    value,
  );

  _is.ColumnValue<int, int> frozenColumns(int value) => _is.ColumnValue(
    table.frozenColumns,
    value,
  );

  _is.ColumnValue<double, double> defaultRowHeight(double value) =>
      _is.ColumnValue(
        table.defaultRowHeight,
        value,
      );

  _is.ColumnValue<double, double> defaultColumnWidth(double value) =>
      _is.ColumnValue(
        table.defaultColumnWidth,
        value,
      );

  _is.ColumnValue<String, String> formatJson(String? value) => _is.ColumnValue(
    table.formatJson,
    value,
  );

  _is.ColumnValue<String, String> printSettingsJson(String? value) =>
      _is.ColumnValue(
        table.printSettingsJson,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class SheetTable extends _is.Table<_is.UuidValue> {
  SheetTable({super.tableRelation}) : super(tableName: 'sheet') {
    updateTable = SheetUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    spreadsheetId = _is.ColumnUuid(
      'spreadsheetId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    sortKey = _is.ColumnString(
      'sortKey',
      this,
    );
    kind = _is.ColumnEnum(
      'kind',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    hidden = _is.ColumnBool(
      'hidden',
      this,
      hasDefault: true,
    );
    tabColor = _is.ColumnString(
      'tabColor',
      this,
    );
    rightToLeft = _is.ColumnBool(
      'rightToLeft',
      this,
      hasDefault: true,
    );
    showGridlines = _is.ColumnBool(
      'showGridlines',
      this,
      hasDefault: true,
    );
    frozenRows = _is.ColumnInt(
      'frozenRows',
      this,
      hasDefault: true,
    );
    frozenColumns = _is.ColumnInt(
      'frozenColumns',
      this,
      hasDefault: true,
    );
    defaultRowHeight = _is.ColumnDouble(
      'defaultRowHeight',
      this,
      hasDefault: true,
    );
    defaultColumnWidth = _is.ColumnDouble(
      'defaultColumnWidth',
      this,
      hasDefault: true,
    );
    formatJson = _is.ColumnString(
      'formatJson',
      this,
    );
    printSettingsJson = _is.ColumnString(
      'printSettingsJson',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final SheetUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid spreadsheetId;

  _iy65bbp5.SpreadsheetTable? _spreadsheet;

  late final _is.ColumnString name;

  /// Fractional index; ties sort by id.
  late final _is.ColumnString sortKey;

  late final _is.ColumnEnum<_io8wjp6c.SheetKind> kind;

  late final _is.ColumnBool hidden;

  late final _is.ColumnString tabColor;

  late final _is.ColumnBool rightToLeft;

  late final _is.ColumnBool showGridlines;

  /// Count from the top in the current order.
  late final _is.ColumnInt frozenRows;

  late final _is.ColumnInt frozenColumns;

  /// Pixels at 100% zoom.
  late final _is.ColumnDouble defaultRowHeight;

  late final _is.ColumnDouble defaultColumnWidth;

  /// Sheet-level default format.
  late final _is.ColumnString formatJson;

  /// Print settings (Sheets 11 §7.2); null = defaults.
  late final _is.ColumnString printSettingsJson;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: Sheet.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _iy65bbp5.SpreadsheetTable get spreadsheet {
    if (_spreadsheet != null) return _spreadsheet!;
    _spreadsheet = _is.createRelationTable(
      relationFieldName: 'spreadsheet',
      field: Sheet.t.spreadsheetId,
      foreignField: _iy65bbp5.Spreadsheet.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _iy65bbp5.SpreadsheetTable(tableRelation: foreignTableRelation),
    );
    return _spreadsheet!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    spreadsheetId,
    name,
    sortKey,
    kind,
    hidden,
    tabColor,
    rightToLeft,
    showGridlines,
    frozenRows,
    frozenColumns,
    defaultRowHeight,
    defaultColumnWidth,
    formatJson,
    printSettingsJson,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'spreadsheet') {
      return spreadsheet;
    }
    return null;
  }
}

class SheetInclude extends _is.IncludeObject {
  SheetInclude._({
    _imcki4bb.RevFileInclude? file,
    _iy65bbp5.SpreadsheetInclude? spreadsheet,
  }) {
    _file = file;
    _spreadsheet = spreadsheet;
  }

  _imcki4bb.RevFileInclude? _file;

  _iy65bbp5.SpreadsheetInclude? _spreadsheet;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'spreadsheet': _spreadsheet,
  };

  @override
  _is.Table<_is.UuidValue> get table => Sheet.t;
}

class SheetIncludeList extends _is.IncludeList {
  SheetIncludeList._({
    _is.WhereExpressionBuilder<SheetTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Sheet.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => Sheet.t;
}

class SheetRepository {
  const SheetRepository._();

  final attachRow = const SheetAttachRowRepository._();

  /// Returns a list of [Sheet]s matching the given query parameters.
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
  Future<List<Sheet>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SheetTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SheetTable>? orderBy,
    _is.OrderByListBuilder<SheetTable>? orderByList,
    _is.Transaction? transaction,
    SheetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Sheet>(
      where: where?.call(Sheet.t),
      orderBy: orderBy?.call(Sheet.t),
      orderByList: orderByList?.call(Sheet.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Sheet]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Sheet.t`.
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
  _ida.Stream<List<Sheet>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SheetTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SheetTable>? orderBy,
    _is.OrderByListBuilder<SheetTable>? orderByList,
    SheetInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Sheet>(
      where: where?.call(Sheet.t),
      orderBy: orderBy?.call(Sheet.t),
      orderByList: orderByList?.call(Sheet.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Sheet] matching the given query parameters.
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
  Future<Sheet?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SheetTable>? where,
    int? offset,
    _is.OrderByBuilder<SheetTable>? orderBy,
    _is.OrderByListBuilder<SheetTable>? orderByList,
    _is.Transaction? transaction,
    SheetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Sheet>(
      where: where?.call(Sheet.t),
      orderBy: orderBy?.call(Sheet.t),
      orderByList: orderByList?.call(Sheet.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Sheet] by its [id] or null if no such row exists.
  Future<Sheet?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    SheetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Sheet>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Sheet]s in the list and returns the inserted rows.
  ///
  /// The returned [Sheet]s will have their `id` fields set.
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
  Future<List<Sheet>> insert(
    _is.DatabaseSession session,
    List<Sheet> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Sheet>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Sheet] and returns the inserted row.
  ///
  /// The returned [Sheet] will have its `id` field set.
  Future<Sheet> insertRow(
    _is.DatabaseSession session,
    Sheet row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Sheet>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Sheet]s in the list and returns the resulting rows.
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
  /// The returned [Sheet]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Sheet>> upsert(
    _is.DatabaseSession session,
    List<Sheet> rows, {
    required _is.ColumnSelections<SheetTable> conflictColumns,
    _is.ColumnSelections<SheetTable>? updateColumns,
    _is.WhereExpressionBuilder<SheetTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Sheet>(
      rows,
      conflictColumns: conflictColumns(Sheet.t),
      updateColumns: updateColumns?.call(Sheet.t),
      updateWhere: updateWhere?.call(Sheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Sheet] and returns the resulting row.
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
  /// The returned [Sheet] will have its `id` field set.
  Future<Sheet?> upsertRow(
    _is.DatabaseSession session,
    Sheet row, {
    required _is.ColumnSelections<SheetTable> conflictColumns,
    _is.ColumnSelections<SheetTable>? updateColumns,
    _is.WhereExpressionBuilder<SheetTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Sheet>(
      row,
      conflictColumns: conflictColumns(Sheet.t),
      updateColumns: updateColumns?.call(Sheet.t),
      updateWhere: updateWhere?.call(Sheet.t),
      transaction: transaction,
    );
  }

  /// Updates all [Sheet]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Sheet>> update(
    _is.DatabaseSession session,
    List<Sheet> rows, {
    _is.ColumnSelections<SheetTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Sheet>(
      rows,
      columns: columns?.call(Sheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Sheet]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Sheet> updateRow(
    _is.DatabaseSession session,
    Sheet row, {
    _is.ColumnSelections<SheetTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Sheet>(
      row,
      columns: columns?.call(Sheet.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Sheet] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Sheet?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<SheetUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Sheet>(
      id,
      columnValues: columnValues(Sheet.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Sheet]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Sheet>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SheetUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SheetTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SheetTable>? orderBy,
    _is.OrderByListBuilder<SheetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Sheet>(
      columnValues: columnValues(Sheet.t.updateTable),
      where: where(Sheet.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Sheet.t),
      orderByList: orderByList?.call(Sheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Sheet]s in the list and returns the deleted rows.
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
  Future<List<Sheet>> delete(
    _is.DatabaseSession session,
    List<Sheet> rows, {
    _is.OrderByBuilder<SheetTable>? orderBy,
    _is.OrderByListBuilder<SheetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Sheet>(
      rows,
      orderBy: orderBy?.call(Sheet.t),
      orderByList: orderByList?.call(Sheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Sheet].
  Future<Sheet> deleteRow(
    _is.DatabaseSession session,
    Sheet row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Sheet>(
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
  Future<List<Sheet>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SheetTable> where,
    _is.OrderByBuilder<SheetTable>? orderBy,
    _is.OrderByListBuilder<SheetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Sheet>(
      where: where(Sheet.t),
      orderBy: orderBy?.call(Sheet.t),
      orderByList: orderByList?.call(Sheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SheetTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Sheet>(
      where: where?.call(Sheet.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Sheet] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SheetTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Sheet>(
      where: where(Sheet.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SheetAttachRowRepository {
  const SheetAttachRowRepository._();

  /// Creates a relation between the given [Sheet] and [RevFile]
  /// by setting the [Sheet]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    Sheet sheet,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $sheet = sheet.copyWith(fileId: file.id);
    await session.db.updateRow<Sheet>(
      $sheet,
      columns: [Sheet.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Sheet] and [Spreadsheet]
  /// by setting the [Sheet]'s foreign key `spreadsheetId` to refer to the [Spreadsheet].
  Future<void> spreadsheet(
    _is.DatabaseSession session,
    Sheet sheet,
    _iy65bbp5.Spreadsheet spreadsheet, {
    _is.Transaction? transaction,
  }) async {
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }
    if (spreadsheet.id == null) {
      throw ArgumentError.notNull('spreadsheet.id');
    }

    var $sheet = sheet.copyWith(spreadsheetId: spreadsheet.id);
    await session.db.updateRow<Sheet>(
      $sheet,
      columns: [Sheet.t.spreadsheetId],
      transaction: transaction,
    );
  }
}
