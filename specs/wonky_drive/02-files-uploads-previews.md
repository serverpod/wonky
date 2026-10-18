# Drive 02 · Files, Uploads and Previews

This spec defines the **`file` kind** (arbitrary uploaded files as drive items), the upload
flow (picker, drag-and-drop, upload queue, offline queue, resumability), MIME sniffing,
in-app previews (images, text/code, audio; no PDF previews in v2, §6.3), *Open with* conversions to Write and Sheets,
downloads, and versions of uploaded files (P2). Storage accounting and enforcement are in
[03](03-storage-quota.md); the screens in [04](04-screens-menus.md); the security rules for
uploads in suite [13 §6](../13-security-and-operations.md).

## 1. The `file` kind

### 1.1 Model additions (`wonky_server/lib/src/platform/drive/`, `…/files/`)

`DriveItemKind` gains `presentation` (Slides decks, Slides 02) and `file` (appended values;
`serialized: byName`, so existing rows and clients are unaffected). Fields added to
`DriveItem` (suite [05 §1](../05-drive-and-files.md)):

```yaml
# drive_item.spy.yaml (additions, v2)
  ### Files: the effective (sniffed, §5) MIME type; null for other kinds.
  mimeType: String?
  ### Files: category for icons, filters and the preview viewer (§1.2).
  fileCategory: FileCategory?
  ### Files: upload state (§2). Null for other kinds.
  uploadState: FileUploadState?
  ### Files: kind-specific metadata JSON: {width, height} (images), {pages} (PDF),
  ### {lines, encoding} (text), {durationMs} (audio, P2). Filled at completion or by the client.
  fileMetaJson: String?
  ### Files: downscaled preview image (StoredFileKind.preview, §6.2). Not counted (03 §2).
  previewFileId: UuidValue?
  ### Bytes of images/attachments stored for this item (03 §2); counted for the owner.
  attachmentBytes: int, default=0
  ### Bit set of the kinds this folder contains recursively (folders only; suite 05 §3.2).
  kindMask: int, default=0
```

For a file, `contentRef` is the `StoredFile.fileUuid` of the current content and `sizeBytes`
is the file size in bytes. A file item's `uuid` is client-generated (UUIDv7) like documents
created offline, so the upload queue can refer to it before the server knows it.

```yaml
# file_category.spy.yaml (new)
enum: FileCategory
serialized: byName
values:
  - image          # jpeg, png, gif, webp, bmp (previewed); heic/tiff/svg (not rendered)
  - pdf
  - text           # text/* and known source/data extensions (§6.4)
  - audio          # P2 preview
  - video          # never previewed
  - archive        # zip, tar, gz, 7z, rar
  - document       # docx, odt, rtf, doc, pages (convertible ones offer Open with Write)
  - spreadsheet    # xlsx, xls, ods, csv, tsv, numbers (convertible ones offer Open with Sheets)
  - presentation   # pptx, odp, key (download only — no Slides import, Slides 01)
  - other

# file_upload_state.spy.yaml (new)
enum: FileUploadState
serialized: byName
values:
  - uploading      # created, bytes not yet verified
  - ready
  - failed         # verification failed (size mismatch, storage error); bytes deleted
```

`StoredFileKind` gains `driveFile` (the bytes of a `file` item; access follows the item,
`itemId` set) and `preview` (server-made preview images; not counted, deleted with the item).

### 1.2 Category detection

`FileCategory` is derived on the server from the effective MIME type (§5) with the extension
as tie-breaker for `text/plain` and `application/octet-stream`; the table lives in
`wonky_core/lib/files/file_types.dart` (pure Dart, shared by server, apps and MCP) together
with the list of **convertible** types (§7) and the **text extensions** list (§6.4).

## 2. Lifecycle

```
createFileUpload ──► uploading ──(bytes in storage, completeFileUpload verifies)──► ready
       │                 │                                                          │
       │                 └─(verify fails / cancel / 24 h without completion)──► failed → deleted
       └─ reserves quota (03 §5)                       ready: reservation becomes usage
```

- **uploading** items are listed only for the uploader (in the list with a progress ring and
  in the upload panel); collaborators of the target folder don't see them, and they are not
  searchable, shareable or copyable. A trash/delete of an uploading item cancels the upload.
- **ready** items behave like every other drive item.
- **failed** items are removed from the listing at once; the upload panel keeps a failed row
  with the reason until dismissed.
