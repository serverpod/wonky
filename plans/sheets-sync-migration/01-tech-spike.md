# 01 · Tech spike: Sheets sync today vs Write's architecture

Read-only investigation of `main` at `bee8c7f` (2026-10-17). Paths are relative to the repository
root. Numbers marked *measured* come from specs/STATUS/TODO; *estimate* means derived from code
reading and not measured.

## 1. What exists today

### 1.1 Write — server-authoritative OT

Specs: [`specs/wonky_write/03-sync-protocol.md`](../../specs/wonky_write/03-sync-protocol.md), suite 12 §1.

- **Model.** One linear Quill Delta per document. Comments and suggestions are Delta attributes,
  so they transform for free. Metadata (theme, page setup, language) is LWW through `updateMeta`.
- **Server** (`wonky_server/lib/src/write/ot/`, 1,634 lines plus a 70-line endpoint):
  - Endpoint: `DocumentEndpoint.connect(documentUuid, knownRevision, Stream<DocClientMessage>)`.
  - Tables: `document`, `document_op` (delta + inverse JSON, unique on revision and on clientOpId), `document_snapshot` (every 500 ops), `document_meta_change`.
  - Per op (`ot_service.dart:50-276`): idempotency check → row lock `SELECT … FOR UPDATE` → rebase against the composition of ops since the base → normalize and validate the whole document → insert op, update head → post on `ClusterBus` → after-commit bookkeeping → `Ack`. Other connections receive `RemoteOp`.
- **Client** (`wonky_write/lib/features/sync/document_sync_controller.dart`, 1,414 lines):
  - ot.js states (one op in flight, buffered chunks of ≤ 2 s).
  - Durable outbox in SQLite *before* sending (`features/offline/`, ~1.9k lines).
  - Strict revision ordering with gap fill.
  - Ack prediction; SHA-256 integrity check every 200 revisions.
- **Open.**
  - Cached: render from SQLite, then connect with `knownRevision` and receive the op tail (≤ 1,000), or a snapshot.
  - Cold: `DocInit` carries the whole document (uncompressed JSON).
- **Offline.** Outbox with `baseRevision`. On reconnect the server transforms against the ops since then. Offline edits older than the 30-day op-log retention get `rebaseTooOld`, and the client offers "save as a copy".

### 1.2 Sheets — CRDT replication (`serverpod_offline_sync`)

Specs: suite 12 §2, [`specs/wonky_sheets/02-data-model.md`](../../specs/wonky_sheets/02-data-model.md), Sheets 10.

- **Unit of replication:** one spreadsheet = one *space*. Every device replicates every space it is a member of, so the server manages an "active set" through membership (`SpaceSubscription`, max 30 per kind, LRU eviction). Each device keeps a pool of 3 reserved spaces for offline creation. The vendored patch OS-8 filters spaces per endpoint (spreadsheets vs decks), and a weekly job purges the local rows of evicted spaces.
- **Data:** 24 synced tables in `packages/wonky_sync_models` (same schema in Postgres and in client SQLite).
  - One `cell` row per non-empty cell with a deterministic UUIDv5 id; 24 columns, one per format attribute.
  - Rows and columns are entities ordered by fractional `sortKey`; formulas store id-based references.
  - The synced `change_log` table gets one row per undo step (replicated to every collaborator).
- **CRDT metadata per domain row:**
  - one `crdt_data_rows` row (HLC, visibility);
  - one `crdt_data_fields` row per separately-authored column, at least 3 per new cell (the FK fields);
  - tombstones and attempted values;
  - per-space node checkpoints.
- **Write path:**
  1. Planner → `RowChange`s → applied synchronously to the in-memory `WorkbookModel`.
  2. `SpaceWriteQueue` → `SyncWriter`: one transaction per ≤ 5,000 changes, set-based `bulkWrite` (OS-7), `ChangeLog` row, dirty mark, journal triggers.
  3. Nothing is pushed: the engine's continuous loop picks the changes up.
- **Loop** (`third_party/serverpod_offline_sync/lib/src/sync/engine.dart:265-403`):
  - Lock-step: send a batch in chunks of 100 changes as JSON, then wait for the peer's batch or a 1 s idle timeout, merge, sleep 200 ms.
  - Server side: `sheetsSync.sync` → `SpaceSync.sync` runs the engine as authoritative peer.
  - `onMergeSuccess` → `ChangeLogConsumer` (activity, cell history, versions, script triggers…).
  - Other devices get the change on their own stream's next cycle.
