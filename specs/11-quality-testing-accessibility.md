# 11 · Quality: Testing, Performance, Accessibility, Internationalization

## 1. Testing strategy

This section defines *what* is tested at which level. *How* to write the tests (layout,
naming, helpers, determinism, running them) is in [15 · Writing tests](15-writing-tests.md).

| Level | Tooling | Scope | Where |
|-------|---------|-------|-------|
| Unit | `test` / `flutter_test` | Pure logic: Delta schema, Markdown codec, OT helpers, formula parser/evaluator/functions, number formats, fractional index, ids, undo handlers, command arg parsing | `*_core/test`, app `test/` |
| Property / fuzz | `test` + seeded random generators (`glados`-style custom generators) | OT convergence (Write), Markdown round-trip, RevLog convergence (apply rules, overlay, bootstrap coverage and client-gate ⇒ server-guard parity; several simulated clients against `FakeRevServer`, [15](15-writing-tests.md)), undo invariants, formula codec A1⇄stored | `*_core/test/property`, server `test/property` |
| Server | `serverpod_test` (`withServerpod`, embedded Postgres via `config/test.yaml` `database.dataPath`; no Docker) | Endpoints, services, stream endpoints, MCP route, permissions, RevLog sequencer, connection, pages and hooks, version providers, scripting compile service | `wonky_server/test/{unit,integration}` |
| Widget | `flutter_test` | Every `wonky_ui` widget (light + dark), dialogs, panels, menus generated from `MenuSpec` | package `test/` |
| Golden | `flutter_test` goldens (+ `alchemist`-style multi-theme matrix) | Editor rendering per Write theme (light/dark), grid rendering (formats, borders, merges, CF), charts, PDF page renders | app `test/goldens` |
| Integration / E2E | `flutter_driver` via the `dart` MCP + `serverpod` MCP (`spawn_flutter_app`, `get_flutter_app_dtd`), `integration_test` | Critical user journeys (below), multi-client collaboration (two app instances), offline/online transitions | app `integration_test/` |
| Export validation | CI containers: LibreOffice headless (DOCX/ODT/XLSX/ODS open + convert), `epubcheck`, PDF text extraction | Export fidelity | CI |
| Performance | Benchmarks (`benchmark_harness`), Flutter `--profile` traces, custom perf suite | Budgets in §2 | `benchmark/` |

**Contract tests**: every command has an execute→undo→redo test (see 08 §4). Every MCP tool
has an integration test through `/mcp`. Every endpoint has permission tests for each role.

### 1.1 Critical user journeys (E2E; journeys 1–10 run on web + macOS in CI, the v2 journeys 11–15 and J-B1 on the web only — 01 A13)
1. Sign up → verify → create document → type with formatting → reload → content persists.
2. Two users co-edit the same paragraph; cursors visible; converge; each undoes only own edits.
3. Go offline, edit document and spreadsheet, go online → changes sync, no data loss.
4. Create spreadsheet, enter data + formulas, sort, filter, chart → reload offline → identical.
5. Share with commenter; commenter comments and suggests; owner accepts suggestion.
6. Restore a previous version in both apps; undo the restore.
7. Export document to PDF/DOCX and spreadsheet to XLSX/PDF; import them back.
8. MCP: create doc via `drive.create_document`, edit via `write.insert_markdown`, control UI via
   `ui.invoke_command`; Sheets via `sheets.set_values` + `ui.sheets.select_range`.
9. Theme editor: create theme, apply, verify editor + PDF reflect it in light & dark.
10. Script: custom function used in a formula; onEdit trigger; time-driven trigger runs on server.
11. (v2) Drive: sign in at `/` lands on Wonky Write's home (`/write/`); the left menu opens
    Wonky Drive at `/drive/`; upload files by drag-and-drop, preview image/code (a PDF shows the *Download* card),
    *Open with* a CSV in Sheets; app homes show only their kind ([Drive 05 §6](wonky_drive/05-implementation-plan.md)).
