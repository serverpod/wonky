# RevLog spec 10 · Work breakdown (PR sequence)

This file replaces the coarser phases of [`../03-implementation-plan.md`](../03-implementation-plan.md)
for execution; that file keeps the rationale, risks and gates.

## 1. Branch strategy

- **Additive pieces land on `main` directly:** the core package, infrastructure, and Write fixes reused by RevLog. They change no behavior.
- **The switch of an app happens on an integration branch:**
  - `revlog/sheets`: PRs R3–R6 are merged into it, and the branch merges into `main` when gate **G2** passes.
  - `revlog/slides`: R7, merged at **G3**.
  - In both cases `main` keeps working the whole time. Rebase the branch on `main` weekly.
- **Sheets and Slides can coexist on different engines in between.** Their tables are separate, the vendored engine stays until R8, and `wonky_sync_kit_flutter` stays until Slides has moved.
- **PR conventions** (AGENTS.md):
  - Each PR updates the specs it changes (spec file 11 lists them per PR).
  - Each PR runs `dart analyze`, `dart format`, migrations via MCP, tests, and log checks.

## 2. PRs

### R0 · Baseline and prototype (≈ 1.5 w) — no merge of product code

| Item | Detail |
|------|--------|
| R0.1 | `slow` benchmarks of today's engine (merged to `main` as tests): `wonky_server/test/integration/sheets/sync/engine_baseline_perf_test.dart`, `wonky_sheets/test/sync/cold_sync_perf_test.dart`. They measure P1, P5–P8 and P11 for the CRDT engine. Results go in `plans/sheets-sync-migration/baseline.md` |
| R0.2 | Throw-away prototype on `revlog/prototype` (never merged): `rev_file`, `rev_op`, `cell` plain table, submit + bus + Dart client. Measure P1, P3, P4, P6, P7. Choose the bulk-SQL form of 05 §3.3 (`jsonb_to_recordset` vs `unnest`) and the structure page sizes (05 §7.1) |
| **G1** | Decision recorded in suite 01 §1 and spec file 01 (go / fallback to option D) |

### R1 · `wonky_revlog` core + shared protection code (≈ 2.5 w) → `main`

