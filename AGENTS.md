# Wonky Work — Flutter & Serverpod project

**Wonky Work** is a collaborative office suite: **Wonky Write** (Markdown-first word processor, like Google Docs), **Wonky Sheets** (offline-first spreadsheet, like Google Sheets) and, in v2, **Wonky Drive** (every file in one place: uploads, previews, storage) and **Wonky Slides** (presentations). They are Flutter apps (v2 ships web only; desktop code must keep compiling) backed by one Serverpod server. Always build the backend with Serverpod. Build for multiple users and use Serverpod's built-in authentication, which is already set up in `wonky_server/lib/server.dart` (email/password, JWT). One sign-in covers all apps.

## Specs

The specs in `specs/` are the source of truth. Start with `specs/README.md` (reading order, conventions), then `specs/01-architecture.md` (layout, package rules, how the apps are served). App specs: `specs/wonky_write/`, `specs/wonky_sheets/`, `specs/wonky_drive/` and `specs/wonky_slides/` (v2 decisions: `specs/v2-review.md`). Cross-app features: `specs/16-bugs-and-improvements.md` (Bugs & improvements board, M12); the RevLog sync of Sheets and Slides: `specs/17-revlog-sync.md`. When implementation reveals a better approach, update the spec in the same change.

Key rules from the specs: every user-visible action is a command and every state change is undoable (`specs/08-commands-and-undo.md`); single window, never open new tabs or windows (`specs/03-app-shell-and-navigation.md`); UI is built with `shad` and custom widgets in `wonky_ui` (`specs/02-design-system.md`); everything works in light and dark.

## Repository layout

