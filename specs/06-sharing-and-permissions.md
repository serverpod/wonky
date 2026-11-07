# 06 · Sharing and Permissions

## 1. Roles

| Role | Read | Comment | Suggest (Write) | Edit content | Share | Manage (rename, move, trash, version restore) | Transfer ownership / delete forever |
|------|------|---------|-----------------|--------------|-------|-----------------------------------------------|--------------------------------------|
| **Owner** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Editor** | ✓ | ✓ | ✓ | ✓ | ✓ (unless owner disabled "Editors can share") | ✓ | — |
| **Commenter** | ✓ | ✓ | ✓ | — | — | — | — |
| **Viewer** | ✓ | — (can see comments if allowed) | — | — | — | — | — |

`enum Role { viewer, commenter, editor, owner }` (ordered; comparisons with `>=`) lives in
`wonky_core`.

**(v2) What the roles mean per kind.**

| Kind | Viewer | Commenter | Editor | Owner |
|------|--------|-----------|--------|-------|
| Document, spreadsheet | as above | as above | as above | as above |
| Presentation (Slides) | View and **present** the deck (presenter view included); PDF download if allowed | + comments on slides/elements | + edit slides, notes, groups, builds, themes; update linked charts | + transfer, delete forever (full table: [Slides 01 §6](wonky_slides/01-overview.md)) |
| File (uploaded) | Preview; download (unless the owner disabled it) | Same as Viewer (comments on files are P2) | + rename, move, trash, upload a new version (P2), *Open with* into their own drive | + transfer, delete forever |
| Folder | List contents (subject to each item's role) | — | + add/upload items, move items in/out | + transfer |

Converting a file (*Open with*, [Drive 02 §7](wonky_drive/02-files-uploads-previews.md))
needs Viewer on the file; the new item belongs to the converting user. Linked Sheets charts in
a deck render from the deck's stored snapshot for people without access to the spreadsheet;
only users with Viewer+ on the spreadsheet can update them ([Slides 08](wonky_slides/08-charts-from-sheets.md)).

Additional per-item settings (Owner only, in Share dialog ⚙):
- *Editors can change permissions and share* (default on).
- *Viewers and commenters can see the option to download, print and copy* (default on). (v2)
  For uploaded files this hides *Download*; the preview still receives the bytes, so it is
  advisory.
- *Viewers can see comments* (default off).

## 2. Data model (server)

```yaml
class: DriveItemPermission
table: drive_item_permission
fields:
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  userId: int?, relation(parent=user_profile, onDelete=Cascade)   # null when pending invite
  invitedEmail: String?            # for users without an account yet; converted on sign-up
  orgKey: String?                  # (Organizations) "Anyone at <domain>" grant (§2.3); one of userId/invitedEmail/orgKey is set
  role: Role
  inheritedFromId: int?            # folder item the grant was inherited from (null = direct)
  grantedById: int
  grantedAt: DateTime
  expiresAt: DateTime?             # optional expiring access (Editors+ can set for others)
  viaPublicationId: int?           # (M14) moderator grant of a submission (18 §5.1); removed with it
indexes:
  perm_item_user_idx: { fields: itemId, userId, inheritedFromId, invitedEmail, orgKey, unique: true, nulls_distinct: false }
  perm_user_idx: { fields: userId }
  perm_org_idx: { fields: orgKey, itemId }

class: ShareLink
table: share_link
fields:
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  token: String                    # 22-char random url-safe
  role: Role?                      # null = link sharing off ("Restricted")
  createdById: int
  createdAt: DateTime
indexes:
  share_link_item_idx: { fields: itemId, unique: true }
  share_link_token_idx: { fields: token, unique: true }

class: AccessRequest
table: access_request
fields:
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  requesterId: int
  requestedRole: Role
  message: String?
  createdAt: DateTime
  handledAt: DateTime?
  outcome: AccessRequestOutcome?   # approved, denied
```

Plus item settings columns on `DriveItem`: `editorsCanShare: bool`, `nonEditorsCanExport: bool`,
`viewersSeeComments: bool`.

### 2.1 Folder inheritance
Sharing a folder grants the role on every descendant (materialized `DriveItemPermission` rows with
`inheritedFromId`), maintained by `AccessService` on share/unshare/move; organization grants
(§2.3) are inherited the same way. Effective role = max(direct grants, inherited grants,
grants to the user's organization (direct or inherited), the link role when link sharing is
on, owner). Link sharing is not inherited: a link-shared folder shows its listing, and each
item inside has its own general access.
Moving an item out of a shared folder removes inherited grants from that folder. Someone who
doesn't own an item may move it only within its current folder tree or into a folder its owner
owns, so an editor can't pull another person's item into their own tree.

**Delete forever never deletes other people's items.** Purging a folder (delete forever, empty
trash, the 30-day auto-purge, account deletion) deletes only the purging owner's part of the
subtree. The topmost items of other owners move to their owners' roots (restored from the trash
if they were trashed with the folder), with their inherited grants and kind masks rebuilt.

