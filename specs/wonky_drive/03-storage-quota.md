# Drive 03 · Storage Quota (50 MB per user)

Every user has **50 MB** of storage. This spec defines what counts, how usage is accounted on
the server, where the quota is enforced (every byte-adding path), the errors, the UI that shows
it everywhere (meters, banners, dialogs, the Storage page), ownership transfer, trash, and the
backfill for existing users. It is authoritative for anything that counts or blocks storage
(other specs link here).

## 1. Rules at a glance

| Rule | Value |
|------|-------|
| Quota | `wonky.drive.quotaBytesPerUser` (default 52,428,800 = 50 × 1024 × 1024), shown as "50 MB" |
| Who pays | The **owner** of a drive item, for the item's content and the images stored in it — no matter who added them |
| What counts | Content of documents, spreadsheets and presentations (server estimate), uploaded files, images/attachments stored in items, trashed items until purged (§2) |
| What doesn't | Version-history snapshots, thumbnails and previews, exports, import sources, avatars, board screenshots (`StoredFileKind.boardScreenshot`, [16 §5.3](../16-bugs-and-improvements.md)), script bytecode, server caches, local device data |
| Blocked when it doesn't fit | Uploads, image inserts, imports and conversions, copies, creation from non-empty templates, ownership transfer to the user (§7) |
| Never blocked | Editing existing content (typing, cells, slides, formatting), creating blank items, offline sync, version restore, restore from trash, deleting anything |
| Over quota | Possible (content growth, backfill, estimates): a banner everywhere and every blocked path refuses until usage is back under the quota (§6.2) |
| Max single upload | min(available bytes, `wonky.files.maxFileUploadBytes` = 50 MB) |

## 2. What counts

| Source | Counted | Charged to | Measured as | Updated |
|--------|---------|------------|-------------|---------|
| Document content | ✓ | item owner | UTF-8 length of the current Delta JSON (snapshot + ops since, i.e. the document as it is now; the op log is history and is not counted) | With the throttled search-text update of the OT service (≤ every 10 s while edited) and on import/copy/restore |
| Spreadsheet content | ✓ | item owner | `SheetsSizeEstimator`: a compact **content** estimate (user decision, §11): 2 KB per spreadsheet + 256 B per sheet + each non-empty cell (16 B + the bytes of its non-null value/format columns) + each row/column with non-default height/width, hidden or format (16 B + its properties) + 256 B per chart, image, pivot, rule, range, filter or script object (+ script source); default rows/columns and empty cells count nothing | By the change-log consumer, at most every 5 min per space (trailing), after server imports, copies, version restores, and nightly by the reconcile (§4.3) |
| Presentation content | ✓ | item owner | Same estimator over the Slides synced tables (Slides 02) | Same cadence (Slides change log) |
| Uploaded file (`file` kind) | ✓ | item owner (the uploader) | Exact stored size | At `completeFileUpload` (reserved at `createFileUpload`, §5) |
| Images / attachments in documents, over cells, on slides (`StoredFile.kind == image`) | ✓ | owner of the item they belong to | Exact stored size, summed in `DriveItem.attachmentBytes` | At upload completion (+), when the weekly orphan cleanup deletes an unreferenced image (−) |
| Previous versions of uploaded files (P2) | ✓ (decided, v2 review Q14; 02 §9) | item owner | Exact | At replace / version delete |
| Trashed items | ✓ until permanently deleted (30 days) | item owner | As above, shown as *Trash* | — |
| Imported originals kept for reference | — (none are kept today; if a "keep original" option is added it counts as a `file`) | | | |
| Version-history snapshots and op logs | ✗ | | | |
| Thumbnails, file previews (`thumbnail`, `preview`) | ✗ | | | |
| Exports and import sources (expire after 24 h) | ✗ | | | |
| Avatars, script bytecode, assistant history, comments | ✗ | | | |
| Folders | ✗ (0 bytes) | | | |
| Built-in templates | ✗ (not owned by a user); copies made from them count for their owner | | | |

The **counted size of an item** is `DriveItem.sizeBytes + DriveItem.attachmentBytes`. It is
what the list's *File size* column, the details panel and the Storage page show, so the numbers
always add up to the meter.

Estimates are deliberately simple and stable: the same content always gives the same number,
and the numbers only change when content changes. They are labeled "about" nowhere — users see
one number per item.

## 3. Configuration and the usage view

```yaml
# config/<runMode>.yaml (v2)
wonky:
  drive:
    quotaBytesPerUser: 52428800      # WONKY_DRIVE_QUOTA_BYTES_PER_USER
    warnAtPercent: 90                # banner threshold
    maxPendingUploadsPerUser: 100
  files:
    maxFileUploadBytes: 52428800     # cap for one uploaded file (≤ quota)
    maxImageUploadBytes: 20971520    # existing
    maxImportUploadBytes: 104857600  # existing (import sources are temporary)
    uploadsPerHour: 200              # rate limits, suite 13 §6
    uploadBytesPerDay: 524288000
```

A per-user override (`UserStorage.quotaBytesOverride`) exists for operators (set through the
database or a server-admin MCP tool later, P2); there is no UI to buy or request more.

`StorageUsage` (existing model, extended, v2) is returned by `drive.storageUsage()`, pushed on
the `drive.watch` stream as `DriveChange(kind: storageChanged, storage: …)` whenever the
caller's counters change (debounced 1 s; the event's `itemUuid` is the nil UUID and `item`
is null), included in the result of every byte-adding endpoint
that returns a view (e.g. `FileUploadStart.storage`), and cached in the shell for offline
display.