12. (v2) Quota: fill the 50 MB, see the refusal and the banners in every app, empty trash, the
    banner disappears live.
13. (v2) Settings split and *Report a bug* in all four apps (since M12 the entry opens *Bugs & improvements*, J-B1).
14. (v2) Slides: create a deck offline with groups, builds and a code block with type-in;
    present it; export PDF; insert a linked Sheets chart and update it after the source
    changed ([Slides 12](wonky_slides/12-implementation-plan.md)).
15. (v2) Two users co-edit a deck; soft lock on a text box; each undoes only their own edits.
16. (M12) **J-B1**, Bugs & improvements ([16 §15](16-bugs-and-improvements.md)): sign in; open the
    dialog from the Sheets editor; add a screenshot and cover an area; see a similar post and
    post anyway; the post is visible (fake triage); a second user votes and comments; an admin
    (`@serverpod.dev` test account in the `e2eSupport` allowlist) selects it, edits and publishes
    the prompt; the second user claims it and sees the claim code; a recorded `pull_request`
    webhook with the code links the PR and a recorded merge marks it done; the voter gets the
    notification. Also checked: the signed-out board loads in the release build.

## 2. Performance budgets (summary; details in app specs)

| Area | Budget |
|------|--------|
| App cold start (web, cached assets) | < 2.5 s to interactive home; desktop < 1.5 s |
| Open document (cached) | < 300 ms first paint |
| Write keystroke latency | < 16 ms p95 (100-page doc) |
| Write remote op visible | < 250 ms p95 same region |
| Sheets open 1M cells | Not on the device: < 1.5 s desktop, < 3 s web to `WorkbookReady`, whole file < 15 s / < 30 s; from the cache: ≤ 0.55 s per 200k cells (RevLog gates P6–P8, [17](17-revlog-sync.md) part 7) |
| Grid scroll | 60 fps at 1M cells (desktop), ≥ 45 fps web |
| Cell commit (local) | < 16 ms; recalculation of 100k dependents < 1 s native, < 2 s web |
| Sheets and Slides remote change visible | p95 < 250 ms on one instance, < 400 ms across two (RevLog gates P1–P2); server commit p95 < 15 ms for ≤ 100 changes, < 300 ms for 5,000 (P3–P4); the full gate list (P1–P12) is in [17](17-revlog-sync.md) part 7 |
| Memory | Web tab < 1.5 GB at 1M cells; desktop < 2 GB |
| Bundle size (web, per app, compressed) | < 6 MB initial (deferred loading for exporters, charts, script runtime, theme editor); (v2) Drive < 4 MB initial (code viewer deferred) |
| (v2) Drive home | First list paint < 1 s with 1,000 items in the folder (cached: < 300 ms); upload throughput limited only by the network (no client re-encoding) |
| (v2) Previews | Image (≤ 4 MB) < 500 ms after bytes arrive; 1 MB text file highlighted < 300 ms |
| (v2) Slides | See [Slides 01 §4](wonky_slides/01-overview.md) (60 fps builds and transitions, deck open budgets) |

Use Flutter deferred imports (`deferred as`) for heavy, rarely used features on web: exporters,
importers, theme editor, chart editor, pivot editor, script editor + runtime, AI panel; (v2)
Drive's text/audio viewers, Slides' presenting, PDF export, 3D charts and code type-in.

## 3. Accessibility (WCAG 2.2 AA target)
- Keyboard: every action reachable by keyboard; visible focus; no traps (Esc always exits
  overlays); skip-to-content shortcut in shell.
- Screen readers: Flutter `Semantics` on all controls; editor exposes document text (super_editor
  semantics) and announces formatting changes; grid announces "B4, 42, formula =SUM(…), bold"
  on navigation and range sizes on selection change; live regions for sync status, remote
  joins, errors.
- Contrast ≥ 4.5:1 text, ≥ 3:1 UI components in both themes; theme editor and CF warn on low
  contrast.
- (v2) Reduce motion also governs Slides builds/transitions (replaced by fades, Slides 06) and
  Drive's upload/preview animations.
