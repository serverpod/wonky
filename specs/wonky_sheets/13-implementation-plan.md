# Sheets 13 · Implementation Plan

This plan turns the Sheets specs into milestones and **parallel workstreams** that engineers
and AI coding agents can build with minimal interference. It aligns with the suite milestones
M0–M7 and states contracts to stub first, folder ownership, deliverables, acceptance tests,
dependencies, risks and the definition of done.

Spec map: [01-overview.md](01-overview.md) · [02-data-model.md](02-data-model.md) ·
[03-grid-and-editing.md](03-grid-and-editing.md) ·
[04-screens-menus-toolbar.md](04-screens-menus-toolbar.md) ·
[05-formula-engine.md](05-formula-engine.md) · [06-formatting.md](06-formatting.md) ·
[07-data-tools.md](07-data-tools.md) · [08-charts-and-objects.md](08-charts-and-objects.md) ·
[09-scripting.md](09-scripting.md) · [10-collaboration-history.md](10-collaboration-history.md) ·
[11-import-export-print.md](11-import-export-print.md) · [12-mcp-and-ai.md](12-mcp-and-ai.md).
Suite: [01-architecture.md](../01-architecture.md),
[08-commands-and-undo.md](../08-commands-and-undo.md),
[12-offline-and-sync.md](../12-offline-and-sync.md).

> **Superseded by RevLog (M13).** This is the historical plan the first iteration followed. Its
> sync parts — the `serverpod_offline_sync` engine, spaces, the reserved-space pool, the active
> set, subscriptions, the synced `ChangeLog` and its consumer, `SheetsWriter`/`SyncTxAdapter`,
> `RemoteChangeTracker`, the upstream requirements U1–U12 and the staged cell limits — were
> replaced by RevLog: [17 · RevLog sync](../17-revlog-sync.md) (plan:
> `plans/sheets-sync-migration/`). The current behavior is in 02, 10, 12 and suite 12/17; the
> notes below mark the main superseded items.

---

## 1. Milestones

| Milestone | Suite scope | Sheets scope | Exit gate |
|-----------|-------------|--------------|-----------|
| **M0** Restructure + foundations | Monorepo layout (01 §2), apps wired to `wonky_server` and served at `/write/`, `/sheets/`, `wonky_core`, `wonky_ui` skeleton, CI | `wonky_sync_models` with all synced Sheets tables (incl. Additions from 08–12 that touch synced schema, to avoid lock-step changes later), ids + fractional index + reference encoding, vendored `serverpod_offline_sync` patch (U11 helper, web fixes), package skeletons `wonky_sheets_core`, `wonky_sheets_script` (in `packages/`), the `wonky_sheets` app on `wonky_app`, contracts (§4) stubbed, the lint test for `columnValues`, multi-client sync harness v0 | `dart test` green; harness syncs 2 clients + server in isolates; schema hash frozen for M3 |
| **M1** Shell, auth, drive | Shell, auth, drive, sharing, command system, undo service | Sheets app boots inside `WonkyShell`; reserved spaces; `registerSpreadsheet`; subscribe/active set; custom sync endpoint with `onMergeSuccess`; `RemoteChangeTracker`; blank spreadsheet opens offline | Create spreadsheet offline → reconnect → appears in Drive for a collaborator |
| **M2** Write MVP | (Write team) | Sheets continues: `WorkbookModel` core, grid rendering read-only on fixtures, formula parser/codec | Grid renders 1M-cell fixture at 60 fps scroll (desktop) |
| **M3** Sheets MVP | — | Data model + sync + grid + selection/editing/clipboard/fill + core formulas (~150 functions) + basic formatting (number formats, fonts, colors, borders, alignment, merges, freeze) + undo + CSV import/export + 1M-cell limit + sheets/rows/cols ops + find/replace | **Perf gate** (suite 12 §5): 1M-cell import, cold sync < 60 s desktop / < 120 s web OPFS; recalculation and scroll budgets of 03/05; command test harness green |
| **M4** Collaboration | Presence, comments, versions, sharing↔space mirroring | Sheets presence + hints, comments/notes, version history (snapshots, view, diff, restore, copy), cell edit history, conflict review, activity | All scenarios of [10](10-collaboration-history.md) §10 pass in the harness |
| **M5** Advanced | — | Full formatting (CF, DV, banding, rich text), filters/filter views/slicers, sort variants, pivots, charts (P0+P1 types), XLSX/ODS import/export, PDF/print, named/protected ranges, groups, remaining functions (~450 total) | XLSX corpus round-trip; print goldens; chart goldens |
| **M6** MCP + AI + scripting | MCP server, UI bridge, assistant | `sheets.*` headless tools, `ui.sheets.*`, resources/prompts, AI features (formula suggestion, explain, fill, analyze, suggest-mode previews), scripting (compile service, client/server runtimes, bridge, editor, triggers, macros) | MCP integration suite; script conformance in all hosts; sandbox escape suite |
| **M7** Polish | Perf, a11y, i18n | Accessibility audit, localization (number/date locales, function name localization P2), performance tuning, raise cell limits as upstream U1–U5 land (5M, then 10M; superseded by RevLog: limits are raised against the gates of suite 17 part 7), P1 leftovers | Perf suite at the new limit; a11y checklist; no P0/P1 bugs open |

