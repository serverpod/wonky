# Slides 02 · Data Model (Offline-First Sync)

**Authoritative.** This spec defines how a Wonky Slides presentation ("deck") is stored, synced,
loaded into memory, mutated and undone. Feature specs (03–11) add fields and tables only through
§14 *Additions defined in feature specs*. A table change is an ordinary server migration plus a
new `slidesSchema` hash; the server accepts the hashes of compatible older clients
([17](../17-revlog-sync.md) part 2 §4.3).

Read first: [17 · RevLog sync](../17-revlog-sync.md) (As built, parts 1, 3 and 6) and
Sheets [02-data-model.md](../wonky_sheets/02-data-model.md) — Slides deliberately mirrors the
Sheets design (decision D6): **one deck = one RevLog file**, field-level last-writer-wins in
server order, deterministic ids where two devices may create "the same" row, fractional
`sortKey`s, one op per change in the file's op log, a mutation planner shared by client and
server, and an undo domain built on the same per-column skip rule.

---

## 1. Modeling principles

| # | Principle | Why |
|---|-----------|-----|
| P1 | **One deck = one RevLog file**; `Deck.id` = file UUID = the deck's drive item UUID. | The file is the unit of sharing and of the op log; the deck URL (`/slides/p/<uuid>`) works the moment a deck is created offline. |
| P2 | **Slides, groups, elements, table rows/columns, builds and code states are rows with stable UUIDs**, ordered by **fractional `sortKey`s** (`FractionalIndex`, ties by `id`). | Insert/move/delete are O(1) writes and merge cleanly with concurrent edits; nothing is renumbered. |
| P3 | **Properties users change independently are separate columns** (frame `x/y/width/height`, `rotation`, `fillJson`, `strokeJson`, `locked`, `hidden`, `text`, …). | Field-level LWW: Anna moving a shape while Bo recolors it keeps both changes. |
| P4 | **Coupled values are written together, always.** Columns that only make sense as a set (`groupId` + `sortKey` of a slide; `x` + `y` on move; `x/y/width/height` on resize) are written in the same op by every writer that changes any of them. | Two writers that both name the same columns produce one consistent winner: the server applies ops in revision order, so every column of the set takes the values of the op that arrived last, and coupled values never tear. |
| P5 | **Rich text is one column per text body** (`SlideElement.text`, `SlideTableCell.text`, `Slide.notes`) holding a Quill Delta (§4). Concurrent edits of the *same* body resolve LWW; a **soft lock** (§4.4) prevents most such conflicts. | Simple, offline-safe, small rows. Alternatives were weighed in the v2 review (§4.5). |
| P6 | **Inheritance by null.** A nullable style/geometry column that is `null` inherits (slide ▸ layout ▸ master ▸ theme). | Re-theming and layout edits propagate without rewriting slides. |
| P7 | **Every update names its columns** (`columnValues:`), enforced by the same repository lint test as Sheets (toptap pattern). | Otherwise an op assigns every column and clobbers concurrent edits of the other columns. |
| P8 | **Derived data is never synced**: resolved styles, auto-fit scale, connector routes, slide numbers, thumbnails, the animation timeline. | Sync volume proportional to user edits; every renderer (editor, presenter, PDF, server) derives the same result from the same rows. |
| P9 | **One op per undo transaction** in the file's server-sequenced op log (`rev_op`, [17](../17-revlog-sync.md) part 2 §1), with the summary of §3.10.1. | Server post-commit hooks (activity, versions, title, search text, comment orphaning, storage) and revert of server changes read the ops. |
| P10 | **No cross-file references by FK.** References outside the deck (drive items, uploaded files, spreadsheets, users) are plain `UuidValue`/`String` columns. | Every row belongs to one RevLog file; the sequencer cascades and checks parents only within the file ([17](../17-revlog-sync.md) RD-3). |

---

## 2. Identifiers, units and encodings

### 2.1 Ids (`wonky_sync_models/lib/src/ids/slides_ids.dart`, pure Dart)

Fresh ids are UUIDv7 from the injected `IdGenerator` (deterministic in tests, suite 15 §4).
Deterministic ids are UUIDv5 over fixed namespaces (constants, **never change**), exported as
`SlidesIds` next to `SheetsIds`:

