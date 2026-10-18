# RevLog spec 03 · Changes, change sets, apply rules and the wire codec

## 1. `RowChange` (moved, semantics unchanged)

`RowChange`, `RowOp`, `MutationPlan`, `composeRowChanges`, `UndoInverter`, `RowsUndoEntry`,
`RowsUndoHandler`, `CoupledColumns`, `ColumnwiseInserts` and `CurrentRowReader` move from
`packages/wonky_sync_kit/lib/src/{rows,undo}` to `packages/wonky_revlog/lib/src/{rows,undo}`.
Their public API stays as it is today (inventory: models §7). `RowPatch` becomes `Overlay` (§7).
`SyncTxAdapter` and `SyncTableSet` are deleted: they are replaced by `RevBinding` (05 §1) and
`RevSchema` (02 §4).

| Op | `before` | `after` | Meaning in RevLog |
|----|----------|---------|-------------------|
| `insert` | — | every column the creator sets, plus `id` | Create the row. If the id exists, the server writes the **non-null** columns of `after` into it (RD-2; see §4.2) |
| `update` | the touched columns' values *as the author saw them* | the touched columns' new values | Assign the named columns. `before` is used for conflict detection (§4.5) and undo |
| `delete` | the full row as the author saw it, plus `id` | — | Delete the row. Children cascade (RD-3); the plan lists the children it knows |

Invariants checked by `RowChange` and the codec:

- `rowId` is a canonical lower-case UUID string.
- `update.after` is non-empty, and its keys equal the keys of `before`.
- `id` never appears in `update.after`.
- Columns exist in `RevSchema`; values have the column's type (§3.2).

## 2. `ChangeSet`

```dart
/// One op: the unit of submission, sequencing and acknowledgement.
final class ChangeSet {
  ChangeSet({
    required this.clientOpId,        // UUIDv7, generated once, reused on every resend
    required this.baseRevision,      // the client's server revision when the op was cut
    required this.changes,           // ≤ RevLimits.maxChangesPerOp, ordered (§4.1)
    required this.label,             // undo label ("Paste", "Insert 3 rows"); "" for maintenance
    required this.actorKind,         // ActorKind name: user | mcp | ai | script | system
    this.summary,                    // ChangeSummary JSON (Sheets: sheets, ranges, kinds, deleted…)
    this.detail,                     // ≤ 200 cells before/after (cell history), as MutationPlan.detailJson
    this.groupId,                    // shared by the ops of one plan / one server operation
    this.groupIndex = 0,             // 0-based position in the group
    this.groupLast = true,           // false on all but the last op of a group
    this.offline = false,            // true if any change was made while disconnected (reported in conflicts and the review UI, 06 §6)
    this.createdAt,                  // client wall-clock UTC of the first change (display only)
  });
}
```

- **Summary and detail.** These are computed exactly as today:
  - `MutationPlan.summaryJson`/`detailJson` for plans;
  - `SheetsWriter.summarize` (moved to the Sheets binding) for plan-less writes: undo, redo, AI, maintenance.
- **Groups.** A plan of more than `maxChangesPerOp` changes is split by `MutationPlan.chunks` into one group. The summary goes on the first op of the group; the detail on the first op if it has ≤ 200 cells, otherwise none. The server stores `groupId`, and history shows a group as one entry.
- **Composing ops.** While an op is in flight, later local changes are composed into the buffered op (06 §4.2). Composing appends changes, runs `composeRowChanges`, and merges summaries (union of sheets, ranges, kinds and deleted ids). Details are concatenated and capped at 200 cells. The label becomes that of the latest step, or "Edits" if they differ. `offline` is OR-ed.

## 3. Wire codec (`RevCodec`, `packages/wonky_revlog/lib/src/codec/`)

### 3.1 Format

A change set is encoded as compact JSON. When the UTF-8 encoding is larger than
`compressAboveBytes` (16 KiB), it is sent gzip-compressed as bytes (04 §2).

