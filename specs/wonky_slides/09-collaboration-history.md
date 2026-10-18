# Slides 09 · Collaboration, Comments and History

How the suite collaboration framework ([07-collaboration.md](../07-collaboration.md)) applies to
decks: **presence** (avatars per slide, selection outlines, live pointers, follow mode, following
a presenter), **soft locks** on text and **ephemeral hints** for a live feel on top of RevLog
sync, **comments** on slides and elements, **version history** (snapshots, per-slide diff,
restore, copies), **activity**, and **offline behavior** with a table of conflict scenarios.

Read first: suite [07](../07-collaboration.md), [17 · RevLog sync](../17-revlog-sync.md) (part 6
§6 conflicts and outcomes), [08 §3](../08-commands-and-undo.md); Slides [02](02-data-model.md)
(ids, op summaries §3.10, soft lock §4.4, invariants §10). Sheets
[10](../wonky_sheets/10-collaboration-history.md) is the model this spec mirrors.

Owned folders: `wonky_slides/lib/features/{collab,comments,history}/`,
`wonky_slides_core/lib/src/{snapshot,diff}/`, `wonky_server/lib/src/slides/versions/` and the
deck hooks (`wonky_server/lib/src/slides/revlog/slides_hooks.dart`, `deck_comments.dart`).

Priorities: soft locks and the presence roster are **M9** (needed as soon as two people edit);
the rest is **M11** unless marked.

---

## 1. Presence

### 1.1 Slides `PresenceCursor` JSON

```jsonc
{
  "route": "editor",                     // editor | present | history | print
  "viewMode": "normal",                  // normal | grid | outline | masters
  "slideId": "Abc…",                     // current slide (masters mode: layout/master id + "owner": "layout"|"master")
  "selection": ["el1…", "el2…"],         // selected element ids (≤ 50), or slide/group ids in the navigator:
  "navSelection": { "slides": [], "groups": [] },
  "editing": null,                       // soft-lock claim, §2.1
  "pointer": null,                       // {x, y} su on the current slide (P1, §1.4)
  "transform": null,                     // live drag hint flag (frames travel as hints, §2.4)
  "viewport": null,                      // {slideId, zoom, cx, cy} — sent only while followed (§1.5)
  "presenting": null                     // {presentationId, slideId, step} while presenting (§1.6, 10)
}
```

- Sent on change, throttled to 10/s and coalesced (suite 07 §1.1); `pointer` at most 20/s, only
  while the pointer is over the slide and the window is focused.
- Unknown ids (rows not synced yet) are ignored until they arrive.
- Agents: headless MCP/AI writes inject a transient participant (suite 07 §1.1) whose `slideId`
  and `selection` come from the plan summary of their writes, for 5 s (`DeckAgentPresence`,
  shown by the server's MCP write path after the write — as Sheets' `AgentCursors`).

### 1.2 Where presence shows

| Place | Rendering |
|-------|-----------|
| Header `PresenceAvatarStack` | Tooltip "Editing slide 4 · Intro", "Presenting", "Editing layouts", "Viewing", "Idle"; click → jump (§1.5); ⋮ → *Follow* |
| Navigator | Up to 3 presence dots (14 px avatars) at the right of the thumbnails of slides people are on, then "+N"; on collapsed group headers for people inside the group |
| Grid view | Same dots under thumbnails |
| Canvas — selections | 2 px outline in the participant's presence color around each selected element + name flag above the first (`RemoteCursorOverlay` primitives, suite 02 §4.8); flags fade after 3 s of inactivity, reappear on hover |
| Canvas — editing | Soft-lock outline (dashed, presence color) + flag "✎ Anna is editing" (§2.3) |
| Canvas — pointers (P1) | Figma-style arrow cursor in presence color with a name label; hidden after 5 s idle; toggle View › Show › Collaborator cursors (`slides.view.toggleRemoteCursors`, default on; off with the a11y setting "Reduce collaborator cursors") |
| Notes pane | "✎ Bo is editing the notes" banner while claimed |
| Outline view | Colored caret bars on the lines others edit |

Away participants are not drawn (avatar greyed). Remote chrome is hidden in presenting, PDF and
thumbnails.

### 1.3 Jump

Clicking an avatar or a navigator presence dot → `slides.presence.jumpTo {sessionId}`: switches to
their slide (and view mode if needed), scrolls so their selection is visible, flashes their
selection outline twice. No change to the local selection.

### 1.4 Live pointers (P1)

Pointer positions are ephemeral (`pointer` in su) and painted in the canvas overlay layer with
1-frame interpolation (no animation with *Reduce motion*). Pointers of participants on other
slides are not shown (their avatar dot in the navigator suffices).

### 1.5 Follow mode

`slides.presence.follow {sessionId}` (avatar ⋮ › *Follow*): banner at the top-right of the canvas
"Following Anna · Stop" (presence-colored left border). We switch to their current slide and view
mode whenever it changes and mirror their `viewport` (zoom/center) when on the same slide.
Stops on any local navigation, selection, scroll/zoom, Esc, *Stop*, or when they leave. The
server counts followers (`FollowerCount`, suite 07/Sheets A-10-6) so the followed client sends
`viewport` updates (≤ 2/s) only while followed; the followed user sees "Bo is following you" in
the avatar tooltip.

### 1.6 Following a presenter

