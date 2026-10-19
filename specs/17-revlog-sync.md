# 17 · RevLog sync (Wonky Sheets and Wonky Slides)

**Status:** built (M13). Wonky Sheets and Wonky Slides sync through **RevLog**, a
server-sequenced, revision-ordered log of row changes. It replaced the vendored
`serverpod_offline_sync` CRDT engine. Wonky Write keeps its own OT protocol
([wonky_write/03](wonky_write/03-sync-protocol.md)), which RevLog's connection code was lifted from.

**What RevLog is.** Every spreadsheet or deck is one **file** with a head revision. Clients keep a
local cache of the file's rows plus a durable **outbox** of their own changes. A change set (an
**op**) is sent over a Serverpod stream; the server applies it to the domain tables in one
transaction, gives it the next revision and fans it out to every other open connection. There is
no operational transform: Sheets and Slides address everything by stable id, so ops are column
assignments with "last arrival wins" per column and "delete wins" for rows. Offline editing works
as before: the outbox survives reloads and is sent when the connection returns.

**How this spec is organized.** Parts 1–6 are the implementation specification (decisions, data
model, change sets, protocol, server, client). Part 7 holds the performance gates. References of
the form `05 §3.3` point to part 5 §3.3 of this file. The **As built** section below records
where the implementation differs from parts 1–7; where they disagree, **As built** wins.

Code: `packages/wonky_revlog` (pure Dart core: schema, codec, apply rules, overlay, client state
machine, chunker; test doubles in `testing.dart`), `packages/wonky_revlog_flutter` (client cache,
transport, per-file connection, per-user client; fakes in `testing.dart`),
`wonky_server/lib/src/platform/revlog/` (sequencer, connection, pages, hooks, headless cache, jobs)
and the bindings `wonky_server/lib/src/sheets/revlog/`, `wonky_server/lib/src/slides/revlog/`,
`wonky_sheets/lib/features/revlog/`, `wonky_slides/lib/features/revlog/`.

## As built

Differences from parts 1–7, and decisions made while implementing:

1. **Client cache layout (02, 06 §2).** Domain rows live in generic tables instead of one table
   per schema table, so the cache needs no DDL per schema and survives schema changes with a
   reset (`RevDomainRows`, `wonky_revlog_flutter/lib/src/store/`):
   - `rev_row(fid, tbl, id, data)` (`WITHOUT ROWID`) holds structure rows, one record each;
   - `rev_cells(rid, fid, tbl, scope, row_key, data)` holds the rows of `cellsByRow` tables
     (Sheets cells) with **one record per sheet row**: every cell of that row in one blob, so a
     viewport or streaming read touches one record per sheet row and a bootstrap page writes
     500 records instead of 13,000;
   - `rev_cell_id(fid, h, rid)` finds a cell's record from its id (an applied update or delete
     carries no sheet/row key): `h` is 52 bits of the id (exact on the web), and the decoded
     ids are checked, so collisions only cost a decode. A bootstrap writes its records without
     these entries and adds them, sorted, in the transaction that marks the file complete
     (random-key inserts dirtied the whole index on every page); until then nothing looks
     cells up by id (domain writes wait for the end of the bootstrap; a page's replayed changes
     find their cells in the page).

   `fid` is an integer per file (`rev_fid`), `tbl` the table's index in the schema, and `data`
   a compact binary row encoding (`RevRowWriter`: the column's index and a tagged value; UUIDs
   as 16 bytes, integers as varints, null columns and the key columns left out). A 1M-cell file
   takes ~110 MB (~112 bytes per cell; the JSON layout took 700). Layout changes are cache
   migrations that reset server state; the outbox stays. The other tables (`rev_meta`,
   `rev_local_file`, `rev_coverage`, `rev_local_op`, `rev_outbox`, `rev_outcome`) are as
   specified; a complete file keeps no coverage keys (a new bootstrap starts from a reset).
2. **File ids.** The file uuid is the drive item uuid and `DriveItem.contentRef` (decks and
   spreadsheets created on a device use their own uuid for both).
3. **Creation is atomic (04, 05 §8.3).** `RevLogService.createFile` inserts `rev_file`, the hook
   state and every initial chunk in **one** transaction (deterministic op ids
   `uuid v5(file, 'init:i')`); `initPending` is not needed. Files created on a device
   (`initialize: false`) take the client's creation op as their first op. The cache of a file
   created on a device is marked complete at once, so it reopens offline.
4. **Wire shapes (04).** `RevRemoteOp` nests a `RevOpView`. Server-side writes use session ids
   `server:<actorKind>`.
5. **Server changes (05 §7).** `submitServerChange` orders changes parents first (`parentsFirst`)
   and normalizes column values per column (uuids as strings, UTC times), so server writers may
   pass `UuidValue`s. Records for undo: `ServerChangeRecord.recordId` links the record to its ops
   (`rev_op.recordId`); the legacy inline/file inverse fields stay for records written before
   (composite assistant changes); `spreadsheetUuid` also holds deck file uuids.
6. **Apply rules (03 §4).** An update is checked only against the parents it changes (moving an
   element to a layout or a group no longer drops it as `parentMissing`).
7. **Times.** Planners use millisecond-precision time, the precision the codec stores and sends,
   so a writer's model equals everyone else's.
8. **Partial caches (06 §5.4).** Reopening a partly loaded file reloads it from the server (the
   outbox stays) instead of resuming per coverage key.
9. **Several tabs (06 §2.6).** A tab adopts the outboxes of tabs that have been gone for 10
   minutes.
