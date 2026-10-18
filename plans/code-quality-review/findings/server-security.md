# Wonky Work server: security review (read-only)

Scope: `wonky_server/lib` (generated code skipped), cross-checked against `specs/13-security-and-operations.md`
and `specs/06-sharing-and-permissions.md`. All paths are relative to `wonky_server/` unless noted. Findings were
verified by reading code; none were exploited against a running server. Items marked **(unverified)** are
suspicions I could not confirm from code alone.

Severity: High = data loss / cross-user access / mass PII; Med = authz gap with preconditions, persistence,
DoS of an instance; Low = hardening, minor leaks, abuse.

---

## 0. Summary of findings

| ID | Title | Sev | Effort |
|----|-------|-----|--------|
| S-01 | Editor can permanently delete items they don't own (move into own folder → trash → delete forever; folder purge ignores ownership) | **High** | M |
| S-02 | `drive.registerSpreadsheet` can bind a new spreadsheet item to another user's **deck** space (persistent access, sharing bypass, deck destruction) | **High** | S |
| S-03 | `user.getUsers(ids)` returns email/name/uuid of any user: whole user base enumerable | **High** | S |
| S-04 | Link sharing = knowing the item uuid; `rotateLink` does not revoke access; link items reach every user's template gallery | Med | M |
| S-05 | Moving an item into your own folder gives a persistent inherited grant and lets you share it (bypasses `editorsCanShare=false`, survives link-off) | Med | M |
| S-06 | Expired grants keep working on open streams and in sync-space membership for up to ~24 h | Med | S |
| S-07 | Presence stream never re-checks access (revoked users keep receiving cursors and Sheets commit hints) | Med | S |
| S-08 | Viewer can copy an item **with comments** although `viewersSeeComments=false` | Med | S |
| S-09 | Viewers can read full op history (`document.getOps`, `DocRequestOps`) although history is Editor+ | Med | S |
| S-10 | Slides AI `describeElements` decodes images without a pixel cap (decompression bomb → OOM) | Med | S |
| S-11 | Unauthenticated / unthrottled write endpoints: `feedback.submit/reportError`, board `similar` (signed out), GitHub webhook buffers 10 MB pre-auth | Med | S |
| S-12 | Notification spam: `sharing.requestAccess` re-notifies owner+editors on every call, unbounded `message` | Low | S |
| S-13 | No per-user quota on the image proxies (`file/sheets/writeExport.fetchImage`); SSRF blocklist gaps and DNS re-resolution | Low | S |
| S-14 | Unthrottled `importSource` (100 MB), `boardScreenshot`, public `avatar` uploads outside quota and rate limits | Low | S |
| S-15 | `script.notifyOpen`: any viewer can enqueue the owner's installable onOpen triggers without limit | Low | S |
| S-16 | GitHub webhook replay: signature covers body only; dedupe on attacker-controlled delivery id | Low | S |
| S-17 | `LoggingEmailSender` is used in production when Resend is not configured: logs recipient + email body | Low | S |
| S-18 | `file.getUrl` on Drive files bypasses the download route's controls (no nosniff/CSP, ignores "viewers can't download") | Low | S |
| S-19 | Misc input bounds: `anchorJson`, presence `cursorJson`, `pageSetup`, MCP 30 MB bodies, unbounded `DocRequestOps` range | Low | S |
| S-20 | `sharing.updateRole` creates a direct grant for any user id (silent share without the email path) | Low | S |
| S-21 | Presentation followers are not re-checked after access loss; pairing-code limiter is per instance | Low | S |
| S-22 | `ui:control` MCP scope is effectively full account control (drives the signed-in UI) | Info | — |

Positive controls verified are listed in §11.

---

## 1. Authorization / IDOR sweep (every endpoint)

`requireLogin` = Serverpod login required. "AS" = `AccessService.require/requireRole/effectiveRole` (lib/src/platform/sharing/access_service.dart).
Unless stated otherwise each endpoint method delegates to the service named and the check is at the line given.

