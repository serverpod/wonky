# 08 · Commands, Keyboard Shortcuts and Undo/Redo

This is the single most important cross-cutting architecture in Wonky Work. **Every** state change
that a user (human or agent) can trigger is a **command**. Commands are what menus, toolbars,
context menus, keyboard shortcuts, the command palette, the MCP UI bridge and the AI assistant
invoke. Undo/redo is built on top of commands.

Package ownership:

| Piece | Package |
|-------|---------|
| `CommandId`, `CommandArgs` schema types, `UndoEntry` abstractions (pure Dart) | `wonky_core` |
| `CommandRegistry`, `CommandDispatcher`, `KeymapService`, `UndoService`, Command Palette widget | `wonky_app` |
| App-specific commands | `wonky_write/lib/commands/…`, `wonky_sheets/lib/commands/…`, (v2) `wonky_drive/lib/commands/…`, `wonky_slides/lib/commands/…` |

---

## 1. Command model

```dart
/// Stable, dot-separated id. Never rename once shipped (MCP clients depend on it).
/// Convention: <app|shell>.<area>.<action>, e.g. "write.format.bold",
/// "sheets.rows.insertAbove", "shell.drive.newFolder"; (v2) app ∈ drive, write, sheets, slides
/// ("drive.upload.retry", "slides.slide.duplicate").
extension type const CommandId(String value) {}

abstract class Command<A extends CommandArgs> {
  CommandId get id;

  /// Human title, localized. Used in menus, palette, tooltips, undo labels ("Undo Bold").
  String title(BuildContext context);

  /// Optional longer description; shown in palette and exposed to MCP as tool description.
  String? description(BuildContext context) => null;

  /// Icon (Lucide icon data from shad).
  IconData? get icon => null;

  /// JSON-schema of the arguments, used by MCP (`ui.invoke_command`) and the AI assistant.
  JsonSchema get argsSchema;
  A parseArgs(Map<String, Object?> json);

  /// Default key bindings (platform-aware). Users can override in Settings → Keyboard.
  List<KeyBinding> get defaultBindings => const [];

  /// Whether the command can currently run (drives disabled state everywhere).
  bool isEnabled(CommandContext ctx, A args) => true;

  /// For toggle commands (bold, show gridlines…): current checked state.
  bool? isChecked(CommandContext ctx) => null;

  /// Minimum role required; checked by the dispatcher before execute.
  Role get requiredRole => Role.editor;

  /// Whether this command mutates undoable state. Non-mutating commands (navigation,
  /// zoom, open dialog) return false and never create undo entries.
  bool get isUndoable => true;

  /// Executes. May be async (e.g. dialogs, server calls). Returns a result that is serialized
  /// back to MCP callers.
  Future<CommandResult> execute(CommandContext ctx, A args);
}
```

`CommandContext` exposes: the active app (`drive`/`write`/`sheets`/`slides`, v2), the active document controller (if
any), the current selection, the user's role on the document, the `UndoService`, the
`BuildContext` (for dialogs; null when headless), and an `InvocationSource` enum
(`menu`, `toolbar`, `shortcut`, `contextMenu`, `palette`, `mcp`, `ai`, `script`).

### 1.1 Registry and dispatch

- `CommandRegistry` is populated at app start. Shell commands are registered by `wonky_app`;
  each app registers its own. Registration is static — no dynamic commands except **script
  macros** in Sheets (`sheets.macro.<macroId>`), registered when a spreadsheet loads.
- `CommandDispatcher.invoke(id, args, source)`:
  1. Looks up command; throws `UnknownCommand` if missing.
  2. Validates args against schema.
  3. Checks role ≥ `requiredRole` (viewers can't run mutating commands; commenters can only run
     comment commands).
  4. Checks `isEnabled`.
  5. Opens an **undo transaction** if `isUndoable` (see §3), runs `execute`, commits the
     transaction (or rolls back on exception).
  6. Emits a `CommandInvoked` event (used for analytics/debug log and the MCP `ui.events` stream).
- Menus/toolbars use `CommandButton(id: …)`, `CommandMenuItem(id: …)` widgets from `wonky_app`
  that read title/icon/shortcut/enabled/checked from the registry and rebuild on relevant changes.
  **No menu or toolbar may call business logic directly.**
