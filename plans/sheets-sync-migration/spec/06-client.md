# RevLog spec 06 · Client

Packages:

- `packages/wonky_revlog`: pure Dart. Codec, apply rules, overlay, chunker and composer, and the **sync state machine `RevSyncCore`**, which has no I/O.
- `packages/wonky_revlog_flutter`: depends on `wonky_revlog`, `wonky_app` and `wonky_client`. Store, transport, I/O wrapper, bootstrap and per-user client.

App bindings: `wonky_sheets/lib/features/revlog/` and `wonky_slides/lib/features/revlog/`. They
replace `wonky_sheets/lib/features/sync/`, `wonky_slides/lib/features/sync/` and
`packages/wonky_sync_kit_flutter`, which is deleted in R8.

| Class | Package | Role | Replaces |
|-------|---------|------|----------|
| `RevSyncCore` | `wonky_revlog` | Per-file state machine (§4): outbox order, in-flight op, buffer composition, revision queue, gap detection, ack handling, rejection handling. Fed by events; emits commands | engine loop, `SpaceWriteQueue`, `JournalIngestion` |
| `RevConnection` | `wonky_revlog_flutter` | Wraps `RevSyncCore` with a `RevTransport`, `RevLocalStore` and `ConnectionKeeper` | — |
| `RevLocalStore` | `wonky_revlog_flutter` | SQLite cache per user and app (02 §3) | `SyncReplica`, `SyncWriter`, `ChangeJournal` |
| `RevTransport` | `wonky_revlog_flutter` | Interface over `client.sheetsDoc` / `client.slidesDoc` (connect, page, ops, info). `FakeRevTransport` (in `package:wonky_revlog/testing.dart`) implements it over `FakeRevServer` | `SyncRemote` |
| `RevBootstrap` | `wonky_revlog_flutter` | Page scheduler and coverage (§5) | `SpaceOpening`, row streaming in `SyncedWorkbookSession` |
| `RevLogClient` | `wonky_revlog_flutter` | Per user and app: store, open sessions, background sync of outboxes, availability, Settings provider | `AppSyncController`, `ReplicaInstallation`, `ReplicaOfflineProvider` |
| `ConnectionKeeper` | `wonky_app` (moved from `wonky_write/lib/features/sync/connection_keeper.dart`) | Reconnect, backoff, connectivity, *Simulate offline* | — |

## 1. Session contracts

### 1.1 Sheets

`LoggedWorkbookSession extends WorkbookSessionBase`, not just `implements WorkbookSession`:
four features downcast to the base for `customFunctions`, `externalData` and `customLists`
(inventory sheets-client §5).

| Member | Contract |
|--------|----------|
| `execute` / `applyChanges` | As today: plan, apply to the model synchronously, persist. **Persist** = append the changes to the outbox (durable), tagged with the plan's `groupId`, and hand them to the connection. The `LoadingGate` checks stay (`checkPlan`; §5.5 adds the delete gates) |
| `flush()` | Unchanged semantics: **everything applied so far is durable locally**, i.e. in the outbox |
| **`whenSynced({Duration? timeout})`** *(new)* | Completes when this tab's outbox for the file is empty, i.e. every change is acknowledged. Fails with `RevOfflineException` when offline. Used by script compile (replacing `SheetsData.current().syncNow()`) and by conflicts |
| `remoteBatches` | Remote ops and streamed page batches are emitted **synchronously, in the same turn as `model.applyChanges`**. Commit hints identify local batches by identity before a `Timer.run` (inventory sheets-client §7) |
| `syncStatus` | §9 |
| `role` | From `RevInit`, `RevRoleChanged` and drive item changes (`updateRole`) |
| `pendingChanges` | Number of this tab's outbox changes for the file |
| **`history`** *(new)* | `RevHistory`: recent op metadata from `rev_local_op` (30 days), plus a broadcast stream of `RevOpMeta {revision, authorUuid, sessionId, actorKind, label, groupId, groupLast, recordId, summary, detail, offline, committedAt}` for every op this session applies: remote ops, and its own acked ops (summary and detail from the outbox). It replaces the local `ChangeLog` reads (§7) |
| **`outcomes`** *(new)* | Stream of `RevOutcome`s (dropped, conflicts, cascaded) of this session's acked ops (§6) |
| **`groupRejected`** *(new)* | Stream of `groupId`s whose ops were rejected (§4.6); the editor drops the matching undo step |
| `rowLoading` | As today (`RowLoadTracker`), fed by `RevBootstrap` |