| Helper | Name string | Used for | Why deterministic |
|--------|-------------|----------|-------------------|
| `SlidesIds.tableCellId(elementId, rowAxisId, colAxisId)` | `cell:<el>:<row>:<col>` | `SlideTableCell.id` | Two offline users typing into the same table cell write one row (per-column merge), like Sheets cells (S3). |
| `SlidesIds.placeholderInstanceId(slideId, layoutPlaceholderId)` | `ph:<slide>:<layoutEl>` | The slide's instance of a layout placeholder (`SlideElement`) | Applying the same layout to the same slide on two devices yields the same placeholder rows (no duplicate titles). |
| `SlidesIds.themeCopyId(deckId, sourceKey)` | `theme:<deck>:<sourceKey>` | `DeckTheme.id` when a built-in or library theme is copied into a deck (`sourceKey` = `builtin:<key>@<version>` or `deck:<itemUuid>:<themeId>`) | Two users applying the same theme offline end up with one theme copy. |
| `SlidesIds.themePartId(themeId, partKey)` | `part:<theme>:<partKey>` | `SlideMaster`, `SlideLayout` and master/layout `SlideElement` ids inside a copied theme (`partKey` = the source row's id or built-in key, e.g. `master:default`, `layout:titleBody`, `el:titleBody/title`) | Same as above: the whole copied tree merges. |
| `SlidesIds.chartLinkId(elementId)` | `chartLink:<el>` | `ChartLink.id` (max one per chart element) | One link row per chart even if two devices link it. |

All UUID strings are normalized to lower case before hashing. Inside JSON values, ids are written
in the 22-char base-62 form (`Base62Uuid`, as Sheets) to keep JSON small.

**As built (SL-2):** `SlidesIds` is exported by `package:wonky_sync_models/ids.dart` with the five
namespace constants (`tableCellNamespace`, `placeholderInstanceNamespace`, `themeCopyNamespace`,
`themePartNamespace`, `chartLinkNamespace` — part of the synced format, never change; the tests
pin one id per helper). UUIDs inside `sourceKey`/`partKey` are lower-cased too; other key text is
hashed as given (built-in keys are case-sensitive). Helpers: `builtinThemeSourceKey(key,
version)` (`builtin:<key>@<v>`), `deckThemeSourceKey(itemUuid, themeId)`, `newMatchKey(ids)`
(base-62 form of a fresh id, §3.5) and `tableCellUuid`. The UUIDv5 hasher is shared with
`SheetsIds` (`src/ids/uuid5.dart`).

### 2.2 Slide units and geometry

- **Slide units (su)**: one unit = one point at the deck's design size. A deck's size is
  `Deck.width × Deck.height` su; the default 16:9 deck is **1920 × 1080 su** (Keynote's
  convention). Every frame, font size, stroke width and inset is in su. The editor maps
  su → logical pixels by `zoom × (viewportFit)`; PDF pages are `width/2 × height/2` pt (16:9 →
  960 × 540 pt = 13.333 × 7.5 in, PowerPoint's widescreen page).
- **Frame**: `x, y` = top-left of the **unrotated** box, `width, height` > 0; `rotation` in
  degrees clockwise about the box center (normalized to `[0, 360)`); `flipH`/`flipV` mirror the
  content inside the box (applied before rotation).
- **Colors** (`ColorRef`, everywhere): `"#RRGGBB"`, `"#RRGGBBAA"`, `"theme:<key>"` (theme color,
  [05 §2.2](05-themes-layouts-masters.md): `bg1`, `text1`, `bg2`, `text2`, `accent1`…`accent6`,
  `link`), optionally with a modifier `"theme:accent1/lum:+0.2"` (lighten/darken in OKLCH,
  −1…+1) or `"theme:accent1/alpha:0.5"`; `"transparent"`; `null` = inherit.
- **Font refs**: `"@heading"`, `"@body"`, `"@mono"` (theme font roles) or a family name from the
  bundled registry ([05 §3](05-themes-layouts-masters.md)).
- **Lengths in JSON** are plain numbers in su unless a field says otherwise (percent fields are
  `0..1` fractions).

### 2.3 Fractional indexes

`FractionalIndex.between/before/after/nBetween` and `FractionalIndex.compare(keyA, idA, keyB,
idB)` from `wonky_sync_models` (Sheets 02 §2). Key spaces in Slides:

| Key | Space (siblings compared) |
|-----|---------------------------|
| `SlideGroup.sortKey` and `Slide.sortKey` of **ungrouped** slides | One shared **top-level** key space per deck (§3.4). |
| `Slide.sortKey` of a **grouped** slide | The key space of its group (`groupId`). |
| `SlideElement.zKey` | Siblings with the same owner (slide/layout/master) and the same `parent` (element group). |
| `SlideElement.readingKey` | Same siblings as `zKey` (reading order override). |
| `SlideTableAxis.sortKey` | Axes of one table and one dimension. |
| `SlideBuild.sortKey` | Builds of one slide. |
| `CodeState.sortKey` | States of one code element. |
| `SlideMaster.sortKey`, `SlideLayout.sortKey` | Masters of a theme / layouts of a master. |

---

## 3. Deck tables

The 12 deck tables are **server tables** of the deck's RevLog file
([17](../17-revlog-sync.md) part 2 §2): `wonky_server/lib/src/slides/models/rows/*.spy.yaml`,
`serverOnly: true` (the client gets no ORM classes; it holds column maps in its cache), each with
`file: RevFile?, relation(onDelete=Cascade)` (the `fileId` set by the sequencer), `revision: int`
(the revision that last wrote the row) and a `<table>_file_idx (fileId, id)` index. The 7 enums
of §3.11 are Serverpod enums next to them (`models/rows/enums/`, shared with the client). The
table schema of the sequencer and the client is `slidesSchema`
(`package:wonky_slides_core/revlog.dart`), generated from these models by `tool/gen_rev_schema.dart`:
deterministic-id tables `slide_table_cell`, `chart_link`, `slide_element` (placeholder
instances), `deck_theme`/`slide_master`/`slide_layout` (theme copies); `SlideElement`'s owners
`slide`/`layout`/`master`/`parent` are optional parents and the sequencer checks that exactly one
of `slideId`/`layoutId`/`masterId` is set; the plain references `Deck.themeId`, `Slide.groupId`,
`Slide.layoutId`, `SlideElement.placeholderOf`, `ChartLink.spreadsheetItemUuid/chartObjectId`
and `linkJson.slideId` are not cascaded (render-time rules and §10 repairs). There is no
change-log table: every change is an op of the file's log (§3.10). Field lists below omit `id`
and the RevLog bookkeeping (`file`, `revision`); every model has `createdAt: DateTime,
defaultModel=now` unless noted. Class names avoid Flutter clashes (`SlideElement`, not `Element`; `SlideBuild`, not `Build`).

**As built (SL-2).** The models below are the `.spy.yaml` files with
these differences: (1) every FK is `relation(onDelete=Cascade, deferred)` and therefore
non-nullable, except `SlideElement.slide/layout/master/parent`, which are
`relation(optional, …)` (exactly one owner is set; `parent` is an unnamed self-relation, no
`slide_element_children` list field); (2) every table has `createdAt`; (3) defaults where a
value is implied: `Deck.width 1920.0`, `height 1080.0`, `sizePreset widescreen16x9`,
`appearance light`, `showSlideNumbers false`, `hideNumberOnTitle true`, `firstSlideNumber 1`;
`skipped`, `hidden`, `hideMasterElements` (layout) `false`; (4) extra non-unique indexes on the
FK columns the cascades and loaders use (`deck_theme_deck_idx`, `slide_master_theme_idx`,
`slide_layout_master_idx`, `slide_table_axis_element_idx (elementId, sortKey)`,
`slide_build_element_idx`, `chart_link_element_idx`); (5) the additions of 03–10 known
at M9 are included: `Deck.guidesJson` (A-03-1), `Deck.presentJson` (A-10-1),
`Slide.timingsJson` (A-10-2), `ChartLink.sheetId` (A-08-2).

### 3.1 Deck

```yaml
### A presentation. id == RevLog file UUID == drive item UUID (P1).
class: Deck
table: deck
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7
  title: String                          # mirrored to DriveItem.name by the server (both ways)
  width: double                          # su; 1920 for 16:9
  height: double                         # su; 1080
  sizePreset: SlideSizePreset            # widescreen16x9, standard4x3, wide16x10, square, portrait9x16, a4, letter, custom
  themeId: UuidValue?                    # default DeckTheme for new slides (same deck; plain UUID, see §3.2)
  appearance: DeckAppearance             # light, dark — which color scheme of the themes is used (05 §2.4)
  language: String?                      # BCP-47 for spelling / hyphenation; null = user's locale
  showSlideNumbers: bool                 # master slide-number placeholders visible
  hideNumberOnTitle: bool                # no number on slides whose layout key is `title`
  firstSlideNumber: int                  # default 1
  footerText: String?                    # master footer placeholders' text; null = hidden
  defaultsJson: String?                  # {transition, buildDefaults, codeFontSize, …} — keys owned by 06/07 (§14)
  createdBy: UuidValue                   # user UUID
  createdAt: DateTime, defaultModel=now
```

`themeId` is a plain UUID (not an FK) so that deleting an unused theme never cascades into the
deck row. A missing `themeId` resolves to the theme with the smallest `id` (§10).

### 3.2 Themes, masters, layouts

```yaml
### A theme copied into the deck (05). A deck has ≥ 1 theme; slides pasted with
### "keep source formatting" bring their own.
class: DeckTheme
table: deck_theme
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7      # SlidesIds.themeCopyId for copies (§2.1)
  deck: Deck?, relation(onDelete=Cascade, deferred)
  name: String
  sourceKey: String?                         # provenance: builtin:<key>@<v> | deck:<itemUuid>:<themeId> | null (created here)
  colorsJson: String                         # {light:{bg1,text1,…,accent1-6,link}, dark:{…}} (05 §2.2)
  fontsJson: String                          # {heading, body, mono, sizes?} (05 §2.3)
  textStylesJson: String                     # {title, subtitle, heading, body, body2, caption, quote, attribution, bigNumber, label, code} (05 §2.5)
  backgroundJson: String                     # default background (05 §2.6)
  shapeStyleJson: String?                    # default fill/stroke/text of new shapes, lines, text boxes (05 §2.7)
  tableStyleJson: String?                    # default table style (05 §2.8)
  codeStyleJson: String?                     # code palettes light/dark + chrome (05 §2.9; behavior 07)
  chartStyleJson: String?                    # series palette order, fonts, gridlines (05 §2.10; behavior 08)
  sortKey: String                            # order in the Themes panel

class: SlideMaster
table: slide_master
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7      # SlidesIds.themePartId for copies
  theme: DeckTheme?, relation(onDelete=Cascade, deferred)
  name: String
  sortKey: String
  backgroundJson: String?                    # null = theme background

class: SlideLayout
table: slide_layout
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7      # SlidesIds.themePartId for copies
  master: SlideMaster?, relation(onDelete=Cascade, deferred)
  name: String                               # "Title and content"
  key: String?                               # built-in layout key (05 §4) — used to map layouts between themes
  sortKey: String
  backgroundJson: String?                    # null = master background
  hideMasterElements: bool                   # don't draw the master's non-placeholder elements
  hidden: bool                               # not offered in the layout picker
```

Master and layout content (placeholders, logos, decorations) are `SlideElement` rows owned by the
master or layout (§3.5).

### 3.3 Slides

```yaml
class: Slide
table: slide
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7
  deck: Deck?, relation(onDelete=Cascade, deferred)
  ### Position: always written together with groupId (P4, §3.4).
  sortKey: String
  groupId: UuidValue?                        # SlideGroup id (plain UUID, no FK — §3.4); null = top level
  layoutId: UuidValue?                       # SlideLayout id (plain UUID); null/missing = fallback (§10)
  backgroundJson: String?                    # null = layout ▸ master ▸ theme
  skipped: bool                              # not shown when presenting / exported unless included
  notes: String?                             # speaker notes, Delta (§4.3); null = empty
  transitionJson: String?                    # transition INTO this slide; schema in 06 (§14); null = deck default
  hideMasterElements: bool?                  # null = layout's setting
  createdAt: DateTime, defaultModel=now
indexes:
  slide_order_idx:
    fields: deckId, sortKey
```

### 3.4 Slide groups and ordering

```yaml
class: SlideGroup
table: slide_group
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7
  deck: Deck?, relation(onDelete=Cascade, deferred)
  title: String                              # "Intro"; 1–100 chars
  sortKey: String                            # top-level key space (shared with ungrouped slides)
  parentId: UuidValue?                       # reserved for nested groups (P2, decided in 04 §5.12); always null in v1
  color: String?                             # palette token: gray, red, orange, amber, green, teal, blue, violet, pink (04 §5.4)
  skipped: bool                              # skips all its slides when presenting/exporting
  createdAt: DateTime, defaultModel=now
indexes:
  slide_group_order_idx:
    fields: deckId, sortKey
```

**Order model (two levels).** The deck's *presentation order* is a tree flattened depth-first:

1. **Top-level items** = all `SlideGroup`s with `parentId == null` plus all `Slide`s whose
   `groupId` is null **or points at a group that doesn't exist** (orphans, §10). They are sorted
   by `(sortKey, id)` in one key space.
2. A group expands in place to its slides (`Slide.groupId == group.id`) sorted by
   `(sortKey, id)` in the group's own key space.

Rules:

- A slide's `groupId` and `sortKey` are **always written together** (P4): add to group, remove from
  group, move inside a group and move to the top level all write both columns.
- Moving a group writes only `SlideGroup.sortKey` (its slides keep their in-group keys) — one row
  per moved group regardless of its slide count.
- **Empty groups are allowed** (they render as a header with a drop zone, 04 §5) and are never
  deleted by maintenance.
- **Group skip** is effective skip: a slide is skipped when `slide.skipped || group.skipped`.
  Toggling a group's skip does not rewrite its slides.
- Nested groups (P2) use `parentId` with the same rule one level deeper; v1 writers never set it,
  v1 readers treat a non-null `parentId` whose parent exists as nesting and render it as a
  top-level group otherwise.

### 3.5 Elements

```yaml
### Any object on a slide, layout or master. Exactly one owner FK is set.
class: SlideElement
table: slide_element
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7
  slide: Slide?, relation(onDelete=Cascade, deferred)
  layout: SlideLayout?, relation(onDelete=Cascade, deferred)
  master: SlideMaster?, relation(onDelete=Cascade, deferred)
  ### Element group this element belongs to (kind = group). Cascade: deleting a group deletes its children.
  parent: SlideElement?, relation(name=slide_element_children, onDelete=Cascade, deferred)
  kind: SlideElementKind                     # text, shape, line, image, table, icon, code, chart, group
  name: String?                              # shown in the Layers panel / animation pane; null = generated ("Shape 3")
  ### Frame (§2.2). Nullable only on placeholder instances (null = inherit from placeholderOf).
  x: double?
  y: double?
  width: double?
  height: double?
  rotation: double?                          # null = 0 (placeholders: inherit)
  flipH: bool, default=false
  flipV: bool, default=false
  zKey: String                               # stacking order among siblings (§2.3)
  readingKey: String?                        # reading order override (03 §17); null = automatic
  locked: bool, default=false                # "Lock" — not selectable by click/marquee, can't move (03 §8.2)
  hidden: bool, default=false                # not drawn (still in Layers panel); hidden in present/PDF
  ### Placeholders (05 §5)
  placeholderType: PlaceholderType?          # on layouts/masters: defines a placeholder; on slides: instance
  placeholderOf: UuidValue?                  # instance → the layout (or master) placeholder element it inherits from
  ### Magic Move / Smart Animate (06 §8.2): elements with equal matchKey on consecutive slides morph.
  matchKey: String                           # 22-char key generated on create; kept on slide duplicate and cross-slide paste, regenerated on same-slide duplicate
  ### Content and style (P3: separate columns)
  text: String?                              # text/shape/placeholder: rich text Delta (§4); code: null (states are CodeState rows, 07 §3.2)
  textStyleJson: String?                     # box-level text properties (§5.1)
  fillJson: String?                          # Fill (§5.2); null = inherit/none per kind
  strokeJson: String?                        # Stroke (§5.3)
  effectsJson: String?                       # shadow, glow, blur, reflection (§5.4)
  opacity: double?                           # 0..1; null = 1
  dataJson: String?                          # kind-specific payload (§6), always with "v"
  linkJson: String?                          # click action when presenting: {url} | {slideId} | {action: next|previous|first|last|end} (03 §6.9)
  altText: String?
  decorative: bool, default=false            # excluded from alt-text checks and screen readers
  createdAt: DateTime, defaultModel=now
indexes:
  slide_element_slide_idx:
    fields: slideId, zKey
  slide_element_layout_idx:
    fields: layoutId
  slide_element_master_idx:
    fields: masterId
  slide_element_parent_idx:
    fields: parentId
```

Owner and parent rules:

- Exactly one of `slide`, `layout`, `master` is set; a child of an element group has the same
  owner as the group.
- Children's frames are in the **group's child space** (§6.9), so moving, rotating or resizing a
  group writes one row.
- `placeholderOf` points at a placeholder element of the slide's layout (or, for layout
  placeholders that refine a master placeholder, at the master's). It is a plain UUID: switching a
  slide's layout re-points instances in the same plan (05 §5.4); a dangling reference makes the
  instance a regular element in place (§10).

### 3.6 Tables

Table structure and cells are rows (P2/P3), mirroring Sheets' rows/columns/cells so concurrent
row insertion, column resizing and typing into different cells all merge.

```yaml
class: SlideTableAxis
table: slide_table_axis
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7
  element: SlideElement?, relation(onDelete=Cascade, deferred)   # kind = table
  dimension: TableDimension                  # row, column
  sortKey: String
  size: double?                              # su; row: min height (rows grow to fit text); null = even split
  header: bool, default=false                # header row / first column styling (05 §2.8)

class: SlideTableCell                        # id = SlidesIds.tableCellId(elementId, rowId, colId)
table: slide_table_cell
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7      # always overwritten with the deterministic id
  element: SlideElement?, relation(onDelete=Cascade, deferred)
  row: SlideTableAxis?, relation(name=table_row_cells, onDelete=Cascade, deferred)
  column: SlideTableAxis?, relation(name=table_column_cells, onDelete=Cascade, deferred)
  text: String?                              # Delta (§4)
  fill: String?                              # ColorRef
  borderTop: String?                         # "<width>|<style>|<ColorRef>" style ∈ solid, dashed, dotted, none
  borderRight: String?
  borderBottom: String?
  borderLeft: String?
  vAlign: String?                            # top, middle, bottom
  padding: String?                           # "t,r,b,l" su
  rowSpan: int?                              # merge origin only; null = 1
  colSpan: int?
indexes:
  slide_table_cell_element_idx:
    fields: elementId
```

A cell row exists iff at least one field is non-null (as Sheets cells). Merges are stored on the
top-left cell (`rowSpan/colSpan`); overlapping merges after a concurrent merge resolve by the
maintenance rule in §10.

### 3.7 Builds (animations)

```yaml
### One animation step on a slide (behavior and effect catalog: 06).
class: SlideBuild
table: slide_build
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7
  slide: Slide?, relation(onDelete=Cascade, deferred)
  element: SlideElement?, relation(onDelete=Cascade, deferred)   # always set (nullable only by the FK convention)
  kind: BuildKind                            # buildIn, buildOut, emphasis, motion (06 §2)
  effect: String                             # e.g. "fade", "moveIn", "typewriter", "codeHighlight" (catalog: 06)
  sortKey: String                            # order on the slide
  trigger: BuildTrigger                      # onClick, withPrevious, afterPrevious
  delayMs: int, default=0
  durationMs: int                            # effect default from 06
  easing: String                             # easing expression (06 §4.3): "easeOut", "cubic(0.2,0,0,1)", "spring(0.5,0.25)"
  optionsJson: String?                       # direction, deliver by (paragraph/word/char/series/…), motion path, code step refs … (06/07/08)
  createdAt: DateTime, defaultModel=now
indexes:
  slide_build_slide_idx:
    fields: slideId, sortKey
```

### 3.8 Code states

```yaml
### One version of a code element's source, for type-in / morph between states (behavior: 07).
### Every state, including the first, is a row; a code element has ≥ 1 state (07 §3.2).
class: CodeState
table: code_state
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7
  element: SlideElement?, relation(onDelete=Cascade, deferred)   # kind = code
  sortKey: String
  label: String?                             # "Add caching"
  code: String                               # full source of this state (whole-value LWW)
  language: String?                          # null = the element's language (07 A-07-2)
  title: String?                             # null = the element's title
  highlight: String?                         # line-highlight steps for this state, e.g. "1-3 | 5" (07 §4.1)
  annotationsJson: String?                   # per-step callouts (07 §4.4)
  transitionJson: String?                    # how this state is reached from the previous: mode type | morph | instant + options (07 §5.3)
  createdAt: DateTime, defaultModel=now
indexes:
  code_state_element_idx:
    fields: elementId, sortKey
```

### 3.9 Linked charts

```yaml
### The link of a chart element to a chart in a Wonky Sheets spreadsheet (behavior: 08).
class: ChartLink                             # id = SlidesIds.chartLinkId(elementId)
table: chart_link
serverOnly: true
fields:
  id: UuidValue, defaultModel=random_v7
  element: SlideElement?, relation(onDelete=Cascade, deferred)   # kind = chart
  spreadsheetItemUuid: UuidValue             # drive item (another file: plain UUID)
  chartObjectId: UuidValue                   # Sheets EmbeddedObject id
  sourceSpecJson: String                     # the Sheets ChartSpec at last update
  dataSnapshotJson: String                   # resolved series/categories at last update (renders offline / without access)
  sourceVersion: String                      # opaque version of the source at last update (08)
  updatedAt: DateTime                        # when the snapshot was taken
  updatedBy: UuidValue
  autoUpdate: bool, default=false            # "Update automatically" (08)
```

The chart element's own `dataJson` holds the **deck-side style override** (theme palette, fonts,
3D camera) and is rendered over the link's snapshot (08). *Unlink* deletes the `ChartLink` row and
moves the snapshot into the element's `dataJson` as a **static** chart (`source: static`, 08 §7).

### 3.10 Op log

Every committed change is one op of the file's log (`rev_op`: revision, author, `actorKind`, label, applied payload with
`before`, `summaryJson` below, `detailJson`, `recordId` of server changes). The client sends the
plan's summary with the op; server changes without one get `SlidesChangeSummary.of(changes)`
(inserts counted as *revived* for reverts and restores). Op payloads are pruned after 30 days
(`revlog.pruneOps`), the slim rows kept for idempotency.

