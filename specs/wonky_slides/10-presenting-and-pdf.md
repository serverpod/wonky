# Slides 10 · Presenting, Presenter View and PDF Export

This spec defines how a deck is **presented** (full screen, navigation, keyboard and clicker
map, laser, pen and highlighter, black/white screen, slide picker with groups, skipped slides,
loop and kiosk mode, rehearsed timings, captions), the **presenter view** in the presenting
window (single-window model, no second window), the **presentation session** that keeps the
audience on other devices or browsers, followers and a **phone remote** in step, presenting
**offline**, and the **exports**: PDF (slides, builds as pages, notes pages, handouts, bookmarks, links, embedded
fonts), PNG, the print preview route, and where rendering runs (client vs. server/MCP).

No PPTX/Keynote/Google Slides import or export and no video (Drive/Slides decisions D12, D13).

Read first: [06-animations-and-transitions.md](06-animations-and-transitions.md) (timeline,
`SlidePlayer`, frames), [07-code-blocks.md](07-code-blocks.md), [08-charts-from-sheets.md](08-charts-from-sheets.md),
[02-data-model.md](02-data-model.md), [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md),
[05-themes-layouts-masters.md](05-themes-layouts-masters.md) (slide numbers, footers, fonts),
suite [03-app-shell-and-navigation.md](../03-app-shell-and-navigation.md) §1 (single window),
[07-collaboration.md](../07-collaboration.md) §1 (presence stream pattern),
[12-offline-and-sync.md](../12-offline-and-sync.md), Write
[07-import-export-print.md](../wonky_write/07-import-export-print.md) §4–§10 (PDF exporter,
print preview, export endpoint patterns reused here).

Priorities: present mode, keyboard/clicker navigation, black/white, slide picker, skipped
slides, presenter view (in this window), the presentation session with the **audience on another
device or browser** (§5.2), PDF slides/builds/notes/handouts and print preview are **P0 (M9)**;
laser/pen/highlighter and loop/kiosk are **P0 (M10)**; rehearse timings, phone remote, followers
and the same-browser fast path **P1** (as in
[04](04-screens-menus-toolbar.md) §3); PNG export **P1**; captions **P2**. Command ids of the
entry points are the ones in 04 §3/§4.

---

## 1. Present mode

### 1.1 Routes

| Route | Screen |
|-------|--------|
| `/slides/p/:uuid/present` (+ `?slide=<slideId>&step=<n>`) | Present mode (audience rendering in this window) |
| `/slides/p/:uuid/present?view=presenter&session=<id>` | Presenter view in this window (§5) |
| `/slides/p/:uuid/present?view=audience&session=<id>` | Audience view on another device or browser (opened by the user from the link/QR or the *Show audience view here* banner, §5.2) |
| `/slides/p/:uuid/remote?session=<id>&key=<pairingKey>` | Phone remote (P1, §6.4) |
| `/slides/p/:uuid/print` (+ `?layout=…`) | Print / PDF preview (§12) |

Present routes require role ≥ viewer. Viewers and commenters can present (Google Slides
behavior); the editor's own state (selection, panels) is restored when presenting ends.

### 1.2 Starting

| Command | Shortcut | Behavior |
|---------|----------|----------|
| `slides.present.fromCurrent` | `Mod+Enter` (in text/code edit mode `Mod+Enter` is contextual and leaves edit mode first, suite 08 §1.2); desktop (deferred) also `Shift+F5` | Presents from the current slide (first non-skipped slide at or after it). |
| `slides.present.fromStart` | `Mod+Shift+Enter`; desktop (deferred) also `F5` | From the first non-skipped slide. |
| `slides.present.fromSlide {slideId, step?}` | — | From a given slide (navigator/group context menu "Present from this group"). |
| `slides.present.presenterView` | `Mod+Alt+Enter` | Presenter view (§5). |
| `slides.present.rehearse` (P1) | — | Rehearse timings (§10). |

The title row's **Present** split button (04 §3) offers: *Present from current slide*,
*From beginning*, *Presenter view*, *Rehearse* (P1), *Use phone as remote* (P1), *Presenting
settings…*. The default click presents from the current slide, or opens the presenter view when
the user preference *Start with presenter view* is on (§3).

**Pre-flight** (≤ 300 ms, skipped when cached): fonts of the deck loaded, images of the first
four slides decoded, timelines of the first two slides compiled, the 3D chart GPU backend started
if the first slides need it. A blocking spinner appears only if it takes longer than 300 ms.

### 1.3 Full screen

- **Web**: `document.documentElement.requestFullscreen({navigationUI: "hide"})` within the
  user gesture that started presenting (package `web`, behind a conditional import). If it is
  refused (iframe, policy, Safari restrictions), present mode runs **full window** (all chrome
  hidden) with a hint bar for 4 s: "Press F11 (⌃⌘F on Mac) for full screen" and a *Full screen*
  button.
- **Desktop** (deferred, suite 01 A13): native full screen via `window_manager` would be a new
  justified dependency; in v2 desktop builds present full window.
- Leaving full screen by the browser/OS (Esc handled by the browser, ⌃⌘F, F11) **ends** present
  mode and returns to the editor at the slide/step that was shown (Google Slides behavior);
  `presentJson.keepPresentingOutsideFullscreen` (default false) keeps present mode in a window.
- The cursor hides after 2 s without movement; the present toolbar (§4.1) shows on movement near
  the bottom-left.

### 1.4 Scaling and letterboxing

