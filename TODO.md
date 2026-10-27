# Wonky Work — TODO

The first iteration delivers **Wonky Write** (sign-in, drive, sharing, a real-time
collaborative editor, comments, suggestions, history, themes, import and export) and
**Wonky Sheets** (offline-first synced spreadsheets: grid, formulas, formatting,
conditional formatting, data tools, validation, protection, pivots, charts, import/export/print,
collaboration and history, MCP and AI). The specs in `specs/` remain the source of truth.
This file lists what is not done yet; the Sheets state per area is in
[specs/wonky_sheets/STATUS.md](specs/wonky_sheets/STATUS.md).

Status legend: ☐ open · ◐ in progress · ☑ done (done items are removed once they are
committed and verified).

## Wonky Write — deferred features (in planned order)

1. ◐ **Theme editor UI** (Write 06 §10): `/themes/:uuid?doc=` with a live preview (sample or the document, light/dark, pages/pageless, zoom), a catalog-driven inspector for every theme property, contrast warnings with *Fix*, dark derivation and overrides, duplicate/rename/delete/restore, revisions, conflict dialog, *Apply to document* and *Set as my default*; all `write.theme.*` commands, undoable. Still open: hover-outlining of matching blocks in the preview.
2. ◐ **Import/export formats** (Write 07): DOCX, ODT, RTF and EPUB exporters plus DOCX, ODT and RTF importers in `wonky_write_core`. Exporting and re-importing our own files gives back the same document for all 8 themes, except that RTF brings heading numbers back as text. Server `writeExport.export` covers all 10 formats, with bundled fonts in `web/fonts` and images read from storage; `drive.import` and `convertForInsert` accept HTML, DOCX, ODT and RTF. In the app, File › Download lists every format, and File › Import / Insert from file accept them; the import banner shows on first open. Still open:
   - the server export cache and the isolate pool; large documents still export on the client;
   - SVG images in DOCX/ODT/RTF/EPUB (rendered as placeholders);
   - comments in DOCX/ODT exports and embedded DOCX fonts (both P2);
   - LibreOffice and epubcheck validation in CI.
3. ◐ **MCP** (suite 09, Write 09) — `/mcp` Streamable HTTP route on the web server (custom
   `mcp_dart` transport; MCP 2026-07-28 stateless + initialize-era sessions), PAT bearer auth
   with scopes, host/origin checks and rate limits; `ToolExecutor` with `drive.*`, `write.*`
   (23 tools), `comments.*`, `versions.*`, `changes.revert`, resources and prompts; UI bridge
   (`uiBridge.connect` + `UiBridgeHub`, client bridge with shared `ui.*` and `ui.write.*`
   tools, control pill with Stop); `wonky_mcp_stdio`; Settings › Developer (tokens with
   scopes/expiry, connection snippets, bridge status). Remaining:
   - resource subscriptions (`notifications/resources/updated`) and MCP 2026
     `subscriptions/listen`; OAuth 2.1;
   - `write.compare_versions`, `write.get_theme`, `write.create_theme`/`update_theme`
     (with the theme editor), the `write.search` regex timeout;
   - the UI-bridge hub is per server instance (no cross-instance relay yet);
   - `ui.write.get_layout_info` does not report the visible Delta range yet.

