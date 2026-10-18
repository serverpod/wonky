# Sheets 02 · Data Model (Offline-First Sync)

Read first: suite [17 · RevLog sync](../17-revlog-sync.md) (parts 1–3: files, ops, apply rules)
and suite [12-offline-and-sync.md](../12-offline-and-sync.md) §2. The file tables below are
server tables (`serverOnly: true`) in `wonky_server/lib/src/sheets/models/rows/`. Server, cores
and clients share their schema as pure Dart: `sheetsSchema` (`wonky_sheets_core`,
`lib/src/revlog/sheets_schema.dart`) drives the codec, the server SQL and the client cache (17
part 2 §4); a server guard test compares it with the generated tables. The domain enums are
hand-written pure-Dart enums with the same names in `packages/wonky_sync_models`. Id helpers (UUIDv5
namespaces, fractional indexing, the 22-char base-62 UUID codec from `wonky_revlog`) are a
pure-Dart library without Serverpod imports (`wonky_sync_models/lib/ids.dart`, implementation in
`lib/src/ids/`) so server and clients compute identical ids.

## 1. Modeling principles

| # | Principle | Why |
|---|-----------|-----|
| S1 | **One spreadsheet = one file**; `Spreadsheet.id` = file UUID = drive item UUID (`DriveItem.contentRef`). | The file is the unit of sharing, sequencing (one op log and head revision) and offline caching. |
| S2 | **Rows and columns are entities with stable UUIDs** (`SheetRow`, `SheetColumn`) ordered by a **fractional index** `sortKey` (base-62 string, tie-break on `id`). | Inserting/deleting/moving rows or columns is O(1) writes and merges cleanly with concurrent edits; cells never need to be renumbered. |
| S3 | **Cells are addressed by (rowId, colId)**, one `Cell` row per *non-empty* cell, with a **deterministic id** `UUIDv5(ns, "cell:<sheetId>:<rowId>:<colId>")`. | Two offline users writing the same cell produce the same row; the inserts merge per column (17 part 3 §4.2), last arrival wins per column. No unique index needed. |
| S4 | **Each format attribute is its own column.** | Concurrent "bold" and "fill color" on the same cell both survive (field-level merge). |
| S5 | **Cell content is a single column** (`content`) in a typed text encoding. | Value + type change atomically (no half-merged states). |
| S6 | **Formulas are stored with id-based references** and rendered as A1 for display/editing. | Concurrent row/column inserts never require rewriting formulas, so offline edits merge without formula corruption. |
| S7 | **Range-based rules** (conditional formats, validation, filters, protected ranges, charts, pivots) store ranges as id-based `GridRange` JSON, not FKs. | Ranges span many rows; FK-per-boundary is brittle. Missing ids shrink/ignore at evaluation time. |
| S8 | **Every update names its columns.** A `RowChange` update carries only the columns it changes (`before`/`after` maps), and the codec sends only those. | Ops assign absolute column values; naming more columns would clobber concurrent edits of the others. |
| S9 | **Computed values are never synced.** Each client (and the server for headless use) evaluates formulas locally with `wonky_sheets_core`. | Keeps sync volume proportional to user edits; avoids recalculation write storms. |
| S10 | **The op log records what changed.** Every op (`rev_op`) carries its author, actor kind, label, summary and ≤ 200-cell detail with the applied changes (§3.7). | Feeds the post-commit hooks (triggers, activity, cell edit history), version attribution, offline history and server-change revert. |

## 2. Identifiers and encodings (`wonky_sync_models/lib/src/`)

- `SheetsIds.cellId(sheetId, rowId, colId)`, `SheetsIds.basicFilterId(sheetId)`,
  `SheetsIds.scriptBuildId(projectId)` — UUIDv5 with fixed namespace UUIDs (constants, never
  change).
- **Fractional index** (`FractionalIndex.between(a, b)`, `.before(a)`, `.after(b)`,
  `.nBetween(a, b, n)`): base-62 strings (Figma/`fractional-indexing` algorithm); generating n keys
  for bulk inserts produces evenly spaced short keys. Ties (concurrent identical keys) sort by
  `id`.
