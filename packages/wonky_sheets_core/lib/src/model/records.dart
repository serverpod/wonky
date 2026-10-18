import '../content/cell_content.dart';
import '../format/attributes.dart';
import 'schema.dart';

/// Typed readers for column maps.
abstract final class ColumnReader {
  /// `String` or null.
  static String? str(Map<String, Object?> m, String k) {
    final v = m[k];
    return v?.toString();
  }

  /// `double` or null.
  static double? dbl(Map<String, Object?> m, String k) {
    final v = m[k];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// `int` or null.
  static int? integer(Map<String, Object?> m, String k) {
    final v = m[k];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// `bool` or null.
  static bool? boolean(Map<String, Object?> m, String k) {
    final v = m[k];
    if (v is bool) return v;
    if (v == 'true' || v == 1) return true;
    if (v == 'false' || v == 0) return false;
    return null;
  }

  /// `DateTime` or null (accepts ISO strings and epoch millis).
  static DateTime? date(Map<String, Object?> m, String k) {
    final v = m[k];
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
    return null;
  }
}

/// The epoch used when a row has no `createdAt`.
final DateTime kEpochUtc = DateTime.utc(1970);

/// Base of all synced row records held by the model. Records are immutable.
abstract class SyncRecord {
  /// Creates a record.
  const SyncRecord(this.id);

  /// Row id (canonical UUID string).
  final String id;

  /// Table name ([SheetsTables]).
  String get table;

  /// All columns (including `id`) as a column map; null-valued columns are
  /// included so the map describes the full row.
  Map<String, Object?> toColumns();

  /// A copy with [update] applied (column → new value).
  SyncRecord withColumns(Map<String, Object?> update);

  /// Current value of [column].
  Object? column(String column) => toColumns()[column];

  @override
  String toString() => '$table($id)';
}

/// A record of a table the model stores without interpretation (scripts, …).
final class GenericRecord extends SyncRecord {
  /// Creates a generic record.
  GenericRecord(this.table, String id, Map<String, Object?> columns)
    : columns = Map.unmodifiable({...columns, Cols.id: id}),
      super(id);

  @override
  final String table;

  /// All columns.
  final Map<String, Object?> columns;

  @override
  Map<String, Object?> toColumns() => Map.of(columns);

  @override
  Object? column(String column) => columns[column];

  @override
  GenericRecord withColumns(Map<String, Object?> update) =>
      GenericRecord(table, id, {...columns, ...update});
}

/// `Spreadsheet` (id = space UUID).
final class SpreadsheetRecord extends SyncRecord {
  /// Creates a spreadsheet record.
  const SpreadsheetRecord({
    required String id,
    this.title = 'Untitled spreadsheet',
    this.locale = 'en_US',
    this.timeZone = 'UTC',
    this.recalcMode = RecalcMode.onChange,
    this.iterativeCalc = false,
    this.maxIterations = 50,
    this.convergenceThreshold = 0.05,
    this.defaultFontFamily = 'Inter',
    this.defaultFontSize = 10,
    this.themeJson = '',
    this.createdBy = '',
    this.displayLanguage,
    this._createdAt,
  }) : super(id);

  final String title;
  final String locale;
  final String timeZone;
  final RecalcMode recalcMode;
  final bool iterativeCalc;
  final int maxIterations;
  final double convergenceThreshold;
  final String defaultFontFamily;
  final double defaultFontSize;
  final String themeJson;
  final String createdBy;
  final String? displayLanguage;
  final DateTime? _createdAt;

  /// Creation time.
  DateTime get createdAt => _createdAt ?? kEpochUtc;

  @override
  String get table => SheetsTables.spreadsheet;

  /// From a column map.
  factory SpreadsheetRecord.fromColumns(Map<String, Object?> m) {
    const r = ColumnReader.str;
    return SpreadsheetRecord(
      id: r(m, Cols.id)!,
      title: r(m, SpreadsheetCols.title) ?? 'Untitled spreadsheet',
      locale: r(m, SpreadsheetCols.locale) ?? 'en_US',
      timeZone: r(m, SpreadsheetCols.timeZone) ?? 'UTC',
      recalcMode:
          enumByName(RecalcMode.values, m[SpreadsheetCols.recalcMode]) ??
          RecalcMode.onChange,
      iterativeCalc:
          ColumnReader.boolean(m, SpreadsheetCols.iterativeCalc) ?? false,
      maxIterations:
          ColumnReader.integer(m, SpreadsheetCols.maxIterations) ?? 50,
      convergenceThreshold:
          ColumnReader.dbl(m, SpreadsheetCols.convergenceThreshold) ?? 0.05,
      defaultFontFamily: r(m, SpreadsheetCols.defaultFontFamily) ?? 'Inter',
      defaultFontSize:
          ColumnReader.dbl(m, SpreadsheetCols.defaultFontSize) ?? 10,
      themeJson: r(m, SpreadsheetCols.themeJson) ?? '',
      createdBy: r(m, Cols.createdBy) ?? '',
      displayLanguage: r(m, SpreadsheetCols.displayLanguage),
      createdAt: ColumnReader.date(m, Cols.createdAt),
    );
  }

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    SpreadsheetCols.title: title,
    SpreadsheetCols.locale: locale,
    SpreadsheetCols.timeZone: timeZone,
    SpreadsheetCols.recalcMode: recalcMode.name,
    SpreadsheetCols.iterativeCalc: iterativeCalc,
    SpreadsheetCols.maxIterations: maxIterations,
    SpreadsheetCols.convergenceThreshold: convergenceThreshold,
    SpreadsheetCols.defaultFontFamily: defaultFontFamily,
    SpreadsheetCols.defaultFontSize: defaultFontSize,
    SpreadsheetCols.themeJson: themeJson,
    Cols.createdBy: createdBy,
    SpreadsheetCols.displayLanguage: displayLanguage,
    Cols.createdAt: createdAt,
  };

  @override
  SpreadsheetRecord withColumns(Map<String, Object?> update) =>
      SpreadsheetRecord.fromColumns({...toColumns(), ...update});
}

/// `Sheet`.
final class SheetRecord extends SyncRecord {
  /// Creates a sheet record.
  const SheetRecord({
    required String id,
    required this.spreadsheetId,
    required this.name,
    required this.sortKey,
    this.kind = SheetKind.grid,
    this.hidden = false,
    this.tabColor,
    this.rightToLeft = false,
    this.showGridlines = true,
    this.frozenRows = 0,
    this.frozenColumns = 0,
    this.defaultRowHeight = 21,
    this.defaultColumnWidth = 100,
    this.formatJson,
    this.printSettingsJson,
    this._createdAt,
  }) : super(id);

