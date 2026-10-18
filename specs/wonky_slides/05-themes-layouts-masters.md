# Slides 05 · Themes, Layouts and Masters

A deck's look comes from its **theme** (colors with a light and a dark appearance, fonts, text
styles, backgrounds, default object styles, code and chart palettes), its **masters** (base slide
designs) and their **layouts** (slide templates with **placeholders**). This spec defines the
theme JSON, appearance, fonts, the built-in layouts and themes, placeholders and inheritance,
master/layout editing, the Themes panel (apply/import), and slide sizes.

Storage: `DeckTheme`, `SlideMaster`, `SlideLayout` and master/layout-owned `SlideElement`s
([02 §3.2, §3.5](02-data-model.md)). Menus and the inspector: [04](04-screens-menus-toolbar.md).
Write's theme system ([Write 06](../wonky_write/06-themes.md)) is the model for validation,
OKLCH color math, fonts and contrast checks; Slides themes differ in being **copied into each
deck** (not a live library) — like Keynote, PowerPoint and Google Slides.

Owned folders: `wonky_slides_core/lib/src/theme/` (schemas, resolver, built-ins, layout library),
`wonky_slides/lib/features/{themes,masters}/`.

---

## 1. Concepts

| Term | Meaning |
|------|---------|
| **Theme** | A `DeckTheme` row + its masters, layouts and their elements, inside one deck. A deck has ≥ 1 theme (more after pasting slides with *Keep source formatting*); `Deck.themeId` is the default for new slides. |
| **Built-in theme** | A theme definition shipped in `wonky_slides_core/lib/src/theme/builtins/` (versioned). Applying it **copies** it into the deck with deterministic ids (02 §2.1). |
| **Appearance** | `Deck.appearance` (`light` \| `dark`): which of each theme's two color schemes resolves `theme:` color refs. Switching appearance re-colors every theme-referenced color in the deck at once. |
| **Master** | Base design of a theme: background, decorative elements (logos, rules), and **master placeholders** (title, body, slide number, footer, date) that define default text styles and positions. |
| **Layout** | A slide template under a master (`SlideLayout`): layout placeholders refine master placeholders; extra decorations; optional own background. |
| **Placeholder** | An element with `placeholderType`; on a layout it defines geometry, style and prompt; slides hold **instances** (`placeholderOf`) whose null fields inherit. |
| **Inheritance chain** | slide instance ▸ layout placeholder ▸ master placeholder of the same type ▸ theme text style ▸ built-in defaults (02 §4.2, P6). |

Principles:
1. **Theme references, not copies of values.** Built-in themes, layouts and default object styles
   use `theme:` color refs and `@heading/@body/@mono` font refs, so re-theming, switching
   appearance and importing themes keep decks coherent.
2. **Explicit always wins.** A user-picked hex color or family stays as chosen through theme and
   appearance changes (the color picker offers theme colors first to encourage refs).
3. **Every renderer resolves the same way.** `DeckThemeResolver` (core, pure Dart) produces a
   `ResolvedTheme` per (theme content hash, appearance) consumed by the canvas, thumbnails,
   presenting, the PDF renderer and MCP.

---

## 2. Theme JSON

All JSON columns of `DeckTheme` carry `"v": 1`, are validated by `DeckThemeValidator` (JSON
schemas in `wonky_slides_core/lib/src/theme/schema/`, exported for MCP) and migrated by
`DeckThemeMigrations` (as Write 06 §2.7). Unknown keys are dropped with a warning.

> Implemented (SL-6): `package:wonky_slides_core/themes.dart`. `DeckThemeData` holds the typed
> columns (`ThemeColors`, `ThemeFonts`, `ThemeTextStyles`, `SlideBackground`,
> `ThemeShapeStyles`, `ThemeTableStyle`, `ThemeCodeStyle`, `ThemeChartStyle`) with
> `toColumns()` / `deckThemeFromColumns()` and a `contentHash` (all JSON columns, not the name).
> `DeckThemeValidator.validateColumn` / `validateTheme` → cleaned value + `ThemeIssue` errors and
> warnings (`{path, code, message}`); missing `"v"` migrates as 1, newer versions are
> `unsupported_version`; missing text styles are filled from the §2.5 defaults (warning);
> unknown code palette ids fall back to the Wonky pair (warning); unknown fonts are kept with an
> `unknown_font` warning (§3.2). `DeckThemeSchemas` are hand-written JSON Schemas (draft
> 2020-12) per column. Small extensions found while building: gradient fills take an optional
> radial `center: [x, y]` and `radius` (fractions; 02 §5.2), `codeStyleJson.box.shadow` is
> `none | soft | strong`, `chartStyleJson.threeD.lighting` is `soft | studio | flat`.

### 2.1 Value types

`ColorRef`, `FontRef`, su lengths and fractions as defined in [02 §2.2](02-data-model.md).
`Fill` = 02 §5.2, `Stroke` = 02 §5.3.

### 2.2 `colorsJson`

```jsonc
{
  "v": 1,
  "light": {
    "bg1": "#FFFFFF",      // slide background
    "text1": "#0F172A",    // primary text
    "bg2": "#F1F5F9",      // alternate surface (cards, table bands, code chrome)
    "text2": "#475569",    // secondary text (subtitles, captions, labels)
    "accent1": "#6366F1", "accent2": "#06B6D4", "accent3": "#10B981",
    "accent4": "#F59E0B", "accent5": "#EF4444", "accent6": "#A855F7",
    "link": "#4F46E5"
  },
  "dark": { /* same 11 keys, all required */ },
  "custom": [ { "name": "Brand orange", "light": "#FF5A1F", "dark": "#FF7A45" } ]   // ≤ 12, referenced as "theme:custom1"…
}
```

Both schemes are **complete** (no derivation at render time). When a user edits a theme and
leaves the dark scheme untouched, the theme editor offers **Derive dark colors** (Write 06 §4
OKLCH algorithm, run once, writes explicit values).

### 2.3 `fontsJson`

```jsonc
{ "v": 1,
  "heading": { "family": "Inter", "weight": 700 },
  "body":    { "family": "Inter", "weight": 400 },
  "mono":    { "family": "JetBrains Mono", "weight": 400 } }
```

Families must be in the bundled registry (§3); unknown families fall back by category with a
warning in the theme editor.

### 2.4 Appearance

- `Deck.appearance` selects `colorsJson.light` or `.dark` for **every** theme in the deck and the
  `backgroundJson` variants (§2.6); code blocks in `auto` palette mode follow the resulting
  background luminance (§2.9).
- Command `slides.deck.setAppearance {appearance}` (Inspector › Slide, Themes panel toggle); one
  undo step; collaborators see it live. Writes one column (`Deck.appearance`).
