# Sheets 06 · Formatting

Cell formatting in depth: format attributes and inheritance, how formatting commands apply to
ranges, paint format, clear formatting, the **number-format language** (Google Sheets / Excel
compatible), text, fill, borders, alignment, wrapping, rotation, merges, rich text runs,
hyperlinks, spreadsheet themes, alternating colors and **conditional formatting**.

Storage is defined in [02-data-model.md](02-data-model.md) (§3.3 `Cell` format columns, §3.4
`MergedRange`, §3.5 `ConditionalFormatRule`, `Banding`, `Spreadsheet.themeJson`). Rendering is in
[03-grid-and-editing.md](03-grid-and-editing.md) §2; menus/toolbar in
[04-screens-menus-toolbar.md](04-screens-menus-toolbar.md) §3.5 and §4.

Code locations:

```
wonky_sheets_core/lib/format/                 # pure Dart, shared with server (exports, MCP, scripts)
  attributes.dart            # FormatAttr enum, FormatValues (bitset + values), ResolvedFormat
  format_resolver.dart       # EffectiveFormatResolver (cell▸row▸col▸sheet▸banding▸theme), CF overlay merge
  number_format/
    parser.dart              # NumberFormatParser (petitparser) → NumberFormatAst
    ast.dart                 # NumberFormat, FormatSection, tokens
    formatter.dart           # NumberFormatter.format(value, locale) → FormattedValue
    presets.dart             # NumberFormatPresets (+ locale resolution of preset ids)
    locale_data.dart         # LocaleFormatData (intl NumberSymbols/DateSymbols, LCID map)
    palette.dart             # [ColorN] palette (Excel 56 colors)
    automatic.dart           # AutomaticFormatter (Automatic/General display rules)
    inference.dart           # FormatInference (auto-detect format from input; used by InputParser)
    decimals.dart            # DecimalsAdjuster (increase/decrease decimals)
    cache.dart               # NumberFormatCache (LRU pattern→AST, (pattern,locale,value)→text)
  borders.dart               # BorderSpec parse/serialize, BorderPresetPlanner, conflict resolution
  rich_text.dart             # RichText (runs) codec/normalizer
  theme.dart                 # SpreadsheetTheme model + presets
  banding.dart               # BandingStyle model + presets
  conditional/
    cf_rule.dart             # CfRule model (ruleJson codec)
    cf_evaluator.dart        # CfEvaluator (per-cell evaluation, stats, caches)
    color_scale.dart, data_bar.dart, icon_set.dart
wonky_sheets/lib/features/
  formatting/                # FormatCommands, FormatWriter (range application), PaintFormatController, ToggleStateQuery
  number_format/             # NumberFormatMenu, Custom* dialogs (04 §11.2–11.4)
  theme/                     # ThemePanel
  banding/                   # AlternatingColorsPanel
  conditional_format/        # CfPanel (list + editor), CfDraftPreview, RulePreviewSwatch
  fonts/                     # CellFontRegistry (bundled cell fonts, lazy loading, substitution)
```

---

## 1. Format attributes and inheritance

### 1.1 Attributes

| Attribute (`Cell` column) | Type / values | Default (theme) | UI |
|---------------------------|---------------|-----------------|----|
| `numberFormat` | pattern string or preset id (§5.1) | `preset:automatic` | Format › Number, toolbar `$ % .0 .00 123` |
| `fontFamily` | font name | `theme.fonts.text` (default `Inter`) | Font picker |
| `fontSize` | pt (double, 1–400) | `Spreadsheet.defaultFontSize` (10) | Size stepper |
| `bold`, `italic`, `underline`, `strikethrough` | bool | false | B I U S |
| `textColor` | `#RRGGBB` / `theme:<key>` | Automatic (`theme:text`, rendered with the `autoText` token when the theme text is default) | Text color |
| `fillColor` | `#RRGGBB` / `theme:<key>` | none | Fill color |
| `hAlign` | left, center, right | null = **general** (§9.1) | Align |
| `vAlign` | top, middle, bottom | bottom | Vertical align |
| `wrap` | overflow, wrap, clip | overflow | Wrapping |
| `rotation` | −90…90, 255 = stacked | 0 | Rotation |
| `borderTop/Right/Bottom/Left` | `"<style>\|<color>"` or `"none"` | no border | Borders |
| `linkUrl` | URL | — | Insert link (not cleared by Clear formatting, §4) |

Color strings: `#RRGGBB` (uppercase hex, no alpha) or `theme:text`, `theme:background`,
`theme:accent1…6`, `theme:link`. Border colors additionally accept `auto` (= Automatic).

### 1.2 Effective format resolution

`EffectiveFormatResolver.resolve(cell)` resolves **each attribute independently** (02 §3.3):

```
CF overlay  ▸  cell explicit  ▸  row.formatJson  ▸  column.formatJson  ▸  sheet.formatJson
            ▸  banding (fill, textColor, bold for header only)  ▸  spreadsheet theme defaults
```

- `null` means "inherit"; explicit values (including `false`, `"none"`) stop inheritance.
- **Conditional formatting** overlays bold/italic/underline/strikethrough/textColor/fillColor
  (§15.9) and wins over everything.
- **Banding** sits *below* any explicit formatting (Google: a fill color you set yourself shows
  over alternating colors).
- **Number-format colors** (`[Red]`) override the resolved text color but not a CF text color.
- **Merged ranges** use the effective format of their top-left cell, except borders (§8.5).
- **Pivot/spill overlays** use the format of the cell they render in (spill) or the pivot spec
  (pivot).

`row/column/sheet.formatJson` is a JSON object whose keys are the `Cell` format column names:
`{"bold":true,"fillColor":"#FCE8B2","numberFormat":"0.00%"}`. Because it is a single
column, concurrent edits to *different attributes of the same row's default format* are LWW for
the whole JSON (documented limitation; rare in practice because whole-row/column formatting is
infrequent and both edits re-apply on retry).

### 1.3 Applying a format to ranges (`FormatWriter`)

All formatting commands call `FormatWriter.apply(ranges, Map<FormatAttr, Object?> values)` inside
one session write (1 undo step, one op group chunked ≤ 5,000 row changes, 02 §7). Strategy per
range kind (03 §6.1 `SelectionKind`):

| Range kind | Writes |
|------------|--------|
| `all` (whole sheet) | `Sheet.formatJson[attr] = v`; set `attr = null` on all `SheetRow/SheetColumn.formatJson` that contain it and on all cells with an explicit value (chunked). |
| `columns` | `SheetColumn.formatJson[attr] = v` for the columns; `attr = null` on explicit cells in those columns; for rows whose `formatJson` contains `attr` (row defaults out-rank column defaults), write explicit cell values at the intersections so the new column format is visible there (Google "last applied wins" behavior). |
| `rows` | `SheetRow.formatJson[attr] = v`; `attr = null` on explicit cells in those rows. |
| `cells` | Explicit `attr = v` on every cell of the range (creating format-only `Cell` rows, deterministic ids). |

- Writes name only the touched columns (`columnValues`, 02 S8).
- A cell row whose fields all become null is deleted (02 §3.3).
- Writing a value equal to the *currently inherited* value still writes it explicitly for `cells`
  ranges (cheap and predictable); `Clear formatting` writes null.
- Pre-flight: a `cells` range creating > 2M format-only cells asks for confirmation; whole
  rows/cols are always cheap.

### 1.4 Toggle and mixed-selection semantics

| Control | Rule |
|---------|------|
| Bold / Italic / Underline / Strikethrough | If **every** cell of the selection (all ranges) is effectively `true` → set `false`; otherwise set `true`. `ToggleStateQuery.allTrue(ranges, attr)` evaluates row/col/sheet defaults plus explicit-cell indices from `CellStore` (attribute bitsets) — never iterates empty cells one by one. |
| Alignment, wrap, rotation, vertical align | Set the chosen value (clicking the current value again does not unset it). |
| Font, size, colors, number format | Set the chosen value. |
| Increase/decrease font size | Each cell moves to the next/previous size in the size list (§6.2) from **its own** current size. |
| Increase/decrease decimals | Per distinct effective pattern in the selection (§5.10). |
| Merge (toolbar main button) | If the selection is exactly one merge → unmerge; else merge all. |
| Toolbar checked/selected states | Reflect the **active cell** only (04 §4). |

While a cell editor has a text selection, B/I/U/S, text color, font, size and link apply to the
selected **run** (§11); other formatting commands are disabled.

**AC-F1**: with A1 bold and A2 not bold, Mod+B on A1:A2 makes both bold; Mod+B again makes both
not bold; each is one undo step.

---

## 2. Paint format

- Toolbar button (🖌) / `sheets.format.paintFormat {sticky: bool}` (—): **single click** arms
  paint format for one application; **double-click** arms it sticky (stays armed until Esc or the
  button is clicked again). The source is the current selection (must be a single range).
- While armed: the source shows marching ants, the cursor is a paint-roller, the button shows
  checked. A click or drag on the grid selects the target; on pointer up →
  `sheets.format.applyPaintFormat {source, target}` (1 step).
- Applies the source's formats exactly like *Paste special › Format only* (03 §12.4): all format
  attributes (incl. number format and borders) and merges, tiled if the target is larger than the
  source; conditional formatting is **not** copied (use paste special).
- Keyboard: arm with the toolbar (Enter), then select the target with Shift+arrows and press
  Enter to apply; Esc disarms.

## 3. Clear formatting