M2 is the Write MVP at suite level. Sheets work during M2 is foundational and runs in parallel
(the Sheets team is not blocked on Write).

---

## 2. Workstreams overview

| WS | Name | Milestone(s) | Depends on (contracts) | Owned folders |
|----|------|--------------|------------------------|---------------|
| WS-S1 | Sync models, ids, writer core, lint | M0 | — | `packages/wonky_sync_models/**`, `wonky_sheets_core/lib/mutations/**`, `wonky_sheets/lib/features/sync/sheets_writer.dart`, `wonky_sheets/test/sync/columns_lint_test.dart` |
| WS-S2 | Sync controller, spaces, subscriptions, custom sync endpoint, change tracking | M0–M1 | S1 | `wonky_server/lib/src/sheets/spaces/**`, `…/sheets/endpoints/sheets_sync_endpoint.dart`, `…/sheets/changelog/**` (consumer skeleton), `wonky_sheets/lib/features/sync/**`, `third_party/serverpod_offline_sync/**` |
| WS-S3 | WorkbookModel (AxisIndex, CellStore, RuleIndex) | M0–M2 | S1 | `wonky_sheets_core/lib/model/**`, `wonky_sheets/lib/features/model/**` (ingestion) |
| WS-S4 | Grid rendering | M2–M3 | S3 | `wonky_sheets/lib/features/grid/render/**` |
| WS-S5 | Selection, editing, clipboard, fill | M3 | S3, S4, S6 | `…/features/grid/interaction/**`, `…/features/formula_bar/**`, `…/features/clipboard/**` |
| WS-S6 | Formula parser and codec | M2 | S1 (ids) | `wonky_sheets_core/lib/formula/parser/**`, `…/formula/codec/**` |
| WS-S7 | Evaluator and dependency graph | M2–M3 | S3, S6 | `wonky_sheets_core/lib/formula/eval/**`, `…/formula/graph/**` |
| WS-S8 | Function library (parallel by category) | M3 (150), M5 (rest) | S7 (`FunctionImpl` API) | `wonky_sheets_core/lib/formula/functions/<category>/**` |
| WS-S9 | Number formats and formatting UI | M3, M5 | S3 | `wonky_sheets_core/lib/format/**`, `…/features/formatting/**` |
| WS-S10 | Conditional formatting and data validation | M5 | S7, S9 | `wonky_sheets_core/lib/rules/{cf,dv}/**`, `…/features/cf/**`, `…/features/dv/**` |
| WS-S11 | Sort, filter, filter views, slicers | M3 (sort), M5 | S3, S1 | `wonky_sheets_core/lib/data_tools/{sort,filter}/**`, `…/features/filters/**` |
| WS-S12 | Pivot tables | M5 | S7, S11 | `wonky_sheets_core/lib/pivot/**`, `…/features/pivot/**` |
| WS-S13 | Charts and objects | M5 | S3, S7, S9 | `wonky_sheets_core/lib/charts/**`, `…/objects/**`, `…/features/charts/**`, `…/features/objects/**` |
| WS-S14 | Import, export, print | M3 (CSV), M5 | S1, S3, S9, S13 (renderers) | `wonky_sheets_core/lib/io/**`, `…/features/import_export/**`, `…/features/print/**`, `wonky_server/lib/src/sheets/imports/**` |
| WS-S15 | Comments, presence, history | M4 | S2, S3, S4 | `…/features/collab/**`, `…/features/comments/**`, `…/features/history/**`, `wonky_sheets_core/lib/{snapshot,copy}/**`, `wonky_server/lib/src/sheets/versions/**` |
| WS-S16 | Scripting | M6 (spikes in M3–M5) | S3, S7, S1 | `packages/wonky_sheets_script/**`, `third_party/dart_eval/**`, `…/features/scripts/**`, `web_worker/`, `wonky_server/lib/src/sheets/scripts/**` |
| WS-S17 | MCP tools | M6 | S1 (planner), S3, S7, headless | `wonky_server/lib/src/sheets/mcp/**`, `…/sheets/headless/**`, `wonky_core/lib/mcp/sheets_tools.dart`, `wonky_sheets/lib/mcp/**` |
| WS-S18 | AI | M6 | S17 | `wonky_server/lib/src/platform/ai/prompts/sheets_*.dart`, `…/sheets/ai/**`, `…/features/ai/**` |
| WS-S19 | Menus, toolbar, panels chrome | M1–M5 | suite command system | `…/config/**` (MenuSpec, toolbar spec), `…/commands/commands.dart` (registration index), `…/features/chrome/**`, `…/features/common/**` (RangeInput, etc.) |

Rules for parallel work:
- A workstream **only edits its owned folders**. Cross-cutting changes go through a contract
  change PR reviewed by the owners of the affected workstreams.
- Commands: each workstream owns its `commands/<area>_commands.dart`; WS-S19 owns the
  registration index and `MenuSpec`/toolbar specs (others submit one-line additions).
- Synced schema changes are frozen at the end of M0 and changed only in batched releases
  (suite 01 §7). Additions from specs 08–12 that touch synced tables are applied in M0
  (see §8.1).

---

## 3. Workstream details

