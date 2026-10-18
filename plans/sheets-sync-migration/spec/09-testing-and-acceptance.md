# RevLog spec 09 · Tests, performance gates and acceptance

Conventions follow `specs/15-writing-tests.md`:

- Given/When/Then names, `clock` instead of `DateTime.now()`, seeded randomness.
- Tags: `property`, `slow`, `integration`, `e2e`.
- Server tests use `withWonkyServerpod`; its `tearDownAll` adds `RevFileStates.clear()` and `HeadlessFileCache.clearAll()`.

## 1. Test doubles

| Double | Where | Based on |
|--------|-------|----------|
| `FakeRevServer` | `packages/wonky_revlog/lib/src/testing/` (exported via `testing.dart`, **not** from the main barrel; avoids code-quality sc L1) | Write's `FakeDocumentServer` (`wonky_write/test/features/sync/support/fake_document_server.dart`): in-memory schema store + pure `applyChangeSet`; `autoDeliver`, `deliverNext/All/Random(dropRate)`, `setRole`, `commitExternal(changes, {userId})`, `forceReject(code)`, `prune(upTo)` |
| `FakeRevTransport` | same | Write's `FakeTransport` |
| `MemoryRevStore` | same | in-memory `RevLocalStore` for unit tests; the SQLite store is tested separately |
| `TestRevClient` | `wonky_server/test/support/test_rev_client.dart` | Write's `TestDocClient` (`connect`, `submit`, `next<T>`, `close`) |
| Device harness | `wonky_server/test/support/sheets_device.dart`, `slides_device.dart` (rewritten) | Real `RevConnection` + `RevLocalStore` (SQLite in a temp dir) against the in-process server over HTTP |

## 2. Property tests (`property`)