While a participant presents (`presenting` set, [10](10-presenting-and-pdf.md)), others see a pill
in the status bar and a live dot on the Present button: **"Anna is presenting — Follow"**
(`slides.presence.followPresenter {sessionId}`). Following opens present mode in **follower mode**
(same tab, full screen optional): slides and build steps track the presenter's `{slideId, step}`
(transitions/builds play locally from the shared timeline, 06), with *Stop following* and *Take
control* disabled (P2 remote control is 10's phone-remote feature). Followers can't navigate while
following (arrow keys show "Following Anna — press Esc to stop"). The presentation session itself
(audience on other devices or browsers, phone remote, sync of steps) is specified in 10.

---

## 2. Soft locks and live hints

> SL-13 hook: text editing asks `textEditingOf(editor).locks` (`TextEditLocks`, app
> `features/text_editing/text_editing_host.dart`) before editing a body (`request`, may show
> the popover and complete later), announces `claim`/`release`, and format commands on whole
> elements skip bodies `heldBy` names. SL-21 supplies the implementation.

### 2.1 Claims

The `editing` field of the cursor (02 §4.4):

```jsonc
"editing": { "kind": "text",            // text | notes | tableCell | code | codeState | groupTitle
             "slideId": "…", "elementId": "…", "cellId": null, "stateId": null,
             "since": 1760262734123,      // claim start (sender clock, ms)
             "forced": false }            // true when entered via "Edit anyway"
```

- A claim starts when text editing starts in a body and ends on exit, after 60 s without input
  (idle), on window hidden > 30 s, or when the session leaves (presence drops it after 30 s).
- **Simultaneous entry race**: if two non-forced claims for the same body exist, the one with the
  earlier `since` wins (tie: smaller `sessionId`). The losing client shows the popover *"Anna
  started editing this text first."* [Stop editing] [Keep editing] — *Keep editing* converts its
  claim to `forced: true` (same as *Edit anyway*).
- Claims cover exactly one body: the text of one element, one table cell, one slide's notes, one
  code state, or one group title (inline rename).

### 2.2 Commands and enforcement

- Entering editing of a body claimed by someone else shows the soft-lock popover (04 §13.11);
  *Edit anyway* → `slides.text.editAnyway {target}` (non-undoable) enters editing with a forced
  claim.
- Commands that would write a claimed body (format whole element, find/replace, AI rewrite,
  paste into it, outline edits) skip it with a toast naming the claimer; box-level properties stay
  editable.
- MCP/AI headless writes get `being_edited` (11) unless forced.

### 2.3 UI states of a claimed body (for others)

| State | Visual |
|-------|--------|
| Claimed | Dashed 1.5 px outline in the claimer's color; flag "✎ Anna is editing"; text shows **live hints** (§2.4) |
| Claimed by two (forced) | Two outlines (offset 2 px) and stacked flags "Anna, Bo editing" |
| Hover | Tooltip "Anna is editing this text — double-click to edit anyway" |
| Released | Outline fades over 300 ms (instant with reduce motion) |

### 2.4 Ephemeral hints

Hints ride on the presence stream (`PresenceUpdate.hints` → `PresenceEvent.Hints`, suite
extension A-10-6) — never persisted, never echoed to the sender; the synced rows remain the
truth. Committed edits reach other editors in about one round trip (RevLog ops are fanned out
at once, [17](../17-revlog-sync.md) part 7 P1), so hints only bridge the time until the editor
commits (the 300 ms typing pause of 02 §4.4, a drag in progress); their behavior doesn't depend
on the sync timing (17 part 6 §10).

```jsonc
// Text being typed (throttled 4/s per body; ≤ 16 KB; full body when ≤ 4 KB, else a Delta diff
// against the sender's last synced text with its hash)
{ "t": "text", "target": {"kind":"text","elementId":"…"}, "delta": [ … ] | null,
  "diff": [ … ] | null, "baseHash": "…", "hlcMillis": 1760262734123 }

// Live drag/resize/rotate (P1, 10/s while transforming)
{ "t": "transform", "slideId": "…", "frames": { "<elId>": [x, y, w, h, rotation] } }

// Structure change just committed (slide insert/move/delete, group ops) — navigator shimmer
{ "t": "structure", "slideIds": ["…"], "groupIds": ["…"], "hlcMillis": … }
```

`hlcMillis` is the sender's wall clock when the hint was made (the name is kept for the wire);
committed ops carry no comparable time, so receivers clear text hints by content (below, §2.5).

Receiver (`SlidesHintOverlay`):

- **Text**: renders the hinted text in place of the stored body (same styles) until a remote
  batch brings a committed text of that body equal to the hint, the claim ends + 5 s, or a local
  edit happens. A diff whose `baseHash` doesn't match the receiver's text is ignored (the next
  full hint or the committed text fixes it).
- **Transform**: draws the moving elements' outlines (not content) at the hinted frames in the
  mover's color; cleared on the committed write (a remote batch touching the element) or after
  2 s.
- **Structure**: a 1 s shimmer on the affected navigator rows.
- Limits: ≤ 20 hint messages/s per session, ≤ 64 KB per message; the server drops hints from
  participants below Editor.

### 2.5 As built (SL-21)

`wonky_slides/lib/features/collab/`:

- `slides_presence_cursor.dart` — `SlidesPresenceCursor` (the §1.1 JSON plus `"app":"slides"` so
  other apps' cursors are ignored, and `following` for "Following you" in the followed user's
  avatar tooltip), `EditingClaim` (§2.1; table cells also carry `rowId`/`columnId` next to the
  `cellId` = `SlidesIds.tableCellId` the server's `DeckTextClaims` reads), `DeckViewport`
  (`zoom` null = *Fit*), `PresentingState`.
- `slides_presence_controller.dart` — `SlidesPresenceController`: publishes the cursor through
  the shell's `PresenceSession` (deduplicated; the session throttles to 10/s; the viewport only
  while `followerCount > 0`, ≤ 2/s), maps remote cursors (`cursorsOn`, `bySlide`, `presenters`),
  flags (3 s, flash on jump), avatar details ("Editing slide 4 · Intro", "Viewing slide …",
  "Presenting", "Editing layouts", "… · Following you"), `jumpTo`, `follow`/`unfollow` (stops on
  a local slide, selection, zoom or view-mode change, a pan, Esc, *Stop*, or when they leave).
- `soft_locks.dart` — `SlidesSoftLocks`, installed as `textEditingOf(editor).locks`: claims with
  idle (60 s) and hidden-window (30 s) expiry (input claims again with a new `since`), the
  soft-lock question (`SoftLockPrompt`), the race rule (`beats`: earlier `since`, tie → smaller
  session id; the loser gets *Stop editing* / *Keep editing*), `heldBy` for formatting.
  The text editing hook gained `TextLockTarget` (element, table cell, notes) and the `…Target`
  methods, defaulting to the element methods (additive).
- `slides_hints.dart` — `SlidesHints` (sender and `SlidesHintOverlay` receiver of §2.4):
  `text` hints of element bodies while typing (≤ 4/s), `transform` hints while dragging
  (≤ 10/s); `hintedScene` swaps the hinted elements' nodes into the stage scene (rebuilt with the
  hinted body, same styles and auto-fit).
- `collab_canvas_layer.dart` — `CollabCanvasLayer` (a `CanvasInteraction`): hinted scene,
  remote selection outlines (2 px, rotated with the element) + name flags, soft-lock outlines
  (dashed 1.5 px, offset 2 px per claimer) + "✎ Anna is editing" flags (hover: "… — double-click
  to edit anyway"), live drag outlines, the soft-lock popover next to the box (`SoftLockPopover`,
  Esc = no) and the follow banner.
- `presence_widgets.dart` — `SlidePresenceDots` (navigator rows, collapsed group headers, grid
  cells; click = jump), `NotesLockBanner` ("✎ Bo is editing the notes" and the notes question),
  `PresenterPill` (status bar, "Anna is presenting — Follow").
