# Sheets 01 · Overview

Wonky Sheets is the spreadsheet app of the Wonky Work suite: a collaborative, **offline-first**
spreadsheet for web and desktop, built with Flutter + `shad` on the client and a single
Serverpod server, synced through RevLog (suite [17](../17-revlog-sync.md)). The product target is
**Google Sheets feature parity where possible**, with three deliberate differences:

1. **Offline is normal.** Every spreadsheet opened on a device is kept in a local SQLite cache;
   every editing feature works without a connection, edits are kept in a durable outbox and sent
   on reconnect ([02-data-model.md](02-data-model.md),
   suite [12-offline-and-sync.md](../12-offline-and-sync.md)). Large spreadsheets open
   viewport-first from the server and load the rest in the background.
2. **Everything is a command.** Every menu item, toolbar control, shortcut and context-menu entry
   is a command `sheets.<area>.<action>` that is undoable (when it mutates) and callable by MCP
   and the AI assistant (suite [08-commands-and-undo.md](../08-commands-and-undo.md),
   [09-mcp.md](../09-mcp.md)).
3. **Scripting in Dart** (`dart_eval`) instead of Apps Script ([09-scripting.md](09-scripting.md)).

Read this file first, then [02-data-model.md](02-data-model.md) (authoritative storage model),
then the spec for the area you are building.

---

## 1. Users and core jobs

| Persona | Core jobs in Sheets |
|---------|---------------------|
| Analyst | Import CSV/XLSX, clean data, formulas, pivot tables, charts, filters, export. |
| Team lead | Shared trackers (dropdowns, checkboxes, protected ranges), comments, notifications, version restore. |
| Power user | Keyboard-only operation, named ranges/functions, macros, custom functions, triggers. |
| AI agent | Headless read/write via MCP `sheets.*` tools; live UI control via `ui.*` bridge. |

## 2. Feature list by area

Priority: **P0** = required for the first Sheets release (milestone M3, see
[13-implementation-plan.md](13-implementation-plan.md)); **P1** = required for "complete" v1;
**P2** = after v1 / nice to have.

### 2.1 Workbook, sheets, grid
| Feature | Pri | Spec |
|---------|-----|------|
| Create/open/rename spreadsheet (drive integration, offline creation with client UUIDs) | P0 | suite 05, 17 |
| Multiple sheets: add, delete, duplicate, rename, reorder (drag), color, hide/unhide, copy to other spreadsheet | P0 (copy-to P1) | [04](04-screens-menus-toolbar.md) §6 |
| Virtualized grid ≥ 1M cells at 60 fps, zoom 50–200 % | P0 | [03](03-grid-and-editing.md) §2 |
| Frozen rows/columns (menu + drag freeze bar) | P0 | [03](03-grid-and-editing.md) §4 |
| Insert/delete/move/hide/resize rows & columns, auto-fit | P0 | [03](03-grid-and-editing.md) §13 |
| Insert/delete cells with shift | P1 | [03](03-grid-and-editing.md) §13 |
| Merge cells (all / horizontal / vertical) | P0 | [06](06-formatting.md) §10 |
| Row/column groups (outline) | P1 | [07](07-data-tools.md) |
| Right-to-left sheets | P2 | [03](03-grid-and-editing.md) §2.11 |

### 2.2 Editing and navigation
| Feature | Pri | Spec |
|---------|-----|------|
| Selection model (multi-range, whole row/col, Mod+A region/all) | P0 | [03](03-grid-and-editing.md) §6 |
| Complete Google-Sheets keyboard map | P0 | [03](03-grid-and-editing.md) §7 |
| In-cell editor + formula bar, enter/edit/point modes | P0 | [03](03-grid-and-editing.md) §8 |
| Locale-aware input parsing (numbers, %, currency, dates, times, booleans) | P0 | [03](03-grid-and-editing.md) §8.6, [06](06-formatting.md) §5.9 |
| Formula editing: syntax colors, colored reference boxes, point-to-reference, F4, function autocomplete + signature help | P0 | [03](03-grid-and-editing.md) §8.7 |
| Column-value autocomplete while typing | P1 | [03](03-grid-and-editing.md) §8.5 |
| Fill handle (copy, series, custom lists, double-click fill) | P0 | [03](03-grid-and-editing.md) §10 |
| Drag-move / drag-copy ranges | P1 | [03](03-grid-and-editing.md) §11 |
| Clipboard with formats, paste special (8 modes), external TSV/CSV/HTML paste | P0 (HTML P1) | [03](03-grid-and-editing.md) §12 |
| Find & replace (regex, formulas, all sheets) | P0 | [07](07-data-tools.md) |
| Notes, hyperlinks, checkboxes, dropdown chips | P0 | [03](03-grid-and-editing.md) §14 |
| Smart chips (people, date) | P2 | [03](03-grid-and-editing.md) §14.5 |