### 1.2 Slides

`LoggedDeckSession extends DeckSessionBase` (uses `DeckWritePath`) gets the same additions. It
runs the 12 `DeckMaintenance` repairs as `SyncedDeckSession` does: 1 s after remote batches,
editors only, not undoable, `actorKind: user` with the summary flag `"repair": true` (03 §6; 08 §4). Additionally, repairs (Sheets and Slides)
run **only when no remote group is half-applied** (the last applied remote op had
`groupLast == true`) **and this tab's outbox is empty** (review 21).

## 2. Local store (`RevLocalStore`)

### 2.1 Opening

```dart
static Future<RevLocalStore> open({required RevSchema schema, required String userUuid,
    required String app /* 'sheets' | 'slides' */, String? directory});
// file: '<app>_cache_<userUuid>.db', via LocalDatabases.open(…, migrations: revCacheMigrations(schema))
```

- **PRAGMAs** as today's replica (`sync_replica.dart:63-76`): 64 MB page cache, in-memory temp store, WAL autocheckpoint 20,000.
- **Old engine files.** On first start of the new build, remove `sheets_<userUuid>.db` / `slides_<userUuid>.db` without reading them. On desktop, `LocalDatabases.delete`. On the web, where `LocalDatabases.canDelete` is false (`local_database.dart:57`), open them and drop every table (one transaction), then record `rev_meta.oldReplicaCleared` so it runs once.

### 2.2 Writes

Every write is one `writeTransaction`:

| Kind | Writes |
|------|--------|
| `appendOutbox(fileUuid, ChangeSet, tabId)` | one `rev_outbox` row (`inflight = 0`, `schema_hash`) |
| `markInflight(clientOpId)` | `inflight = 1` |
| `applyServerOp(fileUuid, revision, applied, meta, {ackedClientOpId})` | **Only if `revision > rev_local_file.revision`** (monotonic, RD-22): replay the applied form literally on the domain rows (upsert full rows for inserts; set columns for updates; delete for deletes), set `revision = r`, insert the `rev_local_op` row, and delete the outbox row `ackedClientOpId` when given. A committed op therefore can't be both applied and in the outbox |
| `applyPage(fileUuid, RevPage, replays)` | For each coverage key whose stored revision is lower than `Rp`: replace the covered rows (§5.3), apply the replayed buffered changes, upsert the coverage key. Set `complete = 1` with the last page |
| `replaceOutboxRows(fileUuid, tabId, List<ChangeSet>)` | after composing buffered chunks (§4.2) or re-stamping (§2.4) |

**Durability before sending.** The session sends an op only after the write that contains it has
completed (`whenDurable`, as Write).

### 2.3 Reads

- `loadFile(fileUuid)` returns the `rev_local_file` row plus this tab's outbox and orphaned outbox rows (§2.6).
- `loadRows(fileUuid, {skip: {cell}})` reads keyset pages of 10,000, as today's `loadSpace`.
- `loadCells(fileUuid, sheetId, rowIds)` reads 500 row ids per query, as `SheetsReplica.loadCells`.
- `coverage(fileUuid)`, `recentOps(fileUuid, since)`, `filesWithOutbox()` and `usage()`.

### 2.4 Schema versions

`rev_meta.schemaHash` records the `RevSchema.hash` the domain tables were created with.

