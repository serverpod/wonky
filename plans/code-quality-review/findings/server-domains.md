# Server domain review: Write OT, Sheets, Slides, AI, jobs, tests

Scope: `wonky_server/lib/src/{write,sheets,slides}`, `platform/ai`, `platform/jobs`, the FutureCalls, and `wonky_server/test`. This was a read-only review and no files were changed. All paths below are relative to `wonky_server/lib/src/` unless they say otherwise. Line numbers are as of 2026-10-17.

Severity: **High** means data loss, an unbounded leak, or a stuck user session in normal use. **Med** means a real risk under load, with big files, or with several instances. **Low** means hygiene, or a problem that only shows at the edges.
Effort: **S** is under half a day, **M** is 1–3 days, **L** is more than 3 days.

---

## 1. Write OT server (`write/ot/`, `DocumentEndpoint.connect`)

### W1. One unexpected error permanently wedges a document connection (High · correctness)
- **Evidence:** `write/ot/document_connection.dart:168-172` chains every client message as `_queue = _queue.then((_) => _handle(m))` (the same at `:364`). `_handle` catches only `WonkyException` (`:468`), and `_submit` catches only `OpRejection` (`:492`). In Dart, once a future in the chain fails, every later `.then` skips its callback and passes the error on. So after the first `DatabaseException`, Redis error, `StateError` or similar, the rest of that connection's messages (ops, pings, cursor updates, role rechecks) are **silently dropped**. The error also surfaces as an unhandled async error.
- **Concrete trigger:** the idempotency check in `write/ot/ot_service.dart:64-75` runs *outside* the lock and the transaction. When a client reconnects and resends, two instances (or two sockets) can submit the same `clientOpId` at the same time. Both pass the check, and the second insert breaks the unique index `document_op_client_idx` (`write/models/document_op.spy.yaml`). That raises a `DatabaseException`, not an `OpRejection`, which wedges the connection.
- **Why it matters:** the editor looks connected, but nothing gets acknowledged, and the client keeps buffering its pending ops forever.
- **Fix:**
  - Chain with `.then(...).catchError(...)`, or run `_handle` inside a catch-all that logs the error, sends `DocOpRejected(code: internal)` for a submit, and closes the stream on unrecoverable errors.
  - In `OtService.submit`, catch a unique violation on `clientOpId` inside the lock, re-read the existing row, and return `CommittedOp(duplicate: true)`.
- **Effort:** S

### W2. Side effects run inside the per-document lock before the Ack (Med–High · performance)
- **Evidence:** `write/ot/ot_service.dart:101` (`state.lock(...)`). After the commit, `_afterCommit` is awaited **inside** the lock (`:262-273`), and the Ack is only sent after it returns (`document_connection.dart:491`). For every op, `_afterCommit` does:
  - `ActivityService.logEdit`: 1 select plus 1 insert or update (`platform/activity/activity_service.dart:46-90`).
  - `VersionService.recordEdit`: 1–2 selects plus 1 update, with no throttling (`platform/versions/version_service.dart:82-125`).
  - `DriveService.recordEdit`, once a minute per user.
  - `touchModified` every 10 s: a `DriveItem` update, a `findById` and a `DriveEvents.notify`. Every 30 s it also writes `searchText` (`DeltaUtils.text` of a document up to 2M characters) and a storage size.
  - `OverlayLifecycle.handle`.
  - A snapshot every 500 ops (JSON-encode plus gzip of the whole document).
- **Why it matters:** each keystroke op costs about 5–8 extra serial database round trips while every other editor of the document waits on the lock. Ack latency becomes "transaction plus side effects" and per-document throughput drops by about 3×. A slow activity or versions query stalls collaborative typing.
- **Fix:** send the Ack (and post to the bus) right after the commit and the in-memory update. Move the side effects to a per-`DocumentState` debounced flusher outside the lock: collect inserted/deleted counters and editor ids in memory, and flush activity and version state every few seconds and on dispose. Throttle `VersionService.recordEdit` the same way as `lastUserEdit`. Write the snapshot outside the lock (from the immutable `after` delta).
- **Effort:** M

