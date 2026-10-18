# Write 08 · Comments, Suggestions, Version History and Presence

This spec defines the **Write-specific** parts of collaboration on top of the shared framework in
[../07-collaboration.md](../07-collaboration.md): how comments anchor into the
Delta, the margin layout, **Suggesting mode** (tracked changes), Write version history (diffs,
attribution, restore) and Write presence rendering.

Authoritative references: Delta overlay attributes `cmt_*`/`sug_*`
([02-document-model.md](02-document-model.md) §1.1), OT, permission-restricted op shapes and
accept/reject semantics ([03-sync-protocol.md](03-sync-protocol.md) §5), undo
([../08-commands-and-undo.md](../08-commands-and-undo.md)), MCP
([../09-mcp.md](../09-mcp.md), [09-mcp-and-ai.md](09-mcp-and-ai.md)), editor
and layers ([04-editor.md](04-editor.md)), menus ([05-screens-menus-toolbar.md](05-screens-menus-toolbar.md)),
theme overlay colors ([06-themes.md](06-themes.md) §2.6, §6.2).

Package ownership:

| Piece | Location |
|-------|----------|
| Overlay range index, suggestion rewriter, accept/reject op builders, suggestion views, attributed diff | `wonky_write_core/lib/collab/` (pure Dart, shared by client, server, MCP) |
| Server overlay tracking, suggestion threads, decisions, restore, diff endpoint | `wonky_server/lib/src/write/collab/`, `…/write/versions/` |
| Margin, cards, highlights, suggesting-mode reaction, history route, presence layers | `wonky_write/lib/features/{comments,suggestions,history,presence}/` |
| Shared comment widgets (`CommentThreadBody`, `CommentsFilterTabs`, `CommentsController`, `CommentsHost`) | `wonky_app` (suite) |

---

## 1. Comment anchors

### 1.1 Representation