  final String spreadsheetId;
  final String name;
  final String sortKey;
  final SheetKind kind;
  final bool hidden;
  final String? tabColor;
  final bool rightToLeft;
  final bool showGridlines;
  final int frozenRows;
  final int frozenColumns;
  final double defaultRowHeight;
  final double defaultColumnWidth;
  final String? formatJson;
  final String? printSettingsJson;
  final DateTime? _createdAt;

  /// Creation time.
  DateTime get createdAt => _createdAt ?? kEpochUtc;

  /// Parsed sheet default format.
  CellFormat get format => CellFormat.fromJson(formatJson);

  @override
  String get table => SheetsTables.sheet;

  /// From a column map.
  factory SheetRecord.fromColumns(Map<String, Object?> m) => SheetRecord(
    id: ColumnReader.str(m, Cols.id)!,
    spreadsheetId: ColumnReader.str(m, Cols.spreadsheetId) ?? '',
    name: ColumnReader.str(m, Cols.name) ?? 'Sheet',
    sortKey: ColumnReader.str(m, Cols.sortKey) ?? 'a0',
    kind: enumByName(SheetKind.values, m[SheetCols.kind]) ?? SheetKind.grid,
    hidden: ColumnReader.boolean(m, Cols.hidden) ?? false,
    tabColor: ColumnReader.str(m, SheetCols.tabColor),
    rightToLeft: ColumnReader.boolean(m, SheetCols.rightToLeft) ?? false,
    showGridlines: ColumnReader.boolean(m, SheetCols.showGridlines) ?? true,
    frozenRows: ColumnReader.integer(m, SheetCols.frozenRows) ?? 0,
    frozenColumns: ColumnReader.integer(m, SheetCols.frozenColumns) ?? 0,
    defaultRowHeight: ColumnReader.dbl(m, SheetCols.defaultRowHeight) ?? 21,
    defaultColumnWidth:
        ColumnReader.dbl(m, SheetCols.defaultColumnWidth) ?? 100,
    formatJson: ColumnReader.str(m, Cols.formatJson),
    printSettingsJson: ColumnReader.str(m, SheetCols.printSettingsJson),
    createdAt: ColumnReader.date(m, Cols.createdAt),
  );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.spreadsheetId: spreadsheetId,
    Cols.name: name,
    Cols.sortKey: sortKey,
    SheetCols.kind: kind.name,
    Cols.hidden: hidden,
    SheetCols.tabColor: tabColor,
    SheetCols.rightToLeft: rightToLeft,
    SheetCols.showGridlines: showGridlines,
    SheetCols.frozenRows: frozenRows,
    SheetCols.frozenColumns: frozenColumns,
    SheetCols.defaultRowHeight: defaultRowHeight,
    SheetCols.defaultColumnWidth: defaultColumnWidth,
    Cols.formatJson: formatJson,
    SheetCols.printSettingsJson: printSettingsJson,
    Cols.createdAt: createdAt,
  };

