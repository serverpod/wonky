# Slides 06 · Animations, Transitions and Magic Move

This spec defines how things move in Wonky Slides: **builds** (animations of elements on a
slide: build in, build out, emphasis, motion path), their **triggers and timing**, the
**animation pane**, **slide transitions** (2D and 3D), **Magic Move** (morphing matched
elements between consecutive slides), the pure-Dart **timeline model** in `wonky_slides_core`
that every consumer shares (editor preview, presenting, PDF "builds as pages", thumbnails,
MCP), how it is **rendered** in Flutter, **reduced motion**, **performance budgets**, the
commands and undo.

The goal is the best of the popular apps: Keynote's build quality, Magic Move and "build by
bullet" with dimming; PowerPoint's animation pane, triggers, motion paths and Morph matching
levels (objects / words / characters); Google Slides' simplicity (one panel, sensible
defaults); Pitch's and Figma Slides' Smart Animate with spring curves and named-layer matching;
reveal.js's step-by-step code focus (code builds are detailed in
[07-code-blocks.md](07-code-blocks.md)).

Read first:
- [02-data-model.md](02-data-model.md): `Deck`, `Slide` (`sortKey`, `groupId`, `transitionJson`),
  `SlideElement` (`kind`, frame, `zKey`, `name`, `dataJson`, `matchKey`), `SlideBuild`, `CodeState`,
  `ChartLink`, `Deck.defaultsJson`. This spec owns the **behavior and JSON schemas** of
  `SlideBuild` (`optionsJson`), `Slide.transitionJson`, the motion keys of `Deck.defaultsJson`
  and the semantics of `SlideElement.matchKey` (§8.2, §20).
- [03-editor-canvas-and-objects.md](03-editor-canvas-and-objects.md) (canvas, selection,
  element rendering, text layout), [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md)
  (menus, toolbar, side panels), [05-themes-layouts-masters.md](05-themes-layouts-masters.md),
  [07-code-blocks.md](07-code-blocks.md) (code builds), [08-charts-from-sheets.md](08-charts-from-sheets.md)
  (chart builds, 3D camera), [10-presenting-and-pdf.md](10-presenting-and-pdf.md) (presenting,
  PDF builds as pages), [11-mcp-and-ai.md](11-mcp-and-ai.md) (`slides.set_builds`,
  `slides.set_transition`, "Animate this slide").
- Suite [08-commands-and-undo.md](../08-commands-and-undo.md), [02-design-system.md](../02-design-system.md)
  §6 (motion, *Reduce motion*), [11-quality-testing-accessibility.md](../11-quality-testing-accessibility.md).

Priorities: **P0** = Slides MVP (M9) or motion milestone (M10) as marked in
[12-implementation-plan.md](12-implementation-plan.md) — everything in this spec is M10 unless
noted; **P1** = v1 if possible; **P2** = designed now, built later.

Units: frames and distances are in **slide units (su)**, the deck's logical coordinate system
(default 1920 × 1080 su for 16:9, see 02). Durations and delays are integer **milliseconds**.

---

## 1. Concepts

