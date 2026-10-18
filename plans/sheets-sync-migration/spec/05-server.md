# RevLog spec 05 · Server

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

## 1. `RevBinding`

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

## 2. File state (per instance)

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

## 3. Submit

### 3.1 Signature

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

### 3.2 Algorithm

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

### 3.3 Set-based SQL (`rev_sql.dart`)

All statements are generated from `RevSchema` and run with `unsafeQuery`/`unsafeExecute` with
named, explicitly cast parameters, following the repo convention of JSON strings cast to `jsonb`
and `@ids::uuid[]` (inventory write-infra §6).

```sql
-- Prefetch (per table touched by the op): by id only, so foreign ids are detected
SELECT "fileId", <all columns> FROM "cell" WHERE id = ANY(@ids::uuid[]) FOR UPDATE;

-- Parent existence (per parent table), within the file
SELECT id FROM "sheet_row" WHERE "fileId" = @f AND id = ANY(@ids::uuid[]);

-- Cascaded cells of deleted rows / columns that the op didn't list (sheet-scoped, uses cell_row_idx / cell_col_idx)
SELECT id, <all columns> FROM "cell"
 WHERE "sheetId" = @s AND "rowId" = ANY(@deletedRows::uuid[]) AND NOT (id = ANY(@explicit::uuid[]));
-- other child tables: WHERE "<parentFk>" = ANY(@deletedParents::uuid[]) (FK columns; small tables)

-- Deletes (children first)
DELETE FROM "cell" WHERE "fileId" = @f AND id = ANY(@ids::uuid[]);

-- Upserts of final row images (parents first); the WHERE guard makes a foreign-id overwrite impossible
INSERT INTO "cell" AS t (id, "fileId", "revision", "createdAt", "sheetId", "rowId", "columnId", content, …)
SELECT r.id, @f, @rev, r."createdAt", r."sheetId", r."rowId", r."columnId", r.content, …
FROM jsonb_to_recordset(@rows::jsonb) AS r(id uuid, "createdAt" timestamp, "sheetId" uuid, …)
ON CONFLICT (id) DO UPDATE SET "revision" = EXCLUDED."revision", content = EXCLUDED.content, …
WHERE t."fileId" = EXCLUDED."fileId";
-- the affected-row count must equal the number of rows; otherwise roll back with invalidChange
```

- **Full row images are safe.** The file lock serializes every writer of the file's rows, and nothing else writes them after the migration.
- **Runs.** A run is a sequence of consecutive changes to one table; runs over 1,000 rows are split. `jsonb_to_recordset` vs `unnest(@col::type[], …)` is measured in R0.2, and the faster one is kept.
- **Cell deletes rely on the explicit cascade.** `cell.rowId`/`columnId` have no DB FK (02 §2.1), so deleting a `sheet_row` never triggers a scan of `cell`.

### 3.4 Throughput and fairness

- Per-file throughput is bounded by commit latency. A typing user produces at most one op per round trip (06 §4.2).
- Server changes release the file lock between chunks (§8.1), so a 100k-cell import never blocks typing collaborators for more than one chunk.

### 3.5 Protected ranges (Sheets binding; RD-19)

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
*Save my changes as a copy* for the rejected group (06 §4.6). This replaces Sheets 10 §9
"Rejected protected-range edits (advisory)".

## 4. Connection (`RevLogConnection`)

This is lifted from Write's `DocumentConnection` (inventory write-infra §1.2) with these rules:

| Aspect | Rule |
|--------|------|
| Open | `static Stream<RevServerMessage> open(Session, RevBinding, UuidValue fileUuid, int knownRevision, String tabId, Stream<RevClientMessage> input)`: a lazy `StreamController` that starts on listen and closes on cancel |
| Start | (1) Find `rev_file` by uuid (missing or `purging` → `notFound`) and its `DriveItem`; `AccessService.requireRole(viewer)`; `DriveService.recordOpen`. (2) `lease = RevFileStates.retain(state)`; `ensureAtLeast(head)`; for Sheets files with protections and an Editor role, also take a `HeadlessFileCache` lease (§3.5). (3) Register the bus listener for `rev:<fileUuid>`, then post `hello` (roster). (4) Send `RevInit`. (5) Start the input subscription. **After every `await`, check `_closed` and undo whatever is already registered** (CQ-5) |
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

## 5. Bus (`rev_bus.dart`)

| Aspect | Rule |
|--------|------|
| Channel | `rev:<fileUuid>` |
| Message | `RevBusMessage` (`serverOnly: true`). Fields: `type` (op · role · hello · here · beat · left · purged), `revision?`, `opJson?` (the `RevOpView` JSON when its payload is ≤ 64 KiB, else null), `originSessionId?`, `userId?`, `joinedAt?`, `headRevision?` (on `beat`) |
| Large ops | An instance whose ring lacks an op fetches it once from `rev_op` (by revision) and adds it to its ring. Connections on the same instance share it |
| `ClusterBus.post(…, immediate: true)` (new) | Delivers locally at once, as today. For Redis, it **first flushes the outbox's queued messages**, so an immediate message never overtakes older queued ones, then publishes. Used for `op`, `role` and `purged`. Write's `DocumentBus.post` for `op` switches to it in the same PR (R2) |
| Lost messages | Redis publish is best effort (`cluster_bus.dart:156-162`). `beat` messages (every 30 s, only when distributed) and every `RevPong` carry `headRevision`. A client or instance that sees a head beyond its revision gap-fills from `rev_op` |
| Ordering | Not guaranteed across instances. Clients order by revision and fill gaps (06 §4.3), as in Write |

## 6. Post-commit hooks (`rev_hooks.dart`)

### 6.1 Runner

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

### 6.2 Hook catalogue

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

## 7. Bootstrap pages (`rev_pages.dart`)

### 7.1 Structure and rows pages

- **Structure pages** walk the non-cell tables in rank order. Their cursor is `{t: tableIdx, after: id}` (04 §3), and each page is built as **one SQL statement**, so it is one snapshot. A page stops at `structurePageRows` (20,000) rows or 4 MiB compressed, whichever comes first.
- Tables with more than 50,000 rows for the file (per `stats.tables`) are skipped by structure pages and listed in `excludedTables`. They are served as `rows` pages (keyset by id, the same caps); the client may run several in parallel.

```sql
WITH h AS (SELECT "headRevision" AS rev FROM rev_file WHERE id = @f)
SELECT h.rev, x.t, x.j FROM h, (
  (SELECT 0 AS t, row_to_json(s)::text AS j FROM "sheet" s
     WHERE s."fileId" = @f AND s.id > @after0::uuid ORDER BY s.id LIMIT @n0)
  UNION ALL
  (SELECT 1, row_to_json(g)::text FROM "dimension_group" g WHERE g."fileId" = @f … LIMIT @n1)
  UNION ALL …
) x;
```

`row_to_json` output is converted to the page format (04 §3.1); `fileId` and `revision` are
excluded. Coverage: one `tbl:<table>:<from>:<to>` key per table touched by the page.

### 7.2 Cell pages (Sheets)

```sql
WITH h AS (SELECT "headRevision" AS rev FROM rev_file WHERE id = @f)
SELECT h.rev, row_to_json(c)::text FROM h, "cell" c
WHERE c."sheetId" = @s AND c."rowId" = ANY(@rows::uuid[]);       -- @s verified to belong to @f
```

At most `pageRows` (1,000) sheet rows per request, and ≤ 4 MiB. Coverage: `row:<s>:<rowId>`
for every requested row.

### 7.3 Consistency