  @override
  SheetRecord withColumns(Map<String, Object?> update) =>
      SheetRecord.fromColumns({...toColumns(), ...update});
}

/// `SheetRow` or `SheetColumn` (one class; [isRow] tells which).
final class DimensionRecord extends SyncRecord {
  /// Creates a row/column record.
  const DimensionRecord({
    required String id,
    required this.isRow,
    required this.sheetId,
    required this.sortKey,
    this.size,
    this.hidden = false,
    this.formatJson,
    this._createdAt,
  }) : super(id);

  /// Whether this is a `SheetRow` (else `SheetColumn`).
  final bool isRow;
  final String sheetId;
  final String sortKey;

  /// `height` (rows) / `width` (columns) in px; null = default/auto.
  final double? size;
  final bool hidden;
  final String? formatJson;
  final DateTime? _createdAt;

  /// Creation time.
  DateTime get createdAt => _createdAt ?? kEpochUtc;

  /// Parsed default format.
  CellFormat get format => CellFormat.fromJson(formatJson);

  /// Size column name.
  String get sizeColumn => isRow ? DimCols.height : DimCols.width;

  @override
  String get table => isRow ? SheetsTables.sheetRow : SheetsTables.sheetColumn;

  /// From a column map of [table].
  factory DimensionRecord.fromColumns(String table, Map<String, Object?> m) {
    final isRow = table == SheetsTables.sheetRow;
    return DimensionRecord(
      id: ColumnReader.str(m, Cols.id)!,
      isRow: isRow,
      sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
      sortKey: ColumnReader.str(m, Cols.sortKey) ?? 'a0',
      size: ColumnReader.dbl(m, isRow ? DimCols.height : DimCols.width),
      hidden: ColumnReader.boolean(m, Cols.hidden) ?? false,
      formatJson: ColumnReader.str(m, Cols.formatJson),
      createdAt: ColumnReader.date(m, Cols.createdAt),
    );
  }

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    Cols.sortKey: sortKey,
    sizeColumn: size,
    Cols.hidden: hidden,
    Cols.formatJson: formatJson,
    Cols.createdAt: createdAt,
  };

  @override
  DimensionRecord withColumns(Map<String, Object?> update) =>
      DimensionRecord.fromColumns(table, {...toColumns(), ...update});
}

/// `Cell`. Format attributes are held in an interned [CellFormat].
final class CellRecord extends SyncRecord {
  /// Creates a cell record. [id] should be `SheetsIds.cellId(sheetId, rowId, columnId)`.
  CellRecord({
    required String id,
    required this.sheetId,
    required this.rowId,
    required this.columnId,
    this.content,
    this.note,
    CellFormat? format,
    this._createdAt,
  }) : format = format ?? CellFormat.empty,
       super(id);

  final String sheetId;
  final String rowId;
  final String columnId;

  /// Encoded content (02 §2) or null.
  final String? content;
  final String? note;

  /// Explicit format attributes.
  final CellFormat format;
  final DateTime? _createdAt;