- **Open** (`SyncedWorkbookSession`, `wonky_sheets/lib/features/sync/synced_workbook_session.dart`):
  - `sheets.subscribe` grants membership. If the space is not on the device, the client waits for the engine download, polling local row counts every 500 ms ("Downloading spreadsheet… 42 %").
  - Then loading is viewport-first from SQLite: every non-cell table, then about 200 rows → `WorkbookReady`; the rest streams in blocks of 500 rows.
  - *Measured:* 200k cells ready in 0.55 s, complete in 8.8 s (from local SQLite).
- **Remote changes into the model:**
  - SQLite triggers append `(space, table, row)` to `sheets_row_journal` (U11).
  - After each merge the session re-reads those rows, overlays queued local writes, and builds a `RowPatch` → `model.applyChanges`.
- **Server-side reads:**
  - `HeadlessWorkbookProvider` (LRU, 2 GB budget) builds a `WorkbookModel` from the synced tables and patches it with an `age(xmin)` scan over the whole space.
  - Used by MCP, AI, exports, scripts and linked charts in Slides.
- **Server-side writes:** MCP, AI, scripts, imports and restores go through `SheetsBulkWriter` / `ServerSheetsWriter` (chunked `transactionForUser` + `bulkWrite`).

### 1.3 Slides — the same CRDT stack as Sheets

- **Client:**
  - `wonky_slides/lib/features/sync/slides_sync_controller.dart:35` extends the kit's `AppSyncController`;
  - `SlidesReplica extends SyncReplica`;
  - `SlidesWriter extends SyncWriter`;
  - `SyncedDeckSession` uses `SpaceWriteQueue` / `JournalIngestion`.
- **Server:** `slidesSync.sync` → `SpaceSync.sync(kind: deck)` (`wonky_server/lib/src/platform/spaces/space_sync.dart`).
- **Text bodies.** Slides borrows only the Delta *format* from Write. Concurrent edits are LWW per body with a presence soft lock (Slides 02 §4.4). Using Write's OT per text body was considered and rejected because it would be "a second sync mechanism next to the CRDT" (Slides 02 §4.5, option C).
- **Decks are small:** typically < 5,000 rows, loaded entirely before `DeckReady`.

**Conclusion:** there are exactly two sync systems: Write's OT log and the Sheets/Slides CRDT.

## 2. Where Sheets' sync spends its time (evidence)

