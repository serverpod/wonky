# Wonky Work — Flutter & Serverpod project

**Wonky Work** is a collaborative office suite: **Wonky Write** (Markdown-first word processor, like Google Docs), **Wonky Sheets** (offline-first spreadsheet, like Google Sheets) and, in v2, **Wonky Drive** (every file in one place: uploads, previews, storage) and **Wonky Slides** (presentations). They are Flutter apps (v2 ships web only; desktop code must keep compiling) backed by one Serverpod server. Always build the backend with Serverpod. Build for multiple users and use Serverpod's built-in authentication, which is already set up in `wonky_server/lib/server.dart` (email/password, JWT). One sign-in covers all apps.

## Specs

The specs in `specs/` are the source of truth. Start with `specs/README.md` (reading order, conventions), then `specs/01-architecture.md` (layout, package rules, how the apps are served). App specs: `specs/wonky_write/`, `specs/wonky_sheets/`, `specs/wonky_drive/` and `specs/wonky_slides/` (v2 decisions: `specs/v2-review.md`). Cross-app features: `specs/16-bugs-and-improvements.md` (Bugs & improvements board, M12); the RevLog sync of Sheets and Slides: `specs/17-revlog-sync.md`. Blog submissions from Wonky Write (M14, built): `specs/18-publications-and-submissions.md`; the guide for blog owners is `docs/blog-integration.md`. Wonky Markdown, Write's second Markdown flavor (the blog's directives: callouts, details, cards, grids, buttons, chips, numbered headings; set per document, publications choose theirs): `specs/wonky_write/11-wonky-markdown.md`. Tables and grids in Write are native document lines (`cell`/`grid` line attributes, the 2D cell layout of super_editor SE-15, the server's upgrade of legacy embeds): `specs/wonky_write/12-native-cells.md`. First-party usage analytics for admins in Wonky Drive (`/drive/analytics`, built): `specs/19-usage-analytics.md`. When implementation reveals a better approach, update the spec in the same change.

Key rules from the specs: every user-visible action is a command and every state change is undoable (`specs/08-commands-and-undo.md`); single window, never open new tabs or windows (`specs/03-app-shell-and-navigation.md`); UI is built with `shad` and custom widgets in `wonky_ui` (`specs/02-design-system.md`); everything works in light and dark; a dialog never shows an X in its top-right corner when it has another way out (Cancel, Close, Done, Got it…): every `ShadDialog` passes `closeIcon: const WonkyDialogCloseButton()` (or `SizedBox.shrink()`), never shad's default X, and its dismiss buttons go in `actions`, where the close button sees them and hides itself (`specs/02-design-system.md` §4.20; `dart run tool/check_dialogs.dart` checks it).

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

Current state: the M0 restructure is done. **Wonky Write is complete for its first iteration** (sign-in, drive, sharing, real-time editor, comments, suggestions, history, themes and theme editor, import/export, offline cache, spellcheck, MCP, AI assistant). **Wonky Sheets is complete for its first iteration** (offline-first sync over RevLog, grid and editing, formulas, formatting and conditional formatting, data tools, validation and protection, pivots, charts, import/export/print, collaboration and history, MCP, AI assistant, scripting with its editor, macros and triggers). Deferred work is in `TODO.md`; the Sheets status per area is in `specs/wonky_sheets/STATUS.md`. **v2 (Drive, Slides, suite changes) is built**: the plans are `specs/wonky_drive/05-implementation-plan.md` and `specs/wonky_slides/12-implementation-plan.md`, the status `specs/wonky_drive/STATUS.md` and `specs/wonky_slides/STATUS.md` (M8 — Drive and the suite changes — is integrated and checked, D-18; the M8–M11 exit checklists are in `specs/14-roadmap.md` §2.1). **Wonky Slides is complete for its first iteration** (M9 SL-23, M10 SL-36, M11 SL-45): home and 10 templates, offline-first decks (RevLog sync), canvas with text, shapes, lines/connectors with route handles, icons, images with live adjustments, tables, element and slide groups, grid and outline views, speaker notes, themes, layouts, masters and the theme editor, clipboard within/across decks and apps, find & replace, builds and transitions incl. 3D and Magic Move, code blocks with highlight steps and type-in, linked Sheets charts incl. 3D, presenting with presenter view and audience/follower on another device, PDF (builds as pages) and PNG export, Layers, accessibility checker, presence, soft locks, live pointers and follow, comments on slides and elements, version history with diffs and restore, overwritten-text review, MCP `slides.*` and `ui.slides.*`, the assistant and AI commands, spelling, special characters and emoji. On hold (user decision): the phone remote, rehearse timings and the same-browser fast path (SL-41). Hidden by `SlidesFeatures` until built: native charts and *Import slides…* (P1), *Make a code walkthrough…*, editor preferences, notification settings, outline Markdown export and snap to grid (P2); the remaining work is in `TODO.md` ("Wonky Slides — later"). **Bugs & improvements (M12, `specs/16-bugs-and-improvements.md`) is built**: the public in-app board replacing *Report a bug* (report dialog with annotated screenshots, votes, Markdown comments, Jev/Gemini vetting on internal keys, admins by email domain, tasks with claims, the `board` MCP scope, `/improvements` routes), including the GitHub App integration (PR gate, AI review, merged/shipped lifecycle), which is enabled by config (`board.github.enabled`, default off); its open items are in spec 16 §17.

## Running locally

The default way to run and try the apps is the Serverpod runner plus debug apps started through the `serverpod` MCP: no release build, and edits hot reload.

1. **One-time setup.** Run `flutter pub get` in the repository root (one pub workspace for every package). In `wonky_server`, run `cp config/passwords.example.yaml config/passwords.yaml` (development defaults, git-ignored). You don't need Docker: `config/development.yaml` sets `database.dataPath`, so the runner starts an embedded PostgreSQL.
2. **Start the server** with `serverpod runner start` in `wonky_server` (see *Serverpod workflow*). When another Serverpod runner on the machine (another project) holds 8080–8082, this one binds ephemeral ports instead. That is fine: `serverpod runner status` prints the addresses.
3. **Start an app** with the MCP tool `spawn_flutter_app` and `appId` `drive`, `write`, `sheets` or `slides` (a user can start one from the `serverpod start` UI). `serverpod: flutter_apps:` declares all four with `auto_launch: false`, so the runner starts only the server. The app runs in debug mode from `lib/driver.dart` on the `web-server` device, at its fixed port and the root path: Drive http://localhost:8100/, Write http://localhost:8101/, Sheets http://localhost:8102/, Slides http://localhost:8104/. The runner passes `--dart-define=SERVER_URL=<the API address it bound>`, which overrides `apiUrl` in the app's `assets/config.json` (`AppUrls.load`), so the app reaches the server whatever port it got. Follow the compile with `tail_flutter_logs` until it prints `lib/driver.dart is being served at`.
4. **Open the app's URL** in a browser (the Browser pane or the user's). The debug app finishes starting only once a page connects: until then `get_flutter_app_dtd` maps it to `null`. The first load is slow (thousands of DDC modules). Edits hot reload automatically; call `hot_restart` for changes that hot reload can't apply.
5. **Sign up** with any email. The verification code is in the server log (`tail_server_logs`: `Registration code for <email>: <code>`).