  CellContent? _decoded;
  bool _decodedSet = false;

  /// Cache slot of the formula-engine bridge (`cellInputOf`): the engine input built
  /// from [content] (records are immutable, so it never goes stale). Not part of the
  /// record's data.
  Object? engineInput;

  /// Creation time.
  DateTime get createdAt => _createdAt ?? kEpochUtc;

  /// Decoded content (cached).
  CellContent? get decoded {
    if (!_decodedSet) {
      _decoded = CellContent.decode(content);
      _decodedSet = true;
    }
    return _decoded;
  }

  /// Whether every field is null (such a row must be deleted, 02 §3.3).
  bool get isBlankRow => content == null && note == null && format.isEmpty;

  @override
  String get table => SheetsTables.cell;

  static final Set<String> _nonFormatColumns = {
    Cols.id,
    Cols.sheetId,
    CellCols.rowId,
    CellCols.columnId,
    CellCols.content,
    CellCols.note,
    Cols.createdAt,
  };

  /// From a column map.
  factory CellRecord.fromColumns(Map<String, Object?> m) {
    // Most cells have no format columns: no map for them (a 1M-cell load).
    Map<String, Object?>? fm;
    m.forEach((k, v) {
      if (!_nonFormatColumns.contains(k)) (fm ??= {})[k] = v;
    });
    return CellRecord(
      id: ColumnReader.str(m, Cols.id)!,
      sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
      rowId: ColumnReader.str(m, CellCols.rowId) ?? '',
      columnId: ColumnReader.str(m, CellCols.columnId) ?? '',
      content: ColumnReader.str(m, CellCols.content),
      note: ColumnReader.str(m, CellCols.note),
      format: fm == null ? CellFormat.empty : CellFormat.fromMap(fm!),
      createdAt: ColumnReader.date(m, Cols.createdAt),
    );
  }

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    CellCols.rowId: rowId,
    CellCols.columnId: columnId,
    CellCols.content: content,
    CellCols.note: note,
    for (final a in FormatAttr.values) a.column: a.toColumnValue(format[a]),
    Cols.createdAt: createdAt,
  };

  @override
  Object? column(String column) {
    switch (column) {
      case Cols.id:
        return id;
      case Cols.sheetId:
        return sheetId;
      case CellCols.rowId:
        return rowId;
      case CellCols.columnId:
        return columnId;
      case CellCols.content:
        return content;
      case CellCols.note:
        return note;
      case Cols.createdAt:
        return createdAt;
    }
    final a = FormatAttr.byColumn(column);
    return a?.toColumnValue(format[a]);
  }

  @override
  CellRecord withColumns(Map<String, Object?> update) {
    var content = this.content;
    var note = this.note;
    var format = this.format;
    Map<FormatAttr, Object?>? fmt;
    update.forEach((k, v) {
      if (k == CellCols.content) {
        content = v as String?;
      } else if (k == CellCols.note) {
        note = v as String?;
      } else {
        final a = FormatAttr.byColumn(k);
        if (a != null) (fmt ??= {})[a] = v;
      }
    });
    if (fmt != null) format = format.withValues(fmt!);
    return CellRecord(
      id: id,
      sheetId: sheetId,
      rowId: rowId,
      columnId: columnId,
      content: content,
      note: note,
      format: format,
      createdAt: _createdAt,
    );
  }
}

/// Base of sheet-scoped rule/range records.
abstract class SheetScopedRecord extends SyncRecord {
  /// Creates a sheet-scoped record.
  const SheetScopedRecord(super.id, this.sheetId, DateTime? createdAt)
    : _createdAt = createdAt;

  /// Owning sheet.
  final String sheetId;
  final DateTime? _createdAt;

  /// Creation time.
  DateTime get createdAt => _createdAt ?? kEpochUtc;
}