### 2.3 Formatting
| Feature | Pri | Spec |
|---------|-----|------|
| Font family/size, bold/italic/underline/strike, text & fill color | P0 | [06](06-formatting.md) |
| Number formats: presets, custom patterns (Sheets/Excel syntax), custom currency, date/time | P0 (custom editor P1) | [06](06-formatting.md) §5 |
| Borders (10 presets, 6 styles, colors) | P0 | [06](06-formatting.md) §8 |
| Alignment, wrapping, rotation | P0 (rotation P1) | [06](06-formatting.md) §9 |
| Rich text runs inside a cell | P1 | [06](06-formatting.md) §11 |
| Paint format, clear formatting | P0 | [06](06-formatting.md) §2–3 |
| Spreadsheet themes | P1 | [06](06-formatting.md) §13 |
| Alternating colors (banding) | P1 | [06](06-formatting.md) §14 |
| Conditional formatting: single color, custom formula, color scale | P0 | [06](06-formatting.md) §15 |
| CF data bars | P1 · icon sets P2 | [06](06-formatting.md) §15 |

### 2.4 Formulas
| Feature | Pri | Spec |
|---------|-----|------|
| Parser, id-based references, A1/R1C1 display, cross-sheet refs | P0 | [05](05-formula-engine.md) |
| ~400 functions (math, stat, text, date, lookup, logical, info, financial, engineering, array, database, web-free) | P0 core 200 · P1 rest | [05](05-formula-engine.md) |
| Dynamic arrays / spill, ARRAYFORMULA, LAMBDA, LET, named functions | P0 spill · P1 LAMBDA | [05](05-formula-engine.md) |
| Incremental recalculation, iterative calculation, volatile functions | P0 | [05](05-formula-engine.md) |
| Custom functions written in Dart | P1 | [09](09-scripting.md) |

### 2.5 Data tools
| Feature | Pri | Spec |
|---------|-----|------|
| Sort sheet/range (advanced, multi-column) | P0 | [07](07-data-tools.md) |
| Basic filter, filter views | P0 · views P1 | [07](07-data-tools.md) |
| Data validation (list, range, checkbox, number, date, text, custom formula) | P0 | [07](07-data-tools.md) |
| Named ranges, protected sheets & ranges | P0 | [07](07-data-tools.md) |
| Pivot tables | P1 | [07](07-data-tools.md) |
| Slicers | P2 | [07](07-data-tools.md) |
| Remove duplicates, trim whitespace, split text to columns, randomize, column stats, cleanup suggestions | P1 (suggestions P2) | [07](07-data-tools.md) |

### 2.6 Charts and objects
| Feature | Pri | Spec |
|---------|-----|------|
| Charts: column, bar, line, area, pie/donut, scatter, combo; editor panel | P0 basic · P1 rest | [08](08-charts-and-objects.md) |
| Sparklines (`SPARKLINE`) | P1 | [08](08-charts-and-objects.md) |
| Images over cells / in cell | P1 | [08](08-charts-and-objects.md) |
| Drawings | P2 | [08](08-charts-and-objects.md) |

### 2.7 Collaboration, history
| Feature | Pri | Spec |
|---------|-----|------|
| Presence, remote selections, follow mode | P0 | [03](03-grid-and-editing.md) §15, [10](10-collaboration-history.md) |
| Cell/range comments with mentions, assignment | P0 | [10](10-collaboration-history.md) |
| Version history (snapshots, restore, copy) | P1 | [10](10-collaboration-history.md) |
| Cell edit history ("Show edit history") | P1 | [10](10-collaboration-history.md) |
| Notification rules, activity dashboard (suite dashboard UI removed; server kept, suite 07 §6) | P2 | [10](10-collaboration-history.md) |

### 2.8 Import, export, print
| Feature | Pri | Spec |
|---------|-----|------|
| Import CSV/TSV/XLSX (6 import locations) | P0 (ODS P1) | [11](11-import-export-print.md) |
| Download XLSX, CSV, TSV, PDF | P0 · ODS/HTML P1 | [11](11-import-export-print.md) |
| Print preview & print settings | P1 | [11](11-import-export-print.md) |

