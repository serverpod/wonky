import 'package:wonky_revlog/rows.dart' show CurrentRowReader;

import 'kinds.dart';
import 'records.dart';

/// Read interface of a deck (02 §11), implemented by `DeckModel` and by
/// read-only snapshot/version models. Every list is in its key-space order
/// (`(sortKey, id)`, 02 §2.3) and excludes rows whose parent is gone only
/// where stated.
abstract interface class DeckReader implements CurrentRowReader {
  /// The deck (= space) id.
  String get deckId;

  /// The `deck` row, or null before it is loaded.
  DeckRec? get deck;

  /// Incremented after every applied batch.
  int get version;

  /// Any record by table and id.
  SlidesRecord? record(String table, String id);

  /// Every record of [table] (unordered).
  Iterable<SlidesRecord> records(String table);

  /// Typed lookups.
  SlideRec? slide(String id);

  /// Group by id.
  SlideGroupRec? group(String id);

  /// Element by id.
  SlideElementRec? element(String id);

  /// Theme by id.
  DeckThemeRec? theme(String id);

  /// Master by id.
  SlideMasterRec? master(String id);

  /// Layout by id.
  SlideLayoutRec? layout(String id);

  /// Build by id.
  SlideBuildRec? build(String id);

  /// Themes in panel order.
  List<DeckThemeRec> get themes;

  /// The deck's default theme: `deck.themeId` if it exists, else the theme
  /// with the smallest id (02 §10), else null.
  DeckThemeRec? get defaultTheme;

  /// Masters of [themeId] in order.
  List<SlideMasterRec> mastersOf(String themeId);

  /// Layouts of [masterId] in order.
  List<SlideLayoutRec> layoutsOf(String masterId);

  /// Groups in top-level order.
  List<SlideGroupRec> get groups;

  /// Slides in the flattened presentation order (02 §3.4): the top-level key
  /// space holds groups and ungrouped slides; a group contributes its slides
  /// in their key order; slides whose group is missing come last (02 §10).
  List<SlideRec> get slides;

  /// Slides of [groupId] in order.
  List<SlideRec> slidesInGroup(String groupId);

  /// Elements of [ownerId] (slide, layout or master) whose `parentId` is
  /// [parentId] (null = top level), back to front (`(zKey, id)`).
  List<SlideElementRec> elementsOf(String ownerId, {String? parentId});

  /// Every element of [ownerId] (all depths, unordered).
  Iterable<SlideElementRec> allElementsOf(String ownerId);

  /// Axes of table [elementId] in [dimension] in order.
  List<SlideTableAxisRec> axesOf(
    String elementId,
    TableAxisDimension dimension,
  );

  /// Cells of table [elementId] (unordered).
  Iterable<SlideTableCellRec> cellsOf(String elementId);

  /// Builds of [slideId] in order.
  List<SlideBuildRec> buildsOf(String slideId);

  /// Code states of [elementId] in order.
  List<CodeStateRec> codeStatesOf(String elementId);

  /// The chart link of [elementId], or null.
  ChartLinkRec? chartLinkOf(String elementId);
}
