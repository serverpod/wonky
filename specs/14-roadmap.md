# 14 · Roadmap, Milestones and Parallel Workstreams

This is the suite-level plan. App-level breakdowns:
[Write implementation plan](wonky_write/10-implementation-plan.md),
[Sheets implementation plan](wonky_sheets/13-implementation-plan.md),
(v2) [Drive implementation plan](wonky_drive/05-implementation-plan.md),
[Slides implementation plan](wonky_slides/12-implementation-plan.md).

**Status (v2 planning, 2026-10):** M0–M7 delivered the first iteration of Write (complete) and
Sheets (complete for its first iteration, `wonky_sheets/STATUS.md`; deferred work in
`TODO.md`). The second iteration adds Wonky Drive, Wonky Slides and suite changes in
milestones **M8–M11** (§2.1), decided in the [v2 review](v2-review.md) and planned as **work
packages** for parallel agents (§2.2). **v2 is web only**: desktop builds keep compiling, desktop
features are deferred ([01 A13](01-architecture.md)). M12 (Bugs & improvements, §2.1a) and M13
(RevLog sync for Sheets and Slides, §2.1b) are built.

## 1. Principles
- **Contract first**: each workstream starts by committing its public Dart interfaces (and
  Serverpod models/endpoint signatures) with stub implementations, so dependent workstreams can
  proceed in parallel.
- **Vertical slices**: every milestone ends with working, demoable software (M0–M7: web and
  macOS; v2 milestones M8–M11: web).
- **Ownership by folder/package** (see 01 §2–§4) to minimize merge conflicts; shared files
  (`server.dart`, command registration lists, `MenuSpec` trees, route tables) are edited only
  via small additive registrations.
- **Definition of done** (every task): analyzer clean, formatted, tests (unit + command
  undo/redo + MCP tool where relevant), light/dark verified, keyboard operable, strings
  externalized, docs/spec updated if behavior changed.

## 2. Milestones

| Milestone | Goal | Exit criteria |
|-----------|------|---------------|
| **M0 · Foundations** | Restructure repo (01 §2 M0 steps): `wonky_write`/`wonky_sheets` join the workspace and are wired to `wonky_server` (client bootstrap ported from the template `wonky_flutter`, which is then deleted), `packages/*` scaffolded; root workspace; CI (analyze, format, test, dependency-rule check, sync-update lint); `wonky_ui` theme + first custom widgets; command registry + undo service skeleton; MCP route spike (`mcp_dart` behind Relic); `third_party/` vendoring set up (§2.3 of 01: root overrides, `VENDORED.md`/`PATCHES.md`, CI running vendored tests) with `super_editor` and `serverpod_offline_sync` copied in; offline-sync module wired (`generator.yaml`: `shared_packages: [../wonky_sync_models]`, module `serverpod_offline_sync` nickname `offline_sync`, `experimental_features: databaseSync: true`; vendored patch if needed); web builds for both apps served by `wonky_server` at `/write/` and `/sheets/` with shared cookie sign-in (01 §2.4–§2.5). | Both apps boot (web + macOS), sign in works and carries over between the two apps, `/mcp` answers `tools/list`, sync session opens with an empty space. |
| **M1 · Shell & Drive** | Auth screens, settings (appearance, keyboard, developer tokens), drive (home, folders, recent, starred, trash, search, templates skeleton), sharing dialog + ACL, presence roster, notifications basics, command palette, quick switcher, offline drive cache. | Journeys 1 (partially) and drive CRUD; drive MCP tools pass. |
| **M2 · Write MVP** | Delta schema + Markdown codec; editor integration (mapper, applier, extractor); OT server + client; offline outbox; collaborative undo; core formatting/blocks; menus/toolbar/status bar; Markdown import/export; default theme rendering. | Journeys 1–3 (Write parts). OT fuzzer green. |
| **M3 · Sheets MVP** | Sync models + writer + active-set subscriptions + reserved spaces; WorkbookModel; grid rendering & editing; clipboard & fill; formula engine with ~150 P0 functions; basic formatting & number formats; undo; CSV import/export; 1M-cell perf gate. | Journeys 3–4 (Sheets parts); offline merge fuzzer green; perf gate passed. |
| **M4 · Collaboration** | Comments (both apps), suggestions (Write), remote cursors (both), version history (both), cell edit history, activity dashboard (UI later removed; server kept, 07 §6), share/role changes live, access requests, email notifications. | Journeys 2, 5, 6. |
| **M5 · Depth** | Write: themes + theme editor, tables editor, images, find/replace, outline, page setup, PDF/HTML/DOCX/ODT/RTF/EPUB/TXT export, print preview. Sheets: full formatting, CF, DV, filters/filter views/slicers, pivots, charts, named/protected ranges, data tools, XLSX/ODS/PDF/HTML export & XLSX/ODS import, print. Functions to ~400. | Journeys 7, 9; export validation CI green. |
| **M6 · Agents & Automation** | Complete MCP tool catalogs (headless + UI bridge) for both apps; AI assistant panels & inline AI; Sheets scripting (compile service, runtimes, bridge, editor, triggers, macros). | Journeys 8, 10; MCP integration suite green. |
| **M7 · Polish & Scale** | Accessibility audit, i18n readiness (pseudo-locales), performance tuning, bundle splitting, error reporting, security review, raise Sheets cell limits as upstream U1–U5 land, desktop packaging (macOS/Windows/Linux; not done — deferred with all desktop features, 01 A13). | All budgets in 11 §2 met; a11y checklist complete. |

