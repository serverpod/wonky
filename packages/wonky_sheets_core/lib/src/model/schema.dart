/// Names of the synced tables and their columns (specs/wonky_sheets/02 §3).
///
/// Row changes ([RowChange]) and the generic ingestion API of the
/// `WorkbookModel` use these names. Column names equal the Serverpod field
/// names of the RevLog table models (relations become `<name>Id`).
///
/// Value types in column maps:
/// - UUID columns (`id`, `…Id`, `createdBy`, …): canonical lower-case `String`
///   (adapters convert `UuidValue` ⇄ `String`).
/// - enums: the enum value `name` (`String`), e.g. `hAlign: 'center'`.
/// - `DateTime` (UTC), `double`, `int`, `bool`, `String` as declared.
library;

export '../formula/model/workbook_view.dart' show RecalcMode;

/// Table names.
abstract final class SheetsTables {
  static const spreadsheet = 'spreadsheet';
  static const sheet = 'sheet';
  static const sheetRow = 'sheet_row';
  static const sheetColumn = 'sheet_column';
  static const cell = 'cell';
  static const mergedRange = 'merged_range';
  static const dimensionGroup = 'dimension_group';
  static const namedRange = 'named_range';
  static const protectedRange = 'protected_range';
  static const conditionalFormatRule = 'conditional_format_rule';
  static const dataValidationRule = 'data_validation_rule';
  static const basicFilter = 'basic_filter';
  static const filterView = 'filter_view';
  static const banding = 'banding';
  static const embeddedObject = 'embedded_object';
  static const pivotTable = 'pivot_table';
  static const scriptProject = 'script_project';
  static const scriptFile = 'script_file';
  static const scriptBuild = 'script_build';
  static const scriptTrigger = 'script_trigger';
  static const macro = 'macro';
  static const scriptProperty = 'script_property';
  static const changeLog = 'change_log';

  /// Per-user script properties (09 §6.9, A-09-4). Rows live in the user's
  /// personal space (space UUID = auth user id), never in a spreadsheet's
  /// space, so the table is not part of [dependencyOrder].
  static const scriptUserProperty = 'script_user_property';

  /// Tables in dependency order (parents first): inserts are applied in this
  /// order, deletes in reverse.
  static const dependencyOrder = [
    spreadsheet,
    sheet,
    sheetRow,
    sheetColumn,
    cell,
    mergedRange,
    dimensionGroup,
    namedRange,
    protectedRange,
    conditionalFormatRule,
    dataValidationRule,
    basicFilter,
    filterView,
    banding,
    embeddedObject,
    pivotTable,
    scriptProject,
    scriptFile,
    scriptBuild,
    scriptTrigger,
    macro,
    scriptProperty,
    changeLog,
  ];

  /// Rank of [table] in [dependencyOrder] (unknown tables last).
  static int rank(String table) => _ranks[table] ?? dependencyOrder.length;

  static final Map<String, int> _ranks = {
    for (var i = 0; i < dependencyOrder.length; i++) dependencyOrder[i]: i,
  };
}

/// Column names shared by several tables.
abstract final class Cols {
  static const id = 'id';
  static const createdAt = 'createdAt';
  static const sheetId = 'sheetId';
  static const spreadsheetId = 'spreadsheetId';
  static const sortKey = 'sortKey';
  static const formatJson = 'formatJson';
  static const rangeJson = 'rangeJson';
  static const rangesJson = 'rangesJson';
  static const hidden = 'hidden';
  static const name = 'name';
  static const createdBy = 'createdBy';
  static const projectId = 'projectId';
}

/// `spreadsheet` columns.
abstract final class SpreadsheetCols {
  static const title = 'title';
  static const locale = 'locale';
  static const timeZone = 'timeZone';
  static const recalcMode = 'recalcMode';
  static const iterativeCalc = 'iterativeCalc';
  static const maxIterations = 'maxIterations';
  static const convergenceThreshold = 'convergenceThreshold';
  static const defaultFontFamily = 'defaultFontFamily';
  static const defaultFontSize = 'defaultFontSize';
  static const themeJson = 'themeJson';
  static const displayLanguage = 'displayLanguage';
}

/// `sheet` columns.
abstract final class SheetCols {
  static const kind = 'kind';
  static const tabColor = 'tabColor';
  static const rightToLeft = 'rightToLeft';
  static const showGridlines = 'showGridlines';
  static const frozenRows = 'frozenRows';
  static const frozenColumns = 'frozenColumns';
  static const defaultRowHeight = 'defaultRowHeight';
  static const defaultColumnWidth = 'defaultColumnWidth';
  static const printSettingsJson = 'printSettingsJson';
}

/// `sheet_row` / `sheet_column` columns.
abstract final class DimCols {
  static const height = 'height';
  static const width = 'width';
}

/// `cell` columns.
abstract final class CellCols {
  static const rowId = 'rowId';
  static const columnId = 'columnId';
  static const content = 'content';
  static const note = 'note';
  static const numberFormat = 'numberFormat';
  static const fontFamily = 'fontFamily';
  static const fontSize = 'fontSize';
  static const bold = 'bold';
  static const italic = 'italic';
  static const underline = 'underline';
  static const strikethrough = 'strikethrough';
  static const textColor = 'textColor';
  static const fillColor = 'fillColor';
  static const hAlign = 'hAlign';
  static const vAlign = 'vAlign';
  static const wrap = 'wrap';
  static const rotation = 'rotation';
  static const borderTop = 'borderTop';
  static const borderRight = 'borderRight';
  static const borderBottom = 'borderBottom';
  static const borderLeft = 'borderLeft';
  static const linkUrl = 'linkUrl';
}

/// `HorizontalAlign` (null = general).
enum HorizontalAlign { left, center, right }

/// `VerticalAlign`.
enum VerticalAlign { top, middle, bottom }

/// `WrapStrategy`.
enum WrapStrategy { overflow, wrap, clip }

/// `SheetKind`.
enum SheetKind { grid, chart }

/// `Dimension` of groups and structure operations.
enum Dimension { rows, columns }

/// `EmbeddedObjectKind`.
enum EmbeddedObjectKind { chart, image, slicer, drawing }

/// `TriggerKind`.
enum TriggerKind { onOpen, onEdit, onChange, onSelectionChange, timeDriven }

/// `ActorKind` of a change.
enum ActorKind { user, mcp, ai, script, system }

/// Parses an enum by name; null for null/unknown.
T? enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name == null) return null;
  if (name is T) return name;
  final s = name.toString();
  for (final v in values) {
    if (v.name == s) return v;
  }
  return null;
}