10. **Rejections (06 §4.6).** The model rolls back, the plan's undo step is removed when it is the
    top step (a buried step's undo finds nothing to revert and is skipped by the per-column rule),
    and one toast names the change and the reason. *Save my changes as a copy* is a follow-up.
11. **Conflicts (06 §6).** The Sheets and Slides conflict reviews keep tracking the cells and text
    bodies written offline and compare them after the outbox drained; the deciding op comes from
    `rev_local_op`. Outcomes are stored and exposed as `session.outcomes`; a review fed directly by
    outcomes is a follow-up.
12. **Loading gates (06 §5.5).** Built as specified: deleting a sheet or columns waits for the whole
    sheet, deleting rows waits for those rows.
13. **Script user properties.** Server table `script_user_property` (read/written with
    `sheets.getUserProperties` / `setUserProperties`), with a copy and the unsent changes in the
    user's local store for offline runs.
14. **Headless models (05 §9).** `HeadlessWorkbookProvider.open` keeps its lease until the
    request's session closes; the cache evicts only after a new entry is leased.
15. **Unsynced-data download (06 §8).** The recovery download of a cache that can't be opened is
    not built yet; on such a failure the editor offers *Try again*. *Clear local data*
    (`RevOfflineProvider.clear`) empties the cache, outboxes included, without exporting them
    first (06 §7.1).
16. **Test doubles (09 §1).** `FakeRevServer` (`wonky_revlog/testing.dart`) and `FakeRevHub` /
    `FakeRevTransport` (`wonky_revlog_flutter/testing.dart`): an in-process server with the real
    apply rules, used by the client, Sheets and Slides tests.
17. **Client-side creation (04 §5, 06 §7).** The clients keep calling
    `drive.registerSpreadsheet(spaceUuid, parentUuid, name)` / `registerPresentation`, which now
    mean `create*(fileUuid: spaceUuid, initialize: false)` (with a fallback to My Drive when the
    parent folder is gone or no longer writable), and `PendingDriveOp` keeps the kinds
    `registerSpreadsheet` / `registerPresentation`. The `createSpreadsheet` endpoint has no
    `fileUuid` / `initialize` parameters (the service has them); `createPresentation` has both.
18. **Assistant runs (RD-21, 05 §8.1).** Each assistant tool call is its own recorded server
    change; at the end of a run its records are combined into one composite record
    (`ServerChangeRecords.composite` in `platform/revlog/server_change_records.dart`: the calls' ops move to one record id), which is the run's single
    undo step. Reverting it reverts the calls' changes in reverse order with the skip rule.
19. **MCP `changes.revert`** keeps "own changes only" (Editor+, not yet reverted, 24 h), stricter
    than the endpoints' Editor+ rule.
20. **Enums (RD-5, 02 §2.1).** No pure-Dart twins in `wonky_sync_models`: the Sheets and Slides
    enums are Serverpod enums generated next to the server tables and shared through
    `wonky_client`; the cores use enum names (`RevColumnType.enumName`).
21. **Deck repairs (06 §1.2).** `LoggedDeckSession.runMaintenance` waits while another
    connection's op group is half applied or this tab's outbox is not empty, and retries later.
22. **Overlay (03 §7).** `Overlay.build(...)` in parts 3 and 6 is the class `RevOverlay`
    (`wonky_revlog/lib/src/apply/overlay.dart`) with `remote`, `acked`, `rejected` and
    `rebuild`; the per-sheet `cell.fileId` is a plain column without a foreign key (02 §2.1), so
    deleting a `rev_file` doesn't scan the cell table.
23. **Performance (R6, part 7).** Server rows are read as `json_strip_nulls(row_to_json(t))`; an
    op's prefetch is one statement for all tables (CTEs, still `FOR UPDATE`); rows that did not
    exist at the prefetch are written with a plain `INSERT`, the others with the upsert of 05
    §3.3; headless loads keyset per-sheet tables along their `(sheetId, rowId)` index; the file
    state caches the drive item id. The codec memoizes UUIDs per payload and `Base62Uuid`
    converts with 16-bit limbs; `RevOverlay` keeps an index of the outbox (key → ops). The client
    cache writes rows in batches, stores row JSON without null columns and rewrites only the
    outbox rows that changed. The measured gates and the misses (P7, P8, P10 as one
    transaction, P9's planner) are in part 7.
24. **Client performance (R7, part 7).**
    - **Reopen from the cache is viewport-first** (06 §5.1): the structure
      (`RevLocalStore.loadStructure`), the cells of the plan's first block
      (`loadScopedAt`), the outbox on top, then ready; the rest of the cells stream in from the
      cache through the same `RevBootstrapPlan` (250 sheet rows per read), so `LoadingGate`,
      `#LOADING` and the shimmer work as during a cold open. Exactness as for pages (06 §5.3):
      each read returns its rows with the revision `Rs` of the stored state (one read
      transaction); ops processed while streaming are buffered; the buffered changes newer than
      `Rs` are replayed on the rows read; rows the outbox touches are seeded in the overlay with
      that server state and rebuilt (`RevFileSync._applyCached`). A bootstrap from the server
      stops the streaming. Decks (no cell table) load everything as before.
    - **A finished bootstrap stores its revision** (`markComplete(revision:)`, the last op
      processed), so the file reopens from the cache; before, a file without ops since its
      download kept `revision = 0` and was downloaded again.
    - **Page writes** don't hold up the model or ready (P6): they are queued in order and not
      awaited, with backpressure on the oldest writes beyond 120,000 queued rows; consecutive
      queued pages are written in one transaction (`applyPages`), and new cell rows in one
      round trip to the database worker (`computeWithDatabase`, native; the web runs the
      statements). A store write that waits for the UI isolate between its statements fell
      behind a download.
    - **Model and planner** (P7, P9): one cell id hash per written cell and `Uuid5` without
      per-call allocations; row and column number formats read once per row and column of a
      paste; plan changes ordered by rank with buckets instead of a comparison sort; cells kept
      out of `WorkbookModel`'s owner map (a sheet lookup finds a cell's sheet); the formula
      engine's cell keys are records instead of 110-character strings, and its range index
      buckets the entries added since its last rebuild by blocks of 16 rows (stabs scanned all
      of them); loaded rows are wrapped (`RowChange.loaded`) instead of copied; the chunker no
      longer composes two full chunks of one plan just to find they don't fit.
    - `_SheetsPlan` hands out each row once (a walk per sheet instead of copying the missing
      rows per block), so several cell pages can be in flight (06 §5.2).
25. **Wire and server performance (R7, part 7).**
    - **Page format version 2** (04 §3.1): binary and columnar (ids once, per-column blocks
      with presence bitmaps, UUID and string dictionaries, varints, zlib where it saves ≥ 20 %),
      negotiated with `RevPageRequest.format`; version 1 (gzip NDJSON) is still served to
      clients without `format` and decoded from servers that ignore it. Decoded rows leave null
      columns out unless the column has a non-null default. A 13,000-cell page: 360 → 250 KB,
      encode 52 → 4 ms, decode 64 → 13 ms.
    - **Server pages** (05 §7) read each table as one row of typed arrays (`array_agg`, UUIDs
      as `uuid_send` bytes) straight into `RevPageBuilder`; cell pages probe the
      `(sheetId, rowId)` index once per sheet row (`unnest … LATERAL … OFFSET 0`), because with
      `rowId = ANY(…)` and statistics older than a big sheet Postgres scanned the whole sheet
      through `cell_col_idx` (2.4 s per page at 1M cells); the cascade of deleted rows' cells
      uses the same form. `RevAnalyze` analyzes the cell table in the background after every
      100,000 committed cell inserts.
    - **Client pages** (06 §5.2): up to 3 cell pages in flight, applied in request order;
      decoding off the UI thread (`RevPageDecoder`: an isolate per page on native, ~8 ms slices
      on the web).
    - **Commits** (05 §3.3): the prefetch reads typed arrays (UUIDs as text) instead of JSON
      rows; inserts and updates send one binary array per column (`unnest`); rows the op read
      are `UPDATE`d in place with only their changed columns (falling back to the upsert when a
      database cascade removed one earlier in the op); the applied form is encoded and gzipped
      once (an all-insert op's view reuses it); file creation answers the prefetch from memory
      (`_CreatedRows`) and builds no views. The cell table has `fillfactor = 85`
      (`RevStorage`, ensured at server start and in `withWonkyServerpod`, since models can't
      declare storage parameters), so rewritten cells can be HOT.



## Part 1 · Decisions, terms, limits and configuration


This is the authoritative list of choices for the RevLog implementation. Later files refer to them
as **RD-n**. The review questions Q1–Q3 were decided on 2026-10-18 (§3).

### 1. Terms

| Term | Meaning |
|------|---------|
| **File** | One spreadsheet or one deck. Its id (**file UUID**) is the drive item UUID, the id of the root row (`Spreadsheet.id` / `Deck.id`) and `DriveItem.contentRef`, as today |
| **Root table** | `spreadsheet` (Sheets) or `deck` (Slides) |
| **Domain tables** | The 24 Sheets and 13 Slides tables that hold file content (02 §2), minus `change_log` and `deck_change_log`, which are removed |
| **`RowChange`** | One row-level change: `{table, rowId, op: insert/update/delete, before, after}`. The existing class, moved to `wonky_revlog` (03 §1) |
| **Change set** (op) | An ordered list of `RowChange`s plus metadata (03 §2). It is the unit of submission, sequencing and acknowledgement |
| **Group** | The ops that form one undo step or one server operation (`groupId`); a plan larger than one op is split into a group |
| **Revision** | A dense integer per file, assigned by the server. Revision *r* is the file state after applying ops 1…*r*; revision 1 is the creation op |
| **Materialized state** | The current rows of a file in the server's domain tables |
| **Outbox** | The client's unacknowledged change sets for a file (one in flight plus buffered), persisted before sending |
| **Sequencer** | The server code path that assigns revisions: `RevLogService.submit` |
| **Binding** | The per-app plug-in (Sheets or Slides) that provides the table schema, validation, normalization and hooks |
| **Applied form** | The normalized version of an op that the server actually committed (RD-20, 03 §4.7) |
| **Record** | The ops of one revertible server change or assistant run (`recordId`, RD-21) |

### 2. Decisions

| # | Decision | Why |
|---|----------|-----|
| RD-1 | **The server totally orders the ops of a file by revision.** One sequencer per file (Postgres row lock on `rev_file`) across instances; one in-memory lock per file per instance in front of it, as Write does | Same guarantee as Write's OT, without the transform |
| RD-2 | **No transform.** A change assigns absolute column values (`after`) to rows addressed by stable ids. Ops are applied in revision order, so later ops overwrite earlier ones per column (LWW by sequence). Concurrent inserts of the same id merge per column: an insert into an existing row writes only its non-null columns (the rule of today's offline-sync patch OS-4) | Sheets and Slides address everything by id (rows, columns, cells, elements, formula references, ranges) |
| RD-3 | **Delete wins, and parents must exist.** A change to a row whose row or a parent row is gone is dropped and reported (`dropped`). Parent/child relations come from `RevSchema`, and the **sequencer cascades explicitly**: when it deletes a row, it also deletes its descendants. Database FKs with `ON DELETE CASCADE` remain as a safety net, except for `cell.rowId`/`cell.columnId`, which become plain columns (02 §2.1) because an FK on them would need two extra indexes on the largest table. **Plans must list every descendant they delete** so that undo can restore them. The planners already do (`planDeleteDimension`, `planDeleteSheet`, `deleteElementTree`), but only for what the model contains. So **deleting rows, columns or sheets requires those parts to be loaded** (`LoadingGate`, 06 §5.5), and a property test enforces the rule (09 §2.4) | Today's FK projection gives the same "delete wins" result |
| RD-4 | **The materialized state is in ordinary server tables.** The domain tables move from `packages/wonky_sync_models` (`database: sync`) to `wonky_server/lib/src/{sheets,slides}/models/rows/` as `serverOnly: true` tables (a shared package can only declare `all`/`sync` tables; inventory §4). That is **22 Sheets tables** (the 24 `.spy.yaml` minus `change_log` and `script_user_property`) and **12 Slides tables** (minus `deck_change_log`). They get `fileId` (FK to `rev_file`) and `revision` columns and lose `spaceId` | No CRDT metadata. One row per cell |
| RD-5 | **The table schema is shared as pure Dart.** The types (`RevSchema`, `RevTable`, `RevColumn`) live in `wonky_revlog`. The instances live in the cores: `sheetsSchema` in `wonky_sheets_core`, `slidesSchema` in `wonky_slides_core` (02 §4). The server, the cores and the clients use them for codecs, SQL and the client cache DDL; a server guard test compares them with the generated tables. The domain **enums** that the cores use today from generated code (`Dimension`, `HorizontalAlign`, `SheetKind`, …, 108 importing files) become hand-written pure-Dart enums in `wonky_sync_models` with the same names and values. The server keeps Serverpod enums for its tables, and a guard test compares the value names. `wonky_sync_models` keeps `ids` and the enums, and becomes pure once Slides has moved (R8). Renaming it is optional and not part of this work | One source for three consumers; the generated client classes are no longer needed |
| RD-6 | **The op log replaces the synced change logs.** `rev_op` stores every op: author, actor, label, summary, detail (≤ 200 cells, as today) and the compressed **applied** changes including `before`. After 30 days the payload, summary and detail of an op are pruned, but a slim row `(fileId, revision, clientOpId, author, committedAt)` stays for a year. That keeps resends idempotent across long offline periods (05 §10). `change_log` and `deck_change_log` disappear | One record per change, written in the same transaction; history, cell history, revert and activity read it |
| RD-7 | **Transport.** One Serverpod bidirectional stream per open file (`SheetsDocEndpoint.connect` / `SlidesDocEndpoint.connect`), like Write's `document.connect`. Unary RPCs for bootstrap pages and op ranges. **No stream message exceeds 1 MiB compressed** (Serverpod has no WebSocket size limit, so we impose one; inventory write-infra §5). Payloads over 16 KiB are gzip-compressed | Proven pattern in this codebase |
| RD-8 | **Immediate fan-out.** `ClusterBus.post` gets `immediate: true`, which publishes at once instead of waiting for the 1 s batch (today only Slides presenting forces a full flush). Used for `rev:<fileUuid>` channels and Write's `doc:` op messages | Cross-instance propagation within the latency budget |
| RD-9 | **Access is the drive item's ACL.** `AccessService` is checked on connect, on every submit and on every RPC. Role changes reach open streams through the existing ACL event path (`acl_events.dart` → bus `role` message → re-check), as Write does. Spaces, memberships, reservations and subscriptions are removed | One permission model for all apps; expired grants stop writes at once (fixes code-quality CQ-16 for these apps) |
| RD-10 | **Side effects run after the ack from durable hook cursors.** Activity, drive `modifiedAt`/search text, cell history, version state, title mirroring, comment orphaning, script triggers and linked-chart invalidation run in a per-file queue after commit, debounced about 1 s. Per file, one `rev_hook_state` row holds every hook's cursor and a lease, so only one instance drains a file. The hooks are at-least-once and resume after a crash (05 §6) | Never inside the sequencer lock (Write's mistake, CQ-22); no lost side effects |
| RD-11 | **The client store is a cache.** It holds the server state at a known revision, the outbox, recent op metadata and view data. It is never the source of truth. When its schema version differs from the app's, the client drops the domain tables and re-downloads them, keeping the outbox (06 §2.4) | No lock-step schema releases |
| RD-12 | **Opening is viewport-first from the server.** A file that is not on the device opens after its first page (structure + visible rows); the rest streams in. Pages carry the revision they were read at, so they combine exactly with ops (05 §7) | Big files open in about a second |
| RD-13 | **Offline creation uses client UUIDs.** The client generates the file UUID and queues an idempotent `drive.createSpreadsheet` / `drive.createPresentation` (`PendingDriveOp`). The creation op is the file's first outbox op. No reserved spaces | Same as Write's offline `createDocument` |
| RD-14 | **Validation on the server; repairs stay on the client.** Every submit is checked against the schema and limits (02 §4, 03 §5). The deterministic, idempotent maintenance repairs stay where they run today: Slides' 12 `DeckMaintenance` rules and Sheets' `AnchorMaintenance`, executed by an editor's client after remote batches. In addition, Sheets wires the core's `WorkbookMaintenance`, which exists but is not called anywhere today. The server hook `RevBinding.normalize` exists and is empty in this migration (03 §6) | Repairs need the whole model, which the clients have and the sequencer should not load. A sequencer makes conflicting repairs rare, and the repairs are idempotent anyway |
| RD-15 | **Undo is unchanged.** `sheets.rows` / `slides.rows` invert against the current model with the per-column skip rule. Server changes keep `ServerChangeRecord`, but the inverse is computed from the op group's stored `before` values instead of a separate inverse file (05 §8) | No behavior change for users |
| RD-16 | **Slides follows Sheets** with the same packages and its own binding (spec file 08). Text bodies stay last-writer-wins per body, with soft locks | One sync system for both apps |
| RD-17 | **No data migration.** Destructive server migrations; client replica files of the old engine are deleted on first start. Protocol bump: `minClientVersion` → 3.0.0 | No users yet |
| RD-18 | **Cell hints are reduced.** The `cell` and `range` commit hints are removed; `typing` and `pending` stay (07 §6) | Data arrives in about one round trip |
| RD-19 | **Protected ranges are enforced by the server (decided, Q2).** For Sheets ops on files with protections, the sequencer runs the core's `ProtectionGuard`, the same code as the client's write gate, against the server's model of the file at the previous revision. An op that writes a protected cell, row, column, rule, filter, object or sheet the author may not edit is rejected whole (`protectedRange`). Warning-only protections never block on the server (the client asked for confirmation). Files without protections pay nothing. Design: 05 §3.5 | Today protection is advisory: a modified or stale client, or an offline edit made before a protection arrived, can write protected cells |
| RD-20 | **Every committed op has one *applied* form, and only that form is ever replayed.** The server normalizes the submitted changes into the applied changes (03 §4.7):<br>• a merged insert becomes an `update` of the columns it wrote, with their `before`;<br>• dropped changes are removed;<br>• cascaded deletes are added.<br>Remote ops, pages, catch-up and the author's own ack all deliver this form, or say it equals the submitted form, so the store never re-derives server state | Exact convergence without trusting client-side re-application or capped outcome lists |
| RD-21 | **Groups and records are different things.** `groupId` ties the ≤ 5,000-change chunks of one plan together (atomic for undo and hints). `recordId` ties the ops of one revertible server change or one assistant run (`ServerChangeRecord`) together | One id with two meanings broke `groupLast` (review item 29) |
| RD-22 | **One sender per file per device.** Several tabs of one user may open the same file. Each tab sends only the outbox rows it created (tagged with its tab id). Rows of a closed tab are adopted by the background sync of another tab, which coordinates through the Web Locks API (desktop: a process-level lock). Store writes are monotonic in revision (06 §2.6) | Multi-tab use is allowed (suite 03) |

### 3. Review questions (decided 2026-10-18)

**Q1 · How does a late offline edit resolve against a newer online edit of the same cell field?**
**Decided: last to arrive wins.** Ops apply in arrival order (RD-2), for online and offline ops
alike.

- **Reporting.** The server reports the fields whose value at apply time differed from the change's `before` and were last written by another user (`conflicts`, 03 §4.5).
- **UX.** The offline author sees "Your offline changes replaced 3 newer edits by Bo — Review", with *Restore theirs* per cell (06 §6). This matches Google Sheets and Write.
- **Considered and not chosen:** keeping the newer value for offline ops (today's semantics).
- **Specs to rewrite:** Sheets 10 §9–§10 and Slides 09 §6.3 (spec file 11).

**Q2 · Enforce protected ranges on the server?**
**Decided: yes, in this migration** (RD-19, design in 05 §3.5). Protections stop being advisory.
Suite 06 §3 and Sheets 07 §10.3 drop their "advisory" notes (spec file 11).

**Q3 · Keep the generated domain-table classes on the client?**
**Decided: no** (RD-4: `serverOnly: true`). The clients use `RevSchema` column maps and the cores'
own records, so the client protocol shrinks by about 35k generated lines. If some client code
still needs a typed row class, it gets a hand-written record in the core.

### 4. Limits

| Limit | Value | Enforced by | Error code |
|-------|-------|-------------|------------|
| Changes per op | 5,000 | client chunker, server chunker (server changes), server | `tooLarge` |
| Uncompressed op payload (incl. `before`) | 16 MiB (a 2 MiB script file update is 4 MiB plus overhead) | server, before decode | `tooLarge` |
| Stream message | 4 MiB after compression. Chunkers cut ops by count **and** by encoded size (target ≤ 1 MiB compressed), so a message normally stays far below the cap. There is no separate large-submit RPC: unary request bodies are capped at 512 KiB (`maxRequestSize`), stream messages are not (inventory write-infra §5) | both | `tooLarge` |
| Batches of ops (`RevInit.ops`, `ops()` responses) | ≤ 1,000 ops **and** ≤ 1 MiB compressed in total. When either limit is hit, the batch stops early and the client gap-fills (04 §2.2) | server | — |
| Bootstrap page | ≤ `pageRows` rows **and** ≤ 4 MiB compressed | server | — |
| Single column value | 50,000 chars (`Cell.content`, `SlideElement.text`); 1 MiB for JSON columns; 2 MiB for `ScriptFile.source` | server (`RevColumn.maxLength`) | `invalidChange` |
| Cells per spreadsheet | `sheets.maxCellsPerSpreadsheet` (1,000,000; grid size counts) | server stats, client | `limitExceeded` |
| Sheets per spreadsheet | `sheets.maxSheetsPerSpreadsheet` (200; exists today in `ServerLimits`, now enforced by the binding) | server, client | `limitExceeded` |
| Elements per deck | **No server limit** (unchanged). 50,000 elements stays a client-side cap on what is kept offline without OPFS | — | — |
| Op-log retention | 30 days for payload, summary and detail; slim rows (idempotency) 365 days (`opTombstoneDays`) | job | — |
| Outbox age (client) | 180 days. Older outbox rows are not resent; the client offers them as *Save my changes as a copy* (06 §8) | client | — |
| Editors per file | 100; later joiners become viewers (Write's rule) | server | — |
| Offline availability (client) | Opened in the last 14 days (max 50 files per app) or pinned. Files with an outbox are never evicted | client | — |
| Offline cell cap without OPFS (client) | 200,000 cells (Sheets), 50,000 elements (Slides): only limits what is kept offline | client | — |

### 5. Configuration

New section `wonky.revlog` in `config/*.yaml` (read by `WonkyConfig`, env override
`WONKY_REVLOG_<KEY>`; suite 01 §6):

```yaml
wonky:
  revlog:
    maxChangesPerOp: 5000
    maxOpBytes: 16777216         # uncompressed payload incl. before
    maxMessageBytes: 4194304     # one stream message, compressed (hard cap)
    targetOpBytes: 1048576       # chunkers aim below this, compressed
    compressAboveBytes: 16384
    opsInInit: 1000              # and ≤ 1 MiB compressed in total
    opRetentionDays: 30          # payload/summary/detail
    opTombstoneDays: 365         # slim rows for idempotency
    maxEditorsPerFile: 100
    pageRows: 1000               # sheet rows per cell page
    structurePageRows: 20000     # rows per structure/rows page (and ≤ 4 MiB)
    hookDebounceMs: 1000
    hookRetryMaxSeconds: 600
    hookLeaseSeconds: 60
    headlessBudgetMb: 2048       # HeadlessFileCache, both apps together
    headlessMaxEntries: 100
    schemaWindowDays: 14         # how long the server accepts an older compatible schema hash
  sheets:
    maxCellsPerSpreadsheet: 1000000      # kept
    # maxActiveSpacesPerUser: removed
  slides:
    # maxActiveSpacesPerUser: removed (no new keys)
  cluster:
    busFlushMs: 1000                     # kept; RevLog posts use immediate: true
```

`ProtocolInfo` (suite 01 §7) replaces `syncTablesHash` with `revSchemaHash` (the hash of `RevSchema`
for both apps, 02 §4.3) and raises `minClientVersion` to `3.0.0`.


## Part 2 · Data model


All models are Serverpod `.spy.yaml`. Field lists of today's domain tables are in
`packages/wonky_sync_models/lib/src/models/**`; only the changes are listed here.

### 1. New server tables (`wonky_server/lib/src/platform/revlog/models/`)

```yaml
class: RevFile
table: rev_file
serverOnly: true
fields:
  fileUuid: UuidValue              # = drive item uuid = root row id
  kind: RevFileKind                # spreadsheet | deck
  item: DriveItem?, relation(onDelete=Restrict)   # itemId; purge deletes rev_file first (05 §10)
  headRevision: int, default=0
  prunedBelow: int, default=0      # ops < prunedBelow have no payload (05 §10); RevInit uses it
  initPending: bool, default=false # createFile wrote the row but not all initial ops yet (05 §8.3)
  purging: bool, default=false     # purge in progress: refuse connects/submits (05 §10)
  schemaHash: String               # RevSchema hash of the last write
  stats: String, default='{}'      # JSON, binding-defined (§1.1)
  contentCount: int, default=0     # Sheets: grid cells (Σ rows × cols); Slides: elements (informational)
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  rev_file_uuid_idx: { fields: fileUuid, unique: true }
  rev_file_item_idx: { fields: itemId, unique: true }

class: RevOp
table: rev_op
serverOnly: true
fields:
  file: RevFile?, relation(onDelete=Cascade)     # fileId
  revision: int
  clientOpId: UuidValue
  baseRevision: int
  authorId: int?                   # user_profile id (null for system)
  authorUuid: UuidValue?           # auth user uuid (sent to clients)
  sessionId: String?               # client connection session id, or "server:<runId>"
  onBehalfOfSessionId: String?
  actorKind: ActorKind
  label: String
  groupId: String?                 # chunk group of one plan (RD-21)
  groupIndex: int, default=0
  groupLast: bool, default=true
  recordId: UuidValue?             # ServerChangeRecord / assistant run (RD-21)
  offline: bool, default=false
  payload: ByteData?               # gzip codec JSON of the APPLIED changes incl. before (RD-20); null once pruned
  changeCount: int
  summaryJson: String?             # null once pruned
  detailJson: String?              # ≤ 200 cells; null once pruned
  outcomeJson: String?             # full outcome (04 §2.2) for idempotent re-acks; null once pruned
  appliedEqualsSubmitted: bool     # true: the applied form is exactly the submitted changes
  clientCreatedAt: DateTime?
  committedAt: DateTime
indexes:
  rev_op_rev_idx: { fields: fileId, revision, unique: true }
  rev_op_client_idx: { fields: fileId, clientOpId, unique: true }
  rev_op_record_idx: { fields: recordId }
  rev_op_committed_idx: { fields: committedAt, type: brin }   # prune jobs

class: RevHookState
table: rev_hook_state
serverOnly: true
fields:
  file: RevFile?, relation(onDelete=Cascade)
  cursorsJson: String              # {"<hookId>": <last processed revision>, …}
  leaseOwner: String?              # instance id draining this file
  leaseUntil: DateTime?
  attempts: int, default=0
  lastError: String?
  nextAttemptAt: DateTime?
  updatedAt: DateTime
indexes:
  rev_hook_state_file_idx: { fields: fileId, unique: true }
  rev_hook_state_due_idx: { fields: nextAttemptAt }

enum: RevFileKind
serialized: byName
values: [spreadsheet, deck]
```

#### 1.1 `rev_file.stats` (also sent as `RevInit.stats` and `RevFileInfo.stats`)

| Binding | JSON |
|---------|------|
| Sheets | `{"tables":{"sheet":3,"sheet_row":3000,"sheet_column":78,"cell":312,…},"sheets":{"<sheetId>":{"rows":1000,"cols":26,"cells":312}}}`. `contentCount` = Σ rows × cols over grid sheets, the quantity capped by `sheets.maxCellsPerSpreadsheet` (Sheets 02 §3.2: "the grid size counts") |
| Slides | `{"tables":{"slide":12,"slide_element":340,…}}`; `contentCount` = elements |

`tables` gives per-table row counts. The client uses them to plan structure loading (06 §5.2); the sequencer uses `tables.protected_range` to skip the protection check on files without protections (05 §3.5).
The sequencer keeps the stats in the same transaction from the applied op's insert and delete
counts (05 §3.2); `revlog.repairStats` recomputes them (05 §10).

### 2. Domain tables

#### 2.1 Location and declaration

| | Sheets | Slides |
|--|--------|--------|
| Move from | `packages/wonky_sync_models/lib/src/models/*.spy.yaml` | `…/models/slides/*.spy.yaml` |
| Move to | `wonky_server/lib/src/sheets/models/rows/` | `wonky_server/lib/src/slides/models/rows/` |
| Tables moved | **22** (the 24 files minus `change_log` and `script_user_property`) | **12** (the 13 files minus `deck_change_log`) |
| Enums | 10 Sheets enums | 7 Slides enums |

Per model:

| Change | Detail |
|--------|--------|
| `database: sync` | **removed** → a server table; add `serverOnly: true` (Q3) |
| `spaceId` (implicit) | gone |
| new `file: RevFile?, relation(onDelete=Cascade)` | `fileId` on **every** domain table. Set by the sequencer, never by clients; not part of `RevSchema` |
| new `revision: int` | The revision that last wrote the row. Set by the sequencer; not part of `RevSchema`. Used for debugging and as the starting point of conflict attribution (03 §4.5, 05 §3.2) |
| domain FKs | unchanged `relation(onDelete=Cascade, deferred)`, **except `cell.row` and `cell.column`**: they become plain `rowId: UuidValue` and `columnId: UuidValue` fields with no DB FK. The sequencer cascades cells explicitly by `(sheetId, rowId)` / `(sheetId, columnId)` using the existing indexes (05 §3.3). A DB FK on them would need `(rowId)` and `(columnId)` indexes on the largest table so that row/column deletes don't scan it. `cell.sheet` keeps its FK; its index `(sheetId, …)` serves it |
| `id`, `createdAt` | unchanged |

**Enums.** The server gets Serverpod enums (`.spy.yaml`, `serialized: byName`) in the same
folders. The cores and apps use hand-written pure-Dart enums with identical names and values in
`packages/wonky_sync_models/lib/enums.dart` (RD-5). On the wire and in column maps, enums are
names, so no conversion code is needed beyond `byName`. A guard test compares the value lists.
`ActorKind` moves to `platform/revlog/models/` (the platform uses it) and also has a pure-Dart
twin.

#### 2.2 Indexes

- Keep every existing index (inventory models §1–§2).
- Add `<table>_file_idx (fileId, id)` to **every domain table except `cell`**, for structure pages, purge and headless loads.
- **`cell` is never read or deleted by `fileId`.** Whole-file cell access goes sheet by sheet (`WHERE "sheetId" = ANY(@sheets)` or one sheet at a time), using `cell_row_idx (sheetId, rowId)`. This rule applies to headless loads, version capture, search text, content size, stats repair and purge (05 §§6, 9, 10). A `cell (fileId)` index would cost about 40 MB per million cells and is not needed.

#### 2.3 Removed tables

| Removed | Replaced by |
|---------|-------------|
| `change_log` (Sheets, synced) | `rev_op` |
| `deck_change_log` (Slides, synced) | `rev_op` |
| `script_user_property` (synced, personal space) | server table `script_user_property` (§2.4) |
| `space_subscription`, `space_reservation` (server) | nothing (RD-9, RD-13) |
| `sheets_change_log_receipt`, `deck_change_log_receipt` (server) | `rev_hook_state` |
| `reserved_space`, `sheets_dirty_space`, `sheets_journal_space`, `sheets_row_journal` (client) | the client cache tables (§3) |
| `crdt_*`, `offline_sync_*` (engine, server and client) | nothing |
| `SheetsMergedSignal` (bus message) | `RevBusMessage` (05 §5) |

**Client database migrations.** `wonky_client/lib/migrations/` is one generated linear chain
(Sheets client migrations followed by `slides-s1`). Never edit it by hand.

- **R5:** once the Sheets synced models and client tables are gone, regenerate the client migrations. The generator produces a migration that drops them.
- **R8:** once the Slides ones are gone too and no `database: client`/`sync` model is left, the server's `config/generator.yaml` loses `experimental_features.databaseSync`, the `serverpod_offline_sync` module and the `shared_packages` entry. The client database is then removed through the generator.

#### 2.4 `script_user_property` (server)

```yaml
class: ScriptUserProperty
table: script_user_property
serverOnly: true
fields:
  user: UserProfile?, relation(onDelete=Cascade)
  fileUuid: UuidValue
  key: String
  value: String
  updatedAt: DateTime
indexes:
  script_user_property_idx: { fields: userId, fileUuid, key, unique: true }
```

Endpoints `sheets.getUserProperties(fileUuid)` and
`sheets.setUserProperties(fileUuid, Map<String,String?> changes)` (null = delete); Viewer+, since
the properties are private per user. The client cache and offline queue are in 06 §7.1. Server
scripts read and write the table directly (`ServerUserProperties`, today
`script_service.dart:1209-1300`).

#### 2.5 Changed server tables

| Table | Change |
|-------|--------|
| `server_change_record` | `spreadsheetUuid` → `fileUuid`. **Remove** `inverseJson`, `inverseFileId`, `forwardFileId`. **Add** `recordId: UuidValue` (= `rev_op.recordId` of its ops). Revert/reapply compute the changes from the ops' applied payloads (05 §8.2). Keep `changeId`, `cellsAffected`, `expiresAt` (≤ 30 days, within payload retention), `revertedAt`, `revertChangeId` |
| `cell_history` | `changeLogId: UuidValue` → `revision: int`; `spreadsheetUuid` → `fileUuid`. Unique `(fileUuid, revision, rowId, colId)` |
| `sheets_snapshot_index`, `slides_snapshot_index` | Add `revision: int` (the file revision captured). `changedRangesJson` / `changesJson` are built from `rev_op.summaryJson` between two capture revisions |
| `sheets_ai_preview_record` | Rename to `ai_preview_record` (`AiPreviewRecord`); `spreadsheetUuid` → `fileUuid` (Slides uses it too). **Done (CQ-52)**, also `server_change_record.spreadsheetUuid` → `fileUuid`; shared code in `platform/ai/ai_preview_records.dart` and `platform/revlog/server_change_records.dart` |
| `item_version` (platform) | For spreadsheets and decks the captured revision goes into the existing `ItemVersion.revision: int?` (`platform/versions/item_version.spy.yaml:13`, used by Write today). `VersionRestoreResult.revision` reports the restore's last revision |
| `sheets_import_job`, `script_execution`, `script_trigger_state`, `script_job`, `script_authorization`, `ai_function_cache` | Unchanged; their `spreadsheetUuid` columns hold the file uuid |
| `drive_item` | `contentRef` = file uuid (unchanged) |

### 3. Client cache schema (SQLite, per user and app)

File `<app>_cache_<userUuid>.db` (`sheets_cache_…`, `slides_cache_…`), opened with
`LocalDatabases.open(…, migrations: revCacheMigrations(schema))` (06 §2). The old
`sheets_<userUuid>.db` / `slides_<userUuid>.db` replica files are removed on first start
(06 §2.1).

```sql
-- Bookkeeping (fixed DDL, in wonky_revlog_flutter)
CREATE TABLE rev_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
   -- 'schemaHash' = RevSchema hash the domain tables were created with (06 §2.4)

CREATE TABLE rev_local_file (
  file_uuid TEXT PRIMARY KEY,
  item_json TEXT,                  -- DriveItemView JSON (offline open, titles)
  role TEXT,
  revision INTEGER NOT NULL,       -- server state stored = state at this revision; only ever increases (06 §2.6)
  complete INTEGER NOT NULL DEFAULT 0,   -- 1 = every row loaded (available offline)
  pinned INTEGER NOT NULL DEFAULT 0,
  last_opened_at INTEGER,
  size_bytes INTEGER NOT NULL DEFAULT 0,
  created_locally INTEGER NOT NULL DEFAULT 0,  -- waiting for the queued drive create (06 §7.1)
  orphaned INTEGER NOT NULL DEFAULT 0          -- queued create failed permanently (06 §8)
);

CREATE TABLE rev_coverage (           -- bootstrap coverage while incomplete (06 §5.3–5.4)
  file_uuid TEXT NOT NULL,
  key TEXT NOT NULL,                  -- 'tbl:<table>:<fromId>:<toId>' (structure ranges) or 'row:<sheetId>:<rowId>' (cells)
  revision INTEGER NOT NULL,          -- page revision Rp
  PRIMARY KEY (file_uuid, key)
);                                    -- collapsed to 'sheet:<sheetId>' once a sheet's cells are all loaded

CREATE TABLE rev_local_op (           -- recent op metadata for offline history (06 §3.3)
  file_uuid TEXT NOT NULL,
  revision INTEGER NOT NULL,
  author_uuid TEXT, session_id TEXT, actor_kind TEXT NOT NULL,
  label TEXT NOT NULL, group_id TEXT, record_id TEXT,
  summary_json TEXT, detail_json TEXT, offline INTEGER NOT NULL DEFAULT 0,
  committed_at INTEGER NOT NULL,
  PRIMARY KEY (file_uuid, revision)
);

CREATE TABLE rev_outbox (
  file_uuid TEXT NOT NULL,
  seq INTEGER NOT NULL,              -- local order
  tab_id TEXT NOT NULL,              -- creating tab/process (RD-22)
  client_op_id TEXT NOT NULL,
  base_revision INTEGER NOT NULL,
  payload TEXT NOT NULL,             -- codec JSON incl. sum/det (uncompressed)
  schema_hash TEXT NOT NULL,         -- hash the payload was encoded with (06 §2.4)
  label TEXT NOT NULL, actor_kind TEXT NOT NULL,
  group_id TEXT, group_index INTEGER NOT NULL DEFAULT 0, group_last INTEGER NOT NULL DEFAULT 1,
  offline INTEGER NOT NULL DEFAULT 0,
  inflight INTEGER NOT NULL DEFAULT 0, -- may have been sent; resend with the same id
  created_at INTEGER NOT NULL,
  PRIMARY KEY (file_uuid, client_op_id)
);
CREATE INDEX rev_outbox_seq ON rev_outbox (file_uuid, seq);

CREATE TABLE rev_outcome (            -- acked outcomes awaiting the review UI (06 §6)
  file_uuid TEXT NOT NULL, revision INTEGER NOT NULL, outcome_json TEXT NOT NULL,
  PRIMARY KEY (file_uuid, revision)
);

-- Domain tables, generated from RevSchema (§4), one per table:
--   CREATE TABLE <table> (id TEXT PRIMARY KEY, file_uuid TEXT NOT NULL, <columns…>);
--   CREATE INDEX <table>_file ON <table> (file_uuid);
--   plus the table's client indexes from RevSchema (e.g. cell (sheetId, rowId)).
-- Column types: uuid/string/json/enumName → TEXT; int/bool/dateTime → INTEGER (dateTime = UTC ms);
-- double → REAL. No foreign keys: cascades arrive as explicit deletes in applied ops and pages.
```

The domain tables hold **server state only**. Unacknowledged local changes live only in
`rev_outbox` and in the in-memory model (the overlay; 03 §7).

### 4. `RevSchema`

Types in `packages/wonky_revlog/lib/src/schema/`; instances in the cores:
`wonky_sheets_core/lib/src/revlog/sheets_schema.dart` and
`wonky_slides_core/lib/src/revlog/slides_schema.dart` (RD-5).

```dart
enum RevColumnType { uuid, string, int, double, bool, dateTime, enumName, json }

final class RevColumn {
  const RevColumn(this.name, this.type, {
    this.nullable = false,
    this.defaultValue,             // applied on insert when the column is missing (03 §4.2)
    this.enumValues,               // for enumName
    this.maxLength,                // string/json (01 §4)
    this.clientWritable = true,    // false: columns only the server writes
    this.immutable = false,        // may not change by update (cell sheetId/rowId/columnId, deterministic-id keys)
  });
}

final class RevParent {
  const RevParent(this.column, this.table, {this.optional = false}); // cascade on delete (sequencer)
}

final class RevTable {
  const RevTable(this.name, this.columns, {
    this.parents = const [],
    this.plainRefs = const [],     // documentation + repair hints; never cascaded
    this.indexes = const [],       // client cache indexes
    this.rank = 0,                 // dependency order (parents first)
    this.deterministicIds = false, // cell, basic_filter, script_build, slide_table_cell, chart_link, theme copies…
    this.clientWritable = true,    // false: script_build
    this.isRoot = false,           // spreadsheet / deck
    this.coverage = RevCoverage.structure, // how bootstrap pages cover this table (06 §5.3)
  });
}

enum RevCoverage { structure, cellsByRow /* Sheets cell: key = sheetId + rowId */ }

final class RevSchema {
  const RevSchema(this.app, this.tables, {required this.coupled, required this.columnwise,
      this.compatibleWith = const {}});
  final String app;                          // 'sheets' | 'slides'
  final Set<String> compatibleWith;          // older hashes whose payloads this schema accepts (additive changes only)
  RevTable table(String name);               // throws on unknown
  RevTable? tryTable(String name);           // decoders: unknown tables/columns of a compatible newer schema are skipped
  int rank(String table);
  String get hash;                           // UUIDv5 over canonical JSON of tables/columns/types/enums
}
```

- **The cores' table constants become part of the schemas.** `SheetsTables`, `SlidesTables`, `SheetsUndo.columnwise` and `SlidesUndoHooks` move onto `sheetsSchema`/`slidesSchema` (`coupled`, `columnwise`). This replaces `SyncedTables`, `SlidesSyncedTables`, `SyncedTableSpec` and `SyncTableSet`.
- **Plan-less summaries move.** Plan-less change summaries are needed by the client (undo, redo, repairs) and the server (server changes). They move from the Sheets app (`SheetsWriter.summarize`, `wonky_sheets/lib/features/sync/sheets_writer.dart:68`) into `wonky_sheets_core` as `SheetsChangeSummary.ofChanges(changes, current)`. Slides keeps `SlidesChangeSummary.of(changes, wasDeleted: …, current: …)` (`change_summary.dart:89`) in its core.

#### 4.1 Guard tests

- **Server** (`wonky_server/test/unit/revlog/schema_guard_test.dart`): for every `RevTable`, the generated server table has the same columns, types and nullability, plus `fileId` and `revision`. Parents match the FKs, except `cell.rowId`/`columnId`, which have no FK (§2.1). Server and pure enums have equal value names. **Built** (code-quality plan, Wave 3): also checks that every server table versioned by RevLog (`fileId` → `rev_file` plus `revision`) is in a schema.
- **Cores:** every table name the planner uses exists in the schema; `coupled`/`columnwise` reference existing columns; `immutable` columns are never updated by any planner op (property test).

#### 4.2 Value conversion

Everything is driven by `RevColumn.type`:

- `RevValues.toWire/fromWire` (codec, 03 §3.2);
- `RevValues.toSql` (server parameters with explicit casts);
- `RevValues.toSqlite/fromSqlite` (client cache).

In memory the column-map conventions stay as today: lower-case UUID strings, enum names, UTC
`DateTime`, `double`. So `WorkbookModel` and `DeckModel` ingestion doesn't change.

#### 4.3 Hash, compatibility and versioning

| Rule | Detail |
|------|--------|
| Where the hash travels | Every payload (`"s"`), `RevInit.schemaHash` + `RevInit.acceptedHashes` (current + `compatibleWith` still inside `schemaWindowDays`), `ProtocolInfo.revSchemaHash` |
| Server accepts a payload | if its `"s"` is the current hash or in `compatibleWith` within the window. Otherwise `schemaMismatch` |
| Client, older than the server | If its hash is in `RevInit.acceptedHashes`: continue; the decoders **skip** unknown tables and columns of the newer schema (additive changes only). If not: stop sending and show "Update required" (suite 01 §7) |
| Client after an update | It **re-encodes and re-stamps** its outbox with the new schema on load (06 §2.4). Changes to tables or columns that no longer exist are dropped and reported once, so a stale hash never deadlocks the outbox |
| What counts as additive | A new nullable column or a new table. Each additive release adds the previous hash to `compatibleWith`. Anything else (rename, type change, removal) is a breaking release: bump `minClientVersion` |


## Part 3 · Changes, change sets, apply rules and the wire codec


### 1. `RowChange` (moved, semantics unchanged)

`RowChange`, `RowOp`, `MutationPlan`, `composeRowChanges`, `UndoInverter`, `RowsUndoEntry`,
`RowsUndoHandler`, `CoupledColumns`, `ColumnwiseInserts` and `CurrentRowReader` move from
`packages/wonky_sync_kit/lib/src/{rows,undo}` to `packages/wonky_revlog/lib/src/{rows,undo}`.
Their public API stays as it is today (inventory: models §7). `RowPatch` becomes `Overlay` (§7).
`SyncTxAdapter` and `SyncTableSet` are deleted: they are replaced by `RevBinding` (05 §1) and
`RevSchema` (02 §4).

| Op | `before` | `after` | Meaning in RevLog |
|----|----------|---------|-------------------|
| `insert` | — | every column the creator sets, plus `id` | Create the row. If the id exists, the server writes the **non-null** columns of `after` into it (RD-2; see §4.2) |
| `update` | the touched columns' values *as the author saw them* | the touched columns' new values | Assign the named columns. `before` is used for conflict detection (§4.5) and undo |
| `delete` | the full row as the author saw it, plus `id` | — | Delete the row. Children cascade (RD-3); the plan lists the children it knows |

Invariants checked by `RowChange` and the codec:

- `rowId` is a canonical lower-case UUID string.
- `update.after` is non-empty, and its keys equal the keys of `before`.
- `id` never appears in `update.after`.
- Columns exist in `RevSchema`; values have the column's type (§3.2).

### 2. `ChangeSet`

```dart
/// One op: the unit of submission, sequencing and acknowledgement.
final class ChangeSet {
  ChangeSet({
    required this.clientOpId,        // UUIDv7, generated once, reused on every resend
    required this.baseRevision,      // the client's server revision when the op was cut
    required this.changes,           // ≤ RevLimits.maxChangesPerOp, ordered (§4.1)
    required this.label,             // undo label ("Paste", "Insert 3 rows"); "" for maintenance
    required this.actorKind,         // ActorKind name: user | mcp | ai | script | system
    this.summary,                    // ChangeSummary JSON (Sheets: sheets, ranges, kinds, deleted…)
    this.detail,                     // ≤ 200 cells before/after (cell history), as MutationPlan.detailJson
    this.groupId,                    // shared by the ops of one plan / one server operation
    this.groupIndex = 0,             // 0-based position in the group
    this.groupLast = true,           // false on all but the last op of a group
    this.offline = false,            // true if any change was made while disconnected (reported in conflicts and the review UI, 06 §6)
    this.createdAt,                  // client wall-clock UTC of the first change (display only)
  });
}
```

- **Summary and detail.** These are computed exactly as today:
  - `MutationPlan.summaryJson`/`detailJson` for plans;
  - `SheetsWriter.summarize` (moved to the Sheets binding) for plan-less writes: undo, redo, AI, maintenance.
- **Groups.** A plan of more than `maxChangesPerOp` changes is split by `MutationPlan.chunks` into one group. The summary goes on the first op of the group; the detail on the first op if it has ≤ 200 cells, otherwise none. The server stores `groupId`, and history shows a group as one entry.
- **Composing ops.** While an op is in flight, later local changes are composed into the buffered op (06 §4.2). Composing appends changes, runs `composeRowChanges`, and merges summaries (union of sheets, ranges, kinds and deleted ids). Details are concatenated and capped at 200 cells. The label becomes that of the latest step, or "Edits" if they differ. `offline` is OR-ed.

### 3. Wire codec (`RevCodec`, `packages/wonky_revlog/lib/src/codec/`)

#### 3.1 Format

A change set is encoded as compact JSON. When the UTF-8 encoding is larger than
`compressAboveBytes` (16 KiB), it is sent gzip-compressed as bytes (04 §2).

```jsonc
{
  "v": 1,                                    // codec version
  "s": "<revSchemaHash>",                    // 02 §4.3; the server rejects a mismatch (schemaMismatch)
  "t": ["cell", "sheet_row"],                // table dictionary for this op
  "c": [["content", "bold"], ["sortKey"]],   // column dictionary per table (same order as "t")
  "ch": [
    // [op, tableIdx, rowId(base62, 22 chars), after?, before?]
    // op: 0 = insert, 1 = update, 2 = delete
    // after/before: arrays aligned with the table's column dictionary; a column that is not
    // part of the change is encoded as the sentinel {"_":0} ("absent")
    [1, 0, "4fG…", ["n:42", {"_":0}], ["s:old", {"_":0}]],
    [0, 1, "7Hb…", ["a0V"]],
    [2, 0, "9zA…", null, ["n:1", true]]
  ]
}
```

- Row ids travel in the 22-character base-62 form (`Base62Uuid`), the same form as formula reference tokens. They are decoded to canonical UUID strings before use.
- `insert` carries `after` only; `update` carries both arrays (the touched columns are those not equal to the "absent" sentinel); `delete` carries `before` only.
- The metadata of §2 (`clientOpId`, `baseRevision`, `label`, …) travels in the message, not in the codec JSON (04 §2).

#### 3.2 Value encoding

Values are encoded per `RevColumnType` (02 §4):

| Type | JSON | Notes |
|------|------|-------|
| `uuid` | base-62 string (22) | FK and plain-reference columns |
| `string` | string | |
| `int` | number (integer) | |
| `double` | number | Dart shortest round-trip; `NaN`/`±Inf` are rejected |
| `bool` | `true`/`false` | |
| `dateTime` | integer (UTC milliseconds since epoch) | |
| `enumName` | string (enum value name) | Unknown names are rejected by the server (`invalidChange`); a client decoding a compatible newer schema keeps the name as-is (02 §4.3) |
| `json` | string (opaque JSON text, as stored) | Validated as JSON by the server; size limit per column |
| null | `null` | Allowed only for nullable columns |

**Round-trip property:** `decode(encode(cs)) == cs` for every valid change set (property test,
09 §2.1). The client and server codecs are the same Dart code.

### 4. Apply rules (pure functions, `packages/wonky_revlog/lib/src/apply/`)

The rules are written once as pure Dart against an abstract row store. The sequencer runs this
very function on prefetched rows (05 §3.2), and clients use it for the overlay (§7) and in tests.
The SQL write step only persists its result, so the server's result equals the pure function's
by construction; 09 §2.2 checks that the persistence is faithful.

```dart
abstract interface class RevRowStore {
  Map<String, Object?>? row(String table, String id);           // null = missing
  void put(String table, String id, Map<String, Object?> row);  // full row
  void remove(String table, String id);                          // no cascade
  Iterable<(String table, String id)> childrenOf(String table, String id); // via RevSchema parents
}

final class ApplyResult {
  final List<RowChange> applied;          // the APPLIED form (§4.7), incl. cascades
  final List<DroppedChange> dropped;      // target or a parent missing
  final List<FieldConflict> candidates;   // fields whose value at apply time ≠ before (§4.5)
  final List<RowChange> cascaded;         // children removed by cascade that the op didn't list
  bool get equalsSubmitted;               // applied == submitted changes (no drops, merges or cascades)
}

ApplyResult applyChangeSet(RevSchema schema, RevRowStore store, ChangeSet cs);
```

#### 4.1 Order

Changes are applied in the order of the op. Planners already emit parents first for inserts and
updates and children first for deletes (`PlanBuilder.build`: stable sort by `RevSchema.rank`). The
client chunker and the composer keep that order. Rank can't order rows of one self-referencing
table (Slides `slide_element.parentId`: a group created in the same op as its children may come
after them), so `RevChunker.split` first runs `parentsFirst(schema, changes)`
(`wonky_revlog/lib/src/apply/order.dart`): an insert created in the op moves to just before the
first insert or update that references it, every other change keeps its place. The server does not
reorder; an out-of-order child insert is simply dropped (§4.2), and that is a client bug caught by
tests.

#### 4.2 Insert

1. **Parents.** Every non-null FK column of the row must reference an existing row (also
   one inserted earlier in the same op). Otherwise the change is **dropped**
   (`DroppedChange(reason: parentMissing)`).
2. **Absent row.** Store the row: `after` plus `RevSchema` defaults for missing columns.
3. **Existing row** (a deterministic id created by someone else, or a replay): write each
   column of `after` whose value is **non-null** (an insert that leaves a column null does not
   author it, OS-4 semantics). Columns whose current value is non-null and
   differs from `after` are conflict candidates (§4.5).

#### 4.3 Update

1. **Missing row** → dropped (`rowMissing`). This is "delete wins".
2. **Immutable columns** (`RevColumn.immutable`) can't be updated; validation rejects such an op (§5).
   - These are `cell.sheetId`, `cell.rowId` and `cell.columnId`: a cell's id is derived from them, so cells never move; moving content writes other cells.
   - The same applies to the key columns of other deterministic-id tables: `slide_table_cell` element, row and column; `chart_link.elementId`.
3. **Parent change.** If a mutable FK column is updated, the new parent must exist, otherwise the whole change is dropped (`parentMissing`). Examples are an element re-parented into another group, or a slide moved between groups (`groupId` is a plain reference, not an FK).
4. **Columns.** Write every column. A column whose current value differs from `before` is a conflict candidate (§4.5).

#### 4.4 Delete

1. **Missing row** → nothing (idempotent; not reported).
2. **Present row** → remove it and every descendant through `RevSchema` parents (cascade). The
   descendants that the op did not delete explicitly are returned as `cascaded` (they
   were created concurrently by someone else; 07 §5 shows them in the conflict review as
   "removed with row 7").

Plain references (`Slide.layoutId`, `DimensionGroup.startId`, pivot anchors, formula tokens,
GridRange JSON) are **not** cascaded. They resolve at evaluation time exactly as today
(Sheets 02 §2, Slides 02 §3), and the client repairs of §6 fix what must be fixed.

#### 4.5 Conflict candidates and attribution

A **candidate** is a field `(table, rowId, column)` where the op's `before` value differs from
the value at apply time. Value equality follows `RowPatch.sameColumns`: numbers by value,
date-times to the millisecond, enums by name, JSON strings byte-wise. The pure function reports
every candidate; it knows nothing about authors.

**Attribution** is a server post-step after the apply, still inside the transaction (05 §3.2
step 3.7). For each candidate, find the op that last wrote that field:

1. Start at the row's `revision` column.
2. Walk back through `rev_op` payloads (applied changes) until one wrote the column. The walk
   is bounded to 50 ops per field and 500 fields per op; beyond that the author is unknown.
3. A field is a **conflict** only if its last writer is **another user** (by `authorUuid`).
   The user's own other sessions and devices don't count, and neither do the user's own server
   changes on their behalf.

The Ack reports conflicts with `theirs` (the value before our write), `byUser` and `byRev`
(04 §2.2). The fields were overwritten: the last arrival wins (Q1, decided).

#### 4.6 Determinism

Given the same state and the same op, `applyChangeSet` produces the same applied form on the
server and on every client. Clients nevertheless never re-derive the server state with it: they
receive the applied form (§4.7, RD-20).

#### 4.7 The applied form (RD-20)

The applied form is the list of changes that turns the state at revision *r−1* into the state at
*r*, written so that it can be replayed literally, with no rules:

| Submitted | In the applied form |
|-----------|---------------------|
| Insert of an absent row | `insert` with the full stored row (defaults filled) |
| Insert merged into an existing row (§4.2.3) | `update` of the columns it actually wrote, with their `before`. So undo, revert and replay never treat it as a whole-row insert or delete, and other users' columns survive |
| Update | `update` of the columns actually written |
| Delete | `delete` with the full row as stored (`before`) |
| Dropped change | absent |
| Cascaded descendants | `delete`s (full rows) after their parent's delete |
| Fix-ups (none in this migration) | appended |

Clients receive the applied form **without `before` values** (04 §2.2), since they never need
them. `rev_op.payload` keeps the `before` values for revert and attribution.

### 5. Validation (server, before applying)

Run against the decoded op. Any failure rejects the whole op with `RevRejected(invalidChange)`,
and the message names the first offending change.

1. `changes.length ≤ maxChangesPerOp`; payload size ≤ `maxOpBytes`.
2. Every table is in the binding's `RevSchema`. Clients may not write tables with
   `RevTable.clientWritable == false` (Sheets `script_build`; Slides none).
3. Every column exists, is writable by clients (`RevColumn.clientWritable`), and has the right
   type and nullability (§3.2). Strings are within `maxLength`. JSON columns parse.
   `immutable` columns appear only in inserts.
3a. **Ids belong to this file.** Every id the op touches that exists on the server must belong
   to this file. The sequencer prefetches by id without a file filter and rejects foreign ids
   with `invalidChange` (05 §3.2). Ids are global UUIDs, so this check is what keeps one file's
   op from writing another file's rows.
4. `insert` of a root-table row is only allowed in the file's creation op (revision 1) and only
   with `id == fileUuid`. A root row can't be deleted through an op (deleting a file is a drive
   operation).
5. `actorKind` is `user` for client submits. `mcp`, `ai`, `script` and `system` are only
   accepted from server-side callers (`submitServerChange`, 05 §8), with one exception: client
   scripts run in the browser submit with `actorKind: script` (Sheets 09 client runtime).
6. Binding checks (`RevBinding.authorize`, 05 §1):
   - Sheets: the cell cap (`contentCount`) and `maxSheetsPerSpreadsheet`.
   - Roles for special tables: `script_trigger` and `script_file` need Editor; triggers keep `runAsUserId == author`, as the server checks today in `ScriptService`.
   - Slides: exactly one owner FK set on `slide_element`.
7. **Protected ranges** (Sheets; RD-19, 05 §3.5): the op must not write protected cells, rows,
   columns, rules, filters, objects or sheets that the author may not edit. Otherwise it is
   rejected whole with `protectedRange`. This runs inside the sequencer, after the in-memory
   apply (it checks the applied form against the model at the previous revision).

### 6. Normalization and repairs

**Server hook (empty in this migration).** `RevBinding.normalize(ctx, applied)` may return extra
changes (fix-ups). They are applied in the same transaction and appended to the op's applied
form (§4.7), so the Ack carries them to the author (06 §4.4). The protocol and the client support fix-ups from day one so that a later binding can
use them without a protocol change. No binding returns any in this migration (RD-14).

**Client repairs (as today, run by an editor's client after remote batches, debounced 1 s, only when no remote group is half-applied and the tab's outbox is empty (06 §1.2), not
undoable, label "Repair", `actorKind: user` (clients may not send `system`, §5 rule 5), summary flag `"repair": true`. A repair op rejected with `protectedRange` is not retried for that violation for 24 h; another user who may edit the protection repairs it when they open the file):**

| App | Repairs | Status today |
|-----|---------|--------------|
| Sheets | `AnchorMaintenance` (object anchors) | Wired in `ObjectsController` (`objects_controller.dart:341-378`) |
| Sheets | `WorkbookMaintenance.plan` (core `mutations/maintenance.dart:15`): duplicate sheet names → " (2)" on the larger id; duplicate named ranges → "_2"; frozen counts clamped; overlapping merges → keep the smaller id; unresolvable merges deleted; basic filters whose range no longer resolves deleted; pivot anchors on deleted rows/columns moved to the nearest survivor; group depths normalized | **Not wired anywhere today.** R5 wires it next to `AnchorMaintenance` (one repair op per debounce) |
| Slides | The 12 `DeckMaintenance` rules (Slides 02 §10; spec file 08 §4) | Wired in `SyncedDeckSession.runMaintenance`; moves to `LoggedDeckSession` unchanged |

Repairs are deterministic and idempotent. Two editors repairing at the same time produce the
same changes, so the second op's changes are no-ops or identical values.

### 7. Overlay (client, replaces `RowPatch`)

The client model is defined as **`model = applyAll(outbox ops, in order, rules of §4) over server
state`**. The outbox is applied with the same `applyChangeSet` rules, not
by blindly re-writing after-values. That means:

- an outbox insert of a deterministic id merges only its non-null columns over a remote insert of the same id, so another user's `bold` stays visible;
- an outbox change whose row or parent was deleted remotely is dropped from the view.

When a remote op (applied form) arrives:

```
touched = rows the remote op changes, plus the rows the outbox changes for those ids
before  = model rows for `touched`                                 // = old server ⊕ outbox
server' = server rows for `touched` with the remote applied form replayed literally
after   = applyAll(outbox ops restricted to `touched`, over server')   // pure, §4 rules
patch   = diff(before, after)   // RowChanges; RowPatch.sameColumns → no flicker, no echo
model.applyChanges(patch)       // emitted as one remote batch
```

`Overlay.build(model, serverRows, remoteApplied, outbox, {schema})` implements this. Outbox
changes for rows outside `touched` are unaffected, so restricting the replay is exact.

**Property test** (09 §2.6, replaces `remote_patch_property_test.dart`): for random server
states, outboxes and remote ops, `model.applyChanges(Overlay.build(...))` equals a full rebuild
`applyAll(outbox, newServerState)`.


## Part 4 · Protocol


The protocol is generic: one set of message models for both apps, under
`wonky_server/lib/src/platform/revlog/messages/` (sealed bases with their variants in the same
folder, as Write's `write/messages/`; inventory write-infra §4). Each app gets a thin endpoint
that names its binding.

### 1. Endpoints

```dart
/// wonky_server/lib/src/sheets/endpoints/sheets_doc_endpoint.dart (Slides: slides_doc_endpoint.dart)
class SheetsDocEndpoint extends Endpoint {
  @override bool get requireLogin => true;

  /// Opens an editing/viewing session on a spreadsheet (§2).
  Stream<RevServerMessage> connect(Session session, UuidValue fileUuid, int knownRevision,
      String tabId, Stream<RevClientMessage> input) async* {
    yield* RevLogConnection.open(session, SheetsRevBinding.instance, fileUuid, knownRevision,
        tabId, input);
  }

  /// Bootstrap page (§3). Viewer+.
  Future<RevPage> page(Session session, UuidValue fileUuid, RevPageRequest request);

  /// Ops in (from, to]: ≤ 1,000 ops and ≤ 1 MiB compressed (fewer if a limit is hit; the
  /// caller continues from the last returned revision). Access rule: 05 §11.
  Future<List<RevOpView>> ops(Session session, UuidValue fileUuid, int fromRevision, int toRevision);

  /// Head revision, role and stats without opening a stream (background sync, Settings). Viewer+.
  Future<RevFileInfo> info(Session session, UuidValue fileUuid);
}
```

Endpoint names on the client: `client.sheetsDoc.*` and `client.slidesDoc.*`. File creation stays
with the drive endpoints (§5).

`tabId` is a random id per app instance (browser tab or desktop process), stable for its
lifetime. It tags the connection so that the server can skip echoes to the sending connection
(§2.2) and so that roster entries are per tab.

### 2. Stream messages

#### 2.1 Client → server (`sealed class RevClientMessage`)

```yaml
class: RevSubmit
extends: RevClientMessage
fields:
  clientOpId: UuidValue          # idempotency key (same on every resend)
  baseRevision: int
  payload: String?               # codec JSON (03 §3) incl. "sum"/"det", when ≤ compressAboveBytes
  payloadGz: ByteData?           # gzip of the same JSON otherwise (exactly one of the two is set)
  label: String
  actorKind: ActorKind           # user | script (03 §5 rule 5)
  groupId: String?
  groupIndex: int
  groupLast: bool
  offline: bool
  createdAt: DateTime            # client clock, display only
```

| Message | Fields | Meaning |
|---------|--------|---------|
| `RevSubmit` | above | One op (03 §2). Sent only after it is durable in the outbox (06 §4.1) |
| `RevRequestOps` | `fromRevision`, `toRevision` | Gap fill. The server answers with `RevRemoteOp`s, the same byte cap applying as for `ops()` |
| `RevPing` | `t` | Keep-alive and latency, every 30 s (as Write) |

The payload JSON adds two keys to the codec object of 03 §3.1:

- `"sum"`: the summary JSON;
- `"det"`: the detail JSON, or absent.

#### 2.2 Server → client (`sealed class RevServerMessage`)

| Message | Fields | Meaning |
|---------|--------|---------|
| `RevInit` | `revision`, `role: AccessRole`, `sessionId`, `schemaHash`, `acceptedHashes: List<String>`, `stats` (02 §1.1), `prunedBelow`, `ops: List<RevOpView>?`, `more: bool`, `bootstrap: bool` | First message. **`ops`:** the ops in (`knownRevision`, `revision`] when `knownRevision ≥ prunedBelow` and there are at most `opsInInit` of them. The list is cut at 1 MiB compressed, and `more: true` tells the client to gap-fill the rest with `ops()`. **`bootstrap: true`:** the gap is too large or pruned, and the client must (re)load pages (06 §5) |
| `RevAck` | `clientOpId`, `revision`, `duplicate: bool`, `applied?` / `appliedGz?`, `outcome?` | The op was committed as `revision`. **`applied`** (the codec JSON of the applied form without `before`, 03 §4.7) is present iff the applied form differs from the submitted changes (`rev_op.appliedEqualsSubmitted == false`). The client stores the applied form (or its own submitted changes when absent) as server state (06 §4.4). **`outcome`** is JSON for the UI (below); absent when empty |
| `RevRemoteOp` | `revision`, `clientOpId`, `payload?` / `payloadGz?` (applied form, no `before`), `authorUuid`, `authorSessionId`, `actorKind`, `label`, `summaryJson`, `detailJson?`, `offline`, `groupId?`, `groupIndex`, `groupLast`, `recordId?`, `onBehalfOfSessionId?`, `committedAt` | An op committed by **another connection**. The sending connection never receives its own op as a `RevRemoteOp`: it gets `RevAck` (Write's rule, `document_connection.dart:309`). Other tabs of the same user receive it like any remote op |
| `RevRejected` | `clientOpId?`, `code: RevRejectCode`, `message`, `detailsJson?` (code-specific, e.g. the protections hit for `protectedRange`) | The op was not committed (§4). `clientOpId == null` means a session-level error, and the server closes the stream after sending it |
| `RevRoleChanged` | `role: AccessRole` | Effective role changed (sharing, expiry, editor limit) |
| `RevResync` | `reason: String` | The server can't continue this session incrementally (for example after an admin repair). The client re-bootstraps (06 §5) |
| `RevPong` | `t`, `headRevision` | `headRevision` lets the client detect a lost bus message and gap-fill (05 §5) |

**Outcome JSON** (in `RevAck.outcome` and `RevOpView.outcomeJson`; for the UI only, since the
state is carried by the applied form):

```jsonc
{
  "dropped":   [ {"t":"cell","id":"<b62>","op":1,"reason":"rowMissing|parentMissing"} ],
  "conflicts": [ {"t":"cell","id":"<b62>","col":"content",
                  "theirs":"n:5", "byUser":"<uuid>", "byRev":4211} ],     // overwritten (last arrival wins, Q1)
  "cascaded":  [ {"t":"cell","id":"<b62>"} ],
  "truncated": false
}
```

Each list is capped at 500 entries; `truncated: true` marks a capped list. Capping never affects
state.

#### 2.3 Views

```yaml
class: RevOpView        # in RevInit.ops and ops()
fields:
  revision: int
  clientOpId: UuidValue
  payload: String?            # applied form without before (null if pruned — never returned then)
  payloadGz: ByteData?
  authorUuid: UuidValue?
  authorSessionId: String?
  actorKind: ActorKind
  label: String
  summaryJson: String?
  detailJson: String?
  offline: bool
  groupId: String?
  groupIndex: int
  groupLast: bool
  recordId: UuidValue?
  onBehalfOfSessionId: String?
  outcomeJson: String?        # lets the author recover a lost ack's outcome
  committedAt: DateTime

class: RevFileInfo
fields:
  fileUuid: UuidValue
  revision: int
  role: AccessRole
  schemaHash: String
  stats: String               # 02 §1.1
```

### 3. Bootstrap pages

```yaml
class: RevPageRequest
fields:
  kind: RevPageKind          # structure | rows | cells
  cursor: String?            # structure/rows: JSON {"t": <tableIdx>, "after": "<id>"} from the previous page; null = start
  table: String?             # kind == rows: the table (keyset over id)
  sheetId: UuidValue?        # kind == cells (Sheets)
  rowIds: List<UuidValue>?   # kind == cells: ≤ pageRows sheet rows
  maxRows: int               # server caps at structurePageRows (structure/rows) or pageRows (cells)
  format: int?               # newest body version the client reads (§3.1); null = a client from before negotiation

class: RevPage
fields:
  revision: int              # exact revision of every row in this page (05 §7)
  body: ByteData             # binary columnar body, version 2 (§3.1); gzip NDJSON (version 1) for clients without `format`
  coverage: List<String>     # coverage keys (§3.2)
  excludedTables: List<String>   # structure: tables the client must load with kind == rows
  nextCursor: String?        # structure/rows: cursor of the next page; null = done
```

#### 3.1 Page body

The body is self-describing: a binary body starts with `RVP` and its version byte, a version-1
body with the gzip magic. **Negotiation:** the client sends the newest version it reads in
`RevPageRequest.format`; the server serves `min(format, its newest)` (`RevPageCodec.negotiate`),
and version 1 when `format` is absent (a client from before negotiation). The client decodes
both versions; a version it does not know fails with a clear `RevCodecException` ("unsupported
page version N"), and loading reports it. Caches need no migration: a page is applied the same
way whatever its version.

**Version 2** (current; `RevPageCodec`, `RevPageBuilder` in `wonky_revlog/lib/src/codec/`) —
binary, columnar, little-endian, unsigned varints (7 bits per byte) and zigzag varints for
signed values:

```
body    := "RVP" 0x02 · flags (u8, 0) · str schemaHash · varint tableCount · table*
table   := str name · varint n · varint columnCount · block ids · column*
column  := str name · u8 RevColumnType.index · block
block   := u8 enc · varint length · bytes        enc: bits 0–1 presence (0 all null, 1 all
                                                 present, 2 bitmap), bit 2 dictionary,
                                                 bit 7 zlib-compressed bytes
str     := varint byteLength · UTF-8
```

- **ids:** `n` × 16 raw bytes (never compressed).
- **Presence:** with a bitmap (`ceil(n/8)` bytes, LSB first) the values follow for the present
  rows only; an all-null column is an empty block.
- **Values per type:** `uuid` 16 bytes each, or a dictionary (`varint d`, `d` × 16 bytes, `u8`
  index width 1/2/4, indexes); `string`/`json`/`enumName` UTF-16 lengths as varints then one
  UTF-8 blob (decoded once and sliced), or a dictionary (`varint d`, `d` lengths, `u8` width,
  indexes, blob of the `d` strings) when values repeat; `int` zigzag varints; `double` float64;
  `bool` a bitmap; `dateTime` zigzag varints of the millisecond delta to the previous value.
- **Compression:** a block of ≥ 256 bytes is zlib-compressed (level 1) when that saves ≥ 20 %;
  raw UUID blocks are never compressed (random bytes).
- **Decoded rows** carry `id` and their non-null columns; a null column is left out (it reads as
  null, as in the client cache) unless the column has a non-null default, where the null is
  explicit. Unknown tables and columns (a newer compatible schema) are skipped; a known column
  of another type is an error.

A 13,000-cell page (500 sheet rows × 26) of the perf data is ~250 KB (version 1: ~360 KB);
encoding takes ~4 ms and decoding ~13 ms on the desktop VM (version 1: ~52 / ~64 ms).

**Version 1** (legacy): gzip NDJSON, a header line `{"s", "t": [tables], "c": [[columns]…]}`
then one line `[tableIdx, "<b62 id>", [values aligned with c[tableIdx]]]` per row, values in
the codec encoding (03 §3.2) with nulls written.

#### 3.2 Coverage

A page is **authoritative** for a set of rows at `revision`. Every row in that set is either in
the page (its state at `revision`) or does not exist at `revision`. Coverage keys are the same
strings the client stores in `rev_coverage` (02 §3).

| Key | Meaning |
|-----|---------|
| `tbl:<table>:<fromId>:<toId>` | Every row of `<table>` with id in (`fromId`, `toId`]. `fromId` = `-` for the start, `toId` = `+` for the end |
| `row:<sheetId>:<rowId>` | Every cell of that sheet row (Sheets) |

**Structure pages** walk the non-cell tables in rank order with a cursor `{t, after}`. A
structure page carries one `tbl:` key per table it touched. Tables with more than 50,000 rows for
the file (per `RevInit.stats.tables`) are listed in `excludedTables` on the first structure page;
the client loads them with `rows` pages instead (two in parallel, 06 §5.2).

### 4. Rejection codes (`enum RevRejectCode`)

| Code | When | Client reaction (06 §4.6, §8) |
|------|------|-------------------------------|
| `invalidChange` | Schema/type/limit violation, a foreign id, an immutable column (03 §5) | Drop the op **and the rest of its group**; roll the model back; drop or trim the plan's undo step; one toast; error log |
| `tooLarge` | Op or message over the limits | Same as `invalidChange` (a chunker bug) |
| `limitExceeded` | Cell cap, sheet count | Same, with the server's message ("This spreadsheet has reached the limit of 1,000,000 cells") |
| `protectedRange` | The op writes protected cells, structure, rules, objects or sheets the author may not edit (05 §3.5). `detailsJson` lists the protections hit | Same as `invalidChange` (drop the group, roll back, drop the undo step), with the blocked-cell message (`GuardResult.blockedMessage`). For `offline` ops, also offer *Save my changes as a copy* (06 §4.6). A repair op isn't retried for 24 h (03 §6) |
| `forbiddenForRole` | Role below Editor (ACL or editor limit), or a table needing a higher role | Keep the outbox, switch to read-only, offer *Save my changes as a copy* |
| `forbidden` | No access at all (session-level; the stream closes) | Unavailable state "You no longer have access…" (outbox kept for the copy offer) |
| `unknownBase` | `baseRevision` > head (the client is ahead of the server, e.g. a restored server database) | Re-bootstrap; offer the outbox as a copy |
| `schemaMismatch` | Payload `"s"` not accepted (02 §4.3) | Stop sending; "Update required" |
| `notFound` | The file doesn't exist (yet) | If a create for this file is queued: wait (06 §5.1). Else unavailable |
| `fileReadOnly` | The file is trashed or being purged | Read-only with the drive's trashed banner |
| `internal` | Unexpected server error | Retry with backoff, same `clientOpId` (idempotent) |

A rejection means **the op is not in the log**: none of its changes were applied.

### 5. File creation (drive endpoints)

```dart
Future<DriveItemView> createSpreadsheet(Session s, UuidValue? parentUuid, String name,
    UuidValue? templateUuid, {String? locale, String? timeZone,          // existing params, kept
     UuidValue? fileUuid, bool initialize = true});                      // new
Future<DriveItemView> createPresentation(Session s, UuidValue? parentUuid, String name,
    UuidValue? templateUuid, {UuidValue? fileUuid, bool initialize = true});
```

- **Idempotency.** With `fileUuid` the call is idempotent: a retry returns the existing item, and finishes initialization if `initPending` (05 §8.3).
- **`initialize: true`.** The server writes the content as revision 1…: the template's rows, or the default content (`SpreadsheetFactory` with locale, time zone and the user's default fonts from `SheetsCreateDefaults`; `DeckFactory` for decks).
- **`initialize: false`.** The file stays at revision 0 and **the client's first op creates the rows**. Used by every client-side creation that writes its own content:
  - offline creation (queued in `PendingDriveOp`);
  - online creation from the Sheets/Slides apps when the client already holds the content: built-in Slides templates and blank decks, version copies, import-as-new (06 §7).
- The Drive app's *New*, MCP, AI and welcome content use `initialize: true`.

| Removed | Replacement |
|---------|-------------|
| `drive.registerSpreadsheet`, `drive.registerPresentation` | `create*(fileUuid, initialize: false)` |
| `sheets.reserveSpaces`, `slides.reserveSpaces`, `subscribe`, `unsubscribe`, `ensureSubscribed`, `spaceStats`, `sheetsSync.sync`, `slidesSync.sync` | nothing (`info`, `connect`) |

`PendingDriveOp` gains the kinds `createSpreadsheet` and `createPresentation` (args `fileUuid`,
`parentUuid`, `name`, `initialize: false`). They replace `registerSpreadsheet` and
`registerPresentation` (06 §7).

**Title of a file created with `initialize: false`.** The creation op inserts the root row with
the title the client had. If the drive item was renamed in between (a queued rename replays
before the creation op arrives), the sequencer sets the root row's title to the drive item's
current name while applying the creation op. The applied form then differs from the submitted
one, so the author learns the title from `RevAck.applied`. This is the only server-side
adjustment in this migration (RD-14).

### 6. Sequences

#### 6.1 Edit while online

```
client A (tab 1)                         server                          client B
  |-- RevSubmit(c1, base=40) ------------>|  validate, lock, apply, rev_op 41, head=41, commit
  |                                       |-- bus rev:<file> (immediate) --------------> RevRemoteOp(41)
  |<---------- RevAck(c1, 41[, applied, outcome]) --|
  |                                       |-- hooks (debounced, after the ack)
```

#### 6.2 Concurrent edits

A's op is committed as 41; B's op (base 40) as 42. On one instance, B receives
`RevRemoteOp(41)` before `RevAck(42)`, because the server posts under the file lock in revision
order. Across instances, `RevAck(42)` can arrive first. In both cases B processes
revision-carrying messages strictly in order (06 §4.3): the ack waits for 41, which arrives by
bus or by gap fill. B applies 41 through the
overlay (its own op stays on top), then the ack of 42 moves 42 from the outbox into server
state. If 41 and 42 wrote the same field, the ack's outcome lists a conflict with `byRev: 41`
(when A is another user).

#### 6.3 Reconnect after offline

```
client: outbox = [c7 (inflight), c8, c9 (buffered, composed)]
  |-- connect(knownRevision=40) ----------->|
  |<----------- RevInit(revision=55, ops 41..55, more=false) --|   (or bootstrap:true)
  | apply 41..55 through the overlay; an op whose clientOpId is c7 is our own committed op → ack c7
  |-- RevSubmit(c7, …) (if still unacked) ------------>|   idempotent: returns the original revision
  |<-------------------------------------- RevAck ------|
  |-- RevSubmit(c8+c9 composed) ---------------------->|
```

- **No age limit for transform.** The server never refuses an old base, since ops need no transform. The only age limits are the idempotency horizon (slim op rows kept 365 days) and the client's 180-day outbox age (01 §4).
- **Own op in the catch-up.** An op in `RevInit.ops` or `ops()` whose `clientOpId` is in this tab's outbox is the tab's own committed op; its ack was lost. The client treats it as the ack and takes the outcome from `outcomeJson`.

#### 6.4 Cold open of a file not on the device

```
  |-- connect(0) ------------------------------->|
  |<-- RevInit(revision=R0, bootstrap:true, stats) --|   later ops arrive as RevRemoteOp
  |-- page(structure, cursor=null) --------------->|   in parallel: rows pages of excluded tables,
  |-- page(cells, sheet S, top-20..top+200) ------>|   then the viewport cells
  |<------ RevPage(rev=R1, coverage …) ------------|   apply page + buffered ops > R1 for covered rows
  |   … WorkbookReady after structure + first cells; the remaining pages stream in (06 §5) …
```


## Part 5 · Server


Module: `wonky_server/lib/src/platform/revlog/`. Bindings: `sheets/revlog/`, `slides/revlog/`.
The patterns are lifted from Write's OT server (`write/ot/`, inventory write-infra §1). The code
is new and generic over a binding, and the bugs listed in 01-tech-spike §6 are fixed by design.

| File | Contents |
|------|----------|
| `rev_binding.dart` | `RevBinding` interface (§1) |
| `rev_log_service.dart` | `submit`, `submitServerChange`, `createFile`, `revert`, `reapply` (§3, §8) |
| `rev_sql.dart` | Set-based reads and writes driven by `RevSchema` (§3.3) |
| `rev_file_state.dart` | Per-instance file state: lock, revision, op ring, catch-up (§2) |
| `rev_log_connection.dart` | Stream connection (§4) |
| `rev_bus.dart` | Bus channel, messages, roster (§5) |
| `rev_hooks.dart` | Durable post-commit hooks (§6) |
| `rev_pages.dart` | Bootstrap pages (§7) |
| `headless_file_cache.dart` | Generic headless model cache (§9) |
| `rev_jobs.dart` | Prune, hook sweep, init sweep, stats repair, purge (§10) |
| `models/`, `messages/` | 02 §1, 04 §2 |

### 1. `RevBinding`

```dart
abstract class RevBinding {
  RevFileKind get kind;                    // spreadsheet | deck
  RevSchema get schema;                    // sheetsSchema (wonky_sheets_core) | slidesSchema (wonky_slides_core)
  DriveItemKind get itemKind;
  String get rootTitleColumn;              // 'title' on spreadsheet / deck (04 §5 creation title)

  /// Limits and roles beyond the schema (03 §5 rule 6). Throws RevRejection.
  Future<void> authorize(RevTx tx, ChangeSet cs, ApplyResult applied, RevAuthor author, RevStats statsAfter, RevModelAccess models);
  // RevAuthor {authUuid, role (effective), actorKind}; RevModelAccess.atPrevious() returns the headless model at revision head (before this op), loaded on first use (§3.5)

  /// Fix-ups appended to the applied form (03 §6). Returns [] in this migration.
  Future<List<RowChange>> normalize(RevTx tx, ApplyResult applied) async => const [];

  /// rev_file.stats/contentCount from the applied form (02 §1.1).
  RevStats updateStats(RevStats before, List<RowChange> applied);

  /// Summary JSON for plan-less server changes, from the core
  /// (SheetsChangeSummary.ofChanges / SlidesChangeSummary.of; 02 §4).
  String summarize(List<RowChange> changes, CurrentRowReader current, {bool insertsAreRevivals = false});

  /// Durable post-commit hooks, in run order (§6).
  List<RevHook> get hooks;

  /// Headless model (§9).
  Object buildModel(UuidValue fileUuid, Iterable<(String table, Map<String, Object?> row)> rows);
  void applyToModel(Object model, List<RowChange> applied);
  int estimateBytes(Object model);

  /// Tables read sheet by sheet instead of by fileId (Sheets: {'cell'}; 02 §2.2).
  Set<String> get perSheetTables;
}
```

`SheetsRevBinding.instance` and `SlidesRevBinding.instance` are registered at startup
(`server.dart`). This replaces `registerScriptHooks()`' change-log plugin and the Slides plugin
registration in `SlidesServer.ensureRegistered`.

### 2. File state (per instance)

```dart
final class RevFileState {
  final UuidValue fileUuid; final int fileId; final RevBinding binding;
  int revision;                         // last revision known to this instance
  final RevOpRing recent;               // ≤ 1,000 RevOpViews and ≤ 32 MiB of payload; larger payloads are not kept (fetched from rev_op)
  Future<T> lock<T>(Future<T> Function() body);        // promise-chain mutex (Write's DocumentState.lock)
  Future<void> ensureAtLeast(Session s, int revision); // coalesced catch-up from rev_op
}

abstract final class RevFileStates {
  static Future<RevFileState> of(Session s, RevBinding b, UuidValue fileUuid);
  static RevFileLease retain(RevFileState st);    // connections, server changes, headless entries
  static void release(RevFileLease lease);        // state disposed 60 s after the last lease
  static void evict(UuidValue fileUuid);          // purge (§10), tests
  static void clear();                             // tests
}
```

### 3. Submit

#### 3.1 Signature

```dart
static Future<RevCommit> submit(Session session, {
  required RevBinding binding,
  required Actor actor,
  required RevFileState state,
  required ChangeSet cs,                // decoded + size-checked (§3.2 step 0)
  required Role connectionRole,         // the connection's effective role (ACL ∧ editor limit), or the server change's
  String? sessionId,                    // the connection's sessionId (used to skip the echo, §4)
  String? onBehalfOfSessionId,
  UuidValue? recordId,                  // server changes (§8)
  bool serverChange = false,
});

final class RevCommit {
  final int revision; final bool duplicate;
  final List<RowChange> applied;        // applied form (with before)
  final bool appliedEqualsSubmitted;
  final RevOutcome outcome;             // dropped, conflicts (attributed), cascaded
  final RevOpView view;                 // bus/ring view (applied form without before + metadata)
}
```

#### 3.2 Algorithm

0. **Before any lock.**
   - Check sizes before decoding: the message against `maxMessageBytes`, the uncompressed payload against `maxOpBytes`.
   - Check `"s"` against the accepted hashes (02 §4.3), else `schemaMismatch`.
   - Run the static validation of 03 §5 rules 1–5 (immutable columns included).
1. **Idempotency fast path.** `SELECT revision, payload, "appliedEqualsSubmitted", "outcomeJson" FROM rev_op WHERE "fileId"=@f AND "clientOpId"=@c`. If found, return `duplicate: true` with the stored applied form and outcome. A pruned payload means the op is older than 30 days; return `applied = null` and `outcome = null`, and the client then re-bootstraps the affected file (06 §4.5).
2. **Access.**
   - `role = min(AccessService.effectiveRole(session, actor, item), connectionRole)`. `effectiveRole` respects grant expiry, and `connectionRole` carries the editor limit.
   - Below Editor → `forbiddenForRole`.
   - Item trashed, or `rev_file.purging` → `fileReadOnly`.

   This runs on **every** submit.
3. **`state.lock(...)`**, then one transaction:
   1. **Lock the file.** `SELECT id, "headRevision", stats, "initPending" FROM rev_file WHERE id=@f FOR UPDATE`, which serializes the file across instances. `cs.baseRevision > head` → `unknownBase`.
   2. **Idempotency again**, inside the transaction. A hit returns the duplicate; this closes Write's race (CQ-5).
   3. **Catch up:** `state.ensureAtLeast(head)`.
   4. **Prefetch (§3.3).**
      - Load the current full rows of every id the op touches, **by id alone, without a file filter**. Any row whose `fileId ≠ @f` → `invalidChange` ("foreign id"; 03 §5 rule 3a).
      - Check the parents the inserts and parent-changing updates need, within the file.
   5. **Apply in memory:** `applyChangeSet(schema, prefetchedStore, cs)` (03 §4) → `ApplyResult` (applied form, dropped, candidates, cascaded-to-compute).
   6. **Cascade (§3.3).** For each deleted row, query the descendants the op did not list, recursively through `RevSchema` parents. Cells go through `(sheetId, rowId)` / `(sheetId, columnId)`. Append them to the applied form as full-row deletes and to `cascaded`.
   7. **Attribute** the conflict candidates (03 §4.5): read the needed `rev_op` payloads (≤ 50 ops per field, ≤ 500 fields), keep the fields last written by another user, and attach `byUser`/`byRev`/`theirs`.
   8. **Creation title.** If the op inserts the root row, set its title column to the drive item's current name (04 §5) and record the change in the applied form.
   9. **Authorize.** `statsAfter = binding.updateStats(...)`, then `binding.authorize(tx, cs, applied, author, statsAfter, models)`: limits, special-table roles and, for Sheets, **protected ranges (§3.5)**. A failure is `limitExceeded`, `forbiddenForRole` or `protectedRange`, and the transaction rolls back.
   10. **Normalize:** `binding.normalize(...)` (always empty now; 03 §6).
   11. **Write (§3.3).** Deletes children first, then upserts parents first. Every written row gets `"revision" = head + 1`.
   12. **Log.** Insert `rev_op` with `revision = head+1`, the applied payload (with `before`, gzip), `appliedEqualsSubmitted`, the summary, the detail and the outcome. `recordId` and the group fields are copied from `cs`/arguments.
   13. **Head.** `UPDATE rev_file SET "headRevision"=@r, stats=@s, "contentCount"=@c, "schemaHash"=@h, "updatedAt"=now() WHERE id=@f` (named columns only; CQ-4).
   14. Commit.
4. **Still inside `state.lock`, after the commit.**
   - Set `state.revision = r` and add the op to the ring.
   - `RevBus.postOp(view, originSessionId: sessionId)` with `immediate: true` (§5).
   - Posting before releasing the lock keeps bus messages in revision order per instance.
5. **After the lock.**
   - Return `RevCommit`; the connection sends `RevAck` with `applied` when `!appliedEqualsSubmitted`.
   - Then `RevHooks.kick(fileId)` (debounced, §6).

**Errors.** `RevRejection` becomes `RevRejected(code)`. Any other exception is logged with the op
id and becomes `RevRejected(internal)`. Nothing was committed (one transaction), so the client
retries with the same `clientOpId`.

**Budget** (measured in R0 and R6): commit p95 < 15 ms for ≤ 100 changes and < 300 ms for 5,000
changes. Per op the statements are:

- 1 head lock;
- 1–3 prefetches per touched table;
- 0–n cascade queries (only when deleting parents);
- 0–1 attribution reads (only with candidates);
- 1–2 writes per table;
- 2 for the op insert and head update.

#### 3.3 Set-based SQL (`rev_sql.dart`)

All statements are generated from `RevSchema` and run with `unsafeQuery`/`unsafeExecute` with
named, explicitly cast or typed parameters (`@ids::uuid[]`, binary arrays `@c:_text`; inventory
write-infra §6).

```sql
-- Prefetch: every table the op touches in one statement, each as one row of typed arrays
-- (UUIDs as text; a column without values as null); by id only, so foreign ids are detected
SELECT * FROM
  (SELECT array_agg(t."fileId"), array_agg(t."revision"), array_agg(t.id::text),
          CASE WHEN count(t.content) = 0 THEN NULL ELSE array_agg(t.content) END, …
     FROM (SELECT * FROM "cell" WHERE id = ANY(@ids0::uuid[]) FOR UPDATE) t) c0,
  (SELECT … FROM (SELECT * FROM "sheet_row" WHERE id = ANY(@ids1::uuid[]) FOR UPDATE) t) c1;

-- Cascaded cells of deleted rows / columns that the op didn't list (sheet-scoped, uses cell_row_idx / cell_col_idx)
SELECT id, <all columns> FROM "cell"
 WHERE "sheetId" = @s AND "rowId" = ANY(@deletedRows::uuid[]) AND NOT (id = ANY(@explicit::uuid[]));
-- other child tables: WHERE "<parentFk>" = ANY(@deletedParents::uuid[]) (FK columns; small tables)

-- Deletes (children first)
DELETE FROM "cell" WHERE "fileId" = @f AND id = ANY(@ids::uuid[]);

-- Rows that did not exist at the prefetch: plain inserts of the final images (parents first),
-- one binary array per column; a column null in every row is a typed NULL
INSERT INTO "cell" AS t (id, "fileId", "revision", "sheetId", …, content, "note", …)
SELECT u.id, @f, @rev, u.c0, …, u.c3, NULL::text, …
FROM unnest(CAST(@ids:_text AS uuid[]), CAST(@c0:_text AS uuid[]), …, @c3:_text, …) AS u(id, c0, …, c3, …);

-- Rows read (and locked) by the prefetch: updated in place, only the columns the op changed
UPDATE "cell" AS t SET "revision" = @rev, content = u.c3
FROM unnest(CAST(@ids:_text AS uuid[]), @c3:_text) AS u(id, c3)
WHERE t.id = u.id AND t."fileId" = @f;
-- the affected-row count must equal the number of rows; otherwise roll back with invalidChange
```

- **Full row images are safe.** The file lock serializes every writer of the file's rows, and nothing else writes them after the migration.
- **Runs.** A run is a sequence of consecutive changes to one table; inserts and updates go in runs of ≤ 5,000 rows, prefetches of ≤ 10,000 ids per table. Binary arrays (`unnest`) replaced `jsonb_to_recordset` and in-place `UPDATE`s replaced `INSERT … ON CONFLICT` for existing rows (an update that misses rows, removed by a database cascade earlier in the op, is written again as the upsert) (R6 follow-up: 5,000 updated cells 108 → 55–73 ms, their prefetch 65 → 35 ms).
- **HOT updates.** The cell table has `fillfactor = 85` (`RevStorage`, ensured at server start because models can't declare it), so rewritten cells mostly stay on their page and skip the three index inserts.
- **File creation (§8.3)** answers the prefetch from memory: every row of the new file was written by the creation's earlier ops (`_CreatedRows`), and its ops build no view (nobody is connected).
- **One encoding per op.** The applied form is encoded once for `rev_op.payload`; an op of inserts only reuses that text and gzip for its view.
- **Cell deletes rely on the explicit cascade.** `cell.rowId`/`columnId` have no DB FK (02 §2.1), so deleting a `sheet_row` never triggers a scan of `cell`.

#### 3.4 Throughput and fairness

- Per-file throughput is bounded by commit latency. A typing user produces at most one op per round trip (06 §4.2).
- Server changes release the file lock between chunks (§8.1), so a 100k-cell import never blocks typing collaborators for more than one chunk.

#### 3.5 Protected ranges (Sheets binding; RD-19)

Protected sheets and ranges (Sheets 07 §10) were enforced only by the client's write gate. The
sequencer now enforces them with the **same core code**:

- `ProtectionGuard` (`wonky_sheets_core/lib/src/data_tools/protection/protection_guard.dart`);
- `WriteIntents`, moved from `wonky_sheets/lib/features/protection/write_intents.dart` into `wonky_sheets_core/lib/src/data_tools/protection/write_intents.dart`, so the client gate, MCP and the sequencer share it.

**When it runs.** In `SheetsRevBinding.authorize` (§3.2 step 9), for every op except
`actorKind: system`, which covers server-internal writes such as the title mirror and script
builds. It runs only if:

- the file has protections (`stats.tables.protected_range > 0`), **or**
- the op inserts, updates or deletes `protected_range` rows.

Otherwise it costs nothing.

**What it checks.** It runs against `models.atPrevious()`, the headless model at the head before
this op (§9; `ensureAtLeast(head)` under the file lock), with the author `(authUuid,
isOwner = role == owner)`:

1. **Derive intents from the applied form**, so dropped changes don't count:
   `WriteIntents.fromApplied(applied, model, deletedIds)`.
   - Cells, row/column default formats, sheet properties, rules, filters, objects and pivots work as today's `WriteIntents.fromChanges`.
   - **Row/column structure is derived from changes,** where the client derives it from the operation:
     - an inserted `sheet_row`/`sheet_column` → the "insert between" check with its neighbours by sortKey in the model;
     - a deleted one → `Structural(delete)` at its index;
     - a `sortKey` update → `Structural(move)`;
     - height, width, hidden and outline groups → no intent (Sheets parity).
   - **Boundary repairs are exempt,** exactly the changes the client's operation-based derivation ignores:
     - an update of a rule table (merge, CF, DV, banding, protection, filter, pivot) that touches only its range columns;
     - an update of a cell's `content` from a stored formula to a stored formula whose text is identical once reference tokens are removed.

     Both qualify only if every reference endpoint that differs between `before` and `after` named a row or column **deleted by this same op**. `BoundaryRepair.isRepair(change, deletedIds)` (core) verifies this. A client therefore can't use the exemption to rewrite protected content, only to repoint references at rows it is legitimately deleting.
   - Cells in rows or columns inserted by this op have no index in the model and are skipped; the insert check covers them.
2. **Protection rows themselves.** Creating a protection (an insert into `protected_range`) is allowed to any editor (Sheets parity). Updating or deleting one needs `ProtectionGuard.canManage(before, author)`; otherwise the op is rejected.
3. **Check each intent:** `ProtectionGuard(model).check(intent, authUuid, isOwner)`. Any `blocked` result rejects the **whole op** with `RevRejected(protectedRange)`. `warnings` are ignored: warning-only ranges never block on the server, because the client asked for confirmation.
4. **Rejection details:** `{"message": GuardResult.blockedMessage, "protections": [{"id", "description", "sheet", "a1"}]}`, carried in `RevRejected.detailsJson` (04 §2.2).

**Keeping the model warm.**

- A connection to a file with protections takes a `HeadlessFileCache` lease at start and holds it while it is open, so the first op doesn't pay the model load inside the lock.
- Server changes already hold a lease while planning.
- If budget eviction drops a model anyway, the next check reloads it under the lock (correct, just slow); this is counted in a metric.
- **Gate P12** (09 §6): commit p95 < 30 ms on a warm protected 200k-cell file.

**Server changes** (§8): MCP, AI, scripts, imports into existing sheets, revert/reapply, version
restore.

- They are checked the same way, with the attributed actor. Script runs use the run-as user.
- `SheetsWrites.run` keeps its early guard, which gives friendly MCP errors and warning-only `warnings` in tool results before planning. The sequencer is authoritative: a `protectedRange` rejection maps to MCP error `protected_range`.
- **Version restore** pre-checks the whole diff with the guard before writing its first chunk, and refuses with "This version changes protected ranges you can't edit". So it never commits partially because of protection.

**Offline edits.** Edits made offline before a protection arrived, or by an editor removed from a
protection, are now rejected when they sync. The client shows the blocked message and offers
*Save my changes as a copy* for the rejected group (06 §4.6). This replaces the former advisory handling
(Sheets 10 §9 "Rejected protected-range edits").

### 4. Connection (`RevLogConnection`)

This is lifted from Write's `DocumentConnection` (inventory write-infra §1.2) with these rules:

| Aspect | Rule |
|--------|------|
| Open | `static Stream<RevServerMessage> open(Session, RevBinding, UuidValue fileUuid, int knownRevision, String tabId, Stream<RevClientMessage> input)`: a lazy `StreamController` that starts on listen and closes on cancel |
| Start | (1) Find `rev_file` by uuid (missing or `purging` → `notFound`) and its `DriveItem`; `AccessService.requireRole(viewer)`; `DriveUserStates.recordOpen`. (2) `lease = RevFileStates.retain(state)`; `ensureAtLeast(head)`; for Sheets files with protections and an Editor role, also take a `HeadlessFileCache` lease (§3.5). (3) Register the bus listener for `rev:<fileUuid>`, then post `hello` (roster). (4) Send `RevInit`. (5) Start the input subscription. **After every `await`, check `_closed` and undo whatever is already registered** (CQ-5) |
| `RevInit` | `ops` per 04 §2.2 (`knownRevision ≥ prunedBelow`, ≤ `opsInInit`, cut at 1 MiB with `more`). Otherwise `bootstrap: true`. `knownRevision > head` → `RevRejected(unknownBase)` and close. `acceptedHashes`, `stats`, `prunedBelow` included |
| Effective role | `role = min(ACL role, editor-limit role)`. It is passed into every `submit` as `connectionRole`, so a joiner over the limit can't write (review 7) |
| Messages | A serial queue per connection. **Each message is handled in its own `try/catch (Object)`**, so the queue never dies. A failed `RevSubmit` replies `RevRejected(code)` |
| `RevRequestOps` | Clamped by count and bytes (04 §1) and to what the role may read (§11). Answered with `RevRemoteOp`s |
| Bus `op` | Forward as `RevRemoteOp` to every connection **except the one whose `sessionId` committed it** (`originSessionId`; Write's rule). That connection receives `RevAck` from its own submit |
| Bus `role` | Re-check the role (`AccessService.effectiveRole`). No access → `RevRejected(forbidden)` and close; otherwise `RevRoleChanged`. Triggered from `acl_events.dart`, whose spreadsheet/presentation branch posts `RevBus.rolesChanged` instead of calling `SpaceService.mirrorMembership` |
| Expiry | The role is also re-checked every 5 min, which closes streams of grants that expired without an ACL event |
| Editor limit | `maxEditorsPerFile` (100) with Write's roster (`hello`/`here`/`beat`/`left`, settle 2 s), keyed by connection `sessionId` |
| Ping | `RevPing` → `RevPong(t, headRevision: state.revision)` |
| Close | Idempotent: cancel timers, remove the bus listener, cancel input, release the lease, post `left`, close output |

### 5. Bus (`rev_bus.dart`)

| Aspect | Rule |
|--------|------|
| Channel | `rev:<fileUuid>` |
| Message | `RevBusMessage` (`serverOnly: true`). Fields: `type` (op · role · hello · here · beat · left · purged), `revision?`, `opJson?` (the `RevOpView` JSON when its payload is ≤ 64 KiB, else null), `originSessionId?`, `userId?`, `joinedAt?`, `headRevision?` (on `beat`) |
| Large ops | An instance whose ring lacks an op fetches it once from `rev_op` (by revision) and adds it to its ring. Connections on the same instance share it |
| `ClusterBus.post(…, immediate: true)` (new) | Delivers locally at once, as today. For Redis, it **first flushes the outbox's queued messages**, so an immediate message never overtakes older queued ones, then publishes. Used for `op`, `role` and `purged`. Write's `DocumentBus.post` for `op` switches to it in the same PR (R2) |
| Lost messages | Redis publish is best effort (`cluster_bus.dart:156-162`). `beat` messages (every 30 s, only when distributed) and every `RevPong` carry `headRevision`. A client or instance that sees a head beyond its revision gap-fills from `rev_op` |
| Ordering | Not guaranteed across instances. Clients order by revision and fill gaps (06 §4.3), as in Write |

### 6. Post-commit hooks (`rev_hooks.dart`)

#### 6.1 Runner

```dart
abstract class RevHook {
  String get id;                       // stable; key in rev_hook_state.cursorsJson
  bool wants(RevOpView op);            // cheap filter (e.g. title hook only if the op touched the root title)
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops);   // revision order, ≤ 200
  Duration get minInterval => Duration.zero;  // throttle (10 s for search text)
}
```

**`RevHooks.kick(fileId)`** is debounced per file per instance (`hookDebounceMs`, 1 s). A drain
works as follows:

1. **Lease.** `UPDATE rev_hook_state SET "leaseOwner"=@me, "leaseUntil"=now()+@lease WHERE "fileId"=@f AND ("leaseUntil" IS NULL OR "leaseUntil" < now() OR "leaseOwner"=@me) RETURNING "cursorsJson"`. No row returned means another instance is draining, so stop. The lease is renewed while draining (`hookLeaseSeconds`, 60 s) and cleared at the end, which makes the exclusion real (review 6).
2. **Read the ops** with `revision > min(cursors)` (≤ 200) from the ring or `rev_op`, with metadata, summary, detail and the applied payload.
3. **Run each hook** in binding order on the ops past its own cursor that it `wants`. Hooks with no wanted ops just advance their cursor.
4. **Save the cursors:** one `UPDATE rev_hook_state SET "cursorsJson"=@c, attempts=0, "lastError"=NULL`. Hooks whose own DB writes must be atomic with their cursor do both in one transaction (`ctx.transaction`); the cursor JSON is updated in it.
5. **Failure.** Catch `Object`. Keep that hook's cursor, store `attempts`/`lastError`/`nextAttemptAt` (backoff 2 s × 2^n up to `hookRetryMaxSeconds`) and log at error level. The other hooks continue. This is at-least-once, never silently skipped.
6. **Throttling.** A hook with `minInterval` that ran less than the interval ago keeps its cursor, and a timer re-kicks it so it gets a trailing run.

The `rev_hook_state` row is created with the file, with all cursors at 0. A hook added later
starts at the current head (no backfill). The sweep job (§10) kicks files whose cursors lag or
whose `nextAttemptAt` is due.

#### 6.2 Hook catalogue

These replace `ChangeLogConsumer`, `DeckChangeLogProcessor` with its plugins, and scattered
writes.

| Hook id | Binding | Does | Today |
|---------|---------|------|-------|
| `activity` | both | `ActivityService.logEdit(item, actor, counters)` aggregated per actor per batch (Sheets: changes, cells; Slides: changes, slides, slidesDeleted, themes, slideIds) | consumer duty 2 / plugin `activity` |
| `versions` | both | `VersionService.recordEdit(item, profileId, revision: op.revision)` once per author per batch | duty 3 / plugin `drive` |
| `driveEdit` | both | `DriveService.recordEdit(userId, item)` once per author per batch | duty 4 / plugin `drive` |
| `title` | both | When the batch wrote the root row's title (seen in the applied form): set `DriveItem.name` and call `DriveEvents.notify`. Skips ops whose title came from the drive name itself (the creation-title rule and system rename ops) | duty 5 (ran on **every** row today) / plugin `drive` |
| `modified` | both | `DriveService.touchModified` (modifiedAt, modifiedById, search text). Search text uses targeted reads: Sheets reads sheet names plus ≤ 10,000 `s:`/`n:` cells, **sheet by sheet**; Slides reads titles, element text, cells and notes. `minInterval` 10 s | duty 6 / plugin `drive` |
| `cellHistory` | Sheets | One multi-row `INSERT … ON CONFLICT DO NOTHING` of the op's `detailJson` cells into `cell_history` (revision, author, actorKind, label, at, before, after), then one trim statement (100 per cell) | duty 7 (2 statements per cell) |
| `comments` | both | `CommentService.orphan/revive` from `summary.deleted/revived` (Sheets rows/cols/sheets; Slides slides/elements) | duty 8 / plugin `comments` |
| `scripts` | Sheets | Compile when `kinds ∋ scripts` (Editor+); `ScriptTriggerService.fireForChange` (onEdit/onChange), skipping `system`/`script` actors; offline = `op.offline` | duty 10 |
| `contentSize` | both | `ContentSizes.onSpaceChanged` (renamed `onFileChanged`). Estimators sum the plain tables by `fileId`, cells sheet by sheet | per-batch duty / plugin `storage` |

**Inline, not durable** (best effort after the ack): agent cursors (`AgentCursors.show` for
`mcp`/`ai` ops, 5 s TTL presence).

**Removed:** `processSpace`, `afterRegistration`, receipts, `pruneOld`, `SheetsMergedSignal`.

### 7. Bootstrap pages (`rev_pages.dart`)

#### 7.1 Structure and rows pages

- **Structure pages** walk the non-cell tables in rank order. Their cursor is `{t: tableIdx, after: id}` (04 §3), and each page is read in **one repeatable-read transaction** (one statement per table), so it is one snapshot. A page stops at `structurePageRows` (20,000) rows or 4 MiB compressed, whichever comes first.
- Tables with more than 50,000 rows for the file (per `stats.tables`) are skipped by structure pages and listed in `excludedTables`. They are served as `rows` pages (keyset by id, the same caps); the client may run several in parallel.

```sql
-- per table of the page (one repeatable-read transaction = one snapshot):
WITH s AS (SELECT * FROM "sheet_row" WHERE "fileId" = @f AND id > @a::uuid ORDER BY id LIMIT @n + 1),
     t AS (SELECT * FROM s ORDER BY id LIMIT @n)
SELECT (SELECT count(*) FROM s) > @n,                        -- more rows follow
       (SELECT id::text FROM t ORDER BY id DESC LIMIT 1),    -- the cursor
       array_agg(uuid_send(t.id)),                           -- ids as 16-byte values
       CASE WHEN count(t."sheetId") = 0 THEN NULL ELSE array_agg(uuid_send(t."sheetId")) END,
       CASE WHEN count(t."sortKey") = 0 THEN NULL ELSE array_agg(t."sortKey") END, …
FROM t;
```

Each table comes back as **one row of typed arrays** (UUIDs as `uuid_send` bytes, a column
without values as null), which go into the version-2 body (04 §3.1) through `RevPageBuilder`
without row maps or JSON; `fileId` and `revision` are excluded. A client without `format` gets
the same rows as version 1. Coverage: one `tbl:<table>:<from>:<to>` key per table touched by
the page.

#### 7.2 Cell pages (Sheets)

```sql
SELECT f."headRevision", array_agg(uuid_send(t.id)) FILTER (WHERE t.id IS NOT NULL),
       CASE WHEN count(t.content) = 0 THEN NULL ELSE array_agg(t.content) END, …
FROM rev_file f JOIN "sheet" s ON s."fileId" = f.id
LEFT JOIN "cell" t ON t."sheetId" = s.id AND t."rowId" = ANY(@rows::uuid[])
WHERE f.id = @f AND s.id = @s::uuid GROUP BY f."headRevision";   -- no row: not a sheet of @f
```

One statement checks the sheet, reads the head and the cells. At most `pageRows` (1,000) sheet
rows per request, and ≤ 4 MiB. Coverage: `row:<s>:<rowId>` for every requested row. A
13,000-cell page takes ~50 ms on the server (R6: ~190 ms with `row_to_json` and NDJSON).

#### 7.3 Consistency

- **One snapshot per page.** Each page is read in one repeatable-read transaction (a cell page in a single statement) and therefore one MVCC snapshot. An op writes its rows and `headRevision` in one transaction, so the snapshot holds exactly the ops ≤ `rev` for every row.
- **Convergence.** Together with the client rule (06 §5.3: apply buffered ops > `Rp` to rows covered by the page; keep ops for uncovered rows), the client converges to the head. Property test: 09 §2.5.

### 8. Server-originated changes

#### 8.1 `submitServerChange`

```dart
static Future<RevServerChangeResult> submitServerChange(Session session, {
  required RevBinding binding,
  required Actor actor,                 // user the change is attributed to
  required UuidValue fileUuid,
  required String actorKind,            // mcp | ai | script | system | user (restore)
  required String label,
  List<RowChange>? changes,             // precomputed, or:
  Future<List<RowChange>> Function(Object model, int revision)? plan,  // planned on the headless model
  String? summaryJson, String? detailJson,
  UuidValue? recordId,                  // join an existing record (assistant run); null + record:true → new record
  String? onBehalfOfSessionId, String? sessionId,
  bool record = false,                  // revertible (ServerChangeRecord)
  Duration lifetime = const Duration(hours: 24),
  bool insertsAreRevivals = false,
  void Function(int done, int total)? onProgress,
});
// → RevServerChangeResult {changeId?, recordId?, groupId, fromRevision, toRevision, outcome}
```

- **Role.** Editor+ for the actor, which replaces `SpaceService.ensureWriter`. `system` changes (the title mirror, script builds) skip the user check but still require the file to exist and not be trashed or purging.
- **Planning against a current model.** With `plan`:
  1. Take a headless lease (§9).
  2. Under `state.lock`, call `headless.ensureAtLeast(state.revision)`, so the model includes every committed op.
  3. Run the planner **once**, on the model at revision *r*.
  4. Submit the result with `baseRevision = r`.
  5. Concurrent client ops resolve by the normal rules (RD-2), as today with LWW.
- **Chunking.** More than 5,000 changes, or more than `targetOpBytes` encoded, are submitted as one group (`groupId`). The lock is taken and released per chunk, with progress per chunk.
- **Atomicity.** Each op is atomic; a group is not. If chunk *k* fails, the earlier chunks stay committed. The record (when `record`) covers what was committed, so the partial change can be reverted from the UI. This fixes CQ-36.
- **Signals.** Every server change goes through the bus and the hooks like any op. This fixes the writers that never signal today (inventory server §10.1).

#### 8.2 Revert and reapply (`ServerChangeRecord`)

- **Record:** `{changeId, fileUuid, recordId, label, actorKind, userId, cellsAffected, expiresAt, revertedAt?, revertChangeId?}`. The ops are those of `rev_op` with that `recordId`.
- **`revert(changeId)`:**
  1. Decode the ops' applied forms. With `before` values, merged inserts are updates (03 §4.7), so reverting never deletes another user's columns.
  2. Invert them in reverse revision order with `UndoInverter.invertChanges(changes, current: headless model)`, using the per-column skip rule. Skipped columns become `RevertResult.skipped`, which drives the partial toast as today.
  3. Submit the result with `record: true` (a new record).
  4. Set `revertedAt`.
- **`reapply`** is the same, using the forward changes.
- **Rule** (aligned for MCP and the endpoints; code-quality slt #11): Editor+, and not already reverted.

#### 8.3 File creation, templates, copies, imports

```dart
static Future<RevFile> createFile(Session session, {
  required RevBinding binding, required DriveItem item, required Actor actor,
  List<RowChange> initialChanges = const [],   // empty: initialize:false (client writes the content)
  String label = 'Create', String actorKind = 'system',
  void Function(int done, int total)? onProgress,
});
```

1. **Transaction A** (the drive item's creation transaction): insert `rev_file` (revision 0, `initPending = initialChanges.isNotEmpty`) and its `rev_hook_state` row. Commit.
2. **Submit** `initialChanges` with `submitServerChange` (group). The chunks' `clientOpId`s are deterministic, `UUIDv5(fileUuid, "init:<chunkIndex>")`, so a retry is idempotent.
3. **Transaction B:** `initPending = false`.

A crash between the steps leaves `initPending = true`. The `create*` retry (same `fileUuid`) and
the `revlog.initSweep` job (§10) resume step 2. Clients that open a file with `initPending`
connect normally; the initial ops arrive as remote ops.

| Today (inventory server §3b, §3c, §5e) | Becomes |
|----------------------------------------|---------|
| `DriveService.createSpreadsheet` → `offlineSync.spaces.createFor` + `SpreadsheetFactory.write` (direct ORM inserts, no change log) | `SpreadsheetFactory.changes(...)` → `createFile` |
| `createSpreadsheetFromSheets` (MCP) | same |
| `SpaceCopier.copy` (templates, *Make a copy*) | `SpaceCopier.changes(sourceRows, …)` (id remap unchanged) → `createFile` |
| `SheetsImportService.importNew` / import jobs | `createFile` with no rows, then chunked `submitServerChange(record: true)` |
| `SlidesDecks.create`, `DeckFactory.write`, `SlidesTemplateDecks.write`, `DeckCopies.copy` | `…changes()` → `createFile` |
| `create*(initialize: false)` (client-written content) | `createFile(initialChanges: [])`; the client's first op is revision 1 |
| Welcome content (`AccountService`) | `createFile` |
| `DriveService.rename` of a spreadsheet/deck | `submitServerChange(update root title, system)` **if the root row exists**; otherwise only the drive item is renamed, and the creation op picks up the name (04 §5) |

### 9. Headless model cache (`HeadlessFileCache<M>`)

This replaces `HeadlessWorkbookProvider` and `HeadlessDeckCache` (CQ-52).

| Aspect | Rule |
|--------|------|
| Load | One `REPEATABLE READ` transaction: read `headRevision`, then every table by `fileId` (keyset, 10,000 rows per query) and the `perSheetTables` sheet by sheet; `binding.buildModel` |
| Fresh | Subscribed to `rev:<fileUuid>`. Applied forms from the bus (or from `rev_op` when large) go through `binding.applyToModel` in revision order, with gaps filled from `rev_op`. `ensureAtLeast(revision)` blocks until applied. **No `age(xmin)` scans, no staleness re-check, no `markStale`/`writeThrough`** |
| Leases | `open()` returns a `HeadlessLease` (`model`, `revision`, `release()`). Eviction disposes a model only when its lease count is 0 (server-domains S2) |
| Budget | One budget for both apps: `revlog.headlessBudgetMb` (2,048) and `revlog.headlessMaxEntries` (100), using `binding.estimateBytes`, re-estimated every 1,000 applied ops |
| Planning lock | `RevFileState.lock` (§8.1). No separate lock with a timeout that breaks exclusion (server-domains S1) |
| Shadows (AI Suggest) | Copy-on-write overlays over the cached model, counted in the budget (CQ-35) |

Call sites (inventory server §4a/§4b) switch to `HeadlessFileCache.sheets/slides.open(session,
fileUuid)` and must `release()`. `withWriteLock` callers become `submitServerChange(plan: …)`.

### 10. Jobs and purge

| Job | Schedule | Does |
|-----|----------|------|
| `revlog.pruneOps` | daily | In batches of 10,000 under a 60 s budget, looping until done: (1) for ops older than `opRetentionDays` that no unexpired `ServerChangeRecord` references, set `payload`/`summaryJson`/`detailJson`/`outcomeJson` to null, and advance `rev_file.prunedBelow` to the first revision still holding a payload; (2) delete slim rows older than `opTombstoneDays` |
| `revlog.hookSweep` | every 5 min | Kicks files whose hook cursors lag the head or whose `nextAttemptAt` is due |
| `revlog.initSweep` | every 5 min | Resumes `createFile` for `initPending` files older than 5 min |
| `revlog.repairStats` | weekly | Recomputes `stats`/`contentCount` for files changed since the last run (sheet by sheet for cells) |
| removed | — | `sheets.pruneChangeLog`, `slides.pruneChangeLog`, `sheets.evictSpaces` |
| changed | — | `revlog.purgeServerChanges` (`ServerChangeRecords.purgeExpired`, records of both apps); `drive.purgeTrash` (§10.1); storage reconcile (estimators by `fileId`) |

#### 10.1 Purge sequence

`rev_file.item` is `onDelete=Restrict`, so a drive item can't be deleted while its `rev_file`
exists. `DriveTrash.purge` calls `RevLogService.purgeFile` for spreadsheet/presentation nodes
**before** deleting the items:

1. `UPDATE rev_file SET purging = true`. New connects and submits now get `notFound` / `fileReadOnly`.
2. Post `purged` on the bus. Every instance closes the file's connections with `notFound`, evicts `RevFileStates` and `HeadlessFileCache` entries, and stops hook drains for the file.
3. Wait for the hook lease to expire or be released.
4. Delete in batches: Sheets cells sheet by sheet (50,000 rows per statement), then the other domain tables by `fileId`.
5. Delete `rev_file`, which cascades `rev_op` and `rev_hook_state`.
6. Delete the drive item (the existing purge continues).

Account deletion uses the same path (together with the ownership fix CQ-1).

### 11. Access rules

| Action | Minimum role |
|--------|--------------|
| `connect`, `page`, `info` | Viewer |
| `ops(from, to)` / `RevRequestOps` | Viewer for ranges within the last 1,000 revisions at call time; Editor+ for older ranges (CQ-17) |
| `RevSubmit` | Editor, as the effective role including the editor limit (§4) |
| `submitServerChange` | Editor for the attributed actor; `system` exempt (§8.1) |
| `cellHistory`, version history | Editor (CQ-17) |
| Writing protected cells, structure, rules, objects or sheets | Owner, the protection's creator or its editors (`ProtectionGuard.canEdit`); warning-only protections: any editor (§3.5) |

Trashed or purging files are read-only. An item that is removed or unshared closes open streams
with `forbidden`.

### 12. Observability

- **Per op:** commit duration, change count, payload bytes, prefetch rows, cascade rows, attribution reads, protection check duration and cold model loads, lock wait. Logged at debug; ops slower than 200 ms at warning (`session.log`).
- **Per connection:** open duration, ops sent, gaps filled.
- **Settings › Developer** (suite 04 §4): ops per minute, p95 commit, hook lag (head minus the minimum cursor) per binding.


## Part 6 · Client


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

### 1. Session contracts

#### 1.1 Sheets

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

#### 1.2 Slides

`LoggedDeckSession extends DeckSessionBase` (uses `DeckWritePath`) gets the same additions. It
runs the 12 `DeckMaintenance` repairs as `SyncedDeckSession` does: 1 s after remote batches,
editors only, not undoable, `actorKind: user` with the summary flag `"repair": true` (03 §6; 08 §4). Additionally, repairs (Sheets and Slides)
run **only when no remote group is half-applied** (the last applied remote op had
`groupLast == true`) **and this tab's outbox is empty** (review 21).

### 2. Local store (`RevLocalStore`)

#### 2.1 Opening

```dart
static Future<RevLocalStore> open({required RevSchema schema, required String userUuid,
    required String app /* 'sheets' | 'slides' */, String? directory});
// file: '<app>_cache_<userUuid>.db', via LocalDatabases.open(…, migrations: revCacheMigrations(schema))
```

- **PRAGMAs** as today's replica (`sync_replica.dart:63-76`): 64 MB page cache, in-memory temp store, WAL autocheckpoint 20,000.
- **Old engine files.** On first start of the new build, remove `sheets_<userUuid>.db` / `slides_<userUuid>.db` without reading them. On desktop, `LocalDatabases.delete`. On the web, where `LocalDatabases.canDelete` is false (`local_database.dart:57`), open them and drop every table (one transaction), then record `rev_meta.oldReplicaCleared` so it runs once.

#### 2.2 Writes

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

#### 2.3 Reads

- `loadFile(fileUuid)` returns the `rev_local_file` row plus this tab's outbox and orphaned outbox rows (§2.6).
- `loadRows(fileUuid, {skip: {cell}})` reads keyset pages of 10,000, as today's `loadSpace`.
- `loadCells(fileUuid, sheetId, rowIds)` reads 500 row ids per query, as `SheetsReplica.loadCells`.
  As built: `loadScoped(fileUuid, sheetId, rowIds)`; `loadStructure(fileUuid)` and
  `loadScopedAt(…)` return the rows with the revision of the stored state they belong to (one
  read transaction), for the viewport-first reopen (As built 24).

- `coverage(fileUuid)`, `recentOps(fileUuid, since)`, `filesWithOutbox()` and `usage()`.

#### 2.4 Schema versions

`rev_meta.schemaHash` records the `RevSchema.hash` the domain tables were created with.

- **App hash changed after an update:**
  1. Keep `rev_local_file`, `rev_outbox` and `rev_local_op`.
  2. Drop and recreate the domain tables and `rev_coverage`.
  3. Set every file to `complete = 0` and `revision = 0`.
  4. **Re-encode every outbox row with the new schema** and set its `schema_hash`. Changes to tables or columns that no longer exist are dropped and reported once in a toast. This keeps a stale hash from blocking the outbox (review 11).
  5. The next open re-bootstraps and overlays the outbox.
- **Server ahead of the app:** the client continues if its hash is in `RevInit.acceptedHashes`; decoders skip unknown tables and columns. Otherwise it shows "Update required" (02 §4.3).

#### 2.5 Eviction (availability)

- **Kept complete:** files opened in the last 14 days (max 50 per app) or pinned (*Make available offline*).
- **Never evicted:** files with outbox rows.
- **Evicted:** everything else is deleted from the cache (domain rows by `file_uuid`, `rev_local_op`, `rev_coverage`, `rev_local_file`) by `RevLogClient.maintain()`, after sign-in and then daily. This replaces the weekly purge and the cell-cap eviction.
- **Without OPFS** (`offlineStorageLimited()`): files beyond 200,000 cells in total (Sheets) or 50,000 elements (Slides) are not kept offline, least recently opened first; pinned files win. A warning shows as today.

#### 2.6 Several tabs (RD-22)

- **Tab id.** Every app instance has a `tabId`. It sends its own outbox rows and only those.
- **Liveness.** Each tab holds a Web Lock `wonky.revlog.tab.<tabId>` for its lifetime; on desktop, a process lock file.
- **Adoption.** `RevLogClient.syncOutboxes` (§7.3) adopts outbox rows whose tab no longer holds its lock: it rewrites `tab_id` to itself, then sends them. Adoption runs inside a Web Lock `wonky.revlog.<app>.<fileUuid>.adopt`, so two tabs never adopt the same rows.
- **Monotonic store.** Two tabs with the same file open each run their own connection and model. Store writes are monotonic (§2.2), so the tab that is behind never moves the cache backwards. A tab that sees `rev_local_file.revision` beyond its own just skips the store write; its model still applies the op.

### 3. Model ⇄ store

#### 3.1 Server state vs model

- The **store** holds server state at `revision`.
- The **model** holds `applyAll(outbox, server state)` (03 §7).
- **Loading:** read the rows from the store (viewport-first, §5.1), then apply the outbox ops to the model with the pure rules. The batch has origin `load` for Slides and is a load batch for Sheets.

#### 3.2 Remote op (another connection's op)

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

#### 3.3 Op metadata retention

`rev_local_op` keeps 30 days or 20,000 ops per file, whichever is smaller, pruned on open and
daily. It holds metadata, summary and detail only.

### 4. Sync state machine (`RevSyncCore`, wrapped by `RevConnection`)

This is ported from Write's `DocumentSyncController` (inventory write-infra §7.1) without the OT
parts.

#### 4.1 Outbox and send path

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

#### 4.2 Buffer composition

A new change set is composed into the **last** buffered chunk if all of these hold:

- both belong to the same group, or both are plain edits (no `groupId`);
- the last chunk started less than 2 s ago;
- the composed result stays within the limits.

Otherwise it starts a new chunk. Composition follows 03 §2: `composeRowChanges`, merged summary,
capped detail, OR-ed `offline`. Undo entries hold their own `RowChange`s and never reference ops,
so composing never changes what undo does.

#### 4.3 Ordering

- Revision-carrying server messages (`RevRemoteOp`, `RevAck`) go into a `SplayTreeMap<int, …>` queue. They are processed strictly as `revision == serverRevision + 1`.
- **Gap:** send `RevRequestOps(serverRevision + 1, firstQueued − 1)`, re-requested after 3 s. A gap also opens when `RevPong.headRevision > serverRevision` and the queue is empty (lost bus message, 05 §5).
- **Duplicates** (`revision ≤ serverRevision`) are ignored.

#### 4.4 Ack

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

#### 4.5 Reconnect and catch-up

1. `connect(knownRevision: serverRevision, tabId)`.
2. Handle `RevInit`:
   - **`ops`:** process them in order through the queue, then gap-fill the rest when `more`. An op carrying this tab's `clientOpId` is handled as an ack (§3.2).
   - **`bootstrap: true`:** run §5 again from the current model (pages replace covered rows; the outbox overlay stays).
3. Resend the in-flight op (same `clientOpId`), then the buffer.
4. **Pruned duplicate.** If the server answers a resend with `duplicate: true` and `applied == null` (payload pruned), the op committed more than 30 days ago. Re-bootstrap the file.
5. **Outbox age.** The server never refuses an old base. Outbox rows older than 180 days are not resent; they are offered as a copy (§8).

#### 4.6 Rejections

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

### 5. Opening and bootstrap (`RevBootstrap`)

#### 5.1 Open flow

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

#### 5.2 Page scheduling

1. **Structure.** Request `structure` pages until `nextCursor == null`. In parallel, request `rows` pages for every table in `excludedTables`, two at a time (large `sheet_row`/`sheet_column`).
2. **Viewport.** While structure loads, request a `cells` page for the frozen rows plus `top−20 … top+200` of the active sheet. Apply it after the structure, because the model needs the row ids.
3. **Ready.** `WorkbookReady` once steps 1–2 are applied. Files with ≤ 2,000 rows load all their cells first, as today.
4. **Streaming.** The remaining cells come in blocks of 500 rows:
   - first the grid's `prioritize` requests (newest of the last 4, ±50 rows);
   - then the active sheet;
   - then the other sheets in tab order.
   At most `RevFileSync.maxPagesInFlight` (3) cell pages are in flight; they are fetched and
   decoded concurrently and applied in request order. A block is split over the free slots
   (≥ 100 rows per page), so even a plan that hands out one block at a time gets parallel
   pages; rows the plan hands out again while their page is in flight are not requested twice
   (the loop waits for that page instead). A plan that skips rows already handed out (not yet
   loaded) keeps every slot busy.
5. **Decoding** (`RevPageDecoder`, `wonky_revlog_flutter/lib/src/transport/`) runs off the UI
   thread: on desktop and mobile in a short-lived isolate per page (`Isolate.run`; the rows come
   back without a copy), on the web in slices of ~8 ms that yield to the event loop. Bodies under
   32 KiB are decoded inline.
6. **Progress.** `rowLoading.progress` = loaded rows / total rows, with the total taken from `RevInit.stats.sheets`.

#### 5.3 Coverage and buffered ops (exactness)

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

#### 5.4 Partial caches

- **Reopen.** Pages are always written to the store, so reopening a partly loaded file is instant for the loaded part. `rev_coverage` records what is present and at which revision.
- **Reconnect.** `RevInit.ops` update the covered rows normally; with `bootstrap: true`, missing and stale parts are requested again.

#### 5.5 Loading gates

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

### 6. Conflicts and outcomes

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

### 7. App data layer and call-site migration

#### 7.1 Sheets (`SheetsRevLog`, replaces `SheetsData`)

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

#### 7.2 Slides (`SlidesRevLog`, replaces `SlidesData`)

- **`createPresentation`:**
  - **Built-in templates and blank decks** are created by the client with `initialize: false` (online: direct call; offline: queued), with the template's rows (`template.build(...).inserts`) as the creation op group.
  - **Non-built-in templates** are created on the server (`initialize: true` + `templateUuid`).
  - `NoReservedSpaceException` and its toast disappear.
- **`DeckOpenHistory`** feeds availability (§2.5).
- **Agent flash** (`mcp/agent_writes.dart`) and the **overwritten-text review** (`local_conflicts.dart`) use `session.history` / `session.outcomes`.
- **AI "wait for the slide to arrive"** (`ai_commands.dart:500-516`) waits in `session.history` for an op with the `recordId` returned by the AI endpoint (`RevServerChangeResult.recordId`, added to the responses). That replaces polling the model 40 × 250 ms.

#### 7.3 Background sync of closed files

`RevLogClient.syncOutboxes()` runs on reconnect and on drive changes:

1. For every file with outbox rows that no open session of this tab owns, including adopted rows (§2.6), open a headless `RevSyncCore` connection (no model), keyed `'<app>.offline:<fileUuid>'`, as Write's `WriteOffline.syncOutboxes`.
2. **`RevInit.ops`:** apply them to the store (`applyServerOp`).
3. **`RevInit(bootstrap: true)`:** send the outbox only. Apply acks to the outbox (delete rows) **without domain writes**, set `complete = 0`, clear the file's coverage, and set `revision = 0`. The next open re-bootstraps (review 34).
4. Stop after the outbox is empty and 5 s of idle, or after 2 minutes.

Files with `created_locally = 1` wait until the queued create has replayed
(`CachedDriveRepository.isPendingCreate`). If the create **fails permanently** (replay dropped it
as non-retryable: quota, permission), the file is marked `orphaned` (§8).

### 8. Errors and unsynced data

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

### 9. Sync status

`SyncStatus` (`wonky_ui`) states keep their meaning, with "saved" now meaning acknowledged:

| State | Condition |
|-------|-----------|
| `saving` (+ `pendingChanges`, `progress` for groups) | this tab's outbox for the file is not empty, and connected |
| `saved` | outbox empty: **every change is acknowledged by the server**. Today "saved" means "in local SQLite" |
| `offline` ("Offline — changes saved on this device") | not connected; outbox durable |
| `connecting` / `reconnecting` (+ `reconnectAt`) | stream opening or backing off |
| `error` (+ retry) | a rejection waits for the user, or a store write failed |

### 10. Commit hints

- **Removed:** the `cell` and `range` hints (RD-18), the hint overlay's wait for synced rows (`_dropSynced`) and `CellRenderCache.hinted`.
- **Kept:** `typing` (Sheets), and the text, transform and structure hints (Slides), unchanged. `pending` (the shimmer for groups over 500 cells) stays and is now dropped when the group's last op arrives (`groupLast`).

The Slides text-hint removal rule (the synced text equals the hint) keeps working, because remote
batches still arrive as remote batches.


## Part 7 · Performance gates


Measured in R6 on a Windows desktop (debug JIT, embedded Postgres, in-process `FakeRevHub` for
the clients); details, setup and the fixes in
[`plans/sheets-sync-migration/baseline.md`](../plans/sheets-sync-migration/baseline.md), the
misses in `TODO.md` ("RevLog sync — open items"). The client gates (P6–P9) were measured again
in R7 after the client work of As built 24 (same machine, three runs). The server and wire gates (P3, P4, P6, P7,
P10, P11) were measured again in R7 after As built 25.

| # | Metric | Budget | Measured by | Measured (R6) |
|---|--------|--------|-------------|---------------|
| P1 | Local op → visible in another client's model, one instance | p95 < 250 ms | e2e + `revlog_perf_test` (two connections, 500 single-cell ops) | server 4.9 ms, client apply 5.6 ms (1M cells) — pass |
| P2 | Same, two instances (`Cluster.debugDistributed` with Redis) | p95 < 400 ms | multi-instance perf test | not measured (no Redis) |
| P3 | Server commit, ≤ 100 changes | p95 < 15 ms | `revlog_perf_test` | 1 change 6.5 ms, 100 changes 13.5 ms → R7 6.7 / 11.4 ms — pass |
| P4 | Server commit, 5,000 changes | p95 < 300 ms | same | 288–306 ms → R7 250 ms (282 ms in a run while other suites ran) — pass |
| P5 | Idle server cost per connected client | no DB queries while idle except the 5-minute role check | query counter in the perf test | 0 — pass |
| P6 | Cold open (not on the device) of a 1M-cell sheet → `WorkbookReady` | < 1.5 s desktop, < 3 s web (OPFS) | client perf test against a local server; web via release build | server part 1.1 s → R7 0.45–0.54 s; client 1.44–2.0 s → R7 0.89–1.12 s — pass; decks 0.70 → 0.38 s; web not measured |
| P7 | Complete download of a 1M-cell sheet | < 15 s desktop, < 30 s web | same | server part 31 s → R7 7.1–7.3 s (pages 2.6 s, decode 0.8–0.9 s, model 3.4 s); client 98 s → R7 12.6–14.5 s (2.6–2.9 s of it the in-process page serving) — pass |
| P8 | Reopen from cache (1M cells) → ready | ≤ today (0.55 s for 200k; scale linearly) | client perf test | 28.6–47 s → R7 0.28–0.43 s (viewport-first; every cell in 8.5–10.8 s in the background) — pass; decks 0.29 → 0.22 s |
| P9 | 1M-cell local import (`applyChanges` into the outbox) | < 30 s | client perf test | 30–32 s → R7 17.3–18.6 s (planner + model 26 → 13.3–14.2 s, outbox 3.9–4.4 s) — pass |
| P10 | Server import of 1M cells (server change, 200 ops) | < 60 s | `revlog_perf_test` | 57.8 s → R7 41–42 s — pass; as a new file in one transaction 63–69 s → R7 37.6–38.0 s — pass |
| P11 | Storage per non-empty cell (Postgres, incl. indexes) | ≤ 250 bytes average for typical content | `pg_total_relation_size` / cells | 210 B → R7 238 B (`fillfactor = 85`) — pass |
| P12 | Server commit on a warm 200k-cell file with 20 protections, ≤ 100 changes | p95 < 30 ms; no cold model load inside the lock while a connection is open | `revlog_perf_test` | 5.6 / 14.2 ms, 0 cold loads — pass |

The suites: `wonky_server/test/integration/sheets/revlog/revlog_perf_test.dart`,
`wonky_sheets/test/revlog/revlog_perf_test.dart` and `wonky_slides/test/revlog/revlog_perf_test.dart`
(tag `slow`). The gates were to be measured in R0 (baseline of the old engine; not recorded) and
R6 (above). A regression > 20 % in the nightly job fails it (code-quality CQ-38).
