# Drive 05 · Implementation Plan

This plan builds Wonky Drive and the suite changes that come with it in milestone **M8 · Drive
+ suite changes** (suite [14 §2.1](../14-roadmap.md)): the unified drive with app homes, file
uploads and previews, the 50 MB quota, the settings split, the *Report a bug* button, and the
**shared-package extractions** that Slides needs (code, charts, number formats, sync kit, rich
text, fonts, spellcheck, the OS-8 space filter). The work is cut into **work packages D-1…D-18**
(§4) that parallel coding agents execute in **waves** (§2): each package is a few hours of agent
work, owns its folders, names the contracts it provides and consumes, and ends with acceptance
tests. The decisions of the [v2 review](../v2-review.md) are binding; v2 is **web only** (suite
[01 A13](../01-architecture.md)).

> **History.** This plan is the record of M8. Its sync parts (D-4 space kinds and OS-8, D-6 the
> sync kit, the space and replica notes in D-1, D-9 and §3) were superseded by RevLog (M13,
> [14 §2.1b](../14-roadmap.md), [17](../17-revlog-sync.md)); they are kept as written.

## 1. How Drive is built

- **New Flutter app `wonky_drive/`**, a pub workspace member like the other apps:
  `lib/main.dart` (`WonkyShell(config: DriveAppConfig())`), `lib/driver.dart` (flutter_driver
  entry, text entry emulation off), `lib/config/drive_app_config.dart`,
  `lib/features/{uploads,preview,storage,settings}/`, `lib/commands/`, `lib/mcp/`, `lib/l10n/`.
  Served at `/drive/` (`--base-href /drive/`), dev alias `drive` on web-port **8100** under
  `serverpod: flutter_apps:` (suite 01 §2.4). **Web only**: the `flutter create` desktop folders
  may exist so the package compiles everywhere, but no desktop feature (URL scheme, `desktop_drop`,
  packaging) is built.
- The site root `/` redirects to **Wonky Write's home** (`/write/`, v2 review Q2); Drive is
  reached from the left menu of every home.
- **Most UI is the shell's drive**, which already exists in `packages/wonky_app/lib/src/drive/`
  (home screen, list/grid, sidebar, details panel, dialogs, template gallery, drive controller)
  and today is shown filtered per app. v2 makes the shell drive **scope-aware**:
  `WonkyAppConfig.homeScope` (`HomeScope.kind(DriveItemKind)` for Write/Sheets/Slides,
  `HomeScope.all` for Drive) decides the kinds listed, the New menu, the left-menu navigation,
  the folder rule (suite 05 §3.2) and which features are on (tree, drag moves, file uploads).
  Drive adds only what the other homes don't have: the upload queue and panel, previews, the
  Storage page and Drive settings.
- `DriveAppConfig`: `app = WonkyAppKind.drive`, `appName = 'Wonky Drive'`, `primaryKind = null`
  (no editor of its own), `itemPath(uuid) = '/file/$uuid'`, `buildEditor` → `FilePreviewScreen`,
  `routes` → `/storage`, `homeScope = HomeScope.all`, `appSettingsSections` → Drive settings,
  `importHandler` → `DriveUploadHandler` (uploads files instead of importing),
  `mcpUiTools` → `ui.drive.*`.
- Drive opens no sync session (no Sheets/Slides cache, no Write document cache): it only uses
  the shell's drive cache and the upload queue store (suite 12 §3).

## 2. How the agents work

These rules apply to M8 and to the Slides milestones (Slides 12 §2 repeats only the deltas).

- **Machine budget**: the developer laptop has 16 GB of RAM. At most **5 agents** run at once,
  and at most **2** of them run the server test suite at the same time (each `dart test` in
  `wonky_server` starts its own embedded PostgreSQL). **Only one agent holds the web-build
  token** at a time: it is the only one that runs `flutter build web` / opens the release build
  at `http://localhost:8082/<app>/` (AGENTS.md); every other agent verifies with
  `dart test` / `flutter test` (widget tests and goldens) and `dart analyze`. The token holder
  per wave is named in §4.
- **Waves**: a wave is a set of ≤ 5 work packages whose dependencies are merged. A package of
  the next wave may start as soon as its own dependencies are merged and an agent slot is free,
  so waves overlap; the wave number is the earliest start, not a barrier.
- **Isolation**: all packages share the one working tree that `serverpod start` watches (code
  generation and hot reload see every change); folder ownership keeps agents apart and the
  orchestrator commits when a package's acceptance tests pass. Contract packages land first.
- **Ownership**: a package edits only its **owned folders**. Shared registration files
  (`wonky_server/lib/server.dart`, `config/*.yaml`, command registration indexes, `MenuSpec`
  trees, route tables, `pubspec.yaml` dependency lists, `tool/check_dependencies.dart` rules)
  get small additive edits only; conflicts there are resolved by the later merger.
- **Migrations**: one open migration at a time. A package that changes `.spy.yaml` table models
  rebases on `main`, runs `create_migration` (serverpod MCP; or the CLI fallback of AGENTS.md
  when no server runs) and merges promptly. Model changes that are known up front are batched
  into the contract package D-1.
- **Server**: agents never start the server (AGENTS.md). Packages whose acceptance needs a
  running server end with a note to the user to start `serverpod start`; the web-build token
  holder then runs the browser checks.
- **Done** = the package's acceptance tests, the suite DoD (14 §1) and §7 below; the spec is
  updated in the same change when the implementation differs.

## 3. Existing code to reuse

| Need | Start from |
|------|------------|
| Drive UI, homes, dialogs | `packages/wonky_app/lib/src/drive/` (`home_screen.dart`, `item_list.dart`, `drive_sidebar.dart`, `drive_controller.dart`, `details_panel.dart`, `template_gallery.dart`, `top_bar.dart`, `dialogs/`) |
| App identity, config | `packages/wonky_app/lib/src/bootstrap/app_urls.dart` (`WonkyAppKind {write, sheets}` with `other` → four values), `packages/wonky_app/lib/src/config/wonky_app_config.dart` (`ImportHandler`) |
| Settings | `packages/wonky_app/lib/src/settings/` (`settings_screen.dart`, `sections/`) |
| Root redirect, config.json | `wonky_server/lib/src/web/routes/{root_redirect_route.dart, app_config_route.dart}` |
| Files, uploads | `wonky_server/lib/src/platform/files/` (`file_service.dart`, `file_endpoint.dart`, `StoredFile`), `platform/drive/` (`drive_service.dart`, `import_service.dart`, `storage_usage.spy.yaml`) |
| Feedback (kept registered) | `wonky_server/lib/src/platform/feedback/` |
| Code highlighting | `wonky_write/lib/features/editor/styles/code_highlighter.dart`, `…/editor/model/code_languages.dart`, `wonky_write_core/lib/src/highlight/`, `third_party/syntax_highlight` |
| Charts | `wonky_sheets_core/lib/src/charts/` (`spec`, `data`, `layout`, `render`, `scene`, `three_d`, …), `wonky_sheets/lib/features/{charts,charts3d}/`, number formats in `wonky_sheets_core/lib/src/format/` |
| Sync kit | `wonky_sheets_core/lib/src/mutations/row_change.dart` (`RowChange`, `UndoInverter`), `wonky_sheets/lib/features/sync/` (`sheets_replica.dart`, `sheets_sync_controller.dart`, `sheets_writer.dart`, `change_journal.dart`, `remote_patch.dart`, `replica_recovery*.dart`, `storage_mode*.dart`), the session pattern `wonky_sheets/lib/features/model/{workbook_session,memory_workbook_session}.dart` |
| Spaces, OS patches | `wonky_server/lib/src/sheets/{spaces,sync,changelog}/`, `wonky_server/lib/src/sheets/models/space_reservation.spy.yaml`, `third_party/serverpod_offline_sync` (`PATCHES.md`) |
| Rich text, fonts, spelling, emoji | `wonky_write_core/lib/src/{delta,fonts,spellcheck}/`, `wonky_write/lib/features/{spellcheck,emoji}/` |

## 4. Work packages

### 4.1 Overview

