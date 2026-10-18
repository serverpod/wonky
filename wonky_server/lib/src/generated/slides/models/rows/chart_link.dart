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
import '../../../slides/models/rows/slide_element.dart' as _ip9zwo22;

/// The link of a chart element to a chart in a Wonky Sheets spreadsheet
/// (Slides 02 §3.9, 08). Its id is always SlidesIds.chartLinkId(elementId).
abstract class ChartLink
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  ChartLink._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.elementId,
    this.element,
    required this.spreadsheetItemUuid,
    required this.chartObjectId,
    this.sheetId,
    required this.sourceSpecJson,
    required this.dataSnapshotJson,
    required this.sourceVersion,
    required this.updatedAt,
    required this.updatedBy,
    bool? autoUpdate,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       autoUpdate = autoUpdate ?? false,
       createdAt = createdAt ?? DateTime.now();

  factory ChartLink({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required _is.UuidValue spreadsheetItemUuid,
    required _is.UuidValue chartObjectId,
    String? sheetId,
    required String sourceSpecJson,
    required String dataSnapshotJson,
    required String sourceVersion,
    required DateTime updatedAt,
    required _is.UuidValue updatedBy,
    bool? autoUpdate,
    DateTime? createdAt,
  }) = _ChartLinkImpl;

  factory ChartLink.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChartLink(
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
      elementId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['elementId'],
      ),
      element: jsonSerialization['element'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_ip9zwo22.SlideElement>(
              jsonSerialization['element'],
            ),
      spreadsheetItemUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['spreadsheetItemUuid'],
      ),
      chartObjectId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['chartObjectId'],
      ),
      sheetId: jsonSerialization['sheetId'] as String?,
      sourceSpecJson: jsonSerialization['sourceSpecJson'] as String,
      dataSnapshotJson: jsonSerialization['dataSnapshotJson'] as String,
      sourceVersion: jsonSerialization['sourceVersion'] as String,
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      updatedBy: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['updatedBy'],
      ),
      autoUpdate: jsonSerialization['autoUpdate'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['autoUpdate']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = ChartLinkTable();

  static const db = ChartLinkRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue elementId;

  /// The chart element (kind chart).
  _ip9zwo22.SlideElement? element;

  /// Drive item of the spreadsheet (cross-space: plain UUID).
  _is.UuidValue spreadsheetItemUuid;

  /// Sheets EmbeddedObject id.
  _is.UuidValue chartObjectId;

  /// Sheet of the chart at the last update (08 A-08-2).
  String? sheetId;

  /// The Sheets ChartSpec at the last update ("gz:" prefix when > 32 KB).
  /// Always written together with dataSnapshotJson (P4).
  String sourceSpecJson;

  /// Resolved series/categories at the last update (08 §3.4).
  String dataSnapshotJson;

  /// Opaque version of the source at the last update (08 §5.1).
  String sourceVersion;

  /// When the snapshot was taken.
  DateTime updatedAt;

  _is.UuidValue updatedBy;

  /// "Update automatically" (08).
  bool autoUpdate;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [ChartLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ChartLink copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedChartLink$file(),
    int? revision,
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedChartLink$element(),
    _is.UuidValue? spreadsheetItemUuid,
    _is.UuidValue? chartObjectId,
    String? sheetId,
    String? sourceSpecJson,
    String? dataSnapshotJson,
    String? sourceVersion,
    DateTime? updatedAt,
    _is.UuidValue? updatedBy,
    bool? autoUpdate,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChartLink',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'elementId': elementId.toJson(),
      if (element != null) 'element': element?.toJson(),
      'spreadsheetItemUuid': spreadsheetItemUuid.toJson(),
      'chartObjectId': chartObjectId.toJson(),
      if (sheetId != null) 'sheetId': sheetId,
      'sourceSpecJson': sourceSpecJson,
      'dataSnapshotJson': dataSnapshotJson,
      'sourceVersion': sourceVersion,
      'updatedAt': updatedAt.toJson(),
      'updatedBy': updatedBy.toJson(),
      'autoUpdate': autoUpdate,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ChartLinkInclude include({
    _imcki4bb.RevFileInclude? file,
    _ip9zwo22.SlideElementInclude? element,
  }) {
    return ChartLinkInclude._(
      file: file,
      element: element,
    );
  }

  static ChartLinkIncludeList includeList({
    _is.WhereExpressionBuilder<ChartLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ChartLinkTable>? orderBy,
    _is.OrderByListBuilder<ChartLinkTable>? orderByList,
    ChartLinkInclude? include,
  }) {
    return ChartLinkIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChartLink.t),
      orderByList: orderByList?.call(ChartLink.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedChartLink$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedChartLink$file();
}

class _UndefinedChartLink$element extends _is.UndefinedSentinel
    implements _ip9zwo22.SlideElement {
  const _UndefinedChartLink$element();
}

class _ChartLinkImpl extends ChartLink {
  _ChartLinkImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required _is.UuidValue spreadsheetItemUuid,
    required _is.UuidValue chartObjectId,
    String? sheetId,
    required String sourceSpecJson,
    required String dataSnapshotJson,
    required String sourceVersion,
    required DateTime updatedAt,
    required _is.UuidValue updatedBy,
    bool? autoUpdate,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         elementId: elementId,
         element: element,
         spreadsheetItemUuid: spreadsheetItemUuid,
         chartObjectId: chartObjectId,
         sheetId: sheetId,
         sourceSpecJson: sourceSpecJson,
         dataSnapshotJson: dataSnapshotJson,
         sourceVersion: sourceVersion,
         updatedAt: updatedAt,
         updatedBy: updatedBy,
         autoUpdate: autoUpdate,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [ChartLink]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ChartLink copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedChartLink$file(),
    int? revision,
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedChartLink$element(),
    _is.UuidValue? spreadsheetItemUuid,
    _is.UuidValue? chartObjectId,
    Object? sheetId = _Undefined,
    String? sourceSpecJson,
    String? dataSnapshotJson,
    String? sourceVersion,
    DateTime? updatedAt,
    _is.UuidValue? updatedBy,
    bool? autoUpdate,
    DateTime? createdAt,
  }) {
    return ChartLink(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      elementId: elementId ?? this.elementId,
      element: element is _is.UndefinedSentinel
          ? this.element?.copyWith()
          : element,
      spreadsheetItemUuid: spreadsheetItemUuid ?? this.spreadsheetItemUuid,
      chartObjectId: chartObjectId ?? this.chartObjectId,
      sheetId: sheetId is String? ? sheetId : this.sheetId,
      sourceSpecJson: sourceSpecJson ?? this.sourceSpecJson,
      dataSnapshotJson: dataSnapshotJson ?? this.dataSnapshotJson,
      sourceVersion: sourceVersion ?? this.sourceVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ChartLinkUpdateTable extends _is.UpdateTable<ChartLinkTable> {
  ChartLinkUpdateTable(super.table);

  _is.ColumnValue<int, int> fileId(int value) => _is.ColumnValue(
    table.fileId,
    value,
  );

  _is.ColumnValue<int, int> revision(int value) => _is.ColumnValue(
    table.revision,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> elementId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.elementId,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> spreadsheetItemUuid(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.spreadsheetItemUuid,
    value,
  );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> chartObjectId(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.chartObjectId,
    value,
  );

  _is.ColumnValue<String, String> sheetId(String? value) => _is.ColumnValue(
    table.sheetId,
    value,
  );

  _is.ColumnValue<String, String> sourceSpecJson(String value) =>
      _is.ColumnValue(
        table.sourceSpecJson,
        value,
      );

  _is.ColumnValue<String, String> dataSnapshotJson(String value) =>
      _is.ColumnValue(
        table.dataSnapshotJson,
        value,
      );

  _is.ColumnValue<String, String> sourceVersion(String value) =>
      _is.ColumnValue(
        table.sourceVersion,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(
        table.updatedAt,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> updatedBy(
    _is.UuidValue value,
  ) => _is.ColumnValue(
    table.updatedBy,
    value,
  );

  _is.ColumnValue<bool, bool> autoUpdate(bool value) => _is.ColumnValue(
    table.autoUpdate,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class ChartLinkTable extends _is.Table<_is.UuidValue> {
  ChartLinkTable({super.tableRelation}) : super(tableName: 'chart_link') {
    updateTable = ChartLinkUpdateTable(this);
    fileId = _is.ColumnInt(
      'fileId',
      this,
    );
    revision = _is.ColumnInt(
      'revision',
      this,
      hasDefault: true,
    );
    elementId = _is.ColumnUuid(
      'elementId',
      this,
    );
    spreadsheetItemUuid = _is.ColumnUuid(
      'spreadsheetItemUuid',
      this,
    );
    chartObjectId = _is.ColumnUuid(
      'chartObjectId',
      this,
    );
    sheetId = _is.ColumnString(
      'sheetId',
      this,
    );
    sourceSpecJson = _is.ColumnString(
      'sourceSpecJson',
      this,
    );
    dataSnapshotJson = _is.ColumnString(
      'dataSnapshotJson',
      this,
    );
    sourceVersion = _is.ColumnString(
      'sourceVersion',
      this,
    );
    updatedAt = _is.ColumnDateTime(
      'updatedAt',
      this,
    );
    updatedBy = _is.ColumnUuid(
      'updatedBy',
      this,
    );
    autoUpdate = _is.ColumnBool(
      'autoUpdate',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final ChartLinkUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid elementId;

  /// The chart element (kind chart).
  _ip9zwo22.SlideElementTable? _element;

  /// Drive item of the spreadsheet (cross-space: plain UUID).
  late final _is.ColumnUuid spreadsheetItemUuid;

  /// Sheets EmbeddedObject id.
  late final _is.ColumnUuid chartObjectId;

  /// Sheet of the chart at the last update (08 A-08-2).
  late final _is.ColumnString sheetId;

  /// The Sheets ChartSpec at the last update ("gz:" prefix when > 32 KB).
  /// Always written together with dataSnapshotJson (P4).
  late final _is.ColumnString sourceSpecJson;

  /// Resolved series/categories at the last update (08 §3.4).
  late final _is.ColumnString dataSnapshotJson;

  /// Opaque version of the source at the last update (08 §5.1).
  late final _is.ColumnString sourceVersion;

  /// When the snapshot was taken.
  late final _is.ColumnDateTime updatedAt;

  late final _is.ColumnUuid updatedBy;

  /// "Update automatically" (08).
  late final _is.ColumnBool autoUpdate;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: ChartLink.t.fileId,
      foreignField: _imcki4bb.RevFile.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _imcki4bb.RevFileTable(tableRelation: foreignTableRelation),
    );
    return _file!;
  }

  _ip9zwo22.SlideElementTable get element {
    if (_element != null) return _element!;
    _element = _is.createRelationTable(
      relationFieldName: 'element',
      field: ChartLink.t.elementId,
      foreignField: _ip9zwo22.SlideElement.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ip9zwo22.SlideElementTable(tableRelation: foreignTableRelation),
    );
    return _element!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    elementId,
    spreadsheetItemUuid,
    chartObjectId,
    sheetId,
    sourceSpecJson,
    dataSnapshotJson,
    sourceVersion,
    updatedAt,
    updatedBy,
    autoUpdate,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'file') {
      return file;
    }
    if (relationField == 'element') {
      return element;
    }
    return null;
  }
}

class ChartLinkInclude extends _is.IncludeObject {
  ChartLinkInclude._({
    _imcki4bb.RevFileInclude? file,
    _ip9zwo22.SlideElementInclude? element,
  }) {
    _file = file;
    _element = element;
  }

  _imcki4bb.RevFileInclude? _file;

  _ip9zwo22.SlideElementInclude? _element;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'element': _element,
  };

  @override
  _is.Table<_is.UuidValue> get table => ChartLink.t;
}

class ChartLinkIncludeList extends _is.IncludeList {
  ChartLinkIncludeList._({
    _is.WhereExpressionBuilder<ChartLinkTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ChartLink.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => ChartLink.t;
}

class ChartLinkRepository {
  const ChartLinkRepository._();

  final attachRow = const ChartLinkAttachRowRepository._();

  /// Returns a list of [ChartLink]s matching the given query parameters.
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
  Future<List<ChartLink>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ChartLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ChartLinkTable>? orderBy,
    _is.OrderByListBuilder<ChartLinkTable>? orderByList,
    _is.Transaction? transaction,
    ChartLinkInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ChartLink>(
      where: where?.call(ChartLink.t),
      orderBy: orderBy?.call(ChartLink.t),
      orderByList: orderByList?.call(ChartLink.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [ChartLink]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `ChartLink.t`.
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
  _ida.Stream<List<ChartLink>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ChartLinkTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ChartLinkTable>? orderBy,
    _is.OrderByListBuilder<ChartLinkTable>? orderByList,
    ChartLinkInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<ChartLink>(
      where: where?.call(ChartLink.t),
      orderBy: orderBy?.call(ChartLink.t),
      orderByList: orderByList?.call(ChartLink.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [ChartLink] matching the given query parameters.
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
  Future<ChartLink?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ChartLinkTable>? where,
    int? offset,
    _is.OrderByBuilder<ChartLinkTable>? orderBy,
    _is.OrderByListBuilder<ChartLinkTable>? orderByList,
    _is.Transaction? transaction,
    ChartLinkInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ChartLink>(
      where: where?.call(ChartLink.t),
      orderBy: orderBy?.call(ChartLink.t),
      orderByList: orderByList?.call(ChartLink.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ChartLink] by its [id] or null if no such row exists.
  Future<ChartLink?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    ChartLinkInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ChartLink>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ChartLink]s in the list and returns the inserted rows.
  ///
  /// The returned [ChartLink]s will have their `id` fields set.
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
  Future<List<ChartLink>> insert(
    _is.DatabaseSession session,
    List<ChartLink> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ChartLink>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ChartLink] and returns the inserted row.
  ///
  /// The returned [ChartLink] will have its `id` field set.
  Future<ChartLink> insertRow(
    _is.DatabaseSession session,
    ChartLink row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ChartLink>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [ChartLink]s in the list and returns the resulting rows.
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
  /// The returned [ChartLink]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ChartLink>> upsert(
    _is.DatabaseSession session,
    List<ChartLink> rows, {
    required _is.ColumnSelections<ChartLinkTable> conflictColumns,
    _is.ColumnSelections<ChartLinkTable>? updateColumns,
    _is.WhereExpressionBuilder<ChartLinkTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ChartLink>(
      rows,
      conflictColumns: conflictColumns(ChartLink.t),
      updateColumns: updateColumns?.call(ChartLink.t),
      updateWhere: updateWhere?.call(ChartLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ChartLink] and returns the resulting row.
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
  /// The returned [ChartLink] will have its `id` field set.
  Future<ChartLink?> upsertRow(
    _is.DatabaseSession session,
    ChartLink row, {
    required _is.ColumnSelections<ChartLinkTable> conflictColumns,
    _is.ColumnSelections<ChartLinkTable>? updateColumns,
    _is.WhereExpressionBuilder<ChartLinkTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ChartLink>(
      row,
      conflictColumns: conflictColumns(ChartLink.t),
      updateColumns: updateColumns?.call(ChartLink.t),
      updateWhere: updateWhere?.call(ChartLink.t),
      transaction: transaction,
    );
  }

  /// Updates all [ChartLink]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ChartLink>> update(
    _is.DatabaseSession session,
    List<ChartLink> rows, {
    _is.ColumnSelections<ChartLinkTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ChartLink>(
      rows,
      columns: columns?.call(ChartLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ChartLink]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ChartLink> updateRow(
    _is.DatabaseSession session,
    ChartLink row, {
    _is.ColumnSelections<ChartLinkTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ChartLink>(
      row,
      columns: columns?.call(ChartLink.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ChartLink] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ChartLink?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ChartLinkUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ChartLink>(
      id,
      columnValues: columnValues(ChartLink.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ChartLink]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ChartLink>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ChartLinkUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ChartLinkTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ChartLinkTable>? orderBy,
    _is.OrderByListBuilder<ChartLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ChartLink>(
      columnValues: columnValues(ChartLink.t.updateTable),
      where: where(ChartLink.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ChartLink.t),
      orderByList: orderByList?.call(ChartLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ChartLink]s in the list and returns the deleted rows.
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
  Future<List<ChartLink>> delete(
    _is.DatabaseSession session,
    List<ChartLink> rows, {
    _is.OrderByBuilder<ChartLinkTable>? orderBy,
    _is.OrderByListBuilder<ChartLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ChartLink>(
      rows,
      orderBy: orderBy?.call(ChartLink.t),
      orderByList: orderByList?.call(ChartLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ChartLink].
  Future<ChartLink> deleteRow(
    _is.DatabaseSession session,
    ChartLink row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ChartLink>(
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
  Future<List<ChartLink>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ChartLinkTable> where,
    _is.OrderByBuilder<ChartLinkTable>? orderBy,
    _is.OrderByListBuilder<ChartLinkTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ChartLink>(
      where: where(ChartLink.t),
      orderBy: orderBy?.call(ChartLink.t),
      orderByList: orderByList?.call(ChartLink.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ChartLinkTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ChartLink>(
      where: where?.call(ChartLink.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ChartLink] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ChartLinkTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ChartLink>(
      where: where(ChartLink.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class ChartLinkAttachRowRepository {
  const ChartLinkAttachRowRepository._();

  /// Creates a relation between the given [ChartLink] and [RevFile]
  /// by setting the [ChartLink]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    ChartLink chartLink,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (chartLink.id == null) {
      throw ArgumentError.notNull('chartLink.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $chartLink = chartLink.copyWith(fileId: file.id);
    await session.db.updateRow<ChartLink>(
      $chartLink,
      columns: [ChartLink.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [ChartLink] and [SlideElement]
  /// by setting the [ChartLink]'s foreign key `elementId` to refer to the [SlideElement].
  Future<void> element(
    _is.DatabaseSession session,
    ChartLink chartLink,
    _ip9zwo22.SlideElement element, {
    _is.Transaction? transaction,
  }) async {
    if (chartLink.id == null) {
      throw ArgumentError.notNull('chartLink.id');
    }
    if (element.id == null) {
      throw ArgumentError.notNull('element.id');
    }

    var $chartLink = chartLink.copyWith(elementId: element.id);
    await session.db.updateRow<ChartLink>(
      $chartLink,
      columns: [ChartLink.t.elementId],
      transaction: transaction,
    );
  }
}
