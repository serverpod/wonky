# Slides 07 · Code Blocks: Highlighting, Line Steps and Type-in

Code is a first-class element in Wonky Slides. This spec defines:
- the shared **`wonky_code`** package (tokenizer, languages, syntax palettes, code layout and
  diffs) extracted from Wonky Write, plus its Flutter companion **`wonky_code_flutter`**, used by
  Write code blocks and Slides code elements;
- the **code element** (`SlideElement.kind = code`): rendering, auto-fit, line numbers, wrap,
  title tab, editing in place, copy button;
- **line highlighting steps** (reveal.js style `"1-3 | 5 | 7-9"`) with dim/blur styles and
  per-step callouts;
- **code states** and the **type-in** animation (code changes typed as if on a keyboard) and
  the alternative **morph** mode (tokens move, Code Hike / Keynote Magic Move style), within a
  slide and across slides;
- the **state strip** UI, presenter controls, exports, MCP/AI hooks (incl. "make a walkthrough
  from a git diff"), commands, undo and acceptance criteria.

Read first: [02-data-model.md](02-data-model.md) (`SlideElement`, `CodeState`),
[03-editor-canvas-and-objects.md](03-editor-canvas-and-objects.md) (selection, soft lock of
text editing, inspector), [06-animations-and-transitions.md](06-animations-and-transitions.md)
(builds, timeline, Magic Move), Write [04-editor.md](../wonky_write/04-editor.md) §15 (code
blocks, languages, highlighting), Write [06-themes.md](../wonky_write/06-themes.md) §2.5
(syntax palette), suite [01-architecture.md](../01-architecture.md) §2.1 (dependency rules).

Priorities: code element, highlighting and line steps are **P0 (M10)**; type-in and morph are
**P0 (M10)**; items marked P1/P2 as noted. Units: slide units (su), milliseconds.

---

## 1. Principles

1. **One tokenizer everywhere.** The editor canvas, present mode, thumbnails, PDF (client and
   server), MCP previews and Write all color code with the same pure-Dart tokenizer and the
   same palettes, so a token is the same color on screen and in the PDF.
2. **Monospace grid.** Code layout is a grid of columns × lines computed in pure Dart from the
   mono font's metrics. Type-in, morph, highlighting, callout anchors and PDF output all use the
   same grid, which makes them deterministic and cheap.
3. **Content is states.** A code element is an ordered list of code states (≥ 1). Everything
   animated (typing, morphing, highlight steps) is derived from the states and their settings.
4. **Deterministic animation.** Typing scripts are pure functions of (from text, to text,
   settings, seed); the timeline can seek to any moment and exports show end states.

---

## 2. Shared packages: `wonky_code` and `wonky_code_flutter`

### 2.1 What moves

| From (today) | To | Notes |
|--------------|----|-------|
| `third_party/syntax_highlight/lib/src/span_parser.dart` (TextMate engine, BSD-3, Serverpod-owned) + patches SH-2…SH-5 | `packages/wonky_code/lib/src/textmate/` | Pure Dart (only `collection`, `string_scanner`). Provenance and patch history in `packages/wonky_code/THIRD_PARTY.md`; `// WONKY PATCH` markers kept. |
| `third_party/syntax_highlight/grammars/*.json` (15 grammars, ~100 KB) + `tool/gen_grammars.py` | `packages/wonky_code/lib/src/grammars/` as generated Dart `const String`s (`tool/embed_grammars.dart`) | Embedding (instead of Flutter assets) makes the tokenizer work on the server and in isolates; lazy parsing per language keeps start-up cost unchanged. |
| `third_party/syntax_highlight/lib/src/highlighter.dart` (`Highlighter.parseScopes`, SH-4) | `wonky_code` `TextMateTokenizer` | The Flutter `TextSpan`/bracket styling parts are dropped (unused). |
| `wonky_write/lib/features/editor/styles/code_highlighter.dart` (`tokenForScopes` rules) | `wonky_code` `ScopeClassifier` | Scope → token class rules unchanged. |
| `wonky_write/lib/features/editor/model/code_languages.dart` (`aliases`, `grammars`, `displayNames`) | `wonky_code` `CodeLanguages` | Extended by §2.4. |
| `wonky_write_core/lib/src/theme/model/syntax_token.dart` (`SyntaxToken`) | `wonky_code` `SyntaxToken` | `wonky_write_core` re-exports it (no API break). |
| `wonky_write_core/lib/src/theme/builtins/common.dart` syntax palettes (`githubDarkSyntaxJson`, `monochromeSyntaxJson`, …) and the palette part of the theme parser | `wonky_code` `SyntaxPalette`, `BuiltInPalettes` | Write themes keep embedding palettes by value (Write 06 §2.5 format unchanged). |
| `wonky_write_core/lib/src/highlight/syntax_highlighter.dart` (highlight.js wrapper used by Write exports) | `wonky_code` `HighlightJsTokenizer` | Fallback tokenizer for languages without a TextMate grammar (§2.2). |
| — (new) | `wonky_code` `CodeLayout`, `MonoFontMetrics`, `SequenceDiff` users, `CodeEditScript`, `TypingScript`, `TokenMorphPlan`, `UnifiedDiff`, `HighlightSteps` | §3–§5. |
| — (new) | `packages/wonky_code_flutter`: `CodeView` (painter widget), `CodeTextStyler`, `CodeEditorField` (re_editor integration), `CodePaletteResolver` | §3, §3.5. |

`wonky_core/lib/src/diff/line_diff.dart` gains a public generic **`SequenceDiff.diff<T>(List<T>
a, List<T> b, {bool Function(T, T)? equals})`** (the existing private Myers implementation,
generalized); `LineDiff` becomes a thin wrapper. `wonky_code` and the Magic Move text matcher
(06 §9.5) use it.

After Write is migrated (§2.7), `third_party/syntax_highlight` is deleted and the root
`pubspec_overrides.yaml` entry removed; the provenance (source archive, hash, license) and the
patch history SH-1…SH-5 live in `packages/wonky_code/THIRD_PARTY.md` (done in D-2).

### 2.2 Tokenizer decision

Today Write's editor uses TextMate grammars (`syntax_highlight`, Flutter-only because grammars
load through `rootBundle`) while Write's exports use highlight.js (`package:highlight`, pure
Dart). The two produce different colors for the same code. **Decision**: `wonky_code` exposes
one `CodeTokenizer` facade:

```dart
abstract interface class CodeTokenizer {
  /// Tokens of [code] in [language] (normalized id): sorted, disjoint, merged spans with a
  /// token class; text not covered is plain (`codeText` color).
  List<CodeToken> tokenize(String code, String language);

  /// Incremental, line-based: tokens of line [i] given the TextMate state after line i-1;
  /// returns the state after the line (used for typing animations and editing, §5.4).
  LineTokens tokenizeLine(String line, String language, LineState? before);
}

final class CodeToken { final int start, end; final SyntaxToken token; }
```

`DefaultCodeTokenizer` routes **TextMate first** (the 15 grammars Write ships, best quality,
patched) and **highlight.js second** for every other language in §2.4 (broad coverage: bash,
C, C++, C#, diff, Dockerfile, GraphQL, Markdown, PHP, Ruby, Scala, …), mapping highlight.js
classes to the same `SyntaxToken`s. Unknown languages render plain.

**Decided (v2 review, Q25) — Write exports.** Write's exports switch to the TextMate route too
(identical colors editor ↔ export) in **M10**, with a golden diff review of the Write export
corpus; the change is limited to token colors. Until then they keep highlight.js (Write 04
§15.5).

**Done (SL-35).** Write's exporters and its editor use `DefaultCodeTokenizer` (the exporters
through `SyntaxHighlighter.instance`, cached, languages normalized). The diff review is the test
`wonky_write_core/test/export/code_tokenizer_switch_test.dart`: highlight.js vs the shared
tokenizer over a code corpus in every exporter, equal once token styling is removed. It found
an engine bug fixed as patch **SH-7** (captures were located by the first occurrence of their
text, e.g. `function f`), and PDF code wrapping that depended on token boundaries (now at
spaces). Since TextMate tokenizes more finely than highlight.js, exports now also color
operators, punctuation, function names and calls (as the editor already did).

**Decided (v2 review, Q26) — copy vs. upstream split.** The TextMate engine is **copied** into
`wonky_code` now (small, already patched, we own the patches) during the M8 extraction; an
upstream split of `syntax_highlight` into a pure-Dart core + Flutter wrapper is proposed later,
and we switch back if it lands.

### 2.3 API (pure Dart, `package:wonky_code/wonky_code.dart`)

