# Slides 03 · Editor Canvas and Objects

The slide canvas is where slides are designed: selecting, moving, resizing, rotating, snapping,
aligning, and editing every element kind. This spec defines the canvas, the selection model, the
transform tools, smart guides, each element kind's editing, element groups, lock/hide/z-order,
the format painter, the keyboard map, the clipboard, find & replace, spell check, accessibility
and performance budgets.

Storage of everything here is [02-data-model.md](02-data-model.md). Menus, toolbar, inspector,
navigator and dialogs are [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md) (the canonical
menu command registry). Code elements' editing is [07-code-blocks.md](07-code-blocks.md); chart
elements' editing [08-charts-from-sheets.md](08-charts-from-sheets.md); builds and Magic Move
[06-animations-and-transitions.md](06-animations-and-transitions.md).

Owned folders: `wonky_slides/lib/features/{canvas,selection,snapping,elements/**,text_editing,
layers,clipboard,find,spellcheck,accessibility}/`, `wonky_slides_core/lib/src/{scene,layout,text,
geometry,connectors,clipboard}/`.

---

## 1. Architecture

### 1.1 Runtime objects (one set per open deck)

| Object | Package | Responsibility |
|--------|---------|----------------|
| `DeckSession` | app `features/model` (contract in [12 §5.3](12-implementation-plan.md); RevLog implementation `features/revlog/logged_deck_session.dart`) | `DeckModel`, `execute(op)`, `applyChanges`, remote batches, load state, role |
| `DeckEditorController` (`DocumentController`) | app `features/editor_screen` | Current slide, view mode, active tool, panels; implements shell hooks (cut/copy/paste, selection snapshot, comment anchors, presence cursor JSON) |
| `CanvasController` | app `features/canvas` | Zoom, fit, scroll offset, su ↔ screen mapping, hit testing, viewport rect |
| `SelectionController` | app `features/selection` | Selected element ids, focus (canvas/text/table/crop), group entry path, marquee |
| `TransformSession` | app `features/selection` | Live drag/resize/rotate state, ghost frames, writes one plan on drop |
| `SnapEngine` | core `geometry/snapping.dart` (pure Dart) | Snap targets and results for a moving box; equal-spacing detection |
| Per-kind behavior | app `features/elements/<kind>/`, core `scene/` | Scene nodes in core (`SlideSceneBuilder`); hit tests, handles, activation and inspector sections per kind in the canvas, selection and inspector (§1.3 as built) |
| `SlideTextEditor` | app `features/text_editing` | The single active rich-text editor (super_editor) for the body being edited |
| `SlideStage` | app `features/stage` (owned by 06 §12.1) | Paints `SlideScene` (02 §11) in the **edit frame** (06 §9.6) with per-element `RepaintBoundary`s; shared by canvas, thumbnails and presenting |

### 1.2 Keyboard scopes (suite 08 §1.2)

| Scope | Active when | Examples |
|-------|-------------|----------|
| `slidesCanvas` | Canvas has focus, no text editing | arrows nudge, Delete, Mod+D, Mod+G, Enter edits text |
| `slidesText` | A text body is being edited | Mod+B, Tab indents list, Esc exits editing |
| `slidesTable` | Table cell range selected (not editing text) | arrows move cell selection, Enter edits cell |
| `slidesCrop` | Image crop mode | Enter commits, Esc cancels |
| `slidesNavigator` | Slide navigator focused (04 §5) | Mod+G groups slides, Mod+↑/↓ move slides |
| `slidesNotes` | Speaker notes editor focused | Mod+B, Esc returns to canvas |
| `present` | Presenting (10 §14) | arrows, Space, B/W |

More specific scopes win; contextual bindings (suite 08 §1.2) let one chord mean different
commands per scope (e.g. Mod+G).

### 1.3 Element kind handler API (contract, [12 §5.4](12-implementation-plan.md))

```dart
abstract class ElementKindHandler {
  SlideElementKind get kind;
  /// Scene node for a resolved element (pure, used by canvas, thumbnails, present, PDF via core).
  SceneNode buildScene(ResolvedElement e, SceneContext ctx);          // implemented in core
  /// Precise hit test in element-local coordinates (su).
  bool hitTest(ResolvedElement e, Offset localSu, {required double tolerancePx});
  /// Extra handles beyond the 8 resize + rotation handles (adjust, line endpoints, crop…).
  List<HandleSpec> extraHandles(ResolvedElement e);
  /// Snap points offered to the SnapEngine (edges, centers, connection sites).
  List<SnapPoint> snapPoints(ResolvedElement e);
  /// What double-click / Enter does (edit text, enter group, crop, open chart editor…).
  ElementActivation activation(ResolvedElement e);
  /// Inspector sections for the Format tab (04 §7.2).
  List<InspectorSectionSpec> inspectorSections(BuildContext context, ElementSelection sel);
  /// Overlay widget while the element is being edited (text editor, code editor, crop UI…).
  Widget? editingOverlay(BuildContext context, EditingTarget target);
}
```

Handlers are registered by each `elements/<kind>/` folder; the canvas never switches on kind.

**As built (CQ-56):** this registry was never wired up: scene nodes are built in core
(`SlideSceneBuilder`, one function per kind), and hit tests, extra handles, activation, minimum
sizes and inspector sections are switches on the element kind in the canvas, selection and
inspector code. The unused `ElementKindHandler`/`ElementKindRegistry` (and the
`CoreSceneBuilding` mixin) were deleted rather than half-adopted; a new kind adds its cases there
(and its scene builder in core). Moving per-kind behavior behind handlers remains a possible
refactor (slides M6), not a contract.

---

## 2. Canvas

### 2.1 Layout

```
┌──────────────────────── canvas viewport (token `canvas`) ───────────────────────┐
│   pasteboard (objects may sit off-slide; drawn at 40 % opacity outside)          │
│        ┌──────────────────────── slide ────────────────────────┐                 │
│        │  background, master/layout elements, slide elements    │  shadow (token  │
│        │  selection chrome, guides, remote selections (09)      │  `slideShadow`) │
│        └────────────────────────────────────────────────────────┘                 │
│                                                    [ − 100 % + ]  [Fit]  (status bar) │
└─────────────────────────────────────────────────────────────────────────────────┘
```

- The slide is centered with a margin of 48 px (Fit) on a pasteboard that extends **one slide
  width/height** beyond each edge (objects can be parked off-slide; they are clipped when
  presenting and in PDF/thumbnails).
- Background of the viewport: app token `canvas` (follows light/dark). The slide renders as
  designed in the deck's **appearance** (05 §2.4), independent of the app theme (suite 02 §8: like
  Sheets cell colors, deck colors are absolute).
- Rulers (P1, §5.6) occupy 20 px at top/left when shown.

### 2.2 Zoom and fit

| Action | Command | Shortcut (mac / win-linux) |
|--------|---------|----------------------------|
| Fit slide to window (default; re-fits on resize) | `slides.view.zoomFit` | ⌥⌘0 / Ctrl+Alt+0 |
| Zoom to 100 % (1 su = 1 logical px) | `slides.view.zoom {percent: 100}` | ⌘0 (desktop) / Ctrl+0 (desktop) |
| Zoom in / out (steps 10, 25, 33, 50, 67, 75, 100, 125, 150, 200, 300, 400 %) | `slides.view.zoomIn` / `zoomOut` | ⌥⌘= / ⌥⌘− ; Ctrl+Alt+= / Ctrl+Alt+− |
| Zoom to selection | `slides.view.zoomToSelection` | — |
| Pinch / Mod+wheel | continuous zoom around the pointer | trackpad / Mod+wheel |

"Fit" is a mode: while active, window resizes keep the slide fitted; any explicit zoom leaves it.
Zoom and scroll are per-user view state (`LocalViewState`, not undoable, suite 08 §2).

### 2.3 Scrolling and panning