- **Content encoding** (`CellContent`):
  | Prefix | Meaning | Example |
  |--------|---------|---------|
  | `=` | Formula in stored-reference form | `=SUM(⟦R:5Kq…;C:9zA…⟧:⟦R:7Hb…;C:9zA…⟧)` |
  | `n:` | Number (Dart double, shortest round-trip repr) | `n:42.5` |
  | `s:` | Text | `s:Hello` |
  | `b:` | Boolean `0`/`1` | `b:1` |
  | `e:` | Error literal | `e:#N/A` |
  | `r:` | Rich text JSON `{"t":"text","runs":[{"s":0,"e":5,"f":{"bold":true,"link":"https://…"}}]}` | |
  Dates/times are numbers (serial date, 1899-12-30 epoch) + a date number format. Text that
  looks like a number but was forced as text (leading `'`) is stored as `s:`.
- **Reference tokens** inside stored formulas: `⟦` + `;`-separated fields + `⟧` where fields are
  `S:<sheetId>` (omitted for same sheet), `R:<rowId>`, `C:<colId>`, `$R`, `$C` (absolute flags).
  UUIDs are written in a 22-char base-62 form. Whole column = only `C:`, whole row = only `R:`.
  Range = `token:token`. Named ranges and functions stay textual.
  `FormulaCodec.toStored(a1Formula, context)` and `.toA1(storedFormula, context)` (in
  `wonky_sheets_core`) convert. A **single-cell** reference whose row/column no longer exists
  renders and evaluates as `#REF!`; a deleted **range endpoint** shrinks the range instead
  (delete commands rewrite endpoints; range tokens also carry `K:`/`KC:` sortKey hints so
  concurrent offline deletes resolve identically on every client). Full grammar, unbound `X:`
  tokens and rewrite rules: [05-formula-engine.md](05-formula-engine.md).
- **GridRange JSON**: `{"s":"<sheetId>","r1":"<rowId>","r2":"<rowId>","c1":"<colId>","c2":"<colId>"}`
  with any bound optional (unbounded). Resolved to index ranges by the current ordering.

## 3. File tables

The 22 tables of a spreadsheet's content. Each has `id: UuidValue` plus two columns the
sequencer sets and clients never write: `fileId` (the `rev_file` row; a plain column without FK
on `cell`) and `revision` (the revision that last wrote the row). Domain FKs cascade on delete
and are `deferred`; the sequencer also cascades explicitly (17 part 1 RD-3). Field lists below
omit `id`/`fileId`/`revision`. Every model has `createdAt: DateTime` unless noted. Clients see
the same tables as column maps through `sheetsSchema`, never as generated classes.

### 3.1 Spreadsheet & sheets

```yaml
class: Spreadsheet                       # id == file UUID
table: spreadsheet
serverOnly: true
fields:
  title: String                          # mirrored to DriveItem.name by the server
  locale: String                         # e.g. en_US, de_DE — number/date parsing & formatting, function arg separator
  timeZone: String                       # IANA
  recalcMode: RecalcMode                 # onChange, onChangeAndEveryMinute, onChangeAndEveryHour
  iterativeCalc: bool
  maxIterations: int                     # default 50
  convergenceThreshold: double           # default 0.05
  defaultFontFamily: String              # theme default (Arial-like default: "Inter")
  defaultFontSize: double                # 10
  themeJson: String                      # {fonts, accent1-6, link, text, background}
  createdBy: UuidValue                   # user UUID (cross-boundary plain UUID)
  createdAt: DateTime

class: Sheet
table: sheet
serverOnly: true
fields:
  spreadsheet: Spreadsheet?, relation(name=spreadsheet_sheets, onDelete=Cascade)
  name: String
  sortKey: String
  kind: SheetKind                        # grid, chart (object sheet holding one chart)
  hidden: bool
  tabColor: String?
  rightToLeft: bool
  showGridlines: bool
  frozenRows: int                        # count from top in current order
  frozenColumns: int
  defaultRowHeight: double               # px at 100% zoom (21)
  defaultColumnWidth: double             # 100
  formatJson: String?                    # sheet-level default format (rarely used)
indexes:
  sheet_order_idx: { fields: spreadsheetId, sortKey }
```

