# Slides 01 · Overview

**Wonky Slides** is the presentation app of the Wonky Work suite: a collaborative,
**offline-first** slide editor and presenter for the web (v2 is web only; the desktop target
compiles but desktop features are deferred, suite 01 A13), built with Flutter + `shad` on
the shared shell (`packages/wonky_app`) and the single Serverpod server. It syncs through RevLog
like Wonky Sheets ([17](../17-revlog-sync.md): one deck = one file with a server-sequenced op log
and an offline outbox; data design shared with Sheets, decision D6).

**Vision — the best of the popular presentation apps, in one coherent tool:**

| From | We take |
|------|---------|
| **Keynote** | Typography and theme quality, *Magic Move*, cinematic builds and transitions, the inspector, presenter view, rehearse timing |
| **PowerPoint** | Masters and layouts with real placeholders, animation pane with triggers/delays, Morph, selection (layers) pane, format painter, align/distribute, PDF handouts |
| **Google Slides** | Real-time collaboration, comments, version history, link-shared decks, "linked charts from Sheets" with *Update*, explore-free simplicity of the menus |
| **Pitch** | Slide groups (sections) that move, copy and collapse together; beautiful modern templates; per-slide presence |
| **Figma Slides** | Smart guides, snapping, multiplayer cursors, grid view, design-tool canvas feel, AI-assisted design |
| **reveal.js / Slides.com** | Code blocks with syntax highlighting, **line-highlight steps** (`1-3 \| 5`), **type-in code animation**, auto-animate of code between slides, keyboard-first presenting |

And the Wonky principles (suite [00](../00-product-overview.md)): every action is a **command**
`slides.<area>.<action>` and every change is **undoable**; **single window**, also when
presenting (presenter view in this window, the audience on another device or browser,
[10-presenting-and-pdf.md](10-presenting-and-pdf.md) §5.2);
UI built with **shad + wonky_ui**; **light and dark**; **keyboard-first**; **offline is normal**;
**agents are first-class** (MCP + AI).

Read this file first, then [02-data-model.md](02-data-model.md) (authoritative storage model),
then the spec for the area you build.

---

## 1. Personas and core jobs

| Persona | Core jobs in Slides |
|---------|---------------------|
| **Speaker / founder** | Turn an outline into a good-looking deck fast (themes, layouts, AI); rehearse; present with notes and a presenter view; export a PDF to send. |
| **Developer advocate / engineer** | Code walkthroughs: highlighted code, step-by-step line highlights, type-in changes, Magic Move between code versions; diagrams with shapes and connectors; keyboard-only editing. |
| **Analyst / team lead** | Weekly business reviews with **linked charts from Wonky Sheets** that update with one click; reuse slide groups across decks; comments and approvals. |
| **Designer / brand owner** | Masters, layouts and themes that keep a team on brand; precise layout tools (guides, snapping, distribute, Layers panel). |
| **Team** | Several people building one deck at once: presence, soft locks on text, comments with mentions, version history, offline work on a plane. |
| **AI agent** | Headless `slides.*` MCP tools (create decks, slides, elements, builds, export PDF) and live `ui.slides.*` control of an open window ([11-mcp-and-ai.md](11-mcp-and-ai.md)). |

---

## 2. Feature list by area

Priority: **P0** = required for the Slides release of its milestone ([12](12-implementation-plan.md)
§1: M9 MVP, M10 motion & content, M11 collaboration/MCP/AI); **P1** = required for "complete" v1;
**P2** = later.

