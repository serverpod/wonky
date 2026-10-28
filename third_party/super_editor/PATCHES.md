# Patches to super_editor

Every change is marked with `// WONKY PATCH <id>` in the code. Tests of our patches live in
`test/wonky_patches/` (run with the package's own suite: `flutter test -x golden`).

## SE-1 — Complete Quill serialization

- **Reason**: upstream `toQuillDeltas` threw on `HorizontalRuleNode`/`TableBlockNode`, dropped inline
  `code`, list/task `indent` and the code-block language, and always treated a final empty
  paragraph as the document's trailing newline. The Write mapper serializes through
  `toQuillDeltas` (with its own Wonky `DeltaSerializer`), and tests compare Deltas with
  `quillDocumentEquivalentTo`.
- **Changes**:
  - `toQuillDeltas(omitTrailingEmptyParagraph:)` (default `true` = upstream behavior).
  - Serializers: `horizontalRuleDeltaSerializer` (`{"divider": true}`, configurable embed builder),
    `tableDeltaSerializer` (`{"table": {"align": [...], "rows": [[inline Markdown]]}}`),
    `bitmapImageDeltaSerializer` (data URI); all in `defaultDeltaSerializers`.
  - Inline `code` → `{"code": true}`; list/task `indent`; `code-block` value from node metadata
    `codeLanguageMetadataKey` (`"plain"` when unset).
  - Parsing: code-block language → metadata; list/task `indent`; `HorizontalRuleEmbedBlockDeltaFormat`,
    `TableEmbedBlockDeltaFormat` in `defaultEmbedBockFormats`.
- **Files**: `lib/src/infrastructure/serialization/quill/serializing/{serializing,serializers}.dart`,
  `lib/src/infrastructure/serialization/quill/parsing/{block_formats,parser}.dart`
- **Tests**: `test/wonky_patches/se1_quill_serialization_test.dart`
- **Spec**: Write 02 §4, Write 04 §2.2
- **Upstream**: generally useful; to be proposed upstream (serializer additions are backwards compatible).

## SE-2 — Incremental, composer-free document patches

- **Reason**: collaborators' changes (and undo/AI/MCP changes) must be applied to the live
  document without going through the composer, without moving the local caret, and without
  being recorded as local edits or triggering autoformat reactions.
- **Changes**:
  - `ApplyDocumentPatchRequest` / `ApplyDocumentPatchCommand` (new file
    `lib/src/default_editor/document_patch.dart`): ordered node operations (`ReplaceNodePatch`,
    `InsertNodePatch`, `DeleteNodePatch`, `MoveNodePatch`), optional transformed selection and
    composing region (reason `contentChange`), optional IME resync, `HistoryBehavior.nonHistorical`,
    a `DocumentPatchAppliedEvent(tag)` marker event; registered in `defaultRequestHandlers`.
  - `Editor`: transactions containing a `ReactionSuppressingEvent` (the patch marker, unless
    `runReactions: true`) notify listeners but skip the reaction pipeline (`core/editor.dart`).
  - Design note: the Quill-Delta → node mapping stays in the app (`DeltaApplier`), because it
    depends on the Wonky schema; the library provides the generic primitive.
- **Files**: `lib/src/default_editor/document_patch.dart`, `lib/src/core/editor.dart`,
  `lib/src/default_editor/default_document_editor.dart`, `lib/super_editor.dart`
- **Tests**: `test/wonky_patches/se2_document_patch_test.dart`
- **Spec**: Write 03 §3, Write 04 §2.2
- **Upstream**: generally useful (collaborative editing); to be proposed.

## SE-3 — Detailed change events

- **Reason**: block-level changes were reported as bare `NodeChangeEvent`s.
- **Changes**: new `NodeChangeEvent` subclasses (backwards compatible) in
  `lib/src/default_editor/node_change_events.dart`: `BlockTypeChangeEvent`,
  `ListItemTypeChangeEvent`, `IndentChangeEvent`, `TaskCompletionChangeEvent`,
  `NodeMetadataChangeEvent`, `NodeReplacedEvent`; emitted by `ChangeParagraphBlockTypeCommand`,
  `ChangeParagraphAlignmentCommand`, paragraph/list/task (un)indent commands,
  `ChangeListItemTypeCommand`, `ChangeTaskCompletionCommand`, the paragraph ⇄ list/task
  conversions and `ConvertTextNodeToParagraphCommand`. New `ChangeNodeMetadataRequest`.
- **Files**: `node_change_events.dart`, `paragraph.dart`, `list_items.dart`, `tasks.dart`, `text.dart`,
  `default_document_editor.dart`
- **Tests**: `test/wonky_patches/se3_node_change_events_test.dart`
- **Spec**: Write 02 §4.4
- **Upstream**: to be proposed.

## SE-4 — Editable tables (cell content builder)

- **Reason**: Write edits table cells in place (Write 04 §18.4). The table stays one block node
  (the document caret never enters it, the `table` embed schema is unchanged); the app turns the
  tapped cell into an editor of the cell's inline Markdown and applies each edit as a node
  replacement (`write.table.replace` semantics, one undo step). Upstream cells are read-only and
  ignore pointer events.
- **Changes**:
  - `MarkdownTableComponent(cellBuilder:)` with `TableCellContentBuilder` /
    `TableCellBuildContext` (`tableNodeId`, `rowIndex`, `columnIndex`, styled `cell` view model,
    `defaultContent`, `isHeader`). Returning `null` keeps the default text.
  - With a cell builder the table is not wrapped in `IgnorePointer`/`SelectableBox`, so cells take
    taps and text input; the block-selection highlight is painted directly.
  - `TableComponentFit.scale` no longer builds the table (and every cell) twice.
- **Files**: `lib/src/default_editor/tables/table_markdown.dart`
- **Tests**: `test/wonky_patches/se4_table_cell_builder_test.dart`; app side
  `wonky_write/test/features/editor/ui/editor_extras_test.dart`
- **Spec**: Write 04 §2.2, §18.4
- **Upstream**: generally useful (custom/editable cells); to be proposed. Caret positions inside
  cells (a `TableCellPosition`) remain a possible later step.

## SE-5 — Fixes found by our tests

1. **List indent limit**: `IndentListItemCommand` stopped at level 6; now `maxListItemIndent = 8`
   (Write's 9 levels). `list_items.dart`.
2. **List type change lost indent/metadata**: `ChangeListItemTypeCommand` rebuilt the node from
   scratch; now copies it. `list_items.dart`.
3. **IME resync**: `MutableDocumentComposer.requestImeResync()` re-notifies selection listeners
   (inside a transaction: at its end) so the IME is re-sent text changed around the caret by a
   patch. `core/document_composer.dart`.
4. **Typing over a selection**: `InsertCharacterAtCaretCommand` inserted the character at the stale
   (pre-deletion) extent, i.e. after the deleted range; now uses the selection after deletion.
   `default_editor/text.dart`.
5. **Undo/redo keyboard actions exported** (`lib/src/undo_redo.dart`) so apps can remove them from
   the default keyboard action lists. `lib/super_editor.dart`.
6. **Right-to-left task checkbox**: its padding (16 before, 4 after) was fixed left/right, so a
   right-to-left task had 4 px between the checkbox and its text; now `EdgeInsetsDirectional`
   (the row is in the task's `Directionality`). `default_editor/tasks.dart`.
7. **Right-to-left line start and end**: `TextComponent.getPositionAtStartOfLine` /
   `getPositionAtEndOfLine` took super_text_layout's positions at the line's left and right
   edges, so in right-to-left text ⌘←/⌘→ (and Home/End) went to the wrong end, and the
   auto-wrap adjustment made the line end offset −1. Swapped for right-to-left components.
   `default_editor/text.dart`.

- **Tests**: `test/wonky_patches/se5_fixes_test.dart`, `se3_node_change_events_test.dart`,
  `se2_document_patch_test.dart`
- **Upstream**: 1–7 are general fixes; to be filed upstream.

## SE-6 — Content drag delegate (drag and drop of the selection)

- **Reason**: dragging selected text must move it (Write 04 §24), but `DocumentMouseInteractor`
  always turned a pan into a new drag selection.
- **Changes**: `ContentDragDelegate` / `ContentDragDetails` (new file
  `lib/src/default_editor/content_drag.dart`); `SuperEditor(contentDragDelegate:)` →
  `DocumentMouseInteractor`. On pan start (from the pointer-down position, not with Shift) the
  delegate may claim the drag; it then gets updates (also while auto-scrolling near the viewport
  edges), end and cancel, and the selection is left alone. Mouse gesture mode only.
- **Files**: `content_drag.dart`, `document_gestures_mouse.dart`, `super_editor.dart`,
  `lib/super_editor.dart`
- **Tests**: `test/wonky_patches/se6_content_drag_test.dart`
- **Spec**: Write 04 §24
- **Upstream**: generally useful; to be proposed.

## SE-7 — List markers don't inherit text highlights

- **Reason**: the default bullet and numeral builders style the marker with the first
  character's attributions, so a comment highlight or suggestion background/strikethrough on the
  start of a list item also painted a thin highlighted sliver on the bullet (or the "1.").
- **Changes**: `_markerStyle` keeps the font, size, weight, color and metrics of that style but
  drops `background`/`backgroundColor` and decorations.
- **Files**: `lib/src/default_editor/list_items.dart`
- **Tests**: `test/wonky_patches/se7_list_marker_style_test.dart`
- **Spec**: Write 08 §3.1
- **Upstream**: generally useful; to be proposed.

## SE-8 — Selection highlight without overlapping bands

- **Reason**: super_text_layout expands every selection box by 2 px above and below and paints
  the boxes one by one in a translucent color, so the boxes of adjacent lines (and of adjacent
  styled runs) overlapped and showed as darker bands — very visible when selecting a
  syntax-highlighted code block.
- **Changes**: `NonOverlappingSelectionHighlight` / `NonOverlappingSelectionPainter` add all
  (expanded, rounded) boxes to one path and fill it once; `TextComponent` uses it instead of
  `TextLayoutSelectionHighlight`.
- **Files**: `lib/src/default_editor/selection_highlight.dart` (new), `lib/src/default_editor/text.dart`
- **Tests**: `test/wonky_patches/se8_selection_highlight_test.dart`
- **Spec**: Write 04 §15.4
- **Upstream**: generally useful (also for super_text_layout's own painter); to be proposed.

## SE-9 — Linear selection styling

- **Reason**: `SingleColumnLayoutSelectionStyler` computed the selected nodes
  (`getNodesInside`, O(n)) again for every component and searched them linearly, and built a log
  line per selected node for every component even with logging off: a selection over a whole
  100-page document took about 350 ms per style pass in the Write perf suite (CQ-42).
- **Changes**: the selected nodes (and a set of their ids) are computed once per `style` pass;
  membership is a set lookup; the per-node log loop runs only when `FINER` is logged.
- **Files**: `lib/src/default_editor/layout_single_column/_styler_user_selection.dart`
- **Tests**: the package's selection tests (behavior unchanged); timed by
  `wonky_write/test/perf/write_perf_test.dart` (select all).
- **Spec**: Write 04 §36
- **Upstream**: generally useful; to be proposed.

## SE-10 — Analyzer clean

- **Reason**: `dart analyze` reported 300 issues in this package (upstream style, Flutter API
  deprecations, test tooling in `lib/`), drowning our own diagnostics in the IDE.
- **Changes**: `dart fix` (198 fixes: package imports, const literals, unused/unnecessary imports
  and a few small lints; unmarked, mechanical); the deprecated Flutter APIs are replaced
  (`TextInputConnection.updateStyle`, `scrollCacheExtent`, `Matrix4.*ByDouble`,
  `Color.toARGB32`, `AttributedText.toPlainText(includePlaceholders: false)` in tests), except
  the iOS `SystemContextMenuController.show`, kept with an `ignore` (its replacement needs the
  items of an `EditableTextState`); the golden helpers moved from `lib/` to
  `test/test_tools_goldens.dart` (they import the dev dependency `golden_toolkit`, CQ-45); the
  test tooling in `lib/src/test/` ignores `invalid_use_of_visible_for_testing_member` /
  `invalid_use_of_protected_member` per file (it inspects test-only state by design); the IME
  reads the `@protected` `childDocumentComponentKey` with an `ignore`; unused members, a stale
  `@override` and the pub.dev `screenshots:` (images not vendored) are removed.
- **Files**: 80+ files under `lib/` and `test/`, `pubspec.yaml`
- **Tests**: the package's suite; CI's `third-party` job runs `dart analyze --fatal-infos` for
  both vendored packages.
- **Upstream**: the API migrations are generally useful; the rest is local.

## SE-11 — The caret is as tall as the text beside it

- **Reason**: the caret spanned the whole line box. With a line height above 1 (every Write
  theme) the box includes the leading, which Flutter's proportional distribution puts mostly
  above the text, and a taller run on the line (Wonky Markdown chips and buttons use 1.8 and
  2.3) stretches it further: the caret rose above the text, most visibly at the end of lines.
- **Changes**: `TextComponentState.getEdgeForPosition` (the caret's geometry) is 1.2 em of the
  font size of the character before the position (else the one after it, when that character is
  on the caret's line), placed where that character's run puts its glyphs: Flutter's character
  boxes include the run's line height (and the last character's box spans the line), so the
  caret takes the run's box (`fontSize × height`, at most the character's box) and the glyphs
  in it (four fifths of the leading above, Flutter's split for common fonts). It is as tall and
  on the same baseline in plain text, inside a chip or button and at the end of a line. On an
  empty line the same within the line box, from the paragraph's style. `getRectForPosition` is
  unchanged (scrolling, anchors). Not on Android and iOS, whose drag handles and magnifier are
  placed from the line rectangle (upstream behavior there). Write's remote carets use the same
  edge.
- **Files**: `lib/src/default_editor/text.dart`; tests:
  `test/wonky_patches/se11_caret_height_test.dart` (new),
  `test/super_editor/supereditor_caret_test.dart` (the expected caret is the edge).
- **Tests**: the files above.
- **Spec**: Write 04 §5 (caret)
- **Upstream**: generally useful; to be proposed.

## SE-12 — The app can move the caret

- **Reason**: Wonky Markdown chips and buttons get room for their pill's right padding from the
  letter spacing of their last character, so a caret at the end of one, still inside it (typed
  text extends it), sat after that gap and looked outside the pill. Write draws it right after
  the last glyph instead; only the app knows the inside/outside state.
- **Changes**: `CaretDocumentOverlay` and `DefaultCaretOverlayBuilder` take an optional
  `adjustCaretRect(position, rect, layout)`, applied to the caret of a collapsed selection, and a
  `caretRectListenable` that repositions the caret when the adjustment changes (the selection
  doesn't).
- **Files**: `lib/src/default_editor/document_caret_overlay.dart`,
  `lib/src/default_editor/super_editor.dart`; test: `test/wonky_patches/se12_caret_adjust_test.dart`
  (new).
- **Tests**: the file above.
- **Spec**: Write 11 §7.4
- **Upstream**: local (small, generic hook).

## SE-13 — A click splits a character at its glyph's middle

- **Reason**: Flutter splits a character's box at its middle to choose the caret position before
  or after it, and the box includes the letter spacing after the glyph. Wonky Markdown gives the
  last character of a chip, button or arrow link (and spaces next to pills) a wide spacing for
  the pill's padding or the arrow, so a click on the right half of that glyph, or on the arrow,
  put the caret before the character: the hit box seemed shifted to the right.
- **Changes**: `TextComponentState.getPositionAtOffset` (every click, drag and drop position)
  moves a position to after the character when the point is on that character's box, right of
  the middle of its glyph (the box without the style's `letterSpacing`); upstream affinity when
  the line wraps after it. Left-to-right text only.
- **Files**: `lib/src/default_editor/text.dart`; test: `test/wonky_patches/se13_glyph_hit_test.dart`
  (new).
- **Tests**: the file above.
- **Spec**: Write 11 §7.4
- **Upstream**: generally useful (any letter spacing); to be proposed.

## SE-14 — Content can opt out of the editor's gestures

- **Reason**: the mouse interactor wraps the document, so its tap and pan recognizers also fire
  for content that handles clicks itself. Write's in-place fields (grid items, table cells) got
  each click twice: the editor requested its focus (out of the field) and put its caret before
  or after the block, while the item started editing or placed the field's caret. In the
  browser this showed as the caret jumping before the grid or table; widget tests don't show it
  (there the field's recognizer wins).
- **Changes**: a `DocumentGestureOptOut` widget (a `MetaData` marker) and, in
  `DocumentMouseInteractor`, a hit test at pointer down: a gesture that starts on opted-out
  content is ignored entirely (tap up, double and triple tap, pan: no focus request, caret,
  selection or drag selection). Mouse interactor only (desktop and web).
- **Files**: `lib/src/default_editor/document_gestures_mouse.dart`; test:
  `test/wonky_patches/se14_gesture_opt_out_test.dart` (new).
- **Tests**: the file above.
- **Spec**: Write 04 §18.4, Write 11 §7.4
- **Upstream**: generally useful (embedded interactive content); to be proposed.

## SE-15 — Cell groups lay out components side by side

- **Reason**: Wonky Write makes every table cell and grid item an ordinary `ParagraphNode`
  (native document text instead of overlay text fields), so the single-column layout must place
  those components in 2D: table rows and flowing grids.
- **Changes**:
  - New public API (`layout_single_column/_cell_layout.dart`): `DocumentCellLayout` (supplied by
    the app, a `Listenable`: `placementOf(nodeId)`, `wrapGroup`, `paintGroup`),
    `DocumentCellPlacement.rows(group, row, column, minColumnWidth = 64, gap, spaceBefore)` /
    `.flow(group, index, maxColumns, minColumnWidth = 160, gap, spaceBefore)`,
    `DocumentCellGroupKind`, `DocumentCellGroup` (id, kind, node ids in document order),
    `DocumentCellGroupGeometry` (size, row/column counts, `columnEdges`, `rowEdges`, `rowBottoms`,
    `slotRects` per node) and the render widget `DocumentCellGroupView` /
    `RenderDocumentCellGroup`. The group-wide values (`minColumnWidth`, `gap`, `maxColumns`) come
    from the group's first placement.
  - `SingleColumnDocumentLayout(cellLayout:)`: maximal runs of consecutive components whose
    placements share a group id become one `DocumentCellGroupView` (wrapped by `wrapGroup`) in
    the column; components keep their keys and presenter builders. Rebuilds when the cell layout
    notifies (after the frame when it notifies during build/layout) or is replaced.
  - Rows: columns share the width equally (minus gaps), never narrower than `minColumnWidth`
    (they overflow); a row is as tall as its tallest cell; missing cells are empty space; the
    largest `spaceBefore` of a row is added above it (outside the row's edges and slots). Flow:
    the column count drops from `maxColumns` while columns would be narrower than
    `minColumnWidth` (a single column takes the available width); items fill rows in index
    order. `paintGroup` paints behind the cells; dry layout and intrinsics are supported.
  - 2D geometry: a point in a cell's slot outside its component (below a short cell, padding)
    resolves to that cell (`getDocumentPositionAtOffset`, `getDesiredCursorAtOffset`); the
    nearest component beside a group is the cell with the nearest slot (2D distance; ordinary
    components keep the vertical distance, they span the width); the start/end-of-content checks
    use the group's bounds; the binary search used by region selection treats a group as one
    block and starts at its first cell, and a cell that doesn't overlap the region no longer
    ends the search; a region end inside a group resolves to the cell at that point (so a drag
    from a later cell of a row starts there).
  - `SuperEditor(cellLayout:)`, `SuperReader(cellLayout:)` → `DocumentScaffold` → layout.
    Keyboard caret movement (document order) is unchanged.
  - A group is no wider than its first component's `maxWidth` (like `_Component`).
  - `DocumentCellPlacement(textDirection:)` (group-wide): right to left, column 0 (rows) and
    the first item (flows) are on the right. `columnEdges` still run left to right (visual
    columns); `slotRects`, hit testing and region selection follow the mirrored slots.
- **Files**: `lib/src/default_editor/layout_single_column/{_cell_layout.dart (new),_layout.dart,layout_single_column.dart}`,
  `lib/src/infrastructure/documents/document_scaffold.dart`, `lib/src/default_editor/super_editor.dart`,
  `lib/src/super_reader/super_reader.dart`; test: `test/wonky_patches/se15_cell_groups_test.dart` (new).
- **Tests**: the file above; the package's layout and selection tests.
- **Spec**: Write 12 §3.2
- **Upstream**: generally useful (tables and grids of ordinary components); to be proposed.

## Infra

- `pubspec.yaml`: `dependency_overrides: attributed_text: {path: ../attributed_text}` so the
  vendored suite runs against the vendored, patched `attributed_text` (patch AT-1).
- `pubspec.yaml`: `golden_toolkit` is a `dev_dependency` (upstream: a regular one), so its
  Roboto font no longer ships in every app's web build (CQ-45). Its only importers are
  tests (`test/test_tools_goldens.dart` since SE-10).