| # | Property | Package / file |
|---|----------|----------------|
| 2.1 | Codec round trip: `decode(encode(cs)) == cs` for random valid change sets of both schemas; payload hash stability | `packages/wonky_revlog/test/property/codec_property_test.dart` |
| 2.2 | **Persisted state == pure apply.** Random initial state and random ops applied by `RevLogService.submit` (Postgres) give tables equal to `applyChangeSet` run on the same state, and the stored applied form equals the pure applied form (dropped, conflict candidates and cascades included; attribution is checked separately in `apply_rules_test`). Replaying the stored applied forms from revision 0 reproduces the tables | `wonky_server/test/integration/platform/revlog/apply_equivalence_test.dart` (tagged `property`) |
| 2.3 | **Convergence fuzzer.** N = 3 clients (each `RevSyncCore` + model, Sheets and Slides variants) and `FakeRevServer`. 400 steps of random planner ops (cells, formats, row/column insert/delete/move, sheets, merges, rules; Slides: slides, elements, groups, tables, text), undo/redo, random delivery and drops, disconnects, offline periods, duplicate sends. At the end, after `deliverAll`, every model equals the server state and every store equals the server. 12 seeds per run, 200 in the nightly job | `packages/wonky_sheets_core/test/property/convergence_property_test.dart`, `packages/wonky_slides_core/test/property/convergence_property_test.dart` |
| 2.4 | **Plans list descendants.** For random models and every delete op, the plan deletes every model descendant of every deleted row (RD-3) | `packages/wonky_sheets_core/test/property/delete_descendants_property_test.dart`, Slides equivalent (fully loaded models; partial models are covered by the delete gates, 06 §5.5) |
| 2.5 | **Bootstrap equivalence.** Server state S0, a random sequence of ops, and pages read at random interleavings (random page boundaries and kinds); the client follows 06 §5.3. The final store and model equal the server head | `packages/wonky_revlog_flutter/test/property/bootstrap_property_test.dart` (includes own acked ops and reconnects during bootstrap) |
| 2.6 | **Overlay.** For random server state, outbox and remote op: `Overlay.build` applied to the model equals a rebuild from (new server state + outbox); no change when the remote op equals the model (echo) | `packages/wonky_revlog/test/property/overlay_property_test.dart` (replaces `remote_patch_property_test.dart` in both apps; includes deterministic-id inserts on both sides) |
| 2.7 | **Chunking.** Plans of up to 120,000 changes chunk into ops ≤ 5,000 changes and ≤ 1 MiB compressed, in rank-respecting order, and applying the chunks equals applying the plan | `packages/wonky_revlog/test/property/chunker_property_test.dart` |
| 2.8 | **Client gate ⇒ server check.** For random protected models (ranges, sheet protections with exceptions, editors, warning-only) and random operations by random users: if the client gate (`WriteIntents.of` + `ProtectionGuard`) allows the operation, the sequencer check (`WriteIntents.fromApplied` + `BoundaryRepair` + `ProtectionGuard`) on the same model allows its plan. If the server blocks, so does the client (except for protections the client doesn't know) | `packages/wonky_sheets_core/test/property/protection_parity_property_test.dart` |

## 3. Server integration tests (`integration`)

`wonky_server/test/integration/platform/revlog/`:

| File | Cases (each a test) |
|------|---------------------|
| `submit_test.dart` | Commits and acks in revision order. Duplicate `clientOpId` sequentially and **concurrently** (two connections) → one op, two acks with the same revision and the same applied form. A duplicate whose payload is pruned → `applied == null`. `unknownBase`. `schemaMismatch` vs an accepted `compatibleWith` hash. Each `invalidChange` rule of 03 §5, incl. **a foreign id from another file is rejected and that file's row is unchanged** (review 4) and immutable columns. `tooLarge`. Root-row insert outside creation refused. The creation op picks up the drive item's current title |
| `apply_rules_test.dart` | Insert under a deleted parent → dropped. Update of a missing row → dropped. Delete of a missing row → no-op. A deterministic-id insert merges per column and **appears as an update in the applied form**; reverting it keeps the other user's columns (review 30). Cascaded children (cells by `(sheetId,rowId)` without a DB FK) are deleted and appended to the applied form. Conflicts are attributed to the field's last writer, and only other users' writes count |
| `ack_echo_test.dart` | The author's connection receives `RevAck` (with `applied` when it differs, and the outcome) and **no** `RevRemoteOp` for its own op. Another tab of the same user receives the `RevRemoteOp`. A lost ack is recovered from `ops()` with `outcomeJson` |
| `editor_limit_test.dart` | A joiner over `maxEditorsPerFile` is told `viewer`, and its submits are refused (`forbiddenForRole`) |
| `protection_test.dart` (Sheets) | Owner protects F2:F40 "Only you": an editor's op writing F5 → `protectedRange` with details; an op touching F5 and G5 is rejected whole; owner, creator and listed editors are allowed; warning-only never blocks. Sheet protection with `except` ranges. Structural: deleting, inserting inside or moving rows that intersect a protection is blocked; resize, hide and groups are allowed. **Boundary repairs**: deleting an unprotected row rewrites a protected formula's reference to that row → allowed; the same rewrite without the delete → blocked; a rewrite of a protected formula that changes anything but tokens of deleted ids → blocked. Updating or deleting a `protected_range` row without `canManage` → blocked; creating one → allowed. `system` server changes exempt. MCP write into a protection → `protected_range`. Version restore pre-check refuses before any chunk. An offline op made before the protection existed → rejected on sync. Files without protections: no headless model is loaded (query counter) |
| `access_test.dart` | Viewer/commenter submit refused. Grant expiry refuses the next submit and closes the stream on the 5-minute re-check (fake clock). Unshare → stream closed `forbidden`. Trash → `fileReadOnly`. `ops()` range rules for viewers vs editors (05 §11) |
| `connection_test.dart` | `RevInit` tail vs bootstrap (≤ 1,000, pruned). Gap fill. A message that throws doesn't stop later messages (CQ-5 pattern). Early cancel during start leaves no lease, timer or roster entry. Ping |
| `multi_instance_test.dart` | `Cluster.debugDistributed`: ops relayed in order with the immediate flush; large ops by reference; catch-up after `RevFileStates.evict`; editor limit with a foreign roster |
| `hooks_test.dart` | Every hook of 05 §6.2 produces its effect. A failing hook keeps its cursor, retries, and doesn't block the other hooks. Crash/restart resumes (simulate by evicting state and running the sweep). The throttled `modified` hook gets a trailing run. **Two instances racing for the lease: only one drains; the lease expires and is taken over after a crash** (review 6). Kicks are debounced (one drain per burst) |
| `lost_bus_test.dart` | A dropped bus `op` message is detected through `RevPong.headRevision` / `beat` and gap-filled (review 36). An immediate post doesn't overtake queued messages |
| `create_init_test.dart` | `createFile` with a crash after transaction A → `initPending` → the retry and `initSweep` finish it idempotently (deterministic init `clientOpId`s) |
| `pages_test.dart` | Structure/rows/cells pages. `coverage` correctness. Each page consistent with its revision while ops commit concurrently |
| `server_change_test.dart` | Chunked server change: lock released between chunks, client ops interleave, record spans the revisions. Revert/reapply with the skip rule (partial). Expired records |
| `create_file_test.dart` | Blank create at revision 0 + client creation op. Template, copy and import create groups. Idempotent on `fileUuid` |
| `purge_test.dart` | Purge of a 200k-cell file in batches, following the sequence of 05 §10.1: open streams closed with `notFound`, headless entries evicted, hooks stopped; ops and hook state cascade. `drive_item` can't be deleted before `rev_file` (Restrict) |
| `jobs_test.dart` | Op pruning (batches, time budget, keeps ops of unexpired records, advances `prunedBelow`, keeps slim rows; idempotency after pruning), hook sweep, init sweep, stats repair |
| `headless_cache_test.dart` | Load at revision. Applies bus ops. Fills gaps from `rev_op`. Leases prevent disposal. Budget eviction. Copy-on-write shadows |

**Ported and rewritten** (inventory server §9):

| Old | New |
|-----|-----|
| `sheets_sync_test.dart` (14) | `integration/sheets/revlog/sheets_revlog_test.dart` (create, edit, two devices, ACL, rename mirror, server create, template + copy, trash, hooks once) |
| `slides_sync_test.dart` (9) | `integration/slides/revlog/slides_revlog_test.dart` |
| `space_kinds_test.dart`, `projection_rebuild_test.dart`, `unit/sync/sync_schema_release_test.dart` | deleted |
| `drive_presentations_test.dart`, `m8_contracts_test.dart` | creation contracts updated (no register) |
| `bulk_writer_test.dart`, `sheets_revert_test.dart` | `server_change_test.dart` + Sheets MCP revert tests |
| `server_writer_perf_test.dart` | `revlog_perf_test.dart` (`slow`) |
| `headless_cache_test.dart`, `slides_headless_test.dart` | adapted to `HeadlessFileCache` |
| Versions, comments, charts, scripts (incl. `scripts_user_properties_test.dart`), AI, import/export, storage tests | Same cases against the new writers and readers; each test file is adapted, not dropped |

## 4. Client tests

| Package | Tests |
|---------|-------|
| `wonky_revlog` (`RevSyncCore`) | State machine with `FakeRevServer`: send only when durable; one in flight; buffer composition; ack with and without `applied`; a lost ack recognized from catch-up; **rejection of one chunk drops the rest of the group and emits `groupRejected`**; reconnect resend; a pruned duplicate → re-bootstrap; outbox older than 180 days not resent |
| `wonky_revlog_flutter` | Store: migrations; `applyServerOp` atomically acks the outbox and is **monotonic** (an older revision is ignored); a schema-hash change keeps and **re-stamps** the outbox; eviction policy; outbox export; web clean-up of the old replica by truncation. **Multi-tab:** two stores on one file, with each tab sending only its rows, adoption of a dead tab's rows under the lock, and a lagging tab never moving the cache backwards (review 22). Bootstrap scheduler: structure + excluded `rows` pages → viewport → ready → streaming; prioritize; coverage table; reconnect during bootstrap. Background sync with `bootstrap: true` sends the outbox only |
| `wonky_sheets` | Port `synced_workbook_session_test` (13) to `logged_workbook_session_test`, keeping every behavior of the inventory checklist (sheets-client §2.9). Port `viewport_loading_test` (6). `sheets_revlog_client_test` replaces the controller and maintenance tests (create online/offline, open offline, availability). **`offline_scenarios_test.dart` (10) rewritten to the expectations of 07 §6.** Conflicts tests fed by outcomes. Cell history with `history`. Commit hints: remove the `cell`/`range` cases. Script compile waits for `whenSynced`. User properties offline queue. **Delete gates:** deleting a sheet, columns or unloaded rows while streaming is refused with `still_loading` (review 8). Repairs don't run while a remote group is half-applied. A rejected group removes its undo step. A `protectedRange` rejection shows the blocked message; for an offline op, *Save my changes as a copy* creates a file containing the rejected edits; a rejected repair isn't retried for 24 h. The client gate imports `WriteIntents` from the core and behaves as today (existing protection tests pass unchanged). Offline create → rename → replay keeps the new name. An orphaned create offers *Save as new* |
| `wonky_slides` | Port `synced_deck_session_test` (16) → `logged_deck_session_test`; `slides_data_test` (7) → `slides_revlog_test`; delete `slides_writer_test` and `columns_lint_test`; history/conflict tests on outcomes; agent writes on `history`; maintenance repair runs after remote ops |
| Cores | Move kit tests (`wonky_sync_kit/test/{rows,undo}`) to `wonky_revlog`; `SyncRelay`-based core tests keep working (in-memory LWW relay; rename to `RevRelay` backed by `applyChangeSet`) |

## 5. End-to-end (`e2e`, against `serverpod start`)

`wonky_sheets/test/e2e/revlog_live_e2e_test.dart` and the Slides equivalent, modelled on Write's
`live_server_e2e_test.dart` (`WONKY_API` env):

1. Two clients edit the same file concurrently and converge.
2. Offline edits on one client, then reconnect.
3. A big paste (50,000 cells).
4. Cold open of a 200,000-cell file.
5. MCP writes while a client edits.
6. Restore a version while a client edits.

**Manual release-build check** (AGENTS.md browser notes): two browser profiles, one with
*Simulate offline*. Steps: edit, go offline, edit, come back, review conflicts, undo, import,
open a large file.

## 6. Performance gates (`slow`; replace suite 12 §5 M3 gates and Sheets 13 §7.5)

| # | Metric | Budget | Measured by |
|---|--------|--------|-------------|
| P1 | Local op → visible in another client's model, one instance | p95 < 250 ms | e2e + `revlog_perf_test` (two `TestRevClient`s, 500 single-cell ops) |
| P2 | Same, two instances (`Cluster.debugDistributed` with Redis) | p95 < 400 ms | multi-instance perf test |
| P3 | Server commit, ≤ 100 changes | p95 < 15 ms | `revlog_perf_test` |
| P4 | Server commit, 5,000 changes | p95 < 300 ms | same |
| P5 | Idle server cost per connected client | no DB queries while idle except the 5-minute role check | query counter in the perf test |
| P6 | Cold open (not on the device) of a 1M-cell sheet → `WorkbookReady` | < 1.5 s desktop, < 3 s web (OPFS) | client perf test against a local server; web via release build |
| P7 | Complete download of a 1M-cell sheet | < 15 s desktop, < 30 s web | same |
| P8 | Reopen from cache (1M cells) → ready | ≤ today (0.55 s for 200k; scale linearly) | client perf test |
| P9 | 1M-cell local import (`applyChanges` into the outbox) | < 30 s | client perf test |
| P10 | Server import of 1M cells (server change, 200 ops) | < 60 s | `revlog_perf_test` |
| P11 | Storage per non-empty cell (Postgres, incl. indexes) | ≤ 250 bytes average for typical content | `pg_total_relation_size` / cells |
| P12 | Server commit on a warm 200k-cell file with 20 protections, ≤ 100 changes | p95 < 30 ms; no cold model load inside the lock while a connection is open | `revlog_perf_test` |

The gates are measured in R0 (prototype; baseline for today's engine) and R6 (real
implementation). A regression > 20 % in the nightly job fails it (code-quality CQ-38).

## 7. Acceptance checklist (user-visible)

**Sheets**

- [ ] Opens instantly from the cache, including offline. A file not on the device opens online after its first pages, with no "Downloading…" percentage.
- [ ] Edits reach collaborators in about a second or less.
- [ ] Remote cursors and typing preview still work.
- [ ] Offline editing, reconnect, and a review of overwritten or dropped edits (07 §6).
- [ ] Undo/redo works across collaborators with the partial toast; server changes (AI, MCP, restore, import) are undoable.
- [ ] Version history: capture, view, diff, attribution, restore (live for collaborators), copy.
- [ ] Cell history online and offline.
- [ ] Scripts: compile after save, triggers, user properties (also offline), time-driven triggers.
- [ ] MCP and AI reads and writes; Suggest mode; `sync_version`.
- [ ] *Make available offline*; Settings › Offline & storage figures; *Clear local data* exports pending changes first.
- [ ] The sync status says "Saved" only after the server acknowledged the changes.
- [ ] Cell limit enforced on the server with a clear message.
- [ ] Protected ranges enforced on the server: no client, offline edit or MCP/AI/script write can change a protected cell without permission. Warning-only protections still just warn.

**Slides**

- [ ] All of the above that apply (opening, editing, offline, undo, versions, MCP/AI).
- [ ] Soft locks, text hints and the overwritten-text review still work.
- [ ] Repairs run.
- [ ] Linked charts update.
- [ ] Presenting shows edits live.

**Operations**

- [ ] No `serverpod_offline_sync` code, tables or config remain.
- [ ] `ProtocolInfo.revSchemaHash` is published.
- [ ] `minClientVersion` 3.0.0.
- [ ] The jobs run.
- [ ] Hook lag is visible in Settings › Developer.
- [ ] The specs are updated (spec file 11).
