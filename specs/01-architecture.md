# 01 · Architecture and Repository Layout

## 1. Decision summary

| # | Decision | Rationale |
|---|----------|-----------|
| A1 | **One Serverpod server** (`wonky_server`) serves both apps, auth, drive, sharing, comments, MCP, AI, and both Flutter web builds. | One account system, one drive, one MCP endpoint, cross-app features (templates, search, sharing) without service-to-service calls. |
| A2 | **Four Flutter apps** (v2; `wonky_drive`, `wonky_write`, `wonky_sheets`, `wonky_slides`) sharing packages (`packages/wonky_app` shell, `wonky_ui`, cores), all served by `wonky_server` on one origin (`/drive/`, `/write/`, `/sheets/`, `/slides/`; `/` → `/drive/`, Wonky Drive's home, v2 review B4) with one shared sign-in. | Smaller bundles, independent release cadence, clear ownership; shared shell keeps UX identical; same origin makes the session cookie shared. |
| A3 | **Pure-Dart "core" packages** for logic needed on both server and client (Markdown↔Delta, OT helpers, exporters, formula engine, number formats, XLSX/CSV mapping, tool schemas). | Headless MCP tools, server-side export/import, AI tools and version materialization need the same logic as the apps. |
| A4 | **Write: server-authoritative OT** over Quill Deltas on typed Serverpod streams; op log in Postgres. | Required by the brief; Delta has `compose/transform/invert/transformPosition`. |
| A5 | **Sheets: offline-first sync over RevLog** ([17](17-revlog-sync.md)): one spreadsheet = one RevLog file; the server sequences change sets into a revision-ordered log; clients keep a local cache and a durable outbox; per-cell rows with deterministic ids; stable row/column ids; formulas stored with id-based references. (Until M13 this was the vendored `serverpod_offline_sync` CRDT engine.) | Offline-first requirement; column-level "last arrival wins" merges; concurrent row/column insertion merges without rewriting cells or formulas; a server-ordered log is simpler, faster and checkable on the server (protection, limits). |
| A6 | **Everything is a command**; undo is per-user forward ops. | Undo-for-everything + MCP control (see 08). |
| A7 | **MCP hosted in the server** (`mcp_dart`, Streamable HTTP) + UI bridge relayed over a Serverpod stream. | Works identically for web and desktop clients. |
| A8 | **Dart scripting via `dart_eval`**: compile on the server, execute bytecode on server (triggers, scheduled jobs) and client (custom functions, macros) inside a sandbox worker. | Keeps the analyzer out of the web bundle; sandboxed by default. |
| A9 | State management: Flutter's layered architecture, `ChangeNotifier` controllers, `provider` for DI, `go_router`. | Official guidance, low ceremony. |
| A10 | (v2) **Slides: offline-first sync like Sheets, over RevLog** (one deck = one RevLog file, column-level "last arrival wins", `slides.rows` undo) with a pure-Dart `wonky_slides_core`. Both apps share `wonky_revlog` (core) and `wonky_revlog_flutter` (client) ([17](17-revlog-sync.md)). | Object-based slide content maps onto rows; offline works; one sync stack for both apps ([Slides 02](wonky_slides/02-data-model.md)). |
| A11 | (v2) **Shared leaf packages** for code highlighting (`wonky_code`, `wonky_code_flutter`, extracted from Write) and charts (`wonky_charts`, `wonky_charts_flutter`, extracted from Sheets), used by Write/Sheets and Slides. | Slides needs both; the app packages still never import each other. |
| A12 | (v2) **One drive, filtered app homes**: Wonky Drive shows every kind and owns uploads, previews and storage; each app home shows only its kind. A 50 MB per-user quota is enforced server-side. | User requirement; [Drive 01](wonky_drive/01-overview.md), [Drive 03](wonky_drive/03-storage-quota.md). |
| A13 | (v2) **Web only for now.** v2 is built, tested and shipped for the web. The desktop targets (`macos/` etc.) **keep compiling** — CI's nightly macOS integration-test job (`e2e.yml`) builds Write for macOS and shared code keeps its conditional imports — but desktop-only features are **disabled or deferred**: native menubar (`PlatformMenuBar`), separate desktop binaries with custom URL schemes and desktop packaging, multi-window (Slides' presenter second window, desktop multi-window spikes), desktop printing extras and OS drag-and-drop in native builds (`desktop_drop`). New v2 code needs no desktop-specific paths; where a platform split is unavoidable the desktop branch may be a stub ("Not available on desktop yet"). The desktop notes in the v1 app specs describe that deferred later state. | User decision (v2 review, Q9/Q29/Q30): one platform to build and verify keeps M8–M11 small. |
| A14 | (v2) **One window, also on the web.** No v2 feature opens a second browser window or tab (including Slides' audience view, which runs on another device or browser joined to a presentation session, [Slides 10 §5](wonky_slides/10-presenting-and-pdf.md)). | Single-window rule of [03 §1](03-app-shell-and-navigation.md) without exceptions beyond external links and Google sign-in (v2 review, Q5). A presenting-only second window is a possible later addition. |

## 2. Repository layout

**History (M0 starting point).** The repository was created from the Serverpod project
template and two `flutter create` apps; M0 (steps below) turned it into the target layout. The
table records where each original folder went:

| Folder | State | Fate |
|--------|-------|------|
| `wonky_server/` | Serverpod 4.1 server: email/password auth (`JwtConfigFromPasswords`, `ServerpodCloudEmailIdpConfig`), cloud storage, `AppConfigRoute`, `FlutterRoute` serving `web/app`, `flutter_build` script, greeting example endpoint | **Kept** — this is *the* server. Example endpoint/model removed in M0. |
| `wonky_client/` | Generated client | **Kept** (regenerated, never edited) |
| `wonky_flutter/` | Template Flutter app: client bootstrap (`client.dart`: server URL from `assets/config.json`, `FlutterAuthSessionManager`), `driver.dart`, sign-in screen | **Reference only** — its client/auth/driver setup is ported into `packages/wonky_app` and the two apps, then the folder is **deleted** in M0 |
| `wonky_write/`, `wonky_sheets/` | Fresh `flutter create` apps (counter demo), not yet in the pub workspace, own `pubspec.lock`, SDK `^3.13.4` | **Become the two apps** (M0: join the workspace, wire to the server) |
| `specs/` | These specs; app specs in `specs/wonky_write/` and `specs/wonky_sheets/` | — |

Root `pubspec.yaml` is a pub workspace listing every package below (it started as
`wonky_client`, `wonky_server`, `wonky_flutter`). `.mcp.json` (git-ignored, per machine) points
the `serverpod` MCP at `wonky_server`.

**CI** (`.github/workflows`; all workflows pin Flutter 3.47.5, the workspace lock file needs
Flutter ≥ 3.47.0) covers every workspace member, whose list is derived from the root
`workspace:` so new packages are picked up automatically:

- `analyze.yml`: `dart analyze --fatal-infos` over all members and `tool/` (lints from
  `packages/wonky_lints`, 11 §6); the dependency check `dart run tool/check_dependencies.dart`
  (§2.1, including unused dependencies and the imports of tests and tools); `generated`:
  `tool/check_generated.sh` regenerates the committed generated code (Serverpod, gen-l10n and
  the `en_XA` pseudo-locales, the board's spec index, the RevLog schemas, the Sheets script
  API index) and fails on any difference (CQ-64b).
- `format.yml`: `dart format --output=none --set-exit-if-changed` over the same folders
  (generated code included — the generators' output is formatted).
- `tests.yml`: the server tests (embedded Postgres, after `serverpod generate`, `-x slow`), one
  matrix job per other member that has tests (`dart test -x slow,e2e`, or `flutter test -x
  golden,slow,e2e` for Flutter packages), and the vendored suites of `super_editor` (`flutter
  test -x golden`) and `attributed_text` (§2.3 rule 4), each after `dart analyze --fatal-infos`
  (they resolve their own lock files, so the `analyze` job doesn't cover them); *All tests* is
  the required check.
- `build.yml`: the `--wasm` web build of every app through `tool/build_web.dart` with the
  bundle-size budgets of `tool/web_budgets.json` (sizes in the job summary; CQ-64a).
- `goldens.yml`: image goldens in the pinned `ghcr.io/cirruslabs/flutter` container for the
  packages with committed masters; a manual run with `update` renders new masters as an
  artifact (`tool/update_goldens.sh` does the same locally with Docker; 15 §7).
- `nightly.yml`: `slow` tests (members and server), the `perf` suites and Sheets core
  benchmarks, long property runs with fixed and random seeds (15 §3, §8). `e2e.yml`: the Write
  E2E journeys on macOS, nightly.
- `deploy.yml` deploys to Serverpod Cloud (`wonky_server/scloud.yaml`; its pre-deploy hook
  runs `serverpod generate` and `serverpod run flutter_build`).

**Target layout** (reached in M0; the tree is the current layout).

```
wonky/
├── pubspec.yaml                         # root Dart pub workspace listing every package below (+ server overrides, §2.3)
├── pubspec_overrides.yaml               # Flutter-only path overrides of vendored packages (§2.3)
├── .mcp.json                            # serverpod MCP → wonky_server; dart MCP
├── AGENTS.md                            # agent instructions (project summary, MCP usage, checklist)
├── specs/                               # suite-level specs (this folder)
│   ├── wonky_drive/                     #   Drive app specs (v2)
│   ├── wonky_write/                     #   Write app specs
│   ├── wonky_sheets/                    #   Sheets app specs
│   └── wonky_slides/                    #   Slides app specs (v2)
├── icons/                               # product icon sources (Work, Drive, Write, Sheets, Slides; 02 §5)
├── wonky_server/                        # THE Serverpod server (auth, drive, storage, sharing, Write OT, Sheets/Slides sync,
│                                        #   MCP, AI, and the web server that serves the four Flutter web builds — §2.4)
├── wonky_client/                        # generated Serverpod client (never edit)
├── wonky_drive/                         # (v2) Flutter app: Wonky Drive (uploads, previews, storage page) — web (A13)
├── wonky_write/                         # Flutter app: Wonky Write (super_editor integration, UI) — web; desktop compiles (A13)
├── wonky_sheets/                        # Flutter app: Wonky Sheets (grid, UI, sync DB, script worker) — web; desktop compiles
├── wonky_slides/                        # (v2) Flutter app: Wonky Slides (canvas, navigator, builds, presenting, sync DB)
├── packages/
│   ├── wonky_core/                      # pure Dart: ids, roles, command/undo abstractions, MCP tool schemas, utils
│   ├── wonky_ui/                        # Flutter: theme + custom shad-style widgets (no server deps)
│   ├── wonky_app/                       # Flutter: shell (client bootstrap, auth, routing, drive, sharing, comments UI,
│   │                                    #          history UI, presence, settings, command system, MCP bridge, AI panel,
│   │                                    #          product icons in assets/icons/)
│   ├── wonky_sync_models/               # pure Dart: id helpers of Sheets + Slides (UUIDv5 ids, id generators,
│   │                                    #   fractional indexes; base-62 from wonky_revlog). Name kept from the CRDT era
│   ├── wonky_write_core/                # pure Dart: Delta schema, Markdown⇄Delta, OT helpers, exporters, theme model
│   ├── wonky_sheets_core/               # pure Dart: addressing, formula parser/evaluator/functions, number formats,
│   │                                    #   recalculation graph, xlsx/csv/ods mapping, sheet model helpers
│   ├── wonky_sheets_script/             # pure Dart: dart_eval bridge (Spreadsheet API), compiler & runtime wrappers
│   ├── wonky_slides_core/               # (v2) pure Dart: deck model, mutation planner, layout/auto-fit, animation timeline,
│   │                                    #   code type-in model, PDF renderer, headless deck for MCP (Slides 01 §7)
│   ├── wonky_charts/                    # (v2) pure Dart: chart spec, data model, layout, scene, 3D scene, SVG/PDF/PNG renderers
│   ├── wonky_charts_flutter/            # (v2) Flutter: chart canvas painter, flutter_scene GPU backend for 3D charts
│   ├── wonky_code/                      # (v2) pure Dart: languages, token classes, palettes, TextMate engine (copied from
│   │                                    #   syntax_highlight) + highlight.js fallback tokenizer, code layout/type-in
│   ├── wonky_numfmt/                    # (v2) pure Dart: number-format patterns and date serials (from Sheets core; Slides 08 §2.5)
│   ├── wonky_rich_text/                 # (v2) pure Dart: Delta inline schema, Delta helpers, link/character rules,
│   │                                    #   RichTextNormalizer, inline Markdown codec (shared by Write and Slides)
│   ├── wonky_fonts/                     # (v2) pure Dart: font registry, FontProvider, BundledFonts manifest + TTFs
│   │                                    #   as package assets in fonts/ (Slides 05 §3.1)
│   ├── wonky_spellcheck/                # (v2) pure Dart: Hunspell engine moved from wonky_write_core + dictionaries as
│   │                                    #   package assets in dictionaries/ (Slides 03 §14)
│   ├── wonky_code_flutter/              # (v2) Flutter: `CodeView`, `CodeTextStyler`, `CodeEditorField` (re_editor)
│   ├── wonky_rich_editor/               # Flutter: lightweight WYSIWYG Markdown editor on super_editor (Markdown ⇄
│   │                                    #   document codec, `WonkyRichEditor`, toolbar) — the board's composer (16 §7.3);
│   │                                    #   also the super_editor spelling glue shared with Slides (`DocumentSpelling`)
│   ├── wonky_revlog/                    # pure Dart: RevLog core (server-sequenced op log): RevSchema, wire codec, apply rules,
│   │                                    #   validation, RevOverlay, RevSyncCore, chunker; RowChange/MutationPlan/UndoInverter
│   ├── wonky_revlog_flutter/            # Flutter: RevLog client — local cache (RevLocalStore), transport, per-file
│   │                                    #   connection with bootstrap pages (RevFileSync), per-user RevLogClient; fakes in testing.dart
│   ├── wonky_mcp_stdio/                 # tiny CLI: stdio ↔ Streamable HTTP proxy
│   └── wonky_lints/                     # shared analysis options (dart.yaml, flutter.yaml; 11 §6), a dev dependency of every package
├── tool/                                # repository scripts: dependency rules, web build + sizes, generated-code check, goldens, pseudo-locale
└── third_party/                         # vendored (locally patched) copies of third-party packages — see §2.3
    ├── super_editor/                    #   (+ super_text_layout / attributed_text only if patches need them)
    ├── dart_quill_delta/                #   only if OT fixes are needed
    └── dart_eval/
```

Paths in the specs are **package-relative** (`wonky_sheets_core/lib/model/`,
`wonky_write/lib/features/editor/`, `wonky_server/lib/src/…`); packages under `packages/` are
referred to by package name.

**M0 migration steps:**

1. Add `wonky_write` and `wonky_sheets` to the root workspace (`resolution: workspace`, delete
   their `pubspec.lock`), align SDK constraints (`environment.sdk`/`flutter`) across all
   packages and the CI Flutter version (CI pins 3.44.4; the new apps were created with Dart
   3.13).
2. Scaffold `packages/*` (workspace members) and `third_party/` (§2.3).
3. Port `wonky_flutter/lib/client.dart` (server URL from `config.json`, connectivity monitor,
   `FlutterAuthSessionManager`) and the sign-in flow into `wonky_app`; add `lib/driver.dart`
   (flutter_driver entry, text entry emulation off) to both apps.
4. Server: replace the single `web/app` `FlutterRoute` with the two app routes and update
   `flutter_build` (§2.4); list both apps under `serverpod: flutter_apps:`; enable cookie auth
   (§2.5); add `shared_packages: [../packages/wonky_sync_models]` to `config/generator.yaml`;
   remove the greeting example (endpoint, model, test).
5. Delete `wonky_flutter/` and remove it from the workspace.
6. Extend CI (analyze/format/test) to every workspace package, add the dependency-rule check
   (§2.1).
7. Update `AGENTS.md` (app names, `driver.dart` locations, `flutter_apps` aliases).

**(v2) Adding an app (Drive and the Slides skeleton in M8)** follows the same steps: create the
Flutter app in the workspace (`resolution: workspace`, `lib/driver.dart`), add its `webApps`
entry, its `FlutterRoute`, its `flutter_apps` alias and port (§2.4), its origin to
`allowedOrigins`, its build to `flutter_build`, its CI matrix entry and dependency-rule row
(§2.1), its web icons and favicon (02 §5; desktop icons only so the desktop target compiles,
A13), its `WonkyAppKind` value and `config.json` URL, and its lines in `AGENTS.md`. The package
extractions of A11 (`wonky_code*`, `wonky_charts*`, `wonky_numfmt`), the sync kit, `wonky_rich_text`,
`wonky_fonts` and `wonky_spellcheck` are moves without behavior change, verified by the existing
Write/Sheets tests and goldens (Drive 05 waves 1–2).

### 2.1 Package dependency rules (enforced by a CI script)

Enforced by `dart run tool/check_dependencies.dart` (repository root; CI job `dependencies` in
`analyze.yml`). The script mirrors this subsection in its `rules` table — change both together.

```
wonky_core            → (common utilities only, see below)
wonky_code            → (v2) wonky_core, string_scanner, highlight (TextMate engine copied in, Slides 07 §2.2) — leaf
wonky_code_flutter    → (v2) wonky_code, wonky_ui, shad, re_editor                       — leaf
wonky_rich_editor     → super_editor (vendored), wonky_rich_text, wonky_ui, shad, markdown — leaf (WYSIWYG Markdown field, 16 §7.3)
wonky_numfmt          → (v2) intl, petitparser                                           — leaf (Slides 08 §2.5)
wonky_rich_text       → (v2) wonky_core, dart_quill_delta, markdown                      — leaf (Delta inline schema + codec)
wonky_fonts           → (v2) (pure-Dart manifest; TTFs as package assets)               — leaf (Slides 05 §3.1)
wonky_spellcheck      → (v2) wonky_core (Hunspell engine; dictionaries as package assets) — leaf
wonky_charts          → (v2) wonky_core, wonky_numfmt, pdf, image, vector_math           — leaf
wonky_charts_flutter  → (v2) wonky_charts, wonky_ui, shad, flutter_scene, vector_math    — leaf
wonky_write_core      → wonky_core, wonky_code (v2; was highlight), wonky_rich_text (v2), wonky_fonts (v2),
                        dart_quill_delta (9.x by default; see §2.2), markdown,
                        html, pdf, archive, xml, image, crypto
wonky_sheets_core     → wonky_core, wonky_revlog, wonky_charts (v2), wonky_numfmt (v2), wonky_sync_models (ids only), petitparser, intl, timezone,
                        archive, xml, csv, pdf, image (in-house OOXML/ODS reader and writer on archive + xml — Sheets 11 §5.1)
wonky_slides_core     → (v2) wonky_core, wonky_revlog, wonky_sync_models (ids only), wonky_charts,
                        wonky_numfmt, wonky_code, wonky_rich_text, wonky_fonts, pdf, image, vector_math, crypto,
                        html (clipboard HTML: tables and rich text pasted from other apps, Slides 03 §12.5)
wonky_sheets_script   → wonky_core, wonky_sheets_core, dart_eval, eval_annotation, native_synchronization
wonky_revlog          → wonky_core, archive, collection, meta, uuid (pure Dart; RevLog core: schema, codec, apply rules, client sync state machine)
wonky_revlog_flutter  → wonky_revlog, wonky_app, wonky_ui, wonky_client, wonky_core (roles), sqlite_async, clock, collection, meta,
                        uuid, web (RevLog client: cache, transport, per-file connection)
wonky_sync_models     → wonky_revlog (base-62 codec), uuid (pure Dart; id helpers only — no Serverpod models since RevLog R8)
wonky_server          → serverpod, serverpod_auth_idp_server, serverpod_cloud_storage, wonky_revlog,
                        wonky_core, wonky_write_core, wonky_sheets_core, wonky_sheets_script, wonky_slides_core (v2),
                        wonky_charts (v2), wonky_code (v2), wonky_sync_models, mcp_dart, http, mime (v2, upload sniffing,
                        Drive 02 §5), dartantic_ai (AI providers: OpenAI, Anthropic, Gemini — 10 §1; pure Dart, no Flutter)
wonky_client          → generated: serverpod_client + module clients (serverpod_auth_idp_client,
                        serverpod_auth_core_client), serverpod_database
wonky_mcp_stdio       → args, http
wonky_lints           → lints, flutter_lints (analysis options only, 11 §6; every package lists it under dev_dependencies)
wonky_ui              → flutter, shad
wonky_app             → wonky_ui, wonky_core, wonky_client, serverpod_flutter, serverpod_auth_idp_flutter, go_router, provider, mcp_dart,
                        wonky_spellcheck (v2; spelling glue and dictionaries moved from Write),
                        wonky_fonts (v2; `AssetFontRegistry` / `BundledAssetFontProvider`, Slides 05 §3.1),
                        wonky_rich_editor (the board's WYSIWYG `MarkdownComposer`, 16 §7.3)
wonky_drive           → (v2) wonky_app, wonky_ui, wonky_core, wonky_client, wonky_code_flutter (text previews), file_picker,
                        file_saver, http (no PDF previews in v2, Drive 02 §6.3)
wonky_write           → wonky_app, wonky_ui, wonky_write_core, wonky_code + wonky_code_flutter (v2), super_editor (vendored), super_clipboard,
                        printing, file_saver, file_picker
wonky_sheets          → wonky_app, wonky_ui, wonky_sheets_core, wonky_sheets_script, two_dimensional_scrollables (auxiliary
                        tables only), super_clipboard, re_editor (+ re_highlight for the Dart grammar),
                        crypto (script file content hashes), printing, file_saver, file_picker,
                        wonky_revlog + wonky_revlog_flutter (RevLog sync, Sheets sync migration spec 06),
                        wonky_sync_models (ids only), wonky_charts_flutter (v2)
                        (charts: the shared engine in wonky_charts + Sheets data resolution in wonky_sheets_core — Sheets 08 §24)
wonky_slides          → (v2) wonky_app, wonky_ui, wonky_slides_core, wonky_revlog, wonky_revlog_flutter, wonky_charts + wonky_charts_flutter,
                        wonky_code_flutter, wonky_rich_text, wonky_fonts, super_editor (vendored; text boxes, Slides 03 §6.1),
                        super_clipboard, printing, file_saver, file_picker, flutter_scene, vector_math, wonky_sync_models
                        (ids only; Slides 01 §7)
```

Forbidden: `wonky_sheets` importing `wonky_sheets_script/compiler.dart`, `testing.dart`,
`package:analyzer` or `package:dart_eval/dart_eval.dart` (the app only runs scripts, A8);
any `*_core` importing Flutter; `wonky_ui` importing client/server code; **(v2) any app family
importing another's packages** — the families are Write (`wonky_write`, `wonky_write_core`),
Sheets (`wonky_sheets`, `wonky_sheets_core`, `wonky_sheets_script`), Slides (`wonky_slides`,
`wonky_slides_core`) and Drive (`wonky_drive`); shared code moves into the shared leaf packages
(`wonky_core`, `wonky_ui`, `wonky_app`, `wonky_code*`, `wonky_charts*`, `wonky_numfmt`,
`wonky_rich_text`, `wonky_rich_editor`, `wonky_fonts`, `wonky_spellcheck`, `wonky_revlog*`);
feature code importing generated server code.

**Unused and undeclared dependencies** (CQ-64i): the script also fails on a `dependencies:` entry
that no `lib/`/`bin/` file imports (move it to `dev_dependencies:` when only tests use it), a
`dev_dependencies:` entry that no test, tool, benchmark, `lib/driver.dart` or
`analysis_options.yaml` uses, and a test/tool/benchmark import of an undeclared package. The few
packages needed without an import are listed with their reason in `_usedWithoutImport`.

**Decided (v2 review, Q3):** code highlighting is **two packages** like the charts —
`wonky_code` (pure Dart: languages, token classes, palettes, the TextMate engine copied from
`syntax_highlight` plus the highlight.js fallback, code layout and type-in; Slides 07 §2) and
`wonky_code_flutter` (`CodeView`, `CodeTextStyler`, `CodeEditorField`). A package is either pure
Dart or Flutter for the dependency check, and `wonky_slides_core` (PDF) and `wonky_server` need
tokenization without Flutter.

**Decided (v2 review, Q4):** `wonky_slides_core` never imports `wonky_write_core`. The pieces
Slides reuses (Delta inline schema and attribute keys, text-run normalization, the Markdown
inline codec) move into the shared leaf **`wonky_rich_text`**; `wonky_write_core` re-exports
them.

**Decided (v2 review, Q23):** the other shared packages are the sync packages (originally
`wonky_sync_kit` + `wonky_sync_kit_flutter` on the CRDT engine; since M13 `wonky_revlog` (pure
Dart) + `wonky_revlog_flutter` (client part), [17](17-revlog-sync.md)), `wonky_fonts` (font registry + TTFs), `wonky_spellcheck`
(pure Hunspell engine; the Flutter glue — `SpellEngine` loader, spelling dialogs — and Write's
emoji picker move into `wonky_app`) and `wonky_numfmt` (Q27).

*Implemented (Drive 05 D-7):* `wonky_write_core` re-exports the moved `wonky_rich_text` names
(`WonkyAttr`, `Attributes`, `DeltaUtils`, `LinkPolicy`, `TextRules`, `InlineRun`,
`InlineMarkdown`, `ImportWarning`, …) and all of `wonky_fonts`, so Write and the server are
unchanged. It does **not** depend on `wonky_spellcheck` (nothing outside the apps spell-checks;
this keeps the 12 MB of dictionaries out of the server upload); its former
`package:wonky_write_core/spellcheck.dart` is `package:wonky_spellcheck/wonky_spellcheck.dart`.
TTFs and dictionaries are Flutter assets declared by the pure-Dart packages (`flutter: assets:`
in their pubspec; Flutter bundles assets of every dependency, keys
`packages/wonky_fonts/fonts/…`, `packages/wonky_spellcheck/dictionaries/…`). The shell exposes the
glue as separate libraries, `package:wonky_app/spellcheck.dart` (with the shared
`PersonalDictionary`), `package:wonky_app/emoji.dart` (emoji data in
`packages/wonky_app/assets/emoji/`) and `package:wonky_app/special_chars.dart` (the special
characters dialog, moved from Write by Slides SL-44; Unicode names in
`packages/wonky_app/assets/unicode/`), plus `showAnchoredPopoverAt` in the main library. Their
strings are in the shell's ARB files; each app passes its own widget-key prefix (`SpellingKeys`,
`EmojiPickerKeys`, `SpecialCharsKeys`: `write` by default, `slides`).

Client code that more than one app needs lives in the shell (CQ-53), in two more libraries so
their names never clash with an app's: `package:wonky_app/platform.dart` (platform glue with web
and desktop implementations: drops from other applications, the system clipboard
`WonkyClipboard` that the apps' clipboard facades wrap, the image clipboard, the in-app PDF
viewer and printing) and `package:wonky_app/uploads.dart` (the durable `PendingUploadQueue`
with its stores and the `PerUserInstallation` helper, used by Sheets and Slides). The main
library adds `ShellCommandUi` and `invokeWithToasts` (one policy for invoking commands from
controls: toasts for people, none for agents), `WonkyFindBar`, `showConflictReview` and
`applyCommentAnchorChanges`.

**What the script checks** (only `dependencies:`, not `dev_dependencies:`; imports in `lib/` and
`bin/`; `third_party/*` are external packages and are not checked):

- every dependency is in the package's list above, in the common utilities, or in the justified
  exceptions below;
- pure-Dart packages (`*_core`, `wonky_sheets_script`, `wonky_sync_models`, `wonky_mcp_stdio`,
  `wonky_server`, `wonky_client`, and (v2) `wonky_charts`, `wonky_code`, `wonky_numfmt`,
  `wonky_rich_text`, `wonky_fonts`, `wonky_spellcheck`, `wonky_revlog`) neither
  depend on nor import Flutter or any package that (transitively) depends on it (read from
  `.dart_tool/package_graph.json`);
- `wonky_ui` imports none of `wonky_client`, `wonky_server`, `wonky_app`, `serverpod*`;
- (v2) the app families (Drive, Write, Sheets, Slides — see *Forbidden*) import no package of
  another family (this generalizes the former Write ⟷ Sheets rule);
- (v2) the shared leaf packages `wonky_code`, `wonky_code_flutter`, `wonky_charts`,
  `wonky_charts_flutter`, `wonky_numfmt`, `wonky_rich_text`, `wonky_rich_editor`, `wonky_fonts`,
  `wonky_spellcheck` import no app-family package and none of `wonky_app`, `wonky_client`,
  `wonky_server`, `wonky_sync_models`, `serverpod*` (they are presentation/engine leaves: data
  comes in through their own types);
- (v2) the Flutter halves depend on their pure halves, never the other way round
  (`wonky_code` must not import `wonky_code_flutter`, `wonky_charts` not `wonky_charts_flutter`,
  `wonky_revlog` not `wonky_revlog_flutter`);
- nothing outside `wonky_server` imports `package:wonky_server/`, and no relative import leaves
  its package (e.g. into `wonky_server/lib/src/generated`);
- every imported package is declared under `dependencies:` of the importing package. Two
  exceptions: `lib/driver.dart` (the development entry point, `target:` under
  `serverpod: flutter_apps:`) may import `dev_dependencies` (`flutter_driver`), and files
  written by `serverpod generate` are skipped for this one rule (they import packages provided
  transitively by the Serverpod runtime packages, e.g. `serverpod_auth_core_*`, `http`).

**Common utilities** (any package): `collection`, `meta`, `clock`, `characters`, `path`, `uuid`,
`intl`. Flutter packages also: `flutter`, `flutter_localizations`, `flutter_web_plugins`, `web`
(browser APIs behind conditional imports), `cupertino_icons`.

**Justified exceptions** (beyond the lists above):

| Package | Dependency | Why |
|---------|------------|-----|
| `wonky_write_core` | `diff_match_patch` | Minimal text diffs for overlay-preserving Delta diffs (`DeltaDiff`) |
| `wonky_sheets_script` | `wonky_sync_models` | Id generators of the script tables |
| `wonky_sheets_script` | `crypto` | Build source hashes; `Utilities.computeDigest`/`computeHmac` |
| `wonky_sheets_script` | `analyzer` | Subset lint and exports of the server-only `compiler.dart` (the app must not import it; enforced) |
| `wonky_sheets_core` | `vector_math` | `Matrix4` for `PdfGraphics.setTransform` in the print PDF renderer (already a dependency of `pdf`); stays with the print renderer after the chart extraction (the chart renderers don't need it) |
| `wonky_server` | `crypto` | Token and content hashes |
| `wonky_server` | `dart_quill_delta` | Server-authoritative OT over Deltas (A4) |
| `wonky_server` | `yaml` | Reads the `wonky`/`mcp`/`ai` sections of the config files |
| `wonky_server` | `image` | Drive upload previews and thumbnails (Drive 02 §6) |
| `wonky_server` | `mime` | MIME sniffing of uploaded files (Drive 02 §5, suite 13 §6) |
| `wonky_server` | `dart_jsonwebtoken` | RS256 JWT of the Bugs & improvements GitHub App (specs/16 §13.3) |
| `wonky_ui` | `flutter_svg` | Empty-state illustrations (already a dependency of `shad`) |
| `wonky_ui` | `flutter_test` | `pumpWonky` in `lib/testing.dart` (15 §7) |
| `wonky_rich_editor` | `flutter_test` | `enterMarkdown` / `typeMarkdown` in `lib/testing.dart` (15 §7) |
| `wonky_app` | `shad` | The shell UI is built with shad (02) |
| `wonky_app` | `flutter_test` | `pumpShell` / `CommandTestHarness` in `lib/testing.dart` (15 §7) |
| `wonky_app` | `serverpod_auth_idp_client` | Auth types used by the auth controller |
| `wonky_app` | `desktop_drop` | Dropping files from the OS onto the drive on desktop (v2: deferred, A13 — kept so desktop compiles) |
| `wonky_app` | `url_launcher` | External links; opening the other app on desktop (deferred, A13) |
| `wonky_app` | `shared_preferences` | Per-device settings (`LocalStore`) |
| `wonky_app` | `sqlite_async`, `path_provider` | Offline cache and outbox (`LocalDatabase`, 12) and its file location on desktop |
| `wonky_app` | `crypto` | PKCE code challenge of Sign in with Google on web (04 §1.6) |
| `wonky_sheets` | `timezone` | IANA time zone list of the spreadsheet settings dialog (Sheets 06 §5.8) |
| `wonky_sheets` | `desktop_drop` | Dropping files onto the grid on desktop (Sheets 11 §2; deferred in v2, A13) |
| `wonky_sheets` | `http` | Fetching XLSX images and URL imports (Sheets 11 §2) |
| `wonky_sheets` | `pdf` | Client PDF export and print preview (Sheets 11 §7) |
| `wonky_sheets` | `archive` | gunzip of version snapshots (Sheets 10 §5.1.2) |
| `wonky_charts` | `archive` | (v2) gzip of large chart snapshot columns (`gz:`, Slides 08 §3.3, SL-27); already resolved through `image` |
| `wonky_slides_core` | `archive` | (v2) gzip NDJSON deck version snapshots, one codec for server and client (`SlidesSnapshotCodec`, Slides 09 §4.1, SL-39); already resolved through `image` |
| `wonky_charts_flutter` | `flutter_scene`, `vector_math` | (v2) GPU backend of 3D charts (Sheets 08 §23.7); moved out of `wonky_sheets` by the extraction (Drive 05 D-3) |
| `wonky_revlog_flutter` | `wonky_core` | Roles (pure Dart) |
| `wonky_sheets` | `flutter_svg` | Rasterizing SVG images on insert (Sheets 08 §10.1) |
| `wonky_write`, `wonky_sheets` (v2: and `wonky_drive`, `wonky_slides`) | `wonky_core`, `wonky_client`, `shad`, `go_router` | Ids/commands/undo, repositories calling endpoints (never widgets, 11 §6), shad UI (02), routes (A9) |
| `wonky_write` | `dart_quill_delta` | Client side of the Delta OT (A4) |
| `wonky_server` | `mime` | (v2) Magic-number sniffing of uploaded files (Drive 02 §5) |
| `wonky_slides` | `flutter_scene`, `vector_math` | (v2) 3D transitions and the chart camera (Slides 06, 08) |
| `wonky_slides` | `qr` | (v2) QR code of the presentation audience link (Slides 10 §5.2); pure Dart, already resolved through `pdf` |
| `wonky_slides` | `http`, `flutter_svg` | (v2) Downloading uploaded images from signed URLs; rasterizing SVG images on insert (Slides 03 §6.5, SL-15) |
| `wonky_write` | `http` | Fetches server-side exports |
| `wonky_write` | `sqlite_async` | Offline document cache (with `wonky_app`'s `LocalDatabase`) |

### 2.2 Third-party version policy
- `super_editor`: **vendored** in `third_party/super_editor`, based on 0.3.0-dev.52 (pre-1.0,
  frequent breaking changes; several gaps we fix in place — patches SE-1…SE-5 in
  [Write 04 §2.2](wonky_write/04-editor.md)). Use its built-in Markdown/Quill
  serialization only where noted (deprecated `super_editor_markdown`/`super_editor_quill`
  packages must not be added).
- `dart_quill_delta`: 9.x on client and server (super_editor's constraint). Because
  super_editor is vendored we may relax that constraint and move to 10.x if useful — decided in
  M0; vendor `dart_quill_delta` itself only if OT fixes are needed (e.g. embed handling in
  `transform`/`invert`, `compose` performance on large documents).
- `serverpod_offline_sync*`: no longer used. Sheets and Slides sync through RevLog
  ([17](17-revlog-sync.md)); the vendored copy, the module and its tables were removed in M13
  (RevLog R8, migration `20261018113026742-revlog-r8-remove-crdt`).
- `dart_eval`: vendored in `third_party/dart_eval` (patches DE-1…DE-3, Sheets 09).
- `syntax_highlight`: (v2, D-2 done) no longer a dependency. Its TextMate engine and the 15
  patched grammars (patches SH-1…SH-5) were **copied** into `packages/wonky_code` (pure Dart,
  grammars embedded as Dart strings; provenance and patch history in
  `packages/wonky_code/THIRD_PARTY.md`, Slides 07 §2.1, v2 review Q26); the vendored
  `third_party/syntax_highlight` and its `pubspec_overrides.yaml` entry are gone. `highlight`
  0.7.x (highlight.js port) is a dependency of `wonky_code` only (`HighlightJsTokenizer`).
- `sqlite3_web` pinned to a version compatible with `sqlite_async` (toptap pins 0.9.4).
- `shad` `^0.99.4`.

### 2.3 Vendored packages (local copies)

**Any third-party package may be copied into the repo and patched** when that is the cleanest
way to get a fix or a missing capability. Prefer fixing a library in place over building
fragile workarounds around it in app code; keep app-specific logic in our own packages.

Rules:
1. **Location & wiring**: `third_party/<package>/`, keeping the original package **name** (so
   transitive dependents resolve to it). Dependent packages keep a normal version constraint.
   How it is wired depends on whether the **server** uses it, because Serverpod Cloud builds the
   server from the root `pubspec.yaml` trimmed to the server's workspace packages, uploads only
   those, and pub resolves every root override even when nothing depends on it:
   - **Used by the server** (`dart_eval`): a **workspace member** (`resolution:
     workspace` in its pubspec, listed under `workspace:`), so the Cloud CLI uploads it. Its
     version must satisfy the hosted dependents' constraints.
   - **Flutter-only** (`super_editor`, `attributed_text`): a path override in the root
     **`pubspec_overrides.yaml`** (committed). Pub reads it locally; the Cloud CLI doesn't upload
     it. A path override in `pubspec.yaml` would break the cloud `pub get` (folder not uploaded),
     and a Flutter-only hosted override there would pull Flutter into it.
   `pubspec_overrides.yaml` replaces the overrides of `pubspec.yaml`, so it repeats the server's
   hosted pins (e.g. `sqlite3_web`). Check a change with `scloud deploy --wet-run --output
   deployment.zip`: unzip it and run `dart pub get --enforce-lockfile` in its server folder.
2. **Provenance**: copy from an exact released version or git commit; record it in
   `third_party/<package>/VENDORED.md` (source, version/commit, date, license). Keep the
   original `LICENSE`. Only permissive licenses (MIT, BSD, Apache-2.0); check before copying.
3. **Patch log**: every change is listed in `third_party/<package>/PATCHES.md` with an id
   (`SE-1`, `DE-2`, `OS-3`…), the reason, files touched, the spec that needs it, and upstream
   status (PR link / "not upstreamable"). Patches are small, focused and covered by tests;
   mark changed code with `// WONKY PATCH <id>` comments.
4. **Tests**: the package's own test suite plus tests for each patch run in CI.
5. **Upstream first**: open upstream PRs for general fixes; Serverpod-owned packages
   (e.g. `shad`) are fixed upstream directly when possible and vendored
   only to unblock. Remove the copy when upstream contains everything we need.
6. **Upgrades**: re-copy the new upstream version, re-apply the patch log, run tests — never
   edit the vendored copy without a `PATCHES.md` entry.
7. **Ownership**: each vendored package is owned by one workstream (see the app plans); the
   package-dependency CI check (§2.1) treats `third_party/*` as external packages.

Current and candidate vendored packages:

| Package | Status | Why |
|---------|--------|-----|
| `super_editor` | Vendored (M0) | Quill serializer gaps, incremental Delta apply, richer change events, editable table cells, fixes found by our tests (Write 04 §2.2) |
| `serverpod_offline_sync` (+ `_client`, `_server`) | Removed (M13, RevLog R8) | Was vendored in M0 for the CRDT sync of Sheets and Slides; replaced by RevLog ([17](17-revlog-sync.md)) |
| `dart_eval` | Vendored (0.8.5, workspace member; patches DE-0…DE-19) | Source positions, interrupt hook, conformance fixes (Sheets 09 §2). Pins the workspace to analyzer 8.x. |
| `dart_quill_delta` | Candidate | Only if OT edge cases or performance require it |
| `docx_creator` | Candidate | If the M5 spike adopts it but finds gaps (Write 07) |
| `re_editor` | Candidate | Fallback if unmaintained (Sheets 09) |
| `mcp_dart` | Candidate | If a Relic-native Streamable HTTP transport is better added in the library (suite 09 §1) |
| `super_clipboard` | Candidate | Platform fixes for rich clipboard on web/desktop |

### 2.4 Building and serving the web apps

All apps (v2: four) are served by **`wonky_server`'s web server** (Relic, port 8082 in
development) from one origin; there is no separate host app.

| Path | Served from | Notes |
|------|-------------|-------|
| `/drive/…` (v2) | `web/drive/` — `wonky_drive` built with `--base-href /drive/` | `FlutterRoute` (SPA fallback to `index.html`) |
| `/write/…` | `web/write/` — `wonky_write` built with `--base-href /write/` | `FlutterRoute` (SPA fallback to `index.html`) |
| `/sheets/…` | `web/sheets/` — `wonky_sheets` built with `--base-href /sheets/` | `FlutterRoute` |
| `/slides/…` (v2) | `web/slides/` — `wonky_slides` built with `--base-href /slides/` | `FlutterRoute` |
| `/<app>/**/sqlite3.wasm`, `/<app>/**/db_worker.js` (nested paths) | `sqliteAssetAlias` middleware | Serves the app's root copies: when `sqlite3_web` opens a database in the page (its worker failed) it resolves the relative default URIs of `sqlite_async` (set inside `serverpod_database`, not configurable) against the page URL, e.g. `/sheets/s/sqlite3.wasm`, which the SPA fallback answered with `index.html` and the local replica could not open |
| `/<app>/assets/assets/config.json` (each app) | `AppConfigRoute` | Replaces the bundled `assets/config.json` at runtime: `{apiUrl, webUrl, apps: {drive, write, sheets, slides}, cookieAuth, google?: {clientId, redirectUri}}` (the API URL — `wonky.publicApiUrl` / `WONKY_PUBLIC_API_URL`, default `https://api.wonky.work` in production (§2.5), else the API server's public host —, the public web origin for the legal pages, the base URL of each app for cross-app links, and Google sign-in, 04 §1.6). The public web origin is `wonky.publicWebUrl` / `WONKY_PUBLIC_WEB_URL`, default `https://wonky.work` in production (Serverpod Cloud generates the server config, so its own `*.serverpod.space` host is never used in links), else the web server's public host; e-mail and MCP links use it too |
| `/auth/callback` | `FlutterWebAuth2CallbackRoute` | OAuth popup callback for Sign in with Google (04 §1.6) |
| `/privacy`, `/terms` | `StaticRoute.file` | Privacy policy and terms of service (`web/pages/privacy.html`, `terms.html`; suite 13 §5) |
| `/` | redirect | (v2) Always to **`/drive/`** — Wonky Drive's home, the default landing app (v2 review B4; `RootRedirectRoute`, `rootRedirectTarget`). The `wonky_last_app` cookie is no longer read (the apps may stop setting it) |
| `/mcp`, `/files/…`, `/invite/:token` | server routes | See 09, 05, 06; (v2) `/files/d/:fileUuid/:name` downloads and `PUT /files/upload/:fileUuid` token uploads (MCP P0, chunked P1), Drive 02 §3.3, §4.3, §8 |
| anything else unbuilt | `web/pages/build_flutter_app.html` | Template fallback shown when an app's build folder is missing |

- **Build**: the `flutter_build` script in `wonky_server/pubspec.yaml` (`serverpod run
  flutter_build`, also run by the Serverpod Cloud pre-deploy hook) builds every app into
  `wonky_server/web/<app>` (`drive`, `write`, `sheets`, `slides`) through `tool/build_web.dart`
  on every platform (CQ-64h): `flutter build web --wasm --base-href /<app>/` in the app folder,
  then a copy of `build/web` (`--output` doesn't work on Windows). It builds the four apps one
  after another (four parallel `--wasm` builds swap on a 16 GB machine), exits non-zero if any
  build fails, never retries silently (`--clean-retry` opts into one `flutter clean` retry) and
  prints the bundle sizes; CI's `web` job runs it with `--budget tool/web_budgets.json`
  (§2, CI). Build folders are git-ignored. After each build, `tool/prune_web_fonts.dart` drops the font families the app
  never uses from `assets/FontManifest.json` (the engine downloads every listed font at
  start-up) and deletes their files: the Lucide stroke weights outside Slides (≈ 2.9 MB),
  shad's Inter in Drive and Write (only chart text uses it, ≈ 0.9 MB) and test fonts (CQ-45).
  The vendored super_editor keeps `golden_toolkit` (and its Roboto) in `dev_dependencies`. WASM and cross-origin-isolation headers: see
  [13 §3](13-security-and-operations.md).
- **Link previews**: each app's `web/index.html` carries a description and Open Graph / X card
  tags (`og:title` is the app — Drive, where `/` lands, says Wonky Work —, `og:site_name` Wonky Work, `twitter:card`
  `summary_large_image`). The SPA fallback serves that file for every URL of the app, shared
  documents and invites included, so the tags stay **generic: never an item's title, owner or
  content**, and there is no `og:url` (it would name another page as the canonical one). The
  image is `https://wonky.work/web/images/og-1.jpg` (1200×630 JPEG, under WhatsApp's 300 KB;
  source `icons/og.webp`): absolute, as crawlers need, and versioned in its name because
  `/web/` is served as immutable — a new image gets a new name. The legal pages carry the
  same tags with their own `og:url` and canonical link.
- **Development**: the apps are declared in `serverpod: flutter_apps:` in the server pubspec
  (aliases `drive`, `write`, `sheets`, `slides`; `path: ../wonky_<app>`,
  `target: lib/driver.dart`, fixed `web-port`s so the origins are stable for
  `allowedOrigins` and cookie auth). None is launched automatically (`auto_launch: false`): a
  debug web app costs a lot of memory, so `serverpod start` starts only the server and the app
  under test is started on demand (from the `serverpod start` UI or the `spawn_flutter_app` MCP
  tool):

  | Alias | Web port | `auto_launch` |
  |-------|----------|---------------|
  | `drive` (v2) | 8100 | false |
  | `write` | 8101 | false |
  | `sheets` | 8102 | false |
  | `slides` (v2) | 8104 | false |

  In development each app runs from `flutter run` on its own port at the root path; the bundled
  `assets/config.json` lists those dev URLs (all four), and `allowedOrigins` in
  `config/development.yaml` lists all four origins. Production builds always come from the
  server's `web/` folders.
- **Routing**: `go_router` paths are relative to the base href (`/d/:uuid` is
  `/write/d/:uuid` in production). Cross-app navigation (open a spreadsheet from Write, the
  left menu's app links, opening a document from Drive, etc.) is a same-tab full page load to
  `apps.<other>` + path from `config.json`. (v2) Item paths per kind: documents `/write/d/<uuid>`,
  spreadsheets `/sheets/s/<uuid>`, presentations `/slides/p/<uuid>` (+ `/present`, `/print`),
  files `/drive/file/<uuid>`, folders `/drive/f/<uuid>` (`<app>/f/<uuid>` in an app home). The
  shared helper `AppUrls.itemUrl(kind, uuid)` (`wonky_app`) and the server's
  `WonkyConfig.itemUrl` (notification e-mails, MCP results) build them.
- **Desktop** (deferred, A13): each app would be a separate desktop binary built from the same
  app ([03 §6](03-app-shell-and-navigation.md)). In v2 the desktop targets only have to compile.

**Decided (v2 review B4, replacing Q2):** `/` always redirects to **Wonky Drive's home**
(`/drive/`), not to the last used app: a predictable landing page with every file; the editors
are one click away in the left menu. (Q2 had chosen Wonky Write's home.)

### 2.5 One sign-in across all apps

A user signs in once and stays signed in when switching between the apps (v2: Drive, Write,
Sheets, Slides — all on one origin, so everything below applies to the four of them).

- **Web**: both apps live on the same origin, so they share one session in either mode:
  - **Cookie auth** when the server is configured for it: `authCookie` (httpOnly, `path: /`,
    `secure` in staging/production) plus `allowedOrigins` (the web server origin; in development
    also both `flutter run` origins) in `config/*.yaml`. The server's `AppConfigRoute` then
    serves `cookieAuth: true` in `config.json` and the client sets `client.cookieAuth = true`.
    The session cookie is shared by `/write/` and `/sheets/` (and, in development, by both
    localhost ports — cookies are not port-isolated); tokens never sit in JavaScript-readable
    storage. The bundled development `config.json` sets `cookieAuth: true` to match
    `development.yaml`.
  - **Token auth** otherwise (`cookieAuth` false or missing), as in the Serverpod template app.
    This is the case on **Serverpod Cloud**: it generates the server config (`.scloudignore`
    excludes `config/production.yaml`), so there is no `authCookie`, the API answers CORS with
    `Access-Control-Allow-Origin: *`, and browsers reject every credentialed request. The API
    also runs on its own host (`<project>.api.serverpod.space`, the app on
    `<project>.serverpod.space`). The session is then kept in the origin's storage, which
    `/write/` and `/sheets/` share.
  Cookie auth must never be switched on by the client alone: with a `*` CORS answer the app
  cannot reach the server at all.
  - **Production domains:** the apps are served on `https://wonky.work` and call the API on the
    custom domain `https://api.wonky.work` (`wonky.publicApiUrl` / `WONKY_PUBLIC_API_URL`,
    default `WonkyConfig.productionApiUrl` in production; `AppConfigRoute` serves it as
    `apiUrl`). Both are on the same *site*, so a `SameSite=Lax` refresh cookie set by the API
    is sent with the apps' requests; the generated `*.api.serverpod.space` host is a different
    site, where cookie auth cannot work. `/mcp` also answers on both public hosts
    (`McpConfig.defaultAllowedHosts`).
  - **Multiple tabs:** refresh tokens rotate and a reused one revokes the session. Cookie mode
    serializes refreshes across the tabs of one origin (Web Locks); token mode does not, so
    several tabs refreshing at once (e.g. after the laptop wakes) can sign the user out. To use
    cookie auth on Serverpod Cloud, set the Serverpod variables (`SERVERPOD_ALLOWED_ORIGINS=
    https://wonky.work`, `SERVERPOD_AUTH_COOKIE_SECURE=true`, `SERVERPOD_AUTH_COOKIE_SAME_SITE=
    lax`, `SERVERPOD_AUTH_COOKIE_PATH=/`); `config.json` then serves `cookieAuth: true`. In
    development, debug apps on ports 8100–8104 and release builds on 8082 are different origins
    sharing one cookie, so they are not coordinated: don't keep both signed in at once.
- Signing out in either app revokes the session for both; the other app notices on its next
  request or auth-state check and shows the sign-in screen (03 §4 *Session expired* flow).
- **Desktop** (deferred in v2, A13): each binary keeps its tokens in secure storage. On macOS
  the apps share a keychain access group so one sign-in covers all of them (P1); elsewhere each
  desktop app signs in separately (P2: shared credential store).
- `wonky_app` owns the client bootstrap (`WonkyClient.initialize()`: server URL from
  `config.json`, `FlutterConnectivityMonitor`, `FlutterAuthSessionManager`, cookie auth on web),
  so both apps behave identically.

## 3. Server structure (`wonky_server/lib/`)

```
server.dart                    # Serverpod bootstrap, auth, web routes (both apps), MCP route, cloud storage, future calls
src/
  platform/
    users/                     # UserProfile, UserPreferences, UserEndpoint, AccessTokenEndpoint
    drive/                     # DriveItem, DriveItemUserState, DriveEndpoint, search, templates, trash purge,
                               #   (v2) file uploads, conversions, kind masks (Drive 02);
                               #   DriveService (read, create, move), DriveCopies, DriveTrash, DriveUserStates, DriveTemplates
    storage/                   # (v2) UserStorage, StorageReservation, StorageService, reconcile + backfill (Drive 03)
    revlog/                    # RevLog (17): RevLogService (sequencer), RevLogConnection (per-file stream), pages,
                               #   bus, hooks and jobs, HeadlessFileCache; RevFile/RevOp models; RevBinding per app
    sharing/                   # DriveItemPermission, ShareLink, SharingEndpoint, AccessService (role resolution)
    comments/                  # CommentThread, Comment, CommentEndpoint
    notifications/             # Notification, NotificationEndpoint, email digests
    presence/                  # PresenceEndpoint (ephemeral)
    versions/                  # ItemVersion, VersionEndpoint, VersionProvider registry, thinning job
    activity/                  # ActivityEvent
    files/                     # StoredFile (uploads: images, avatars, imports, exports, drive files, previews), signed URLs,
                               #   (v2) FileTypeSniffer, download route, preview generation
    mcp/                       # transport, auth, ToolExecutor, McpErrors (tool ↔ endpoint ↔ protocol errors), UiBridgeHub, UiBridgeEndpoint
    ai/                        # AiModelClient (dartantic_ai), AiKeys, AiCall, AssistantService, AssistantEndpoint
    feedback/                  # FeedbackEndpoint
  write/
    models/                    # Document, DocumentOp, DocumentSnapshot, WriteTheme, …
    ot/                        # DocumentSessionManager (in-memory per-doc state), OtService
    endpoints/                 # DocumentEndpoint (stream), WriteThemeEndpoint, WriteExportEndpoint
    versions/                  # WriteVersionProvider
    mcp/                       # write.* tools
  sheets/
    revlog/                    # SheetsRevBinding (schema, validation, protection), hooks, server writes
    spaces/                    # spreadsheet factory, create defaults, copier (folder name kept; no sync spaces any more)
    endpoints/                 # SheetsEndpoint (online-only ops), SheetsDocEndpoint (the RevLog stream of a spreadsheet)
    scripts/                   # compile service, server runtime pool, triggers, scheduled jobs, quotas
    changelog/                 # ChangeLog processing (activity, triggers, cell history, pruning)
    versions/                  # SheetsVersionProvider (snapshots to cloud storage)
    imports/                   # xlsx/csv/ods import pipeline (server-side for large files)
    mcp/                       # sheets.* tools
  slides/                      # (v2) RevLog binding (revlog/), decks, versions, chart links, PDF
                               #   exports, templates, slides.* MCP tools, AI (Slides 01 §7)
```

Endpoints are thin; business logic lives in services (`*_service.dart`) that are unit-testable
with `serverpod_test`.

## 4. Client structure (each Flutter app)

```
lib/
  main.dart                    # WonkyShell(config: WriteAppConfig()) / SheetsAppConfig / DriveAppConfig / SlidesAppConfig
  driver.dart                  # flutter_driver entry for agents/E2E (ported from the template app in M0)
  config/                      # app config, routes, menus (MenuSpec), toolbar spec
  commands/                    # one file per command group; registered in commands.dart
  features/<feature>/          # ui/ (widgets), view_models/, data/ (repositories)
  mcp/                         # app-specific ui.* tools
  theme/                       # app-specific tokens (on top of wonky_ui)
```

Feature folders are the unit of parallel work: e.g. Write `features/editor`,
`features/theme_editor`, `features/export`, `features/outline`, `features/find_replace`,
`features/suggestions`, …; Sheets `features/grid`, `features/formula_bar`, `features/charts`,
`features/pivot`, `features/filters`, `features/scripts`, ….

## 5. Cross-cutting runtime flows

```
             ┌──────────── Flutter app (web/desktop) ─────────────┐
 User/MCP ──►│ Command ─► Controller ─► Repository ─┬─► Serverpod RPC/streams ─┐
             │    │                                  └─► Local store (SQLite)   │
             │    └─► UndoService                                               │
             └──────────────────────────────────────────────────────────────────┘
                                                                                ▼
             ┌──────────────────────── wonky_server ───────────────────────────┐
             │ Endpoints ─► Services ─► Postgres (platform + Write tables)       │
             │                       └► RevLog sequencer (Sheets/Slides files)   │
             │ MCP route ─► ToolExecutor ─► same Services  (+ UiBridgeHub ─► apps)│
             │ AssistantService ─► dartantic_ai (OpenAI/Anthropic/Gemini) ─► Tools│
             │ session.messages (Redis when multi-instance): presence, doc ops,  │
             │   drive changes, comments, UI bridge                              │
             └───────────────────────────────────────────────────────────────────┘
```

## 6. Configuration

`config/*.yaml` additions live in one `wonky:` section (Serverpod ignores unknown keys; read once
per file by `WonkyConfigFile` (`platform/config/wonky_config_file.dart`) for `WonkyConfig`,
`AiConfig`, `McpConfig` and `BoardConfig`; a run mode other than development, test, staging or
production fails at start instead of silently using the development settings; without a
server (unit tests, tools) the development file is read; env overrides `WONKY_<SECTION>_<KEY>`):
`features: {ai, scripting, mcpUiBridge, experimentalCharts}`, `ai: {enabled, dailyTokenBudgetPerUser}`, `mcp: {enabled, port?,
allowedHosts, allowedOrigins}`, `sheets: {maxCellsPerSpreadsheet, maxSheetsPerSpreadsheet,
scriptTimeoutMs, scriptDailyQuotaMs}`, `write: {snapshotEveryNOps, maxDocumentChars}`,
`cluster: {busFlushMs}` (13 §4, `WONKY_CLUSTER_BUS_FLUSH_MS`), `publicWebUrl`,
`webApps: {drive: {dir: web/drive, path: /drive/}, write: {dir: web/write, path: /write/},
sheets: {dir: web/sheets, path: /sheets/}, slides: {dir: web/slides, path: /slides/}}` (§2.4;
drive and slides v2); (v2) `drive: {quotaBytesPerUser, warnAtPercent, maxPendingUploadsPerUser}`,
`files: {maxFileUploadBytes, maxImageUploadBytes, maxImportUploadBytes, downloadBytesPerDay}` (Drive 03 §3),
`help: {bugReportUrl}` (default
`https://github.com/serverpod/wonky/issues`, the fallback of 03 §3.4), (M12) `board: {enabled, repository}` in `config.json` (16 §12); the template's commented-out
`authCookie` + `allowedOrigins` are enabled (§2.5).
RevLog limits (op size and change count, message size, ops in `RevInit`, page sizes, retention,
hook timing, headless cache budget, schema window) are listed as a `revlog:` section in
[17](17-revlog-sync.md) Part 1; as built they are constants of the RevLog services (e.g.
`RevLogConnection.opsInInit`), not yet read from the config. The sync-era keys
`sheets.maxActiveSpacesPerUser` and `slides.maxActiveSpacesPerUser` (and
`ServerLimits.maxActiveSpacesPerUser`) are gone: there are no sync spaces or active sets.
Secrets in `passwords.yaml`: `openaiApiKey` / `anthropicApiKey` / `geminiApiKey` (any or none,
10 §1), `jwt…` (existing), email provider credentials.

Redis is **required** as soon as more than one server instance runs (global
`session.messages` for presence, Write op fan-out, UI bridge and assistant relays, plus the
MCP session registry and rate counter); how every in-memory service behaves across instances
is in [13 §4](13-security-and-operations.md). The shipped staging/production configs run one
instance with Redis disabled; enabling it is a config/env change. Development and tests run
without Redis (local scope).

## 7. Protocol versioning

- `ProtocolInfo { serverVersion, minClientVersion, revSchemaHash, …, redisEnabled,
  redisConnected }` returned by `meta.getInfo()`; clients check on connect (see shell spec for
  UX). The Redis fields feed Settings › Developer (suite 04 §4). `revSchemaHash` is
  `sheets:<hash>,slides:<hash>`, the `RevSchema.hash` of each app ([17](17-revlog-sync.md)
  02 §4.3); Settings › About shows it shortened.
- (v2) New values of byName enums that clients deserialize (`DriveItemKind.presentation/file`,
  `DriveChangeKind.storageChanged`, `NotificationKind.storage`, `WonkyErrorCode.quotaExceeded`)
  make older clients throw; such releases bump `minClientVersion` so cached web apps reload.
  M8 set `minClientVersion` (and `serverVersion`) to 2.0.0. M13 (RevLog, [17](17-revlog-sync.md)
  RD-17) raises both to 3.0.0, since 2.x clients speak the removed CRDT sync protocol; the
  apps' `WONKY_VERSION` default is 3.0.0.
- Synced-schema changes are **no longer lock-step** (the CRDT engine's `syncTablesHash` and its
  schema releases are gone with M13). Every RevLog payload carries its app's schema hash; the
  server accepts the current hash and, for additive changes (a new nullable column or table),
  the previous hashes listed in `compatibleWith` for `schemaWindowDays`, and announces them in
  `RevInit.acceptedHashes`. Older clients keep working against an additively newer server (their
  decoders skip unknown tables and columns) and re-stamp their outbox after an update. Only a
  breaking change (rename, type change, removal) bumps `minClientVersion`; a client whose hash
  is not accepted stops sending and shows "Update required" without losing its outbox
  ([17](17-revlog-sync.md) 02 §4.3, 06 §2.4).
