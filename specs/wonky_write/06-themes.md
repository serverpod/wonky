# Write 06 · Themes and the Theme Editor

Wonky Write content is **Markdown only** ([02-document-model.md](02-document-model.md)): no fonts,
colors, sizes, alignment or spacing are stored in the Delta. **All visual appearance comes from a
theme.** A theme is a named, versioned style sheet that maps every Markdown element (and the page
around it) to concrete visual styles, in a **light** and a **dark** variant. The same theme drives
the editor, the read-only renderers (version history, previews), print and every exporter (PDF,
HTML, DOCX, ODT, RTF, EPUB), so a document looks the same everywhere.

Related specs: suite design system [../02-design-system.md](../02-design-system.md)
(app tokens, `WonkyColorPicker`, `FontPicker`, `WonkyNumberStepper`), commands & undo
[../08-commands-and-undo.md](../08-commands-and-undo.md) (domain `write.theme`),
MCP [../09-mcp.md](../09-mcp.md), editor [04-editor.md](04-editor.md), Wonky Markdown elements
[11-wonky-markdown.md](11-wonky-markdown.md) §8, screens
& menus [05-screens-menus-toolbar.md](05-screens-menus-toolbar.md), exports
[07-import-export-print.md](07-import-export-print.md).

---

## 1. Concepts

| Term | Meaning |
|------|---------|
| **Theme** | A `WriteThemeData` (pure Dart, JSON-serializable) stored as a `WriteTheme` row. Has `light` and `dark` variants. |
| **Built-in theme** | Read-only theme shipped with the server (`isBuiltin = true`, `ownerId = null`), stable UUID. Can be duplicated, never edited. |
| **User theme** | Theme in a user's personal library (`ownerId = me`). Only the owner can edit it. |
| **Document theme** | `Document.themeId` — the theme assigned to a document. `null` = **"Use my default theme"**: each viewer sees their own default (from `UserPreferences.writeDefaults.defaultThemeId`, falling back to *Wonky Default*). |
| **Variant** | `light` or `dark`. Chosen by the app theme (system/light/dark) for on-screen rendering; exports/print use `light` unless the user ticks *Use dark theme* ([../02-design-system.md](../02-design-system.md) §8). |
| **Theme palette** ("Theme colors") | Named colors (`text`, `accent`, `page`, …) defined per variant. Element styles reference palette entries (`"@accent"`) so a dark variant mostly only redefines the palette. |
| **Font role** | `body`, `heading`, `mono`. Elements reference roles (`"@heading"`) or a concrete family name from the curated font list (§8). |
| **Resolved theme** | `ResolvedWriteTheme`: the fully cascaded, unit-normalized, variant-specific style values consumed by renderers. Never persisted. |

Principles:
1. **Presentation only.** A theme can never change content or Markdown semantics. Theme-level
   choices that look like content (justified text, heading numbering, page break before H1) are
   allowed because they apply uniformly to all elements of a kind and are dropped by the
   Markdown export.
2. **Live link.** Documents reference a theme by UUID; saving a theme updates every document that
   uses it, for every collaborator, in real time (§5.3).
3. **One model, many renderers.** `WriteThemeData` → `ResolvedWriteTheme` happens in
   `wonky_write_core` (pure Dart). Renderers (super_editor `Stylesheet`, PDF, CSS, DOCX styles, …)
   are thin mappers over `ResolvedWriteTheme`.

---

## 2. Theme JSON schema (`schemaVersion: 1`)

### 2.1 Value types

| Type | JSON form | Notes |
|------|-----------|-------|
| `Length` | string `"<number><unit>"`, units `pt`, `px`, `em`, `mm`, `in`, `%` | `1pt = 4/3 px` (CSS convention). The editor renders 1 CSS px = 1 logical pixel at 100 % zoom, so `11pt` text is 14.67 px on screen. `em` is relative to the element's own resolved font size (for `fontSize`: relative to body size). `%` only for widths (relative to content width). |
| `ColorRef` | `"#RRGGBB"`, `"#RRGGBBAA"`, `"@<paletteKey>"`, `"transparent"`, or `null` (= inherit) | Palette refs resolve per variant. |
| `FontRef` | `"@body"`, `"@heading"`, `"@mono"`, or a family name from the font registry | Unknown families fall back to the role default with a warning. |
| `FontWeight` | integer `100`…`900` | Snapped to the nearest weight shipped for the family (§8.2). |
| `LineHeight` | number (multiplier of font size), e.g. `1.5` | |
| `Border` | `{"width": Length, "style": "none"\|"solid"\|"dashed"\|"dotted"\|"double", "color": ColorRef}` | |
| `Edges<T>` | `{"top": T, "right": T, "bottom": T, "left": T}` (any key optional) or a single `T` for all four | |
| `CaseTransform` | `"none"\|"uppercase"\|"lowercase"\|"capitalize"\|"smallCaps"` | See §6.4 for editor implementation. |
| `Align` | `"left"\|"center"\|"right"\|"justify"` | `right`/`center` only for headings, captions, header/footer slots. RTL documents mirror `left`↔`right` (§6.6). |

### 2.2 Top-level structure

```jsonc
{
  "schemaVersion": 1,
  "name": "Classic Serif",
  "description": "Traditional book typography.",
  "basedOn": "builtin:classic-serif",          // provenance only (informational)
  "fonts": { "body": "Source Serif 4", "heading": "Source Serif 4", "mono": "JetBrains Mono" },
  "palette": {                                 // light palette (required, complete)
    "text": "#1f2328", "heading": "#111111", "muted": "#6b7280",
    "accent": "#1d4ed8", "link": "@accent", "linkHover": "#1e40af",
    "page": "#ffffff", "canvas": "#f1f3f4", "border": "#d0d7de",
    "codeText": "#24292f", "codeBg": "#f6f8fa", "quoteText": "#4b5563",
    "quoteBar": "#d0d7de", "quoteBg": "transparent",
    "tableHeaderBg": "#f3f4f6", "tableStripe": "#fafafa",
    "mentionBg": "#e0e7ff", "mentionText": "#3730a3",
    "highlight": "#fff3bf",
    "custom1": null, "custom2": null, "custom3": null, "custom4": null, "custom5": null, "custom6": null
  },
  "dark": {
    "mode": "derived",                         // "derived" | "explicit"
    "palette": { "accent": "#93c5fd" },        // derived: overrides on top of the derived palette;
                                               // explicit: complete palette (validated)
    "elements": { "codeBlock": { "border": { "width": "1px", "style": "solid", "color": "@border" } } },
    "syntax": null                             // null = derive from light syntax palette
  },
  "page": { … },              // §2.3
  "elements": { … },          // §2.4
  "syntax": { … },            // §2.5 (light syntax palette)
  "overlays": { … }           // §2.6 (optional overrides of app tokens)
}
```

Palette keys are **fixed** (the list above); `custom1…custom6` are free user colors that appear
in the *Theme colors* row of `WonkyColorPicker` and can be referenced as `"@custom3"`.

### 2.3 `page`

| Property | Type | Default (Wonky Default) | Meaning |
|----------|------|-------------------------|---------|
| `paperColor` | ColorRef | `"@page"` | Page surface (Pages mode) / content background (Pageless). |
| `canvasColor` | ColorRef | `"@canvas"` | Area around pages (Pages mode). Pageless uses `paperColor` everywhere. |
| `pageShadow` | `"none"\|"soft"\|"strong"` | `"soft"` | Editor only. |
| `pagelessMaxWidth` | Length | `"760px"` | Max content width in Pageless mode (content centered). |
| `pagelessPadding` | Edges<Length> | `{"top":"48px","bottom":"96px","left":"32px","right":"32px"}` | |
| `defaultMargins` | Edges<Length> | `"1in"` | Used by page setup when `margins: "theme"` ([07](07-import-export-print.md) §6). |
| `headerFooter` | TextStyleProps + `{"borderBottom"(header)/"borderTop"(footer): Border}` | `@body`, `9pt`, `"@muted"` | Typography of page header/footer slots (content comes from page setup). |

### 2.4 `elements`

Every element key below is optional; missing properties **inherit** (§3). Property groups:

- **TextStyleProps**: `fontFamily: FontRef`, `fontSize: Length`, `fontWeight`, `fontStyle:
  "normal"|"italic"`, `lineHeight`, `letterSpacing: Length` (`em` recommended), `color: ColorRef`,
  `caseTransform`, `fontFeatures: [String]` (OpenType tags, e.g. `"onum"`, `"liga"`).
