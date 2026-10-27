# 18 · Publications and submissions (M14, built)

Lets a blog (or any site with an editorial queue) take stories written in Wonky Write. The blog
links to Wonky Write; the contributor writes in a normal Wonky document and presses **Submit**;
the story lands in the blog's review queue, where a moderator approves it, asks for changes or
declines it. Moderators read and comment on the document in Wonky, and their decisions come
back into the document as messages.

Status: **built** (M14); open items in §13. The developer
guide for blog owners is [`docs/blog-integration.md`](../docs/blog-integration.md). As-built
notes are in §13.

## 1. Decisions

| # | Decision | Reason |
|---|----------|--------|
| P1 | The blog registers a **publication** in Wonky once; the contributor link carries only its public id (`/write/new?publication=pub_…`) | The link can't choose where content goes, and holds no secret. A static link works on a static site |
| P2 | No secret ever lives in a link or a document. The signing secret and the API key stay on the server and with the blog | Sharing, copying, exporting, versions, MCP and AI can't leak them |
| P3 | Any editor of the document can submit | The blog's moderators are the gate; the worst a wrong submission does is add an entry to the queue |
| P4 | The action is called **Submit** (not *Publish*) | It goes to review, not live |
| P5 | Wonky pushes each submission to the blog's webhook, signed per [Standard Webhooks](https://www.standardwebhooks.com/); the blog calls Wonky's publication API back with a status and messages | Small amount of code on the blog side; signatures and timestamps make forged or replayed deliveries detectable |
| P6 | Each moderator account gets **Commenter** on a submitted document (06 §1: read, comment, suggest), and loses it when the submission is withdrawn, declined or disconnected | Inline comments and suggestions are the best way to give feedback on writing |
| P7 | The webhook and all outbound calls go through the SSRF-safe client of the URL fetch proxy (13 §1) | The webhook URL is user-supplied |
| P8 | A submit names a version (07 §5) and records the revision; the blog approves the revision it received | Moderators approve exactly what they reviewed; authors and moderators see diffs between submissions in version history |

## 2. Concepts

- **Publication**: a registered destination, owned by one Wonky user (the blog owner). It has a
  name, a site URL, a webhook URL, moderators, submission fields, an optional template and terms
  link, a signing secret and an API key.
- **Submission**: the link between one Write document and one publication. A document has at
  most one submission. It starts as a draft when the contributor starts from the link and
  becomes *In review* with the first submit.
- **Submitted revision**: one submit of a submission (the first one or a resubmit): document
  revision, named version, fields, the images it references.
- **Feedback thread**: one document-level comment thread per submission (Write 08 §1,
  `anchorKind: document`) where the publication's messages appear and authors reply.

### 2.1 Submission status

```
 draft ──submit──▶ inReview ──(blog)──▶ changesRequested ──resubmit──▶ inReview
   ▲                  │  ▲                                                 │
   │                  │  └──────────────── resubmit (changes) ─────────────┘
   │                  ├──(blog)──▶ declined            (final; Submit hidden)
   │                  └──(blog)──▶ published ──submit update──▶ inReview (publicUrl kept)
 inReview / changesRequested ──withdraw──▶ withdrawn ──submit──▶ inReview
```

`declined` is final for that submission: the contributor can disconnect and start a new one.
Wonky sets `inReview` itself at a submit (the chip shows *Submitting…* until the blog accepts
the webhook; if every retry fails the status goes back, §7.2); every other transition comes
from the blog (§7.3). Withdrawing (moderator access removed) leaves `withdrawn`; submitting
again is allowed.

## 3. Contributor flow

1. **The blog** links to `https://wonky.work/write/new?publication=pub_7Hk2…`, optionally with
   `&ref=<blog's own id>` (≤ 64 chars, `[A-Za-z0-9_-]`, e.g. a call-for-posts id; passed back
   in every webhook, never trusted for anything).
2. **Sign in or sign up** if needed: the auth guard keeps the whole route with its query in
   `next` (03 §2). Sign-up still creates the welcome items (04 §1.1) but lands on `next`.
