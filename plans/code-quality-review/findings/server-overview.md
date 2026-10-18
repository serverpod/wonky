# wonky_server code-quality review: cross-cutting findings

Cross-cutting findings over the whole server. The detailed slices are in
[server-security.md](server-security.md), [server-platform.md](server-platform.md),
[server-mcp-ai-board.md](server-mcp-ai-board.md), [server-write-sheets.md](server-write-sheets.md),
[server-slides-and-tests.md](server-slides-and-tests.md) and [server-domains.md](server-domains.md).
These were separate reviews, so a few findings appear in more than one file.

Scope: wonky_server/lib (excluding generated), bin, config, migrations (skimmed), test. About 78.8k lines in lib/bin, 130 test files (49k lines).

## Findings (prioritised)

### S-1 Drive search: no full-text index, and every page re-does all the work. Med, perf
- Evidence: lib/src/platform/drive/drive_service.dart:348-441. The `to_tsvector('simple', name||description||searchText)` is computed per row inside the query (lines 366-382). No GIN or trigram index exists in any migration (grep `USING gin`/`pg_trgm` finds nothing). The query loads up to `_maxCandidates = 5000` ids (line 49). It then loads all 5000 DriveItems, runs `AccessService.rolesFor` and `DriveViews.build` on all of them (6+ IN-list queries, including every permission row of those items), and only then does `skip(offset).take(pageSize)` (line 435). The offset cursor means page N repeats the whole pipeline.
- Why it matters: search cost grows with corpus size, not with page size, and it runs on every keystroke-debounced search.
- Fix: push the kind/owner/date filters into SQL, then build views only for the page slice. Use a keyset cursor on (rank, modifiedAt, id). Add a GIN index on a stored tsvector, or trigram on name, through a hand-edited migration. Serverpod models cannot express expression indexes, so this needs a documented exception. Effort: M.
- Same pattern (lower volume): board search, lib/src/platform/board/board_search.dart:12-13 and :83-218, is a public signed-out full-text search over title+body with no index.

### S-2 Hand-rolled static caches and maps with no bound or eviction; `session.caches` never used. Med, perf/Serverpod usage
- Evidence: there are 0 uses of `session.caches` in lib. Static maps that only grow:
  - `UserService._profileIdByAuthUser` and `_avatarUrlCache` (lib/src/platform/users/user_service.dart:36-37, 240-252). The avatar cache never expires.
  - `ChangeLogConsumer._lastTouch` (lib/src/sheets/changelog/change_log_consumer.dart:42, 248-259): one entry per spreadsheet ever edited.
  - `ContentSizes._lastRun` (lib/src/platform/storage/content_sizes.dart:217, 247).
  - The Slides twin of `_lastTouch` (lib/src/slides/changelog/deck_drive_mirror.dart).
  - `RateLimiter._calls` (lib/src/platform/common/rate_limiter.dart:58, 104-117). Its cleanup at more than 10,000 keys removes only *empty* lists. Idle keys keep stale timestamps forever because pruning happens only when that same key is hit, so the cleanup barely frees anything.
- Fix: use `session.caches.local` (maxEntries plus lifetime) for profile and avatar lookups, or a small LRU/TTL helper in platform/common. In RateLimiter, drop keys whose newest timestamp is older than the window. Effort: S-M.

### S-3 Sheets and Slides change-log "touch" throttle is copy-pasted. Low-Med, maintainability/correctness
- Evidence: change_log_consumer.dart:240-277 and deck_drive_mirror.dart:90-125 are near-identical. Each has `_lastTouch`/`_trailing` maps, a `Timer` trailing refresh, a detached `createSession`, and nested `catch (_) {}` (the only 4 empty catches in lib).
- Why: two copies drift apart. The in-memory Timer is lost on restart and is per instance (with N instances you get N refreshes per window).
- Fix: extract a shared `ThrottledItemTouch` helper in platform/drive. Consider `futureCalls.callWithDelay` with a fixed identifier instead of a Timer. Effort: S.