#### 3.10.1 `summaryJson`

```jsonc
{
  "v": 1,
  "kinds": ["text", "frame", "style", "structure", "order", "theme", "build", "code", "chart", "notes", "deck"],
  "slides": ["<id>", …],                      // slides touched (≤ 500; then "slidesOverflow": true)
  "elements": ["<id>", …],                    // elements touched (≤ 1,000; then "elementsOverflow": true)
  "deleted": { "slides": [], "elements": [], "groups": [], "themes": [] },   // comment orphaning (09 §3.2)
  "revived": { "slides": [], "elements": [], "groups": [], "themes": [] },
  "chartLinks": ["<elementId>", …]            // links created/updated/removed (08)
}
```

Server consumption ([17](../17-revlog-sync.md) part 5 §6.2): the durable post-commit hooks of `SlidesRevBinding`
(`wonky_server/lib/src/slides/revlog/slides_hooks.dart`), in order `activity` (one edit event
per author and batch: `changes`, `slides`, `slidesDeleted`, `themes`, the set `slideIds`;
repairs and system ops don't count), `versions`, `driveEdit`, `title` (`Deck.title` →
`DriveItem.name`, skipping system ops), `modified` (`modifiedAt` and search text from the deck
title, group titles, slide element text, table cells and notes, read by `fileId`; ≤ 10,000 rows
each, ≤ 100,000 characters; throttled 10 s), `comments` (orphaning/revival from `deleted`/
`revived`, reason `{kind, id, revision}`) and `contentSize`. The headless deck follows the ops
([17](../17-revlog-sync.md) part 5 §9), so it needs no invalidation.

### 3.11 Enums (`wonky_server/lib/src/slides/models/rows/enums/`)

| Enum | Values |
|------|--------|
| `SlideSizePreset` | `widescreen16x9`, `standard4x3`, `wide16x10`, `square`, `portrait9x16`, `a4`, `letter`, `custom` |
| `DeckAppearance` | `light`, `dark` |
| `SlideElementKind` | `text`, `shape`, `line`, `image`, `table`, `icon`, `code`, `chart`, `group` |
| `PlaceholderType` | `title`, `subtitle`, `body`, `picture`, `chart`, `table`, `code`, `caption`, `bigNumber`, `quote`, `attribution`, `slideNumber`, `footer`, `date`, `object` |
| `TableDimension` | `row`, `column` |
| `BuildKind` | `buildIn`, `buildOut`, `emphasis`, `motion` (append-only; 06 A-06-2) |
| `BuildTrigger` | `onClick`, `withPrevious`, `afterPrevious`, `onElementClick` (added in S-2, reserved for P2: never written yet) |

Enums are serialized by name. New values are additive and change the `slidesSchema` hash
([17](../17-revlog-sync.md) part 2 §4.3; §14.1).

---

## 4. Rich text