- **BlockProps**: `spaceBefore: Length`, `spaceAfter: Length`, `padding: Edges<Length>`,
  `background: ColorRef`, `border: Edges<Border>`, `borderRadius: Length`, `align: Align`,
  `keepWithNext: bool` (pagination), `pageBreakBefore: bool` (pagination; print/export only).

| Element key | Groups | Extra properties |
|-------------|--------|------------------|
| `body` | Text + Block | `firstLineIndent: Length` (P2, §6.5), `align` limited to `left`/`justify` |
| `headings` | Text + Block | Shared base for all headings; `numbering`: `{ "enabled": bool, "fromLevel": 1-6, "toLevel": 1-6, "style": "decimal"\|"outline"\|"legal"\|"upperRoman-upperAlpha-decimal", "suffix": ". " }` — `decimal` = "1.", `outline` = "1.1.1", `legal` = "1.1.1." (trailing dot), roman = "I. A. 1." |
| `h1` … `h6` | Text + Block | `borderBottom: Border`, `borderBottomGap: Length` (space between text and border) |
| `bold` | — | `fontWeight` (default 700), `color: ColorRef?` |
| `italic` | — | `fontStyle: "italic"\|"oblique"` (oblique = synthetic slant even if the family has an italic face), `color: ColorRef?` |
| `strike` | — | `lineColor: ColorRef?`, `lineThickness: Length`, `color: ColorRef?` (text color of struck text, e.g. `@muted`) |
| `inlineCode` | Text subset | `fontFamily` (default `@mono`), `sizeRatio: number` (default 0.9 of surrounding text), `color`, `background`, `paddingX: Length`, `borderRadius: Length`, `border: Border?` |
| `link` | — | `color`, `hoverColor`, `underline: "always"\|"hover"\|"none"`, `underlineStyle: "solid"\|"dotted"\|"dashed"`, `underlineThickness: Length`. *Visited* styling is not supported (no visit tracking; privacy). |
| `mention` | — | `color`, `background`, `borderRadius`, `fontWeight`, `prefix: "@"\|""` |
| `paragraphAfterHeading` | Block | Optional spacing override for a paragraph directly after any heading (maps to `BlockSelector("paragraph").after("headerN")`). |
| `blockquote` | Text + Block | `bar: Border` (left bar; width/color), `italic: bool` |
| `codeBlock` | Text + Block | `fontFamily` (`@mono`), `wrap: bool` (editor: wrap vs. horizontal scroll; exports always wrap), `showLanguageLabel: bool`, `tabSize: int` (2–8), `lineNumbers: bool` (P2) |
| `list` | Block | `bullets: [String × 9]` (per indent level 0–8, default `["•","◦","▪","•","◦","▪","•","◦","▪"]`), `bulletColor: ColorRef`, `bulletScale: number`, `numbering: [style × 9]` with style ∈ `decimal`, `lowerAlpha`, `upperAlpha`, `lowerRoman`, `upperRoman` (default cycle `decimal, lowerAlpha, lowerRoman`), `numberSuffix: "."\|")"`, `numberColor: ColorRef`, `indentPerLevel: Length`, `markerGap: Length`, `itemSpacing: Length` (between items), `spaceBefore`/`spaceAfter` (around a list run) |
| `task` | Block | `checkbox`: `{ "shape": "square"\|"rounded"\|"circle", "size": Length, "borderColor", "checkedFill", "checkColor" }`, `checkedText`: `{ "strike": bool, "opacity": 0–1, "color": ColorRef? }` |
| `rule` | Block | `style: "solid"\|"dashed"\|"dotted"\|"double"\|"ornament"`, `thickness: Length`, `color`, `width: Length` (`%` of content width), `ornament: String` (glyph(s) for `ornament`, default `"⁂"`) |
| `image` | Block | `maxWidth: Length` (`%`), `align: "center"\|"left"`, `borderRadius`, `border: Border?`, `shadow: "none"\|"soft"\|"strong"`, `caption`: TextStyleProps + `{ "show": bool, "align": Align, "gap": Length }` (caption text = image `title`, else none) |
| `table` | Text subset + Block | `width: "auto"\|"full"`, `headerBackground`, `headerColor`, `headerFontWeight`, `borders: "all"\|"horizontal"\|"outer"\|"headerOnly"\|"none"`, `borderColor`, `borderWidth`, `zebra: bool`, `zebraColor`, `cellPadding: Edges<Length>`, `fontSizeRatio` |
| `header`, `footer` | see `page.headerFooter` | Aliases to `page.headerFooter` overrides for header vs. footer separately. |

### 2.5 `syntax` (code highlighting palette)

`{ "keyword", "string", "number", "comment", "function", "type", "variable", "operator",
"punctuation", "builtin", "literal", "meta", "tag", "attribute", "regexp", "addition",
"deletion" }` → `{ "color": ColorRef, "fontStyle"?: "italic", "fontWeight"?: int }`.
Unlisted tokens render in `codeText`. Dark syntax: derived (§4) unless `dark.syntax` is given.
The editor and the exporters tokenize with `wonky_code`'s `DefaultCodeTokenizer` (since M10,
Slides SL-35): the TextMate engine copied from `syntax_highlight` for its 15 languages
([04](04-editor.md) §15.4/§15.5), highlight.js (`HighlightJsTokenizer`, wrapping `highlight`
0.7.x — `re_highlight` was rejected because it depends on Flutter; the ~45 most common grammars)
for the others, both mapped to the same token kinds, so screen, exports and Slides color code
identically. The exporters call it through `wonky_write_core`'s `SyntaxHighlighter` (cached).
Before M10 the exporters used highlight.js for every language. `SyntaxToken` is defined in
`wonky_code`. Unknown language → no highlighting.

### 2.6 `overlays` (optional overrides of app tokens)

`selection`, `caret` (`{color, width}`), `commentHighlight`, `commentHighlightActive`,
`suggestionInsert`, `suggestionDelete`, `findMatch`, `findMatchActive`. `null`/absent = use the
app token from [../02-design-system.md](../02-design-system.md) §2. Presence
colors are **not** overridable. The theme editor shows these under *Advanced* with a note
"Usually best left to the app".

### 2.7 Validation and migration

- `WriteThemeValidator` (core): JSON-schema check (schema file `wonky_write_core/lib/theme/
  theme_schema_v1.json`, also exported for MCP), plus semantic checks: lengths within bounds
  (font size 6–96 pt, line height 0.8–3.0, spacing 0–200 pt, margins 0–3 in), palette complete,
  font families known, `numbering.fromLevel ≤ toLevel`, 9 bullets/numbering entries.
- Unknown properties are **dropped with a warning** (forward compatibility for imports).
- `ThemeMigrations.migrate(json) → json` upgrades older `schemaVersion`s step by step; the
  server stores only the latest schema version and migrates rows lazily on read (writes back
  on next save).

---

## 3. Cascade and resolution

```
built-in base (hard-coded "Wonky Default" values, complete)
  └─ theme.elements.body
       ├─ paragraph (= body)
       ├─ headings ─► h1 … h6
       ├─ blockquote, list, task, table, codeBlock*, image.caption, header/footer
       └─ inline: bold / italic / strike / inlineCode* / link / mention apply as deltas over the
          surrounding text style
  dark variant: same cascade, palette = derived/explicit dark palette, then dark.elements overrides
```

`*` `codeBlock` and `inlineCode` inherit only `color`/`lineHeight` from body; their font is
`@mono`.

```dart
// wonky_write_core/lib/theme/
final class WriteThemeData {           // immutable, == by value, toJson/fromJson
  final int schemaVersion;
  final String name;
  final String? description;
  final ThemeFonts fonts;
  final ThemePalette palette;
  final DarkVariantSpec dark;
  final PageStyleSpec page;
  final Map<ThemeElement, ElementStyleSpec> elements;   // sparse
  final SyntaxPalette syntax;
  final OverlaySpec overlays;
}

enum ThemeElement { body, headings, h1, h2, h3, h4, h5, h6, paragraphAfterHeading, bold,
  italic, strike, inlineCode, link, mention, blockquote, codeBlock, list, task, rule, image,
  table, header, footer }

enum ThemeVariant { light, dark }

final class ResolvedWriteTheme {       // all values concrete; lengths in pt; colors as ARGB ints
  final ThemeVariant variant;
  final ResolvedPage page;
  final ResolvedText body;
  final List<ResolvedHeading> headings;          // index 0 = h1
  final ResolvedInline bold, italic, strike, inlineCode, link, mention;
  final ResolvedBlockquote blockquote;
  final ResolvedCodeBlock codeBlock;
  final ResolvedList list;
  final ResolvedTask task;
  final ResolvedRule rule;
  final ResolvedImage image;
  final ResolvedTable table;
  final ResolvedText header, footer;
  final Map<SyntaxToken, ResolvedTokenStyle> syntax;
  final ResolvedOverlays overlays;               // nullable entries = app token
  final String contentHash;                      // sha256 of canonical source JSON + variant
}

abstract interface class ThemeResolver {
  ResolvedWriteTheme resolve(WriteThemeData theme, ThemeVariant variant);   // memoized by hash
}
```