### W3. `DocumentState` leaks: headless and server paths never release, and a close/start race (Med · resource leak)
- **Evidence:**
  - `DocumentCache.of` puts every loaded state into `_states` (`write/ot/document_cache.dart:155-188`). Only `release()` schedules disposal (`:197-205`), and only `DocumentConnection` calls `retain`/`release`.
  - `OtService.submit`, `submitServerChange` (`write/ot/ot_service.dart:100, 381`, used for restores) and `HeadlessDocumentEditor.head` (`write/mcp/headless_editor.dart:121`, used for MCP and AI) load states that are **never disposed**.
  - `DocumentCache.evict` is never called in `lib/`, so deleted documents stay in the cache too.
  - The race: `_start` awaits several things before `DocumentCache.retain(_state)` (`document_connection.dart:96-105`). If the client cancels during that window, `_close` runs first. Its `release(_state)` throws `LateInitializationError`, which is swallowed (`:513-517`). Then `_start` carries on: it retains (the count never goes back down), adds the bus listener, and in a cluster starts `Timer.periodic` heartbeats (`:175`) that are never cancelled.
- **Why it matters:** each leaked state holds the whole document (up to 2M characters) plus 1,000 recent deltas and an `OverlayIndex`, for the life of the process. AI and MCP use touches many documents.
- **Fix:**
  - When `of()` loads a state, start the dispose timer if `connections == 0`, and refresh a `lastUsed` timestamp on every `lock()`.
  - Call `evict` when a document is purged.
  - In `_start`, check `_closed` after every await and register `addWillCloseListener` first.
- **Effort:** S

### W4. No size or complexity cap on incoming ops (Med · robustness/performance)
- **Evidence:** `write/ot/ot_service.dart:82-98` decodes `deltaJson` of any size and component count. `WonkyOt.rebaseOnServer` (`:152`) transforms it against up to 1,000 cached ops while **holding the lock**. Only the resulting document length is checked (`:189-202`, 2M characters). `maxRequestSize: 524288` (`config/*.yaml`) covers HTTP calls; whether it also limits streaming (WebSocket) messages needs checking.
- **Why it matters:** one op with hundreds of thousands of tiny retain/insert components costs O(components × ops) CPU under the lock and blocks the document for every editor.
- **Fix:** reject ops whose `deltaJson` exceeds a byte cap (for example 1 MB) or whose component count exceeds a cap (for example 20k) before decoding, with `tooLarge`. Do the same in `HeadlessDocumentEditor.mutate`.
- **Effort:** S

### W5. Write snapshots are never deleted (Med · storage growth)
- **Evidence:** `write/versions/write_version_provider.dart:58-61` says snapshots "are shared with the op log and pruned with it". But `DocumentService.pruneOps` (`write/ot/document_service.dart:285-309`) deletes **ops only** and *adds* a snapshot each time. Snapshots are written every 500 ops (`ot_service.dart:292`), on every version capture (`write_version_provider.dart:24`), and on every prune. Thinning versions (`VersionService.thin`) calls `discard`, which does nothing for Write.
- **Why it matters:** `document_snapshot` grows without bound: one full document per idle-period capture, kept forever.
- **Fix:** in the daily prune, delete snapshots that are older than the op retention, except the newest one at or below the oldest kept op and those whose revision is referenced by an `ItemVersion`. Make `discard` delete the snapshot of a thinned version when no other version references it.
- **Effort:** M

### W6. `pruneOps` does not scale (Med · performance)
- **Evidence:** `write/ot/document_service.dart:287-293` runs `SELECT documentId, max(revision) ... WHERE createdAt < @cutoff GROUP BY documentId LIMIT 500` with no index on `createdAt` (the indexes are `(documentId, revision)` and `(documentId, clientOpId)`). That is a full scan of `document_op` every day. It handles at most 500 documents per day, each with a full `contentAt` replay, so a backlog can build up.
- **Fix:** add an index on `(createdAt)` (or `(documentId, createdAt)`). Loop in batches under a time budget instead of a fixed `LIMIT` once a day.
- **Effort:** S

### W7. Expensive requests a client can trigger (Low · performance)
- `DocHashCheck` for a non-head revision materializes `contentAt` (snapshot decode plus up to 499 composes) (`document_connection.dart:454-466`).
- Every `DocCursorUpdate` does `ensureAtLeast` and a bus post with no server-side throttle (`:405-430`).
- **Fix:** answer hash checks only for revisions in the `recent` cache, and rate-limit cursor updates per session (for example 20/s).
- **Effort:** S

---

## 2. Sheets server (`sheets/`)

