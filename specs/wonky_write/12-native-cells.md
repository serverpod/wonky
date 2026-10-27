# Wonky Write — Native table and grid cells

Tables (04 §18) and Wonky Markdown grids (11 §2.2) used to be single block embeds whose cells were
inline-Markdown strings. They were edited through text fields overlaid on the rendered block (the
"in-place editing" of SE-4 and `InlineGridEditing`). Two editors then competed for focus, text
input, clicks and selection: every interaction between them needed its own workaround (tap region
groups, a gesture opt-out, a delayed presence selection, click counting, a selection hold), and
each fix exposed the next case. Collaboration was coarse: every edit replaced the whole embed, so
concurrent edits to one table overwrote each other, and comments, suggestions and remote carets
could not point inside a cell.

This spec makes every **table cell** and every **grid item** an ordinary line of the document. The
document editor's own caret, selection, typing, IME, spellcheck, inline formatting, comments,
suggestions, undo and presence work in cells exactly as elsewhere. Only layout (cells side by
side), navigation between cells and structural commands are specific to cells.

Status: **built** (branch `feat/native-table-grid-cells`). It supersedes 02 §1.3 (`table` embed),
04 §18.1–18.4 (model, in-place editing) and the grid embed of 11 §2.2, which now point here.

## 1. Document model

### 1.1 Table cells

A table is a run of consecutive lines carrying the line attribute **`cell`**:

```json
{"insert": "Name"},  {"insert": "\n", "attributes": {"cell": {"table": "t1", "row": "r1"}}},
{"insert": "Qty"},   {"insert": "\n", "attributes": {"cell": {"table": "t1", "row": "r1", "align": "right"}}},
{"insert": "Apples"},{"insert": "\n", "attributes": {"cell": {"table": "t1", "row": "r2"}}},
{"insert": "3"},     {"insert": "\n", "attributes": {"cell": {"table": "t1", "row": "r2", "align": "right"}}}
```

- `table`: the table's id (a UUIDv7 for new tables, the old embed id for upgraded ones). `row`: the
  row's id, unique within the table (8 random base-36 characters). `align`: `left`, `center` or
  `right`; absent means default. Nothing else.
- **Order is the structure.** A table is a maximal run of consecutive lines with the same `table`
  id. A row is a maximal run of consecutive lines of that table with the same `row` id. Columns are
  positional: the k-th line of a row is in column k. Row 0 is the header row (GFM semantics).
- A table's **column count** is the length of its longest row. A shorter row ("ragged", possible
  after concurrent structural edits, §5.3) renders its missing cells as empty, non-editable
  placeholders; every structural command first completes ragged rows (§3.6).