### 2.9 Scripting, MCP, AI
| Feature | Pri | Spec |
|---------|-----|------|
| Script editor, macros (record/run), triggers | P1 | [09](09-scripting.md) |
| MCP headless `sheets.*` tools, UI bridge `ui.sheets.*` | P0 | [12](12-mcp-and-ai.md) |
| AI assistant panel, formula suggestion, explain formula, fill with AI, analyze | P1 | [12](12-mcp-and-ai.md), suite [10](../10-ai-assistant.md) |

### 2.10 Cross-cutting
| Feature | Pri | Spec |
|---------|-----|------|
| Undo/redo for every mutation (one command = one step) | P0 | suite 08, [02](02-data-model.md) §7 |
| Light/dark/system app theme (cell colors absolute) | P0 | [04](04-screens-menus-toolbar.md) §14 |
| Accessibility: screen reader cell announcements, keyboard-only | P0 | [03](03-grid-and-editing.md) §18 |
| Locale & time zone per spreadsheet; i18n-ready UI | P0 | [06](06-formatting.md) §5.8 |

## 3. Limits

Limits are enforced on the client (pre-flight checks with a clear message, before any write) and
on the server for headless writes (MCP, imports, scripts); the cell and sheet counts are also
checked by the server on every op (`limitExceeded`, suite 17 part 4 §4). Values marked *config* are server
config read at startup and delivered to clients in `ProtocolInfo`.

| Limit | Value | Behavior when exceeded |
|-------|-------|------------------------|
| Cells per spreadsheet (grid size = Σ rows × columns over all sheets, like Google) | 1,000,000, *config* `sheets.maxCellsPerSpreadsheet`; enforced by the server on every op (suite 12 §4); raising it is gated by suite 17 part 7 | Operation refused with dialog "This action would exceed the limit of N cells"; status bar warning at ≥ 80 % |
| Columns per sheet | 18,278 (A … ZZZ) | Insert column disabled at limit |
| Rows per sheet | bounded only by the cell limit | — |
| Sheets per spreadsheet | 200 | *+ Add sheet* disabled |
| Characters per cell (value or input) | 50,000 | Editor stops accepting input; paste/import truncates with a warning toast |
| Formula length | 32,768 characters (A1 form) | Commit rejected with inline error |
| Formula nesting depth | 100 levels | `#ERROR!` "Formula too complex" |
| Array/spill result | ≤ cell limit, and ≤ 5,000,000 values per array | `#ERROR!` "Result too large" |
| Iterative calculation | max iterations 1–1,000 (default 50), threshold ≥ 0 (default 0.05) | Settings dialog validation |
| Conditional formatting rules | 500 per sheet | *Add rule* disabled |
| Data validation rules | 5,000 per sheet (ranges merged where possible) | Refused with message |
| Named ranges / named functions | 5,000 / 1,000 per spreadsheet | Refused with message |
| Merged ranges | 50,000 per sheet | Refused |
| Embedded objects (charts, images, slicers) | 500 per sheet | Refused |
| Sheet name | 1–100 chars, no `[ ] * ? / \ :`, unique (case-insensitive) | Inline validation |
| Zoom | 50 %–200 % | Clamped |
| Row height / column width | 2–2,000 px / 2–5,000 px (at 100 %) | Clamped |
| Font size | 1–400 pt | Clamped |
| Import file size | 100 MB (XLSX/ODS), 200 MB (CSV/TSV) | Refused before upload |
| Clipboard paste | up to the cell limit; > 20,000 cells shows progress; > 500,000 cells asks for confirmation | — |
| Undo stack | 500 steps per spreadsheet (suite 08) | Oldest dropped |
| Op detail (`rev_op.detailJson`) | ≤ 200 cells per op (02 §3.7) | Larger changes have summary only |

## 4. Concurrency semantics (user-facing)

This section is the user-facing explanation of how collaboration works in Wonky Sheets (there is
no in-app help center; it can feed docs or the assistant). Engineers: the mechanics are in
[02-data-model.md](02-data-model.md) §1 and suite [17](../17-revlog-sync.md).

1. **Your edits are saved on this device immediately** and reach others in about a second while
   online. Offline, everything keeps working; changes sync when you reconnect.
2. **Same cell, different people:** the **edit that reaches the server last wins** for the
   cell's value, also for edits made offline; if your offline edits replaced newer edits of
   others, Sheets tells you and offers *Review* (10 §9). Formatting is
   merged **per attribute**: if Anna makes A1 bold while Bo colors it red, A1 ends up bold *and*
   red.
3. **Rows and columns have identity.** If Anna inserts a row above row 5 while Bo (offline)
   edits B7, Bo's edit lands in the same logical row (now row 8). Formulas keep pointing at the
   same cells — references never "shift onto the wrong data".
