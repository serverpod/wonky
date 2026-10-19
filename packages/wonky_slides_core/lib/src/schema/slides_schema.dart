/// Names of the synced Slides tables and their columns (specs/wonky_slides/02
/// §3, schema release S-1).
///
/// Row changes (`RowChange` of `wonky_revlog`) and the generic ingestion
/// API of the deck model use these names. Column names equal the Serverpod
/// field names of the RevLog table models of the server
/// (relations become `<name>Id`); `test/schema/slides_schema_test.dart`
/// checks them against the generated tables.
///
/// Value types in column maps (as Sheets):
/// - UUID columns (`id`, `…Id`, `createdBy`, `placeholderOf`, …): canonical
///   lower-case `String`;
/// - enums: the enum value `name` (`String`), e.g. `kind: 'shape'`;
/// - `DateTime` (UTC), `double`, `int`, `bool`, `String` as declared.
library;

/// Table names.
abstract final class SlidesTables {
  static const deck = 'deck';
  static const deckTheme = 'deck_theme';
  static const slideMaster = 'slide_master';
  static const slideLayout = 'slide_layout';
  static const slideGroup = 'slide_group';
  static const slide = 'slide';
  static const slideElement = 'slide_element';
  static const slideTableAxis = 'slide_table_axis';
  static const slideTableCell = 'slide_table_cell';
  static const slideBuild = 'slide_build';
  static const codeState = 'code_state';
  static const chartLink = 'chart_link';
  static const deckChangeLog = 'deck_change_log';

  /// Tables in dependency order (parents first): inserts are applied in this
  /// order, deletes in reverse. `slide_element` also references itself
  /// (`parentId`); its foreign keys are deferred, so a transaction may hold
  /// children before parents.
  static const dependencyOrder = [
    deck,
    deckTheme,
    slideMaster,
    slideLayout,
    slideGroup,
    slide,
    slideElement,
    slideTableAxis,
    slideTableCell,
    slideBuild,
    codeState,
    chartLink,
    deckChangeLog,
  ];

  /// Synced tables that are not part of the in-memory deck model (02 §11):
  /// the change log is written with every plan but never loaded.
  static const nonModelTables = {deckChangeLog};

  /// Rank of [table] in [dependencyOrder] (unknown tables last).
  static int rank(String table) {
    final i = dependencyOrder.indexOf(table);
    return i < 0 ? dependencyOrder.length : i;
  }