| Item | Files |
|------|-------|
| New package `packages/wonky_revlog` (pure Dart; deps `wonky_core`, `collection`; **no** dependency on `wonky_sync_models`) | `pubspec.yaml`, `analysis_options.yaml` (strict modes, CQ-64e), `lib/{rows,undo,schema,codec,apply,client}.dart`, `lib/testing.dart` (not exported from the main barrel) |
| Move from `wonky_sync_kit`: `row_change`, `mutation_plan`, `compose_row_changes`, `undo_inverter`, `rows_undo` (+ tests); `RowsUndoEntry` gains an optional `groupId` (06 §4.6) | `packages/wonky_sync_kit/lib/src/{rows,undo}/*` → `packages/wonky_revlog/lib/src/{rows,undo}/*`; `wonky_sync_kit` re-exports them, so nothing else changes in this PR |
| `RowPatch` → `Overlay` (keep `RowPatch` as a deprecated alias until R5/R7) | `lib/src/apply/overlay.dart` |
| `RevSchema` types | `packages/wonky_revlog/lib/src/schema/*` |
| `sheetsSchema`, `slidesSchema` (instances, hand-written from today's `.spy.yaml`) | `packages/wonky_sheets_core/lib/src/revlog/sheets_schema.dart`, `packages/wonky_slides_core/lib/src/revlog/slides_schema.dart`; cores add the `wonky_revlog` dependency |
| Protection code shared (RD-19) | Move `WriteIntents` from `wonky_sheets/lib/features/protection/write_intents.dart` to `wonky_sheets_core/lib/src/data_tools/protection/write_intents.dart` (the app imports it; behavior unchanged). Add `WriteIntents.fromApplied(applied, model, deletedIds)` (structure derived from changes) and `BoundaryRepair.isRepair` (05 §3.5). Tests: 09 §2.8 parity property; unit tests for `BoundaryRepair` |
| Plan-less summaries move to the core | `SheetsWriter.summarize` (`wonky_sheets/lib/features/sync/sheets_writer.dart:67-109`) → `SheetsChangeSummary.ofChanges` in `wonky_sheets_core` (the app calls the core version) |
| Codec, `ChangeSet`, chunker, composer, `applyChangeSet`, `RevRowStore`, **`RevSyncCore`** (pure state machine), `FakeRevServer`, `FakeRevTransport` | `lib/src/{codec,apply,client}/*`, `lib/src/testing/*` |
| Tests | 09 §2.1, 2.3 (pure: `RevSyncCore` against `FakeRevServer`), 2.4, 2.6, 2.7; schema guard on the cores |
| Dependency rules | `tool/check_dependencies.dart`: `wonky_revlog` is pure (layer of `wonky_core`); the cores may depend on it |

### R2 · Shared infrastructure (≈ 0.5 w) → `main`

| Item | Files |
|------|-------|
| `ConnectionKeeper` (+ Shell/Simple variants) moved to `wonky_app`; Write imports it from there | `wonky_write/lib/features/sync/connection_keeper.dart` → `packages/wonky_app/lib/src/sync/connection_keeper.dart` |
| `ClusterBus.post(…, immediate: true)`; Write's `DocumentBus` op posts use it | `wonky_server/lib/src/platform/cluster/cluster_bus.dart`, `write/ot/document_bus.dart`, `cluster_bus_test.dart` |
| Write OT fixes reused as patterns (from the code-quality plan): per-message `catch (Object)`, idempotency inside the transaction, `_closed` checks, `updateMeta` named columns, leases in `DocumentCache` | `write/ot/*` (CQ-4, CQ-5, CQ-23) — recommended before R3 so the lifted code starts correct |

### R3 · Server platform + Sheets server binding (≈ 3.5 w) → `revlog/sheets`

| Item | Files |
|------|-------|
| Platform module | `wonky_server/lib/src/platform/revlog/{rev_binding,rev_log_service,rev_sql,rev_file_state,rev_log_connection,rev_bus,rev_hooks,rev_pages,rev_jobs}.dart`, `models/{rev_file,rev_op,rev_hook_state,rev_file_kind}.spy.yaml`, `messages/*.spy.yaml` (04 §2) |
| Sheets tables become server tables | Move 22 `.spy.yaml` from `packages/wonky_sync_models/lib/src/models/` to `wonky_server/lib/src/sheets/models/rows/` (drop `database: sync`, add `serverOnly`, `file`, `revision`; `cell.row`/`cell.column` become plain `rowId`/`columnId`; 02 §2). Delete `change_log.spy.yaml`; `script_user_property` → server table (02 §2.4). `create_migration` (destructive) + `apply_migrations`. **On the long-lived branch, regenerate this migration when merging to `main`** (the migration registry is linear) |
| Sheets enums | Server: 10 Serverpod enums next to the tables. Cores and apps: hand-written pure-Dart twins in `packages/wonky_sync_models/lib/enums.dart` (same names and values); change the ≈ 80 Sheets-side imports (`wonky_sheets_core`, `wonky_sheets_script`, the app) from the generated protocol to `enums.dart`; guard test (02 §2.1) |
| Sheets binding and endpoint | `sheets/revlog/{sheets_rev_binding,sheets_hooks,sheets_stats}.dart`, `sheets/endpoints/sheets_doc_endpoint.dart` |
| Protection enforcement | `sheets/revlog/sheets_protection.dart`: `authorize` runs the guard on `models.atPrevious()` (05 §3.5); connection pre-warm lease for protected files; `RevRejectCode.protectedRange` + `detailsJson`. Needs `HeadlessFileCache` (pulled forward from R4: load, ops subscription, leases). Tests: `protection_test.dart`, P12 |
| Hooks | Port the `ChangeLogConsumer` duties (05 §6.2); delete `sheets/changelog/change_log_consumer.dart` and `sheets_change_log_receipt`. `server.dart`: register the binding and jobs; remove `registerScriptHooks`' plugin registration |
| Access | `platform/sharing/acl_events.dart`: spreadsheet branch → `RevBus.rolesChanged` |
| Creation | `drive.createSpreadsheet(…, fileUuid?, initialize)` (04 §5); remove `registerSpreadsheet`; `SpreadsheetFactory.changes` + `createFile` with `initPending` (05 §8.3); purge sequence and `rev_file.item` Restrict (05 §10.1) |
| Tests | 09 §3 platform files with the Sheets binding; 09 §2.2 |

### R4 · Sheets server writers and readers (≈ 3.25 w) → `revlog/sheets`

| Item | Files (inventory server §3–§6) |
|------|-------------------------------|
| `submitServerChange`, revert/reapply, `ServerChangeRecord` reshaped (02 §2.5) | `platform/revlog/rev_log_service.dart`, `sheets/models/server_change_record.spy.yaml` |
| Writers re-pointed | `sheets/mcp/sheets_writes.dart` (44 MCP sites unchanged; the primitive changes), `sheets_bulk_writer.dart` (deleted; logic in `submitServerChange`), `sheets_changes.dart`, `sheets/sync/server_sheets_writer.dart` (deleted), `sheets/ai/sheets_ai_service.dart` (applyFill, applyPreview), `sheets/scripts/script_service.dart` (compile, writeFile, deleteFile, run, user properties), `sheets/imports/sheets_import_service.dart` and `sheets_import_jobs.dart` (also fix the lease/claim bugs, CQ-9), `sheets/versions/sheets_version_provider.dart` (capture at a revision, restore), `sheets/spaces/space_copier.dart` → `changes()`, `platform/drive/drive_service.dart` (rename mirror, copy, purge batching, CQ-1) |
| Readers | `HeadlessFileCache` (05 §9) replacing `sheets/headless/headless_workbook_provider.dart`; call sites of inventory server §4a; `SlidesChartService` keyed on revision (Slides still on the CRDT reads the Sheets file through the new cache) |
| Versions | `sheets_version_changes.dart` by revision windows; `sheets_snapshot_index.revision`; `cell_history` reshaped; `sheets_service.cellHistory` (Editor+); version restore **protection pre-check** (05 §3.5) |
| MCP and scripts | `protectedRange` rejections → MCP error `protected_range`; `SheetsWrites.run` keeps its early guard, now with `WriteIntents` from the core; script runs checked as the run-as user |
| Storage | `platform/storage/content_sizes.dart` Sheets estimator by `fileId` |
| Delete | `sheets/sync/{sync_db,synced_tables,sheets_sync_service}.dart`, `sheets/endpoints/sheets_sync_endpoint.dart`, `sheets/spaces/sheets_spaces.dart` (reserve/subscribe/…), Sheets parts of `platform/spaces/*` (the Slides parts stay until R7) |
| Tests | 09 §3 ported Sheets files |

### R5 · Client package + Sheets app (≈ 4.25 w) → `revlog/sheets`

| Item | Files |
|------|-------|
| `packages/wonky_revlog_flutter` | `lib/src/{store,connection,bootstrap,client,offline,export}/*` (06) |
| Sheets binding | `wonky_sheets/lib/features/revlog/{logged_workbook_session,sheets_rev_log,sheets_files,user_properties_client}.dart` |
| Call sites (06 §7.1) | `config/sheets_app_config.dart`, `features/sheet_editor/sheet_editor_screen.dart`, `features/import/import_pipeline.dart`, `features/history/{version_copy,cell_history,local_conflicts,conflict_review_dialog}.dart`, `features/scripts/{script_service,runtime/user_properties}.dart`, `features/ai/external_agent_writes.dart`, `features/collab/sheets_collab.dart`, `features/collab/hints/commit_hints.dart` (remove cell/range), `features/objects/objects_controller.dart` + wire `WorkbookMaintenance` (03 §6) |
| Delete | `wonky_sheets/lib/features/sync/*` (9 files) and the Sheets use of `wonky_sync_kit_flutter`. **Client DB migrations:** regenerate (the generator emits a migration that drops the Sheets client tables); never delete generated migration files by hand (02 §2.3) |
| Gates and multi-tab | `LoadingGate` delete gates (06 §5.5); tab ids, Web Locks and outbox adoption (06 §2.6) |
| Protection rejections | `protectedRange` handling (06 §4.6 step 5): blocked message, *Save my changes as a copy* for offline groups, repair back-off; strings |
| Strings | Remove `downloadingSpreadsheet`, the recovery strings and the reserved-space errors; add the conflict and outcome strings of 06 §6, "Opening spreadsheet…", and wire `loadingRowsStatus` |
| Tests | 09 §4 (Sheets + `wonky_revlog_flutter`), 09 §2.5 |

### R6 · Sheets performance, e2e, merge (≈ 1 w) → **G2**, merge `revlog/sheets` → `main`

| Item | Detail |
|------|--------|
| Gates | 09 §6 P1–P12 for Sheets; results appended to `baseline.md` |
| e2e | 09 §5 Sheets |
| Specs | Spec file 11, Sheets part |
| `minClientVersion` | 3.0.0 (`ProtocolInfo`), `revSchemaHash` published |

### R7 · Slides (≈ 5 w) → `revlog/slides` → **G3**, merge → `main`

| Item | Files |
|------|-------|
| Server | Move the 12 Slides `.spy.yaml` (delete `deck_change_log`); Slides enums: Serverpod enums + pure twins in `wonky_sync_models/lib/enums.dart` (the ≈ 28 Slides-side imports change, as R3 for Sheets); regenerate the migration at merge; `slides/revlog/{slides_rev_binding,slides_hooks}.dart`; `slides/endpoints/slides_doc_endpoint.dart`; writers (`slides/sync/server_slides_writer.dart` deleted → `submitServerChange`), `headless_deck.dart`, `headless_deck_cache.dart` (deleted → `HeadlessFileCache.slides`), `slides_decks.dart`, `deck_factory.dart`, `slides_template_decks.dart`, `deck_copies.dart`, `slides_version_provider.dart`, `slides/changelog/*` (deleted → hooks), `slides/mcp/*` (`sync_version`, writes), `slides/ai/*` (shadows, previews), `slides_chart_service.dart` |
| Client | `wonky_slides/lib/features/revlog/{logged_deck_session,slides_rev_log}.dart`; call sites of 08 §2; delete `wonky_slides/lib/features/sync/*`, `features/model/synced_deck_session.dart` |
| Tests | 09 §2.3–2.5 Slides variants, §3 Slides ported, §4 Slides, §5 Slides e2e |
| Gates | P1, P6, P8 for decks (500-slide deck) |

### R8 · Removal (≈ 1 w) → `main`

| Item | Files |
|------|-------|
| Engine | Delete `third_party/serverpod_offline_sync`; remove `serverpod_offline_sync*` from `wonky_server/pubspec.yaml`, `wonky_client`, root `pubspec.yaml`/overrides; `config/generator.yaml` loses the module, `databaseSync` and (if empty) `shared_packages` |
| Kit | Delete `packages/wonky_sync_kit` (after its re-exports are gone) and `packages/wonky_sync_kit_flutter` |
| Spaces | Delete `platform/spaces/*`, `SpaceSubscription`, `SpaceReservation`, `SpaceKind`, `SubscriptionReason`, `SubscribeResult`, `SpaceStats`, receipts, `SheetsMergedSignal`; meta `maxActiveSpacesPerUser` |
| `wonky_sync_models` | Drop the Serverpod dependencies and generated code; keep `ids` and `enums` (pure; optional rename deferred) |
| Client migrations | Removed through the generator once no client tables remain (02 §2.3) |
| CI | Remove the engine from the test matrix; add `wonky_revlog`, `wonky_revlog_flutter` |
| Docs | `AGENTS.md` (package table: remove the sync kit; add the revlog packages), `TODO.md` (remove engine items U1–U12, OS-*, the kit follow-ups; add RevLog follow-ups: Slides text OT), `third_party/README` |

## 3. Totals and critical path

| PR | Estimate | Lands on |
|----|----------|----------|
| R0 | 1.5 w | — / tests on main |
| R1 | 2.5 w | main |
| R2 | 0.5 w | main |
| R3 | 3.5 w | revlog/sheets |
| R4 | 3.25 w | revlog/sheets |
| R5 | 4.25 w | revlog/sheets |
| R6 | 1 w | main (G2) |
| R7 | 5 w | main (G3) |
| R8 | 1 w | main |
| **Total** | **≈ 22.5 w** (+ 10–15 % contingency; protection enforcement adds ≈ 1.5 w) | |

**Parallelism.**

- R1 ∥ R2.
- R3 → (R4 ∥ R5): R5 can start against `FakeRevServer` once 04 (protocol) is frozen in R3.
- R7's server part can start after R4.

**Critical path:** R0 → R1 → R3 → R5 → R6 → R7 → R8 ≈ 17.75 w.