- An anchored comment thread is a `CommentThread` (suite model, `anchorKind: textRange`) **plus**
  the inline attribute `cmt_<threadUuid>: true` on every character it covers. The Delta is the
  source of truth for *where* a comment is; the server model is the source of truth for *what*
  it says. `anchorJson` for Write threads is `{"v":1}` (no positions — they'd go stale), or
  `{"v":1,"suggestionId":"<id>"}` for suggestion threads (§2.7). `quotedText` stores the text
  at creation (≤ 500 chars).
- Anchors may cover any text, including across paragraphs (the attribute is set on the text of
  each line; line-ending `"\n"`s inside the range also carry it so a range spanning blocks stays
  one contiguous run), and embeds (the embed insert carries the attribute).
- Overlapping comments compose naturally: each thread has its own key.
- Copy/cut to the clipboard strips `cmt_*` (pasting never duplicates anchors). *Make a copy* with
  *Copy comments* rewrites keys to the new thread UUIDs server-side; without it, `cmt_*` are
  stripped.
- `document` threads (`anchorKind: document`, "comment on the whole document") have no anchor
  attribute; their composer and their cards sit at the top of the margin (Write has no
  comments panel; the margin lists unresolved document and orphaned threads at the top, before
  the anchored ones).

### 1.2 Creating a comment

Trigger: `shell.comments.create` (suite command, Write implementation; `Mod+Alt+M`, toolbar 💬,
context menu, selection bubble — see [04-editor.md](04-editor.md) §33). Role: Commenter+.

1. Requires a non-collapsed selection; with a collapsed caret, the **word** at the caret is used
   (or the whole block if the block is empty → disabled).
2. Client generates `threadUuid` (UUIDv7) and opens the **composer card** in the margin at the
   selection; the range is highlighted as *pending* (dashed underline). The anchor is tracked as a
   local, non-synced range (transformed through remote ops) — **no op leaves the outbox and no
   undo step exists until the comment is saved**, so cancelling leaves no trace.
3. On *Comment*: in one undo transaction (label "Comment"):
   - `CommentEndpoint.createThread(itemUuid, anchorKind: textRange, anchor: {"v":1}, body,
     mentions, assigneeId?, threadUuid)` — the suite endpoint takes the client-generated
     `threadUuid` (idempotent on it) — queued in the shell's pending queue when offline;
   - a local op: retain over the (current, transformed) range with `cmt_<threadUuid>: true`
     (allowed for commenters, [03](03-sync-protocol.md) §5).
   The op travels through the normal outbox; order between the two doesn't matter: clients that
   receive an anchor for an unknown thread render the highlight and show a skeleton card until
   `CommentEndpoint.watch` delivers the thread (5 s timeout → card shows "Comment unavailable").
4. *Cancel* / Esc discards; no op is sent.

If the range was concurrently deleted while composing, the composer stays open with "The text you
selected was deleted" and *Comment on document instead* / *Discard*.

### 1.3 Anchor lifecycle

- **Edits inside** the anchor: typed characters inherit `cmt_*` when typed strictly inside the
  range (super_editor attribution expansion rules: our `CommentAttribution` is **not** extended
  when typing at the range's start or end boundary, so comments don't grow when you type after
  them). Splitting/merging paragraphs keeps attributes.
- **Deleting all anchored text** orphans the thread (§1.4). Partially deleting just shrinks it.
- **Undo** of a deletion re-inserts the text **with** its `cmt_*` attributes (the inverse delta
  contains them) → the anchor comes back (§1.4 un-orphaning).
- Copying a range into another document drops anchors (above).

### 1.4 Server-side overlay tracking (`OverlayIndex`)

Each `DocumentSession` keeps an `OverlayIndex` (pure Dart, core) mapping every `cmt_*` and
`sug_*` key → number of characters carrying it. Built from the head document when the session is
created (O(n)); updated per applied op from `(op, inverse)` only:

- op `insert` with key K → `+len`;
- op `delete` → the inverse's inserts carry the deleted attributes → `−len` per key;
- op `retain` with `K: value` where inverse has `K: null` → `+len`; op `K: null` where inverse has
  `K: value` → `−len`.

Transitions are processed after commit:

| Transition | Comment thread (`cmt_`) | Suggestion (`sug_`) |
|------------|-------------------------|---------------------|
| 0 → >0 (first appearance) | if status `orphaned` → `open` (+ system event `reopened`) | create the suggestion thread if missing (§2.7); if it was resolved by a decision → reopen with system event `suggestionReopened` |
| >0 → 0 | if `open` → `orphaned` (system comment "Original content deleted"); resolved threads stay resolved | decision inference (§2.9) → resolve thread with `suggestionAccepted` / `suggestionRejected` / `suggestionWithdrawn` / `suggestionSuperseded` |

Status changes are broadcast through `CommentEndpoint.watch` (`CommentEvent.statusChanged`).
Orphaned threads carry the quoted text and the label **"Original content deleted"**; they can be
resolved, deleted or re-anchored by an Editor (`write.comments.reattach`, *Re-attach to
selection*, sets `cmt_*` on the new selection → back to `open`). They have no anchor, so the
margin lists them at its top (§1.1) with the other open threads.

### 1.5 Resolve, reopen, delete

- **Resolve** (Commenter+): thread status `resolved`; the `cmt_*` attribute **stays** in the
  Delta (so *Reopen* restores the highlight) but is rendered without highlight. Undoable (suite
  `comments` domain).
- **Delete thread** (author of the root comment, or Editor+): `CommentEndpoint.deleteThread` +
  an op removing `cmt_<id>` everywhere (one undo step; undo restores both).
- Resolved threads older than 30 days still keep their attributes; `WonkyDeltaNormalizer`
  removes `cmt_*` keys whose thread no longer exists (server job weekly, as a `system` op).

---

## 2. Suggesting mode (tracked changes)

### 2.1 Modes

| Mode | Who | Behavior |
|------|-----|----------|
| **Editing** | Editor, Owner | Direct edits |
| **Suggesting** | Editor, Owner (opt-in); **Commenter (always)** | Every content change becomes a suggestion |
| **Viewing** | everyone | Read-only (`SuperReader`); suggestions rendered in the *original* view by default, toggleable ([04-editor.md](04-editor.md) §31) |

- Mode switch: `write.mode.set {mode}` (defined in [04-editor.md](04-editor.md) §31): View › Mode ▸,
  the mode switcher ([05](05-screens-menus-toolbar.md)), shortcuts `Mod+Alt+Shift+Z` (Editing),
  `Mod+Alt+Shift+X` (Suggesting), `Mod+Alt+Shift+C` (Viewing). The mode is per user per document, stored locally
  (last used), not synced. Commenters see Editing disabled with tooltip.
- The toolbar's mode switcher shows "Suggesting" (with the canvas cue, 05 §15) and the caret
  flag shows it in the user's presence color; the presence roster state includes the mode.

### 2.2 Representation (recap + clarifications of [02](02-document-model.md) §1.1)

`sug_<suggestionId>: {"t": "ins"|"del"|"fmt", "by": "<userUuid>", "at": <epochMs>, "before"?: {…}, "via"?: "ai"|"mcp"}`

- `ins`: the characters were inserted as a suggestion.
- `del`: the characters are proposed for deletion (still present in the Delta, rendered struck).
- `fmt` on text: inline attributes were changed; `before` = the **original** inline attributes
  (subset of `bold, italic, strike, code, link, mention`; absent key = not set).
- `fmt` on a line's `"\n"`: block attributes were changed; `before` = original block attributes
  (`header, blockquote, code-block, list, indent`; `{}` = plain paragraph). Example: paragraph →
  H2 suggestion: `{"insert":"\n","attributes":{"header":2,"sug_7f…":{"t":"fmt","by":"…","at":…,"before":{}}}}`.
- `ins` / `del` on a line's `"\n"`: a suggested paragraph split (Enter) / join (Backspace at line
  start). `ins`/`del` on an **embed** insert and its trailing `"\n"`: suggested image/table/rule
  insertion/removal. (Clarification for 02 §1.4 rule 2: *block* attributes are forbidden on an
  embed's `"\n"`; overlay attributes `cmt_*`/`sug_*` are allowed.)
- **One suggestion id can span several parts**: a *replacement* (select text + type) is one id
  with a `del` part and an `ins` part; a multi-paragraph insertion is one id. Parts with the same
  id are always by the same author.
- `via` (optional): set when the change was produced by AI or MCP on the user's behalf
  (rendered as a ✨ badge on the card). *Requires adding the optional key to the 02 schema and
  validator.*

### 2.3 Generation: `SuggestionRewriter` (core)

The editor is not special-cased per edit type. In Suggesting mode, a super_editor `EditReaction`
(`SuggestingModeReaction`, registered first) runs inside the same transaction after each local
change: it obtains the change delta `C` from `ChangeDeltaExtractor` ([02](02-document-model.md)
§4.4), calls `SuggestionRewriter.rewrite(docBefore, C, ctx)` → `S`, and, if `S ≠ C`, executes
corrective `EditCommand`s so the document equals `docBefore.compose(S)` before layout/paint (no
flicker). The outgoing op is `S`. Selection is adjusted (§2.4).

```dart
final class SuggestionContext {
  final String userUuid;
  final int nowMs;
  final SuggestionSession session;     // current suggestion id + adjacency info
  final String? via;                   // "ai" | "mcp" | null
}
abstract interface class SuggestionRewriter {
  Delta rewrite(Delta docBefore, Delta change, SuggestionContext ctx);
}
```

Rules (applied per op component of `C`, against the attributes of `docBefore` at that position):

| Change component | Target text state | Rewritten as |
|------------------|-------------------|--------------|
| `insert` text/embed | — | same insert + `sug_<id>{t:ins}` (strip any foreign `sug_*` it may carry) |
| `delete` span | own `sug_*{t:ins}` chars | **real delete** (retracting your own suggestion) |
| | chars with any `sug_*{t:del}` | no-op (already proposed for deletion); caret just moves |
| | other chars (incl. others' `ins`) | `retain` + `sug_<id>{t:del}` |
| `retain` with inline attr changes | own `ins` chars | applied directly (no `fmt`) |
| | chars with own `fmt` suggestion | apply attrs; keep the existing `before`; if new attrs == `before` → remove the `fmt` key (net no change) |
| | other chars | apply attrs + `sug_<id>{t:fmt, before: original inline attrs}`; spans with different original attrs are split so each part has a correct `before` |
| `retain` on `"\n"` with block attr changes | analogous with block attrs | `fmt` with block `before` |
| `insert "\n"` (Enter) | — | `"\n"` + block attrs + `sug{t:ins}` |
| `delete "\n"` (join) | own `ins` `"\n"` | real delete |
| | other | `retain` + `sug{t:del}` on that `"\n"` (blocks stay separate until accepted) |
| Image/divider insert or delete | — | `ins` / `del` on the embed insert and its `"\n"` |
| Table edits, table insert, block moves | — | **Not suggestable in v1** (commands disabled in Suggesting mode, [04](04-editor.md) §32.1). P2 design: `del` on the old table embed + `ins` on a replacement embed with a **new embed id**, same suggestion id |
| `cmt_*` attribute changes | — | passed through unchanged (commenting is not a suggestion) |

Constraints are kept valid: e.g. a suggested `code` format still excludes `bold/italic/strike`
(the rewriter records all removed attrs in `before`).

**As built (CQ-50):** one implementation, `SuggestionRewriter` in `wonky_write_core`
(`collab/suggestion_rewriter.dart`), used by the editor (on a window around the change,
Write 04 §32.1), the AI assistant and the server's MCP headless editor, so all three produce the
same suggestions. Beyond the table: `insert, delete` runs are reordered to `delete, insert`
(the `ins` part of a replacement follows the struck text, §2.4); the user's own typing inside,
right after or right before their own typed insertion **extends** it (same key and mark), while
agent edits (`via`) always get a mark of their own (attribution and the returned suggestion id
stay right); the inserts of one change share one mark; an attribute change with no effect on a piece adds no
`fmt`, and attributes invalid for a piece (block keys on text, inline keys on `"\n"`) are
dropped. The editor's former copy is kept only as the oracle of
`test/collab/suggestion_rewriter_differential_test.dart`.

### 2.4 Suggestion identity and caret behavior

- `SuggestionSession` reuses the current suggestion id for consecutive insertions/deletions by
  the same user **in the same block within 30 s without a caret jump** (insertion touches a span of
  the current id, or deletion is contiguous with it); otherwise a new UUIDv7 is minted (grouping
  rule shared with [04](04-editor.md) §32.1). Typing over a selection =
  one replacement id. Formatting commands always mint a new id (separate cards), except when
  re-formatting the same range within 5 s.
- Backspace over others' text in Suggesting mode marks it `del` and moves the caret **before**
  the struck text; Delete moves it after. Selecting struck text and typing creates a replacement
  whose `ins` part is placed after the struck span.
- Undo (`Mod+Z`) in Suggesting mode reverts the rewritten op `S` (normal `write.content` undo),
  so undoing a suggested deletion simply removes the `del` attribute.

### 2.5 Rendering

| Kind | Rendering (inline styler / layers, [06](06-themes.md) §6.2) |
|------|----------------------------------------------------------------|
| `ins` | text in the `suggestionInsert` color (green), no underline; background `suggestionInsert` at 12 % |
| `del` | text and strikethrough in the `suggestionDelete` color (red); background `suggestionDelete` at 8 % |
| `fmt` (inline) | the new formatting + dotted underline in the author's color |
| `fmt` (block) | the new block style + 2 px vertical bar in the author's color in the left margin |
| `ins`/`del` on `"\n"` | small ¶ glyph at the line end (struck for `del`) drawn by a layer |
| Embed `ins`/`del` | 2 px outline in the author's color; `del` embeds dimmed with a diagonal hatch |

Presence color (format suggestions) = `presence[colorIndex(userUuid)]` from the design system,
consistent with avatars and cursors. Insertions and deletions use fixed green/red so the
proposed edit reads at a glance; the author is on the margin card.

### 2.6 Display toggles (View › Preview suggestions ▸, `write.view.suggestionPreview {mode}` from [04](04-editor.md) §31)

| Option | Effect |
|--------|--------|
| **Show suggestions** (default in Editing/Suggesting) | Rendering above; editable |
| **Preview accepted** | Render `SuggestionView.accepted(delta)` (drop `del` text, plain `ins`, keep new formatting) in a `SuperReader` — read-only; banner "Previewing with all suggestions accepted — *Back to editing*" |
| **Preview original** (default in Viewing) | Render `SuggestionView.original(delta)` (drop `ins`, plain `del`, restore `before`) read-only |

`SuggestionView` (core) is shared with exporters ([07](07-import-export-print.md) §2.1) and MCP
(`write.get_document {suggestions}`).

### 2.7 Suggestion cards and threads

- Each suggestion id has a **suggestion thread**: `CommentThread(anchorKind: textRange,
  anchorJson: {"v":1,"suggestionId":id})`, uuid = UUIDv5(documentUuid, "sug:" + id) so every
  client can address it without lookup. The **server** creates it when `OverlayIndex` first sees
  the id (§1.4), with `createdById` = the `by` user and no comments (system thread).
- **Card** (margin, same layout as comment cards): author avatar/name, relative time, ✨ badge
  if `via`, a summary — "Add: ‘quarterly’", "Delete: ‘the old plan’", "Replace: ‘red’ with
  ‘blue’", "Format: Bold", "Change paragraph to Heading 2", "Add image", "Insert paragraph break"
  (long texts truncated to 120 chars) — buttons **✓ Accept** / **✗ Reject** (Editor+; the author
  sees **✗ Withdraw**), ⋮ (Link to suggestion), then the suggestion thread's **replies** and a
  reply box (the shared `CommentThreadBody`): replies are normal comments in the suggestion
  thread (mentions/notifications work as usual).
- Clicking a card selects/highlights all parts of the suggestion; clicking suggested text
  activates its card.
- Suggestion cards live only in the margin (there is no Suggestions panel or toolbar toggle);
  the margin shows them with the open threads (§3.2). *Accept all* / *Reject all*
  (`write.suggestions.acceptAll` / `rejectAll`, confirm when > 10) are commands (palette, MCP).

### 2.8 Accept / reject operations (`SuggestionOps`, core)

Built from the **current** document state for the chosen ids, one op per user action (one undo
step "Accept suggestion" / "Accept 12 suggestions"):

| Part | Accept | Reject / Withdraw |
|------|--------|-------------------|
| `ins` | retain with `sug_<id>: null` | delete the chars |
| `del` | delete the chars | retain with `sug_<id>: null` |
| `fmt` inline | retain with `sug_<id>: null` | retain resetting attrs to `before` (absent keys → `null`) + `sug_<id>: null` |
| `fmt` block | retain `"\n"` with `sug_<id>: null` | retain `"\n"` restoring block attrs from `before` + `sug_<id>: null` |

- Accept/Reject requires Editor+ (and Editing or Suggesting mode — accepting is never itself a
  suggestion). Withdraw is allowed for the author (any role ≥ Commenter); it's a shape commenters
  may submit ([03](03-sync-protocol.md) §5).
- *Accept all* / *Reject all* compose all parts of all pending ids (optionally filtered by author:
  P2) into one op.
- Ops are computed at the client's current revision and go through OT like any edit; characters a
  collaborator adds to the same suggestion concurrently keep the attribute and remain pending
  ("1 more change" on the card).

### 2.9 Decision inference (server)

When `OverlayIndex` reports `sug_X` >0 → 0 for an op by actor A, the server classifies the op's
effect on X's former spans (from the inverse): for the `ins` part (or the only part):

- chars kept, attribute removed → **accepted**;
- chars deleted → **withdrawn** if A == author, else **rejected**;
- for `del` parts: chars deleted → accepted, attribute removed → rejected/withdrawn;
- for `fmt`: attributes after == `before` → rejected/withdrawn, else accepted;
- if the op also deleted characters **outside** X's spans in the same contiguous region (e.g. a
  whole paragraph deleted in Editing mode) → **superseded**.

The suggestion thread is resolved with the matching `CommentSystemEvent`
(`suggestionAccepted`, `suggestionRejected`, `suggestionWithdrawn`, `suggestionSuperseded` —
extend the suite enum, which currently lists `suggestionAccepted…`) and the author is notified
(except when A is the author). Undoing an accept re-adds the attribute → 0 → >0 →
`suggestionReopened`.

### 2.10 Server validation of suggestion ops (extends [03](03-sync-protocol.md) §5)

For Commenters (and for any op flagged `mode: suggesting` by a client — informational only), the
transformed op must consist only of:
(a) `cmt_*`-only retains; (b) inserts carrying exactly one `sug_<id>{t:ins, by: self}` (and no
other foreign `sug_*`); (c) retains adding `sug_<id>{t:del, by: self}` with no other attribute
change; (d) **format suggestions**: retains that change inline/block attributes **and** set
`sug_<id>{t:fmt, by: self, before}` where `before` equals the span's pre-op attributes (or the
existing own `fmt` suggestion's `before`) — verified against the head document; (e) retractions:
deleting chars carrying own `t:ins`, removing own `sug_*`, and restoring `before` while removing
own `fmt`. Anything else → `OpRejected(code: forbiddenForRole)`.
`by` must equal the authenticated user; `at` is overwritten with server time on apply (the
normalizer rewrites it so clients can't backdate).

### 2.11 Notifications

- The document **owner** (and Editors who opted in via notification settings) get one
  `Notification(kind: suggestion)` per author per document per 10 minutes ("Bo suggested 4
  edits in *Q3 planning*"), linking to `/d/<uuid>?comment=<suggestionThreadUuid>`.
- The suggestion author is notified on accept/reject (not withdraw/supersede).
- Replies and mentions in suggestion threads notify like normal comments.

---

## 3. Margin and highlights

### 3.1 Highlight colors

| State | Color |
|-------|-------|
| Open comment | `commentHighlight` (theme overlay override possible); +15 % alpha per additional overlapping open thread, capped at 2 overlaps |
| Active comment | `commentHighlightActive` + 1 px underline, painted by `HighlightLayer` (repaint only) |
| Resolved / orphaned | no highlight |
| Hover over a card | its anchor gets the active color temporarily |
| Composer pending range | dashed underline in `primary` |

List markers (bullets, numerals) never take the first character's comment highlight or
suggestion background/strikethrough (vendored super_editor patch SE-7, [04](04-editor.md) §2.2).

### 3.2 Margin layout (`CommentMarginLayout`, pure function, unit-tested)

Inputs: visible items (open comment threads + pending suggestions + composer) with `anchorTop`
(y of the first line box of the item's first range, in scroll-content coordinates, from
`DocumentLayout.getRectForPosition`), `anchorOffset` (Delta offset, tie-breaker), `height`
(measured card height; collapsed cards show ≤ 3 lines of the root + "N replies"; estimate 76 px
until measured), the active item (or none), `gap = 8`, `minY = 0`.

```
sort items by (anchorTop, anchorOffset, createdAt)
if no active item:
    y[0] = max(anchorTop[0], minY)
    for i in 1..n-1: y[i] = max(anchorTop[i], y[i-1] + h[i-1] + gap)
else (active index a):
    y[a] = anchorTop[a]                                    # active card aligned with its anchor
    for i in a+1..n-1: y[i] = max(anchorTop[i], y[i-1] + h[i-1] + gap)
    for i in a-1..0:   y[i] = min(anchorTop[i], y[i+1] - gap - h[i])   # push earlier cards up
    if y[0] < minY: shift = minY - y[0]; re-run forward pass from 0 with y[0] = minY   # active may move down
```

- Recomputed (next frame, coalesced) on: document layout change, item list change, active
  change, measured height change, zoom, panel resize. Cards animate to new positions (150 ms,
  off with *Reduce motion*).
- Only cards intersecting the viewport ± 1 viewport height are built; others contribute
  estimated/cached heights.
- The margin is the **only** place comments and suggestions are shown (there is no comments
  side panel or Suggestions panel; [05](05-screens-menus-toolbar.md) §10.2). Write's
  `WriteViewPrefs` is the shell `CommentsHost`: the title-row 💬 button and *View › Comments and
  suggestions* (`shell.comments.togglePanel`) show/hide it (local pref `write.view.commentMargin`,
  default on); creating or activating a comment shows it.
- The margin has no filter: it shows open threads and pending suggestions (the shared
  `CommentsFilterTabs` Open / For you filter is not shown and stays at *Open*).
- The new-comment composer is a card in the margin at its anchor (an item of the layout above).
- Margin column: 300 px cards (column 324 px with its padding) to the right of the page (Pages)
  or of the content column (Pageless). Pages: the margin is drawn over the canvas's right edge
  and the page centers in the rest (`WonkyEditor.endInset`), moving left as needed; when the
  window is too narrow for both, the page sits at an 8 px left gutter so the margin covers at most
  the page's right margin. Pageless: a column beside the content. Hidden below 600 px window
  width.

### 3.3 Interaction

- Click on highlighted text → activates the innermost (shortest) thread under the click; when
  several overlap, the active card shows "1 of 3 ▸" to cycle.
- Moving the caret into an anchor (keyboard) **marks** the card (subtle ring) but doesn't
  activate it (no layout jump while typing).
- Activating a card scrolls its anchor into view if needed; `Esc` deactivates.
- `?comment=<threadUuid>` deep link activates the thread after load (and shows the margin if it
  is hidden).
- Next/previous comment or suggestion (document order): `Mod+Alt+N` / `Mod+Alt+P` (editor
  scope; on Windows, Ctrl+Alt combos that produce an AltGr character are passed to text input
  instead).
- Viewers see comments only if the owner allows it; they never see the composer.

---

## 4. Version history (Write)

### 4.1 `WriteVersionProvider` (server, implements the suite `VersionProvider`)

- **Capture**: `ItemVersion(storageKind: writeRevision, revision: head, authors)` per the suite
  capture policy (auto after 5 min idle following edits, ≤ 1 per 30 min of continuous editing,
  named on demand, `restorePoint` before restores). Capture ensures a `DocumentSnapshot` exists
  at that revision (written synchronously if missing), so op-log pruning never breaks
  materialization. `authors` = distinct `authorId`s (and actor kinds) of ops since the previous
  version.
- **Materialize**(revision): nearest snapshot ≤ revision, compose ops up to it (cached LRU by
  `(documentId, revision)`, 64 entries).
- **Restore**: §4.5.

### 4.2 Diff with per-author attribution (`AttributedDiff`, core)

Comparing revisions `A < B` (default in the UI: each version vs. the previous version in the
list):

1. **Attributed replay** (exact authorship) when all ops `A+1…B` are retained and their count
   ≤ 20,000 (`WriteHistoryService.maxReplayOps`; past it the ops are not loaded at all and the
   diff compares the two snapshots, step 2):
   - Start from `doc(A)` with `cmt_*`/`sug_*` stripped; maintain a *tombstone document* `T` in
     which every char carries an internal mark: `orig` (present at A), `ins{by}`,
     `del{by}` (present at A, deleted later — kept as a tombstone), `fmt{by, before}`.
   - For each op `O` (author `u`): walk `O` against `T` where **retain/delete lengths count only
     non-tombstone characters** (tombstones are skipped transparently): inserts → new chars
     `ins{u}`; deletes of `ins` chars → removed entirely (they never existed at A or B); deletes of
     `orig`/`fmt` chars → become `del{u}` tombstones; retains with non-overlay attribute changes
     on `orig` chars → `fmt{u, before}` (first `before` kept).
   - At the end, chars marked `fmt` whose attributes equal `before` revert to `orig`.
2. **Fallback** (ops pruned or > 20k): `doc(A).diff(doc(B))` (dart_quill_delta, document deltas)
   with authorship unknown → changes attributed to "Multiple people" (the version's `authors`
   shown in the legend) in a neutral color.

Result (`WriteDiffView`):

```jsonc
{
  "fromRevision": 120, "toRevision": 184, "exact": true,
  "deltaJson": "...",   // doc(B) content plus tombstones, with overlay attrs:
                        //   diff_ins:{"by":"<userUuid>"} · diff_del:{"by":…} · diff_fmt:{"by":…,"before":{…}}
  "authors": [{"userUuid":"…","name":"Anna","colorIndex":3,"actorKind":"user","inserted":312,"deleted":40,"formatted":12}],
  "changeCount": 17     // contiguous change regions (for next/prev navigation)
}
```

Computed server-side by `WriteHistoryEndpoint.diff`, cached in memory (LRU 32) and in table
`write_diff_cache` (documentId, fromRevision, toRevision, json, createdAt; purged after 7 days).
p95 budget: < 500 ms for 2,000 ops on a 50-page document.

### 4.3 Endpoint — `WriteHistoryEndpoint` (`writeHistory`)

| Method | Description |
|--------|-------------|
| `getVersionDocument(documentUuid, revision)` → `{deltaJson, revision}` | Materialized content (overlays stripped) |
| `diff(documentUuid, fromRevision, toRevision)` → `WriteDiffView` | §4.2 |
| `createRestorePoint(documentUuid)` → `ItemVersionView` | Captures `restorePoint` at head |
| `restore(documentUuid, versionId)` → `{revision}` | Server-computed restore (used by MCP / headless) |
| `copyVersion(documentUuid, versionId, name, parentUuid?)` → `DriveItemView` | New document from the version (overlays stripped) |

Listing, naming and thinning use the shared `VersionEndpoint`. Role: viewing history and diffs
requires **Editor+** (Google Docs parity); Commenters/Viewers see *Version history* disabled
("Ask an editor"). Named versions list (`versions.list`) is visible to Viewer+ for downloading
named versions if export is allowed (P2).

### 4.4 History UI (route `/d/:uuid/history`, suite layout)

- **Left**: `SuperReader` with the document theme rendering the selected version's
  `WriteDiffView` when *Show changes* is on (insertions: author color text + underline;
  deletions: struck in author color; formatting: dotted underline + tooltip "Formatted: Bold"),
  or the plain version when off. Toolbar: *Show changes* switch, author legend chips (click to
  show/hide one author's highlights), change navigation `↑ ↓` ("Change 3 of 17", also `Mod+Alt+N/P`),
  zoom.
- **Right**: versions list (suite) — each entry shows name or timestamp, author avatars with
  colors, and for auto groups an expander. ⋮: *Name this version*, *Restore this version*,
  *Make a copy*, *Download as ▸* (formats from [07](07-import-export-print.md), using `revision`),
  *Compare with…* (pick a second version; diff between the two, any order normalized to A < B).
- **Top bar**: *← Back to editing*, version title, *Restore this version* (primary).
- The current version (head) is the first list entry ("Current version"); live edits by others
  update it (refetch diff debounced 5 s).
- Keyboard: ↑/↓ in the list moves between versions; Enter toggles a group.

### 4.5 Restore

Client flow (interactive, one undo step "Restore version"):
1. `createRestorePoint(documentUuid)` (named "Before restoring ‘<version name/time>’").
2. Fetch `getVersionDocument(revision)` → `V`; take the current local document `C` (head as
   known by the client).
3. `R = strip(C).diff(strip(V))` where `strip` removes `cmt_*`/`sug_*` (lengths are unaffected —
   overlays are attributes). Applying `R` to `C` keeps comment anchors and pending suggestions on
   surviving text; text that only exists in `V` comes back without overlays; comments whose text
   disappears become orphaned (and un-orphan on undo).
4. Submit `R` as a normal op with `kind: restore`; it's transformed by OT if others edit
   concurrently (their concurrent edits survive, like Google Docs). Undo = inverse, as usual.
5. Navigate back to the editor with a toast "Restored version from 10:42 — *Undo*".

Headless (`versions.restore`, MCP/AI): the server does the same under the document lock and
returns `change_id` (`changes.revert` works for 24 h).

*Current implementation (v1):* the interactive *Restore this version* also uses the suite's
server-side restore (`shell.versions.restore` → `version.restore`, restore point captured
first); the restore op reaches every client on the document stream (concurrent edits survive
through OT) and the step is undone by restoring the restore point (`versions` undo domain).

---

## 5. Presence in Write

- **Channels**: remote carets/selections use the **document stream** (`CursorUpdate` /
  `RemoteCursor`, [03](03-sync-protocol.md) §1) because they must be ordered with ops for correct
  transformation; the shared `PresenceEndpoint` carries the roster, state (active/idle/away),
  mode (editing/suggesting/viewing) and is what the avatar stack uses. Write clients send
  `PresenceUpdate.cursor = null` (cursor data lives on the doc stream).
- **Rendering** (`RemoteCursorLayer`, `RemoteSelectionLayer` using suite primitives): caret 2 px in
  presence color with a name flag (flag shown for 3 s after movement or on hover); selection fill
  20 % alpha; idle users' carets at 50 % opacity without flag; away users' carets hidden; the
  user's own other sessions shown as dashed caret "You (other tab)".
- Remote positions are kept as `(revision, anchor, head)` and transformed through every applied op
  (`transformPosition`, remote inserts at the same index push the caret right except for the
  author's own op).
- **Follow** (`write.presence.follow`): the viewport keeps the followed user's caret within the
  middle third (smooth scroll); stops on local scroll/typing/click; avatar ring dashed while
  following; works in Viewing mode.
- **Agent presence**: when an MCP/AI op is applied, the server emits a transient `RemoteCursor`
  for the synthetic participant ("Claude via Anna", sparkle flag) at the end of the changed
  range plus a 1 s flash highlight of the changed range; removed after 5 s of inactivity.
- **Offline**: remote cursors are removed; reappear on reconnect after `Init`.

---

## 6. Activity

- Edits are logged as aggregated `ActivityEvent(edited)` (suite §5 of drive spec); Write adds a
  summary `{insertedChars, deletedChars, suggestions: n, actorKinds}` for the details panel.
- Title row "Last edit was 3 minutes ago by Bo" (see [05](05-screens-menus-toolbar.md)) opens
  history at the latest version.
- Suggestion decisions and comment resolutions appear in the activity feed.

---

## 7. Commands

| Command id | Args | Role | Undoable | Binding |
|------------|------|------|----------|---------|
| `shell.comments.create` (suite id; Write implementation) | `{range?}` (default selection) | Commenter | ✓ (with thread) | `Mod+Alt+M` |
| `write.comments.addDocumentComment` | — | Commenter | ✓ | |
| `write.comments.activate` | `{threadUuid}` | Viewer* | — | |
| `write.comments.next` / `write.comments.previous` | — | Viewer* | — | `Mod+Alt+N` / `Mod+Alt+P` |
| `write.comments.reattach` | `{threadUuid, range?}` | Editor | ✓ | |
| `write.comments.deleteThread` | `{threadUuid}` | author/Editor | ✓ | |
| `write.mode.set` (defined in [04](04-editor.md) §31) | `{mode: "editing"\|"suggesting"\|"viewing"}` | Viewer (editing needs Editor) | — | `Mod+Alt+Shift+Z/X/C` |
| `write.suggestions.accept` | `{suggestionIds: [..]}` (default: active/selection) | Editor | ✓ | |
| `write.suggestions.reject` | `{suggestionIds}` | Editor (author: withdraw) | ✓ | |
| `write.suggestions.acceptAll` / `write.suggestions.rejectAll` | `{authorUuid?}` | Editor | ✓ | |
| `write.suggestions.next` / `write.suggestions.previous` | — | Viewer* | — | |
| `write.view.suggestionPreview` (defined in [04](04-editor.md) §31) | `{mode: "show"\|"accepted"\|"original"}` | Viewer* | — | |
| `write.history.open` | `{versionId?}` | Editor | — | `Mod+Alt+Shift+H` |
| `write.history.nameCurrentVersion` | `{name}` | Editor | — (suite: naming isn't on the content stack) | |
| `write.history.selectVersion` | `{versionId}` | Editor | — | |
| `write.history.compare` | `{fromVersionId, toVersionId}` | Editor | — | |
| `write.history.toggleShowChanges` | `{on?}` | Editor | — | |
| `write.history.nextChange` / `write.history.previousChange` | — | Editor | — | |
| `write.history.restore` | `{versionId}` | Editor | ✓ | |
| `write.history.copyVersion` | `{versionId, name}` | Editor | ✓ (drive) | |
| `write.presence.follow` / `write.presence.unfollow` | `{sessionId}` | Viewer | — | |
| `write.presence.jumpTo` | `{sessionId}` | Viewer | — | |

`*` subject to the "viewers can see comments" setting. Shared comment actions (reply, edit,
resolve, reopen, react) are suite `shell.comments.*` commands.

---

## 8. MCP for comments, suggestions, versions (Write specifics)

- **Anchors** for `comments.create` on documents: `{quote: string, occurrence?: int (1-based,
  default 1)}` matched against the document's **plain text** (Delta text where embeds are
  U+FFFC, U+2028 kept; exact, case-sensitive; `not_found` / `ambiguous` errors when occurrence
  is omitted and the quote appears more than once — `details.count`), or `{start: int, length:
  int}` (0-based Delta offsets), or `{document: true}`. The server applies the `cmt_*` op
  (`actorKind: mcp`) and creates the thread in one step; returns `{thread_uuid, change_id,
  revision}`.
- `comments.list` on documents adds per thread `{anchor: {start, length, quote} | null, status,
  suggestion_id?}` computed from head.
- Suggestions: `write.list_suggestions`, `write.accept_suggestion`, `write.reject_suggestion`,
  `write.suggest_edit` — specified in [09-mcp-and-ai.md](09-mcp-and-ai.md).
- `versions.get {uuid, version_id, format: "markdown"|"delta"|"text"}`; `versions.restore` (§4.5);
  Write adds `write.compare_versions {document_uuid, from_version_id?, to_version_id?,
  from_revision?, to_revision?, format: "summary"|"markdown"|"delta" = "summary"}` →
  `{exact, authors[], changes: [{kind: "insert"|"delete"|"format", by, text, context_before,
  context_after, position}]}` (summary capped at 200 changes, paginated with `cursor`).

---

## 9. Undo behavior

| User action | Undo domain(s) | Undo result |
|-------------|----------------|-------------|
| Add comment | `comments` + `write.content` (one step) | Thread deleted, anchor attribute removed |
| Delete thread | same | Thread restored (suite comment snapshot) + anchor re-added |
| Resolve / reopen | `comments` | Status reverted |
| Suggest (typing/deleting/formatting in Suggesting mode) | `write.content` | Suggestion change reverted (rewritten op inverse) |
| Accept / reject / withdraw (single or all) | `write.content` | Suggestion(s) reappear; server reopens threads (`suggestionReopened`) |
| Restore version | `write.content` | Inverse of the restore op; the restore point stays in history |
| Re-attach orphaned comment | `write.content` | Attribute removed → thread orphaned again |

Remote changes rebase these entries per [03](03-sync-protocol.md) §4; an accept whose
suggestion was concurrently modified undoes only what it changed.

---

## 10. Edge cases

| Case | Behavior |
|------|----------|
| Concurrent accept (Alice) and author typing inside the suggestion (Bob) | OT keeps Bob's new chars with `sug_X`; X stays pending with the remaining part; card shows "1 more change". |
| Concurrent accept and reject of the same suggestion | Server order decides; the second op's parts are no-ops after transform (attribute already gone / chars already deleted); the later actor sees a toast "Already handled by Anna". |
| Suggestion within suggestion (Alice suggests deleting text inside Bob's suggested insertion) | Both attributes on the chars. Accept Alice's `del` → chars deleted → Bob's X shrinks (or is *superseded* if empty). Reject Bob's `ins` → chars deleted → Alice's suggestion superseded. |
| Formatting suggestion over another user's insertion suggestion | `fmt` with `before` = attrs at that time; both cards independent. |
| Comment on suggested text | Allowed (separate `cmt_*`); if the suggested text is rejected, the comment is orphaned. |
| Editor in Editing mode edits text inside someone's `ins` suggestion | Typed chars inherit the suggestion attribute only if typed strictly inside (attribution expansion), otherwise plain; deleting it is a real delete (may supersede). |
| Role downgrade Editor → Commenter while in Editing mode | Mode switches to Suggesting live; buffered local ops that aren't valid commenter shapes are rewritten with `SuggestionRewriter` against the current doc before sending; if rewriting fails → discarded with the suite "unsaved changes" export. |
| Undo of an accept after the text was further edited | Rebased inverse re-adds the attribute on remaining chars only. |
| Comment anchor fully inside a suggestion that gets rejected | Thread orphaned ("Original content deleted"); undo of reject un-orphans. |
| Copy/paste of suggested text | Clipboard uses `SuggestionView.accepted` text; overlays stripped. |
| Very many comments (> 500 open) | Margin builds only visible cards; highlights still rendered (inline styler). |
| History diff across a restore | Attributed replay shows the restore op as edits by the restoring user. |

---

## 11. Acceptance criteria

1. Adding a comment on a selection shows the highlight and card for all collaborators within
   500 ms; works offline (anchor op + thread queued) and syncs on reconnect.
2. Deleting all anchored text marks the thread *Original content deleted* for everyone; undo
   restores the anchor and the thread returns to open.
3. Margin cards never overlap; the active card aligns with its anchor; layout recomputation
   < 4 ms for 200 visible items.
4. In Suggesting mode, typing, deleting, Enter/Backspace joins, inline formatting, block type
   changes, list changes, image/divider insertion and deletion, paste and AI insertions all
   produce suggestions (table edits are disabled in v1); no direct content change is ever sent by a Commenter (server rejects any).
5. Accept/Reject (single and all) produce the documented ops; each is one undo step; undoing
   reopens the suggestion thread; decisions notify the author.
6. *Preview accepted*/*Preview original* render exactly `SuggestionView` output; exports with
   `suggestions: accepted|original` match the previews.
7. History shows per-author colored insertions/deletions for versions within retained ops, and
   a correct (unattributed) diff otherwise; restore creates a restore point, is one undo step, and
   keeps concurrent edits by others.
8. Remote carets stay at the correct positions under concurrent edits (fuzz test) and follow mode
   tracks the followed user.
9. All commands in §7 are invocable through `ui.invoke_command`; MCP `comments.create` with
   `{quote, occurrence}` anchors correctly and reports `ambiguous`/`not_found`.

## 12. Tests

- **Core unit/property**: `SuggestionRewriter` table-driven per rule + property test: for random
  docs and random edits, `SuggestionView.original(docBefore.compose(rewrite(C))) ==
  SuggestionView.original(docBefore)` (suggesting never changes the original) and
  `SuggestionView.accepted(...)` equals `docBefore.compose(C)` modulo overlays; `SuggestionOps`
  accept/reject correctness; `OverlayIndex` counts vs. full rescans after random op sequences;
  decision inference; `AttributedDiff` vs. brute force on small random histories (tombstone
  replay equals naive per-char tracking); margin layout (no overlaps, active alignment,
  monotonic order).
- **OT fuzzer extension**: include comment anchors, suggestions, accepts/rejects and restores;
  assert convergence, validity and that commenter clients never produce rejected ops.
- **Widget**: cards, composer, markers mode, suggestion rendering goldens (light/dark), history
  screen goldens.
- **Server** (`serverpod_test`): commenter op validation (all allowed/forbidden shapes),
  suggestion thread auto-creation (UUIDv5), orphan/un-orphan transitions, notifications
  throttling, restore endpoint, diff cache, role gates for history.
- **Integration** (flutter_driver + MCP): two app instances — Commenter suggests, Editor accepts
  via `ui.invoke_command("write.suggestions.accept")`, verify via `write.get_document`.