`sheets.format.clear {ranges?}` — `Mod+\` — 1 step.
- Sets all format attributes of §1.1 except `linkUrl` to null on cells; for whole rows/cols/sheet
  also removes those keys from `formatJson`.
- Rich text: formatting runs are removed (text kept); **link runs are kept**.
- Not affected: values, notes, links, data validation, conditional formatting, banding, merges
  (Google parity: clear formatting doesn't unmerge).

## 4. Formats and other operations

| Operation | Effect on formats |
|-----------|-------------------|
| Typing / editing a value | Keeps all formats; may add an auto-detected `numberFormat` (§5.9) |
| Delete key (`sheets.edit.clearValues`) | Keeps formats |
| Insert rows/columns | New rows copy the anchor row's formats (03 §13.1) |
| Fill handle, Mod+D/R/Enter | Copies formats cyclically with content (03 §10.2) |
| Copy/paste | All formats + merges; paste special modes select subsets (03 §12.4) |
| Sort range | Formats move with their cells (cell rows move; row/column defaults stay with the rows/columns) — 07 |
| Move rows/columns | Row/column `formatJson` moves with the entity; cells keep their formats |
| Cut/drag-move | Formats move with content (03 §11) |
| Import | Mapped from XLSX/ODS styles (11) |

---

## 5. Number formats

### 5.1 Storage and presets

`Cell.numberFormat` (and `formatJson.numberFormat`) holds either a **pattern** or a **preset id**
`preset:<name>`. Preset ids exist for formats whose pattern depends on the spreadsheet locale, so
changing the locale re-renders them (Google behavior). The formula engine's result
format hints (05) use the same mechanism: `preset:percent`, `preset:scientific`,
`preset:duration`, `preset:cur` (locale currency) and `preset:cur:<ISO>` (e.g. `preset:cur:EUR`)
resolve like the menu presets. `NumberFormatPresets.resolve(id, locale)`:

| Menu item | Stored | Pattern (en_US) | Pattern (de_DE) | Example (en_US) |
|-----------|--------|-----------------|-----------------|-----------------|
| Automatic | `preset:automatic` | (Automatic rules §5.9) | | `1234.5` |
| Plain text | `@` | `@` | `@` | `0012` |
| Number | `#,##0.00` | `#,##0.00` | (symbols localized) | `1,000.12` |
| Percent | `0.00%` | `0.00%` | | `10.12%` |
| Scientific | `0.00E+00` | `0.00E+00` | | `1.01E+03` |
| Accounting | `preset:accounting` | `_("$"* #,##0.00_);_("$"* \(#,##0.00\);_("$"* "-"??_);_(@_)` | `_-* #,##0.00 [$€-407]_-;-* #,##0.00 [$€-407]_-;_-* "-"?? [$€-407]_-;_-@_-` | `$ (1,000.12)` |
| Financial | `#,##0.00;(#,##0.00)` | same | | `(1,000.12)` |
| Currency | `preset:currency` | `"$"#,##0.00` | `#,##0.00 [$€-407]` | `$1,000.12` |
| Currency rounded | `preset:currencyRounded` | `"$"#,##0` | `#,##0 [$€-407]` | `$1,000` |
| Date | `preset:date` | `M/d/yyyy` | `dd.MM.yyyy` | `9/26/2008` |
| Time | `preset:time` | `h:mm:ss AM/PM` | `HH:mm:ss` | `3:59:00 PM` |
| Date time | `preset:dateTime` | `M/d/yyyy H:mm:ss` | `dd.MM.yyyy HH:mm:ss` | `9/26/2008 15:59:00` |
| Duration | `[h]:mm:ss` | `[h]:mm:ss` | | `24:01:00` |

Locale patterns for presets come from `intl` `DateSymbols`/`NumberSymbols` and the currency of
the locale (`NumberFormat.simpleCurrency(locale)`), converted to our pattern syntax by
`NumberFormatPresets` (unit-tested for the 40 most common locales).

Custom formats picked from the menus are stored as patterns. Recently used custom patterns of a
spreadsheet (max 5) are listed under Format › Number (derived from the patterns present in the
spreadsheet, most recently written first; no extra storage).

### 5.2 Grammar (EBNF; implemented with `petitparser`)

```
format        = section { ";" section }              (* 1–4 sections *)
section       = { condition | color } { item }
condition     = "[" ( "<" | ">" | "=" | "<=" | ">=" | "<>" ) number "]"
color         = "[" ( "Black" | "Blue" | "Cyan" | "Green" | "Magenta" | "Red" | "White" | "Yellow"
                    | "Color" digit [digit] ) "]"             (* case-insensitive; Color1..Color56 *)
item          = digit_ph | "." | "," | "%" | "‰" | exponent | "@" | date_token | elapsed
              | ampm | literal | escape | repeat | spacer | locale_tag | fraction_sep | other
digit_ph      = "0" | "#" | "?"
exponent      = ( "E" | "e" ) ( "+" | "-" ) digit_ph { digit_ph }
date_token    = "d"{1,4} | "m"{1,5} | "y"{2} | "y"{4} | "h"{1,2} | "s"{1,2}
              | ".0" {"0"}                                    (* fractional seconds after s *)
elapsed       = "[" ( "h"+ | "m"+ | "s"+ ) "]"
ampm          = "AM/PM" | "am/pm" | "A/P" | "a/p"
literal       = '"' { any - '"' } '"'
escape        = "\" any
repeat        = "*" any                                       (* fill the cell width with char *)
spacer        = "_" any                                       (* space as wide as char *)
locale_tag    = "[$" { any - ( "-" | "]" ) } [ "-" hex ] "]"  (* currency symbol + LCID *)
fraction_sep  = "/"                                           (* inside a number section: fraction *)
other         = "$" | "-" | "+" | "(" | ")" | ":" | " " | "!" | "^" | "&" | "'" | "~" | "{" | "}"
              | "<" | ">" | "=" | any non-ASCII letter/symbol (* displayed literally *)
```

Parsing is case-insensitive for tokens (`D`/`d`, `M`/`m`, `Y`/`y`, `H`/`h`, `S`/`s`, `E`/`e`,
`General`). The literal word `General` in a section means Automatic display for that section.
Invalid patterns produce a `FormatParseError(position, message)` shown in the custom format
dialog; a stored invalid pattern renders the raw value with Automatic rules and a warning
in the dialog when opened.

### 5.3 Number tokens

| Token | Meaning |
|-------|---------|
| `0` | Digit; pads with zeros (`00.0` on 1.5 → `01.5`) |
| `#` | Digit; no padding; a lone `#` before the decimal point shows nothing for 0 (`#.##` on 0.5 → `.5`) |
| `?` | Digit; pads with a space as wide as a digit (aligns decimals) |
| `.` | Decimal point → locale decimal symbol |
| `,` between digit placeholders | Thousands grouping → locale grouping symbol (Indian grouping for `hi_IN`-style locales: `#,##,##0`) |
| `,` after the last digit placeholder (before `.` or at end of the number part) | Scale by 1/1,000 per comma |
| `%` | Multiply by 100 and show `%` (`‰` multiplies by 1,000) |
| `E+00` / `E-00` | Scientific: mantissa uses the placeholders before `E`; exponent padded to the number of `0`s; `E+` always shows the sign, `E-` only for negatives. If the integer part has *n* placeholders (`##0.0E+0`), the exponent is a multiple of *n* (engineering notation) |
| `/` with digit placeholders | Fraction: `# ?/?` (proper fraction with integer part), `?/?` (improper), denominator placeholders bound the denominator digits; a fixed denominator (`# ?/16`) rounds to that denominator; best rational approximation by continued fractions within the digit bound |
| `@` | The text value (text section) |
| `"…"`, `\c` | Literal text |
| `*c` | Repeat `c` to fill the column width (painter expands, §5.12) |
| `_c` | A space as wide as `c` (e.g. `_)` aligns positives with parenthesized negatives) |
| `[$sym-LCID]` | Currency symbol `sym` (may be empty) and optional locale id (hex LCID) — §5.7 |

Rounding: **half away from zero** applied on the decimal (shortest round-trip) representation of
the double, so `0.12345 → 12.35%` and `2.675 → 2.68` (not binary-floating artifacts). Values are
first rounded to 15 significant digits.

Negative sign: with a single section, negatives show `-` before the first digit or literal that
follows a leading sign position (Excel behavior: `-$5.00` for `"$"0.00`). With ≥ 2 sections, the
second section gets the **absolute** value and shows only what it contains (`(5.00)`).

### 5.4 Sections and conditions

| Sections | Applied to |
|----------|------------|
| 1 | All numbers (negatives get a `-`); text shown as is unless the section contains `@` |
| 2 | 1st: ≥ 0, 2nd: < 0 |
| 3 | 1st: > 0, 2nd: < 0, 3rd: = 0 |
| 4 | as 3 + 4th: text |

- With **conditions**: sections are tested in order: up to two conditional sections; the next
  unconditioned section is the fallback (Excel semantics: `[>1000]#,##0,"K";[>0]0;0`). In
  conditional sections the value is shown **with its sign** (no absolute value).
- Booleans display as `TRUE`/`FALSE` regardless of number format (locale-translated when the
  spreadsheet display language is set, P2). Errors are never formatted.
- Text in a format without a text section shows as is; a text section without `@` hides the text
  (shows the literal only).
- An empty section hides values of that kind (`0;-0;;@` hides zeros).

### 5.5 Colors

`[Black] [Blue] [Cyan] [Green] [Magenta] [Red] [White] [Yellow]` and `[Color1]`…`[Color56]`
(Excel default palette, defined in `palette.dart`; e.g. 1 `#000000`, 2 `#FFFFFF`, 3 `#FF0000`, 4
`#00FF00`, 5 `#0000FF`, 6 `#FFFF00`, 7 `#FF00FF`, 8 `#00FFFF`, 9 `#800000`, 10 `#008000`, 11
`#000080`, 12 `#808000`, 13 `#800080`, 14 `#008080`, 15 `#C0C0C0`, 16 `#808080` …). Named colors
map to `#000000 #0000FF #00FFFF #00FF00 #FF00FF #FF0000 #FFFFFF #FFFF00`. In dark app mode these
remain absolute (03 §2.9).

