# 00 · Product Overview — Wonky Work

## 1. Vision

**Wonky Work** is a collaborative office suite built with Flutter and a single Serverpod backend. It contains
four applications (v2: Drive and Slides added). **v2 targets the web only**: the desktop targets
keep compiling, but desktop-only features (native menubar, separate desktop binaries and URL
schemes, desktop packaging, OS windows, OS drag-and-drop in native builds) are deferred
([01 §1 A13](01-architecture.md)).

| App | Purpose | Closest analogue | Core tech |
|-----|---------|------------------|-----------|
| **Wonky Drive** (`wonky_drive`, v2) | The unified drive: all documents, spreadsheets, presentations and uploaded files in one place; previews; storage (50 MB per user) | Google Drive | Shared shell drive (`wonky_app`), Serverpod file uploads, in-app previews |
| **Wonky Write** (`wonky_write`) | Collaborative Markdown-first word processor | Google Docs | `super_editor`, Quill Delta OT over Serverpod streams |
| **Wonky Sheets** (`wonky_sheets`) | Collaborative, offline-first spreadsheet | Google Sheets | RevLog offline-first sync over Serverpod streams ([17](17-revlog-sync.md)), formula engine, Dart scripting (`dart_eval`) |
| **Wonky Slides** (`wonky_slides`, v2) | Collaborative, offline-first presentations with Keynote-class animations, code blocks with type-in, linked (3D) charts from Sheets, PDF export | Keynote / Google Slides / Pitch | RevLog offline-first sync like Sheets, `wonky_slides_core`, shared `wonky_charts` and `wonky_code` |