- A column's alignment is the `align` of its header cell; commands set it on every cell of the
  column (so a cell renders with the alignment it carries, and exports use the header's).
- Cell text is ordinary inline content: every inline attribute (bold, italic, code, links,
  mentions, chips, buttons, comments, suggestions) is allowed. A cell is **one line**: no soft line
  breaks (U+2028 becomes a space) and no other block attributes (`header`, `list`, `indent`,
  `blockquote`, `code-block`, `align`, `step` are removed). The only other line attribute a cell
  may carry is `box` (a table inside containers, 11 §2.1), the same on every cell of the table.

### 1.2 Grid items

A grid (Wonky Markdown only) is a run of consecutive lines carrying the line attribute **`grid`**:

```json
{"insert": "Fast"},     {"insert": "\n", "attributes": {"grid": {"id": "g1", "columns": 3, "bullets": "check"}}},
{"insert": "Reliable"}, {"insert": "\n", "attributes": {"grid": {"id": "g1", "columns": 3, "bullets": "check"}}}
```

- `id`: the grid's id. `columns`: 1–4 (canonical as in 11 §2.2: 1, 2 or 4, else 3). `bullets`:
  `check`, `circle` or `none`. Commands set the same `columns` and `bullets` on every item; when
  items disagree (a concurrent edit), the first item's values are the grid's (rendering, exports,
  `CellGrid`), and the next command on the grid makes them agree.
- A grid is a maximal run of consecutive lines with the same grid `id`; items are in line order.
  At most 100 items (`GridEmbed.maxItems`); an empty grid does not exist (its last item removed,
  the grid is gone).
- Items are one line each with inline content, like cells (§1.1), and may also carry `box`.

### 1.3 Ids

New ids come from `CellIds` in `wonky_write_core`: table and grid ids are UUIDv7, row ids 8
base-36 characters from a random source. Ids only group lines; they are not unique across the
document by construction (two pasted copies of one table would share an id), so **paste and
import regenerate** them (§3.8). Two adjacent runs that share a table id are one table; the
normalizer does not try to repair that (it cannot happen through commands).

### 1.4 Validator and normalizer

`WonkyDeltaValidator` accepts `cell` and `grid` line attributes with the shapes above and rejects
cell or grid lines that carry block attributes other than `box`. `WonkyDeltaNormalizer` (on every
change, client and server):

1. removes unknown keys inside `cell`/`grid`, invalid `align`/`bullets` values and canonicalizes
   `columns`;
2. removes block attributes other than `box` from cell and grid lines, and `cell` from a line that
   also has `grid` (a line is either);
3. replaces U+2028 in cell and grid lines with a space.

The rules are line-local, like every other normalizer rule, so normalizing a change on its lines
equals normalizing it on the whole document. Cross-line facts (equal `columns`/`bullets` on a grid's
items, equal alignment in a column, complete rows) are kept by the commands and read
leniently (first item, header cell, placeholders).

### 1.5 Legacy embeds and the upgrade

Documents written before this change hold `table` and `grid` **embeds** (02 §1.3, 11 §2.2). They
stay valid input everywhere, and `CellUpgrade` (`wonky_write_core`) converts them:

- `CellUpgrade.upgradeChange(Delta document)` returns the change that replaces every legacy
  `table`/`grid` embed line with cell or item lines (inline Markdown parsed into inline attributes,
  the embed id kept as the table/grid id, new row ids, the embed line's `box` copied to each line,
  `cmt_*`/`sug_*` of the embed dropped), or `null` when there are none.
- **Server** (`CellUpgrader`, `wonky_server/lib/src/write/ot/cell_upgrader.dart`): when a
  document's state is loaded (`DocumentCache.of`), and after every committed op whose result still
  contains a legacy embed (an old client, a restored version; `OtService.submit`), the server
  commits the upgrade as a system op (`kind: system`, a system actor, no author; "Upgrade tables"
  in the logs), so stored documents converge to the new format. Clients receive it as an ordinary
  remote op. The change is computed from the head and committed only at that head (`atHead`;
  otherwise it retries from the new head), so two upgrades never both apply; once the head holds no
  legacy embed nothing is committed. It bumps the document's revision and `updatedAt`, but adds no
  activity, version or drive "modified" entry. Readers that bypass the document cache (snapshots,
  exports, copies) see legacy embeds until the first load; they handle both forms. Comment threads
  anchored on an embed become orphaned (text deleted).
- **Client**: a legacy embed that is still in a local document (an offline cache from before the
  upgrade) renders read-only as before (`TableBlockNode`, the grid component without editing)
  until the server's upgrade op arrives. The editor never creates legacy embeds.
- **Everything else** that reads Deltas (exporters, `DocTree`, plain text, stats, history diffs,
  importers of old exports) handles both forms: `DocTreeBuilder` turns either into the same
  `TableBlock`/`GridBlock`.

### 1.6 Markdown and other formats

Nothing changes in the formats: a table is a GFM table, a grid the `:::grid` directive (11 §4).
Import produces cell/item lines; export reads them through `DocTree`. A cell's inline content is
written as inline Markdown (pipes escaped), so a cell with a comment or a mention round-trips as
its text.

## 2. DocTree

`TableBlock(id, align, rows, cellMarkdown)` and `GridBlock(id, columns, bullets, items,
itemMarkdown)` keep their shape. `DocTreeBuilder` builds them from a run of cell/item lines (rows
and columns as in §1.1; ragged rows padded with empty cells; `cellMarkdown`/`itemMarkdown` written
from the runs) or from a legacy embed. `deltaStart`/`deltaLength` span the whole run. Exporters are
unchanged apart from reading runs instead of re-parsing Markdown where they did.

## 3. Editor

### 3.1 Nodes

Each cell or item line is a `ParagraphNode` (block type paragraph) whose metadata holds the line
attribute: `WonkyNodeMetadata.cell` (`{table, row, align?}`) or `WonkyNodeMetadata.gridItem`
(`{id, columns, bullets}`), next to `box` when in containers. `DeltaNodeCodec` maps them both ways;
the mirror, `DeltaApplier` and `ChangeDeltaExtractor` need nothing else. Helpers in
`model/cells.dart` answer "which table/grid, row, column, item index" for a node and list a
table's rows (`CellTable`) or a grid's items (`CellGrid`) from the document.

### 3.2 Layout (super_editor patch SE-15)

super_editor stacks components in one column. **SE-15** adds `DocumentCellLayout`, passed to
`SuperEditor` and `SuperReader` (`cellLayout:`) and on to `SingleColumnDocumentLayout`:

```dart
abstract class DocumentCellLayout implements Listenable {
  DocumentCellPlacement? placementOf(String nodeId);   // group, row/column or flow index
  Widget wrapGroup(BuildContext context, DocumentCellGroup group, Widget child);
  void paintGroup(Canvas canvas, Offset offset, DocumentCellGroupGeometry geometry);
}
```

- Consecutive components whose placements share a `group` are laid out by one
  `DocumentCellGroupView` (a custom render object) instead of the column: either **rows** (each
  placement names its row and column) or **flow** (an index, a maximum column count and a minimum
  column width: the count drops while columns would be narrower). Columns share the width equally
  (`minColumnWidth` 64 px for tables); each row is as tall as its tallest cell and every cell is
  given that height, so borders line up. Missing cells of ragged rows are empty space.
- `paintGroup` paints behind the cells with the cell rectangles (table borders, header background);
  `wrapGroup` wraps the whole group (container frames, chrome); both come from the app.
- The layout rebuilds when `placementOf` changes (the cell layout notifies).
- Geometry stays exact: components keep their keys and render boxes, so positions, selection
  rectangles, carets and hit tests work as for any component. The patch also makes the
  "nearest component" fallback measure 2D distance (it measured only vertical distance, which
  picked the first cell of a row for a click between cells).
- Mouse and touch interactors are unchanged: clicks, double/triple clicks and drags in cells are
  the editor's.

Write's `WriteCellLayout` provides placements from the node metadata, table borders and the header
background from `TableStyles`, grid gaps from the theme, container frames around a group (the
frame segments of the group's first and last node) and the chrome (§3.7).

### 3.3 Styling

`CellStylePhase` (after the stylesheet, before pagination) gives cell and item view models their
padding (table cells: `TableStyles.cellPadding`; grid items: the grid gap), the header row a bold
text style, a cell its `align` as text alignment, and removes block spacing. Grid items render
their bullet before the text (`GridItemComponentBuilder`). Containers no longer frame cell
components one by one; `WriteCellLayout.wrapGroup` frames the group.

### 3.4 Caret, selection and keys

The caret is the document caret. Clicking, double click (word), triple click (line), dragging,
Shift+arrows and Shift+click select as in paragraphs; a selection may span cells and continues in
document order (row by row). Keys in a cell or item (`CellKeyboard`, before the defaults):

| Key | Table cell | Grid item |
|-----|------------|-----------|
| Enter | caret to the cell below; in the last row, appends a row first | inserts an item after this one (text after the caret moves into it) |
| Shift+Enter | caret to the cell above | — (ignored) |
| Tab / Shift+Tab | next / previous cell, selecting its text; Tab in the last cell appends a row | next / previous item; Tab in the last item appends one |
| ↑ / ↓ | same column, row above / below (keeping the x position); from the first / last row, to the block before / after the table | the item above / below in the flowed layout |
| ← / → | across the cell edge to the previous / next cell (document order), out of the table at its ends | same, in item order |
| Backspace at the start | moves the caret to the end of the previous cell (never merges cells) | in an empty item, removes it (and the grid with its last item), caret to the previous item's end; otherwise like a cell |
| Delete at the end | moves the caret to the start of the next cell | removes the next item if it is empty, else moves |
| Mod+A | selects the document | selects the document |

- **Deleting a selection that spans cells** clears the selected text in each cell; cells and rows
  stay (`CellDeletionHandler`, a request handler before super_editor's). Typing or pasting over
  such a selection clears it, then inserts into the first cell.
- **Selections that start outside a table** and end inside it (or the reverse) delete whole lines
  outside and clear text inside. A selection covering a whole table (every cell, as from Mod+A or
  dragging across it) deletes the table.
- **Paste into a cell** inserts plain text with line breaks as spaces; rich content keeps its
  inline formatting. Pasting cell lines (copied from a table) into a cell pastes their text joined
  with spaces. Pasting them into an ordinary line inserts a new table (new ids, §1.3).
- **Copy** of a selection inside one table writes its text as TSV (cells separated by tabs, rows by
  newlines) as plain text, the Delta (with new ids on paste) and an HTML table.
- Inline formatting commands work on cell text. Block commands (headings, lists, quote, code
  block, alignment, indentation, numbered heading, insert table/grid/container) are disabled in a
  cell; the normalizer removes such attributes anyway (§1.4).

### 3.5 Commands

All structural commands are one undo step, run on the caret's table/grid (or `nodeId:` any of its
nodes) and are **not suggestable** (Suggesting mode disables them; typing in cells is suggestable
like any text). Each builds a Delta through `CellEdits` (`wonky_write_core`), the same code the MCP
tools use (§4).

| Command | Effect |
|---------|--------|
| `write.insert.table {rows, cols}` | inserts a table after the current block (or replacing an empty paragraph), caret in the first cell |
| `write.table.insertRow {index?, position}` | inserts a row above/below (default: the caret's row) |
| `write.table.insertColumn {index?, position}` | inserts a column left/right (default: the caret's column) |
| `write.table.deleteRow {index?}` / `deleteColumn` | deletes; deleting the last row or column deletes the table; the header row cannot be deleted while body rows exist (it can be emptied) |
| `write.table.moveRow {from, to}` / `moveColumn` | moves (the moved cells' text is deleted and re-inserted) |
| `write.table.setColumnAlignment {index?, align}` | sets `align` on the column's cells |
| `write.table.setCell {row, col, markdown}` | replaces a cell's content (MCP) |
| `write.table.delete` | deletes the table |
| `write.table.edit` | opens the table editor popover (§3.6) |
| `write.insert.grid` | inserts a grid of three empty items, caret in the first |
| `write.grid.setColumns {columns}` / `setBullets {bullets}` | sets on every item |
| `write.grid.addItem` / `removeItem {index}` / `delete` | as named |

Choosing a value the table or grid already has succeeds without an edit (04 radio rule).

### 3.6 Table editor popover

The popover (04 §18.4) stays for bulk work (reordering, sorting, pasting a grid of values). It
edits a `TableDraft` built from the table's lines; **Done** replaces the table's lines with the
draft's (one undo step "Edit table"), keeping the table id. Inline attributes that inline Markdown
cannot express (comments, suggestions) in changed cells are lost; unchanged cells keep their lines.
Before any structural command or the popover, ragged rows are completed with empty cells (part of
the same step).

### 3.7 Chrome and menus

- **Table**: on hover or with the caret inside, the chrome above the table's top-right corner has
  *Edit table* (the popover) and ⋯ (insert row above/below, insert column left/right, delete row,
  delete column, alignment, delete table). The context menu in a cell has the same row/column
  items. *Format › Table ▸* lists them when the caret is in a table.
- **Grid**: the chrome of 11 §7.2 (columns, bullets, add item, ⋯ delete) sits on the group.
- The chrome is in `WriteCellLayout.wrapGroup`, so it belongs to the group, not to one cell.

### 3.8 Pagination

In Pages mode a table row moves to the next page as a unit: `PaginationController` measures a row
as the union of its cells and gives every cell of the row the same gap. Grid rows likewise. A row
taller than a page overflows the seam (as an oversized block does).

### 3.9 Collaboration

Edits to cell text merge character by character, like paragraphs. Remote carets and selections
show inside cells. Comments and suggestions anchor to cell text. Structural edits are line
inserts/deletes and merge by OT; the only anomaly is a **ragged row** (one user inserts a column
while another inserts a row: the new row lacks the new column's cell), shown with placeholders and
completed by the next structural command. Two users deleting the same row converge (the second
delete is empty after the transform).

## 4. Server, MCP and AI

- `CellEdits` (`wonky_write_core/edit/cell_edits.dart`) builds every structural change from a
  document and a table/grid id (insert/delete/move row and column, alignment, set cell, insert
  table/grid, grid columns/bullets/items, replace a table from rows). `DocumentEdits` (MCP on the
  server) uses it; so do the editor commands.
- The server MCP tools keep their names and arguments (`write.insert_table`,
  `write.update_table`, 09 §3); cell arguments are inline Markdown, as before. The editor's
  `write.table.*` and `write.grid.*` commands (§3.5) are reachable through `ui.write`. Document
  offsets now count a table's cell text and line ends (an image still counts 1).
- The AI assistant reads documents as Markdown and writes Markdown: unchanged.
- `CellUpgrader` upgrades legacy embeds on load and after commits (§1.5).

## 5. Tests and acceptance

### 5.1 Tests

- **Core**: codec round trips (Markdown ⇄ lines, legacy embed ⇄ lines), validator and normalizer
  rules, `CellUpgrade` (shapes, ids, inline Markdown, box, comments dropped), `CellEdits` (every
  command, ragged tables, last row/column), `DocTreeBuilder` for both forms, every exporter on a
  line table (golden text where present), OT convergence fuzz with tables and grids
  (`EditGen`/`DeltaGen` generate cell and grid lines).
- **super_editor (SE-15)**: rows and flow layout geometry, nearest-component in 2D, hit testing,
  caret and selection rectangles in a group, rebuild on placement change, `SuperReader`.
- **Editor**: typing, click and double click inside a cell (the caret and word land in that cell),
  every key in §3.4, deletion across cells, paste and copy, every command (one undo step each),
  container frame around a table, pagination of rows, the legacy read-only path.
- **Server**: upgrade on load and after a legacy commit (one system op, idempotent), MCP table and
  grid tools on line tables.

### 5.2 Acceptance criteria

**AC-12.1** Clicking a word in any cell puts the caret there; double-clicking selects the word;
typing goes into that cell; nothing else in the document moves.
**AC-12.2** Tab walks the cells in order and appends a row at the end; Enter goes to the cell
below; ↑/↓ keep the column.
**AC-12.3** Selecting across three cells and pressing Delete clears the selected text and keeps
the table's shape; undo restores it.
**AC-12.4** Two users typing in different cells of one table at the same time both keep their
text; a comment on a cell's word survives a remote edit in another cell.
**AC-12.5** A document saved before this change opens with its tables and grids intact and
editable; its Markdown export is unchanged by the upgrade.
**AC-12.6** Bold, links, chips and mentions in a cell export to Markdown, HTML, PDF and DOCX.
**AC-12.7** A grid item: Enter adds the next item, Backspace in an empty item removes it, the
chrome changes columns and bullets.

## 6. Removed

`InlineTableEditing`, `InlineGridEditing`, `FieldClicks` and their tap-region, focus and
click-counting logic; the editor no longer uses `DocumentGestureOptOut` (SE-14 stays in
super_editor, unused by Write). The `table` and `grid` embeds remain readable (§1.5) but are
never written.
