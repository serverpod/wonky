# 07 · Collaboration: Presence, Comments, Mentions, Notifications, Version History

This spec defines the **shared** collaboration framework. App specs define how each feature
anchors to content (text ranges vs. cells) and how versions are captured.

**Edit propagation.** Content edits travel over each app's own stream, not over presence:
Write ops over the document stream (OT, [Write 03](wonky_write/03-sync-protocol.md)),
spreadsheet and deck ops over the RevLog stream ([17](17-revlog-sync.md)). The server commits
an op, posts it on the bus at once (`immediate: true`, also across instances) and every other
open client applies it, so a collaborator sees an edit about one round trip after it was made
(RevLog budgets: p95 < 250 ms on one instance, < 400 ms across two, 17 part 7 P1–P2).
Presence (cursors, selections, hints) is separate and may lag up to the bus flush interval
across instances (13 §4).

## 1. Presence

### 1.1 Protocol
Presence is **ephemeral** (never stored in Postgres). It runs over a Serverpod streaming method:

```
PresenceEndpoint.join(String itemUuid, Stream<PresenceUpdate> updates) → Stream<PresenceEvent>
```

- Client sends `PresenceUpdate { state: active|idle|away, cursor: PresenceCursor?, viewport: … }`
  on change (throttled to 10/s; cursor updates coalesced).
- Server keeps a per-item roster in memory and broadcasts via `session.messages` channel
  `presence:<itemUuid>` (global scope with Redis when running multiple instances; local
  otherwise). Each server instance relays relevant events to its connected clients.
- `PresenceEvent` variants (sealed base model): `Roster(List<Participant>)` (on join),
  `Joined(Participant)`, `Left(sessionId)`, `Updated(sessionId, cursor, state)`.
- `Participant { sessionId, userId, displayName, avatarUrl, colorIndex, role, actorKind
  (user|mcp|ai), state }`. The same user in two tabs appears as two sessions, grouped in UI.
- Idle after 60 s without input, away when the tab/window is hidden. Sessions are dropped 30 s
  after the stream dies.
- With several instances each session also sends a `beat` every 30 s; sessions not heard of
  for 90 s leave the roster (their instance crashed or the `bye` was lost;
  [13 §4](13-security-and-operations.md)).
- **Limits**: the server drops updates with a cursor (`cursorJson`) over 8 KB or a `mode` /
  followed session id over 64 chars, and relays at most 20 updates per second and session
  (more are coalesced: the latest one is sent when the second ends).
- **Access re-check**: a joined session re-resolves the user's role when the item's ACL
  changes (the user's drive signal for the item) and every 5 minutes (grants that expire send
  no signal). Without viewer access the stream ends with `notFound`, like a join without
  access.
- **MCP/AI presence**: when an agent edits headlessly, the server injects a transient
  participant (`actorKind: mcp`, name "Claude via MCP (Anna)") so humans see agent activity.

`PresenceCursor` is app-specific JSON:
- Write: **not sent here** — Write cursors travel on the document stream (`CursorUpdate` /
  `RemoteCursor`, Write 03 §1) because they must be ordered with ops; the presence stream only
  carries the roster/state for Write.
- Sheets: `{sheetId, activeCell: {rowId, colId}, ranges: [{r1,c1,r2,c2 as ids}], editing: bool}`.
- (v2) Slides: `{slideId, selection: [elementId], editingElementId?, textSelection?}` — the
  current slide (navigator avatars), selected elements (presence-colored outlines) and the text
  box being edited, which drives the **soft lock** ("Anna is editing" overlay, *Edit anyway*).
  Exact shape and behavior: [Slides 09](wonky_slides/09-collaboration-history.md). Slides also
  uses the presence stream for ephemeral hints (live drag positions) and the presentation
  session (presenter ↔ audience/remote, 03 §1).
- (v2) Drive: no presence (lists update through `drive.watch`); file previews show no avatars.

### 1.2 UI
- `PresenceAvatarStack` in header; follow mode: click an avatar → scroll to their cursor; long-
  press/⋮ → *Follow* (viewport tracks theirs until you scroll).
- Remote cursors/selections drawn with presence colors; name flag on hover or recent activity.
- Join/leave toasts are **off** by default (setting), screen-reader announcements on.

## 2. Comments

### 2.1 Model (server, Postgres; shared by both apps)

