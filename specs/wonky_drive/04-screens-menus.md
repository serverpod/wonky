# Drive 04 · Screens, Menus and Commands

The Wonky Drive UI: the left menu shared by all homes (Drive variant), the Drive home with
all kinds, grid/list views, details panel, multi-select, drag-and-drop, the upload panel, the
file preview screen, the Storage page and Drive settings — with their commands, keyboard map,
light/dark and responsive rules. Shared drive widgets stay in `wonky_app`
(`lib/src/drive/`); Drive-only screens live in the `wonky_drive` app (05 §2).

## 1. Conventions and screen inventory

Routes are relative to `/drive/` (suite 03 §2). "Shell" means `packages/wonky_app`.

| Route | Screen | Class (package) | Notes |
|-------|--------|-----------------|-------|
| `/` | Home: suggested + recent, all kinds | `DriveHomeScreen` (shell) with `DriveAppConfig.homeScope = all` | §3 |
| `/my-drive` | My Drive (root folder) | shell | §3 |
| `/f/:folderUuid` | Folder | shell | v2 route (was `/drive/:folderUuid`; the old path redirects) |
| `/shared`, `/recent`, `/starred`, `/trash` | Drive views | shell | |
| `/search?q=&type=&owner=&modified=` | Search results | shell | §3.2 |
| `/storage` | Storage page | `StorageScreen` (`wonky_drive`) | §7, [03 §6.4](03-storage-quota.md) |
| `/file/:uuid` | File preview | `FilePreviewScreen` (`wonky_drive`) | §6; `DriveAppConfig.itemPath` |
| `/templates` | Template gallery with tabs Documents / Spreadsheets / Presentations | shell | creating navigates to the app (§5) |
| `/settings/:section`, `/settings/app` | Wonky Work settings, Drive settings | shell | §8, suite 04 §4 |
| `/invite/:token`, `/no-access` | Share-link landing, no access | shell | |

There is no *Offline* view in Drive: on-device availability belongs to each app (its local
cache; for Sheets and Slides the RevLog client's `RevOfflineProvider`, [17](../17-revlog-sync.md)
part 6 §7.1); Drive shows the *Make available offline* pin badge and command (suite 05 §4).

## 2. Left menu (`HomeSidebar`, shell — all homes)

`HomeSidebar` (shell, replaces `DriveSidebar`; width 256 px) is the same widget in every home
and is configured by the app (`WonkyAppConfig.homeNav`, suite 03 §3.3). Drive variant:

```
┌──────────────────────────────┐
│ [▣] Drive                ●   │  ← app section: product icons (18 px), current app highlighted
│ ──────────────────────────── │     (sidebarAccent pill), click = shell.account.switchApp {app}
│ [▣] Write                    │
│ [▣] Sheets                   │
│ [▣] Slides                   │
│ ──────────────────────────── │
│ [ + New ]                    │  ← New menu (§3.1; Drive only)
│ ⌂  Home                      │
│ ▤  My Drive              ▸   │  ← chevron toggles the lazy folder tree (drop targets)
│      ▸ Finance               │
│      ▸ Team                  │
│ 👥 Shared with me            │
│ 🕘 Recent                    │
│ ☆  Starred                   │
│ 🗑 Trash                     │
│ ◔  Storage                   │
│                              │  ← flexible space
│ ──────────────────────────── │
│ ⚙  Drive settings            │  → /settings/app            (shell.settings.openApp)
│ [▣] Wonky Work settings     │  → /settings/account        (shell.settings.open)
│ 💬 Bugs & improvements       │  → report dialog            (shell.board.report)
│ ▬▬▬▬▬▬▬▬▬▬░░░░               │
│ 12.3 MB of 50 MB used        │  ← StorageMeter (Drive 03 §6.1) → /drive/storage
└──────────────────────────────┘
```

- **App section**: four rows (32 px, product icon + "Write" / "Sheets" / "Slides" / "Drive",
  short names without "Wonky"); the current app's row is highlighted and not clickable
  (`Semantics(selected: true)`). Other rows navigate in the same tab to that app's home
  (`/write/`, …). Section semantics label "Apps". Order is fixed: Drive, a divider, then Write, Sheets,
  Slides (the order of `WonkyAppKind`, also used by the account menu's *Open app*; v2 review B4).
- ***+ New***: only in Drive (and v1 homes). The app homes (Write, Sheets, Slides) have no *+ New*
  in the left menu: they create from the template strip's large *Blank* card (and the template
  gallery); importing stays reachable as `shell.drive.upload` (⇧U, command palette).