- **App hash changed after an update:**
  1. Keep `rev_local_file`, `rev_outbox` and `rev_local_op`.
  2. Drop and recreate the domain tables and `rev_coverage`.
  3. Set every file to `complete = 0` and `revision = 0`.
  4. **Re-encode every outbox row with the new schema** and set its `schema_hash`. Changes to tables or columns that no longer exist are dropped and reported once in a toast. This keeps a stale hash from blocking the outbox (review 11).
  5. The next open re-bootstraps and overlays the outbox.
- **Server ahead of the app:** the client continues if its hash is in `RevInit.acceptedHashes`; decoders skip unknown tables and columns. Otherwise it shows "Update required" (02 §4.3).

### 2.5 Eviction (availability)

- **Kept complete:** files opened in the last 14 days (max 50 per app) or pinned (*Make available offline*).
- **Never evicted:** files with outbox rows.
- **Evicted:** everything else is deleted from the cache (domain rows by `file_uuid`, `rev_local_op`, `rev_coverage`, `rev_local_file`) by `RevLogClient.maintain()`, after sign-in and then daily. This replaces the weekly purge and the cell-cap eviction.
- **Without OPFS** (`offlineStorageLimited()`): files beyond 200,000 cells in total (Sheets) or 50,000 elements (Slides) are not kept offline, least recently opened first; pinned files win. A warning shows as today.

### 2.6 Several tabs (RD-22)

- **Tab id.** Every app instance has a `tabId`. It sends its own outbox rows and only those.
- **Liveness.** Each tab holds a Web Lock `wonky.revlog.tab.<tabId>` for its lifetime; on desktop, a process lock file.
- **Adoption.** `RevLogClient.syncOutboxes` (§7.3) adopts outbox rows whose tab no longer holds its lock: it rewrites `tab_id` to itself, then sends them. Adoption runs inside a Web Lock `wonky.revlog.<app>.<fileUuid>.adopt`, so two tabs never adopt the same rows.
- **Monotonic store.** Two tabs with the same file open each run their own connection and model. Store writes are monotonic (§2.2), so the tab that is behind never moves the cache backwards. A tab that sees `rev_local_file.revision` beyond its own just skips the store write; its model still applies the op.

## 3. Model ⇄ store

### 3.1 Server state vs model

- The **store** holds server state at `revision`.
- The **model** holds `applyAll(outbox, server state)` (03 §7).
- **Loading:** read the rows from the store (viewport-first, §5.1), then apply the outbox ops to the model with the pure rules. The batch has origin `load` for Slides and is a load batch for Sheets.

### 3.2 Remote op (another connection's op)

```
onRemoteOp(op):                                  // strictly in revision order (§4.3)
  if op.clientOpId ∈ thisTabOutbox:              // our own op seen through catch-up (ack lost)
      onAck(op.clientOpId, op.revision, applied: op.payload, outcome: op.outcomeJson); return
  applied = decode(op.payload)                   // applied form, no before
  patch = Overlay.build(model, serverRows, applied, outbox)    // 03 §7
  batch = model.applyChanges(patch)              // origin remote
  remoteBatches.add(batch)                       // same turn
  store.applyServerOp(fileUuid, op.revision, applied, meta(op))   // async, ordered, monotonic
  history.add(meta(op))
  if bootstrapping: bootstrap.buffer(op)         // §5.3
```

### 3.3 Op metadata retention

`rev_local_op` keeps 30 days or 20,000 ops per file, whichever is smaller, pruned on open and
daily. It holds metadata, summary and detail only.

## 4. Sync state machine (`RevSyncCore`, wrapped by `RevConnection`)

This is ported from Write's `DocumentSyncController` (inventory write-infra §7.1) without the OT
parts.

### 4.1 Outbox and send path