- Wheel/trackpad scroll pans the pasteboard (when the slide doesn't fit); at Fit, vertical wheel
  over the canvas **switches slides** (P1, setting *Scroll to change slides*, default off — Google
  behavior is to scroll within the page).
- **Space+drag** (or middle-mouse drag) pans; the cursor shows a hand.
- Scrollbars: `WonkyScrollArea` thin auto-hide.

### 2.4 Rendering

- The current slide is painted from its `SlideScene` (02 §11): one `RepaintBoundary` per
  top-level element, a background layer, an **overlay layer** for selection chrome, guides,
  remote selections and comment pins (repaints without touching content).
- **Incremental rendering (as built, CQ-43).** Resolved elements keep their identity while
  their inputs are unchanged (the row, the rows of the placeholder chain, the theme, the slide
  size and the group context), so an edit rebuilds and repaints only the changed elements'
  nodes and layers. Master and layout decorations resolve once and are shared by every slide
  that draws them (instead of a separately cached master/layout picture). Scene nodes are
  cached per resolved element and context (canvas, thumbnail, present), keyed by the
  element's revision of dependent rows (table cells, code states, chart links). Render
  revisions (`DeckIndexes.revision`) change only with what a slide draws from: its
  render-relevant columns, its elements and builds, its effective layout, master and theme
  (rows and elements), and the deck's size, appearance, theme, numbering and footer — not
  speaker notes, timings, the deck title, guides or present settings; a change to a layout
  re-renders only the slides that use it. (Known edge: an instance whose `placeholderOf`
  points into another layout than its slide's is not invalidated by that layout; repair
  re-links such instances.)
- Text is laid out by the Flutter `TextLayoutEngine` (same metrics as thumbnails/presenting);
  fonts load on demand (05 §3.3); until loaded, fallback metrics then re-layout (max 1.5 s).
- During a drag, only the moving elements' boundaries repaint, never relayout. As built: a
  top-level element that only moves and stays inside the slide is moved as a composited layer
  (`SlideLiveTransforms`, no repaint and no stage rebuild per pointer move); nested elements,
  resizes, rotations and elements crossing the slide edge repaint through the frame. The
  stage widget and the per-element semantics nodes are reused between pointer moves.
- Off-slide content is drawn at 40 % opacity; hidden elements are not drawn (§8.2). Only
  elements whose painted bounds (strokes, shadows, blur) cross the slide edge are painted
  twice (dimmed outside, full inside); others are painted once.
- Images decode at about the size they are drawn at (power-of-two width buckets, never above
  the natural size) into one cache per open deck shared by the canvas, thumbnails, previews
  and presenting, bounded by bytes (256 MB native, 160 MB web). A missing image stays blank;
  a transient failure (offline, server error) is retried with backoff and when the
  connection comes back. Polling for another user's pending upload stops when the deck
  closes.
- Empty placeholders draw a dashed outline (token `placeholderBorder`) and their prompt text
  (§6.2) — only in the editor (never thumbnails, presenting or PDF).

---

## 3. Selection model

### 3.1 States

| State | Visual | Keyboard |
|-------|--------|----------|
| **None** (slide focused) | — | arrows: nothing; Tab selects the first element in reading order; Enter: nothing |
| **Element(s) selected** | 1.5 px `slidesSelection` outline per element; **one** bounding box with 8 resize handles + rotation handle when one element (or a multi-selection — box of the union); dimensions badge while transforming | arrows nudge, Delete, Mod+D, Mod+C/X, Tab/Shift+Tab next/previous element, Enter activates (§3.4), Esc clears |
| **Inside group** | Group's outline dashed; selected child outlined | Esc → selects the group |
| **Text editing** | Box outline thin dashed, caret, text selection | `slidesText` scope; Esc → element selected |
| **Table cells** | Cell range highlight | `slidesTable` scope |
| **Crop** | Crop frame + dimmed outside area | `slidesCrop` scope |
| **Line endpoints** | Lines show endpoint handles instead of a box | drag endpoints |

Selection is **per slide**: changing the current slide clears it (restored when returning in the
same session). Selection is view state, never undoable, but restored by undo/redo (suite 08).

### 3.2 Pointer rules

| Gesture | Result |
|---------|--------|
| Click on an element | Select it alone (the **topmost hit**, by z-order, among unlocked, visible elements; transparent areas of shapes without fill hit only within 4 px of the stroke unless the shape has text) |
| Click on an element inside a group (group not entered) | Selects the **group** |
| Double-click on a group | Enters the group and selects the hit child |
| Click on empty slide / pasteboard | Clears the selection (slide focused) |
| Shift+click | Toggle element in the selection (Mod+click too) |
| Mod+click on a child inside a group (not entered) | Selects the child directly ("deep select") |
| Drag from empty area | **Marquee**: selects elements fully inside the rectangle; with Alt (Option): elements touching it; Shift adds to the selection |
| Drag on a selected element | Moves the selection (§4.1) |
| Drag on an unselected element | Selects it and moves it in one gesture |
| Click on a locked element | Nothing is selected (click goes through to elements below); Layers panel can select it (§8.1) |
| Right-click | Selects the hit element if not selected, then the context menu (04 §11.2) |
| Double-click / Enter | Activation (§3.4) |

Hit tolerance: 4 logical px for strokes and line elements (8 px for lines thinner than 4 px).

### 3.3 Keyboard selection

- **Tab / Shift+Tab** cycles elements of the current slide in **reading order** (§17.2),
  including placeholders; inside an entered group, cycles its children.
- **Mod+A** (`shell.edit.selectAll`): canvas → all unlocked, visible elements of the slide; text
  editing → all text of the body; table → all cells.
- **Esc**: text editing → element selected; inside group → group selected; element(s) → none.
- `slides.select.sameKind` (P2): selects every element of the same kind on the slide.

### 3.4 Activation (double-click / Enter)

| Kind | Activation |
|------|------------|
| text, shape, placeholder with text | Enter text editing (caret at click position; Enter key: caret at end) |
| group | Enter group |
| table | Edit the clicked cell's text (Enter: first cell) |
| image | Enter crop mode (§6.5.4) |
| picture placeholder (empty) | Open *Insert image* (§6.5.1) |
| line/connector | Edit the line label (P2); otherwise nothing |
| code | Enter code editing ([07](07-code-blocks.md)) |
| chart | Open the chart inspector section ([08](08-charts-from-sheets.md)) |
| icon | Open the icon picker to replace the icon |

**Typing** a printable character with exactly one text-capable element selected enters text
editing with the caret at the end and inserts the character (Google behavior). Typing with an
empty placeholder selected replaces its prompt.

---

## 4. Transforms

### 4.1 Move

- Drag starts after a 3 px threshold. A **live ghost** (the elements themselves, moved on the
  transform layer) follows the pointer; snapping (§5) applies continuously; a badge shows `x, y`
  in su.
- **Shift** constrains to horizontal/vertical/45°. **Alt (Option)** at drop *duplicates* instead
  of moving (Keynote/Figma); the cursor shows `+`. **Mod** held disables snapping temporarily.
- On drop the move is written **once** as `slides.element.move {ids, dx, dy}` →
  `UpdateFrames` naming `x,y` (02 P4). One undo step "Move".
- Dragging off the slide parks elements on the pasteboard; dragging onto the navigator moves
  (Alt: copies) them to the hovered slide (P1, drop indicator on the thumbnail).
- Auto-scroll when the pointer is within 24 px of the viewport edge (zoomed in).

### 4.2 Resize

- 8 handles (corners + edges, 8 px squares, `slidesSelection` stroke, `background` fill; 16 px
  touch targets). Corner drag resizes both dimensions; **Shift** keeps aspect ratio (default *on*
  for images, icons and groups — Shift then frees it); **Alt** resizes from the center.
- Multi-selection resize scales every element's frame relative to the selection box (font sizes
  are **not** scaled unless *Scale text* is checked in the inspector's Arrange section, P1).
- Text boxes with `autofit: resize`: dragging the top/bottom handles sets the minimum height;
  `wrap: false` boxes resize width only by dragging the left/right handles (switching to
  `wrap: true` on drag).
- Minimum 1 su (lines: 0 in one dimension). Negative drags flip (`flipH`/`flipV` toggled) like
  Keynote.
- Written once on release: `slides.element.resize {ids, frames}` naming `x,y,width,height`
  (+ `flipH/flipV` if changed). One undo step "Resize".

### 4.3 Rotate

- Rotation handle 24 px above the top edge (below when near the viewport top). Drag rotates about
  the box center; **Shift** snaps to 15°; angle badge shows degrees. Near 0/90/180/270° it snaps
  within 3° (Mod disables).
- Multi-selection rotates every element about the selection center (each element's `x,y` and
  `rotation` written).
- Commands: `slides.arrange.rotate {degrees: 90|-90}`, `slides.arrange.flip {axis: h|v}`.
- Numeric rotation in the inspector (Arrange section, `WonkyNumberStepper`, −360…360).

### 4.4 Nudge

Arrow = 1 su, Shift+arrow = 10 su (Mod+arrow: 1 screen pixel at the current zoom, P2). A burst of
nudges within 1000 ms coalesces into one undo step "Nudge" (`UndoService.replaceLast`).
`slides.element.nudge {dx, dy}`.

### 4.5 Numeric frame

Inspector › Arrange (04 §7.2): X, Y, W, H (su; also in in/cm per Settings › Slides › Units, P1),
lock-aspect toggle, rotation, flip buttons. Each committed field is one undo step.

### 4.6 Remote and permissions

- Collaborators see the result on drop (sync) and, while dragging, a **transient outline** of the
  moving frame in the mover's presence color (presence `transform` hint, 09 §2.4, P1).
- Viewers/commenters can select (to copy if allowed, read alt text, comment) but not transform:
  handles are hidden and the cursor shows the default arrow.

---

## 5. Smart guides, snapping, alignment, rulers and guides

### 5.1 Snap targets

`SnapEngine.snap(movingBox, targets, thresholdSu)` (pure Dart) with targets (in priority order):

1. Slide edges and center lines (horizontal and vertical).
2. User guides (§5.6).
3. Edges and centers of other **visible** elements on the slide (including master/layout
   decorations and placeholders), and of the selection's own siblings inside an entered group.
4. **Equal spacing**: gaps equal to existing gaps between neighbors in the same row/column.
5. **Equal size** (resize only): widths/heights equal to other elements'.
6. Grid (P2: optional 8 su grid, View › Snap to grid).

Threshold: 6 screen px converted to su at the current zoom. Snapping applies to the moving
selection's left/center/right and top/middle/bottom. Lines snap their endpoints to targets and to
**connection sites** (§6.4).

### 5.2 Visuals

- Alignment guides: 1 px lines in token `slidesGuide` (magenta-ish `#E5389B` light / `#F472B6`
  dark) spanning between the aligned objects, with small × markers at aligned points.
- Equal spacing: pink bars with the distance label ("48") between each pair of equal gaps.
- Slide center: dashed guide across the whole slide.
- Distance labels (P1): holding **Alt** while an element is selected and the pointer hovers
  another element (or the slide) shows distances in su (Figma).

### 5.3 Preferences

View › Snap ▸ *Smart guides* (`slides.view.toggleSmartGuides`, default on), *Snap to objects*
(`slides.view.toggleSnapObjects`, on), *Snap to guides* (on), *Snap to grid* (P2, off). Per-user
(`UserPreferences.slidesDefaults`), not undoable.

### 5.4 Keyboard

While dragging: Shift constrain, Alt duplicate, Mod no-snap. While resizing: Shift aspect, Alt
center.

### 5.5 Align and distribute

| Command | Effect | Shortcut |
|---------|--------|----------|
| `slides.arrange.align {edge: left\|centerH\|right\|top\|middle\|bottom}` | ≥ 2 selected: align to the **selection bounds** (or to the *key object* if one was clicked last with Alt, P2); 1 selected: align to the **slide** | ⌥⌘← ⌥⌘→ ⌥⌘↑ ⌥⌘↓ for left/right/top/bottom (canvas scope) · Ctrl+Alt+arrows |
| `slides.arrange.distribute {axis: horizontal\|vertical}` | ≥ 3 selected: equal gaps between first and last | — |
| `slides.arrange.centerOnSlide {axis: horizontal\|vertical\|both}` | Center the selection box on the slide | — |
| `slides.arrange.matchSize {dimension: width\|height\|both}` (P1) | Set to the key (first-selected) element's size | — |
| `slides.arrange.tidy` (P2) | Figma "tidy up": snap a near-grid to an even grid | — |

Each is one undo step naming `x,y` (and `width,height` for match size).

### 5.6 Rulers and guides (P1)

- View › Show › *Rulers* (`slides.view.toggleRulers`, ⌥⇧⌘R / Ctrl+Alt+Shift+R — ⇧⌘R reloads the page in browsers): su scale with
  selection extent highlighted.
- **Drag from a ruler** creates a guide (vertical from the left ruler, horizontal from the top);
  drag a guide off the slide to delete; double-click a guide → position input. Guides are stored
  per deck in `Deck.guidesJson` (§20) — a whole-value JSON (`[{"axis":"v","at":960}]`), one undo
  step per change, commands `slides.guides.add {axis, at}`, `slides.guides.move`,
  `slides.guides.delete`, `slides.guides.clear`. Guides are drawn in token `slidesUserGuide`
  (teal) and hidden when presenting/printing.
- Master/layout guides (P2): guides of the slide's layout are shown dashed.


### 5.7 As built (SL-12)

- **Code.** Core `package:wonky_slides_core/snapping.dart` (`lib/src/snapping/`, not
  `geometry/snapping.dart`): `SnapEngine` (`snapMove`, `snapResize` with equal size,
  `snapPoint` with connection-site gluing, `snapAngle`), `SnapTargets` (built once per drag;
  sorted lines + binary search; a query over 500 elements stays well under the 2 ms
  budget), `FrameTransforms`
  (`resize` by handle in the frame's rotated axes with aspect/center/flip, `scaleInBox`,
  `rotateAbout`, `constrain`, `toChild`/`deltaToChild` = inverse of `GroupSpace.toParent`),
  `UserGuides` (`Deck.guidesJson` codec). App: `features/canvas/` (`SlideCanvas`,
  `SlideCanvasController` — one per open deck, attached by the editor screen, owns the deck's
  `SlideRenderer` over the session's image resolver; `CanvasController` = viewport;
  `CanvasOverlayPainter`; `RulerPainter`; `CanvasTokens`), `features/selection/`
  (`SelectionController` via `selectionOf(editor)`, `TransformSession`, `ReadingOrder`,
  `SlideElements`), `commands/canvas_commands.dart`.
- **Selection** ids stay in `DeckEditorController.selectedElementIds` (chrome, undo snapshots,
  MCP); `SelectionController` adds the entered group, the marquee and per-slide memory.
  Mod+click deep-selects when it hits a child of a group that isn't entered, otherwise it
  toggles like Shift+click; Mod pressed *during* a drag disables snapping. A click (no drag)
  on an element of a multi-selection selects it alone. Locked elements are click-through and
  show a lock badge instead of handles when selected elsewhere; hidden elements aren't drawn
  or hit. Tab order = `ReadingOrder` (§17.2, locked elements skipped).
- **Live previews** are element visual states of the stage's `SlideFrame` (a matrix from the
  start frame to the live frame, conjugated into the parent node's space): nothing is laid
  out or written while dragging, so text scales visually during a resize and glued
  connectors follow on drop. Each gesture writes one command on release: `slides.element.move
  {ids, dx, dy, duplicate?}` (slide-space delta, mapped into group child space per element),
  `slides.element.resize {frames, label: resize|rotate}` (stored frames — children in their
  group's child space; only the given columns), `slides.element.adjust {id, key, value}`
  (`dataJson.adjust`), `slides.element.setLineEnds {id, start, end}` (slide points, optional
  `elementId`/`site`; frame = the endpoints' box, rotation/flips cleared, `start/end`
  normalized with base-62 `connect`), `slides.guides.add|move|delete {axis, at, index}`.
  Values are rounded to 0.01 su. Esc while dragging cancels the gesture.
- **Nudges** (`slides.element.nudge {dx, dy}`, arrows / Shift+arrows) coalesce into one step
  when the same selection is nudged within the undo service's 1,000 ms window (the Sheets
  object pattern: the top step is replaced with merged row changes).
- **Snapping preferences:** object snapping (slide, elements, equal spacing/size) needs both
  *Smart guides* and *Snap to objects*; *Snap to guides* controls user guides. Guides draw on
  the overlay in `slidesGuide`; equal-size matches draw a bar under each matching box.
- **Viewport:** zoom stays in the editor (`DeckEditorController.zoom`/`zoomFit`, SL-11's
  steps); the canvas owns the pan, fits with a 48 px margin (16 px below 768 px), pans the
  pasteboard (one slide beyond each edge) with the wheel, Space/middle-drag and auto-scroll,
  zooms around the pointer with Mod+wheel and pinch, and draws thin scrollbar indicators
  (not draggable).
- **Arrange:** align with one element aligns to the slide, a single child of an entered group
  to its group's box; distribute and match size need one common parent; *Rotate 90°* turns
  each element about its own center. Edit › Delete/Duplicate act on elements and fall back to
  `slides.slide.delete`/`duplicate` without an element selection; duplicating (and Alt-drag
  duplicating) is limited to top-level elements. `slides.element.activate` (Enter /
  double-click) enters element groups; SL-13/SL-15 extend it for text, tables and crop.
- **Rulers and guides (P1):** rulers overlay the top/left 20 px of the canvas (they don't
  shift it); dragging from a ruler adds a guide, dragging a guide (within 4 px) moves it, off
  the slide deletes it; `Deck.guidesJson` is the object `{"v":1,"guides":[{"axis":"v",
  "at":960}]}` (the planner stores JSON objects only). Not built: double-click → position
  input, layout guides (P2).
- **Tokens** live in `features/canvas/canvas_tokens.dart` (`CanvasTokens`, light/dark) rather
  than `theme/slides_tokens.dart`.
- **Not built (TODO.md):** Alt distance labels (P1), drop on a navigator thumbnail (P1), smart
  duplicate offset (P1), *Scale text* for multi-resize (P1), Mod+arrow 1-px nudge (P2),
  remote transform hints (09 §2.4), snap to grid (P2). (Text-box resize rules: SL-13, §6.2
  "As built".)

---

## 6. Element kinds

### 6.1 Text

**Create**: Insert › Text box (`slides.insert.textBox`, key **T** in the canvas scope). The next
click on the slide creates an auto-width box (`wrap: false`) at that point with the caret inside;
a drag creates a fixed-width box (`wrap: true`) of the dragged width. Keyboard creation: the
command with no pointer inserts a 960 × 120 su box at the slide center. Default style: theme
`shapeStyle.text` (05 §2.7), `autofit: resize`. An empty text box that loses editing is **deleted**
(part of the same undo step as its creation).

**Editing engine**: one `SlideTextEditor` at a time — the vendored `super_editor` configured as a
shrink-wrapped, non-scrolling editor whose document maps 1:1 to the Slides Delta schema (02 §4.1)
through a `SlidesDeltaMapper` (paragraphs, list items, tasks; attributions for every inline
attribute). It sits as an overlay exactly over the element's text rectangle (rotation and flip
applied via a transform), so the caret and selection align with the static rendering. Static text
(non-edited bodies, thumbnails, presenting) is painted by the scene painter from the same resolved
styles; golden tests assert identical line breaks between both (§22).

**Decided (v2 review, Q20): super_editor overlay.** The vendored super_editor
(IME/selection/clipboard proven in Write, spellcheck integration exists) is the text editor of
text boxes, confirmed by a timeboxed spike at the start of M9 (Slides 12 work package SL-4)
measuring open-editor latency (< 50 ms target) and the line-break equality test. Only if the
spike fails both does the fallback — a custom `EditableText`-based rich editor (lighter, but IME,
multi-paragraph selection, lists and RTL rebuilt) — get a decision record.

**Decided by spike SL-4: super_editor overlay confirmed** (prototype in
`wonky_slides/lib/features/text_editing/`, tests in `wonky_slides/test/features/text_editing/`; no
super_editor patch needed). The fallback is not needed. How the overlay matches the static text
*by construction*:

- **Same paragraph model, same styles.** A custom style phase (`SlidesTextStylePhase`) builds the
  core `TextParagraphs` of the document being edited (the model the `FlutterTextLayoutEngine`
  lays out) and gives every paragraph view model its *display* text (caps, U+2028) with one
  presentation-only attribution per styled run whose `TextStyle` has the engine's values (font,
  weight, size × auto-fit, height + even leading, letter spacing, decorations, highlight). Our
  component (`SlidesTextComponent`) puts super_editor's `TextComponent` at the paragraph's text
  indent with full layout width (alignment happens inside the paragraph, as in the engine), the
  view model padding carries space before/after, and list markers are the engine's own marker
  paragraphs at the engine's offsets. `TextScaler.noScaling`; stylesheet without padding or max
  width.
- **Same geometry.** `TextEditGeometry` rebuilds the element with the body being edited through
  `SlideSceneBuilder.buildElement` and takes the text node's transform chain (element rotation and
  flips, group space, shape text rectangle, insets, vertical anchor) and layout (width,
  `fitScale`, height). So auto-fit (`shrink` scale, `resize` growth) and anchors follow every
  keystroke (live auto-fit) without duplicated math. The overlay is laid out in su at that width
  and transformed by zoom × that matrix; the static text of the edited element is left out of the
  stage while editing (`sceneWithoutText`). A blank body is laid out as one zero-width character
  with the paragraph's attributes (the caret of an empty box or placeholder sits on the first
  line; no prompt).
- **Mapping.** `SlidesDeltaMapper`: paragraph → `ParagraphNode`, `list: bullet|ordered` →
  `ListItemNode`, `check|unchecked` → `TaskNode`, `indent` → node indent, other block attributes
  in node metadata `slidesBlock`; `bold/italic/underline/strike/code/script` → super_editor's
  attributions, `link` → `LinkAttribution`, valued attributes → `SlidesValueAttribution`; soft
  break U+2028 ⇄ `"\n"` in the node. Enter at the end of a paragraph keeps its paragraph
  attributes (`SlidesParagraphInheritReaction`; super_editor starts a plain paragraph there).
