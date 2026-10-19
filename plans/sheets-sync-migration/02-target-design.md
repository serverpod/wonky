# 02 · Target design: RevLog — a server-sequenced log of row changes

> **Superseded in detail by [spec/](spec/README.md).** Notable refinements there:
> - The domain tables move to `wonky_server` as `serverOnly` tables: a Serverpod shared package can't declare server tables.
> - Repairs stay client-side; the server normalization hook stays empty for now.
> - Stream messages are capped at 1 MiB compressed, with no separate large-submit RPC.
> - Creation has an `initialize` flag.
> - The review questions are decided (spec 01 §3): last arrival wins; protected ranges are enforced by the server; the domain classes are server-only.

**RevLog** is Write's architecture with Sheets' data. The server keeps a sequencer per file. It
holds a materialized current state in ordinary Postgres tables, an op log ordered by an integer
revision, and a Serverpod stream that pushes ops to connected clients. Clients keep a local cache
(server state at a revision, an op tail and a durable outbox) and the in-memory model they already
have. Ops are batches of `RowChange` (absolute column assignments, inserts and deletes by id), so
no operational transform is needed.

The design is generic over a *table set*: Sheets binds it first, Slides second (the same split as
today's `wonky_sync_kit`).

## 1. Vocabulary

| Term | Meaning |
|------|---------|
| **File** | One spreadsheet or deck (the drive item; its UUID is the file id) |
| **Change set** (op) | A list of `RowChange {table, rowId, op: insert/update/delete, columnsBefore, columnsAfter}` with `clientOpId`, `baseRevision`, `label`, `actorKind`, `groupId` (one undo step may span several ops) |
| **Revision** | Server-assigned, dense, per file. Revision `r` is the state after applying ops `1…r` |
| **Materialized state** | The current rows of the file in plain server tables (no CRDT metadata) |
| **Outbox** | The client's unacknowledged change sets (in flight + buffered), persisted before sending |

## 2. Packages and layering

| Package / folder | Kind | Contents | Replaces |
|------------------|------|----------|----------|
| `packages/wonky_revlog` (new, pure Dart) | shared | `RowChange`/`MutationPlan` (moved from `wonky_sync_kit`), `ChangeSet` codec (compact JSON, gzip over a threshold), apply rules (LWW per column, drop-if-parent-gone), `Overlay` (re-apply pending local changes over remote ones), op chunking (≤ 5,000 changes per op), `UndoInverter` + rows undo (moved), `RevTableSet` (table order, parent links, cascade rules) | `wonky_sync_kit` |
| `packages/wonky_revlog_flutter` (new) | client | `RevLogConnection` (stream, ot.js-style states without transform, gap fill, reconnect via a shared `ConnectionKeeper`), `RevLogStore` (SQLite cache: domain tables + revision + op tail + outbox), `RevLogBootstrap` (paged viewport-first download), `RevLogInstallation` (per-user lifecycle, *Settings › Offline & storage*), background sync of closed files with an outbox | `wonky_sync_kit_flutter` |
| `wonky_server/lib/src/platform/revlog/` (new) | server | `RevLogService` (submit, sequencing, apply, ack, broadcast, server changes), `RevLogConnection` (stream handler), `RevLogPages` (bootstrap/page reads), `RevLogHooks` (post-commit queue), `RevLogStore` (op log, prune), `RevLogBinding` interface | `platform/spaces/` (`SpaceSync`, `SpaceService`, kinds), the vendored engine |
| `wonky_server/lib/src/sheets/revlog/` | server binding | `SheetsRevLogBinding` (table set, validation, normalization, cell cap, protected ranges), post-commit hooks (activity, cell history, versions, triggers, title mirror) | `sheets/sync/`, `sheets/changelog/` consumer |
| `wonky_sheets/lib/features/revlog/` | client binding | `LoggedWorkbookSession implements WorkbookSession`, `SheetsLocalStore` (Sheets tables) | `features/sync/` (`SyncedWorkbookSession`, replica, writer, controller, remote patch) |
| `ConnectionKeeper` | moved to `wonky_app` | Reconnect/backoff from Write (`wonky_write/lib/features/sync/connection_keeper.dart`), shared by Write and RevLog | — |

Dependency rules (01 §2.1):

- `wonky_revlog` is pure Dart (server, cores and apps may use it).
- `wonky_revlog_flutter` depends on `wonky_app`/`wonky_client`.
- The cores (`wonky_sheets_core`, `wonky_slides_core`) depend on `wonky_revlog` only, as they depend on `wonky_sync_kit` today.

## 3. Server

### 3.1 Tables

Move the 24 Sheets models from `packages/wonky_sync_models` (`database: sync`) to ordinary server
tables. Keep the same columns and add `fileId` (the file UUID, indexed first in every index).
Drop `spaceId` and all CRDT metadata.

- **Model location.** Serverpod needs the generated classes on the client for the wire. They can stay in `wonky_sync_models` (rename the package later to `wonky_doc_models`) without `database: sync`. Phase 0 confirms that a shared package may declare plain tables; if not, the tables move to `wonky_server/lib/src/sheets/models/` and the wire uses the `ChangeSet` codec, not the generated classes.
- **Indexes:**
  - `cell (fileId, sheetId, rowId)`, `cell (fileId, sheetId, columnId)`;
  - `sheet_row (fileId, sheetId, sortKey)` and the same for columns;
  - `(fileId)` on every small table.
  - Cell ids stay deterministic UUIDv5. Phase 0 checks whether random-UUID primary-key inserts are the 1M-import bottleneck (`TODO.md`) and, if so, uses `(fileId, sheetId, rowId, columnId)` as the clustered/unique key and keeps `id` for references.
- **Revisions:** `rev_file` with `fileId` (unique), `kind` (spreadsheet/deck), `headRevision`, `createdAt`, `stats` (cell count, …) — one row per file, the lock target.
- **Op log:** `rev_op` with `fileId`, `revision`, `clientOpId`, `authorId`, `sessionId`, `actorKind`, `groupId`, `label`, `changes` (compressed bytes), `summaryJson` (sheets/ranges/kinds, as today's `ChangeLog.summaryJson`), `detailJson` (≤ 200 cells before/after, for cell history and revert), `createdAt`.
  - Unique `(fileId, revision)` and `(fileId, clientOpId)`; BRIN on `createdAt` for pruning.
  - This **replaces the synced `change_log` table**. History, cell history, MCP revert and activity read the op log.

No snapshots are needed for open: the materialized tables *are* the current state. Versions keep
their existing gzip NDJSON snapshots (`SheetsVersionProvider`, ~25 B/cell), captured at a revision.

### 3.2 Stream protocol

```dart
class SheetsDocEndpoint extends Endpoint {        // DeckDocEndpoint for Slides
  Stream<RevServerMessage> connect(Session s, UuidValue fileUuid, int knownRevision,
      Stream<RevClientMessage> input);
  Future<RevPage> page(Session s, UuidValue fileUuid, RevPageRequest request);   // bootstrap
  Future<List<RevOpView>> ops(Session s, UuidValue fileUuid, int from, int to);  // gap fill, ≤ 1,000
}
```

| Client → server | Fields |
|-----------------|--------|
| `RevSubmit` | `clientOpId`, `baseRevision`, `changes` (codec), `label`, `actorKind`, `groupId?`, `groupIndex`, `groupLast` |
| `RevRequestOps` | `from`, `to` |
| `RevPing` | `t` |

| Server → client | Fields |
|-----------------|--------|
| `RevInit` | `revision`, `role`, `meta`, `ops[]?` (tail since `knownRevision` if ≤ 1,000, else `bootstrap: true`) |
| `RevAck` | `clientOpId`, `revision`, `dropped[]` (changes whose target was gone), `overwritten[]` (fields whose current value ≠ `columnsBefore`), `fixups?` (server normalization, as a change set) |
| `RevRemoteOp` | `revision`, `changes`, `authorId`, `sessionId`, `actorKind`, `groupId`, `label`, `onBehalfOfSessionId?` |
| `RevRoleChanged` / `RevRejected{code}` / `RevPong` | |

- **Presence and cursors stay on the shared presence stream**, as today: Sheets cursors are id-based and need no transform.
- **Changes are small on the wire.** Each change set has a column dictionary per table. Changes encode as arrays (`[tableIdx, rowId(base62), op, [colIdx, value]…]`), and the set is gzipped when larger than 16 KB. Bulk payloads (> 1 MB) go over HTTP RPCs (`page`, and a `submitLarge` variant if Phase 0 shows that the stream frame size is a problem).

### 3.3 Submit algorithm (`RevLogService.submit`)

1. **Idempotency.** If `(fileId, clientOpId)` exists, reply `RevAck` with the stored revision and stored dropped/overwritten. Check again inside the transaction (Write has this race today: code-quality CQ-5).
2. **Permission.** Role ≥ editor (commenters write no rows; comments are not in the log). Re-checked on `RevRoleChanged`.
3. **Validate the change set only, never the whole file:**
   - table and column allowlist, value sizes, number of changes ≤ 5,000;
   - the cell cap from `rev_file.stats`;
   - protected ranges — *new*: enforced on the server.
4. **Lock and apply.** In one transaction:
   - take `pg_advisory_xact_lock(fileKey)` (or `SELECT … FOR UPDATE` on `rev_file`) and read `headRevision`;
   - apply with set-based SQL per table: `INSERT … SELECT FROM jsonb_to_recordset(@rows) ON CONFLICT (id) DO UPDATE SET <named columns>`, `UPDATE … FROM jsonb_to_recordset` for column updates, and `DELETE … WHERE id = ANY(@ids)` (cascading deletes by FK: cells of deleted rows, columns and sheets);
   - the inserts/updates join the parent tables (`WHERE EXISTS (row) AND EXISTS (column)`) so writes to deleted parents are dropped; collect the dropped ids with `RETURNING`;
   - compute `overwritten` by comparing `columnsBefore` with the pre-update values (`RETURNING` the old values through a CTE).
5. **Normalize.** Binding hook, e.g. auto-rename a duplicate sheet name or clamp `frozenRows`. Fix-ups are appended to the same op, so every client gets them.
6. **Record.** Insert `rev_op(revision = head + 1)`; update `rev_file.headRevision` and `stats` (only named columns). Commit.
7. **Push.** Post `RevRemoteOp` on the bus channel `rev:<fileId>` with **immediate flush** (no 1 s batching), then reply `RevAck`.
8. **Side effects, outside the lock and after the ack.** Enqueue on a per-file `RevLogHooks` queue: activity, drive `modifiedAt` (throttled), cell history (one multi-row insert), version state, title mirroring, comment orphaning, script `onEdit`/`onChange` triggers, linked-chart invalidation. This replaces `ChangeLogConsumer` and its receipts. Hooks are durable: a hook cursor per file (`rev_hook_cursor(fileId, hook, revision)`) makes them at-least-once and resumable after a crash, which also fixes the current "plugin failure is marked done" bug.

**Throughput.** One transaction with ~4 statements per op, serialized per file. A typing user produces ≤ 1 op per round trip (outbox buffering, §4.3). *Target:* p95 commit < 15 ms for ≤ 100 changes and < 300 ms for 5,000 changes.

**Big operations** (paste 100k cells, import, sort, restore) are planned as one undo step and
split into ops of ≤ 5,000 changes with the same `groupId`. Each op is atomic; collaborators see
them arrive progressively (as today with chunked transactions). Server-side writers (import,
restore) hold the file lock per chunk, not for the whole operation.

### 3.4 Server-originated changes

`RevLogService.submitServerChange(session, fileId, changes, actor, {onBehalfOfSessionId, groupId, label})`
follows the same path as a client submit (Write's `submitServerChange`). All of these move onto it:

- MCP and AI writes (`SheetsBulkWriter`, `sheets_writes.dart`);
- script commits (`ScriptService`);
- imports (`SheetsImportService`);
- version restore (`SheetsVersionProvider.restore`);
- `revertChange`/`reapplyChange`;
- copies and templates (`SpaceCopier`/`SpreadsheetFactory` → bulk insert into the materialized tables at revision 1).

### 3.5 Headless model (MCP, AI, exports, scripts, linked charts)

- `HeadlessWorkbookProvider` loads from the materialized tables (keyset pages by `fileId`), remembers the revision, and **subscribes to `rev:<fileId>`**. Each op is applied to the cached model in memory (`model.applyChanges`), and gaps are filled from `rev_op`.
- This removes the `age(xmin)` whole-space scans (H8) and the 60 s staleness re-check.
- Linked charts in Slides use the revision as the cache key instead of `COUNT(change_log)`.

### 3.6 Bootstrap pages (cold open without local data)

`page(fileUuid, request)` returns rows in pages, **viewport-first**:

1. `structure`: every non-cell table of the file. This is small, except for row/column entities of huge sheets, which page by sortKey.
2. `cells(sheetId, rowIds | sortKey range)`: 500–2,000 rows per page, the requested viewport first, then the active sheet, then the others.

Each page reads its rows **and** `headRevision` in a single SQL statement, so they come from one
snapshot and the page is exactly the state at revision `Rp`. The client connects with
`knownRevision = R0` (the revision of the first page) and keeps the ops it receives. Then:

- for each page: apply the rows, then re-apply only the ops with `revision > Rp` that touch rows of that page;
- ops with `revision ≤ Rp` are already contained in the page.

Ops are absolute assignments and the order is total, so the result equals the state at the head.

Pages are gzip-compressed (NDJSON, the version-snapshot codec). For files over the size where
paging is slower than one blob (Phase 0 measures this), the server can stream a cached
compressed snapshot at a revision, plus the tail.

## 4. Client

### 4.1 Local store (`sheets_<userId>.db`, new schema; Slides `slides_<userId>.db`)

Raw SQL on `sqlite_async` through `LocalDatabases.open`, as Write's `write_local_store.dart` does.

| Table | Fields |
|-------|--------|
| `local_file` | `fileId`, `itemJson`, `role`, `revision` (state stored = server state at this revision), `complete` (all pages loaded), `pinned`, `lastOpenedAt`, `sizeBytes` |
| domain tables (`cell`, `sheet_row`, …) | Same columns as the server tables. **No CRDT metadata, no triggers, no journal** |
| `local_op` | Server ops after `revision` that have not been folded in yet (folded in batches, as Write's 200-op compaction) |
| `local_pending_op` | Outbox: `fileId`, `seq`, `clientOpId`, `baseRevision`, `changes`, `label`, `groupId`, `inflight`, `createdAt` |
| `local_undo_stack` | As today (best effort) |

- A **local edit** costs one `local_pending_op` insert (plus the in-memory apply). The domain tables only ever hold *server* state.
- On reload, the store loads server state + outbox and overlays the outbox onto the model. This is Write's "server document + outbox" invariant.
- Applying a **remote op** is one transaction: set-based upserts and deletes of the changed rows, plus `revision = r`.

### 4.2 `LoggedWorkbookSession implements WorkbookSession`

The editor contract (`wonky_sheets/lib/features/model/workbook_session.dart:62`) stays as it is:

- **`execute` / `applyChanges`:**
  1. Plan.
  2. Apply to the model synchronously.
  3. Append to the outbox (durable).
  4. Hand to `RevLogConnection`.
- **Open:**
  - **Local and complete:** load from SQLite viewport-first (today's `_loadAll` logic, minus the journal), `WorkbookReady`, then connect with `knownRevision`.
  - **Not local (or incomplete) and online:** bootstrap pages from the server (§3.6). `WorkbookReady` after the first page — no full download first.
  - **Not local and offline:** `WorkbookUnavailable(offline)`, as today.
  - The existing `rowLoading`/`LoadingGate` machinery keeps working; rows are just fed from server pages instead of SQLite blocks.
- **Remote op:**
  1. Apply the changes to the model.
  2. Re-apply the outbox's columns for the same rows (`Overlay`, the generalized `RowPatch` overlay).
  3. Emit them on `remoteBatches`.
  4. Persist into the local store.
  - Echoes of the user's own ops are recognized by `clientOpId`.
- **Ack:**
  - Remove the op from the outbox.
  - Apply `fixups` like a remote op.
  - Remove `dropped` changes from the model (the target is gone, so the model removes them anyway when the delete arrived).
  - Report `overwritten` to `SheetsConflicts`.
- **Undo:** unchanged (`sheets.rows` domain, inverse against the current model, skipping columns that changed since). The inverse is submitted as a normal op.

### 4.3 Outbox and connection states

These are ot.js states without the transform:

- **Synchronized:** a local change becomes the in-flight op.
- **AwaitingAck:** later changes are buffered and composed per row and column (`composeRowChanges`, already in the kit) into one buffered op. Chunks are cut at 2 s windows and at 5,000 changes.
- **Ack:** the buffer becomes the in-flight op.

Ordering, gap fill and reconnect are Write's: revision-ordered queue, `RevRequestOps` on a gap,
resend the in-flight op with the same `clientOpId`. There is no rebase step and no prediction step:

- Remote ops never change the meaning of a local op (absolute assignments).
- The server's result is `dropped` / `overwritten` / `fixups`, which the ack carries explicitly.

### 4.4 Offline

- **Edits** accumulate in the outbox, composed per row and column, so a long offline session stays small.
- **Reconnect:** `connect(knownRevision)` → ops since then → overlay → resend the outbox. There is **no age limit** (no transform, so no `rebaseTooOld`).
- **Offline creation:**
  - The client generates the file UUID. `drive.createSpreadsheet` (idempotent) is queued in the shell's `PendingDriveOp`, as Write's `createDocument`.
  - The first outbox op carries the initial structure (spreadsheet, sheet, 1,000 rows, 26 columns).
  - **No reserved spaces.**
- **Availability** (as Write):
  - Spreadsheets opened in the last 14 days (max 50) or pinned are kept complete locally.
  - A file with an outbox is never evicted.
  - The IndexedDB fallback only limits how much is kept *offline*; opening online always works through pages.
- **Closed files with an outbox** sync in the background through a headless `RevLogConnection` (Write's `write_offline.dart` pattern).

### 4.5 Collaboration

- **Data latency** drops from 0.2–2.5 s to about one round trip.
- **Commit hints** (`commit_hints.dart`):
  - The `cell` and `range` hints can be removed; they were a workaround for U6.
  - Keep `typing` (characters while editing a cell) and `pending` (shimmer during big chunked operations).
- Cursors, follow mode and presence are unchanged.

### 4.6 What this removes

| Removed | Lines (approx.) |
|---------|-----------------|
| `third_party/serverpod_offline_sync` (vendored engine, OS-1…OS-9) and the hosted `serverpod_offline_sync_client/_server` dependencies | 26.4k |
| `wonky_sync_kit_flutter`: replica, journal, writer, `AppSyncController`, space opening, recovery reader | ~2.1k |
| Sheets `features/sync/` (replica, writer, controller, remote patch, recovery) and the journal parts of `features/model/` | ~2.5k |
| Server `platform/spaces/` (`SpaceSync`, `SpaceService`, kinds, reservations, subscriptions, active set, `ensureSubscribed`, `spaceStats`), `sheets/sync/`, the `ChangeLogConsumer` receipts | ~2.5k |
| The same for Slides (`features/sync/`, `slides/sync/`, `DeckChangeLog` consumer, pruning) | ~2k |
| Client tables `reserved_space`, `sheets_dirty_space`, `sheets_row_journal`, `sheets_journal_space`, all `crdt_*`/`offline_sync_*` tables, both server- and client-side | — |
| Workarounds: weekly purge, cell-cap eviction by membership, recovery export of a broken replica (the outbox is small and is exported instead), OS-8 kind filter | — |

New code: ≈ 4–5k lines (`wonky_revlog` ~1.2k incl. moved code, `wonky_revlog_flutter` ~1.8k,
server `platform/revlog` ~1.2k, bindings ~0.8k per app).

## 5. Slides on RevLog

- Slides binds the same packages: a `DeckRevLogBinding` (13 tables, normalization of §10 maintenance repairs) and `LoggedDeckSession implements DeckSession` (`wonky_slides/lib/features/model/deck_session.dart:64`).
- Decks are small: bootstrap is a single page (structure + all elements).
- **New option for text bodies.** With a server sequencer per deck, Slides 02 §4.5 option C ("OT per text body") becomes cheap. The server can rebase a body's Delta against the intervening ops on the same body with `WonkyOt.rebaseOnServer`, giving character-level merging inside one text box. The soft lock could then become advisory. That is a follow-up, not part of the migration.

## 6. Properties to test (Phase 1 onwards)

1. **Convergence fuzzer** (port Write's `convergence_fuzz_test`): N clients with random plans (cells, formats, row/column inserts and deletes, sheets, merges, rules), random delays, reorders and disconnects, against an in-process server → all models equal the server's materialized state.
2. **Bootstrap equivalence:** pages read at random revisions while ops commit → the client state equals the head (property test).
3. **Overlay:** remote op + outbox overlay = server result after ack (property test).
4. **Idempotency:** resend, duplicate, crash between persist and send.
5. **Undo** across remote edits (existing `sheets.rows` tests, re-pointed).
6. **Server bulk apply** equals per-row apply (replaces the OS-7 equivalence test).
7. **Performance suite** (`slow` tag), with the gates in the plan.