```
submitLocal(changes, {label, actorKind, groupId, summary, detail}):
  cs = ChangeSet(clientOpId: v7, baseRevision: serverRevision, changes, …, offline: !connected)
  for chunk in RevChunker.split(cs):             // ≤ 5,000 changes and ≤ targetOpBytes encoded (one group)
      if inflight == null and buffer empty and connected: inflight = chunk
      else buffer.addOrCompose(chunk)            // §4.2
  store.appendOutbox/replaceOutboxRows → whenDurable → sendInflight()
```

- Only one op is in flight at a time.
- `sendInflight` sends `RevSubmit` only once the write is durable. It sends at most once per connection and resends after a reconnect with the same `clientOpId`.

### 4.2 Buffer composition

A new change set is composed into the **last** buffered chunk if all of these hold:

- both belong to the same group, or both are plain edits (no `groupId`);
- the last chunk started less than 2 s ago;
- the composed result stays within the limits.

Otherwise it starts a new chunk. Composition follows 03 §2: `composeRowChanges`, merged summary,
capped detail, OR-ed `offline`. Undo entries hold their own `RowChange`s and never reference ops,
so composing never changes what undo does.

### 4.3 Ordering

- Revision-carrying server messages (`RevRemoteOp`, `RevAck`) go into a `SplayTreeMap<int, …>` queue. They are processed strictly as `revision == serverRevision + 1`.
- **Gap:** send `RevRequestOps(serverRevision + 1, firstQueued − 1)`, re-requested after 3 s. A gap also opens when `RevPong.headRevision > serverRevision` and the queue is empty (lost bus message, 05 §5).
- **Duplicates** (`revision ≤ serverRevision`) are ignored.

### 4.4 Ack

```
onAck(clientOpId, revision, applied?, outcome?):     // in revision order
  op = outbox.take(clientOpId)
  appliedForm = applied ?? op.changes               // RD-20: never re-derived
  store.applyServerOp(fileUuid, revision, appliedForm, meta(op), ackedClientOpId: clientOpId)
  if applied != null:                               // the server's result differs (drops, merges, cascades, creation title)
      patch = Overlay.build(model, serverRows, appliedForm, remainingOutbox)  // as for a remote op
      remoteBatches.add(model.applyChanges(patch))
  serverRevision = revision
  history.add(meta(op)); if outcome: outcomes.add(outcome)
  if buffer not empty: inflight = buffer.removeFirst(); sendInflight()
```

### 4.5 Reconnect and catch-up

1. `connect(knownRevision: serverRevision, tabId)`.
2. Handle `RevInit`:
   - **`ops`:** process them in order through the queue, then gap-fill the rest when `more`. An op carrying this tab's `clientOpId` is handled as an ack (§3.2).
   - **`bootstrap: true`:** run §5 again from the current model (pages replace covered rows; the outbox overlay stays).
3. Resend the in-flight op (same `clientOpId`), then the buffer.
4. **Pruned duplicate.** If the server answers a resend with `duplicate: true` and `applied == null` (payload pruned), the op committed more than 30 days ago. Re-bootstrap the file.
5. **Outbox age.** The server never refuses an old base. Outbox rows older than 180 days are not resent; they are offered as a copy (§8).

### 4.6 Rejections

On `invalidChange`, `tooLarge`, `limitExceeded` and `protectedRange` for an op of group *g*:

1. Remove that op **and every other outbox op of group *g*** (the rest of the plan).
2. Rebuild the model rows they touched as `applyAll(remaining outbox, server state)`, emitted as one remote batch.
3. Emit `groupRejected(g)`. The editor's undo service removes the undo step recorded for that plan; `RowsUndoEntry` gets an optional `groupId` (05 §8.2 analogue on the client). If the step is buried under later steps, it is marked inert: its undo becomes a no-op with the toast "This change was not saved".
4. Show one toast for the group with the server message, and log the op id and code (error level).
5. **`protectedRange`.**
   - The toast is the blocked-cell message (`GuardResult.blockedMessage`) naming the protections from `detailsJson`.
   - For ops with `offline: true`, the toast adds *Save my changes as a copy* (§8). The rejected group's changes are kept for 7 days for that purpose.
   - A rejected repair op (`"repair": true`) shows nothing and is not retried for that violation for 24 h.

