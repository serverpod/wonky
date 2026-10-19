# 12 · Offline, Sync and Local Storage

| App | Online sync | Offline strategy | Local store |
|-----|-------------|------------------|-------------|
| Write | Server-authoritative OT over a Serverpod stream (Quill Delta) | Local op queue + snapshot cache; rebase (transform) on reconnect | SQLite (`sqlite_async`, same infra as Sheets) — `write_cache_<userId>.db` |
| Sheets | RevLog: server-sequenced op log over a Serverpod stream ([17](17-revlog-sync.md)) | Local cache of the file's rows + durable outbox of local ops, sent on reconnect | `sheets_cache_<userId>.db` |
| Slides (v2) | RevLog, like Sheets ([17](17-revlog-sync.md)) | Like Sheets | `slides_cache_<userId>.db` |
| Shell (all homes, incl. Drive) | RPC + `drive.watch` stream | Cached drive listing + queued drive ops + (v2) cached storage usage | device key-value store (§3) |
| Drive uploads (v2) | `drive.createFileUpload` / storage upload / `completeFileUpload` | Persistent upload queue, started when online | `LocalPendingUpload` in the Drive app's local DB (`drive_<userId>.db`, §1.1) |

All local databases are **per user** (file name includes the user's UUID). Signing out keeps them
(encrypted at rest on desktop via OS file protection; on web relies on origin storage);
*Settings › Offline & storage › Clear local data* deletes them (desktop) or clears them (web — DB
deletion is unsupported on web, so tables are truncated and files download again when opened).

Web storage: `sqlite_async` with `sqlite3.wasm` + `db_worker.js` in `web/` (versions must match
the `sqlite_async` version). `WebSqlite.connectToRecommended` picks **OPFS** when available,
else IndexedDB (which keeps the whole DB in memory). Large spreadsheets require OPFS; on the
IndexedDB fallback, offline availability is limited (configurable, default 200k cells total) and
the UI shows "Offline storage is limited in this browser". Build web with `--wasm` (as toptap).

> **As built (Sheets).** The worker doesn't report which storage it chose, so the app checks
> the same prerequisites (`storage_mode_web.dart`: secure context, `FileSystemFileHandle`, a
> working `navigator.storage.getDirectory()`). Without them, Settings › Offline & storage shows
> the warning (`OfflineUsage.warnings`), a toast says it once per user and device, and
> the RevLog client's availability policy keeps the files opened most recently (17, 06 §2.5),
> with 200,000 cells (Sheets) or 50,000 elements (Slides) on such devices.

---

## 1. Write (documents)

### 1.1 Local cache tables (`database: client` style local tables, not synced)

Implemented with raw SQL on `sqlite_async` (`wonky_write/lib/features/offline/write_local_store.dart`,
migrations in `writeCacheMigrations`); the shared opener is `LocalDatabases.open` in `wonky_app`
(`core/local_database.dart`).

| Table | Fields |
|-------|--------|
| `LocalDocument` | `documentUuid`, `itemUuid`, `title`, `itemJson` (drive item, for offline open), `snapshotDelta` (JSON), `snapshotRevision`, `headRevision`, `metaJson`, `role`, `themeId`, `updatedAt`, `lastOpenedAt`, `pinned`, `sizeBytes` |
| `LocalDocumentOp` | `documentUuid`, `revision`, `deltaJson` — server ops after the snapshot (an op log, so a remote op costs a small insert instead of a snapshot rewrite; folded into the snapshot every 200 ops, after a resync and when the document closes) |
| `LocalPendingOp` | `documentUuid`, `seq` (local monotonically increasing), `baseRevision`, `deltaJson`, `clientOpId` (UUIDv7), `createdAt`, `kind` (content kinds / `meta`), `inflight` (may have been sent; resent with the same id) |
| `LocalUndoStack` | `documentUuid`, `stackJson` (serialized undo/redo stacks, best-effort), `docHash` (SHA-256 of the local document the stacks apply to; restored only onto an identical document) |
| `LocalPendingUpload` | `fileUuid` (client-generated UUIDv7), `itemUuid`, `bytes` (blob), `mimeType`, `fileName`, `createdAt`, `attempts`, `lastError` — shared by all apps (images in documents, images over cells, (v2) images on slides, imports); (v2) also `purpose` (`attachment` / `driveFile`), `parentUuid`, `sizeBytes`, `lastModified`, `sourcePath` (desktop: upload from the original path), `state`, `receivedBytes` (resume), `volatile` (web without OPFS, > 5 MB) — [Drive 02 §4.1](wonky_drive/02-files-uploads-previews.md). The Drive app keeps its queue in `drive_<userId>.db` (opened with `LocalDatabases.open`, same migrations helper) |

Consistency: every write stores one consistent capture of the sync state in one transaction — the
server ops since the last write (or a new snapshot) plus the outbox rows that changed. Outbox ops
are always expressed against `headRevision`, so a reload restores exactly `server document +
outbox`. A failed write makes the next one a full rewrite.

**Uploads and the files service.** (v2) Every upload is checked against the storage quota of
the user it is charged to (the item owner for images, the uploader for Drive files); a queued
upload refused for quota stays queued as failed with *Retry* / *Manage storage*
([Drive 03 §6.3](wonky_drive/03-storage-quota.md)). `FileEndpoint` (server `platform/files`) accepts a
**client-supplied `fileUuid`** and is idempotent on it: `createUpload(fileUuid, itemUuid,
fileName, mimeType, size)` → upload description; `completeUpload(fileUuid)`;
`getUrl(fileUuid)` → `{status: pending|ready|failed, url?}` (signed, 15 min). Content may
reference `wonky-file://<fileUuid>` before the bytes arrive; clients render a placeholder while
`status == pending` (uploader's own client renders from local bytes). Uploads are retried from
`LocalPendingUpload` with backoff when online.

### 1.2 Behavior
- Opening a document: render from `LocalDocument` immediately if present (stale-while-
  revalidate), then connect the stream; server sends ops since `snapshotRevision` (or a fresh
  snapshot if too old). The cached drive item is revalidated in the background. A document that
  is not on the device cannot be opened offline ("This document isn't available offline"; it
  re-opens by itself when the connection returns).
- Every local change is written to `LocalPendingOp` **before** sending (durable outbox): the
  controller only sends an op once the write that contains it completed.
- Offline: editing continues; pending ops accumulate (composed into one op per 2 s of typing to
  bound the queue). Remote cursors disappear; presence shows "Offline". The status indicator
  says "Offline" (its tooltip and details dialog: "Offline — changes saved on this device"); the
  shell shows the offline banner.
- Reconnect: client sends pending ops with their `baseRevision`; server transforms them against
  ops since that revision (bounded: if `baseRevision` is older than the server's retained op
  log — 30 days — the server rejects with `RebaseTooOld`, and the client offers *Save my offline
  changes as a copy* which creates a new document from the local state). The copy is created
  like an offline document (client UUIDs) with the local state as its first pending op, so it
  works offline too and keeps every attribute.
- Documents that are not open but have an outbox (edited offline, then closed) are synced in
  the background by a headless sync session when the connection returns.
- Metadata changes (theme, page setup, language, front matter) made offline are queued as
  `LocalPendingOp` rows of kind `meta` and replayed with the same `clientOpId` after connecting.
- Documents become available offline when opened in the last 14 days (max 50) or **pinned**
  (*File › Make available offline*; pinned documents are downloaded with `document.getInfo` +
  `getSnapshot` when pinned and whenever the app comes online). Documents with local changes are
  never evicted. Drive list shows offline badges (pinned: check; recently opened: muted check;
  pinned but not downloaded yet: download arrow) and, while offline, dims files that are not on
  the device (tooltip "This file isn't available offline"; opening shows the same toast).
- New documents can be created offline: client generates `documentUuid` (UUIDv7) and
  `itemUuid`, stores a pending `createDocument` intent; the server endpoint is idempotent on
  these UUIDs. The document opens at once from an empty local copy (revision 0, which is what the
  server creates) and connects once the queued creation went through. Creations from a template
  or with initial content need the server and open when back online.
- Images inserted offline are stored in `LocalPendingUpload` before uploading, render from the
  local bytes (also after a reload) and upload with backoff (2 s → 10 min) when online.
- The signed-in user's profile is kept on the device so the app can start offline with the
  user's local data.
- *Settings › Offline & storage* shows files on the device, pinned files, pending changes,
  pending uploads and storage used, *Clear local data*, and the developer switch *Simulate
  offline* (`ConnectivityService.forceOffline`, the test hook of suite 15 §9: streams are dropped
  and every repository call fails like a network error; also the command
  `write.offline.simulate` for the UI bridge; remembered across reloads).

Details of the OT protocol are in [Write 03 · Sync protocol](wonky_write/03-sync-protocol.md).

## 2. Sheets and Slides (RevLog)

Spreadsheets and decks sync through **RevLog**, specified in [17 · RevLog sync](17-revlog-sync.md).
In short:

- **One file = one op log.** Each spreadsheet or deck is a file with a head revision. The server
  applies each op (a change set of row changes) in one transaction to the domain tables, gives it
  the next revision and streams it to every other open connection (about one round trip).
- **Offline.** The client keeps a local cache of the file's rows (`rev_row`) and a durable outbox
  of its own ops. A file opened before (or created on the device) opens offline from the cache;
  edits go into the outbox and are sent when the connection returns. Conflicts: last arrival
  wins per column; a deleted row stays deleted; the outcome of each op is reported back.
- **Opening.** A file not on the device loads with bootstrap pages: the structure first, then the
  cells of the viewport, then the rest (Sheets 02 §6); decks load in one page.
- **Access.** Every submit and every stream checks the drive ACL; protected ranges are enforced
  by the server.
- **Server writes** (MCP, AI, imports, scripts, restores) are submitted as server changes with the
  same rules, in op groups, with records for undo.

Sheets and Slides use no CRDT engine, sync spaces, active set or reserved spaces. The
remaining code of the former engine (`third_party/serverpod_offline_sync`, `platform/spaces`,
`wonky_sync_kit*`) is removed by the last step of M13 ([14](14-roadmap.md)).

## 3. Shell (drive)
Drive listing cache + `PendingDriveOp` queue (rename, move, star, trash, registerSpreadsheet,
(v2) registerPresentation, createDocument) replayed in order on reconnect.
`registerSpreadsheet` / `registerPresentation` create the RevLog file of a spreadsheet or deck
made on the device with `initialize: false`, so the creation op in the device's outbox becomes
its first revision ([05 §2](05-drive-and-files.md), [17](17-revlog-sync.md) part 4 §5). (v2)
The cache also keeps the last `StorageUsage` (meter offline). Each app caches the items of its home's kind;
the Drive app caches the last 500 items of any kind plus all pinned items. Drive's upload queue
is in its own local DB (§1.1), not in the key-value store, because it holds file bytes. Both are per user (`u.<userUuid>.` keys) in the
device key-value store (`shared_preferences`; the data is small and needs no queries, so the
shell does not use a separate `shell_<userId>.db`). A queued `createDocument` whose folder is gone
by the time it replays is created in My Drive instead.

## 4. Scale limits

| Limit | Value | Enforced by |
|-------|-------|-------------|
| Cells per spreadsheet | `sheets.maxCellsPerSpreadsheet` (1,000,000) | the server on every op (`limitExceeded`), the client's cell counters |
| Sheets per spreadsheet | `sheets.maxSheetsPerSpreadsheet` | the server on every op |

Raising them is gated by the performance gates of [17](17-revlog-sync.md) part 7.