- **App theme ≠ deck appearance**: a dark app shows a light deck as light (04 §16). The editor
  offers (P2) *View › Preview in dark appearance* — a local, non-persisted override for checking
  both.
- Explicit hex colors don't change with appearance; the accessibility checker (03 §17.4) flags
  contrast problems in the active appearance, and the theme editor previews both.

### 2.5 `textStylesJson`

```jsonc
{ "v": 1,
  "styles": {
    "title":       { "font": "@heading", "size": 96,  "weight": 700, "lineHeight": 1.05, "letterSpacing": -0.02, "color": "theme:text1" },
    "subtitle":    { "font": "@body",    "size": 44,  "weight": 400, "lineHeight": 1.25, "color": "theme:text2" },
    "heading":     { "font": "@heading", "size": 64,  "weight": 700, "lineHeight": 1.1,  "color": "theme:text1" },
    "body":        { "font": "@body",    "size": 40,  "weight": 400, "lineHeight": 1.35, "color": "theme:text1", "spaceAfter": 16 },
    "body2":       { "font": "@body",    "size": 32,  "weight": 400, "lineHeight": 1.4,  "color": "theme:text2" },
    "caption":     { "font": "@body",    "size": 24,  "weight": 400, "lineHeight": 1.3,  "color": "theme:text2" },
    "quote":       { "font": "@heading", "size": 72,  "weight": 500, "lineHeight": 1.15, "italic": false, "color": "theme:text1" },
    "attribution": { "font": "@body",    "size": 28,  "weight": 600, "caps": "all", "letterSpacing": 0.08, "color": "theme:text2" },
    "bigNumber":   { "font": "@heading", "size": 280, "weight": 800, "lineHeight": 1.0,  "color": "theme:accent1" },
    "label":       { "font": "@body",    "size": 20,  "weight": 600, "caps": "all", "letterSpacing": 0.1, "color": "theme:text2" }
  },
  "lists": {
    "bullets":   ["disc", "dash", "circle", "dash", "circle", "dash", "circle", "dash", "circle"],   // per indent level 0–8
    "numbering": ["decimal", "lowerAlpha", "lowerRoman", "decimal", "lowerAlpha", "lowerRoman", "decimal", "lowerAlpha", "lowerRoman"],
    "bulletColor": "theme:accent1",
    "indentPerLevel": 56, "markerGap": 20, "levelSizeScale": 0.9                                   // each level 90 % of the previous (min body2 size)
  },
  "links": { "color": "theme:link", "underline": true },
  "inlineCode": { "background": "theme:bg2", "radius": 6, "paddingX": 8 }
}
```

Text style properties: `font`, `size` (su), `weight`, `italic`, `lineHeight`, `letterSpacing` (em),
`color`, `caps`, `align`, `spaceBefore`, `spaceAfter`. Paragraph `style` attributes and placeholder
defaults refer to these keys (02 §4.1).

### 2.6 `backgroundJson`

```jsonc
{ "v": 1,
  "fill": { "v": 1, "type": "solid", "color": "theme:bg1" },               // Fill; theme refs follow appearance
  "fillDark": null,                                                       // optional explicit dark fill (e.g. a different image)
  "overlay": null }                                                       // optional Fill drawn above (gradient vignette, texture)
```

The same shape is used by `SlideMaster.backgroundJson`, `SlideLayout.backgroundJson` and
`Slide.backgroundJson` (each null = inherit). Image backgrounds use uploaded files (`fileUuid`).

### 2.7 `shapeStyleJson` (defaults for new objects)

```jsonc
{ "v": 1,
  "text":  { "fill": {"type":"none"}, "stroke": {"type":"none"}, "textStyle": { "defaults": { "style": "body" }, "autofit": "resize" } },
  "shape": { "fill": {"type":"solid","color":"theme:accent1"}, "stroke": {"type":"none"},
             "textStyle": { "anchor": "middle", "defaults": { "style": "body", "color": "theme:bg1", "align": "center" } } },
  "line":  { "stroke": { "color": "theme:text2", "width": 4, "endArrow": "none" } },
  "icon":  { "stroke": { "color": "theme:text1" } },
  "quickStyles": [                                                         // 8 entries for the shape quick-style row (03 §6.3)
    { "fill": {"type":"solid","color":"theme:accent1"}, "textColor": "theme:bg1" },
    { "fill": {"type":"solid","color":"theme:accent2"}, "textColor": "theme:bg1" }, …,
    { "fill": {"type":"none"}, "stroke": {"color":"theme:accent1","width":4} },
    { "fill": {"type":"solid","color":"theme:accent1/alpha:0.15"}, "textColor": "theme:accent1" } ],
  "shadow": { "color": "#00000033", "blur": 32, "dx": 0, "dy": 16 }        // default when a user turns shadow on
}
```

### 2.8 `tableStyleJson`

```jsonc
{ "v": 1,
  "header":     { "fill": "theme:accent1", "text": { "color": "theme:bg1", "weight": 700 } },
  "body":       { "fill": "theme:bg1", "text": { "style": "body2" } },
  "bandFill":   "theme:bg2",
  "firstColumn":{ "text": { "weight": 700 } },
  "totalRow":   { "fill": "theme:bg2", "text": { "weight": 700 }, "borderTop": "3|solid|theme:text1" },
  "borders":    { "outer": "0|none|theme:text2", "horizontal": "1|solid|theme:text2/alpha:0.3", "vertical": "0|none|theme:text2" },
  "cellPadding": [12, 16, 12, 16], "radius": 12 }
```

### 2.9 `codeStyleJson` (consumed by [07](07-code-blocks.md))

```jsonc
{ "v": 1,
  "palettes": { "light": "wonky-light", "dark": "wonky-dark" },   // palette pair from `wonky_code` BuiltInPalettes (07 §2.5)
  "custom": null,                    // optional inline palettes {light: SyntaxPalette, dark: SyntaxPalette} overriding the ids
  "font": "@mono",                   // theme mono font (JetBrains Mono by default)
  "box": { "cornerRadius": 16, "shadow": "soft" },
  "chrome": "window" }               // default chrome for new code elements: none | tab | window | caption
```

A code element with `palette: "auto"` picks the light or dark palette of this pair by the
luminance of its effective background (07 §2.5), so switching the deck appearance (§2.4) — which
changes the slide backgrounds — switches code blocks automatically. Palettes use Write's 17 syntax
token keys (Write 06 §2.5) through the shared `wonky_code` package (D7). Built-in theme pairs:
Wonky `wonky-light/wonky-dark`, Paper `solarized-light/solarized-dark`, Midnight
`github-light/one-dark`, Swiss `monochrome-light/monochrome-dark`, Terminal
`github-light/github-dark`, Aurora `wonky-light/dracula`, Studio `wonky-light/one-dark`, Classic
`github-light/github-dark`, Mono `monochrome-light/monochrome-dark`, Botanical
`solarized-light/solarized-dark`.