```jsonc
{
  "v": 1,                                    // codec version
  "s": "<revSchemaHash>",                    // 02 §4.3; the server rejects a mismatch (schemaMismatch)
  "t": ["cell", "sheet_row"],                // table dictionary for this op
  "c": [["content", "bold"], ["sortKey"]],   // column dictionary per table (same order as "t")
  "ch": [
    // [op, tableIdx, rowId(base62, 22 chars), after?, before?]
    // op: 0 = insert, 1 = update, 2 = delete
    // after/before: arrays aligned with the table's column dictionary; a column that is not
    // part of the change is encoded as the sentinel {"_":0} ("absent")
    [1, 0, "4fG…", ["n:42", {"_":0}], ["s:old", {"_":0}]],
    [0, 1, "7Hb…", ["a0V"]],
    [2, 0, "9zA…", null, ["n:1", true]]
  ]
}
```

- Row ids travel in the 22-character base-62 form (`Base62Uuid`), the same form as formula reference tokens. They are decoded to canonical UUID strings before use.
- `insert` carries `after` only; `update` carries both arrays (the touched columns are those not equal to the "absent" sentinel); `delete` carries `before` only.
- The metadata of §2 (`clientOpId`, `baseRevision`, `label`, …) travels in the message, not in the codec JSON (04 §2).

### 3.2 Value encoding

Values are encoded per `RevColumnType` (02 §4):

| Type | JSON | Notes |
|------|------|-------|
| `uuid` | base-62 string (22) | FK and plain-reference columns |
| `string` | string | |
| `int` | number (integer) | |
| `double` | number | Dart shortest round-trip; `NaN`/`±Inf` are rejected |
| `bool` | `true`/`false` | |
| `dateTime` | integer (UTC milliseconds since epoch) | |
| `enumName` | string (enum value name) | Unknown names are rejected by the server (`invalidChange`); a client decoding a compatible newer schema keeps the name as-is (02 §4.3) |
| `json` | string (opaque JSON text, as stored) | Validated as JSON by the server; size limit per column |
| null | `null` | Allowed only for nullable columns |

**Round-trip property:** `decode(encode(cs)) == cs` for every valid change set (property test,
09 §2.1). The client and server codecs are the same Dart code.

## 4. Apply rules (pure functions, `packages/wonky_revlog/lib/src/apply/`)

The rules are written once as pure Dart against an abstract row store. The sequencer runs this
very function on prefetched rows (05 §3.2), and clients use it for the overlay (§7) and in tests.
The SQL write step only persists its result, so the server's result equals the pure function's
by construction; 09 §2.2 checks that the persistence is faithful.

```dart
abstract interface class RevRowStore {
  Map<String, Object?>? row(String table, String id);           // null = missing
  void put(String table, String id, Map<String, Object?> row);  // full row
  void remove(String table, String id);                          // no cascade
  Iterable<(String table, String id)> childrenOf(String table, String id); // via RevSchema parents
}

final class ApplyResult {
  final List<RowChange> applied;          // the APPLIED form (§4.7), incl. cascades
  final List<DroppedChange> dropped;      // target or a parent missing
  final List<FieldConflict> candidates;   // fields whose value at apply time ≠ before (§4.5)
  final List<RowChange> cascaded;         // children removed by cascade that the op didn't list
  bool get equalsSubmitted;               // applied == submitted changes (no drops, merges or cascades)
}

ApplyResult applyChangeSet(RevSchema schema, RevRowStore store, ChangeSet cs);
```

### 4.1 Order

Changes are applied in the order of the op. Planners already emit parents first for inserts and
updates and children first for deletes (`PlanBuilder.build`: stable sort by `RevSchema.rank`). The
client chunker and the composer keep that order. Rank can't order rows of one self-referencing
table (Slides `slide_element.parentId`: a group created in the same op as its children may come
after them), so `RevChunker.split` first runs `parentsFirst(schema, changes)`
(`wonky_revlog/lib/src/apply/order.dart`): an insert created in the op moves to just before the
first insert or update that references it, every other change keeps its place. The server does not
reorder; an out-of-order child insert is simply dropped (§4.2), and that is a client bug caught by
tests.

### 4.2 Insert

1. **Parents.** Every non-null FK column of the row must reference an existing row (also
   one inserted earlier in the same op). Otherwise the change is **dropped**
   (`DroppedChange(reason: parentMissing)`).
2. **Absent row.** Store the row: `after` plus `RevSchema` defaults for missing columns.
3. **Existing row** (a deterministic id created by someone else, or a replay): write each
   column of `after` whose value is **non-null** (an insert that leaves a column null does not
   author it, OS-4 semantics). Columns whose current value is non-null and
   differs from `after` are conflict candidates (§4.5).

### 4.3 Update