### 2.1 Decks, slides, groups
| Feature | Pri | Spec |
|---------|-----|------|
| Create/open/rename deck (unified Drive, offline creation with client UUIDs) | P0 | [02 §9.3](02-data-model.md), suite 05 |
| Slide navigator: thumbnails, select, multi-select, drag reorder, new/duplicate/delete, skip | P0 | [04 §5](04-screens-menus-toolbar.md) |
| **Slide groups**: create (Mod+G), rename, color, collapse/expand (per user), drag group, duplicate, delete, skip, ungroup | P0 | [04 §5](04-screens-menus-toolbar.md), [02 §3.4](02-data-model.md) |
| Copy/paste slides **and groups** within and across decks (with elements, builds, code states, linked charts, images) | P0 (across decks P0) | [03 §12](03-editor-canvas-and-objects.md) |
| Nested groups | P2 | [04 §5.12](04-screens-menus-toolbar.md) |
| Grid view (light table) with groups as sections | P1 | [04 §9](04-screens-menus-toolbar.md) |
| Outline view (edit titles and bullets of all slides as text) | P1 | [04 §10](04-screens-menus-toolbar.md) |
| Import slides from another Wonky deck | P1 | [04 §13.9](04-screens-menus-toolbar.md) |
| Slide sizes 16:9, 4:3, 16:10, 1:1, A4, Letter, custom; 9:16 | P0 · 9:16 P1 | [05 §7](05-themes-layouts-masters.md) |
| Speaker notes (rich text) | P0 | [04 §8](04-screens-menus-toolbar.md) |
| Slide numbers, footer text | P1 | [05 §5.5](05-themes-layouts-masters.md) |