**The client write gate is unchanged.** `SheetEditorController.apply` → `WriteIntents.of` →
`ProtectionGuard`, now imported from `wonky_sheets_core`. It still shows the blocked dialog and the
warning-only "Heads up!" confirm before anything is sent. Server enforcement only catches what the
client couldn't know: a protection that arrived later, a changed editor list, or a stale or
modified client. Property test: for the same model, client-gate "allowed" implies server "allowed"
(09 §2.8).

## 5. Opening and bootstrap (`RevBootstrap`)

### 5.1 Open flow

Sheets is shown; Slides is the same with whole-deck loading.

```
open(fileUuid):
  local = store.loadFile(fileUuid)
  if local?.createdLocally:                          // queued create not replayed yet — FIRST
      open from the outbox (the creation op) → WorkbookReady; connect once the create has replayed
  else if local != null and (local.complete or local.revision > 0):
      load from the store viewport-first (today's _loadAll: all non-cell tables, frozen rows +
      top−20…top+200 of the ViewportHint; files ≤ 2,000 rows fully) → overlay outbox → WorkbookReady
      connect(knownRevision: local.revision)          // RevInit ops or bootstrap
      if !local.complete: continue §5.2 for what is missing
  else if online:
      connect(0) → RevInit(R0, bootstrap, stats)
      if R0 == 0 (created elsewhere, not initialized yet):
          WorkbookUnavailable("This spreadsheet is still being created on another device")
          — keep the stream open; the first remote ops create it → re-open
      else: structure pages → first cell page → WorkbookReady; continue §5.2
  else:
      WorkbookUnavailable(offline: true)              // re-opens when back online (as today)
```

### 5.2 Page scheduling

1. **Structure.** Request `structure` pages until `nextCursor == null`. In parallel, request `rows` pages for every table in `excludedTables`, two at a time (large `sheet_row`/`sheet_column`).
2. **Viewport.** While structure loads, request a `cells` page for the frozen rows plus `top−20 … top+200` of the active sheet. Apply it after the structure, because the model needs the row ids.
3. **Ready.** `WorkbookReady` once steps 1–2 are applied. Files with ≤ 2,000 rows load all their cells first, as today.
4. **Streaming.** The remaining cells come in blocks of 500 rows:
   - first the grid's `prioritize` requests (newest of the last 4, ±50 rows);
   - then the active sheet;
   - then the other sheets in tab order.
   At most 2 requests are in flight.
5. **Progress.** `rowLoading.progress` = loaded rows / total rows, with the total taken from `RevInit.stats.sheets`.

### 5.3 Coverage and buffered ops (exactness)

During bootstrap the client keeps:

- **`serverRevision`**: the last op processed in order. It starts at `R0`.
- **The buffer:** every op processed since `R0`, as `(revision, applied form)`, in revision order. This includes **this tab's own acked ops** (their applied form), not only remote ops (review 16).
- **Coverage:** the keys from `rev_coverage` with their page revisions.

A change's **coverage key** comes from the schema (`RevTable.coverage`):

- **structure tables:** `tbl:<table>` plus the id, matched against the stored ranges.
- **`cell`:** `row:<sheetId>:<rowId>`. Inserts carry `sheetId`/`rowId`. For updates and deletes, the key is found from the row in the store or in the page being applied; if neither has it, the cell is not covered yet. Cell key columns are immutable (03 §4.3), so the key never changes.