```dart
abstract final class CodeLanguages {
  static String normalize(String input);               // aliases, lowercase, '' = plain
  static String displayName(String language);          // "TypeScript"; unknown → input
  static bool isHighlighted(String language);          // TextMate or highlight.js support
  static List<String> get pickerLanguages;              // §2.4 order
  static String? fromFileName(String name);             // "main.dart" → dart (extension table)
  static String? detect(String code);                   // P1: highlight.js relevance auto-detect
}

final class SyntaxPalette {                             // Write 06 §2.5 JSON format
  final String id;                                      // "wonky-light", "github-dark", …
  final String name;
  final Brightness brightness;                          // light | dark (pure-Dart enum)
  final int background, text, lineNumber, lineNumberActive, selection, caret,
            highlightBar, dimOverlay, titleTabBackground, titleTabText, border;
  final Map<SyntaxToken, TokenStyle> tokens;            // color (ARGB), bold, italic
  factory SyntaxPalette.fromJson(Map<String, Object?> json);
  Map<String, Object?> toJson();
}

final class MonoFontMetrics {                           // from the TTF (hhea/hmtx), per family
  final String family;                                  // "JetBrains Mono"
  final double advanceEm;                               // 0.6 for JetBrains Mono
  final double ascentEm, descentEm, lineGapEm;
}

final class CodeLayout {                                // §3.3
  static CodeLayout layout(String code, CodeLayoutOptions o);   // grid: lines, columns, wraps
  int get lineCount; int get maxColumns;
  GridPos posOf(int offset); int offsetAt(GridPos p);
  Rect rectOfRange(int start, int end);                 // su, for selection/highlights/callouts
}
```

Plus `HighlightSteps.parse` (§4.1), `CodeEditScript.compute` (§5.2), `TypingScript.build`
(§5.3), `TokenMorphPlan.build` (§5.6), `UnifiedDiff.parse` (§10.2).

`wonky_code_flutter` (`package:wonky_code_flutter/wonky_code_flutter.dart`):
- `CodeView` — a `LeafRenderObjectWidget` painting code on the grid with tokens, line numbers,
  highlight styles, caret/selection, title tab and callouts from a `CodeViewState` (06 §9.2);
  used by Slides and (P2) by Write's read-only renderers and the Drive file preview of code
  files.
- `CodeTextStyler` — `SyntaxPalette` + font → `TextStyle`s per token (used by Write's
  `CodeHighlightStylePhase` instead of its private styler).
- `CodeEditorField` — editing wrapper (§3.5).

**Status (M8, Drive 05 D-2 — extraction done).** Built and differing from the sketch above:
- `CodeTokenizer` has `supports(language)` + `tokenize(code, language)`; `tokenizeLine` /
  `LineTokens` / `LineState` come with type-in and editing (M10, §5.4) — the copied engine parses
  whole texts and has no line-state API yet.
- `wonky_code` also exposes `TextMateTokenizer`, `HighlightJsTokenizer` (moved from
  `wonky_write_core`, which keeps `SyntaxHighlighter`/`SyntaxSpan` as typedefs),
  `DefaultCodeTokenizer`, `ScopeClassifier`, `CodeToken`, `SyntaxToken`, `SyntaxPalette` (+
  `TokenStyle`, `PaletteBrightness`, `parseColor`/`formatColor`/`contrastRatio`) and
  `BuiltInPalettes` (§2.5 table; One Dark, Dracula and Solarized accents are lightened/darkened
  where the originals miss 4.5:1). `CodeLanguages` additionally has `grammars` (language → TextMate
  grammar), `grammarFor`, `highlightJsLanguages`, `displayNames`, `aliases`, `extensions`;
  `detect` (P1) is not built. `wonky_code` does not depend on `wonky_core` yet (nothing needed).
- `wonky_code_flutter` (depends only on `flutter` + `wonky_code` so far) has `CodeTextStyler`
  and a **read-only `CodeView` widget** for Drive previews: virtualized lines (fixed line extent,
  fixed line-number gutter, horizontal scroll) or soft wrap, highlighted lines, `SelectionArea`
  selection, deferred highlighting for long code (sync up to 50k UTF-16 units, at most the first
  500k highlighted), default palette from the ambient `Theme` brightness. The grid-exact painter
  driven by `CodeViewState` (title tab, callouts, dimming, caret; §3.3–§3.4) arrives with
  `CodeLayout`/`MonoFontMetrics` in M10, as is `CodeEditorField` and `CodePaletteResolver`.
- Write's editor uses `TextMateTokenizer` (not yet the facade) and its own class-keyed theme
  styling (Write 04 §15.5).

**Status (M10, SL-26 — code core built).** Differences from the sketches in §2.3–§5:
- `MonoFontMetrics {family, advanceEm, ascentEm, descentEm, lineGapEm}`: `forFamily` returns the
  values measured from the bundled files (JetBrains Mono 0.6 / 1.02 / 0.3 em, Roboto Mono), 0.6
  em for other monospace families; `fromTtf` reads `head`/`hhea`/`hmtx` (dominant advance).
- `CodeLayout.layout(code, CodeLayoutOptions {fontSize, lineHeight, tabSize, wrapColumns,
  metrics})` has visual rows (`CodeRow`, soft wrap after the last whitespace, else inside the
  word) besides lines (`CodeLayoutLine`); `GridPos` is `(row, column)` of visual rows;
  rectangles are `CodeRect` (pure Dart) relative to the code area: `rectsOfRange` (one per row),
  `rectOfRange`, `rectOfLines`. Grapheme clusters come from `CodeColumns` (a dependency-free
  segmentation covering CRLF, combining marks, variation selectors, emoji modifiers, ZWJ
  sequences, regional-indicator pairs).
- Box geometry and auto size are in `wonky_code` too (`CodeBoxOptions`, `CodeBoxGeometry`,
  `CodeChrome`, `CodeAutoFit.fit`): the window bar is always drawn, a tab or caption only with a
  title; with `fitAcrossStates` the title area is kept for every state so code never jumps.
- `HighlightSteps.parse(input, {lineCount, startLine})` → `HighlightStepsResult {steps,
  issues, normalized}` (`*` writes "show all" steps); `@` displayed numbers and `line:col-col`
  are parsed; `validate` flags steps past the end.
- `CodeEditScript.compute`: pairing similarity is `1 − Levenshtein / max(len)` over graphemes
  (bounded, with cheap length/multiset pre-checks; a 24-line look-ahead per old line);
  inserted whole lines are typed like an editor user — Enter at the end of the previous line,
  then the lines (so auto-indent applies); `stats` gives the state strip's +/−.
- `TypingScript` events are `caretShow`, `caretTo`, `select`, `delete`, `insert`, `paste`,
  `end` (no `scroll`: the composer derives scroll-follow from the caret); `durationMs` includes
  the 600 ms caret linger; the seed is `typingSeed(elementId, targetStateId)` (FNV-1a + 32-bit
  Mulberry32, exact on VM and web, like the timeline, 06 §9.3); `stateAt(ms)` →
  `TypingFrame {text, caret, caretFrom, caretGlide, caretOpacity, selection, fades}`.
- `TokenMorphPlan.build` anchors on the line diff (equal lines match their lexemes, changed
  hunks run `SequenceDiff` on lexeme texts, ≤ 800 lexemes per side), then matches identical
  leftovers by nearest distance; `frameAt(ms)` → `MorphGlyph`s (su positions, opacity, color
  mix for `oklabLerp`, font size).
- `CachedCodeTokenizer` (LRU per language + text) serves repeated tokenizations (§14 cache);
  `tokenizeLine`/`LineState` (§5.4) are not built — type-in frames re-tokenize the whole text.
- TextMate engine patch SH-6 (`THIRD_PARTY.md`): next-match search and an own scanner, spans
  unchanged; 1,000 lines of Dart ≈ 17–20 ms on the VM (was ≈ 56; the 15 ms target is open).
- Slides core (`package:wonky_slides_core/code.dart`): `CodeElementData` (§3.1),
  `CodeAnnotations` (§4.4), `CodeStateModel`/`CodeElementModel` (modes, cached typing scripts
  and morph plans, derived durations), `CodeSceneComposer` (static scenes with step
  transitions, focus scroll/zoom, callout anchors with `auto` side; type-in, morph and
  instant frames) and `CodeElementLayout` (the scene builder's `CodeSceneSource`; `auto` picks
  the palette by the element's box background, else the slide's effective background color).

