# Sheets 03 · Grid and Editing

The grid is the heart of Wonky Sheets: a virtualized, painter-based viewport over the in-memory
`WorkbookModel` ([02-data-model.md](02-data-model.md) §6) plus every interaction that happens on
cells — selection, keyboard navigation, cell and formula editing, fill handle, drag-move,
clipboard, structural operations, in-cell widgets, collaborators' presence and accessibility.

Related: menus/toolbar/dialogs in [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md),
formats in [06-formatting.md](06-formatting.md), formula semantics in
[05-formula-engine.md](05-formula-engine.md), data tools (sort, filter, DV, groups, find) in
[07-data-tools.md](07-data-tools.md), floating objects in
[08-charts-and-objects.md](08-charts-and-objects.md), comments/history in
[10-collaboration-history.md](10-collaboration-history.md), MCP tools in
[12-mcp-and-ai.md](12-mcp-and-ai.md).

## 0. Conventions

- **Command ids** follow `sheets.<area>.<action>` (suite 08 §1). Areas used here: `nav`,
  `select`, `cell`, `edit`, `fill`, `cells`, `rows`, `cols`, `sheet`, `notes`, `link`, `dv`,
  `view`, `freeze`. Every command listed here is registered in
  `wonky_sheets/lib/commands/` and appears in the catalogue (§19).
- **Shortcuts** are written `Mod+X` (⌘ on macOS, Ctrl elsewhere); `Alt` = ⌥ on macOS. Where macOS
  differs it is given as `mac: …`. Browser-reserved chords (⌘W/T/N/L, Ctrl+W/T/N/L, F5 on web,
  F11) are never bound. Chords that browsers would otherwise handle but that we override
  (Mod+D, Mod+R, Mod+K, Mod+F, Mod+P, Mod+O) call `preventDefault` only while the grid or a
  Sheets surface has focus.
- **Undo**: "1 step" means one `UndoStep` in domain `sheets.rows` produced by one session write
  (one plan, possibly chunked into an op group; 02 §7). "—" means not undoable (view state).
- **Scopes** (suite 08 §1.2): `grid` (grid focused, not editing), `cellEditor` (cell editor or
  formula bar focused), `global`.
- Indices are **0-based** in code; A1 notation is used in the UI and in MCP arguments.

---

## 1. Feature folder layout and class map

> **As built (2026-10-14).** The editor follows this map with these differences:
> `features/sheet_editor/` holds `SheetEditorController` (the hub of §1.1, also the
> navigation logic), `SheetsDocumentController` (the shell's `DocumentController`: title,
> role, undo handler, selection snapshots, Edit-menu contributions) and
> `sheet_editor_screen.dart` (screen + `SpreadsheetLoadingView`). The grid is
> `grid/grid_area.dart` (widget + pointer router + scrollbars + "Add rows" footer),
> `grid/viewport/` (`GridGeometry`/`GridPane`, `GridScrollController`, `GridPass` render
> object), `grid/paint/` (`GridLayer` API, `CellRenderCache` over the core
> `CellDisplayResolver`, `TextLayoutCache`, `layers/content_layers.dart`,
> `layers/overlay_layers.dart`), `grid/selection/` (`GridSelection`,
> `GridSelectionController`, `DataEdgeFinder`). The cell editor is `cell_editor/`
> (`CellEditorController`, `CellEditorOverlay`, `FormulaTextController`, `FormulaAssist`).
> The fill handle, drag-move, resize and freeze drags live in the grid's pointer router;
> structure operations are plain commands (`commands/structure_commands.dart`); the
> `sheets.rows` undo adapter is `features/model/sheets_undo.dart`. Colors are in
> `theme/sheets_tokens.dart` (`GridPaintTokens`).

All paths are in `wonky_sheets/lib/`. Each top-level folder under
`features/` is independently ownable; dependencies flow downward in this list
(`model` ← `grid` ← `cell_editor` …). Pure logic that the server/MCP also needs lives in
`wonky_sheets_core` (marked **core**).

```
features/
  model/                                   # owned by 02: WorkbookSession (write path), LoadingGate, row loading; the model itself is core
  revlog/                                  # owned by 02: LoggedWorkbookSession, SheetsRevLog (RevLog client, suite 17)
  sheet_editor/
    sheet_editor_screen.dart               # SheetEditorScreen: header, menubar, toolbar, formula bar, grid, tab bar, status bar
    sheet_editor_controller.dart           # SheetEditorController: active sheet, mode (edit/view), wires sub-controllers
    sheet_view_state.dart                  # SheetViewState (per sheet: scroll, zoom, showFormulas, selection) ⇄ LocalViewState
  grid/
    grid_area.dart                         # GridArea: corner + headers + panes + overlays (Stack)
    viewport/
      grid_scrollable.dart                 # GridScrollable: wraps TwoDimensionalScrollable, wheel/zoom/pinch handling
      grid_geometry.dart                   # GridGeometry: zoom, DPR, pixel⇄index, cell rects, merged rects, pane mapping
      pane_layout.dart                     # PaneLayout: frozen quadrants (corner/top/left/main) + offsets
      visible_window.dart                  # VisibleWindow: index ranges per pane incl. overscan & overflow margins
      grid_content_viewport.dart           # GridContentViewport (LeafRenderObjectWidget) + RenderGridContent (static layers, tile cache)
      grid_overlay_viewport.dart           # GridOverlayViewport + RenderGridOverlay (dynamic layers)
    paint/
      grid_layer.dart                      # abstract GridLayer { paint(GridPaintContext, Canvas, PaneRect) }
      layers/background_layer.dart         # sheet bg, banding, cell fill, CF fill, data bars, protected stripes
      layers/gridline_layer.dart
      layers/cell_content_layer.dart       # text (overflow/wrap/clip/rotation), checkboxes, chips, CF icons, sparklines, links
      layers/border_layer.dart
      layers/decoration_layer.dart         # note/comment/error triangles, filter buttons, dropdown arrows, spill frames
      layers/loading_layer.dart            # skeleton shimmer for not-yet-loaded chunks
      layers/selection_layer.dart          # local selection, active cell, fill handle, copy marching ants
      layers/reference_highlight_layer.dart# formula-edit colored reference boxes
      (RemotePresenceLayer from collab/presence/ is registered as a dynamic layer, 10 §1.2)
      layers/drag_feedback_layer.dart      # drag-move / fill / resize / header-move previews
      layers/frozen_divider_layer.dart
      cell_render_resolver.dart            # CellRenderResolver → CellRenderInfo (effective format + CF + DV + overlay value)
      text_layout_cache.dart               # TextLayoutCache (LRU of ui.Paragraph)
      tile_cache.dart                      # TileCache (ui.Picture per 512×512 tile per pane)
      grid_paint_tokens.dart               # GridPaintTokens (from WonkyColors + theme brightness)
    headers/
      column_header_painter.dart, row_header_painter.dart, corner_header.dart
      header_hit_tester.dart               # resize zones, hidden-indicator arrows, group gutter hits
      header_resize_controller.dart        # HeaderResizeController
      header_move_controller.dart          # HeaderMoveController (drag reorder rows/cols)
    freeze/freeze_bar_controller.dart      # FreezeBarController
    selection/
      grid_selection.dart                  # GridSelection, SelectionRange, CellRef (immutable, id-based)
      resolved_selection.dart              # ResolvedSelection (index-based cache)
      grid_selection_controller.dart       # GridSelectionController (ValueNotifier<GridSelection>)
      data_edge_finder.dart                # DataEdgeFinder (Mod+arrow, data region for Mod+A)
    interaction/
      grid_pointer_router.dart             # GridPointerRouter: hit-test → gesture handler (select/fill/move/resize/widget)
      grid_keyboard_handler.dart           # GridKeyboardHandler: key → command via KeymapService(scope grid)
      auto_scroller.dart                   # AutoScroller during drags near edges
      grid_scroll_controller.dart          # GridScrollController: scrollToCell, page up/down, follow mode
    a11y/grid_semantics.dart, a11y/selection_announcer.dart
  cell_editor/
    cell_editor_controller.dart            # CellEditorController: modes, session lifecycle, commit/cancel
    cell_edit_session.dart                 # CellEditSession: target cell(s), FormulaTextEditingController, initial value
    cell_editor_overlay.dart               # CellEditorOverlay widget (positioned EditableText)
    input_commit_service.dart              # InputCommitService: parse → DV → protection → session write
    column_autocomplete.dart               # ColumnAutocomplete (P1)
    rich_text_editing.dart                 # RichTextEditingController (runs, P1)
    formula/
      formula_text_controller.dart         # FormulaTextEditingController (buildTextSpan → token colors)
      reference_colorizer.dart             # ReferenceColorizer (ref → color index)
      point_mode_controller.dart           # PointModeController (click/arrow to insert references)
      reference_box_controller.dart        # ReferenceBoxController (drag/resize colored boxes on grid)
      function_autocomplete.dart           # FunctionAutocompleteController + popup widget
      signature_help.dart                  # SignatureHelpController + card widget
      paren_matcher.dart
      formula_preview.dart                 # FormulaPreviewController (live result/error preview)
  formula_bar/
    formula_bar.dart                       # FormulaBar widget (name box | fx | editor | ✨)
    formula_bar_controller.dart            # FormulaBarController (expanded state, display text for selection)
    name_box.dart, name_box_controller.dart# NameBoxController (parse A1/named range, jump, create named range)
  fill/fill_handle_controller.dart         # FillHandleController (drag, double-click, preview)
  drag_move/range_drag_controller.dart     # RangeDragController (move/copy by border drag)
  clipboard/
    clipboard_service.dart                 # ClipboardService (super_clipboard), copy/cut/paste/paste special
    sheets_clipboard_payload.dart          # SheetsClipboardPayload (internal rich payload)
    paste_planner.dart                     # PastePlanner: source → target writes (tiling, transpose, modes)
  structure/structure_service.dart         # StructureService: insert/delete/move/hide/resize rows/cols/cells, merges
  in_cell/
    checkbox_interaction.dart, dropdown_picker.dart (DropdownPickerPopover), link_hover_card.dart,
    note_popover.dart, comment_indicator_card.dart, error_tooltip.dart, smart_chip_*.dart (P2),
    spill_inspector.dart, pivot_cell_guard.dart
  collab/presence/                         # owned by 10: SheetsPresenceController, RemotePresenceLayer,
                                           #   CommitHintOverlay, FollowController (grid only hosts the layer)
commands/
  nav_commands.dart, select_commands.dart, cell_commands.dart, edit_commands.dart,
  clipboard_commands.dart, fill_commands.dart, rows_commands.dart, cols_commands.dart,
  cells_commands.dart, sheet_commands.dart, view_commands.dart, notes_commands.dart,
  link_commands.dart, dv_interaction_commands.dart
```

**Core (`wonky_sheets_core/lib/`)** pieces used here: `address/` (A1 parsing, `ColumnLetters`),
`input/input_parser.dart` (`InputParser`), `format/` (number formatter, 06),
`formula/lexer.dart` (`FormulaLexer`, tokens for highlighting), `formula/codec.dart`
(`FormulaCodec`, `translate` for relative copy), `formula/reference_rewriter.dart`
(`ReferenceRewriter` for cut/move/delete), `fill/series_detector.dart` (`SeriesDetector`),
`clipboard/tsv_codec.dart`, `clipboard/html_table_codec.dart` (`HtmlTableCodec`, uses
`package:html`).

### 1.1 Controller wiring

```dart
class SheetEditorController extends ChangeNotifier {
  final WorkbookModel model;                 // 02 §6
  final WorkbookSession session;             // 02 §7 (plans, outbox, undo)
  final FormulaEngine engine;                // 05
  final GridSelectionController selection;
  final CellEditorController editor;
  final FormulaBarController formulaBar;
  final GridScrollController scroll;
  final FillHandleController fill;
  final RangeDragController dragMove;
  final ClipboardService clipboard;
  final StructureService structure;
  final SheetsPresenceController presence;   // 10 §1.6
  final CommitHintOverlay commitHints;       // 10 §2.2
  String get activeSheetId;
  EditorMode get mode;                       // edit | view (role-dependent, suite 06)
  SheetViewState viewState(String sheetId);
}
```

Commands receive the `SheetEditorController` through `CommandContext.documentController`. No
widget writes to the session directly.

---

## 2. Rendering

### 2.1 Decision: custom painter-based viewport (not `TableView`)

| Criterion | `two_dimensional_scrollables` `TableView` 0.5.x | Custom leaf render object over `TwoDimensionalScrollable` (**chosen**) |
|-----------|--------------------------------------------------|-------------------------------------------------------------------------|
| Cell model | One child widget/RenderBox per visible cell (build + layout per cell per scroll frame) | No per-cell widgets; cells are painted directly from `CellStore` |
| Pinned rows/cols | Built in | Implemented by `PaneLayout` (4 quadrants), trivial with a painter |
| Merged cells | Built in (`TableVicinity` spans) | Implemented via `RuleIndex` merge interval tree |
| Text overflow into empty neighbours | Not supported (children clip to their cell) | Supported (content layer paints across cells) |
| Borders with conflict resolution, double borders | Per-cell decorations only | Single border pass with shared-edge resolution |
| Overlays spanning cells (selection, remote selections, ref boxes, spill frames, fill handle) | Separate overlay needed anyway | Native layers |
| 1M–10M cells, 60 fps, 2,000+ visible cells at 50 % zoom | Element/RenderObject churn of thousands of children per frame | Bounded per-frame cost: paint only; tile pictures reused |
| Hit testing | Per child | Geometry lookup O(log n) via Fenwick tree |