- **One snapshot per page.** Each page is a single statement and therefore one MVCC snapshot. An op writes its rows and `headRevision` in one transaction, so the snapshot holds exactly the ops ≤ `rev` for every row.
- **Convergence.** Together with the client rule (06 §5.3: apply buffered ops > `Rp` to rows covered by the page; keep ops for uncovered rows), the client converges to the head. Property test: 09 §2.5.

## 8. Server-originated changes

### 8.1 `submitServerChange`

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

### 8.2 Revert and reapply (`ServerChangeRecord`)

- **Record:** `{changeId, fileUuid, recordId, label, actorKind, userId, cellsAffected, expiresAt, revertedAt?, revertChangeId?}`. The ops are those of `rev_op` with that `recordId`.
- **`revert(changeId)`:**
  1. Decode the ops' applied forms. With `before` values, merged inserts are updates (03 §4.7), so reverting never deletes another user's columns.
  2. Invert them in reverse revision order with `UndoInverter.invertChanges(changes, current: headless model)`, using the per-column skip rule. Skipped columns become `RevertResult.skipped`, which drives the partial toast as today.
  3. Submit the result with `record: true` (a new record).
  4. Set `revertedAt`.
- **`reapply`** is the same, using the forward changes.
- **Rule** (aligned for MCP and the endpoints; code-quality slt #11): Editor+, and not already reverted.

### 8.3 File creation, templates, copies, imports

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

## 9. Headless model cache (`HeadlessFileCache<M>`)

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

## 10. Jobs and purge

| Job | Schedule | Does |
|-----|----------|------|
| `revlog.pruneOps` | daily | In batches of 10,000 under a 60 s budget, looping until done: (1) for ops older than `opRetentionDays` that no unexpired `ServerChangeRecord` references, set `payload`/`summaryJson`/`detailJson`/`outcomeJson` to null, and advance `rev_file.prunedBelow` to the first revision still holding a payload; (2) delete slim rows older than `opTombstoneDays` |
| `revlog.hookSweep` | every 5 min | Kicks files whose hook cursors lag the head or whose `nextAttemptAt` is due |
| `revlog.initSweep` | every 5 min | Resumes `createFile` for `initPending` files older than 5 min |
| `revlog.repairStats` | weekly | Recomputes `stats`/`contentCount` for files changed since the last run (sheet by sheet for cells) |
| removed | — | `sheets.pruneChangeLog`, `slides.pruneChangeLog`, `sheets.evictSpaces` |
| changed | — | `sheets.purgeServerChanges` (records only); `drive.purgeTrash` (§10.1); storage reconcile (estimators by `fileId`) |

### 10.1 Purge sequence

`rev_file.item` is `onDelete=Restrict`, so a drive item can't be deleted while its `rev_file`
exists. `DriveService.purge` calls `RevLogService.purgeFile` for spreadsheet/presentation nodes
**before** deleting the items:

1. `UPDATE rev_file SET purging = true`. New connects and submits now get `notFound` / `fileReadOnly`.
2. Post `purged` on the bus. Every instance closes the file's connections with `notFound`, evicts `RevFileStates` and `HeadlessFileCache` entries, and stops hook drains for the file.
3. Wait for the hook lease to expire or be released.
4. Delete in batches: Sheets cells sheet by sheet (50,000 rows per statement), then the other domain tables by `fileId`.
5. Delete `rev_file`, which cascades `rev_op` and `rev_hook_state`.
6. Delete the drive item (the existing purge continues).

Account deletion uses the same path (together with the ownership fix CQ-1).

## 11. Access rules

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

## 12. Observability

- **Per op:** commit duration, change count, payload bytes, prefetch rows, cascade rows, attribution reads, protection check duration and cold model loads, lock wait. Logged at debug; ops slower than 200 ms at warning (`session.log`).
- **Per connection:** open duration, ops sent, gaps filled.
- **Settings › Developer** (suite 04 §4): ops per minute, p95 commit, hook lag (head minus the minimum cursor) per binding.