Resolution is deterministic and pure; results are memoized by `(contentHash, variant)`. Unit
conversion happens here once (`Length` → pt as `double`); renderers convert pt → px (`× 4/3`)
or keep pt (PDF, DOCX half-points, RTF twips).

---

## 4. Dark variants

`dark.mode`:
- **`derived`** (default for user themes): the dark palette is computed from the light palette
  by `DarkPaletteDeriver` (core), then `dark.palette` entries override individual keys, then
  `dark.elements` overrides element properties. The theme editor shows derived values greyed
  with an *Override* affordance per key.
- **`explicit`**: `dark.palette` must be complete; no derivation.

Derivation algorithm (OKLCH, implemented in core without Flutter):
1. Convert each palette color to OKLCH.
2. **Surfaces** (`page`, `canvas`, `codeBg`, `quoteBg`, `tableHeaderBg`, `tableStripe`,
   `mentionBg`, `highlight`): `L' = 0.16 + (1 − L) × 0.14` (very light → ~0.16–0.30), chroma
   × 0.6, hue kept. `canvas` is made 0.03 darker than `page`.
3. **Foregrounds** (`text`, `heading`, `muted`, `codeText`, `quoteText`, `mentionText`):
   `L' = 1 − L × 0.85` clamped to [0.55, 0.96], chroma × 0.8.
4. **Accents** (`accent`, `link`, `linkHover`, `quoteBar`, `border`, `custom*`): `L' = max(L,
   0.72)` for accents, `0.38` for `border`/`quoteBar`; chroma × 0.85.
5. **Contrast repair**: for each foreground/background pair in the contrast table (§7.6), if the
   WCAG ratio < 4.5 (3.0 for large text), raise the foreground lightness in steps of 0.02 until
   it passes or L = 0.98.
6. Syntax palette: same as accents, then contrast-repaired against `codeBg`.

Built-in themes ship **explicit** dark palettes (hand-tuned); derivation is for user themes.

---

## 5. Data model, storage and versioning

### 5.1 Server tables (`wonky_server/lib/src/write/models/`)

```yaml
class: WriteTheme
table: write_theme
fields:
  uuid: UuidValue, defaultPersist=random_v7     # built-ins: fixed UUIDv5("wonky-theme:<key>")
  ownerId: int?, relation(parent=user_profile, onDelete=Cascade)   # null for built-ins
  isBuiltin: bool
  builtinKey: String?               # "wonky-default", "classic-serif", …
  name: String                      # 1–80 chars
  description: String?
  schemaVersion: int
  version: int                      # 1-based, +1 on every save (optimistic concurrency)
  json: String                      # canonical WriteThemeData JSON (sorted keys, no whitespace)
  contentHash: String               # sha256(json), used for caching & export provenance
  createdAt: DateTime
  updatedAt: DateTime
  deletedAt: DateTime?              # soft delete (§5.4)
indexes:
  write_theme_uuid_idx: { fields: uuid, unique: true }
  write_theme_owner_idx: { fields: ownerId, deletedAt }
  write_theme_builtin_idx: { fields: builtinKey, unique: true }

class: WriteThemeRevision           # last 50 saved versions per theme (conflicts, revert, audit)
table: write_theme_revision
fields:
  themeId: int, relation(parent=write_theme, onDelete=Cascade)
  version: int
  json: String
  savedById: int?
  actorKind: ActorKind
  createdAt: DateTime
indexes:
  write_theme_rev_idx: { fields: themeId, version, unique: true }
```

- Built-ins are upserted at server start from `wonky_write_core/lib/theme/builtins/*.json`
  (compiled-in constants) — **not** copied per user. (The "seed default Write themes" step in
  [../04-auth-and-accounts.md](../04-auth-and-accounts.md) §1.1 means: set
  `writeDefaults.defaultThemeId` to *Wonky Default*.) Changing a built-in in a release bumps its
  `version`, so documents using it update on next open.
- `Document.themeId` ([02](02-document-model.md) §3) references `WriteTheme.uuid`.

### 5.2 Document ↔ theme reference

- `Document.themeId = <uuid>` → that theme, at its **current** version (live link).
- `Document.themeId = null` → viewer's default theme (*Use my default theme*). Exports made by a
  user use **that user's** default; MCP/headless exports use the token owner's default.
- Changing the assignment is a **meta change** (`DocumentEndpoint.updateMeta`, field `themeId`,
  LWW, see [03-sync-protocol.md](03-sync-protocol.md) §6). `DocumentMetaChange.afterJson` stores
  `{"themeId": "<uuid>|null", "version": n, "hash": "<contentHash>"}` for provenance (history
  shows "Anna changed the theme to Classic Serif").
- Undo: domain `write.meta`, entry `{field: themeId, before, after}` — dropped if the current
  value ≠ `after` (suite rule).
- Viewers/Commenters cannot change the document theme (Editor+). There is no local theme
  preview in the editor (*View › Preview theme* / `write.theme.previewLocal` was removed); the
  theme picker and theme editor show previews.

### 5.3 Live updates

- On save, the server bumps `version`, writes a `WriteThemeRevision`, and publishes on
  `session.messages` channel `theme:<uuid>` (global scope with Redis).
- Each `DocumentSession` whose document references that theme subscribes to the channel and
  forwards `MetaChanged(field: "themeVersion", valueJson: {"themeId", "version", "hash"})` to its
  clients. Clients refetch via `WriteThemeEndpoint.get` (cached by `(uuid, version)` in memory and
  in the local SQLite cache table `LocalTheme(uuid, version, json, fetchedAt)` for offline use).
- Offline: the last fetched theme version is used; if a document's theme was never fetched,
  render with *Wonky Default* and show a subtle "Theme unavailable offline" chip in the status
  bar.

### 5.4 Deletion and access

- **Read access** to a theme: owner; anyone (signed-in) for built-ins; anyone with ≥ Viewer
  access to a document whose `themeId` is that theme (`WriteThemeEndpoint.get(uuid,
  viaDocumentUuid)` checks this). Collaborators therefore always see the document as intended,
  but cannot edit someone else's theme — they can **Copy to my themes** (duplicate into their
  library).
- **Delete** is a soft delete (`deletedAt`). A deleted theme disappears from the owner's library
  but stays readable through referencing documents; the document's theme menu shows "*<name>*
  (deleted)" with actions *Restore theme* (owner only) / *Copy to my themes* / *Choose another*.
  A daily job hard-deletes soft-deleted themes that are no longer referenced by any document and
  were deleted > 30 days ago. If the owner's account is deleted (cascade), documents fall back to
  the viewer's default theme and show a one-time notice.
- Users' default theme pointing at a deleted theme falls back to *Wonky Default*.

### 5.5 Endpoint — `WriteThemeEndpoint` (`writeTheme`)

| Method | Description |
|--------|-------------|
| `listBuiltins()` | `List<WriteThemeView>` (`uuid, name, description, isBuiltin, ownerSummary, version, contentHash, json, updatedAt`) |
| `listMine()` | User's themes (not deleted), sorted by name |
| `get(uuid, viaDocumentUuid?)` | Single theme (access rule §5.4) |
| `getMany(uuids, viaDocumentUuid?)` | Batch |
| `create(name, json, basedOnUuid?)` | Validates; returns view (version 1) |
| `update(uuid, json, expectedVersion)` | Owner only; `ThemeConflict` error if `expectedVersion ≠ version` (payload: server json + version) |
| `rename(uuid, name, expectedVersion)` | |
| `duplicate(uuid, name, viaDocumentUuid?)` | Copy into caller's library (works for built-ins and readable foreign themes) |
| `delete(uuid)` / `restore(uuid)` | Soft delete / undelete |
| `listRevisions(uuid)` / `getRevision(uuid, version)` | Owner only |
| `usage(uuid)` | Number of documents (owned by caller) referencing the theme — shown before delete / when editing ("Used by 12 of your documents") |

Import/export JSON is **client-side** (create/update with the parsed JSON).

---