```yaml
class: StorageUsage
fields:
  quotaBytes: int
  bytesUsed: int                # counted usage incl. trash (existing field, new meaning: §2 only)
  reservedBytes: int            # pending uploads (§5)
  availableBytes: int           # max(0, quotaBytes - bytesUsed - reservedBytes)
  overQuota: bool               # bytesUsed > quotaBytes
  documentsBytes: int           # non-trashed, incl. their attachments
  spreadsheetsBytes: int
  presentationsBytes: int
  filesBytes: int
  trashBytes: int               # all trashed items
  documents: int                # counts (existing)
  spreadsheets: int
  presentations: int
  files: int
  folders: int
  maxFileUploadBytes: int       # min(availableBytes, config cap)
  calculating: bool             # backfill for this user not finished yet (§9)
```

**Display.** Bytes are shown with binary units labeled KB/MB (as `formatBytes` does today):
one decimal below 100 ("12.3 MB"), none above; "0 bytes", "820 KB". The quota is always "50 MB".
The meter text is "12.3 MB of 50 MB used".

## 4. Accounting model (server)

### 4.1 Tables

```yaml
# platform/storage/user_storage.spy.yaml (new)
### Storage counters of a user (Drive 03). Maintained transactionally by StorageService;
### reconciled nightly from the source rows.
class: UserStorage
table: user_storage
fields:
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  usedBytes: int, default=0          # Σ counted size of owned items (incl. trash)
  reservedBytes: int, default=0      # Σ open reservations
  documentsBytes: int, default=0
  spreadsheetsBytes: int, default=0
  presentationsBytes: int, default=0
  filesBytes: int, default=0
  trashBytes: int, default=0
  quotaBytesOverride: int?           # null = config default
  overQuotaSince: DateTime?          # set/cleared when usedBytes crosses the quota
  reconciledAt: DateTime?            # null until the first reconcile/backfill (§9)
  updatedAt: DateTime
indexes:
  user_storage_user_idx: { fields: userId, unique: true }

# platform/storage/storage_reservation.spy.yaml (new)
### Quota held for an upload that has not completed (Drive 03 §5).
class: StorageReservation
table: storage_reservation
fields:
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  fileUuid: UuidValue                # the StoredFile being uploaded
  itemId: int?, relation(parent=drive_item, onDelete=Cascade)
  bytes: int
  createdAt: DateTime
  expiresAt: DateTime                # createdAt + 24 h
indexes:
  storage_reservation_file_idx: { fields: fileUuid, unique: true }
  storage_reservation_user_idx: { fields: userId }
  storage_reservation_expiry_idx: { fields: expiresAt }   # as built (D-1): expiry sweeps
```

Both tables are `serverOnly` (as built, D-1).

`DriveItem` gets `attachmentBytes` (02 §1.1); `sizeBytes` keeps its column with the meaning
of §2 (content estimate, or the file size for files).

### 4.2 `StorageService` (`wonky_server/lib/src/platform/storage/`)

The only code that changes `user_storage`. Every source change calls it **in the same
database transaction** as the change itself:

| Method | Called by |
|--------|-----------|
| `reserve(session, userId, fileUuid, itemId?, bytes)` → throws `quotaExceeded` | `drive.createFileUpload`, `file.createUpload(kind: image)` |
| `commitReservation(session, fileUuid, actualBytes)` (reserved → used; the item's `sizeBytes`/`attachmentBytes` updated) | `drive.completeFileUpload`, `file.completeUpload` |
| `releaseReservation(session, fileUuid)` | cancel, failure, expiry |
| `checkRoom(session, userId, bytes)` → throws `quotaExceeded` | copies, imports, conversions, template creations, ownership transfer |
| `setItemSize(session, item, sizeBytes)` / `addAttachment(item, ±bytes)` (never throw) | OT size update, `SheetsSizeEstimator`, Slides estimator, orphan cleanup |
| `onTrash(items)`, `onRestore(items)` (move bytes between kind counters and `trashBytes`) | `drive.trash` / `restore` / purge |
| `onDelete(items)` (subtract) | delete forever, trash purge, account deletion |
| `onOwnerChange(item, fromUserId, toUserId)` | ownership transfer (§7.3) |
| `usage(session, userId)` → `StorageUsage` | endpoints, MCP |

Concurrency: the room check and the reservation are one conditional statement, so parallel
uploads can't overshoot:

```sql
UPDATE user_storage
   SET "reservedBytes" = "reservedBytes" + @n, "updatedAt" = now()
 WHERE "userId" = @u
   AND "usedBytes" + "reservedBytes" + @n <= @quota
RETURNING "usedBytes", "reservedBytes";
-- no row → quotaExceeded
```

`checkRoom` takes `SELECT … FOR UPDATE` on the user's row for the rest of the transaction.
Content growth (`setItemSize`) adds unconditionally (`usedBytes = usedBytes + delta`), then sets
or clears `overQuotaSince` and posts `storageChanged` to the owner's drive channel (after
commit).

### 4.3 Reconciliation

`StorageReconcileFutureCall` (nightly, per user in batches of 200; also on demand after a
backfill or by an operator) recomputes every counter from the sources (`drive_item` sizes by
owner, kind and trash state; open reservations; expired reservations are deleted first),
writes the corrected row and logs `storage.drift {userId, field, before, after}` when a counter
was off by more than 1 % or 64 KB. Before recounting, it re-estimates the user's spreadsheets
(`StorageMaintenance.nightlyKinds`), so a changed estimator corrects every user by the next
night and a missed trailing refresh can't leave a stale size. A test asserts that after any sequence of service calls the
reconciled row equals the maintained one.

## 5. Reservations

- `reserve` happens **before** bytes are uploaded (declared size), so a 40 MB upload can't
  start when 30 MB are free. A user can have at most `maxPendingUploadsPerUser` (100) open
  reservations (`limitExceeded` "Too many uploads at once. Wait for some to finish.").
