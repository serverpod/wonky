# Drive 01 · Overview

**Wonky Drive** is where a user manages everything they own or can access in Wonky Work. Until
v2 each app showed the shared drive filtered to its own kind, with a "Type: All" toggle; v2
splits the roles:

- **Wonky Drive** (`/drive/`) is the *full* drive: every kind, folders, moves, uploads of
  arbitrary files, previews, storage management.
- **App homes** (`/write/`, `/sheets/`, `/slides/`) show **only their own kind** and link to
  Drive for everything else (suite [05 §3](../05-drive-and-files.md),
  [03 §3.3](../03-app-shell-and-navigation.md)).

This file is the entry point to the Drive specs: purpose, principles, prioritized features,
limits and the document map.

## 1. Purpose and positioning

| Question | Answer |
|----------|--------|
| What is it? | A Flutter app (web only in v2; the desktop target compiles, suite 01 A13) on `wonky_app` that shows the unified Wonky drive — like Google Drive for the Wonky suite. |
| Who is it for? | Every user: one click from every app home's left menu (the site root `/` opens Wonky Write's home, v2 review Q2), the place to organize folders, upload files, free up storage and find anything regardless of kind. |
| What does it add over the app homes? | All kinds in one list, folder tree and folder management, drag-and-drop moves, uploads of any file type, previews of uploaded files, *Open with* conversions, the Storage page and storage clean-up. |
| What does it not do? | Edit documents, spreadsheets or presentations (opening one navigates to its app in the same tab), edit uploaded files (no in-browser editors for images, PDFs, text files), host public websites (no anonymous links). |
| Tech | `wonky_drive` app = a `DriveAppConfig` (`WonkyAppConfig`) plus Drive-only features (upload queue, previews, Storage page). The drive list, sidebar, dialogs, details panel and commands stay in `wonky_app` (`lib/src/drive/`) and are shared with the app homes. Previews: images via Flutter, PDF via `printing`'s rasterizer (spike, 02 §6.3), text/code via `wonky_code_flutter`. |

## 2. Drive-specific principles

1. **One drive, many lenses.** There is one set of `DriveItem`s. Drive shows them all; app
   homes are filtered lenses over the same data (same endpoints, same `DriveItemView`s, same
   live `drive.watch` stream).
2. **Uploaded files are first-class drive items** (`DriveItemKind.file`): they can be shared,
   starred, moved, trashed, searched and counted like any other item.
3. **Previews never execute content.** Uploaded bytes are rendered by Flutter (pixels,
   text) — never as HTML/SVG/JS in the browser; downloads are always attachments
   (suite [13 §6](../13-security-and-operations.md)).
4. **Storage is visible and fair.** The 50 MB quota is shown wherever bytes can be added; the
   server enforces it on every byte-adding path; editing existing content is never blocked
   ([03](03-storage-quota.md)).
5. **Same suite rules.** Every action is a command (`shell.drive.*` shared, `drive.*`
   Drive-only), drive changes are undoable where suite [08 §2](../08-commands-and-undo.md) says
   so, single window (previews are in-app routes), shad + `wonky_ui`, light and dark,
   keyboard-first, offline browsing from the cached listing, MCP + AI.

## 3. Feature list

Priorities: **P0** required for M8, **P1** should ship with M8 and may slip to the next
release, **P2** designed now, built later.

### 3.1 App and navigation

| Feature | Priority | Spec |
|---------|----------|------|
| `wonky_drive` app served at `/drive/`, linked from the left menu of every home (root `/` redirects to `/drive/`, the landing app; v2 review B4) | P0 | suite 01 §2.4 |
| Left menu: app links (Drive, Write, Sheets, Slides), Drive navigation, Drive settings, Wonky Work settings, Report a bug, storage meter | P0 | 04 §2 |
| Views: Home (recent + suggested), My Drive (+ folder tree), Shared with me, Recent, Starred, Trash, Storage | P0 | 04 §3 |
| Search across all kinds with type/owner/modified chips | P0 | 04 §3.2 |
| Opening a document/spreadsheet/presentation navigates to its app (same tab); a file opens its in-app preview | P0 | 04 §5 |
| Desktop app (macOS first) with URL scheme `wonkydrive://` | Deferred (v2 is web only, suite 01 A13) | suite 03 §6 |

### 3.2 Items and organization

| Feature | Priority | Spec |
|---------|----------|------|
| All kinds in one list: folders, documents, spreadsheets, presentations, files | P0 | suite 05 |
| New ▸ Folder / Document / Spreadsheet / Presentation / File upload / Folder upload (P1) / From template | P0 | 04 §3.1 |
| Grid and list layouts, sort, folders on top, type filter incl. file subtypes (Images, PDFs, Text & code, Audio, Archives, Other) | P0 | 04 §3 |
| Multi-select (click, Mod/Shift, rubber band, Mod+A), selection action bar | P0 | 04 §3.4 |
| Drag-and-drop moves (list, tree, breadcrumb), drop onto Trash (P1) | P0 | 04 §3.5 |
| Details panel with activity, sharing summary, counted storage, file metadata | P0 | 04 §3.6 |
| Rename, move, copy, star, share, trash, restore, delete forever, empty trash — with undo per suite 08 §2 | P0 | suite 05, 08 |
| Download (single file; documents/spreadsheets/presentations in a chosen format) | P0 | 02 §8 |
| Download several items as one ZIP | P1 | 02 §8 |

### 3.3 Files and previews