### 4.1 Wonky Slides Text Schema v1 (Delta)

Text bodies are **Quill Delta documents** (inserts only, ending with `"\n"`), like Write
([Write 02 §1](../wonky_write/02-document-model.md)), but with **presentation formatting**: Slides
is not Markdown-bound. One schema serves text boxes, shapes, placeholders and table cells; notes
use a subset (§4.3). Validator/normalizer: `SlidesDeltaValidator`, `SlidesDeltaNormalizer` in
`wonky_slides_core/lib/src/text/` (client, server, importers, MCP).

**Inline attributes** (on text inserts):

| Attribute | Value | Notes |
|-----------|-------|-------|
| `bold` | `true` | Weight from the theme font (≥ 600) |
| `italic` | `true` | |
| `underline` | `true` | |
| `strike` | `true` | |
| `code` | `true` | Inline code: `@mono` + `codeStyle.inline` chrome (05 §2.9) |
| `font` | FontRef | `@heading`/`@body`/`@mono`/family |
| `weight` | `100`–`900` | Snapped to the family's shipped weights |
| `size` | number (su) | 6–800 |
| `color` | ColorRef | |
| `highlight` | ColorRef | Text background |
| `script` | `"super"` \| `"sub"` | |
| `caps` | `"all"` \| `"small"` \| `"title"` | Display transform, text unchanged |
| `letterSpacing` | number (em, −0.2…1) | |
| `link` | `https://…` \| `mailto:` \| `slide:<slideId base62>` \| `wonky://…` | Slide links jump when presenting (03 §6.9) |

**Block attributes** (on `"\n"`):

