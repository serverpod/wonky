# 13 · Security, Privacy and Operations

## 1. Threat model (summary)

| Threat | Mitigation |
|--------|------------|
| Unauthorized document access | All reads/writes through `AccessService`; ids are unguessable UUIDs but never treated as secrets; per-endpoint role tests |
| Privilege escalation via crafted ops (Write) | Server validates every op against schema + role-specific op shapes (Write 03 §5) |
| Tampered sync client (Sheets, Slides) | The RevLog sequencer checks the ACL role on every op and validates every change against the schema and limits (types, foreign ids, immutable columns, sizes; [17](17-revlog-sync.md) part 3 §5) before applying it. Protected ranges are enforced server-side by the same guard as the client (17 part 5 §3.5). Server-side jobs (versions, triggers) treat file content as untrusted input |
| XSS via document content (HTML export, link hrefs) | Markdown/HTML exporters escape; links restricted to `http(s)`, `mailto`, `wonky://`; `javascript:` and `data:` rejected at schema validation |
| SSRF (IMPORTDATA/IMAGE/UrlFetch/image-from-URL) | Server-side fetch proxy: DNS resolution then block private/link-local/metadata ranges, allowlisted ports 80/443, 10 s timeout, 10 MB cap, content-type checks, per-user quotas |
| Script sandbox escape | `dart_eval` default-deny permissions; no FS/process; network only via bridged proxy; isolate/worker kill on timeout; memory caps via value-count limits |
| MCP token theft | Tokens hashed (SHA-256), shown once, scoped, expirable, revocable, `lastUsedAt` displayed; rate limits |
| Prompt injection via document content into AI/MCP | AI tool layer enforces the user's permissions; AI cannot call sharing/permission tools; destructive bulk operations require confirmation; content from documents is placed in user-turn context, never system prompt |
| CSRF / DNS rebinding on `/mcp` | Bearer auth only (the web apps' auth cookie is ignored on `/mcp`), `allowedHosts`/`allowedOrigins` checks |
| Memory/CPU exhaustion through unauthenticated or oversized requests | Header-only checks before any body is read: `/mcp` (enabled, host, origin, bearer format, declared size; 16 MB cap, 09 §2) and the GitHub webhook (enabled, `X-Hub-Signature-256`, GitHub headers, declared size; 5 MB cap, 16 §13.3); per-token MCP limit also for `resources/*` and `prompts/get`; signed-out board searches limited per address and in total, search text capped at 200 chars (16 §11); images for Slides AI refused above 40 MP from the header, decoded off the request isolate; presence cursors ≤ 8 KB and ≤ 20 updates/s per session (07 §1); Sheets `script.notifyOpen` ≤ 10/min per user and spreadsheet and 120/min per spreadsheet |
| Access kept by open streams after it was revoked | Presence streams re-check access on the user's drive signal for the item (ACL changes) and every 5 min (expiring grants) and close with `notFound`; presentation members re-check at most every 5 s while the presenter's state arrives and end with `noAccess` (Slides 10 §6.5) |
| File upload abuse | Type sniffing, size limits (images 20 MB, imports 100 MB, (v2) drive files 50 MB and the per-user quota), image re-encoding for thumbnails, private storage with signed URLs (15 min); (v2) arbitrary uploads: §6 |
| (v2) Uploaded active content (HTML/SVG/JS) executing in the app origin | Never rendered; downloads forced to `attachment` with `nosniff` and `CSP: sandbox` (§6) |
| (v2) Storage/bandwidth abuse through uploads | 50 MB quota per user, reservations, pending-upload cap, upload rate limits (§6) |
| (v2) Second presenting window (Slides, if adopted) | Opens only the audience route of the same deck, same origin, no other content; closed with the presentation (03 §1) |
| Brute-force login | Serverpod IDP rate limiting; generic error messages |
| Test-support endpoint left open (E2E verification codes, 15 §9) | `e2eSupport` refuses every call outside the `development`/`test` run modes and only serves `@example.test` addresses; a server test asserts the refusal in `staging`/`production` |
| (M12) Security vulnerabilities posted on the public board | The dialog points to `security@serverpod.dev` and `SECURITY.md`; Jev's `security` check holds at ≥ 0.5 and lists at ≥ 0.2 for admins ([16 §11](16-bugs-and-improvements.md)) |
| (M12) Personal data in board posts and screenshots | Warnings, the cover tool (opaque, flattened on the device), route ids stripped, Jev's `personal_data` check, author can delete and remove screenshots (16 §5, §11) |
| (M12) Prompt injection into triage, task prompts and PR reviews | Jev returns typed answers only; Gemini gets post and PR text as delimited untrusted data and answers through schemas; task prompts need admin review and sit in a fixed template; PR reviews are advisory and the server never runs PR code (16 §10.2, §13.5) |
| (M12) Forged GitHub webhooks, claim takeover | HMAC-SHA256 check (`githubWebhookSecret`), delivery dedupe, per-claim codes compared in constant time (16 §13.3, §13.7) |
| (M12) Runaway AI spend on the board | Separate daily token budgets for Jev and Gemini, per-PR review limits, per-user rate limits (16 §6.1, §11, §13.5) |
| (M14) Publications: forged contributor links, SSRF through webhook URLs, forged or replayed deliveries, stolen API keys, moderator overreach, submission spam | Links carry only a public publication id and the consent dialog names the verified site host (or the webhook host); outbound calls through the SSRF-safe client; Standard Webhooks signatures with timestamp window and ids; hashed, scoped, rotatable API keys with rate limits; moderators get Commenter only, removed with the submission; per-user limits and blocks ([18 §11](18-publications-and-submissions.md)) |
| Session token theft via XSS (web) | Cookie auth: tokens in an httpOnly, `secure`, `SameSite=lax` cookie shared by both apps; `allowedOrigins` restricts credentialed cross-origin calls (01 §2.5) |

## 2. Privacy
- Data minimization in logs (no document content in logs; ids only).
- (M12) **Bugs & improvements**: posts, comments, task text and screenshots are **public** (readable
  signed out). They are checked by Jev (TypeSafe) and written about by Gemini (Google, paid-tier
  key) on internal keys; the dialog names both. The per-user AI opt-out below does **not** apply
  to board content, because it is public anyway. Details: [16 §6.1, §11](16-bugs-and-improvements.md).
- AI: opt-out per user and per deployment; notice in panel naming the provider. Provider API
  keys (server passwords `openaiApiKey`, `anthropicApiKey`, `geminiApiKey`, and users' own keys
  in `ai_user_key`) are server-side only. A user's own key is accepted only while the server has
  none, used only for that user's requests, never logged and never returned (the client sees the
  provider and the last four characters); the model is `serverOnly`. It is stored **unencrypted**
  in Postgres (there is no encryption helper): database access or a backup exposes it, so
  deployments that must avoid that set `ai.allowUserKeys: false` and configure a server key.