| WP | Title | Wave | Depends on | Web-build token |
|----|-------|------|-----------|-----------------|
| D-1 | M8 contracts (server models, endpoint stubs, shell interfaces) | 1 | — | |
| D-2 | Extract `wonky_code` + `wonky_code_flutter` | 1 | — | |
| D-3 | Extract `wonky_numfmt` + `wonky_charts` + `wonky_charts_flutter` | 1 | — | |
| D-4 | Space kinds + offline-sync patch OS-8 | 1 | D-1 | |
| D-5 | Drive app scaffold, serving, root redirect, CI | 1 | D-1 (shell enum) | ✓ |
| D-6 | Extract `wonky_sync_kit` + `wonky_sync_kit_flutter` | 2 | — (after D-3 merged, both touch Sheets) | |
| D-7 | Extract `wonky_rich_text`, `wonky_fonts`, `wonky_spellcheck`; emoji/spelling glue → `wonky_app` | 2 | — (after D-2 merged, both touch Write) | |
| D-8 | Server: files, uploads, downloads, sniffing, previews, `kindMask` | 2 | D-1 | |
| D-9 | Server: storage quota service and enforcement | 2 | D-1 | |
| D-10 | Shell v2: scope-aware homes, left menu, routes, *Report a bug* | 2 | D-1 | ✓ |
| D-11 | Shell storage UI (meter, banner, dialog, error presenter) | 3 | D-1, D-10 | |
| D-12 | Settings split | 3 | D-10 | |
| D-13 | Drive: upload queue, upload panel, drops, downloads, *Open with* | 3 | D-5, D-8, D-10 | ✓ |
| D-14 | Drive: file previews | 3 | D-2, D-5, D-8 | |
| D-15 | MCP & AI for Drive (server tools) | 3 | D-8, D-9 | |
| D-16 | Write & Sheets adaptations | 4 | D-10, D-11, D-12 | |
| D-17 | Drive: Storage page, Drive settings, commands and keymap | 4 | D-11, D-12, D-13 | |
| D-18 | M8 integration: backfill dry run, E2E journeys, docs | 4 | all | ✓ |

