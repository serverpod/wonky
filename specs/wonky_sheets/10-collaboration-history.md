# Sheets 10 · Collaboration, Comments and History

This spec defines how the suite collaboration framework
([07-collaboration.md](../07-collaboration.md)) applies to spreadsheets: **presence**
(cursors, selections, follow mode, sheet-tab avatars), **ephemeral commit hints**, **comments**
anchored to cells and ranges, **notes**, **version history** (snapshots, viewing, diffs,
restore, copies), **cell edit history**, the activity dashboard, change notifications,
conflict UX, and a walk-through of offline collaboration scenarios.

Read first: suite [07-collaboration.md](../07-collaboration.md),
[12-offline-and-sync.md](../12-offline-and-sync.md) §2, [17-revlog-sync.md](../17-revlog-sync.md)
(op log, outcomes, conflicts: part 6 §6),
[08-commands-and-undo.md](../08-commands-and-undo.md) §3;
Sheets [02-data-model.md](02-data-model.md) (ids, op log, `cell_history`, writes),
[03-grid-and-editing.md](03-grid-and-editing.md) (grid layers, selection model),
[07-data-tools.md](07-data-tools.md) (sort semantics).

Priorities: P0 = first complete release, P1 = v1 if possible, P2 = later.

---

## 1. Presence

### 1.1 Sheets `PresenceCursor` JSON

The suite defines `PresenceCursor` as app-specific JSON. Sheets uses:

```jsonc
{
  "route": "grid",                       // grid | script | history | print
  "sheetId": "Abc…",                     // active sheet (22-char base-62 ids everywhere)
  "activeCell": { "rowId": "5Kq…", "colId": "9zA…" },
  "ranges": [ { "r1": "5Kq…", "c1": "9zA…", "r2": "7Hb…", "c2": "Q2w…" } ],  // max 20 ranges
  "editing": false,                      // cell editor open on activeCell
  "objectId": null,                      // selected embedded object (charts/images)
  "viewport": { "topRowId": "…", "leftColId": "…", "rows": 42, "cols": 14, "zoom": 1.0 },
  "scriptFile": null                     // route == script: open file name
}
```

- Sent on change, throttled to 10/s (suite), coalesced. Viewport updates are throttled to 2/s
  and sent only while someone follows this participant (the server tells the followed client
  through a `FollowerCount` event, see §1.5).
- Ids that the receiver doesn't know yet (rows created by the sender whose op hasn't arrived)
  are ignored until they arrive. A range with an unknown bound is drawn up to the known bounds.
- `actorKind: mcp|ai` participants (suite §1.1) send cursors injected by the server: after a
  headless write, the server sets the agent participant's `ranges` to the written ranges for 5 s.
  Implementation: `AgentCursors` (`wonky_server/lib/src/sheets/changelog/agent_cursors.dart`)
  runs inline after a tool write is committed (`SheetsWrites`; best effort, not a durable hook,
  suite 17 part 5 §6.2): one participant per spreadsheet, user and
  actor kind (`PresenceService.injectAgent` with a reused session id and the cursor JSON built
  from `summaryJson.ranges`), removed 5 s after its last write. The client labels it "Claude via
  MCP (Anna)" / "Assistant (Anna)".

### 1.2 Rendering remote cursors on the grid

Painted by `RemotePresenceLayer` (in the grid layer stack above objects, below the local
active-cell border; see [03-grid-and-editing.md](03-grid-and-editing.md)) using the shared
`RemoteCursorOverlay` primitives from `wonky_ui`.

| Element | Style |
|---------|-------|
| Remote active cell | 2 px border in the participant's presence color (`presence1…12`), inset 0.5 px so adjacent cursors don't overlap the gridline. |
| Remote ranges | 1 px border in presence color + fill at 10 % alpha (light) / 16 % (dark). |
| Name flag | Pill above the active cell's top-left corner (below when at the top edge of the viewport): presence color background, contrasting text (white/black chosen by luminance), 11 px Geist, `displayName` (or "Claude via MCP (Anna)"). Visible for 3 s after the cursor moves, while hovered, and while `editing`. |
| Editing indicator | When `editing: true`: the border animates (dashed, 1 s march; static dashed with *Reduce motion* — the OS setting or Settings › Sheets *Reduce animations*) and the flag shows a ✎ icon and "typing…". With a `typing` hint (P2, §2.1) the collaborator's text is drawn over the cell (italic, at most 240 px wide). |
| Same-cell overlap | Several remote cursors on one cell: stacked flags (max 3, then "+N"). |
| Agent (MCP/AI) | Same, with a ✨/🤖 glyph in the flag and a dotted border. |
| Object selection | Outline around the object in presence color (§[08](08-charts-and-objects.md) §9.2). |

Hovering a remote cursor's cell shows its flag too (`SheetsPresenceController.setHover`, from
the collaboration overlay's hover tracking).

Remote cursors in frozen panes are clipped like local selections. Cursors on hidden rows or
columns collapse onto the boundary line. Cursors are not drawn for participants in `away`
state (avatar greyed instead), and are hidden while printing/exporting.

### 1.3 Sheet tab avatars
Each sheet tab ([04-screens-menus-toolbar.md](04-screens-menus-toolbar.md)) shows up to 3 small
(14 px) presence-colored avatar dots at its top edge for participants whose `sheetId` is that
sheet, then "+N". Hover → tooltip with names. Clicking a dot jumps to that participant (same as
§1.4).

### 1.4 Header avatar stack and jumping
`PresenceAvatarStack` (suite) entries show "Viewing Sheet2" / "Editing Sheet1!B4" / "In
script editor" / "Idle". Click → `sheets.presence.jumpTo(sessionId)`: activates their sheet
and scrolls so their active cell is visible (no selection change), flashes their cursor
outline twice.

### 1.5 Follow mode
`sheets.presence.follow(sessionId)` (avatar ⋮ › *Follow*):
- Shows a banner in the grid's top-right "Following Anna · Stop" (presence-colored left
  border).
- Activates their sheet whenever their `sheetId` changes; sets our viewport to their
  `viewport` (top-left ids + zoom-independent: we keep our zoom and align their top-left).
- Stops on: any local scroll, selection, sheet switch, Esc, *Stop*, or when they leave.
- Following someone in the script editor navigates to the script route and opens their file
  (read-only cursor, no viewport sync inside code in v1).
