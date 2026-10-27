# Wonky Write — Specifications

Collaborative, Markdown-first word processor (Google Docs–like) built on `super_editor`, with
real-time sync via Quill Delta OT over typed Serverpod streams. Read the
[suite specs](../README.md) first (architecture, commands & undo, offline & sync).

| # | Spec | Summary |
|---|------|---------|
| 01 | [Overview](01-overview.md) | Purpose, prioritized feature list, what's intentionally unsupported, document map |
| 02 | [Document model](02-document-model.md) | **Canonical** Wonky Delta Schema v1, Markdown codec, server models, Delta ⇄ super_editor mapping |
| 03 | [Sync protocol](03-sync-protocol.md) | Server-authoritative OT, stream messages, client state machine, collaborative undo, permission-restricted ops |
| 04 | [Editor](04-editor.md) | super_editor integration and every editing feature (typing, selection, formatting, lists, code, images, tables, mentions, slash menu, clipboard, find/replace, spellcheck, …) |
| 05 | [Screens, menus & toolbar](05-screens-menus-toolbar.md) | Editor screen, complete menubar, toolbar, context menus, panels, dialogs, status bar, view modes, Pages/Pageless |
| 06 | [Themes](06-themes.md) | Theme JSON schema, presets, fonts, dark variants, super_editor & exporter mapping, theme editor |
| 07 | [Import, export & print](07-import-export-print.md) | MD/TXT/HTML/DOCX import; MD/PDF/HTML/DOCX/ODT/RTF/EPUB/TXT export; page setup; pagination; print preview |
| 08 | [Comments, suggestions & history](08-comments-suggestions-history.md) | Comment anchors, suggesting mode, accept/reject, version history & diffs, presence specifics |
| 09 | [MCP & AI](09-mcp-and-ai.md) | Headless `write.*` tools, `ui.write.*` bridge tools, resources, AI assistant and inline AI |
| 10 | [Implementation plan](10-implementation-plan.md) | Workstreams WS-W*, contracts, dependency graph, spikes, definition of done |
| 11 | [Wonky Markdown](11-wonky-markdown.md) | The second Markdown flavor: Serverpod blog directives (callouts, details, cards, grids, buttons, arrow links, chips, numbered headings), the flavor setting, schema, codec, editing, themes and exports |

Authority order when specs disagree: suite specs for cross-cutting rules → 02/03 for content
and sync semantics → feature specs. Fix the disagreement in the same change that finds it.