| Feature | Priority | Spec |
|---------|----------|------|
| Upload any file type up to the remaining quota (≤ 50 MB per file) — picker and OS drag-and-drop | P0 | 02 §3 |
| Upload panel with per-file progress, cancel, retry, persistence across reloads | P0 | 02 §3.5, 04 §4 |
| Offline upload queue (uploads start when back online) | P0 | 02 §4 |
| Resumable uploads (chunked, resume after network loss without restarting) | P1 | 02 §4.3 |
| Server MIME sniffing and safe content types | P0 | 02 §5 |
| Previews: images (P0), ~~PDF pages~~ (none in v2, user decision — PDFs download, 02 §6.3), text and code with syntax highlighting (P0), CSV as a table (P1), audio (P2); other types: icon + metadata + Download | P0 | 02 §6 |
| Thumbnails for images in grid view (no PDF thumbnails in v2) | P1 | 02 §6.6 |
| *Open with* Wonky Sheets (CSV, TSV, XLSX, XLS, ODS) / Wonky Write (DOCX, ODT, RTF, MD, TXT, HTML) — creates a new item through the existing import pipelines | P0 | 02 §7 |
| Setting "Convert uploads to Wonky formats" | P1 | 02 §7.3 |
| Upload new version of a file, version list | P2 | 02 §9 |
| Comments on files | P2 | suite 07 §2 |

### 3.4 Storage

| Feature | Priority | Spec |
|---------|----------|------|
| 50 MB per-user quota, server-enforced on every byte-adding path | P0 | 03 §4, §7 |
| Storage meter in every home's left menu, banners at 90 % and 100 %, *out of storage* dialog | P0 | 03 §6 |
| Storage page: usage by kind, largest items, empty trash, free-up-space suggestions | P0 | 03 §6.4 |
| Backfill of existing users' usage; non-destructive over-quota state | P0 | 03 §9 |
| Per-user quota override (operator only) | P2 | 03 §3 |

### 3.5 Agents

| Feature | Priority | Spec |
|---------|----------|------|
| MCP: `drive.upload_file`, `drive.create_upload`/`drive.complete_upload`, `drive.download_file`, `drive.convert_file`, `drive.get_storage`; `kinds` filters on list/search | P0 | suite 09 §4 |
| `ui.drive.*` bridge tools (selection, preview) | P1 | suite 09 §6 |
| Assistant panel in Drive (find, organize, summarize text files, create a document from files) | P1 | suite 10 §4 |

## 4. Not supported (by design)

- Editing uploaded files in the browser (images, PDFs, Office files): *Open with* converts to a
  Wonky item instead; the original stays a file.
- Rendering uploaded HTML, SVG or other active content (shown as source text, 02 §6.4).
- Video previews and streaming (shown as a file with Download). No audio recording.
- Anonymous (signed-out) access to uploaded files and folders, also with link sharing
  (signed-out viewing covers documents, spreadsheets and presentations only, suite 06 §2.4);
  public website hosting.
- Syncing a local folder with the drive (no desktop sync client).
- Storage purchases or plans: the quota is fixed by configuration ([03 §3](03-storage-quota.md)).

## 5. Limits

| Limit | Value | Where |
|-------|-------|-------|
| Storage per user | 50 MB (`wonky.drive.quotaBytesPerUser` = 52,428,800) | 03 §3 |
| Max size of one upload | min(remaining quota, `wonky.files.maxFileUploadBytes` = 50 MB) | 02 §3.2 |
| Files per upload batch | 500 (more: "Upload at most 500 files at a time") | 02 §3.1 |
| Pending uploads per user (server reservations) | 100 or the quota, whichever is hit first | 03 §5 |
| Text preview | first 1 MB of the file | 02 §6.4 |
| Image preview | decodes ≤ 50 megapixels; server preview image ≤ 2048 px | 02 §6.2 |
| PDF preview | none in v2 (*Download* card) | 02 §6.3 |
| ZIP download (P1) | 200 items, 200 MB uncompressed | 02 §8 |
| Trash retention | 30 days (counts against the quota until purged) | 03 §2 |

## 6. Relationship to the app homes

| | Wonky Drive | App home (Write / Sheets / Slides) |
|-|-------------|-------------------------------------|
| Kinds listed | all | the app's kind only (+ folders that contain it, suite 05 §3.2) |
| New | folder, document, spreadsheet, presentation, upload, template | the app's kind, from template |
| Folder management (create, tree, drag moves) | yes | no — *Open in Wonky Drive*; per-item *Move to…* stays |
| Upload | any file (or convert, setting) | *Import* of convertible files into the app's kind |
| Previews of files | yes | — (files are not listed) |
| Storage page | yes | meter + link to Drive's Storage page |

## 7. Document map

| Need | Read |
|------|------|
| Drive model, endpoints, app homes, offline drive cache | suite [05](../05-drive-and-files.md) |
| Left menu, homes, settings routes, Report a bug, single window | suite [03](../03-app-shell-and-navigation.md) |
| Settings split (suite vs app settings) | suite [04 §4](../04-auth-and-accounts.md) |
| Sharing of files and presentations | suite [06](../06-sharing-and-permissions.md) |
| Commands and undo (`shell.drive.*`, `drive.*`) | suite [08](../08-commands-and-undo.md) |
| MCP drive tools | suite [09 §4](../09-mcp.md) |
| Upload queue storage, offline | suite [12 §1.1, §3](../12-offline-and-sync.md) |
| Upload security, MIME sniffing, download headers | suite [13 §6](../13-security-and-operations.md) |
| Milestone and workstreams | [05](05-implementation-plan.md), suite [14](../14-roadmap.md) |