All apps are served by the same server from one origin (`/drive/`, `/write/`, `/sheets/`,
`/slides/`; `/` opens Wonky Write's home) and share one account system and sign-in session, one file system
(**Wonky Drive** — each app's home shows only its own kind, Drive shows everything), one
storage quota, one sharing model, one design system, one command/undo architecture and one MCP
(Model Context Protocol) surface. Switching apps is a same-tab navigation from the left menu of
every home.

Guiding principles:

1. **Everything is a command.** Every user-visible action (menu item, toolbar button, keyboard
   shortcut, context-menu entry, MCP tool, AI action) goes through a single command registry. This
   gives us undo/redo for everything and full MCP controllability "for free".
2. **Everything is undoable.** Content edits, formatting, structural changes, renames, moves,
   theme edits, sheet settings — if it changes state the user cares about, it can be undone
   (see [08-commands-and-undo.md](08-commands-and-undo.md)).
3. **Single window.** The app never opens new browser tabs or OS windows. Navigation, dialogs,
   side panels and document switching happen inside one window (see
   [03-app-shell-and-navigation.md](03-app-shell-and-navigation.md)); the only exceptions are
   external links (e.g. in documents and help) and Google's sign-in popup (03 §1). Slides presents in
   one window too: the audience view on a second screen runs on another device or browser
   joined to the presentation (Slides 10 §5).
4. **Offline is normal.** Sheets and Slides are offline-first through the sync engine; Write
   queues edits locally and rebases on reconnect; Drive browses from its cache and queues
   uploads (see [12-offline-and-sync.md](12-offline-and-sync.md)).
5. **Markdown is the truth for Write.** No styling that Markdown (GFM) can't express. Visual
   appearance is controlled only through **themes**.
6. **Agents are first-class users.** The MCP server can do anything a human can, with the same
   permissions and the same undo history.
7. **Light and dark.** Every screen, widget, editor theme, chart and export preview works in both.

## 2. Users and personas

| Persona | Needs |
|---------|-------|
| **Writer** | Distraction-free writing, outline, comments, version history, beautiful exports (PDF/DOCX/EPUB). |
| **Presenter** (v2) | Beautiful decks fast: themes and layouts, builds and Magic Move, code walkthroughs, charts that stay linked to the data, presenting with a presenter view, PDF handouts. |
| **Everyone** (v2) | One place for all files incl. PDFs, images and other uploads; knowing how much storage is left and how to free it. |
| **Analyst** | Large sheets, formulas, pivot tables, charts, filters, import/export XLSX/CSV. |
| **Team lead** | Sharing, permissions, comments with @mentions, activity, version restore. |
| **Power user / developer** | Keyboard-driven, command palette, scripting in Dart, MCP access with personal access tokens. |
| **AI agent** | MCP tools for headless document/sheet access, plus live UI control of an open app session. |

## 3. Scope

### In scope (v1 "complete")

- Email/password accounts (Serverpod IDP), profiles, avatars, preferences.
- Wonky Drive: folders, recent, starred, shared-with-me, trash, search, templates, upload/import.
- (v2) Wonky Drive app: all kinds in one place, arbitrary file uploads with previews (images, PDF,
  text/code), *Open with* conversions, 50 MB storage per user with a Storage page
  ([Drive specs](wonky_drive/01-overview.md)).
- (v2) Wonky Slides: decks with themes/layouts/masters, slide groups, builds and transitions
  incl. Magic Move, code blocks with line highlighting and type-in, linked Sheets charts incl.
  3D, presenting with presenter view, PDF export ([Slides specs](wonky_slides/01-overview.md)).
- (v2) Suite: settings split into *Wonky Work settings* and per-app settings, *Report a bug*
  in every app.
- Sharing: per-user roles (Owner, Editor, Commenter, Viewer), link sharing, transfer ownership.
- Real-time collaboration: presence, remote cursors/selections, live edits.
- Comments: threaded, anchored, @mentions, resolve/reopen, notifications.
- Version history: automatic + named versions, browse, compare (Write), restore, copy-from-version.
- Write: all `super_editor`-supported GFM features, theme editor, outline, find/replace, word
  count, page setup, export (Markdown, PDF, HTML, DOCX, ODT, RTF, EPUB, TXT), import (MD, TXT,
  HTML, DOCX best-effort), suggestion mode (tracked changes).
- Sheets: multi-sheet spreadsheets up to ~10M cells, full formula engine (~400 functions),
  formatting, conditional formatting, data validation, sort/filter/filter views, pivot tables,
  charts, named/protected ranges, find/replace, freeze, group, merge, import/export (XLSX, CSV,
  TSV, ODS, PDF), printing, Dart scripting (macros, custom functions, triggers).
- Undo/redo for everything.
- MCP: server-side headless tools + in-app UI bridge.
- AI assistant panel in every app (OpenAI/Anthropic/Gemini, server-side; Drive P1).
- Light/dark/system theme, keyboard shortcuts, command palette, accessibility, i18n-ready.

### Non-goals (v1)

- Mobile phone layouts (the app must not break on narrow widths, but mobile UX is not designed).
- (v2) Desktop-specific features: v2 ships on the web only. Desktop builds must keep compiling
  (the macOS integration-test job `e2e.yml` keeps building them), but native menubar, desktop binaries/URL schemes/packaging, multi-window
  and native drag-and-drop are deferred to a later iteration ([01 §1 A13](01-architecture.md)).
- Forms app. (v2: the presentation app is in scope as Wonky Slides — without PPTX/Keynote/Google
  Slides import or export, and without video.)
- Third-party sign-in providers (Google/Apple/etc.) — email + password only for now; the auth
  layer must not preclude adding them.
- Arbitrary text styling in Write (fonts, colors, sizes per run) — only themes.
- Public internet publishing/hosting of documents (beyond "anyone with the link").
- Real-time co-editing of scripts (script files use last-write-wins with conflict warning).

**Decided (v2 review, Q1):** the suite is named **Wonky Work** everywhere — product icon label,
sign-in headline, legal pages, page titles, `WonkyProduct.work`, wonky.work — and the suite
settings are **Wonky Work settings** (D4).

## 4. Glossary

| Term | Meaning |
|------|---------|
| **Drive item** | A folder, document (Write), spreadsheet (Sheets), presentation (Slides) or uploaded file in Wonky Drive. |
| **File** (v2) | An uploaded drive item of any type (`DriveItemKind.file`): stored as-is, previewed in Drive. |
| **Presentation / deck** (v2) | A Wonky Slides file ([Slides 02](wonky_slides/02-data-model.md)). |
| **App home** (v2) | An app's documents view (`/write/`, `/sheets/`, `/slides/`): the drive filtered to the app's kind, with the left menu. |
| **Storage quota** (v2) | 50 MB per user, counted for item owners ([Drive 03](wonky_drive/03-storage-quota.md)). |
| **Document** | A Wonky Write file. Content is a Quill Delta whose attributes map 1:1 to GFM. |
| **Spreadsheet** | A Wonky Sheets file. Contains one or more **sheets** (tabs). |
| **RevLog** | The sync of Sheets and Slides: each spreadsheet or deck is one file with a server-sequenced op log; clients keep a local cache and an outbox of their own changes ([17](17-revlog-sync.md)). |
| **Command** | A named, typed, invocable action (`write.format.bold`, `sheets.rows.insertAbove`). |
| **Undo transaction** | A group of state changes that undo/redo as one step. |
| **Revision** | Monotonic version number of a Write document's operation log, or of a spreadsheet's or deck's RevLog op log. |
| **Presence** | Ephemeral real-time info about who is viewing/editing and where. |
| **MCP** | Model Context Protocol — the tool interface for AI agents. |
| **UI bridge** | The channel through which MCP tools drive a live, open app session. |
| **Theme (Write)** | A named style sheet mapping Markdown elements to visual styles. |
| **App theme** | Light/dark/system appearance of the app chrome (not to be confused with Write themes). |

## 5. Document map

Suite-level specs live in `/specs`. App specs live in [`/specs/wonky_drive`](wonky_drive/README.md),
[`/specs/wonky_write`](wonky_write/README.md), [`/specs/wonky_sheets`](wonky_sheets/README.md) and
[`/specs/wonky_slides`](wonky_slides/01-overview.md). See [README.md](README.md) for the full
index and reading order.
