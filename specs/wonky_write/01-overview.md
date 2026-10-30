# Write 01 · Overview

**Wonky Write** is the collaborative, Markdown-first word processor in the Wonky Work suite. It
looks and feels like Google Docs: a menubar, a formatting toolbar, pages or a pageless canvas,
live collaborators, comments and suggestions, version history. Every document is still a
GitHub-Flavored Markdown (GFM) document. Any formatting a user can apply can be written as GFM,
and **themes** control how the document looks. Users cannot style individual runs of text.

This file is the entry point to the Write specs. It states what Write does, how each feature is
prioritised, and what Write deliberately does not support. It also maps the Write specs to the
suite specs they build on.

## 1. Purpose and positioning

| Question | Answer |
|----------|--------|
| What is it? | A collaborative document editor (Flutter web + desktop) whose canonical content is a Quill Delta that maps 1:1 to GFM ([02-document-model.md](02-document-model.md)). |
| Who is it for? | Writers, teams and agents who want Google-Docs-level collaboration and portable, diff-able, AI-friendly Markdown. See personas in [../00-product-overview.md](../00-product-overview.md) §2. |
| How is it different from Google Docs? | Content is always valid Markdown. Appearance comes only from themes. Every action is a command that can be undone and invoked through MCP. Export to `.md` loses nothing except comments, which are kept separately. |
| How is it different from a Markdown editor? | WYSIWYG (no visible syntax), real-time multi-user editing (OT), comments and suggestions, version history, pages and print layout, and themes for PDF/DOCX/EPUB export. |
| Tech | `super_editor` (**vendored** copy based on 0.3.0-dev.52 with our patches SE-1…SE-5, see [04 §2.2](04-editor.md)) for the editing surface; `dart_quill_delta` 9.x for OT; Serverpod streams for sync; `shad` 1.0.2 + `wonky_ui` for the chrome. |

## 2. Write-specific principles

1. **The Delta is the truth, Markdown is the contract.** The editor shows a Wonky Delta (schema
   v1). An action the schema cannot express does not exist in the UI. This holds even when
   `super_editor` supports the action, for example underline or paragraph indentation.
2. **Themes, not formatting.** Fonts, colors, spacing, heading looks, code colors, page
   decoration, headers and footers come from the document's theme and page setup
   ([06-themes.md](06-themes.md), [07-import-export-print.md](07-import-export-print.md)).
3. **Every action is a command** (`write.<area>.<action>`, see
   [../08-commands-and-undo.md](../08-commands-and-undo.md)). Menus,
   toolbars, shortcuts, slash menu, context menus, MCP and AI all invoke the same commands.
4. **Undo covers only your own edits.** Collaborators' edits are never on your undo stack.
   `super_editor` history is disabled ([03-sync-protocol.md](03-sync-protocol.md) §4).
5. **The app is a single window.** Popovers, panels, dialogs and full-screen in-app routes
   replace new windows ([../03-app-shell-and-navigation.md](../03-app-shell-and-navigation.md) §1).
6. **Light and dark everywhere.** This covers the chrome, the document surface (through theme
   variants), every popover, the print preview canvas and the export previews.

## 3. Feature list

Priorities: **P0** is required for v1 ("complete"). **P1** should ship in v1 and can slip to
v1.1 without blocking release. **P2** is planned later; it is designed for now so the
architecture does not block it.

### 3.1 Documents and files

| Feature | Priority | Spec |
|---------|----------|------|
| Create blank / from template (each template with its own built-in theme) / offline (client UUIDv7) | P0 | suite 05, 12 |
| Inline title editing (`DocumentTitleField`), rename undoable | P0 | 05 |
| Star, move, make a copy, trash, details, make available offline | P0 | suite 05 |
| Document settings: theme, page setup, layout mode, language, front matter (each from its own menu item; no settings dialog) | P0 | 05, 06, 07 |
| Quick switcher (`Mod+O`), back/forward between files | P0 | suite 03 |
| Document properties dialog (front matter editor, stats, created/modified) | P1 | 05 |

### 3.2 Editing core