### WS-S1 · Sync models, ids, writer core, lint (M0)
- **Scope**: all `database: sync` models of [02](02-data-model.md) §3 plus synced Additions
  (A-08-1/2/3 enum/JSON only, A-09-1..4, A-11-1); `SheetsIds`, `FractionalIndex`,
  `CellContent` codec, reference token codec primitives, `GridRange` JSON;
  `RowChange`, `MutationPlan`, `SheetsMutationPlanner` skeleton with the first ops
  (`SetCells`, `InsertRows/Cols`, `DeleteRows/Cols`, `AddSheet`, `RenameSheet`); client
  `SheetsWriter` applying plans with `columnValues` and `ChangeLog`; undo handler for domain
  `sheets.rows`.
- **Contracts first**: `RowChange`, `MutationPlan`, `SyncTxAdapter` (§4.1).
- **Deliverables**: models + generated code; unit tests; **lint test** that scans
  repositories/writers for synced updates without `columnValues` (toptap pattern) and fails CI.
- **Acceptance**: fractional index property tests (ordering, density, `nBetween` evenness);
  deterministic cell ids; planner ops round-trip with undo (execute → undo → state equal).

### WS-S2 · Sync controller and spaces (M0–M1)
- **Scope**: `SheetsSyncController` lifecycle; reserved space pool;
  `SheetsEndpoint.reserveSpaces/subscribe/ensureSubscribed/spaceStats`; active set eviction job;
  custom sync endpoint `sheetsSync.sync` with `onMergeSuccess` fan-out (`session.messages`
  `sheets:merged:<space>`); `ChangeLog` consumer skeleton (cursor per space, idempotent);
  client `RemoteChangeTracker` (U11 helper in the vendored engine); pending-change guard; web
  OPFS/IndexedDB setup; recovery export on open failure.
- **Contracts**: `RemoteChangeSink` (model ingestion interface), `ChangeLogConsumer` plugin
  interface (§4.6) so later workstreams register consumers (versions, triggers, history,
  notifications) without touching this code.
- **Acceptance**: harness tests: offline create → sync → collaborator sees it; membership
  mirroring of roles; eviction never removes pinned/dirty spaces; consumer exactly-once per
  ChangeLog row across server restarts.
- **Superseded by RevLog (M13):** `SheetsRevLog` + `LoggedWorkbookSession` (client),
  `SheetsDocEndpoint.connect` stream, `SheetsRevBinding` and durable post-commit hooks
  (server); offline creation with client file UUIDs (suite 17 parts 4–6).

### WS-S3 · WorkbookModel (M0–M2)
- **Scope** (pure Dart in `wonky_sheets_core/lib/model/`): `AxisIndex` (ordered ids,
  id→index map, Fenwick sizes, hidden), `CellStore` (sparse columnar, format attribute tables),
  `RuleIndex` (interval trees for merges, CF, DV, protections, filters, banding, objects),
  `WorkbookModel` (sheets, named ranges, change events), A1 ↔ id resolution, used range;
  Flutter ingestion from SQLite (viewport-first loading, 10k-row chunks), `ComputedValueCache`.
- **Contracts**: `CellSource` / `WorkbookReader`, `WorkbookChangeEvent` (§4.2).
- **Acceptance**: 1M-cell fixture loads < 3 s from SQLite on desktop; pixel↔index lookups
  O(log n) verified; incremental patch from `RemoteChangeTracker` equals full reload (property
  test).

### WS-S4 · Grid rendering (M2–M3)
- **Scope**: `TwoDimensionalScrollView`-based (`two_dimensional_scrollables`) or custom
  render object grid per [03](03-grid-and-editing.md): layers (cells, CF, borders, merges,
  objects slot, selection, remote presence slot, frozen panes), text layout cache, overflow,
  headers, zoom, light/dark tokens, hidden rows/cols, gridlines.
- **Contracts**: `GridLayer` plug-in API (§4.4) so S10, S13, S15 add layers without editing
  the core painter.
- **Acceptance**: golden suite (formats × themes × zoom); scroll 60 fps with 1M cells;
  layer API used by a sample layer.

### WS-S5 · Selection, editing, clipboard, fill (M3)
- **Scope**: selection model (ranges, active cell, keyboard navigation, Ctrl+arrows), cell
  editor + formula bar (with formula autocomplete and range highlighting), `CellInputParser`,
  clipboard (internal JSON, TSV, HTML), paste special, fill handle (series detection), drag-move,
  `sheets.edit.*` commands.
- **Contracts**: `SelectionModel` (§4.4), `CellInputParser` (shared with import and MCP).
- **Acceptance**: command harness for all edit commands; paste 100k cells < 2 s as one undo
  step; typing coalescing.

### WS-S6 · Formula parser and codec (M2)
- **Scope**: `petitparser` grammar for Google-Sheets-compatible formulas (locale-aware
  separators), AST, `FormulaCodec.toStored/toA1`, reference adjustment helpers (for fill/copy),
  pretty-printer, syntax highlighting tokens.
- **Contracts**: AST node types, `FormulaCodec` (§4.3).
- **Acceptance**: parse/print round-trip corpus (≥ 5,000 formulas from public datasets),
  fuzzing (no crash, bounded time), `#REF!` rendering for missing ids.