Sheet name uniqueness is **not** a DB constraint (an offline rename would be rejected whole);
instead the client prevents duplicates and, if a merge produces duplicates, the UI
shows both with a warning badge and formula references use sheet **ids** so nothing breaks;
the later-created sheet is auto-renamed by the first client that notices (`"Sheet1 (2)"`,
idempotent deterministic rename rule: append ` (2)` to the one with the larger id).

### 3.2 Rows and columns

```yaml
class: SheetRow
table: sheet_row
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_rows, onDelete=Cascade)
  sortKey: String
  height: double?                        # null = default/auto-fit
  hidden: bool                           # user-hidden (filter-hidden is computed, not stored)
  formatJson: String?                    # row default format (applies to empty cells in row)
indexes:
  sheet_row_order_idx: { fields: sheetId, sortKey }

class: SheetColumn
table: sheet_column
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_columns, onDelete=Cascade)
  sortKey: String
  width: double?
  hidden: bool
  formatJson: String?                    # column default format
indexes:
  sheet_column_order_idx: { fields: sheetId, sortKey }
```

A new sheet creates 1,000 rows × 26 columns (entities only; no cells). "Add 1000 more rows" at
the bottom of the grid creates more. The **grid size** counts toward the cell limit
(rows × columns), like Google Sheets.

### 3.3 Cells

```yaml
class: Cell
table: cell
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7   # always overwritten with SheetsIds.cellId(...) before insert
  sheet: Sheet?, relation(name=sheet_cells, onDelete=Cascade)
  rowId: UuidValue                       # plain id, no DB FK: the sequencer cascades cells by (sheetId, rowId)
  columnId: UuidValue                    # and (sheetId, columnId) (17 part 2 §2.1)
  content: String?                       # §2 encoding; null = no value
  note: String?                          # cell note (not a comment)
  # ---- format (each independently merged; null = inherit row/column/sheet default) ----
  numberFormat: String?                  # pattern, e.g. "#,##0.00", "yyyy-mm-dd", "[$€]#,##0", or preset id
  fontFamily: String?
  fontSize: double?
  bold: bool?
  italic: bool?
  underline: bool?
  strikethrough: bool?
  textColor: String?                     # "#RRGGBB" or "theme:accent3"
  fillColor: String?
  hAlign: HorizontalAlign?               # left, center, right (null = general: numbers right, text left)
  vAlign: VerticalAlign?                 # top, middle, bottom
  wrap: WrapStrategy?                    # overflow, wrap, clip
  rotation: int?                         # -90..90 degrees; 255 = vertical stacked
  borderTop: String?                     # "<style>|<color>" style ∈ thin, medium, thick, dashed, dotted, double; "none"
  borderRight: String?
  borderBottom: String?
  borderLeft: String?
  linkUrl: String?                       # whole-cell hyperlink (runs use r: content)
indexes:
  cell_row_idx: { fields: sheetId, rowId }
  cell_col_idx: { fields: sheetId, columnId }
```

- A cell row exists iff at least one field is non-null; clearing all fields deletes it
  (re-creating inserts the same deterministic id again).
- Effective format = cell ▸ row ▸ column ▸ sheet ▸ spreadsheet theme defaults (per attribute).
- Border conflicts between adjacent cells (A1.bottom vs A2.top): render the heavier style; if
  equal, the top/left cell wins.
- Concurrency semantics (documented to users in help): the last op to arrive at the server wins
  **per cell value** and **per format attribute**; deleting a row/column wins over concurrent
  edits to its cells.

### 3.4 Structure & ranges