## 6. Mapping to super_editor (`wonky_write/lib/features/theme/stylesheet/`)

`WriteStylesheetBuilder` converts a `ResolvedWriteTheme` into the super_editor configuration.
It is rebuilt only when `(contentHash, variant, layoutMode)` changes (memoized), so typing never
rebuilds the stylesheet.

```dart
class WriteEditorStyle {
  final Stylesheet stylesheet;
  final SelectionStyles selectionStyles;
  final CaretStyle caretStyle;                 // super_text_layout
  final List<ComponentBuilder> componentBuilders;   // themed custom components (§6.3)
  final Color paperColor, canvasColor;
}

abstract interface class WriteStylesheetBuilder {
  WriteEditorStyle build(ResolvedWriteTheme t, {required LayoutMode layout, required AppTokens app});
}
```

### 6.1 Block rules (`StyleRule` + `BlockSelector`)

super_editor's default stylesheet only defines h1–h3, paragraph, listItem, blockquote; ours
defines **every** block type. Rule order (later rules override earlier keys):

| # | Selector | Styles keys set |
|---|----------|-----------------|
| 1 | `BlockSelector.all` | `textStyle` (body), `padding` (`CascadingPadding.only(top: spaceBefore, bottom: spaceAfter)`), `maxWidth` (pageless max width / page content width), `textAlign` (body align) |
| 2 | `BlockSelector("paragraph")` | body spacing, `textAlign` |
| 3 | `BlockSelector("header1")` … `("header6")` | `textStyle` (font, size, weight, color, letterSpacing, height, `fontFeatures` incl. `smcp` for small caps), `padding`, `textAlign` |
| 4 | `BlockSelector("paragraph").after("headerN")` (N = 1…6) | `paragraphAfterHeading` spacing |
| 5 | `BlockSelector("blockquote")` | `textStyle` (italic/color), `padding` (incl. left padding = bar width + gap), `backgroundColor` |
| 6 | `BlockSelector("code")` | `textStyle` (mono), `padding`, `backgroundColor`, `borderRadius` |
| 7 | `BlockSelector("listItem")` | `textStyle`, `padding` (item spacing), `dotColor`, `dotShape` (`BoxShape.circle`/`rectangle` when the bullet glyph is •/▪; other glyphs use the custom list component §6.3), `dotSize`, `listNumeralStyle` (`OrderedListNumeralStyle` per level — set per node in the custom component because the key is per-rule) |
| 8 | `BlockSelector("task")` | `textStyle`, `padding` |
| 9 | `BlockSelector("horizontalRule")` | `padding` |
| 10 | `BlockSelector("image")` | `padding`, `maxWidth` |
| 11 | `BlockSelector("tableBlock")` | `padding`, `TableStyles.headerTextStyle`, `TableStyles.border` (`TableBorder` built from `borders` mode), `TableStyles.cellDecorator` (header background + zebra rows), `TableStyles.cellPadding` (`CascadingPadding`) |
| 12 | `BlockSelector.all.first()` | `padding.top = 0` (no space before the first block) |
| 13 | `BlockSelector.all.last()` | extra bottom padding (Pageless: `pagelessPadding.bottom`) |

`Stylesheet.documentPadding` = Pageless: `pagelessPadding`; Pages: zero (page margins are
applied by the page frame, see [04-editor.md](04-editor.md)).

Rule keys that are themselves listenable (comment/find highlights) are **not** in the
stylesheet; they're layers (§6.2).

### 6.2 Inline styles (`inlineTextStyler`)

`Stylesheet.inlineTextStyler` is an `AttributionStyleAdjuster` built by
`WriteInlineStyler(resolvedTheme, appTokens)`:

| Attribution | Adjustment |
|-------------|------------|
| `boldAttribution` | `fontWeight` = `bold.fontWeight`; `color` if set |
| `italicsAttribution` | `fontStyle: italic` (synthetic oblique when `fontStyle: oblique` → the italic face is not registered for that family alias, see §8.3) |
| `strikethroughAttribution` | `decoration: lineThrough`, `decorationColor`, `decorationThickness`, `color` |
| `codeAttribution` (inline) | `fontFamily` mono, `fontSize × sizeRatio`, `color`, `backgroundColor` (flat fill; rounded chip painted by `InlineChipLayer` when `borderRadius > 0`, see below) |
| `LinkAttribution` | `color`, `decoration: underline` (when `underline: always`), `decorationStyle` |
| `MentionAttribution` | `color`, `fontWeight`; chip background painted by `InlineChipLayer` |
| `CommentAttribution` (open thread) | `backgroundColor` = `commentHighlight`; each additional overlapping open thread raises alpha by 15 %, capped at 2 overlaps ([04-editor.md](04-editor.md) §33) |
| `SuggestionAttribution` | insert: author presence color + underline; delete: `lineThrough` + presence color at 70 %; fmt: dotted underline (see [08-comments-suggestions-history.md](08-comments-suggestions-history.md)) |
| `SyntaxTokenAttribution(kind)` (ephemeral, §6.3) | color/style from the syntax palette |

`InlineChipLayer` and `HighlightLayer` are super_editor document layers (`SuperEditorLayerBuilder`)
that paint rounded rects behind text using `DocumentLayout.getRectsForSelection`; they handle
inline-code chips, mention chips, the **active** comment highlight, find matches and link hover
color. Layers repaint without relayout.

### 6.3 Themed custom component builders

| Builder | Purpose |
|---------|---------|
| `ThemedHeadingComponentBuilder` | Wraps the heading `TextComponent` in a `Row` with a non-selectable numbering label (`HeadingNumberer` computes "1.2." from the outline, recomputed incrementally on header changes); draws `borderBottom`. |
| `ThemedListItemComponentBuilder` | Custom marker widget: bullet glyph per indent level (text glyph in bullet color/scale), numbering per level (`decimal`, `lowerAlpha`, …, suffix), indent per level, marker gap. |
| `ThemedTaskComponentBuilder` | Checkbox shape/size/colors; checked text strike + opacity. |
| `ThemedCodeBlockComponentBuilder` | Background, border, radius, language label, wrap/scroll; adds **ephemeral** `SyntaxTokenAttribution`s to a copy of the node text in `createViewModel` (document untouched); tokenization cached per node `(text hash, language)` and computed off the UI thread for blocks > 2,000 chars. |
| `ThemedImageComponentBuilder` | `wonky-file://` loading, max width, alignment, radius, border, shadow, caption from `title`. |
| `ThemedHorizontalRuleComponentBuilder` | Style, thickness, width, color, ornament glyph. |
| `ThemedTableComponentBuilder` | Wraps super_editor's table component; `width: full` stretches. |

### 6.4 Case transforms

Flutter has no CSS `text-transform`. `uppercase`/`lowercase`/`capitalize` are implemented in
`ThemedHeadingComponentBuilder` by transforming the **displayed** text per UTF-16 code unit
(length-preserving: characters whose case mapping changes length, e.g. `ß`, are left
untouched), so caret/selection offsets map 1:1. `smallCaps` uses font features `smcp` (+ `c2sc`
when combined with uppercase source); the font registry declares which families support it;
the inspector disables *Small caps* for others. Exporters use real CSS/DOCX/ODT case properties
(`text-transform`, `w:caps`/`w:smallCaps`, `fo:text-transform`/`fo:font-variant`, RTF `\caps`/
`\scaps`) and PDF applies the same transform to the text it draws.

### 6.5 First-line indent (P2)

Supported by all exporters natively. In the editor: `IndentedTextComponent` prepends a
`WidgetSpan` placeholder of the indent width and wraps the `TextLayout` in an adapter that
shifts text positions by one; behind a feature flag until selection/IME tests pass.

### 6.6 Other details

- **Selection**: `SelectionStyles(selectionColor: overlays.selection ?? app selection token,
  highlightEmptyTextBlocks: true)`; `selectedTextColorStrategy` keeps text color.
- **Caret**: `CaretStyle(color: overlays.caret.color ?? primary, width: 2)` passed to the
  caret overlay builder.
- **Paper/canvas** colors are provided to the page frame and to the `page` custom token
  (`WonkyColors.page`) via a scoped `ShadTheme` override around the editor.
- **RTL**: if `Document.language` is an RTL language, `left`↔`right` in `align`, padding and
  quote bar side are mirrored.
- **Zoom** does not touch the stylesheet: the editor scales with a `Transform`/`textScaler` at
  the viewport level ([04-editor.md](04-editor.md)).
- `SuperReader` (history, previews) uses the same `WriteEditorStyle`.

---