- `commitReservation` uses the **actual** size from storage; if it is larger than reserved and
  no longer fits, the upload fails (`quotaExceeded`) and the bytes are deleted.
- Expired reservations (24 h) are released by `drive.expireUploads` (02 §2).
- `availableBytes` subtracts reservations, so the meter shows uploads in flight as used.

## 6. UI

### 6.1 Storage meter (`StorageMeter`, `wonky_app/lib/src/storage/`)

- In the **bottom section of every home's left menu** (Drive, Write, Sheets, Slides; suite 03
  §3.3), in Settings › Wonky Work › Storage, and at the top of Drive's Storage page (large).
- A 4 px `ShadProgress`-style bar + "12.3 MB of 50 MB used". Color: `primary` below
  `warnAtPercent`, `warning` token from 90 %, `destructive` at ≥ 100 % ("50.4 MB of 50 MB used —
  over quota"). While `calculating`: indeterminate bar + "Calculating storage…".
- Click (or Enter) runs `shell.storage.open` → Drive's Storage page (same tab; cross-app from
  the other homes). Tooltip: "Storage is shared by Wonky Drive, Write, Sheets and Slides."
- Offline: last known value with "(offline)" in the tooltip.

### 6.2 Banners (`StorageBanner`)

Shown below the top bar in homes and below the editor header in editors (one line, `warning` or
`destructive` tinted, with a close ×):

| State | Text | Action | Dismissal |
|-------|------|--------|-----------|
| ≥ 90 % | "You've used 46.1 MB of your 50 MB storage." | *Manage storage* | per device for 7 days |
| Over quota | "You're out of storage. You can keep editing, but you can't upload files, add images, import, or make copies until you free up space." | *Manage storage* | homes: not dismissible; editors: once per day per device |

Editors show the banner only for items the user **owns** (an editor of Anna's document isn't
told about their own quota, but gets the dialog of §6.3 if Anna is full).

### 6.3 *Out of storage* dialog (`QuotaExceededDialog`)

Shown when a byte-adding action is refused (server error `quotaExceeded`, §7.1) or the client
pre-check fails. `ShadDialog.alert`, built with `WonkyDialogSpec` (MCP-operable):

| Variant | Title | Body | Buttons |
|---------|-------|------|---------|
| Own quota | "You're out of storage" | "This needs 12.4 MB, but you have 3.1 MB left of your 50 MB. Free up space in Wonky Drive by deleting files you no longer need and emptying the trash." | **Manage storage** · Close |
| Owner's quota (editor adds an image to someone else's item) | "Anna Berg is out of storage" | "Images added to this document count against the owner's storage. Ask Anna Berg to free up space, or add the image to a document you own." | Close |
| Batch upload | "Not enough storage for all files" | "These 5 files need 62.0 MB, but you have 18.5 MB left. Upload the files that fit, or free up space first." | **Upload the files that fit** · Manage storage · Cancel |
| Ownership transfer (requester) | "Bo Chen doesn't have enough storage" | "Bo Chen needs 8.2 MB free to take ownership of "Q3 deck". Ask them to free up space first." | Close |
| Ownership transfer (new owner accepting) | "You don't have enough storage" | "Taking ownership of "Q3 deck" needs 8.2 MB, but you have 2.0 MB left." | **Manage storage** · Close |
| File too large | "This file is too large" | "Files can be at most 50 MB." (or "…at most 18.5 MB right now, because that's how much storage you have left.") | Close |

Image inserts that fail **after** being placed (uploaded in the background, e.g. offline)
leave the image as a placeholder "Not uploaded — out of storage" with *Retry* and *Remove*
(Write 04 §17, Sheets 08 §10, Slides 03).

### 6.4 Storage page (`/drive/storage`, Drive app)

```
┌ Storage ────────────────────────────────────────────────────────────────────────┐
│ 46.1 MB of 50 MB used                                         [Empty trash]      │
│ ███████████████████████████████████████████████░░░░░  92 %                       │
│ ■ Documents 4.2 MB  ■ Spreadsheets 9.8 MB  ■ Presentations 6.0 MB  ■ Files 18.0 MB│
│ ■ Trash 8.1 MB      □ Free 3.9 MB                                                 │
├──────────────────────────────────────────────────────────────────────────────────┤
│ Free up space                                                                     │
│ ┌──────────────────────┐ ┌──────────────────────────┐ ┌────────────────────────┐ │
│ │ Empty trash           │ │ Large files               │ │ Not opened in 6 months │ │
│ │ Frees 8.1 MB          │ │ 6 files over 1 MB         │ │ 14 files · 7.4 MB      │ │
│ │ [Empty trash]         │ │ [Review]                  │ │ [Review]               │ │
│ └──────────────────────┘ └──────────────────────────┘ └────────────────────────┘ │
├──────────────────────────────────────────────────────────────────────────────────┤
│ Items using storage                       Type: All ▾        Sort: Size ▾        │
│ Name                     Kind          Location        Last opened   Storage  ⋮  │
│ 🎵 interview.m4a         Audio         My Drive        3 months ago  18.0 MB  ⋮  │
│ 📊 Sales 2025            Spreadsheet   Finance         Yesterday      6.1 MB  ⋮  │
│ 🗑 old-scan.pdf (trash)  PDF           Trash           —              4.0 MB  ⋮  │
│ …                                                                                 │
│ What counts? Documents, spreadsheets, presentations, uploaded files and images in │
│ your files, including the trash. Version history, thumbnails and exports don't.   │
└──────────────────────────────────────────────────────────────────────────────────┘
```

- **Usage bar** (stacked, colors `chart1–5` + muted for free; legend with values; screen
  readers get "Documents 4.2 MB, …" as one label). Over quota: the bar is full in `destructive`
  with "over by 0.4 MB".
