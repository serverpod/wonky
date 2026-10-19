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
import '../../../slides/models/rows/enums/table_dimension.dart' as _ibo86twl;
import '../../../slides/models/rows/slide_element.dart' as _ip9zwo22;

/// A row or column of a table element (Slides 02 §3.6), like Sheets'
/// rows/columns so concurrent structure edits merge.
abstract class SlideTableAxis
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  SlideTableAxis._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.elementId,
    this.element,
    required this.dimension,
    required this.sortKey,
    this.size,
    bool? header,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       header = header ?? false,
       createdAt = createdAt ?? DateTime.now();

  factory SlideTableAxis({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required _ibo86twl.TableDimension dimension,
    required String sortKey,
    double? size,
    bool? header,
    DateTime? createdAt,
  }) = _SlideTableAxisImpl;

  factory SlideTableAxis.fromJson(Map<String, dynamic> jsonSerialization) {
    return SlideTableAxis(
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
      dimension: _ibo86twl.TableDimension.fromJson(
        (jsonSerialization['dimension'] as String),
      ),
      sortKey: jsonSerialization['sortKey'] as String,
      size: (jsonSerialization['size'] as num?)?.toDouble(),
      header: jsonSerialization['header'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['header']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = SlideTableAxisTable();

  static const db = SlideTableAxisRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue elementId;

  /// The table element (kind table).
  _ip9zwo22.SlideElement? element;

  _ibo86twl.TableDimension dimension;

  /// Order among the axes of one table and dimension.
  String sortKey;

  /// su; row: min height (rows grow to fit text); null = even split.
  double? size;

  /// Header row / first column styling (05 §2.8).
  bool header;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [SlideTableAxis]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SlideTableAxis copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSlideTableAxis$file(),
    int? revision,
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedSlideTableAxis$element(),
    _ibo86twl.TableDimension? dimension,
    String? sortKey,
    double? size,
    bool? header,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SlideTableAxis',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'elementId': elementId.toJson(),
      if (element != null) 'element': element?.toJson(),
      'dimension': dimension.toJson(),
      'sortKey': sortKey,
      if (size != null) 'size': size,
      'header': header,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SlideTableAxisInclude include({
    _imcki4bb.RevFileInclude? file,
    _ip9zwo22.SlideElementInclude? element,
  }) {
    return SlideTableAxisInclude._(
      file: file,
      element: element,
    );
  }

  static SlideTableAxisIncludeList includeList({
    _is.WhereExpressionBuilder<SlideTableAxisTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideTableAxisTable>? orderBy,
    _is.OrderByListBuilder<SlideTableAxisTable>? orderByList,
    SlideTableAxisInclude? include,
  }) {
    return SlideTableAxisIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SlideTableAxis.t),
      orderByList: orderByList?.call(SlideTableAxis.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedSlideTableAxis$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedSlideTableAxis$file();
}

class _UndefinedSlideTableAxis$element extends _is.UndefinedSentinel
    implements _ip9zwo22.SlideElement {
  const _UndefinedSlideTableAxis$element();
}

class _SlideTableAxisImpl extends SlideTableAxis {
  _SlideTableAxisImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required _ibo86twl.TableDimension dimension,
    required String sortKey,
    double? size,
    bool? header,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         elementId: elementId,
         element: element,
         dimension: dimension,
         sortKey: sortKey,
         size: size,
         header: header,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SlideTableAxis]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SlideTableAxis copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSlideTableAxis$file(),
    int? revision,
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedSlideTableAxis$element(),
    _ibo86twl.TableDimension? dimension,
    String? sortKey,
    Object? size = _Undefined,
    bool? header,
    DateTime? createdAt,
  }) {
    return SlideTableAxis(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      elementId: elementId ?? this.elementId,
      element: element is _is.UndefinedSentinel
          ? this.element?.copyWith()
          : element,
      dimension: dimension ?? this.dimension,
      sortKey: sortKey ?? this.sortKey,
      size: size is double? ? size : this.size,
      header: header ?? this.header,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SlideTableAxisUpdateTable extends _is.UpdateTable<SlideTableAxisTable> {
  SlideTableAxisUpdateTable(super.table);

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

  _is.ColumnValue<_ibo86twl.TableDimension, _ibo86twl.TableDimension> dimension(
    _ibo86twl.TableDimension value,
  ) => _is.ColumnValue(
    table.dimension,
    value,
  );

  _is.ColumnValue<String, String> sortKey(String value) => _is.ColumnValue(
    table.sortKey,
    value,
  );

  _is.ColumnValue<double, double> size(double? value) => _is.ColumnValue(
    table.size,
    value,
  );

  _is.ColumnValue<bool, bool> header(bool value) => _is.ColumnValue(
    table.header,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class SlideTableAxisTable extends _is.Table<_is.UuidValue> {
  SlideTableAxisTable({super.tableRelation})
    : super(tableName: 'slide_table_axis') {
    updateTable = SlideTableAxisUpdateTable(this);
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
    dimension = _is.ColumnEnum(
      'dimension',
      this,
      _is.EnumSerialization.byName,
    );
    sortKey = _is.ColumnString(
      'sortKey',
      this,
    );
    size = _is.ColumnDouble(
      'size',
      this,
    );
    header = _is.ColumnBool(
      'header',
      this,
      hasDefault: true,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final SlideTableAxisUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid elementId;

  /// The table element (kind table).
  _ip9zwo22.SlideElementTable? _element;

  late final _is.ColumnEnum<_ibo86twl.TableDimension> dimension;

  /// Order among the axes of one table and dimension.
  late final _is.ColumnString sortKey;

  /// su; row: min height (rows grow to fit text); null = even split.
  late final _is.ColumnDouble size;

  /// Header row / first column styling (05 §2.8).
  late final _is.ColumnBool header;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: SlideTableAxis.t.fileId,
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
      field: SlideTableAxis.t.elementId,
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
    dimension,
    sortKey,
    size,
    header,
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

class SlideTableAxisInclude extends _is.IncludeObject {
  SlideTableAxisInclude._({
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
  _is.Table<_is.UuidValue> get table => SlideTableAxis.t;
}

class SlideTableAxisIncludeList extends _is.IncludeList {
  SlideTableAxisIncludeList._({
    _is.WhereExpressionBuilder<SlideTableAxisTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SlideTableAxis.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => SlideTableAxis.t;
}

class SlideTableAxisRepository {
  const SlideTableAxisRepository._();

  final attachRow = const SlideTableAxisAttachRowRepository._();

  /// Returns a list of [SlideTableAxis]s matching the given query parameters.
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
  Future<List<SlideTableAxis>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideTableAxisTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideTableAxisTable>? orderBy,
    _is.OrderByListBuilder<SlideTableAxisTable>? orderByList,
    _is.Transaction? transaction,
    SlideTableAxisInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SlideTableAxis>(
      where: where?.call(SlideTableAxis.t),
      orderBy: orderBy?.call(SlideTableAxis.t),
      orderByList: orderByList?.call(SlideTableAxis.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [SlideTableAxis]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `SlideTableAxis.t`.
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
  _ida.Stream<List<SlideTableAxis>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideTableAxisTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideTableAxisTable>? orderBy,
    _is.OrderByListBuilder<SlideTableAxisTable>? orderByList,
    SlideTableAxisInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<SlideTableAxis>(
      where: where?.call(SlideTableAxis.t),
      orderBy: orderBy?.call(SlideTableAxis.t),
      orderByList: orderByList?.call(SlideTableAxis.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [SlideTableAxis] matching the given query parameters.
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
  Future<SlideTableAxis?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideTableAxisTable>? where,
    int? offset,
    _is.OrderByBuilder<SlideTableAxisTable>? orderBy,
    _is.OrderByListBuilder<SlideTableAxisTable>? orderByList,
    _is.Transaction? transaction,
    SlideTableAxisInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SlideTableAxis>(
      where: where?.call(SlideTableAxis.t),
      orderBy: orderBy?.call(SlideTableAxis.t),
      orderByList: orderByList?.call(SlideTableAxis.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SlideTableAxis] by its [id] or null if no such row exists.
  Future<SlideTableAxis?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    SlideTableAxisInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SlideTableAxis>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SlideTableAxis]s in the list and returns the inserted rows.
  ///
  /// The returned [SlideTableAxis]s will have their `id` fields set.
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
  Future<List<SlideTableAxis>> insert(
    _is.DatabaseSession session,
    List<SlideTableAxis> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SlideTableAxis>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SlideTableAxis] and returns the inserted row.
  ///
  /// The returned [SlideTableAxis] will have its `id` field set.
  Future<SlideTableAxis> insertRow(
    _is.DatabaseSession session,
    SlideTableAxis row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SlideTableAxis>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SlideTableAxis]s in the list and returns the resulting rows.
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
  /// The returned [SlideTableAxis]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideTableAxis>> upsert(
    _is.DatabaseSession session,
    List<SlideTableAxis> rows, {
    required _is.ColumnSelections<SlideTableAxisTable> conflictColumns,
    _is.ColumnSelections<SlideTableAxisTable>? updateColumns,
    _is.WhereExpressionBuilder<SlideTableAxisTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SlideTableAxis>(
      rows,
      conflictColumns: conflictColumns(SlideTableAxis.t),
      updateColumns: updateColumns?.call(SlideTableAxis.t),
      updateWhere: updateWhere?.call(SlideTableAxis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SlideTableAxis] and returns the resulting row.
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
  /// The returned [SlideTableAxis] will have its `id` field set.
  Future<SlideTableAxis?> upsertRow(
    _is.DatabaseSession session,
    SlideTableAxis row, {
    required _is.ColumnSelections<SlideTableAxisTable> conflictColumns,
    _is.ColumnSelections<SlideTableAxisTable>? updateColumns,
    _is.WhereExpressionBuilder<SlideTableAxisTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SlideTableAxis>(
      row,
      conflictColumns: conflictColumns(SlideTableAxis.t),
      updateColumns: updateColumns?.call(SlideTableAxis.t),
      updateWhere: updateWhere?.call(SlideTableAxis.t),
      transaction: transaction,
    );
  }

  /// Updates all [SlideTableAxis]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideTableAxis>> update(
    _is.DatabaseSession session,
    List<SlideTableAxis> rows, {
    _is.ColumnSelections<SlideTableAxisTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SlideTableAxis>(
      rows,
      columns: columns?.call(SlideTableAxis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SlideTableAxis]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SlideTableAxis> updateRow(
    _is.DatabaseSession session,
    SlideTableAxis row, {
    _is.ColumnSelections<SlideTableAxisTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SlideTableAxis>(
      row,
      columns: columns?.call(SlideTableAxis.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SlideTableAxis] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SlideTableAxis?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<SlideTableAxisUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SlideTableAxis>(
      id,
      columnValues: columnValues(SlideTableAxis.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SlideTableAxis]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideTableAxis>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SlideTableAxisUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SlideTableAxisTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideTableAxisTable>? orderBy,
    _is.OrderByListBuilder<SlideTableAxisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SlideTableAxis>(
      columnValues: columnValues(SlideTableAxis.t.updateTable),
      where: where(SlideTableAxis.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SlideTableAxis.t),
      orderByList: orderByList?.call(SlideTableAxis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SlideTableAxis]s in the list and returns the deleted rows.
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
  Future<List<SlideTableAxis>> delete(
    _is.DatabaseSession session,
    List<SlideTableAxis> rows, {
    _is.OrderByBuilder<SlideTableAxisTable>? orderBy,
    _is.OrderByListBuilder<SlideTableAxisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SlideTableAxis>(
      rows,
      orderBy: orderBy?.call(SlideTableAxis.t),
      orderByList: orderByList?.call(SlideTableAxis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SlideTableAxis].
  Future<SlideTableAxis> deleteRow(
    _is.DatabaseSession session,
    SlideTableAxis row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SlideTableAxis>(
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
  Future<List<SlideTableAxis>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SlideTableAxisTable> where,
    _is.OrderByBuilder<SlideTableAxisTable>? orderBy,
    _is.OrderByListBuilder<SlideTableAxisTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SlideTableAxis>(
      where: where(SlideTableAxis.t),
      orderBy: orderBy?.call(SlideTableAxis.t),
      orderByList: orderByList?.call(SlideTableAxis.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideTableAxisTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SlideTableAxis>(
      where: where?.call(SlideTableAxis.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SlideTableAxis] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SlideTableAxisTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SlideTableAxis>(
      where: where(SlideTableAxis.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SlideTableAxisAttachRowRepository {
  const SlideTableAxisAttachRowRepository._();

  /// Creates a relation between the given [SlideTableAxis] and [RevFile]
  /// by setting the [SlideTableAxis]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    SlideTableAxis slideTableAxis,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (slideTableAxis.id == null) {
      throw ArgumentError.notNull('slideTableAxis.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $slideTableAxis = slideTableAxis.copyWith(fileId: file.id);
    await session.db.updateRow<SlideTableAxis>(
      $slideTableAxis,
      columns: [SlideTableAxis.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideTableAxis] and [SlideElement]
  /// by setting the [SlideTableAxis]'s foreign key `elementId` to refer to the [SlideElement].
  Future<void> element(
    _is.DatabaseSession session,
    SlideTableAxis slideTableAxis,
    _ip9zwo22.SlideElement element, {
    _is.Transaction? transaction,
  }) async {
    if (slideTableAxis.id == null) {
      throw ArgumentError.notNull('slideTableAxis.id');
    }
    if (element.id == null) {
      throw ArgumentError.notNull('element.id');
    }

    var $slideTableAxis = slideTableAxis.copyWith(elementId: element.id);
    await session.db.updateRow<SlideTableAxis>(
      $slideTableAxis,
      columns: [SlideTableAxis.t.elementId],
      transaction: transaction,
    );
  }
}