> **History.** M0, M3 and M7 describe the original Sheets sync on the vendored
> `serverpod_offline_sync` engine (module setup, reserved spaces, active-set subscriptions, the
> sync-update lint, raising cell limits as upstream requirements U1–U5 land). M13 (§2.1b)
> replaced that stack with RevLog ([17](17-revlog-sync.md)); the rows are kept as history.

### 2.1 Second iteration (v2)

Scope rules for all four milestones: **web only** (01 A13 — the desktop targets must still
compile, nothing desktop-specific is built: no native menubar, desktop binaries/URL schemes,
packaging, multi-window or native drag-and-drop); **single window** everywhere, also when
presenting (03 §1); the site root `/` lands on **Wonky Write's home** (01 §2.4).

| Milestone | Goal | Exit criteria |
|-----------|------|---------------|
| **M8 · Drive + suite changes** ([Drive 05](wonky_drive/05-implementation-plan.md), D-1…D-18 + Slides SL-1) | `wonky_drive` app at `/drive/`; root `/` → `/write/`; unified drive with kinds `presentation` (model + `registerPresentation`) and `file`; uploads (queue, offline, whole-file retry), MIME sniffing, previews (image, PDF, text/code), *Open with*, downloads; **50 MB quota** (accounting, enforcement on every byte-adding path, meters, banners, dialogs, Storage page, backfill, no grace); app homes filtered to their kind with the left menu (app links, settings, *Report a bug*, storage meter); **settings split** (Wonky Work vs app settings); *Report a bug* (new-issue link) in every app; **shared-package extractions** without behavior change: `wonky_code*`, `wonky_numfmt`, `wonky_charts*`, `wonky_sync_kit*`, `wonky_rich_text`, `wonky_fonts`, `wonky_spellcheck`; space kinds + OS-8 space filter; Slides app skeleton at `/slides/` | Journeys 11–13 (11 §1.1) and J-D1…J-D10 on the web; quota enforcement table (Drive 03 §7.2) fully tested; backfill dry run on a production copy; Write and Sheets suites and goldens unchanged after the extractions; a deck space never reaches the Sheets replica; the Slides home lists presentations |
| **M9 · Slides MVP** ([Slides 12](wonky_slides/12-implementation-plan.md), SL-2…SL-23) | Slides data model + sync (one deck = one space, schema S-1, shared sync kit), editor canvas and core objects (text, shapes, lines, images, tables, groups), themes/layouts/masters, slide navigator with **slide groups**, grid view, speaker notes, presenting (full screen; presenter view in this window; audience on another device or browser via the presentation session), PDF export, app home + settings, offline creation, presence + soft locks, 5 templates | Journey 14 (without builds/code/charts) and J-S1…J-S4; offline merge fuzzer for decks green; multi-client scenarios of Slides 12 §1; PDF fidelity suite; web perf budgets of Slides 03 §18 |
| **M10 · Slides motion & content** (SL-24…SL-36) | Builds and the animation pane, transitions incl. Magic Move, laser/pen, loop/kiosk; code blocks with line highlighting and type-in/morph (`wonky_code`); Write exports on the shared tokenizer; linked Sheets charts incl. 3D and camera animation with client-side auto-update (`wonky_charts`), native charts (P1); PDF builds as pages; outline view, Layers, accessibility checker; masters and theme editor; 10 templates | Journey 14 complete and J-S5…J-S7; timeline determinism (client ≡ server); 60 fps budgets of Slides 01 met in Chrome on the reference machine |
| **M11 · Slides collaboration, MCP & AI** (SL-37…SL-45) | Live pointers and follow modes, comments on slides/elements, version history, activity; phone remote, rehearse, same-browser fast path (P1); `slides.*` headless and `ui.slides.*` tools; assistant in Slides (generate decks, notes, alt text, code walkthroughs) and in Drive (P1) | Journey 15 and J-S8…J-S10; MCP integration suite for `slides.*` green; a11y checklist; no open P0/P1 bugs |