- **Free up space** cards (shown when relevant): *Empty trash* (if `trashBytes > 0`; confirm
  "Permanently delete 23 items in the trash? This frees 8.1 MB and can't be undone." → 
  `shell.drive.emptyTrash`); *Large files* (owned, ≥ 1 MB; filters the table); *Not opened in 6
  months* (owned, ≥ 256 KB, `lastOpenedAt` older than 180 days or never; filters the table);
  *Duplicate files* (P1: same name + size + MIME); *Old file versions* (P2).
- **Items using storage**: owned items (incl. trashed) sorted by counted size desc, paged 50,
  from `drive.listByStorage(filter, cursor)`; type filter (All, Documents, Spreadsheets,
  Presentations, Files, Trash); multi-select with *Move to trash*, *Delete forever* (trashed
  items only), *Download*; row ⋮ = the normal item menu. Opening a row opens the item.
- The page updates live from `storageChanged` events.

### 6.5 Elsewhere

- **Details panel** (all homes): "Storage used: 6.1 MB" with "Counts against Anna Berg's
  storage" when the viewer isn't the owner; for folders: nothing.
- **List/grid**: the *File size* column shows the counted size; folders "—".
- **Settings › Wonky Work › Storage** (`/settings/storage`, suite 04 §4): meter, breakdown,
  "What counts" text, *Manage storage in Wonky Drive* (→ `/drive/storage`).
- **Upload panel** rows that fail on quota: "Not uploaded — you're out of storage" + *Manage
  storage*.
- **New ▸ From template** on a full account: templates show a tooltip "Not enough storage"
  and are disabled when the template's size doesn't fit (`TemplateView.sizeBytes`, v2).
- **Copy / Make a copy** dialogs: disabled *OK* with "Not enough storage (needs 6.1 MB)".

### 6.6 MCP and AI

`drive.get_storage` returns `StorageUsage` as JSON; every byte-adding tool's result carries
`storage: {used_bytes, quota_bytes, available_bytes}`; refusals are `quota_exceeded` errors
with the details of §7.1 (suite 09 §4). The assistant explains the error to the user and never
deletes or empties the trash to make room on its own (destructive-confirmation rule, suite 10).

## 7. Enforcement

### 7.1 Error

New `WonkyErrorCode.quotaExceeded` (`wonky_server/lib/src/platform/common/`) with
`detailsJson`:

```json
{ "neededBytes": 12998246, "availableBytes": 3250585, "quotaBytes": 52428800,
  "chargedUserId": 42, "chargedUserName": "Anna Berg", "isCaller": false,
  "reason": "upload" }
```

`reason` ∈ `upload`, `image`, `import`, `convert`, `copy`, `template`, `transfer`,
`restoreVersionCopy`. (As built, D-1: the JSON is the protocol model `QuotaExceededDetails`,
so clients parse it with `QuotaExceededDetails.fromJson`; `reason` is a string — `import` is a
reserved enum value — with server constants `QuotaReason`.) Message: "Not enough storage: this needs 12.4 MB, 3.1 MB is available."
The client maps it to the dialog variants of §6.3 (`QuotaErrorPresenter`, `wonky_app`).

### 7.2 Enforcement points by endpoint

| Path (endpoint / tool) | Bytes checked | Charged to | Behavior |
|------------------------|---------------|------------|----------|
| `drive.createFileUpload` (Drive uploads), MCP `drive.upload_file` / `drive.create_upload` | declared file size | uploader | `reserve`; refuse |
| `file.createUpload(kind: image)` — images in Write, over cells (Sheets), on slides, image-by-URL copies stored by the server | image size | **owner of `itemUuid`** | `reserve` on the owner; refuse (owner variant if caller ≠ owner) |
| `file.createUpload(kind: importSource)` | — (temporary, 24 h) | — | size cap only |
| `drive.import` (server import pipeline), `drive.convertFile`, MCP `drive.import`/`drive.convert_file` | source file size before work; real content size after | importer | `checkRoom` twice; refuse; no item is created on refusal |
| Client-side imports (Write documents, Sheets ≤ 5 MB XLSX/CSV, app import routes of 02 §7.2) | file size | importer | client pre-check against `availableBytes` + `drive.checkRoom(bytes)` RPC before creating; offline imports are not blocked (content arrives through sync) |
| `drive.copy`, *Make a copy* in editors, MCP `drive.copy` | counted size of the source (content + attachments) | the copier (new owner) | `checkRoom`; refuse |
| `versions` *Make a copy* of a version | version content size | caller | `checkRoom`; refuse |
| `drive.createDocument/createSpreadsheet/createPresentation` with `templateUuid` or initial content; MCP `drive.create_*` with content | template/content size | creator | `checkRoom`; refuse. Blank items: 0 bytes, always allowed |
| `drive.registerSpreadsheet` / `registerPresentation` (offline-first creations) | 0 | owner | never refused (the content arrives as the file's RevLog ops) |
| `sharing.transferOwnership` (request and accept) | counted size of the item | new owner | `checkRoom` at request (pre-check) and at accept; refuse |
| `drive.restore` (from trash) | 0 (trash already counts) | — | never refused |
| `versions.restore` | content change = an edit | owner | never refused |
| Write OT ops, Sheets/Slides sync, text edits through MCP/AI/scripts | growth via size estimates | owner | **never refused**; may lead to over quota |
| `drive.setThumbnail`, previews, exports, avatars, (M12) board screenshots (`board.createScreenshotUpload`: PNG/JPEG, 5 MB each) | not counted | — | existing size caps only |

`drive.checkRoom(int bytes, UuidValue? itemUuid)` (new, cheap, read-only) lets clients
pre-check paths where the bytes don't go through an upload (client-side imports, large pastes
of images in a batch); it never reserves.