- `slides_collab.dart` — `SlidesCollab.attach/of(editor)` (attached by `DeckEditorScreen` when the
  deck is ready; `DeckDocumentController.attachPresence/revealParticipant/followParticipant`
  forward to it; `describeState` adds `collaborators`, `softLocks`, `following` to MCP
  `ui.get_state`). Presenting is published from SL-19's `activePresentation` (the present screen
  of this deck, not audience views).
- Commands (`commands/collab_commands.dart`): `slides.presence.jumpTo|follow|unfollow|
  followPresenter`, `slides.text.editAnyway {elementId?, rowId?, columnId?}`.

Deviations: text hints carry the **full body** only (no `diff`/`baseHash`; bodies over 16 KB
send no hint); a hint is cleared when the synced text **equals** it (ops carry no comparable time),
when the sender's claim ended + 5 s (30 s without updates at most) or on a local edit; table
cell and notes bodies get claims but no live hints. (Built since by SL-37, §2.6: `structure`
hints and the navigator shimmer, live pointers, the Present button's live dot, the 300 ms fade
of released outlines, *Follow presenter* as a `follower` of the presentation session — SL-21
joined as an audience view, which the server refuses for other accounts.) Without a session
*Follow presenter* follows the presented slide in the editor. The View toggle *Collaborator
cursors* hides remote selection outlines, flags and pointers (soft locks stay).

### 2.6 As built (SL-37)

`wonky_slides/lib/features/collab/` (extends §2.5):

- **Live pointers (§1.4).** `SlidesPresenceCursor.pointer` (`{x, y}` in whole su of the canvas
  surface) is set by `CollabCanvasOverlay` from mouse hover/move while the pointer is over the
  slide and the window is resumed (cleared on exit, hide, inactive) and published with the cursor
  (`SlidesPresenceController.pointer`). Receivers draw `CollabPointer` (arrow + name pill in the
  presence color, `slides.collab.pointer.<sessionId>`, semantics "Anna's pointer") for people on
  the same surface (`pointersOn`), moving with a 100 ms `AnimatedPositioned` (none with reduce
  motion), hidden 5 s after the pointer last moved (`RemoteDeckCursor.pointerAt`) and with the
  *Collaborator cursors* toggle off. Deviation: pointers ride the presence session's cursor
  throttle (10/s, not 20/s); there is no separate a11y setting "Reduce collaborator cursors" (the
  Slides default `showRemoteCursors` is the switch).