- The server counts followers per session and sends `FollowerCount` so the followed client
  knows to send viewport updates. The followed user sees "Bo is following you" in their avatar
  tooltip (no toast).

### 1.6 Implementation
`wonky_sheets/lib/features/collab/presence/`: `SheetsPresenceController` (builds
`PresenceUpdate`s from the selection model; maps incoming cursors to grid rects through
`AxisIndex`; exposes a `ValueListenable<List<RemoteCursorView>>` per sheet), `RemotePresenceLayer`,
`SheetTabPresence`, `FollowController`. Uses the shared `PresenceService` from `wonky_app`.

---

## 2. Ephemeral commit hints

Committed edits reach other clients as RevLog ops in about one round trip (suite 17 part 7,
P1 < 250 ms), so hints carry no committed values. Two **hints** ride the presence stream: the
live `typing` preview of a cell being edited, and a `pending` shimmer over a range whose large
change (a group of several ops) is still being saved (suite 17 part 6 §10). The ops remain the
source of truth.

> **As built.** `CommitHints` sends `typing` and `pending` only; `cell`/`range` hints of older
> clients are ignored. A `pending` shimmer is dropped by the last op of a remote group, the next
> remote change to its sheet, its sender leaving, or after 5 s.

### 2.1 Message formats

Hints ride on the presence protocol: `PresenceUpdate` gains an optional `hints` list, and the
server relays them as `PresenceEvent.Hints(sessionId, hints)` to other participants of the
same item (not persisted, not echoed to the sender).

```jsonc
// A commit of more than 500 cells still being saved: no values, just a "pending" shimmer
{ "t": "pending", "sheetId": "…", "range": { "r1": "…", "c1": "…", "r2": "…", "c2": "…" },
  "kind": "format" | "structure", "hlcMillis": … }

// Live typing preview (P2): sender's in-progress editor text for the active cell, ≤ 200 chars, throttled 4/s
{ "t": "typing", "sheetId": "…", "rowId": "…", "colId": "…", "text": "Hel" }
```

Limits: max 500 cells per message, max 20 hint messages/s per session, max 64 KB per message.
Larger operations send only a `pending` hint for the bounding range. The server drops hints
from participants whose role is below Editor.

### 2.2 Receiver behavior (`CommitHintOverlay`)
- `typing` hints show the collaborator's in-progress text over the cell (presence layer).
- `pending` hints draw a subtle animated shimmer over the range (static tint with *Reduce
  motion*) until the group's last op arrives, the sheet's cells change remotely, the sender
  leaves, or 5 s pass.
- Unknown ids → hint ignored.

---

## 3. Comments

### 3.1 Anchors

Comments live in Postgres (`CommentThread`, `Comment`, suite §2.1), not in the spreadsheet's
file, so commenters don't need write access to it.

| `anchorKind` | `anchorJson` | Created from |
|--------------|-------------|--------------|
| `cell` | `{"v":1,"sheetId":"…","rowId":"…","colId":"…"}` | single cell selected (or the top-left cell of a merge) |
| `range` | `{"v":1,"range":{"s":"…","r1":"…","c1":"…","r2":"…","c2":"…"}}` | multi-cell selection (P1; v0 anchors to the active cell) |
| `document` | `{"v":1}` | comments panel "Comment on spreadsheet" (P2) |

`quotedText` = the cell's formatted display value (or "A1:C4" summary for ranges) at creation.

### 3.2 Anchor survival
- Anchors use row/column **ids**, so inserting, deleting other rows, moving rows/columns and
  sorting that reorders rows (sortKey rewrite) keep the comment on the same logical cell
  (Google Sheets parity: comments follow sorted rows).
