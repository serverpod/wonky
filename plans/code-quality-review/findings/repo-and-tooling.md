# Wonky Work: repository-wide engineering hygiene review (read-only)

Scope: workspace setup, lints, tool/ scripts, CI, tests, size hotspots, repo hygiene, docs drift,
web bundle size and performance, generated code. Date: 2026-10-17, HEAD `bee8c7f` (89 commits).
Nothing in the repo was modified. The only command run inside the repo was `dart analyze --fatal-infos <all members> tool`,
which reported **"No issues found!"** (exit 0).

## Overall verdict

The repository is in better shape than most monorepos of this size (~620k lines of hand-written Dart
in lib/test, excluding generated code). It has a real pub workspace with one lock file. Analyze is clean
with `--fatal-infos`. CI covers analyze, format, a per-package test matrix that is derived from the
workspace (so it can't silently miss a package) and a dependency-rule checker. Tests skip almost nothing
(no `skip:` in app code), app code has 0 FIXME and close to 0 TODO, and 0 `print(` in lib. The gaps are
at the edges. **Nothing ever builds the web apps before deploy.** Golden tests exist but have never
been able to pass. The generated code that is committed (Serverpod, l10n) is never checked for
staleness. There is no `.gitattributes`. The web bundles load about 4.3 MB of fonts at startup that
they mostly don't need. Several docs claim things that are no longer true.

## Prioritised findings

| ID | Title | Sev | Category | Effort |
|----|-------|-----|----------|--------|
| R-1 | No CI web (`--wasm`) build: wasm breakages first show up at deploy | High | build | S |
| R-2 | 7 golden test files with no masters and no golden CI job (dead tests, and they fail locally) | High | testing | M |
| R-3 | Committed generated code (Serverpod client/server, sync models, l10n) never checked for staleness in CI | High | build/DX | S |
| R-4 | No `.gitattributes`: 674 phantom "modified" generated files on Windows | High | DX | S |
| R-5 | Web apps eagerly load ~4.3 MB of fonts at startup (Lucide variable weights, Inter, golden_toolkit Roboto) | High | perf | S–M |
| R-6 | Lint strictness differs per package; the apps and server skip the spec-mandated strict modes | Med | maintainability | M |
| R-7 | No app-level deferred loading; main.dart.wasm is 9.2 MB (Write) and 12.1 MB (Slides) | Med | perf | L |
| R-8 | Font TTFs committed 3× (27 MB) and Sheets ships a second copy in its bundle | Med | build/perf | M |
| R-9 | `slow`, property-long, e2e (except 5 Write journeys), export-validation, perf and coverage gates never run | Med | testing | M |
| R-10 | Server `slow` perf test runs on every PR; tag not declared in the server's `dart_test.yaml` | Med | testing | S |
| R-11 | `flutter_build` script: the Windows branch swallows failures; both branches hide build flakiness behind `flutter clean`; AGENTS says "in parallel" | Med | build | S |
| R-12 | Docs drift: specs/README, TODO.md, specs/01 §2 and AGENTS.md contradict the code | Med | DX | S |
| R-13 | SDK and Flutter lower bounds in all pubspecs are below what the lock file needs | Low | build | S |
| R-14 | Unused or undeclared-use dependencies (≈29 suspects); the dependency checker doesn't flag unused deps or test imports | Low | maintainability | S |
| R-15 | `implementation_imports` of `package:pdf/src` and `dart_eval/src` in 6 places | Low | maintainability | M |
| R-16 | Real clock in tests (`DateTime.now()` in 57 test files) against specs/15 §4 | Low | testing | M |
| R-17 | Deploy pipeline not runnable (`wonky_server/scloud.yaml` missing); uploads `.symbols` and both JS and wasm | Low | build | S |
| R-18 | Spellcheck dictionaries (13 MB) bundled into every app, including Drive | Low | perf/build | S |
| R-19 | Migration `definition.json` files are ~550 KB each (15 MB for 19 migrations) | Low | maintainability | S |
| R-20 | Minor: constraint drift, template boilerplate in app pubspecs, dev DB password in committed files, en_XA ARB missing for Sheets | Low | DX | S |

---

### R-1 No CI web build (High, build, S)
- **Evidence:** `.github/workflows/{analyze,format,tests,e2e}.yml` contain no `flutter build web`.
  The only build is the Serverpod Cloud pre-deploy hook (`deploy.yml`, which is not configured, see R-17). The
  repo already ships wasm-specific workarounds: `pubspec_overrides.yaml` pins `isolate_manager ^6.3.2`
  because "isolate_contactor imports dart:html and breaks `flutter build web --wasm`", and `sqlite3_web: 0.9.4`
  because 0.9.5 "breaks the web build of sqlite_async". The release builds produced locally are 84–96 MB per app.
- **Why it matters:** the product is web-only in v2. A dependency bump that adds `dart:html` or
  `package:js`, or an unsupported FFI or conditional import, passes analyze and tests and only fails
  at deploy or in a developer's manual release build. The desktop "must keep compiling" rule (A13) has
  no enforcement either.
- **Recommendation:** add a `build-web` matrix job to the PR workflow (drive/write/sheets/slides:
  `flutter build web --wasm --base-href /<app>/ --no-tree-shake-icons=false`). Upload a size report
  (`main.dart.wasm`, `main.dart.js` and the `assets/` total) as an artifact, and fail the job past a
  budget, for example +5 % over the last main. Add a weekly `flutter build macos --debug` (or `linux`) job
  for one app so A13 holds.

### R-2 Golden tests are dead (High, testing, M)
- **Evidence:** 7 golden test files: `packages/wonky_app/test/goldens/{board,drive,storage}`,
  `wonky_drive/test/goldens/{preview,storage,uploads}` and `wonky_sheets/test/goldens/charts`. `git ls-files '*/test/goldens/*'`
  lists **no PNG masters**. `tests.yml` excludes `golden`, and no other job runs them.
  specs/15 §7 points to `tool/update_goldens.sh` and a "CI golden container", but **neither exists**
  (`ls tool` gives check_dependencies.dart, pseudo_locale.dart, spec_index.dart). TODO.md lines 72, 151 and 276
  confirm "no committed masters, so those six golden tests fail locally". Write and Slides have **no** goldens,
  although specs/11 §1 requires editor and grid goldens per theme.
- **Why it matters:** these tests cost maintenance and protect nothing. Rendering regressions in
  light and dark (a core requirement) are only caught by hand.
- **Recommendation:** add `tool/update_goldens.sh`, which runs a pinned `ghcr.io/cirruslabs/flutter:3.47.5`
  container with `flutter test --update-goldens -t golden`. Commit the masters, and add a `goldens` job
  in the same container that runs `flutter test -t golden` for the packages that have `test/goldens`.
  On failure, upload the `failures/` directory as an artifact. Until that exists, delete the goldens or
  mark them `skip:` with a reason, so that `flutter test` passes locally.

### R-3 Generated code is not checked for staleness (High, build/DX, S)
- **Evidence:** 368,369 lines of generated code are committed: `wonky_client` (288 files, 58k lines),
  `wonky_server/lib/src/generated`, `packages/wonky_sync_models/lib/src/generated`,
  `wonky_server/test/integration/test_tools/serverpod_test_tools.dart` (10.9k lines) and 12 gen-l10n
  outputs (~89.5k lines, for example `wonky_slides/lib/l10n/gen/slides_localizations_en.dart` at 15.9k). In
  `tests.yml`, the `server` job runs `serverpod generate` and then tests against the *fresh* output. The
  package and app jobs use the *committed* client. No job runs `git diff --exit-code` after generating, and
  nothing re-runs `flutter gen-l10n`. Generated data files `api_index_data.dart` ("GENERATED by
  tool/gen_api_index.dart") and `code_page_tables.dart` are not checked either.
- **Why it matters:** a model or ARB change committed without regenerating can still pass CI. The server
  tests see new code while the apps see stale code. Committing Serverpod output is the right call:
  Serverpod Cloud and the Flutter apps need it, and agents read it. The missing piece is a freshness check.
- **Recommendation:** add a `generated` job that runs `serverpod generate` in `wonky_server` and `flutter gen-l10n`
  in each package with `l10n.yaml`, then `dart run packages/wonky_sheets_script/tool/gen_api_index.dart`
  and `dart run tool/pseudo_locale.dart`, followed by `git diff --exit-code`. Make it a required check.

### R-4 No `.gitattributes` (High, DX, S)
- **Evidence:** there is no `.gitattributes` anywhere outside third_party, and `core.autocrlf=true`. `git status --porcelain` shows
  674 entries (333 `wonky_server/lib`, 283 `wonky_client/lib`, 55 `wonky_sync_models`). `git diff
  --ignore-cr-at-eol` shows nothing. `git ls-files --eol` shows the index at LF and hand-written files in the
  working tree at CRLF (`wonky_write/lib/main.dart: i/lf w/crlf`), while the generator writes LF.
- **Why it matters:** every `serverpod generate` on Windows produces hundreds of phantom changes.
  These hide real generator diffs, inflate agent and PR noise, and risk CRLF commits. The repo is
  developed on Windows (the `.mcp.json` uses `cmd /c`).
- **Recommendation:** add `* text=auto eol=lf`, plus `*.png *.ttf *.otf *.wasm *.dic *.aff *.webp *.jpg *.zip *.pdf *.xlsx *.docx *.pptx binary`. Then run
  `git add --renormalize .` once in a dedicated commit.

### R-5 About 4.3 MB of fonts loaded at startup by every app (High, perf, S–M)
- **Evidence:** in `wonky_server/web/write/assets/FontManifest.json` (local release build), the
  Flutter web engine fetches every family in this manifest at boot:
  - `lucide_icons_flutter/assets/build_font/LucideVariable-w100…w600.ttf`: 6 files, 459–518 KB each,
    **~2.9 MB, not icon-tree-shaken** (only `lucide.ttf` was shaken, to 84 KB)
  - `shad/fonts/Inter[opsz,wght].ttf` 877 KB, `Geist` 169 KB, `GeistMono` 171 KB
  - `golden_toolkit/fonts/Roboto-Regular.ttf` 163 KB. This is a **test package** that reaches the release
    bundle because vendored `third_party/super_editor/pubspec.yaml:52` lists `golden_toolkit`, `mockito` and
    `flutter_test` under `dependencies:` ("testing tools that we ship").
  The Slides build is the same, plus `flutter_scene` 5.8 MB of assets (lazy).
- **Why it matters:** first load downloads several megabytes of fonts before the first frame on
  cold cache, for every one of the 4 apps. The specs set startup budgets (11 §2).
- **Recommendation:** (a) Confirm in the DevTools network tab. (b) If the weighted Lucide families are
  unused (likely), get rid of them. Options: switch to `lucide_icons` (static), pin a
  `lucide_icons_flutter` version without `build_font`, or vendor and patch its pubspec `fonts:`. (c) In the
  vendored super_editor, move `golden_toolkit`, `mockito` and `flutter_test_robots` to `dev_dependencies`
  and gate `lib/src/test/**` behind a separate library. Record this as a PATCHES.md entry, since the
  package is already patched. (d) Check whether both Inter and Geist are needed. shad's default is Geist,
  so drop the other if the theme never uses it.

### R-6 Lint configuration varies per package and is weaker than the spec (Med, maintainability, M)
- **Evidence:** there is no shared `analysis_options` package or root file. 26 copies exist in 4 variants
  (blob hashes: 13 identical pure-Dart files, 5 identical Flutter-package files, 4 identical apps, plus the server and client).
  specs/11 §6 says "`dart analyze` clean (strict-casts, strict-inference, strict-raw-types)". **The 4 apps,
  `wonky_server`, `wonky_charts_flutter` and `wonky_client` don't enable the strict modes.** These are the
  largest code bases (Slides 101k lines, Sheets 95k, server 76k). `unawaited_futures` is enabled only in
  the server (a Flutter app full of async commands benefits most from it). specs/11 §6 also says "every
  public API in `*_core` packages documented", but `public_member_api_docs` is on nowhere. The formatter
  `trailing_commas: preserve` is set only in server and client, so formatting style differs per package.
- **Recommendation:** create `packages/wonky_lints` (or a root `analysis_options.yaml` that members
  `include:`), with a pure and a Flutter variant. Turn on the strict modes plus `unawaited_futures`,
  `discarded_futures` (apps), `prefer_final_locals`, `avoid_dynamic_calls` and `public_member_api_docs` (cores).
  Roll it out per package, and expect a burst of fixes in the apps. Narrow `lints`/`flutter_lints` from
  `'>=3.0.0 <7.0.0'` to `^6.x`.

### R-7 No application-level code splitting (Med, perf, L)
- **Evidence:** `grep -r "deferred as"` over all wonky code finds 0 hits. In the local release builds,
  `main.dart.wasm` is 9.17 MB for Write and 12.15 MB for Slides, and `main.dart.js` (fallback) is 9.7 and
  12.9 MB. The 81 `main.dart.js_N.part.js` parts (~1.5 KB each) are shad's deferred locale strings,
  not app code. Rarely used heavy features are all eager: Sheets scripting (re_editor, dart_eval runtime),
  import/export (RTF/ODT/HTML importers, PDF exporter), the theme editor, version history,
  charts 3D (`flutter_scene`), and presenter mode.
- **Why it matters:** parse and instantiate time on mid-range devices, and cold-cache download time.
  dart2wasm supports deferred imports (they compile to separate modules in recent SDKs, so check the 3.47
  behavior).
- **Recommendation:** measure first. Add the size report from R-1, and use `--analyze-size` or the
  dart2js `--dump-info` for JS. Then use `deferred as` for the top 3–5 feature routes (import/export,
  script editor, theme editor, history, 3D charts), behind `go_router` route builders that `await loadLibrary()`.

### R-8 Fonts committed three times; Sheets bundles a second copy (Med, build/perf, M)
- **Evidence:** blob hashes match across `packages/wonky_fonts/fonts/`, `wonky_sheets/assets/fonts/`
  and `wonky_server/web/fonts/` (9.1 MB each, 27 MB total, all 40 TTFs plus OFL files). `wonky_sheets/pubspec.yaml`
  declares `assets/fonts/` (used by `features/formatting/cell_fonts.dart:244` and `print/print_fonts.dart:30`),
  while it also gets `packages/wonky_fonts/fonts/` through `wonky_app`. The Sheets build therefore contains both sets.
  Spec 01 D-7 moved fonts into `wonky_fonts`, but Sheets was not migrated. The server copy is read from disk by
  `server_fonts.dart`, `sheets_pdf_fonts.dart` and `slides_export_service.dart`. The 4 apps also commit an
  identical `web/sqlite3.wasm` (750 KB) and `web/db_worker.js`.
- **Recommendation:** point Sheets' `CellFonts` and print fonts at `packages/wonky_fonts/fonts/…` (the
  `BundledAssetFontProvider` already exists) and delete `wonky_sheets/assets/fonts`. For the server,
  either resolve `package:wonky_fonts` with `Isolate.resolvePackageUri` (check that the Cloud upload
  includes it), or keep the copy but add a CI check that compares hashes with `wonky_fonts/fonts`. For
  `sqlite3.wasm` and `db_worker.js`, keep one source (for example `packages/wonky_app/web/`) and have a check
  or a `flutter_build` step copy it, so the "keep web/db_worker.js in step with sqlite_async" note in
  pubspec.yaml applies to one file instead of four.

### R-9 Large parts of the test strategy never run (Med, testing, M)
- **Evidence:** `tests.yml` excludes `slow` and `e2e` and says they "run nightly". The only nightly
  workflow (`e2e.yml`) runs **5 Write journeys on macOS** (1, 2, 5, 6, 8). No workflow runs:
  `-t slow` (9 perf/benchmark files: `wonky_sheets/test/features/grid/grid_performance_test.dart`,
  `wonky_slides/test/features/thumbnails/thumbnail_benchmark_test.dart`, …), long property seeds,
  `wonky_sheets/integration_test/chart3d_backends_test.dart`, journeys 3, 4, 7, 9, 10 and the v2 journeys
  11–16 that specs/11 §1.1 says "run on web + macOS in CI", export validation (LibreOffice/epubcheck/poppler,
  specs/11 §1), or the ≥90 % coverage gate for `*_core` (specs/15 §10). specs/15 §10 admits most of this
  ("Still to be added"). Tag hygiene: 8 packages have no `dart_test.yaml` (none use tags yet, so this is harmless),
  `wonky_write/dart_test.yaml` declares no `golden` tag, and the `dart_test.yaml` files come in 5 variants.
- **Recommendation:** add a `nightly.yml` with jobs `slow` (`dart test -t slow` / `flutter test -t slow`
  per package, reusing the list-packages step), `property-long` (`WONKY_PROPERTY_RUNS=…`, random
  seed printed), and `coverage` (`dart test --coverage` + `format_coverage` + a threshold script for
  the `*_core` packages). Make the web E2E runner (chromedriver on ubuntu) a nightly job. Standardise
  one `dart_test.yaml` that declares all five tags in every package.

### R-10 Server perf test runs on every PR (Med, testing, S)
- **Evidence:** `wonky_server/test/integration/sheets/sync/server_writer_perf_test.dart:1` has `@Tags(['slow'])` and
  writes 20,000 cells. `wonky_server/dart_test.yaml` declares only `integration` and `live-ai`. `tests.yml`
  runs plain `dart test` for the server (no `-x slow`).
- **Recommendation:** declare `slow` (and `property`) in the server's `dart_test.yaml`, and either set
  `exclude_tags: slow` there (as the core packages do) or run `dart test -x slow` in CI.

### R-11 `flutter_build` script robustness (Med, build, S)
- **Evidence:** `wonky_server/pubspec.yaml:70-108`. The Windows branch chains with `&`, so a failed
  build of one app doesn't fail the script. The posix branch tracks failures properly. Both branches retry
  after `flutter clean` on any failure, which hides real errors and doubles the time. AGENTS.md says
  "`serverpod run flutter_build` … builds every existing app in parallel", but the comment says posix builds
  "one after another".
- **Recommendation:** make Windows exit non-zero on any failure (for example a small Dart script
  `tool/build_web.dart` that is shared by both platforms and by CI from R-1). Retry with `clean` only when an
  opt-in flag is set. Fix the AGENTS.md wording.

### R-12 Docs drift (Med, DX, S)
- **Evidence:**
  - `specs/README.md:18`: v2 is "specified and planned … not implemented", while AGENTS.md says v2 is built.
  - `TODO.md:68`: "open violation: `wonky_sheets_core` imports `vector_math` without declaring it; Sheets
    packages still have analyzer infos and unformatted files, so the analyze/format jobs fail". Analyze is clean
    today and `vector_math` is declared.
  - `TODO.md:83` item 13: "☐ v2 … specified and planned", which is stale.
  - TODO.md legend says "done items are removed", yet 17 ☑ remain. Only 41 of 161 bullets carry a status marker,
    and the file is 939 lines / 85 KB with Slides alone at ~550 lines. `specs/wonky_slides/STATUS.md` is 144 KB.
  - `specs/01-architecture.md` §2 still opens with "Current state (starting point)", describing `wonky_flutter/`
    (deleted), "CI pins 3.44.4" and the M0 steps.
  - specs/15 §7 references a non-existent `tool/update_goldens.sh`.
  - specs/01 lists `.mcp.json` as a committed root file, but it is gitignored (and Windows-only `cmd /c`).
- **Recommendation:** in one docs pass, fix specs/README, collapse the 01 §2 "starting point" into a
  history note, and drop the done items in TODO.md. Split TODO.md per app (`specs/<app>/TODO.md`, or move it
  into the STATUS files) with a fixed schema of status, priority, spec ref and owner. Consider a CI lint
  (`tool/spec_index.dart` already exists) that fails on links to missing files under `tool/`.

### R-13 SDK constraints below the lock file (Low, build, S)
- **Evidence:** 27 pubspecs say `sdk: '^3.12.2'` and 10 say `flutter: '^3.44.4'`. `pubspec.lock` `sdks:` requires
  `dart >=3.13.0` and `flutter >=3.47.0`, and CI pins 3.47.5.
- **Recommendation:** raise to `sdk: ^3.13.0` and `flutter: ^3.47.0` everywhere (it is one constant per file).
  Optionally add a check that every member's constraint equals the root's.

### R-14 Dependency hygiene and checker gaps (Low, maintainability, S)
- **Evidence:** declared `dependencies:` with no `package:<dep>/` import in that package's lib/bin
  (heuristic). Examples: `cupertino_icons` in all 4 apps, `wonky_write: sqlite_async, characters`,
  `wonky_sheets: path, path_provider, collection, serverpod_offline_sync_client`, `wonky_slides:
  serverpod_offline_sync_client`, `wonky_sheets_core: csv, image, uuid, meta, wonky_core`, `wonky_write_core:
  clock, wonky_core`, `wonky_server: collection, uuid, serverpod_offline_sync`, and `collection` in 6 more
  packages. Some may be intentional: plugin registration, or `serverpod_offline_sync` needed by the generator.
  `tool/check_dependencies.dart` checks allowed lists and import edges, but it does not check (a) unused
  dependencies, (b) imports in `test/` against `dev_dependencies`, or (c) third-party members. Lower-bound
  drift: `archive ^4.0.0` vs `^4.5.1`, `image ^4.5.4` vs `^4.12.0`, `crypto`, `meta`, `uuid` (the workspace
  resolves one version, so this is cosmetic). There is no Dependabot or Renovate config.
- **Recommendation:** add an "unused dependency" warning to the checker (whitelist plugins), and
  check `test/` imports. Add `.github/dependabot.yml` for `pub` (directory `/`) and `github-actions`.

### R-15 Implementation imports (Low, maintainability, M)
- **Evidence:** `// ignore: implementation_imports` of `package:pdf/src/...` in
  `wonky_sheets_core/lib/src/io/print/pdf_renderer.dart:7`, `wonky_write_core/lib/src/export/pdf/pdf_exporter.dart:13`
  and `wonky_slides_core/lib/src/export/pdf/slides_pdf_exporter.dart:31`. `dart_eval/src` is imported in
  `wonky_sheets_script` (3 places) and `wonky_server/lib/src/sheets/headless/sheets_core_internal.dart`
  (`ignore_for_file`). All other suppressions are benign (~35 in hand-written code in total, mostly
  `prefer_initializing_formals` and `avoid_print` in benchmarks).
- **Recommendation:** for `pdf`, wrap the internal use in one adapter file in `wonky_charts` or a new
  `wonky_pdf` helper, so an upgrade touches one place, and pin `pdf` to an exact version with a comment.
  `dart_eval` is vendored, so expose what is needed from its public library in a PATCHES.md entry.

### R-16 Real time in tests (Low, testing, M)
- **Evidence:** `DateTime.now()` appears in 57 test files (server 29, sheets 8, slides 4, sync_kit_flutter 4, app 4, …).
  specs/15 §4 and §11 say "No real time … seeds and clocks are injected". Only 2 `Future.delayed` and no `sleep(`
  were found, and no unseeded `Random()` in real tests.
- **Recommendation:** audit for assertions that depend on the wall clock (date boundaries, "just now" labels).
  Use `withClock(Clock.fixed(...))` (package `clock` is already a dependency) or pass explicit times.

### R-17 Deploy pipeline (Low, build, S)
- **Evidence:** `deploy.yml` needs `wonky_server/scloud.yaml` ("commit the scloud.yaml it creates"), which is
  missing. The `.scloudignore` opts in `!web/**`, which uploads `canvaskit/*.symbols` (~6 MB per app) and both
  the dart2js and dart2wasm outputs. The Flutter setup in the deploy job is not cached.
- **Recommendation:** when deploy is set up, exclude `web/*/canvaskit/*.symbols` and the
  `canvaskit/chromium` variant that is unused under skwasm (if the JS fallback is wanted, keep it). Add `cache: true`.

### R-18 Dictionaries in every bundle (Low, perf/build, S)
- **Evidence:** `packages/wonky_spellcheck/dictionaries` (13 MB: da-DK.dic 3.9 MB, nl-NL 2.7 MB, sv-SE 2.5 MB, …)
  is a package asset and is therefore copied into every app that depends on `wonky_app`, including Drive, which
  has no spell-checking. Assets are fetched lazily on the web, so runtime cost is low, but deploy size and the
  service-worker cache list grow.
- **Recommendation:** serve the dictionaries once from the server (`/dict/…`) with long cache headers instead of
  per-app assets, or at least gzip and brotli them (.dic compresses ~4–5×). Make sure the server sends
  `Content-Encoding` for `.dic`, `.wasm` and `.ttf`.

### R-19 Migration definition size (Low, maintainability, S)
- **Evidence:** `wonky_server/migrations/*/definition.json` is ~550 KB each, so 19 migrations take 15 MB
  (91 files). This is normal for Serverpod but grows linearly.
- **Recommendation:** nothing urgent. Before v1, consider squashing the pre-release migrations into a new baseline.

### R-20 Minor items (Low, DX, S)
- The app pubspecs keep the `flutter create` boilerplate comments (`wonky_write/pubspec.yaml:1-31`, `flutter:` section).
- A dev DB password is committed in `.vscode/tasks.json` and `tests.yml` (template practice, local
  embedded DB only; worth a comment that it is non-secret).
- `wonky_sheets` has no `sheets_en_XA.arb` (the other apps have pseudo-locales); the `ar_XB` RTL pseudo-locale is still open.
- `dart_test.yaml` and analysis files are copy-pasted (see R-6/R-9). Shared test helpers are duplicated:
  `test/support/property.dart` is byte-identical in `wonky_code`, `wonky_rich_text` and `wonky_write_core`. Move it to a
  `wonky_test_support` package or to `wonky_core/testing.dart`.

## What is good (keep)
- A pub workspace with one lock file and documented override handling for Serverpod Cloud (pubspec.yaml comments).
- `dart analyze --fatal-infos` over all 28 members plus `tool/` is **clean**. `dart format` is enforced.
- The test matrix is derived from `workspace:`, so new packages are tested automatically. The single required
  "All tests" check removes the need for ruleset churn. Vendored suites (super_editor, attributed_text, dart_eval) run too.
- `tool/check_dependencies.dart` (987 lines) enforces the spec 01 §2.1 rules, including Flutter-transitive
  detection through `package_graph.json`, the Sheets "no compiler/analyzer in the app" ban, family isolation and
  undeclared imports.
- Code is well modularised. There are only 17 genuinely hand-written files over 1500 lines and none over 2600.
  The Slides app (~100k lines) has none over 1500.
- Very low debt markers: 7 TODO, 0 FIXME, 5 HACK/XXX in app code. There are no `print(` calls in lib.
- 7,281 `test(` and 1,326 `testWidgets(` calls in total; tests skip almost nothing.

---

## Appendix A: test inventory per package

`libLOC` = hand-written lib/bin lines (excluding `generated/`, but *including* committed l10n gen. The
adjusted column excludes l10n gen and generated data). Test counts come from a grep of `test(` / `testWidgets(`
in test/ and integration_test/ (rough). `skip` = `skip:` occurrences, mostly false positives (named
params) except wonky_spellcheck. `gold` = files with golden tests.

| Package | lib files | lib LOC | adj. lib LOC | test files | test LOC | test( | testWidgets( | gold | test/lib ratio (adj) |
|---|---|---|---|---|---|---|---|---|---|
| wonky_server | 278 | 76,470 | 76,470 | 130 | 49,238 | 1,208 | 0 | 0 | 0.64 |
| wonky_client (generated) | 288 | 58,070 | – | 0 | 0 | 0 | 0 | 0 | – |
| wonky_write | 148 | 66,143 | 49,573 | 58 | 14,246 | 329 | 121 | 0 | 0.29 |
| wonky_sheets | 321 | 117,963 | 95,193 | 119 | 22,480 | 541 | 187 | 1 (no masters) | 0.24 |
| wonky_drive | 51 | 12,730 | 9,426 | 20 | 5,145 | 89 | 86 | 3 (no masters) | 0.55 |
| wonky_slides | 311 | 130,434 | 101,558 | 119 | 32,366 | 671 | 419 | 0 | 0.32 |
| wonky_app | 194 | 71,956 | 54,926 | 66 | 15,517 | 247 | 387 | 3 (no masters) | 0.28 |
| wonky_charts | 58 | 19,317 | | 21 | 4,945 | 278 | 0 | 0 | 0.26 |
| wonky_charts_flutter | 14 | 2,967 | | 4 | 421 | 7 | 6 | 0 | **0.14** |
| wonky_code | 39 | 7,048 | | 19 | 2,740 | 168 | 0 | 0 | 0.39 |
| wonky_code_flutter | 4 | 1,166 | | 3 | 519 | 12 | 20 | 0 | 0.45 |
| wonky_core | 32 | 10,216 | | 15 | 1,588 | 128 | 0 | 0 | **0.16** |
| wonky_fonts | 4 | 867 | | 1 | 117 | 9 | 0 | 0 | 0.13 |
| wonky_mcp_stdio | 3 | 620 | | 1 | 597 | 14 | 0 | 0 | 0.96 |
| wonky_numfmt | 15 | 4,055 | | 3 | 306 | 26 | 0 | 0 | **0.08** (2 sheets_core tests import it) |
| wonky_rich_editor | 12 | 4,351 | | 5 | 2,155 | 60 | 39 | 0 | 0.50 |
| wonky_rich_text | 12 | 2,137 | | 2 | 447 | 23 | 0 | 0 | 0.21 |
| wonky_sheets_core | 308 | 96,171 | | 148 | 33,932 | 1,486 | 0 | 0 | 0.35 |
| wonky_sheets_script | 35 | 18,683 | 14,401 | 12 | 2,117 | 103 | 0 | 0 | **0.15** |
| wonky_slides_core | 219 | 58,300 | | 88 | 21,749 | 995 | 0 | 0 | 0.37 |
| wonky_spellcheck | 11 | 2,537 | | 8 | 1,637 | 51 | 0 | 0 | 0.65 (dictionary tests skip when files are absent) |
| wonky_sync_kit | 11 | 924 | | 6 | 668 | 33 | 0 | 0 | 0.72 |
| wonky_sync_kit_flutter | 20 | 2,324 | | 8 | 1,075 | 34 | 0 | 0 | 0.46 |
| wonky_sync_models | 11 | 1,140 | | 8 | 865 | 52 | 0 | 0 | 0.76 |
| wonky_ui | 42 | 9,410 | 8,414 | 13 | 2,031 | 21 | 61 | 0 | 0.24 (30 widget files / 13 test files) |
| wonky_write_core | 116 | 40,954 | 39,385 | 22 | 8,756 | 289 | 0 | 0 | **0.22**, against the ≥90 % coverage target |
| third_party/serverpod_offline_sync | 31 | 14,115 | | 0 | 0 | 0 | 0 | 0 | 0 (patched, no tests; PATCHES.md OS-n) |
| third_party/dart_eval | 224 | 44,639 | | 39 | 10,010 | 462 | 0 | 0 | 0.22 |

Low ratios worth a look: `wonky_numfmt` (number formats are high-risk logic), `wonky_sheets_script`,
`wonky_core` (holds the MCP tool schemas: `mcp/slides_tools.dart` 1,724 lines, `sheets_tools.dart` 1,683),
`wonky_write_core` (RTF/ODT/HTML importers ~1.5–1.9k lines each; some coverage comes from the server's
12 test files that import it), `wonky_charts_flutter`, and the patched `serverpod_offline_sync` with zero tests.

Tag usage (`@Tags`): integration 16, property 11, slow 9 (+1 `tags: ['slow']`), golden 7, e2e 7, live-ai 1.
Integration tests: `wonky_write/integration_test` (5 journeys + support), `wonky_sheets/integration_test/chart3d_backends_test.dart`.

## Appendix B: 40 largest hand-written Dart files

Excludes `generated/`, `wonky_client`, `third_party`, l10n gen outputs and `serverpod_test_tools.dart`.
`*` = generated data checked in under lib (not hand-written, but also not excluded by tooling).

| # | Lines | File |
|---|---|---|
| 1 | 4282 | `packages/wonky_sheets_script/lib/src/api/api_index_data.dart` * |
| 2 | 2552 | `packages/wonky_sheets_core/lib/src/formula/recalc/formula_engine.dart` |
| 3 | 2251 | `packages/wonky_sheets_script/lib/src/api/api_source.dart` |
| 4 | 2185 | `wonky_server/lib/src/platform/drive/drive_service.dart` |
| 5 | 2127 | `packages/wonky_charts/lib/src/layout/layout_cartesian.dart` |
| 6 | 2057 | `packages/wonky_sheets_core/lib/src/io/write/ir_to_rows_planner.dart` |
| 7 | 1968 | `packages/wonky_sheets_script/lib/src/host/script_host.dart` |
| 8 | 1962 | `wonky_sheets/lib/features/charts/editor/chart_editor_panel.dart` |
| 9 | 1939 | `packages/wonky_write_core/lib/src/import/rtf/rtf_importer.dart` |
| 10 | 1724 | `packages/wonky_core/lib/mcp/slides_tools.dart` |
| 11 | 1683 | `packages/wonky_core/lib/mcp/sheets_tools.dart` |
| 12 | 1661 | `wonky_write/lib/features/editor/commands/write_editor_commands.dart` |
| 13 | 1624 | `packages/wonky_slides_core/lib/src/export/pdf/slide_pdf_painter.dart` |
| 14 | 1604 | `packages/wonky_write_core/lib/src/export/pdf/pdf_exporter.dart` |
| 15 | 1590 | `packages/wonky_slides_core/lib/src/geometry/shape_library.dart` |
| 16 | 1569 | `packages/wonky_write_core/lib/src/import/code_page_tables.dart` * |
| 17 | 1560 | `wonky_write/lib/features/sync/document_sync_controller.dart` |
| 18 | 1559 | `packages/wonky_app/lib/src/testing/fake_board_repository.dart` |
| 19 | 1511 | `packages/wonky_write_core/lib/src/import/html/html_importer.dart` |
| 20 | 1492 | `wonky_sheets/lib/features/conditional_format/cf_panel.dart` |
| 21 | 1476 | `packages/wonky_write_core/lib/src/theme/resolve/resolved_theme.dart` |
| 22 | 1474 | `wonky_slides/lib/features/navigator/slide_navigator.dart` |
| 23 | 1462 | `packages/wonky_sheets_core/lib/src/io/xlsx/xlsx_importer.dart` |
| 24 | 1460 | `wonky_sheets/lib/features/scripts/script_service.dart` |
| 25 | 1458 | `wonky_sheets/lib/features/scripts/editor/script_editor_screen.dart` |
| 26 | 1447 | `packages/wonky_write_core/lib/src/import/odt/odt_importer.dart` |
| 27 | 1424 | `wonky_slides/lib/features/history/slides_version_view.dart` |
| 28 | 1414 | `wonky_slides/lib/features/themes/editor/theme_editor_sections.dart` |
| 29 | 1404 | `packages/wonky_sheets_core/lib/src/io/print/pdf_renderer.dart` |
| 30 | 1397 | `packages/wonky_app/lib/src/commands/shell_commands/general_commands.dart` |
| 31 | 1388 | `wonky_slides/lib/features/present/present_controller.dart` |
| 32 | 1371 | `wonky_write/lib/commands/screen_commands.dart` |
| 33 | 1364 | `wonky_slides/lib/commands/canvas_commands.dart` |
| 34 | 1326 | `packages/wonky_sheets_script/lib/src/testing/conformance.dart` |
| 35 | 1319 | `wonky_slides/lib/features/outline_view/outline_view.dart` |
| 36 | 1311 | `wonky_sheets/lib/features/import/import_dialog.dart` |
| 37 | 1308 | `wonky_server/lib/src/sheets/scripts/script_service.dart` |
| 38 | 1305 | `wonky_server/lib/src/sheets/ai/sheets_ai_service.dart` |
| 39 | 1299 | `packages/wonky_write_core/lib/src/export/rtf/rtf_exporter.dart` |
| 40 | 1296 | `wonky_write/lib/features/theme_editor/theme_editor_screen.dart` |

Files > 1500 lines per package (same exclusions; 19 in total, 17 hand-written): wonky_write_core 4 (1 generated
data), wonky_sheets_script 3 (1 generated data), wonky_write 2, wonky_slides_core 2, wonky_sheets_core 2,
wonky_core 2, wonky_sheets 1, wonky_server 1, wonky_charts 1, wonky_app 1; wonky_slides 0, wonky_drive 0. 99 files are over 1000 lines.

Committed generated Dart **not** in this table: l10n gen (12 files, ~89.5k lines; the largest is
`wonky_slides/lib/l10n/gen/slides_localizations_en.dart` at 15,868), `serverpod_test_tools.dart` 10,865,
`wonky_client` 58k, and the server and sync-model `generated/` folders.

## Appendix C: repo weight

- Pack size 25 MB; 5,891 tracked files.
- Largest tracked binaries: spellcheck `.dic` (da-DK 3.9 MB, nl-NL 2.7 MB, sv-SE 2.5 MB, fr-FR 1.3 MB, …, 13 MB total);
  `sqlite3.wasm` 750 KB ×4; TTFs 9.1 MB ×3; migrations 15 MB; the Sheets macOS app icon 572 KB.
- Ignored local build outputs: `wonky_server/web/{write,slides}` (84 MB and 96 MB; `canvaskit/` is 37 MB of each,
  holding canvaskit, skwasm, skwasm_heavy, wimp, chromium and webparagraph variants plus `.symbols`).

## Appendix D: CI summary

| Workflow | Trigger | Runs | Gaps |
|---|---|---|---|
| analyze.yml | push/PR main | `dart analyze --fatal-infos` all members + tool; `check_dependencies.dart` | no generated-code freshness check (R-3) |
| format.yml | push/PR main | `dart format --set-exit-if-changed` all members + tool | – |
| tests.yml | push/PR main | server (`serverpod generate` + `dart test`, embedded PG cached); matrix per member with tests (`-x golden,slow,e2e`); super_editor + attributed_text | server runs `slow` (R-10); no goldens (R-2); no web build (R-1); no coverage |
| e2e.yml | nightly 02:23 + manual | 5 Write journeys on macOS against a dev server | web, Sheets/Slides/Drive journeys, 11–16 missing (R-9) |
| deploy.yml | push to `deploy` | Serverpod Cloud deploy | `scloud.yaml` missing (R-17) |
| cla.yaml | PR/comment | CLA assistant | – |

Missing: nightly `slow`/property/coverage, goldens, web/desktop build, Dependabot, and generated-code and l10n
freshness checks. All jobs pin Flutter 3.47.5 and use `subosito/flutter-action` with `cache: true`. Each of the
~26 matrix jobs runs `flutter pub get` for the whole workspace.