- A daily job (`drive.expireUploads`, part of the existing maintenance FutureCall) deletes
  items still `uploading` after 24 h, their partial bytes and their reservations.

## 3. Upload flow

### 3.1 Entry points

| Entry point | Where | Command |
|-------------|-------|---------|
| *New ▸ File upload* | Drive left menu, Drive empty-area context menu | `shell.drive.upload` |
| *New ▸ Folder upload* (P1) | same | `drive.upload.folder` |
| Drag files or folders from the OS onto the list or a folder row/card (tree nodes and breadcrumbs: P1) | Drive home | — (drop handler → `drive.upload.files {staged, parentUuid}`) |
| Paste files from the clipboard (P1, browsers that expose files) | Drive home | `shell.edit.paste` (contributed by the home) |
| MCP `drive.upload_file` / `drive.create_upload` | headless | suite 09 §4 |

In app homes, `shell.drive.upload` stays the **import** entry point (label *Import file…*):
it accepts only the app's convertible types and creates items of the app's kind (today's
behavior, suite 05 §3.1). Dropping a non-importable file on an app home shows the toast
"Wonky Write can't open "photos.zip". Upload it in Wonky Drive instead. [Open Wonky Drive]".

A batch has at most 500 files; folder uploads recreate the folder structure under the
target folder (folders are created with `drive.createFolder` before their files are queued;
online only). **As built (D-13):** *dropped* folders are in M8 (the web drop's
`webkitGetAsEntry` tree through `desktop_drop`); empty dropped folders are not created, and the
folder *picker* (`drive.upload.folder`, `webkitdirectory`) stays P1. The files of a drop or
pick are staged in the app and `drive.upload.files` receives the stage id (bytes can't travel in
command arguments).

### 3.2 Client pre-checks (before anything is sent)

The pre-checks run on the sizes the file picker reports (`PlatformFile.length`), before any
content is read: the picker returns `LazyImportFile`s and the queue gets `UploadFile.lazy`
entries, so a refused file (too large, too many files, over quota) is never loaded into
memory, and a file the queue accepts is read when it is enqueued (a file that can no longer
be read becomes a failed row). Only where the platform reports no size is the file read
first (DR-1).

1. **Size**: a file larger than `maxFileUploadBytes` (from `meta.getInfo`, default 50 MB) is
   rejected in the panel: "photo.raw is too large — files can be at most 50 MB."