1. **Missing row** → dropped (`rowMissing`). This is "delete wins".
2. **Immutable columns** (`RevColumn.immutable`) can't be updated; validation rejects such an op (§5).
   - These are `cell.sheetId`, `cell.rowId` and `cell.columnId`: a cell's id is derived from them, so cells never move; moving content writes other cells.
   - The same applies to the key columns of other deterministic-id tables: `slide_table_cell` element, row and column; `chart_link.elementId`.
3. **Parent change.** If a mutable FK column is updated, the new parent must exist, otherwise the whole change is dropped (`parentMissing`). Examples are an element re-parented into another group, or a slide moved between groups (`groupId` is a plain reference, not an FK).
4. **Columns.** Write every column. A column whose current value differs from `before` is a conflict candidate (§4.5).

### 4.4 Delete

1. **Missing row** → nothing (idempotent; not reported).
2. **Present row** → remove it and every descendant through `RevSchema` parents (cascade). The
   descendants that the op did not delete explicitly are returned as `cascaded` (they
   were created concurrently by someone else; 07 §5 shows them in the conflict review as
   "removed with row 7").

Plain references (`Slide.layoutId`, `DimensionGroup.startId`, pivot anchors, formula tokens,
GridRange JSON) are **not** cascaded. They resolve at evaluation time exactly as today
(Sheets 02 §2, Slides 02 §3), and the client repairs of §6 fix what must be fixed.

### 4.5 Conflict candidates and attribution

A **candidate** is a field `(table, rowId, column)` where the op's `before` value differs from
the value at apply time. Value equality follows `RowPatch.sameColumns`: numbers by value,
date-times to the millisecond, enums by name, JSON strings byte-wise. The pure function reports
every candidate; it knows nothing about authors.

**Attribution** is a server post-step after the apply, still inside the transaction (05 §3.2
step 3.7). For each candidate, find the op that last wrote that field:

1. Start at the row's `revision` column.
2. Walk back through `rev_op` payloads (applied changes) until one wrote the column. The walk
   is bounded to 50 ops per field and 500 fields per op; beyond that the author is unknown.
3. A field is a **conflict** only if its last writer is **another user** (by `authorUuid`).
   The user's own other sessions and devices don't count, and neither do the user's own server
   changes on their behalf.

The Ack reports conflicts with `theirs` (the value before our write), `byUser` and `byRev`
(04 §2.2). The fields were overwritten: the last arrival wins (Q1, decided).

### 4.6 Determinism

Given the same state and the same op, `applyChangeSet` produces the same applied form on the
server and on every client. Clients nevertheless never re-derive the server state with it: they
receive the applied form (§4.7, RD-20).

### 4.7 The applied form (RD-20)

The applied form is the list of changes that turns the state at revision *r−1* into the state at
*r*, written so that it can be replayed literally, with no rules:

| Submitted | In the applied form |
|-----------|---------------------|
| Insert of an absent row | `insert` with the full stored row (defaults filled) |
| Insert merged into an existing row (§4.2.3) | `update` of the columns it actually wrote, with their `before`. So undo, revert and replay never treat it as a whole-row insert or delete, and other users' columns survive |
| Update | `update` of the columns actually written |
| Delete | `delete` with the full row as stored (`before`) |
| Dropped change | absent |
| Cascaded descendants | `delete`s (full rows) after their parent's delete |
| Fix-ups (none in this migration) | appended |

Clients receive the applied form **without `before` values** (04 §2.2), since they never need
them. `rev_op.payload` keeps the `before` values for revert and attribution.

## 5. Validation (server, before applying)

Run against the decoded op. Any failure rejects the whole op with `RevRejected(invalidChange)`,
and the message names the first offending change.

1. `changes.length ≤ maxChangesPerOp`; payload size ≤ `maxOpBytes`.
2. Every table is in the binding's `RevSchema`. Clients may not write tables with
   `RevTable.clientWritable == false` (Sheets `script_build`; Slides none).
3. Every column exists, is writable by clients (`RevColumn.clientWritable`), and has the right
   type and nullability (§3.2). Strings are within `maxLength`. JSON columns parse.
   `immutable` columns appear only in inserts.
3a. **Ids belong to this file.** Every id the op touches that exists on the server must belong
   to this file. The sequencer prefetches by id without a file filter and rejects foreign ids
   with `invalidChange` (05 §3.2). Ids are global UUIDs, so this check is what keeps one file's
   op from writing another file's rows.