- **Navigation** (Drive): Home, My Drive (+ tree), Shared with me, Recent, Starred, Trash,
  Storage. App homes use their own list (suite 03 §3.3).
- **Bottom section** (pinned to the bottom, scrolls with the menu when the window is short):
  *Drive settings* (`settings` icon; app homes: *Write settings*, *Sheets settings*, *Slides
  settings*), *Wonky Work settings* (Work product icon), *Bugs & improvements* (M12, Lucide
  `messageSquarePlus`; opens the report dialog, suite 16 §4.2; replaced *Report a bug*), then the `StorageMeter`.
- Drop targets: *My Drive* (and tree nodes) accept dragged items (move) and OS files (upload
  into that folder); *Trash* accepts dragged items (P1, trash; undoable).
- Collapsing: the top bar's ☰ collapses the menu (state per device); below `md` it becomes a
  drawer (`ShadSheet`, left) opened by ☰. While the menu is collapsed (or a drawer), Drive's
  top bar shows *+ New* (outline button, icon only below 640 px; same New menu) between the
  logo and the search field.

## 3. Drive home

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ [☰] [▣] Drive   [ 🔍 Search in Drive…                                ] [◐] [🔔] [👤] │ ← WonkyTopBar
├──────────────┬───────────────────────────────────────────────────────────────────────┤
│ (left menu)  │ My Drive › Team ▾                                         [⊞|☰] [ⓘ]   │ ← breadcrumb + layout/details
│              │ Type ▾  People ▾  Modified ▾  Sort: Name ▾                             │ ← filter bar
│              │ ───────────────────────────────────────────────────────────────────── │
│              │ Name                        Owner     Last modified   File size    ⋮   │
│              │ ▸ 📁 Designs                 me        Oct 2           —            ⋮   │
│              │ 📄 Q3 planning              me        10:42           24 KB        ⋮   │
│              │ 📊 Budget 2026              Anna B.   Yesterday       1.2 MB       ⋮   │
│              │ 🖼 holiday.jpg              me        Sep 30          3.4 MB       ⋮   │
│              │ ◌ 42% interview.m4a         me        uploading…      18.0 MB      ✕   │
│              │                                                                         │
│              │                                          ┌ Uploading 2 items ─── ˅ ✕ ┐ │
│              │                                          │ interview.m4a   ◌ 42 %  ✕ │ │ ← upload panel (§4)
│              │                                          │ notes.pdf       ✓          │ │
└──────────────┴──────────────────────────────────────────└──────────────────────────────┘
```

- **Top bar** (`WonkyTopBar`): Drive logo + "Drive" (→ Home), search (all kinds), app theme
  toggle, notifications, account menu (suite 03 §3.3). No upload button in the bar (New menu,
  drag-and-drop).
- **Header row**: breadcrumb (`ShadBreadcrumb`; segments are drop targets; the last segment
  opens a folder menu: New folder, Upload files, Rename, Share, Move, Download (P1), Trash),
  layout toggle (grid/list, `drive.view.setLayout`), details toggle (`shell.file.details`).
- **Home view**: a *Suggested* strip (up to 6 cards of recently opened items of any kind, with
  thumbnails) above the *Recent* list (sticky Today / Yesterday / Earlier this week / Earlier
  headers). No template strip (that belongs to the app homes); *New ▸ From template* opens
  the gallery.
- **Trash**: banner "Items in the trash are deleted forever after 30 days. They count
  against your storage until then." + *Empty trash*.

### 3.1 New menu (`+ New`)

| Item | Command | Notes |
|------|---------|-------|
| New folder | `shell.drive.newFolder` | Inline name dialog; undoable |
| — | | |
| File upload | `shell.drive.upload` | Picker (multi-select) → upload queue (02 §3) |
| Folder upload (P1) | `drive.upload.folder` | Directory picker (web: `webkitdirectory`; desktop: `file_picker` directory) |
| — | | |
| Document | `shell.file.new {kind: document}` | Navigates to `/write/new?folder=<uuid>` (§5) |
| Spreadsheet | `shell.file.new {kind: spreadsheet}` | `/sheets/new?folder=<uuid>` |
| Presentation | `shell.file.new {kind: presentation}` | `/slides/new?folder=<uuid>` |
| From template… | `shell.file.newFromTemplate` | `/templates` gallery, kind tabs |

The same entries appear in the empty-area context menu of the list (plus *Paste*, P1, and
*View ▸ Grid/List*, *Sort ▸*).

### 3.2 Search

- The top-bar field searches **all kinds** (`drive.search` with `kinds: null`); the suggestion
  dropdown shows matching items with kind icons (files: category icons), recent searches and
  chips *Type* (Folders, Documents, Spreadsheets, Presentations, Files ▸ Images / PDFs / Text &
  code / Audio / Archives / Other), *Owner*, *Modified*.
- Results page `/search?q=…` uses the filter bar with the same chips; uploaded files match on
  name (and on the first 64 KB of text files, `searchText`, P1).

### 3.3 Filter bar, layouts, sorting

- Chips: **Type** (as above; in a folder it filters children), **People** (Anyone / Owned by
  me / Not owned by me / a specific person, P1), **Modified** (Today, Last 7 days, Last 30
  days, This year, Custom range, P1), **Sort** (Name, Last modified, Last modified by me, Last
  opened by me, File size; asc/desc; *Folders on top* toggle).
- **List** (`DriveItemList`): columns Name (kind icon, name, shared badge, star, offline pin
  badge, upload progress), Owner, Last modified, File size (counted size, 03 §2), ⋮. Column
  header click sorts. Resizable Name column (P1).
- **Grid** (`DriveItemCard`): sections *Folders* (compact chips) then *Files* (cards with
  thumbnail 16:10 — image thumbnail, app thumbnail, else a category icon with
  the extension label — name, kind icon, ⋮). Card min width 200 px.
- Layout, sort and *Folders on top* persist per device (`drive.view.*` local prefs; defaults
  from Drive settings, §8).
- Virtualized, paged (100 per page, infinite scroll), live via `drive.watch`.

### 3.4 Selection and the action bar

- Click selects; `Mod`+click toggles; `Shift`+click selects a range; rubber band in grid and in
  the empty area of the list; `Mod+A` selects all loaded items; `Esc` clears.
- The **selection action bar** replaces the filter bar: count ("3 selected"), *Share* (single),
  *Download*, *Move*, *Make a copy*, *Star*, *Rename* (single), *Move to trash*, ⋮ (remaining
  item actions only: Open with ▸, Add shortcut, Make available offline, Details, Version history
  (Wonky items, single), Upload new version (file, single, P2)), *Clear* ✕.
- In Trash: *Restore*, *Delete forever* (confirm with count and freed size: "Delete 3 items
  forever? This frees 4.2 MB.").
- Mixed selections enable only actions every selected item allows (e.g. *Download* of a folder
  needs the ZIP download, P1).

### 3.5 Drag and drop

| Drag | Drop on | Effect |
|------|---------|--------|
| Items (list/grid/tree) | Folder row/card, tree node, breadcrumb segment, *My Drive* nav | Move (`shell.drive.move`, undoable); onto a folder shared with other people (P1): confirm "People with access to "Team" will get access to these items." |
| Items | *Trash* nav (P1) | Trash (undoable) |
| Items | Outside the window / onto the OS (desktop, P2) | — (not supported) |
| OS files | List / grid empty area | Upload into the current folder (My Drive on Home/Recent/Starred) |
| OS files | Folder row/card, tree node, *My Drive* | Upload into that folder |
| OS folders (P1) | Same | Folder upload (02 §3.1) |

- Drag chip: kind icon + name, or "5 items"; invalid targets (no Editor role, into itself or a
  descendant, uploading items) show the not-allowed state and don't highlight.
- OS drag over the content shows the **drop overlay** (dashed `ring`-colored border, centered
  "Drop files to upload to Team"); hovering a folder row highlights it ("Upload to Designs").
- Web: `DropTarget` via the HTML drop events (`package:web`); desktop (deferred, suite 01 A13): `desktop_drop` (already
  a shell dependency).

### 3.6 Details panel

Right panel (`WonkySplitView`, `rail: false`), toggled by `i` / `shell.file.details`:
thumbnail or preview (images: the preview image), name, type ("PNG image",
"PDF document", "Dart source", "Spreadsheet"), dimensions (images), size and
"Storage used" (03 §6.5), owner, location (breadcrumb, clickable), sharing summary + *Manage
access*, created / modified (by) / opened by me, description (editable, Editors+), *Open with*
(convertible files), *Manage versions* (P2), activity feed. Multi-selection: "3 items selected"
with total size.

### 3.7 Context menus

**Item** (right-click / ⋮; Wonky items as in suite 05 §3.1, files):

| Item | Command | Enabled |
|------|---------|---------|
| Preview | `drive.file.preview {uuid}` | file |
| Open with ▸ Wonky Write / Wonky Sheets | `drive.file.openWith {uuid, app}` | convertible file (02 §7.1), Viewer+ |
| Download | `drive.file.download {uuids}` | file; Wonky items: *Download as ▸ formats* (`shell.file.download`) |
| — | | |
| Share ▸ Share… / Copy link | `shell.sharing.open`, `shell.sharing.copyLink` | |
| — | | |
| Rename | `shell.drive.rename` | Editor+ |
| Move to… | `shell.drive.move` | |
| Add shortcut to My Drive | `shell.drive.addShortcut` | shared items |
| Star / Unstar | `shell.drive.setStarred` | |
| Make available offline | `shell.drive.togglePinnedOffline` | Wonky items |
| Make a copy | `shell.drive.copy` | storage permitting (03 §6.5) |
| Details | `shell.file.details` | |
| Upload new version… (P2) | `drive.file.uploadNewVersion {uuid}` | file, Editor+ |
| Manage versions (P2) | `drive.file.manageVersions {uuid}` | file |
| — | | |
| Move to trash | `shell.drive.trash` | |

In Trash: *Restore*, *Delete forever*.

### 3.8 Empty and loading states

| View | Illustration + text | Action |
|------|---------------------|--------|
| My Drive / folder | "Drop files here or use the New button" | *Upload files* |
| Shared with me | "Files others share with you appear here" | — |
| Starred | "No starred files yet" | — |
| Trash | "Trash is empty" | — |
| Search | "No results for "q"" + *Search tips* | *Clear filters* |
| Offline, not cached | "You're offline. Showing files saved on this device." | — |

Loading uses `LoadingShimmer` rows/cards (suite 02 §4.18).

## 4. Upload panel (`UploadPanel`, `wonky_drive`)

- Floating card, bottom-right (above toasts), 360 px wide, max 50 % of the window height,
  scrollable. Header: "Uploading 3 items · 2 min left" / "3 uploads complete" / "2 uploads
  failed", collapse ˅/˄, close ✕ (if uploads are running: "Cancel 2 uploads?" confirm).
- Rows: category icon, name (ellipsis middle), status (progress ring with percent, "Waiting for
  connection", "Queued", "Verifying…", ✓ "Uploaded", ⚠ "Not uploaded — you're out of storage",
  "Failed — network error"), row action: ✕ cancel (running/queued), ↻ retry (failed), 📂 show in
  folder (done; selects the item in its folder). Clicking a done row opens the preview.
- Footer (failures): *Retry all* · *Clear finished*.
- Collapsed: a pill "Uploading 3 · 42 %" (progress of the batch). The panel is a live region
  (polite) announcing "Upload of notes.pdf complete" / "… failed".
- State and actions are commands (`drive.upload.*`, §9), so MCP can read and drive it.

## 5. Opening items

| Kind | Open from Drive | Open from an app home |
|------|-----------------|-----------------------|
| Folder | `/drive/f/<uuid>` | `<app>/f/<uuid>` (filtered folder) |
| Document | `/write/d/<uuid>` (full page load, same tab) | same |
| Spreadsheet | `/sheets/s/<uuid>` | same |
| Presentation | `/slides/p/<uuid>` | same |
| File | `/drive/file/<uuid>` (in-app preview) | not listed; links go to Drive |

- **New** Wonky items from Drive navigate to the app's **`/new` route**
  (`/write/new?folder=<uuid>&template=<uuid>`, `/sheets/new?…`, `/slides/new?…`), which creates
  the item in that app (offline-first where the app supports it: client ids, and for
  Sheets/Slides the creation op in the RevLog outbox) and replaces the route with the editor.
  Drive itself never holds a Sheets or Slides cache.
- Back from an editor returns to the Drive location it was opened from (browser history).
- Cross-app navigation sets the `wonky_last_app` cookie only when an app home or editor is
  opened (it is informational in v2, suite 01 §2.4).

## 6. File preview screen (`/drive/file/:uuid`)

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ [←] 🖼 holiday.jpg          [Open with ▾] [⬇ Download] [Share] [☆] [⋮]  [ⓘ]  [✕] │ ← 48 px bar
├──────────────────────────────────────────────────────────────────────────────────┤
│ ‹                                                                              › │
│                               (viewer — 02 §6)                                   │
│                                                                                  │
├──────────────────────────────────────────────────────────────────────────────────┤
│      [−] 100 % [+]  [Fit]  [⟳]                 3 of 12 in "Holiday"              │ ← viewer bar (per type)
└──────────────────────────────────────────────────────────────────────────────────┘
```

