# Slides 12 · Implementation Plan

This plan turns the Slides specs into milestones and **work packages SL-1…SL-45** that parallel
coding agents execute in **waves**: each package is a few hours of agent work, owns its folders,
names the contracts it provides and consumes, and ends with acceptance tests. It follows the
Sheets plan ([Sheets 13](../wonky_sheets/13-implementation-plan.md)), the agent rules of
[Drive 05 §2](../wonky_drive/05-implementation-plan.md) and the decisions of the
[v2 review](../v2-review.md). **v2 is web only** (suite [01 A13](../01-architecture.md)): no
desktop-specific work is planned; desktop builds only have to compile.

Spec map: [01](01-overview.md) · [02](02-data-model.md) · [03](03-editor-canvas-and-objects.md) ·
[04](04-screens-menus-toolbar.md) · [05](05-themes-layouts-masters.md) ·
[06](06-animations-and-transitions.md) · [07](07-code-blocks.md) ·
[08](08-charts-from-sheets.md) · [09](09-collaboration-history.md) ·
[10](10-presenting-and-pdf.md) · [11](11-mcp-and-ai.md). Suite: [01](../01-architecture.md),
[08](../08-commands-and-undo.md), [12](../12-offline-and-sync.md), [14](../14-roadmap.md),
[15](../15-writing-tests.md).

> **Historical plan (M9–M11).** This plan is kept as built and is not updated. Since milestone
> **M13** (suite [14 · Roadmap](../14-roadmap.md), RevLog) Wonky Slides syncs through RevLog
> ([17](../17-revlog-sync.md)) instead of the `serverpod_offline_sync` engine: deck spaces,
> reserved spaces, `slidesSync`, the replica, `SlidesWriter`/`ServerSlidesWriter`,
> `DeckChangeLog` and its consumer, `HeadlessDeckCache`, `SyncedDeckSession` and the shared sync
> kit's client named below are gone. Current behavior: Slides [02](02-data-model.md) §3, §9–§12,
> [09](09-collaboration-history.md) §4–§6, [11](11-mcp-and-ai.md) §2.1 and [STATUS](STATUS.md).

---

## 1. Milestones

Suite milestones after the Sheets first iteration (D14): **M8** Drive + suite changes → **M9**
Slides MVP → **M10** Slides motion & content → **M11** Slides collaboration, MCP & AI.

| Milestone | Slides scope | Exit gate |
|-----------|--------------|-----------|
| **M8** Drive + suite changes (prerequisite, [Drive 05](../wonky_drive/05-implementation-plan.md)) | Unified Drive with `presentation` kind and `registerPresentation`; app homes filtered per kind; settings split; Report a bug; 50 MB quota; **shared packages extracted** (Drive 05 D-2 `wonky_code*`, D-3 `wonky_numfmt`/`wonky_charts*`, D-4 space kinds + OS-8, D-6 `wonky_sync_kit*`, D-7 `wonky_rich_text`/`wonky_fonts`/`wonky_spellcheck`); **SL-1**: `wonky_slides` skeleton boots in the shell at `/slides/` (dev port 8104) with its home | Sheets and Write green after the extractions (no behavior change); Slides home lists presentations; an empty deck route renders "Coming soon" |
| **M9** Slides MVP | Synced schema release **S-1** with every Slides table of 02 §3 + all synced additions from 03–11 known at M9; ids; `DeckModel`; planner + undo; sync (spaces, `slidesSync`, change-log consumer); canvas, selection, transforms, smart guides, align/distribute; text (super_editor overlay), shapes, lines/connectors, images, tables, icons; element groups, lock/hide/z-order; format painter; clipboard (within/across decks, Write/Sheets/OS); find & replace; navigator with **slide groups** (D11); grid view; speaker notes; inspector (Format + Slide tabs); menus/toolbar/context menus; themes (10 built-ins), layouts (16), placeholders, Themes panel, page setup; presence roster + **soft locks** + text hints; **present** (full screen, keyboard, slide picker with groups, **presenter view in this window**, **audience on another device or browser** via the presentation session — no second window, v2 review Q29); **PDF export** (slides, notes pages, skipped in/out, group bookmarks); thumbnails; templates (5 of 10) | Journeys J-S1…J-S4 (§7.6) pass on the web; command harness green; multi-client scenarios 09 §6.4 #1–17, 21–22, 26–29 pass; perf budgets of 03 §18 (web); PDF of the reference decks validated (§7.7) |
| **M10** Motion & content | Builds, animation pane (Inspector › Animate), transitions incl. 3D, **Magic Move**, timeline model, reduced motion (06); laser/pen/highlighter, loop/kiosk (10); code blocks, highlight steps, **type-in**, morph (07); Write exports on the shared tokenizer (Q25); **linked Sheets charts** with update/client-side auto-update (Q28)/unlink, native charts (P1), **3D charts** with animatable camera (08); PDF builds as pages; outline view; masters & layout editing + theme editor (05 §8); Layers panel; accessibility checker; templates 10 of 10 | Journeys J-S5…J-S7; timeline determinism tests (client ≡ server frames); 60 fps transitions on the reference machine in Chrome; scenarios #18–20, 23–25 |
| **M11** Collaboration, MCP & AI | Live pointers, follow mode, follow presenter, transform hints (09 §1–2); comments on slides/elements; version history (snapshots, per-slide diff, restore, copies); overwritten-text review; activity; phone remote, rehearse, same-browser fast path (10, P1 items); `slides.*` headless MCP tools + `ui.slides.*` (11); AI features (11) and the Drive assistant (P1); remaining P1 items (spelling, emoji, image adjustments, curved connectors) | Journeys J-S8…J-S10; all §7.3 scenarios; MCP integration suite; a11y checklist; no open P0/P1 bugs |

**Synced schema releases.** S-1 (M9, SL-2) contains every table and column defined in 02 and
the additions listed in 02 §14 at that time. Additions discovered later are batched into S-2
(start of M10, SL-24) and S-3 (start of M11, SL-37) at most; each release bumps
`syncTablesHash` for **all** apps (Sheets clients must update too, suite 01 §7), so releases are
coordinated with Sheets.

---

## 2. How the agents work

The rules of [Drive 05 §2](../wonky_drive/05-implementation-plan.md) apply unchanged: ≤ 5
agents at once on the 16 GB laptop, ≤ 2 concurrent server test runs, **one web-build token**
(named per wave in §4), one shared working tree, ownership by folder, one open migration at a
time, agents never start the server. Slides-specific additions:

- **Registration files**: SL-11 owns the command registration index
  (`wonky_slides/lib/commands/commands.dart`), `MenuSpec`, toolbar spec and the inspector/panel
  registries; other packages add one-line registrations and own their
  `commands/<area>_commands.dart`.
- **Synced schema**: only SL-2 (S-1), SL-24 (S-2) and SL-37 (S-3) change synced models; other
  packages queue their additions in 02 §14 and the next release picks them up.
- **Contract changes** after a contract package merged go through a small contract PR that the
  owners of the consuming packages review.
- **Ownership moves**: when a package is merged, its folders may be extended by later packages
  that name them under *Owns* (e.g. `features/present/` by SL-29).

---

## 3. Existing code to reuse

| Need | Start from |
|------|------------|
| Session per open file | `wonky_sheets/lib/features/model/{workbook_session,memory_workbook_session}.dart` → `DeckSession`/`MemoryDeckSession` (§5.3) |
| Replica, sync controller, writer, journal | `wonky_sync_kit_flutter` (extracted by Drive 05 D-6 from `wonky_sheets/lib/features/sync/`); `synced_workbook_session.dart` as the model for `SyncedDeckSession` |
| Planner, row changes, undo | `wonky_sync_kit` (`RowChange`, `MutationPlan`, `UndoInverter`); Sheets' `wonky_sheets_core/lib/src/mutations/{planner,plan_builder,operations,maintenance}.dart` as the pattern |
| Server spaces, sync, change log, headless | `wonky_server/lib/src/platform/spaces/` (D-4), `wonky_server/lib/src/sheets/{sync,changelog,headless,versions,exports}/` (`server_sheets_writer.dart`, `change_log_consumer.dart`, `headless_workbook*.dart`, `sheets_export_service.dart`) |
| Rich text | `wonky_rich_text` (D-7) and Write's super_editor integration in `wonky_write/lib/features/editor/` (mapper/applier/extractor) |
| Charts | `wonky_charts`, `wonky_charts_flutter`, `wonky_numfmt` (D-3); Sheets' chart insert/editor UI in `wonky_sheets/lib/features/charts/` as the UX reference |
| Code | `wonky_code`, `wonky_code_flutter` (D-2) |
| Shell, homes, comments, versions, presence, MCP bridge, assistant | `packages/wonky_app/lib/src/{drive,comments,versions,presence,mcp_bridge,assistant}/`; server `platform/{comments,versions,presence,mcp,ai}/` |
| Exports, print preview | Write `wonky_write_core/lib/src/export/pdf/`, `wonky_write/lib/features/print/`; Sheets `wonky_sheets/lib/features/print/` |

---

## 4. Work packages

### 4.1 Overview

| WP | Title | Milestone · wave | Depends on | Token |
|----|-------|------------------|-----------|-------|
| SL-1 | App skeleton, serving, home | M8 · Drive wave 4 | D-5, D-10 | (D-18 builds) |
| SL-2 | Synced schema S-1, ids, columns lint | M9 · 1 | D-6 | |
| SL-3 | Core contracts, `DeckSession`, test harness | M9 · 1 | SL-2 (types) | |
| SL-4 | Spike: super_editor text overlay | M9 · 1 | SL-1 | |
| SL-5 | Server: deck spaces, `slidesSync`, change-log consumer | M9 · 1 | SL-2, D-4 | |
| SL-6 | Themes core, layouts, built-in themes, fonts | M9 · 1 | D-7 | |
| SL-7 | Core model, resolvers, planner, maintenance | M9 · 2 | SL-3 | |
| SL-8 | Copier, clipboard codec, text schema, headless deck | M9 · 2 | SL-3, SL-5 | |
| SL-9 | Client sync, replica, `SyncedDeckSession`, offline creation | M9 · 2 | SL-3, SL-5 | |
| SL-10 | Scene, text layout, geometry, connectors, stage, thumbnails | M9 · 2 | SL-3, SL-6 | |
| SL-11 | Chrome: editor screen, menus, toolbar, inspector shell, home, settings | M9 · 2 | SL-1, SL-3 | ✓ |
| SL-12 | Canvas, selection, transforms, snapping | M9 · 3 | SL-7, SL-10 | |
| SL-13 | Text editing overlay and placeholders | M9 · 3 | SL-4, SL-10, SL-12 (API) | ✓ |
| SL-14 | Shapes, lines/connectors, icons, groups, z-order, format painter | M9 · 3 | SL-7, SL-10, SL-12 (API) | |
| SL-15 | Images and tables | M9 · 3 | SL-7, SL-10, SL-12 (API) | |
| SL-16 | Navigator, slide groups, grid view, notes | M9 · 3 | SL-7, SL-10, SL-11 | |
| SL-17 | Themes panel, layout apply, page setup | M9 · 4 | SL-6, SL-11, SL-12 | |
| SL-18 | Clipboard UI, cross-app paste, find & replace | M9 · 4 | SL-8, SL-13…SL-15 | |
| SL-19 | Present mode, presenter view, presentation session | M9 · 4 | SL-10, SL-11, SL-16 | ✓ |
| SL-20 | PDF export and print preview | M9 · 4 | SL-10 | |
| SL-21 | Presence, soft locks, text hints | M9 · 4 | SL-9, SL-13 | |
| SL-22 | Templates (5 of 10) | M9 · 5 | SL-6, SL-8 | |
| SL-23 | M9 integration and exit | M9 · 5 | all M9 | ✓ |
| SL-24 | Timeline core and builds model (+ schema S-2) | M10 · 1 | SL-7, SL-10 | |
| SL-25 | Transitions and Magic Move core | M10 · 1 | SL-10, SL-24 (API) | |
| SL-26 | Code core (`wonky_code` layout/type-in/morph, code element model) | M10 · 1 | D-2, SL-7 | |
| SL-27 | Chart link core, `wonky_charts` additions, server chart endpoint | M10 · 1 | D-3, SL-7 | |
| SL-28 | Masters, layout editing, theme editor | M10 · 1 | SL-17 | |
| SL-29 | Motion player and rendering; present with builds; present tools | M10 · 2 | SL-24, SL-25, SL-19 | ✓ |
| SL-30 | Animate tab, animation pane, transitions UI | M10 · 2 | SL-24, SL-25, SL-11 | |
| SL-31 | Code element UI | M10 · 2 | SL-26, SL-24 (API) | |
| SL-32 | Chart element UI, linked updates, 3D camera | M10 · 2 | SL-27, SL-24 (API) | |
| SL-33 | PDF builds as pages, print frame option, PNG export | M10 · 2 | SL-20, SL-24 | |
| SL-34 | Outline view, Layers panel, accessibility checker | M10 · 3 | SL-14, SL-16 | |
| SL-35 | Write exports on the shared tokenizer | M10 · 3 | SL-26 | |
| SL-36 | Templates 10 of 10, M10 integration and exit | M10 · 3 | all M10 | ✓ |
| SL-37 | Live collaboration (+ schema S-3) | M11 · 1 | SL-21 | |
| SL-38 | Comments on slides and elements | M11 · 1 | SL-12, SL-16 | |
| SL-39 | Version history, overwritten-text review, activity | M11 · 1 | SL-8, SL-9 | |
| SL-40 | MCP headless tools `slides.*` | M11 · 1 | SL-8, SL-20, SL-24…SL-27 | |
| SL-41 | Phone remote, rehearse timings, same-browser fast path (on hold) | M11 · 1 | SL-19, SL-29 | ✓ |
| SL-42 | UI bridge `ui.slides.*` | M11 · 2 | SL-11, SL-40 | |
| SL-43 | AI in Slides (+ Drive assistant, P1) | M11 · 2 | SL-40 | |
| SL-44 | Remaining P1: spelling, emoji, image adjustments, curved connectors | M11 · 2 | D-7, SL-13…SL-15 | ✓ |
| SL-45 | M11 integration and exit | M11 · 2 | all M11 | ✓ |

Waves hold ≤ 5 packages; a later wave's package starts as soon as its dependencies are merged
(M9 wave 5 overlaps M10 wave 1). "(API)" means only that package's contract must be merged.
Critical path to M9: D-6 → SL-2 → SL-3 → SL-7/SL-10 → SL-12 → SL-13 → SL-18/SL-21 → SL-23.

```
M8   D-wave 1–3 extractions ──────────────────────────────── SL-1 skeleton (D-wave 4)
M9 1 SL-2 schema ─ SL-3 contracts      SL-4 spike   SL-5 server sync   SL-6 themes core
   2 SL-7 model/planner · SL-8 copier/headless · SL-9 client sync · SL-10 scene/stage · SL-11 chrome
   3 SL-12 canvas · SL-13 text · SL-14 shapes/lines/groups · SL-15 images/tables · SL-16 navigator
   4 SL-17 themes UI · SL-18 clipboard/find · SL-19 present · SL-20 PDF · SL-21 soft locks
   5 SL-22 templates · SL-23 M9 exit
M10 1 SL-24 timeline · SL-25 transitions · SL-26 code core · SL-27 chart core · SL-28 masters
    2 SL-29 player · SL-30 Animate UI · SL-31 code UI · SL-32 chart UI · SL-33 PDF builds
    3 SL-34 outline/layers/a11y · SL-35 Write export tokenizer · SL-36 M10 exit
M11 1 SL-37 live collab · SL-38 comments · SL-39 history · SL-40 MCP · SL-41 remote/rehearse
    2 SL-42 UI bridge · SL-43 AI · SL-44 P1 leftovers · SL-45 M11 exit
```

Paths below: `app/` = `wonky_slides/lib/`, `core/` = `packages/wonky_slides_core/lib/src/`,
`server/` = `wonky_server/lib/src/slides/`.

### 4.2 M8 (in Drive 05 wave 4)

**SL-1 · App skeleton, serving, home**
- Scope: `wonky_slides` workspace member, `main.dart`, `driver.dart`, minimal `SlidesAppConfig`
  (`app: slides`, `primaryKind: presentation`, `HomeScope.kind(presentation)`, deck route
  "Coming soon"); `webApps`/`FlutterRoute` `/slides/`, `flutter_apps` alias `slides` (8104,
  `auto_launch: false` while under construction), `flutter_build` entry, origins, web icons,
  AGENTS.md lines; `wonky_slides_core` package scaffold.
- Owns: `wonky_slides/` (scaffold), `packages/wonky_slides_core/` (scaffold), additive lines in
  `wonky_server/{pubspec.yaml,config/*.yaml,lib/server.dart}`, `AGENTS.md`.
- Acceptance: the Slides home lists presentations (none yet) with the left menu; `/slides/p/x`
  shows "Coming soon"; analyze/format clean; D-18 includes Slides in its release build check.
- As built: `wonky_slides/` (workspace member; `lib/{main,driver}.dart`; `lib/config/
  slides_app_config.dart`: `SlidesAppConfig` — `WonkyAppKind.slides`, `primaryKind:
  presentation`, brand `#d97706` (the presentation kind color, amber of the product icon),
  `WonkyProduct.slides` logo (the icon already existed in `wonky_app/assets/icons/`),
  `HomeScope.kind(presentation)` → app-home menu, `/p/:uuid` → `DeckPlaceholderScreen`
  (`lib/features/editor/`: `EditorScaffold` with a `BasicDocumentController`, title row/menubar
  of the shell, *Coming soon* body with *Back to Slides* = `shell.nav.home`); `createItem`
  creates nothing and shows a *Creating presentations is coming soon* toast, so the home's
  *+ New*, `shell.file.new {kind: presentation}` and `/new` (Drive's *New* menu; the shell then
  goes back) are safe until SL-5/SL-9 bring deck spaces and offline creation; no import route
  or handler); ARB l10n `SlidesLocalizations` (`slides_en.arb` + generated `slides_en_XA.arb`);
  `web/` (product icon favicon/192/512, manifest, sqlite files for the replica of SL-9);
  `assets/config.json` (four apps). Server: `flutter_apps: slides` (8104, `auto_launch:
  false`); `/slides/`, `config.json`, origins and `flutter_build` were already in place from
  D-5. `tool/check_dependencies.dart` rule `wonky_slides` (the full 01 §2.1 list; SL-1 uses
  only the shell). `wonky_slides_core` was already scaffolded by SL-6. An unknown or
  inaccessible deck id shows the shell's not-found / error pages (not "Coming soon"). Tests:
  `wonky_slides` 18 (config contract, home scoped to presentations light/dark with the
  app-home menu and empty state, placeholder editor light/dark + *Back to Slides*).