```yaml
class: CommentThread
table: comment_thread
fields:
  uuid: UuidValue, defaultPersist=random_v7
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  anchorKind: CommentAnchorKind     # enum: textRange (Write), cell (Sheets), range (Sheets), document,
                                    #   (v2) slide, element (Slides 09), file (P2: page/region of a file preview)
  anchorJson: String                # app-specific anchor (see app specs)
  quotedText: String?               # snapshot of anchored text/cell value at creation
  status: CommentStatus             # enum: open, resolved, orphaned (anchor deleted)
  createdById: int
  createdAt: DateTime
  resolvedById: int?
  resolvedAt: DateTime?
  assigneeId: int?                  # "assign to" via @mention + checkbox
  statusBeforeOrphan: CommentStatus?  # restored if the anchor comes back (undo/revive)
  orphanReasonJson: String?         # e.g. {"kind":"rowDeleted","rowId":…}
indexes:
  comment_thread_item_idx: { fields: itemId, status }
  comment_thread_uuid_idx: { fields: uuid, unique: true }

class: Comment
table: comment
fields:
  threadId: int, relation(parent=comment_thread, onDelete=Cascade)
  authorId: int
  authorKind: ActorKind
  body: String                      # Markdown (inline subset: bold, italic, code, links, mentions)
  mentions: List<int>
  reactions: String                 # JSON {emoji: [userId]}
  createdAt: DateTime
  editedAt: DateTime?
  deletedAt: DateTime?              # soft delete → "Comment deleted"
  systemEvent: CommentSystemEvent?  # enum: resolved, reopened, assigned, suggestionAccepted,
                                    #   suggestionRejected, suggestionWithdrawn,
                                    #   suggestionSuperseded, suggestionReopened
```

### 2.2 Endpoints — `CommentEndpoint` (`comment`)
`listThreads(itemUuid, filter)`, `createThread(threadUuid, itemUuid, anchor, body, mentions,
assigneeId?)` (client-supplied `threadUuid`, idempotent — enables offline creation via a queued
call),
`reply(threadUuid, body, mentions)`, `edit(commentId, body)`, `delete(commentId)`,
`resolve(threadUuid)`, `reopen(threadUuid)`, `react(commentId, emoji)`,
`watch(itemUuid) → Stream<CommentEvent>` (live updates), `updateAnchor(threadUuid, anchor)`
(used by Sheets when cell ids change; Write anchors live in the Delta, see Write spec).

Role rules: Commenter+ can create/reply/react/resolve; authors edit/delete their own comments;
Editors+ can delete any thread. Viewers see comments only if the owner allows it (share setting).

### 2.3 UI (shared widgets in `wonky_app`, anchoring per app)
- **Margin threads** (Write) / **cell indicator** triangle (Sheets) for anchors.
- **Comment card**: avatar, name, relative time, body (Markdown, rendered by `WonkyMarkdown` with
  `MarkdownProfile.comment`: inline styles, links, lists, code blocks; M12), reactions, ⋮ (Edit, Delete,
  Link to comment, Mark unread), reply box, *Resolve* ✓ button. Active thread expands and
  aligns next to its anchor. The comments + reply box part is `CommentThreadBody`, reused by app
  cards (Write's suggestion cards, whose replies are comments in the suggestion's thread). (M12)
  `CommentThreadBody` works through a `CommentThreadActions` interface (reply, edit, delete,
  react, per-comment permissions) and `CommentThreadBody.custom(services, actions, comments)`
  renders `ThreadComment`s. Document comments use `DocumentCommentThreadActions` (the
  `shell.comments.*` commands, no behavior change); the Bugs & improvements board uses its own
  implementation (`shell.board.comment.*`, [16 §7.3](16-bugs-and-improvements.md)).
