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
import '../../../sheets/models/rows/enums/recalc_mode.dart' as _iaq2zucp;

/// A spreadsheet. Its id is always the uuidSpaceId of the space it lives in
/// (one spreadsheet per space, Sheets 02 §3.1).
abstract class Spreadsheet
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  Spreadsheet._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.title,
    required this.locale,
    required this.timeZone,
    _iaq2zucp.RecalcMode? recalcMode,
    bool? iterativeCalc,
    int? maxIterations,
    double? convergenceThreshold,
    String? defaultFontFamily,
    double? defaultFontSize,
    required this.themeJson,
    this.displayLanguage,
    required this.createdBy,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       recalcMode = recalcMode ?? _iaq2zucp.RecalcMode.onChange,
       iterativeCalc = iterativeCalc ?? false,
       maxIterations = maxIterations ?? 50,
       convergenceThreshold = convergenceThreshold ?? 0.05,
       defaultFontFamily = defaultFontFamily ?? 'Inter',
       defaultFontSize = defaultFontSize ?? 10.0,
       createdAt = createdAt ?? DateTime.now();

  factory Spreadsheet({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required String title,
    required String locale,
    required String timeZone,
    _iaq2zucp.RecalcMode? recalcMode,
    bool? iterativeCalc,
    int? maxIterations,
    double? convergenceThreshold,
    String? defaultFontFamily,
    double? defaultFontSize,
    required String themeJson,
    String? displayLanguage,
    required _is.UuidValue createdBy,
    DateTime? createdAt,
  }) = _SpreadsheetImpl;

  factory Spreadsheet.fromJson(Map<String, dynamic> jsonSerialization) {
    return Spreadsheet(
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
      title: jsonSerialization['title'] as String,
      locale: jsonSerialization['locale'] as String,
      timeZone: jsonSerialization['timeZone'] as String,
      recalcMode: jsonSerialization['recalcMode'] == null
          ? null
          : _iaq2zucp.RecalcMode.fromJson(
              (jsonSerialization['recalcMode'] as String),
            ),
      iterativeCalc: jsonSerialization['iterativeCalc'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['iterativeCalc']),
      maxIterations: jsonSerialization['maxIterations'] as int?,
      convergenceThreshold: (jsonSerialization['convergenceThreshold'] as num?)
          ?.toDouble(),
      defaultFontFamily: jsonSerialization['defaultFontFamily'] as String?,
      defaultFontSize: (jsonSerialization['defaultFontSize'] as num?)
          ?.toDouble(),
      themeJson: jsonSerialization['themeJson'] as String,
      displayLanguage: jsonSerialization['displayLanguage'] as String?,
      createdBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['createdBy'],
      ),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = SpreadsheetTable();

  static const db = SpreadsheetRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  /// Mirrored to DriveItem.name by the server.
  String title;

  /// Number/date parsing and formatting, function argument separator (e.g. en_US).
  String locale;

  /// IANA time zone.
  String timeZone;

  _iaq2zucp.RecalcMode recalcMode;

  bool iterativeCalc;

  int maxIterations;

  double convergenceThreshold;

  String defaultFontFamily;

  double defaultFontSize;

  /// {v, name, fonts: {text}, colors: {...}} (Sheets 06 §13.1).
  String themeJson;

  /// Function name language; null = English (Sheets 04 §15, P2).
  String? displayLanguage;

  /// Auth user UUID of the creator.
  _is.UuidValue createdBy;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [Spreadsheet]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Spreadsheet copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSpreadsheet$file(),
    int? revision,
    String? title,
    String? locale,
    String? timeZone,
    _iaq2zucp.RecalcMode? recalcMode,
    bool? iterativeCalc,
    int? maxIterations,
    double? convergenceThreshold,
    String? defaultFontFamily,
    double? defaultFontSize,
    String? themeJson,
    String? displayLanguage,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Spreadsheet',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'title': title,
      'locale': locale,
      'timeZone': timeZone,
      'recalcMode': recalcMode.toJson(),
      'iterativeCalc': iterativeCalc,
      'maxIterations': maxIterations,
      'convergenceThreshold': convergenceThreshold,
      'defaultFontFamily': defaultFontFamily,
      'defaultFontSize': defaultFontSize,
      'themeJson': themeJson,
      if (displayLanguage != null) 'displayLanguage': displayLanguage,
      'createdBy': createdBy.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SpreadsheetInclude include({_imcki4bb.RevFileInclude? file}) {
    return SpreadsheetInclude._(file: file);
  }

  static SpreadsheetIncludeList includeList({
    _is.WhereExpressionBuilder<SpreadsheetTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SpreadsheetTable>? orderBy,
    _is.OrderByListBuilder<SpreadsheetTable>? orderByList,
    SpreadsheetInclude? include,
  }) {
    return SpreadsheetIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Spreadsheet.t),
      orderByList: orderByList?.call(Spreadsheet.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedSpreadsheet$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedSpreadsheet$file();
}

class _SpreadsheetImpl extends Spreadsheet {
  _SpreadsheetImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required String title,
    required String locale,
    required String timeZone,
    _iaq2zucp.RecalcMode? recalcMode,
    bool? iterativeCalc,
    int? maxIterations,
    double? convergenceThreshold,
    String? defaultFontFamily,
    double? defaultFontSize,
    required String themeJson,
    String? displayLanguage,
    required _is.UuidValue createdBy,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         title: title,
         locale: locale,
         timeZone: timeZone,
         recalcMode: recalcMode,
         iterativeCalc: iterativeCalc,
         maxIterations: maxIterations,
         convergenceThreshold: convergenceThreshold,
         defaultFontFamily: defaultFontFamily,
         defaultFontSize: defaultFontSize,
         themeJson: themeJson,
         displayLanguage: displayLanguage,
         createdBy: createdBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Spreadsheet]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Spreadsheet copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSpreadsheet$file(),
    int? revision,
    String? title,
    String? locale,
    String? timeZone,
    _iaq2zucp.RecalcMode? recalcMode,
    bool? iterativeCalc,
    int? maxIterations,
    double? convergenceThreshold,
    String? defaultFontFamily,
    double? defaultFontSize,
    String? themeJson,
    Object? displayLanguage = _Undefined,
    _is.UuidValue? createdBy,
    DateTime? createdAt,
  }) {
    return Spreadsheet(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      title: title ?? this.title,
      locale: locale ?? this.locale,
      timeZone: timeZone ?? this.timeZone,
      recalcMode: recalcMode ?? this.recalcMode,
      iterativeCalc: iterativeCalc ?? this.iterativeCalc,
      maxIterations: maxIterations ?? this.maxIterations,
      convergenceThreshold: convergenceThreshold ?? this.convergenceThreshold,
      defaultFontFamily: defaultFontFamily ?? this.defaultFontFamily,
      defaultFontSize: defaultFontSize ?? this.defaultFontSize,
      themeJson: themeJson ?? this.themeJson,
      displayLanguage: displayLanguage is String?
          ? displayLanguage
          : this.displayLanguage,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SpreadsheetUpdateTable extends _is.UpdateTable<SpreadsheetTable> {
  SpreadsheetUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> locale(String value) => _is.ColumnValue(
    table.locale,
    value,
  );

  _is.ColumnValue<String, String> timeZone(String value) => _is.ColumnValue(
    table.timeZone,
    value,
  );

  _is.ColumnValue<_iaq2zucp.RecalcMode, _iaq2zucp.RecalcMode> recalcMode(
    _iaq2zucp.RecalcMode value,
  ) => _is.ColumnValue(
    table.recalcMode,
    value,
  );

  _is.ColumnValue<bool, bool> iterativeCalc(bool value) => _is.ColumnValue(
    table.iterativeCalc,
    value,
  );

  _is.ColumnValue<int, int> maxIterations(int value) => _is.ColumnValue(
    table.maxIterations,
    value,
  );

  _is.ColumnValue<double, double> convergenceThreshold(double value) =>
      _is.ColumnValue(
        table.convergenceThreshold,
        value,
      );

  _is.ColumnValue<String, String> defaultFontFamily(String value) =>
      _is.ColumnValue(
        table.defaultFontFamily,
        value,
      );

  _is.ColumnValue<double, double> defaultFontSize(double value) =>
      _is.ColumnValue(
        table.defaultFontSize,
        value,
      );

  _is.ColumnValue<String, String> themeJson(String value) => _is.ColumnValue(
    table.themeJson,
    value,
  );

  _is.ColumnValue<String, String> displayLanguage(String? value) =>
      _is.ColumnValue(
        table.displayLanguage,
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

class SpreadsheetTable extends _is.Table<_is.UuidValue> {
  SpreadsheetTable({super.tableRelation}) : super(tableName: 'spreadsheet') {
    updateTable = SpreadsheetUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    locale = _is.ColumnString(
      'locale',
      this,
    );
    timeZone = _is.ColumnString(
      'timeZone',
      this,
    );
    recalcMode = _is.ColumnEnum(
      'recalcMode',
      this,
      _is.EnumSerialization.byName,
      hasDefault: true,
    );
    iterativeCalc = _is.ColumnBool(
      'iterativeCalc',
      this,
      hasDefault: true,
    );
    maxIterations = _is.ColumnInt(
      'maxIterations',
      this,
      hasDefault: true,
    );
    convergenceThreshold = _is.ColumnDouble(
      'convergenceThreshold',
      this,
      hasDefault: true,
    );
    defaultFontFamily = _is.ColumnString(
      'defaultFontFamily',
      this,
      hasDefault: true,
    );
    defaultFontSize = _is.ColumnDouble(
      'defaultFontSize',
      this,
      hasDefault: true,
    );
    themeJson = _is.ColumnString(
      'themeJson',
      this,
    );
    displayLanguage = _is.ColumnString(
      'displayLanguage',
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

  late final SpreadsheetUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  /// Mirrored to DriveItem.name by the server.
  late final _is.ColumnString title;

  /// Number/date parsing and formatting, function argument separator (e.g. en_US).
  late final _is.ColumnString locale;

  /// IANA time zone.
  late final _is.ColumnString timeZone;

  late final _is.ColumnEnum<_iaq2zucp.RecalcMode> recalcMode;

  late final _is.ColumnBool iterativeCalc;

  late final _is.ColumnInt maxIterations;

  late final _is.ColumnDouble convergenceThreshold;

  late final _is.ColumnString defaultFontFamily;

  late final _is.ColumnDouble defaultFontSize;

  /// {v, name, fonts: {text}, colors: {...}} (Sheets 06 §13.1).
  late final _is.ColumnString themeJson;

  /// Function name language; null = English (Sheets 04 §15, P2).
  late final _is.ColumnString displayLanguage;

  /// Auth user UUID of the creator.
  late final _is.ColumnUuid createdBy;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: Spreadsheet.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    title,
    locale,
    timeZone,
    recalcMode,
    iterativeCalc,
    maxIterations,
    convergenceThreshold,
    defaultFontFamily,
    defaultFontSize,
    themeJson,
    displayLanguage,
    createdBy,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    return null;
  }
}

class SpreadsheetInclude extends _is.IncludeObject {
  SpreadsheetInclude._({_imcki4bb.RevFileInclude? file}) {
    _file = file;
  }

  _imcki4bb.RevFileInclude? _file;

  @override
  Map<String, _is.Include?> get includes => {'file': _file};

  @override
  _is.Table<_is.UuidValue> get table => Spreadsheet.t;
}

class SpreadsheetIncludeList extends _is.IncludeList {
  SpreadsheetIncludeList._({
    _is.WhereExpressionBuilder<SpreadsheetTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Spreadsheet.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => Spreadsheet.t;
}

class SpreadsheetRepository {
  const SpreadsheetRepository._();

  final attachRow = const SpreadsheetAttachRowRepository._();

  /// Returns a list of [Spreadsheet]s matching the given query parameters.
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
  Future<List<Spreadsheet>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SpreadsheetTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SpreadsheetTable>? orderBy,
    _is.OrderByListBuilder<SpreadsheetTable>? orderByList,
    _is.Transaction? transaction,
    SpreadsheetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Spreadsheet>(
      where: where?.call(Spreadsheet.t),
      orderBy: orderBy?.call(Spreadsheet.t),
      orderByList: orderByList?.call(Spreadsheet.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Spreadsheet]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Spreadsheet.t`.
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
  _ida.Stream<List<Spreadsheet>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SpreadsheetTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SpreadsheetTable>? orderBy,
    _is.OrderByListBuilder<SpreadsheetTable>? orderByList,
    SpreadsheetInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Spreadsheet>(
      where: where?.call(Spreadsheet.t),
      orderBy: orderBy?.call(Spreadsheet.t),
      orderByList: orderByList?.call(Spreadsheet.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Spreadsheet] matching the given query parameters.
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
  Future<Spreadsheet?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SpreadsheetTable>? where,
    int? offset,
    _is.OrderByBuilder<SpreadsheetTable>? orderBy,
    _is.OrderByListBuilder<SpreadsheetTable>? orderByList,
    _is.Transaction? transaction,
    SpreadsheetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Spreadsheet>(
      where: where?.call(Spreadsheet.t),
      orderBy: orderBy?.call(Spreadsheet.t),
      orderByList: orderByList?.call(Spreadsheet.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Spreadsheet] by its [id] or null if no such row exists.
  Future<Spreadsheet?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    SpreadsheetInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Spreadsheet>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Spreadsheet]s in the list and returns the inserted rows.
  ///
  /// The returned [Spreadsheet]s will have their `id` fields set.
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
  Future<List<Spreadsheet>> insert(
    _is.DatabaseSession session,
    List<Spreadsheet> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Spreadsheet>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Spreadsheet] and returns the inserted row.
  ///
  /// The returned [Spreadsheet] will have its `id` field set.
  Future<Spreadsheet> insertRow(
    _is.DatabaseSession session,
    Spreadsheet row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Spreadsheet>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Spreadsheet]s in the list and returns the resulting rows.
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
  /// The returned [Spreadsheet]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Spreadsheet>> upsert(
    _is.DatabaseSession session,
    List<Spreadsheet> rows, {
    required _is.ColumnSelections<SpreadsheetTable> conflictColumns,
    _is.ColumnSelections<SpreadsheetTable>? updateColumns,
    _is.WhereExpressionBuilder<SpreadsheetTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Spreadsheet>(
      rows,
      conflictColumns: conflictColumns(Spreadsheet.t),
      updateColumns: updateColumns?.call(Spreadsheet.t),
      updateWhere: updateWhere?.call(Spreadsheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Spreadsheet] and returns the resulting row.
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
  /// The returned [Spreadsheet] will have its `id` field set.
  Future<Spreadsheet?> upsertRow(
    _is.DatabaseSession session,
    Spreadsheet row, {
    required _is.ColumnSelections<SpreadsheetTable> conflictColumns,
    _is.ColumnSelections<SpreadsheetTable>? updateColumns,
    _is.WhereExpressionBuilder<SpreadsheetTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Spreadsheet>(
      row,
      conflictColumns: conflictColumns(Spreadsheet.t),
      updateColumns: updateColumns?.call(Spreadsheet.t),
      updateWhere: updateWhere?.call(Spreadsheet.t),
      transaction: transaction,
    );
  }

  /// Updates all [Spreadsheet]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Spreadsheet>> update(
    _is.DatabaseSession session,
    List<Spreadsheet> rows, {
    _is.ColumnSelections<SpreadsheetTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Spreadsheet>(
      rows,
      columns: columns?.call(Spreadsheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Spreadsheet]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Spreadsheet> updateRow(
    _is.DatabaseSession session,
    Spreadsheet row, {
    _is.ColumnSelections<SpreadsheetTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Spreadsheet>(
      row,
      columns: columns?.call(Spreadsheet.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Spreadsheet] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Spreadsheet?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<SpreadsheetUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Spreadsheet>(
      id,
      columnValues: columnValues(Spreadsheet.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Spreadsheet]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Spreadsheet>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SpreadsheetUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SpreadsheetTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SpreadsheetTable>? orderBy,
    _is.OrderByListBuilder<SpreadsheetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Spreadsheet>(
      columnValues: columnValues(Spreadsheet.t.updateTable),
      where: where(Spreadsheet.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Spreadsheet.t),
      orderByList: orderByList?.call(Spreadsheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Spreadsheet]s in the list and returns the deleted rows.
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
  Future<List<Spreadsheet>> delete(
    _is.DatabaseSession session,
    List<Spreadsheet> rows, {
    _is.OrderByBuilder<SpreadsheetTable>? orderBy,
    _is.OrderByListBuilder<SpreadsheetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Spreadsheet>(
      rows,
      orderBy: orderBy?.call(Spreadsheet.t),
      orderByList: orderByList?.call(Spreadsheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Spreadsheet].
  Future<Spreadsheet> deleteRow(
    _is.DatabaseSession session,
    Spreadsheet row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Spreadsheet>(
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
  Future<List<Spreadsheet>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SpreadsheetTable> where,
    _is.OrderByBuilder<SpreadsheetTable>? orderBy,
    _is.OrderByListBuilder<SpreadsheetTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Spreadsheet>(
      where: where(Spreadsheet.t),
      orderBy: orderBy?.call(Spreadsheet.t),
      orderByList: orderByList?.call(Spreadsheet.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SpreadsheetTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Spreadsheet>(
      where: where?.call(Spreadsheet.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Spreadsheet] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SpreadsheetTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Spreadsheet>(
      where: where(Spreadsheet.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SpreadsheetAttachRowRepository {
  const SpreadsheetAttachRowRepository._();

  /// Creates a relation between the given [Spreadsheet] and [RevFile]
  /// by setting the [Spreadsheet]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    Spreadsheet spreadsheet,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (spreadsheet.id == null) {
      throw ArgumentError.notNull('spreadsheet.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $spreadsheet = spreadsheet.copyWith(fileId: file.id);
    await session.db.updateRow<Spreadsheet>(
      $spreadsheet,
      columns: [Spreadsheet.t.fileId],
      transaction: transaction,
    );
  }
}