- **Two change signals** (CQ-39): the registry notifies when commands *or their state* may
  have changed. Registration is synchronous; `notifyStateChanged()` (the active document
  changed, selection moved, role changed, undo ran) is coalesced to at most one notification
  per frame, delivered at the start of the next frame. `CommandRegistry.registrations`
  notifies only on register/unregister; the `KeymapService` rebuilds its chord table on that
  signal alone, never per keystroke. The editor scaffold rebuilds only its menubar from the
  registry; toolbars, panels and status widgets listen to what they show, and the document
  body is never rebuilt from a command-state signal (`editor_scaffold_rebuilds_test.dart`
  counts the rebuilds).

### 1.2 Keyboard shortcuts

- `KeymapService` maps `KeyBinding` → `CommandId` (+ fixed args). Platform-aware: `Mod` = ⌘ on
  macOS, Ctrl elsewhere. On web, browser-reserved shortcuts (⌘W, ⌘T, ⌘N, ⌘L) are never bound.
- Scopes: `global` (app shell), `editor` (Write editor focused), `grid` (Sheets grid focused),
  `cellEditor` (Sheets cell editing), `dialog`; (v2) `driveList` (a home's list/grid focused),
  `preview` (Drive file preview), and the Slides scopes of
  [Slides 04](wonky_slides/04-screens-menus-toolbar.md) (canvas, text editing, navigator,
  presenting). More specific scopes win.
- **Argument bindings**: `Command.argBindings` binds a chord to fixed arguments, optionally in
  another scope (`sheets.nav.move {dir: down}` on ↓ in `grid`); menus show the shortcut of a
  parameterized item through `KeymapService.labelsFor(id, args)`.
- **Contextual bindings**: a key binding may map to an ordered list of commands within a scope;
  the dispatcher runs the first one whose `isEnabled` is true (e.g. `Tab` = indent list item →
  insert spaces in code block → move focus; `Mod+J` = inline AI prompt when the caret is in an
  empty paragraph → toggle assistant panel otherwise). Conflict detection in the settings
  screen treats such lists as one binding.
- Shared edit commands have fixed ids: `shell.edit.undo`, `shell.edit.redo`, `shell.edit.cut`,
  `shell.edit.copy`, `shell.edit.paste`, `shell.edit.pasteWithoutFormatting`,
  `shell.edit.selectAll`, `shell.edit.undoHistory`; apps contribute the actual behavior through
  the active document controller.
- User overrides are stored in `UserPreferences.keymapOverrides` (JSON) and synced via server.
- **Settings → Keyboard shortcuts** screen: searchable table of all commands with bindings;
  click to record a new binding; conflict detection with "Replace"/"Cancel"; reset per row and
  "Reset all".
- **Keyboard shortcuts help** dialog (`Mod+/`): categorized read-only list, searchable.

### 1.3 Command palette

- Opened with `Mod+Shift+P` (`Mod+K` is reserved for *Insert link* in both apps, as in Google
  Docs/Sheets). Built from shad `ShadDialog` + custom
  `CommandPalette` list (see design system).
- Fuzzy search over title, description, aliases and menu path ("Format › Text › Bold"). This is
  also how menu commands are searched (there is no separate "Search the menus" mode).
- Rows for files show the file's kind icon (`PaletteRow.leading`, `DriveKindIcon`, suite 02 §5).
- Shows shortcut on the right, disabled commands greyed (with reason tooltip).
- Sections: *Recent*, *Suggested* (context-dependent), *All commands*. Additional providers:
  "Go to document…" (drive search), "Go to sheet/heading…", "Ask AI: <query>".
- Commands that need args show an inline arg form (e.g. "Insert rows… → count").

---

## 2. What counts as undoable

| Area | Undoable | Not undoable (by design) |
|------|----------|--------------------------|
| Write content | All text/structure/format edits, paste, find-replace-all, AI insertions | — |
| Write metadata | Title rename, theme assignment, theme edits, page setup, document language | Sharing changes |
| Sheets content | Cell values, formulas, formats, row/col ops, sheet ops, merges, CF/DV rules, filters, sorts, charts, pivots, named ranges, protected ranges | — |
| Sheets settings | Spreadsheet settings (locale, recalc, iterative calc), sheet properties (name, color, gridlines, frozen panes) | — |
| Slides content (v2) | Slides, groups, elements, text, styles, builds, transitions, themes/masters/layouts, code states, chart links (update/unlink), notes — through `slides.rows` | — |
| Drive | Move, rename, star, trash (undo = restore), create folder, (v2) upload batch (undo = trash the uploaded items) | Permanent delete, empty trash, sharing changes, ownership transfer, (v2) downloads, conversions (*Open with* creates a new item you can trash), settings |
| View state | — | Zoom, scroll, panel visibility, selection (selection is *restored* on undo but isn't an undo step) |
| Comments | Creating/editing/deleting own comment, resolve/reopen | — |

Non-undoable actions that are destructive (permanent delete, unshare) always show a confirm
dialog instead.

---

## 3. Undo architecture

### 3.1 Principles

1. **Local, per-user, per-document undo** (like Google Docs/Sheets): undo only reverts *your*
   changes, never a collaborator's. Remote changes are never on your stack.
2. **Undo is a forward operation.** Undoing writes a new change that restores previous state.
   Collaborators see it as a normal edit. Nothing is ever "rewound" on the server.
3. **Transactions.** One user gesture = one undo step. Commands open a transaction; the
   transaction collects `UndoEntry`s from each affected domain and commits them atomically.
4. **Typing coalescing.** Consecutive character insertions/deletions in the same block within
   1000 ms and without caret jumps coalesce into one step (Write and Sheets cell editor).
5. **Selection restoration.** Each step records `selectionBefore` and `selectionAfter`; undo
   restores `selectionBefore`, redo restores `selectionAfter`.
6. **Redo is cleared** by any new local undoable change.
7. **Stack size**: 500 steps per document (configurable constant). Stacks are kept in memory and
   persisted to local storage per document so undo survives reload (best-effort; cleared when
   the local document state is discarded).
8. **Labels**: every step has a label ("Undo Typing", "Undo Insert row", "Undo Paste") shown in
   Edit menu and tooltips.

### 3.2 Core types (`wonky_core`)

```dart
abstract class UndoEntry {
  /// Domain key ("write.content", "write.meta", "sheets.cells", "drive"…). Used to
  /// route the entry to the right UndoHandler.
  String get domain;

  /// Called when a remote change arrives in this domain. Returns the rebased entry,
  /// or null if the entry is now a no-op (e.g. the edited text was deleted remotely).
  UndoEntry? rebase(RemoteChange change);
}

class UndoStep {
  final String label;
  final List<UndoEntry> entries;           // applied in reverse order on undo
  final SelectionSnapshot? selectionBefore;
  final SelectionSnapshot? selectionAfter;
  final DateTime createdAt;
  final InvocationSource source;           // so MCP/AI steps can be labelled ("Undo AI edit")
}

abstract class UndoHandler<E extends UndoEntry> {
  String get domain;
  /// Apply the inverse of [entry] as a new forward change; return the entry that would redo it.
  Future<E> undo(E entry);
  Future<E> redo(E entry);
}
```

`UndoService.replaceLast(step)` replaces the top undo step in place (used by follow-up
refinements of the last action, e.g. re-running *Split text to columns* with another
separator or changing a paste-special mode from the paste chip).

`UndoService` (in `wonky_app`) owns `undoStack`/`redoStack` per open document plus one
**shell stack** for drive operations, exposes `canUndo/canRedo/undoLabel/redoLabel` as
`ValueListenable`s, and exposes `beginTransaction(label)` / `commit()` / `rollback()`.

The dispatcher's transaction is **scoped to the command's async call chain**
(`beginTransaction(scoped: true)` + `runInTransaction`, a forked zone): `currentTransaction`
returns it only for code running in that chain (and for sync stream listeners it notifies, so
Write's local-change listener records into it). A keystroke or another command that runs while
a command awaits (a long sort, a data job, an agent command) records its own step, and a
failing command's rollback only reverts its own entries. Undo, redo and `undoTo` are
**queued**: each starts after the previous one finished (a held ⌘Z) and picks the top step
only then; the step stays on its stack until its handlers ran. When a handler throws (other
than `UndoConflict`), the entries not applied stay undoable, those applied go to redo (both
marked partial), and the error surfaces.

### 3.3 Domain strategies

| Domain | Entry content | Undo action | Rebase on remote change |
|--------|---------------|-------------|-------------------------|
| `write.content` | Inverse Quill Delta of the local change | Submit the inverse delta as a new local op | `inverse = remoteDelta.transform(inverse, priority)` (OT transform; see Write sync spec) |
| `write.meta` | `{field, before, after}` for title/theme/page setup | Write `before` via endpoint | If server value ≠ `after` (someone else changed it), entry is dropped (no-op) |
| `write.theme` | Theme JSON before/after | Save theme `before` | Same as `write.meta` |
| `sheets.rows` (RevLog rows) | List of `{table, rowId, op: insert/update/delete, columnsBefore, columnsAfter}`, plus the plan's `groupId` | Apply the inverse to the model and append it to the outbox, naming only those columns ([17](17-revlog-sync.md) part 6 §1). If the server rejects the plan's group, the entry is removed (or made inert when buried, 17 part 6 §4.6) | Per column: if current value ≠ `after`, that column is skipped ("someone else changed it"). If all columns skipped, the entry is a no-op |
| `sheets.serverChange` | `{changeId}` of a change executed server-side on the user's behalf (version restore, server import, AI/MCP loops) | `SheetsEndpoint.revertChange(changeId)` (redo: `reapplyChange`): the server inverts the applied forms of the record's op group (`rev_op` with its `recordId`, `before` values included) with the per-column skip rule and submits the result as a new server change (17 part 5 §8.2) | Server-side, same rule as `sheets.rows` |
| `slides.rows` (v2) | Same shape as `sheets.rows` over the Slides tables (generic `UndoInverter` from `wonky_revlog`) | As `sheets.rows`, through the deck session's outbox | Per-column skip rule as `sheets.rows` ([Slides 02](wonky_slides/02-data-model.md)) |
| `slides.serverChange` (v2) | `{changeId}` of a server-executed Slides change (version restore, MCP/AI) | `SlidesEndpoint.revertChange` / `reapplyChange`, from the record's ops as for Sheets | Server-side, same rule |
| `drive` | `{itemId, op, before, after}`; (v2) `{op: upload, itemUuids}` for an upload batch | Call drive endpoint with `before`; (v2) upload: `drive.trash(itemUuids)` (redo: `restore`) | Same as `write.meta`; items deleted forever meanwhile are skipped |
| `comments` | Comment snapshot | Restore/delete/edit via endpoint | Drop if the thread was deleted |

When an undo step becomes **partially** no-op due to remote changes, the UI shows a toast:
*"Some changes couldn't be undone because they were edited by someone else."*

### 3.4 MCP and AI integration

- MCP tool calls and AI actions run through the dispatcher, so their changes land on the
  **acting user's** undo stack, labelled with the source ("Undo AI: Rewrite paragraph").
- A single MCP tool call = one undo step, even if it touches many cells/blocks.
- MCP exposes `ui.undo`/`ui.redo` (live session) and the headless `write.undo`/`sheets.undo`
  (v2: `slides.undo`) are **not** offered (headless tools have no client stack). Instead headless tools return a
  `changeId`, and headless `*.revert_change(changeId)` reverts that change using the same
  server-side record (24 hours; Sheets and Slides: the record's RevLog ops, 17 part 5 §8.2).

### 3.5 Edit menu contract (all editors)

| Item | Shortcut | Notes |
|------|----------|-------|
| Undo *label* | Mod+Z | Disabled when stack empty |
| Redo *label* | Mod+Shift+Z, Mod+Y (Win/Linux) | |
| Cut / Copy / Paste | Mod+X / C / V | |
| Paste without formatting | Mod+Shift+V | |
| Select all | Mod+A | |
| Delete | Del | |
| Find and replace | Mod+H (Mod+Shift+H on macOS web) | |

A **History** popover (click-and-hold the Undo toolbar button, or *Edit › Undo history…*) lists
the last 50 steps with labels and timestamps; clicking a step undoes everything above it (one
undo per step, executed in order).

---

## 4. Testing requirements

- Every command has a unit test that runs `execute` then `undo` then `redo` and asserts state
  equality (structural equality of document/rows, and selection).
- **Sweep (as built, CQ-54).** `sweepCommands` (`wonky_app/testing.dart`) runs every registered
  command of a namespace on a fresh fixture (arguments sampled from its schema, or given per id)
  and checks: a recorded step changed the document, undo restores it and redo restores the change;
  nothing changes the document without an undo step or after failing; one invocation records at
  most one step. Commands that need a dialog, the platform or other arguments are reported as not
  run; commands that change the document without a step by design are listed with the reason
  (`noUndoStep`: creating a file, *Available offline*, the lazily created Sheets script project).
  One test per app: `wonky_app/test/commands/shell_command_sweep_test.dart` (`shell.*`),
  `wonky_write/test/features/commands/command_sweep_test.dart`,
  `wonky_sheets/test/commands/command_sweep_test.dart`,
  `wonky_slides/test/commands/command_sweep_test.dart`,
  `wonky_drive/test/commands/command_sweep_test.dart`, each with a floor of fully round-tripped
  commands (raise it when adding fixture arguments). The per-command tests above stay where a
  command needs a richer fixture or checks the selection.
- Property test for Write: random local+remote op sequences; after undoing all local steps, the
  document equals "initial + remote ops only".
- Property test for Sheets: random edits from two simulated clients; undo of client A never
  modifies a column last written by client B.

---

## 5. Shell command catalog (shared by all apps)

Canonical ids for commands implemented in `wonky_app` (apps may only *contribute behavior*
through the active document controller, never re-register these ids):

| Area | Command ids |
|------|-------------|
| Navigation | `shell.nav.home`, `shell.nav.back`, `shell.nav.forward`, `shell.nav.quickSwitcher`, `shell.nav.commandPalette`, `shell.focus.nextRegion`, `shell.focus.previousRegion`, (v2) `shell.nav.openInDrive {folderUuid?}` (app homes: the same folder in Wonky Drive) |
| File | `shell.file.new {kind}` ((v2) kind adds `presentation`; from another app it navigates to that app's `/new`), `shell.file.newFromTemplate`, `shell.file.open`, `shell.file.import`, `shell.file.print`, `shell.file.download {format}`, `shell.file.details` |
| Drive | `shell.drive.newFolder` (an explicit `parentUuid: null` is My Drive's root; the Move dialog's *New folder* uses it), `shell.drive.rename`, `shell.drive.setDescription {description}` (the details panel's field; undo domain `drive`), `shell.drive.move`, `shell.drive.copy`, `shell.drive.addShortcut`, `shell.drive.setStarred`, `shell.drive.togglePinnedOffline`, `shell.drive.trash`, `shell.drive.restore`, `shell.drive.deleteForever`, `shell.drive.emptyTrash`, `shell.drive.upload` ((v2) in Drive: upload arbitrary files, undoable batch; in app homes: *Import file…* of the app's convertible types) |
| Sharing | `shell.sharing.open`, `shell.sharing.copyLink`, `shell.sharing.requestAccess` |
| Edit | `shell.edit.undo`, `shell.edit.redo`, `shell.edit.undoHistory`, `shell.edit.undoTo {stepIndex}`, `shell.edit.cut`, `shell.edit.copy`, `shell.edit.paste`, `shell.edit.pasteWithoutFormatting`, `shell.edit.selectAll` |
| Comments | `shell.comments.create`, `shell.comments.reply`, `shell.comments.resolve`, `shell.comments.reopen`, `shell.comments.delete`, `shell.comments.activate {threadUuid}`, `shell.comments.togglePanel` (show through the app's `CommentsHost` when set, else the comments side panel; suite 07 §2.3) |
| Versions | `shell.versions.open`, `shell.versions.togglePanel`, `shell.versions.nameCurrent`, `shell.versions.restore {versionId}` |
| Panels | `shell.panels.open {panelId}`, `shell.panels.close {panelId}`, `shell.panels.toggle {panelId}` (in the editors, closing collapses the panel to the icon rail, suite 02 §4.5) |
| MCP | `shell.mcp.copyConnectionInfo`, `shell.mcp.toggleUiBridge`, `shell.mcp.stopControl` |
| View | `shell.view.zoom {percent}` (the editor chrome is always shown: no compact mode, full screen or show/hide toggles for toolbar, menubar or status bar) |
| Appearance & settings | `shell.appearance.setTheme {mode}`, `shell.settings.open {section}` (Wonky Work settings; legacy sections `write`/`sheets`/`themes` map to app settings, 04 §4.1), (v2) **`shell.settings.openApp {section?}`** (the current app's settings, `Mod+,` on desktop) |
| AI | `shell.ai.togglePanel`, `shell.ai.newThread`, `shell.ai.send`, `shell.ai.stop` |
| Help | `shell.help.shortcuts`, `shell.help.whatsNew`, `shell.help.about`, (v2) `shell.help.reportBug` and `shell.help.feedback`: since M12 **aliases of `shell.board.report`** (kind Bug, resp. the dialog's own choice; hidden from the palette; ids never change; with `board: false` the GitHub issue link of 03 §3.4) (no help center or menu search) |
| Board (M12) | `shell.board.report {kind?, includeError?}`, `shell.board.open {tab?}` (open the dialog / the board; not undoable); `shell.board.createPost` (the report dialog posts through it), `editPost`, `deletePost`, `vote {postNumber, value}`, `comment.add`, `comment.edit`, `comment.delete`, `flag`, `claim`, `release` (undoable, shell stack, undo domain `board`, server inverse); `removeScreenshot`, `copyClaimCode`, `copyPrompt` (not undoable); **`shell.board.admin.*`** (`moderate`, `setLabels`, `editPost`, `applySuggestedTitle`, `merge`, `unmerge`, `decline`, `reopen`, `block`, `createTask`, `updateTask`, `setTaskPosts`, `regeneratePrompt`, `setPrompt`, `publishTask`, `linkPullRequest`, `markDone`, `markShipped`, `cancelTask`: undoable; `suggestBundles`, `dismissSuggestion`, `dismissDuplicate`: not undoable; registered for everyone, enabled only for board admins). `requiredRole: viewer`. Catalog and undo inverses: [16 §14](16-bugs-and-improvements.md) |
| Account | `shell.account.signOut`, `shell.account.switchApp {app}` ((v2) `app` ∈ `drive`, `write`, `sheets`, `slides`; the left menu's app links) |
| Storage (v2) | `shell.storage.open` (Drive's Storage page: in-app in Drive, same-tab cross-app navigation to `/drive/storage` elsewhere; meters, banners, *Manage storage* buttons) |

## 6. App command namespaces (v2)

| Namespace | Registered by | Canonical list | Undo domains |
|-----------|---------------|----------------|--------------|
| `write.*` | `wonky_write` | [Write 04 §40](wonky_write/04-editor.md), [Write 05](wonky_write/05-screens-menus-toolbar.md) | `write.content`, `write.meta`, `write.theme` |
| `sheets.*` | `wonky_sheets` | [Sheets 04](wonky_sheets/04-screens-menus-toolbar.md) | `sheets.rows`, `sheets.serverChange` |
| `drive.*` | `wonky_drive` | [Drive 04 §9](wonky_drive/04-screens-menus.md): `drive.upload.*` (`folder`, `files`, `cancel`, `cancelAll`, `retry`, `retryAll`, `clearFinished`, `togglePanel`), `drive.file.*` (`preview`, `openWith`, `download`, `uploadNewVersion` P2, `manageVersions` P2), `drive.preview.*`, `drive.view.*`, `drive.prefs.set` | `drive` (shell stack) |
| `slides.*` | `wonky_slides` | [Slides 04](wonky_slides/04-screens-menus-toolbar.md) (canonical menu registry), [Slides 03](wonky_slides/03-editor-canvas-and-objects.md), [06](wonky_slides/06-animations-and-transitions.md), [07](wonky_slides/07-code-blocks.md), [10](wonky_slides/10-presenting-and-pdf.md) | `slides.rows`, `slides.serverChange` |

Rules: an app registers only its own namespace; `shell.*` ids are reserved for `wonky_app`;
command ids never change once shipped (MCP clients depend on them). Commands of another app
are not available (the palette's *Go to …* rows navigate instead).