Decision: the grid is a **custom painter-based viewport**. We use Flutter's framework class
`TwoDimensionalScrollable` (in `package:flutter/widgets.dart`) only for scroll physics, drag,
fling, scrollbars and `ViewportOffset`s, and supply our own leaf render objects as the viewport.
`two_dimensional_scrollables` stays a dependency only for small auxiliary tables (import preview,
paste preview, pivot editor field lists) — it is **not** used for the main grid.

Floating objects (charts, images, slicers) and interactive popovers are real widgets in an
`ObjectLayer` positioned above the panes (owned by 08).

### 2.2 Widget/render tree

> **As built.** Two leaf render objects (`GridPass`, `RenderGridPass`, each a repaint
> boundary) paint the whole grid: the *content* pass (layers with `zOrder` < 500) and the
> *overlay* pass (selection, reference boxes, drag feedback, frozen dividers, headers).
> Scrolling is not built on `TwoDimensionalScrollable`: `GridScrollController` holds the
> offsets and the grid handles wheel, trackpad pan/zoom (`PointerPanZoom*`), Mod+wheel
> zoom and draggable scrollbar thumbs itself. The cell editor `EditableText` stays mounted
> (invisible) above the passes, see §8.3.

```
GridArea (Stack, Focus scope "grid")
├── CornerHeader                      (select-all button + freeze bar handles)
├── ColumnHeaderStrip ×2              (frozen part + scrolling part; one RenderBox painting both)
├── RowHeaderStrip ×2
├── GridScrollable(TwoDimensionalScrollable, diagonalDragBehavior: free)
│   └── viewportBuilder → Stack
│       ├── GridContentViewport  (RenderGridContent, repaint boundary)    ← static layers, tile cache
│       ├── GridOverlayViewport  (RenderGridOverlay, repaint boundary)    ← dynamic layers
│       ├── ObjectLayer          (08: charts/images/slicers widgets, clipped per pane)
│       ├── InCellWidgetLayer    (dropdown picker anchors, link card anchors — CompositedTransformTargets)
│       └── CellEditorOverlay    (positioned EditableText while editing)
├── AddRowsFooter                     ("Add [1000] more rows at bottom")
└── Scrollbars (WonkyScrollArea styling; vertical + horizontal)
```

`RenderGridContent` and `RenderGridOverlay` both read a shared `GridGeometry` (a
`ChangeNotifier`) and call `applyViewportDimension`/`applyContentDimensions` on the vertical and
horizontal `ViewportOffset`s in `performLayout` (content extent = total scrollable size minus
the frozen extent; see §2.3).

### 2.3 Geometry, panes and coordinates

- **Logical units**: row heights and column widths are stored at 100 % zoom in logical pixels
  (02: `defaultRowHeight` 21, `defaultColumnWidth` 100). Screen size = stored × `zoom`.
- `AxisIndex` (02 §6) holds a Fenwick tree of 100 %-sizes (hidden and filter-hidden = 0).
  `GridGeometry.rowTop(i) = fenwick.prefix(i) × zoom`; `rowAt(y)` = Fenwick lower-bound
  search on `y / zoom` — both O(log n).
- **Row display order** (07 §4.4, sorted filter views): `GridGeometry(rowOrder:)` shows a
  contiguous block of rows below the frozen rows in a permuted order (`ViewRowOrder`, core):
  positions, hit testing and scrolling work in display rows, the pane API stays in model rows
  (`GridPane.rows` iterates the rows shown in display order), and selections made on screen are
  display ranges that resolve to several model ranges (§6.1). Row headers keep model numbers.
- **Panes** (`PaneLayout`), given `frozenRows = fr`, `frozenColumns = fc`:

  | Pane | Rows | Columns | Scrolls |
  |------|------|---------|---------|
  | corner | 0..fr-1 | 0..fc-1 | never |
  | top | 0..fr-1 | fc.. | horizontally |
  | left | fr.. | 0..fc-1 | vertically |
  | main | fr.. | fc.. | both |

  Content extents: `vertical = rowTop(rowCount) - rowTop(fr)`, `horizontal = colLeft(colCount) -
  colLeft(fc)`. A point `(x, y)` in viewport space maps to grid space by subtracting the pane
  origin and adding the pane's scroll offset. Each pane paints with `canvas.clipRect(paneRect)`.
- Frozen extent must leave ≥ 50 px of scrollable area; otherwise freeze commands show
  "The frozen area would be larger than the window. Zoom out or freeze fewer rows."
- **Merged cells** crossing the frozen boundary are painted in each pane clipped (Google
  behavior); selecting them selects the whole merge.
- **Pixel snapping**: `snap(v) = (v * dpr).roundToDouble() / dpr`. Every cell edge is snapped
  once in `GridGeometry` (cached per visible row/col per frame), so gridlines, fills and borders
  share identical edges. 1-px lines are drawn as filled rects of width `max(1, (dpr).floor()) /
  dpr` aligned to the snapped edge (no half-pixel blur). Text baselines are snapped.
- **Zoom** 50–200 % (`sheets.view.zoom`), steps 50, 75, 90, 100, 125, 150, 200 in the toolbar
  select; `Mod+wheel`/pinch zoom continuously in 5 % steps clamped. Zoom is per user and per
  spreadsheet (`LocalViewState`). Fonts scale with zoom; header heights/widths scale with zoom.
  Zoom keeps the active cell (or pointer location for wheel/pinch) fixed on screen.
- **Device pixel ratio** changes (window moved across monitors) invalidate the tile cache and
  text layouts.

### 2.4 Layers

Static layers are painted by `RenderGridContent` into tile pictures; dynamic layers by
`RenderGridOverlay` every frame they change. Order (bottom → top):

| # | Layer | Static/dynamic | Content |
|---|-------|----------------|---------|
| 1 | Background | static | Canvas bg (`page`-like sheet bg token), banding colors (06 §14), effective fill color, CF fill/color-scale fill (06 §15), protected-range stripes (when view option on, §16) |
| 2 | CF data bars | static | Bars per 06 §15.6 (under text) |
| 3 | Gridlines | static | `gridLine` token; skipped inside merges; skipped when `Sheet.showGridlines == false`; cells with a fill paint over gridlines on their own edges only where neighbour also filled (Google look: fill covers gridline) |
| 4 | Cell content | static | Text with overflow/wrap/clip/rotation, rich runs, links, checkboxes, dropdown chips/arrows, CF icons (P2), sparklines (08), in-cell images (08), spill & pivot overlay values, commit-hint values, loading skeleton |
| 5 | Borders | static | Resolved borders (06 §8.4) |
| 6 | Decorations | static | Note triangle (black/`foreground`), comment triangle (`commentHighlight`), error triangle (`destructive`), DV-invalid triangle (`warning`), filter header buttons (07), group outline gutter (07, painted in headers) |
| 7 | Find highlights | dynamic | `findMatch`/`findMatchActive` fills (07) |
| 8 | Remote selections | dynamic | Presence-colored ranges, active-cell frames, name flags, editing marker (§15) |
| 9 | Reference boxes | dynamic | Formula-edit colored boxes with handles (§8.7) |
| 10 | Local selection | dynamic | `selectionFill` over non-active cells of ranges, `selectionBorder` 1 px range outline, 2 px active-cell frame, fill handle (6×6 square), copy/cut marching ants (dashed 1 px, 8 px dash, animated 30 fps), spill-range frame of selected anchor |
| 11 | Drag feedback | dynamic | Fill preview (dashed outline), move preview (thick outline), resize guide line, header-move drop line |
| 12 | Frozen dividers | dynamic | 1 px `border` lines + the draggable freeze bars (thicker 4 px in headers) |
| 13 | Objects | widgets | Charts, images, slicers (08) |
| 14 | Cell editor | widget | `CellEditorOverlay` |

Pivot overlays and spill results are not separate layers: `CellRenderResolver` returns the
overlay value for those cells; the decoration layer draws the spill frame.

### 2.5 Cell render pipeline

```dart
/// Produced per visible cell per paint (cached per tile; invalidated by dirty notifications).
class CellRenderInfo {
  final String? displayText;        // formatted value (06 §5) or formula text when showFormulas
  final List<TextRun>? runs;        // rich text runs (r: content)
  final ResolvedFormat format;      // effective attributes after cell▸row▸col▸sheet▸theme + banding + CF
  final Color? fill;                // after banding/CF
  final Color textColor;            // after number-format color ([Red]) and CF
  final HorizontalAlign hAlign;     // resolved general alignment (06 §9.1)
  final CellWidgetKind widget;      // none, checkbox, dropdownChip, dropdownArrow, smartChip, image, sparkline
  final bool isError, hasNote, hasComment, isInvalid, isSpillAnchor, isOverlay, isLoading;
  final double? dataBarFraction;    // CF data bar
}
```

`CellRenderResolver.resolve(sheetId, rowIdx, colIdx)` steps:
1. Look up `CellRecord` in `CellStore`; if absent, check overlays (spill / pivot via the formula
   engine's `OverlayIndex`) and commit hints.
2. Effective format: per attribute cell ▸ row `formatJson` ▸ column `formatJson` ▸ sheet
   `formatJson` ▸ spreadsheet theme defaults (06 §1).
3. Value: literal from content, or computed value from `FormulaEngine.valueOf(cellId)`;
   formatted with `NumberFormatter` (06 §5, cached by (pattern, locale, value)).
4. Banding then conditional formatting (06 §14–15) override fill/text attributes.
5. Data validation decides `widget` (checkbox, dropdown) and `isInvalid` (07).
6. `showFormulas` view toggle: formulas show A1 text, numbers show raw value (`General`), left
   aligned, column widths doubled visually (Google behavior; not persisted).

### 2.6 Text layout and overflow

- Text is laid out with `ui.ParagraphBuilder` using the effective font (bundled cell fonts,
  06 §6), size × zoom, weight/style/decoration, color; rich runs push styles per run.
- **`TextLayoutCache`**: LRU (default 20,000 entries, ~30 MB cap) keyed by
  `(text, runsHash, styleKey, wrapWidth?, zoom)`. Unwrapped text is laid out with infinite
  width once; its `maxIntrinsicWidth` drives overflow. Cache hit rate target ≥ 95 % while
  scrolling.
- **Wrap strategies** (06 §9.3):
  - `overflow` (default): if text is wider than the cell and the neighbour(s) in the overflow
    direction are **empty** (no content, no overlay value, not merged, not a widget cell), text
    paints into them, clipped at the first non-empty cell or the pane edge. Direction: left-
    aligned → right; right-aligned → left; centered → both sides symmetrically. Numbers never
    overflow: a number that doesn't fit renders `####` filling the cell width (Google: numbers
    in narrow columns show `###`; dates too).
  - `wrap`: word-wrap at cell width minus padding (3 px left/right at 100 %); breaks long words
    by grapheme; row auto-height grows (§13.6).
  - `clip`: clipped to cell rect.
- **Overflow scan**: for each row in the visible window, cells up to 50 columns left/right of the
  window (`VisibleWindow.overflowMargin`) whose text could overflow into it are included. The
  scan uses `CellStore` row occupancy lists so it is O(non-empty cells).
- **Vertical alignment**: bottom (default), middle, top; padding 2 px top/bottom at 100 %.
- **Rotation** (06 §9.4): paint with `canvas.rotate`; rotated text does not overflow
  horizontally in v1 (clipped to the cell plus row auto-height growth); `vertical stacked`
  (255) stacks graphemes top-to-bottom.
- Line breaks (`\n`) inside cell text are always rendered as separate lines (Google behavior),
  regardless of the wrap strategy; the row auto-grows (§13.6) and overflow/clip apply per line.
- Hyperlinks paint in the theme link color with underline unless the cell explicitly sets text
  color/underline=false.

### 2.7 Tile cache and frame budget

> **As built.** No tile cache yet: both passes repaint the visible window on scroll, with
> per-cell render data (`CellRenderCache`) and laid-out paragraphs (`TextLayoutCache`, LRU
> 20,000) cached. **Render-cache invalidation (CQ-41):** a content or note edit
> (`CellsChanged` without format keys) drops the changed cells and every cached cell without
> a constant value (formulas, empty cells a spill or pivot may reach — the engine is
> pull-based, so dependents are known only when they are read again); constant cells stay.
> Sheets with conditional formatting, validation or pivots are dropped whole on any content
> change (their display reads other cells, also across sheets); a CF draft being previewed
> drops everything. An engine `RecalcBatch` (script drains, `recalcAll`) drops its cells and
> spill rectangles (everything above 20,000). Format, structure, sheet, rule, name and
> spreadsheet changes, theme/locale changes and streaming rows still drop everything. The
> border fast path (`sheetHasBorders`, read on every content paint) is O(1): a per-sheet flag
> kept from model batches (a cell format change can only turn it on; structure and sheet
> changes rescan once). The rich-text paragraph cache keys on the theme its run colors were
> resolved with. **Geometry (S-06):** `SheetEditorController.geometry` is the grid
> viewport's geometry at the current scroll, zoom and model state, memoized until one of them
> or a repaint signal changes (it also keeps the scroll limits). The overlay pass records the
> viewport size during layout; nothing is written during paint, and overlays built before
> the paint (scrollbars, chips, buttons, collaborator cards) use this frame's geometry. The
> pointer cursor is its own `ValueNotifier`, so cursor changes rebuild only the
> `MouseRegion`, not the passes. `test/features/grid/grid_performance_test.dart`
> (tag `slow`) scrolls a 100k × 10 (1M cells) sheet: median 12.6 ms, p95 20 ms per frame for
> both passes in the debug test VM (JIT; release builds are faster). Tiles remain the plan if
> the release build misses the budget.

- Static layers are recorded into `ui.Picture` tiles of 512 × 512 logical px per pane at the
  current zoom/DPR. `TileCache` keyed `(sheetId, pane, tileX, tileY, zoom, dpr, theme)`, max 96
  tiles (LRU). Scrolling only composites cached tiles and records newly exposed ones.
