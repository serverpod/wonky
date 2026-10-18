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
import '../../../sheets/models/rows/enums/horizontal_align.dart' as _id5xe3zl;
import '../../../sheets/models/rows/enums/vertical_align.dart' as _i4hmikpl;
import '../../../sheets/models/rows/enums/wrap_strategy.dart' as _iprlvb3g;
import '../../../sheets/models/rows/sheet.dart' as _ij40k88n;

/// A non-empty cell. Its id is always SheetsIds.cellId(sheetId, rowId, colId), so
/// concurrent writers of the same cell write the same row. Every format
/// attribute is its own column (field-level merge).
abstract class Cell
    implements _is.TableRow<_is.UuidValue>, _is.ProtocolSerialization {
  Cell._({
    _is.UuidValue? id,
    required this.fileId,
    int? revision,
    required this.sheetId,
    this.sheet,
    required this.rowId,
    required this.columnId,
    this.content,
    this.note,
    this.numberFormat,
    this.fontFamily,
    this.fontSize,
    this.bold,
    this.italic,
    this.underline,
    this.strikethrough,
    this.textColor,
    this.fillColor,
    this.hAlign,
    this.vAlign,
    this.wrap,
    this.rotation,
    this.borderTop,
    this.borderRight,
    this.borderBottom,
    this.borderLeft,
    this.linkUrl,
    DateTime? createdAt,
  }) : id = id ?? const _is.Uuid().v7obj(),
       revision = revision ?? 0,
       createdAt = createdAt ?? DateTime.now();

  factory Cell({
    _is.UuidValue? id,
    required int fileId,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required _is.UuidValue rowId,
    required _is.UuidValue columnId,
    String? content,
    String? note,
    String? numberFormat,
    String? fontFamily,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? textColor,
    String? fillColor,
    _id5xe3zl.HorizontalAlign? hAlign,
    _i4hmikpl.VerticalAlign? vAlign,
    _iprlvb3g.WrapStrategy? wrap,
    int? rotation,
    String? borderTop,
    String? borderRight,
    String? borderBottom,
    String? borderLeft,
    String? linkUrl,
    DateTime? createdAt,
  }) = _CellImpl;

  factory Cell.fromJson(Map<String, dynamic> jsonSerialization) {
    return Cell(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      fileId: jsonSerialization['fileId'] as int,
      revision: jsonSerialization['revision'] as int?,
      sheetId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['sheetId'],
      ),
      sheet: jsonSerialization['sheet'] == null
          ? null
          : _il4umwa0.Protocol().deserialize<_ij40k88n.Sheet>(
              jsonSerialization['sheet'],
            ),
      rowId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['rowId']),
      columnId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['columnId'],
      ),
      content: jsonSerialization['content'] as String?,
      note: jsonSerialization['note'] as String?,
      numberFormat: jsonSerialization['numberFormat'] as String?,
      fontFamily: jsonSerialization['fontFamily'] as String?,
      fontSize: (jsonSerialization['fontSize'] as num?)?.toDouble(),
      bold: jsonSerialization['bold'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['bold']),
      italic: jsonSerialization['italic'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['italic']),
      underline: jsonSerialization['underline'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['underline']),
      strikethrough: jsonSerialization['strikethrough'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['strikethrough']),
      textColor: jsonSerialization['textColor'] as String?,
      fillColor: jsonSerialization['fillColor'] as String?,
      hAlign: jsonSerialization['hAlign'] == null
          ? null
          : _id5xe3zl.HorizontalAlign.fromJson(
              (jsonSerialization['hAlign'] as String),
            ),
      vAlign: jsonSerialization['vAlign'] == null
          ? null
          : _i4hmikpl.VerticalAlign.fromJson(
              (jsonSerialization['vAlign'] as String),
            ),
      wrap: jsonSerialization['wrap'] == null
          ? null
          : _iprlvb3g.WrapStrategy.fromJson(
              (jsonSerialization['wrap'] as String),
            ),
      rotation: jsonSerialization['rotation'] as int?,
      borderTop: jsonSerialization['borderTop'] as String?,
      borderRight: jsonSerialization['borderRight'] as String?,
      borderBottom: jsonSerialization['borderBottom'] as String?,
      borderLeft: jsonSerialization['borderLeft'] as String?,
      linkUrl: jsonSerialization['linkUrl'] as String?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
    );
  }

  static final t = CellTable();

  static const db = CellRepository._();

  @override
  _is.UuidValue id;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1). Plain, no
  /// foreign key: cells are never read or deleted by file (02 §2.2), and a
  /// key would make deleting a rev_file scan the cell table.
  int fileId;

  /// The revision that last wrote the row.
  int revision;

  _is.UuidValue sheetId;

  _ij40k88n.Sheet? sheet;

  /// Plain id, no DB foreign key: the sequencer cascades cells (02 §2.1).
  _is.UuidValue rowId;

  _is.UuidValue columnId;

  /// Typed encoding (=, n:, s:, b:, e:, r:); null = no value.
  String? content;

  /// Cell note (not a comment).
  String? note;

  String? numberFormat;

  String? fontFamily;

  double? fontSize;

  bool? bold;

  bool? italic;

  bool? underline;

  bool? strikethrough;

  /// "#RRGGBB" or "theme:accent3".
  String? textColor;

  String? fillColor;

  _id5xe3zl.HorizontalAlign? hAlign;

  _i4hmikpl.VerticalAlign? vAlign;

  _iprlvb3g.WrapStrategy? wrap;

  /// -90..90 degrees; 255 = vertical stacked.
  int? rotation;

  /// "<style>|<color>" or "none".
  String? borderTop;

  String? borderRight;

  String? borderBottom;

  String? borderLeft;

  /// Whole-cell hyperlink.
  String? linkUrl;

  DateTime createdAt;

  @override
  _is.Table<_is.UuidValue> get table => t;

  /// Returns a shallow copy of this [Cell]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Cell copyWith({
    _is.UuidValue? id,
    int? fileId,
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedCell$sheet(),
    _is.UuidValue? rowId,
    _is.UuidValue? columnId,
    String? content,
    String? note,
    String? numberFormat,
    String? fontFamily,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? textColor,
    String? fillColor,
    _id5xe3zl.HorizontalAlign? hAlign,
    _i4hmikpl.VerticalAlign? vAlign,
    _iprlvb3g.WrapStrategy? wrap,
    int? rotation,
    String? borderTop,
    String? borderRight,
    String? borderBottom,
    String? borderLeft,
    String? linkUrl,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Cell',
      'id': id.toJson(),
      'fileId': fileId,
      'revision': revision,
      'sheetId': sheetId.toJson(),
      if (sheet != null) 'sheet': sheet?.toJson(),
      'rowId': rowId.toJson(),
      'columnId': columnId.toJson(),
      if (content != null) 'content': content,
      if (note != null) 'note': note,
      if (numberFormat != null) 'numberFormat': numberFormat,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (fontSize != null) 'fontSize': fontSize,
      if (bold != null) 'bold': bold,
      if (italic != null) 'italic': italic,
      if (underline != null) 'underline': underline,
      if (strikethrough != null) 'strikethrough': strikethrough,
      if (textColor != null) 'textColor': textColor,
      if (fillColor != null) 'fillColor': fillColor,
      if (hAlign != null) 'hAlign': hAlign?.toJson(),
      if (vAlign != null) 'vAlign': vAlign?.toJson(),
      if (wrap != null) 'wrap': wrap?.toJson(),
      if (rotation != null) 'rotation': rotation,
      if (borderTop != null) 'borderTop': borderTop,
      if (borderRight != null) 'borderRight': borderRight,
      if (borderBottom != null) 'borderBottom': borderBottom,
      if (borderLeft != null) 'borderLeft': borderLeft,
      if (linkUrl != null) 'linkUrl': linkUrl,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static CellInclude include({_ij40k88n.SheetInclude? sheet}) {
    return CellInclude._(sheet: sheet);
  }

  static CellIncludeList includeList({
    _is.WhereExpressionBuilder<CellTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CellTable>? orderBy,
    _is.OrderByListBuilder<CellTable>? orderByList,
    CellInclude? include,
  }) {
    return CellIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Cell.t),
      orderByList: orderByList?.call(Cell.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UndefinedCell$sheet extends _is.UndefinedSentinel
    implements _ij40k88n.Sheet {
  const _UndefinedCell$sheet();
}

class _CellImpl extends Cell {
  _CellImpl({
    _is.UuidValue? id,
    required int fileId,
    int? revision,
    required _is.UuidValue sheetId,
    _ij40k88n.Sheet? sheet,
    required _is.UuidValue rowId,
    required _is.UuidValue columnId,
    String? content,
    String? note,
    String? numberFormat,
    String? fontFamily,
    double? fontSize,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? textColor,
    String? fillColor,
    _id5xe3zl.HorizontalAlign? hAlign,
    _i4hmikpl.VerticalAlign? vAlign,
    _iprlvb3g.WrapStrategy? wrap,
    int? rotation,
    String? borderTop,
    String? borderRight,
    String? borderBottom,
    String? borderLeft,
    String? linkUrl,
    DateTime? createdAt,
  }) : super._(
         id: id,
         fileId: fileId,
         revision: revision,
         sheetId: sheetId,
         sheet: sheet,
         rowId: rowId,
         columnId: columnId,
         content: content,
         note: note,
         numberFormat: numberFormat,
         fontFamily: fontFamily,
         fontSize: fontSize,
         bold: bold,
         italic: italic,
         underline: underline,
         strikethrough: strikethrough,
         textColor: textColor,
         fillColor: fillColor,
         hAlign: hAlign,
         vAlign: vAlign,
         wrap: wrap,
         rotation: rotation,
         borderTop: borderTop,
         borderRight: borderRight,
         borderBottom: borderBottom,
         borderLeft: borderLeft,
         linkUrl: linkUrl,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Cell]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Cell copyWith({
    _is.UuidValue? id,
    int? fileId,
    int? revision,
    _is.UuidValue? sheetId,
    _ij40k88n.Sheet? sheet = const _UndefinedCell$sheet(),
    _is.UuidValue? rowId,
    _is.UuidValue? columnId,
    Object? content = _Undefined,
    Object? note = _Undefined,
    Object? numberFormat = _Undefined,
    Object? fontFamily = _Undefined,
    Object? fontSize = _Undefined,
    Object? bold = _Undefined,
    Object? italic = _Undefined,
    Object? underline = _Undefined,
    Object? strikethrough = _Undefined,
    Object? textColor = _Undefined,
    Object? fillColor = _Undefined,
    Object? hAlign = _Undefined,
    Object? vAlign = _Undefined,
    Object? wrap = _Undefined,
    Object? rotation = _Undefined,
    Object? borderTop = _Undefined,
    Object? borderRight = _Undefined,
    Object? borderBottom = _Undefined,
    Object? borderLeft = _Undefined,
    Object? linkUrl = _Undefined,
    DateTime? createdAt,
  }) {
    return Cell(
      id: id ?? this.id,
      fileId: fileId ?? this.fileId,
      revision: revision ?? this.revision,
      sheetId: sheetId ?? this.sheetId,
      sheet: sheet is _is.UndefinedSentinel ? this.sheet?.copyWith() : sheet,
      rowId: rowId ?? this.rowId,
      columnId: columnId ?? this.columnId,
      content: content is String? ? content : this.content,
      note: note is String? ? note : this.note,
      numberFormat: numberFormat is String? ? numberFormat : this.numberFormat,
      fontFamily: fontFamily is String? ? fontFamily : this.fontFamily,
      fontSize: fontSize is double? ? fontSize : this.fontSize,
      bold: bold is bool? ? bold : this.bold,
      italic: italic is bool? ? italic : this.italic,
      underline: underline is bool? ? underline : this.underline,
      strikethrough: strikethrough is bool?
          ? strikethrough
          : this.strikethrough,
      textColor: textColor is String? ? textColor : this.textColor,
      fillColor: fillColor is String? ? fillColor : this.fillColor,
      hAlign: hAlign is _id5xe3zl.HorizontalAlign? ? hAlign : this.hAlign,
      vAlign: vAlign is _i4hmikpl.VerticalAlign? ? vAlign : this.vAlign,
      wrap: wrap is _iprlvb3g.WrapStrategy? ? wrap : this.wrap,
      rotation: rotation is int? ? rotation : this.rotation,
      borderTop: borderTop is String? ? borderTop : this.borderTop,
      borderRight: borderRight is String? ? borderRight : this.borderRight,
      borderBottom: borderBottom is String? ? borderBottom : this.borderBottom,
      borderLeft: borderLeft is String? ? borderLeft : this.borderLeft,
      linkUrl: linkUrl is String? ? linkUrl : this.linkUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CellUpdateTable extends _is.UpdateTable<CellTable> {
  CellUpdateTable(super.table);

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

  _is.ColumnValue<String, String> content(String? value) => _is.ColumnValue(
    table.content,
    value,
  );

  _is.ColumnValue<String, String> note(String? value) => _is.ColumnValue(
    table.note,
    value,
  );

  _is.ColumnValue<String, String> numberFormat(String? value) =>
      _is.ColumnValue(
        table.numberFormat,
        value,
      );

  _is.ColumnValue<String, String> fontFamily(String? value) => _is.ColumnValue(
    table.fontFamily,
    value,
  );

  _is.ColumnValue<double, double> fontSize(double? value) => _is.ColumnValue(
    table.fontSize,
    value,
  );

  _is.ColumnValue<bool, bool> bold(bool? value) => _is.ColumnValue(
    table.bold,
    value,
  );

  _is.ColumnValue<bool, bool> italic(bool? value) => _is.ColumnValue(
    table.italic,
    value,
  );

  _is.ColumnValue<bool, bool> underline(bool? value) => _is.ColumnValue(
    table.underline,
    value,
  );

  _is.ColumnValue<bool, bool> strikethrough(bool? value) => _is.ColumnValue(
    table.strikethrough,
    value,
  );

  _is.ColumnValue<String, String> textColor(String? value) => _is.ColumnValue(
    table.textColor,
    value,
  );

  _is.ColumnValue<String, String> fillColor(String? value) => _is.ColumnValue(
    table.fillColor,
    value,
  );

  _is.ColumnValue<_id5xe3zl.HorizontalAlign, _id5xe3zl.HorizontalAlign> hAlign(
    _id5xe3zl.HorizontalAlign? value,
  ) => _is.ColumnValue(
    table.hAlign,
    value,
  );

  _is.ColumnValue<_i4hmikpl.VerticalAlign, _i4hmikpl.VerticalAlign> vAlign(
    _i4hmikpl.VerticalAlign? value,
  ) => _is.ColumnValue(
    table.vAlign,
    value,
  );

  _is.ColumnValue<_iprlvb3g.WrapStrategy, _iprlvb3g.WrapStrategy> wrap(
    _iprlvb3g.WrapStrategy? value,
  ) => _is.ColumnValue(
    table.wrap,
    value,
  );

  _is.ColumnValue<int, int> rotation(int? value) => _is.ColumnValue(
    table.rotation,
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

  _is.ColumnValue<String, String> linkUrl(String? value) => _is.ColumnValue(
    table.linkUrl,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class CellTable extends _is.Table<_is.UuidValue> {
  CellTable({super.tableRelation}) : super(tableName: 'cell') {
    updateTable = CellUpdateTable(this);
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
    rowId = _is.ColumnUuid(
      'rowId',
      this,
    );
    columnId = _is.ColumnUuid(
      'columnId',
      this,
    );
    content = _is.ColumnString(
      'content',
      this,
    );
    note = _is.ColumnString(
      'note',
      this,
    );
    numberFormat = _is.ColumnString(
      'numberFormat',
      this,
    );
    fontFamily = _is.ColumnString(
      'fontFamily',
      this,
    );
    fontSize = _is.ColumnDouble(
      'fontSize',
      this,
    );
    bold = _is.ColumnBool(
      'bold',
      this,
    );
    italic = _is.ColumnBool(
      'italic',
      this,
    );
    underline = _is.ColumnBool(
      'underline',
      this,
    );
    strikethrough = _is.ColumnBool(
      'strikethrough',
      this,
    );
    textColor = _is.ColumnString(
      'textColor',
      this,
    );
    fillColor = _is.ColumnString(
      'fillColor',
      this,
    );
    hAlign = _is.ColumnEnum(
      'hAlign',
      this,
      _is.EnumSerialization.byName,
    );
    vAlign = _is.ColumnEnum(
      'vAlign',
      this,
      _is.EnumSerialization.byName,
    );
    wrap = _is.ColumnEnum(
      'wrap',
      this,
      _is.EnumSerialization.byName,
    );
    rotation = _is.ColumnInt(
      'rotation',
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
    linkUrl = _is.ColumnString(
      'linkUrl',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final CellUpdateTable updateTable;

  /// The RevLog file (set by the sequencer; RevLog spec 02 §2.1). Plain, no
  /// foreign key: cells are never read or deleted by file (02 §2.2), and a
  /// key would make deleting a rev_file scan the cell table.
  late final _is.ColumnInt fileId;

  /// The revision that last wrote the row.
  late final _is.ColumnInt revision;

  late final _is.ColumnUuid sheetId;

  _ij40k88n.SheetTable? _sheet;

  /// Plain id, no DB foreign key: the sequencer cascades cells (02 §2.1).
  late final _is.ColumnUuid rowId;

  late final _is.ColumnUuid columnId;

  /// Typed encoding (=, n:, s:, b:, e:, r:); null = no value.
  late final _is.ColumnString content;

  /// Cell note (not a comment).
  late final _is.ColumnString note;

  late final _is.ColumnString numberFormat;

  late final _is.ColumnString fontFamily;

  late final _is.ColumnDouble fontSize;

  late final _is.ColumnBool bold;

  late final _is.ColumnBool italic;

  late final _is.ColumnBool underline;

  late final _is.ColumnBool strikethrough;

  /// "#RRGGBB" or "theme:accent3".
  late final _is.ColumnString textColor;

  late final _is.ColumnString fillColor;

  late final _is.ColumnEnum<_id5xe3zl.HorizontalAlign> hAlign;

  late final _is.ColumnEnum<_i4hmikpl.VerticalAlign> vAlign;

  late final _is.ColumnEnum<_iprlvb3g.WrapStrategy> wrap;

  /// -90..90 degrees; 255 = vertical stacked.
  late final _is.ColumnInt rotation;

  /// "<style>|<color>" or "none".
  late final _is.ColumnString borderTop;

  late final _is.ColumnString borderRight;

  late final _is.ColumnString borderBottom;

  late final _is.ColumnString borderLeft;

  /// Whole-cell hyperlink.
  late final _is.ColumnString linkUrl;

  late final _is.ColumnDateTime createdAt;

  _ij40k88n.SheetTable get sheet {
    if (_sheet != null) return _sheet!;
    _sheet = _is.createRelationTable(
      relationFieldName: 'sheet',
      field: Cell.t.sheetId,
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
    rowId,
    columnId,
    content,
    note,
    numberFormat,
    fontFamily,
    fontSize,
    bold,
    italic,
    underline,
    strikethrough,
    textColor,
    fillColor,
    hAlign,
    vAlign,
    wrap,
    rotation,
    borderTop,
    borderRight,
    borderBottom,
    borderLeft,
    linkUrl,
    createdAt,
  ];

  @override
  _is.Table? getRelationTable(String relationField) {
    if (relationField == 'sheet') {
      return sheet;
    }
    return null;
  }
}

class CellInclude extends _is.IncludeObject {
  CellInclude._({_ij40k88n.SheetInclude? sheet}) {
    _sheet = sheet;
  }

  _ij40k88n.SheetInclude? _sheet;

  @override
  Map<String, _is.Include?> get includes => {'sheet': _sheet};

  @override
  _is.Table<_is.UuidValue> get table => Cell.t;
}

class CellIncludeList extends _is.IncludeList {
  CellIncludeList._({
    _is.WhereExpressionBuilder<CellTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Cell.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue> get table => Cell.t;
}

class CellRepository {
  const CellRepository._();

  final attachRow = const CellAttachRowRepository._();

  /// Returns a list of [Cell]s matching the given query parameters.
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
  Future<List<Cell>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CellTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CellTable>? orderBy,
    _is.OrderByListBuilder<CellTable>? orderByList,
    _is.Transaction? transaction,
    CellInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Cell>(
      where: where?.call(Cell.t),
      orderBy: orderBy?.call(Cell.t),
      orderByList: orderByList?.call(Cell.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Emits [Cell]s matching the given query parameters every time the
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
  /// to that set. Pass [Table] instances such as `Cell.t`.
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
  _ida.Stream<List<Cell>> watch(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CellTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CellTable>? orderBy,
    _is.OrderByListBuilder<CellTable>? orderByList,
    CellInclude? include,
    Duration? throttle = const Duration(milliseconds: 30),
    Iterable<_is.Table>? alsoTriggerOnTables,
  }) {
    return session.db.watch<Cell>(
      where: where?.call(Cell.t),
      orderBy: orderBy?.call(Cell.t),
      orderByList: orderByList?.call(Cell.t),
      limit: limit,
      offset: offset,
      include: include,
      throttle: throttle,
      alsoTriggerOnTables: alsoTriggerOnTables,
    );
  }

  /// Returns the first matching [Cell] matching the given query parameters.
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
  Future<Cell?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CellTable>? where,
    int? offset,
    _is.OrderByBuilder<CellTable>? orderBy,
    _is.OrderByListBuilder<CellTable>? orderByList,
    _is.Transaction? transaction,
    CellInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Cell>(
      where: where?.call(Cell.t),
      orderBy: orderBy?.call(Cell.t),
      orderByList: orderByList?.call(Cell.t),
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Cell] by its [id] or null if no such row exists.
  Future<Cell?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    CellInclude? include,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Cell>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Cell]s in the list and returns the inserted rows.
  ///
  /// The returned [Cell]s will have their `id` fields set.
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
  Future<List<Cell>> insert(
    _is.DatabaseSession session,
    List<Cell> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Cell>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Cell] and returns the inserted row.
  ///
  /// The returned [Cell] will have its `id` field set.
  Future<Cell> insertRow(
    _is.DatabaseSession session,
    Cell row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Cell>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Cell]s in the list and returns the resulting rows.
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
  /// The returned [Cell]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Cell>> upsert(
    _is.DatabaseSession session,
    List<Cell> rows, {
    required _is.ColumnSelections<CellTable> conflictColumns,
    _is.ColumnSelections<CellTable>? updateColumns,
    _is.WhereExpressionBuilder<CellTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Cell>(
      rows,
      conflictColumns: conflictColumns(Cell.t),
      updateColumns: updateColumns?.call(Cell.t),
      updateWhere: updateWhere?.call(Cell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Cell] and returns the resulting row.
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
  /// The returned [Cell] will have its `id` field set.
  Future<Cell?> upsertRow(
    _is.DatabaseSession session,
    Cell row, {
    required _is.ColumnSelections<CellTable> conflictColumns,
    _is.ColumnSelections<CellTable>? updateColumns,
    _is.WhereExpressionBuilder<CellTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Cell>(
      row,
      conflictColumns: conflictColumns(Cell.t),
      updateColumns: updateColumns?.call(Cell.t),
      updateWhere: updateWhere?.call(Cell.t),
      transaction: transaction,
    );
  }

  /// Updates all [Cell]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Cell>> update(
    _is.DatabaseSession session,
    List<Cell> rows, {
    _is.ColumnSelections<CellTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Cell>(
      rows,
      columns: columns?.call(Cell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Cell]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Cell> updateRow(
    _is.DatabaseSession session,
    Cell row, {
    _is.ColumnSelections<CellTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Cell>(
      row,
      columns: columns?.call(Cell.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Cell] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Cell?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<CellUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Cell>(
      id,
      columnValues: columnValues(Cell.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Cell]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Cell>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<CellUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<CellTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<CellTable>? orderBy,
    _is.OrderByListBuilder<CellTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Cell>(
      columnValues: columnValues(Cell.t.updateTable),
      where: where(Cell.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Cell.t),
      orderByList: orderByList?.call(Cell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Cell]s in the list and returns the deleted rows.
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
  Future<List<Cell>> delete(
    _is.DatabaseSession session,
    List<Cell> rows, {
    _is.OrderByBuilder<CellTable>? orderBy,
    _is.OrderByListBuilder<CellTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Cell>(
      rows,
      orderBy: orderBy?.call(Cell.t),
      orderByList: orderByList?.call(Cell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Cell].
  Future<Cell> deleteRow(
    _is.DatabaseSession session,
    Cell row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Cell>(
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
  Future<List<Cell>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CellTable> where,
    _is.OrderByBuilder<CellTable>? orderBy,
    _is.OrderByListBuilder<CellTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Cell>(
      where: where(Cell.t),
      orderBy: orderBy?.call(Cell.t),
      orderByList: orderByList?.call(Cell.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<CellTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Cell>(
      where: where?.call(Cell.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Cell] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<CellTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Cell>(
      where: where(Cell.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class CellAttachRowRepository {
  const CellAttachRowRepository._();

  /// Creates a relation between the given [Cell] and [Sheet]
  /// by setting the [Cell]'s foreign key `sheetId` to refer to the [Sheet].
  Future<void> sheet(
    _is.DatabaseSession session,
    Cell cell,
    _ij40k88n.Sheet sheet, {
    _is.Transaction? transaction,
  }) async {
    if (cell.id == null) {
      throw ArgumentError.notNull('cell.id');
    }
    if (sheet.id == null) {
      throw ArgumentError.notNull('sheet.id');
    }

    var $cell = cell.copyWith(sheetId: sheet.id);
    await session.db.updateRow<Cell>(
      $cell,
      columns: [Cell.t.sheetId],
      transaction: transaction,
    );
  }
}
