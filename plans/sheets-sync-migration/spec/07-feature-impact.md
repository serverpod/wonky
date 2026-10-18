# RevLog spec 07 · Feature impact

Every feature that touches the old sync layer, and what it becomes. "Server" paths are relative
to `wonky_server/lib/src/`. Evidence for "today" is in the inventories (server §1–§7, Sheets
client §4–§9, Slides client §2–§7).

## 1. Versions and history

| Feature | Today | With RevLog |
|---------|-------|-------------|
| Capture trigger | Change-log consumer → `VersionService.recordEdit`; the minute job `captureDue` | `versions` hook (05 §6.2) with `revision`; `captureDue` unchanged |
| Capture (Sheets) | `SheetsVersionProvider.readSpace` (CRDT admin read) → gzip NDJSON (header `syncTablesHash`) | Read the tables by `fileId` in one `REPEATABLE READ` transaction at `headRevision`, **streaming the encoding** (fixes CQ-29). Header `revSchemaHash` + `revision`; `ItemVersion` stores the revision. `afterCapture` takes counts computed during capture (no re-download) |
| Capture (Slides) | `HeadlessDeckCache.readSpace` | Same as Sheets (or from the headless model if cached) |
| Changed ranges / attribution | Receipt `processedAt` windows → `ChangeLog`/`DeckChangeLog` summaries (≤ 20k) | `rev_op` rows with `revision` in (previous version's revision, this version's revision]: summaries and authors. Exact: offline edits belong to the version whose revision window contains their commit |
| Viewing a version, client-side diff | Snapshot download; the model is built in memory | Unchanged (snapshot format v2 differs only in the header) |
| Server diff (> 500k cells) | `SheetsVersionEndpoint.diff` (main isolate) | Unchanged API; runs in the shared isolate runner (CQ-24) |
| Restore | Diff (current vs snapshot) → `SheetsBulkWriter.applyRecorded` / `ServerSlidesWriter.applyRecorded(revives)`; no consumer signal | Same diff → `submitServerChange(record: true, label: "Restore version '…'", actorKind: user, insertsAreRevivals: Slides)`. Collaborators see the ops arrive live. The `versionRestored` presence notice stays. Undo via `*.serverChange` (05 §8.2) |
| Make a copy of a version | Sheets: client copy into a reserved space + `registerSpreadsheet` + `copyExtras`. Slides: server `makeCopy` | Sheets: client `SpaceCopier.changes` → new file (06 §7.1). Slides: unchanged (`DeckCopies.changes` + `createFile`) |
| Version thinning | Unchanged | Unchanged (deletes snapshot files) |
| Cell edit history | Local `ChangeLog` (30 days) + server `cell_history` via `sheets.cellHistory` | Local `rev_local_op.detail_json` (30 days) + server `cell_history` (fed by the `cellHistory` hook). The API is unchanged except `changeLogId` → `revision`. Editor+ (05 §11) |
| Activity summary (`sheets.activitySummary`, no app caller) | Reads `ChangeLog` | Reads `rev_op` (or delete the endpoint: it has no caller; decide in R4) |

## 2. MCP and AI

