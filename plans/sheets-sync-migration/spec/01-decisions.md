# RevLog spec 01 · Decisions, terms, limits and configuration

This is the authoritative list of choices for the RevLog implementation. Later files refer to them
as **RD-n**. The review questions Q1–Q3 were decided on 2026-10-18 (§3).

## 1. Terms

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

## 2. Decisions

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

## 3. Review questions (decided 2026-10-18)

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

## 4. Limits

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

## 5. Configuration

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
