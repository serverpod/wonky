# Code-quality review: `wonky_sheets/` (Flutter app layer)

Scope: `wonky_sheets/lib` (321 files, ~118k lines, of which ~22.7k are generated l10n) and `wonky_sheets/test`
(125 files, ~22k lines, ~728 test cases). I did not review the core package or the sync engine internals, and
looked at the sync layer only where the app uses it. All file:line references are relative to
`C:\Users\info\Projects\wonky\`. I read the code behind every finding. Findings I could not confirm by running
the app are marked **(unverified)**.

Context read: AGENTS.md, specs/README.md, specs/01-architecture.md, specs/08-commands-and-undo.md,
specs/wonky_sheets/{README,STATUS}.md, 03-grid-and-editing.md §2.

---

## Prioritised findings

| ID | Title | Sev | Category | Effort |
|----|-------|-----|----------|--------|
| S-01 | Touch can't scroll the grid on phones (mobile read-only view) | High | bug / a11y | M |
| S-02 | Long data jobs keep the global undo transaction open, so concurrent edits join it | High | bug (undo) | M |
| S-03 | Selection stats scan up to 5M cells and wipe the render cache | High | perf | S |
| S-04 | Every selection change or model batch rebuilds the whole editor chrome | Med | perf | M |
| S-05 | The render cache is dropped wholesale on every batch or recalc, and the border check is O(rows+cols) per frame and O(cells) per edit | Med | perf | M |
| S-06 | Widget overlays use the previous frame's geometry; paint mutates controller state | Med | perf / maintainability | M |
| S-07 | A cursor change calls `setState` on `GridArea`, which repaints both grid passes | Med | perf | S |
| S-08 | `PointerCancel` commits drags (fill, move, resize, freeze) | Med | bug | S |
| S-09 | The global rich-text layout cache ignores the spreadsheet theme | Med | bug | S |
| S-10 | `ui.sheets.type_in_cell` records agent writes as `ui` and discards the user's edit in progress | Med | bug / compliance | S |
| S-11 | God files and classes | Med | maintainability | L |
| S-12 | Code duplicated with Slides/Write that belongs in `wonky_app` | Med | maintainability | M |
| S-13 | Per-editor services: lifecycle and ownership are inconsistent | Low | maintainability | S |
| S-14 | Placeholder commands for features shared packages now provide (emoji, spellcheck) | Low | maintainability | S–M |
| S-15 | Overlay repaints redo work (formula re-parse, `showFormulas` A1 conversion) | Low | perf | S |
| S-16 | Swallowed exceptions and exception-as-control-flow | Low | DX | S |
| S-17 | Hard-coded English labels | Low | i18n | S |
| S-18 | Semantics tree rebuilt on every scroll frame (2,500 nodes) | Low | a11y / perf | S |
| S-19 | Stale project docs (AGENTS.md vs STATUS.md) | Low | DX | S |
| T-01…T-08 | Testing gaps | Med | testing | M |

---

### S-01: Touch can't scroll the grid on phones (High, bug/a11y, M)

**Evidence.**
- `wonky_sheets/lib/features/grid/grid_area.dart:1030-1038`. The grid is one raw `Listener`
  (`onPointerDown/Move/Up/Cancel`, `onPointerSignal`, `onPointerPanZoom*`). It has no `PointerDeviceKind`
  handling, no drag or scale recognizer, and no `Scrollable`.
- `_onDown` (282-485) turns every primary pointer-down on a cell into `_Drag.select`, and `_onMove`
  (549-554) extends the selection. A one-finger swipe therefore selects a range and never scrolls. Scrolling
  comes only from wheel signals (839-859) and trackpad `PointerPanZoom*` (876-886), which phones never send.
  Pinch-zoom has the same gap: `PointerScaleEvent` and `PointerPanZoom` come from trackpads only.
- Searching `grid/`, `sheet_editor/`, `collab_overlay.dart`, `objects_layer.dart` and `grid_drop_target.dart`
  for touch handling finds only the 8 px scrollbar thumb's `onPanUpdate` (grid_area.dart:1202).
- The suite spec (specs/02-design-system.md §6.1, T-9/T-12) makes phones show the Sheets grid read-only.
  `test/features/sheet_editor/sheet_editor_screen_test.dart:93-182` checks only the mobile layout widgets.

**Why it matters.** A phone user can open a spreadsheet but can only reach the visible rows and columns, or
drag an 8 px thumb. This is the main use of the mobile view. **(unverified on a device, but the code has no
path for it)**

**Recommendation.** In `_onDown`, branch on `e.kind == PointerDeviceKind.touch` (and stylus). A touch drag
pans `c.scroll` and flings with a `FrictionSimulation` or `ClampingScrollSimulation` driven by a ticker. A
tap selects the cell. A long-press then drag selects a range. Two fingers pinch-zoom (use a
`ScaleGestureRecognizer` in a `RawGestureDetector`, or track the pointers by hand). In read-only mobile mode,
skip fill-handle and move hit-testing. Add widget tests that send `PointerDeviceKind.touch` gestures.

### S-02: Long data jobs keep the undo transaction open, so concurrent commands join it (High, bug, M)

**Evidence.**
- `packages/wonky_app/lib/src/commands/command_dispatcher.dart:170-174`: if
  `undo.currentTransaction != null` when a command runs, the command is treated as *nested* and joins that
  transaction. `currentTransaction` is global (`undo_service.dart:155`).
- `wonky_sheets/lib/features/data_tools/data_job.dart:54-114, 120-162`: `DataJobs.run` awaits frames
  (`_nextFrame`) while it plans in cooperative steps. It shows only a non-modal progress toast. It runs inside
  sort, remove duplicates, trim, split, filter and cleanup commands (`commands/sort_commands.dart:119`,
  `data_commands.dart:57,131,154,173`, `cleanup_commands.dart:103,162,287`, `filter_commands.dart:325`), so
  the command's transaction stays open across many frames while the grid stays interactive.
- No write gate stops edits while a job runs. `_planInSteps` (`data_job.dart:126`) even listens for model
  changes and re-plans.
- *Cancel* throws `WriteDeclined` (`data_job.dart:93-96`), and the dispatcher then calls `t.rollback()`
  (`command_dispatcher.dart:195-199`).

**Why it matters.** A user who types into a cell during a 25k-row sort runs `sheets.cell.setInput` as a
nested command:
- the edit gets no undo step of its own;
- undoing "Sort" also reverts the typed value;
- cancelling the sort rolls the typed value back.

MCP or agent commands (`ui.invoke_command`, assistant runs) that arrive while any async command awaits, for
example a dialog-driven command, join it the same way. Imports are mostly safe for human input because
`runWithProgress` is modal (`features/import_export/progress_dialog.dart:40-65`), but agents can still
interleave.

**Recommendation.**
- Short term, in the app: while `DataJobs` runs, add a `writeGate` that refuses writes with "Wait for the
  sort to finish", or make the progress toast modal for writes. Also refuse agent `ui.*` writes while a job
  runs.
- Root fix, in `wonky_app`: detect nesting with a `Zone` value set by `_run`, or with an explicit
  `ctx.transaction`, instead of the global `currentTransaction`. Then an unrelated command that starts during
  an await opens its own transaction.
- Add a test: start a ≥20k-row sort, type into a cell before it finishes, undo, and check the typed value
  survives.

### S-03: Selection stats scan up to 5M cells and wipe the render cache (High, perf, S)

**Evidence.**
- `wonky_sheets/lib/features/status/selection_stats.dart:58-104`: `SelectionStats.of(ed, cap: 5000000)`
  visits every content cell of the selection on the UI thread. For **every numeric cell** it calls
  `ed.cells.displayAt(...)` (line 88), which does the full format, number-format and conditional-format
  resolution, and it keeps doing so after `mixed` is already true.
- `features/grid/paint/cell_render_cache.dart:429-438`: `displayAt` caches every result and **clears the
  whole map once it holds more than 60,000 entries**.
- The status button recomputes on every selection change and every `contentSignal` (that is, every model
  batch, local or remote, and every recalc), debounced by 100 ms
  (`features/status/selection_stats_button.dart:44-67`). The Explore panel and MCP call it too
  (`explore_panel.dart:140`, `mcp/ui_sheets_tools.dart:159`).

**Why it matters.** With a column or the whole sheet selected (Mod+A, column headers), each remote edit
causes:
- a synchronous scan of up to millions of cells;
- a full display resolution of every number;
- repeated clearing of the paint cache. The next grid frame then re-resolves every visible cell.

That makes visible jank on large sheets during collaboration.

**Recommendation.**
- Read only the number-format pattern, cheaply: `CellSource.numberFormatAt` or the explicit-format chain.
  Stop comparing once `mixed` is true.
- Never fill the paint cache from non-paint code: give `CellRenderCache` a non-caching `peek` or `resolve`.
- Above a threshold (for example 100k cells), compute in time slices or keep running aggregates. Cap the
  synchronous path near 200k cells, as MCP and Explore already do.

### S-04: Every selection change or model batch rebuilds the whole editor chrome (Med, perf, M)

**Evidence.**
- The notification chain:
  - `sheet_editor_controller.dart:391-394`: `_onSelection` calls `notifyListeners()` on every selection
    change, including each cell crossed in a drag-select or Shift+arrow. `_onBatch` does the same for every
    model batch (380-383).
  - `sheets_document_controller.dart:74`: `editor.addListener(notifyListeners)` forwards it.
  - `packages/wonky_app/lib/src/shell/shell_services.dart:363,379`: the document listener calls
    `registry.notifyStateChanged()`.
- Listeners that rebuild on it:
  - `EditorScaffold` (`packages/wonky_app/lib/src/editor/editor_scaffold.dart:368`, the
    `ListenableBuilder(listenable: s.registry)` around the title row, menubar and panels);
  - `SheetsToolbar` (`features/toolbar/sheets_toolbar.dart:65-73`: about 60 `dispatcher.stateOf` calls plus
    `ed.activeFormat()` per build);
  - `SheetTabBar` (`tab_bar/sheet_tab_bar.dart:61`);
  - both status bars (`status/selection_stats_button.dart:135,203`);
  - `SheetObjectsHost` (`objects/objects_layer.dart:98-100`, which rebuilds the objects overlay);
  - the formula bar (`formula_bar/formula_bar.dart:34`);
  - several panels (`named_ranges_panel.dart:55`, `filter_views_panel.dart:55`, …).

**Why it matters.** Arrow keys, drag selection and every remote edit pay for rebuilding the toolbar, tab
bar, status bar, object overlay and scaffold. This is the hottest input path. The cost has not been
measured; profile it in a release build with the performance overlay **(unverified magnitude)**.

**Recommendation.**
- Stop calling `notifyListeners()` from `_onSelection`. Consumers that need selection should listen to
  `selection` directly.
- Have `SheetsDocumentController` forward only role, title or sheet changes.
- Coalesce `registry.notifyStateChanged()` to once per frame.
- Rebuild the toolbar from a derived `ValueListenable<ToolbarState>` (active format plus enabled flags,
  compared by value) so unchanged state skips the rebuild.
- Make `SheetObjectsHost` listen to `activeSheetId` or sheet-kind changes only.

### S-05: The render cache is dropped wholesale; the border fast path is O(n) (Med, perf, M)

**Evidence.**
- `sheet_editor_controller.dart:145-146, 380, 385-389`: every model batch **and** every recalc batch calls
  `cells.invalidate()`, which clears all cached `CellDisplay`, edges and the resolver
  (`cell_render_cache.dart:420-425`). The next frame re-resolves every visible cell (about 2,000 at 50 % zoom,
  including conditional-format evaluation). Spec 03 §2.7 plans dirty-range invalidation; the code does not
  do it.
- `content_layers.dart:515` calls `CellRenderCache.sheetHasBorders` on **every content paint**, so on every
  scroll frame. Unless the sheet record has borders, it iterates **all** `rowRecords` and `columnRecords`
  (`cell_render_cache.dart:483-495`). Every row has a `SheetRow` record
  (`packages/wonky_sheets_core/lib/src/model/sheet_model.dart:27`, `workbook_model.dart:643`), so this is
  O(rows) per frame. After each invalidation, `_cellBorders` (497-509) also scans **every cell** of the sheet
  once.

**Why it matters.** On a 100k-row or 1M-cell sheet without borders, which is the common case:
- each scroll frame pays an O(rows) loop;
- each edit or recalc (volatile functions, `=AI()` results streaming in, custom functions) pays an O(cells)
  scan plus a cold re-resolve of the viewport.

This partly explains the 12.6–20 ms debug frame times noted in STATUS.

**Recommendation.**
- Keep a per-sheet `hasBorders` flag that the model maintains (or that is cached by model version), not
  recomputed on each paint.
- Invalidate per sheet and per range from `WorkbookChangeBatch` events (`CellsChanged` and similar) and from
  the recalc batch's changed cell ids. Keep wholesale invalidation for theme, locale and structure changes.

### S-06: Widget overlays use the previous frame's geometry; paint mutates state (Med, perf/maintainability, M)

**Evidence.**
- `viewport/grid_pass.dart:123-133`: the overlay pass sets `controller.lastGeometry` and calls
  `scroll.updateLimits(...)` **inside `paint()`**. `updateLimits` defers its notification to a post-frame
  callback (`grid_scroll_controller.dart:40-45`).
- These widgets rebuild on `scroll` or `overlaySignal` but read `lastGeometry` during build, which runs
  before this frame's paint, so they position with stale geometry:
  - `_AddRowsFooter` (`grid_area.dart:1249-1256`);
  - `_Scrollbars` (`grid_area.dart:1122-1131`, which needs a
    `addPostFrameCallback(... (context as Element).markNeedsBuild())` workaround);
  - `PivotEditButton` (`pivot/ui/pivot_edit_button.dart:21-24`);
  - `SplitSeparatorChip` (`data_tools/data_tools_overlay.dart:175-177`);
  - collab cards (`collab/collab_overlay.dart:185`).
- `CellEditorOverlay` (`cell_editor_overlay.dart:57`) and `objects_layer.dart:210` compute fresh geometry
  with `geometryFor`. Two conventions coexist, and `geometryFor` builds a new `GridGeometry` 3–4 times per
  frame.

**Why it matters.** Floating buttons, chips and cards lag the grid by one frame while scrolling or zooming
(they "swim"). Writing state during paint is fragile: it depends on paint order and breaks if a pass is
skipped. A post-frame `markNeedsBuild` on an arbitrary element is a workaround, not a design.

**Recommendation.** Compute geometry once per frame in one place: a `GridViewport` `ChangeNotifier` updated
from layout (`performLayout` of a small render object, or a `LayoutBuilder`) and from scroll, zoom and model
changes. Both passes and all widgets read it. Move `updateLimits` into layout. Remove `lastGeometry` writes
from `paint`.

### S-07: A cursor change calls `setState` on `GridArea`, repainting both passes (Med, perf, S)

**Evidence.**
- `grid_area.dart:928-930`: `_setCursor` calls `setState` on the whole `_GridAreaState`. The cursor changes
  over header boundaries, the fill handle, selection borders, freeze bars and plug-in hit handlers
  (888-926), and during move-drags (623-625).
- `build` (1001-1108) creates new layer lists and a new `Listenable.merge(...)` for both `GridPass` widgets
  on every build. `RenderGridPass.layers=` always calls `markNeedsPaint` (`grid_pass.dart:75-78`), and the new
  `repaint` identity re-subscribes listeners (80-89). `GridSemantics`, `CellEditorOverlay`, `_Scrollbars`,
  `_AddRowsFooter` and the hook overlays rebuild as well.

**Why it matters.** Moving the mouse across a column boundary, or onto the fill handle, triggers a full
repaint of the content pass, which is the expensive one.

**Recommendation.** Put the cursor in a `ValueNotifier<MouseCursor>` read by a small `ValueListenableBuilder`
around `MouseRegion`. Memoize the sorted layer lists and the merged listenables, and rebuild them only when
`c.layers` notifies. Make the `layers` setter compare lists before marking.

### S-08: `PointerCancel` commits drags (Med, bug, S)

**Evidence.** `grid_area.dart:1035`: `onPointerCancel: _onUp`. `_onUp` (672-754) commits the pending drag:
`sheets.fill.series`, `sheets.cells.moveRange`, `sheets.cols/rows.move`, resize, freeze and paint format.

**Why it matters.** The OS or browser cancels a gesture when focus is lost mid-drag, a touch is interrupted,
or a system gesture takes over. A cancelled gesture should abort, but here it writes a fill or move to the
document. (The write is undoable, but unexpected.)

**Recommendation.** Add `_onCancel`: reset `_drag`, clear `c.drag.value`, stop auto-scroll and restore the
cursor, without invoking commands. Add a widget test with `gesture.cancel()`.

### S-09: The global rich-text layout cache ignores the theme (Med, bug, S)

**Evidence.**
- `features/formatting/rich_text_paint.dart:17-61, 254`: `richTextLayouts` is a **process-global** LRU of
  2,000 entries. Its key is `(rich, base, pxPerPoint, linkColor, conditional, wrapWidth, chipText)`. The
  `resolveColor` callback, `ctx.model.theme.resolveColor`, is used to build the paragraph (line 91: run text
  colours such as `theme:accent1`) but is **not part of the key**.
- The cache is cleared only when fonts load (`formatting_features.dart:77-80`), not on theme change or
  theme preview.

**Why it matters.** Rich-text runs coloured with theme colours keep their old colour after Format › Theme,
during a theme preview, and across spreadsheets with different themes, until LRU eviction. **(Likely; check
in the app by applying a theme colour to part of a cell's text, then switching theme.)**

**Recommendation.**
- Add a theme generation (or the resolved run colours) to the key, or clear `richTextLayouts` on theme and
  preview changes.
- Make the cache per editor, like `TextLayoutCache`, to remove cross-document state.

### S-10: `type_in_cell` records agent writes as `ui` and discards the user's edit (Med, bug/compliance, S)

**Evidence.**
- `mcp/ui_sheets_tools.dart:36-39`: the doc comment says writes go through commands "(source `mcp`)". But
  `typeInCell` (586-629) commits through `ed.editor.commit()`, which calls `host.invokeCommand(...)` with the
  default `InvocationSource.ui` (`cell_editor/cell_editor_controller.dart:479-497`,
  `sheet_editor_controller.dart:417-421`). The undo label therefore lacks the agent prefix
  (`command_dispatcher.dart:178-180`), and any agent-specific gating that keys on `source.isAgent` is
  skipped.
- `_beginAt` (538-569) calls `ed.editor.cancel()` when the user is already editing, which silently drops the
  user's typed text.

**Recommendation.**
- Pass an `InvocationSource` through `CellEditorController.commit` and use `InvocationSource.mcp` from the
  bridge.
- Refuse the tool with `busy` while the user is editing, or commit the user's text first, as Google Sheets
  does.

### S-11: God files and classes (Med, maintainability, L)

Largest hand-written files (generated `l10n/gen/*` excluded: 14,416 and 8,322 lines). Each entry gives line
count, then the problem, then a recommended split.

| File | Lines | Problem | Split recommendation |
|------|------:|---------|----------------------|
| `features/charts/editor/chart_editor_panel.dart` | 1,962 | `_ChartEditorPanelState` is about 1,800 lines (65-1869) | `ChartSetupTab`, one widget per Customize section (title, legend, axes, series, trendlines and error bars, pie, 3D), and a `ChartEditorDraft` controller for field state and coalesced writes |
| `features/conditional_format/cf_panel.dart` | 1,492 | `_CfPanelState` is about 1,080 lines (41-1124) | Rule list, condition editor, style editor and colour-scale editor as widgets. Move draft and validation state into a `CfPanelState` controller, like the existing `DvPanelState` and `ProtectionPanelState` |
| `features/scripts/script_service.dart` | 1,460 | One `ChangeNotifier` (67-1431) owns build loading and bytecode cache, sessions and runs, triggers, drafts and local history, save, authorization, compile and execution reporting | `ScriptBuildManager`, `ScriptRunner` (plus a trigger dispatcher), `ScriptDraftStore`, `ScriptAuthorization`, `ExecutionReporter` |
| `features/scripts/editor/script_editor_screen.dart` | 1,458 | One State, about 1,390 lines | File list, editor pane, toolbar, compare/merge view, history view, presence |
| `features/import/import_dialog.dart` | 1,311 | One State | Source tabs (Upload, Recent, Drive), CSV options form, location picker, preview |
| `features/grid/grid_area.dart` | 1,290 | About 900 lines of pointer state machine inside the widget State | `GridPointerController` (drag enum, hit regions, auto-scroll) testable without widgets; move `_Scrollbars` and `_AddRowsFooter` to their own files |
| `features/data_validation/dv_panel.dart` | 1,290 | `_RuleEditorState` is about 670 lines (458-1125) | One editor per criteria family (list, number/date, text, checkbox, custom formula) |
| `features/pivot/pivot_overlay_service.dart` | 1,272 | Overlay service plus isolate/time-slicing plus incremental deltas | Split the compute scheduling (isolate or time-sliced) from the overlay index |
| `features/objects/objects_layer.dart` | 1,141 | `_ObjectsOverlayState` (152-743) holds drag, resize and snap logic in the widget | `ObjectDragController` plus painter widgets |
| `features/print/print_page_painter.dart` | 1,083 | Third cell renderer (grid, print preview, core PDF) | Accepted because it mirrors the PDF exactly; document that, and share border and checkbox geometry helpers with `content_layers.dart` |
| `features/sheet_editor/sheet_editor_controller.dart` | 1,031 | State, writes, navigation, cell queries and MCP describe in one class | Extract `GridNavigator` (`moveActive`, `enterMove`, `tabMove`, `page`, `jumpTo`, `goTo`, `_cycle`, 616-889) and `CellQueries` (`editableText`, `activeFormat`, `activeDisplay`, 891-982) |
| `mcp/ui_sheets_tools.dart` | 930 | 15 tool handlers plus the screenshot renderer | One file per tool group (selection and navigation, panels, editing, screenshot) |

Commands are also large (`commands/` has 13,255 lines, the biggest file being `object_commands.dart` at 872)
but are already split by area.

### S-12: Code duplicated with Slides/Write that belongs in `wonky_app` (Med, maintainability, M)

**Evidence.**
- **Invoke-with-toasts** exists three times with different error policies:
  - `features/toolbar/command_ui.dart:132-162` (`invoke`);
  - `features/sheet_editor/sheet_editor_controller.dart:417-444` (`invokeCommand`, an identical body);
  - `wonky_slides/lib/features/toolbar/command_ui.dart` (`SlidesCommandUi.run`, which also suppresses toasts
    for agents).
- **`CommandUi` vs `SlidesCommandUi`**: `button`, `toggle`, `item`, `state`, `title` and `shortcut` are
  near-identical (Sheets 162 lines, Slides 145). Only the key prefix and the l10n getter differ.
- **Find bar**: `wonky_sheets/lib/features/find/find_bar.dart` (220) vs
  `wonky_slides/lib/features/find/find_bar.dart` (232): same structure (status text, ↑/↓, Find and replace,
  ✕, Enter/Shift+Enter/Esc).
- **Conflict review dialog** (`features/history/conflict_review_dialog.dart`, 112 vs 117 in Slides) and
  **comment anchor moves** (`features/comments/comment_anchor_moves.dart`, 148 vs 111): the same shape with
  domain-specific labels.

**Recommendation.**
- Add `ShellServices.invokeWithToasts(id, args, source, context)` to `wonky_app`, with one policy (no toasts
  for agent sources).
- Add a generic `CommandUi(prefix:, l10n:)` in `wonky_app`.
- Add `WonkyFindBar` driven by a small `FindBarModel` interface.
- Add a generic `ConflictReviewDialog<T>` that takes `where(T)` and `value(T)` builders.

### S-13: Per-editor services: lifecycle and ownership are inconsistent (Low, maintainability, S)

**Evidence.** About 18 `X.of(editor)` lazy singletons (`grep "static .* of(SheetEditorController"`) use three
lifecycles:
- `editor.extension` plus `editor.onDispose`: `ScriptService`, `MacroService`, `DvPanelState`;
- a static `Expando` disposed by a widget: `ObjectsController`, disposed in `SheetObjectsHost.dispose`
  (`objects/objects_layer.dart:84-87`), which resets `_registry[editor] = null`
  (`objects_controller.dart:444`);
- never disposed: `SheetsImageService` (`images/image_service.dart:173-178`, which holds a `ValueNotifier`
  and up to 100 MB of decoded images until GC).

A command or MCP call after the host widget is gone (for example during the `WorkbookReady` →
`WorkbookUnavailable` → `WorkbookReady` cycle when access is removed and restored,
`sync/synced_workbook_session.dart:515-549`) re-creates an `ObjectsController` that subscribes to the model,
engine and remote streams and is never disposed. `GridHooks.hover` and `.overlays`
(`grid/paint/grid_layer.dart:318-323`) are never disposed in `SheetEditorController.dispose` (1006-1030).

**Recommendation.** Use one rule: every per-editor service is created through `editor.extension` and
registers `editor.onDispose`. Widgets never dispose shared controllers.

### S-14: Placeholder commands for features that shared packages now provide (Low, maintainability, S–M)

`commands/data_commands.dart:261-328` registers disabled placeholders, including `sheets.insert.emoji` and
`sheets.tools.spellCheck` / `personalDictionary`. `packages/wonky_app/lib/{emoji,spellcheck,special_chars}.dart`
now provide these, and Write and Slides use them. Wire them into the cell editor, or at least track this in
TODO.md. The other placeholders (drawing, convert to table, RTL, copy to …) are compiled-in dead menu
entries. They are intentional (STATUS "Editor UI"), but keep a list of them in STATUS so they don't rot.

### S-15: Overlay repaints redo work (Low, perf, S)

- `grid/paint/layers/overlay_layers.dart:44-57`: `ReferenceBoxLayer` re-parses the edited formula with
  `FormulaHighlighter.references` on every overlay repaint. While editing, the overlay repaints on every
  scroll frame and, with ants, about 30 times a second (`grid_area.dart:91-95`). Cache it per
  `(text, locale)`.
- `content_layers.dart:274-281`: with `showFormulas`, each formula cell calls `editableText()` and so
  `hooks.toA1(...)` on every content paint, uncached.
- `content_layers.dart:170-183`: each visible row allocates a `Set<int>` and walks all of the row's stored
  cells for overflow candidates on every frame. That is acceptable, but it belongs in a tile cache or a
  cache keyed by model version.

### S-16: Swallowed exceptions and exception-as-control-flow (Low, DX, S)

- 62 `catch (_)` sites. Most guard parsers, but some hide real failures:
  - `charts/view/chart_view.dart:121` and `collab/presence/sheets_presence_controller.dart:362` wrap
    `SheetsUserDefaults.of(...)` in `catch (_) {}` (presumably for tests without prefs);
  - `cell_editor_controller.dart:362-372` throws a private `_Off()` purely to jump into the `catch` that
    clears `signature`.
- 63 `debugPrint` or `kDebugMode` uses. Errors such as anchor maintenance
  (`objects/objects_controller.dart:373-377`) go only to the console, with no observability hook (spec 11).

Make `SheetsUserDefaults.of` total, with defaults when it isn't installed. Replace `_Off` with an `if`. Route
unexpected failures through a shared error reporter.

### S-17: Hard-coded English labels (Low, i18n, S)

- 24 `label: 'English…'` plan and undo labels: `commands/cell_commands.dart:110,178` ("Typing"),
  `image_commands.dart:373,479`, `ai_commands.dart:330`, `history/sheets_version_view.dart:65`,
  `history/version_copy.dart:52`, `scripts/settings_dialog.dart:30`, `triggers_dialog.dart:154,184`,
  `objects/objects_controller.dart:374`.
- The user-visible `WorkbookUnavailable('You no longer have access to this spreadsheet.')` reason
  (`sync/synced_workbook_session.dart:517-519`) is shown as the empty-state description.
- `chart_controller.dart:287` has a `'… chart'` fallback.

If these labels reach the change log, cell history or version UI, they show in English. Use l10n keys or
stable codes that are localised at display time.

### S-18: Semantics tree rebuilt on every scroll frame (Low, a11y/perf, S)

`grid/a11y/grid_semantics.dart:174-345`: while semantics is on, `assembleSemanticsNode` rebuilds up to 2,500
cell nodes with `describeCell` labels on every scroll tick, content signal and selection change. Screen-reader
users get the slowest scrolling. Debounce scroll-driven updates to the end of the fling, or about 100 ms.
Update only labels whose cells changed (key by `(rowId, colId)` plus the cache version).

### S-19: Stale project docs (Low, DX, S)

`AGENTS.md` says the Sheets "scripting engine is done but its UI is not". STATUS.md, the code
(`features/scripts/editor/script_editor_screen.dart`, `script_panels.dart`, triggers and executions panels)
and 65 app script tests show the UI is built. Update AGENTS.md. Also, spec 03 §2.2/§2.3 describes
`GridGeometry` as a shared `ChangeNotifier` used in `performLayout`, and the "as built" notes don't mention
the per-paint construction (see S-06).

---

## Testing gaps

| ID | Gap | Evidence | Suggested tests |
|----|-----|----------|-----------------|
| T-01 | No grid goldens. Only chart goldens exist (`test/goldens/charts`). `grid_paint_test.dart` (3 tests) checks that painting completes, not pixels | `test/goldens/`, `test/features/grid/grid_paint_test.dart:72-116` | Goldens (light and dark) for borders including double/dashed, overflow and `####`, merges across frozen panes, rotation, chips and checkboxes, CF data bars and icons, filtered or sorted view headers |
| T-02 | Touch, pointer cancel and the mobile grid are untested | no `PointerDeviceKind.touch` or `cancel` in `test/features/grid` | Covers S-01 and S-08 |
| T-03 | Concurrency of async commands vs user edits | none | Covers S-02 |
| T-04 | Toolbar, status bar and selection stats have no direct tests (`SheetsToolbar` mentioned in 1 file, `SelectionStats` in none) | `features/toolbar` (826 lines), `features/status` (376) | Toolbar state reflects the active format; stats on multi-range or large selections; stats don't evict the render cache (S-03) |
| T-05 | Render-cache and text-cache invalidation are untested (`CellRenderCache`, `TextLayoutCache`, `richTextLayouts`) | grep finds 0 test files | Theme change recolours rich runs (S-09); range invalidation once S-05 lands |
| T-06 | Light coverage of big UI modules: CF panel UI (2 mentions; commands are covered), slicers (3), explore (4), clipboard service (1 direct), groups (commands only) | feature/test mapping | Widget tests for the CF panel draft → Done → one undo step; slicer panel filters; system clipboard paste paths |
| T-07 | Load-state transitions (Ready → Unavailable → Ready) don't remount the editor stack | none | Covers S-13: re-share while open, then use objects and charts |
| T-08 | Perf test only covers scrolling in debug VM (`grid_performance_test.dart`, `-t slow`) | `test/features/grid/grid_performance_test.dart:13` | Add an edit-while-scrolling and selection-drag benchmark (S-04, S-05); run a release-mode profile in CI or by hand |

---

## Things done well

- **Rendering architecture.** No widget per cell: two leaf `RenderBox` passes, each a repaint boundary,
  separate content (cells) from overlay (selection, headers), so selection changes don't repaint cells
  (`grid_pass.dart`, `grid_area.dart:1041-1073`). Geometry uses Fenwick prefix sums, O(log n)
  (`grid_geometry.dart`). Frozen panes are clipped quadrants with a shared pane API. Sorted filter views
  reuse the same pane abstraction.
- **Bounded caches.** `CellRenderCache` caps at 60k entries per sheet. `TextLayoutCache` is an LRU of 20k
  entries that **disposes** evicted `ui.Paragraph`s. The empty-cell fast path skips resolution
  (`cell_render_cache.dart:440-461`).
- **Plug-in layers and hooks** (`GridLayer`, `GridHitHandler`, `GridHooks`). Features such as CF, presence,
  filters, AI highlights and loading skeletons add behaviour without editing the core painter.
- **Command discipline is strong.** Panels, popovers and dialogs write through `invoke` or `ui.run`. Writes
  go through `SheetEditorController.apply`, which runs `writeGates` and records one `sheets.rows` undo entry
  per plan. Direct `session.execute` is limited to documented exceptions (script source saves, idempotent
  anchor maintenance). Gates refuse writes into loading rows, pivots and protected ranges.
- **Viewport-first loading** with a skeleton layer, a write gate and `#LOADING` formulas
  (`loading_layer.dart`, `loading_formula_source.dart`).
- **Per-editor services** use `Expando` or `editor.extension`, so they are collected with the editor.
- **Accessibility.** A semantics table is built only when semantics is on, capped at 2,500 cells, with a
  debounced `SelectionAnnouncer`.
- **Tests.** 125 test files with consistent Given/When/Then names, command-level tests for most areas, and a
  1M-cell scroll performance test. There are no `TODO`/`FIXME` comments in `lib/`, and analyzer hygiene is
  maintained per STATUS.