- **Cut & paste** moves cell contents to new cells. The paste command collects threads
  anchored in the cut source and calls `comment.updateAnchor` for each, mapping offsets to the
  destination (comments move with cut cells, Google behavior). These calls are part of the paste's
  undo step through the `comments` undo domain. Copy & paste never copies comments.
  Implementation: `CommentAnchorMoves` listens to `SheetEditorController.applyListeners`
  (called after every applied operation inside the command's transaction) for
  `PasteClipboard` of a cut with `PasteMode.all`, and records `CommentUndoEntry(op: updateAnchor)`
  (`previousAnchorJson` ⇄ `anchorJson`). Range anchors move only when the whole range was cut.
- Range sorts that move **contents** between rows (partial-range sorts, see
  [07-data-tools.md](07-data-tools.md)) update anchors the same way (not built yet).
- **Orphaning**: when the anchor's row, column or sheet is deleted, the thread becomes
  `orphaned`. Detection is **server-side** in the `comments` post-commit hook (suite 17 part 5
  §6.2): the op's `summaryJson` lists deleted row/column/sheet ids (Additions A-10-1). For each,
  the server marks threads `orphaned` with `orphanReason {kind: row|column|sheet, id, revision}` and
  records the previous status. Undoing the deletion revives the same ids. When a later op lists
  them as **revived**, the server restores the previous status. The client also hides threads
  whose anchors don't resolve, so the UI is right before the server catches up.
- Orphaned threads appear in the comments panel under "Orphaned" with the quoted text and
  "The cell this comment was on was deleted"; they can be resolved or deleted, not
  re-anchored (P2: *Re-anchor to selection*).

### 3.3 Indicators on the grid
- **Comment indicator**: a 6 px triangle in the cell's top-right corner, `commentHighlight`
  color (orange-ish in light, amber in dark). Resolved threads show no indicator. Range
  anchors show the triangle on the range's top-right cell, and the range is outlined when the
  thread is active.
- **Note indicator**: a 6 px black (light) / light-grey (dark) triangle in the same corner. If a
  cell has both, the comment triangle wins and the hover card shows both.
- Hover over an indicator (300 ms) → **hover card** (`ShadPopover`, non-modal) with the
  thread (first comment + reply count) or the note; clicking opens the thread card. Viewers
  without comment visibility see no comment indicators.
- Active cell with a thread: the thread card opens docked to the right of the cell (or left
  when there is no space), aligned to the cell top, following scroll.

### 3.4 Creating and working with comments
- `Mod+Alt+M`, cell context menu *Comment*, *Insert › Comment*, toolbar comment button →
  `shell.comments.create` with the Sheets anchor of the current selection → composer card
  next to the cell (suite composer with `@` mentions and *Assign to*). The anchor provider's
  `CommentPanelOptions.composesInline` keeps the panel closed; the collaboration overlay docks the suite
  `NewCommentCard` next to the anchor (Esc cancels). With the comments panel open, the composer
  stays in the panel.
- Thread cards (suite widget) support reply, edit, delete, reactions, resolve, link to comment
  (`/s/<uuid>?comment=<threadUuid>` → activates sheet, scrolls, opens card).
- Keyboard: `Mod+Alt+Shift+A` opens the comments panel; inside the grid, `Mod+Alt+N`/`Mod+Alt+P`
  (Sheets: `sheets.comments.next` / `previous`) jump to the next/previous cell with an open
  thread in reading order (sheet order, row, column).

### 3.5 Comments panel (Sheets specifics)
Suite panel (filters **Open** / **For you**, no search; suite 07 §2.3) + a scope filter **This
sheet / All sheets** (default All), grouped by sheet with sheet headers (in tab order), each
thread showing the cell reference ("Sheet1!B4" computed live from ids) and quoted text. Sort
*By position* (sheet order, row, col) or *By date*. Additional filter *Orphaned* (P2).
Implementation: the suite panel shows an app scope filter from `CommentPanelOptions.scopes`
/ `inScope` (tabs under Open / For you) and group headers from `groupOf` in the position sort;
Sheets groups by sheet name, unresolvable anchors under "Orphaned". *This sheet* follows the
active sheet; `sheets.comments.openPanel {scope}` sets it.

### 3.6 Mentions, assignments, notifications
Suite §3–4 unchanged. Notification payloads for Sheets include `{sheetName, a1, quotedText}`;
email links use `?comment=`. Assigning requires the assignee to have Commenter+ access
(share prompt otherwise).

### 3.7 Offline comments (P1)
Comment endpoints are online. Offline, creating/replying/resolving queues the operation in the
local `PendingCommentOp` table (Additions A-10-4) and shows the card with "Pending — will be
posted when you're online". Thread/comment UUIDs are client-generated (UUIDv7) and the endpoint
is idempotent on them. Edits to others' threads while offline are not allowed.
Implementation: generic in the suite `CommentsController` (`queueOffline`, set by Sheets):
create, reply, resolve/reopen and anchor moves are queued while offline (or when the call fails
for lack of a connection) as `PendingCommentOp`s in the user's `LocalStore`
(`comments.pending.<itemUuid>`), shown optimistically (local comments have negative ids; the
card shows "Pending — will be posted when you're online") and posted in order when the
connection is back. Undoing an offline create drops its queued operations.

---

## 4. Notes vs. comments

| | Note | Comment |
|-|------|---------|
| Storage | `Cell.note` (file column, last arrival wins) | Postgres threads |
| Who can edit | Editors | Commenters+ |
| Threads, mentions, resolve, notifications | — | ✓ |
| Offline | ✓ (outbox) | queued (P1) |
| Indicator | dark triangle | colored triangle |
| Undo | spreadsheet undo (`sheets.rows`) | `comments` domain |
| Export XLSX | `<comment>` legacy notes | threaded comments (P2) or notes with "[Comment] author: text" |
| Import XLSX | legacy notes → notes; threaded comments → comments (P1, author mapped by email if user exists, else text prefix) | |

Commands: `sheets.notes.insert` (`Shift+F2`, opens an inline note editor: `ShadTextarea`
popover anchored to the cell, auto-saves on blur/Esc, empty = delete), `sheets.notes.clear`
(for the selection), `sheets.notes.convertToComments` (P2; one step: creates threads and clears
notes).

---

## 5. Version history

### 5.1 `SheetsVersionProvider` (server, `wonky_server/lib/src/sheets/versions/`)

Implements the suite `VersionProvider` contract: **capture**, **materialize**, **restore**,
plus **diff** and **copy** for Sheets.

#### 5.1.1 Capture triggers
- The `versions` post-commit hook of the RevLog file (RevLog spec 05 §6) updates per
  spreadsheet `lastEditAt` and `editorsSinceLastVersion` in the server-only
  `ItemVersionState` table (Additions A-10-3).
- `SheetsVersionScheduler` (FutureCall every minute) applies the suite capture policy: an
  `auto` version when ≥ 5 min passed since `lastEditAt` and there were edits since the last
  version, and at most one per 30 min of continuous editing (force a capture after 30 min
  even while editing continues). Named versions (`versions.name_current`, *File › Version
  history › Name current version*) capture immediately.
- Offline edits that sync later belong to the next version: a version is captured **at a file
  revision** (`ItemVersion.revision`, the head the snapshot shows), and an edit belongs to the
  version whose revision window (previous capture's revision, this one] contains its op's
  commit, whatever its creation time.

#### 5.1.2 Snapshot format
A snapshot is a compressed export of **all rows of the spreadsheet** at capture time, read
with an admin read inside one repeatable-read transaction together with the file's
`headRevision` (recorded in `ItemVersion.revision` and the header's `revision`):

```
snapshot.wsv (gzip)
├── header line (JSON): {"format":"wonky-sheets-snapshot","v":1,"spreadsheetId":"…",
│                        "capturedAt":"…","revision":123,"schemaHash":"…",
│                        "engineVersion":"…","counts":{"cell":123456,…}}
└── NDJSON records, grouped by table in dependency order:
    {"tb":"spreadsheet","row":{…all columns…}}
    {"tb":"sheet","row":{…}}  {"tb":"sheet_row",…}  {"tb":"sheet_column",…}  {"tb":"cell",…}
    {"tb":"merged_range",…} … {"tb":"embedded_object",…} {"tb":"pivot_table",…}
    {"tb":"script_project",…} {"tb":"script_file",…} {"tb":"macro",…} {"tb":"script_property",…}
```

- Excluded tables: `script_build` (derived),
  `script_trigger` (security: per installer; never restored).
- Cells are written compactly: column names abbreviated via a per-table key map in the header,
  null fields omitted. Typical size: ~25 bytes/cell after gzip.
- Stored as a `StoredFile` (cloud storage) referenced by `ItemVersion.snapshotFileId`;
  `ItemVersion.storageKind = snapshotFile`, `sizeBytes` set.
- `SheetsSnapshotIndex` (server-only, Additions A-10-3) stores per version: sheet list (id, name,
  row/col counts, cell count, kind) and `changedRangesJson` (union of the `rev_op.summaryJson`
  ranges committed since the previous version, per sheet, capped at 1,000 ranges then marked
  `"approx": true`). It also stores the author ids.
  Format: `{"v":1,"approx":false,"ranges":[{"s","r1","c1","r2","c2","u":<user id>}]}`, oldest
  first; the window is the ops with revision in (previous version's `revision`, this version's
  `revision`] (`SheetsVersionChanges.between`; versions captured before RevLog, without a
  revision, fall back to the commit times between the two captures).
- The header carries the captured `revision` and the `sheetsSchema` hash (`schemaHash`; older
  snapshots carry `engineHlc`/`syncTablesHash` instead); restores keep only the tables and columns of the current
  RevLog schema, so older snapshots stay restorable.
- Capture runs in a background isolate on the server, streaming rows (bounded memory). It
  takes < 10 s for 1M cells. Thinning (suite policy) deletes snapshot files of thinned
  versions.

### 5.2 Viewing a version

Route `/s/:uuid/history?version=<itemVersionId>` (suite §5 UI). Sheets-specific behavior:

1. The client requests `VersionEndpoint.getSnapshotUrl(itemUuid, versionId)` (signed URL,
   15 min) and downloads + decodes the snapshot in a background isolate (web: chunked parse
   with `scheduleTask` yielding) into a **read-only in-memory `WorkbookModel`** (no sync DB,
   no writer). The formula engine evaluates it like a live workbook. Volatile functions
   (`NOW`, `RAND`) are frozen to the capture time / seeded with the version id.
   Custom (script) functions use the snapshot's script files only if a build with that
   `sourceHash` still exists; otherwise they show `#LOADING`→"Not available in history".
2. The grid renders it with `GridView(readOnly: true)`: no editing, no fill handle; selection,
   copy, find, sheet switching and zoom work. Hidden/frozen/merged/CF/charts render as in the
   version.
3. **Changes highlight** (toggle *Show changes*, default on): cells that differ from the
   **previous version** get a 2 px outline + 15 % fill in the author's presence color (or a
   neutral "multiple authors" color). Sheet tabs with changes show a dot. Deleted sheets are
   shown as tabs with strikethrough names that open read-only from the previous version.
   A *Changes* list in the right panel (under the selected version) shows a summary: "B4:B9 by
   Anna · Inserted 3 rows by Bo · Sheet 'Q3' renamed". *Next change* / *Previous change*
   buttons (`Mod+Alt+↓/↑`) navigate changed cells in reading order.
4. **Diff computation**: cell-level by cell id between the two snapshots, comparing `content`,
   `note` and format fields (format-only changes outlined dashed). Structure changes compare row/
   column/sheet id sets. Strategy:
   - Snapshots with ≤ 500k cells each: client computes the diff (both snapshots are
     downloaded; hash maps by id; < 1 s).
   - Larger: `SheetsVersionEndpoint.diff(itemUuid, versionId, previousVersionId)` computes it
     server-side once and caches the result as a `StoredFile` (`<versionId>.diff.gz`,
     `SheetsSnapshotIndex.diffFileId`); the client downloads the gzip JSON
     `{diff: SnapshotDiff JSON, a: [author user id per changed cell, 0 = unknown]}` instead of
     the previous snapshot.
5. **Author attribution**: for each changed cell, the author is taken from the ops
   (and `cell_history` for pruned ones) in the revision window between the two captures whose `detailJson` or
   ranges include the cell (latest wins). The server returns this as part of the diff (`authorId`).
   Cells changed by bulk operations without details are attributed from `summaryJson.ranges`.
   Agent edits show the agent attribution ("Claude via MCP (Anna)").
   Implementation: attribution uses the version's changed ranges (latest range containing the
   cell wins; `SheetsVersionEndpoint.changes` for the client-side diff, the same ranges inside
   the server diff). Changed cells are drawn in their author's presence color; unattributed
   cells use the single author's color or the neutral color. The bar shows the authors' colors
   (legend); `sheets.history.toggleShowChanges` toggles *Show changes*
   (`VersionHistoryScreen.showChanges`). Charts and images render through `SheetObjectsHost`.

Right panel: suite version list; each Sheets version also shows a size and sheet count tooltip.

### 5.3 Restore

`VersionEndpoint.restore(itemUuid, versionId)` (Editors+, online only):

1. Capture a `restorePoint` version of the current state (suite rule).
2. Stream the snapshot rows and the current rows (admin read) table by table, and compute the
   **row diff by id**:
   | Case | Write |
   |------|-------|
   | Row in snapshot, missing in current | insert with the same id and all snapshot columns |
   | Row in current, missing in snapshot | delete |
   | Row in both, some columns differ | update naming **only the differing columns** |
3. **Protection pre-check** (RevLog spec 05 §3.5): the whole diff is checked with the
   protection guard (`ProtectionCheck.ofApplied` against the current headless model, as the
   restoring user) before anything is written; a diff that touches ranges protected from the
   user is refused with "This version changes protected ranges you can't edit"
   (`forbidden`, reason `protected_range`), so a restore never commits partially because of
   protection. (The restore point of step 1 stays.)
4. Apply as RevLog server changes (`SheetsServerWrites.applyRecorded`): chunked ops in
   dependency order (parents first for inserts, children first for deletes), each op with
   `actorKind: user`, label `"Restore version '<name or time>'"`, kinds `["restore"]`, joined by
   one record id; one `ServerChangeRecord` (7 days) points at them so the restore can be
   reverted (the ops' applied forms carry the pre-restore values).
5. Progress is streamed (`Stream<RestoreProgress {phase, done, total}>`); the client shows a
   progress dialog. Collaborators see the ops arrive live, plus a toast "Anna
   restored a previous version" (presence `system` event).
6. Excluded from restore: `script_trigger`, `script_build`. The current
   spreadsheet title is restored too (mirrored to Drive).
Implementation note: the restore is written with `SheetsServerWrites` (RevLog server changes, same
`ServerChangeRecord` with a record id); its op summary lists deleted/revived rows/columns/sheets (comment
orphaning) and up to 200 cell details (cell history), and the server broadcasts a presence notice
`versionRestored` that shows the toast. The client records the undo entry through
`VersionRenderer.restoreUndoEntry` (suite hook) on `shell.versions.restore`.

7. **Undo**: the restore's response contains `changeId`. The client pushes an `UndoStep`
   labelled "Restore version" with one entry in the new undo domain **`sheets.serverChange`**
   (Additions A-10-5): undo calls `SheetsEndpoint.revertChange(changeId)` (server inverts the
   record's applied ops with the same per-column skip rule, 12 §2.5: columns changed since by others are
   skipped and reported, which drives the partial-undo toast); redo calls
   `SheetsEndpoint.reapplyChange(changeId)`.
8. Concurrency: edits by others during the restore are ordinary ops; the later arrival wins per
   column. The restore never blocks collaborators.

### 5.4 Named versions, copies, downloads
- *Name this version* / rename: `versions.*` endpoints (suite); not undoable (metadata).
- **Make a copy** (from a version or from the current state, *File › Make a copy*):
  `DriveEndpoint.copy` uses `SpaceCopier` (pure Dart, `wonky_sheets_core/lib/copy/`), which
  rewrites every id for the new file (row ids are global and can't move between files):
  new UUIDv7 for all entities; cell ids recomputed with `SheetsIds.cellId`; stored formula
  reference tokens remapped; `GridRange` JSON in rules, objects, pivots, named ranges and comments
  anchors remapped; script files copied (triggers not copied); the op log is not copied (the copy starts with its creation ops, `createFile`). Options:
  *Copy comments* (threads with remapped anchors), *Share with the same people*. From a version
  the copy is written on the client (a new file created with `initialize: false` whose first op group is the copy, 02 §4); the options are applied by
  `SheetsVersionEndpoint.copyExtras(source, target, anchorIdMapJson, copyComments, copySharing)`
  with the sheet/row/column id map of the copy (online only; a toast reports failures). The
  same
  `SpaceCopier` implements *Copy sheet to another spreadsheet* (single-sheet subset).
- **Download as…** from a version: XLSX/ODS/CSV/PDF exporters run on the in-memory model of
  the version (client) or server-side for large versions (`drive.export` with `versionId`).
  Implementation: `sheets.history.download {format}` (XLSX, ODS, CSV, TSV, HTML) runs the
  client exporters on the version's model; PDF (print route) and server-side exports of
  versions are not offered yet.

---

## 6. Cell edit history

*Show edit history* (cell context menu, `sheets.history.showCellHistory`) opens a popover
anchored to the cell:

```
┌ Edit history ─────────────── ‹  2 of 14  › ✕ ┐
│ (A) Anna Berg · Oct 10, 14:32                 │
│ Changed  "Pending" → "Done"                   │
│ via Paste                                     │
│                         [ Restore this value ]│
└───────────────────────────────────────────────┘
```

- Entries (newest first): author avatar/name (agent attribution for `mcp`/`ai`/`script`
  actors: "Script: onEdit (Anna)"), time, old → new value rendered as display text (formulas
  shown as `=SUM(B2:B9)` in A1 against the **current** structure; references to deleted rows
  show `#REF!`), the change label ("Paste", "Fill down", "Restore version") when not a plain edit.
  Labels are stored as stable English codes (shared log, other locales; `SheetsChangeLabels`)
  and localized when shown (`changeLabelText`; unknown labels, e.g. server or older clients',
  as stored; CQ-57).
- Bulk changes without per-cell details (`detailJson == null`) show "Changed as part of
  'Paste' (12,000 cells)" without values, and *Restore* is disabled.
- **Sources** (merged and de-duplicated by op revision):
  1. Local op metadata of the last 30 days whose `detailJson` contains the cell
     (`LoggedWorkbookSession.recentOps`, from the cache's `rev_local_op`; works offline;
     indexed client-side by a lazily built map cellId → revisions for the open spreadsheet).
  2. Server `cell_history` (older entries, up to 100 per cell) via
     `SheetsEndpoint.cellHistory(spreadsheetUuid, sheetId, rowId, colId, cursor)` when online
     (Editor+); entries carry the op's `revision`.
- Only **value** changes are listed (format changes are not, matching Google Sheets).
- *Restore this value* → `sheets.history.restoreCellValue {sheetId,rowId,colId,changeLogId}`
  (`changeLogId` holds the entry's op revision) writes the old content through the session
  (undoable, label "Restore value").
- Merged cells: history of the top-left cell. Cells that received content by cut/paste have
  their own history only (history follows cell ids, not moved content).
- `cell_history` population: the `cellHistory` post-commit hook (suite 17 part 5 §6.2) inserts
  each op's `detailJson` cells (`revision`, `before`, `after`, user, actor kind, label, at;
  `ON CONFLICT DO NOTHING`), so the history outlives the op log's 30-day payload retention,
  trimming to the latest 100 per cell.

---

## 7. Activity dashboard (Sheets specifics)

*The suite dashboard UI was removed (suite 07 §6); if it returns,* it adds a **Changes** tab for Editors+, computed from
the op log (`rev_op`, 30 days) + `ActivityEvent`:
- Edits per day chart (stacked by user, top 8 + "others", rendered with our chart engine).
- Contributors table: user, edits, last edit, most edited sheet.
- Sheets table: sheet, edits, last edited by/at.
- Agent activity: MCP/AI/script edit counts.
Data via `SheetsEndpoint.activitySummary(spreadsheetUuid, days)` (server aggregates; cached
10 min).

---

## 8. Change notification rules (P2)

*Tools › Notification settings › Editing notifications* dialog: "Notify me when: ○ Any changes
are made ○ Nothing (default)", "Notify me with: ○ Email – daily digest ○ Email – right away".

```yaml
class: SheetsNotificationRule          # server-only
table: sheets_notification_rule
fields:
  userId: int
  spreadsheetUuid: UuidValue
  mode: SheetsNotifyMode               # off, immediate, dailyDigest
  lastNotifiedAt: DateTime?
  lastNotifiedRevision: int?
indexes:
  sheets_notify_idx: { fields: spreadsheetUuid, userId, unique: true }
```

A post-commit hook (suite 17 part 5 §6) marks rules dirty; a FutureCall batches **immediate** notifications
every 15 min (suite email batching) and **daily** digests at 07:00 in the user's time zone.
Email content: per user who changed things, a list of "Sheet1: changed 14 cells in B2:F30,
inserted 2 rows" (from `summaryJson`), with a link to version history at that time. Own
changes are excluded. Users lose rules when they lose access.

---

## 9. Conflict UX

Ops apply in the order they reach the server, online and offline alike: **the last arrival
wins** per column, and a deleted row, column or sheet stays deleted (suite 17 part 1 Q1, RD-2,
RD-3). The server reports each acknowledged op's outcome (`RevOutcome`: `conflicts`, `dropped`,
`cascaded`; suite 17 part 6 §6), and the UI is shown only for ops made offline.

- **Help article** ("How simultaneous edits work", linked from the sync status details and the
  conflict toasts): the edit that reaches the server last wins per cell value and per format
  attribute; deleting a row, column or sheet wins over edits inside it; formulas never break
  when rows/columns move; offline edits are sent when you reconnect and may replace newer edits.
- **Partial undo**: the suite toast "Some changes couldn't be undone because they were edited
  by someone else." with *Details* (lists the skipped cells as A1 refs and who changed them,
  from the op metadata).
- **Offline edits that replaced newer edits (P1)**: when an offline op overwrote values that
  another user had written after the op's base (outcome `conflicts`), the author sees the toast
  "Your offline changes replaced {n} newer edits by {name} — Review". The review dialog lists
  cell, your value, their previous value and author, with *Restore theirs* (undoable, one step)
  and *Dismiss*.
- **Dropped offline edits**: edits into a row, column or sheet that another user deleted
  (outcome `dropped`) appear as "Row deleted by {name}" / "Column…" / "Sheet…" (no apply). The
  deleter comes from the local op metadata (`rev_local_op`) or the server's op range. A deleted
  row's cells that the offline user created before the delete arrived are cascaded; the deleter
  sees "Also removed {n} cells added by {name}" (`cascaded`, P2; logged in P1).
- **Sorts**: a `sheet_row.sortKey` conflict on at least half the rows of an offline sort gives
  "Your sort was replaced by a newer sort from {name}".
- Outcomes are kept in the cache (`rev_outcome`) until reviewed or 7 days old.
- **Rejected protected-range edits**: the server rejects an op that writes cells, structure,
  rules, objects or sheets protected from its author (suite 17 part 5 §3.5; 07 §10.3), e.g. an
  edit made offline before the protection arrived. The whole op group is rolled back on the
  client, its undo step removed, and the toast "“{label}” wasn’t saved because it edits a
  protected cell or object." is shown (03 §16). For offline ops the toast also offers *Save my
  changes as a copy*: a new spreadsheet (`initialize: false`) from the server state plus the
  rejected group, kept 7 days (suite 17 part 6 §4.6, §8).

> **As built.** The review is fed by tracking, not yet directly by outcomes (suite 17, As built
> 11): `SheetsConflicts` (`features/history/local_conflicts.dart`) records the cells and sorts
> written offline (`sheets.offlineEdits.<item>` in the user's local store), waits until the outbox drained after reconnecting (`session.whenSynced`),
> compares the tracked cells with the model and finds the deciding op in the local op metadata
> (details, else ranges; deletions from `summaryJson.deleted`). It reports offline edits that a
> later op of someone else replaced or dropped — "{n} of your offline edits were replaced by
> newer edits from {name}" — with *Apply mine again* (`sheets.conflicts.applyMine`, one undo
> step of `RestoreCellValue`s) and *Dismiss*; conflicts are kept as `LocalConflict`s in the
> user's local store (`sheets.conflicts.<item>`, 7 days). The "you replaced newer edits" review
> with *Restore theirs* is not built. *Save my changes as a copy* on a rejection is not built
> either (As built 10): the rejected group is only rolled back with the toast.

---

## 10. Offline collaboration scenarios

Two users, Anna (A) and Bo (B), both offline, then both reconnect. "Later arrival" = the op the
server sequenced later (higher revision), whatever the time the edit was made.

| # | Scenario | Data-model behavior | Expected outcome | UX |
|---|----------|--------------------|------------------|----|
| 1 | A and B type different values into **the same cell** C5 | Same deterministic `Cell` id → one row; the inserts merge per column (non-null columns), `content` last arrival wins | The later arrival's value wins everywhere. Formats set by either survive per attribute. | The later arriver gets the "replaced newer edits" review (§9). Edit history shows both entries. |
| 2 | A edits C5, B edits D5 (**same row**, different cells) | Different cell rows | Both values survive | — |
| 3 | A sets C5 = 10, B makes C5 bold | Different columns of the same cell row | Both survive (C5 = 10, bold) | — |
| 4 | A and B both **insert a row** below row 4 and type into it | Both generate `FractionalIndex.between(k4, k5)` → possibly identical `sortKey`s; tie broken by row `id` | Two new rows, both kept, in a deterministic order (same on all clients); both rows' contents intact | Users may see their row at index 5 or 6. |
| 5 | A **deletes row 7**, B edits cells in row 7 | The sequencer deletes the row and cascades its cells (A's plan lists the cells it loaded); B's later changes to the row are dropped (`dropped`); cells B created before A's delete arrived are cascaded (`cascaded`) | Row 7 is gone. B's edits are not visible | B gets the review entry "Row deleted by Anna". If A undoes the delete, A's undo restores the cells A's plan deleted; cells B created after the delete was committed are not revived. A sees "Also removed n cells added by Bo" for cells cascaded (P2). |
| 6 | A edits C5, B **deletes column C** | Same as 5 | Column gone | as 5 |
| 7 | A **deletes sheet** "Q3", B edits it | Sheet deleted, cascades | Sheet gone; B's edits lost | Review: "Sheet deleted by Anna"; A's undo restores the sheet. |
| 8 | A and B **sort the same range** by different columns (full-row sort rewrites `SheetRow.sortKey`, see [07-data-tools.md](07-data-tools.md)) | Each row's `sortKey`: last arrival wins | Rows written by the later-arriving sort take its keys. If both sorts covered the same rows, the final order is exactly that sort's order. Rows inserted by the other user meanwhile keep their own keys and land between neighbors. | No corruption: rows move as units. The earlier sorter, if offline, gets the toast "Your sort was replaced by a newer sort from Bo" (P1, from `sortKey` conflicts). |
| 9 | A sorts a **partial range** (content move), B edits a cell inside it | Range sort moves `content`/format columns between cells; per cell, last arrival wins | The later arrival per cell wins. The data can end up mixed (B's value in a cell whose row now holds A's sorted data). | Documented limitation. The sort dialog shows "Sorting part of a table while others edit it can mix rows — sort entire rows instead" when collaborators are present. Review dialog lists overwritten cells. |
| 10 | A and B **rename different sheets to the same name** "Q1" | Not a DB constraint; client maintenance rename rule (`WorkbookMaintenance`, 02 §8) | The sheet with the larger id becomes "Q1 (2)" (deterministic, first client to notice writes it) | Formulas use sheet ids, so nothing breaks. **As built:** `WorkbookMaintenance` isn't run by the app yet (02 §8), so both sheets keep "Q1". |
| 11 | A and B **rename the same sheet** differently | `Sheet.name`: last arrival wins | Later arrival's name wins | Review entry for the offline author whose rename replaced the other (P1). |
| 12 | A and B **insert columns** at the same place and write formulas referencing them | Formulas store id tokens | Both formulas reference the intended columns | — |
| 13 | A merges A1:B2, B merges B2:C3 (**overlapping merges**) | Two `MergedRange` rows overlap; client maintenance keeps the smaller id (02 §8) | One merge survives; the other is removed deterministically | Toast for the loser (P1). |
| 14 | A and B **paste overlapping ranges** | Per cell, last arrival wins | Per cell, the later-arriving paste wins: the overlap can mix | Review for overwritten cells. |
| 15 | A writes `=SUM(B2:B9)`, B **deletes row 9** | Token for row 9 no longer resolves | Range shrinks to B2:B8 (range ends adapt like insert/delete in Sheets: the deleted bound moves to the next surviving row); a single deleted reference gives `#REF!` | — |
| 16 | A **undoes** an edit after B changed the same cell | Undo per-column skip rule | A's undo skips C5 | Partial-undo toast. |
| 17 | A and B add **conditional format rules** to overlapping ranges | Independent rows ordered by `sortKey` | Both rules exist; priority by `sortKey` | — |
| 18 | A moves a chart, B edits its title | See [08-charts-and-objects.md](08-charts-and-objects.md) §15.2 | Both survive | — |
| 19 | A and B edit the **same script file** | `ScriptFile.source`: last arrival wins (whole file) | Later-arriving save wins | Online: conflict dialog before saving; offline: loser's text kept in local script history ([09-scripting.md](09-scripting.md) §14.3). |
| 20 | A **changes the locale**, B types `1,5` offline | B's client parsed input with the old locale at typing time (content stored typed, e.g. `n:1.5`) | Value stays 1.5; display follows the new locale | — |
| 21 | A creates a spreadsheet offline, B can't see it yet | Client file UUID; the drive create is queued and the creation op is the first outbox op (02 §4) | Visible to collaborators after A reconnects and shares | — |
| 22 | A is downgraded to viewer while offline with pending edits | The resend is rejected (`forbiddenForRole`); the outbox is kept | A's pending edits are not applied | Read-only, toast "You can no longer edit this spreadsheet", *Save my changes as a copy* (suite 17 part 6 §8). **As built:** the copy offer is not built (suite 17, As built 10). |
| 23 | A edits B4 offline; meanwhile the owner protects column B ("Only me") | The sequencer's protection check rejects A's op (`protectedRange`, suite 17 part 5 §3.5) | B4 keeps the owner's value; nothing of A's op group is applied | A sees the blocked message with *Save my changes as a copy* (§9; as built: the message only). |
| 24 | A (not a protection editor) uses a stale or modified client to write a protected cell | Rejected by the server (`protectedRange`) | Nothing is written | The rejection toast (§9). |

Each row of this table is a test case of the multi-client tests against the in-process RevLog
server (`FakeRevServer`/`FakeRevHub`, suite 17 As built 16;
`wonky_sheets/test/features/collab/offline_scenarios_test.dart`,
`rejections_test.dart`).

---

## 11. Commands

| Command id | Args | Undoable | Role |
|------------|------|----------|------|
| `sheets.presence.jumpTo` | `{sessionId}` | — | Viewer+ |
| `sheets.presence.follow` / `unfollow` | `{sessionId}` | — | Viewer+ |
| `shell.comments.create` (Sheets anchor) | `{anchor?: {sheetId,a1}, body, mentions, assigneeId?}` | ✓ (`comments`) | Commenter+ |
| `sheets.comments.next` / `previous` | — | — | Viewer+ (if visible) |
| `sheets.comments.openPanel` | `{scope?: sheet\|all}` | — | |
| `sheets.notes.insert` | `{cell?: A1, text?}` | ✓ | Editor |
| `sheets.notes.clear` | `{ranges?}` | ✓ | Editor |
| `sheets.notes.convertToComments` (P2) | `{ranges?}` | ✓ | Editor |
| `sheets.history.open` | `{versionId?}` | — | Editor+ (suite: version history requires edit access) |
| `sheets.history.nameCurrentVersion` | `{name}` | — | Editor |
| `sheets.history.restoreVersion` | `{versionId}` | ✓ (`sheets.serverChange`) | Editor |
| `sheets.history.makeCopy` | `{versionId?, name, folderUuid?, copyComments, copySharing}` | — (Drive) | Viewer+ (if copying allowed) |
| `sheets.history.toggleShowChanges` | — | — | |
| `sheets.history.download` | `{format}` | — | Editor+ (history route) |
| `sheets.history.nextChange` / `previousChange` | — | — | |
| `sheets.history.showCellHistory` | `{cell?: A1}` | — | Editor |
| `sheets.history.restoreCellValue` | `{sheetId,rowId,colId,changeLogId}` | ✓ | Editor |
| `sheets.conflicts.review` | — | — | Editor |
| `sheets.conflicts.applyMine` | `{conflictIds}` | ✓ | Editor |
| `sheets.notifications.openSettings` (P2) | — | — | Viewer+ |

---

## 12. MCP mapping

| Need | Tool |
|------|------|
| List/create/reply/resolve comments | suite `comments.*` with Sheets anchor `{"sheet": "Sheet1", "a1": "B4"}` (or `"a1": "B4:D9"` → range anchor). Results include `a1` computed from ids and `orphaned`. |
| Versions | suite `versions.list`, `versions.name_current`, `versions.restore` (returns `change_id`), `versions.get(format: "values", range: "Sheet1!A1:D20")` → values JSON from the snapshot model; `format: "diff"` (Sheets extension) → changed cells vs previous version with authors. |
| Cell history | `sheets.get_cell_history` ([12-mcp-and-ai.md](12-mcp-and-ai.md) §3.11) |
| Presence | `ui.get_state` includes collaborators; no headless presence tool (agents appear automatically). |

---

## 13. Packages and folders

| Location | Content |
|----------|---------|
| `wonky_sheets/lib/features/collab/presence/` | presence controller, layers, follow mode, tab avatars |
| `wonky_sheets/lib/features/collab/hints/` | `CommitHintSender`, `CommitHintOverlay` |
| `wonky_sheets/lib/features/comments/` | Sheets anchors, indicators, docked thread cards, panel scope filter, cut/paste anchor updates |
| `wonky_sheets/lib/features/history/` | history route, snapshot loader, diff view, cell history popover, conflict review |
| `wonky_sheets_core/lib/snapshot/` | snapshot codec (read/write), diff algorithm (pure Dart; used by client and server) |
| `wonky_sheets_core/lib/copy/` | `SpaceCopier` |
| `wonky_server/lib/src/sheets/versions/` | `SheetsVersionProvider`, scheduler, restore, diff cache |
| `wonky_server/lib/src/sheets/revlog/sheets_hooks.dart` | post-commit hooks (suite 17 part 5 §6.2): orphaning, `cell_history`, version state, script compile and trigger enqueue |
| `wonky_server/lib/src/sheets/changelog/agent_cursors.dart` | agent cursors after tool writes |

---

## 14. Additions to 02-data-model

| # | Change |
|---|--------|
| A-10-1 | The op summary (`summaryJson`) gains `deleted: {rows: [ids], cols: [ids], sheets: [ids]}` and `revived: {…}` (capped at 1,000 ids each; beyond that `structureOverflow: true` makes the server rescan anchors of affected sheets). |
| A-10-2 | `CommentThread` (suite table) gains `orphanReasonJson: String?` and `statusBeforeOrphan: CommentStatus?` (applied in suite 07 §2.1). |
| A-10-3 | Server tables `ItemVersionState` (shared by both apps: `itemId, lastEditAt, dirtySince, lastVersionAt, editorsSinceLastVersion: List<int>, lastRevision`; replaces the proposed `SheetsVersionState`) and `SheetsSnapshotIndex(itemVersionId, sheetsJson, changedRangesJson, authorIds: List<int>, diffFileId?)`. |
| A-10-4 | Local-only records `PendingCommentOp(opId, threadUuid, kind, payloadJson, createdAt)` and `LocalConflict(id, spreadsheetId, sheetId, rowId, colId, column, myValue, theirValue, theirUserId, changeLogId (the deciding op's revision), detectedAt, dismissed)` — kept as JSON in the user's `LocalStore` (not cache tables). |
| A-10-5 | New undo domain `sheets.serverChange` (entry = `{changeId}`); undo → `SheetsEndpoint.revertChange`, redo → `reapplyChange`. Shared with MCP-originated changes surfaced in the UI. |
| A-10-6 | `PresenceUpdate.hints` / `PresenceEvent.Hints` and `FollowerCount` event (suite 07 protocol extension). |

---

## 15. Acceptance criteria

1. Two windows on the same sheet: B sees A's active cell border, range fill and name flag
   within 200 ms of A moving; A's committed value appears in B's grid within 300 ms (the remote
   op, suite 17 part 7 P1) without flicker.
2. Tab avatars show who is on which sheet; *Follow* tracks the followed user's sheet and
   viewport until local interaction.
3. A comment on B4 stays on the same logical cell after inserting rows above, sorting the
   table, and moving column B; deleting row 4 orphans it; undoing the deletion restores it as
   open.
4. Cut B4 → paste to F10 moves the comment to F10; one undo restores both.
5. Version history shows auto versions after 5 min of inactivity; selecting a version renders
   it read-only with changed cells outlined in author colors, and *Next change* navigates them.
6. Restoring a version with 100k cell differences completes with progress, appears to
   collaborators live, and one Mod+Z (online) reverts it except for cells edited by others
   since (partial-undo toast).
7. *Make a copy* from a version produces an independent spreadsheet whose formulas, charts,
   CF/DV rules, pivots and comments (if chosen) work and point at the copy.
8. *Show edit history* lists previous values with authors offline (last 30 days) and online
   (older), and *Restore this value* is undoable.
9. Every scenario in §10 passes in the multi-client tests with the stated outcome.
10. Offline edits that replaced newer edits produce a review toast and *Restore theirs* works;
    an offline edit into a range protected meanwhile is rejected with the blocked message.

## 16. Tests

- Unit: presence cursor mapping (ids → rects, unknown ids), hint overlay expiry rules, comment
  anchor mapping for cut/paste, snapshot codec round-trip (all tables, nulls, unicode),
  diff algorithm (content/format/structure), `SpaceCopier` remapping (formulas, GridRanges,
  objects, comments), cell-history merge/dedupe.
- Server (`serverpod_test`): capture policy timing (fake clock), restore diff/apply with
  concurrent writes, restore refused by the protection pre-check, revert of restore with
  per-column skip, orphaning/revival from op summaries (`comments` hook), `cell_history`
  population (`cellHistory` hook) and trimming, version windows by revision (an offline edit
  committed late belongs to the version whose revision window contains it), notification
  batching.
- Multi-client (in-process RevLog server, `FakeRevServer`): §10 table (each row a test,
  including the `protectedRange` rejections of scenarios 23–24), outcomes (`conflicts`,
  `dropped`) driving the review, hint behavior with 3 clients.
- Golden: remote cursor rendering (light/dark, overlaps, editing state), comment/note
  indicators, history diff highlighting.
- Performance: snapshot capture and load of 1M cells (< 10 s capture, < 8 s load on desktop),
  diff of two 1M-cell snapshots server-side < 5 s.