| Term | Meaning |
|------|---------|
| **Build** | One animation of one element on a slide (a `SlideBuild` row). Kinds: **in** (element appears), **out** (disappears), **emphasis** (changes while visible), **motion** (moves along a path or to a target transform). |
| **Part** | A build can animate an element in parts (**delivery**): paragraphs, words or characters of text; series, categories or points of a chart; lines of a shape group. Each part is scheduled separately. |
| **Step** | What one click (→, Space, clicker) plays. A step contains one or more builds/parts that run with or after each other. **Step 0** holds the builds that run automatically right after the slide appears. |
| **Transition** | How the slide replaces the previous one (`Slide.transitionJson`), played when the slide is **entered** (PowerPoint and Google Slides convention; Keynote attaches it to the outgoing slide — we don't). |
| **Magic Move** | A transition type that morphs elements of the previous slide into their matched counterparts on this slide (Keynote Magic Move, PowerPoint Morph, Figma Smart Animate). |
| **Match key** | `SlideElement.matchKey`: elements on two slides with the same key are the "same object" for Magic Move. |
| **Timeline** | The compiled, deterministic schedule of a slide (transition + steps), computed by `SlideTimelineCompiler` in `wonky_slides_core` (§9). |
| **Frame** | The visual state of every element at one timeline position (`SlideFrame`, §9.3). |
| **Edit frame** | What the editor canvas shows: every element visible in its authored state, no builds applied (§9.6). |

---

## 2. Build model

### 2.1 `SlideBuild` row (fields; synced, field-level LWW)

| Field | Type | Meaning |
|-------|------|---------|
| `id` | UUID | Row id (the deck's RevLog file, `fileId`, is set by the server's sequencer). |
| `slide` (`slideId`) | FK | Slide the build belongs to (cascade). |
| `element` (`elementId`) | FK | Animated element (top-level element or element group; children of groups: P2) (cascade). |
| `sortKey` | String | Fractional index: order in the slide's build sequence (tie-break on `id`). |
| `kind` | `BuildKind` | `buildIn`, `buildOut`, `emphasis`, `motion`. |
| `effect` | String | Effect id from the catalog (§3). Unknown ids (from newer clients) play as `fade` (in/out) or are skipped (emphasis/motion), and the pane shows "Effect not supported by this version". |
| `trigger` | `BuildTrigger` | `onClick`, `withPrevious`, `afterPrevious` (§4). |
| `delayMs` | int | 0–60,000. |
| `durationMs` | int | 0–20,000. Ignored by effects whose duration is derived (typewriter, type-in, `appear`). For springs it is the *perceptual* duration (§4.3). |
| `easing` | String | Easing expression (§4.3), e.g. `easeOut`, `cubic(0.2,0,0,1)`, `spring(0.5,0.25)`. |
| `optionsJson` | String? | Effect parameters, delivery, parts, after-build behavior, repeat (§2.2). Carries `"v": 1`; null = all defaults. |

Builds are deleted by cascade with their element or slide. A build whose element no longer
exists (concurrent delete) is ignored by the compiler and removed by the next editor that opens
the slide (idempotent maintenance write, no undo step).

### 2.2 `optionsJson`

```jsonc
{
  "v": 1,
  "params": { … },                    // effect parameters (§3 tables); omitted keys = defaults
  "delivery": {                        // §2.3; omitted = whole element at once
    "by": "paragraph",                 // all | paragraph | paragraphGroup | line (P1) | word | character
                                       // | series | category | point | chartElement
    "order": "forward",                // forward | backward | center | edges | random (seeded)
    "parts": { "from": 1, "to": null },// 1-based inclusive range of parts to build; null = to the end
    "partTrigger": "onClick",          // onClick | afterPrevious | withPrevious (stagger)
    "staggerMs": null,                 // with withPrevious/afterPrevious: gap between part starts; null = auto
    "includeBackground": true          // charts: axes, gridlines, legend and titles come with part 1
  },
  "afterBuild": {                      // what happens to earlier parts when the next part builds
    "mode": "none",                    // none | dim | hide
    "dimOpacity": 0.35,                // mode dim
    "dimColor": null                   // optional color for dimmed text (theme ref or hex)
  },
  "repeat": {                          // emphasis (transient effects) only
    "count": 1,                        // 1–20
    "untilNextClick": false,           // loops until the next step starts
    "autoReverse": false
  },
  "persist": null                      // emphasis: override the effect's default persistence (§3.3)
}
```

### 2.3 Delivery (building in parts)

| `delivery.by` | Applies to | Parts | Notes |
|---------------|------------|-------|-------|
| `all` | everything | 1 | Default. |
| `paragraph` | text, shapes with text, placeholders | each paragraph (bullet) | Keynote "By Bullet". Empty paragraphs are skipped. |
| `paragraphGroup` | same | each top-level paragraph with its nested sub-bullets | Keynote "By Bullet Group". |
| `line` (P1) | same | each laid-out line | Depends on layout; recomputed when text reflows. |
| `word` | same | each word (Unicode word boundaries; punctuation sticks to the preceding word) | Auto `staggerMs` 60. |
| `character` | same | each grapheme cluster | Auto `staggerMs` 30. Max 2,000 parts; longer texts fall back to `word` (pane warning). |
| `series` | chart | background (if `includeBackground`), then each visible series | Order = legend order. |
| `category` | chart | background, then all series at category 1, 2, … | Pie: each slice. |
| `point` | chart | background, then (series 1, point 1), (series 1, point 2), … | Max 500 parts; more → falls back to `series`. |
| `chartElement` | chart | background, then series 1 … n (lines draw on), then data labels | Keynote "By Element". |
| `codeStep` / `codeState` | code | — | Code elements don't use delivery; their steps are separate builds (07 §6). |

- `partTrigger: onClick` makes **each part its own step** (one click per bullet), the default
  for `paragraph`/`paragraphGroup` with in-builds. `withPrevious` starts parts staggered by
  `staggerMs` (auto: `durationMs × 0.15` for paragraphs, 60 ms words, 30 ms characters);
  `afterPrevious` starts each part when the previous part ends (+ `staggerMs`, default 0).
- `order`: `backward` (last part first), `center` (middle out), `edges` (outside in), `random`
  (Fisher–Yates with a PRNG seeded by `hash(build.id)`, so every client and the PDF agree).
- `parts.from/to` builds only a range (Keynote "Build from 2 to 5"); parts outside the range
  are visible from the start (in-builds) or stay visible (out-builds).
- `afterBuild.mode: dim` dims the previous parts to `dimOpacity` (or recolors text to
  `dimColor`) as the next part starts (Keynote "Highlighted bullet"/PowerPoint "After animation:
  dim"); `hide` removes them. Dimming animates over 300 ms and is part of the next part's step.

### 2.4 Several builds on one element

An element may have several builds in sequence, e.g. in → emphasis → motion → out → in again.
Rules (enforced by the compiler; violations show a warning icon in the pane and are skipped):
- An element's **initial visibility** is hidden if its first visibility-changing build is a
  build in; otherwise visible.
- A build in on an already visible element and a build out on an already hidden element are
  skipped ("Element is already visible").
- Emphasis and motion builds on a hidden element are skipped.
- Builds on elements of a slide's layout/master (logo, footer): not in v1 (P2).

---

## 3. Effect catalog

Every effect has an id, the element kinds it applies to (`text` = text boxes, placeholders and
shapes with text; `visual` = every kind), parameters (`params`) with defaults, a default duration
and easing, and its **reduced-motion** replacement (§13). The **Animate** panel shows the effects
as a grid of tiles with a live hover preview (§5.3).

### 3.1 Build in (`kind: buildIn`)

| Effect id | Name | Kinds | `params` (defaults) | Default duration / easing | Reduced motion |
|-----------|------|-------|---------------------|---------------------------|----------------|
| `appear` | Appear | visual | — | 0 | same |
| `fade` | Fade | visual | — | 500 / `easeOut` | same |
| `rise` | Rise | visual | `distance: 40` (su), `fade: true` | 600 / `spring(0.6,0)` | fade |
| `moveIn` | Move in | visual | `direction: left` (left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight), `distance: "offSlide"` \| su, `fade: false` | 700 / `easeOutCubic` | fade |
| `scale` | Scale | visual | `from: 0.5` (0–4), `origin: center` (center or one of 8 anchors), `fade: true` | 500 / `easeOutCubic` | fade |
| `pop` | Pop | visual | `from: 0`, `bounce: 0.35` (0–0.8) | 500 / `spring(0.5,0.35)` (from `bounce`) | fade |
| `zoom` | Zoom | visual | `from: 3` (scale toward the viewer), `fade: true` | 600 / `easeOutQuint` | fade |
| `blur` | Blur | visual | `from: 24` (blur sigma in su), `fade: true` | 600 / `easeOut` | fade |
| `wipe` | Wipe | visual | `direction: left`, `softness: 0.2` (0–1, feathered edge as fraction of the element) | 600 / `easeInOut` | fade |
| `iris` | Iris | visual | `shape: circle` (circle, rect, diamond), `origin: center` | 600 / `easeInOut` | fade |
| `dissolve` | Dissolve | visual | `cell: 6` (su, noise cell size) | 700 / `linear` | fade |
| `drop` | Drop | visual | `height: "offSlide"` \| su, `bounces: 2` (0–3) | 900 / physical (gravity + restitution 0.4) | fade |
| `flip` | Flip | visual | `axis: y` (x, y), `direction: forward`, `perspective: 0.0012` | 700 / `easeOutCubic` | fade |
| `rotate` | Rotate | visual | `angle: -90` (−720…720°), `origin: center`, `scale: 1`, `fade: true` | 700 / `easeOutCubic` | fade |
| `typewriter` | Typewriter | text | `cps: 30` (characters/s), `caret: true`, `jitter: 0` (0–1) | derived = chars / cps | `fade` per paragraph |
| `lineDraw` | Draw line | shape, line, connector, arrow, icon | `fillDelay: 0.6` (fraction of the duration after which the fill fades in), `direction: forward` | 1000 / `easeInOut` | fade |
| `chartGrow` | Grow (chart) | chart | `from: baseline` (baseline, center); bars/columns grow from the baseline, lines and areas draw on left to right, pie wedges sweep, 3D items rise from the floor (08 §9) | 800 / `easeOutCubic` per part | fade |
| `codeType` | Type code | code | Types the first code state from empty (07 §5) | derived | fade |
| `shimmer` (P2) | Shimmer | text | particles condense into glyphs | 1200 | fade |

### 3.2 Build out (`kind: buildOut`)

Mirror effects of §3.1 with the same parameters, played in reverse direction semantics:
`disappear`, `fadeOut`, `sink` (mirror of rise), `moveOut` (`direction` = where it goes),
`scaleOut` (`to: 0.5`), `popOut` (anticipation: grows 8 %, then collapses), `zoomOut` (`to: 3`,
toward the viewer), `blurOut`, `wipeOut`, `irisOut`, `dissolveOut`, `fall` (mirror of drop:
falls off the bottom with gravity, `rotation` up to 15°), `flipOut`, `rotateOut`,
`eraseText` (mirror of typewriter: characters disappear from the end, like backspacing),
`lineErase`, `chartShrink`. Reduced motion: `fadeOut`.

### 3.3 Emphasis (`kind: emphasis`)

**Transient** effects return to the previous state; **persistent** effects change the element's
state for the rest of the slide (the next builds start from it; PDF builds-as-pages show it).
`optionsJson.persist` can turn a persistent effect transient (e.g. a spin that returns).

| Effect id | Name | Kinds | `params` | Default | Persistence | Reduced motion |
|-----------|------|-------|----------|---------|-------------|----------------|
| `pulse` | Pulse | visual | `scale: 1.1`, `count: 1` | 500 / `easeInOut` | transient | skipped |
| `bounce` | Bounce | visual | `height: 40` su, `count: 1` | 700 / physical | transient | skipped |
| `shake` | Shake | visual | `amplitude: 12` su, `count: 3`, `axis: x` | 500 | transient | skipped |
| `blink` | Blink | visual | `count: 2` | 600 | transient | skipped |
| `spin` | Spin | visual | `angle: 360` (−3600…3600), `origin: center` | 1000 / `easeInOut` | persistent (net angle) | instant + fade |
| `grow` | Grow / shrink | visual | `scale: 1.2` (0.1–4), `origin: center` | 500 / `spring(0.5,0.2)` | persistent | instant + fade |
| `opacityTo` | Transparency | visual | `opacity: 0.4` | 500 / `easeInOut` | persistent | same (fade) |
| `colorChange` | Color change | shape, text, line, icon | `property: fill` (fill, stroke, text), `to: "theme:accent2"` | 500 / `easeInOut` (OKLab) | persistent | instant |
| `highlight` | Highlight | text | `color: "theme:highlight"` (marker), `style: marker` (marker, underline, box) — sweeps behind the text left to right, per part | 600 / `easeInOut` | persistent | instant |
| `chartHighlight` | Highlight series | chart | `target: {series: key}` or `{point: [key, index]}`, `dimOthers: 0.3` | 400 | persistent until `chartHighlightClear` | instant |
| `chartHighlightClear` | Clear highlight | chart | — | 400 | persistent | instant |
| `chartOrbit` | Orbit (3D) | 3D chart | `azimuth: 360` (Δ°), `elevation: 0` (Δ°), `persist: false` | 6000 / `easeInOut` | transient by default (returns), persistent if `persist` | skipped |
| `chartCamera` | Rotate to angle (3D) | 3D chart | `azimuth`, `elevation`, `perspective` (absolute; null = keep), `preset?` (08 §10.2) | 1200 / `easeInOutCubic` | persistent | instant + fade |
| `codeHighlight` | Highlight lines | code | `step: n` (index into the current state's highlight steps; 07 §4) | 400 | persistent | instant + fade |
| `codeState` | Next code state | code | `state: n`, `mode: type` (type, morph, instant) + typing params (07 §5) | derived | persistent | crossfade 300 |

### 3.4 Motion (`kind: motion`)

| Effect id | Name | `params` | Default | Notes |
|-----------|------|----------|---------|-------|
| `path` | Motion path | `path`: SVG-style path data in su **relative to the element's center at the start of the build** (`M0 0 C 120 -80 …`), `preset?` (line, arc, curve, circle, zigzag, custom), `orientToPath: false`, `relativeEnd: true` | 1500 / `easeInOut` | The element ends at the path's end (persistent). Path presets are generated as editable paths. |
| `moveTo` | Transform | `to: {x?, y?, w?, h?, rotation?, opacity?}` (absolute frame values; omitted = unchanged), `origin: center` | 1000 / `spring(0.8,0)` | Keynote's Move/Scale/Rotate/Opacity actions in one: interpolated like Magic Move within the slide (§8.4 interpolation rules, frame and rotation only). Persistent. |

Motion paths are edited on the canvas (§5.5). Path data is stored in su; when the element is
moved in the editor, the path moves with it (relative). Paths are limited to 200 segments.

### 3.5 Parameter validation

`params` are validated by `EffectCatalog.validate(kind, effect, params)` in `wonky_slides_core`
(shared by commands, MCP and the AI). Out-of-range numbers are clamped with a warning (MCP
`warnings`), unknown keys are kept (forward compatibility), wrong types fail with `invalid_args`.
The catalog is data (`EffectSpec {id, kind, appliesTo, params: [ParamSpec], defaultDurationMs,
defaultEasing, derivedDuration, persistence, reducedMotion}`) so the pane, the JSON schema for
MCP ([11](11-mcp-and-ai.md) §2.7) and the AI prompt's effect list are generated from it.

---

## 4. Triggers and timing

### 4.1 Triggers

| Trigger | Name in UI | Semantics |
|---------|------------|-----------|
| `onClick` | On click | Starts a **new step**; starts `delayMs` after the click. |
| `withPrevious` | With previous | Same step; starts `delayMs` after the **start** of the previous build in sequence order. |
| `afterPrevious` | After previous | Same step; starts `delayMs` after the **end** of the previous build (including all its parts and repeats). |

- Builds before the first `onClick` build form **step 0** and start automatically when the slide's
  transition ends (Keynote "After transition"). The first build of a slide with `withPrevious`
  starts with the transition's end; with `afterPrevious` likewise (there is no previous build).
- A build whose parts use `partTrigger: onClick` contributes one step per part (the first part
  follows the build's own trigger).
- Trigger "on click of an element" (PowerPoint interactive triggers) and "on media bookmark" are
  not supported (P2: `onElementClick {elementId}` for interactive decks).

### 4.2 Step compilation (normative)

```
steps = [Step(0)]
for b in builds sorted by (sortKey, id) where valid(b):
  if b.trigger == onClick: steps.add(Step(steps.length)); b.start = b.delay
  elif b is the first build of the current step: b.start = b.delay
  elif b.trigger == withPrevious: b.start = prev.start + b.delay
  else /* afterPrevious */:       b.start = prev.end   + b.delay
  expand parts: part k starts at b.start + offset(k) (stagger/after-previous chain);
                parts with partTrigger onClick open new steps (k ≥ 2)
  b.end = max(part ends)  (+ repeats)
  prev = b
step.durationMs = max(end of its builds) (0 for an empty step 0)
```

### 4.3 Easing

`SlideBuild.easing` and transition easing use one expression grammar (parsed by `Easing.parse`):

| Expression | Curve |
|------------|-------|
| `linear`, `ease`, `easeIn`, `easeOut`, `easeInOut` | CSS equivalents |
| `easeInCubic`, `easeOutCubic`, `easeInOutCubic`, `easeOutQuint`, `easeInOutQuint`, `easeOutExpo` | Penner curves |
| `easeOutBack`, `easeInBack`, `easeInOutBack` | Overshoot (back = 1.70158) |
| `cubic(x1,y1,x2,y2)` | Cubic Bézier (x in 0–1) |
| `spring(d,b)` | Spring with perceptual duration `d` seconds and bounce `b` (−1…1; 0 = critically damped, > 0 bouncy, < 0 overdamped) — the SwiftUI/Figma model. |
| `steps(n)` | Discrete steps (used by `blink`) |

Springs: stiffness `k = (2π / d)²`, damping `c = 4π(1 − b) / d` for `b ≥ 0` and
`c = 4π / (d (1 + b))` for `b < 0`, mass 1, initial velocity 0; evaluated in closed form
(under-, critically or over-damped solution), so `value(t)` is exact and deterministic. The
build's effective length is the **settle time** (|x − 1| < 0.001 and |v| < 0.01), computed
analytically and capped at `4 × d`; the pane shows it as "≈ 0.62 s". The duration field of a
spring-eased build edits `d`.

The pane offers presets: *Smooth* (`easeInOutCubic`), *Snappy* (`spring(0.4,0)`), *Bouncy*
(`spring(0.5,0.35)`), *Gentle* (`spring(0.9,0)`), *Linear*, *Ease in*, *Ease out*, *Custom…*
(curve editor with two Bézier handles and a preview dot; spring mode with duration and bounce
sliders).

### 4.4 Slide advance

`Slide.transitionJson.advance` (§7.1): `onClick` (default) or `auto` with `afterMs` — after the
last step has settled (or right after the transition when there are no builds) the presentation
advances by itself. Steps after step 0 still need clicks unless `advance.autoBuilds: true`, which
turns every `onClick` into `afterPrevious` with `advance.buildDelayMs` (self-running decks,
kiosk mode [10](10-presenting-and-pdf.md) §9; rehearsed timings override the delays).

---

## 5. Animate tab (animation pane)

The **Animate tab of the docked inspector** ([04](04-screens-menus-toolbar.md) §7.1, §7.3;
opened by the toolbar's *Animate* button, *Arrange › Animate…*, *Slide › Transition…* and
`slides.panel.animate {tab}`, an alias of `slides.inspector.open {tab: animate, sub}`) with three
sub-tabs. It replaces Keynote's Animate inspector +
Build Order window and PowerPoint's ribbon + Animation Pane. Width is the inspector width
(260–420 px, 04 §7.1); everything below must work at 260 px.

```
┌ Inspector: Format · [Animate] · Slide ─────────────────┐
│ [ Transition ] [ Build ] [ Order ]                     │
├────────────────────────────────────────────────────────┤
│ Build tab — "Title 2" selected                          │
│  [ In ] [ Action ] [ Out ]          (counts: 1 · 0 · 0) │
│  ┌──────────────────────────────────────────────────┐  │
│  │ ▣ Fade   ▣ Rise   ▣ Move in  ▣ Scale  ▣ Pop  …   │  │  effect grid, live hover preview
│  └──────────────────────────────────────────────────┘  │
│  Effect      Rise                              [▶]     │
│  Distance    [ 40 ] su                                  │
│  Delivery    [ By bullet ▾ ]  Parts [1] to [end]        │
│  Start       [ On click ▾ ]  Delay [0.0] s              │
│  Duration    [ 0.6 ] s      Easing [ Snappy ▾ ]         │
│  After build [ Dim ▾ ] 35 %                             │
│  [ + Add another build ]                     [Remove]   │
├────────────────────────────────────────────────────────┤
│ Order tab                                               │
│  Step 0 · automatic                                     │
│   ⚡ ▣ Logo            Fade              ▕██      ▏     │
│  Click 1                                                │
│   ▶ ▣ Title 2         Rise        ↳     ▕  ███    ▏     │
│   ⏵ ▣ Chart 1         Grow · series     ▕   ██████▏     │
│  Click 2 … 5  (Body: Rise by bullet)                    │
│   ▶ ▣ Body            Rise · 4 parts    ▕█▏…            │
│  [ ▶ Preview ]  [ ▶ Play from selected ]  [ ⚙ ]         │
└────────────────────────────────────────────────────────┘
```

### 5.1 Transition tab

Shown for the current slide (multi-selection in the navigator: edits apply to all selected
slides). Effect grid (§7.2) with hover previews rendered from the actual previous and current
slide thumbnails; parameters of the selected transition; **Advance** (On click / Automatically
after [n] s, Auto-play builds); *Apply to all slides* (`slides.transition.applyToAll`);
Magic Move options (§8.6) when Magic Move is chosen; *Preview* (plays previous slide → this
slide in the canvas).

### 5.2 Build tab

- Context: the selected element(s). With nothing selected the tab says "Select an object to
  animate it" and lists the slide's animated elements as shortcuts.
- Sub-tabs **In / Action / Out** (Action = emphasis + motion), each with a count badge.
- Choosing an effect for an element that has none **adds** a build (`slides.animate.addBuild`,
  appended to the end of the sequence, trigger `onClick` — or `withPrevious` if the user holds
  Alt while clicking the tile); choosing another effect for the selected build **changes** it.
- *Add another build* adds a second build of the same kind (e.g. two emphasis builds).
- Parameters are rendered from the catalog's `ParamSpec`s: direction pickers (8-way arrow
  pad), sliders with numeric input (`WonkyNumberStepper`), color pickers (`WonkyColorPicker`
  with theme colors), selects. Every field edit is one command (`slides.animate.updateBuild`
  with a `coalesceKey` per field so slider drags are one undo step).
- Multi-selection of elements: tiles apply the effect to every selected element (one build
  each, ordered by z-order top to bottom, triggers: first `onClick`, rest `withPrevious` — Alt
  inverts); shared parameters show mixed states ("—").
- Elements of kinds that don't support an effect show the tile disabled with the reason tooltip
  ("Typewriter works on text only").

### 5.3 Effect tiles and previews

Each tile (88 × 64 px) shows the effect's glyph; on hover (or keyboard focus for 400 ms) it
plays the effect on a miniature of the **actual** element (rendered with the same engine at tile
size) on loop. Tiles are grouped: *Basic* (appear, fade, rise, move in, scale, pop), *Exciting*
(zoom, blur, flip, rotate, drop, dissolve, wipe, iris), *Text* (typewriter, highlight), *Shape*
(draw line), *Chart* / *Code* (when applicable). A search field filters tiles by name.

### 5.4 Order tab

- Lists every build of the slide grouped by step headers ("Step 0 · automatic", "Click 1", …).
  Row: kind color bar (in = green, action = amber, out = red, motion = blue; both themes have
  ≥ 3:1 contrast tokens `buildIn`, `buildEmphasis`, `buildOut`, `buildMotion` added to
  `WonkyColors`), trigger icon (`mouse-pointer-click` / `link` (with previous) / `clock`
  (after previous)), element icon + name (Element `name`, else "Title 2"), effect name with
  delivery ("Rise · by bullet · 4 parts"), and a **timing bar** (start/duration on a shared
  time scale of the step; P1: drag the bar's ends to edit delay/duration — PowerPoint's
  advanced timeline).
- Rows with parts expand (chevron) to show the parts ("Paragraph 2: Pricing").
- **Reorder** by drag-and-drop (drop indicator between rows; dropping onto a step header puts
  the build first in that step) or `Mod+Alt+↑/↓` while the Order list has focus (keymap scope
  `slidesAnimatePane`; on the canvas these chords align objects, 04 §4.7). Moving a build into the middle of a step
  keeps its trigger; moving the first build of a step changes it to `onClick` only if the user
  drops it onto a step boundary (indicator shows "New click"). One command
  (`slides.animate.moveBuilds`) per drop = one undo step.
- Multi-select rows (Shift/Mod-click): set trigger, delay, duration, easing for all; delete; copy.
- Selecting a row selects the element on the canvas and switches the Build tab to that build.
- Row context menu: *Preview from here*, *Set trigger ▸*, *Move up/down*, *Copy build*,
  *Remove*, *Select element*.
- Warnings (§2.4, unsupported effects) show a `triangle-alert` icon with tooltip.
- Footer: **Preview** (plays the whole slide from step 0, including the transition when
  *Include transition* is on in ⚙), **Play from selected** (seeks to the start of the selected
  build's step with the frame state of the end of the previous step and plays from there),
  ⚙ menu: *Auto-preview changes* (default on: changing an effect plays it once on the canvas),
  *Include transition in preview*, *Show build order on canvas*.

### 5.5 Canvas affordances

- **Build order badges** (when the Animate tab is open or View › *Show build order*,
  `slides.animate.toggleOrderOverlay`): small chips at each animated element's top-left
  showing its step numbers ("1", "2–5", "0" for automatic), colored by kind. Clicking a chip
  selects that build in the Order tab. Badges are not in exports or present mode.
- **Preview on canvas**: previews play in place on the editing canvas (the canvas switches to
  a read-only "preview" mode for the duration: chrome dimmed, a floating bar with *Stop*
  (Esc) and a scrubber (P1)); any click/keypress stops the preview and returns to the edit
  frame.
- **Motion path editing**: a selected `path` build shows its path as a dashed line from a green
  start dot to a red end dot, with a ghost of the element at the end. Dragging the end dot moves
  the end; double-clicking the path enters vertex edit mode (drag vertices and Bézier handles,
  double-click a segment to add a vertex, Delete to remove; Esc exits). *Draw path* tool
  (`slides.animate.drawMotionPath`): freehand drag on the canvas, simplified with
  Ramer–Douglas–Peucker (tolerance 2 su) and fitted to cubic Béziers.
- **Transform (`moveTo`) editing**: "Set end state" mode shows a ghost copy of the element that
  the user moves/resizes/rotates with normal handles; *Done* writes `params.to`.
- Navigator thumbnails show a small `sparkles` glyph on slides with builds and a transition
  glyph on slides with a transition other than none (04).

### 5.6 Animation painter and copy/paste

- *Copy animation* / *Paste animation* (`slides.animate.copyBuilds` / `pasteBuilds`, PowerPoint
  "Animation Painter"): copies the selected element's builds (effects, timing, options) and
  pastes them onto other selected elements (appended in sequence order, triggers preserved
  relative). Double-click the toolbar painter to keep it active for several targets (Esc ends).
- Copying an element (03 clipboard) includes its builds; pasting onto another slide appends them
  at the end of that slide's sequence.

### 5.7 As built (SL-30)

The Animate tab, the animation pane and the transitions UI are in `wonky_slides/lib/features/inspector/animate/`
(`AnimateTab`, `TransitionTab`, `BuildTab`, `OrderTab`, `EffectTileGrid`, `animate_controls.dart`),
their view state and canvas side in `wonky_slides/lib/features/builds/` (`AnimateView` — selected
builds, the Build tab's kind sub-tab, the canvas toggles, the ⚙ options, copied builds, timelines
compiled per slide revision; `AnimatePreview`; `AnimateCanvasLayer`; `BuildOrder`; `BuildLabels`
and `EasingPresets`; `BuildRecipes` and `MotionPaths`) and the commands in
`wonky_slides/lib/commands/animate_commands.dart`. Every edit goes through SL-24's `BuildEdits`
(one `slides.rows` undo step each).

- **Commands.** Every command of §15 except `drawMotionPath` and `editMotionPath` (no canvas path
  editing yet). Additions: `slides.animate.selectBuilds {buildIds, selectElements?}` (Order list
  selection, MCP-operable), `slides.animate.togglePreviewOption {option: autoPreview |
  includeTransition | fullMotion}` (the ⚙ menu), `slides.animate.moveBuilds {by: ±1}` (the
  `Mod+Alt+↑/↓` bindings of the `slidesAnimatePane` scope; Delete/Backspace remove there too),
  `slides.animate.addBuild` also takes the context menu's `kind: in | action | out` and, without an
  `effect`, adds the quick-add effect (the deck's `defaultsJson.build` of that kind, else Slides
  settings › *Default build* for in, Pulse for action, Fade out for out) and opens the Build tab.
  `slides.animate.preview` also takes `buildIds` (only those builds). The feature switch covers the
  prefixes `slides.transition.` and `slides.element.setMatchKey` too.
- **`coalesceKey`.** The dispatcher has no coalescing, so `updateBuild` with a `coalesceKey` applies
  its plan in a transaction of its own with that key (`UndoService` merges steps with the same key
  within the undo window); the dispatcher's transaction stays empty. Steppers send one key per
  field; sliders commit on release.
- **Previews** use SL-29's `SlidePlayer` and `SlidePlaybackStage`: `AnimatePreview` plays the slide
  (optionally entered from the previous slide), *from here* (the build's step, from the end state
  of the step before), only some builds (▶ of the edited build; *Auto-preview changes* after an
  effect change), the transition (into the slide, then step 0) or a hovered effect (looping); steps
  follow each other with a 450 ms pause standing in for the clicks. The canvas shows the player
  over the slide (`AnimateCanvasLayer`: read-only, selection chrome hidden, a floating bar with
  *Stop*); a press, any key (Esc consumed) or a change of the slide stops it; a collaborator's
  change shows "The animations changed — Preview again". Previews compile with *Reduce motion*
  (OS/app setting or Slides › *Reduce motion in the editor*) unless *Preview full motion*; the tab
  shows the banner of §13.
- **Build tab.** Kind sub-tabs with counts and the kind color, chips for several builds of one kind
  on an element, a search field, the effect grid (groups Basic, Exciting, Emphasis, Text, Shape,
  Motion, Chart, Code — chart and code groups only when such an object is selected; tiles of
  other kinds disabled with the reason), parameters rendered from the `ParamSpec`s (direction pad,
  segmented choices or selects, switches, steppers, colors with theme colors, distance with *Off
  slide*), motion path presets (`MotionPaths`: line, arc, curve, circle, zigzag; the canvas draws
  the path dashed from a green to a red dot), the `moveTo` end state as numeric fields, the series
  of `chartHighlight`, delivery (text: paragraph, paragraph group, word, character; charts: series,
  category, point, element) with order, parts from/to, part start and stagger, after-build
  keep/dim/hide with the dim level, timing (start, delay, duration — *Automatic* for derived
  durations —, easing presets with the spring's settle time), repeat for transient emphasis and
  *Return to the start* for persistent emphasis, *Add another build*, *Build all steps* (code:
  `codeHighlight` per step of the first state, then `codeState` + its steps per further state;
  charts: `chartGrow` by series, each part on click), *Copy/Paste animation*. Several selected
  builds share the timing fields (mixed values show "—").
- **Order tab.** Steps "Automatic" / "Click n" with their length, rows with the kind bar, trigger
  glyph, element glyph and name, effect summary ("Rise · by paragraph · 3 parts"), timing bar on the
  step's scale, warnings (`TimelineWarning` codes localized), parts that expand to "Part 2: Two";
  click / Shift / Mod selection, ↑/↓ moves the selection, Enter opens the Build tab, drag and drop
  (vertical slop first so clicks select; above/below the row's middle; a drop on a step header moves
  the builds before that step's first build as a **new click** — `onClick`; step 0: `withPrevious` —
  instead of "first in that step"), the row context menu of §5.4 and the footer *Preview* / *Play
  from selected* / ⚙ (*Auto-preview changes*, *Include transition in preview*, *Preview full
  motion*, *Show build order*).
- **Transition tab.** Header (slide or "n slides" for a navigator multi-selection; "Uses the
  presentation's default transition" when the slide has none of its own), the tile grid by
  `TransitionGroup` with **live previews inside the tile** (hover/focus 400 ms: the actual previous
  slide → this slide with that transition, looping, `TransitionTilePreview`), duration, easing,
  the type's parameters, the Magic Move options of §8.6 with the match count ("3 objects match the
  previous slide", or the crossfade fallback) and *Show matches*, *Play backwards when going back*,
  advance (On click / Automatically after n s, *Play builds automatically*, the delay between
  builds), *Preview*, *Apply transition to all slides*, *Remove*.
- **Canvas.** Build order badges (Animate tab open or View › *Show build order*; "1", "2–4",
  "0" automatic, "1, 3" for several builds; selected builds outlined; a click selects the build in
  the Order list), Magic Move `link` badges on matched objects (Transition tab open or the toggle;
  tooltip "Matches “Pricing” on slide 1") and with *Show Magic Move matches* the previous slide's
  dashed ghost outlines joined to their counterparts.
- **Magic Move.** *Insert › Magic Move slide* duplicates the slide (keys kept) and sets Magic Move in
  one undo step; Inspector › Arrange › *Magic Move ID* (`slides.element.setMatchKey`, the name as
  placeholder).
- **Settings › Animations.** *Default transition* (every type but Magic Move) with its duration is
  written as `Deck.defaultsJson.transition` of **blank** presentations (core: `CreateDeck
  .defaultsJson`, validated like `SetDeckProps`); decks made from a built-in template take the
  template's own default transition instead (`SlidesTemplate.defaultTransition`, part of its
  design — every built-in has one since SL-36; 04 §15); *Default build* lists the build-in effects for
  every kind of object; *Preview animations on hover* gates the hover previews; *Reduce motion in
  the editor* reduces previews.
- **Tokens.** The build kind colors are `SlidesTokens.buildIn/buildEmphasis/buildOut/buildMotion`
  (Slides only), not `WonkyColors` (A-06-9).

Deviations and not built (see `TODO.md`): build tiles preview **on the canvas** on the selected
objects (Keynote-style), not in a miniature inside the tile (transition tiles do play inside);
no curve editor (*Custom…*: Bézier handles, spring sliders) — custom expressions show as *Custom*
and are kept; no canvas motion path editing (end dot drag, vertex mode, *Draw path*) and no
*Set end state* ghost for `moveTo`; no timing-bar dragging, preview scrubber, presence in the tab
header (P1); the animation painter has no "double-click keeps it active"; F2 doesn't rename from the
Order list; badges only for top-level elements; `Deck.defaultsJson.build` is read but not written;
the navigator's builds/transition glyphs (04 P1) are not built.

---

## 6. Previewing and playing (shared player)

`SlidePlayer` (Flutter, `wonky_slides/lib/features/motion/player/`) drives a compiled timeline
with a `Ticker` and renders frames through the stage (§12). It is used by the canvas preview,
the effect tile previews, present mode and the presenter view's "next build" preview.

| Operation | Behavior |
|-----------|----------|
| `playStep(i)` | Plays step *i* from its start; at the end the frame settles at `endOfStep(i)`. |
| `next()` while a step is running | **Finishes** the running step immediately (jump to its end state) — a second `next()` starts the following step (PowerPoint/Keynote). Present-mode option `advanceDuringBuild: finish | skip` ([10](10-presenting-and-pdf.md) §3). |
| `previous()` | Jumps (no animation) to `endOfStep(i − 1)`; at step 0 goes to the previous slide's final state. |
| `seek(step, ms)` | Shows the exact frame (scrubbing, tests). |
| `playTransition(from, to, reverse)` | Plays the entry transition (§7), then step 0. |

Going **backwards** across slides: navigating from slide B back to A plays **B's transition
reversed** (mirrored direction; Magic Move morphs B → A)
when `transitionJson.reverseOnBack` is true (default), then shows A at its final state. Jumping
to a non-adjacent slide (slide picker, number entry) plays the target's transition forward.

---

## 7. Transitions

### 7.1 `Slide.transitionJson`

```jsonc
{
  "v": 1,
  "type": "push",                   // §7.2 id; "none" = cut
  "durationMs": 700,
  "easing": "easeInOutCubic",
  "params": { "direction": "left" },// per type (§7.2)
  "reverseOnBack": true,            // navigating back plays this transition reversed
  "advance": {
    "mode": "onClick",              // onClick | auto
    "afterMs": 0,                   // auto: delay after the last step settles
    "autoBuilds": false,            // auto: also play onClick steps automatically
    "buildDelayMs": 1000            // autoBuilds: delay before each formerly-onClick step
  },
  "magicMove": { … }                // only for type magicMove (§8.6)
}
```

A `null` column means **the deck default**: `Deck.defaultsJson.transition` (02 §3.1; set with
*Apply to all slides* or Slides settings › Defaults › "Default transition", [04](04-screens-menus-toolbar.md)),
which itself defaults to `{"type": "none"}`. Changing the deck default therefore changes every
slide without an own transition (one row written). `{"type": "none"}` stored on a slide means an
explicit cut.

### 7.2 Catalog

| Type id | Name | `params` (defaults) | Default duration | 2D/3D | Reduced motion |
|---------|------|---------------------|------------------|-------|----------------|
| `none` | None | — | 0 | — | — |
| `fade` | Fade | `through: null` (null = crossfade; or a color: fade through black/white/theme) | 500 | 2D | same |
| `dissolve` | Dissolve | `cell: 8` (noise) | 700 | 2D (shader) | fade |
| `push` | Push | `direction: left` (left, right, up, down) | 700 | 2D | fade |
| `slide` | Slide in | `direction: left` (new slide moves over the old one, which stays) | 600 | 2D | fade |
| `cover` | Cover | `direction` | 600 | 2D (new slide slides over, old dims 20 %) | fade |
| `uncover` | Uncover | `direction` (old slide slides away revealing the new) | 600 | 2D | fade |
| `wipe` | Wipe | `direction` (8-way), `softness: 0.15` | 700 | 2D | fade |
| `iris` | Iris | `shape: circle`, `origin: center` | 700 | 2D | fade |
| `zoom` | Zoom | `mode: in` (in: new slide grows from center; out: old slide shrinks away), `origin: center` | 700 | 2D | fade |
| `flip` | Flip | `axis: y`, `direction: left` | 900 | 3D | fade |
| `cube` | Cube | `direction: left` (the slides are two faces of a cube rotating 90°) | 1000 | 3D | fade |
| `doorway` | Doorway | — (old slide opens like double doors toward the viewer, new slide zooms in from behind) | 1100 | 3D | fade |
| `swap` | Swap | `direction: left` (slides swap places front/back with a perspective arc) | 1000 | 3D | fade |
| `revolve` | Revolve | `direction: left` (old slide swings away on its edge like a door) | 1000 | 3D | fade |
| `magicMove` | Magic Move | §8.6 | 1000 | 2D/3D (morph) | crossfade |
| `pageCurl` (P2) | Page curl | `direction` | 1200 | 3D (flutter_scene or shader) | fade |
| `objectZoom` (P2) | Object zoom | Keynote "object" transitions: elements of both slides animate individually | 1200 | 2D | fade |

All 3D transitions use a camera distance of 2.2 × slide width (perspective factor
`1 / (2.2 × width)` in `Matrix4.setEntry(3, 2, …)`), back-face culling (a face whose transformed
normal points away is not drawn), and a subtle 12 % darkening of faces turned away from the
viewer (cube, flip) for depth. The letterbox color ([10](10-presenting-and-pdf.md) §1.4) fills
the area uncovered during 3D transitions in present mode; in the editor preview the canvas
color.

---

## 8. Magic Move (Smart Animate / Morph)

### 8.1 What it does

When slide B has `transitionJson.type = magicMove` and is entered from slide A (the slide
actually shown before it, which in normal order is the previous non-skipped slide), elements of
A's **final frame** (after all of A's builds, §9.3) are matched with elements of B's **initial
frame** (before B's step 1 — elements hidden by B's in-builds don't take part). Matched pairs
morph from A's appearance to B's; unmatched A elements fade out, unmatched B elements fade in.
Then B's step 0 plays.

### 8.2 Match keys (`SlideElement.matchKey`)

- Every element gets a `matchKey` when created (a new random 22-char id).
- **Duplicating a slide** (`slides.slide.duplicate`, Insert › *Magic Move slide*), copying
  elements to another slide, or pasting them on another slide **keep** the key — the main
  workflow: duplicate the slide, rearrange, set Magic Move (Keynote).
- Duplicating an element **within the same slide** (or pasting onto the slide it came from)
  gives the copy a **new** key.
- Users can set the key by hand: Inspector › Arrange › *Magic Move ID* (text field; the
  element's `name` is suggested; PowerPoint's `!!name` naming and Figma's layer names play the
  same role). MCP sets it with `slides.update_element {match_key}` ([11](11-mcp-and-ai.md)).
- *Insert › Magic Move slide* (`slides.slide.duplicateForMagicMove`): duplicates the current
  slide right after it and sets the new slide's transition to Magic Move (one undo step).

### 8.3 Matching (normative, `MagicMoveMatcher` in `wonky_slides_core`)

Input: A's final-frame elements and B's initial-frame elements (top-level elements; element
groups are matched as units, then their children recursively by the same passes).

1. **Pass 1 — keys**: pairs with equal `matchKey` and both sides present. If a key occurs
   several times on one side (possible after concurrent edits), pair them by z-order rank
   (lowest with lowest).
2. **Pass 2 — content** (when `magicMove.matchByContent`, default true): among still-unmatched
   elements, pair elements of the same `kind` with an equal **content signature**: text →
   normalized plain text; image → `fileUuid`; chart → link source (`spreadsheetUuid`,
   `chartObjectId`) or native data hash; code → text of its displayed state; shape → shape type +
   plain text; icon → icon id. Ties: nearest center distance.
3. **Pass 3 — kind + name** (P1): same `kind` and equal non-empty `name`.
4. Everything else is unmatched.

The editor shows matches: when the current slide's transition is Magic Move, matched elements
carry a small `link` badge (hover: "Matches 'Title' on slide 4"); View › *Show Magic Move
matches* draws A's ghost outlines (dashed, 30 % opacity) with connector lines to their
counterparts on the canvas.

### 8.4 What interpolates

| Property | Interpolation |
|----------|---------------|
| Frame (x, y, w, h) | Center and size linearly (with the easing); for elements with `lockAspect` the size interpolates in log space (no squashing). |
| Rotation | Shortest angular path (`rotation: shortest`); option `rotation: literal` interpolates the stored values (720° spins, Keynote). |
| Opacity | Linear. |
| Fill, stroke, text color, shadow color, gradient stops | In **OKLab**; gradients with the same stop count interpolate stop-wise (position + color), otherwise crossfade within the morphing frame. |
| Corner radius, stroke width, dash pattern (same count), shadow offset/blur | Linear. |
| Shape geometry | Same shape type: interpolate shape parameters (corner radius, star points count must match, arrow head size…). Different types: **path morph** — both outlines flattened, resampled to 128 points by arc length, start index aligned by minimal squared distance, points lerped; multi-subpath shapes (donut, frame) crossfade instead. |
| Text — matching level `object` | Frame interpolates; if the text content differs the old text fades out while the new fades in (crossfade over the middle 60 %). Font size, color, letter spacing interpolate when the text is identical. |
| Text — `word` / `character` | Both texts are laid out; words (or grapheme clusters) are aligned with a Myers diff (`wonky_core` diff over tokens, §9.5); matched glyph runs move from their old layout position and size to the new ones (scale by font-size ratio) and interpolate color; unmatched ones fade out/in (old during the first 50 %, new during the last 50 %). PowerPoint Morph "Words"/"Characters", Keynote "Text: by character". |
| Images | Frame, crop rect (in image coordinates), mask shape (as shape geometry), filters (brightness, contrast, saturation, blur — numeric), corner radius. Different image files with the same key crossfade. |
| Charts (2D) | If both reference the same source (link or native data) the chart scenes morph: primitives matched by `SceneTag` (series key, point index, role) — rects, arcs and polylines interpolate geometry, labels crossfade, unmatched primitives fade ([08](08-charts-from-sheets.md) §9.4). Different sources: crossfade. |
| Charts (3D) | `Chart3DModel.lerp` (items by key, new ones grow from the floor) **and the camera**: azimuth (shortest arc), elevation, perspective interpolate — Magic Move between camera angles ([08](08-charts-from-sheets.md) §10.3). |
| Code | Token morph between the displayed states ([07](07-code-blocks.md) §5.6). |
| Tables | Frame interpolates; cell contents crossfade (P1: cells matched by row/column index, text morph per cell). |
| Element groups | Group frame interpolates; children matched recursively. |
| Builds-related state | Persistent emphasis of A (grown, spun, recolored, dimmed parts) is A's final frame, so the morph starts from what the audience sees. |

Draw order during the morph: B's z-order for matched and incoming elements; outgoing elements
are inserted at their A rank relative to their nearest matched neighbor. Backgrounds of A and
B crossfade when they differ. Layout/master elements that are identical stay still; otherwise
they crossfade.

### 8.5 Fallbacks

| Situation | Behavior |
|-----------|----------|
| No element matched | Plays as `fade` (crossfade) with the Magic Move duration. |
| Matched pair of different kinds (manual key) | Frame + opacity interpolate; contents crossfade. |
| Entering B from a slide other than its predecessor (picker jump) | Matching runs against the slide actually shown; few matches → mostly crossfade. |
| Text with > 2,000 characters on either side at `character` level | Uses `word` level. |
| Reduced motion | Crossfade, 300 ms (§13). |
| Device too slow (frame budget missed 10 frames in a row, §14) | Remaining duration plays as crossfade of snapshots. |

### 8.6 `transitionJson.magicMove`

```jsonc
"magicMove": {
  "textMatching": "object",       // object | word | character
  "matchByContent": true,         // pass 2
  "fadeUnmatched": "together",    // together | before (fade out unmatched first, then morph) | after
  "rotation": "shortest",         // shortest | literal
  "stagger": 0                    // ms between successive matched pairs (by reading order); 0 = all together
}
```

The Transition tab shows these as *Match text by* (Object / Word / Character), *Match identical
content* (switch), *Unmatched objects* (Fade with the move / Fade out first / Fade in after),
*Rotation* (Shortest / As set), *Stagger* (slider).

---

## 9. Timeline model (`wonky_slides_core`, pure Dart)

Location: `packages/wonky_slides_core/lib/src/motion/` (exported as `motion.dart`). No
Flutter; used by the app, the server (PDF/PNG export, MCP `slides.get_slide` build summaries,
AI validation) and tests.

### 9.1 Responsibilities

1. Validate builds and the transition against the catalog (§3.5).
2. Compile a slide's builds into **steps** and **tracks** (§4.2) — `SlideTimelineCompiler`.
3. Compile a **transition plan** between two slides, including Magic Move matching and
   interpolation descriptors — `TransitionCompiler` / `MagicMoveMatcher`.
4. **Evaluate**: the frame at any position (`frameAt(step, ms)`), the settled frame at the end
   of a step, the initial frame, the print frame — `SlideTimeline`.
5. Provide durations and summaries for UIs and MCP (`describe()`: "5 clicks, 12.4 s").

### 9.2 Types (sketch)

```dart
final class SlideTimeline {
  final String slideId;
  final List<TimelineStep> steps;          // steps[0] = automatic step (may be empty)
  final Map<String, ElementTrack> tracks;  // per element id
  final List<TimelineWarning> warnings;    // skipped builds, fallbacks
  SlideFrame get initial;                  // after the transition, before step 0 runs
  SlideFrame endOfStep(int step);          // settled frame after step `step`
  SlideFrame frameAt(TimelinePosition p);  // exact, deterministic
  SlideFrame get finalFrame;               // endOfStep(steps.length - 1)
  SlideFrame get printFrame;               // §9.6
  int get stepCount;                       // steps.length - 1 clicks after step 0
}

final class TimelinePosition { final int step; final int ms; } // ms ≥ step.durationMs = settled

final class TimelineStep {
  final int index;
  final int durationMs;
  final List<ScheduledEffect> effects;     // sorted by startMs
}

final class ScheduledEffect {
  final String buildId;
  final String elementId;
  final int part;                          // 0 = whole element
  final int startMs, durationMs;           // relative to the step start
  final Easing easing;
  final EffectProgram program;             // evaluates channel values for progress 0..1
  final bool persistent;
}

final class SlideFrame {
  final Map<String, ElementVisualState> elements;  // absent = edit state (unanimated)
  final BackgroundState background;
}

final class ElementVisualState {
  final bool visible;
  final double opacity;                    // 0..1
  final Affine3 transform;                 // 4×4 (column-major Float64List), su, includes perspective
  final ClipSpec? clip;                    // inset/polygon/circle with feather (wipe, iris)
  final double blurSigma;                  // su
  final double dissolve;                   // 0..1 with seed
  final ColorOverrides? colors;            // fill/stroke/text/highlight overrides (resolved ARGB)
  final PartStates? parts;                 // per part: opacity, transform, reveal (typewriter count), dim
  final double drawProgress;               // lineDraw 0..1 (1 = complete)
  final ChartRevealState? chart;           // per SceneTag reveal/growth, highlight, 3D camera (08)
  final CodeViewState? code;               // state index, typing position, highlight step mix (07)
}
```

`EffectProgram`s are pure functions `(progress, params, elementGeometry) → ChannelValues`.
Channels combine per element in a fixed order: base state (persistent results of earlier
steps) → motion translation/orientation → build transform → emphasis transform; opacities
multiply; clips intersect; blur takes the max; color overrides apply in schedule order (last
started wins).

### 9.3 Frames and persistence

- `initial` applies: hidden elements (first visibility build is an in-build), parts outside
  `parts.from/to` visible, and nothing else.
- `endOfStep(i)` = `initial` with every effect of steps 0…i settled; transient emphasis
  returns to the base; persistent effects (§3.3, motion) accumulate into the base state.
- `frameAt` evaluates the step's running effects on top of `endOfStep(i − 1)`.
- All evaluation is **deterministic**: integer milliseconds, closed-form easing, seeded PRNGs
  (`SplitMix64(hash(buildId, part))`) for random order, dissolve noise, typewriter jitter and
  type-in jitter. No wall clock, no platform randomness. Two runs (client, server, PDF) produce
  bit-identical `SlideFrame`s for the same inputs (tested with JSON snapshots).

### 9.4 Inputs the compiler needs

The compiler is given a `SlideMotionInput`: the slide's builds and transition, the resolved
elements (`ResolvedSlide` / `SlideScene` nodes keyed by element id, 02 §11: kind, frame,
rotation, style), and **part geometry** where delivery depends on layout:
paragraph/word/character boxes for text (from the text layout — Flutter `TextPainter` in the
app via `TextPartGeometryProvider`; the core `TextLayoutEngine` on the server, 02 §11 / 03), chart scene
tags (from `wonky_charts` layout, 08), code layout (monospace grid from `wonky_code`, 07). Part
geometry is supplied lazily per element and cached by `(elementId, contentHash, frame size)`.

### 9.5 Magic Move compilation

`TransitionCompiler.compile(from: SlideFrame A.final, to: SlideFrame B.initial, transition,
geometry)` → `TransitionPlan { pairs: [MorphPair], outgoing: [id], incoming: [id],
durationMs, easing }`, where `MorphPair` carries the per-property interpolation descriptors of
§8.4 (precomputed: resampled shape paths, aligned glyph runs, chart primitive pairs, camera
endpoints, code token pairs). Token/word/character alignment uses the shared Myers sequence
diff (`wonky_core` `SequenceDiff.diff<T>`, generalized from `LineDiff` — [07](07-code-blocks.md)
§5.2). Plans are cached per (A content hash, B content hash, transition JSON).

### 9.6 Edit frame, thumbnails and print frame

| Consumer | Frame shown |
|----------|-------------|
| Editor canvas (editing) | Edit frame: all elements visible, authored state, no builds. Code elements show the state selected in the inspector (07); charts fully drawn. |
| Navigator thumbnails, grid view, Drive thumbnail | Edit frame, except code elements show their **last** state and charts their final camera of the authored spec. |
| Presenter view "current"/"next" | `frameAt` / `endOfStep(current + 1)`. |
| PDF without builds ([10](10-presenting-and-pdf.md) §11) | **Print frame**: edit frame + content-progressive elements at their final content (code: last state, no highlight dimming; charts fully built; typewriter text complete); elements with out-builds are kept; motion paths and persistent emphasis are **not** applied (objects stay where the author placed them). |
| PDF with builds as pages | One page per step: `initial` if step 0 is empty and step 1 exists, then `endOfStep(i)` for every step (deduplicated when two steps produce identical frames). |
| PNG export ([10](10-presenting-and-pdf.md) §13, SL-33) | The print frame by default; *After the last build* = `finalFrame`; *Each build stage* = the PDF's build pages, one image each. |

**Decided (v2 review, Q24) — print frame.** Prints and thumbnails use the print frame above
(authored layout + completed content), with a P1 PDF option *Show final animation state* (uses
`finalFrame`). Keynote prints the authored slide too; PowerPoint prints all objects at their
starting positions, which hides out-built content.

### 9.7 Performance of the core

| Operation | Budget |
|-----------|--------|
| Compile a slide with 200 builds / 2,000 parts | ≤ 2 ms (desktop), ≤ 5 ms (web) |
| `frameAt` for 100 animating elements | ≤ 0.5 ms |
| Magic Move plan, 60 elements, character-level text of 1,000 chars | ≤ 15 ms; computed when the slide **before** it is shown (prefetch, §14) |

### 9.8 As built (SL-24)

`package:wonky_slides_core/motion.dart` (`lib/src/motion/{easing,effects,builds,timeline,util}/`;
the transition stub was replaced by SL-25, §9.9):

- **API.** `SlideTimelineCompiler.compile(SlideMotionInput)` → `SlideTimeline` (`steps`,
  `stepCount`, `initial`, `endOfStep(i)` (−1 = initial, clamped), `frameAt(TimelinePosition)`,
  `finalFrame`, `printFrame`, `tracks`, `stepsOfBuild(id)`, `durationMs`, `describe()`,
  `warnings`). Build the input with **`SlideMotionInput.fromDeck(deck, slideId, {resolved,
  scene, options, chartShapeOf})`**: resolved element frames/rotation/opacity, text (Delta →
  `MotionText` with paragraph levels), part boxes from the scene's text layout, chart shapes,
  code states, the effective transition (slide ▸ deck default ▸ none), slide size and theme color
  resolution. The plain constructor (`slide`, `builds`) still works but knows no geometry
  (transforms about the origin, no reference checks) — consumers must move to `fromDeck`.
  `SlideTimeline(slideId:, steps:)` builds program-less fakes (every frame = edit frame).
  `TimelineStep {index, durationMs, effects, hasLoops}`, `ScheduledEffect {buildId, elementId,
  part (0 = whole, k = 1-based natural part), startMs, durationMs, endMs, effectId, kind, role
  (build | dim), persistent, loops, easing}`.
- **Frames** (`slide_frame.dart`): `ElementVisualState` keeps the stub's fields and adds
  `drawReverse`, `fillOpacity`, `clip` (`ClipSpec` wipe/iris: kind, progress, direction, shape,
  origin, softness — descriptive, the renderer builds it in the unrotated box), `dissolve`
  (`DissolveState` amount, seed, cell), `colors` (`ColorOverride {from?, to, mix}` by property;
  the renderer blends from the authored color in OKLab), `highlights` (`TextHighlightState`),
  `parts` (`TextPartStates {parts: [TextPartState {start, end, visible, opacity, transform,
  clip, blurSigma, revealEnd, caret, dim, dimColor}], backgroundOpacity}`), `chart`
  (`ChartRevealState {backgroundOpacity, parts: [ChartPartState {ChartPartKey(role, series,
  index), grow, opacity}], highlight, highlightMix, azimuthDelta, elevationDelta, camera,
  fromCamera, cameraMix}`) and `code` (`CodeViewState {stateIndex, fromStateIndex (−1 =
  empty), mix, mode, highlightStep, fromHighlightStep, highlightMix, typing}`). **Element
  transforms are slide-space matrices pre-multiplied before the element's own transform** (as
  the stage and PDF painter apply them); part transforms are in the element's local space (its
  text node). Frames list only non-edit states; `toJson()` is canonical (sorted, 1e-6 rounding)
  for the determinism tests.
- **Evaluation**: persistent geometry is an effective frame per element (center, size,
  rotation) that motion paths, `moveTo`, `spin` and `grow` change (about their `origin`); the
  state matrix maps the authored box onto it; running channel effects compose on top
  (`T(dx,dy) · base · Π T(a)·P·Rx·Ry·Rz·S·T(−a)`). Part-based in-builds keep the element drawn
  with its unbuilt parts hidden; the box/background (text) or chart background
  (`includeBackground`) arrives with the first part and leaves with the last part of an out
  build. Typewriter is part-based too (one part = the whole text without delivery).
- **Build model**: `EffectCatalog` (every §3 effect as `EffectSpec` with `ParamSpec`s,
  `validate`, `forElement`, `fallback`), `BuildOptions` (codec of §2.2: errors for wrong types,
  clamping warnings, unknown keys kept), `TransitionSpec`/`TransitionCatalog`
  (`effective`, `patch`), `DeckMotionDefaults`, `MotionEasing` (`bind(durationMs)` →
  `BoundEasing`), `TextParts`, `ChartShape`, `PartOrdering`, and **`BuildEdits`** — the
  operations behind the §15 commands (`add`, `update` with options merge patches, `move`
  (index/before/after + trigger), `removeAll`, `copy`/`paste` animation, `setTransition`,
  `removeTransition`, `setAdvance`, `applyTransitionToAll`); one operation = one undo step.
- **Planner** (02 §12.1, additive): build columns are validated (catalog effect of the
  resulting kind, easing grammar, `optionsJson` via `BuildOptions` with clamping warnings and
  the normalized JSON written, delay 0–60,000 ms, duration 0–20,000 ms, `onElementClick`
  refused); `MoveBuilds.trigger` writes the first moved build's trigger ("New click");
  `SetSlideProps.transitionJson` and `SetDeckProps.defaultsJson.transition` are validated;
  `SetDeckProps.resetSlideTransitions` = *Apply to all slides* in one step; **new slides get
  `transitionJson` null** (they inherit the deck default; SL-7 copied the default into them).

Deviations and decisions:
- Seeded randomness is **Mulberry32 seeded by FNV-1a** (32-bit arithmetic, exact on the VM,
  dart2wasm and the JavaScript debug builds) instead of SplitMix64. Seeds: `hash(buildId:part)`;
  random order `hash(buildId:0:order)`.
- Springs: a spring-eased build's `durationMs` is the perceptual `d` (the `d` inside
  `spring(d,b)` applies when the duration is 0; `BuildEdits.update` keeps both in sync); bounce
  is clamped to ±0.95; the settle time uses the analytic envelopes (under/overdamped) or a
  bisection (critical) and is capped at 4 d (e.g. `spring(0.8,−0.5)` hits the cap).
- `codeHighlight.step` and `codeState.state` are 1-based (07 §4.5; `step: 0` clears, an omitted
  `state` = the next one). Derived code durations are estimates (28 characters/s for type-in,
  `durationMs` or 800 ms for morph) until SL-26's `TypingScript` replaces them.
- Delivery on emphasis: only `highlight` and the transient channel effects (pulse, bounce,
  shake, blink) use text parts; persistent geometric/color emphasis and motion apply to the
  whole element. Chart deliveries need a `ChartShape` (from the link snapshot/static data JSON
  or `chartShapeOf`); without one the chart builds as one part (`deliveryFallback`).
- Reduced motion: "instant" persistent emphasis jumps to its end state at the start of a 200 ms
  slot (the frame model has no crossfade; SL-29 may crossfade); `codeState` becomes a 300 ms
  `crossfade` mode; typewriter/type-in become 200 ms fades per paragraph (code: whole element).
- Not in the core (SL-29): the blur budget fallback (4 elements, σ ≤ 40), frame-budget
  degradation, `line` delivery with layout (compiles as `paragraph`).
- `onElementClick` builds are skipped with the warning `unsupportedTrigger`.

### 9.9 As built (SL-25): transitions and Magic Move

`package:wonky_slides_core/motion.dart` → `lib/src/motion/transitions/` and
`lib/src/motion/magic_move/` (the stub `stub/transition_stub.dart` is gone; the type names
`TransitionCompiler`/`TransitionPlan` stayed). Pure Dart, no UI — the player/renderer is SL-29,
the Transition tab SL-30 (the `animations` feature is on since SL-29 + SL-30).

- **Compiling.** `TransitionCompiler.compile(from: SlideFrame, to: SlideFrame, {transitionJson
  | spec, options: TransitionOptions, fromSlide, toSlide})` → `TransitionPlan`; `from` is always
  the slide being **left** (its `finalFrame`), `to` the slide **entered** (its `initial`).
  `TransitionCompiler.between(deck, fromSlideId:, toSlideId:, {fromFrame, toFrame, options,
  fromScene, toScene, textLayout})` does the rest from a deck (effective transition of the entered
  slide — or, with `options.reverse`, of the left slide —, slide size, dissolve seed = the entered
  slide id, theme colors for `fade.through`, `MagicMoveSlide.fromDeck` for both slides when the
  type is Magic Move). `TransitionCompiler.preview(spec)` = tile previews without slides.
  `TransitionOptions {slideWidth, slideHeight, reducedMotion, reverse, seedKey, resolveColor,
  cameraLerp}`.
- **Plans.** `TransitionPlan {requestedType, type (played), spec, durationMs, curve, reverse, is3d,
  isCut, from, to, magicMove, throughColor, seed, warnings, outgoing, incoming}` with
  `frameAt(ms)`, `at(t)` (linear 0..1, previews/scrubbing), `sample(n)`, `describe()`, canonical
  `toJson()`. Fallbacks (warnings): `unknownTransition` and `unavailableTransition` (P2:
  `pageCurl`, `objectZoom`) → `fade`; `reducedMotion` → `fade` 300 ms `easeInOut` (a cut stays a
  cut; `fade.through` is kept); Magic Move without slides (`magicMoveNoSlides`) or without any
  match (`magicMoveNoMatches`, §8.5) → `fade` with the Magic Move duration. Springs last their
  settle time (as builds).
- **Snapshot frames** (`TransitionFrame {progress, quads, backdrop, magicMove}`): each slide is
  drawn as one or more `TransitionQuad {layer (outgoing|incoming), transform (slide space, 3D
  types with the perspective entry `(3, 2) = −1 / (2.2 × width)` — the timeline's sign, +z toward
  the viewer — so renderers need the projective divide), opacity, clip (`ClipSpec` wipe/iris),
  dissolve (`DissolveState`), shade (0..1 toward black), region (a part of the slide: doorway
  halves), visible (back-face culled / transparent)}` in paint order; `backdrop` = the *fade
  through* color (null = letterbox/canvas). `frontFacing(m, rect)` and `faceShade` (12 %) are
  exported. Geometry per type: `direction` is where the slides **move** (`left`: the new slide comes
  from the right); push/slide/cover (old dims 20 %)/uncover translate by the slide size; wipe/iris
  clip the incoming slide with the build `ClipSpec` semantics; zoom `in` grows the new slide 0.25 →
  1 (fading in over the first 40 %), `out` shrinks the old 1 → 0.25 (fading over the last 40 %);
  flip = one card turning 180° (old face until halfway, then the new back face) pushed back by
  `sin(πp) × span / 2` so the near edge never grows; cube = faces at ±90° about the cube center
  (depth = half the width/height), pushed back by `0.25 w sin(πp)`; doorway = the old slide's halves
  turning ±75° about their outer edges toward the viewer (fading over the last 40 %) while the new
  one scales 0.6 → 1 out of 40 % shade; swap = the slides arc sideways (±0.55 w) and back (0.7 w)
  with ±25° yaw, trading the front at the middle; revolve = the old slide swinging 90° away about
  its leading edge (fading over the last 30 %) over the new one. Shade of turned faces =
  `12 % × (1 − cos θ)`.
- **Reverse** (`reverseOnBack`, §6): pass the *left* slide's transition with `reverse: true`;
  snapshot types play the forward frames backwards with the easing applied forwards and the layers
  swapped (push left looks like push right); Magic Move compiles from the left slide to the entered
  one, with `fadeUnmatched: before`/`after` swapped.
- **Magic Move input.** `MagicMoveSlide {slideId, width, height, elements, frame, chrome,
  chromeKey, backgroundKey}` via `MagicMoveSlide.fromDeck(deck, slideId, {frame, resolved, scene,
  textLayout})`: top-level elements visible in `frame` (in-built and `hidden` elements left out),
  each a `MagicMoveElement {id, kind, matchKey, name, frame, rotation, literalRotation, opacity, z,
  signature (pass 2), contentKey (equal = same drawing), geometryKey (shape type + adjust),
  fillColor, strokeColor, outline (shape body path), text (`MagicMoveText {plain, layout, origin,
  rangeBox?}`), code (`MagicMoveCode {code, language, stateIndex, layout, origin}` of the displayed
  state, laid out by `CodeElementLayout`'s composer), chart (`MagicMoveChart {source (link or data
  hash), dataHash, camera}`), image (`{src, crop}`), children, state}`; `geometry` is what the
  audience sees (the frame state's transform decomposed: persistent grow/spin/motion of A's final
  frame is where the morph starts). Without a scene the core `SlideTextLayout` builds one (≈ 6 ms
  for 60 elements; pass the stage's scenes when at hand).
- **Matching** (`MagicMoveMatcher.match(from, to, {options})` → `MagicMoveMatches {pairs,
  outgoing, incoming, allPairs, pairOf}`, `MagicMoveMatch {from, to, pass (key|content|name),
  children}`) is §8.3 as written: keys with duplicate keys paired by z rank; content signatures
  per kind (text: normalized plain text; shape: geometry + text; image: `src`; chart: link
  `spreadsheet/chart` or data hash; code: displayed code; icon: set + name) greedily by nearest
  center (ties: outgoing then incoming order); pass 3 (kind + non-empty name) is built; groups
  match their children recursively.
- **Plan** (`MagicMovePlan.compile(from, to, {spec, reverse, cameraLerp})`; `TransitionPlan
  .magicMove`): `pairs` (`MorphPair {match, mode, index (reading order), logSize, rotationDelta,
  fromAuthored, toAuthored, path, text, code, fromCamera, toCamera, chartMorph}`), `durationMs`
  (= morph + stagger × (pairs − 1)), `layers`, `outgoingIds`/`incomingIds`. Modes: `replace`
  (same `contentKey`: only B is drawn, stretched from its box onto the interpolated geometry;
  fill/stroke colors blend as `colors` overrides), `path` (shapes whose outline changed:
  `PathMorph` — 128 points by arc length in box-relative coordinates, orientation matched, start
  aligned by minimal squared distance; multi-subpath outlines and open/closed mixes crossfade),
  `glyphs` (text boxes with `word`/`character` matching, **and object-level text whose plain text is
  identical** — it moves glyph by glyph so size and color interpolate: `TextMorph` aligns words or
  graphemes with `SequenceDiff`; matched characters form **runs** — consecutive in both texts, on
  one line and one style run in both layouts, spaces between matched tokens joining —; > 2,000
  characters fall back to words), `crossfade` (different content; text boxes object-level over the
  middle 60 %, rigidly placed — text is never stretched), `group` (both group nodes drawn; children
  morph as pairs of their own; unmatched children ride with their group's interpolated box).
  Geometry: center linear, size linear or in log space when both boxes have the same aspect ratio
  (there is no `lockAspect` column), rotation shortest or literal (stored values), opacity linear.
  Code pairs get a `TokenMorphPlan` (SL-26, tokenized with `CachedCodeTokenizer.shared`); chart
  pairs interpolate the camera through the `ChartCameraLerp` seam (default `ChartCameraView.lerp`
  → `wonky_charts` `Chart3DView.lerp`, SL-27) and mark `chartMorph` when the source is the same
  but the data differs (`ChartSceneMorph`, 08 §9.4, is the renderer's); image pairs with the same
  file interpolate the crop. Timing (`fadeUnmatched`): `together` = everything over the whole
  duration; `before` = unmatched fade out over the first 35 %, the morph over the rest; `after` =
  the morph over the first 65 %, unmatched fade in after; each pair starts `stagger × index` later.
- **Frames** (`MagicMovePlan.frameAt(ms)` → `MagicMoveFrame {progress, outgoing, incoming,
  layers, pairs}`): two ordinary `SlideFrame`s — `outgoing` for A's scene (starts from A's final
  frame), `incoming` for B's (starts from B's initial frame; its `background.opacity` is the
  background crossfade) — so the stage draws both scenes with the usual `ElementVisualState`s, plus
  `layers` (paint order: A's background when the backgrounds differ, B's, layout/master decorations
  (A's hidden when both slides share them, else crossfading), then B's order with each outgoing
  element at its A rank next to its nearest matched neighbor and A's half of non-replacing pairs
  right below B's) and `pairs` (`MorphPairState {mode, progress, contentMix, geometry, path (in B's
  local space), camera, codeProgress (linear), crop}` for what frames can't express). Glyph runs are
  `TextPartState`s of A's element (element-local transforms moving each run from its old to its new
  box, scaled by the font-size ratio, with the new `TextPartState.color` blend); B hides its matched
  ranges and fades in its new ones over the second half, A fades its removed ones over the first
  half. `SlideFrame.toJson` writes a changed background under `@background`.
- **Measured** (VM, the §9.7 fixture: 60 elements per slide incl. a 1,000-character text matched by
  character, 40 shapes moving/recoloring/changing outline, 4 charts at new angles): plan ≈ 1.4 ms
  (budget 15 ms), `frameAt` ≈ 0.35 ms.

Deviations and decisions:
- Magic Move **only uses glyph runs for text boxes**; shapes with text morph as shapes (stretch)
  with their text crossfading when it differs.
- Same-type shapes don't interpolate their adjust parameters; different adjustments morph the
  outline (`path`). Gradients, shadows, corner radius and stroke width are not interpolated
  (stretch, or crossfade when the fill kind differs) — P1.
- `ElementVisualState.opacity` may exceed 1 in Magic Move frames (the product with the element's
  own opacity interpolates); renderers clamp the product.
- Group children carry states of their own (renderers apply nested element states, SL-29); a
  persistent transform on an outgoing *group* is not composed into its children's geometry.
- Not in the core (SL-29): plan caching per (A hash, B hash, transition JSON) and prefetch,
  snapshotting, the frame-budget degradation to crossfades, live text relayout during morphs.

---

## 10. Interaction with other features

- **Code blocks** ([07](07-code-blocks.md)): `codeHighlight` and `codeState` builds; *Build all
  steps* creates one build per highlight step and state transition in order.
- **Charts** ([08](08-charts-from-sheets.md)): `chartGrow`/`chartShrink` with chart delivery,
  `chartHighlight`, 3D `chartOrbit`/`chartCamera`, chart morphs in Magic Move.
- **Comments and history**: builds and transitions are content; version history restores them;
  comments can anchor to an element, not to a build.
- **Placeholders**: replacing a placeholder's content keeps its builds (the element id stays).
- **Element deletion**: deletes its builds (cascade in the same undo step; undo restores both).
- **Slide duplication**: duplicates builds (new ids, same order, element ids remapped) and the
  transition.
- **Skipped slides**: Magic Move compares with the slide actually shown; a skipped slide never
  takes part.

---

## 11. Collaboration and concurrency

- `SlideBuild` rows merge field by field (LWW). Two users editing different fields of the same build
  both survive; `optionsJson` is one column (whole-JSON LWW). The pane applies edits as
  read-modify-write patches on the latest local value (like Sheets chart specs, Sheets 08 §15.2).
- Concurrent reorders: both writers compute fractional `sortKey`s; ties break on `id`, so the
  order converges. A user who reorders sees their own result immediately; a conflicting remote
  reorder animates the row to its new position in the Order tab.
- The Animate tab shows presence: when another user has it open on the same slide, their
  avatar appears in the tab header; while a remote user drags a timing bar, the bar is outlined
  in their presence color (P1).
- A remote change to the slide's builds during a running preview stops the preview ("The
  animations changed — Preview again").

---

## 12. Rendering (Flutter)

### 12.1 Stage

`SlideStage` (`wonky_slides/lib/features/stage/`, shared by canvas, presenting, thumbnails,
previews, PNG export) renders one slide at a target size with a `SlideFrame`:
- One `RenderSlideStage` (custom `RenderBox`) scales su → logical pixels and paints the
  background, then each element through `RenderSlideElement` children in z-order.
- `RenderSlideElement` applies its `ElementVisualState`:
  - transform via `pushTransform` with the element's `Matrix4` (perspective entry for flip/3D),
    composed with the stage scale;
  - opacity via `pushOpacity` only when < 1 (no `saveLayer` for opaque elements);
  - clip via `pushClipPath`/`pushClipRect`; feathered wipes/irises via `pushShaderMask` with
    a gradient shader (soft edge);
  - blur via an `ImageFilterLayer` (`ImageFilter.blur`, sigma scaled to device pixels; capped,
    §14);
  - dissolve via a fragment shader (`shaders/dissolve.frag`, `FragmentProgram.fromAsset`,
    seeded noise) — fallback to opacity when shaders are unavailable;
  - parts: text elements keep one laid-out paragraph and paint **part runs** (glyph ranges)
    with their own opacity/transform/clip; typewriter reveal clips to the union of revealed
    glyph boxes (no relayout per frame); dimmed parts repaint with the dim opacity/color;
  - `drawProgress` uses `PathMetrics.extractPath` for stroke draw-on;
  - charts and code delegate to their painters with `ChartRevealState` / `CodeViewState`.
- Every animating element gets its own compositing layer (`isRepaintBoundary` while it has a
  running effect), so static elements are not repainted per frame.

**As built (SL-10, edit frame).** `SlideStage` (`wonky_slides/lib/features/stage/`) is a
`Stack` of one `RepaintBoundary` + `CustomPaint` for the background and one per top-level scene
node (elements and master/layout decorations, keyed by element id), so the stage widget needs
no custom render objects yet; `SlideScenePainter` applies each element's `ElementVisualState`
(visibility, opacity via `saveLayer` only below 1, the state transform pre-multiplied in slide
space, blur) and draws paths, images (`SlideImageCache`), text (the Flutter engine's
paragraphs), charts (`paintChartScene`) and code. Thumbnails, snapshots and PNG export record
the same painter into a `ui.Picture` (`recordScene`). SL-29 added every remaining frame field
(§12.4).

### 12.2 Transitions

`TransitionStage` composites the outgoing and incoming slides:
- **Snapshot transitions** (all types except Magic Move): both slides are rasterized once at
  device resolution (`RenderRepaintBoundary.toImageSync`) when the transition starts and the
  images are transformed/clipped/blended per frame — constant cost regardless of slide
  complexity (Keynote does the same). Snapshots of the next slide are prepared ahead (§14).
- **3D types** use `Matrix4` perspective transforms of the snapshot quads (cube: two faces
  rotating about the shared edge at depth `width / 2`; flip: one quad rotating 180° with the
  back face showing the new slide; doorway: two half-quads rotating outward ±75° while the new
  slide scales 0.6 → 1; swap: quads following a perspective arc; revolve: rotation about the
  leading edge).
- **Magic Move** renders live (not snapshots): unmatched elements and matched pairs are drawn
  by `RenderSlideElement` with interpolated states from the `TransitionPlan`; text glyph
  morphs paint glyph runs from both layouts with per-run transforms.
- Elements that render through the GPU (3D charts via `flutter_scene`, [08](08-charts-from-sheets.md)
  §10) are included in snapshots through their canvas output (the GPU backend paints into the
  canvas), so 3D transitions of slides with 3D charts need no special path.

### 12.3 When to use `flutter_scene`

**As built (SL-29): the five 3D transition types render with `flutter_scene` where Flutter GPU
runs (the web build), with this section's 2D projective path as the fallback (§12.4).** The
original decision:

**Decision**: v1 transitions and builds use Flutter's 2D compositor with `Matrix4` perspective
(true 3D projection of flat quads is all that cube, flip, doorway, swap and revolve need). The
`flutter_scene` GPU backend is used **only** for 3D charts (shared backend from
`wonky_charts_flutter`, lazily started). Reasons: no shader-bundle download for decks without
3D charts, no WebGL2 requirement for transitions, deterministic rendering for exports, simpler
tests. P2 transitions that need real geometry or lighting (page curl, shatter, cube with
reflections) may use `flutter_scene` behind the same lazy starter, with a 2D fallback (`fade`)
when the GPU backend is unavailable.

---

### 12.4 As built (SL-29): player, stage frames, transitions

`wonky_slides/lib/features/{motion,transitions}/` (the player is not under `motion/player/`
only: the shared widgets sit next to it).

- **Player** (`motion/player/slide_player.dart`). `SlidePlayer({timelineOf, planOf})` is pure
  state over a caller clock: `show(slide, step)` (settled), `playStep(i)`, `enter(slide, {from,
  fromStep, fromFrame, toStep, reverse, playStep0, elapsed})` (transition, then step 0 — or the
  settled `toStep` when going back or jumping to a step), `finish()`, `degrade(now)`,
  `isRunning(now)` (a looping emphasis past its first cycle doesn't count), `needsTicks(now)`,
  `viewAt(now)` → `PlayerView`: `SlidePlayerView(slideId, step, frame)`,
  `TransitionPlayerView(plan, ms, frame, fromSlideId, fromFrame, toFrame)` or
  `CrossfadePlayerView` (degraded). `TransitionRequest {fromSlideId, fromStep, fromFrame,
  toSlideId, toStep (−1 = initial), toFrame, reverse}` is what callers compile with
  `TransitionCompiler.between` and cache (`key`). Every view is a function of the time, so tests
  seek exact frames. `seek(step, ms)` of §6 is `playStep(step, elapsed: ms)` / `show`.
- **Widgets.** `MotionStage({view, renderer, scale?, letterbox?, reducedMotion})` draws any
  `PlayerView` fitted and centered (present mode, the presenter view, the Animate tab's previews);
  `SlidePlayback` + `SlidePlaybackStage` (a player on a clock with its own `Ticker`) drive
  previews; `MotionTicker` ticks only while something runs; `PlayerStage` is the drawing core.
- **Frame content** (`motion/render/`). `MotionScenes.apply(scene, frame)` recomposes what
  painting can't express: code elements through SL-31's `CodeFrames.applyFrame` (states, steps,
  type-in, morphs) and charts through `SlideChartLayout.build(reveal:, view:, fitViews:)` with
  `SlideChartMotion.reveal/view/fitViews/baseView` when the renderer's chart source is a
  `SlideChartLayout` (SL-32). The stage painter (`stage/scene_painter.dart`) applies the rest:
  nodes inherit their element's state (`paintNode(owner:)`), the element group applies
  transform (perspective included), opacity (product clamped), blur (σ ≤ 40 su) and the
  **mask** (`MotionMask`: hard wipe/iris clips; feathered wipes as a layer × gradient
  `dstIn`; dissolve as a seeded noise image — one gray pixel per cell, drawn once per seed
  and grid with `toImageSync` — scaled over the box with a steep alpha color matrix:
  deterministic, no shader asset); `MotionNodePaint` does fill/stroke color changes (OKLab),
  `drawProgress`/`drawReverse` (`PathMetrics.extractPath`; outline-less shapes draw with their
  fill color; glyph elements wipe), `fillOpacity` and the text box's `backgroundOpacity`;
  `MotionTextPainter` draws **part runs** on the laid-out paragraphs (no relayout): characters
  outside animated parts in one pass clipped to their glyph boxes, each non-resting part on its
  own as glyph runs (one-line paragraphs per style run at the laid-out positions, cached per
  range; element-local transform, opacity × dim, clip, blur, `dimColor`/Magic Move color tint),
  typewriter reveals with a caret, highlight sweeps (marker/box behind, underline above), text
  color changes. Glyph boxes come from `TextRangeGeometry` (Flutter `getBoxesForRange` through
  `PlacedParagraph.start/length/marker`, added to `FlutterTextLayoutEngine`; cached per layout).
  `FrameDiff` compares states structurally, so a stage node repaints only when its elements'
  states changed (frames create new state objects every tick).
- **Transitions** (`transitions/`). Snapshot types: `SlideSnapshots` rasterizes both slides in
  their frames at device resolution (`recordScene` → `toImageSync`, LRU of 6, ≤ 4096 px,
  `SlideSnapshots.of(renderer)` shared) and `TransitionPainter` draws `frame.quads` back to front
  (canvas transform incl. the perspective entry — Skia does the projective divide —, region,
  wipe/iris/dissolve masks, shade as a `srcATop` black filter, opacity, `backdrop`); content may
  leave the slide rect (the letterbox shows behind). Magic Move renders live
  (`MagicMovePainter`): both scenes in `layers` order with their frames (decorations without an
  id follow their background), refined by `MagicMoveScenes.refine` (morphed outline replaces
  the incoming body path, interpolated image crop), `MagicMoveCharts` (same-source charts with
  different data morph with `ChartSceneMorph` at full opacity) and `MagicMoveCodeMorphs` (two
  code elements matched across slides draw the pair's `TokenMorphPlan` glyphs inside the
  incoming box; the outgoing one hides).
- **3D on the GPU** (decision revisited, §12.3). `transitions/gpu/gpu_transitions.dart`:
  `GpuTransitions` renders flip, cube, doorway, swap and revolve with `flutter_scene` (Flutter
  GPU; WebGL2 on the web) — the snapshots as unlit display-referred textured quads (shade via
  the base color factor, depth buffer, MSAA) seen by a camera at 2.2 × the width in front of
  the slide center, the same projection as the core frames (`body = view⁻¹ · quad.transform`,
  z mirrored). It starts lazily when a 3D transition is prefetched, uploads both snapshots as
  textures ahead (`Texture2D.fromImage`), and is enabled on the web only
  (`GpuTransitions.enabled`); without Impeller/WebGL2, before the textures are uploaded, or on
  any error the 2D projective painter draws the frame (identical geometry).
- **Presenting.** See [10](10-presenting-and-pdf.md) §8.1.
- **Budgets** (`motion/player/motion_budget.dart`). `MotionBudget.limitBlur` keeps blur on the
  first 4 elements/text parts (element id order) and caps σ at 40 su; the rest play as their
  fade. `FrameBudget` counts animation frames whose interval exceeds 24 ms (pauses > 250 ms
  don't count); 10 in a row → `SlidePlayer.degrade`: the rest of the running step or transition
  (≤ 1.5 s) is a crossfade of snapshots, the presenter view shows *Reduced effects*, and
  `slides.motion.degraded` is logged (no telemetry pipeline yet).
- **Reduced motion** is the compiler's (§13): timelines with `CompileOptions.reducedMotion`,
  transitions with `TransitionOptions.reducedMotion` (300 ms fades, Magic Move → crossfade); the
  deck's *Reduce motion while presenting* applies too. The persistent-emphasis "instant + 200 ms
  crossfade" stays the core's jump (the frame model has no crossfade).
- **Measured** (06 §14 budgets): Chrome (the Claude browser pane), release `--wasm`, 2048×1536 device px on a 120 Hz display, `benchmark/motion_bench.dart` (50 animating elements with every build effect, a 2,000-character by-character build, a typewriter, all 14 snapshot/3D transitions, a 61-pair Magic Move), warm second pass: engine build p95 1.5 ms and raster p95 2.0 ms over 3,961 frames (per segment: 50 elements raster p95 3.9 ms; 3D transitions on the GPU build p95 ≤ 3.6 ms, raster ≤ 1 ms); vsync interval p50 8.3 ms, p95 ≤ 10.3 ms in most segments (single missed 120 Hz vsyncs in flip/swap). Offscreen paint + raster + GPU round trip at 1920×1080: 2,000-character build p50 3.3 / p95 8.5 ms (15.4 ms before animating parts drew their own glyph runs), 50 elements p50 6.9 / p95 14.4 ms, transitions p95 ≤ 2.4 ms. Cold first pass: one-off spikes (font loading, the GPU renderer's first frame ≈ 0.5 s, the first dissolve noise) — now warmed/prefetched (GPU warm-up frame, noise as one vertex list, prefetch). The benchmark runs by hand (`flutter build web --wasm --target benchmark/motion_bench.dart …`; `?gpu=0` the 2D path, `?offscreen=1` without a visible page, `?freeze=<slide>&at=<ms>` one frame for visual checks); the GPU and 2D frames of the 3D types were compared visually (identical geometry).

Deviations: dissolve uses a noise image instead of a `FragmentProgram` shader (no shader asset,
identical on every backend; cells fade over 1/24 of the amount); after-build `dimColor` recolors
at full opacity once settled (the core sets `dimColor` only on settled parts, so it pops at the
end of the 300 ms dim); `RenderSlideElement` was not needed — per-element `RepaintBoundary`s
with structural frame diffs give the same per-element compositing.

## 13. Reduced motion

Active when any of these is on: the OS/browser setting (`MediaQuery.disableAnimations`), Wonky
Work settings › Appearance › *Reduce motion* (suite 02 §1), or the present-mode option *Reduce
motion while presenting* ([10](10-presenting-and-pdf.md) §3).

| Animation | Replacement |
|-----------|-------------|
| Build in/out with movement, scale, rotation, blur, flip, drop, zoom, wipe, iris, dissolve, line draw | `fade` / `fadeOut` with `min(duration, 300 ms)` |
| Typewriter, type-in, eraseText | Whole parts appear with a 200 ms fade (text per paragraph, code per state) |
| Delivery by word/character | By paragraph |
| Transient emphasis (pulse, bounce, shake, blink, orbit) | Skipped |
| Persistent emphasis (spin, grow, color, opacity, highlight, camera, code steps) | Final state appears with a 200 ms crossfade |
| Motion path, transform | Element fades out at the start and in at the end position (200 ms each) |
| Transitions (all) | `fade`, 300 ms |
| Magic Move | Crossfade, 300 ms |

The timeline compiler applies the replacements (`CompileOptions.reducedMotion`), so presenting,
previews and the presenter view stay consistent. The Animate tab shows a banner "Reduce
motion is on — animations play as fades" with a link to the setting; previews in the tab can
be played at full motion with *Preview full motion* (author's choice, not the audience's).

---

## 14. Performance budgets

Reference machines: suite 11 (desktop: mid-range laptop; web: Chrome on the same machine,
CanvasKit/Skwasm WASM build).

| Item | Budget |
|------|--------|
| Frame rate while presenting at 1920 × 1080 (device px) | **60 fps** (frame build + raster ≤ 12 ms desktop, ≤ 14 ms web) for: any transition, ≤ 50 simultaneously animating elements, ≤ 2,000 animating text parts |
| 4K (3840 × 2160) | ≥ 50 fps desktop; web best effort ≥ 45 fps |
| Blur | Max 4 simultaneously blurred elements and sigma ≤ 40 su; beyond that blur effects fall back to fade (warning in the pane) |
| Snapshot transitions | Snapshot of the next slide prepared within 200 ms after the current slide settles (idle-time `toImageSync`, released after use); transition start latency ≤ 1 frame |
| Prefetch | While slide *n* is shown: compile timelines of *n ± 1*, Magic Move plan for *n → n + 1*, decode images of *n + 1 … n + 3*, start the 3D chart GPU backend if *n + 1* has a 3D chart |
| Advance latency | Key press → first changed frame ≤ 1 frame (16 ms) |
| Shader warm-up | Dissolve and mask shaders are compiled at app start of present mode (`FragmentProgram` preload) |
| Degradation | If 10 consecutive frames miss the budget during a transition or build, the remaining animation of that step plays as crossfades of snapshots and the presenter view shows a small "Reduced effects" indicator; telemetry event `slides.motion.degraded` (suite 11 §5) |

Perf tests (`-t slow`): `motion_benchmark_test.dart` presents a fixture deck (every effect,
every transition, 50-element slides, 2,000-char typewriter, Magic Move with 60 pairs) with
`FrameTiming` collection and asserts p95 frame time; a web variant runs in the E2E job.

---

## 15. Commands

All ids are stable. `requiredRole` editor unless noted. Undoable commands create one step in the
`slides.rows` undo domain (02, suite 08 §3.3) and record `selectionBefore/After` (selected
elements and, for build commands, the selected build).

| Command id | Args | Undoable | Label / notes |
|------------|------|----------|---------------|
| `slides.panel.animate` | `{tab?: transition\|build\|order}` | — | Alias: opens the inspector's Animate tab at the sub-tab (04 §12). Viewer+ (read-only for viewers). |
| `slides.animate.addBuild` | `{elementIds?, kind, effect, params?, delivery?, trigger?, delayMs?, durationMs?, easing?, at?: {afterBuildId\|beforeBuildId\|index}}` | ✓ | "Add animation". Returns `buildIds`. |
| `slides.animate.updateBuild` | `{buildIds, patch: {effect?, trigger?, delayMs?, durationMs?, easing?, options?: JsonMergePatch}, coalesceKey?}` | ✓ | "Edit animation"; edits with the same `coalesceKey` within 1 s coalesce. |
| `slides.animate.deleteBuilds` | `{buildIds?}` (default: selected) | ✓ | "Remove animation". |
| `slides.animate.removeAll` | `{slideIds?}` | ✓ | "Remove all animations". |
| `slides.animate.moveBuilds` | `{buildIds, to: {index\|beforeBuildId\|afterBuildId}, trigger?}` | ✓ | "Reorder animations". `Mod+Alt+↑/↓` in the Order list (scope `slidesAnimatePane`). |
| `slides.animate.setTrigger` | `{buildIds, trigger}` | ✓ | |
| `slides.animate.copyBuilds` | `{elementId?}` | — | Animation painter source. |
| `slides.animate.pasteBuilds` | `{elementIds?}` | ✓ | "Paste animation". |
| `slides.animate.setMotionPath` | `{buildId, path, orientToPath?}` | ✓ | From path edit mode / draw tool. |
| `slides.animate.drawMotionPath` | `{elementId?}` | — (the result is `setMotionPath`/`addBuild`) | Enters the draw tool. |
| `slides.animate.editMotionPath` | `{buildId}` | — | Enters vertex edit mode. |
| `slides.animate.setTransformTarget` | `{buildId, to}` | ✓ | `moveTo` end state. |
| `slides.animate.preview` | `{slideId?, fromBuildId?, includeTransition?}` | — | `Mod+Alt+Shift+P` (⌥⇧⌘P; `Mod+Alt+Enter` belongs to *Presenter view*, 10 §1.2). Viewer+. |
| `slides.animate.stopPreview` | — | — | Esc during preview. |
| `slides.animate.toggleOrderOverlay` | — | — | View › Show build order. Viewer+. |
| `slides.animate.buildAllSteps` | `{elementId}` | ✓ | Code/chart convenience: one build per step/part (07, 08). |
| `slides.transition.set` | `{slideIds?, transition: TransitionJson}` (merge patch over the current) | ✓ | "Set transition". |
| `slides.transition.remove` | `{slideIds?}` | ✓ | Sets `none`. |
| `slides.transition.applyToAll` | `{transition?}` (default: the current slide's) | ✓ | "Apply transition to all slides": writes `Deck.defaultsJson.transition` and resets every slide's own `transitionJson` to null. |
| `slides.transition.setAdvance` | `{slideIds?, advance}` | ✓ | |
| `slides.transition.preview` | `{slideId?}` | — | Viewer+. |
| `slides.slide.duplicateForMagicMove` | `{slideId?}` | ✓ | Insert › Magic Move slide; `Mod+Alt+Shift+D`. |
| `slides.element.setMatchKey` | `{elementId, matchKey}` | ✓ | "Set Magic Move ID". |
| `slides.magicMove.toggleMatches` | — | — | View › Show Magic Move matches. Viewer+. |

Menus ([04](04-screens-menus-toolbar.md)): *Arrange › Animate…* (opens the Animate tab), *Slide ›
Transition…*, *Slide › Remove all animations*, *Insert › Magic Move slide*, *View › Show build
order*, *View › Show Magic Move matches*, element context menu *Animate ▸ (Add build in ▸, Add
action ▸, Add build out ▸, Copy animation, Paste animation, Remove animations)*; toolbar button
*Animate* (`sparkles`, opens the Animate tab at Build).

---

## 16. Undo

| Operation | Rows written | Undo label |
|-----------|--------------|------------|
| Add build(s) | insert `SlideBuild` rows | "Add animation" |
| Edit build field(s) | `SlideBuild` columns (coalesced per field drag) | "Edit animation" |
| Reorder | `sortKey` (+ `trigger`) of moved builds | "Reorder animations" |
| Remove | delete `SlideBuild` rows | "Remove animation" |
| Set/remove transition, apply to all | `Slide.transitionJson` of each slide | "Set transition" |
| Motion path / transform target | `SlideBuild.optionsJson` | "Edit motion path" |
| Magic Move slide | insert slide + elements + builds, set transition | "Add Magic Move slide" |
| Set match key | `SlideElement.matchKey` | "Set Magic Move ID" |

Previews, overlays and panel state are not undoable. Undo of a build edit that a collaborator
changed afterwards follows the suite per-column skip rule (toast "Some changes couldn't be undone
because they were edited by someone else").

---

## 17. Accessibility

- Animations never carry information alone: everything that builds in is in the slide's
  accessible content from the start of the slide in the editor; in present mode, screen readers
  get a polite live-region announcement of newly built text ("Pricing: 3 tiers…") and of code
  state changes ("Code updated: 4 lines changed").
- The Animate tab is fully keyboard operable: tabs, effect grid (`ShadRovingFocus`, arrows,
  Enter applies), Order list (arrows, `Mod+Alt+↑/↓` reorder, Del removes, F2 renames the element).
- Each effect tile has an accessible name and description ("Rise: the object moves up a short
  distance while fading in").
- Flashing: `blink` is limited to ≤ 3 flashes per second (WCAG 2.3.1); `count × 2 / duration` is
  clamped.

---

## 18. Acceptance criteria

1. Selecting a bulleted text box and choosing *Rise* with delivery *By bullet* creates one build;
   presenting needs one click per bullet; with *After build: Dim* earlier bullets dim to 35 %
   as the next one rises. One undo removes the build.
2. A slide with step 0 builds plays them automatically after its transition; `withPrevious`
   and `afterPrevious` builds start exactly at the computed offsets (frame-time test ± 1 frame).
3. Every effect in §3.1–§3.4 (P0/P1) renders in the editor preview, in present mode and — at
   step ends — in PDF builds-as-pages, and the PDF page equals `endOfStep(i)` (scene snapshot
   test).
4. Clicking during a running step finishes it instantly; a second click starts the next step.
   Going back shows the previous step's end state without animation.
5. Duplicating a slide, moving and resizing a shape, recoloring it and editing a title, then
   setting Magic Move morphs position, size, rotation, color and (with *Character* matching) the
   title's shared characters; unmatched elements fade. With no matches it plays a crossfade.
6. Magic Move between two slides with the same linked 3D chart at different camera angles
   rotates the chart camera smoothly (no pop), and between two states of the same code element
   morphs tokens.
7. Cube, flip, doorway, swap and revolve render with correct perspective (no z-fighting, back
   faces culled) in the editor preview and present mode on web (CanvasKit and Skwasm) and macOS.
8. With *Reduce motion* on, all transitions are 300 ms fades, typewriter text appears per
   paragraph, transient emphasis is skipped — in previews and presenting.
9. The 50-element fixture slide and every transition keep p95 frame time ≤ 16 ms at 1080p on
   the reference desktop and web machine (benchmark).
10. The same slide compiled on the client and on the server yields identical `SlideFrame` JSON
    for every step (determinism test incl. random order, dissolve seeds and typing jitter).
11. All commands in §15 are invocable via `ui.invoke_command` and pass the execute → undo →
    redo equality test; slider drags in the pane are one undo step.
12. Two users editing different builds of the same slide offline converge after sync with no
    lost builds; concurrent reorders converge to the same order on both clients.

## 19. Tests

- **Core unit** (`wonky_slides_core/test/motion/`): step compilation table tests (triggers,
  delays, parts, partTrigger, repeats); easing (Bézier, springs: settle time, closed-form vs
  numeric integration within 1e-6); every `EffectProgram` at progress 0/0.5/1 (golden JSON);
  persistence accumulation; delivery orders incl. seeded random; Magic Move matcher passes
  (keys, duplicates, content signatures, groups); path resampling and alignment; glyph run
  alignment; print frame rules.
- **Determinism**: compile + evaluate every fixture on VM and in a web (dart2wasm) test run and
  compare JSON hashes.
- **Widget/golden** (`wonky_slides/test/features/motion/`): stage rendering of each effect at
  progress 0.25/0.5/0.75 (contact sheets, light/dark canvas), transitions mid-way, Magic Move
  mid-way; Animate tab at 260 px and 420 px, light/dark; Order list drag reorder → command;
  effect tile hover preview.
- **Command tests**: execute → undo → redo for every command in §15.
- **Concurrency**: two simulated clients (multi-client sync harness) editing builds and reorders.
- **Performance**: §14 benchmark (`-t slow`).
- **E2E**: present a fixture deck through `flutter_driver` (next/previous/finish-during-build),
  PDF builds-as-pages page count equals step count.

---

## 20. Additions to 02-data-model

| # | Change | Reason |
|---|--------|--------|
| A-06-1 | `SlideBuild` as in 02 §3.7 (`slide`, `element`, `kind`, `effect`, `sortKey`, `trigger`, `delayMs`, `durationMs`, `easing`, `optionsJson`) — no field changes; this spec defines the values (§2–§4). | §2 |
| A-06-2 | Enums `BuildKind { buildIn, buildOut, emphasis, motion }` and `BuildTrigger { onClick, withPrevious, afterPrevious, onElementClick }` (enum values are append-only; `onElementClick` added in schema release S-2 and reserved for P2: skipped by the timeline, refused by the planner). | §2.1, §4.1 |
| A-06-3 | `SlideBuild.optionsJson` schema as §2.2 (`v`, `params`, `delivery`, `afterBuild`, `repeat`, `persist`). | §2.2 |
| A-06-4 | `Slide.transitionJson` schema as §7.1 (`v`, `type`, `durationMs`, `easing`, `params`, `reverseOnBack`, `advance {mode, afterMs, autoBuilds, buildDelayMs}`, `magicMove {textMatching, matchByContent, fadeUnmatched, rotation, stagger}`). | §7, §8.6 |
| A-06-5 | `SlideElement.matchKey` as already in 02 §3.5 (generated on create; copied on slide duplicate and cross-slide copy/paste; regenerated on same-slide duplicate). Also: `slides.slide.duplicateForMagicMove` copies keys. | §8.2 |
| A-06-6 | `SlideElement.name` (02 §3.5) is the Order-list label, Magic Move pass 3 key and the suggested Magic Move ID. | §5.4, §8.3 |
| A-06-7 | `Deck.defaultsJson` keys owned by 06: `"transition"` (a `transitionJson` object: the transition of every slide whose own `transitionJson` is null — new slides are created with null; absent = `none`) and `"build"` (`{kind, effect, trigger, durationMs, easing}` last used for quick add). | §5.2, §7.1 |
| A-06-8 | Cascade rules: deleting an `SlideElement` deletes its `SlideBuild` rows; deleting a `Slide` deletes its builds. Maintenance: builds referencing a missing element are deleted by the next editor (no undo step). | §2.1 |
| A-06-9 | `WonkyColors` tokens `buildIn`, `buildEmphasis`, `buildOut`, `buildMotion` (light/dark) — suite 02 addition. | §5.4 |