| Attribute | Value | Notes |
|-----------|-------|-------|
| `style` | theme text style key: `title`, `subtitle`, `heading`, `body`, `body2`, `caption`, `quote`, `attribution`, `bigNumber`, `label` | null = the box's default style (placeholder type or `body`) |
| `align` | `left`, `center`, `right`, `justify` | null = text style's |
| `list` | `bullet`, `ordered`, `check`, `unchecked` | |
| `listStyle` | bullet glyph key (`disc`, `circle`, `square`, `dash`, `arrow`, `check`, `star`, `emoji:<char>`, `none`) or numbering (`decimal`, `lowerAlpha`, `upperAlpha`, `lowerRoman`, `upperRoman`) | null = theme default per level (05 §2.5). A paragraph without `list` and `style` takes `list`/`listStyle`/`listStart`/`indent` from the box defaults (`textStyleJson.defaults`, e.g. a body placeholder's bullets); `listStyle: none` turns such a default list off (SL-13) |
| `listStart` | int ≥ 0 | Ordered lists: first number of the run |
| `indent` | 0–8 | Lists and plain paragraphs |
| `lineHeight` | multiplier 0.7–3 | |
| `spaceBefore`, `spaceAfter` | su 0–400 | |
| `dir` | `rtl` | Right-to-left paragraph |

No embeds: images, tables, charts, icons and code are **elements**, not inline content. Emoji are
text. Soft line breaks are U+2028 (as Write).

Constraints (validated before every write, client and server): canonical form (no empty inserts,
adjacent equal attributes merged, ends with `"\n"`); no control characters except `\n`, U+2028,
and `\t` (converted to 4 spaces outside lists); unknown attributes dropped; ≤ 20,000 characters
per body (§13); links restricted to the schemes above.

*As built (SL-7, SL-8):* the schemas are `SlidesText` (`wonky_slides_core/lib/src/model/text/`);
`SlidesDeltaValidator` (issues `{code, message, op?, attribute?}`: `not_a_delta`,
`not_an_insert`, `embed`, `missing_final_newline`, `control_character`, `unknown_attribute`,
`invalid_attribute`, `not_canonical`, `too_long`) and `SlidesDeltaNormalizer` (canonical form,
truncation keeping the cut line's paragraph attributes, `fromPlainText` with list detection) are
in `lib/src/text/` (`package:wonky_slides_core/text.dart`).

### 4.2 Effective text style

Per run: **inline attributes** ▸ **paragraph `style`** (theme text style) ▸ **box defaults**
(`textStyleJson.defaults`, §5.1) ▸ **placeholder chain** (instance ▸ layout placeholder ▸ master
placeholder `textStyleJson`) ▸ **theme text style** for the box's default style key ▸ theme
`body`. Resolution is pure Dart (`TextStyleResolver`, core) and memoized per (theme hash,
appearance, box style hash).

### 4.3 Speaker notes

`Slide.notes` uses the same Delta form restricted to `bold`, `italic`, `underline`, `strike`,
`link`, `highlight`, `list` (`bullet`/`ordered`), `indent`. Notes render in the app UI font in
the editor/presenter and in the theme body font in PDF notes pages (10). ≤ 50,000 characters.

### 4.4 Concurrent editing: soft lock (decision D6)

Concurrent edits of the **same** text body resolve last-writer-wins on the whole `text` column:
the op that reaches the server last wins ([17](../17-revlog-sync.md) Q1). To make that rare,
editing a text body claims it:

1. Entering text editing in a body (`SlideElement.text`, `SlideTableCell.text`, `Slide.notes`,
   `CodeState.code`) publishes `editing: {target}` in the user's presence cursor (09 §1.1). The
   claim is ephemeral (presence only, never synced) and released on exit, on idle (60 s without
   input) and when the session leaves.
2. Other participants see the body **soft-locked**: a presence-colored outline with "Anna is
   editing" (09 §2.3); double-click / Enter shows a popover *"Anna is editing this text."* with
   **Edit anyway** and **Cancel**. Text commands targeting the body are disabled with the reason
   "Anna is editing this text"; box-level changes (move, resize, fill, style) remain allowed —
   they are different columns.
3. **Edit anyway** enters editing while the other claim exists; both claims show. The write
   that arrives last wins the column; the overwritten user's text is kept locally and offered
   for recovery (*Overwritten text* review, 09 §6.3).
4. Offline there are no claims: concurrent offline edits of one body resolve LWW when the outbox
   is sent (the last to arrive wins, also over newer online edits), with the same recovery offer.
5. Live feel: while editing, the editor persists the body after 300 ms of inactivity and on exit
   (one `slides.rows` undo step per typing burst, suite 08 §3.1 rule 4), and broadcasts
   **ephemeral text hints** (09 §2.4) so watchers see typing in real time between commits.
6. Agents: headless writes to a body claimed by a human return `being_edited` unless the tool is
   called with `force: true` (11).

### 4.5 Decided (v2 review, Q18): finer-grained text merging

**Decision:** option A (soft lock + LWW per body) ships in M9; option D (three-way merge on
receive) is a **P2** improvement, built only if users report lost text. The options considered:

| Option | How | Pros | Cons |
|--------|-----|------|------|
| **A. Soft lock + LWW per body** *(chosen for v1)* | As §4.4 | Simple; offline-safe; small rows; same machinery as other columns; text bodies on slides are short | Two people typing in one box at once lose work (mitigated by lock, hints and recovery) |
| B. Per-paragraph rows | `TextParagraph(elementId, sortKey, text, blockAttrsJson)` rows; edits within one paragraph LWW | Different paragraphs of one box merge; offline-friendly | 5–10× more rows; cross-paragraph operations (split/join, multi-paragraph paste, list renumbering) become multi-row plans; same-paragraph conflicts remain; complicates auto-fit/layout ingestion |
| C. OT per text body | Delta OT over a per-deck collaboration stream (reuse Write's `compose/transform`), LWW snapshot persisted to the row | Character-level real-time merging | Online only (offline falls back to A anyway); a second sync mechanism next to the deck's row sync; server must hold per-body OT state; much more code |
| D. Three-way merge on receive | Client keeps the last synced text as base; when a remote write arrives for a body with unsynced local edits, merge base/ours/theirs with `DeltaDiff` and write the result | Recovers most concurrent edits, offline too | Both sides may merge and re-write (needs a deterministic tie rule); rare surprising results |

The *Overwritten text* review measures how often A loses text (count of recovery offers per
1,000 editing sessions, logged); that metric decides whether D is scheduled.

**Option C is unblocked by RevLog** (follow-up, not scheduled). Whole-body LWW is ordered by
arrival at the server's sequencer, and that sequencer makes a character-level merge feasible
without a second stream: rebase a body's Delta against the intervening ops of the same column
before applying it, offline edits included.

---

## 5. Common style JSON

All JSON columns carry `"v": 1` and are validated by `SlidesStyleSchemas` (core; JSON-schema
files exported for MCP). Unknown keys are dropped with a warning.

### 5.1 `textStyleJson` (box-level text)

```jsonc
{
  "v": 1,
  "anchor": "top",                 // top | middle | bottom (vertical alignment in the box)
  "insets": [24, 24, 24, 24],      // t, r, b, l su
  "autofit": "shrink",             // none | shrink (shrink text on overflow) | resize (grow box height)
  "wrap": true,                    // false = single line, box grows horizontally (text boxes)
  "columns": 1,                    // 1–3 (P2), with "columnGap": 24
  "defaults": {                    // default run/paragraph attributes for this box (any §4.1 attrs)
    "style": "body", "font": "@body", "size": 40, "color": "theme:text1", "align": "left"
  },
  "verticalText": false            // P2
}
```

Auto-fit is **derived** (P8): `shrink` computes a scale in steps of 2.5 % (min 25 %) applied to
sizes and spacing until the text fits; `resize` grows the effective height (the stored height is
the minimum). Both are recomputed by every renderer from the same rows (03 §6.4).

### 5.2 Fill (`fillJson`)

```jsonc
{ "v":1, "type":"solid",    "color":"theme:accent1" }
{ "v":1, "type":"gradient", "kind":"linear", "angle":135,
  "stops":[{"at":0,"color":"#4F46E5"},{"at":1,"color":"#EC4899"}] }          // kind: linear | radial
{ "v":1, "type":"gradient", "kind":"radial", "center":[0,0], "radius":0.9,      // radial: center (fractions, default 0.5,0.5),
  "stops":[…] }                                                              // radius (fraction of the diagonal, default 0.5)
{ "v":1, "type":"image",    "fileUuid":"…", "fit":"cover", "opacity":1 }     // fit: cover | contain | tile | stretch
{ "v":1, "type":"none" }
```

### 5.3 Stroke (`strokeJson`)

```jsonc
{ "v":1, "color":"theme:text1", "width":4, "dash":"solid",     // solid | dash | dot | dashDot | longDash
  "cap":"round", "join":"round",                                // butt|round|square ; miter|round|bevel
  "startArrow":"none", "endArrow":"triangle",                   // lines only: none | triangle | open | stealth | circle | diamond | bar
  "arrowSize":"m" }                                             // s | m | l
```

`{"v":1,"type":"none"}` = no stroke.

### 5.4 Effects (`effectsJson`)

```jsonc
{ "v":1,
  "shadow": { "color":"#00000040", "blur":24, "dx":0, "dy":12, "spread":0 },   // outer shadow
  "glow":   { "color":"theme:accent1/alpha:0.6", "radius":16 },                 // P1
  "blur":   8,                                                                  // layer blur (P1)
  "reflection": { "opacity":0.3, "distance":0, "size":0.5 },                    // P2
  "blendMode": "normal" }                                                       // P2
```

---

## 6. Per-kind `dataJson` schemas

Behavior of each kind is specified in [03](03-editor-canvas-and-objects.md) (and 07/08 for code
and charts). `dataJson` is whole-value LWW; fields that users change independently and often live
in columns instead (§3.5).

### 6.1 `text`

Text boxes use `text`, `textStyleJson` (default `autofit: "resize"`, `wrap: true`) and optional
`fillJson`/`strokeJson`. `dataJson` is null.

### 6.2 `shape`

```jsonc
{ "v":1,
  "geometry":"roundRect",          // shape library key (03 §6.3): rect, roundRect, ellipse, triangle, rightTriangle,
                                   // diamond, pentagon, hexagon, octagon, star5, star8, arrowRight, arrowLeftRight,
                                   // chevron, callout, speech, cloud, heart, plus, cross, donut, arc, blockArc, frame,
                                   // cylinder, cube, ribbon, brace, bracket, … | "custom"
  "adjust": { "radius": 0.12 },    // geometry handles (0..1 of the relevant dimension)
  "path": null,                    // custom: SVG path data in a 0..1000 box, "fillRule": "nonzero" | "evenOdd"
  "textBounds": null }             // optional override of the text rectangle inside the geometry
```

Shapes may hold text (`text`, `textStyleJson`, default `anchor: "middle"`, `align: "center"`).

### 6.3 `line` (lines, arrows, connectors)

```jsonc
{ "v":1,
  "routing":"straight",            // straight | elbow | curved
  "start": { "x":0, "y":0, "connect": { "elementId":"<b62>", "site":"right" } },   // site: top|right|bottom|left|center|<n> (geometry site index)
  "end":   { "x":1, "y":1, "connect": null },
  "waypoints": [],                 // elbow: corners the route runs through; curved: [bend point] (SL-44); normalized in the frame
  "label": null }                  // P2: text on the line
```

Endpoints are normalized to the frame (0..1). A connected endpoint is **derived** from the
connected element's current frame at render time (P8): moving a shape never writes its
connectors; the frame stored on the line is refreshed only when the line itself is edited.
A dangling `connect` (element deleted) renders at the stored point.

### 6.4 `image`

```jsonc
{ "v":1,
  "src":"wonky-file://<fileUuid>",   // uploaded file (suite 12 §1.1); https:// only via the image proxy (03 §6.5)
  "naturalWidth":3024, "naturalHeight":4032,
  "crop": { "l":0.1, "t":0, "r":0.05, "b":0.2 },  // fractions of the natural size removed from each side
  "mask": "ellipse",                 // null | any shape geometry key (§6.2) — mask to shape
  "maskAdjust": null,
  "adjust": { "brightness":0, "contrast":0, "saturation":0, "temperature":0,   // −1..1
              "blur":0, "grayscale":false, "sepia":false, "invert":false },
  "recolor": null,                   // P2: ColorRef duotone
  "fileName":"team.jpg", "mimeType":"image/jpeg" }
```

### 6.5 `table`

```jsonc
{ "v":1,
  "style":"theme",                   // table style key from the theme (05 §2.8) or "none"
  "options": { "headerRow":true, "firstColumn":false, "bandedRows":true, "bandedColumns":false, "totalRow":false },
  "defaultCellPadding":[12,16,12,16] }
```

Rows, columns and cells are `SlideTableAxis` / `SlideTableCell` rows (§3.6). The element's
`height` is the minimum; rows grow to fit their text (derived).

### 6.6 `icon`

```jsonc
{ "v":1, "set":"lucide", "name":"rocket", "strokeWidth":2 }     // set: lucide | emoji
{ "v":1, "set":"emoji",  "char":"🚀" }
```

Lucide icons take their color from `strokeJson.color` (and `fillJson` for filled variants);
emoji render with the bundled emoji font (color on screen, monochrome Noto Emoji in PDF, 10).

### 6.7 `code` (fields only — behavior in [07](07-code-blocks.md))

```jsonc
{ "v":1,
  "language":"dart",                 // Write language list (shared `wonky_code`, D7)
  "lineNumbers":true, "startLine":1, "wrap":false,
  "fontSize":null,                   // su; null = auto-fit
  "title":"main.dart",               // filename tab; null = none
  "chrome":"window" }                // none | tab | window | caption (07)
```

`SlideElement.text` is null for code: every state (including the first) is a `CodeState` row
(§3.8) holding its source and highlight steps. The full field list (palette, fonts, box,
highlight style, typing defaults, callouts…) is 07 §3.1 (A-07-1).

### 6.8 `chart` (fields only — behavior in [08](08-charts-from-sheets.md))

```jsonc
{ "v":1,
  "source":"linked",                 // linked (ChartLink row) | static (unlinked snapshot) | native (08 A-08-1)
  "spec": null,                      // native: ChartSpec (shared `wonky_charts`, D7); linked: null (spec in ChartLink)
  "data": null,                      // native: small data table {columns, rows}
  "style": { "useDeckTheme":true, "palette":null, "font":null },   // deck-side overrides
  "camera": null }                   // 3D: {azimuth, elevation, perspective} override (animatable, 06/08)
```

### 6.9 `group`

```jsonc
{ "v":1, "childBounds": { "x":120, "y":80, "w":640, "h":360 } }
```

Children's frames live in the group's **child space**; rendering maps `childBounds` onto the
group's frame (scale + rotation + flip), so resizing a group scales its children without writing
them (PowerPoint's `chOff/chExt`). *Ungroup* bakes the transform into each child's frame (one
plan). Groups never hold text.

---

## 7. Local-only client tables

The Slides cache (`slides_cache_<userUuid>.db`, §9.1) has the generic tables of the RevLog
client ([17](../17-revlog-sync.md) part 2 §3 and As built 1): the decks' rows (`rev_row`), files
and revisions, coverage, the outbox, recent op metadata and outcomes. Small per-user state lives
in the user's local key-value store (suite 12 §3) under `slides.*` keys:

| Key | Content |
|-----|---------|
| `slides.view.<deckId>` (`LocalViewState`, newest 200 kept) | current slide id, selection (element ids), zoom/fit, scroll, view mode (`normal`/`grid`/`outline`/`masters`), **collapsed group ids**, navigator width, notes pane height and visibility, inspector tab, open side panel, grid-view thumbnail size, last presented slide, edit state per code element (07 A-07-5). Presenter preferences are per user in `UserPreferences.slidesPresenter` (10 A-10-4). |
| `slides.offlineEdits.<deckId>` / `slides.conflicts.<deckId>` | Overwritten-edit tracking and the review list (09 §6.3) |
| `slides.recentColors`, `slides.recentShapes`, `slides.recentIcons`, `slides.recentLanguages` | Pickers' recents (also in `UserPreferences.slidesDefaults` when online, D4) |
| `slides.clipboard` | In-app clipboard payload (web) next to the system-clipboard marker (03 §12) |
| `comments.pending.<itemUuid>` | Offline comment queue (suite 07 §2.3) |

Collapsed groups are **per user and device** (D6/D11): never synced.

---

## 8. Server-only tables (Postgres)

| Table | Purpose |
|-------|---------|
| `rev_file`, `rev_op`, `rev_hook_state` | The deck's RevLog file (head revision, stats), op log and hook cursors ([17](../17-revlog-sync.md) part 2 §1), shared with Sheets. |
| `SlidesSnapshotIndex` | Per version: slide list (id, title, group, skipped), changed slide/element ids since the previous version with author ids (09 §4.1). |
| `ItemVersionState` | Shared (suite 07, Sheets A-10-3). |
| `ServerChangeRecord` | Server-executed changes (restore, MCP, AI) for `slides.serverChange` undo, shared with Sheets: `spreadsheetUuid` holds the deck's file uuid and `recordId` joins the change's ops, whose applied forms revert/reapply read ([17](../17-revlog-sync.md) part 5 §8.2). `slides.revertChange`/`reapplyChange` only accept records of presentations, Sheets' only of spreadsheets. |
| `ChartLinkSourceState` | Cache of each linked spreadsheet chart's current `sourceVersion` for update checks (08). |

---

## 9. Sync, files and creation

### 9.1 RevLog session

Decks sync through RevLog ([17](../17-revlog-sync.md)): the server sequences every op of a deck
file, applies it to the deck tables and streams its applied form to every other open
connection; clients keep a local cache of the deck's rows and a durable outbox of their own ops.

- **Endpoint `slidesDoc`** (`wonky_server/lib/src/slides/endpoints/slides_doc_endpoint.dart`):
  `connect(fileUuid, knownRevision, tabId, input)` (the stream of 17 part 4 §2), `page(fileUuid,
  request)` (bootstrap pages; a deck loads in one structure page with every table), `ops(fileUuid,
  from, to)` and `info(fileUuid)`. Viewer+ to read, Editor+ (the effective role incl. the
  editor limit) to submit. ACL changes post `RevBus.rolesChanged` (open sessions re-check).
- **Binding** `SlidesRevBinding` (`wonky_server/lib/src/slides/revlog/`): schema `slidesSchema`,
  `contentCount` = elements, the owner check of §3, the summary of §3.10.1, the hooks of §3.10
  and the headless model (`DeckModel`) of `HeadlessFileCache` (`SlidesRevlog.model(session,
  fileUuid)`). Registered at start (`SlidesRevlog.register()`, `server.dart`). Deck sizes for
  the quota sum the file's rows (`RevFileSizeEstimator`).
- **Client** (`wonky_slides/lib/features/revlog/`): `SlidesRevLog` installs one `RevLogClient`
  per signed-in user (cache `slides_cache_<userUuid>.db`; desktop: app support dir; web: OPFS
  via `sqlite3.wasm` + `db_worker.js`, IndexedDB fallback, suite 12). `openDeckSession(services,
  itemUuid)` opens a `LoggedDeckSession` (17 part 6 §1.2): a deck in the cache opens from it with
  the outbox on top (`DeckReady` at once, also offline) and catches up from the ops since its
  revision; a deck not on the device shows "Downloading presentation…" until its single
  structure page arrived, or "This presentation isn't available offline." while offline (it
  opens by itself once online). Writes go into the outbox and are sent as ops; remote ops arrive
  in revision order as remote batches; editors run the repairs of §10.
- **Availability** (17 part 6 §2.5): decks opened in the last 14 days (at most 50) or pinned
  (*Make available offline*) stay complete in the cache; decks with unsent changes are never
  evicted. Browsers without OPFS keep at most 50,000 elements, the decks opened least recently
  leave first.
- Whole-body LWW per `text`/`notes`/`code` column (§4.4); the sequencer orders concurrent writes
  by arrival.

### 9.2 Decided (v2 review, Q19): one replica syncing every space kind

**Superseded by RevLog (M13).** Every deck and spreadsheet is a RevLog file opened by its own
session, so an app's cache only ever holds files of its own kind; no filter is needed.

### 9.3 Creating decks (offline-first)

- **Drive API** (17 part 4 §5): `drive.createPresentation(parentUuid?, name, templateUuid?,
  {fileUuid?, initialize})`; with `fileUuid` it is idempotent. `initialize: true` (default)
  commits the content as the file's first revisions in the transaction that creates the drive
  item and `rev_file` (`SlidesDecks.createFile` over `RevLogService.createFile`):
  `DeckFactory.rows` (blank deck with a built-in theme and a title slide),
  `SlidesTemplateDecks.changes` (built-in templates) or `DeckCopies` (a presentation published
  as a template; quota checked first). `initialize: false` leaves the file at revision 0 and the
  client's first op creates the deck. `drive.registerPresentation(spaceUuid, parentUuid?, name)`
  is the device-side form: `createPresentation(fileUuid: spaceUuid, initialize: false)`, queued
  offline as a `PendingDriveOp` and replayed into My Drive when the folder is gone. The drive
  item UUID is always the file UUID. The creation op takes the drive item's current name as
  title (17 part 4 §5).
- *New presentation* (`shell.file.new {kind: presentation}`) and the built-in templates are
  created **on the device**, online or offline (`SlidesRevLog.createPresentation`): a fresh
  UUIDv7 is the file and deck id; the rows (`CreateDeck` from the user's *New presentations*
  defaults — deck row, the default theme copy with `SlidesIds.themeCopyId/themePartId`, one
  `Slide` with layout `title` and its placeholder instances — or the built-in template's rows,
  `SlidesTemplates` in `package:wonky_slides_core/templates.dart`) become the creation op
  ("Create presentation") in the outbox; then `drive.registerPresentation` runs through the
  shell's cached drive repository (an optimistic item, queued while offline). The deck opens at
  `/slides/p/<uuid>` at once and keeps that URL; it is sent once the create has replayed.
- Presentations published as templates (items), MCP `drive.create_presentation`, AI "Generate
  deck" and devices whose cache didn't open create on the server (`initialize: true`).
- **Copy** (*Make a copy*, copy from a version, templates): `DeckCopier` (core,
  `wonky_slides_core/lib/src/copy/`) rewrites every id for the new deck (row ids are global):
  fresh UUIDv7 for every row; deterministic ids recomputed (`tableCellId`, `placeholderInstanceId`,
  `themeCopyId`/`themePartId` with the new deck id, `chartLinkId`); references remapped
  (`Slide.groupId/layoutId`, `SlideElement.placeholderOf`, `matchKey` unchanged, `parent`,
  connector `connect.elementId`, `linkJson.slideId`, text `slide:` links, build `optionsJson`
  element refs, `Deck.themeId`); uploaded files re-homed (`FileEndpoint.copyToItem`, quota-checked,
  D3); the op log is not copied; `ChartLink` rows kept (the copy stays linked if the user can
  read the spreadsheet).
- *As built (SL-8):* `DeckCopier.copy` (`package:wonky_slides_core/copy.dart`) returns the rows,
  the id map and the files to re-home (`FileRehome`). Themes with a `sourceKey` get
  `themeCopyId(newDeck, sourceKey)`, their parts `themePartId(theme, partKey)` with the built-in
  part key when the part is a built-in's deterministic row (so re-applying that built-in in the
  copy adds nothing), else the source row id; themes without provenance get fresh ids. Match
  keys of theme elements follow their ids; slide elements keep theirs. Rows whose owner is gone
  are left out. The server copies decks with `DeckCopies` (`drive.copy`, templates, version
  copies): quota check of the source's size + attachments, `DeckCopier` rows committed as the new
  file's first revisions ("Copy presentation", `SlidesDecks.createFile`), images re-homed with
  `file.copyToItem`, size measured.

---

## 10. Invariants and maintenance

Run 1 s after remote batches and after the deck is ready by the first editor client that detects
a violation (and by the server writer before headless writes). Every rule is deterministic so
concurrent fixes converge, and fixes are written as normal plans (`actorKind: user`, label
"Repair presentation", not on the undo stack).

| Violation | Render-time rule (always) | Repair write (editors) |
|-----------|---------------------------|------------------------|
| Slide whose `groupId` names a missing group (orphan) | Shown at the **end of the top level** in `(sortKey, id)` order | `groupId = null`, `sortKey = after(last top-level key)` (both columns, P4) |
| Duplicate keys in a key space | Tie-break by `id` | none |
| `Slide.layoutId` missing | First layout with the same `key` in the deck's default theme, else the `blank`-key layout, else no layout | none (an explicit layout change writes) |
| Placeholder instance whose `placeholderOf` is missing | Rendered as a regular element with its last effective frame/style computed from the master placeholder of the same `placeholderType` (else 10 %-inset default frame) | Materialize: write the resolved frame and `textStyleJson`, set `placeholderOf` to the current layout's placeholder of the same type if one exists, else null |
| Two instances on one slide pointing at the same layout placeholder (should be impossible with deterministic ids; can happen after a layout switch race) | Draw both | Keep the one with the deterministic id; the other gets `placeholderOf = null` and keeps its content |
| Element-group cycle (`parent` chain loops) | The member with the smallest id is treated as top-level | Set that element's `parent = null` with its frame baked to slide space |
| Element group with no children | Not drawn | Delete the group row |
| Child whose `parent` belongs to another owner | Treated as top-level | Re-parent to null with baked frame |
| `Deck.themeId` missing | Theme with the smallest id | Write `themeId` |
| No theme / master / layout at all (all deleted concurrently) | Built-in *Wonky* resolved in memory | Copy the built-in default theme (deterministic ids) |
| Overlapping table merges | Keep the merge whose origin has the smaller id | Clear the other origin's `rowSpan/colSpan` |
| Table cell whose row/column axis is gone | Hidden (FK repair) | none |
| Code element with no `CodeState` (concurrent delete of the last state) | Rendered empty | Insert an empty state (07 A-07-2) |
| Build whose element is gone | Cascade deletes it | — |
| Deck with zero slides | Shows the empty-deck state (04 §5.11) | none (never auto-creates slides) |

Sheet-like name uniqueness does not apply: groups and slides may share titles.

**As built (SL-7):** `DeckMaintenance` (`package:wonky_slides_core/maintenance.dart`):
`detect(model)` lists `DeckViolation`s in rule order (`noTheme`, `missingDeckTheme`,
`orphanSlide`, `groupCycle`, `foreignParent`, `missingParent`, `emptyGroup`,
`danglingPlaceholder`, `dupPlaceholder`, `mergeOverlap`, `codeWithoutState`, `orphanBuild`),
`repairOp(model)` returns the `RepairDeck` the planner turns into deterministic writes (it
re-checks every violation, so stale or repeated repairs write nothing). Differences: a slide
whose layout row is gone falls back to the default theme's `blank` layout (the missing layout's
key is unknown); cycle breakers and children with a foreign or missing parent (`missingParent`
is an addition: the parent is gone or not a group) are repaired by `parent = null` **without**
baking — the render rule already draws them top-level with their stored frame, so the picture
doesn't change; `codeWithoutState` applies to code elements on slides that are not
placeholders (code placeholders hold no state until code is inserted) and inserts the state
`SlidesIds.themePartId(elementId, "repair:codeState")`; `orphanBuild` (06 A-06-8) deletes
builds whose element or slide is gone; `noTheme` copies the built-in default with the
deterministic ids of §2.1 (its theme elements' `matchKey`s are the base-62 form of their ids,
`ThemeCopy`) and makes it the default theme; dangling and duplicate instances are materialized
(effective frame, box text style, fill/stroke/effects written) — dangling ones re-pointed at
the current layout's free placeholder of the same type, duplicates with `placeholderOf = null`.

**Hosts** ([17](../17-revlog-sync.md) part 6 §1.2). `LoggedDeckSession.runMaintenance` runs
`DeckMaintenance.repairOp` 1 s after remote batches and after ready (editors only) and commits
the repair as a normal op ("Repair presentation", `actorKind: user`, summary flag
`"repair": true`, not undoable). Server headless writes (`ServerHeadlessDeck.writeSteps`) repair
first through `SlidesServerWrites.apply(repair: true)`; the activity hook skips repair ops.

---

## 11. In-memory model (`wonky_slides_core`, pure Dart)

The RevLog cache (client) and the deck tables (server) are the persistence layer; editor,
presenter, PDF exporter, server headless tools and
version views share an in-memory **`DeckModel`** (`wonky_slides_core/lib/src/model/`, exported by
`lib/model.dart`):

- **Records**: plain Dart records per table (`DeckRec`, `SlideRec`, `SlideGroupRec`,
  `SlideElementRec`, …) built from generic `RowChange`s (`table`, `rowId`, column maps; UUIDs as
  strings, enums by name) — independent of generated Serverpod classes, exactly as Sheets
  (`WorkbookModel.applyChanges`). `DeckModel.applyChanges(List<RowChange>)` is the single
  ingestion path for local writes, remote patches, snapshots and server writes.
- **Indexes**: `SlideOrder` (flattened presentation order with group ranges, id → index, effective
  skip, slide numbers), `ElementTree` per owner (children by `parent`, sorted by `(zKey, id)`),
  `PlaceholderIndex` (instance → layout → master chains), `TableIndex` (axes by sortKey, cells by
  `(row, col)`), `BuildIndex`, `CodeStateIndex`, `ThemeIndex`.
- **Resolution**: `SlideResolver.resolve(slideId, appearance) → ResolvedSlide` — background,
  master/layout decorations, every element with effective frame, style, text styles (§4.2),
  derived auto-fit and connector routes — memoized by per-slide revision counters (a change to a
  layout bumps every slide using it).
- **Scene**: `SlideSceneBuilder` turns a `ResolvedSlide` into a renderer-independent display list
  (`SlideScene`: groups, paths, images, text runs laid out through the `TextLayoutEngine`
  interface, chart sub-scenes, code sub-scenes). Consumers: the Flutter painter, thumbnails, the
  PDF renderer (10), server PNG/thumbnail rendering, and the animation timeline (06), which
  animates scene nodes keyed by element id.
- **Change events**: `DeckChangeEvent` (`SlidesChanged`, `OrderChanged`, `ElementsChanged(slideIds,
  elementIds)`, `ThemeChanged`, `BuildsChanged`, `DeckChanged`) drive repaint and thumbnail
  invalidation.
- **Remote changes** ([17](../17-revlog-sync.md) part 6 §3.2): each remote op, in revision
  order, is overlaid with this tab's unacknowledged outbox (`Overlay.build`, so local changes
  stay on top), applied to the model and emitted on `DeckSession.remoteBatches` in the same turn.
  A property test checks that incremental patching equals a full reload.

The Flutter app adds `DeckSession` (12 §5.3) and painters (`wonky_slides/lib/features/model/`)
and the RevLog session `LoggedDeckSession` (§9.1).

**As built (SL-3):** the API surface is `package:wonky_slides_core/model.dart`
(`lib/src/model/api/`): records named `…Rec` (`DeckRec`, `SlideRec`, `SlideElementRec`, …;
map-backed, full rows), `DeckReader`, `DeckModel` with `applyChanges(changes, origin:)` and
parent indexes plus the flattened slide order (orphans last), and the events above plus
`OtherRowsChanged`, batched in `DeckChangeBatch` with `DeckChangeOrigin {local, remote, load}`.
The indexes and resolvers named above are SL-7's. Details: 12 §5.3 "As built".

**As built (SL-7):** `DeckIndexes.of(model)` / `model.indexes` holds `SlideOrder` (entries with
index, effective group, effective skip, number; group ranges; top-level items),
`ElementTree` per owner (render rules of §10), `ThemeIndex` (effective layout, usage counts),
`PlaceholderIndex` (decoded placeholder columns cached per record; resolver per slide with the
master fallback), `TableIndex` (merges with the overlap rule), builds by element and
`revision(slideId)`; each is rebuilt lazily after a batch that touches it (a silent ingestion
invalidates all). `SlideResolver(model).resolve(slideId, appearance:)` → `ResolvedSlide`
(theme via `DeckThemeResolver`, background slide ▸ layout ▸ master ▸ theme, master decorations
unless hidden, slide-number/footer field placeholders per 05 §5.5, layout decorations, the
element tree with group child space mapped into slide space, effective style, `textStyles` and
prompts), memoized per revision and appearance. Auto-fit and connector routes are derived by
the scene/geometry layer (SL-10), not stored on `ResolvedElement`: the `SlideSceneBuilder`
puts the auto-fit scale on each text layout (`TextLayoutResult.fitScale`), derived frames
(`resize` auto-fit, auto-width text, grown tables) in `SlideScene.frames` and connector routes
in `SlideScene.routes` (03 §6.10). `TextStyleResolver`
implements §4.2 (`resolve` → `ResolvedTextStyles`, memoized; `run` → `EffectiveRunStyle`). The
text schema of §4.1/§4.3 is `SlidesText` (`lib/src/model/text/`, on `RichTextNormalizer`); SL-8
adds the validator/normalizer names of §4.1 on top of it. The seeded property test checks that
a model patched incrementally (cached indexes and resolver) equals a reload after every step.

---

## 12. Writes and undo (`slides.rows` undo domain)

### 12.1 Mutation planner

All mutations are planned by **`SlidesMutationPlanner`** (core) from a `SlidesOperation` against
the `DeckModel`, producing a `MutationPlan {label, summary, changes: List<RowChange>, detail?}` —
the same plan shape as Sheets (generic types in `wonky_revlog`, `package:wonky_revlog/rows.dart`).
The planner is used by the app session and by the server writes (`SlidesServerWrites`: MCP, AI,
restore, templates), so headless and UI edits are identical.

`SlidesOperation` (sealed; one file per area under `mutations/ops/`):

| Area | Operations |
|------|------------|
| Deck | `SetDeckProps` (title, size + scale mode, appearance, numbering, footer, defaults), `SetDeckTheme` |
| Slides | `AddSlides(layoutId, after, count, inGroup?)`, `DuplicateSlides`, `DeleteSlides`, `MoveSlides(ids, target: TopLevel(before/after) \| InGroup(groupId, before/after))`, `SetSlideProps` (skip, background, layout + placeholder remap, transition, notes, hideMasterElements), `ResetSlideToLayout` |
| Groups | `CreateGroup(slideIds, title, color, target?)` (target: top-level position; required for an empty group — SL-16), `Ungroup(groupId)`, `MoveGroups(ids, before/after)`, `SetGroupProps` (title, color, skipped), `DeleteGroups(ids, withSlides)`, `DuplicateGroups` |
| Clipboard | `PasteSlides(payload, target, themeMode: keepSource \| useDestination)`, `PasteElements(payload, slideId, at?)` |
| Elements | `InsertElements`, `UpdateFrames` (move/resize/rotate/flip; names exactly the frame columns it changes), `SetElementProps` (fill, stroke, effects, opacity, locked, hidden, name, alt text, link, matchKey, readingKey), `DeleteElements`, `ReorderZ(op)`, `MoveElementsZ` (Layers drag: in front of / behind a sibling or into a group, re-parenting; SL-34), `SetReadingOrder(owner, ids)` (custom reading order, SL-34), `AlignDistribute`, `GroupElements`, `UngroupElements`, `ReplaceImage`, `SetElementData` (kind payload) |
| Text | `SetText(target, delta)` (whole body), `FormatText(targets, attrs, range?)`, `SetTextBoxStyle` |
| Tables | `InsertTableAxes`, `DeleteTableAxes`, `MoveTableAxes`, `ResizeTableAxes`, `SetCells(text/format)`, `MergeCells`, `UnmergeCells`, `SetTableOptions` |
| Builds | `AddBuilds`, `UpdateBuilds`, `MoveBuilds`, `DeleteBuilds` (details 06) |
| Code | `SetCode`, `AddCodeStates`, `UpdateCodeState`, `MoveCodeStates`, `DeleteCodeStates` (details 07) |
| Charts | `LinkChart`, `UpdateChartLink(snapshot)`, `SetChartAutoUpdate`, `UnlinkChart`, `SetChartStyle` (details 08) |
| Themes | `ImportTheme(themeTree)`, `UpdateTheme(partial)`, `ApplyThemeToSlides(themeId, slideIds, layoutMapping)`, `DeleteTheme`, master/layout CRUD and their elements (05) |
| Maintenance | `RepairDeck(violations)` (§10) |

Planner rules: plans name exactly the touched columns (P7); coupled columns are always written
together (P4); deletes of parents list child rows explicitly when the inverse must revive them
(the sequencer cascades, but undo needs the full rows; [17](../17-revlog-sync.md) RD-3); limits (§13) throw
`PlanException(code: limit, …)` before anything is applied.

**As built (SL-3):** the family is `package:wonky_slides_core/ops.dart` with one addition,
`CreateDeck(deckId, title, themeKey, size, appearance, firstLayoutKey)` — the local creation of
§9.3 (deck row, theme copy with deterministic ids, first slide with its placeholder instances),
like Sheets' `CreateSpreadsheet`; master/layout CRUD is `AddMaster`, `AddLayout`,
`UpdateMasterOrLayout`, `DeleteMastersOrLayouts`. Nullable columns are set with `Patch<T>`.
`SlidesChangeSummary.of(changes, current:)` derives §3.10.1 summaries for writers of bare
changes (undo/redo, remote patches). See 12 §5.3 "As built".

**As built (SL-7):** the planner is `SlidesPlanner` (`package:wonky_slides_core/planner.dart`).
Every plan is collected by a `PlanBuilder` over the model: later steps read the plan's own
writes, each row appears at most once (insert + updates = one insert, insert + delete =
nothing, updates name only changed columns), and coupled columns are forced into an update
together (slide `groupId+sortKey`, group `parentId+sortKey`, element `x+y` on move and all four
on resize or when an inherited frame is first written, `parentId+zKey` (+ the baked frame on
ungroup), cell `rowSpan+colSpan`, deck page size, chart snapshot). Keys come from `OrderKeys`
(robust against duplicate and malformed keys). Text bodies are normalized with `SlidesText`
before every write and limited per §13; JSON columns must be objects (`"v": 1` added). Plans
carry `detail` (`{v, texts: [{table, id, column, before, after}]}`, ≤ 20 bodies of ≤ 2,000
chars) and `result` ids (`slideIds`, `elementIds`, `groupId`, `themeId`, …). Behavior notes:
locked elements refuse frame changes and deletion (`PlanException(locked)`); deleting every
child of an element group deletes the group; ungrouping deletes builds of the group with a plan
warning; *Scale content* regenerates built-in theme geometry for the new size (part keys) and
replaces unmodified built-in text styles, scaling everything else by `s`; `DeleteTheme` moves
`Deck.themeId` to another theme; layouts/masters/themes in use are refused with "Used by N
slides — …"; `PasteSlides`/`PasteElements` take the 03 §12.2 payload (`format`, `v`, `kind`,
`groups` with `slides`, `themes` with `masters`/`layouts`/`elements`, rows by table) and rewrite
every id (placeholder instance, cell and chart-link ids recomputed; connector and build refs
remapped in JSON); file re-homing is SL-8/SL-18's. Undo labels are English, as Sheets'.