**Status (M10, SL-31 — code element UI built, feature `codeBlocks` on).** Differences from
§3–§11:
- **Rendering**: the stage's `CodeScenePainter` (`wonky_slides/lib/features/elements/code/`)
  draws every `CodeScene` field (the `CodeView`-driven painter of §2.3 lives in the app because
  `CodeScene` is a Slides core type). Callouts use the deck theme's `accent1` and body font
  (`CodeCalloutPlacement.color/textColor/fontFamily`, from `CodeRenderStyle`); glyphs of wide
  graphemes (CJK) are not yet centered in their cells. The PDF painter draws static code (box,
  border, chrome, numbers, grid runs, bars, line opacity; blur as opacity); callouts, the caret
  and animation frames in PDF are SL-33's.
- **Editing** (§3.5): `CodeEditorField` (`wonky_code_flutter`, re_editor) over the code area;
  the stage keeps drawing box and chrome, the field draws text and numbers; a baseline
  correction (`baselineInRow`) aligns re_editor's proportional leading with the grid. Tokens
  come from the shared cached tokenizer (whole text per edit up to 20,000 characters; longer
  texts keep their tokens shifted past the edit and are tokenized again after 150 ms without
  typing, CD-2; no `tokenizeLine`). `CodeView` memoizes its line spans, widest line and font
  metrics per input (CD-1). The field
  writes after 300 ms idle and on exit (`CodeEditSession`, coalesced "Typing" steps per state);
  undo/redo flush pending typing first. Auto size re-fits on each write, not per keystroke.
  Inside the field `Mod+Z` is re_editor's own undo (its result is written like typing). The soft
  lock uses the element's text-lock target (presence "editing"). The language and palette
  chips inside the box are not built: the toolbar's language button shows the current language,
  palettes are in the inspector and Format › Code › Colors. *Show changes* marks added /
  changed lines and removals in the field's gutter.
- **Insert** (§3.6): *Insert › Code block › Dart/JavaScript/Python/Plain text* or *All
  languages…* (`{pick: true}` opens the language dialog); the toolbar button inserts with the
  last used (else the default) language and starts editing. New blocks take the Code settings:
  *Default code language*, *Largest code font size* (`fontSizeMax`) and *Typing speed*
  (`typing.cps` 16 / 28 / 50). Recently used languages are per session (not shared with
  Write). *Type-in sound* (P2) is not offered. The paste chip and ```` ``` ```` in an empty
  text box are not built; *Convert to code block* (`slides.code.convertFromText`) is in the
  text box context menu. File drop (P1) is not built.
- **Inspector** (§7): language, colors (*Auto (Wonky Dark)*), font size (*Auto* shows the fitted
  size, min–max), line numbers + start, wrap, ligatures, frame + title, language badge, copy
  button; the state strip with live mini previews (the arrival mode icon between chips), `+`,
  duplicate, delete, move earlier/later, ▶ (type-in of state 1 / the change into the selected
  state, played on the canvas with the composer's frames), *Edit code*, the state name and *Show
  changes*; the arrival (mode, speed, rhythm, deletions, *More…* = all §5.3 settings, the
  derived duration "≈ 4.2 s (typed)"); line steps (the §4.1 field, normalized on commit, issues
  inline, the parsed steps with their callouts; clicking a step previews it on the canvas,
  `SceneContext.codeSteps`); highlight style, focus, *Same size in all states*. *Build all
  steps* comes with the Animate UI (SL-30); *Pick lines…* mode is not built
  (`slides.code.addStepFromLines` is).
- **Commands** (§11): all but `pickLines` and `walkthroughFromDiff`; added
  `slides.code.setStateLabel`, `slides.code.previewStep {step}` and `slides.code.preview
  {index}`; `updateOptions` takes `{patch}` or `{toggle}` (no arguments = *Line numbers*);
  `setStateTransition {more: true}` opens the typing settings; `setHighlightSteps
  {normalize}` stores the normalized form.
- **Presenting** (§8): build durations come from the model (12 §5.5); drawing builds while
  presenting and the copy button in present/view mode are the motion player's (SL-29), which
  recomposes code nodes per frame with `CodeFrames.applyFrame`.

### 2.4 Languages

Picker order: *Plain text*, recently used (max 5, per user, shared with Write), then:

| Language id | Display | Tokenizer | Aliases (normalized on input) | File extensions |
|-------------|---------|-----------|-------------------------------|-----------------|
| `css` | CSS | TextMate | — | `.css` |
| `dart` | Dart | TextMate | — | `.dart` |
| `go` | Go | TextMate | `golang` | `.go` |
| `html` | HTML | TextMate | `htm` | `.html`, `.htm` |
| `java` | Java | TextMate | — | `.java` |
| `javascript` | JavaScript | TextMate | `js`, `jsx`, `mjs`, `cjs` | `.js`, `.jsx`, `.mjs`, `.cjs` |
| `json` | JSON | TextMate | `jsonc` | `.json` |
| `kotlin` | Kotlin | TextMate | `kt`, `kts` | `.kt`, `.kts` |
| `python` | Python | TextMate | `py`, `py3`, `python3` | `.py` |
| `rust` | Rust | TextMate | `rs` | `.rs` |
| `serverpod` | Serverpod models | TextMate | `spy`, `serverpod_protocol` | `.spy.yaml` |
| `sql` | SQL | TextMate | — | `.sql` |
| `swift` | Swift | TextMate | — | `.swift` |
| `typescript` | TypeScript | TextMate | `ts`, `tsx` | `.ts`, `.tsx` |
| `yaml` | YAML | TextMate | `yml` | `.yaml`, `.yml` |
| `bash` | Bash | highlight.js | `sh`, `shell`, `zsh` | `.sh`, `.bash`, `.zsh` |
| `c` | C | highlight.js | `h` | `.c`, `.h` |
| `cpp` | C++ | highlight.js | `c++`, `cc`, `hpp` | `.cpp`, `.cc`, `.hpp` |
| `csharp` | C# | highlight.js | `c#`, `cs` | `.cs` |
| `diff` | Diff | highlight.js | `patch` | `.diff`, `.patch` |
| `dockerfile` | Dockerfile | highlight.js | `docker` | `Dockerfile` |
| `graphql` | GraphQL | highlight.js | `gql` | `.graphql` |
| `markdown` | Markdown | highlight.js | `md` | `.md` |
| `php` | PHP | highlight.js | — | `.php` |
| `ruby` | Ruby | highlight.js | `rb` | `.rb` |
| `scala` | Scala | highlight.js | — | `.scala` |
| `xml` | XML | highlight.js | `svg`, `plist` | `.xml`, `.svg` |
| `lua`, `perl`, `r`, `haskell`, `elixir`, `erlang`, `objectivec`, `powershell`, `protobuf`, `ini`, `makefile`, `nginx`, `scss`, `less`, `groovy`, `gradle`, `matlab`, `clojure`, `http` | (display names) | highlight.js | as in `package:highlight` | — |

Other typed languages are kept verbatim (lowercased), labelled with their display name when
known, and rendered plain. Write's language picker shows the same list (Write 04 §15.1 is
updated by reference).

### 2.5 Syntax palettes (themes)

Built-in palettes (`BuiltInPalettes`), each fully specified for all `SyntaxToken`s and chrome
colors and contrast-checked (every token ≥ 4.5:1 against its background; test):

| Id | Name | Brightness | Origin |
|----|------|------------|--------|
| `wonky-light` | Wonky Light | light | Write's default light syntax palette |
| `wonky-dark` | Wonky Dark | dark | Write's default dark palette (GitHub-dark-like) |
| `github-light` / `github-dark` | GitHub Light / Dark | both | `githubDarkSyntaxJson` + light counterpart |
| `one-dark` | One Dark | dark | Atom One Dark colors |
| `dracula` | Dracula | dark | Dracula spec colors |
| `solarized-light` / `solarized-dark` | Solarized | both | Solarized |
| `monochrome-light` / `monochrome-dark` | Monochrome | both | `monochromeSyntaxJson` (bold keywords, italic comments) |
| `high-contrast-light` / `-dark` | High contrast | both | WCAG AAA (7:1) |

**Deck theme integration** ([05-themes-layouts-masters.md](05-themes-layouts-masters.md)): a
deck theme names a palette pair `code: {light: "wonky-light", dark: "wonky-dark"}` and the mono
font family (default JetBrains Mono). A code element's `palette` setting (§3.1):
- `auto` (default) — the **light** or **dark** palette of the pair, chosen by the luminance of
  the element's effective background: its own box background if set, else the slide
  background at the element's center (a dark master gets dark code automatically);
- `light` / `dark` — force one of the pair;
- a palette id — fixed palette, independent of the theme.