### 2.10 `chartStyleJson` (consumed by [08](08-charts-from-sheets.md))

```jsonc
{ "v": 1,
  "palette": ["theme:accent1","theme:accent2","theme:accent3","theme:accent4","theme:accent5","theme:accent6"],
  "font": "@body", "textColor": "theme:text2", "titleStyle": "body2",
  "gridlines": "theme:text2/alpha:0.15", "axis": "theme:text2/alpha:0.5",
  "background": "transparent", "threeD": { "lighting": "soft", "floor": "theme:bg2" } }
```

---

## 3. Fonts

### 3.1 Shared font registry (suite addition)

Write (Write 06 §8) and Sheets each bundle fonts today. Slides needs display faces, and all three
apps plus the server PDF renderers must embed the **same files**. Proposal (suite agent, §10):
move the registry into a shared package **`packages/wonky_fonts`** (pure-Dart manifest +
`FontProvider` for server/core, Flutter `AssetFontRegistry` for apps, assets under
`packages/wonky_fonts/fonts/`, mirrored to `wonky_server/web/fonts/`). Static TTF instances only
(the `pdf` package supports neither variable fonts nor CFF OTF).

> Implemented (Drive 05 D-7): `packages/wonky_fonts` holds `FontRegistry`, `FontProvider` /
> `InMemoryFontProvider` and the `BundledFonts` manifest (`BundledFontFace`: family, weight,
> italic, file, `assetKey`; `facesOf`, `closestFace`, `licenseFiles`) of the 40 static TTFs in
> `fonts/` (the union of Write's and Sheets' sets, identical to `wonky_server/web/fonts/`).
> SL-6 added the shared Flutter loader to `wonky_app` (`package:wonky_app/fonts.dart`):
> `AssetFontRegistry` (`ensure(family, weight, italic)`, `ensureAll`, `generation`,
> `registerLicenses`) and `BundledAssetFontProvider` (a `FontProvider` over the package assets
> with per-category substitutes). Write keeps its `WriteFonts`/`AssetFontProvider` for now.
> Sheets loads the same package assets (`CellFonts`, `print_fonts.dart`; its own copy in `wonky_sheets/assets/fonts/` was dropped in CQ-64g).

### 3.2 Families available in Slides

The Write curated list (Write 06 §8.1: Inter, Source Sans 3, IBM Plex Sans, Open Sans, Work Sans,
Atkinson Hyperlegible Next, Montserrat, Liberation Sans, Source Serif 4, Merriweather, Lora, Libre
Baskerville, EB Garamond, Crimson Pro, Literata, IBM Plex Serif, Playfair Display, Liberation
Serif, JetBrains Mono, IBM Plex Mono, Source Code Pro, Courier Prime, Geist / Geist Mono) and
Sheets' Nunito, **plus display families for presentations**:

| Family | Category | Weights (static) | License | Used by built-in |
|--------|----------|------------------|---------|------------------|
| Instrument Serif | Serif (display) | 400 R/I | OFL 1.1 | Paper |
| Space Grotesk | Sans (display) | 400, 500, 700 | OFL 1.1 | Midnight |
| Sora | Sans (geometric) | 400, 600, 700 | OFL 1.1 | Aurora |
| Manrope | Sans | 400, 600, 700 | OFL 1.1 | Aurora |
| Bricolage Grotesque | Sans (display) | 400, 700, 800 | OFL 1.1 | Studio |
| Fraunces | Serif (display, static instances) | 400 R/I, 600, 700 | OFL 1.1 | Botanical |
| Bebas Neue | Sans (condensed display) | 400 | OFL 1.1 | — (P1) |
| DM Serif Display | Serif (display) | 400 R/I | OFL 1.1 | — (P1) |

Fallbacks (Noto families, CJK, emoji) as Write 06 §8.1. Emoji on screen use the platform color
emoji; PDFs embed monochrome Noto Emoji (10).