3. **`/new` with `publication`** (online only; offline it shows "Starting a story for a
   publication needs a connection" with *Try again*):
   - `publication.resolve(publicId)` returns the public card (§9.1) and the caller's open
     submissions for it (`draft` or `changesRequested`, role ≥ editor). Unknown, disabled or
     blocked: an empty state "This link doesn't work anymore" (blocked: "<Name> isn't accepting
     stories from you") with *Go to Wonky Write*.
   - **Consent dialog**, once per user and publication (repeated when the publication's site
     host, webhook host or terms URL changes):
     ```
     ┌ Write for Serverpod blog ─────────────────────────────────┐
     │ 📰 Serverpod blog · blog.serverpod.dev ✓                  │
     │ You'll write in your own Wonky document. When you press   │
     │ Submit, Serverpod blog receives:                          │
     │  • the text and images of the document                    │
     │  • the fields you fill in and your display name           │
     │ and its moderators can read and comment on the document.  │
     │ ☐ I agree to Serverpod blog's contributor terms ↗         │
     │                               [Cancel]  [Start writing]   │
     └───────────────────────────────────────────────────────────┘
     ```
     Unverified publication (§8.2): the line shows the **webhook host** instead of the site host
     and "Wonky hasn't verified that this publication belongs to blog.serverpod.dev". The terms
     checkbox shows only when the publication has a terms URL and is required then. With open
     submissions the dialog lists them first: *Continue "My story"* rows and *Start a new story*.
   - *Start writing* calls `publication.startSubmission(publicId, ref?)`: the server creates a
     Write document in the user's *My files* root (from the publication's template, or empty;
     counted in the user's quota, Drive 03), the submission (`draft`) and the consent record,
     and returns the document uuid; the client replaces the route with `/d/:uuid`.
4. **Writing** is a normal document: co-authors, comments, suggestions, offline editing.
5. **Submit** (§4.2) sends the current revision. The chip shows **In review**.
6. **Feedback**: moderators comment and suggest in the document as themselves; the blog's
   status messages appear in the feedback thread (§5) and notify the document's editors.
7. **Resubmit / Submit update** after changes; **Withdraw** from the chip's popover.

## 4. Write UI

### 4.1 Title row

Documents with a submission show, left of *Share* (Write 05 §3.2):

| Element | Widget | Behaviour |
|---------|--------|-----------|
| Status chip | `SubmissionStatusChip` (`wonky_app`; Lucide `newspaper`) | Hidden for `draft`. *In review* (neutral), *Changes requested* (warning), *Declined* (muted), *Published* (success). Click → status popover (§4.3). Shown to every role |
| Submit | `ShadButton.secondary` (Lucide `send`) | `write.submission.submit`. Label: *Submit* (`draft`), *Resubmit* (`changesRequested`, or `inReview` with changes), *Submit update* (`published` with changes). Disabled with a tooltip: offline ("Submitting needs a connection"), no changes since the last submitted revision ("No changes since you submitted"). Hidden for role < editor, `declined`, and a disabled publication. Tooltip "Submit to Serverpod blog". Between 640 and 1200 px icon only |

### 4.2 Submit dialog

```
┌ Submit to Serverpod blog ───────────────────────────────────┐
│ 📰 Serverpod blog · blog.serverpod.dev ✓                    │
│ Title*        [ How we sped up our CI ×3          ]         │
│ Summary       [ A short look at …                 ]         │
│ Tags          [ dart ×] [ ci ×] [ + ]                       │
│ Cover image   [thumbnail] [⇪ Upload image] (Replace, Remove)│
│ Note to the moderators  [                          ]        │
│ ⚠ 2 open suggestions aren't included. Review them first?    │
│ Comments in the document stay in Wonky (moderators can see  │
│ them).                                                      │
│                                      [Cancel]  [Submit]     │
└─────────────────────────────────────────────────────────────┘
```

- Fields are the publication's configuration (§8.1). First submit prefills: title = document
  title (or the first heading), summary = the first paragraph (≤ 300 chars); the cover is never
  prefilled (below). Later submits start from the stored values.
- **Cover image** (T-19): uploaded in the dialog, not picked from the document. An image in the
  text would be shown twice by blogs that put the cover above the post (and at full size).
  The field (`ImageFieldSpec` of the form dialog, `wonky_app`) shows a 16:9 thumbnail (muted
  box with *No cover* when empty), *Upload image* (*Replace* once set) and *Remove*, and the
  hint "Shown with your post. It isn't added to the document." *Upload image* opens the image
  picker (png, jpg, gif, webp; Write 04 §17.1), runs the storage pre-check and uploads the file
  as an **image of the story's document** (`StoredFileKind.image`, the document's item: counted
  in its owner's quota, readable by its moderators, deleted with it) without inserting it into
  the text. It is uploaded with `imageProfile: cover`, so the server stores it as a **1200 × 630
  WebP**, cropped to fill around the most salient region (12 §1.1 *Image optimization*); the
  thumbnail shows the picked file. *Submit* waits for a running upload. A stored cover (also one picked from the
  document's images before T-19) shows as the thumbnail. A required cover without an image:
  toast "Pick a cover image."
- Open suggestions are sent as the original text (Write 07 §4.1 `suggestions: original`); the
  warning links to the first one.
- *Submit* calls `submission.submit(itemUuid, fields, expectedRevision)`; it waits up to 10 s
  for the delivery (§7.2). Accepted: toast "Submitted to Serverpod blog", chip *In review*. Not
  accepted in time: chip *Submitting…*, toast "Serverpod blog didn't answer yet. We'll keep
  trying." (§7.2).

### 4.3 Status popover

Publication card (name, host, ✓), status with time and actor ("In review · submitted by Anna 2
h ago, revision 3"), the last message (excerpt, *Open thread* scrolls the margin to the feedback
thread), *View post ↗* (when `publicUrl`), the submission history (submitted revisions with
*Compare* → version history), *Withdraw submission* (`inReview`, `changesRequested`; confirm),
*Disconnect from Serverpod blog* (not while `inReview`/`changesRequested`; §4.5).

### 4.4 Menus and commands

File menu (Write 05 §7.1), after *Share ▸*: *Submit to <Name>…* (`write.submission.submit`),
*Submission status* (`write.submission.showStatus`), *Withdraw submission*
(`write.submission.withdraw`) — only for documents with a submission.

| Command | Undo |
|---------|------|
| `write.submission.submit {fields?}` | Not undoable (sent outside Wonky; *Withdraw* is the counterpart) |
| `write.submission.withdraw` | Not undoable; confirms |
| `write.submission.disconnect` | Undoable (domain `drive`, server inverse: `reconnect` clears `disconnectedAt`) |
| `write.submission.showStatus` | — (view) |
| `shell.settings.open {section: publications}` | — |

`requiredRole: editor` except `showStatus` (viewer). Enabled flags: `online`, `hasSubmission`.

### 4.5 Copies, trash and history

- *Make a copy*, templates and export never take the submission along.
- Trashing a document withdraws an open submission (`submission.withdrawn`, reason `trashed`);
  restoring does not resubmit. Purging deletes the submission row (history stays in the blog).
- Disconnecting sets `disconnectedAt`, removes moderator grants and sends
  `submission.disconnected`; undo within the session reconnects (no webhook for the
  reconnect — the next submit carries the same submission id).
- Version restore doesn't change the submission.

## 5. Moderators and feedback

### 5.1 Moderator access

- Moderators are Wonky accounts the publication owner lists (§8.1; pending emails are converted
  on sign-up, like invites, 06 §2).
- **First submit** grants each moderator Commenter on the document: a `DriveItemPermission` with
  `viaPublicationId` set (§6), `grantedById` = the submitter, no share notification or email. A
  moderator who already has a role keeps the higher one and gets no extra row.
- Withdraw, decline, disconnect, trash and removal of a moderator from the publication delete
  the `viaPublicationId` rows; moderators added later get access to the publication's
  `inReview`/`changesRequested` submissions. `published` submissions keep access (updates are
  reviewed the same way).
- The share dialog (06 §5) shows these rows as "Moderator · Serverpod blog" with Commenter; the
  owner (or an editor who may share) can remove them. A direct `share`/`updateRole` for that user
  turns the row into a direct grant (`viaPublicationId` cleared).
- Moderators open documents from the blog's queue (`documentUrl` in the webhook); submissions
  don't appear in their *Shared with me* until opened (06 §2.2 behaviour for state rows).

### 5.2 Feedback thread

- Created by the first message from the blog (§7.3): a `document` thread whose comments have
  `authorKind: system` and `publicationId` set (07 §2.1). They render with the publication's name
  and the `newspaper` icon. Status messages start with a status line ("**Changes requested**").
- Editors and moderators reply as themselves. Replies by anyone except the publication itself are
  sent to the blog as `comment.created` (§7.1). Other threads stay in Wonky.
- Resolving the thread is allowed; a new message from the blog reopens it.

### 5.3 Notifications

New `NotificationKind.submission` (07 §4) for status changes and blog messages, to every editor
of the document (and the submitter). New category `submissions` in Settings › Notifications:
default in-app + immediate email (rare and important). Payload: publication name, status,
message excerpt; link to the document with `?comment=<feedback thread>`.

## 6. Data model (server, `platform/publications/`)

The models are in `wonky_server/lib/src/platform/publications/models/` (all tables
`serverOnly`; clients get the `*View`, `PublicationCard`, `PublicationSettings` and
`PublicationSecret` classes):

| Table | What |
|-------|------|
| `publication` | Owner, `publicId` (`pub_` + 22), name, site URL (origin), webhook URL, `verifiedHost`, template item, terms URL, `fields` (`PublicationFields`, JSON column), signing secret (+ previous one during a 24 h rotation), API key hash and last 4, enabled |
| `publication_moderator` | Email (lower case) and the user once an account has it |
| `publication_consent` | Per user: a hash of what was agreed to (shown host, webhook host, terms URL) |
| `publication_block` | Users the publication refuses |
| `submission` | One per document (`itemId` unique): `uuid` (public `sub_<uuid>`), `ref`, `status`, `statusBeforeSubmit` (restored when a delivery fails), `delivery` (`pending`/`failed`/null), `values` (`SubmissionValues`, JSON), `publicUrl`, `feedbackThreadId`, `disconnectedAt` |
| `submission_revision` | One per submit: `sequence`, document `revision`, named `versionId`, values, and the **`payload`** sent (served again by `GET …/content`) |
| `submission_asset` | Images a submit referenced (`fileUuid`); the API key may download only these |
| `publication_delivery` | The webhook outbox: `webhookId` (`msg_…`), type, payload, `sequence`, attempts, `nextAttemptAt`, `leaseUntil`, last status and error, delivered/failed times |

Changes to existing models: `DriveItemPermission.viaPublicationId` (FK, cascade: deleting a
publication removes its moderator grants; 06 §2) and `PermissionView.viaPublication` (the
share dialog's "Moderator · <name>"), `Comment.publicationId` (FK, set null) and
`CommentView.authorLabel` (07 §2.1), `NotificationKind.submission` (07 §4),
`ActivityType.submission` (05 §5; summary `{publication, action: submitted | withdrawn |
disconnected | reconnected | status, status?}`).

## 7. Protocol

### 7.1 Webhooks (Wonky → blog)

`POST <webhookUrl>`, `Content-Type: application/json`, headers `webhook-id`,
`webhook-timestamp` (Unix seconds) and `webhook-signature` (`v1,<base64 HMAC-SHA256 of
"<id>.<timestamp>.<body>">`; during rotation two space-separated signatures). The blog must
check the signature, reject timestamps more than 5 minutes off and drop repeated ids.

| Type | When | Extra fields |
|------|------|--------------|
| `submission.submitted` | Every submit | `sequence`, `revision`, `fields`, `markdown`, `assets`, `submittedBy`, `note` |
| `submission.withdrawn` | Withdraw or trash | `reason`: `author` \| `trashed` |
| `submission.disconnected` | Disconnect (also after `published`) | — |
| `comment.created` | Reply in the feedback thread | `comment {id, body (Markdown), author {name, wonkyUserId, isModerator}}` |
| `publication.ping` | *Send test* and saving a new webhook URL | — |

```json
{
  "type": "submission.submitted",
  "createdAt": "2026-10-20T09:14:03Z",
  "publicationId": "pub_7Hk2…",
  "submission": {
    "id": "sub_0192…", "ref": "cfp-2026", "status": "inReview",
    "documentUrl": "https://wonky.work/write/d/0192…"
  },
  "sequence": 2, "revision": 418,
  "fields": { "title": "How we sped up our CI ×3", "summary": "…", "tags": ["dart", "ci"],
              "coverImage": "ast_0192…" },
  "note": "Fixed the code samples, thanks!",
  "markdown": "# How we sped up our CI ×3\n\n…![Build graph](https://wonky.work/api/pub/v1/assets/ast_0192…)…",
  "markdownFlavor": "gfm",
  "assets": [{ "id": "ast_0192…", "name": "build-graph.webp", "type": "image/webp", "bytes": 48213,
               "url": "https://wonky.work/api/pub/v1/assets/ast_0192…" }],
  "submittedBy": { "name": "Anna Berg", "wonkyUserId": "0191…" }
}
```

- `markdown` is the Write Markdown export (Write 07 §4) in the document's flavor
  (`markdownFlavor`: `gfm` or `wonky`, Write 11 §3.3) with suggestions as original, no front
  matter and no comments; `wonky-file://` images become asset URLs, `https://` images stay.
- `fields.coverImage` is the asset id of the cover, which is always in `assets` (and a
  `submission_asset`, so the API key may download it). The cover is accepted when it is an
  image in the text or a ready image file of the story's document (uploaded in the submit
  dialog, §4.2); anything else is dropped, and a required cover that isn't one is refused
  ("Upload a cover image.").
- Asset URLs need the API key (§7.3). The blog should download them when it receives the
  webhook; they work as long as the image exists in Wonky.
- No email addresses are sent. `wonkyUserId` is the profile uuid (for blocking, §7.3).

### 7.2 Delivery

- Sent by the server through the SSRF-safe client (P7: resolve, block private/link-local/
  metadata ranges, pin the address, https on port 443 only, no redirects), 10 s
  timeout, response body ignored beyond 4 KB. 2xx = accepted.
- `submission.submit` writes the `PublicationDelivery` row in the same transaction as the
  `SubmissionRevision`, then tries once while the client waits (≤ 10 s). Accepted →
  `status = inReview`, `delivery = null`. Otherwise `delivery = pending` and the outbox retries
  with the same `webhook-id`: 1 min, 5 min, 30 min, 2 h, 6 h, 12 h (`wonky.publicationSweep`,
  every minute, under a lease; at most 4 concurrent deliveries per publication, oldest first).
  After the last failure: `delivery = failed`, the status stays where it was (the chip drops *Submitting…*), the
  submitter gets a `submission` notification ("Serverpod blog couldn't receive your
  submission"), and the owner sees it under *Deliveries*.
- Deliveries are delivered at least once and may arrive out of order; `sequence` lets the blog
  ignore an older submit.

### 7.3 Publication API (blog → Wonky)

Relic routes under `https://wonky.work/api/pub/v1/` (`wonky_server/lib/src/web/routes/`),
`Authorization: Bearer wpk_…` (the publication's API key; every call is scoped to that
publication's submissions), JSON, errors `{ "error": "<code>", "message": "…" }`. Header-only
checks before the body (13 §1), 1 MB body cap, 120 requests/min per key (Redis counter like the
MCP limit, 13 §4).

| Call | Purpose |
|------|---------|
| `GET submissions?status=&after=&limit=` | List for reconciliation (cursor paging) |
| `GET submissions/{id}` | Status, `documentUrl`, last `sequence`/`revision`, fields, `publicUrl` |
| `GET submissions/{id}/content?sequence=` | The `submission.submitted` payload of that submit (from its named version), for a missed webhook |
| `GET assets/{assetId}` | Image bytes; only assets listed in a `SubmissionRevision` of this publication; streamed like downloads (13 §6) |
| `POST submissions/{id}/status` `{status, message?, publicUrl?}` | `inReview`, `changesRequested`, `declined`, `published` (`publicUrl` required, https). Transitions per §2.1; `409 invalidTransition` otherwise. `message` (Markdown, ≤ 10 000 chars) goes into the feedback thread |
| `POST submissions/{id}/messages` `{body}` | A message in the feedback thread without a status change |
| `POST blocks` `{wonkyUserId}` · `DELETE blocks/{wonkyUserId}` | Stop a user from starting or submitting stories to this publication |

A status call or message on a withdrawn or disconnected submission is `410 gone`.

## 8. Publication setup (blog owner)

### 8.1 Settings › Publications

New Wonky Work settings section `publications` (04 §4.1): a list of the user's publications
(≤ 10) with an empty state "Let people write for your blog in Wonky Write" and *New
publication*. The editor:

- **General**: name, site URL, webhook URL, enabled, terms URL, template (picker of the owner's
  Write documents; its content is copied at start, comments not).
- **Submission fields**: title (always, required) plus toggles for summary, tags (optional list
  of allowed tags), cover image, author bio, note to the moderators; each optional or required.
- **Moderators**: add by email (≤ 20), remove.
- **Verification** (§8.2): status and *Verify*.
- **Credentials**: publication id and contributor link (copy buttons), signing secret (shown once
  at creation; *Rotate*, old one signs for 24 h), API key (*Create*, shown once; *Rotate*
  revokes the old key at once).
- **Deliveries**: the last 50 with type, time, HTTP status, error; *Resend*; *Send test*
  (`publication.ping`).

Saving a new webhook URL sends a `publication.ping`; a non-2xx answer shows the error and saves
the URL anyway (the blog may deploy its receiver later). Settings changes are not undoable
(like sharing, 08 §2).

### 8.2 Verification

The owner serves `https://<site host>/.well-known/wonky-publications.json`:

```json
{ "publications": ["pub_7Hk2…"] }
```

*Verify* fetches it through the SSRF-safe client; when it lists the publication,
`verifiedHost` = the site host. Changing the site URL clears verification. Verified publications
show the site host with ✓ in the consent and submit dialogs; unverified ones show the webhook
host and a warning (§3), so a copied name can't pretend to be another blog.

### 8.3 Blog-side checklist (also in the developer guide, §12 PUB-7)

1. Create the publication, verify the site, store the signing secret and API key server-side.
2. Add the *Write for us* link.
3. Webhook receiver: check the signature (any Standard Webhooks library), dedupe by
   `webhook-id`, upsert the queue entry by `submission.id`, ignore an older `sequence`, download
   the assets, answer 2xx fast.
4. Moderation UI: show the Markdown, link *Open in Wonky* (`documentUrl`), and call the status
   API for *Request changes*, *Decline* and *Publish* (with the post's URL).

## 9. Endpoints and MCP

### 9.1 `PublicationEndpoint` (`publication`, signed in)

`resolve(publicId)` → `PublicationCard {name, siteHost, verified, webhookHost, termsUrl,
fields, ownerName, consentNeeded, openSubmissions}`; `startSubmission(publicId, ref?,
consent?)` → item uuid; owner-only: `list()`, `create(...)`, `update(...)`, `verify(uuid)`,
`rotateSecret(uuid)`, `createApiKey(uuid)` → key once, `setModerators(uuid, emails)`,
`deliveries(uuid)`, `resend(deliveryId)`, `sendTest(uuid)`, `delete(uuid)` (disconnects every
submission, sends nothing).

### 9.2 `SubmissionEndpoint` (`submission`)

`get(itemUuid)` → `SubmissionView?` (viewer+); `submit(itemUuid, values, agreed)` (editor+,
publication enabled, not blocked, not `declined`; `agreed` confirms changed terms): names a
version, exports that version's revision and sends it; `values.coverImage` is the file uuid of
the cover (uploaded through `file.createUpload`/`completeUpload` as an image of the document,
§4.2, §7.1); `withdraw(itemUuid)`,
`disconnect(itemUuid)`, `reconnect(itemUuid)` (editor+). Changes reach open editors as a
`DriveChange` of kind `updated` for the item; Write's `SubmissionController` reloads on it.

### 9.3 MCP and AI

**Not planned** (only on a feature request): headless `write.get_submission` and
`write.submit` tools. Agents can use the commands through the UI bridge
(`ui.invoke_command`, `write.submission.*`). The AI assistant can't submit, withdraw or
disconnect (like sharing, 13 §1).

## 10. Limits and abuse

- ≤ 10 publications per owner, ≤ 20 moderators per publication.
- Per user and publication: ≤ 10 `startSubmission` and ≤ 20 submits per day
  (`limitExceeded` "You've sent a lot to Serverpod blog today. Try again tomorrow.").
- Markdown payload ≤ 5 MB (`tooLarge` in the submit dialog); fields ≤ 2 000 chars each.
- Blocks (§7.3) stop `startSubmission` and `submit` for that user.
- Account deletion: an owner's publications are deleted (submissions disconnected, moderator
  grants removed); a contributor's documents follow 13 §2 and their open submissions are
  withdrawn.

## 11. Security and privacy summary

Rows in 13 §1: forged contributor links (P1, §8.2), SSRF through the webhook URL (P7), forged or
replayed deliveries (signatures, timestamp window, ids), stolen API keys (hashed, shown once,
rotate, scoped to one publication, rate limited), moderator access beyond the submission
(Commenter only, removed on withdraw/decline/disconnect), spam and floods (§10). Privacy (13 §2):
submitted content goes to a third party the user chose, after consent; the signing secret is
stored unencrypted (it must sign) with the same caveat as user AI keys; the privacy policy (13
§5) names submissions.

## 12. Work packages

| WP | Scope | Depends on |
|----|-------|------------|
| PUB-1 | Models (§6) and migration, `PublicationService`, `SubmissionService`, access rules, moderator grants (06), feedback-thread comments (07) | — |
| PUB-2 | Outbound: shared SSRF-safe client extracted from `url_fetch_proxy.dart`, Standard Webhooks signer, outbox and `wonky.publicationSweep` | PUB-1 |
| PUB-3 | Publication API routes (§7.3), API keys, rate limit, `.well-known` verification | PUB-1 |
| PUB-4 | Settings › Publications (§8.1) | PUB-1–3 |
| PUB-5 | Write: `/new?publication=`, consent dialog, Submit button and dialog, status chip and popover, commands, File menu, notifications category | PUB-1, PUB-2 |
| PUB-6 | MCP tools, activity entries, legal pages | PUB-5 |
| PUB-7 | Developer guide for blog owners with a sample receiver (Dart, Relic) | PUB-3 |
| PUB-8 | Tests: services and API (access matrix, transitions, rotation, blocks), webhook signing vectors, SSRF matrix reused, delivery retries with a fake receiver (tests allow a loopback receiver through a test-only override, never in staging/production), widget tests and goldens (light/dark), E2E journey J-P1: link → sign up → write → submit → request changes → resubmit → publish | all |

## 13. As built (M14)

- **Server**: `platform/publications/` (`PublicationService`, `SubmissionService`,
  `PublicationWebhooks` outbox, `PublicationApi` behind `web/routes/publication_api_route.dart`,
  `PublicationHttp` on the SSRF-safe `UrlFetchProxy` with https/443 only and no redirects,
  `PublicationsFutureCall` with `wonky.publicationSweep` every minute, deliveries purged after 30
  days). Hooks: trash/restore (`DriveTrash`), feedback-thread replies (`CommentService.reply`),
  pending moderators linked at sign-up (`UserService.ensureProfile`), direct shares turn a
  moderator grant into a direct one (`SharingService`).
- **Moderator access** is synced at every submit, status change, withdraw, disconnect, trash
  and restore. A moderator who signs up later, or whom an editor removes in the share dialog,
  gets access back with the next submit or status change.
- **Templates**: the template's text is copied without comments and with suggestions accepted;
  its images are copied into the new document (they belong to the contributor).
- **Client**: `wonky_app` (`PublicationRepository`, Settings › Publications
  `PublicationsSection`, `startPublicationStory` for `/new?publication=`, `SubmissionUndoHandler`
  for disconnect, notification, activity, comment and share-dialog rendering) and Write
  (`features/publish/`: `SubmissionController` on `WriteDocumentController.submission`,
  `SubmissionTitleActions`, the submit dialog, `write.submission.*` commands, File menu items,
  which stay listed but disabled for documents without a submission).
- **Tests**: server `test/unit/publications/` (signing vector of the guide, rules) and
  `test/integration/platform/publications/` (flow, API over HTTP, owner endpoints, the uploaded
  cover image in `submission_cover_test.dart`); client `wonky_app/test/publications/` and
  `wonky_write/test/features/publish/`.
- **Open**: light/dark goldens of the dialogs and chip; the E2E journey J-P1; moderators who
  sign up later get access only with the next submit or status change.
- **Not planned** (only on a feature request): MCP tools (§9.3); Write `?comment=` deep links,
  so notifications open the publication's thread (they open the document).
