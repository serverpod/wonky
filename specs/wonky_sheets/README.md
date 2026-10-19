# Wonky Sheets — Specifications

Collaborative, offline-first spreadsheet (Google Sheets–like) that syncs through RevLog, a
server-sequenced op log with a local cache and outbox, with a pure-Dart formula engine and Dart
scripting (`dart_eval`). Read the [suite specs](../README.md) first — especially
[12 · Offline & sync](../12-offline-and-sync.md) and [17 · RevLog sync](../17-revlog-sync.md) for
the sync rules and limits.

| # | Spec | Summary |
|---|------|---------|
| 01 | [Overview](01-overview.md) | Purpose, prioritized features, limits, concurrency semantics, document map |
| 02 | [Data model](02-data-model.md) | **Canonical** file schema: stable row/column ids, deterministic cells, id-based formulas, rules, scripts, op log, in-memory model, writes & undo |
| 03 | [Grid & editing](03-grid-and-editing.md) | Custom grid renderer, selection, keyboard, cell/formula editing, fill, clipboard, structure ops |
| 04 | [Screens, menus & toolbar](04-screens-menus-toolbar.md) | Complete menubar (canonical menu command registry), toolbar, tabs, context menus, panels, dialogs |
| 05 | [Formula engine](05-formula-engine.md) | Grammar, codec, evaluation, arrays, dependency graph & recalculation, ~480-function catalog, QUERY |
| 06 | [Formatting](06-formatting.md) | Format inheritance, number-format language, fonts, borders, themes, alternating colors, conditional formatting |
| 07 | [Data tools](07-data-tools.md) | Sort, filters & filter views, slicers, data validation, pivot tables, named ranges/functions, protection, cleanup tools |
| 08 | [Charts & objects](08-charts-and-objects.md) | Pure-Dart chart engine, chart editor, images, object model |
| 09 | [Scripting](09-scripting.md) | Wonky Script API, server compile, sandboxed runtimes, triggers, macros, script editor |
| 10 | [Collaboration & history](10-collaboration-history.md) | Presence, commit hints, comments, version history, cell edit history, offline conflict scenarios |
| 11 | [Import, export & print](11-import-export-print.md) | XLSX/ODS/CSV import & export, PDF/print settings and pagination |
| 12 | [MCP & AI](12-mcp-and-ai.md) | Headless `sheets.*` tools, `ui.sheets.*` bridge, AI features |
| 13 | [Implementation plan](13-implementation-plan.md) | Workstreams WS-S1…S19, contracts, dependency graph, risks |
| — | [Status](STATUS.md) | **Current implementation status** (Sheets is paused; what exists, what's open, how to resume) |

Authority order when specs disagree: suite specs → 02 (data model) → 04 (command ids) → feature
specs. Fix the disagreement in the same change that finds it.