### 4.3 M9 wave 1 — contracts and foundations

**SL-2 · Synced schema S-1** (02 §3, §14)
*Superseded by RevLog (M13): the tables are server tables, 02 §3, §14.1.*
- Scope: every `.spy.yaml` of 02 §3 + enums + the synced additions of 03–11 known now,
  `SlidesIds` (deterministic ids), table codec registration in `wonky_sync_kit`, server and client
  migrations, `syncTablesHash` bump coordinated with Sheets, columns lint test.
- Owns: `packages/wonky_sync_models/lib/src/models/slides/**`,
  `packages/wonky_sync_models/lib/src/ids/slides_ids.dart`, `wonky_server/migrations/`,
  `wonky_slides/test/sync/columns_lint_test.dart`.
- Provides: generated model types for everything else.
- Acceptance: generated code compiles; deterministic id tests; S-1 hash recorded in 02;
  Sheets suites green with the new hash.
- As built: models in `wonky_sync_models/lib/src/models/slides/` (+ `enums/`), migration
  `20261014234831373-slides-s1` (server + client), `SlidesIds`, the table codec
  `SlidesSyncedTables` (`wonky_sync_models/tables.dart`), `SyncSchemaRelease` (S-1 hash, guard
  tests on the server and in Sheets), and `package:wonky_slides_core/schema.dart`
  (`SlidesTables`/`…Cols`, `SlidesTableSet`, `SlidesUndoHooks` = coupled columns + column-wise
  cell inserts) — 02 §2.1, §3, §12.2, §14.1. The columns lint test lives in
  `wonky_slides_core/test/schema/columns_lint_test.dart` (it scans `wonky_slides/lib/features/
  {sync,model}` and `wonky_server/lib/src/slides` once they exist) because `wonky_slides` did not
  exist yet; SL-9 moved it to `wonky_slides/test/sync/columns_lint_test.dart`.

**SL-3 · Core contracts, `DeckSession`, harness** (§5)
- Scope: records and `DeckModel` API, the sealed `SlidesOperation` set, `SlidesPlanContext`,
  `PlanException`; scene node types and `TextLayoutEngine`; `SlideTimeline` stub (zero steps,
  `printFrame` = edit frame); `ElementKindHandler` registry; server interfaces
  (`DeckChangeLogConsumer`, `HeadlessDeckProvider`, `SlidesPdfRenderer`); `DeckSession`,
  `DeckLoadState`, `MemoryDeckSession`; `CommandTestHarness` setup and fixture builders.
- Owns: `core/{model/api,ops,scene/nodes,motion/stub,interfaces}/`, `app/features/model/`,
  `wonky_slides/test/harness/`.
- Acceptance: contracts compile with fakes; a harness smoke test runs a no-op command
  execute → undo → redo on `MemoryDeckSession`.
- As built: core libraries `model.dart` (`core/model/api/`: records, `DeckModel`,
  `DeckReader`, events, `ResolvedElement` stub), `ops.dart` (`core/ops/`: the sealed
  operation family, one part per area, `Patch<T>`, `SlidesPlanContext`, `SlidesLimits`,
  `PlanException`, `SlidesChangeSummary`/`SlidesPlan`, `SlidesMutationPlanner` interface),
  `scene.dart` (`core/scene/nodes/`), `motion.dart` (`core/motion/stub/`), `interfaces.dart`
  (`core/interfaces/`), `session.dart` (`core/session/`: `DeckWritePath`, pure-Dart
  `MemoryDeck`, `slides.rows` undo entry/handler) and `testing.dart` (`DeckBuilder`,
  `themePackageRows`, `FakeSlidesPlanner`, `LwwSyncRelay`); app `features/model/`
  (`DeckSession`, `DeckSessionBase`, `MemoryDeckSession`) and
  `features/elements/element_kind_handler.dart` (handler contract + `ElementKindRegistry`);
  harness `wonky_slides/test/harness/deck_harness.dart` (`DeckHarness` on SL-1's
  `slidesHarness()`). Contract details and deviations: §5 "As built". Status: [STATUS.md](STATUS.md).

**SL-4 · Spike: super_editor overlay** (03 §6.1, v2 review Q20) — timebox 1 day
- Scope: prototype an overlay editor over a rotated text box with `SlidesDeltaMapper`; measure
  enter-editing latency (< 50 ms) and line-break equality with static rendering.
- Owns: `app/features/text_editing/spike/` (deleted or promoted by SL-13).
- Acceptance: decision record appended to 03 §6.1 (confirm super_editor, or the documented
  fallback with numbers).
