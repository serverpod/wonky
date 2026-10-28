# Write 11 · Wonky Markdown

**Wonky Markdown** is a second Markdown flavor for Wonky Write documents: GitHub-Flavored
Markdown plus the directives of the Serverpod blog (`serverpod_website`,
`serverpod_website_server/doc/serverpod_markdown_spec.md`). A document is written in exactly
one flavor. **GitHub** (GFM, everything in [02](02-document-model.md)) is the default; in
**Wonky** mode the editor offers callouts, expandable details, cards, grids, buttons, arrow
links, chips and numbered headings, edits them visually, and reads and writes them as the
blog's directive syntax, so a Wonky document submitted to the blog
([../18-publications-and-submissions.md](../18-publications-and-submissions.md)) renders there
as it looks in Write.

Status: in progress. This spec is the source of truth for the feature; the specs it extends
(02, 04, 05, 06, 07, 09, 18) link here instead of repeating it.

## 1. Decisions

| # | Decision | Reason |
|---|----------|--------|
| WM1 | The flavor is a **document setting** (`markdownFlavor`: `gfm` \| `wonky`, default `gfm`), a meta change like the language (05 §13.1): LWW, undoable in `write.meta`, editors only | The content depends on it; every collaborator, export and MCP client must agree on it |
| WM2 | Switching **Wonky → GitHub** asks first, then converts every Wonky element to its closest GFM form in the same undo step (§3.2) | A GFM document never carries content GFM cannot write |
| WM3 | Switching **GitHub → Wonky** changes no content | GFM is a subset of Wonky Markdown, except literal text that would now read as a directive, which the exporter escapes (§5.3) |
| WM4 | The syntax is **exactly the blog's** (§4), limits included; Write never writes Markdown the blog would render differently | Submissions must render on the blog as they look in Write |
| WM5 | Containers (callout, details, card) are a **`box` stack on every line** they contain, like a quote, not embeds; they nest (§2.2) | Their content stays ordinary editable lines: lists, code, images, tables and other containers inside work with every existing editing feature, OT, comments and suggestions |
| WM6 | The grid is an **embed** with inline-Markdown items, edited in place like a table | A grid lays items out side by side, which a vertical document layout of lines cannot show; an embed renders the real grid |
| WM7 | Button and arrow link are a **`linkStyle`** of a link; a chip is a **`chip`** text attribute | They are text with a look: labels stay editable inline, and the link popover sets the style |
| WM8 | Numbered headings store their **explicit number** (`step`), as the Markdown does; commands propose the next number | User decision; round-trips exactly |
| WM9 | The look comes from the **document theme** (new elements, §8); built-in themes get defaults close to the blog's, in light and dark | Themes, not formatting (01 §2) |
| WM10 | Chip icons (`{icon=…}`) are **kept but not shown** | Out of scope for the UI; keeping the value makes import → export lossless |
| WM11 | A **publication** can declare Wonky Markdown; documents started from its link begin in Wonky mode and submit Wonky Markdown | The Serverpod blog takes directives |

## 2. Delta schema additions (Wonky Delta Schema v1, 02 §1)

All additions are valid in documents of either flavor (the flavor is a setting, not a schema
version), so a flavor change racing with an edit never makes an op invalid. The UI only offers
them in Wonky mode, and the GFM exporter writes them in their GFM form (§3.2).

### 2.1 Inline attributes

| Attribute | Value | Markdown (Wonky) | Rules |
|-----------|-------|------------------|-------|
| `linkStyle` | `"arrow"` \| `"button"` \| `"buttonSecondary"` | `:link[label](url)` · `:button[label](url)` · `:button[label](url){variant=secondary}` | Only with `link` (not a mention link). The label is plain text: excludes `bold`, `italic`, `strike`, `code`, `mention` (like `code`, 02 §1.4 rule 3) |
| `chip` | `true`, or a `String` icon name `[a-z0-9-]{1,32}` | `:chip[label]` · `:chip[label]{icon=name}` | Plain text: excludes every other inline attribute, `link` included |

Labels cannot contain `]` (blog grammar `[^\]]*`), so the exporter writes a `]` in a label as
`)` (§5.3); neither label holds a soft break (exported as a space). Adjacent runs with equal
attributes merge in the canonical Delta, so `:chip[A]:chip[B]` (no space) imports as one chip
`AB`; the blog writes chips with a space between them.

### 2.2 Block attributes

| Attribute | Value | Markdown (Wonky) | Rules |
|-----------|-------|------------------|-------|
| `box` | `[Frame, …]`, outermost first, 1–3 frames | `:::callout`/`:::details`/`:::card` … `:::` around the lines | On any line, embed lines included; next to every other block attribute |
| `step` | `int` 0–9999 | `## (n) Title` / `### (n) Title` | Only with `header: 2` or `header: 3` |