- **Invalidation**: the model emits `CellsChanged(sheetId, dirtyRange)`,
  `AxisChanged(sheetId, dimension, fromIndex)` (insert/delete/move/resize/hide shifts everything
  after `fromIndex`), `RulesChanged(sheetId, ranges)`, `ValuesRecalculated(cellIds)` from the
  engine, `ThemeChanged`. Each maps to tiles to drop. Dirty rects are coalesced per frame.
- **Frame budget** (desktop, 1M-cell sheet, 4K window at 100 %): ≤ 8 ms UI-thread time per scroll
  frame (record ≤ 2 new tiles per frame; others wait one frame with the previous zoom's picture
  scaled, never blank), ≤ 4 ms raster. If tile recording would exceed budget, remaining tiles are
  scheduled with `SchedulerBinding.scheduleTask(Priority.animation)` and the area shows the
  background + gridlines only for ≤ 1 frame.
- Overscan: one tile ring in scroll direction recorded during idle
  (`Priority.idle`).
- Web (CanvasKit/Skwasm): same strategy; `--wasm` build (suite 12). Paragraph layout is the
  dominant cost: prefer cache hits; numbers formatted through a per-pattern cache.

### 2.8 Loading skeleton

Until the session is ready (`WorkbookReady`) the editor shows the document shimmer with an
"Opening spreadsheet…" card and an indeterminate progress bar; there is no download percentage,
because a spreadsheet not on the device is ready after its structure and the viewport's cells
(02 §6, 17 part 6 §5.1). A spreadsheet that isn't on the device can't open offline
("This spreadsheet isn't available offline"; it reopens when the connection returns).

`CellStore` streams rows in 10k-row chunks after the viewport-first load (02 §6). Rows whose
chunk is not loaded paint `ShadSkeleton`-colored rounded bars (shimmer animated in the overlay
viewport at 2 Hz, disabled with Reduce motion). Typing into a not-yet-loaded cell shows a toast
"Still loading this part of the sheet…" and is ignored; navigation works.