### S1. Lock timeouts break mutual exclusion in `withWriteLock` (Med · correctness)
- **Evidence:** `sheets/headless/headless_workbook_provider.dart:135-159`; the same code is in `slides/headless/headless_deck_cache.dart:180-205`. Each caller installs its own future and waits on the previous one with `.timeout(30 s)`. When B times out, its `finally` completes B's future even though A is still running. Then C, which was queued behind B, starts **while A still holds the lock**.
- **Why it matters:** two concurrent planners write against the same cached model. The result is lost or duplicated row changes, and write-through applied to a model mid-plan.
- **Fix:** when a waiter times out, complete its own future only after its predecessor completes (`previous.whenComplete(done.complete)`). Alternatively, keep a FIFO of completers and remove the timed-out waiter from the chain.
- **Effort:** S

### S2. Evicting a cache entry disposes engines that are still in use (Med · correctness)
- **Evidence:** `_drop` calls `wb.dispose()`, which disposes the engine and binding (`headless_workbook_provider.dart:368-379`). It is called from `_evictIdle` and `_enforceBudget` (on any other space's `open`) and after a failed patch. Long holders keep the `HeadlessWorkbook` across many awaits: import jobs hold `wb` and `wb.hooks`/`wb.engine` through the whole import (`sheets/imports/sheets_import_jobs.dart:428-540`), and MCP writes and AI runs do the same. With `maxEntries = 50`, a burst of opens can evict a workbook that is in use.
- **Fix:** reference-count leases (`open` returns a lease; dispose only when evicted *and* the lease count is 0), or defer `dispose` until the last user releases it.
- **Effort:** M

### S3. The headless patch query scans the whole space (Med · performance)
- **Evidence:** `headless_workbook_provider.dart:207-226` (and the copy in `headless_deck_cache.dart:247-266`). `age(r.xmin) <= age(xid) OR EXISTS(fields ...) OR EXISTS(tombstone ...)` cannot use an index, so it reads every row of the space plus correlated subqueries. It runs on the next `open` after **every** merge signal and at least every 60 s. Two concurrent `open`s of a stale entry both patch the same model at once (`:81-91`, nothing coalesces them).
- **Why it matters:** with a 1M-cell spreadsheet under active collaboration, every MCP or AI call pays for a full-space scan.
- **Fix:**
  - Coalesce patches per entry (store a `Future` of the patch in progress).
  - Narrow the scan with what the merge signal already carries (HLC), for example via an indexed sync version or HLC column on `crdt_data_rows`/fields if the offline-sync engine has one.
  - Or patch from the `change_log` rows since the last patch.
- **Effort:** M–L

### S4. Import lease expires during long phases, so jobs run twice or get marked failed (Med · correctness)
- **Evidence:** `leaseDuration = 2 min` (`sheets/imports/sheets_import_jobs.dart:39`) is renewed only by `_update` per written chunk (`:286-311`). Reading the file, parsing (`:420-435`, big XLSX files) and uploading images (`:477-490`) do not renew it. Meanwhile `watch`/`progress` call `_expireLease` (`:622-641`), which marks the job failed **and kicks the next job of the same user** while the first is still running. Later the first job's `_finish` (`:330-343`) overwrites the status with `done`.
- **Fix:** run a lease heartbeat (a `Timer.periodic`) for the whole of `_execute`. Make `_update`/`_finish` conditional on `leaseOwner = me` (`UPDATE ... WHERE id=@id AND "leaseOwner"=@me`) and abort when the lease has been lost.
- **Effort:** S

### S5. Big imports keep every row change in memory (Med · memory)
- **Evidence:** `applied` collects every `RowChange` of the whole import (`sheets_import_jobs.dart:492, 521`), with before-values, for the revert and the record. `SheetsChangeRecords.store` then builds the inverse list, JSON, gzip, base64 and the utf8 bytes for both inverse and forward (`sheets/mcp/sheets_bulk_writer.dart:432-467`). That is about 4–6 copies. This contradicts the comment that chunked planning "never holds every row change at once" (`:453-456`).
- **Fix:** append each chunk's applied changes to a gzip NDJSON temporary stored file (inverse and forward). Revert by streaming that file backwards, and store the `ServerChangeRecord` pointing at the files.
- **Effort:** M

### S6. `SheetsBulkWriter.applyRecorded` is not atomic and reads stale before-values (Med · correctness)
- **Evidence:** `apply` commits each 5,000-change chunk in its own `transactionForUser` (`sheets/mcp/sheets_bulk_writer.dart:161-376`), and `applyRecorded` stores the change record only after all chunks succeed (`:79-96`). If chunk k fails, chunks 1 to k-1 stay written with **no revert record**. Version restores of big sheets use this path (`sheets/versions/sheets_version_provider.dart:244-260`). The "current" rows are also read **before** the transaction opens (`:171-179`), so `before` values, and the choice between insert and update, can be stale against a concurrent client merge.
- **Fix:** on failure, revert what was applied (as the import does), or store the record incrementally. Read the current rows inside the transaction.
- **Effort:** M

### S7. The change-log consumer makes hundreds of serial queries per change (Med–High · performance)
- **Evidence:** `sheets/changelog/change_log_consumer.dart:177-219`. Per `ChangeLog` row:
  - a profile lookup;
  - `logEdit` (2 queries), `VersionService.recordEdit` (2–3) and `DriveService.recordEdit` (2);
  - `_mirrorTitle`, which reads the `Spreadsheet` and `DriveItem` **on every change** (`:282-300`);
  - `_history`, which runs **2 statements per cell, serially** (insert and trim; up to 200 cells, so 400 round trips) (`:378-419`);
  - `_orphans`, which loads every comment thread of the item whenever rows, columns or sheets were deleted (`:439-442`).
  Finding new rows anti-joins **every** `change_log` row of the space from the last 30 days against the receipts on each pass (`:90-106`). Its join is on `spaceId`; the declared index is `(spreadsheetId, at)`.
- **Fix:**
  - Batch per pass: aggregate activity and version counters per actor once per pass.
  - Write history with one multi-row `INSERT ... SELECT unnest(...) ON CONFLICT DO NOTHING` and trim with one `DELETE ... WHERE id IN (SELECT ... row_number() OVER (PARTITION BY cell) > 100)`.
  - Mirror the title only when the summary touched the spreadsheet row.
  - Keep a per-space processed watermark instead of the anti-join.
- **Effort:** M

### S8. Change-log pruning can stop for good (Med · correctness/maintenance)
- **Evidence:** `pruneOld` (`change_log_consumer.dart:477-525`) fetches 2,000 old rows **unordered** and skips spaces whose item or owner is missing, or whose owner is not `readWrite` (`:500, 505`). Skipped rows come back the next day. Once there are 2,000 or more of them, nothing else is ever pruned.
- **Fix:** exclude the skipped spaces in the query, order by `at`, delete orphaned spaces' rows through an admin transaction, and loop under a time budget.
- **Effort:** S

### S9. Version capture is too heavy for big sheets (Med · memory/CPU)
- **Evidence:** `capture` (`sheets/versions/sheets_version_provider.dart:147-165`) reads the whole space into maps (`readSpace :51-98`), builds one NDJSON `StringBuffer`, then utf8 bytes, then gzip: 3–4 full copies. `afterCapture` (`:168-201`) **downloads and decodes the snapshot it just wrote** only to count rows, and `countFor` is O(sheets × rows). `captureDue` runs up to 200 captures in series every minute (`platform/versions/version_service.dart:389-415`).
- **Fix:** encode as a stream (write lines into a `GZipEncoder` chunked sink per 5k-row chunk), compute the per-sheet counts during capture, and pass them to `afterCapture`. Reuse the warm `HeadlessWorkbook` when it is cached.
- **Effort:** M

### S10. Version capture overlaps itself and loses dirty state (Med · correctness)
- **Evidence:** `wonky.captureVersions` runs every minute (`server.dart:212-215`) with no lock. Serverpod schedules the next cron run before the current one executes (`server.dart:247-248`), so a run longer than a minute overlaps the next and captures the same dirty items twice. `VersionService.capture` (`version_service.dart:139-171`) reads `ItemVersionState` *after* the slow provider capture, then writes the whole row with `dirtySince: null, editorsSinceLastVersion: []`. Edits recorded during the capture, which Write records **per op**, are lost from dirty tracking, and `lastEditAt` is reverted.
- **Fix:** claim items first (`UPDATE item_version_state SET "capturingSince"=now WHERE ... RETURNING`) or wrap in `Cluster.withLock`. Clear the dirty flag with a conditional update (`WHERE "lastEditAt" = @seen`).
- **Effort:** S–M

### S11. The script scheduler tick scales with the total number of triggers (Low–Med · performance)
- **Evidence:** `sheets/scripts/script_triggers.dart:133-206` loads **every** time-driven trigger and **every** `ScriptTriggerState` each minute, and fetches the `Spreadsheet` for each trigger whose schedule changed.
- **Fix:** select only the states whose `nextRunAt <= now` (add an index), and sync schedule changes from the change-log plugin instead of on each tick.
- **Effort:** M

### S12. Script job claim limits race across instances (Low · correctness)
- **Evidence:** `sheets/scripts/script_jobs.dart:245-268`. The per-user count and the "no running job for this trigger" checks are subqueries that the claim does not lock, so two instances can both pass them. The `_pumping` flag (`:197, 213-236`) can leave a newly queued job waiting until the next tick. A crash after `runTrigger` but before the final `updateRow` re-runs the job after the lease ends, so scripts with side effects (UrlFetch, writes) run twice.
- **Fix:** take `pg_try_advisory_xact_lock(hash(runAsUserId))` or `hash(triggerId)` in the claim, and re-check the queue after `_pumping = false`.
- **Effort:** S

### S13. Suggest-mode shadows copy whole models outside the cache budget (Med · memory)
- **Evidence:**
  - `SheetsShadow.of` builds **two** full `WorkbookModel` copies, `wb` and `base` (`sheets/mcp/sheets_shadow.dart:48-73`). Each lives up to 30 min (`:100`) and is not counted in the 2 GB headless budget.
  - Slides `DeckSteps` copies the whole deck for **every** write call, even one with a single step (`slides/headless/headless_deck.dart:274-278`).
- **Fix:**
  - Build `base` lazily from the `columnsBefore` of the recorded `RowChange`s (before/after previews only need the touched rows).
  - Make the shadow copy-on-write, or at least count it in the budget.
  - In `DeckSteps`, plan directly against the cached model when there is a single step, and copy only for multi-step writes.
- **Effort:** M

### S14. `AI()` cell evaluation runs one model call at a time (Low · performance)
- **Evidence:** `sheets/ai/sheets_ai_service.dart:1049-1107` makes one model call per uncached cell, in series, inside one unary request. The budget is checked once. It uses `DateTime.now()` (`:1023, 1080`) instead of `clock`.
- **Fix:** bounded parallelism (like `fillParallel`), a budget check per batch, and `clock.now()`.
- **Effort:** S

---

## 3. Slides server (`slides/`)

### SL1. PDF export runs on the server isolate and its timeout does not stop it (Med–High · performance)
- **Evidence:** `slides/exports/slides_export_service.dart:157-184` runs the CPU-bound `SlidesPdfExporter.render` on the main isolate. `.timeout(120 s)` only abandons the future; the render keeps going, and `finally` (`:215-217`) frees the user's slot, so more exports can start. The concurrency cap is per user **per instance** (`:34, 144-148`), and there is no global cap.
- **Why it matters:** a few large exports starve the event loop that also serves OT, sync and presenting (presenting targets 300 ms p95).
- **Fix:** render in `Isolate.run` or a small worker pool behind a global semaphore, with a cancel flag checked between pages (and on stream cancel in `exportWithProgress`).
- **Effort:** M

### SL2. Export cache and hash costs (Low · performance/memory)
- **Evidence:** the cache key hashes `jsonEncode(model.dump())` of the whole deck on every request, including cache hits (`:112-121`). `_results` is only pruned on lookup, so it grows without bound (`:48, 225-230`). `ServerSlideImageResolver._cache` keeps every image's bytes for the whole export (`:369-376`).
- **Fix:** key on the deck's sync version or watermark, add an LRU cap to `_results`, and drop image bytes once a page is drawn.
- **Effort:** S

### SL3. Presenter connection lifecycle (Low · resources)
- **Evidence:** `slides/present/presentation_service.dart`.
  - Busy-polling loops with 10–20 ms `Future.delayed` (`:133-136, 224-227, 536-545`).
  - `addWillCloseListener` is registered only after all the awaits (`:395`). A cancel during `_start` runs `_leave`, and `_start` then still calls `_listen()` and `addListener(_deckCh)` (`:403-447, 466`). These are bounded by the session's lifetime.
  - `_resolves` (`:74`) is never pruned per user.
- **Fix:** use completers with timeouts, check `_closed` after each await in `_start`, and prune `_resolves`.
- **Effort:** S

### SL4. `HeadlessDeckCache` copies `HeadlessWorkbookProvider` (Low · maintainability)
- **Evidence:** about 250 near-identical lines between the two files: lock, patch SQL, `_listen`/`_drop`, budget, `readSpace`, `_snapshotXmin`. The copy includes the S1 lock bug. `SheetsVersionProvider.readSpace` (`:51-98`) is a third verbatim copy of `HeadlessWorkbookProvider.readSpace` (`:298-342`). In both caches, idle entries are evicted only on `open`.
- **Fix:** extract `HeadlessSpaceCache<M>` with hooks for loading from rows, applying, estimating and disposing, plus one shared `readSpace`.
- **Effort:** M

---

## 4. AI services

### A1. Duplicated scaffolding across 5 services (Med · maintainability)
| Pattern | Copies | Files |
|---|---|---|
| Availability check, `backendFor`, null → `unavailable` | 4 (+1 in the assistant) | inline_ai, proofread, sheets_ai, slides_ai |
| `acquire`, `send`, `AiUsageService.record`, refusal → `WonkyException`, `AiApiException` → `AssistantErrors` | 6 | assistant, inline_ai, proofread, sheets_ai (`_send` :114-154), slides_ai (`_send` :121-161) |
| `AiCancelToken` + `StreamController.onCancel` + background `createSession` + `catchError`/`whenComplete(release, close)` | 5 | assistant :152-202, inline_ai :80-168, proofread :114-225, sheets_ai explain :523-590, slides_ai :623-700 |
| `McpToolException` → `WonkyException` `_guard` | 6 | sheets_ai, slides_ai, drive/sheets/slides/write `*_mcp_content` |
| `requireAvailable` then `requireBudget` again | 3 | sheets_ai :59-60, slides_ai :77-78, sheets AI() :1041-1042 |

That is roughly 450–550 lines of near-identical code.

**Proposed abstraction** (`platform/ai/ai_call.dart`):
```dart
final class AiCall {
  /// Availability + budget (one usage query), backend, quality; throws WonkyException.
  static Future<AiCall> open(Session s, Actor a, {required String feature});
  final AiBackend backend; final AiQuality quality;
  /// acquire/release, record usage, refusal + API errors mapped to AiFailure.
  Future<AiResponse> send(AiRequest r, {AiCancelToken? cancel, void Function(String)? onText});
  /// Background run with cancellation wired to the stream; errors mapped via onFailure.
  Stream<E> stream<E>(Future<void> Function(AiCall c, Session bg, void Function(E) emit, AiCancelToken cancel) body,
                      {required E Function(AiFailure f) onFailure});
}
/// platform/mcp: one McpToolException -> WonkyException mapper used by every _guard.
```
Inline AI, proofread, Sheets explain and Slides streams become about 20 lines each. The assistant loop keeps its own loop logic but uses `AiCall.send`.

- **Effort:** M

### A2. Suggest-mode state leaks when a run fails (Med · resource leak)
- **Evidence:** `_Loop.execute` calls `target.beginRun` (`platform/ai/assistant_service.dart:557-562`) and `target.endRun` (`:727-735`) with no `try/finally`. Any exception in between skips `endRun`, for example from `_persistAssistant`, `_appendToolResults`, a database error or `AiKeys`. The result:
  - `SlidesShadows._byRun` and `DeckOverlays._all` keep the entry forever (`slides/ai/slides_shadow.dart:88-113`, no expiry).
  - `SheetsShadows._byGroup` keeps a run that `end()` never moved to preview (two workbook copies, see S13).
  - The `ui.*` bus listener (`:737-742`) is never removed.
- **Fix:** wrap the loop in `try/finally`, and in `finally` call `endRun` with an aborted flag and remove the listener.
- **Effort:** S

### A3. Gaps in token and cost limits (Med · cost control)
- **Evidence:**
  - The budget is checked only *before* each round (`assistant_service.dart:571`). One round can use `maxTokens: 64000` of output (`llm/ai_client.dart:66`) plus a large input, and there is no cap per run.
  - Proofread and inline AI check only at the start (`write/ai/proofread_service.dart:97`, `inline_ai_service.dart:56`); proofread then sends every section.
  - The text fields of `InlineAiRequest` (`contextBefore`, `selectedMarkdown`, `contextAfter`, `instruction`, `previousOutput`) are put into the prompt **with no length cap** (`write/ai/inline_ai_service.dart:191-210`).
  - `usedToday` loads all of today's rows and sums them in Dart (`platform/ai/ai_usage_service.dart:74-88`). It runs 2–3 times per request (`status` :128, `requireBudget` :176-185, and the services' extra `requireBudget`).