Changing the deck theme re-colors `auto` code elements. The app theme (light/dark chrome) never
changes slide content.

### 2.6 Dependency rules (suite 01 §2.1 updates)

```
wonky_code          → wonky_core, string_scanner, highlight          (pure Dart)
wonky_code_flutter  → flutter, wonky_code, wonky_ui, shad, re_editor
wonky_write         → … + wonky_code, wonky_code_flutter (replaces syntax_highlight)
wonky_write_core    → … + wonky_code (replaces highlight)
wonky_slides_core   → … + wonky_code
wonky_slides        → … + wonky_code, wonky_code_flutter
wonky_server        → … + wonky_code (via the cores; server PDF/MCP)
```
`wonky_code` is neither a Write nor a Sheets package, so Write and Slides may both depend on it.
`re_editor` moves from "Sheets only" to also `wonky_code_flutter` (Sheets keeps its own direct
dependency for the script editor; P2: Sheets' script editor uses `CodeEditorField` too).

### 2.7 Write migration (no visible change except export colors)

1. Write's `CodeHighlightStylePhase` calls `DefaultCodeTokenizer.tokenize` (sync; grammars are
   embedded, so the "grammar not yet loaded" state disappears) and styles via `CodeTextStyler`.
2. `CodeLanguages`, `SyntaxToken` and palettes come from `wonky_code`; Write keeps thin
   re-exports for its public APIs.
3. Write exporters call the same tokenizer (M10, decided in §2.2; M8 kept highlight.js for
   exports). Done in SL-35, together with step 1 (the editor on `DefaultCodeTokenizer`; it keeps
   its class-keyed `EditorTheme.syntax` styling instead of `CodeTextStyler`).
4. Tests: Write 04 AC-15.1/15.2 unchanged; the vendored package's patch tests
   (`wonky_patches_test.dart`) move to `wonky_code/test/textmate/` (every grammar highlights a
   realistic sample and every prefix of it).

---

## 3. The code element

### 3.1 Code `dataJson` (extends 02 §6.7)

02 §6.7 lists the base fields (`language`, `lineNumbers`, `startLine`, `wrap`, `fontSize`,
`title`, `chrome`); this is the full list. `dataJson` is whole-value LWW (02 §6).

```jsonc
{
  "v": 1,
  "language": "dart",                 // normalized id; "" = plain text (02)
  "lineNumbers": true, "startLine": 1,// (02)
  "wrap": false,                      // soft wrap at the frame width, continuation marker ↪ (02)
  "fontSize": null,                   // su; null = auto-fit (02)
  "title": "lib/main.dart",           // title text; null = none (02)
  "chrome": "tab",                    // none | tab | window (traffic lights) | caption (02)
  // --- additions (07) ---
  "showLanguage": false,              // language badge in the tab/window title
  "palette": "auto",                  // auto | light | dark | <palette id> (§2.5)
  "fontFamily": null,                 // null = "@mono" (deck theme mono font, JetBrains Mono by default)
  "fontSizeMin": 14, "fontSizeMax": 40, // auto-fit bounds (su)
  "lineHeight": 1.5,
  "ligatures": false,
  "fitAcrossStates": true,            // auto size fits the largest state (no jumping, §3.3)
  "tabSize": 2,                       // 2 | 4 | 8 (display of \t)
  "padding": 32,                      // su, inner padding of the box
  "box": { "background": null, "border": null, "cornerRadius": 16, "shadow": "soft" },
                                      // null = from palette; shadow none | soft | strong
  "highlightStyle": { "style": "dim", "dimOpacity": 0.3, "blurSigma": 2.5, "barColor": null,
                      "gutterMarker": true, "focus": "scroll", "startWithFirstStep": false },  // §4.2, §4.3
  "copyButton": "present",            // never | present (present & view modes) | always
  "typing": { … },                    // element defaults for state transitions (§5.3) + "crossSlideMode"
  "callouts": { "style": "bubble", "maxWidth": 520 }   // §4.4 defaults
}
```

### 3.2 States (`CodeState` rows)

**Decision** (02 §6.7, §3.8): **every** state, including the first, is a `CodeState` row;
`SlideElement.text` is null for code elements. The state strip treats all states alike (reorder,
duplicate, delete, per-state label, title, language, callouts and arrival settings), and
reordering never swaps contents between an element column and a row. A code element has **≥ 1**
`CodeState` (created in the same plan as the element).

| Field | Type | Meaning |
|-------|------|---------|
| `id` | UUID | |
| `element` (`elementId`) | FK | Owner code element (cascade delete). |
| `sortKey` | String | Order of states (02 §2.3). |
| `label` | String? | Name in the state strip ("Add caching") (02). |
| `code` | String | The code text of this state (`\n` line breaks, tabs kept; ≤ 20,000 chars, ≤ 1,000 lines) (02). |
| `highlight` | String? | Line-highlight step syntax (§4.1); null/`""` = no steps (02). |
| `transitionJson` | String? | How the code arrives **at this state** from the previous one (§5.3/§5.6); ignored for the first state (02). |
| `language` | String? | **Addition**: override (e.g. a state showing a shell command); null = element's language. |
| `title` | String? | **Addition**: title override (file name changes); null = element's title. |
| `annotationsJson` | String? | **Addition**: per-step callouts (§4.4). |

The canvas shows one state at a time: the **edit state** (selected in the state strip, a
per-user view setting, not synced). Thumbnails and the print frame show the **last** state.

### 3.3 Layout and auto-fit (pure Dart, `CodeLayout`)

- Grid: each grapheme cluster occupies 1 column, East Asian Wide/Fullwidth and emoji
  graphemes 2 columns, `\t` advances to the next multiple of `tabSize`. Column width = `size ×
  advanceEm` (JetBrains Mono 0.6), line height = `size × lineHeight`.
- Box geometry (su): title area (tab/window: `size × 2.2`; caption: `size × 1.6` above the box),
  padding, gutter (line numbers: `digits(lastLineNumber) + 2` columns at `0.85 × size`),
  code area.
- **Auto size** (`fontSize = null`): the largest size `s ∈ [fontSizeMin, fontSizeMax]` (step 0.5) such
  that the widest line (in columns) and the line count of the **fitting text** fit in the code
  area. The fitting text is the current state, or with `fitAcrossStates` the maximum columns and
  lines over all states (and over intermediate typing states — the maximum of the two
  endpoints bounds them because typing only shows prefixes/merges of lines of both, §5.3). With
  `wrap: true` only the line count (after wrapping at the area width) constrains the size.
- If even `fontSizeMin` doesn't fit, the element uses it and the code **overflows**: the
  viewport shows the top (or the focused lines, §4.3); the canvas shows a `fold-vertical`
  overflow badge with "18 lines hidden — enlarge the box, lower Min size or turn on wrap".
- Glyphs are painted at their grid positions (one `TextPainter` per token run per line, run
  positions from the grid); glyphs whose real advance differs (font fallback for CJK) are
  centered in their cells, so the grid stays exact.
- Ligatures are off by default (`FontFeature.disable('calt')`, `liga`) so characters animate
  individually; `ligatures: true` turns them on (they stay on during typing; morph splits them).

### 3.4 Rendering details

- Background = palette background (or `box.background`), corner radius, border, shadow (soft:
  0 12 32 rgba(0,0,0,.18); strong: 0 20 48 rgba(0,0,0,.30)).
