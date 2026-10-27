# Write 07 · Import, Export, Page Setup and Print

This spec defines how Wonky Write documents get **in** (Markdown, text, HTML, DOCX, ODT, RTF,
paste), how they get **out** (Markdown, PDF, HTML, DOCX, ODT, RTF, EPUB, text), the **page
setup** model, the shared **pagination engine** (used by PDF/print and by the editor's Pages
mode), and **print preview / printing**.

Related: canonical Delta schema and Markdown codec [02-document-model.md](02-document-model.md);
Wonky Markdown import/export and how every exporter renders its elements
[11-wonky-markdown.md](11-wonky-markdown.md) §5, §9;
themes [06-themes.md](06-themes.md) (every exporter renders through `ResolvedWriteTheme`);
editor Pages/Pageless rendering and paste handling [04-editor.md](04-editor.md); menus
[05-screens-menus-toolbar.md](05-screens-menus-toolbar.md); drive import/export
[../05-drive-and-files.md](../05-drive-and-files.md); MCP
[../09-mcp.md](../09-mcp.md) (`drive.export`, `drive.import`).

---

## 1. Principles

1. **One implementation, two runtimes.** Importers, exporters, the pagination engine and the
   document IR live in **pure Dart** in `wonky_write_core` (no Flutter), so they run on the
   **server** (MCP `drive.export`, large files, server-side imports) and on the **client**
   (offline export, paste, drag-and-drop, quick exports). Fonts and images are passed in through
   interfaces (`FontProvider`, `ImageResolver`), never loaded via Flutter APIs inside core.
2. **Theme fidelity.** Every exporter renders through the document's resolved theme
   ([06-themes.md](06-themes.md) §7); light variant by default, *Use dark theme* optional.
3. **Markdown subset in, Markdown subset out.** Importers reduce rich formats to the Wonky
   Delta Schema v1 and **report** what they dropped (`ImportWarning`s → banner). Exporters never
   invent styling that isn't in the theme.
4. **Single window.** Downloads use the browser download mechanism (web) or a native save
   dialog (desktop); print preview is an in-app route; printing uses the system print dialog.
5. **Deterministic output.** Same input (delta, revision, theme hash, page setup, options,
   fonts) → byte-identical output (fixed timestamps from `meta.modifiedAt` unless the format
   requires "now"; stable ids; sorted zip entries). Enables caching and golden tests.

---

## 2. Core architecture (`wonky_write_core`)

### 2.1 Document IR (`lib/ir/`)

All importers produce, and all exporters consume, a **block tree** (`DocTree`) instead of
re-parsing Deltas/Markdown in each format:

```dart
final class DocTree { final List<DocBlock> blocks; final DocMeta meta; }

sealed class DocBlock { final int deltaStart; final int deltaLength; }  // offsets for mapping (export only)
final class ParagraphBlock extends DocBlock { final List<InlineRun> runs; }
final class HeadingBlock   extends DocBlock { final int level; final List<InlineRun> runs; final String anchorId; }
final class ListItemBlock  extends DocBlock { final ListKind kind; /* bullet|ordered */ final int indent; final int ordinal; final List<InlineRun> runs; }
final class TaskBlock      extends DocBlock { final bool checked; final int indent; final List<InlineRun> runs; }
final class QuoteBlock     extends DocBlock { final List<List<InlineRun>> lines; }          // consecutive quote lines
final class CodeBlock      extends DocBlock { final String language; final String text; }  // merged code lines
final class ImageBlock     extends DocBlock { final String id, src, alt; final String? title; }
final class RuleBlock      extends DocBlock { final String id; }
final class TableBlock     extends DocBlock { final String id; final List<CellAlign?> align; final List<List<List<InlineRun>>> rows; }

final class InlineRun {
  final String text;               // may contain U+2028 (soft break)
  final bool bold, italic, strike, code;
  final String? link;
  final String? mentionUserUuid;
}
```

- `DocTreeBuilder.fromDelta(Delta d, {SuggestionView view = accepted})` — applies the suggestion
  view (accepted: drop `t:del` text, keep `t:ins`; `fmt` keeps current attrs. original: drop
  `t:ins`, keep `t:del`, `fmt` restores `before`), strips `cmt_*`, computes list ordinals (per
  list run and indent level, restarting after a non-list block) and heading anchor ids
  (`h-<slug>-<n>`, unique).
- `DocTreeToDelta.convert(DocTree)` → Delta, followed by `WonkyDeltaNormalizer` +
  `WonkyDeltaValidator` (importers must yield valid deltas).
- `MarkdownCodec` ([02](02-document-model.md) §2) remains the canonical Markdown path; it is
  implemented on top of the IR too, so `md → IR → delta` and `delta → IR → md` share code.

### 2.2 Interfaces

```dart
enum ExportFormat { markdown, markdownZip, pdf, html, htmlZip, docx, odt, rtf, epub, txt }
enum ImportFormat { markdown, txt, html, docx, odt, rtf }

final class ExportInput {
  final Delta document;            // canonical document delta at `revision`
  final int revision;
  final DocMeta meta;              // documentUuid, title, authorName, language, frontMatter, createdAt, modifiedAt
  final WriteThemeData theme;
  final ThemeVariant variant;      // light unless "Use dark theme"
  final PageSetup pageSetup;       // §6
  final ImageResolver images;
  final FontProvider fonts;        // 06-themes §8.3
  final LinkResolver links;        // wonky://doc/<uuid>#slug → https://<host>/write/d/<uuid>#slug (same doc → internal anchor);
                                   // wonky://sheet/<uuid> → https://<host>/sheets/s/<uuid>; wonky-file:// handled by images
  final String locale;             // date formatting in headers/footers
  final DateTime now;              // injected for {date}
  final ExportProgressSink? progress;
  final CancellationToken? cancel;
}

abstract interface class ImageResolver {
  /// Bytes + intrinsic size for `wonky-file://<uuid>` or `https://…` sources.
  /// Returns null if unavailable (exporters render an "[Image: alt]" placeholder + warning).
  Future<ResolvedImage?> resolve(String src);
}
final class ResolvedImage { final Uint8List bytes; final String mime; final int widthPx, heightPx; }

abstract interface class DocumentExporter<O extends ExportOptions> {
  ExportFormat get format;
  Future<ExportArtifact> export(ExportInput input, O options);
}
final class ExportArtifact {
  final String fileName; final String mimeType; final Uint8List bytes;
  final int? pageCount; final List<ExportWarning> warnings;
}

abstract interface class DocumentImporter {
  ImportFormat get format;
  Future<ImportResult> import(Uint8List bytes, ImportOptions options);
}
final class ImportResult {                      // extends 02-document-model §2.1 ImportResult
  final Delta delta;                            // images reference "import-image://<tempId>"
  final List<ImportWarning> warnings;           // kind, message, location (line/paragraph index)
  final String? title;                          // suggested title (front matter, docProps, <title>, first H1)
  final String? frontMatter;
  final String? language;
  final List<ImportedImage> images;             // tempId, bytes, mime, alt
}
```

`ImportPostProcessor` (runs where the importer ran) uploads `ImportedImage`s to the files service
and rewrites `import-image://<tempId>` → `wonky-file://<fileUuid>` (or keeps `https://` sources),
then validates.

### 2.3 Package layout

```
wonky_write_core/lib/
  ir/            doc_tree.dart, doc_tree_builder.dart, doc_tree_to_delta.dart, ordinals.dart, anchors.dart
  import/        markdown_importer.dart, txt_importer.dart, html/ (html_importer.dart, google_docs.dart, ms_word_html.dart),
                 docx/ (docx_importer.dart, ooxml_reader.dart), odt/, rtf/ (rtf_tokenizer.dart, rtf_importer.dart),
                 encoding.dart (BOM/UTF-16/Windows-1252 detection), import_post_processor.dart
  export/        markdown_exporter.dart, txt_exporter.dart, html_exporter.dart, pdf/ (pdf_exporter.dart,
                 wonky_paragraph.dart (adapted pw.RichText exposing line metrics), pdf_measurer.dart, toc.dart),
                 docx/ (ooxml_writer.dart, styles_xml.dart, numbering_xml.dart, document_xml.dart),
                 odt/, rtf/, epub/ (opf.dart, nav.dart, xhtml_writer.dart), zip.dart (deterministic zips)
  layout/        page_setup.dart, pagination_engine.dart, block_metrics.dart, header_footer_tokens.dart
  highlight/     (`SyntaxHighlighter`: the exporters' cached front for `wonky_code`'s
                 `DefaultCodeTokenizer` — the editor's and Slides' tokenizer, Write 04 §15.5;
                 06-themes §2.5)
```

