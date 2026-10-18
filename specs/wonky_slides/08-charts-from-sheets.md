# Slides 08 · Charts from Sheets (linked, 3D, native)

Wonky Slides shows charts made in Wonky Sheets — including 3D charts — as **linked chart
elements**, like Google Slides' linked Sheets charts but with the same rendering engine as
Sheets, animatable data builds, an animatable 3D camera and Magic Move between chart states.
This spec defines:
- the **extraction** of the chart engine out of `wonky_sheets_core` into the shared pure-Dart
  package **`wonky_charts`** and the Flutter package **`wonky_charts_flutter`** (exact module
  boundaries; what stays in Sheets);
- the **chart element** and its `ChartLink`: source ids, data **snapshot**, theme override,
  style overrides;
- the **insert flow** (Drive picker → spreadsheet → chart list with previews);
- **update detection**, the **Update** button and auto-update;
- **permission and error cases** (viewer without sheet access, deleted/moved chart, offline);
- **unlink**, editing style in Slides, **chart builds**, **3D** (GPU backend, camera presets,
  orbit and camera builds, Magic Move between angles), **native charts** from a small data table
  (P1), **PDF** rendering, **server endpoints**, commands, undo, acceptance criteria.

Read first: Sheets [08-charts-and-objects.md](../wonky_sheets/08-charts-and-objects.md) (§3 chart
spec, §4 data resolution, §6 rendering, §23 3D), Sheets
[12-mcp-and-ai.md](../wonky_sheets/12-mcp-and-ai.md) §2 (`HeadlessWorkbook`),
[02-data-model.md](02-data-model.md) (`SlideElement`, `ChartLink`),
[06-animations-and-transitions.md](06-animations-and-transitions.md) (builds, Magic Move),
[10-presenting-and-pdf.md](10-presenting-and-pdf.md) (PDF), suite
[06-sharing-and-permissions.md](../06-sharing-and-permissions.md),
[01-architecture.md](../01-architecture.md) §2.1.

Priorities: extraction, linked charts, update flow, 2D builds and 3D rendering/camera builds
are **P0 for M10**; native charts and paste-from-Sheets are **P1**; items marked P2 later.

---

## 1. Principles

1. **One engine.** Sheets and Slides render charts with the same layout engine, scene and
   renderers; a linked chart in Slides looks exactly like the chart in Sheets (except for the
   optional deck-theme restyle).
2. **Snapshots, not live queries.** A deck stores the chart's spec and its **resolved data**.
   It renders offline, in PDFs, on the server and for viewers who can't open the spreadsheet.
   Updating is an explicit (or opted-in automatic) write.
3. **Sheets owns the data.** Data ranges, aggregation and header detection are edited in Sheets;
   Slides edits only presentation (style overrides, camera, builds).
4. **No cross-app imports.** Slides never imports Sheets packages; it talks to the server, which
   resolves charts with `wonky_sheets_core`.

---

## 2. Package extraction (`wonky_charts`, `wonky_charts_flutter`)

### 2.1 Boundaries

```
wonky_numfmt (pure)      number-format patterns, date serials, locale symbols  (§2.5)
      ▲
wonky_charts (pure)      spec model + schema, ChartData model (+ JSON), layout, scene, 3D model/
      ▲   ▲              mesher/camera/software renderer, SVG/PDF/raster renderers, stats,
      │   │              downsampling, describer, reveal masks, snapshot format, table recommender
      │   └──────────── wonky_sheets_core: cell data resolution (ChartDataResolver), cell-based
      │                  recommender, sparklines, anchors, XLSX/ODS chart mapping, print hook
wonky_charts_flutter     ChartPainter, FlutterTextMeasurer, ChartView (hover/legend), 3D GPU backend
                         (flutter_scene), orbit gesture, chart type icons, ChartStyleEditor (Customize UI)
      ▲            ▲
wonky_sheets       wonky_slides
```

### 2.2 Module map (from `wonky_sheets_core/lib/src/charts/**`)

| Today | Goes to | Notes |
|-------|---------|-------|
| `spec/chart_spec.dart`, `chart_spec_parts.dart`, `chart_type.dart`, `series_style.dart`, `type_options.dart`, `three_d_options.dart`, `error_bars.dart`, `spec_json.dart` | `wonky_charts/lib/src/spec/` | `GridRange` references become opaque (§2.4). |
| `spec/chart_data_spec.dart` | `wonky_charts/lib/src/spec/` | `ranges` = `List<DataRangeRef>` (opaque JSON); `DataRef`, `DomainRef`, `SeriesRef` unchanged. |
| `spec/spec_schema.dart` | `wonky_charts/lib/src/spec/` | `GridRangeSchema` replaced by a pluggable `RangeRefSchema` (Sheets registers the GridRange validator, Slides a "no ranges allowed" validator for native/snapshot specs). |
| `spec/image_spec.dart` | **stays** in `wonky_sheets_core` (`objects/`) | Sheets images are not charts. |
| `data/chart_data.dart` | `wonky_charts/lib/src/data/` | + `toJson`/`fromJson` (§3.4). |
| `data/data_algorithms.dart` | split: generic (aggregation over doubles, histogram buckets, LTTB) → `wonky_charts`; `FValue`-specific helpers stay in Sheets | |
| `data/chart_data_resolver.dart` | **stays** (`wonky_sheets_core/lib/src/charts/data/`) | Reads cells; produces `wonky_charts` `ChartData`. |
| `data/value_formatter.dart` | `ChartValueFormatter` interface + `ChartFormats` → `wonky_charts`; `DefaultChartValueFormatter` → `wonky_charts` on top of `wonky_numfmt` | §2.5 |
| `describe/chart_describer.dart` | `wonky_charts` | |
| `layout/*` (engine, cartesian, pie, radial, tabular, 3D layout, scales, text measurer) | `wonky_charts/lib/src/layout/` | `scales.dart` takes date serials from `wonky_numfmt`; `chart_theme.dart` takes a `ChartThemeSource` (§2.6). |
| `recommend/chart_recommender.dart` | split: profiling + rules over a generic `ChartTable` → `wonky_charts` (used by native charts, P1); cell selection/region detection → Sheets | |
| `render/**` (SVG, PDF, raster incl. rasterizer, stroker, bitmap text) | `wonky_charts/lib/src/render/` | `PdfTextMeasurer` gains a TTF-backed variant (§12). |
| `scene/**` | `wonky_charts/lib/src/scene/` | |
| `sparkline/sparkline.dart` | **stays** in Sheets (formula value), uses `wonky_charts` scene/layout primitives | |
| `stats/**` | `wonky_charts` | |
| `three_d/**` | `wonky_charts/lib/src/three_d/` | + `Chart3DView.lerp` (camera interpolation, §10.3). |
| `chart_pipeline.dart` | split: `ChartPipeline` (generic: `layout`, `exportSvg/Pdf/Png` from `ChartData`) → `wonky_charts`; `SheetsChartPipeline` (`resolve`, `build`, `printSceneFor` from `WorkbookModel`) → Sheets | |

From `wonky_sheets/lib/features/`:

| Today | Goes to |
|-------|---------|
| `charts/render/chart_painter.dart` (`ChartPainter`, scene `Picture` cache) | `wonky_charts_flutter/lib/src/render/` |
| Flutter `TextMeasurer` (TextPainter) | `wonky_charts_flutter` |
| `charts/view/chart_view.dart` (hover tooltips, legend highlight) — generic part | `wonky_charts_flutter` `ChartView` (input: `ChartSpec`, `ChartData`, theme, options; no Sheets controller) |
| `charts/view/chart_data_table_dialog.dart` | `wonky_charts_flutter` |
| `charts3d/chart3d_gpu.dart`, `gpu/flutter_scene_renderer.dart`, `gpu/mesh_winding.dart`, `gpu/install_chart3d_gpu.dart` | `wonky_charts_flutter/lib/src/three_d/` (lazy starter unchanged) |
| `charts3d/orbit/chart_orbit.dart` | `wonky_charts_flutter` (gesture + inertia; emits angle changes via callback) |
| `charts3d/icons/chart3d_glyph.dart`, `ChartTypeIcon` | `wonky_charts_flutter` |
| `charts/editor/*` Customize-tab sections, `charts3d/editor/chart3d_section.dart` | `wonky_charts_flutter` `ChartStyleEditor` — edits a `ChartSpec` through `onPatch(JsonMergePatch, {coalesceKey})`; no command or Sheets types inside |
| `charts/editor/chart_editor_panel.dart` (Setup tab, ranges, Sheets commands), `chart_editor_mcp.dart`, `controller/chart_controller.dart`, `chart_insert.dart`, `chart_sheet_rules.dart`, `view/chart_sheet_view.dart` | **stay** in Sheets (they compose `wonky_charts_flutter` parts) |

### 2.3 What stays in Sheets