### 7.3 Ownership transfer

- `sharing.transferOwnership(itemUuid, newOwnerUserId)` checks the new owner's room for the
  item's counted size and refuses up front ("Bo Chen doesn't have enough storage").
- Acceptance (the new owner) runs the check again inside the transfer transaction; on success
  `onOwnerChange` moves the counted size between the two users' counters and re-charges the
  item's images (`attachmentBytes` move with the item). Transferring a folder transfers only
  the folder (0 bytes); its children keep their owners (suite 06 §4).
- Deleting an account with *transfer files* first runs the same checks per item and lists the
  items that didn't fit (they stay with the deleted user's choice: delete or skip).

### 7.4 Trash

- Trashing moves an item's bytes from its kind counter to `trashBytes`; usage doesn't change.
- Restoring moves them back; never blocked.
- *Delete forever*, *Empty trash* and the 30-day purge subtract the bytes in the same
  transaction as the row delete; the meter updates through `storageChanged`.
- The Storage page and the over-quota banner both point at *Empty trash* first when trash is
  ≥ 10 % of usage.

## 8. Edge cases

- **Editors adding images to someone else's item** charge the owner (§2). The over-quota
  owner variant of the dialog explains it; the editor's own quota is unaffected.
- **Shared folders**: items created or uploaded into someone else's folder belong to (and are
  charged to) their creator, as today; moving an item doesn't change its owner.
- **Offline growth**: spreadsheets and presentations grow through sync and documents through
  the OT queue; none of it can be refused. Images queued offline are refused on upload (§6.3)
  and stay as placeholders.
- **Estimate jumps**: a spreadsheet's estimate is refreshed at most every 5 minutes; usage may
  briefly lag. Byte-adding checks always use the stored counters (no on-demand estimation in
  the request path).
- **Account deletion** removes the user's items (and `user_storage` by cascade).
- **Templates published by users** (`setTemplate`) count for their owner like any item; copies
  count for the copier.

## 9. Migration and backfill for existing users

1. **Schema migration** (one Serverpod migration, M8): `user_storage`, `storage_reservation`,
   the new `DriveItem` columns (02 §1.1), `StoredFileKind`/`DriveItemKind`/`FileCategory`
   enum values. All additive; no data rewritten in `migration.sql`.
2. **Backfill** (`StorageBackfillFutureCall`, scheduled once at server start when
   `user_storage` has no rows or the stored backfill version is older; idempotent, resumable,
   100 items per batch, under a cluster advisory lock, suite 13 §4):
   - documents: recompute `sizeBytes` from the current content (§2);
   - spreadsheets (and presentations): run `SheetsSizeEstimator` per file;
   - `attachmentBytes`: sum of ready `image` StoredFiles per `itemId`;
   - then a full reconcile (§4.3) per user, setting `reconciledAt`.
   While a user's row has `reconciledAt == null`, `StorageUsage.calculating` is true, the meter
   shows "Calculating storage…" and enforcement **fails open** (uploads are allowed; the
   reconcile catches up). Expected duration: minutes (the backfill reads each file once).
3. **Users over 50 MB after the backfill** keep all their data. They get the over-quota
   banner and one in-app notification (`NotificationKind.storage`, new): "Wonky Work now
   includes 50 MB of storage per person. You're using 73.2 MB — you can keep editing, but free
   up space to upload or copy files again. [Manage storage]". No email.
4. **Release note**: `StorageUsage.bytesUsed` changes meaning (it previously added every
   `StoredFile` the user uploaded, including thumbnails and version snapshots).

**Decided (v2 review, Q15):** **no grace period** for existing users who are over the quota
after the backfill: the over-quota state is non-destructive and blocks only new bytes; a
temporary higher quota would add a second rule users must understand.

**Decided (v2 review, Q16):** restores from trash are **never blocked** (§7.2): trashed items
already count, so a restore adds no bytes. D3's "restore of trashed items" enforcement point is
dropped; only paths that add bytes are checked.

## 10. Acceptance criteria

- **AC-D3.1** With 49 MB used, uploading a 2 MB file fails before any byte is sent; the dialog
  shows "needs 2.0 MB … 1.0 MB left"; the meter shows the warning color (98 %).
- **AC-D3.2** Two parallel 30 MB uploads with 50 MB free: exactly one succeeds; the other fails
  with `quotaExceeded`; `reservedBytes` returns to 0.
- **AC-D3.3** An editor inserting a 3 MB image into a document whose owner has 1 MB left gets
  the *owner* dialog; the owner's usage is unchanged.
- **AC-D3.4** Trashing an 8 MB file moves 8 MB to *Trash* (usage unchanged); *Empty trash*
  frees it; the meter in the open Write home updates within 2 s.
- **AC-D3.5** Over quota, typing in a document, editing cells and slides keeps working; *Make
  a copy* and image inserts are refused; deleting enough files clears the banner live.
- **AC-D3.6** Transfer of a 10 MB spreadsheet to a user with 5 MB left is refused at request
  time; after they free space, acceptance succeeds and both meters update.
- **AC-D3.7** Reconcile after a randomized sequence of 1,000 service calls (property test)
  produces the same counters as the incremental maintenance.
- **AC-D3.8** Backfill on a copy of production data completes, sets `reconciledAt` for every
  user and leaves the server responsive (no request blocked > 1 s by it).

## 11. As built (D-9)

Code: `wonky_server/lib/src/platform/storage/` — `DbStorageService` (the installed
`StorageService.instance`; `PassThroughStorageService` stays for tests that bypass the quota,
`StorageService.resetInstance()` restores the default), `StorageCounters` (SQL over
`user_storage`), `ContentSizes` (estimators and cadence), `StorageMaintenance` (backfill,
reconcile), `StorageFutureCall`, `StorageEvents`, `StorageHooks` (one-line enforcement hooks),
`StorageListing` (`drive.listByStorage`).