- Chrome (`chrome`): **tab** (a rounded tab on the top-left, filename + optional language badge),
  **window** (macOS-style title bar with three dots and centered title), **caption** (small
  label above the box in the slide's text color), **none**.
- Line numbers in `lineNumber` color, right-aligned; highlighted lines' numbers in
  `lineNumberActive`; optional gutter marker bar (3 su) on highlighted lines.
- Selection (edit mode, typing animations) in the palette `selection` color; caret 2 su bar in
  `caret` color.
- Plain text (`language: ""`) uses the palette's `text` color only.
- Light/dark: palettes are content colors, so the app theme does not change them (§2.5).

### 3.5 Editing in place

**Options considered**

| Option | Pros | Cons |
|--------|------|------|
| Write's editor (super_editor, one code-block paragraph) | Same keys as Write; IME, accessibility, spellcheck plumbing exist | Heavy (document model, Delta, schema guard) for one string; layout is Flutter paragraph layout, not our grid → text shifts when entering/leaving edit |
| **`re_editor`** (already used by Sheets' script editor) | Real code editor: line numbers, indent/outdent, find, auto-pairs, multi-line selection, scroll, large files; `CodeLineSpanBuilder` hook lets us color with `wonky_code` tokens; proven in our app | Its own layout (we must match metrics); an extra dependency for Write-free packages |
| Own `EditableText`-based field | Full control, exact grid | Re-implements a code editor (selection, IME, undo, keyboard) |

**Decision**: `re_editor` behind `CodeEditorField` (`wonky_code_flutter`), configured to match
`CodeView` exactly: same font family/size (the element's computed size × canvas zoom), same line
height, same padding and gutter width, ligatures off, tokens colored through `spanBuilder`
from `DefaultCodeTokenizer.tokenizeLine` (incremental), same palette. Entering and leaving
edit mode therefore doesn't move a single glyph (golden test).

Behavior:
- Enter edit mode: double-click the code, Enter with the element selected, or *Edit code*
  (`slides.code.edit`). The field edits the **edit state** (state strip, §7). The soft lock of
  [02](02-data-model.md) §4.4 applies to `CodeState.code` (presence "Anna is editing code"; others get a
  read-only overlay with *Edit anyway*).
- Keys inside (aligned with Write 04 §15.2): Enter/Shift+Enter newline with the current
  indentation (+1 indent unit after `{ ( [ :`); Tab / Shift+Tab indent/outdent (selection: all
  touched lines); auto-pairs `( [ { " ' \``; Backspace in leading whitespace deletes to the
  previous indent stop; `Mod+/` toggles line comments (language-aware: `//`, `#`, `--`);
  `Mod+F` find within the code (re_editor find panel); `Mod+A` selects all code; paste is plain
  text (tabs kept, `\r\n` normalized). `Esc` or a click outside leaves edit mode.
- Typing coalesces into undo steps per suite 08 §3.1 (1,000 ms, no caret jumps): each step
  writes `CodeState.code` (whole-string LWW; one `slides.rows` entry with before/after code).
  While editing, the field persists after 300 ms of inactivity and on exit (02 §4.4).
- Auto-size re-fits live while typing (with `fitAcrossStates`, only when the text exceeds the
  current maximum).
- The language chip (top-right inside the box, on hover/selection, like Write) opens the
  language picker (`slides.code.setLanguage`); a palette chip opens the palette picker.
- Spellcheck is off in code.

### 3.6 Inserting code

| Entry point | Result |
|-------------|--------|
| *Insert › Code block* (`slides.insert.code`, toolbar *Code* button, "code" in the insert palette) | Code element in the selected placeholder area or centered (60 % × 50 % of the slide), language = last used, edit mode on. |
| Paste text that looks like code (≥ 2 lines and ≥ 2 of: leading indentation, `;` line ends, braces/brackets balance, keywords of a known language; or clipboard HTML with a monospace font) onto the canvas with no text box in edit mode | Pastes as a text box and shows a paste chip *Paste as code block* (one click converts; language auto-detected, P1) |
| Typing ```` ``` ```` (+ optional language) + Enter at the start of an **empty** text box | Converts the text box into a code element (same frame), Write-like |
| Dropping a source file from the OS (`desktop_drop` / web drop) (P1) | Code element with language from the extension and the file name as title; files > 20,000 chars are refused ("File too large for a code block") |
| MCP / AI | `slides.add_code_block`, walkthrough tools ([11](11-mcp-and-ai.md)) |

Copy/paste of a code element includes its states and builds (03 clipboard payload).

### 3.7 Copy button

In present mode, the shared viewer mode and published decks, hovering a code element with
`copyButton: present` (or `always`, which also shows it in the editor) shows a 32 su
`copy` icon button at the top-right of the box; it copies the **currently displayed** state's
code as plain text (`slides.code.copy`), shows the toast "Code copied" (presenter's screen only;
in present mode the toast appears in the presenter view when one is open, else as a 1 s check
icon on the button). Keyboard in present mode: none (the copy button is for the audience's own
viewer sessions and remote followers, [10](10-presenting-and-pdf.md) §6). Not undoable; Viewer+.

---

## 4. Line highlighting

### 4.1 Step syntax (`CodeState.highlight`)

reveal.js-compatible, extended:

```
steps   := step ( "|" step )*
step    := "" | "*" | items                 // "" or "*" = no highlight (all lines normal)
items   := item ( "," item )*
item    := line | line "-" line | line "-"   // "7-" = from 7 to the last line
         | line ":" col "-" col              // P2: column range within one line
line    := [1-9][0-9]*                        // 1-based physical line of the state
```

- Line numbers are **physical line numbers of the state** (1-based), independent of
  `startLine` (the UI translates when a custom start is shown; the parser accepts the
  displayed numbers when the input begins with `@`, e.g. `@42-44`, P1).
- Whitespace is ignored. Examples: `1-3 | 5 | 7-9`, `| 2,4 | *`, `10-`.
- Validation (`HighlightSteps.parse` → `HighlightStepsResult {steps, issues}`): out-of-range
  lines are clamped with an issue "Line 40 doesn't exist (the code has 32 lines)"; reversed
  ranges are swapped; empty steps are kept (they are "show all" steps). The inspector field shows
  issues inline in `destructive` color; commands accept the string and store it as typed
  (normalized form `1-3|5|7-9` written on blur).
- When a state's code changes, steps keep their numbers (they are text); lines that no longer
  exist are flagged in the inspector ("Step 3 points past the end").

### 4.2 Highlight styles (`dataJson.highlightStyle.style`)

| Style | Non-highlighted lines | Highlighted lines |
|-------|-----------------------|-------------------|
| `dim` (default) | Opacity `dimOpacity` (0.3) | normal |
| `blur` | Gaussian blur `blurSigma` (2.5 su) + opacity 0.6 | normal |
| `dimBlur` | both | normal |
| `bar` | normal | background band in `barColor` (palette `highlightBar`) spanning the line width, 4 su rounded |
| `box` | opacity 0.6 | rounded outline (2 su, palette `caret` color) around each contiguous highlighted range |
| `none` | normal | normal (steps used only for focus/callouts) |

- Transitions between steps animate: opacity/blur cross-interpolate per line over the build's
  duration (default 400 ms, `easeInOut`); bars and boxes morph their rectangles (union of line
  rects per contiguous range, matched by overlap).
- Line numbers of highlighted lines use `lineNumberActive`; the gutter marker (3 su bar) appears
  next to highlighted lines when `gutterMarker` is on.
- In PDF, `blur` is rendered as `dim` with opacity 0.45 (no blur in vector PDF; P2: rasterized
  blur).

### 4.3 Focus: keeping highlighted lines in view

When the code overflows its box (§3.3), a step brings its lines into view:
- `focus: scroll` (default) — the viewport scrolls so that the highlighted range is centered
  (or top-aligned if taller than the viewport), with a spring (`spring(0.6,0)`).
- `focus: zoom` (Code Hike style) — the font scales up/down (within `fontSizeMin…fontSizeMax × 1.5`) and
  scrolls so that the highlighted range fills ≥ 60 % of the viewport height; non-highlighted
  lines may leave the box (clipped with a 24 su fade at the edges).
- `focus: none` — no movement.

### 4.4 Callouts (per-step annotations)

`CodeState.annotationsJson`:

```jsonc
{
  "v": 1,
  "steps": {
    "2": {                                  // 1-based step index
      "text": "**Null-safe** by default",   // inline Markdown (bold, italic, code), ≤ 280 chars
      "anchor": { "line": 5, "side": "right" },   // line: default = last highlighted line;
                                                  // side: auto | right | left | above | below
      "style": "bubble",                    // bubble | label | pill (element default if omitted)
      "dx": 0, "dy": 0                      // su nudge set by dragging the callout
    }
  }
}
```

- Rendering: a callout is drawn by `CodeView` **outside or over** the code box (it may extend
  beyond the element frame; the element's selection bounds include it in the editor). `bubble`
  = rounded rectangle with a pointer toward the anchor line (deck theme accent background, text
  in contrasting color, body font at 0.9 × code size, max width `callouts.maxWidth`); `label` =
  text with a thin leader line; `pill` = compact rounded tag at the line end.
- `side: auto` picks right if there is ≥ maxWidth/2 space between the code's longest
  highlighted line end and the box edge, else below the range, else above.
- Animation: the callout of step *n* fades and rises 12 su in with the step (250 ms after the
  highlight starts) and fades out when the next step starts.
- Callouts are part of the PDF (builds as pages: the step's callout; print frame: none).
- Editing: in the state strip's step list (§7) each step has a callout field; on the canvas the
  callout of the selected step can be dragged (writes `dx/dy`) and double-clicked to edit text.

### 4.5 Builds

Each highlight step is a `codeHighlight` emphasis build (06 §3.3) with `params.step`. The
inspector's *Build all steps* (`slides.animate.buildAllSteps`) creates, for every state in order:
`codeHighlight` builds for its steps 1…n, then a `codeState` build for the next state (type-in or
morph per that state's `transitionJson`), all `onClick` — i.e. one click per step and per state
change. Before the first build the element shows state 1 with **no** highlight (or step 1 already
active when `highlightStyle.startWithFirstStep` is true, P1).

---

## 5. Code states, type-in and morph

### 5.1 Overview

Advancing from state *N* to *N + 1* (a `codeState` build, or Magic Move between slides, §5.7)
animates the change in one of three modes, set per target state (`CodeState.transitionJson.mode`,
default from `dataJson.typing.mode`):

| Mode | Look | When to use |
|------|------|-------------|
| `type` (default) | A caret moves to each change; deletions are backspaced or selected and deleted; insertions are typed character by character with optional human-like rhythm | Live-coding feel; small and medium changes |
| `morph` | Unchanged tokens glide to their new positions; removed tokens fade out; new tokens fade in | Refactorings, reordering, large changes |
| `instant` | Crossfade (200 ms) | Big rewrites, reduced motion |

### 5.2 Diff: from two states to an edit script (`CodeEditScript.compute`)

1. **Line diff** with `SequenceDiff` (Myers) over lines → equal / delete / insert runs.
2. **Pairing**: each adjacent (delete-run, insert-run) block is a *replace hunk*. Within a hunk,
   old and new lines are paired in order when their character similarity (`1 − charEditDistance
   / max(len)`, computed with Myers on grapheme clusters) is ≥ 0.4; unpaired old lines are
   deleted whole, unpaired new lines inserted whole.
3. **Character diff** for each paired line: Myers on grapheme clusters → keep / delete / insert
   spans.
4. **Token snapping**: if a character edit changes more than 50 % of a token of the old or new
   line (tokens from the tokenizer), the edit is widened to the whole token (typing `total`
   instead of morphing `count` → `tot` + `al`); adjacent edits closer than 3 kept characters on
   the same line are merged (one caret visit).
5. Result: `CodeEditScript { edits: [CodeEdit {oldStart, oldEnd, newText, kind: insert|delete|
   replace, lineIndex}] }` in document order (offsets into the **old** text; the typing
   simulation shifts them as it goes).

The script is deterministic and independent of the tokenizer except for step 4 (same tokenizer
everywhere, §1).

### 5.3 Typing simulation (`TypingScript.build`)

Settings (`CodeState.transitionJson` overrides `dataJson.typing`; defaults shown):

```jsonc
{
  "mode": "type",                 // type | morph | instant
  "cps": 28,                      // typed characters per second (5–200)
  "deleteMode": "auto",           // auto | backspace | select
  "backspaceMax": 12,             // auto: deletions up to n chars are backspaced, longer ones selected + deleted
  "deleteCps": 60,                // backspace speed
  "jitter": 0.35,                 // 0–1: per-keystroke delay varies ± jitter × base (seeded)
  "pauses": { "lineEnd": 160, "punctuation": 60, "betweenEdits": 300, "beforeStart": 200 },  // ms
  "caretGlideMs": 180,            // caret moves to the next edit (0 = jump)
  "order": "document",            // document (top → bottom) | reverse (bottom → top)
  "pasteLines": 12,               // insertions with ≥ n new lines appear as a paste (fade-in 250 ms) instead of being typed
  "autoIndent": true,             // new lines get their leading whitespace instantly (editor auto-indent)
  "maxDurationMs": 10000,         // if the natural duration is longer, speed scales up to fit
  "scrollFollow": true,           // §5.5
  "highlightOnArrive": true,      // apply the target state's step 1 at the end (if any)
  "caret": "bar",                 // bar | block | underline; hidden at the end after 600 ms
  "sound": false                  // P2: key clicks in present mode only
}
```

Algorithm:
1. Start from the old text; caret appears at the first edit (fade 150 ms), after
   `pauses.beforeStart`.
2. For each edit in `order`: glide the caret to the edit's position (`caretGlideMs`, ease);
   pause `betweenEdits` (except the first).
   - **Delete** part: if `deleteMode = backspace` or (`auto` and length ≤ `backspaceMax`): place
     the caret at the end of the deleted span and remove one grapheme per keystroke at
     `deleteCps`; else select the span (selection grows over 200 ms) then remove it at once.
   - **Insert** part: if the inserted text has ≥ `pasteLines` lines, it appears as a paste
     (fade 250 ms, caret jumps to its end). Otherwise each grapheme is one keystroke at `cps`;
     after a newline, with `autoIndent`, the next line's leading whitespace appears in the same
     keystroke; extra pauses after newlines (`lineEnd`) and after `; , . ) } ]`
     (`punctuation`).
   - Keystroke delays: `base × (1 + jitter × (2u − 1))` with `u` from `SplitMix64(seed)`,
     `seed = hash(elementId, targetStateId)`; never below 15 ms.
3. If the total exceeds `maxDurationMs`, all delays (not the caret glides) scale by
   `maxDurationMs / natural` (min factor 0.1; beyond that remaining insertions become pastes).
4. Output: `TypingScript { events: [TypingEvent {atMs, kind: caretTo|select|delete|insert|
   paste|scroll|end, payload}], durationMs }` plus a **snapshot index** (text + caret every 50
   events) so `stateAt(ms)` is O(log n + 50).

The duration of a `codeState` build in `type` mode is derived (`durationMs` of the `SlideBuild` is
ignored, the pane shows "≈ 4.2 s (typed)").

### 5.4 Highlighting while typing

The intermediate text is tokenized **incrementally**: line end-states of the TextMate tokenizer
are cached; after a keystroke, lines from the edited line on are re-tokenized until a line's end
state equals the cached one. highlight.js languages re-tokenize the edited line ± 20 lines (no
state). Budget: ≤ 1 ms per keystroke for 300-line code on desktop; tokens per snapshot are cached
for seeking.

### 5.5 Viewport and scroll-follow

The font size during the animation is fixed (auto size fits all states, §3.3). If the code
overflows the box, the viewport follows the caret: it scrolls (spring) so the caret stays ≥ 2
lines from the top/bottom edge; at the end it settles on the target state's focus (§4.3) or the
top. Horizontal overflow (no wrap) scrolls horizontally the same way.

### 5.6 Morph mode (`TokenMorphPlan`)

1. Tokenize both states into **lexemes** (token spans split at whitespace; whitespace is not
   animated).
2. Match lexemes with `SequenceDiff` over `(text)` (equality: same text); then match leftover
   identical lexemes across non-aligned positions greedily by nearest grid distance (moved lines
   and swapped blocks). Lexemes whose text is equal but token class differs still match (color
   interpolates).
3. Matched lexemes animate from old grid position to new (x/y, in OKLab color, font size when the
   auto size differs); removed lexemes fade out and drift 8 su upward during the first 50 %;
   added lexemes fade in and settle from 8 su below during the last 60 %; line numbers crossfade;
   the box frame and title interpolate.
4. Defaults: 800 ms, `easeInOutCubic`, optional `stagger` (ms per line, default 0).

### 5.7 Across slides (Magic Move)

Two code elements with the same `matchKey` on consecutive slides with a Magic Move transition
(06 §8) animate from the source element's **displayed** state at the end of its slide to the
target element's **first** state. The mode is the target element's
`dataJson.typing.crossSlideMode` (default `morph`; `type` and `instant` are allowed). Frames,
title and palette interpolate like other elements.

### 5.8 Determinism and end states

`CodeViewState` (06 §9.2) = `{stateIndex, toStateIndex?, progressMs, highlightFrom, highlightTo,
highlightProgress, scroll}`. Given the same inputs, client, server and PDF produce identical
typing scripts and frames. PDF/thumbnails show completed states (the last state for thumbnails
and the print frame; each state/step end for builds-as-pages).

### 5.9 In-builds and reduced motion

- `codeType` (in-build) types the **first** state from an empty box using the first state's
  typing settings.
- Reduced motion (06 §13): `type` and `morph` become `instant` (200 ms crossfade); highlight
  steps crossfade; scroll-follow jumps.

---

## 6. Builds integration (summary)

| Build | Effect | Meaning |
|-------|--------|---------|
| In | `codeType` | Type state 1 from empty. Also every generic in-effect (fade, rise…) works on code. |
| Emphasis | `codeHighlight {step}` | Go to highlight step *step* of the current state. |
| Emphasis | `codeState {state, mode?}` | Go to state *state* (mode overrides the state's `transitionJson.mode`). |
| Out | any out effect | — |

The timeline (06 §9) validates order: a `codeHighlight` refers to the steps of the state that is
current at that point; invalid references are skipped with a warning ("Step 4 doesn't exist in
state 2"). Jumping states backwards (`state` < current) plays `instant` unless `mode` is set.

---

## 7. Inspector: the Code section and state strip

Shown in the Format inspector ([04](04-screens-menus-toolbar.md)) when a code element is
selected:

```
┌ Code ─────────────────────────────────────────────────────┐
│ Language [ Dart ▾ ]   Palette [ Auto (Wonky Dark) ▾ ]      │
│ Font size [ Auto ▾ ] (28)   Min [14] Max [40]   ☐ Ligatures │
│ ☑ Line numbers  start [1]   ☐ Wrap   Chrome [ tab ▾ ] [lib/main.dart] │
│ Copy button [ In presentation ▾ ]                            │
├ States ────────────────────────────────────────────────────┤
│  ┌───┐ → ┌───┐ ⌨ ┌───┐ ◇ ┌───┐   [+]                      │
│  │ 1 │   │ 2 │   │ 3 │   │ 4 │                             │  mini previews; arrows show the
│  └───┘   └───┘   └───┘   └───┘                             │  transition mode (⌨ type, ◇ morph)
│  State 2 · 18 lines · +3 −1 vs. state 1     [⧉] [🗑] [▶]    │
│  ☐ Show changes (diff gutter)                               │
│  Arrives by [ Typing ▾ ]  Speed [ 28 ] cps  Rhythm ▬▬▬○ 0.35 │
│  Deletions [ Auto ▾ ]  More…                                │
├ Line steps (state 2) ──────────────────────────────────────┤
│  [ 1-3 | 5 | 7-9                                  ] ✓       │
│  ① 1-3   "Imports"                         ✎  ×            │
│  ② 5     "**Null-safe** by default"         ✎  ×            │
│  ③ 7-9   —                                  ✎  ×            │
│  [ Pick lines… ]  Style [ Dim ▾ ]  Focus [ Scroll ▾ ]        │
├────────────────────────────────────────────────────────────┤
│  [ Build all steps ]   4 builds on this slide · ▶ Preview   │
└────────────────────────────────────────────────────────────┘
```

- **State strip**: chips with live mini previews (rendered by `CodeView` at thumbnail scale);
  click selects the edit state (the canvas shows it); drag to reorder
  (`slides.code.moveState`); `+` adds a state = duplicate of the selected one placed after it
  (`slides.code.addState`, the usual way to "change the code"); ⧉ duplicate; 🗑 delete (disabled
  for the last remaining state); ▶ previews the transition into the selected state on the
  canvas. Keyboard: `Alt+Shift+←/→` previous/next state while a code element is selected
  (contextual canvas binding; `Mod+Alt+←/→` align objects and `Mod+Alt+N` jumps to comments,
  04 §4.7 / 09); *New state* has no default chord (palette, state strip `+`).
- **Diff gutter** (*Show changes*): in edit mode the gutter marks lines added (`+`, green) and
  changed (`~`, amber) compared with the previous state, and shows removed lines as a thin red
  marker between lines — so authors see what will be typed.
- **Arrives by**: Typing / Morph / Instant + typing settings (*More…* opens all §5.3 settings).
  The estimated duration is shown ("≈ 4.2 s").
- **Line steps**: the text field accepts the §4.1 syntax (validated inline); the list below shows
  parsed steps with an optional callout text each (✎ edits inline; Markdown-lite).
- **Pick lines…** (`slides.code.pickLines`): the canvas enters a line-picking mode for the
  selected code element: a checkbox column appears in the gutter; click, Shift-click (range),
  drag over line numbers to select lines; a floating bar offers *Add as step*, *Replace step
  n*, *Done*. Selected lines preview the highlight style live.
- **Build all steps** (§4.5); the counter links to the Animate panel's Order tab.

---

## 8. Presenting

- Each highlight step and state change is a click (build). The presenter view
  ([10](10-presenting-and-pdf.md) §5) labels the next build "Code: type state 3 (≈ 4 s)" /
  "Code: highlight lines 7–9" and shows the next state in the "next" preview.
- Clicking during typing finishes it immediately (06 §6); `←` returns to the previous step's end
  state instantly.
- `Shift+→` (next slide) skips remaining code steps.
- Copy button: §3.7. Present-mode option *Show caret in code animations* (default on).
- Live followers and remotes (10 §6) receive the step index, not the typing state; their own
  timeline plays the same deterministic animation (latency-compensated: they start at
  `now − startedAt`).

---

## 9. Exports

- **PDF** ([10](10-presenting-and-pdf.md) §11): vector text in the deck's mono font (embedded,
  subset), token colors, box, title, line numbers, highlight styles (blur → dim), callouts per
  builds-as-pages step; print frame = last state without highlight dimming.
- **PNG** (P1): via the stage.
- **Copy as image** of a code element (P1): PNG to the clipboard at 2×.
- **Copy code** (`slides.code.copy`): plain text of the edit state (editor) or displayed state
  (present).

---

## 10. MCP and AI hooks

### 10.1 Tools (defined in [11](11-mcp-and-ai.md))

`slides.add_code_block {deck, slide, language, states: [{code, title?, highlight_steps?,
annotations?, arrive?: {mode, cps, …}}], frame?, options?, builds?: "all_steps" | "none"}`,
`slides.update_code_block`, `slides.set_code_states` (replace all states), and
`slides.code_walkthrough_from_diff` (below). All accept Markdown-free plain code; highlight steps
use the §4.1 syntax.

### 10.2 Walkthrough from a diff (deterministic core)

`UnifiedDiff.parse(text)` (pure Dart, `wonky_code`) reads `git diff` / `diff -u` output
(file headers, `@@ -a,b +c,d @@` hunks, renames, new/deleted files; binary files skipped with a
warning). `WalkthroughBuilder.build(diff, options)` produces a deck fragment:

| Option | Values (default) | Effect |
|--------|------------------|--------|
| `granularity` | `file` \| `hunk` (`file`) | One code element per file, or per hunk |
| `layout` | `slidePerFile` \| `slidePerHunk` \| `singleSlide` (`slidePerFile`) | Where elements go |
| `states` | `beforeAfter` \| `progressive` (`progressive`) | before → after, or before → after hunk 1 → after hunks 1–2 → … |
| `source` | `hunks` \| `fullFiles` (`hunks`) | With `fullFiles` the caller supplies before/after file contents (MCP `files: [{path, before, after}]`), else the code is the hunks' context + changed lines, with `⋯` separator lines between hunks |
| `maxLines` | 40 | Longer states are split into windows around the changes (each window its own element/slide) |
| `highlight` | `changed` \| `none` (`changed`) | Steps highlighting the changed lines of each state |
| `arrive` | `type` \| `morph` (`type` for ≤ 15 changed lines, else `morph`) | Transition mode |
| `titleSlide` | bool (true) | A section title slide per file ("lib/user.dart — 3 changes") |

Language from the file extension (§2.4); title tab = path. The builder is used by the command
*Insert › Code walkthrough from diff…* (`slides.code.walkthroughFromDiff`: dialog with a diff
text area, a file list with checkboxes, the options above, *Insert*), by the MCP tool and by the AI.

### 10.3 AI layer

`slides.ai.codeWalkthrough` ([11](11-mcp-and-ai.md) §6.6) runs the deterministic builder and
then asks the model (strict tool `annotate_walkthrough`) for: slide titles, one callout per
highlight step (≤ 120 chars), speaker notes per slide, and optionally a reordered state sequence
that tells a story (e.g. interface first). The model never edits the code text itself; the
result is previewed (Suggest mode) or applied as one undo step.

---

## 11. Commands

`requiredRole` editor unless noted. Undoable commands = one `slides.rows` undo step.

| Command id | Args | Undoable | Notes |
|------------|------|----------|-------|
| `slides.insert.code` | `{language?, code?, frame?}` | ✓ | "Insert code block" (id from 04 §4.4). |
| `slides.code.edit` | `{elementId?, stateId?}` | — | Enter edit mode. |
| `slides.code.setLanguage` | `{elementIds?, language}` | ✓ | |
| `slides.code.setPalette` | `{elementIds?, palette}` | ✓ | |
| `slides.code.updateOptions` | `{elementIds?, patch: JsonMergePatch on the code dataJson, coalesceKey?}` | ✓ | Font, numbers, wrap, title, box, highlight style, copy button, typing defaults. |
| `slides.code.setText` | `{elementId, stateId?, code}` | ✓ | Replaces a state's code (MCP, paste-replace). |
| `slides.code.addState` | `{elementId?, afterStateId?, code?}` | ✓ | Default: duplicate of the selected state. |
| `slides.code.duplicateState` / `deleteState` | `{stateId}` | ✓ | Delete refuses the last state. |
| `slides.code.moveState` | `{stateId, to: {index}}` | ✓ | |
| `slides.code.selectState` | `{elementId?, stateId \| index \| delta}` | — | Edit state (view). `Alt+Shift+←/→` (code element selected). Viewer+. |
| `slides.code.setStateTransition` | `{stateId, transition: JsonMergePatch}` | ✓ | |
| `slides.code.setHighlightSteps` | `{stateId?, steps: string}` | ✓ | |
| `slides.code.setCallout` | `{stateId?, step, callout: {text, anchor?, style?, dx?, dy?} \| null}` | ✓ | |
| `slides.code.pickLines` | `{elementId?}` | — | Enters picking mode. |
| `slides.code.addStepFromLines` | `{stateId?, lines: [int], replaceStep?}` | ✓ | From picking mode. |
| `slides.code.toggleDiffGutter` | — | — | View setting. |
| `slides.code.copy` | `{elementId?}` | — | Viewer+. |
| `slides.code.convertFromText` | `{elementId, language?}` | ✓ | Text box → code (paste chip, ```` ``` ````). |
| `slides.code.walkthroughFromDiff` | `{diff?, options?}` | ✓ (insert) | Without `diff` opens the dialog. |
| `slides.animate.buildAllSteps` | `{elementId}` | ✓ | Defined in 06 §15. |