- As built: **super_editor confirmed** (decision record and numbers: 03 §6.1 "Decided by spike
  SL-4"). The prototype is production-shaped and lives directly in `app/features/text_editing/`
  (not `spike/`), for SL-13 to extend: `slides_delta_mapper.dart` (`SlidesDeltaMapper`,
  `SlidesValueAttribution`, `sameDelta`), `slides_text_components.dart` (`SlidesTextStylePhase`,
  `SlidesTextViewModel`, `SlidesTextComponent(Builder)`, `SlidesTextLayoutSpec`,
  `slidesRunTextStyle`), `text_edit_geometry.dart` (`TextEditGeometry` from
  `SlideSceneBuilder.buildElement`, `sceneWithoutText`), `slides_text_reactions.dart`
  (`SlidesParagraphInheritReaction`, `createSlidesTextEditor`), `slide_text_editor.dart`
  (`SlideTextEditController`: document, editor, live geometry, 300 ms writes, external patches;
  `SlideTextEditorOverlay`; `recordTypingStep` + `SlidesTypingUndoEntry`). `wonky_slides` now
  depends on `super_editor` and `wonky_rich_text` (dev: `flutter_test_robots`). Not wired into
  the canvas (SL-12/SL-13). Tests: `wonky_slides/test/features/text_editing/` 44 (mapper 11,
  overlay ≡ static 16 incl. 3 paint comparisons and a negative control, controller/IME/pointer/
  undo 15, benchmark 2 tagged `slow`).

**SL-5 · Server: deck spaces, `slidesSync`, change-log consumer** (02 §9, 09)
*Superseded by RevLog (M13): `slidesDoc`, `SlidesRevBinding` and its hooks, 02 §3.10, §9.*
- Scope: deck kind on `SpaceService` (D-4), `slidesSync.sync` with `onMergeSuccess` and the
  OS-8 filter (deck spaces + personal space), `SlidesEndpoint.{reserveSpaces, subscribe,
  ensureSubscribed, spaceStats}` (+ `revertChange`/`reapplyChange` stubs), membership mirrored
  from the ACL, title mirroring into the drive item, `DeckChangeLog` consumer skeleton with the
  plugin registry (§5.7), `ServerSlidesWriter` skeleton.
- Owns: `server/{spaces,sync,changelog,endpoints}/`.
- Acceptance: server tests — reserve/subscribe per role, a Sheets client never receives deck
  rows, consumer exactly-once across restarts, title mirroring.
- As built: `wonky_server/lib/src/slides/` — `endpoints/` (`SlidesEndpoint` `slides.*`:
  `reserveSpaces`, `subscribe`, `unsubscribe`, `ensureSubscribed`, `spaceStats`;
  `revertChange`/`reapplyChange` throw `unavailable` until server deck edits record inverses;
  `SlidesSyncEndpoint` `slidesSync.sync`), `spaces/` (`SlidesSpaces` = `SpaceService` with
  `kind: deck`; the shared `SpaceStats` reports `sheetCount` = slides, `cellCount` = elements,
  `gridCells` 0; `SlidesDecks.create` = server-side creation behind the new
  **`drive.createPresentation(parentUuid?, name, templateUuid?)`** (`createSpace(kind: deck)`,
  `DeckFactory` rows = built-in theme copy + title slide + "Create presentation" log row, drive
  item, size estimate; `templateUuid` refused until SL-8/SL-22); `SlidesDecks.mirrorTitleToDeck`
  = drive rename → `Deck.title`), `sync/` (`SlidesSyncService` = `SpaceSync.sync(kind: deck)` +
  `onMergeSuccess` → `slides:merged:<space>` bus signal + consumer, `afterRegistration` called
  by `drive.registerPresentation`; `ServerSlidesWriter` skeleton: chunks of ≤ 5,000 changes per
  `transactionForUser` + `DeckChangeLog`, consecutive inserts batched, runs the consumer),
  `changelog/` (`DeckChangeLogProcessor` with the plugin registry; plugins `drive`
  (`DeckDriveMirror`: last-edited state, `VersionService.recordEdit`, `Deck.title` →
  `DriveItem.name`, `modifiedAt` + search text — title, group titles, element and table-cell
  text, notes — throttled 10 s with a trailing refresh), `activity` (`DeckActivity`: one
  `logEdit` per author and batch, counters `changes`, `slides`, `slidesDeleted`, `themes`),
  `storage` (`ContentSizes.onSpaceChanged`; `SlidesSizeEstimator` registered for
  `presentation`, change log excluded)), `slides_server.dart` (`SlidesServer.ensureRegistered`,
  called from `server.dart` `registerSlidesHooks` and before processing). Server-only model
  `DeckChangeLogReceipt` (migration `20261015005729394-slides-receipts`): claim per row,
  **`doneConsumers` per plugin** so a re-claimed stale row only runs the plugins not yet
  recorded (exactly once per plugin across restarts); a throwing plugin is logged and counted
  as done. ACL changes mirror deck membership (`AclEvents` → `SpaceService.mirrorMembership`).
  The server now depends on `wonky_slides_core` and `wonky_sync_kit` (01 §2.1). Deviations:
  plugins bind the core contract to `DeckChangeLogConsumer<DeckConsumerContext>` (session +
  drive item + cached authors) instead of `<Session>` (§5.7); until SL-7's planner exists,
  `DeckFactory` takes its rows from the core's `DeckBuilder` (same rows as `CreateDeck`).
  Tests: `wonky_server/test/integration/slides/slides_sync_test.dart` (9, `SlidesDevice`
  isolate devices in `test/support/slides_device.dart`).

**SL-6 · Themes core** (05 §2–§7)
- Scope: theme JSON schemas, validator, migrations, resolver; 16 built-in layouts; 10 built-in
  themes as JSON; slide sizes and scaling math; Slides display families registered in
  `wonky_fonts` (static TTF, OFL).
- Owns: `core/theme/**`, `packages/wonky_fonts/` (Slides families only).
- Acceptance: 05 §12 unit tests (validation, resolution, layout remap, size scaling); every
  built-in theme × layout resolves without warnings.
- As built: code in `core/theme/**` (`package:wonky_slides_core/themes.dart`); the display
  families are not bundled yet, so the built-ins use bundled substitutes (05 §3.2, §6) and
  `wonky_fonts` is unchanged; the shared Flutter `AssetFontRegistry` landed in `wonky_app`
  (`package:wonky_app/fonts.dart`, 05 §3.1). Status: [STATUS.md](STATUS.md).

### 4.4 M9 wave 2 — model, sync, scene, chrome

**SL-7 · Core model and planner** (02 §10–§12)
- Scope: `DeckModel` ingestion and indexes, `SlideResolver`, `TextStyleResolver`,
  `SlidesMutationPlanner` with every op of 02 §12.1 (build/code/chart ops as stubs for M10),
  coupled-column groups for `UndoInverter`, maintenance rules (02 §10), limits.
- Owns: `core/{model,mutations,maintenance}/**`.
- Acceptance: execute → undo → redo equality for every op; seeded op-sequence property test
  (invariants of 02 §10 hold; undo of all returns to the start); incremental remote patch ≡
  full reload; ≥ 90 % line coverage.
- As built: `package:wonky_slides_core/model.dart` gains `lib/src/model/{index,resolve,text,
  geometry}/` — `DeckIndexes` (`model.indexes`: `SlideOrder`, `ElementTree`, `ThemeIndex`,
  `PlaceholderIndex`, `TableIndex`, builds by element, per-slide revisions; invalidated per
  change batch), `SlideResolver` → `ResolvedSlide`/`ResolvedElement`, `TextStyleResolver`,
  `ElementFrame`/`GroupSpace`, `SlidesText` (02 §4 schema on `wonky_rich_text`); new libraries
  `planner.dart` (`lib/src/planner/`, not `mutations/`: `SlidesPlanner` for all 62 operations,
  `PlanBuilder`, `OrderKeys`, `ThemeCopy`) and `maintenance.dart` (`DeckMaintenance`).
  `SlidesPlanner` is the default of `MemoryDeckSession.blank` and `DeckHarness`;
  `FakeSlidesPlanner` stays for session contract tests. Additive contract changes:
  `ElementSpec.tableRows/tableColumns/codeStates`, `ApplyThemeToSlides.setDefault` (empty
  `slideIds` = all), `ResolvedElement` style/placeholder/field fields, `DeckViolation.toString`.
  Builds, code states and chart links are planned at row level (not stubs); their catalogs and
  schemas are validated by SL-24/SL-26/SL-27. Details: 02 §10–§12 "As built (SL-7)",
  [STATUS.md](STATUS.md).

**SL-8 · Copier, clipboard codec, text schema, headless deck**
- Scope: `DeckCopier` (id rewrite, reference remap, file re-homing plan), `SlidesClipboardCodec`,
  text schema validator/normalizer on `wonky_rich_text`, `HeadlessDeck` + `ServerSlidesWriter`
  (server write path for templates, copies, MCP), `drive.copy`/*Make a copy* for decks.
- Owns: `core/{copy,clipboard,text}/**`, `server/headless/**`.
- Acceptance: copier property test (no id collisions, every reference remapped); clipboard
  round trip; headless create → read → copy tests on the server.
- As built: core libraries `copy.dart` (`lib/src/copy/`: `DeckCopier.copy(source, deckId:,
  userId:, now:, title:, ids:, rehomeFiles:)` → `DeckCopy {rows, ids, files, dropped}`;
  `SlidesIdRemapper` shared with the clipboard; `FileRehome`), `clipboard.dart`
  (`lib/src/clipboard/`: `SlidesClipboardCodec` builds, encodes, sanitizes and renders 03 §12.2
  payloads — the planner's `PasteSlides`/`PasteElements` stay the id remapper of pastes — and
  re-homes files with `rehomeFiles`; `SlidesPasteMappers` maps plain text, Write rich text,
  grids/TSV, Sheets objects and images to `elements` payloads) and `text.dart`
  (`lib/src/text/`: `SlidesDeltaValidator`/`SlidesDeltaNormalizer` on SL-7's `SlidesText`, which
  stays in `model/text/`). Theme copies: a theme with a `sourceKey` gets
  `themeCopyId(newDeck, sourceKey)`; its parts `themePartId(theme, partKey)` with the built-in
  part key when the source part is a built-in's deterministic row, else the source row id — so
  re-applying the same built-in in the copy dedupes. Fresh ids never reuse a source id.
  Server (`wonky_server/lib/src/slides/`): `headless/` — `HeadlessDeckCache` (11 §2.1 cache and
  invalidation, pattern of Sheets' provider), `ServerHeadlessDeck` + `SlidesHeadlessProvider`
  (binds the core contract to `HeadlessDeckContext {session, actor}`; `write(op, force:)` →
  `HeadlessDeckWrite {plan, changeId, syncVersion, repaired}`), `DeckTextClaims` (presence
  claims for `being_edited`; the first watch sends a new presence `probe` message that joined
  sessions answer with `here`); `sync/server_slides_writer.dart` gained `apply` (current rows
  read first, revives through the OS-7 bulk write, skip rule with coupled columns and
  column-wise cells), `applyRecorded`, `revert`, `reapply`; `spaces/deck_copies.dart`
  (`DeckCopies.copy`) used by `drive.copy` and `drive.createPresentation(templateUuid)`;
  `DeckFactory` plans `CreateDeck` with `SlidesPlanner`. Suite additions: `file.copyToItem`
  (03 A-03-3) and the Sheets objects clipboard carries `spreadsheetItemUuid`/`objectId`/`sheetId`
  (A-03-5). Deviations: the headless code lives in `slides/headless/` (11 §2.1 named
  `slides/mcp/`); `being_edited` is a `WonkyException(conflict)` with `detailsJson {code:
  being_edited, targets}` (no new error code; SL-40 maps it to the MCP error); deck change
  records reuse Sheets' `ServerChangeRecord` (`spreadsheetUuid` = deck space, 02 §8 "shared
  format") — no migration; change-log pruning stays with SL-39 (`TODO.md`); built-in
  presentation templates (SL-22, since built) were refused with `unavailable`. Tests: core 61, server
  `test/integration/slides/slides_headless_test.dart` 12 ([STATUS.md](STATUS.md)).

**SL-9 · Client sync and sessions** (02 §9, suite 12)
*Superseded by RevLog (M13): `SlidesRevLog`, `LoggedDeckSession`, 02 §9.*
- Scope: `SlidesSyncController` on `wonky_sync_kit_flutter`, replica `slides_<userId>.db` (web
  OPFS/IndexedDB), reserved-space pool, `SyncedDeckSession`, offline *New presentation* with
  the queued `drive.registerPresentation`, remote batches, recovery export (web: download of
  `rows.json` per unsynced deck), *Simulate offline*.
- Owns: `app/features/sync/**`, `app/features/model/synced_deck_session.dart`.
- Acceptance: harness — create a deck offline → reconnect → a collaborator sees it in Drive and
  opens it; roles mirror; two clients converge on random edits (smoke property run).
- As built: `wonky_slides/lib/features/sync/` — `SlidesReplica` (`slides_<userId>.db`,
  `SlidesTableSet.tables`, `hasDeck`), `SlidesWriter` (the kit's `SyncWriter`: column-named
  updates, `bulkWrite` runs, `DeckChangeLog` row, `SlidesChangeSummary.of` for plan-less writes;
  an insert hitting a visible deterministic row keeps `id`, `createdAt` and a table cell's keys),
  `ClientSlidesRemote` (`slidesSync.sync` + `slides.*`, *Simulate offline*),
  `SlidesSyncController` (kit `AppSyncController`: loop, backoff, pause when hidden, pool of 3
  reserved deck spaces, weekly purge; `createLocalPresentation` = `CreateDeck` planned by
  `SlidesPlanner` in a reserved space; `openSession`; `elementCap` = `DeviceRowCap` on
  `slide_element`, 50,000 on browsers without OPFS), `DeckRemotePatch` (kit `RowPatch` in Slides
  rank), `SlidesData` (`install`/`uninstall`/`ready`/`current`/`createPresentation`/`strings`,
  kit `ReplicaInstallation` with the offline provider `slides` and the limited-storage
  warning), `openDeckSession(services, itemUuid)` (memory deck when not installed;
  `SlidesDataUnavailableException` when installed but not started), `DeckOpenHistory`
  (`slides.opened.<deckId>`, newest 200, for the device cap), `SlidesReplicaRecovery` (JSON of
  the unsynced decks' rows, `Wonky Slides unsynced changes <date>.json`).
  `features/model/synced_deck_session.dart`: `SyncedDeckSession` (subscribe → role, wait with
  "Downloading presentation… 42 %", load every row (`DeckChangeOrigin.load`), `DeckReady`;
  offline unavailable + reopen when online; journal ingestion → `applyRemote`; pending writes
  overlaid; role from membership after each ingestion; writes refused while opening
  (`PlanException.locked`); `DeckMaintenance.repairOp` written by editors 1 s after merges,
  not undoable). Load-state strings come from the ARB files (`SyncedDeckStrings`).
  `SlidesAppConfig`: `onSignedIn`/`onSigningOut` install/uninstall the data layer;
  `createItem` = `SlidesData.createPresentation` (offline: toast "Connect to the internet to
  create a presentation" when no reservation is usable yet). Shell additions (`wonky_app`):
  `DriveRepository.createPresentation`/`registerPresentation` (cached repository: create online
  only, register queued offline with an optimistic item, replayed into My Drive when the folder
  is gone), `createItemOnServer` handles presentations. The columns lint test moved to
  `wonky_slides/test/sync/columns_lint_test.dart`. Deviations: the recovery export is desktop
  only (as Sheets: on the web the replica sits behind the SQLite worker and can't be read once
  it failed to open) and is one JSON file (no per-deck ZIP). Tests: `wonky_slides/test/sync/`
  (43: writer/replica, session, remote-patch ≡ full-reload property (5 seeds), controller with
  an in-process sync server — offline creation → collaborator opens, viewer read-only,
  two-client random-edit convergence — `SlidesData`/`openDeckSession`, recovery, lint), server
  `test/integration/slides/slides_client_creation_test.dart` (the planner's `CreateDeck` rows →
  `slidesSync` → `registerPresentation` → consumer → collaborator device),
  `wonky_app` `test/drive/cached_drive_repository_test.dart` (queued registration).

**SL-10 · Scene, text layout, geometry, stage** (03 §6.3, 06 §12.1)
- Scope: `SlideSceneBuilder`, `FlutterTextLayoutEngine` and the core `SlideTextLayout` (pdf
  metrics), auto-fit, `ShapeLibrary` geometry, connector routing, `SlideStage` (edit frame),
  thumbnails.
- Owns: `core/{scene,layout,text_layout,geometry,connectors}/**`, `app/features/stage/**`.
- Acceptance: goldens of every geometry and text style; overlay vs static line breaks equal
  (with SL-13's mapper fake); thumbnail ≤ 8 ms.
- As built: core (`package:wonky_slides_core/scene.dart`) — `lib/src/geometry/`
  (`ShapeLibrary`: all 70 keys of 03 §6.3 incl. `custom`, with outlines as `ShapePart`s
  (shaded faces, stroke-only details), adjusts with defaults/ranges/handle tracks, text
  rectangles and connection sites; `SvgPathParser`; `ShapePathBuilder`/`PathOps`),
  `lib/src/connectors/` (`ConnectorRouter`: free and glued endpoints derived from the target's
  current frame, straight/elbow/curved routes, elbow candidate search with 24 su clearance;
  `ArrowHeads`), `lib/src/layout/` (`AutoFit`), `lib/src/text_layout/` (`TextParagraphs` =
  the styled paragraph model both engines share; `SlideTextLayout` with an injectable
  `SlideTextMeasurer`, `ApproxTextMeasurer` default), `lib/src/scene/builder/`
  (`SlideSceneBuilder` + `ScenePaint`, `ImageAdjust`, `BasicCodeLayout`) and
  `lib/src/scene/hit/` (`SceneHitTest`, for SL-12). App — `features/stage/`
  (`FlutterTextLayoutEngine`, `SlideScenePainter`, `SlideStage`, `SlideImageCache`,
  `SlideRenderer` = resolver + builder + engine + images + fonts + thumbnails per open deck,
  `CoreSceneBuilding` handler mixin) and `features/thumbnails/` (`SlideThumbnailCache`,
  `SlideThumbnail`; a folder of its own, not under `stage/`). Additive contract changes:
  `SceneContext` (`deck`, `purpose`, `icons`, `charts`, `code`, `codeStates`, `generation`,
  `withTheme`), `SlideScene.frames`/`routes`/`frameOf` (derived geometry), `PromptNode.layout`,
  `CodeScene` layout fields, `ResolvedTextStyles.theme`/`withBox`, `ScenePurpose`,
  `SlideIconSource`/`IconGlyph`, `ChartSceneSource`, `CodeSceneSource`. Deviations: no golden
  masters (they are generated on CI Linux only, 15 §7) — paint-pattern tests per kind in light
  and dark instead; the overlay-equality test uses a `TextPainter` over the same styled runs as
  SL-13's mapper fake; the stage is a `Stack` of one `RepaintBoundary` + `CustomPaint` per
  top-level node (not a custom `RenderSlideStage`, 06 §12.1); the core engine's `pdf`-metrics
  measurer is SL-20's. Details: 03 §6 "As built (SL-10)", 06 §12.1, [STATUS.md](STATUS.md).

**SL-11 · Chrome** (04) — web-build token
- Scope: full `SlidesAppConfig` (routes, `editorRoutes` present/print, `createItem` offline,
  settings sections, `mcpUiTools` stub), editor screen layout, `MenuSpec` (04 §4) with every
  command id registered (unimplemented ones disabled with a reason), toolbar spec, inspector
  shell (tabs, section registry), dialogs host, status bar, keyboard scopes (03 §1.2), palette
  providers, home config + thumbnails, Slides settings sections.
- Owns: `app/{main.dart,driver.dart,config/**,commands/commands.dart}`,
  `app/features/{editor_screen,menus,toolbar,inspector,dialogs,home,settings}/**`.
- Acceptance: 04 AC-1, AC-2, AC-9 (describable dialogs), AC-10, AC-11, AC-12 at the chrome
  level; release build opens an (empty) deck from the home.
- As built: `wonky_slides/lib/commands/` (`commands.dart` registration index — real commands,
  then the disabled placeholders (`placeholder_commands.dart`, each naming its WP) of every
  menu/toolbar/context-menu id without a real registration; `SlidesCommand`,
  `SlidesKeyScopes`; `chrome_commands.dart`: view modes, panes, inspector + the
  `slides.panel.animate` alias, zoom, View › Show/Snap toggles, Editing/Viewing, slide
  navigation, Select tool), `config/menus/` (menubar = canonical id registry, context menus),
  `config/toolbar/` (contextual section), `config/panels/` (side panel registry),
  `features/editor_screen/` (`DeckEditorScreen` on `openDeckSession` with the load states,
  `DeckDocumentController`, `DeckEditorController` with `apply(ctx, op)` = the command write
  path, responsive body, Present split button in the new `EditorScaffold.titleActions`, status
  bar, shells of canvas/navigator/notes/grid/outline/masters on a static `SlidePreview`),
  `features/inspector/` (section registry + Format/Animate/Slide tabs), `features/toolbar/`,
  `features/dialogs/` (Go to slide), `features/settings/` (four Slides settings sections,
  `slides.prefs.set`/`slides.presenter.set`), `theme/slides_tokens.dart`. `DeckHarness` runs on
  the real document/editor controllers. Shell changes (additive): `EditorScaffold.titleActions`,
  scrolling menubar strip and Star/Move hidden below 480 px (360 px), dialog `optionLabels`.
  Deviations: 04 §19. The release build signs in and shows the Slides home; opening a deck in
  the browser was blocked by a stale dev server (no `slides` endpoint) — verified by widget
  tests instead. Status: [STATUS.md](STATUS.md).

### 4.5 M9 wave 3 — editing

**SL-12 · Canvas** (03 §2–§5)
- Scope: zoom/fit/pan, selection model, marquee, handles, move/resize/rotate/nudge, `SnapEngine`
  (core), smart guides, align/distribute; rulers/guides P1.
- Owns: `app/features/{canvas,selection,snapping}/**`, `core/snapping/**`.
- Provides: selection and transform API for SL-13…SL-15 (merge the API first).
- Acceptance: 03 AC 1–3; drag perf budgets of 03 §18 (web).
- As built: core `package:wonky_slides_core/snapping.dart` (`lib/src/snapping/`:
  `SnapEngine`, `SnapTargets`, `FrameTransforms`, `UserGuides`); app `features/canvas/`
  (`SlideCanvas(editor:, controller:)`, `SlideCanvasController` — attached per open deck by
  `DeckEditorScreen`, found with `SlideCanvasController.of(editor)`, owns the deck's
  `SlideRenderer`; `CanvasController` viewport, overlay and ruler painters, `CanvasTokens`),
  `features/selection/` (`selectionOf(editor)` → `SelectionController`: select / toggle /
  enterGroup / escape / selectAll / cycle, entered group, marquee, per-slide memory;
  `TransformSession`; `ReadingOrder`; `SlideElements`), `commands/canvas_commands.dart`
  (selection, gesture writes `slides.element.move|resize|nudge|adjust|setLineEnds`, arrange
  incl. z-order, lock/hide, Edit › Delete/Duplicate of elements, guides, zoom to selection).
  Wiring into SL-11's chrome: `CanvasRegion` shows `SlideCanvas` once the controller is
  attached; `DeckDocumentController.selectAll` selects the canvas scope. API for SL-13…SL-15:
  extend `slides.element.activate` (groups only so far), read `selectionOf(editor)` and
  `SlideCanvasController.of(editor)` (scene, frames, `hitPath`/`pick`, viewport mapping,
  `handles()`); element handlers' `extraHandles` aren't consulted yet — the canvas draws shape
  adjust handles from `ShapeLibrary` and line endpoints from the scene's routes itself.
  Details and deviations: 03 §5.7, [STATUS.md](STATUS.md).

**SL-13 · Text editing and placeholders** (03 §6.1–§6.2) — web-build token (IME checks)
- Scope: super_editor overlay, `SlidesDeltaMapper`, text commands, placeholders and prompts,
  live auto-fit, typing undo bursts.
- Owns: `app/features/{text_editing,elements/text}/**`.
- Acceptance: 03 AC 4–5; IME and RTL manual check in Chrome and Safari; line-break equality
  goldens.
- As built: `app/features/text_editing/` (SL-4's overlay + `SlideTextEditing` host via
  `textEditingOf(editor)`, `SlideTextEditingLayer`, `TextFormatter`/`TextFormatState`),
  `app/features/elements/text/` (text box tool on SL-14's `CanvasTools`, toolbar text
  controls, Inspector › Text, link/value dialogs), `commands/text_commands.dart` (every text
  format command, text box, links, *Reset to layout*); `slides.element.activate` edits text;
  core op `ResetPlaceholders`; box-default lists in `TextParagraphs`; shell
  `UndoService.discardTop` + `DocumentController.beforeRedo`. Soft-lock hook
  `TextEditLocks` for SL-21. The Chrome/Safari IME/RTL check moved to SL-23 (no web build in
  SL-13). Details: 03 §6.2.1, [STATUS.md](STATUS.md).

**SL-14 · Shapes, lines, icons, groups, z-order, format painter** (03 §6.3–§6.5, §7–§9)
- Owns: `app/features/elements/{shape,line,icon,group}/**`, `app/features/format_painter/`.
- Acceptance: 03 AC 6 (shapes/lines/groups parts) and the z-order/lock/hide tests; every
  command execute → undo → redo.
- As built: app `features/elements/{shape,line,icon,style,common}/` (shape gallery + tool,
  line tool, `LucideIconSource` + icon picker, style helpers/sections/toolbar, Arrange and
  Accessibility sections), `features/format_painter/`, `commands/object_commands.dart` and
  `commands/style_commands.dart` (one line each in `commands.dart`; their placeholders are
  gone), the canvas tool hook `features/canvas/canvas_tools.dart` (`CanvasTool`/`CanvasTools`,
  wired into `SlideCanvas`, the overlay painter and `SlideCanvasController.toolPreview`); core
  `package:wonky_slides_core/icons.dart` (`LucideGlyphs`, `LucideCatalog`, generator
  `tool/generate_lucide_glyphs.dart`). Small edits in shared files: `SlideRenderer` defaults
  to `LucideIconSource`, `slides.element.activate` replaces icons, `slides.select.escape`
  disarms tools, inspector section builders, toolbar/menu/context-menu specs (gallery slots
  `insert.shape.gallery`, `format.shape.change.gallery`). New command ids:
  `slides.icon.replace`, `slides.icon.setStrokeWidth`, `slides.element.rename`; z-order,
  lock/hide were already SL-12's. Details: 03 §6.11, 04 §13.6, [STATUS.md](STATUS.md).

**SL-15 · Images and tables** (03 §6.6–§6.7)
- Scope: every image insert path (upload with quota pre-check, Drive, URL via
  `files.fetchImage`), crop, mask, replace; tables (axes, cells, merge, styles).
- Owns: `app/features/elements/{image,table}/**`, server `platform/files` addition
  `files.fetchImage` (03 A-03-4).
- Acceptance: 03 AC 7; quota refusal shows the shared dialog; table op property test.
- As built: `app/features/elements/{image,table}/**`, `app/features/uploads/**`
  (`SlidesPendingUploads` queue, `SlidesImageService` = the renderers' `SlideImageResolver`
  wired in `SlideCanvasController.attach`, `DeckThumbnails` and the print preview — the
  session's own resolver stays the in-memory fallback), `commands/{image,table}_commands.dart`;
  canvas hook `features/canvas/canvas_interactions.dart` (crop mode, table cells) and
  `features/elements/element_activation.dart`; text editing of table cells (SL-13's overlay
  with a cell target), text format targets of cells, the format painter for cells; server
  `file.fetchImage(itemUuid, url) → bytes` (`platform/files/file_image_proxy.dart`) and
  `file.copyToItem` for Drive image files. Core (additive): `ReplaceImage.crop`,
  `TextNode.partId`, `TableGrid` + `SlideSceneBuilder.tableGrid`. Details and deviations:
  03 §6.12, [STATUS.md](STATUS.md).

**SL-16 · Navigator, slide groups, grid view, notes** (04 §5, §8, §9)
- Owns: `app/features/{navigator,groups,grid_view,notes}/**`.
- Acceptance: 04 AC-3, AC-5, AC-8 (grid part); one-level groups only (Q22).
- As built: `app/features/{navigator,grid_view,notes}/**` (groups live in `navigator/`) and
  `app/commands/navigator_commands.dart` — the navigator (rows, selection, collapse per user
  and device, inline rename, color menu, drag and drop with live indicators and one-step
  drops, Alt copy, insertion caret, §5.9 keyboard), the grid view (light table) and the
  speaker notes editor (notes subset on super_editor, coalesced typing steps, mini toolbar,
  zoom); 19 placeholders replaced plus `slides.group.rename/move/toggleCollapsed`,
  `slides.nav.selectAllSlides`, `slides.navigator.copy/cut/paste`, `slides.notes.zoom`; the
  shell Edit menu routes cut/copy/paste/select all to the navigator when it owns them.
  Additive core contract: `CreateGroup.target` (empty groups; a group created from a grouped
  slide goes after its group) and the lowest free "Group n". Details: 04 §20,
  [STATUS.md](STATUS.md).

### 4.6 M9 wave 4 — themes UI, clipboard, presenting, PDF, soft locks

**SL-17 · Themes panel and page setup** (05 §7, §9)
- Owns: `app/features/themes/**`.
- Acceptance: 05 AC 1–8 (apply, import, appearance, scaling).
- As built: app `features/themes/` (`ThemesPanel` + `themesPanelSpec` — the side panel
  registered in `config/panels/slides_panels.dart`; `ThemePreviews`/`ThemePreviewDeck` —
  in-memory preview decks (built-ins at the deck size, shared; the deck's own themes copied
  row for row, rebuilt after theme/master/layout/size changes) drawn by `SlideThumbnail` in the
  deck appearance, never written to the open deck; `PreviewCard`; `ThemeImport` +
  `PresentationPickerDialog`; Inspector › Slide › Background `backgroundSection`),
  `features/layouts/` (`LayoutGallery` — thumbnails of the current slide's theme with prompts,
  in the toolbar's *Layout ▾* and Inspector › Slide › Layout (`layoutSection`)),
  `features/page_setup/` (`PageSetupDialog` — custom, MCP-describable, preview of the current
  slide letterboxed or clipped; `showNumberingDialog` — `WonkyDialogSpec`) and
  `commands/theme_commands.dart`: `slides.panel.themes`, `slides.theme.apply|import|rename|
  duplicate|setDefault|delete|removeUnused`, `slides.deck.setAppearance` (toggle without an
  argument), `slides.slide.applyLayout|resetToLayout|setBackground|applyBackgroundToAll|
  setHideMasterElements`, `slides.file.pageSetup` + new `slides.deck.setSize`,
  `slides.deck.openNumbering` + new `slides.deck.setNumbering` (nine placeholders replaced).
  *Apply theme* with a built-in = `ImportTheme` + `ApplyThemeToSlides` in one transaction (one
  undo step; scope *all* sets the default, *selected* keeps it). Core (additive):
  `ImportTheme.themeEntry` + `themeName` (copies a deck theme's rows — element groups, images,
  every column — deterministic with a `sourceKey`, fresh ids for *Duplicate theme*; shares
  `copyThemeEntry` with *Keep source formatting* pastes), `SlidesClipboardCodec.themeEntry`
  public. Server: `slides/themes/` — `SlidesThemesEndpoint` (`slidesThemes.list(itemUuid)`,
  viewer+, theme entries + usage as JSON). Re-homed theme images get deterministic copy uuids
  (`themePartId(theme, "file:<n>")`), so repeated imports reuse their copies. Deviations and
  leftovers: 05 §9 "As built (SL-17)", `TODO.md`.

**SL-18 · Clipboard UI, cross-app paste, find & replace** (03 §12–§13)
- Scope: web Clipboard API + in-app store, paste mappers (Write, Sheets, HTML, plain text,
  images), paste options chip, cross-deck paste with `FileEndpoint.copyToItem` re-homing
  (03 A-03-3, quota-checked), find & replace.
- Owns: `app/features/{clipboard,find}/**`, `copyToItem` in `wonky_server/lib/src/platform/files/`.
- Acceptance: 03 AC 8–10; 04 AC-4 (groups across decks, online and offline).
- As built: core `clipboard/slides_html.dart` (`SlidesHtml`: payload HTML with the embedded
  `data-wonky-slides` payload, Write's `data-wonky-delta`, single-table grids with formats and
  merges, any HTML → Write-flavored Delta), `SlidesClipboardCodec.htmlBody`,
  `SlidesPasteMappers.html|writeText`, and the new `find.dart` (`DeckFind`; `html` joins the
  core's dependencies); app `features/clipboard/` (`system_clipboard*` — async Clipboard API
  text/HTML/PNG, Flutter text on desktop; `deck_clipboard.dart` — targets, copy/cut/paste,
  resolution order, `prepareFiles`; `rehome_queue.dart` — `SlidesRehomeQueue`;
  `paste_options.dart` — chip), `features/find/` (`find_controller`, `find_bar`,
  `find_replace_panel`, `find_overlay` with `DeckCanvasOverlays` and the highlight painter),
  `commands/{clipboard,find}_commands.dart`; small wiring in `commands/commands.dart`,
  `placeholder_commands.dart` (three placeholders removed), `config/menus/slides_menu_spec.dart`
  (Edit › Find), `editor_screen/{deck_document_controller,canvas_region}.dart`,
  `text_editing/text_editing_layer.dart` (Mod+C/X/V), `navigator/navigator_clipboard.dart`
  (the in-app store also writes the system clipboard; `adopt`, `hasElements`),
  `commands/navigator_commands.dart` (paste re-homes and shows the chip),
  `uploads/slides_image_service.dart` (pending copies render from their source), ARB strings;
  Sheets `features/objects/object_ops.dart` writes object copies to the shared user store
  (`clipboard.sheetsObjects`) so Slides pastes linked charts across apps. No endpoint changes:
  `file.copyToItem` (SL-8) is used as is; server test
  `test/integration/platform/file_copy_to_item_test.dart` covers the paste flows. Deviations
  and details: 03 §12 / §13 "As built (SL-18)", `TODO.md`.

**SL-19 · Present mode, presenter view, presentation session** (10 §1–§6) — web-build token
- Scope: present route, full screen with the full-window fallback, keymap scope `present`,
  navigation and clicker map, slide picker with groups, black/white, end screen; **presenter
  view in this window** (§5.1); `PresentationEndpoint` with the `audience` role, *Open on
  another device…* (link + QR), *Show audience view here* banner; no `window.open` anywhere
  (v2 review Q5/Q29).
- Owns: `app/features/present/**`, `server/present/**`.
- Acceptance: 10 AC 1–5 and 7; a second browser signed in as the same user follows navigation
  ≤ 300 ms p95 on a LAN; the single-window test of 10 §18.
- As built: app `features/present/` (`PresentScreen` on the `present` child route with
  `view=presenter|audience`, `PresentSequence` over timeline steps, `PresentController`,
  `PresentStage`, `SlidePicker`, `PresenterView`, overlays/toolbar/help, *Open on another
  device…* with a QR code (new justified dependency `qr`), `PresentSessionBanner` in the editor,
  `PresentationLink` + `ClockOffset`, `PresentPlatform` Fullscreen API behind a conditional
  import) and `commands/present_commands.dart` (25 commands incl. the undoable
  `slides.deck.setPresentSettings`); server `slides/present/` (`PresentationEndpoint`
  `presentation.join`/`findSession`, `PresentationService` on `present:<sessionId>`, 21
  non-table models). The state message carries elapsed times relative to the send time plus a
  `serverTimeMs` on every event (10 §6.2 as built). Web checks (full screen, clicker, second
  browser latency) were not run (no web-build token) and kiosk timers, pre-flight and presence
  `presenting` are open — `TODO.md`. Details: 10 §6.6, [STATUS.md](STATUS.md).

**SL-20 · PDF export and print preview** (10 §11–§12)
- Scope: core PDF renderer (slides, notes pages, skipped in/out, group bookmarks, links, embedded
  subset fonts), client export (Flutter layout results), server export endpoint, print route;
  handouts P1.
- Owns: `core/export/pdf/**`, `app/features/print/**`, `server/exports/**`.
- Acceptance: 10 AC 12–14 for M9 options; client/server parity diff < 1 % on the corpus.
- As built: core `package:wonky_slides_core/pdf.dart` (`lib/src/export/pdf/`) —
  `SlidesPdfExporter` (the `SlidesPdfRenderer`), `SlidePdfPainter`, `SlidesPdfPlanner` +
  `SlidesPdfGeometry`, `SlidesPdfOptionsCodec` (JSON, layout defaults, last-used
  preferences), `SlidesPdfStrings`, and SL-10's TTF measurer `TtfTextMeasurer` (+
  `TtfFaceSet`, `RecordingTextMeasurer`, `BundledFileFontProvider` over `wonky_fonts` files);
  additive contract fields `SlidesPdfOptions.slideIds` and `SlidesExportResources.info`
  (`SlidesPdfDocumentInfo`). Server `slides/exports/` (`SlidesExportEndpoint` =
  `slidesExport`, `SlidesExportService`, `ServerSlideImageResolver`). App
  `features/print/` (`PrintPreviewScreen` on the `print` child route, `SlidesPrintController`,
  `PrintSettingsPanel`, `PdfView`, `SlidesClientExport`) and `commands/print_commands.dart`
  (`slides.print.open`, `slides.file.download`, `slides.print.print`). Handouts are built
  (not deferred). Client/server parity is checked on line breaks (stage engine vs TTF layout,
  all built-in themes) instead of a raster diff (no poppler on the dev machine; `TODO.md`).
  Details: 10 §11.3 "As built (SL-20)", [STATUS.md](STATUS.md).

**SL-21 · Presence, soft locks, text hints** (09 §1.1, §2)
- Owns: `app/features/collab/**` (roster, locks, hints).
- Acceptance: 09 AC 1–3; scenarios 09 §6.4 for locks.
- As built: `wonky_slides/lib/features/collab/` — `SlidesCollab` (per editor:
  `SlidesPresenceController`, `SlidesSoftLocks` = the text editing's `TextEditLocks`,
  `SlidesHints`), `CollabCanvasLayer` (hinted scene, remote outlines and flags, soft-lock
  outlines/flags/popover, drag outlines, follow banner), `SlidePresenceDots` (navigator, collapsed
  groups, grid), `NotesLockBanner`, `PresenterPill`; `commands/collab_commands.dart`
  (`slides.presence.jumpTo|follow|unfollow|followPresenter`, `slides.text.editAnyway`). Hooks:
  `TextLockTarget` + `…Target` methods on `TextEditLocks` (cells, notes), the notes pane claims
  its body, `DeckDocumentController` presence forwarding and `ui.get_state` collaborators,
  `DeckEditorScreen` attaches the collaboration. Presenting is read from SL-19's
  `activePresentation`; *Follow presenter* joins its audience view. Also fixed SL-9's follow-up:
  a membership that returns while a deck (or a Sheets workbook) is open reloads it and turns it
  ready again. Details and deviations: 09 §2.5, [STATUS.md](STATUS.md).

### 4.7 M9 wave 5 — exit

**SL-22 · Templates (5 of 10)** (04 §15)
- Owns: `server/templates/**` (decks as JSON fixtures applied by `ServerSlidesWriter`).
- Acceptance: each template opens offline after first sync; gallery screenshots generated.
- As built: the decks are **pure-Dart definitions in the core**, not JSON fixtures —
  `package:wonky_slides_core/templates.dart` (`lib/src/templates/`): `SlidesTemplate` (key,
  name, description, category, built-in theme, script), `SlidesTemplates.all/byKey/byUuid/
  uuidOf` (gallery uuid = UUIDv5(URL, `wonky-template:<key>`), same as the server's
  `BuiltinTemplate.uuid`), `TemplateDeckBuilder` (each slide, group, placeholder text, shape,
  table and code state is a `SlidesOperation` planned by `SlidesPlanner` against the growing
  model; `inserts` in dependency order), `TemplateShapes`/`TemplateText`/`TemplatePara`/
  `TemplateRun` and shared compositions (`decks/parts.dart`: cards, stats, people, timeline,
  flow; shapes and text only, theme colors only). Five templates, each on its own theme:
  *Pitch deck* (Aurora, 4 slide groups), *Project kickoff* (Swiss, 3 groups, milestone table),
  *Weekly update* (Wonky, status table), *Lesson* (Botanical, 3 groups, process flow),
  *Workshop agenda* (Terminal, 2 groups, schedule table, 2 Python code slides). Server
  (`wonky_server/lib/src/slides/templates/slides_template_decks.dart`): `SlidesTemplateDecks`
  (`preview` build with fixed ids for the card text and the size estimate, `write` through
  `ServerSlidesWriter`); `BuiltinTemplates.all` adds `BuiltinTemplate.presentation(t)` per core
  template (category by name, `themeKey` = the Slides theme, `previewStyle` from the theme's
  colors, `previewText` = title slide); `SlidesDecks._fromTemplate` builds built-ins (quota
  pre-check, reason `template`), `_createDeck` shared with blank decks. Client: built-in
  templates are created **offline-first** in a reserved space (`SlidesData.createPresentation`
  → `SlidesSyncController.createLocalPresentation(template:)`); gallery cards of built-ins
  render their first slide (`WonkyAppConfig.templatePreview` hook →
  `features/templates/template_preview.dart`, `SlideThumbnail` of an in-memory build);
  presentation cards are 16:9 in every app (Drive draws a title-slide miniature from
  `previewStyle`/`previewText`). Gallery screenshots: contact sheets of every template in
  light and dark are written by `wonky_slides/test/features/templates/slides_templates_test.dart`
  with `WONKY_TEMPLATE_PNG_DIR=<dir>`. Deviations: categories map to the suite's existing
  `TemplateCategory` values (Business → *Work*, Engineering → *Education*; no new enum values);
  Quarterly review, Tech talk, Product launch and Portfolio come with SL-36 (linked charts,
  type-in, images). Tests: core `test/templates` 39, server
  `test/integration/slides/slides_templates_test.dart` 8, Slides
  `test/features/templates` 5, `wonky_app` `test/drive/template_cards_test.dart` 2
  ([STATUS.md](STATUS.md)).

**SL-23 · M9 integration and exit** — web-build token
- Scope: J-S1…J-S4, multi-client scenarios for M9, perf budgets, PDF validation corpus,
  AGENTS.md, spec touch-ups (all apps stay `auto_launch: false`, suite 01 §2.4).
- Owns: `wonky_slides/integration_test/`, `wonky_slides/test/harness/scenarios/`,
  `benchmark/slides/`.
- Acceptance: the M9 exit gate of §1.
- As built (changed goal from the user: a clean, working M9 that **only shows what works**,
  remaining work handed to `TODO.md`): `app/config/slides_features.dart` — `SlidesFeature`
  (one value per unbuilt area with its WP) and `SlidesFeatures` (`enabled`, empty for M9;
  `featureOfCommand`/`featureOf(id, args)`/`offers`/`registers`/`prune`/`pruneRoot`/
  `hidesShellCommand`). Commands of hidden features — real and placeholder — aren't
  registered (`slidesCommands`); the menubar, context menus and the Present split menu are
  pruned; the toolbar, inspector (Animate tab, Format sections without a builder), status bar
  (outline mode), layout section (*Edit layout*), print panel (*Print each build stage*),
  settings (`offersDefaultsKey`, the *Animations & code* page) and the command schemas
  (`setMode`, `inspector.open`, `file.download`, `edit.pasteSpecial`, `prefs.set`) only offer
  what works; `DeckEditorController.setMode`/`inspectorTab` refuse hidden modes/tabs; the
  `history` child route isn't registered. Shared additive API: `WonkyAppConfig
  .hidesShellCommand` (shell comments/versions/assistant commands left out of Slides) and
  `EditorScaffold.historyPanel`. Sheets chart pastes are refused with a toast while charts are
  hidden. Wiring: `PresentController` compiles with `SlideMotionInput.fromDeck` and
  `CompileOptions(reducedMotion:)`; blank decks take the *New presentations* defaults
  (`newPresentationDefaults`). Not built from the original scope: the `integration_test/`
  journeys, the scripted multi-client scenarios, perf benchmarks and the PDF corpus diff (see
  the M9 checklist in [suite 14 §2.1](../14-roadmap.md) and `TODO.md`). Like every app,
  `slides` has `auto_launch: false` (suite 01 §2.4). Details: [STATUS.md](STATUS.md).

### 4.8 M10 wave 1 — motion, code and chart cores

**SL-24 · Timeline core and builds model** (06 §2–§4, §9; schema S-2)
- Owns: `core/motion/{timeline,builds,effects}/**`, S-2 model additions.
- Acceptance: 06 timeline unit tests; determinism (same input → same frames, client ≡ server);
  print frame per Q24.
- As built: `package:wonky_slides_core/motion.dart` → `lib/src/motion/{easing,effects,builds,
  timeline,util}/` (the stub's `stub/` keeps only the transition stub for SL-25): the
  compiler/evaluator (`SlideTimelineCompiler.compile(SlideMotionInput.fromDeck(deck, slideId,
  {resolved, scene}))`), frames, `EffectCatalog`, `BuildOptions`, `TransitionSpec`,
  `DeckMotionDefaults`, `MotionEasing`, part segmentation and order, `BuildEdits` (the
  operations of the 06 §15 build/transition commands); planner validation of builds and
  transitions, `MoveBuilds.trigger`, `SetDeckProps.resetSlideTransitions`, new slides inherit
  the deck default transition; the PDF exporter compiles from the resolved slide and scene.
  **Schema release S-2**: `BuildTrigger.onElementClick` (reserved) + the enum-values guard
  `SyncSchemaRelease.syncEnumsHash`; no table change, no migration. Details and deviations:
  06 §9.8, 02 §14.1, [STATUS.md](STATUS.md).

**SL-25 · Transitions and Magic Move core** (06 §7–§8)
- Owns: `core/motion/{transitions,magic_move}/**`.
- Acceptance: `MagicMoveMatcher` tests (shapes, text glyphs via `SequenceDiff`, code tokens,
  chart camera); plan budget ≤ 15 ms for the 06 §9.7 fixture.
- As built: `package:wonky_slides_core/motion.dart` → `lib/src/motion/transitions/`
  (`TransitionCompiler.compile`/`between`/`preview` → `TransitionPlan` with `frameAt(ms)`,
  `at(t)`, `sample(n)`, `describe()`; `TransitionFrame` of `TransitionQuad`s — every 06 §7.2 type
  as slide-space 2D/3D transforms with perspective, clips, dissolve, shading, regions, back-face
  culling, `backdrop` for *fade through* —; fallbacks and reduced motion (300 ms fade); reverse
  playback; `TransitionInfo` tile metadata) and `lib/src/motion/magic_move/` (`MagicMoveSlide
  .fromDeck`, `MagicMoveMatcher` (keys, content signatures, names, groups), `MagicMovePlan` with
  `MorphPair`s in modes replace/path/glyphs/crossfade/group, `PathMorph` (128-point outlines),
  `TextMorph` (glyph runs via `SequenceDiff`), code `TokenMorphPlan`s (SL-26), chart cameras
  through the `ChartCameraLerp` seam → `Chart3DView.lerp` (SL-27); `frameAt(ms)` → both slides'
  `SlideFrame`s + paint layers + pair descriptors). Additive frame fields: `TextPartState.color`,
  `BackgroundState.toJson`. Plan ≈ 1.4 ms for the §9.7 fixture. **For SL-29**: compile with
  `TransitionCompiler.between(model, fromSlideId:, toSlideId:, fromFrame: A.finalFrame, toFrame:
  B.initial, options: TransitionOptions(reducedMotion:, reverse:), fromScene:, toScene:)`;
  snapshot types draw `frame.quads` (projective divide for 3D), Magic Move draws both scenes with
  `frame.magicMove.outgoing/incoming` in `layers` order (nested element states for group
  children; clamp opacity products) and may refine with `pairs` (morphed outlines, code token
  glyphs, chart scene morph, image crop). **For SL-30**: `TransitionCatalog` + `TransitionInfo`
  (group, description, icon, direction param, reduced-motion behavior), `TransitionCompiler
  .preview(spec)` / `plan.sample(n)` for tiles, `MagicMoveMatcher.match` /
  `MagicMovePlan.matches` for the match badges and View › *Show Magic Move matches*. The
  `animations` feature is on since SL-29/SL-30. Details and deviations: 06 §9.9, [STATUS.md](STATUS.md).

**SL-26 · Code core** (07 §3–§6)
- Scope: `CodeLayout`, `MonoFontMetrics`, `CodeEditScript`, `TypingScript`, `TokenMorphPlan`,
  `HighlightSteps` in `wonky_code`; `CodeElementModel` and `CodeScene` in the core.
- Owns: `packages/wonky_code/lib/src/{layout,typing,morph,steps}/**`, `core/code/**`.
- Acceptance: 07 §16 unit tests; tokenizer budget of 07 §14.
- As built: `wonky_code` — `layout/` (`MonoFontMetrics` with the measured JetBrains Mono /
  Roboto Mono metrics and `fromTtf`, `CodeColumns`, `CodeLayout` + `CodeLayoutOptions`/
  `CodeRow`/`CodeLayoutLine`/`GridPos`/`CodeRect`, `CodeBoxGeometry`/`CodeBoxOptions`/
  `CodeChrome`, `CodeAutoFit`), `steps/` (`HighlightSteps`), `typing/` (`CodeEditScript`,
  `TypingSettings`, `TypingScript`, `typingSeed`), `morph/` (`CodeLexer`, `TokenMorphPlan`,
  `oklabLerp`), `CachedCodeTokenizer`, and the engine patch SH-6 (next-match search, own
  scanner; spans unchanged) for the tokenizer budget. `wonky_code` now depends on
  `wonky_core` (`SequenceDiff`). Core — `lib/src/code/` (`package:wonky_slides_core/code.dart`,
  not `core/code/`): `CodeElementData`, `CodeAnnotations`, `CodeStateModel`,
  `CodeElementModel`, `CodeSceneComposer`, `CodeRenderStyle`, `CodeElementLayout` (the scene
  builder's default `CodeSceneSource`; `BasicCodeLayout` is an alias). `CodeScene` gained
  additive fields for SL-31/SL-33 (grid columns, line opacity/blur, bars, caret, callouts,
  morph glyphs, underlay, chrome geometry); `CodeSceneSource.codeScene` gained `step` and
  `background`. **For SL-31/SL-35/SL-24**: compose scenes with
  `CodeElementLayout().composer(element, deck, theme, background:)` →
  `build(state, step:, fromStep:, stepMix:)` / `buildTransition(from:, to:, ms:, mode:,
  reducedMotion:)`; durations from `CodeElementModel.transitionDurationMs` /
  `typeInDurationMs`; step counts from `HighlightSteps.count`; Write exports (SL-35) use
  `DefaultCodeTokenizer`/`CachedCodeTokenizer` (TextMate first). Not built: `tokenizeLine`
  (07 §5.4), `UnifiedDiff`/`WalkthroughBuilder` (07 §10.2). Details: 07 §2.3 status, [STATUS.md](STATUS.md).

**SL-27 · Chart link core and server** (08 §2.7, §3, §5, §13)
- Scope: the new `wonky_charts` APIs (reveal state, scene morph, `Chart3DView.lerp`, TTF text
  measurer, snapshot format), chart link data in the core, `SlidesChartEndpoint`
  (`resolveSnapshot`, status), Sheets clipboard payload addition (03 A-03-5).
- Owns: `packages/wonky_charts/lib/src/{reveal,morph,snapshot}/**`, `core/charts/**`,
  `server/charts/**`.
- Acceptance: 08 §20 core and server tests; snapshots contain only resolved series (08 §6).
- As built: **`wonky_charts`** — `snapshot/` (`ChartData.toJson/fromJson` via `ChartDataCodec`,
  `ChartDataSnapshot`, `ChartSourceTheme`, `ChartSourceInfo`, `ChartSourceSnapshot` = the spec's
  in-memory `ChartSnapshot` pair, renamed because the core ops already have `ChartSnapshot`;
  `ChartSnapshotColumns` (`gz:`; `archive` is a justified dependency), `ChartSourceVersion`,
  `ChartSnapshotLimits`), `reveal/` (`ChartReveal` = the spec's `ChartRevealState`, renamed
  because the timeline's per-element state has that name: a scene transform every renderer
  honors, plus `applyTo3D`), `morph/` (`ChartSceneMorph`, `OkLab`), `three_d/chart3d_view.dart`
  (`Chart3DView.lerp`, presets, `Chart3DTurn`), `render/pdf/ttf_chart_text_measurer.dart`
  (`TtfChartTextMeasurer` — the core's text layout already has a `TtfTextMeasurer`); additive
  hooks `ChartPipeline.layout(reveal:)`, `ChartLayoutOptions.perspective3D/transform3D/fitViews3D`
  (union camera fit), `Chart3DItem.withColor`. **Core** — `package:wonky_slides_core/charts.dart`
  (`lib/src/charts/`, not `core/charts/`): `ChartElementData`, `ChartOverrides`,
  `SlideChartSpec.effective` → `SlideChartLook`, `SlideChartLayout` (the `ChartSceneSource`;
  the interface gained `background`), `SlideChartMotion`, `ChartLinkService`/`ChartLinkOps`;
  planner: `gz:` columns, unlink writes `dataJson.snapshot`, `SetChartStyle` enforces the
  allowlist; `DeckBuilder.chartLink`. **Server** — `wonky_server/lib/src/slides/charts/`:
  `SlidesChartsEndpoint` (`slidesCharts`: `listCharts`, `resolveSnapshot`, `checkLinks`; the
  P1 `watch` stream is not built), `SlidesChartService`, non-table models (no migration).
  **For SL-32**: render with `SlideChartLayout(measurer: FlutterTextMeasurer())` as the stage's
  `charts`; insert/update with `ChartLinkOps.link/update` from a `ResolvedChartSnapshot` of
  `slidesCharts.resolveSnapshot`, token refresh with `ChartLinkOps.refreshToken`
  (maintenance write), probes with `ChartLinkOps.probesOf`; style edits are
  `SetChartStyle` patches (`overrides` checked by `ChartOverrides.rejectedPaths`); update
  animations with `ChartSceneMorph`. **For SL-25/SL-29**: `SlideMotionInput.fromDeck(...,
  chartShapeOf: SlideChartMotion.shapes(deck))`; per frame `SlideChartMotion.reveal(state)`,
  `.view(state, base)` and `.fitViews(state, base)` into `SlideChartLayout.build(reveal:,
  view:, fitViews:)`; Magic Move of cameras with `Chart3DView.lerp`, of 3D models with
  `transitionFrom3D`. **For SL-40**: `SlidesChartService` directly. Paste from Sheets
  (03 A-03-5) needed nothing more: the objects clipboard already carries
  `spreadsheetItemUuid`/`objectId`/`sheetId` (SL-8/SL-18). Details: 08 §2.10–§2.11,
  [STATUS.md](STATUS.md).

**SL-28 · Masters, layout editing, theme editor** (05 §8)
- Owns: `app/features/masters/**`, `app/features/themes/editor/**`.
- Acceptance: 05 AC for master and theme editing; undo of every edit.
- As built: feature `masters` on (`SlidesFeatures.shipped`). App `features/masters/`
  (`MastersView` + `MastersBanner`, `MastersNavigator` — themes, masters, layouts with live
  thumbnails and usage; `MastersCanvasLayer` — placeholder outlines and type labels;
  `surface_inspector.dart` — Inspector › Layout/Master; `MastersTargets` — command targets,
  placeholder specs, replacement layouts), `features/themes/editor/` (`themeEditorSections`,
  `ThemeEditScope`/`ThemeEditorState`, controls) and `commands/master_commands.dart`
  (`slides.layout.add|duplicate|rename|move|delete|setBackground|setHideMasterElements|
  toggleHidden|insertPlaceholder`, `slides.master.add|duplicate|rename|delete|setBackground`,
  `slides.theme.edit|update|deriveDarkColors|resetToBuiltIn`, `slides.masters.exit`; the two
  SL-28 placeholders are gone). Masters mode reuses the whole canvas: the editor's `surfaceId`
  / `surfaceKind` replace `currentSlideId` where the canvas, selection, text editing, crop and
  table modes, inserts and pastes address the edited surface. Core (additive):
  `SlideResolver.resolve` resolves layout/master ids as surfaces (`ResolvedSlide.surface`),
  `PasteElements.ownerKind`, `UpdateMasterOrLayout` accepts `sortKey`, `ThemeDarkDeriver`, the
  clipboard's `sourceSlideId` is the owner for layout elements. Deviations and leftovers: 05
  §8.4 "As built (SL-28)", `TODO.md`, [STATUS.md](STATUS.md).

### 4.9 M10 wave 2 — motion and content UI

**SL-29 · Motion player and rendering** (06 §6, §12–§14; 10 §4, §9) — web-build token
- Scope: `SlidePlayer`, stage frames, transition rendering incl. 3D (`flutter_scene`), reduced
  motion, presenting with builds and transitions, laser/pen/highlighter, loop and kiosk.
- Owns: `app/features/{motion,transitions}/**`, `app/features/present/tools/**`.
- Acceptance: 06 AC; 10 AC 6, 8; 60 fps budget of 06 §14 in Chrome on the reference machine.
- As built: `app/features/motion/` (`SlidePlayer` + `PlayerView`s and `TransitionRequest`,
  `MotionBudget`/`FrameBudget`, `MotionStage`, `SlidePlayback`/`SlidePlaybackStage` for SL-30's
  previews, `MotionTicker`, `PlayerStage`, `render/`: `MotionScenes` (code via SL-31's
  `CodeFrames`, charts via `SlideChartLayout.build(reveal:, view:, fitViews:)`), `MotionMask`,
  `MotionNodePaint`, `MotionTextPainter`, `TextRangeGeometry`, `FrameDiff`),
  `app/features/transitions/` (`SlideSnapshots`, `TransitionPainter`/`CrossfadePainter`,
  `MagicMovePainter` + `MagicMoveScenes`/`MagicMoveCharts`, `MagicMoveCodeMorphs`,
  `gpu/GpuTransitions` — flip/cube/doorway/swap/revolve on `flutter_scene` on the web with the 2D
  projective fallback), `app/features/present/tools/kiosk_exit.dart`; the stage painter applies
  every frame field (nodes inherit their element's state); `PresentController` plays builds and
  transitions through the player (reverse on back, finish/skip, audience mid-animation sync, plan
  cache and prefetch, blur and frame budgets, auto-advance, rehearsed timings, kiosk with
  `?kiosk=1`). Laser/pen/highlighter stayed where SL-19 built them (nothing to move). The
  `animations` feature is on (with SL-30). Benchmark: `wonky_slides/benchmark/motion_bench.dart`.
  Details: 06 §12.4, 10 §8.1 and §9, [STATUS.md](STATUS.md).

**SL-30 · Animate tab and animation pane** (06 §5, §7 UI)
- Owns: `app/features/builds/**`, the inspector's Animate section (`app/features/inspector/animate/`).
- Acceptance: 06 §18 UI criteria; `slides.panel.animate` opens the inspector tab (Q21).
- As built: `wonky_slides/lib/features/inspector/animate/` (`AnimateTab`, `TransitionTab`,
  `BuildTab`, `OrderTab`, `EffectTileGrid`, controls), `lib/features/builds/` (`AnimateView`,
  `AnimatePreview` on SL-29's `SlidePlayer`/`SlidePlaybackStage`, `AnimateCanvasLayer` — preview,
  build order and Magic Move badges, match ghosts, motion path —, `BuildOrder`, `BuildLabels`,
  `EasingPresets`, `BuildRecipes`, `MotionPaths`) and `lib/commands/animate_commands.dart` (06 §15
  but `drawMotionPath`/`editMotionPath`, plus `selectBuilds`, `togglePreviewOption`,
  `moveBuilds {by}`; the SL-30 placeholders are gone). Transition tiles preview the real previous →
  current slide inside the tile; build tiles preview on the canvas. Core (additive):
  `CreateDeck.defaultsJson` (Settings › *Default transition* for blank decks). The feature
  `animations` is on (added to `SlidesFeatures.shipped` once SL-29 verified present-mode
  playback). Details and deviations: 06 §5.7,
  [STATUS.md](STATUS.md), `TODO.md`.

**SL-31 · Code element UI** (07 §3, §7–§8)
- Owns: `app/features/elements/code/**`.
- Acceptance: 07 §15 criteria incl. type-in while presenting (J-S6 parts).
- As built: `wonky_slides/lib/features/elements/code/` — `CodeScenePainter` draws every
  `CodeScene` field on the stage (box, border, tab/window/caption chrome with traffic lights
  and language badge, bars/boxes/selections/gutter markers, numbers with the active color and
  `↪`, grid-placed runs with line opacity and blur, morph glyphs and gutter labels, caret,
  bubble/label/pill callouts with inline Markdown, crossfade underlay); `CodeFrames`
  (`sceneOf(composer, CodeViewState)`, `applyFrame(scene, frame, composerOf)`, `replace`) is
  **the hook for SL-29** — the player recomposes code nodes per frame with it;
  `CodeBlockView` (edit state per element, previewed step, diff gutter, in-place edit,
  transition preview, recent languages) and `CodeEditSession` (300 ms writes, coalesced
  "Typing" steps); `CodeCanvasMode` (edit field overlay, ▶ preview with the composer's
  type-in/morph/instant frames, overflow badge); the Code inspector section, dialogs and the
  toolbar language label; `lib/commands/code_commands.dart` (all 07 §11 commands but
  `pickLines` and `walkthroughFromDiff`, plus `setStateLabel`, `previewStep`, `preview`).
  `wonky_code_flutter` gained `CodeEditorField` (re_editor) and `CodeEditorGutter`. Core:
  build durations come from `CodeElementModel` (`MotionElement.codeTimings`,
  `ModelCodeMotionTimings`), `MotionCodeState.stepsOf` = `HighlightSteps.count` (empty
  steps kept), `SceneContext.codeSteps`, callout accent/body font in `CodeRenderStyle`, the
  PDF painter draws static code (box, chrome, numbers, runs, bars, line opacity). Feature
  `codeBlocks` is on. Details and leftovers: 07 §2.3 "Status (M10, SL-31)",
  [STATUS.md](STATUS.md), `TODO.md`.

**SL-32 · Chart element UI** (08 §4–§10)
- Scope: insert linked chart, *Update*, client-side auto-update (Q28), unlink/relink, Linked
  objects panel, stale badge, chart builds, 3D camera; native charts (P1).
- Owns: `app/features/elements/chart/**`.
- Acceptance: 08 §19 criteria (J-S7 parts).
- As built: feature `charts` ships (native charts stay hidden as `nativeCharts`, P1).
  `features/elements/chart/` — `SlidesChartApi` (client of `slidesCharts`, installable fake),
  `ChartLinks` (checks on open/resume/5 min/present, derived statuses, maintenance writes for
  tokens, auto-update and first snapshots), `ChartCanvasMode` (link badge / *Update*, orbit drag,
  update morph), `chartSection` (Inspector › Chart), `showChartInsertDialog` (two steps, previews,
  MCP), `LinkedChartsPanel`, `ChartPaste` (snapshots on paste), `SlidesChartText` (shared
  measurer with deck fonts), chart toolbar; `commands/chart_commands.dart` (every 08 §14 command
  but the P1 native ones, plus `addCameraStep`, `copyAsImage`). `wonky_charts_flutter` gained
  `ChartView`, the data table dialog, `ChartTypeIcon` (moved), `ChartTooltip` and
  `ChartStyleEditor` (override mode); the stage draws 3D charts on the GPU backend. Details and
  leftovers: 08 §2.12, [STATUS.md](STATUS.md).

**SL-33 · PDF builds as pages, print frame option, PNG** (10 §11, §13)
- Owns: additions in `core/export/pdf/**`, `app/features/print/**`.
- Acceptance: page count = step count; *Show final animation state* (P1) option; PNG export P1.
- As built: features `printBuilds` and `imageExports` ship (the Markdown download is the hidden
  `markdownExport`, P2). Core (`lib/src/export/pdf/`): builds as pages print one page per step
  whose settled frame differs from the step before (`SlidesPdfExporter.printedSteps`,
  `SlidesPdfPlanner.select(buildSteps:)`), so page count = distinct steps; *Show final animation
  state* prints `finalFrame`; notes and handouts with builds print the final step; the painter
  applies settled frames like the stage (visibility, opacity, transforms, color changes, fill
  opacity, text parts with dimming/recolor/reveal, highlights); new `SlideFrameScenes` composes
  code states/steps and chart reveals/cameras per frame; code callouts, caret, selections, glyphs
  and gutter labels are drawn; charts default to `SlideChartLayout` with TTF metrics of the
  embedded chart font (server PDFs had placeholders). App (`features/print/`): the print
  preview's *Print each build stage* and *Show final animation state*; PNG export
  (`slides.file.download {format: png|pngZip}` → `showPngExportDialog`, `SlidesPngExport` on the
  stage's software renderer, `StoredZip`). Server PNG and *Copy slide as image* stay open.
  Details: 10 §11.3/§13 "As built (SL-33)", [STATUS.md](STATUS.md), `TODO.md`.

### 4.10 M10 wave 3 — views, Write switch, exit

**SL-34 · Outline view, Layers panel, accessibility checker** (04 §10, 03 §8, §17)
- Owns: `app/features/{outline_view,layers,accessibility}/**`.
- Acceptance: 04 AC-8 (outline part); checker rules unit-tested.
- As built: `app/features/outline_view/` (`OutlineView`, `OutlineBody` paragraph model with
  formatting-preserving text diffs, `OutlineController` focus/typing state,
  `OutlineSlideParts`), `app/features/layers/` (`LayersPanel` with the *Reading order* tab,
  `ElementNames`), `app/features/accessibility/` (pure-Dart `AccessibilityChecker` +
  `A11yFixes`, `AccessibilityPanel`), `commands/{outline,layers,accessibility}_commands.dart`;
  core additions `MoveElementsZ` (Layers drag in/out of element groups) and `SetReadingOrder`
  (`ops/parts/layer_ops.dart`, `planner/parts/layer_part.dart`) and `GroupSpace.toChild`.
  Features `outlineView`, `layers`, `accessibilityChecker` ship. Details: 04 §10, 03 §8.1 and
  §17.4 "As built (SL-34)", [STATUS.md](STATUS.md); leftovers in `TODO.md`.

**SL-35 · Write exports on the shared tokenizer** (07 §2.2, v2 review Q25)
- Owns: the code-highlighting call sites in `wonky_write_core/lib/src/export/**`.
- Acceptance: golden diff review of the Write export corpus (only token colors change); Write
  suites green.
- As built: every Write exporter (PDF and print, HTML, HTML zip, EPUB, DOCX, ODT, RTF)
  tokenizes through `SyntaxHighlighter.instance` (`wonky_write_core/lib/src/highlight/`):
  `DefaultCodeTokenizer` behind a 32-entry `CachedCodeTokenizer`, fence languages normalized
  (`CodeLanguages.normalize`); `SyntaxHighlighter.withTokenizer` (a zone value) lets tests
  compare tokenizers. The Write editor's style phase uses the same facade (07 §2.7 step 1), so
  highlight.js languages are highlighted on screen too. Two fixes the review needed: TextMate
  patch **SH-7** in `wonky_code` (captures located from the regex group tree instead of the
  first occurrence of their text — `function f` scoped the `f` of `function`; overlapping
  tokens would have duplicated code in HTML; `TextMateTokenizer` also clips overlaps) and PDF
  code wrapping independent of the token runs (`PdfLineBreaker`: a code word spans runs). The
  diff review is a test (`wonky_write_core/test/export/code_tokenizer_switch_test.dart`): a
  33-block corpus through all 9 exporters × 12 theme/appearance cases, highlight.js vs the
  shared tokenizer, equal after removing token styling. Not done: the 15 ms tokenizer budget
  and Write's language picker (`pickerLanguages`) — `TODO.md`. Details: [STATUS.md](STATUS.md).

**SL-36 · Templates 10 of 10, M10 integration and exit** — web-build token
- Owns: `server/templates/**`, integration tests and benchmarks for M10.
- Acceptance: the M10 exit gate of §1.
- As built (2026-10-15): **templates** — four more core decks in
  `packages/wonky_slides_core/lib/src/templates/decks/` (the server picks them up through
  `SlidesTemplates.all`; nothing template-specific changed on the server): *Quarterly review*
  (Classic), *Tech talk* (Midnight), *Product launch* (Studio), *Portfolio* (Paper) — nine decks,
  with *Blank* the gallery strip's ten (04 §15 "As built (SL-36)"); gallery order follows the
  strip. They showcase M10: builds (step-0 builds after the transition, one click per card/stat/
  milestone, paragraph builds with *dim*, `lineDraw`, `chartGrow` by series, `chartCamera`,
  `codeState` type-in, `codeHighlight` steps with callouts), transitions (cube, flip, doorway,
  revolve, push) and three Magic Move pairs (a code token morph, a device that moves aside, a
  project cover that opens into its page). Charts are **sample snapshots** (`source: static`)
  in the chart layout's placeholder — a template can't link to a spreadsheet the user doesn't
  have; *Relink…* links them, keeping frame, builds and camera. `TemplateDeckBuilder` gained
  `insert`/`lastElements`, `builds`, `transition`, `matchKey`, `codeStates`
  (`TemplateCodeState`: highlight, label, title, arrival mode and typing, callouts),
  `staticChart` (+ alt text), `TemplateShapes.shape/text(matchKey:)`; `decks/sample_charts.dart`
  (`sampleChart`), build helpers in `decks/parts.dart`. **Default transition of templates**
  (SL-30 leftover): `SlidesTemplate.defaultTransition` → `CreateDeck.defaultsJson` — every
  built-in carries one (fade; push for Product launch); the user's *Default transition* stays
  for blank decks (06 §5.7). Fixed while building them: the M9 Workshop description typo
  ("TemplateRun a…"), the Weekly update's statement subtitle alignment. **Bugs found and fixed
  (with regression tests):** (1) the *Statement* layout inherited the master body's bullets — a
  stray marker before every statement in the stage/thumbnails/editor (core `TextParagraphs` and
  the app's `effectiveList` now honor `listStyle: none` as a box default, the layout writes it
  via `PlaceholderDef.noList`; built-in theme hashes change, existing decks keep their copies);
  (2) the accessibility checker treated an ellipse's whole frame as its area, so the Pitch deck's
  orb gave a false contrast error (ellipse hit test); (3) on the web, code blocks were laid out
  with the fallback font when their mono family loaded after the first paint
  (`CodeScenePainter`'s paragraph cache now clears on `PaintingBinding.systemFonts`) —
  proportional code with gaps between the grid-placed runs in the editor and present mode.
  **Integration:** the full Slides suite and the shared packages were run (counts in
  [STATUS.md](STATUS.md)); the browser walkthrough of the release build and what wasn't verified
  are in the M10 exit checklist ([suite 14 §2.1](../14-roadmap.md)). Not built: the M10
  `integration_test` journeys J-S5…J-S7 (no chromedriver, as M9), the motion benchmark as a
  `-t slow` test with p95 frame timings in Chrome, scripted multi-client scenarios #18–20,
  23–25 — `TODO.md`.

### 4.11 M11 wave 1 — collaboration, history, MCP, remote

**SL-37 · Live collaboration** (09 §1–§2; schema S-3)
- Scope: live pointers, follow mode, follow presenter (followers in the presentation session),
  transform hints.
- Owns: `app/features/collab/**` (extends SL-21), S-3 model additions.
- Acceptance: 09 AC 4–6.
- As built: live pointers (cursor `pointer` in su, `CollabPointer`, 5 s idle, View toggle),
  canvas *surfaces* (masters-mode `surfaceId`), follow/jump into every view mode, *Watch
  presentation* in the follow banner, the follower view of a presentation session
  (`PresentView.follower`, `?view=follow`, role `follower`; `FollowerBar`; browse away +
  `slides.presence.returnToPresenter`), the Present button's live dot and *Follow Anna's
  presentation* menu item, `structure` hints with the navigator `StructureShimmer`, the 300 ms
  fade of released soft-lock outlines, outline-view claims and text hints, richer
  `ui.get_state` collaborators (agent cursors and flashes: SL-40/SL-42). Server: none needed (the follower role and agent
  presence existed). **S-3 not cut** — nothing synced was queued (02 §14.1); no migration.
  Acceptance note: AC 4–6 of 09 are comments/history/offline scenarios (SL-38/SL-39); SL-37
  was checked against 09 AC 1 and 3 (pointers, follow mode, following a presenter) with the
  collab rig and the presentation fake hub. Details: 09 §2.6, [STATUS.md](STATUS.md).

**SL-38 · Comments on slides and elements** (09 §3)
- Owns: `app/features/comments/**`; `CommentAnchorKind` additions in `platform/comments`.
- Acceptance: J-S8; anchors survive cut/paste re-anchoring.
- As built: `CommentAnchorKind.slide` / `.element` (enum stored by name — no migration);
  server change-log plugin `comments` (`slides/changelog/deck_comment_orphans.dart`:
  orphaning from `summaryJson.deleted`, revival from `revived`, reason `slide|element`) and
  notification extras `slideNumber`/`slideTitle` (`CommentService.payloadExtras`, deck cache);
  deck comment emails and the bell open `/slides/p/<uuid>?comment=`. App
  `features/comments/`: `SlidesCommentAnchor` (JSON of 09 §3.1), `SlidesComments`
  (`CommentAnchorProvider` + `CommentPanelOptions` + the new optional shell interface
  `CommentPanelSections` for group sections; open threads per slide, lazy slide-hint fix,
  next/previous, deep links), `CommentAnchorMoves` (cut & paste of elements and of slides
  re-anchors through `DeckEditorController.applyListeners` and the paste plans' new
  `elementIdMap`/`slideIdMap`), `CommentPinsLayer` (pins, hover cards, docked card, inline
  composer, active outline), `SlideCommentBadge` (navigator rows, collapsed groups, grid);
  `commands/comment_commands.dart` (`slides.comments.next/previous/openPanel/show`). Feature
  `comments` ships. Details: 09 §3.7 "As built (SL-38)", [STATUS.md](STATUS.md).

**SL-39 · Version history, overwritten-text review, activity** (09 §4–§6)
- Owns: `app/features/history/**`, `core/{snapshot,diff}/**`, `server/versions/**`.
- Acceptance: J-S9; restore is one undo step; `revertChange`/`reapplyChange` implemented.
- As built: core `package:wonky_slides_core/history.dart` — `SlidesSnapshotCodec` (09 §4.1
  format, gzip on `archive`, one codec for server and client), `SlidesVersionChanges` (who
  changed what, latest author last, agent authors), `SnapshotSlideEntry` (slide list),
  `DeckDiff` (slides/elements/groups/theme/deck, element kinds, roll-up, navigation stops),
  `TextDiff` (word LCS), `SlidesRestoreChanges` (row diff of a restore). Server
  `slides/versions/`: `SlidesVersionProvider` (registered in `server.dart`; capture → snapshot
  file + `SlidesSnapshotIndex`, attribution from the change-log receipts of the capture
  window; restore → `ServerSlidesWriter.applyRecorded`, 7-day record, `versionRestored`
  notice), `SlidesVersionEndpoint` (`changes`, `makeCopy` on `DeckCopies.copy(sourceModel:)`),
  `DeckChangeLogPruning` (30 days, daily job); migration `20261015115837413-slides-versions`.
  App `features/history/`: `SlidesVersionRenderer` in the shell's history route (restore =
  one `slides.serverChange` step through SL-43's handler), `SlidesVersionView` (navigator with
  badges and ghost rows, read-only stage with outlines, change list with inline text diffs,
  next/previous change, *Show removed*, PDF download, *Make a copy*; strip layout under
  720 px), `SlidesConflicts` + review dialog; `commands/history_commands.dart`. Activity:
  `slideIds` sets on edit events and a detail line in the shell feed. Feature
  `versionHistory` ships. Deviations and leftovers: 09 §4.7 "As built (SL-39)",
  [STATUS.md](STATUS.md), `TODO.md`.

**SL-40 · MCP headless tools** (11 §2–§4)
- Scope: `slides.*` tools, resources, prompts, `slides.export_pdf` with
  `refresh_linked_charts`; conditional: server-side chart auto-update index (08 §5.5) only if
  M10 telemetry shows stale decks.
- Owns: `wonky_core/lib/mcp/slides_tools.dart`, `server/mcp/**`, `core/markdown/**`.
- Acceptance: 11 §10 headless criteria; J-S10 headless part.
- As built: definitions `SlidesTools` (`wonky_core/lib/mcp/slides_tools.dart`, 47 tools incl.
  `drive.create_presentation`; `McpToolCatalog.slides`), core `package:wonky_slides_core/markdown.dart`
  (`lib/src/markdown/`: `SlidesMarkdownCodec` — Markdown ↔ body Delta, rich reads, `keepFormatting`,
  `concat`; `DeckOutlineCodec` — outline parse/write, layout inference), server
  `wonky_server/lib/src/slides/mcp/` (`SlidesMcp` addressing and errors, `SlidesWrites` +
  `DeckAgentPresence`, `SlidesInput`, `SlidesContent`, handlers `slides_{read,deck,element,media}_handlers.dart`,
  `SlidesToolHandlers.all`, `SlidesMcpContent` resources/prompts, `SlidesChanges` for `changes.revert`). One
  call = one change through the new additive `ServerHeadlessDeck.writeSteps` + `DeckSteps` (each operation
  planned against a scratch copy, row changes composed with `composeRowChanges`). `drive.export` of decks
  (pdf, md) and the per-deck write limit (`ToolExecutor` target key `deck`). Deviations: the handlers are
  five files, not `tools/*.dart`; overflow warnings use the core's approximate text metrics; P1 tools
  (`update_theme`, `copy_slides_to_deck`, native charts) and `code_walkthrough_from_diff` (needs
  `UnifiedDiff`/`WalkthroughBuilder`) are not built; `render_slide` answers `unsupported`; no tool/command
  row-parity tests (the tools use the same operations as the commands). Tests: core 28 (markdown), `wonky_core`
  5, server 29 ([STATUS.md](STATUS.md)).

**SL-41 · Phone remote, rehearse, same-browser fast path** (10 §5.2, §6.4, §10) — web-build token
- Owns: `app/features/present/{remote,rehearse,broadcast}/**`, `server/present/**` (pairing).
- Acceptance: 10 AC 9, 11; the fast path keeps a pair running through a 10 s connection drop.
- **On hold (user decision 2026-10-15).** Built and tested so far: server pairing keys and
  codes (`PresentationPairingUpdate`/`…Event`/`…Target`, `presentation.resolvePairingCode`,
  10 §6.6 "As built (SL-41, partial)") and the same-browser channel
  (`features/present/broadcast/`, not wired into `PresentationLink`). Not built: the phone
  remote UI, rehearse, the fast-path wiring, *Freeze audience*; the feature
  `remoteAndRehearse` stays off. What's left and how to resume: `TODO.md` (SL-41).

### 4.12 M11 wave 2 — UI bridge, AI, leftovers, exit

**SL-42 · UI bridge `ui.slides.*`** (11 §5)
- Owns: `wonky_core/lib/mcp/ui_slides_tools.dart`, `app/mcp/**`.
- Acceptance: J-S10 UI-bridge part; every dialog describable (04 AC-9).
- As built: 17 tools (`UiSlidesTools`, relayed by the server to `app: slides` windows;
  handlers `UiSlidesToolHandlers` in `wonky_slides/lib/mcp/ui_slides_tools.dart`): the 11 §5 set
  plus `set_view` (view mode, zoom), `close_panel`, `open_dialog` (runs a command as the user so it
  shows its dialog — Slides commands skip dialogs for agents) and `get_context_menu` (the 04 §11
  menus with command states, instead of a `menu` argument on the shared `ui.get_menu_tree`).
  Actions run through the dispatcher (source `mcp`), so roles and `SlidesFeatures` apply. Agent
  highlight: `SlidesAgentFlash` + `AgentFlashLayer` (violet outline + "✦ agent" tag, light/dark
  violet), fed by the tools and by `SlidesAgentWrites` (headless MCP/AI writes from the replica's
  `DeckChangeLog`, like Sheets' `ExternalAgentWrites`); `SlidesUiBridge` is attached by the editor
  screen and also registers the soft-lock popover as an MCP dialog (`SoftLockDialog`).
  `PanelDescriber` moved to `wonky_app` (Sheets re-uses it) with `under(key)` for the docked
  inspector. Dialog audit: all Slides custom dialogs were describable; fixed the soft-lock popover,
  the chart data table (`McpDialogScope`) and the shared shortcuts, spelling, personal dictionary,
  special characters and emoji dialogs (`McpDialogRegistration`). Tests: 52 app, 5 server relay,
  2 core, 2 `wonky_app` ([STATUS.md](STATUS.md)). Not built: flutter_driver runs against a live
  app (11 §11 *UI bridge*).

**SL-43 · AI in Slides** (11 §6–§8; Drive assistant P1)
- Owns: `server/ai/**`, `app/features/{ai,assistant}/**`, `wonky_drive/lib/features/assistant/` (P1).
- Acceptance: 11 §10 AI criteria with a fake provider; prompt-injection corpus (§7.8).
- As built: server `wonky_server/lib/src/slides/ai/` (`SlidesAssistantTarget` — the `slides.*` tools
  bound to the deck, `force` stripped, §8.1 confirmations via `SlidesAiGuard`, one composite change
  per Edit-mode run, Suggest-mode `SlidesShadow` as a `DeckOverlay` of the headless deck —,
  `SlidesContextBuilder`, `SlidesPrompts`, `SlidesAiService` + endpoint `slidesAi`), core
  `package:wonky_slides_core/ai.dart` (`AiOutline` → deck-outline Markdown, `DesignIdeasEngine`), app
  `wonky_slides/lib/features/{ai,assistant,undo}/` + `commands/ai_commands.dart` (assistant panel and
  adapter, Generate presentation, Rewrite, speaker notes, alt text incl. the Accessibility panel's
  *Generate with AI*, Design ideas, AI changes preview with before/after thumbnails; the shared
  `slides.serverChange` undo handler). Deviations: previews in the shared `ai_preview_record` (no
  `SlidesAiPreviewRecord` table); rewrite in a dialog instead of a canvas overlay; design ideas are
  theme layouts only; the Drive assistant (P1), code walkthrough, *Animate this slide* and §6.11 are
  not built; the injection corpus is §8.4's (the plan's "§7.8"). Details: 11 §6.12; tests: server
  18, core 10, app 34 ([STATUS.md](STATUS.md)).

**SL-44 · Remaining P1** (03 §14, emoji, image adjustments, curved connectors)
- Owns: `app/features/spellcheck/**`, additions in `app/features/elements/{image,line}/**`.
- Acceptance: spelling uses `wonky_spellcheck` + `wonky_app` glue; each item's spec criteria.
- As built: `app/features/spellcheck/` (`SlidesSpelling`, `EditorSpelling`,
  `SpellingCanvasLayer`, `SlidesSpellingSession`, `spelling_actions.dart`,
  `text_inserts.dart`), `commands/spelling_commands.dart` (check, toggle underline, replace,
  replace all, ignore, add to dictionary, personal dictionary, `slides.file.setLanguage`,
  `slides.insert.specialCharacter`; their placeholders are gone; feature `spelling` ships),
  `app/features/elements/image/image_adjust_preview.dart` (live slider preview),
  `app/features/elements/line/connector_handles.dart` + `commands/connector_commands.dart`
  (`slides.line.setWaypoints`; elbow segment and curved bend handles), core
  `ConnectorRouter.curveMidpoint` and curved routes bending through their first waypoint.
  Shared: the spelling dialogs, emoji picker and (moved from Write) special characters dialog of
  `wonky_app` read their strings from the shell ARB files and take an app key prefix (Write keeps
  `write.*`); `PersonalDictionary` (the synced list Write already used) in
  `package:wonky_app/spellcheck.dart`. Small hooks: `SlideTextEditAddon` (text overlay and
  notes), `SlideTextEditing.prepareContextMenu`, `NotesPane.contextMenuEntries`, outline line
  squiggles, `context.text.spelling` menu slot, `CanvasTokens.spellingError`; `slides.insert.emoji`
  types into text being edited; moving a line end clears edited waypoints. Details and
  deviations: 03 §14.1, [STATUS.md](STATUS.md).

**SL-45 · M11 integration and exit** — web-build token
- Acceptance: the M11 exit gate of §1.
- As built (2026-10-15): **Wonky Slides is complete for its first iteration.** Full test runs
  (counts in [STATUS.md](STATUS.md)), two timing-sensitive Slides tests made deterministic
  (`presentation_link_test` on `testWidgets`' fake clock instead of real delays;
  `notes_pane_test` failed under load because every editor screen loaded the real Hunspell
  dictionary — real asset I/O parsed in 8 ms real-time slices, one per frame, so
  `typeImeText`'s `pumpAndSettle` advanced a load-dependent amount of fake time and split one
  typing burst into two undo steps; `wonky_slides/test/flutter_test_config.dart` now starts every
  test without dictionaries, spelling tests install fakes). Sheets' `writer_perf_test` was
  already tagged `slow`. Browser walkthrough of the release build (Slides, then Write and Sheets
  for the shared fixes): suite 14 §2.1 "M11 exit checklist". **Bugs found and fixed (each with a
  regression test):** (1) long context menus ran off the bottom of the window — the shared
  `WonkyPopupMenuHost` now opens below, above or shifted to fit and scrolls menus taller than
  the window (all apps); (2) context-menu entries were built again after the menu took the
  keyboard focus, so Slides' spelling suggestions vanished — entries are built once per opening;
  (3) Slides' text editors (canvas overlay, notes) dropped their selection when the focus moved,
  so *Special characters* and *Emoji* typed nothing and the spelling menu lost its word — they
  keep it like Write (`clearSelectionWhen{EditorLosesFocus,ImeConnectionCloses}: false`);
  (4) *Comment* / *Comment on slide* in the context menus failed with "unknown property anchor"
  — `shell.comments.create` takes an `anchor` scope and providers may implement
  `CommentAnchorScopes` (Slides: `slide`, `element`), and a menu test validates every fixed menu
  argument against its command's schema; (5) undoing a delete or cut (and server reverts and
  version restores) didn't revive the comment threads the deletion orphaned — undo/redo writes
  and `ServerSlidesWriter.apply(revives:)` list re-inserted rows as `revived`; (6) comment
  system events read "Someone · orphaned" (raw enum names, no author) — localized sentences;
  (7) the reply box of the docked comment card wasn't focused when opened (autofocus loses to
  the focused card) — `MentionField` requests focus; (8) the version history route squeezed the
  preview to 40 px and its header overflowed by 448 px at 360 px — under 640 px the versions
  list sits under the preview and the header is compact (all apps); (9) emoji and arrows in slide
  text were drawn as empty boxes after a reload until something else re-laid them out — the
  font registry's generation also bumps when the engine's fonts change
  (`AssetFontRegistry.watchEngineFonts`, fallback fonts arrive after the first layout); (10) a
  selected connector's outline was the box around it (it read as a second, closed route) — the
  outline follows the route. Leftovers and what wasn't verified: `TODO.md` "Wonky Slides —
  later".

---

## 5. Contracts to stub first

Stubbed with fakes by SL-3 at the start of M9 (the shared kit already exists from Drive 05 D-6)
so the packages of §4 can start in parallel.
Names are binding unless changed via a contract PR.

### 5.1 Shared sync kit — pure Dart (extracted from Sheets)

*Superseded by RevLog (M13): the row types live in `wonky_revlog` ([17](../17-revlog-sync.md) part 3).*

Built by Drive 05 D-6 (`packages/wonky_sync_kit`); the signatures below are the implemented
ones (README of the package for the full list).

```dart
/// package:wonky_sync_kit/rows.dart (pure Dart; v2 review Q23)
enum RowOp { insert, update, delete }
final class RowChange {               // = Sheets' RowChange, moved
  final String table; final String rowId; final RowOp op;
  final Map<String, Object?> columnsBefore, columnsAfter;
  Set<String> get touchedColumns;  RowChange inverse();  toJson()/fromJson()
}
abstract interface class CurrentRowReader { Map<String, Object?>? currentColumns(String table, String rowId); }
abstract interface class ChangeSummary { Map<String, Object?> toJson(); }   // + JsonChangeSummary
final class MutationPlan<S extends ChangeSummary> {
  final String label; final S summary; final List<RowChange> changes;
  final Map<String, Object?>? detail; final List<String> warnings; final Map<String, Object?> result;
  static const chunkSize = 5000;  List<List<RowChange>> get chunks;  String get summaryJson;  String? get detailJson;
  MutationPlan<S> inverse({String? label});
}
/// Columns that must be skipped together by undo (02 P4).
abstract interface class CoupledColumns { Set<String>? groupOf(String table, String column); }   // + TableCoupledColumns
/// Table hook: inserts undone column by column (Sheets' cells).
abstract interface class ColumnwiseInserts { Set<String>? identityColumns(String table); }    // + TableColumnwiseInserts
abstract final class UndoInverter {
  static List<RowChange> invert(MutationPlan<ChangeSummary> plan, CurrentRowReader current,
      {CoupledColumns? coupled, ColumnwiseInserts? columnwise, SkippedColumn? skipped});
  static List<RowChange> invertChanges(List<RowChange> changes, CurrentRowReader current, {…same});
}
abstract interface class SyncTxAdapter {   // client writer (SyncWriter); server writers later
  Future<void> apply(MutationPlan<ChangeSummary> plan,
      {required String spaceId, required String actorKind, required String sessionId});
}
/// Remote patching: replica rows (+ pending local writes) → model changes.
abstract final class RowPatch {
  static List<RowChange> build(CurrentRowReader model, Map<String, Iterable<String>> changed,
      Map<String, Map<String, Map<String, Object?>>> rows, List<RowChange> pending, {required TableRank rank});
  static List<RowChange> reconcile(CurrentRowReader model, Iterable<(String, Map<String, Object?>)> modelRows,
      List<(String, Map<String, Object?>)> all, List<RowChange> pending, {required TableRank rank});
}

/// package:wonky_sync_kit/tables.dart — an app's synced tables (dependency order, model tables, root table)
final class SyncTableSet { SyncTableSet(List<AnySyncedTable> all, {Set<String> nonModelTables, String? rootTable}); int rank(String table); … }
// specs of the Slides tables: SyncedTableSpec<Deck>.of(Deck.t, Deck.fromJson) (wonky_sync_models/tables.dart)

/// package:wonky_sync_kit/undo.dart — the `*.rows` undo domain
class RowsUndoEntry extends UndoEntry { RowsUndoEntry(String domain, List<RowChange> changes, {String label}); … }
abstract interface class RowsUndoTarget { CurrentRowReader get currentRows; void applyChanges(List<RowChange>, {required String label, String actorKind}); }
abstract class RowsUndoHandler<E extends RowsUndoEntry> extends UndoHandler<E> { RowsUndoTarget get target; … }
```

Sheets keeps its cell-specific undo rule (Sheets 02 §7) as a table hook of the generic inverter
(`SheetsUndo.columnwise`); its `ChangeSummary` implements the kit interface and its
`MutationPlan` is `MutationPlan<ChangeSummary>` (a typedef in `wonky_sheets_core`, so a file
importing both `wonky_sheets_core` and `wonky_sync_kit` hides one of the two names). Slides
defines `SlidesChangeSummary` and `typedef SlidesPlan = MutationPlan<SlidesChangeSummary>`, and a
`slides.rows` `RowsUndoEntry`/`RowsUndoHandler` with `TableCoupledColumns` for P4.

### 5.2 Shared sync kit — client (`wonky_sync_kit_flutter`; extracted from `wonky_sheets/lib/features/sync/`)

*Superseded by RevLog (M13): `wonky_revlog_flutter` and `LoggedDeckSession` ([17](../17-revlog-sync.md) part 6).*

```dart
class SyncReplica {                     // per user + app (`SyncReplica.fileName('slides', userId)`)
  SyncReplica(OfflineSyncDatabaseSession session, {required UuidValue userUuid, required SyncTableSet tables});
  static Future<OfflineSyncDatabaseSession> openSession({client, path, userUuid, isDebugMode});
  Future<void> prepare();               // tuning + change journal triggers
  // spaces: spaceKey, roleOf, memberSpaces, hasRoot, rootIds, rowCounts, rowCountsBySpace,
  //         hiddenSpaces, purgeSpace(int key)
  // reservations: reservations, reservedSpaces, addReservations, usableReservations, removeReservation
  // dirty marks: markDirty, dirtySpaces, clearDirty;  rows: loadSpace, readRows;  clearAllTables
}
class ChangeJournal {                   // U11 trigger journal per open space
  Future<void> track(int spaceKey); Future<void> untrack(int spaceKey); Future<int> head();
  Future<JournalChanges> changesSince(int spaceKey, int after); Future<void> prune(int upTo);
}
abstract class SyncWriter implements SyncTxAdapter {   // chunking, columnValues, bulkWrite runs, dirty marks
  Future<void> write({spaceId, changes, plan, label, actorKind, sessionId, onProgress});
  Future<void> writeChangeLog(DatabaseSession s, ChangeLogEntry entry, Transaction tx);   // app hook
  ChangeSummary summarize(List<RowChange> changes);                                     // app hook
  Iterable<String> columnsIfVisible(RowChange change);                                  // app hook
}
abstract interface class SyncRemote { OfflineSyncClient get sync; reserveSpaces; subscribe; spaceStats;
  ensureSubscribed; unsubscribe; }      // EndpointSyncRemote on generated endpoint methods
class AppSyncController<R extends SyncReplica, W extends SyncWriter, S extends HostedSpaceSession>
    implements SyncSessionHost<R, W> {  // guard → syncOnce → reservations → syncContinuously; backoff;
  Stream<UuidValue> get merges;         //   pause when hidden; DeviceRowCap; weekly purge
  ValueNotifier<bool> connected; ValueNotifier<int> cycles; ValueNotifier<Object?> lastError;
  Future<UuidValue> createInReservedSpace(Future<void> Function(UuidValue space) create);
  @protected S registerSession(S session);
}
// Session building blocks (DeckSession mirrors SyncedWorkbookSession on them):
class SpaceWriteQueue { enqueue(changes, {plan, label, actorKind}); flush(); pendingOverlay; status({online}); }
class JournalIngestion { spaceKey; cursor; needsReload; Future<void> ingest(); }   // applyRows / reloadRows hooks
abstract final class SpaceOpening { waitForSpace(…); roleOf(AccessRole); roleFromMembership(…); }
// Lifecycle and shell glue:
abstract class ReplicaInstallation<R, C> { attach(); detach(); ready(timeout); reset(user); … }  // per signed-in user
class ReplicaOfflineProvider implements OfflineDataProvider { … }   // Settings › Offline & storage
class ShellSyncConnectivity implements SyncConnectivity { … }
abstract final class ReplicaRecoveryReader { static Future<List<RecoveredSpace>?> read(String path, SyncTableSet tables); }
abstract final class ReplicaFiles { path; delete; moveAside; }   Future<bool> offlineStorageLimited();
```

The local bookkeeping tables (`reserved_space`, `sheets_dirty_space`, `sheets_row_journal`,
`sheets_journal_space`) are `database: client` models present in every replica of the generated
client; each app's replica is its own file, so Slides reuses them as they are.

### 5.3 `DeckSession` (app, `features/model/deck_session.dart`)

```dart
sealed class DeckLoadState { const DeckLoadState(); }
final class DeckLoading extends DeckLoadState { final double? progress; final String? message; … }
final class DeckReady extends DeckLoadState { const DeckReady(); }
final class DeckUnavailable extends DeckLoadState { final String reason; final bool offline; … }

/// One open deck: the in-memory DeckModel built from the replica and the write path
/// (02 §11–12). Mirrors Sheets' WorkbookSession.
abstract class DeckSession {
  String get deckId;                       // = space UUID = drive item UUID
  UuidValue get itemUuid;
  String get userId;
  DeckModel get model;
  ValueListenable<DeckLoadState> get loadState;
  ValueListenable<SyncStatus> get syncStatus;
  ValueListenable<Role> get role;
  bool get canEdit => role.value >= Role.editor;

  SlidesPlanContext planContext();
  /// Plans [op], applies it to [model] synchronously and persists it asynchronously
  /// (≤ 5,000 changes per transaction + DeckChangeLog). Throws PlanException. No undo
  /// recording: the editor controller pushes a `slides.rows` step with the returned plan.
  MutationPlan execute(SlidesOperation op, {String actorKind = 'user'});
  void applyChanges(List<RowChange> changes, {required String label, String actorKind = 'user'});
  Future<void> flush();
  Stream<DeckChangeBatch> get remoteBatches;
  /// Image bytes/URLs: local bytes for pending uploads, signed URLs otherwise (cached).
  SlideImageResolver get images;
  Future<void> dispose();
}
// Implementations: SyncedDeckSession (replica), MemoryDeckSession (tests, version views,
// previews, AI suggest mode).
```

**As built (SL-3).**

- **Write path in core.** `package:wonky_slides_core/session.dart` holds the logic every
  session shares: the mixin `DeckWritePath` (`model`, `userId`, `planner`, `limits`, `ids`,
  `isOwner`; `planContext()`, `execute(op)` = plan → `checkPlan` → `model.applyPlan` →
  `persist`, `applyChanges`, `applyRemote(changes)` = `model.applyChanges(origin: remote)`,
  never persisted; it is the kit's `RowsUndoTarget`), the pure-Dart `MemoryDeck` (records
  `PersistedWrite`s; `onPersist` hook) and the undo domain: `slidesRowsDomain`,
  `SlidesRowsUndoEntry` (+ `fromJson`), `SlidesRowsUndoHandler(() => target, onPartial:)` with
  `SlidesUndoHooks.coupled/columnwise`; `slidesServerChangeDomain` is the name of the server
  domain (SL-39). The undo types live in core (Sheets keeps them in its app) so server, MCP and
  core tests share them.
- **App contract** (`wonky_slides/lib/features/model/`): `deck_session.dart` is the sketch
  above; `execute` returns `SlidesPlan` (= `MutationPlan<SlidesChangeSummary>`), the session
  `implements RowsUndoTarget` (`currentRows` = `model`), `images` is the core
  `SlideImageResolver` (`interfaces.dart`; `cachedBytes`/`bytes`/`url`,
  `MemorySlideImageResolver`). `memory_deck_session.dart`: `DeckSessionBase extends DeckSession
  with DeckWritePath` (notifiers `loadStateNotifier`/`syncStatusNotifier`, `roleValue`,
  `remoteBatches` = remote batches of `model.changes`, `checkPlan` refuses non-editors with
  `PlanException(permission)`, `dispose` flushes and disposes the model) and
  `MemoryDeckSession` (`persisted`, `persistedLabels`; `MemoryDeckSession.blank(planner: …)`
  runs `CreateDeck`). The planner is a constructor argument until SL-7 ships the default.
- **What `SyncedDeckSession` (SL-9) needs**: extend `DeckSessionBase`; override
  `persist(changes, plan:, label:, actorKind:)` to enqueue into the kit's `SpaceWriteQueue`
  (`SlidesWriter` = `SyncWriter` with `summarize` → `SlidesChangeSummary.of(changes, current:
  model)`, `writeChangeLog` → `DeckChangeLog`, `columnsIfVisible`), and `flush()`; open with
  `SpaceOpening.waitForSpace`, load rows of `SlidesTableSet.tables.modelTables` into
  `DeckModel.fromRows`/`applyChanges(origin: load)`, set `loadStateNotifier` (`DeckLoading`
  with progress → `DeckReady`/`DeckUnavailable`), map the space role to `roleValue`, mirror
  `SyncStatus` from the queue, and feed `JournalIngestion` results through `applyRemote`
  (pending local writes overlaid by `RowPatch.build` with `rank: SlidesTables.rank`).
- **Harness** (`wonky_slides/test/harness/deck_harness.dart`): `DeckHarness.open({role,
  fixture, planner})` = SL-1's `slidesHarness()` + a `MemoryDeckSession` over a `DeckBuilder`
  fixture + an active `HarnessDeckDocument` (the `slides.rows` handler; SL-11's
  `DeckDocumentController` replaces it); `registerOp(id, op, argsSchema:)` registers an
  undoable command that executes the op and records a `SlidesRowsUndoEntry` — the pattern of
  every Slides command; `run`/`undo`/`redo`/`undoLabels`.
- **Model API** (`package:wonky_slides_core/model.dart`, `core/model/api/`): map-backed
  immutable records per table (`DeckRec`, `DeckThemeRec`, `SlideMasterRec`, `SlideLayoutRec`,
  `SlideGroupRec`, `SlideRec`, `SlideElementRec`, `SlideTableAxisRec`, `SlideTableCellRec`,
  `SlideBuildRec`, `CodeStateRec`, `ChartLinkRec`, `GenericSlidesRecord`) holding the full row
  (missing columns null) with typed getters and core enums (`ElementKind`, `SlideBuildKind`,
  `SlideBuildTrigger`, `TableAxisDimension`, `ElementOwnerKind`; placeholder types and
  appearance reuse SL-6's `SlidePlaceholderType`/`SlideAppearance`); `DeckReader`
  (`CurrentRowReader` + typed lookups, `themes`, `defaultTheme`, `mastersOf`, `layoutsOf`,
  `groups`, flattened `slides` with orphans last, `slidesInGroup`, `elementsOf(owner,
  parentId:)`, `allElementsOf`, `axesOf`, `cellsOf`, `buildsOf`, `codeStatesOf`,
  `chartLinkOf`); `DeckModel` (`fromRows`, `applyChanges(changes, origin:, silent:)`,
  `applyPlan`, synchronous `changes` stream + `addListener`, `version`, canonical `dump()`)
  with parent-bucket indexes; events `DeckChanged`, `SlidesChanged`, `OrderChanged`,
  `ElementsChanged` (dependent rows report their element), `ThemeChanged` (layout/master
  elements too), `BuildsChanged`, `OtherRowsChanged` in a `DeckChangeBatch` with
  `DeckChangeOrigin {local, remote, load}`; no-op writes emit nothing. SL-7 adds `SlideOrder`,
  `ElementTree`, `PlaceholderIndex`, resolvers behind this API.
- **Operations** (`ops.dart`): every op of 02 §12.1 plus `CreateDeck` (02 §9.3), master/layout
  CRUD named `AddMaster`, `AddLayout`, `UpdateMasterOrLayout`, `DeleteMastersOrLayouts`; nullable
  columns are set through `Patch<T>` (`null` = unchanged, `Patch(null)` = clear); targets
  `TopLevel`/`InGroup` (`SlideTarget`) and `ElementText`/`CellText`/`NotesText`
  (`TextTarget`). `SlidesMutationPlanner` is an interface (`plan(op, DeckModel, ctx)`); SL-7
  implements it. Until then `FakeSlidesPlanner` (`testing.dart`) plans `CreateDeck`,
  `SetDeckProps`, `AddSlides`, `DeleteSlides`, `MoveSlides`, `SetSlideProps`, `CreateGroup`,
  `InsertElements`, `UpdateFrames`, `SetElementProps`, `DeleteElements`, `SetText`, `SetCells`
  and refuses the rest with `PlanException(unsupported)`.

### 5.4 Element renderer API

- `ElementKindHandler` (app, 03 §1.3) registry.
- Core scene (`wonky_slides_core/lib/src/scene/`):

```dart
sealed class SceneNode { String? get elementId; }
final class SGroup extends SceneNode { Matrix4 transform; double opacity; SClip? clip; List<SceneNode> children; }
final class SPath extends SceneNode { ScenePath path; SFill? fill; SStroke? stroke; SEffects? effects; }
final class SImage extends SceneNode { SlideImageRef image; Rect src; Rect dst; List<double>? colorMatrix; ScenePath? mask; }
final class SText extends SceneNode { TextLayoutResult layout; }        // positioned lines and runs
final class SChart extends SceneNode { ChartScene scene; }              // wonky_charts (08)
final class SCode extends SceneNode { CodeScene scene; }                // wonky_code (07)
final class SPrompt extends SceneNode { String text; Rect box; }        // editor only

abstract interface class TextLayoutEngine {
  TextLayoutResult layout(TextBody body, ResolvedTextStyles styles,
      {required double width, double scale = 1});
}
// Implementations: FlutterTextLayoutEngine (app, dart:ui Paragraph) and SlideTextLayout
// (core, pdf-package metrics; server/headless). Client PDF export passes the Flutter layout
// results to the PDF writer so client PDFs match the screen exactly (10).
```

**As built (SL-3).** `package:wonky_slides_core/scene.dart` (`core/scene/nodes/`). The nodes
are named `GroupNode`, `PathNode`, `ImageNode`, `TextNode`, `ChartNode`, `CodeNode`,
`PromptNode` (not `SGroup`, … — `wonky_charts` exports `SGroup`/`SPath`/`SText`/`SClip`/
`SStroke`, and the scene builder and PDF renderer import both); `GroupNode.transform` is a
`vector_math_64` `Matrix4` (the same type as Flutter's), fills are SL-6's `ResolvedFill`,
strokes `NodeStroke` (chart engine `SStrokeCap`/`SStrokeJoin`, arrowheads), effects
`NodeEffects`/`NodeShadow`, clips `NodeClip`, images `SlideImageRef` (`wonky-file://<uuid>` or
a proxied URL). `ScenePath` wraps the chart engine's `PathCmd`s (re-exported with
`PathBuilder`), so path code is shared. `SlideScene {slideId, width, height, background:
ResolvedBackground, nodes}` with `nodesOf(elementId)`. `SceneContext {theme: ResolvedTheme,
textLayout, editing}`. Text: `TextBody` (Delta ops; `fromJson`, `plain`, `plainText`),
`ResolvedTextStyles {styles, defaultStyle, box: BoxTextStyle?}`, `TextLayoutResult {width,
height, lines: [TextLineBox {runs: [TextRunBox]}], fitScale, overflows, lineBreaks}`.
`CodeScene` (lines of colored runs, 07) is a stub SL-26 fills. `ElementKindHandler` +
`ElementKindRegistry` are in the app (`features/elements/element_kind_handler.dart`) as in 03
§1.3, with `HandleSpec`, `SnapPoint`, `ElementActivation`, `EditingTarget`; deviations:
`hitTest` takes a Flutter `Offset`, `inspectorSections(selection)` returns section **ids** of
SL-11's registry (no `BuildContext`), `ElementSelection` is a `List<ResolvedElement>`, and
`snapPoints` defaults to the frame corners and center. `ResolvedElement` (`model.dart`) is a
stub with `record`, effective `frame`, `rotation`, flips, `opacity`, `inherited`,
`children`; SL-7 adds the resolved styles.

### 5.5 Timeline API (owned by 06 §9)

`SlideTimelineCompiler.compile(SlideMotionInput) → SlideTimeline` (`initial`, `endOfStep`,
`frameAt`, `finalFrame`, `printFrame`), `TransitionCompiler` / `MagicMoveMatcher` →
`TransitionPlan`, `SlideFrame`/`ElementVisualState` consumed by `SlideStage`. M9 stub: every
slide compiles to zero steps; `printFrame` = edit frame.

**As built (SL-3).** `package:wonky_slides_core/motion.dart` (`core/motion/stub/timeline.dart`):
`SlideTimeline` (`steps` = `[step 0]`, `stepCount` 0, every frame `SlideFrame.edit`,
`describe()`), `TimelinePosition`, `TimelineStep`, `ScheduledEffect`, `TimelineWarning`,
`SlideFrame` (`stateOf(id)`), `ElementVisualState` (subset of 06 §9.2: `visible`, `opacity`,
`transform` `Matrix4`, `blurSigma`, `drawProgress`, code state/step), `SlideMotionInput {slide,
builds}`, `SlideTimelineCompiler.compile` and `TransitionCompiler.compile` →
`TransitionPlan.cut`. SL-24/SL-25 replace the compilers and extend the types (`motion/`).

**As built (SL-24).** The timeline compiler and frames are real (06 §9.8); the type names of the
stub stay and its constructors keep compiling (`SlideMotionInput(slide:, builds:)`,
`SlideTimeline(slideId:, steps:)` = program-less fake, `ElementVisualState(...)`). Consumers
should build the input with `SlideMotionInput.fromDeck(model, slideId, resolved:, scene:)` so
transforms are about the elements' centers and part boxes come from the text layout (the PDF
exporter does; present mode, SL-19, still uses the plain constructor). Player rules for SL-29:
`frameAt(step, ms)` for `ms ≥ step.durationMs` is the settled `endOfStep(step)` unless
`step.hasLoops` (an `untilNextClick` emphasis keeps cycling until the next step);
`endOfStep(-1)` = `initial`. `TransitionSpec` (codec, catalog, `advance`) is in
`builds/transition_spec.dart`.

**As built (SL-25).** The stub is gone: `TransitionCompiler.compile(from:, to:, {transitionJson |
spec, options, fromSlide, toSlide})` / `TransitionCompiler.between(deck, fromSlideId:,
toSlideId:, …)` → `TransitionPlan` (`frameAt(ms)` → `TransitionFrame`: snapshot quads or a
`MagicMoveFrame` with both slides' `SlideFrame`s), `MagicMoveMatcher`, `MagicMovePlan`
(06 §9.9). The old public `TransitionPlan` constructor and the `const TransitionPlan.cut` became
a private constructor and a `final` cut plan (no consumers outside the core).

**SL-31 additions.** `SlideMotionInput.fromDeck` gives code elements `codeTimings`
(`ModelCodeMotionTimings` over a lazily built `CodeElementModel`): `codeType` lasts
`typeInDurationMs()`, `codeState` the change's `transitionDurationMs(from, to, mode)` (typed
changes derived, morph = the state's morph settings, instant = the 200 ms crossfade); inputs
built without it keep the estimates. `MotionCodeState.stepsOf` counts with
`HighlightSteps.count` (empty "show all" steps kept, 07 §4.1). Frames map to code scenes with
the app's `CodeFrames.sceneOf`/`applyFrame` (`features/elements/code/code_frames.dart`).

### 5.6 Code and charts

- `CodeElementModel` (07): states, highlight steps, `CodeScene build(state, step, size)`, type-in
  plan from `wonky_core` diff (`SequenceDiff`).
- `ChartLinkService` (08): `link(spreadsheetItemUuid, chartObjectId) → snapshot`,
  `status(links) → {stale, sourceVersion}`, `update(elementId)`.

### 5.7 Server

*The change-log consumer and writer contracts are superseded by RevLog (M13): hooks of
`SlidesRevBinding` and `SlidesServerWrites` (02 §3.10, §12.2).*

```dart
abstract interface class DeckChangeLogConsumer {   // registered plugins: drive mirror, activity,
  String get id;                                   // orphaning, versions, agent cursors, headless cache
  Future<void> consume(Session session, UuidValue deckSpace, List<DeckChangeLogRow> rows);
}
abstract interface class HeadlessDeckProvider { Future<HeadlessDeck> open(UuidValue deckSpace); }
abstract interface class SlidesPdfRenderer {        // core; options per 10
  Stream<List<int>> render(DeckModel deck, SlidesPdfOptions options, FontProvider fonts, ImageProvider images);
}
```

**As built (SL-3).** `package:wonky_slides_core/interfaces.dart` (pure Dart, `core/interfaces/`):
`SlidesPdfRenderer.render(DeckModel, SlidesPdfOptions, SlidesExportResources) →
Future<SlidesPdfResult {bytes, pageCount, warnings}>` (10 §11.3's shape; the options carry
every field of 10 §11.1 — named `Slides…` because Write exports `PdfExportOptions`;
resources = `FontProvider` (`wonky_fonts`), `SlideImageResolver`, optional
`TextLayoutEngine` and `lineBreakHints`). The server contracts are generic over the server's
context so core stays free of Serverpod: `DeckChangeLogConsumer<C>` (`id`, `consume(C context,
String deckId, List<DeckChangeLogEntry> rows)`; `DeckChangeLogEntry` = the row as plain
values), `HeadlessDeck {model, execute(op, actorKind: 'mcp') → Future<SlidesPlan>}` and
`HeadlessDeckProvider<C>.open(C context, String deckId)`; the server binds `C` = `Session`
(SL-5, SL-8).

As built (SL-5): the core contract is generic (`DeckChangeLogConsumer<C>` with
`consume(C, String deckId, List<DeckChangeLogEntry>)`); the server binds
`C = DeckConsumerContext` (session, the deck's `DriveItem`, `actorOf(entry)`) and registers
plugins with `DeckChangeLogProcessor.register` (ids `drive`, `activity`, `storage`; later
`comments`, `versions`, `agents`, `headless`).

---

## 6. Risks

| # | Risk | Likelihood | Impact | Mitigation | Owner |
|---|------|-----------|--------|------------|-------|
| R1 | Extracting the shared sync kit destabilizes Sheets | Medium | High | Done in M8 (Drive 05 D-6) behind Sheets' full test + harness suites; pure moves, no behavior change | D-6 |
| R2 | One-replica-per-app downloads every space kind (02 §9.2) | Low (OS-8 in M8) | High | OS-8 space filter (Drive 05 D-4) before the first deck space; fallback: Slides active set limited to recently opened decks | D-4, SL-5 |
| R3 | Text LWW loses concurrent edits | Medium | Medium | Soft locks + live hints + overwritten-text review; recovery-offer metric; three-way merge ready as P2 (Q18) | SL-21, SL-39 |
| R4 | Editor overlay vs static text rendering mismatch (line breaks, auto-fit) | Medium | High | One `TextLayoutEngine` for static + overlay metrics; golden equality tests; spike SL-4 first | SL-4, SL-10, SL-13 |
| R5 | Screen vs server PDF layout differences (pdf metrics vs Flutter) | Medium | Medium | Client PDFs reuse Flutter layout results; server PDFs accept ≤ 1-line differences; tests flag diffs | SL-20 |
| R6 | Fonts: bundle size (display families) and PDF embedding | Medium | Medium | Deferred asset loading per family; subset in PDF; `wonky_fonts` assets cached by the browser across apps (same origin) | SL-6 |
| R7 | Lock-step synced schema releases span Sheets and Slides | Medium | Medium | Front-load S-1; batch S-2/S-3; recovery export | SL-2, SL-24, SL-37 |
| R8 | Motion performance on web (3D transitions, Magic Move of many text glyphs) | Medium | High | 06 budgets, prefetch plans, fallbacks under reduced motion, `flutter_scene` only where needed | SL-29 |
| R9 | Cross-deck paste of large groups (files, quota, offline) | Medium | Medium | Async re-homing queue, quota pre-check, placeholders while pending | SL-18 |
| R10 | Many parallel agents editing shared files; 16 GB laptop | Medium | Medium | Ownership table, registration indexes owned by SL-11, ≤ 5 agents, one web-build token (§2) | all |
| R11 | Laptop + projector without a second window is less convenient | High | Medium | Presenter view in this window + audience in a second browser or device via the session (one banner click); P1 same-browser fast path (SL-41); a presenting-only second window stays a possible later addition (10 §5.3) | SL-19, SL-41 |
| R12 | Linked chart data leakage/staleness | Low | Medium | Snapshot contains only resolved series; access-checked updates; stale badge; server auto-update only if needed (Q28) | SL-27, SL-32 |

---

## 7. Testing strategy

Follow suite [15](../15-writing-tests.md) (layout, naming, helpers, determinism, tags).

### 7.1 Unit (pure Dart)
`wonky_slides_core` ≥ 90 % line coverage on logic folders: ids, model ingestion, resolvers,
planner ops, inverter coupled columns, maintenance rules, copier/remapping, clipboard codec, text
schema, snapping, geometry, connectors, auto-fit, theme validation/resolution, layout remap,
size scaling, snapshot codec, diff, timeline (06), code diff/type-in (07), chart snapshot (08),
PDF structure (10).

### 7.2 Command tests
Every command: execute → undo → redo equality (model state + selection) headless on a
`MemoryDeckSession` via `CommandTestHarness` (`wonky_slides/test/harness/`), plus the
permission matrix per role (`forEachRole`).

### 7.3 Multi-client sync harness
*With RevLog (M13) the clients run against `FakeRevServer` / `FakeRevHub` ([17](../17-revlog-sync.md) As built 16).*
As Sheets 13 §7.3: server (`serverpod_test` with the offline-sync engine) + N clients in isolates
with their own replicas, `DeckModel`s, writers and undo stacks.
- **Scripted**: every row of [09 §6.4](09-collaboration-history.md) and 06 §11 / 07 / 08
  concurrency tables.
- **Property**: random sequences (slide add/move/delete/duplicate, group create/move/ungroup/
  delete, element insert/move/resize/style/text/group/ungroup/delete, layout apply, theme apply,
  table axes/cells, builds, undo/redo) on 2–4 clients with random online/offline toggles.
  Invariants after full sync: replicas identical (canonical dump); 02 §10 invariants hold after
  maintenance; every slide reachable in the flattened order exactly once; no torn
  `groupId`/`sortKey` pairs; undo of client A never changes a column last written by B.
- Seeds recorded, failures shrink, nightly long runs.

### 7.4 Goldens
Built-in themes × layouts × appearances (thumbnail size), every shape geometry, text styles and
lists, tables, images (crop/mask/adjust), selection chrome and guides, navigator (groups
expanded/collapsed/skipped/colored, light/dark chrome), inspector sections, dialogs. CI Linux,
bundled fonts only.

### 7.5 Performance
Fixtures: 50, 200, 1,000-slide decks (40 elements/slide, images, tables). Metrics of 03 §18 and
06 §14; open from replica, cold sync, thumbnail generation, paste 50 slides across decks, PDF of
200 slides (web client, server). Nightly; > 10 % regression fails.

### 7.6 Integration (flutter_driver, via the serverpod MCP and the UI bridge)

| Journey | Steps |
|---------|-------|
| J-S1 | Create deck from template → edit title → add slides with layouts → group 3 slides (⌘G) → rename/color/collapse group → reorder by drag → present from start → presenter view with the audience in a second browser → exit |
| J-S2 | Insert image (upload), shape with text, connector between shapes, table; align/distribute; undo/redo everything |
| J-S3 | Two browsers (two users): soft lock + Edit anyway; group moved in one appears in the other; offline edit + reconnect |
| J-S4 | Copy a group from deck A, paste into deck B (keep source formatting); export PDF with notes pages |
| J-S5 | Builds by bullet + Magic Move between duplicated slides; preview; present through steps |
| J-S6 | Code block with 3 states, highlight steps, type-in while presenting |
| J-S7 | Insert linked chart from a spreadsheet; edit data in Sheets; *Update* in Slides; 3D camera build |
| J-S8 | Comment on an element with @mention; reply; resolve; deep link |
| J-S9 | Version history: view diff, restore, undo restore |
| J-S10 | MCP: create a deck headlessly, add slides/elements, export PDF; UI bridge: navigate and invoke commands |

### 7.7 PDF validation
Reference decks rendered to PDF (client and server); pages rasterized (pdfium/`pdftoppm` in CI) and
compared with the canvas goldens (tolerance); text extractable and in reading order; fonts
embedded; bookmarks = groups.

### 7.8 Security
Permission matrix for commands, endpoints and MCP tools per role; file re-homing checks
(`copyToItem` refuses files of items the caller can't read); image proxy SSRF matrix (suite 13);
linked-chart snapshots never leak spreadsheet data beyond the chart's resolved series; prompt
injection corpus for AI tools.

---

## 8. Decisions index (v2 review)

| # | Question | Where | Decision |
|---|----------|-------|----------|
| Q18 | Finer-grained concurrent text merging | 02 §4.5 | Soft lock + LWW in v1; three-way merge on receive as P2 |
| Q19 | Replica syncing every space kind | 02 §9.2 | Vendored OS-8 space filter per sync endpoint (M8, Drive 05 D-4) |
| Q20 | super_editor vs lighter rich-text editor | 03 §6.1 | super_editor overlay, confirmed by spike SL-4 |
| Q21 | Inspector docked vs side panel (Animate UI placement) | 04 §7.1 | Docked inspector hosting 06's Animate UI as a tab; `slides.panel.animate` is an alias |
| Q22 | Nested slide groups | 04 §5.12 | One level in v1; `parentId` reserved |
| Q23 | Shared package names | suite 01 §2.1 | `wonky_sync_kit` + `wonky_sync_kit_flutter`, `wonky_fonts`, `wonky_spellcheck` (+ glue in `wonky_app`) |
| Q24 | Print frame of animated slides | 06 §9.6 | Authored layout + completed content; *Show final animation state* option (P1) |
| Q25–Q26 | Write exports on TextMate; copy vs upstream split | 07 §2.2 | Switch in M10 (SL-35); copy the engine now (D-2) |
| Q27 | Number formats outside Sheets | 08 §2.5 | Extract `wonky_numfmt` (D-3) |
| Q28 | Linked chart auto-update | 08 §5.5 | Client-side in M10; server index in M11 only if needed |
| Q5/Q29/Q30 | Presenter view windows, desktop multi-window | 10 §5.2–§5.3 | Single window: presenter view here, audience on another device or browser; desktop multi-window deferred |

---

## 9. Definition of done (every work item)

- Code only in the owned folders; contracts unchanged or changed via an approved contract PR.
- Commands registered with stable ids (04 registry), args schema, titles, icons, shortcuts,
  menu/toolbar/context entries; execute/undo/redo tests; `ui.invoke_command` works.
- Synced writes name their columns (lint green); coupled columns written together; `DeckChangeLog`
  rows with correct `actorKind`, labels and summaries (deleted/revived lists).
- Web only: no desktop-specific code paths (suite 01 A13); no code opens a window or tab
  (suite 03 §1).
- Light and dark app chrome verified; slides render identically regardless of app theme; no
  overflow at 360 px for panels/dialogs.
- Keyboard operable; semantics labels; announcements where specified; reduced motion honored.
- Offline behavior as specified and covered by the harness when it touches synced data.
- MCP coverage where required (11), with integration tests.
- Unit, command, widget, golden and integration tests added; perf budgets measured where listed.
- Spec updated in the same change when behavior differs; `dart analyze` clean, `dart format`,
  dependency-rule check passes; `AGENTS.md` updated when apps/ports/driver entry points change
  (Slides: `wonky_slides/lib/driver.dart`, `flutter_apps` alias `slides`, web port 8104,
  release build `flutter build web --wasm --base-href /slides/ --output ../wonky_server/web/slides`).