- Respect OS reduce-motion, text scaling (chrome scales to 200% without overlap; document zoom
  separate), high contrast (Windows) where available.
- Settings › Accessibility: screen-reader optimizations (e.g. disable remote cursor flags,
  verbose announcements), always show keyboard focus.

## 4. Internationalization
- `flutter_localizations` + `intl` ARB files in `wonky_app/lib/l10n` (shared strings) and per app
  (`wonky_write/lib/l10n`, `wonky_sheets/lib/l10n`, (v2) `wonky_drive/lib/l10n`,
  `wonky_slides/lib/l10n`); shad's own
  `GlobalShadLocalizations` for component strings.
- v1 ships English; all strings externalized from day one; pseudo-locale (`en_XA`) build for
  testing truncation/RTL (`ar_XB`).
- Pseudo-locale: `dart run tool/pseudo_locale.dart <x_en.arb> <x_en_XA.arb>` regenerates an
  `en_XA` ARB (accented letters, ~35% padding, `[…]` brackets; ICU placeholders, plural/select
  and `#` kept; `--self-test` checks the transform) — rerun it after adding keys. Build or run
  any app with `--dart-define=WONKY_LOCALE=en_XA` (or any supported tag, e.g. `en`) to force the
  shell's locale; shad, Flutter's `Global*Localizations` and untranslated keys fall back to `en`.
- RTL: shell mirrors; Write supports RTL paragraphs (super_editor RTL support); Sheets has
  per-sheet RTL.
- Locale-aware formatting of dates/numbers in UI; Sheets uses the spreadsheet locale for cell
  parsing/formatting independent of UI language.

## 5. Observability
- Server: Serverpod session logs (structured), slow-query logging, per-endpoint metrics, OT
  metrics (ops/s, transform time, rejections), RevLog metrics (per op: commit duration,
  changes, bytes, lock wait, protection-check duration; per connection: ops, gaps filled; hook
  lag; [17](17-revlog-sync.md) part 5 §12), MCP/AI usage and errors.
- Client: error reporting endpoint (`feedback.reportError` with stack, app/build version,
  route, anonymized state), performance marks (open time, frame drops) sampled. (M12) Error
  reports stay **private telemetry**: they are never shown on the public board. They feed the
  report dialog's *Include the last error* option (the error boundary's last report, shown to
  the user before posting) and, as P1, the admin *Error reports* view
  ([16 §12](16-bugs-and-improvements.md)).
- Health: Serverpod health endpoints (`/livez`, `/readyz`) with custom indicators (DB, Redis,
  AI provider reachability (non-critical), storage).

## 6. Code quality rules
- `dart analyze --fatal-infos` clean (strict-casts, strict-inference, strict-raw-types,
  `unawaited_futures`, `discarded_futures`), `dart format`. The options live in one package,
  `packages/wonky_lints` (`dart.yaml` for pure Dart and the server, `flutter.yaml` for Flutter
  packages and apps), which every package's `analysis_options.yaml` includes (CQ-64e); a package
  may turn a mode or rule off only with a `TODO(CQ-64e)` naming the number of issues (today:
  `discarded_futures` in `wonky_app`, Write, Sheets and Slides). The generated client and the
  vendored packages keep their own options.
- No business logic in widgets; no direct client calls from widgets.
- Generated code never edited (see AGENTS.md).
- Vendored packages in `third_party/` are changed only with a `PATCHES.md` entry and tests
  (01 §2.3); their own test suites run in CI.
- `RevSchema` tests (each core's schema is consistent, and planner output validates against it, so
  every write names its columns; [17](17-revlog-sync.md) part 2 §4) — fail CI.
- Package dependency rule check script (01-architecture §2.1) — fails CI. (v2) Covers the four
  app families and the shared leaf packages.
- (v2) Every byte-adding endpoint has a quota test (Drive 03 §7.2); every file viewer is tested
  with malformed input (Drive 05 §7).
- Every public API in `*_core` packages documented.