- Top bar: back (`drive.preview.close`, returns to the previous location with the item
  selected; a preview opened by a link or after a reload returns to the file's folder), category icon, name (rename inline for Editors+, `DocumentTitleField`), *Open with*
  (convertible only), *Download* (hidden when export is not allowed), *Share*, star, ⋮ (Rename,
  Move to…, Make a copy, Details, Upload new version (P2), Move to trash), details toggle,
  close ✕ (same as back).
- `‹ ›` (and ←/→) step through the **ready files** of the list the preview was opened from
  (folder, search results, starred…), skipping folders and Wonky items; "3 of 12 in "Holiday"".
- Viewer bar per type: image (zoom −/+, %, Fit, 1:1, rotate), text (wrap toggle, language label, *Copy all*, line count),
  CSV (Table/Text toggle, P1), audio (P2 player in the body instead). PDFs have no viewer in v2
  (the *Download* card, 02 §6.3).
- Background: `canvas` token (dark gray in dark mode, light gray in light); code uses the light or dark code palette of `wonky_code`.
- The preview of a trashed file shows a banner "This file is in the trash" + *Restore*.

## 7. Storage page (`/drive/storage`)

Specified in [03 §6.4](03-storage-quota.md). Reached from the left-menu item *Storage*, every
`StorageMeter`, banners, dialogs (*Manage storage*), Settings › Wonky Work › Storage and
`shell.storage.open`.

## 8. Drive settings (`/settings/app`)

Shown in the settings frame's app group "Wonky Drive" (suite 04 §4). One section `drive`:

| Setting | Values (default) | Key in `UserPreferences.driveDefaults` |
|---------|------------------|----------------------------------------|
| Default layout | List / Grid (List) | `layout` |
| Default sort | Name / Last modified / … (Last modified) | `sortField`, `sortDescending` |
| Folders on top | on | `foldersOnTop` |
| Show file extensions | on | `showExtensions` (off hides the extension of `file` names in lists, never in dialogs or the preview title) |
| Ask when uploaded files have the same name | on | `askOnNameConflict` |
| Convert uploads to Wonky formats (P1) | off | `convertUploads` |
| Confirm before moving items into shared folders (P1) | on | `confirmSharedMoves` |

Each change is the command `drive.prefs.set {key, value}` (not undoable, suite 04 §4).

As built (D-17): `DriveSettingsSection` (`wonky_drive/lib/features/settings/`) has the groups
*Files list* (layout, sort field, sort order, folders on top, file extensions) and *Uploads*
(name conflicts, convert uploads); *Confirm before moving items into shared folders* waits for
its P1 confirm. Values are checked by `DriveSettings.validators` (`sortField` ∈ name, modifiedAt,
lastOpenedByMe, lastModifiedByMe, size). A new list default also clears this device's
remembered choice (`drive.view.layout`, `drive.view.sortField`, `drive.view.sortDescending`,
`drive.view.foldersOnTop` device keys) and applies to the shown list at once; the app homes keep
v1's unpersisted sort and the shared `drive.layout` key. *Show file extensions* off goes through
`WonkyAppConfig.listItemName` (list rows, grid cards, the Storage table).

## 9. Commands

Shared drive commands keep their `shell.drive.*` ids (suite 08 §5) and work in every home;
Drive-only commands use `drive.<area>.<action>` and are registered by `wonky_drive`.

| Command | Title | Args | Default binding (list scope) | Undoable |
|---------|-------|------|------------------------------|----------|
| `shell.drive.upload` | File upload… | `{parentUuid?}` | `Shift+U` | ✓ (batch, 02 §3.4) |
| `drive.upload.folder` (P1) | Folder upload… | `{parentUuid?}` | — | ✓ |
| `drive.upload.files` | Upload files (drop/paste handler) | `{parentUuid?, files}` (UI only; not in MCP) | — | ✓ |
| `drive.upload.cancel` | Cancel upload | `{uploadId}` | — | — |
| `drive.upload.cancelAll` | Cancel all uploads | — | — | — |
| `drive.upload.retry` | Retry upload | `{uploadId}` | — | — |
| `drive.upload.retryAll` | Retry failed uploads | — | — | — |
| `drive.upload.clearFinished` | Clear finished uploads | — | — | — |
| `drive.upload.togglePanel` | Show uploads | — | — | — |
| `drive.file.preview` | Preview | `{uuid}` | `Space`, `Enter` (files) | — |
| `drive.file.openWith` | Open with … | `{uuid, app: write\|sheets}` | — | — (creates an item through the app's import) |
| `drive.file.download` | Download | `{uuids}` (default: the open preview, else the selected files) | `Mod+Shift+D` | — |
| `drive.file.uploadNewVersion` (P2) | Upload new version… | `{uuid}` | — | ✓ |
| `drive.file.manageVersions` (P2) | Manage versions | `{uuid}` | — | — |
| `drive.preview.next` / `.previous` | Next / Previous file | — | `→` / `←` (preview scope) | — |
| `drive.preview.zoomIn` / `.zoomOut` / `.zoomFit` / `.zoomActual` | Zoom | — | `+` / `−` / `0` / `1` | — |
| `drive.preview.rotate` | Rotate view | — | `R` | — |
| `drive.preview.toggleWrap` | Wrap lines | — | `Alt+Z` (text) | — |
| `drive.preview.close` | Close preview | — | `Esc` | — |
| `shell.storage.open` | Manage storage (shell command, all apps) | — | — | — |
| `drive.view.setLayout` | Grid / List view | `{layout: grid\|list}` | — | — |
| `drive.view.sort` | Sort by … | `{field, descending}` | — | — |
| `drive.view.toggleFoldersOnTop` | Folders on top | — | — | — |
| `drive.prefs.set` | (settings) | `{key, value}` | — | — |
| `drive.storage.show` | Show storage | `{filter?: all\|documents\|spreadsheets\|presentations\|files\|trash\|large\|notOpened}` → `/storage?filter=` | — | — |
| `drive.ai.askAboutItem` (P1) | Ask the assistant about this file | `{uuid}` | — | — |

Shell commands used (unchanged ids): `shell.drive.newFolder` (`Shift+F`), `rename` (`F2`),
`move`, `copy`, `addShortcut`, `setStarred` (`S`), `togglePinnedOffline`, `trash` (`Del`),
`restore`, `deleteForever`, `emptyTrash`, `shell.file.new {kind}` (`Mod+Alt+N` = new document
in Drive), `shell.file.newFromTemplate`, `shell.file.details` (`i`), `shell.sharing.open`
(`.`), `shell.nav.home`, `shell.settings.open`, `shell.settings.openApp`,
`shell.board.report`, `shell.board.open`, `shell.account.switchApp {app}`, `shell.storage.open`,
`shell.ai.togglePanel` (Drive assistant, P1, suite 10 §3.1). App homes additionally use
`shell.nav.openInDrive {folderUuid?}`.

## 10. Keyboard map

| Scope | Keys |
|-------|------|
| Global (home) | `/` focus search · `Mod+O` quick switcher (all kinds) · `Mod+Shift+P` palette · `Mod+[` / `Mod+]` back/forward (desktop) |
| List / grid | arrows move focus · `Shift`+arrows extend · `Mod+A` select all · `Enter` open · `Space` preview (files) · `F2` rename · `Del` trash · `S` star · `.` share · `i` details · `Shift+F` new folder · `Shift+U` upload files · `Esc` clear selection |
| Preview | `←`/`→` previous/next · `+`/`−`/`0`/`1` zoom · `R` rotate · `Alt+Z` wrap · `Mod+C` copy (text selection, P1) · `Esc` close |
| Upload panel | `Tab` into the panel · arrows between rows · `Enter` activates the row action |

Single-key bindings are active only when focus is in the list, grid or preview (not in text
fields), as today.

## 11. Light and dark, responsive

- All Drive screens use shad tokens and `wonky_ui` widgets; thumbnails are rendered in the light
  theme (as documents' are) and shown on a `card` background with a 1 px `border` in dark mode.
- Category icons use the kind colors of `DriveKindIcon` (suite 02 §5), with distinct colors for
  files: image (violet), PDF (red), text/code (slate), audio (amber), video (pink), archive
  (brown), other (muted).
- Below `md`: left menu as drawer, details panel as overlay with scrim, list shows Name +
  ⋮ only, the upload panel spans the width minus 16 px, preview bars collapse secondary
  buttons into ⋮. Nothing overflows at 360 px.

## 12. Accessibility

- List rows: "holiday.jpg, PNG image, 3.4 MB, modified September 30, owned by me, starred".
- Upload progress: polite live region; the panel's buttons have labels ("Cancel upload of
  interview.m4a").
- Preview: image `Semantics(label: name + dimensions)`; text preview exposes the text.
- The storage meter has `Semantics(value: "12.3 MB of 50 MB used, 25 percent")`.

## 13. MCP exposure

- Every command above is reachable through `ui.invoke_command`; dialogs (*Upload options*,
  *Out of storage*, confirms) are `WonkyDialogSpec` dialogs.
- `ui.drive.*` (P1, `wonky_drive/lib/mcp/`): `ui.drive.get_selection`,
  `ui.drive.select_items {uuids}`, `ui.drive.get_upload_queue`, `ui.drive.open_preview {uuid}`,
  `ui.drive.get_preview_state` (type, zoom). Uploading bytes goes through headless
  `drive.upload_file` (suite 09 §4), not the bridge. As built (D-17, `UiDriveToolHandlers`): `get_selection`
  reports `view` (`home`, `my_drive`, `folder`, `shared`, `starred`, `recent`, `trash`,
  `search`, `storage` with its `filter`, or `preview`), the folder `{uuid, name, path}` and the
  selected items `{uuid, name, kind, file_category, size_bytes, trashed}`; `select_items` works
  on the shown list (home or Storage page), focuses the first item and returns `not_found`
  (`unavailable` when no list is shown); `get_upload_queue` lists `upload_id`, `item_uuid`,
  `state`, `sent_bytes`, `error`, `converted_to` and totals; `get_preview_state` adds
  `phase`, `fit`, `rotation`, `wrap`, `has_next/has_previous`.

## 14. Widget inventory (new)

| Widget | Package | Purpose |
|--------|---------|---------|
| `HomeSidebar`, `AppLinksSection`, `HomeSidebarFooter` | `wonky_app` | Left menu of every home (§2) |
| `StorageMeter`, `StorageBanner`, `QuotaExceededDialog`, `QuotaErrorPresenter` | `wonky_app` (`lib/src/storage/`) | Drive 03 §6 |
| `WonkyStackedBar` | `wonky_ui` | Stacked usage bar with legend (Storage page, settings) |
| `DriveKindIcon` (+ `FileCategory` variants) | `wonky_app` | Kind and file-category glyphs |
| `UploadQueue`, `UploadPanel`, `UploadDropOverlay`, `UploadOptionsDialog` | `wonky_drive` | §4, 02 §3 |
| `FilePreviewScreen`, `ImageViewer`, `TextFileViewer`, `CsvTableViewer` (P1), `AudioPlayerCard` (P2), `UnsupportedFileView` | `wonky_drive` | §6, 02 §6 |
| `StorageScreen` | `wonky_drive` | 03 §6.4 |
| `CodeView` | `wonky_code_flutter` | Read-only highlighted text (shared with Write and Slides) |

## 15. Acceptance criteria

- **AC-D4.1** The left menu shows the four apps (Drive, a divider, Write, Sheets, Slides) with
  Drive highlighted; *Sheets* opens
  `/sheets/` in the same tab; the menu in the Sheets home shows the same four rows with Sheets
  highlighted.
- **AC-D4.2** Drive lists folders, documents, spreadsheets, presentations and files together;
  the Type chip narrows to *Files ▸ PDFs*; grid shows image thumbnails.
- **AC-D4.3** Dragging 3 selected items onto a tree node moves them; `Mod+Z` moves them back.
- **AC-D4.4** Dropping 2 OS files onto a folder row uploads them into that folder with the
  overlay text "Upload to Designs"; the upload panel shows progress and completion.
- **AC-D4.5** `Space` on a PDF opens its preview (the *Download* card); `→` goes to the next file; `Esc` returns with
  the PDF still selected and focused.
- **AC-D4.6** *Bugs & improvements* in the left menu opens the report dialog (with `board: false`:
  the external-link confirm popover for github.com, suite 03 §3.4).
- **AC-D4.7** Every screen of this spec passes the golden matrix in light and dark and the
  360 px overflow check.