- **Surfaces.** In masters mode the cursor carries `surfaceId` (the edited layout/master);
  remote outlines, flags, pointers, drag hints and the followed viewport compare *surfaces*
  (`RemoteDeckCursor.surfaceId`, `cursorsOn(surfaceId)`), so selections on a layout show only to
  people editing that layout. The avatar tooltip names the layout ("Editing layout · Title and
  body").
- **Follow mode refinements (§1.3, §1.5).** Jump and follow switch to the participant's view
  mode incl. the outline and masters (their layout, when this user may edit layouts; else their
  slide in the normal view); a local change of the masters target also stops following. While
  the followed participant presents, the follow banner offers *Watch presentation*
  (`slides.presence.followPresenter`). The banner is width-constrained (360 px).
- **Following a presenter (§1.6, 10 §6.3).** `slides.presence.followPresenter` with a
  presentation session opens `…/present?view=follow&session=<id>` (`PresentView.follower`,
  role `follower`: ≥ viewer, any account; the server drops followers' commands). The follower
  view tracks slides and build steps like the audience view, never sends commands, has no
  toolbar, ink or kiosk/auto-advance, and shows `FollowerBar` ("Following Anna — press Esc to
  stop", *Full screen*, *Stop following* = `slides.present.end`/Esc). Navigation keys **browse
  away** locally (10 §6.3 — this replaces §1.6's "arrow keys only show a hint"): the bar then
  says "You left Anna's slide" with *Return to presenter* (`slides.presence.returnToPresenter`,
  Shift+R, keymap scope `present`), which jumps to the presenter's latest state.
  `SlidesCollab` doesn't publish `presenting` for audience or follower views. The Present
  split button shows a live dot in the presenter's color while someone presents
  (`PresentLiveDot`, `slides.present.liveDot`) and its menu starts with *Follow Anna's
  presentation*.
- **Structure hints (§2.4).** A local batch with `OrderChanged` sends `{t: structure, slideIds,
  groupIds, hlcMillis}` (≤ 200 ids each). Receivers start a 1 s shimmer of the navigator row of
  known slides/groups at once, and of ids not synced yet when their rows arrive (within 10 s)
  — `SlidesHints.shimmerOf`, `StructureShimmer` (sweeping primary-color gradient; a static tint
  with reduce motion) on navigator slide rows and group headers.
- **Released soft locks (§2.3)** fade over 300 ms (instant with reduce motion;
  `slides.collab.released`).
- **Outline view (SL-34 leftover).** Focusing a title or bullet line claims its element (a
  forced claim: the outline has no soft-lock question, so it enters claimed bodies as with *Edit
  anyway* and never starts a race prompt; released when no line of the slide has focus), and
  typing sends `text` hints of the whole body (`SlidesHints.typing`).
- **Agents.** Headless MCP/AI writes show the agent as a participant for 5 s (server
  `DeckAgentPresence`, SL-40) and open editors flash the touched elements (`SlidesAgentFlash`,
  SL-42) — the "server-side agent cursors" and "client-side agent flash" leftovers are done
  there. MCP `ui.get_state` collaborators gain `viewMode`, `surfaceId`, `pointer`, and the
  state lists `presenters`.

Not built (`TODO.md`): text hints for notes and table cells and the Delta `diff`/`baseHash`
form for large bodies; the outline view doesn't show others' live hints in its lines; a
follower count in the presenter view.

---

## 3. Comments

Comments use the suite tables and endpoints (`CommentThread`, `Comment`, suite 07 §2) and the
shell comments UI (`CommentsController`, `CommentThreadBody`, side panel). Slides implements the
`CommentAnchorProvider` + `CommentPanelOptions` (`features/comments/slides_comment_anchors.dart`).

### 3.1 Anchors

| `anchorKind` (suite addition A-04-5) | `anchorJson` | Created from |
|---------------------------------------|-------------|--------------|
| `slide` | `{"v":1,"slideId":"…","point":{"x":1440,"y":200}?}` | Canvas with no selection (pin at the click point or the slide's top-right), navigator slide context menu, *Comment on slide* |
| `element` | `{"v":1,"slideId":"…","elementId":"…","point":{"x":0.9,"y":0.1}?}` | Selected element (point normalized in the element frame; default top-right) |
| `document` | `{"v":1}` | Comments panel "Comment on presentation" (P1) |

- `quotedText` = the element's text (first 120 chars) or kind label ("Image: team.jpg", "Chart:
  Revenue by quarter"), or "Slide 4: Our mission" for slide anchors.
- **`elementId` is authoritative**; `slideId` is a hint: if the element moved to another slide
  (drag to a navigator thumbnail keeps the element id), the client resolves the current slide from
  the model and lazily calls `comment.updateAnchor` (queued offline).

### 3.2 Anchor survival

| Event | Effect |
|-------|--------|
| Slide moved, regrouped, skipped | Anchor unchanged (ids) |
| Element moved/resized/restyled, text edited | Unchanged; pin follows the element |
| **Cut & paste** of elements (same or other slide of the same deck) | The paste re-anchors threads of the cut elements to the new element ids (`comment.updateAnchor`, `comments` undo domain, part of the paste step), as Sheets 10 §3.2 |
| Copy & paste, duplicate slide/element, copy to another deck | Comments are **not** copied |
| Element or slide **deleted** | Thread becomes `orphaned` — server-side from the op summary's `deleted` (02 §3.10.1) with `orphanReasonJson {kind: slide\|element, id, revision}`; the client hides unresolvable anchors immediately |
| Deletion **undone** (revived ids in `summaryJson.revived`) | Previous status restored |
| Slide's group deleted with slides | Each slide's threads orphaned (as slide deletion) |

Orphaned threads appear in the panel under "Orphaned" with the quoted text ("The object this
comment was on was deleted"); they can be resolved or deleted (P2: *Re-anchor to selection*).

### 3.3 Indicators

- **Canvas pins** (`slides.view.toggleCommentPins`, default on): a 28 px speech-bubble pin with the
  thread author's avatar at the anchor point (element anchors: relative point; slide anchors:
  absolute point); a count badge when several threads share an element. Active thread: pin
  enlarged + element outlined in `commentHighlightActive`. Resolved threads show no pin.
- **Navigator**: open-thread count badge per slide (04 §5.2); collapsed group headers show the
  sum.
- **Hover** a pin (300 ms) → hover card with the first comment and reply count; click → the
  thread card docked next to the pin (composer inline, `CommentPanelOptions.composesInline`), or
  in the panel when it's open.

### 3.4 Creating and navigating

- `shell.comments.create` (⌥⌘M, toolbar, context menus) with the anchor from the selection
  (element > slide). With *Comments* panel closed, the composer opens docked at the pin; Esc
  cancels.
- `slides.comments.next` / `previous` (⌥⌘N / ⌥⌘P — Win/Linux Ctrl+Alt+N / P) jump to the next
  open thread in presentation order (slide order, then reading order of elements).
- Deep links `/slides/p/<uuid>?comment=<threadUuid>` (also from notification emails) open the
  slide, select the anchor element and the thread card.

### 3.5 Comments panel (Slides specifics)

Suite panel (Open / For you) + scope filter **This slide / All slides** (default All;
`CommentPanelOptions.scopes`), position sort grouped by **slide** with headers "4 · Our mission"
under **group** super-headers (color dot + title) in presentation order; *By date* sort without
headers; "Orphaned" section at the end. `slides.comments.openPanel {scope?}`.

### 3.6 Mentions, notifications, roles, offline

Suite §3–4 unchanged; notification payloads include `{slideNumber, slideTitle, quotedText}`;
email links use `?comment=`. Commenters can comment, viewers only see comments if the owner allows
it. Offline: `CommentsController.queueOffline = true` (create, reply, resolve/reopen, anchor
moves queued and posted in order, pending marker) as Sheets 10 §3.7.

### 3.7 As built (SL-38)

- **Anchors**: `SlidesCommentAnchor` (`features/comments/slides_comment_anchor.dart`) encodes
  the JSON of §3.1. The anchor comes from the selection: the element being edited (text box,
  shape or table — the selected text is quoted, else the element's text or kind label), else
  the first selected element, else the current slide; with the speaker notes focused, the
  slide. There are no text-range anchors inside bodies, cells or notes (not specced: element
  anchors cover them). Masters view offers no comments. A right-click on the canvas is
  remembered for one minute: the next comment pins at that point (slide su, or normalized in
  the element); otherwise element pins sit at the top-right corner and slide pins stack down
  from the slide's top-right corner. *Comment on presentation* (`document`, P1) has no UI;
  `shell.comments.create {anchorKind: document, anchorJson: '{"v":1}'}` works.
- **Survival**: server hook `comments` of the deck's RevLog ops (`slides/revlog/slides_hooks.dart`)
  orphans open threads when `deleted.elements` holds the element (reason `slide` when its
  slide went too) or `deleted.slides` holds a slide anchor's slide, and revives them from
  `revived`. Resolved threads stay resolved. An element anchor whose slide hint is deleted
  while the element lives on elsewhere stays open. On the client, unresolvable anchors are
  hidden at once and listed under "Orphaned". The slide hint of a moved element is fixed
  lazily (once per thread, by its author or an editor).
- **Cut & paste**: the paste plans return `elementIdMap` / `slideIdMap` (old → new ids);
  `CommentAnchorMoves` (a `DeckEditorController.applyListeners` hook) re-anchors every
  thread whose original element or slide is gone from the deck after a `PasteElements` /
  `PasteSlides` — i.e. it was cut — and records `CommentUndoEntry(updateAnchor)` in the
  paste's step. This also covers cutting and pasting **slides** in the navigator (slide and
  element threads follow). Copies (originals still present) never move or copy comments.
- **Indicators**: `CommentPinsLayer` (a canvas interaction) draws 28 px speech-bubble pins
  (34 px when active, count badge when threads share an element), the active element's
  outline in `commentHighlightActive`, the 300 ms hover card, the docked thread card (Esc or ×
  closes it until another thread is shown) and the inline composer while the comments panel
  is closed. Pin clicks run `slides.comments.show {threadUuid}` (new, palette-hidden: show a
  thread in place). `SlideCommentBadge` shows the open count at the bottom left of navigator
  thumbnails, after collapsed group headers and next to grid cell numbers; clicking it opens
  the panel scoped to that slide.
- **Panel**: scopes *This slide / All slides*; slide headers "4 · Our mission"; slide-group
  sections with the group's color dot through the shell's new optional
  `CommentPanelSections` interface; "Orphaned" last. Slide-anchor labels follow the slide's
  live number and title (the stored quote is "Slide 4: Our mission").
- **Notifications**: payloads gain `slideNumber` and `slideTitle` (`CommentService.payloadExtras`
  for presentations, from the server's deck cache); emails and the bell open
  `/slides/p/<uuid>?comment=<thread>`, which selects the element and docks the card (orphaned
  threads open in the panel).
- **MCP**: `ui.get_state` adds `openComments`, `activeComment`, `commentPins`; every action is a
  command (`shell.comments.*` with `anchorKind` `slide`/`element`, `slides.comments.*`). The
  headless `comments.*` tools with Slides anchors (§8) are SL-40's.

---

## 4. Version history

### 4.1 `SlidesVersionProvider` (server, `wonky_server/lib/src/slides/versions/`)

Implements the suite contract (capture, materialize, restore) + diff and copy.

- **Capture triggers**: the `versions` hook of the deck's RevLog ops updates the shared
  `ItemVersionState` (`lastEditAt`, `editorsSinceLastVersion`, dirty marks); the scheduler
  (FutureCall every minute) applies the suite policy (auto version after ≥ 5 min of inactivity,
  at most one per 30 min of continuous editing, named versions immediately).
- **Snapshot** (`snapshot.wsd`, gzip): header JSON line `{"format":"wonky-slides-snapshot","v":1,
  "deckId","capturedAt","counts":{…}}` + NDJSON records
  `{"tb":"<table>","row":{…}}` for every deck table in dependency order (deck, themes,
  masters, layouts, groups, slides, elements (parents first), table axes, cells, builds, code
  states, chart links). Read with the file's head revision in one repeatable-read transaction
  (below); typical
  size 50–500 KB. Stored as a `StoredFile` (`ItemVersion.storageKind = snapshotFile`; not counted
  toward quota, D3).
- **Uploaded files referenced by versions**: files removed from the current deck stay stored while
  a retained version references them (not quota-counted, D3); they are garbage-collected when no
  retained version and no current content reference them (30-day grace) — coordinate with the
  Drive storage spec.
- **`SlidesSnapshotIndex`** (02 §8): per version the slide list (id, title, group, skipped) and
  `changes` `{slides: {<id>: [authorIds]}, elements: {<id>: [authorIds]}, structure: [...],
  theme: [authorIds]}` built from the ops committed since the previous capture
  (`summaryJson.slides/elements/deleted/revived` + author/`actorKind`).
- **Revision windows**: a capture reads every row of the file and its `headRevision` in one
  repeatable-read transaction and records `ItemVersion.revision`; the window of a version is
  the revisions (previous capture's revision, this one's] — by commit time for versions without
  a revision. Ops whose payload was pruned (> 30 days) mark the changes `approx`.

### 4.2 Viewing a version

Route `/p/:uuid/history?version=<id>` (suite 07 §5 UI) — `SlidesVersionRenderer`
(`VersionRenderer` hook):

1. Download the snapshot (signed URL) and the **previous** version's snapshot; decode in a
   background isolate into two read-only `DeckModel`s (no cache, no session). Fonts and images
   load as usual (images via signed URLs of the referenced files).
2. **Layout**: left = the version's navigator (groups, thumbnails) with change badges; center = the
   selected slide on a read-only canvas; right = suite versions list + **Changes on this slide**.
3. **Badges** (toggle *Show changes*, default on, `slides.history.toggleShowChanges`):

| Change | Navigator | Canvas |
|--------|-----------|--------|
| Slide added | green "New" tag | — |
| Slide changed | dot in the author's presence color (neutral gray for several authors) | Changed elements outlined (2 px, author color); added elements with a "+" corner tag; removed elements as dashed ghost outlines at their previous frames (toggle *Show removed*) |
| Slide moved / regrouped | "↕ Moved" tag | — |
| Slide deleted | ghost row with strikethrough title at its previous position (opens the previous version's slide read-only) | — |
| Group added/renamed/recolored/deleted | header tag "New" / "Renamed" / strikethrough | — |
| Theme/master/layout changed | "Theme changed" row at the top of the change list (opens master mode read-only, P1) | Inherited changes outlined faintly |

4. **Changes on this slide** list: human summaries per element ("Title text edited by Anna",
   "Image replaced by Bo", "3 objects moved by Anna", "Animation added", "Notes edited"); hovering
   a text change shows an inline **text diff** (insertions/deletions colored, computed with
   `DeltaDiff` over the two Deltas); clicking selects the element.
5. **Navigate changes**: `slides.history.nextChange` / `previousChange` (⌥⌘↓ / ⌥⌘↑) step through
   changed slides and elements in presentation order.
6. **Side by side** (P1): the canvas splits into *Previous version* | *This version* for the
   current slide.

### 4.3 Diff computation (`wonky_slides_core/lib/src/diff/`)

Pure Dart, client-side (decks are small; a server endpoint `SlidesVersionEndpoint.diff` caches the
result for decks > 20 MB snapshot size, P2):

- Rows matched **by id** per table; per column compare. Classification:
  - Element: added / removed / changed with kinds `text`, `frame`, `style`, `data`, `order`
    (zKey), `visibility`; children of groups roll up to the group when the group itself changed.
  - Slide: added / removed / moved (`sortKey` or `groupId` changed) / changed (own columns, notes,
    transition, any element, build, code state or chart link of the slide) / skipped toggled.
  - Group: added / removed / renamed / recolored / moved / skip toggled.
  - Theme rows: changed (any column) → listed once.
- Author attribution: from `SlidesSnapshotIndex.changes` (latest author per id); unattributed →
  neutral color. Agent edits show "Claude via MCP (Anna)".

### 4.4 Restore

`VersionEndpoint.restore(itemUuid, versionId)` (Editors+, online only), as Sheets 10 §5.3:

1. Capture a `restorePoint` version of the current state.
2. Stream snapshot and current rows (admin read), row diff by id: snapshot-only rows → insert
   with the same id (revives tombstones); current-only rows → delete; both → update naming only
   differing columns.
3. Commit as a RevLog server change (`SlidesServerWrites.applyRecorded`,
   [17](../17-revlog-sync.md) part 5 §8.1; chunked op group, label "Restore version '<name or
   time>'", inserts counted as `revived` (`insertsAreRevivals`) so orphaned comments come back).
   One `ServerChangeRecord` joins the ops (`recordId`); revert inverts their applied forms.
4. Collaborators receive the ops like any other edit, plus the toast "Anna restored a previous version"
   (presence notice `versionRestored`). Restore never blocks others; their later writes win
   (LWW).
5. **Undo**: the response's `changeId` → one `UndoStep` "Restore version" in the
   **`slides.serverChange`** domain (`SlidesEndpoint.revertChange` / `reapplyChange`, per-column
   skip rule).
6. The deck title is restored and mirrored to Drive. Linked charts restore their snapshot data
   (not re-fetched).

### 4.5 Copies and downloads

- *Make a copy* from a version (`slides.history.makeCopy {versionId, name, folderUuid?,
  copyComments, copySharing}`): `DeckCopier` on the version model (client; online for file
  re-homing), options as Sheets 10 §5.4 (`SlidesVersionEndpoint.copyExtras` for comments with
  remapped anchors and sharing).
- *Download* from a version: PDF (`slides.history.download {format: pdf}`) rendered by the core
  PDF renderer (10) from the version model.

### 4.6 Named versions

*Name current version* (`slides.history.nameCurrentVersion {name}`) and rename/delete names via
the suite `versions.*` endpoints (not undoable; metadata).

### 4.7 As built (SL-39)

- **Core** (`package:wonky_slides_core/history.dart`): `SlidesSnapshotCodec` writes the §4.1
  format (gzip on `archive`, abbreviated column keys per table, null columns omitted, `$d`
  dates, elements parents first) and is used by the server (capture) and the client (viewing);
  the header's optional `engineHlc`/`syncTablesHash` fields are never written. `DeckDiff` follows
  §4.3 with these choices: the first version is diffed against an empty deck (everything new,
  as Sheets); a changed child whose group did not change keeps its own entry and outlines its
  top-level ancestor (the canvas outlines top-level frames); builds add an `animation` kind;
  table cells, axes, code states and chart links fold into their element. `TextDiff` is a
  word-level LCS (not `DeltaDiff`, which is Write's). `SlidesRestoreChanges` is the restore row
  diff (deletes children first, inserts parents first).
- **Index**: `SlidesSnapshotIndex(itemVersionId, slidesJson, changesJson, authorIds)` with
  `changesJson = {v, slides: {id: [userIds]}, elements, groups, theme, deck, agents, approx}`
  (latest author last; `agents` = authors who edited through MCP/AI in the window, shown as
  "Claude via MCP (Anna)") — no `structure` list. Attribution uses the ops of the capture
  window (§4.1; offline edits belong to the version whose window holds their commit).
  `slidesVersion.changes` returns it (computed on the fly for versions without an index). Op
  payloads are pruned after 30 days (`revlog.pruneOps`); captured versions keep their
  attribution in the index.
- **Viewing**: the shell's history route (`/p/:uuid/history`, `?version=<id>` selects a
  version — added to the shell) with `SlidesVersionRenderer`: navigator (group headers with
  *New*/*Renamed*/*Moved* tags, slide thumbnails with *New*, *↕ Moved* and the author dot,
  ghost rows of deleted slides that open the previous version's slide), the read-only stage
  with 2 px outlines in the author's color, a "+" tag on added objects and dashed ghosts of
  removed ones (*Show removed objects*), and *Changes on this slide* with deck-level rows on
  top (theme, settings, groups). Text changes show their diff **inline** in the list (not on
  hover); clicking a row highlights the object. Below 720 px the navigator is a strip above the
  stage and the list goes below it; below 480 px the bar's actions are icons. Not built:
  *Side by side* (P1), the read-only master view of a theme change and the faint outlines of
  inherited changes.
- **Restore** as §4.4 through `VersionEndpoint.restore` → `SlidesVersionProvider.restore`
  (`SlidesServerWrites.applyRecorded`, record kept 7 days); the shell command records SL-43's
  `SlidesServerChangeEntry` (undo = `slides.revertChange`, redo = `slides.reapplyChange`).
  Collaborators get "Anna restored a previous version" (presence notice, shown by
  `SlidesConflicts`).
- **Copies and downloads**: *Make a copy* runs on the **server**
  (`slidesVersion.makeCopy(itemUuid, versionId, name, folderUuid?, copyComments, copySharing)`
  → `DeckCopies.copy(sourceModel:)` with re-homed images and the caller's quota, comments
  with remapped anchors, sharing) instead of a client `DeckCopier` + `copyExtras` — version
  history is online-only anyway and the server already has the copy pipeline. Editors+ (suite
  07 §5). *Download* is the version's PDF with the user's last-used export options
  (`SlidesClientExport`).
- **Commands** (§7): `slides.history.*` run without an open editor (they act on the shown
  version); `toggleSideBySide` is not registered. ⌥⌘↓/⌥⌘↑ step through the stops: each changed
  slide, then its changed objects top-to-bottom, left-to-right.

---

## 5. Activity

The post-commit hooks of the deck's RevLog ops (at least once per op, cursors in
`rev_hook_state`, [17](../17-revlog-sync.md) part 5 §6) produce:

- `DriveItem.modifiedAt` / `modifiedById` and search text (titles, text, notes, group titles;
  throttled 10 s with a trailing refresh) — as Sheets.
- `ActivityEvent`s aggregated per user and 10-minute window: "Anna edited slides 3–5 in Intro",
  "Bo added the group Demo", "Anna changed the theme to Midnight", "Claude via MCP (Anna) added 6
  slides" — shown in the Drive details panel feed (suite 05 §5).
- No per-edit notifications (P2: change notification rules like Sheets 10 §8).
- As built (SL-39): the `activity` plugin aggregates through `ActivityService.logEdit` with
  counters (`changes`, `slides`, `slidesDeleted`, `themes`) and the new id set `slideIds`
  (distinct slides of the 10-minute event); the shell feed adds a detail line "3 slides ·
  1 slide deleted · theme changed · with Claude" under "Anna edited". Slide numbers and group
  names ("slides 3–5 in Intro") are not shown (the feed has no deck model).

---

## 6. Offline behavior and conflicts

### 6.1 Offline behavior

- Everything in the editor works offline on decks in the device cache (02 §9.1): editing, groups,
  themes, builds, code states, notes, comments (queued), creating decks (02 §9.3), copying and
  pasting between decks on the device (file re-homing queued), PDF export (fonts and images
  cached; images not on the device render as placeholders with a warning in the export dialog).
- Not offline: version history (view/restore), *Update* of linked charts (shows "Connect to update
  this chart"), importing themes/slides from decks not on the device, image by URL, AI.
- Presence, soft locks and hints are absent offline; the header shows *Offline*; the offline
  banner (suite 03 §4) appears.
- Offline edits go into the outbox (*Offline — changes saved on this device*). On reconnect the
  session catches up with the ops it missed, then sends the outbox; the server applies the ops in
  arrival order (field LWW: an offline edit sent late overwrites newer online edits of the same
  column, a deleted row stays deleted, [17](../17-revlog-sync.md) Q1); maintenance (02 §10)
  repairs; the conflict tracker (§6.3) reports overwritten text.

### 6.2 Conflict UX

- **Partial undo** toast (suite): *"Some changes couldn't be undone because they were edited by
  someone else."* with *Details* listing the elements/slides and who changed them (from the
  latest op touching them in the session's recent ops).
- **Moved to the end**: when maintenance moves orphaned slides (group deleted concurrently), the
  editor that wrote them sees "1 slide moved to the end because its group was deleted by Anna" —
  *Show* selects them.
- **Deleted while editing**: "Slide 7 was deleted by Anna — your changes to it were discarded"
  with *Undo isn't possible for you; ask Anna or restore a version* — and the overwritten-text
  review keeps the text.

### 6.3 Overwritten text review (P1)

`SlidesConflicts` (`features/history/local_conflicts.dart`):

- While a body is edited **offline** or with a **forced** claim, the client records
  `{target, myText}` per body in `slides.offlineEdits.<deckId>` (local store). Once the outbox
  has drained after reconnecting (every change acknowledged, the ops before them applied), for
  each recorded body: if the current value differs from `myText` and the deciding write came
  from another user (the latest op touching the body in the session's recent ops, `rev_local_op`),
  it records a `LocalConflict {target, myText, theirText, theirUserId, changeLogId (the deciding
  op's revision), detectedAt}` in
  `slides.conflicts.<deckId>`. Deleted targets record "deleted by Anna".
- Toast: "2 of your text edits were replaced by newer edits from Bo — Review". The review dialog
  (`WonkyDialogSpec`, 04 §13.14) lists each body (slide number, element label, *Yours* vs
  *Current* with a diff) with checkboxes; **Restore mine** writes the selected texts back
  (`slides.conflicts.restoreMine {conflictIds}`, one undo step); *Copy mine* puts the text on the
  clipboard; *Dismiss all*. Conflicts expire after 7 days.
- As built (SL-39): `SlidesConflicts` (`features/history/local_conflicts.dart`) tracks element
  text, table cell text and speaker notes (not code states) written offline or under a forced
  soft lock; the check runs once the outbox drained after reconnecting
  (`LoggedDeckSession.whenSynced`, ≤ 90 s). The winner is the latest op of another user in
  `LoggedDeckSession.recentOps` (30 days) that touched the body (or deleted it). The dialog's
  buttons are *Dismiss all*, *Copy* and *Restore* (short labels so three fit the dialog).
- **Follow-up** ([17](../17-revlog-sync.md) As built 11): feed the review directly from the
  session's outcomes (`LoggedDeckSession.outcomes`: `conflicts` on the `text`/`notes`/`code`
  columns of `offline` or forced ops, `dropped` for deleted targets, 17 part 6 §6) instead of the
  tracked bodies; the outcomes are already stored (`rev_outcome`) and exposed.

### 6.4 Offline collaboration scenarios

Anna (A) and Bo (B), both offline, then both reconnect; "later" = the op that reaches the server
later (arrival order, [17](../17-revlog-sync.md) Q1). Every row is a test case in the
multi-client sync harness ([12 §7.3](12-implementation-plan.md); with RevLog the clients run
against `FakeRevServer`, 17 As built 16).

| # | Scenario | Data-model behavior | Outcome | UX |
|---|----------|--------------------|---------|----|
| 1 | Both move the same element | `x,y` LWW (both wrote both, P4) | Later move wins consistently | — |
| 2 | A moves an element, B recolors it | Different columns | Moved and recolored | — |
| 3 | Both edit the same text box | `text` LWW | Later text wins | Loser: overwritten-text review |
| 4 | A edits the title, B the body of one slide | Different rows | Both | — |
| 5 | A deletes slide S, B edits S | Slide deleted (the sequencer cascades its rows); B's changes to S are dropped | S gone | B: "Slide deleted by Anna" + text review; A's undo revives S incl. B's surviving rows |
| 6 | Both insert a slide after slide 4 | `FractionalIndex.between` may tie; order by `(sortKey, id)` | Both slides, same deterministic order everywhere | — |
| 7 | A moves slide X into group G, B moves X to the end (top level) | `groupId`+`sortKey` written together by both | Later move wins both columns; X is either in G or at the end, never torn | — |
| 8 | A deletes group G with its slides, B adds a new slide to G | A's slides deleted; B's slide's group missing → orphan | B's slide shown at the end; maintenance writes it top-level | B: "moved to the end" toast |
| 9 | A ungroups G, B moves slide Y into G | Group row deleted; Y orphan | Y at the end (repair) | Same toast |
| 10 | A renames group G, B recolors it | Different columns | Both | — |
| 11 | A collapses G | Local view state | No sync, no conflict | — |
| 12 | A moves group G, B moves a slide inside G | G.sortKey vs slide's in-group key | Both: G moves with all slides, B's order inside G kept | — |
| 13 | A applies layout L2 to slide S, B types into S's title | Instance re-pointed (same id) or materialized (same id) | B's text kept in the title (new geometry) | — |
| 14 | Both apply the same built-in theme | Deterministic theme copy ids | One theme copy | — |
| 15 | A applies theme T1 to all, B applies T2 to all | `Deck.themeId` and each slide's `layoutId` LWW; both wrote all slides | Deck ends with the later theme on all slides it touched; slides added meanwhile keep theirs; the other copy is unused | "Remove unused themes" available |
| 16 | A moves a layout placeholder, B moves the instance on one slide | Layout row vs instance frame | B's slide keeps B's frame; others follow A | — |
| 17 | A groups E1+E2, B moves E1 | Grouping keeps child frames numerically (child space = slide space at creation) | E1 moved by B inside the group | — |
| 18 | A deletes element E, B edits E's text | Delete wins (B's change dropped) | E gone | B: text review "deleted by Anna" |
| 19 | A adds a build on E, B deletes E | Build cascades | No build | — |
| 20 | A reorders builds, B adds a build | Different rows / sortKeys | Both, ordered by sortKey | — |
| 21 | A types in table cell (r1,c1), B in (r2,c2) / same cell | Deterministic cell ids | Different cells: both; same cell: LWW per column | Same-cell loser: text review |
| 22 | A inserts a table row, B inserts a column | Separate axis rows | Both | — |
| 23 | A updates a linked chart, B changes its deck style | `ChartLink` row vs element `dataJson` | Both | — |
| 24 | A changes the deck size (scale content), B edits frames offline | B's later frame writes keep pre-scale coordinates | B's edited elements may be misplaced | Page setup warns when collaborators edited in the last 24 h: "Changing the slide size while others are editing offline may misplace their changes" |
| 25 | A edits code state 2, B deletes state 2 | Delete wins (A's change dropped) | State gone | A: text review |
| 26 | A edits notes, B edits notes of the same slide | `Slide.notes` LWW | Later wins | Loser: text review |
| 27 | A undoes a move after B moved the same element | Per-column skip rule (frame set as a unit) | B's position stays | Partial-undo toast |
| 28 | A downgraded to viewer while offline with pending edits | The server rejects A's ops (`forbiddenForRole`) | A's edits rolled back; the deck turns read-only for A | Toast naming the change and the reason; *Save my changes as a copy* is a follow-up ([17](../17-revlog-sync.md) As built 10) |
| 29 | A creates a deck offline | Client UUID; the creation op waits in the outbox; `registerPresentation` queued (02 §9.3) | Appears in Drive for others after A reconnects and shares | — |
| 30 | A comments offline on an element B deletes | Queued create posts on an anchor whose element is gone (the `comments` hook, §3) | Thread orphaned | A sees it under "Orphaned" |

---

## 7. Commands

| Command id | Args | Undoable | Role |
|------------|------|----------|------|
| `slides.presence.jumpTo` | `{sessionId}` | — | Viewer+ |
| `slides.presence.follow` / `unfollow` | `{sessionId}` | — | Viewer+ |
| `slides.presence.followPresenter` | `{sessionId}` | — | Viewer+ |
| `slides.presence.returnToPresenter` (SL-37) | — | — | Viewer+ (follower view, after browsing away) |
| `slides.view.toggleRemoteCursors` / `toggleCommentPins` | — | — | Viewer+ |
| `slides.text.editAnyway` | `{target}` | — | Editor |
| `shell.comments.create` (Slides anchors) | `{anchor?: {slideId, elementId?, point?}, body, mentions, assigneeId?}` | ✓ (`comments`) | Commenter+ |
| `slides.comments.next` / `previous` | — | — | Viewer+ (if visible) |
| `slides.comments.openPanel` | `{scope?: slide\|all}` | — | Viewer+ |
| `slides.comments.show` (SL-38) | `{threadUuid}` | — | Viewer+ (if visible) |
| `slides.history.open` | `{versionId?}` | — | Editor+ |
| `slides.history.nameCurrentVersion` | `{name}` | — | Editor |
| `slides.history.restoreVersion` | `{versionId}` | ✓ (`slides.serverChange`) | Editor |
| `slides.history.makeCopy` | `{versionId?, name, folderUuid?, copyComments, copySharing}` | — (Drive) | Viewer+ (if copying allowed) |
| `slides.history.toggleShowChanges` / `toggleShowRemoved` / `toggleSideBySide` (P1) | — | — | Editor+ |
| `slides.history.nextChange` / `previousChange` | — | — | Editor+ |
| `slides.history.download` | `{format: pdf}` | — | Editor+ |
| `slides.conflicts.review` | — | — | Editor |
| `slides.conflicts.restoreMine` | `{conflictIds}` | ✓ | Editor |

## 8. MCP mapping

| Need | Tool |
|------|------|
| Comments | Suite `comments.*` with Slides anchors `{"slide": 4}` / `{"slide": 4, "element": "<id or name>"}`; results include `slideNumber`, `elementLabel`, `orphaned`. |
| Versions | Suite `versions.list`, `versions.name_current`, `versions.restore` (returns `change_id`), `versions.get(format: "outline")` (titles + text per slide of a version), `format: "diff"` (changed slides/elements vs the previous version with authors). |
| Presence | `ui.get_state` includes collaborators and soft locks; agents appear automatically (§1.1). |

Details in [11](11-mcp-and-ai.md).

## 9. Packages and folders

| Location | Content |
|----------|---------|
| `wonky_slides/lib/features/collab/` | `SlidesPresenceController` (cursor JSON from editor state; maps remote cursors to canvas/navigator), soft-lock manager, hint sender/overlay, follow & follow-presenter controllers, remote pointer layer |
| `wonky_slides/lib/features/comments/` | Anchor provider + panel options, pins layer, docked thread cards, cut/paste re-anchoring |
| `wonky_slides/lib/features/history/` | History route, snapshot loader, diff view, change list, text diff popover, conflicts review |
| `wonky_slides_core/lib/src/snapshot/`, `…/diff/` | Snapshot codec, deck diff, change summaries (pure Dart, client + server) |
| `wonky_server/lib/src/slides/versions/` | `SlidesVersionProvider`, scheduler hooks, restore, copy extras |
| `wonky_server/lib/src/slides/changelog/` | Consumer: drive mirror, activity, orphaning, version state, agent cursors, headless cache invalidation |

## 10. Acceptance criteria

1. Two windows on one deck: B sees A's avatar on A's slide in the navigator and A's selection
   outline within 200 ms; A's typing appears live in B's canvas (hints) and stays after sync
   without flicker.
2. Soft lock: B double-clicking A's text box gets the popover; *Edit anyway* lets both edit; the
   later write wins and the other user gets the review offer; simultaneous entry resolves to the
   earlier claim.
3. Follow mode tracks slide changes and viewport until local interaction; following a presenter
   tracks slides and build steps.
4. A comment on an element follows it through moves, slide reordering and regrouping, moves with
   cut & paste, orphans on deletion and revives on undo.
5. Version history shows auto versions; per-slide badges and element outlines in author colors;
   text diffs on hover; next/previous change navigation; restore is one undo step and reverts
   except for later edits by others.
6. Every scenario of §6.4 passes in the multi-client harness with the stated outcome.

## 11. Additions to 02-data-model and suite specs

| # | Addition |
|---|----------|
| A-09-1 | `PresenceCursor` JSON for Slides (§1.1) and the `editing` claim (§2.1). |
| A-09-2 | Hint messages `text`, `transform`, `structure` on the suite hint channel (Sheets A-10-6). |
| A-09-3 | `CommentAnchorKind.slide` / `.element` (suite 07; 04 A-04-5) with the anchor JSON of §3.1. |
| A-09-4 | Server `SlidesSnapshotIndex(itemVersionId, slidesJson, changesJson, authorIds)` and `ItemVersion.revision`; snapshot format §4.1. |
| A-09-5 | Local-store keys `slides.offlineEdits.<deckId>`, `slides.conflicts.<deckId>` (02 §7). |
| A-09-6 | **Drive/quota**: files referenced only by retained versions are kept (not counted) and garbage-collected after the last reference + 30 days. |