> **History.** M8 and M9 built Slides on the shared sync kit (`wonky_sync_kit*`), space kinds
> and the OS-8 space filter. M13 (§2.1b) replaced that stack with RevLog; the M8/M9 text here,
> in §2.2, in §3 (WS-6, WS-19) and in §4 is kept as history.

**M8 exit checklist** (checked by D-18 on 2026-10-15; evidence in
[Drive STATUS](wonky_drive/STATUS.md)):

- ☑ Journeys 11–13 and J-D1…J-D8 walked through in the web release builds (light and dark,
  wide and narrow); J-D9 (MCP) and J-D10 (transfer to a nearly full user) green as server
  tests (`drive_file_tools_test`, `storage_enforcement_test`). ◐ Not yet automated: the web
  E2E runner and `integration_test` journeys (no chromedriver; steps in 15 §9, `TODO.md`).
  Journey 13 covers Drive, Write and Sheets; Slides' settings and bug button come with M9.
- ☑ Quota enforcement table (Drive 03 §7.2) fully tested (`storage_enforcement_test`,
  `storage_service_test`, MCP `quota_exceeded`).
- ◐ Backfill dry run: run on the development database (43 users, all reconciled at start,
  numbers in Drive 03 §11); a production copy doesn't exist yet — repeat on one before the
  first v2 deploy.
- ☑ Write and Sheets suites and goldens unchanged after the extractions (D-2, D-3, D-6, D-7
  rows of the Drive STATUS; golden masters are made on CI Linux).
- ☑ A deck space never reaches the Sheets replica (`space_kinds_test`, D-4).
- ☑ The Slides home lists presentations (SL-1 widget tests; `/slides/` release build opens on
  the presentations-only home with the app-home left menu, D-18).