**Links between apps are expected to break when running locally; this is not a bug to fix.** Each debug app runs on its own origin, so:
- A link into another app (for example, opening a spreadsheet from Drive) goes to that app's dev port. That port only answers if that app has also been started with `spawn_flutter_app`.
- The session is stored per origin, so each app needs its own sign-in.
- Links to pages on the web server (`webUrl` in `config.json`, such as the legal pages) point at port 8082. When the runner bound ephemeral ports, that port belongs to another project's server or nothing at all. Only the API address follows the runner.

Check a feature inside one app. When a check really crosses apps, start the other app too and sign in there, or use the release builds below. Don't change `config.json`, `AppUrls` or the link code to make local cross-app links work.

Release builds are only for checking the production bundle (bundle sizes, Wasm-only behaviour, performance measurements). `serverpod run flutter_build` (in `wonky_server`) builds every app with `tool/build_web.dart`: it fails when any build fails and prints the bundle sizes; `dart run tool/build_web.dart write` builds one app. The server's web server then serves them at `/drive/`, `/write/`, `/sheets/` and `/slides/` (`/` redirects to `/drive/`). In development it injects a live-reload script into those pages, which reloads them whenever `/__dev/version` changes (every server reload, also from other agents' edits). For a long walkthrough, make `fetch('/__dev/version')` reject in the page's console after each load.

Browser checks: the agent's Browser pane only paints while it is displayed (when hidden, frames lag and animations can't be judged). It has no PDF viewer and can't emulate `prefers-reduced-motion`. Enabling Flutter semantics (click `flt-semantics-placeholder`) makes `find`/`read_page` usable.

## Serverpod workflow

The server and the Flutter apps run under the Serverpod runner, a background process for `wonky_server`. The user attaches to it with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then call `tail_runner_logs` to learn whether it is still starting or why it stopped. If nothing is running, start it with `serverpod runner start` in `wonky_server` (or `serverpod runner start -d wonky_server`), which returns once the server is up and leaves it running for the user to attach to; a cold start compiles the whole project and can take minutes, so run it in the background. If it fails, fix the cause it reports (a build error, a port held by another process, Docker) instead of retrying; only a `serverpod runner start` your shell killed on a timeout is run again, since the runner keeps starting. Leave the runner running, and run `serverpod runner stop` only when asked. The Flutter apps are not launched automatically (`auto_launch: false`): start the one you need with the MCP tool `spawn_flutter_app` (check first with `get_flutter_app_dtd` whether it is already running).

While running, the runner watches for file changes to run incremental code generation and hot reload both the server and the Flutter apps. `serverpod runner status` prints its state and the server addresses, which are not always the configured ports when another Serverpod runner on the machine holds them.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line for the tasks below. The `serverpod runner` commands are the exception: they manage the stack itself. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_runner_logs` to read the output of the runner itself (code generation, compilation, Docker, raw server output). The only tool that also works while the server is starting or after it stopped.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `wonky_server/lib/src/generated/` directory and the whole `wonky_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `wonky_server/lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the MCP is not available or `serverpod runner start` cannot bring the server up, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; the runner applies pending migrations when it boots the server.

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