### 2.2 Canvas and objects
| Feature | Pri | Spec |
|---------|-----|------|
| Canvas: zoom/fit, scroll, pan (Space-drag), pixel-precise selection | P0 | [03 §2](03-editor-canvas-and-objects.md) |
| Selection: click, Shift/Mod-click, marquee, select inside groups, Tab cycling | P0 | [03 §3](03-editor-canvas-and-objects.md) |
| Move/resize/rotate/flip with handles, nudge, numeric frame in inspector | P0 | [03 §4](03-editor-canvas-and-objects.md) |
| **Smart guides**, snapping (objects, slide edges/centers, guides), equal-spacing hints | P0 | [03 §5](03-editor-canvas-and-objects.md) |
| Align / distribute / center on slide | P0 | [03 §5.5](03-editor-canvas-and-objects.md) |
| Rulers and user guides | P1 | [03 §5.6](03-editor-canvas-and-objects.md) |
| Text boxes with rich formatting, lists, auto-fit, links | P0 | [03 §6.1](03-editor-canvas-and-objects.md) |
| Shapes library (~60 shapes) with text, adjust handles | P0 (library P0 core 20, rest P1) | [03 §6.3](03-editor-canvas-and-objects.md) |
| Lines, arrows, **connectors** (straight/elbow/curved, glued to shapes) | P0 · curved P1 | [03 §6.4](03-editor-canvas-and-objects.md) |
| Images: upload/Drive/URL/paste/drop, crop, mask to shape, replace, adjustments | P0 · adjustments P1 | [03 §6.5](03-editor-canvas-and-objects.md) |
| Tables (merge, header row, banding, cell styles) | P0 · merges P1 | [03 §6.6](03-editor-canvas-and-objects.md) |
| Icons (Lucide set) and emoji as objects | P0 · emoji P1 | [03 §6.7](03-editor-canvas-and-objects.md) |
| Element groups, lock, hide, z-order, Layers panel | P0 · Layers P1 | [03 §7–8](03-editor-canvas-and-objects.md) |
| Format painter; copy/paste style | P0 | [03 §9](03-editor-canvas-and-objects.md) |
| Fills (solid, gradient, image), strokes, shadows; glow/blur | P0 · glow/blur P1 | [02 §5](02-data-model.md) |
| Find & replace (text, notes; whole deck) | P0 | [03 §13](03-editor-canvas-and-objects.md) |
| Spell check (Write's checker) | P1 | [03 §14](03-editor-canvas-and-objects.md) |
| Clipboard from Write (text, lists, tables, images, code), Sheets (cells → table, charts → linked chart), OS (text, images, HTML) | P0 · HTML P1 | [03 §12](03-editor-canvas-and-objects.md) |

### 2.3 Themes, layouts, masters
| Feature | Pri | Spec |
|---------|-----|------|
| ~10 built-in themes, each with light and dark appearance | P0 | [05 §6](05-themes-layouts-masters.md) |
| Theme colors and fonts (bundled families), backgrounds, code palette light/dark | P0 | [05 §2](05-themes-layouts-masters.md) |
| 16 built-in layouts with placeholders; apply/reset layout | P0 | [05 §4](05-themes-layouts-masters.md) |
| Edit masters and layouts | P1 | [05 §8](05-themes-layouts-masters.md) |
| Import/apply theme from another deck | P1 | [05 §9](05-themes-layouts-masters.md) |
| Templates gallery (presentations as templates) | P0 | [04 §15](04-screens-menus-toolbar.md) |

### 2.4 Motion
| Feature | Pri | Spec |
|---------|-----|------|
| Builds in/out/emphasis/motion path with triggers, delay, duration, easing; animation pane | P0 (M10) · motion paths P1 | [06](06-animations-and-transitions.md) |
| Text builds by paragraph/word/character | P0 (M10) | 06 |
| Transitions (fade, push, wipe, zoom, flip, cube, …) | P0 (M10) | 06 |
| **Magic Move** between consecutive slides (`matchKey`) incl. text, shapes, code tokens, chart camera | P0 (M10) | 06 |
| Reduced-motion fallbacks | P0 | 06 |

### 2.5 Code and charts
| Feature | Pri | Spec |
|---------|-----|------|
| Code blocks with syntax highlighting (Write's languages), line numbers, title tab, auto-fit | P0 (M10) | [07](07-code-blocks.md) |
| Line-highlight steps (`1-3 \| 5`) as builds; annotations | P0 (M10) · annotations P1 | 07 |
| **Type-in** code states and **morph** between states | P0 (M10) | 07 |
| Linked charts from Sheets with Update / auto-update / unlink; deck-themed styling | P0 (M10) | [08](08-charts-from-sheets.md) |
| **3D charts** with animatable camera | P0 (M10) | 08 |
| Native charts from a small data table | P1 | 08 |

### 2.6 Presenting and export
| Feature | Pri | Spec |
|---------|-----|------|
| Present full screen (same tab), keyboard/clicker, slide picker with groups, black/white screen | P0 | [10](10-presenting-and-pdf.md) |
| Presenter view in this window, timers, notes; audience view on another device or browser via the presentation session | P0 (decided, v2 review Q29: no second window) | 10 |
| Laser pointer, pen/highlighter (ephemeral) | P1 | 10 |
| Rehearse timings | P1 | 10 |
| Phone as remote | P1 | 10 |
| **PDF export**: slides, builds as pages, notes pages, handouts, skipped in/out, groups as bookmarks | P0 · handouts P1 | 10 |
| PNG export of a slide | P1 | 10 |

### 2.7 Collaboration, history
| Feature | Pri | Spec |
|---------|-----|------|
| Presence: avatars, per-slide avatars in the navigator, selection outlines, soft text locks | P0 (soft locks M9, rest M11) | [09 §1–2](09-collaboration-history.md) |
| Live pointer cursors on the canvas, follow mode, follow the presenter | P1 | 09 §1 |
| Comments on slides and elements (shell comments) | P0 (M11) | 09 §3 |
| Version history: snapshots, per-slide diff view, restore, copy | P0 (M11) | 09 §4 |
| Offline editing with conflict recovery (overwritten text) | P0 · recovery P1 | 09 §6 |

### 2.8 MCP and AI
| Feature | Pri | Spec |
|---------|-----|------|
| Headless `slides.*` tools; `ui.slides.*` bridge tools | P0 (M11) | [11](11-mcp-and-ai.md) |
| AI: generate deck from prompt/outline/Write doc, rewrite text, layout suggestions, speaker notes, alt text, "make it a code walkthrough" | P1 (M11) | 11 |

### 2.9 Cross-cutting
| Feature | Pri | Spec |
|---------|-----|------|
| Undo/redo for every mutation (one command = one step) | P0 | suite 08, [02 §12](02-data-model.md) |
| Light/dark app chrome; slides render as designed (deck appearance) | P0 | [04 §16](04-screens-menus-toolbar.md), [05 §2.4](05-themes-layouts-masters.md) |
| Accessibility: alt text, reading order, keyboard-only editing, accessibility checker | P0 · checker P1 | [03 §17](03-editor-canvas-and-objects.md) |
| Storage quota (images, deck content count toward 50 MB) | P0 | D3, suite specs |
| Report a bug, settings split (Slides settings vs Wonky Work settings) | P0 | suite 03/04 (D4, D5) |

---

## 3. Non-goals

- **No interop with other presentation programs**: no PPTX/Keynote/Google Slides/ODP import or
  export. (Paste of plain text, images and HTML from other apps is supported.) Export is **PDF**
  (and PNG of a slide).
- **No video and no audio**: no video/audio elements, no recording of narration, no soundtracks.
  (A single optional, default-off keyboard click sound for type-in is the only sound, 07.)
- No web publishing beyond suite link sharing (no "publish to web" embed).
- No 3D objects other than 3D charts; no freeform drawing tools for content (pen/highlighter are
  ephemeral presenting aids, 10). Freeform polyline shapes are P2.
- No live data embeds other than linked Sheets charts; no live web pages.
- No mobile phone editing layout (the app must not break at 360 px; phone-as-remote is a P1
  presenting feature).
- No real-time character-level co-editing of one text box in v1 (soft lock + LWW, 02 §4.4).

---

## 4. Limits

The authoritative list is [02 §13](02-data-model.md). Summary:

| Limit | Value |
|-------|-------|
| Slides per deck | 1,000 (*config*) |
| Groups per deck / nesting | 200 / 1 level (2 with P2) |
| Objects per slide | 500 |
| Text per text body / notes per slide | 20,000 / 50,000 characters |
| Table | 50 × 20 |
| Builds per slide | 200 |
| Code: lines per state / states | 1,000 / 50 |
| Image | ≤ 25 MB and ≤ remaining quota; > 40 MP downscaled |
| Storage | 50 MB per user, shared across the suite (D3) |
| Zoom | 10 – 400 % |
| Undo | 500 steps per deck |

---

## 5. Concurrency semantics (user-facing)

How collaboration works in Wonky Slides (feeds help texts and the assistant; mechanics in
[02](02-data-model.md) and [09](09-collaboration-history.md)):

1. **Your edits are saved on this device immediately** and reach collaborators in well under a
   second; typing in a text box shows up live. Offline, everything keeps working and syncs when
   you reconnect.
2. **Different objects, no conflicts.** Anna editing slide 3 while Bo edits slide 7 — or two
   different shapes on the same slide — never interfere.
3. **Same object, different properties merge.** If Anna moves a shape while Bo changes its color,
   it ends up moved *and* recolored.
4. **Same property: the last change wins.** Two people moving the same shape at once: the move
   that reaches the server last wins (for offline edits: the one synced last).
5. **Text boxes are claimed while someone types.** When Anna is editing a text box, others see
   "Anna is editing" and the text is read-only for them (they can still *Edit anyway*). If two
   people edit the same text at the same time anyway (or offline), the version that reaches the
   server last wins and the other person is offered their overwritten text back.
6. **Slides and groups keep their identity.** Moving, duplicating or regrouping slides by
   different people merges: each slide ends where its last move put it. If someone deletes a
   group while you add a slide to it, your slide moves to the end of the deck instead of
   disappearing.
7. **Deleting wins.** If one person deletes a slide (or object) while another edits it, it stays
   deleted. Undo of the deletion (by the person who deleted) restores it with everything on it.
8. **Undo only undoes your own changes.** If someone else changed the same thing after you,
   undoing leaves their change and says *"Some changes couldn't be undone because they were
   edited by someone else."*
9. **Themes are shared by the deck.** Changing a theme, master or layout updates every slide using
   it for everyone.
10. **Linked charts** show the data from their last update; anyone with edit access can press
    *Update* to pull the latest from the spreadsheet (or turn on *Update automatically*).
11. **Collapsed groups are yours.** Collapsing a group in the slide list only affects your view.

---

## 6. Roles in Slides

| Capability | Viewer | Commenter | Editor | Owner |
|------------|--------|-----------|--------|-------|
| View deck, navigate, present, presenter view, grid/outline views (read-only), zoom | ✓ | ✓ | ✓ | ✓ |
| Copy slides/objects, download PDF/PNG, print | if the owner allows download/copy (suite 06) | same | ✓ | ✓ |
| See comments | if allowed | ✓ | ✓ | ✓ |
| Comment on slides/elements | — | ✓ | ✓ | ✓ |
| Edit slides, objects, notes, groups, builds, themes/masters, update linked charts | — | — | ✓ | ✓ |
| Version history (view, name, restore) | — | — | ✓ | ✓ |
| Share, move, rename | — | — | ✓ (if allowed) | ✓ |

Viewers and commenters open the deck read-only (the server accepts ops from Editor+ only); the
editor runs in **view mode**:
no canvas editing, mutating commands disabled with "You have view access" / "You have comment
access", and a *Present* button as the primary action. Collapsing groups and every per-user view
state work for all roles. Linked charts render from the snapshot for users without access to the
spreadsheet.

---

## 7. Packages and ownership

| Package / folder | Content | Main specs |
|------------------|---------|-----------|
| `wonky_server/lib/src/slides/models/rows/` | The 12 deck tables and their 7 enums (server tables of the deck's RevLog file; enums shared with the client) | 02 |
| `packages/wonky_sync_models` (`lib/src/ids/slides_ids.dart`) | `SlidesIds` (deterministic ids), `FractionalIndex` | 02 |
| `packages/wonky_slides_core` (pure Dart, **new**) | `DeckModel`, records, indexes, `SlidesMutationPlanner`, text schema + validator + style resolution, theme resolution + built-in themes/layouts, `SlideSceneBuilder`, layout/auto-fit (`TextLayoutEngine` interface), connectors routing, animation **timeline model** (06), code diff/type-in model (07, on `wonky_core/diff.dart`), chart link data (08, on `wonky_charts`), **PDF renderer** (10), snapshot codec + diff (09), `DeckCopier`, clipboard payload codec, headless deck for MCP (11), outline extraction | 02, 03, 05–11 |
| `packages/wonky_charts`, `packages/wonky_charts_flutter` (**new**, extracted from Sheets, D7) | Chart engine + 3D scene + renderers | 08, suite 01 |
| `packages/wonky_code`, `packages/wonky_code_flutter` (**new**, extracted from Write, D7, v2 review Q3) | Pure: tokenizer (TextMate + highlight.js), language list, palettes, code layout/type-in · Flutter: `CodeView`, `CodeEditorField` | 07, suite 01 |
| `packages/wonky_numfmt`, `wonky_rich_text`, `wonky_fonts`, `wonky_spellcheck` (**new**, v2 review Q4/Q23/Q27) | Number formats (from Sheets) · Delta inline schema + codec (from Write) · font registry + TTFs · Hunspell engine (from Write) | 08, 02, 05, 03 |
| `packages/wonky_revlog` + `wonky_revlog_flutter` (shared with Sheets, [17](../17-revlog-sync.md)) | Pure: `RowChange`/`MutationPlan`/`UndoInverter`, `RevSchema`, codec, apply rules, overlay, client state machine · Flutter: local cache and outbox, transport, per-file connection, `RevLogClient` | 02, 17 |
| `wonky_slides` (Flutter app, **new**) | Editor, canvas, navigator, inspector, notes, grid/outline views, themes/master editing UI, builds UI, code/chart UI, presenting, print/PDF preview, history, collab, MCP UI tools, AI UI | 03–11 |
| `wonky_server` `lib/src/slides/` (**new**) | Deck tables, RevLog binding and hooks (`revlog/`), `slidesDoc` endpoint, deck creation and copies, versions, chart-link status, exports (PDF), templates, headless + `slides.*` MCP tools, AI | 08–12 |

`wonky_slides/lib/features/` folders (unit of parallel work): `revlog/`, `model/`, `editor_screen/`,
`canvas/`, `selection/`, `snapping/`, `elements/{text,shape,line,image,table,icon,code,chart,group}/`,
`text_editing/`, `navigator/`, `groups/`, `inspector/`, `notes/`, `grid_view/`, `outline_view/`,
`themes/`, `masters/`, `layers/`, `stage/` (shared slide renderer, 06 §12.1), `motion/` (player, 06),
`builds/`, `transitions/`, `present/`, `print/`, `clipboard/`,
`find/`, `spellcheck/`, `collab/`, `comments/`, `history/`, `menus/`, `toolbar/`, `dialogs/`,
`home/`, `assistant/`, `ai/`, `accessibility/`. Each spec lists the folders it owns.

Dependency rules (authoritative list: suite 01 §2.1): `wonky_slides_core` → `wonky_core`,
`wonky_revlog` (and `wonky_sync_kit`, which only re-exports its rows until the kit is deleted),
`wonky_sync_models` (ids only), `wonky_charts`, `wonky_numfmt`, `wonky_code`,
`wonky_rich_text`, `wonky_fonts`, `pdf`, `image`, `vector_math`, `crypto`;
`wonky_slides` → `wonky_app`, `wonky_ui`, `wonky_slides_core`, `wonky_revlog`,
`wonky_revlog_flutter`, `wonky_charts_flutter`, `wonky_code_flutter`, vendored `super_editor`,
`super_clipboard`, `printing`, `file_saver`, `file_picker`, `flutter_scene`, `wonky_sync_models`
(ids only). **Slides packages never
import Write or Sheets app/core packages** (and vice versa); shared code moves to shared packages.

---

## 8. Document map

### 8.1 Slides specs (`specs/wonky_slides/`)

| # | File | Content |
|---|------|---------|
| 01 | [01-overview.md](01-overview.md) | This file: vision, personas, features, priorities, non-goals, limits, concurrency semantics, roles, packages, glossary. |
| 02 | [02-data-model.md](02-data-model.md) | **Authoritative** deck tables, ids, text schema, style JSON, in-memory model, planner, writer, undo, invariants, limits. |
| 03 | [03-editor-canvas-and-objects.md](03-editor-canvas-and-objects.md) | Canvas, selection, transforms, snapping, every element kind, format painter, keyboard, clipboard, find/replace, spelling, accessibility, performance. |
| 04 | [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md) | Screens, editor layout, **slide navigator and groups**, inspector, notes, grid/outline views, complete menubar, toolbar, context menus, panels, dialogs, status bar. **Canonical command-id registry for menus.** |
| 05 | [05-themes-layouts-masters.md](05-themes-layouts-masters.md) | Theme model, built-in themes, layouts, masters & placeholders, master editing, importing themes, slide sizes. |
| 06 | [06-animations-and-transitions.md](06-animations-and-transitions.md) | Builds, effect catalog, animation pane, transitions, Magic Move, timeline model, reduced motion. |
| 07 | [07-code-blocks.md](07-code-blocks.md) | Code elements, highlighting, line-highlight steps, code states, type-in and morph. |
| 08 | [08-charts-from-sheets.md](08-charts-from-sheets.md) | Linked Sheets charts, update detection, 3D charts and camera, native charts. |
| 09 | [09-collaboration-history.md](09-collaboration-history.md) | Presence, soft locks, follow mode, comments, version history, activity, offline conflicts. |
| 10 | [10-presenting-and-pdf.md](10-presenting-and-pdf.md) | Present mode, presenter view, remote, rehearse, PDF/PNG export, print. |
| 11 | [11-mcp-and-ai.md](11-mcp-and-ai.md) | `slides.*` headless tools, `ui.slides.*`, AI features. |
| 12 | [12-implementation-plan.md](12-implementation-plan.md) | Workstreams, contracts, milestones M9–M11, testing, risks, definition of done. |

### 8.2 Suite specs this app depends on

| Suite spec | What Slides takes from it |
|------------|---------------------------|
| [00 · Product overview](../00-product-overview.md) | Principles, personas (Slides added by the suite update). |
| [01 · Architecture](../01-architecture.md) | Package rules, serving `/slides/`, shared sign-in, dev port 8104 (D1). |
| [02 · Design system](../02-design-system.md) | `shad`, tokens, `wonky_ui` widgets (`WonkyToolbar`, `WonkyColorPicker`, `FontPicker`, `WonkySplitView`, `WonkyTreeView`, …), product icon `WonkyProduct.slides`. |
| [03 · App shell](../03-app-shell-and-navigation.md) | Routes, editor header, shared menus, single-window rule (no presenting exception in v2). |
| [04 · Auth & accounts](../04-auth-and-accounts.md) | Settings split (Slides settings vs Wonky Work settings, D4), `UserPreferences.slidesDefaults`. |
| [05 · Drive](../05-drive-and-files.md) and `specs/wonky_drive/` | Unified Drive, `presentation` kind, app home filtered to presentations, quota, templates, thumbnails. |
| [06 · Sharing](../06-sharing-and-permissions.md) | Roles (the drive ACL, checked on every op). |
| [07 · Collaboration](../07-collaboration.md) | Presence protocol, comments, versions framework. |
| [08 · Commands & undo](../08-commands-and-undo.md) | Command model, keymap scopes, undo domains `slides.rows`, `slides.serverChange`. |
| [09 · MCP](../09-mcp.md), [10 · AI](../10-ai-assistant.md) | Tool conventions, UI bridge, assistant panel. |
| [12 · Offline & sync](../12-offline-and-sync.md) | Local stores, web storage (OPFS), the drive op queue. |
| [17 · RevLog sync](../17-revlog-sync.md) | Files, ops and revisions, outbox, opening, conflicts and outcomes, server changes, headless models (Slides binding: part 6 §1.2, §7.2). |

---

## 9. Glossary (Slides-specific)

| Term | Meaning |
|------|---------|
| **Deck** | A presentation file (= one RevLog file). |
| **Slide** | One page of a deck, built from a **layout**; has elements, notes, builds and a transition. |
| **Slide group** | A named, colored section of consecutive slides in the navigator; moves/copies/skips as a unit; collapse state is per user. |
| **Top level** | The ordered list of groups and ungrouped slides (02 §3.4). |
| **Element** | Any object on a slide, layout or master: text, shape, line, image, table, icon, code, chart, group (`SlideElement`). |
| **Element group** | An element of kind `group` holding child elements (not to be confused with a slide group). |
| **Theme** | Colors (light and dark appearance), fonts, text styles, backgrounds and default object styles, copied into a deck (`DeckTheme`). |
| **Appearance** | Whether a deck uses its themes' light or dark color scheme (`Deck.appearance`); independent of the app theme. |
| **Master** | The base slide design of a theme (background, decorations, placeholder styles). |
| **Layout** | A slide template under a master with placeholders (Title and content, Two columns, …). |
| **Placeholder** | A layout element slides instantiate; instance fields left null inherit from it. |
| **Slide units (su)** | Deck coordinate unit; 16:9 decks are 1920 × 1080 su. |
| **Build** | One animation step on a slide (build in/out, emphasis, motion, action). |
| **Transition** | The effect between two slides. |
| **Magic Move** | A transition that morphs elements with equal `matchKey` from one slide to the next. |
| **Match key** | Identity of an element across slides for Magic Move (`matchKey`, generated on create; kept when slides are duplicated or elements pasted onto another slide, 06 §8.2). |
| **Code state** | One version of a code element's source; advancing animates type-in or morph to the next state. |
| **Type-in** | Animating code changes as if typed: caret, deletions, insertions. |
| **Linked chart** | A chart element linked to a chart in a Wonky Sheets spreadsheet, rendered from a stored snapshot until updated. |
| **Soft lock** | Ephemeral claim on a text body while someone edits it; others see it read-only unless they choose *Edit anyway*. |
| **Navigator** | The slide list on the left (thumbnails and group headers). |
| **Inspector** | The docked right column with Format / Animate / Slide tabs. |
| **Skipped** | Slide (or group) not shown when presenting and excluded from PDF unless included. |
| **Presenter view** | The speaker's screen with notes, next slide and timers while the audience sees the slides. |