- **Fix:** cap input fields on the server (for example 50k characters each). Add a token cap per run and per proofread with a check between sections. Compute usage once with `SELECT sum(...)`. Optionally reserve an estimated budget before a call.
- **Effort:** S–M

### A4. Concurrency slots can leak (Low–Med · correctness)
- **Evidence:** `acquire` is called before code that can throw and is not covered by the `whenComplete(release)`:
  - inline AI: `build(...)` (`inline_ai_service.dart:72-79`);
  - proofread: `split(...)` (`proofread_service.dart:112-113`);
  - assistant: `AiUsageService.quality` (`assistant_service.dart:145-154`).
  A throw there takes one of the user's `maxConcurrentRequests` slots on that instance for good. The assistant also creates the thread row before the busy checks (`:128-145`), so a busy error leaves an empty thread behind.
- **Fix:** acquire as the last step before `unawaited(body())`, or guard it with `try/catch` and release on error. Create the thread after `acquire`.
- **Effort:** S

### A5. `ai_usage` is never purged (Low · storage)
- **Evidence:** `AiUsageService.purge` (`ai_usage_service.dart:117-121`) says "called with the daily job", but `MaintenanceFutureCall.daily` (`platform/jobs/maintenance_future_call.dart:59-116`) never calls it.
- **Fix:** add it to `daily`.
- **Effort:** S