Cell data resolution (`ChartDataResolver`, live updates on `RecalcBatch`), cell-based
recommendations, sparklines, `EmbeddedObject` anchors/object layer, chart sheets, the chart
editor's Setup tab and all `sheets.chart.*` commands, XLSX/ODS chart import/export, the print
renderer integration, Sheets MCP chart tools. Sheets behavior does not change (all Sheets chart
tests keep passing; golden masters unchanged).

### 2.4 Opaque data references

`ChartSpec.data.ranges` and scorecard `keyValueRef`/`baselineRef` are stored JSON-identical to
today (`{"s","r1","r2","c1","c2"}`), but `wonky_charts` types them as `DataRangeRef` (a
wrapper around the raw JSON map with value equality). Sheets converts with
`GridRange.fromRef(DataRangeRef)` / `.toRef()`. No data migration; `extras` preservation of
unknown keys is unchanged.

### 2.5 Number formatting (`wonky_numfmt`)

Chart axes, data labels, tooltips and table charts format numbers with spreadsheet number-format
patterns (`#,##0.0`, `0%`, `[$€]#,##0`, `yyyy-mm-dd`). The engine lives in
`wonky_sheets_core/lib/src/format/number_format/` and depends on Sheets cell types.

**Decision** (v2 review, Q27): extract the pattern engine into a new pure package
**`packages/wonky_numfmt`** — pattern parser/AST, formatter over `double`/date serials, presets,
locale symbol data, serial calendar (`dates.dart`). Sheets keeps the cell adapters
(`CellTextFormatter`, value bridges, inference from input). `wonky_charts`'
`DefaultChartValueFormatter` uses `wonky_numfmt`; Slides native charts (P1) use it for their
column formats.

Option (A) was chosen over (B) — keeping the engine in Sheets and storing pre-formatted labels
in the snapshot with a reduced formatter in Slides — because (A) gives identical labels in Sheets
and Slides and server PDF parity for ~5 kLOC moved mechanically. The extraction runs in M8
together with `wonky_charts` (Drive 05 work package D-3).

### 2.6 Theme boundary

`ChartTheme.from` takes a `ChartThemeSource { List<int> accents (ARGB, 6); String textFont;
int? background; int? text }` instead of `SpreadsheetTheme`. Sheets adapts its spreadsheet theme;
Slides adapts the deck theme (§3.5). `ChartUiTokens` (card/foreground/border for automatic
colors) stay as they are.

### 2.7 New in `wonky_charts`