```yaml
class: MergedRange
table: merged_range
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_merges, onDelete=Cascade)
  rangeJson: String                       # GridRange with all four bounds

class: DimensionGroup                      # row/column grouping (outline)
table: dimension_group
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_groups, onDelete=Cascade)
  dimension: Dimension                     # rows, columns
  startId: UuidValue
  endId: UuidValue
  depth: int                               # 1..8
  collapsed: bool

class: NamedRange
table: named_range
serverOnly: true
fields:
  spreadsheet: Spreadsheet?, relation(name=spreadsheet_named_ranges, onDelete=Cascade)
  name: String                             # validated: letters, digits, _, not A1-like, case-insensitive unique (client-enforced)
  rangeJson: String?                       # GridRange, or null when `formula` used
  formula: String?                         # named formula / LAMBDA (stored-ref form)
  comment: String?

class: ProtectedRange
table: protected_range
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_protections, onDelete=Cascade)
  rangeJson: String?                       # null = whole sheet
  exceptRangesJson: String?                # for sheet protection: unprotected ranges
  description: String?
  warningOnly: bool
  editorsJson: String                      # list of user UUIDs allowed to edit (owner always)
  createdBy: UuidValue
```

### 3.5 Rules, filters, objects

```yaml
class: ConditionalFormatRule
table: conditional_format_rule
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_cf_rules, onDelete=Cascade)
  sortKey: String                           # priority (first = highest)
  rangesJson: String                        # list of GridRange
  ruleJson: String                          # {type: boolean|colorScale, condition, format | gradient}
  enabled: bool

class: DataValidationRule
table: data_validation_rule
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_dv_rules, onDelete=Cascade)
  rangesJson: String
  criteriaJson: String                      # type + values (see data tools spec)
  strict: bool                              # reject invalid input vs. show warning
  showDropdown: bool                        # for list types: chip/arrow/plain
  displayStyle: String?                     # chip, arrow, plainText
  helpText: String?

class: BasicFilter                          # id = SheetsIds.basicFilterId(sheetId): max one per sheet
table: basic_filter
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_basic_filter, onDelete=Cascade)
  rangeJson: String
  criteriaJson: String                      # {colId: criteria}
  sortJson: String?                         # [{colId, ascending}]

class: FilterView
table: filter_view
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_filter_views, onDelete=Cascade)
  name: String
  rangeJson: String
  criteriaJson: String
  sortJson: String?
  createdBy: UuidValue

class: Banding                              # alternating colors
table: banding
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_bandings, onDelete=Cascade)
  rangeJson: String
  styleJson: String                         # header, first band, second band, footer colors

class: EmbeddedObject                       # charts, images, drawings (images only in v1), slicers
table: embedded_object
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_objects, onDelete=Cascade)
  kind: EmbeddedObjectKind                  # chart, image, slicer
  anchorJson: String                        # {rowId, colId, dx, dy, width, height} or {"ownSheet":true}
  specJson: String                          # chart spec / slicer spec / image {fileUuid, alt, fit}
  zIndex: int
  title: String?
  altText: String?

class: PivotTable
table: pivot_table
serverOnly: true
fields:
  sheet: Sheet?, relation(name=sheet_pivots, onDelete=Cascade)   # sheet that displays the pivot
  anchorRowId: UuidValue
  anchorColId: UuidValue
  sourceRangeJson: String
  specJson: String                          # rows, columns, values, filters, options
```

Pivot output cells are **computed locally** (like formulas) and rendered as a read-only overlay
anchored at (anchorRowId, anchorColId); they are not stored as `Cell` rows (avoids write storms
and conflicts). Same for array-formula spill results.

### 3.6 Scripts

