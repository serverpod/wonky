# Write 03 · Real-time Sync Protocol (Quill Delta OT over Serverpod Streams)

Wonky Write uses **server-authoritative operational transformation** (Jupiter/ot.js model):
the server totally orders operations by **revision**; each client keeps at most one operation
in flight; concurrent ops are transformed with `dart_quill_delta`'s
`Delta.transform(other, priority)`; cursors with `transformPosition`; undo with
`Delta.invert(base)`.

## 1. Stream endpoint

```dart
class DocumentEndpoint extends Endpoint {
  /// Opens an editing/viewing session on a document.
  Stream<DocServerMessage> connect(
    Session session,
    UuidValue documentUuid,
    int knownRevision,              // revision of the client's cached snapshot (0 = none)
    Stream<DocClientMessage> input,
  );

  // Non-streaming helpers
  Future<DocumentInfo> getInfo(Session s, UuidValue documentUuid);
  Future<List<DocumentOpView>> getOps(Session s, UuidValue documentUuid, int fromRevision, int toRevision);
  Future<DocumentSnapshotView> getSnapshot(Session s, UuidValue documentUuid, int? revision);
  Future<void> updateMeta(Session s, UuidValue documentUuid, DocumentMetaPatch patch, UuidValue clientOpId);
}
```

All message classes are Serverpod models with sealed base classes (`DocClientMessage`,
`DocServerMessage`) so the typed streams can carry variants. The generated classes carry a `Doc`
prefix to keep the client namespace clean: `DocSubmitOp`, `DocCursorUpdate`, `DocRequestOps`,
`DocPing`, `DocHashCheck` (client → server) and `DocInit`, `DocAck`, `DocRemoteOp`, `DocRemoteCursor`,
`DocParticipantJoined`, `DocParticipantLeft`, `DocMetaChanged`, `DocRoleChanged`, `DocOpRejected`
(`code: DocRejectCode`), `DocPong`, `DocHashResult` (server → client).

### 1.1 Client → server

| Message | Fields | Meaning |
|---------|--------|---------|
| `SubmitOp` | `clientOpId`, `baseRevision`, `deltaJson`, `kind` | A local change based on `baseRevision` |
| `CursorUpdate` | `revision`, `anchor`, `head`, `focused` | Local selection as Delta offsets at `revision` (throttled 10/s) |
| `RequestOps` | `fromRevision`, `toRevision` | Gap fill. Below Editor (and in `getOps`) only the ops of the last 1,000 revisions are served; older ops are history (Editor+, like old snapshots) |
| `Ping` | `t` | Keepalive / latency measurement |

### 1.2 Server → client

| Message | Fields | Meaning |
|---------|--------|---------|
| `Init` | `revision`, `snapshotJson?`, `ops[]?`, `meta`, `role`, `participants[]` | Snapshot (if client is too far behind) or ops since `knownRevision` |
| `Ack` | `clientOpId`, `revision` | Your op was applied as `revision` |
| `RemoteOp` | `revision`, `deltaJson`, `authorId`, `authorSessionId`, `actorKind`, `onBehalfOfSessionId?`, `groupId?` | Someone else's op (already transformed to apply on `revision-1`). For AI/MCP ops executed server-side on behalf of a user's live session, `onBehalfOfSessionId` lets that session put the op on its own undo stack (grouped by `groupId`) — see [09 §5.2](09-mcp-and-ai.md) |
| `RemoteCursor` | `sessionId`, `userId`, `revision`, `anchor`, `head`, `focused` | Collaborator selection |
| `ParticipantJoined` / `ParticipantLeft` | participant / sessionId | Write-local presence (mirrors shared presence roster) |
| `MetaChanged` | `field`, `valueJson`, `authorId` | Theme/page setup/language/title changed |
| `RoleChanged` | `role` | Your effective role changed |
| `OpRejected` | `clientOpId`, `code`, `message` | Validation/permission failure; client must resync |
| `Pong` | `t` | |

## 2. Server algorithm

Per document, operations are serialized across server instances with a **Postgres row lock**
on `document` (`SELECT … FOR UPDATE` in a transaction); within one instance an in-memory
`DocumentSession` (per document, created on first connect, disposed 60 s after the last client
leaves, or 60 s after its last headless use by MCP, AI or a restore) caches the head document
Delta and recent ops (last 1,000) to avoid DB reads.

On `SubmitOp(clientOpId, base, A)`:
1. **Idempotency**: if `(documentId, clientOpId)` exists → reply `Ack` with its revision. Checked
   again after the row lock (step 3), and a unique violation on `clientOpId` is also a duplicate,
   so a resend racing on another socket or instance gets the same `Ack`.