  /// The columns of every table (without the engine-managed `spaceId`), for
  /// validating row changes. Equal to the generated tables
  /// (`test/schema/slides_schema_test.dart`).
  static const Map<String, Set<String>> columns = {
    deck: {
      SlidesCols.id,
      DeckCols.title,
      DeckCols.width,
      DeckCols.height,
      DeckCols.sizePreset,
      DeckCols.themeId,
      DeckCols.appearance,
      DeckCols.language,
      DeckCols.showSlideNumbers,
      DeckCols.hideNumberOnTitle,
      DeckCols.firstSlideNumber,
      DeckCols.footerText,
      DeckCols.defaultsJson,
      DeckCols.guidesJson,
      DeckCols.presentJson,
      DeckCols.createdBy,
      SlidesCols.createdAt,
    },
    deckTheme: {
      SlidesCols.id,
      DeckThemeCols.deckId,
      SlidesCols.name,
      DeckThemeCols.sourceKey,
      DeckThemeCols.colorsJson,
      DeckThemeCols.fontsJson,
      DeckThemeCols.textStylesJson,
      DeckThemeCols.backgroundJson,
      DeckThemeCols.shapeStyleJson,
      DeckThemeCols.tableStyleJson,
      DeckThemeCols.codeStyleJson,
      DeckThemeCols.chartStyleJson,
      SlidesCols.sortKey,
      SlidesCols.createdAt,
    },
    slideMaster: {
      SlidesCols.id,
      SlideMasterCols.themeId,
      SlidesCols.name,
      SlidesCols.sortKey,
      SlidesCols.backgroundJson,
      SlidesCols.createdAt,
    },
    slideLayout: {
      SlidesCols.id,
      SlideLayoutCols.masterId,
      SlidesCols.name,
      SlideLayoutCols.key,
      SlidesCols.sortKey,
      SlidesCols.backgroundJson,
      SlidesCols.hideMasterElements,
      SlidesCols.hidden,
      SlidesCols.createdAt,
    },
    slideGroup: {
      SlidesCols.id,
      SlidesCols.deckId,
      SlidesCols.title,
      SlidesCols.sortKey,
      SlidesCols.parentId,
      SlideGroupCols.color,
      SlidesCols.skipped,
      SlidesCols.createdAt,
    },
    slide: {
      SlidesCols.id,
      SlidesCols.deckId,
      SlidesCols.sortKey,
      SlideCols.groupId,
      SlideCols.layoutId,
      SlidesCols.backgroundJson,
      SlidesCols.skipped,
      SlideCols.notes,
      SlidesCols.transitionJson,
      SlidesCols.hideMasterElements,
      SlideCols.timingsJson,
      SlidesCols.createdAt,
    },
    slideElement: {
      SlidesCols.id,
      SlidesCols.slideId,
      ElementCols.layoutId,
      ElementCols.masterId,
      SlidesCols.parentId,
      SlidesCols.kind,
      SlidesCols.name,
      ElementCols.x,
      ElementCols.y,
      ElementCols.width,
      ElementCols.height,
      ElementCols.rotation,
      ElementCols.flipH,
      ElementCols.flipV,
      ElementCols.zKey,
      ElementCols.readingKey,
      ElementCols.locked,
      SlidesCols.hidden,
      ElementCols.placeholderType,
      ElementCols.placeholderOf,
      ElementCols.matchKey,
      SlidesCols.text,
      ElementCols.textStyleJson,
      ElementCols.fillJson,
      ElementCols.strokeJson,
      ElementCols.effectsJson,
      ElementCols.opacity,
      ElementCols.dataJson,
      ElementCols.linkJson,
      ElementCols.altText,
      ElementCols.decorative,
      SlidesCols.createdAt,
    },
    slideTableAxis: {
      SlidesCols.id,
      SlidesCols.elementId,
      TableAxisCols.dimension,
      SlidesCols.sortKey,
      TableAxisCols.size,
      TableAxisCols.header,
      SlidesCols.createdAt,
    },
    slideTableCell: {
      SlidesCols.id,
      SlidesCols.elementId,
      TableCellCols.rowId,
      TableCellCols.columnId,
      SlidesCols.text,
      TableCellCols.fill,
      TableCellCols.borderTop,
      TableCellCols.borderRight,
      TableCellCols.borderBottom,
      TableCellCols.borderLeft,
      TableCellCols.vAlign,
      TableCellCols.padding,
      TableCellCols.rowSpan,
      TableCellCols.colSpan,
      SlidesCols.createdAt,
    },
    slideBuild: {
      SlidesCols.id,
      SlidesCols.slideId,
      SlidesCols.elementId,
      SlidesCols.kind,
      BuildCols.effect,
      SlidesCols.sortKey,
      BuildCols.trigger,
      BuildCols.delayMs,
      BuildCols.durationMs,
      BuildCols.easing,
      BuildCols.optionsJson,
      SlidesCols.createdAt,
    },
    codeState: {
      SlidesCols.id,
      SlidesCols.elementId,
      SlidesCols.sortKey,
      SlidesCols.label,
      CodeStateCols.code,
      CodeStateCols.language,
      SlidesCols.title,
      CodeStateCols.highlight,
      CodeStateCols.annotationsJson,
      SlidesCols.transitionJson,
      SlidesCols.createdAt,
    },
    chartLink: {
      SlidesCols.id,
      SlidesCols.elementId,
      ChartLinkCols.spreadsheetItemUuid,
      ChartLinkCols.chartObjectId,
      ChartLinkCols.sheetId,
      ChartLinkCols.sourceSpecJson,
      ChartLinkCols.dataSnapshotJson,
      ChartLinkCols.sourceVersion,
      ChartLinkCols.updatedAt,
      ChartLinkCols.updatedBy,
      ChartLinkCols.autoUpdate,
      SlidesCols.createdAt,
    },
    deckChangeLog: {
      SlidesCols.id,
      SlidesCols.deckId,
      DeckChangeLogCols.userId,
      DeckChangeLogCols.actorKind,
      DeckChangeLogCols.sessionId,
      SlidesCols.label,
      DeckChangeLogCols.summaryJson,
      DeckChangeLogCols.detailJson,
      DeckChangeLogCols.at,
      SlidesCols.createdAt,
    },
  };
}

/// Column names shared by several tables.
abstract final class SlidesCols {
  static const id = 'id';
  static const createdAt = 'createdAt';
  static const deckId = 'deckId';
  static const slideId = 'slideId';
  static const elementId = 'elementId';
  static const sortKey = 'sortKey';
  static const name = 'name';
  static const title = 'title';
  static const backgroundJson = 'backgroundJson';
  static const hideMasterElements = 'hideMasterElements';
  static const hidden = 'hidden';
  static const skipped = 'skipped';
  static const parentId = 'parentId';
  static const kind = 'kind';
  static const text = 'text';
  static const transitionJson = 'transitionJson';
  static const label = 'label';
}

/// `deck` columns (02 §3.1, 03 A-03-1, 10 A-10-1).
abstract final class DeckCols {
  static const title = 'title';
  static const width = 'width';
  static const height = 'height';
  static const sizePreset = 'sizePreset';
  static const themeId = 'themeId';
  static const appearance = 'appearance';
  static const language = 'language';
  static const showSlideNumbers = 'showSlideNumbers';
  static const hideNumberOnTitle = 'hideNumberOnTitle';
  static const firstSlideNumber = 'firstSlideNumber';
  static const footerText = 'footerText';
  static const defaultsJson = 'defaultsJson';
  static const guidesJson = 'guidesJson';
  static const presentJson = 'presentJson';
  static const createdBy = 'createdBy';
}