### 12.2 Writer and undo

Client (`LoggedDeckSession`, [17](../17-revlog-sync.md) part 6 §1, §4):

1. Apply the plan's `RowChange`s to the model synchronously (updates name only touched columns;
   inserts and deletes as whole rows).
2. Append them to the outbox (durable) with the label, `actorKind`, the §3.10.1 summary and the
   detail; the connection sends them as ops once stored.
3. The editor controller pushes an `UndoStep` (domain **`slides.rows`**) with the plan.
4. The server's ack makes the change "saved". A rejected op group (17 part 4 §4) rolls the
   model back, removes the plan's undo step and shows one toast naming the change and the reason.

Plans are chunked into ops of ≤ 5,000 row changes (only template/import-scale operations reach
that) that form one op group while remaining one undo step.

**Undo/redo** replay `UndoInverter.invert(plan, currentRowReader)` with the suite per-column skip
rule (suite 08 §3.3): a column whose current value differs from the plan's `columnsAfter` was
changed by someone else and is skipped; a fully skipped step is a no-op and partial skips show
*"Some changes couldn't be undone because they were edited by someone else."* Deleted rows are
restored by re-inserting the same ids (an insert of a deleted id creates the row again), so references, comment
anchors, `matchKey`s and deterministic ids stay valid. Coupled-column groups (P4) are skipped as a
unit: if any column of `{groupId, sortKey}` (or a frame set) was changed by someone else, the
whole set is skipped, so undo never tears them.