| Endpoint (file) | Login | Methods → check | Notes |
|---|---|---|---|
| `EmailIdpEndpoint`, `JwtRefreshEndpoint`, `GoogleIdpEndpoint` (auth/, users/) | public | Serverpod IDP base classes | Google links to an existing profile by verified email (`users/google_idp.dart:91-123`) |
| `ActivityEndpoint` (platform/activity/activity_endpoint.dart) | yes | `dashboard` → AS viewer (`activity_service.dart:222`), viewer list Editor+ (`:249`); `showViewHistory/setShowViewHistory` own | OK |
| `AssistantEndpoint` (platform/ai/assistant_endpoint.dart) | yes | status/quality/key: own; `chat/inline/proofread`: AS on item via tools; `stop/confirm/uiToolResult` by own userId; threads via `_own` (`assistant_service.dart:373,404`); `revertChange` own | Tool allow/deny list (`assistant_tools.dart:73-85`) blocks share/trash/delete; thread pinning `:283-301` |
| `BoardEndpoint` (platform/board/board_endpoint.dart) | **public** | reads: `BoardAccess.canSee*` (`board_access.dart:96-115`); writes: `requireWriter` (signed-in, not blocked); admin ops: `requireAdmin` (email domain, `board_admins.dart:17-30`) | S-11 (signed-out `similar` unthrottled); per-user limits only for signed-in (`board_common.dart:70-82`) |
| `CommentEndpoint` (platform/comments/) | yes | list/get/watch: viewer + `viewersSeeComments` (`comment_service.dart:28-43,103-108,845-852`); create/reply/resolve/react/edit: commenter (`:237-242`, `_thread` min commenter `:45-63`); delete/deleteThread/updateAnchor: author or Editor+ (`:523,546,685`); edit author-only (`:490`) | OK. `anchorJson` unbounded (S-19) |
| `DriveEndpoint` (platform/drive/drive_endpoint.dart) | yes | `get/path/activity/markOpened/setStarred/setPinnedOffline/addShortcut`: AS viewer; `list` folder viewer + per-child `rolesFor` (`drive_service.dart:157,252`); `search` candidates owner/grant/link-visited + `rolesFor` (`:367-424`); `createFolder/createDocument/...`: parent Editor+ (`_parentFor` `:454`); template source viewer (`:678,837`); `rename/updateDescription/setThumbnail/trash/restore`: Editor+; `move`: Editor+ on item and target, root only owner (`:1129-1155`); `copy`: viewer + `nonEditorsCanExport` (`:1248-1256`); `deletePermanently`: owner (`:1905`); `emptyTrash` owned; `setTemplate` owner; `removeShortcut` own state; `checkRoom` viewer (leaks owner quota headroom, minor); `registerSpreadsheet` space role (`:776-789`); `registerPresentation` (`drive_presentations.dart:28-55`); file uploads/convert/contentUrl/updateFileMeta (`drive_file_service.dart:64,505,616,697`); `listByStorage/storageUsage` own | **S-01, S-02, S-05, S-08** |
| `E2eSupportEndpoint` (platform/e2e/) | public | refuses outside development/test and non-`@example.test` (`e2e_support_endpoint.dart:15-23`); codes only captured in dev/test (`email_idp.dart:20-23`) | OK |
| `FeedbackEndpoint` (platform/feedback/) | **public** | none (by design) | S-11 |
| `FileEndpoint` (platform/files/file_endpoint.dart) | yes | `createUpload`: item Editor+ (`file_service.dart:120-128`), type allowlist; `completeUpload` owner; `getUrl/getUrls`: `canRead` = owner, avatar, or any role on the file's item (`:302-316`); `copyToItem`: Editor+ target + `canRead` source (`:458-490`); `fetchImage`: AS viewer (`file_image_proxy.dart`) | S-13, S-14, S-18 |
| `UiBridgeEndpoint` (platform/mcp/ui_bridge/) | yes | windows registered under caller's userId (`ui_bridge_hub.dart:177-198`) | S-22 |
| `MetaEndpoint` (platform/meta/) | public | none; exposes runMode, Redis status, limits | Info |
| `NotificationEndpoint` | yes | all filtered by own userId (`notification_service.dart:225-228`) | OK |
| `PresenceEndpoint` | yes | `join`: AS viewer at start only (`presence_service.dart:264-269`) | **S-07** |
| `SharingEndpoint` | yes | `getSharing` viewer (returns all grantee emails to viewers); `share/updateRole/setLink/rotateLink`: `_requireSharer` (owner or editor+editorsCanShare) and role ≤ own (`sharing_service.dart:32-47,199-201,311-314,594-597`); `remove`: self or sharer; `transferOwnership/updateSettings`: owner; `respondToOwnershipTransfer`: recipient; `requestAccess`: any signed-in user knowing the uuid; `handleAccessRequest`: sharer; `resolveInvite`: token | S-04, S-12, S-20 |
| `AccessTokenEndpoint` | yes | own tokens (`account_service.dart:194-268`) | tokens have no default expiry (Info) |
| `UserEndpoint` | yes | profile/avatar/prefs/deletion: own; `searchUsers`: restricted to related users or exact email (`user_service.dart:448-495`); **`getUsers`: any ids** (`user_endpoint.dart:91-95`) | **S-03** |
| `VersionEndpoint` | yes | Editor+ via `requireVersion` (`version_service.dart:216-234`) incl. `getSnapshotUrl` | OK |
| `SheetsAiEndpoint` | yes | `_open` via `SheetsMcp.open` (viewer) / editor for fill/apply (`sheets_ai_service.dart:53,622,780,1244`); previews bound to userId (`:1122-1127`) | OK |
| `SheetsEndpoint` | yes | subscribe/unsubscribe/stats/namedFunctions/theme: AS viewer; revert/reapply: Editor+ (`sheets_service.dart:113,133`); cellHistory viewer; activitySummary Editor+; fetchImage viewer (`sheets_image_proxy.dart:36`); `ensureSubscribed` per-space AS (`space_service.dart:267-325`) | OK |
| `SheetsSyncEndpoint`, `SlidesSyncEndpoint` | yes | offline-sync membership + kind filter (`space_sync.dart:34-49`, `space_kinds.dart:111-123`); inbound writes re-check membership per batch (third_party engine `engine.dart:478-489`) | S-02, S-06 |
| `SheetsImportEndpoint` | yes | `importInto`: Editor+ and own upload (`sheets_import_jobs.dart:76-92`); jobs `_own`; `sourceFromDrive`: viewer + `nonEditorsCanExport` (`sheets_export_service.dart:40-50`) | OK |
| `ScriptEndpoint` | yes (feature off in prod) | compile/analyze Editor+; bytecode/run/runLive/urlFetch/authorize viewer (`script_service.dart:111,375,434,722,789`); executions all for Editor+; `notifyOpen` viewer | S-15 |
| `SheetsVersionEndpoint` | yes | Editor+ (`sheets_version_endpoint.dart:33-38,68-87`); `copyExtras` viewer+export on source, owner on target (`:160-176`) | OK |
| `SlidesAiEndpoint` | yes | `_open` Editor+ default (`slides_ai_service.dart:89-97`), rankDesigns viewer; previews by userId (`:1095`) | S-10 |
| `SlidesChartsEndpoint` | yes | viewer on **source spreadsheet** + `nonEditorsCanExport` (`slides_chart_service.dart:350-377`); checkLinks per spreadsheet (`:244-261`); ≤50 probes, per-user limiter | OK (item 8) |
| `SlidesEndpoint` | yes | same as Sheets (kind deck) | OK |
| `SlidesExportEndpoint` | yes | viewer + `nonEditorsCanExport` (`slides_export_service.dart:95`) | OK |
| `PresentationEndpoint` | yes | `join/find`: AS viewer (`presentation_service.dart:372,194`); `resolvePairingCode`: limiter + viewer after resolve (`:97-150`) | S-21 |
| `SlidesThemesEndpoint` | yes | headless deck open → AS viewer (`headless_deck.dart:334-338`) | OK |
| `SlidesVersionEndpoint` | yes | Editor+ | OK |
| `DocumentEndpoint` | yes | `connect`: viewer at open, re-check on `role` bus message (`document_connection.dart:101,362-397`); ops validated by role (`ot_service.dart:76,162-174`); `getInfo/getOps` viewer; `getSnapshot` old revs Editor+ (`document_service.dart:127`); `updateMeta` Editor+ | S-09 |
| `WriteExportEndpoint` | yes | viewer + `nonEditorsCanExport`, old revs Editor+ (`write_export_service.dart:83-95`); `convertForInsert` own file + Editor+ target; `fetchImage` viewer | S-13 |
| `WriteHistoryEndpoint` | yes | Editor+ (`write_history_service.dart:30-187`) | OK |
| `WriteThemeEndpoint` | yes | owner/builtin/via doc viewer (`theme_service.dart:142-164`); writes owner (`:188-200`) | OK |
| Web routes | — | `/files/d` HMAC token + AS re-check (`file_routes.dart:86-146`); `/files/upload` token + owner + size (`:161-218`); `/mcp` bearer token; `/api/github/webhook` HMAC; `/invite/:token` (oracle of item kind only); `/improvements/**` fixed `/drive` prefix (no open redirect) | S-11, S-16 |