Slides 12's **SL-1** (Slides app skeleton) runs in wave 4 next to D-16…D-18 (it needs D-5 and
D-10). Critical path: D-1 → D-8/D-9 → D-13 → D-17 → D-18 (quota in the upload flow). The shell
refactor (D-10) touches the most shared files: it lands early behind a compatibility default
(`homeScope` keeps today's behavior until D-16 switches the Write/Sheets configs).

```
wave 1   D-1 contracts ─┬─ D-4 OS-8          D-2 code ─────┐      D-3 charts ──┐
                        └─ D-5 scaffold                     │                   │
wave 2   D-8 files ── D-9 quota ── D-10 shell homes   D-7 rich text/fonts/spell  D-6 sync kit
wave 3   D-11 storage UI · D-12 settings · D-13 uploads · D-14 previews · D-15 MCP
wave 4   D-16 Write/Sheets · D-17 Storage page · D-18 integration · (Slides SL-1)
```

### 4.2 Wave 1 — contracts, extractions, serving

**D-1 · M8 contracts**
- Scope: every model change of M8 in **one migration**: `DriveItemKind.presentation/file`,
  `StoredFileKind.driveFile/preview`, `FileCategory`, `FileUploadState`, the new `DriveItem`
  columns (Drive 02 §1.1, incl. `kindMask`, `attachmentBytes`), `UserStorage`,
  `StorageReservation`, extended `StorageUsage`, `FileUploadRequest`/`FileUploadStart`/
  `FileUploadProgress`, `WonkyErrorCode.quotaExceeded`, `DriveChangeKind.storageChanged`,
  `NotificationKind.storage`, `SpaceKind {spreadsheet, deck}` + `kind` on `SpaceReservation`/
  `SpaceSubscription`, `UserPreferences.driveDefaults`/`slidesDefaults`. Endpoint signatures with
  stub bodies (Drive 02 §3.3, `drive.checkRoom`, `drive.listByStorage`, `drive.storageUsage`,
  `drive.registerPresentation`). `StorageService` interface (Drive 03 §4.2) with a pass-through
  implementation. Bump `minClientVersion` (old web clients can't read the new enum values,
  suite 01 §7). `wonky_core/lib/files/file_types.dart` (categories, convertible types, text
  extensions, language mapping). Shell: `WonkyAppKind {drive, write, sheets, slides}` (drop
  `other`), `AppUrls.apps` with four entries, `HomeScope`, `HomeNavSpec`,
  `WonkyAppConfig.{homeScope, homeNav, appSettingsSections, newItemRoute, importRoute}` with
  defaults that keep today's behavior, `StorageController` (`ValueListenable<StorageUsage?>`)
  and `FakeStorage` in `package:wonky_app/testing.dart`.
- Owns: `wonky_server/lib/src/platform/{drive,files,users,notifications,common}/**/*.spy.yaml`,
  `wonky_server/lib/src/sheets/models/` (space kind), new `wonky_server/lib/src/platform/storage/`
  (models + interface only), endpoint stub methods, `wonky_server/migrations/`,
  `wonky_core/lib/files/`, `packages/wonky_app/lib/src/{bootstrap,config}/`,
  `packages/wonky_app/lib/testing.dart`.
- Provides: every M8 model and endpoint signature, `StorageService`, `HomeScope`,
  `WonkyAppKind`, `StorageController`/`FakeStorage`, `file_types.dart`.
- Acceptance: generation and `dart analyze` clean; the migration applies to a copy of the
  development database; server, Write and Sheets test suites green (no behavior change);
  `file_types_test.dart` covers every category and the extension → language table; a test
  deserializes every new enum value through the client.
- **As built (contracts for D-4, D-5, D-8–D-17 and Slides):**
  - *Migration* `20261014223419475-m8-drive-contracts` (additive only): `drive_item` +
    `attachmentBytes`, `kindMask` (bit `1 << DriveItemKind.index`), `mimeType`,
    `fileCategory`, `uploadState`, `fileMetaJson`, `previewFileId`, index
    `drive_item_upload_idx (uploadState, createdAt)` for `drive.expireUploads`; tables
    `user_storage` and `storage_reservation` (both `serverOnly`, Drive 03 §4.1; extra index
    `storage_reservation_expiry_idx`); `space_reservation.kind` / `space_subscription.kind`
    (`SpaceKind {spreadsheet, deck}`, default `spreadsheet`; the subscription's
    `spreadsheetItemId` column keeps its name and holds the deck item for `deck`);
    `user_preferences` + `slidesDefaults`, `slidesPresenter` (Slides 10 A-10-4; the last-used
    export options live under `slidesDefaults.exportOptions`), `driveDefaults` (all `'{}'`),
    merged key by key by `user.updatePreferences` (`UserPreferencesPatch` has the three keys).
  - *Protocol* (non-table): `FileUploadRequest` / `FileUploadStart` / `FileUploadProgress`,
    `UploadConflictMode {keepBoth, replace, fail}`, `FileCategory`, `FileUploadState`,
    `StorageListFilter {kinds, trashedOnly, minCountedBytes, notOpenedSince}`
    (`drive.listByStorage`), `QuotaExceededDetails {neededBytes, availableBytes, quotaBytes,
    chargedUserId, chargedUserName, isCaller, reason}` — the `detailsJson` of
    `WonkyErrorCode.quotaExceeded` (`reason` is a string because `import` is a reserved enum
    value; server constants `QuotaReason`; build errors with `Errors.quotaExceeded(details)`).
    `StorageUsage` gains every field of Drive 03 §3 with defaults (old payloads still parse).
    `DriveItemView` + `attachmentBytes`, `countedBytes`, the file fields. `DriveListFilter` +
    `fileCategories`, `foldersContaining`; `DriveSearchFilters` + `fileCategories`;
    `TemplateView.sizeBytes`; `ServerLimits.{maxFileUploadBytes, quotaBytesPerUser}`.
    `DriveChange.storage` carries the usage of a `storageChanged` event, whose `itemUuid` is the
    nil UUID. `ActivityType.uploaded` (Drive 02 §3.3) and `NotificationKind.storage` (payload
    `message` shown verbatim when present).
  - *Endpoints* (`DriveEndpoint`): `registerPresentation`, `createFileUpload`,
    `completeFileUpload`, `cancelFileUpload`, `fileUploadStatus`, `convertFile`,
    `fileContentUrl(itemUuid, {download})`, `updateFileMeta`, `listByStorage(filter, cursor,
    limit)` throw `unavailable` until D-8/D-9; `checkRoom(bytes, itemUuid?)` works (charges the
    item owner when `itemUuid` is given, Viewer+ required) and `storageUsage` runs through
    `StorageService.instance.usage`.
  - *Server storage* (`platform/storage/storage_service.dart`): `StorageService` (static
    `instance`) with `reserve`, `commitReservation`, `releaseReservation`, `checkRoom`,
    `setItemSize`, `addAttachment`, `onTrash`, `onRestore`, `onDelete`, `onOwnerChange`,
    `usage` — named arguments and an optional `Transaction`; `PassThroughStorageService` never
    refuses, keeps the v1 `bytesUsed` and fills the v2 breakdown from `drive_item`. Config
    (`WonkyConfig`): `files.maxFileUploadBytes`, `drive.{quotaBytesPerUser, warnAtPercent,
    maxPendingUploadsPerUser}`, `files.{uploadsPerHour, uploadBytesPerDay}`.
  - *Versions*: `minClientVersion` and `serverVersion` 2.0.0 (configs and defaults); the apps'
    `WONKY_VERSION` default is 2.0.0, so v1 web clients get the reload toast.
  - *`wonky_core/files.dart`*: `FileTypeCategory` (names = `FileCategory`), `ConvertTarget
    {write, sheets}`, `FileTypes` (`categoryOf(mime, fileName:)`, `extensionOf` incl.
    `spy.yaml`/`tar.gz`, `mimeTypesByExtension`, `textExtensions`, `languagesByExtension`,
    `languageOf`, `convertTargetOf`, `convertibleExtensions`, `isTextMimeType`,
    `isRenderableImage`, `isActive`) and `formatStorageBytes` ("12.4 MB", "820 KB").
  - *Shell*: `WonkyAppKind {drive, write, sheets, slides}` with `productName`, `editorKind`,
    `devOrigin` (8100/8101/8102/8104), `urlScheme`, `forItemKind(kind, current:)`,
    `itemPathFor(kind, uuid)` (`/d/`, `/s/`, `/p/`, `/file/`; folders `/drive/` until D-10's
    `/f/`), `ownerOfPath(path)`; `AppUrls.apps` always has four entries; `openItem`/`openPath`
    route every kind to its app. `WonkyAppConfig`: `primaryKind` is nullable (Drive),
    `appName` defaults to `app.productName`, `homeScope` (null = v1 home until D-16),
    `homeNav` (`HomeNavSpec.appHome` / `.drive`), `appSettingsSections` (empty until D-12),
    `newItemRoute` (`NewItemRouteHandler`, default `createItem`; null for Drive) and
    `importRoute` (`ImportRouteHandler`, null) with `NewItemRequest` / `ImportRouteRequest`
    query parsers (`config/home_scope.dart`). `HomeScope.all()` / `HomeScope.kind(k)` expose
    `listKinds`, `searchKinds`, `foldersContaining`, `newKinds`, `managesFolders`,
    `uploadsFiles`, `showsTypeFilter`, `showsTemplateStrip`, `lists(k)`. `StorageController`
    (`ValueListenable<StorageUsage?>`, `refresh`, `stale`; `StorageController.none()` is
    installed as `ShellServices.storage` until D-11) and `StorageUsageChecks`
    (`usedFraction`, `isWarning`, `fits`). `package:wonky_app/testing.dart`: `FakeStorage`
    (`used`, `usageOf`, `emit`), `CommandTestHarness(storage:)`, `TestAppConfig(app:,
    scope:)`. `shell.account.switchApp {app}` accepts the four apps (no argument: Write ⇄
    Sheets until D-10's *Open ▸*).

**D-2 · Extract `wonky_code` + `wonky_code_flutter`** (Slides 07 §2.1, Write 04 §15.5)
- Scope: `CodeLanguages`, `SyntaxToken`, `ScopeClassifier`, palettes (`SyntaxPalette`,
  `BuiltInPalettes`), `HighlightJsTokenizer`, the **copied TextMate engine** with embedded
  grammars (`TextMateTokenizer`, v2 review Q26), `DefaultCodeTokenizer` facade, `CodeView` and
  `CodeTextStyler` in `wonky_code_flutter`; `SequenceDiff` generalized in `wonky_core`; Write's
  editor switched to the shared tokenizer (same colors); Write's **exports keep highlight.js**
  until M10 (Q17/Q25); `third_party/syntax_highlight` and its `pubspec_overrides.yaml` entry
  deleted; dependency rows of suite 01 §2.1 in `tool/check_dependencies.dart`.
- Owns: `packages/wonky_code/`, `packages/wonky_code_flutter/`,
  `wonky_write/lib/features/editor/{styles/code_highlighter.dart,model/code_languages.dart}`,
  `wonky_write_core/lib/src/{highlight,theme/model/syntax_token.dart}` (re-exports),
  `wonky_core/lib/src/diff/`, `third_party/syntax_highlight/`.
- Provides: `CodeTokenizer`, `CodeLanguages`, `SyntaxPalette`, `CodeView` (for D-14 and Slides).
- Acceptance: Write 04 AC-15.1/15.2; Write editor and export goldens unchanged; the vendored
  patch tests run as `wonky_code/test/textmate/` (every grammar highlights its sample and every
  prefix); `dart run tool/check_dependencies.dart` passes.

**D-3 · Extract `wonky_numfmt` + `wonky_charts` + `wonky_charts_flutter`** (Slides 08 §2,
v2 review Q27)
- Scope: migration order of Slides 08 §2.9 steps 1–4 (number formats, engine, Flutter
  painter and 3D GPU backend, tests with their code); Sheets core re-exports what Sheets
  imports; `flutter_scene`/`vector_math` move out of `wonky_sheets`' direct dependencies. The
  new APIs of 08 §2.7 are **not** in scope (SL-27, M10).
- Owns: `packages/wonky_numfmt/`, `packages/wonky_charts/`, `packages/wonky_charts_flutter/`,
  `wonky_sheets_core/lib/src/{charts,format/number_format}/`,
  `wonky_sheets/lib/features/{charts/render,charts3d}/`.
- Provides: `ChartSpec`/`ChartData`/scene/renderers, `ChartPainter`, number-format engine.
- Acceptance: all Sheets core and app tests green; chart scene JSON goldens byte-identical;
  Sheets chart goldens (2D and 3D) unchanged; dependency check passes.

**D-4 · Space kinds + OS-8** (v2 review Q19; *superseded by RevLog, M13*)
- Scope: vendored patch **OS-8** — `offlineSync.sync(…, spaceFilter:)` — with tests and a
  `PATCHES.md` entry; Sheets' `spaces/` service generalized to `platform/spaces/`
  (`SpaceService` with `SpaceKind`, reservations and subscriptions per kind, active-set limits
  per kind); `sheetsSync` passes spreadsheet spaces + the personal space.
- Owns: `third_party/serverpod_offline_sync/`, `wonky_server/lib/src/sheets/spaces/` →
  `wonky_server/lib/src/platform/spaces/`, `wonky_server/lib/src/sheets/sync/` (filter call).
- Consumes: D-1 (`SpaceKind` columns). Provides: `SpaceService` for Slides (SL-5).
- Acceptance: vendored suite + patch tests green; a server test creates a `deck` space for a
  member and asserts the Sheets replica never receives its rows; Sheets sync harness and offline
  merge fuzzer green.
- **As built:** engine patch OS-8 (`spaceFilter`, a batch `OfflineSyncSpaceFilter`; personal space
  always kept; authoritative only) in `third_party/serverpod_offline_sync` (`PATCHES.md`).
  Server `platform/spaces/`: `SpaceService` (moved from `sheets/spaces/`, every method kind-aware:
  `reserveSpaces(kind:)`, `createSpace(kind:)`, `useReservation(kind:)` (throws on a reservation of
  another kind), `subscribe(kind:)` → `SpaceSubscribeGrant`, `unsubscribe(kind:)`,
  `ensureSubscribed(kind:)`, `touchSubscription`/`setPinned`/`mirrorMembership`/`ensureWriter`
  for spreadsheets and presentations, `evictInactive` per kind, `maxActiveSpaces(kind)`,
  `spaceOf(item, kind:)`), `SpaceKinds` (item kind ↔ space kind, `recorded`, `of`;
  unrecorded = spreadsheet), `SpaceKindFilter`, `SpaceSync.sync(kind:)`. Sheets:
  `sheets/spaces/sheets_spaces.dart` (`SheetsSpaces`: the `sheets.*` space endpoints with
  `SubscribeResult`/`SpaceStats`), `SheetsSyncService.sync` → `SpaceSync` with `spreadsheet`.
  Config `slides.maxActiveSpacesPerUser` (`WonkyConfig.maxActiveDecksPerUser`, 30). No client
  change (then suite 12 §2.6, removed with M13). For SL-5: `SlidesEndpoint` wraps `SpaceService` with
  `kind: deck` and `slidesSync` calls `SpaceSync.sync(kind: deck)`.

**D-5 · Drive app scaffold, serving, root redirect, CI** — web-build token
- Scope: `wonky_drive` package (§1; `DriveAppConfig` with an empty Storage route), workspace
  member, CI matrix rows; `flutter_build` builds every existing app folder in parallel
  (`drive`, `write`, `sheets`, later `slides`); `webApps` + `FlutterRoute` for `/drive/`;
  `AppConfigRoute` serves `apps: {drive, write, sheets, slides}`; **`RootRedirectRoute` always
  → `/write/`** (cookie ignored); `flutter_apps` alias `drive` (8100); `allowedOrigins` and the
  bundled dev `config.json` with all four origins; web icons and favicon; AGENTS.md (app list,
  `driver.dart`, alias, release build command for `/drive/`).
- Owns: `wonky_drive/` (scaffold: `pubspec.yaml`, `lib/{main,driver}.dart`, `lib/config/`,
  `web/`), `wonky_server/{pubspec.yaml,config/*.yaml}`, `wonky_server/lib/src/web/`,
  web-route registration in `wonky_server/lib/server.dart`, root `pubspec.yaml` (workspace),
  `.github/workflows/`, `AGENTS.md`.
- Consumes: D-1 (`WonkyAppKind.drive`; start with the server/CI part until it lands).
- Acceptance: server test — `GET /` answers `302 /write/` with and without a `wonky_last_app`
  cookie; `/drive/` serves the Drive build with the SPA fallback; `config.json` lists four apps;
  the release web build of Drive boots, shares the sign-in with `/write/` and shows the (still
  unscoped) home.
- **As built:** `wonky_server/lib/src/web/web_apps.dart` (`webApps = [drive, write, sheets,
  slides]`, `rootRedirectTarget`); `server.dart` registers `config.json`, `FlutterRoute` and
  `sqliteAssetAlias` per entry (an unbuilt app, e.g. Slides, gets the build-instructions page);
  `AppConfigWidget(apps: Map)`; `RootRedirectRoute` → `/write/` (cookie ignored; the shell may
  still set `wonky_last_app`). `flutter_build`: posix builds every `../wonky_<app>` that has a
  `pubspec.yaml` in parallel (logs per app, printed on failure, exit 1 if any fails); Windows
  builds them one after another with the same guard. `flutter_apps: drive` (8100); `slides`
  joins with SL-1. `allowedOrigins` (and `wonky.mcp.allowedOrigins`) list 8082 + the four dev
  ports; the bundled `assets/config.json` of Drive, Write and Sheets list all four apps.
  `wonky_drive`: `DriveAppConfig` (brand `#6a5cb3`, was `#0284c7` before the new icon; `WonkyProduct.drive` logo,
  `HomeScope.all()`, `/file/:uuid` → `FilePreviewScreen` placeholder, `/storage` →
  `StorageScreen` placeholder, both a `DrivePendingPage` with *Back to Drive* =
  `shell.nav.home`), ARB l10n (`DriveLocalizations`, `en` + generated `en_XA`), web folder with
  the Drive product icon (favicon, 192/512, manifest) and the sqlite files (for the upload queue
  store of D-13). No desktop folders (web only). CI needs no new rows: analyze, format and the
  test matrix iterate over the workspace members. `tool/check_dependencies.dart`: rule for
  `wonky_drive` (suite 01 §2.1) and the family rule generalized to Write/Sheets/Slides/Drive.

### 4.3 Wave 2 — services, shell, remaining extractions

**D-6 · Extract `wonky_sync_kit` + `wonky_sync_kit_flutter`** (Slides 12 §5.1–5.2; *superseded
by RevLog, M13: `wonky_revlog` + `wonky_revlog_flutter`*)
- Scope: pure `RowChange`, `RowOp`, `ChangeSummary`, `MutationPlan`, `CoupledColumns`,
  `UndoInverter`, `SyncTxAdapter` (Sheets' cell-specific undo rule becomes a table hook);
  Flutter `SyncReplica`, `AppSyncController`, `SyncWriter`, `ChangeJournal`, recovery export
  plumbing and storage-mode detection; Sheets switched to them (its `WorkbookSession` and
  `SyncedWorkbookSession` keep their API).
- Owns: `packages/wonky_sync_kit/`, `packages/wonky_sync_kit_flutter/`,
  `wonky_sheets_core/lib/src/mutations/row_change.dart`, `wonky_sheets/lib/features/sync/`,
  `wonky_sheets/lib/features/model/sheets_undo.dart`.
- Provides: the contracts of Slides 12 §5.1–5.2 under those names.
- Acceptance: Sheets core/app suites, the multi-client sync harness and the offline merge
  fuzzer green; dependency check (pure half Flutter-free) passes.
- As built: the contracts of Slides 12 §5.1–5.2 were updated to the implemented API
  (`SyncTxAdapter.apply` takes the `spaceId`; Sheets' cell rule is the `ColumnwiseInserts`
  hook; `SyncTableSet`, `RowPatch`, `RowsUndoEntry`/`RowsUndoHandler`; client session building
  blocks `SpaceWriteQueue`, `JournalIngestion`, `SpaceOpening`; per-user lifecycle
  `ReplicaInstallation` + `ReplicaOfflineProvider`). Sheets keeps its names as bindings
  (`SheetsReplica`, `SheetsWriter`, `SheetsSyncController`, `SheetsRemote`, `SheetsSessionHost`,
  `RemotePatch`, `SheetsRowsUndoEntry/Handler`; core: `ChangeSummary`, `MutationPlan` typedef,
  `SheetsUndo` replacing direct `UndoInverter` calls). Server writers unchanged (TODO.md).

**D-7 · Extract `wonky_rich_text`, `wonky_fonts`, `wonky_spellcheck`** (v2 review Q4, Q23)
- Scope: Delta inline schema/attribute keys, normalizer and the Markdown inline codec pieces
  Slides needs → `wonky_rich_text` (re-exported by `wonky_write_core`); the font registry and
  bundled TTFs → `wonky_fonts` (Slides 05 §3.1 manifest API; Slides display families are added
  by SL-6); the Hunspell engine → `wonky_spellcheck`; `SpellEngine`, dictionary loading,
  spelling dialogs and the emoji picker → `wonky_app` (`lib/src/{spellcheck,emoji}/`).
- Owns: `packages/{wonky_rich_text,wonky_fonts,wonky_spellcheck}/`,
  `wonky_write_core/lib/src/{delta,fonts,spellcheck}/` (moves + re-exports),
  `wonky_write/lib/features/{spellcheck,emoji}/`, `packages/wonky_app/lib/src/{spellcheck,emoji}/`.
- Acceptance: Write core/app suites and goldens green; Write spellcheck and emoji widget tests
  pass from their new homes; dependency check passes.

**D-8 · Server: files, uploads, downloads, sniffing, previews** (Drive 02)
- Scope: `createFileUpload`/`completeFileUpload`/`cancelFileUpload`/`fileUploadStatus`,
  `fileContentUrl`, `updateFileMeta`, `convertFile`; `FileTypeSniffer`; `GET /files/d/…`
  downloads and `PUT /files/upload/:fileUuid` token uploads (suite 13 §6 headers); preview and
  thumbnail FutureCall; `drive.expireUploads`; `kindMask` maintenance + nightly recompute +
  `filter.foldersContaining`; search filters by kinds/categories; `drive.registerPresentation`
  (idempotent, for Slides). Uploads call `StorageService.reserve/commit/release`.
- Owns: `wonky_server/lib/src/platform/{drive,files}/` (code), `test/fixtures/files/`.
- Acceptance: every endpoint of Drive 02 per role (`forEachRole`); ≥ 40 sniffer vectors incl.
  spoofed extensions and polyglots; download headers; `kindMask` property test (random
  create/move/trash/restore/delete sequences ≡ full recompute); upload expiry.
- **As built (contracts for D-9, D-13, D-14, D-15 and Slides):**
  - *Services*: `platform/drive/drive_file_service.dart` (`DriveFileService.createUpload`,
    `completeUpload`, `cancelUpload`, `status`, `contentUrl`, `updateMeta`, `convert`,
    `copyFile`, `expireUploads`, `uploadUrl(session, actor, itemUuid)` → `{url, expiresAt}` of
    the `PUT` route for MCP `drive.create_upload` (D-15), `downloadUrl`, `mergeServerMeta`);
    `drive_presentations.dart` (`DrivePresentations.register`, kind-aware
    `SpaceService.useReservation(kind: deck)` + `touchSubscription`); `kind_masks.dart`
    (`KindMasks.bit/has/refreshChain/refreshSubtree/computeAll/recomputeAll`);
    `drive_file_filters.dart` (upload visibility, `fileCategories`, `foldersContaining`).
    `DriveService.insertItem/parentFor/afterCreate` are the public wrappers other drive
    services use; `drive.get`, `list`, `search` and `watch` hide `uploading` items from
    everyone but the uploader (search never shows them).
  - *Quota calls*: `createFileUpload` → `StorageService.reserve(userId, fileUuid, itemId,
    bytes, reason: upload)` in the insert transaction; `completeFileUpload` →
    `commitReservation(fileUuid, actual)` **first**, then D-8 writes `sizeBytes = actual`
    itself (the pass-through commit is a no-op; D-9's commit may set the same value); cancel,
    failure and expiry → `releaseReservation(fileUuid)`; file copies → `checkRoom(reason:
    copy)` then `setItemSize(copy, n)` (the copy is inserted with size 0); `convertFile` →
    `checkRoom(reason: convert, bytes: file size)` before the import pipeline (the import's own
    size hook is D-9's). A refused commit (`quotaExceeded`) fails the upload (bytes deleted).
  - *Limits*: pending uploads (`maxPendingUploadsPerUser`, counted from `uploading` items),
    `uploadsPerHour` and `uploadBytesPerDay` counted from `driveFile` StoredFile rows of the
    last hour/day; cancelled and failed uploads keep their StoredFile row (detached, `failed`,
    `expiresAt` +1 day, removed by `files.cleanup`) so they still count.
  - *Sniffing*: `platform/files/file_type_sniffer.dart` (`FileTypeSniffer.sniff(bytes,
    fileName:, tail:)` → `SniffResult{mimeType, encoding}`); own signatures first (incl. OOXML by
    local + central-directory part names, ODF `mimetype`, EPUB, JAR, iWork, OLE2 family by
    extension), then the `mime` package; the text check also accepts **Latin-1** (no NUL, < 1 %
    control bytes; `encoding: latin1`), and active markup (HTML/SVG/XML) is detected from the
    content only. Completion records `fileMetaJson {encoding, lines}` for text.
  - *Names*: `FileNames.sanitize` (also strips U+200E/F, U+061C and BOM), `ascii`,
    `numbered` ("Keep both" → `name (1).ext`, case-insensitive against ready items),
    `contentDisposition`. `UploadConflictMode.replace` answers `unavailable` (P2);
    `chunked: true` is ignored (whole-file description, P1).
  - *URLs*: preview URLs are storage signed URLs served as `application/octet-stream`
    attachments; downloads are `GET /files/d/:fileUuid/:name?t=` (`FileRoutes`, registered in
    `server.dart`), which re-checks access and `nonEditorsCanExport` per request, answers
    `HEAD`, and adds `Referrer-Policy: no-referrer` to the suite 13 §6 headers.
    `PUT /files/upload/:fileUuid?t=` takes the whole body (413 beyond the declared size, 501 for
    `Content-Range`; token only — session auth comes with P1 chunks). Tokens
    (`FileUrlTokens`): HMAC-SHA256, key = password `fileUrlSecret`, else derived from
    `jwtHmacSha512PrivateKey`/`serviceSecret`.
  - *Previews*: `FilePreviewFutureCall.generate(itemId)` (scheduled through the replaceable
    `FilePreviewService.schedule`); `FilePreviews.render` in an isolate with a 10 s limit:
    ≤ 50 MP, EXIF orientation baked, EXIF/ICC/text stripped, preview ≤ 2048 px and a
    cover-cropped 400 × 300 thumbnail, PNG when the image has alpha else JPEG 85; also on
    copies; meta `{width, height}` even when the image is too large to decode.
  - *kindMask*: bit `1 << DriveItemKind.index`; a subfolder contributes its own mask plus the
    folder bit; files count only when `ready`. Maintained in the transaction of create
    (`_insertItem`), move (old and new chain), trash, restore (whole subtree), purge and upload
    completion; `drive.recomputeKindMasks` and `drive.expireUploads` run in the daily
    maintenance job.
  - *Copies*: `drive.copy` of a file copies the stored object server-side (Drive 02 §10).

**D-9 · Server: storage quota service and enforcement** (Drive 03) — starts with spike S-D3
- Scope: `StorageService` implementation, reservations, `quotaExceeded`; enforcement hooks in
  every path of Drive 03 §7.2 except the upload endpoints (D-8) — copies, transfers, imports,
  image uploads in Write/Sheets, version restore copies; size estimators (documents in the OT
  service, `SheetsSizeEstimator`, the Slides estimator interface); reconcile and backfill
  FutureCalls; `storageChanged` drive events; `NotificationKind.storage` notice; no grace period
  (Q15); restores from trash never blocked (Q16).
- Owns: `wonky_server/lib/src/platform/storage/`; one-line hooks in `write/ot`,
  `sheets/changelog`, `platform/{sharing,drive}`.
- Acceptance: Drive 03 §7.2 table row by row; parallel reservation race (`Future.wait`); AC-D3.2,
  D3.4–D3.7 server parts; reconcile property test; backfill idempotent and resumable.
- **As built:** see [Drive 03 §11](03-storage-quota.md#11-as-built-d-9) — `DbStorageService` is
  the installed service (structural callbacks recount owners after the change), estimators via
  `ContentSizes` (S-D3: index-driven via `crdt_data_rows`, 5-minute cadence confirmed), backfill
  at every start for users without a reconciled row, nightly `wonky.storageReconcile`,
  `drive.listByStorage`, `storageChanged` on `drive.watch`, MCP `quota_exceeded`.

**D-10 · Shell v2: homes, left menu, routes, *Report a bug*** — web-build token
- Scope: `HomeScope` in `DriveHomeScreen`/`DriveController` (kind filter, folder rule via
  `foldersContaining`, New menu, features per scope); `HomeSidebar` (apps section, `homeNav`,
  bottom section with a slot for the storage meter); routes `/f/:uuid` (+ redirect of
  `/drive/:uuid`), `/my-files`/`/my-drive`, the `/new` and `/import` route contracts; *Open in
  Wonky Drive*; account menu *Open ▸* four apps; editor title-row *Report a bug* button,
  `shell.help.reportBug` with the new-issue URL builder (no user content, Q8) and
  `.github/ISSUE_TEMPLATE/bug_report.yml`; Help menu: *Report a bug* replaces *Report a
  problem* (`shell.help.feedback` stays registered, Q6).
- Owns: `packages/wonky_app/lib/src/{drive,shell,routing,branding,menus}/`,
  `.github/ISSUE_TEMPLATE/`.
- Provides: scope-aware homes for D-13, D-16 and Slides SL-11.
- Acceptance: widget tests and light/dark goldens of `HomeSidebar` and a scoped home; the URL
  builder test (fields, 2,000-character fallback, no ids/emails); existing shell tests green
  with the compatibility default; in the release build, Write's home lists all kinds as before
  until D-16.
- **As built:** `DriveController`/`DriveHomeScreen` read `config.homeScope` (null = v1):
  app homes list `[kind, folder]` with `foldersContaining: kind` in folder views and `[kind]` in
  Recent/Offline/Trash, hide the type chip, item drags and the template-less Drive parts, title
  `/` *Recent*, show *Open in Wonky Drive* (`shell.nav.openInDrive {folderUuid?}`; without an
  argument the current folder or the matching Drive view) and search their kind with a "Search
  all of Wonky Drive" row; Drive (`HomeScope.all`) starts at *All types* with Presentations and
  *Files ▸* Images/PDFs/Text & code/Audio/Videos/Archives/Other (`fileCategories`), New menu
  folder / upload / document / spreadsheet / presentation / template. `HomeSidebar` (apps,
  *+ New*, `homeNav`, bottom section) replaces `DriveSidebar`; drawer below 768 px. Routes:
  `/f/:uuid` (`/drive/:uuid` redirects; `WonkyAppKind.itemPathFor(folder)` = `/f/`),
  `/my-files` ⇄ `/my-drive`, `/new` (`NewItemRoutePage`, replaces the route with the editor;
  absent when `newItemRoute` is null), `/import` (`ImportRoutePage`, when `importRoute` is set),
  `/settings/app[/:section]` (redirects to the v1 sections until D-12). Commands
  `shell.help.reportBug`, `shell.nav.openInDrive`, `shell.settings.openApp {section?}`,
  `shell.storage.open`; `shell.file.new {kind: presentation}`; cross-kind *New* goes through the
  target app's `/new`. Account menu: app settings, Wonky Work settings, *Open ▸* four apps.
  Editor title row bug button (≥ 640 px); Help menu *Report a bug* replaces *Report a problem*.
  Test helpers: `FakeCrossApp` (installed by `CommandTestHarness`, `h.crossApp`), the fake
  drive computes the `kindMask` rule and `fileCategories`. Not done here (TODO.md): server
  `help.bugReportUrl`, server folder links, Tools menu settings entries (D-12), Drive template
  kind tabs.

### 4.4 Wave 3 — user-facing features

**D-11 · Shell storage UI** (Drive 03 §6)
- Scope: `StorageController` implementation on `drive.storageUsage` + `storageChanged` events
  (offline: last cached value), `StorageMeter`, `StorageBanner` (≥ 90 %, over quota),
  `QuotaExceededDialog` variants (self / owner), `QuotaErrorPresenter` for `quotaExceeded` errors
  from any call; meter in the left menu slot.
- Owns: `packages/wonky_app/lib/src/storage/`.
- Acceptance: widget tests + light/dark goldens of meter, banner and every dialog variant;
  banner disappears live on a fake `storageChanged`.
- **As built:** see [Drive 03 §12](03-storage-quota.md#12-as-built-d-11). API for D-13, D-16,
  D-17 and Slides: `services.storageChecks.ensureRoom(bytes, reason: QuotaReasons.image, item:)`
  before image inserts / imports / copies, `services.storageChecks.fittingUploads(sizes)` before
  Drive uploads (indices that may start), `services.quotaErrors.present(error)` in `catch`
  blocks outside commands (true = handled, skip your own message), `services.storage.report(
  usage)` with the usage of byte-adding results, `StorageMeter(large: true)` for the Storage
  page and Settings, `StorageBanner(place: StorageBannerPlace.editor, item:)` in custom editor
  frames. `QuotaErrorPresenter` is attached to the dispatcher, so commands need nothing.

**D-12 · Settings split** (suite 04 §4)
- Scope: settings frame with the app group and the Wonky Work group; `/settings/:section` and
  `/settings/app[/:section]`; re-homed sections per suite 04 §4.1 (Keyboard shortcuts in Wonky
  Work settings with *Shared*/*<App>* groups, Q10); `appSettingsSections` hosting; redirects of
  old section ids; Settings › Wonky Work › Storage; moving Write's and Sheets' sections from the
  shell into their apps (`lib/features/settings/`); `UserPreferences` columns.
- Owns: `packages/wonky_app/lib/src/settings/`, `wonky_write/lib/features/settings/`,
  `wonky_sheets/lib/features/settings/`, `wonky_server/lib/src/platform/users/` (code).
- Acceptance: J-D6 as a widget test per app; old `/settings/write` redirects; every setting
  command still invocable via `ui.invoke_command`.
- **As built:** see [suite 04 §4.2 "As built (D-12)"](../04-auth-and-accounts.md#42-settings-screen).
  Shell: `SettingsScreen(area:)`, `settingsRoutes`, `SettingsHandoffPage`,
  `legacySettingsTarget`, `workSettingsSectionIds`, `settingsBackTarget` (exported from
  `wonky_app.dart`); new sections `SecuritySection`, `StorageSection` (D-11's `StorageMeter`);
  keyboard groups + scoped *Reset all*; Tools menu `tools.preferences` = app settings +
  `tools.workSettings`; `Mod+,` → `shell.settings.openApp`; `PreferencesController`
  `driveDefaults`/`slidesDefaults`/`slidesPresenter`; `WonkyAppConfig.settingsSections` and
  `sheetsSettings` removed. Apps: Write `features/settings/` (4 sections, `write.prefs.
  setDefaultLayout/setExportFormat/resetPageSetup/removeDictionaryWord`), Sheets
  `features/settings/` (`defaults`, `sheets.prefs.set`), Drive `features/settings/` (stub section
  `drive` for D-17). The server's `UserPreferences` columns and key-wise merge were already done
  by D-1 (no server change). For D-17: replace `DriveSettingsSection` and add `drive.prefs.set`
  on `PreferencesController.setDriveDefault`. For Slides: `appSettingsSections` +
  `setSlidesDefault`/`setSlidesPresenter`.

**D-13 · Drive: uploads, drops, downloads, *Open with*** — web-build token; starts with spike
S-D2
- Scope: upload queue (`LocalPendingUpload` v2 columns, OPFS/IndexedDB limits of Drive 02
  §4.1, offline queueing), upload panel, drop overlay (web drop events only), options dialog
  for name conflicts, client pre-check (`checkRoom`), whole-file retries (Q12; no chunking),
  downloads via hidden anchor, *Open with* → `/import?file=` of the target app.
- Owns: `wonky_drive/lib/features/uploads/`, `wonky_drive/lib/commands/upload_commands.dart`,
  upload store in `packages/wonky_app/lib/src/data/` (additive).
- Acceptance: J-D2 (upload parts), J-D3 (pre-check dialog, forced-upload refusal), J-D8 in the
  release build; `UploadPanel` state goldens; queue survives a reload (OPFS).
- **As built:** `wonky_drive/lib/features/uploads/`: `UploadQueue` (`ChangeNotifier`, 3 in
  parallel FIFO, states `queued/waitingForNetwork/starting/uploading/verifying/done/failed/
  cancelled`, failures `network/outOfStorage/tooLarge/folderGone/rateLimited/notSaved/other`;
  network failures retried 2 s → 10 min ±20 % up to 8 times, then "Failed — network error";
  an incomplete upload (`invalidArgument` at completion) or a refused failed item (`conflict`
  at creation) restarts once with **new item/file uuids**; manual *Retry* keeps the ids only
  after network/rate-limit failures; batch progress and time left after 2 s), `UploadStore`
  (`SqliteUploadStore` on `drive_<userUuid>.db` via `LocalDatabases.open`, table
  `local_pending_upload` with the 02 §4.1 columns + `batch_id`, `parent_name`, `volatile`,
  `error_kind`, `result_json`; `MemoryUploadStore` fallback/tests), `UploadApi` /
  `ServerUploadApi` (`drive.createFileUpload/completeFileUpload/cancelFileUpload`,
  `namesIn` for conflicts) and `ByteSender` (spike S-D2: the web `http` client — and so
  Serverpod's `FileUploader` — buffers the body and reports no upload progress, so the web
  sends the upload description itself with an `XMLHttpRequest` and `upload.onprogress`
  (binary and multipart descriptions); desktop counts the `FileUploader` stream),
  `UploadPlan` / `filesThatFit` (02 §3.2 pre-checks: size against
  `ServerLimits.maxFileUploadBytes`, quota against the cached `StorageUsage` minus queued
  bytes — fails open while unknown/calculating, names), dialogs (`WonkyDialogSpec`:
  *Not enough storage for all files* / *You're out of storage* with *Upload the files that
  fit* · *Manage storage* · *Cancel*; *Upload options* with *Keep both* · *Skip* · *Cancel* —
  *Replace* is P2; *Cancel N uploads?*), `UploadPanel` + `UploadPanelLayer` (mounted by
  `DriveAppConfig.wrap`; 360 px card bottom-right / full width minus 16 px below 768 px,
  pill when collapsed, live-region header, per-row actions and footer, arrow keys between
  rows), `UploadHost` (per-shell queue following `currentUser`, staged files, panel state,
  announcements, `beforeunload` guard), `DriveUploadHandler` (`ImportHandler`: `file_picker`
  for *File upload…*, drops → `drive.upload.files`). Commands (`lib/commands/
  upload_commands.dart`): `drive.upload.files {staged, parentUuid?}` (undoable batch on the
  shell stack, `UploadBatchUndoEntry`/`UploadUndoHandler`: undo cancels running uploads and
  trashes uploaded files and created folders, redo restores them and restarts the cancelled
  ones), `drive.upload.cancel/cancelAll/retry {uploadId, toMyDrive?}/retryAll/remove/
  clearFinished/togglePanel`. Folder drops are in M8: dropped directories (web
  `webkitGetAsEntry` through `desktop_drop`) are recreated with `drive.createFolder` before
  their files are queued (online only); the folder *picker* (`drive.upload.folder`) stays P1.
  Shell (additive): `ImportFile.{lastModified, folderPath}`; the drive home's drop handler
  uploads every file type in `HomeScope.uploadsFiles` homes, hit-tests folder rows/cards
  (`osDropFolderTarget`, `DriveOsDropScope`) so a drop on a folder uploads into it with the
  overlay "Upload to Designs" / "Drop files to upload to Team"; uploading rows show
  "Uploading…"; *Upload files* in empty My Drive/folders; `shell.drive.upload {parentUuid?}`
  (`Shift+U`, stays enabled offline in Drive); `WonkyAppConfig.itemMenuCommands` →
  Drive's item menu shows *Preview*, *Open with Wonky Write/Sheets* and *Download* for files
  (reusing D-14's `drive.file.*` commands) instead of *Open*.

**D-14 · Drive: file previews** — starts with spike S-D1
- Scope: `FilePreviewScreen` (`/file/:uuid`), image viewer, ~~PDF viewer (S-D1 library,
  self-hosted worker)~~ (dropped: no PDF previews in v2, 02 §6.3), text/code viewer on `CodeView` (D-2), CSV table (P1), "everything else"
  card, error states for malformed files.
- Owns: `wonky_drive/lib/features/preview/`.
- Acceptance: each viewer tested with a valid and a malformed fixture (truncated PNG, binary
  named `.txt`) → error state, not a crash; light/dark goldens; preview budgets of
  suite 11 §2 measured on the fixtures.
- **As built:** `wonky_drive/lib/features/preview/`: `FilePreviewScreen` (`/file/:uuid`, top bar,
  viewer bar, ‹ ›, trashed banner with *Restore*, details panel = the shell's
  `DriveDetailsPanel`, now exported; overlay below 768 px), `FilePreviewController` (phases
  loading / uploading (polls `drive.fileUploadStatus` every 3 s) / ready / offline / tooLarge /
  failed / notFound / notAFile (redirects to the item's app); problems imageBroken, notText), `FilePreviewHost` (per-shell collaborators, 100 MB
  `PreviewByteCache`, the active preview), `FilePreviewApi` / `ServerFilePreviewApi`
  (`drive.fileContentUrl`, `file.getUrl` for the server preview image, `http` GET with a
  50 MB cap), `PreviewType` (viewer by the sniffed MIME type; active types only as text; PDFs
  get the *Download* card), viewers `ImageViewer`, `TextFileViewer` (`CodeView`, `PreviewTokenizer`), `CsvTableViewer`, `UnsupportedFileView`,
  `FileCategoryIcon`; `PlatformFileDownloader` (web: hidden `<a download>` via `dart:js_interop`,
  same tab; desktop: not yet). Commands (`preview_commands.dart`, registered by
  `DriveAppConfig.commands`): `drive.file.preview` (`Space`, drive scope), `drive.file.openWith`
  (→ `<app>/import?file=`), `drive.file.download` (`{uuids}` or the open preview),
  `drive.preview.next/previous/zoomIn/zoomOut/zoomFit/zoomActual/rotate/toggleWrap/
  copyAll/close` in the `drivePreview` key scope (inactive in text fields). D-13 and D-17 reuse
  these ids. `wonky_core/files.dart` gained `CsvSniffer`.
- **PDF previews removed (user decision after D-18, [v2-review](../v2-review.md)):** the
  S-D1 PDF viewer (`PdfViewer`, `PdfDocumentState`, `PrintingPdfRasterizer`, page field,
  `drive.preview.goToPage`, password/broken/unavailable states, page count via
  `drive.updateFileMeta`), `web/index.html`'s `dartPdfJsBaseUrl`, `tool/fetch_pdfjs.sh` and the
  `printing` dependency were deleted; PDFs show the *Download* card like every other
  non-previewable file (02 §6.3, §6.7).

**D-15 · MCP & AI for Drive** (Drive 01 §3, suite 09)
- Scope: `drive.upload_file`, `drive.create_upload`/`drive.complete_upload`,
  `drive.download_file`, `drive.convert_file`, `drive.get_storage`, `kinds` filters, `storage`
  in results, `quota_exceeded` mapping; `ui.drive.*` definitions (P1).
- Owns: `wonky_core/lib/mcp/drive_tools.dart`, `wonky_server/lib/src/platform/mcp/drive_tool_handlers.dart`,
  `wonky_drive/lib/mcp/`.
- Acceptance: J-D9 as an MCP integration test through `/mcp`; tool schemas validated.
- **As built:** see [suite 09 §4 "As built (D-15)"](../09-mcp.md#4-shared-headless-tools) —
  `DriveTools.{uploadFile, createUpload, completeUpload, downloadFile, convertFile,
  getStorage}`, `McpSchemas.{kinds, fileCategory, storage}`, `UiDriveTools` (+
  `McpToolCatalog.drive`), `McpScope.{slidesRead, slidesEdit}` (server `allowedScopes`,
  Settings › Developer labels); server `DriveFileToolHandlers`, `DriveMcpContent`
  (`wonky://file/<uuid>`, `wonky://drive/storage`), `storage` in byte-adding results, snake_case
  `quota_exceeded` details, `ui.drive.*` relays (`app: drive`). Deviations: `drive.create_presentation`
  waits for SL-40 (headless deck); the Drive assistant (P1) is M11 (Slides 12 §1); the
  `wonky_drive/lib/mcp/` handlers are D-17.

### 4.5 Wave 4 — adaptations and integration

**D-16 · Write & Sheets adaptations**
- Scope: Write/Sheets home configs (`HomeScope.kind`, `homeNav`, template strips), *Import
  file…* label, `/new` and `/import?file=` routes, Help menu and title-row *Report a bug*,
  quota error handling on image inserts and imports (`QuotaErrorPresenter`), storage banner in
  editors.
- Owns: `wonky_write/lib/{config,features/{import,images}}/`, `wonky_sheets/lib/{config,features/{import,images,import_export}}/`.
- Acceptance: J-D5, J-D7; Write and Sheets suites green; an image insert over quota shows the
  owner dialog (AC-D3.3, widget level).
- **As built:** `WriteAppConfig`/`SheetsAppConfig.homeScope = HomeScope.kind(document /
  spreadsheet)` (app-home menu, template strip, folder rule, *Open in Wonky Drive* follow);
  `/new` = the shell default (`createItem`; Sheets offline-first); `importRoute` =
  `importDriveFileAsDocument` (Write: `drive.convertFile` directly, no options dialog — Write has
  none) / `importDriveFileAsSpreadsheet` (Sheets: bytes via `drive.fileContentUrl`, the import
  dialog with *Create new spreadsheet* only, then `drive.convertFile` with `optionsJson`); both
  pre-check the file size (`ensureRoom(reason: convert)`) and show the *Out of storage* dialog
  for a refused conversion; test seams `WriteDriveFileApi` / `DriveFileImportApi`. Shell (small,
  additive): File › New ▸ *Presentation*; app-home New menu *Import file…*; empty homes name the
  app and kind (`emptyAppHomeTitle/Body`); `ImportRoutePage`/`NewItemRoutePage` exported, cancel
  → `CrossAppNavigator.historyBack()` (browser back to Drive), errors stay in the app.
  Image uploads refused on quota (both apps, direct and queued): "Not uploaded — out of storage"
  with *Retry* / *Remove* (Write `ImageUploadPhase.outOfStorage`; Sheets
  `ImageOutOfStorageOverlay`), kept on the device and not retried automatically
  (`PendingUploads.refused/isOutOfStorage/retry`, `SheetsPendingUploads.isOutOfStorage/retry/
  cancel`). Server folder links (MCP `urlOf`, notification emails) → `/drive/f/<uuid>` (emails
  also link presentations and files). The Help menu, title-row bug button, storage banner and
  quota pre-checks of image inserts/imports were already provided by D-10/D-11.

**D-17 · Drive: Storage page, settings, commands**
- Scope: Storage page (`/storage`: breakdown, largest items, trash, versions, *Free up space*),
  Drive settings section (*Convert uploads* default off, Q13), Drive command set and keymap,
  `ui.drive.*` handlers (P1).
- Owns: `wonky_drive/lib/features/{storage,settings}/`, `wonky_drive/lib/commands/` (except
  uploads), `wonky_drive/lib/mcp/` (UI handlers).
- Acceptance: Storage page goldens light/dark; every Drive command passes execute → undo → redo
  where undoable; J-D10 server part green.
- **As built:** see [03 §13](03-storage-quota.md#13-as-built-d-17) (Storage page) and
  [04 §8–9, §13](04-screens-menus.md#8-drive-settings-settingsapp) (settings, commands, tools).
  `wonky_drive/lib/features/storage/` (`StorageScreen` in the home frame, `StoragePageController`,
  `StorageFilter` = type filters + the *Free up space* filters, `StorageApi` /
  `ServerStorageApi` on `drive.listByStorage`, `StorageHost`), `features/settings/`
  (`DriveSettingsSection`, `DriveSettings` keys/defaults/validators), `commands/drive_commands.dart`
  (`drive.view.setLayout/sort/toggleFoldersOnTop`, `drive.prefs.set`, `drive.storage.show
  {filter}`), `mcp/ui_drive_tools.dart` (`UiDriveToolHandlers`, `DriveAppConfig.mcpUiTools`).
  *Convert uploads* is built (02 §7.3 as built). `drive.file.download` got `Mod+Shift+D` and
  downloads the selected files outside a preview. Shell (additive): `ShellServices.driveView`,
  Drive's per-device view keys + `driveDefaults` in `DriveController` (`applyViewPrefs`,
  `selectIds(focus:)`), `WonkyAppConfig.listItemName`, `HomeSidebar.activeDestination`, exports
  of `DriveController`, `WonkyTopBar`, `itemMenuEntries`; `FakeUserRepository` merges
  `driveDefaults`. `wonky_ui`: `WonkyStackedBar`. J-D10's server part is
  `storage_enforcement_test.dart` (AC-D3.6, D-9).

**D-18 · M8 integration** — web-build token
- Scope: backfill dry run on a production copy (S-D3 numbers recorded in Drive 03 §2),
  a web E2E runner (`flutter drive` + chromedriver against the release builds; today's
  `e2e.yml` runs on macOS only, TODO.md), E2E journeys §6 on the web, AGENTS.md and spec
  touch-ups, the M8 exit checklist of suite 14 §2.1.
- Owns: `wonky_drive/integration_test/`, `wonky_write/integration_test/` and
  `wonky_sheets/integration_test/` (new v2 journeys only), `AGENTS.md`, `specs/`.
- Acceptance: J-D1…J-D10 pass; M8 exit criteria met.
- **As built:** the journeys were walked through by hand in the release builds (wasm,
  `localhost:8082`, light and dark, 900 px and ~480 px) with the built-in browser: files for
  uploads are generated in the page and handed to `file_picker`'s input (OS drops can't be
  synthesized, D-13), the quota is simulated with `user_storage.quotaBytesOverride` on the dev
  database, J-D9/J-D10 run as server tests. The **backfill dry run** ran on the development
  database (no production copy exists yet): see [03 §11](03-storage-quota.md#11-as-built-d-9).
  The **web E2E runner** is not set up: this machine has no chromedriver (not downloaded), so
  suite [15 §9](../15-writing-tests.md) documents the steps and the `integration_test`
  journeys J-D1…J-D10 stay open (`TODO.md`). Bugs found and fixed: see `STATUS.md` D-18 —
  notably image previews on the web (`ImageDimensions` header reader in
  `wonky_core/files.dart`; `ImageDescriptor.encoded` has no size there), the code font of
  text previews (JetBrains Mono registered through `AssetFontRegistry`), uploads of an
  offline-opened folder going to My Drive (`DriveController` only writes the shared drive
  state while it is the active home) and the *Open with Wonky Sheets* dialog
  (`showImportDialog(fileLocked: true)`: no *Change file*, only *Create new spreadsheet*).

## 5. Spikes (timeboxed, inside their package)

| ID | In | Question | Timebox | Exit |
|----|----|----------|---------|------|
| S-D1 | D-14 | PDF rendering under cross-origin isolation: `printing` raster with self-hosted pdf.js vs `pdfrx` (PDFium WASM) — bundle size, speed on a 100-page PDF, memory | 4 h | Chose `printing` + self-hosted pdf.js; **superseded**: the user decided on no PDF previews in v2 (02 §6.3), so the viewer was removed and the pdf.js files were never fetched |
| S-D2 | D-13 | Web upload plumbing: large blobs (50 MB) in OPFS via `sqlite_async`, folder drops (`webkitGetAsEntry`), XHR progress through Serverpod's `FileUploader` on web | 4 h | Confirmed limits in 02 §4.1, folder upload in or out of M8 |
| S-D3 | D-9 | Cost of `SheetsSizeEstimator` (`pg_column_size` over a 1M-cell space) and of the backfill on a production-sized copy | 2 h | Cadence in 03 §2 confirmed or an incremental estimate chosen. **Done:** cadence confirmed (03 §11); after D-18 the user chose a compact content estimate (empty spreadsheet ~80 KB → 2.3 KB), same index-driven query shape |

## 6. Acceptance tests (M8 exit)

E2E journeys on the **web** release builds (`integration_test` via the `dart` MCP
flutter_driver, suite 11 §1.1):

| # | Journey |
|---|---------|
| J-D1 | Sign in at `/` → lands on Wonky Write's home (`/write/`); the left menu shows the four apps and the meter "x MB of 50 MB used"; *Wonky Drive* opens `/drive/` |
| J-D2 | Upload 3 files by drag-and-drop into a new folder; preview the image and a `.dart` file in light and dark (the PDF shows the *Download* card); download one |
| J-D3 | Upload until the quota is full: the pre-check dialog, the server refusal on a forced upload, the over-quota banner in Drive and in the Write home; empty trash → banner disappears live |
| J-D4 | *Open with Wonky Sheets* on a CSV → spreadsheet opens in Sheets; Back returns to Drive |
| J-D5 | Write home lists only documents and the folders that contain documents; *Open in Wonky Drive* shows the same folder with all kinds |
| J-D6 | Settings split: *Write settings* from the left menu shows the Write sections; *Wonky Work settings* from the account menu shows Account…About; old `/settings/write` redirects |
| J-D7 | *Report a bug* in the Sheets editor header and Help menu shows the confirm popover and opens the prefilled GitHub new-issue page externally |
| J-D8 | Offline: drop 2 files → "Waiting for connection"; reconnect → both upload |
| J-D9 | MCP: `drive.upload_file` (text), `drive.get_storage`, `drive.download_file`, `drive.convert_file` → document; a too-large upload returns `quota_exceeded` |
| J-D10 | Ownership transfer of a large spreadsheet to a nearly full user is refused; after they free space, it succeeds |

Server tests: every endpoint of 02/03 for each role (`forEachRole`, suite 15), enforcement table
03 §7.2 row by row, reservation races, reconcile property test (03 AC-D3.7), backfill
idempotency, sniffer vectors. Widget tests and goldens (light/dark) for `HomeSidebar`,
`StorageMeter`, `StorageBanner`, the quota dialog variants, `UploadPanel` states, each viewer and
the Storage page. Every new command gets the execute→undo→redo test where undoable (suite 08 §4).
The extractions (D-2, D-3, D-6, D-7) are accepted only with the Write and Sheets suites and
goldens unchanged.

## 7. Definition of done (Drive additions)

Suite DoD (14 §1) plus: every byte-adding path has a quota test; every viewer is tested with a
malformed file and shows the error state, not a crash; the left menu and settings split are
verified in all apps that exist at the time (Drive, Write, Sheets; Slides with SL-1); no
desktop-only code paths are added (suite 01 A13); `AGENTS.md` lists the Drive app, its
`driver.dart`, the `drive` alias and the release build command.

## 8. Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| ~~PDF rendering on web under COEP (pdf.js from a CDN is blocked)~~ | — | Retired: no PDF previews in v2 (user decision, 02 §6.3); PDFs download / *Open with* |
| Large blobs in web local storage (IndexedDB fallback keeps the DB in memory) | Memory pressure, lost queued uploads | 5 MB cap for persisted blobs without OPFS; volatile rows with a clear message (02 §4.1) |
| Size estimates for big spreadsheets are expensive or jumpy | DB load, confusing meters | S-D3; throttled estimator; incremental fallback; reconcile (re-estimates spreadsheets nightly — time it on the production copy) |
| Existing users above 50 MB after the backfill | Support load, frustration | Non-destructive over-quota state, clear notification and Storage page; no grace (Q15) |
| Four web builds in `flutter_build` (deploy pre-hook time, CI minutes) | Slower deploys | Build apps in parallel in the script; cache Flutter; build only changed apps in CI |
| Old cached web clients and new enum values | Crashes on drive lists | `minClientVersion` bump (D-1) |
| Extractions destabilize Write/Sheets | Regressions | Pure moves with re-exports; existing suites and goldens are the acceptance gate (D-2, D-3, D-6, D-7) |
| Shell refactor collides with Slides work | Merge conflicts in `wonky_app` | D-10 lands in wave 2 behind a compatibility default; Slides UI starts on the scope-aware shell |
| Parallel agents exhaust the 16 GB laptop | Swapping, flaky tests | ≤ 5 agents, ≤ 2 server test runs, one web-build token (§2) |
| Upload abuse (bandwidth, storage filling across many accounts) | Cost | Quota, per-user pending-upload cap, rate limits (suite 13 §6) |