**As built (SL-2):** the table hooks are `SlidesUndoHooks` (`wonky_slides_core/schema.dart`):
`coupled` (`TableCoupledColumns`) — `slide {groupId, sortKey}`, `slide_group {parentId,
sortKey}`, `slide_element {parentId, zKey, x, y, width, height, rotation, flipH, flipV}` (the
frame lives in the parent's child space and `zKey` in the parent's key space, so (un)grouping is
undone whole or not at all), `slide_table_cell {rowSpan, colSpan}`, `slide_master {themeId,
sortKey}`, `slide_layout {masterId, sortKey}`, `chart_link` snapshot columns (A-08-2), `deck
{width, height, sizePreset}`; a group only spans the columns a step wrote. `columnwise`
(`TableColumnwiseInserts`) — `slide_table_cell` inserts undo column by column like Sheets'
cells, because deterministic cell ids let two users create the same row.

Server-executed changes (version restore, headless MCP/AI runs surfaced in the UI) use the shared
undo domain **`slides.serverChange`** (`{changeId}` → `SlidesEndpoint.revertChange` /
`reapplyChange`), mirroring Sheets A-10-5. The server writer is `SlidesServerWrites`
(`wonky_server/lib/src/slides/revlog/slides_server_writes.dart`) over
`RevLogService.submitServerChange` (17 part 5 §8: chunked op groups under the deck's file lock,
Editor+ for the attributed actor); recorded writes join their ops with a `recordId` and store a
`ServerChangeRecord`; revert/reapply invert the ops' applied forms with the per-column skip rule
above (coupled columns, column-wise cell inserts) and commit a new record; an assistant run's
records are joined into one (`ServerChangeRecords.composite`, shared with Sheets).