## 7. Mapping to exporters

All exporters consume `ResolvedWriteTheme` (light by default). Shared helpers in
`wonky_write_core/lib/theme/mappers/`.

### 7.1 Per-element mapping overview

| Theme concept | PDF (`pdf` pkg) | HTML/EPUB CSS | DOCX (OOXML) | ODT | RTF |
|---------------|-----------------|---------------|--------------|-----|-----|
| Body font/size/lh/color | `pw.TextStyle(font, fontSize pt, lineSpacing, color)` | `body {font-family; font-size: pt; line-height; color}` | `Normal` style `w:rFonts`, `w:sz` (half-pt), `w:spacing w:line` (240ths, `lineRule=auto`) | `Standard` paragraph style `fo:*` | `\s0 \f \fs(half-pt) \sl` |
| Paragraph spacing | widget padding | `p {margin}` | `w:spacing w:before/after` (twips) | `fo:margin-top/bottom` | `\sb \sa` (twips) |
| Justify | `TextAlign.justify` | `text-align: justify` | `w:jc w:val="both"` | `fo:text-align="justify"` | `\qj` |
| H1–H6 | numbered `pw.Text` with outline (`pw.Outline`) | `h1…h6` | styles `Heading1…6` with `w:outlineLvl`, `w:keepNext` | `Heading_20_1…6` with `style:default-outline-level` | `\s1…\s6 \outlinelevelN \keepn` |
| Heading numbering | text prefix | `::before` counters | `numbering.xml` multilevel list linked to Heading styles | `text:outline-style` | text prefix |
| Heading border | `pw.Container` bottom border | `border-bottom` | `w:pBdr w:bottom` | `fo:border-bottom` | `\brdrb` |
| Bold/italic/strike | font variant / `decoration` | `strong/em/del` rules | `w:b`, `w:i`, `w:strike` (+ color) | `fo:font-weight`, `style:text-line-through-style` | `\b \i \strike` |
| Inline code | mono font `pw.TextSpan` with `background: pw.BoxDecoration(color, borderRadius)` | `code {…}` | char style `Code Char` (shading `w:shd`) | text style `Source_20_Text` | `\cs` char style + `\chcbpat` |
| Code block | `pw.Container` (bg, border, radius) + highlighted spans | `pre code` + `.tok-*` classes | para style `Code Block` + `w:shd`, per-token run colors | `Preformatted_20_Text` | `\s` code style |
| Blockquote | `pw.Container` left border + padding | `blockquote` | `Quote` style with `w:pBdr w:left`, `w:ind` | `Quotations` | `\s` quote style `\brdrl` |
| Link | `pw.UrlLink` + style | `a` | `w:hyperlink` + `Hyperlink` char style | `text:a` | `{\field{\*\fldinst HYPERLINK "…"}{\fldrslt …}}` |
| Lists | custom marker column | `ul/ol` + `list-style-type`/`::marker` | `numbering.xml` abstractNum per list kind (9 levels: bullets glyph/color, number formats `decimal/lowerLetter/lowerRoman`) | `text:list-style` | `\listtable` + `\ls` |
| Task | checkbox glyph (☐/☑ drawn as vector box) | `input[type=checkbox][disabled]` styled | `☐`/`☒` glyph runs (w14:checkbox is optional, P2) | glyph | glyph |
| Rule | `pw.Divider`/custom | `hr` | empty paragraph with `w:pBdr w:bottom` | para with bottom border | `\brdrb` paragraph |
| Image | `pw.Image` scaled, radius via clip, caption | `figure img figcaption` | `w:drawing` inline + caption para (`Caption` style) | `draw:frame` | `\pict\pngblip` |
| Table | `pw.Table` (headerCount repeat) | `table th td` | `w:tbl` + table style `WonkyTable` (header row, banded rows) | `table:table` | `\trowd \cellx` |
| Page color | page background rect (only if not white, option) | `html {background}` | `w:background` + `w:displayBackgroundShape` | `style:page-layout` background | `\*\background` (P2) |
| Header/footer typography | `MultiPage.header/footer` styles | — (HTML has no pages; print CSS `@page` margins boxes not supported widely) | `Header`/`Footer` styles | `Header`/`Footer` | `\header \footer` |

### 7.2 CSS writer

`ThemeCssWriter.write(ResolvedWriteTheme light, {ResolvedWriteTheme? dark, CssTarget target})`
emits a self-contained stylesheet: CSS custom properties for the palette (`--wk-text`, …),
element rules scoped under `.wonky-doc`, `@media (prefers-color-scheme: dark)` block when `dark`
is given (HTML export option *Include dark mode*), `@font-face` rules (HTML: TTF inlined as base64 data URIs, only for the families/weights used;
EPUB/zip: relative font files),
`@page { size; margin }` for print-friendly HTML. *Export theme as CSS…* in the theme editor uses
the same writer (`target: standalone`).

### 7.3 Consistency guarantees

- Spacing collapse rule (identical everywhere): space between two blocks = `max(spaceAfter(a),
  spaceBefore(b))` (CSS margin-collapse semantics). The editor implements it via the
  `BlockSelector.after` rules + `CascadingPadding` (top padding of b = max − spaceAfter(a)); PDF and
  DOCX (`w:contextualSpacing` is **not** used; explicit computed values instead) compute it
  explicitly. Golden tests (§11) verify.
- Line height: Flutter `height` multiplier, PDF `lineSpacing = (lh − 1) × fontSize`, CSS
  unitless `line-height`, DOCX `w:line = lh × 240` auto.

---

## 8. Fonts

### 8.1 Curated font registry

Fonts live in **`wonky_write/fonts/`** (source of truth, checked in), with `fonts.json`
(manifest: family, category, files per weight/style, license, supported features, coverage).
A build step (`tool/sync_fonts.dart`) copies them to `wonky_write/assets/fonts/` and to
the server's `web/fonts/` (served with `Cache-Control: immutable`). All fonts are **static TTF**
instances (the `pdf` package does not support variable fonts or CFF-flavoured OTF).

| # | Family | Category | Weights shipped (R = regular, I = italic) | License |
|---|--------|----------|-------------------------------------------|---------|
| 1 | Inter | Sans | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 2 | Source Sans 3 | Sans | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 3 | IBM Plex Sans | Sans | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 4 | Open Sans | Sans | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 5 | Work Sans | Sans | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 6 | Atkinson Hyperlegible Next | Sans (accessibility) | 400 R/I, 700 R/I | OFL 1.1 |
| 7 | Montserrat | Sans (display) | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 8 | Liberation Sans | Sans (Arial-metric) | 400 R/I, 700 R/I | OFL 1.1 |
| 9 | Source Serif 4 | Serif | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 10 | Merriweather | Serif | 400 R/I, 700 R/I | OFL 1.1 |
| 11 | Lora | Serif | 400 R/I, 700 R/I | OFL 1.1 |
| 12 | Libre Baskerville | Serif | 400 R/I, 700 R | OFL 1.1 |
| 13 | EB Garamond | Serif | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 14 | Crimson Pro | Serif | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 15 | Literata | Serif | 400 R/I, 700 R/I | OFL 1.1 |
| 16 | IBM Plex Serif | Serif | 400 R/I, 600 R, 700 R/I | OFL 1.1 |
| 17 | Playfair Display | Serif (display) | 400 R/I, 700 R/I | OFL 1.1 |
| 18 | Liberation Serif | Serif (Times-metric) | 400 R/I, 700 R/I | OFL 1.1 |
| 19 | JetBrains Mono | Mono | 400 R/I, 700 R | OFL 1.1 |
| 20 | IBM Plex Mono | Mono | 400 R/I, 700 R | OFL 1.1 |
| 21 | Source Code Pro | Mono | 400 R/I, 700 R | OFL 1.1 |
| 22 | Courier Prime | Mono (typewriter) | 400 R/I, 700 R/I | OFL 1.1 |
| 23 | Geist / Geist Mono | Sans / Mono | 400, 600, 700 (already bundled by `wonky_ui` for UI; registered as document fonts too) | OFL 1.1 |

**Fallback fonts** (not user-selectable, loaded on demand when glyphs are missing): Noto Sans,
Noto Serif, Noto Sans Mono, Noto Sans Symbols 2, Noto Emoji (monochrome; PDF can't embed color
emoji), and CJK (Noto Sans SC/TC/JP/KR — large; web/desktop download on first need from
`/fonts/`, never bundled in the desktop installer). Arabic/Hebrew/Devanagari Noto families
likewise on demand. All OFL 1.1. License texts are included in the About › Licenses page
(`LicenseRegistry.addLicense`) and in exported EPUBs that embed fonts.