Context menu of a code element: *Edit code*, *Language ▸*, *Palette ▸*, *Add state*, *Copy
code*, *Build all steps*, standard element items.

---

## 12. Undo and concurrency

| Operation | Rows | Label |
|-----------|------|-------|
| Typing in edit mode (coalesced) | `CodeState.code` | "Typing" |
| Options | `SlideElement.dataJson` | "Edit code block" |
| Add/duplicate/delete/move state | `CodeState` insert/delete/`sortKey` | "Add code state" … |
| Steps / callouts / state transition | `CodeState` columns | "Edit line steps" … |
| Walkthrough insert | slides + elements + states + builds | "Insert code walkthrough" |

Concurrency (field-level LWW): two users editing **different** states merge; the same state's
`code` is one column (last writer wins), mitigated by the soft lock (02 §4.4) — a user who chooses
*Edit anyway* is warned "Changes by Anna to this code may be overwritten". `dataJson` edits are
read-modify-write patches on the latest local value. Deleting the element deletes its states
and builds.

---

## 13. Accessibility

- Semantics: "Code block, Dart, 24 lines, title lib/main.dart" + the displayed code as the
  value; line steps announced in present mode ("Lines 7 to 9 highlighted: <callout>").
- Type-in announces the final state once ("Code updated, 3 lines changed") instead of every
  keystroke.