- **Editor setup.** `SuperEditor` inside its own non-scrolling, shrink-wrapped `CustomScrollView`
  (super_editor attaches to the nearest vertical `Scrollable`, which must not be the canvas's),
  mouse gestures, IME input, no editor history; super_editor's undo/redo and Esc actions are
  replaced by host keys (Esc → exit; Mod+Z / Mod+Shift+Z / Ctrl+Y → write pending typing, then the
  shell's undo stack); caret 2 logical px at any zoom; links don't open while editing.
- **Writes and undo.** Edits stay in the document and are written as `SetText` after 300 ms idle
  and on exit (02 §4.4). Each write is one `slides.rows` entry pushed with the coalescing key
  `slides.text:<elementId>` (one step per burst). Typing entries (`SlidesTypingUndoEntry`)
  coalesce by **composing** updates of the same row: the kit's `RowsUndoEntry.coalesce` appends
  changes, and the rows undo inverts each change against the current model, skipping columns whose
  value isn't the change's `after`, so two appended writes of one `text` column undid only the last
  one — fixed since in `wonky_revlog` (`composeRowChanges`), and `SlidesTypingUndoEntry` now
  uses the kit's coalescing. Undo, redo and collaborators' changes of the body are
  patched into the document (SE-2 `ApplyDocumentPatchRequest`, caret clamped); unwritten local
  edits win (LWW, soft lock).

Measurements (widget-test VM: debug JIT, software raster; slower than a release web build):

| Check | Result |
|-------|--------|
| Glyph equality: every character's box in the overlay's `RenderParagraph` vs the engine's `ui.Paragraph` (±0.01 su), paragraph origins and heights, overlay height = static content height | Equal for wrapped text, mixed inline styles (bold, italic, sizes, caps, letter spacing, superscript, highlight, underline, strike, mono), title/caption styles, center/right/justify, line height, space before/after, bullets on 3 levels, numbered with `listStart`, checklists, empty paragraphs, soft breaks, RTL, empty body, filled and empty title placeholders, shrink-to-fit shape (scale < 1, middle anchor), rotated 30° and 90°, and after typing (resize growth, live shrink) |
| Screen position of a glyph at 30° / 90° | Equals the static transform of the engine's glyph box (±0.01 px) |
| Paint comparison (static frame vs. stage without the text + overlay, real bundled fonts) | 0 differing px of 10,594 / 10,242 / 5,714 inked px (0°×0.5, 0°×0.75, 90°×0.5), max channel delta 0; negative control (overlay off by ≈ 0.35 px): 63 % of inked px differ |
| Delta ⇄ document round trip | Unchanged for every inline and block attribute of 02 §4.1, lists/tasks/levels, soft breaks, emoji, empty bodies |
| Pointer at 0°, 30°, 90° | Click puts the caret before the clicked glyph; a drag selects to the glyph under the pointer |
| Web IME (super_editor web path, simulated) | The hidden input gets the edited paragraph's transform = zoom × rotation |
| Enter text editing (controller + document + geometry + first frame) | median 10–12 ms, max 18 ms (first open in a fresh VM ≈ 190–220 ms: JIT) — budget < 50 ms |
| Typing (IME delta → document → style phase → layout → paint) | p50 5–6 ms, p95 7–8 ms per keystroke; geometry rebuild 0.15 ms — budget < 16 ms p95 |

Open for SL-13 (`TODO.md`): IME composition, dead keys and RTL by hand in Chrome and Safari (web
build); flush pending typing before menu/toolbar undo too (only the overlay's keys do it now);
selection chrome from `TextEditGeometry` while typing (the stored frame updates on write);
`Localizations` locale reaches the overlay's paragraphs but not the engine's (CJK fallback);
caps transforms that change length (ß → SS) show the source text while editing; checklist
glyphs ☑/☐ are missing from the bundled fonts (both renderers).

**Behavior**:

| Feature | Behavior | Command |
|---------|----------|---------|
| Bold / italic / underline / strike | Toggle on selection; collapsed caret sets typing attributes | `slides.format.bold` ⌘B, `…italic` ⌘I, `…underline` ⌘U, `…strikethrough` ⇧⌘X |
| Font, size, color, highlight | Toolbar/inspector; size steps 8 10 12 14 18 24 28 32 36 40 48 56 64 72 96 120 144 200 | `slides.format.font {family}`, `…fontSize {size}`, `…increaseFontSize` ⇧⌘. / `…decreaseFontSize` ⇧⌘, , `…textColor {color}`, `…highlight {color}` |
| Superscript / subscript | | `slides.format.script {value: super\|sub\|none}` ⌘. / ⌘, |
| Capitalization | All caps, Small caps, Title case, None | `slides.format.caps {value}` |
| Letter spacing, line spacing, space before/after | Inspector › Text | `slides.format.letterSpacing`, `…lineHeight`, `…paragraphSpacing {before?, after?}` |
| Alignment | Left/center/right/justify | `slides.format.align {value}` ⇧⌘L / ⇧⌘E / ⇧⌘R / ⇧⌘J |
| Vertical anchor | Top/middle/bottom | `slides.format.anchor {value}` |
| Lists | Bulleted ⇧⌘8, numbered ⇧⌘7, checklist ⇧⌘9; Tab / Shift+Tab indent/outdent list items (and plain paragraphs, levels 0–8); list style picker (bullets glyphs, numbering styles, start number) | `slides.format.list {type}`, `…indent`, `…outdent`, `…listStyle {style}`, `…listStart {n}` |
| Autoformat | `- `, `* ` → bullet; `1. ` → numbered; `[ ] ` → checklist; `--` → em dash (P1); smart quotes (P1, Settings › Slides) | — (typing) |
| Paragraph style | Apply a theme text style (Title, Subtitle, Heading, Body, Body 2, Caption, Quote, Attribution, Big number, Label) | `slides.format.textStyle {key}` ⌥⌘1…⌥⌘9 in that order (Label has none) |
| Links | Mod+K opens the link popover: URL, or **Slide in this deck** (searchable list), *Remove* | `slides.insert.link {url? \| slideId?}`, `slides.text.removeLink` |
| Auto-fit | Do not autofit / Shrink text on overflow / Resize shape to fit text | `slides.format.autofit {mode}` |
| Text insets | Inspector › Text › Insets | `slides.format.insets {t,r,b,l}` |
| Clear formatting | Removes inline attributes (keeps paragraph lists) | `slides.format.clear` ⌘\ |
| Soft line break | Shift+Enter inserts U+2028 | — |
| Exit editing | Esc (selects the box), clicking outside, Mod+Enter (P1: same) | `slides.text.exitEditing` |

Applying a format command with **element(s) selected but not editing** applies it to **all text**
of every selected text-capable element (one undo step; bodies soft-locked by others are skipped
with a toast "Skipped 1 text box Anna is editing").

**Overflow**: with `autofit: none`, text that overflows is drawn beyond the box; in the editor a
small red `+` badge marks overflow (P1). **Shrink**: derived scale (02 §5.1), shown in the
inspector as "Text shrunk to 85 %". **Resize**: effective height grows; the selection box follows.

**Undo**: typing bursts coalesce (suite 08 §3.1 rule 4) and are persisted after 300 ms idle and on
exit (02 §4.4) — one step "Typing" per burst; formatting commands are one step each.

### 6.2 Placeholders

- Instances inherit frame and style from their layout placeholder until changed; the inspector
  shows "From layout: Title" with **Reset to layout** (`slides.element.resetPlaceholder`).
- Empty text placeholders show **prompt text** (from the layout placeholder's prompt, default
  "Click to add title" / "Click to add text" / "Click to add subtitle"); never presented,
  thumbnailed or exported.
- Picture/chart/table/code placeholders show an icon button in the center: click opens the
  matching insert flow; the inserted element takes the placeholder's frame and becomes the
  placeholder's instance (`placeholderOf`), so a later layout change moves it with the layout.
- Deleting a placeholder instance's content leaves the empty placeholder; deleting the
  (selected) empty placeholder removes it from the slide (it can be restored with *Reset slide*).

### 6.2.1 As built (SL-13): text editing, format commands, placeholders

- **Code.** `wonky_slides/lib/features/text_editing/`: SL-4's overlay (`SlideTextEditController`,
  `SlideTextEditorOverlay`, mapper, components, `TextEditGeometry` — now also the live derived
  box `frame`) plus `text_editing_host.dart` (`textEditingOf(editor)` → `SlideTextEditing`: one
  session per deck, `begin(id, {at, caretOffset, insert, selectAll})`, `end`, `commit`,
  `placeCaretAt`, the soft-lock hook `TextEditLocks`, `typeToEdit`), `text_editing_layer.dart`
  (`SlideTextEditingLayer`: the overlay at the slide origin inside the `slidesText` scope) and
  `text_format.dart` (`TextFormatScope`, `TextFormatState`, `TextFormatter`, `paragraphsOf`,
  `effectiveList`). `features/elements/text/`: `TextBoxTool` (a `CanvasTools` box tool, SL-14's
  registry), `text_toolbar.dart` (contextual *Text* controls), `text_inspector_section.dart`
  (Inspector › Format › Text), `text_dialogs.dart` (value/choice/link `WonkyDialogSpec`s).
  `lib/commands/text_commands.dart` registers every `slides.format.*` text command,
  `slides.format.letterSpacing` / `insets` (new ids), `slides.text.exitEditing`,
  `slides.text.removeLink`, `slides.insert.textBox`, `slides.insert.link`,
  `slides.element.setLink` / `removeLink`, `slides.element.resetPlaceholder`; SL-12's
  `slides.element.activate` edits text-capable elements (`{x, y}` = caret point).
- **Activation.** Double-click (caret at the click point via the overlay's document layout,
  after the first layout), Enter (caret at the end), a printable character with one
  text-capable element selected (`typeToEdit` in the canvas scope, before the keymap: with a
  box selected, T types a "T"), a single click (no drag) on an empty text placeholder
  (*Click to add title*), creating a text box. The canvas keeps the keyboard focus during
  the click, so the host focuses the editor explicitly after layout. Editing ends on Esc /
  Mod+Enter / `slides.text.exitEditing` (box stays selected), a press outside the box (the
  press then selects as usual), any selection or slide change, losing edit access, the
  element disappearing. A press inside the box but beside the laid-out text moves the caret
  to the nearest position; a right-click inside opens `context.text`.
- **Keys.** The `slidesText` scope is a `Focus` around the overlay: super_editor first (typing,
  IME, caret, clipboard, Mod+A, Enter, Shift+Enter), then host keys (Esc, Mod+Enter, Tab /
  Shift+Tab → `slides.format.indent` / `outdent` on any paragraph, Mod+Z / Mod+Shift+Z →
  write pending typing + shell undo/redo), then `slidesText` bindings and chords with
  Mod/Alt of the global scope (format commands, link, comments); everything else is passed
  to the platform and never reaches the canvas scope (no nudges, Delete, tools). super_editor's
  own Cmd+B / Cmd+I are removed so bold/italic are commands (one undo step).
- **Writes and undo.** Typing as SL-4 (300 ms idle, "Typing" steps coalescing per burst).
  `DeckDocumentController.beforeUndo` / `beforeRedo` (new shell hook) and every format command
  write pending typing first. Format commands while editing format the selected range with
  `FormatText` (one step; the document is patched back from the stored body, selection kept);
  with a collapsed caret they change super_editor's typing attributes (no step, like Write).
  Without editing they format whole bodies of the selected text-capable elements (group
  children included), skipping bodies `TextEditLocks.heldBy` names (toast). Paragraph
  commands (indent, list toggles, list style) write one `FormatText` per paragraph in the
  same step; *Increase/Decrease font size* steps each run from its effective size (steps of
  §6.1 continued 240 … 800). Bold off on theme-bold text writes `weight: 400`.
- **Text boxes.** The tool (toolbar toggle, menu, T) arms `armedTool = 'text'`; a click creates
  an auto-width box (`wrap: false`, `autofit: resize`), a drag ≥ 8 su a fixed-width box; the
  palette and agents insert 960 × 120 su at the slide center (agents get it selected, not
  edited; optional `text`). A text box (not a placeholder) that is blank when editing ends is
  deleted; when its creation is still the top undo step that step is dropped
  (`UndoService.discardTop`), else the deletion is its own step. Resizing an auto-width box by
  hand switches it to `wrap: true` in the same step (resize frame arg `wrap`); top/bottom
  handles of `autofit: resize` boxes write the minimum height (the scene grows it).
- **Placeholders.** Prompts come from the layout (scene `PromptNode`, edit purpose only); the
  edited body's prompt/text is left out of the stage while editing. *Reset to layout* is the
  new core op `ResetPlaceholders(elementIds)` (frame, rotation, `textStyleJson`, fill, stroke,
  effects, opacity → null; text kept). **Box-default lists:** paragraphs without a `list` and
  without their own `style` take `textStyleJson.defaults.list` / `listStyle` / `listStart` /
  `indent` from the box (placeholder chain) in `TextParagraphs` — so the static engines, PDF
  and the overlay draw a body placeholder's bullets alike; `listStyle: none` on a paragraph
  turns a default list off (what the list toggle writes). Picture/chart/table/code
  placeholder buttons belong to SL-15/SL-31/SL-32.
- **Links.** `slides.insert.link {url? | slideId?}` (Mod+K): a range gets the `link`
  attribute, a caret gets the URL (or "Slide n") inserted as linked text; without editing it
  sets the element link. The link popover of 04 §13.5 is a `WonkyDialogSpec`
  (`dialog.slides.link`: target select — web address, every slide, element actions — and the
  address field, *Remove link*), MCP-operable.
- **Chrome.** The contextual toolbar's *Text* controls (04 §6.2) mirror `TextFormatState`:
  style, font (theme fonts + bundled families), size field, B/I/U toggles, text color and
  highlight split buttons (`WonkyColorPicker` with theme swatches), link, align/anchor,
  lists + list styles + restart numbering, line spacing + space before/after, outdent,
  indent, clear. Inspector › Text has style, font, size, B/I/U/S/super/sub, caps, letter
  spacing, alignment, anchor, line spacing, space before/after, lists and list style,
  text fitting and insets. The toolbar and the section listen to the host (caret moves).
- **Hook for SL-21.** `textEditingOf(editor).locks = …` (`request` may show the soft-lock
  popover asynchronously; `claim`/`release`; `heldBy`).
- **Not built / open (TODO.md):** IME, dead keys, emoji picker and RTL checked only in widget
  tests (simulated IME incl. a composition) — check by hand in Chrome and Safari; autoformat
  (`- `, `1. `, `[ ] `); the overflow `+` badge (P1); Mod+click-to-follow links; overwritten
  text review and the soft-lock popover (SL-21); localized built-in prompts; caps
  transforms that change length show the source text while editing; checklist glyphs.

### 6.3 Shapes

**Library** (`Insert › Shape ▸`, toolbar shape menu; `slides.insert.shape {geometry}`; key **S**
repeats the last shape, P1):

| Category | Shapes (geometry keys) | Pri |
|----------|------------------------|-----|
| Basic | rect, roundRect, ellipse, triangle, rightTriangle, diamond, pentagon, hexagon, octagon, parallelogram, trapezoid, donut, arc, blockArc, pie, chord, frame, halfFrame, plus, cross, cylinder, cube, can, heart, cloud, moon, sun, lightning | P0 (first 12), P1 rest |
| Arrows | arrowRight, arrowLeft, arrowUp, arrowDown, arrowLeftRight, arrowUpDown, chevron, homePlate, notchedArrow, curvedArrow, circularArrow, uTurn | P0 (first 6), P1 |
| Stars & badges | star4, star5, star6, star8, star12, burst, ribbon, wave, seal | P1 |
| Callouts | speech, speechRound, thought, calloutRect, calloutLine, banner | P0 (speech, calloutRect), P1 |
| Flowchart | process, decision, terminator, document, data, manualInput, predefinedProcess, connector, offPage, delay, storage | P1 |
| Brackets | brace, bracket, doubleBrace | P1 |
| Custom | `custom` (SVG path; created by pasting SVG paths, P2 edit points) | P2 |

**Drawing**: after choosing a shape the cursor becomes a crosshair; click inserts at 240 × 240 su
(arrows 320 × 160), drag sizes it (Shift = 1:1, Alt from center). Esc cancels the tool. One undo
step "Insert shape". Default style: theme `shapeStyle.shape` (accent1 fill, no stroke).

**Adjust handles**: yellow diamonds (`slidesAdjustHandle`) for geometry parameters (corner radius,
arrow head size, star inner radius…); dragging writes `dataJson.adjust` on release.

**Change shape** (`slides.shape.change {geometry}`): keeps frame, text, style, builds, matchKey.

**Quick styles** (P1): a row of 8 theme-based styles (solid accent fills 1–6, outline, soft tint)
in the toolbar fill menu (`slides.shape.applyQuickStyle {index}`).

Text in shapes: double-click/Enter/typing edits; defaults `anchor: middle`, `align: center`,
`autofit: shrink`.

### 6.4 Lines, arrows and connectors

- Tools: **Line** (L), **Arrow**, **Elbow connector**, **Curved connector** (P1), all under
  Insert › Line ▸ (`slides.insert.line {routing, arrow}`). Drag from start to end; Shift snaps to
  45°. Click without drag inserts a 400 su horizontal line.
- **Connection sites**: hovering a shape with a line tool (or dragging an endpoint) shows its sites
  as small circles (top, right, bottom, left, center + geometry-specific); dropping on a site
  **glues** the endpoint (`connect: {elementId, site}`), on the shape body glues to the nearest
  site. Glued endpoints follow the shape when it moves (derived routing, 02 §6.3); selection shows
  glued endpoints as filled green dots, free ones as hollow.
- **Elbow routing**: orthogonal path avoiding the two connected shapes' boxes with 24 su clearance;
  a midpoint handle per inner segment moves it across its direction (stored as `waypoints`: the
  route's corners). **Curved** connectors have one bend handle at the curve's middle; dragging it
  bends the curve through the pointer (`waypoints: [bend]`). Both write
  `slides.line.setWaypoints {id, waypoints}` (one step; `[]` restores the automatic route);
  moving an endpoint re-routes automatically (waypoints cleared). As built: SL-44, §14.1.
- Endpoint handles replace the resize box for single lines; rotation handle hidden (angle comes
  from endpoints).
- Arrowheads, width, dash, color, cap in toolbar/inspector (`slides.line.setArrow {end, style}`,
  `slides.format.stroke {…}`).
- Deleting a connected shape leaves its connectors with the last stored endpoint.

### 6.5 Images

#### 6.5.1 Insert

| Source | Flow | Command |
|--------|------|---------|
| Upload | `file_picker` (png, jpg, jpeg, gif, webp, svg; no BMP) → upload | `slides.insert.image {source: upload}` |
| Drag & drop | From the OS onto the canvas (web drop zone; `desktop_drop` deferred with desktop, suite 01 A13); several files insert cascaded | — |
| Paste | Image data from the OS clipboard (§12.5) | `shell.edit.paste` |
| Wonky Drive | Drive picker filtered to images (D2 `file` kind) → server copies the file into the deck | `slides.insert.image {source: drive, fileItemUuid}` |
| By URL | URL dialog; fetched through the server image proxy (`files.fetchImage`, generalized from Sheets' `sheets.fetchImage`; SSRF rules of suite 13) and stored as an upload | `slides.insert.image {source: url, url}` |
| Placeholder | Picture placeholder button or drop onto a picture placeholder (fills and crops to cover) | — |

- Uploads go through `FileEndpoint` with a client-generated `fileUuid` (suite 12 §1.1);
  `src = wonky-file://<fileUuid>`. Offline: bytes in `LocalPendingUpload` (render from local bytes,
  upload with backoff). Quota (D3) is checked before upload: over quota →
  *"You're out of storage — free up space in Wonky Drive"* dialog, nothing inserted.
- Size: natural size at 1 px = 1 su, scaled down to fit 80 % of the slide; placed centered (or at
  the drop point). Images > 40 MP are downscaled client-side to 40 MP (JPEG q 0.9 / PNG); SVG is
  rasterized at 2× its intrinsic size (max 4096 px) and the SVG kept as the original (P2: vector
  SVG rendering); BMP isn't supported (the toast below); animated GIFs animate in the editor and presenting (first frame in
  PDF/thumbnails).
- Unsupported/corrupt file → toast "Couldn't insert 'x.heic' — this image type isn't supported."

#### 6.5.2 Replace and reset

- *Replace image* (`slides.image.replace {source}`) keeps frame, crop proportions (re-fit to cover
  the same frame), mask, adjustments, builds and matchKey.
- *Reset image* (`slides.image.reset`) clears crop, mask and adjustments and restores natural
  aspect (keeps width).

#### 6.5.3 Mask

*Mask with shape ▸* (`slides.image.mask {geometry}`): any basic shape; adjust handles of the shape
apply. `mask: null` removes. Masking draws the image clipped to the geometry inside the frame.

#### 6.5.4 Crop mode

Double-click (or `slides.image.crop`, Enter on a selected image): the full image appears dimmed
outside the crop rectangle; drag the **crop handles** to change the visible area, drag the image
to reposition it inside the frame, aspect presets in a floating bar (Free, Original, 1:1, 4:3,
16:9, 3:2, 9:16), **Fill** / **Fit** buttons. Enter or clicking outside commits (one undo step
"Crop image", writes `dataJson.crop` and frame); Esc cancels.

#### 6.5.5 Adjustments (P1)

Inspector › Image: sliders Brightness, Contrast, Saturation, Temperature (−100…100), Blur (0…40),
toggles Grayscale/Sepia/Invert; *Reset adjustments*. Live preview while dragging (the canvas
redraws the image with the dragged value, nothing written — `ImageAdjustPreview`, SL-44); written
on release (`slides.image.adjust {…}`); applied with a `ColorFilter` matrix on screen and baked
into PDF images by the core renderer (same matrix math, 10).

#### 6.5.6 Other

Alt text (§17.1), transparency (`opacity`), shadow/border via common style, *Download original*
(`slides.image.downloadOriginal`, needs download permission).

### 6.6 Tables

- **Insert**: Insert › Table ▸ `WonkyTableSizePicker` (suite 02 §4.10; up to 20 × 20; larger tables up to 50 rows × 20 columns through the command's arguments in the palette) →
  `slides.insert.table {rows, cols}`; default width 80 % of the slide, row height from the theme
  body size; style `theme`.
- **Cell selection**: click into a cell edits its text; drag across cells or Shift+arrows (from
  `slidesTable` scope) selects a cell range (highlight `slidesTableSelection`). Esc from editing
  selects the cell; Esc again selects the table.
- **Keyboard**: Tab / Shift+Tab next/previous cell (Tab in the last cell adds a row,
  `slides.table.insertRow {below}`), arrows at text edges move between cells, Enter in range
  selection edits the active cell.
- **Structure** (context menu, inspector, `slides.table.*`): insert row above/below
  (`insertRow {above|below, count}`), insert column left/right, delete rows/columns, delete
  table, **merge cells** / unmerge (P1), distribute rows/columns evenly, resize by dragging inner
  borders (writes axis `size`, one step), header row / first column / banded rows / banded
  columns / total row toggles (`slides.table.setOptions {…}`).
- **Cell formatting**: fill (`slides.table.setCellFill`), borders (`TableBorderPicker`: all,
  outer, inner, horizontal, vertical, top, bottom, left, right, none + width/style/color →
  `slides.table.setBorders`), vertical align, padding; text formatting applies to selected cells'
  whole text (like §6.1 element-level formatting).
- **Paste**: TSV/HTML tables or Sheets cells into a selected cell range fill cells from the
  active cell, adding rows/columns up to the limit (§12.4).
- Rows grow to fit text (derived); the table's frame height is the minimum (02 §6.5).

### 6.7 Icons and emoji

- **Icon picker** (`slides.insert.icon` → dialog, 04 §13.6): search over the Lucide set (~1,600
  icons, names + tags), categories, recently used, stroke width (1–3), color (theme colors). Insert
  as a 160 × 160 su `icon` element (aspect locked), stroke color `theme:text1` by default.
- **Emoji** (P1): emoji picker (shared widget, extracted from Write's emoji feature to
  `wonky_ui`, suite agent) → `slides.insert.emoji {char}` as an `icon` element with `set: emoji`
  (240 su). Emoji typed inside text stay text: while a body is edited, *Insert › Emoji* types the
  picked emoji at the caret (SL-44; the picker is `package:wonky_app/emoji.dart` with Slides' key
  prefix).
- Double-click an icon → picker to replace (keeps frame, color, builds).

### 6.8 Code and charts (object behavior)

Code and chart elements select, move, resize, rotate (code: rotation allowed but discouraged —
the inspector warns), group, lock and z-order like other elements. Content editing: code →
[07](07-code-blocks.md) (`slides.code.*`), charts → [08](08-charts-from-sheets.md)
(`slides.chart.*`). Insert commands: `slides.insert.code {language?}` (placement per 07 §3.4),
`slides.insert.chartFromSheets` and `slides.insert.chart {type}` (native, P1).

### 6.9 Element links and actions

Inspector › Link (or Mod+K with an element selected): *URL*, *Slide* (picker), *Next slide*,
*Previous slide*, *First/Last slide*, *End show* → `linkJson`
(`slides.element.setLink {…}` / `removeLink`). Presenting: clicking the element follows the link
(external URLs use the external-link confirm of suite 03 §1 — not in an audience view: they
open on the presenter's screen, 10). The editor shows a small link badge on hover.

### 6.10 As built (SL-10): rendering rules of the element kinds

The scene builder (`SlideSceneBuilder`, core) draws every kind from the resolved rows; these
rules are normative for all renderers (canvas, thumbnails, presenting, PDF):

- **Theme defaults** (05 §2.7): unset `fillJson`/`strokeJson`/`textStyleJson` take the
  theme's `shapeStyle` entry of the kind (`text`, `shape`, `line`, `icon`) at render time —
  nothing is baked into rows, so changing the theme restyles default objects. The kind default
  box text properties sit *under* the element's (and placeholder chain's) values.
- **Text** (§6.1): insets default to `[8, 16, 8, 16]` su when the chain sets none; auto-fit
  defaults are `resize` for text boxes and `shrink` for shapes; anchors default to `top` (text)
  and `middle` (shapes). `resize` grows the box downwards and `wrap: false` sizes the box to
  its text — both as *derived frames* on the scene (`SlideScene.frames`), which selection
  chrome uses. Flipped shapes keep their text readable (the text is not mirrored). Field
  placeholders (slide number, footer) use the paragraph attributes of the layout definition.
  Super/subscript runs are scaled to 65 %; the Flutter engine does not raise/lower them yet
  (the core engine records `baselineShift`).
- **Shapes** (§6.3): `ShapeLibrary` has all 70 keys of the table, each with outline parts
  (cube/cylinder/ribbon faces are shaded ±15–20 % in OKLCH lightness; brackets, `arc` and
  callout lines are stroke-only parts), adjusts (`dataJson.adjust`, values clamped; angles of
  `arc`/`pie`/`chord`/`blockArc` are `start`/`end` turn fractions; callout tails are
  `tipX`/`tipY` fractions of the frame, may lie outside it), handle tracks for the adjust
  handles, the text rectangle and connection sites (`top`, `right`, `bottom`, `left`, `center`
  + indexed geometry sites such as polygon corners, star points, arrow tips, callout tips).
  `textBounds` is `{x, y, w, h}` in fractions of the frame. `custom` paths are SVG path data
  in a 0..1000 box (`M L H V C S Q T A Z`).
- **Lines and connectors** (§6.4): `connect.elementId` is the base-62 element id (a dashed
  UUID is accepted); glued endpoints are derived from the target's current frame (rotation and
  flips applied) and fall back to the stored point when the target is gone. Elbow routes pick
  the cheapest axis-aligned candidate (L, Z, around-the-boxes and between-the-boxes routes;
  length + 2 × clearance per bend) whose inner segments avoid both glued shapes inflated by
  24 su and whose first/last segments leave along the sites' directions; `waypoints` are
  joined orthogonally. Curved routes are one cubic with control points 40 % of the distance
  (≥ 24 su) out along the site directions. Arrowheads (`triangle`, `stealth`, `open`,
  `diamond`, `circle`; `bar` draws as `open` until P1) are separate scene nodes of length
  `max(3 × width, 6) × {s 0.75, m 1, l 1.5}`, and the shaft is trimmed under filled heads.
  Routes are exposed on the scene (`SlideScene.routes`) for endpoint handles and hit tests.
- **Images** (§6.5): `crop` fractions map onto the natural size (a downscaled upload maps its
  natural pixels onto the decoded ones); `mask` uses the shape library's fill path;
  adjustments are one 4×5 color matrix (`ImageAdjust`, Flutter `ColorFilter.matrix`
  convention, offsets 0..255) and `adjust.blur` is a blur sigma in su. A stroke draws over the
  image along the mask (or frame).
- **Tables** (§6.6): columns with a `size` keep their proportions and are scaled to the frame
  width (null sizes share the rest); rows grow to fit their text (+ cell padding), merged
  cells add their extra need to their last row, and the grown height is a derived frame.
  Theme areas (05 §2.8) apply in the order cell fill ▸ header/total ▸ bands ▸ first column ▸
  body; theme borders skip the inside of merges; cell borders (`"width|style|color"`,
  `dashed`/`dotted` accepted) draw on top; the theme radius clips the table.
- **Icons** (§6.7): drawn as glyphs of an icon font through `SlideIconSource` (the app maps
  Lucide names to its icon font, SL-14; emoji use the emoji family), colored with the stroke
  color; an unknown glyph draws a neutral rounded frame.
- **Code and charts** (§6.8): code uses `BasicCodeLayout` until SL-26 (state per scene
  purpose — edit: the inspector's state, thumbnails/print: the last; tokens of the shared
  tokenizer, theme palette and mono font, a monospace grid auto-fitted to the box between 8
  and 40 su, line numbers, a title bar, the theme's corner radius and code shadow). Charts are
  laid out by a `ChartSceneSource` (SL-27/SL-32); without one a placeholder card with three
  bars in the chart palette is drawn.
- **Effects**: shadows are blurred silhouettes of the element (blur radius → sigma ÷ 2), glow
  is a zero-offset shadow with spread, `blur` a layer blur.
- **Hit testing** (`SceneHitTest`, core): topmost element whose *drawn* content is under the
  point (fills by containment, strokes and lines within the tolerance, text line boxes, image
  masks); the canvas may still prefer the frame for text boxes (§3.2).

---

### 6.11 As built (SL-14): shapes, lines, icons, groups, format painter

- **Code.** App `features/elements/{shape,line,icon,style,common}/`, `features/format_painter/`,
  `commands/{object,style}_commands.dart`, the canvas tool hook `features/canvas/canvas_tools.dart`;
  core `package:wonky_slides_core/icons.dart` (`LucideGlyphs` name → code point map generated
  from `lucide_icons_flutter` by `tool/generate_lucide_glyphs.dart`, `LucideCatalog`). (The plan
  named `elements/{shape,line,icon,group}`; groups need no folder of their own — their commands
  are in `object_commands.dart`, the Arrange/Accessibility sections in `elements/common/`.)
- **Insert tools.** `slides.insert.shape {geometry}` / `slides.insert.line {routing, arrows}`
  from the UI arm a canvas tool (`DeckEditorController.armedTool` = `shape:<key>` /
  `line:<routing>:<arrows>`); with a frame (`x, y, width, height` / `start`, `end`) or from an
  agent they insert directly (agents: centered default size). S / L arm the last shape / line.
  Armed tools are `CanvasTool`s resolved by `CanvasTools` (a registry other packages can add
  to): box gestures (click = default size centered on the click — 240 su, natural-aspect
  shapes such as arrows 320 × 160; drag = the box, Shift 1:1, Alt from the center, snapped to
  objects/guides, Mod disables snapping), line gestures (endpoints glue to connection sites,
  Shift 45°, click = a 400 su horizontal line), pick gestures (format painter). Line tools show
  the sites of the shape under the pointer. Esc (`slides.select.escape`) disarms; inserting
  selects the new element and returns to Select. Inserts write no style (theme defaults at
  render time); arrows write `strokeJson.{start,end}Arrow: triangle`. *All shapes…* =
  `slides.insert.shape {pick: true}` (gallery dialog, MCP-describable).
- **Icons.** `LucideIconSource` (every `SlideRenderer`'s default) draws glyphs with the weighted
  Lucide fonts: stroke width 1 / 1.5 / 2 / 2.5 / 3 → `Lucide200…600` (never used as
  `const IconData`, so icon-font tree shaking keeps them whole). `slides.insert.icon {name,
  strokeWidth, color}` (picker without a name), `slides.insert.emoji {char}` (shell
  `WonkyEmojiPicker`, 240 su), `slides.icon.replace {name?}` (picker; double-click / Enter on an
  icon), `slides.icon.setStrokeWidth {value}` (new ids). Names may be aliases; the canonical
  name is stored.
- **Shapes and lines.** `slides.shape.change {geometry}` keeps frame, text, style, builds and
  `matchKey`, drops `adjust`/`path`; `slides.shape.applyQuickStyle {index}` writes fill, stroke
  and `textStyleJson.defaults.color` (the theme's `quickStyles`, else eight defaults: accent
  1–6 solid, outline, soft tint); `slides.line.setArrow {end: start|end|both, style?, size?}`
  merges the arrow keys into `strokeJson`; `slides.line.setRouting {routing}` clears
  `waypoints`.
- **Style commands.** `slides.format.fill {color | fill | none}` (null color = theme default),
  `slides.format.stroke {color, width, dash, cap, join | none | reset}` (a merge into the
  stroke, keeping arrowheads; a value after `none` brings the border back), `slides.format.effects
  {shadow, glow: bool | object, blur | reset}` (merge; `shadow: true` = the theme shadow),
  `slides.format.opacity {value}` (1 clears). All take optional `ids`, apply to the kinds that
  have the property (fill: text, shape, icon; stroke: text, shape, line, image, icon) and are
  disabled with a reason otherwise. Without a value from the UI (*Fill…*, *Border…*,
  *Effects…*, *Opacity…*) they open the inspector section.
- **Groups.** `slides.arrange.group` (canvas scope: Mod+G and ⌥Mod+G) / `ungroup` (Mod+Shift+G,
  ⌥Mod+Shift+G) run the planner's `GroupElements` / `UngroupElements` (identity child space at
  creation, baking on ungroup, builds removed with the planner's warning as a toast), select the
  new group / the children and keep the entered group. Disabled reasons: fewer than two
  objects, placeholders, different parents.
- **Format painter.** `slides.format.paintFormat` captures the first selected element's style
  (`ElementStylePayload`: fill, stroke, effects, opacity; text-capable: `textStyleJson` and the
  longest run's inline + the first paragraph's block attributes; images: mask and adjustments)
  and arms the `paintFormat` pick tool; a click applies it (`{targetIds}`, one undo step) and
  disarms; a second click on the brush within 500 ms (or `{sticky: true}`) keeps it armed until
  Esc or the brush. Arrowheads are only painted onto lines. `copyStyle` / `pasteStyle {style?,
  ids?}` use the same payload (in-app clipboard; `copyStyle` returns it for MCP).
- **Inspector and toolbar.** Format sections Fill, Border, Effects (shadow, glow, opacity
  slider — one step on release), Line (color, weight, dash, ends, arrowheads + size, routing),
  Icon (name, *Replace icon…*, color, stroke width, background fill), Arrange (X/Y/W/H and
  rotation for top-level objects, align/distribute, order, flip, rotate, lock, name =
  `slides.element.rename`, *Edit inside group*) and Accessibility (alt text, *Decorative*,
  reading order position; `slides.element.editAltText {altText?, decorative?}` opens a dialog
  without arguments). The contextual toolbar has fill/border/line/icon color split buttons
  with the color picker (theme colors row, *Theme default*), weight, dash, quick styles, the
  *Change shape* gallery, start/end arrow and routing menus, icon stroke width and *Replace
  icon*; Insert › Shape ▸, the toolbar shape menu and Format › Shape › Change shape ▸ show the
  drawn gallery; context menus add Change shape ▸ (shapes), Line ▸ (lines) and *Replace icon…*
  (icons).
- **Not built:** see `TODO.md` "Shapes, lines, icons, groups, format painter leftovers (SL-14)".

### 6.12 As built (SL-15): images and tables

- **Code.** App `features/elements/image/` (`image_rules.dart` formats, sniffing,
  `SlidesImagePrep` (SVG → PNG at 2× ≤ 4,096 px, > 40 MP downscaled to PNG),
  `SlidesImageIo` picker/save; `image_geometry.dart` `ImageGeometry` (placement, cover crop,
  reset height) and `CropState`; `crop_mode.dart` `ImageCropMode`; `image_canvas.dart`
  (`ImageDrops`, `ImageCanvasLayer`: web drop zone + out-of-storage badges); `image_dialogs.dart`
  (source, URL, mask and Drive picker dialogs); `image_section.dart`; `image_clipboard*.dart`,
  `external_drop*.dart`), `features/elements/table/` (`table_cells.dart` `TableRange`,
  `TableCellSelection`, `TableGeometry`; `table_interaction.dart` `TableCanvasMode`;
  `table_sections.dart` Table/Cell sections + `TableBorderPicker`), `features/uploads/`
  (`SlidesPendingUploads` = `LocalPendingUpload` queue in `slides_uploads_<userId>.db`;
  `SlidesImageService` = the deck's `SlideImageResolver`), `commands/{image,table}_commands.dart`.
  Shared hooks added on the way: `features/canvas/canvas_interactions.dart`
  (`CanvasInteraction`: element-kind modes that take presses before the default gestures, paint
  on the overlay, filter the stage scene, add canvas widgets (`CanvasChrome`) and key scopes —
  the canvas region tries `slidesCrop`/`slidesTable` before `slidesCanvas`),
  `features/elements/element_activation.dart` (`slides.element.activate` per kind), the
  `tableSelection` canvas token (`slidesTableSelection`).
- **Images.** `slides.insert.image {source: upload|drive|url|clipboard|drop, url?,
  fileItemUuid?, x?, y?}` (no source: a source dialog; upload picks several files, inserted
  cascaded by 24 su). Bytes are validated (sniffed), prepared, quota-checked
  (`storageChecks.ensureRoom`, reason `image`, the deck's item — agents get the server's
  `quotaExceeded` instead), stored in the device queue and referenced as
  `wonky-file://<client uuid>` at once; the image renders from the local bytes until uploaded
  (`SlidesImageService` tries local bytes → queue → the session's resolver → the server: signed
  URL, polling while another user's upload is pending; `https://` sources through
  `file.fetchImage`). A refused upload shows "Not uploaded — out of storage" on the canvas and
  in the Image section with *Retry* (`slides.image.retryUpload`) and *Remove*
  (`slides.image.removeNotUploaded`, one step). *From Wonky Drive* copies the image file into the
  deck on the server (`file.copyToItem`, which now also accepts Drive files with an image MIME
  type); *By URL* fetches through **`file.fetchImage(itemUuid, url) → bytes`** (A-03-4, viewer
  access to the item; SSRF rules of `SafeImageFetcher`) and uploads the bytes like any insert.
  An empty picture placeholder (selected, or under a drop point) is filled with the image cropped
  to cover it (`ReplaceImage` with a cover crop). Activation (double-click / Enter): crop mode;
  on an empty picture placeholder *Insert image*.
- **Replace / reset / mask / adjust / crop.** `slides.image.replace {source…}` keeps frame, mask,
  adjustments, builds and match key and re-fits a cover crop (core: `ReplaceImage.crop`, additive).
  `slides.image.reset` removes crop, mask and adjustments and restores the natural aspect at the
  current width (one step: data + frame). `slides.image.mask {geometry | none}` (UI: a dialog
  with the basic shapes). `slides.image.adjust {brightness, contrast, saturation, temperature
  (−100…100, stored −1…1), blur (0…40), grayscale, sepia, invert | reset}` (UI without values
  opens Inspector › Image; sliders write on release). `slides.image.crop {crop, x, y, width,
  height}` writes crop and frame in one step "Crop image"; without `crop` the UI enters
  **crop mode**: the image's node leaves the stage scene and the overlay draws the whole image
  dimmed, the crop box bright with thirds and L-shaped handles; side/corner handles resize the
  box inside the image (Shift or a preset keeps the aspect), dragging inside moves the image
  under the box; the floating crop bar (a `CanvasChrome`) has the aspect presets Free, Original,
  1:1, 4:3, 16:9, 3:2, 9:16, *Fill*, *Fit*, *Cancel*, *Done*. Enter (`slides.image.cropApply`),
  *Done* or a click outside commit; Esc (`slides.image.cropCancel`) or *Cancel* leave. Crop
  mode ends when the selection or slide changes. `slides.image.downloadOriginal` saves the
  original bytes (download permission).
- **Tables.** `slides.insert.table {rows, cols, x?, y?, width?}` (palette: a rows/columns
  dialog; menu/toolbar: the size picker) — 80 % of the slide wide, centered, rows one line of
  the theme's table text + cell padding high, `style: theme` with header row and banded rows.
  With one table selected, the `TableCanvasMode` interaction takes presses inside the table
  (the outer 1.5 × 4 px band stays the table's: move and handles): a click edits the cell
  (SL-13's overlay with a **cell target** — `SlideTextEditController.cellRowId/cellColumnId`
  write `SetText(CellText)`, geometry from the table layout, `TextEditGeometry.ofCell`, the
  stage hides only that cell's text node), a drag or Shift+click selects a cell range
  (highlighted), dragging an inner column border resizes the two columns beside it (every
  column's width is written so the shares stay) and an inner row border the row's minimum
  height (`slides.table.resizeAxes {id, sizes}`, one step), right-click opens `context.table`.
  Cell keys while editing: Tab / Shift+Tab next/previous cell (Tab in the last cell inserts a
  row), arrows at the start/end of the text (Up/Down in the first/last paragraph) move to the
  neighbor cell, Esc selects the cell. `slidesTable` scope (a cell range, not editing): arrows
  / Shift+arrows (`slides.table.select*` / `extend*`), Tab / Shift+Tab, Enter
  (`slides.table.editCell`), Delete/Backspace (`slides.table.clearCells`), Esc
  (`slides.table.clearCellSelection`); typing edits the active cell. The cell selection is view
  state (`TableCellSelection`, axis ids, cleared when the table stops being the single
  selection); `slides.table.selectCells {id, row, column, rowSpan, colSpan}` sets it for agents.
- **Table commands** act on explicit `row`/`column`/`rowSpan`/`colSpan` args, else the cell
  selection, else the cell being edited, else the whole table: `insertRow {below}`,
  `insertColumn {right}` (relative to the range), `deleteRows`/`deleteColumns` (need cells;
  deleting every row/column deletes the table), `delete`, `mergeCells` (range > one cell) /
  `unmergeCells`, `distributeRows`/`distributeColumns` (laid-out sizes averaged),
  `setOptions {style, headerRow, firstColumn, bandedRows, bandedColumns, totalRow,
  cellPadding}`, `setCellFill {color | none}`, `setBorders {edges, width, style, color}` (edges
  of the `TableBorderPicker`; shared inner edges are written once — on the lower cell's top and
  the right cell's left; `none` clears the cell borders, the table style's stay),
  `setCellAlign {vAlign}`, `setCellPadding {padding | all}` (new id), `clearCells`; without
  values from the UI they open Inspector › Table/Cell. Text format commands on a selected table
  format the selected cells' (else every cell's) whole text (`TextFormatTarget.cell`), and the
  format painter copies a cell's fill, borders, padding, vertical align and dominant text
  attributes onto the clicked cell (03 §9; `ElementStylePayload.cell`).
- **Core additions (additive):** `ReplaceImage.crop`; `TextNode.partId`
  (`"<rowId>|<columnId>"` on table cell text); `TableGrid`/`TableGridCell` and
  `SlideSceneBuilder.tableGrid(element, context, {cellText})` — the same layout the scene draws
  (column/row edges, grown rows, merges, padding, vertical align, cell styles).
- **Not built / deviations:** see `TODO.md` "Images and tables leftovers (SL-15)".

## 7. Element groups

- **Group** (`slides.arrange.group`, ⌥⌘G / Ctrl+Alt+G, and contextual **Mod+G** in the canvas
  scope with ≥ 2 elements selected): creates a `group` element at the max zKey of the members,
  with `childBounds` = the members' union box; children keep their visual position (frames
  converted to child space — identity at creation). One undo step "Group".
- **Ungroup** (`slides.arrange.ungroup`, ⌥⇧⌘G / Ctrl+Alt+Shift+G, and **Mod+Shift+G** in the
  canvas scope): bakes the group transform into each child, inserts the children at the group's
  z position (keeping their relative order), deletes the group. Builds targeting the group are
  **deleted** with a toast "Ungrouping removed 2 animations" (one undo step restores everything).
- Groups nest (depth ≤ 8). Placeholders cannot be grouped (command disabled with reason).
- Transforms apply to the group frame; children keep relative layout. Group opacity multiplies.
- Selecting inside a group (§3.2) and editing children (text, style) writes only the child.
- Magic Move matches groups by `matchKey` as one unit; children with their own `matchKey`s match
  individually only when both slides contain the same group (06).

---

## 8. Lock, hide, z-order, Layers panel

### 8.1 Layers panel (P1; `slides.panel.layers`)

Side panel listing the current slide's elements as a tree (front-most at the top), each row:
kind icon, name (double-click to rename → `slides.element.rename`), eye (hide) and lock toggles.
Rows are drag-reorderable (`slides.arrange.setZ {id, before|after}`), nested under groups
(dragging into/out of a group regroups, one step). Clicking selects (also locked/hidden
elements). A collapsed section *From layout* lists layout/master elements read-only with
*Edit layout* link. A tab **Reading order** (P1) shows the reading order list (§17.2).

**As built (SL-34).** `features/layers/` (`LayersPanel`), feature `layers`. In masters mode the
panel lists the edited layout or master. Rows: click selects (Shift extends among siblings, Mod
toggles; the canvas selection is the same), a second click within the double-tap time renames
inline, eye and lock call `slides.element.hide`/`show` and `slides.element.lock`/`unlock` with
`ids`. Drag and drop: upper/lower half of a row = in front of / behind it, the middle half of a
group row = into the group, below the last row = to the back; `slides.arrange.setZ {ids?,
aboveId | belowId | groupId}` plans **`MoveElementsZ`** (new core operation): siblings keep their
relative order, re-parenting maps frames through the group child spaces (`GroupSpace.toChild`,
the inverse of `toParent`) so nothing moves on the slide, the opacity of groups left is multiplied
in, groups left empty are deleted and unrotated, unflipped groups are refitted to their children
(frame and `childBounds` together); placeholders can't move into groups. Keyboard: ↑/↓ select
the next row, Shift extends, Alt+Shift+↑/↓ move the selection one row, Enter/F2 rename, ←/→
collapse/expand a group. *From layout (n)* lists the layout and master elements; *Edit layout*
opens masters mode on the slide's layout. The *Reading order* tab lists the current reading order
(decorative and hidden objects excluded); drag or the ↑/↓ buttons write
`slides.a11y.setReadingOrder {ids}` (**`SetReadingOrder`**: ascending `readingKey`s for the
listed elements, every other key cleared), *Reset to automatic* `slides.a11y.resetReadingOrder`.

### 8.2 Lock and hide

- `slides.element.lock` / `unlock` (⌥⇧⌘L / Ctrl+Alt+Shift+L toggles), `slides.element.unlockAll`
  (Arrange menu). Locked: not hit by clicks/marquee on the canvas, cannot be moved/resized/deleted
  from the canvas; selectable from the Layers panel (then properties are editable but transform
  handles show a lock badge instead). Locked state is shared (synced), like Google/PowerPoint
  lock behaviors in team templates.
- `slides.element.hide` / `show`: hidden elements are not drawn (editor, present, PDF,
  thumbnails) and not hit; visible only as rows in the Layers panel (dimmed). Builds of hidden
  elements are skipped.

### 8.3 Z-order

| Command | Effect | Shortcut |
|---------|--------|----------|
| `slides.arrange.order {op: bringToFront}` | `zKey = after(max sibling)` | ⌥⇧⌘↑ / Ctrl+Alt+Shift+↑ |
| `… {op: bringForward}` | Move above the next **overlapping** sibling above (`between` its key and the next) | ⇧⌘↑ / Ctrl+Shift+↑ (canvas scope) |
| `… {op: sendBackward}` | Below the next overlapping sibling below | ⇧⌘↓ / Ctrl+Shift+↓ |
| `… {op: sendToBack}` | `zKey = before(min sibling)` | ⌥⇧⌘↓ / Ctrl+Alt+Shift+↓ |

Multi-selection keeps relative order (`nBetween`). Master/layout elements are always behind slide
elements (layers are separate); placeholders participate in slide z-order like other elements.
Each is one undo step writing only `zKey`.

> Shortcut note: Align uses ⌥⌘+arrows (§5.5), order uses ⇧⌘+arrows and ⌥⇧⌘+arrows, nudge uses
> plain/Shift arrows. Slide reordering (⌘↑/⌘↓) is only bound in the navigator scope (04 §5.9).

---

## 9. Format painter and copy/paste style

- **Paint format** (`slides.format.paintFormat {sticky}`, toolbar brush; double-click = sticky):
  copies the style of the selected element (or of the text at the caret) and applies it to the
  next clicked element or selected text. Sticky stays armed until Esc or clicking the brush.
- What is copied, by target:

| Source → target | Copied |
|-----------------|--------|
| Element → element (any kinds) | `fillJson`, `strokeJson`, `effectsJson`, `opacity`; for text-capable targets also `textStyleJson` (including insets and auto-fit) and the dominant run + paragraph attributes applied to all text |
| Text selection → text selection | Inline attributes (font, size, weight, color, highlight, bold/italic/underline/strike, caps, letter spacing) and, when whole paragraphs are selected, paragraph attributes (style, align, list, spacing) |
| Image → image | Mask, adjustments, stroke, effects, opacity (not crop) |
| Table cell(s) → cells | Fill, borders, padding, vertical align, text attributes |
| Line → line | Stroke incl. arrowheads |

- **Copy style / Paste style** (`slides.format.copyStyle` ⌥⌘C, `slides.format.pasteStyle` ⌥⌘V,
  Keynote): same payload kept in an in-app style clipboard (not the system clipboard); paste
  applies to every selected element. Each application is one undo step "Paste style".

---

## 10. Keyboard map (canvas, text, table)

macOS / Windows-Linux. Browser-reserved chords are never bound (suite 08 §1.2). Navigator and
presenting keys: [04 §5.9](04-screens-menus-toolbar.md), [10](10-presenting-and-pdf.md).

| Action | macOS | Win/Linux | Scope | Command |
|--------|-------|-----------|-------|---------|
| Undo / Redo | ⌘Z / ⇧⌘Z | Ctrl+Z / Ctrl+Y, Ctrl+Shift+Z | global | `shell.edit.undo` / `redo` |
| Cut / Copy / Paste | ⌘X / ⌘C / ⌘V | Ctrl+X / C / V | canvas, text, table | `shell.edit.*` |
| Paste without formatting | ⇧⌘V | Ctrl+Shift+V | canvas, text | `shell.edit.pasteWithoutFormatting` |
| Duplicate | ⌘D | Ctrl+D | canvas | `slides.edit.duplicate` |
| Delete | ⌫ / ⌦ | Backspace / Delete | canvas | `slides.edit.delete` |
| Select all | ⌘A | Ctrl+A | canvas, text, table | `shell.edit.selectAll` |
| Next / previous element | Tab / ⇧Tab | Tab / Shift+Tab | canvas | `slides.select.next` / `previous` |
| Activate (edit text, enter group, crop) | Enter | Enter | canvas | `slides.element.activate` |
| Exit / deselect | Esc | Esc | all | `slides.select.escape` |
| Nudge 1 / 10 su | arrows / ⇧arrows | arrows / Shift+arrows | canvas | `slides.element.nudge` |
| Group / ungroup elements | ⌘G or ⌥⌘G / ⇧⌘G or ⌥⇧⌘G | Ctrl+G or Ctrl+Alt+G / Ctrl+Shift+G or Ctrl+Alt+Shift+G | canvas | `slides.arrange.group` / `ungroup` |
| Bring forward / send backward | ⇧⌘↑ / ⇧⌘↓ | Ctrl+Shift+↑ / ↓ | canvas | `slides.arrange.order` |
| Bring to front / send to back | ⌥⇧⌘↑ / ⌥⇧⌘↓ | Ctrl+Alt+Shift+↑ / ↓ | canvas | `slides.arrange.order` |
| Align left/right/top/bottom | ⌥⌘← → ↑ ↓ | Ctrl+Alt+arrows | canvas | `slides.arrange.align` |
| Lock / unlock | ⌥⇧⌘L | Ctrl+Alt+Shift+L | canvas | `slides.element.toggleLock` |
| Text box / shape / line tools | T / S (last shape) / L | same | canvas | `slides.insert.textBox` / `shape` / `line` |
| Insert link | ⌘K | Ctrl+K | canvas, text | `slides.insert.link` |
| Comment | ⌥⌘M | Ctrl+Alt+M | canvas, text | `shell.comments.create` |
| Alt text | ⌥⌘Y | Ctrl+Alt+Y | canvas | `slides.element.editAltText` |
| Paint format / copy style / paste style | — / ⌥⌘C / ⌥⌘V | — / Ctrl+Alt+C / Ctrl+Alt+V | canvas, text | `slides.format.paintFormat` / `copyStyle` / `pasteStyle` |
| Bold / italic / underline / strikethrough | ⌘B / ⌘I / ⌘U / ⇧⌘X | Ctrl+B / I / U / Alt+Shift+5 | canvas, text, table | `slides.format.*` |
| Font size bigger / smaller | ⇧⌘. / ⇧⌘, | Ctrl+Shift+. / , | canvas, text | `slides.format.increaseFontSize` / `decrease…` |
| Superscript / subscript | ⌘. / ⌘, | Ctrl+. / Ctrl+, | text | `slides.format.script` |
| Align text left / center / right / justify | ⇧⌘L / E / R / J | Ctrl+Shift+L / E / R / J | canvas, text | `slides.format.align` |
| Bulleted / numbered / checklist | ⇧⌘8 / ⇧⌘7 / ⇧⌘9 | Ctrl+Shift+8 / 7 / 9 | canvas, text | `slides.format.list` |
| Indent / outdent | Tab / ⇧Tab (lists), ⌘] / ⌘[ | Tab / Shift+Tab, Ctrl+] / Ctrl+[ | text | `slides.format.indent` / `outdent` |
| Text style 1–9 | ⌥⌘1…9 | Ctrl+Alt+1…9 | text, canvas | `slides.format.textStyle` |
| Clear formatting | ⌘\ | Ctrl+\ | canvas, text | `slides.format.clear` |
| Zoom fit / in / out | ⌥⌘0 / ⌥⌘= / ⌥⌘− | Ctrl+Alt+0 / = / − | global | `slides.view.zoom*` |
| Find / find and replace | ⌘F / ⇧⌘H | Ctrl+F / Ctrl+H | global | `slides.find.open` / `openReplace` |
| Present / from start | ⌘Enter / ⇧⌘Enter | Ctrl+Enter / Ctrl+Shift+Enter | canvas, navigator | `slides.present.fromCurrent` / `fromStart` (10) |
| New slide | ⌃M (⌘M minimizes the window on macOS) | Ctrl+M | global | `slides.slide.new` |
| Previous / next slide | PgUp / PgDn (canvas), ↑/↓ (navigator) | same | canvas, navigator | `slides.nav.previousSlide` / `nextSlide` |
| Pan | Space+drag | Space+drag | canvas | — |
| Command palette | ⇧⌘P | Ctrl+Shift+P | global | `shell.nav.commandPalette` |

---

## 11. Edit commands (non-menu details)

- `slides.edit.delete`: canvas → delete selected elements (and their builds, cascade); text →
  delete selection; navigator → delete slides (04 §5.7). One step.
- `slides.edit.duplicate`: elements → copies offset +32 su (or by the last duplicate's offset if
  the user moved the previous duplicate — Keynote "smart duplicate", P1); navigator → duplicate
  slides/groups (04).
- `matchKey` rules (06 §8.2): duplicating elements **on the same slide** regenerates their
  `matchKey`; duplicating slides and copying/pasting elements **to another slide** keeps it, so
  Magic Move matches them across slides.

---

## 12. Clipboard

### 12.1 Representations written on copy

| Format | Content | When |
|--------|---------|------|
| `application/x-wonky-slides` (JSON, §12.2) | Lossless payload | Always (in-app store on web + text marker; custom format on desktop via `super_clipboard`) |
| `text/plain` | Text of the selection (elements: their text in reading order; slides: titles and body text as an outline) | Always |
| `text/html` | Rich text (text selections, tables as `<table>`) | P1 |
| `image/png` | Selection rendered at 2× (elements) / the slide (slides, first one) | Copy of elements/slides when the platform supports image clipboard (web Clipboard API, macOS) |
| `text/markdown` marker | Slides outline as Markdown for Write (`# Title` + bullets) | Slides copies |

### 12.2 Payload `application/x-wonky-slides` v1

```jsonc
{
  "format": "wonky-slides-clipboard", "v": 1,
  "sourceDeckId": "…", "sourceItemUuid": "…", "sourceSlideId": "…",   // element copies
  "kind": "elements" | "slides" | "groups" | "text",
  "themes":   [ { /* DeckTheme row */ "masters": [ … ], "layouts": [ … ], "elements": [ … ] } ],  // only themes used by copied slides
  "groups":   [ { "id", "title", "color", "skipped", "slides": ["<slideId>", …] } ],
  "slides":   [ { /* Slide row */ } ],
  "elements": [ { /* SlideElement row */ } ],
  "tableAxes": [ … ], "tableCells": [ … ], "builds": [ … ], "codeStates": [ … ], "chartLinks": [ … ],
  "files":    [ { "fileUuid", "itemUuid", "mimeType", "size" } ],   // uploaded files referenced by src/fill
  "text":     { "delta": [ … ] }                                     // kind = text (text selection)
}
```

Built and parsed by `SlidesClipboardCodec` (core). Ids are remapped on paste by the same remapper
as `DeckCopier` (02 §9.3) — every paste produces fresh ids (and fresh deterministic ids);
`matchKey`s are kept, except when elements are pasted onto the slide they were copied from (then
regenerated, 06 §8.2).

### 12.3 Paste rules

| Target | Payload | Result |
|--------|---------|--------|
| Canvas (no text editing) | elements | Inserted on the current slide at the **same positions** if pasted onto another slide; offset +32 su on the same slide (repeated pastes cascade). Above all elements, selected. |
| Canvas | slides/groups | Inserted as slides **after the current slide** (same as navigator paste) |
| Navigator (slide/group selected or insertion point) | slides/groups | After the selection / at the insertion point (04 §5.8); groups arrive as groups (title, color, skip) with their slides |
| Navigator | elements | Disabled ("Paste objects on a slide") |
| Text editing | text / elements with text | Rich text inserted at the caret (schema-filtered); objects without text ignored |
| Table cell range | TSV/HTML/Sheets cells | Fills cells (§6.6) |

**Cross-deck paste** (source deck ≠ target deck):

- **Themes**: slides keep their layout by **mapping** to the target's default theme: same layout
  `key` → that layout; else best placeholder-signature match; else `titleBody`/`blank`
  ("**Use destination theme**", default). A floating **paste options chip** (bottom-right of the
  pasted range, 10 s) offers **Keep source formatting**: re-runs the paste (replacing the same undo
  step, `UndoService.replaceLast`) bringing the source theme copy (deterministic `themeCopyId`, so
  repeated pastes from one deck share one theme copy).
- Elements pasted cross-deck keep explicit colors; `theme:` color refs resolve against the target
  theme (that is the point of "use destination theme").
- **Files**: each referenced `wonky-file://` is re-homed into the target deck with
  `FileEndpoint.copyToItem(sourceFileUuid, newFileUuid, targetItemUuid)` (idempotent on
  `newFileUuid`, quota-checked — §20); `src` is rewritten to the new uuid immediately and the copy
  is queued offline (renders from the source URL meanwhile if cached). A quota failure removes the
  image with a toast.
- **Linked charts** stay linked (`ChartLink` copied with the new element id).
- **Comments** are never copied. **Builds** and **code states** are copied with their elements;
  builds whose element isn't copied are dropped.
- Permissions: copying from a deck whose owner disallowed copying for viewers is blocked at copy
  time (the copy command is disabled).

### 12.4 From Write and Sheets

| Source (clipboard format) | Paste on canvas | Paste into text editing |
|---------------------------|-----------------|-------------------------|
| Write text (`application/x-wonky-write` Delta, or `text/markdown`) | New text box: headings → `heading` style paragraphs (H1 → title-sized), lists keep nesting/checklists, bold/italic/strike/inline code/links mapped; **Write images** → image elements below the text box; **Write tables** → table element; **code blocks** → code element (language kept) | Inline attributes and lists mapped; headings → `heading` style; embeds ignored |
| Sheets cells (`application/x-wonky-sheets` or TSV/HTML) | **Table element** with values as displayed (formatted text), bold/italic/colors/fills/alignment mapped, merges kept; > 50 × 20 truncated with toast "Only the first 50 rows and 20 columns were pasted" | Tab-separated text |
| Sheets chart object (`application/x-wonky-sheets-objects` with spreadsheet item uuid + object id) | **Linked chart** (08) with *Paste unlinked* in the paste options chip | — |
| Sheets image object | Image element | — |

The Sheets object payload must carry `spreadsheetItemUuid` and `objectId` (addition to Sheets 08
§9.5, §20).

### 12.5 From the OS and other apps

| Format | Result |
|--------|--------|
| Image data / image files | Image element(s) (§6.5) |
| `text/html` (P1) | Rich text mapped to the schema (fonts dropped unless bundled, sizes converted px→su ×1.33, colors kept); `<table>` → table element; `<img>` with http(s) src → images via the proxy |
| `text/plain` | Text box (paragraphs per line; lines starting with `- `/`* `/`1. ` become lists) |
| SVG text (`<svg …`) | Image (rasterized; P2: shapes) |
| URL only | Text box with the link (P2: link card) |

*Paste without formatting* (⇧⌘V) pastes plain text into the editing body or a new text box with
the theme body style.

*As built (SL-8, core only; the UI is SL-18):* `package:wonky_slides_core/clipboard.dart` —
`SlidesClipboardCodec` (`copyElements` with descendants and placeholder instances materialized
to their effective frame, `copySlides` for slides and groups with their themes, `copyText`;
`encode`/`decode`/`sanitize` for untrusted payloads — known columns only, UUID ids, text
normalized, dependents of missing elements dropped, ≤ 200,000 rows; `plainText`/`markdown`;
`fileUuids`/`rehomeFiles` for cross-deck pastes; `checkLimits`) and `SlidesPasteMappers`
(`plainText`, `writeDelta` — Write tables become table elements from their inline Markdown,
`parseTsv`/`tsv`/`grid` with formats, merges and the 50 × 20 cut, `sheetsObject` — linked chart
when the item names `spreadsheetItemUuid` + `objectId`, else static; images — `image`). Mappers
return `elements` payloads for `PasteElements` and warning codes (`truncated`,
`remote_images`). HTML paste (P1) is not built yet.

*As built (SL-18):* app `features/clipboard/` + `commands/clipboard_commands.dart`;
core `SlidesHtml` (`clipboard/slides_html.dart`), `SlidesClipboardCodec.htmlBody`,
`SlidesPasteMappers.html` / `writeText`.

- **Commands.** `slides.edit.copy`, `slides.edit.cut`, `slides.edit.paste {plainText?, text?,
  html?, imageBase64?, imageType?}` (hidden from the palette; the shell's `shell.edit.cut|copy|
  paste|pasteWithoutFormatting` reach them through `DeckDocumentController`, and the text
  layer runs them for Mod+C/X/V and ⇧Mod+V while a body is edited) and
  `slides.edit.pasteSpecial {mode: useDestination|keepSource|unlinked|linked}`. The target is
  the body being edited, else the selected table cells, else the navigator/grid (slides and
  groups; with nothing selected on the canvas, non-slide content still goes to the canvas),
  else the canvas. Each paste or cut is one undo step.
- **Representations (§12.1).** One `ClipboardItem` with `text/plain` (outline or text) and
  `text/html` — readable HTML (paragraphs, headings, nested lists, inline formatting, tables
  as `<table>` with merges and fills, code as `<pre>`, slides as an `<h2>` title + their text)
  with the payload embedded as base64url JSON in `data-wonky-slides` (the pattern of Write's
  `data-wonky-delta`; payloads > 4 M characters are not embedded) — plus the in-app store
  (`SlidesSlideClipboard`: memory + `slides.clipboard` in the user store). Pasting reads the
  embedded payload, else the in-app payload when the system clipboard holds exactly its plain
  text without HTML (desktop) or can't be read (permission denied). The async Clipboard API
  accepts no custom MIME types (only `web `-prefixed ones in Chrome), so
  `application/x-wonky-slides` travels as the embedded HTML payload; `image/png` of copied
  elements and the `text/markdown` marker are not written (Write pastes the HTML).
- **Resolution order of a paste.** Slides payload → Sheets objects (the plain-text marker
  `wonky-sheets-objects:<id>` + `clipboard.sheetsObjects` in the user's local store, which the
  Wonky Work apps of one origin share; Sheets writes it on *Copy* of objects) → Write's Delta
  (`data-wonky-delta`) → an image without HTML text (inserted through `slides.insert.image
  {source: drop}`: validation, quota pre-check, offline upload queue) → HTML (one table →
  table element with bold/italic/colors/fills/alignment/merges; anything else → Write-flavored
  Delta → text box, images, tables, code) → TSV (≥ 2 columns) → a single URL (text box with
  the link) → plain text (lists detected). *Paste without formatting* takes the plain text
  only. In a text body: rich text at the caret replacing the selection (schema-filtered;
  Write headings → `title`/`heading`, lists kept, embeds dropped; the last pasted paragraph
  merges into the caret's). In table cells: TSV, HTML tables, Sheets cells or a copied Slides
  table fill from the range's top-left cell (one value fills the whole range), clipped to the
  table (toast), and the pasted range is selected; cells copy as TSV + an HTML table.
- **Positions.** Elements paste at the same positions on another slide; on their source slide
  repeated pastes cascade by 32 su (32, 64, …); after a cut the first paste lands in place.
- **Cross-deck and cross-app files (A-03-3).** `DeckClipboard.prepareFiles`: every
  `wonky-file://` of a payload from another deck — and of Write/Sheets content — gets a new
  uuid **deterministic per (target deck, source file)** (`SlidesIds.themePartId(deck,
  'file:<source>')`), so a re-run of the same paste (*Keep source formatting*) and repeated
  pastes reuse one copy; the bytes the device knows (payload `files[].size`, filled at copy
  time from the image cache, or cached images) are pre-checked against the deck owner's quota
  (`StorageChecks.ensureRoom`; refusal → the quota dialog, nothing pasted); the copies go to
  `SlidesRehomeQueue` (`features/clipboard/rehome_queue.dart`: per user in the device store
  `user.<id>.slides.rehome`, offline-first, backoff 2 s → 10 min, 12 attempts per start — the
  target may not be registered yet or the source still uploading). While pending, the image
  renders from its source (`SlidesImageService` resolves the new uuid to the source) and counts
  as uploading; a quota refusal of a copy shows the *Not uploaded — out of storage* badge with
  *Retry*/*Remove* (deviation: §12.3 said "removes the image with a toast"). `https://`
  images of pasted HTML keep their URL (drawn through the image proxy, not re-hosted).
- **Paste options chip (04 §13.12).** `PasteOptions` + `PasteOptionsChip` in the canvas
  overlay layer: after a cross-deck slides/groups paste (*Use destination theme* ✓ / *Keep
  source formatting*) and a linked Sheets chart paste (*Linked to the spreadsheet* ✓ / *Paste
  chart unlinked*). It hides after 10 s or when another undo step lands; choosing an option
  runs `slides.edit.pasteSpecial`, which undoes the paste (still the top step) and pastes again
  in the chosen mode in its own transaction — the stack keeps one step. Not offered for
  cross-deck element pastes (their `theme:` refs resolve against the destination, as
  specified); the chart chip sits at the pasted chart's bottom-right, the slides chip at the
  canvas' bottom-right corner.

---

## 13. Find and replace

- `slides.find.open` (⌘F) opens a compact find bar at the top-right of the canvas;
  `slides.find.openReplace` (⇧⌘H) the full non-modal dialog (`WonkyDialogSpec`, MCP-operable):
  fields `find`, `replace`, `matchCase`, `wholeWords`, `useRegex`, `includeNotes` (default on),
  `includeSkipped` (default on), `scope` (All slides / Current slide / Selected slides); buttons
  [Previous] [Next] ("3 of 12"), [Replace], [Replace all], [Done].
- Searches every text body in presentation order: slide elements (reading order), table cells,
  code text (P1, off by default: `includeCode`), notes, group titles (P1). Master/layout text only
  in master editing mode.
- Matches highlight with `findMatch` / `findMatchActive` tokens on the canvas and in notes; Next
  navigates to the slide and selects the match (enters text editing on it).
- *Replace all* = one undo step "Replace all" (toast "Replaced 12 instances of 'x' with 'y'");
  bodies soft-locked by others are skipped and reported ("2 matches in text Anna is editing were
  skipped").

*As built (SL-18):* core `DeckFind` (`package:wonky_slides_core/find.dart`: bodies in
presentation order — slide elements in reading order with groups expanded, table cells row by
row, then the slide's notes; options `matchCase`, `wholeWords` (Unicode letters/digits),
`useRegex` (`$1…$9`, `$$` in replacements), `includeNotes`, `includeSkipped` (slide or group
skipped), `scope` all/current/selected; `replaceRanges` keeps the first replaced character's
inline attributes); app `features/find/` (`DeckFindController` per editor — matches
recomputed 150 ms after deck changes, the current match kept by body and offset;
`SlidesFindBar`; `FindReplacePanel` — non-modal over the canvas, MCP-describable
`dialog.slides.findReplace` with fields `find`, `replace`, `scope`, `matchCase`, `wholeWords`,
`useRegex`, `includeNotes`, `includeSkipped` and buttons `previous`, `next`, `replace`,
`replaceAll`, `done`; `FindHighlights` — `findMatch`/`findMatchActive` rectangles from the
canvas scene's text runs, split per character proportionally; `DeckCanvasOverlays` — the layer
above the canvas region, outside the `slidesCanvas` key scope) and
`commands/find_commands.dart`: `slides.find.open {query?}` (⌘F; prefills the selected text),
`slides.find.openReplace {find?, replace?}` (⇧⌘H), `slides.find.next|previous {query?,
options…}`, `slides.find.replace|replaceAll {find|query, replace, options…}` and
`slides.find.close` (new id). *Next* makes the match's slide current and selects the match in
its body (text editing; when another participant holds the body the element is only
selected); notes matches open the notes pane. *Replace all* is one step (label
`undoReplaceAll`), returns `{replaced, skipped, message, skippedMessage}` and toasts the §13
messages. Not built: code text (P1 `includeCode`), group titles (P1), master/layout text in
master editing (SL-28), highlights inside the notes pane.

---

## 14. Spell check (P1)

- Uses the suite's shared spell engine (Write's Hunspell engine in the pure-Dart
  `wonky_spellcheck` package and the `SpellEngine` glue in `wonky_app`, extracted in M8, §20) with the
  same dictionaries and the user's personal dictionary (`UserPreferences`).
- Language: `Deck.language` ?? user locale; per-paragraph `lang` is not supported.
- Squiggles (token `spellingError`) under misspelled words in the **body being edited**, and on
  the canvas for visible text boxes of the current slide when *Tools › Spelling › Underline
  errors* is on (`slides.spelling.toggleUnderline`, default on).
- Context menu on a misspelling: up to 5 suggestions, *Ignore*, *Add to dictionary*.
- *Tools › Spelling › Check spelling* (`slides.spelling.check`): steps through errors deck-wide in
  a small dialog (Change / Change all / Ignore / Ignore all / Add) — one undo step per change.

### 14.1 As built (SL-44): spelling, language, special characters, emoji, route handles

- **Code.** `wonky_slides/lib/features/spellcheck/` — `SlidesSpelling` (per open deck,
  `SlidesSpelling.of(editor)`: the engine of the presentation language from
  `SpellDictionaries`, the synced personal dictionary `PersonalDictionary` — the list Write
  already kept in `writeDefaults.personalDictionary`, now shared through
  `package:wonky_app/spellcheck.dart` — and the session's ignored words; checks plain text or a
  stored body (links and inline code skipped, results cached per body JSON) and the whole deck in
  `DeckFind.bodies` order), `EditorSpelling` (squiggles of a super_editor document through
  `SpellingAndGrammarStyler`: the canvas text overlay — boxes, shapes, placeholders, table cells —
  and the speaker notes; a `DocumentSpelling` of `wonky_rich_editor`, shared with the suite's
  Markdown composer, suite 16 §7.3, with `SlidesSpelling` as its checker; the context-menu
  section is the shared `spellingMenuEntries`), `SpellingCanvasLayer` (a `CanvasInteraction` painting the squiggles of
  the current slide's visible text from the stage scene's own paragraph boxes, token
  `spellingError`), `SlidesSpellingSession` (the shell's Check spelling dialog over the deck),
  `spelling_actions.dart` (replacements, the context-menu section), `text_inserts.dart`;
  `commands/spelling_commands.dart`. Hooks added for it: `SlideTextEditAddon` with
  `SlideTextEditing.addonFactories` / `NotesPane.addonFactories` (per-session style phases),
  `SlideTextEditing.prepareContextMenu` (a right-click outside the selection moves the caret
  there), `NotesPane.contextMenuEntries`, the outline's `_RunsController` squiggles, the
  `context.text.spelling` custom slot first in the text context menu.
- **Language.** `Deck.language` (File › Language ▸ = `slides.file.setLanguage {language}`,
  undoable, radio-checked), else the user's *Language* for new presentations
  (`slidesDefaults.defaultLanguage`, now shown in Settings), else the device locale. Regional
  fallbacks of the shared glue (en → en-US, en-AU → en-GB, any dictionary of the language); a
  language without a bundled dictionary turns checking off (the dialog says so; agents get
  `available: false`). Per-paragraph language is not supported (spec).
- **Squiggles.** Under misspelled words of the body being edited and, with *Underline errors* on
  (`slides.spelling.toggleUnderline`, `slidesDefaults.underlineSpelling`, Settings › Editing ›
  Spelling), of every visible text of the current slide (not while objects are dragged), the
  notes being edited and the outline lines. A misspelled word is held back while it is being
  typed and flagged once the caret leaves it; moving the caret into a flagged word keeps it
  flagged (for its menu). *Underline errors* off hides every squiggle; Check spelling still works.
- **Context menus.** Right-click a flagged word in the canvas text, the notes or an outline line:
  up to five suggestions (`slides.spelling.replace {elementId[, rowId, columnId] | notesSlideId,
  start, length, word?, replacement}`, one step "Correct spelling"; in the outline the line is
  edited like typing), *Ignore* (`slides.spelling.ignore`, this session) and *Add "word" to
  dictionary* (`slides.spelling.addToDictionary`, synced, max 10,000 words).
- **Check spelling.** Tools › Spelling › *Check spelling…* opens the shell's dialog (keys
  `slides.dialog.spelling…`) over every body of the deck end to end, from the caret or the
  current slide; showing a word makes its slide current and selects the object (or opens the
  notes) — the text editor isn't started under the modal dialog (deviation: Google selects the
  word). *Change* and *Change all* (`slides.spelling.replaceAll {word, replacement}` for agents)
  are one step each; bodies another participant is editing are skipped. For agents the command
  returns `{language, dictionary, available, count, issues: [{slideId, elementId | rowId,
  columnId | notesSlideId, start, length, word, suggestions}]}` instead of the dialog. Tools ›
  Spelling › *Personal dictionary…* (`slides.spelling.personalDictionary`, agents: `{add, remove}`
  → `words`).
- **Special characters and emoji.** *Insert › Special characters…*
  (`slides.insert.specialCharacter {char?}`, enabled while text is edited) opens the special
  characters dialog moved from Write to `package:wonky_app/special_chars.dart` (keys
  `slides.dialog.specialChars…`; recents shared with Write) and types each pick at the caret;
  *Insert › Emoji* types the emoji while text is edited (else an emoji object). Both are typing
  steps of the body.
- **Image adjustments.** The sliders preview live on the canvas (`ImageAdjustPreview`, the
  stage's image node gets the dragged matrix/blur; nothing written until release). Thumbnails and
  PDF already drew adjustments (SL-15/SL-20).
- **Connectors.** Route handles of a single selected top-level elbow (inner segments) or curved
  (bend) connector (`elements/line/connector_handles.dart`, `ConnectorHandles`), previewed on the
  overlay while dragged, written by `slides.line.setWaypoints` (`commands/connector_commands.dart`):
  the frame becomes the box of the current endpoints and waypoints (rotation/flips cleared),
  waypoints normalized in it. Core: a curved route with a waypoint bends through it at t = ½
  (`ConnectorRouter.curveMidpoint`).
- **Not built:** see `TODO.md` "Spelling, special characters, route handles leftovers (SL-44)".

---

## 15. Undo granularity summary

| Gesture | Steps |
|---------|-------|
| Drag move / resize / rotate (any number of elements) | 1 on drop |
| Nudge burst ≤ 1 s apart | 1 |
| Typing burst in one body | 1 per burst (suite rule) |
| Formatting command | 1 |
| Insert (incl. upload) | 1 (the upload completes later without another step) |
| Paste (any payload), paste-options switch | 1 (switch replaces it) |
| Crop session | 1 on commit |
| Table structure op / cell format | 1 each |
| Group / ungroup / align / distribute / z-order | 1 each |
| Format painter application | 1 per application |
| Find & replace all | 1 |
| Selection, zoom, scroll, panels | 0 (view state) |

---

## 16. View mode (viewers and commenters)

Canvas shows the slide; elements are selectable (no handles) for reading alt text, copying (if
allowed) and commenting (commenters); text can be selected and copied when copying is allowed;
links open with the external-link confirm. Mutating commands are disabled with the role reason.

---

## 17. Accessibility

### 17.1 Alt text

- *Alt text…* (`slides.element.editAltText`, ⌥⌘Y): dialog with `altText` (textarea, 1,000 chars),
  *Mark as decorative* checkbox (`decorative`), and **Generate with AI** (11, when AI is enabled).
  One undo step. Images, icons, charts (default: chart describer summary, 08), shapes without text
  and groups take alt text; text elements use their text.

### 17.2 Reading order

- Automatic order (when no element on the slide has `readingKey`): title placeholder, subtitle,
  then the remaining elements by **visual rows** (elements whose vertical centers are within
  10 % of the slide height form a row; rows top→bottom, left→right inside a row; RTL decks
  right→left), then slide number/footer/date last; decorative and hidden elements excluded.
- Override: Layers panel › *Reading order* tab (and the accessibility checker) — drag rows; the
  first drag writes `readingKey` for every element on the slide (`slides.a11y.setReadingOrder
  {ids}`, one step). *Reset to automatic* clears them.
- Used by: Tab cycling, the semantics tree, screen-reader presenting (10), PDF tagging (10),
  copying slides as text, MCP `slides.get_slide` text order.

### 17.3 Semantics and announcements

- The canvas exposes one semantics node per element in reading order: role (text, image, button
  for linked elements), label (`"Title: Q3 results"`, `"Image: <alt text>"`, `"Chart: <alt>"`,
  `"Table, 4 rows, 3 columns"`), value (text content, truncated 200 chars), state (selected,
  locked, hidden).
- Announcements (`SemanticsService.announce`): selection changes ("Rectangle 2 selected, 3 of 7
  objects"), moves after drop ("Moved to x 120, y 340"), slide change ("Slide 4 of 24, Intro
  group: Our mission"), soft-lock refusals.
- Keyboard-only creation: insert commands place elements at the slide center and select them; all
  transforms are reachable via nudge and the inspector's numeric fields.
- Focus: visible `ring` on the focused region (navigator, canvas, inspector, notes);
  `shell.focus.nextRegion` (F6) cycles toolbar → navigator → canvas → inspector → notes.

### 17.4 Accessibility checker (P1)

`slides.tools.accessibilityCheck` opens the side panel `slides.panel.accessibility` listing issues
by slide with *Fix* actions:

| Rule | Severity | Fix |
|------|----------|-----|
| Image/icon/chart without alt text (not decorative) | Error | Alt text dialog (Generate with AI) |
| Text contrast < 4.5:1 (< 3:1 for text ≥ 32 su bold / 40 su) against its resolved background (fill, else slide background; images: sampled average, warning only) | Error | Select element |
| Slide without a title (no title placeholder text and no `heading`-style paragraph) | Warning | Edit slide |
| Duplicate slide titles | Warning | — |
| Text smaller than 18 su | Warning | Select |
| Reading order differs strongly from visual order (custom order) | Info | Reading order tab |
| Table without header row | Warning | Toggle header row |

**As built (SL-34).** `features/accessibility/` (pure-Dart `AccessibilityChecker` + `A11yFixes`,
`AccessibilityPanel`), feature `accessibilityChecker`. Two rules were added: **text over an image**
(an image element or image fill/background behind the text: *warning*, check by eye — the
"sampled average" isn't computed) and **empty placeholders** (body, subtitle, picture, …; *tip*,
fix *Remove placeholder*). Contrast: each non-blank run's resolved color (inline ▸ paragraph style
▸ box defaults ▸ theme style, element opacity applied) against the element's own fill, else the
topmost filled element behind its center, else the slide background — all resolved for the deck's
appearance, so a dark deck is checked with its dark scheme; large = ≥ 40 su or ≥ 32 su bold. The
reading-order rule fires when a custom order doesn't read the title first or swaps more than a
third of the element pairs (*tip*). Skipped slides aren't checked; table cells, code and chart
text aren't checked yet. Commands: `slides.tools.accessibilityCheck {slideIds?}` (report JSON for
MCP; opens the panel from the UI), `slides.a11y.goTo {slideId, elementId?}`, `slides.a11y.fix
{rule, slideId, elementId?, altText?, decorative?}` — fixes: alt text (dialog, or the given text)
and *Mark decorative*; contrast → the first of `text1`, `bg1`, `text2`, `bg2`, black, white that
meets 4.5:1; small text → the small runs set to 18; reading order → reset; table → header row on;
empty placeholder → removed; slide titles and text over images have *Go to* only. The panel
re-checks 400 ms after each change while open.

---

## 18. Performance budgets

| Scenario | Budget |
|----------|--------|
| Open a cached 200-slide deck to first slide painted | < 800 ms desktop, < 1.5 s web |
| Switch slide (navigator click) to painted | < 50 ms (p95) for slides ≤ 100 elements |
| Drag/resize 50 selected elements | 60 fps desktop, ≥ 45 fps web |
| Typing latency in a text box | < 16 ms p95 |
| Enter text editing (editor overlay ready) | < 50 ms |
| Thumbnail render (navigator, 240 px wide) | ≤ 8 ms each, off the critical path; one cache entry per slide, width and appearance, re-recorded when its render revision changes |
| Snap computation per pointer move (500 elements) | < 2 ms |
| Paste 50 slides cross-deck | < 1 s local apply (file copies async) |
| Remote change visible (other device) | < 300 ms via hints; committed edits p95 < 250 ms via sync (RevLog gate P1, [17](../17-revlog-sync.md) part 7) |

**Perf suite (CQ-38, as built).** `wonky_slides/test/perf/slides_perf_test.dart` (tag `perf`,
skipped by default: `flutter test -t perf --run-skipped test/perf`) counts what one edit costs
through the editor screen of a 40-slide deck (25 elements per slide, ten navigator thumbnails)
and fails on count regressions. Before → after CQ-43 (counts per edit; times are debug JIT
medians on one machine, comparable only with each other):

| Scenario | Nodes built | Layers painted | Stage builds | Thumbnails recorded |
|----------|-------------|----------------|--------------|---------------------|
| Move one element on the current slide | 50 → 2 | 25 → 1 | 1 → 1 | 1 → 1 |
| Speaker notes commit | 50 → 0 | 25 → 0 | 1 → 0 | 1 → 0 |
| Deck rename / guide move | 275 → 0 | 25 → 0 | 1 → 0 | 10 → 0 |
| A collaborator moves an element on another slide | 25 → 1 | 0 → 0 | 1 → 0 | 1 → 1 |
| Drag: per pointer move | 0 → 0 | 0.7 → 0 | 1 → 0 | — |

Scenes of 100 slides × 30 elements: cold 169 → 172 ms; one slide after one edit 1.5 → 0.3 ms
(30 → 1 nodes built); a deck rename, a notes commit or an edit of an unused layout re-rendered
100 / 1 / 100 → 0 / 0 / 0 slides. Thumbnail cache after 20 commits on one of 10 slides:
30 → 10 entries. A 3000 × 2000 photo drawn 640 logical px wide (DPR 3) decodes to 10.7 MB
instead of 22.9 MB.

---

## 19. Commands owned by this spec (not all are in menus)

| Area | Command ids |
|------|-------------|
| View/canvas | `slides.view.zoom {percent}`, `slides.view.zoomFit`, `slides.view.zoomIn`, `slides.view.zoomOut`, `slides.view.zoomToSelection`, `slides.view.toggleRulers`, `slides.view.toggleSmartGuides`, `slides.view.toggleSnapObjects`, `slides.view.toggleSnapGuides`, `slides.view.toggleSnapGrid` (P2) |
| Selection | `slides.select.elements {ids}`, `slides.select.next`, `slides.select.previous`, `slides.select.escape`, `slides.select.enterGroup`, `slides.select.sameKind` (P2), `slides.element.activate` |
| Elements | `slides.element.move`, `…resize`, `…nudge`, `…adjust` (SL-12), `…setLineEnds` (SL-12), `…rename`, `…toggleLock`, `…lock`, `…unlock`, `…unlockAll`, `…hide`, `…show`, `…editAltText`, `…setLink`, `…removeLink`, `…resetPlaceholder`, `…setMatchKey` (06) |
| Arrange | `slides.arrange.align`, `…distribute`, `…centerOnSlide`, `…matchSize`, `…order`, `…setZ`, `…rotate`, `…flip`, `…group`, `…ungroup`, `…tidy` (P2) |
| Insert | `slides.insert.textBox`, `…shape`, `…line`, `…image`, `…table`, `…icon`, `…emoji`, `…code`, `…chart`, `…chartFromSheets`, `…link`, `…specialCharacter` |
| Text/format | `slides.format.bold`, `…italic`, `…underline`, `…strikethrough`, `…font`, `…fontSize`, `…increaseFontSize`, `…decreaseFontSize`, `…textColor`, `…highlight`, `…script`, `…caps`, `…letterSpacing`, `…lineHeight`, `…paragraphSpacing`, `…align`, `…anchor`, `…list`, `…listStyle`, `…listStart`, `…indent`, `…outdent`, `…textStyle`, `…autofit`, `…insets`, `…clear`, `…fill`, `…stroke`, `…effects`, `…opacity`, `…paintFormat`, `…copyStyle`, `…pasteStyle`; `slides.text.exitEditing`, `slides.text.removeLink` |
| Shapes/lines/images | `slides.shape.change`, `…applyQuickStyle`, `slides.line.setArrow`, `…setRouting`, `slides.image.replace`, `…reset`, `…mask`, `…crop`, `…adjust`, `…downloadOriginal` |
| Tables | `slides.table.insertRow`, `…insertColumn`, `…deleteRows`, `…deleteColumns`, `…mergeCells`, `…unmergeCells`, `…distributeRows`, `…distributeColumns`, `…setOptions`, `…setCellFill`, `…setBorders`, `…setCellAlign`, `…setCellPadding`, `…delete` |
| Guides | `slides.guides.add`, `…move`, `…delete`, `…clear` |
| Edit | `slides.edit.delete`, `slides.edit.duplicate`, `slides.edit.pasteSpecial {mode: keepSource\|useDestination\|unlinked}` |
| Find/spelling | `slides.find.open`, `…openReplace`, `…next`, `…previous`, `…replace`, `…replaceAll`; `slides.spelling.check`, `…toggleUnderline`, `…addToDictionary` |
| Accessibility | `slides.a11y.setReadingOrder`, `…resetReadingOrder`, `…goTo`, `…fix`, `slides.tools.accessibilityCheck` (SL-34) |

---

## 20. Additions to 02-data-model and to suite specs

| # | Addition |
|---|----------|
| A-03-1 | `Deck.guidesJson: String?` — `[{"axis":"v"\|"h","at":<su>}]`, whole-value LWW (§5.6). |
| A-03-2 | Shape geometry keys of §6.3 are the `dataJson.geometry` enum (core `ShapeLibrary`, with geometry functions, adjust defaults and connection sites, shared by renderers and MCP). |
| A-03-3 | **Suite (files)**: `FileEndpoint.copyToItem(sourceFileUuid, newFileUuid, targetItemUuid)` idempotent on `newFileUuid`, quota-checked (D3); queued offline. Used by cross-deck paste, `DeckCopier`, *Insert image from Drive*. *Built (SL-8):* images the caller can read, target Editor+, charged to the target owner's attachment bytes. |
| A-03-4 | **Suite (files)**: generalize Sheets' image proxy `sheets.fetchImage` to `files.fetchImage(url) → fileUuid` for all apps. *Built (SL-15):* `file.fetchImage(itemUuid, url) → bytes` (viewer of the item; the client stores the bytes as an ordinary queued, quota-checked upload, so offline-first inserts and URL inserts share one path). |
| A-03-5 | **Sheets 08 §9.5**: the objects clipboard payload carries `spreadsheetItemUuid` and `objectId` so Slides can paste a linked chart. *Built (SL-8):* plus `sheetId` (`wonky_sheets/lib/features/objects/object_ops.dart`). |
| A-03-6 | **Shared packages** (decided, v2 review Q23): Write's Hunspell engine moves to the pure-Dart `wonky_spellcheck`; the Flutter glue (`SpellEngine`, dictionary loading, spelling dialogs) and the emoji picker move to `wonky_app`, so Slides doesn't import Write. |
| A-03-7 | Tokens (registered by `wonky_slides/lib/theme/slides_tokens.dart`, light/dark): `slidesSelection`, `slidesHandleFill`, `slidesAdjustHandle`, `slidesGuide`, `slidesUserGuide`, `slidesTableSelection`, `placeholderBorder`, `slideShadow`, `spellingError`. |

---

## 21. Acceptance criteria

1. Click, Shift/Mod-click, marquee (inside/touching), double-click into groups, Tab cycling and
   Esc behave per §3; locked elements are click-through; hidden elements are not drawn.
2. Moving 20 elements with smart guides shows alignment and equal-spacing guides, snaps within
   6 px, and writes one undo step naming only `x,y`; a concurrent recolor by another client
   survives (multi-client harness).
3. Resize with Shift keeps aspect; Alt resizes from center; group resize scales children without
   writing them; ungroup bakes frames exactly (golden comparison before/after).
4. Text editing: every §6.1 command works on selections and on whole elements; lists indent with
   Tab; auto-fit shrink/resize render identically in editor overlay, static canvas, thumbnail and
   PDF (line breaks equal in goldens).
5. Connectors glued to shapes follow moves without writing the connector row; elbow routes avoid
   both shapes.
6. Image insert works from upload, drop, paste, Drive and URL, offline (renders from local bytes,
   uploads later), and refuses over quota with the quota dialog; crop/mask/replace/reset per §6.5.
7. Tables: Tab navigation, add row on last Tab, merges, borders picker, paste of a 10 × 5 Sheets
   range into a new table and into a cell range.
8. Copy a group of 5 slides with images, a linked chart, builds and code states from deck A and
   paste into deck B: groups/slides/elements/builds/states arrive, images are re-homed (quota
   counted to B's owner), the chart stays linked, *Keep source formatting* brings A's theme once.
9. Paste from Write (headings, nested lists, table, image, code block) and from the OS (image,
   plain text) produce the elements of §12.4–12.5.
10. Find & replace all across slides and notes is one undo step and skips soft-locked bodies with
    the stated toast.
11. Keyboard map §10 complete (test iterates bindings vs. the registry); all transforms reachable
    without a pointer; screen reader announces selection and slide changes.
12. Budgets of §18 met on reference hardware (perf suite).

## 22. Tests

- **Core unit**: `SnapEngine` (targets, thresholds, equal spacing, rotation-aware boxes),
  geometry library (paths, adjust handles, connection sites), connector routing (straight, elbow
  avoiding boxes), group transform math (child space ⇄ slide space, bake on ungroup), auto-fit
  algorithm, text schema validator/normalizer, clipboard codec and id remapping, Write/Sheets/HTML
  paste mappers, reading-order algorithm, contrast checker.
- **Command tests**: every command in §19 executes → undo → redo with state + selection equality
  (`CommandTestHarness` on an in-memory `DeckSession`).
- **Widget tests**: selection gestures, marquee, handles, crop mode, table keyboard, text editor
  overlay alignment with rotation/flip, soft-lock refusal popover.
- **Goldens** (light/dark app chrome; slides in both appearances): selection chrome, smart guides,
  every shape geometry, lines/arrowheads, image crop/mask/adjustments, tables with merges/borders,
  text styles and lists, editor-overlay vs static text equality.
- **Multi-client harness**: concurrent move vs recolor, concurrent group/ungroup, text soft-lock
  and *Edit anyway* LWW + recovery offer, cross-device paste of the same payload.
- **Perf**: §18 scenarios with seeded decks (200 slides × 40 elements).
