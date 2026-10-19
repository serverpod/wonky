# 05 · Wonky Drive — Files, Folders, Homes

Wonky Drive is the one file system of the suite. It is implemented once in
`packages/wonky_app` (UI: home screen, list/grid, left menu, dialogs, details panel) and
`wonky_server/lib/src/platform/drive/` (server).

**(v2) One drive, many lenses** (decisions D2/D3):

- The **Wonky Drive app** (`wonky_drive`, `/drive/`) shows the full drive: folders, documents,
  spreadsheets, presentations and uploaded files, with folder management, uploads, previews and
  the Storage page. Its own specs are in [`wonky_drive/`](wonky_drive/README.md).
- Each **app home** (`/write/`, `/sheets/`, `/slides/`) shows **only its own kind** (no "show
  everything" toggle any more) and links to Drive for everything else (§3.2).
- Opening an item of another kind navigates to that kind's app URL (same origin; 01 §2.4). This
  is a full-page navigation **within the same browser tab/window** — never a new window.
- Every user has **50 MB** of storage, enforced on every byte-adding path
  ([Drive 03](wonky_drive/03-storage-quota.md)).
- The site root `/` lands on **Wonky Write's home** (`/write/`, v2 review Q2); Wonky Drive is one
  click away in the left menu of every home (01 §2.4).

## 1. Data model (server, Postgres — not synced)

```yaml
# drive_item.spy.yaml
class: DriveItem
table: drive_item
fields:
  uuid: UuidValue, defaultPersist=random_v7   # public id used in URLs: /d/<uuid>, /s/<uuid>, /p/<uuid>, /file/<uuid>
  kind: DriveItemKind                          # enum: folder, document, spreadsheet, presentation (v2), file (v2)
  name: String
  ownerId: int, relation(parent=user_profile, onDelete=Restrict)
  parentId: int?, relation(parent=drive_item, onDelete=SetNull)   # null = owner's root
  description: String?
  # Documents: document_id; spreadsheets and (v2) presentations: the RevLog file UUID
  # (= Spreadsheet.id / Deck.id = item uuid, 17 As built 2); files: StoredFile.fileUuid
  contentRef: UuidValue?
  thumbnailFileId: UuidValue?
  sizeBytes: int, default=0                    # (v2) counted content size: estimate or file size (Drive 03 §2)
  attachmentBytes: int, default=0              # (v2) images stored for this item, charged to its owner (Drive 03 §2)
  kindMask: int, default=0                     # (v2) folders: kinds contained recursively (§3.2)
  mimeType: String?                            # (v2) files only — and the fields below (Drive 02 §1.1)
  fileCategory: FileCategory?
  uploadState: FileUploadState?
  fileMetaJson: String?
  previewFileId: UuidValue?
  createdAt: DateTime
  createdById: int
  modifiedAt: DateTime                         # last content modification (any user)
  modifiedById: int?
  trashedAt: DateTime?
  trashedById: int?
  templateOf: TemplateCategory?                # non-null = this item is a template in the gallery
indexes:
  drive_item_uuid_idx: { fields: uuid, unique: true }
  drive_item_parent_idx: { fields: parentId }
  drive_item_owner_idx: { fields: ownerId, trashedAt }
  drive_item_content_idx: { fields: contentRef }
  drive_item_upload_idx: { fields: uploadState, createdAt }   # (v2) drive.expireUploads
```

```yaml
# drive_item_user_state.spy.yaml — per-user view state
class: DriveItemUserState
table: drive_item_user_state
fields:
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  starred: bool, default=false
  lastOpenedAt: DateTime?
  lastEditedAt: DateTime?
  pinnedOffline: bool, default=false          # keep available offline
  shortcutParentId: int?                      # "Add shortcut to My Drive" for shared items
indexes:
  drive_item_user_state_idx: { fields: itemId, userId, unique: true }
  drive_item_user_recent_idx: { fields: userId, lastOpenedAt }
```

Sharing tables (`DriveItemPermission`, `ShareLink`) are defined in
[06-sharing-and-permissions.md](06-sharing-and-permissions.md). (v2) Storage tables
(`UserStorage`, `StorageReservation`) are in [Drive 03 §4](wonky_drive/03-storage-quota.md);
`StoredFileKind` gains `driveFile` and `preview` ([Drive 02 §1.1](wonky_drive/02-files-uploads-previews.md)).

**(v2) Kinds.**

| Kind | App | Content | Created by |
|------|-----|---------|-----------|
| `folder` | Drive | — | `createFolder` |
| `document` | Write | `Document` + op log | `createDocument` (online/offline, client ids) |
| `spreadsheet` | Sheets | RevLog file (domain rows + op log, [17](17-revlog-sync.md)) | `registerSpreadsheet` (content written by the client, online/offline, client ids), or `createSpreadsheet` |
| `presentation` | Slides | RevLog file | `registerPresentation` (as for spreadsheets), or `createPresentation` ([Slides 02 §9.3](wonky_slides/02-data-model.md)) |
| `file` | Drive (preview) | `StoredFile` (`driveFile`) | `createFileUpload` + `completeFileUpload` ([Drive 02 §3](wonky_drive/02-files-uploads-previews.md)) |

Full-text search uses Postgres `to_tsvector('simple', …)`/prefix `to_tsquery` (plus `ILIKE` on
the name) over `name`, `description` and an extracted `searchText` field updated asynchronously
(document plain text, throttled; spreadsheet sheet names + first 10k cell values), restricted to
items the caller can access. The document expression has a GIN index and the name a `pg_trgm`
index (when the extension exists); both are created at server start by `SearchIndexes`, outside
the models, because Serverpod models cannot declare expression indexes and `definition.sql` must
stay the generated one (13 §3). **As built (CQ-25):** `list` and `search` run in SQL
(`DriveListing`): the view, visibility (owned, granted and not expired, or a link role; search:
link items only once opened), kind/owner/category/folder/date/shared filters and the sort are
in the query, pages are cut with an opaque keyset cursor (sort keys + id; search: rank, modified,
id; a cursor of another list or sort is refused with `invalidArgument`), and views are built for
the page only. Names sort by `lower(name)` in code-point order. The template gallery filters
visibility in SQL too.

## 2. Endpoints — `DriveEndpoint` (`drive`)

| Method | Description |
|--------|-------------|
| `list(folderUuid?, filter, sort, cursor, limit)` | Children of a folder or a virtual view. `filter`: `kind` set, `ownedByMe`, `sharedWithMe`, `starred`, `recent`, `trash`; (v2) `fileCategories` (files only), `foldersContaining` (a kind: folders are returned only if their `kindMask` has it, §3.2; app homes always pass it). Returns `DriveItemView` (item + effective role + user state + owner summary; v2: + the file fields and `countedBytes`). `uploading` files are returned only to their uploader. |
| `get(uuid)` | Single item view (404 if no access). |
| `path(uuid)` | Breadcrumb ancestors visible to the user. |
| `search(query, filters, cursor)` | Full-text + filters (type, owner, modified range, shared). |
| `createFolder(parentUuid?, name)` | |
| `createDocument(parentUuid?, name, templateUuid?, initialMarkdown?)` | Creates `DriveItem` + `Document` (see Write data model). |
| `registerSpreadsheet(spaceUuid, parentUuid?, name)` | Creates the drive item and the RevLog file for a spreadsheet created on a device (client-generated file UUID = item uuid) with `initialize: false`: the file stays at revision 0 and the client's queued creation op becomes revision 1 ([17](17-revlog-sync.md) part 4 §5). Idempotent on the UUID; works offline-first (queued as a `PendingDriveOp`); a parent folder that is gone or no longer writable falls back to My Drive. |
| `createSpreadsheet(parentUuid?, name, templateUuid?, locale?, timeZone?)` | Server-side creation (Drive's *New* online, MCP, AI, templates, welcome content): the server writes the template's or the default content as the file's first ops (`RevLogService.createFile`, 17 part 5 §8.3). |
| `registerPresentation(spaceUuid, parentUuid?, name)` · `createPresentation(parentUuid?, name, templateUuid?, fileUuid?, initialize?)` | (v2) As for spreadsheets; `createPresentation` with `fileUuid` is idempotent and with `initialize: false` leaves the file for the client's creation op ([Slides 02 §9.3](wonky_slides/02-data-model.md)). |
| `createFileUpload(request)` · `completeFileUpload(itemUuid)` · `cancelFileUpload(itemUuid)` · `fileUploadStatus(itemUuid)` | (v2) Uploads of `file` items, quota reservation ([Drive 02 §3](wonky_drive/02-files-uploads-previews.md)). |
| `fileContentUrl(itemUuid, download)` · `updateFileMeta(itemUuid, fileMetaJson)` · `convertFile(fileItemUuid, target, options)` | (v2) Preview/download URLs, client-measured metadata, *Open with* conversion (Drive 02 §6–§8). |
| `checkRoom(bytes, itemUuid?)` · `listByStorage(filter, cursor)` | (v2) Quota pre-check; owned items by counted size for the Storage page ([Drive 03](wonky_drive/03-storage-quota.md)). |
| `downloadZip(uuids, formats)` | (v2, P1) ZIP of several items (Drive 02 §8). |
| `rename(uuid, name)` · `move(uuids, newParentUuid?)` · `copy(uuid, newName, parentUuid?, copyComments, copySharing)` | |
| `setStarred(uuid, starred)` · `setPinnedOffline(uuid, pinned)` | |
| `trash(uuids)` · `restore(uuids)` · `deletePermanently(uuids)` · `emptyTrash()` | Trash auto-purges after 30 days (FutureCall `drive.purgeTrash`, daily). |
| `watch()` | **Stream** of `DriveChange` events for items visible to the user (created/renamed/moved/trashed/shared/modified) so lists update live. (v2) Also `storageChanged` with the caller's new `StorageUsage` (Drive 03 §3). |
| `listTemplates(kind)` | Template gallery: `TemplateView`s of the built-in templates (compiled into the server, stable UUIDv5 ids `wonky-template:<key>`) plus items published with `setTemplate(uuid, category)`. A `TemplateView` carries `themeKey` (the built-in Write theme a document template creates its document with) and `previewStyle` (`TemplatePreviewStyle`: `paper`/`text`/`heading`/`accent` colors for light and dark, `banner`, `centeredHeadings`, `uppercaseHeadings`, `fontCategory` serif/sans/mono; null = neutral page) for the card's miniature page (§3.1). |
| `import(uploadId, kind, options: DriveImportOptions)` | Server-side import pipeline (see each app's import spec) returning the new item. (v2) Checks the quota (Drive 03 §7.2). |
| `storageUsage()` | (v2) `StorageUsage`: quota, counted usage incl. trash, reservations, breakdown by kind ([Drive 03 §3](wonky_drive/03-storage-quota.md)). |
| `setThumbnail(uuid, uploadedFileUuid)` | Clients render thumbnails (first page / visible grid area, light theme, 400×300 PNG) at most every 10 min while editing and upload them; Editors+ only. |

Server rules:
- (v2) Every byte-adding method checks the storage quota of the user it charges and throws
  `quotaExceeded` ([Drive 03 §7](wonky_drive/03-storage-quota.md)); editing content never does.
- Moving into a folder requires Editor on the target folder and Owner/Editor on the item.
- Cycles are rejected (`DriveException.cycle`).
- Names: 1–255 chars, trimmed, no `/`; duplicates allowed (like Google Drive).
- Trashing a folder trashes descendants (same `trashedAt`); restore restores them together.

## 3. Homes

### 3.0 Wonky Drive vs app homes (v2)

| | Wonky Drive (`/drive/`) | App home (`/write/`, `/sheets/`, `/slides/`) |
|-|-------------------------|-----------------------------------------------|
| Kinds | all | the app's kind only (no type toggle) |
| Folders | all, with tree and drag-and-drop moves, *New folder* | only folders containing the kind (§3.2), as navigation; *Open in Wonky Drive* |
| New | folder, document, spreadsheet, presentation, upload, template | the app's kind, template strip |
| Uploads | any file ([Drive 02](wonky_drive/02-files-uploads-previews.md)) | *Import file…* of the app's convertible types |
| Views (left menu) | Home, My Drive, Shared with me, Recent, Starred, Trash, Storage | Recent, My files, Shared with me, Starred, Offline, Trash |
| Spec | [Drive 04](wonky_drive/04-screens-menus.md) | this section + the app's screen spec |

Both are the same shell screen (`DriveHomeScreen`) configured by `WonkyAppConfig.homeScope`
(03 §3.3). The layout below is an app home (Write); Drive's is in Drive 04 §3.

### 3.1 Layout (app home, v2)

Single-window page at `/` of each app — layout:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [≡] [◆] Write    [ 🔍 Search documents…                       ]  [◐] [🔔] [👤] │  ← TopBar
├────────────────┬─────────────────────────────────────────────────────────────┤
│ ▣ Wonky Drive  │  Start a new document                                        │
│ ▣ Wonky Write ●│  [Blank] [Meeting notes] [Project brief] [Letter] [More ▸]   │ ← Template strip
│ ▣ Wonky Sheets │─────────────────────────────────────────────────────────────│
│ ▣ Wonky Slides │  Recent                          [▣ Open in Wonky Drive]     │ ← header row
│ ───────────    │  Owned by anyone ▾   Sort ▾   [▦|☰]                           │ ← Filter bar
│ + New          │  Name                 Owner      Last modified     ⋮         │
│ 🕘 Recent      │  📄 Q3 planning       me         10:42             ⋮         │
│ ▤ My files     │  📄 Notes             Anna B.    Yesterday         ⋮         │
│ 👥 Shared      │  …                                                           │
│ ☆ Starred      │                                                              │
│ ⇩ Offline      │                                                              │
│ 🗑 Trash        │                                                              │
│ ───────────    │                                                              │
│ ⚙ Write sett…  │                                                              │
│ ▣ Wonky Work… │      (bottom section: Write settings, Wonky Work settings,  │
│ 💬 Bugs & Impr.│       Bugs & improvements, storage meter "12.3 MB of 50 MB used")   │
│ ▬▬▬░ 12.3/50 MB│                                                              │
└────────────────┴─────────────────────────────────────────────────────────────┘
```

### 3.2 Components
- **TopBar** (shared `WonkyTopBar`): hamburger (collapses sidebar), app logo (the product icon,
  suite 02 §5) + short name ("Write" / "Sheets"; click → home), drive search field (while the
  sidebar is open it starts where the page content starts — sidebar 256 px + the 20 px content
  inset, `WonkyTopBar.contentStart` — so it lines up with "Start a new document" / "Home") with
  suggestions dropdown (recent
  searches, matching items with their kind icons, "Search for '…'" row, filter chips: type,
  owner, modified), app theme toggle (light/dark/system cycle), notifications, account avatar
  menu (name, email, (v2) *<App> settings*, *Wonky Work settings*, *Open ▸* Drive / Write /
  Sheets / Slides with the product icons, Sign out). There is no help button (Help lives in the
  editor's Help menu and *Bugs & improvements* (M12, was *Report a bug*) in the left menu; there is no help center). (v2) In app
  homes the search is filtered to the app's kind; its dropdown ends with "Search all of Wonky
  Drive for '…'" (→ Drive's search, same tab).
- **Left menu** (v2: `HomeSidebar`, replaces `DriveSidebar`; 03 §3.3, Drive 04 §2): app section
  (four apps), *New* button (12 px left of the +; app homes: New <kind> / From template…), the
  app's nav items (app homes: Recent, My files, Shared with me, Starred, Offline, Trash — no
  folder tree), bottom section (*<App> settings*, *Wonky Work settings*, *Bugs & improvements*,
  storage meter "12.3 MB of 50 MB used").
- **(v2) Folder rule in app homes.** A folder appears in an app home only if it contains —
  recursively, ignoring trashed items — at least one item of the app's kind. The server keeps
  `DriveItem.kindMask` per folder (bit per kind; updated for all ancestors on create, register,
  move, trash, restore and delete of a non-folder item, in the same transaction; a nightly job
  recomputes masks) and `list(filter.foldersContaining: k)` returns only folders whose mask has
  `k`. The mask ignores per-user access (a folder whose only document you can't see may show
  and open empty). (Decided in the v2 review, Q7; 03 §3.3.) Moving between folders, creating folders and
  uploads happen in Drive (header-row button **Open in Wonky Drive** → the same folder in
  Drive); the per-item *Move to…* dialog stays in app homes and editors.
- **Template strip** (not in the mobile layout, suite 02 §6.1, T-12): collapsible ("Hide
  templates"), 20 px horizontal padding (matching the list
  header), horizontal list of `TemplateCard`s; *More*
  opens the template gallery page (`/templates`) with categories (Personal, Work, Education,
  Project management, Finance for Sheets…). A card draws a **miniature page** in the template's
  `previewStyle` (paper, text, heading and accent colors for the current app theme; accent
  banner, centered or uppercase headings, serif/sans/mono character), clipped to the card (no
  scroll view, so no scrollbar on hover). Each built-in document template creates its document
  with its own built-in Write theme and sample content: Meeting notes → *modern-sans* (banner),
  Project brief → *technical*, Letter → *classic-serif* (centered letterhead), Weekly report →
  *newsletter* (accent headings), Lecture notes → *academic-apa* (centered), To-do list →
  *minimal-mono*, Recipe → *wonky-default* (banner), Story draft → *manuscript* (centered
  uppercase). Spreadsheet templates have an accent color for their card. (v2) Presentation
  templates (Slides 04 §15) have slide-shaped (16:9, 1.4× wider) cards: the app may supply
  the picture (`WonkyAppConfig.templatePreview`; Wonky Slides renders the first slide),
  otherwise a title-slide miniature in the Slides theme's colors (`previewStyle` from the
  theme, `previewText` = title and subtitle of the first slide). Clicking a card
  immediately disables the card and shows a loading spinner (`ShadSpinner`) to prevent
  duplicate creations from rapid clicks (T-7); if creation fails, the card re-enables
  and the spinner is hidden.
- **Filter bar**: view selector (Recent/Last opened by me/Last modified by me/Last modified),
  owner filter, grid/list toggle, sort menu (Name, Last modified, Last opened by me, Size;
  asc/desc), folders-on-top toggle. (v2) The type filter (Documents, Spreadsheets, Folders,
  All) exists only in Drive, with presentations and file subtypes (Drive 04 §3.3). In the
  mobile layout (T-12) there is no grid/list toggle: phones always show the list, and a grid
  chosen on the desktop stays saved for wider windows.
- **Item list** (`DriveItemList`, list mode): columns Name (kind icon, name, shared badge, star,
  offline badge), Owner (avatar+name / "me"), Last modified (relative), File size, row ⋮ menu.
  Grid mode: `DriveItemCard` with thumbnail preview, name, kind icon, ⋮ menu. Kind icons are
  `DriveKindIcon` (suite 02 §5: plain glyphs in the kind colors), also on the drag chip.
  Virtualized, infinite scroll, sticky "Today / Yesterday / Earlier this week / Earlier"
  group headers in Recent view.
- **Selection**: click selects, Mod/Shift-click multi-select, rubber-band selection in grid view,
  Mod+A selects all; a **selection action bar** replaces the filter bar (Share, Move, Copy,
  Download/Export, Star, Rename (single), Trash, Clear; its actions scroll horizontally when
  they don't fit, e.g. at 360 px). In the mobile layout (T-9, suite 02 §6.1) one tap opens an
  item; ⋮ has the other actions. Its ⋮ menu holds the remaining item
  actions only — it does not repeat the bar's icon actions (`itemMenuEntries(exclude:)`).
- **Context menu** (right-click / ⋮): Open, Share,
  Copy link, Rename, Move to…, Add shortcut, Star/Unstar, Make available offline, Make a copy,
  Download as ▸ (formats), Version history, Details, Move to trash. In Trash: Restore, Delete
  forever.
- **Details panel** (toggle `i`): right side panel (`WonkySplitView` with `rail: false`: a close
  button, no icon rail; suite 02 §4.5) with thumbnail (or the kind icon), type, owner, location,
  sharing summary, created/modified/opened, description (editable; saved on blur through the
  undoable `shell.drive.setDescription`), activity feed (who did
  what, from server activity log). (v2) Also "Storage used" (counted size, with "Counts against
  <owner>'s storage" for other people's items) and, for files, type/dimensions/pages and *Open
  with* ([Drive 04 §3.6](wonky_drive/04-screens-menus.md)).
- **Drag and drop**: (v2) in Drive: items onto folders moves them (undoable), OS files upload
  as files (Drive 04 §3.5). In app homes: files from the OS onto the list **import** the app's
  convertible types (`.md/.txt/.html/.docx/.odt/.rtf` → Write; `.xlsx/.xls/.ods/.csv/.tsv` →
  Sheets; Slides imports nothing) with an upload progress toast list (bottom-right); other files
  get the toast "Wonky Write can't open "x.zip". Upload it in Wonky Drive instead. [Open Wonky
  Drive]". Item drags onto folders are Drive-only.
- **Empty states**: illustrated (light/dark variants) per view ("No starred files yet").
  The primary creation button (`drive.empty.new`) disables and shows a loading spinner
  (`ShadSpinner`) while file creation is in flight (T-7).

### 3.3 Dialogs
- **Rename** (`ShadDialog` with input, Enter to save).
- **Move to…**: folder browser with breadcrumb, create-new-folder inline, disabled targets where
  user lacks permission.
- **Make a copy**: name, folder, checkboxes "Copy comments", "Share with the same people".
- **Delete forever**: confirm with count.
- **Upload/import options**: for CSV (delimiter, encoding, header row, convert numbers/dates),
  for XLSX (import all sheets / selected sheets), for DOCX (mapping notice: "Formatting not
  supported in Markdown will be removed").
- (v2) **Out of storage** ([Drive 03 §6.3](wonky_drive/03-storage-quota.md)) and **Upload
  options** for name conflicts ([Drive 02 §3.2](wonky_drive/02-files-uploads-previews.md)).

### 3.4 Keyboard
`/` focus search · `Enter` open · `F2`/`N` rename · `Del` trash · `S` star · `Mod+Alt+N` new
(app's default type) · `Shift+F` new folder (Drive only, v2) · arrows navigate · `.` share ·
`i` details. All via commands (`shell.drive.*`); Drive adds `Space` preview and `Shift+U`
upload (Drive 04 §10).

## 4. Offline behavior

- The drive list is cached locally (last 500 items + all pinned) for offline browsing. Offline,
  "New spreadsheet" works (client generates the file UUID, the creation op goes into the
  outbox and `registerSpreadsheet` is queued; [17](17-revlog-sync.md) part 6 §7.1). "New
  document" works offline (client generates `documentId` UUIDv7; registration queued; see
  offline spec). (v2) "New presentation" works offline like spreadsheets (Slides 02 §9.3). In
  Drive, *New* Wonky items navigate to the app's `/new` route, which creates them offline-first
  (Drive 04 §5); Drive itself holds no Sheets/Slides cache.
- (v2) Uploads in Drive are queued while offline and start when the connection returns; the
  quota applies when they reach the server ([Drive 02 §4](wonky_drive/02-files-uploads-previews.md)).
  Previews of files are available offline only from the in-memory cache.
- (v2) The storage meter shows the last known usage while offline.
- Items not available offline are dimmed with a tooltip when offline.
- Pending drive operations (rename/move/star/trash) are queued and replayed in order; conflicts
  resolve server-side by "last write wins" per field with a toast if the item no longer exists.

## 5. Activity log (shared)

```yaml
class: ActivityEvent
table: activity_event
fields:
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  actorId: int?
  actorKind: ActorKind        # enum: user, mcp, ai, script, system
  type: ActivityType          # enum: created, renamed, moved, edited, commented, shared,
                              #   unshared, restoredVersion, trashed, restored, exported,
                              #   uploaded (v2), newVersionUploaded (v2, P2), converted (v2: the
                              #   new item's "Created from data.csv")
  summary: String             # JSON payload for rendering
  at: DateTime
indexes:
  activity_item_idx: { fields: itemId, at }
```

Edits are aggregated: at most one `edited` event per (user, item) per 10-minute window.