| Event | Action |
|-------|--------|
| Page (`Rp`, coverage keys `C`, rows) | (1) For each key in `C` not already covered at a revision ≥ `Rp`: rows present in the page replace the store/model rows; rows of that key absent from the page are deleted. (2) Replay, in order, the buffered changes with `revision > Rp` whose coverage key is in `C`. (3) Store `C → Rp` |
| Op `r` processed | For each change in its applied form: if its key is covered at `Rp < r`, apply it now; if covered at `Rp ≥ r`, skip it (already contained); if not covered, it waits in the buffer. Then append the op to the buffer |
| Reconnect during bootstrap | `connect(knownRevision: serverRevision)`. `RevInit.ops` are processed as ops, as above. `bootstrap: true` restarts the remaining page requests; pages already applied stay valid, because their coverage revisions still decide what is newer |
| Bootstrap complete | Drop the buffer; `complete = 1` if the file qualifies for offline (§2.5); collapse `row:` coverage keys into `sheet:` keys |

The model is updated through the overlay at every step, so outbox changes stay on top. Property
test: 09 §2.5.

### 5.4 Partial caches

- **Reopen.** Pages are always written to the store, so reopening a partly loaded file is instant for the loaded part. `rev_coverage` records what is present and at which revision.
- **Reconnect.** `RevInit.ops` update the covered rows normally; with `bootstrap: true`, missing and stale parts are requested again.

### 5.5 Loading gates

- **Kept as today:**
  - `LoadingGate` (write and range-read refusal over unloaded rows);
  - `#LOADING` formulas (`LoadingFormulaSource`);
  - the `LoadingLayer` shimmer;
  - `ViewportHint` (from `LocalViewState` or `?gid=`).
  - The `_touched` protection now follows from §5.3, because newer ops win over older pages; keep its test.
- **Added (RD-3, review 8):**
  - **`DeleteSheet` and `DeleteDimension` (columns) require the whole sheet to be loaded.** The planners list descendants from the model, so unloaded cells would be cascaded instead of listed, and undo couldn't restore them.
  - `DeleteDimension` (rows) requires every deleted row to be loaded.
  - The refusal message is today's `still_loading` ("Still loading this part of the sheet…").

## 6. Conflicts and outcomes

The `RevOutcome`s of acked ops drive the conflict UI. They replace today's heuristics, which
compare the model after a sync cycle and look up the winner in the local `ChangeLog` (inventory
sheets-client §6, slides-client §5).

| Outcome | Sheets UI | Slides UI |
|---------|-----------|-----------|
| `conflicts` (overwritten: last arrival wins, Q1) | Toast "Your offline changes replaced {n} newer edits by {name} — Review". Dialog: cell, your value, their previous value, author; *Restore theirs* (undoable, one step) and *Dismiss* | "You replaced {name}'s newer text in {n} boxes", with *Restore theirs* |
| `dropped` (target or parent gone) | Entries "Row deleted by {name}" / "Column…" / "Sheet…" (no apply). The deleter comes from `rev_local_op` or `ops()` (the op that deleted the row; `byRev` when known) | "Slide deleted by {name}" |
| `cascaded` | Info toast "Also removed {n} cells added by {name}" (P2; logged in P1) | — |

- **When shown.** Only for `offline: true` ops (the online case is normal collaboration), and for Slides edits made with `forced` soft-lock claims (as today; `sum.forcedBodies`).
- **Storage.** Kept in `rev_outcome` until reviewed or 7 days old. The user-store keys `sheets.offlineEdits.*`, `sheets.conflicts.*`, `slides.offlineEdits.*` and `slides.conflicts.*` are removed.
- **Sorts.** A `sheet_row.sortKey` conflict on at least half the rows of an offline sort gives the sort toast ("Your sort was replaced").

## 7. App data layer and call-site migration

### 7.1 Sheets (`SheetsRevLog`, replaces `SheetsData`)