| # | Hotspot | Evidence | Effect |
|---|---------|----------|--------|
| H1 | **Lock-step polling, no push** | `engine.dart:67` (100 changes/chunk), `:71` (200 ms interval), `:290` (1 s idle wait) | Remote propagation 0.2–2.5 s (suite 12 §2.1). Masked by presence "commit hints" (`wonky_sheets/lib/features/collab/hints/commit_hints.dart`, 476 lines), which are display-only: dependents are not recalculated until the row arrives. Every connected device costs ~0.8 cycles/s while idle |
| H2 | **Change capture scans all metadata each cycle** (U4, open) | `collectPendingChanges` filters `crdt_data_rows`/`_fields`/`_tombstone` with a CASE over (space, node) checkpoints (`engine.dart:797-835, 1197-1222`). The migrations have no index on any HLC column (checked `wonky_server/migrations/*/definition.sql`) | Per connected device, on the server *and* on the client (incl. the web wasm replica), cost grows with the total metadata of all synced spaces. Spec: "server CPU budget monitored" — no metric exists |
| H3 | **N+1 outbound reads** | `_fetchDomainRow` runs one `SELECT … WHERE id = … AND spaceId = …` per changed row (`engine.dart:614, 845-868`); `_fetchOwnedColumnValue` one per changed field (`:692, 911`) | A cold download of a 100k-cell sheet ≈ 100k point queries plus ≥ 300k field rows loaded. Big pastes pay the same per row on the receiving side of the server stream |
| H4 | **No streaming or bounded memory** (U3, open) | Outbound `find` materializes every changed metadata row. The client buffers the whole cycle until `EndOfBatch` and then merges | Memory spikes on cold download. The 1M-cell cold-sync gate (< 60 s desktop / < 120 s web, Sheets 13 M3) was never measured (no result in STATUS, TODO or tests) |
| H5 | **Write amplification** | One-cell commit: domain row + CRDT row/field upserts + `change_log` row + its CRDT metadata + journal trigger rows + dirty mark ≈ 8–10 SQLite writes; then the same on Postgres | *Measured:* new cells 60–120 µs each, updates ~40 µs; 1M-cell import ≈ 2 min (Sheets 02 §7, `TODO.md` "Sync / data layer") |
| H6 | **Storage per cell** | ~5 table rows per cell on the server (*estimate* 0.5–0.8 KB before content) vs ~25 B/cell gzip in a version snapshot | Postgres size, index cache pressure, backup size |
| H7 | **FK projection on deletes** | Deleting rows/columns on the server still runs the full projection: *measured* ~8 s per 500 rows at 50k cells (`TODO.md`). OS-6 only skips it for `cell` | Slow structural edits through MCP/AI/restore |
| H8 | **Server reads re-derive state** | `HeadlessWorkbookProvider._patch` scans the whole space by `age(xmin)` on every stale open and every 60 s re-check (`wonky_server/lib/src/sheets/headless/headless_workbook_provider.dart:196-216`) | Cost grows with spreadsheet size for every MCP/AI/linked-chart read |
| H9 | **"Sync every member space" workarounds** | Active set, reservations, OS-8 kind filter, weekly purge, IndexedDB 200k-cell cap with LRU eviction, pending-change guard (`ensureSubscribed`) | Complexity and latency on open: "Downloading spreadsheet…" before a big sheet that isn't on the device can show anything |
| H10 | **Lock-step synced schema** | `syncTablesHash`; projection rebuild on registry change (OS-9; incident 2026-10-15 crashed `serverpod start`) | Every synced-schema release is a coordinated client+server event |
| H11 | **Change-log consumer cost** | Per `ChangeLog` row: claim, profile, activity r/w, version r/w, `recordEdit`, title mirror (two reads), touch, orphans, plugins; `_history` 2 SQL per cell (up to ~400 per change); pending query anti-joins the 30-day log on every merge (`wonky_server/lib/src/sheets/changelog/change_log_consumer.dart:86-103, 197-230, 366-415`) | Server CPU and DB load proportional to edit rate × history size |
| H12 | **Maintenance burden** | Vendored engine 26.4k LOC with 9 local patches (OS-1…OS-9), 0.0.9 while upstream is at 0.0.11, no tests of its own in CI | Every fix to sync behavior is a patch to a fork |

What is **not** a hotspot: the in-memory model. `CellStore` is sparse and columnar; `AxisIndex`
uses a Fenwick tree; the grid and the formula engine never read SQLite; loading is viewport-first.
None of that depends on the sync transport, so a migration keeps it unchanged.

## 3. Why a Write-style log fits Sheets better than Write-style OT

Write needs OT because Delta positions are indices: a concurrent insert shifts every later
position. Sheets addresses everything by stable id:

- cells by `(sheetId, rowId, colId)`, with deterministic cell ids;
- rows and columns by UUID, ordered by fractional `sortKey`;
- formula references by row and column id (`⟦R:…;C:…⟧`), with sortKey hints that let range
  endpoints survive deletes deterministically;
- range-based rules by id-based `GridRange` JSON.

Each `RowChange` is an **absolute assignment of named columns** (`columnsAfter`), plus inserts and
deletes by id. Two concurrent change sets therefore commute except in three cases:

1. **The same column of the same row:** a pure LWW choice. Today the newest HLC (author time)
   wins. Under a sequencer the later *arrival* wins: same result online; different for late
   offline edits (§5).
2. **Delete versus edit:** a change to a cell whose row, column or sheet was deleted is dropped.
   This is the same rule the CRDT's FK projection implements today ("deleting a row/column wins",
   Sheets 02 §3.3).
3. **Invariants spanning rows:** duplicate sheet names, overlapping merges, frozen counts beyond
   the grid. Today the first client that notices repairs them deterministically (Sheets 02 §8). A
   sequencer can **validate and normalize on the server** instead (upstream wish U9, impossible
   with the CRDT).

So the "transform" function of Write's architecture becomes *identity + drop-if-target-gone +
optional server normalization*. This is the model Figma's multiplayer uses (server-authoritative,
property-level LWW, client overlays its unacknowledged changes). It avoids the main research risk
of spreadsheet OT, which needs index transforms for row/column inserts.

## 4. Options considered