The slide is scaled to fit the screen (contain), centered; the remaining area is the
**letterbox color** (`presentJson.letterboxColor`, default black). Rendering uses device pixels
(`devicePixelRatio`) so text stays crisp; images are decoded at the presented size (not the
editor's thumbnail size).

### 1.5 End of the presentation

After the last step of the last slide the next advance shows an **end screen** (black, "End of
presentation — click to exit", muted text) per `presentJson.endBehavior: endScreen | exit |
loop` (default `endScreen`); the next advance exits. Kiosk/loop modes override (§9).

### 1.6 Mobile presenter mode (T-9)

In the mobile layout (suite 02 §6.1) present mode (`view` absent, not kiosk) takes the whole
window as a column: the **presenter bar** (`WonkyPresenterBar`, 52 px, suite 02 §6.1) on top —
close runs `slides.present.end` (back to the read-only deck at the shown slide), back and forward
run `slides.present.previous` / `slides.present.next` (back is disabled at the first step) — and
the stage below it, letterboxed in the app theme's background (light or dark) instead of
`letterboxColor`. Taps and swipes on the stage navigate as in present mode; the bottom-left
present toolbar, the full-screen hint and the cursor hiding are not used. The presenter view,
audience and follower views keep their own layouts.

---

## 2. Navigation

### 2.1 Keyboard, clicker and mouse map (keymap scope `present`, new scope in suite 08 §1.2)

| Action | Keys | Mouse / touch |
|--------|------|---------------|
| Next (step, then slide) | `→`, `↓`, `Space`, `Enter`, `PageDown`, `N` | Click, wheel down (`presentJson.wheelAdvance`), tap right two-thirds, swipe left |
| Previous | `←`, `↑`, `Backspace`, `PageUp`, `P`, `Shift+Space` | Wheel up, tap left third, swipe right |
| Next slide (skip remaining builds) | `Shift+→`, `]` | — |
| Previous slide (to its start) | `Shift+←`, `[` | — |
| First / last slide | `Home` / `End` | — |
| Go to slide *n* | digits then `Enter` (an overlay shows "Go to 12"; `Esc` cancels) | — |
| Slide picker | `G`, `-` | Toolbar |
| Black / white screen | `B` or `.` / `W` or `,` (again or any navigation key to return) | Toolbar |
| Laser pointer | `L` (toggle); hold `Mod` while moving the mouse = temporary laser | Long-press (touch) |
| Pen / highlighter / eraser | `D` / `H` / `E` (toggle; `Esc` returns to the arrow) | Toolbar |
| Clear ink on this slide | `C` | Toolbar |
| Undo last ink stroke | `Mod+Z` | — |
| Full screen toggle | `F` | — |
| Captions (P2) | `Shift+C` | — |
| Help overlay (all shortcuts) | `?`, `/` | — |
| End presentation | `Esc` (when not in a tool, picker, number entry or overlay) | Toolbar |

- **Clickers** send `PageDown`/`PageUp` (next/previous), `B`/`.` (black), and `F5`/`Shift+F5`/
  `Esc` (start/stop). In present mode `F5` and `Shift+F5` are captured (`preventDefault`) and
  mean "resume from the current slide" (no browser reload); outside present mode the web app
  never binds `F5` (browser-reserved).
- **During a running step**, *Next* finishes it immediately (jumps to its end) — a second *Next*
  advances (06 §6). `presentJson.advanceDuringBuild: finish | skip` (skip = finish and start the
  next step at once).
- *Previous* never plays animations backwards: it jumps to the previous step's end state; across
  slides it plays the reversed transition and shows the previous slide's final frame (06 §6).
- Key repeat is ignored for navigation (holding → doesn't race through slides); a burst of
  inputs within 120 ms is collapsed into one.
- Right-click (or two-finger tap) opens the present **context menu**: Next, Previous, Go to slide
  ▸ (grouped list), Black screen, White screen, Laser, Pen, Highlighter, Eraser, Clear ink,
  Captions (P2), Help, End presentation.

### 2.2 Order and skipped slides

The presentation order is the deck order. **Skipped slides** (`Slide.skipped`) and slides of a
**skipped group** (`SlideGroup.skipped`) are left out of next/previous; they remain reachable via
the slide picker and *Go to slide* (number = position in the full deck, as shown in the
navigator). After showing a skipped slide, *Next* continues with the following non-skipped slide.
The presenter view has *Show skipped slides* (temporarily include them in the sequence).

---

## 3. Presentation settings

Two levels, both on the **Presenting** page of Slides settings (`shell.settings.openApp
{section: presenting}`, 04 §3): *Your presenter preferences* (per user, below) and — when opened
from a deck by an editor — *This presentation*, which edits `Deck.presentJson` (synced;
`slides.deck.setPresentSettings`, undoable):

```jsonc
{
  "v": 1,
  "mode": "normal",                    // normal | loop | kiosk (§9)
  "useRehearsedTimings": false,        // auto-advance with Slide.timingsJson (§10)
  "advanceDuringBuild": "finish",      // finish | skip
  "endBehavior": "endScreen",          // endScreen | exit | loop
  "wheelAdvance": true,
  "letterboxColor": "#000000",
  "reduceMotion": false,               // reduce motion while presenting (06 §13)
  "keepPresentingOutsideFullscreen": false,
  "kiosk": { "restartAfterIdleSec": 120, "exitGesture": "holdEsc" },   // holdEsc (2 s) | esc
  "laserColor": "red",                 // red | green | blue | amber
  "showCaptionsByDefault": false       // P2
}
```

Per-user presenter preferences (Slides app settings, Drive/suite settings split D4; stored in
`UserPreferences.slidesPresenter`): presenter view layout preset, notes font size, timer mode
(elapsed / countdown with target minutes), pen colors and widths last used, *Start with presenter view*
(default off), *Show skipped slides in presenter view*.

---

## 4. In-presentation tools

### 4.1 Present toolbar

Hover the bottom-left area (or press any modifier) → a translucent pill (shad `card` at 85 %,
blur behind) with: ◀ · "12 / 40" (click = slide picker) · ▶ · laser · pen · highlighter ·
eraser · clear · black/white · ⋮ (Help, Captions P2, Presenter view, Full screen) · *End*. Auto-
hides after 2 s; never captured by PDF/screenshots of an audience view (it is present only
in the view with the mouse).

### 4.2 Laser pointer

A glowing dot (12 su core, 40 su glow) in `laserColor` follows the pointer with a short fading
trail (last 300 ms). Shown in the audience rendering (and mirrored from the presenter view: the
presenter moves the pointer over the *current slide* preview, §5.1). Followers and remotes receive
laser positions (throttled to 30 Hz, interpolated) through the presentation session (§6).

### 4.3 Pen, highlighter, eraser (ephemeral ink)

- **Pen**: 4 su (thin) / 8 su (medium) / 14 su (thick) strokes in 6 colors (red, blue, green,
  amber, white, black); **highlighter**: 28 su, 40 % opacity, multiply-like (drawn under text by
  painting with `BlendMode.multiply` on light slides and `screen` on dark slides);
  **eraser**: removes whole strokes it touches.
- Strokes are smoothed (one-euro filter on input, Catmull-Rom → cubic Béziers, pressure from
  stylus when available) and stored in slide units, per slide, **in memory only** for the
  presentation (navigating away and back keeps them; ending the presentation discards them).
  P2: *Keep ink as a drawing* (`slides.present.keepInk`) converts strokes into a freehand element
  on each slide (undoable) when ending.
- `Mod+Z` removes the last stroke of the current slide (local stack, not the document undo).
- Ink is shown in the audience rendering and sent to followers as stroke deltas (§6).

### 4.4 Black and white screen

`B`/`.` and `W`/`,` cover the audience rendering with black/white (200 ms fade unless reduced
motion); the presenter view shows "Audience: black screen" and a *Show slide* button. Any
navigation returns to the slide first (without advancing).

### 4.5 Slide picker

`G` opens a full-screen overlay (audience views show it too, unless the presenter view is
open — then only the presenter view shows it, the audience keeps the current slide):
- Grid of thumbnails (edit-frame thumbnails, 06 §9.6), 4–8 columns by width, with **group
  headers** (title, color dot, slide count; collapsed state from the navigator's local view
  state, toggled here without affecting it); skipped slides dimmed with `eye-off` and still
  selectable; the current slide outlined.
- Type to filter by slide title or number; arrows/Home/End/PageUp/PageDown move; `Enter` goes
  to the slide (its transition plays forward), `Esc` closes.

### 4.6 Help overlay

`?` shows the shortcut table (generated from the `present` keymap scope, includes user overrides).

---

## 5. Presenter view

### 5.1 Layout

```
┌ Presenter view — Q3 Review ──────────────────────────── [Other device…] [End] ┐
│ ┌──────────────────────────────────┐  ┌───────────────────────┐  00:12:41 ⏸ ⟲ │
│ │                                  │  │ Next: build 3 of 5    │  14:32 (clock)│
│ │        CURRENT (live, step 2/5)  │  │  (next frame preview) │  Slide 12 / 40│
│ │                                  │  └───────────────────────┘  ▮▮▮▮▯ ahead  │
│ │                                  │  Notes                  A− A+         │
│ └──────────────────────────────────┘  ┌──────────────────────────────────┐ │
│  ◀  ▶   🔴 laser  ✎ pen  ▬ highlighter  ⌫ clear  ■ black  □ white          │ │
│ ┌─ strip: ▭ 10  ▭ 11  [▭ 12]  ▭ 13  ▭ 14 … (groups as separators) ──────┐ │ │
└──────────────────────────────────────────────────────────────────────────┘
```

- **Current**: the live slide as the audience sees it (same `SlidePlayer` state), with step
  indicator "Step 2 of 5". Pointer tools work on it and are mirrored to the audience.
- **Next**: `endOfStep(current + 1)` of the current slide while steps remain ("Next: build 3 of
  5 — Code: type state 3 (≈ 4 s)" from the build summary), else the next slide's initial frame
  ("Next slide: Pricing"); "End of presentation" at the end.
- **Notes**: the slide's speaker notes (rich text, deck theme body font at the user's notes
  size, 12–48 pt, `A−`/`A+` or `Mod+=`/`Mod+-`), scrollable (`Mod+↑/↓` or the mouse wheel over
  the notes), optional auto-scroll per step (P2: notes markers `[click]` advance the scroll).
- **Timers**: elapsed (starts with the first advance or *Start*; pause ⏸ / reset ⟲, `T` toggles
  pause), wall clock, slide number; **pacing** (when rehearsed timings exist): "2:10 ahead" /
  "1:05 behind" vs. the cumulative rehearsed time at this step, with a 5-segment bar.
- **Strip**: horizontally scrolling thumbnails around the current slide, group separators with
  titles, skipped slides dimmed; click = go to (audience follows).
- **Audience controls**: black/white, *Freeze audience* (P1: the audience keeps the current frame
  while the presenter browses ahead in the strip without changing it — Keynote "rehearse"
  style), *Show skipped slides*.
- **Layout presets** (user preference): *Standard* (above), *Notes focus* (notes take 60 %),
  *Next focus* (current and next side by side, equal size). P2: free arrangement.
- Light/dark: the presenter view follows the app theme (it is chrome), slides render as authored.
- All presenter view controls are commands (§14) with the `present` keymap scope plus: `T`
  timer pause, `R` reset timer, `Mod+=`/`Mod+-` notes size.

### 5.2 Screens and devices — one window (decided)

**Decided (v2 review, Q5/Q29/Q30):** Wonky Slides opens **no second window** — suite 03 §1 has
no presenting exception in v2, on the web or on desktop (v2 is web only, suite 01 A13).
Presenting offers three modes that share one state model, the **presentation session** (§6):

| Mode | Where it shows | How |
|------|----------------|-----|
| **Present** | This window, full screen (§1) | Laptop + projector: the user mirrors the displays, or moves the browser window to the projector before presenting |
| **Presenter view** | This window (§5.1): current and next slide, notes, timers, strip | `slides.present.presenterView`. Creates a presentation session; the audience doesn't see this window |
| **Audience on another device or browser** | Any other device, or another browser window the user opens **by hand** (e.g. on the projector machine, or a window they drag to the external display) | Joins the session as `audience` (§6.3) and renders full screen; the presenter view drives it (~50–300 ms lag over the server) |

- *Open on another device…* (`slides.present.openOnAnotherDevice`, header of the presenter view
  and the Present menu) shows the audience link and a QR code
  (`/slides/p/<uuid>/present?view=audience&session=<id>`) plus *Copy link*. The link is
  user-bound: only the presenter's own account (or followers per §6.3) can join.
- When the same user opens the deck anywhere else while a session is live, a banner offers
  *Show audience view here* (`slides.present.joinAsAudience`) / *Use as remote* (§6.3). Opening
  a window is always the user's own navigation, never the app's.
- With an extended display (`window.screen.isExtended`, Chromium) *Presenter view* shows a
  one-time hint: "To show slides on the projector, open this presentation in a window there and
  choose *Show audience view here* — or use *Open on another device…*."
- **Same-browser fast path (P1):** when presenter and audience run in one browser profile, the
  session messages of §6.2 additionally travel over `BroadcastChannel('wonky-present-<sessionId>')`
  (no server round trip, ≤ 1 frame lag) and the pair keeps running through connection drops after
  joining. The server session stays the authority for joining.
- Single-screen presenting without presenter view creates no session (no network needed).

### 5.3 Possible later addition: a presenting-only second window (not in v2)

Recorded for a later iteration, not built: *Presenter view* opening the audience view in one
extra window of its own origin — web via the Window Management API (`getScreenDetails()` +
fullscreen companion window, Chromium; a popup the user drags elsewhere), desktop via a second OS
window (Flutter's multi-window API, fallback `desktop_multi_window`; this was the desktop
multi-window spike, Q30). It would be the only exception to suite 03 §1 (opened only by an
explicit user action, closed when presenting ends, never navigating elsewhere) and would reuse
the §6.2 messages over `BroadcastChannel`/in-process, so the state model above doesn't change.

## 6. Presentation session (followers, other devices, phone remote)

### 6.1 Endpoint

```
PresentationEndpoint.join(String deckUuid, PresentationJoin join, Stream<PresentationUpdate> updates)
  → Stream<PresentationEvent>
```

- Ephemeral, like presence (suite 07 §1): an in-memory roster per session on the serving
  instance, relayed on the bus channel `present:<sessionId>` (Redis when multi-instance).
- `PresentationJoin {sessionId?, role: presenter | audience | remote | follower, pairingKey?,
  deviceLabel}`. The first presenter join creates the session (`sessionId` = random 128-bit,
  base-62). One presenter per session; a second presenter join takes over after confirmation
  ("Take over the presentation from your other window?").
- Sessions end 30 s after the presenter's stream closes (grace for reconnects) or on
  `PresentationUpdate.end`.

### 6.2 Messages

| Message | Direction | Content |
|---------|-----------|---------|
| `state` | presenter → all | `{revision, slideId, step, stepStartedAt (server ms), blank: none\|black\|white, picker: bool, timer {running, startedAt, elapsedMs}, deckRevision}` — full state, sent on every change and every 10 s |
| `laser` | presenter → all | `{x, y}` in su or `null` (hidden); ≤ 30 Hz |
| `ink` | presenter → all | `{slideId, op: add\|remove\|clear, stroke? {id, tool, color, width, points (su, quantized 0.5)}}` |
| `command` | remote → presenter | `next \| previous \| nextSlide \| previousSlide \| goTo {slideId, step} \| blank {color} \| timer {action}` — the presenter applies it and broadcasts `state` (the presenter is the only authority) |
| `camera` (P1) | presenter → all | Live 3D chart camera while orbiting in present mode (08 §10.5) |
| `end` | presenter → all | Session over |

Followers render locally with their own `SlidePlayer`: on `state` they seek to `(slideId, step,
now − stepStartedAt)` so animations stay roughly in sync (clock offset estimated from the
endpoint's server timestamps; ±50 ms). The deck content itself comes from normal sync; if the
follower's deck revision is older, it waits for sync (spinner "Catching up…").

### 6.3 Who may join

| Role | Who | How |
|------|-----|-----|
| `audience` (P0) | The presenter's own account on any device or browser | Presenter view › *Open on another device…* shows a link + QR (`/slides/p/<uuid>/present?view=audience&session=<id>`); also offered automatically: when the same user opens the deck elsewhere while a session is live, a banner "You're presenting on MacBook — *Show audience view here* / *Use as remote*" |
| `remote` | The presenter's own account, or anyone with a **pairing key** | §6.4 |
| `follower` (P1) | Users with ≥ viewer access to the deck | "Follow along" link the presenter shares (`?view=follow&session=<id>`) or the header's *Follow Anna's presentation* (04 §3; follow UI in [09](09-collaboration-history.md) §1.6 — this spec owns the protocol); followers can't control; they see laser and ink; they may browse away and *Return to presenter*. P2: anonymous followers for public decks. |

### 6.4 Phone remote (P1)

- Presenter view › *Use your phone as a remote* shows a QR code and a 6-digit code; the URL
  carries `session` and a **pairing key** (random, single use, valid 10 min). Scanning opens
  `/slides/p/<uuid>/remote` in the phone's browser (the Slides web app, responsive), which asks
  the user to sign in if needed: the presenter's own account pairs without the key; another
  account needs the key **and** ≥ viewer on the deck.
- Remote UI (360 px wide): top bar (elapsed time, slide n / N, connection dot), current slide
  thumbnail with the step, next preview, notes (scrollable, font size), and two large buttons
  **Previous** / **Next** (full width bottom, 96 px tall); swipe left/right on the slide area;
  long-press on the slide thumbnail = **laser** (touch position mapped to su); black screen
  button; vibration feedback on each advance (`navigator.vibrate(10)`); keeps the screen awake
  (Screen Wake Lock API).
- Latency target: command → audience frame ≤ 150 ms p50, ≤ 400 ms p95 on the same Wi-Fi.
- If the connection drops, the remote shows "Reconnecting…" and disables buttons; the presenter
  is unaffected.

### 6.5 Security

Session ids and pairing keys are unguessable and never logged; joining checks the deck ACL on
every join; remote commands from a user who loses access are rejected; sessions carry no deck
content (only positions and ink). Rate limit: 20 commands/s per remote.

### 6.6 As built (SL-19)

- **Endpoint** `PresentationEndpoint` (`client.presentation`): `join(deckUuid, PresentationJoin,
  Stream<PresentationUpdate>) → Stream<PresentationEvent>` and `findSession(deckUuid) →
  PresentationSessionInfo?` (the caller's live presenter session, for the *Show audience view
  here* banner). Server `wonky_server/lib/src/slides/present/`.
- **Models** (not tables): `PresentationRole` (presenter, audience, remote, follower),
  `PresentationJoin {sessionId?, role, pairingKey?, deviceLabel, takeOver?}`,
  `PresentationState {revision, slideId?, step, stepElapsedMs, blank, picker, endScreen,
  timerRunning, timerElapsedMs, deckRevision?}`, sealed `PresentationUpdate` (`…StateUpdate`,
  `…LaserUpdate`, `…InkUpdate {slideId, op, strokeId?, strokeJson?}`, `…CommandUpdate {command,
  argsJson?}`, `…EndUpdate`) and sealed `PresentationEvent {serverTimeMs}` (`…Welcome`,
  `…StateEvent`, `…LaserEvent`, `…InkEvent`, `…CommandEvent`, `…RosterEvent`,
  `…PresenterEvent {connected}`, `…EndedEvent {reason}`), `PresentationParticipant`,
  `PresentationSessionInfo`, server-only `PresentationBusMessage`.
- **Deviation from §6.2:** elapsed times are relative to the moment the state was sent and every
  event carries the server time (`serverTimeMs`); followers estimate the clock offset from the
  smallest `local − server` of recent events (`ClockOffset`) and derive step/timer times locally.
  Instead of `stepStartedAt` in server time.
- **Protocol on the bus** (`present:<sessionId>`, flushed to other instances at once): `hello` /
  `here` / `meta` (members answer while the presenter reconnects) / `joined` (roster of admitted
  members only) / `who` (presenter rejoin probe) / `takeover` / `away` (presenter stream closed;
  members end after the 30 s grace) / `bye` / `state` / `laser` / `ink` / `command` / `end`;
  discovery on `present-deck:<deckUuid>` (`find` → `found`).
- **Roles:** `audience` and `remote` need the presenter's own account (a `remote` of
  another account with a pairing key since SL-41, §6.7); `follower` needs ≥ viewer; every join checks the deck ACL, commands re-check it
  every 5 s. Audience devices may send commands too (a clicker plugged into the projector
  machine); followers can't. A presenter join with the id of a live session ends with
  `presenterActive` until it is repeated with `takeOver` ("Take over the presentation from
  your other window?"); the old presenter gets `takenOver`. End reasons: `ended`, `expired`,
  `takenOver`, `presenterActive`, `notFound`, `noAccess`.
- **Client:** route `/slides/p/:uuid/present` with `view=presenter|audience`, `slide`, `step`,
  `session`, `share=1` (the presenter view opens *Open on another device…* once connected —
  `slides.present.openOnAnotherDevice` from the editor). Present mode creates no session; the
  presenter view publishes its full state on every change and every 10 s and resends ink after
  rejoining; it keeps presenting offline ("Offline — other devices can't join") and joins once
  online. The audience view shows a start card (full screen needs a click on that device),
  waits for unsynced slides ("Catching up…") and returns to the editor when the presentation
  ends. Keys: the `present` keymap scope of §2.1 (`?` is handled by the screen next to `/`;
  digits + `Enter` and `Esc` precedence too).

### 6.7 As built (SL-41, partial — on hold)

- **Pairing (server, built):** the presenter sends `PresentationPairingUpdate` and gets a
  `PresentationPairingEvent {pairingKey (128-bit base-62), code (6 digits), expiresAtMs}`;
  keys are single use and valid 10 min, a new request revokes the unused ones (`revoke: true`
  only revokes). A `remote` join of another account carries the key in its bus `hello`; the
  presenter's connection answers `here` with `admitted` and remembers the account, so the
  remote reconnects without a key (also after the presenter rejoined: members' `here` rebuild
  it). Refusals end the join with `noAccess` (no key) or `pairingExpired`. A typed code
  resolves through `presentation.resolvePairingCode(code) → PresentationPairingTarget
  {deckUuid, sessionId, pairingKey}?` (bus `present-code:<code>`, ≥ viewer, 10 tries a
  minute per user). Deviation from §6.4: codes are looked up on the bus, not stored.
- **Same-browser channel (client core, built, not wired):** `PresentFastPath` over
  `BroadcastChannel('wonky-present-<sessionId>')` carries `state`/`laser`/`ink`/`end` from the
  presenter and `command`s from members as JSON with local times (mapped to server time with
  the link's `ClockOffset`), plus 2 s pings for liveness.
- Not built yet: the remote UI, rehearse, the fast-path wiring and *Freeze audience* (TODO).

---

## 7. Presenting offline

- A deck is presentable offline once it is in the local replica (offline-first sync, 02/09):
  slides, notes, builds, code states, chart snapshots, themes. Fonts are bundled. Images use
  the local blob cache; the pre-flight (§1.2) checks that all images of the deck are cached and
  otherwise shows "3 images aren't available offline" (*Present anyway* shows placeholders).
- *File › Make available offline* (suite) pins the deck and prefetches all its images.
- Present mode and the presenter view in this window work offline. Audience devices or
  browsers, the phone remote and followers need the server to join ("Offline — other devices
  can't join"); with the P1 same-browser fast path (§5.2) a joined pair keeps running through
  connection drops.
- Linked charts render from snapshots; update checks are skipped (08 §16).

---

## 8. Rendering in present mode

- The audience view is a `SlideStage` (06 §12) at screen size driven by `SlidePlayer`, with the
  prefetching and performance budgets of 06 §14 (60 fps at 1080p).
- Text is rendered at device resolution; images are decoded for the presented size (cached per
  size); the 3D chart GPU backend is used when available (08 §10).
- No editor chrome, selection, comments, presence cursors or build badges are drawn.
- Presence: other participants see "Anna is presenting" on the deck (presence state
  `presenting`), not her cursor.

---

### 8.1 As built (SL-29): builds and transitions while presenting

- `PresentController` owns a `SlidePlayer` (06 §12.4) and routes every navigation through it:
  the next step on the slide plays; other steps on it are jumps; another slide plays its
  transition and then step 0 (forward), or — *Previous*, *Previous slide* — the left slide's
  transition reversed when its `reverseOnBack` (else the target's transition forward) and the
  target settled. Jumps (picker, *Go to*, first/last, loop restart) play the target's transition
  forward. `stepRunning` is the player's: *Next* during a transition or build finishes it
  (`advanceDuringBuild: skip` also starts the next step); the 120 ms burst filter is unchanged.
- `PresentController.playerView` / `frame` / `animating`; the stage (`PresentStage`) draws the
  view through `PlayerStage` and ticks (`MotionTicker`) only while something runs; it calls
  `animationFrame()` per tick for the frame budget (06 §14). The presenter view's current slide
  is the same live view; *Next* stays the settled `endOfStep`.
- Timelines compile with the stage's scenes (`scenesOf`: exact text part boxes) and chart shapes
  (`SlideChartMotion.shapes`). Plans are cached per (slides, steps, direction, revisions,
  reduced motion) and prefetched for the next slide (`upcomingTransition`, `prefetch()` after
  every navigation); once the slide settles, the stage rasterizes the next transition's
  snapshots (and uploads them as GPU textures for 3D types).
- Audience devices follow with the same animation from the presenter's elapsed time
  (`applyState` plays from `stepElapsedMs`).
- Auto-advance (06 §4.4): after the last step settles + `advance.afterMs` when `advance.mode` is
  `auto`; with `useRehearsedTimings` each step after its rehearsed time (`Slide.timingsJson
  .stepsMs`). It waits while the screen is blanked or the picker is open.

## 9. Loop and kiosk (self-running) modes

| Mode | Behavior |
|------|----------|
| `normal` | As above. |
| `loop` | After the last slide, continue with the first (transition of the first slide). Manual navigation works. `Esc` exits. |
| `kiosk` | Self-running: every slide advances automatically after its steps (`onClick` steps become `afterPrevious` with the slide's `advance.buildDelayMs`, or the rehearsed step times with `useRehearsedTimings`); slides without timing advance after 5 s; loops; keyboard/mouse navigation disabled except *Next/Previous* when `kiosk.allowNavigation` (P1); restarts at slide 1 after `restartAfterIdleSec` without input when navigation is allowed; exit with **hold Esc for 2 s** (`exitGesture: holdEsc`, progress ring shown) or plain `Esc`. The cursor stays hidden. |

Kiosk can be started from the *This presentation* settings or with `?kiosk=1` on the present route (for
info screens; still requires sign-in and access).

---

**As built (SL-29).** `?kiosk=1` (route parameter → `PresentScreen.kiosk`) or `presentJson.mode:
kiosk` runs the deck self-running: each click step starts `advance.buildDelayMs` (default 1 s)
after the previous step settles (rehearsed step times when the slide has them), a slide's last
step stays `advance.afterMs` (when `auto`) or 5 s, then the next slide's transition plays; the
deck loops. Keys, clicks, the wheel, the toolbar and the context menu are off; `Esc` held for
2 s (progress ring, *Keep holding Esc to exit*; `present/tools/kiosk_exit.dart`) or pressed once
(`exitGesture: esc`) ends it; the cursor stays hidden. Not built: `kiosk.allowNavigation` and
the idle restart (P1, they need navigation). A 50 ms timer checks the auto-advance time
(`PresentController.autoTick`).

## 10. Rehearse timings

`slides.present.rehearse`: present mode in this window (presenter view when *Start with presenter
view* is on, else full screen with a timing HUD at the top-left: current step time, slide time,
total). Each advance records the
time spent on the step. At the end (or `Esc`): dialog "Total time 18:42 (40 slides). Keep the
new timings?" — *Keep* writes `Slide.timingsJson` for every presented slide (one undo step
"Record timings"), *Discard*. Partial rehearsals keep timings only for slides that were
completed.

```jsonc
// Slide.timingsJson
{ "v": 1, "stepsMs": [4200, 15800, 9000], "totalMs": 29000, "rehearsedAt": "2026-10-14T10:12:00Z",
  "by": "<userUuid>" }
```

Used by: the presenter view pacing indicator (§5.1), kiosk/`useRehearsedTimings` auto-advance,
the navigator's optional duration badges (View › *Show timings*, P1), and MCP `slides.get_deck`
(`rehearsed_ms`). *Slide › Clear timings* removes them (undoable).

---

## 11. PDF export

### 11.1 Options (`SlidesPdfOptions`; dialog, MCP and last-used defaults per user)

| Option | Values | Default |
|--------|--------|---------|
| `layout` | `slides` \| `notes` \| `handouts` | `slides` |
| `handoutsPerPage` | 1, 2, 3, 4, 6, 9 | 6 |
| `handoutOrder` | `horizontal` \| `vertical` | `horizontal` |
| `includeBuilds` | bool — "Print each stage of builds" (one page per step, 06 §9.6) | false |
| `includeSkipped` | bool | false |
| `range` | `all` \| `current` \| `selection` \| `"1-3,7"` (deck positions) \| `{groupIds: [...]}` | `all` |
| `pageSize` | `slide` (page = slide aspect) \| `letter` \| `a4` \| `legal` \| `a3` \| `tabloid` | `slide` for `slides`; `letter`/`a4` by locale for notes/handouts |
| `orientation` | `auto` \| `portrait` \| `landscape` | `auto` (slides: landscape for wide decks; notes: portrait; handouts: portrait except 2-up landscape option) |
| `margins` | `none` \| `narrow` (0.25 in) \| `normal` (0.5 in) | `none` for `slides`/`slide` size, else `normal` |
| `frameSlides` | bool — thin border around each slide image | false (`slides`), true (handouts) |
| `background` | `include` \| `omit` ("Ink saver": slide backgrounds and background images omitted, P1) | `include` |
| `headerFooter` | `{date: bool, title: bool, pageNumbers: bool}` (notes/handouts pages) | all true |
| `slideNumbers` | bool — numbers under handout slides | true |
| `bookmarks` | bool — PDF outline: groups → slides | true |
| `links` | bool — clickable links | true |
| `quality` | `high` (images up to 2× the printed size) \| `compact` (1×, JPEG 80 %) | `high` |
| `finalAnimationState` (P1) | bool — use `finalFrame` instead of the print frame | false |
| `fileName` | string (sanitized, ≤ 120 chars) | deck title |

Comments are not exported (P2: comments as end notes). There is no dark variant: slides print
as authored.

**As built (SL-33).** `includeBuilds` (*Print each build stage*) and `finalAnimationState`
(*Show final animation state*) are in the print preview's settings column (feature
`printBuilds`); the final-state box is hidden while build stages are printed.

### 11.2 Page layouts

- **Slides**: one slide (or one step) per page. Page size `slide`: `Deck.width / 2 ×
  Deck.height / 2` pt (02 §2.2; 16:9 1920 × 1080 su → 960 × 540 pt = 13.33 × 7.5 in, like
  PowerPoint's widescreen page; capped at 14,400 pt per side). With paper sizes the slide is
  scaled to fit inside the margins and centered.
- **Notes pages**: portrait; slide image at the top (80 % of the content width, framed), speaker
  notes below as rich text (deck theme body font 12 pt, bullets, bold/italic/links preserved);
  notes overflowing a page continue on a following page headed "Notes (continued) — Slide 12";
  header (deck title, date) and footer (page n of m) per `headerFooter`.
- **Handouts**: grids — 1 (slide with ruled note lines below), 2 (stacked), 3 (slides left,
  ruled lines right — PowerPoint style), 4 (2 × 2), 6 (2 × 3), 9 (3 × 3); order horizontal or
  vertical; slide numbers below each slide; header/footer.
- With `includeBuilds`, notes pages and handouts use the final step of each slide (builds as
  pages only applies to `slides`).
- Builds as pages (SL-33): a slide prints one page per step whose settled frame
  (`endOfStep(i)`) differs from the previous step's — the empty automatic step 0 prints the
  slide before any click; a click whose effects leave nothing changed (a transient pulse) adds
  no page. *Page count = step count* means the number of distinct steps.
- Groups: with `range: {groupIds}` only those groups' slides; with `bookmarks` the PDF outline
  has one top-level entry per group (group title) with its slides as children (slide title, else
  "Slide 7"); ungrouped slides are top-level entries. With builds as pages, a slide's bookmark
  points to its first page.

### 11.3 Rendering pipeline (`wonky_slides_core/lib/src/export/pdf/`)

`SlidesPdfRenderer.render(DeckModel deck, SlidesPdfOptions o, SlidesExportResources r) →
SlidesPdfResult {bytes, pageCount, warnings}` (contract in `package:wonky_slides_core/interfaces.dart`,
12 §5.7; `Slides…` names because Write exports `PdfExportOptions`) — pure Dart, low-level `pdf` API (`PdfDocument`,
`PdfGraphics`) like Write's exporter (Write 07 §5.2):

1. Resolve the page list: slides in range (minus skipped unless included) → per slide the frames
   to print (print frame or one per step, 06 §9.6) → page layout boxes.
2. For each frame, `SlidePdfPainter` draws the slide's **`SlideScene`** (the renderer-independent
   display list of 02 §11, built by `SlideSceneBuilder` from the `ResolvedSlide`) — background,
   layout/master decorations and elements in z-order — applying each element's
   `ElementVisualState` from the timeline (settled frames only: opacity, transforms, dimmed
   parts, persistent emphasis, chart reveal, code state; no blur/transition states exist at step
   ends except `blur`-style code highlighting, 07 §4.2).
3. Element mapping:

| Element content | PDF output |
|-----------------|------------|
| Shapes, lines, connectors, arrows | Vector paths; fills (solid, linear/radial gradients as PDF shadings), strokes, dashes, caps/joins, arrowheads |
| Text | Glyph runs with embedded fonts; line breaks from the core `TextLayoutEngine` (02 §11, 03) with TTF metrics. The **client** passes `LineBreakHints` (the line breaks Flutter laid out on screen) so the PDF matches the screen exactly; the server uses the core layout (a parity test keeps the two within the corpus). Auto-fit sizes are taken from the element's stored/computed fit (03). Text effects: color, highlight, underline, strikethrough, letter spacing, sub/superscript; text shadows rasterized (P1) |
| Images | `PdfImage` (JPEG passthrough, PNG decoded), crop via clip, masks via clip path, corner radius; filters (brightness, contrast, saturation, blur) pre-applied on a raster copy at the printed resolution (`image` package); SVG images as vector (`pdf`'s SVG parser) |
| Tables | Vector cells, borders, text as above |
| Icons (Lucide) | Vector paths from the icon SVGs |
| Emoji | Noto Color Emoji glyph bitmaps rasterized at 4× (P1); v1: Noto Emoji monochrome vector (as Write) |
| Charts | Vector via `PdfChartRenderer` (08 §12), 3D via the software backend |
| Code | Vector text in the mono font (07 §9) |
| Shadows (elements) | Rasterized soft shadow image (2× resolution) under the element |
| Opacity | `ExtGState` alpha |
| Hyperlinks | `PdfAnnotUrlLink` over the link's glyph boxes; links to slides of the deck (`wonky://slide/<slideId>`) → GoTo the target slide's first page (dropped with a warning if the slide is excluded) |

4. Fonts: the deck theme fonts and every font used by elements (curated font list, 05) as
   TTFs from `FontProvider` (client: bundled assets; server: `web/fonts/`), including
   **JetBrains Mono** for code; embedded and **subset** to used glyphs (`pdf`'s `TtfWriter`);
   per-run fallback chain (Noto Sans → Noto Sans Symbols → Noto Emoji) for missing glyphs;
   missing families fall back to the standard fonts with a `font_fallback` warning.
5. Metadata: title, author (owner name), subject (Drive description), creator "Wonky Slides",
   deterministic document id (deck uuid + revision + options hash) and dates (deck modified
   time), so the same input yields the same bytes.
6. su → pt: each slide box applies `scale = boxWidthPt / deck.widthSu`; all geometry is computed
   in su and transformed (§11.2).

Not supported (documented): tagged/accessible PDF structure (the `pdf` package has no tagging;
**P2**: reading order = placeholder order then z-order, alt texts on images/charts), PDF/A,
embedded video/audio (none exist), transitions/animations inside the PDF.

**As built (SL-20).** Code in `wonky_slides_core/lib/src/export/pdf/` (library
`package:wonky_slides_core/pdf.dart`), not `…/src/export/pdf/` under a `core/` folder name.
The exporter first builds every scene with a recording measurer to find the faces in use,
loads them (`TtfFaceSet` over the `FontProvider`: bundled families as themselves, others by
category through `SlidesFonts.resolve`, Open Sans as glyph fallback), then lays text out
for real: on the server with `TtfTextMeasurer` (TTF advance widths, no kerning — exactly
what the PDF draws), in the app with its own `FlutterTextLayoutEngine` passed as
`SlidesExportResources.textLayout` (fonts registered first through `prepareLayoutFonts`), so
client PDFs use the screen's layout results. `lineBreakHints` stays unused (the engine
contract carries no element ids). A parity test keeps the two layouts within 1 line on the
built-in themes (97 % identical breaks). Notes are laid out with the core engine (deck theme
body font, 12 pt). Element shadows print as offset silhouettes (soft raster shadows P1),
group opacity is multiplied into each primitive, icons need an embeddable icon font
(`icon_unavailable` otherwise). The PDF is written on the calling isolate
(`PdfDocument.write` with event-loop balancing). Additive contract fields:
`SlidesPdfOptions.slideIds` (`current`/`selection` resolved by the caller) and
`SlidesExportResources.info` (`SlidesPdfDocumentInfo`: title, author, subject, modified
time, header date label, revision for the deterministic id). Warning codes: `font_fallback`,
`glyph_missing`, `icon_unavailable`, `image_missing`, `image_invalid`, `image_limit`,
`link_dropped`, `page_limit`, `range_unresolved`, `empty_selection`.

**As built (SL-33).** Frames: the print frame without builds (scenes built with
`ScenePurpose.print`: code at its last state, undimmed), and with builds as pages, the final
frame (`finalAnimationState`) and notes/handouts with builds the timeline's settled frames
(scenes built with `ScenePurpose.present`, code as presented). `SlideFrameScenes.apply`
(`lib/src/export/pdf/frame_scenes.dart`) composes what a frame says about content — code state
and highlight step through the element's `CodeSceneComposer` (callouts included), chart reveal
and 3D camera through `SlideChartLayout.build(reveal:, view:, fitViews:)` — and the painter
applies the rest like the stage's `SlideScenePainter`: element visibility, opacity and transform
(the element's own group; anonymous children inherit the state), fill/stroke/text color changes
(OKLab), fill opacity, text parts (hidden, dimmed, `dimColor`, recolored, moved, `revealEnd`),
persistent highlights and the box opacity of text built in parts. Settled frames have no
blur, clip or caret; those running states are not drawn. Code elements draw every `CodeScene`
field the stage draws (callouts with inline Markdown wrapped to ≤ 8 lines, pills on one line with
an ellipsis, no drop shadow; caret; selections; morph glyphs; gutter labels; underlay). Charts:
without a caller-supplied `ChartSceneSource` the exporter lays charts out with `SlideChartLayout`
measuring with the embedded chart font (`TtfChartTextMeasurer` over Open Sans), so server PDFs
draw real charts; timelines get `chartShapeOf` (`SlideChartMotion.shapes`) for chart deliveries.

### 11.4 Where exports run

| Situation | Runs on |
|-----------|---------|
| Offline | Client |
| Online, ≤ 80 pages | Client (desktop: `Isolate.run` with fonts/images pre-resolved; web: main isolate in cooperative chunks behind a progress dialog with *Cancel*) |
| Online, > 80 pages, or images not cached locally | Server (`SlidesExportEndpoint.exportWithProgress`), downloaded via a signed URL |
| MCP `slides.export_pdf`, `drive.export`, AI | Server |
| An older revision (version history) | Server (P1) |

Budgets: 50 slides with images and charts ≤ 5 s desktop client, ≤ 10 s web, ≤ 15 s server; limits
500 pages, 2,000 images, 120 s server timeout, 2 concurrent exports per user.

### 11.5 Server endpoint (`SlidesExportEndpoint`, `slidesExport`)

Same shape as Write's `writeExport` (Write 07 §10): `export(deckUuid, format: pdf | png |
pngZip, optionsJson, revision?) → ExportResultView {fileName, mimeType, sizeBytes, pageCount?,
downloadUrl, expiresAt, warnings}` (≤ 30 s, else `useProgressApi`) and
`exportWithProgress(…) → Stream<ExportProgressEvent>` (`phase`: loading, layout, fonts, images,
charts, packaging, uploading; `progress`; `done`; `error`). Access: viewer+; viewers/commenters
only if `nonEditorsCanExport`. Output stored as a private `StoredFile(kind: exportResult,
expiresAt: +24 h)` (not counted toward quota, Drive D3), signed URL valid 15 min; result cache
keyed by `sha256(deckUuid, revision, format, options, fontsVersion)`. Logs `ActivityEvent(exported,
{format})`.

### 11.6 Export UI

*File › Download ▸ PDF document (.pdf)* (`slides.file.download {format: pdf}`, 04 §4.1) opens
the print/PDF preview (§12), whose settings column holds the §11.1 options and whose *Download
PDF* button exports. Shift-click on the menu item exports immediately with the last-used options
(`immediate: true`). The preview's *More options…* opens the full options dialog
(`WonkyDialogSpec`, MCP-operable): layout cards (Slides / Notes pages / Handouts with an N-up
picker), all §11.1 options, file name, *Cancel*, *Apply*. Progress toast for exports > 1 s;
completion toast "Exported 'Q3 Review.pdf'" (*Show in folder* on desktop); warnings (font
fallbacks, missing images, excluded link targets) under *Details*.

**As built (SL-20).** `slidesExport.export`/`exportWithProgress` reuse Write's
`ExportResultView`/`ExportProgressEvent` (no new models); `itemUuid` is the deck's drive item
(= space). Formats: `pdf`; `png`/`pngZip` and `revision` answer `unavailable` (P1). The
result cache is per server instance, keyed by the deck's content hash (canonical model dump),
options, fonts version and user. In the app, *File › Download ▸ PDF* opens the preview;
`immediate: true` exports with `options` merged over the last-used options (stored in
`UserPreferences.slidesDefaults.exportOptions`); the full options dialog is not built — the
preview's settings column holds every §11.1 option. Client exports have no progress toast or
server switch yet (`TODO.md`).

---

## 12. Print preview route (`/slides/p/:uuid/print`)

```
┌ ← Back   Print preview — Q3 Review                      [Download PDF] [Print] ┐
├──────────┬──────────────────────────────────────────────┬────────────────────┤
│ ▭ 1      │                                              │ Layout             │
│ ▭ 2      │        ┌───────────────────────────┐         │ (Slides|Notes|Hand)│
│ ▭ 3 ◄    │        │       page 3 image        │         │ Per page [6 ▾]     │
│ ▭ 4      │        └───────────────────────────┘         │ ☐ Each build stage │
│ …        │                   3 / 42                     │ ☐ Skipped slides   │
│          │                                              │ Range [All ▾]      │
│          │                                              │ Paper [Slide ▾]    │
│          │                                              │ ☐ Frame slides     │
│          │                                              │ ☑ Header & footer  │
├──────────┴──────────────────────── Zoom [Fit ▾] − + ─────┴────────────────────┤
```

Same implementation pattern as Write's print preview (Write 07 §8.1): the client PDF is shown in
the browser's PDF viewer inside an in-app `<iframe>` platform view on web (page thumbnails,
zoom, navigation from the viewer); desktop rasterizes visible pages with `Printing.raster`
lazily (cached per page and dpi). Settings changes regenerate the PDF (debounced 300 ms) and keep
the current page. *Print* → browser print dialog of the frame (web) / `Printing.layoutPdf`
(desktop; disabled with a tooltip when printing is unavailable). `Mod+P` in the editor opens the
route; `Mod+P` inside prints; `Esc` goes back. Viewers/commenters can print only with
`nonEditorsCanExport`.

---

**As built (SL-20).** `wonky_slides/lib/features/print/`: `PrintPreviewScreen` on the
`print` child route (`?layout=slides|notes|handouts`), the browser's PDF viewer in an
`<iframe>` platform view (web; other platforms show a summary), a 300 px settings column
(below 720 px a header toggle swaps preview and settings), *Download PDF* and *Print* (the
viewer frame's print dialog). It renders with the open editor's session (the editor stays
mounted underneath). The viewer's current page is not kept across regenerations (not
readable from the frame).

## 13. PNG export (P1) and slide images

- *File › Download ▸ PNG image (current slide)* / *PNG images (.zip, all slides)*; options:
  scale 1× / 2× / 4× of the slide size in su (1920 × 1080 su → 1920 × 1080 px at 1×; max 7680 px
  wide), *Transparent background* (omits the slide background), *Step* (final frame default; or
  each build stage as separate images), range as PDF.
- Client: `SlideStage` rendered offscreen (`RenderRepaintBoundary.toImage`) with the edit or
  chosen frame; zip via `archive`.
- Server (MCP `slides.render_slide`, Drive thumbnails when no client thumbnail exists):
  `SlideRasterRenderer` in `wonky_slides_core` (P1) — the `wonky_charts` scanline rasterizer
  extended with TTF glyph outlines (`TtfGlyphOutlines` from `pdf`'s `TtfParser`), antialiased,
  images via `image`; quality sufficient for agents and thumbnails, not for print.
- Copy slide as image (`slides.slide.copyAsImage`, P1): PNG 2× to the clipboard.

**As built (SL-33).** Feature `imageExports`. *File › Download ▸ PNG image (current slide)…* /
*PNG images (all slides, .zip)…* (`slides.file.download {format: png|pngZip}`) open the PNG
dialog (`dialog.slides.downloadPng`, a `WonkyDialogSpec`): *Slides* (current, selected — with a
multi-selection —, all), *Size* (1×, 2×, 4×, capped at 7,680 px wide), *Builds* (*All content (as
printed)* = the print frame, *After the last build* = `finalFrame`, *Each build stage* = one
image per printed step as in the PDF) and *Transparent background*. `immediate: true` and MCP
calls skip the dialog; `options` keys: `range` (`current|selection|all|"1-3,7"`), `scale`,
`frames` (`print|final|builds`), `transparent`, `includeSkipped`, `fileName`. **Deviation:** the
default is the print frame (Q24: prints and thumbnails show the authored slide), not the final
frame. Rendering is the stage's software path (`MotionScenes` + `recordScene` → `toImage`, as
snapshot transitions; images preloaded; 3D charts on the software backend), independent of the
canvas zoom — not a `RepaintBoundary`. One image downloads as `<title>.png`; several as
`<title>.zip` with stored entries "Slide 03.png" / "Slide 03, step 2.png" (`StoredZip`: no
deflate — PNGs don't shrink —, CRC-32, fixed dates; written in the app instead of the `archive`
dependency of A-10-8). Downloads use the same-tab browser download of PDFs. Last-used size,
frames and transparency: `slidesDefaults.imageExportOptions`. Not built: the server's
`SlideRasterRenderer` and `slidesExport` `png`/`pngZip` (still `unavailable`), *Copy slide as
image*.

---

## 14. Commands

Present-mode commands are in keymap scope `present` (addition to suite 08 §1.2). `requiredRole`
viewer unless noted; none are undoable except where marked.

| Command id | Args | Notes |
|------------|------|-------|
| `slides.present.fromCurrent` / `fromStart` | `{kiosk?: bool}` | `Mod+Enter` / `Mod+Shift+Enter` (04) |
| `slides.present.fromSlide` | `{slideId, step?}` | |
| `slides.present.presenterView` | `{from?: current\|start}` | `Mod+Alt+Enter` |
| `slides.present.end` | — | `Esc` |
| `slides.present.next` / `previous` | — | Step-wise |
| `slides.present.nextSlide` / `previousSlide` | — | Skip builds |
| `slides.present.goTo` | `{slideId \| position, step?}` | |
| `slides.present.first` / `last` | — | |
| `slides.present.blank` | `{color: black\|white\|none}` | |
| `slides.present.picker` | `{open?: bool}` | |
| `slides.present.tool` | `{tool: arrow\|laser\|pen\|highlighter\|eraser, color?, width?}` | |
| `slides.present.clearInk` / `undoInk` | `{slideId?}` | |
| `slides.present.keepInk` (P2) | — | Editor; ✓ undoable |
| `slides.present.timer` | `{action: start\|pause\|resume\|reset}` | |
| `slides.present.openOnAnotherDevice` | — | Audience link + QR dialog (§5.2) |
| `slides.present.joinAsAudience` | `{sessionId}` | *Show audience view here* banner (§5.2, §6.3) |
| `slides.present.remote` (P1) | — | "Use phone as remote": QR + code (id from 04 §3) |
| `slides.present.toggleFullscreen` | — | `F` |
| `slides.present.toggleSkipped` | — | Presenter view |
| `slides.present.notesSize` | `{delta \| size}` | |
| `slides.present.captions` (P2) | `{on?: bool, language?}` | |
| `slides.present.help` | — | `?` |
| `slides.present.rehearse` | — | Editor |
| `slides.present.saveTimings` | `{timings}` | Editor; ✓ "Record timings" |
| `slides.slide.clearTimings` | `{slideIds?}` | Editor; ✓ |
| `slides.deck.setPresentSettings` | `{patch}` | Editor; ✓ "Presentation settings" |
| `slides.file.download` | `{format: pdf\|png\|pngZip\|markdown, options?, immediate?: bool}` | Id from 04 §4.1. `pdf` opens the print/PDF preview (§12) unless `immediate` (Shift-click, MCP) exports with `options` or the last used; `png`/`pngZip` open the PNG dialog unless `immediate`/MCP (§13, SL-33); `markdown` = outline (04 §10, P2, hidden). Viewer+ subject to `nonEditorsCanExport` |
| `slides.print.open` | `{layout?}` | `Mod+P` |
| `slides.print.print` | — | `Mod+P` in the route |
| `slides.slide.copyAsImage` (P1) | `{slideId?}` | |

Menus ([04](04-screens-menus-toolbar.md)): *View › Present ▸* (from current, from beginning,
presenter view, rehearse), the title-row Present button, *File › Download ▸ PDF / PNG*, *File ›
Print* (`Mod+P`, `slides.print.open`). Addition requested in 04: *Present ▸ Presenting
settings…* opens the settings page with the *This presentation* section.

---

## 15. Captions (P2)

Live captions from the presenter's microphone (Web Speech API `SpeechRecognition` where
available; desktop: platform speech recognizers), shown at the bottom of the audience view (two
lines, 32 su, high-contrast pill) and sent to followers. Opt-in per presentation with a privacy
notice ("Your browser may send audio to its speech service"); nothing is recorded or stored.
Language from the deck's language setting.

---

## 16. Accessibility

- Present mode exposes the current slide's content to screen readers in reading order
  (placeholders first, then z-order top to bottom) and announces newly built content (06 §17).
- The presenter view, picker, remote and dialogs are fully keyboard operable; focus never lands
  in an audience view.
- Laser and ink don't carry information alone; the help overlay lists every shortcut.
- Black/white screens and transitions honor reduced motion (fades shortened to 0/100 ms).

---

## 17. Acceptance criteria

1. `Mod+Shift+Enter` presents full screen from the first non-skipped slide; `→`/`PageDown`/
   click step through builds and slides; `Esc` returns to the editor at the shown slide.
2. A Logitech-style clicker (PageDown/PageUp/B/F5/Esc) drives the whole presentation on the web
   without triggering browser reloads.
3. Clicking during a running build finishes it; `←` jumps to the previous step's end state.
4. *Presenter view* runs in the presenting window; no code path opens a window (test: no
   `window.open`/Window Management API calls; suite 03 §1). A second browser signed in to the
   same account opens the audience link (or the *Show audience view here* banner), goes full
   screen and follows navigation, laser and ink within 300 ms p95 on a LAN; ending the
   presentation ends the audience view.
5. The presenter view shows current, next build/slide, notes, timers and pacing against
   rehearsed timings.
6. Laser, pen, highlighter, eraser and clear work on the audience view (and from the presenter
   view's current slide); ink survives navigating away and back and disappears after ending.
7. The slide picker shows groups and skipped slides; picking a skipped slide shows it; *Next*
   continues after it with the next non-skipped slide.
8. Kiosk mode advances on its own, loops, and exits only with a 2 s Esc hold.
9. Rehearsing and keeping timings is one undo step; auto-advance with rehearsed timings follows
   them within ±1 frame.
10. A deck presents fully offline (images cached) including linked charts and 3D charts.
11. (P1) A phone joins as remote via QR; Next on the phone advances the audience in ≤ 150 ms p50.
12. PDF export: slides, builds as pages (page count = step count), notes pages, handouts 2/3/4/
    6/9, skipped slides in/out, group bookmarks, clickable URL and slide links, fonts embedded
    and subset (incl. JetBrains Mono), vector text selectable/searchable; the same options on
    server and client give the same page count and visually equal pages (raster diff < 1 %).
13. 50-slide fixture deck exports within the §11.4 budgets.
14. Print preview regenerates on option changes and prints via the browser/OS dialog.
15. All commands in §14 are invocable via `ui.invoke_command`; undoable ones pass execute → undo
    → redo.

## 18. Tests

- Core: page list resolution (ranges, skipped, groups, builds as pages), page geometry per
  layout and paper, bookmarks tree, link targets, deterministic bytes for a fixture (server
  layout path), font subsetting, warnings.
- Client/server parity: render the PDF corpus on both, rasterize with `pdftoppm` in CI and diff
  (< 1 %); page counts equal.
- Present mode widget tests: keymap (all keys in §2.1), finish-during-build, skipped slides,
  picker, black/white, ink model, kiosk timers (fake clock), rehearse flow.
- Presentation session: server tests for join/roles/pairing/expiry/takeover, message relay across
  two instances (bus), rate limits; client tests for follower seek and clock offset.
- Single window: a test asserts that presenting never calls `window.open` or the Window
  Management API; manual QA checklist for presenter view + audience in a second browser on
  Chrome, Firefox and Safari, and with a phone as audience.
- E2E: present a fixture deck via `flutter_driver`, export PDF and check page count/bookmarks.

---

## 19. Additions to 02-data-model

| # | Change | Reason |
|---|--------|--------|
| A-10-1 | `Deck.presentJson: String?` with the §3 schema (`v`, `mode`, `useRehearsedTimings`, `advanceDuringBuild`, `endBehavior`, `wheelAdvance`, `letterboxColor`, `reduceMotion`, `keepPresentingOutsideFullscreen`, `kiosk {restartAfterIdleSec, exitGesture, allowNavigation}`, `laserColor`, `showCaptionsByDefault`). | §3 |
| A-10-2 | `Slide.timingsJson: String?` (`v`, `stepsMs`, `totalMs`, `rehearsedAt`, `by`). | §10 |
| A-10-3 | `Slide.skipped: bool` and `SlideGroup.skipped: bool` semantics as §2.2 (effective skip = slide or its group). | §2.2 |
| A-10-4 | `UserPreferences.slidesPresenter` (JSON, synced per user): presenter layout preset, notes size, timer mode/target, pen colors/widths, start-with-presenter-view, show-skipped-in-presenter; and `slidesExportOptions` (last-used PDF/PNG options). | §3, §11.1 |
| A-10-5 | Server (not synced, ephemeral): `PresentationEndpoint` with `PresentationJoin`, `PresentationUpdate`, `PresentationEvent` (sealed: `state`, `laser`, `ink`, `command`, `camera`, `end`, `roster`) models; bus channel `present:<sessionId>`. | §6 |
| A-10-6 | Server: `SlidesExportEndpoint` + `ExportResultView`/`ExportProgressEvent` reuse (Write's models generalized to `itemUuid`). | §11.5 |
| A-10-7 | Presence state value `presenting` (suite 07 §1.1). | §8 |
| A-10-8 | Suite 03 §1: no presenting exception in v2 (§5.2, decided); suite 08: keymap scope `present`; suite 01 §2.1: `wonky_slides` justified exceptions `printing`, `pdf`, `archive` (PNG zip); `window_manager`/`screen_retriever` only when desktop work resumes. | §5, §2, §12 |