/// `MergedRange`.
final class MergedRangeRecord extends SheetScopedRecord {
  /// Creates a merge record.
  const MergedRangeRecord({
    required String id,
    required String sheetId,
    required this.rangeJson,
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  /// GridRange with all four bounds.
  final String rangeJson;

  @override
  String get table => SheetsTables.mergedRange;

  /// From a column map.
  factory MergedRangeRecord.fromColumns(Map<String, Object?> m) =>
      MergedRangeRecord(
        id: ColumnReader.str(m, Cols.id)!,
        sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
        rangeJson: ColumnReader.str(m, Cols.rangeJson) ?? '{}',
        createdAt: ColumnReader.date(m, Cols.createdAt),
      );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    Cols.rangeJson: rangeJson,
    Cols.createdAt: createdAt,
  };

  @override
  MergedRangeRecord withColumns(Map<String, Object?> update) =>
      MergedRangeRecord.fromColumns({...toColumns(), ...update});
}

/// `DimensionGroup` (row/column outline group).
final class DimensionGroupRecord extends SheetScopedRecord {
  /// Creates a group record.
  const DimensionGroupRecord({
    required String id,
    required String sheetId,
    required this.dimension,
    required this.startId,
    required this.endId,
    this.depth = 1,
    this.collapsed = false,
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  final Dimension dimension;
  final String startId;
  final String endId;
  final int depth;
  final bool collapsed;

  @override
  String get table => SheetsTables.dimensionGroup;

  /// From a column map.
  factory DimensionGroupRecord.fromColumns(Map<String, Object?> m) =>
      DimensionGroupRecord(
        id: ColumnReader.str(m, Cols.id)!,
        sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
        dimension:
            enumByName(Dimension.values, m['dimension']) ?? Dimension.rows,
        startId: ColumnReader.str(m, 'startId') ?? '',
        endId: ColumnReader.str(m, 'endId') ?? '',
        depth: ColumnReader.integer(m, 'depth') ?? 1,
        collapsed: ColumnReader.boolean(m, 'collapsed') ?? false,
        createdAt: ColumnReader.date(m, Cols.createdAt),
      );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    'dimension': dimension.name,
    'startId': startId,
    'endId': endId,
    'depth': depth,
    'collapsed': collapsed,
    Cols.createdAt: createdAt,
  };

  @override
  DimensionGroupRecord withColumns(Map<String, Object?> update) =>
      DimensionGroupRecord.fromColumns({...toColumns(), ...update});
}

/// `NamedRange` (also named functions when [formula] is set).
final class NamedRangeRecord extends SyncRecord {
  /// Creates a named range record.
  const NamedRangeRecord({
    required String id,
    required this.spreadsheetId,
    required this.name,
    this.rangeJson,
    this.formula,
    this.comment,
    this.metaJson,
    this._createdAt,
  }) : super(id);

  final String spreadsheetId;
  final String name;
  final String? rangeJson;
  final String? formula;
  final String? comment;
  final String? metaJson;
  final DateTime? _createdAt;

  /// Creation time.
  DateTime get createdAt => _createdAt ?? kEpochUtc;

  /// Whether this is a named function / formula (no range).
  bool get isFormula => rangeJson == null && formula != null;

  @override
  String get table => SheetsTables.namedRange;

  /// From a column map.
  factory NamedRangeRecord.fromColumns(Map<String, Object?> m) =>
      NamedRangeRecord(
        id: ColumnReader.str(m, Cols.id)!,
        spreadsheetId: ColumnReader.str(m, Cols.spreadsheetId) ?? '',
        name: ColumnReader.str(m, Cols.name) ?? '',
        rangeJson: ColumnReader.str(m, Cols.rangeJson),
        formula: ColumnReader.str(m, 'formula'),
        comment: ColumnReader.str(m, 'comment'),
        metaJson: ColumnReader.str(m, 'metaJson'),
        createdAt: ColumnReader.date(m, Cols.createdAt),
      );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.spreadsheetId: spreadsheetId,
    Cols.name: name,
    Cols.rangeJson: rangeJson,
    'formula': formula,
    'comment': comment,
    'metaJson': metaJson,
    Cols.createdAt: createdAt,
  };