4. ◐ **AI assistant** (suite 10, Write 09 §5): server `AnthropicClient` (HTTP + SSE, retries with backoff/`retry-after`, refusal fallbacks, beta features that degrade on a 400) and agent loop (`assistant` endpoint: chat stream, threads, stop, destructive-change confirmation, inline rewrite/continue/summarize/outline/explain, proofread with the strict `report_issues` tool; tools generated from the MCP registry and bound to the open document; prompt caching; daily token budget, 2 concurrent requests, `AiUsage`); one run = one undo step "AI: …" on the requesting client (`onBehalfOfSessionId`/`groupId`); the shared `AssistantPanel` (threads, streaming Markdown, tool chips with Show/Undo, context chips, Stop, quick prompts, Edit/Suggest, privacy notice, "AI isn't configured" state); inline AI (selection ✨ menu, `/ai`, Mod+J prompt, preview with Replace/Insert below/Try again/Refine/Discard and a word diff, continue writing, AI suggestions with `via: ai`); Tools › Summarize document / Generate outline / Proofread document; Settings › AI (enable, quality, usage, clear history). Enable it with `anthropicApiKey` in `config/passwords.yaml`. Still open:
   - the `ui.write.get_ai_preview` UI-bridge tool, and `write.compare_versions` / `write.get_theme` for the assistant (they don't exist as MCP tools yet);
   - a live check against the real API (no key in development); the run and concurrency registry is per server instance;
   - continue writing shows its ghost text in a card at the caret, not inline in the text layout.
5. ◐ **Offline persistence** (suite 12 §1): per-user `write_cache_<userId>.db` on `sqlite_async`
   (web: `sqlite3.wasm` + `db_worker.js` in `wonky_write/web/`, OPFS or IndexedDB; desktop: a
   file) with `LocalDocument` (+ server op log), the durable `LocalPendingOp` outbox (written
   before sending, 2 s chunks, resent with the same `clientOpId`, `RebaseTooOld` → "Save my
   offline changes as a copy"), `LocalUndoStack` and `LocalPendingUpload`. Documents open from
   the device first (stale-while-revalidate), can be created offline, and stay available when
   opened in the last 14 days (max 50) or made available offline (downloaded, drive badges,
   unavailable items dimmed). Closed documents with an outbox sync in the background; metadata
   changes are queued; the profile is cached for offline starts; the drive cache and queue are
   per user. Settings › Offline & storage shows usage, *Clear local data* and *Simulate offline*
   (`write.offline.simulate`, the `ConnectivityService.forceOffline` test hook). Still open:
   - the offline theme cache (documents opened offline use the default theme when their theme
     was never loaded) and offline comments;
   - "Offline storage is limited in this browser" for the IndexedDB fallback;
   - deleting the database file on desktop (tables are truncated, as on the web).

6. ◐ **Spellcheck** (Write 04 §28): pure-Dart Hunspell checker in `wonky_write_core` (`package:wonky_write_core/spellcheck.dart`: affixes, flags, compounding, REP/MAP/KEY/TRY + n-gram suggestions, tokenizer with the skip rules); bundled en-US, en-GB, fr-FR, es-ES, nl-NL, sv-SE, da-DK dictionaries (open licenses, `assets/dictionaries/LICENSES.md`), loaded on first need and parsed in 8 ms frame slices; red wavy underlines, context-menu suggestions, Ignore, Add to dictionary (synced personal dictionary), Tools › Spelling (Check spelling… dialog with Change / Change all, Next error ⌘', Underline errors, Ignore UPPERCASE, Personal dictionary…), per-document language. Still open:
   - de-DE, it-IT, nb-NO (GPL-only upstream) and pt-BR, pl-PL (size) dictionaries; licenses in About;
   - a Web Worker / isolate for checking very large documents.
7. ◐ **Editor extras:** SE-4 in-place table cell editing (click a cell, Tab/Enter navigation, Markdown source per cell, one "Edit cell" step per commit); drag and drop (SE-6 selection move/copy, block drag via the handle with drop line and auto-scroll, web OS drops of images, documents and text/HTML); emoji picker (Insert › Emoji, `/emoji`, `:` trigger) and special characters dialog; image lightbox (focus mode and typewriter scrolling were built and later removed). Still open:
   - OS drag and drop in native desktop builds (needs a drop plugin);
   - the emoji picker in wonky_ui for comment reactions; self-hosted fallback fonts (`fontFallbackBaseUrl`);
   - table cells: caret inside cells in the document itself (cells are edited through a per-cell field).
8. ◐ **Notifications** (07 §4, §6): pluggable `EmailSender` (Resend HTTP API with the passwords `resendApiKey` + `emailFrom`, otherwise logged), mention/assignment emails right away (`NotificationEmailFutureCall`), the 15-minute digest for the other kinds (or one email each with `digest: false`), honoring Settings › Notifications (mentions, replies, shares, access requests, suggestions, digest); notifications popover (grouping, excerpts, All/Unread, paging, settings link, keyboard); activity dashboard server side (`ActivityEndpoint`: viewers for Editors+ from the share set, view and comment trend charts, "Show my view history"; the dashboard dialog was removed from the UI, 07 §6); paged activity feed in the details panel. Still open:
   - localized emails (server emails are English);
   - undo for *Mark all as read*;
   - deep links from emails to the comment thread.
9. ◐ **Quality**:
   - CI (CQ-64, specs/01 §2 "CI"): analyze, format, the dependency check (incl. unused dependencies and test imports) and the generated-code check on every PR; tests per package plus the vendored suites; the `--wasm` build of every app with bundle-size budgets (`build.yml`); goldens in a pinned Linux container (`goldens.yml`); nightly `slow`, perf and long property runs (`nightly.yml`) and the Write E2E journeys on macOS (`e2e.yml`). Open: the coverage gate of specs/15 §10, export validation (LibreOffice, epubcheck, poppler), the web E2E runner;
   - ☑ i18n: wonky_app and wonky_write strings in ARB (`write_en.arb`, `wonky_app_en.arb`), `en_XA` pseudo-locale (`tool/pseudo_locale.dart`, `--dart-define=WONKY_LOCALE=en_XA`); the menubar overflows at 1024 px under en_XA; `ar_XB` (RTL) is not generated yet;
   - ☑ accessibility: labeled icon buttons, `textContrastGuideline` + `labeledTapTargetGuideline` in the screen-level tests (home, settings, Write screen, notifications);
   - ◐ E2E journeys in `wonky_write/integration_test` (macOS; nightly `e2e.yml`): 1, 2, 5, 6 and 8 (MCP drive/write tools; `ui.invoke_command` not yet) pass locally; web needs `flutter drive` + chromedriver; journeys 3, 4, 7, 9, 10 are open;
   - ◐ golden tests: `goldens.yml` compares the masters on CI Linux; none are committed yet (generate them with `tool/update_goldens.sh` or the workflow's `update` run, then commit the PNGs); Write, Slides and `wonky_ui` have no goldens yet;
   - ◐ performance suites: Write and Slides `perf`, Sheets core benchmarks (nightly, `nightly.yml`); a shell rebuild counter is open (CQ-38).
10. ☐ **Deployment** (deferred to a later iteration; the release build served at `/write/` already loads and works in development):
    - verify production builds served by the server at `/write/` and `/sheets/` (`serverpod run flutter_build`), with WASM and cross-origin-isolation headers;
    - the sign-in is shared on the single origin; in development the two `flutter run` origins (8101 and 8102) don't share it.
11. ☐ **Desktop** (deferred to a later iteration; v2 is web only, `specs/01-architecture.md` A13 — the desktop targets must keep compiling) (macOS first): packaging, native menubar, keychain sharing between apps, four binaries with `wonkydrive://` / `wonkywrite://` / `wonkysheets://` / `wonkyslides://` URL schemes, OS drag and drop in native builds, desktop printing extras, Slides presenting in native full screen (`window_manager`).
12. ☐ **Multi-window presenting** (deferred, v2 review Q5/Q29/Q30): a presenting-only second window for Slides' audience view — Window Management API on the web, Flutter multi-window (fallback `desktop_multi_window`) on desktop — reusing the presentation-session messages (`specs/wonky_slides/10-presenting-and-pdf.md` §5.3). v2 presents in one window with the audience on another device or browser.

## Repository, tooling and CI — open items (CQ-64 follow-ups)

- **Line endings:** `.gitattributes` (`* text=auto eol=lf`, binaries) is in place; right after the
  next commit run `git add --renormalize .` once and commit it alone. It changes the 12 OFL
  license texts whose index copy has CRLF or mixed endings (`*/fonts/OFL-*.txt`); everything else
  is already LF in the index.
- **SDK lower bounds:** the pubspecs say `sdk: ^3.12.2` while the lock file needs Dart ≥ 3.13.0
  (Flutter lower bounds are raised to `^3.47.0`). Raising `sdk` to `^3.13.0` changes the language
  version and with it the formatter style of 615 files; do it in a quiet window together with a
  repo-wide `dart format` (one commit), then keep `wonky_client`'s pubspec in step.
- **`discarded_futures`** is off in `wonky_app` (79), Write (13), Sheets (18) and Slides (27)
  (`TODO(CQ-64e)` in their `analysis_options.yaml`); fix with `unawaited(…)` or awaits and turn it on.
- **Golden masters:** none committed yet; generate them on Linux (`tool/update_goldens.sh` with
  Docker, or the `Goldens` workflow with `update`) and commit the PNGs. `tool/*.sh` were created on
  Windows without the executable bit (CI calls them with `bash`); `git update-index --chmod=+x`
  when committing.
- **Bundle size** (2026-10-18, `tool/build_web.dart`): `main.dart.wasm` Drive 6.3 MB, Write 9.1 MB,
  Sheets 12.5 MB, Slides 11.0 MB; assets 25–35 MB per app, of which the spellcheck dictionaries
  are 13 MB in every app (Drive included; serve them once from the server, R-18). No app-level
  deferred loading yet (R-7): candidates are the script editor, theme editors, chart editor,
  import/export and presenter mode (`deferred as` behind route builders; check dart2wasm's
  deferred-module support first). Budgets: `tool/web_budgets.json`.
- **`package:pdf/src` imports** (Write, Sheets, Slides PDF exporters): `PdfString` (deterministic
  `/CreationDate`) is not exported by `pdf` and no public API sets the date, so the three
  `implementation_imports` stay; check them on every `pdf` upgrade (or move them into one adapter
  if a shared pdf helper package appears).
- **`dart_eval` pins the workspace to analyzer 8.x** (`third_party/dart_eval`, Sheets 09 §23):
  plan — port the compiler's AST use to analyzer 13 (≈ 93 errors in dart_eval + 15 in
  `wonky_sheets_script`, measured against 13.3), run the dart_eval suite and the script
  conformance tests, then bump the lock in a quiet window. Isolating it instead (a non-workspace
  compiler package run as a separate process by the server) is not small: Serverpod Cloud only
  uploads workspace packages and the server compiles in-process. The script host no longer
  imports `dart_eval/src` (patch DE-22).
- **Forks:** `super_editor`'s own suite runs in CI (`tests.yml`, `third-party`; its upstream
  goldens live in `test_goldens/`, which is not vendored); upstreaming SE-1…SE-9 is open (PATCHES.md).
  `serverpod_offline_sync` is deleted (obsolete since RevLog).
- **Still missing in CI:** the coverage gate for `*_core` (specs/15 §10), export validation
  (LibreOffice, epubcheck, poppler), the web E2E runner, Dependabot or a scheduled `pub outdated`
  report, `wonky_sheets` `en_XA`, `ar_XB`.

## Known issues

- **Unlabelled dialog barriers:** `showShadDialog`'s `barrierLabel` defaults to `''`, so the
  barrier of every open dialog is a tappable node without a label (`labeledTapTargetGuideline`
  fails once a dialog is opened through it); pass a label (e.g. *Close*) at the call sites or
  wrap `showShadDialog` in `wonky_ui`.
- **Full-text search scans** (CQ-25, specs/13 §3 "Search indexes"): the drive and board search
  documents have no GIN index, because Serverpod's startup schema check reports expression indexes
  as a mismatch at every boot. Add the indexes back (e.g. as `SearchIndexes` entries) when search
  gets slow or when Serverpod can declare expression indexes / suppress the check for them.

- Version restore uses the shell's server-side restore; undoing it restores the restore point (Write 08 §4.5).
- When a role is downgraded while editing, pending ops that are no longer allowed are discarded through a resync, not converted into suggestions.
- Recurring server jobs are re-registered on every server start under fixed identifiers.
- Search uses no full-text GIN index yet.
- shad tooltips and popovers swallow Esc; the toolbar works around this with `ToolbarEscapeScope`.
- PDF exports (client and server) cover Latin, Greek and Cyrillic with the bundled TTFs; CJK, Arabic and emoji fall back to placeholders until the fallback fonts are added.
- WYSIWYG Markdown composer (`wonky_rich_editor`, specs/16 §7.3): ☐ a code block's language can only be set when typing the fence; ☐ browser check of IME typing (the first keys after a click, fixed in the widget, see §7.3), paste, copy as Markdown, the spelling menu and the link dialog in the release builds; ☐ the composer's spelling language is the device locale (no per-field language).

## Publications & submissions (M14) — open items

Spec: `specs/18-publications-and-submissions.md` §13; guide: `docs/blog-integration.md`.

- [ ] Light/dark goldens of the consent dialog, submit dialog, status chip and Settings ›
      Publications.
- [ ] E2E journey J-P1 (link → sign up → write → submit → changes requested → resubmit →
      published) against a fake blog receiver, and a walkthrough against the live server.
- [ ] Moderators who sign up later get access only with the next submit or status change; grant
      at sign-up instead.

## Wonky Markdown (Write 11) — open items

Spec: `specs/wonky_write/11-wonky-markdown.md`.

- [ ] Chip icons (`:chip[x]{icon=…}`): kept in the Delta and in Markdown, not drawn in the
      editor or the exports (out of scope by decision).
- [ ] App widget tests per §12: container frames and chrome, grid inline editing (Enter,
      Backspace, arrows, Tab), link style popover, slash items, menu and toolbar visibility per
      flavor; light/dark goldens of the elements in the editor, print preview, PDF and HTML.
- [ ] Submit dialog: a *Switch flavor* action next to the flavor warning (today it points to
      *File › Markdown flavor*).
- [ ] AC-WM.1–7 and 9 were walked through in a release build (2026-10-26); still open: the
      same with two collaborators (flavor switch seen by both), AC-WM.8 through the UI (a
      Wonky publication and a submission), and pasting the blog examples as Markdown (the
      agent browser pane can't write the clipboard; covered by the codec tests).
- [ ] YouTube videos: the blog's renderer for `::youtube` (`docs/blog-integration.md`; the
      serverpod_website repository); thumbnails instead of a link in PDF, DOCX and ODT
      exports; other video sites if needed.
- [ ] Chips inside tinted callouts have little contrast (the chip's gray `@codeBg` pill on a
      light tint, editor and PDF); consider a subtle border or a tint-aware chip color.

## RevLog sync — open items

Sheets and Slides sync through RevLog (`specs/17-revlog-sync.md`); the CRDT engine, the sync
kit and the sync spaces were removed in R8. Deferred:

- ☐ **Save my changes as a copy** when the server rejects an op (permission lost, file deleted,
  protection).
- ☐ **Conflict review fed by outcomes:** feed the conflict review from the server's op
  outcomes (what was overwritten or skipped).
- ☐ **Unsynced-data download** for a local cache that cannot be opened: offer its unsynced
  changes as a file before the cache is cleared.
- ☐ **Slides character-level text merge:** concurrent edits of the same text box are column
  "last arrival wins"; merge text at character level.
- ☐ **`cascaded` info toast** (P2): tell the user when their op removed rows they did not
  touch directly (cascade of a delete).
- ☐ Optional: rename `wonky_sync_models` (now only id helpers) and the `sheets/spaces/` server
  folder; the `spaceUuid` parameters of `drive.registerSpreadsheet`/`registerPresentation`
  (the file UUID) keep their name because queued drive ops store it; the version snapshot
  headers of the cores still accept a legacy `syncTablesHash` field.
- ☐ The RevLog limits are code constants; read them from a `revlog:` config section
  (`specs/01-architecture.md` §6).
- ☐ **Performance gates missed in R6** (`plans/sheets-sync-migration/baseline.md`, spec 17 part 7;
  Windows desktop, debug JIT, embedded Postgres, 1M = 38,461 rows × 26 columns):
  - **P7 client margin** (< 15 s for 1M): 12.6–14.5 s with SQLite since R7, of which ~2.6 s
    is the in-process page serving of the test; most of the rest is the model and the formula
    engine taking 1M cells on the UI isolate (~3.4 s) and the store's id index, built in one
    sorted insert when the download completes (~1.9 s); a bulk model load and building that
    index lazily (the open model knows every cell's row) are the next steps.
  - **P3/P4 on the CI machine:** R7 p95 11.4 ms (100 changes) and 250 ms (5,000 changes) on
    this desktop, 282 ms for P4 while other suites ran; re-measure on the CI machine.
  - **Not measured:** P2 (two instances need Redis), web (OPFS) for P6/P7/P8 (the web runs the
    cache's page writes as statements: `computeWithDatabase` needs the native worker), and the
    e2e P1 against `serverpod start`.
  - Resolved in R7 (client, spec 17 As built 24): P8 reopen from the cache (28.6–47.1 s →
    0.28–0.43 s, viewport-first), P6 on the client (1.44–2.0 → 0.89–1.12 s), P9 local import
    (30–32 → 17.3–18.6 s) and the cache size (695–733 → 107–108 MiB for 1M cells).
  - Resolved in R7 (wire and server, spec 17 As built 25): P7 server side (31.2 → 7.1–7.3 s;
    page format version 2, typed-array page reads, parallel pages decoded off the UI isolate),
    P10 import into a new file (63–69 → 37.6–38.0 s) and into an existing sheet (58 → 41–42 s;
    binary-array writes, in-place updates, creation prefetch from memory, one encoding per op),
    P4 (288–322 → 250 ms) and the cell table's `fillfactor` (85, P11 210 → 238 B).
- ☐ The generated client still carries the five client-database migrations of the CRDT era
  (`wonky_client/lib/migrations/`); no app opens that database any more. Remove them when the
  generator supports dropping the client database.

## Wonky Sheets — open items

Everything below is deferred; the app works without it. Areas are in rough priority order.

1. ☐ **Scripting UI — follow-ups** (Sheets 09 §23; autocomplete/hover docs, squiggles,
   Compare/Merge + local history, drafts, presence, live logs, persistent bytecode cache and
   execution queue, drag-reorder, *Help › Script API reference*, UI DSL sidebars/dialogs,
   *Enable scripts*, "Loading…" cells and the macro digit shortcuts are done; the editor, save,
   run, live logs, a custom function and an onOpen menu were checked live in the wasm build):
   `isolate_manager` is overridden to 6.x in `pubspec_overrides.yaml` so `re_editor` compiles
   to wasm — drop the override when re_editor allows 6.x; Tab does not accept a completion
   (re_editor binds only Enter), no signature help while typing arguments; `UiImage` of the UI
   DSL; a live look at completion popups, hover, sidebars and Mod+Alt+Shift+1 (item 2). The
   script editor's code font (GeistMono, synthesized italic for comments) intermittently drew
   wrong or missing glyphs in the wasm build (`///` as boxes, `=`/`<`/`-` gone, "@custom©nction"),
   gone after a reload — an engine-level issue, not reproduced on demand.
2. ☐ **Live verification leftovers** (phase 4 pass, see STATUS; the browser pane was hidden for
   the last part, so these were not reached): dark mode and ~400 px for the phase-4 features;
   slicers filtering a pivot; DV chip colors, smart chips and file chips; the bundled fonts in
   cells and print/PDF; display language (Function language: de); macro record + replay; script
   sidebars/dialogs and *Enable scripts*; two-tab presence, comments scope filter, offline
   comment queue, conflict review, version history author colors/download/copy; Explore panel,
   assistant empty state, AI not configured; import dialog tabs, print page-break dragging and
   the dark PDF option; scrolling a 50k-cell sheet. Not drivable in the automation browser:
   picking real files (Import CSV/XLSX, image over cells), XLSX/PDF downloads and pasting an
   image (the pane denies clipboard reads; the app now says so instead of "The clipboard is
   empty"). Also seen, not fixed: the menubar is clipped at 800 px when a script adds a menu
   (Help and the custom menu's popup go off-screen; the strip should scroll or overflow), and
   submenus opened from a menu at the right edge cover their parent instead of flipping left
   (shad's anchor only falls back vertically); a filter-view sort of 25k rows blocks the page
   for ~10 s; the open-spreadsheet skeleton still shows document lines.
3. ☐ **Large-sheet performance (CQ-40 leftovers)** — sync itself is RevLog now (see *RevLog
   sync — open items*): `SUM` over 1M rows takes 35–70 ms against a 10 ms budget (boxed
   doubles in `SUM`); structural edits take 33/65 ms against 16 ms (the range index rebuild and
   the formula scans on insert/delete).
4. ☐ **Editor** (LocalViewState, editing preferences, column autocomplete, formula preview,
   a11y semantics + announcer, context menu position, drag-copy cursor, `RangeInput` picking
   (also in the filter views panel), dark-mode automatic text, sort undo selection, side panel
   restore precedence are done): *low priority — large-sheet performance is deferred:* tile cache only if the release build misses the frame budget —
   decided by measurement: the VM test at 1M cells shows median 12.6–16 ms, p95 20–25 ms in
   debug JIT on a loaded machine (`test/features/grid/grid_performance_test.dart`); a release
   profile of the web build decides.
5. ☑ **Formatting** (phase 4): display language, server-created spreadsheet defaults and the
   theme preset fonts (Merriweather, Montserrat, Nunito, Source Sans 3 bundled; the mono presets
   use JetBrains Mono instead of Courier Prime) — see STATUS.
6. ☐ **Data tools** (the rest is done, see STATUS; view-only sort in filter views and `DataJobs`
   progress + cancel done in phase 4; a sorted filter view and the progress toast were checked
   live on 25k rows): a live check that slicers with *apply to pivot tables* filter pivots
   (`PivotOverlayService.slicerMask` reads the slicer JSON; both sides were built in parallel);
   *Cancel* of a running job (a 25k-row sort finishes in ~1 s, too fast to cancel by hand).
7. ☑ **Data validation & protection** (phase 4): chip colors via `WonkyColorPicker`, file chips,
   chips as rich runs in the cell layer — see STATUS. No place chips (optional).
8. ☑ **Pivot tables** (phase 4): incremental (delta) refresh for decomposable aggregates and the
   big-source snapshot in slices — see STATUS.
9. ☐ **Charts, images, objects** (phase 4 done, see STATUS): golden masters of
   `wonky_sheets/test/goldens/charts` must be generated on Linux (`tool/update_goldens.sh`, not committed yet); the
   GPU vs software comparison (`wonky_sheets/integration_test/chart3d_backends_test.dart`) needs
   a Flutter GPU device and was not run, and the GPU backend is still verified on the web only
   (live: GPU path active, orbit, Alt+Shift+arrows, hover, undo, all 3D types);
   image clipboard (paste, copy as PNG) on Windows/Linux desktop (web and macOS only); remote
   object outlines show a collaborator's primary selected object only; 3D trendlines are not
   drawn on horizontal 3D bars; ODS import doesn't read charts; image paste in the release
   build (the automation browser denies clipboard reads).
10. ☐ **Import / export / print** (*low priority — large-file performance is deferred*): server import jobs run in the instance that queued them (no
    worker pool); the parsed IR of a file is still held in memory whole (planning and writing
    are chunked, `IrToRowsPlanner.planChunked`).
11. ☐ **Collaboration & history** (conflict review + "your sort was replaced", comments scope
    filter, cut/paste anchor moves, offline comment queue, inline composer, show-changes command,
    per-cell author colors, server-side diff, version downloads, copy comments/sharing,
    `changedRangesJson`, objects in the version view, marching/hover flags, typing preview,
    agent cursors and the server version tests are done, see STATUS): partial-range sorts don't
    move comment anchors; PDF and server-side downloads of a version; *Your sort was replaced*
    finds the winner by the "Sort…" change label; the server-injected agent cursor and the app's
    external-write flash (item 12) may both show for the same MCP write; a live two-window check
    of the new presence/comment/conflict UI.
12. ☐ **MCP & AI** (rest): a live test with a real API key (no `anthropicApiKey` in
    `config/passwords.yaml`); `AI()` values are not persisted in a client `ComputedValueCache`
    (offline shows `#LOADING`) and `sheets.ai.refreshAiCells {ranges}` refreshes every call;
    `#AI_ERROR!` is shown as `#N/A` with the reason; `ui.sheets.describe_panel` cannot set
    selects/segmented controls (only text, checkbox, switch, buttons); PNG pixel-diff fixtures.
13. ☐ **Scripting engine** (job queue + worker role, rate limits, coalescing, failure
    notifications, fetch cache, chart/filter/protection/CF members, Lock/Cache services and
    `runLive` log streaming are done, 09 §23): web SharedArrayBuffer worker / snapshot mode
    (decision in 09 §8.2.1: not isolated yet — next step COOP same-origin + COEP
    credentialless on `/sheets/`, Safari stays inline); limits, locks and caches are per
    instance (Redis for several workers); `DriveApp`; `dart_eval` pins the workspace to
    `analyzer` 8.x (assessed: 93 errors in dart_eval + 15 in wonky_sheets_script against
    analyzer 13.3; needs a lockfile bump in a quiet window, 09 §23).
14. ◐ **Core**: chunked planning (`IrToRowsPlanner.planChunked`), CF/DV ranges and formulas
    on moves (06 §15.3) and charts without an Excel equivalent as XLSX pictures are done. Left:
    a cut with hidden rows (several blocks) moves a CF rule's formula with the first block's
    offset only.

## Wonky Drive — open items

- **Upload follow-ups from the CQ-60 tests:**
  - `UploadQueue` falls back to `DateTime.now` instead of `clock.now` (`wonky_drive` doesn't
    depend on `clock` yet).
  - The web XHR sender (`byte_sender_web.dart`) needs a browser test (`flutter test --platform chrome`).
- **M8 integration (D-18 follow-ups):** the web E2E runner (chromedriver + `flutter drive`,
  steps in specs/15 §9) and the J-D1…J-D10 `integration_test` journeys
  (`wonky_drive/integration_test/`) — the journeys were checked by hand in the release builds.
  Grid cards show a category icon, not the thumbnail of Drive 04 §10 (image previews,
  app thumbnails: `thumbnailFileId` is never displayed). `HEAD /files/d/…`
  answers without `content-type` and with `content-length: 0`. *Offline & device data* in
  Drive doesn't count queued uploads under *Changes waiting to sync*. Sheets'
  `decodeImageSize` (`features/images/image_service.dart`, unused) relies on
  `ImageDescriptor.encoded`, which has no size on the web — remove it or use
  `ImageDimensions`. Browser checks: the dev server's live-reload script (`/__dev/version`)
  reloads the release pages after every server reload, so long manual checks get reset while
  other agents edit server files.
- **Server files (D-8 follow-ups, Drive 02):** *Replace* / upload new version (P2, §9:
  `UploadConflictMode.replace` answers `unavailable`); chunked resumable uploads (P1, §4.3:
  `chunked` is ignored, the `PUT /files/upload` route answers 501 for `Content-Range` and takes
  only the URL token, not the session); multi-file ZIP downloads (P1, §8); per-instance
  download volume limit (2 GB/day, suite 13 §6) is not counted yet; HEIC/TIFF server previews
  (not rendered today); `drive.copy` of presentations waits for Slides (`DeckCopier`).
- **File previews (D-14 follow-ups, Drive 02 §6, Drive 04 §6):** (no PDF previews in v2 —
  user decision, Drive 02 §6.3.) Measure the image budget of suite 11 §2 in the release build
  (image ≤ 4 MB < 500 ms; only the text budget is measured, on the VM). Prev/next uses the
  file's folder, not the list the preview was opened from (search, starred, recent — the home
  should hand its visible list to the preview). P1: find in file (`Mod+F`),
  P2: audio player card (shown as the file
  card today). Desktop downloads (`PlatformFileDownloader` returns false off the web, A13). The
  TextMate engine is superlinear on big inputs (≈ 0.7 s / 100 K chars, ≈ 19 s / 500 K on the VM);
  the preview uses highlight.js beyond 50 K chars and highlights the first 250 K only — fix the
  engine (line-wise parsing) with `tokenizeLine` in M10.
- **Uploads (D-13 follow-ups, Drive 02 §3–4, Drive 04 §4):** checked live by D-18 (uploads,
  previews after upload, *Download*, pre-check dialog, offline queue → reconnect); a real OS
  drop still can't be automated (`webkitGetAsEntry()` is null for synthetic `DataTransfer`s).
  The upload panel is mounted by `WonkyAppConfig.wrap`, above the navigator, so it stays
  clickable over modal dialogs and, below `md`, covers the drawer's bottom section (settings,
  *Report a bug*, meter) — move it into the navigator overlay (a shell hook) or make it inert
  while a dialog or the drawer is open. Rows of files without a browser MIME type (e.g.
  `.dart`) show the generic file glyph in the panel (the list shows the code glyph after
  upload). P1: folder
  picker (`drive.upload.folder`, `webkitdirectory`), paste of files, OS drops on tree nodes and
  breadcrumbs, empty dropped folders, a progress ring in uploading list rows (they say
  "Uploading…"). `desktop_drop` (web) drops a whole drop when one item has no
  file entry (e.g. a dragged link). D-11's *Not enough storage for all files* dialog lays its three
  buttons out in one row above 640 px; with the test font they overflow the 464 px dialog
  (the D-13 widget test runs it at 360 px) — check with real fonts and long translations.
- **Storage page, Drive settings, commands (D-17 follow-ups, Drive 03 §6.4, Drive 04 §7–9,
  §13):** checked in the release build by D-18 (Storage page light/dark, live `storageChanged`
  banner updates, *Empty trash*); not checked: `drive.listByStorage` paging past 50 rows. The table sorts by counted size
  only (`drive.listByStorage` has no other order; the mockup's *Sort ▾* is not built). The
  *Free up space* counts read at most 200 rows per card ("More than 200 files"). *Duplicate
  files* (P1) and *Old file versions* (P2) cards are not built. The home's layout button and
  sort menu (shell) call `DriveController` directly; the `drive.view.*` commands wrap the same
  methods. `ui.drive.select_items` selects and focuses but does not scroll the home list to the
  row (the Storage table neither). *Convert uploads* converts after the upload completes
  (`drive.convertFile`, then the uploaded file is trashed and deleted forever) instead of a
  server-side import of an `importSource` upload (02 §7.3): it needs room for both copies for a
  moment, and after a reload the batch's undo trashes the deleted original instead of the
  converted item. *Confirm before moving items into shared folders* (P1) is not a setting yet
  (the confirm itself is P1). The list's *File size* column (shell `item_list.dart`) still shows
  `sizeBytes`, not `countedBytes` (03 §2).
- **Drive app scaffold (D-5 follow-ups):** the Drive web icons (`wonky_drive/web/icons/Icon-512.png`)
  are upscaled from the 256 px product icon (`icons/drive.webp`); replace them with renders of a
  512/1024 px master. The `slides`
  `flutter_apps` alias (8104) is added by SL-1 when `wonky_slides/` exists.
- **Shell v2 (D-10 follow-ups, suite 03 §3.3–3.4):** the server's `AppConfigRoute` doesn't
  serve `help.bugReportUrl` yet (`wonky.help.bugReportUrl`; the apps fall back to
  `https://github.com/serverpod/wonky/issues`). The drawer (below `md`) keeps the theme it opened with when the app
  theme changes while it is open (shad sheets capture the theme), and Esc doesn't close it after
  a menu inside it was closed with Esc (focus leaves the sheet). Drive's template gallery shows
  all templates by category (one *Blank* per kind), not the kind tabs of Drive 04 §1. The
  *Report a bug* footer link on the auth screens has no widget test.
- **Settings split (D-12 follow-ups, suite 04 §4):** *Sign-in & security* lacks the Google
  account link status / *Link Google account* (needs a server call listing the user's identity
  providers) and *Sign out of all devices* (P2). *Offline & device data* shows only the current
  app's device data, not the summary row per other app on this device. Write's *Page & export* defaults are stored but not all
  applied: new documents apply the default layout (T-1) but ignore the saved page setup, and the
  export dialog doesn't preselect the default format (as in v1). The `/settings/sheets` hand-over from
  Write and the `/settings/write` redirect were checked in the browser (D-18); the
  *Settings of other apps* links were not clicked.
- **Shared chart packages (D-3 follow-ups, SL-27 in M10, Slides 08 §2.7, §2.10):** `ChartData`
  JSON, `ChartSnapshot`, `ChartRevealState`, `ChartSceneMorph`, `Chart3DView.lerp`, `ChartTable`
  + the generic recommender split, `TtfTextMeasurer`, a pluggable range-ref validator for
  `ChartSpecSchema` (Slides: no ranges), deck-theme `background`/`text` in `ChartThemeSource`;
  move `ChartView` (generic part), the data table dialog, `ChartTypeIcon` and the Customize-tab
  `ChartStyleEditor` from `wonky_sheets` into `wonky_charts_flutter`. The workbook-based layout,
  3D and describer tests stay in `wonky_sheets_core`; port some to `ChartData` fixtures in
  `wonky_charts/test`. Sheets chart golden PNGs (`wonky_sheets/test/goldens/charts`) have no
  committed masters yet (`tool/update_goldens.sh`; `goldens.yml` compares them once committed).
- **Shared code packages (D-2 follow-ups, M10 with Slides code elements, Slides 07):**
  `CodeTokenizer.tokenizeLine` (incremental line state for type-in/editing), `CodeLayout` +
  `MonoFontMetrics`, the grid-exact `CodeView` mode driven by `CodeViewState` (title tab,
  callouts, dimming, caret), `CodeEditorField` (re_editor) and `CodePaletteResolver`;
  `CodeLanguages.detect` (P1). Write's exports and editor use `DefaultCodeTokenizer` since
  SL-35; still open: Write's code language menu (`codeLanguageEntries` in
  `wonky_write/lib/features/screen/document_menus.dart`, Write 05 §9.4) offers only the 15
  TextMate languages — offer `CodeLanguages.pickerLanguages` (the highlight.js ones are
  highlighted now, but can only be chosen by typing a fence).
- **TextMate tokenizer speed:** see "Code core leftovers (SL-26)" below (≈ 17–19 ms for 1,000
  lines of Dart after SH-6; budget 15 ms desktop / 30 ms web).
- **Shared rich text, fonts, spelling, emoji (D-7 follow-ups):** Sheets loads the `wonky_fonts`
  package assets since CQ-64g (its copy of the 40 TTFs is gone; `CellFonts`, `print_fonts.dart`); the
  server keeps its mirror (`wonky_server/web/fonts/`, `FileSystemFontProvider`; Sheets' `bundled_fonts_test` checks it matches); switch it to the
  `wonky_fonts` package (`BundledFonts`) and drop the copy (check that the Cloud upload includes it;
  suite 01 §2.1). The shared Flutter `AssetFontRegistry` + `BundledAssetFontProvider`
  (`package:wonky_app/fonts.dart`, SL-6) exist; Write (`WriteFonts`/`AssetFontProvider`) and
  Sheets still use their own loaders — switch them when convenient. (The shared spelling dialogs,
  emoji picker and — moved from Write by SL-44 — special characters dialog read their strings
  from the `wonky_app` ARB files and take an app key prefix: Write keeps `write.*`, Slides uses
  `slides.*`.) `EmojiPrefs` keeps its `write.emoji.*` store keys and the special characters
  recents `write.specialChars.recent` (recents shared by the apps); the emoji and special
  character category names come from the asset data (English). The personal dictionary is the
  shared `PersonalDictionary` list, still stored as `writeDefaults.personalDictionary` — move it
  to a suite-wide preferences field when a migration touches `UserPreferences`.
- **Storage quota (D-9 follow-ups, Drive 03 §11):** (spreadsheets now use a compact content
  estimate — user decision, Drive 03 §11; existing sizes are corrected by the nightly
  reconcile.) Repeat the backfill dry run on a production copy before the first v2 deploy
  (also time the nightly spreadsheet re-estimate there). Slides' `SlidesSizeEstimator` still
  sums `pg_column_size`: a new empty deck costs ~18 KB (theme, master, layouts) — switch it to
  a content estimate like Sheets' (`SpaceSizeEstimator.rowBytes`/`baseBytes`) if that
  matters. The weekly orphan-image cleanup that subtracts
  unreferenced images (03 §2) doesn't exist; images stored by a failed MCP `write.insert_image`
  mutation or a cancelled import stay charged until then. Spreadsheet imports check only the
  source size before work (the real size is the estimate after creation). No admin tool for
  `quotaBytesOverride` (P2).
- **Shell storage UI (D-11 follow-ups, Drive 03 §6.3–6.5):** not built yet: the *From
  template* tooltip "Not enough storage" with disabled templates (`TemplateView.sizeBytes`), the
  copy dialog's disabled *OK* "Not enough storage (needs 6.1 MB)" (the copy command pre-checks
  and shows the dialog instead), the details panel's "Counts against Anna Berg's storage", and the
  upload panel's "Not uploaded — you're out of storage" rows (D-13). Ownership-transfer
  dialogs use the presenter's generic mapping (`reason: transfer`); the share dialog's own
  error display was not switched to it. Golden masters of the meter/banner/dialogs are made on
  CI (specs/15 §7). (Meter, banners and the *Out of storage* dialog were checked in the
  browser by D-18.)
- **Write & Sheets adaptations (D-16 follow-ups):** D-18 checked `/sheets/import` (CSV →
  spreadsheet in the file's folder, browser Back → Drive), the flipped homes and the Write
  image pre-check in the browser; not yet: *Open with* → `/write/import`, *Cancel* going back
  to Drive (`history.back`) and File › New ▸ *Presentation* (Slides `/new`). Write's
  `/import` has no options dialog (Write imports have none; the server pipeline's defaults
  apply). Sheets' `/import` loads the whole file into the browser for the dialog's preview
  (large files are slow to analyze there; the conversion itself runs on the server). Images
  refused on quota: background (queue) refusals show only the placeholder, not the *Out of
  storage* dialog; Sheets in-cell `IMAGE()` images show no "Not uploaded" state; the refusal is
  not persisted, so after a reload the queue tries once more (and is refused again). Write's
  *Page & export* defaults (D-12 follow-up) are still not applied to new documents (needs the
  page setup written at creation, also for offline-created documents).
- **MCP & AI for Drive (D-15 follow-ups, suite 09 §4–§6, suite 10 §3.1):**
  (`drive.create_presentation`, the `slides:*` scopes and `drive.export` of presentations: done,
  SL-40.) The `ui.drive.*`
  window handlers (D-17, `wonky_drive/lib/mcp/`) are tested in the window only; a relay test
  through `/mcp` with a live Drive window is still open (needs a developer token in the
  browser profile; not done in D-18). The
  Drive assistant (P1: drive-scoped threads, the restricted tool list of suite 10 §3.1 — the
  current `AssistantToolset` binds `uuid` to the open file, so it needs a drive variant — the
  folder/selection context builder and `drive.ai.askAboutItem`) is planned with M11. Resource
  subscriptions for `wonky://file/<uuid>` / `wonky://drive/storage` follow the suite-wide
  subscription work. `wonky://file` lists the 50 most recently modified files only.

## Wonky Slides — later

**Wonky Slides is complete for its first iteration** (M9 closed with SL-23, M10 with SL-36, M11
with SL-45 on 2026-10-15; exit checklists in [specs/14-roadmap.md](specs/14-roadmap.md) §2.1,
evidence in [specs/wonky_slides/STATUS.md](specs/wonky_slides/STATUS.md)). Slides **only shows
what works**: what is not built is hidden. Below are the real leftovers of the first iteration —
hidden features, the on-hold work package SL-41, P1/P2 items and the checks that are still
missing. Per-package leftovers of the built areas (canvas, text, shapes, images and tables,
navigator, themes, presenting, PDF, code core, …) are in "Wonky Slides — open items" below.

**How hidden features come back.** `wonky_slides/lib/config/slides_features.dart` has one
`SlidesFeature` value per hidden area and `SlidesFeatures.shipped`. While a feature is off its
commands — real ones and the disabled `placeholder_commands.dart` entries — are not registered
(so menus, toolbar, context menus, palette, shortcuts and MCP `ui.*` don't offer them; menus and
context menus are pruned with `SlidesFeatures.prune`), the inspector drops its sections, and its
settings are neither shown nor advertised (`offersDefaultsKey`). A work package turns its feature
on by adding it to `SlidesFeatures.shipped`, registering real commands (its placeholders then
drop out), giving its inspector sections a builder, and updating
`test/config/menu_registry_test.dart` (golden ids) and the tests that assert the hidden state
(`chrome_commands_test`, `deck_editor_screen_test`, `slides_settings_test`,
`clipboard_commands_test`). Remove a `SlidesFeature` value once its feature ships.

### Hidden features (still off)

| `SlidesFeature` | What | Priority / spec |
|-----------------|------|-----------------|
| `remoteAndRehearse` | Phone remote, rehearse timings, same-browser fast path, *Freeze audience* | **On hold** (SL-41, below) |
| `nativeCharts` | *Insert › Chart › Column / Bar / …* from a small data table, the chart data panel, *Convert to native* (`ChartTable`, `TableChartData.fromTable`, recommender split, "no ranges" `RangeRefSchema` validator) | P1, 08 §11 |
| `importSlides` | *Import slides…* from another deck | P1, 04 §13.9 |
| `aiCodeWalkthrough` | *Make a code walkthrough…* (needs `UnifiedDiff` / `WalkthroughBuilder`, 07 §10.2; also MCP `slides.code_walkthrough_from_diff`) | 11 §6.9 |
| `editorPreferences` | Units, scroll changes slides, smart quotes, autoformat lists (SL-13 leftovers) | 04 §13.16 |
| `notificationSettings` | Slides notification settings | suite 07 |
| `markdownExport` | *Download ▸ Outline as Markdown* | P2, 04 §10 |
| `snapGrid` | Snap to grid | P2, 03 §5.3 |

Not a feature switch but also not offered: canvas motion-path editing (drag the end dot, vertex
edit mode, *Draw path* — `slides.animate.drawMotionPath` / `editMotionPath` are not registered;
numeric `moveTo` fields only) and the *Set end state* ghost of `moveTo` (06 §5).

### On hold: SL-41

- **SL-41 · Phone remote, rehearse, same-browser fast path — On hold (user decision
  2026-10-15)** (10 §5.2, §6.4, §10; deps SL-19 ✓, SL-29 ✓). Feature `remoteAndRehearse`
  stays **off** (not in `SlidesFeatures.shipped`; *Rehearse* and *Use phone as remote* are
  hidden, their placeholders in `placeholder_commands.dart` remain).
  - **In place (tested):** server pairing in `wonky_server/lib/src/slides/present/` —
    non-table models `PresentationPairingUpdate {revoke?}` (presenter asks for a key),
    `PresentationPairingEvent {pairingKey, code, expiresAtMs}`, `PresentationPairingTarget
    {deckUuid, sessionId, pairingKey}`, bus fields `pairingKey`/`admitted`; the presenter
    connection issues single-use 128-bit keys + six-digit codes (10 min,
    `PresentationService.pairingTtl`; a new request revokes unused ones), admits a `remote`
    of another account (≥ viewer) whose `hello` carries a valid key, and re-admits paired
    accounts on reconnect (also after a presenter rejoin); refusals end with `noAccess` (no
    key) or `pairingExpired`; `presentation.resolvePairingCode(code)` (answered on
    `present-code:<code>`, ≥ viewer, 10 tries/min per user). Tests:
    `wonky_server/test/integration/slides/presentation_pairing_test.dart` (8). Client:
    `PresentationTransport.resolvePairingCode` (+ the fake hub issues pairings); the
    same-browser channel `wonky_slides/lib/features/present/broadcast/`
    (`PresentChannel` — `BroadcastChannel` on the web, `MemoryPresentChannel` elsewhere —
    and `PresentFastPath`: presenter posts state/laser/ink/end, members post commands,
    pings for liveness, local times mapped to server time), tested in
    `test/features/present/present_fast_path_test.dart` (5) but **not wired** into
    `PresentationLink` yet. (Also fixed: a presenter that never joined stays `offline`
    while it retries, instead of flickering to `reconnecting`.)
  - **Left:** (1) fast path wiring in `PresentationLink`: open `PresentFastPath` after the
    first welcome, post every `send` over it too, tag commands with an `_id` in `argsJson`
    and drop duplicates on the presenter, drop the server's laser/ink echoes while the local
    presenter is live, `fastPathLive`/`canSend` for the UI (the audience's "Connecting…"
    pill), no `end` after `takenOver`; a test hook that drops the stream while
    `ConnectivityService.forcedOffline` (plus a `slides.offline.simulate` developer command
    for browser checks); acceptance: a pair keeps running through a 10 s drop. A first
    wiring was written and backed out (unverified). (2) Phone remote UI: the `remote` editor
    child route (`/p/:uuid/remote?session=&key=`, `RemoteController` over the link with
    role `remote` — state, timer, sequence, next preview — and a 360 px `RemoteScreen`: top
    bar with elapsed/slide n of N/connection dot, current slide at its step, next preview,
    notes with A−/A+, 96 px Previous/Next, swipes, long-press laser (a new `laser` command
    in `PresentController.applyCommand`, ≤ 12 Hz), black screen, `navigator.vibrate`,
    Screen Wake Lock, "Reconnecting…" disables the buttons, ended/expired/no-access
    states); the presenter's *Use your phone as a remote* dialog (QR of the remote link,
    the code, expiry countdown, *New code*, paired devices from the roster, MCP-describable)
    from the presenter view header, the Present menu (`slides.present.remote`, from the
    editor via `?remote=1`); a `/remote` app route to type the code
    (`resolvePairingCode`); `slides.remote.*` commands. (3) Rehearse: `?rehearse=1`, a
    recorder of per-step times (completed slides only), the HUD (top-left / bar above the
    presenter view), `PresentController` rehearsing mode (no auto-advance, loop, kiosk or
    exit end behavior), the "Keep the new timings?" dialog (`WonkyDialogSpec` with *Advance
    automatically with these timings*), `slides.present.saveTimings` (one undo step "Record
    timings", `SetSlideProps.timingsJson` per slide + `presentJson.useRehearsedTimings`),
    `slides.slide.clearTimings` (Slide menu). (4) *Freeze audience* (`PresentController`:
    publish nothing while frozen, resend state + ink on unfreeze; presenter view control
    and command). (5) ARB strings, widget tests (360 px, light/dark, keyboard), browser
    checks (phone tab at 375 px, 10 s drop), 10 AC 9 and 11. Then turn the feature on,
    drop the two placeholders and update `menu_registry_test` / the hidden-feature tests.
  - **Resume:** re-read 10 §5.2/§6.4/§6.6/§10 and the pairing tests; SL-37 added
    `PresentView.follower` to the present controller/screen (keep edits in separate blocks).

### P1 leftovers (marked P1 in the specs)

- **Motion (06, 10):** interpolate same-type shape adjustments, gradient stops, shadows, corner
  radius and stroke width in Magic Move (06 §8.4; today stretch or crossfade); kiosk
  `allowNavigation` and idle restart; the navigator's builds/transition glyphs (04 §5); dragging
  timing bars, a preview scrubber and presence in the Animate tab header.
- **Code (07):** source file drop onto the canvas.
- **Charts (08):** the push stream `slidesCharts.watch(deckUuid)` (08 §5.3); native charts (see
  hidden features).
- **Export (10):** *Copy slide as image* (`slides.slide.copyAsImage`).
- **History (09):** *Side by side* (`slides.history.toggleSideBySide`).
- **MCP (11):** `slides.update_theme`, `slides.copy_slides_to_deck`,
  `slides.insert_native_chart`, `slides.set_chart_data`; `==highlight==` in the Markdown codec.
- **AI (11, suite 10):** the **Drive assistant** (suite 10 §3.1) — drive-scoped threads
  (`AssistantThread.itemId = null`), a `DriveAssistantTarget` with the `drive.*` tool set (trash
  with confirmation, never delete forever/empty trash/sharing), the ✨ button in the Drive top
  bar + `Mod+J` + palette, one undo step per run on the shell stack (needs server change records
  for drive ops), quick prompts, *Ask the assistant about this file*; the slide image for design
  tasks.
- **Import slides** (see hidden features).

### P2 leftovers

The presenter view's notes auto-scroll per step; the code type-in sound (setting hidden);
*Download ▸ Outline as Markdown*; *Re-anchor to selection* for orphaned comment threads; the
server diff cache for decks > 20 MB (`SlidesVersionEndpoint.diff`); snap to grid; the `date`
placeholder (05 §4).

### Other leftovers (no priority in the specs)

- **Motion:** exact glyph boxes through `MagicMoveText.rangeBox`; glyph runs for shapes with
  text, table cells by row/column and a persistent transform of an outgoing group in Magic Move;
  the core should carry `dimColor` during the running dim effect and a reduced-motion crossfade
  for "instant" persistent emphasis; screen-reader announcements of built content and code
  changes while presenting (06 §17, 10 §16); chart hover tooltips and orbit while presenting
  (`interactive.hoverTooltips/orbitInPresent` are stored); a telemetry event for
  `slides.motion.degraded`; a dissolve/mask `FragmentProgram`; GPU 3D transitions on desktop
  builds. Animate tab: the easing curve editor (*Custom…* Bézier handles and spring sliders),
  build tile previews inside the tile, F2 rename from the Order list, build order badges for
  group children, writing `Deck.defaultsJson.build`, the 06 §14 blur-budget warning,
  `chartHighlight` targets by point; "double-click keeps the animation painter active".
- **Code UI (07 §2.3 "Status (M10, SL-31)"):** *Pick lines…* canvas mode, the paste chip *Paste
  as code block* and ```` ``` ```` + Enter in an empty text box, language/palette chips inside
  the box, dragging and double-click editing of callouts on the canvas, live auto-size re-fit per
  keystroke, recent languages per user (per session now), wide-grapheme (CJK) centering, code
  canvas semantics ("Code block, Dart, 24 lines…"), the copy button in the shared viewer and with
  `copyButton: always`; the Tech talk template's type-in deletes most of the old code before
  typing (smaller edit scripts per line, 07 §5.2).
- **Charts:** the link badge on hover, the Linked charts panel's rail count badge, *Request
  access* / *Open in Drive* actions of 08 §6, dropping overrides that don't apply after relinking
  to another chart type, a list of camera steps in Inspector › Chart, the Sheets route
  `?object=<id>` (A-08-7), Sheets' Customize tab on the shared `ChartStyleEditor`; the scorecard
  count-up of chart builds; token detection misses server writes that bypass the Sheets change
  log; server-side auto-update (Q28, only if needed); template charts are static snapshots.
- **PDF / PNG:** the server `SlideRasterRenderer` (10 §13) and `slidesExport` `png`/`pngZip` —
  MCP `slides.render_slide` and `drive.export png` answer `unsupported` until then; PNG export
  progress and *Cancel*; running (non-settled) frame states in PDF (blur, wipe/iris clips,
  dissolves, partial line drawing, code transitions); code callout shadows in PDF; PNGs of decks
  with images not yet cached offline wait for their downloads.
- **Outline view, Layers, checker (SL-34):** empty slide groups aren't listed in the outline;
  no selection across outline lines; ⌘B/⌘I don't format in outline lines; the *Reading order*
  tab orders top-level elements only; a multi-selection dragged across parents lands under one
  parent; rotated/flipped groups aren't refitted; the checker doesn't check table cells, code,
  chart text or text over images; move `AccessibilityChecker` to `wonky_slides_core` for a
  headless `slides.check_accessibility` tool.
- **Templates:** decks are built in English only; Portfolio's covers are shapes (images would
  need bundled uploads and a quota story); the Magic Move pairs repeat their title (checker
  warning); the gallery card shows the first slide only.
- **Collaboration (09 §2):** see "Collaboration leftovers (SL-21/SL-37)" in the open items.
- **Comments (09 §3.7):** headless `comments.*` MCP tools with Slides anchors
  (`{"slide": 4, "element": …}`, results with `slideNumber`/`elementLabel`/`orphaned`, 09 §8);
  *Comment on presentation* (`document` anchor) has no button in the panel; the navigator row's
  semantics label doesn't include the comment count; a pin docks the first of its threads only
  (switch threads in the panel); scenario 30 of 09 §6.4 needs the multi-client harness.
- **History (09 §4.7):** the read-only master/layout view of a theme change and the faint
  outlines of inherited changes; text diffs show inline, not as a hover popover; activity says
  "3 slides · 1 slide deleted · theme changed · with Claude", not slide numbers and group names;
  MCP `versions.get(format: "outline" | "diff")` for decks (core `DeckDiff`/`SnapshotSlideEntry`
  and `slidesVersion.changes` are ready); files referenced only by retained versions are not
  protected from Drive's garbage collection (A-09-6); the overwritten-text review doesn't track
  code states.
- **MCP (11 §2–§4):** tool/command row-parity tests (11 AC 2); `text_overflow` uses the core's
  approximate metrics (load a `TtfFaceSet` like the PDF export); `https` image URLs through the
  image proxy (11 §3.8); the conditional server-side chart auto-update index (08 §5.5).
- **UI bridge (11 §5):** `describe_panel`/`set_panel_field` read and set only text inputs,
  checkboxes, switches and buttons (selects, colors, sliders and segmented controls need the
  `slides.*` commands); shell dialogs still not MCP-describable (all apps): share dialog,
  command palette / quick switcher, undo history, *Report a bug*, *What's new*, session expired;
  the server's agent participant and the client flash may both outline the same elements after a
  headless write; agent steps through `ui.invoke_command` are labelled "AI: …" on the undo stack.
- **AI (11 §6.12):** `comments.list/create/reply`, `versions.list` and the `ui.slides.*` window
  tools in the assistant's tool set; *Show differences* in the AI changes preview; the client
  flash for the user's own assistant runs; Generate presentation: the *Wonky Write document*
  source, the *Theme* choice, Home *New ▸ Generate with AI*, drag-reorder in the outline, the
  "(cont.)" overflow split, *Design ideas* after generation, title text boxes for
  `bigNumber`/`quote` slides; Rewrite: the canvas preview overlay with *Show changes*, rewriting a
  selected range, *Translate ▸* languages, word-diff style keeping; Design ideas: content
  arrangements (cards grid, timeline, image left/right/full-bleed, quote emphasis), live hover
  preview, `text_tweaks`, the toolbar *Layout ▾* footer; *Animate this slide* (11 §6.10) and §6.11
  (proofread, translate, shorten, summarize presentation); the nightly eval suite.
- **Suite (found in the SL-45 walkthrough):** the emoji picker lists Emoji 15.1 sequences
  (e.g. *head shaking*) that the web engine's emoji fallback font draws as their components —
  limit the bundled table (`wonky_write/tool/unicode/gen_emoji.py`) to what the fallback font
  covers; a context menu that is open while a menubar menu opens stays open until the next
  click on the canvas (shad's shared context-menu tap group).

### Not verified / test infrastructure

- `integration_test` journeys J-S1…J-S10 and journey 15 on the web (no chromedriver on the
  development machine; runner steps in specs/15 §9).
- The scripted multi-client harness with `serverpod_test` isolates (12 §7.3) for the 09 §6.4
  scenarios (today: replica-level sync tests and the collab widget tests), and the offline merge
  fuzzer for decks.
- Perf budgets of 03 §18 on the web and 60 fps transitions/type-in with recorded frame timings
  (`wonky_slides/benchmark/motion_bench.dart` runs by hand; make it a `-t slow` test with
  `FrameTiming` p95 assertions and a web variant in the E2E job).
- The PDF raster corpus with `pdftoppm` (needs poppler in CI); pixel goldens of edit-mode parity
  for code (CI golden container).
- flutter_driver + MCP checks of every `ui.slides.*` tool against a running app (11 §11).
- Browser items not walked through in SL-45 (see the M11 checklist): the AI flows with a real
  provider (none is configured on the development server), clipboard paste in the browser (the
  agent's pane can't grant clipboard read), keyboard shortcuts (the pane's synthetic Cmd keys),
  connector route-handle drags and the image adjustment preview with a real mouse, reduced
  motion, laser/pen/kiosk, PNG/PDF downloads, @mention notifications and comment deep links,
  the `ui.slides.*` tools through an MCP client, a screen-reader pass.
- One crash of the Slides wasm build in the agent's Browser pane (`RuntimeError: memory access
  out of bounds`, the page stopped responding) after many viewport-emulation changes and two
  rebuilds of the same output folder; not reproduced afterwards — watch for it (a skwasm/engine
  issue or a renderer leak).

## Wonky Slides — open items

Status per work package: [specs/wonky_slides/STATUS.md](specs/wonky_slides/STATUS.md).

- **Spelling, special characters, route handles leftovers (SL-44, Slides 03 §14.1):**
  - Checked in the SL-45 release build: squiggles on the canvas and in the text overlay, the
    right-click suggestions on the canvas, the Check spelling dialog (Change, Ignore all, slide
    navigation), Special characters and Emoji typing into canvas text. Not checked in a browser:
    squiggles in notes and outline lines, squiggles while an IME composes (the outline hides
    them while composing).
  - The Check spelling dialog selects the word's object (or opens the notes) instead of
    selecting the word in the text editor (it would take the keyboard from the modal dialog);
    there is no *Next error* shortcut (Write's ⌘') and no *Ignore UPPERCASE* switch (ALL-CAPS
    words are always skipped).
  - Not checked: code elements, chart text, master/layout text (masters mode), group titles;
    per-paragraph languages are not supported (spec). Canvas squiggles are painted on the
    overlay (above objects that overlap the text) and hidden while objects are dragged.
  - Emoji and special characters type into the canvas text only: not into the notes or outline
    lines (*Insert* there makes an emoji object / is disabled); the `:shortcode` emoji trigger of
    Write's editor isn't in the Slides text overlay.
  - Route handles: only top-level connectors (not inside groups); the first and last segments
    of an elbow route (attached to the sites) have no handle; moving an endpoint clears edited
    waypoints instead of keeping them relative; glued connectors still re-route only on drop
    while a shape is dragged (SL-12 note); the handles have no keyboard equivalent (agents and
    the palette-less command take `waypoints`).
  - Desktop (disabled for v2): a right-click in an outline line would show shad's text toolbar
    next to the spelling menu.

- **Display fonts (SL-6, Slides 05 §3.2, §6):** only the 10 families of `wonky_fonts` are
  bundled, so the built-in themes ship with substitutes (Open Sans, EB Garamond, Lato, Roboto,
  Nunito, Montserrat, Merriweather, Source Sans 3, JetBrains Mono, Roboto Mono). Bundle static
  TTF instances (OFL) of Inter, Work Sans, IBM Plex Sans/Mono, Source Serif 4 and the display
  families (Instrument Serif, Space Grotesk, Sora, Manrope, Bricolage Grotesque, Fraunces;
  P1: Bebas Neue, DM Serif Display) into `packages/wonky_fonts/fonts/` (+ manifest, licenses,
  mirror in `wonky_server/web/fonts/`, `SlidesFonts` categories), then move the built-ins to the
  designed fonts with a version bump (`builtin:<key>@2`).
- **Collaboration leftovers (SL-21/SL-37, 09 §2.5–§2.6):** text hints send the full body only
  (no Delta `diff` + `baseHash` for bodies over 4 KB; over 16 KB nothing is sent) and only for
  element bodies (table cells and notes are claimed but not hinted); the outline view's lines
  don't show others' live text hints (they update after the sync); live pointers ride the
  presence cursor throttle (10/s instead of 20/s) and have no a11y setting of their own ("Reduce
  collaborator cursors" — the View toggle is the switch); the presenter view doesn't count
  followers (the server's roster has them; the device list filters them out); outline claims are
  always forced (no soft-lock question or race prompt in the outline); checked in the SL-45
  release build with two tabs of one user: live pointer with name tag, presence avatar and
  selection outline, soft-lock banner and *Edit anyway* popover, live text hint, *… is presenting
  · Follow*, the follower view following the presenter and *Stop following*, the Present live
  dot (dark, desktop); not checked: pointer smoothness with a real mouse, the follower view full
  screen, the structure shimmer.
- **Date placeholder (P2, 05 §4):** the built-in masters have no `date` placeholder yet.
- **Built-in prompts are English** (`Click to add title`, …) and stored in the copied layout
  rows; localize them when a built-in is copied into a deck (planner `ThemeCopy`), or render prompts of built-in
  part keys from the app's ARB strings (not done in SL-13).
- **Chrome leftovers (SL-11, Slides 04 §19):**
  - The canvas, navigator, notes pane, grid and outline views are shells on the static
    `SlidePreview` (`features/editor_screen/slide_preview.dart`): SL-12 swaps the canvas body
    in `canvas_region.dart` for SL-10's `SlideStage` + selection (the outline shell is gone:
    SL-34's `OutlineView`); delete `SlidePreview` once nothing uses it. (Navigator, notes and grid: done, SL-16.)
  - (Placeholders: since SL-23 the remaining placeholder commands
    (`commands/placeholder_commands.dart`, each names its WP) and the inspector sections without
    a `builder` are hidden, not shown disabled — "Wonky Slides — later" above.)
  - Home thumbnails (04 §15: first non-skipped slide rendered after an editing session,
    `drive.setThumbnail`) need SL-10's renderer and the files upload — not built.
  - 04 §16 at 1,200–1,440 px: collapsing the docked inspector to a 44 px tab strip while a side
    panel is open; the narrow navigator drawer should open from the title row (needs a left
    app slot in `EditorScaffold`).
  - Keyboard: menu mnemonics (Alt+letter, 04 §4.11) come from the shell menubar.
  - (MCP UI tools and context menus over MCP: done, SL-42 — `ui.slides.get_context_menu`.)
  - The browser check of SL-11 stopped at the home: the running dev server had no `slides`
    endpoint (stale `serverpod start`); open a deck from the home in the next release check.
- **Navigator, groups, grid, notes leftovers (SL-16, Slides 04 §5, §8, §9):**
  - Slide-row badges: builds ⚡ and transition glyphs (P1, SL-30). (Open comment count: done,
    SL-38; presence dots: SL-21.)
  - Speaker notes soft lock ("Anna is editing these notes", 02 §4.4) — SL-21. (Find & replace
    in notes: done, SL-18.)
  - (Cross-deck re-homing of uploaded files, the web Clipboard API representation and the
    paste options chip: done, SL-18.)
  - P1 drops: canvas elements onto a slide row (03 §4.1), OS image files onto/between rows.
  - The dragged group header is dimmed during a drag (04 §5.10 says "collapses visually");
    rows are `Semantics` buttons with `expanded`/`selected` and full labels, not tree items
    (no tree role in this Flutter version).
  - (Pasting Slides payloads copied in another browser tab: done, SL-18 — the payload travels
    embedded in the clipboard HTML.)
- **Contract stubs of SL-3 to replace:** (`HarnessDeckDocument` gave way to SL-11's
  `DeckDocumentController` + `DeckEditorController` in `DeckHarness`.) `CodeScene` (filled by SL-26) and the timeline stub
  (`motion.dart`, replaced by SL-24) were minimal on purpose. The in-memory
  `LwwSyncRelay` is a skeleton; SL-9 added the replica-level harness
  (`wonky_slides/test/sync/support/`: replicas, in-process sync peer, devices).
  (`SlidesPlanner` is now the default of `DeckHarness` and `MemoryDeckSession.blank`;
  `FakeSlidesPlanner` stays for session contract tests.)
- **Core model and planner leftovers (SL-7):** the Slides text schema is `SlidesText`
  (`wonky_slides_core/model.dart`, `lib/src/model/text/`) — SL-8 adds the
  `SlidesDeltaValidator`/`SlidesDeltaNormalizer` names (02 §4.1) on top of it in `core/text/`
  (done, SL-8). Paste (`PasteSlides`/`PasteElements`, 03 §12.2 payload) keeps
  `wonky-file://` sources as they are: the client calls `SlidesClipboardCodec.rehomeFiles` for
  cross-deck pastes and queues `file.copyToItem` (done, SL-18's `SlidesRehomeQueue`). Auto-fit scales and connector routes are
  derived by SL-10's scene layer (on `SlideScene`, not on `ResolvedElement`). The order index treats
  every slide group as top-level (nested groups are P2, 02 §3.4). Maintenance must be
  *scheduled*: `SyncedDeckSession` runs `DeckMaintenance.repairOp(model)` after merges
  (debounced 1 s, SL-9) and the headless deck before every server write (SL-8, not recorded). Build, code-state
  and chart-link operations are planned at row level with basic validation; effect catalogs,
  `optionsJson`/annotation schemas and chart behavior are validated by SL-24/SL-26/SL-27. Undo
  labels of plans are English (as Sheets'); localize with the shell's undo labels if needed.
  The server's `DeckFactory` plans `CreateDeck` with `SlidesPlanner` (SL-8).
- **Images and tables leftovers (SL-15, Slides 03 §6.5–§6.6, §6.12):**
  - No persistent image cache yet (Sheets has `SheetsImageBlobCache`): an image uploaded from
    this device is downloaded again after a reload, and offline after a reload only images
    still in the upload queue render. Add a per-user blob cache under `features/uploads/`.
  - (Adjustment sliders preview live on the canvas: done, SL-44.) The URL dialog has no
    preview (04 §13.2); animated GIFs draw their first frame on the canvas; downscaled
    > 40 MP images are re-encoded as PNG (not JPEG q 0.9); SVG originals are not kept (P2).
  - Mask: the mask shape's adjust handles (`maskAdjust`) aren't on the canvas; crop mode shows
    the rectangular crop box, not the mask outline.
  - Tables: merging keeps the covered cells' text hidden instead of concatenating it (Google
    concatenates); Up/Down at text edges use paragraphs, not visual lines; typing into a
    selected cell appends (Google replaces the content); `setBorders {edges: none}` clears
    the cell borders but not the table style's (use *Style: None*); dragging a row border
    sets the row's minimum height only. (Cell copy/cut/paste and pasting TSV/Sheets ranges
    into cells: done, SL-18.)
  - The Drive picker lists recently opened image files plus search (no folder browsing);
    (pasting OS images with `shell.edit.paste`: done, SL-18); drag & drop and clipboard
    images are web only (desktop disabled, suite 01 A13).
  - Table cell soft locks (two people typing in one cell) follow SL-21's text locks — cells
    are not claimed yet.
- **Client sync leftovers:** the full multi-client harness with `serverpod_test` and isolates
  (12 §7.3) remains for the scripted scenarios of 09 §6.4 (RevLog has in-process fakes:
  `FakeRevServer`, `FakeRevTransport`).
- **Scene and stage leftovers (SL-10):** the core `SlideTextLayout` defaults to
  `ApproxTextMeasurer`; SL-20 added `TtfTextMeasurer` (`package:wonky_slides_core/pdf.dart`,
  real TTF metrics, used by PDF exports) — the MCP overflow warnings (SL-40) still use the
  approximate measurer and should load a `TtfFaceSet` too; the core engine lays out `justify` as `left`,
  right-aligns RTL paragraphs without bidi reordering and renders small caps as all caps; the
  Flutter engine scales super/subscripts but doesn't shift their baseline (`dart:ui` has no
  baseline offset — use a placeholder span or font features). (Lucide icons: done in SL-14 —
  `LucideIconSource` is every `SlideRenderer`'s default.) (Charts: every `SlideRenderer`
  lays them out with `SlideChartLayout`, SL-32.) Code uses `BasicCodeLayout` until SL-26's
  `CodeElementModel` (highlight steps, window chrome, `palette: auto` by background). The
  stage draws every motion frame field since SL-29 (06 §12.4); off-slide content at
  40 % is used by SL-12's canvas (`SlideStage.offSlideOpacity`). Shadow spread is
  approximated by scaling the silhouette. Golden masters (every geometry and text style,
  15 §7) still have to be generated on CI Linux; SL-10 tests paint patterns per kind in light
  and dark instead. (SL-12 wires `SlideRenderer` per open deck through
  `SlideCanvasController`, over the session's `SlideImageResolver`.)
- **Canvas leftovers (SL-12, Slides 03 §5.7):** P1/P2 canvas items not built: Alt distance
  labels (§5.2), dropping elements on a navigator thumbnail (§4.1), smart-duplicate offset
  (§11), *Scale text* for multi-selection resize (§4.2), Mod+arrow 1-px nudges (§4.4, P2),
  double-click a guide → position input and layout guides (§5.6), snap to grid (P2,
  `slides.view.toggleSnapGrid` stays a placeholder), `slides.select.sameKind` (P2). (Text-box resize
  rules, type-to-edit and text activation: done in SL-13.) SL-15 adds crop/table activation. Element handlers' `extraHandles`/`snapPoints` aren't
  consulted yet (the canvas draws shape adjust handles and line endpoints itself — move them
  into SL-14's handlers). Live previews are transforms: text scales visually during a resize
  and glued connectors follow only on drop (draw connector routes live from the preview
  frames). Duplicating (Edit › Duplicate, Alt-drag) is limited to top-level elements (pasting
  children of scaled groups needs child-space-aware `PasteElements`). Scrollbars are
  indicators, not draggable. (Remote transform hints: SL-21.) The canvas shows the
  slide in the editor's zoom steps (SL-11: 25…400 %; 03 §2.2 also lists 10/33/67 %).
  Check pointer gestures, pinch zoom and cursors by hand in Chrome and Safari (web build).
- **Text editing leftovers (SL-13, Slides 03 §6.2.1):** check IME composition, dead keys,
  emoji picker and RTL by hand in Chrome and Safari (web build, SL-23 — only simulated in
  widget tests). Not built: autoformat while typing (`- `, `* `, `1. `, `[ ] `, `--`, smart
  quotes), the overflow `+` badge (P1), following links with Mod+click while editing, task
  markers clickable in the overlay, the soft-lock popover/claims (SL-21 implements
  `TextEditLocks`), overwritten-text review (SL-37+), localized prompts of built-in
  placeholders (render from ARB strings), *Scale text* on multi-resize. `Localizations` gives
  the overlay's paragraphs a locale the static engine doesn't set (CJK fallback could differ);
  caps transforms that change the length (ß → SS) show the source text while editing; the
  checklist glyphs ☑/☐ are missing from the bundled fonts. The menu/toolbar Undo is disabled
  while the only change is unwritten typing (≤ 300 ms; the shell enables Undo from the stack).
  Text inside tables (cells) is SL-15's; a default-list paragraph turned off is stored as
  `listStyle: none`.
- **Copier, clipboard, headless deck leftovers (SL-8):** (MCP `being_edited`/`force`: done, SL-40);
  (the clipboard UI and HTML paste: done, SL-18); (*Make a copy* with comments remaps slide and
  element anchors through the copier's id map: checked by SL-38's server test); (version copies on
  `DeckCopies.copy(sourceModel:)`: done, SL-39); a deck copy whose image copy fails (file gone or
  unreadable) keeps the new reference (missing image) and logs a warning; deck change records
  reuse Sheets' `ServerChangeRecord` table (rename `spreadsheetUuid` → `fileUuid` when a
  migration touches it anyway); (`DeckChangeLog` pruning: done, SL-39).
- **PDF export and print preview leftovers (SL-20, Slides 10 §11–§13):** (builds as pages,
  code callouts/caret and charts per build stage: done, SL-33); element shadows print as offset silhouettes (no rasterized soft shadow,
  P1); text shadows, emoji bitmaps (P1) and Lucide icons (the PDF warns `icon_unavailable`)
  are not drawn — the client export can embed the font asset
  `packages/lucide_icons_flutter/assets/build_font/LucideVariable-w<100…600>.ttf` with
  `LucideGlyphs.codePoint`/`fontFamilyFor` (`package:wonky_slides_core/icons.dart`, SL-14);
  the server needs a copy of those TTFs (ISC license) in its assets; (charts: the exporter's
  default `SlideChartLayout` with TTF metrics draws them on the server too since SL-33)
  group opacity multiplies into each primitive (no transparency groups), gradient stop alpha
  is averaged. Client exports run on the main isolate in cooperative chunks without the
  progress toast / *Cancel* for > 1 s and without the > 80 pages → server switch (10 §11.4);
  the preview's *More options…* dialog is not built (every §11.1 option is in the settings
  column) and regenerating the PDF does not keep the viewer's page (the browser viewer's page
  isn't readable). Server: `revision` (older versions) and PNG/PNG ZIP are refused as
  unavailable (P1); the result cache is in memory per instance. Client/server raster parity
  (`pdftoppm` diff < 1 %, 10 §18) needs poppler in CI — the line-break parity test covers the
  text layout. Check the in-app viewer and the print dialog in Chrome, Firefox and Safari
  (web build). The editor's own layout overflows by 20 px at 360 × 720 (seen under the print
  route in tests; SL-11).
- **Shapes, lines, icons, groups, format painter leftovers (SL-14, Slides 03 §6.3–§6.7,
  §7, §9):** (elbow segment and curved bend handles: done, SL-44) connector routes still
  update only on drop (SL-12 note above); element handlers' `extraHandles`/`snapPoints` are still unused (the
  canvas draws adjust handles and line endpoints itself). Not built: the quick-style row with
  live swatches (the toolbar/menu list the eight styles by name), gradient/image fill editors
  in the inspector (the commands accept any `fillJson`), layer blur and reflection controls
  (`slides.format.effects {blur}` exists, no UI), *Format › Effects* presets, the icon picker's
  filled variants (`fillJson` draws a background), custom-shape point editing (P2) and SVG
  paste (see SL-18 leftovers). The format painter paints whole elements: text selection → text selection
  painting (03 §9 row 2) needs SL-13's editor, table cells SL-15's cell model. Icon-picker
  categories come from name keywords (Lucide's tag data isn't shipped with the font package);
  aliases and a synonym list cover search. Check in a release web build that the weighted
  Lucide fonts (`Lucide200…600`) keep every glyph (they aren't referenced by `const IconData`,
  so icon tree shaking should leave them whole) and the crosshair tools by hand in Chrome and
  Safari.
- **Clipboard, find & replace leftovers (SL-18, Slides 03 §12–§13, 04 §13.12):**
  - Not checked in a browser (no web build in SL-18): the async Clipboard API read/write of
    `text/html` + `image/png` in Chrome, Safari (paste prompt, user-gesture rules) and
    Firefox, Mod+V reaching the app (not the browser's native paste into the IME textarea),
    and cross-app paste Write ↔ Slides ↔ Sheets in one browser.
  - Not written on copy: `image/png` of copied elements/slides (03 §12.1; render the selection
    from the canvas scene at 2×) and the `text/markdown` marker (Write pastes the HTML). Slides
    → Write/Sheets carries text, lists and tables, not images (Write would need its own
    re-homing).
  - Paste: SVG text → rasterized image (03 §12.5) is not built (pasted as text); `https://`
    images in pasted HTML keep their URL (drawn through the image proxy, not re-hosted as
    uploads); fonts/sizes of foreign HTML are dropped (no px→su conversion); speaker notes keep
    super_editor's plain-text paste (no rich paste into notes); *Keep source formatting* is not
    offered for cross-deck **element** pastes (would need the source theme in the payload to
    bake `theme:` colors); the slides chip sits at the canvas corner, not at the pasted range.
  - Re-homing: a copy refused for storage shows the out-of-storage badge (Retry/Remove)
    instead of removing the image; jobs that fail 12 times wait for the next app start;
    copies of an undone paste still run (their files become orphans collected by the server).
  - Find: code text (P1 `includeCode`), group titles (P1) and master/layout text (masters
    mode exists since SL-28) are not searched; notes matches open the notes pane but aren't highlighted
    there; highlights split runs proportionally per character (approximate for proportional
    fonts). (MCP `slides.search`/`slides.replace_text`: done, SL-40; code text is searched there.)
- **Templates leftovers (SL-22, Slides 04 §15):** five of the ten templates are built (Pitch
  deck, Project kickoff, Weekly update, Lesson, Workshop agenda); Quarterly review (linked
  chart placeholders), Tech talk (code type-in), Product launch and Portfolio (images) come
  with SL-36. Templates use shapes only — add Lucide icons now that `LucideIconSource` is every client
  renderer's default (SL-14); PDF/server rendering of icons is still open (see SL-20). Template content is English (like
  Write/Sheets built-ins). Templates write `list` on every bullet paragraph (since SL-13 the
  engines also apply a box's `defaults.list`, so typed paragraphs of body placeholders are
  bulleted too).
  The default table style's header (`accent1` fill, `bg1` text) is 4.47:1 on *Wonky* light —
  templates use 36 su bold header text (large text); consider a darker header fill in the
  theme (the theme editor can change it since SL-28). Local (offline) creation from a template has no quota pre-check (the
  server measures the size after registration, like a blank deck). Gallery screenshots are
  contact sheets from a widget test (`WONKY_TEMPLATE_PNG_DIR`), not browser screenshots.
- **Themes panel, layouts, page setup leftovers (SL-17, Slides 05 §4, §7, §9):** *Import
  theme from a presentation…* reads the source deck on the server (`slidesThemes.list`), so it
  needs a connection even when that deck is on the device (05 §9 allows on-device decks: read
  the local RevLog cache when the deck is on the device); the chooser for decks with several themes is a
  select with names and usage, not previews. Inspector › Slide › Background edits solid colors
  only (gradient and image backgrounds render, editors not built — share them with SL-14's fill
  editors). The menubar's and context menus' *Apply layout ▸* list layout names (MCP-readable);
  thumbnails are in the toolbar's *Layout ▾* gallery and Inspector › Slide › Layout. Page setup
  writes one plan: decks over 5,000 row changes need the chunked write with progress of 02
  §12.2 (one undo step). Not built (P2): *View › Preview in dark appearance*, *Update to the
  latest version* of a built-in copy, a personal theme library. (*Edit theme…* and master mode:
  done, SL-28.) Check the panel, the galleries and the page setup dialog in a release web build
  (no web build in SL-17).
- **Masters and theme editor leftovers (SL-28, Slides 05 §8):**
  - Check masters mode and the theme editor by hand in a release web build (none in SL-28;
    widget tests only): navigator scrolling with 16+ layouts per master, the placeholder labels
    on rotated placeholders, font faces in the font selects (families show in their own face
    only once loaded).
  - Theme editor not built: gradient and image backgrounds (theme, master, layout — solid
    colors only, like Inspector › Slide › Background; share SL-14's fill editors), list markers
    of levels 4–9, `levelSizeScale`/`markerGap`, link and inline-code styles, table first
    column/total row/borders/padding, text box defaults beyond the fill (stroke, autofit),
    quick-style strokes, custom code palettes (`codeStyleJson.custom`), chart font/title style/
    3D floor, code previews with highlighted sample code (palette swatches only).
  - Layout reordering is *Move up/down* (context menu, `slides.layout.move`); no drag and drop
    in the masters navigator. Masters can't be reordered from the UI (`UpdateMasterOrLayout`
    takes a master `sortKey`; no command). Theme sections aren't collapsible in the navigator.
  - Placeholders inserted on a layout reach existing slides only through *Reset slide to
    layout* or re-applying the layout (as Google Slides); deleting a layout placeholder leaves
    the slide instances dangling until maintenance re-points or materializes them (02 §10).
    The date placeholder (P2) is not offered.
  - Presence shows "Editing layouts" (SL-21) but not *which* layout; remote selections and
    soft locks on layout elements show only for collaborators editing the same layout.
  - Find & replace doesn't search master/layout text (see the SL-18 leftovers).
- **Timeline leftovers (SL-24, Slides 06 §9.8):** (present mode compiles with
  `SlideMotionInput.fromDeck(scene:, chartShapeOf:)` and the stage renders every frame field
  since SL-29.) Code durations are estimates until SL-26's `TypingScript`
  (`MotionCodeState` should then carry the derived type-in length); chart shapes come from the
  snapshot JSON (`gz:` compressed snapshots are not read — pass `chartShapeOf` from SL-27/32).
  Not in the core: `line`
  delivery with layout (compiles as paragraph), interactive `onElementClick` triggers (P2),
  builds on group children / layout elements (P2), `Deck.defaultsJson.build` quick-add memory
  (SL-30 reads it; nothing writes it yet). The VM ≡ dart2wasm determinism run (06 §19) needs a web test
  run (no web build in SL-24); frames are compared as rounded JSON.
- **Code core leftovers (SL-26, Slides 07):**
  - Renderers: the stage draws every `CodeScene` field since SL-31 (`CodeScenePainter`); the PDF
    painter too since SL-33 (callouts, caret, selections, glyphs, gutter labels, underlay; the
    states and steps of build pages through `SlideFrameScenes`) — line blur prints as opacity.
  - Incremental tokenization (07 §5.4: `tokenizeLine`/`LineState`, ≤ 1 ms per keystroke for 300
    lines) is not built: type-in frames re-tokenize the whole intermediate text (≈ 5 ms for 300
    lines of Dart on the VM; the `CachedCodeTokenizer` LRU serves repeated frames). The TextMate
    engine could restart from top-level resume points (positions where the scope stack is
    empty) and stop once a resume point matches the previous parse.
  - Tokenizer budget (07 §14: 1,000 lines of Dart ≤ 15 ms desktop): SH-6 brought it from ≈ 56
    to ≈ 17–20 ms on the VM on a loaded laptop (`dart test -P slow` in `wonky_code`); the rest
    is mostly regex search, led by the Dart grammar's function-call rule, which backtracks
    inside every identifier. Measure on the web (≤ 30 ms) once a web test run is allowed.
    Tried in SL-35: a `(?<![a-zA-Z0-9_$])` lookbehind on that rule saves ≈ 1.5–2 ms (16.8 →
    14.9–15.4 ms on the budget text) but is not span-preserving (a mid-identifier match such
    as `ooBar(` in `FooBar(` is no longer scoped), so it was not applied; an exact speedup
    needs an identifier-start search in the SH-6 next-match memo. SH-7 (capture offsets,
    SL-35) costs nothing measurable.
  - Not built (outside SL-26): `UnifiedDiff` and `WalkthroughBuilder` (07 §10.2, with SL-40/43),
    `CodeLanguages.detect` (P1), sound (P2). (Cross-slide code morphs are drawn since SL-29,
    `MagicMoveCodeMorphs`.)
  - Simplifications: scroll-follow while typing is a stateless function of the caret (no
    spring; the renderer may smooth it); `focus: zoom` scales so the range fills 60 % of the
    viewport without the 24 su edge fade; the `auto` palette uses the slide's solid
    background color (gradients/images count as `bg1`). (`string_scanner` was removed from
    `wonky_code`'s dependencies in SL-23.)
- **Presenting leftovers (SL-19, Slides 10 §1–§9):**
  - Browser checks not done (no web build in SL-19; D-18 held the token): full screen +
    refusal hint, F5/Shift+F5 capture and a Logitech-style clicker, Esc/F11 leaving full
    screen ends present mode, presenter view + audience in a second browser (Chrome, Firefox,
    Safari) and on a phone, the ≤ 300 ms p95 follow latency on a LAN (10 AC 2, AC 4), the
    one-time extended-display hint. The running dev server needs a restart (or a hot reload
    that picked up the new `presentation` endpoint) before the audience view can join.
  - (Kiosk, running builds, transitions, `advanceDuringBuild: skip` and follower seek within a
    step: done in SL-29, 10 §8.1/§9 as built; kiosk idle restart with `allowNavigation` is P1.)
  - Pre-flight (10 §1.2: fonts, first images, "3 images aren't available offline" with
    *Present anyway*) — not built; fonts load on demand through the renderer.
  - Presence state `presenting` ("Anna is presenting", A-10-7) needs a `PresenceState` value
    (shared model) — SL-21. Followers (`?view=follow`, P1) are accepted by the server but have
    no UI; phone remote and pairing keys, rehearse timings, same-browser `BroadcastChannel`
    fast path, *Freeze audience* — SL-41 (P1, on hold; server pairing and the channel are
    built, see the SL-41 entry above). Captions P2.
  - *This presentation* settings UI (10 §3) on the Presenting settings page — the command
    `slides.deck.setPresentSettings {patch}` exists (undoable); the page section doesn't.
  - Screen readers: the presented slide is one labeled image; exposing its content in reading
    order and announcing builds (10 §16, 06 §17) is open.
  - The presenter view's notes don't auto-scroll per step (P2) and have no `Mod+↑/↓` scroll
    binding; the 3D chart `camera` message (P1) is not relayed.