### WS-S7 · Evaluator and dependency graph (M2–M3)
- **Scope**: value types (incl. arrays, errors, `#LOADING`), evaluator, dependency graph with
  range nodes, dirty propagation, recalculation scheduler (incremental, background isolate on
  native / time-sliced on web), spills, iterative calculation, volatile handling,
  custom-function hook (`CustomFunctionProvider`), `evaluateWithTrace`.
- **Contracts**: `FunctionImpl` API + `FunctionRegistry`, `RecalcBatch` events (§4.3).
- **Acceptance**: recalculation budgets of [05](05-formula-engine.md); correctness vs reference
  values; spill conflicts; cycles.

### WS-S8 · Function library (M3: ~150, M5: rest)
- **Parallelizable by category**: each category is an independent work item with its own folder
  and test fixture file: math & trig, statistical, text, logical, lookup & reference, date &
  time, financial, information, engineering, array (FILTER/SORT/UNIQUE/SEQUENCE…), database,
  parser/web (IMPORT*, P2), Google-specific (QUERY (own sub-project), SPLIT, REGEX*,
  ARRAYFORMULA), LAMBDA family.
- **Acceptance**: per-function test vectors generated from Google Sheets/Excel/LibreOffice
  (checked-in JSON fixtures; tolerance rules); function help metadata (for autocomplete and AI).

### WS-S9 · Number formats and formatting UI (M3, M5)
- **Scope**: number format parser/formatter (patterns, locales, dates, durations, fractions,
  currencies), presets, custom format dialog, toolbar/menus for fonts, colors
  (`WonkyColorPicker`), borders, alignment, wrap, rotation, merges, paint format, clear
  formatting, theme (spreadsheet theme dialog), banding UI (M5), rich text in cells (M5).
- **Acceptance**: format corpus vs Excel/Sheets outputs; goldens of dialogs light/dark.

### WS-S10 · CF and DV (M5)
- **Scope**: rule models, evaluation (`RuleIndex` + formula engine), CF render layer, DV
  enforcement in the editor, dropdown chips/arrows, checkboxes, date picker, side panels.
- **Acceptance**: rule type matrix tests; goldens; undo; concurrency (both rules survive).

### WS-S11 · Sort, filter, filter views, slicers (M3 sort, M5 rest)
- **Scope**: sort (full-row via `sortKey` rewrite; partial-range via content moves), basic
  filter (criteria, computed hidden rows), filter views (URL, per-user temporary views),
  slicers (with S13 object layer).
- **Acceptance**: sort stability and locale collation; filter criteria matrix; harness
  scenarios 8–9 of [10](10-collaboration-history.md) §10.

### WS-S12 · Pivot tables (M5)
- **Scope**: pivot engine (grouping, aggregations, show-as, calculated fields, date grouping),
  overlay rendering anchored at cells, editor panel, drill-down (P1).
- **Acceptance**: result fixtures vs Google Sheets; 1M-row source < 2 s.

### WS-S13 · Charts and objects (M5)
- See [08](08-charts-and-objects.md) §19. Spike in M3: `ChartScene` + Flutter painter + PDF
  renderer for column/line to validate the renderer-independent design.
- **Acceptance**: [08](08-charts-and-objects.md) §21.

### WS-S14 · Import, export, print (M3 CSV, M5 rest)
- See [11](11-import-export-print.md). Decided: own OOXML reader/writer (`archive` + `xml`, 11 §5.1); M3 perf check of a 1M-cell
  workbook (performance, memory, API gaps) → decision record.
- **Acceptance**: [11](11-import-export-print.md) §11.

### WS-S15 · Comments, presence, history (M4)
- See [10](10-collaboration-history.md) §13.
- **Acceptance**: [10](10-collaboration-history.md) §15.

### WS-S16 · Scripting (M6; spikes earlier)
- **Spikes** (M3–M5, one engineer/agent part-time):
  1. dart_eval 0.8.5 compile of the API bindings + `executeLib` round trip on web worker (dart2js)
     and desktop isolate; measure bundle size and call overhead.
  2. `Mailbox` sync channel and SharedArrayBuffer/Atomics channel prototypes; COOP/COEP impact on
     the Flutter web build (fonts, images, sqlite worker).
  3. Patches DE-1 (positions) and DE-2 (checkpoints) feasibility.
- **Build**: `wonky_sheets_script` packages (API, bindings, plugin, protocol, guest, host,
  compiler), server compile service + script workers + scheduler + job queue + URL fetch proxy,
  client `ScriptService` + guests + `ClientScriptHost`, custom function provider, editor route,
  triggers dialog, executions panel, macro recorder (P1), MCP script tools.
- **Acceptance**: [09](09-scripting.md) §20 and the test plan §21.

### WS-S17 · MCP tools (M6)
- **Scope**: `HeadlessWorkbook` + cache + invalidation, `ServerSheetsWriter`,
  `ServerChangeRecord` + `changes.revert`, all `sheets.*` tools, resources/prompts,
  `ui.sheets.*` bridge tools in the app.
- **Acceptance**: [12](12-mcp-and-ai.md) §9 items 1–7.

### WS-S18 · AI (M6)
- **Scope**: `SheetsContextBuilder`, prompts, suggest-mode shadow workbook + preview dialog,
  formula suggestion, explain, fill, analyze, describe chart, confirmations; P2 `AI()`.
- **Acceptance**: [12](12-mcp-and-ai.md) §9 items 8–11; eval thresholds.

