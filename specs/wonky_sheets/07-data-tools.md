# Sheets 07 · Data Tools

Read first: [02-data-model.md](02-data-model.md) (tables used here: `BasicFilter`, `FilterView`,
`DataValidationRule`, `PivotTable`, `NamedRange`, `ProtectedRange`, `DimensionGroup`,
`EmbeddedObject` kind `slicer`, `Cell`, the op log), [05-formula-engine.md](05-formula-engine.md)
(evaluation, `FormulaCodec`, `ReferenceRewriter`, offload jobs), suite
[08-commands-and-undo.md](../08-commands-and-undo.md) and
[06-sharing-and-permissions.md](../06-sharing-and-permissions.md). Menu entries, panel
ids and dialog field ids are fixed in [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md)
(§3.6, §10, §11); grid rendering of filter buttons, checkboxes, dropdown chips, group gutters and
protection stripes in [03-grid-and-editing.md](03-grid-and-editing.md) (§3, §14, §16).
Conditional formatting lives in [06-formatting.md](06-formatting.md) and shares the `Condition`
model defined here (§3.3). Charts/slicer object layer: [08-charts-and-objects.md](08-charts-and-objects.md).
MCP tool implementations: [12-mcp-and-ai.md](12-mcp-and-ai.md).

## 1. Overview

### 1.1 Features and priorities

| § | Feature | Priority | Synced model | Computed locally |
|---|---------|----------|--------------|------------------|
| 2 | Sort sheet / sort range (multi-key), sort by color | P0 (color P2) | `Cell` writes | sort permutation |
| 3 | Basic filter (values, condition, color) | P0 (color P1) | `BasicFilter` | hidden-row mask |
| 4 | Filter views (saved, temporary) | P1 | `FilterView` (+ `LocalViewState`) | mask, view row order |
| 5 | Slicers | P2 | `EmbeddedObject(kind: slicer)` | mask |
| 6 | Data validation (all criteria, chips, checkboxes) | P0 (multi-select P2) | `DataValidationRule` | invalid markers |
| 7 | Pivot tables | P1 | `PivotTable` | output overlay |
| 8 | Named ranges | P0 | `NamedRange` | — |
| 9 | Named functions | P1 | `NamedRange` (`formula`, `metaJson`) | — |
| 10 | Protected sheets & ranges | P0 | `ProtectedRange` | guard checks |
| 11 | Find & replace | P0 | `Cell` writes | match list |
| 12 | Remove duplicates, trim whitespace, cleanup suggestions | P1 (suggestions P2) | `Cell` writes | duplicate detection |
| 13 | Split text to columns | P1 | `Cell` writes | separator detection |
| 14 | Randomize range | P1 | `Cell` writes | shuffle |
| 15 | Column stats | P1 | — | stats |
| 16 | Row/column groups | P1 | `DimensionGroup` | collapsed-hidden mask |
| 17 | Convert to table (structured tables) | P2 | `SheetTable` (addition) | — |
| 18 | Smart fill / data extraction | P2 | `Cell` writes | pattern synthesis / AI |

Global rules for every feature:

- **Everything works offline** on the local model; every computed artifact (hidden rows, invalid
  markers, pivot output, stats, find results) is computed on the device by `wonky_sheets_core`
  (server uses the same code headlessly for MCP).
- **One command = one undo step** through the session (02 §7); large writes are chunked
  (≤ 5,000 row changes per op, one op group) but remain one step.
- **Every action is a command** with a stable id (§20) and is MCP-controllable through
  `ui.invoke_command`; dialogs are `WonkyDialogSpec`s (suite 09 §6.2); headless tools are listed
  in §21.
- **Light & dark**: all panels use shad tokens; data colors chosen by users (chip colors, slicer
  colors) are absolute like cell colors (suite 02 §8).
- **Permissions**: mutating commands require Editor (`requiredRole: editor`); viewers/commenters
  get temporary filter views and local slicer state only. Protected ranges are checked by
  `ProtectionGuard` (§10) before any write.

### 1.2 Package layout

`packages/wonky_sheets_core/lib/` (pure Dart, shared with the server):

```
rules/
  conditions/                   # shared Condition model (CF, DV, filters, slicers, pivot filters)
    condition.dart              # Condition sealed types + JSON (06 §15.1 shape)
    condition_evaluator.dart    # evaluates against FValue + display text, custom formulas via engine
    relative_dates.dart         # today/yesterday/past week… in Spreadsheet.timeZone
  dv/                           # data validation (CF lives in rules/cf, owned by 06; WS-S10 in 13)
    dv_criteria.dart, validation_engine.dart, list_source.dart
data_tools/
  sort/sort_spec.dart, sort_keys.dart, sort_planner.dart   # comparator, permutation, strategy, write plan
  filter/filter_criteria.dart, filter_engine.dart, value_index.dart, view_row_order.dart
  protection/protection_guard.dart, protected_index.dart
  find/find_query.dart, find_engine.dart, replace_planner.dart
  cleanup/dedupe.dart, trim.dart, suggestions.dart (P2)
  split/separator_detector.dart, text_splitter.dart
  stats/column_stats.dart
  groups/group_layout.dart       # depth normalization, collapsed mask, level ops
  names/name_rules.dart          # named range / named function name validation
  move/row_move_plan.dart        # shared "move cell rows within a range" planner (sort, randomize, dedupe)
  jobs/data_job.dart             # DataJob, progress, CancellationToken (wraps 05 §10.3 offload)
pivot/
  pivot_spec.dart               # PivotSpec JSON model
  pivot_engine.dart             # grouping + aggregation → PivotResult
  pivot_grouping.dart           # date / histogram / manual groups
  pivot_layout.dart             # PivotResult → overlay grid (labels, totals, formats)
  aggregators.dart              # streaming aggregators sharing formula/functions implementations
  get_pivot_data.dart           # lookup used by GETPIVOTDATA
tables/ (P2)                     # structured tables
```

`wonky_sheets/lib/` (one folder = one parallel work unit):

```
features/
  sort/            ui/sort_dialog.dart (04 §11.5), sort_controller.dart
  filters/         ui/filter_column_popover.dart, filter_header_buttons.dart (painter hook for 03),
                   basic_filter_controller.dart, filter_visibility_service.dart
  filter_views/    ui/filter_view_bar.dart, filter_views_panel.dart, filter_view_controller.dart
  slicers/         ui/slicer_panel.dart, slicer_popover.dart, slicer_controller.dart   (P2)
  dv/              ui/dv_panel.dart, dv_rule_editor.dart, dropdown_options_editor.dart,
                   dv_controller.dart, invalid_marker_service.dart
  pivot/           ui/pivot_editor_panel.dart, pivot_field_list.dart, pivot_field_card.dart,
                   create_pivot_dialog.dart, pivot_controller.dart, pivot_overlay_service.dart
  named_ranges/    ui/named_ranges_panel.dart, named_range_controller.dart
  named_functions/ ui/named_functions_panel.dart, named_function_editor.dart, named_function_controller.dart
  protection/      ui/protection_panel.dart, protection_permissions_dialog.dart, protection_controller.dart
  find_replace/    ui/find_bar.dart, find_replace_dialog.dart, find_controller.dart
  cleanup/         ui/remove_duplicates_dialog.dart, cleanup_suggestions_panel.dart (P2), cleanup_controller.dart
  split_text/      ui/separator_chip.dart, split_controller.dart
  column_stats/    ui/column_stats_panel.dart, column_stats_controller.dart
  grouping/        group_controller.dart, ui/group_gutter_hit_handler.dart (painting in 03)
  data_jobs/       data_job_runner.dart, ui/job_progress_toast.dart
commands/
  data_commands.dart, filter_commands.dart, filter_view_commands.dart, slicer_commands.dart,
  dv_commands.dart, pivot_commands.dart, named_range_commands.dart, named_function_commands.dart,
  protection_commands.dart, find_commands.dart, cleanup_commands.dart, group_commands.dart
features/common/  (shared widgets next to 04's RangeInput/FormulaEditor)
  condition_editor.dart, value_checklist.dart, color_filter_picker.dart, sort_spec_list.dart,
  user_multi_select.dart, histogram_view.dart
```

### 1.3 Shared widgets