| Today (inventory sheets-client §4–§5) | With RevLog |
|---------------------------------------|-------------|
| `SheetsData.install/uninstall/current/ready` (`sheets_app_config.dart:125,136`) | `SheetsRevLog.install/uninstall/current/ready`: same lifecycle (per user, follows `currentUser`, pauses when hidden) |
| `openWorkbookSession(services, itemUuid)` | Same signature; `fileUuid = item.contentRef ?? itemUuid`; role `item.myRole`; subscribes `driveChanges → updateRole` |
| `SheetsData.createSpreadsheet` (reserved space + `registerSpreadsheet`) | **Online:** `drive.createSpreadsheet(fileUuid: v7, initialize: true, locale, timeZone)` (templates go to the server as today), then open. **Offline:** queue `PendingDriveOp(createSpreadsheet {fileUuid, parentUuid, name, initialize: false})`, create `rev_local_file(created_locally = 1)`, put the creation op (`CreateSpreadsheet` plan with `SheetsUserDefaults`) in the outbox, and open at once (§5.1). `NoReservedSpaceException` disappears |
| Import as new (`import_pipeline.dart:369-413`, second headless session) | Create with `initialize: false` (online: direct call; offline: queued), then `openWorkbookSession` for the new file, `CreateSpreadsheet` + chunked `applyChanges`, `flush`, `dispose`. The outbox chunks it into groups |
| Version copy (`version_copy.dart:26-57`, writes into a reserved space) | `SpaceCopier.changes(...)` → create with `initialize: false` (online direct or queued). The changes become the first op group. `sheetsVersion.copyExtras` unchanged (online only) |
| Script compile (`script_service.dart:1048-1050`: `flush()` + `syncNow()`) | `await session.whenSynced(timeout: 10 s)`, then `backend.compile` |
| Script user properties (`user_properties.dart`, personal space) | Online via `sheets.get/setUserProperties` (02 §2.4), cached per file in the user store (`sheets.userProps.<fileUuid>`). Offline writes are queued in the user store and flushed on reconnect (last write wins per key) |
| External agent highlights (`external_agent_writes.dart`, local `ChangeLog`) | `session.history` stream filtered to `actorKind ∈ {mcp, ai}` and `sessionId` starting with `server:`; ranges from `summary.ranges` |
| "Row deleted by" toast (`sheets_collab.dart:248-275`) | `session.history` (last hour), `summary.deleted` |
| Cell history (`cell_history.dart:310-346`) | Local: `session.history.recentOps` (30 days), `detail.cells`. Server: `sheets.cellHistory` (unchanged API; `changeLogId` → `revision`). Deduplicate by revision |
| Conflicts (`local_conflicts.dart`) | §6. `SheetsConflicts` keeps its dialog and commands; detection and tracking come from outcomes |
| Settings › Offline & storage (`ReplicaOfflineProvider`) | `RevOfflineProvider implements OfflineDataProvider`. `isAvailableOffline(item)` = `complete`. `usage` = files, pinned, pending changes (outbox rows), bytes, warnings. `clear()` empties the cache **after exporting non-empty outboxes** (§8) |
| *Simulate offline* | Unchanged (`ConnectivityService.forceOffline`); `ConnectionKeeper` drops the streams |
| Recovery export of a broken replica | Outbox export (§8) |
| `WorkbookLoading(progress)` "Downloading spreadsheet… N%" | Removed. `WorkbookLoading()` shows "Opening spreadsheet…". Delete the `downloadingSpreadsheet` string. Wire `loadingRowsStatus` to `rowLoading.progress` (the string exists but is unused) |

### 7.2 Slides (`SlidesRevLog`, replaces `SlidesData`)

- **`createPresentation`:**
  - **Built-in templates and blank decks** are created by the client with `initialize: false` (online: direct call; offline: queued), with the template's rows (`template.build(...).inserts`) as the creation op group.
  - **Non-built-in templates** are created on the server (`initialize: true` + `templateUuid`).
  - `NoReservedSpaceException` and its toast disappear.
