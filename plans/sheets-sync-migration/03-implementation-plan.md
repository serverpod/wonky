# 03 · Implementation plan: Sheets (then Slides) onto RevLog

> **For execution, use [spec/10-work-breakdown.md](spec/10-work-breakdown.md)** (PRs R0–R8 with
> files, branch strategy and gates). This file keeps the phase overview, risks and gate rationale.

Work-package ids are `RL-n`. Estimates are engineer-weeks (w) for one engineer who knows the
codebase. Phases 1–2 can partly overlap with Phase 4. **There is no data migration**: no users
exist, so existing Sheets/Slides data in dev databases is dropped (`create_repair_migration` or a
fresh database) and client replicas are deleted on first start of the new build.

Every phase follows `AGENTS.md`:

- models through `.spy.yaml` and `create_migration` / `apply_migrations` via MCP;
- `dart analyze` and `dart format`;
- tests per `specs/15-writing-tests.md`;
- specs updated in the same change.

## Phase 0 — Baseline and prototype (≈ 1.5 w) — decision gate

| Id | Task | Output |
|----|------|--------|
| RL-0.1 | **Measure today's engine** with `slow`-tagged benchmarks (no product changes): cold sync 100k / 1M cells (desktop and web/OPFS release build), one-cell edit → visible on a second client (p50/p95, 1 and 2 server instances), idle server CPU and queries per second with 10 connected devices × 30 spaces, `EXPLAIN ANALYZE` of `collectPendingChanges`, bytes per cell (`pg_total_relation_size`, SQLite `dbstat`) | `plans/sheets-sync-migration/baseline.md` with numbers |
| RL-0.2 | **Throw-away prototype** on a branch: `rev_file` + `rev_op` + materialized `cell` table, a `submit` with set-based apply and drop-if-parent-gone, a stream that pushes ops, and a headless Dart client. Benchmark the same scenarios | Prototype numbers next to the baseline |
| RL-0.3 | Confirm framework questions: can `wonky_sync_models` declare plain tables, or must they move to the server? Stream frame-size limits for 1–5 MB change sets, gzip on the stream vs HTTP RPC for pages. `jsonb_to_recordset` vs `unnest` arrays for bulk upserts | Notes in the baseline doc |
| RL-0.4 | **Decide.** Proceed if the prototype meets: propagation p95 < 250 ms on one instance; 5,000-change commit p95 < 300 ms; idle CPU ≈ 0; first page of a 1M-cell sheet < 1 s; full 1M-cell bootstrap < 15 s desktop. Otherwise fall back to option D (server "poke" for the CRDT loop, 1–2 w) and stop | Decision recorded in suite 01 §1 and 12 |

## Phase 1 — `wonky_revlog` core (≈ 2 w)

| Id | Task | Files |
|----|------|-------|
| RL-1.1 | Create `packages/wonky_revlog` (pure Dart, workspace member, analysis options like the other cores). Move in from `wonky_sync_kit`: `RowChange`, `MutationPlan`, `compose_row_changes`, `RowPatch`→`Overlay`, `UndoInverter`, `rows_undo`, `SyncTableSet`→`RevTableSet` (add parent links and cascade rules). Re-export shims in `wonky_sync_kit` until Phase 7 so the cores keep compiling | `packages/wonky_sync_kit/lib/src/{rows,undo,tables}/*` → `packages/wonky_revlog/lib/src/…` |
| RL-1.2 | `ChangeSet` model and codec: column dictionary per table, compact arrays, base-62 ids, gzip above 16 KB, deterministic encoding (stable hash for tests). Chunking to ≤ 5,000 changes with `groupId/groupIndex/groupLast` | new |
| RL-1.3 | Apply rules as pure functions over an abstract row source: LWW per column, drop-if-parent-gone, cascade on delete, `overwritten` detection from `columnsBefore` | new |
| RL-1.4 | Client state machine (pure Dart, no I/O): Synchronized / AwaitingAck / AwaitingAckWithBuffer, revision-ordered queue, gap detection, resend rules, outbox compose per row+column, 2 s chunk windows | new (ported from `document_sync_controller.dart` without OT) |
| RL-1.5 | **Convergence fuzzer** with an in-memory server: random plans from the real `SheetsMutationPlanner` (cells, formats, row/col insert/delete/move, sheets, merges, rules), random delays, reorders, disconnects and duplicate sends → all clients equal the server. Overlay property test. Chunked-group test | `packages/wonky_revlog/test/`, plus a Sheets-specific fuzzer in `wonky_sheets_core/test/revlog/` |

Exit: fuzzers green for 10k iterations; `dart analyze` clean; dependency-rule check updated (`tool/`).

## Phase 2 — Server sequencer and Sheets tables (≈ 3 w)