```yaml
class: ScriptProject                        # one per spreadsheet (bound script), created on first use
table: script_project
serverOnly: true
fields:
  spreadsheet: Spreadsheet?, relation(name=spreadsheet_script, onDelete=Cascade)
  name: String
  settingsJson: String                      # time zone, runtime options

class: ScriptFile
table: script_file
serverOnly: true
fields:
  project: ScriptProject?, relation(name=project_files, onDelete=Cascade)
  name: String                              # e.g. "main.dart"
  sortKey: String
  source: String                            # whole-file LWW (editor warns on concurrent edit)
  updatedBy: UuidValue
  updatedAt: DateTime

class: ScriptBuild                          # written by the server only (id = SheetsIds.scriptBuildId; clientWritable: false in sheetsSchema)
table: script_build
serverOnly: true
fields:
  project: ScriptProject?, relation(name=project_build, onDelete=Cascade)
  sourceHash: String
  bytecodeFileUuid: UuidValue?              # EVC bytecode in cloud storage (null if errors)
  diagnosticsJson: String
  exportsJson: String                       # functions, custom functions (with JSDoc-like metadata), macros
  builtAt: DateTime

class: ScriptTrigger
table: script_trigger
serverOnly: true
fields:
  project: ScriptProject?, relation(name=project_triggers, onDelete=Cascade)
  kind: TriggerKind                         # onOpen, onEdit, onChange, onSelectionChange, timeDriven
  functionName: String
  scheduleJson: String?                     # for timeDriven
  runAsUserId: UuidValue                    # installer; must keep edit access
  enabled: bool

class: Macro
table: macro
serverOnly: true
fields:
  project: ScriptProject?, relation(name=project_macros, onDelete=Cascade)
  name: String
  functionName: String
  shortcutSlot: int?                        # 1..10 → Mod+Alt+Shift+<n>

class: ScriptProperty
table: script_property
serverOnly: true
fields:
  project: ScriptProject?, relation(name=project_properties, onDelete=Cascade)
  key: String
  value: String
```

Execution logs and quotas are server-side Postgres tables (see scripting spec).

### 3.7 Op log

There is no change-log table. Every op is a row of the platform table `rev_op` (17 part 2 §1),
written by the sequencer in the same transaction as the change: revision, author, `actorKind`
(user, mcp, ai, script, system), session id, label (the undo label: "Paste", "Insert 3 rows"),
`groupId` (one plan split into ≤ 5,000-change ops), `recordId` (one revertible server change),
`offline`, `summaryJson` (`{sheets:[id], ranges:[GridRange], kinds:[values, format, structure,
…], deleted, revived}`, the core's `ChangeSummary`), `detailJson` (before/after
content of ≤ 200 cells; null if larger) and the compressed applied changes with their `before`
values.

- After commit, durable hooks (17 part 5 §6.2) turn it into activity, `DriveItem.modifiedAt`
  and search text, cell edit history (`cell_history`), comment orphaning, script compiles and
  `onEdit`/`onChange` triggers.
- Payload, summary and detail are pruned after 30 days (a slim row stays a year for idempotent
  resends); `cell_history` keeps the latest 100 values per cell beyond that (10 §6).
- Clients keep the metadata, summary and detail of recent ops in their cache (`rev_local_op`,
  30 days) and read them through `LoggedWorkbookSession.history` (§4).

## 4. Client cache (local SQLite, not the source of truth)

Each user has one RevLog cache per app, `sheets_cache_<userUuid>.db` (17 part 2 §3), opened by
`RevLogClient` (`wonky_revlog_flutter`) through `SheetsRevLog`
(`wonky_sheets/lib/features/revlog/`). It holds the server state of each spreadsheet at a known
revision (`rev_row`, one generic table for every file table), the durable **outbox** of this
device's unacknowledged ops (`rev_outbox`), bootstrap coverage (`rev_coverage`), recent op
metadata (`rev_local_op`) and outcomes awaiting review (`rev_outcome`). Spreadsheets opened in the
last 14 days (max 50) or pinned are kept complete; files with outbox rows are never evicted
(17 part 6 §2.5). When the app's schema hash changes, the domain rows are dropped and
re-downloaded and the outbox is re-encoded (17 part 6 §2.4).