- Edit mode is a standard text input for screen readers (re_editor semantics).
- Palettes meet 4.5:1 (high-contrast palettes 7:1); `dim` at 0.3 is decorative — highlighted
  lines remain fully readable.

---

## 14. Performance

| Item | Budget |
|------|--------|
| Tokenize 1,000 lines (TextMate, Dart grammar) | ≤ 15 ms desktop, ≤ 30 ms web; cached per (text hash, language) |
| `CodeView` paint of 60 visible lines | ≤ 2 ms |
| Typing animation frame (300-line code, incremental tokenize + paint) | ≤ 4 ms |
| `TypingScript.build` for 200 changed lines | ≤ 20 ms (computed when the slide is prefetched, 06 §14) |
| `TokenMorphPlan.build` for 2 × 300 lines | ≤ 15 ms |
| Edit mode keystroke latency (500 lines) | < 16 ms p95 |

---

## 15. Acceptance criteria

1. Write code blocks look the same before and after the `wonky_code` migration (golden tests),
   and the Write editor no longer has a "grammar loading" plain-text flash.
2. The same Dart snippet has identical token colors in the Slides canvas, present mode, the
   client PDF and the server PDF (token color extraction test on the PDF content stream).
3. A code element with auto size shows 30 lines × 80 columns at ≥ 16 su in a 1600 × 900 su
   box; adding a longer second state does not change the size of state 1 when `fitAcrossStates`
   is on.