2. **Permission and size**: role ≥ editor, or commenter-restricted op (§5). Ops over 1 MiB of
   JSON or with more than 20,000 components → `OpRejected(code: tooLarge)` before they are
   decoded or transformed (server-computed restores are exempt).
3. Lock the document row; load `head`.
4. If `base < head`: load ops `base+1…head` (cache or DB), compose them into `S`, and transform:
   `A' = S.transform(A, true)` (server ops win ties: their inserts go first).
   If `base` is older than retained ops → `OpRejected(code: rebaseTooOld)`.
5. Apply `A'` to the head doc → `D'`; run `WonkyDeltaNormalizer` (may append fix-up ops, e.g.
   embed identity rule, trailing newline) → final `A''`; validate `D'` with
   `WonkyDeltaValidator`; reject if invalid (`code: invalidOp`).
6. Insert `DocumentOp(revision: head+1, delta: A'', inverse: A''.invert(head doc))`, update
   `document.headRevision` and stats (char/word counts every 50 ops). Commit.
7. Publish `RemoteOp` on `session.messages` channel `doc:<documentUuid>` (global scope when
   Redis enabled; posted with `immediate: true`, so other instances get it without waiting for
   the next bus batch, [13 §4](../13-security-and-operations.md)) and reply `Ack` to the author.
   Every instance's `DocumentSession` forwards to its connected clients except the author's
   session.
8. Side effects run after the per-document lock is released, one after the other per document
   (so the next op doesn't wait for them): the comment/suggestion thread lifecycle (Write 08
   §1.4, only for ops with overlay transitions) and, every 500 revisions, a `DocumentSnapshot`.
   The **bookkeeping** — activity log, version capture state, "last edited by me",
   `DriveItem.modifiedAt` (throttled 10 s), search text and size (30 s) — is only counted in
   memory per op (`PendingEdits`, `write/ot/edit_bookkeeping.dart`) and written in one batch for
   all editors 5 s after the first unflushed op, and whenever the document settles: a connection
   closes (it waits up to 10 s), a server-side caller (MCP, AI, restores) waits for its op, a
   version is captured (`VersionProvider.beforeCapture`), or the state is disposed. A deleted
   document's pending bookkeeping is dropped. A failure is logged and never breaks the
   connection: any unexpected error while handling a message is logged (a failed submit is
   answered with `OpRejected`) and the connection goes on.

`DocumentMetaChange` writes (§6) update only the changed column, never the whole row, so they
can't roll back a concurrently committed `headRevision`.

Ordering guarantee: Redis delivery is best-effort and unordered; each client tracks
`expectedRevision` and on receiving revision `r > expected` buffers it and sends `RequestOps`
for the gap (the server serves from DB). Duplicates (`r < expected`) are ignored.

Other instances: an instance whose `DocumentSession` only sees a commit as a bus message
catches up from the op log (coalesced); `RequestOps`, `CursorUpdate` and `HashCheck` first
catch up to the revision the client names. Rosters (`hello`/`here`/`left`) get a 30 s `beat`
with 90 s expiry, and the editor limit (§7) is re-checked 2 s after joining once the other
instances' replies arrived ([13 §4](../13-security-and-operations.md)).

## 3. Client algorithm (`DocumentSyncController`, `wonky_write/lib/features/sync/`)

States (ot.js): **Synchronized**, **AwaitingAck(inflight)**,
**AwaitingAckWithBuffer(inflight, buffer)**.

- **Local change** `L` (from `ChangeDeltaExtractor`):
  - Synchronized → send `SubmitOp(L, base = revision)`, state AwaitingAck(L).
  - AwaitingAck(I) → state AwaitingAckWithBuffer(I, L).
  - AwaitingAckWithBuffer(I, B) → B = B.compose(L).
  - Always persist to `LocalPendingOp` first (offline outbox).
- **Ack(r)**: revision = r; if buffer → send buffer as next op (base = r), state AwaitingAck(B);
  else Synchronized. Delete acked op from outbox.
- **RemoteOp(r, R)**:
  - Synchronized: apply R.
  - AwaitingAck(I): `I' = R.transform(I, true)`; `R' = I.transform(R, false)`; apply R'; state
    AwaitingAck(I'). (R was committed first, so it has priority — exactly what the server will
    compute for I.)
  - AwaitingAckWithBuffer(I, B): `I' = R.transform(I, true)`, `R1 = I.transform(R, false)`,
    `B' = R1.transform(B, true)`, `R2 = B.transform(R1, false)`; apply R2.
  - (`a.transform(b, p)` = b transformed against a; `p == true` ⇒ a's inserts win ties. A unit
    test pins this convention against `dart_quill_delta` 9.x.)
  - revision = r.
  - Transform local selection, remote cursors, undo/redo stack entries, find-highlights and
    pending AI preview ranges through the applied op (`transformPosition`).
