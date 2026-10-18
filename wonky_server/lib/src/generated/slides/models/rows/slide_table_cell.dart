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
import '../../../slides/models/rows/slide_table_axis.dart' as _i18qvmsz;

/// A non-empty table cell (Slides 02 §3.6). Its id is always
/// SlidesIds.tableCellId(elementId, rowId, columnId), so concurrent writers of
/// the same cell share one row (per-column merge). Exists iff a field is set.
abstract class SlideTableCell
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  SlideTableCell._({
    _is.UuidValue? id,
    required this.fileId,
    this.file,
    int? revision,
    required this.elementId,
    this.element,
    required this.rowId,
    this.row,
    required this.columnId,
    this.column,
    this.text,
    this.fill,
    this.borderTop,
    this.borderRight,
    this.borderBottom,
    this.borderLeft,
    this.vAlign,
    this.padding,
    this.rowSpan,
    this.colSpan,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory SlideTableCell({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required _is.UuidValue rowId,
    _i18qvmsz.SlideTableAxis? row,
    required _is.UuidValue columnId,
    _i18qvmsz.SlideTableAxis? column,
    String? text,
    String? fill,
    String? borderTop,
    String? borderRight,
    String? borderBottom,
    String? borderLeft,
    String? vAlign,
    String? padding,
    int? rowSpan,
    int? colSpan,
    DateTime? createdAt,
  }) = _SlideTableCellImpl;

  factory SlideTableCell.fromJson(Map<String, dynamic> jsonSerialization) {
    return SlideTableCell(
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
      rowId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['rowId']),
      row: jsonSerialization['row'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_i18qvmsz.SlideTableAxis>(
              jsonSerialization['row'],
            ),
      columnId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['columnId'],
      ),
      column: jsonSerialization['column'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_i18qvmsz.SlideTableAxis>(
              jsonSerialization['column'],
            ),
      text: jsonSerialization['text'] as String?,
      fill: jsonSerialization['fill'] as String?,
      borderTop: jsonSerialization['borderTop'] as String?,
      borderRight: jsonSerialization['borderRight'] as String?,
      borderBottom: jsonSerialization['borderBottom'] as String?,
      borderLeft: jsonSerialization['borderLeft'] as String?,
      vAlign: jsonSerialization['vAlign'] as String?,
      padding: jsonSerialization['padding'] as String?,
      rowSpan: jsonSerialization['rowSpan'] as int?,
      colSpan: jsonSerialization['colSpan'] as int?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = SlideTableCellTable();

  static const db = SlideTableCellRepository._();

  @override
  _is.UuidValue id;

  int fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFile? file;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue elementId;

  _ip9zwo22.SlideElement? element;

  _is.UuidValue rowId;

  _i18qvmsz.SlideTableAxis? row;

  _is.UuidValue columnId;

  _i18qvmsz.SlideTableAxis? column;

  /// Rich text Delta (02 §4).
  String? text;

  /// ColorRef.
  String? fill;

  /// "<width>|<style>|<ColorRef>", style: solid, dashed, dotted, none.
  String? borderTop;

  String? borderRight;

  String? borderBottom;

  String? borderLeft;

  /// top, middle, bottom.
  String? vAlign;

  /// "t,r,b,l" in su.
  String? padding;

  /// Merge origin only; null = 1.
  int? rowSpan;

  int? colSpan;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [SlideTableCell]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  SlideTableCell copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSlideTableCell$file(),
    int? revision,
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedSlideTableCell$element(),
    _is.UuidValue? rowId,
    _i18qvmsz.SlideTableAxis? row = const _UndefinedSlideTableCell$row(),
    _is.UuidValue? columnId,
    _i18qvmsz.SlideTableAxis? column = const _UndefinedSlideTableCell$row(),
    String? text,
    String? fill,
    String? borderTop,
    String? borderRight,
    String? borderBottom,
    String? borderLeft,
    String? vAlign,
    String? padding,
    int? rowSpan,
    int? colSpan,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SlideTableCell',
      'id': id.toJson(),
      'fileId': fileId,
      if (file != null) 'file': file?.toJson(),
      'revision': revision,
      'elementId': elementId.toJson(),
      if (element != null) 'element': element?.toJson(),
      'rowId': rowId.toJson(),
      if (row != null) 'row': row?.toJson(),
      'columnId': columnId.toJson(),
      if (column != null) 'column': column?.toJson(),
      if (text != null) 'text': text,
      if (fill != null) 'fill': fill,
      if (borderTop != null) 'borderTop': borderTop,
      if (borderRight != null) 'borderRight': borderRight,
      if (borderBottom != null) 'borderBottom': borderBottom,
      if (borderLeft != null) 'borderLeft': borderLeft,
      if (vAlign != null) 'vAlign': vAlign,
      if (padding != null) 'padding': padding,
      if (rowSpan != null) 'rowSpan': rowSpan,
      if (colSpan != null) 'colSpan': colSpan,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static SlideTableCellInclude include({
    _imcki4bb.RevFileInclude? file,
    _ip9zwo22.SlideElementInclude? element,
    _i18qvmsz.SlideTableAxisInclude? row,
    _i18qvmsz.SlideTableAxisInclude? column,
  }) {
    return SlideTableCellInclude._(
      file: file,
      element: element,
      row: row,
      column: column,
    );
  }

  static SlideTableCellIncludeList includeList({
    _is.WhereExpressionBuilder<SlideTableCellTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideTableCellTable>? orderBy,
    _is.OrderByListBuilder<SlideTableCellTable>? orderByList,
    SlideTableCellInclude? include,
  }) {
    return SlideTableCellIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SlideTableCell.t),
      orderByList: orderByList?.call(SlideTableCell.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedSlideTableCell$file extends _is.UndefinedSentinel
    implements _imcki4bb.RevFile {
  const _UndefinedSlideTableCell$file();
}

class _UndefinedSlideTableCell$element extends _is.UndefinedSentinel
    implements _ip9zwo22.SlideElement {
  const _UndefinedSlideTableCell$element();
}

class _UndefinedSlideTableCell$row extends _is.UndefinedSentinel
    implements _i18qvmsz.SlideTableAxis {
  const _UndefinedSlideTableCell$row();
}

class _SlideTableCellImpl extends SlideTableCell {
  _SlideTableCellImpl({
    _is.UuidValue? id,
    required int fileId,
    _imcki4bb.RevFile? file,
    int? revision,
    required _is.UuidValue elementId,
    _ip9zwo22.SlideElement? element,
    required _is.UuidValue rowId,
    _i18qvmsz.SlideTableAxis? row,
    required _is.UuidValue columnId,
    _i18qvmsz.SlideTableAxis? column,
    String? text,
    String? fill,
    String? borderTop,
    String? borderRight,
    String? borderBottom,
    String? borderLeft,
    String? vAlign,
    String? padding,
    int? rowSpan,
    int? colSpan,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         file: file,
         revision: revision,
         elementId: elementId,
         element: element,
         rowId: rowId,
         row: row,
         columnId: columnId,
         column: column,
         text: text,
         fill: fill,
         borderTop: borderTop,
         borderRight: borderRight,
         borderBottom: borderBottom,
         borderLeft: borderLeft,
         vAlign: vAlign,
         padding: padding,
         rowSpan: rowSpan,
         colSpan: colSpan,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SlideTableCell]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  SlideTableCell copyWith({
    _is.UuidValue? id,
    int? fileId,
    _imcki4bb.RevFile? file = const _UndefinedSlideTableCell$file(),
    int? revision,
    _is.UuidValue? elementId,
    _ip9zwo22.SlideElement? element = const _UndefinedSlideTableCell$element(),
    _is.UuidValue? rowId,
    _i18qvmsz.SlideTableAxis? row = const _UndefinedSlideTableCell$row(),
    _is.UuidValue? columnId,
    _i18qvmsz.SlideTableAxis? column = const _UndefinedSlideTableCell$row(),
    Object? text = _Undefined,
    Object? fill = _Undefined,
    Object? borderTop = _Undefined,
    Object? borderRight = _Undefined,
    Object? borderBottom = _Undefined,
    Object? borderLeft = _Undefined,
    Object? vAlign = _Undefined,
    Object? padding = _Undefined,
    Object? rowSpan = _Undefined,
    Object? colSpan = _Undefined,
    DateTime? createdAt,
  }) {
    return SlideTableCell(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      file: file is _is.UndefinedSentinel ? this.file?.copyWith() : file,
      revision: revision ?? this.revision,
      elementId: elementId ?? this.elementId,
      element: element is _is.UndefinedSentinel
          ? this.element?.copyWith()
          : element,
      rowId: rowId ?? this.rowId,
      row: row is _is.UndefinedSentinel ? this.row?.copyWith() : row,
      columnId: columnId ?? this.columnId,
      column: column is _is.UndefinedSentinel
          ? this.column?.copyWith()
          : column,
      text: text is String? ? text : this.text,
      fill: fill is String? ? fill : this.fill,
      borderTop: borderTop is String? ? borderTop : this.borderTop,
      borderRight: borderRight is String? ? borderRight : this.borderRight,
      borderBottom: borderBottom is String? ? borderBottom : this.borderBottom,
      borderLeft: borderLeft is String? ? borderLeft : this.borderLeft,
      vAlign: vAlign is String? ? vAlign : this.vAlign,
      padding: padding is String? ? padding : this.padding,
      rowSpan: rowSpan is int? ? rowSpan : this.rowSpan,
      colSpan: colSpan is int? ? colSpan : this.colSpan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SlideTableCellUpdateTable extends _is.UpdateTable<SlideTableCellTable> {
  SlideTableCellUpdateTable(super.table);

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

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> rowId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.rowId,
        value,
      );

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> columnId(_is.UuidValue value) =>
      _is.ColumnValue(
        table.columnId,
        value,
      );

  _is.ColumnValue<String, String> text(String? value) => _is.ColumnValue(
    table.text,
    value,
  );

  _is.ColumnValue<String, String> fill(String? value) => _is.ColumnValue(
    table.fill,
    value,
  );

  _is.ColumnValue<String, String> borderTop(String? value) => _is.ColumnValue(
    table.borderTop,
    value,
  );

  _is.ColumnValue<String, String> borderRight(String? value) => _is.ColumnValue(
    table.borderRight,
    value,
  );

  _is.ColumnValue<String, String> borderBottom(String? value) =>
      _is.ColumnValue(
        table.borderBottom,
        value,
      );

  _is.ColumnValue<String, String> borderLeft(String? value) => _is.ColumnValue(
    table.borderLeft,
    value,
  );

  _is.ColumnValue<String, String> vAlign(String? value) => _is.ColumnValue(
    table.vAlign,
    value,
  );

  _is.ColumnValue<String, String> padding(String? value) => _is.ColumnValue(
    table.padding,
    value,
  );

  _is.ColumnValue<int, int> rowSpan(int? value) => _is.ColumnValue(
    table.rowSpan,
    value,
  );

  _is.ColumnValue<int, int> colSpan(int? value) => _is.ColumnValue(
    table.colSpan,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class SlideTableCellTable extends _is.Table<_is.UuidValue> {
  SlideTableCellTable({super.tableRelation})
    : super(tableName: 'slide_table_cell') {
    updateTable = SlideTableCellUpdateTable(this);
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
    rowId = _is.ColumnUuid(
      'rowId',
      this,
    );
    columnId = _is.ColumnUuid(
      'columnId',
      this,
    );
    text = _is.ColumnString(
      'text',
      this,
    );
    fill = _is.ColumnString(
      'fill',
      this,
    );
    borderTop = _is.ColumnString(
      'borderTop',
      this,
    );
    borderRight = _is.ColumnString(
      'borderRight',
      this,
    );
    borderBottom = _is.ColumnString(
      'borderBottom',
      this,
    );
    borderLeft = _is.ColumnString(
      'borderLeft',
      this,
    );
    vAlign = _is.ColumnString(
      'vAlign',
      this,
    );
    padding = _is.ColumnString(
      'padding',
      this,
    );
    rowSpan = _is.ColumnInt(
      'rowSpan',
      this,
    );
    colSpan = _is.ColumnInt(
      'colSpan',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final SlideTableCellUpdateTable updateTable;

  late final _is.ColumnInt fileId;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1).
  _imcki4bb.RevFileTable? _file;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid elementId;

  _ip9zwo22.SlideElementTable? _element;

  late final _is.ColumnUuid rowId;

  _i18qvmsz.SlideTableAxisTable? _row;

  late final _is.ColumnUuid columnId;

  _i18qvmsz.SlideTableAxisTable? _column;

  /// Rich text Delta (02 §4).
  late final _is.ColumnString text;

  /// ColorRef.
  late final _is.ColumnString fill;

  /// "<width>|<style>|<ColorRef>", style: solid, dashed, dotted, none.
  late final _is.ColumnString borderTop;

  late final _is.ColumnString borderRight;

  late final _is.ColumnString borderBottom;

  late final _is.ColumnString borderLeft;

  /// top, middle, bottom.
  late final _is.ColumnString vAlign;

  /// "t,r,b,l" in su.
  late final _is.ColumnString padding;

  /// Merge origin only; null = 1.
  late final _is.ColumnInt rowSpan;

  late final _is.ColumnInt colSpan;

  late final _is.ColumnDateTime createdAt;

  _imcki4bb.RevFileTable get file {
    if (_file != null) return _file!;
    _file = _is.createRelationTable(
      relationFieldName: 'file',
      field: SlideTableCell.t.fileId,
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
      field: SlideTableCell.t.elementId,
      foreignField: _ip9zwo22.SlideElement.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _ip9zwo22.SlideElementTable(tableRelation: foreignTableRelation),
    );
    return _element!;
  }

  _i18qvmsz.SlideTableAxisTable get row {
    if (_row != null) return _row!;
    _row = _is.createRelationTable(
      relationFieldName: 'row',
      field: SlideTableCell.t.rowId,
      foreignField: _i18qvmsz.SlideTableAxis.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i18qvmsz.SlideTableAxisTable(tableRelation: foreignTableRelation),
    );
    return _row!;
  }

  _i18qvmsz.SlideTableAxisTable get column {
    if (_column != null) return _column!;
    _column = _is.createRelationTable(
      relationFieldName: 'column',
      field: SlideTableCell.t.columnId,
      foreignField: _i18qvmsz.SlideTableAxis.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i18qvmsz.SlideTableAxisTable(tableRelation: foreignTableRelation),
    );
    return _column!;
  }

  @override
  List<_is.Column> get columns => [
    id,
    fileId,
    revision,
    elementId,
    rowId,
    columnId,
    text,
    fill,
    borderTop,
    borderRight,
    borderBottom,
    borderLeft,
    vAlign,
    padding,
    rowSpan,
    colSpan,
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
    if (relationField == 'row') {
      return row;
    }
    if (relationField == 'column') {
      return column;
    }
    return null;
  }
}

class SlideTableCellInclude extends _is.IncludeObject {
  SlideTableCellInclude._({
    _imcki4bb.RevFileInclude? file,
    _ip9zwo22.SlideElementInclude? element,
    _i18qvmsz.SlideTableAxisInclude? row,
    _i18qvmsz.SlideTableAxisInclude? column,
  }) {
    _file = file;
    _element = element;
    _row = row;
    _column = column;
  }

  _imcki4bb.RevFileInclude? _file;

  _ip9zwo22.SlideElementInclude? _element;

  _i18qvmsz.SlideTableAxisInclude? _row;

  _i18qvmsz.SlideTableAxisInclude? _column;

  @override
  Map<String, _is.Include?> get includes => {
    'file': _file,
    'element': _element,
    'row': _row,
    'column': _column,
  };

  @override
  _is.Table<_is.UuidValue> get table => SlideTableCell.t;
}

class SlideTableCellIncludeList extends _is.IncludeList {
  SlideTableCellIncludeList._({
    _is.WhereExpressionBuilder<SlideTableCellTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(SlideTableCell.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => SlideTableCell.t;
}

class SlideTableCellRepository {
  const SlideTableCellRepository._();

  final attachRow = const SlideTableCellAttachRowRepository._();

  /// Returns a list of [SlideTableCell]s matching the given query parameters.
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
  Future<List<SlideTableCell>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideTableCellTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideTableCellTable>? orderBy,
    _is.OrderByListBuilder<SlideTableCellTable>? orderByList,
    _is.Transaction? transaction,
    SlideTableCellInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<SlideTableCell>(
      where: where?.call(SlideTableCell.t),
      orderBy: orderBy?.call(SlideTableCell.t),
      orderByList: orderByList?.call(SlideTableCell.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [SlideTableCell]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `SlideTableCell.t`.
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
  _ida.Stream<List<SlideTableCell>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideTableCellTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideTableCellTable>? orderBy,
    _is.OrderByListBuilder<SlideTableCellTable>? orderByList,
    SlideTableCellInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<SlideTableCell>(
      where: where?.call(SlideTableCell.t),
      orderBy: orderBy?.call(SlideTableCell.t),
      orderByList: orderByList?.call(SlideTableCell.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [SlideTableCell] matching the given query parameters.
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
  Future<SlideTableCell?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideTableCellTable>? where,
    int? offset,
    _is.OrderByBuilder<SlideTableCellTable>? orderBy,
    _is.OrderByListBuilder<SlideTableCellTable>? orderByList,
    _is.Transaction? transaction,
    SlideTableCellInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<SlideTableCell>(
      where: where?.call(SlideTableCell.t),
      orderBy: orderBy?.call(SlideTableCell.t),
      orderByList: orderByList?.call(SlideTableCell.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [SlideTableCell] by its [id] or null if no such row exists.
  Future<SlideTableCell?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    SlideTableCellInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<SlideTableCell>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [SlideTableCell]s in the list and returns the inserted rows.
  ///
  /// The returned [SlideTableCell]s will have their `id` fields set.
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
  Future<List<SlideTableCell>> insert(
    _is.DatabaseSession session,
    List<SlideTableCell> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<SlideTableCell>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [SlideTableCell] and returns the inserted row.
  ///
  /// The returned [SlideTableCell] will have its `id` field set.
  Future<SlideTableCell> insertRow(
    _is.DatabaseSession session,
    SlideTableCell row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<SlideTableCell>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [SlideTableCell]s in the list and returns the resulting rows.
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
  /// The returned [SlideTableCell]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideTableCell>> upsert(
    _is.DatabaseSession session,
    List<SlideTableCell> rows, {
    required _is.ColumnSelections<SlideTableCellTable> conflictColumns,
    _is.ColumnSelections<SlideTableCellTable>? updateColumns,
    _is.WhereExpressionBuilder<SlideTableCellTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<SlideTableCell>(
      rows,
      conflictColumns: conflictColumns(SlideTableCell.t),
      updateColumns: updateColumns?.call(SlideTableCell.t),
      updateWhere: updateWhere?.call(SlideTableCell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [SlideTableCell] and returns the resulting row.
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
  /// The returned [SlideTableCell] will have its `id` field set.
  Future<SlideTableCell?> upsertRow(
    _is.DatabaseSession session,
    SlideTableCell row, {
    required _is.ColumnSelections<SlideTableCellTable> conflictColumns,
    _is.ColumnSelections<SlideTableCellTable>? updateColumns,
    _is.WhereExpressionBuilder<SlideTableCellTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<SlideTableCell>(
      row,
      conflictColumns: conflictColumns(SlideTableCell.t),
      updateColumns: updateColumns?.call(SlideTableCell.t),
      updateWhere: updateWhere?.call(SlideTableCell.t),
      transaction: transaction,
    );
  }

  /// Updates all [SlideTableCell]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideTableCell>> update(
    _is.DatabaseSession session,
    List<SlideTableCell> rows, {
    _is.ColumnSelections<SlideTableCellTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<SlideTableCell>(
      rows,
      columns: columns?.call(SlideTableCell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [SlideTableCell]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<SlideTableCell> updateRow(
    _is.DatabaseSession session,
    SlideTableCell row, {
    _is.ColumnSelections<SlideTableCellTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<SlideTableCell>(
      row,
      columns: columns?.call(SlideTableCell.t),
      transaction: transaction,
    );
  }

  /// Updates a single [SlideTableCell] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<SlideTableCell?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<SlideTableCellUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<SlideTableCell>(
      id,
      columnValues: columnValues(SlideTableCell.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [SlideTableCell]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<SlideTableCell>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<SlideTableCellUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<SlideTableCellTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<SlideTableCellTable>? orderBy,
    _is.OrderByListBuilder<SlideTableCellTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<SlideTableCell>(
      columnValues: columnValues(SlideTableCell.t.updateTable),
      where: where(SlideTableCell.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(SlideTableCell.t),
      orderByList: orderByList?.call(SlideTableCell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [SlideTableCell]s in the list and returns the deleted rows.
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
  Future<List<SlideTableCell>> delete(
    _is.DatabaseSession session,
    List<SlideTableCell> rows, {
    _is.OrderByBuilder<SlideTableCellTable>? orderBy,
    _is.OrderByListBuilder<SlideTableCellTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<SlideTableCell>(
      rows,
      orderBy: orderBy?.call(SlideTableCell.t),
      orderByList: orderByList?.call(SlideTableCell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [SlideTableCell].
  Future<SlideTableCell> deleteRow(
    _is.DatabaseSession session,
    SlideTableCell row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<SlideTableCell>(
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
  Future<List<SlideTableCell>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SlideTableCellTable> where,
    _is.OrderByBuilder<SlideTableCellTable>? orderBy,
    _is.OrderByListBuilder<SlideTableCellTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<SlideTableCell>(
      where: where(SlideTableCell.t),
      orderBy: orderBy?.call(SlideTableCell.t),
      orderByList: orderByList?.call(SlideTableCell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<SlideTableCellTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<SlideTableCell>(
      where: where?.call(SlideTableCell.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [SlideTableCell] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<SlideTableCellTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<SlideTableCell>(
      where: where(SlideTableCell.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class SlideTableCellAttachRowRepository {
  const SlideTableCellAttachRowRepository._();

  /// Creates a relation between the given [SlideTableCell] and [RevFile]
  /// by setting the [SlideTableCell]'s foreign key `fileId` to refer to the [RevFile].
  Future<void> file(
    _is.DatabaseSession session,
    SlideTableCell slideTableCell,
    _imcki4bb.RevFile file, {
    _is.Transaction? transaction,
  }) async {
    if (slideTableCell.id == null) {
      throw ArgumentError.notNull('slideTableCell.id');
    }
    if (file.id == null) {
      throw ArgumentError.notNull('file.id');
    }

    var $slideTableCell = slideTableCell.copyWith(fileId: file.id);
    await session.db.updateRow<SlideTableCell>(
      $slideTableCell,
      columns: [SlideTableCell.t.fileId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideTableCell] and [SlideElement]
  /// by setting the [SlideTableCell]'s foreign key `elementId` to refer to the [SlideElement].
  Future<void> element(
    _is.DatabaseSession session,
    SlideTableCell slideTableCell,
    _ip9zwo22.SlideElement element, {
    _is.Transaction? transaction,
  }) async {
    if (slideTableCell.id == null) {
      throw ArgumentError.notNull('slideTableCell.id');
    }
    if (element.id == null) {
      throw ArgumentError.notNull('element.id');
    }

    var $slideTableCell = slideTableCell.copyWith(elementId: element.id);
    await session.db.updateRow<SlideTableCell>(
      $slideTableCell,
      columns: [SlideTableCell.t.elementId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideTableCell] and [SlideTableAxis]
  /// by setting the [SlideTableCell]'s foreign key `rowId` to refer to the [SlideTableAxis].
  Future<void> row(
    _is.DatabaseSession session,
    SlideTableCell slideTableCell,
    _i18qvmsz.SlideTableAxis row, {
    _is.Transaction? transaction,
  }) async {
    if (slideTableCell.id == null) {
      throw ArgumentError.notNull('slideTableCell.id');
    }
    if (row.id == null) {
      throw ArgumentError.notNull('row.id');
    }

    var $slideTableCell = slideTableCell.copyWith(rowId: row.id);
    await session.db.updateRow<SlideTableCell>(
      $slideTableCell,
      columns: [SlideTableCell.t.rowId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [SlideTableCell] and [SlideTableAxis]
  /// by setting the [SlideTableCell]'s foreign key `columnId` to refer to the [SlideTableAxis].
  Future<void> column(
    _is.DatabaseSession session,
    SlideTableCell slideTableCell,
    _i18qvmsz.SlideTableAxis column, {
    _is.Transaction? transaction,
  }) async {
    if (slideTableCell.id == null) {
      throw ArgumentError.notNull('slideTableCell.id');
    }
    if (column.id == null) {
      throw ArgumentError.notNull('column.id');
    }

    var $slideTableCell = slideTableCell.copyWith(columnId: column.id);
    await session.db.updateRow<SlideTableCell>(
      $slideTableCell,
      columns: [SlideTableCell.t.columnId],
      transaction: transaction,
    );
  }
}
