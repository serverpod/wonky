# Sheets 08 · Charts, Images and Embedded Objects

This spec covers everything that floats over or replaces the grid: **charts** (all chart
types, the chart spec, data extraction, rendering, the chart editor), **images** (over cells
and in cells), **chart sheets**, **slicer objects** (rendering only), **drawings** (P2), and
the shared **object layer**: selection, move/resize, z-order, clipboard, undo, concurrency.

Read first:
- [02-data-model.md](02-data-model.md): `EmbeddedObject`, `Sheet.kind`, `GridRange`, writes (§7).
- Suite [02-design-system.md](../02-design-system.md): `WonkySplitView`, `WonkyColorPicker`.
- Suite [08-commands-and-undo.md](../08-commands-and-undo.md): commands, undo transactions.
- Related Sheets specs: [03-grid-and-editing.md](03-grid-and-editing.md) (grid layers, selection),
  [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md) (Insert menu, toolbar),
  [05-formula-engine.md](05-formula-engine.md) (`IMAGE()`, `SPARKLINE()`, value types),
  [06-formatting.md](06-formatting.md) (number formats used by axes and labels),
  [07-data-tools.md](07-data-tools.md) (slicer behavior, filters, pivot tables),
  [11-import-export-print.md](11-import-export-print.md) (XLSX chart mapping, PDF output),
  [12-mcp-and-ai.md](12-mcp-and-ai.md) (chart MCP tools).

Priorities: **P0** is required for the first complete release, **P1** should ship in v1, and
**P2** is designed now but built later.

---

## 1. Object model

### 1.1 `EmbeddedObject` recap

One `EmbeddedObject` row per object ([02-data-model.md](02-data-model.md) §3.5). The columns
are merged field by field (LWW per column), which defines the concurrency semantics in §15.

| Column | Meaning in this spec |
|--------|----------------------|
| `sheet` | Sheet that shows the object. For chart sheets this is the `Sheet` row with `kind = chart`. |
| `kind` | `chart`, `image`, `slicer` (+ `drawing` in P2, see §19). |
| `anchorJson` | Position and size (§1.2). Changed by move and resize. |
| `specJson` | Kind-specific content: `ChartSpec` (§3), `ImageSpec` (§10.1), `SlicerSpec` ([07-data-tools.md](07-data-tools.md)). Changed by the chart editor and image options. |
| `zIndex` | Stacking order within the sheet. Higher draws on top. |
| `title` | Object name shown in the object list, in alt-text defaults and in MCP (`"Chart 1"`, `"Image 3"`). It is **not** the chart's visible title; that one lives in `specJson.title`. |
| `altText` | Accessible description (§14). |

### 1.2 Anchor JSON

```jsonc
// Over-grid object
{
  "v": 1,
  "rowId": "5Kq…",        // anchor cell row id (22-char base-62 UUID)
  "colId": "9zA…",        // anchor cell column id
  "dx": 12.0,              // px offset from the anchor cell's top-left, at 100 % zoom, ≥ 0
  "dy": 4.0,
  "width": 600.0,          // px at 100 % zoom, ≥ 20
  "height": 371.0,         // ≥ 20
  "lockAspect": false      // images default true, charts false
}
// Object on a chart sheet (Sheet.kind == chart)
{ "v": 1, "ownSheet": true }
```

Rules:
- `dx` must be smaller than the anchor column's width and `dy` smaller than the anchor row's
  height after **normalization**. Every write normalizes the anchor: the writer picks the cell
  that contains the object's top-left point, and stores the offset inside that cell. Two
  clients that move the same object therefore write comparable anchors.
- Objects **move with their anchor cell** when rows or columns are inserted, deleted above or
  left, resized, or reordered. The size in px does not change when rows or columns are resized
  (Google Sheets behavior).
- Anchor row or column hidden: the object stays visible, positioned at the collapsed edge.
- Anchor row or column **deleted**: the object re-anchors to the next surviving row (by
  `sortKey`, else the previous one) and the same column logic. This is an idempotent
  maintenance step like the pivot rule in [02-data-model.md](02-data-model.md) §8, run by the
  first client that notices. Concurrent fixers write identical anchors because the rule is
  deterministic (`dx`, `dy` are reset to 0). Local row/column deletes re-anchor in the same plan; the app runs
  the core `AnchorMaintenance` (`ObjectsController.runMaintenance`) when a spreadsheet opens and
  after remote structure/object batches, writing the fixes without an undo step (editors only).
- Anchor sheet deleted: the object is deleted by cascade.

### 1.3 Spec envelope

