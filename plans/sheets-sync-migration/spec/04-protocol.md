# RevLog spec 04 · Protocol

The protocol is generic: one set of message models for both apps, under
`wonky_server/lib/src/platform/revlog/messages/` (sealed bases with their variants in the same
folder, as Write's `write/messages/`; inventory write-infra §4). Each app gets a thin endpoint
that names its binding.

## 1. Endpoints

```dart
/// wonky_server/lib/src/sheets/endpoints/sheets_doc_endpoint.dart (Slides: slides_doc_endpoint.dart)
class SheetsDocEndpoint extends Endpoint {
  @override bool get requireLogin => true;

  /// Opens an editing/viewing session on a spreadsheet (§2).
  Stream<RevServerMessage> connect(Session session, UuidValue fileUuid, int knownRevision,
      String tabId, Stream<RevClientMessage> input) async* {
    yield* RevLogConnection.open(session, SheetsRevBinding.instance, fileUuid, knownRevision,
        tabId, input);
  }

  /// Bootstrap page (§3). Viewer+.
  Future<RevPage> page(Session session, UuidValue fileUuid, RevPageRequest request);

  /// Ops in (from, to]: ≤ 1,000 ops and ≤ 1 MiB compressed (fewer if a limit is hit; the
  /// caller continues from the last returned revision). Access rule: 05 §11.
  Future<List<RevOpView>> ops(Session session, UuidValue fileUuid, int fromRevision, int toRevision);

  /// Head revision, role and stats without opening a stream (background sync, Settings). Viewer+.
  Future<RevFileInfo> info(Session session, UuidValue fileUuid);
}
```

Endpoint names on the client: `client.sheetsDoc.*` and `client.slidesDoc.*`. File creation stays
with the drive endpoints (§5).

`tabId` is a random id per app instance (browser tab or desktop process), stable for its
lifetime. It tags the connection so that the server can skip echoes to the sending connection
(§2.2) and so that roster entries are per tab.

## 2. Stream messages

### 2.1 Client → server (`sealed class RevClientMessage`)

```yaml
class: RevSubmit
extends: RevClientMessage
fields:
  clientOpId: UuidValue          # idempotency key (same on every resend)
  baseRevision: int
  payload: String?               # codec JSON (03 §3) incl. "sum"/"det", when ≤ compressAboveBytes
  payloadGz: ByteData?           # gzip of the same JSON otherwise (exactly one of the two is set)
  label: String
  actorKind: ActorKind           # user | script (03 §5 rule 5)
  groupId: String?
  groupIndex: int
  groupLast: bool
  offline: bool
  createdAt: DateTime            # client clock, display only
```

| Message | Fields | Meaning |
|---------|--------|---------|
| `RevSubmit` | above | One op (03 §2). Sent only after it is durable in the outbox (06 §4.1) |
| `RevRequestOps` | `fromRevision`, `toRevision` | Gap fill. The server answers with `RevRemoteOp`s, the same byte cap applying as for `ops()` |
| `RevPing` | `t` | Keep-alive and latency, every 30 s (as Write) |

The payload JSON adds two keys to the codec object of 03 §3.1:

- `"sum"`: the summary JSON;
- `"det"`: the detail JSON, or absent.

### 2.2 Server → client (`sealed class RevServerMessage`)

| Message | Fields | Meaning |
|---------|--------|---------|
| `RevInit` | `revision`, `role: AccessRole`, `sessionId`, `schemaHash`, `acceptedHashes: List<String>`, `stats` (02 §1.1), `prunedBelow`, `ops: List<RevOpView>?`, `more: bool`, `bootstrap: bool` | First message. **`ops`:** the ops in (`knownRevision`, `revision`] when `knownRevision ≥ prunedBelow` and there are at most `opsInInit` of them. The list is cut at 1 MiB compressed, and `more: true` tells the client to gap-fill the rest with `ops()`. **`bootstrap: true`:** the gap is too large or pruned, and the client must (re)load pages (06 §5) |
| `RevAck` | `clientOpId`, `revision`, `duplicate: bool`, `applied?` / `appliedGz?`, `outcome?` | The op was committed as `revision`. **`applied`** (the codec JSON of the applied form without `before`, 03 §4.7) is present iff the applied form differs from the submitted changes (`rev_op.appliedEqualsSubmitted == false`). The client stores the applied form (or its own submitted changes when absent) as server state (06 §4.4). **`outcome`** is JSON for the UI (below); absent when empty |
| `RevRemoteOp` | `revision`, `clientOpId`, `payload?` / `payloadGz?` (applied form, no `before`), `authorUuid`, `authorSessionId`, `actorKind`, `label`, `summaryJson`, `detailJson?`, `offline`, `groupId?`, `groupIndex`, `groupLast`, `recordId?`, `onBehalfOfSessionId?`, `committedAt` | An op committed by **another connection**. The sending connection never receives its own op as a `RevRemoteOp`: it gets `RevAck` (Write's rule, `document_connection.dart:309`). Other tabs of the same user receive it like any remote op |
| `RevRejected` | `clientOpId?`, `code: RevRejectCode`, `message`, `detailsJson?` (code-specific, e.g. the protections hit for `protectedRange`) | The op was not committed (§4). `clientOpId == null` means a session-level error, and the server closes the stream after sending it |
| `RevRoleChanged` | `role: AccessRole` | Effective role changed (sharing, expiry, editor limit) |
| `RevResync` | `reason: String` | The server can't continue this session incrementally (for example after an admin repair). The client re-bootstraps (06 §5) |
| `RevPong` | `t`, `headRevision` | `headRevision` lets the client detect a lost bus message and gap-fill (05 §5) |

**Outcome JSON** (in `RevAck.outcome` and `RevOpView.outcomeJson`; for the UI only, since the
state is carried by the applied form):

```jsonc
{
  "dropped":   [ {"t":"cell","id":"<b62>","op":1,"reason":"rowMissing|parentMissing"} ],
  "conflicts": [ {"t":"cell","id":"<b62>","col":"content",
                  "theirs":"n:5", "byUser":"<uuid>", "byRev":4211} ],     // overwritten (last arrival wins, Q1)
  "cascaded":  [ {"t":"cell","id":"<b62>"} ],
  "truncated": false
}
```

Each list is capped at 500 entries; `truncated: true` marks a capped list. Capping never affects
state.

### 2.3 Views

```yaml
class: RevOpView        # in RevInit.ops and ops()
fields:
  revision: int
  clientOpId: UuidValue
  payload: String?            # applied form without before (null if pruned — never returned then)
  payloadGz: ByteData?
  authorUuid: UuidValue?
  authorSessionId: String?
  actorKind: ActorKind
  label: String
  summaryJson: String?
  detailJson: String?
  offline: bool
  groupId: String?
  groupIndex: int
  groupLast: bool
  recordId: UuidValue?
  onBehalfOfSessionId: String?
  outcomeJson: String?        # lets the author recover a lost ack's outcome
  committedAt: DateTime

class: RevFileInfo
fields:
  fileUuid: UuidValue
  revision: int
  role: AccessRole
  schemaHash: String
  stats: String               # 02 §1.1
```

## 3. Bootstrap pages

```yaml
class: RevPageRequest
fields:
  kind: RevPageKind          # structure | rows | cells
  cursor: String?            # structure/rows: JSON {"t": <tableIdx>, "after": "<id>"} from the previous page; null = start
  table: String?             # kind == rows: the table (keyset over id)
  sheetId: UuidValue?        # kind == cells (Sheets)
  rowIds: List<UuidValue>?   # kind == cells: ≤ pageRows sheet rows
  maxRows: int               # server caps at structurePageRows (structure/rows) or pageRows (cells)

class: RevPage
fields:
  revision: int              # exact revision of every row in this page (05 §7)
  body: ByteData             # gzip NDJSON (§3.1), ≤ 4 MiB
  coverage: List<String>     # coverage keys (§3.2)
  excludedTables: List<String>   # structure: tables the client must load with kind == rows
  nextCursor: String?        # structure/rows: cursor of the next page; null = done
```

### 3.1 Page body

One NDJSON line per row, with the same column dictionary approach as the codec:

```
{"t":["spreadsheet","sheet",…],"c":[[…],[…]]}           ← header line: tables and their columns
[0,"<b62 id>",[…values…]]                               ← [tableIdx, id, values aligned with c[tableIdx]]
```

Values use the codec encoding (03 §3.2). Nulls are written; there are no "absent" sentinels.

### 3.2 Coverage

A page is **authoritative** for a set of rows at `revision`. Every row in that set is either in
the page (its state at `revision`) or does not exist at `revision`. Coverage keys are the same
strings the client stores in `rev_coverage` (02 §3).

| Key | Meaning |
|-----|---------|
| `tbl:<table>:<fromId>:<toId>` | Every row of `<table>` with id in (`fromId`, `toId`]. `fromId` = `-` for the start, `toId` = `+` for the end |
| `row:<sheetId>:<rowId>` | Every cell of that sheet row (Sheets) |

**Structure pages** walk the non-cell tables in rank order with a cursor `{t, after}`. A
structure page carries one `tbl:` key per table it touched. Tables with more than 50,000 rows for
the file (per `RevInit.stats.tables`) are listed in `excludedTables` on the first structure page;
the client loads them with `rows` pages instead (two in parallel, 06 §5.2).

## 4. Rejection codes (`enum RevRejectCode`)

| Code | When | Client reaction (06 §4.6, §8) |
|------|------|-------------------------------|
| `invalidChange` | Schema/type/limit violation, a foreign id, an immutable column (03 §5) | Drop the op **and the rest of its group**; roll the model back; drop or trim the plan's undo step; one toast; error log |
| `tooLarge` | Op or message over the limits | Same as `invalidChange` (a chunker bug) |
| `limitExceeded` | Cell cap, sheet count | Same, with the server's message ("This spreadsheet has reached the limit of 1,000,000 cells") |
| `protectedRange` | The op writes protected cells, structure, rules, objects or sheets the author may not edit (05 §3.5). `detailsJson` lists the protections hit | Same as `invalidChange` (drop the group, roll back, drop the undo step), with the blocked-cell message (`GuardResult.blockedMessage`). For `offline` ops, also offer *Save my changes as a copy* (06 §4.6). A repair op isn't retried for 24 h (03 §6) |
| `forbiddenForRole` | Role below Editor (ACL or editor limit), or a table needing a higher role | Keep the outbox, switch to read-only, offer *Save my changes as a copy* |
| `forbidden` | No access at all (session-level; the stream closes) | Unavailable state "You no longer have access…" (outbox kept for the copy offer) |
| `unknownBase` | `baseRevision` > head (the client is ahead of the server, e.g. a restored server database) | Re-bootstrap; offer the outbox as a copy |
| `schemaMismatch` | Payload `"s"` not accepted (02 §4.3) | Stop sending; "Update required" |
| `notFound` | The file doesn't exist (yet) | If a create for this file is queued: wait (06 §5.1). Else unavailable |
| `fileReadOnly` | The file is trashed or being purged | Read-only with the drive's trashed banner |
| `internal` | Unexpected server error | Retry with backoff, same `clientOpId` (idempotent) |

A rejection means **the op is not in the log**: none of its changes were applied.

## 5. File creation (drive endpoints)

```dart
Future<DriveItemView> createSpreadsheet(Session s, UuidValue? parentUuid, String name,
    UuidValue? templateUuid, {String? locale, String? timeZone,          // existing params, kept
     UuidValue? fileUuid, bool initialize = true});                      // new
Future<DriveItemView> createPresentation(Session s, UuidValue? parentUuid, String name,
    UuidValue? templateUuid, {UuidValue? fileUuid, bool initialize = true});
```

- **Idempotency.** With `fileUuid` the call is idempotent: a retry returns the existing item, and finishes initialization if `initPending` (05 §8.3).
- **`initialize: true`.** The server writes the content as revision 1…: the template's rows, or the default content (`SpreadsheetFactory` with locale, time zone and the user's default fonts from `SheetsCreateDefaults`; `DeckFactory` for decks).
- **`initialize: false`.** The file stays at revision 0 and **the client's first op creates the rows**. Used by every client-side creation that writes its own content:
  - offline creation (queued in `PendingDriveOp`);
  - online creation from the Sheets/Slides apps when the client already holds the content: built-in Slides templates and blank decks, version copies, import-as-new (06 §7).
- The Drive app's *New*, MCP, AI and welcome content use `initialize: true`.

| Removed | Replacement |
|---------|-------------|
| `drive.registerSpreadsheet`, `drive.registerPresentation` | `create*(fileUuid, initialize: false)` |
| `sheets.reserveSpaces`, `slides.reserveSpaces`, `subscribe`, `unsubscribe`, `ensureSubscribed`, `spaceStats`, `sheetsSync.sync`, `slidesSync.sync` | nothing (`info`, `connect`) |

`PendingDriveOp` gains the kinds `createSpreadsheet` and `createPresentation` (args `fileUuid`,
`parentUuid`, `name`, `initialize: false`). They replace `registerSpreadsheet` and
`registerPresentation` (06 §7).

**Title of a file created with `initialize: false`.** The creation op inserts the root row with
the title the client had. If the drive item was renamed in between (a queued rename replays
before the creation op arrives), the sequencer sets the root row's title to the drive item's
current name while applying the creation op. The applied form then differs from the submitted
one, so the author learns the title from `RevAck.applied`. This is the only server-side
adjustment in this migration (RD-14).

## 6. Sequences

### 6.1 Edit while online

```
client A (tab 1)                         server                          client B
  |-- RevSubmit(c1, base=40) ------------>|  validate, lock, apply, rev_op 41, head=41, commit
  |                                       |-- bus rev:<file> (immediate) --------------> RevRemoteOp(41)
  |<---------- RevAck(c1, 41[, applied, outcome]) --|
  |                                       |-- hooks (debounced, after the ack)
```

### 6.2 Concurrent edits

A's op is committed as 41; B's op (base 40) as 42. On one instance, B receives
`RevRemoteOp(41)` before `RevAck(42)`, because the server posts under the file lock in revision
order. Across instances, `RevAck(42)` can arrive first. In both cases B processes
revision-carrying messages strictly in order (06 §4.3): the ack waits for 41, which arrives by
bus or by gap fill. B applies 41 through the
overlay (its own op stays on top), then the ack of 42 moves 42 from the outbox into server
state. If 41 and 42 wrote the same field, the ack's outcome lists a conflict with `byRev: 41`
(when A is another user).

### 6.3 Reconnect after offline

```
client: outbox = [c7 (inflight), c8, c9 (buffered, composed)]
  |-- connect(knownRevision=40) ----------->|
  |<----------- RevInit(revision=55, ops 41..55, more=false) --|   (or bootstrap:true)
  | apply 41..55 through the overlay; an op whose clientOpId is c7 is our own committed op → ack c7
  |-- RevSubmit(c7, …) (if still unacked) ------------>|   idempotent: returns the original revision
  |<-------------------------------------- RevAck ------|
  |-- RevSubmit(c8+c9 composed) ---------------------->|
```

- **No age limit for transform.** The server never refuses an old base, since ops need no transform. The only age limits are the idempotency horizon (slim op rows kept 365 days) and the client's 180-day outbox age (01 §4).
- **Own op in the catch-up.** An op in `RevInit.ops` or `ops()` whose `clientOpId` is in this tab's outbox is the tab's own committed op; its ack was lost. The client treats it as the ack and takes the outcome from `outcomeJson`.

### 6.4 Cold open of a file not on the device

```
  |-- connect(0) ------------------------------->|
  |<-- RevInit(revision=R0, bootstrap:true, stats) --|   later ops arrive as RevRemoteOp
  |-- page(structure, cursor=null) --------------->|   in parallel: rows pages of excluded tables,
  |-- page(cells, sheet S, top-20..top+200) ------>|   then the viewport cells
  |<------ RevPage(rev=R1, coverage …) ------------|   apply page + buffered ops > R1 for covered rows
  |   … WorkbookReady after structure + first cells; the remaining pages stream in (06 §5) …
```