### WS-S19 · Menus, toolbar, panels chrome (M1–M5)
- **Scope**: `SheetsAppConfig`, `MenuSpec` for all Sheets menus, toolbar spec, sheet tabs bar,
  status bar (sum/avg/count), side panel registrations, shared Sheets widgets (`RangeInput`,
  `WonkyAccordionSection`), keyboard scopes (`grid`, `cellEditor`, `scriptEditor`), command
  palette providers ("Go to sheet", "Go to named range", "Go to chart").
- **Acceptance**: every menu item maps to a registered command; `ui.get_menu_tree` snapshot
  test; overflow behavior at narrow widths; a11y focus order.

---

## 4. Contracts to stub first (M0)

Interfaces are stubbed with fakes in M0 so all workstreams can start in parallel. Names are
binding unless changed via a contract PR.

### 4.1 Writes

```dart
/// wonky_sheets_core/lib/src/mutations/row_change.dart (exported by lib/model.dart)
enum RowOp { insert, update, delete }
final class RowChange {
  final String table;                     // 'cell', 'sheet_row', …
  final UuidValue rowId;
  final RowOp op;
  final Map<String, Object?> columnsBefore; // touched columns; full row for delete (undo revives it)
  final Map<String, Object?> columnsAfter;  // touched columns; full row for insert
}
final class MutationPlan {
  final String label;                     // undo label
  final ChangeSummary summary;            // → ChangeLog.summaryJson (kinds, sheets, ranges, deleted ids…)
  final List<RowChange> changes;          // ordered; chunked by the writer (≤ 5,000)
  final Map<String, Object?>? detail;     // ≤ 200 cells before/after → ChangeLog.detailJson
}
final class SheetsMutationPlanner {              // throws PlanException(code, message)
  MutationPlan plan(SheetsOperation op, WorkbookModel model, PlanContext ctx);
}
// Undo: UndoInverter.invert(plan, currentRowReader) applies the per-column skip rule.
sealed class SheetsOperation { /* SetCells, Format, InsertRows, DeleteRows, MoveDimension,
  AddSheet, …, AddChart, UpdateObject, SetPrintSettings, ScriptFileSave, … */ }

/// Implemented by SheetsWriter (client) and ServerSheetsWriter (server).
abstract interface class SyncTxAdapter {
  Future<void> apply(MutationPlan plan, {required String actorKind, required String sessionId});
}
```

Superseded by RevLog (M13): plans are committed by the client session (outbox, op groups) and on
the server by `submitServerChange`; summary and detail go into the op (`rev_op.summaryJson`,
`detailJson`), 02 §3.7 and §7.

### 4.2 Model

```dart
abstract interface class WorkbookReader {
  SpreadsheetMeta get meta;
  List<SheetMeta> get sheets;
  AxisIndex rows(String sheetId);
  AxisIndex columns(String sheetId);
  CellRecord? cell(String sheetId, UuidValue rowId, UuidValue colId);
  Iterable<CellRecord> cellsIn(ResolvedRange range);
  RuleIndex rules(String sheetId);
  ResolvedRange resolve(GridRange r);
  ResolvedRange parseA1(String a1, {String? contextSheetId});
}
abstract interface class CellSource {          // used by formula engine, charts, exporters
  FormulaValue valueAt(String sheetId, int row, int col);
  EffectiveFormat formatAt(String sheetId, int row, int col);
  bool isHidden(String sheetId, Dimension d, int index, {bool includeFilter = true});
}
sealed class WorkbookChangeEvent { /* CellsChanged(ranges), StructureChanged(sheetId, dim),
  SheetsChanged, RulesChanged(kind), ObjectsChanged, RecalcBatch(changedCells) */ }
```

### 4.3 Formulas

```dart
abstract interface class FormulaCodec {
  String toStored(String a1Formula, FormulaContext ctx);   // throws FormulaParseError
  String toA1(String storedFormula, FormulaContext ctx);
}
abstract interface class FunctionImpl {
  String get name;                        // upper-case
  FunctionSignature get signature;        // arity, arg kinds (value/range/lazy), volatile, array-aware
  FormulaValue call(List<ArgValue> args, EvalContext ctx);
  FunctionHelp get help;                  // for autocomplete, AI, docs
}
abstract interface class CustomFunctionProvider { /* see 09 §8.6 */ }
```

### 4.4 Grid

```dart
// wonky_sheets/lib/features/grid/paint/grid_layer.dart (as built)
abstract class GridLayer {
  int get zOrder;            // GridZ: background 0, gridlines 50, cells 100, cf 150, borders 200,
                             // decorations 250, objects 400, find 450, presence 500,
                             // referenceBoxes 550, selection 600, dragFeedback 700, headers 900
  Listenable? get repaint;   // extra repaint signal (null = repaint with the grid)
  void paint(GridPaintContext ctx, Canvas canvas);   // ctx.forEachPane(canvas, (pane) {...})
}
// Layers with zOrder < 500 are painted by the content pass, the others by the overlay pass.
// Register: SheetEditorController.layers.add(layer) / remove(layer).
// Conditional formatting plugs into CellRenderCache.conditional (ConditionalOverlayProvider).
```