A **Frame** is a map:

| Key | Value | Notes |
|-----|-------|-------|
| `id` | String, UUIDv7 | Identity of the container; new containers get a fresh id |
| `type` | `"callout"` \| `"details"` \| `"card"` | |
| `variant` | `"info"` \| `"tip"` \| `"note"` \| `"warning"` \| `"caution"` \| `"danger"` | Callouts only (required); `caution` is the blog's alias of `warning` with its own label |
| `title` | String, single line, ≤ 200 chars, no `]` | Callouts only, optional (`:::warning[Heads up]`); plain text |

**Containers are runs.** At depth *k*, consecutive lines whose frame *k* has the same `id`
(and the same frames 0…*k*−1) form one container. A container's properties are those of its
first line's frame; the other lines' copies are ignored by renderers and exporters (an OT race
can leave them stale; the next edit of the container rewrites all of them). An id that comes
back after other lines starts a second container. These rules make a box interpretable from
any lines without cross-line normalization, so the normalizer's per-line window (02 §1.4,
`normalizedChange`) still holds.

**Details summary.** A details container's summary is its first line when that line is a
`header: 3` directly in it (not in a nested container); otherwise the summary is empty. The
importer moves the blog's summary (the first own `###` anywhere in the block) to the front.

**Lists in containers.** A list run ends where the `box` path changes (indent and numbering
restart), like a quoted and an unquoted list (02 §1.2).

**Quotes in containers** are allowed; a container cannot be inside a quote (a line with
`blockquote` keeps its `box`, and the quote is drawn inside the container).

### 2.3 Block embeds `grid` and `youtube`

> **Grids are native lines now** ([12 §1.2](12-native-cells.md)): each item is a line with the
> `grid` line attribute `{id, columns, bullets}`. The `grid` embed below is the legacy form,
> still read (and upgraded by the server, 12 §1.5) but never written.

| Embed | Value | Markdown (Wonky) |
|-------|-------|------------------|
| `grid` | `{"id", "columns": 1–4, "bullets": "check"\|"circle"\|"none", "items": [cellMarkdown, …]}` | `:::grid{columns=3 bullets=check}` + one `- item` line per item + `:::` |
| `youtube` | `{"id", "videoId": 11 chars [A-Za-z0-9_-], "start"?: seconds 0–360000, "title"?: single line ≤ 300 chars without `]`}` | `::youtube[Title]{id=AGAQ_N56wCs start=90}` (title and `start` optional) |