New pure-Dart dependencies for `wonky_write_core` (add to the dependency rules in
[../01-architecture.md](../01-architecture.md) §2.1): `html` (HTML5 parser),
`image` (decode WebP/GIF/BMP → PNG, read dimensions), `crypto` (hashes), and — only if the spike in
§5.5 passes — `docx_creator`.

---

## 3. Import

### 3.1 Entry points

| Entry point | Where it runs | Result |
|-------------|---------------|--------|
| Drive *New ▸ Upload file…* / drag files onto drive list / *File › Import…* | **Server** (`DriveEndpoint.import`) | New document |
| *File › Import into this document…* / drag a file onto the editor | **Client** if ≤ 5 MB and online-or-offline; otherwise server (`WriteExportEndpoint.convertForInsert`) | Inserted at caret as **one op** (`kind: import`) = one undo step "Import file" |
| Paste (`Mod+V`) | Client (see [04-editor.md](04-editor.md) for clipboard priority) | Inserted at caret; one undo step "Paste" |
| MCP `drive.import` | Server | New document |
| Offline *Upload file* | Client import → document created offline ([../12-offline-and-sync.md](../12-offline-and-sync.md) §1.2) with the imported delta as its first pending op | New document |

Limits: client imports ≤ 5 MB input and ≤ 200k resulting characters (else server); server ≤ 50
MB input, result ≤ `write.maxDocumentChars` (2M) — else `ImportTooLarge` error with a message
suggesting splitting. ZIP-based inputs (DOCX, ODT, Markdown zip) are also limited before any
part is inflated (zip bombs, `ArchiveLimits`): ≤ 10,000 entries and ≤ 200 MB declared
uncompressed size in total, else `ImportTooLarge` ("The file is too large to import…"); a part
never inflates past the size its directory declares. Server imports run in their own isolate
(`WriteImportService.runKillable`) that is killed after 60 s.

### 3.2 Server pipeline

1. Client uploads the file via the files service (upload description → direct cloud-storage
   upload → `StoredFile(kind: importSource, expires 24 h)`).
2. `DriveEndpoint.import(uploadId, kind: document, options)` — `options`: `{format?: auto,
   name?, parentUuid?, txt: {lineBreaks}, html: {downloadRemoteImages}, docx: {…}}`. Format is
   detected by extension, then sniffed (ZIP + `[Content_Types].xml` → DOCX; ZIP + `mimetype`
   `application/vnd.oasis.opendocument.text` → ODT; `{\rtf` → RTF; `<html`/`<!doctype html` →
   HTML; else text/Markdown by extension, default Markdown).
3. Importer → `ImportResult`; post-processor uploads images (owner = the new document item).
4. Creates `DriveItem` + `Document` with `frontMatter`, `language`, initial `DocumentOp`
   (revision 1, `kind: import`, `actorKind` of caller) and a snapshot at revision 1.