### S-4 `UserService.summaries` is N+1 on cold avatars. Low, perf
- Evidence: user_service.dart:203-218 awaits `summaryOf` per profile. That calls `avatarUrl`, which does one `StoredFile` query per uncached avatar (240-246). Avatars that are not ready are never cached, so they are re-queried on every call. It is used by `DriveViews.build` for every listing.
- Fix: batch-load StoredFiles for all `avatarFileId`s in one query. Effort: S.

### S-5 `AccessService.subtree` is quadratic. Low, perf
- Evidence: lib/src/platform/sharing/access_service.dart:188-210. `frontier` is a List, and `children.where((c) => frontier.contains(c.id))` costs O(n²) for large folders. `ancestors` (166-186) does one query per depth level.
- Fix: use a Set for frontier, or a recursive CTE for both. Effort: S.

### S-6 Link role grants access to any signed-in user who knows the item uuid. Low, security/design (by design, but the spec contradicts it)
- Evidence: access_service.dart:118-125 applies `ShareLink.role` to every user. Spec 13 §1 says ids are "never treated as secrets", but with link sharing on, the uuid *is* the secret ("anyone with the link").
- Fix: no code change needed, but align the spec wording and make sure uuids never appear in logs or public board posts (spec 16 strips route ids). Effort: S (docs).

### S-7 Recurring-job table is typed `dynamic`. Low, DX
- Evidence: lib/server.dart:211-226, `Future<void> Function(dynamic recurring)` with `r.maintenance.captureVersions()` and so on. These calls are dynamically dispatched, so a renamed FutureCall compiles fine and fails only at startup.
- Fix: type the parameter with the generated recurring-call builder type. Effort: S.

### S-8 Raw SQL volume. Low, maintainability (security OK)
- Evidence: 66 `unsafeQuery`/`unsafeExecute` calls. All user input goes through `QueryParameters.named`. The only interpolations are enums, ints, constant SQL fragments and internal table and column names (board_search.dart:88-218, board_votes.dart:32 `IN (${ids.join})`, storage_counters.dart:135, content_sizes.dart:90-99, sheets_spaces.dart:96). I found no injection.
- Fix: replace the `IN (${ids.join(', ')})` in board_votes.dart:32 with `= ANY(@ids)`. Keep a lint or review rule that interpolated identifiers come from constants. Effort: S.

### S-9 God files. Low-Med, maintainability
Largest non-generated files: drive_service.dart 2185 (split into listing/search, create/copy, move/trash, templates), script_service.dart 1308, sheets_ai_service.dart 1305 and slides_ai_service.dart 1192 (likely shared run-loop and context code with platform/ai/assistant_service.dart 1073; the duplication is quantified in server-domains.md A1), board_tasks.dart 1214, slides_element_handlers 1081, write_tool_handlers 1052, slides_media_handlers 1020, drive_file_service 999. spec_index.g.dart (2319) is generated data. Effort: M each.

## Things done well (keep)
- AccessService is the single permission source. `require()` returns notFound for users with no access, so ids don't leak. Role lookups are batched (`rolesFor`) and DriveViews.build is batched (no N+1).
- All raw SQL is parameterised. Cluster.withLock correctly uses `pg_advisory_xact_lock` inside a transaction, which is safe with pooled connections.
- The recurring-job reconciler is idempotent and serialised across instances (server.dart:199-256).
- The e2e support endpoint is gated by run mode and an `@example.test` address.
- `meta.getInfo` caches the Redis ping (30 s) so the heartbeat isn't a Redis command per user.
- RateLimiter is Redis-backed with an in-memory fallback.
- Tests: 130 files and no real `Future.delayed` sleeps. A `live-ai` tag is skipped by default.

## Coverage
The authorization/IDOR sweep of all endpoints and streams, MCP, the GitHub webhook, SSRF, the Write
OT server, the job queues, Slides presentations and linked charts, and the test-coverage map are
in the slice files linked at the top.