The selection model is `GridSelectionController` (id-based `GridSelection`, resolved to
`ResolvedSelection`; `setRanges`, `selectCell`, `extendTo`, `selectRows/Columns/All`).

### 4.5 Scripts, headless, IO

```dart
abstract interface class WorkbookAccess { /* 09 §3.2 */ }
abstract interface class HeadlessWorkbookProvider {
  Future<HeadlessWorkbook> open(UuidValue spaceId);       // cached
}
abstract interface class SpreadsheetImporter { Stream<ImportEvent> import(ByteStream data, ImportOptions o); }
abstract interface class SpreadsheetExporter { Stream<List<int>> export(WorkbookReader m, CellSource v, ExportOptions o); }
```

### 4.6 Server consumers

```dart
abstract interface class ChangeLogConsumer {
  String get id;                                   // 'versions', 'triggers', 'cellHistory', …
  Future<void> consume(Session session, UuidValue spaceId, List<ChangeLogRow> rows);
}
```

Superseded by RevLog (M13): consumers are RevLog post-commit hooks (`RevHook`, suite 17 part 5
§6), and headless models are leases of `HeadlessFileCache` (part 5 §9;
`HeadlessWorkbookProvider.open` remains as the Sheets wrapper).

---

## 5. Dependency graph

```
            ┌────────┐
            │ WS-S1  │ models · ids · planner · writer · lint
            └───┬────┘
      ┌─────────┼───────────────┬───────────────┐
      ▼         ▼               ▼               ▼
  ┌──────┐  ┌──────┐        ┌──────┐        ┌──────┐
  │ S2   │  │ S3   │◄───────│ S6   │        │ S19  │ chrome (needs suite commands)
  │ sync │  │model │        │parser│        └──────┘
  └──┬───┘  └─┬──┬─┘        └──┬───┘
     │        │  └──────┐      │
     │        ▼         ▼      ▼
     │     ┌──────┐   ┌──────────┐
     │     │ S4   │   │   S7     │ evaluator + graph
     │     │ grid │   └────┬─────┘
     │     └──┬───┘        │
     │        ▼            ▼
     │     ┌──────┐   ┌──────────┐   ┌──────┐
     │     │ S5   │   │ S8 (×N)  │   │ S9   │ number formats
     │     │ edit │   │functions │   └──┬───┘
     │     └──────┘   └──────────┘      │
     │        ┌─────────────┬───────────┼───────────┬────────────┐
     │        ▼             ▼           ▼           ▼            ▼
     │     ┌──────┐     ┌──────┐    ┌──────┐    ┌──────┐     ┌──────┐
     │     │ S10  │     │ S11  │───►│ S12  │    │ S13  │────►│ S14  │ (renderers for PDF/XLSX charts)
     │     │CF/DV │     │filter│    │pivot │    │charts│     │ io   │
     │     └──────┘     └──────┘    └──────┘    └──────┘     └──────┘
     ▼
  ┌──────┐   ┌──────────────┐   ┌──────┐
  │ S15  │   │ S17 MCP      │──►│ S18  │ AI
  │collab│   │ (S1 S3 S7)   │   └──────┘
  └──────┘   └──────┬───────┘
                    ▼
               ┌──────────┐
               │ S16      │ scripting (S3, S7, S17 headless)
               └──────────┘
```

Critical path to M3: S1 → S3 → S4 → S5, and S6 → S7 → S8 (150 functions), with S2 in
parallel. S9 (number formats) is needed by S4 for display, so a minimal formatter
(general/number/percent/date) ships in M2 and the full one in M3.

---

## 6. Parallelization schedule (indicative)

| Phase | Parallel tracks (agents/engineers) |
|-------|-------------------------------------|
| M0 (2–3 weeks) | S1 (2), S2-engine-patch (1), S3 skeleton + fakes (1), S6 grammar (1), harness (1) |
| M1 (3 weeks) | S2 (2), S3 ingestion (1), S6 codec (1), S7 skeleton (1), S19 config (1) |
| M2 (4 weeks) | S3 (1), S4 (2), S7 (2), S8 categories (3–5 in parallel), S9 minimal (1) |
| M3 (6 weeks) | S4 (1), S5 (2), S7 (1), S8 (4), S9 (1), S11 sort (1), S14 CSV (1), S19 (1), perf (1), spikes S13/S14/S16 (1) |
| M4 (4 weeks) | S15 (3), S2 polish (1), S8 (2), S9 (1) |
| M5 (8 weeks) | S10 (2), S11 (2), S12 (2), S13 (2), S14 (3), S8 (2), S9 (1), S19 (1) |
| M6 (8 weeks) | S16 (3), S17 (2), S18 (2), S19 (1) |
| M7 (6 weeks) | perf (2), a11y (1), i18n (1), bugs (all) |

Agents work best on items with a clear contract and test fixture: function categories (S8),
importer/exporter mappings (S14), chart types (S13), MCP tools (S17, one tool per task), and
script API members (S16, one class per task) are explicitly sliced that way.

---

## 7. Testing strategy

### 7.1 Unit tests
Pure Dart packages (`wonky_sheets_core`, `wonky_sheets_script`, `wonky_sync_models`) have
≥ 90 % line coverage on logic folders. Table-driven fixtures in JSON for functions, formats,
recommendations, importers.