| Path | What |
|------|------|
| `wonky_server/` | The Serverpod server. Its web server also serves the Flutter web builds: `/drive/`, `/write/`, `/sheets/` and `/slides/`; `/` redirects to `/drive/` (`specs/01-architecture.md` §2.4) |
| `wonky_client/` | Generated client (never edit) |
| `wonky_write/` | Flutter app: Wonky Write |
| `wonky_sheets/` | Flutter app: Wonky Sheets |
| `wonky_drive/` | Flutter app: Wonky Drive (v2, web only) |
| `wonky_slides/` | Flutter app: Wonky Slides (v2, web only; M9 MVP and M10 motion & content complete — unbuilt M11 features are hidden behind `lib/config/slides_features.dart`) |
| `packages/` | Shared packages: `wonky_core`, `wonky_ui`, `wonky_app` (shell), `wonky_sync_models` (pure-Dart id helpers of Sheets and Slides: UUIDv5 ids, id generators, fractional indexes), `wonky_write_core`, `wonky_sheets_core`, `wonky_sheets_script`, `wonky_mcp_stdio`, `wonky_code` + `wonky_code_flutter` (shared code highlighting, `CodeView`), `wonky_numfmt` (number formats), `wonky_charts` + `wonky_charts_flutter` (chart engine and painter, 3D GPU backend), `wonky_rich_text` (Delta inline schema, inline Markdown codec), `wonky_rich_editor` (lightweight WYSIWYG Markdown field on super_editor: the board's `MarkdownComposer`), `wonky_fonts` (font registry + bundled TTFs; Flutter loader in `wonky_app/fonts.dart`), `wonky_spellcheck` (Hunspell engine + dictionaries; glue in `wonky_app/spellcheck.dart`, emoji picker in `wonky_app/emoji.dart`), `wonky_revlog` + `wonky_revlog_flutter` (RevLog, the server-sequenced sync of Sheets and Slides: core and Flutter client, `specs/17-revlog-sync.md`), `wonky_slides_core` (Slides core: themes, layouts; more per the Slides plan), `wonky_lints` (the shared analysis options every package includes, specs/11 §6) |
| `third_party/` | Vendored, locally patched third-party packages (`specs/01-architecture.md` §2.3) |
| `tool/` | Repository scripts (dependency-rule check, web build + bundle sizes, generated-code check, goldens, pseudo-locale) |

Current state: the M0 restructure is done. **Wonky Write is complete for its first iteration** (sign-in, drive, sharing, real-time editor, comments, suggestions, history, themes and theme editor, import/export, offline cache, spellcheck, MCP, AI assistant). **Wonky Sheets is complete for its first iteration** (offline-first sync over RevLog, grid and editing, formulas, formatting and conditional formatting, data tools, validation and protection, pivots, charts, import/export/print, collaboration and history, MCP, AI assistant, scripting with its editor, macros and triggers). Deferred work is in `TODO.md`; the Sheets status per area is in `specs/wonky_sheets/STATUS.md`. **v2 (Drive, Slides, suite changes) is built**: the plans are `specs/wonky_drive/05-implementation-plan.md` and `specs/wonky_slides/12-implementation-plan.md`, the status `specs/wonky_drive/STATUS.md` and `specs/wonky_slides/STATUS.md` (M8 — Drive and the suite changes — is integrated and checked, D-18; the M8–M11 exit checklists are in `specs/14-roadmap.md` §2.1). **Wonky Slides is complete for its first iteration** (M9 SL-23, M10 SL-36, M11 SL-45): home and 10 templates, offline-first decks (RevLog sync), canvas with text, shapes, lines/connectors with route handles, icons, images with live adjustments, tables, element and slide groups, grid and outline views, speaker notes, themes, layouts, masters and the theme editor, clipboard within/across decks and apps, find & replace, builds and transitions incl. 3D and Magic Move, code blocks with highlight steps and type-in, linked Sheets charts incl. 3D, presenting with presenter view and audience/follower on another device, PDF (builds as pages) and PNG export, Layers, accessibility checker, presence, soft locks, live pointers and follow, comments on slides and elements, version history with diffs and restore, overwritten-text review, MCP `slides.*` and `ui.slides.*`, the assistant and AI commands, spelling, special characters and emoji. On hold (user decision): the phone remote, rehearse timings and the same-browser fast path (SL-41). Hidden by `SlidesFeatures` until built: native charts and *Import slides…* (P1), *Make a code walkthrough…*, editor preferences, notification settings, outline Markdown export and snap to grid (P2); the remaining work is in `TODO.md` ("Wonky Slides — later"). **Bugs & improvements (M12, `specs/16-bugs-and-improvements.md`) is built**: the public in-app board replacing *Report a bug* (report dialog with annotated screenshots, votes, Markdown comments, Jev/Gemini vetting on internal keys, admins by email domain, tasks with claims, the `board` MCP scope, `/improvements` routes), including the GitHub App integration (PR gate, AI review, merged/shipped lifecycle), which is enabled by config (`board.github.enabled`, default off); its open items are in spec 16 §17. `serverpod: flutter_apps:` declares `drive` (web-port 8100), `write` (8101), `sheets` (8102) and `slides` (8104), all with `auto_launch: false`: `serverpod start` starts only the server, and an app is started on demand (the user from the `serverpod start` UI, agents with the `spawn_flutter_app` MCP tool). The debug web apps load slowly (thousands of DDC modules); for browser checks build a release with `flutter build web --wasm --base-href /write/ --output ../wonky_server/web/write` in `wonky_write` and open http://localhost:8082/write/ (Sheets: `--base-href /sheets/ --output ../wonky_server/web/sheets` in `wonky_sheets`, http://localhost:8082/sheets/; Drive: `--base-href /drive/ --output ../wonky_server/web/drive` in `wonky_drive`, http://localhost:8082/drive/; Slides: `--base-href /slides/ --output ../wonky_server/web/slides` in `wonky_slides`, http://localhost:8082/slides/). `serverpod run flutter_build` (in `wonky_server`) builds every existing app one after another with `tool/build_web.dart` (it fails when any build fails and prints the bundle sizes; `dart run tool/build_web.dart write` builds one app). Browser checks of the release builds: the dev server injects a live-reload script that reloads the page when `/__dev/version` changes (every server reload, also from other agents' edits — for a long walkthrough, make `fetch('/__dev/version')` reject in the page's console after each load); the agent's Browser pane only paints while it is displayed (hidden: frames lag and animations can't be judged), has no PDF viewer and can't emulate `prefers-reduced-motion`; enabling Flutter semantics (click `flt-semantics-placeholder`) makes `find`/`read_page` usable.

## Serverpod workflow

The user starts the server with `serverpod start` (the Flutter apps are not launched automatically). There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself. Start the Flutter app you need with the MCP tool `spawn_flutter_app` (check first with `get_flutter_app_dtd` whether it is already running).

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload both the server and the Flutter apps.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `wonky_server/lib/src/generated/` directory and the whole `wonky_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `wonky_server/lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

How to write tests (layout, naming, helpers, determinism, tags) is in `specs/15-writing-tests.md`; read it before writing tests. Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package. Pure-Dart packages run `dart test` and Flutter packages and apps run `flutter test` in their own folder.

## Checklist after changes

Do these in order:

- `dart analyze` (CLI)
- `dart format` (CLI)
- `create_migration` and `apply_migrations` (MCP - only if necessary)
- Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
- Run tests, if applicable (`dart test` in the server package, `dart test`/`flutter test` in changed packages and apps)
- Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

## Testing the apps

If the user asks you to test an app:

1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD (pick the app's `flutter_apps` alias); if the app isn't running, start it with `spawn_flutter_app` first
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

Each app is launched from its `lib/driver.dart` (`wonky_drive/lib/driver.dart`, `wonky_write/lib/driver.dart`, `wonky_sheets/lib/driver.dart`, `wonky_slides/lib/driver.dart`). It starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.