| Feature | Priority | Spec |
|---------|----------|------|
| Typing, IME composition (CJK, dead keys, emoji keyboard), web + macOS | P0 | 04 §3 |
| IME on Windows/Linux desktop (unverified upstream; requires QA sign-off) | P0 (QA) | 04 §3.4 |
| Selection: mouse, keyboard, shift-click, double/triple-click, drag, select all, block selection | P0 | 04 §4 |
| Caret navigation: char/word/line/paragraph/document, Home/End, PageUp/Down | P0 | 04 §5 |
| Enter/Backspace/Delete semantics per block type | P0 | 04 §6 |
| Markdown autoformat while typing (`# `, `- `, `1. `, `> `, `---`, ```` ``` ````, `[ ] `, `**x**` …), toggleable | P0 | 04 §7 |
| Smart quotes / dashes / ellipsis (setting) | P1 | 04 §8 |
| Auto-pair brackets and quotes (setting) | P1 | 04 §9 |
| Undo/redo of everything, typing coalescing, undo history popover | P0 | 04 §35, suite 08 |
| Clipboard: copy as Markdown + HTML + plain; rich paste → allowed subset; paste without formatting; paste images | P0 | 04 §23 |
| Drag & drop of text within the editor, files and external text into the editor | P1 | 04 §24 |

### 3.3 Formatting (GFM only)

| Feature | Priority |
|---------|----------|
| Bold, italic, strikethrough, inline code; stored typing attributes at caret | P0 |
| Clear formatting | P0 |
| Paragraph styles: Normal text, Heading 1–6, Quote, Code block | P0 |
| Links: insert/edit popover (`Mod+K`), autolink on typing/paste, hover card (Open/Copy/Edit/Remove) | P0 |
| Internal links to other Wonky documents and to headings (`wonky://`) | P0 |
| Theme picker and editor (visual styling) | P0 (see [06-themes.md](06-themes.md)) |

### 3.4 Blocks and insertions

| Feature | Priority |
|---------|----------|
| Bulleted, numbered and checklist lists with 9 levels (indent 0–8), Tab/Shift+Tab, renumbering, click-to-check | P0 |
| Blockquote | P0 |
| Fenced code blocks with language; Tab inserts spaces; exit with `Mod+Enter`/triple Enter | P0 |
| Code syntax highlighting (pure-Dart highlighter, colors from the theme) | P1 |
| Horizontal rule | P0 |
| Images: upload (button / drag-drop / paste), from URL, alt text, replace, download, progress placeholders, offline upload queue | P0 |
| Tables: insert with size picker, table editor (rows/cols add/remove/move, column alignment, inline Markdown in cells), paste Markdown/HTML tables | P0 |
| @mentions (user chip, exported as `[@Name](mailto:…)`) | P0 |
| Emoji picker (Unicode text) | P1 |
| Special characters dialog | P1 |
| Slash command menu (`/`) for all blocks and AI | P0 |
| Block commands: turn into, duplicate, delete, move up/down (`Alt+Shift+↑/↓`), copy link to heading — via shortcuts, context menu, palette and MCP (no block handle or block menu, no drag to reorder) | P0 |
| Insert date (as plain text in the user's locale format) | P2 |
| Table of contents (generated as a static list of heading links, with an "Update" action) | P2 |

### 3.5 Navigation, structure and tools

| Feature | Priority |
|---------|----------|
| Outline panel (headings tree, click to navigate, live) | P0 |
| Go to heading (palette `#` provider and dialog) | P0 |
| Find & replace panel: match case, whole word, regex, replace one/all (one undo step) | P0 |
| Word count dialog and optional live status-bar count (document and selection; off by default) | P0 |
| Spellcheck (pure-Dart Hunspell checker, per-document language) | P1 |
| Document language (BCP-47) for spellcheck, hyphenation and export metadata | P0 (setting) / P1 (use) |
| Zoom 50–200 % | P0 |
| Layout modes: **Pages** (paginated print layout) and **Pageless** | P0 |
| ~~Focus mode~~, ~~typewriter scrolling~~, ~~View Markdown source dialog~~ | Removed |

### 3.6 Collaboration

| Feature | Priority | Spec |
|---------|----------|------|
| Real-time co-editing (OT), offline outbox, reconnect rebase | P0 | [03-sync-protocol.md](03-sync-protocol.md), suite 12 |
| Presence avatars, remote cursors and selections with name flags | P0 | 04 §34, suite 07 |
| Follow a collaborator | P1 | 04 §34.4 |
| Comments: anchored to text, margin cards (the only place they show; open threads only, no filter), @mentions, resolve | P0 | [08-comments-suggestions-history.md](08-comments-suggestions-history.md) |
| Suggesting mode (tracked changes), accept/reject, per-author colors; suggestion cards with replies in the margin | P0 | 08 + 04 §32 |
| Version history: list, compare with highlighted changes, restore, name | P0 | 08, suite 07 |
| View modes: Editing / Suggesting / Viewing; role-driven read-only (`SuperReader`) | P0 | 04 §31, 05 §15 |

### 3.7 Import, export and print

| Feature | Priority |
|---------|----------|
| Import Markdown, TXT, HTML; DOCX best-effort | P0 (MD/TXT/HTML) / P1 (DOCX) |
| Export Markdown (+ zip with images), PDF, HTML, TXT | P0 |
| Export DOCX, ODT, RTF, EPUB | P1 |
| Page setup: size, orientation, margins, header/footer text with page numbers | P0 |
| Print preview (in-app route) + print / save as PDF | P0 |

Details are in [07-import-export-print.md](07-import-export-print.md).

### 3.8 AI and MCP

| Feature | Priority |
|---------|----------|
| Every feature exposed as a command, so it is invocable via `ui.invoke_command` | P0 |
| Headless `write.*` MCP tools (read/edit Markdown, ranges, comments, suggestions) | P0 |
| `ui.write.*` live-session tools (selection, scroll, layout info) | P0 |
| Assistant panel; inline AI (selection ✨ menu, `/ai`, continue writing) | P0 |
| AI edits as suggestions ("Suggest" apply mode) | P1 |

Details are in [09-mcp-and-ai.md](09-mcp-and-ai.md).

### 3.9 Quality attributes

| Attribute | Target |
|-----------|--------|
| Performance | Budgets in [03-sync-protocol.md](03-sync-protocol.md) §7 (keystroke < 16 ms p95 on 100 pages) |
| Accessibility | Screen reader semantics for the editor, keyboard operability of every control, announcements (04 §37) |
| i18n | All strings localised (ARB); RTL text inside documents (04 §38); RTL chrome is P2 |
| Platforms | Web (Chrome, Edge, Firefox, Safari — latest 2), macOS desktop (P0), Windows/Linux desktop (P1) |

## 4. Intentionally not supported

Write supports only what GFM can express. The features below are excluded **on purpose**. The
UI never offers them, and import or paste turns them into the nearest supported construct.
Toasts and import warnings say when this happens.

| Not supported | Why | What happens on paste/import |
|---------------|-----|------------------------------|
| Underline | No GFM syntax | Dropped. `Mod+U` shows a one-time hint "Underline isn't available in Markdown — use *italic* or **bold**" |
| Text color, highlight/background color | Not Markdown | Dropped |
| Font family, font size per run | Not Markdown; themes control fonts | Dropped |
| Superscript / subscript | Not GFM | Content kept as plain text |
| Paragraph alignment (center/right/justify) | Not Markdown | Dropped (left/start-aligned per the theme). Table **column** alignment *is* supported (GFM) |
| Line spacing, paragraph spacing per paragraph | Theme-only | Dropped |
| Indentation of normal paragraphs | Only list items have levels | Dropped (`super_editor` paragraph indent is disabled) |
| Manual page breaks, section breaks, columns | Not Markdown; pagination is computed | Page/section breaks dropped; columns linearised |
| Per-section or odd/even headers & footers | Page setup is global per document | Only document-level header/footer from page setup |
| Footnotes, math/equations, definition lists | Not GFM core / not supported by the editor | Kept as literal text |
| Nested blockquotes, lists inside quotes | Not supported by `super_editor` | Flattened (warning) |
| Ordered list start number ≠ 1 | No start number in `super_editor` lists | Numbering restarts at 1 (warning) |
| Image size, wrapping, positioning, captions | Not Markdown | Images are block-level at natural size (max content width). Alt and title are kept |
| Table cell merges, cell colors, multi-paragraph cells, block content in cells | Not GFM | Merged cells are split; cell content is reduced to inline Markdown |
| Drawings, charts, embeds (video, maps), smart chips other than @mentions | Not Markdown | Dropped; links are kept |
| Bookmarks to arbitrary positions | Not Markdown | Only links to headings (`wonky://doc/<uuid>#<heading-slug>`) |
| Per-run text direction | Not Markdown | Direction is detected per paragraph (first strong character) |
| Raw HTML blocks / inline HTML | Not rendered by Write | Tags stripped; `<br>` becomes a soft break |
| Custom fonts inside documents | Theme-only (curated list) | — |

The full import mapping is in [02-document-model.md](02-document-model.md) §2.1, and the paste
filter in [04-editor.md](04-editor.md) §23.

## 5. Document map (Write specs)

| # | File | Contents | Depends on |
|---|------|----------|------------|
| 01 | `01-overview.md` (this) | Purpose, features, priorities, non-goals, map | — |
| 02 | [02-document-model.md](02-document-model.md) | **Authoritative** Wonky Delta Schema v1, Markdown codec, server models, Delta ⇄ `super_editor` mapping, derived data | suite 01 |
| 03 | [03-sync-protocol.md](03-sync-protocol.md) | **Authoritative** OT protocol, client state machine, `DeltaApplier`, Write undo, permission-restricted ops, performance budgets | 02, suite 07, 08, 12 |
| 04 | [04-editor.md](04-editor.md) | `super_editor` integration and every editing behaviour, command catalog, keyboard map, editor package layout | 02, 03, suite 02, 08 |
| 05 | [05-screens-menus-toolbar.md](05-screens-menus-toolbar.md) | Every screen, menubar, toolbar, context menus, floating toolbar, slash menu, panels, status bar, dialogs, view modes, responsive, light/dark | 04, suite 02, 03, 07 |
| 06 | [06-themes.md](06-themes.md) | Write theme model (`WriteTheme`), built-in themes, theme picker & editor, stylesheet generation, light/dark variants | 02, suite 02 |
| 07 | [07-import-export-print.md](07-import-export-print.md) | Importers, exporters (MD, PDF, HTML, DOCX, ODT, RTF, EPUB, TXT), page setup model, print preview, pagination algorithm for print | 02, 06 |
| 08 | [08-comments-suggestions-history.md](08-comments-suggestions-history.md) | Write comment anchoring (`cmt_*`), suggestion model and accept/reject (`sug_*`), version capture/compare/restore | 02, 03, suite 07 |
| 09 | [09-mcp-and-ai.md](09-mcp-and-ai.md) | Headless `write.*` MCP tools, `ui.write.*` tools, AI assistant tools/prompts for Write | 02–05, suite 09, 10 |
| 10 | [10-implementation-plan.md](10-implementation-plan.md) | Milestones, work packages for parallel engineers/agents, test strategy, definition of done | all |

Reading order for an engineer new to Write: 01 → 02 → 03 → 04 → 05, then whichever of 06–09
their task needs, then 10 for their work package.

### 5.1 Suite specs Write builds on

| Suite spec | What Write takes from it |
|------------|--------------------------|
| [00-product-overview](../00-product-overview.md) | Vision, principles, glossary |
| [01-architecture](../01-architecture.md) | Packages (`wonky_write_core`, `wonky_write`), dependency rules, vendored packages (§2.3), server layout (`src/write/…`) |
| [02-design-system](../02-design-system.md) | `shad` components, `wonky_ui` widgets (`WonkyToolbar`, `WonkyMenubar`, `WonkyDropdownMenu`, `WonkySplitView`, `WonkyTreeView`, `PresenceAvatarStack`, `RemoteCursorOverlay`, `WonkyTableSizePicker`, `StatusBar`, `SyncStatusIndicator`, `DocumentTitleField`), tokens (`canvas`, `page`, `commentHighlight*`, `suggestion*`, `findMatch*`, `presence1…12`) |
| [03-app-shell-and-navigation](../03-app-shell-and-navigation.md) | Single-window rule, routes `/d/:uuid…`, editor header structure, shared File/Edit/View/Tools/Help menus, overlays |
| [04-auth-and-accounts](../04-auth-and-accounts.md) | `UserPreferences.writeDefaults` (spellcheck, smart quotes, auto-pair, Markdown shortcuts, default theme, page setup), Settings › Write |
| [05-drive-and-files](../05-drive-and-files.md) | Home screen, drive operations, templates, activity |
| [06-sharing-and-permissions](../06-sharing-and-permissions.md) | Roles → editor modes; "viewers can copy/print/download" setting |
| [07-collaboration](../07-collaboration.md) | Presence protocol, comments model & UI, mentions, notifications, version framework |
| [08-commands-and-undo](../08-commands-and-undo.md) | `Command`, `CommandDispatcher`, `KeymapService` scopes, `UndoService`, Edit menu contract |
| [09-mcp](../09-mcp.md) | MCP hosting, `ui.*` bridge, `WonkyDialogSpec` |
| [10-ai-assistant](../10-ai-assistant.md) | Assistant panel, inline AI entry points, `write.ai.*` commands |
| [12-offline-and-sync](../12-offline-and-sync.md) | Write local cache tables, outbox, offline creation |

## 6. Write glossary

| Term | Meaning |
|------|---------|
| **Block / node** | One `super_editor` `DocumentNode` (paragraph, heading, list item, task, quote line, code block, image, HR, table). One node equals one Delta line, except that a code block node covers all of its lines. |
| **Embed** | Image, divider or table: a block that is a single Delta insert of a map ([02](02-document-model.md) §1.3). |
| **Attribution** | `super_editor`'s name for inline formatting spans (bold, link, comment anchor…). |
| **Delta offset** | 0-based character index into the document Delta (embeds count 1). Used by sync, cursors, MCP. |
| **DocumentPosition** | `super_editor` position: `(nodeId, NodePosition)`. Converted to and from Delta offsets by `DeltaIndex`. |
| **Layout mode** | *Pages* (paginated) or *Pageless* (continuous). A per-document setting. |
| **View mode** | *Editing*, *Suggesting* or *Viewing*. A per-user, per-session state limited by role. |
| **Typing attributes** | Inline attributions applied to the next typed characters (`composer.preferences.currentAttributions`). |
| **Theme** | A `WriteTheme`: named mapping from Markdown elements to visual styles, with light and dark variants. |