**M9 exit checklist** (checked by SL-23 on 2026-10-15 with a changed goal from the user: M9
ends clean and working, everything not built is hidden and handed to `TODO.md` "Wonky Slides —
later (M10/M11)"; evidence in [Slides STATUS](wonky_slides/STATUS.md)):

- ◐ J-S1 (create from template and blank, edit) and J-S2 (present, presenter view, audience on
  another browser following, end) walked through in the web release build — partly: text
  editing, undo, slides, tables, menus/toolbar/inspector, presenting, presenter view, audience
  follow and the presenting banner, PDF export verified (light desktop, dark ~480 px); shapes,
  images, navigator groups, grid, notes, themes/page setup, cross-app paste, find & replace,
  offline resync and soft locks between tabs only through widget/integration tests. J-S3/J-S4
  not walked. ◐ Not automated: `integration_test` journeys (no chromedriver).
- ☑ Command harness green (`wonky_slides` suite, every registered command has a localized
  title; hidden features are not registered).
- ◐ Multi-client scenarios 09 §6.4: covered by the replica-level sync harness and the collab
  tests (SL-9, SL-21); the scripted `serverpod_test` isolate harness (12 §7.3) is not built.
- ☐ Offline merge fuzzer for decks — not built (property/convergence runs of SL-9 only).
- ☐ Perf budgets of Slides 03 §18 on the web — not measured.
- ◐ PDF: exports validated structurally (pages, fonts, bookmarks; client/server line-break
  parity, SL-20); the `pdftoppm` raster corpus diff needs poppler in CI.
- ☑ Slides home (presentations only, template gallery) and *Report a bug* in the editor title
  row seen in the release build; Slides settings tested in widget tests (settings of hidden
  features are hidden).

**M10 exit checklist** (checked by SL-36 on 2026-10-15; M10 ends like M9: everything built is
on, the rest is hidden and listed in `TODO.md` "Wonky Slides — later"; evidence in
[Slides STATUS](wonky_slides/STATUS.md) and the SL-36 "As built" note):

- ◐ Journey 14 complete and J-S5…J-S7 — walked through by hand in the web release build
  (`/slides/`, desktop 1280 px and 800 px, ~480 px, light and dark): decks from the four new
  templates (gallery cards and `/new?template=`); present mode with step-0 builds, click builds
  (cards pop, paragraph builds), a 3D cube transition forward and reversed on back (landing on
  the previous slide's final step), Magic Move (device moving aside — end state only, the pane
  was hidden then; code token morph mid-frames in the Transition tab preview, "2 objects match"), code type-in and highlight steps with callouts while
  presenting and in the Animate preview; Animate tab (Transition tiles with the deck default,
  Build tab adding *Rise* with auto-preview, Order tab with steps and durations) also at 480 px;
  a linked chart inserted from a Sheets spreadsheet, the source edited in Sheets in the same tab,
  the stale *Update* badge and the update; 3D chart orbit by drag, undo, the *3D view* menu;
  masters and layouts mode, the theme editor, outline view, Layers panel, accessibility checker
  (0 errors on the templates); print preview with *Print each build stage* (13 → 26 pages; the
  PDF checked by its bytes — the embedded browser pane has no PDF viewer) and the PNG dialog.
  Not walked: reduced motion (the pane can't emulate `prefers-reduced-motion`; covered by the
  player/compiler tests), laser/pen/kiosk, PNG and PDF downloads (no downloads from the agent),
  auto-update of linked charts while presenting. ☐ Not automated: `integration_test` journeys
  (no chromedriver).
- ☑ Timeline determinism (client ≡ server): one pure-Dart compiler/evaluator in
  `wonky_slides_core` for the app, the server PDF and MCP; `frames_test` (same input → identical
  frame JSON, recorded frames), the templates' builds compile without warnings.
- ☐ 60 fps budgets in Chrome on the reference machine — not measured (the motion benchmark
  `wonky_slides/benchmark/motion_bench.dart` runs by hand; the transitions and type-in looked
  smooth in the walkthrough, no frame timings recorded).
- ◐ Multi-client scenarios #18–20, 23–25: replica-level sync and collab tests only (as M9).
- ☑ Templates 10 of 10 (nine built-ins + Blank) with tests (planner, maintenance, copy,
  contrast/fit in both appearances, timeline warnings, Magic Move matches, accessibility
  checker), on the server (`slides_templates_test`) and in the gallery.

**M11 exit checklist** (checked by SL-45 on 2026-10-15; Wonky Slides is complete for its first
iteration — everything built is on, SL-41 is on hold by the user's decision, the rest is hidden
and listed in `TODO.md` "Wonky Slides — later"; evidence in [Slides STATUS](wonky_slides/STATUS.md)
and the SL-45 "As built" note):

- ◐ Journey 15 and J-S8…J-S10 — walked through by hand in the web release build (`/slides/`,
  desktop 1280 px and 800 px, 480 px and 400 px, light and dark; two tabs signed in as the same
  user): **J-S8** comment on an element (toolbar and context menu), docked card with pin and
  count badge, reply, comments panel with *This slide / All slides* and slide group headers,
  delete → *Orphaned* with "The commented content was deleted" → undo → the threads are open
  again (fixed in SL-45); not walked: @mention notifications and the deep link (server and
  widget tests). **J-S9** name a version, edit and delete a slide, full history with the per-slide
  change list, ghost row of the deleted slide and the inline text diff, restore (restore point
  kept, toast), undo of the restore; also at 400 px (fixed layout). **J-S10** headless part: MCP
  route and tool suites green on the server (`slides.*` 29 + 5 relay); UI-bridge part not walked
  in the browser (widget tests and the server relay test only; no MCP client against the dev
  server). **Journey 15** (two editors, soft lock, own undo): live pointer with name tag,
  selection outline and presence, soft-lock banner and *Edit anyway* popover, live text hint
  (own-undo per user: widget and sync tests only); follow a presentation (*… is presenting · Follow*, follower
  view following the presenter, *Stop following*). Also seen: spelling squiggles, right-click
  suggestions (fixed in SL-45), the Check spelling dialog, Special characters and Emoji typing
  into text (fixed in SL-45), the assistant panel without a configured provider (the development
  server has no AI key: banner with *Add an API key*, quick prompts, Edit/Suggest; no AI run was
  made), Design ideas, an elbow connector glued to two shapes (outline fixed in SL-45),
  M9/M10 regression (editing, present with builds and code type-in, a linked chart, print preview
  with a 13-page PDF checked by its bytes). Not walked: AI flows with a real provider, the image
  adjustment preview and route-handle drags with a real mouse, clipboard paste (the pane can't
  grant clipboard read), keyboard shortcuts (synthetic Cmd keys), reduced motion, downloads.
  ☐ Not automated: `integration_test` journeys (no chromedriver).
- ◐ All §7.3 scenarios: replica-level sync and collab tests, server comment/version/headless
  integration tests; the scripted `serverpod_test` isolate harness (12 §7.3) is still not built.
- ☑ MCP integration suite for `slides.*` green (server `test/integration/slides` incl. `mcp/`,
  `ai/`; platform MCP suites).
- ◐ a11y checklist: keyboard-operable commands and dialogs, MCP-describable dialogs (04 AC-9),
  contrast and tap-target guidelines in the screen-level widget tests, light and dark at 360–480
  px; not done: a screen-reader pass in the browser (the SL-23 finding — canvas text editing
  with Flutter semantics on — is still open).
- ◐ No open P0/P1 bugs: the ten bugs found in the walkthrough are fixed with regression tests;
  open: one `RuntimeError: memory access out of bounds` crash of the wasm build in the agent's
  pane after many viewport-emulation changes (not reproduced), P1 features listed in `TODO.md`.

M8 must land the shell changes (scope-aware homes, settings split, `WonkyAppKind` with four
apps) before Slides UI work starts in M9, and every shared-package extraction plus OS-8 before
the first Slides package that needs it (SL-2 needs D-6; SL-5 needs D-4; SL-26/SL-27 need D-2/D-3).

### 2.1a Bugs & improvements (M12, built)

| Milestone | Goal | Exit criteria |
|-----------|------|---------------|
| **M12 · Bugs & improvements** ([16](16-bugs-and-improvements.md), BI-1…BI-9; P1 BI-10; GitHub step 2 BI-11, BI-12) | Replace *Report a bug* and *Report a problem* with a public in-app board: report dialog with similar posts and an annotated screenshot, votes, Markdown comments (shared with document comments), triage and moderation by Jev and writing by Gemini (internal keys, separate from the in-app AI), admins by email domain, tasks (single posts or bundles) with AI-written, admin-reviewed contributor prompts, 48-hour claims with claim codes, `CONTRIBUTING.md`, `SECURITY.md` and PR template; step 2: a GitHub App gate (only PRs with a claimed task), an advisory AI review against the task, merged → done, deployed → shipped | J-B1 green; board access matrix tested; document comment suites green; light/dark goldens; signed-out board loads in the release build; `CONTRIBUTING.md` verified by a fresh-clone dry run |

**Delivered** (BI-1…BI-9 and BI-11, BI-12; BI-10 (P1) not built, open items in
[16 §17](16-bugs-and-improvements.md)).

**M12 exit checklist** (checked 2026-10-15: suites, then a browser walkthrough of the Drive release
build against the live server with the real Jev and Gemini APIs):

- ☑ Server board suites (`wonky_server/test/integration/platform/board/`, `test/unit/board/`): access matrix (signed out, signed
  in, author, admin, blocked), posts, votes, comments, claims and sweep, triage bands and
  pipeline, Jev/Gemini isolation, MCP tools, GitHub gate, lifecycle, review and webhook.
- ☑ Client suites (`packages/wonky_app/test/board/`: commands with undo, report dialog, board
  pages, review tab, screenshot editor), `WonkyMarkdown`/`MarkdownComposer`, and
  `CommentThreadBody` with both action implementations.
- ☑ Document comment suites unchanged apart from Markdown rendering: `test/comments` plus the
  Write (comments, suggestions, AI, images, offline, document), Sheets (comments, collab, AI) and
  Slides (present, comments) suites green after the `CommentThreadActions` refactor.
- ☑ J-B1 walked through in the browser: report from the left menu with a captured, covered and
  highlighted screenshot; live Jev triage (labels, spam held, duplicate hint, merge); post page
  (Markdown, screenshot, admin scores, Gemini title); comment; select for building with the
  prompt written in the background; publish; claim with the claim code. The GitHub side is
  covered by recorded-webhook tests (the App is not installed yet); keyboard undo could not be
  driven in the agent's browser pane (command undo tests are green).
- ☑ Signed-out board in the release build: `/drive/improvements` loads signed out with the
  sign-in banner; `/improvements/**` redirects to Drive.
- ☐ Light/dark goldens for the dialog, row, post page and editor — not written.
- ☐ `CONTRIBUTING.md` fresh-clone dry run — the kit exists (`CONTRIBUTING.md`, `SECURITY.md`,
  `.github/pull_request_template.md`, issue template `config.yml`, `passwords.example.yaml`),
  not yet verified by an agent on a clean machine.
- ◐ Triage evaluation set (`ai/eval/`, tag `live-ai`, labeled posts): runs only with
  live keys, results not recorded in the spec.
- ◐ Step 2: gate and review proven with recorded payloads and a fake GitHub API; a real PR from
  a non-member fork against the installed App is pending.

### 2.1b RevLog sync (M13, built)

| Milestone | Goal | Exit criteria |
|-----------|------|---------------|
| **M13 · RevLog** ([17](17-revlog-sync.md); PRs R0–R8, gates G1–G3) | Sheets and Slides sync through RevLog instead of the vendored CRDT engine: one server-sequenced op log per file over one Serverpod stream per open file; the domain tables as plain server tables; a client cache with a durable outbox (`wonky_revlog`, `wonky_revlog_flutter`); viewport-first opening; protected ranges enforced by the server; post-commit hooks instead of the change-log consumers; server writes through `submitServerChange`; one headless model cache for both apps. PRs: R0 baseline and prototype (G1: go), R1 core package, R2 shared infrastructure (`ConnectionKeeper` in `wonky_app`, `immediate` bus posts), R3 server platform + Sheets binding, R4 Sheets server writers and readers, R5 client package + Sheets app, R6 Sheets gates and merge (G2), R7 Slides (G3), R8 removal of the engine, spaces and sync kit | G2: Sheets suites green on RevLog, gates P1–P12; G3: Slides suites green, P1, P6, P8 for a 500-slide deck; R8: no engine code left; specs adopted (17, 12 §2, app specs) |

**M13 exit checklist** (status 2026-10-18):

- ☑ Core and client packages: `wonky_revlog` (codec, apply rules, overlay, chunker,
  `RevSyncCore`, `FakeRevServer`; property tests for codec, chunker, overlay and convergence) and
  `wonky_revlog_flutter` (cache, transport, connection, bootstrap, `RevLogClient`, `FakeRevHub`).
- ☑ Server: `platform/revlog/` (sequencer, connection, pages, hooks, `HeadlessFileCache`, jobs
  `revlog.pruneOps`, `revlog.hookSweep`, `revlog.repairStats`) with the Sheets and Slides
  bindings; suites in `wonky_server/test/integration/{platform,sheets,slides}/revlog/`.
- ☑ Protected ranges enforced by the sequencer (`protectedRange`) and handled by the Sheets
  client (rejection toast, rollback, undo step dropped).
- ☑ Sheets and Slides apps on `LoggedWorkbookSession` / `LoggedDeckSession`: creation online and
  offline, imports, version copies, scripts, MCP, AI, versions and restore through RevLog;
  Sheets offline scenarios of [Sheets 10 §10](wonky_sheets/10-collaboration-history.md).
- ☐ Performance gates P1–P12 (17 part 7): no RevLog perf suite and no recorded results yet.
- ◐ R8 removal: `wonky_sync_kit` only re-exports `wonky_revlog`; still in the tree:
  `third_party/serverpod_offline_sync` with its module, `databaseSync` and `shared_packages` in
  `wonky_server/config/generator.yaml`, `platform/spaces/` (still called by
  `drive.setPinnedOffline`) and `wonky_sync_kit_flutter`.

Open follow-ups (not exit criteria; 17 As built): *Save my changes as a copy* after a rejection
(As built 10), a conflict review fed directly by outcomes (11), the download of unsynced changes
when the cache can't be opened and before *Clear local data* (15), the `cascaded` info toast
(P2, 17 part 6 §6), and character-level merge of concurrent text edits in Slides
([Slides 02 §4.5](wonky_slides/02-data-model.md)).

### 2.1c Publications & submissions (M14, built)

| Milestone | Goal | Exit criteria |
|-----------|------|---------------|
| **M14 · Publications** ([18](18-publications-and-submissions.md), PUB-1…PUB-8) | Blogs register a publication and link to Wonky Write; contributors write and *Submit* to the blog's review queue; moderators comment in the document; the blog's decisions and messages come back as a feedback thread and notifications | J-P1 green against a fake blog receiver; API access matrix and transitions tested; signing vectors and SSRF matrix green; light/dark goldens of the consent dialog, submit dialog, chip and settings section; developer guide verified by building the sample receiver |

**M14 status** (2026-10-20): built, see [18 §13](18-publications-and-submissions.md). Server
suites (flow, API over HTTP, owner endpoints, rules, the guide's signing vector) and client
suites (start flow, settings section, Write title row, submit, disconnect undo) are green.
Open: J-P1 E2E, goldens, a walkthrough against a live server.

### 2.2 Executing the plan with parallel agents (v2)

The app plans list **work packages** (Drive 05 §4: D-1…D-18; Slides 12 §4: SL-1…SL-45). Each
is a few hours of agent work with: scope, owned folders, dependencies, contracts provided and
consumed, acceptance tests, a wave and — where browser checks are needed — the web-build token.

- **Capacity**: the developer laptop has 16 GB of RAM → at most **5 agents** at once, at most
  **2** running the server test suite (embedded PostgreSQL each), and **one** agent holding the
  web-build token (`flutter build web` + browser checks at `localhost:8082/<app>/`).
- **Waves**: ≤ 5 packages each; a package starts when its dependencies are merged and a slot is
  free (waves overlap). Order: M8 waves 1–4 → M9 waves 1–5 → M10 waves 1–3 → M11 waves 1–2.
- **Wave 1 of M8 is foundations**: contracts (D-1: all M8 models in one migration incl.
  `DriveItemKind.presentation/file`, `SpaceKind`), extractions (D-2 `wonky_code*`, D-3
  `wonky_numfmt`/`wonky_charts*`), the OS-8 space filter (D-4) and the Drive scaffold with the
  root redirect (D-5). Wave 2 adds the remaining extractions (D-6 `wonky_sync_kit*`, D-7
  `wonky_rich_text`/`wonky_fonts`/`wonky_spellcheck`) next to the server and shell services.
- **Mechanics** (Drive 05 §2): agents share one working tree (the running `serverpod start` watches it), the orchestrator commits after green acceptance tests,
  ownership by folder with additive edits to registration files, one open migration at a time,
  agents never start the server (AGENTS.md), contract changes via a small contract PR.
- **Reuse** before writing new code: the shell drive UI (`packages/wonky_app/lib/src/drive/`),
  the Sheets sync layer (`wonky_sheets/lib/features/sync/`) and `WorkbookSession` pattern, the
  Sheets chart engine (`wonky_sheets_core/lib/src/charts/`, `wonky_sheets/lib/features/{charts,charts3d}/`),
  Write's code highlighting — the tables in Drive 05 §3 and Slides 12 §3 map each need to code.

## 3. Workstreams (suite-level, shared)

| ID | Workstream | Owns | Depends on | Milestone |
|----|------------|------|-----------|-----------|
| WS-0 | Repo restructure, CI, workspace, web build/serving (`flutter_build`, app routes), cookie auth config | root, CI scripts, `wonky_server/pubspec.yaml`, `wonky_server/lib/server.dart` (web routes) | — | M0 |
| WS-1 | `wonky_core`: ids, roles, command & undo abstractions, MCP tool schema types | `packages/wonky_core` | — | M0 |
| WS-2 | `wonky_ui`: theme, tokens, custom widgets (02 §4) | `packages/wonky_ui` | — | M0–M1 |
| WS-3 | Shell: routing, layout, overlays, connectivity, command registry/dispatcher, keymap, palette, undo service | `wonky_app/lib/{shell,commands,undo}` | WS-1, WS-2 | M0–M1 |
| WS-4 | Auth & accounts & settings | server `platform/users`, `wonky_app/lib/auth`, `…/settings` | WS-3 | M1 |
| WS-5 | Drive (server + UI) | server `platform/drive`, `wonky_app/lib/drive` | WS-4 | M1 |
| WS-6 | Sharing & AccessService (+ space membership mirroring hook) | server `platform/sharing`, `wonky_app/lib/sharing` | WS-5 | M1, M4 |
| WS-7 | Presence & notifications | server `platform/{presence,notifications}`, `wonky_app/lib/{presence,notifications}` | WS-3 | M1, M4 |
| WS-8 | Comments framework (server + shared UI) | server `platform/comments`, `wonky_app/lib/comments` | WS-6 | M4 |
| WS-9 | Versions framework | server `platform/versions`, `wonky_app/lib/versions` | WS-5 | M4 |
| WS-10 | MCP platform: route, auth tokens, ToolExecutor, UI bridge hub + client bridge, shared tools (drive/comments/versions/changes) | server `platform/mcp`, `wonky_app/lib/mcp_bridge`, `wonky_mcp_stdio` | WS-1, WS-5 | M0 spike, M6 |
| WS-11 | AI platform: Anthropic client, assistant service/endpoint, shared panel | server `platform/ai`, `wonky_app/lib/assistant` | WS-10 | M6 |
| WS-12 | Files/uploads/signed URLs | server `platform/files` | WS-4 | M1 |
| WS-13 | Quality infra: test helpers of 15 (`pumpWonky`, `CommandTestHarness`, `TestUsers`, `forEachRole`, seeded generators, golden script), harnesses, multi-client simulators, perf suite, golden matrix | `tool/`, `benchmark/`, `lib/testing.dart` + `test/support/` of each package | WS-0 | M0 → ongoing |
| WS-14 (v2) | Drive app, files, uploads, previews, Drive MCP (Drive D-5, D-8, D-13, D-14, D-15, D-17) | `wonky_drive/`, server `platform/{drive,files}` | WS-5, WS-12 | M8 |
| WS-15 (v2) | Storage quota (Drive D-9) | server `platform/storage` + hooks | WS-14 | M8 |
| WS-16 (v2) | Shell v2: scope-aware homes, left menu, `WonkyAppKind` ×4, storage UI, *Report a bug*, app adaptations (Drive D-1, D-10, D-11, D-16) | `wonky_app/lib/src/{bootstrap,config,drive,shell,storage,routing,menus}`, app home configs | WS-3, WS-5 | M8 |
| WS-17 (v2) | Settings split (Drive D-12) | `wonky_app/lib/src/settings`, app settings sections | WS-16 | M8 |
| WS-18 (v2) | Shared packages: `wonky_code*`, `wonky_numfmt`, `wonky_charts*`, `wonky_rich_text`, `wonky_fonts`, `wonky_spellcheck` (Drive D-2, D-3, D-7), dependency rules | `packages/…`, `tool/check_dependencies.dart` | — | M8 |
| WS-19 (v2) | Shared sync kit + OS-8 space filter + space kinds (Drive D-4, D-6) | `packages/wonky_sync_kit*`, `third_party/serverpod_offline_sync`, server `platform/spaces` | — | M8 |

App workstreams: see the app plans (WS-W*, WS-S*; (v2) work packages D-* in Drive 05 and SL-* in Slides 12).

## 4. Dependency graph (simplified)

```
WS-0 ─┬─ WS-1 ─┬─ WS-3 ─┬─ WS-4 ─ WS-5 ─┬─ WS-6 ─ WS-8
      │        │        │               ├─ WS-9
      └─ WS-2 ─┘        ├─ WS-7         └─ WS-10 ─ WS-11
                        └─ (Write WS-W*, Sheets WS-S* start after WS-3 contracts exist)

(v2)  M8 wave 1: D-1 contracts · D-2 code · D-3 charts · D-4 OS-8 · D-5 scaffold
      M8 wave 2: D-6 sync kit · D-7 rich text/fonts/spell · D-8 files · D-9 quota · D-10 shell
      M8 wave 3–4: D-11…D-18 (+ SL-1) ──► M9 (SL-2…SL-23) ──► M10 (SL-24…SL-36) ──► M11 (SL-37…SL-45)
```

## 5. Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| `serverpod_offline_sync` maturity (0.0.x, experimental) and scale limits | Sheets data loss/perf | Vendored patch, extensive fuzzing, staged cell limits, upstream requirements U1–U11 — the team can contribute upstream. **Retired by M13**: Sheets and Slides sync through RevLog ([17](17-revlog-sync.md)) |
| RevLog sequencer load (one sequencer per file, protection checks on large protected files, hook lag) | Slow commits or late side effects on busy files | Gates P3, P4 and P12 (17 part 7), per-op metrics and hook lag in Settings › Developer (17 part 5 §12), warm headless models for protected files |
| super_editor pre-1.0 API churn; gaps (tables read-only, no incremental Quill apply) | Write delays | Vendored copy (01 §2.3) with focused patches SE-1…SE-5; our mapper/applier/extractor layer isolates the rest of the app; upgrade only deliberately |
| Web SQLite (OPFS availability, IndexedDB memory) | Large offline sheets on some browsers | Detect storage mode, limit offline size, warn |
| `dart_eval` performance and language coverage; web worker complexity | Scripting UX | Server-side compile; documented language subset; generous timeouts; P1 features gated |
| Formula compatibility | User trust | Differential tests vs LibreOffice; golden vectors |
| MCP spec evolution | Integration breakage | `mcp_dart` protocol profiles; integration tests per profile |
| Scope (Google Docs + Sheets parity) | Schedule | P0/P1/P2 priorities in app overviews; milestones deliver usable slices |
| (v2) Sync engine syncs every member space (decks + spreadsheets in both replicas) | Slides/Sheets download each other's data | OS-8 space filter patch and space kinds in M8 wave 1 (Drive 05 D-4). **Retired by M13**: each client loads only the files it opens or keeps offline |
| (v2) Existing users above the new 50 MB quota | Frustration, support | Non-destructive over-quota state, clear Storage page, one-time notice (Drive 03 §9) |
| (v2) Shell refactor for four apps collides with app work | Merge conflicts | D-10 lands in M8 wave 2 behind a compatibility default (Drive 05 §4) |
| (v2) Parallel agents on a 16 GB laptop | Swapping, flaky tests, merge conflicts | ≤ 5 agents, ≤ 2 server test runs, one web-build token, folder ownership (§2.2) |
| (v2) Presenting without a second window | Laptop + projector setups need a second browser or device | Presenter view in this window + audience via the presentation session (Slides 10 §5.2); same-browser fast path (P1); a second window is a possible later addition |
| (v2) Four web builds | Deploy time, CI minutes | Parallel builds in `flutter_build`; only changed apps rebuilt in CI (01 §2.4) |