- **New comment**: `Mod+Alt+M` with selection → composer card with mention autocomplete (`@`),
  *Assign to* checkbox when a mention exists, *Comment*/*Cancel*.
- **Where comments show**: an app may show the open file's comments somewhere other than the
  side panel by setting a `CommentsHost` (`ShellServices.commentsHost`, a `Listenable` with
  `isShown`); `shell.comments.togglePanel`, `shell.comments.create` (without a body) and
  `shell.comments.activate` then show the comments through the host instead of the side panel.
  Write shows them only in the margin next to the page (Write 05 §10, Write 08 §3.2); Sheets
  uses the side panel; (v2) Slides uses the side panel plus pins on the canvas (Slides 09).
- **Comments panel** (side panel, `EditorScaffold.commentsInPanel`): filter tabs
  (`CommentsFilterTabs`) **Open** (default) / **For you** (open threads that mention or are
  assigned to me; Write's margin hides the filter and always shows Open), sort (position / date); each thread links to its
  anchor. Resolved threads are not listed; there is no comments search. An app's
  anchor provider may also implement the optional `CommentPanelOptions` (checked with `is`, so
  existing providers need no change) to add a scope filter (`scopes`/`inScope`, Sheets: This sheet / All
  sheets) and group headers in the position sort (`groupOf`, Sheets: sheet names), and may
  compose new comments next to the anchor instead of in the panel (`composesInline`).
- **Offline** (opt-in per app, `CommentsController.queueOffline`; Sheets 10 §3.7): create,
  reply, resolve/reopen and anchor moves (`updateAnchor`, undo op `updateAnchor`) are queued in
  the user's local store while offline, shown with "Pending — will be posted when you're
  online", and posted in order on reconnect.
- Notification bell? No — notifications are in the account menu and email (see §4).
- All comment actions are commands (`shell.comments.*`) and undoable (create → delete, etc.).

## 3. Mentions
- `@` triggers user autocomplete: users with access first, then other users matching email
  (shows "Will be given access?" prompt: *Share & mention* (as Commenter/Viewer) or *Mention
  without sharing*).
- Mentioning in a comment notifies the user; in Write documents, `@` in body text inserts a
  **link** to the user (rendered as a chip; exported as Markdown link `[@Name](mailto:…)`).

## 4. Notifications

```yaml
class: UserNotification     # named so it does not clash with Flutter's Notification
table: notification
fields:
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  kind: NotificationKind   # mention, reply, assigned, shared, accessRequest, suggestion, scriptFailure,
                           #   (v2) storage (quota warnings and the one-time v2 notice, Drive 03 §9);
                           #   (M12) boardReply, boardStatus, boardClaim (16 §12);
                           #   Slides adds kinds only through Slides 09
  itemId: int?
  payload: String          # JSON
  createdAt: DateTime
  readAt: DateTime?
```

- In-app: the top bar's bell shows the unread count; the **Notifications popover** lists them
  grouped (Today / Yesterday / Earlier) with the actor, kind icon, comment excerpt or share
  message, unread dot and time; All / Unread filter, paging (*Load more*), *Mark all as read*,
  *Notification settings*; opening one marks it read and opens its item. Live via
  `NotificationEndpoint.watch()`.
- Settings › Notifications (`UserPreferences.notificationSettings` JSON): per category
  `inApp` | `email` (in-app and email) | `off` — `mentions` (mentions and assignments),
  `replies`, `shares` (shares, ownership transfers), `accessRequests` (falls back to `shares`
  for older settings), `suggestions` (new suggestions on my files, decisions on mine), (M12) `board` (Bugs &
  Improvements: `boardReply` a comment on a post I wrote or commented on, `boardStatus` a post I
  wrote or voted on was planned, built, shipped, declined or merged, or my post was held or
  removed, `boardClaim` claim warnings, expiry and release or PR-closed notices; default
  in-app + digest email; links `/drive/improvements/p/<n>` and `/t/<n>`,
  [16 §12](16-bugs-and-improvements.md)) — plus
  `digest: bool` (default true). `off` creates no notification.
- Email: **mentions and assignments** set to email are sent right away (a `FutureCall` without
  delay, `NotificationEmailFutureCall`); everything else set to email goes into the **digest
  every 15 min** (`MaintenanceFutureCall.sendDigests`), or one email each when `digest` is
  false. Only unread, not yet emailed notifications of the last 2 days are sent. A
  notification whose kind is set to email when it is created is marked `emailPending`; the
  digest reads only those rows (so in-app notifications never fill its batch), drops the mark
  of rows read, too old or no longer set to email, and every email first **claims** its rows
  (`emailPending` → false, `emailedAt` set, in one conditional update), so the immediate email
  and the digest never send one twice; a failed send gives the claim back and the digest
  retries it. Read notifications are deleted after 90 days and all after a year
  (`notifications.purgeOld`, daily). Links
  point at the item's URL by kind (`<web origin>/write/d/<uuid>`, `/sheets/s/…`, (v2)
  `/slides/p/…`, `/drive/file/…`, `WonkyConfig.itemUrl`, 01 §2.4) and the footer at
  Wonky Work settings › Notifications. (v2) `storage` notifications are in-app only.
- Sending is pluggable (`EmailSender` in `platform/notifications/email/`): the
  [Resend](https://resend.com) HTTP API when the passwords `resendApiKey` and `emailFrom` are
  set, otherwise `LoggingEmailSender` logs the email (development; the Serverpod Cloud email
  service only offers auth templates). Tests install a fake sender.

## 5. Version history (shared framework)

Each app implements a `VersionProvider` (server) that can **capture**, **materialize** and
**restore** a version ((v2) Slides: `SlidesVersionProvider`, compressed deck snapshots in
cloud storage like Sheets, [Slides 09](wonky_slides/09-collaboration-history.md); uploaded
files have no version history — their P2 *versions* are uploads, Drive 02 §9). Version
snapshots never count against the storage quota (Drive 03 §2). Shared models:

```yaml
class: ItemVersion
table: item_version
fields:
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  kind: VersionKind          # auto, named, restorePoint (created automatically before a restore)
  name: String?
  createdAt: DateTime
  authors: List<int>         # users who contributed since previous version
  storageKind: VersionStorage # writeRevision | snapshotFile
  revision: int?             # op-log revision this version represents (Write; Sheets and Slides: the RevLog file revision captured)
  snapshotFileId: UuidValue? # Sheets, (v2) Slides: compressed snapshot in cloud storage
  sizeBytes: int
indexes:
  item_version_item_idx: { fields: itemId, createdAt }
```

Capture policy (both apps): an `auto` version after ≥ 5 min of inactivity following edits, at
most one per 30 min of continuous editing, plus on explicit "Name current version". Auto versions
are thinned over time (keep all for 7 days, then hourly for 30 days, then daily). Named
versions are never thinned.

How the policy runs (`VersionService`): edits are recorded with one atomic upsert of
`ItemVersionState` (editors merged in SQL, so concurrent recorders never lose one). The
minute job `versions.capture` **claims** due items one at a time (`capturingSince`,
`FOR UPDATE SKIP LOCKED`), so overlapping runs and instances never capture an item twice; a
claim older than 10 minutes is taken over, which is also when a failed capture is retried. A
capture reads the state *before* the provider captures (`beforeCapture` first writes pending
bookkeeping, e.g. Write's batched edits) and clears the dirty flag only if `lastEditAt` is
unchanged; an edit recorded during the capture keeps the item dirty from the capture's start.
Providers compute their index during the capture (Sheets' per-sheet counts, Slides' slide list)
instead of re-reading the snapshot they just stored; Sheets encodes its snapshot as a stream.
Nightly thinning (`versions.thin`) works through the items in rounds of 100 under a time
budget.

Sheets and Slides capture a version **at a file revision**: the snapshot is read in one
transaction at the file's head revision, which `ItemVersion.revision` records. A version's
changes and authors are the RevLog ops in its **revision window** (the previous version's
revision, this version's revision], read from `rev_op`, so an edit made offline belongs to the
version whose window contains its commit ([17](17-revlog-sync.md) part 2 §2.5;
[Sheets 10 §5](wonky_sheets/10-collaboration-history.md),
[Slides 09 §4](wonky_slides/09-collaboration-history.md)).

Access: **Editors and Owners** can view version history, name versions and restore;
Commenters/Viewers cannot (as in Google Docs). *Make a copy* from a version requires Editor+.

UI (full-screen route `/…/history`):
- Left: read-only rendering of the selected version with **changes highlighted** (Write:
  insertions/deletions colored per author; Sheets: changed cells outlined per author) and a
  "Show changes" toggle.
- Right panel: versions list grouped by date (expandable groups of auto versions), each with
  name/time/author avatars; ⋮ → *Name this version*, *Restore this version*, *Make a copy*,
  *Download as…*. Filter *Only named versions*.
- Top bar: back arrow ("Back to editing"), current version title, *Restore this version* button.
- Restore creates a `restorePoint` of the current state, then applies the version as a normal
  forward edit (collaborators see it live; it is one undo step for the restoring user). Sheets
  and Slides submit the diff as a recorded server change (`submitServerChange(record: true)`,
  17 part 5 §8), so it is undone with `*.serverChange` (08 §3.3); Sheets first checks the whole
  diff against protected ranges and refuses a restore the user can't fully write.

## 6. Activity dashboard (removed from the UI)
The *Tools › Activity dashboard* dialog (`shell.activity.open`) was removed; the item's activity
feed stays in the drive details panel (suite 05 §3.1). The server side below stays
(`ActivityEndpoint`, view recording) and is kept for a later UI: period selector
(7 / 28 / 90 days) and three tabs:
- **Viewers** (Editors and Owners only): people in the item's share set (owner and grantees, not
  link visitors) who opened it in the period, most recent first, with role, "Viewed …" and view
  count. People who turned their view history off are left out and counted ("2 more people
  turned off their view history").
- **Trends**: unique viewers per day and comments + replies per day (bar charts with a
  semantics summary), for every role.
- **Activity**: the item's activity feed (same widget as the details panel, with paging).

Views are recorded per user and UTC day (`item_view_day`) whenever the item is opened
(`DriveUserStates.recordOpen`: `drive.markOpened`, document connect, invite). The privacy toggle
**"Show my view history"** (`UserActivitySettings.showViewHistory`, default on;
`ActivityEndpoint.setShowViewHistory`) has no UI while the dialog is gone; when off, the user's
views still count anonymously in the trends.
