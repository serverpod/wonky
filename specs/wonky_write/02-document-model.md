# Write 02 · Document Model, Delta Schema and Markdown Mapping

The **canonical representation** of a Wonky Write document is a **Quill Delta** (document form:
inserts only) that conforms to the **Wonky Delta Schema v1** below. Every attribute in the schema
maps 1:1 to GitHub-Flavored Markdown (GFM) or to a non-printing collaboration overlay (comments,
suggestions). The editor (`super_editor`) is a *view* of this Delta; Markdown is the
import/export format. A document in the second flavor, **Wonky Markdown** (the Serverpod blog's
directives), adds the attributes and the `grid` embed of
[11-wonky-markdown.md](11-wonky-markdown.md) §2, which map 1:1 to that flavor.

Three representations, two converters each, all round-trip tested:

```
                 wonky_write_core (pure Dart)                    wonky_write (app)
 Markdown  ⇄  WonkyDelta (canonical)  ⇄  super_editor MutableDocument
   (MarkdownCodec)                          (DeltaDocumentMapper + DeltaApplier)
```

- `MarkdownCodec` (`wonky_write_core/lib/markdown/`): our own parser (on top of package
  `markdown`'s GFM block/inline syntaxes → AST → Delta) and serializer (Delta → Markdown with
  correct escaping). We do **not** use super_editor's Markdown serializer for persistence: it is
  Flutter-only (unusable on the server), drops code-fence languages, doesn't escape text, and has
  list/quote output issues.
- `DeltaDocumentMapper` (`wonky_write/lib/features/editor/mapping/`): full Delta →
  `MutableDocument` (initial load) and `MutableDocument` → Delta (for diffing). Upstream
  super_editor's Quill serializers throw on `HorizontalRuleNode`/`TableBlockNode` and drop
  inline `code` and list indents; since super_editor is **vendored** (suite
  [01 §2.3](../01-architecture.md)), we fix this in the library (patch **SE-1**,
  [04 §2.2](04-editor.md)) and build the mapper on its `toQuillDeltas` / parser with our schema
  formats. Until SE-1 lands, the mapper uses custom `DeltaSerializer`s / `BlockDeltaFormat`s.
- `DeltaApplier`: applies an **incremental** change Delta (from collaborators, undo, AI, MCP) to
  the live `MutableDocument` **without moving the local caret** (see sync spec). Upstream
  `applyToDocument` is not suitable (it only builds whole documents and routes edits through the
  composer), so patch **SE-2** adds an incremental, composer-free apply API to our vendored copy;
  `DeltaApplier` wraps it (and falls back to custom `EditCommand`s before SE-2 lands).

## 1. Wonky Delta Schema v1

A document Delta is a list of `insert` ops. Text is split into **lines**; each line ends with
`"\n"` whose attributes are the **block attributes** of that line. The document always ends with
`"\n"`. Allowed content:

### 1.1 Inline attributes (on text inserts)