> Implementation note (iteration 1; moved in v2, Drive 05 D-7): the static TTFs and the
> registry live in the shared package `packages/wonky_fonts` (`fonts/` as package assets,
> manifest `BundledFonts`); Write loads Open Sans, EB Garamond and JetBrains Mono from it
> (`packages/wonky_fonts/fonts/…`; OFL-1.1, licenses in the same folder and on the About › Licenses page). Families that are not bundled are
> substituted by category (sans → Inter from `wonky_ui` on screen / Open Sans in PDFs, serif → EB
> Garamond, mono → JetBrains Mono) by `WriteFonts` (`features/themes/write_fonts.dart`); Open
> Sans is the PDF glyph fallback (Latin Extended, Greek, Cyrillic). CJK/Arabic fallbacks and the
> full curated set are a TODO. The server has the same TTFs in `wonky_server/web/fonts/`
> (`FileSystemFontProvider`, `write/export/server_fonts.dart`, same substitution rules), so
> server-side PDF/HTML/EPUB exports embed the same faces as client exports.

### 8.2 Weight snapping

Requested weight → nearest shipped weight of that family (ties go heavier). The inspector's
weight select only offers shipped weights; JSON imports with other weights are snapped with a
warning.

### 8.3 Loading strategy

- Document fonts are declared under `assets:` (not `fonts:`) in the Flutter pubspec, so Flutter
  web does **not** download them at startup. `WriteFontRegistry` (Flutter) registers families on
  demand with `FontLoader(family)..addFont(rootBundle.load(path))` when a resolved theme needs
  them; the editor shows the document with fallback metrics only until fonts are ready (max
  1.5 s, then render anyway and re-layout when ready). Theme editor's `FontPicker` loads each
  family's regular face lazily as the list scrolls (preview text in its own face).
- Italic synthesis is avoided by always registering the italic face when shipped.
- `FontProvider` interface in core (used by exporters on server and client):

```dart
abstract interface class FontProvider {
  /// Returns TTF bytes for the closest available face.
  Future<FontFace> load(String family, {int weight = 400, bool italic = false});
  /// Fallback chain for glyph coverage (script-aware).
  Future<List<FontFace>> fallbacksFor(String text);
}
// Server: FileSystemFontProvider(web/fonts). Client: AssetFontProvider(rootBundle) with
// HttpFontProvider for on-demand fallbacks. Both cache bytes in memory (LRU 64 MB).
```

- **PDF embedding**: `pw.Font.ttf(bytes)`; the `pdf` package subsets automatically. All
  exporters that support embedding (PDF always; EPUB optionally — default on; DOCX "Embed fonts"
  option, P2) embed only the faces actually used.

---

## 9. Built-in presets

All built-ins ship explicit dark palettes and use JetBrains Mono for code (the `mono` role).
Key characteristics (full JSON in
`wonky_write_core/lib/theme/builtins/`):

| Key | Name | Fonts (body / heading / mono) | Body | Headings | Notable |
|-----|------|-------------------------------|------|----------|---------|
| `wonky-default` | Wonky Default | Inter / Inter / JetBrains Mono | 11pt, lh 1.5, after 8pt | 600 weight, H1 24pt … H6 11pt, `@heading` | Accent links, soft code blocks, rounded images |
| `classic-serif` | Classic Serif | Source Serif 4 / Source Serif 4 / JetBrains Mono | 12pt, lh 1.45, justify | H1 26pt 600, small-caps H3 | Ornament rule `⁂`, italic blockquotes, onum |
| `modern-sans` | Modern Sans | Work Sans / Montserrat / JetBrains Mono | 11pt, lh 1.6 | Bold, tight letter spacing (−0.01em), H1 border-bottom | Full-width tables, zebra |
| `academic-apa` | Academic (APA-like) | Liberation Serif / Liberation Serif / JetBrains Mono | 12pt, **lh 2.0**, first-line indent 0.5in (P2), no paragraph spacing | All 12pt bold; H1 centered; H3 bold italic | Margins 1in, header: `{title}` right `{page}`; tables `horizontal` borders, no zebra; captions above (P2) |
| `technical` | Technical | IBM Plex Sans / IBM Plex Sans / JetBrains Mono | 10.5pt, lh 1.5 | Numbering `outline` H1–H3 | Code blocks with border + line numbers (P2), dense lists |
| `manuscript` | Manuscript | Courier Prime / Courier Prime / JetBrains Mono | 12pt, lh 2.0, first-line indent 0.5in (P2) | 12pt, uppercase H1, centered, page break before H1 | Rule = `#` centered; header `{author} / {title} / {page}` |
| `minimal-mono` | Minimal Mono | IBM Plex Mono / IBM Plex Mono / JetBrains Mono | 10.5pt, lh 1.6 | Same size as body, weight only; `#` prefix look via numbering off | Monochrome palette, no backgrounds |
| `newsletter` | Newsletter | Lora / Playfair Display / JetBrains Mono | 11.5pt, lh 1.55 | H1 34pt Playfair, accent color | Pageless max width 640px, centered images with captions & shadow, accent quote bar 4px |

---

## 10. Theme editor UI (`wonky_write/lib/features/theme_editor/`)

### 10.1 Entry points and route

- Route: **`/themes/:themeUuid`** (full-screen in-app route; `?doc=<documentUuid>` = opened
  from a document → preview can show that document and *Apply to document* targets it). Add to
  the route table in [../03-app-shell-and-navigation.md](../03-app-shell-and-navigation.md).
  `/themes` opens the last edited theme or the default.
- Entry points: *Format › Theme ▸* submenu (list of themes with ✓ on current, *Use my default
  theme*, separator, *Customize theme…*, *Manage themes…*); toolbar theme dropdown (if present,
  see [05-screens-menus-toolbar.md](05-screens-menus-toolbar.md)); *Settings › Write › Default
  theme › Edit…*; command palette.
- Back arrow returns to the document (or settings). Leaving with unsaved changes → dialog *Save*,
  *Discard*, *Cancel*.
- `< MD` width: element tree and inspector become tabs; preview below.

> Implementation (iteration 1, `wonky_write/lib/features/theme_editor/`): `ThemeEditorRoute`
> (`/themes` → last edited theme from the user store, else the default), `ThemeEditorScreen`,
> `ThemeEditorController` (draft, save/conflict, preview state; `ThemeEditorController.active`
> is the open editor for commands and MCP), `ThemeLibrary` (create/duplicate/rename/delete/
> restore as `write.theme` shell steps), `ThemeInspector` (catalog-driven: every property of
> `ThemeCatalog` gets a typed control; labels/groups in `theme_editor_model.dart`),
> `ThemePreview` (read-only `WonkyEditor`; click-to-select maps the caret's block/inline
> attributes to the element) and `theme_sample.dart`. Server access goes through
> `features/themes/theme_repository.dart` (`ThemeRepository`, fakes in tests). Below 880 px
> the theme list, element tree and inspector become tabs above the preview. The preview
> follows the app brightness until a variant is picked. Hover-outlining of matching blocks is
> not implemented yet.

### 10.2 Layout

```
┌ ← Back to "Q3 planning"   Theme: Classic Serif (copy) ▾   ● Unsaved  [Revert] [Save] [Apply to document] ⋮ ┐
├────────────────┬───────────────────────────────────────────────┬────────────────────────────┤
│ THEMES         │  Preview: [Sample ▾ | This document]  [☀|☾] [Pages|Pageless]  100% ▾  │ PROPERTIES — Heading 2  │
│ ★ My default   │ ┌───────────────────────────────────────────┐ │ ⚠ Contrast 3.9:1 (Fix)     │
│ My themes      │ │  Heading 1                                 │ │ Font      [Source Serif 4▾]│
│  · Report      │ │  Lorem ipsum dolor sit amet, **bold** …    │ │ Size      [ 18 ][pt▾] − +  │
│  · Letters     │ │  ## Heading 2  ◄ hover = outline highlight │ │ Weight    [600 ▾]          │
│ Built-in       │ │  > Quote…                                  │ │ Style     [Normal|Italic]  │
│  · Wonky Def.  │ │  - list item                               │ │ Color     [■ @heading ▾]   │
│  · Classic …   │ │  ```dart code```                           │ │ Letter sp [0.00 em]        │
│ [+ New theme]  │ └───────────────────────────────────────────┘ │ Case      [None ▾]         │
│────────────────│                                               │ Space before [18pt] after… │
│ ELEMENTS       │                                               │ Border bottom [ ] …        │
│ ▸ Page         │                                               │ Keep with next [✓]         │
│ ▸ Theme colors │                                               │ [Reset element]            │
│ ▸ Fonts        │                                               │ ── Dark variant ──         │
│ ▸ Body text    │                                               │ Color (dark) [derived ▾]   │
│ ▾ Headings     │                                               │                            │
│    H1 … H6     │                                               │                            │
│ ▸ Inline       │                                               │                            │
│ ▸ Blocks       │                                               │                            │
│ ▸ Header/footer│                                               │                            │
│ ▸ Advanced     │                                               │                            │
└────────────────┴───────────────────────────────────────────────┴────────────────────────────┘
```