Selection (current slide, selected elements, text caret) is captured in
`SelectionSnapshot`s before/after each step and restored on undo/redo (suite 08 §3.1 rule 5).

---

## 13. Limits

Enforced by the planner (client and server) with the listed message; *config* values come from
`ProtocolInfo` (`wonky.slides.*`).

| Limit | Value | Behavior when exceeded |
|-------|-------|------------------------|
| Slides per deck | 1,000 (*config* `slides.maxSlidesPerDeck`) | *New slide* disabled; paste refused: "A presentation can have at most 1,000 slides." |
| Slide groups per deck | 200 | "A presentation can have at most 200 groups." |
| Group nesting depth | 1 (v1; 2 with P2 nesting) | — |
| Elements per slide / layout / master (incl. group children) | 500 | "This slide can't hold more than 500 objects." |
| Element group depth | 8 | Group command disabled |
| Text per body | 20,000 characters | Editor stops input; paste truncates with a toast |
| Speaker notes per slide | 50,000 characters | Same |
| Table size | 50 rows × 20 columns | Size picker and insert commands capped |
| Builds per slide | 200 | *Add animation* disabled |
| Code: characters / lines per state, states per element | 20,000 / 1,000, 50 | 07 A-07-3 |
| Themes per deck / masters per theme / layouts per master | 20 / 10 / 50 | Refused with message |
| Deck size | 320 – 7,680 su per side, aspect 1:4 … 4:1 | Page setup validation |
| Element frame | 1 – 20,000 su per side; positions ±40,000 su | Clamped |
| Font size | 6 – 800 su | Clamped |
| Zoom | 10 % – 400 % | Clamped |
| Image upload | ≤ remaining storage quota, ≤ 25 MB per image, ≤ 40 MP (downscaled above) | Suite quota dialog (D3) |
| Undo stack | 500 steps per deck (suite 08) | Oldest dropped |
| Op `detailJson` | ≤ 20 bodies × 2,000 chars | Summary only |
| Deck content (server-estimated serialized size, counts toward the 50 MB quota, D3) | quota | Editing never blocked; copies/imports/uploads blocked when over quota |

---

## 14. Additions defined in feature specs

Feature specs add fields and tables next to the features that need them. They are part of this
data model and **must be applied together with it** (a migration plus a new `slidesSchema`,
§14.1). Each spec lists its additions in
an "Additions to 02-data-model" section; this table indexes them.

| Spec | Section | Highlights |
|------|---------|------------|
| [03 · Editor canvas & objects](03-editor-canvas-and-objects.md) | §20 | Guides (`Deck.guidesJson`), shape library keys, image proxy, `FileEndpoint.copyToItem` |
| [04 · Screens, menus & toolbar](04-screens-menus-toolbar.md) | §17 | `LocalViewState` keys, `UserPreferences.slidesDefaults`, `drive.registerPresentation`, editor title-row action slot |
| [05 · Themes, layouts & masters](05-themes-layouts-masters.md) | §10 | Theme JSON schemas, built-in theme/layout keys, font registry additions |
| [06 · Animations & transitions](06-animations-and-transitions.md) | §20 (A-06-x) | `SlideBuild` fields/enums, `optionsJson` schema, `Slide.transitionJson` schema, `matchKey` semantics, deck motion defaults, cascade/maintenance, build tokens |
| [07 · Code blocks](07-code-blocks.md) | §17 (A-07-x) | Code `dataJson` fields, every state a `CodeState` row (+ `language`, `title`, `annotationsJson`), code limits, palette pair in the theme |
| [08 · Charts from Sheets](08-charts-from-sheets.md) | §21 (A-08-x) | Chart `dataJson` (`static` source, overrides, snapshot), `ChartLink.sheetId`, snapshot schemas, maintenance writes, `SlidesChartEndpoint` |
| [09 · Collaboration & history](09-collaboration-history.md) | §11 | Presence cursor JSON, text hints, `SlidesSnapshotIndex`, comment anchor kinds |
| [10 · Presenting & PDF](10-presenting-and-pdf.md) | §19 (A-10-x) | `Deck.presentJson`, `Slide.timingsJson`, skip semantics, `UserPreferences.slidesPresenter`, presentation session models, export endpoint |
| 11 · MCP & AI | (by 11) | Headless deck cache, `being_edited` error, AI preview records |

Known LWW granularity limits (documented, accepted): text bodies (`text`, `notes`, `code`) merge as
whole values (§4.4); `fillJson`, `strokeJson`, `effectsJson`, `textStyleJson`, `dataJson`,
`transitionJson`, `optionsJson` and theme JSON columns merge as whole values.

### 14.1 Schema changes

The deck tables are server tables (§3), so a table or enum change is an ordinary server
migration (`create_migration`) plus a regenerated `slidesSchema` (`tool/gen_rev_schema.dart`),
whose hash changes. The client's cache drops and re-downloads the deck rows when its schema hash
differs, keeping the outbox; the server accepts ops encoded with the hashes it lists as
compatible (`RevSchema.compatibleWith`) and asks older clients to update otherwise
([17](../17-revlog-sync.md) part 2 §4.3, part 6 §2.4). Guard tests compare `slidesSchema` with the
deck tables. The current tables come from migration `20261018102850457-slides-revlog`.

*As built (M9–M11):* before RevLog the tables were synced by the offline-sync engine and changed
in lock-step schema releases for all apps (S-1 with SL-2, S-2 with SL-24).