- Account deletion deletes owned items (or transfers on request), script user properties, tokens,
  notifications; anonymizes authorship in shared items ("Deleted user").
- RevLog op log ([17](17-revlog-sync.md)): the payload, summary and cell detail of a spreadsheet's or
  deck's ops (cell values before and after, authors) are kept 30 days, then pruned by
  `revlog.pruneOps`; a slim row (revision, client op id, author, time) stays 365 days for
  idempotent resends. Purging a file deletes its ops.
- (M14) Submissions send a document's text, images, fields and the submitter's display name to
  the publication the user chose, after a consent dialog; publication signing secrets are stored
  unencrypted because they must sign ([18 §11](18-publications-and-submissions.md)).
- Export of all user data (*Settings › Account › Download your data*: zip of documents as
  Markdown, spreadsheets as XLSX, comments as JSON) — P1.

## 3. Operations
- **Deployment**: Serverpod Cloud (default) or Docker (existing `Dockerfile`); Postgres; Redis
  required for > 1 instance (§4); cloud storage (Serverpod Cloud storage or S3/GCS) for uploads,
  exports, version snapshots, script bytecode.
- **Web builds**: all Flutter web apps (`wonky_drive`, `wonky_write`, `wonky_sheets`,
  `wonky_slides`; v2: four) built with `--wasm` by the server's `flutter_build` script into
  `wonky_server/web/<app>` (01 §2.4), served by `FlutterRoute` with WASM headers (`enableWasmHeaders: true`; COOP/COEP required for
  `SharedArrayBuffer`/OPFS performance). `sqlite3.wasm` + `db_worker.js` shipped in each app's
  `web/` folder (versions pinned to the `sqlite_async` version). Because both apps are served
  cross-origin-isolated (COOP `same-origin` + COEP `require-corp`, also needed for the Sheets
  script bridge's SharedArrayBuffer), every cross-origin subresource must send CORP/CORS headers:
  external images (Write image-by-URL, Sheets `IMAGE()`) are therefore loaded through the
  server's image proxy (`/files/proxy?url=…`, SSRF-protected, cached), never directly. (v2)
  Drive has no PDF viewer (no PDF previews in v2, Drive 02 §6.3), so no pdf.js/PDFium is
  shipped; a later PDF viewer would have to be served from the app's own `web/` folder for the
  same reason.
- **Script workers**: Sheets scripts (installable/time-driven triggers, MCP `run_function`) run
  on server instances started with the `sheets.scripts.worker: true` role, consuming a job queue
  with an isolate pool (Sheets 09); API instances don't execute scripts. One combined role is
  fine for small deployments.
- **Migrations**: Serverpod migrations. A change to the Sheets or Slides tables changes the
  RevLog schema hash: additive changes stay compatible for `schemaWindowDays`, breaking ones
  bump `minClientVersion`; clients reset their cache after an update (no lock-step releases;
  01 §7, [17](17-revlog-sync.md) part 2 §4.3).
- **Backups**: Postgres PITR; cloud storage versioning for snapshots.
- **Scheduled jobs** (Serverpod FutureCalls): trash purge (daily), version capture & thinning
  (every 5 min scan / nightly thinning), op-log pruning (daily; Write `write.pruneOps`, RevLog
  `revlog.pruneOps`), RevLog hook sweep (`wonky.revlogSweep`, every 5 min) and stats repair
  (`revlog.repairStats`, weekly), email digests (15 min), script time-driven triggers
  (minute resolution), AI usage rollups (hourly), expired grants (`wonky.expireGrants`, hourly at :27,
  in batches until none are left), AI usage purge (`ai.purgeUsage`, in the daily chain; every job
  of a chain catches `Object` and logs its name and duration, so one failure never skips the
  rest), orphan file cleanup (weekly); (v2) storage
  reconcile (nightly), storage backfill (once, at the M8 deploy), upload expiry
  (`drive.expireUploads`, daily: uploads not completed in 24 h, reservations, chunk parts),
  file preview/thumbnail generation (on upload completion), folder `kindMask` recompute
  (nightly), Slides jobs per Slides 12; (M12) **`wonky.boardSweep`** (every 10 minutes: expired
  and expiring task claims, unchecked-post re-triage, retention of removed board content, and
  the GitHub part: delivery purge, auto-close of PRs without a valid task, postponed reviews;
  16 §8.2, §11, §13.4).
  Batched jobs work in rounds under a time budget instead of one fixed `LIMIT` per run:
  `files.cleanup` (expired files and day-old pending uploads as two indexed queries, never one
  `OR`), `versions.thin`, `write.pruneOps`, `notifications.purgeOld`. The scans they and the
  hourly jobs filter on are indexed: `stored_file (ownerId, kind, createdAt)` (upload rate limits,
  usage), `stored_file (status, createdAt)`, `stored_file.expiresAt`, `drive_item.trashedAt`,
  `drive_item_permission.expiresAt`, `notification (emailPending, createdAt)` (the digest's
  pending rows; Serverpod models have no partial indexes) and BRIN indexes on
  `document_op.createdAt`, `write_diff_cache.createdAt` and `notification.createdAt`.
- **Server write and job rules** (checked by `wonky_server/test/unit/source_rules_test.dart`):
  - *T1, no stale full-row writes*: `X.db.updateRow(row)` names the changed `columns:` (or the
    code uses `updateWhere` / atomic SQL), because a row read earlier would revert what another
    request changed meanwhile. Tables with one writer at a time (per-user settings, caches,
    lease-owned job rows) are listed in the test with the reason.
  - *T2, failures never escape long-lived work*: jobs, sweeps, queues and connections catch
    `Object`, not only `Exception`, through `runGuarded(session, name, body)`
    (`platform/common/guarded.dart`: logs at error level with the name and duration); empty
    `catch (_) {}` blocks are not allowed anywhere.
  - *T3, decide inside the write*: check-then-act decisions (answering an access request or an
    ownership transfer, orphaning or reviving a comment thread, claiming a notification email
    or a version capture) are conditional updates (`WHERE … handledAt IS NULL`, `status = …`)
    whose result says who won; read-modify-write of JSON (comment reactions, activity
    counters) happens under the row lock.
- **Search indexes** (documented exception to "the schema is `definition.sql`"): Serverpod models
  cannot declare `gin_trgm_ops` indexes, and a migration's SQL never runs on databases created
  from `definition.sql`, so `SearchIndexes` (`platform/common/search_indexes.dart`) creates the
  `pg_trgm` indexes on `drive_item.name` and `board_post.title` at every server start, in the
  background, `CONCURRENTLY` and `IF NOT EXISTS`, when the extension is available (the embedded
  test Postgres has no `pg_trgm`; the substring match then scans). The full-text search documents
  (drive item, board post) have **no index for now**: Serverpod's integrity check reports
  expression indexes as a mismatch at every start, and a clean check (an early signal of real
  schema drift) is worth more than the speed while the tables are small; full-text search scans
  (TODO.md). The expression indexes of an earlier build are dropped at start.
- **Heavy work** (T4) runs in worker isolates through the shared `IsolateRunner`
  (`platform/common/isolate_runner.dart`): Write/Slides exports, Write and Sheets imports
  (parse), image previews, script compiles and analyses, Write and Sheets version diffs and the
  Slides AI image re-encode. The isolate is **killed** at its time limit or when the caller
  cancels (an export's progress stream closed), never only abandoned; at most
  `IsolateRunner.maxConcurrent` (half the cores, 2–8) run per instance and later work waits up
  to 30 s in FIFO order, then fails with `busy`. Work that needs the database (export images)
  asks the request isolate through the runner's channel. Spreadsheet exports stay on the request
  isolate (they read the headless workbook's live formula engine; a worker would recalculate the
  workbook) and are capped at 2 per user. Process-local maps keyed by users, files or results are
  bounded (`LruMap`, T5); Slides export results are keyed on the deck's RevLog revision.
- (M12) **Board secrets and settings**: the passwords `internalJevApiKey`, `internalGeminiApiKey`
  (board AI, separate from the in-app keys), `githubAppPrivateKey` and `githubWebhookSecret` (the
  GitHub App; the webhook route is `POST https://wonky.work/api/github/webhook`, setup in
  `wonky_server/lib/src/platform/board/github/README.md`); config `wonky: board:` (16 §12), the
  GitHub integration is off until `board.github.enabled` is true.
- **Feature flags**: config-driven flags (`features.*`) for AI, scripting, MCP UI bridge,
  experimental chart types — checked server-side and delivered to clients in `meta.getInfo()`.

## 4. Running several instances

The server runs as one instance or as several identical instances behind a load balancer
(no sticky sessions needed). Several instances **require Redis**: Postgres is the only shared
state besides Redis, and `session.messages` is global only with Redis.

**Enabling it.** `config/staging.yaml` and `production.yaml` ship with `redis: enabled: false`
(a single instance, which works wherever no Redis is provisioned). To scale out, enable Redis in the
config or with `SERVERPOD_REDIS_ENABLED=true`, `SERVERPOD_REDIS_HOST`, `SERVERPOD_REDIS_PORT`
and `SERVERPOD_REDIS_PASSWORD` (or `redis:` in `passwords.yaml`). Only enable it with a Redis
that is reachable: in `production` run mode Serverpod does not fall back when Redis is down,
and messages to the other instances are then lost (sessions on the same instance still get
them, see the bus below). In staging/production
the server prints a warning at start when Redis is disabled. Development and tests run
without Redis.

**How the pieces work across instances** (helpers in
`wonky_server/lib/src/platform/cluster/cluster.dart`: `Cluster.instanceId`,
`Cluster.distributed` = Redis enabled, `ClusterSignal`s on channel `wonky:cluster`,
`Cluster.withLock` = Postgres advisory lock):

| Area | Mechanism |
|------|-----------|
| Bus channels (`doc:`, `rev:`, `presence:`, `theme:`, drive, comments, notifications) | `ClusterBus.post` (`cluster/cluster_bus.dart`): delivered to this instance's listeners at once (`MessageScope.local`), and queued for the other instances, which get everything an instance queued in **one Redis publish** on `wonky:bus` (`ClusterBusBatch`, in order) every `cluster.busFlushMs` (default 1000 ms; sooner past 256 KB). Messages with a coalesce key — a session's Write cursor and `beat`, presence `update` and `beat` — replace their queued predecessor and move to the end, so a batch carries only the latest. A post with `immediate: true` publishes the queue at once (that message and everything queued before it, in order): Write ops and the RevLog messages of `rev:<fileUuid>` (ops, role changes) use it, so collaborators on another instance see edits without the batching delay; cursors, presence and other messages still wait up to a second. Receivers drop their own batches and re-post the rest locally. The OT catch-up below and RevLog's gap fill (a client that sees a revision gap requests the missing ops, 17 part 6 §4.3) make a lost or late batch safe. Delivery is best effort |
| Write OT commits | Postgres row lock + catch-up from the op log (Write 03 §2) — correct on any instance |
| Write in-memory `DocumentState` | Each instance keeps its own. Remote `op` messages make it catch up from the op log (coalesced), and `CursorUpdate`, `RequestOps` and `HashCheck` first catch up to the revision the client names, so gap fills and cursor transforms never use a stale head |
| Document and presence rosters | `hello`/`here`/`left` plus, with Redis, a `beat` every 30 s; participants not heard of for 90 s are dropped (crashed instance, lost `left`); a `beat` of an unknown participant adds it. MCP/AI agents get a session id derived from user + document + agent, so all instances show one participant, and re-announce while active |
| Editor limit (Write 03 §7) | Checked at Init and, with Redis, again 2 s later when the `here` replies of other instances arrived (editors that joined earlier count); an over-limit joiner is switched to viewer (`RoleChanged`) |
| MCP sessions (`Mcp-Session-Id`) | Registered in Redis (`wonky:mcp:session:<id>`, TTL = idle time, refreshed each minute of use). An instance that does not know a session resumes it (replays the stored `initialize`); `DELETE` and expiry apply everywhere; new sessions are marked ready by the server so `notifications/initialized` may land anywhere. The `GET` event stream only carries notifications of the instance serving it |
| MCP rate limit | Fixed one-minute window per token counted in Redis (`INCR`), so the limit is global (up to 2× at a window boundary); in-memory sliding window without Redis or when Redis fails |
| Redis traffic | Per instance at most one bus publish per `busFlushMs`, plus `wonky:cluster` signals and the UI bridge (direct `session.messages`, latency-sensitive and rare). Serverpod subscribes each listened channel in Redis (no messages flow on them). `meta.getInfo`, the apps' 15 s connectivity heartbeat, caches its Redis ping for 30 s; Serverpod's own Redis `PING`s come from its readiness health check (`/readyz` probes), not from users |
| MCP UI bridge | Windows are registered on the instance serving their stream and listen on `uibridge:user:<userId>` and `uibridge:window:<id>`. `ui.list_sessions` merges local windows with replies collected for 300 ms; calls to a window elsewhere are relayed and answered on `uibridge:reply:<requestId>` |
| AI assistant `stop` / `confirm` | Unary calls handled locally when the run is here, else relayed as `ClusterSignal`s to the instance running the chat stream |
| Profile-id cache (`UserService`) | Account deletion invalidates it on all instances (`user.forget` signal) |
| Recurring jobs (FutureCalls) | Every instance reconciles the schedule at start under an advisory lock: existing jobs with the same cron are kept, missing ones added, changed or duplicated ones replaced. Serverpod claims each run, so it executes on one instance |
| RevLog commits | One sequencer per file: an in-memory lock per instance plus a Postgres row lock on `rev_file` (`FOR UPDATE`) across instances; revisions are dense per file (17 part 5 §2–§3) |
| RevLog post-commit hooks | Per file one `rev_hook_state` row with each hook's cursor and a lease (`leaseOwner`, `leaseUntil`, 60 s), so one instance drains a file; at-least-once, resumed by `revlog.hookSweep` (17 part 5 §6) |
| RevLog headless models (`HeadlessFileCache`) | Per instance, kept current from `rev:` bus messages with gaps filled from `rev_op` (17 part 5 §9) |

**Accepted per-instance limits** (soft limits; documented, not enforced globally):
AI concurrency per user (`ai.maxConcurrentRequests`, Suite 10) and export concurrency per user
are counted per instance; "one run per assistant thread" is checked per instance (the app
already prevents a second run); the maximum of 20 MCP sessions per user is per instance;
caches of signed/public URLs and the AI feature fallbacks are per instance. E2E verification
codes (`platform/e2e/`) are in memory and exist only in development/test, which run one
instance.

**Known framework caveat.** Serverpod's Redis controller keeps one callback per channel and
re-subscribing right after the last listener of a channel unsubscribed can lose that
subscription's messages until the next listener change; our streams subscribe after several
database round trips, which avoids the race in practice.

**Tests** simulate a cluster on one process: `Cluster.debugDistributed = true` turns on the
cluster code paths on the local bus, messages from "another instance" are posted with a
foreign `originInstance` or straight onto the channels, `ClusterBus.debugPublish` captures
batches instead of Redis and `ClusterBus.receive` delivers a foreign one, evicting `DocumentCache` gives a
connection the state another instance would have, and two `McpHttpHandler`s share an
`InMemoryMcpSessionDirectory`.

## 5. Legal pages

The web server serves a privacy policy (`/privacy`) and terms of service (`/terms`): static
HTML in `wonky_server/web/pages/` (`privacy.html`, `terms.html`), styled like the app (light and
dark, the Wonky Work icon). They name Serverpod AB (Sjöbjörnsvägen 46, 117 67 Stockholm, Sweden)
as the provider and data controller, and are linked from the sign-up screen (suite 04 §1.1).
Google sign-in requires both: the consent screen links `https://wonky.work/privacy` and
`https://wonky.work/terms` (04 §1.6). Keep them in step with the product (data collected, AI providers,
retention — trash is purged after 30 days, `DriveTrash.trashRetention`) and have changes
reviewed before publishing; material changes update the effective date and are announced.
(v2) The M8 release updates both: uploaded files of any type, the 50 MB storage limit and what
happens over it (Drive 03), acceptable use of uploads (no illegal content, no malware), and the
public nature of bug reports on GitHub (03 §3.4). (M12) The privacy policy also names the public
Bugs & improvements board and the AI checks of its posts ([16](16-bugs-and-improvements.md)).

## 6. Arbitrary uploads (v2)

Wonky Drive stores files of any type ([Drive 02](wonky_drive/02-files-uploads-previews.md)).
Rules:

| Area | Rule |
|------|------|
| Limits | One file ≤ min(available quota, `files.maxFileUploadBytes` = 50 MB); 50 MB storage per user ([Drive 03](wonky_drive/03-storage-quota.md)); ≤ 100 open reservations per user; ≤ 500 files per batch (client) |
| Rate limits | Per user: 200 upload starts per hour and 500 MB of upload traffic per day (`files.uploadsPerHour`, `files.uploadBytesPerDay`; `limitExceeded` "You've uploaded a lot recently. Try again later."); downloads: 2 GB per user per day (`files.downloadBytesPerDay`; `429` "You've downloaded a lot today. Try again tomorrow."), counted per instance and UTC day (soft, §4; `DownloadBudget`) |
| Type detection | Server-side sniffing of the stored bytes (magic numbers, then a UTF-8 text check) on the first 4 KB and, for ZIP containers, the last 64 KB, read with ranged reads (`StorageReads`; text line counts stream), never the whole object; the client-declared type and the extension never override a binary signature (Drive 02 §5) |
| No active content | HTML, SVG, XML, JavaScript and unknown types are never rendered — text types are shown as escaped source in Flutter, others not at all. Images are decoded by Flutter/`package:image` (bounded: ≤ 50 MP, 10 s), PDFs rasterized (no PDF JavaScript, forms or link actions) |
| Downloads | Served by `GET /files/d/:fileUuid/:name?t=…` (HMAC token: file + user + expiry, 15 min), streamed from private storage in 1 MB pieces (`StorageReads`: database storage by `substring`, cloud storage over its temporary URL; never buffered whole) with `Content-Disposition: attachment; filename="<ascii>"; filename*=UTF-8''<encoded>`, `Content-Type` = the sniffed type (or `application/octet-stream`), `X-Content-Type-Options: nosniff`, `Content-Security-Policy: sandbox; default-src 'none'`, `Cross-Origin-Resource-Policy: same-origin`, `Cache-Control: private, no-store`. Never inline |
| Uploads | `PUT /files/upload/:fileUuid` accepts only the declared size (`413` beyond), requires the token or the session; objects go to private storage under `drive/<ownerUuid>/<fileUuid>/` (ASCII-safe names) |
| Names | Display names keep Unicode but lose control characters and bidi overrides (U+202A–U+202E, U+2066–U+2069), so extensions can't be spoofed (Drive 02 §5.1) |
| Archives | Never extracted or listed on the server (no zip bombs); XLSX/DOCX/ODS imports keep their existing decompressed-size limits |
| Previews | Generated server-side only for images (re-encoded, metadata stripped — EXIF GPS removed from previews; the original file is unchanged and downloads as uploaded) |
| Malware | Not scanned in v2: files are private, shared only with signed-in users, and never executed or rendered by Wonky (decided below) |
| Sharing | No anonymous links (06 §2.2); every byte request is permission-checked; URLs are short-lived and user-bound |
| Privacy | File contents are never logged; MCP/AI read text files only through permission-checked tools; the legal pages (§5) list uploaded files as stored content (retention: deleted with the item; trash purged after 30 days) |

**Decided (v2 review, Q11):** no malware scanning of uploads in M8 (e.g. ClamAV in a sidecar):
the risk is limited by private storage, signed-in sharing and forced downloads. Revisit before
anonymous or public sharing exists.