| Option | What | Performance gain | Cost | Verdict |
|--------|------|------------------|------|---------|
| **A. Keep the CRDT, patch the engine** (U3 streaming, U4 HLC index, U5 snapshot bootstrap, U6 push) | Four deep patches to a 26k-line fork without tests | H1–H4 partly. H5, H6, H9, H10 stay (they come from the CRDT metadata model) | ≈ 10–12 weeks, high risk (fork drifts further from upstream, see code-quality CQ-62) | Not recommended |
| **B. RevLog: Write's architecture with row-change ops** (this proposal) | Server sequencer per spreadsheet, op log, materialized server state, paged viewport-first bootstrap, outbox, push over a Serverpod stream | H1–H12 all addressed | ≈ 16 weeks for Sheets, +5 for Slides, +2 for removal | **Recommended**, gated by Phase 0 |
| C. Full spreadsheet OT (index-based ops like Google Sheets) | New op algebra with transform/compose/invert | Same as B | Much larger: research risk, fuzzers, rewrites the model's id-based design | Rejected: B gets the same result without an algebra |
| D. Hybrid: keep the CRDT, add a server "poke" stream | On `onMergeSuccess`, poke other devices' engines so they sync at once | H1 only (latency) | ≈ 1–2 weeks | Fallback if B is rejected or Phase 0 fails: cheap latency win |

## 5. Behavior changes to accept

| Topic | Today | With RevLog | Mitigation |
|-------|-------|-------------|------------|
| Late offline edit vs newer online edit of the same cell field | Older HLC loses (the online edit survives) | Later arrival wins (the offline edit overwrites) | The server compares each change's `columnsBefore` with the current value and reports the fields it overwrote in the `Ack`. The existing conflict review (`SheetsConflicts`, Sheets 10 §9) shows them with *Keep mine / Restore theirs*. Google Sheets and Write behave this way too |
| Offline creation | Reserved spaces (pool of 3) | Client-generated UUID + idempotent create (as Write's `createDocument`) | Simpler: no reservations |
| Opening a spreadsheet not on the device | Wait for the whole download | Opens from the server page by page; offline availability needs a complete download (recent/pinned, as Write) | Better UX |
| Offline horizon | None | None. Ops need no transform, so there is no `rebaseTooOld` | Op log retention only affects history, not sync |
| Server-side validation | Advisory (protected ranges enforced client-side only) | The server can reject or normalize (protected ranges, cell cap, roles) | New capability |
| Sync of computed values | Never | Never (unchanged, S9) | — |

## 6. Write's weaknesses the new system must not copy

Found by the code-quality review (CQ-4, CQ-5, CQ-22, CQ-23):

- **Side effects inside the lock.** `_afterCommit` (activity, versions, drive, snapshot) runs inside the per-document lock, before the `Ack` (`ot_service.dart:101, 262`). RevLog acks and broadcasts first and runs side effects from a per-document queue.
- **Whole-document validate per op** (`ot_service.dart:155-205`). RevLog validates only the change set and the rows it touches.
- **Uncompressed cold open.** `DocInit` sends the whole document uncompressed. RevLog pages and compresses.
- **Stale full-row writes.** `updateMeta` rewrites the whole `document` row from a stale read and can roll back `headRevision` (`document_service.dart:145,227`). RevLog updates only named columns and keeps the head in one place.
- **A broken connection queue.** The handler queue dies on the first unexpected exception (`document_connection.dart:169`). RevLog catches `Object` per message.
- **A leaking cache.** The headless document cache never releases documents used without a connection (`document_cache.dart:198, 208`). RevLog uses retain/release for headless use.
- **Cross-instance delay.** The bus flushes every 1 s (`cluster_bus.dart:24`). RevLog channels flush immediately; Slides presentations already do.

## 7. Open questions (answered in Phase 0)

1. Real cold-sync time and server CPU of the current engine at 100k and 1M cells, and the idle cost with N devices (`EXPLAIN` the capture query).
2. Real bytes per cell in Postgres and SQLite (`pg_total_relation_size`).
3. Prototype numbers:
   - submit → remote apply p50/p95 on one instance and on two;
   - bulk apply of 5,000 changes in Postgres;
   - paged bootstrap of 1M cells on desktop and on web/OPFS.
4. Whether Serverpod's streaming WebSocket is a bottleneck for 1–5 MB change sets, or whether bulk payloads should go over HTTP RPCs (the same question applies to bootstrap pages).
5. Whether the IndexedDB fallback (no OPFS) still needs a cell cap. With server-side paging only *offline* availability depends on the local store.