### 5.6 Dates, times and durations

| Token | Output (2026-10-12 14:05:09.5, Monday) |
|-------|----------------------------------------|
| `d` / `dd` | `12` / `12` (day; `dd` zero-padded) |
| `ddd` / `dddd` | `Mon` / `Monday` (locale) |
| `m` / `mm` | month `10` / `10` — or **minutes** when directly after `h`/`hh` (ignoring literals/separators) or directly before `s`/`ss` |
| `mmm` / `mmmm` / `mmmmm` | `Oct` / `October` / `O` |
| `yy` / `yyyy` | `26` / `2026` (`y`/`yyy` treated as `yy`/`yyyy`) |
| `h` / `hh` | `14` / `14` (12-hour when an AM/PM token is present: `2` / `02`) |
| `s` / `ss` | `9` / `09` |
| `ss.0`, `ss.00`, `ss.000` | `09.5`, `09.50`, `09.500` (fractional seconds) |
| `AM/PM`, `am/pm`, `A/P`, `a/p` | `PM`, `pm`, `P`, `p` (locale AM/PM strings for `AM/PM`) |
| `[h]`, `[hh]` | elapsed hours (no wrap at 24): 1.5 days → `36` |
| `[m]`, `[mm]`, `[s]`, `[ss]` | elapsed minutes / seconds |

- **Serial date system**: value = days since **1899-12-30** (00:00), fraction = time of day.
  Serial 1 = 1899-12-31, 61 = 1900-03-01 (identical to Excel for serials ≥ 61; Excel's fictitious
  1900-02-29 does not exist here). Negative serials represent dates before 1899-12-30 (valid down
  to year 1, Google behavior). Max = 9999-12-31 (2,958,465); values outside the supported range
  with a date format render the raw number with Automatic rules (Google behavior).
- Times are wall-clock values without time zone; `NOW()`/`TODAY()` and *Insert date/time*
  (03 §7.2) use the **spreadsheet time zone** (`Spreadsheet.timeZone`, IANA, via `timezone` data
  bundled in `wonky_sheets_core`).
- Seconds are rounded to the shown precision before carrying (59.6 s with `ss` → next minute).
- **Durations**: elapsed tokens; negative durations show `-` (`-12:00:00`).
- Locale: month/day names and AM/PM from `intl` `DateSymbols` of the spreadsheet locale.
- **Custom date and time dialog** (04 §11.3) edits the same patterns via a chip builder; chips map
  1:1 to tokens (`Day: 1 → d, 01 → dd, Tue → ddd, Tuesday → dddd; Month: 8 → m, 08 → mm, Aug →
  mmm, August → mmmm, A → mmmmm; Year: 08 → yy, 2008 → yyyy; Hour: 1 → h, 01 → hh, elapsed →
  [h]; Minute: 1 → m, 01 → mm; Second: 1 → s, 01 → ss; Millisecond: .0 → .000; AM/PM`).

### 5.7 Currency and locale tags

- `[$€]` inserts `€`; `[$€-407]` inserts `€` and records LCID `0x407` (de-DE). In Wonky Sheets the
  **separators always follow the spreadsheet locale**; the LCID only selects month/day names and
  AM/PM text for date tokens in that section (Excel behavior) and is preserved for XLSX
  round-trip. LCID ↔ locale map: the 120 most common LCIDs (`locale_data.dart`).
- `[$USD]` → literal `USD` (ISO codes allowed).
- *Custom currency* dialog builds patterns: symbol before/after, with/without space, decimals,
  negative style (`-`, parentheses, red): e.g. `[$€]#,##0.00`, `#,##0.00 [$€]`,
  `[$€]#,##0.00;[Red]-[$€]#,##0.00`.

### 5.8 Locale-aware symbols

`NumberFormatter` maps pattern placeholders to the spreadsheet locale's symbols: decimal
(`.`/`,`), grouping (`,`/`.`/`U+202F` narrow no-break space for fr_FR/`'` for de_CH), percent,
minus (`-` ASCII always, for predictable copy/paste), exponent `E`. Digits are always ASCII
(Latin) in v1; native digit shaping is P2. The function argument separator (`,` vs `;`) follows the
locale's decimal separator (05).

### 5.9 Automatic format and auto-detection

**Automatic display** (`AutomaticFormatter`, also used for the `General` keyword):
- Integers with |x| < 10¹⁵ → all digits, no grouping (`123456789012`).
- Other numbers → rounded to **10 significant digits**, trailing zeros trimmed (`=1/3` →
  `0.3333333333`, `=PI()` → `3.141592654`, `0.1+0.2` → `0.3`).
- |x| ≥ 10¹⁵ or 0 < |x| < 10⁻⁹ → scientific with up to 5 decimals (`1E+15`, `1.23457E+18`).
- If the text doesn't fit the column width, decimals are reduced (down to 0), then scientific,
  then `####` (painter-driven: `AutomaticFormatter.fit(value, maxWidthPx, measure)`).
- Formula results with Automatic format use the engine's **format hint** (05: e.g. `=A1+1` where
  A1 is a date → date; `=SUM(currency cells)` → currency; `=NOW()` → date time; `=0.5*100%`…).

**Auto-detection on input** (`FormatInference`, invoked by `InputParser`, 03 §8.6): when the
target cell's effective format is Automatic (or `preset:automatic`), committing typed input that
was recognized as percent / currency / date / time / datetime / duration / scientific /
grouped-number writes `numberFormat` explicitly in the same transaction:

| Input | Detected pattern |
|-------|------------------|
| `12%`, `12.50%` | `0%`, `0.00%` (decimals as typed) |
| `$1,200`, `$1,200.5`, `€12`, `12 €` | `"$"#,##0`, `"$"#,##0.00` (`$` in every locale); other symbols as `[$sym]` without LCID where typed: `[$€]#,##0`, `#,##0 [$€]`; decimals as typed (0, else at least 2) |
| `1,234`, `1,234.5` | `#,##0`, `#,##0.0` |
| `1.5E3` | `0.00E+00` |
| dates | `preset:date`, date times `preset:dateTime`; ISO input keeps the typed shape (`yyyy-mm-dd`, `yyyy-mm-dd hh:mm[:ss]`) |
| times (`14:30`, `2:30 PM`, `14:30:15`, `14:30:15.5`) | the typed shape: `h:mm`, `h:mm AM/PM`, `h:mm:ss`, `h:mm:ss.000` (` AM/PM` appended when typed with AM/PM) — as 03 §8.6 |
| `0 1/2`, `1 3/16` | `# ?/?`, `# ??/??` (mixed fraction; a bare `1/2` is a date) |
| `36:15:00`, `36:15` | `[h]:mm:ss`, `[h]:mm` |

Detection never overrides an explicit non-Automatic format (typing `5%` into a `0.00` cell stores
0.05 and keeps `0.00` → shows `0.05`).

### 5.10 Increase / decrease decimals (`sheets.format.increaseDecimals` / `decreaseDecimals`)

For each distinct effective pattern in the selection (`DecimalsAdjuster`):
- **Automatic**: derive the displayed decimals *d* of the active cell's value under Automatic;
  new pattern = `#,##0` + (`.` + `0`×(d±1) if > 0) — Google behavior.
- **Patterns**: in every numeric section, add a `0` after the last decimal placeholder (or insert
  `.0` after the last integer placeholder if none); decrease removes the last decimal placeholder
  (and the `.` when none remain). Scientific mantissas, percentages, fractions (no-op), currency
  patterns handled the same way; text sections untouched.
- **Dates/times**: adjust fractional seconds (`ss` ⇄ `ss.0` ⇄ `ss.00` ⇄ `ss.000`); no-op without
  seconds.
- Preset ids are first resolved to their locale pattern; result stored as a pattern.
- Max 30 decimals. 1 step.

### 5.11 Formatter API and caching

```dart
class NumberFormatter {
  /// Formats [value] (num, String, bool, CellError) for display. Pure, synchronous, cached.
  FormattedValue format(CellValue value, String patternOrPreset, LocaleFormatData locale);
}

class FormattedValue {
  final List<FormatSegment> segments; // text | spacer(width of char) | repeat(char)
  final int? colorArgb;               // from [Red] / [ColorN]
  final bool overflowHashes;          // caller should render "####" if it doesn't fit (numbers/dates)
  String get plainText;               // segments flattened (repeat → nothing, spacer → ' ')
}
```

- `NumberFormatCache`: pattern → AST (LRU 2,000), and `(patternId, localeId, valueBits)` →
  `FormattedValue` (LRU 50,000; value cache cleared on locale change). Target: ≤ 1 µs per cached
  format, ≤ 20 µs uncached on desktop.
- The same formatter is used by the grid painter, clipboard (TSV/HTML), CSV/PDF export (11), MCP
  `formatted` values (12), charts axes/labels (08) and `TEXT()` (05 reuses the parser/formatter;
  `TEXT` uses the same token semantics).