- **Apply** = `DeltaApplier.apply(R)` → custom `EditCommand`s marked
  `HistoryBehavior.nonHistorical` that edit nodes directly (`replaceNodeById`, `insertNodeAt`,
  `deleteNode`), log the right `DocumentEdit` events, keep `DeltaIndex` in sync, and finally
  restore the transformed local selection with `ChangeSelectionRequest(…,
  SelectionReason.contentChange)`. If an IME composing region intersects the change, the
  composing region is cleared and the IME re-synced (`DocumentImeSerializer`).
  `ChangeDeltaExtractor` ignores changes made by `DeltaApplier` (flag on the transaction).

### 3.1 Reconnect / offline
Reconnects (backoff, connectivity, *Simulate offline*) are driven by `ConnectionKeeper`
(`wonky_app`, shared with the RevLog clients of Sheets and Slides). On (re)connect the client
sends `connect(knownRevision = revision)` and receives missed ops (transformed into its
inflight/buffer as above); then re-submits the outbox: the inflight op is resent with the same
`clientOpId` (idempotent), the buffer follows. Long offline periods compose the outbox into
≤ 1 op per 2 s of editing: the buffer is a list of chunks (one per 2 s window and per op
kind/group); remote ops are transformed through the chunks one after the other, and when
the in-flight op is acknowledged the leading chunks of the same kind are composed into the next
op.

The outbox is durable (suite 12 §1): the controller reports every server-document change and
outbox change to a `SyncPersistence` (`features/sync/sync_persistence.dart`, SQLite
implementation in `features/offline/`) and sends an op only after the write that contains it
completed. After a reload `DocumentSyncController.restore` loads the stored server document and
outbox (the document renders and is editable before connecting); a restored in-flight op is
treated as possibly sent, so its committed form is never predicted (it is taken from `Init` ops
or `getOps`). If the server is behind the stored revision (another history), the client resyncs
and offers the local state as a copy.

### 3.2 Integrity check
Every 200 revisions, once when a copy restored from the offline cache connects (it can have
drifted, e.g. after an op an older or newer server normalized differently than the client
predicted), and on demand in debug, client and server compare a SHA-256 of the
canonical document JSON at a given revision (`Hash` message variant). Mismatch → client discards
local document state (keeping the outbox as a recovery file), re-inits from a snapshot, and logs
an error with the op range for diagnosis.

### 3.3 Implementation notes (client)
- **Acks don't carry the committed op**, but the server may commit something other than
  what the client sent: it rebases the op *as sent* against the **composition** of the ops
  since its base (which can order tied inserts differently from transforming through them
  one by one) and then normalizes it. On `Ack(r)` the client therefore predicts the committed
  op exactly as the server computes it — `WonkyOt.rebaseOnServer(sent, ops sentBase+1…r-1)`
  then `WonkyDeltaNormalizer.normalizeChange`, computed with `normalizedChange` on the lines
  the op touches (same result for the normalized server document: normalization is per line
  given the list indent before; an op inserting an embed, or whose indent change cascades
  past its lines, is normalized against the whole document; CQ-49) — and, when it differs
  from its local in-flight
  op, applies the document difference as a *fix-up* (transformed against the buffer like a
  remote op). When prediction is impossible (the op introduces `sug_*` values, whose `at`
  is server time, or it was sent on more than one connection) the client fetches
  `getOps(r, r)` before continuing; ordered processing pauses meanwhile.
- Server messages are processed strictly by revision: remote ops **and acks** that arrive
  ahead of a gap wait; the gap is requested with `RequestOps` (re-requested after 3 s). A
  remote op whose `clientOpId` (Init ops, `getOps`) or `authorSessionId` matches the in-flight
  op is treated as its ack.
- The outbox is the in-flight op plus the buffer chunks (persisted, §3.1); reconnects resend
  the in-flight op (same `clientOpId`) unless it was already sent on that connection.
- Remote cursors arrive at a server revision: older ones are transformed through the
  remembered recent ops, newer ones wait; local cursors are expressed at the client's server
  revision by transforming through the inverse of the pending changes (built from their
  lengths only; positions don't depend on the deleted text, so the server document is not
  walked per cursor update).