The YouTube video is a Wonky extension of our own: the blog has no renderer for it yet
(`docs/blog-integration.md` describes the one it needs; existing posts embed `<iframe>` HTML,
which Write doesn't import). `YouTubeEmbed.parseUrl` reads `watch?v=`, `youtu.be/`, `/embed/`,
`/shorts/`, `/live/` and `youtube-nocookie.com` links and bare ids, with `t=`/`start=` times
(`90`, `90s`, `1m30s`).

Items are inline Markdown strings like table cells (02 §1.3), single line, may be empty. A grid
has 1–100 items. The blog's default for a missing or invalid `columns` is 3 and for `bullets`
`none`; the canonical embed always holds both. A grid line may carry `box` (a grid in a card).

### 2.4 Validator and normalizer (02 §1.4)

New per-line rules (rule numbers continue 02 §1.4):

10. `linkStyle` only with a non-mention `link`; `chip` without `link`/`mention`; the
    exclusions of §2.1 (normalizer: drop the excluded keys, like `code`).
11. `box` is a list of 1–3 valid frames with distinct ids; invalid frames are dropped
    (normalizer), a `title` is trimmed to one line of ≤ 200 chars and `]` becomes `)`.
12. `step` only with `header` 2–3, value 0–9999 (normalizer: removed otherwise).
13. Grid embeds are canonical (`columns` clamped to 1–4, unknown `bullets` → `none`, items
    single-line, 1–100 items).
14. YouTube titles are canonical (one line, `]` → `)`, ≤ 300 chars, empty → none).

Embed lines keep `box` (all other block attributes are still removed from them).

## 3. Flavor setting

### 3.1 Model and UI

- Server: `Document.markdownFlavor` (`String`, `gfm` | `wonky`, default `gfm`), part of
  `DocumentMetaView`, `DocumentMetaPatch`, `DocMetaChanged` and `DocumentMetaChange`
  (`field: markdownFlavor`). Copies keep it; Markdown import into a new document takes the
  importing user's choice (§5.1).
- *File › Markdown flavor ▸* **GitHub Markdown** / **Wonky Markdown** (radio), after *Language…*
  and *Page setup…*: `write.doc.setMarkdownFlavor {flavor}`. Editors only; others see the
  current value disabled. Collaborators get the meta toast (05 §13.1).
- The title row shows nothing extra; the flavor is visible in the menu, in *File › Details* and
  in the Wonky items that appear in the menus, toolbar and slash menu.

### 3.2 Switching to GitHub (conversion)

If the document holds Wonky elements, a confirmation dialog lists what will change (counts per
element) with *Convert to GitHub Markdown* / *Cancel*. On confirm, one command applies the
conversion Delta and the meta change in one undo step (`write.doc.setMarkdownFlavor` is a
composite step: content change + meta change; undo restores both). Conversion
(`WonkyToGfm.convert(Delta) → Delta`, core, also used by the GFM exporter on the fly):

| Element | GFM form |
|---------|----------|
| Callout | A quote: a bold first line with the title, or the type label (*Warning*), then the content as quote lines; lists stay quoted lists; headings, code blocks, embeds and nested containers' content leave the quote (02 §1.2 cannot quote them) |
| Details | The summary as a level-3 heading, then the body |
| Card | Its content, unwrapped |
| Grid | A bullet list of the items |
| Button, arrow link | A plain link |
| Chip | Plain text |
| Numbered heading | The heading with the text `(n) ` in front |
| YouTube video | A paragraph with a link to the video (its title, else the watch URL) |

### 3.3 Publications

`Publication.markdownFlavor` (`gfm` | `wonky`, default `gfm`), set in the publication settings
(18 §5) and through the publication API. `/write/new?publication=…` creates the document in
that flavor; the submit dialog warns when the document's flavor differs from the
publication's (`SubmissionView.markdownFlavor`) and points to *File › Markdown flavor*. The
submission is exported in the document's flavor. The webhook's `submission.submitted` payload gains
`markdownFlavor` next to `markdown` (18 §7.1); `docs/blog-integration.md` documents it.

## 4. Syntax (Wonky flavor)

Exactly the blog's grammar (`serverpod_website_server/lib/src/markdown/markdown_renderer.dart`):

- Inline (anywhere inline Markdown is parsed, table cells and grid items included):
  `:button\[([^\]]*)\]\(([^)]*)\)(?:\{([^}]*)\})?`, `:link\[([^\]]*)\]\(([^)]*)\)`,
  `:chip\[([^\]]*)\](?:\{([^}]*)\})?`. Labels are plain text (not parsed as Markdown). Options
  are `{key=value key=value}`. URLs follow the link policy (02 §1.4 rule 9); an unsupported URL
  keeps the label as plain text with a warning.
- Block, each on its own line (leading/trailing spaces allowed), closed by a line that is only
  `:::`:
  - `:::(info|tip|note|warning|caution|danger)(\[title\])?`
  - `:::details`
  - `:::card`
  - `:::grid({columns=n bullets=b})?` — a space is allowed before `{`; only `- ` / `* ` lines
    count as items, other lines are dropped (warning).
  - Nesting: an opening line inside a block opens a nested block; `:::` inside a fenced code
    block is code. An unterminated block runs to the end of the document (warning).
- Numbered heading: `^(#{2,3})\s+\((\d+)\)\s+(.*)$`.
- YouTube video (a leaf directive of our own, not in the blog yet), on its own line:
  `^::youtube(\[title\])?(\s*\{options\})?\s*$` with options `id` (required; a YouTube link
  is accepted on import) and `start` (seconds or `1m30s`). The title is plain text. An invalid
  id keeps the line as text (warning). A text line starting with `::` is written as `\::`.
- Inside a block the content is parsed as a document (any block Markdown).

## 5. Markdown codec

### 5.1 Import

`ImportOptions.flavor` (`MarkdownFlavor.gfm` default). GFM import is unchanged: directives stay
literal text. Wonky import adds block syntaxes (callouts, details, card, grid, numbered
headings) and inline syntaxes (button, link, chip) to the `package:markdown` extension set and
maps their AST elements to the attributes of §2. Every importer entry point passes the
document's flavor: file import into an open document, *Paste as Markdown*, clipboard Markdown,
MCP `insert_markdown`/`set_markdown`, AI edits. *File › Import* of a `.md` file into a new
document creates a Wonky document when the file contains directives.

### 5.2 Export

`MarkdownExportOptions.flavor`. Wonky export writes §4 syntax:

- Blocks are separated by blank lines as today; a container writes its opening line, a blank
  line, its content, a blank line and `:::`. Nested containers indent nothing.
- Details: `:::details`, then the summary as `### …` (when present), then the body.
- Grid: `:::grid{columns=n bullets=b}` and one `- item` per item (an empty item is `- <!-- -->`
  like an empty nested list item, 02 §2.2).
- Numbered headings: `## (n) Title`.
- YouTube video: `::youtube[Title]{id=… start=…}` (title and start only when set).
- GFM export of a document with Wonky elements exports `WonkyToGfm.convert` of it.

### 5.3 Escaping

In both flavors (so a GFM document can be switched without changing meaning) the inline
writer escapes `:` as `\:` before `button[`, `link[` and `chip[`, and a line of text starting
with `:::` gets `\:::`. In Wonky export a heading whose text starts with `(digits) ` gets
`\(`. In labels `]` becomes `)` and a soft break a space (§2.1).

### 5.4 Round trip

The 02 §2.2 guarantee extends to Wonky export/import: `import(export(D, wonky), wonky) ==
normalize(D)` for valid deltas whose labels hold no `]`, with box and grid ids replayed through
`ImportOptions.idGenerator` (ids are not representable in Markdown) and grid items in canonical
inline Markdown. The property test generator produces boxes (nested), grids, steps, link
styles and chips. Limits, which follow from the blog's grammar and which the generator
respects: a details' summary is only its first line when that line is an H3, and it never has
a step (the blog reads `(n)` there as text); a code line or inline code span that starts a line
with ```` ``` ```` would end the blog's block scan early; two adjacent chips with the same icon
merge into one.

## 6. IR (07 §2.1)

- `InlineRun` gains `linkStyle` and `chip` (pure-Dart `wonky_rich_text`; Slides ignores them).
- `ContainerBlock(type, id, variant?, title?, children: [DocBlock])` — the IR nests; the
  builder groups lines by §2.2's run rule. `DetailsSummary` is the first child when it is a
  level-3 `HeadingBlock` (`ContainerBlock.summary`).
- `GridBlock(id, columns, bullets, items: [[InlineRun]], itemMarkdown)`.
- `HeadingBlock.step` (`int?`).

Every exporter handles `ContainerBlock` and `GridBlock` (the sealed class makes it a compile
error not to).

## 7. Editor

### 7.1 Mapping (02 §4)

- Every node carries the line's frames in metadata `wonkyBox` (absent = no container);
  `DeltaApplier`, `ChangeDeltaExtractor` and the mirror treat it as a block attribute.
- `step` is node metadata `wonkyStep` on heading paragraphs.
- `grid` maps to a `WonkyEmbedNode` (raw embed in `WonkyNodeMetadata.embed`), rendered by
  `WonkyGridComponentBuilder` and edited inline by `InlineGridEditing` (like tables, items in
  one tap region group: pressing another item moves the editing there without ending it first;
  the caret goes where the item was clicked, a double click selects a word and a triple click
  the text, the editor's
  selection color; the grid becomes the selection once the field has the focus; items opt out
  of the editor's own gestures, SE-14, like table cells).
- `WonkyBoxGuard` keeps `wonkyBox` on nodes that super_editor commands create or replace
  without copying metadata (a split, a block-type conversion): its `snapshot` reaction runs
  first in the pipeline and records the frames of the transaction's nodes from the mirror
  (which the change extractor's first checkpoint updates), its `restore` reaction runs last
  in both reaction phases and puts them back (a new node takes the frames of the node before
  it). Commands that move a node out of a container set `wonkyBox` themselves.
- `linkStyle` and `chip` map to `LinkStyleAttribution` and `ChipAttribution`; the attribution
  whitelist (04 §2.5) and the schema guard (04 §2.4) know them and their exclusions.

### 7.2 Rendering

All component builders wrap their component in the frames of its node
(`BoxFrameComponentBuilder`; `BoxStylePhase` moves the stylesheet padding inside the frames): for each frame, outermost first, the frame's background, side borders
and inner side padding; the first node of a container also draws the top border and the
header, the last one the bottom border and bottom padding. The stylesheet removes the vertical
block spacing between nodes of one container and the frame adds it inside, so a container is
one continuous box. Frames ignore pointers except their chrome (code-block rule, 04 §15.1).
Nothing a component paints is a hit target of its own (the pill painter, a video's thumbnail
and an image are not; `EditorBlockContent` reads double clicks from raw pointer events): the
editor's interactor lies below the document content, so a hit target there swallowed clicks,
and lines with a pill could not be clicked into. What a component reads from its node besides
its view model (a container's frames, a numbered heading's step, a code block's language)
changes no view model when it changes alone, so those parts are wrapped in
`EditorNodeWatcher`, which rebuilds them when the document changes the node (a callout's new
type or a new step number showed only after something else redrew the block).

| Element | Look (theme defaults, §8) | Chrome |
|---------|---------------------------|--------|
| Callout | Tinted box, 1 px border, radius 6; header row: type icon (Lucide set of the blog) + uppercase label (title or type label) | Header label: click opens the title popover (`write.box.editTitle`); icon: type picker (`write.box.setVariant`); hover ⋯ menu (§7.5) |
| Details | Bordered box, radius 12; the summary line in summary style with a chevron at the right; an empty summary shows the placeholder *Summary* | Chevron collapses/expands the body (§7.3); hover ⋯ menu |
| Card | Light gray rounded box with a soft shadow | Hover ⋯ menu |
| Grid | The real grid: `columns` columns (fewer under narrow content widths: ≥ 2 columns need 320 px, ≥ 3 need 480 px), each item with its bullet (check, circle or none) | Hover chrome just above the grid's top-right corner (in the overlay, so it never covers the first row): columns (1–4), bullets (check/circle/none), add item, ⋯ (delete grid). A selected grid shows no text selection toolbar |
| Button | Pill: accent fill with white text (primary), gray fill (secondary) | — (link popover, §7.4) |
| Arrow link | Accent, semibold, with a trailing ↗ | — |
| Chip | Rounded gray pill | — |
| Numbered heading | Accent circle with the number before the heading text | Badge: click opens a number field (`write.heading.setStepNumber`) |
| YouTube video | Its thumbnail (`i.ytimg.com/vi/<id>/hqdefault.jpg` through the image services, 16:9, rounded) with a dark play badge, the title centered below; not played in the editor | Hover chrome above it: Edit… (also double-click), Open on YouTube, ⋯ (delete); a click selects it |

Pills are painted per text component by `InlinePillComponentBuilder` (inside the frames, so
above a container's background and behind the text; a document-wide underlay layer would be
covered by the frame backgrounds), from the component's selection rectangles, one pill per
line. `PillSpacingStylePhase` adds a presentation-only `PillGapAttribution` (letter spacing,
never saved): 0.45 em after a pill's last character, 0.6 em on a space next to a pill and
1.05 em after an arrow link's last character, where its ↗ is painted; so neighbouring pills
never touch. Line heights inside callouts grow to fit button pills.

### 7.3 Details collapse

Collapsing is a per-user view state (not synced, not undoable, kept per document for the
session). In Editing and Suggesting mode details start expanded; in Viewing mode collapsed.
A collapsed body's nodes lay out at zero height. When the selection or a find match moves into
a collapsed body, it expands. Collapsing with the caret in the body moves it to the end of the
summary. A collapsed details is closed at its summary (bottom border and padding, without the
summary's own block spacing below it: as much room below the summary as above). The state
lives in the controller's `BoxFrameLayout` (`controller.boxFrames`). Print
and exports show details expanded (HTML: `<details open>`).

### 7.4 Editing behaviour

- **Wrap / unwrap.** Inserting a container with a selection wraps the selected lines (pushes a
  frame on each, max depth 3); with a caret in an empty paragraph it turns that line into the
  container's first line; otherwise it inserts a new line after the caret line. A new details
  gets a summary line (H3) and an empty body line, the caret in the summary.
- **Enter** in a container adds a line in the same container (the new line copies the
  frames). Enter on an **empty last line** of a container leaves the innermost container (pops
  a frame), like an empty quote line (04 §14). Shift+Enter is a soft break as usual.
- **Backspace** at the start of a container's first line pops its frame from that line
  (moves it out above). Deleting all lines of a container deletes it.
- Block-type changes (heading, list, quote, code) keep `box`.
- **Tab / Shift+Tab** indent lists as usual; they never change containers.
- Copy/paste copies frames; pasted containers get fresh ids (like embed ids).
- **Grid items:** Enter in an item adds an item after it; Backspace in an empty item removes
  it (the last one removes the grid); ↑↓←→ move between items in reading order and out of the
  grid at its ends; Tab/Shift+Tab move to the next/previous item. Inline formatting, links and
  chips work in items.
- **Link popover** (05 §9.1): in Wonky mode a *Style* segmented control (Link · Arrow link ·
  Button · Secondary). `write.link.setStyle {style}`.
- **Buttons from the toolbar/menu** on a selection without a link open the link popover with
  the style preset; on a caret they insert the label *Button* selected and open the popover.
- **Chip** toggles on a selection (`write.format.chip`); on a caret it toggles the typing
  attribute.
- **Numbered heading** (`write.heading.toggleStep`): on a paragraph it makes an H3; it sets
  `step` to the previous step in the section + 1 (section: since the last heading of a higher
  level than this one), 1 for the first. `write.heading.renumberSteps` renumbers the steps of
  the caret's section from 1. The outline panel shows `(n)` before step titles.
- **Markdown shortcuts** (04 §7.1, Wonky mode only, with *Markdown shortcuts* on): like the
  other block prefixes they trigger on the space typed after them at the start of a normal
  paragraph: `:::info `, `:::tip[Title] ` … `:::danger `, `:::details `, `:::card ` put the
  line in that container (inside the line's containers, max depth 3; a details' line becomes
  its H3 summary with an empty body line after it); `:::grid ` or
  `:::grid{columns=n bullets=b} ` inserts a grid before the line and puts the caret in its
  first item (like `write.insert.grid`; both go through `controller.gridEditing`). `(n) ` at the start of an
  H2/H3 (not a details summary) sets the step. Inline, `:chip[x]` on typing `]` and
  `:button[x](url)` / `:link[x](url)` (absolute URLs) on typing `)` convert; this reaction
  runs after auto-pair, so an overtyped closer converts too.
- **The end of a chip, button or arrow link** (`PillBoundary`): a caret there is *inside* by
  default, so typing extends the element (with its link); the caret is drawn right after the
  last glyph, not after the room for the pill's padding or the arrow (the last character's
  letter spacing; `PillBoundary.caretRect` through super_editor SE-12). → moves the caret
  *outside* without moving it (typing follows the element; the caret is drawn past the pill's
  edge or the arrow), ← moves it back inside (in a right-to-left block ← moves out and → back
  in); a click past the element's end, beyond its last character's box (right of it; left of it
  in a right-to-left block), puts the caret outside too (`PillBoundaryTapHandler`), and a click
  on the element's end puts it inside; a click splits the last character at its glyph's
  middle, not its box's, which includes that room (super_editor SE-13), and a click on what is
  under the pointer (a link to open, the link card) takes the character whose box holds the
  point (`DocumentGeometry.characterAt`), so the arrow belongs to its link; the link card also
  shows at the end of a button or arrow link while the caret is inside it (a one-character
  button can be edited); at the *start* of a chip or button after a space the caret (typed
  text goes before the element) is drawn before the pill, not on its first glyph; any other caret move ends the state. An element made by an
  inline shortcut or inserted through the link popover leaves the caret outside. Plain links
  still don't grow at their end (04 §10.3).
- **Link popover:** changing only the style of an existing link applies the style (the link
  itself is unchanged).
- **Suggesting mode:** wrapping/unwrapping, frame and step changes are block format
  suggestions (`before` holds the previous `box`/`step`); `linkStyle`/`chip` are inline format
  suggestions; grid edits are not suggestable (like tables).

### 7.5 Commands, menus, toolbar, slash menu

New commands (all undoable unless noted; *W* = enabled only in Wonky mode and hidden in GitHub
mode):

| Command | Args | Notes |
|---------|------|-------|
| `write.doc.setMarkdownFlavor` | `flavor` | §3.1–3.2 |
| `write.insert.callout` *W* | `variant` (default `info`) | |
| `write.insert.details` *W* | | |
| `write.insert.card` *W* | | |
| `write.insert.grid` *W* | `columns?` (3), `bullets?` (`check`) | Three empty items, caret in the first |
| `write.insert.youtube` *W* | `url`, `title?` | Without `url` (menus, toolbar, slash): a dialog asks for the link and title |
| `write.youtube.edit` *W* | `nodeId?`, `url?`, `title?` (empty removes it) | Without `url`/`title`: the dialog, prefilled |
| `write.youtube.open` *W* | `nodeId?` | Opens the watch page (external link confirmation, 04 §11.6); not undoable |
| `write.youtube.delete` *W* | `nodeId?` | |
| `write.box.setVariant` *W* | `variant` | Innermost callout at the caret |
| `write.box.editTitle` *W* | `title?` | Without `title`: inline title editor |
| `write.box.convert` *W* | `type` | callout ⇄ details ⇄ card (details gets/keeps a summary) |
| `write.box.unwrap` *W* | | Removes the innermost container, keeps its content |
| `write.box.delete` *W* | | Deletes the innermost container with its content |
| `write.details.toggleCollapsed` *W* | `nodeId?` | View state, not undoable |
| `write.grid.setColumns` / `setBullets` / `addItem` / `removeItem` *W* | | |
| `write.link.setStyle` *W* | `style`: `plain`\|`arrow`\|`button`\|`buttonSecondary` | |
| `write.insert.button` *W* | `variant?` | Opens the link popover |
| `write.format.chip` *W* | | Toggle |
| `write.heading.toggleStep` / `setStepNumber {n}` / `renumberSteps` *W* | | |

- **Toolbar:** in Wonky mode one `ToolbarDropdownButton` *Insert element* (icon
  `layout-template`, prio 2) after Table: Callout ▸ (Info, Tip, Note, Warning, Caution,
  Danger, each with its type icon: menus take a per-argument icon from `Command.iconFor`), Details, Card, Grid, ─, Button, Secondary button, Arrow link, Chip, ─, Numbered
  heading. The paragraph style dropdown gets *Numbered heading* under the headings.
- **Insert menu:** a Wonky group after Quote/Checklist: Callout ▸, Details, Card, Grid,
  YouTube video…, Button…, Arrow link…, Chip. The toolbar's *Insert element* has YouTube
  video… after Grid.
- **Format menu:** *Text ▸ Chip* (check); *Link ▸ Style ▸* (radio); *Paragraph styles ▸
  Numbered heading* (check), *Renumber steps*; *Container ▸* (when the caret is in one): type
  ▸ (callout variants radio), Edit title…, Change to ▸ Callout/Details/Card, Remove container
  (keep content), Delete container; *Grid ▸* (grid selected): Columns ▸ 1–4, Bullets ▸, Add
  item, Delete grid.
- **Context menu:** the Container, Grid and YouTube video items (Edit video…, Open on
  YouTube, Delete video) when applicable.
- **Chrome ⋯ menus** leave out what the block's own chrome offers (`chrome: true`): a grid's
  has Delete grid (columns, bullets and add item are buttons), a video's Delete video (Edit and
  Open are buttons), a container's no type or title (the callout header) and no
  expand/collapse (the details chevron); the context menu keeps everything.
- **Choices** (`EditorCommandSpec.radio`: callout type, container type, grid columns and
  bullets, link style): choosing the current one does nothing and succeeds. Likewise setting a
  value to what it is (a step number, a callout title, a video's link or title) succeeds
  without an edit instead of reporting *Not available here*.
- **Slash menu:** group *Wonky* (Wonky mode): Callout (`info`, `tip`, `note`, `warning`,
  `caution`, `danger`, `admonition`, `alert`), Details (`faq`, `toggle`, `collapsible`,
  `expandable`), Card (`box`, `panel`), Grid (`features`, `columns`, `checklist grid`), Button
  (`cta`), Arrow link (`link arrow`), Chip (`tag`, `pill`, `badge`), Numbered heading (`step`),
  YouTube video (`video`, `embed`, `movie`).

## 8. Themes (06 §2.4)

New elements, all optional with defaults in `BaseTheme` (dark variants derived, 06 §4):

| Element | Properties |
|---------|------------|
| `callout` | Block props (spaceBefore 6pt, spaceAfter 10pt, padding 12pt, borderRadius 6pt, borderWidth 1px), `titleCaseTransform` (uppercase), `titleSizeRatio` (0.75), `titleWeight` (600), per variant `{info, tip, note, warning, danger}` a `color` (`#0284c7`, `#059669`, `#6b7280`, `#d97706`, `#dc2626`; `caution` uses `warning`) from which the resolver mixes the background tint, border and title color in Oklab (dark variants mixed toward the dark page) |
| `details` | Block props (padding 14pt, background `@page`, border 1px `@border`, radius 9pt), `summaryWeight` (600), `chevronColor` (`@muted`) |
| `card` | Block props (background `@codeBg`, radius 9pt, padding 14pt 18pt), `shadow`: `none`\|`soft` (`soft`) |
| `grid` | Block spacing, `bulletColor` (`@accent`), `columnGap` (24pt), `rowGap` (9pt) |
| `button` | `background` (`@accent`), `color` (`@page`), `secondaryBackground` (`@muted`), `secondaryColor` (`@page`), `borderRadius` (6pt), `fontWeight` (600), and the arrow link's `arrowColor` (`@accent`) and `arrowWeight` (600) |
| `chip` | `background` (`@codeBg`), `color` (`@text`), `borderRadius` (200pt, the maximum), `fontWeight` (500) |
| `stepBadge` | `background` (`@accent`), `color` (`@page`), `sizeRatio` (1.1 × the heading's font size) |

The theme editor gets a *Wonky elements* group (shown for all documents); its sample
document is imported as Wonky Markdown and holds a numbered heading, a callout with a chip, a
button and an arrow link, a details block and a card with a grid. The CSS writer emits rules for the HTML export classes (§9).

## 9. Exports (07 §5)

| Format | Containers | Grid | Button / arrow link / chip | Numbered heading |
|--------|------------|------|-----------------------------|------------------|
| Markdown | §5.2 (GFM: §3.2) | | | |
| HTML, EPUB | `<div class="wonky-callout wonky-callout-warning">` with title row; `<details class="wonky-details" open>` + `<summary>`; `<div class="wonky-card">`; theme CSS | CSS grid, bullets as inline SVG | `<a class="wonky-button">`, `<a class="wonky-link">…↗`, `<span class="wonky-chip">` | Badge span |
| PDF / print | Nested frames: each block in a container carries the container's frame (background, side borders, rounded top on its first slice, bottom on its last; frames reach over the gaps between the children, so a container is one box across pages); callout header row with the Lucide icon (drawn as strokes) and the cased label; details: summary in the summary weight with a chevron at the right, body expanded; card: background and radius (no shadow); the content is laid out in the inner width | Rows of `columns` items (2 below 360 pt of width, 1 below 240 pt), check/circle bullets drawn in the bullet color; rows paginate like table rows | Chips and buttons: one pill per label behind the text (drawn before the line's text, a plain space added on each side), links active; arrow link: semibold accent text + `↗` (`→` or `>` when no font has the glyph) | Filled badge circle with the number before the text (the number is part of the bookmark title) |
| DOCX, ODT | Flattened: a callout's label as a bold first paragraph in its title color, a details summary as a bold paragraph; every paragraph-like block in a container gets the container's shading and (callouts, details) a left border; nested containers indent 12 pt per level. Headings inside containers are not in the ODT table of contents | A borderless table, one row per `columns` items, the bullet as a colored `✓`/`•` | Buttons and arrow links: bold hyperlinks; chips: shaded text in the chip colors | `n. ` before the heading text |
| RTF, TXT | Title line + content | Items as lines | Label (RTF: link) | `(n) ` prefix |