### A6. Concurrency limits are per instance (Low)
- **Evidence:** `ai_usage_service.dart:189-214` and the assistant's "busy thread" check (`assistant_service.dart:140-143`). With N instances a user gets N× the limit.
- **Fix:** a Redis counter or advisory lock when the server is distributed.
- **Effort:** S–M

---

## 5. FutureCalls and recurring jobs

### F1. Job wrappers catch only `Exception`, so one `Error` aborts the whole daily chain (Med · reliability)
- **Evidence:** `MaintenanceFutureCall._run` uses `on Exception` (`platform/jobs/maintenance_future_call.dart:29`). `daily()` runs 12 jobs in sequence (`:59-116`), so a `StateError`, `TypeError`, `RangeError` or `LateInitializationError` in, say, `purgeExpiredTrash` skips all the later prunes. The same narrow catch is in `ScriptSchedulerFutureCall`, `StorageFutureCall`, `BoardFutureCall`, `FilePreviewFutureCall`, `NotificationEmailFutureCall` and `ChangeLogConsumer._consume` (`:212`). In the consumer the receipt is never completed, so the same row is retried every 10 minutes forever (a poison row).
- **Fix:** catch `Object` in `_run`, log the duration of each job, and give each job a time budget. In the consumer, complete the receipt with an error flag after N attempts.
- **Effort:** S