> **As built.** `LoadingLayer` (`grid/paint/layers/loading_layer.dart`, overlay pass) paints
> `skeleton` bars of varying width in rows whose cells are not loaded, toggling at 2 Hz (static
> with the platform's reduce motion), asks the session for the visible rows first and removes
> itself when loading completes. Blocks are 500 rows (02 §6). The editor's write gate refuses
> edits there before the cell editor opens. A formula that reads rows not loaded yet (directly,
> or through single-cell references to such formulas, 4 levels) shows `#LOADING` — the muted
> italic "Loading…" — instead of a partial value until they arrive
> (`features/model/loading_formula_source.dart`, the grid's `CellSource` while streaming).

### 2.9 Grid paint tokens (light/dark)

`GridPaintTokens` derives from `WonkyColors` (suite 02 §2): `gridLine`, `gridHeaderBg`,
`gridHeaderFg`, `gridHeaderSelectedBg`, `selectionFill`, `selectionBorder`, `fillHandle`,
`commentHighlight`, `findMatch*`, `presence1…12`, plus Sheets-only tokens defined in
`wonky_sheets/lib/theme/sheets_tokens.dart`: `sheetBackground`, `referenceColors[10]`,
`protectedStripe`, `spillFrame`, `errorTriangle`, `noteTriangle`, `invalidTriangle`,
`skeleton`. Light/dark values are listed in [04 §14](04-screens-menus-toolbar.md#14-light-and-dark-grid-colors).
Cell colors set by users are **absolute** (a red fill is red in both modes); "Automatic" text
and fill follow the app theme.

### 2.10 Hit testing

`GridGeometry.hitTest(Offset) → GridHit` with variants: `CellHit(row, col, zone)` where zone ∈
{body, fillHandle, selectionBorder (4 px band on the active range edge), checkbox, dropdownArrow,
chip, link, noteTriangle, commentTriangle, errorTriangle, filterButton}, `ColumnHeaderHit(col,
zone: body|resizeEdge|hiddenIndicator|groupGutter)`, `RowHeaderHit(...)`, `CornerHit`,
`FreezeBarHit(dimension)`, `ObjectHit(objectId)` (objects are hit-tested first, by z-order).
The `GridPointerRouter` uses the hit to start one of: selection drag, fill drag, move drag,
resize drag, header-move drag, freeze drag, widget interaction. Cursor: cell body =
`SystemMouseCursors.cell`; fill handle = `precise` (crosshair); selection border =
`grab`/`grabbing`; resize edges = `resizeColumn`/`resizeRow`; links = `click` when Mod held.

### 2.11 Right-to-left sheets (P2)

`Sheet.rightToLeft` mirrors the horizontal axis in `GridGeometry` (column 0 at the right, row
headers on the right); text direction per cell still follows content. Keyboard arrows are
mirrored. Command `sheets.sheet.setRightToLeft {sheetId, rtl}` (1 step).

**Acceptance criteria (rendering)**
- AC-R1: 1M-cell sheet (100k × 10, mixed text/numbers/formats) scrolls at ≥ 58 fps median on
  the reference desktop (M1 MacBook Air, Chrome stable, `--wasm`) and ≥ 55 fps on a 2020
  Windows laptop; no frame > 50 ms during a 10 s fling.
- AC-R2: Text overflows into empty neighbours and is clipped at the first non-empty one; numbers
  wider than the column render `####`.
- AC-R3: Gridlines, fills and borders share pixel-exact edges at DPR 1, 1.5, 2 and zoom 50–200 %
  (golden tests).
- AC-R4: Frozen panes paint independently; merged cells crossing the freeze line render in both
  panes.
- AC-R5: Light/dark switch repaints chrome tokens without changing user-set cell colors.

---

## 3. Headers

| Aspect | Spec |
|--------|------|
| Column header | Height 24 px × zoom; label = column letters (`A`…`Z`, `AA`…`ZZZ`, `ColumnLetters.fromIndex`); font Geist 11 px × zoom, `gridHeaderFg` |
| Row header | Width = max(46, digits × 8 + 16) px × zoom; label = 1-based row number of the **current index** |
| Highlight | Headers of rows/cols intersecting the selection use `gridHeaderSelectedBg`; fully selected rows/cols use `selectionBorder` at 25 % alpha bg and bold label |
| Corner | Select-all on click (`sheets.select.all`); contains freeze bar handles at its bottom/right edges |
| Resize | Hover within ±4 px of a header boundary shows resize cursor; drag shows a guide line across the grid and a tooltip "Width: 120 px". If the dragged header belongs to a whole-row/col selection, all selected rows/cols get the new size. Command `sheets.cols.resize {colIds, width}` / `sheets.rows.resize {rowIds, height}` (1 step) |
| Auto-fit | Double-click a boundary → `sheets.cols.autoFit {colIds}` / `sheets.rows.autoFit {rowIds}` (fit to data, §13.6) for the column left of / row above the boundary, or for all selected if it is part of the selection |
| Hidden indicator | Where hidden rows/cols exist, two small arrow buttons (◂ ▸ / ▴ ▾) at the boundary; click → `sheets.cols.unhide {colIds}` for that hidden run (1 step) |
| Select | Click selects the whole column/row; Shift+click extends; Mod+click adds a range; drag across headers selects multiple |
| Move | Press on an already fully-selected header and drag → `HeaderMoveController` shows a translucent ghost of the header and a 3 px drop line between headers; drop → `sheets.cols.move {colIds, beforeColId}` / `sheets.rows.move {rowIds, beforeRowId}` (1 step, only `sortKey` changes, §13.4). Auto-scroll near edges. Disabled for frozen↔unfrozen crossing that would split a merge (toast) |
| Group gutter | When row/col groups exist, a gutter (16 px per depth) above column headers / left of row headers shows outline brackets and +/− buttons (07) |
| Context menu | Right-click: row header menu / column header menu ([04 §9](04-screens-menus-toolbar.md#9-context-menus)) |
| Filter buttons | When a basic filter covers the header row, filter icons are drawn in the **cells** of the filter's header row, not in grid headers (07) |

---

## 4. Frozen rows and columns

- Stored per sheet: `Sheet.frozenRows`, `Sheet.frozenColumns` (02 §3.1). Changing them is
  undoable (`sheets.view.freezeRows {count}`, `sheets.view.freezeColumns {count}`, 1 step each,
  synced to everyone — Google behavior).
- **Freeze bars**: a 4 px thick, `border`-colored bar at the bottom of the corner header (rows)
  and at its right (columns). Hover → grab cursor and bar darkens; drag → a translucent bar
  follows the pointer across the grid and snaps to the nearest row/column boundary; release
  commits the count. Dragging back to the top/left → 0.
- Menu: View › Freeze ▸ (No rows, 1 row, 2 rows, Up to row N (N = current active row), No
  columns, 1 column, 2 columns, Up to column X).
- Frozen rows count refers to the first N **visible-order** rows; hidden rows inside the frozen
  area count but are not shown.
- Invariant (02 §8): clamp when counts exceed available rows/cols.
- Scrolling with frozen panes: the main pane scrolls; keyboard navigation into frozen rows does
  not scroll vertically.

**AC**: dragging the freeze bar to below row 3 sets `frozenRows = 3` for all collaborators, and
Undo restores the previous count.

---

## 5. Scrolling

| Input | Behavior |
|-------|----------|
| Mouse wheel | Vertical: 3 × default row height × zoom per notch (platform delta respected); Shift+wheel: horizontal |
| Trackpad | Pixel-precise 2D scrolling with platform momentum (`diagonalDragBehavior.free`) |
| Touch | `GridTouchTracker` (`grid/grid_touch.dart`): a tap selects like a click (double-tap edits); one finger past the touch slop scrolls, with a `ClampingScrollSimulation` fling on release; a long press (500 ms) then drag runs the grid's pointer drag (range selection, fill handle, drag-move, header resize/move, freeze bars) instead of scrolling; two fingers pinch-zoom about their midpoint (50–200 %, 5 % steps) and pan. Mouse, pen and trackpad input are unchanged. In the read-only mobile layout (suite 02 §6.1, T-1) there is no cell selection: every pointer (a mouse in a narrow window too) pans like one finger, with the fling, taps and long presses do nothing, and the selection isn't painted (`SheetEditorController.readOnlyView`) |
| Mod+wheel / pinch (`PointerScaleEvent`, trackpad pinch on web) | Zoom about pointer (§2.3) |
| Pointer cancel | A `PointerCancelEvent` (the OS or browser took the pointer, a second finger during a long-press drag) aborts the drag in progress: no fill, move, resize, freeze or paint format is committed |
| Scrollbars | Thin auto-hide (`WonkyScrollArea` style); dragging the vertical thumb shows a tooltip "Row 12,345" |
| Keyboard | Arrow navigation scrolls minimally to keep the active cell fully visible (with 1-cell margin); PageUp/PageDown scroll by one viewport height and move the active cell by the same number of visible rows; Alt+PageUp/PageDown scroll one viewport width left/right and move the active cell |
| Mod+Backspace | `sheets.nav.scrollToActive` — scroll the active cell into view (center if far) |
| Name box / Go to | `GridScrollController.scrollToCell(cell, align: center if offscreen)` with a 200 ms animation (disabled with Reduce motion) |
| Auto-scroll | During selection/fill/move/resize drags, `AutoScroller` scrolls when the pointer is within 24 px of the pane edge (speed ∝ distance beyond the edge, max 40 rows/s) |
| Follow mode | When following a collaborator, scroll tracks their active cell (suite 07 §1.2) until the user scrolls/clicks |

- **"Add more rows" footer**: after the last row, a 48 px footer row shows
  `Add [1000] more rows at bottom` (`WonkyNumberStepper`-style input + *Add* button) →
  `sheets.rows.addMore {count}` (1 step; counts against the cell limit).
- Scroll position is pixel-based (no row snapping) and saved per sheet in `LocalViewState`
  (as the top-left row/col **ids** + pixel offsets, so remote inserts don't jump the view).
- **Anchor stability**: when rows above the viewport change size or are inserted/deleted
  remotely, the scroll offset is adjusted to keep the top visible row's id at the same screen
  position.

**AC**: a remote insertion of 100 rows above the viewport doesn't move what the user sees.

---

## 6. Selection model

### 6.1 Data structures

```dart
/// Id-based so that remote structure edits never corrupt it.
class CellRef { final String rowId; final String colId; }

enum SelectionKind { cells, rows, columns, all }

class SelectionRange {
  final SelectionKind kind;
  final String? r1, r2;   // row ids (null for columns/all)
  final String? c1, c2;   // col ids (null for rows/all)
}

class GridSelection {
  final String sheetId;
  final List<SelectionRange> ranges;   // ≥ 1, order of creation
  final int activeRangeIndex;          // range containing the active cell
  final CellRef activeCell;            // typing target; always inside ranges[activeRangeIndex]
  final CellRef anchor;                // fixed corner of the active range for Shift-extend
  GridRange toGridRange(int i);        // 02 GridRange JSON
}
```

`ResolvedSelection` caches index rectangles; it is recomputed when `AxisIndex.epoch` changes. If
a range bound id disappears (remote delete), the range is shrunk to surviving ids; if the active
cell disappears, it moves to the nearest surviving cell (same index clamped).

### 6.2 Pointer selection

| Gesture | Result |
|---------|--------|
| Click cell | Single range of that cell (merges expand to the whole merge); active = clicked |
| Drag | Range from anchor to pointer, expanded to fully include intersecting merges |
| Shift+click | Replace active range with anchor→clicked |
| Mod+click / Mod+drag | Add a new range; it becomes the active range |
| Click row/col header | `rows`/`columns` range; active cell = first visible cell of that row/col in the viewport's first visible column/row |
| Click corner | `all` |
| Double-click cell | Enter edit mode (§8) |
| Right-click | If outside selection, select the cell first; open context menu |

### 6.3 Keyboard extension and data edges

- `Shift+Arrow` moves the **focus corner** (opposite the anchor) by one visible cell, skipping
  hidden rows/cols, expanding over merges.
- `Mod+Arrow` / `Mod+Shift+Arrow` use `DataEdgeFinder.next(from, direction)`:
  1. Let `c` = current cell, `n` = next visible cell in direction.
  2. If `c` non-empty and `n` non-empty → move to the last non-empty cell before the first empty
     one.
  3. Else → move to the first non-empty cell in direction; if none, to the sheet edge.
  "Non-empty" = has content or an overlay value (spill/pivot). Uses per-row/per-column sorted
  occupancy lists in `CellStore` (binary search, O(log n)).
- `Mod+A` (`sheets.select.all`): if the active cell is inside a **data region** (8-connected
  block of non-empty cells, computed by `DataEdgeFinder.region`, capped at 1M cells) and the
  selection is not already exactly that region → select it; otherwise select all.
- `Mod+Space` (mac: `⌃Space`, since ⌘Space is Spotlight) selects the active range's columns;
  `Shift+Space` selects its rows; pressing both selects all.

### 6.4 Selection-related behaviors

- Selection is **view state**: not undoable; undo restores `selectionBefore` (suite 08 §3.1).
- Selection changes are published to presence (throttled 10/s) as `PresenceCursor {sheetId,
  activeCell, ranges, editing}` (suite 07 §1.1).
- Switching sheets saves/restores the selection per sheet (`SheetViewState`).
- Selection statistics (sum/avg/…) recompute from the selection, debounced 100 ms, capped at
  5M cells with background chunking ([04 §7](04-screens-menus-toolbar.md#7-selection-statistics-and-explore)).
- Commands: `sheets.select.range {a1}` (also used by MCP `ui.sheets.select_range`),
  `sheets.select.all`, `sheets.select.rows`, `sheets.select.columns`,
  `sheets.select.dataRegion`.

**AC**: Mod+click three disjoint ranges, then Mod+B bolds all three in one undo step; Mod+↓ on
`A1` with data in `A1:A10` and `A15:A20` lands on `A10`, then `A15`, then `A20`, then the last
row.

---

## 7. Keyboard map (grid scope unless noted)

All bindings are `KeyBinding`s on commands and user-overridable (suite 08 §1.2). Table lists
Win/Linux; macOS uses ⌘ for Mod and ⌥ for Alt unless a `mac:` override is given.

### 7.1 Navigation and selection

| Keys | Command | Behavior |
|------|---------|----------|
| ←↑→↓ | `sheets.nav.move {dir}` | Move active cell one visible cell; collapses selection; merges are stepped over as one cell |
| Shift+Arrow | `sheets.nav.move {dir, extend:true}` | Extend focus corner |
| Mod+Arrow | `sheets.nav.move {dir, toEdge:true}` | Data edge (§6.3) |
| Mod+Shift+Arrow | `sheets.nav.move {dir, toEdge:true, extend:true}` | Extend to data edge |
| Tab / Shift+Tab | `sheets.nav.tab {reverse}` | Right/left; inside a multi-cell selection cycles within it (wrap to next row) |
| Enter / Shift+Enter | `sheets.nav.enter {reverse}` | Down/up; inside a multi-cell selection cycles within it (wrap to next column); after a sequence of Tabs, Enter returns to the column where the Tab sequence started, one row down |
| Home / End | `sheets.nav.rowStart` / `sheets.nav.rowEnd` | First column / last non-empty column of the row |
| Mod+Home / Mod+End | `sheets.nav.sheetStart` / `sheets.nav.sheetEnd` | A1 / last used cell (max used row × max used col) |
| Shift+Home/End, Mod+Shift+Home/End | same with `extend` | |
| PageUp / PageDown | `sheets.nav.page {dir}` | §5 |
| Alt+PageUp / Alt+PageDown (mac: ⌥Fn↑/↓) | `sheets.nav.pageHorizontal {dir}` | One screen left/right |
| Mod+Shift+PageUp / PageDown (mac: ⌥⌘↑ / ⌥⌘↓; ⌥↓ is reserved for dropdowns) | `sheets.sheet.activatePrevious` / `…Next` | Previous/next visible sheet |
| Mod+Backspace | `sheets.nav.scrollToActive` | |
| Mod+A | `sheets.select.all` | Region, then all (§6.3) |
| Mod+Space (mac ⌃Space) / Shift+Space | `sheets.select.columns` / `sheets.select.rows` | |
| Mod+Alt+G (desktop also F5) | `sheets.nav.goTo` | Opens Go to range dialog / focuses name box |
| Mod+F | `sheets.find.open` | Find bar (07) |
| Mod+H (mac web Mod+Shift+H) | `sheets.find.openReplace` | Find & replace dialog (07) |
| Mod+J | `shell.ai.togglePanel` | Assistant |
| Alt+Shift+X | `sheets.explore.toggle` | Explore panel |
| Mod+/ | `shell.help.shortcuts` | Keyboard shortcuts dialog |

### 7.2 Editing

| Keys | Scope | Command | Behavior |
|------|-------|---------|----------|
| Any printable char | grid | (starts session) | Enter mode with the char as the new content (replaces) |
| `=` / `+` / `-` | grid | (starts session) | Enter mode; formula editing if `=` |
| F2 | grid | `sheets.cell.edit` | Edit mode, caret at end |
| F2 | cellEditor | (mode toggle) | Toggle enter ⇄ edit |
| Enter | grid | `sheets.cell.edit` when `UserPreferences.sheetsDefaults.enterStartsEditing` (default **off**, Google moves down) and one cell is selected (`sheets.nav.enter`) | |
| Double-click | grid | `sheets.cell.edit {caretAtPointer}` | |
| Enter / Shift+Enter | cellEditor | commit, move down/up | |
| Tab / Shift+Tab | cellEditor | commit, move right/left (or accept autocomplete) | |
| Arrow keys | cellEditor (enter mode) | commit and move; in point mode insert/move reference | |
| Esc | cellEditor | cancel; restore original | |
| Alt+Enter (mac ⌥Enter, also ⌃Enter) | cellEditor | insert newline in cell | |
| Mod+Enter | cellEditor | multi-cell selection: commit the input to **every** cell of the selection (`sheets.cell.setInputForSelection`), formulas translated relatively; single cell (mac): newline | |
| Mod+Shift+Enter | cellEditor | `sheets.formula.toggleArrayFormula` | Wrap/unwrap the formula in `ARRAYFORMULA(…)` (05) |
| F4 | cellEditor | `sheets.formula.cycleReferenceType` | Cycle `$` on the reference at the caret (§8.7) |
| Shift+F1 / F1 | cellEditor | `sheets.formula.toggleHelpCardVisible` / `sheets.formula.toggleHelpCard` | Show/hide the formula help card / expand ↔ compact |
| Delete / Backspace | grid | `sheets.edit.clearValues` | Clear content of selection (formats kept; notes kept; checkbox cells set to unchecked—Google behavior: Delete on checkbox resets to FALSE) |
| Mod+D | grid | `sheets.fill.down` | Copy top row of each range down (formulas translated) |
| Mod+R | grid | `sheets.fill.right` | Copy left column right |
| Mod+Enter | grid | `sheets.fill.selection` | Fill the whole selection with the active cell's content (translated) |
| Mod+; | grid/cellEditor | `sheets.cell.insertDate` | Today's date (spreadsheet time zone), date format |
| Mod+Shift+; | grid/cellEditor | `sheets.cell.insertTime` | Current time |
| Mod+Alt+Shift+; | grid/cellEditor | `sheets.cell.insertDateTime` | |
| Mod+Z / Mod+Shift+Z, Mod+Y (Win/Linux) | global | `sheets.edit.undo` / `sheets.edit.redo` | In cellEditor scope, they act on editor text first (local text undo), then fall through to the grid stack when the session is unchanged |
| F4 / Mod+Y (when nothing to redo) | grid | `sheets.edit.repeatLast` | Repeat last formatting/structure command on the current selection |
| Mod+X / C / V | grid | `sheets.edit.cut` / `copy` / `paste` | §12 |
| Mod+Shift+V | grid | `sheets.edit.pasteSpecial {mode: values}` | |
| Mod+Alt+V | grid | `sheets.edit.pasteSpecial {mode: format}` | |
| Mod+K | grid/cellEditor | `sheets.insert.link` | Link editor popover (§14.4) |
| Mod+Alt+M | grid | `shell.comments.create` | Comment composer anchored to active cell |
| Shift+F2 | grid | `sheets.notes.insert` | Note popover |
| Alt+↓ | grid | `sheets.dv.openDropdown` | Open dropdown picker on a DV list cell |
| Space | grid | `sheets.dv.toggleCheckbox` | Toggle checkboxes in selection (only when the active cell is a checkbox cell; otherwise starts editing with a space) |
| Mod+\` (mac ⌃\`) | grid | `sheets.view.toggleFormulas` | Show formulas |
| Mod+Alt+= / Mod+Alt+- | grid | `sheets.structure.insertBySelection` / `sheets.structure.deleteBySelection` | Rows if whole rows selected, columns if whole cols, else Insert/Delete cells dialog |
| Mod+Alt+9 / Mod+Shift+9 | grid | `sheets.rows.hide` / `sheets.rows.unhide` | |
| Mod+Alt+0 / Mod+Shift+0 | grid | `sheets.cols.hide` / `sheets.cols.unhide` | |
| Alt+Shift+→ / ← | grid | `sheets.group.groupSelection` / `sheets.group.ungroupSelection` | (07) |
| Alt+Shift+↓ / ↑ | grid | `sheets.group.expand` / `sheets.group.collapse` | (07) |
| Shift+F11 | grid | `sheets.sheet.add` | |
| Mod+P | global | `sheets.print.open` | |
| Mod+S | global | `sheets.file.saveNoop` | Shows toast "Wonky Sheets saves automatically" (prevents browser save dialog) |

Formatting shortcuts (Mod+B/I/U, Alt+Shift+5, Mod+Shift+E/L/R, Mod+Shift+1…6, Mod+\, Alt+Shift+1…7,
Mod+Shift+. / ,) are listed in [06 §16](06-formatting.md#16-command-catalogue).

**AC**: every binding above is covered by a widget test that sends the key and asserts the
command id dispatched (via a recording `CommandDispatcher`).

---

## 8. Cell editing

### 8.1 Modes (state machine)

```
            type char / = / + / -                 F2, dbl-click, click formula bar
  READY ─────────────────────────────► ENTER ◄──────────F2──────────► EDIT
    ▲                                    │  ▲ caret at insertion point     │
    │ commit/cancel                      │  │ in formula → POINT (sub-mode) │
    └────────────────────────────────────┴──┴───────────────────────────────┘
```

| Mode | Arrow keys | Home/End | Click on grid |
|------|-----------|----------|----------------|
| READY | Navigate grid | Grid | Select |
| ENTER | Commit + move (unless POINT) | Commit + move | Commit + select (unless POINT) |
| EDIT | Move caret | Caret line start/end | Formula: insert reference when POINT-eligible; else commit + select |
| POINT (formula, caret after `=`, `(`, operator, argument separator or `:`) | Move/extend the inserted reference (Shift = extend, Mod = to edge) | — | Insert/replace reference; drag = range; Mod+click = add another reference with separator |

Any non-navigation key in POINT ends POINT (the reference is final). The status of the mode is
shown at the left of the status bar ("Enter" / "Edit" / "Point") for power users (Excel parity,
toggleable in Settings › Sheets).

### 8.2 `CellEditorController` API

```dart
class CellEditorController extends ChangeNotifier {
  CellEditSession? get session;            // null when READY
  EditorMode get mode;                     // ready, enter, edit (point is a flag)
  bool get isPointMode;
  /// Starts editing the active cell. [initialText] replaces content (typing) or null to load
  /// the existing input (A1 formula text, or the formatted-for-editing value).
  void begin({String? initialText, required EditorMode mode, EditSurface surface = EditSurface.cell,
              int? caretOffset});
  Future<CommitResult> commit({CommitMove move = CommitMove.down, bool toSelection = false,
                               bool asArrayFormula = false});
  void cancel();
  void toggleEnterEdit();                  // F2
  void insertReference(GridRange range);   // POINT / ref-box drag
  void cycleAbsolute();                    // F4
}
```

**Editable text of an existing cell** (what the editor shows on F2):
- Formula → A1 text via `FormulaCodec.toA1` (in the spreadsheet locale's argument separator).
- Number with date/time format → locale short date/time edit form (`2026-10-12` for ISO
  locales, `10/12/2026` en_US, `12.10.2026` de_DE; time `14:30:00`).
- Percent format → `12.5%`; currency → the plain number (`1234.5`) (Google shows the raw
  number for currency).
- Text that would parse as a number/date/bool → prefixed with `'` (so re-commit keeps text).
- Rich text → plain text with runs preserved in `RichTextEditingController` (P1).

### 8.3 Editor overlay

> **As built — "ready" state.** While the grid has focus and the user can edit, the
> invisible cell editor `EditableText` holds the primary focus (the grid's focus node
> redirects to it). Typed text — keyboard, IME composition, dictation — arrives through the
> platform text input and starts the session with that text, so no keystroke is lost and
> IME works from the first character. Grid shortcuts are handled by a key handler above it
> that is inactive while a session is open; undo/redo/cut/copy/paste are therefore also bound
> in the `grid` scope (the shell's global bindings don't apply inside text fields).

- Positioned exactly over the active cell (or merged rect), above all panes; if the cell is in a
  frozen pane, the overlay is clipped/positioned in that pane's coordinates.
- Font, size × zoom, color, fill and horizontal alignment match the cell; padding matches the
  painter so text doesn't jump when editing starts.
- **Auto-size**: width grows to fit the text (to the right for left-aligned, both ways for
  centered) up to the viewport's right edge; then wraps and grows downward up to 50 % of the
  viewport height, then scrolls internally. For `wrap` cells the width stays the cell width and
  height grows.
- 2 px `selectionBorder` frame + soft shadow; the grid cells underneath remain painted.
- While editing, the grid shows the **formula bar** in sync (shared controller, §9).
- A small **cell reference badge** (e.g. `B4`) appears above-left of the editor when the cell's
  row/column header is scrolled out of view.
- Typing into a cell **replaces** its content (READY → ENTER); IME composition is supported
  (the overlay `EditableText` is created hidden on focus so the first keystroke goes to it — no
  lost characters for fast typists or IME).

### 8.4 Commit pipeline (`InputCommitService`)

1. **Length checks** (≤ 50,000 chars; formula ≤ 32,768).
2. **Classify** (`InputParser.classify(input, locale)` in core):
   - Leading `'` → text without the apostrophe (`s:`).
   - Leading `=` → formula. Missing closing parentheses are auto-appended (Google behavior). A
     formula that fails to parse is still committed (stored verbatim; evaluates `#ERROR!` with
     the parse message) — see 05.
   - Leading `+` or `-` that is not a valid number/date and parses as a formula → `=` + input.
   - Otherwise `InputParser.parseValue` (§8.6).
3. **Data validation** (07): strict rule failing → reject: dialog "Invalid entry — The data you
   entered in cell B4 violates the data validation rules set on this cell. ‹help text›" [OK]
   and the editor stays open with text selected; warning rule → commit and mark invalid.
4. **Protection** (§16): blocked → dialog; warning → confirm dialog.
5. **Pivot/spill guard**: editing a pivot output cell → toast "You can't edit a pivot table's
   output…"; typing into a cell covered by another formula's spill commits and the anchor
   becomes `#SPILL!` (Google behavior).
6. **Write** the `SetCellInputs` operation through the session; its changes name only `content`
   (+ `numberFormat` when auto-detected and the cell's effective format is
   Automatic, 06 §5.9). One undo step labeled "Typing" (suite 08 coalescing does not apply
   across cells; each commit = 1 step).
7. **Commit hint**: stop the `typing` hint ([10 §2](10-collaboration-history.md)).
8. **Move** the active cell per `CommitMove` (Enter/Tab rules §7.1).

Commit target "toSelection" (Mod+Enter) writes translated content to every cell of every range
(1 step). Committing to a cell in a hidden row is allowed.

### 8.5 Column autocomplete (P1)

While typing text (not formula, not number) in ENTER mode, `ColumnAutocomplete` looks at the
contiguous non-empty block above and below in the same column (max 1,000 cells), finds unique
values with the typed prefix (case-insensitive), and shows the completion as **inline ghost text**
(selected suffix). Tab/Enter accepts; continuing to type refines; Backspace removes the
suggestion. Disabled by Tools › Autocomplete toggle (`sheets.tools.toggleAutocomplete`, per
user).

> **As built.** `ColumnAutocomplete` (`cell_editor/column_autocomplete.dart`) completes only
> when exactly one distinct value of the block matches; the completion is inserted selected
> (typing replaces it, Backspace drops it, Tab/Enter commit it). The preference is
> `sheetsDefaults.autocomplete` (Settings › Sheets and the Tools toggle).

### 8.6 Input parsing per locale (`InputParser`)

Locale data comes from `intl` (`NumberSymbols`, `DateSymbols`) for `Spreadsheet.locale`.
Recognized inputs (en_US / de_DE examples) and the auto-detected format (06 §5.9):

| Input (en_US) | Input (de_DE) | Value | Auto format |
|---------------|---------------|-------|-------------|
| `1234` / `-12.5` / `1,234.5` | `1234` / `-12,5` / `1.234,5` | number | Automatic (`1,234.5` gets `#,##0.0`) |
| `1.5E3` | `1,5E3` | 1500 | Scientific `0.00E+00` |
| `12%` / `12.5 %` | `12 %` | 0.12 | `0%` / `0.0%` |
| `$12` / `-$1,200.50` / `($5)` | `12 €` / `-1.200,50 €` | number | Currency for the typed symbol (06 §5.9): `$` → `"$"#,##0` in every locale; other symbols → `[$€]` without LCID, placed where typed (`€12` → `[$€]#,##0`, `12 €` → `#,##0 [$€]`, `12€` → `#,##0[$€]`); decimals as typed (0, else at least 2: `-$1,200.50` → `"$"#,##0.00`). The Format › Number currency presets use `[$sym-LCID]` instead (06 §5.1) |
| `(123)` | `(123)` | -123 | Automatic |
| `10/12/2026`, `Oct 12 2026`, `12-Oct-2026`, `2026-10-12` | `12.10.2026`, `12. Okt. 2026`, `2026-10-12` | serial date | Date `preset:date` (locale short date, en_US `M/d/yyyy`); ISO input keeps its shape `yyyy-mm-dd` |
| `14:30`, `2:30 PM`, `14:30:15`, `14:30:15.5` | `14:30` | fraction | Time `h:mm` / `h:mm AM/PM` / `h:mm:ss` / `h:mm:ss.000` (` AM/PM` appended when typed with AM/PM) |
| `10/12/2026 14:30` | `12.10.2026 14:30` | serial | Date time `preset:dateTime` (ISO input: `yyyy-mm-dd hh:mm[:ss]`) |
| `36:15:00` / `36:15` | `36:15:00` | 1.51 | Duration `[h]:mm:ss` / `[h]:mm` |
| `TRUE` / `false` | `WAHR` / `FALSCH` (when function display language is de, P2; English always accepted) | boolean | — |
| `#N/A`, `#DIV/0!` … | same | error | — |
| `1/2` | `1/2` | **date** (Jan 2 current year, Google behavior) | Date; type `0 1/2` for the fraction 0.5 (format `# ?/?`; `1 3/16` → `# ??/??`) |
| ` 42 ` | ` 42 ` | 42 (trimmed) | — |
| `00123` | `00123` | **123** (number; Google drops leading zeros) | — |
| anything else | | text | — |

- Ambiguous dates follow the locale's day/month order; 2-digit years: 00–29 → 2000–2029,
  30–99 → 1930–1999.
- Plain-text number format (`@`) on the target cell: everything is stored as text.
- Input is never altered beyond trimming of leading/trailing ASCII spaces for non-text values.

### 8.7 Formula editing

**Syntax highlighting** (`FormulaTextEditingController.buildTextSpan`) uses `FormulaLexer`
tokens: functions `foreground` medium weight; references/ranges in their assigned
**reference color**; numbers `chart2`-ish blue token `formulaNumber`; strings `formulaString`
(green); operators/punctuation `mutedForeground`; errors and unmatched parens `destructive`;
named ranges italic in a reference color. Formula bar uses GeistMono when content is a formula
(Geist otherwise); the in-cell editor uses the cell font.

**Reference colors**: `ReferenceColorizer` assigns colors from `referenceColors[0..9]` in order
of first appearance; identical references reuse the color; cycles after 10.

**Reference boxes on the grid** (`ReferenceBoxController`): each reference in the edited formula
on the visible sheet gets a 2 px box in its color with 10 % fill; ranges have 4 corner handles.
- Drag the box border → moves the reference (keeps size); drag a corner → resizes; the formula
  text updates live; Esc reverts the whole edit.
- References to other sheets show boxes only when that sheet is active.

**Point mode**: eligible when the caret follows `=`, `(`, `,`/`;` (locale separator), an operator
(`+ - * / ^ & = < > <= >= <>`), `:` or `!`. Then:
- Click a cell → inserts `B4`; drag → `B4:D9`; Shift+click → extends the just-inserted ref;
  Mod+click → inserts separator + new ref; clicking a column/row header inserts `B:B` / `4:4`.
- Arrow keys move the inserted reference (cell cursor drawn as a dashed box), Shift+arrows
  extend, Mod+arrows jump to data edges.
- Clicking another **sheet tab** while editing keeps the session open on the original cell (the
  formula bar becomes the editing surface) and inserted refs are `'Sheet 2'!A1`; committing
  returns to the original sheet.

**F4** (`cycleAbsolute`): for the reference token at/before the caret (or all refs in the text
selection): `A1 → $A$1 → A$1 → $A1 → A1`; ranges apply the same state to both ends; whole
column/row refs cycle `B:B → $B:$B`.

**Function autocomplete** (`FunctionAutocompleteController`): after typing ≥ 1 letter of an
identifier in an expression position, a popup (`ShadPopover`, max 8 rows, 320 px wide) lists
matches from: built-in functions (05 registry, with category and one-line description), named
functions, script custom functions (09), named ranges (different icon, inserted without `(`).
Ranking: prefix match on name, then usage frequency (per user, local). Keys: ↑/↓ select,
Tab/Enter insert `NAME(`, Esc dismiss, continuing to type filters. Disabled by the user
preference *Formula autocomplete* (Settings › Sheets).

**Signature help** (`SignatureHelpController`): when the caret is inside a function call's
parentheses, a card below the editor shows `VLOOKUP(search_key, range, index, [is_sorted])` with
the current argument (by counting top-level separators) in bold, plus — expanded (F1 toggles) —
summary, per-argument description, an example, and *Learn more* (opens the in-app Function
help dialog, [04 §11.20](04-screens-menus-toolbar.md#11-dialogs)). `Shift+F1` hides/shows the
card (remembered per user).

**Parenthesis matching**: when the caret is next to a paren, the pair is drawn with `accent`
background; an unmatched paren is `destructive`.

**Live preview** (`FormulaPreviewController`): 150 ms after the last keystroke the formula is
evaluated detached (`FormulaEngine.evaluateDetached(a1Text, at: cell)`, ≤ 50 ms budget; skipped
if exceeded or if the formula references > 1M cells) and a chip above the editor shows the
formatted result (`= 1,234.50`) or the error with its message (`#REF! — Reference does not
exist`). Array results show the top-left value + "(3×4 array)". **As built:** `cell_editor/formula_preview.dart`;
the chip sits above the in-cell editor (next to the address badge), formatted with the cell's
explicit number format or the result's hint. Formula autocomplete and signature help follow
Settings › Sheets (`formulaAutocomplete`, `formulaHelp`).

**Parse errors on commit** are not blocking (§8.4); the cell shows `#ERROR!` and the error
tooltip shows the parser message ("Formula parse error at position 12").

### 8.8 Rich text editing (P1)

When editing a text cell, selecting part of the text and pressing Mod+B/I/U, Alt+Shift+5 or
picking a text color/link from the toolbar applies the attribute to the selected **run** only
(`RichTextEditingController` keeps runs). On commit, content is stored as `r:` JSON (02 §2) if
any run differs from the cell format, else as plain `s:`. Formulas and numbers cannot have runs.
Details in [06 §11](06-formatting.md#11-rich-text-runs).

### 8.9 Undo inside the editor

Text-level undo (Mod+Z inside the editor) uses `EditableText`'s undo history. After commit, the
whole commit is one grid undo step ("Undo Typing in B4"); undo restores the previous content
and format attributes written by the commit, and selects the cell.

**Acceptance criteria (editing)**
- AC-E1: Typing `=su` shows SUM first in autocomplete; Tab inserts `=SUM(`; clicking A1 and
  Shift+clicking A5 yields `=SUM(A1:A5` with A1:A5 boxed in color 1; Enter commits `=SUM(A1:A5)`.
- AC-E2: F4 on `A1` in `=A1*2` cycles through the four states.
- AC-E3: In de_DE, typing `1.234,5` stores `n:1234.5`; typing `12.10.2026` stores the serial for
  2026-10-12 with a date format.
- AC-E4: `'0012` stores `s:0012` and shows `0012` left aligned.
- AC-E5: With A1:B3 selected, typing `x` then Mod+Enter writes `x` into all six cells in one undo
  step.
- AC-E6: Enter inside a 3×2 selection cycles the active cell through all six cells without
  changing the selection.

---

## 9. Formula bar

```
┌────────────┬────┬───────────────────────────────────────────────────────────┬────┬───┐
│ B4       ▾ │ fx │ =VLOOKUP(A4, Prices!A:C, 3, FALSE)                         │ ✨ │ ⌄ │
└────────────┴────┴───────────────────────────────────────────────────────────┴────┴───┘
```

| Element | Spec |
|---------|------|
| **Name box** (`NameBox`, 120 px, `ShadInput` + dropdown chevron) | Shows the active cell (`B4`), the selection size while dragging (`3R × 2C`), or a named range name when the selection equals one. Typing `D10`, `A1:C20`, `Sheet2!B5`, `B:B`, `3:3` or a named range name + Enter → `sheets.nav.goTo {target}` (selects and scrolls; switches sheet). Typing a **new valid name** with a range selected + Enter → `sheets.namedRanges.createFromSelection {name}` (1 step) with a toast "Named range 'Sales' created — Manage". Chevron opens a dropdown of named ranges (search + "Manage named ranges" → panel, 07). Invalid input → shake + inline error tooltip. |
| **fx** | Icon; click opens Function help dialog for the function at the caret (or the function list). |
| **Editor area** | Shares the `FormulaTextEditingController` of the current `CellEditSession`; when not editing, shows the active cell's editable text (read-only render, click → EDIT mode with the caret at the click position). Multi-line content: single line + "…" when collapsed. For spilled cells, shows the anchor's formula greyed. For pivot output, shows the value greyed. In view mode (viewers) it is read-only and selectable. |
| **Expand** (⌄) | Toggles expanded height (`FormulaBarController.expanded`, 1 line ↔ up to 8 lines, resizable by dragging the bottom edge); remembered per user. |
| **✨** | `sheets.ai.suggestFormula` (suite 10): popover "Describe the formula you need" → suggestion + explanation → *Insert* (puts it into the editor, not committed). |

Commands: `sheets.view.toggleFormulaBar` (View › Show › Formula bar, per user, —),
`sheets.formulaBar.toggleExpanded` (—), `sheets.nav.goTo`.

**AC**: typing `Sales` into the name box with `B2:B20` selected creates a named range; typing
`Sales` again later selects `B2:B20`.

---

## 10. Fill handle

### 10.1 Interaction (`FillHandleController`)

- A 6 × 6 px `fillHandle`-colored square with 1 px `background` outline at the bottom-right corner
  of the active range (only when the selection is a single range and the user can edit).
- **Drag**: direction = axis of the larger pointer delta beyond the range; the preview shows a
  dashed outline over the target and a tooltip with the value that will be written into the
  last target cell. Auto-scroll applies.
- **Release** → `sheets.fill.series {source: GridRange, target: GridRange, mode: auto|copy}` (1
  step). Holding **Alt (⌥)** during release toggles auto ↔ copy (Google behavior: series vs
  copy for numbers/dates).
- **Double-click** the handle → `sheets.fill.autoFillDown`: fills down to the last row of the
  contiguous data in the adjacent column (left, else right), stopping at the first empty cell
  of that column; no-op if nothing adjacent.
- Dragging the handle back inside the selection does nothing (Google parity).
- Filling over cells with content overwrites them; filling into protected ranges is checked
  first (§16).

### 10.2 Series detection (`SeriesDetector`, core)

Per row (horizontal fill) or per column (vertical fill) of the source, independently:

| Source pattern | Auto result | Copy (Alt) |
|----------------|-------------|------------|
| Single number | **copy** (`5,5,5`) | series +1 |
| ≥ 2 numbers | Linear trend: if arithmetic progression, continue the step; else least-squares linear fit (`1,2,4 → 5.33, 6.83…`) | copy cyclically |
| Single date / datetime | +1 day | copy |
| ≥ 2 dates | If all same day-of-month and month deltas equal → step months (end-of-month clamped); same for years; else day step | copy |
| Times | step from first two, else +1 hour | copy |
| Text with trailing/leading integer (`Item 1`, `Q1-2026`→ number nearest the end) | increment the number, preserving zero-padding (`A009 → A010`) | copy |
| Known list item (weekday/month short/long, quarter `Q1`, locale names; case preserved) | continue the list cyclically; step from two samples | copy |
| User custom lists (`UserPreferences.sheetsDefaults.customLists`, Settings › Sheets) | continue | copy |
| Plain text / boolean / error | copy cyclically | copy |
| Formula | copy, **relative references translated** (`FormulaCodec.translate(stored, from, to)` resolves relative tokens by index offset and maps back to ids; out-of-grid → `#REF!`) | same |

Mixed sources (e.g. `1, a, 3`) are split into runs of compatible cells and each run is extended
cyclically (Excel/Google behavior). Formats are copied cyclically from the source cells along
with content (all attributes, DV and notes are **not** copied; CF ranges are not changed).
Reverse fill (drag up/left) extends series backwards.

**AC**: filling `Mon` down 8 cells yields `Tue … Mon Tue`; filling `1,3` yields `5,7,9`;
filling `=A1*2` from B1 to B2:B4 yields `=A2*2 … =A4*2`.

---

## 11. Drag-move and drag-copy

- Hovering the 4 px border band of the active range shows a grab cursor (`RangeDragController`).
- Drag shows a thick outline at the drop position (snapped to cells) and the target address
  tooltip. Holding **Mod** (Alt on macOS, like Finder copy) at drop copies instead of moving
  (cursor shows `+`).
- Drop on non-empty cells → `ShadDialog.alert` "There's already data here. Do you want to replace
  it?" [Cancel] [OK].
- Move = `sheets.cells.moveRange {source, destTopLeft}`; copy = `sheets.cells.copyRange {…}`
  (1 step each).
- **Move semantics** (same as cut-paste, §12.6): contents, formats, notes, DV and merges move;
  formulas *inside* the moved range keep pointing at the same data (absolute and relative
  alike, Google behavior); formulas *elsewhere* (and CF/DV/named ranges/chart ranges) whose
  single-cell references or ranges lie **fully inside** the moved block are retargeted to the new
  location by `ReferenceRewriter.remap` using the engine's dependents index, in the same
  transaction; partially overlapping ranges are unchanged ([05 §5.5](05-formula-engine.md)).
- Drag across sheets is not supported (use cut/paste).
- **As built:** the cursor is `grabbing` while moving and `copy` while the modifier is held;
  pressing or releasing it mid-drag switches without moving the pointer.

---

## 12. Clipboard

### 12.1 Platform integration

> **As built.** `ClipboardService` uses the same approach as Wonky Write instead of
> `super_clipboard`: the async Clipboard API on web (`text/html` + `text/plain`) and
> Flutter's plain-text `Clipboard` elsewhere (the HTML of the last copy is kept in memory).
> Encoding/decoding is the core `ClipboardEncoder` / `ClipboardDecoder`.

`ClipboardService` uses **`super_clipboard`** (add to `wonky_sheets` dependencies; it
supports multiple formats — `text/plain`, `text/html`, images — on web, macOS, Windows, Linux).
On web, paste is driven by the browser `paste` event (`ClipboardEvents.instance` from
`super_clipboard`) so no permission prompt appears; copy/cut use the `copy`/`cut` events when
triggered by keyboard and `navigator.clipboard.write` when triggered from menus (menu paste on
web shows the hint "Use Mod+V to paste — your browser blocks menu paste", as Google does,
unless clipboard read permission was granted).

### 12.2 Copy (`sheets.edit.copy`, —)

- Only a single rectangular range can be copied (multi-range selection → toast "This action
  won't work on multiple selections").
- In a filtered/hidden-row range only **visible** rows/cols are copied.
- Writes three representations:
  1. `text/plain`: TSV of **displayed** values (formatted text; formulas' values); cells with tabs
     or newlines are quoted per RFC 4180-style TSV.
  2. `text/html`: a `<table>` with inline CSS per cell (font family/size/weight/style,
     decoration, color, background, text-align, vertical-align, white-space, borders), `colspan`/
     `rowspan` for merges, `<col width>`, plus `data-sheets-value` (JSON typed value),
     `data-sheets-formula` (R1C1-relative A1 formula, Google-compatible), and
     `data-sheets-numberformat` attributes; the `<table>` carries
     `data-wonky-clip="<clipId>"` and an HTML comment `<!--wonky:<base64 json>-->` with the full
     `SheetsClipboardPayload` when ≤ 5 MB.
  3. In-memory `SheetsClipboardPayload` (`ClipboardService.last`) with: source spreadsheet/sheet
     ids, the range, cells (content in **A1 relative form** + all format attributes + notes +
     linkUrl), merges, DV rules, CF rules intersecting, column widths/row heights.
- The copied range shows **marching ants** until Esc, an edit, or another copy.

### 12.3 Paste (`sheets.edit.paste`, 1 step)

Source resolution order (`ClipboardDecoder.decode` → `PasteSource`): (a) HTML contains
`data-wonky-clip` matching the in-memory payload →
internal payload; (b) HTML contains a `wonky:` comment → decoded payload (other window/app
instance); (c) HTML with a `<table>` → `HtmlTableCodec.parse` (Google Sheets, Excel, LibreOffice,
web pages); (d) `text/plain` → TSV (or CSV detection, §12.5); (e) image → insert image over cells
(08).

**Target** (`PastePlanner`):
- Top-left = active range's top-left. If the selection is a single range whose size is an exact
  multiple of the source size, the source is **tiled** to fill it (Google behavior); otherwise the
  source size is used.
- Pastes write through hidden rows (contiguous) — copied hidden rows were excluded at copy time.
- If the paste extends beyond the last row/column, rows/cols are **added** automatically (within
  the cell limit; else refused).
- Merged cells in the target that intersect the paste area partially → dialog "You can't paste
  here because it would break apart a merged cell" (Google message).
- Protected target cells → §16 checks; DV strict rules are **not** applied on paste (Google
  behavior: pasted invalid data is marked invalid).
- Formulas are translated relative to the new position (`FormulaCodec.translate`) — from internal
  payloads and from HTML `data-sheets-formula`.
- Pastes > 20,000 cells show a progress toast (chunked writes, 02 §7); > 500,000 cells confirm
  first.

### 12.4 Paste special (`sheets.edit.pasteSpecial {mode}`, 1 step)

| Mode | Shortcut | Writes |
|------|----------|--------|
| `values` | Mod+Shift+V | Values only (formulas → their current computed values; display numbers keep the raw number), no formats |
| `format` | Mod+Alt+V | Format attributes only (+ merges) |
| `formulas` | — | Content only (formulas translated, literals as-is), no formats |
| `conditionalFormatting` | — | Adds CF rules from the source mapped to the target range |
| `dataValidation` | — | Adds/replaces DV rules on the target (pasted CF/DV formulas are re-anchored like cell formulas, 06 §15.3) |
| `columnWidths` | — | Source column widths applied to target columns |
| `transposed` | — | Everything, rows ⇄ columns (formulas translated with transposed offsets) |
| `allExceptBorders` | — | Everything except the four border attributes |

From external sources only `values`, `format`, `transposed` and `allExceptBorders` are enabled
(others need the internal payload).

### 12.5 External formats

- **HTML** (`HtmlTableCodec`): first `<table>` (or all tables stacked with a blank row in
  between); `<th>/<td>` text (with `<br>` → `\n`), colspan/rowspan → merges, inline style and
  `<b>/<i>/<u>/<s>/<a href>` → formats and links (`<a>` covering the whole cell → `linkUrl`;
  partial → rich runs), `bgcolor`/`style` colors, borders (`border-*` CSS → nearest style),
  Google `data-sheets-*`, Excel `x:num`/`x:fmla`/`mso-number-format` → number formats. Values
  are parsed with `InputParser` (source locale assumed = spreadsheet locale) unless typed by
  `data-sheets-value`/`x:num`.
- **TSV/plain text**: split on `\t` and newlines (respecting quotes). A single column of text
  containing commas (or semicolons) in ≥ 80 % of lines shows a small **"Split text to columns"**
  chip near the pasted range for 10 s → `sheets.data.splitTextToColumns` (07).
- Text over 50,000 chars per cell is truncated with a warning toast.

### 12.6 Cut (`sheets.edit.cut`, —) and paste-after-cut

- Mod+X marks the range (marching ants, dashed). Nothing changes until paste.
- Paste after cut = **move** (§11 semantics; references follow; source cleared; 1 step). The cut
  payload is consumed (the clipboard then holds a normal copy of the moved data).
- Cut + paste into another spreadsheet = copy + clear source; references elsewhere in the source
  spreadsheet keep pointing at the now-empty source cells (Google behavior).
- A cut whose copy skipped hidden/filtered rows or columns (§12.2) moves only the copied (visible)
  cells: they land contiguously at the target, hidden source cells stay untouched, and references
  follow the moved cells (ranges only when entirely inside one visible block).

**AC**: copy a 3×3 range with a formula, bold and a merge from Wonky to Google Sheets and back
preserves values, formula, bold and merge; paste into a 6×6 selection tiles four times.

---

## 13. Structural operations

All through `StructureService`, all one undo step each, all MCP-callable. Row/column entities are
created with `FractionalIndex.nBetween(prev.sortKey, next.sortKey, n)` (02 §2).

### 13.1 Insert rows/columns

| Command | Menu | Args |
|---------|------|------|
| `sheets.rows.insertAbove` | Insert › Rows › Insert N rows above | `{count?, beforeRowId?}` (count defaults to the number of selected rows) |
| `sheets.rows.insertBelow` | … below | `{count?, afterRowId?}` |
| `sheets.cols.insertLeft` / `sheets.cols.insertRight` | Insert › Columns | `{count?, …}` |
| `sheets.rows.addMore` | footer | `{count}` (appends at end) |

- New rows copy the **anchor row's** row-level `formatJson` and height, and format-only cells for
  the anchor row's formatted cells (≤ 10,000; beyond that only the row-level format). Anchor =
  the row above for "below", the selected first row for "above" (Google: inserted rows take the
  formatting of the row above when one exists — we use the row above in both cases when it
  exists, else the row below).
- Ranges (CF, DV, filters, named, protected, charts, merges, groups) whose boundaries straddle the
  insertion point grow automatically because new ids sort between their boundary ids (02 S2).
- Formulas need no rewrite (id-based references, 02 S6).
- Checks the cell limit first; refusal dialog shows the current/maximum counts.

### 13.2 Delete rows/columns

`sheets.rows.delete {rowIds?}`, `sheets.cols.delete {colIds?}` (defaults: rows/cols of the
selection).
- Deletes `SheetRow`/`SheetColumn` entities (cells cascade, 02 §3.3).
- **Boundary repair** in the same transaction (`RangeBoundaryRepair`): for every GridRange in
  rules/named ranges/filters/charts/merges/groups and every **range reference in formulas** whose
  `r1`/`r2` (`c1`/`c2`) is deleted, move the boundary inward to the nearest surviving id inside the
  range; if nothing survives, the reference becomes `#REF!` (formulas) or the rule is deleted
  (rules; restored by undo). Single-cell references to deleted cells become `#REF!` (Google
  behavior: `=A5` → `=#REF!`).
- Deleting all rows of a sheet is refused ("A sheet must have at least one row").
- Undo re-inserts the same ids (with the descendants the plan listed) and restores rewritten formulas/ranges.

### 13.3 Insert/delete cells with shift (P1)

`sheets.cells.insertShiftRight`, `sheets.cells.insertShiftDown`, `sheets.cells.deleteShiftLeft`,
`sheets.cells.deleteShiftUp` (`{range}`):
- Implemented as moving the content of the affected strip (selected rows × columns from the
  range to the last used column, or selected columns × rows below) by N cells — cells are
  re-keyed (new deterministic ids), so this is a bulk move with `ReferenceRewriter` remapping
  references to moved cells (like §11). Rows/columns are appended if content would fall off.
- Merges crossing the strip boundary → refused with dialog.

### 13.4 Move rows/columns

`sheets.rows.move {rowIds, beforeRowId}` / `sheets.cols.move {colIds, beforeColId}`;
Edit › Move › Row up/down, Column left/right (`sheets.rows.moveUp`, `sheets.rows.moveDown`,
`sheets.cols.moveLeft`, `sheets.cols.moveRight`). Only `sortKey`s change (new keys between the
target neighbours); formulas keep pointing at the same cells; ranges whose interior order changes
keep their boundary ids (a moved-out boundary row moves the range edge with it — Google
behavior).

### 13.5 Hide/unhide

`sheets.rows.hide`, `sheets.rows.unhide`, `sheets.cols.hide`, `sheets.cols.unhide` (`{ids?}`;
unhide with no args unhides hidden runs inside/adjacent to the selection). Writes
`hidden` on entities. Hiding all columns is refused.

### 13.6 Resize and auto-fit

- `sheets.rows.resize {rowIds, height | null}` (null = automatic) and
  `sheets.cols.resize {colIds, width}`; the **Resize rows/columns dialog** offers "Specify row
  height [21] px" or "Fit to data" ([04 §11](04-screens-menus-toolbar.md#11-dialogs)).
- **Auto-fit columns** (`sheets.cols.autoFit`): width = max over non-empty cells of the measured
  display width (text layout at 100 % + padding 6 px; checkboxes 22 px; chips +24 px), header
  min 30 px, max 1,000 px. Computed asynchronously over all cells of the column (chunked, with
  progress if > 100k cells).
- **Automatic row heights** (row `height == null`): height = max(default height, tallest content —
  wrapped text, multi-line text, larger fonts, rotated text, in-cell images). `RowAutoHeightIndex`
  computes lazily for rows in/near the viewport and on load for rows containing wrapped/large
  content (index of such rows maintained by `CellStore`); when a computed height differs from the
  Fenwick value, the Fenwick is updated and scroll anchoring (§5) keeps the view stable.
  `sheets.rows.autoFit` resets heights to `null`.

### 13.7 Merge cells

UI and semantics in [06 §10](06-formatting.md#10-merge-cells). Grid behaviors: merges select as a
unit; navigation steps over them; the active cell inside a merge is the top-left cell; the editor
covers the merged rect.

### 13.8 Groups

Row/column grouping (outline) is specified in [07](07-data-tools.md); the grid renders the gutter
(§3) and hides collapsed rows/cols via `AxisIndex` sizes.

**AC**: inserting 3 rows above row 5 while a collaborator offline edits B7 results, after sync,
in their value at B10; deleting rows 1–3 changes `=SUM(A1:A10)` into `=SUM(A1:A7)` (displayed),
and undo restores both rows and formula text.

---

## 14. In-cell content and widgets

### 14.1 Checkboxes (DV checkbox)

- Cells with a DV `checkbox` rule (07) paint a 14 × 14 px (× zoom) rounded box aligned per the
  cell's horizontal alignment (default center), checked = filled with the cell's text color
  (default `primary`) + check mark; unchecked = 1.5 px outline. Custom checked/unchecked values
  supported (07).
- Click on the box toggles (`sheets.dv.toggleCheckbox {cells:[…]}`, 1 step); click elsewhere in
  the cell selects only. **Space** toggles all checkbox cells in the selection: if any is
  unchecked → check all, else uncheck all.
- Insert › Checkbox (`sheets.insert.checkbox`) creates the DV rule on the selection.

### 14.2 Dropdown chips (DV list)

- Display styles from `DataValidationRule.displayStyle`: `chip` (rounded pill with option color
  from the rule, text ellipsized, chevron ▾ inside), `arrow` (plain text + ▾ at the right edge),
  `plainText` (no affordance).
- Click on chip/arrow or **Alt+↓** → `DropdownPickerPopover` (`ShadPopover` anchored to the
  cell): search input (when > 7 options), option list with color dots, current value checked,
  keyboard ↑/↓/Enter, Esc closes; multi-select rules (P2) show checkboxes and *Done*. Selecting
  writes the value (`sheets.cell.setInput`, 1 step).
- Invalid values (warning rules) show the `invalidTriangle` and a tooltip with the rule help text.

### 14.3 Smart chips (P2)

- Typing `@` at the start of a cell opens a chip menu (People, Date, Dropdown). People chip =
  rich run with `{"chip":{"kind":"person","userId":"…","email":"…"}}` (addition to the `r:` run
  format, §20). Hover → person card (avatar, name, email). Date chip → date picker
  (`ShadCalendar`) and stores a date number with a date format.
- **As built** (`features/in_cell/smart_chips.dart`, `commands/chip_commands.dart`): typing `@`
  as the first character of a new value drops the edit and opens `SmartChipMenu` at the cell
  (also Insert › Smart chips and the context menus, `sheets.insert.smartChip` without `kind`):
  a search field continues the text; *People* are the spreadsheet's editors (cached per device
  for offline, `FileEditors`) plus the user; *Date* opens the date picker; *Dropdown* runs
  `sheets.insert.dropdown`; *Insert "@…" as text* keeps the typed text. ↑/↓/Enter, Esc. The
  hover card shows name, email and *Copy email*. Agents pass `kind` (`person` with
  `email`/`name`/`userId`, `file` with `uuid` (+ `name`/`itemKind`), `date` with an ISO `date`).
  **Chips are rich runs** laid out by the cell layer (`RichTextLayoutCache`: a leading
  placeholder for the avatar/icon, the label in the neutral chip text color, end padding;
  `paintRichChipsBehind`/`paintRichChipsFront` draw the pills and avatars around the paragraph),
  so chips align, wrap and mix with other text and runs ("Owner: @Ann").
  **File chips**: the menu's *Files* section lists recently opened drive items and drive search
  results (not this spreadsheet); a chip is `{"chip":{"kind":"file","uuid":…,"itemKind":…}}` on
  the item's name with a document/spreadsheet/folder icon. Its hover card has *Open*
  (`sheets.chip.openFile {uuid}`: the item opens in this window, `ShellServices.openItem`). No
  place chips.

### 14.4 Hyperlinks

- `Cell.linkUrl` (whole cell) or link runs; text matching a URL (`https?://…`, `www.…`, e-mail)
  typed into a cell auto-links (stored as `linkUrl`; undoable as part of the commit). Internal
  links `#sheet=<sheetId>&range=A1:B2` navigate within the spreadsheet.
- Hover a link (400 ms) or select a linked cell → **link card** (`LinkHoverCard`, `ShadPopover`):
  URL (elided), *Copy link*, *Edit* (Mod+K), *Remove link* (`sheets.link.remove`). No external
  previews are fetched (privacy). Click on the URL in the card → external link confirm (suite
  03 §1). Mod+click on the cell text opens directly (with confirm).
- `sheets.insert.link` (Mod+K): popover with *Text* (prefilled with cell text) and *Link* input
  (URL, or search sheets/named ranges for internal links) → *Apply* (1 step).
  *Copy link* is `sheets.link.copy {url?}` (system clipboard, toast; no undo step).
  **As built** (`features/links/link_dialog.dart`): a dialog (`dialog.link`, MCP-describable with
  fields `text`/`url` and the current `suggestions`) rather than a cell-anchored popover. Typing
  in *Link* lists matching sheets, named ranges and — when the text is a range (`B2:C9`,
  `Sheet2!A1`) — that range (↑/↓, Enter or click picks one). Targets are stored as
  `#sheet=<id>`, `#range=<name>` (follows the named range) or `#sheet=<id>&range=A1:B2`; an empty
  cell gets the target's label as text; the link card shows "In this spreadsheet · ‹label›".

### 14.5 Notes

- Black 6 px triangle top-right. Hover → read-only note popover (max 320 × 240, scroll).
- Shift+F2 / Insert › Note / context menu → `NotePopover` editor (`ShadTextarea`, auto-focus);
  closes and saves on blur/Esc (Esc saves, as Google) via `sheets.notes.insert {cell, text}` (1
  step); empty text deletes the note. Edit › Delete › Notes = `sheets.notes.clear {range}`.

### 14.6 Comments indicator

Cells with open comment threads (anchor kind `cell`/`range`, suite 07 §2) show a
`commentHighlight` triangle top-right; if a cell has both a note and a comment, the comment
triangle wins and the hover card shows both. Hover (300 ms) → hover card; click → thread card
docked next to the cell. Details: [10 §3.3](10-collaboration-history.md).

### 14.7 Error cells

Formula errors render the error text (`#DIV/0!`) centered with an `errorTriangle` top-right.
Hover (300 ms) → `ErrorTooltip`: title "Error", message from the engine (e.g. "Function DIVIDE
parameter 2 cannot be zero."), and for `#REF!`/`#NAME?` a hint. `#N/A` shows the triangle only if
the error carries a message (Google behavior).

### 14.8 Spilled arrays

- Spill values render like normal values (no special color). When the **anchor** or any spilled
  cell is selected, a 1 px `spillFrame` border outlines the spill range.
- Selecting a spilled (non-anchor) cell shows the anchor's formula greyed in the formula bar.
- `#SPILL!` at the anchor: tooltip "Array result was not expanded because it would overwrite
  data in B3."; blocking cells get a dashed `spillFrame` outline while the anchor is selected
  (as built: `SpillBlockersLayer`, `features/in_cell/spill_blockers_layer.dart`, over the core
  `FormulaEngine.spillAreas`: content cells of the wanted area and cells of other arrays or pivot
  output there, ≤ 500).
- Typing into a spilled cell writes a literal there (anchor becomes `#SPILL!`).

### 14.9 Pivot table output

Pivot output (07) renders as read-only overlay values with formats from the pivot spec. Selecting
a pivot cell shows a floating *Edit* button (✎, top-right of the pivot's anchor area) that opens
the pivot editor panel. Edits/paste/delete in the pivot area → toast "You can't edit a pivot
table's output. Use the pivot table editor." Overlays are recomputed locally (02 §3.5). Implementation:
the *Edit* button floats just right of the output's top-right corner (inside the grid when that
is off-screen); double-clicking a value cell drills down (07 §7.9) instead of editing; Delete over
the whole output deletes the pivot (07 §7.13).

### 14.10 Images in cells and sparklines

Rendered by the content layer via renderers registered by 08 (`InCellRenderer` interface: `bool
handles(CellRenderInfo)`, `void paint(Canvas, Rect, CellRenderInfo)`).

---

## 15. Collaboration visuals

### 15.1 Remote cursors and selections

Owned by [10 §1](10-collaboration-history.md) (`PresenceCursor` JSON, `RemotePresenceLayer`
styles, sheet-tab avatars, jump-to and follow mode). Grid contract:
- The grid registers `RemotePresenceLayer` as a dynamic layer of `RenderGridOverlay` (layer #8,
  §2.4) and provides `GridGeometry` for id → rect mapping (frozen-pane clipping, hidden rows
  collapse onto the boundary).
- Local selection changes are published through `SheetsPresenceController` (throttled 10/s),
  including `editing: true` while a `CellEditSession` is open.
- `GridScrollController` exposes `revealCell(CellRef, {flash})` and `followViewport(...)` used
  by jump-to and follow mode; any local scroll/selection stops following.

### 15.2 Commit hints

Owned by [10 §2](10-collaboration-history.md) (`CommitHintOverlay`). Committed values reach
other clients as RevLog ops in about one round trip, so hints carry no values: the overlay draws
a collaborator's in-progress text over the cell (`typing`) and a shimmer over a range whose large
change is still being saved (`pending`), and invalidates the affected tiles when hints arrive or
expire. Hints never write to the database.

### 15.3 Toasts and indicators

| Situation | UI |
|-----------|----|
| Undo step partially skipped (columns changed remotely) | `ShadSonner` toast "Some changes couldn't be undone because they were edited by someone else." |
| Undo step fully no-op | toast "Nothing to undo here — this was changed by someone else." and the step is dropped |
| Edited cell changed remotely while you were editing it | on commit, your value wins (it arrives at the server last); no toast. Offline edits that replaced newer remote edits → review toast/dialog per [10 §9](10-collaboration-history.md) |
| Row/column you are editing deleted remotely | editor closes, toast "The row you were editing was deleted by Bo." |
| Offline | Shell offline banner; `SyncStatusIndicator` "Offline" (tooltip: "Offline — changes saved on this device"); remote cursors fade out after 30 s |
| Sync error | Status "Sync error" (click → details & retry) |
| Your change rejected by the server (protected range, limit, invalid change) | The change is rolled back, its undo step removed, and one toast names the change and the reason (17 part 6 §4.6; protected ranges §16) |

---

## 16. Protected ranges in the grid

- **View › Show › Protected ranges** (`sheets.view.toggleProtectedRanges`, per user, —, default
  on for editors who can't edit them; kept per spreadsheet in the user's `LocalViewState`,
  `prot: false`): diagonal stripes (45°, 1 px lines every 8 px,
  `protectedStripe` token) over protected cells the user **cannot** edit (or all protected cells
  for owners when "show all" is selected).
- Before any write (the client write gate: `SheetEditorController.apply` → `WriteIntents.of` →
  `ProtectionGuard`, both in `wonky_sheets_core`):
  - **Not allowed** → `ShadDialog.alert` "Protected cell or object — You are trying to edit a
    protected cell or object. Please contact the spreadsheet owner to remove protection if you
    need to edit." [OK]. Nothing is written (the whole command aborts).
  - **Warning only** → dialog "Heads up! Someone has protected part of this sheet to prevent
    accidental changes. Edit anyway?" with checkbox "Don't show this again for 5 minutes" →
    [Cancel] [OK]. After OK the command **resumes** at the blocked write (commands that ask
    something first — link, alt text, resize, merge, delete sheet, pivot drill-down — apply
    through `applyConfirmed`, so their dialogs aren't shown again); commands without dialogs
    simply run again.
- Commands from MCP/AI/scripts get the same check (tool error `protected_range` for not allowed;
  warning-only ranges are writable for MCP with a `warnings` entry in the result).
- **The server enforces it too** ([07 §10.3](07-data-tools.md), 17 part 5 §3.5): an op that
  writes a protected cell, structure, rule, object or sheet the author may not edit is rejected
  whole. That catches what the gate couldn't know: an edit made offline before the protection
  arrived, a changed editor list, a stale client. The grid rolls the change back, removes its
  undo step and shows the toast "“{label}” wasn’t saved because it edits a protected cell or
  object." **As built:** the toast doesn't offer *Save my changes as a copy* for offline edits
  yet (17, As built 10).
- Protection definitions & panel: [07](07-data-tools.md).

---

## 17. Performance budgets and instrumentation

| Scenario | Budget | Measured by |
|----------|--------|-------------|
| Open spreadsheet with 1M cells already synced: first viewport painted | < 3 s desktop, < 4 s web (OPFS) from route push | `perf_open_1m` integration test (timeline) |
| Background load of remaining chunks | < 15 s for 1M cells, UI responsive (no frame > 50 ms) | same |
| Scroll/fling at 1M cells | ≥ 58 fps median, p99 frame < 25 ms | `perf_scroll_1m` |
| Local edit commit → cell repainted | < 16 ms (model update synchronous, DB write async) | `perf_commit` |
| Local commit → dependent formulas recalculated (1,000 dependents) | < 50 ms | 05 benchmarks |
| Selection change → overlay repaint | < 4 ms | |
| Paste 100k cells | < 3 s to visible result, < 10 s fully persisted | `perf_paste_100k` |
| Insert 1,000 rows at top of 1M-cell sheet | < 200 ms visible | |
| Sort 100k rows | < 2 s (07) | |
| Memory for 1M-cell sheet | < 600 MB desktop, < 900 MB web | DevTools memory snapshot |

`GridPerfMonitor` (debug + profile builds) records frame times, tile-record times, paragraph cache
hit rates and exposes them in a hidden debug panel (`sheets.debug.perfOverlay`, only in
non-release builds) and to MCP `ui.get_state` in debug builds.

---

## 18. Accessibility

- `GridSemantics` exposes the grid as a semantics node with `SemanticsRole.grid`
  (`role: table` on web), label "Sheet1 grid", and child nodes for **visible cells only**
  (capped at 2,500) with `SemanticsRole.cell`, row/column index attributes, value = formatted
  value; header nodes use `columnHeader`/`rowHeader` roles.
- `SelectionAnnouncer` (debounced 100 ms) calls `SemanticsService.announce` on active-cell
  change: "B4, 42" / "B4, 42, formula =SUM(B1:B3)" / "B4, empty" / "B4, checkbox checked" /
  "B4, link, example.com" / "B4, has note" / "B4, has comment"; multi-cell selection: "A1 to C5
  selected, 15 cells". Merges: "B4 to C5 merged". Errors: "B4, error, divide by zero".
- Editing: entering edit mode announces "Editing B4"; commit announces nothing extra; validation
  errors are announced via dialog semantics.
- Remote edits are not announced per cell; join/leave are (suite 07, setting).
- Keyboard-only: every feature reachable without a pointer — context menu via Shift+F10 /
  Menu key (`sheets.contextMenu.open` at active cell), fill via Mod+D/R/Enter and Edit menu,
  resize via dialog, move via Edit › Move, freeze via View menu, dropdown via Alt+↓, links via
  Mod+K, notes via Shift+F2, sheet tabs via Mod+Shift+PageUp/Down and the All sheets list.
- Focus visibility: the active-cell frame doubles as the focus indicator (2 px, ≥ 3:1 contrast in
  both themes).
- High-contrast: when the OS requests high contrast, gridlines and selection use stronger tokens.
- Reduce motion disables marching ants animation (static dashes), skeleton shimmer, smooth scroll
  animations and editing-indicator animation.

> **As built** (`grid/a11y/grid_semantics.dart`): `GridSemantics` is a render object that
> builds its semantics only while semantics are on: a `table` node, a header `row` of
> `columnHeader` nodes, and per visible row a `row` node with the row number and the cells
> (`cell`, label = the 03 §18 description, selected = active cell), capped at 2,500 cells,
> rebuilt on scroll/content/selection. `SelectionAnnouncer` sends `sendAnnouncement` 100 ms
> after the selection settles and "Editing B4" when editing starts. Comment presence is not
> announced yet.

---

## 19. Command catalogue (grid & editing)

Undo column: **1** = one undo step; **—** = not undoable. All commands have `requiredRole =
editor` if they mutate, `viewer` otherwise. MCP: all are invocable through
`ui.invoke_command`; headless equivalents are in [12](12-mcp-and-ai.md).

| Command id | Args | Shortcut | Undo | Notes / MCP |
|------------|------|----------|------|-------------|
| `sheets.nav.move` | `dir: up\|down\|left\|right, extend?, toEdge?` | arrows (+Shift/Mod) | — | |
| `sheets.nav.tab` / `sheets.nav.enter` | `reverse?` | Tab / Enter | — | |
| `sheets.nav.rowStart` / `rowEnd` / `sheetStart` / `sheetEnd` | `extend?` | Home/End (+Mod/Shift) | — | |
| `sheets.nav.page` / `sheets.nav.pageHorizontal` | `dir` | PgUp/PgDn (+Alt) | — | |
| `sheets.nav.scrollToActive` | — | Mod+Backspace | — | |
| `sheets.nav.goTo` | `target: string` (A1, range, sheet!A1, named range) | Mod+Alt+G | — | MCP-friendly navigation |
| `sheets.select.range` | `a1: string` (multi via `,`) | — | — | `ui.sheets.select_range` |
| `sheets.select.all` / `.rows` / `.columns` / `.dataRegion` | — | Mod+A / Shift+Space / Mod+Space | — | |
| `sheets.cell.edit` | `caretAtEnd?` | F2 | — | Opens editor |
| `sheets.cell.setInput` | `a1?, input: string` | (editor commit) | 1 | Same pipeline as typing (parse, DV, protection) |
| `sheets.formula.cycleReferenceType` / `toggleArrayFormula` / `toggleHelpCard` / `toggleHelpCardVisible` | — | F4 / Mod+Shift+Enter / F1 / Shift+F1 (cellEditor) | — | Defined in [05](05-formula-engine.md); editor-text operations |
| `sheets.cell.setInputForSelection` | `input` | Mod+Enter (editor) | 1 | |
| `sheets.cell.insertDate` / `insertTime` / `insertDateTime` | — | Mod+; / Mod+Shift+; / Mod+Alt+Shift+; | 1 | |
| `sheets.cell.copyLink` | — | — | — | "Get link to this cell": copies `/s/<uuid>?sheet=<id>&range=B4` |
| `sheets.edit.undo` / `sheets.edit.redo` | — | Mod+Z / Mod+Shift+Z, Mod+Y | — | `ui.undo`/`ui.redo` |
| `sheets.edit.repeatLast` | — | F4 | 1 | |
| `sheets.edit.cut` / `copy` | — | Mod+X / Mod+C | — | |
| `sheets.edit.paste` | — | Mod+V | 1 | MCP: prefer `sheets.set_values` headless |
| `sheets.edit.pasteSpecial` | `mode` (§12.4) | Mod+Shift+V, Mod+Alt+V | 1 | |
| `sheets.edit.clearValues` | `range?` | Delete/Backspace | 1 | |
| `sheets.edit.clearAll` | `range?` | — | 1 | Values + formats + notes + links |
| `sheets.fill.down` / `sheets.fill.right` / `sheets.fill.selection` | — | Mod+D / Mod+R / Mod+Enter | 1 | |
| `sheets.fill.series` | `source, target, mode: auto\|copy` | (fill handle) | 1 | |
| `sheets.fill.autoFillDown` | — | (double-click handle) | 1 | |
| `sheets.cells.moveRange` / `copyRange` | `source, destTopLeft` | (drag) | 1 | |
| `sheets.cells.insertShiftRight` / `insertShiftDown` / `deleteShiftLeft` / `deleteShiftUp` | `range?` | — | 1 | P1 |
| `sheets.structure.insertBySelection` / `deleteBySelection` | — | Mod+Alt+= / Mod+Alt+- | 1 | Dispatches to rows/cols/cells |
| `sheets.rows.insertAbove` / `insertBelow` | `count?` | — | 1 | |
| `sheets.cols.insertLeft` / `insertRight` | `count?` | — | 1 | |
| `sheets.rows.addMore` | `count` | — | 1 | |
| `sheets.rows.delete` / `sheets.cols.delete` | `ids?` | — | 1 | |
| `sheets.rows.move` / `sheets.cols.move` | `ids, before` | (header drag) | 1 | |
| `sheets.rows.moveUp` / `moveDown`, `sheets.cols.moveLeft` / `moveRight` | — | — | 1 | |
| `sheets.rows.hide` / `unhide`, `sheets.cols.hide` / `unhide` | `ids?` | Mod+Alt+9 / Mod+Shift+9, Mod+Alt+0 / Mod+Shift+0 | 1 | |
| `sheets.rows.resize` / `sheets.cols.resize` | `ids, size\|null` | (drag) | 1 | |
| `sheets.rows.autoFit` / `sheets.cols.autoFit` | `ids` | (double-click edge) | 1 | |
| `sheets.view.freezeRows` / `freezeColumns` | `count` | — | 1 | Synced sheet property |
| `sheets.view.zoom` | `percent` | Mod+= / Mod+- (desktop), Mod+wheel | — | Web: browser zoom keys not overridden |
| `sheets.view.toggleFormulas` | — | Mod+\` | — | Per user |
| `sheets.view.toggleFormulaBar` | — | — | — | Per user |
| `sheets.view.toggleGridlines` | — | — | 1 | Sheet property |
| `sheets.view.toggleProtectedRanges` | — | — | — | Per user |
| `sheets.formulaBar.toggleExpanded` | — | — | — | |
| `sheets.namedRanges.createFromSelection` | `name` | (name box) | 1 | |
| `sheets.insert.link` / `sheets.link.remove` / `sheets.link.open` | `url?, text?` | Mod+K | 1 / 1 / — | |
| `sheets.link.copy` | `url?` (default: the active cell's link) | — | — | Link card *Copy link* |
| `sheets.insert.smartChip` (P2) | `kind` (`person`/`date`/`dropdown`), `email?`, `name?`, `date?` | `@` at the start of a cell | 1 | §14.3 |
| `sheets.notes.insert` / `sheets.notes.clear` | `cell, text` / `range` | Shift+F2 | 1 | |
| `sheets.dv.toggleCheckbox` | `cells?` | Space | 1 | |
| `sheets.dv.openDropdown` | — | Alt+↓ | — | |
| `sheets.insert.checkbox` / `sheets.insert.dropdown` | — | — | 1 | Creates DV rule (07) |
| `sheets.contextMenu.open` | — | Shift+F10 / Menu | — | |
| `sheets.tools.toggleAutocomplete` | — | — | — | Per user |
| `sheets.sheet.activateNext` / `activatePrevious` / `sheets.sheet.activate` | `sheetId?` | Mod+Shift+PgDn/PgUp | — | |
| `sheets.file.saveNoop` | — | Mod+S | — | Toast only |

---

## 20. Additions to 02-data-model (proposed)

> These are **additions**, not changes; 02 remains authoritative. To be merged into 02 by its
> owner.

| Addition | Where | Purpose |
|----------|-------|---------|
| Rich-text run attribute `chip` (`{"kind":"person"\|"date"\|"file", …}`) | `r:` content run `f` map | Smart chips (P2, §14.3) |
| `LocalViewState.json` keys: `zoom`, `showFormulas`, `showFormulaBar`, `showProtectedRanges`, `formulaBarExpanded`, per-sheet `{scrollTopRowId, scrollTopOffset, scrollLeftColId, scrollLeftOffset, selection}` | local-only table (02 §4) | View state persistence |
| `UserPreferences.sheetsDefaults` keys: `enterStartsEditing`, `formulaAutocomplete`, `formulaHelp`, `customLists: [[…]]`, `autocomplete`, `showEditorMode` | suite 04 | Per-user editing preferences |
| Commit hints carry the sender's `sessionId` | presence payload (`PresenceEvent.Hints`, [10 §2.1](10-collaboration-history.md)) | Attribute `typing`/`pending` hints to a participant |

## 21. Testing

- Golden tests per layer (light/dark, DPR 1/2, zoom 50/100/200): overflow, wrap, rotation,
  borders, merges, frozen panes, checkboxes, chips, triangles, remote selections, ref boxes.
- Widget tests: keyboard map (§7), editor modes (§8.1), point mode, F4, autocomplete, fill handle
  drags (simulated pointer), header resize/move, freeze drag, clipboard round-trips (fake
  `super_clipboard` backend).
- Unit tests (core): `InputParser` vectors per locale (en_US, en_GB, de_DE, fr_FR, ja_JP),
  `SeriesDetector`, `HtmlTableCodec` (fixtures copied from Google Sheets, Excel, LibreOffice,
  Wikipedia), `FormulaCodec.translate`, `ReferenceRewriter`, `DataEdgeFinder`.
- Command tests: execute → undo → redo equality for every mutating command in §19 (suite 08 §4).
- Integration perf tests (§17) run nightly on desktop and web (`--wasm`).