| Id | Task | Files |
|----|------|-------|
| RL-2.1 | **Models.** Turn the 24 Sheets models into plain tables with `fileId` (and indexes per design §3.1). Drop `ChangeLog` (synced). New `rev_file`, `rev_op`, `rev_hook_cursor` (`wonky_server/lib/src/platform/revlog/models/`). `create_migration` (destructive; no data to keep) | `packages/wonky_sync_models/lib/src/models/*.spy.yaml`, server models |
| RL-2.2 | `RevLogService.submit` per design §3.3: idempotency (checked again inside the transaction), role, change-set validation, advisory lock, set-based apply with `RETURNING` for dropped/overwritten, binding normalize hook, op insert, head update with named columns only, immediate bus post, ack | `platform/revlog/rev_log_service.dart`, `rev_log_store.dart` |
| RL-2.3 | Stream endpoint and connection: `SheetsDocEndpoint.connect`, `RevInit` (tail ≤ 1,000 or `bootstrap`), `RevRequestOps`, ping. Per-message `try/catch (Object)` (never let the queue die: code-quality CQ-5). `_closed` checks after every await on start (code-quality CQ-5). Role changes → `RevRoleChanged`. Max editors per file (100) as in Write | `platform/revlog/rev_log_connection.dart`, `sheets/endpoints/sheets_doc_endpoint.dart` |
| RL-2.4 | `ClusterBus`: immediate-flush channels for `rev:*` (and switch Write's `doc:*` to them too, since it has the same 1 s delay) | `platform/cluster/cluster_bus.dart` |
| RL-2.5 | Bootstrap pages per design §3.6: structure page, cell pages by row ids or sortKey range in one SQL statement with `headRevision`, gzip NDJSON, viewport-first ordering hints | `platform/revlog/rev_log_pages.dart` |
| RL-2.6 | Post-commit hooks queue (outside the lock, after the ack): per-file serial queue, durable cursors per hook, retries with backoff, `on Object` catch. Port the `ChangeLogConsumer` work: activity, drive `modifiedAt`/search text (throttled), title mirroring (only when the op touches `Spreadsheet.title`), cell history (one multi-row insert + one trim per op), version state, comment orphaning, script triggers, linked-chart invalidation | `platform/revlog/rev_log_hooks.dart`, `sheets/revlog/sheets_hooks.dart`; delete `sheets/changelog/change_log_consumer.dart` |
| RL-2.7 | `SheetsRevLogBinding`: table set, server validation (cell cap from `rev_file.stats`, protected ranges, value sizes), normalization (sheet-name duplicates, frozen clamp, overlapping merges; today's client maintenance of Sheets 02 §8) | `sheets/revlog/` |
| RL-2.8 | File lifecycle: `drive.createSpreadsheet` creates `rev_file` + initial rows at revision 1 (idempotent on the client UUID). Copies and templates bulk-insert into the materialized tables. Trash/purge deletes by `fileId`. Storage accounting (`ContentSizes`) counts rows/bytes by `fileId` | `platform/drive/drive_service.dart`, `sheets/spaces/*` → `sheets/files/*`, `platform/storage/content_sizes.dart` |
| RL-2.9 | Op-log retention: prune ops older than 30 days in batches with a time budget (BRIN on `createdAt`); keep ops referenced by named versions or cell history needs | `platform/revlog/rev_log_store.dart`, maintenance job |

Tests:

- `test/integration/platform/revlog/` for submit, idempotency races, drop/overwrite, multi-instance relay, hooks crash/resume and pages-at-revision equivalence;
- `test/integration/sheets/revlog/` with a role matrix.

Exit: the Phase 1 fuzzer runs against the real server (in-process clients over HTTP, as `sheets_sync_test.dart` does today).

## Phase 3 — Server readers and writers (≈ 3 w)

| Id | Task | Files |
|----|------|-------|
| RL-3.1 | `submitServerChange` (with `onBehalfOfSessionId`, `groupId`, label, actor). Chunked for large plans, holding the lock per chunk. The op group is recorded so revert/reapply works for the whole group | `platform/revlog/` |
| RL-3.2 | Re-point the writers: `SheetsBulkWriter`, `ServerSheetsWriter`, `sheets_writes.dart` (MCP), AI apply/preview (`SheetsShadow`; use a copy-on-write overlay instead of two full copies, code-quality CQ-35), `ScriptService` commits, `SheetsImportService` (also fix the lease renewal and claim bugs while touching it), restore and revert/reapply | `sheets/mcp/*`, `sheets/ai/*`, `sheets/scripts/*`, `sheets/imports/*`, `sheets/versions/*` |
| RL-3.3 | `HeadlessWorkbookProvider`: load by `fileId` keyset pages, track the revision, subscribe to `rev:<fileId>` and apply ops in memory. Delete the `age(xmin)` patch. Refcount entries so eviction never disposes an engine in use (code-quality findings, server-domains S2) | `sheets/headless/*` |
| RL-3.4 | Versions: capture at a revision (the snapshot codec is unchanged). Read the materialized tables at that revision inside one repeatable-read transaction. History lists from `rev_op` (labels, authors). Cell history from `rev_op.detailJson` and the `cell_history` table | `sheets/versions/*`, `sheets/sheets_service.dart` |
| RL-3.5 | Linked charts (Slides): cache by `(fileId, revision)` instead of `COUNT(change_log)` | `slides/charts/slides_chart_service.dart` |
| RL-3.6 | Exports and MCP reads: switch from synced tables to the materialized ones (mostly via the headless provider) | `sheets/exports/*`, `sheets/mcp/*read*` |

Exit: all `test/integration/sheets/**` tests ported and green. MCP tool tests and AI tests are unchanged in behavior.

## Phase 4 — Client (≈ 4 w)

| Id | Task | Files |
|----|------|-------|
| RL-4.1 | `wonky_revlog_flutter`: `RevLogStore` (schema of design §4.1, migrations helper from `LocalDatabases.open`); `RevLogConnection` over the generated stream client using the Phase 1 state machine; move `ConnectionKeeper` from Write to `wonky_app` and use it in both | `packages/wonky_revlog_flutter/`, `packages/wonky_app/lib/src/core/connection_keeper.dart` |
| RL-4.2 | `LoggedWorkbookSession implements WorkbookSession`: execute/applyChanges → model + outbox; remote ops → model + overlay + `remoteBatches` + store; acks (dropped/overwritten/fixups); `flush()` = outbox durable | `wonky_sheets/lib/features/revlog/logged_workbook_session.dart` |
| RL-4.3 | Open paths: local-complete (viewport-first from SQLite, reuse `_loadAll` logic minus the journal), remote bootstrap (pages → `WorkbookRowLoading`/`LoadingGate`), offline unavailable. Progress UI without "Downloading spreadsheet… %" (ready after the first page) | same folder; `features/model/row_loading.dart` |
| RL-4.4 | Offline: outbox compose, background sync of closed files with an outbox, availability (recent 14 days / 50, pinned; *Make available offline* downloads all pages), *Settings › Offline & storage* (`ReplicaOfflineProvider` → `RevLogOfflineProvider`), *Clear local data*, *Simulate offline* | `features/revlog/`, `packages/wonky_revlog_flutter/lib/src/install/` |
| RL-4.5 | Offline creation without reserved spaces: client UUID, queued `drive.createSpreadsheet`, the first outbox op carries the initial structure | `features/revlog/sheets_files.dart`, shell `PendingDriveOp` |
| RL-4.6 | Conflicts: feed `RevAck.overwritten` into `SheetsConflicts` (review dialog, Sheets 10 §9); remove the HLC-based detection | `features/collab/conflicts/*` |
| RL-4.7 | Collaboration: drop `cell`/`range` commit hints (keep `typing`, `pending`); remove the hint overlay paths that wait for synced rows | `features/collab/hints/commit_hints.dart` |
| RL-4.8 | Wire up: `SheetsData` → `SheetsRevLog` (install at sign-in, `openWorkbookSession`, `createSpreadsheet`); delete `features/sync/` | `wonky_sheets/lib/features/sync/*` (deleted) |

Tests:

- port `test/sync` and `test/model` to the new session (remove the journal/property tests that compared incremental vs full reload, replace them with overlay tests);
- an in-process server test with two clients;
- offline reconnect after "days" (fake clock);
- crash between outbox write and send;
- conflicts dialog fed from acks.

Exit: `flutter test` green in `wonky_sheets`; manual check of the release web build with two browsers (edit, offline, reconnect, conflicts, big paste, import).

## Phase 5 — Performance verification (≈ 1 w)

| Id | Task |
|----|------|
| RL-5.1 | Re-run the RL-0.1 suite on the real implementation; add it to the `slow` tag set (server `test/integration/sheets/revlog/perf_test.dart`, client `wonky_sheets/test/revlog/perf_test.dart`) |
| RL-5.2 | **Gates** (replace suite 12 §5 M3): propagation p95 < 250 ms (one instance), < 400 ms (two); first paint of a 1M-cell sheet not on the device < 1.5 s desktop / < 3 s web; complete download 1M cells < 15 s desktop / < 30 s web OPFS; 1M-cell import (local) < 30 s; 5,000-change commit p95 < 300 ms; idle server CPU per connection ≈ 0 |
| RL-5.3 | Raise the cell limit if the gates hold at 5M (the old U1–U5 prerequisites no longer apply) |

## Phase 6 — Slides onto RevLog (≈ 5 w)

| Id | Task |
|----|------|
| RL-6.1 | Models: 13 Slides tables → plain tables with `fileId`; drop `DeckChangeLog` (synced) and the receipt tables |
| RL-6.2 | `DeckRevLogBinding` (validation, normalization of the Slides 02 §10 maintenance repairs, text-body size limits); hooks (activity, versions, chart links, comment orphaning, overwritten-text review data) |
| RL-6.3 | Server writers: `ServerSlidesWriter`, headless deck cache (shared generic `HeadlessFileCache<T>` with the Sheets provider: one memory budget, refcounts, op subscription; fixes the duplication found in review), AI, MCP, templates, copies, restore |
| RL-6.4 | `LoggedDeckSession implements DeckSession`; single-page bootstrap; offline creation without reservations; soft locks and text hints unchanged |
| RL-6.5 | Port the Slides sync and model tests; release-build check with two browsers |

## Phase 7 — Removal and specs (≈ 2 w)

| Id | Task |
|----|------|
| RL-7.1 | Delete `third_party/serverpod_offline_sync`, the `serverpod_offline_sync_client`/`_server` dependencies and their config; `wonky_sync_kit*` (or keep the name as an alias for `wonky_revlog`, then delete); `platform/spaces/`; client migrations of synced tables; `sheets_*` journal tables; reserved-space pools; the weekly purge; replica recovery export; OS-8 kind filter |
| RL-7.2 | Update the specs in the same change: suite 01 (decisions A10 and the related ones, package list, third-party list), suite 12 (rewrite §2 and §4–5; the upstream requirements table goes away), suite 07 (collaboration latency), suite 13 (server-side validation, op log retention), Sheets 02 (§1 principles S1/S8/S10, §3.7, §4, §5, §6–§8), Sheets 10 (§2 hints, §5 versions, §6 cell history, §9 conflicts, §10 offline scenarios), Sheets 13 (perf gates), Sheets STATUS, Slides 02 (§9, §4.5 note), Slides 09, Slides STATUS, Drive 05 D-4/D-6 notes, `AGENTS.md` package table, `TODO.md` (remove engine items, add RevLog follow-ups) |
| RL-7.3 | CI: drop the engine from the workspace; add `wonky_revlog`/`wonky_revlog_flutter` test jobs |

## Totals

| Phase | Estimate |
|-------|----------|
| 0 Baseline + prototype | 1.5 w |
| 1 Core | 2 w |
| 2 Server sequencer + tables | 3 w |
| 3 Server readers/writers | 3 w |
| 4 Client | 4 w |
| 5 Perf verification | 1 w |
| 6 Slides | 5 w |
| 7 Removal + specs | 2 w |
| **Total** | **≈ 21.5 w** (Sheets alone, phases 0–5: ≈ 14.5 w) + 10–15 % contingency |

**Critical path:** 0 → 1 → 2 → (3 ∥ 4) → 5 → 6 → 7. Phases 3 and 4 can run in parallel once the Phase 2 protocol is frozen.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Per-file serialization limits throughput (many editors, huge pastes) | Low | Medium | Small ops, set-based SQL, side effects outside the lock; chunked big ops; measure at 50 editors in Phase 5 |
| Large change sets on the stream (frame limits, memory) | Medium | Medium | Gzip; `submitLarge` over HTTP; ≤ 5,000 changes per op |
| Overlay/ack bugs cause divergence | Medium | High | Fuzzers from Phase 1; a debug-only full-state hash compare (client vs server, per sheet) behind a developer switch |
| Semantics change for late offline edits surprises users | Medium | Low | Overwritten-field review from acks; help text update (Sheets 02 §3.3) |
| Scope creep (rewriting features while migrating) | Medium | Medium | The editor contract (`WorkbookSession`/`DeckSession`) is frozen; only the data layer changes |
| Server becomes a single point for edits (no peer-to-peer) | — | — | Already true in practice (the server is the authoritative peer today) |
| Web storage without OPFS | Medium | Low | Only offline availability is limited; online opening works by pages |

## What to do with the code-quality items that touch sync

If this migration is accepted, skip these items in the code-quality plan (they disappear with the code):

- the vendored engine upgrade (CQ-62, TP-1);
- the `ChangeLogConsumer`/`DeckChangeLog` consumer and pruning fixes (fix them only if Phase 2 is more than a month away: the pruning stall is a real bug);
- the headless `xmin` patch scan;
- the duplicated Sheets/Slides consumer code;
- the `sheets_*` journal table renames.

The Write OT fixes (W1–W6) are independent and should be done either way. RevLog reuses that
code's patterns.