4. **Deleting wins.** If one person deletes a row or column while someone else edits cells in
   it, the row/column stays deleted (the edit is discarded). Formulas that referenced it show
   `#REF!`. Undo of the deletion (by the person who deleted) restores the row with its cells.
5. **Undo only undoes your own changes.** If someone else changed a cell after you, undoing
   leaves their value and shows *"Some changes couldn't be undone because they were edited by
   someone else."*
6. **Sorting, moving and pasting are applied as a set of row/cell changes**; if two people sort
   the same range offline, the result after merging is the later sort for the rows' order and
   the merged values — it may look unsorted; just sort again.
7. **Sheet names**: two people creating "Sheet2" offline end up with "Sheet2" and "Sheet2 (2)".
8. **Protection is enforced by the server.** Only the people a protection lists can edit its
   cells, also through MCP, scripts or edits made offline; an offline edit into a range protected
   meanwhile is rejected when it syncs, with *Save my changes as a copy* (07 §10.3, 10 §9).
9. **Calculated values are computed on each device.** Two people may briefly see different
   results for volatile functions (`NOW`, `RAND`), exactly as in Google Sheets.
10. While you edit a cell, collaborators see a colored "editing" outline on that cell; the value
    appears for them when you commit.

## 5. Roles in Sheets

| Capability | Viewer | Commenter | Editor | Owner |
|------------|--------|-----------|--------|-------|
| View, select, copy, use temporary filter views, change own zoom/view options | ✓ (copy/download if allowed by owner setting) | ✓ | ✓ | ✓ |
| Comments | see if allowed | ✓ | ✓ | ✓ |
| Edit cells, formats, structure, rules, charts | — | — | ✓ (except protected ranges they're not listed on) | ✓ |
| Protect ranges, edit protection | — | — | ✓ (own protections; owner can edit all) | ✓ |
| Script editor, triggers | — | — | ✓ | ✓ |
| Share / settings | — | — | ✓ (if allowed) | ✓ |

Viewers and commenters open the spreadsheet read-only (the server refuses their ops); the grid runs in
**view mode** (no cell editor, editing commands disabled with tooltip "You have view access").

## 6. Packages and ownership

| Package | Content | Main specs |
|---------|---------|-----------|
| `packages/wonky_sync_models` | Id helpers, fractional index, pure-Dart domain enums | 02 |
| `packages/wonky_revlog`, `packages/wonky_revlog_flutter` | RevLog: schema types, codec, apply rules, overlay, chunker, sync state machine; client cache, transport, per-user client (suite 17) | 02 |
| `packages/wonky_sheets_core` (pure Dart) | `sheetsSchema` (the file tables), addressing, `FormulaCodec`, parser, evaluator, functions, recalculation graph, number formats, input parsing, series detection, clipboard TSV/HTML codecs, XLSX/CSV/ODS mapping | 05, 06, 11, parts of 03 |
| `packages/wonky_sheets_script` | `dart_eval` bridge, Spreadsheet API | 09 |
| `wonky_sheets` (Flutter app) | App: `LoggedWorkbookSession` and `SheetsRevLog` (`features/revlog/`), grid, menus, toolbar, panels, dialogs, script worker | 03, 04, 06–12 |
| `wonky_server` `src/sheets/` | File tables (`models/rows/`), RevLog binding and hooks (`revlog/`), versions, imports, script compile/run, MCP tools | 09–12 |

`wonky_sheets/lib/features/` folders (unit of parallel work): `model/`, `grid/`,
`formula_bar/`, `editing/`, `clipboard/`, `menus/`, `toolbar/`, `tab_bar/`, `status/`,
`formatting/`, `number_format/`, `conditional_format/`, `banding/`, `theme/`, `data_tools/…`,
`charts/`, `pivot/`, `scripts/`, `history/`, `import_export/`, `print/`, `assistant/`,
`explore/`, `dialogs/`, `panels/`. Each spec lists the folders it owns.

## 7. Document map

### 7.1 Sheets specs (`specs/wonky_sheets/`)

| # | File | Content |
|---|------|---------|
| 01 | [01-overview.md](01-overview.md) | This file: scope, features, priorities, limits, concurrency semantics, map. |
| 02 | [02-data-model.md](02-data-model.md) | **Authoritative** file tables, ids, encodings, in-memory model, writes, undo. |
| 03 | [03-grid-and-editing.md](03-grid-and-editing.md) | Grid rendering, headers, frozen panes, scrolling, selection, keyboard, cell/formula editing, fill handle, clipboard, structure ops, in-cell widgets, remote presence, performance, a11y. |
| 04 | [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md) | Screens, complete menubar, toolbar, sheet tabs, context menus, side panels, dialogs, status bar, home screen, light/dark grid colors. **Canonical command-id registry for menus.** |
| 05 | [05-formula-engine.md](05-formula-engine.md) | Grammar, parser, A1⇄stored codec, evaluator, function library, dependency graph, recalculation, spill, errors. |
| 06 | [06-formatting.md](06-formatting.md) | Format attributes & inheritance, number-format language, borders, alignment, rich text, themes, banding, conditional formatting. |
| 07 | [07-data-tools.md](07-data-tools.md) | Sort, filter, filter views, slicers, data validation, pivot tables, named & protected ranges, find/replace, cleanup, groups. |
| 08 | [08-charts-and-objects.md](08-charts-and-objects.md) | Charts, chart editor, sparklines, images, drawings, object layer. |
| 09 | [09-scripting.md](09-scripting.md) | Dart scripting: editor, API, macros, custom functions, triggers, sandbox, quotas. |
| 10 | [10-collaboration-history.md](10-collaboration-history.md) | Presence details, comments on cells, version history, cell edit history, notifications. |
| 11 | [11-import-export-print.md](11-import-export-print.md) | XLSX/ODS/CSV/TSV/HTML/PDF import & export, print. |
| 12 | [12-mcp-and-ai.md](12-mcp-and-ai.md) | `sheets.*` headless MCP tools, `ui.sheets.*`, AI assistant integration. |
| 13 | [13-implementation-plan.md](13-implementation-plan.md) | Milestones, work packages, test strategy, perf gates. |

### 7.2 Suite specs this app depends on (`/specs/`)

| Suite spec | What Sheets takes from it |
|------------|---------------------------|
| [00-product-overview](../00-product-overview.md) | Principles, personas, scope. |
| [01-architecture](../01-architecture.md) | Package layout and dependency rules, server structure. |
| [02-design-system](../02-design-system.md) | `shad`, tokens (`gridLine`, `selectionFill`, `presence1…12`…), `wonky_ui` widgets. |
| [03-app-shell-and-navigation](../03-app-shell-and-navigation.md) | Routes `/s/:uuid…`, editor header, shared menus, overlays, single-window rule. |
| [04-auth-and-accounts](../04-auth-and-accounts.md) | `UserPreferences.sheetsDefaults`, locale/time-zone defaults. |
| [05-drive-and-files](../05-drive-and-files.md) | Home screen, `drive.createSpreadsheet`, templates, thumbnails. |
| [06-sharing-and-permissions](../06-sharing-and-permissions.md) | Roles, protected ranges. |
| [07-collaboration](../07-collaboration.md) | Presence protocol (`PresenceCursor` for Sheets), comments, versions framework. |
| [08-commands-and-undo](../08-commands-and-undo.md) | Command model, keymap scopes (`grid`, `cellEditor`), undo domain `sheets.rows`. |
| [09-mcp](../09-mcp.md) | Tool conventions, UI bridge, `WonkyDialogSpec`. |
| [10-ai-assistant](../10-ai-assistant.md) | Assistant panel, `sheets.ai.*` commands. |
| [12-offline-and-sync](../12-offline-and-sync.md) | Local stores, offline behavior, scale limits. |
| [17-revlog-sync](../17-revlog-sync.md) | RevLog: file tables, op log, protocol, server changes, client cache and outbox, conflicts, performance gates. |

## 8. Glossary (Sheets-specific)

| Term | Meaning |
|------|---------|
| **Spreadsheet** | The file (= one RevLog file with its own op log and head revision). |
| **Sheet** | One tab; kind `grid` or `chart`. |
| **Row/column entity** | `SheetRow`/`SheetColumn` with stable UUID and fractional `sortKey`. |
| **Index** | A row/column's current 0-based position in `AxisIndex` (changes when others move). |
| **A1 / stored form** | Display formula text vs. persisted formula with `⟦…⟧` id tokens. |
| **Grid range** | Rectangular id-based range (`GridRange` JSON). |
| **Active cell** | The cell with the thick border inside the selection; target of typing. |
| **Spill** | Values produced by an array formula into neighbouring cells (computed, not stored). |
| **Overlay** | Computed, read-only cell content not stored as `Cell` rows (spill, pivot output). |
| **Effective format** | Per-attribute resolution cell ▸ row ▸ column ▸ sheet ▸ theme, plus CF and banding. |
| **Commit hint** | Ephemeral presence message about a collaborator's edit (`typing` while editing a cell, `pending` while a large change is being saved). |