- **Left column** (240 px): theme list (sections *My default*, *My themes*, *Built-in*, *Used
  by this document* when it's a foreign theme) with per-row ⋮ (Duplicate, Rename, Delete, Export
  JSON, Set as my default); below it the **element tree** (`WonkyTreeView`): Page, Theme colors,
  Fonts, Body text, Headings (group + H1–H6), Inline (Bold, Italic, Strikethrough, Inline code,
  Link, Mention), Blocks (Blockquote, Code block, Syntax colors, Lists, Task lists, Horizontal
  rule, Image, Table), Page header & footer, Advanced (overlays, numbering). Elements with
  overrides show a dot; elements with contrast warnings show ⚠.
- **Center**: live preview (`SuperReader` with the draft `ResolvedWriteTheme`), toolbar: preview
  source (*Sample document* — a built-in Markdown file exercising every element, or *This
  document* when `?doc` is set, read from the open document's current Delta, read-only), light/dark
  toggle (independent of app theme), Pages/Pageless toggle (Pages renders page frames like the
  editor, [04-editor.md](04-editor.md) §29, using the document's or default page setup), zoom.
  **Click-to-select**: clicking an element in the preview selects it in the tree/inspector;
  hovering a tree node outlines matching blocks in the preview.
  Preview updates within one frame of a property change (resolution is memoized; only the
  stylesheet is rebuilt).
- **Right column** (320 px): property inspector for the selected element; groups (Text,
  Spacing, Box, element-specific), each property row has a label, typed control, and a reset ⟲
  (shown when overridden at this level; tooltip shows the inherited value and its source, e.g.
  "Inherited from Body: 11pt"). A *Dark variant* section lists color properties whose dark value
  differs (derived ⇢ override).

### 10.3 Controls

| Property type | Control |
|---------------|---------|
| FontRef | `FontPicker` (sections: *Theme fonts* (roles), *Sans*, *Serif*, *Mono*, *Display*; preview in face; search) |
| Length | `WonkyNumberStepper` + unit `ShadSelect` (pt/px/em/mm/in/% — allowed units per property); converting units preserves the visual value |
| FontWeight | `ShadSelect` of shipped weights for the family |
| ColorRef | `WonkyColorPicker` with *Theme colors* row (palette keys, shown as named swatches), *Reset (inherit)*, custom; returns `WonkyColor{hex, themeRef}` stored as `"@key"` when a theme swatch is picked |
| Enums (align, case, style, borders, shape) | `ShadToggleGroup` (≤ 4 options, icons) or `ShadSelect` |
| bool | `ShadSwitch` |
| number ratio / opacity / line height | `ShadSlider` + numeric input |
| Bullets per level | 9 small inputs with glyph presets popover (• ◦ ▪ – ➤ ✓ ★ ▹ ●) |
| Numbering per level | 9 `ShadSelect`s (1., a., A., i., I.) |
| Border | composite: width stepper, style select, color picker |
| Edges | linked/unlinked 4-value editor (chain toggle) |

Slider and stepper drags are coalesced into one draft undo step per gesture.

### 10.4 Draft, save and undo model

- The editor edits a **draft** `WriteThemeData` held by `ThemeEditorController`
  (`ChangeNotifier`). Every property change is a command (`write.theme.setProperty`) recorded on a
  **theme-editor undo scope** (`UndoService` stack keyed `theme-draft:<uuid>`, domain
  `write.theme`, entries `{path, before, after}`); `Mod+Z`/`Mod+Shift+Z` act on it while the
  route is active.
- **Save** (`Mod+S`): `WriteThemeEndpoint.update(uuid, json, expectedVersion)`. On success the
  draft stack is cleared and a single coarse step "Edit theme ‘X’" (domain `write.theme`, `{uuid,
  beforeJson, afterJson, versionAfter}`) is pushed onto the shell stack (the originating
  document is not open while the editor route is). Undoing it later saves `beforeJson` if the server version is still
  `versionAfter` — otherwise dropped with the standard toast.
- **Conflict** (`ThemeConflict`, same theme saved from another window): dialog *Reload theirs*
  (discard draft), *Overwrite* (save with new expectedVersion), *Save as copy*.
- **Revert changes** discards the draft (confirm if > 0 changes). **Reset element** removes all
  overrides of the selected element (one draft step).
- Editing a **built-in** or a **foreign** theme: the inspector is read-only with a banner
  "Built-in themes can't be changed — *Duplicate to customize*". Duplicate creates a user theme,
  navigates to it, and (when opened from a document whose theme was the source) offers *Apply the
  copy to this document*.
- Editing a theme used by documents shared with others shows "Changes affect N documents"
  (from `usage`) next to *Save*.
- Theme create/rename/delete/duplicate are undoable shell-level steps (domain `write.theme`:
  create ↔ delete, rename before/after, delete ↔ restore).
- *Apply to document* (`write.theme.applyToDocument`, shown when opened with `?doc=` and the
  user can edit that document) assigns the theme through `document.updateMeta`; it is a
  `write.theme` shell step `{op: assigned, target: documentUuid, before, after}`.
- Saves (here or by anyone) reach open documents live: the catalog entry is replaced and the
  document's `DocumentThemeController` re-resolves; `MetaChanged(themeVersion)` makes other
  clients refetch (`WriteThemeCatalog.refresh`, read with `viaDocumentUuid`).
- The user's default theme is stored as `writeDefaults.defaultThemeId` (older clients wrote
  `themeUuid`, still read).

### 10.5 Import / export

- **Export JSON**: `<name>.wonkytheme.json` — the canonical JSON plus `{"$schema":
  "https://wonky.work/schemas/write-theme-v1.json", "exportedAt"}`; saved with `file_saver`.
- **Import JSON**: `file_picker` (`.json`, `.wonkytheme.json`) or drag a file onto the theme
  list → parse → migrate → validate → if errors: dialog listing them (cannot import); if
  warnings (unknown props dropped, weights snapped, unknown fonts → role default): list +
  *Import anyway* → creates a new user theme (name de-duplicated "Name (2)").
- **Export CSS** (one-way): standalone CSS via `ThemeCssWriter` (light + dark media query).
- MCP/AI can import by passing JSON to `write.create_theme`.

### 10.6 Contrast checker

`ContrastChecker` (core) computes WCAG 2.x contrast ratios for the resolved draft in **both**
variants for these pairs:

| Foreground | Background |
|------------|------------|
| body text, h1–h6, muted (captions, header/footer) | paper |
| link, mention text | paper / mention bg |
| inline code text | inline code bg (over paper) |
| code block text + each syntax token | code block bg |
| blockquote text | quote bg (over paper) |
| table header text / cell text | header bg / zebra / paper |
| checked task text (with opacity applied) | paper |

Threshold 4.5:1, or 3:1 for large text (≥ 18pt, or ≥ 14pt and weight ≥ 700). Failing pairs show
⚠ in the tree and inspector with ratio and a **Fix** button (adjusts the foreground's lightness
in OKLCH minimally until it passes; one draft undo step). Contrast warnings never block saving.
Exposed to MCP via `write.get_theme` (`contrast_warnings`).

---

## 11. Commands (`wonky_write/lib/commands/theme_commands.dart`)

| Command id | Args | Role | Undoable | Notes |
|------------|------|------|----------|-------|
| `write.theme.apply` | `{themeId: string\|null}` (alias `themeUuid`) | Editor | ✓ (`write.meta`) | `null` = *Use my default theme* |
| `write.theme.useDefault` | — | Editor | ✓ | Alias for apply(null), menu item |
>>>

| `write.theme.openEditor` | `{themeUuid?, element?}` | Viewer | — | Opens `/themes/:uuid?doc=` |
| `write.theme.openManager` | — | Viewer | — | Opens editor on theme list |
| `write.theme.create` | `{name, fromThemeUuid?}` | — (own library) | ✓ (`write.theme`) | |
| `write.theme.duplicate` | `{themeUuid, name?}` | — | ✓ | Also "Copy to my themes" |
| `write.theme.rename` | `{themeUuid, name}` | owner | ✓ | |
| `write.theme.delete` | `{themeUuid}` | owner | ✓ (restore) | Confirm when used by documents |
| `write.theme.setAsDefault` | `{themeUuid}` | — | — (setting) | Writes `writeDefaults.defaultThemeId` |
| `write.theme.selectElement` | `{element}` | — | — | Theme editor navigation |
| `write.theme.setProperty` | `{path: string, value: json\|null, variant?: "light"\|"dark", gesture?: string}` | owner | ✓ (draft) | `path` like `elements.h2.fontSize`, `palette.accent`, `dark.palette.text`; `null` = reset to inherit; steps with the same `gesture` coalesce (drags); `dark.mode = explicit` fills the dark palette with the derived colors |
| `write.theme.resetElement` | `{element}` | owner | ✓ (draft) | |
| `write.theme.fixContrast` | `{pairId}` | owner | ✓ (draft) | |
| `write.theme.revert` | — | owner | — | Discards draft |
| `write.theme.restore` | `{themeUuid?}` | owner | ✓ (delete) | Undelete a soft-deleted theme |
| `write.theme.applyToDocument` | — | Editor on `?doc` | ✓ (`write.theme`) | Theme editor *Apply to document* |
| `write.theme.showRevisions` | — | owner | — | Revision list; *Load* puts a revision into the draft (one draft step) |
| `write.theme.save` | — | owner | ✓ (coarse step) | `Mod+S` in the theme editor |
| `write.theme.setPreviewSource` | `{source: "sample"\|"document"}` | — | — | |
| `write.theme.setPreviewVariant` | `{variant}` | — | — | |
| `write.theme.setPreviewLayout` | `{layout: "pages"\|"pageless"}` | — | — | |
| `write.theme.importJson` | `{json?: string}` (file picker when absent) | — | ✓ | |
| `write.theme.exportJson` | `{themeUuid}` | readable | — | |
| `write.theme.exportCss` | `{themeUuid}` | readable | — | |

All theme editor dialogs (rename, import report, conflict, unsaved changes) are built with
`WonkyDialogSpec` so they are MCP-operable.

---

## 12. MCP tools (headless; definitions in `wonky_core/lib/mcp/write_tools.dart`)

| Tool | Input | Output |
|------|-------|--------|
| `write.list_themes` | `{scope?: "all"\|"builtin"\|"mine" = "all", document_uuid?: string}` (with `document_uuid`: also includes that document's theme even if foreign) | `{themes: [{uuid, name, description, is_builtin, owner, version, updated_at, is_default: bool, used_by_document: bool}]}` |
| `write.get_theme` | `{theme_uuid?: string, document_uuid?: string, variant?: "light"\|"dark", resolved?: bool = false}` (one of the two ids; `document_uuid` alone = the doc's effective theme) | `{uuid, name, version, content_hash, json: object, resolved?: object, contrast_warnings: [{pair, variant, ratio, required}], schema_url}` |
| `write.create_theme` | `{name: string, json?: object, based_on_uuid?: string}` (json validated; if absent, copy of `based_on_uuid` or Wonky Default) | `{theme_uuid, version, warnings: [..]}`, `change_id` |
| `write.update_theme` | `{theme_uuid, patch: object (RFC 7396 JSON merge patch over theme JSON), expected_version?: int, name?: string}` | `{version, warnings, contrast_warnings}`, `change_id` |
| `write.apply_theme` | `{document_uuid, theme_uuid: string\|null}` | `{document_uuid, theme_uuid, revision}`, `change_id` |

- Errors: `not_found`, `forbidden` (not owner / built-in), `validation_failed` (`details:
  [{path, message}]`), `version_conflict` (`details: {current_version}`).
- `changes.revert(change_id)` restores the previous theme JSON / assignment (24 h).
- The JSON schema is exposed as MCP resource `wonky://schemas/write-theme-v1.json`.
- UI bridge: `ui.write.open_theme_editor` ([09-mcp-and-ai.md](09-mcp-and-ai.md)); theme editor
  state through `ui.get_state` (`{theme_editor: {theme_uuid, element, dirty, preview}}`) and
  `ui.invoke_command("write.theme.setProperty", …)`.

---

## 13. Package layout

```
wonky_write_core/lib/theme/
  model/ (write_theme_data.dart, length.dart, color_ref.dart, element_style.dart, …)
  schema/theme_schema_v1.json, validator.dart, migrations.dart
  resolve/theme_resolver.dart, dark_palette_deriver.dart, oklch.dart, contrast_checker.dart
  builtins/*.json + builtins.dart
  mappers/css_writer.dart, pdf_styles.dart, docx_styles.dart, odt_styles.dart, rtf_styles.dart
  numbering/heading_numberer.dart, list_markers.dart (shared marker text generation)
wonky_write_core/lib/highlight/  (syntax tokenizer wrapper)
wonky_write_core/lib/fonts/      (FontProvider, font manifest model)
wonky_write/lib/features/theme/        (WriteStylesheetBuilder, component builders, layers, WriteFontRegistry, ThemeRepository, ThemeCache)
wonky_write/lib/features/theme_editor/ (route, controller, inspector, controls, preview)
wonky_write/lib/commands/theme_commands.dart
wonky_server/lib/src/write/models/write_theme*.spy.yaml
wonky_server/lib/src/write/endpoints/write_theme_endpoint.dart, services/theme_service.dart
wonky_server/lib/src/write/mcp/theme_tools.dart
wonky_write/fonts/ (TTFs, fonts.json, OFL.txt per family)
```

---

## 14. Acceptance criteria

1. Every Markdown element from [02](02-document-model.md) §1 (paragraph, H1–H6, bold, italic,
   strike, inline code, link, mention, quote, code block with language, bullet/ordered/task
   lists at 9 indent levels, rule, image with title, table) renders with theme-defined styles in
   the editor, `SuperReader`, PDF, HTML, DOCX, ODT, RTF and EPUB; no element falls back to
   super_editor defaults.
2. All 8 built-in themes pass validation and contrast checks in light and dark (body/headings
   ≥ 4.5:1).
3. Switching the document theme updates all connected collaborators' editors within 1 s, is a
   single undo step, and survives reload.
4. Saving a theme updates every open document using it (other users included) within 2 s without
   losing caret/selection or scroll position.
5. Theme editor: changing any property updates the preview in < 50 ms (p95) on the sample
   document; undo/redo work for every property change; Revert restores the saved state; leaving
   with unsaved changes prompts.
6. Dark variant: toggling app theme switches the editor to the dark variant instantly; derived
   dark palettes for 50 randomly generated light palettes satisfy contrast ≥ 4.5 for body text.
7. Import of an exported theme JSON reproduces a byte-identical canonical JSON (round trip);
   importing JSON with unknown properties succeeds with warnings.
8. Fonts: every registry font renders in editor (web + desktop) and is embedded in PDF; web
   initial page load downloads no document font files until a document/theme needs them.
9. A collaborator without access to the theme owner's library can open a document using that
   theme, sees it correctly, and can *Copy to my themes*.
10. All `write.theme.*` commands are listed by `ui.list_commands` and invocable via
    `ui.invoke_command`; the five MCP tools pass integration tests through the MCP route.

## 15. Tests

- **Unit (core)**: resolver cascade (table-driven per element/property), unit conversions,
  dark derivation (property test: contrast invariants), contrast checker against WCAG reference
  values, validator/migrations, CSS writer snapshot tests, heading numbering sequences, list
  marker generation (a…z, aa…; i…mmm).
- **Widget**: `WriteStylesheetBuilder` produces expected `Styles` for each selector; inspector
  controls; theme editor flows (create → edit → save → undo); conflict dialog.
- **Golden**: sample document × 8 built-ins × {light, dark} × {pages, pageless} rendered with
  `SuperReader` (Flutter goldens, fonts loaded in test via `FontLoader`); theme editor screen
  light/dark.
- **Cross-renderer consistency**: for each built-in, render the sample to PDF and to a Flutter
  golden; compare block y-positions extracted from both (PDF via text positions from
  `pdftotext -bbox`) — per-block vertical drift ≤ 2 pt on page 1.
- **Server** (`serverpod_test`): endpoint access rules (foreign theme via document, built-ins
  immutable, soft delete), optimistic concurrency, `theme:<uuid>` broadcast →
  `MetaChanged(themeVersion)`.