- **Accounting** (§4.2). `setItemSize` / `addAttachment` / `commitReservation` change the
  `drive_item` column and add the difference to the owner's counter (kind, or `trashBytes`
  while trashed; folders count nothing) under the user's row lock. The structural callbacks
  `onTrash`, `onRestore`, `onDelete`, `onOwnerChange` are called **after** the change in its
  transaction and **recount** the affected owners' item-derived counters from `drive_item`
  (same query as the reconcile, one user) — robust against stale item objects and subtrees
  with several owners. `usedBytes` is always the sum of the five counters. `overQuotaSince` is
  set/cleared by every counter write.
- **Reservations** (§5): `reserve` is the conditional `UPDATE` of §4.2 (fail open while
  `reconciledAt` is null), idempotent per `fileUuid`, capped at `maxPendingUploadsPerUser`
  open reservations (`limitExceeded`). `commitReservation` without a reservation sets a file's
  exact size (idempotent) and charges nothing for images. Image uploads
  (`file.createUpload(kind: image)`) reserve on the **item owner** in the transaction that
  inserts the `StoredFile` and commit/release in `file.completeUpload`; deleting a stored file
  releases its reservation.
- **Content sizes** (§2): documents = UTF-8 length of the Delta JSON (`DocumentSize`), set on
  create/copy/import/version copy and by the OT service's throttled update. RevLog files
  (spreadsheets, decks): `RevFileSizeEstimator` (generic over table names; Slides registers its
  deck estimator with `ContentSizes.register(DriveItemKind.presentation, …)`) sums
  `pg_column_size` of the file's rows by the `fileId` index. `SheetsSizeEstimator` covers
  every Sheets table except `script_build` (bytecode), with cells read sheet by sheet
  ([17](../17-revlog-sync.md) part 2 §2.2); the op log is history and does not count. The
  RevLog `contentSize` hook calls `ContentSizes.onSpaceChanged` (immediately when the last
  estimate is ≥ 5 min old, else one trailing `StorageFutureCall.refreshItemSize` at the end of
  the interval); server creations, copies and imports refresh at once.
- **Spike S-D3** (index-driven query on the former CRDT engine's tables, before M13; embedded
  Postgres on the laptop): 100k cells → estimate 12.9 MB in ~35 ms; 1M cells → 125 MB in ~3 s; a small space next to 2M foreign cells → 6 ms
  (cost follows the space, not the table; a plain `WHERE "spaceId" = …` would scan the whole
  table — no index on `spaceId`). The 5-minute cadence is confirmed. **Finding:** a cell row
  costs ~125 bytes, so 50 MB holds ~400k cells, less than `maxCellsPerSpreadsheet` (1M) —
  resolved by the content estimate below.