- The client's server document is updated per remote op and ack with
  `WonkyOt.applyToCanonical`: only the ops around the change are composed and canonicalized,
  the rest are reused (same result as `WonkyOt.apply`; CQ-49).
- Undo stacks are rebased by `rebaseWriteStacks` (wonky_write `features/document/write_undo.dart`):
  the remote change is walked newest → oldest across *all* steps of the undo stack, and
  separately of the redo stack, before `UndoService.applyRemote` swaps in the results. An entry
  whose change is disjoint from the remote one (all of it before or after, no tie) is moved
  without transforms, and an entry that doesn't move stays the same object, so its step is
  not rebuilt (CQ-49).
- Write undo stacks are not persisted by the shell (entries are only valid against the live
  document). The session stores them best-effort with the offline copy (`LocalUndoStack`,
  suite 12 §1.1) together with the hash of the local document, and restores them only when the
  restored document has the same hash. They are stored when the app is hidden and when the
  document closes, not after every change (hashing a long document took tens of ms).

## 4. Undo/redo (Write-specific)

- super_editor history is **disabled** (`isHistoryEnabled: false`) because its undo resets to
  the initial snapshot and replays local commands, which is incompatible with remote edits. Its
  Cmd/Ctrl+Z actions are removed from `keyboardActions`; our commands handle the shortcuts.
- `WriteUndoHandler` (domain `write.content`) stores, per undo step, the **inverse delta**
  `L.invert(docBefore)` and selection before/after.
- On each applied remote op `R`: walk the undo stack from newest to oldest; for each entry `U`:
  `U' = R.transform(U, true)` and `R = U.transform(R, false)` (so `R` is expressed past `U` for
  the next older entry). Same for the redo stack. This is standard selective-undo rebasing;
  entries that become empty are dropped.
- Undo = submit `U` as a normal local op; push `invert(U)` on the redo stack.
- Grouping: consecutive typing within 1 s in the same node without caret jumps, consecutive
  deletions likewise; formatting and structural commands are always separate steps; paste,
  find-replace-all, AI edits, table edits are single steps.

## 5. Permission-restricted ops

| Role | Allowed op shapes |
|------|-------------------|
| Editor/Owner | Anything valid |
| Commenter | (a) `retain` ops whose attribute keys are **only** `cmt_*` (adding/removing comment anchors); (b) **suggestion ops**: inserts must carry exactly one `sug_<id>` attribute with `t:"ins"` and `by` = self; "deletions" must be retains adding `sug_<id>` with `t:"del"`; **formatting suggestions** are
retains that change inline/block attributes **and** add `sug_<id>` with `t:"fmt"`, `by` = self and
`before` = the exact previous attributes of each affected segment (server verifies `before`
against the pre-op document); retracting own suggestions (deleting text that carries own `sug_* t:"ins"`, removing own `sug_*` attributes) |
| Viewer | Nothing (stream is read-only; `CursorUpdate` allowed so presence works) |

Editors in **Suggesting mode** produce the same shapes as commenters (client-side mode; the
server doesn't care). Accepting/rejecting suggestions (Editor+) is a normal op: accept
insert = remove `sug_*` attr; accept delete = delete the text; reject insert = delete the text;
reject delete = remove the attr; `fmt` suggestions apply/restore `before` attrs.

## 6. Metadata (non-content) changes

Title (via `drive.rename`), theme, page setup, language and front matter are changed through
`updateMeta` (LWW). The server stores a `DocumentMetaChange`, broadcasts `MetaChanged`, and the
client undo handler (domain `write.meta`) stores before/after (see suite undo spec: entries are
dropped if the current value no longer equals `after`).

## 7. Performance budgets

| Metric | Budget |
|--------|--------|
| Keystroke → local render | < 16 ms (p95) on a 100-page document |
| Local op → remote render (same region) | < 250 ms p95 |
| Server op processing (transform + persist) | < 20 ms p95 with ≤ 50 concurrent editors per doc |
| Initial open (cached) | < 300 ms to first paint; (uncached, 100 pages) < 1.5 s |
| Max concurrent editors per document | 100 (beyond: new joiners become viewers with notice) |

## 8. Tests
- OT convergence fuzzer: N simulated clients with random ops (text, formats, block attrs,
  embeds, comments, suggestions), random network delays/reorders/disconnects, against an
  in-process server; assert all replicas converge and validate against the schema.
- Undo fuzzer (see suite spec §4).
- Mapper round-trip: random valid delta → MutableDocument → delta equality.
- Applier: random change deltas applied to the editor equal `compose` result; local selection
  preserved as `transformPosition` predicts.