| API | Purpose |
|-----|---------|
| `ChartData.toJson()` / `ChartData.fromJson()` | Snapshot serialization (§3.4): domain (kind, labels, numeric values, format), series (key, name, `Float64List` values as base64 little-endian doubles, format, type, axis), histogram/scorecard/table payloads, warnings. Round-trip exact. |
| `ChartSnapshot` | `{spec, data, sourceTheme, locale, source, version}` model + JSON (§3.4). |
| `ChartPipeline.layout(spec, data, …)` | Already generic; also takes `ChartRevealState` (§9). |
| `ChartRevealState` | Per `SceneTag` visibility/growth/opacity used by builds (§9); honored by all renderers. |
| `ChartSceneMorph` | Matches two scenes by `SceneTag` and interpolates primitives (Magic Move, data updates). |
| `Chart3DView` + `.lerp` | Camera triple (azimuth, elevation, perspective) with shortest-arc azimuth interpolation (§10.3). |
| `ChartTable` + `TableChartData.fromTable` | Native chart data (P1, §11). |
| `TtfTextMeasurer` | Text metrics from TTF bytes (`pdf`'s `TtfParser`) for PDFs with embedded deck fonts (§12). |

### 2.8 Dependency rules (suite 01 §2.1 updates)

```
wonky_numfmt          → intl, petitparser                                   (pure)
wonky_charts          → wonky_numfmt, pdf, image, vector_math               (pure)
wonky_charts_flutter  → flutter, wonky_charts, wonky_ui, shad, flutter_scene, vector_math
wonky_sheets_core     → … + wonky_charts, wonky_numfmt
wonky_sheets          → … + wonky_charts_flutter (flutter_scene moves out of its direct deps)
wonky_slides_core     → … + wonky_charts, wonky_numfmt
wonky_slides          → … + wonky_charts_flutter
wonky_server          → … + wonky_charts (via the cores)
```
`wonky_charts*` are neither Write nor Sheets packages, so Slides may use them. The justified
exception `wonky_sheets_core → vector_math` stays: it belongs to the print PDF renderer
(`io/print/pdf_renderer.dart`), not to the chart renderers, so `wonky_charts` does not depend on
`vector_math` (it is allowed for the 3D work of SL-27).

### 2.9 Migration order (M8 wave 1, Drive 05 D-3; step 5 may finish in M10 with the chart element)

1. Create `wonky_numfmt` (move + re-export from Sheets core; Sheets tests green).
2. Create `wonky_charts` by moving files (git mv), introduce `DataRangeRef`, `ChartThemeSource`,
   split the pipeline; Sheets core re-exports what Sheets code imports.
3. Create `wonky_charts_flutter`, move Flutter files; Sheets composes them.
4. Move tests with their code (`test/charts/**` → `wonky_charts/test/`, golden masters re-homed;
   the scene JSON goldens must be byte-identical).
5. Add the new APIs (§2.7) with tests.

### 2.10 As built (D-3, M8)

Steps 1–4 are done; step 5 (§2.7 APIs except `DataRangeRef`, `ChartThemeSource` and the
generic `ChartPipeline`) is SL-27 (M10). Differences from the plan above:

- **`wonky_numfmt`** exports `NumberPatternFormatter` (cached; `formatNumber(double, …)`,
  `formatString`, `formatNumberText`) plus the parser/AST, `NumberFormatRenderer` (numbers and
  text), `AutomaticFormatter`, presets, `LocaleFormatData`, `FormattedValue`, `SerialCalendar`
  and `DateSerial` (moved from Sheets `formula/values/dates.dart`, re-exported there). Sheets
  keeps `NumberFormatter` (cell values, booleans/errors, format hints; delegates to
  `NumberPatternFormatter` and shares its cache), `CellTextFormatter`, inference,
  `DecimalsAdjuster` (it takes a cell value) and `FontSizeSteps`.
- **`DataRangeRef`** wraps the stored JSON (null values dropped; requires a string `s`, which is
  exactly when `GridRange.tryParse` succeeds, so validation is unchanged). The schema node is
  `RangeRefSchema` with the old GridRange JSON Schema and message; the pluggable "no ranges"
  validator for Slides comes with SL-27. Sheets helpers: `GridRange.fromRef` / `toRef`,
  `ChartDataSpec.gridRanges`, `ScorecardOptions.keyValueRange` / `baselineRange`,
  `Iterable<GridRange>.toRefs()` (`charts/chart_ranges.dart`).
- **`ChartThemeSource`** is an interface (`accentArgbs`, `textFont`, `resolveArgb`) that
  `SpreadsheetTheme` implements (call sites unchanged); `ChartThemeColors` is a plain-value
  implementation. `background`/`text` overrides come with the deck theme adapter (SL-27).
  `ChartTheme.spreadsheetTheme` is now `ChartTheme.source`.
- **Pipeline**: `ChartPipeline` (`wonky_charts`: `layout`, `build`, `exportSvg/Pdf/Png` over
  `ChartData`) and `SheetsChartPipeline` (`wonky_sheets_core`: `resolve`, `build`, `exportTheme`,
  `exportSvg/Pdf/Png`, `printSceneFor` over a `WorkbookModel`).
- **Stays in Sheets** besides §2.3: the whole recommender (the `ChartTable` profiling split is
  SL-27), `HeaderDetection` (split out of `data_algorithms.dart`; it reads `FValue`s),
  `ImageSpec` (now `objects/image_spec.dart`).
- **`wonky_charts_flutter`** got `ChartScenePainter`/`paintChartScene`/`chartSceneToPng`,
  `FlutterTextMeasurer`, `Chart3DGpuRenderer`/`Chart3DBackends`, `ChartOrbitGesture`,
  `Chart3DGlyphPainter`, and in the separate library `gpu.dart` the `flutter_scene` backend
  (`installChart3DGpuBackend`, only the app entry point imports it). `ChartView`, the data table
  dialog, `ChartTypeIcon` and the Customize-tab `ChartStyleEditor` stay in Sheets until Slides
  needs them (SL-27); they are outside D-3's owned folders.
- **Tests**: tests that need no workbook moved (`wonky_charts/test`: spec, scales, text measurer,
  scene, renderers, stats, generic data algorithms, value formatter; `wonky_numfmt/test`: parser,
  automatic; `wonky_charts_flutter/test`: mesh winding) plus new tests for `ChartPipeline`,
  `DataRangeRef`, `ChartThemeColors`, `NumberPatternFormatter` and the painter. Layout, 3D,
  describer, recommender and resolver tests build their data from workbooks and stay in
  `wonky_sheets_core/test/charts` with the scene JSON goldens (unchanged, byte-identical).

### 2.11 As built (SL-27, M10)

The §2.7 APIs exist, with these names and additions:

- **Snapshot** (`wonky_charts/lib/src/snapshot/`): `ChartData.toJson`/`fromJson`
  (`ChartDataCodec`: numeric arrays as base64 little-endian doubles, single numbers as JSON
  numbers or `"NaN"`/`"Infinity"`, `dataVersion` as a decimal string because 64-bit hashes
  don't fit JavaScript numbers, `domain.length` for the timeline); `ChartDataSnapshot`
  (`dataSnapshotJson`, §3.4, with `ChartSourceTheme` — accents, text font **and the named
  theme colors** — and `ChartSourceInfo`); **`ChartSourceSnapshot`** is the in-memory pair the
  spec calls `ChartSnapshot` (the core's operations already export a `ChartSnapshot`: the
  column values of a link update); `ChartSnapshotColumns` (`gz:` + base64 gzip beyond 32 KB
  via `package:archive`, 512 KB limit); `ChartSourceVersion` (token parse/format);
  `ChartSnapshotLimits` (§3.4 downsampling; `preview` = 200 points).
- **Reveal**: **`ChartReveal`** (the spec's `ChartRevealState`; that name is the timeline's
  per-element state in `wonky_slides_core/motion.dart`). It is applied as a transform of the
  laid-out 2D scene (`applyTo`), so the Flutter painter and the PDF/SVG/raster renderers honor
  it unchanged, and to the 3D model (`applyTo3D`: `collapsed.lerpTo(item, grow)`, fades toward
  the chart background, hidden items left out; `Chart3DItem.withColor`). Bars grow from the
  edge nearest the zero line (the most common bar edge), horizontal for `bar`; lines draw on
  by arc length (category/point deliveries follow the revealed prefix) with markers popping in
  when reached; areas clip to the revealed x extent; radar shapes scale from the center; pie
  wedges sweep; data labels appear in the last 20 % of their part; scorecards fade (no
  count-up yet). `ChartPipeline.layout(reveal:)` applies both.
- **Morph**: `ChartSceneMorph` + `OkLab` as §9.4 (keys = tag + type + order; < 50 % matched
  data primitives → crossfade); 3D groups crossfade (3D morphs go through
  `ChartLayoutOptions.transitionFrom3D` and `Chart3DView.lerp`).
- **Camera**: `Chart3DView` (`lerp` with `Chart3DTurn` `shortest|cw|ccw` and `turns`,
  `presets`/`piePresets` of §10.2, `of(spec)`, `applyTo(ChartThreeD)`, JSON), plus
  `ChartLayoutOptions.perspective3D` and **`fitViews3D`** (§10.3 union fit: the zoom is the
  smallest fit of the listed views, compared in px per world unit).
- **Text**: **`TtfChartTextMeasurer`** (`TtfChartFace`/`TtfChartFamily`; the core's text
  layout already has a `TtfTextMeasurer`): advances equal `PdfTtfFont.stringMetrics`, missing
  glyphs measure as `?` like the PDF draws them.
- Not built: `ChartTable` + `TableChartData.fromTable` and the recommender split (native charts,
  P1), the "no ranges" `RangeRefSchema` validator for native specs (P1), `ChartView`/
  `ChartStyleEditor`/`ChartDataTableDialog` in `wonky_charts_flutter` (SL-32), the scorecard
  count-up of §9.1.

**Core** (`package:wonky_slides_core/charts.dart`, `lib/src/charts/`): `ChartElementData`
(§3.2; `background` null = the style mode's default — transparent with *Match theme*, the
sheet's background, white by default, with *Keep source style*; reads the pre-SL-27 static
forms `spec`/`spec`+`data`), `ChartOverrides` (§8.2 allowlist, `rejectedPaths`, `filter`,
`merge`, `unusedSeries`), `SlideChartSpec.effective` → `SlideChartLook {spec, theme, locale,
warnings}` (§3.5; the color behind the chart decides light/dark text), `SlideChartLayout`
(the slide scene's `ChartSceneSource`; charts are laid out at the frame size ÷ `suPerPx` = 2,
so text keeps its Sheets proportions, and `ChartNode` scales the scene into the frame;
`ChartSceneSource.chartScene` gained `background`), `SlideChartMotion` (`shapes(deck)` for
`SlideMotionInput.fromDeck(chartShapeOf:)` incl. `gz:` columns, pie and 3D flags; `reveal`,
`view`, `fitViews` from a frame's `ChartRevealState`), `ChartLinkService` (§5.6 client
contract) and `ChartLinkOps` (`link`, `update`, `refreshToken`, `probesOf`). The planner
stores `gz:` columns (validated by decoding), unlink writes `dataJson.snapshot`
`{sourceSpec, dataSnapshot}` (§3.2), and `SetChartStyle` refuses keys outside the allowlist and
the `source`/`snapshot`/`spec`/`data` keys of non-native charts (`invalid_argument`).


### 2.12 As built (SL-32, M10)

The chart element UI is in `wonky_slides/lib/features/elements/chart/` and
`wonky_slides/lib/commands/chart_commands.dart`; feature `charts` ships (native charts are the
separate hidden feature `nativeCharts`, P1).

- **`wonky_charts_flutter`** gained the shared widgets of §2.2: `ChartView` (spec + data + theme,
  hover tooltips, legend highlight, optional GPU key; the insert dialog's previews), the data
  table dialog (`showChartDataTableDialog`, `ChartDataTableDialog`, `chartDataRows`,
  `chartDataJson`; texts passed as `ChartDataTableStrings`), `ChartTypeIcon` (moved from Sheets;
  `ChartTypeIcon.of(spec)`), the hover tooltip (`ChartTooltip`, `chartTooltipLines`) and
  **`ChartStyleEditor`** (full mode, or override mode with `allows` = the §8.2 allowlist, a dot
  and a per-field reset on overridden fields; edits are merge patches through
  `onPatch(patch, {coalesceKey})`; texts through `ChartStyleEditorStrings`). Sheets uses the
  moved data table, icon and tooltip; its Customize tab stays its own (it edits more than the
  allowlist and is wired to Sheets commands) — the shared editor is new, not a move.
  `FlutterTextMeasurer` takes `familyOf` (Slides maps deck fonts registered at runtime) and
  `clear()`; `ChartScenePainter`/`chartSceneToPng` take the measurer. New dependencies: `shad`,
  `wonky_ui` (both in §2.8).
- **Stage**: `SlideRenderer.charts` defaults to `SlideChartLayout(measurer:
  SlidesChartText.measurer)` (one shared measurer for layout and paint; deck fonts load on demand
  and clear the chart layouts); chart text families are preloaded like slide text.
  `ScenePaintOptions.gpuCharts`/`chartGpu`: live stages (`SlideStage`) draw 3D charts with the
  `flutter_scene` backend (started by the first 3D chart; `main.dart` registers the starter),
  pictures (thumbnails, PNG) stay software.
- **Insert** (§4): `showChartInsertDialog` — step 1 lists spreadsheets (tabs Recent, My files =
  the root folder, Shared with me, Starred; search; spreadsheets the user may not copy from are
  disabled with the export message), step 2 the charts by sheet with `ChartView` previews in the
  deck theme (or the source look), badges (3D, chart sheet, newer version), Mod-click for several,
  *Link to spreadsheet*, *Match presentation theme* and the data notice; MCP-operable (fields
  `search`, `tab`, `spreadsheet` / `search`, `chart`, `link`, `matchTheme`; buttons `cancel`,
  `back`, `insert`). New charts use a 600 × 371 aspect (the snapshot has no Sheets anchor size);
  a selected empty chart placeholder is filled in place. Alt text = `ChartDescriber` (regenerated
  on update/relink while it still looks generated). Paste (§4.4) resolves the snapshot before
  the paste: linked pastes carry their data, *Paste chart unlinked* gives a static chart with its
  frozen snapshot; offline, links get their first snapshot at the next check.
- **Updates** (§5): `ChartLinks` (per open deck) checks on open, on resume after ≥ 60 s
  (`AppLifecycleListener`), every 5 min and once when presenting starts; after a presentation a
  toast offers *Update all*. Statuses are derived from the stored token (an undone *Update* shows
  *Update* again). Editors write token refreshes, auto-updates (toast "Charts updated from …") and
  first snapshots of pasted links as maintenance writes. The canvas badge shows for the
  **selected** linked chart (not on hover): "Linked", the §6 states, "(offline)", or the primary
  *Update* button with the summary tooltip; viewers see none. Applied updates morph on the canvas
  with `ChartSceneMorph` (450 ms; off with *Reduce editor motion*). The **Linked charts** panel
  (`slides.panel.linkedObjects`, View › Panels and Tools) lists links by spreadsheet with status,
  slide number (click selects), *Update* and *Update all* (one step), *Check now*.
- **Inspector › Chart** (§8.1, §10.2): source path + *Open*, status, *Update*, *Auto-update*,
  *Unlink*, *Change linked chart…*, style mode, background (default, transparent, slide color,
  white), 3D view (presets, rotation/tilt/perspective sliders, *Reset view*, *Add camera step*
  when animations are on), presenting options (`interactive.hoverTooltips/orbitInPresent`),
  Customize (`ChartStyleEditor` in override mode, unused series overrides with *Clean up*,
  invalid-override warning, *Reset style overrides*, *View data as table*). Toolbar: *Update*,
  *Open source*, *3D view ▾*, *Style ▾*. Format › Chart and the chart context menu carry the same
  commands.
- **Commands** (§14) as specified, with: `slides.chart.updateStyle {patch (overrides), options
  (background | interactive | style.palette/font), coalesceKey}`; `slides.chart.setCamera`
  also takes `deltaAzimuth`/`deltaElevation` (Alt+Shift+arrows, 5°) and `reset`, and always
  coalesces per chart within the undo window (drags, keys, sliders); `slides.chart.addCameraStep`
  (a `chartCamera` emphasis build of the current view; registered only with the animations
  feature); `slides.chart.copyAsImage` (PNG via the image clipboard). Orbit: dragging the plot of
  the selected 3D chart orbits it live (`ChartOrbitGesture`) and commits one `setCamera`.
- Not built: the hover badge, the panel's rail count badge, *Request access* / *Open in Drive*
  actions of §6, dropping overrides that don't apply after relinking to another type (they are
  kept and ignored by validation), a list of existing camera steps in the section, hover tooltips
  and orbit while presenting (the flags are stored; the player is SL-29's), `watch` (P1), native
  charts (P1), the scorecard count-up.

---

## 3. The chart element

### 3.1 Sources

| `source` | What it is | Data | Editable in Slides |
|----------|------------|------|--------------------|
| `linked` | Linked to a chart in a spreadsheet (`ChartLink` row) | Snapshot, refreshed by Update | Style overrides, camera, builds |
| `static` | A former linked chart that was unlinked (or inserted with "Link" off) | Frozen snapshot | Style overrides, camera, builds |
| `native` (P1) | Created in Slides from a small data table | Table in the element | Everything incl. type and data |

### 3.2 Chart `dataJson` (extends 02 §6.8)

02's keys keep their names (`source`, `spec`, `data`, `style`, `camera`); this spec adds
`static`, `overrides`, `snapshot`, `background` and `interactive`.

```jsonc
{
  "v": 1,
  "source": "linked",                    // linked | static (addition) | native (P1)
  "style": {                             // deck-side style (02)
    "useDeckTheme": true,                // true: restyle to the deck theme; false: keep the sheet's look (§3.5)
    "palette": null,                     // null = deck accents (or source palette); or ["#hex", …]
    "font": null                         // null = deck body font (or source font); or a font ref ("@body", family)
  },
  "camera": null,                        // 3D: {azimuth, elevation, perspective} override (02; §10.2–§10.3)
  "overrides": { … },                    // addition: RFC 7386 merge patch over the source spec, allowlisted keys only (§8.2)
  "snapshot": null,                      // addition, static only: {sourceSpec, dataSnapshot} frozen at unlink (§3.4 shapes)
  "spec": null,                          // native (P1): full ChartSpec without data ranges (02)
  "data": null,                          // native (P1): ChartTable (§11) (02 "small data table")
  "background": "transparent",           // addition: transparent | theme | "#hex"
  "interactive": { "hoverTooltips": false, "orbitInPresent": false }   // addition: present/viewer mode (§10.5)
}
```

### 3.3 `ChartLink` (02 §3.9; one per linked chart element, id = `SlidesIds.chartLinkId(elementId)`)

| Field | Type | Meaning |
|-------|------|---------|
| `element` (`elementId`) | FK | Owner chart element (cascade). |
| `spreadsheetItemUuid` | UUID | Drive item uuid of the spreadsheet (as in `/sheets/s/<uuid>`). |
| `chartObjectId` | UUID | `EmbeddedObject` id of the chart in that spreadsheet (MCP `chart_id`). |
| `sourceSpecJson` | String | The source `ChartSpec` JSON at the last update (`data.ranges` kept as opaque refs, used only to show "Q3!A1:D13" in the inspector; series refs keep their keys). |
| `dataSnapshotJson` | String | `ChartDataSnapshot` JSON (§3.4). Both JSON columns are stored gzip+base64 with the prefix `gz:` when > 32 KB. |
| `sourceVersion` | String | Version token of the snapshot (§5.1). |
| `updatedAt` | DateTime | When the snapshot was resolved (server time). |
| `updatedBy` | UUID | User who inserted/updated. |
| `autoUpdate` | bool | "Update automatically" (§5.5). |
| `sheetId` | String? | **Addition**: sheet the chart was on when linked (display only). |

Both snapshot columns are always written together (one plan), so a reader never combines a new
spec with old data.

### 3.4 `ChartDataSnapshot` JSON (`dataSnapshotJson`)

```jsonc
{
  "v": 1,
  "data": { … },                 // ChartData JSON (§2.7)
  "sourceTheme": { "accents": ["#4285F4", …], "textFont": "Inter" },
  "locale": "en_US",             // spreadsheet locale (formatting of labels and ticks)
  "source": {                    // display info, refreshed on update
    "spreadsheetTitle": "Finance 2026", "sheetName": "Q3", "chartTitle": "Revenue by region",
    "rangesA1": ["Q3!A1:D13"]
  },
  "version": "…"                 // = ChartLink.sourceVersion (§5.1)
}
```

`ChartSnapshot` (in `wonky_charts`, §2.7) is the in-memory pair `{sourceSpec, dataSnapshot}` read
from the two columns (linked) or from `dataJson.snapshot` (static).

Size limits: `data` is downsampled on the server before snapshotting (LTTB to ≤ 2,000 points
per series for line/area/scatter, ≤ 500 categories for column/bar, pie "Other" grouping beyond 50
slices, table charts ≤ 200 rows); the snapshot is ≤ 512 KB compressed (larger → error
`chart_too_large`: "This chart has too much data to place in a presentation. Reduce its range in
Sheets."). Snapshot bytes count toward the deck's content size for the storage quota (Drive D3).

### 3.5 Effective spec and theme

The rendered spec is computed by `SlideChartSpec.effective(sourceSpec, dataJson, deckTheme)`:

1. Start from the snapshot's source spec.
2. If `style.useDeckTheme`: palette ← deck theme accents 1–6 (+ the 60 %/40 % tints, Sheets 08
   §6.4); font family ← deck body font; title font ← deck heading font; automatic text and line
   colors resolve against the **slide background** (dark masters get light text); chart
   background ← transparent. Explicit series colors from the sheet are replaced by palette
   positions (deck look), unless an override sets them.
3. Else (keep source style): the sheet's palette/fonts (`sourceTheme`); automatic colors still
   resolve against the slide background so the chart is readable on dark slides; chart
   background as in the sheet (white by default) unless `background` says otherwise.
4. Apply `style.palette`/`style.font` when set, then `overrides` (merge patch), then `camera`
   (into `threeD.azimuth/elevation/perspective`).
5. Validate with `ChartSpecSchema` (invalid overrides are dropped with a warning in the
   inspector).

`ChartThemeSource` for layout: deck accents/fonts (`useDeckTheme`) or `sourceTheme`
(otherwise); `ChartUiTokens` derived from the slide background luminance, not from the app theme
(slides are content, the app theme never changes them).

---

## 4. Insert flow

Entry points: *Insert › Chart › From Wonky Sheets…* (`slides.insert.chartFromSheets`, 04 §4.4), the insert
palette ("chart"), a chart placeholder's "Insert chart" button, and P1 paste (§4.4).

### 4.1 Step 1 — pick a spreadsheet

The shell's Drive picker dialog (`DrivePickerDialog`, from the Drive spec) filtered to
`kind = spreadsheet`: tabs *Recent*, *My files*, *Shared with me*, *Starred*, search field;
rows show title, owner, modified date. Only spreadsheets the user can view **and** export from
(role ≥ editor, or `nonEditorsCanExport` on) are selectable; others are shown disabled with the
tooltip "The owner doesn't allow viewers to copy charts from this spreadsheet". *Next*.

### 4.2 Step 2 — pick a chart

```
┌ Insert chart from "Finance 2026" ─────────────────────────────── ✕ ┐
│ ← Back                                         Search charts [   ] │
│ Q3 ─────────────────────────────────────────────────────────────── │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                             │
│  │ ▇▅▇▃     │ │  ◔       │ │ ▟▙ 3D    │                             │
│  │ Revenue  │ │ Mix      │ │ Units 3D │                             │
│  └──────────┘ └──────────┘ └──────────┘                             │
│ Pipeline ───────────────────────────────────────────────────────── │
│  ┌──────────┐                                                       │
│  │ ⟋⟋       │                                                       │
│  └──────────┘                                                       │
│ ☑ Link to spreadsheet   ☑ Match presentation theme                 │
│                                         [ Cancel ]  [ Insert ]     │
└────────────────────────────────────────────────────────────────────┘
```

- Data: `slidesCharts.listCharts(spreadsheetUuid)` (§13) returns, per chart: id, title, type,
  sheet name, 3D flag, and a **preview snapshot** (spec + data downsampled to 200 points). The
  dialog renders previews client-side with `ChartView` at 200 × 124 px (deck theme applied when
  *Match presentation theme* is checked, so the user sees the result). Charts on chart sheets
  are listed under their sheet name with a "chart sheet" badge.
- States: loading (skeleton tiles), empty ("This spreadsheet has no charts. Create one in
  Wonky Sheets." + *Open in Sheets*), error (`noAccess`, `notFound`, `offline` — §6), newer spec
  version (tile shows "Needs a newer version" and is disabled).
- Selecting a tile (click/Enter; multiple with Mod-click → inserted as several elements laid out
  in a grid) and *Insert* calls `slidesCharts.resolveSnapshot` for each chart, then
  `slides.chart.insertLinked` (one undo step "Insert chart").
- Placement: into the selected chart/content placeholder (fit inside, keep the chart's aspect
  ratio from its Sheets anchor size), else centered at 70 % of the slide width.
- *Link to spreadsheet* off → `source: static` (no `ChartLink`). *Match presentation theme* →
  `style.useDeckTheme`.

### 4.3 Errors during insert

| Code | Message |
|------|---------|
| `offline` | "You're offline. Connect to insert charts from Sheets." (menu item disabled offline with this tooltip) |
| `no_access` | "You don't have access to this spreadsheet anymore." |
| `export_disabled` | "The owner doesn't allow viewers to copy charts from this spreadsheet." |
| `chart_not_found` | "This chart was deleted. Pick another one." |
| `chart_too_large` | §3.4 |
| `unsupported_spec` | "This chart was made with a newer version of Wonky Sheets. Reload to insert it." |
| `quota_exceeded` | Storage quota dialog (Drive D3) |

### 4.4 Paste from Sheets (P1)

Copying a chart in Sheets (`sheets.object.copy`) also writes a
`web application/x-wonky-chart` clipboard item (and a `data-wonky-chart` attribute in the HTML
flavor as fallback) with `{spreadsheetUuid, chartObjectId}`. Pasting it in Slides runs the
insert with *Link* and *Match theme* on (resolving the snapshot from the server); a paste chip
offers *Keep source formatting* and *Paste unlinked*. Desktop apps use the same payload through
`super_clipboard` custom formats.

---

## 5. Updates

### 5.1 Version token

`sourceVersion = "<revision>:<specHash>:<dataVersion>"`:
- `revision` — `r<headRevision>`, the head revision of the spreadsheet's RevLog file when
  resolved ([17](../17-revlog-sync.md) part 2 §1; the cheap "anything changed?" check). Every
  committed change of the spreadsheet raises it — client edits, offline edits sent late and server
  writes alike — so nothing bypasses the comparison; empty when the file doesn't exist;
- `specHash` — SHA-256 (first 16 hex) of the chart's `specJson` (canonical JSON);
- `dataVersion` — `ChartData.dataVersion` (hash of all source values, Sheets 08 §4).

The first part is `ChartSourceVersion.changeLog` in code (`wonky_charts`); tokens stored with an
older marker simply compare unequal once and are refreshed by the next resolve.

### 5.2 Checking (server, `slidesCharts.checkLinks`)

For each link probe `{elementId, spreadsheetUuid, chartObjectId, sourceVersion}`:
1. Access check for the **caller** (role on the spreadsheet; trashed/deleted state). → `noAccess`,
   `spreadsheetTrashed`, `spreadsheetDeleted`.
2. If the spreadsheet's head revision equals the token's `revision` → `upToDate` (no workbook
   load).
3. Else open the spreadsheet's headless model (`HeadlessWorkbookProvider.open`, a lease on the
   shared `HeadlessFileCache`, [17](../17-revlog-sync.md) part 5 §9), find the object →
   `chartDeleted` if missing; compute `specHash` and resolve data (`dataVersion`) → `upToDate`
   (both equal; the response carries the new token so the client can store the newer
   `revision` silently, see below) or `changed` (with the new token and a short summary:
   "Data changed", "Chart style changed", "Data and style changed").
4. Batched: ≤ 50 probes per call, grouped by spreadsheet; ≤ 2 s typical; per-user rate limit 30
   calls/min.
5. The server caches the current token per `(spreadsheetItemUuid, chartObjectId)` in
   `ChartLinkSourceState` (02 §8), keyed by the spreadsheet's head revision, so many decks
   linking the same chart share one resolve.

When the result is `upToDate` with a newer `revision`, editors write the new token without an
undo step (maintenance write, so later checks stay cheap); viewers just cache it locally.

### 5.3 When clients check

- On opening the deck (editor and viewer), for all linked charts of the deck (batched).
- When the deck window regains focus/visibility after ≥ 60 s.
- Every 5 minutes while the deck is open and online.
- P1: **push** — `slidesCharts.watch(deckUuid)` stream: the server subscribes to the
  `rev:<fileUuid>` bus channels ([17](../17-revlog-sync.md) part 5 §5) of the deck's linked
  spreadsheets and sends `linkChanged {spreadsheetUuid}` (debounced 5 s); the client then
  re-checks those links.
- Presenting: the check runs once at start; updates are never applied during a presentation
  (no surprises on stage); a toast after the presentation offers "2 charts have newer data —
  Update".

### 5.4 UI

- **Linked badge**: in the editor, a linked chart shows (on hover and when selected) a small
  chip at its top-left: `sheet` product glyph + "Linked". When `changed`, the chip becomes an
  **Update** button (primary, `refresh-cw` icon) — Google Slides style — with a tooltip
  "Finance 2026 › Revenue by region changed (data). Update to show the latest version."
- Element ⋮ / context menu: *Update* (`slides.chart.update`), *Update automatically* (check),
  *Open source in Sheets*, *Unlink*, *Change linked chart…* (relink, §7), *Restyle: Match theme
  / Keep source style*.
- **Linked objects** panel (`slides.panel.linkedObjects`, *Tools › Linked objects*): every linked
  chart of the deck grouped by spreadsheet, with status (Up to date / Changed / No access / Source
  deleted), slide number (click → go to slide and select), *Update*, and *Update all* (one undo
  step). Badge with the number of changed links on the panel's rail icon.
- Viewers/commenters see no badge or button; the snapshot is all they see.

### 5.5 Update and auto-update

- **Update** (`slides.chart.update {elementIds}`): the client calls
  `slidesCharts.resolveSnapshot` and writes `ChartLink.sourceSpecJson`, `dataSnapshotJson`,
  `sourceVersion`, `updatedAt`, `updatedBy` — one undo step "Update chart" (undo restores the previous
  snapshot; the chart then shows *Update* again). Overrides, builds, camera and the element frame
  are kept. Series that disappeared lose their builds' parts silently; new series appear in
  `series`-delivery builds as additional parts.
- **Update automatically** (`autoUpdate = true`): any **editor** client with the deck open that
  sees `changed` applies the update itself as a maintenance write (no undo step, attributed to
  that user, presence toast "Charts updated from Finance 2026" for 3 s). Two editors applying
  the same update write identical values (LWW-safe). Viewers render the stored snapshot.

**Decided (v2 review, Q28) — server-side auto-update.** Auto-update is **client-side in M10**
(simple, no background writes into other users' decks); MCP `slides.export_pdf` gets
`refresh_linked_charts: true` to update right before export (editor role required). Client-side
updates leave decks that nobody opens stale (e.g. exported via MCP); if usage shows that, M11
adds the server-side variant: a reverse index `ChartLinkIndex(spreadsheetUuid → deckUuid,
elementId)` maintained from deck ops and a debounced job that updates `autoUpdate` snapshots
after spreadsheet changes, writing into the deck as a server change attributed to the deck owner.

---

## 6. Permission and availability cases

| Case | Viewer of the deck | Editor of the deck |
|------|--------------------|--------------------|
| Has access to the spreadsheet | Snapshot; no badge | Badge; Update when changed |
| No access to the spreadsheet | Snapshot (data is part of the deck, like Google Slides) | Badge "Linked · no access"; *Update* disabled: "You need access to 'Finance 2026' to update this chart." with *Request access* (suite 06 request flow) |
| Spreadsheet export disabled for viewers and the user is a viewer of it | Snapshot | Same as "no access" with the export message |
| Chart deleted in Sheets | Snapshot | Badge "Source chart deleted"; actions *Unlink* (keep as static), *Change linked chart…* |
| Spreadsheet in trash | Snapshot | Badge "Source in trash"; *Open in Drive*; updates resume when restored |
| Spreadsheet deleted forever | Snapshot | Badge "Source deleted"; *Unlink* |
| Spreadsheet moved/renamed | Unaffected (uuid link); the source title refreshes on the next update | Same |
| Chart moved to another sheet / to a chart sheet | Unaffected (object id) | Same |
| Offline | Snapshot | Badge shows last known status; *Update* disabled: "You're offline" |
| Deck copied (*Make a copy*) / template | Links are copied (still linked) | Same |
| Deck published / public link | Snapshot only; no server calls for chart data | — |
| Newer chart spec version in the sheet | Snapshot | Update fails with `unsupported_spec` |

Server enforcement: `resolveSnapshot`/`listCharts` require role ≥ viewer on the spreadsheet and
(role ≥ editor or `nonEditorsCanExport`); `checkLinks` returns only status codes for
spreadsheets the caller cannot read (never data or titles). The deck's snapshot is readable by
anyone who can read the deck — inserting a linked chart is an explicit export of that data into
the deck, so the insert dialog says "Anyone with access to this presentation will see this
chart's data."

---

## 7. Unlink, relink, convert

| Command | Effect |
|---------|--------|
| `slides.chart.unlink` | Linked → `static`: the snapshot moves into `dataJson.snapshot`, the `ChartLink` row is deleted. One undo step ("Unlink chart"). (`static`, not `native`: native charts (P1) have small editable tables that linked data may exceed; *Convert to native* is a separate, P1 step.) |
| `slides.chart.relink` | *Change linked chart…*: the insert dialog opens at step 2 (current spreadsheet) or step 1; the chosen chart replaces the link and snapshot; overrides whose keys don't apply to the new type are dropped (warning). |
| `slides.chart.convertToNative` (P1) | Static/linked → `native`: the snapshot's `ChartData` becomes a `ChartTable` (§11), the source spec becomes the native spec (style merged), the link is removed. Refused with a message when the data exceeds native limits (50 × 12). |
| `slides.chart.openSource` | Same-tab navigation to `/sheets/s/<uuid>?object=<chartObjectId>` (Sheets selects the chart and opens its editor; **addition to the Sheets routes**, Sheets 04 / suite 03). Viewer+ with spreadsheet access. |

---

## 8. Editing style in Slides

### 8.1 Inspector › Chart section

```
┌ Chart ───────────────────────────────────────────────┐
│ ⧉ Finance 2026 › Q3 › Revenue by region   [Open ↗]    │
│ Linked · Up to date (2 min ago)      [ Update ] ☐ Auto │
│ Style  ( Match theme | Keep source )                   │
│ Background [ Transparent ▾ ]                           │
├ Customize (ChartStyleEditor) ─────────────────────────┤
│ ▸ Chart & axis titles   ▸ Series   ▸ Legend            │
│ ▸ Horizontal axis   ▸ Vertical axis   ▸ Gridlines       │
│ ▸ 3D (camera, lighting, walls)                         │
│ [ Reset overrides ]                                     │
└───────────────────────────────────────────────────────┘
```

The Customize sections are `wonky_charts_flutter`'s `ChartStyleEditor` (shared with Sheets) in
**override mode**: only allowlisted fields are editable; edited fields show a dot and a per-field
reset; *Reset overrides* clears `overrides`. Each edit is `slides.chart.updateStyle {elementId,
patch, coalesceKey}`.

### 8.2 Override allowlist

| Allowed (presentation) | Not allowed in Slides (edit in Sheets) |
|------------------------|----------------------------------------|
| `title`, `subtitle` (text, visibility, font) | `data.*` (ranges, headers, switch rows/columns, aggregate, series refs) |
| `legend` (position, font, alignment) | `type` and `stacking` (P1: switching between compatible types column ↔ bar ↔ line ↔ area as an override) |
| `axes.*.title`, `axes.*.labels` (font, slant), `axes.*.showLine`, `axes.*.numberFormat` | `axes.*.min/max/logScale/reverse` (changes the meaning; P2) |
| `gridlines.*` visibility and colors | `typeOptions` that change data (histogram buckets, waterfall subtotals) |
| `series.<key>.color`, `lineWidth`, `pointSize`, `pointShape`, `dataLabels`, `labelOverride` | `series.<key>.type/axis` |
| `style.background`, `style.fontFamily`, `style.border`, `style.maximize`, `style.palette` | trendlines (P2: show/hide only) |
| `threeD.lighting/wallsVisible/floorColor/depth/gapDepth/shape/explode` (the camera is `dataJson.camera`) | `threeD.enabled` (P1 as override) |
| pie `typeOptions.pieHole`, `sliceLabel`, `startAngle`, `slices.*.offset/color` | |

Overrides survive updates; an override whose target no longer exists (deleted series) is
ignored (kept in JSON, shown as "unused" in the inspector with *Clean up*).

---

## 9. Chart builds and data animation

### 9.1 Reveal model

`ChartRevealState` (06 §9.2) maps scene parts to progress: `background` (all primitives with
roles `background, plotArea, title, subtitle, axis*, gridline, tick, legend*, baseline`) and data
parts keyed by `(seriesKey?, pointIndex?)`. Each renderer (Flutter painter, PDF, SVG, raster)
applies it:

| Chart type | `chartGrow` (part progress p) | Fade-based effects |
|------------|-------------------------------|--------------------|
| column/bar (2D) | Rect grows from the baseline (value axis) to its value: height × p | Opacity per part |
| stacked column/bar | Segments grow in stack order | |
| line/area | Polyline/area drawn from the first to the last point (clip by x = p of the series' extent; markers pop in as the line reaches them) | |
| pie/doughnut | Wedge sweep from its start angle, sweep × p; labels fade in at p > 0.8 | |
| scatter/bubble | Markers scale 0 → 1 (spring) | |
| radar | Polygon scales from the center | |
| waterfall/candlestick | Bars grow from their start value | |
| table/scorecard | Rows/value fade in (scorecard: number counts up from 0 to the value, formatted each frame) | |
| 3D (all) | `Chart3DModel.lerp(collapsed, full, p)`: boxes rise from the floor, wedges extrude, ribbons sweep | |

Data labels of a part appear in the last 20 % of its progress.

### 9.2 Delivery

Charts use `series`, `category`, `point`, `chartElement` deliveries (06 §2.3) with
`includeBackground`. Default for `chartGrow`: `series` with `partTrigger: afterPrevious`, stagger
150 ms. Part order uses the snapshot's series order (legend order) and domain order.

### 9.3 Emphasis

`chartHighlight` dims all other series/points to `dimOthers` (renders through the legend
highlight path of the layout, `ChartLayoutOptions.highlight`), persistent until
`chartHighlightClear` or another highlight. 3D: other items fade toward the background (Sheets
08 §23.2).

### 9.4 Morphs (Magic Move and updates)

`ChartSceneMorph` matches the primitives of two 2D scenes by `SceneTag` (role + series key +
point index + detail): rects, arcs and paths interpolate geometry, colors interpolate in OKLab,
texts crossfade, unmatched primitives fade. Used by Magic Move between two chart elements with
the same `matchKey` (same or different data/spec — e.g. slide 1 shows 2025, slide 2 the same
chart with an extra series) and by the editor when an update is applied (450 ms, like Sheets 3D
data animations; off with reduced motion). Different chart types morph only where tags match
(column → line morphs poorly and falls back to crossfade when < 50 % of data primitives match).

---

## 10. 3D charts in Slides

### 10.1 Rendering

- 3D charts render with `wonky_charts_flutter`'s `flutter_scene` GPU backend (Flutter GPU on
  desktop, Flutter Scene's WebGL2 backend on web — Sheets 08 §23.7), started lazily by
  `Chart3DBackends.ensureStarted()` the first time a deck shows a 3D chart (and prefetched when
  the next slide in a presentation has one, 06 §14). Labels are Flutter text painted on top with
  the same camera mapping.
- Fallback to the core software backend when the GPU backend is unavailable or a frame fails;
  thumbnails, the navigator, PDF and PNG exports always use the software backend (vector in PDF).
- The deck theme lighting preset: `threeD.lighting` from the source spec; the floor and walls take
  the deck's neutral colors in `deck` style mode.

### 10.2 Camera presets

Inspector › Chart › 3D offers presets (writing `dataJson.camera`)
plus the Sheets sliders (Rotation, Tilt, Perspective) and orbit-by-drag on the selected chart
(one undo step per drag, as in Sheets 08 §23.6):

| Preset | Azimuth | Elevation | Perspective (FOV°) |
|--------|---------|-----------|--------------------|
| Default | 20 | 20 | 15 |
| Front | 0 | 8 | 10 |
| Isometric | 45 | 35.264 | 0 |
| Top-down | 0 | 85 | 0 |
| Low angle | 25 | 5 | 30 |
| Side | 80 | 15 | 15 |
| Dramatic | 35 | 25 | 45 |

Pie charts use their own defaults (azimuth 0, elevation 40) and presets *Flat* (elevation 85),
*Tilted* (40), *Steep* (60).

### 10.3 Animatable camera

- **`chartCamera`** emphasis (06 §3.3): animate to absolute angles or a preset; persistent.
  Interpolation: `Chart3DView.lerp` — azimuth along the shortest arc (unless the build sets
  `params.direction: cw|ccw` and `turns`), elevation and FOV linearly, with the build's easing.
- **`chartOrbit`** emphasis: relative rotation (`azimuth: 360` = one full turn), optional
  elevation sway; `persist: false` returns to the start angle at the end (for a turntable effect
  use `repeat.untilNextClick`, P1 "continuous orbit while the slide is shown").
- **Magic Move between angles**: the same chart (same `matchKey`, typically a duplicated slide
  with a different camera) morphs camera and model (`Chart3DModel.lerp` for data/style
  differences).
- Layout during camera animation: the 3D scene is re-fitted per frame (`Chart3DScene` fit into
  the plot rect) with the fit computed once for the union of start and end views (no zoom pumping).
- Reduced motion: camera changes jump (200 ms crossfade); orbit is skipped.

### 10.4 Performance

GPU backend: ≤ 4 ms per frame for ≤ 2,000 3D items at 1080p (desktop), ≤ 8 ms web. Software
fallback during animation: shadows are dropped while the camera moves (restored on settle) and
items beyond 600 render without gradients — keeps ≤ 12 ms per frame on the reference machine.
Meshes are rebuilt only when the model changes (`meshHash`), not when the camera moves.

### 10.5 Interaction in present/view mode

`dataJson.interactive.hoverTooltips` (default off) shows tooltips on hover in present mode and
the viewer; `orbitInPresent` (default off) lets the presenter drag to orbit a 3D chart (local,
not saved; reset when leaving the slide). Followers of a presentation session see the
presenter's live camera (sent as part of the session state, 10 §6, P1).

---

## 11. Native charts (P1)

*Insert › Chart ▸ Column / Bar / Line / Area / Pie / Doughnut / Scatter / 3D column / 3D pie /
More…* creates a `native` chart with sample data and opens the **data editor**:

- A side panel `slides.panel.chartData` with a compact grid (`two_dimensional_scrollables` is
  not needed: max 50 rows × 12 columns, a simple custom grid in `wonky_slides`): first row =
  series names, first column = categories; per-column type/format (Number, Percent, Currency
  (symbol), Date — `wonky_numfmt` patterns); paste TSV/CSV from the clipboard (replaces from the
  active cell); keyboard like a mini spreadsheet (arrows, Enter, Tab, Delete); no formulas.
- The chart type picker (shared `ChartTypePicker` icons) and the full `ChartStyleEditor`
  (all fields, not only the allowlist) edit `dataJson.spec`.
- Recommendations: `ChartRecommender.recommendForTable` (wonky_charts) suggests types for pasted
  data.
- `ChartTable` JSON: `{"v":1, "columns": [{"name","format"}], "categories": [...], "rows":
  [[number|null,…]], "categoryKind": "text|number|date"}`; `TableChartData.fromTable` produces
  `ChartData` (series keys = stable column ids `c1…c12`, so styles survive column renames).
- Undo: each cell edit / paste is one step ("Edit chart data"); typing coalesces per cell.

---

## 12. PDF and image rendering

- Charts in the Slides PDF ([10](10-presenting-and-pdf.md) §11) are drawn as **vector** graphics
  by `wonky_charts`' `PdfChartRenderer` into the page's `PdfGraphics` (no separate page): the
  chart scene is laid out at the element's frame size in su and drawn through the page's su → pt
  transform (10 §11.3), with a `TtfTextMeasurer` for the deck's embedded font (so labels are
  measured with the font they are drawn in) — no Helvetica fallback for deck fonts.
- 3D charts use the software backend (gradients as PDF axial shadings, Sheets 08 §23.5).
- Builds as pages: the chart reveal state of each step (`ChartRevealState`) is applied; the
  print frame shows the fully built chart.
- PNG export (P1) renders via the stage (GPU backend allowed on the client); server raster uses
  `RasterChartRenderer`.
- Alt text and auto description (Sheets 08 §14) are emitted into the PDF as the image
  alternative text when tagged PDF lands (P2).

---

## 13. Server endpoints (`SlidesChartsEndpoint`, `slidesCharts`)

Location: `wonky_server/lib/src/slides/charts/` (service `SlidesChartService`; uses
`HeadlessWorkbookCache` and `SheetsChartPipeline` from the Sheets server modules — server code may
use both cores).

| Method | Description |
|--------|-------------|
| `listCharts(spreadsheetUuid) → ChartSourceList {spreadsheetTitle, charts: [ChartSourceSummary {chartObjectId, title, type, is3D, sheetName, onChartSheet, previewSnapshotJson}], exportAllowed}` | For the insert dialog (§4.2). Preview snapshots are downsampled to ≤ 200 points. |
| `resolveSnapshot(spreadsheetUuid, chartObjectId) → ChartSnapshotView {sourceSpecJson, dataSnapshotJson, sourceVersion, updatedAt, warnings}` | Full snapshot (§3.3–§3.4). |
| `checkLinks(List<ChartLinkProbe>) → List<ChartLinkStatus {elementId, status: upToDate\|changed\|noAccess\|exportDisabled\|chartDeleted\|spreadsheetTrashed\|spreadsheetDeleted\|unsupportedSpec, newVersion?, summary?}>` | §5.2. |
| `watch(deckUuid) → Stream<ChartLinkEvent {spreadsheetUuid}>` (P1) | §5.3 push. Requires role ≥ viewer on the deck. |

- Access: §6. Every call logs nothing of the data; errors map to the codes of §4.3.
- Caching: resolved snapshots cached per `(chartObjectId, sourceVersion)` for 10 min (in-memory
  per instance, invalidated by the workbook watermark).
- Limits: `listCharts` ≤ 100 charts; `resolveSnapshot` ≤ 10 s (workbook load included); 60
  resolves/min per user.
- MCP uses the same service ([11](11-mcp-and-ai.md): `slides.list_sheet_charts`,
  `slides.insert_linked_chart`, `slides.refresh_linked_charts`).

*As built (SL-27):* `wonky_server/lib/src/slides/charts/` — `SlidesChartsEndpoint` (class name
gives the `slidesCharts` client name) over `SlidesChartService`; models `ChartSourceList`,
`ChartSourceSummary` (+ `unsupported`), `ChartSnapshotView` (+ `spreadsheetUuid`,
`chartObjectId`, `sheetId`; plain JSON columns — the client stores them with `gz:`),
`ChartLinkProbe`, `ChartLinkStatus`, `ChartLinkState` (no table, no migration). Errors are
`WonkyException`s with `detailsJson {"reason"}` = the §4.3 codes: `no_access` / `spreadsheet_trashed`
/ `chart_not_found` (notFound), `export_disabled` (forbidden), `unsupported_spec`
(invalidArgument), `chart_too_large` (tooLarge); rate limits (60 resolves, 30 checks, 30 lists
per minute and user) give `limitExceeded`. `listCharts` is viewer+: without the right to copy
data the charts are listed **without previews** and `exportAllowed: false` (titles are visible
to viewers anyway). `checkLinks` checks the role before the trash state, so callers without
access learn nothing but `noAccess`; a missing item is `spreadsheetDeleted`. The token cache
(`ChartLinkSourceState` of §5.2) is in memory per instance, keyed by the spreadsheet's head
revision (`r<headRevision>` read from `rev_file`; no bus subscription needed); resolved
snapshots are cached 10 min per token.
`watch` (P1) is not built.

---

## 14. Commands

`requiredRole` editor unless noted; undoable = one `slides.rows` step.

| Command id | Args | Undoable | Notes |
|------------|------|----------|-------|
| `slides.insert.chartFromSheets` | `{spreadsheetUuid?, chartObjectIds?, link?: bool, useDeckTheme?: bool, frame?}` | ✓ (insert) | Id from 04 §4.4. Without ids opens the dialog. Disabled offline. |
| `slides.chart.insertLinked` | `{snapshots: [{spreadsheetUuid, chartObjectId, sourceSpecJson, dataSnapshotJson, sourceVersion}], link, useDeckTheme, frame?}` | ✓ | Internal (dialog result, MCP bridge). |
| `slides.chart.update` | `{elementIds?}` (default: selected; `all: true` = every changed link) | ✓ | "Update chart(s)". |
| `slides.chart.setAutoUpdate` | `{elementIds?, autoUpdate}` | ✓ | |
| `slides.chart.unlink` | `{elementIds?}` | ✓ | |
| `slides.chart.relink` | `{elementId, spreadsheetUuid?, chartObjectId?}` | ✓ | Without target opens the dialog. |
| `slides.chart.openSource` | `{elementId?}` | — | Viewer+ (with sheet access). |
| `slides.chart.setUseDeckTheme` | `{elementIds?, useDeckTheme: bool}` | ✓ | |
| `slides.chart.updateStyle` | `{elementId, patch: JsonMergePatch (overrides), coalesceKey?}` | ✓ | Allowlist enforced (§8.2); native: full spec. |
| `slides.chart.resetOverrides` | `{elementIds?}` | ✓ | |
| `slides.chart.setCamera` | `{elementId, azimuth?, elevation?, perspective?, preset?}` | ✓ | Coalesces within 1 s (drag/keys). `Alt+Shift+arrows` rotate 5° like Sheets. |
| `slides.chart.viewDataTable` | `{elementId?}` | — | Viewer+ (snapshot data). |
| `slides.chart.checkUpdates` | — | — | Re-runs §5.2 now. Viewer+. |
| `slides.panel.linkedObjects` | — | — | Viewer+ (read-only for viewers). |
| `slides.insert.chart` (P1) | `{type, table?, spec?, frame?}` | ✓ | Native chart; id from 04 §4.4. |
| `slides.chart.editData` (P1) | `{elementId?}` | — | Opens the data panel. |
| `slides.chart.setData` (P1) | `{elementId, table: ChartTable}` | ✓ | MCP and paste. |
| `slides.chart.convertToNative` (P1) | `{elementId}` | ✓ | |

---

## 15. Undo and concurrency

| Operation | Rows | Label |
|-----------|------|-------|
| Insert linked chart | `SlideElement` + `ChartLink` | "Insert chart" |
| Update / Update all | `ChartLink` snapshot columns | "Update chart" |
| Auto-update, token refresh | `ChartLink` (maintenance, no undo step) | — |
| Style override / camera | `SlideElement.dataJson` (`style`, `overrides`, `camera`) | "Edit chart style" / "Rotate chart" |
| Unlink / relink / convert | `SlideElement` kind JSON, `ChartLink` delete/insert | "Unlink chart" … |

Concurrency: `dataJson` is one column (read-modify-write patches on the latest local value; LWW
for concurrent offline edits, as Sheets 08 §15.2). A concurrent *Update* (A) and style override
(B) both survive (different rows). Two concurrent updates write equal or newer snapshots; the
later `updatedAt` wins (LWW on the row's columns — the stale writer's undo becomes a no-op).
Unlink (A) ∥ update (B): if the `ChartLink` row is deleted first, B's update writes to a tombstone
and is discarded; the static snapshot from A stays.

---

## 16. Offline

- Linked, static and native charts render fully offline (snapshot in the synced deck).
- Insert from Sheets, Update, relink and *Open source* are disabled offline (tooltip "You're
  offline"); status badges show the last known status with "(offline)".
- The 3D GPU backend works offline (shaders are bundled assets).

---

## 17. Accessibility

- Alt text: the element's alt text (03) defaults to the auto description from `ChartDescriber`
  ("Column chart: Revenue by region. 3 series: …"), regenerated when the snapshot updates unless
  the author edited it; *Generate with AI* reuses Sheets' chart description prompt on the snapshot
  ([11](11-mcp-and-ai.md)).
- *View data as table* (`slides.chart.viewDataTable`) shows the snapshot data (`ChartDataTableDialog`)
  in the editor, the viewer and — for screen-reader users — as a semantics action in present mode.
- Linked badge and Update button are keyboard reachable when the chart is selected (Tab into the
  element's chrome, Enter activates).

---

## 18. Performance

| Item | Budget |
|------|--------|
| Snapshot decode + layout of a 2,000-point line chart | ≤ 10 ms |
| Chart paint per frame during `chartGrow` (2D, ≤ 500 parts) | ≤ 3 ms (scene laid out once; reveal applied at paint) |
| Insert dialog: chart list with previews (≤ 30 charts) | first tiles ≤ 1.5 s after picking the spreadsheet (server resolve dominates) |
| `checkLinks` for 20 links in 3 spreadsheets, nothing changed | ≤ 150 ms server time (head-revision comparison only) |

---

## 19. Acceptance criteria

1. After the extraction, all Sheets chart tests and goldens pass unchanged; `wonky_charts` has
   no Flutter dependency (dependency check) and Slides imports no Sheets package.
2. Inserting "Revenue by region" from a spreadsheet shows the same chart (deck theme applied) in
   the editor, present mode, the client PDF and the server PDF; with *Keep source style* it is
   pixel-equivalent to Sheets' chart at the same size (< 1 % diff).
3. Editing a source cell in Sheets makes the Slides editor show *Update* within 5 minutes
   (immediately after focus/refresh; < 10 s with P1 push); *Update* refreshes the data in one undo
   step and keeps overrides, builds and camera.
4. A deck viewer without access to the spreadsheet sees the chart (snapshot) and no badge; an
   editor without access sees *Update* disabled with *Request access*.
5. Deleting the chart in Sheets shows "Source chart deleted" with *Unlink*; unlink keeps the chart
   visible as static.
6. A deck with linked and 3D charts opens and presents offline with charts visible.
7. A `chartGrow` build by series on a column chart grows each series' bars from the baseline one
   after the other; PDF builds-as-pages shows one page per series stage.
8. A 3D column chart with a `chartCamera` build rotates smoothly to the *Isometric* preset at 60
   fps (GPU backend) and Magic Move between two slides with different angles interpolates the
   camera along the shortest arc.
9. With the GPU backend unavailable (forced), the same deck renders 3D charts via the software
   backend in editor and present mode.
10. All commands in §14 pass execute → undo → redo; style overrides outside the allowlist are
    rejected with `invalid_args` (MCP) / not editable (UI).
11. (P1) A native column chart created from pasted TSV data renders, edits, undoes and exports.

## 20. Tests

- `wonky_numfmt`, `wonky_charts`: moved Sheets tests (spec, layout, scene goldens, renderers,
  3D); new: `ChartData` JSON round-trip (exact doubles, NaN gaps), `ChartSnapshot`, opaque range
  refs, `ChartThemeSource`, `ChartRevealState` in every renderer (scene JSON + raster goldens),
  `ChartSceneMorph`, `Chart3DView.lerp` (shortest arc across 0/360), `TtfTextMeasurer` vs PDF
  output widths.
- `wonky_charts_flutter`: painter goldens (moved), `ChartStyleEditor` in override mode
  (allowlist, reset), orbit gesture.
- Server: `slidesCharts` endpoint tests with `serverpod_test` (access matrix of §6, export
  disabled, deleted/trashed, unchanged vs changed detection after a committed Sheets op, rate
  limits, snapshot size limit, downsampling).
- Slides: insert dialog flow (fake API), badge/Update states, update undo, unlink/relink,
  inspector overrides, 3D presets and camera builds, offline disabled states; E2E: insert from a
  real spreadsheet in the test server, edit the sheet via MCP, Update in Slides.

---

## 21. Additions to 02-data-model

| # | Change | Reason |
|---|--------|--------|
| A-08-1 | Chart `dataJson` (02 §6.8) gains: `source` value `static`; `overrides` (allowlisted merge patch, §8.2); `snapshot` (static: `{sourceSpec, dataSnapshot}`); `background`; `interactive {hoverTooltips, orbitInPresent}`. `data` (native) is the §11 `ChartTable`. Unlink produces `static`, not `native` (§7). | §3.2 |
| A-08-2 | `ChartLink` (02 §3.9) gains `sheetId: String?`; `sourceSpecJson`/`dataSnapshotJson` use the `gz:` prefix for gzip+base64 when > 32 KB and are always written together; `dataSnapshotJson` schema §3.4; `sourceVersion` format §5.1. | §3.3, §3.4, §5.1 |
| A-08-3 | `ChartSnapshot` JSON schema (§3.4) and `ChartTable` JSON (§11); limits: snapshot ≤ 512 KB compressed, native table ≤ 50 × 12. | §3.4, §11 |
| A-08-4 | Maintenance writes (no undo step): `ChartLink.sourceVersion` token refresh and auto-updates by editor clients. | §5.2, §5.5 |
| A-08-5 | Snapshot bytes count toward the deck's content size (storage quota, Drive). | §3.4 |
| A-08-6 | Server: `SlidesChartEndpoint` (§13); P2/M11 option `ChartLinkIndex` (server-only table `spreadsheetUuid, deckUuid, elementId`) for server-side auto-update. | §5.5, §13 |
| A-08-7 | Sheets route param `?object=<objectId>` on `/sheets/s/:uuid` (select + open chart editor) — Sheets 04 / suite 03 addition. | §7 |
| A-08-8 | Suite 01 §2.1: packages `wonky_numfmt`, `wonky_charts`, `wonky_charts_flutter` and their dependency lists (§2.8). | §2 |