Other local state:

| Table | Purpose |
|-------|---------|
| `ComputedValueCache` | `(cellId, valueJson, formattedText?, engineVersion)` for fast reopen of large sheets; invalidated per engine version. **Deferred:** measured reopen cost is model build and formula compilation, not evaluation (150k formulas: model 2.1 s, first window 1.2 s, the visible window's values a few ms; viewport-first loading spreads the compile over the streamed chunks). Formulas over rows that are still streaming in show `#LOADING` instead of partial values (`LoadingFormulaSource`, 03 §2.8). |
| `LocalUndoStack` | Serialized undo/redo stacks per spreadsheet (best effort). |
| `LocalViewState` | Per spreadsheet: active sheet, selection, scroll, zoom, panel states, temporary filter views. **As built:** not a table but small JSON in the user's local key-value store (`sheets.view.<spreadsheetId>`, newest 200 kept, like the shell's per-user data, suite 12 §3); also the viewport hint of viewport-first loading and the "last opened" order of the IndexedDB cell cap. Side panel precedence on open: a panel the spreadsheet opens while it starts (`?comment=` deep link, pivot/chart editor) > the saved panel > a panel still open from the previous document (the shell's panel host is shared); a saved "no panel" leaves a carried-over panel open. |
| ~~`PendingDriveRegistration`~~ | Not a table: a spreadsheet created on the device puts its creation op in the outbox and calls `drive.registerSpreadsheet(fileUuid, parentUuid, name)`, queued in the shell's `PendingDriveOp` queue while offline (suite 12 §3). The server runs it as `createSpreadsheet(fileUuid, initialize: false)`, so the client's creation op is the file's first op (17 part 4 §5, part 6 §7.1). |

## 5. Server-only tables (Postgres, `serverOnly: true`)

Besides the file tables (§3) and the platform's RevLog tables (`rev_file`, `rev_op`,
`rev_hook_state`; 17 part 2 §1):

| Table | Content |
|-------|---------|
| `cell_history` | `fileUuid, sheetId, rowId, colId, revision, userUuid, actorKind, label, at, before, after`; unique per `(fileUuid, revision, rowId, colId)`, latest 100 per cell (10 §6) |
| `server_change_record` | Revertible server changes (MCP, AI, scripts, imports, restores): `changeId`, `spreadsheetUuid` (the file uuid), `recordId` (= `rev_op.recordId` of its ops), label, actor, `cellsAffected`, `expiresAt`, `revertedAt`, `revertChangeId`. The inline/file inverse fields only serve records written before RevLog (17, As built 5; [12](12-mcp-and-ai.md) §2.5) |
| `script_user_property` | Per-user script properties: `userId, fileUuid, key, value, updatedAt` (09 §6.9; 17 part 2 §2.4) |
| `ScriptExecution`, `ScriptQuotaUsage`, … | Script logs and quotas (09) |
| `sheets_snapshot_index` | Version index; the captured revision is `ItemVersion.revision` (10 §5.1) |

## 6. In-memory model (`wonky_sheets_core/lib/src/model/`, pure Dart, exported by `lib/model.dart`)

The UI and formula engine work on an in-memory `WorkbookModel`: the server state from the cache
or the server, with this device's outbox applied on top (17 part 3 §7). It lives in **pure
Dart** (`wonky_sheets_core`) because the server needs the same model for headless MCP tools,
version snapshots/diffs, exports, scripts and the protection check of the sequencer
(`HeadlessFileCache`, 17 part 5 §9); the Flutter app adds viewport/painter adapters and the
session (`LoggedWorkbookSession`, `wonky_sheets/lib/features/revlog/`). Mutations are planned by
a shared `SheetsMutationPlanner` (core) and persisted by the session (client) or submitted as a
server change (see [12-mcp-and-ai.md](12-mcp-and-ai.md)):