5. Returns `ImportReportView {item, warnings[]}`; warnings are also stored for 7 days and shown
   as a dismissible banner the first time the importing user opens the document ("3 elements
   couldn't be imported exactly — *Details*").
6. `ActivityEvent(created)` with summary `{importedFrom: "docx"}`.

### 3.3 Markdown (`.md`, `.markdown`, `.mdown`, `.mkd`)

Per [02](02-document-model.md) §2.1 (front matter preserved; unsupported constructs mapped as
listed there). Additions:
- Title: front matter `title` → first H1 text → file name without extension. The H1 stays in
  the content.
- Relative image paths: in a **zip** import (`.zip` containing one `.md` + assets, as produced by
  our *Markdown + images* export) images are resolved from the archive and uploaded; otherwise
  relative images become a placeholder paragraph `[image: alt (path)]` + warning.
- Encoding: UTF-8 (BOM stripped), UTF-16 LE/BE by BOM; invalid UTF-8 → decode as Windows-1252 +
  warning.

### 3.4 Plain text (`.txt`, `.text`, unknown text)

- Option `lineBreaks: "paragraph" (default) | "soft"`: each line → paragraph, or blank-line
  separated blocks → paragraphs with single breaks → U+2028.
- Tabs → 4 spaces; control chars removed; CRLF/CR → LF.
- No Markdown interpretation (that's what `.md` is for). *Import as Markdown* toggle in the
  upload options dialog for `.txt` files that look like Markdown (≥ 3 of: `#` headings, `- `
  lists, fenced code, `**`, `[x](y)`).

### 3.5 HTML (`.html`, `.htm`; also clipboard HTML)

Parser: package `html` (spec-compliant HTML5 tree). `HtmlImporter` walks the DOM with a block
context stack:

| HTML | Result |
|------|--------|
| `h1`–`h6` | `header` 1–6 |
| `p`, `div`, `section`, `article`, `header`, `footer`, `li > p` | paragraph boundaries (no empty paragraphs from wrappers) |
| `br` | U+2028 (in code: newline) |
| `strong`, `b`, `[style*=font-weight:(bold\|[6-9]00)]` | `bold` |
| `em`, `i`, `cite`, `[style*=font-style:italic]` | `italic` |
| `s`, `del`, `strike`, `[style*=line-through]` | `strike` |
| `code`, `kbd`, `samp`, `tt` (inline) | `code` |
| `pre` (optionally with `code.language-xx` / `lang-xx` / `data-lang`) | `code-block` with language |
| `a[href]` | `link` (absolute http(s)/mailto only; relative resolved against `<base>`/source URL when known, else dropped + warning; `javascript:` dropped) |
| `img` | image embed (`data:` URIs → uploaded; `http(s)` kept as remote `src`, or downloaded when `downloadRemoteImages` (server only, SSRF-safe fetcher: https only, public IPs, ≤ 10 MB, 15 s)) |
| `ul`/`ol`/`li` (nested) | `list` bullet/ordered with `indent` = nesting depth (max 8; deeper flattened) |
| `li` starting with `input[type=checkbox]` or `☐/☑/☒` | `list: checked/unchecked` |
| `blockquote` (nested) | `blockquote` (flattened to one level; lists inside → quoted list items, `blockquote` + `list`, 02 §1.2) |
| `hr` | divider |
| `table` | table embed: `thead`/`th` row or first row = header; `colspan`/`rowspan` → content in first cell, others empty (warning); nested tables → text; `align`/`text-align` → column align |
| `figure > img + figcaption` | image with `title` = caption text |
| `u`, `mark`, `sup`, `sub`, `small`, `span`, `font`, colors, fonts | text only (dropped formatting; counted in one aggregated warning) |
| `script`, `style`, `iframe`, `object`, `embed`, `form`, `input` (other), `svg`, `canvas`, comments | dropped |

Source-specific normalizers (detected by markers):
- **Google Docs** (`id="docs-internal-guid-…"`): ignore the `<b style="font-weight:normal">`
  wrapper; map `span` styles (`font-weight:700`, `font-style:italic`,
  `text-decoration:line-through`, monospace `font-family` → `code`); lists use `aria-level`.
- **Microsoft Word HTML** (`xmlns:w`, `class=Mso…`): `MsoListParagraph*` + `mso-list:lN levelM`
  → lists (bullet vs. ordered from the `mso-list` ignore span text); `MsoHeadingN`/`MsoTitle` →
  headings; strip conditional comments.
- **super_editor / Wonky** own HTML (from our exporter): round-trips exactly (classes
  `wonky-*`).

### 3.6 DOCX (`.docx`)

Reader: `OoxmlReader` (archive + xml) unless `docx_creator`'s reader passes the spike (§5.5).
Reads `word/document.xml`, `styles.xml` (style inheritance via `w:basedOn`), `numbering.xml`,
`_rels`, `media/`, `docProps/core.xml` (title, creator, language).

| DOCX | Result |
|------|--------|
| Paragraph style `Heading1…6` / `Title` (→ H1) / `Subtitle` (→ H2) / any style with `w:outlineLvl` 0–5 | `header` |
| `Quote`, `IntenseQuote`, styles with left border + indent named *quote* | `blockquote` |
| Paragraph whose runs are all monospace (font in mono list: Courier*, Consolas, Menlo, *Mono*, Source Code Pro…) or style `HTMLPreformatted`/`Code*` | `code-block` (consecutive paragraphs merged; language `""`) |
| `w:numPr` (`numId`, `ilvl`) | list; `numFmt` `bullet` → bullet, others → ordered; `ilvl` → `indent`; restarts/starts ≠ 1 → numbering restarts at 1 (warning) |
| Leading `☐`/`☒`/`☑` glyph or `w14:checkbox` content control | task list item |
| Run `w:b`, `w:i`, `w:strike`/`w:dstrike` (incl. via char style) | `bold`, `italic`, `strike` |
| Run in monospace font | `code` |
| `w:hyperlink` (r:id external) / `HYPERLINK` field | `link`; internal bookmarks → text only |
| `w:drawing` inline/anchor `a:blip` | image embed (alt from `wp:docPr/@descr`, title from `@title`); TIFF and BMP → PNG; EMF/WMF → placeholder + warning; anchored/floating images → inline at paragraph position |
| `w:tbl` | table embed (cells → inline Markdown; multi-paragraph cells joined with U+2028 → exported `<br>`-free as spaces, warning; merged cells (`gridSpan`/`vMerge`) → first cell; nested tables → text) |
| `w:br w:type=page`, section breaks, columns | dropped (warning once) |
| `w:br` (text wrapping) | U+2028 |
| Footnotes/endnotes | appended as a final "Notes" section: references become `[1]` text, notes as ordered list (warning) |
| Comments (`comments.xml`) | dropped in v1 (warning); P2: imported as comment threads (author name quoted in body) |
| Tracked changes (`w:ins`/`w:del`) | accepted (`w:del` dropped, `w:ins` kept) (warning); P2 option: import as suggestions |
| Text boxes, shapes, SmartArt, charts, equations (`m:oMath`) | text content if any, else `[equation]`/`[chart]` placeholder (warning) |
| Underline, colors, highlight, fonts, sizes, alignment, indents, spacing | dropped (aggregated warning "Formatting not supported in Markdown was removed") |
| Headers/footers | dropped (warning); page size/orientation/margins → **page setup** of the new document |
| `docProps/core.xml` title / `dc:language` | title / `Document.language` |

### 3.7 ODT (`.odt`) — P2

`content.xml` + `styles.xml`: `text:h` (`text:outline-level`) → headings; `text:p` style
resolution through `style:parent-style-name` (`Quotations` → quote, `Preformatted_20_Text` →
code); `text:list` nesting → lists (`text:list-level-style-bullet|number`); `text:span` automatic
styles (`fo:font-weight=bold`, `fo:font-style=italic`, `style:text-line-through-style≠none`,
monospace `style:font-name`) → inline attrs; `text:a` → link; `draw:frame/draw:image`
(`Pictures/…`) → image; `table:table` → table; `text:line-break` → U+2028; `text:s`/`text:tab`
→ spaces. Same warning policy as DOCX.

### 3.8 RTF (`.rtf`) — P2

`RtfTokenizer` (control words, symbols, groups, `\binN`, `\'hh` with `\ansicpgN` code pages —
built-in tables for 1250–1258, 437, 850; `\uN` with `\ucN` skip) → `RtfImporter` with a
character/paragraph state stack: `\b \i \strike \striked1`, `\par` (paragraph), `\line` (U+2028),
stylesheet names `heading N` → headings, `\outlinelevelN` → headings, `\pntext`/`\listtext` +
`\ls`/`\ilvl` → lists, `\field{\*\fldinst HYPERLINK "…"}` → link, `\pict` (`\pngblip`,
`\jpegblip`; others → placeholder) → image, `\trowd … \cell \row` → tables, monospace fonts →
code. Unknown destinations `{\* …}` skipped.

### 3.9 Paste-import

Clipboard handling lives in the editor ([04-editor.md](04-editor.md)); it uses these importers:
internal Wonky format (`application/x-wonky-delta+json`, a Delta slice; `cmt_*`/`sug_*` stripped)
→ HTML (`HtmlImporter`, with Google Docs/Word normalizers) → plain text (Markdown-detected when
the *Paste Markdown as formatted text* preference is on; otherwise `TxtImporter` soft mode).
`Mod+Shift+V` always uses plain text. Pasted images (`super_clipboard` PNG/JPEG data) are
uploaded and inserted as image embeds (placeholder while uploading; offline: kept as a local
pending upload, inserted with a `wonky-file://` UUID reserved client-side and uploaded on
reconnect).

---

## 4. Export — common behavior

### 4.1 Options common to all formats

| Option | Values | Default |
|--------|--------|---------|
| `suggestions` | `accepted` \| `original` | `accepted` |
| `variant` | `light` \| `dark` | `light` (formats without colors ignore it) |
| `revision` | int (export an older version from history) | head |
| `fileName` | string (sanitized: no `/\:*?"<>|`, ≤ 120 chars) | document title |

Comments are never exported in v1 (P2: DOCX/ODT native comments; PDF/HTML "comments as
endnotes").

### 4.2 Per-format options

| Format | Options |
|--------|---------|
| Markdown (`.md`) | `images: "signedUrl" \| "wonkyLink" \| "omit"` (default `signedUrl`, 7-day signed URLs, warning about expiry), `frontMatter: bool` (true) |
| Markdown + images (`.zip`) | `document.md` + `images/<n>-<slug>.<ext>`; relative paths; front matter |
| PDF | `includeToc: bool` (false), `tocDepth: 1–6` (3), `bookmarks: bool` (true), `pageRange: "all" \| "1-3,5"`, `headerFooter: bool` (true), `pageBackground: bool` (false unless paper color ≠ white or dark variant) |
| HTML (`.html`) | `embedImages: bool` (true → data URIs), `embedFonts: bool` (false → CSS font stack with fallbacks), `includeDarkMode: bool` (true), `includeToc: bool` (false) |
| Web page (`.zip`) | `index.html` + `images/` + `fonts/` (embedFonts default true) + `style.css` |
| DOCX | `includeToc: bool` (false; inserts a TOC field Word updates on open), `embedFonts: bool` (false, P2) |
| ODT | `includeToc` |
| RTF | — |
| EPUB | `chapterSplit: "h1" \| "h2" \| "none"` (`h1`), `cover: "auto" \| "none" \| {imageFileUuid}` (`auto`), `embedFonts: bool` (true), `useThemeColors: bool` (false — let readers control colors), `author` (owner display name or front matter `author`) |
| Plain text | `lineEndings: "lf" \| "crlf"` (lf), `wrapColumn: 0 \| 72 \| 80` (0), `tables: "tsv" \| "aligned"` (`aligned`) |

Last-used options per format are stored in `UserPreferences.writeDefaults.exportOptions[format]`.

### 4.3 Where exports run

| Situation | Runs on |
|-----------|---------|
| Offline | Client (always) |
| Online, ≤ 50 pages estimated (≈ 25k words) or text formats | Client |
| Online, larger | Server (`WriteExportEndpoint.exportWithProgress`), downloaded via signed URL |
| MCP `drive.export`, AI | Server |
| Exporting an older `revision` | Server (needs materialization) unless the version is cached locally |

> Implementation note (iteration 1): the app exports every format on the client regardless of
> size (File › Download lists all ten formats); the server path is used by MCP and is available
> through `writeExport.export`. File › Import / *Upload file…* go through the server pipeline
> (`drive.import`, images stored with the new document, import banner on first open) when online
> and convert on the client when offline; *Insert from file…* converts on the client and uploads
> embedded images as files of the current document.

Client: desktop runs exporters in `Isolate.run` (fonts/images pre-resolved and passed as bytes);
web runs on the main isolate in cooperative chunks (`await` a zero-delay future between blocks
and pages) behind a progress dialog with *Cancel*. As built (W-07, CQ-44): every client export
runs on the main isolate (no `Isolate.run` yet) with an `ExportYielder` in its `ExportInput`;
the PDF exporter gives the event loop a turn at most every 12 ms between blocks (line
breaking) and pages, then checks the `CancellationToken`. *File › Download* shows a progress
toast (layout progress) with *Cancel*; a cancelled export closes it without an error. Server
exports pass no yielder and stay synchronous; the bytes are the same with or without one. The
other exporters still report progress only between phases. Threshold is configurable
(`write.export.clientMaxPages`). Same code + same fonts ⇒ identical bytes on both sides
(verified by a test that hashes client vs. server output for the corpus).

### 4.4 Image handling in exports

`ImageResolver` implementations: **server** reads `StoredFile` bytes directly (access already
checked on the document) and fetches remote `https` images with the SSRF-safe fetcher (cached 1
h); **client** uses the image cache / signed URL fetch; on web, remote images blocked by CORS fall
back to the server proxy `WriteExportEndpoint.fetchImage(documentUuid, src)` when online, else a
placeholder box with alt text (+ warning). Both resolvers pass PNG/JPEG/GIF/WebP through as they are
(`describeExportImage`, header only; images of documents are WebP, suite 12 §1.1): Markdown
(`images/<n>-<slug>.webp`) and HTML keep them, DOCX/ODT/RTF/EPUB convert to PNG/JPEG
(`prepareOfficeImage`: opaque lossy WebP → JPEG q 90, other WebP → PNG) and PDF decodes them (`image` package). Only other formats (SVG, AVIF of
`https` images) are re-encoded to PNG by the client (Flutter); never WebP, because Flutter web's
`toByteData(format: png)` can put the image on a larger transparent canvas;
SVG: PDF uses `pw.SvgImage`, DOCX/ODT/RTF rasterize to PNG at 2× (P2; v1 placeholder + warning).
Images are downscaled to ≤ 2400 px on the long side for PDF/DOCX/EPUB (option *Keep original
resolution*).

---

## 5. Export formats

### 5.1 Markdown / Markdown + images

`MarkdownCodec.export` ([02](02-document-model.md) §2.2) + suggestion view + image rewriting.
Mentions export as `[@Name](mailto:email)`. Internal links `wonky://doc/<uuid>[#slug]` → absolute
`https://<host>/write/d/<uuid>[#slug]`; links to headings of the same document → `#slug`. Theme-level heading numbering is **not** emitted (presentation
only).

### 5.2 PDF (`pdf` 3.13.x)

> Implementation note: `PdfExporter` (`wonky_write_core/lib/src/export/pdf/`) renders with the
> low-level `pdf` API (`PdfDocument`/`PdfGraphics`) and its own line breaker (`PdfLineBreaker`,
> glyph metrics + per-character font fallback), so measured lines are exactly the drawn lines;
> no adapted `pw.RichText` is needed. Missing families fall back to the standard PDF fonts with a
> `font_fallback` warning. Ids and dates are deterministic (PDF 1.4, document id from
> uuid/revision/theme hash, dates from `meta.modifiedAt`).

- Built with our **pagination engine** (§7) and a custom page builder (not `pw.MultiPage`, which
  lacks keep-with-next and widow/orphan control): each laid-out page becomes one `pw.Page` whose
  content is a `pw.Stack`/`pw.Column` of placed block slices.
- Text: `WonkyParagraph` — an adapted copy of `pw.RichText` (Apache-2.0, attribution kept)
  that exposes line breaks/heights for measurement and can render a line range `[from, to)`.
  Inline runs map to `pw.TextSpan` (font face per bold/italic/code, decorations, link
  annotations). Justification via `TextAlign.justify` (last line left).
- Fonts: faces from `FontProvider` via `pw.Font.ttf`; fallback chain per run for missing glyphs
  (`pw.TextStyle.fontFallback`), emoji via Noto Emoji (monochrome).
- **Bookmarks/outline**: `pw.Outline` per heading (level = heading level) when `bookmarks`.
- **Links**: `pw.UrlLink` for external; internal heading links / TOC entries use `pw.Link` to
  `pw.Anchor(name: anchorId)`.
- **TOC**: optional; generated after a first layout pass (to know heading page numbers),
  inserted after the title block (first H1 if it's the first block, else at the start); layout is
  repeated until page numbers are stable (max 3 passes). TOC entries: indented by level, dot
  leaders, right-aligned page numbers, clickable.
- Header/footer: rendered from page setup slots (§6.3) with theme `header`/`footer` typography;
  `{page}`/`{pages}` use the logical numbering (start value, format).
- Images: `pw.MemoryImage`, scaled to fit content width × min(theme maxWidth, 100 %) and page
  content height; border radius via `pw.ClipRRect`; shadow approximated with an offset blurred
  rect (`soft`/`strong`); caption below.
- Code blocks: background box per page slice (rounded corners only on the true start/end
  slices), highlighted token spans, long lines wrap with a `↪` continuation marker in `muted`.
  Wrapping ignores the token runs (a word continues across syntax tokens), so a line wraps at
  the same spaces whatever the highlighting (SL-35).
- Tables: our table layout (column widths: proportional to max content width, min 2 em, capped
  to content width), header row repeated on each continuation page.
- Task checkboxes drawn as vector boxes/checkmarks (theme `task.checkbox`).
- Metadata: `title`, `author` (owner name), `subject` (Drive description), `keywords` (front matter
  `tags`), `creator: "Wonky Write"`, `producer` default; creation date = `meta.modifiedAt`.
- Dark variant: page background rect in dark paper color on every page.
- Not supported (documented): tagged/accessible PDF structure (the `pdf` package has no tagging),
  PDF/A (P3), hyphenation.

### 5.3 HTML / Web page zip

```html
<!doctype html>
<html lang="{language}">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  <meta name="generator" content="Wonky Write">
  <style>/* ThemeCssWriter output (+ dark media query) */</style>   <!-- zip: <link rel=stylesheet href="style.css"> -->
</head>
<body><article class="wonky-doc">…</article></body>
</html>
```

All text HTML-escaped; links `rel="noopener noreferrer"`; heading ids = anchor ids; code tokens
as `<span class="tok-keyword">`; tasks as disabled checkboxes; images `<figure>` with
`<figcaption>`; tables with `<thead>`; mentions `<a class="wonky-mention" href="mailto:…">@Name</a>`.
Optional TOC as `<nav class="wonky-toc">`. Validated with the Nu HTML Checker in CI.

### 5.4 DOCX

> Implementation note: the `docx_creator` spike (§5.5) was skipped; `DocxExporter`
> (`export/docx/`) writes the parts itself and `DocxImporter` (`import/docx/`) reads them with
> `OoxmlReader`. Conventions that make our own files round-trip exactly (the importer recognizes
> them; Word and LibreOffice treat them as ordinary styles):
> - presentation-only styles are named `Wonky …` (`WonkyTableHeading`, `WonkyTaskDone`,
>   `WonkyMention`, `WonkyFigure`, `WonkyRule` = *Wonky Horizontal Rule*, `WonkySpacer`); the
>   importer ignores their run toggles, imports `WonkyRule` paragraphs as rules and drops
>   `WonkySpacer` paragraphs (they carry table spacing and keep adjacent tables apart);
> - tasks are `ListParagraph` items on a marker-less numbering (`numFmt none`) with a ☐/☒ glyph +
>   tab, so their indent survives; ordered runs get their own `w:num` (with `startOverride`),
>   bullets share one; `w:numId`s are contiguous (some readers index `w:num` by position);
> - mentions are `mailto:` hyperlinks with `w:tooltip="wonky-mention:<uuid>"`;
> - a `Caption` paragraph right after an image that repeats its `wp:docPr/@title` is not imported
>   again; heading bookmarks are the anchor ids (sanitized, ≤ 40 chars) so `#slug` links work;
> - files whose `docProps/app.xml` Application is `Wonky Write` produce no "formatting removed"
>   warnings, their TOC paragraphs are skipped and paragraph-style fonts never mark text as code
>   (inline code is `CodeChar`).
> Block spacing is written explicitly (`before = max(0, before − after(prev))`, Word adds both).
> Code block language and heading-numbering labels are not stored in DOCX.

Writer: `OoxmlWriter` (archive + xml), or `docx_creator` 1.4.0 if it passes §5.5. Package parts
(deterministic order):

```
[Content_Types].xml
_rels/.rels
docProps/core.xml          (dc:title, dc:creator, dc:language, dcterms:modified = meta.modifiedAt)
docProps/app.xml           (Application "Wonky Write")
word/document.xml
word/styles.xml            (from theme: docDefaults, Normal, Heading1–6, Title?, Quote, CodeBlock (para),
                            CodeChar (char), Hyperlink (char), ListParagraph, Caption, Header, Footer,
                            TOCHeading, TOC1–6, table style WonkyTable)
word/numbering.xml         (abstractNum 1: bullets 9 levels — glyph, color (w:color in lvl rPr), indent;
                            abstractNum 2: ordered 9 levels — numFmt decimal/lowerLetter/lowerRoman…, lvlText "%1.";
                            abstractNum 3: heading numbering (if enabled) linked via w:pStyle on levels)
word/settings.xml          (w:updateFields when TOC present, w:defaultTabStop, w:compat mode 15)
word/fontTable.xml
word/header1.xml, footer1.xml (+ header2/footer2 type="first" when differentFirstPage)
word/_rels/document.xml.rels (styles, numbering, settings, fontTable, headers, footers, images, hyperlinks)
word/media/image{n}.{png|jpeg}
```

- Each separate ordered list run gets its own `w:num` (pointing to abstractNum 2) so numbering
  restarts; bullets share one `w:num`. Indent per level from theme `list.indentPerLevel`.
- Tasks: paragraphs in `ListParagraph` style with leading `☐`/`☒` + tab, checked text
  `w:strike` + color when the theme says so.
- Code blocks: one paragraph per code line in `CodeBlock` style with `w:shd`; tokens as runs
  with colors; `w:spacing` before/after only on first/last line.
- Blockquote: `Quote` style with `w:pBdr/w:left` (bar) and `w:ind`.
- Rule: empty paragraph with `w:pBdr/w:bottom` per theme rule style (`ornament` → centered glyph
  paragraph).
- Images: `w:drawing/wp:inline` with sizes in EMU (1 px @96 dpi = 9525 EMU), `wp:docPr descr` =
  alt; caption paragraph in `Caption` style.
- Tables: `w:tbl` with `w:tblStyle=WonkyTable`, `w:tblHeader` on row 1 (repeat), `w:tblW` full or
  auto, column `w:gridCol` widths, cell alignment `w:jc`.
- Hyperlinks: relationship `TargetMode="External"`; mentions as `mailto:` hyperlinks.
- Section: `w:pgSz` (twips, `w:orient`), `w:pgMar` (twips, header/footer distance), `w:titlePg`
  for different first page, `w:pgNumType w:start w:fmt`.
- Header/footer slots: a 3-tab-stop paragraph (left/center/right) with `PAGE`/`NUMPAGES`
  `w:fldSimple`, title/author/date as text (date formatted at export time).
- Page color: `w:background` + settings `w:displayBackgroundShape` when `pageBackground`.
- Validation in CI: LibreOffice headless conversion succeeds; XML parts schema-validated
  (ECMA-376 transitional XSD subset); manual Word check per release.

### 5.5 `docx_creator` evaluation (M5 spike, ≤ 2 days)

Adopt `docx_creator` 1.4.0 for **writing** only if all hold: (1) compiles for VM **and** web
(pure Dart, no `dart:io` in used paths); (2) supports custom `styles.xml` with our style ids or
lets us inject raw parts, 9-level numbering definitions with per-level glyph/format/indent,
inline images, external hyperlinks, header/footer with fields, table header repeat, section
properties; (3) output opens in Word, LibreOffice and Google Docs without repair prompts; (4)
deterministic output; (5) permissive license. Adopt its **reader** only if it exposes paragraph
style ids, numbering (`numId`/`ilvl`), run properties incl. fonts, hyperlinks with targets, and
image bytes. Otherwise implement `OoxmlWriter`/`OoxmlReader` ourselves (estimated ~1,500 +
~1,200 LoC). Record the decision in the core package's `doc/` folder and in this spec.

### 5.6 ODT

`mimetype` (stored, first) · `META-INF/manifest.xml` · `meta.xml` · `styles.xml` (`office:styles`
from theme: default style, `Standard`, `Heading_20_1…6` with `style:default-outline-level`,
`Quotations`, `Preformatted_20_Text`, `Source_20_Text`, `Internet_20_link`, list styles
`WonkyBullets`/`WonkyNumbers` (9 levels), `Table_20_Heading`, `Caption`; `office:automatic-styles`
page layout with size/margins/header-footer; `office:master-styles` `Standard` master page with
header/footer slots using `text:page-number`, `text:page-count`, `text:title`) · `content.xml`
(`text:h`, `text:p`, `text:list`, `text:a`, `draw:frame`/`draw:image`, `table:table` with
`table:table-header-rows`) · `Pictures/*` · `settings.xml` (empty). Validated in CI with
LibreOffice and the ODF Toolkit validator.

> Implementation note: `OdtExporter`/`OdtImporter` (`export/odt/`, `import/odt/`). Heading
> numbering uses `text:outline-style`; tasks are a marker-less `WonkyTasks` list with ☐/☒ glyph
> text (checked-task strike/color in the `Task_20_Checked` paragraph style, ignored on import);
> a `Horizontal_20_Line` paragraph is a rule; headings carry bookmarks named after their anchor
> ids. Import: TOCs/indexes are dropped with a warning, annotations → `commentsDropped`.

### 5.7 RTF

Hand-written `RtfWriter`: header `{\rtf1\ansi\ansicpg1252\deff0\uc1`, `\fonttbl` (theme fonts),
`\colortbl` (palette colors used), `\stylesheet` (`\s0 Normal`, `\s1…\s6 heading 1…6` with
`\outlinelevelN\keepn`, quote, code, caption; `\cs` char styles for code/hyperlink),
`\listtable` + `\listoverridetable` (bullets/numbers, 9 levels), `\info` (title, author),
section/page (`\paperw \paperh \margl… \headery \footery \titlepg \pgnstarts`), header/footer
groups with `\chpgn` and `{\field{\*\fldinst NUMPAGES}}`. Text escaping: `\ \{ \}`, non-ASCII as
`\uN?` (signed 16-bit; surrogate pairs as two `\u`), tabs `\tab`, U+2028 `\line`. Images:
`{\pict\pngblip\picwN\pichN\picwgoalN\pichgoalN <hex>}` (JPEG `\jpegblip`). Tables: `\trowd
\trgaph108 \trhdr` (header) `\cellxN … \intbl … \cell … \row`. Links: `\field` HYPERLINK.

> Implementation note: `RtfExporter` / `RtfTokenizer` + `RtfImporter`. Round-trip extensions:
> code block language in an ignorable `{\*\wonkycodelang …}` group; mentions as `HYPERLINK "mailto:…"
> \o "wonky-mention:<uuid>"`; image alt in `\*\picprop` `wzDescription`; rules in a
> "Horizontal Line" paragraph style; tasks as a list level with `\levelnfc255` plus ☐/☒ glyph
> and tab. Every paragraph gets explicit collapsed `\sbN` and `\sa0`. The dark variant is not
> supported (`variant_unsupported` warning).

### 5.8 EPUB 3

Hand-built (no suitable pub package):

```
mimetype                                  (stored, first: application/epub+zip)
META-INF/container.xml
OEBPS/content.opf                         (metadata: dc:identifier urn:uuid:<documentUuid>, dc:title, dc:creator,
                                           dc:language, meta dcterms:modified (meta.modifiedAt, ISO, seconds);
                                           manifest; spine; cover-image property)
OEBPS/nav.xhtml                           (EPUB 3 nav: toc (H1–H3), landmarks)
OEBPS/toc.ncx                             (EPUB 2 compatibility)
OEBPS/cover.xhtml                         (when cover ≠ none)
OEBPS/text/chapter-001.xhtml …            (split at H1 / H2 / none; first chunk before the first split heading
                                           becomes "chapter-000" if non-empty)
OEBPS/styles/theme.css                    (ThemeCssWriter target: epub — no page background, colors only when
                                           useThemeColors; relative font sizes in em)
OEBPS/fonts/*.ttf                         (embedFonts; OFL permits embedding)
OEBPS/images/*
```

Cover `auto`: first image in the document if any; else a generated SVG cover page (title +
author, theme heading font and accent color). XHTML is well-formed (XML escaping, self-closing
void elements, `epub:type` on nav). Internal links across chapters are rewritten to
`chapter-00N.xhtml#anchor`. Validated by **epubcheck** (0 errors, 0 warnings) in CI.

> Implementation note: `EpubExporter` (`export/epub/`). With `chapterSplit: none` (or no split
> heading) the whole document is `chapter-001`. Theme heading numbering continues across chapter
> files through an inline `counter-reset` per chapter, and nav/NCX labels carry the numbers.
> Unknown `#fragment` links point to the first chapter. SVG images become placeholders (as in the
> other office formats); the light theme is always used.

### 5.9 Plain text

From the IR: headings as their text (blank line after), list items with `- `/`1. `/`[ ] `
prefixes and 2-space indent per level, quotes with `> `, code blocks verbatim, rules `----`,
images `[image: alt]`, tables as TSV or space-aligned columns, U+2028 → newline; optional hard
wrap at the column (words not broken; code not wrapped).

---

## 6. Page setup

### 6.1 Model (`Document.pageSetupJson`, `wonky_write_core/lib/layout/page_setup.dart`)

```jsonc
{
  "v": 1,
  "layout": "pages",                    // "pages" | "pageless"
  "paper": "letter",                    // letter | a4 | a3 | a5 | legal | tabloid | custom
  "customSize": { "width": "8.5in", "height": "11in" },   // only for custom (min 2in, max 48in)
  "orientation": "portrait",            // portrait | landscape
  "margins": "theme",                   // "theme" (06-themes page.defaultMargins) or Edges<Length>
  "header": { "enabled": true, "left": "", "center": "", "right": "{title}", "distance": "0.5in" },
  "footer": { "enabled": true, "left": "", "center": "{page}", "right": "", "distance": "0.5in" },
  "differentFirstPage": false,
  "firstPage": { "header": { … }, "footer": { … } },        // used when differentFirstPage
  "pageNumberStart": 1,
  "pageNumberFormat": "decimal"         // decimal | lowerRoman | upperRoman
}
```

| Paper | Size |
|-------|------|
| Letter | 8.5 × 11 in |
| Legal | 8.5 × 14 in |
| Tabloid | 11 × 17 in |
| A3 | 297 × 420 mm |
| A4 | 210 × 297 mm |
| A5 | 148 × 210 mm |

- **Defaults** for new documents: user preference *Settings › Write › Default page setup*
  (`writeDefaults.pageSetup`), else locale-based paper (Letter for `en-US`, `en-CA`, `es-MX`,
  `fil-PH`, `es-CL`, `es-CO`; A4 elsewhere), margins `theme`, footer center `{page}`, layout
  `pages`.
- Page background color always follows the theme (`page.paperColor`); there is no per-document
  page color.
- Changes go through `DocumentEndpoint.updateMeta` (field `pageSetup`, LWW); one undo step
  per dialog *Apply* (domain `write.meta`). Viewers/Commenters can't change it.
- `PageSetupValidator`: margins ≥ 0 and content box ≥ 2 × 2 in; header/footer distance <
  corresponding margin.

### 6.2 Page setup dialog (`WonkyDialogSpec`, MCP-operable)

```
┌ Page setup ─────────────────────────────────────────────────────────┐
│ ( ) Pages  ( ) Pageless          ┌─────────┐                         │
│ Orientation  [Portrait|Landscape]│ preview │ (miniature page with    │
│ Paper size   [Letter ▾]          │  ▭ ▭ ▭  │  margins & slots drawn) │
│ Margins      [Use theme margins ☑]└─────────┘                        │
│   Top [1 in] Bottom [1 in] Left [1 in] Right [1 in]  (units: in/cm)  │
│ Header  [✓] Left [      ] Center [      ] Right [{title}  ] ⓘ tokens │
│ Footer  [✓] Left [      ] Center [{page}] Right [         ]          │
│ [ ] Different first page  (expands first-page header/footer rows)    │
│ Page numbers start at [1]  Format [1, 2, 3 ▾]                        │
│ [Set as default]                               [Cancel] [OK]         │
└──────────────────────────────────────────────────────────────────────┘
```

Token help popover lists tokens with a click-to-insert. Units follow the locale (in for US, cm
otherwise). Pageless disables paper/orientation/margins/header/footer controls (kept for
export, which always uses pages). When a margin change (e.g. the *Narrow* preset) would leave a
header/footer distance at or beyond its margin, the dialog moves the distance inside it (half
the margin). `PageSetupValidator` errors are listed inline in the dialog and disable **OK**. The
dialog applies through `write.doc.setPageSetup {pageSetup}`, whose args schema accepts the
`PageSetup` JSON (an open object).

### 6.3 Header/footer tokens

| Token | Value |
|-------|-------|
| `{title}` | Drive item name |
| `{page}` | Logical page number (start + index, formatted) |
| `{pages}` | Total pages (logical count) |
| `{date}` | Export/print date, locale medium format |
| `{date:<pattern>}` | `intl` pattern, e.g. `{date:yyyy-MM-dd}` |
| `{author}` | Owner display name (or front matter `author`) |
| `{modified}` | Last modified date |
| `{{` / `}}` | Literal braces |

Unknown tokens render literally. Slots are plain text (no Markdown). The editor's Pages mode
shows headers/footers on page frames (non-editable; double-click opens the page setup dialog).

---

## 7. Pagination engine (`wonky_write_core/lib/layout/pagination_engine.dart`)

The **authoritative, line-level** paginator, used by **PDF, print preview and server-side page
counts** (with `PdfBlockMeasurer`). The editor's Pages mode uses its own block-level
approximation ([04-editor.md](04-editor.md) §29.3). The engine is measurer-agnostic (`BlockMeasurer`), so the editor's P1
line-level splitting (`PageSplitTextComponent`) can reuse it with a Flutter `TextLayout`-based
measurer to converge on identical breaks.

### 7.1 Inputs

```dart
final class PageGeometry {                  // in pt
  final double pageWidth, pageHeight;
  final EdgeInsetsPt margins;
  final double headerHeight, footerHeight;  // measured slot heights for this page kind
  final double headerDistance, footerDistance;
  double get contentTop    => math.max(margins.top, headerDistance + headerHeight + 6);
  double get contentBottom => math.max(margins.bottom, footerDistance + footerHeight + 6);
  double get contentHeight => pageHeight - contentTop - contentBottom;
  double get contentWidth  => pageWidth - margins.left - margins.right;
}

final class BlockMetrics {
  final int blockIndex;
  final double spaceBefore, spaceAfter;     // from theme
  final List<double> lineHeights;           // splittable text-like blocks (paragraph, list, task, quote line, code)
  final double? fixedHeight;                // unsplittable (image incl. caption, rule)
  final List<RowMetrics>? rows;             // tables: per-row height (+ per-cell line heights)
  final bool keepWithNext;                  // headings (theme), true by default
  final bool pageBreakBefore;               // theme (e.g. Manuscript H1)
}

abstract interface class BlockMeasurer {
  BlockMetrics measure(DocBlock block, double contentWidth);
}
```

### 7.2 Algorithm

Greedy fill with constraint back-off:

1. `y = 0` (top of content box), `prevSpaceAfter = 0`.
2. For each block `b`:
   - If `b.pageBreakBefore` and the page isn't empty → new page.
   - `gap = pageEmpty ? 0 : max(prevSpaceAfter, b.spaceBefore)` (space before is suppressed at
     the top of a page).
   - **Keep-with-next group**: if `b.keepWithNext`, form the group `b, b+1, …` while blocks are
     keep-with-next, plus the **minimum chunk** of the first non-keep block (its first
     `orphans` lines, its first table row + header, or the whole block if unsplittable). If the
     group doesn't fit in the remaining space but would fit on an empty page → new page before
     `b`. If the group is taller than a page, ignore keep-with-next.
   - If `gap + height(b) ≤ remaining` → place whole, continue.
   - **Splittable text block** with `n` lines: `k` = number of lines fitting in
     `remaining − gap`. Widow/orphan control (2 lines each): if `n < 4` or `k < 2` → move the
     whole block to the next page; else `k = min(k, n − 2)`; place lines `[0,k)`, continue with
     `[k,n)` on the next page (repeat while it doesn't fit).
   - **Code block**: same as text with lines = code lines (wrapped visual lines); widows/orphans
     2; continuation slices drawn without top/bottom radius.
   - **Table**: split between rows; continuation pages repeat the header row (its height is
     reserved before placing rows). A row taller than a full page's remaining content height is
     split at line boundaries **per cell** (each cell gets the lines that fit; continuation row
     shows the rest); header rows never split.
   - **Image**: never split; if it doesn't fit → next page; if taller than the content height →
     scaled down (keeping aspect) to the content height minus caption.
   - **Rule**: never split; a rule at the top of a page is dropped visually (zero height) but
     kept in the model.
   - `prevSpaceAfter = b.spaceAfter`.
3. Empty paragraphs occupy one line height. Trailing empty pages are never produced.

Output:

```dart
final class PaginationResult {
  final List<PageLayout> pages;
}
final class PageLayout {
  final int index;                          // 0-based physical page
  final List<PlacedSlice> slices;           // blockIndex, lineFrom/lineTo or rowFrom/rowTo, y, height, isContinuation
}
```

Complexity O(blocks); measurement is cached per block by `(block content hash, contentWidth,
theme hash)`, so the editor re-paginates incrementally after edits (only from the first changed
block onward, stopping early when a page break position re-synchronizes with the previous
result).

---

## 8. Print and print preview

### 8.1 Route `/d/:uuid/print` (`PrintPreviewScreen`)

> Implementation note (iteration 1, web first): the client PDF (`PdfExporter`, bundled fonts via
> `AssetFontProvider`) is shown in the browser's built-in PDF viewer inside an in-app
> `<iframe>` platform view (`features/print/pdf_view_web.dart`) — page thumbnails, zoom and
> page navigation come from the viewer, so `Printing.raster` (which loads pdf.js from a CDN) is
> not used. *Print* calls `print()` on that frame (same tab, browser print dialog); desktop shows
> a summary and offers *Download PDF* until the `printing` integration lands. Settings: light /
> dark, suggestions accepted / original, header & footer, table of contents.

```
┌ ← Back   Print preview — Q3 planning                 [Download PDF] [Print] ┐
├──────────┬──────────────────────────────────────────────────┬──────────────┤
│ ▭ 1      │                                                  │ Settings     │
│ ▭ 2      │             ┌───────────────────┐                │ Pages: All ▾ │
│ ▭ 3 ◄    │             │   page 3 image    │                │ [Light|Dark] │
│ ▭ 4      │             │                   │                │ Suggestions: │
│ …        │             └───────────────────┘                │  Accepted ▾  │
│          │                  3 / 12                          │ [ ] TOC      │
│          │                                                  │ [✓] Header & │
│          │                                                  │     footer   │
│          │                                                  │ Page setup … │
├──────────┴────────────────────── Zoom [Fit width ▾] − + ────┴──────────────┤
```

- PDF bytes are generated with the PDF exporter (client, same thresholds as §4.3; server for
  large docs) and **rasterized** with `Printing.raster(bytes, pages: [i], dpi: …)` lazily for
  visible pages (dpi = 72 × zoom × devicePixelRatio, cached per (page, dpi)); thumbnails at 24
  dpi. Settings changes regenerate the PDF (debounced 300 ms) and keep the current page.
- Navigation: thumbnails click, PgUp/PgDn, Home/End, `Mod+=`/`Mod+-` zoom, `Esc` back.
- *Print* → `Printing.layoutPdf(onLayout: (_) async => bytes, name: title, format:
  pageFormat)`: desktop opens the native print dialog; web prints the PDF through the browser
  print dialog (the `printing` package uses a hidden iframe — no new window). If
  `Printing.info()` reports printing unavailable (e.g. Linux without CUPS, some browsers), *Print*
  is disabled with a tooltip and *Download PDF* is highlighted.
- `Mod+P` in the editor opens this route (Google Docs-like); `Mod+P` inside the route prints.
- Viewers/Commenters can print only if `nonEditorsCanExport` is on
  ([../06-sharing-and-permissions.md](../06-sharing-and-permissions.md) §1).
- MCP: `ui.navigate("/d/<uuid>/print")`, commands below; `ui.screenshot` captures the preview.

---

## 9. Export UI

### 9.1 *File › Download* submenu

Markdown (.md) · Markdown with images (.zip) · PDF document (.pdf) · Web page (.html) · Web page,
zipped (.zip) · Microsoft Word (.docx) · OpenDocument text (.odt) · Rich Text Format (.rtf) ·
EPUB publication (.epub) · Plain text (.txt) · separator · *More export options…*.

Clicking a format exports immediately with last-used options and the default file name (no
dialog); *More export options…* (or Shift-click) opens the export dialog. Progress: toast with
spinner for > 1 s exports, *Cancel*; on completion: web → browser download; desktop → native save
dialog (`file_picker` `saveFile`, suggested name, default folder = last used) then write; toast
"Exported ‘Q3 planning.pdf’" with *Show in folder* (desktop). Warnings (missing images, dropped
content) are listed in the toast's *Details*.

### 9.2 Export dialog

`ShadDialog` (720 px): left list of formats (icon, name, extension); right: options of the
selected format (§4.2) + common options (suggestions, light/dark, version: *Current* or a named
version picker); bottom: file name input, *Preview* (PDF only → opens print preview with these
options), *Cancel*, *Export*. Built with `WonkyDialogSpec`.

---

## 10. Server: `WriteExportEndpoint` (`writeExport`) and MCP

| Method | Description |
|--------|-------------|
| `export(documentUuid, format, optionsJson, revision?)` → `ExportResultView {fileName, mimeType, sizeBytes, pageCount?, downloadUrl, expiresAt, inlineText?, warnings}` | Synchronous for small docs (≤ 30 s), else error `useProgressApi` |
| `exportWithProgress(documentUuid, format, optionsJson, revision?)` → `Stream<ExportProgressEvent>` | Events: `phase` (loading, layout, fonts, images, packaging, uploading), `progress` (0–1, page n/m), `done(ExportResultView)`, `error(code, message)`; cancel by closing the stream |
| `convertForInsert(uploadId, format, options)` → `{deltaJson, warnings}` | Server-side conversion of a large file for *Import into this document* (images already uploaded, owned by the target document) |
| `fetchImage(documentUuid, src)` → bytes | Proxy for CORS-blocked remote images during client exports (≤ 10 MB, cached) |

- Access: Viewer+; Viewers/Commenters only if `nonEditorsCanExport`. Exporting an old revision
  requires the same role as viewing history (Editor+, per history spec).
- Implementation note: every format runs through the core exporters with the document's theme
  (assigned theme → the caller's default theme → *Wonky Default*), page setup and metadata;
  fonts come from `web/fonts/` (`FileSystemFontProvider`, same TTFs and family substitution as
  the app's `AssetFontProvider`), images from storage / the SSRF-safe fetcher
  (`ServerImageResolver`). Option keys are accepted in camelCase or snake_case. Exports run in a
  worker isolate of the shared `IsolateRunner` (spec 13 §3: killed after 120 s or when the
  progress stream is cancelled; images are resolved on the request isolate through its channel);
  the result cache is not implemented yet. Server imports (`drive.import`, `convertForInsert`) run
  the core importers in an `IsolateRunner` isolate that is killed after 60 s;
  version diffs (08 §4.3) run there too (60 s); the
  source page geometry becomes the new document's page setup (`ImportedPageSetups`).
- Output stored as `StoredFile(kind: exportResult, private, expiresAt: +24 h)`; `downloadUrl` is a
  signed URL valid 15 min; cleanup FutureCall hourly. `inlineText` set for `markdown`/`txt` ≤ 1 MB.
- **Cache**: key `sha256(documentUuid, revision, format, optionsJson, theme contentHash +
  variant, pageSetupJson, fontsVersion)` → reuse an unexpired StoredFile.
- Limits: 2 concurrent exports per user, the runner's global slots (half the cores, 2–8), 120 s timeout, max
  2,000 pages, max 500 images.
- Logs `ActivityEvent(exported, {format})`.

MCP mapping ([../09-mcp.md](../09-mcp.md) §4):

| MCP | Implementation |
|-----|----------------|
| `drive.export {uuid, format, options?, revision?}` | `format` ∈ `md`, `md_zip`, `pdf`, `html`, `html_zip`, `docx`, `odt`, `rtf`, `epub`, `txt`; `options` = §4.2 JSON (snake_case); returns `{download_url, expires_at, file_name, size_bytes, page_count?, warnings}` and inline `text` for `md`/`txt` |
| `drive.import {name, kind: "document", format?, content_base64 \| text, parent_uuid?, options?}` | §3.2 pipeline; returns `{item, warnings}` |
| `write.get_page_setup` / `write.update_page_setup` | See [09-mcp-and-ai.md](09-mcp-and-ai.md) |

---

## 11. Fidelity tables

### 11.1 Import (✓ kept · ≈ converted/approximate · ✗ dropped with warning)

| Feature | MD | TXT | HTML | DOCX | ODT (P2) | RTF (P2) |
|---------|----|-----|------|------|----------|----------|
| Headings 1–6 | ✓ | ✗ | ✓ | ✓ (styles/outline) | ✓ | ✓ (stylesheet/outline) |
| Bold / italic / strike | ✓ | — | ✓ | ✓ | ✓ | ✓ |
| Underline / color / font / size | — | — | ✗ | ✗ | ✗ | ✗ |
| Inline code | ✓ | — | ✓ | ≈ (mono font) | ≈ | ≈ |
| Links | ✓ | — | ✓ | ✓ | ✓ | ✓ |
| Bullet / ordered lists (nesting) | ✓ | — | ✓ | ✓ | ✓ | ✓ |
| List start ≠ 1 | ≈ restart | — | ≈ | ≈ | ≈ | ≈ |
| Task lists | ✓ | — | ✓ | ≈ (glyph/checkbox) | ≈ | ≈ |
| Blockquote | ✓ (nesting flattened) | — | ✓ (nesting flattened) | ≈ (Quote style) | ≈ | ≈ |
| Lists inside quotes | ✓ | — | ✓ | ≈ (plain list items) | ≈ | ≈ |
| Code block (+ language) | ✓ | — | ✓ | ≈ (no language) | ≈ | ≈ |
| Images | ✓ (URL / zip) | — | ✓ | ✓ (EMF/WMF ✗) | ✓ | ✓ (png/jpeg) |
| Image captions | title | — | figcaption | ✗ | ✗ | ✗ |
| Tables | ✓ | — | ≈ (spans flattened) | ≈ (merges flattened) | ≈ | ≈ |
| Horizontal rule | ✓ | — | ✓ | ≈ (border para ✗) | ✗ | ✗ |
| Soft line breaks | ✓ | option | ✓ | ✓ | ✓ | ✓ |
| Footnotes | literal | — | ✗ | ≈ ("Notes" section) | ≈ | ✗ |
| Comments | — | — | — | ✗ (P2 ✓) | ✗ | ✗ |
| Tracked changes | — | — | — | ≈ accepted (P2 suggestions) | ≈ | ✗ |
| Page size/margins | — | — | — | ✓ → page setup | ✓ | ✓ |
| Headers/footers | — | — | — | ✗ | ✗ | ✗ |
| Front matter / metadata | ✓ | — | `<title>`, `lang` | title, language | title | title |

### 11.2 Export (✓ full · ≈ approximate · ✗ not represented)

| Feature | MD | PDF | HTML | DOCX | ODT | RTF | EPUB | TXT |
|---------|----|-----|------|------|-----|-----|------|-----|
| Theme typography | ✗ | ✓ | ✓ | ✓ (styles) | ✓ (styles) | ✓ | ✓ (CSS) | ✗ |
| Heading numbering (theme) | ✗ | ✓ | ✓ | ✓ (numbering) | ✓ | ≈ (text) | ✓ | ✗ |
| Syntax highlighting | fence lang | ✓ | ✓ | ✓ (run colors) | ✓ | ✓ | ✓ | ✗ |
| Images | link/zip | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | `[image]` |
| Tables (header repeat) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ≈ |
| Task checkboxes | ✓ | ✓ | ✓ | ≈ glyph | ≈ glyph | ≈ glyph | ✓ | ✓ `[ ]` |
| Lists inside quotes | ✓ `> - ` | ✓ bar + indent | ✓ `<blockquote><ul>` | ≈ bar + indent | ≈ quote style | ≈ bar + indent | ✓ | ✓ `> - ` |
| Links / mentions | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | URL in parens |
| Page setup / header & footer | ✗ | ✓ | ≈ (`@page` size/margins) | ✓ | ✓ | ✓ | ✗ | ✗ |
| TOC | ✗ | ✓ (opt) | ✓ (opt) | ✓ (field) | ✓ (opt) | ✗ | nav ✓ | ✗ |
| Bookmarks/outline | ✗ | ✓ | ids | headings | headings | ✗ | nav | ✗ |
| Fonts embedded | — | ✓ | opt | P2 | ✗ | ✗ | opt | — |
| Dark variant | — | ✓ | ✓ (media query) | ≈ (page color) | ≈ | ✗ | ✗ | — |
| Suggestions (accepted/original) | ✓ | ✓ | ✓ | ✓ (P2 tracked changes) | ✓ | ✓ | ✓ | ✓ |
| Comments | ✗ | ✗ | ✗ | ✗ (P2) | ✗ (P2) | ✗ | ✗ | ✗ |

---

## 12. Commands

| Command id | Args | Role | Undoable | Default binding / menu |
|------------|------|------|----------|------------------------|
| `write.export.download` | `{format, options?, fileName?, revision?}` | Viewer (+ export setting) | — | File › Download ▸ items |
| `write.export.openDialog` | `{format?}` | Viewer | — | File › Download › More export options… |
| `write.import.intoDocument` | `{fileUuid?}` (picker when absent) | Editor | ✓ (`write.content`, one step) | File › Import into this document… |
| `write.pageSetup.open` | — | Viewer (read-only for < Editor) | — | File › Page setup… |
| `write.pageSetup.update` | `{patch: PageSetupPatch}` | Editor | ✓ (`write.meta`) | dialog OK |
| `write.pageSetup.setPaper` | `{paper, customSize?}` | Editor | ✓ | |
| `write.pageSetup.setOrientation` | `{orientation}` | Editor | ✓ | |
| `write.pageSetup.setAsDefault` | — | — | — (setting) | dialog button |
| `write.print.openPreview` | — | Viewer (+ export setting) | — | File › Print, `Mod+P` |
| `write.print.print` | — | same | — | `Mod+P` in preview |
| `write.print.setOptions` | `{pageRange?, variant?, suggestions?, includeToc?, headerFooter?}` | — | — | preview settings |
| `write.print.goToPage` | `{page}` | — | — | |
| `write.print.setZoom` | `{zoom: "fitWidth"\|"fitPage"\|number}` | — | — | |

Shell-level `shell.drive.import` (*File › Import…*, new document) is defined in
[../05-drive-and-files.md](../05-drive-and-files.md). Related commands defined in
[04-editor.md](04-editor.md): `write.doc.setLayout {layout}` (Pages/Pageless; writes
`pageSetup.layout`, undoable meta change) and `write.edit.copyAsMarkdown` / `copyAsHtml`.

---

## 13. Acceptance criteria

1. **Markdown round trip**: `import(export(D)) == normalize(D)` for 10k random valid documents
   (property test, per [02](02-document-model.md) §2.2), including the zip variant with images.
2. **HTML round trip**: own HTML export → import yields the same delta (minus theme numbering).
3. **DOCX round trip** for the supported subset (headings, inline attrs, links, nested lists,
   tasks, quotes, code, images, tables): export → import equals the source delta for the
   200-document corpus; files open without repair in Word (manual release check), LibreOffice
   (CI) and Google Docs (manual).
4. Importing the fixture corpus (Google Docs HTML & DOCX, Word DOCX & HTML, LibreOffice ODT,
   Notion/Obsidian Markdown, GitHub README files) produces valid deltas with the expected
   warnings (snapshot tests).
5. PDF: page count matches the editor's Pages mode for ≥ 90 % of the corpus (and differs by at
   most 1 page otherwise; the editor shows its approximation hint); headings appear as bookmarks; links clickable; fonts embedded (`pdffonts` lists
   only embedded subsets); headers/footers show correct tokens; widows/orphans never < 2 lines;
   headings never last on a page; table headers repeat.
6. EPUB passes epubcheck with 0 errors/warnings; HTML passes the Nu checker; ODT passes ODF
   validator; DOCX/ODT/RTF convert with LibreOffice headless without errors.
7. Exports work offline on desktop and web (client path) and produce byte-identical output to the
   server path for the same inputs.
8. Print preview renders the first page < 1 s for a 20-page document on desktop; printing opens
   the system/browser print dialog without opening a new window/tab.
9. Page setup changes are one undo step, sync to collaborators live (Pages mode re-paginates),
   and are reflected in all exports.
10. Every command in §12 is invocable via `ui.invoke_command`; `drive.export`/`drive.import`
    integration tests pass through the MCP route for every format.

## 14. Tests

- **Unit (core)**: each importer against fixtures (input file → expected delta JSON + warnings);
  each exporter's XML parts snapshot-tested (canonicalized); RTF tokenizer; encoding detection;
  page setup validation; header/footer token rendering; pagination engine with synthetic metrics
  (table-driven: widows/orphans, keep-with-next chains, oversized images/rows, page break before).
- **Property/fuzz**: random documents → every exporter must not throw and must produce
  structurally valid output (zip opens, XML well-formed, PDF parses with `pdf`'s parser); random
  HTML (generated DOM trees) → importer yields valid deltas.
- **Golden PDF images**: sample + corpus documents × 8 built-in themes × {light, dark} →
  rasterized in CI with `pdftoppm -r 72` → compared to checked-in PNGs (per-pixel diff ≤ 0.5 %,
  `tool/golden_pdf.dart --update` to refresh).
- **External validators in CI** (Docker image `wonky-ci-validators`): LibreOffice headless
  (`soffice --headless --convert-to pdf` for DOCX/ODT/RTF, page count within ±1 of our PDF),
  epubcheck 5.x, Nu HTML checker, ODF validator, `pdffonts`/`pdfinfo` assertions.
- **Widget/integration**: export dialog flows, download submenu, page setup dialog (MCP
  `ui.fill_dialog`), print preview navigation (flutter_driver), offline export on desktop.
- **Server** (`serverpod_test`): `WriteExportEndpoint` access rules (`nonEditorsCanExport`),
  caching, signed URL expiry, progress stream, cancellation, `DriveEndpoint.import` per format,
  SSRF fetcher rejects private IPs/redirects to private IPs.