2. **Quota**: the client sums the batch and compares it with `StorageUsage.availableBytes`
   (03 §3). If the batch doesn't fit, the **out of storage** dialog (03 §6.3, variant *batch*)
   offers *Upload the files that fit* (smallest first, in the user's order otherwise) or
   *Cancel*. The server stays authoritative (§3.3).
3. **Name conflicts**: if a ready item with the same name (case-insensitive) exists in the
   target folder, the *Upload options* dialog asks "Keep both" (default; the new file gets
   " (1)" before the extension), "Skip" (those files aren't uploaded) or "Replace" (P2, uploads
   a new version, §9; not offered until then). The dialog is
   skipped when the Drive setting *Ask when uploaded files have the same name* is off (then
   Keep both), and for MCP/AI invocations (Keep both; a batch over quota uploads the files that
   fit).
4. **Empty files** (0 bytes) are allowed.

### 3.3 Server calls

```
client                              server (DriveEndpoint / FileService)                storage
  │ createFileUpload(req) ─────────►│ checks: role on parent (Editor+), name, size ≤ max,
  │                                 │ quota reservation (03 §5) — atomically
  │                                 │ inserts DriveItem(kind:file, uploadState:uploading)
  │                                 │ + StoredFile(kind:driveFile, status:pending)
  │◄──── FileUploadStart ───────────│ (item view, upload description, chunk size if chunked)
  │ FileUploader.upload(bytes) ─────────────────────────────────────────────────────────►│
  │ completeFileUpload(itemUuid) ──►│ verifyDirectFileUpload; actual size == declared?
  │                                 │ sniff first 4 KB (§5) → mimeType, fileCategory
  │                                 │ uploadState: ready; reservation → usage (03 §5)
  │                                 │ DriveChange(created) to watchers; ActivityEvent(uploaded)
  │                                 │ schedule preview/thumbnail generation (§6.6)
  │◄──── DriveItemView ─────────────│
```

```dart
// DriveEndpoint additions (v2)
Future<FileUploadStart> createFileUpload(Session session, FileUploadRequest request);
Future<DriveItemView> completeFileUpload(Session session, UuidValue itemUuid);
Future<void> cancelFileUpload(Session session, UuidValue itemUuid);
Future<FileUploadProgress> fileUploadStatus(Session session, UuidValue itemUuid); // resume (§4.3)
Future<ImportReportView> convertFile(Session session, UuidValue fileItemUuid,
    DriveItemKind target, DriveImportOptions options);                          // §7
Future<FileUrlView> fileContentUrl(Session session, UuidValue itemUuid,
    {bool download = false});                                                  // §6.1, §8
Future<DriveItemView> updateFileMeta(Session session, UuidValue itemUuid,
    String fileMetaJson);                       // client-measured metadata (PDF pages), Editor+
```

```yaml
class: FileUploadRequest
fields:
  itemUuid: UuidValue          # client-generated (idempotency key with fileUuid)
  fileUuid: UuidValue          # client-generated
  parentUuid: UuidValue?       # null = My Drive root
  name: String                 # original file name (display name; §5.1 sanitizes)
  sizeBytes: int
  declaredMimeType: String?    # browser/OS type, informative only
  lastModified: DateTime?
  conflict: UploadConflictMode # keepBoth (default) | replace (P2) | fail
  chunked: bool, default=false # P1 resumable upload (§4.3)

class: FileUploadStart
fields:
  item: DriveItemView
  ticket: FileUploadTicket     # uploadDescription null when already complete (idempotent retry)
  chunkSizeBytes: int?         # chunked uploads only
  storage: StorageUsage        # usage after the reservation (03 §3)

class: FileUploadProgress
fields:
  uploadState: FileUploadState
  receivedBytes: int           # chunked: bytes the server has; else 0 or sizeBytes
```

Rules:

- `createFileUpload` is **idempotent** on `(itemUuid, fileUuid)`: a retry returns the existing
  item and either a fresh upload description (still pending) or `null` (already complete).
  Reusing an `itemUuid` with a different `fileUuid` or size is `conflict`.
- Errors: `forbidden` (no Editor role on the parent), `notFound` (parent gone — the client then
  offers *Upload to My Drive*), `invalidArgument` (name), `tooLarge` ("Files can be at most
  50 MB."), `quotaExceeded` (03 §7), `limitExceeded` (more than 100 pending uploads).
- `completeFileUpload` fails the item (state `failed`, bytes deleted, reservation released) when
  the stored size differs from `sizeBytes` or the storage reports no object; the error is
  `invalidArgument` "The upload was incomplete. Try again." and the client retries the whole
  file once automatically.
- Uploading into a folder shared with others: the file is owned by the **uploader** and
  counts against the uploader's quota (03 §2), exactly like a document created there.
- **Upload route for non-Serverpod clients.** MCP agents (`drive.create_upload`, suite 09 §4)
  can't use Serverpod upload descriptions (S3/GCS presigned POST forms). They get a URL of the
  server web route `PUT /files/upload/:fileUuid?t=<token>` (HMAC token bound to user, file and
  declared size, 15 min) that accepts the whole body in one request and streams it to storage;
  the same route takes `Content-Range` chunks for resumable uploads (§4.3, P1). Bodies larger
  than the declared size are cut off with `413`.

### 3.4 Undo

An upload batch is one undo step on the shell stack ("Undo Upload", domain `drive`): undo
moves the batch's ready items to the trash (uploads still running are cancelled); redo
restores them. Permanent deletion stays non-undoable (suite 08 §2).

### 3.5 Upload queue (client)

`UploadQueue` (`wonky_drive/lib/features/uploads/`, a `ChangeNotifier`) owns all uploads of the
Drive app:

- Runs **3 uploads in parallel** (FIFO), keeps per-file state: `queued`, `waitingForNetwork`,
  `starting`, `uploading(bytesSent)`, `verifying`, `done(item)`, `failed(reason, retryable)`,
  `cancelled`.
- Progress: **spike S-D2** found that the web `http` client — and so Serverpod's
  `FileUploader` — buffers the request body and reports no upload progress; the web client
  therefore sends the upload description (binary or multipart) itself with an
  `XMLHttpRequest` and `upload.onprogress`; desktop sends it with `http` on a counted byte
  stream (not `FileUploader`, which hangs when the connection fails before the body is read
  and reports every failure as `false`): an unreachable storage is an `OfflineException`, an
  error status an `UploadTransferException`, and the transfer ends on cancel or after 60 s
  without progress or answer (DR-5).
  Throughput and time left are shown after 2 s of data.
- *Cancel* calls `cancelFileUpload` (releases the reservation); a cancel while
  `createFileUpload` is still in flight releases the reservation as soon as that call returns
  (DR-2). A cancel while `completeFileUpload` is in flight doesn't race it: when the completion
  succeeds the file is kept and the row shows it as uploaded; when it fails the reservation is
  released. That release uses the ids the completion was called with: an undo and redo meanwhile
  rotates the task's ids and reserves new ones. *Retry* re-runs from `createFileUpload` (idempotent).
- Leaving the Drive app (navigating to Write, closing the tab) while uploads run asks
  "Uploads in progress — leave and continue later?" (web `beforeunload` prompt). **As built
  (D-13):** cross-app navigation is a full page load, so the browser's own `beforeunload`
  prompt covers it too; there is no separate `ShadDialog`. Queued and interrupted uploads continue on the next start
  of the Drive app (§4); there is no background upload while the app is closed.
- Each queue change is written to the local store first (§4.1), so a reload restores the panel.

## 4. Offline and resumability

### 4.1 Persistence

The queue is persisted in `LocalPendingUpload` (suite [12 §1.1](../12-offline-and-sync.md),
the table shared by all apps) in the Drive app's local database `drive_<userId>.db` (opened
with the shell's `LocalDatabases.open`), with v2 columns:

| Column | Meaning |
|--------|---------|
| `purpose` | `attachment` (existing: images in documents/over cells, imports) or `driveFile` |
| `itemUuid`, `fileUuid` | client ids (§3.3) |
| `parentUuid` | target folder |
| `fileName`, `sizeBytes`, `mimeType`, `lastModified` | |
| `bytes` | the content (web), or null when `sourcePath` is used |
| `sourcePath` | desktop only (deferred in v2, suite 01 A13; always null on web): path of the original file (no copy); re-read at upload time, verified by size + modification time; if it changed or vanished the row fails with "The file changed or was moved after you added it." |
| `state`, `attempts`, `lastError`, `receivedBytes` | queue state (§3.5), resume offset (§4.3) |

Web storage: bytes up to **5 MB per file** are stored in the local database even on the
IndexedDB fallback; larger files are stored only when OPFS is available (suite 12 intro). On
the IndexedDB fallback a larger file is held in memory only and its row is marked
`volatile`: the panel shows "Keep this tab open until the upload finishes"; after a reload such
rows show "Add the file again — it wasn't saved on this device." with *Choose file*.

**As built (D-13, S-D2):** the store lives in `wonky_drive` (`SqliteUploadStore`, not in
`wonky_app/lib/src/data/`: only Drive uploads files; Write keeps its image table), the file is
`drive_<userUuid>.db` (the user's uuid, like Write's cache), and the table is
`local_pending_upload` with the columns above plus `batch_id`, `parent_name`, `volatile`,
`error_kind` and `result_json`. OPFS is detected like the Sheets cache does (secure context,
`FileSystemFileHandle`, a working `navigator.storage.getDirectory()`). Finished rows are dropped
at the next start; interrupted uploads (starting/uploading/verifying) are queued again with the
same ids (idempotent).

### 4.2 Offline queueing

- Offline (`ConnectivityService.online == false`), new uploads go straight to
  `waitingForNetwork`; the list shows the items dimmed with a cloud-off badge ("Waiting for
  connection"). The quota pre-check uses the cached `StorageUsage` and pending queue sizes.
- When the connection returns, the queue starts in order; retries use exponential backoff
  2 s → 10 min with jitter (same as image uploads, suite 12 §1.2).
- **Quota applies when the upload reaches the server**: a queued file that no longer fits
  fails with "Not uploaded — you're out of storage" and the action *Manage storage*; it stays
  in the panel (and the local store) for *Retry* after space was freed.
- A queued upload whose target folder was deleted or lost access meanwhile offers *Upload to
  My Drive* / *Remove*.

### 4.3 Resumable uploads (P1)

M8 (P0) restarts a failed file from its first byte (≤ 50 MB). P1 adds **chunked resumable
uploads** for files over 8 MB:

- `createFileUpload(chunked: true)` returns `chunkSizeBytes` (8 MB) and no upload
  description. The client `PUT`s chunks to the server web route
  `PUT /files/upload/:fileUuid` with `Content-Range: bytes <start>-<end>/<total>` and the
  bearer/cookie session; each chunk is stored as a part object (`uploads/<fileUuid>/<n>`) in
  cloud storage; the server answers `{receivedBytes}`.
- After a network loss or reload the client calls `fileUploadStatus` and continues at
  `receivedBytes`. `completeFileUpload` concatenates the parts into the final object (stream
  copy) and deletes them.
- Parts of uploads that never complete are deleted by `drive.expireUploads` after 24 h.

**Decided (v2 review, Q12):** M8 ships **whole-file retries** (the 50 MB cap keeps a retry
cheap); the chunked route above stays P1 and is built only if upload-failure telemetry shows a
need (it needs our own route and server-side concatenation because Serverpod's upload
descriptions are single-request).

## 5. MIME sniffing and safe types

Done on the server in `completeFileUpload` by `FileTypeSniffer` (`platform/files/`), reading the
first 4 KB of the stored object:

1. **Magic numbers** via the `mime` package (`lookupMimeType(name, headerBytes:)`) plus our
   own signatures for types it misses (PDF `%PDF-`, ZIP/OOXML `PK\x03\x04` + `[Content_Types].xml`
   check → docx/xlsx/pptx by the first part names, ODF `mimetype` entry, WebP `RIFF….WEBP`,
   MP3/ID3, Ogg, WAV, FLAC, MP4/M4A `ftyp`).
2. If no signature matches: **text check** — valid UTF-8 (or UTF-16 with BOM) without NUL bytes
   in the sample → `text/plain` (or a specific text type from the extension: `text/markdown`,
   `text/csv`, `application/json`, source code types — the list in `file_types.dart`). Bytes
   that are not UTF-8 but have no NUL and fewer than 1 % control bytes are text too, with
   encoding Latin-1 (§6.4 "Shown as Latin-1"). HTML, SVG and XML are recognized from the
   **content** (`<!doctype html`, `<html`, `<script`, `<svg`, `<?xml` …), never from the name.
3. Otherwise `application/octet-stream`.

The **declared** type (browser/OS, client) and the extension never override a sniffed binary
signature. Mismatches are kept as is (a `.png` that is really a PDF is treated as a PDF — the
*Download* card, §6.3; its name is not changed). Active types are never rendered (§6): `text/html`, `image/svg+xml`,
`application/xhtml+xml`, `text/xml`, JavaScript and every unknown type are previewed as text
(if text) or not at all.

### 5.1 File names

`DriveItem.name` keeps the user's original name (Unicode allowed, 1–255 chars, trimmed, `/`
replaced by `_`, control characters and bidi overrides U+202A–U+202E, U+2066–U+2069 removed so
"invoice‮fdp.exe" can't pose as a PDF). The storage path uses `FileService._safeName` (ASCII)
under `drive/<ownerUuid>/<fileUuid>/`.

## 6. Previews

### 6.1 Route and loading

- Route **`/drive/file/:uuid`** (`FilePreviewScreen`, Drive app): a full-screen in-app page
  (single window; suite 03 §1). It is also `DriveAppConfig.itemPath`, so the shell's item route,
  the quick switcher, links in notifications and share-link landings all open it. Opening a
  file from an app context (e.g. a search result in Write) navigates to Drive (same tab).
- Bytes are loaded with `drive.fileContentUrl(uuid)` → signed URL (15 min; served as an
  `application/octet-stream` attachment, never inline) → `http` GET into
  memory (`Uint8List`), cached per `(fileUuid)` in an in-memory LRU (100 MB) for prev/next
  browsing. Images use the server preview (§6.2) when the original is over 4 MB. Text and CSV
  previews request only the first 1 MB + 1 byte (`Range: bytes=0-1048576`; a storage host that
  ignores it is read only that far, one whose CORS rules refuse it is asked again without it),
  and only that is cached (DR-3). Stepping prev/next reuses the folder listing for 30 s while it
  holds the file (DR-6).
- States: loading (skeleton + spinner after 300 ms), *still uploading* ("This file is still
  uploading (42 %)" — the uploader sees live progress; others never reach it), error ("Couldn't
  load the preview. [Retry] [Download]"), offline ("Previews aren't available offline." — unless
  the bytes are in the cache), too large to preview ("Preview isn't available for files over
  …; [Download]").
- *As built (D-14):* ‹ › and ←/→ step through the ready files of the **file's folder** (sorted
  by name); the home does not yet hand its visible list (search results, starred…) to the
  preview (TODO.md). *Close* returns to the last non-preview location of the shell history with
  the file selected. The cache key is the item's `contentRef` (or the preview image's
  `previewFileId`), so a reopened or offline file shows from memory.
- Viewers with *Viewer/Commenter* role on an item whose owner turned off
  `nonEditorsCanExport` see the preview but no Download (advisory: the bytes reach the client
  for the preview; suite 06 §1).

### 6.2 Images (P0)

- Rendered: JPEG, PNG, GIF (animated), WebP (animated), BMP. HEIC/TIFF/ICO and SVG are not
  rendered (icon + Download; SVG is shown as text, §6.4).
- Decoding is bounded: images over 50 megapixels show the server preview only.
- Server preview: on completion a FutureCall decodes the image with `package:image` (time limit
  10 s, ≤ 50 MP), auto-orients by EXIF, strips metadata, and writes a ≤ 2048 px PNG/JPEG as
  `StoredFileKind.preview` (`DriveItem.previewFileId`) plus a 400 × 300 thumbnail
  (`thumbnailFileId`). Failures leave both null (the client falls back to the original if
  ≤ 4 MB). `fileMetaJson` gets `{width, height}`.
- Viewer: fit to window (default), zoom 10 %–800 % (`+`/`−`, `Mod`+scroll, pinch), `0` fit, `1`
  actual size, drag to pan, rotate 90° (view only, not saved), checkerboard behind transparency
  (`canvas` token based, light/dark).

### 6.3 PDF — no previews in v2

**Decided (user, after D-18): no PDF previews in v2.** PDFs get the same treatment as every
other file that can't be previewed (§6.7): the card with the category icon (PDF red), name, type
· size, owner and date, and *Download* (and *Open with* where a conversion exists — none for
PDFs today). No error or "unavailable" message: a PDF is simply not a previewable type. The
viewer's bytes are never fetched for a PDF, so opening one costs one `drive.get`.

What was built and removed again: S-D1 had picked `printing`'s `Printing.raster` with a
self-hosted pdf.js (`wonky_drive/web/pdfjs/`, `window.dartPdfJsBaseUrl`, `tool/fetch_pdfjs.sh`,
page scan ≤ 300 pages, page field, go to page, fit width, password and broken states, page count
written back with `drive.updateFileMeta`). The pdf.js files were never committed (a ~4 MB
third-party download), and the user decided previews aren't worth it. The viewer, the
`drive.preview.goToPage` command, its strings and the `printing` dependency of `wonky_drive` are
gone; `drive.updateFileMeta` stays on the server (generic client-measured metadata, §1.1) without
a v2 caller. PDFs have no thumbnail (the category icon is shown). A later PDF preview would
start again from S-D1 (`printing` + pdf.js, or `pdfrx`).

### 6.4 Text and code (P0)

- Applies to `fileCategory == text` (UTF-8/UTF-16; other encodings decoded as Latin-1 with a
  notice "Shown as Latin-1"). Shows the **first 1 MB**, with "Showing the first 1 MB. Download
  to see the whole file." beyond that.
- Rendered read-only with `CodeView` from `wonky_code_flutter` (suite 01 §2.1): line numbers,
  soft wrap toggle (`Alt+Z`), syntax highlighting when the extension maps to a language of the
  shared language list (`dart`, `py`, `js`, `ts`, `json`, `yaml`, `html`, `css`, `sql`, `go`,
  `rs`, `java`, `kt`, `swift`, `md`, `spy.yaml` → `serverpod`), light/dark code palettes,
  *Copy all*, find in file (`Mod+F`, P1).
- Markdown is shown as source (with *Open with Wonky Write* to get it rendered); HTML, SVG and
  XML are shown as source and never rendered.
- CSV/TSV (P1): a *Table* / *Text* toggle; the table shows the first 1,000 rows in a simple
  virtualized table (a fixed-row-height list with a row-number column — `ShadTable` is not
  virtualized), parsed with the Sheets CSV rules (delimiter sniffing in
  `wonky_core/lib/files/csv_sniffer.dart`, `CsvSniffer`, no type conversion).
- As built (D-14): files up to 50,000 characters are highlighted with the shared default
  tokenizer (TextMate, then highlight.js); longer ones with highlight.js, and only their first
  250,000 characters (≈ 5,000 lines; the rest stays plain). The copied TextMate engine is
  superlinear on large inputs (≈ 0.7 s for 100 K characters, ≈ 19 s for 500 K on the VM), which
  would freeze the page; highlight.js stays linear (1 MB file: decode 3 ms + highlight ≈ 180 ms
  on the VM, `preview_budget_test.dart`). Bytes that look binary (NUL bytes or > 1 % control
  characters) show "This file can't be shown as text" instead of garbage.

### 6.5 Audio (P2)

MP3, M4A/AAC, OGG/Opus, WAV, FLAC: a player card (play/pause, scrubber, time, volume,
playback speed) using the platform media element (web `<audio>` through `package:web`;
desktop: `just_audio` — spike when scheduled). Bytes are streamed from the signed URL (no
full download). Video files are never played (no video in v2).

### 6.6 Thumbnails

| Kind | Thumbnail |
|------|-----------|
| Images | Server, at completion (§6.2) |
| PDF | None in v2 (category icon; no PDF rendering, §6.3) |
| Text/code | None (kind icon with the extension label) |
| Documents, spreadsheets, presentations | Rendered by their apps (suite 05 §2 `setThumbnail`; Slides: first slide) |

Thumbnails and previews never count against the quota (03 §2).

### 6.7 Everything else

Icon by `FileCategory` (Lucide `file-image`, `file-text`, `file-code`, `file-audio`,
`file-video`, `file-archive`, `file-spreadsheet`, `presentation`, `file`) at 96 px, the name,
"ZIP archive · 12.4 MB", owner, modified date, and the primary button **Download**; convertible
types also show **Open with Wonky Write / Wonky Sheets**. Archives are not listed or extracted.

## 7. *Open with* — conversions

### 7.1 Mapping

| File types | Target | Pipeline |
|------------|--------|----------|
| `.csv`, `.tsv` | Wonky Sheets | Sheets 11 CSV import (options: delimiter, encoding, header row, conversions) |
| `.xlsx`, `.xls`, `.ods` | Wonky Sheets | Sheets 11 XLSX/ODS import (sheet selection) |
| `.docx`, `.odt`, `.rtf` | Wonky Write | Write 07 import ("Formatting not supported in Markdown will be removed") |
| `.md`, `.markdown`, `.txt`, `.html`, `.htm` | Wonky Write | Write 07 import |
| `.pptx`, `.key`, `.odp` | — | not offered (no presentation import, Slides 01) |

### 7.2 Flow

- UI: *Open with ▸ Wonky Sheets* (preview top bar, item ⋮ menu, details panel) runs
  `drive.file.openWith {uuid, app: sheets}`, which navigates (same tab, full page load) to the
  target app's import route **`/sheets/import?file=<fileItemUuid>`** (`/write/import?file=…`).
  The target app loads the bytes through `drive.fileContentUrl`, shows its own import options
  dialog (Sheets 04 §11.15, Write 07 §3), imports into the **file's folder** (or My Drive when
  the user can't edit that folder), names the new item after the file without its extension,
  and opens it. *Cancel* in the options dialog returns to the previous Drive location
  (`history.back`). The original file is kept.
- Headless (MCP, AI): `drive.convertFile(fileItemUuid, target, options)` runs the server import
  pipelines (`ImportService`, as `drive.import` does for `importSource` uploads) directly on the
  file's stored bytes.
- The new item's size counts against the importing user's quota (it is the owner); a
  conversion that doesn't fit fails with `quotaExceeded` before work starts (estimate = file size)
  and again on the real size.
- Permission: Viewer+ on the file and Editor+ on the target folder (else My Drive).

### 7.3 Convert on upload (P1)

Drive setting *Convert uploads to Wonky formats* (default **off**): when on, convertible files
dropped or picked in Drive are imported (as the app homes do) instead of stored as files;
non-convertible files upload normally. The upload panel row then reads "Converted to a
spreadsheet". Server-side pipeline only (`drive.import` with an `importSource` upload).

**Decided (v2 review, Q13):** Drive does **not** convert by default — it keeps the original
(what users expect from "upload"); converting is one click away (*Open with*), and this setting
exists for people who want Google's old "convert uploads" behavior.

As built (D-17): the upload queue converts after `drive.completeFileUpload`
(`UploadQueue.convertTo`, set by `UploadHost` from the setting and `FileTypes.convertTargetOf`):
`drive.convertFile` into a document or spreadsheet next to the file, then the uploaded file is
trashed and deleted forever, and the task's result is the new item (the batch undo trashes it;
the row reads "Converted to a spreadsheet" and opens the item in its app). A failed conversion
keeps the file and shows "notes.docx couldn't be converted. It was kept as a file." This is a
client-side sequence, not the server-side `importSource` import (TODO.md).

## 8. Downloads

- **Files**: `drive.fileContentUrl(uuid, download: true)` returns a short-lived URL of the
  server route `GET /files/d/:fileUuid/:name?t=<token>` (token: HMAC of fileUuid + userId +
  expiry, 15 min). The route streams from storage with forced headers (suite 13 §6:
  `Content-Disposition: attachment`, `X-Content-Type-Options: nosniff`,
  `Content-Security-Policy: sandbox`). Web: the app triggers it with a hidden anchor carrying
  the `download` attribute (same tab — no new window); desktop: `file_saver` save dialog,
  streamed to disk.
- **Documents, spreadsheets, presentations**: *Download ▸ format* runs the existing exports
  (`shell.file.download {format}` / `drive.export`; Slides: PDF, Slides 10).
- **Several items (P1)**: *Download* on a multi-selection builds a ZIP on the server
  (`drive.downloadZip(uuids, formats)` → export job with progress toast → `exportResult`
  StoredFile, not counted) with the folder structure; Wonky items in the user's default formats
  (documents `.md`, spreadsheets `.xlsx`, presentations `.pdf`; changeable in the dialog). Limit
  200 items / 200 MB uncompressed.
- Every download records an `ActivityEvent(exported)` for Wonky items (unchanged) and nothing
  for files (no download tracking).

## 9. Versions of uploaded files (P2)

- *Upload new version* (item ⋮, preview ⋮; `drive.file.uploadNewVersion {uuid}`) and the
  *Replace* choice of the name-conflict dialog keep the item's uuid, sharing, stars and links,
  and replace its content. Previous contents become `DriveFileVersion` rows:

```yaml
class: DriveFileVersion
table: drive_file_version
fields:
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  fileUuid: UuidValue          # StoredFile of that version
  sizeBytes: int
  mimeType: String
  uploadedById: int
  uploadedAt: DateTime
  keepForever: bool, default=false
indexes:
  drive_file_version_item_idx: { fields: itemId, uploadedAt }
```

- *Manage versions* (details panel) lists versions with Download, *Keep forever*, *Delete*.
  Versions are kept 30 days or 100 versions unless *Keep forever*.

**Decided (v2 review, Q14):** previous file versions **count** against the quota (suite D3
excludes only *version-history snapshots*, which are system-made): uploaded versions are user
bytes, and Google Drive counts them too. The Storage page lists them under the file and *Free
up space* suggests deleting old ones.

## 10. Copies, trash and deletion

- `drive.copy` of a file copies the stored object server-side (no re-upload) into a new
  `StoredFile`; the copy counts for its new owner (03 §4).
- Trash keeps the bytes (counted until purged, 03 §2); *Delete forever* and the 30-day purge
  delete the `DriveItem`, its `StoredFile`s (content, preview, versions) from storage and release
  the usage in the same transaction as the row delete (object deletion is retried by the
  weekly orphan cleanup, suite 13 §3, if storage fails).

## 11. Acceptance criteria

- **AC-D2.1** Uploading 3 files (1 KB, 10 MB, 40 MB) with 50 MB free: the first two succeed, the
  pre-check offers *Upload the files that fit* for the third; the server refuses a forced third
  with `quotaExceeded`; usage afterwards equals the sum of the stored sizes.
- **AC-D2.2** Reload during an upload (web, OPFS): the panel restores; the upload restarts (P0)
  or resumes at `receivedBytes` (P1) and completes once; no duplicate item.
- **AC-D2.3** Going offline, dropping two files, reconnecting: both upload in order; while
  offline they show "Waiting for connection".
- **AC-D2.4** A `.jpg` that is really HTML is stored as `text/html`, previewed as source text,
  and downloaded with `Content-Disposition: attachment` and `nosniff`.
- **AC-D2.5** Image, Dart source and a 3 MB log file preview in light and dark (a PDF shows the
  *Download* card, §6.3);
  ←/→ moves between files of the folder; Esc returns to the folder with the selection kept.
- **AC-D2.6** *Open with Wonky Sheets* on a CSV shows the Sheets import dialog, creates a
  spreadsheet next to the CSV, opens it; Back returns to Drive; the CSV still exists.
- **AC-D2.7** Undo after uploading 5 files moves them to the trash; redo restores them.
- **AC-D2.8** A collaborator listing the shared folder never sees another user's
  `uploading` item.