- `AxisIndex` per sheet and dimension: ordered list of row/col ids (sorted by `sortKey`, then
  `id`) with an id→index hash map and a Fenwick tree of sizes (heights/widths, hidden = 0) for
  O(log n) pixel ↔ index lookups.
- `CellStore` per sheet: sparse columnar map `rowIndex → colIndex → CellRecord` (content,
  format attribute bitset + value table) loaded at open (viewport-first, then background
  streaming). **As built** (`LoggedWorkbookSession` + `RevBootstrap`, 17 part 6 §5): from the
  cache if the file is there, otherwise from the server's bootstrap pages, every table but
  `cell` loads first, then the cells of the active sheet's frozen rows and 200 rows from the
  restored top row (`ViewportHint`: `LocalViewState` or `?gid=`) → `WorkbookReady`;
  spreadsheets of ≤ 2,000 rows load completely first. The rest streams in blocks of 500 rows,
  the active sheet first and rows the grid shows first (`WorkbookRowLoading.prioritize`), and is
  announced on `remoteBatches`. Pages carry the revision they were read at, so ops that arrive
  meanwhile are applied exactly once (coverage, 17 part 6 §5.3); the outbox stays on top. Writes
  that would touch rows still loading — or read whole ranges (sort, find and replace, shift,
  duplicate sheet) over them — are refused (`LoadingGate`, "Still loading this part of the
  sheet…"); deleting a sheet or columns waits for the whole sheet, deleting rows for those rows
  (17 part 6 §5.5).
- `RuleIndex`: interval trees for CF, DV, merges, protected ranges, filters, banding.
- **Generic ingestion**: the model holds plain Dart records (`records.dart`), independent of the
  generated Serverpod classes; it ingests `RowChange`s (`table`, `rowId`, column-name maps; UUIDs as
  strings, enums by name) so the app, the server and snapshots share one path
  (`WorkbookModel.applyChanges`). `ModelWorkbookView` adapts it to the formula engine's
  `WorkbookView` and `ModelEngineBinding` forwards change batches to the engine.
- **Change ingestion**:
  - Local writes update the model synchronously (optimistic) and the outbox asynchronously.
  - Remote ops arrive on the file's stream in revision order with their applied changes. The
    session replays them over the server rows they touch, re-applies the outbox ops for those
    rows with the same apply rules, and patches the model with the difference (`RevOverlay`, `wonky_revlog`;
    17 part 3 §7); the patch is emitted on `WorkbookSession.remoteBatches` in the same turn.
    Rows equal to the model produce no change, and the author's own ack produces a patch only
    when the server's applied form differs from what was sent (drops, merges, cascades). A
    property test checks that the overlay patch equals a full rebuild.
- Formula engine (`wonky_sheets_core`) consumes the model through a `CellSource` interface; see
  formula spec for the dependency graph and recalculation.

## 7. Writes and undo (`sheets.rows` undo domain)

All client mutations go through the session (`LoggedWorkbookSession.execute` /
`applyChanges`), which:
1. Plans the operation against the model (`SheetsMutationPlanner`), giving
   `RowChange {table, rowId, op, columnsBefore, columnsAfter}`s that name only the columns they
   change, plus the summary and detail; the protection gate (07 §10.3) and the `LoadingGate`
   check the plan.
2. Applies the changes to the model synchronously.
3. Appends them to the outbox as change sets (one durable cache write) and sends them once that
   write completed; `flush()` waits for local durability, `whenSynced()` for the server's ack.
4. Pushes an `UndoStep` (domain `sheets.rows`) with the recorded changes and the plan's
   `groupId`.

Undo replays inverses with the same naming discipline; a column whose current value differs from
`columnsAfter` (someone else changed it since) is skipped (see suite undo spec §3.3). Deleted
rows are restored by re-inserting the same id (with every descendant the plan listed), so
references and deterministic ids stay valid. If the server rejects a plan's group, the model
rolls back and the undo step is removed (17 part 6 §4.6).

Bulk operations (paste 100k cells, import, sort) are split by `RevChunker` into ops of ≤ 5,000
changes and ≤ ~1 MiB encoded, which form one **group** (`groupId`) and remain **one undo step**;
consecutive small edits within 2 s are composed into one op. Groups report progress in the sync
status while they are sent (17 part 6 §9). The server applies each op in one transaction with
set-based SQL (17 part 5 §3.3); throughput budgets are the performance gates of
[17](../17-revlog-sync.md) part 7 (P3/P4 server commits, P9 1M-cell local import, P10 1M-cell
server import).

## 8. Invariants & maintenance (client-side, idempotent)

Run after remote batches (debounced) by an editor's client that detects them, as an ordinary op
that is not an undo step (17 part 3 §6: repairs stay on the client, the server only validates).
All rules are deterministic and idempotent, so concurrent fixes converge. The rules are
`WorkbookMaintenance.plan` (core `mutations/maintenance.dart`); object anchors are repaired by
`AnchorMaintenance` ([08](08-charts-and-objects.md) §1.2). `LoggedWorkbookSession.runMaintenance` runs
`WorkbookMaintenance` 1 s after remote batches and after ready, for editors, once the spreadsheet
is settled (every row loaded, no remote op group half applied, this tab's outbox empty — 17 part
6 §1.2), and sends the plan as a `"repair": true` op that is not an undo step.
- Sheet name duplicates → rename rule (§3.1).
- `frozenRows/Columns` > visible counts → clamp.
- Merges overlapping → keep the one with the smaller id, delete others.
- Basic filter / pivot anchors pointing at deleted rows → delete rule / move anchor to nearest
  surviving row.
- Cells whose row or column is missing (the sequencer cascades them; a client never shows them) → ignored.

## 9. Additions defined in feature specs

Feature specs add fields and tables next to the features that need them. They are part of this
data model and **must be applied together with it**: each is a column of `sheetsSchema` and of
the server table. A new nullable column or table is additive (older clients keep working within
the schema window); anything else bumps `minClientVersion` (17 part 2 §4.3):

| Spec | Section | Highlights |
|------|---------|------------|
| [03 · Grid & editing](03-grid-and-editing.md) | §20 | Grid/view-state keys, commit-hint `sessionId` |
| [04 · Screens, menus & toolbar](04-screens-menus-toolbar.md) | §15 | `Spreadsheet.displayLanguage`, `LocalViewState` keys, `sheetsDefaults` keys |
| [05 · Formula engine](05-formula-engine.md) | §24 (F1–F8) | Reference token `K:`/`KC:`/`X:` fields, GridRange key fields, engine caches |
| [06 · Formatting](06-formatting.md) | §19 | `themeJson`/banding `styleJson` schemas, `preset:*` number formats, CF `dataBar`/`iconSet`/`stopIfTrue`, smart-chip runs |
| [07 · Data tools](07-data-tools.md) | §22 (D1–D10) | Filter/DV/pivot/named-function JSON schemas, protection details |
| [08 · Charts & objects](08-charts-and-objects.md) | §20 | `ChartSpec` schema, object anchor fields |
| [09 · Scripting](09-scripting.md) | §19 | `ScriptBuild.lastGood*` fields, `ScriptUserProperty` (server table), `ScriptExecution` (server) |
| [10 · Collaboration & history](10-collaboration-history.md) | §14 (A-10-x) | Op summary deletions (`summaryJson.deleted`), version state tables, `PendingCommentOp`, `LocalConflict`, `sheets.serverChange` undo domain |
| [11 · Import, export & print](11-import-export-print.md) | §10 | `Sheet.printSettingsJson` |
| [12 · MCP & AI](12-mcp-and-ai.md) | §8 (A-12-x) | Model in `wonky_sheets_core`, `SheetsMutationPlanner`, `ServerChangeRecord`, `AiFunctionCache` |

Known LWW granularity limits (documented, accepted): row/column/sheet default `formatJson`,
`BasicFilter.criteriaJson`, chart `specJson` and `ScriptFile.source` merge as whole values.