  @override
  NamedRangeRecord withColumns(Map<String, Object?> update) =>
      NamedRangeRecord.fromColumns({...toColumns(), ...update});
}

/// `ProtectedRange`.
final class ProtectedRangeRecord extends SheetScopedRecord {
  /// Creates a protection record.
  const ProtectedRangeRecord({
    required String id,
    required String sheetId,
    this.rangeJson,
    this.exceptRangesJson,
    this.description,
    this.warningOnly = false,
    this.editorsJson = '[]',
    this.createdBy = '',
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  /// Range, or null for the whole sheet.
  final String? rangeJson;
  final String? exceptRangesJson;
  final String? description;
  final bool warningOnly;
  final String editorsJson;
  final String createdBy;

  @override
  String get table => SheetsTables.protectedRange;

  /// From a column map.
  factory ProtectedRangeRecord.fromColumns(Map<String, Object?> m) =>
      ProtectedRangeRecord(
        id: ColumnReader.str(m, Cols.id)!,
        sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
        rangeJson: ColumnReader.str(m, Cols.rangeJson),
        exceptRangesJson: ColumnReader.str(m, 'exceptRangesJson'),
        description: ColumnReader.str(m, 'description'),
        warningOnly: ColumnReader.boolean(m, 'warningOnly') ?? false,
        editorsJson: ColumnReader.str(m, 'editorsJson') ?? '[]',
        createdBy: ColumnReader.str(m, Cols.createdBy) ?? '',
        createdAt: ColumnReader.date(m, Cols.createdAt),
      );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    Cols.rangeJson: rangeJson,
    'exceptRangesJson': exceptRangesJson,
    'description': description,
    'warningOnly': warningOnly,
    'editorsJson': editorsJson,
    Cols.createdBy: createdBy,
    Cols.createdAt: createdAt,
  };

  @override
  ProtectedRangeRecord withColumns(Map<String, Object?> update) =>
      ProtectedRangeRecord.fromColumns({...toColumns(), ...update});
}

/// `ConditionalFormatRule`.
final class CfRuleRecord extends SheetScopedRecord {
  /// Creates a CF rule record.
  const CfRuleRecord({
    required String id,
    required String sheetId,
    required this.sortKey,
    required this.rangesJson,
    required this.ruleJson,
    this.enabled = true,
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  final String sortKey;
  final String rangesJson;
  final String ruleJson;
  final bool enabled;

  @override
  String get table => SheetsTables.conditionalFormatRule;

  /// From a column map.
  factory CfRuleRecord.fromColumns(Map<String, Object?> m) => CfRuleRecord(
    id: ColumnReader.str(m, Cols.id)!,
    sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
    sortKey: ColumnReader.str(m, Cols.sortKey) ?? 'a0',
    rangesJson: ColumnReader.str(m, Cols.rangesJson) ?? '[]',
    ruleJson: ColumnReader.str(m, 'ruleJson') ?? '{}',
    enabled: ColumnReader.boolean(m, 'enabled') ?? true,
    createdAt: ColumnReader.date(m, Cols.createdAt),
  );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    Cols.sortKey: sortKey,
    Cols.rangesJson: rangesJson,
    'ruleJson': ruleJson,
    'enabled': enabled,
    Cols.createdAt: createdAt,
  };

  @override
  CfRuleRecord withColumns(Map<String, Object?> update) =>
      CfRuleRecord.fromColumns({...toColumns(), ...update});
}

/// `DataValidationRule`.
final class DvRuleRecord extends SheetScopedRecord {
  /// Creates a DV rule record.
  const DvRuleRecord({
    required String id,
    required String sheetId,
    required this.rangesJson,
    required this.criteriaJson,
    this.strict = false,
    this.showDropdown = true,
    this.displayStyle,
    this.helpText,
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  final String rangesJson;
  final String criteriaJson;
  final bool strict;
  final bool showDropdown;
  final String? displayStyle;
  final String? helpText;

  @override
  String get table => SheetsTables.dataValidationRule;

  /// From a column map.
  factory DvRuleRecord.fromColumns(Map<String, Object?> m) => DvRuleRecord(
    id: ColumnReader.str(m, Cols.id)!,
    sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
    rangesJson: ColumnReader.str(m, Cols.rangesJson) ?? '[]',
    criteriaJson: ColumnReader.str(m, 'criteriaJson') ?? '{}',
    strict: ColumnReader.boolean(m, 'strict') ?? false,
    showDropdown: ColumnReader.boolean(m, 'showDropdown') ?? true,
    displayStyle: ColumnReader.str(m, 'displayStyle'),
    helpText: ColumnReader.str(m, 'helpText'),
    createdAt: ColumnReader.date(m, Cols.createdAt),
  );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    Cols.rangesJson: rangesJson,
    'criteriaJson': criteriaJson,
    'strict': strict,
    'showDropdown': showDropdown,
    'displayStyle': displayStyle,
    'helpText': helpText,
    Cols.createdAt: createdAt,
  };

  @override
  DvRuleRecord withColumns(Map<String, Object?> update) =>
      DvRuleRecord.fromColumns({...toColumns(), ...update});
}

/// `BasicFilter` (id = `SheetsIds.basicFilterId(sheetId)`) and `FilterView`
/// (one class; [isView] tells which).
final class FilterRecord extends SheetScopedRecord {
  /// Creates a filter record.
  const FilterRecord({
    required String id,
    required String sheetId,
    required this.isView,
    required this.rangeJson,
    this.criteriaJson = '{}',
    this.sortJson,
    this.name,
    this.createdBy,
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  /// Whether this is a `FilterView` (else the basic filter).
  final bool isView;
  final String rangeJson;
  final String criteriaJson;
  final String? sortJson;

  /// Filter view name (views only).
  final String? name;

  /// Creator (views only).
  final String? createdBy;

  @override
  String get table =>
      isView ? SheetsTables.filterView : SheetsTables.basicFilter;

  /// From a column map of [table].
  factory FilterRecord.fromColumns(String table, Map<String, Object?> m) =>
      FilterRecord(
        id: ColumnReader.str(m, Cols.id)!,
        sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
        isView: table == SheetsTables.filterView,
        rangeJson: ColumnReader.str(m, Cols.rangeJson) ?? '{}',
        criteriaJson: ColumnReader.str(m, 'criteriaJson') ?? '{}',
        sortJson: ColumnReader.str(m, 'sortJson'),
        name: ColumnReader.str(m, Cols.name),
        createdBy: ColumnReader.str(m, Cols.createdBy),
        createdAt: ColumnReader.date(m, Cols.createdAt),
      );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    Cols.rangeJson: rangeJson,
    'criteriaJson': criteriaJson,
    'sortJson': sortJson,
    if (isView) Cols.name: name ?? 'Filter',
    if (isView) Cols.createdBy: createdBy ?? '',
    Cols.createdAt: createdAt,
  };

  @override
  FilterRecord withColumns(Map<String, Object?> update) =>
      FilterRecord.fromColumns(table, {...toColumns(), ...update});
}

/// `Banding`.
final class BandingRecord extends SheetScopedRecord {
  /// Creates a banding record.
  const BandingRecord({
    required String id,
    required String sheetId,
    required this.rangeJson,
    required this.styleJson,
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  final String rangeJson;
  final String styleJson;

  @override
  String get table => SheetsTables.banding;

  /// From a column map.
  factory BandingRecord.fromColumns(Map<String, Object?> m) => BandingRecord(
    id: ColumnReader.str(m, Cols.id)!,
    sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
    rangeJson: ColumnReader.str(m, Cols.rangeJson) ?? '{}',
    styleJson: ColumnReader.str(m, 'styleJson') ?? '{}',
    createdAt: ColumnReader.date(m, Cols.createdAt),
  );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    Cols.rangeJson: rangeJson,
    'styleJson': styleJson,
    Cols.createdAt: createdAt,
  };

  @override
  BandingRecord withColumns(Map<String, Object?> update) =>
      BandingRecord.fromColumns({...toColumns(), ...update});
}

/// `EmbeddedObject` (charts, images, slicers).
final class EmbeddedObjectRecord extends SheetScopedRecord {
  /// Creates an object record.
  const EmbeddedObjectRecord({
    required String id,
    required String sheetId,
    required this.kind,
    required this.anchorJson,
    required this.specJson,
    this.zIndex = 0,
    this.title,
    this.altText,
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  final EmbeddedObjectKind kind;
  final String anchorJson;
  final String specJson;
  final int zIndex;
  final String? title;
  final String? altText;

  @override
  String get table => SheetsTables.embeddedObject;

  /// From a column map.
  factory EmbeddedObjectRecord.fromColumns(Map<String, Object?> m) =>
      EmbeddedObjectRecord(
        id: ColumnReader.str(m, Cols.id)!,
        sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
        kind:
            enumByName(EmbeddedObjectKind.values, m['kind']) ??
            EmbeddedObjectKind.chart,
        anchorJson: ColumnReader.str(m, 'anchorJson') ?? '{}',
        specJson: ColumnReader.str(m, 'specJson') ?? '{}',
        zIndex: ColumnReader.integer(m, 'zIndex') ?? 0,
        title: ColumnReader.str(m, 'title'),
        altText: ColumnReader.str(m, 'altText'),
        createdAt: ColumnReader.date(m, Cols.createdAt),
      );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    'kind': kind.name,
    'anchorJson': anchorJson,
    'specJson': specJson,
    'zIndex': zIndex,
    'title': title,
    'altText': altText,
    Cols.createdAt: createdAt,
  };

  @override
  EmbeddedObjectRecord withColumns(Map<String, Object?> update) =>
      EmbeddedObjectRecord.fromColumns({...toColumns(), ...update});
}

/// `PivotTable`.
final class PivotTableRecord extends SheetScopedRecord {
  /// Creates a pivot record.
  const PivotTableRecord({
    required String id,
    required String sheetId,
    required this.anchorRowId,
    required this.anchorColId,
    required this.sourceRangeJson,
    required this.specJson,
    DateTime? createdAt,
  }) : super(id, sheetId, createdAt);