> **Implemented (SL-6) — bundled families only.** Slides draws only families with static TTFs
> in `wonky_fonts` (`SlidesFonts` in `wonky_slides_core/lib/src/theme/fonts/`): Open Sans,
> EB Garamond, JetBrains Mono, Roboto, Roboto Mono, Lato, Source Sans 3 (the renamed
> `WonkySansThree-*` files), Nunito, Montserrat and Merriweather. Any other family (the rest of
> the Write list and the display families of the table above, which are not bundled yet — TODO,
> Wonky Slides) is kept in the theme JSON with an `unknown_font` warning and drawn with the
> category substitute: sans → Open Sans, serif → Merriweather, mono → JetBrains Mono (category
> from the bundled list, else Write's `FontRegistry`, else the role). The built-in themes use
> bundled families (§6).

### 3.3 Loading

Fonts are declared as assets and registered on demand (Write 06 §8.3): when a resolved theme or a
run needs a family, `AssetFontRegistry.ensure(family, weight, italic)`; the canvas renders with
fallback metrics until ready (≤ 1.5 s) and re-lays out. Thumbnails wait for fonts (they are
cached). The presenter preloads all fonts of the deck before starting (10). Weight snapping:
nearest shipped weight, ties heavier.

### 3.4 Font picker

`FontPicker` (suite 02 §4.11) with sections **Theme fonts** (Heading, Body, Mono — inserting
`@heading`/`@body`/`@mono` refs), **Recent**, **All fonts** (by category). Each row previews the
family in its own face.

---

## 4. Built-in layouts

Every built-in master ships these 16 layouts (keys are stable; `SlideLayout.key`). Geometry is for
1920 × 1080 su (scaled proportionally for other sizes, §7); margins 120 su left/right.

| # | Key | Name | Placeholders (type: x, y, w, h · style · notes) |
|---|-----|------|--------------------------------------------------|
| 1 | `title` | Title | title: 120, 360, 1680, 240 · title · anchor bottom; subtitle: 120, 624, 1680, 144 · subtitle |
| 2 | `section` | Section header | label: 120, 336, 1680, 48 · label ("Section 1"); title: 120, 400, 1680, 200 · heading ×1.25; subtitle: 120, 624, 1680, 96 · subtitle |
| 3 | `titleBody` | Title and content | title: 120, 72, 1680, 144 · heading · anchor bottom; body: 120, 264, 1680, 720 · body · lists on |
| 4 | `titleOnly` | Title only | title as #3 |
| 5 | `twoColumns` | Two columns | title as #3; body: 120, 264, 816, 720; body: 984, 264, 816, 720 |
| 6 | `comparison` | Comparison | title as #3; label-heading: 120, 264, 816, 88 · heading ×0.6; body: 120, 368, 816, 616; same pair at x 984 |
| 7 | `bigNumber` | Big number | bigNumber: 120, 200, 1680, 440 · bigNumber · center; caption: 120, 680, 1680, 200 · subtitle · center |
| 8 | `quote` | Quote | quote: 240, 240, 1440, 480 · quote · anchor middle; attribution: 240, 760, 1440, 72 · attribution |
| 9 | `statement` | Statement | body: 240, 280, 1440, 520 · heading · center, anchor middle (one big sentence) |
| 10 | `imageFull` | Full-bleed image | picture: 0, 0, 1920, 1080 (fill/crop cover); caption: 120, 920, 1680, 96 · caption on a `theme:bg1/alpha:0.7` band (optional) |
| 11 | `imageLeft` | Image left | picture: 0, 0, 900, 1080; title: 1020, 120, 780, 240 · heading; body: 1020, 384, 780, 600 · body |
| 12 | `imageRight` | Image right | mirror of #11 |
| 13 | `code` | Code | title as #3 (heading ×0.8); code: 120, 248, 1680, 760 (07) |
| 14 | `chart` | Chart | title as #3; chart: 120, 248, 1680, 656 (08); caption: 120, 928, 1680, 72 · caption |
| 15 | `agenda` | Agenda | title as #3; body: 120, 264, 1680, 720 · body · numbered list default, `spaceAfter` 32 |
| 16 | `blank` | Blank | — (master decorations and slide number only) |

Master placeholders (every built-in master): **title** and **body** (style sources for all
layouts), **slideNumber** (1680, 992, 120, 48 · label · right), **footer** (120, 992, 1200, 48 ·
label), **date** (P2). Slide number and footer visibility come from `Deck.showSlideNumbers`,
`Deck.footerText`, `Deck.hideNumberOnTitle` (02 §3.1).

Built-in themes may restyle layouts (decorations, background, alignment) but keep the keys and
placeholder types, so layouts map 1:1 between themes.

> Implemented (SL-6, `BuiltInLayouts`): placeholder types for the table's roles — section
> *label* = `caption` (style `label`), comparison *label-heading*s = `subtitle` (style `heading`
> ×0.6), *statement* = `body` (style `heading`, no list), big-number caption = `caption`. Every
> built-in text placeholder has `insets: [0,0,0,0]`, `autofit: shrink`, `wrap: true` and an
> English prompt (`Click to add title`, …); style scales (`×1.25`, `×0.6`, `×0.8`) are written as
> explicit `defaults.size` computed from the theme style. Layout `title`/`body` placeholders refine
> the master's (`placeholderOf`); other types have no master placeholder. Geometry for other
> sizes (§7) is generated by `LayoutGeometry`: each axis maps piecewise-linearly, the 120 su
> margin bands become `120 × u` (u = shorter side / 1080, 1 for every preset) and the content
> band stretches, so 16:9 is unchanged, landscape presets keep 120 su margins and the 1080 su
> grid, and full-bleed pictures always cover the slide.

---

## 5. Masters and placeholders

### 5.1 Placeholder definition (layouts and masters)

A placeholder is a `SlideElement` owned by a layout or master with `placeholderType` set. Its
fields define: frame, `textStyleJson` (box defaults incl. paragraph `style` key), `fillJson`,
`strokeJson`, `dataJson` (picture fit; code language; chart defaults), and **prompt text** stored
as the placeholder's `text` (rendered as the prompt on empty instances, 03 §6.2).

Layout placeholders refine master placeholders of the same type via `placeholderOf` (null fields
inherit from the master's).

### 5.2 Instances on slides

- Applying a layout to a slide creates one instance per layout placeholder (except `slideNumber`,
  `footer`, `date`, which are drawn from the layout/master directly and are not instantiated) with
  id `SlidesIds.placeholderInstanceId(slideId, layoutPlaceholderId)` (02 §2.1), `placeholderOf` =
  the layout placeholder, frame/style **null** (inherit), `text` null (empty → prompt).
- Editing an instance writes only the changed columns: typing writes `text`; moving writes `x,y`
  (materializing the frame: once any frame column is non-null, **all four** frame columns are
  written, so the frame no longer half-inherits).
- *Reset to layout* (`slides.element.resetPlaceholder`) sets frame/style columns back to null
  (keeps text).

### 5.3 Effective values

`PlaceholderResolver` (core): for each null column of an instance, walk `placeholderOf` to the
layout placeholder, then to its master placeholder, then theme defaults for the type
(title → `title`/`heading` style, body → `body`, etc.). Changing a layout or master therefore
updates all inheriting instances immediately for everyone.

> Implemented (SL-6): `PlaceholderResolver` works on `PlaceholderNode`s (the placeholder columns
> of an element) through a lookup, so `DeckModel` (SL-7) and tests feed it the same way. Scalar
> columns take the first non-null value along the chain (frame columns per field — writers keep
> all four together); `textStyleJson` is merged key-wise from the master to the instance
> (`defaults` merged by attribute); the default style key comes from the merged `defaults.style`,
> else the type (`SlidePlaceholderType.defaultStyleKey`), else `body`. A dangling `placeholderOf`
> uses the master placeholder of the same type, else a 10 % inset frame (02 §10). The §5.4
> matching is `LayoutRemapper.remap` (returns re-point / materialize / delete / create lists for
> the planner); the §9 layout choice is `LayoutMatcher.match` (same key, else the layout sharing
> the most instantiated placeholder types with the fewest extras, else `titleBody` for slides with
> placeholders or `blank`).

### 5.4 Changing a slide's layout

`slides.slide.applyLayout {slideIds, layoutId}` (planner `SetSlideProps` with remap):

1. For each instance on the slide, find the new layout's placeholder of the **same type**,
   matching in order (1st body → 1st body, 2nd body → 2nd body). Matches are **re-pointed**
   (`placeholderOf` updated; frame/style columns that were null stay null → new geometry).
2. Instances without a match become **regular elements in place**: their effective frame and
   style are materialized into their columns, `placeholderOf = null` (content never disappears).
   Empty unmatched instances are deleted.
3. New layout placeholders without an instance get new (empty) instances with deterministic ids.
4. `Slide.layoutId` is written. One undo step "Apply layout".

`slides.slide.resetToLayout {slideIds}`: every instance's frame/style → null, deleted placeholder
instances restored (deterministic ids revive tombstones), unmatched materialized elements kept.

> Implemented (SL-7): `SetSlideProps(layoutId)` / `ResetSlideToLayout` in `SlidesPlanner`.
> Instances are matched in the old layout's placeholder order, then reading order; materialized
> elements also get `placeholderType = null` (they are regular elements); an instance counts as
> empty when its text is blank and it holds no code states, table axes, chart link or image
> payload. When a re-pointed instance already holds the deterministic id of a new target, the
> new instance gets a fresh id. *Apply theme* is `ApplyThemeToSlides` (empty `slideIds` = all;
> `setDefault` null = write `Deck.themeId` when every slide is covered), matching each slide's
> layout with `LayoutMatcher` among the theme's non-hidden layouts unless mapped explicitly;
> built-in imports (`ImportTheme`) insert only the rows of the deterministic copy that don't
> exist, so repeated applies merge and keep edits.

### 5.5 Slide numbers, footer, date

Rendered from master/layout `slideNumber`/`footer`/`date` placeholders when enabled: number =
position among **non-skipped** slides starting at `Deck.firstSlideNumber` (skipped slides show no
number; 10 and the navigator show the same numbering), footer = `Deck.footerText`. Hidden on
slides whose layout key is `title` when `hideNumberOnTitle`, and when `hideMasterElements` is set.

---

## 6. Built-in themes

Ten themes, each with hand-tuned light and dark schemes (contrast-checked, §11). `appearance`
column = the scheme new decks start with (user default overrides). Fonts are heading / body /
mono (mono is JetBrains Mono unless stated).

| Key | Name | Character | Fonts (as designed) | Fonts (shipped, bundled — SL-6) | Default appearance |
|-----|------|-----------|-------|------|--------------------|
| `wonky` | **Wonky** (default) | Clean, modern product style; generous whitespace; rounded cards | Inter 700 / Inter 400 | Open Sans 700 / Open Sans 400 | light |
| `paper` | **Paper** | Editorial, warm paper tone, elegant serif titles | Instrument Serif 400 / Inter 400 | EB Garamond 400 / Lato 400 | light |
| `midnight` | **Midnight** | Deep navy with electric accents and a soft radial glow; keynote-stage feel | Space Grotesk 700 / Inter 400 | Lato 700 / Lato 400 | dark |
| `swiss` | **Swiss** | International style: huge left-aligned titles, red rule, strict grid | Work Sans 700 / Work Sans 400 | Roboto 700 / Roboto 400 | light |
| `terminal` | **Terminal** | Developer talks: GitHub-like palette, mono headings, code-first layouts | JetBrains Mono 700 / IBM Plex Sans 400 | JetBrains Mono 700 / Source Sans 3 400 | dark |
| `aurora` | **Aurora** | Gradient backgrounds, glassy cards, vivid accents | Sora 600 / Manrope 400 | Nunito 700 / Open Sans 400 | dark |
| `studio` | **Studio** | Pitch-style bold color blocks and playful display type | Bricolage Grotesque 800 / Inter 400 | Montserrat 700 (800 snaps to 700) / Lato 400 | light |
| `classic` | **Classic** | Corporate navy, serif headings, restrained | Source Serif 4 600 / Source Sans 3 400 | Merriweather 700 / Source Sans 3 400 | light |
| `mono` | **Mono** | Minimal grayscale with a single blue highlight | IBM Plex Sans 600 / IBM Plex Sans 400 / IBM Plex Mono | Source Sans 3 600→700 / Source Sans 3 400 / Roboto Mono | light |
| `botanical` | **Botanical** | Natural greens and clay, soft serif display | Fraunces 600 / Nunito 400 | EB Garamond 600 / Nunito 400 | light |

The shipped fonts use only bundled families (§3.2); when the display families are bundled
(TODO, Wonky Slides) the built-ins move to the designed fonts with a version bump
(`builtin:<key>@2`; existing decks keep their copies).

Palettes (`bg1, text1, bg2, text2 | accent1–6 | link`):

| Theme | Light | Dark |
|-------|-------|------|
| Wonky | `#FFFFFF #0F172A #F1F5F9 #475569 \| #6366F1 #06B6D4 #10B981 #F59E0B #EF4444 #A855F7 \| #4F46E5` | `#0B1020 #F8FAFC #161C2E #94A3B8 \| #818CF8 #22D3EE #34D399 #FBBF24 #F87171 #C084FC \| #A5B4FC` |
| Paper | `#FBF8F3 #1C1917 #F3EDE4 #57534E \| #C2410C #4D7C0F #1E40AF #B45309 #9D174D #0F766E \| #C2410C` | `#1A1714 #F5F0E8 #26211C #A8A29E \| #FB923C #A3E635 #93C5FD #FCD34D #F9A8D4 #5EEAD4 \| #FDBA74` |
| Midnight | `#F8FAFC #0F172A #E2E8F0 #475569 \| #0891B2 #C026D3 #65A30D #D97706 #E11D48 #7C3AED \| #0E7490` | `#070B1A #E2E8F0 #11162B #94A3B8 \| #22D3EE #E879F9 #A3E635 #FBBF24 #FB7185 #A78BFA \| #67E8F9` |
| Swiss | `#FFFFFF #0A0A0A #F5F5F5 #525252 \| #E30613 #0A0A0A #0057B8 #FFD500 #00A651 #737373 \| #0057B8` | `#0A0A0A #FAFAFA #171717 #A3A3A3 \| #FF3B30 #FAFAFA #4D9FFF #FFE14D #34D399 #A3A3A3 \| #4D9FFF` |
| Terminal | `#FFFFFF #1F2328 #F6F8FA #59636E \| #1A7F37 #0969DA #8250DF #BC4C00 #CF222E #9A6700 \| #0969DA` | `#0D1117 #E6EDF3 #161B22 #8B949E \| #3FB950 #58A6FF #BC8CFF #F0883E #FF7B72 #D29922 \| #58A6FF` |
| Aurora | `#F5F3FF #1E1B4B #FFFFFFB3 #4C4F6B \| #DB2777 #2563EB #059669 #D97706 #7C3AED #DC2626 \| #2563EB` | `#120F33 #F8FAFC #FFFFFF14 #CBD5E1 \| #F472B6 #60A5FA #34D399 #FBBF24 #A78BFA #F87171 \| #93C5FD` |
| Studio | `#FFF9F0 #111827 #FFE8CC #4B5563 \| #F24B27 #1D4ED8 #FFC53D #0F766E #F9A8D4 #111827 \| #1D4ED8` | `#14110F #FFF7ED #2A2118 #D6CFC4 \| #FF7A59 #6B8CFF #FFD166 #2DD4BF #F9A8D4 #FFF7ED \| #8FA8FF` |
| Classic | `#FFFFFF #1F2A37 #F2F5F9 #4B5563 \| #1F3A5F #2E6DA4 #D9822B #5B8C5A #8E5572 #C9A227 \| #2E6DA4` | `#0F1A2A #F1F5F9 #18263A #A9B4C2 \| #7FA7D9 #5FA8E8 #F2A65A #8FC18E #C48BB0 #E6C65C \| #8EC1F0` |
| Mono | `#FFFFFF #111111 #F2F2F2 #6B6B6B \| #111111 #4D4D4D #8C8C8C #BFBFBF #2563EB #DC2626 \| #2563EB` | `#111111 #F5F5F5 #1C1C1C #A3A3A3 \| #F5F5F5 #C7C7C7 #8C8C8C #5C5C5C #60A5FA #F87171 \| #60A5FA` |
| Botanical | `#F4F1E8 #22302A #E7E2D3 #5B6B61 \| #2F6B4F #D97757 #E8B04B #7A9E9F #8C5E8C #3B5BA5 \| #2F6B4F` | `#18201B #EEF0E6 #222C25 #A7B3A9 \| #6FBF95 #F0997B #F2C76B #9CC3C4 #C49AC4 #8EA7E0 \| #6FBF95` |

Two light-scheme values were darkened during implementation to pass the §11 contrast checks:
Midnight `link` `#0891B2` → `#0E7490` (3.5 → 5.1:1 on bg1) and Studio `accent1` `#FF5A36` →
`#F24B27` (2.96 → 3.45:1).

Design notes per theme (decorations and layout styling live in the built-in definitions under
`builtins/themes/<key>.dart` — Dart, like Write's built-ins — which `BuiltInThemeDef.build`
expands into a `ThemePackage` (theme row + master + 16 layouts + elements, JSON via
`ThemePackage.toJson`/`fromJson`) for a slide size; `BuiltInThemes.package(key, size:)`):

- **Wonky**: title slide with a large accent1 → accent6 gradient blob (shape, bottom-right, 20 %
  opacity); `bigNumber` in accent1; cards (`bg2`, radius 32) in `comparison`.
- **Paper**: thin `text1` hairline under titles; quote layout with an oversized “ in accent1;
  images with 12 su radius.
- **Midnight**: background `bg1` + radial gradient overlay (accent1 at 12 % from top-left);
  titles with tight tracking; section headers with accent2 underline glow (effects glow).
- **Swiss**: 24 su red (`accent1`) bar at the top-left of title and section layouts; titles
  left-aligned 120 su; no rounded corners anywhere.
- **Terminal**: a `›_` label in accent1 before section titles; code layout uses `chrome: window`
  with traffic-light dots; body in IBM Plex Sans; code palettes `github-light`/`github-dark`.
- **Aurora**: background gradient (`#120F33 → #2A1F6B` dark, `#F5F3FF → #FDF2F8` light) with two
  blurred color orbs; glass cards (`bg2` translucent + blur effect).
- **Studio**: section layout = full-bleed accent block (accent1 fill, `bg1` text); title slide
  with oversized display type; playful 48 su radius cards.
- **Classic**: navy title band on title/section layouts, serif headings, footer rule.
- **Mono**: no decorations, strong typographic hierarchy; accent5 (blue) for highlights only.
- **Botanical**: soft organic blob shapes in `bg2`, serif display headings, clay accent rules.

Every built-in ships complete `codeStyleJson` (light/dark), `chartStyleJson`, `tableStyleJson` and
`shapeStyleJson` consistent with its palette.

Built-in definitions are versioned (`builtin:<key>@<version>`); a new version does not touch
existing decks (they hold copies); the Themes panel offers *Update to the latest version* (P2)
when a deck's copy is older.

---

## 7. Slide sizes

| Preset (`SlideSizePreset`) | Size (su) | Notes |
|----------------------------|-----------|-------|
| `widescreen16x9` | 1920 × 1080 | Default |
| `standard4x3` | 1440 × 1080 | |
| `wide16x10` | 1728 × 1080 | |
| `square` | 1080 × 1080 | Social |
| `portrait9x16` | 1080 × 1920 | Stories (P1) |
| `a4` | 1527 × 1080 | A4 landscape ratio (297 × 210 mm) |
| `letter` | 1397 × 1080 | US Letter landscape (11 × 8.5 in) |
| `custom` | 320–7,680 su per side, aspect 1:4…4:1 | Units su / px / in (96 px = 1 in on screen; PDF uses su/2 pt) / cm |

Height stays 1080 su for landscape presets so font sizes mean the same across sizes.

**Changing the size** (`slides.deck.setSize {preset, width, height, scaleContent}`, Page setup
dialog 04 §13.1) — one undo step:

- **Scale content** (default): every frame on slides, layouts and masters is mapped by a uniform
  scale `s = min(w'/w, h'/h)` and centered (letterboxed content keeps aspect); font sizes, stroke
  widths and insets in explicit columns are scaled by `s` (theme text style sizes too, by writing
  the theme JSON); built-in layout placeholders are **re-generated** for the new aspect from the
  layout library (keys known) instead of letterboxed.
- **Don't scale**: frames keep su values; content may overflow or leave space.
- Large decks: the plan can exceed 5,000 row changes → chunked transactions with progress (still
  one undo step, 02 §12.2).

> Implemented (SL-6): `SlideSize` / `SlideSizeKind` (presets, `validate` with the page-setup
> messages, `pdfPageSize`), `SlideUnits` (1 in = 144 su, 1 px = 1.5 su, 1 cm = 144/2.54 su),
> `SlideSizeScaling` (`scale`, centering `dx/dy`, `mapRect`, `scaleFontSize` clamped to
> 6–800 su), `ThemeTextStyles.scaled` / `BoxTextStyle.scaled` / `SlideStroke.scaled`, and
> `BuiltInThemes.package(key, size:)` for re-generated built-in layouts (custom sizes larger than
> the presets also scale the theme text styles by `u`).

---

## 8. Editing masters, layouts and themes

### 8.1 Master mode

`slides.view.setMode {mode: masters, layoutId?}` (View › Edit masters and layouts, Slide › Edit
masters and layouts, *Edit layout* from the Slide tab) switches the editor:

- **Navigator** shows the deck's themes as sections → masters → their layouts (tree,
  `WonkyTreeView`), each with a thumbnail; usage badge on layouts ("Used by 12 slides"); unused
  themes dimmed.
- **Canvas** edits the selected master or layout's elements with all canvas tools (03); a banner
  "Editing layout 'Title and content' of theme Wonky — changes apply to 12 slides · Done".
- **Insert › Placeholder ▸** (`slides.layout.insertPlaceholder {type}`) adds placeholders to a
  layout/master.
- **Inspector**: Format tab as usual; the Slide tab becomes **Layout** (name, background, hide
  master elements, hidden-in-picker) / **Master** (name, background); a **Theme** tab appears
  (§8.4).
- Exit with **Done** (or Esc on the canvas with nothing selected, or `slides.view.setMode
  {mode: normal}`).

### 8.2 Layout and master commands

| Command | Effect |
|---------|--------|
| `slides.layout.add {masterId, basedOn?}` | New layout (copy of `basedOn` or blank with title) |
| `slides.layout.duplicate {layoutId}` / `rename {layoutId, name}` / `move {layoutId, to}` | |
| `slides.layout.delete {layoutId}` | Disabled while slides use it (reason "Used by 3 slides — apply another layout first"); P1: offer "Apply *Title and content* to those slides and delete" |
| `slides.layout.setBackground {layoutId, background?}` | |
| `slides.layout.setHideMasterElements {layoutId, value}` / `toggleHidden {layoutId}` | |
| `slides.layout.insertPlaceholder {layoutId?, type}` | |
| `slides.master.add {themeId}` (P1) / `duplicate` / `rename` / `delete` (not the last) / `setBackground` | |

All are one undo step each (planner ops on masters/layouts/elements, 02 §12.1).

### 8.3 Live propagation and collaboration

Edits to masters/layouts are normal synced writes; every slide inheriting from them updates for
everyone immediately (P6). Collaborators in normal mode see a toast-free update; presence shows
"Editing layouts" (09). Soft locks apply to placeholder prompt text like any text body.

### 8.4 Theme tab (theme editor)

In master mode, Inspector › **Theme** edits the theme of the selected master:

| Section | Controls | Writes |
|---------|----------|--------|
| Colors | Light/Dark segmented; 11 swatches (`WonkyColorPicker`) with names and contrast badges (text1/bg1, text2/bg1, accent on bg1); *Derive dark colors*; custom colors list (add/rename/remove) | `colorsJson` |
| Fonts | Heading / Body / Mono `FontPicker` + weight select | `fontsJson` |
| Text styles | List of the 10 styles with live samples; each expands to font/size/weight/line height/letter spacing/color/caps/spacing; list bullets/numbering per level | `textStylesJson` |
| Background | Default background fill + dark override | `backgroundJson` |
| Objects | Default text/shape/line/icon styles; quick styles editor (8); default shadow | `shapeStyleJson` |
| Tables, Code, Charts | Style editors per §2.8–2.10 with previews in both appearances | `tableStyleJson`, `codeStyleJson`, `chartStyleJson` |
| Theme | Name, *Duplicate theme*, *Reset to built-in* (if `sourceKey` is a built-in) | `name`, … |

Each committed control is one undo step writing only that JSON column (whole-value LWW, 02 §14).
`slides.theme.edit` opens master mode on the deck's default theme with the Theme tab.

> **As built (SL-28).** *Surfaces:* `SlideResolver.resolve(id)` also resolves a layout or master
> id as its editing surface (`ResolvedSlide.surface` = `layout` | `master`: the owner's own
> elements incl. placeholder definitions are the editable `elements`, a layout draws its
> master's decorations and the master's slide number/footer it doesn't redefine as inherited
> `masterElements`; slide number / footer fields read `‹#›` / the deck footer). The editor's
> `surfaceId` / `surfaceKind` (`DeckEditorController`) is the current slide in Normal view and
> the edited layout/master in masters mode, so the canvas, selection, text editing, crop/table
> modes, inserts (`InsertElements.ownerKind`) and pastes (`PasteElements.ownerKind`, additive)
> work on layouts and masters unchanged; picture placeholders of layouts are never *filled*.
> *Mode:* `slides.view.setMode {mode: masters, layoutId? | masterId?}` (default: the current
> slide's layout); editors in Editing mode only (Viewing mode or losing edit access leaves it);
> Esc on the canvas with nothing selected = `slides.masters.exit`. *Navigator:*
> `features/masters/MastersNavigator` — a list, not `WonkyTreeView` (rows carry live
> thumbnails): theme section headers (default badge, unused themes dimmed), master rows, layout
> rows with usage count and a hidden badge, *New layout* per master; click / Up / Down edit,
> Enter focuses the canvas, F2 renames, Delete deletes, right-click / ⋮ / Shift+F10 open
> `context.mastersLayout` / `context.mastersMaster`. A banner names the layout/master, its theme
> and the slides it affects, with **Done**. The canvas outlines every placeholder (dashed, with
> a type label above it, `MastersCanvasLayer`). *Inspector:* Slide tab → **Layout** / **Master**
> (Properties: name, usage, *Hide master objects*, *Hidden in layout picker*, duplicate/delete
> / new layout; Background: solid color + *Use master/theme background*; Placeholders: list,
> click selects, *Add…*); **Theme** tab = the theme editor (`features/themes/editor/`).
> *Commands:* all of §8.2 incl. `slides.master.add` (P1) and `slides.layout.move {to |
> direction}` (writes `sortKey` through `UpdateMasterOrLayout`, which accepts `sortKey` now);
> `slides.layout.delete` of a used layout offers *Apply “Title and content” to those slides and
> delete* (P1; `replaceWith` for MCP; agents without it get "Used by n slides — apply another
> layout first"), the last layout of a master can't be deleted. *Insert placeholder* refines the
> master's placeholder of the type on layouts (its frame, styles inherited) or gets the §4
> geometry and the type's text style; prompts come from the ARB (`placeholderPrompt`); `date`
> is not offered (P2); placeholders added to a layout reach existing slides on *Reset slide to
> layout* or when the layout is applied (as Google Slides). *Theme editor:* `slides.theme.update
> {themeId?, name?, columns}` (whole JSON columns, validated by the planner), `slides.theme.
> deriveDarkColors` (`ThemeDarkDeriver` in core: Write 06 §4 on the 11 keys, repaired to the
> §11 pairs), `slides.theme.resetToBuiltIn` (JSON columns only, name, masters and layouts kept).
> Sections: Theme (name, based-on, usage, *Duplicate*, *Reset to built-in*, *Set as default*),
> Colors (Light/Dark switch, 11 hex swatches with contrast badges for text1/text2/accent1/link
> on bg1, *Derive dark colors*, custom colors add/rename/remove), Fonts (family + weight per
> role, fallback note), Text styles (10 rows with live samples in the theme's face and color;
> expand → font, size, weight, italic, line height, letter spacing, color, capitals, space
> before/after; Lists: bullet and numbering for levels 1–3, bullet color, indent), Background
> (solid fill, dark override), Objects (text box fill; shape fill/border/text color; line color
> and weight; icon color; default shadow color/blur/offset; the 8 quick styles' fill and text
> color), Tables (header fill/text, body fill, banded rows, radius; light/dark preview), Code
> (light/dark palette with swatches, chrome, radius, shadow), Charts (6 series colors, text,
> gridlines, axis, 3D lighting; light/dark preview). `slides.theme.edit {themeId?}` edits the
> current slide's theme (else the default) — keeping the edited layout when it already belongs
> to it, else showing the theme's master. Not built (TODO.md): gradient/image backgrounds,
> levels 4–9 of the list markers, link/inline-code styles, per-type text box defaults beyond
> the fill, code previews with real code, the *Preview in dark appearance* toggle (P2).

---

## 9. Themes panel (apply, import, manage)

Side panel `slides.panel.themes` (Slide › Change theme…, toolbar *Theme*):

```
┌ Themes ────────────────────────────── ⌄ ┐
│ Appearance  [ Light | Dark ]             │
│ In this presentation                     │
│  ▣ Wonky (default)      used by 24 ⋮    │
│  ▣ Classic              used by 3  ⋮    │
│ Built-in themes                          │
│  [Wonky][Paper][Midnight][Swiss] …       │  thumbnails (title slide in current appearance)
│ [ Import theme from a presentation… ]    │
│ Apply to: ( ) Selected slides (•) All    │
└──────────────────────────────────────────┘
```

| Action | Command | Behavior |
|--------|---------|----------|
| Click a built-in theme | `slides.theme.apply {source: {builtin: key}, scope: all\|selected}` | Copies the built-in tree into the deck (deterministic ids — repeated applies merge), sets `Deck.themeId` (scope all), remaps each slide's layout **by key** (else best placeholder-signature match, else `titleBody`/`blank`) per §5.4; explicit styles are kept. One undo step "Apply theme". Applying to *selected slides* keeps `Deck.themeId`. |
| Click a deck theme | same with `{source: {deckThemeId}}` | Re-applies an existing theme (no copy) |
| Import theme from a presentation… | `slides.theme.import {itemUuid, themeId}` → Drive picker (presentations) → list of that deck's themes with previews | Copies the theme tree with `themeCopyId(deck, "deck:<itemUuid>:<themeId>")`; uploaded background/logo images are re-homed (`FileEndpoint.copyToItem`, quota); then offers *Apply to all slides*. Needs the source deck on the device or online. |
| ⋮ › Rename / Duplicate / Set as default / Edit / Remove | `slides.theme.rename`, `duplicate`, `setDefault`, `edit`, `delete` | Remove is disabled while slides use the theme; *Remove unused themes* (`slides.theme.removeUnused`) at the bottom when any exist |
| Appearance toggle | `slides.deck.setAppearance` | §2.4 |

Previews render the theme's `title` layout in the current appearance via `SlideStage` thumbnails
(cached per theme hash).

Saving a theme to a personal **theme library** (like Write's) is P2: v1 shares themes through
templates and *Import theme from a presentation*.

> **As built (SL-17).** Panel layout top to bottom: *Appearance* (Light | Dark buttons), *Apply
> to* (All slides / Selected slides — panel state, default All), *In this presentation*
> (preview card of the theme's `title` layout with its name, *Default* badge, "Used by n
> slides", ⋮ = Rename… / Duplicate / Set as default / Edit theme… (SL-28) / Remove; a click
> applies), *Remove unused themes* (every unused theme except the default, one step), *Built-in
> themes* (2–3 columns of previews; the deck's default copy is outlined), *Import theme from a
> presentation…*. Previews are in-memory preview decks (title layout with the theme name and a
> subtitle; layout galleries show each layout with its prompts) in the deck's appearance.
> `slides.theme.apply` takes `builtin` or `themeId` (also `source: {builtin | deckThemeId}`),
> `scope` (`all` | `selected`) or explicit `slideIds`. `slides.theme.import {itemUuid, themeId,
> apply}` reads the source deck online through the new `slidesThemes.list` endpoint (the
> on-device source path is `TODO.md`); several themes → a select dialog (names + usage, no
> previews); after the import a toast offers *Apply to all slides*. *Duplicate theme* copies
> every row with fresh ids ("<name> copy", `sourceKey` null). Inspector › Slide › Background
> sets solid colors (theme colors first) and *Reset to layout background*; gradients/images
> are not editable there yet. *Slide numbers and footer* (04 §13.3) and Page setup (04 §13.1;
> units su/px/in/cm, the preview letterboxes with *Scale content* and clips with *Don't
> scale*) are built; `slides.deck.setSize {preset, width, height, scaleContent}` and
> `slides.deck.setNumbering` are the MCP-friendly forms of the dialogs.

---

## 10. Additions to 02-data-model and suite specs

| # | Addition |
|---|----------|
| A-05-1 | JSON schemas of `DeckTheme.colorsJson`, `fontsJson`, `textStylesJson`, `backgroundJson`, `shapeStyleJson`, `tableStyleJson`, `codeStyleJson` (palette pair — satisfies 07 A-07-4), `chartStyleJson` as §2 (`v: 1`). |
| A-05-2 | Built-in layout keys (§4) and theme keys (§6) are stable identifiers (MCP, templates, AI). |
| A-05-3 | **Suite (fonts)**: shared `packages/wonky_fonts` registry used by Write, Sheets, Slides and the server; Slides display families of §3.2 added (static TTF, OFL). |
| A-05-4 | `UserPreferences.slidesDefaults.defaultThemeKey` / `defaultAppearance` / `defaultSize` (04 A-04-2). |

## 11. Acceptance criteria

1. Each built-in theme passes contrast checks in both schemes: text1/bg1 ≥ 7:1, text2/bg1 ≥ 4.5:1,
   accent1 on bg1 ≥ 3:1, link/bg1 ≥ 4.5:1 (core test over the built-in JSON).
2. Switching `Deck.appearance` re-colors all theme-referenced colors, backgrounds and code blocks
   (auto) on every slide in one undo step; explicit colors don't change; a collaborator sees it
   within 3 s.
3. Applying another built-in theme to all slides remaps layouts by key, keeps all content, keeps
   explicit styles; undo restores the previous theme fully; applying the same theme on two
   offline devices yields a single theme copy after sync.
4. Changing a layout's title placeholder position moves the title on every slide using that
   layout whose title frame isn't materialized; materialized ones stay.
5. Applying a layout without a matching placeholder keeps the content as regular elements in
   place.
6. Page setup 16:9 → 4:3 with *Scale content* letterboxes slide content, regenerates built-in
   layouts' placeholders, and is one undo step.
7. Importing a theme from another deck brings masters, layouts, decorations and background images
   (re-homed, quota-counted).
8. All renderers (canvas, thumbnail, present, PDF) resolve identical styles for the same theme
   (golden comparison of a reference deck per built-in theme in both appearances).

## 12. Tests

- Core: theme validator/migrations, resolver (cascade, appearance, color modifiers `lum`/`alpha`,
  custom colors), placeholder resolver and layout-remap algorithm (all §5.4 cases), size change
  scaling, built-in theme contrast test, deterministic copy ids.
- Command tests: every command of §8.2, §9 and `slides.deck.setAppearance/setSize` execute →
  undo → redo.
- Goldens: every built-in theme × 16 layouts × light/dark (thumbnail size), theme editor panel in
  app light/dark.
- Multi-client harness: concurrent layout edit vs slide edit; concurrent theme apply on two
  offline devices; layout delete vs layout apply race (maintenance §02 §10).