- **`DeckOpenHistory`** feeds availability (§2.5).
- **Agent flash** (`mcp/agent_writes.dart`) and the **overwritten-text review** (`local_conflicts.dart`) use `session.history` / `session.outcomes`.
- **AI "wait for the slide to arrive"** (`ai_commands.dart:500-516`) waits in `session.history` for an op with the `recordId` returned by the AI endpoint (`RevServerChangeResult.recordId`, added to the responses). That replaces polling the model 40 × 250 ms.

### 7.3 Background sync of closed files

`RevLogClient.syncOutboxes()` runs on reconnect and on drive changes:

1. For every file with outbox rows that no open session of this tab owns, including adopted rows (§2.6), open a headless `RevSyncCore` connection (no model), keyed `'<app>.offline:<fileUuid>'`, as Write's `WriteOffline.syncOutboxes`.
2. **`RevInit.ops`:** apply them to the store (`applyServerOp`).
3. **`RevInit(bootstrap: true)`:** send the outbox only. Apply acks to the outbox (delete rows) **without domain writes**, set `complete = 0`, clear the file's coverage, and set `revision = 0`. The next open re-bootstraps (review 34).
4. Stop after the outbox is empty and 5 s of idle, or after 2 minutes.

Files with `created_locally = 1` wait until the queued create has replayed
(`CachedDriveRepository.isPendingCreate`). If the create **fails permanently** (replay dropped it
as non-retryable: quota, permission), the file is marked `orphaned` (§8).

## 8. Errors and unsynced data

| Situation | Behavior |
|-----------|----------|
| Access lost (`forbidden`; or `RevRoleChanged(viewer)` / `forbiddenForRole` with a non-empty outbox) | Read-only. Toast "You can no longer edit this spreadsheet". The outbox is kept for 7 days and offered as *Save my changes as a copy*, which creates a new file with `initialize: false` from server state + outbox (as Write's copy). Then it is discarded |
| Orphaned local file (queued create failed permanently) | Toast "This spreadsheet couldn't be created on the server", with *Save as new spreadsheet*: a new `fileUuid`, the same changes, queued again |
| Outbox older than 180 days | Not resent; offered as a copy |
| `schemaMismatch` | Stop sending; "Update required"; after the reload, §2.4 |
| `unknownBase` | Re-bootstrap; offer the outbox as a copy |
| Cache can't be opened | Read `rev_outbox` with plain SQLite (desktop) and offer *Download unsynced changes* (a ZIP with one JSON per file of the change sets). On the web the cache is emptied. Then start with a fresh cache |
| Rejected op | §4.6 |
| Offline edits rejected by a protection | *Save my changes as a copy* creates a new spreadsheet (`initialize: false`) from server state plus the rejected group, so nothing typed offline is lost (§4.6 step 5) |

## 9. Sync status

`SyncStatus` (`wonky_ui`) states keep their meaning, with "saved" now meaning acknowledged:

| State | Condition |
|-------|-----------|
| `saving` (+ `pendingChanges`, `progress` for groups) | this tab's outbox for the file is not empty, and connected |
| `saved` | outbox empty: **every change is acknowledged by the server**. Today "saved" means "in local SQLite" |
| `offline` ("Offline — changes saved on this device") | not connected; outbox durable |
| `connecting` / `reconnecting` (+ `reconnectAt`) | stream opening or backing off |
| `error` (+ retry) | a rejection waits for the user, or a store write failed |

## 10. Commit hints

- **Removed:** the `cell` and `range` hints (RD-18), the hint overlay's wait for synced rows (`_dropSynced`) and `CellRenderCache.hinted`.
- **Kept:** `typing` (Sheets), and the text, transform and structure hints (Slides), unchanged. `pending` (the shimmer for groups over 500 cells) stays and is now dropped when the group's last op arrives (`groupLast`).

The Slides text-hint removal rule (the synced text equals the hint) keeps working, because remote
batches still arrive as remote batches.