  final String anchorRowId;
  final String anchorColId;
  final String sourceRangeJson;
  final String specJson;

  @override
  String get table => SheetsTables.pivotTable;

  /// From a column map.
  factory PivotTableRecord.fromColumns(Map<String, Object?> m) =>
      PivotTableRecord(
        id: ColumnReader.str(m, Cols.id)!,
        sheetId: ColumnReader.str(m, Cols.sheetId) ?? '',
        anchorRowId: ColumnReader.str(m, 'anchorRowId') ?? '',
        anchorColId: ColumnReader.str(m, 'anchorColId') ?? '',
        sourceRangeJson: ColumnReader.str(m, 'sourceRangeJson') ?? '{}',
        specJson: ColumnReader.str(m, 'specJson') ?? '{}',
        createdAt: ColumnReader.date(m, Cols.createdAt),
      );

  @override
  Map<String, Object?> toColumns() => {
    Cols.id: id,
    Cols.sheetId: sheetId,
    'anchorRowId': anchorRowId,
    'anchorColId': anchorColId,
    'sourceRangeJson': sourceRangeJson,
    'specJson': specJson,
    Cols.createdAt: createdAt,
  };

  @override
  PivotTableRecord withColumns(Map<String, Object?> update) =>
      PivotTableRecord.fromColumns({...toColumns(), ...update});
}

/// Builds the typed record for [table] from a full column map.
SyncRecord recordFromColumns(String table, Map<String, Object?> m) {
  switch (table) {
    case SheetsTables.spreadsheet:
      return SpreadsheetRecord.fromColumns(m);
    case SheetsTables.sheet:
      return SheetRecord.fromColumns(m);
    case SheetsTables.sheetRow:
    case SheetsTables.sheetColumn:
      return DimensionRecord.fromColumns(table, m);
    case SheetsTables.cell:
      return CellRecord.fromColumns(m);
    case SheetsTables.mergedRange:
      return MergedRangeRecord.fromColumns(m);
    case SheetsTables.dimensionGroup:
      return DimensionGroupRecord.fromColumns(m);
    case SheetsTables.namedRange:
      return NamedRangeRecord.fromColumns(m);
    case SheetsTables.protectedRange:
      return ProtectedRangeRecord.fromColumns(m);
    case SheetsTables.conditionalFormatRule:
      return CfRuleRecord.fromColumns(m);
    case SheetsTables.dataValidationRule:
      return DvRuleRecord.fromColumns(m);
    case SheetsTables.basicFilter:
    case SheetsTables.filterView:
      return FilterRecord.fromColumns(table, m);
    case SheetsTables.banding:
      return BandingRecord.fromColumns(m);
    case SheetsTables.embeddedObject:
      return EmbeddedObjectRecord.fromColumns(m);
    case SheetsTables.pivotTable:
      return PivotTableRecord.fromColumns(m);
    default:
      return GenericRecord(table, m[Cols.id].toString(), m);
  }
}