| Feature | Today | With RevLog |
|---------|-------|-------------|
| MCP reads (`SheetsMcp.open`, `SlidesHeadlessProvider.open`, 44 + 38 write sites, many reads) | Headless caches over CRDT tables | `HeadlessFileCache` leases (05 §9). The tool code is unchanged apart from `open/release` |
| MCP writes (`SheetsWrites.run`, `SlidesWrites.run`/`writeSteps`) | Plan on the headless model under `withWriteLock` → `SheetsBulkWriter.applyRecorded` / `ServerSlidesWriter.applyRecorded` → `afterCommit` signal | `submitServerChange(plan: …, record: true, actorKind: mcp\|ai, sessionId: 'server:…', onBehalfOfSessionId)`. Soft-lock check (`DeckTextClaims`) and protection guard unchanged |
| `sync_version` (MCP tool) | Newest `ChangeLog`/`DeckChangeLog` id | The file's `headRevision` (as a string) |
| `changes.revert` (MCP and assistant) | `SheetsChanges.tryRevert` / `SlidesChanges.tryRevert` | 05 §8.2. Also align the two revert rules (MCP: own unreverted changes only; endpoint: any editor; code-quality slt #11): this spec adopts "Editor+, not already reverted" for both |
| `SheetsChanges.composite` (assistant run = one record) | Merges `ServerChangeRecord`s | One `recordId` per assistant run (RD-21); the record spans the run's ops |
| UI bridge (`ui.sheets.*`, `ui.slides.*`) | Commands on the open session; `flush` | Unchanged. "Wait idle" uses `flush()` (local durability) as today; tools that must see server state use `whenSynced` |
| AI Suggest previews (`SheetsShadows`, `DeckOverlays`, `ai_preview_record`) | Two full model copies; records keyed by spreadsheet uuid | Copy-on-write overlays (05 §9); `ai_preview_record.fileUuid`. Apply = `submitServerChange` |
| `AI()` cell function, `applyFill` | `SheetsWrites.run` | `submitServerChange` |
| Assistant targets (`sheets_assistant_target.dart`, `slides_assistant_target.dart`) | Headless open + composite record | Leases + one group per run |
| Agent cursors (server presence) | Consumer duty 9 | Inline after the ack (05 §6.2) |
| Client agent flash | Local change-log rows | `session.history` (06 §7.1) |

## 3. Scripts (Sheets)

| Feature | Today | With RevLog |
|---------|-------|-------------|
| Script files and projects (`script_project`, `script_file`) | Client writes through the session; server `writeFile/deleteFile` via `ServerSheetsWriter.apply` | Unchanged on the client. Server via `submitServerChange` with the caller's actor kind (`user` from the script endpoint, `mcp`/`ai` from tools), so the Editor role is checked |
| Builds (`script_build`, server-written) | `ServerSheetsWriter.apply` in `_compile` | `submitServerChange(actorKind: system)`; `script_build` is `clientWritable: false` |
| Compile trigger on save | Consumer plugin `kinds ∋ scripts` | `scripts` hook |
| Compile from the editor | `flush()` + `syncNow()` | `whenSynced()` (06 §7.1) |
| Run (server) / commit of script changes | Headless model, `SheetsBulkWriter.applyRecorded` + `writeThrough` | Headless lease, `submitServerChange(record: true, actorKind: script)`; no write-through |
| Triggers (onEdit/onChange) | Consumer plugin → `fireForChange` (resolves ranges with the headless model; offline flag from `createdAt` vs `at`) | `scripts` hook; offline flag = `op.offline` |
| Time-driven triggers (`ScriptTriggerService.tick`) | Reads synced `ScriptTrigger` through the CRDT session | Plain reads by `fileId` |
| User properties | Personal space (synced) | Server table + endpoints (02 §2.4, 06 §7.1) |
| Client script runtime writes (`session_workbook_access.dart`) | `session.execute(op, actorKind: 'script')` | Unchanged (`RevSubmit.actorKind: script` is allowed; 03 §5 rule 5) |

## 4. Drive, sharing, storage

| Feature | Today | With RevLog |
|---------|-------|-------------|
| New spreadsheet / presentation (online) | Server create, or a client reserved space + `register*` | `drive.createSpreadsheet/createPresentation(fileUuid, …)` (04 §5) |
| New (offline) | Reserved space; `PendingDriveOp(register*)` | Client UUID; `PendingDriveOp(create*)`; the creation op in the outbox (06 §7.1) |
| Templates, copies, imports | `SpreadsheetFactory.write`, `SpaceCopier.copy`, `DeckCopies.copy`, `SheetsImportService.importNew` (direct inserts, mostly no change log) | `…changes()` + `RevLogService.createFile` (05 §8.3): every content change is in the log |
| Rename | `_mirrorTitleToSpreadsheet` / `mirrorTitleToDeck` (direct ORM writes) | `submitServerChange(update title, system)`. The reverse direction (title edited in the app) uses the `title` hook |
| *Make available offline* (`setPinnedOffline`) | `SpaceService.setPinned` (membership + subscription) | Drive user state only (`DriveItemUserState.pinnedOffline`, as Write); the client's `RevLogClient` downloads pinned files (06 §2.5) |
| Sharing / role changes (`AclEvents.changed`) | `SpaceService.mirrorMembership` | `RevBus.rolesChanged(fileUuid)` (05 §4) |
| Grant expiry | Daily `removeExpiredGrants` revokes membership | Checked per submit and on stream (05 §4); the daily job still deletes expired grants |
| Trash / restore | Membership revoke / re-grant | Trashed → `fileReadOnly` on submit; streams get `RevRoleChanged(viewer)` |
| Purge (delete forever, trash expiry) | Delete `OfflineSyncSpace` + reservation | Batched purge of `rev_file` (05 §10). **Plus fix CQ-1** (never purge items owned by others) in the same work |
| Account deletion | Deletes memberships and the personal space | `script_user_property` cascades by user; files purge as above |
| Storage accounting (`ContentSizes`, `SheetsSizeEstimator`, `SlidesSizeEstimator`) | SQL over CRDT tables | SQL over the plain tables by `fileId` (`contentSize` hook + reconcile job) |
| `ServerLimits.maxActiveSpacesPerUser` (meta, client-visible) | Shown to clients | Removed; `maxCellsPerSpreadsheet` stays; `maxSheetsPerSpreadsheet` stays and is now enforced by the Sheets binding |
| Drive previews / thumbnails | No synced reads | Unchanged |
| Welcome content (`AccountService`) | `DriveService.createSpreadsheet` | `createFile` |

## 4a. Protected sheets and ranges (Sheets)

| Feature | Today | With RevLog |
|---------|-------|-------------|
| Enforcement | Advisory: the client write gate (`SheetEditorController.apply` → `WriteIntents` → `ProtectionGuard`), plus the MCP and server-script guard in `SheetsWrites.run`. A modified or stale client, or an offline edit, can bypass it (Sheets 07 §10.3) | **Enforced by the sequencer** (RD-19, 05 §3.5) with the same core guard. Client gate and MCP guard stay for UX (dialogs, warning-only confirmation, friendly tool errors) |
| `WriteIntents` | In the app (`wonky_sheets/lib/features/protection/write_intents.dart`) | Moved to `wonky_sheets_core` (shared by client, MCP and sequencer), plus `fromApplied` (structure derived from changes) and `BoundaryRepair` |
| Warning-only protections | "Heads up!" confirm on the client | Unchanged; never blocked by the server |
| Managing protections | `canManage` checked by the client and the MCP rule handlers | Also checked by the sequencer on every update or delete of a `protected_range` row |
| Version restore over protected ranges | Writes them (advisory) | Pre-checked: refused if it changes protections the user can't edit (05 §3.5) |
| Offline edits into ranges protected meanwhile | Merged | Rejected on sync, offered as a copy (06 §4.6; scenario 23) |
| Repairs touching protected areas | Applied by any editor's client | Rejected for users who can't edit the protection; a permitted user's client repairs instead (03 §6) |

## 5. Collaboration

| Feature | Today | With RevLog |
|---------|-------|-------------|
| Presence, cursors, follow, sheet-tab avatars | Presence stream | Unchanged |
| Commit hints | `cell`, `range`, `pending`, `typing` | `typing`, `pending` (RD-18; 06 §10) |
| Slides soft locks, text/transform/structure hints | Presence | Unchanged |
| Comment orphaning/revival | Consumer from `summary.deleted/revived` | `comments` hook; Slides undo-of-delete still reports inserts as revivals (`insertsAreRevivals` in summaries, as `SlidesWriter.summarize`) |
| Conflict UX | Heuristic after a sync cycle (§6 of the client inventories) | Exact outcomes (06 §6) |
| Offline collaboration scenarios (Sheets 10 §10) | Engine LWW by HLC | See §6 below |

## 6. Sheets 10 §10 scenarios under RevLog (Q1 decided: last arrival wins)

| # | Scenario | Outcome with RevLog |
|---|----------|---------------------|
| 1 | Same cell, both offline | The later **arrival** wins the content. Formats set by either survive per attribute. The later arriver gets an "overwritten" outcome and a review |
| 2 | Same row, different cells | Both survive |
| 3 | Value vs bold, same cell | Both survive (different columns; deterministic-id insert merge, 03 §4.2) |
| 4 | Both insert a row at the same place | Both rows kept; deterministic order (sortKey, then id) |
| 5 | A deletes row 7, B edits it | Row gone. B's edits are dropped (B: "Row deleted by Anna"). **Changed:** if A undoes the delete, A's undo restores the cells A's plan deleted. Cells **B created** in row 7 after A's delete was committed were dropped and are not revived, whereas the CRDT revived them. Cells B created *before* A's delete arrived were cascaded (A sees "Also removed n cells added by Bo") |
| 6 | A edits C5, B deletes column C | As 5 |
| 7 | A deletes sheet, B edits it | As 5 |
| 8 | Both sort the same range | The later-arriving sort's keys win per row; the earlier sorter, if it was offline, gets the sort toast |
| 9 | Partial-range sort vs edit | Per cell, the later arrival wins (documented limitation, unchanged) |
| 10 | Two sheets renamed to the same name | Client repair (`WorkbookMaintenance`, now wired) renames the larger id " (2)" |
| 11 | Same sheet renamed differently | Later arrival wins; the offline loser gets a review entry |
| 12 | Column inserts + formulas | Unchanged (id tokens) |
| 13 | Overlapping merges | Client repair keeps the smaller id |
| 14 | Overlapping pastes | Per cell, the later arrival wins; review for overwritten cells |
| 15 | `=SUM(B2:B9)` vs deleting row 9 | Unchanged (range shrinks) |
| 16 | Undo after another user changed the cell | Unchanged (skip rule, partial toast) |
| 17 | CF rules on overlapping ranges | Unchanged |
| 18 | Move chart vs edit title | Unchanged |
| 19 | Same script file | Later arrival wins (whole file), plus the online conflict dialog (unchanged) |
| 20 | Locale change vs offline typing | Unchanged |
| 21 | Created offline, not visible to B | Same: visible after A's create replays and A shares |
| 22 | Downgraded to viewer while offline | `forbiddenForRole` on resend → read-only, *Save my changes as a copy* (06 §8) |
| 23 | A edits B4 offline; meanwhile the owner protects column B ("Only me") | A's op is rejected with `protectedRange` on sync (05 §3.5). A sees the blocked message with *Save my changes as a copy*. B4 keeps the owner's value. **New:** today the edit goes through, because protection is advisory |
| 24 | A (not a protection editor) uses a stale or modified client to write a protected cell | Rejected by the server (`protectedRange`); nothing is written |


## 7. Slides-specific

See spec file 08.

## 8. Things that get simpler or disappear

- Reserved spaces and their pools; `NoReservedSpaceException`.
- Membership, active sets and `subscribe`/`ensureSubscribed`/`unsubscribe`; the weekly purge.
- "Downloading spreadsheet… N%".
- The SQLite trigger journal and its pruning.
- `SyncSchemaRelease` lock-step hashes and projection rebuilds (OS-9).
- The change-log tables and receipts.
- 9 vendored engine patches.
- Recovery export of whole replicas (replaced by outbox export).
- The `sheets.offlineEdits.*` / `slides.offlineEdits.*` heuristics.