- **Backfill dry run (D-18)** on the development database (no production copy yet; 43 users,
  41 spreadsheets, 69 documents, 3 uploads): the backfill ran 10 s after `serverpod start`
  and left no user pending (43/43 with `reconciledAt`), nobody over the quota or in the 90 %
  warning, median usage 85 KB, total 12 MB. Spreadsheets dominate: the largest user has
  8.4 MB, one sheet of 50k cells estimated at 8.29 MB (**~166 B/cell**, slightly above
  S-D3's 125 B because of formats and the change log); and **every new spreadsheet costs
  ~80 KB before any cell is typed** (its 1,000 `sheet_row` + 26 `sheet_column` rows: the
  welcome spreadsheet is 83 KB with 24 cells, a 12-cell CSV import 82 KB), so 50 MB hold
  ~600 empty spreadsheets. Documents are small (1.4 KB average).
- **Decided: a compact content estimate for spreadsheets** (user, after D-18: "an estimate is
  ok"). `SheetsSizeEstimator` no longer sums `pg_column_size` of the stored rows; it counts
  content (§2 table): a 2 KB base per spreadsheet and 256 B per sheet; cells, `sheet_row` and
  `sheet_column` only when they carry something — 16 B plus the bytes of their non-null
  value/format columns (`SheetsSizeEstimator.valueBytes`, derived from the generated tables:
  text by UTF-8 length, numbers/dates 8, ints 4, enums 1, `true` flags 1; ids, references,
  sort keys and `createdAt` never count); 256 B per row of every other table (charts and
  images as `embedded_object`, pivots, merges, groups, named/protected ranges, CF/DV rules,
  filters, filter views, bandings, script projects/triggers/properties, macros), script files
  256 B + their source. The query is one `UNION ALL` over the tables (since M13 by `fileId`,
  cells by sheet) — only the per-row expression differs from the generic estimator;
  `RevFileSizeEstimator` keeps `pg_column_size` as its default (`rowBytes`, `baseBytes` are the
  override points). `StorageHooks.sheetsEstimate` (template and sheet-list pre-checks) uses the
  same constants and mirrors `SpreadsheetFactory` (cells it writes, bold, number formats,
  formula references in stored form), so the pre-check and the measured size agree (the
  *Monthly budget* template: 4,571 B pre-check, 4,555 B measured). Existing users are
  corrected without a migration: the nightly reconcile re-estimates every spreadsheet before
  recounting (§4.3) — the first night logs one `storage.drift` per user with spreadsheets.
  Numbers (embedded Postgres, laptop; old = `pg_column_size` of the same rows): a new empty
  spreadsheet **82,410 B → 2,304 B** (base + one sheet; its 1,000 default rows and 26 columns
  count nothing); a 50k-cell sheet (5,000 rows × 10 columns, one short text and nine number
  columns, no formats) **6.78 MB (136 B/cell) → 1.23 MB (24.7 B/cell)**, estimated in 86 ms
  (old query 57 ms). 50 MB now hold ~2M such cells, above `maxCellsPerSpreadsheet` (1M).
  Slides keeps `pg_column_size` (`SlidesSizeEstimator`): a new empty deck costs **~18 KB**
  (theme, master and layout rows) — the same effect, 4× smaller; left as is (TODO.md).
- **Enforcement** (§7.2) as built: uploads (D-8) and image uploads reserve; `drive.import` /
  MCP `drive.import` check the source size before any work and, for documents, the converted
  content + image bytes before anything is stored (spreadsheets: the source size; the real size
  is the estimate after creation); `drive.convertFile` pre-checks with `convert` (D-8) and the
  import checks again; `sheetsImport.importInto` checks the **spreadsheet owner** with the
  upload size before queueing; images stored by imports and MCP `write.insert_image` are
  charged to the item owner (`attachmentBytes`); copies (`drive.copy`, MCP `drive.copy`)
  check the source's counted size for the copier; `writeHistory.copyVersion`
  (`restoreVersionCopy`); creations with a template or initial content (built-in spreadsheet
  templates use a cell-count pre-estimate, `StorageHooks.sheetsEstimate`;
  `TemplateView.sizeBytes` is filled the same way); `sharing.transferOwnership` at request
  (new owner, `isCaller: false`) and inside the acceptance transaction (refusal leaves the
  offer open). Never refused: restores, OT/sync/MCP edits, blank items,
  `registerSpreadsheet`/`registerPresentation`. MCP maps the error to `quota_exceeded` with the
  `QuotaExceededDetails` as `details`.
- **Events**: `storageChanged` is posted (debounced 1 s per user, `StorageEvents.debounce`)
  on the user's drive channel; `drive.watch` turns it into `DriveChange(kind:
  storageChanged, itemUuid: nil, storage: usage)`.
- **Backfill** (§9): there is no stored backfill version — a user is *pending* while they have
  no `user_storage` row or `reconciledAt` is null. New users get a reconciled row at sign-up
  (`UserService.ensureProfile`). `StorageFutureCall.backfill` is scheduled 10 s after every
  server start (`scheduleStorageBackfill`, identifier `wonky.storageBackfill`) and runs under a
  `pg_try_advisory_xact_lock` (another instance running it → skipped): per pending user it
  recomputes document/space sizes (100 items per batch) and `attachmentBytes` from ready
  `image` StoredFiles, then reconciles (commits per user → resumable; from the sources →
  idempotent) and sends the over-quota notification once (payload `message`, `reason:
  overQuotaAfterBackfill`, `link: /drive/storage`).
- **Reconcile** (§4.3): recurring job `wonky.storageReconcile` (03:47 daily) over all users in
  batches of 200; pending users are backfilled; per user, expired reservations are deleted and
  all counters (incl. `reservedBytes`) recomputed under the row lock; drifts > 1 % or 64 KB are
  logged as `storage.drift {userId, field, before, after}`.
- Not built: the weekly orphan-image cleanup (§2 "−" path) does not exist yet; the per-user
  override has no admin tool; the backfill dry run on a production copy is still to do.
  (MCP results' `storage` field, `drive.get_storage` and the snake_case `quota_exceeded`
  details came with D-15, suite 09 §4.)

## 12. As built (D-11)

Code: `packages/wonky_app/lib/src/storage/` (exported by `package:wonky_app/wonky_app.dart`).

- **Controller** (§3, §6.1). `ShellServices.storage` is a `LiveStorageController` in the apps
  (`WonkyShell.createServices`): it loads `drive.storageUsage` after sign-in, follows the
  `storageChanged` events of the supervised `drive.watch`, refetches when the drive refreshes
  (`ShellServices.driveRefresh`: reconnect, *Empty trash*) and caches the last value per user
  (`storage.usage` in the user store), shown offline with `stale == true`; `stop()` on sign-out.
  The `StorageController` contract gained `report(usage)` (results of byte-adding endpoints,
  e.g. `FileUploadStart.storage`) and `checkRoom(bytes, itemUuid:)` (`drive.checkRoom`).
  `StorageController.none()` stays the default of hand-built services (meters hide, checks
  pass); tests use `FakeStorage` (`onCheckRoom`, `checkRoomCalls`, `quotaError(...)`).
- **Meter** `StorageMeter(services, onOpen:, large:)` (§6.1): `ShadProgress` 4 px (8 px with
  `large`), "12.3 MB of 50 MB used" (`storageBytes` / `storageQuota` format helpers), `primary` /
  `warning` (≥ 90 %) / `destructive` (≥ 100 %, "… used — over quota"), indeterminate +
  "Calculating storage…"; a button for click, Enter and Space; one semantics node (label
  "Storage", value with the percentage, the tooltip as hint, "(offline)" when stale or
  disconnected). `HomeSidebar`'s `StorageMeterSlot` (key `home.storage`) hosts it with
  `shell.storage.open`; Settings › Storage and the Storage page reuse it.
- **Banner** `StorageBanner(services, place:, item:)` (§6.2): below the top bar of every home
  (`DriveHomeScreen`) and below the toolbar of every editor (`EditorScaffold`, owned items only).
  Warning and destructive tints, *Manage storage*, and *Empty trash* first when the trash holds
  ≥ 10 % of the usage (§7.4). Dismissal per device (`storage.banner.warningDismissedAt` /
  `overDismissedAt` in the device store): 90 % for 7 days; over quota in editors until the next
  calendar day ("once per day"), never in homes. Long translations wrap; buttons ellipsize.
- **Dialog** (§6.3): `QuotaExceededDialog.spec(l10n, problem)` → a `WonkyDialogSpec` with the new
  `alert: true` (`ShadDialog.alert`), key `dialog.quota`, buttons `manage`, `fit`, `close` /
  `cancel` (MCP `ui.get_dialog` / `ui.press_dialog_button`); `showQuotaDialog` returns a
  `QuotaDialogChoice` and runs `shell.storage.open` for *Manage storage*. Variants:
  `OwnQuotaProblem` (needed bytes optional — "You have 3.1 MB left of your 50 MB…" when the
  error carries no details), `OwnerQuotaProblem` (images: "Images added to this
  document/spreadsheet/presentation…"; other reasons: "Content added to this file counts against
  the owner's storage. Ask Anna Berg to free up space first."), `BatchQuotaProblem` (480 px
  wide), `TransferQuotaProblem`, `TransferAcceptQuotaProblem`, `FileTooLargeProblem` (`byQuota`
  for the "…right now" text). Below shad's `sm` breakpoint every `WonkyFormDialog` now
  ellipsizes long button labels (buttons stack there).
- **Error presenter** `QuotaErrorPresenter` (`services.quotaErrors`, §7.1): `isQuotaExceeded`,
  `detailsOf`, `problemOf(error, itemKind:, itemName:, reason:)` (caller → own; not the caller →
  owner, with the open item's kind; `reason: transfer` → requester / new-owner variants),
  `present(error)` (true when handled; each error object once, so nested commands show one
  dialog) and `show(problem)`. It listens to every command invocation: a **human**-invoked
  command that fails with `quotaExceeded` shows the dialog, and menus / the palette skip their
  "Command failed" toast for it; MCP, AI and script invocations only get the error (§6.6).
- **Pre-checks** `StorageChecks` (`services.storageChecks`, §7.2): `ensureRoom(bytes, reason:,
  item:, askServer:)` checks the known usage for the user's own items, then (online)
  `drive.checkRoom(bytes, item)` — the owner of someone else's item is charged and gets the
  owner variant — and fails open offline or on other errors; `fittingUploads(sizes)` returns the
  indices that may start (files above `ServerLimits.maxFileUploadBytes` → *This file is too
  large*; one file or none fitting → own variant; else the batch dialog, *Upload the files that
  fit* = greedy in order); `fits(bytes)` for disabling controls. Wired: `shell.drive.copy`
  (human invocations: the source's `countedBytes` against the copier's usage), Write
  `write.insert.image`, `write.image.replace` and canvas drops (`imagesFitStorage`),
  `WriteImportHandler` and `write.insert.fromFile` (presenter), Sheets image inserts and pastes
  (`_prepared`, human only) and `SheetsImportHandler`.

## 13. As built (D-17)

Code: `wonky_drive/lib/features/storage/` — `StorageScreen` (`/storage[?filter=…]`, in the home
frame: top bar, banner, left menu with *Storage* highlighted via
`HomeSidebar.activeDestination`), `StorageUsageSummary`, `StorageSuggestions`, the table
(`StorageTableTitle`, `StorageTableBar`, `StorageRow`), `StoragePageController`, `StorageFilter`,
`StorageApi` (`drive.listByStorage`).

- **Usage** (§6.4): "46.1 MB of 50 MB used" and "92 %", `WonkyStackedBar` (`wonky_ui`) with the
  legend Documents · Spreadsheets · Presentations · Files · Trash · Free. Colors are the kind
  colors of the drive icons (documents blue, spreadsheets green, presentations amber), files
  violet and trash muted — not `chart1–5`, which are grays in the zinc theme. Over quota: the
  bar is full in `destructive`, the headline "… used — over quota" and "Over by 0.4 MB";
  calculating: the shell's large `StorageMeter`.
- **Free up space**: *Empty trash* (trash bytes > 0; confirm "Permanently delete 23 items in the
  trash? This frees 8.1 MB and can't be undone.", the count from a trash listing of ≤ 200 rows,
  then `shell.drive.emptyTrash {confirmed}`), *Large files* (≥ 1 MB, trashed ones included),
  *Not opened in 6 months* (≥ 256 KB, `notOpenedSince` = now − 180 days; items **created** after
  the cutoff are left out, so a fresh upload nobody opened yet is not a candidate). Counts read
  ≤ 200 rows ("More than 200 files"). *Review* runs `drive.storage.show {filter}`; the filter is
  a removable chip in the table title.
- **Items using storage**: the type menu (All, Documents, Spreadsheets, Presentations, Files,
  Trash) is the `?filter=` of the route; paged by 50 with the keyset cursor (infinite scroll);
  sorted by counted size only (no sort menu). Columns Name (category icon, *In trash* badge),
  Kind ("M4A audio", "Spreadsheet"), Location (folder name, *My Drive*, *Trash*; the folder names
  of a page are looked up as one batch, 8 at a time, with one rebuild, and failed lookups are
  retried on the next page load, DR-4), Last opened,
  Storage, ⋮ (the shell's item menu); below ~800 px only Name, Storage and ⋮. Checkboxes,
  click / `Mod`-click / `Shift`-click, arrows / Home / End / Esc; the selection is published as
  `ShellServices.driveSelection`, so `Del`, `Space`, `Enter`, `F2`, `S` and `Mod+A` act on it.
  Selection bar: "3 selected · 12.4 MB", *Move to trash* (`shell.drive.trash`, undoable),
  *Restore* and *Delete forever* (trashed selections; confirm "Delete 3 items forever? This
  frees 4.2 MB and can't be undone."), *Download* (files only, `drive.file.download`).
- **Live**: reloads (debounced 300 ms, keeping the loaded rows) on drive changes, a changed
  `StorageUsage` (`storageChanged`) and `driveRefresh`; offline: the cached usage and "You're
  offline" with *Retry* for the table.