/// `deck_theme` columns (02 §3.2, 05 §2).
abstract final class DeckThemeCols {
  static const deckId = 'deckId';
  static const sourceKey = 'sourceKey';
  static const colorsJson = 'colorsJson';
  static const fontsJson = 'fontsJson';
  static const textStylesJson = 'textStylesJson';
  static const backgroundJson = 'backgroundJson';
  static const shapeStyleJson = 'shapeStyleJson';
  static const tableStyleJson = 'tableStyleJson';
  static const codeStyleJson = 'codeStyleJson';
  static const chartStyleJson = 'chartStyleJson';
}

/// `slide_master` columns (02 §3.2). The owning theme is `themeId`.
abstract final class SlideMasterCols {
  static const themeId = 'themeId';
}

/// `slide_layout` columns (02 §3.2).
abstract final class SlideLayoutCols {
  static const masterId = 'masterId';
  static const key = 'key';
}

/// `slide` columns (02 §3.3, 10 A-10-2).
abstract final class SlideCols {
  static const groupId = 'groupId';
  static const layoutId = 'layoutId';
  static const notes = 'notes';
  static const timingsJson = 'timingsJson';
}

/// `slide_group` columns (02 §3.4).
abstract final class SlideGroupCols {
  static const color = 'color';
}

/// `slide_element` columns (02 §3.5).
abstract final class ElementCols {
  static const layoutId = 'layoutId';
  static const masterId = 'masterId';
  static const x = 'x';
  static const y = 'y';
  static const width = 'width';
  static const height = 'height';
  static const rotation = 'rotation';
  static const flipH = 'flipH';
  static const flipV = 'flipV';
  static const zKey = 'zKey';
  static const readingKey = 'readingKey';
  static const locked = 'locked';
  static const placeholderType = 'placeholderType';
  static const placeholderOf = 'placeholderOf';
  static const matchKey = 'matchKey';
  static const textStyleJson = 'textStyleJson';
  static const fillJson = 'fillJson';
  static const strokeJson = 'strokeJson';
  static const effectsJson = 'effectsJson';
  static const opacity = 'opacity';
  static const dataJson = 'dataJson';
  static const linkJson = 'linkJson';
  static const altText = 'altText';
  static const decorative = 'decorative';

  /// The owner columns: exactly one is set (02 §3.5).
  static const owners = [SlidesCols.slideId, layoutId, masterId];

  /// The frame (02 §2.2).
  static const frame = [x, y, width, height];
}

/// `slide_table_axis` columns (02 §3.6).
abstract final class TableAxisCols {
  static const dimension = 'dimension';
  static const size = 'size';
  static const header = 'header';
}

/// `slide_table_cell` columns (02 §3.6).
abstract final class TableCellCols {
  static const rowId = 'rowId';
  static const columnId = 'columnId';
  static const fill = 'fill';
  static const borderTop = 'borderTop';
  static const borderRight = 'borderRight';
  static const borderBottom = 'borderBottom';
  static const borderLeft = 'borderLeft';
  static const vAlign = 'vAlign';
  static const padding = 'padding';
  static const rowSpan = 'rowSpan';
  static const colSpan = 'colSpan';
}

/// `slide_build` columns (02 §3.7, 06 A-06-1).
abstract final class BuildCols {
  static const effect = 'effect';
  static const trigger = 'trigger';
  static const delayMs = 'delayMs';
  static const durationMs = 'durationMs';
  static const easing = 'easing';
  static const optionsJson = 'optionsJson';
}

/// `code_state` columns (02 §3.8, 07 A-07-2).
abstract final class CodeStateCols {
  static const code = 'code';
  static const language = 'language';
  static const highlight = 'highlight';
  static const annotationsJson = 'annotationsJson';
}

/// `chart_link` columns (02 §3.9, 08 A-08-2).
abstract final class ChartLinkCols {
  static const spreadsheetItemUuid = 'spreadsheetItemUuid';
  static const chartObjectId = 'chartObjectId';
  static const sheetId = 'sheetId';
  static const sourceSpecJson = 'sourceSpecJson';
  static const dataSnapshotJson = 'dataSnapshotJson';
  static const sourceVersion = 'sourceVersion';
  static const updatedAt = 'updatedAt';
  static const updatedBy = 'updatedBy';
  static const autoUpdate = 'autoUpdate';
}

/// `deck_change_log` columns (02 §3.10).
abstract final class DeckChangeLogCols {
  static const userId = 'userId';
  static const actorKind = 'actorKind';
  static const sessionId = 'sessionId';
  static const summaryJson = 'summaryJson';
  static const detailJson = 'detailJson';
  static const at = 'at';
}