### 7.2 Command tests
Suite rule: every command has execute → undo → redo equality tests (state + selection), run
headless against an in-memory sync DB (`CommandTestHarness` in `wonky_sheets/test/harness/`).

### 7.3 Multi-client sync harness (property/fuzz)
Modelled on toptap's approach: a server (`serverpod_test` with the offline-sync engine) and
N simulated clients, **each in its own isolate** with its own SQLite file, `WorkbookModel`,
`SheetsWriter` and undo stack.
- **Scripted scenarios**: [10-collaboration-history.md](10-collaboration-history.md) §10
  table (every row), charts concurrency ([08](08-charts-and-objects.md) §15.2), scripts LWW.
- **Property tests**: random operation sequences (edits, formats, row/col inserts/deletes/moves,
  sheet ops, sorts, merges, undo/redo) on 2–4 clients with random online/offline toggles and
  partitions. Invariants after full sync: all replicas byte-identical (canonical dump);
  maintenance invariants hold (no overlapping merges, unique sheet names, valid anchors);
  formulas never refer to wrong cells (each formula's referenced cell ids exist or render
  `#REF!`); undo of client A never modifies a column last written by client B (suite 08 §4).
- Seeds recorded; failures shrink to minimal sequences; nightly long runs (10k sequences).
- **Superseded by RevLog (M13):** clients run against the in-process RevLog server
  (`FakeRevServer`/`FakeRevHub`, suite 17 As built 16; `wonky_sheets/test/revlog/support/`,
  `test/features/collab/offline_scenarios_test.dart`); the RevLog property tests are listed in
  suite 17 part 3 §7 and the plan's testing file.

### 7.4 Golden tests
Grid rendering (formats, merges, borders, CF, overflow, RTL, zoom, light/dark), panels,
charts, print pages. Goldens are generated on CI Linux with bundled fonts only.

### 7.5 Performance suite
Fixtures: 100k, 1M (and later 5M/10M) cell spreadsheets of three shapes (wide, tall,
formula-heavy). Metrics: cold open from SQLite, cold sync (desktop, web OPFS), scroll frame
times, edit-to-paint latency, recalculation of 100k dependent formulas, paste 100k cells, sort
1M rows, CSV/XLSX import/export, PDF of 100 pages, chart with 1M points, headless MCP read of
100k cells. Run nightly on reference hardware; regressions > 10 % fail the build.

**As built:** `slow`-tagged timings — `wonky_sheets/test/sync/writer_perf_test.dart` (local
writer: `BLOCKS=20` 100k cells ≈ 8 s, `BLOCKS=200` 1M cells ≈ 2 min on a loaded dev machine,
5,000 updates ≈ 0.2 s), `test/sync/viewport_loading_test.dart` (200k-cell open),
`wonky_server/test/integration/sheets/sync/server_writer_perf_test.dart` (`ROWS=2500`: 50k-cell
`set_values`, revert, redo). Remaining cost at 1M cells: commits of random-UUID index pages
(cell ids, `crdt_data_rows`), and deleting rows/columns on the server runs the full FK
projection (~8 s per 500 rows at 50k cells).

**Superseded by RevLog (M13):** the sync and write timings above measured the old engine. The
sync performance budgets are the RevLog gates P1–P12 of [17](../17-revlog-sync.md) part 7
(propagation, server commits, cold open and complete download of 1M cells, reopen from cache,
1M-cell local and server imports, storage per cell, protected-file commits); the rest of this
suite (grid, formulas, import/export, print, charts) is unchanged.

### 7.6 Integration tests
`flutter_driver`-based app tests (skill `flutter-add-integration-test`) driven through the
Serverpod MCP and the app's UI bridge: create spreadsheet, type, format, chart, print preview,
script editor run, comments, version restore. Server integration tests for all endpoints and
MCP tools (`serverpod_test`).

### 7.7 Compatibility corpora
Formula compatibility (function vectors vs Google Sheets/Excel/LibreOffice), XLSX/ODS corpus
with LibreOffice headless validation ([11](11-import-export-print.md) §12), script conformance
corpus run in three hosts ([09](09-scripting.md) §21).

### 7.8 Security tests
Sandbox escape suite, SSRF matrix, permission matrix for tools/commands per role, protected
ranges, prompt-injection corpus.

---