### F2. `VersionService.thin` is unbounded (Low–Med · performance)
- **Evidence:** `platform/versions/version_service.dart:420-446` loads every non-named version older than 7 days, across all items, every day.
- **Fix:** page through items, or only look at versions created since the last thinning boundary.
- **Effort:** S

### F3. Digest and immediate emails (Low · correctness)
- **Evidence:** `platform/notifications/notification_service.dart:322-372`. Unread notifications of kinds not set to email are never marked, so they are re-read every 15 minutes, and with `limit: 5000` ordered by `userId` they can starve later users. A digest can also pick up a notification before `sendImmediate` marks it, which sends it twice (`:284-314`).
- **Fix:** filter by channel in SQL, or mark such notifications `skipped`. Claim rows with `UPDATE ... RETURNING` before sending.
- **Effort:** S

### F4. No sweeper for work that is left stranded (Low · reliability)
- **Evidence:**
  - Queued import jobs only start from `importInto`, `watch` or `_expireLease` (`sheets_import_jobs.dart:138, 170, 639`).
  - Stale change-log claims are retried only on the next merge for that space (`sheets/sync/sheets_sync_service.dart:60`).
  - Script jobs queued on a non-worker instance wait for the minute tick (this one is fine).
- **Fix:** add a 10-minute sweep (like `wonky.boardSweep`) that kicks queued imports and reprocesses spaces with stale claims.
- **Effort:** S