### 2.2 General access and link sharing
**General access** is one choice per item (`enum GeneralAccess { restricted, organization,
link }`, `sharing.setGeneralAccess`): **Restricted** (only people with access), **Anyone at
<domain>** with a role (§2.3), or **Anyone with the link** with a role. Choosing one turns the
other off (link off when choosing the organization, the organization grant removed when choosing
the link). Grants to people are independent of it.

"Anyone with the link" + role (`ShareLink.role`). When a signed-in user opens `/d/<uuid>` (v2:
or `/s/…`, `/slides/p/…`, `/drive/file/…`, or `/invite/<token>`)
and the item has link sharing, the server records a `DriveItemUserState` (so it appears in
"Shared with me" after first open) and treats them as having the link role. **(Organizations)
Signed-out visitors** may open link-shared documents, spreadsheets and presentations
**view-only** (§2.4); this reverses v1's "anonymous access is not supported".

### 2.3 Sharing with an organization
"Anyone at <domain>" + role (Viewer, Commenter, Editor) shares an item with every member of the
sharer's organization ([04 §6](04-auth-and-accounts.md): same verified email domain, public mail
providers excluded, configured aliases merged).

- **Storage**: a `DriveItemPermission` row with `orgKey` = the organization key (its first
  domain), `userId` and `invitedEmail` null, no expiry. It matches every domain of the
  member's alias group (`orgKey IN (<the user's domains>)`). Folder grants are materialized on
  descendants like personal grants (§2.1) and copied by *Make a copy* with sharing.
- **Who may set it**: sharers (owner, editors when *Editors can share*), with a role up to
  their own; the key is the **caller's** organization. A sharer without an organization (an
  outside editor) can only change the role of, or remove, the organization grant already on the
  item; for anyone else the option is hidden (the server refuses with `invalidArgument`).
- **Visibility**: like link sharing, an organization item is not listed to members who never
  opened it: it appears in *Shared with me*, *Recent* and search **after the first open**
  (the first open records `DriveItemUserState.viaLink`, the flag both share). Items inside a
  folder shared with the organization are listed in that folder. Templates shared with the
  organization appear in every member's template gallery.
- **Signed out**: organization access never applies (no identity), so an item shared only
  with the organization is `notFound` signed out.
- **Changes**: setting, changing or removing it runs the ACL change path (§3): open streams
  of members re-check their role, and members who opened the item (state rows) get the drive
  signal; a member who leaves the organization (impossible today: no email change) or a domain
  made public by configuration loses access at the next check.

### 2.4 Signed-out viewing (Organizations milestone)
With "Anyone with the link", **documents, spreadsheets and presentations** open without an
account, **view-only regardless of the link role**. Drive folders and uploaded files stay
sign-in only: uploads are not malware-scanned (13 §6), and folders would expose listings.

- **Identity**: the signed-out caller is `Actor.anonymous` (profile id 0, no profile row).
  `AccessService.rolesFor(0, items)` returns Viewer for link-shared items of the three kinds
  that are not in the trash, and nothing else; no grant, organization or ownership can match.
- **What a signed-out client can call** (endpoints with `requireLogin: false`; every other
  method of them calls `UserService.actorOf`, which refuses signed-out callers):
  `publicItem.get(uuid)` (name, kind, content ref, owner display name, modified time — by item
  uuid or content ref; `notFound` otherwise), `document.connect/getInfo/getOps/getSnapshot`
  (head only; older revisions need Editor+), `sheetsDoc.*` and `slidesDoc.*`
  (`connect/page/ops/info`), `file.getUrl/getUrls` (only files of items it can view: the
  images of the item; never `file` items) and `writeTheme.listBuiltins/get/getMany` (the
  document's theme via `viaDocumentUuid`). Everything else — drive, comments, presence,
  sharing, users, notifications, AI, exports, versions — keeps `requireLogin`.
- **Never emails**: views returned to signed-out callers blank every `UserSummary.email`
  (`DriveItemView.owner/modifiedBy`, theme owners) and hide `parentUuid`; `PublicItemView`
  carries the owner's display name only. Document streams send no participants and no remote
  cursors to signed-out viewers.
- **No trace, no presence identity**: signed-out sessions are not announced on the document or
  RevLog roster (other users don't see them), record no `DriveItemUserState`, activity, view
  counts or usage analytics, and never remove a legacy file on open.
- **Writes are refused** on the stream (`forbiddenForRole`, "Sign in to edit."), before the
  role check, and every write RPC needs an account.
- **Streams re-check**: turning link sharing off, trashing or deleting the item reaches open
  signed-out streams through the ACL change path (`RevBus.rolesChanged` /
  `DocumentBus.rolesChanged`, which re-check every session including the anonymous ones) and the
  5-minute re-check; they close with `forbidden`/`notFound`.
- **Rate limits** (`AnonymousAccess`): 120 calls per client address and minute, 20 stream opens
  per address and minute, 6,000 calls per minute for all signed-out callers together (holds
  when addresses are forged or rotated; with Redis across instances), at most 1,000 open
  signed-out streams per instance (`limitExceeded` beyond).
- **Expired sessions**: a request that carries an auth key which no longer validates gets
  HTTP 401 (as on `requireLogin` endpoints) instead of being served signed out, so the client
  refreshes its token and the user keeps their real role.
- **Apps**: the editor routes (`/write/d/:uuid`, `/sheets/s/:uuid`, `/slides/p/:uuid`) render
  for signed-out users (03 §2); the editor opens read-only with a *Sign in* button that
  returns to the item (the link role then applies). Details: §5.1.

## 3. Enforcement

- **Single source of truth**: `AccessService.effectiveRole(session, userId, itemId)` (cached per
  session; invalidated via `session.messages` channel `acl:<itemId>`). It includes organization
  grants (§2.3) and the signed-out viewer (§2.4, user id 0); the drive listing and search SQL
  (`DriveListing._visible`) mirror it.
- **Write**: every document endpoint/stream checks role on connect and on every submitted op
  (ops are validated by kind: commenters may only submit `comment`-attribute or
  suggestion-attribute ops — see Write sync spec). When a role changes, the server pushes a
  `RoleChanged` event on the document stream; downgrade to viewer closes the editing channel.
- **Sheets** (and (v2) **Slides**): the RevLog stream and RPCs check the drive item's ACL
  through `AccessService` on connect, on every submitted op and on every page/ops request
  ([17](17-revlog-sync.md) part 5 §11): Viewer+ to connect and read, Editor+ (the effective
  role, including the editor limit) to submit. Role changes reach open streams through the ACL
  event path (`acl_events.dart` → `RevBus.rolesChanged` → re-check → `RevRoleChanged`), as for
  documents; a removed or unshared item closes the stream with `forbidden`, a trashed file is
  read-only. Commenters and Viewers can't submit ops; comments live in Postgres (comment
  endpoints), not in the file.
- **(v2) Files**: every file endpoint (`fileContentUrl`, download route, `convertFile`,
  `updateFileMeta`) checks the effective role through `AccessService`; download URLs are
  short-lived (15 min) and bound to the requesting user (Drive 02 §8). `uploading` files are
  visible only to their uploader.
- **Protected ranges/sheets (Sheets)** are enforced by the server: the RevLog sequencer runs
  the core's `ProtectionGuard` on every op of a file with protections and rejects an op that
  writes protected cells, structure, rules, objects or sheets its author may not edit
  (`protectedRange`; [17](17-revlog-sync.md) part 5 §3.5). The client write gate and the MCP
  guard run the same code first for the dialogs and friendly errors; warning-only protections
  never block on the server. Offline edits rejected this way are reported to their author
  ([Sheets 07 §10.3](wonky_sheets/07-data-tools.md)).
- **Fan-out of a change** (`AclEvents.changed`, CQ-26): a share, move, trash, restore or purge
  of a folder notifies its whole subtree. The interested users (owner, grantees, users with a
  state row) of all nodes are loaded in a few batched queries, and each user gets **one**
  `drive:user:<id>` signal listing up to 500 item ids, which the watcher resolves in one batch
  (`DriveChange` events per item, unchanged for clients). Subtrees above 200 items are fanned
  out by a future call (`AclFutureCall`) right after the request. Move, trash, restore and
  delete forever take at most 500 items per call (`limitExceeded`).
- **MCP / AI / scripts** go through the same `AccessService`.

## 4. Endpoints — `SharingEndpoint` (`sharing`)

`getSharing(itemUuid)` → owner, permissions (with user summaries), link, settings, pending
requests; `share(itemUuid, emails, role, notify, message, expiresAt?)`;
`updateRole(itemUuid, userId, role)` (only for people who already have the item, directly or
through a folder; anyone else is shared with through `share`, which notifies them); `remove(itemUuid, userId)`;
`setGeneralAccess(itemUuid, access, role?)` (§2.2–2.3; restricted needs no role);
`transferOwnership(itemUuid, newOwnerUserId)` (new owner must accept → notification; previous
owner becomes Editor; (v2) refused with `quotaExceeded` when the item's counted size doesn't fit
the new owner's storage — checked at request and at acceptance, [Drive 03 §7.3](wonky_drive/03-storage-quota.md)); `setLink(itemUuid, role?)`; `rotateLink(itemUuid)`;
`updateSettings(itemUuid, settings)`; `requestAccess(itemUuid, role, message)`;
`setLink(itemUuid, role)` with a role = `setGeneralAccess(link, role)`; with null only turns the
link off. `getSharing` returns `generalAccess`, `organization` (the caller's organization key,
null without one), `orgAccess` (the item's own organization grant) and `inheritedOrgAccess`
(the highest one inherited from a folder). `PublicItemEndpoint` (`publicItem`): `get(uuid)`
(§2.4, signed out allowed).
`handleAccessRequest(requestId, approve, role?)`; `resolveInvite(token)` → item uuid + role.

**Share emails.** `share`'s `notify` is the dialog's *Send an email* (default on). With it,
every **newly added** person gets an email right away, off the request path
(`ShareEmailFutureCall`, through the `EmailSender` of [07 §4](07-collaboration.md)); a role
change of someone who already had a direct grant or invite sends none:
- An **existing user** gets a `shared` notification and the email "<name> shared “<title>” with
  you" (role, the optional message, a button to the item's URL, a footer link to turn share
  emails off). Their *shares* setting `off` means no notification and no email; otherwise
  (`inApp` or `email`) the sender's explicit choice wins. The notification is created as
  emailed (`emailedAt` set), so the digest never sends it again; when the send fails the claim
  is given back and the digest sends it if their *shares* setting is `email`.
- An **address without an account** becomes a pending invite and gets an invitation: "<name>
  invited you to “<title>” on Wonky Work", the role, the message, "create a free account with
  this address" and *Sign up and open*, which opens sign-up in the item's app and comes back
  to the item (`/write/signup?next=/d/<uuid>`; spreadsheets `/sheets/signup?next=/s/<uuid>`,
  presentations `/slides/…/p/…`, folders and files in Drive with `/f/…` and `/file/…`); the
  invite is converted at sign-up. Nothing is sent when the invite
  was removed or converted before the email went out.
- **Abuse limits.** Invitations count per sender against `sharing.inviteEmailsPerHour` (30)
  and `sharing.inviteEmailsPerDay` (100) (a `RateLimiter`, in Redis with several instances,
  [13 §4](13-security-and-operations.md)); a share whose new invitations do not fit is refused
  with `limitExceeded` before anything changes ("…try again later, or turn off *Send an
  email*"). 0 turns invitation emails off (invites are still created). Emails never name
  another person's address: only the recipient's own address appears, the sender is named by
  display name. The message is at most 1000 characters (`invalid` beyond), and names and the
  message are escaped in the HTML and kept to one line where a line is expected (subjects).
- Off: no notification and no email.
- Shares by approving an access request (`handleAccessRequest`) email the requester the same
  way; MCP `drive.share` takes `notify` (default true, [09](09-mcp.md)).

Sharing changes are **not undoable**; destructive ones (remove, transfer) confirm.

(M14) Submitting a document to a publication grants its moderators Commenter without a
notification; the dialog shows them as "Moderator · <publication>" ([18 §5.1](18-publications-and-submissions.md)).

## 5. Share dialog (shared UI, `wonky_app`)

```
┌ Share "Q3 planning" ─────────────────────────────────── ⚙  ? ┐
│ [ Add people by name or email…                    ] [Editor ▾]│
│ ── People with access ─────────────────────────────────────── │
│ (A) Anna Berg (you)        anna@…                      Owner  │
│ (B) Bo Chen                bo@…                     [Editor ▾]│
│ (C) carl@… (pending)                                [Viewer ▾]│
│ ── General access ─────────────────────────────────────────── │
│ 🔒 [Restricted ▾]  Only people with access can open            │
│    (or 🏢 Anyone at acme.dev [Viewer ▾])                        │
│    (or 🌐 Anyone with the link [Viewer ▾])                     │
│ [🔗 Copy link]                                         [Done] │
└───────────────────────────────────────────────────────────────┘
```

- **Footer**: *Copy link* on the left, *Done* on the right (a full-width actions row).
- **Adding people** starts as soon as something is typed or picked: the dialog then shows only
  the composer — *People with access*, *General access*, ⚙, *Copy link* and *Done* are hidden
  — and the footer is *Cancel* (left) and *Send* (right; *Share* while *Send an email* is
  off). *Cancel* (or Esc) drops the recipients, the typed text and the message and goes back.
  The composer: a chip per recipient (made on space, comma, semicolon, Enter or picking a
  suggestion; Backspace in the empty input removes the last chip whole; autocomplete from
  `user.searchUsers`: related people, members of the caller's organization by name or email
  prefix, anyone by exact email — [04 §6.3](04-auth-and-accounts.md)), role select, the *Send
  an email* checkbox (default on, no subtitle) and the optional message (only while it is on,
  at most 1000 characters; §4 *Share emails*). *Send*/*Share* is enabled with a chip or a valid
  typed address that is not a chip yet (it becomes one). When a name search finds no one, a
  muted line under the field says "Enter the full email to add someone outside <domain>"
  (without an organization: "Enter the full email address to add someone"); its line is always
  reserved, so nothing below moves when it appears.
- (Organizations) **The people field** is one field: a `ShadDecorator` with the theme's field
  decoration (one border, fill, shadow, focus ring while the input has focus) around the chips
  and a `ShadInput` with `ShadDecoration.none`; without chips it is exactly as tall as the role
  select next to it (36 px) and aligned with it; chips may wrap and make it taller.
- (Organizations) **General access** is one select with Restricted (lock), *Anyone at
  <domain>* (building; only when the caller has an organization or the item already has an
  organization grant, named after that grant) and *Anyone with the link* (globe), plus a role
  select (Viewer, Commenter, Editor) for the two open choices; every change calls
  `sharing.setGeneralAccess` (choosing an open option starts at Viewer). Hints: "Only people
  with access can open" · "Anyone at <domain> can view/comment/edit" · for documents,
  spreadsheets and presentations "Anyone with the link can view, also without signing in"
  (with Commenter/Editor: "…can view, and comment/edit when signed in", §2.4) · for files and
  folders "Anyone signed in who has the link can …". An organization grant inherited from a
  folder adds a muted line "Anyone at <domain> can also <role> through "<folder>"". Selects
  follow the server state and snap back after a failed change; non-sharers see them
  disabled.
- Role dropdown per person: Viewer, Commenter, Editor, separator, *Transfer ownership*,
  *Add expiration*, *Remove access*.
- ⚙ opens the settings sub-page: the three owner settings and *Done* (back to the main page;
  no back arrow). There is no *Reset link*: the link people copy is the item's URL, which a new
  token would not change; Restricted is how link access is revoked (`rotateLink` stays in the
  API for `/invite/<token>` links).
- Pending **access requests** banner at top with Approve/Deny.
- Keyboard: Esc cancels adding people, else closes; Enter in the composer makes a chip, or
  sends when the input is empty.
- MCP: `drive.share`, `drive.unshare`, `drive.set_link_sharing`; UI bridge can drive the dialog
  via its `WonkyDialogSpec`.
- (v2) The dialog is the same for every kind; for files the ⚙ settings say "Viewers and
  commenters can download" instead of "…download, print and copy". Invitation e-mails and the
  share link use the kind's URL (01 §2.4). The `/invite/:token` landing exists in every app and
  forwards to the item's app.