4. Entering and leaving edit mode moves no glyph (pixel golden at 1× and 2× zoom).
5. `1-3 | 5 | 7-9` creates three steps; *Build all steps* creates 3 highlight builds; in present
   mode each click dims all other lines with a 400 ms animation and the step's callout appears.
6. Adding state 2 (rename a variable, add 3 lines, delete 1) and presenting types the change: the
   caret glides to each change, backspaces the short deletion, types insertions with rhythm, and
   ends on exactly state 2's text; the PDF with builds as pages has one page per state/step.
7. Morph mode moves unchanged tokens to their new positions without any token jumping (frame
   test: every matched lexeme's position is monotonic in time between endpoints).
8. Two slides with the same code element (`matchKey`) and Magic Move morph the code between them.
9. Walkthrough from a 3-file `git diff` inserts title + code slides with progressive states and
   changed-line steps; one undo removes everything.
10. Typing script and frames are identical on VM and web (determinism test with jitter on).
11. Viewers see the copy button in present/view mode and copying yields the displayed state's
    text.
12. All commands in §11 pass execute → undo → redo.

## 16. Tests

- `wonky_code`: tokenizer per language (samples + every prefix, moved from the vendored
  package), highlight.js mapping, alias/extension tables, palette contrast, `CodeLayout` (wide
  chars, tabs, wrap, auto size), `HighlightSteps.parse` (grammar, clamping, issues),
  `CodeEditScript` (pairing, char diff, token snapping; property test: applying the script to
  the old text yields the new text for random edits), `TypingScript` (end text equals target;
  durations; scaling; seeded jitter), `TokenMorphPlan` (matching, moves), `UnifiedDiff` (git
  fixtures incl. renames, new/deleted files, no-newline markers), `WalkthroughBuilder`.
- `wonky_core`: `SequenceDiff` generic (property test vs. brute-force LCS for small inputs).
- `wonky_code_flutter`: `CodeView` goldens (palettes, styles, title styles, callouts, light/dark
  slides), `CodeEditorField` metric parity golden, widget tests for edit keys.
- `wonky_slides`: inspector state strip and pick-lines flows, commands execute/undo/redo,
  present-mode typing E2E (finish on click).

---

## 17. Additions to 02-data-model

| # | Change | Reason |
|---|--------|--------|
| A-07-1 | Code `dataJson` (02 §6.7) gains: `showLanguage`, `palette`, `fontFamily`, `fontSizeMin`, `fontSizeMax`, `lineHeight`, `ligatures`, `fitAcrossStates`, `tabSize`, `padding`, `box {background, border, cornerRadius, shadow}`, `highlightStyle {style, dimOpacity, blurSigma, barColor, gutterMarker, focus, startWithFirstStep}`, `copyButton`, `typing {§5.3 settings, crossSlideMode}`, `callouts {style, maxWidth}`. Steps live in `CodeState.highlight` (§3.2). | §3.1 |
| A-07-2 | `CodeState` (02 §3.8) gains `language: String?`, `title: String?`, `annotationsJson: String?` (§4.4). `highlight` uses the §4.1 grammar; `transitionJson` the §5.3 schema (incl. `mode: type\|morph\|instant`, as in 02). Every state incl. the first is a `CodeState` row; `SlideElement.text` is null for code (§3.2, as 02 §6.7). Invariant: ≥ 1 state per code element (created in the same plan as the element; the last state can't be deleted; maintenance recreates an empty state if a concurrent delete removed all). | §3.2 |
| A-07-3 | Limits: `CodeState.code` ≤ 20,000 chars / 1,000 lines; ≤ 50 states per element. | §3.2 |
| A-07-4 | Deck theme gains `code: {light: paletteId, dark: paletteId}` and `fonts.mono` (default JetBrains Mono) — owned by 05. | §2.5 |
| A-07-5 | Per-user view state (local, not synced): the edit state per code element, diff-gutter toggle. | §3.2, §7 |
| A-07-6 | Suite 01 §2.1: new packages `wonky_code` (pure) and `wonky_code_flutter`; `wonky_core` exports `SequenceDiff`; `third_party/syntax_highlight` removed after the Write migration. | §2 |