YouTube videos: Markdown §5.2 (GFM: a link, §3.2); HTML: the player, an `<iframe>` of
`https://www.youtube.com/embed/<id>?start=<s>` at full width and 16:9 (like the blog's posts);
EPUB, PDF / print, DOCX, ODT, RTF and TXT: a paragraph linking to the watch page
(`DocTree.withVideosAsLinks`, `YouTubeBlock.asLink`).

## 10. MCP and AI (09)

- `write.get_document` returns `markdown_flavor` and Markdown in the document's flavor;
  `write.insert_markdown`, `write.set_markdown`, `write.replace_range` with Markdown parse in
  the document's flavor. `write.set_markdown_flavor {flavor, convert?: true}` sets the flavor
  (converting per §3.2; `convert: false` fails with `hasWonkyContent` when there is content to
  convert).
- Tool descriptions mention that Wonky documents accept the directive syntax (§4). The AI
  system prompt (09 §5.7) adds a short Wonky syntax reference when the document's flavor is
  Wonky, and tells the model not to use directives in GitHub documents.
- `ui.write.*`: the new commands are callable through `ui.write.run_command`.

## 11. Acceptance criteria

**AC-WM.1** A GitHub document shows no Wonky items in menus, toolbar or slash menu. *File ›
Markdown flavor ▸ Wonky Markdown* shows them for every collaborator; undo switches back.
**AC-WM.2** In a Wonky document, *Insert ▸ Callout ▸ Warning* with three paragraphs selected
draws one warning box around them; typing the title "Heads up" in its header, then *Download ›
Markdown* gives `:::warning[Heads up]`, the three paragraphs and `:::`.
**AC-WM.3** Pasting the blog spec's examples as Markdown in a Wonky document renders every
element; exporting gives the same Markdown back (modulo blank lines).
**AC-WM.4** A details block collapses with its chevron, expands when the caret moves into it,
and Enter on its empty last line leaves it.
**AC-WM.5** A card holding a callout holding a list renders nested boxes; the list's numbering
is its own; export nests the directives.
**AC-WM.6** A 3-column check grid shows three columns; Enter in an item adds one; the columns
control switches to 2 columns; undo restores 3.
**AC-WM.7** Switching a Wonky document with elements to GitHub shows the conversion dialog;
confirming converts per §3.2 in one undo step.
**AC-WM.8** A submission to a Wonky publication sends Wonky Markdown and
`markdownFlavor: wonky`.
**AC-WM.9** Every element renders in light and dark, with every built-in theme, in the editor,
print preview, PDF and HTML export.

## 12. Tests

- Core: schema (validator/normalizer rules 10–13, idempotence, `normalizedChange` = whole
  normalization on random box documents), Markdown import/export golden tests for every blog
  example, nesting, unterminated blocks, escaping; the round-trip property test with Wonky
  generators; `WonkyToGfm` conversion; IR builder grouping; each exporter (smoke + HTML/PDF
  goldens).
- App: mapping round trip with boxes/steps/grids; widget tests for container rendering and
  chrome, Enter/Backspace in containers, details collapse, grid editing, link style popover,
  slash and shortcuts; menu visibility per flavor.
- Server: flavor meta change, copies, publication flavor, webhook payload, MCP tools.