- **As built (CQ-50):** `TEXT()`, `TO_TEXT`, `DOLLAR`, `FIXED` and QUERY `format` call
  `NumberFormatTextFormatter` (the engine's default `textFormatter`), which formats through
  `NumberPatternFormatter.instance` and flattens to `plainText`; the formula engine's own
  1,100-line formatter is deleted, so `=TEXT(A1, "<A1's format>")` gives what A1 shows. Invalid
  patterns and the internal `preset:*` ids give `#VALUE!`; an empty pattern gives `""` for
  numbers. Where the two used to disagree, TEXT() now follows the display: a negative value
  rounding to zero keeps its sign (`-0.00`), fractions keep their alignment padding (`" 1/3"`,
  `"1    "`), the else section of a conditional format adds the minus sign, serials past
  9999-12-31 format as dates/times (still open: `#####` like Excel?), month and weekday
  abbreviations are CLDR's (`Dez.`, `März`), `AM/PM` keeps the pattern's case. Vectors:
  `test/fixtures/text_format_vectors.tsv` (3,375 pairs where both agreed, en_US and de_DE) and
  `test/formula/functions/text_format_vectors_test.dart`.

### 5.12 Rendering rules

- `*c` repeat: painter fills remaining width with `c` at the token's position (one per section);
  `_c` spacer: blank of the width of `c` in the cell font.
- Numbers and dates that don't fit render `####` (03 §2.6); text formats overflow normally.
- Number-format color applies to the whole cell text.
- Alignment of formatted numbers follows general alignment (§9.1) unless `hAlign` is set.

### 5.13 Test vectors (`format/number_format_test.dart`; locale en_US unless noted)

| # | Pattern | Value | Expected |
|---|---------|-------|----------|
| 1 | `#,##0.00` | 1234.567 | `1,234.57` |
| 2 | `#,##0.00` | -1234.567 | `-1,234.57` |
| 3 | `0.00%` | 0.12345 | `12.35%` |
| 4 | `0%` | 1 | `100%` |
| 5 | `0.00E+00` | 12345 | `1.23E+04` |
| 6 | `0.0E+0` | 0.000123 | `1.2E-4` |
| 7 | `##0.0E+0` | 12345 | `12.3E+3` |
| 8 | `0.###` | 1.5 | `1.5` |
| 9 | `0.###` | 2 | `2.` |
| 10 | `#` | 0 | `` (empty) |
| 11 | `0` | 2.5 | `3` |
| 12 | `0` | -2.5 | `-3` |
| 13 | `0.00` | 2.675 | `2.68` |
| 14 | `#,##0;(#,##0)` | -1234 | `(1,234)` |
| 15 | `#,##0;[Red](#,##0);"-"` | 0 | `-` |
| 16 | `#,##0;[Red](#,##0);"-"` | -5 | `(5)` + color `#FF0000` |
| 17 | `0.0,,"M"` | 1234567 | `1.2M` |
| 18 | `#,##0,"K"` | 15300 | `15K` |
| 19 | `000-00-0000` | 123456789 | `123-45-6789` |
| 20 | `# ?/?` | 1.25 | `1 1/4` |
| 21 | `# ??/??` | 3.14159265 | `3 14/99` |
| 22 | `"$"#,##0.00` | 3.5 | `$3.50` |
| 23 | `\$0` | 5 | `$5` |
| 24 | `0 "items"` | 1 | `1 items` |
| 25 | `0;-0;0;"Text: "@` | `abc` | `Text: abc` |
| 26 | `[>1000]#,##0,"K";0` | 1500 | `2K` |
| 27 | `[>1000]#,##0,"K";0` | 500 | `500` |
| 28 | `yyyy-mm-dd` | 46307 | `2026-10-12` |
| 29 | `dddd, mmmm d, yyyy` | 46307 | `Monday, October 12, 2026` |
| 30 | `ddd d mmm yy` | 46307 | `Mon 12 Oct 26` |
| 31 | `mmm-yy` | 46307 | `Oct-26` |
| 32 | `mmmmm` | 46307 | `O` |
| 33 | `m/d/yyyy h:mm` | 46307.5 | `10/12/2026 12:00` |
| 34 | `h:mm AM/PM` | 0.75 | `6:00 PM` |
| 35 | `h AM/PM` | 0 | `12 AM` |
| 36 | `h:mm A/P` | 0.25 | `6:00 A` |
| 37 | `hh:mm:ss` | 0.5 | `12:00:00` |
| 38 | `[h]:mm` | 1.5 | `36:00` |
| 39 | `[mm]:ss` | 0.0625 | `90:00` |
| 40 | `[h]:mm:ss` | -0.5 | `-12:00:00` |
| 41 | `ss.000` | 0.5/86400 | `00.500` |
| 42 | `dd.mm.yyyy hh:mm:ss` | 46307.75 | `12.10.2026 18:00:00` |
| 43 | `dddd` (de_DE) | 46307 | `Montag` |
| 44 | `yyyy"年"m"月"d"日"` (ja_JP) | 46307 | `2026年10月12日` |
| 45 | `#,##0.00` (de_DE) | 1234.5 | `1.234,50` |
| 46 | `#,##0.00` (fr_FR) | 1234.5 | `1 234,50` (U+202F) |
| 47 | `[$€-407]#,##0.00` (en_US) | 1234.5 | `€1,234.50` |
| 48 | `#,##0.00 [$€-407]` (de_DE) | 1234.5 | `1.234,50 €` |
| 49 | `preset:currency` (en_US / de_DE) | 1000.123 | `$1,000.12` / `1.000,12 €` |
| 50 | `preset:date` (en_US / de_DE) | 46307 | `10/12/2026` / `12.10.2026` |
| 51 | `[Color10]0` | 7 | `7` + color `#008000` |
| 52 | `@` | 123 (number) | `123` (numbers shown with Automatic in a text-only format) |
| 53 | Automatic | `=1/3` | `0.3333333333` |
| 54 | Automatic | `=PI()` | `3.141592654` |
| 55 | Automatic | 123456789012 | `123456789012` |
| 56 | Automatic | 1E+15 | `1E+15` |
| 57 | Automatic | 0.1+0.2 | `0.3` |
| 58 | `0.00` | `TRUE` (bool) | `TRUE` |
| 59 | `0.00` | `#DIV/0!` | `#DIV/0!` |
| 60 | `0;-0;;@` | 0 | `` (empty) |

Parser error vectors: `0.00"` (unterminated literal, pos 4), `[Colr3]0` (unknown color), `0;0;0;0;0`
(more than 4 sections), `[>1000` (unclosed bracket).

---

## 6. Text formatting

### 6.1 Cell fonts (`CellFontRegistry`)

Curated **bundled** cell fonts (no runtime Google Fonts; suite 02 §2), files under
`wonky_sheets/assets/fonts/cells/` (regular, bold, italic, bold-italic each):

| Group | Fonts |
|-------|-------|
| Default / UI-like | **Inter** (default, ships with shad), Roboto, Open Sans, Lato, Source Sans 3, Noto Sans, Nunito, Montserrat, Oswald |
| Serif | Merriweather, Lora, Playfair Display, Noto Serif |
| Mono | JetBrains Mono, Roboto Mono, Source Code Pro (Courier Prime is not offered: JetBrains Mono is the suite's monospace face) |
| Handwriting/display | Caveat, Comfortaa |
| Metric-compatible (XLSX fidelity) | Arimo (≈ Arial/Helvetica), Tinos (≈ Times New Roman), Cousine (≈ Courier New), Carlito (≈ Calibri), Caladea (≈ Cambria), Gelasio (≈ Georgia) |

> **As built (phase 2).** Bundled: Inter, Geist, Geist Mono (from `shad`) and static OFL faces of
> Open Sans, EB Garamond and JetBrains Mono (`wonky_fonts`' package assets, `packages/wonky_fonts/fonts/` — Sheets' own copy was dropped in CQ-64g —, loaded on demand by
> `CellFonts`, `features/formatting/cell_fonts.dart`). Every other name — including the theme
> presets' fonts — is stored unchanged and displayed by category (serif → EB Garamond, mono →
> JetBrains Mono, else Inter); the picker labels it "X (displayed as Y)". The font menu has
> *Theme font*, *Recent* (session) and *All fonts* sections. Live previews of CF rules,
> alternating colors and themes go through `WorkbookModel.previewTheme` /
> `WorkbookModel.bandingPreview` and `CfEvaluator.setDraft`; `RangeInput`'s ⊞ toggles
> "follow the grid selection" instead of a modal picking card.

- Web: only Inter is in the initial bundle; other families load on first use via `FontLoader`
  from the app's own origin (cached by the service worker for offline); until loaded, cells render
  with Inter and repaint when ready (tile invalidation).
- **Substitution**: unknown names (from imports/pastes) are stored unchanged (round-trip) and
  rendered via a substitution map (Arial/Helvetica → Arimo, Times New Roman → Tinos, Courier New
  → Cousine, Calibri → Carlito, Cambria → Caladea, Georgia → Gelasio, Verdana/Tahoma/Segoe UI →
  Inter, others → Inter). The font picker shows such names in italic with tooltip "Displayed as
  Arimo".
- `FontPicker` (suite 02 §4.11) sections: *Theme font*, *Recent* (per user), *All fonts*.
  `sheets.format.fontFamily {family, ranges?}` (1 step).

### 6.2 Font size

Menu list `6 7 8 9 10 11 12 14 18 24 36`; toolbar stepper accepts 1–400 (decimals allowed, one
place). `sheets.format.fontSize {size}`; `sheets.format.increaseFontSize` (`Mod+Shift+.`) /
`decreaseFontSize` (`Mod+Shift+,`) step through `6 7 8 9 10 11 12 14 18 24 36 48 72 96` per cell
(§1.4). Row heights auto-grow for rows with automatic height (03 §13.6).

### 6.3 Styles and color

- `sheets.format.bold` (Mod+B), `italic` (Mod+I), `underline` (Mod+U), `strikethrough`
  (Win/Linux `Alt+Shift+5`, macOS `⇧⌘X`) — toggles per §1.4.
- `sheets.format.textColor {color | null}` — `WonkyColorPicker`; *Reset* = Automatic (null).
  Theme colors row inserts `theme:accentN` references; custom colors stored as hex.
- Underline and strikethrough draw 1 px (× zoom, snapped) lines in the text color; link underline
  uses the link color.

## 7. Fill color

`sheets.format.fillColor {color | null}` — `WonkyColorPicker`; *Reset* = none (null). The picker
footer has *Alternating colors…* (→ panel §14) and *Conditional formatting…*. Fill paints over
gridlines (03 §2.4).

---

## 8. Borders

### 8.1 Styles

| Style | Width at 100 % | Rendering | Weight (conflict order) |
|-------|---------------|-----------|-------------------------|
| `thin` | 1 px | solid | 2 |
| `medium` | 2 px | solid | 4 |
| `thick` | 3 px | solid | 6 |
| `dashed` | 1 px | dash 3 / gap 2 | 3 |
| `dotted` | 1 px | dot 1 / gap 1 | 1 |
| `double` | 3 px | two 1 px lines with 1 px gap | 5 |

Widths scale with zoom (min 1 physical px) and are pixel-snapped (03 §2.3). Color: `#RRGGBB`,
`theme:<key>` or `auto` (= `autoBorder` token, black in light mode, light grey in dark).

### 8.2 Storage

Each cell edge is `"<style>|<color>"` (e.g. `"thin|#000000"`, `"medium|auto"`) or `"none"`
(explicitly no border; stops inheritance from row/column defaults) or null (inherit).

### 8.3 Border picker presets → edges (`BorderPresetPlanner`)

For a range with rows `r1..r2`, columns `c1..c2` (merges treated as their bounding cells):

| Preset | Writes (value `v = style\|color`) |
|--------|----------------------------------|
| all | outer + inner horizontal + inner vertical |
| inner | inner horizontal + inner vertical |
| horizontal | inner horizontal: `borderBottom = v` on rows `r1..r2-1` |
| vertical | inner vertical: `borderRight = v` on columns `c1..c2-1` |
| outer | top + bottom + left + right |
| top | `borderTop = v` on row `r1`, columns `c1..c2` |
| bottom | `borderBottom = v` on row `r2` |
| left | `borderLeft = v` on column `c1` |
| right | `borderRight = v` on column `c2` |
| clear | all four edges of every cell in the range = null, plus the facing edges of the neighbours just outside the range (cell above's bottom, etc.) = null |

**Canonical edge ownership**: inner lines are stored on the **upper/left** cell (bottom/right
edge). Whenever an edge is written, the **facing edge** of the adjacent cell (e.g. writing
`A2.borderTop` → `A1.borderBottom`) is set to null if non-null, so the newly written edge is
authoritative and the conflict rule (§8.4) never surprises the user. Whole-row/column ranges use
`formatJson` for the uniform edges (e.g. *all* on columns B:C writes `borderLeft/Right/Top/Bottom`
into the columns' `formatJson`) and explicit cells only for range-boundary edges (*outer* on
columns writes left/right into `formatJson`, and top/bottom on the first/last row's cells).

Command: `sheets.format.borders {preset, style = thin, color = auto, ranges?}` (1 step).
Shortcuts (Win/Linux `Alt+Shift+n`, macOS `⌥⇧n`): 1 = top, 2 = right, 3 = bottom, 4 = left,
6 = clear, 7 = outer (thin, auto color). (5 is strikethrough.)

### 8.4 Conflict resolution (render)

For a shared edge (A1.bottom vs A2.top; B1.left vs A1.right): render the style with the higher
weight (§8.1); if equal weight, the **top/left** cell's edge wins (02 §3.3). Color comes from the
winning edge. `"none"` loses against any visible style.

### 8.5 Borders and merges

The border of a merged range is composed from its boundary cells' outer edges (top edge = top
edges of the top row cells, per column segment); interior edges are not drawn. Merging keeps the
boundary cells' borders; unmerging restores per-cell borders as stored.

**AC-B1**: *outer* thick red on B2:D4 then *inner* thin on the same range produces a 3×3 grid
with a thick red frame; undo of the second step leaves only the frame.

---

## 9. Alignment, wrapping, rotation

### 9.1 Horizontal alignment

`hAlign` null = **general alignment**: numbers (including dates, times, durations, percent,
currency) right; text left; booleans center; errors center; checkboxes center; dropdown chips
left. Explicit `left | center | right` override. Commands `sheets.format.hAlign {align}` with
shortcuts `Mod+Shift+L / E / R`. Padding 3 px (× zoom) left/right.

### 9.2 Vertical alignment

`top | middle | bottom` (default bottom). `sheets.format.vAlign {align}`. Padding 2 px.

### 9.3 Wrapping

`overflow` (default), `wrap`, `clip` — `sheets.format.wrap {strategy}`. Semantics and painting in
03 §2.6. `wrap` on rows with automatic height grows the row to the tallest wrapped cell (03
§13.6); `clip` never changes row height (except explicit `\n`).

### 9.4 Rotation

`rotation` −90…90 degrees (positive = counter-clockwise, "tilt up"), `255` = vertical stacked.
Menu items: None (0), Tilt up (45), Tilt down (−45), Stack vertically (255), Rotate up (90),
Rotate down (−90), Custom angle (popover, 04 §11.21). `sheets.format.rotation {angle}`.
- Painting rotates the text block about the cell's anchor point given by alignment; rotated text
  is clipped to the cell (no overflow) in v1; automatic row height = `w·|sin θ| + h·|cos θ|`.
- Stacked: each grapheme on its own line, centered; row height grows.
- Borders are not slanted (Google slants them; P2).

## 10. Merge cells

Commands: `sheets.format.merge {mode: all | horizontal | vertical, ranges?}`,
`sheets.format.unmerge {ranges?}` (1 step each). Storage: `MergedRange` rows with all four bounds
(02 §3.4).

| Mode | Result |
|------|--------|
| all | One merge covering each selected range |
| horizontal | One merge per row of each range (single-row ranges only make sense; 1-column ranges → no-op) |
| vertical | One merge per column of each range |

Rules:
- **Data loss warning**: if any cell other than the kept one(s) has content, show the merge
  warning dialog (04 §11.11); on OK, those contents are cleared in the same step (Google keeps
  only the top-left value; horizontal keeps the leftmost per row, vertical the topmost per column).
- On merge, the kept cell's non-border format attributes are **copied** to all other cells of the
  merge (so unmerge yields uniformly formatted cells, Google behavior); boundary borders kept.
- New merges replace any existing merges they overlap (deleted in the same step).
- Refused (toast/dialog with reason): merging across the frozen boundary ("You can't merge frozen
  and non-frozen cells"), merges that would partially overlap a pivot output, merges in a filtered
  range with hidden rows, ranges of 1 cell, more than 50,000 merges per sheet.
- **Unmerge**: deletes `MergedRange` rows intersecting the selection.
- Grid behaviors (selection, navigation, editing) in 03 §13.7; sort/filter interactions in 07
  (sorting ranges with merges of different shapes is refused).
- Invariant after concurrent merges (02 §8): overlapping merges → keep the smaller id.

## 11. Rich text runs

Stored as content `r:` + JSON (02 §2):

```json
{"t":"Total revenue (EUR)","runs":[
  {"s":0,"e":5,"f":{"bold":true}},
  {"s":15,"e":18,"f":{"textColor":"#D93025","link":"https://example.com/fx"}}]}
```

- `s`/`e`: UTF-16 code-unit offsets, `[s, e)`, non-overlapping, sorted; text outside runs uses the
  cell format.
- `f` keys: `bold`, `italic`, `underline`, `strikethrough`, `textColor`, `fontFamily`,
  `fontSize`, `link`, and (P2) `chip` (03 §20).
- **Normalization** (`RichText.normalize`): merge adjacent runs with equal `f`; drop empty runs
  and keys equal to the cell format; if no run remains → store plain `s:`; a single `link` run
  covering the whole text → `linkUrl` + plain text.
- Editing: 03 §8.8. Formulas, numbers, booleans can't have runs. Pasting HTML with partial
  styling creates runs (03 §12.5).
- Precedence when painting: CF attributes (cell-wide) > run attributes > cell format.
- `sheets.format.*` text commands applied to a **cell selection** (not in-editor) set the
  cell-level attribute and **remove that key from all runs** (so the whole cell becomes uniform).
- Export: XLSX rich text runs (`<r>`), HTML spans, CSV plain text (11).

## 12. Hyperlinks

- Whole-cell link: `Cell.linkUrl`; partial links: runs with `link`. `HYPERLINK(url, label)`
  formula results also render as links (05).
- Allowed schemes: `http`, `https`, `mailto`, internal `#sheet=<sheetId>&range=<A1>` (and
  `#range=<namedRange>`). Others are stored but rendered as plain text with a warning icon.
- Auto-link on input: text that is entirely a URL/email becomes `linkUrl` (03 §14.4).
- Commands: `sheets.insert.link {url, text?}` (Mod+K), `sheets.link.remove`. Link color =
  `theme.colors.link`; underline unless the cell explicitly sets `underline: false`.
- Clear formatting keeps links (§3).

---

## 13. Spreadsheet theme

### 13.1 Model (`Spreadsheet.themeJson`)

```json
{
  "v": 1,
  "name": "Standard",
  "fonts": { "text": "Inter" },
  "colors": {
    "text": "#000000", "background": "#FFFFFF",
    "accent1": "#4285F4", "accent2": "#EA4335", "accent3": "#FBBC04",
    "accent4": "#34A853", "accent5": "#FF6D01", "accent6": "#46BDC6",
    "link": "#1155CC"
  }
}
```

- `fonts.text` is the default cell font; `Spreadsheet.defaultFontFamily` is kept equal to it
  (both columns written by `sheets.theme.set`; readers prefer `themeJson`).
- Theme color references (`theme:accent3`) in cell text/fill/border colors, CF formats, banding,
  chart series (08) and tab colors resolve at render time, so changing the theme updates them.
- `background` is the default *cell* background for printing/exports and charts; in dark app
  mode the grid still uses the `sheetBackground` token unless the theme background is
  non-default (then cells render with the theme background as an explicit fill).

### 13.2 Presets (`theme.dart`)

| Preset | Font | Accents 1–6 | Link |
|--------|------|-------------|------|
| Standard | Inter | `#4285F4 #EA4335 #FBBC04 #34A853 #FF6D01 #46BDC6` | `#1155CC` |
| Simple | Roboto | `#3C78D8 #6AA84F #F1C232 #CC0000 #674EA7 #E69138` | `#1155CC` |
| Streamline | Lato | `#2C3E50 #3498DB #1ABC9C #F39C12 #E74C3C #9B59B6` | `#2980B9` |
| Paperback | Merriweather | `#5D4037 #8D6E63 #A1887F #BCAAA4 #D7CCC8 #6D4C41` | `#5D4037` |
| Marina | Source Sans 3 | `#00796B #0097A7 #0288D1 #26A69A #80CBC4 #004D40` | `#00796B` |
| Coral | Nunito | `#FF7043 #FFAB91 #F4511E #FFCCBC #BF360C #FF8A65` | `#D84315` |
| Forest | Open Sans | `#2E7D32 #66BB6A #A5D6A7 #558B2F #9CCC65 #1B5E20` | `#2E7D32` |
| Mono | JetBrains Mono | `#212121 #424242 #616161 #757575 #9E9E9E #BDBDBD` | `#1A73E8` |
| Retro | JetBrains Mono | `#E76F51 #F4A261 #E9C46A #2A9D8F #264653 #8AB17D` | `#264653` |
| Ocean | Montserrat | `#023E8A #0077B6 #0096C7 #00B4D8 #48CAE4 #90E0EF` | `#0077B6` |

### 13.3 Theme panel (`sheets.panel.theme`)

- List of preset cards (font name rendered in its font, 6 accent swatches, preview mini-table) —
  click applies to the **draft** (live preview); current theme highlighted.
- *Customize*: text font (`FontPicker`), text color, background, accent 1–6, link color (each a
  `WonkyColorPicker` without theme row), *Reset to preset*.
- [Done] commits `sheets.theme.set {themeJson}` (1 step); [Cancel] discards.
- *Import theme* (P2): copy a theme from another spreadsheet (drive picker). Built: the panel's
  *Import theme* previews it until Done; `sheets.theme.import {sourceItemUuid?}` applies it in one
  step (server `SheetsEndpoint.spreadsheetTheme`).

---

## 14. Alternating colors (banding)

### 14.1 Model (`Banding.styleJson`)

```json
{"v":1,"header":"#5B95F9","firstBand":"#FFFFFF","secondBand":"#E8F0FE",
 "footer":"#ACC9FE","showHeader":true,"showFooter":false,"dimension":"rows"}
```

- Colors may be theme references. `dimension: columns` (column banding) is P2.
- Header row = first row of `rangeJson`, footer = last row (when enabled); bands alternate on
  **visible** rows (filter-hidden and user-hidden rows are skipped, Google behavior).
- Header bold text is applied as a banding-level default (`bold` for header when `showHeader`),
  below explicit formatting.
- Ranges grow automatically with inserted rows (02 S2). Bandings may not overlap: applying to an
  overlapping range replaces/edits the existing banding.

### 14.2 Panel (`sheets.panel.alternatingColors`, `sheets.banding.openPanel`)

- *Apply to range* (`RangeInput`, default = current data region of the selection), *Header* and
  *Footer* checkboxes, *Default styles* grid of 12 presets (derived from theme accents 1–6, light
  and medium variants), *Custom styles* (header / color 1 / color 2 / footer `WonkyColorPicker`
  buttons, plus saved custom styles of this spreadsheet), live preview on the grid (draft),
  [Remove alternating colors] (destructive link), [Done].
- Commands: `sheets.banding.add {range, style}`, `sheets.banding.update {bandingId, range?, style?}`,
  `sheets.banding.remove {bandingId}` (1 step each; the panel's Done issues one of them).

---

## 15. Conditional formatting

The shared condition model and evaluator (condition JSON, `ConditionEvaluator`) live in
`wonky_sheets_core/lib/rules/conditions/` and are reused by data validation and filters
([07-data-tools.md](07-data-tools.md)). Formula-based conditions are compiled relative to each
cell via `FormulaEngine.compileRelative` and registered as virtual dependents so they are
invalidated on recalculation ([05-formula-engine.md](05-formula-engine.md)).

### 15.1 Rule model (`ConditionalFormatRule.ruleJson`)

`ConditionalFormatRule` rows (02 §3.5) hold `sortKey` (priority, first = highest), `rangesJson`
(list of GridRange), `enabled`, `ruleJson`. `ruleJson` schema (extends 02's `{type: boolean |
colorScale, …}` with `dataBar` and `iconSet` — see §19):

```jsonc
// Single color (boolean) rule
{ "v": 1, "type": "boolean",
  "condition": { "type": "numberGreater", "values": [ { "v": "100" } ] },
  "format": { "bold": true, "textColor": "#B31412", "fillColor": "#FCE8E6" },
  "stopIfTrue": true }

// Color scale
{ "v": 1, "type": "colorScale",
  "points": [ { "kind": "min", "color": "#FFFFFF" },
              { "kind": "percentile", "value": "50", "color": "#FFD666" },   // optional midpoint
              { "kind": "max", "color": "#57BB8A" } ] }

// Data bar (P1)
{ "v": 1, "type": "dataBar",
  "min": { "kind": "min" }, "max": { "kind": "max" },
  "color": "#638EC6", "negativeColor": "#E06666", "gradient": true,
  "axis": "auto",            // auto | middle | none
  "direction": "context",    // context | ltr | rtl
  "showValue": true }

// Icon set (P2)
{ "v": 1, "type": "iconSet", "set": "3arrows",
  "thresholds": [ { "op": ">=", "kind": "percent", "value": "67" },
                  { "op": ">=", "kind": "percent", "value": "33" } ],
  "reverse": false, "showValue": true }
```

Condition `values[].v` strings are literals or formulas (leading `=`) in **stored-reference
form** (02 §2, converted with `FormulaCodec`); relative dates use `{ "rel": "pastWeek" }`.

### 15.2 Condition types (single color)

| `condition.type` | UI label | Values | Semantics |
|------------------|----------|--------|-----------|
| `blank` | Is empty | 0 | No content and no overlay value (empty string from a formula counts as empty) |
| `notBlank` | Is not empty | 0 | |
| `textContains` | Text contains | 1 | Case-insensitive substring of the value converted to text (numbers via Automatic rules, not the formatted display) |
| `textNotContains` | Text does not contain | 1 | |
| `textStartsWith` | Text starts with | 1 | case-insensitive |
| `textEndsWith` | Text ends with | 1 | case-insensitive |
| `textEq` | Text is exactly | 1 | case-insensitive full match |
| `dateEq` | Date is | 1 (`rel` or exact) | `rel` ∈ today, tomorrow, yesterday, pastWeek, pastMonth, pastYear; exact = date value or formula |
| `dateBefore` | Date is before | 1 | same `rel` set (pastWeek = before 7 days ago, …) |
| `dateAfter` | Date is after | 1 | |
| `numberGreater` / `numberGreaterEq` | Greater than / or equal to | 1 | numeric values only |
| `numberLess` / `numberLessEq` | Less than / or equal to | 1 | |
| `numberEq` / `numberNotEq` | Is equal to / Is not equal to | 1 | numbers; non-numeric cells: `numberEq` false, `numberNotEq` true |
| `numberBetween` / `numberNotBetween` | Is between / Is not between | 2 | inclusive bounds, order-insensitive |
| `customFormula` | Custom formula is | 1 (formula) | truthy result (§15.3) |

Text conditions operate on the cell value converted to text with Automatic rules (numbers as
`1234.5`, booleans `TRUE`), not on the formatted display. Date conditions require a numeric value
(dates are numbers); relative dates use the spreadsheet time zone and are re-evaluated at
midnight (volatile, like `TODAY()`).

### 15.3 Formulas in conditions (custom formula and `=` values)

- Relative references are relative to the **top-left cell of the first range** of the rule
  (Google behavior): `=$B2>100` applied to `A2:D50` evaluates for row *n* as `=$Bn>100`.
- Evaluation uses `FormulaEngine.compileRelative(stored, anchorCell)` once per rule and evaluates
  per cell with `(rowOffset, colOffset)` (05) — no per-cell parsing.
- Truthiness: `TRUE`, or a non-zero number → match; `FALSE`, 0, text, empty, errors → no match.
  Array results use the top-left element.
- Cross-sheet references are allowed (Google requires `INDIRECT`; we allow direct references).
- **Moves (drag, cut & paste; as built in `mutations/handlers/move.dart`):** the parts of CF and
  DV ranges inside the moved cells move with them (a CF rule moved only in part is split; the
  moved part becomes a rule right after it). Rule formulas behave like the moved cells'
  formulas: references keep their targets, references into the moved cells follow them, and a
  rule whose first range changes is re-anchored so every cell evaluates the same formula as
  before. Copies translate like copied cell formulas (paste: 03 §12.4).

### 15.4 Allowed formats (single color)

`bold`, `italic`, `underline`, `strikethrough`, `textColor`, `fillColor` (Google parity). Number
formats, fonts and borders are not allowed (XLSX import keeps unsupported parts in the rule for
export but ignores them for rendering; 11).

*Formatting style* presets in the editor: Default (fill `#B7E1CD`), and 8 more combinations
(green/yellow/red fill with dark text, bold, strikethrough grey…).

### 15.5 Color scales

- Points: `min`, `max` (required, unless replaced by `number`/`percent`/`percentile`/`formula`
  kinds), optional midpoint (`number`, `percent`, `percentile`, `formula`; default none).
  `percent` = min + p% × (max − min); `percentile` = linear-interpolated percentile of the
  numeric values in the rule's ranges.
- Only numeric cells are colored; color = component-wise sRGB linear interpolation between the
  neighbouring points; values outside [min, max] clamp.
- Contributes `fillColor` only (text color unchanged).
- Presets (editor dropdown, 12): White→Green, Green→White, White→Red, Red→White, Red→White→Green,
  Green→White→Red, Red→Yellow→Green, Green→Yellow→Red, White→Blue, Blue→White, Yellow→Green,
  Theme accent 1 light→dark.
- Statistics (min, max, percentiles) are computed over **all** ranges of the rule
  (`RangeStats`, §15.10).

### 15.6 Data bars (P1)

- Bar length ∝ (value − min)/(max − min) of the cell content box (inset 2 px, height 70 % of the
  cell, vertically centered), gradient from `color` to 10 % alpha when `gradient`.
- Negative values: drawn in `negativeColor` from an axis at the zero position (`axis: auto`
  places the axis proportionally; `middle` at 50 %; `none` draws negatives from the left).
- `direction: context` follows the sheet direction (`Sheet.rightToLeft`); `ltr`/`rtl` force it.
  Bars always grow away from the axis.
- `showValue: false` hides the cell text. Painted in the background layer (03 §2.4 #2).

### 15.7 Icon sets (P2)

Sets: `3arrows`, `3arrowsGray`, `3triangles`, `3trafficLights`, `3signs`, `3symbols`, `3flags`,
`3stars`, `4arrows`, `4ratings`, `4trafficLights`, `5arrows`, `5ratings`, `5quarters`. Thresholds
evaluated top-down (`op` ≥/>; kinds number/percent/percentile/formula). Icons are vector paths
(14 px × zoom) painted left of the text; `reverse` flips the order; `showValue: false` hides text.

### 15.8 Priority, conflicts and stop-if-true

- Rules are evaluated in `sortKey` order (top of the panel list = first).
- For a cell, the effective CF format is built **per attribute**: the first matching boolean rule
  that sets an attribute wins that attribute; later matching rules can still contribute
  attributes not yet set (e.g. rule 1 sets fill, rule 2 sets bold → both apply).
- `stopIfTrue: true` on a matching rule stops evaluation for that cell. **Rules created in Wonky
  default to `stopIfTrue: true`**, which reproduces Google Sheets semantics (only the first
  matching rule applies). Rules imported from XLSX keep Excel's flag (usually `false`), so
  Excel's attribute-combining behavior is preserved. The editor shows it as a "Stop if true"
  checkbox under *Advanced*.
- Color scales contribute `fillColor` if not already set by a higher-priority matching rule; data
  bars and icon sets are independent decorations (one of each kind per cell: the highest-priority
  matching rule of that kind).
- Disabled rules (`enabled = false`) are skipped (toggle in the list, P1).

### 15.9 Editor panel (`sheets.panel.conditionalFormatting`)

**List view**
```
┌ Conditional format rules ─────────────────── ✕ ┐
│ [ Single color | Color scale ]  (shown when editing)
│ ┌───────────────────────────────────────────┐ │
│ │ ⠿ [Aa] Cell is not empty           🗑     │ │ ← drag handle, preview swatch, summary, delete on hover
│ │       A1:D100                              │ │
│ ├───────────────────────────────────────────┤ │
│ │ ⠿ [▬▬] Color scale                 🗑     │ │
│ │       E2:E100                              │ │
│ └───────────────────────────────────────────┘ │
│ + Add another rule                             │
│ Show rules for: [Selected range ▾ | This sheet]│
└────────────────────────────────────────────────┘
```
- Opens filtered to rules intersecting the selection (toggle to all rules of the sheet).
- Click a rule → edit view. Drag ⠿ → reorder (`sheets.cf.reorder {ruleId, beforeRuleId?}`,
  1 step, new `sortKey`). 🗑 → `sheets.cf.deleteRule` (1 step). Hover a rule highlights its ranges
  on the grid. Switch to enable/disable (P1, `sheets.cf.setEnabled`).
- *+ Add another rule* → edit view with a new draft (ranges = selection, condition `notBlank`,
  default style).

**Edit view** (`ShadTabs`: *Single color* / *Color scale* / *Data bar* (P1) / *Icon set* (P2)):
- *Apply to range*: `RangeInput` (multiple ranges allowed).
- Single color: *Format cells if…* `ShadSelect` grouped (Empty / Text / Date / Number / Custom);
  value input(s) as needed — date conditions show a second select (today… exact date) and a
  `ShadDatePicker` for exact; values starting with `=` use the `FormulaEditor` (04 §13) with
  point-to-reference; *Formatting style*: preset dropdown + toggles B I U S + text color + fill
  color; `RulePreviewSwatch` ("123" rendered with the format). *Advanced* accordion: Stop if
  true.
- Color scale: preview gradient bar, preset dropdown, rows *Minpoint / Midpoint / Maxpoint*:
  kind select (Min value / Max value / Number / Percent / Percentile / None for midpoint), value
  input (or formula), color button.
- Data bar: color, negative color, gradient toggle, min/max kind, axis, show value.
- Validation errors inline (empty value, invalid formula — parse message, invalid range).
- [Cancel] discards the draft; [Done] commits: `sheets.cf.addRule {ranges, rule, beforeRuleId?}`
  or `sheets.cf.updateRule {ruleId, ranges?, rule?}` (1 step).
- While editing, the grid shows the draft's effect (preview overlay in `CfEvaluator` with the
  draft rule inserted at its priority) without persisting.

### 15.10 Evaluation engine and performance (`CfEvaluator`)

- **Visible-first**: rules are evaluated only for cells being painted (visible window + overscan),
  then cached in `CfResultCache` keyed `(ruleId, rowId, colId)` → `{match | color | barFraction |
  icon}`; the resolver merges cached per-rule results per §15.8.
- **Rule index**: `RuleIndex` interval tree (02 §6) maps a cell to candidate rules in O(log n + k).
- **Invalidation**:
  - Rule added/changed/removed/reordered → drop that rule's cache entries and repaint its ranges.
  - Cell value changes inside a rule's ranges → drop entries for those cells; for color scales,
    data bars, percent/percentile points and `stats`-dependent rules → also invalidate
    `RangeStats` for the rule (recomputed lazily).
  - Custom-formula and `=` values: the formula engine registers each compiled rule as a **virtual
    dependent** over the bounding rectangle of its referenced ranges expanded by the rule's apply
    range size (05 `VirtualDependent` API); recalculation notifies `CfEvaluator` with the
    affected rule ids → their caches drop and visible cells repaint.
  - Volatile conditions (relative dates, `TODAY()`/`NOW()`/`RAND()` in formulas) are invalidated
    on the engine's volatile tick (and at midnight).
- **RangeStats**: min/max/count/sorted sample for percentiles per rule; computed in a background
  isolate (web: chunked microtasks) when the ranges contain > 100k cells; until ready, cells
  render without the scale (no flicker afterwards: tile invalidation once).
- **Budgets**: ≤ 2 ms per frame for 2,000 visible cells with 20 active rules (cache-warm); cold
  evaluation of a 1,000-cell viewport with 10 custom-formula rules ≤ 15 ms; 500 rules per sheet
  max (01 §3).
- Server/headless (exports, MCP `formatted` reads) uses the same `CfEvaluator` in core without
  caches beyond the request.

### 15.11 Interactions

- Rules are range-based, so **sort** and **filter** don't move rules; formats follow positions
  (Google behavior). Insert/delete rows inside ranges grows/shrinks them (03 §13.1–13.2 boundary
  repair).
- Copy/paste: normal paste and *Paste special › Conditional formatting only* copy intersecting
  rules translated to the target (03 §12.4); same-spreadsheet pastes with an identical rule
  (same `ruleJson`, adjacent range) **merge ranges** into the existing rule instead of creating a
  duplicate.
- Fill handle does not extend CF ranges (03 §10.2).
- Deleting all ranges of a rule deletes the rule.

---

## 16. Command catalogue

All mutating commands accept an optional `ranges` argument (A1 list) for MCP; default = current
selection. Undo: 1 = one step.

| Command id | Args | Shortcut (Win/Linux · macOS) | Undo | MCP notes |
|------------|------|------------------------------|------|-----------|
| `sheets.format.bold` / `italic` / `underline` | `value?` (omit = toggle §1.4) | Ctrl+B/I/U · ⌘B/I/U | 1 | Headless: `sheets.format_range` |
| `sheets.format.strikethrough` | `value?` | Alt+Shift+5 · ⇧⌘X | 1 | |
| `sheets.format.fontFamily` | `family` | — | 1 | |
| `sheets.format.fontSize` | `size` | — | 1 | |
| `sheets.format.increaseFontSize` / `decreaseFontSize` | — | Ctrl+Shift+. / , · ⇧⌘. / , | 1 | |
| `sheets.format.textColor` / `fillColor` | `color \| null` | — | 1 | `#RRGGBB` or `theme:accentN` |
| `sheets.format.hAlign` | `align: left\|center\|right\|general` | Ctrl+Shift+L/E/R · ⇧⌘L/E/R | 1 | |
| `sheets.format.vAlign` | `align: top\|middle\|bottom` | — | 1 | |
| `sheets.format.wrap` | `strategy` | — | 1 | |
| `sheets.format.rotation` | `angle` (−90…90, 255) | — | 1 | |
| `sheets.format.numberFormat` | `preset?` \| `pattern?` | Ctrl+Shift+1 number, 2 time, 3 date, 4 currency, 5 percent, 6 scientific · ⇧⌘1…6 | 1 | Validates pattern; error `invalid_number_format` |
| `sheets.format.increaseDecimals` / `decreaseDecimals` | — | — | 1 | |
| `sheets.format.openCustomNumberFormat` / `openCustomDateTime` / `openCustomCurrency` | — | — | — | dialogs (04 §11.2–11.4) |
| `sheets.format.borders` | `preset, style?, color?` | Alt+Shift+1/2/3/4/6/7 · ⌥⇧1/2/3/4/6/7 | 1 | |
| `sheets.format.merge` | `mode` | — | 1 | `force: true` skips the data-loss dialog (MCP) |
| `sheets.format.unmerge` | — | — | 1 | |
| `sheets.format.clear` | — | Ctrl+\\ · ⌘\\ | 1 | |
| `sheets.format.paintFormat` | `sticky?` | — | — | arms |
| `sheets.format.applyPaintFormat` | `source, target` | — | 1 | MCP: prefer `pasteSpecial {mode: format}` |
| `sheets.format.convertToTable` (P2) | — | Ctrl+Alt+T · ⌥⌘T | 1 | 07 |
| `sheets.theme.openPanel` | — | — | — | |
| `sheets.theme.set` | `themeJson \| presetName` | — | 1 | |
| `sheets.banding.openPanel` | — | — | — | |
| `sheets.banding.add` / `update` / `remove` | §14.2 | — | 1 | |
| `sheets.cf.openPanel` | `range?` | — | — | |
| `sheets.cf.addRule` | `ranges, rule, beforeRuleId?` | — | 1 | `rule` uses A1 formulas in MCP (converted to stored form) |
| `sheets.cf.updateRule` | `ruleId, ranges?, rule?` | — | 1 | |
| `sheets.cf.deleteRule` | `ruleId` | — | 1 | |
| `sheets.cf.reorder` | `ruleId, beforeRuleId?` | — | 1 | |
| `sheets.cf.setEnabled` (P1) | `ruleId, enabled` | — | 1 | |
| `sheets.insert.link` / `sheets.link.remove` | `url, text?` | Ctrl+K · ⌘K | 1 | |

MCP: the UI bridge can call every command via `ui.invoke_command`; headless tools (12) expose
`sheets.format_range {range, format: {…§1.1 keys}}`, `sheets.set_number_format`,
`sheets.set_borders`, `sheets.merge_cells`, `sheets.list_conditional_formats`,
`sheets.add_conditional_format`, `sheets.update_conditional_format`,
`sheets.delete_conditional_format`, `sheets.set_theme`, `sheets.set_banding` — implemented with
the same core classes (the shared `SheetsMutationPlanner`, committed on the server as a
server change, 12 §2.4).

## 17. Acceptance criteria

- AC-F1: toggle semantics (§1.4).
- AC-F2: Formatting a whole column B bold writes one `SheetColumn.formatJson` change (plus nulling
  explicit cells), not 1M cell rows; cell B5 in a row with row-level `bold:false` becomes bold.
- AC-F3: All number-format vectors in §5.13 pass in core unit tests; the same patterns render the
  same text in the grid (golden) and in CSV export.
- AC-F4: Typing `$1,200.5` into an Automatic cell stores `n:1200.5` and `numberFormat` `"$"#,##0.00`;
  typing `5%` into a `0.00` cell stores 0.05 and keeps `0.00`.
- AC-F5: Increase decimals on a cell showing `1235` (Automatic, value 1234.5) results in
  `1,234.5`.
- AC-F6: Changing the spreadsheet locale from en_US to de_DE changes `preset:currency` cells from
  `$1,000.12` to `1.000,12 €` without writing any cell.
- AC-F7: Border presets map to edges per §8.3, including facing-edge clearing; conflicts render per
  §8.4 (golden tests).
- AC-F8: Merge all on B2:C3 with values in B2 and C3 shows the warning; OK keeps B2's value; undo
  restores C3 and the unmerged state.
- AC-F9: A CF rule `=$C2>100` on `A2:F100` highlights entire rows where column C > 100; editing C7
  updates row 7's highlight within one frame after recalculation.
- AC-F10: Two matching rules created in Wonky (fill red; bold): only red applies (default
  `stopIfTrue: true`, Google semantics). With `stopIfTrue` unchecked on the first (or rules
  imported from XLSX without the flag), both apply.
- AC-F11: Color scale min→max white→green colors the max value exactly `#57BB8A` and the min
  `#FFFFFF`.
- AC-F12: Theme change from Standard to Ocean recolors all cells using `theme:accent1` and the
  banding derived from it, in one undo step.
- AC-F13: Paint format double-click stays armed across three applications (three undo steps) and
  disarms on Esc.
- AC-F14: Clear formatting keeps links, notes, DV, CF, merges; removes number formats and borders.

## 18. Testing

- Core unit tests: parser (valid/invalid grammar), formatter vectors (§5.13) for en_US, de_DE,
  fr_FR, ja_JP, en_IN, de_CH; `FormatInference`; `DecimalsAdjuster`; `BorderPresetPlanner`;
  `RichText.normalize`; `CfEvaluator` (each condition type, color scale math, priority/stop rules,
  relative formula translation).
- Property tests: `format(parse(p))` never throws for random patterns from the grammar; formatting
  is deterministic across platforms (web vs VM) for 10k random values × 100 patterns (golden
  file).
- Widget/golden tests: toolbar states, border picker, CF panel (list & edit, light/dark), theme
  panel, banding panel.
- Command tests: execute → undo → redo for every command in §16 (suite 08 §4).

## 19. Additions to 02-data-model (proposed)

| Addition | Detail |
|----------|--------|
| `ConditionalFormatRule.ruleJson.type` adds `dataBar` (P1) and `iconSet` (P2); boolean rules add optional `stopIfTrue` | Schema §15.1 (versioned with `"v":1`) |
| `numberFormat` preset ids `preset:automatic`, `preset:accounting`, `preset:currency`, `preset:currencyRounded`, `preset:date`, `preset:time`, `preset:dateTime` | Locale-dependent presets §5.1 (02 already allows "preset id") |
| Border color value `auto` | §8.2 |
| `Banding.styleJson` schema | §14.1 |
| `Spreadsheet.themeJson` schema (`v`, `name`, `fonts.text`, `colors.*`) and rule "themeJson wins over `defaultFontFamily`" | §13.1 |

## 20. Implementation notes (Phase 3, app)

- **Settings › Sheets** (04 §11.24) is the Sheets app's section (`WonkyAppConfig.sheetsSettings`
  → `SheetsSettingsSection`); every key goes through `SheetsUserDefaults`
  (`features/formatting/sheets_user_defaults.dart`). New spreadsheets created on the client get
  the default locale, time zone, theme font (`CreateSpreadsheet {fontFamily}` writes it into
  `themeJson.fonts.text`) and size; spreadsheets created on the server (`initialize: true`) get
  them through `SheetsCreateDefaults`; template copies keep the template's settings (04 §11.24). Custom fill lists feed `PlanContext.customLists`
  (`WorkbookSessionBase.customLists`); *Reduce grid animations* stops the marching ants; *Show
  editor mode* hides the status-bar mode.
- **Custom formulas** use `FormulaField` (`features/formatting/formula_field.dart`): syntax colors,
  function autocomplete, signature help, parse errors and point mode (selecting on the grid
  inserts the reference while the caret is at an insertion point; the next selection replaces
  it). Used by the CF editor and the filter condition editor. Value errors show under their
  field once the user changed it; "add a format" under the formatting style. *Exact date* has a
  calendar (ISO date).
- **CF caches** (§15.10): recalculations drop only the changed cells' results, rules with range
  statistics over them and formula rules that may read them (cross-sheet formula rules too);
  > 20,000 changed cells drop everything. Rules over > 100k cells get `RangeStats` in the
  background (`CfEvaluator.asyncStats`: values read in chunks between frames, sorted with
  `compute`); until ready they render nothing, later edits keep the old stats until the new ones
  arrive.
- **Column banding** (P2): `BandingStyle.dimension = columns` (*Alternate columns* in the panel);
  the draft's range is outlined while the panel is open.
- **Fonts**: bundled Inter, Roboto, Open Sans, Lato, Source Sans 3, Nunito, Montserrat, Geist,
  EB Garamond, Merriweather, Geist Mono, JetBrains Mono, Roboto Mono (Roboto/Roboto Mono Apache
  2.0, the others OFL; licenses next to the TTFs in `packages/wonky_fonts/fonts/`). Merriweather, Montserrat and
  Nunito are the last static TTFs of `google/fonts` (before those families went variable); Source
  Sans 3 exists there only as a variable font, so `WonkySansThree-*.ttf` are static instances of it
  (wght 400/700, upright and italic, hinting and variation tables removed), renamed because
  "Source" is a Reserved Font Name (`OFL-WonkySansThree.txt`). Names matching a bundled family
  case-insensitively render with it (*Source Sans Pro* with Source Sans 3); other geometric/rounded
  sans names (Poppins, Raleway …) render with Lato, serif with EB Garamond, mono (Courier Prime,
  Courier New …) with JetBrains Mono — JetBrains Mono is the suite's monospace face, so the *Mono*
  and *Retro* presets use it and Courier Prime is not offered. The font menu shows "Aa" in each
  face. PDF (client and server, `BundledPdfFonts`): Roboto, Lato, Source Sans 3, Nunito,
  Montserrat, Merriweather and Roboto Mono embed as themselves, other sans as Open Sans, serif as
  EB Garamond, mono as JetBrains Mono (`web/fonts/` holds the same files).
- **Rich text** (§11): Mod+K on a text selection in the cell editor links the selection (link run);
  formatting that can't be a run (`sheets.format.*` other than B/I/U/S, colors, font, size) is
  disabled while text is selected ("Not available while text in the cell is selected"); the
  formula bar shows the runs (styles without sizes/families).
- Custom currency examples are colored by `[Red]`-style sections; currency names come from the
  `currencyName` ICU select (translatable).
- Spreadsheet display language (P2, built): function names and booleans in de/fr/es/sv
  (04 §11.1 *As built*); booleans display translated. Error names stay English.