| Attribute | Value | Markdown | Notes |
|-----------|-------|----------|-------|
| `bold` | `true` | `**x**` | |
| `italic` | `true` | `*x*` | |
| `strike` | `true` | `~~x~~` | GFM |
| `code` | `true` | `` `x` `` | Excludes all other inline attrs except `link`, `cmt_*`, `sug_*` |
| `link` | `String` (absolute URL, `mailto:`, or `wonky://` internal link) | `[x](url)` | Autolinks become `link` too |
| `mention` | `String` user UUID | `[@Name](mailto:email)` on export | Always paired with `link: "mailto:…"`; rendered as a chip |
| `cmt_<threadUuid>` | `true` | — (dropped on export) | Comment anchor; one key per thread so overlapping comments compose independently |
| `sug_<suggestionUuid>` | `{"t":"ins"\|"del"\|"fmt", "by":"<userUuid>", "at":<epochMs>, "before":{…}?, "via":"ai"\|"mcp"?}` | — (export applies "accepted" or "original" view, user's choice) | Suggestion mode; `before` holds prior inline attrs for `fmt` |

**Disallowed**: underline, color, background, font, size, script, align (not expressible in GFM).
Paste and import strip them.

Soft line break (Shift+Enter) is the character **U+2028** inside a line's text (export: hard
break `\` + newline; import: hard breaks → U+2028). Not allowed inside code blocks (code uses
real lines).

### 1.2 Block attributes (on `"\n"`)

| Attribute | Value | Markdown | super_editor node |
|-----------|-------|----------|-------------------|
| *(none)* | — | paragraph | `ParagraphNode` (blockType `paragraphAttribution`) |
| `header` | `1`–`6` | `#`…`######` | `ParagraphNode` (blockType `header1Attribution`…`header6Attribution`) |
| `blockquote` | `true` | `> ` | `ParagraphNode` (blockType `blockquoteAttribution`) — one node per line |
| `code-block` | `String` language (`""` = none) | fenced ```` ```lang ```` | **Consecutive** `code-block` lines with the same language ↔ **one** `ParagraphNode` (blockType `codeAttribution`) whose text contains `\n`; language stored in node metadata `codeLanguage` |
| `list` | `"bullet"` \| `"ordered"` | `- ` / `1. ` | `ListItemNode.unordered` / `.ordered` |
| `list` | `"checked"` \| `"unchecked"` | `- [x] ` / `- [ ] ` | `TaskNode(isComplete)` |
| `indent` | `1`–`8` | nested list (2/3-space indentation per level) | `ListItemNode.indent` / `TaskNode.indent`; **only valid with `list`** |
| `blockquote` + `list` | `true` next to a `list` value (+ `indent`) | `> - ` / `> 1. ` / `> - [ ] ` (a list inside a quote) | `ListItemNode` / `TaskNode` with node metadata `wonkyQuoted: true` (T-19) |

The line-end `"\n"` may additionally carry `cmt_*` and `sug_*` attributes (not block attributes):
`sug_<id>` with `t:"ins"`/`t:"del"` on a `"\n"` represents a suggested line split/merge, and
`t:"fmt"` with `before: {<previous block attrs>}` represents a suggested block-type change
(e.g. paragraph → heading); `cmt_*` on `"\n"` lets a comment span whole lines.

Combinations: `header`, `blockquote`, `code-block`, `list` are mutually exclusive, except
`blockquote` with `list`: a **list item inside a quote** (bullet, ordered or task, any indent;
`BlockFormat.quoted`). Consecutive quote lines and quoted list items form one quote. A quoted and
an unquoted list next to each other are two lists: an item's indent may be at most one deeper
than the previous list line's only when both are quoted or both are not (validator, normalizer
and the editor's schema guard), and ordered numbering restarts. Headings and code blocks can't
be in a quote; nested quotes are flattened to one level.

### 1.3 Block embeds

An embed is a single insert whose `insert` value is a map, always followed by a `"\n"` without
block attributes. The embed insert (and its `"\n"`) may carry only `cmt_*` and `sug_*`
attributes (suggested insertion/deletion of an image, divider or table; comments on them). Every embed has a stable `id` (UUIDv7) used for identity rules (§4.3).

| Embed | Value | Markdown | super_editor |
|-------|-------|----------|--------------|
| `image` | `{"id","src","alt","title"?}` — `src` is `wonky-file://<fileUuid>` (uploaded) or an `https://` URL | `![alt](src "title")` (export rewrites `wonky-file://` to a signed/public URL or to a relative path in zip exports) | `ImageNode` |
| `divider` | `{"id"}` | `---` | `HorizontalRuleNode` |
| `table` | **Legacy** ([12 §1.5](12-native-cells.md): read, upgraded by the server, never written) `{"id","align":[ "left"\|"center"\|"right"\|null, …], "rows":[[cellMarkdown,…],…]}` — row 0 is the header row; cells are **inline Markdown strings** | GFM table | `TableBlockNode` (read-only) |
| *(line attribute)* `cell` | `{"table", "row", "align"?}` on each cell's `"\n"`; a table is a run of cell lines, row 0 the header ([12 §1.1](12-native-cells.md)) | GFM table | `ParagraphNode` with `WonkyNodeMetadata.cell`, laid out in rows (SE-15) |

### 1.4 Constraints (validated on client before submit and on server after transform)

1. Document ends with `"\n"`; no empty inserts; adjacent inserts with equal attributes are merged
   (canonical form, so diffs and hashes are stable).
2. Embeds are followed by `"\n"` without attributes and preceded by `"\n"` or document start.
3. `code` inline excludes `bold/italic/strike`.
4. `indent` only with `list`; max 8; a list line's indent is at most the previous list line's
   indent + 1 within the same list run (the first item of a run has indent 0) — the same rule
   as the editor's Tab (04 §13.3); normalized by clamping.
5. Text characters: no control chars except `\n` (line end) and U+2028; no U+2029 (→ U+2028),
   U+FFFC (reserved for embeds in addressing text) or unpaired surrogates; tabs allowed only in
   code blocks (elsewhere converted to 4 spaces).
6. Max document length: 2,000,000 characters (config `write.maxDocumentChars`).
7. At most one embed per `id`.
8. Text of `code-block` lines carries no inline attributes (only `cmt_*`/`sug_*`); U+2028 in a
   code line becomes a real line end. Code languages match `[A-Za-z0-9_+#.-]{0,32}`.
9. Links are canonical URLs (schemes http, https, mailto, wonky, tel, ftp; percent-encoded like
   CommonMark link destinations) so they survive Markdown round trips; others are removed.

`WonkyDeltaValidator` and `WonkyDeltaNormalizer` live in `wonky_write_core` and are used by
client, server, importers and MCP tools.

## 2. Markdown codec

### 2.1 Import (Markdown → Delta)
- Parser: package `markdown` with GFM extension set (tables, strikethrough, task lists,
  autolinks, fenced code). Front matter (`---\n…\n---` at top) is preserved in
  `Document.frontMatter` (string) and re-emitted on export; it's not editable in the editor
  but visible/editable in *File › Document properties*.
- Unsupported constructs mapping:
  | Markdown | Result |
  |----------|--------|
  | Setext headings | `header` |
  | Inline HTML | stripped to text (except `<br>` → U+2028) |
  | HTML blocks | converted to text paragraphs (tags stripped) |
  | Nested blockquotes | flattened to one level |
  | Lists in quotes | quoted list items (`blockquote` + `list`, §1.2) |
  | Footnotes, math, definition lists | kept as literal text |
  | Reference-style links/images | resolved to inline |
  | Loose vs tight lists | both → list lines (export always tight) |
  | Ordered list start ≠ 1 | numbering restarts at 1 (notice) |
  | Images inside paragraphs | split: text before, image embed, text after |
- Import returns `ImportResult { delta, warnings: [ImportWarning(kind, line)] }`; warnings shown
  in a dismissible banner.

### 2.2 Export (Delta → Markdown)
- Escape Markdown-significant characters in text (`\ * _ ` # + - . ! [ ] ( ) < > | ~`) only where
  they would change meaning (context-aware escaping, CommonMark rules); inside code, no escaping
  and fence length chosen to exceed the longest backtick run.
- Lists: `-` for bullets, `1.` numbering incremented, 2 spaces per indent level for bullets, 3
  for ordered.
- Blockquote runs: consecutive `blockquote` lines → one `>` block, lines separated by `>` blank
  lines (paragraphs). Quoted list items are the list's Markdown behind `> ` in the same block:
  items of one list on consecutive lines, a `>` blank line between a paragraph and a list; a
  quoted and an unquoted block are always separated by a blank line (the quote ends).
- Code: ```` ```lang ```` fences.
- Tables: pipes escaped in cells, alignment row from `align`.
- Comments are dropped; suggestions are exported as *accepted* (default) or *original*
  (option).
- Line endings `\n`, trailing newline, no trailing spaces except none (hard breaks use `\`).
- Lossless encodings (implementation, `markdown_exporter.dart`): a soft break with no text after
  it on the line is written as `<br>`; a line whose content is only k plain soft breaks is
  written as k+1 `<br>` tags (an empty paragraph/quote line is `<br>`, an empty heading `# <br>`);
  empty list items are a bare marker at top level and `- <!-- -->` when nested (an empty item
  cannot interrupt the parent paragraph); leading/trailing whitespace is written as numeric
  character references; mentions are `[@Name](mailto:email "wonky-mention:<userUuid>")`; when
  CommonMark delimiter flanking rules cannot express the formatting, `_`-delimiters and finally
  `<strong>/<em>/<del>` tags are used (the importer maps those tags). Every block is verified by
  parsing it back.
- **Round-trip guarantee**: `import(export(D)) == normalize(D)` for any valid delta without
  `cmt_*`/`sug_*` (property test with random documents), up to embed ids (not representable in
  Markdown; the test replays them through `ImportOptions.idGenerator`) and with table cells in
  canonical inline Markdown (`InlineMarkdown.canonicalCell`).

## 3. Server data model (`wonky_server/lib/src/write/models/`)

```yaml
class: Document
table: document
fields:
  uuid: UuidValue                    # client may generate (UUIDv7) for offline creation
  itemId: int, relation(parent=drive_item, onDelete=Cascade)
  headRevision: int, default=0
  latestSnapshotRevision: int, default=0
  themeId: UuidValue?                # → WriteTheme.uuid (null = user's default theme at view time)
  pageSetupJson: String              # see export spec (size, orientation, margins, header/footer)
  language: String?                  # BCP-47 for spellcheck & hyphenation
  frontMatter: String?
  charCount: int, default=0
  wordCount: int, default=0
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  document_uuid_idx: { fields: uuid, unique: true }
  document_item_idx: { fields: itemId, unique: true }

class: DocumentOp
table: document_op
fields:
  documentId: int, relation(parent=document, onDelete=Cascade)
  revision: int                       # = head after applying this op (1-based)
  clientOpId: UuidValue               # idempotency key
  authorId: int?
  actorKind: ActorKind                # user, mcp, ai, system
  sessionId: String?                  # editing session (for presence attribution)
  kind: DocumentOpKind                # content, restore, imported, aiEdit, system (`import` is reserved in Serverpod)
  baseRevision: int                   # revision the client based the op on (diagnostics)
  deltaJson: String                   # transformed op as applied
  inverseJson: String                 # inverse against the pre-op doc (for revert/history)
  createdAt: DateTime
indexes:
  document_op_rev_idx: { fields: documentId, revision, unique: true }
  document_op_client_idx: { fields: documentId, clientOpId, unique: true }

class: DocumentSnapshot
table: document_snapshot
fields:
  documentId: int, relation(parent=document, onDelete=Cascade)
  revision: int
  deltaJson: String                    # full document delta at revision (gzip+base64 if > 64 KB)
  compressed: bool
  createdAt: DateTime
indexes:
  document_snapshot_idx: { fields: documentId, revision, unique: true }

class: DocumentMetaChange               # LWW metadata changes (title lives on DriveItem)
table: document_meta_change
fields:
  documentId: int, relation(parent=document, onDelete=Cascade)
  field: String                        # themeId, pageSetup, language, frontMatter
  beforeJson: String
  afterJson: String
  authorId: int?
  actorKind: ActorKind
  createdAt: DateTime
```

- Snapshots every 500 ops and at each `ItemVersion` capture. Ops older than 30 days are deleted
  except those needed between retained snapshots for version diffs (the version provider keeps
  snapshots at each version revision, so older ops can always be deleted). The daily prune
  (`DocumentService.pruneOps`, batches of 100 documents under a 5-minute budget) first writes a
  snapshot at the newest pruned revision, then deletes the snapshots below it except those at
  an `ItemVersion` revision. When version thinning deletes a version, its snapshot goes too
  (`WriteVersionProvider.discard`) unless another version shows that revision, it is the newest
  snapshot, or it is the base the oldest kept op is applied to.
- `WriteTheme` model: see themes spec.
- Images: uploaded via the platform `files` service (`StoredFile`, private cloud storage,
  owner = document item; access checked through document access), referenced as
  `wonky-file://<fileUuid>`; clients fetch through `FileEndpoint.getUrl(fileUuid)` (signed URL,
  cached).

## 4. Mapping details (Delta ⇄ super_editor)

### 4.1 Index model
Each Delta line maps to one node, except merged code lines:

| Node | Delta length |
|------|--------------|
| Paragraph/header/quote/list/task with text `t` | `len(t) + 1` |
| Code `ParagraphNode` with text containing k `\n` | `len(text) + 1` (each inner `\n` is a code-block line end) |
| Image / HR / (legacy) table node | `2` (embed + `\n`) |
| Table cell / grid item node | its text length + `1` (a line) |

`DeltaIndex` (in the Flutter mapper) maintains a prefix-sum structure (Fenwick tree keyed by
node order) for O(log n) conversions `int deltaOffset ⇄ DocumentPosition(nodeId, offset)`,
updated incrementally on every document change.

### 4.2 Attribution mapping
| Delta | super_editor attribution |
|-------|--------------------------|
| `bold` | `boldAttribution` |
| `italic` | `italicsAttribution` |
| `strike` | `strikethroughAttribution` |
| `code` | `codeAttribution` (inline) |
| `link` | `LinkAttribution.fromUri(Uri)` |
| `mention` | `MentionAttribution(userUuid)` (custom, + `LinkAttribution`) |
| `cmt_<id>` | `CommentAttribution(threadUuid)` (custom; `canMergeWith` compares ids) |
| `sug_<id>` | `SuggestionAttribution(id, type, authorUuid, at, before)` (custom) |

### 4.3 Embed identity rule
The server enforces "at most one embed per `id`": if a transformed incoming op would insert an
embed whose `id` already exists (e.g. two users replaced the same table concurrently: each op
deletes the old table and inserts a new one with the same `id`), the server rewrites the op to
also delete the existing embed with that `id` (last writer wins), and the rewrite is included in
the broadcast op. Clients never need special handling.

### 4.4 Local change → outgoing Delta
After each super_editor transaction (observed with an `EditListener`), the client computes the
change Delta. Two strategies, both implemented behind `ChangeDeltaExtractor`:
1. **Event mapping (fast path)**: `TextInsertionEvent`, `TextDeletedEvent`,
   `AttributionChangeEvent`, `NodeInsertedEvent`, `NodeRemovedEvent` mapped directly to Delta ops
   using `DeltaIndex`.
2. **Line diff (fallback)**: for `NodeChangeEvent` (block type/indent/task changes, which don't
   carry details) and anything not covered by (1): re-serialize only the affected node(s) to
   Delta lines and diff against the previous lines (`Delta.diff` on the affected slice).

A debug-mode invariant check after every transaction asserts
`fullDelta(doc) == previousFullDelta.compose(change)` (disabled in release; sampled 1% in
profile builds).

## 5. Derived data
- **Outline**: list of `{level, text, deltaOffset, nodeId}` from header lines (live-updated).
- **Stats**: words, characters (with/without spaces), paragraphs, pages (from the paginated
  layout), reading time; for selection too.
- **Plain text** (search index, AI context): Delta text with embeds rendered as `[image: alt]`,
  `---`, table as TSV.