All `specJson` payloads carry `"v": <int>` (schema version). Readers accept older versions and
upgrade them in memory. A writer never downgrades a newer version it can't read: if the local
app knows only `v1` and finds `v2`, the object renders as a placeholder card ("This chart was
created with a newer version of Wonky Sheets — Reload to edit") and editing is disabled.

---

## 2. Chart type catalog

| Type id | Google Sheets name | Prio | Data shape | Variants / options | XLSX (see 11) |
|---------|--------------------|------|------------|--------------------|---------------|
| `column` | Column | P0 | domain + 1..n numeric series | `stacking: none/normal/percent` | `c:barChart barDir=col` |
| `bar` | Bar | P0 | same | stacking | `c:barChart barDir=bar` |
| `line` | Line, Smooth line | P0 | domain + series | `curve: straight/smooth`, `stepped` (P2) | `c:lineChart` (`c:smooth`) |
| `area` | Area, stacked area, 100 % stacked area | P0 | domain + series | stacking, `stepped` (P2) | `c:areaChart` |
| `combo` | Combo | P0 | domain + series; each series picks `column`/`line`/`area` | per-series type, right axis | multiple plot groups |
| `pie` | Pie, Doughnut | P0 | labels + 1 numeric series | `pieHole: 0..0.9` (doughnut when > 0), slice offsets | `c:pieChart` / `c:doughnutChart` |
| `scatter` | Scatter | P0 | numeric X + 1..n numeric Y | point shapes, trendlines | `c:scatterChart` |
| `bubble` | Bubble | P1 | id label, X, Y, color group?, size | size scale | `c:bubbleChart` |
| `histogram` | Histogram | P1 | 1..n numeric columns | bucket size, outlier percentile, item dividers | — (export as column chart of buckets) |
| `candlestick` | Candlestick | P1 | domain + low, open, close, high (+ more groups) | rising/falling colors | `c:stockChart` |
| `waterfall` | Waterfall | P1 | labels + values | subtotals, connector lines, colors | — (export as stacked column) |
| `scorecard` | Scorecard | P1 | key value (+ baseline) | aggregate, compare mode, formats | — (export as image) |
| `table` | Table chart | P1 | any columns | paging, sorting, row numbers, alternating colors | — (export as image) |
| `radar` | Radar | P1 | domain + series | fill opacity | `c:radarChart` |
| `ohlc` | OHLC | P2 | like candlestick | — | `c:stockChart` |
| `gauge` | Gauge | P2 | label + value | min/max, color ranges | — |
| `treemap` | Tree map | P2 | label, parent, size, color | depth, colors | — |
| `org` | Organizational | P2 | node, parent, tooltip | size | — |
| `timeline` | Timeline | P2 | date + series | zoom range | — |
| `geo` | Geo | P2 | region + value | region, colors | — (needs offline map data; P2) |
| 3D column, bar, line, area, pie | (AppleWorks / Excel 3-D) | P1 | as the flat type | `threeD` section, §23 | `c:bar3DChart` / `c:line3DChart` / `c:area3DChart` / `c:pie3DChart` + `c:view3D` |
| Sparkline | `SPARKLINE()` formula | P0 | in-cell | see [05-formula-engine.md](05-formula-engine.md) | Excel sparklines (P2) |

`SPARKLINE()` is not an `EmbeddedObject`. It is a formula whose value is a
`SparklineValue`, painted inside the cell by the grid. It reuses the chart layout primitives
(`ChartScene`, §6.3) with all axes and labels turned off.

---

## 3. Chart spec (`ChartSpec` v1)

Dart model in `wonky_sheets_core/lib/src/charts/spec/` (pure Dart, JSON round-trip via
`toJson`/`fromJson`, value equality, `copyWith`, `patch(Map json)` for MCP updates). Unknown
JSON keys are preserved on round-trip (`extras` map) so newer clients don't lose data
written by future versions.

### 3.1 Top level

```jsonc
{
  "v": 1,
  "type": "column",                     // §2 type id
  "stacking": "none",                   // none | normal | percent  (column, bar, area, combo)
  "data": { … },                        // §3.2
  "style": { … },                       // §3.3
  "title":      { "text": "Revenue by region", "font": {…}, "align": "left" },
  "subtitle":   { "text": "", … },
  "axes": {
    "h":  { … },                        // horizontal axis (§3.5)
    "v":  { … },                        // left vertical axis
    "v2": { … }                         // right vertical axis (only if a series uses it)
  },
  "legend": { "position": "auto", "font": {…}, "alignment": "center" },
  "gridlines": { … },                   // §3.6
  "series": { "<seriesKey>": { … } },   // per-series style overrides (§3.4)
  "typeOptions": { … }                  // type-specific (§3.7)
}
```

### 3.2 Data section

```jsonc
"data": {
  "ranges": [ {"s":"…","r1":"…","r2":"…","c1":"…","c2":"…"} ],   // GridRange list (≥ 1)
  "switchRowsColumns": false,          // series are rows instead of columns
  "headerCount": 1,                    // "Use row 1 as headers" (0..n); null = auto-detect
  "useFirstColumnAsLabels": true,      // first column (row when switched) is the domain
  "treatLabelsAsText": false,          // categorical X even if numbers/dates
  "aggregate": null,                   // null | sum | average | count | max | min | median
  "domain": { "ref": {"range": 0, "offset": 0}, "reverse": false },
  "seriesRefs": [                      // ordered list; order defines draw order and colors
    { "key": "9zA…", "ref": {"range": 0, "offset": 1} },
    { "key": "Hq2…", "ref": {"range": 0, "offset": 2}, "hidden": false }
  ],
  "includeHidden": false,              // include rows/cols hidden by user or filters
  "emptyCells": "gap",                 // gap | zero | connect (line/area/scatter)
  "maxPoints": null                    // override of the downsampling threshold (§12)
}
```

- `ref.offset` is the column (or row, when switched) **index within the range**. Because
  ranges are id-based, the resolver turns them into concrete row/column ids when it resolves
  the range. `key` is the stable **series key**: the source column id (row id when switched).
  Series styles in `spec.series` are keyed by it, so a series keeps its color after columns are
  inserted before it.
- Multiple disjoint ranges (Ctrl-selection when inserting) are allowed. They are concatenated
  side by side (or stacked when switched) and must resolve to the same number of rows. If they
  don't, the shorter ones are padded with empty cells and the editor shows the warning
  "Ranges have different sizes".
- `headerCount = null` means auto-detect (§4.2). Explicit values come from the "Use row N as
  headers" checkbox.
- `aggregate` groups rows by the domain value and applies the function to each series ("Aggregate"
  checkbox under X-axis). Required for pie charts over raw transactional data.

### 3.3 Style section

```jsonc
"style": {
  "background": null,                  // null = automatic (follows app theme in editor, white in exports)
  "fontFamily": null,                  // null = spreadsheet theme font
  "border": null,                      // color or null (none)
  "maximize": false,                   // reduce padding, legend & titles inside plot
  "smooth": false,                     // line/area/combo lines curved (monotone cubic)
  "plotNullValues": false,             // = data.emptyCells "zero" shortcut kept for GS parity
  "compareMode": "datum",              // tooltip: datum | category (show all series at X)
  "palette": null                      // null = theme accents; or ["#hex", …]
}
```

Font object (used by titles, legend, axis labels, data labels):
`{"family": null, "size": null, "bold": false, "italic": false, "color": null}`; `null`
means inherit (chart default: 12 px titles 16 px, color automatic).

### 3.4 Series style

```jsonc
"series": {
  "9zA…": {
    "type": "column",                  // combo only: column | line | area
    "axis": "left",                    // left | right
    "color": "theme:accent1",          // WonkyColor string (hex or theme ref); null = palette
    "fillOpacity": 1.0,
    "lineColor": null, "lineOpacity": 1.0,
    "lineWidth": 2,                    // 0..8 px
    "lineDash": "solid",               // solid | dash | dot | dashDot | longDash
    "pointSize": 0,                    // 0 = none (line) ; scatter default 7
    "pointShape": "circle",            // circle | triangle | square | diamond | star | polygon
    "dataLabels": { "show": false, "position": "auto", "type": "value", "font": {…} },
                                       // position: auto | center | insideEnd | insideBase | outsideEnd | above | below | left | right
                                       // type: value | percent | label (pie) | custom (P2: from range)
    "trendline": null,                 // §7
    "errorBars": null,                 // P2: {type: constant|percent|stdev, value}
    "points": { "3": { "color": "#E53935" } },   // P1 "Format data point" by domain index
    "labelOverride": null              // legend label override (else header text)
  }
}
```

### 3.5 Axis

```jsonc
"h": {
  "title": { "text": "", "font": {…} },
  "showLine": true,
  "labels": { "show": true, "font": {…}, "slant": "auto", "angle": 0 },   // slant: auto | none | custom
  "reverse": false,
  "min": null, "max": null,            // numeric/date axes only; null = auto
  "logScale": false,                   // numeric axes; values ≤ 0 are skipped with a warning
  "numberFormat": null,                // null = from source cells; else pattern ("#,##0.0", "0%")
  "dateGrouping": null                 // P2: year | quarter | month | week | day
}
```

The vertical axes (`v`, `v2`) have the same shape. For `bar` charts the value axis is
horizontal; the editor still names them "Horizontal axis" and "Vertical axis" by screen
position, and the model maps them to `domain`/`value` internally.

### 3.6 Gridlines and ticks

```jsonc
"gridlines": {
  "h": { "major": { "show": true, "count": null, "spacing": null, "color": null },
         "minor": { "show": false, "count": 1, "color": null },
         "ticks": { "major": "none", "minor": "none" } },  // none | inside | outside
  "v": { … }
}
```

### 3.7 Type options

| Type | `typeOptions` keys |
|------|--------------------|
| `pie` | `pieHole` (0–0.9), `sliceLabel` (none/label/value/percentage/valueAndPercentage), `borderColor`, `slices: {index: {color, offset 0–1}}`, `startAngle` |
| `histogram` | `bucketSize` (null = auto via Freedman–Diaconis, capped 100 buckets), `outlierPercentile` (0–25 %), `showItemDividers` |
| `candlestick` | `risingColor`, `fallingColor`, `risingFilled`, `fallingFilled` |
| `waterfall` | `connectorLines: {show, color, dash}`, `subtotals: [{afterIndex, label}]`, `firstValueIsSubtotal`, `positiveColor`, `negativeColor`, `subtotalColor` |
| `scorecard` | `keyValueRef` (cell id or aggregate over range), `baselineRef`, `aggregate`, `compareMode` (absolute/percent), `keyFormat`, `baselineFormat`, `positiveColor`, `negativeColor`, `showSparkline` (P2) |
| `table` | `pageSize` (0 = no paging), `sortColumn`, `sortAscending`, `showRowNumbers`, `alternatingColors`, `formatFromSource` |
| `radar` | `fillOpacity`, `gridShape` (polygon/circle) |
| `bubble` | `sizeRange: [min, max] px`, `colorBy` (series/category) |
| `gauge` (P2) | `min`, `max`, `ranges: [{from, to, color}]` |

---

## 4. Data extraction (`ChartDataResolver`)

Location: `wonky_sheets_core/lib/src/charts/data/`. Input: `ChartSpec`, a `CellSource` (the same
read interface the formula engine uses; computed values, number formats, hidden/filter state),
and the locale. Output: `ChartData` (immutable):

```dart
class ChartData {
  final ChartDomain domain;            // kind: categorical | numeric | dateTime; values; labels; format
  final List<ChartSeries> series;      // key, name, values (Float64List with NaN = empty), format, type, axis
  final List<ChartWarning> warnings;   // ranges mismatch, non-numeric values ignored, log ≤ 0 skipped…
  final int sourceCellCount;
  final int dataVersion;               // hash of all source values, for cache invalidation
}
```

### 4.1 Steps
1. Resolve each `GridRange` to index bounds in the current order. Unbounded ranges (`A:C`) are
   clipped to the sheet's **used range**. Deleted bounds → the range shrinks (S7). If a range
   resolves to nothing, the chart shows the empty state "No data" and a warning in the editor.
2. Build a logical table (rows × columns). Hidden rows/columns are skipped unless
   `includeHidden` (Google Sheets: "Show hidden/filtered data" off by default). Rows hidden by
   a **filter view** do not count. Only the basic filter and user-hidden rows do.
3. Transpose if `switchRowsColumns`.
4. Headers: the first `headerCount` rows are joined with a space to form series names.
5. Domain: the column at `domain.ref`. Its kind is detected from the computed values:
   all numbers with a date/time number format → `dateTime`; all numbers → `numeric`
   (scatter, line and area use a continuous axis) unless `treatLabelsAsText`; otherwise
   `categorical` (labels are the cells' **formatted** text).
6. Series: numeric value per row. Text and booleans count as empty, errors count as empty with
   a warning. Percent-formatted sources keep their format for labels.
7. Aggregation (if set): group by domain value (stable order of first appearance, or sorted for
   numeric/date domains), apply the function.
8. Downsampling (§12) when points > threshold.

### 4.2 Header auto-detection
`headerCount = 1` if the first row contains at least one text cell and all cells in the same
column below it (sampled first 50 rows) are numbers, or if the first row's cells are all text
and the second row has numbers. Otherwise 0. The result is written into the spec when the chart
is created, so later data changes don't flip the header choice silently.

### 4.3 Live updates
- `ChartController` (Flutter, one per visible chart) subscribes to the workbook's
  `RecalcBatch` events (from [05-formula-engine.md](05-formula-engine.md)). If the batch's
  changed-cell set intersects the chart's source ranges (interval check on the `RuleIndex`), the
  chart re-resolves its data **debounced 150 ms** (trailing, max wait 500 ms).
- Structure changes (insert/delete/move rows/cols, hide/unhide, filters) always trigger
  re-resolution.
- Offscreen charts mark themselves dirty and re-resolve when they scroll into view.

---

## 5. Recommended charts

Opened when the user inserts a chart (`sheets.chart.insert`) and shown as the "Suggested" row
in the chart type picker.

### 5.1 Profile the selection
For each column of the selection (after header detection), compute: count, numeric share,
date share, distinct count, monotonic increase (for dates/numbers), all-positive flag.

### 5.2 Rules (first match is the default chart; up to 4 suggestions shown)

| # | Condition | Default | Other suggestions |
|---|-----------|---------|-------------------|
| 1 | 1 text column with ≤ 12 distinct values + 1 numeric all-positive column | `pie` | column, bar, doughnut |
| 2 | Date/time domain column (monotonic or not) + 1..n numeric columns | `line` | area, column, combo |
| 3 | Text domain + 1..n numeric columns, ≤ 30 rows | `column` | bar, stacked column, line |
| 4 | Text domain + 1 numeric column, > 30 distinct, many repeats | `column` with `aggregate: sum` | pie (aggregated), table |
| 5 | 2 numeric columns, no text column | `scatter` | line, bubble (if 3 numeric) |
| 6 | 1 numeric column only | `histogram` | column, scorecard |
| 7 | Date + 4 numeric columns (low/open/close/high pattern by header names) | `candlestick` | line |
| 8 | Single cell numeric | `scorecard` | gauge (P2) |
| 9 | Mixed or text-heavy | `table` | column |

Data range when nothing is selected or a single cell is selected: the contiguous region around
the active cell (same algorithm as Ctrl+A first press, see [03-grid-and-editing.md](03-grid-and-editing.md)).

The default size is 600 × 371 px (golden ratio). The chart is placed with its top-left at the
first column right of the data region, top row of the region (`dx = 12`). If that column lies
beyond the sheet's visible area, it is placed at the top-left of the current viewport + 24 px.
A region starting in frozen rows (or columns) never anchors the chart in the frozen pane (objects
there stay fixed over the scrolling panes): the chart goes to the top (left) of the scrolling
pane's visible area instead (`defaultChartAnchor(frozenRows, frozenColumns)`).

---

## 6. Rendering

### 6.1 Library evaluation

| Criterion | `fl_chart` 1.2.0 | `graphic` 2.7.0 | Own scene graph + painters |
|-----------|------------------|-----------------|---------------------------|
| Types covered | line, bar, pie, scatter, radar, candlestick | grammar of graphics: interval, line, area, point, polygon, polar coords (pie/radar/rose), custom shapes | everything in §2 |
| Combo / dual axis | partial (overlay two charts by hand) | yes (multiple marks, but dual-axis needs custom scales) | yes |
| Log axis, date axis, custom number formats | log no, date manual | via scales, partial | yes, uses our number formatter |
| Waterfall, histogram, scorecard, table, treemap | no | waterfall/histogram via interval marks, others no | yes |
| Output targets | Flutter `Canvas` only | Flutter `Canvas` only | Canvas, SVG, PDF, server raster from **one** layout |
| Runs on the server (MCP `export_chart_png`, PDF export) | no (Flutter) | no (Flutter) | yes (pure Dart layout) |
| Maintenance | very active, large community | one maintainer, slower | ours |

**Decision:** Wonky Sheets uses an **own pure-Dart chart layout engine** that produces a
renderer-independent `ChartScene`, plus thin renderers. Neither `fl_chart` nor `graphic` is
used for spreadsheet charts. Reasons:
1. The same chart must look identical in the editor, PDF/print, PNG/SVG download, XLSX preview
   and server-side MCP export. Both libraries are Flutter-only, so the server and the PDF
   pipeline would need a second implementation that drifts.
2. Google Sheets parity needs log axes, combo dual axes, waterfall, histogram, scorecard,
   table charts, trendlines with equations, and spreadsheet number formats on axes. Neither
   library covers all of these, so we would fork or wrap them heavily anyway.
3. Downsampling, hit-testing and incremental updates for 100k-point charts are easier to
   control in our own code.

Suite [01-architecture.md](../01-architecture.md) §2.1 therefore lists no chart
library. The design takes ideas from `graphic` (scales, marks, coordinate systems) and from Google Charts'
visual defaults.

### 6.2 Layers

```
wonky_sheets_core/lib/src/charts/
  spec/            ChartSpec model, JSON, migrations
  data/            ChartDataResolver, aggregation, histogram buckets, downsampling (LTTB)
  stats/           trendline regressions, R², moving average
  layout/          ChartLayoutEngine: text measurement interface, scales (linear, log, band,
                   time), nice ticks, axis label collision, legend layout, plot area
  scene/           ChartScene: primitive list (rect, path, polyline, arc, text, clip, group)
                   with semantic tags (series key, point index) for hit-testing
  render/svg/      SvgChartRenderer (string builder)
  render/pdf/      PdfChartRenderer (draws on `pdf` PdfGraphics; used by print & PDF export)
  render/raster/   RasterChartRenderer (server PNG; `image` package + bundled bitmap fonts)
wonky_sheets/lib/features/charts/
  render/          ChartPainter (CustomPainter over ChartScene), TextMeasurer (TextPainter)
  view/            ChartView widget, tooltips, hover, legend interaction
  editor/          Chart editor side panel (§8)
  controller/      ChartController (data subscription, scene cache)
```

`ChartLayoutEngine.layout(spec, data, Size size, ChartTheme theme, TextMeasurer measurer)
→ ChartScene`. The `TextMeasurer` interface hides the platform: Flutter uses `TextPainter`;
PDF uses the `pdf` font metrics of the font it draws with (`PdfTextMeasurer`, Helvetica by
default); the server raster renderer draws text with the bitmap Arial fonts bundled in
`package:image` and lays out PNG exports with their metrics (`RasterTextMeasurer`). Text
layout therefore differs slightly between outputs (label skipping and ellipsis), while the
geometry of the plot is the same. Tests and scene goldens use the deterministic
`ApproxTextMeasurer` (Helvetica advance widths).

The entry points the app and server use are in `ChartPipeline` (`charts/chart_pipeline.dart`):
`resolve` (spec + workbook → `ChartData`), `layout` / `build` (→ `ChartScene` plus warnings),
`exportSvg` / `exportPdf` / `exportPng` (08 §13) and `printSceneFor` (the chart callback of the
print renderer, 11 §6.3).

### 6.3 Scene primitives

```dart
sealed class ScenePrimitive { final SceneTag? tag; }        // tag = (seriesKey, pointIndex, role)
class SRect    extends ScenePrimitive { Rect r; Paint fill; Stroke? stroke; double radius; }
class SPath    extends ScenePrimitive { List<PathCmd> cmds; Paint? fill; Stroke? stroke; }
class SPolyline extends ScenePrimitive { Float64List xy; Stroke stroke; }   // fast path for big lines
class SMarkers extends ScenePrimitive { Float64List xy; MarkerShape shape; double size; Paint fill; }
class SArc     extends ScenePrimitive { Offset c; double r, innerR, start, sweep; Paint fill; Stroke? stroke; }
class SText    extends ScenePrimitive { String text; Offset at; TextStyleSpec style; double angle; TextAnchor anchor; }
class SClip    extends ScenePrimitive { Rect r; List<ScenePrimitive> children; }
```

Colors in the scene are resolved ARGB ints. Theme refs (`theme:accent3`) are resolved by the
layout engine through `ChartTheme`.

### 6.4 Colors and theme
- Series palette: spreadsheet theme `accent1…accent6` (from `Spreadsheet.themeJson`), then
  the same six at 60 % lightness, then at 40 % (18 colors), then cycling. A series' color is
  chosen by its **position** in `seriesRefs` unless overridden.
- `ChartTheme` is derived from (spreadsheet theme, brightness, export flag):

| Element | Editor, light | Editor, dark | Export / print (default) |
|---------|---------------|--------------|--------------------------|
| Background `automatic` | `card` token (white) | `card` token (dark) | `#FFFFFF` |
| Text `automatic` | `foreground` | `foreground` | `#202124` |
| Axis line / gridline `automatic` | `border` / `border` 60 % | same tokens (dark) | `#9AA0A6` / `#E0E0E0` |
| Explicit colors | as stored | as stored | as stored |

- "Export with dark theme" (download dialog option) uses the dark column for exports.
- Default accents must have ≥ 3:1 contrast against both light and dark automatic backgrounds
  (checked by a unit test over the built-in spreadsheet themes).

### 6.5 Interaction (editor only)
- Hover: nearest point (by `SceneTag` hit-test, 8 px tolerance) shows a `ShadTooltip`-styled
  card with domain label, series name and formatted value; `compareMode = category` lists all
  series at that X.
- Clicking a legend entry highlights that series (others dim to 30 %). Not persisted.
- Double-click a chart element → opens the chart editor **Customize** tab at the matching
  section (title → Chart & axis titles, series → Series with that series selected, axis →
  axis section, legend → Legend).
- Charts are not interactive in exports.

### 6.6 Text and number formatting
Axis labels, data labels, tooltips and table charts format values with the spreadsheet
number-format engine ([06-formatting.md](06-formatting.md)) using `axis.numberFormat` or the
first source cell's effective format, in the spreadsheet locale.

---

## 7. Trendlines

`trendline` object on a series (scatter, line, column, bar; not stacked):

```jsonc
{ "type": "linear",                 // linear | exponential | polynomial | logarithmic | power | movingAverage
  "degree": 2,                      // polynomial 2..10
  "period": 3,                      // movingAverage 2..n
  "label": "none",                  // none | equation | custom
  "customLabel": "",
  "showR2": false,
  "color": null, "opacity": 1, "lineWidth": 2, "lineDash": "solid",
  "forward": 0, "backward": 0 }     // P2: extend forecast by n domain units
```

Math in `wonky_sheets_core/lib/src/charts/stats/regression.dart` (shared with the `LINEST`,
`LOGEST`, `TREND`, `GROWTH` functions in [05-formula-engine.md](05-formula-engine.md)):

| Type | Model | Fit | Valid inputs |
|------|-------|-----|--------------|
| linear | y = m·x + b | ordinary least squares | all |
| exponential | y = a·e^(b·x) | OLS on ln y | y > 0 |
| polynomial | y = Σ cᵢxⁱ | OLS via QR decomposition (Householder), degree ≤ min(10, n−1) | all |
| logarithmic | y = a·ln x + b | OLS on ln x | x > 0 |
| power | y = a·x^b | OLS on ln x, ln y | x > 0, y > 0 |
| movingAverage | mean of last `period` points | — | — (no R²) |

R² = 1 − SS_res/SS_tot computed on the **original** scale for linear and polynomial, and on
the transformed scale for exponential, logarithmic and power (Google Sheets and Excel
behavior). For categorical domains, x = 1..n. Points that are invalid for the model are
skipped, and the editor shows the warning "Trendline ignores N non-positive values". The
equation label uses 4 significant digits and is drawn in the legend (Google Sheets style)
and, if `label = equation`, also next to the line end.

---

## 8. Chart editor side panel

Panel id `sheets.panel.chartEditor` (04 §10; `showAsTab: false`, opened by its commands) in `WonkySplitView` (the shared panel width, suite 02 §4.5). It opens on
insert, on double-click, from ⋮ › *Edit chart*, and via `sheets.chart.edit`. Header: the host's
panel icons and collapse (no title). Body: `ShadTabs` with **Setup** and **Customize**. When it is open, the edited
object stays selected and the panel follows selection: selecting another chart switches the
panel to that chart. Selecting a cell keeps the panel open with an empty state ("Select a chart
to edit it").

Every field change dispatches `sheets.chart.update` with a JSON **patch** (§16). Text fields
commit on blur or Enter. Sliders, color pickers and number steppers commit on change, and
consecutive changes to the **same field** within 1000 ms coalesce into one undo step
(`UndoService` coalescing key `chart:<objectId>:<fieldPath>`).

### 8.1 Setup tab

```
┌ Chart editor ─────────────────────── ✕ ┐
│ [ Setup ] [ Customize ]                │
│ Chart type                             │
│ [▦ Column chart                    ▾]  │  → picker popover (§8.3)
│ Stacking   [ None ▾ ]                  │  (column/bar/area/combo)
│ Data range                             │
│ [ A1:D20                         ⊞ ]   │  RangeInput (multi-range, comma-separated)
│ X-axis                                 │
│ [ ▤ Region                      ⋮ ]    │  ⋮: Aggregate ☐, Remove, Treat labels as text ☐
│ [ + Add X-axis ] (when none)           │
│ Series                                 │
│ [ ▮ Q1 revenue                  ⋮ ]    │  ⋮: Edit (range), Remove, Aggregate (if domain agg)
│ [ ▮ Q2 revenue                  ⋮ ]    │  drag handle to reorder
│ [ + Add series ]                       │
│ ☐ Switch rows / columns                │
│ ☑ Use row 1 as headers   [1 ▾]         │  number of header rows
│ ☑ Use column A as labels               │
│ ☐ Aggregate  [Sum ▾]                   │
│ ☐ Include hidden and filtered data     │  (Google: in Customize › Chart style; we keep here)
│ Empty cells  [ Show as gaps ▾ ]        │  (line/area/scatter)
└────────────────────────────────────────┘
```

- **RangeInput** (custom widget in `wonky_sheets/lib/features/common/range_input.dart`,
  shared with CF/DV/pivot editors): `ShadInput` showing A1 text; the ⊞ button opens a floating
  "Select a data range" popover while the grid highlights the current ranges with colored
  borders. The user can drag-select on the grid; "Add another range" appends; OK commits.
  Invalid A1 → inline error. Stores GridRange ids on commit.
- Changing the type keeps data, keeps compatible style fields (titles, legend, colors) and
  drops incompatible ones (`typeOptions` of other types are kept in `extras` so switching back
  restores them within the same session).
- Series chips show the series color swatch; clicking the label opens a small popover with
  the series' A1 range (editable).
- "Use column A as labels" text follows the actual column letter; "Use row 1 as headers"
  follows the actual first row number.

### 8.2 Customize tab (`ShadAccordion`, multiple open)

| Section | Fields |
|---------|--------|
| **Chart style** | Background color (`WonkyColorPicker`, *Automatic*), Font (`FontPicker`), Chart border color (*None*), ☐ Maximize, ☐ Smooth (line/area/combo), ☐ Plot null values, Compare mode (Off/Datum/Category) |
| **Chart & axis titles** | Target select (Chart title, Chart subtitle, Horizontal axis title, Vertical axis title, Right vertical axis title), text input, font, size, B/I toggles, text color, alignment (Auto/Left/Center/Right) |
| **Series** | Target select (*Apply to all series*, each series), Format: fill color, fill opacity, line color, line opacity, line thickness, line dash, point size, point shape; Axis (Left/Right); Type (combo); ☐ Data labels → position, type, font, size, color; ☐ Error bars → type (constant / percent / standard deviation) and value (unstacked column, bar, line, scatter, combo; `errorBars` JSON `{type, value, color?}`, `ErrorBarsSpec`; whiskers with caps that widen the value range); ☐ Trendline → type, degree/period, label (custom label text when *Custom*), ☐ Show R², color, opacity, thickness; *Format data point* ▸ pick a point from the domain list + *Add*, then a color per formatted point and remove (one series selected) |
| **Legend** | Position (Auto, Top, Bottom, Left, Right, Inside, None), font, size, B/I, color |
| **Horizontal axis** | Label font, size, B/I, color; ☐ Show axis line; ☐ Reverse axis order; ☐ Show labels; Slant labels (Auto/None/Custom angle); for numeric axes: Min, Max, ☐ Log scale, Number format (Auto/From source/Custom pattern) |
| **Vertical axis** | Same + right axis selector when a series uses it |
| **Gridlines and ticks** | Target (Vertical/Horizontal axis), Major gridlines (count Auto/1..20 or spacing), color, Minor gridlines (count), color, Major ticks (None/Inside/Outside), Minor ticks |
| **Pie chart** (pie) | Doughnut hole (None/25 %/50 %/75 %/custom), Border color, Slice label, Label font |
| **Pie slice** (pie) | Slice select, color, distance from center (0–100 %) |
| **Histogram** | Bucket size, Outlier percentile, ☐ Show item dividers |
| **Waterfall** | ☐ First value is subtotal, Subtotals list (*Add subtotal*; each row: after which point, label, remove), Connector lines (show, color, dash), colors |
| **Candlestick** | Rising/falling colors and filled flags |
| **Scorecard** | Key value cell and Baseline cell (A1, empty = from the data range), aggregate, Compare mode, formats, positive/negative colors |
| **Table** | Page size, ☐ Row numbers, ☐ Alternating colors, ☐ Format from source |

Every field shows the inherited/automatic value as placeholder text. A **Reset** link per
section clears overrides in that section (one undo step).

### 8.3 Chart type picker
`ShadPopover` anchored to the type select: **Suggested** row (from §5, max 4, icons with
names), then groups *Line*, *Area*, *Column*, *Bar*, *Pie*, *Scatter*, *Map* (P2), *Other*.
Each tile is a 48×36 Lucide-like glyph drawn by `ChartTypeIcon` (custom painter, uses theme
colors). Keyboard: roving focus; Enter selects. Type-ahead search field at the top.

### 8.4 Editor accessibility
All fields are labelled; the accordion and tabs are keyboard operable; color pickers announce
color names; the panel is MCP-describable (`ChartEditorMcp`,
`features/charts/editor/chart_editor_mcp.dart`): `describe()` returns the fields of the selected
chart with spec-path ids (`title.text`, `legend.position`, `series.<key>.color`,
`series.<key>.errorBars.type` …), labels, types, values and options; `setField(id, value)`
validates and writes through `sheets.chart.update` / `setType` / `setDataRanges` (one undo step).
`ui.sheets.describe_panel` adds it as `chart`, and `ui.sheets.set_panel_field` accepts those ids.

---

## 9. Objects on the grid

### 9.1 Rendering layer

Implementation note: the objects layer is `SheetObjectsHost` (`features/objects/objects_layer.dart`),
a widget stack over the whole `GridArea`, so objects draw above the selection and the active-cell
border (as in Google Sheets) rather than below them. Selected objects take keyboard focus in the
`sheetsObject` key scope; Mod+V in the grid pastes copied objects while they are the newest copy.
The grid ([03-grid-and-editing.md](03-grid-and-editing.md)) is painted in layers. Objects are
an `ObjectLayer` **above** cell content, CF, merges and the selection fill, and **below** the
frozen-pane divider lines, the active-cell border and remote cursors.

- Each visible object is a positioned child widget (`EmbeddedObjectView`) inside a
  `Stack` aligned with the scroll offsets of the pane its anchor cell lives in. An object anchored
  in the frozen area but extending past it is clipped to the frozen pane (Google Sheets
  behavior). An object anchored in the scrolling area is clipped to the scrolling pane.
- Only objects intersecting the viewport (plus 1 viewport overscan) are built. Charts outside
  keep their cached `ChartScene`.
- Zoom scales positions and sizes; chart text scales with zoom (scene laid out at logical
  size × zoom for crisp text).
- Each object has a `RepaintBoundary`. The chart scene is cached per (spec hash, dataVersion,
  size, brightness, zoom).

### 9.2 Selection and focus model

| State | How | Visual | Keyboard |
|-------|-----|--------|----------|
| None | default | — | grid has focus |
| **Selected** | click object, keyboard cycle (`Mod+Alt+Shift+O`, see below), MCP | 1 px `selectionBorder` outline + 8 resize handles (squares 8 px, `background` fill, `selectionBorder` stroke) + ⋮ button top-right (on hover/selected) | arrows nudge, Del deletes, Enter opens editor (chart) / alt text (image), Esc deselects back to grid, Mod+C/X/V, Mod+D duplicate |
| **Multi-selected** | Shift/Mod-click (toggles), `sheets.object.select {objectIds}` | outline on each, handles hidden | nudge, delete, z-order (keeps the relative order), copy/cut/duplicate, **align / distribute** (⋮ › Align: left, center, right, top, middle, bottom, distribute horizontally/vertically, `sheets.object.align`); dragging any member moves the group (one `sheets.object.move {objectIds, by}`); a click without drag on a member selects it alone |
| **Editing** (chart editor open) | double-click / Enter | same as selected + panel | panel focus |

- Selecting an object **does not** change the cell selection, but the grid's keyboard focus
  moves to the object layer (`ObjectFocusNode`). The formula bar shows the object's name
  (read-only) while an object is selected.
- Clicking a cell or pressing Esc returns focus to the grid.
- Keyboard access to objects: `Mod+Alt+Shift+O` ("Select next object", Sheets command
  `sheets.object.selectNext`) cycles objects on the current sheet in z-order (top first).
  `Shift` variant (`sheets.object.selectPrevious`) goes backwards.
- Remote collaborators' object selections are shown as a 2 px outline in their presence color
  with a name flag (presence cursor field `objectId` = the primary selected object, published on
  every selection change; see [10-collaboration-history.md](10-collaboration-history.md) §1).

### 9.3 Move and resize
- Drag the body to move; drag a handle to resize. Corner handles resize both dimensions;
  Shift on a corner keeps the aspect ratio (default on for images, `lockAspect`).
- **Snapping**: holding **Alt** while dragging snaps the moving edge(s) to cell gridlines
  (Google Sheets behavior). Without Alt, movement is free (1 px at 100 % zoom).
- Smart guides (P1): when an edge or center is within 4 px of another object's edge or center,
  show a dashed guide in `selectionBorder` and snap to it.
- A live ghost (the object itself, rendered at the new position) follows the pointer. The
  write happens **once on drop** as `sheets.object.move` / `sheets.object.resize` (one undo
  step), with the normalized anchor (§1.2).
- Dragging near the viewport edge auto-scrolls (same speed curve as range selection).
- Min size 20×20 px. Max size 4000×4000 px.
- **Nudge**: arrow keys move 1 px (at 100 % zoom), Shift+arrows move 10 px; Alt+arrows move
  by one cell. A burst of nudges within 1000 ms coalesces into one undo step.
- Viewers and commenters can select objects (to read alt text, download) but not move them.

### 9.4 Z-order
`zIndex` is an `int`. Commands: *Bring to front* (`max + 1`), *Send to back* (`min − 1`),
*Bring forward* / *Send backward* (swap with the next overlapping object above/below; writes
both objects' `zIndex`). Ties sort by object `id`. A merge can produce equal values; that is
harmless because the tie-break is deterministic.

### 9.5 Copy, cut, paste, duplicate
- Copy writes two clipboard representations:
  1. Internal JSON `application/x-wonky-sheets-objects` (kind, anchor size, spec with ranges
     re-encoded as **A1 + sheet name** for cross-spreadsheet paste, alt text). On web, stored in
     the in-app clipboard store plus a text marker; on desktop, custom clipboard format via
     `super_clipboard`-style API wrapped in our `ClipboardService` ([03-grid-and-editing.md](03-grid-and-editing.md)).
  2. A PNG of the object (charts rendered at 2×, images as PNG; the primary object of a
     multi-selection) for pasting into other apps, written next to the text marker
     (`ImageClipboard`: the async Clipboard API on the web, the runner's `wonky.sheets/clipboard`
     channel on macOS — NSPasteboard; other desktops have no image clipboard yet).
- Paste in the same spreadsheet: new object id, same spec (ranges re-resolved from A1, so they
  point at the same cells), placed at the active cell with `dx = dy = 0`. Pasting into another
  spreadsheet: ranges resolve against sheets **with the same names** in the target; if a sheet
  is missing, the range keeps the A1 text and the chart shows "Data range not found" until
  edited.
- Duplicate (`Mod+D` when an object is selected): copy + paste offset by (+16, +16) px.
- Pasting an image file or image data from the OS clipboard while the grid has focus inserts an
  image over cells at the active cell (§10.1): `sheets.edit.paste` checks the clipboard for an
  image first and uses it when the clipboard holds no text (a copied web page with text pastes as
  cells). The insert dialog has *Paste from clipboard*, and `sheets.image.insertOverCells` takes
  `source: clipboard`.

### 9.6 ⋮ object menu

| Item | Command | Chart | Image | Slicer |
|------|---------|-------|-------|--------|
| Edit chart | `sheets.chart.edit` | ✓ | | |
| Edit slicer | `sheets.slicer.edit` | | | ✓ |
| Replace image | `sheets.image.replace` | | ✓ | |
| Place image in selected cell | `sheets.image.placeInCell` | | ✓ | |
| Reset size | `sheets.image.resetSize` | | ✓ | |
| Alt text | `sheets.object.editAltText` | ✓ | ✓ | ✓ |
| Copy chart / Copy | `sheets.object.copy` | ✓ | ✓ | ✓ |
| Copy chart as image | `sheets.chart.copyAsImage` | ✓ | | |
| Download ▸ PNG image / SVG / PDF document | `sheets.chart.download(format)` | ✓ | (original file) | |
| Move to own sheet | `sheets.chart.moveToOwnSheet` | ✓ | | |
| Order ▸ Bring to front / forward / backward / Send to back | `sheets.object.order(op)` | ✓ | ✓ | ✓ |
| Delete | `sheets.object.delete` | ✓ | ✓ | ✓ |

Right-click on an object opens the same menu as a context menu. Publishing charts to the web
is **not** supported.

---

## 10. Images

### 10.1 Image over cells (`EmbeddedObject.kind = image`)

`ImageSpec`:

```jsonc
{ "v": 1,
  "fileUuid": "0193…",            // StoredFile (suite files service), owner = spreadsheet DriveItem
  "mime": "image/png",
  "naturalWidth": 1200, "naturalHeight": 800,
  "crop": null,                    // P2 {l,t,r,b} fractions
  "fit": "stretch",                // stretch (fill the box) | contain | cover
  "sourceUrl": null }              // when inserted by URL (informational)
```

Insert flows (*Insert › Image ▸ Insert image over cells*, `sheets.image.insertOverCells`):
dialog tabs **Upload** (drag-drop zone + file picker, `file_picker`), **By URL** (server
fetches the image through the same SSRF-protected fetcher as scripts, see
[09-scripting.md](09-scripting.md) §8.3, and stores a copy), **Drive** (P2: images stored in
Wonky Drive), **Paste** from clipboard.

Limits: PNG, JPEG, GIF (animated in the editor — first frame with reduced motion, in exports,
print and in-cell images), WebP, SVG (rasterized at insert to a PNG at 2× its own size, ≤ 4000 px,
with `flutter_svg`; the SVG's size is the natural size; the original SVG is not kept). BMP is
not supported ("Only PNG, JPEG, GIF, WebP and SVG images can be inserted"). Max 50 MB. Images above 25 megapixels are downscaled on the client to fit
25 MP (as PNG) before upload (`SheetsImagePrep`).

Default size: natural size scaled down to fit in 600×400 px, keeping the aspect ratio.
*Reset size* restores natural size (capped to 4000 px). Images are **not** stored in the
spreadsheet. Only the file reference is, so they need the server to download the first time.

**Offline**: the upload is queued in the Sheets pending-upload queue (`SheetsPendingUploads`,
`sheets_uploads_<userId>.db`, durable, retried with backoff); the `fileUuid` is a
client-generated UUIDv7 and the image bytes also go to the local blob cache
(`SheetsImageBlobCache`, `local_blob_cache` in `sheets_images_<userId>.db`, 200 MB LRU, see
A-08-5), which also keeps downloaded images, so images render offline and after a reload. The
inserting client sees the image immediately. Other clients see a placeholder ("Image uploading…") until
the file exists. `StoredFile` creation is idempotent on the client-generated UUID.

Image caching: decoded images are cached by `fileUuid` in memory (LRU 100 MB) and on disk
(desktop) / Cache Storage (web) via signed URLs that are refreshed when they expire.

### 10.2 Image in cell

- *Insert › Image ▸ Insert image in cell* (`sheets.image.insertInCell`) uploads as above, then
  writes the active cell's content as the formula `=IMAGE("wonky-file://<fileUuid>")`. One undo
  step covers the upload registration and the cell write. The upload itself is not undone;
  orphan files are garbage-collected by the server after 30 days without references.
- `IMAGE(url, [mode], [height], [width])` (Google Sheets signature; modes 1 fit, 2 stretch,
  3 original size, 4 custom) is evaluated by the formula engine to an `ImageValue`. The grid
  paints it inside the cell (clipped, with cell padding). `wonky-file://` URLs resolve via
  the files service. `https://` URLs are loaded **through the server image proxy**
  (`/files/proxy?url=…`, SSRF-protected, cached 24 h, max 10 MB) so clients never contact
  arbitrary hosts directly and CORS issues on web are avoided.
- Over-cell ↔ in-cell conversion: *Place image in selected cell* deletes the object and writes
  `=IMAGE(...)` into the active cell (one undo step). On an in-cell image, the cell context
  menu offers *Place image over cells*.
- Alt text for in-cell images: P1 via a 5th optional argument `IMAGE(url, mode, h, w,
  alt_text)`. This is a Wonky extension; it is exported to XLSX without the extra argument.

---

## 11. Chart sheets

- *Move to own sheet* (`sheets.chart.moveToOwnSheet`) creates a `Sheet` (`kind = chart`,
  name = chart title or `"Chart 1"`, `sortKey` right after the current sheet) and moves the
  object by updating `sheet` and `anchorJson = {"ownSheet": true}`. The old anchor is stored in
  the object spec's `extras.previousAnchor` so *Move to sheet…* can restore it. One undo
  step covers both rows.
- A chart sheet has no grid. It renders the chart filling the content area with 24 px padding,
  keeping the stored aspect ratio only if `lockAspect`. The sheet tab shows a chart icon.
  Formula bar, toolbar formatting buttons and grid commands are disabled on chart sheets
  (`ChartSheetRules`: command groups that need cells — format, cell(s), rows, cols, insert, data,
  filters, find, CF/DV … plus clipboard/freeze/gridline commands — report "Not available on chart
  sheets"; the formula bar shows that text, disabled). The chart stays selected on its sheet.
- On a chart sheet, the ⋮ menu offers *Move to sheet ▸ <grid sheets>* (`sheets.chart.moveToSheet`),
  which creates a normal anchor at A1 of the target sheet (or `previousAnchor` if it is on that
  sheet) and deletes the chart sheet (one undo step).
- Deleting the chart deletes the chart sheet too (the editor asks for confirmation).
- References: formulas can't refer to chart sheets. `INDIRECT("ChartSheet!A1")` → `#REF!`.

---

## 12. Performance

| Item | Budget / rule |
|------|---------------|
| Max source cells per chart | 1,000,000 (Google: 50k data points per series shown, more is downsampled) |
| Downsampling | Line/area/scatter series with > 10,000 points use **LTTB** (largest-triangle-three-buckets) to `max(2 × plot width px, 2000)` points. Column/bar with > 2,000 categories render as a density band (aggregated by pixel column) with an editor warning "Too many categories to show individually". Pie > 50 slices → smallest grouped into "Other" (P1 option `pieOtherThreshold`). |
| Resolve + layout time | ≤ 16 ms for 10k points, ≤ 120 ms for 1M source cells (done in a background isolate on native and in chunks via `scheduleTask` on web when > 100k cells). |
| Paint | `SPolyline` uses `Canvas.drawRawPoints`/`drawVertices` paths; markers batched; no per-point widgets. |
| Rebuilds | Grid scroll doesn't rebuild charts (transform only). Data changes rebuild only affected charts (§4.3). |
| Many charts | 50 charts per sheet visible at once must keep 60 fps scrolling on a mid-range laptop (perf test `test/features/charts/charts_scroll_benchmark_test.dart`, `-t slow`: scrolling walks no chart scene). |
| Raster cache | 2D scenes are recorded once into a `Picture` (`ChartScenePainter`, kept per scene) and replayed on repaints (hover tooltips, frames, zoom); a 1M-point line lays out in ~120 ms (core `chart_scale_test.dart`). |

---

## 13. Exports of a single chart

`sheets.chart.download(format: png|svg|pdf, scale: 1|2|4 (png), darkTheme: bool)`:
- PNG: render the scene via `ChartPainter` into a `PictureRecorder` at `size × scale` → PNG
  bytes → `file_saver` (desktop: save dialog; web: browser download). File name
  `<chart title or object title>.png`.
- SVG: `SvgChartRenderer`, text as `<text>` elements with `font-family` fallbacks.
- PDF: one page sized to the chart + 0.5 in margins, via `PdfChartRenderer`.
- Server side (MCP `sheets.export_chart_png`, Drive export, print on server): uses
  `RasterChartRenderer` (PNG) or `PdfChartRenderer`, so no Flutter is needed.
- XLSX export mapping of charts lives in [11-import-export-print.md](11-import-export-print.md) §6.

---

## 14. Accessibility

- Every object exposes `Semantics(label: altText ?? autoDescription, button: true,
  selected: …)`. **Auto description** for charts when `altText` is empty: "<Type> chart:
  <title>. <n> series: <names>. X axis: <domain name>, <first label> to <last label>."
- The **alt-text dialog** (`sheets.object.editAltText`): Title + Description (`ShadTextarea`,
  2000 chars), with a "Generate with AI" button (P1, `sheets.ai.describeChart`, see
  [12-mcp-and-ai.md](12-mcp-and-ai.md) §6.10).
- **Data table fallback**: with screen readers active (or via ⋮ › *View data as table*, P1),
  the chart offers a read-only `ShadTable` of the resolved `ChartData` (domain + series
  columns, formatted values) in a dialog.
- Chart colors: series also differ by dash pattern/point shape when *Settings › Sheets ›
  Distinguish chart series by pattern* is on (`SheetsUserDefaults.chartSeriesByPattern`; editor
  only, downloads stay standard).
- Screen readers: every chart offers the custom semantics action *View data as table*
  (`sheets.chart.viewDataTable`), also on chart sheets.
- Keyboard: objects reachable (§9.2), editor fully keyboard operable (§8.4).

---

## 15. Undo and concurrency

### 15.1 Undo
All object mutations go through the session (one plan, one op with
`kinds: ["objects"]`, one undo step):

| Operation | Rows/columns written | Undo label |
|-----------|---------------------|------------|
| Insert chart/image | insert `EmbeddedObject` | "Insert chart" / "Insert image" |
| Move | `anchorJson` | "Move chart" |
| Resize | `anchorJson` | "Resize chart" |
| Edit spec field | `specJson` (patched JSON, whole column) | "Edit chart" |
| Alt text | `altText`, `title` | "Edit alt text" |
| Z-order | `zIndex` of 1–2 objects | "Bring to front" |
| Delete | delete row(s) | "Delete chart" |
| Move to own sheet / back | insert/delete `Sheet` + `sheet`, `anchorJson` of object | "Move chart to own sheet" |
| Image in cell | `Cell.content` (+ object delete when converting) | "Insert image" |

### 15.2 Concurrency (last arrival wins per column)

| Concurrent edits (A ∥ B) | Outcome |
|--------------------------|---------|
| A moves, B edits chart spec | Both survive (`anchorJson` vs `specJson` are different columns). |
| A moves, B resizes | Last writer wins on `anchorJson` (both write the whole anchor). The loser's undo becomes a no-op with the standard partial-undo toast. |
| A and B edit different spec fields (title vs series color) | **Last writer wins on the whole `specJson`**: one change is lost. Mitigation: before writing, the editor re-reads `specJson` and applies its patch to the **latest** local value (read-modify-write on the current model), so the loss only happens for offline writes or writes within one round trip. Documented in help. A per-field split (separate columns) was rejected because the spec is large. |
| A deletes, B edits | Delete wins: the server drops updates to deleted rows (B's outcome `dropped`). B's undo is a no-op. |
| A deletes the anchor row, B moves the object | B's anchor (if it was written later) may point to the deleted row → maintenance re-anchors (§1.2). |
| A changes data cells, B edits chart | Independent. The chart re-resolves. |
| A deletes a source column | Series whose `ref` no longer resolves disappear from the chart, and the editor lists them as "Missing series (column deleted)" with *Remove*. |

---

## 16. Commands

All ids are stable. Args are JSON-schema validated. `requiredRole` is editor unless noted.

| Command id | Args | Undoable | Notes |
|------------|------|----------|-------|
| `sheets.chart.insert` | `{ranges?: A1[], type?, spec?: ChartSpec, anchor?: {cell: A1, dx, dy, width, height}}` | ✓ | No args → recommended chart for selection, opens editor. Returns `objectId`. |
| `sheets.chart.edit` | `{objectId?}` | — | Opens chart editor for the selected/given chart. |
| `sheets.chart.update` | `{objectId, patch: JsonMergePatch, coalesceKey?}` | ✓ | RFC 7386 merge patch on `ChartSpec`. Validated after patching. Edits with the same `coalesceKey` within 1000 ms are one undo step (editor steppers/colors). |
| `sheets.chart.setType` | `{objectId, type, stacking?}` | ✓ | Convenience. |
| `sheets.chart.setDataRanges` | `{objectId, ranges: A1[]}` | ✓ | Re-runs header/series detection unless `keepSeries`. |
| `sheets.chart.download` | `{objectId, format: png\|svg\|pdf, scale?, darkTheme?}` | — | Viewer+ (if export allowed by share settings). |
| `sheets.chart.copyAsImage` | `{objectId}` | — | PNG to clipboard. |
| `sheets.chart.moveToOwnSheet` | `{objectId}` | ✓ | Returns new `sheetId`. |
| `sheets.chart.moveToSheet` | `{objectId, sheetId}` | ✓ | From chart sheet back to grid. |
| `sheets.chart.viewDataTable` | `{objectId}` | — | Viewer+. |
| `sheets.image.insertOverCells` | `{source: upload\|url\|clipboard, url?, anchor?}` | ✓ | Opens dialog when no source given. |
| `sheets.image.insertInCell` | `{source, url?, cell?: A1, mode?}` | ✓ | |
| `sheets.image.replace` | `{objectId, source, url?}` | ✓ | Keeps anchor and size. |
| `sheets.image.resetSize` | `{objectId}` | ✓ | |
| `sheets.image.placeInCell` | `{objectId, cell?: A1}` | ✓ | |
| `sheets.image.placeOverCells` | `{cell: A1}` | ✓ | From an `=IMAGE()` cell. |
| `sheets.object.select` | `{objectId, add?}` or `{objectIds}` | — | Viewer+. `add` toggles in a multi-selection. |
| `sheets.object.selectNext` / `selectPrevious` | — | — | `Mod+Alt+Shift+O` / with Shift reversed. |
| `sheets.object.deselect` | — | — | Esc. |
| `sheets.object.move` | `{objectId, anchor: {cell: A1, dx, dy}}`, `{objectId, by: {x, y}}`, `{objectId, to: {x, y}}` (sheet px, used by drags) or `{objectIds, by}` (group move) | ✓ | |
| `sheets.object.align` | `{objectIds?, op: left\|center\|right\|top\|middle\|bottom\|distributeHorizontally\|distributeVertically}` | ✓ | ≥ 2 objects (distribute ≥ 3). |
| `sheets.object.resize` | `{objectId, width, height, x?, y?}` (`x`/`y`: new top-left when a left/top handle was dragged) | ✓ | |
| `sheets.object.nudge` | `{dx, dy}` (selected objects) | ✓ | Coalesces. |
| `sheets.object.order` | `{objectId?, op: front\|forward\|backward\|back}` | ✓ | |
| `sheets.object.delete` | `{objectIds?}` | ✓ | Del / Backspace. |
| `sheets.object.duplicate` | `{objectIds?}` | ✓ | Mod+D. |
| `sheets.object.copy` / `cut` | `{objectIds?}` | cut ✓ | Mod+C / Mod+X with object focus. |
| `sheets.object.paste` | — | ✓ | Mod+V; normally routed via `sheets.edit.paste`. |
| `sheets.object.editAltText` | `{objectId, title?, description?}` | ✓ | Without args opens dialog. |
| `sheets.object.list` | `{sheetId?}` | — | Viewer+. Used by MCP and the "Objects" palette provider ("Go to chart…"). |

Menus: *Insert › Chart*, *Insert › Image ▸ (in cell / over cells)*, *Insert › Drawing* (P2),
toolbar "Insert chart" button; see [04-screens-menus-toolbar.md](04-screens-menus-toolbar.md).

---

## 17. MCP needs

Headless tools are defined in [12-mcp-and-ai.md](12-mcp-and-ai.md) §3.10:
`sheets.create_chart`, `sheets.update_chart`, `sheets.delete_chart`, `sheets.export_chart_png`,
and the object listing in `sheets.get_spreadsheet`. Requirements this spec puts on them:
- Charts are addressed by `chart_id` (= object id) and listed with `title`, `type`, `sheet`,
  A1 data ranges and anchor cell (A1).
- `ChartSpec` JSON in MCP uses **A1 ranges** (`"ranges": ["Sheet1!A1:C20"]`) and series refs by
  header name or A1 column (`{"column": "C"}`); the server converts them to GridRange ids.
  The full JSON schema of `ChartSpec` is generated from the Dart model into
  `wonky_core/lib/mcp/schemas/chart_spec.schema.json` (strict-compatible: all properties
  listed, `additionalProperties: false`, optional fields nullable). Maps keyed by series key or
  point index are key/value pair lists in that schema; `ChartSpecSchema.fromStrictJson`
  turns a strict payload back into the stored form (pairs → maps, `null` → absent).
- `export_chart_png` returns MCP image content using `RasterChartRenderer`.
- UI bridge: `ui.sheets.open_panel({panel: "chartEditor", objectId})`, plus
  `ui.invoke_command` with the commands above.

---

## 18. Slicers and drawings

- **Slicer objects** (`kind = slicer`, P2): behavior, spec and filter semantics are in
  [07-data-tools.md](07-data-tools.md). This spec provides the object layer (move, resize,
  z-order, copy, delete, alt text, concurrency) and the rendering shell: a `ShadCard` with
  header (column name, filter icon, "N of M" summary) that opens the slicer filter popover.
  Default size 180×36 px. Slicers ignore `lockAspect`.
- **Drawings** (P2): `kind = drawing`, spec = list of shapes (rect, ellipse, line, arrow,
  text box, image) in a 2D canvas with fill/stroke/text options, edited in a full-screen in-app
  drawing route `/s/:uuid/drawing/:objectId`. Rendered by a `DrawingScene` reusing the chart
  scene primitives. Not specified further in v1. The enum value is reserved now (Additions).

---

## 19. Packages, folders and widgets

(v2) The chart engine moves to the shared packages `wonky_charts` / `wonky_charts_flutter`
(§24); the paths below are the pre-extraction locations and map as listed there.

| Location | Content | Owner workstream ([13](13-implementation-plan.md)) |
|----------|---------|------------------|
| `wonky_sheets_core/lib/src/charts/**` | spec, data resolver, stats, layout, scene, SVG/PDF/raster renderers | WS-S13 |
| `wonky_sheets_core/lib/src/objects/anchor.dart` | `ObjectAnchor` parse/normalize/re-anchor rules | WS-S13 |
| `wonky_sheets/lib/features/charts/**` | `ChartPainter`, `ChartView`, `ChartController`, editor panel | WS-S13 |
| `wonky_sheets/lib/features/objects/**` | `ObjectLayer`, `EmbeddedObjectView`, handles, drag/resize, z-order, clipboard, image dialogs | WS-S13 |
| `wonky_sheets/lib/features/common/range_input.dart` | `RangeInput` | WS-S19 (shared) |
| `wonky_sheets/lib/commands/chart_commands.dart`, `object_commands.dart`, `image_commands.dart` | commands | WS-S13 |
| `wonky_server/lib/src/sheets/mcp/chart_tools.dart` | chart MCP tools | WS-S17 |

New widgets (Sheets-local unless stated):

| Widget | Purpose |
|--------|---------|
| `ChartTypeIcon` | Painted glyph per chart type, theme-aware. |
| `ChartTypePicker` | Popover grid with suggestions and search. |
| `RangeInput` | A1 range field + grid picking popover. |
| `ObjectResizeHandles` | 8 handles + rotation-less frame, hit areas 16 px. |
| `SnapGuidesPainter` | Smart guides and Alt-snapping guides. |
| `AltTextDialog` | `WonkyDialogSpec`-based dialog. |
| `ImageInsertDialog` | Upload / URL / Paste tabs. |
| `WonkyAccordionSection` (in `wonky_ui`) | `ShadAccordion` item with a "Reset" trailing action and a summary line; reused by CF/DV/pivot editors. |

---

## 20. Additions to 02-data-model

| # | Change | Reason |
|---|--------|--------|
| A-08-1 | `EmbeddedObjectKind` gains `drawing` (reserved, P2). Enum value added now to avoid a later breaking schema change (suite 17 part 2 §4.3). | §18 |
| A-08-2 | `anchorJson` gains `v` and `lockAspect`; `{"ownSheet": true}` documented as the chart-sheet anchor. | §1.2, §11 |
| A-08-3 | `specJson` always carries `v`; `ChartSpec`, `ImageSpec` schemas as in §3 and §10.1. | §1.3 |
| A-08-4 | Maintenance invariant: objects whose anchor row/column is deleted are re-anchored deterministically to the next surviving row/column (`dx = dy = 0`). | §1.2 |
| A-08-5 | Local-only table `local_blob_cache(file_uuid, mime, bytes, size, created_at, used_at)` in `sheets_images_<userId>.db` (Sheets-local; 200 MB LRU) for offline and reloaded images; pending uploads stay in `sheets_uploads_<userId>.db`. | §10.1 |
| A-08-6 | The op summary (`summaryJson.kinds`) uses the value `objects` for object operations. | §15 |

---

## 21. Acceptance criteria

1. Selecting A1:D13 (header row + 12 months × 3 numeric columns) and *Insert › Chart* creates
   a line chart (date domain) or column chart (text months) with 3 series named from row 1,
   positioned right of the data, and opens the editor. One undo removes it.
2. Every type marked P0/P1 in §2 renders in the editor, in PNG/SVG/PDF downloads and in print
   output, and the outputs match each other (golden tests: scene JSON identical; pixel diff
   < 1 % between Flutter PNG and server raster PNG for the reference fixtures).
3. Editing a source cell updates the chart within 300 ms (debounce + render) on a 10k-point
   chart. Inserting a column inside the data range adds a series; deleting a source column
   removes it without errors.
4. Inserting 10 rows above a chart's anchor moves the chart down by those rows' heights; the
   chart size stays the same.
5. Alt-drag snaps the chart edges to gridlines; arrow keys nudge 1 px; Shift+arrows nudge 10 px;
   a burst of nudges is one undo step.
6. Concurrent move (client A) and title change (client B) offline both survive after sync.
7. Light/dark switch re-renders charts with *automatic* background/text colors following the
   app theme; downloads stay light unless "dark theme" is chosen.
8. A line chart with 1,000,000 points scrolls the grid at 60 fps and renders in < 150 ms
   (desktop reference machine) using LTTB.
9. Trendlines: linear, exponential, polynomial (2–6), logarithmic, power and moving average
   match Excel/Google Sheets coefficients and R² to 1e-9 relative on the test corpus.
10. Image over cells: upload, URL insert, paste from clipboard, offline insert (visible locally,
    synced later), reset size, replace, place in cell and back. Every operation is one undo step.
11. `=IMAGE("https://…")` renders through the proxy. Private-IP URLs are refused with `#REF!`
    and the error tooltip "Image URL not allowed".
12. Move to own sheet and back restores the original anchor. The chart sheet tab shows a chart icon.
13. A screen-reader user can reach every chart with `Mod+Alt+Shift+O`, hear its alt text
    (or auto-description), and open the data table.
14. All commands in §16 are invocable via `ui.invoke_command` and pass the execute→undo→redo
    equality test.

## 22. Tests

- **Unit** (`wonky_sheets_core`): spec JSON round-trip incl. unknown keys; patch validation;
  data resolver (headers, switch, aggregation, hidden rows, multi-range, missing columns);
  recommendation rules table-driven; regression math vs. reference values (generated with
  NumPy and checked into fixtures); nice-tick algorithm; LTTB.
- **Golden** (`wonky_sheets/test/goldens/charts/chart_types_golden_test.dart`, tag `golden`):
  every type (2D and 3D) × light/dark × 2 sizes as contact sheets; editor panel light/dark.
  Masters are generated on CI Linux (specs/15 §7).
- **Scene goldens** (pure Dart): `ChartScene` JSON snapshots per fixture, shared by all renderers.
- **Widget tests**: select/move/resize/nudge/z-order/delete/copy-paste flows; editor field →
  command dispatch; undo coalescing.
- **Concurrency**: two simulated clients (§15.2 table) against the in-process RevLog server
  (`FakeRevServer`, suite 17 As built 16).
- **Performance**: 1M-point line; 50 charts/sheet scroll benchmark.

## 23. 3D charts

3D column (clustered, stacked, 100 %), bar, line (ribbons), area (rows or stacked), pie /
doughnut and surface charts in the friendly AppleWorks style: chunky extruded marks, a floor and back/side
walls with gridlines, a soft key light with lit tops and shaded sides, gentle highlights, soft
floor shadows, crisp Flutter text on top. 3D is a section of the existing spec, not new types:
switching a chart between flat and 3D keeps everything else. The one exception is the
**surface** type (`ChartType.surface`, P1, `only3D`): a height field over the grid of categories ×
series that is always drawn in 3D (`threeD.enabled` is implied).

### 23.1 Spec (`threeD`, in `specJson`, no schema change)

```jsonc
"threeD": {
  "enabled": true,          // only column, bar, line, area, pie (ChartType.supports3D)
  "azimuth": 20,            // degrees 0..360 (null = type default: 20, pie 0)
  "elevation": 20,          // degrees 0..90 (null = type default: 20, pie 40)
  "perspective": 15,        // field of view in degrees, 0 (none) .. 60
  "depth": 100,             // % of the column/row width; pie: height
  "gapDepth": 150,          // % gap between rows / in front of and behind columns
  "lighting": "soft",       // soft | bright | flat
  "wallsVisible": true,     // floor, back and side walls with gridlines
  "floorColor": "#RRGGBB",  // null = from the theme
  "shape": "box",           // box | cylinder | cone | pyramid (column, bar)
  "explode": 0              // pie: every slice pulled out (0..1); per-slice offsets still apply
}
```

Defaults are omitted from the JSON; the schema (`ChartSpecSchema`, MCP) validates ranges.
`ChartSpec.is3D` = `type.only3D || (threeD.enabled && type.supports3D)`; other types ignore the
section (it is kept when switching types). Smooth lines and areas are monotone cubics sampled 8×
(picking maps back to the nearest point); trendlines are thin ribbons in front of their row (lines,
areas) or of the columns (column charts; not on horizontal bars); data labels sit on columns, bars
and ribbon tops. Secondary axes and log scales are not drawn in 3D.

### 23.2 Layout and data

- First series in front (Excel). Columns/bars cluster side by side with the depth of one column;
  stacking and 100 % work as in 2D. Lines are ribbons, unstacked areas slabs, each series in its
  own depth row; stacked areas share one row.
- The value axis is a nice-tick range (axis min/max/gridline count/spacing honoured); tick labels
  sit at the side wall's front edge, category labels below the floor's front edge (thinned when
  they would collide). Walls are always on the far sides: they swap sides while orbiting.
- The legend uses boxes for every series; the legend highlight fades the other series toward the
  background (no transparency, so sorting stays correct).
- Pie: one wedge per positive value, labels on the top faces (hidden below 3 %).
- Surface: one patch (`Chart3DPatch`, two double-sided triangles) per pair of neighbouring
  points of neighbouring series, colored by **value band**: the value axis ticks bound the bands,
  band *b* uses palette color *b*, and the legend lists the bands ("10 – 20"). Series names label
  the depth rows. With one series it falls back to an area ribbon.

### 23.3 Core (`packages/wonky_sheets_core/lib/src/charts/three_d/`)

`layout/layout_3d.dart` builds a `Chart3DModel` in world units (right-handed, y up, +z toward the
default viewer): items (`Chart3DBox`, `Chart3DWedge`, `Chart3DSlab`, `Chart3DLine`) with stable
keys, labels at world anchors, bounds, view and lighting. `Chart3DMesher` turns items into convex
chunks of faces with outward normals (smooth normals on cylinders, cones and pie rims). A
`Chart3DScene` fits a `Chart3DCamera` (orbit camera, perspective from the field of view, fitted
into the plot rectangle) and is attached to the layout as `ChartScene.threeD`. The scene's
primitives contain the **software rendering** in one `SGroup` tagged
`detail: 'chart3d'`, followed by the labels as `SText`.

### 23.4 Camera and picking

The camera maps a world point to `X = cx + s·(xv/zf − ox)`, `Y = cy − s·(yv/zf − oy)` (view
coordinates). `gpuViewport` + `gpuFovY` describe the GPU perspective camera that produces exactly
these pixels, so the GPU image, the labels and hit-testing agree. `Chart3DScene.pick(x, y)` casts a
ray through the meshes (Möller–Trumbore) and returns the point tag: tooltips and double-click work
with both backends.

### 23.5 Software backend (web fallback, exports, print)

Painter's algorithm: walls, floor, gridlines, soft floor shadows (projected convex hulls, three
stacked translucent layers, clipped to the floor; doughnut holes stay free), then data chunks back
to front (pie bottoms, sides, tops in layers; otherwise the axis-aligned plane separating two
chunks' bounds decides, falling back to distance). Back faces are culled. Each face is shaded per
vertex (ambient + key light fixed relative to the view + Blinn-Phong highlight + contact darkening
near the floor) and filled with a linear gradient (`SPath.gradient`, `SGradient`) between its
brightest and darkest vertex; faces get a hairline outline (darker on edges, same color between
facets to hide anti-aliasing seams). Every renderer draws the gradients: the Flutter painter,
SVG (`linearGradient`), PDF (axial shading clipped to the face) and the server raster PNG
(per-pixel interpolation). PNG/SVG/PDF downloads, print and the MCP `export_chart_png` always use
this backend.

### 23.6 Interaction

- **Orbit**: dragging inside the plot area of a *selected* 3D chart (always on chart sheets)
  rotates it (0.45°/px horizontally, 0.3°/px vertically) with inertia (friction simulation);
  the end angle is written as one `sheets.chart.update` (one undo step). The chart view claims the
  pointer (`ChartPointerClaims`) so the objects layer doesn't start a move; a drag outside the
  plot area (titles, legend) still moves the chart. Viewers can look around locally.
  **Alt+Shift+arrow keys** turn a selected 3D chart by 5° (`sheets.chart.rotate3D` with
  `dAzimuth`/`dElevation`; repeated presses coalesce into one undo step).
- **Animated data changes**: when the model's content changes (data, stacking, highlight), the
  chart animates from what is on screen to the new model over 450 ms (`Chart3DModel.lerp`: items
  matched by key, new ones grow from their base). Off with reduced motion.
- Hover tooltips come from `pick`; the item under the pointer is drawn 28 % lighter by both backends
  (`ChartLayoutOptions.hover3D` → `Chart3DScene.hover` / `colorOf`; ribbons light up as a whole;
  the GPU backend rebuilds its meshes on `meshHash`; hover never animates). The a11y description
  starts with "3D" (`ChartDescriber`).

### 23.7 GPU backend (`flutter_scene`)

`wonky_sheets/lib/features/charts3d/gpu/flutter_scene_renderer.dart` renders the scene's chunks
with `flutter_scene` (meshes built at runtime with `MeshGeometry.fromArrays`, one physically based
material per color, a shadow-casting directional light following the view, ambient occlusion,
`pbrNeutral` tone mapping), mirroring z into Flutter Scene's left-handed world, into the
`gpuViewport` of the core camera; the painter draws it in place of the software group and paints
the labels on top. `main.dart` registers the starter; it starts with the first 3D chart shown, so
spreadsheets without 3D charts never load the shader bundles. Platforms: **web** (Flutter Scene's
built-in WebGL2 backend, CanvasKit and Skwasm, no build flags: `flutter build web --wasm` as
before), native desktop/mobile through Flutter GPU (Impeller + `FLTEnableFlutterGPU`, set in
`macos/Runner/Info.plist`). Triangles are re-wound against their outward normals after the z
mirror (`gpu/mesh_winding.dart`): Flutter Scene lights back faces of double-sided materials with
the reversed normal, so mirrored faces were lit from inside (dark floors, washed-out colors). On
the web each frame is snapshotted into an engine-owned image (`Picture.toImageSync`): the image
Flutter Scene hands over comes from a transferred `ImageBitmap` that is only good for one
rasterization, and charts went blank under dialog blurs and the side sheet's scrim. The console
logs `3D charts: GPU backend ready (flutter_scene)` when the GPU path is active. When Flutter Scene can't start (no WebGL2, no Flutter GPU) or a frame
fails, the software backend draws it. Tests never import the backend.

### 23.8 XLSX

Export writes `c:view3D` (`rotX` = elevation, `rotY` = azimuth, `depthPercent`, `rAngAx` = 1 when
the perspective is 0, else `perspective` = 2 × field of view), `c:floor`/`c:sideWall`/`c:backWall`
(floor color, `noFill` when walls are hidden) and `c:bar3DChart` (`gapDepth`, `shape`, third
`axId` 0), `c:line3DChart` / unstacked `c:area3DChart` with a deleted `c:serAx`, stacked
`c:area3DChart`, `c:pie3DChart`. 3D doughnuts are written as flat doughnuts (Excel has no 3-D
doughnut). Surface charts are `c:surface3DChart` (series axis, no wireframe) both ways.
Import maps the same elements back to `threeD`.

**ODS** (11 §6.4): charts are embedded ODF chart objects (`Object N/content.xml`, `office:chart`,
shown by a `draw:frame` in the sheet's `table:shapes`); 3D charts set `chart:three-dimensional`,
`chart:deep` (3D lines, unstacked areas, surfaces), `chart:solid-type` (column shape) and the view
(`dr3d:transform` rotations from azimuth/elevation, `dr3d:projection`). Types ODS has no class for
(scorecard, table, histogram, waterfall, candlestick, bubble) are listed in the export report.

### 23.9 Editor

The type picker has a **3D** group (3D column, stacked, 100 %, bar, stacked bar, line, area,
stacked area, pie, doughnut, surface) whose icons are tiny scenes drawn by the core software
renderer.
Customize › **3D** (for column, bar, line, area, pie): Show in 3D, Rotation / Tilt / Perspective
sliders (one undo step per drag), Depth (pie: Height), Gap depth (pie: Pull slices apart),
Lighting, Shape (column/bar), Floor and walls, Floor color, Reset view, and the orbit hint
(surface charts have no *Show in 3D* switch; `sheets.chart.toggle3D` is disabled for them).

### 23.10 Commands and MCP

`sheets.chart.setType` takes `threeD: bool`; `sheets.chart.toggle3D` (palette), `sheets.chart.reset3DView`
(palette), `sheets.chart.rotate3D` (`azimuth`/`elevation` or `dAzimuth`/`dElevation`; edits within
1 s coalesce). MCP `sheets.create_chart` / `update_chart` accept `options.threeD` (or
`three_d: true`) and the types `column_3d`, `bar_3d`, `line_3d`, `area_3d`, `pie_3d`, `surface`.

### 23.11 Tests

Core `test/charts/three_d/chart3d_test.dart` (spec, camera ↔ GPU mapping, ray picking, meshes,
painter order, gradients, layouts per type, transitions, dark theme, SVG/PNG) and
`test/io/xlsx/xlsx_charts_3d_test.dart` (round trip); server
`test/unit/mcp/sheets_chart_3d_options_test.dart`; app `test/features/charts3d/chart3d_test.dart`
(commands + undo, software painting per type light/dark, GPU hook, 3D section at 360 px, type
icons, orbit drag = one undo step without moving the object). Phase 4: core
`test/charts/three_d/chart3d_phase4_test.dart` (surface layout/legend/picking/XLSX, hover
highlight, smooth ribbons, ribbon data labels, 3D trendlines), `test/charts/render/gradient_render_test.dart`
(raster and PDF gradients), `test/io/ods/ods_charts_test.dart`; app
`integration_test/chart3d_backends_test.dart` renders the same scene with the GPU and the
software backend and compares hue and brightness of every lit face (needs Flutter GPU: run on a
desktop device, skipped elsewhere). `CHART3D_PREVIEW=<dir> dart test -P
slow test/charts/three_d/chart3d_preview_test.dart` writes PNG/SVG previews.

## 24. Extraction to `wonky_charts` and `wonky_charts_flutter` (v2)

Wonky Slides renders charts too (linked Sheets charts incl. 3D, and native charts —
[Slides 08](../wonky_slides/08-charts-from-sheets.md)), and app packages may not import each
other (suite [01 §2.1](../01-architecture.md)). In milestone M8 (Drive 05 work package D-3, before Slides
needs it in M10) the engine moves into two shared leaf packages **without behavior change**
(number formats into `wonky_numfmt` at the same time, [Slides 08 §2.5](../wonky_slides/08-charts-from-sheets.md)):

| From | To | Notes |
|------|----|-------|
| `wonky_sheets_core/lib/src/charts/{spec,layout,scene,render,three_d,stats,sparkline,describe,recommend}` | `packages/wonky_charts/lib/src/…` (pure Dart) | `ChartSpec`, `ChartType`, styles, `ChartLayoutEngine`, `ChartScene`, SVG/PDF/raster renderers, 3D model/camera/mesh/shading, trendline stats, sparklines, describer, recommender |
| `…/charts/data/chart_data.dart`, `value_formatter.dart` (interface part), `data_algorithms.dart` | `wonky_charts` | `ChartData` (resolved series: categories, values, labels, formats) is the engine's **only** data input; `ChartValueFormatter` is an interface with a simple default |
| `…/charts/data/chart_data_resolver.dart`, `ChartDataSpec` range parsing (`GridRange`, `FValue`) | **stays** in `wonky_sheets_core` | Sheets resolves cells → `ChartData` and implements `ChartValueFormatter` with its number-format engine (06) |
| `…/charts/chart_pipeline.dart` | split: generic `ChartPipeline(spec, data)` in `wonky_charts`; `SheetsChartPipeline` (resolve → pipeline) in `wonky_sheets_core` | |
| `wonky_sheets/lib/features/charts/render/chart_painter.dart`, `view/chart_view.dart` (rendering part) | `packages/wonky_charts_flutter` | `ChartPainter`, a `ChartView` widget taking `ChartScene`/`ChartData` (no Sheets controller) |
| `wonky_sheets/lib/features/charts3d/` (GPU backend, `flutter_scene_renderer.dart`, install hook) | `wonky_charts_flutter` | `flutter_scene` + `vector_math` dependencies move with it (01 §2.1 exceptions) |
| Chart editor panel, type picker, controller, insert, chart sheets, MCP chart tools | **stay** in `wonky_sheets` / server | Sheets-specific UI and data wiring |

Rules: `ChartSpec` JSON (§3) is unchanged and versioned in `wonky_charts`; the spec's data
section keeps opaque source references (`ChartDataSpec.ranges` as stored strings) that only the
resolver interprets, so Slides can store a data snapshot instead of ranges. The extraction is
verified by the existing chart unit/golden tests moving with the code and by the unchanged
Sheets goldens.

**Done (M8, D-3).** `packages/wonky_numfmt`, `packages/wonky_charts` and
`packages/wonky_charts_flutter` exist; `model.dart` re-exports `wonky_charts` and `wonky_numfmt`,
so Sheets and server imports are unchanged except: `ChartPipeline.resolve/build/export*/
printSceneFor/exportTheme` are now `SheetsChartPipeline.*` (`ChartPipeline.layout` is the
generic engine call), `ChartDataSpec.ranges` holds `DataRangeRef`s (`spec.data.gridRanges`,
`GridRange.fromRef`/`toRef`), the painter/3D GPU/orbit/glyph code is imported from
`package:wonky_charts_flutter/wonky_charts_flutter.dart` (GPU backend: `…/gpu.dart`). Stored
spec JSON is unchanged. Details and deviations: [Slides 08 §2.10](../wonky_slides/08-charts-from-sheets.md).