Also related: S10 (capture overlap) and W6, S8 (prune stalls).

---

## 6. Test coverage map (`wonky_server/test`, 112 test files)

| Feature folder | Tests | Notes |
|---|---|---|
| platform/activity | integration/platform/activity_endpoint_test | ✓ |
| platform/ai | integration ai_provider_key, assistant; unit ai/* (5) | budget limits during a run not tested |
| platform/board | test/platform/board/** (23) | well covered |
| platform/cluster | cluster_test, cluster_bus_test | ✓ |
| platform/comments | comment_endpoint_test | ✓ |
| platform/drive, files, storage | drive_* (5), file_* (3), storage (2), unit files (4) | ✓ |
| platform/jobs | MaintenanceFutureCall referenced once | **`scheduleRecurringJobs`, `VersionService.thin`, `DocumentService.pruneOps` untested** |
| platform/mcp | 6 integration + 5 unit | ✓ |
| platform/notifications | notification_email_test, unit | ✓ |
| platform/presence, sharing, users, meta | one test each | `SharingService.removeExpiredGrants` has no direct test |
| platform/spaces | space_kinds_test, evictInactive | ✓ |
| write/ot | document_endpoint_test, multi_instance_test | no tests for `rebaseTooOld`, the wedge/error path (W1), cache disposal or op pruning |
| write/ai | inline_ai_test (proofread covered) | ✓ |
| write/export, themes, versions, mcp | export_import, theme_endpoint, versions, write_tools (2) | `ThemeService.purgeDeleted`, `WriteHistoryService.purgeDiffCache` untested |
| write/collab | OverlayLifecycle referenced once | thin |
| sheets/ai, endpoints, exports, headless, imports, mcp, scripts, sync, versions | 26 files | good; includes server_writer_perf and bulk_writer |
| sheets/changelog | ChangeLogConsumer in 2 files | pruning stall (S8) not tested |
| sheets/images | — | **`SheetsImageProxy` untested** |
| sheets/spaces | create_defaults; copy via drive.copy in sheets_sync_test | `SpaceCopier` only indirectly |
| slides/* | 16 files (present, charts, comments, export, headless, sync, templates, themes, versions, ai, mcp) | good |
| headless caches | headless_cache_test, slides_headless_test | **`withWriteLock` contention and timeouts untested in both caches (S1)** |

The most important untested services are:
1. Op and snapshot retention (`pruneOps`, W5/W6).
2. `scheduleRecurringJobs` and the daily chain (F1).
3. `VersionService.thin` and capture concurrency (S10).
4. Lock timeouts in the write lock (S1).
5. OT error and duplicate paths (W1).
6. `SheetsImageProxy`.
7. Theme and diff-cache purges.
8. Budget enforcement during a run (A3).

---

## 7. Done well
- **OT design:** `SELECT ... FOR UPDATE` on the document row is the authority across instances. Ops are idempotent through a unique `clientOpId`. A 1,000-op memory window catches up from the op log, and `ensureAtLeast` coalesces catch-ups. Server ops win ties. The result is normalized and validated before commit, and a shape validator restricts commenters. Inverses are stored with each op.
- **Several instances:** participant heartbeats with expiry, bus coalesce keys for cursor and heartbeat messages, editor limits re-checked once the roster settles, a `multi_instance_test`.
- **Headless caches:** LRU with a memory budget, patches driven by an xmin watermark, write-through of the instance's own writes with their signals ignored, coalesced loads.
- **Job queues:** claims with `FOR UPDATE SKIP LOCKED` and leases, `maxAttempts`, overflow coalescing per trigger. The import pipeline is chunked, can be cancelled and reverts on failure. Change-log rows are processed exactly once through unique receipts that can be reclaimed when stale.
- **Recurring jobs:** scheduling is idempotent under a cluster lock and repairs changed or duplicated cron chains.
- **AI:** one provider-agnostic client, cancellation tied to stream cancel, refusal and max-tokens handled explicitly (cut-off tool calls are answered, never run), tool results capped, a stable prompt prefix for provider caching, a destructive-change guard with user confirmation, and the budget re-checked every round.
- **Exports:** cache keyed by content hash, a timeout, and an SSRF-safe image fetcher.
- **Tests:** strong integration coverage of real flows, including perf tests for the server writer and bulk writer and a headless cache test.