`RangeInput` and `FormulaEditor` are defined in [04 §13](04-screens-menus-toolbar.md#13-shared-custom-widgets-introduced-by-sheets).
New widgets (in `wonky_sheets/lib/features/common/`, built only from shad primitives and
`wonky_ui`, each with a widget preview in light & dark and a widget test):

| Widget | Description | Used by |
|--------|-------------|---------|
| `ConditionEditor` | `ShadSelect` of condition types (grouped: *Empty*, *Text*, *Date*, *Number*, *Custom*), then 0/1/2 value inputs depending on the type; date types add a relative-date `ShadSelect` (Today, Tomorrow, Yesterday, In the past week, In the past month, In the past year, Exact date → `ShadDatePicker`); any value may be a formula starting with `=` (switches the input to `FormulaEditor`). Emits a `Condition`. Validation messages inline. | filters, filter views, DV, CF (06), pivot filters, slicers |
| `ValueChecklist` | Search input + "Select all · Clear" links + virtualized checkbox list of distinct **display values** with counts (`(Blanks)` first), sorted by the column's sort order; shows "Showing 1,000 of 52,311 values — refine your search" beyond 1,000 rows per search page; keyboard (↑/↓, Space toggles, Enter = OK). Emits a hidden-values set. | filters, filter views, slicers, pivot filters |
| `ColorFilterPicker` | Two sections *Fill color* / *Text color* listing distinct effective colors present in the column (swatches with names); single select. | filters (P1), sort by color (P2) |
| `SortSpecList` | Reorderable list of `{column select, A→Z / Z→A radio}` rows with ✕ and "+ Add another sort column". | sort dialog, pivot |
| `UserMultiSelect` | Checkbox list of the file's editors (avatar, name, email from sharing) + "Add editors" input with autocomplete. | protection permissions |
| `HistogramView` | Small bar chart (rendered with the own chart engine's `ChartScene`, see [08](08-charts-and-objects.md)) using the `chart1` token, tooltips with bucket range & count, keyboard focusable bars. | column stats |
| `PivotFieldList` / `PivotFieldCard` | Field picker (search + list of source columns with type icons) and the per-field option cards in the pivot editor (§7.3). | pivot editor |

### 1.4 Background jobs

Long operations run as a `DataJob` (`data_tools/jobs/data_job.dart`):

1. **Compute phase** — pure function over immutable column snapshots, run through
   `ComputeOffload` ([05 §10.3](05-formula-engine.md#103-offload-jobs)) when above its threshold;
   reports progress (0–1) and honours a `CancellationToken`.
2. **Write phase** — session write, chunked into ops of ≤ 5,000 row changes (one group), still
   one undo step. Cancelling during writes rolls back the already-written chunks by applying their inverse
   (the job ends with no net change and no undo step).

`DataJobRunner` shows a `ShadSonner` toast after 500 ms ("Sorting 412,000 rows… 37 %" with
*Cancel*) and a status-bar spinner. Only one write job per spreadsheet at a time; a second
request queues (toast "Waiting for the current operation to finish"). MCP calls of job-backed
commands await completion (timeout 120 s, then return `{status: running, job_id}`; pollable via
`ui.wait_for`).

---

## 2. Sort

### 2.1 Entry points

| Entry | Command | Notes |
|-------|---------|-------|
| Data › Sort sheet › Sort sheet by column X (A→Z / Z→A) | `sheets.data.sortSheet {colId, ascending}` | Range = all rows **below the frozen rows** × all columns of the sheet |
| Data › Sort range › Sort range by column X (A→Z / Z→A) | `sheets.data.sortRange {range, colId, ascending}` | Range = selection (single range, ≥ 2 rows) |
| Data › Sort range › Advanced range sorting options | `sheets.data.openSortDialog` → `sheets.data.sortRange {range, specs, hasHeader}` | 04 §11.5 |
| Column header context menu › Sort sheet A→Z / Z→A | `sheets.data.sortSheet {colId, ascending}` | 04 §9.3 |
| Basic filter column menu › Sort A→Z / Z→A | `sheets.filter.sortColumn {colId, ascending}` | Range = filter range minus its header row; also writes `BasicFilter.sortJson` (§3.8) |
| Filter view column menu › Sort | `sheets.filterView.sortColumn {viewId, colId, ascending}` | **view-only**, no data change (§4.4) |
| Sort by color (P2) | `sheets.data.sortRange {…, specs: [{colId, fillColor or textColor: hex}]}` | Rows with the color first |

`specs` = `[{colId, ascending: bool} | {colId, fillColor | textColor}]`, max = number of columns
in the range; `hasHeader` excludes the first row of the range. If the selection is a single cell,
`sortRange` expands to the data region (03 `DataEdgeFinder`) and asks (header detection, §2.6).

### 2.2 Decision: one semantics, two physical strategies

**Semantics (always, Google parity)**: references keep pointing at **positions** — a formula
elsewhere that reads `B5` reads whatever record lands in row 5; ranges (formula ranges and every
id-based `GridRange`: CF, DV, banding, protected/named ranges, charts, pivot sources, filters,
slicers, groups) keep covering the **same block of positions**; formulas inside moved rows get
**copy semantics** (§2.5). Users therefore see exactly Google's results, whichever strategy runs.

**Physical strategies** (chosen automatically by `SortPlanner`):

| | A. Row-entity reorder (**full-row sorts**) | B. Content move (**partial-range sorts**) |
|---|---|---|
| Eligible when | the sorted rows have **no cells outside the sort range's columns** (always true for *Sort sheet*, whole-row selections, and tables whose rows are empty beyond the table) and no vertical merges | otherwise |
| Main writes | permute the existing set of `SheetRow.sortKey`s among the rows (n `sortKey` writes; the block keeps its place in the sheet) | write every cell whose content changes (all `Cell` fields of the slice) |
| Fix-up writes in the same step | (1) **re-pin** id-based range endpoints that point at rows inside the block to the id now at the same position (`ReferenceRewriter.repinPermutation`, uses the graph's endpoint index 05 §8.3 and the `RuleIndex`); (2) re-pin single-cell references from **outside** the block into it; (3) rewrite formulas **inside** moved rows only when copy semantics differ from following their own row (refs to other rows of the block, absolute refs) | none (positions never change identity) |
| Travels with the row | cells, notes, row height, row format, hidden flag, **comments, cell history and concurrent offline edits** (they target row ids) | cell fields only; comments re-anchored per [10 §3.2](10-collaboration-history.md) |
| Concurrent sorts of the same rows | `sortKey` LWW per row → final order = the later sort's order ([10 §10](10-collaboration-history.md) scenario 8) | per-cell LWW, may look unsorted → sort again (01 §4 rule 6) |

Why not entity reorder everywhere: rows span all columns, so a partial-width sort cannot move
row entities; and without re-pinning, any range whose boundary row moved would silently change
coverage (e.g. a CF rule on `A2:A1000` whose first row moves to position 57). Why not content move
everywhere: for full-row sorts it writes rows × columns cells instead of n keys, and an offline
collaborator's edit to a sorted row would land on whatever record now occupies that position;
entity reorder keeps such edits, comments and cell history on the right record.

### 2.3 Ordering

`SortKeys.compare` (core) — Google Sheets ordering, stable:

1. **Numbers** (dates and times are numbers) ascending.
2. **Text**: case-insensitive comparison using a deterministic collation key (Unicode
   NFKD → strip combining marks → simple case folding, then the original string ordinal as tie-
   breaker), so "apple" < "Banana" < "cherry", "é" sorts with "e". Digits in text compare
   character-wise (no natural sort, Sheets parity). One implementation, `Collation`
   (`formula/values/collation.dart`, LRU-cached keys), shared by `SORT()`/`SORTN()`, Data › Sort,
   filter views and pivot groups (CQ-50; `SORT()` computes the keys once per row).
3. **Booleans**: FALSE < TRUE.
4. **Errors** (by `ERROR.TYPE` code).
5. **Blank cells always last**, in both ascending and descending order (Sheets parity). A formula
   returning `""` is blank for sorting.

Descending reverses groups 1–4 (blanks still last). Values used are **computed values** (formula
results); spill overlay cells cannot be sorted (a range containing spill output or pivot output
is refused: "You can't sort a range that contains part of an array result or pivot table").
Multi-key: compare by spec order, then original row index (stability).

### 2.4 What moves

| Moves with the record | Stays at the position |
|-----------------------|-----------------------|
| Cell `content` (formulas per §2.5), `note`, every format attribute, `linkUrl`; comments (strategy A: automatically via row ids; B: re-anchored like cut & paste, 10 §3.2) | CF/DV/banding/protection/named/chart/pivot/filter/group ranges (re-pinned in A; untouched in B) |
| Strategy A only: row height, row `formatJson`, row `hidden` flag | Strategy B: row heights, row formats, hidden flags |

Refusals (dialog, nothing written): range intersects a vertical merge ("Can't sort a range with
vertically merged cells"), contains spill/pivot output (§2.3), or protected cells the user can't
edit (§10). Rows hidden by the user, by filters or by collapsed groups **are sorted too** (Sheets
parity). Horizontal (single-row) merges move with their row.

### 2.5 Formulas in moved rows

A formula moving from row *i* to row *j* behaves as if copied: relative row references shift by
*j − i*, absolute (`$`) ones stay (`FormulaCodec.translate(stored, from: (i, c), to: (j, c))`).
A formula referencing its own row (`=B2*C2`) keeps referencing its own row. In strategy A the
planner computes the translated text against the post-sort axis and writes the cell only if it
differs from the stored text (own-row references already follow the row id, so most formulas need
no write). References from outside the block keep pointing at positions (they see the new data).

### 2.6 Header handling

- `sortSheet` excludes `Sheet.frozenRows` from the range; if `frozenRows == 0` and the first row
  "looks like a header" (`HeaderDetector`: every non-empty cell in row 1 is text and at least one
  column below has a different dominant type), a toast offers *"Freeze row 1 and re-sort"*
  (`sheets.view.freezeRows {count: 1}` + re-run as one step).
- The advanced dialog pre-checks *Data has header row* using `HeaderDetector`.

### 2.7 Execution

```
SortPlanner.plan(range, specs, hasHeader) → SortPlan {strategy: rowReorder | contentMove,
                                                     permutation: Int32List, writes: WriteBatch}
```

1. Snapshot key columns (computed values) as typed arrays + collation keys (`sort_keys.dart`).
2. Compute a stable permutation (TimSort over indices). > 50k rows → offloaded job (§1.4).
3. Choose the strategy (§2.2) and build writes:
   - *rowReorder*: new `sortKey` per row (existing keys reassigned, `columnValues: ['sortKey']`),
     re-pinned `GridRange` JSON columns, re-pinned/rewritten formula cells (`['content']`).
   - *contentMove*: for each target position whose source differs, write all cell fields of the
     source (or delete the target cell when the source is empty), naming the changed columns
     (02 S8); unchanged positions are skipped.
4. Execute in chunks as one undo step labelled "Sort range" / "Sort sheet".
5. Undo entry: ≤ 20k changed rows/cells → the normal `RowChange` list; above that a compact
   `PermutationUndoEntry {range, strategy, permutation, hashes}` whose undo applies the inverse
   permutation, skipping rows/cells whose current value differs from what the sort wrote (suite 08
   §3.3 rule).

The shared row-move planner (`data_tools/move/row_move_plan.dart`) is reused by randomize (§14) and
remove duplicates (§12.1).

### 2.8 Concurrency and side effects

- Strategy A merges well with offline edits (they target row ids); strategy B's caveats are listed
  in §2.2 and in the user-facing collaboration rules ([01 §4](01-overview.md)).
- Comments: A needs nothing (anchors use row ids, 10 §3.2); B re-anchors threads of moved cells
  exactly like cut & paste (10 §3.2, `comment.updateAnchor` in the `comments` undo domain).
- `BasicFilter.sortJson` is updated by `sheets.filter.sortColumn` only (sort indicator).

### 2.9 Acceptance criteria

- [ ] Sort sheet by column B (A→Z) with 1 frozen row: header stays; numbers, then text
      (case-insensitive), then booleans, then errors; blanks at the bottom in both directions.
- [ ] `=B2*2` in C2 moved to C5 becomes `=B5*2`; `=$B$2` stays; `=SUM(A2:A10)` elsewhere is
      unchanged and shows the same sum; a CF rule on `A2:A1000` still covers `A2:A1000`.
- [ ] *Sort sheet* on a 3-column table writes only `sortKey`s (plus re-pinned ranges); a comment on
      a sorted row stays with its record; a collaborator's offline edit to that row lands on the
      same record after sync.
- [ ] Sorting B2:D20 leaves column A and rows outside untouched; notes and formats move.
- [ ] Sorting 500k rows × 10 columns shows progress, can be cancelled during compute without
      changes, and is a single undo step whose undo restores the original order.
- [ ] A range with a vertical merge or spill output is refused with the documented message.

---

## 3. Basic filter

### 3.1 Concepts

| Kind | Stored | Who sees it | Who can change | Affects formulas (SUBTOTAL/AGGREGATE) |
|------|--------|-------------|----------------|---------------------------------------|
| **Basic filter** (one per sheet) | `BasicFilter` (synced, id = `SheetsIds.basicFilterId(sheetId)`) | everyone | editors | **yes** |
| **Filter view** (named, many) | `FilterView` (synced) | anyone who activates it (URL `?fv=<id>`) | editors (definition); everyone can activate | no |
| **Temporary filter view** | `LocalViewState` (local only) | only its creator, this device | its creator (incl. viewers) | no |
| **Slicer** (§5) | `EmbeddedObject(kind: slicer)` | everyone | editors (viewers: local override) | yes (filters its range like the basic filter) |

Filter views and temporary views never change formula results, keeping computed values identical
on every client (05 §12).

### 3.2 Criteria model (`BasicFilter.criteriaJson`, `FilterView.criteriaJson`)

```jsonc
{
  "<colId>": {                                   // column inside the filter range
    "hiddenValues": ["Closed", ""],              // display texts to hide ("" = blanks)
    "condition": {"type": "numberGreater", "values": [{"v": "100"}]},   // §3.3, optional
    "visibleBackgroundColor": "#F4CCCC",         // P1, optional (exact effective fill color)
    "visibleForegroundColor": null               // P1, optional (effective text color)
  }
}
```

- A row is visible iff, for **every** column with criteria, the cell passes: not in
  `hiddenValues` **and** satisfies `condition` (if any) **and** matches the color criteria (if
  any). Google allows either values or condition per column in the UI; the model allows both
  (MCP/XLSX import) and ANDs them.
- `hiddenValues` match the cell's **display text** (formatted value, as listed in the
  `ValueChecklist`), case-sensitive exact match; blanks are `""`.
- `sortJson` (`[{colId, ascending}]`) on `BasicFilter` records the last sort applied through the
  filter menu (indicator only, §3.8); on `FilterView` it is the view's display order (§4.4).
- Column ids that no longer exist are ignored (and removed by the next edit of the filter).

### 3.3 `Condition` model (shared with CF, DV, slicers, pivot filters)

One condition model and one evaluator (`wonky_sheets_core/lib/rules/conditions/`) serve conditional
formatting, data validation, filters, filter views, slicers and pivot filters. The JSON shape and
the semantics of the common types are defined in
[06 §15.1–15.3](06-formatting.md#15-conditional-formatting) and reused verbatim:

```jsonc
{ "type": "numberGreater", "values": [ { "v": "100" } ] }          // literal (parsed per locale)
{ "type": "numberBetween", "values": [ { "v": "1" }, { "v": "=⟦R:…;C:…⟧" } ] }   // formula, stored form
{ "type": "dateAfter", "values": [ { "rel": "pastWeek" } ] }      // relative date
{ "type": "customFormula", "values": [ { "v": "=⟦C:…;$C⟧2>100" } ] }
```

| `type` | Values | UI label (Google wording) | Filters | CF (06) | DV (§6) |
|--------|--------|---------------------------|---------|---------|---------|
| `blank` / `notBlank` | — | Is empty / Is not empty | ✓ | ✓ | — |
| `textContains` / `textNotContains` | 1 | Text contains / does not contain | ✓ | ✓ | ✓ |
| `textStartsWith` / `textEndsWith` | 1 | Text starts with / ends with | ✓ | ✓ | — |
| `textEq` | 1 | Text is exactly | ✓ | ✓ | ✓ |
| `textIsEmail` / `textIsUrl` | — | Text is valid email / Text is valid URL | — | — | ✓ (defined here) |
| `dateEq` / `dateBefore` / `dateAfter` | 1 (`rel` or date) | Date is / is before / is after | ✓ | ✓ | ✓ |
| `dateOnOrBefore` / `dateOnOrAfter` | 1 | Date is on or before / on or after | — | — | ✓ (defined here) |
| `dateBetween` / `dateNotBetween` | 2 | Date is between / not between | — | — | ✓ (defined here) |
| `dateIsValid` | — | Is valid date | — | — | ✓ (defined here) |
| `numberGreater` / `numberGreaterEq` / `numberLess` / `numberLessEq` | 1 | Greater than / … | ✓ | ✓ | ✓ |
| `numberEq` / `numberNotEq` | 1 | Is equal to / Is not equal to | ✓ | ✓ | ✓ |
| `numberBetween` / `numberNotBetween` | 2 | Is between / Is not between | ✓ | ✓ | ✓ |
| `customFormula` | 1 (formula) | Custom formula is | ✓ | ✓ | ✓ |
| `oneOfList` / `oneOfRange` / `checkbox` | §6.1 | Dropdown / Dropdown (from a range) / Checkbox | — | — | ✓ (§6.1 shape) |

Semantics summary (authoritative text in 06 §15.2–15.3): text conditions compare the value
converted to text with Automatic rules (not the formatted display), case-insensitively; number
conditions apply to numeric values only (`numberNotEq` is true for non-numeric cells); date
conditions require numeric (date) values; relative dates use `Spreadsheet.timeZone` and are
re-evaluated at midnight. DV-only types: `textIsEmail` (RFC 5322 simplified: `local@domain.tld`),
`textIsUrl` (http/https/ftp or `www.` hosts), `dateIsValid` (numeric value with a date/time
format hint or date-parseable text), `dateOnOrBefore/After`, `dateBetween/NotBetween` (inclusive).

**Custom formula and `=` values**: relative references are relative to the top-left cell of the
rule's (first) range — for filters, the first **data** cell of the column. Evaluation uses
`FormulaEngine.compileRelative(stored, anchorCell)` once per rule and evaluates per cell with a
row/column offset (05 §7.1), registering a `ConditionNode` in the dependency graph (05 §8.1) so
results refresh after recalcs. Truthy (`TRUE` or non-zero number) passes; errors, text and empty
fail.

Filters additionally have **values criteria** (`hiddenValues`, §3.2) that match the formatted
**display text**, exactly as listed in the checklist.

### 3.4 Filter engine

`FilterEngine.compute(FilterInput) → RowVisibility` (core, pure):

- Input: filter range resolved to indices, criteria, column snapshots of **computed values +
  display texts** (display text from the number-format engine, 06), effective colors (for color
  criteria).
- Output: a `BitSet` over the range's data rows (header row always visible). The sheet's
  `FilterVisibilityService` (Flutter) combines layers: user-hidden ∪ group-collapsed ∪
  basic-filter-hidden ∪ slicer-hidden **or**, when a filter view is active, user-hidden ∪
  group-collapsed ∪ view-hidden. The grid's `AxisIndex` Fenwick sizes use the combined mask
  (hidden = 0 px).
- **Live re-filtering**: the mask is recomputed incrementally when cells in filtered columns change
  (only changed rows re-evaluated; `customFormula` and relative-date conditions re-evaluate their
  column after each recalc batch). Rows therefore hide/show immediately when edits make them
  (non)matching — deterministic across clients (unlike Sheets' "sticky" rows).
- **Sticky edit row (UX only)**: when the local user edits a cell so that its row no longer
  matches, the row stays visible **on this device only** (dimmed 50 %, row header shows a
  `LucideIcons.filterX` badge, tooltip "This row no longer matches the filter") until the
  selection leaves the row. It does not affect `SUBTOTAL` or other clients.
- `SUBTOTAL`/`AGGREGATE` read only the deterministic mask (basic filter + slicers + user-hidden
  + collapsed groups for 1xx codes), via `FilterDep` (05 §8.2).
- Performance: values criteria use a `ValueIndex` (display text → row bitset, built per column on
  first use, maintained incrementally) so toggling a checklist value is O(rows with that value).
  1M rows: initial compute < 300 ms native / < 800 ms web (offloaded above 100k rows).

### 3.5 UI

**Filter header buttons**: when a basic filter exists, each header cell of the filter range shows
a filter button (painted by 03's decoration layer): outline funnel; **filled funnel in `primary`**
when the column has criteria; sort arrow when `sortJson` names the column. The filter range gets
a 2 px `success`-token outline (Google's green) while the filter is on and the selection is inside
it; row headers of filtered sheets show hidden-row boundaries as in 03 §3 (no unhide arrows for
filter-hidden rows).

**Column popover** (`FilterColumnPopover`, `ShadPopover` 280 × ≤ 520 px, anchored to the button):

```
┌──────────────────────────────────┐
│ Sort A → Z                       │
│ Sort Z → A                       │
│ Sort by color ▸ (P2)             │
│──────────────────────────────────│
│ ▸ Filter by color (P1)           │  (ColorFilterPicker)
│ ▸ Filter by condition            │  (ConditionEditor, filter subset)
│ ▾ Filter by values               │
│   Select all 2,031 · Clear       │
│   [🔍 Search            ]        │
│   ☑ (Blanks)              12     │
│   ☑ Closed               503     │
│   ☐ Open                 911     │
│   …                              │
│──────────────────────────────────│
│                   [Cancel] [OK]  │
└──────────────────────────────────┘
```

- Sections are `ShadAccordion`s (one open at a time; the section that has criteria opens first).
- *OK* commits `sheets.filter.setColumnCriteria {colId, criteria}` (1 step). Live preview while
  the popover is open is **local only** (grid applies the draft mask); *Cancel*/Esc discards.
- Values list is built from the column's distinct display texts **considering the other columns'
  criteria** (values hidden by other columns are listed greyed under "Hidden by other filters",
  Sheets parity) — computed in background for > 100k rows with a skeleton.
- Search filters the list; *Select all*/*Clear* apply to the search results only (Sheets parity).
- Keyboard: the popover opens with **Mod+Alt+R** on the active header cell (Google) or Enter on a
  focused filter button; Tab cycles sections.

### 3.6 Creating, changing and removing the basic filter

- `sheets.filter.toggle` (Data › Create a filter / Remove filter, toolbar funnel, column header
  menu; ⌥⇧⌘L / Ctrl+Alt+Shift+L per 04):
  - Create: range = selection if it is a multi-cell range, else the **data region** around the
    active cell (`DataEdgeFinder`). If the region extends to the last used row of the sheet, the
    stored range is **open-ended** (`r2` omitted) so rows appended below are included; otherwise
    bounded. The first row is the header row.
  - Remove: deletes the `BasicFilter` row (criteria lost; undo restores). Hidden rows reappear.
- `sheets.filter.setRange {range}` (select a new range, Data › Create a filter while a filter
  exists offers *Change range*): keeps criteria for columns still inside.
- `sheets.filter.clearColumn {colId}` / `sheets.filter.clearAll`.
- `sheets.filter.saveAsFilterView` — creates a `FilterView` with the same range/criteria/sort
  (Data › Filter views › Save as filter view) and activates it.
- Inserting rows inside the filter range extends it automatically (ids, 02 S2); deleting the
  header row deletes the filter (02 §8 invariant; undo restores).
- Viewers: `sheets.filter.toggle` and criteria commands are disabled with reason "You have view
  access — use a temporary filter view" and a button that runs `sheets.filterView.create
  {temporary: true}` with the same criteria.

### 3.7 Effects of filter-hidden rows elsewhere

| Feature | Behavior |
|---------|----------|
| Copy (03 §12.2) | copies visible rows only |
| Paste / fill | writes through hidden rows (Sheets parity, 03) |
| Selection stats (status bar) | visible cells only |
| `SUBTOTAL` 1–11 / 101–111, `AGGREGATE` | ignore basic-filter/slicer-hidden rows |
| Charts | follow chart option "Show hidden data" (08) |
| Pivot tables | **not** affected (use all source rows) unless a slicer targets them |
| Sort | sorts hidden rows too (§2.4) |
| Find | skips hidden rows when navigating; Replace all includes them (§11.3) |
| Delete rows | `sheets.rows.delete` on a selection spanning hidden rows deletes only visible rows (Sheets parity; dialog "Delete N visible rows?") |

### 3.8 Sort from the filter menu

`sheets.filter.sortColumn {colId, ascending}` = `sortRange` over the filter range without its
header (all rows, hidden included), plus writing `BasicFilter.sortJson = [{colId, ascending}]` in
the same step. The sort is **not** re-applied automatically when data changes (Sheets parity).

### 3.9 Concurrency

- `BasicFilter` has a deterministic id per sheet, so two users creating a filter offline merge
  into one row; `rangeJson`, `criteriaJson`, `sortJson` are LWW per column. Concurrent edits of
  **different columns' criteria** both live in `criteriaJson` → the later write wins for the whole
  JSON (documented; a column-level merge would need one row per column — P2 option:
  `BasicFilterColumn` rows keyed by `UUIDv5(filterId, colId)`).
- Filter-hidden state is never synced; it is recomputed on each device from synced data.

### 3.10 Acceptance criteria

- [ ] Creating a filter on a single cell inside a table selects the data region, header row gets
      buttons; filtering "Status" values hides rows on all collaborators' screens within sync
      latency; `=SUBTOTAL(9, C2:C100)` changes accordingly on all devices identically.
- [ ] Filter by condition "Greater than 100" and by values combine across columns (AND).
- [ ] Editing a visible row so it no longer matches keeps it visible (dimmed) for the editor until
      they move away, and hides it immediately for others.
- [ ] A viewer cannot change the basic filter but can open a temporary filter view with one click.
- [ ] 1M-row sheet: applying a values filter completes in < 1 s native and the UI stays responsive.

---

## 4. Filter views (P1)

### 4.1 Model

`FilterView {sheet, name, rangeJson, criteriaJson, sortJson?, createdBy}` (02) — criteria schema
§3.2. Temporary views live in `LocalViewState.temporaryFilterViews` (§22) with the same JSON plus
`{tempId, name: "Temporary filter 1"}`.

The **active** filter view is per user and device (`LocalViewState.activeFilterViewId[sheetId]`),
reflected in the route as `/s/<uuid>?fv=<filterViewId>` (same URL family as 03 §12/§19
"Get link to this cell" `/s/<uuid>?sheet=<id>&range=B4`). Opening such a link
activates the view if it exists (else toast "This filter view no longer exists").

### 4.2 UI

- Data › Create filter view (`sheets.filterView.create`): editors create a **saved** view (name
  "Filter 1", range = basic filter range or data region); viewers/commenters create a
  **temporary** view. Toolbar filter split button lists views (04 §5 item 28).
- Active view chrome: the column/row headers turn **dark** (`gridHeaderBg` replaced by
  `foreground` at 85 % with `background` text — readable in both themes) and a **filter view bar**
  appears above the column headers:

```
┌ Name: [Filter 1          ]  Range: [A1:F2000 ⊞]   ⋮   ✕ ┐
```

  `⋮` menu: Rename, Update range, Duplicate, Copy link, Save view (temporary only; editors), Delete.
  ✕ closes the view (`sheets.filterView.activate {viewId: null}`).
- Panel `sheets.panel.filterViews` (Data › Change view ▸ Manage): list of saved views of the sheet
  with search, creator avatar, *Open*, *Duplicate*, *Delete*. **As built:** the active view's row
  has a *Range* field (`RangeInput` with picking, 04 §13): selecting on the grid while it is
  focused writes the range live; `sheets.filterView.setRange` runs when picking ends (saved view:
  1 step; temporary: local).
- Filter buttons and column popovers work as for the basic filter but call
  `sheets.filterView.setColumnCriteria {viewId, colId, criteria}` (saved view: synced write, 1 step;
  temporary: local state, not undoable).

### 4.3 Semantics

- While a view is active, the basic filter's hidden rows are **not** applied in this user's grid
  (the view replaces it); formulas still use the basic filter (§3.1).
- Editing cells inside a filter view edits the real cells (normal writes).
- Saved views are visible to everyone with access; anyone with edit access can modify them (Sheets
  parity). Changes to a view another user is looking at apply live for them.
- Deleting a view others have active: their view closes with toast "Filter view was deleted".

### 4.4 View-only sort order

Sorting inside a filter view (`sheets.filterView.sortColumn`) does **not** move data. It sets the
view's `sortJson` and the grid displays the view's data rows in sorted order through a
`ViewRowOrder` (core `data_tools/filter/view_row_order.dart`): a permutation of the range's row indices
recomputed with `SortKeys` when data changes (debounced 300 ms). Requirement for 03: the grid's
row axis must support a **display permutation within a contiguous range** (`RowDisplayMap
{int modelRow(int displayRow); int displayRow(int modelRow)}` layered on `AxisIndex`); row headers
show the **model** row numbers (so users see that rows are reordered); keyboard navigation and
selection operate in display order; formulas/selections store model positions. Temporary views
support the same. (Open question §23 if 03 cannot support permutations in M3 — fallback: views
only filter, sort disabled with tooltip.)

> **As built.** The column popover's *Sort A → Z / Z → A* in a view run
> `sheets.filterView.sortColumn {viewId, colId?, ascending}` (saved view: `UpdateFilterView
> {sortJson}`, 1 step; temporary: local; no `colId` clears it; sort by color stays basic-filter
> only). The view bar shows "Sorted by ‹header› ✕". `FilterController.rowOrder` builds a
> `ViewRowOrder` (core `ViewRowOrder.forRows`: the sort comparator over computed values; refused
> over vertical merges) and installs it as `GridHooks.rowOrder`; it is rebuilt when the view, its
> sort or the rows change and 300 ms after data changes. The grid works in that order:
> `GridGeometry(rowOrder)` maps display ⇄ model rows (`displayRow`/`modelRow`, display offsets
> with prefix sums of the permuted sizes, hit testing, `scrollToReveal`); `GridPane` keeps model
> rows in its API (`y`, `cellRect`, `cellAt`) and adds `rows` (the model rows shown, in display
> order, used by the gridline/fill/content/border/header/semantics/DV/find/image layers),
> `isRowShown`, `bottomOf`, `displayRangeRect`; other layers keep `rowStart..rowEnd`, which then
> bound the model rows shown. Row headers show model numbers. Selecting on screen (drag,
> Shift+arrows/click, row-header drags) stores **display ranges** (`SelectionRange.display`): they
> resolve to the model rows shown as several ranges (runs adjacent in both orders, in display
> order; `ResolvedSelectionRange.displayRect`/`group`, `ResolvedSelection.isSingleGroup`), painted
> as one rectangle; commands get the model runs. Arrow keys, Enter, PageUp/Down and Mod+↑/↓ (the
> block's first/last row) follow the screen order. Copy of a display range copies its rows in
> display order (`ClipboardEncoder.copy(rowOrder:)`, DV/CF rules not carried); paste and
> Mod+D fill the rows shown below in display order, one undo step (`ViewSortEditing`); cut, the
> fill handle, moving cells and dragging rows are off inside a sorted block (cut asks to copy;
> a cut can't be pasted into it). Temporary views' sort isn't kept across reloads.

### 4.5 Commands

`sheets.filterView.create {temporary?, fromBasicFilter?}`, `sheets.filterView.activate
{viewId?}`, `sheets.filterView.rename {viewId, name}`, `sheets.filterView.setRange {viewId,
range}`, `sheets.filterView.setColumnCriteria {viewId, colId, criteria}`,
`sheets.filterView.sortColumn {viewId, colId, ascending}`, `sheets.filterView.duplicate {viewId}`,
`sheets.filterView.save {tempId}` (temporary → saved), `sheets.filterView.delete {viewId}`,
`sheets.filterView.copyLink {viewId}`, `sheets.filterView.openPanel`. Undoable: all saved-view
mutations (1 step); activation and temporary-view changes are view state (not undoable).

### 4.6 Acceptance criteria

- [ ] Two users activate different filter views of the same sheet simultaneously; each sees only
      their view's rows; a third user without a view sees the basic filter.
- [ ] Sorting in a view reorders only the viewer's display; the data and others' screens are
      unchanged; `SUBTOTAL` results are unchanged.
- [ ] Opening `/s/<uuid>?fv=<id>` activates the view; a viewer can create, use and discard a
      temporary view; it survives reload on the same device.

---

## 5. Slicers (P2)

- Insert: Data › Add a slicer (`sheets.slicer.add`) creates an `EmbeddedObject(kind: slicer)`
  anchored near the selection (object layer, move/resize/delete/copy: [08 §18](08-charts-and-objects.md)),
  opens panel `sheets.panel.slicer`.
- `specJson` (`SlicerSpec`, addition D4):

```jsonc
{
  "v": 1,
  "dataRange": {"s": "…", "r1": "…", "c1": "…", "c2": "…"},   // GridRange incl. header row
  "colId": "…",                                                // column to filter
  "criteria": {"hiddenValues": [], "condition": null},         // §3.2 per-column criteria
  "title": "Region",
  "applyToPivotTables": true,
  "style": {"backgroundColor": "#FFFFFF", "textColor": "#202124", "fontFamily": null,
            "fontSize": 10, "bold": false, "italic": false, "titleAlign": "left"}
}
```

- Semantics: a slicer filters **its data range for everyone** as an additional AND layer next to
  the basic filter (hidden rows computed like §3.4, deterministic, counted by `SUBTOTAL`). Charts
  whose source range equals or lies within the slicer's data range use the filtered rows; pivots
  with the same source range are filtered when `applyToPivotTables`.
- Interaction: clicking the slicer opens `SlicerPopover` (same content as the filter column
  popover: values/condition). Editors' changes write `criteria` (1 step, "Set slicer filter").
  **Viewers'** changes are local overrides (`LocalViewState.slicerOverrides[objectId]`), applied
  only on their screen (and not to formulas). Editors can *Set current filters as default*
  (`sheets.slicer.setDefault`) — i.e. persist their working criteria.
- Panel: Data tab (range `RangeInput`, column `ShadSelect`, apply to pivot tables), Customize tab
  (title, font, colors via `WonkyColorPicker`).
- Commands: `sheets.slicer.add`, `sheets.slicer.edit {objectId}` (08), `sheets.slicer.update
  {objectId, spec}`, `sheets.slicer.setCriteria {objectId, criteria}`, `sheets.slicer.setDefault`,
  `sheets.slicer.reset`.
- Acceptance: a slicer on Region hides non-matching rows for all users and updates a chart and a
  pivot on the same data; a viewer's slicer change affects only their view.

---

## 6. Data validation

### 6.1 Model

`DataValidationRule {sheet, rangesJson, criteriaJson, strict, showDropdown, displayStyle,
helpText}` (02 §3.5). `rangesJson` is a list of `GridRange`. `criteriaJson`:

```jsonc
// Dropdown (list of items)
{"type": "oneOfList",
 "options": [{"value": "Open", "bg": "#D4EDBC", "fg": "#11734B"},
             {"value": "Closed", "bg": "#FFCFC9", "fg": "#B10202"}],
 "allowMultiple": false}                                        // P2
// Dropdown from a range (items = distinct display values of the range, in order)
{"type": "oneOfRange", "range": {"s": "…", "r1": "…", "r2": "…", "c1": "…", "c2": "…"},
 "colors": {"Open": {"bg": "#D4EDBC", "fg": "#11734B"}}, "allowMultiple": false}
// Checkbox (both values omitted = TRUE/FALSE)
{"type": "checkbox", "checked": "Yes", "unchecked": "No"}
// Any DV-capable Condition from §3.3
{"type": "numberBetween", "values": [{"v": "1"}, {"v": "=⟦R:…;C:…⟧"}]}
{"type": "customFormula", "values": [{"v": "=AND(ISNUMBER(⟦…⟧), ⟦…⟧>0)"}]}
```

- `displayStyle` ∈ `chip` (default for dropdowns), `arrow`, `plainText`; `showDropdown` is kept
  equal to `displayStyle != plainText` for older readers.
- Formula values (`=…`) are stored in stored form (05 §5), relative to the top-left cell of the
  **first** range in `rangesJson`.
- Option colors are absolute (user data); new options get colors cycling through a 10-entry
  palette (light pastel bg + dark fg pairs, Google's chip palette); "No color" allowed.

### 6.2 Criteria and messages

Default invalid message (shown in the reject dialog and invalid-marker tooltip unless `helpText`
is set):

| Criteria | Message |
|----------|---------|
| `oneOfList`, `oneOfRange` | Input must be an item on the specified list |
| `numberBetween` / `numberNotBetween` | Input must be a number between 1 and 10 / not between 1 and 10 |
| `numberGreater`, `…GreaterEq`, `…Less`, `…LessEq`, `…Eq`, `…NotEq` | Input must be greater than 5 / greater than or equal to 5 / less than 5 / … / equal to 5 / not equal to 5 |
| `textContains` / `textNotContains` / `textEq` | Input must contain "x" / must not contain "x" / must be exactly "x" |
| `textIsEmail` / `textIsUrl` | Input must be a valid email address / a valid URL |
| `dateIsValid` | Input must be a valid date |
| `dateEq`, `dateBefore`, `dateAfter`, `dateOnOrBefore`, `dateOnOrAfter`, `dateBetween`, `dateNotBetween` | Input must be a date on / before / after / on or before / on or after / between … and … / not between … |
| `checkbox` | Input must be TRUE or FALSE (custom: Input must be "Yes" or "No") |
| `customFormula` | Input must satisfy the specified formula |

Rules: **empty cells are always valid** (Sheets); values are the cell's computed value (formula
results are validated too); list items match the cell's display text exactly (case-sensitive,
Sheets dropdown behavior), except that numeric items also match numerically equal numbers
(`"1.50"` matches 1.5). Condition-based criteria follow §3.3.
Multi-select (P2) values are stored as text joined by `", "` and each part must be an item.

### 6.3 Panel (`sheets.panel.dataValidation`)

```
Data validation rules                               ✕
┌ A2:A500  ● Open ● Closed ● Blocked     ──── ┐   (rule list; click to edit)
└ C2:C500  Checkbox                       ──── ┘
[+ Add rule]                [Remove all in selection]

── editing a rule ───────────────────────────────────
Apply to range   [Sheet1!A2:A500 ⊞]  [+ Add another range]
Criteria         [Dropdown ▾]
                 ● [Open      ] [🎨]  ⠿ ✕
                 ● [Closed    ] [🎨]  ⠿ ✕
                 [Add another item]
▾ Advanced options
  If the data is invalid:  (•) Show a warning  ( ) Reject the input
  ☐ Show help text for a selected cell   [textarea]
  Display style:  (•) Chip  ( ) Arrow  ( ) Plain text
  ☐ Allow multiple selections (P2)
[Remove rule]                                [Done]
```

- Criteria `ShadSelect` groups: Dropdown, Dropdown (from a range), Text…, Date…, Number…,
  Checkbox, Custom formula is — editors per type via `ConditionEditor`, the options editor (drag to
  reorder, color per option via `WonkyColorPicker` with "No color"), `RangeInput`, or checkbox
  values (☐ Use custom cell values → *Checked* / *Unchecked* inputs).
- Draft semantics per [04 §10](04-screens-menus-toolbar.md#10-side-panels): live preview, *Done*
  commits **one undo step**, Cancel/✕ discards. Opening the panel with a selection that has no
  rule starts a new draft for the selection.
- Rule list rows show the range(s), a criteria summary and chip previews; hovering highlights the
  range on the grid.

> **As built.** The draft is previewed live on the grid (core `DvDraftPreview`: chips,
> checkboxes and invalid markers of the draft's ranges; an edited rule's other cells show no
> rule; never written and never enforced) through `DataValidationController.setDraft` →
> `DvEvaluator.draft` + `CellRenderCache.dvDraft`. Hovering or focusing a rule row outlines its
> ranges (`RangeHighlightLayer`, Enter edits, Delete removes). Items reorder by dragging the ⠿
> handle or with Alt+↑/↓ in the item field (screen readers: *Move up/down* actions). Chip colors
> come from `WonkyColorPicker` (*No color*, the palette, the 10 chip pairs as the "Chip colors"
> row, custom colors): a pair keeps its text color, any other background gets a readable text
> color of the same hue (`chipTextColorFor`). Strict
> rejection runs in the cell editor commit (`CellEditorController.commitCheck`, editor stays
> open) and as a `SheetEditorController.writeGates` gate on `SetCellInputs` of typed input
> (agents get `validation: …`); typed **formulas** are checked with their result evaluated
> detached at the cell (`FormulaEngine.evaluateDetached`, 50 ms budget; over budget they are
> accepted and marked after recalculation).

### 6.4 Applying a rule — overlap semantics

A cell has at most one effective rule (Sheets). On *Done*:

1. For every other rule of the sheet, subtract the new rule's ranges (`RangeSet.subtract`, splits
   rectangles into ≤ 4 pieces each) and delete rules whose ranges become empty.
2. Write the new/updated rule.

All in one step. If concurrent offline edits still produce overlaps, the **effective rule for a
cell is the containing rule with the greatest `(createdAt, id)`** — deterministic on every
client; the panel shows a warning icon on shadowed rules. Rules are capped at 1,000 rectangles
(further subtraction results merge into bounding rows with a toast).

`Remove all in selection` (`sheets.dv.clearRange {range}`) subtracts the selection from every
rule. Insert/delete rows/columns grow/shrink ranges via ids and 03's boundary repair.

### 6.5 Validation engine and invalid markers

- `ValidationEngine.validate(value, displayText, rule, ctx) → ValidationResult {valid, message}`
  (core), using `ConditionEvaluator` (§3.3) for conditions and `ListSource` for dropdown items.
- `InvalidMarkerService` (Flutter) computes markers **lazily for visible cells** (plus a 1-screen
  margin) and caches per cell keyed by `(contentGeneration, ruleGeneration, dependencyEpoch)`;
  rules with `oneOfRange` or formula values depend on the engine (they register `ConditionNode`s,
  05 §8.1) and are re-validated after recalc batches touching their precedents.
- Marker: `invalidTriangle` token top-right (03 §2.9/§14.2) with tooltip = help text or message.
- `ListSource` for `oneOfRange`: distinct non-empty display values in range order, max 1,000
  items (dropdown shows a search field above 7 items); updates live when the source changes.

### 6.6 Enforcement

| Write path | Strict rule (`strict: true`) | Warning rule |
|------------|------------------------------|--------------|
| Typing / formula bar / `sheets.cell.setInput` | rejected with dialog "Invalid entry — The data you entered in cell B4 violates the data validation rules set on this cell. ‹help text or message›" (03 §8.4) | committed, marked invalid |
| Dropdown pick / checkbox toggle | always valid | — |
| Paste, fill, drag-move, import, sort, find-replace | not rejected (Sheets parity), marked invalid | marked invalid |
| MCP `sheets.set_values` | cells violating strict rules are **not written**; result lists `validation_errors: [{cell, message}]`; `ignore_validation: true` writes them | written, `warnings` listed |
| Scripts (`Range.setValue`) | written, marked invalid (Apps Script parity) | written |
| Remote writes | never re-validated on receipt (just marked) | — |

### 6.7 Dropdowns and checkboxes

- Rendering & interaction are 03 §14.1–14.2 (`DropdownPickerPopover`, chips, Alt+↓, Space).
- **Insert › Dropdown** (`sheets.insert.dropdown`) creates an empty `oneOfList` rule on the
  selection and opens the panel editor with focus on the first item.
  `sheets.insert.dropdown {fromValues: true}` (*Convert to dropdown* in the column menu) builds
  options from the selection's distinct display values (≤ 500, else toast "Too many distinct
  values to convert to a dropdown") with auto colors; existing values stay.
- **Insert › Checkbox** (`sheets.insert.checkbox`) creates a `checkbox` rule and writes `b:0` into
  **empty** cells of the selection (non-empty cells keep their values and are marked invalid
  unless they equal TRUE/FALSE or the custom values) — one step.
- Custom checkbox values: checked/unchecked texts are parsed like typed input (numbers become
  numbers). Toggling writes the corresponding value.

### 6.8 Commands

| Command | Args | Undo |
|---------|------|------|
| `sheets.dv.openPanel` | `{ruleId?}` | — |
| `sheets.dv.saveRule` | `{ruleId?, ranges, criteria, strict, displayStyle?, helpText?}` | 1 |
| `sheets.dv.deleteRule` | `{ruleId}` | 1 |
| `sheets.dv.clearRange` | `{range}` | 1 |
| `sheets.dv.toggleCheckbox` (03) | `{cells?}` | 1 |
| `sheets.dv.openDropdown` (03) | — | — |
| `sheets.insert.dropdown` | `{fromValues?}` | 1 |
| `sheets.insert.checkbox` | `{checked?, unchecked?}` | 1 |

### 6.9 Acceptance criteria

- [ ] A dropdown rule with three colored options renders chips; picking via Alt+↓ writes the value;
      typing an unknown value in a strict rule shows the reject dialog and keeps the editor open.
- [ ] Applying a new rule over part of an existing rule's range splits the old rule; undo restores
      both exactly.
- [ ] A `oneOfRange` dropdown updates its items when the source range changes on another client.
- [ ] Insert › Checkbox on A1:A10 (A3 = "x") sets empty cells unchecked and marks A3 invalid;
      Space toggles all selected checkboxes.
- [ ] Custom formula `=B2>A2` on B2:B100 validates each row relative to its own row.

---

## 7. Pivot tables (P1)

### 7.1 Model

`PivotTable {sheet, anchorRowId, anchorColId, sourceRangeJson, specJson}` (02 §3.5). The source
range includes the header row (its first row). `specJson` (`PivotSpec` v1, addition D3):

```jsonc
{
  "v": 1,
  "rows":    [PivotGroup, …],
  "columns": [PivotGroup, …],
  "values":  [PivotValue, …],
  "filters": [PivotFilter, …],
  "valueLayout": "columns",            // "columns": values side by side | "rows": values stacked as an inner row level
  "showEmptyGroups": false             // P2
}
// PivotGroup
{ "source": "<colId>",                 // column id inside the source range (stable across header renames/moves)
  "label": null,                       // custom header text
  "showTotals": true,
  "order": "asc",                      // asc | desc
  "sortByValue": null,                 // {"valueIndex": 0} → sort groups by that value's total (P1)
  "repeatLabels": false,               // P1
  "group": null }                      // or {"kind":"date","unit":"yearMonth"}
                                       //    {"kind":"histogram","size":10,"min":0,"max":1000}
                                       //    {"kind":"manual","groups":[{"name":"East","items":["NY","MA"]}],"ungrouped":"Other"}
// PivotValue
{ "source": "<colId>",                 // null for calculated fields
  "formula": null,                     // calculated field, stored form with field tokens ⟦F:<colId>⟧
  "summarizeBy": "sum",                // sum counta count countunique average max min median product stdev stdevp var varp custom
  "name": "SUM of Revenue",            // display name (default "<SUMMARIZE> of <header>")
  "showAs": "default",                 // default percentOfRowTotal percentOfColumnTotal percentOfGrandTotal
  "numberFormat": null }               // overrides the inherited format
// PivotFilter
{ "source": "<colId>", "criteria": {"hiddenValues": […], "condition": {…}} }   // §3.2 column criteria
```

Fields whose source column no longer exists are ignored by the engine and shown in the editor with
a warning badge ("This field no longer exists in the source range").

### 7.2 Creating

Insert › Pivot table (`sheets.insert.pivotTable`) opens `CreatePivotDialog` (WonkyDialogSpec):
`range` (`RangeInput`, default = data region of the selection), `destination` radio *New sheet*
(default) / *Existing sheet* + `location` (`RangeInput`, single cell). [Cancel] [Create] → one
step: optional new sheet "Pivot table 1" (inserted after the source sheet, 26 cols × 1,000 rows)
+ `PivotTable` row with an empty spec; the editor panel opens. Headers that are empty are shown as
"Column C".

### 7.3 Editor panel (`sheets.panel.pivotEditor`)

```
Pivot table editor                                         ✕
Range  [Sheet1!A1:F5000 ⊞]
Suggested (P2)  [Revenue by Region] [Units per Month] …
Rows                                              [Add ▾]
┌ Region ──────────────────────────────────── ✕ ┐
│ Order [Ascending ▾]   Sort by [Region ▾]       │
│ ☑ Show totals   ☐ Repeat row labels            │
└────────────────────────────────────────────────┘
Columns                                           [Add ▾]
Values            Display [Columns ▾]             [Add ▾]
┌ Revenue ─────────────────────────────────── ✕ ┐
│ Summarize by [SUM ▾]   Show as [Default ▾]     │
└────────────────────────────────────────────────┘
Filters                                           [Add ▾]
┌ Status ──────────────────────────────────── ✕ ┐
│ Status [Showing all items ▾]                   │   → FilterColumnPopover content (§3.5)
└────────────────────────────────────────────────┘
```

- `Add ▾` opens `PivotFieldList` (search, source headers with type icons: number, text, date,
  boolean; Values also lists *Calculated field*). Cards (`PivotFieldCard`) are draggable between
  sections (drag handle, drop indicators; keyboard: card ⋮ › Move to Rows/Columns/Values/Filters).
- Date fields: card ⋮ › *Create pivot date group* ▸ units (§7.7); numeric fields: *Create pivot
  group rule* (histogram dialog: min, max, interval). Manual groups (P1): select labels in the
  output, context menu *Create pivot group* → names the group.
- Calculated field card: name input + `FormulaEditor` where source headers are offered as
  completions (`'Unit price' * Quantity`), Summarize by (SUM or Custom).
- Every change commits immediately `sheets.pivot.update {pivotId, spec}` (one step each; Sheets
  applies live). The panel opens via 03's floating ✎ button on the pivot or when the selection
  enters pivot output and the user presses *Edit*.

### 7.4 Engine (`wonky_sheets_core/lib/pivot/`)

```dart
final class PivotEngine {
  PivotResult compute(PivotSpec spec, SourceTable source, PivotContext ctx, {CancellationToken? cancel});
}
// SourceTable: column snapshots of computed values, display texts and formats for the source
// range minus its header; header names; row mask from pivot filters and from slicers whose
// applyToPivotTables is true.
```

1. **Filter** rows by `filters` (shared `FilterEngine` evaluation) and slicer masks.
2. **Group keys** per row: for each row/column group, the normalized key — numbers by value, text
   **case-insensitive** with the first-seen casing as label (confirm with golden vectors),
   booleans, blanks as their own group (label empty, sorted last), dates transformed by the date
   unit, histogram bucket `floor((x − min) / size)` (values below `min`/above `max` go to
   "< min" / "> max" buckets), manual groups via an item→group map.
3. **Aggregate** with streaming `Aggregator`s (`aggregators.dart`) that reuse the formula library's
   semantics (SUM ignores text, COUNTA counts non-empty, COUNTUNIQUE uses a hash set, MEDIAN keeps
   values, STDEV/VAR via Welford) — for every (rowKey, colKey) cell, each subtotal level and
   grand totals.
4. **Calculated fields**: *Summarize by SUM* → the formula is evaluated per source row (field
   tokens bound to that row's values) and summed; *Custom* → evaluated per output cell with field
   tokens bound to **arrays** of the group's values (`=SUM(Revenue)/COUNTA(Region)`), using the
   formula engine's `evaluate` with a LET-like environment.
5. **Show as**: divide each value by its row total, column total or grand total (percent format).
6. **Sort** groups by label (type order §2.3, asc/desc) or by a value's total (`sortByValue`).
7. Complexity O(rows × groups) with hash grouping; jobs above 100k source rows are offloaded
   (§1.4); results are cached by `(spec hash, source generation)`.

### 7.5 Output layout and formats

`PivotLayout.build(result) → OverlayGrid` (tabular form, Sheets layout):

- Anchor = top-left. One label **column per row group**; one header **row per column group**,
  plus one row of value names when there are ≥ 2 values and `valueLayout == columns`; with
  `valueLayout == rows` values become the innermost row level ("Values" column).
- Subtotal rows "‹label› Total" after each non-innermost row group with `showTotals`; *Grand
  Total* row at the bottom and *Grand Total* column(s) at the right when the outermost group has
  `showTotals`.
- Empty spec → a single muted overlay text "Add rows, columns, or values in the pivot table
  editor".
- Default formats (computed, not stored): header and total rows bold; header row fill
  `pivotHeaderFill` and total rows `pivotTotalFill` (theme-adaptive grid tokens, light/dark, added
  to 04 §14); value cells inherit the source column's number format for SUM/AVERAGE/MIN/MAX/MEDIAN,
  General for counts, `0.00%` for show-as percentages, overridden by `numberFormat`.
- Users may format pivot cells normally (Format menu): this writes format-only `Cell` rows at those
  positions, which render over the computed defaults (formats don't block the overlay; Sheets
  parity — formats stay with positions).
- Limit: 1M output cells → anchor `#REF!` "Pivot table is too large".
- Header block (implementation, `PivotLayout`): with column groups, the first header row holds
  the value name in the corner cell and the column field names; the row field names sit in the
  last header row above the label columns. Without column groups there is a single header row
  (row field names, then value names). Calculated fields evaluate through
  `EnginePivotFormulaEvaluator` (formula engine `compileWithBindings`).

### 7.6 Overlay, collisions and editing

- The output is a **computed overlay** (02 §3.5) registered in the engine's `OverlayIndex`
  (shared with spills, [05 §7.5](05-formula-engine.md#75-spilling-and-computed-overlays)); the
  pivot is a `PivotNode` in the dependency graph (05 §8.1) depending on the source range, pivot
  filters' formula conditions and slicers.
- **Collision**: if any cell of the output rectangle (including the anchor) has `content`, or the
  rectangle overlaps an overlay that wins the deterministic rule (first anchor in sheet/row/col
  order), no output is produced and the anchor shows `#REF!` "Pivot table results would overwrite
  data in B5. Remove that data or move the pivot table." with a *Select blocking cells* action.
- **Grid edge**: output larger than the sheet → `#REF!` "The pivot table needs 120 more rows."
  with an *Insert rows* action (`sheets.formula.insertRowsForSpill`, 05 §19).
- Editing output cells is blocked with 03's toast (03 §14.9); formulas may read output cells
  (`OverlayDep`), including `GETPIVOTDATA` (§7.8).
- **Move**: cut/paste with the anchor in the cut range (or dragging the whole output) updates
  `anchorRowId/anchorColId` (one step). **Delete**: context menu *Delete pivot table*
  (`sheets.pivot.delete`), or selecting the whole output and pressing Delete. Anchor row/column
  deleted → invariant moves the anchor (02 §8).

### 7.7 Grouping options

| Kind | Options |
|------|---------|
| Date group (`unit`) | `second`, `minute`, `hour`, `hourMinute`, `hourMinuteAmPm`, `dayOfWeek`, `dayOfYear`, `dayOfMonth`, `dayMonth`, `month`, `quarter`, `year`, `yearMonth`, `yearQuarter`, `yearMonthDay` (labels formatted per locale, e.g. "Jan", "Q1", "2026-Q1") |
| Histogram | `size` (> 0), `min`, `max` (optional; default data min/max); labels "0–10", "10–20"… |
| Manual | named groups of items; ungrouped items stay as themselves or go to `ungrouped` name |

Text values in date-grouped fields form a "(non-date)" group.

### 7.8 GETPIVOTDATA

`GETPIVOTDATA(value_name, any_pivot_table_cell, [original_column, pivot_item, …])`:

- Resolves the pivot whose output (or anchor) contains `any_pivot_table_cell`.
- `value_name` matches a value's `name` or its source header, case-insensitive.
- Each `(original_column, pivot_item)` pair fixes a row/column group by header name → item label
  (case-insensitive; dates match by value). Groups not fixed → the matching total (e.g. only
  Region given → the Region subtotal / grand total across columns).
- Errors: unknown value/field → `#REF!` "Field 'X' was not found in the pivot table."; no such
  item combination or totals hidden → `#N/A`.
- Implemented in `pivot/get_pivot_data.dart` over `PivotResult`; depends on the `PivotNode`.

### 7.9 Drill-down (P1)

Double-click a value cell (or context menu *Show details*) → `sheets.pivot.drillDown {pivotId,
cell}`: creates a new sheet "Details 1" after the pivot sheet with the source header row and all
source rows contributing to that cell (values only, formats copied), and activates it — one step.
Above 100k rows a confirm dialog appears.

### 7.10 Refresh

- Source edits (local or remote) dirty the `PivotNode`; recompute is debounced 300 ms and runs at
  priority P-2 when the pivot is visible, else P-4 (05 §10.1). The previous output stays visible
  (stale styling) until the new result replaces it atomically.
- `sheets.pivot.refresh` forces a recompute. P2: incremental delta aggregation for decomposable
  aggregates (SUM, COUNT, COUNTA, MIN/MAX on inserts).

### 7.11 Suggested pivots (P2)

Heuristics over the source (categorical × numeric, date × numeric, top-cardinality limits) produce
up to 4 suggestion chips; *Explore* / AI (12) can contribute more. Clicking applies the spec
(one step).

### 7.12 Commands, MCP, acceptance

Commands: `sheets.insert.pivotTable {range?, destination?, location?}`, `sheets.pivot.openEditor {pivotId}`,
`sheets.pivot.update {pivotId, spec? , sourceRange?}` (1 step), `sheets.pivot.delete {pivotId}`,
`sheets.pivot.refresh {pivotId}`, `sheets.pivot.drillDown {pivotId, cell}`,
`sheets.pivot.createGroup {pivotId, field, group}`, `sheets.pivot.expandGrid {pivotId}` (§7.13).

Acceptance:
- [ ] Pivot of 200k sales rows with Rows = Region, Columns = Year (date group), Values = SUM and
      COUNTA renders in < 1 s native, totals correct vs. SUMIFS cross-check.
- [ ] Typing into a cell where the pivot output would expand shows the collision `#REF!`; deleting
      the blocking value restores the output.
- [ ] Editing a source value on another client updates the pivot on all clients identically.
- [ ] `=GETPIVOTDATA("SUM of Revenue", Pivot!A1, "Region", "East")` returns the East total.
- [ ] Every editor change is a single undo step; undo restores the previous layout.

### 7.13 Implementation notes (app, `wonky_sheets/lib/features/pivot/`)

- **Overlay without a `PivotNode`**: `PivotOverlayService` computes every pivot
  (`SourceTable.fromModel` over the engine → `PivotEngine` → `PivotLayout`) and serves the output
  through `ModelWorkbookView.overlays` (`ComputedOverlaySource`, core): the engine reads output
  cells of empty cells as **literal inputs**, so formulas (`=SUM(Pivot!B2:B9)`, whole columns),
  the grid painter, Ctrl+arrows and the clipboard see them; copying output copies values. After a
  recompute the service calls `FormulaEngine.rectChanged` for the old ∪ new rectangle, which
  dirties dependents incl. `GETPIVOTDATA` (its reference argument points into the output).
  `engine.pivots` is the service (`PivotDataLookup`). Spill vs pivot follows 05 §7.5's anchor
  order: blank output cells are inputs too (an array anchored later that would spill into the
  output shows `#SPILL!`); a dynamic array anchored earlier (core `FormulaEngine.spillAreas`, also
  a `#SPILL!` array that only the pivot blocks) wins — the pivot shows the collision, or nothing
  at all when the array covers its anchor (`PivotOutput.yielded`). Typed formulas are evaluated
  after their batch and the rule re-checked; `FormulaEngine.rectChanged` re-evaluates arrays
  over the changed rectangle.
- **Refresh**: `PivotTable` row changes (edit, undo, remote) and anchor moves recompute at once;
  edits inside the source (local/remote, plus any content edit when the source holds formulas,
  plus engine recalc batches inside the source) recompute after 300 ms; content typed into the
  output rectangle (or anywhere on the sheet while it is blocked) re-checks collisions at once.
  Outputs only change (and dependents only dirty) when the laid-out values differ.
- **Formats**: bold header/total cells come from `CellRenderCache.computedFormat` (skipped where
  the user set bold); `pivotHeaderFill` / `pivotTotalFill` are painted by `PivotLayer`
  (z 90, under explicit fills); the empty-spec message is painted muted/italic, not a value.
- **Write guard** (a `WriteGate`): typing, paste (except format/CF/DV/widths), fill, sort,
  randomize, dedupe, trim, split and restore into the output are refused with
  "You can't edit a pivot table's output. Use the pivot table editor."; the cell editor checks
  the gate before it opens. Clearing a range that contains a whole output deletes the pivot (same
  step); a partial clear is refused. A move/cut-paste of a whole output moves the anchor
  (`UpdatePivotTable`, same step; to another sheet: see *Moving* below).
- **Create dialog**: `range` is a text field (A1 with sheet) until the shared `RangeInput`
  exists; `location` is used for *Existing sheet* (default: the active cell). New sheets are named
  "Pivot table N" (localized).
- **Editor panel**: `showAsTab: false` (opened by *Edit*, the context menu or the commands; it
  follows the selection into another pivot while open). The range field commits on Enter/blur.
  Value cards: Summarize by (all 13; Custom only for calculated fields), Show as, ⋮ › Rename….
  Group cards: Order, Sort by (label or any value's total), Show totals, Repeat row labels
  (Rows), ⋮ › Create pivot date group ▸ unit (date/number fields), Create pivot group rule…
  (histogram dialog), Remove grouping; manual groups only via `sheets.pivot.createGroup`.
  Calculated fields: name + formula text with source headers as names (`='Unit price' * Qty`),
  converted to `⟦F:colId⟧` tokens. Filter cards: popover with *Filter by condition* (filter
  condition types without custom formulas) and *Filter by values* (search, Select all · Clear,
  counts). Suggestions (P2): up to 3 chips for an empty spec (measure by low-cardinality
  dimension, date dims grouped by Year-Month, then counts).
- **Grid edge**: the problem banner offers *Insert rows* (`sheets.pivot.expandGrid {pivotId}`,
  appends the missing rows/columns) instead of `sheets.formula.insertRowsForSpill`; collisions
  offer *Select blocking cells*.
- **Drill-down**: double-click on a value cell (editors) or the context menu *Show details*;
  the "Details N" sheet gets the header row (bold), the rows as values and the source columns'
  number formats; above 100,000 rows a confirm dialog asks first.
- **Big pivots**: sources with ≥ 100,000 data rows are aggregated in the background — in an
  isolate on native (`compute`), time-sliced on the web and for specs with calculated fields or
  formula filters (`PivotEngine.computeSliced`, 8 ms slices); the source snapshot is read in
  slices too (see *Big sources* below). Meanwhile the previous output stays, dimmed, with an "Updating…" pill
  (`PivotStaleLayer`); a newer edit cancels and restarts the job.
- **Show items with no data** (`showEmptyGroups`, panel checkbox under the areas): every item of
  a group under every item of the enclosing group, filtered items included, with empty values.
- **Manual groups from the grid**: selecting row/column labels of one field (not date/histogram
  grouped) → context menu *Create pivot group* (`sheets.pivot.groupSelection {name?}`, asks the
  name, default "Group N"); labels that are group names merge their groups.
- **Filters**: *Filter by condition* includes *Custom formula is* (A1 shown, stored relative to
  the field's first data cell); *Filter by color* (fill / text color present in the field's
  cells, `visibleBackgroundColor` / `visibleForegroundColor`; the source snapshot then carries
  effective colors, core `SourceTable.fromModel(colorAt:)`).
- **Moving**: cut/paste (and `MoveRange`) of a whole output moves the pivot, to another sheet
  too (re-created there with the same source and spec in the same step; the editor panel
  follows).
- **Export**: XLSX/ODS write pivot output as cells (values, number formats, bold headers and
  totals) — core `EngineIrValueSource` places pivots with `PivotOutputs` (same placement rules)
  and implements `IrOverlayFormats`.
- **Slicer masks**: slicers (objects of kind `slicer`, spec JSON of §5) whose data range is the
  pivot's source range and that apply to pivot tables filter the source for everyone
  (`PivotOverlayService.slicerMask` → `SourceTable.rowMask`; viewers' local overrides don't);
  slicer changes recompute the pivots (debounced). `rowMask` overrides it.
- **Incremental refresh** (P2, §7.10): when only source *values* changed (content edits or
  recalculated cells inside the source, no format/structure/spec/slicer change, no formulas in the
  source), `PivotOverlayService` updates the previous result in place with
  `PivotEngine.applyDelta` — old values out of, new values into the affected aggregates, then
  re-sorted. Decomposable only: SUM, AVERAGE, COUNT, COUNTA, MIN/MAX (unless the extreme is taken
  out), no pivot filters, calculated fields, histogram groups or slicer masks, unchanged group
  keys and number formats, no errors to take out, ≤ max(256, rows/10) changed rows; otherwise it
  computes anew. After 64 deltas a full computation bounds floating-point drift. A text group
  keeps its first-seen label.
- **Big sources** (≥ 100k data rows): the source snapshot is read in slices between event-loop
  turns (`SourceTableBuilder`, 8 ms per turn), then aggregated in an isolate (native) or
  time-sliced; a source change during the snapshot starts a new job.

---

## 8. Named ranges

### 8.1 Panel (`sheets.panel.namedRanges`)

- List sorted case-insensitively; each row: **name**, range text (`'Sheet 1'!A1:B10`); clicking
  selects the range (switching sheets); hover shows ✎ and 🗑. Search field above 10 items.
- *+ Add a range* → inline form: `name` (`ShadInput`), `range` (`RangeInput`, default = selection),
  [Cancel] [Done]. Editing uses the same form plus *Remove*.
- Also created from the name box (03: `sheets.namedRanges.createFromSelection {name}`) and the
  column header menu *Define named range*.

### 8.2 Name rules (`data_tools/names/name_rules.dart`)

| Rule | Message (Sheets wording) |
|------|--------------------------|
| 1–250 chars, `^[A-Za-z_][A-Za-z0-9_]*$` | Range names must contain only letters, numbers, and underscores. |
| Doesn't start with a digit or with `true`/`false` (case-insensitive) | Range names cannot start with a number, or the words "true" or "false". |
| Not a cell/R1C1 reference (`A1`, `TAX2024`, `R1C1`, `R2C`) per 05 §3.4 limits | Range names can't look like a cell reference (e.g. "A1" or "R1C1"). |
| Unique (case-insensitive) among named ranges **and** named functions | A range with this name already exists. |

### 8.3 Semantics

- `rangeJson` is an id-based `GridRange`; it grows/shrinks with row/column inserts/deletes (03
  §13.2 boundary repair). Formulas reference names textually (05 §3.7).
- **Rename** (`sheets.namedRanges.update {id, name}`) rewrites, in the same undo step, every
  formula that uses the old name (dependents via the graph's `NameDep`, plus CF/DV/filter custom
  formulas found by scanning rule JSON) with `ReferenceRewriter.renameName`.
- **Delete** keeps formula text; formulas show `#NAME?` "Unknown range name: 'Sales'."; undo
  restores.
- **Concurrency**: two offline users creating the same name → both rows sync; evaluation uses the
  row with the smaller id; the invariant pass (02 §8) renames the other to `Name_2` (`_3`, …;
  larger id gets the suffix) — deterministic and idempotent.
- A named range whose sheet was deleted shows a `#REF!` badge in the panel.

### 8.4 Commands and acceptance

`sheets.namedRanges.openPanel`, `sheets.namedRanges.add {name, range, comment?}`,
`sheets.namedRanges.update {id, name?, range?, comment?}`, `sheets.namedRanges.delete {id}`,
`sheets.namedRanges.createFromSelection {name}` (03), `sheets.namedRanges.goTo {name}` — all
mutations 1 step.

- [ ] Creating `Sales` for B2:B100 and using `=SUM(Sales)` works; inserting a row inside the range
      extends it; renaming to `Revenue` updates the formula text in one undo step.
- [ ] `TAX2024`, `1abc`, `true_x` are rejected with the messages above.

---

## 9. Named functions (P1)

### 9.1 Storage

A named function is a `NamedRange` row with `rangeJson = null`,
`formula = "=LAMBDA(price, rate, price*(1+rate))"` (stored form), `comment` = description and
`metaJson` ([05 §24 F3](05-formula-engine.md#24-additions-to-02-data-model)):

```json
{"kind": "function",
 "params": [{"name": "price", "description": "Net price", "example": "100"},
            {"name": "rate",  "description": "Tax rate",  "example": "0.19"}],
 "examples": ["=GROSS(100, 0.19)"]}
```

### 9.2 Panel and editor (`sheets.panel.namedFunctions`)

- List: name with argument signature (`GROSS(price, rate)`), description, ⋮ *Edit* / *Remove*;
  *Add new function*; *Import function* (P2). Empty state shows an example.
- Editor (two steps inside the panel, Sheets layout):
  1. **Define**: *Function name* (auto-uppercased), *Function description* (textarea), *Argument
     placeholders* (chip input; Enter adds; drag to reorder; ✕ removes), *Formula definition*
     (`FormulaEditor`; argument names are highlighted and offered in autocomplete). [Cancel] [Next].
  2. **Preview**: per argument a description and example input; *Function preview* evaluates the
     example call with the engine (`FormulaEngine.evaluate`) and shows the result or error.
     [Back] [Create] / [Update].
- One undo step per create/update/delete.

### 9.3 Validation

| Rule | Message |
|------|---------|
| Name `^[A-Z][A-Z0-9_]*$` after uppercasing, ≤ 255 chars | Function names can only contain letters, numbers and underscores, and must start with a letter. |
| Not a built-in function, named range or other named function name; not cell-like | A function with this name already exists. / The name can't be a cell reference. |
| Params: identifier rules, unique, not cell-like, ≤ 30 params | Invalid argument placeholder "x". |
| Definition parses; uses only its params, literals, functions, named ranges/functions — **no direct cell/range references** in v1 | The formula definition can't contain range references. Use argument placeholders instead. |

### 9.4 Semantics

- Called like built-ins (`=GROSS(B2, 0.19)`); argument count must match exactly
  (`#N/A` "Wrong number of arguments to GROSS. Expected 2 arguments, but got 1 argument.").
- May call other named functions and recurse (depth limit 05 §3.8).
- Autocomplete/signature help/function help use `metaJson` (05 §18).
- Rename → dependents rewritten (as §8.3); delete → `#NAME?`.
- **Import (P2)**: *Import function* opens the Drive picker (spreadsheets the user can view), then
  a checklist of that spreadsheet's named functions (fetched online via
  `SheetsEndpoint.getNamedFunctions(itemUuid)`); imports selected ones plus their named-function
  dependencies; name conflicts ask *Replace* / *Skip*. One step.

### 9.5 Commands and acceptance

`sheets.namedFunctions.openPanel`, `sheets.namedFunctions.create {name, description, params,
definition}`, `sheets.namedFunctions.update {id, …}`, `sheets.namedFunctions.delete {id}`,
`sheets.namedFunctions.import {sourceItemUuid, names}` (P2).

- [ ] Creating `GROSS(price, rate)` makes `=GROSS(100, 0.19)` return 119 and appear in
      autocomplete with its description and argument help.
- [ ] A definition containing `A1` is rejected; recursion `FACTR(n)` works up to the depth limit.

---

## 10. Protected sheets and ranges

### 10.1 Model and permissions

`ProtectedRange {sheet, rangeJson (null = whole sheet), exceptRangesJson, description,
warningOnly, editorsJson, createdBy}` (02 §3.4).

- Who may edit protected cells: the spreadsheet **owner**, the protection's **creator**, and users
  in `editorsJson` (user UUIDs). `warningOnly` protections let every editor edit after a warning; the warning shows for
  everyone, the owner and the creator included (they guard against accidental edits).
- Who may change/remove a protection: the owner and users allowed to edit it. Others see it
  read-only in the panel (lock icon, "You can't edit this protection").
- Commenters/viewers can't edit anything anyway (the server refuses their ops).

### 10.2 Panel (`sheets.panel.protected`)

```
Protected sheets & ranges                             ✕
┌ 🔒 Budget totals       Sheet1!F2:F40     Only you ┐
└ 🔒 Sheet "Config"      except B2:B5      3 editors┘
[+ Add a sheet or range]
── adding/editing ──────────────────────────────────
[ Range | Sheet ]                       (ShadTabs)
Enter a description  [                  ]
Range: [Sheet1!F2:F40 ⊞]          | Sheet: [Config ▾] ☐ Except certain cells [B2:B5 ⊞] [+ Add another range]
[Cancel]                                 [Set permissions]
```

*Set permissions* opens `ProtectionPermissionsDialog` (WonkyDialogSpec):

```
Range editing permissions
( ) Show a warning when editing this range
(•) Restrict who can edit this range
    [Only you ▾]   Only you | Custom | Copy permissions from another range
    Custom → UserMultiSelect (file editors, checkboxes) + [Add editors: email…]
                                                   [Cancel] [Done]
```

Adding editors who don't have edit access to the file shows "Bo doesn't have edit access to the
spreadsheet" with a link to the Share dialog (sharing is not part of the undo step). *Done*
commits the protection (one step).

> **As built.** Emails typed into *Add editors* that aren't file editors open "Share with new
> editors?" (`dialog.protectionInvite`): *Share and add* shares the spreadsheet with them as
> editors (`SharingRepository.share`, not undoable) and adds the accounts to the protection;
> invited people without an account get a toast to add them after they accept. Offline (or when
> sharing can't be read) the dialog lists the editors last seen on this device
> (`FileEditors`, user store `sheets.fileEditors.<item>`) with a note, and unknown emails only
> get the toast with *Share*.

### 10.3 Enforcement (`ProtectionGuard`, core)

```dart
final class ProtectionGuard {
  GuardResult check(WriteIntent intent, UserId user);   // allowed | warnings | blocked (with ranges)
}
sealed class WriteIntent { }   // CellWrites(rects) | Structural(sheet, dim, ids, op) | RuleWrite(kind, rects)
                               // | SheetOp(sheetId, op) | ObjectWrite(sheetId) | FilterWrite(sheetId, range)
```

| Intent | Blocked when it touches… |
|--------|---------------------------|
| Cell writes (values, formulas, formats, notes, links, DV toggles) — incl. paste, fill, sort, randomize, dedupe, split, find-replace | any protected cell the user can't edit |
| Insert/delete/move rows or columns | rows/columns containing protected cells (sheet protection: any row/column of the sheet outside `except` ranges) |
| Merge/unmerge, CF/DV/banding rule changes | rule ranges intersecting protected cells |
| Sheet rename/delete/move/hide/tab color, freeze | sheet-protected sheets |
| Charts/images/slicers on the sheet | sheet-protected sheets |
| Basic filter create/change | protected header/filter range or sheet protection (filter views are always allowed) |
| Named ranges, named functions | never (not cell content) |

Row/column resize and hide are allowed (Sheets parity). Commands touching both protected and
unprotected cells abort entirely (03 §16). Dialogs/UX: 03 §16. `ProtectedIndex` (interval index
per sheet) makes checks O(log n) per rectangle.

- **Server-side tools**: MCP tools and server scripts run the same guard on the headless model
  before planning (error code `protected_range`; warning-only ranges are writable with
  `warnings` in the result, 03 §16).
- **Enforced by the sequencer** (suite [17](../17-revlog-sync.md) part 5 §3.5): every op except
  `system` ops on a file with protections (or one that writes `protected_range` rows) is
  checked against the server's model at the previous revision with the same core code:
  `ProtectionCheck.ofApplied` (`wonky_sheets_core/lib/src/data_tools/protection/`) derives the
  intents from the op's applied changes (row/column structure from inserted, deleted and moved
  rows/columns; range repairs that only repoint references at rows the same op deletes are
  exempt, `BoundaryRepair`) and runs `ProtectionGuard`. Updating or deleting a protection needs
  `canManage`. A blocked intent rejects the **whole op** (`protectedRange`, with the
  protections hit); warning-only protections never block on the server. This covers server
  changes too (MCP, AI, scripts with the run-as user, imports, revert/reapply).
- **Offline edits and stale clients**: an edit made offline before a protection arrived, by an
  editor removed from a protection, or by a stale or modified client is rejected when it syncs:
  the client rolls the group back, removes its undo step and shows the blocked message (03 §16;
  [10 §9](10-collaboration-history.md)). The client gate stays for the dialogs and the
  warning-only confirmation.
- **Version restore** pre-checks the whole diff with the guard before writing and refuses with
  "This version changes protected ranges you can't edit" (10 §5.3), so it never commits
  partially.

> **As built.** Enforcement is a write gate on `SheetEditorController.apply`: the operation is
> planned without applying and its `WriteIntent`s are derived from the row changes
> (`WriteIntents`, in `wonky_sheets_core/lib/src/data_tools/protection/write_intents.dart` so the
> client gate, MCP and the sequencer share it; row/column structure from the operation, inserts
> count only inside a protection). Blocked → "Protected cell or object" dialog (agents: failed
> `protected_range: …`); warning-only → "Heads up!" confirm; after OK the command resumes at the
> blocked write (`applyConfirmed` in commands with dialogs, 03 §16), others rerun. The
> permissions dialog (`ProtectionPermissionsDialog`, MCP-describable like a `WonkyDialogSpec`:
> fields `mode`, `who`, `editor:<id>`, `add`) shows *Who can edit* only for *Restrict* and the
> editor checkboxes and "Add editors" only for *Custom*. Stripes cover every protected cell while
> the view option is on (Google parity), not only cells the user can't edit; the option is kept
> per user and spreadsheet in `LocalViewState`.

### 10.4 Commands and acceptance

`sheets.protect.openPanel {prefill?}`, `sheets.protect.add {target: {range} | {sheetId,
exceptRanges?}, description?, warningOnly, editors}`, `sheets.protect.update {id, …}`,
`sheets.protect.delete {id}`, `sheets.view.toggleProtectedRanges` (03) — mutations 1 step.

- [ ] Owner protects F2:F40 "Only you"; an editor typing in F5 gets the blocked dialog; pasting a
      block that overlaps F5 is aborted entirely; the same write through MCP fails with
      `protected_range`.
- [ ] A warning-only protection shows the "Heads up!" confirm once per 5 minutes when opted.
- [ ] Sheet protection with an `except` range allows edits only inside the exception.

---

## 11. Find and replace

### 11.1 Find bar (`sheets.find.open`, Mod+F)

Compact bar at the top-right of the grid area (`FindBar`, `ShadCard` with `ShadInput`): query,
status "3 of 12", ↑/↓ buttons, ⋮ (opens the full dialog with the query), ✕. Searches the **active
sheet**, case-insensitive, partial match, display values. Enter = next, Shift+Enter = previous,
Esc closes and returns focus to the grid. All matches in the viewport get the `findMatch` token
fill, the current one `findMatchActive` (suite 02 tokens), drawn by 03's overlay layer.

### 11.2 Dialog (`sheets.find.openReplace`)

Fields are fixed by [04 §11.7](04-screens-menus-toolbar.md#117-find-and-replace-sheetsfindopenreplace):
`find`, `replace`, `searchIn` (All sheets / This sheet / Specific range + `RangeInput`),
`matchCase`, `matchEntireCell`, `useRegex`, `searchFormulas`, `searchLinks` (P1). Buttons: Find,
Replace, Replace all, Done. Non-modal and draggable.

### 11.3 Semantics

| Aspect | Rule |
|--------|------|
| What is matched | Non-formula cells: their **display text** (formatted value; rich text as plain text). Formula cells: the display text of the result, or — with *Also search within formulas* — the **A1 formula text** in the spreadsheet locale. Overlay cells (spill/pivot output) are found but never replaced. *Also search within links*: `linkUrl` and link runs. Notes and comments are not searched. |
| Matching | Case-insensitive (Unicode simple folding) unless *Match case*; substring unless *Match entire cell contents*; *Search using regular expressions* uses Dart `RegExp` with the RE2 shim of [05 §15.5](05-formula-engine.md#155-text) (invalid pattern → inline error under the input). |
| Order | Row-major from the active cell, wrapping; *All sheets* continues in sheet order (hidden sheets skipped). |
| Hidden rows | *Find* navigation skips rows hidden by filters or collapsed groups (and user-hidden rows); *Replace all* includes them — the result toast says "(including 3 in hidden rows)". |
| Replace in values | The replacement is applied to the cell's **edit text** (what the cell editor would show, e.g. `1234.5` for a currency-formatted number), then the result is parsed like typed input (03 §8.6) — so replacing `1` with `2` in `100` yields the number 200. If the match exists only in the display text (e.g. searching `$` in a currency format), the cell is not replaceable and is counted as skipped. |
| Replace in formulas | Text/regex replacement on the A1 text, then `FormulaCodec.toStored` at the cell (05 §5). Unparseable results are still stored (cell shows `#ERROR!`, 05 §5.3) — Sheets parity. Replacing a sheet name inside references re-targets them by name. |
| Regex replacement | `$1`…`$99`, `$&` whole match, `$$` literal `$`. |
| Protection | *Replace all* skips cells the user can't edit (toast "12 cells were skipped because they are protected"); warning-only protections ask once. Single *Replace* on a blocked cell shows the 03 §16 dialog. |
| DV | Replacements are not rejected by strict rules (marked invalid), like paste. |
| Undo | *Replace* = 1 step per replacement; *Replace all* = **one step** (chunked writes). Toast "Replaced 12 instances of 'x' with 'y'". |

### 11.4 Engine and performance

`FindEngine` (core) scans `CellStore` snapshots per sheet in chunks (10k cells per slice on the UI
isolate, offloaded above 100k cells), streaming matches to the UI (first results < 100 ms on a
1M-cell sheet); capped at 100,000 matches ("100,000+ matches"). Changing the query cancels the
running scan. Edits invalidate only the edited cells' match status. `ReplacePlanner` builds the
write batch (with `columnValues: ['content']`, plus runs for rich text).

### 11.5 Commands and acceptance

| Command | Args | Binding | Undo |
|---------|------|---------|------|
| `sheets.find.open` | `{query?}` | Mod+F (grid) | — |
| `sheets.find.openReplace` | `{query?}` | ⇧⌘H (macOS) / Ctrl+H (04) | — |
| `sheets.find.next` / `sheets.find.previous` | — | Enter / Shift+Enter (find bar), Mod+G / Mod+Shift+G | — |
| `sheets.find.replace` | `{find, replace, options}` | — | 1 |
| `sheets.find.replaceAll` | `{find, replace, scope, matchCase, matchEntireCell, useRegex, searchFormulas, searchLinks}` | — | 1 |

- [ ] Searching "east" finds "East" and "Northeast"; with *Match entire cell* only "East".
- [ ] Regex `(\d+)-(\d+)` → `$2-$1` swaps parts in 10,000 cells in one undo step.
- [ ] With *search within formulas*, replacing `SUM` by `AVERAGE` rewrites formulas and keeps
      their id-based references intact (verified by inserting a row afterwards).

---

## 12. Data cleanup

### 12.1 Remove duplicates (`sheets.cleanup.openRemoveDuplicates`)

- Range = selection, or the data region of the active cell when a single cell is selected.
  Dialog per [04 §11.12](04-screens-menus-toolbar.md): `hasHeader` (pre-checked by
  `HeaderDetector`), `columns` checklist (header names or "Column B"), *Select all*.
- Two rows are duplicates when all selected columns have equal **values**: numbers numerically
  (formats ignored), text exact and case-sensitive (whitespace significant — use *Trim
  whitespace* first), booleans, errors by type, blanks equal blanks; formula cells by result.
  The **first** occurrence is kept.
- Execution (`data_tools/cleanup/dedupe.dart` + `move/row_move_plan.dart`): kept rows are compacted
  upward **within the range** with the sort machinery (§2.2 strategy choice, formulas with copy
  semantics §2.5); the cells of the vacated rows at the bottom of the range are cleared (all cell
  fields) — rows themselves are not deleted, cells outside the range are untouched. One undo step
  labelled "Remove duplicates".
- Result dialog: "N duplicate rows found and removed. M unique rows remain." or "No duplicate
  rows found." [OK]. Large ranges run as a `DataJob` (hashing 1M rows < 2 s native).
- Refusals like sort (§2.4): vertical merges, overlays, protected cells.

### 12.2 Trim whitespace (`sheets.cleanup.trimWhitespace {range?}`)

- Range = selection (data region if a single cell). For text content (`s:`, and `r:` with runs
  re-offset): remove leading/trailing whitespace (space, tab, CR, LF, NBSP U+00A0 and other
  Unicode `Zs`), and collapse internal runs of spaces/NBSPs to one space (line breaks inside the
  text are kept). Numbers, booleans, formulas and errors are untouched; trimmed values remain text
  (no re-parse).
- One step; toast "Trimmed whitespace from N cells." or "No whitespace to trim."

### 12.3 Cleanup suggestions (P2, `sheets.panel.cleanupSuggestions`)

Background detectors (`data_tools/cleanup/suggestions.dart`) over the active sheet's data region:
numbers/dates stored as text ("Convert 23 cells in column D to numbers"), leading/trailing
whitespace, duplicate rows, inconsistent capitalization of categorical values ("east" vs "East"),
empty rows inside the data, mixed types in a column. Each card shows a before/after preview of up
to 3 cells with *Apply* (one step) and *Dismiss* (local). Links to Column stats.

---

## 13. Split text to columns (`sheets.data.splitTextToColumns {range?, separator?}`)

UI per [04 §11.13](04-screens-menus-toolbar.md) (immediate split + floating separator chip).

- Source must be a **single column** (else toast "Please select a single column of data to
  split."); a single selected cell expands to its column's data region. Formula cells in the
  source are skipped.
- **Separator detection** (`SeparatorDetector`): sample ≤ 1,000 non-empty cells; candidates
  `,` `;` tab `|` space `.`; choose the candidate present in the most cells with the most
  consistent count per cell (lowest coefficient of variation), ties: `,` > `;` > tab > `|` >
  space > `.`. None found → the chip opens with "Couldn't detect a separator" and *Custom*
  focused.
- **Splitting**: CSV-style quoting is honoured for `,` and `;` (`"Doe, John",42`); consecutive
  separators produce empty parts; parts are trimmed of surrounding spaces (except when the
  separator is space). Each part is parsed like typed input (03 §8.6, locale-aware) unless the
  target column's number format is plain text.
- **Output**: part 1 replaces the source cell, parts 2…n go to the right. If any target cell to
  the right is non-empty → dialog "Do you want to replace existing data?" [Cancel] [Replace].
  Columns are appended if needed (cell-limit check).
- **Separator chip** (`SeparatorChip`, anchored below the range): Detect automatically / Comma /
  Semicolon / Period / Space / Custom [input]. Changing it re-runs the split **replacing the same
  undo step** (requires `UndoService.replaceLast(step)`, addition to suite 08 — open question §23).
  The chip disappears on the next edit, selection change or Esc.
- Also offered after pasting delimited text into a single column (03 §12.5).

Acceptance: `"Doe, John",42,2026-10-12` splits into three cells (text, number, date) with
auto-detected comma; switching to *Semicolon* in the chip restores and re-splits within one undo
step.

---

## 14. Randomize range (`sheets.data.randomizeRange {range?}`)

- Range = selection (≥ 2 rows; single column or multi-column). Rows of the range are shuffled with
  Fisher–Yates using `Random.secure()` and applied with the shared row-move planner exactly like a
  sort (§2.2–§2.7, same strategy choice and semantics): **formulas get copy semantics** (§2.5),
  one undo step labelled "Randomize range".
- Refusals as sort (merges, overlays, protection). No confirm dialog is needed because formula
  behavior is identical to sorting (see open question §23 regarding 04 §11.23's wording).

---

## 15. Column stats (`sheets.data.columnStats {colId?}`, panel `sheets.panel.columnStats`)

```
Column stats                                        ✕
‹  B · Revenue  ›                ☑ Ignore header row
Count       Values 1,204 · Empty 12 · Unique 980
Distribution  [histogram ▁▃▆█▆▃▁]          (HistogramView)
Frequency     Value          Count    %
              East             412   34 %
              West             380   31 %   … [Show more]
Summary (numbers)  Sum 1,234,567 · Average 1,025.4 · Median 980 · Min 3 · Max 9,820
```

- Column = active cell's column (‹ › switch columns; `sheets.columnStats.selectColumn`). Data =
  the column's cells within the data region below the header (all rows, including hidden).
- Distribution: numeric columns → histogram with ≤ 20 buckets (Freedman–Diaconis width, clamped);
  text columns → bar chart of the top 10 values; dates → histogram by month/year automatically.
  Charts use the `chart1` token (light/dark) with an accessible data-table alternative
  (`ShadTable`) toggled by a "Table" switch.
- Frequency table: value (display text), count, share; sorted by count desc; pages of 50.
- Summary: Sum, Average, Median, Min, Max for numeric; Min/Max for dates (formatted); for text the
  shortest/longest length.
- Computation: `ColumnStats.compute(columnSnapshot)` (core), offloaded above 100k cells (1M cells
  < 500 ms native); live update debounced 500 ms after changes in that column.
- MCP: `sheets.get_column_stats` (headless, same engine).

---

## 16. Row and column groups (outline)

### 16.1 Model

`DimensionGroup {sheet, dimension, startId, endId, depth (1..8), collapsed}` (02 §3.4). Collapsed
state is **shared** (synced), as in Sheets. Rows inside collapsed groups are hidden by a computed
`GroupCollapseMask` (core `data_tools/groups/group_layout.dart`) — `SheetRow.hidden` is not written.
User-hidden rows stay hidden when a group expands.

### 16.2 Commands and gestures

| Command | Binding | Behavior |
|---------|---------|----------|
| `sheets.group.groupRows` / `sheets.group.groupColumns` `{ids?}` | Alt+Shift+→ (rows resp. columns selected); with a cell range selected a small popover offers "Group rows 2 – 5" / "Group columns B – D" | creates a group over the contiguous span |
| `sheets.group.ungroupRows` / `sheets.group.ungroupColumns` `{ids?}` | Alt+Shift+← | removes the span from the deepest intersecting groups |
| `sheets.group.toggle` `{groupId}` | click +/− in the gutter | collapse/expand |
| `sheets.group.collapseToLevel` `{dimension, level}` | click level buttons 1…n in the gutter corner | groups with depth ≥ level collapse, others expand |
| `sheets.group.expandAll` / `sheets.group.collapseAll` `{dimension}` | View › Group (04) | |
| `sheets.group.removeAll` `{dimension}` | gutter context menu | |

All are one undo step (collapse state is synced content, suite 08 §2).

### 16.3 Semantics

- **Create** over span S: depth = 1 + number of existing groups that contain S (maximum 8, else
  toast "You can't group more than 8 levels."); existing groups strictly contained in S get
  depth + 1 (rewritten in the same step). A group that partially overlaps S at the resulting depth
  is merged: S is extended to the union (Sheets behavior). Grouping an identical span again nests
  it one level deeper.
- **Ungroup** span S at the deepest intersecting level: S covers the group → delete it; S covers
  an end → shrink it; S is strictly inside → split into two groups. Groups contained in a deleted
  group decrease depth by one.
- **Structure**: inserting rows strictly inside a group extends it (ids); inserting directly after
  `endId` does not. Deleting rows shrinks/deletes groups via 03's boundary repair. Moving rows
  keeps endpoint ids (the group follows its endpoint rows).
- **Rendering** (03 §3): gutter of 16 px per depth level left of row headers / above column
  headers; brackets drawn from start to end; the +/− button sits on the row **after** the group's
  last row (Sheets default; P2 option "+/− at top"); level buttons in the corner. Gutter controls
  are keyboard-reachable (Tab into the gutter, Enter toggles) and announced ("Group rows 2 to 5,
  expanded").
- **Invariant normalization** (02 §8, after merges): sort groups by (start index, −length, id);
  identical spans with equal depth → keep the smaller id; depth = 1 + number of groups containing
  it (clamped to 8); write only rows whose stored depth differs. Deterministic and idempotent.

### 16.4 Acceptance

- [ ] Selecting rows 3–8 and pressing Alt+Shift+→ creates a group with a − button under row 8;
      grouping 4–5 inside it creates depth 2; level button 1 collapses everything for all
      collaborators.
- [ ] Ungrouping row 5 from the depth-2 group 4–5 shrinks it to row 4.
- [ ] Two users grouping overlapping spans offline converge to the same depths after sync.

---

## 17. Convert to table (P2)

Structured tables (Google "Tables"): *Format › Convert to table* (`sheets.format.convertToTable`,
⌥⌘T / Ctrl+Alt+T per 04) turns a data region into a named table with a header row, column types
(text, number, date, dropdown, checkbox, smart chip) that create DV rules and formats, alternating
colors, a table menu (sort, filter, group-by views), automatic expansion when typing directly below
the last row, and structured references in formulas (`=SUM(Sales[Revenue])`, grammar extension in
05 §3.5). Proposed model (addition D8):

```yaml
class: SheetTable
table: sheet_table
serverOnly: true             # a file table (02 §3), plus a sheetsSchema entry
fields:
  sheet: Sheet?, relation(name=sheet_tables, onDelete=Cascade)
  name: String                 # unique per spreadsheet, same rules as named ranges
  rangeJson: String            # GridRange incl. header row; r2 extended when rows are appended
  columnsJson: String          # [{colId, name, type, dvRuleId?, numberFormat?}]
  styleJson: String            # colors, banding, footer
```

Detailed design deferred to a dedicated spec before P2 starts.

---

## 18. Smart fill and data extraction (P2)

- **Smart fill**: when a user types 2–3 example values in a column next to data, a local
  pattern-synthesis engine (`data_tools/smart_fill/`, FlashFill-style: substrings by token/position,
  concatenation, case changes, date reformatting) proposes the remaining values; a suggestion
  banner over the column shows a preview with ✓ (one step, writes values) / ✕. If no program
  explains the examples, the banner offers *Fill with AI* (suite 10 `sheets.ai.fillRange`).
- **Data extraction** (`sheets.data.extraction`): extracts fields from smart chips (people → email,
  file → owner) into adjacent columns; depends on smart chips (03 §14.3, P2).

---

## 19. Performance budgets (1M-row sheets)

| Operation | Native | Web (wasm) | Notes |
|-----------|--------|------------|-------|
| Sort permutation, 1M rows × 2 keys | < 1.5 s | < 4 s | offloaded; writes extra: strategy A ≈ 1 write/row, B ≈ cells (≈ 50k row changes/s native, 20k/s web OPFS) |
| Basic filter apply (values or condition), 1M rows | < 300 ms | < 800 ms | incremental afterwards O(changed rows) |
| Filter popover value list, 1M rows / 50k distinct | < 400 ms | < 1 s | virtualized list |
| DV markers for a viewport | < 2 ms | < 4 ms | lazy, cached |
| Pivot, 1M rows, 2 row groups + 1 column group + 2 values | < 1.5 s | < 3.5 s | offloaded |
| Remove duplicates, 1M rows × 3 columns (compute) | < 2 s | < 5 s | |
| Find across 10M cells | first match < 100 ms, full < 2 s | full < 5 s | streaming |
| Column stats, 1M cells | < 500 ms | < 1.2 s | |
| Group collapse/expand of 100k rows | < 16 ms | < 16 ms | Fenwick range update |

UI frames stay ≤ 20 ms during all jobs (compute off the UI isolate or time-sliced; write chunks
yield between transactions). Every job is cancellable in its compute phase.

---

## 20. Command catalog

All ids are stable (suite 08). Ids marked (04)/(03) are already listed in those specs' menus; this
spec defines their behavior. "1" = one undo step, "—" = not undoable. Required role: editor for
mutations, viewer otherwise.

| Command id | Args | Shortcut | Undo |
|------------|------|----------|------|
| `sheets.data.sortSheet` (04) | `{colId, ascending, freezeHeader?}` | — | 1 |
| `sheets.data.sortRange` (04) | `{range, colId?, ascending?, specs?, hasHeader?}` | — | 1 |
| `sheets.data.openSortDialog` (04) | — | — | — |
| `sheets.data.randomizeRange` (04) | `{range?}` | — | 1 |
| `sheets.data.splitTextToColumns` (04) | `{range?, separator?}` | — | 1 |
| `sheets.data.columnStats` (04) | `{colId?}` | — | — |
| `sheets.columnStats.selectColumn` | `{colId}` | — | — |
| `sheets.filter.toggle` (04) | `{range?}` | ⌥⇧⌘L / Ctrl+Alt+Shift+L | 1 |
| `sheets.filter.setRange` | `{range}` | — | 1 |
| `sheets.filter.openColumnMenu` | `{colId?}` | Mod+Alt+R | — |
| `sheets.filter.setColumnCriteria` | `{colId, criteria \| null}` | — | 1 |
| `sheets.filter.clearColumn` / `sheets.filter.clearAll` | `{colId}` / — | — | 1 |
| `sheets.filter.sortColumn` | `{colId, ascending \| fillColor \| textColor}` | — | 1 |
| `sheets.filter.saveAsFilterView` | — | — | 1 |
| `sheets.filterView.create` (04) | `{temporary?, fromBasicFilter?}` | — | 1 (saved) / — (temp) |
| `sheets.filterView.activate` (04) | `{viewId?}` | — | — |
| `sheets.filterView.rename` / `.setRange` / `.setColumnCriteria` / `.sortColumn` / `.duplicate` / `.save` / `.delete` | see §4.5 | — | 1 (saved) / — (temp) |
| `sheets.filterView.copyLink` / `.openPanel` | `{viewId}` / — | — | — |
| `sheets.slicer.add` (04) / `.edit` (08) / `.update` / `.setCriteria` / `.setDefault` / `.reset` | see §5 | — | 1 (editors) |
| `sheets.dv.openPanel` (04), `sheets.dv.saveRule`, `sheets.dv.deleteRule`, `sheets.dv.clearRange` | see §6.8 | — | — / 1 / 1 / 1 |
| `sheets.dv.toggleCheckbox` (03), `sheets.dv.openDropdown` (03) | | Space, Alt+↓ | 1 / — |
| `sheets.insert.checkbox` (04), `sheets.insert.dropdown` (04) | see §6.7 | — | 1 |
| `sheets.insert.pivotTable` (04) | `{range?, destination?}` | — | 1 |
| `sheets.pivot.openEditor` / `.update` / `.delete` / `.refresh` / `.drillDown` / `.createGroup` | see §7.12 | — | — / 1 / 1 / — / 1 / 1 |
| `sheets.namedRanges.openPanel` (04), `.add`, `.update`, `.delete`, `.goTo`, `.createFromSelection` (03) | see §8.4 | — | — / 1 / 1 / 1 / — / 1 |
| `sheets.namedFunctions.openPanel` (04), `.create`, `.update`, `.delete`, `.import {sourceItemUuid?, names?, replace?}` (P2) | see §9.5 | — | — / 1 |
| `sheets.protect.openPanel` (04), `.add`, `.update`, `.delete` | see §10.4 | — | — / 1 |
| `sheets.view.toggleProtectedRanges` (03) | — | — | — |
| `sheets.find.open`, `.openReplace` (04), `.next`, `.previous`, `.replace`, `.replaceAll` | see §11.5 | Mod+F, ⇧⌘H/Ctrl+H, Mod+G, Mod+Shift+G | — / 1 |
| `sheets.cleanup.openRemoveDuplicates` (04), `sheets.cleanup.removeDuplicates` | `{range, hasHeader, colIds}` | — | — / 1 |
| `sheets.cleanup.trimWhitespace` (04) | `{range?}` | — | 1 |
| `sheets.cleanup.openSuggestions` (04, P2), `sheets.cleanup.applySuggestion` | `{id}` | — | — / 1 |
| `sheets.group.groupRows` / `groupColumns` / `ungroupRows` / `ungroupColumns` (04) | `{ids?}` | Alt+Shift+→ / ← | 1 |
| `sheets.group.toggle`, `.collapseToLevel`, `.expandAll` (04), `.collapseAll` (04), `.removeAll` | see §16.2 | — | 1 |
| `sheets.format.convertToTable` (04, P2) | `{range?}` | ⌥⌘T / Ctrl+Alt+T | 1 |
| `sheets.data.extraction` (04, P2), `sheets.data.smartFillAccept` (P2) | | — | 1 |

---

## 21. MCP tools (to be implemented by 12)

Headless tools run on the server with the same core engines and the same `ProtectionGuard`.
[12-mcp-and-ai.md](12-mcp-and-ai.md) §3 owns names and schemas; tools marked *in 12* already
exist there (their criteria/spec arguments map onto the JSON models of this spec), the others are
**proposed additions**:

| Tool | Behavior defined in | Status |
|------|---------------------|--------|
| `sheets.sort_range` | §2 (strategy chosen automatically) | in 12 |
| `sheets.set_basic_filter` / `sheets.clear_filter` | §3 | in 12 |
| `sheets.get_filter_state` (criteria, visible row count, hidden rows paginated) | §3.4 | proposed |
| `sheets.create_filter_view` / `sheets.list_filter_views` / `sheets.delete_filter_view` | §4 | in 12 |
| `sheets.update_filter_view` | §4 | proposed |
| `sheets.set_data_validation` (`null` criteria removes) | §6 (12's snake_case criteria names map to §6.1 types) | in 12 |
| `sheets.get_data_validation` | §6 | proposed |
| `sheets.create_pivot_table` / `sheets.update_pivot_table` / `sheets.delete_pivot_table` | §7 (fields by header name → `colId`) | in 12 |
| `sheets.get_pivot_table` (spec + computed output values) | §7 | proposed |
| `sheets.list_named_ranges` / `sheets.create_named_range` / `sheets.update_named_range` | §8 | in 12 |
| `sheets.delete_named_range` | §8 | proposed |
| `sheets.list_named_functions` / `sheets.set_named_function` / `sheets.delete_named_function` | §9 | proposed |
| `sheets.list_protections` / `sheets.protect_range` | §10 | in 12 |
| `sheets.unprotect_range` | §10 | proposed |
| `sheets.find` / `sheets.find_replace` | §11 | in 12 |
| `sheets.remove_duplicates` / `sheets.trim_whitespace` / `sheets.split_text_to_columns` / `sheets.randomize_range` | §12–§14 | proposed |
| `sheets.get_column_stats` | §15 | proposed (12's `sheets.describe_data` may cover it) |
| `sheets.group_dimension` | §16 | in 12 |
| `sheets.ungroup_dimension` / `sheets.set_group_collapsed` | §16 | proposed |
| `sheets.create_slicer` / `sheets.update_slicer` (P2) | §5 | proposed |

UI-bridge agents use `ui.invoke_command` with the ids of §20 and `ui.fill_dialog` for the
`WonkyDialogSpec` dialogs (sort, create pivot, remove duplicates, protection permissions).

---

## 22. Additions to 02-data-model

| # | Addition | Where | Purpose |
|---|----------|-------|---------|
| D1 | `criteriaJson` schema (§3.2) and `sortJson` schema for `BasicFilter` and `FilterView`; `hiddenValues` match display text | §3.5 | Filters |
| D2 | `DataValidationRule.criteriaJson` schema (§6.1) incl. `options[{value,bg,fg}]`, `allowMultiple`; `displayStyle` authoritative, `showDropdown` derived | §3.5 | DV |
| D3 | `PivotTable.specJson` schema `PivotSpec` v1 (§7.1) with field tokens `⟦F:<colId>⟧` in calculated fields | §3.5 | Pivots |
| D4 | `EmbeddedObject.specJson` for `kind = slicer`: `SlicerSpec` (§5) | §3.5 | Slicers |
| D5 | `NamedRange.metaJson` (same as 05 §24 F3) | §3.4 | Named functions |
| D7 | `LocalViewState` keys: `activeFilterViewId[sheetId]`, `temporaryFilterViews[]`, `slicerOverrides{objectId: criteria}`, `columnStats{open, colId}`, `findOptions` | §4 | Local view state |
| D8 | `SheetTable` (P2, §17) | §3.5 | Structured tables |
| D9 | Grid tokens `pivotHeaderFill`, `pivotTotalFill`, `filterRangeOutline` (light/dark) | 04 §14 | Pivot/filter chrome |
| D10 | `SheetsEndpoint.getNamedFunctions(itemUuid)` (online-only) | server | Named function import (P2) |

---

## 23. Cross-spec notes

Resolved: command namespaces follow [04](04-screens-menus-toolbar.md) (`sheets.filter.*`,
`sheets.filterView.*`, `sheets.dv.*`, `sheets.group.*`, `sheets.protect.*`, …); randomize
adjusts formulas like sort (04 §11.23 updated); `UndoService.replaceLast` added to suite 08;
the shared `Condition` model location is stated in 06 §15; slicers are P2 everywhere; sort
uses full-row `sortKey` rewrite + re-pinning, partial sorts move contents.

Still open (decide during implementation):
1. ~~**Filter-view display permutation** (§4.4)~~ — built (`ViewRowOrder` in the grid geometry
   and selection, §4.4 *As built*).
2. **Basic filter criteria merge granularity** (§3.9): whole-JSON LWW; switch to a per-column
   table if concurrent filter editing proves common.
3. **Live re-filtering** (§3.4) deliberately differs from Sheets' sticky behavior to keep
   `SUBTOTAL` deterministic; validate with users.

### Implementation notes (app, data tools agent)

- View-only sort in filter views is built (§4.4 *As built*): a row display order in the grid's
  geometry and selection.
- While a filter view is active, the basic filter keeps feeding the `filter` hidden layer
  (`SUBTOTAL`) and the layer is **suppressed** on screen (`AxisIndex.setLayerSuppressed`); the
  view's rows are the `filterView` layer.
- A basic filter created from the data region (single active cell) whose region reaches the last
  used row is stored **open-ended** (`SetBasicFilter {openEnded}`: no `r2`); the app resolves it
  down to the last used row, so rows typed below join the filter.
- Sticky edit row (§3.4): dimmed and badged "Hidden by filter" (`StickyRowLayer`) until the
  selection leaves it.
- Sort by color (P2): *Sort by color* in the column popover → `sheets.filter.sortColumn
  {fillColor | textColor}`.
- *Freeze row 1 and re-sort* (§2.6): `sheets.data.sortSheet` toasts when row 1 looks like a header
  and nothing is frozen; the action undoes the sort and runs `{freezeHeader: true}` (freeze +
  sort, one step).
- `DataJobs.run` (`features/data_tools/data_job.dart`): jobs over ≥ 20,000 rows show a progress
  toast (`Toasts.showProgress`: bar, percentage, *Cancel*) and run one at a time per spreadsheet
  ("Waiting for the current operation to finish…"). Sort, randomize and remove duplicates plan
  **cooperatively** (compute phase): `SheetsMutationPlanner.steps` yields progress from the row
  tools (`applyRowPermutationSteps`, every 2,048 rows/formula cells), DataJobs runs ~12 ms of
  steps per frame; *Cancel* stops with nothing changed (no undo step). The finished plan is handed
  to the normal write path with `SheetsMutationPlanner.offer(op, model, plan)` (gates, undo, change
  log unchanged), so the write phase isn't cancellable; the local store writes it in chunks in the
  background. A remote change while planning restarts it (twice), then the plan is made while
  applying. Split/trim/cleanup show an indeterminate bar (fast planners).
- Slicers (§5): `features/slicers/` (`SlicerSpec`, `SlicerController`, `SlicerView` via
  `objectViewBuilders` of the objects layer, `SlicerPanel`), `commands/slicer_commands.dart`.
  Synced criteria → `slicer` layer (formulas/charts); viewers' local overrides → `slicerView`
  layer with `slicer` suppressed. Pivot tables don't follow slicers yet (`applyToPivotTables` is
  stored only).
- Cleanup suggestions (§12.3): `features/data_tools/cleanup_suggestions.dart` (detectors over
  ≤ 50k rows of the used range), panel `sheets.panel.cleanupSuggestions`, apply = one step,
  dismiss = this device.
- Named function import (§9.4): `sheets.namedFunctions.import`, server
  `SheetsEndpoint.namedFunctions(itemUuid)` (stored-form formulas), dependencies come along, name
  conflicts skip unless *Replace* is checked (one choice for all).
