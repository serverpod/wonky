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
  role: Role
  inheritedFromId: int?            # folder item the grant was inherited from (null = direct)
  grantedById: int
  grantedAt: DateTime
  expiresAt: DateTime?             # optional expiring access (Editors+ can set for others)
indexes:
  perm_item_user_idx: { fields: itemId, userId, inheritedFromId, unique: true }
  perm_user_idx: { fields: userId }

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
`inheritedFromId`), maintained by `AccessService` on share/unshare/move. Effective role =
max(direct grants, inherited grants, link role if the user has opened via link, owner).
Moving an item out of a shared folder removes inherited grants from that folder. Someone who
doesn't own an item may move it only within its current folder tree or into a folder its owner
owns, so an editor can't pull another person's item into their own tree.

**Delete forever never deletes other people's items.** Purging a folder (delete forever, empty
trash, the 30-day auto-purge, account deletion) deletes only the purging owner's part of the
subtree. The topmost items of other owners move to their owners' roots (restored from the trash
if they were trashed with the folder), with their inherited grants and kind masks rebuilt.

### 2.2 Link sharing
"Anyone with the link" + role. When a signed-in user opens `/d/<uuid>` (v2: or `/s/…`,
`/slides/p/…`, `/drive/file/…`, or `/invite/<token>`)
and the item has link sharing, the server records a `DriveItemUserState` (so it appears in
"Shared with me" after first open) and treats them as having the link role. Anonymous (signed
out) access is **not** supported in v1 — users must sign in.

## 3. Enforcement

- **Single source of truth**: `AccessService.effectiveRole(session, userId, itemId)` (cached per
  session; invalidated via `session.messages` channel `acl:<itemId>`).
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
`transferOwnership(itemUuid, newOwnerUserId)` (new owner must accept → notification; previous
owner becomes Editor; (v2) refused with `quotaExceeded` when the item's counted size doesn't fit
the new owner's storage — checked at request and at acceptance, [Drive 03 §7.3](wonky_drive/03-storage-quota.md)); `setLink(itemUuid, role?)`; `rotateLink(itemUuid)`;
`updateSettings(itemUuid, settings)`; `requestAccess(itemUuid, role, message)`;
`handleAccessRequest(requestId, approve, role?)`; `resolveInvite(token)` → item uuid + role.

Sharing changes are **not undoable**; destructive ones (remove, transfer) confirm.

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
│    (or 🌐 Anyone with the link [Viewer ▾])                     │
│ [🔗 Copy link]                                         [Done] │
└───────────────────────────────────────────────────────────────┘
```

- Adding people expands to a composer: chips for each recipient (autocomplete from
  `user.searchUsers`), role select, *Notify people* checkbox, message textarea, *Send*.
- Role dropdown per person: Viewer, Commenter, Editor, separator, *Transfer ownership*,
  *Add expiration*, *Remove access*.
- ⚙ opens settings sub-page (the three owner settings).
- Pending **access requests** banner at top with Approve/Deny.
- Keyboard: Esc closes; Enter in the composer sends.
- MCP: `drive.share`, `drive.unshare`, `drive.set_link_sharing`; UI bridge can drive the dialog
  via its `WonkyDialogSpec`.
- (v2) The dialog is the same for every kind; for files the ⚙ settings say "Viewers and
  commenters can download" instead of "…download, print and copy". Invitation e-mails and the
  share link use the kind's URL (01 §2.4). The `/invite/:token` landing exists in every app and
  forwards to the item's app.