---

## 2. Findings in detail

### S-01 (High) Editor-to-permanent-deletion of other users' items
**Evidence**
- `DriveService.move` (lib/src/platform/drive/drive_service.dart:1121-1201) only needs Editor+ on the item and on the target folder; ownership is checked only for moves to the root (`:1151`).
- `DriveService.trash` (`:1789-1825`) marks the **whole subtree** trashed for any Editor+ of the root, regardless of the owners of descendants.
- `DriveService.deletePermanently` (`:1893-1913`) checks `role == owner` on the **root only**, then `purge` (`:1935-1982`) deletes every node of the subtree (`DriveItem.db.deleteWhere(id in ids)`, `OfflineSyncSpace.db.deleteWhere` for spreadsheets/decks `:1944-1951`, stored files). `emptyTrash` (`:1915-1932`) and the daily `purgeExpiredTrash` (`:1984-2002`) do the same.
**Impact** Spec 06 §1: "delete forever" is Owner-only. Any Editor of an item (including everyone when "Anyone with the link: Editor" is on) can move it into a folder they own, trash the folder and delete it forever — the victim's document/spreadsheet/deck is gone (only version snapshots may survive). Also, any Editor of a shared folder who trashes it schedules deletion of every item inside it that other people own, 30 days later, without those owners seeing it in their trash.
**Fix** In `purge`/`deletePermanently`/`purgeExpiredTrash`, only delete nodes owned by the deleting user (or the root's owner); re-parent foreign-owned descendants to their owner's root (Google Drive behaviour) and rebuild inherited grants. Consider requiring ownership (or `editorsCanShare`-like setting) to move items between folders of different owners.
**Effort** M

### S-02 (High) Spreadsheet registration on a deck space
**Evidence**
- `DriveService.registerSpreadsheet` (drive_service.dart:762-819): the idempotency check looks only for an existing **spreadsheet** item with that `contentRef` (`:769-775`); otherwise it accepts any space the caller has `readWrite` on (`:782-789`).
- `SpaceService.useReservation` (lib/src/platform/spaces/space_service.dart:137-170) returns `false` when the reservation belongs to another user **before** the kind check (`:149` vs `:152`), so a deck reserved by its owner falls through to the `readWrite` check, which a deck Editor passes (`subscribe` grants readWrite to editors, `:173-205`).
- `drive_item.contentRef` is not unique (`drive_item.spy.yaml` index `drive_item_content_idx`).
- Compare `DrivePresentations.register` (lib/src/platform/drive/drive_presentations.dart:28-37), which rejects a `contentRef` used by **any** item kind.
**Impact** A deck Editor creates a spreadsheet item they **own** that points at the deck's space. Then: (a) after the deck owner removes them, `sheets.subscribe` on the fake item re-grants `readWrite` on the deck space (`SpaceService.subscribe`), and the Slides sync serves it whenever `SpaceKinds.recorded` (`space_kinds.dart:48-76`, "last item wins", order undefined) resolves the space as a deck — persistent access; (b) they can share the fake item with anyone (bypasses `editorsCanShare`); (c) trashing and deleting the fake item runs `purge`, which deletes the `OfflineSyncSpace` rows of the deck — destroys the victim's deck; (d) the kind ambiguity can also break the owner's own Slides sync.
**Fix** In `registerSpreadsheet` check `contentRef` across all kinds (as `DrivePresentations.register` does) and refuse spaces whose recorded kind is not spreadsheet; in `useReservation` check kind before ownership; add a unique index on `drive_item.contentRef` (nullable) via migration.
**Effort** S

### S-03 (High) User directory enumeration via `user.getUsers`
**Evidence** lib/src/platform/users/user_endpoint.dart:91-95 returns `UserService.summaries` for any 200 ids per call; `UserSummary` includes `email`, `displayName`, auth `uuid`, avatar (`user_service.dart:225-236`). Profile ids are sequential ints. `searchUsers` (`:448-495`) deliberately restricts results to related users, which this bypasses.
**Impact** Any signed-in account (sign-up is open) can harvest every user's email and name in a loop. With S-20 they can then silently grant items to arbitrary users.
**Fix** Restrict `getUsers` to users related to the caller (same "related" CTE as `searchUsers`, plus co-participants of items the caller can read), or return summaries without `email` for unrelated users; rate-limit.
**Effort** S

### S-04 (Med) Link sharing keyed on the item uuid; `rotateLink` ineffective; gallery spam
**Evidence** `AccessService.rolesFor` (access_service.dart:119-126) grants the link role to **every** user for every item whose `ShareLink.role` is set, without requiring that they resolved the token. `rotateLink` (sharing_service.dart:641-665) only changes the token ("old links stop working"). Item uuids travel in many places (app URLs `/d/<uuid>`, deck chart links store the spreadsheet uuid, notifications, MCP output); new uuids are v7 (time-ordered prefix). `listTemplates` (drive_service.dart:2027-2056) loads up to 500 published templates of **all users** and keeps those with any role — link-shared templates therefore appear in every user's gallery (name, description, 140-char preview text).
**Impact** Rotating the link does not cut off people who saw the old URL or uuid; anyone who learns a uuid of a link-shared item gets the link role. Any user can push content (phishing text) into every other user's template gallery, and 500 such items push legitimate shared templates out.
**Fix** Treat the link role as applying only to users who resolved the current token (record `DriveItemUserState.viaLink` with the token generation, and drop link visitors on rotation) or document that the uuid is the secret and make `rotateLink` also re-key; exclude link-only roles from `listTemplates` (direct grants/ownership only) and query the caller's visible templates instead of a global top-500.
**Effort** M

### S-05 (Med) Persistent access and sharing-restriction bypass via move
**Evidence** `move` (drive_service.dart:1121-1201) → `AccessService.rebuildInherited` (access_service.dart:214-348) gives the **target folder's owner** an inherited Editor grant (`:297-309`) and copies every direct grant of that folder onto the item at the folder grant's role (`:280-295`).
**Impact** An Editor (including a link Editor, or an Editor with `editorsCanShare=false`) moves the item into a folder they own: they keep Editor after the owner turns the link off, and can share that folder with anyone to grant Editor on the item — bypassing the owner's "Editors can share" setting. The item also vanishes from its original folder (others lose inherited access).
**Fix** Only allow moving into a folder whose owner equals the item owner, or require `canShare` on the item for cross-owner moves; never grant inherited roles above what `editorsCanShare` allows; show the owner a notification.
**Effort** M

### S-06 (Med) Expired grants linger on live channels for up to ~24 h
**Evidence** `AccessService.rolesFor` filters `expiresAt` (access_service.dart:113), but nothing fires `AclEvents.changed` at expiry except the **daily** job `SharingService.removeExpiredGrants` (sharing_service.dart:839-864, scheduled in `wonky.daily` 03:17, `server.dart:218`, max 1000 rows per run). Space membership (`SpaceService.mirrorMembership`, space_service.dart:393-430), the Write stream's cached `_role` (document_connection.dart:53,378-397) and presence (S-07) are only updated by those events. Inbound sync writes are checked against **membership**, not the ACL (third_party/serverpod_offline_sync/lib/src/sync/engine.dart:478-489).
**Impact** A user whose access expired can keep reading and writing a spreadsheet/deck through sync, and keep editing an open Write document, until the next daily run (or longer if >1000 grants expire).
**Fix** Schedule a FutureCall at each grant's `expiresAt` (or run the expiry job every few minutes) and call `AclEvents.changed`; have `DocumentConnection._submit` re-check the role when the cached one is older than N seconds.
**Effort** S

### S-07 (Med) Presence stream never re-checks access
**Evidence** `PresenceService.join` (lib/src/platform/presence/presence_service.dart:35-300) checks viewer once in `start()` (`:264-269`), then relays all bus messages (`hello/update/hints/follow`) for the item channel. No listener for ACL changes; the role used to gate hints is captured once (`:224`).
**Impact** After being removed from an item (or after expiry), a still-connected client keeps receiving participants (names, avatars, user uuids), cursor/selection JSON and Sheets "commit hints" (Sheets 10 §2.1; ephemeral cell commits), and a demoted editor can keep posting hints.
**Fix** Subscribe to the item's ACL change (e.g. reuse `DocumentBus.rolesChanged`-style signal or `DriveEvents`) and re-run `AccessService.effectiveRole` on it and on a timer (as `PresentationService` does every 5 s); close the stream on loss.
**Effort** S

### S-08 (Med) Copy with comments ignores `viewersSeeComments`
**Evidence** `DriveService.copy` (drive_service.dart:1239-1430) requires viewer + `nonEditorsCanExport` (`:1248-1256`) and then honours `copyComments` for decks (`:1273-1279`), documents (`:1312-1371`) and spreadsheets (`:1408-1416`) with no check of `viewersSeeComments`. `CommentService._requireRead` (comment_service.dart:28-43) hides comments from viewers in that case.
**Impact** A Viewer copies the item with comments into their own drive and reads all comment threads (bodies, authors, mentions) the owner chose to hide. Same via MCP `drive.copy` (`drive_tool_handlers.dart:365`).
**Fix** Force `copyComments=false` when `role == viewer && !source.viewersSeeComments`. Also consider requiring Editor+ for `copySharing` (a viewer currently copies the grant list and pending invites onto their copy, `copyGrants` `:1537-1575`).
**Effort** S

### S-09 (Med) Op history readable by viewers
**Evidence** `DocumentService.getSnapshot` refuses old revisions for non-editors (document_service.dart:127-129), but `getOps` (`:80-117`) returns any op range to viewers (1000 per call, all within the 30-day op retention), and the stream's `DocRequestOps` (document_connection.dart:431-452) returns any range with no cap.
**Impact** Viewers reconstruct deleted text and the edit history ("Viewing history requires edit access" is bypassed), including comment/suggestion attribute ops.
**Fix** For role < Editor allow only ops above the revision the client joined at (or ≥ head − small window); cap `DocRequestOps` to `maxOpsPerRequest`.
**Effort** S

### S-10 (Med) Unbounded image decode in Slides AI
**Evidence** `SlidesAiService._imageOf` (lib/src/slides/ai/slides_ai_service.dart:950-986) calls `img.decodeImage(bytes)` on stored images (≤ 20 MB, `maxImageUploadBytes`) on the request isolate with no pixel cap or timeout. `FilePreviewService` does cap at 50 MP and uses an isolate with a timeout (file_preview_service.dart:47,63-68,167-169).
**Impact** A deck Editor with AI enabled inserts a highly compressible huge PNG (e.g. 30 000 × 30 000) and calls *Describe elements*: multi-GB allocation → instance OOM/stall.
**Fix** Use `findDecoderForData(...).startDecode` to read dimensions first and skip > 50 MP; decode in `Isolate.run` with a timeout (reuse `FilePreviewService`).
**Effort** S

### S-11 (Med) Unauthenticated / unthrottled entry points
**Evidence**
- `FeedbackEndpoint.submit/reportError` (lib/src/platform/feedback/feedback_endpoint.dart:13-51): no login, no rate limit; each call inserts a row of up to ~90 KB (message 20k + stack 50k + context 20k chars).
- `BoardPosts.similar` (board_posts.dart:96-110) rate-limits signed-in callers only; signed-out callers run a 40-term prefix `to_tsquery` over `board_post` without limit (`board_search.dart:68-101`). Same for `list`/`getPost` reads (no limiter at all, acceptable for reads).
- `GithubWebhookRoute` (lib/src/web/routes/github_webhook_route.dart) folds the body into a `List<int>` of up to 10 MB **before** the enabled/signature checks (`GithubWebhook.receive` returns 202 when disabled only after the read) — ~80 MB heap per request as boxed ints.
**Impact** DB growth and CPU/memory DoS by anonymous clients (Serverpod has no global per-IP limiter).
**Fix** Per-IP limiter (or require login) for feedback; per-IP limiter for signed-out `similar`; in the webhook check `enabled` first and read into a `BytesBuilder` with a smaller cap (GitHub events used here are < 1 MB).
**Effort** S

### S-12 (Low) Access-request notification spam
**Evidence** `SharingService.requestAccess` (sharing_service.dart:697-764): any signed-in user who knows a uuid; updates the pending request and **re-notifies** the owner and every editor (when `editorsCanShare`) on every call; `message` has no length cap (`:735`).
**Fix** Rate-limit per requester/item, notify only on create (or once per day), cap `message` (e.g. 1000 chars).
**Effort** S

### S-13 (Low) Image proxy quotas and SSRF hardening
**Evidence** `SafeImageFetcher.fetch` (lib/src/write/export/server_images.dart:22-68) — https, port 443, no redirects, 10 s, 10 MB, `image/*` (no SVG): good. Gaps: (a) DNS is resolved by `InternetAddress.lookup` (`:32`) and then **again** by `HttpClient.getUrl` (rebinding TOCTOU; largely neutralised by TLS hostname verification, hence Low); (b) `isPrivate` (`:71-97`) misses 192.0.0.0/24, 198.18.0.0/15, 240.0.0.0/4/255.255.255.255, NAT64 `64:ff9b::/96`, 6to4 `2002::/16`, `fec0::/10`; (c) no per-user quota (spec 13 §1 promises "per-user quotas"): `FileImageProxy` (`file_image_proxy.dart`) has only a global LRU cache. The script `UrlFetchProxy` (lib/src/sheets/scripts/url_fetch_proxy.dart) already pins the resolved address and blocks all of these ranges — reuse it.
**Fix** Route `SafeImageFetcher` through `UrlFetchProxy.isBlockedAddress` and its pinned `connectionFactory`; add a per-user limiter (e.g. 60/min, 200 MB/day).
**Effort** S

### S-14 (Low) Uploads outside quota and rate limits
**Evidence** `FileService.createUpload` (file_service.dart:84-221): `importSource` (100 MB, 24 h), `boardScreenshot` (5 MB, 1 day, reachable directly through `file.createUpload` without `BoardAccess.requireWriter`), `avatar` (5 MB, **public** storage) are neither quota-reserved nor rate-limited; only Drive files go through `_checkRates` (drive_file_service.dart:254-292). `importSource` content type is client-declared and not sniffed (only images are, `:232-248`).
**Impact** Storage exhaustion by one account (100 MB × unlimited per day); public avatar storage usable as free image hosting.
**Fix** Apply the `files.uploadsPerHour`/`uploadBytesPerDay` limiter to all kinds; cap pending import sources per user; route board screenshots only through the board endpoint.
**Effort** S

### S-15 (Low) `script.notifyOpen` can be spammed by viewers
**Evidence** lib/src/sheets/scripts/script_endpoint.dart:183-193 → `ScriptTriggerService.fireOpen` (script_triggers.dart:499-518) enqueues every installable onOpen trigger per call, no rate limit; triggers run with their installer's authorization and quota.
**Impact** Any viewer (incl. link viewers) can burn the trigger owner's daily script quota / worker pool. Scripting is off in production config (`features.scripting: false`), hence Low.
**Fix** Debounce per (user, spreadsheet) (e.g. once per 5 min).
**Effort** S

### S-16 (Low) GitHub webhook replay
**Evidence** lib/src/platform/board/github/github_webhook.dart: HMAC-SHA256 over the body, constant-time compare (`:19-42`) — good. Dedupe uses `X-GitHub-Delivery` (`:97-123,161-183`), which is **not** covered by the signature; delivery rows are purged after 7 days (`board_github.dart:66,309`).
**Impact** Anyone holding one captured signed delivery can replay it with a new delivery id (re-trigger PR lifecycle transitions/reviews). Needs a captured payload, hence Low.
**Fix** Also dedupe on a hash of the body (or `(event, action, pr.number, head sha, updated_at)`), and ignore events whose embedded timestamps are older than N minutes.
**Effort** S

### S-17 (Low) Email bodies logged when no mail provider is set
**Evidence** lib/src/platform/notifications/email/email_sender.dart:53-66,133-149: without `resendApiKey` the `LoggingEmailSender` logs `to`, subject and full text (comment bodies, share messages, document names). `delivers` is never consulted (only defined at `:35,58,90`). No run-mode guard.
**Impact** PII and document content in production logs if the key is missing (spec 13 §2 "no document content in logs").
**Fix** In staging/production use a sender that drops (and warns once) instead of logging bodies; skip scheduling emails when `!delivers`.
**Effort** S

### S-18 (Low) `file.getUrl` path for Drive files
**Evidence** `FileService.getUrl/getUrls` (file_service.dart:317-341) serve any `StoredFile` whose item the caller can read, including `driveFile` bytes, as a storage signed URL with the **sniffed** content type (`_view` `:348-379`). It bypasses the `nonEditorsCanExport` check enforced by `DriveFileService.contentUrl` (drive_file_service.dart:524) and `/files/d` (file_routes.dart:118), and the spec-mandated `nosniff`/`CSP: sandbox` headers. Verified in serverpod 4.1.0-beta.3 `public_endpoint.dart:199-216` that `downloadFileName` forces `Content-Disposition: attachment`, so no inline rendering on the DB-storage fallback (hence Low).
**Fix** Refuse `driveFile` kinds in `FileService.getUrl/getUrls` (Drive files go through `drive.fileContentUrl`), or force `application/octet-stream`.
**Effort** S

### S-19 (Low) Input bounds
- API `maxRequestSize` is 512 KB in all configs (config/production.yaml:57), which bounds unary endpoint params. Not bounded below that: comment `anchorJson` (comment_service.dart:243-247, 694-698), presence `cursorJson` (relayed to all participants, presence_service.dart:209-221), document `pageSetup` (document_service.dart:189-193).
- Streaming (WebSocket) message size limits are Serverpod's, **(unverified)** whether `maxRequestSize` applies to stream frames (`DocSubmitOp.deltaJson`, sync batches).
- `/mcp` accepts 30 M-char bodies (`McpHttpHandler.maxBodyChars`, mcp_http.dart) decoded with `jsonDecode` (deep nesting throws `StackOverflowError`, caught as a 500 — no crash, but a 30 MB decode per request per token).
- `DocRequestOps` unbounded range (document_connection.dart:431-452); `DocHashCheck` reconstructs any old revision on demand (`:453-466`) without a limiter.
**Fix** Cap these strings (e.g. 8 KB anchors/cursors, 16 KB pageSetup), lower MCP body to a few MB, cap op ranges and rate-limit hash checks.
**Effort** S

### S-20 (Low) `sharing.updateRole` creates grants for any user id
**Evidence** sharing_service.dart:316-337: when no direct grant exists ("Inherited only") it inserts one for the given `userId` without checking that the user has an inherited grant. Sharer-only, so not an escalation, but it shares silently (no notification, no activity log) with arbitrary ids (combine with S-03).
**Fix** Require an existing (inherited) grant for `userId`, else go through `share`.
**Effort** S

### S-21 (Low) Presentations
**Evidence** Session ids: 128-bit random base62 (`presentation_service.dart:158-171`). Joining needs viewer on the deck (`:372`) and the presenter's session id; only presenter/follower/remote roles; remotes of another account need a presenter-admitted pairing key (`:492-505`). Commands re-check access every 5 s (`:801-811`) but followers/audience are never re-checked after joining. Pairing codes: 6 digits, 10-minute TTL, 10 tries/min per user **per instance** (in-memory `_resolves`, `:70-107`); resolution still requires viewer on the deck (`:144`). No anonymous access (all methods `requireLogin`).
**Impact** A follower who loses access keeps receiving slide position/laser/drawing state until they disconnect (content itself comes from sync, which is revoked). Phone remote is on hold.
**Fix** Apply the 5 s access re-check to followers on received state; move the code limiter to the shared `RateLimiter`.
**Effort** S

### S-22 (Info) `ui:control` scope
A token with only `ui:control` drives the user's signed-in app windows through the UI bridge (`ui_bridge_hub.dart`, `ui_tool_handlers.dart`), which can perform any UI action (open items, share dialog per spec 06 §5). Its effective power exceeds `drive:*`/`write:*` scopes. Document this in the token UI ("full control of open windows") or have the client reject bridge commands outside an allowlist.

---

## 3. Streams and role revocation (item 2)

| Stream | Re-check on ACL change? | Evidence |
|---|---|---|
| `document.connect` (Write) | Yes, on `DocumentBus.rolesChanged` from `AclEvents` (closes on loss, `DocRoleChanged` on downgrade) | document_connection.dart:362-397; acl_events.dart:36-39. Expiry only via daily job (S-06) |
| `sheetsSync.sync` / `slidesSync.sync` | Membership mirrored by `AclEvents` → `mirrorMembership`; engine cycles membership and checks inbound writes per batch | space_service.dart:393-430; engine.dart:478-489. Expiry delay (S-06); S-02 re-grant |
| `comment.watch` | Yes, per signal (role and `viewersSeeComments`) | comment_service.dart:845-852 (only when a comment signal arrives) |
| `drive.watch` | Yes, per signal (`effectiveRole` per item) | drive_events.dart:64-76 |
| `presence.join` | **No** | S-07 |
| `presentation.join` | Commands every 5 s; followers no | S-21 |
| `notification.watch`, `uiBridge.connect`, assistant `stop/confirm` | Per-user, n/a | — |
| `assistant.chat/inline/proofread`, AI streams | Tools go through services with AS checks per call | assistant_tools.dart:243-307 |
| `board.watchPost/watchTasks` | Visibility re-checked per signal | board_live_streams.dart:11-38 |
| `sheetsImport.watchImport` | Own job | sheets_import_jobs.dart:605 |

## 4. MCP (item 3)
- Auth: bearer only, cookies ignored (mcp_http.dart, "Bearer auth only"); tokens `wkpat_` + 40 base62 chars (~238 bits) from `Random.secure` (account_service.dart:232-238), stored as SHA-256 (`:179-180`), looked up by hash, revocable, optional expiry (no default expiry), `lastUsedAt` updated each minute (`:272-302`). ≤50 active tokens per user.
- Host/Origin checks against `allowedHosts`/`allowedOrigins` (mcp_config.dart:15-33); requests without Origin allowed (non-browser).
- Sessions bound to (userId, tokenId) (`mcp_http.dart` "This session belongs to another access token"); 20 per user per instance.
- Scopes: enforced per tool in `ToolExecutor.call` (`tool_executor.dart:~85-98`) before arguments and handlers; allowed set in account_service.dart:159-173.
- Rate limits: 600 tool calls/min per token (`McpConfig.rateLimitPerMinute`), 60 writes/min per token per target (`tool_executor.dart:~44-125`); Redis-backed when enabled. `initialize`, `tools/list` and failed auth are not limited (Low; token entropy makes guessing infeasible).
- ACL bypass: none found. Handlers resolve items through `SheetsMcp.resolveItem`/`SlidesMcp.openRef`/services with `AccessService` (sheets_mcp_support.dart:101-145, slides_mcp_support.dart:70-110); comment/version/drive/sharing tools call the same services. Inherits S-01/S-05/S-08 via `drive.move/trash/delete/copy`. The in-app assistant cannot call share/unshare/link/trash/delete (assistant_tools.dart:73-85). `ui:control`: S-22.

## 5. GitHub webhook and board (item 4)
- HMAC-SHA256 with constant-time compare: yes (github_webhook.dart:19-42). Secret missing → 401. Disabled → 202.
- Replay: dedupe on delivery id only (S-16). Pre-auth 10 MB buffering (S-11).
- Board: public reads; writes need sign-in and not blocked; admins by email domain (`serverpod.dev` default, board_config.dart:17,113) relying on verified emails; per-user limits for posts/comments/votes/flags/similar (board_common.dart:38-82) — none for signed-out callers (S-11). SQL uses enum names or parameters only (board_search.dart). Board views never include emails (board_views.dart:17).

## 6. URL fetching / SSRF (item 5)
- Image proxies (`file.fetchImage`, `sheets.fetchImage`, `writeExport.fetchImage`, export image resolver): `SafeImageFetcher` — S-13.
- Script `UrlFetchApp`: `UrlFetchProxy` validates scheme/port/userinfo/metadata hosts/numeric hosts, blocks private/reserved v4/v6 incl. NAT64/6to4, pins the resolved address in `connectionFactory`, re-validates every redirect hop (≤5), 10 MB request/response, ≤60 s timeout, strips cookies, per-user daily quotas (script_service.dart:665-685). Good. Feature off in production.
- Outbound to fixed hosts only: Resend, GitHub, Jev/Gemini (no user-controlled URLs found).
- No link-preview fetcher found.

## 7. File uploads (item 6)
- Size: per kind (file_service.dart:52-59), declared size enforced by storage upload description `maxFileSize` (`:206-214`) and by `/files/upload` (`file_routes.dart:189-200`); Drive files ≤ `maxFileUploadBytes` (50 MB) + quota + rate limits (drive_file_service.dart:70-76,254-292).
- Content type: image kinds sniffed at completion (file_service.dart:232-248); Drive files sniffed (`FileTypeSniffer`), served only as attachment with nosniff/CSP sandbox/CORP (file_routes.dart:31-37,121-146). Import sources not sniffed (S-14). S-18 for `file.getUrl`.
- Storage keys: `files/<kind>/<uuid>/<sanitized name>` (`_safeName` strips separators, `[^A-Za-z0-9._ -]`, file_service.dart:63-70) and `drive/<authUserUuid>/<fileUuid>/<ascii name>` (drive_file_service.dart:60): no traversal.
- Signed URLs: 15 min (`signedUrlLifetime`, `FileUrlTokens.lifetime`); upload descriptions 30 min. Download/upload tokens: HMAC-SHA256 over purpose|file|user|size|expiry, constant-time compare (file_url_tokens.dart). Key derived from `fileUrlSecret` → `jwtHmacSha512PrivateKey` → `serviceSecret`; random per-instance fallback if none (breaks multi-instance, not security).

## 8. Linked Sheets charts (item 8)
`SlidesChartService.listCharts/resolveSnapshot/checkLinks` require ≥ Viewer on the **source spreadsheet** (and `nonEditorsCanExport` for data) via `AccessService.effectiveRole` (slides_chart_service.dart:244-261,350-377), accept item or space uuid but check the resolved item; trashed → refused; ≤50 probes and per-user limiters. Viewers without spreadsheet access see only the deck's stored snapshot (spec 06 §1). OK.

## 9. Secrets and logging (item 9)
- `config/passwords.yaml` is git-ignored (wonky_server/.gitignore:18) and was never committed (`git log --all` empty). `passwords.example.yaml` contains **real-looking development/test DB and Redis passwords** (matching docker-compose); dev-only, acceptable but should be `CHANGE_ME`.
- No API keys/private keys found in tracked files (test fixtures only).
- Google client secret never printed (google_idp.dart:50-55). Tokens/secrets not logged. S-17 for email bodies. Export image failures log the remote URL at debug (server_images.dart:151) — fine.
- Users' own AI keys stored unencrypted (documented in spec 13 §2).

## 10. Input bounds (item 10)
See S-19 and S-11. Good examples: names 1–255 (common/names.dart), comment bodies 10 000, share ≤100 emails, `getUrls`/`getUsers` ≤200, `ensureSubscribed` ≤200, `getOps` ≤1000, chart probes ≤50, drive list/search page clamps, board title/body caps, `fileMetaJson` cap, front matter 64 KB, MCP JSON-RPC batches refused.

## 11. Positive controls verified
- Every non-auth endpoint except Board/Feedback/Meta/E2E sets `requireLogin`.
- `AccessService.require` returns `notFound` without access (no existence oracle), owner/grant/inherited/link roles, expiry filtered.
- Commenter op-shape validation on Write ops (ot_service.dart:162-174); viewers can't submit.
- Sheets/Slides writes checked against sync membership per batch.
- Comment visibility rule honoured on list/get/watch.
- Download route re-checks the ACL with the token's user (no token-only access).
- E2E support refused outside development/test and codes only captured there.
- AI previews and assistant threads bound to the user.
- Cookie auth `secure`, `SameSite=lax`, `allowedOrigins` in production config.

## 12. Unverified / to confirm at runtime
- S-02 end-to-end (which kind `SpaceKinds.recorded` resolves when two items share a space; whether the deck owner's own Slides sync breaks).
- Whether Serverpod applies `maxRequestSize` to WebSocket stream messages.
- Whether S-01's victims see trashed items they own inside someone else's trashed folder in their Trash view.