## 8. Risk register

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|------------|-------|
| R1 | `serverpod_offline_sync` maturity (0.0.x): bugs, scale limits, missing hooks (U1–U11) | High | High | Vendored patch with tests; staged cell limits; harness catches regressions; close collaboration with upstream; abstraction (`SyncTxAdapter`, `RemoteChangeSink`) limits blast radius. *Superseded by RevLog (M13): the engine was replaced (suite 17)* | S2 |
| R2 | Large spreadsheets: sync volume and memory (1M → 10M cells) | High | High | Per-cell rows only for non-empty cells; column default formats; op detail cap; viewport-first bootstrap pages; RevLog performance gates (suite 17 part 7) before raising the cell limit. *Superseded by RevLog (M13): the upstream items U3/U5 no longer apply* | S2/S3 |
| R3 | Web SQLite/OPFS availability and performance (Safari, private mode, IndexedDB fallback) | Medium | High | Detect and warn; limited offline on fallback (200,000 cells kept offline, suite 17 part 6 §2.5); the cache is never the source of truth, so a dropped cache only re-downloads; `--wasm` builds; perf suite on all browsers | S2 |
| R4 | Synced schema changes are lock-step | Medium | Medium | Front-load Additions into M0; batch releases; recovery export path. *Superseded by RevLog (M13): additive schema changes are accepted within a window; the client re-encodes its outbox (suite 17 part 2 §4.3)* | S1 |
| R5 | `dart_eval` performance and language coverage | High | Medium | Subset lint, bulk APIs, batching, vendored patches, conformance corpus; host protocol engine-agnostic (QuickJS fallback possible) | S16 |
| R6 | Synchronous bridge on web (COOP/COEP) breaks other resources | Medium | Medium | Same-origin resources; spike in M3; snapshot-mode fallback; run-on-server option | S16 |
| R7 | Formula compatibility with Google Sheets/Excel (≈ 450 functions, edge cases, QUERY) | High | Medium | Category-parallel work, test vectors from real apps, explicit unsupported list, import reports | S8 |
| R8 | Grid rendering performance on web (CanvasKit/skwasm text cost) | Medium | High | Text layout cache, glyph atlas experiments, layer repaint isolation, perf gate in M2 | S4 |
| R9 | Own OOXML reader/writer gaps/performance at 1M cells | Medium | Medium | Corpus + LibreOffice validation; streaming parts; IR boundary keeps fixes local | S14 |
| R10 | Concurrency surprises (LWW on whole JSON specs, partial-range sorts) | Medium | Medium | Read-modify-write within transactions; documentation; conflict review UI; full-row sorts preferred | S11/S13/S15 |
| R11 | Advisory protection bypass (U9) | Medium | Low | Documented; ChangeLog-based warnings; server-side enforcement for MCP/scripts. *Superseded by RevLog (M13): the sequencer enforces protections (07 §10.3)* | S10/S17 |
| R12 | AI cost and prompt injection | Medium | Medium | Budgets, caching, confirmations, data-tag wrapping, no sharing tools, eval suite | S18 |
| R13 | Many parallel agents editing shared files | Medium | Medium | Folder ownership, contract PRs, registration indexes owned by S19, CI checks for forbidden imports | all |
| R14 | Vendored packages (`serverpod_offline_sync`, `dart_eval`, candidates) drift from upstream | Medium | Medium | Patch logs, upstream PRs (the sync module is Serverpod-owned), deliberate re-sync per upgrade (suite 01 §2.3). *Superseded by RevLog (M13) for the sync module* | S2, S16 |

---

## 9. Cross-spec decisions (resolved)

Questions raised while writing specs 01–13, and where they were settled:

1. **Chart library** — own pure-Dart chart engine ([08](08-charts-and-objects.md) §6); no
   `fl_chart`. Suite 01 §2.1 updated (`wonky_sheets_core` may use `image`, `pdf`,
   `timezone`).
2. **Model location** — `WorkbookModel` and `SheetsMutationPlanner` live in
   `wonky_sheets_core` ([02](02-data-model.md) §6).
3. **Shortcuts** — macros keep `Mod+Alt+Shift+0…9`; side panels cycle with
   `Mod+Alt+Shift+[`/`]` (suite 02 §4.5). Command palette `Mod+Shift+P`, `Mod+K` = Insert link
   (suite 08 §1.3).
4. **Undo domain `sheets.serverChange`** — added to suite 08 §3.3.
5. **Presence extensions and comment orphan fields** — suite 07 updated.
6. **Personal space** — implicit in the engine (UUID = user id, always `readWrite`); no
   creation step. *Superseded by RevLog (M13): no personal space; script user properties are
   a server table (09 §6.9).*
7. **Dependencies** — `native_synchronization` (script), `re_editor` and `super_clipboard`
   (Flutter app) added to suite 01 §2.1.
8. **COOP/COEP** — both web apps are cross-origin isolated; external images go through the
   image proxy (suite 13 §3).
9. **Script workers** — separate deployment role, see suite 13 §3.
10. **Version history permission** — Editor+ (suite 07 §5).
11. **Sort semantics** — full-row sorts rewrite `SheetRow.sortKey` and re-pin references; partial
   sorts move contents ([07](07-data-tools.md)).
12. **Conditional formatting priority** — Google semantics by default (`stopIfTrue: true` for
   rules created in Wonky; XLSX-imported rules keep Excel's flag) ([06](06-formatting.md) §15.8).

---

## 10. Definition of done (every work item)

- Code in the owned folders; contracts unchanged or changed via an approved contract PR.
- Commands registered with stable ids, args schema, titles, icons, shortcuts, menu entries;
  execute/undo/redo tests pass; `ui.invoke_command` works.
- Light and dark mode verified (goldens or widget previews per the `flutter-add-widget-preview`
  skill); no overflow at 360 px for panels/dialogs.
- Keyboard operable; semantics labels; screen-reader announcements where specified.
- Offline behavior as specified (and tested with the harness when it touches synced data).
- All writes name only the columns they change; ops carry the correct `actorKind` and labels.
- MCP: tools/bridge coverage where the spec requires it, with integration tests.
- Unit, widget, golden and integration tests added; perf budgets measured if applicable.
- Docs: in-app help entries for user-visible features; spec updated if behavior differs.
- No new analyzer warnings; `dart format`; CI dependency-rule check passes.