4. `insert` of a root-table row is only allowed in the file's creation op (revision 1) and only
   with `id == fileUuid`. A root row can't be deleted through an op (deleting a file is a drive
   operation).
5. `actorKind` is `user` for client submits. `mcp`, `ai`, `script` and `system` are only
   accepted from server-side callers (`submitServerChange`, 05 §8), with one exception: client
   scripts run in the browser submit with `actorKind: script` (Sheets 09 client runtime).
6. Binding checks (`RevBinding.authorize`, 05 §1):
   - Sheets: the cell cap (`contentCount`) and `maxSheetsPerSpreadsheet`.
   - Roles for special tables: `script_trigger` and `script_file` need Editor; triggers keep `runAsUserId == author`, as the server checks today in `ScriptService`.
   - Slides: exactly one owner FK set on `slide_element`.
7. **Protected ranges** (Sheets; RD-19, 05 §3.5): the op must not write protected cells, rows,
   columns, rules, filters, objects or sheets that the author may not edit. Otherwise it is
   rejected whole with `protectedRange`. This runs inside the sequencer, after the in-memory
   apply (it checks the applied form against the model at the previous revision).

## 6. Normalization and repairs

**Server hook (empty in this migration).** `RevBinding.normalize(ctx, applied)` may return extra
changes (fix-ups). They are applied in the same transaction and appended to the op's applied
form (§4.7), so the Ack carries them to the author (06 §4.4). The protocol and the client support fix-ups from day one so that a later binding can
use them without a protocol change. No binding returns any in this migration (RD-14).

**Client repairs (as today, run by an editor's client after remote batches, debounced 1 s, only when no remote group is half-applied and the tab's outbox is empty (06 §1.2), not
undoable, label "Repair", `actorKind: user` (clients may not send `system`, §5 rule 5), summary flag `"repair": true`. A repair op rejected with `protectedRange` is not retried for that violation for 24 h; another user who may edit the protection repairs it when they open the file):**

| App | Repairs | Status today |
|-----|---------|--------------|
| Sheets | `AnchorMaintenance` (object anchors) | Wired in `ObjectsController` (`objects_controller.dart:341-378`) |
| Sheets | `WorkbookMaintenance.plan` (core `mutations/maintenance.dart:15`): duplicate sheet names → " (2)" on the larger id; duplicate named ranges → "_2"; frozen counts clamped; overlapping merges → keep the smaller id; unresolvable merges deleted; basic filters whose range no longer resolves deleted; pivot anchors on deleted rows/columns moved to the nearest survivor; group depths normalized | **Not wired anywhere today.** R5 wires it next to `AnchorMaintenance` (one repair op per debounce) |
| Slides | The 12 `DeckMaintenance` rules (Slides 02 §10; spec file 08 §4) | Wired in `SyncedDeckSession.runMaintenance`; moves to `LoggedDeckSession` unchanged |

Repairs are deterministic and idempotent. Two editors repairing at the same time produce the
same changes, so the second op's changes are no-ops or identical values.

## 7. Overlay (client, replaces `RowPatch`)

The client model is defined as **`model = applyAll(outbox ops, in order, rules of §4) over server
state`**. The outbox is applied with the same `applyChangeSet` rules, not
by blindly re-writing after-values. That means:

- an outbox insert of a deterministic id merges only its non-null columns over a remote insert of the same id, so another user's `bold` stays visible;
- an outbox change whose row or parent was deleted remotely is dropped from the view.

When a remote op (applied form) arrives:

```
touched = rows the remote op changes, plus the rows the outbox changes for those ids
before  = model rows for `touched`                                 // = old server ⊕ outbox
server' = server rows for `touched` with the remote applied form replayed literally
after   = applyAll(outbox ops restricted to `touched`, over server')   // pure, §4 rules
patch   = diff(before, after)   // RowChanges; RowPatch.sameColumns → no flicker, no echo
model.applyChanges(patch)       // emitted as one remote batch
```

`Overlay.build(model, serverRows, remoteApplied, outbox, {schema})` implements this. Outbox
changes for rows outside `touched` are unaffected, so restricting the replay is exact.

**Property test** (09 §2.6, replaces `remote_patch_property_test.dart`): for random server
states, outboxes and remote ops, `model.applyChanges(Overlay.build(...))` equals a full rebuild
`applyAll(outbox, newServerState)`.
