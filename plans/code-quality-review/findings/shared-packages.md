# Code-quality review — shared packages

Scope: `packages/wonky_app` (shell), `wonky_ui`, `wonky_core`, `wonky_rich_text`, `wonky_rich_editor`,
`wonky_fonts`, `wonky_spellcheck` and their tests. Read-only review (nothing in the repo was changed).
Context read: AGENTS.md, specs/README, 01 (§2.1 package rules), 02, 03, 08.

Paths are relative to `C:\Users\info\Projects\wonky\packages\` unless they start with an app folder.
"Verified" = read in code; "Speculative" = mechanism verified, real-world impact not measured.

## Size overview

| Package | lib lines (files) | test lines (files) |
|---|---|---|
| wonky_app | 71,956 (194) — of which 17,030 generated l10n | 15,517 (73) |
| wonky_ui | 9,410 (42) | 2,031 (13) |
| wonky_core | 10,216 (32) — 5.9k are MCP tool schemas | 1,588 (15) |
| wonky_rich_editor | 4,351 (12) | 2,155 (5) |
| wonky_spellcheck | 2,537 (11) | 1,637 (11) |
| wonky_rich_text | 2,137 (12) | 447 (3) |
| wonky_fonts | 867 (4) | 117 (1) |

wonky_app by area: board 12.5k, drive 5.1k, commands 3.7k, assistant 2.8k, testing fakes 2.8k, shell 2.6k,
comments 2.5k, mcp_bridge 2.3k, auth 2.1k, data 2.1k, settings 2.0k, emoji 1.5k, storage 1.3k.

Dependency-rule check (`dart run tool/check_dependencies.dart`): no violation in this slice. It reports 4
false positives on Windows (see L-12).

---

## Prioritised findings

### HIGH

#### H-1 · Every document change rebuilds the keymap and the whole editor scaffold (perf)
- **Category:** perf · **Effort:** M
- **Evidence (verified):**
  - `wonky_app/lib/src/shell/shell_services.dart:363,379` — `activate()` adds `_onDocumentChanged`, which
    calls `registry.notifyStateChanged()` on **every** `DocumentController` notification.
  - App controllers notify very often: `wonky_write/lib/features/screen/write_document_controller.dart:136,352-359`
    (every editor change; on a selection change it also calls `notifyStateChanged()` directly, so the work runs twice);
    `wonky_sheets/lib/features/sheet_editor/sheets_document_controller.dart:74` and
    `wonky_slides/lib/features/editor_screen/deck_document_controller.dart:88` forward every editor notification.
  - `wonky_app/lib/src/commands/command_registry.dart:50` — `notifyStateChanged()` is the same notifier as
    register/unregister.
  - `wonky_app/lib/src/commands/keymap_service.dart:55` — `registry.addListener(_rebuild)`; `_rebuild`
    (`:187-216`) loops over every command (≈150 shell + 85 Write / 346 Sheets / 391 Slides command ids), calls the
    `defaultBindings`/`argBindings` getters (which allocate), rebuilds the entry list, then `notifyListeners()`.
    This runs on each keystroke or selection move.
  - `wonky_app/lib/src/editor/editor_scaffold.dart:368-479` — `ListenableBuilder(listenable: s.registry)` wraps the
    **whole** scaffold: title row, `s.menuRoot(context)` (rebuilds the app's MenuSpec tree), toolbar builder,
    new `SidePanelSpec` list with new closures, `WonkySplitView`, **`widget.body(context, item)` (the editor/grid/canvas)**
    and the status bar.
  - The apps' toolbars also listen to the registry (`wonky_write/.../write_toolbar.dart:232`,
    `wonky_sheets/.../sheets_toolbar.dart:68`, `wonky_slides/.../slides_toolbar.dart:38`, plus about 12 Slides panels).
- **Why it matters:** typing latency and selection drag in all three editors pay for a full keymap rebuild and
  a rebuild from the scaffold root (with a rebuilt document body widget) on every change. This is the
  hottest path in the product.
- **Recommendation:**
  1. Split the registry signals: keep `CommandRegistry` (ChangeNotifier) for register/unregister only, and add a
     separate `commandState` notifier (`ValueNotifier<int>` or a `Listenable`) for "enabled/checked may have changed".
     `KeymapService` listens only to structure changes.
  2. Coalesce `notifyStateChanged()` to at most once per frame (set a flag; notify from
     `SchedulerBinding.addPostFrameCallback`/`scheduleMicrotask`).
  3. Narrow the scaffold's builder: only the title row (undo labels, role) needs command state. Menubar entries
     are already lazy (`menu_resolver.dart:151-160`), so the menubar needs only labels. Build the panel list and
     the body outside the builder (or cache them in state). Never rebuild the body from a registry signal.
  4. Add a test that counts `KeymapService._rebuild` and scaffold builds per simulated keystroke.

#### H-2 · Undo transactions are global, so unrelated commands and typing join an in-flight command (bug, data integrity)
- **Category:** bug · **Effort:** M
- **Evidence (verified mechanism):**
  - `wonky_app/lib/src/undo/undo_service.dart:155` — `currentTransaction => _open.last`. This is process-global,
    not tied to the async call chain.
  - `wonky_app/lib/src/commands/command_dispatcher.dart:170-175` — any undoable command invoked while **any**
    transaction is open "joins" it (`ctx.withTransaction(outer)`). On failure `_run` rolls the whole transaction
    back (`:195-199`; `UndoTransaction.rollback` at `undo_service.dart:91-102`).
  - `wonky_write/lib/features/document/write_document_session.dart:693-697,842-846` — Write's typing and meta
    changes record into `undo.currentTransaction` when its stack matches.
- **Scenario (plausible, not reproduced):** an undoable command awaits something (a server call, an MCP
  `ui.invoke_command`, a non-modal picker such as `write.insert.emoji`, `extras_commands.dart:43-60`, which awaits
  `showEmojiPickerDialog`). Meanwhile the user presses a shortcut or types. The user's change is recorded in the
  *other* command's step (possibly labelled "AI: …") and is undone with it. If that command then fails or
  returns non-ok, the **rollback reverts the user's edits**. If the outer transaction commits first, the late
  `record()` throws `StateError('Transaction already closed')` (`undo_service.dart:66`).
- **Recommendation:** scope the current transaction to the async call chain. Run `command.execute` inside
  `runZoned(zoneValues: {_txKey: t})` and read `Zone.current[_txKey]`. Alternatively, let only the command's own
  `CommandContext.transaction` be used for nesting, and stop sharing a global. Add a test with two overlapping
  async commands, and with typing during a pending command.

#### H-3 · Editor scaffold starts presence/comments after it was disposed: zombie streams (bug, leak)
- **Category:** bug · **Effort:** S
- **Evidence (verified):**
  - `wonky_app/lib/src/editor/editor_scaffold.dart:228-239` — `_load()` awaits `markOpened`, then calls
    `widget.onItemLoaded`, `_comments.start()` and `_presence.start()` **without checking `mounted`**.
    `_setItem` checks it, but the code after `_setItem` does not.
  - `wonky_app/lib/src/presence/presence_session.dart:56-65` — `start()` has no `_disposed` guard. It adds a
    `WidgetsBindingObserver` (never removed again) and a supervised presence stream. `dispose()` (`:237-247`)
    has already cancelled the supervisor key and closed `_updates`.
  - `wonky_app/lib/src/comments/comments_controller.dart:106-115` — same for the comments watch stream
    (`dispose` at `:546-551`).
  - `wonky_app/lib/src/core/stream_supervisor.dart:48-59,111-120` — `supervise()` **replaces by key**
    (`presence:<uuid>` / `comments:<uuid>`) and retries forever.
- **Why it matters:** suppose the user opens a document and leaves before `markOpened` returns (slow network,
  quick Back). A zombie stream then reconnects forever, with backoff. The user may stay "present" in that file.
  If the same document is reopened quickly, the late zombie `supervise()` can **replace the live editor's
  stream** with the same key. The observer leak keeps the disposed session reachable.
- **Recommendation:** add `if (!mounted) return;` right after the await in `_load`. Make `PresenceSession.start`
  and `CommentsController.start` no-ops after dispose. Make `supervise` return an owner token whose
  `cancel()` only cancels its own entry, so stale owners cannot evict or replace other entries.

### MEDIUM-HIGH

#### H-4 · Undo/redo is not serialized, and a failing handler loses the step (bug)
- **Category:** bug · **Effort:** S–M
- **Evidence (verified):**
  - `wonky_app/lib/src/undo/undo_service.dart:410-446` — `_apply` removes the step (`from.removeLast()`, `:414`)
    before awaiting the handlers. Any exception other than `UndoConflict` propagates and the step is pushed
    nowhere: it is in neither undo nor redo, and the entries that were already applied are not recorded either.
  - `_applying` is a bool (`:139,417,429`). The first of two concurrent undos resets it while the second is still
    running.
  - `keymap_service.dart:268-282,286-290` — undo/redo are explicitly key-repeatable, and shortcut invocations
    are not awaited. Holding Ctrl+Z therefore starts overlapping `_apply` calls.
  - Write depends on `isApplying` to avoid recording undo-generated edits:
    `write_document_session.dart:696,836`, `write_comments.dart:255,278`, `ai_undo_grouping.dart:56`.
- **Why it matters:** holding Ctrl+Z, or a network error in a drive/server-change undo handler, can corrupt the
  stacks. Write may record undo output as new user edits, which clears redo.
- **Recommendation:** serialize `undo/redo/undoTo` through a Future-chain mutex and make `_applying` a depth counter.
  On a handler failure, put the step back (or push the partial inverse to the opposite stack, marked
  `partiallyRebased`) and surface the error. Add tests for both cases.

#### H-5 · Cold-start downloads several MB of unused fonts (perf, web startup)
- **Category:** perf · **Effort:** S–M
- **Evidence (verified in `wonky_server/web/write/assets/FontManifest.json`):** the manifest lists
  `LucideVariable-w100…w600.ttf` (6 files, ≈2.9 MB, not tree-shaken), shad's `Inter[opsz,wght].ttf` (877 KB; the theme
  uses Geist, `wonky_ui/lib/src/theme/wonky_theme.dart:95`) and **`golden_toolkit/fonts/Roboto-Regular.ttf`**
  (163 KB, a test package). `golden_toolkit`, `flutter_test`, `mockito` and others are regular `dependencies` of the
  vendored `third_party/super_editor/pubspec.yaml:46-56`. They reach **every** app through
  `wonky_app → wonky_rich_editor → super_editor`. Only Slides uses the `Lucide100…600` families
  (`wonky_slides_core/lib/src/icons/lucide_glyphs.dart:15-57`).
- **Why it matters:** Flutter web fetches the fonts in `FontManifest.json` during engine start-up. Confirm in the
  network panel: this is how the engine works, but I did not measure it. That is about 4 MB of avoidable downloads
  before the first frame in Write, Sheets and Drive.
- **Recommendation:** in the vendored super_editor (already patched), move test tooling to `dev_dependencies` or
  into a separate `super_editor_test` library. In `flutter_build`, post-process `FontManifest.json` for each app
  to drop unused families (Lucide weights outside Slides, Inter if unused). In Slides, load the Lucide weight
  fonts lazily with `FontLoader`, as `AssetFontRegistry` already does for document fonts.

#### H-6 · Boot is blocked on sequential network round trips (perf/UX, offline-first)
- **Category:** perf · **Effort:** M
- **Evidence (verified):** `wonky_app/lib/src/shell/wonky_shell.dart:96-104` waits for `WonkyClient.initialize()`
  before `runApp` (auth init up to 8 s, `bootstrap/wonky_client.dart:46-52`). `_init` (`wonky_shell.dart:194-202`)
  then awaits `_afterSignIn`, which in turn awaits `users.getMe()`, `CachedDriveRepository.init()`,
  `prefs.loadRemote()` and `config.onSignedIn(s)` **sequentially** (`:217-255`). Only after that does it set
  `_ready = true`. `ShellOverlays` shows only the logo and spinner until then (`shell/overlays/shell_overlays.dart:85-97`).
- **Why it matters:** the first frame of real UI waits for 2–3 dependent RTTs. If the server is unreachable but
  the browser is "online", each call waits for the client timeout. That can take tens of seconds (speculative,
  depends on the Serverpod client timeout), which defeats the offline-first Sheets/Slides story.
- **Recommendation:** set `_ready` after the local work (`prefs.loadLocal`, cached profile in `userStore`, cache
  bind). Run `getMe`/`loadRemote`/`onSignedIn` in the background in parallel (`Future.wait`), with short timeouts.
  Persist the last `UserProfileView` so `currentUser` exists offline.

### MEDIUM

#### M-1 · Shell mutations that bypass the command system (spec 08 violation)
- **Category:** maintainability/bug · **Effort:** S
- **Evidence (verified):** `wonky_app/lib/src/drive/details_panel.dart:48-63` calls
  `services.drive.updateDescription` directly. `wonky_app/lib/src/drive/dialogs/drive_dialogs.dart:245-260`
  ("New folder" in the Move dialog) calls `s.drive.createFolder` directly. Neither is undoable, neither is
  MCP-invokable, and neither emits `CommandInvoked`. (Token create/revoke in `mcp_bridge/developer_settings.dart:190,213`
  also bypasses commands; that may be intentional for secrets.) Also: `details_panel.dart:41-46,76` sets controller
  text inside `build()` (`_ensure`).
- **Recommendation:** route both through `shell.drive.*` commands (`shell.drive.newFolder` exists,
  `drive_commands.dart:35`). Add a `shell.drive.setDescription` command with an undo entry. Move `_ensure`
  into `didUpdateWidget`.

#### M-2 · Large lists rebuild every child on each notification (perf)
- **Category:** perf · **Effort:** S–M
- **Evidence (verified):**
  - `wonky_app/lib/src/drive/item_list.dart:126-133,150-184,240-251` — list view is `ListView(children: rows)`
    (eager). It rebuilds on `DriveController`, `connectivity` and `OfflineStorage` changes, and paging (50–100 per
    page, `drive_controller.dart:275,289`) grows it without bound. The grid already uses `GridView.builder` (`:266`).
  - `wonky_app/lib/src/comments/comments_panel.dart:86-186` — eager `ListView` of all thread cards.
    `CommentsController.visible` (`comments_controller.dart:348-368`) refilters and sorts with `positionOf` (an
    anchor mapping, probably O(doc) in Write) on every build, without memoization.
  - `wonky_app/lib/src/assistant/assistant_panel.dart:110-111,284-307` — the panel rebuilds all entries on every
    controller notify (each streamed delta). `WonkyMarkdown` re-parses its text in every `build`
    (`markdown/wonky_markdown.dart:161-164`) and disposes/recreates link recognizers each time. Streaming cost is
    O(conversation) per token.
- **Recommendation:** use `ListView.builder`/`SliverList` over a flat item model (headers + rows). Memoize
  `visible` per (threads version, filter, sort, anchor generation), with sort keys precomputed once. In
  `WonkyMarkdown`, cache the parsed blocks in state and reparse only when `text`/`profile` change
  (`didUpdateWidget`). Give the streaming reply its own `ValueListenable`.

#### M-3 · Persisted undo stacks grow in localStorage without bounds or cleanup (perf/robustness, partly speculative)
- **Category:** perf/bug · **Effort:** M
- **Evidence (verified):** Sheets and Slides set `persistUndo => true` (`sheets_document_controller.dart:67`,
  `deck_document_controller.dart:31`). `UndoService._save` writes up to 500 steps as JSON per document
  (`undo/undo_service.dart:121,450-485`, 600 ms debounce) through `SharedPreferencesStore`
  (`core/local_store.dart:50-70`), which is localStorage on the web: synchronous, ≈5 MB per origin, and shared by
  all four apps on the one origin. Keys `undo.<doc>` are deleted only with `forget: true`, which only Write's theme
  editor uses (`theme_editor_controller.dart:480`). *Clear local data* does not clear them
  (`settings/sections/offline_section.dart:122-130`). Sign-out clears only memory (`wonky_shell.dart:262`).
  Pending saves are cancelled on dispose, not flushed (`undo_service.dart:511-514`). The drive cache (500 items) and
  the offline drive op queue live in the same store (`data/drive_cache.dart:175-181,292-293`).
- **Why it matters:** once the quota is hit, writes fail. Undo failures are swallowed (`:484`). Queued offline
  drive ops would fail to persist. Large JSON encodes run on the UI thread.
- **Recommendation:** keep an LRU index of undo keys (for example, the last 20 documents) with a byte cap per stack.
  Better, move undo persistence to `LocalDatabase` (sqlite/IndexedDB). Clear on *Clear local data* and sign-out.
  Flush on dispose.

#### M-4 · Async errors are not reported; the error boundary is installed repeatedly (observability)
- **Category:** bug/DX · **Effort:** S
- **Evidence (verified):** `shell/overlays/shell_overlays.dart:40-45,256-266` sets `FlutterError.onError` and
  `ErrorWidget.builder` only. Nothing sets `PlatformDispatcher.instance.onError`, so the errors of the 130
  `unawaited(...)` futures in wonky_app (including streams and repository calls) never reach `feedback.reportError`
  or the board's "last error". `installErrorBoundary` runs in `initState`, and each new `ShellOverlays` state
  chains another wrapper around the previous handler (duplicate reports, and closures over old `ShellServices`).
  It is never uninstalled in `dispose`.
- **Recommendation:** install once per `ShellServices` (idempotent) and restore it on dispose. Add
  `PlatformDispatcher.instance.onError` that reports and returns `true`. Enable the `unawaited_futures`,
  `discarded_futures` (where it makes sense), `cancel_subscriptions` and `close_sinks` lints. Today only strict
  language modes are on (`*/analysis_options.yaml`).

#### M-5 · `ShellServices` is a god object and service locator with mutable UI slots (maintainability)
- **Category:** maintainability · **Effort:** L
- **Evidence (verified):** `wonky_app/lib/src/shell/shell_services.dart:99-467` has about 45 public fields. It mixes
  DI (repositories, dispatcher, undo, prefs), app-wide state (`currentUser`, `serverInfo`) and **widget-owned
  slots**: `driveSelectAll`, `driveSearchFocus`, `startTitleRename`, `focusRegions`, `commentsHost`, `openDialogs`.
  Widgets set and clear these by hand with identity checks (`editor_scaffold.dart:165,253-264`,
  `drive/drive_controller.dart:37,518`, `drive/home_screen.dart:75,90-93`,
  `wonky_drive/.../file_preview_screen.dart:67,78`). Feature singletons are attached through `Expando`s
  (`BoardHub._hubs`, `_bridges`, `ShellSpelling._ignoredBy`).
- **Recommendation:** split it into `ShellServices` (immutable DI), `ShellSession` (signed-in state) and
  `ShellViewState` (UI slots). Expose slot registration as `Disposer register…()` handles instead of public
  mutable fields. Move the navigation-history logic (`:222-282`) into its own class.

#### M-6 · Cross-app duplication that belongs in `wonky_app` (maintainability)
- **Category:** maintainability · **Effort:** M
- **Evidence (verified):** `wonky_sheets/lib/features/images/image_clipboard_web.dart` and
  `wonky_slides/lib/features/elements/image/image_clipboard_web.dart` are **identical** (`diff` is empty), and their
  `_io`/facade files nearly so. `pdf_view_web.dart` in Write and Slides differs only in the view-type prefix and a
  `page` parameter. There are three `system_clipboard{,_io,_web}.dart` (Write/Sheets/Slides), three
  `print_preview_screen.dart` (426/682/458 lines) and three `server_change_undo.dart`.
- **Recommendation:** move the platform helpers (`PdfView`, image/system clipboard read/write) into `wonky_app`
  (or a small `wonky_platform` leaf), parameterised by key prefix as already done for `SpellingKeys` and
  `EmojiPickerKeys`. Consider a shared print-preview frame.

#### M-7 · Three Markdown implementations with no cross-check (correctness risk)
- **Category:** maintainability/testing · **Effort:** M
- **Evidence (verified):** the board/comment/assistant *renderer* is a hand-written regex/line parser
  (`wonky_app/lib/src/markdown/markdown_blocks.dart`, `markdown_inline.dart`). The *composer* encodes with
  `package:markdown` in `wonky_rich_editor/lib/src/codec/markdown_document_codec.dart`. A third inline codec is
  `wonky_rich_text/lib/src/markdown/*`. No test feeds composer output into `MarkdownBlocks`
  (`wonky_app/test/markdown/*` tests each side alone).
- **Recommendation:** add a property test that takes random documents, encodes them with the composer codec,
  renders them with `MarkdownBlocks` and checks the structure (lists, nesting, code fences, escapes, links). In the
  longer term, share one block/inline grammar (keep the tolerant streaming mode as a flag).

#### M-8 · Testing gaps in the shell's riskiest parts (testing)
- **Category:** testing · **Effort:** M
- **Evidence (verified by grep of `wonky_app/test`):**
  - No direct tests for `EditorScaffold` (864 lines), `ShareDialog` (803), `PresenceSession`, `StreamSupervisor`,
    `ConnectivityService`, `MenuResolver` or `CommentsController` (552; only `comment_thread_body_test.dart`).
  - `undo_service_test.dart` (252 lines) does not cover concurrent undo, handler failure or overlapping transactions.
  - `json_schema_test.dart` (101 lines) covers a 436-line validator that guards every MCP/AI command.
  - No goldens in `wonky_ui`, which needs light/dark regression checks of tokens; wonky_app has 3 golden files.
  - `wonky_rich_text` has no tests for `delta_utils`, `links`, `text_rules` or `attributes` (it relies on Write's
    tests).
- **Recommendation:** add unit tests for H-2/H-3/H-4 first (they are cheap with `CommandTestHarness`/fakes), then a
  supervisor test with fake async (backoff, replace-by-key, reconnect), then light/dark goldens for the wonky_ui
  widgets.

### LOW

| ID | Title | Cat. | Evidence | Recommendation | Effort |
|---|---|---|---|---|---|
| L-1 | Keymap dispatch scans linearly, with a substring "repeatable" heuristic | perf/bug | `commands/keymap_service.dart:265-268`: every key event scans all entries per bubbling scope and allocates `binding.resolve(platform)` per entry. `:286-290`: `_repeatable` uses `id.contains('move'/'undo'/…)`, which matches `shell.edit.undoHistory` and every `*.remove*` (`drive.upload.remove`, `sheets.link.remove`, …) | Index `Map<(KeyScope, ResolvedChord), List<KeymapEntry>>` in `_rebuild`, and add an explicit `Command.repeatable` flag | S |
| L-2 | `DocumentScope`/`ActiveDocumentHostScope` are dead public API | maint. | `document/document_controller.dart:155-226`; no usage outside docs (the class doc at `:14` still says editors use it; `EditorScaffold` activates directly, `editor_scaffold.dart:184-200`) | Delete, or make `EditorScaffold` use it; fix the docs | S |
| L-3 | `_afterSignIn` runs twice on every sign-in | perf | `auth/auth_controller.dart:136-139,152-155,209-211,266-267` notify, then call `onSignedIn`. The notify triggers `_onAuth` → `_afterSignIn(null)` (`shell/wonky_shell.dart:267-270`): duplicate `getMe` and `CachedDriveRepository.init` | Guard with an in-flight Future, or drop one trigger | S |
| L-4 | Listener on a parent-owned FocusNode is never removed | bug | `drive/top_bar.dart:170-175` adds a closure to `widget.focusNode` (owned by `home_screen.dart:52`) that calls `_popover.show()`. `_popover` is disposed in `:178-182`, so a recreated search field (mobile/desktop switch) leaves a stale listener | Store the callback; remove it in `dispose`/`didUpdateWidget` | S |
| L-5 | `setState` after `await` without a `mounted` check | bug | `drive/dialogs/drive_dialogs.dart:256`, `mcp_bridge/developer_settings.dart:195` | Add `if (!mounted) return;` | S |
| L-6 | Root `ShadApp` rebuilds on any preference write | perf | `shell/wonky_shell.dart:310-349` listens to all of `s.prefs` (device values such as `search.recent` and `panel.width` notify, `core/preferences_controller.dart:237-241`). `config.mcpUiTools(s)` is rebuilt every time but read only in `initState` (`mcp_bridge/mcp_bridge_scope.dart:44-51`) | Listen to a theme-only selector; compute `mcpUiTools` once | S |
| L-7 | Kind colors bypass tokens and differ between helpers | design | `drive/drive_format.dart:64-70`: `kindColor` has no dark variants and presentation is `#d97706`, while `fileCategoryColor` (`:37-58`) uses `#ea580c` | Add `kindDocument/Spreadsheet/Presentation` custom tokens in `WonkyColors` (spec 02 §2), light and dark | S |
| L-8 | v1 leftovers in shared code | maint. | `commands/shell_commands/general_commands.dart:1290-1310`: `shell.account.switchApp` is titled "Open Sheets/Open Write" in Drive/Slides. Spelling settings and the personal dictionary live in `writeDefaults` but are used by the board and Slides (`spellcheck/shell_spelling.dart:274-277`, `personal_dictionary.dart:6-17`) | Title by target app; move spelling prefs to a suite-level key (with migration) | S |
| L-9 | A new Timer on every key/pointer event | perf | `editor/editor_scaffold.dart:361-367` → `presence/presence_session.dart:169-179` (`_resetIdle` cancels and recreates a 60 s Timer) | Store a `lastActivity` timestamp; one periodic check | S |
| L-10 | Font registry ignores weight/italic; caches bytes forever | perf | `fonts/asset_font_registry.dart:73-90` loads **all** faces of a family on first use; `BundledAssetFontProvider._bytes` (`:139-142`) never evicts (PDF export) | Load the requested face first, the rest lazily; LRU-cap the byte cache | S |
| L-11 | Every web build copies 13 MB of dictionaries and 9 MB of fonts, and each app has its own URL | ops/perf | `wonky_server/web/write` (84 MB) and `slides` (96 MB) each contain `assets/packages/wonky_spellcheck` and `wonky_fonts`; Drive gets them too through wonky_app. Write and Slides users download the same `.dic` twice (different paths, no shared cache) | Serve shared assets from one origin path (the server already has `web/fonts`) and point `SpellDictionaries`/`AssetFontRegistry` at it on the web | M |
| L-12 | The dependency-check tool fails on Windows | DX | `tool/check_dependencies.dart:712-715`: `packageRel` has `\` separators, so `_devEntryPoints.contains('lib/driver.dart')` fails and it reports 4 false violations locally | Normalize with `p.posix`/`replaceAll(r'\', '/')` | S |
| L-13 | Errors are swallowed silently | DX | 16 `catch (_) {}` in this slice (for example `board/pages/board_page.dart:126,130`, `post_page.dart:137,170,503`, `sharing/share_dialog.dart:118`, `shell/wonky_shell.dart:207`). `CommandDispatcher.stateOf` (`command_dispatcher.dart:109-115`) turns `isEnabled` exceptions into "disabled" without a log | `debugPrint`/report in debug at least; log in `stateOf` under `kDebugMode` | S |
| L-14 | `EditorScaffold` assumes the apps key it by uuid | maint. | `editor_scaffold.dart:186-198` handles a controller change but not an `itemUuid` change. Correctness depends on every app passing `ValueKey('…screen.$uuid')` (`write_document_screen.dart:176`, `sheet_editor_screen.dart:263`, `deck_editor_screen.dart:303`) | Assert in `didUpdateWidget` or rebuild the comments/presence objects on a uuid change | S |
| L-15 | Very long build methods | maint. | `drive/home_screen.dart:539` (≈384 lines), `board/pages/post_page.dart:602` (≈254), `editor/editor_scaffold.dart:626` `_titleRow` (≈203) and `:324` `build` (≈159), `versions/version_history_screen.dart:78` (≈188) | Extract private widgets (selection bar, title row, filters). This also narrows rebuilds | M |
| L-16 | Heartbeat keeps pinging in hidden tabs | perf | `core/connectivity_service.dart:19` (15 s) ignores `AppLifecycleState` (only presence/MCP observe it) | Back off while hidden; check immediately on resume | S |
| L-17 | Undo stack open/close races | bug (speculative) | `shell_services.dart:355-361,374`: `openStack` is unawaited, so steps pushed during `_load` end up *below* the restored ones (`undo_service.dart:181,503-504` uses `addAll`). Reopening a document while `closeStack` is saving lets the pending close remove the reopened stack (`:214-215`) | Make `openStack` insert restored steps at index 0 and keep per-key open/close futures | S |

---

## Largest files (non-generated) and recommendations

| Lines | File | Recommendation |
|---|---|---|
| 9,112 / 7,918 | `wonky_app/lib/src/l10n/*` | Generated; fine |
| 1,724 / 1,683 / 916 / 584 | `wonky_core/lib/mcp/{slides,sheets,write,drive}_tools.dart` | Declarative schemas; fine, but split per area (`sheets_tools/cells.dart`, …) for reviewability. Not in client bundles (`McpToolCatalog` is unused client-side) |
| 1,559 | `wonky_app/lib/src/testing/fake_board_repository.dart` | Test fake in `lib/`; split per feature (posts/tasks/admin) or move to a `wonky_app_testing` package |
| 1,397 | `wonky_app/lib/src/commands/shell_commands/general_commands.dart` | Already grouped by function; split into one file per group (navigation/file/sharing/edit/comments/versions/panels/view/misc) |
| 1,280 | `wonky_app/lib/src/board/board_commands.dart` | Split by posts/comments/tasks/admin |
| 1,221 | `wonky_app/lib/src/comments/comments_panel.dart` | Move `MentionField`, `NewCommentCard` and `CommentThreadCard` into files; builder list (M-2) |
| 1,160 | `wonky_app/lib/src/emoji/emoji_picker.dart` | Split data/model from widget |
| 1,136 | `wonky_app/lib/src/board/report/board_report_dialog.dart` | Extract screenshot, details and similar-posts sections |
| 1,054 / 875 / 861 | `board/pages/{board_page,post_page,board_widgets}.dart` | Fine-grained widgets; post_page build is ≈254 lines |
| 1,029 | `wonky_app/lib/src/drive/home_screen.dart` | The 384-line build is the main candidate to split |
| 980 / 955 | `wonky_rich_editor/.../wonky_rich_editor.dart`, `markdown_editing_controller.dart` | Acceptable; well tested (≈2.1k lines of tests) |
| 921 | `board/screenshot/screenshot_editor.dart` | OK |
| 910 | `assistant/assistant_panel.dart` | Builder list (M-2) |
| 897 | `drive/item_list.dart` | Builder list (M-2) |
| 864 | `editor/editor_scaffold.dart` | Narrow rebuild scope (H-1), split `_titleRow` |

Board placement: the 12.5k-line board ships in every app's main bundle, and nothing in wonky_app uses deferred
imports. Settings, the board, the screenshot editor, version history and the emoji/special-characters data are
candidates for `deferred as` loading. Check dart2wasm deferred-loading support for the pinned Flutter first.
Main bundles today: Write `main.dart.wasm` 9.2 MB, Slides 12.1 MB, uncompressed.

---

## Things done well
- **Spellcheck:** dictionaries load on demand, parsing is time-sliced to 8 ms per frame with no timers
  (`spellcheck/dictionaries.dart:116-142`), and suggestions run under a time budget
  (`wonky_spellcheck/lib/src/suggester.dart:23-50`). Pure-Dart engine with 1.6k lines of tests.
- **Fonts:** no `fonts:` pubspec sections for document fonts. `AssetFontRegistry` loads families lazily with
  `FontLoader` and a generation notifier.
- **Theme:** memoized by value (`WonkyTheme._cache`), and `WonkyThemeExtension` has proper `==`/`hashCode`, which
  avoids the 200 ms lerp and needless rebuilds.
- **Custom toolbar overflow:** done as a single-pass `RenderBox` (`wonky_ui/.../overflow_layout.dart`), not
  LayoutBuilder measuring.
- **Package rules:** the dependency rules hold (only the Windows false positives); the platform splits are clean
  (`jpeg_encoder_web.dart` uses the browser's encoder instead of `package:image`).
- **Accessibility:** of 66 `ShadIconButton`s in the slice, only 2 lack a `semanticLabel`/tooltip wrapper, and
  both are wrapped in `Semantics`. Undo announcements use `SemanticsService`, there is a home-screen a11y test, and
  essentially no hard-coded English strings.
- **Lifecycles:** carefully handled in most widgets (identity-checked slot cleanup, post-frame
  activate/deactivate to avoid build-phase notifications, `_disposed` guards in notifiers). The `StreamSupervisor`
  has jittered backoff and reconnects on connectivity.
- **Spec traceability:** doc comments cite spec sections almost everywhere, so intent is easy to check.
- **Test helpers:** `CommandTestHarness`, `pumpShell` and fakes make shell tests cheap. The rich editor has
  property tests for its codec.
