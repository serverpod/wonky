# Code-quality review: Wonky Write (`wonky_write/`) + `packages/wonky_write_core`

Read-only review. Nothing in the repo was changed. Specs read: AGENTS.md, specs/README.md,
01-architecture.md, wonky_write/README.md, 02-document-model.md, 04-editor.md (§2, §29, §35–36, §43),
08-commands-and-undo.md (skimmed), 07 §4.3 (export threading). The sync protocol is covered by
another reviewer, so sync code is only looked at here for performance.

Size: `wonky_write/lib` ≈ 49.6k hand-written lines (+16.5k generated l10n), 61 unit/widget test
files (13.4k lines) + 6 integration files. `wonky_write_core/lib` ≈ 41k lines, 24 test files (8.8k lines).

Every finding below was checked against the code. Anything not fully proven is marked
**(likely)** or **(speculative)**.

---

## Prioritised findings

### HIGH

#### W-01 · Each keystroke rebuilds a lot of UI and runs O(document) scans while the comment margin is on
- **Severity** High · **Category** perf · **Effort** M
- **Evidence**
  - Every local change bumps `contentVersion` (`write_document_session.dart:825`). `WriteComments._onContent` then clears its anchor cache and notifies (`features/comments/write_comments.dart:112-115`). `WriteSuggestionsController._onContent` drops its pending list, calls `byId(_active)` when a suggestion is active, and notifies (`features/suggestions/suggestions_controller.dart:66-70`). Calling `byId` rebuilds the list straight away.
  - The getters rebuild from the whole document: `anchors => _anchors ??= CommentAnchors.anchors(session.editor.delta)` (`write_comments.dart:58-61`) and `pending => _pending ??= SuggestionIndex.list(session.editor.delta)` (`suggestions_controller.dart:30-32`). `editor.delta` is `mirror.toDelta()`, which is O(n) (`write_editor_controller.dart:398`).
  - Three places read these getters on every notify:
    - `_canvas` `ListenableBuilder` listens to `session.comments` and `session.suggestions`. It rebuilds `WonkyEditor` (and so `SuperEditor`) and calls `_marginShown()`, which reads `anchoredOpenThreads` and `suggestions.pending` (`features/screen/write_document_screen.dart:273-281, 440-446`).
    - A second `ListenableBuilder` with the same listenables wraps `_withMargin` (`write_document_screen.dart:393-398`).
    - `CommentMargin` relayouts after each frame and calls `_collect()`, which reads `anchors` and `pending` (`features/comments/comment_margin.dart:96-135`).
  - The toolbar rebuilds on `doc` (the `WriteDocumentController`) and on `services.undo` (`features/screen/write_toolbar.dart:229-236`). `WriteDocumentController._onEditor` notifies on every editor change. When the selection changed it also calls `registry.notifyStateChanged()`, which rebuilds the menus (`write_document_controller.dart:352-360`).
  - `WonkyEditorState._onControllerChanged` also calls `setState` on every controller notify (`features/editor/ui/wonky_editor.dart:268-272`).
- **Why it matters.** The budget is under 16 ms p95 from keystroke to render on a 100-page document (Write 03 §7 / 04 §36). Today one keystroke means at least 3 full Delta serialisations and scans, plus a rebuild of the editor, toolbar, menus and margin.
- **Recommended change**
  - Keep the comment anchors and the suggestion index up to date incrementally. Transform the cached ranges through each change Delta, as `EditorViewState.transformThrough` already does, and rebuild in full only on debounce or resync.
  - Notify only when the derived data actually changed.
  - Drop `session.comments` and `session.suggestions` from the `_canvas` listenables. Only `endInset` depends on them, so compute that in a small child widget.
  - Split the toolbar listenable: format state should rebuild per selection (throttled), not on every `doc` notify.

#### W-02 · The layout pipeline is O(document) per keystroke, our style phases add to it, and the spec's mitigations are missing
- **Severity** High · **Category** perf · **Effort** M (phases), L (large-document mode / lazy layout)
- **Evidence**
  - super_editor (vendored) rebuilds the whole view model on every document change:
    - it calls `createViewModel` for every node (`third_party/super_editor/lib/src/default_editor/layout_single_column/_presenter.dart:164-186`);
    - it runs every style phase over all components (`:188-193`);
    - it compares every old and new component with `==`, an AttributedText comparison (`:229+`).
  - `CodeHighlightStylePhase.style` runs on every keystroke. For every code block it calls `toPlainText`, `model.copy()`, `text.copy()` and one `addAttribution` per token, even on a cache hit (`features/editor/styles/style_phases.dart:56-105`). The cache only saves the tokenising, not the rebuilding of attributed text.
  - `TextDirectionStylePhase` runs `detectTextDirection(toPlainText())` for every text block on every keystroke (`style_phases.dart:150-179`).
  - Spec 04 §36 calls for a large-document mode at more than 5,000 nodes or more than 500k characters, viewport-only highlighting and spelling, and CI benchmarks. None of it exists. A grep for 5000/500000/largeDoc finds nothing, and there are no Write bench fixtures (only Sheets, Slides and spellcheck have benchmarks).
  - Spec §36.6 asks for chunked or isolate mapping on initial load. `EditorPipeline` maps synchronously (`controller/editor_pipeline.dart:28-30`).
- **Why it matters.** The cost per keystroke grows linearly with document size, and nothing measures it.
- **Recommended change**
  - In the phases, cache the *output view model* per `(nodeId, input text identity, language/direction)` and return the same instance when nothing changed. Equality then short-circuits, and the copy and attribution work disappears.
  - Cache direction per node in the same way.
  - Add a `bench_100_pages` widget benchmark (profile mode) before optimising further.
  - Implement the large-document switches.
  - Keep the P2 lazy sliver layout on the roadmap.

#### W-03 · Pages mode re-measures the whole document after every rebuild, including plain caret moves
- **Severity** High (Pages documents) · **Category** perf · **Effort** M
- **Evidence**
  - Every Pages-mode build resets the pass budget and schedules repagination (`wonky_editor.dart:717-720`). Because of W-01, that is every keystroke and every selection change.
  - `PaginationController.measure` builds `document.toList()` and calls `layout.getRectForSelection(begin, end)` and `getRectForPosition` for **every node** (`features/editor/pagination/pagination.dart:71-93`). For text components that means computing the text boxes of every paragraph.
  - `PageChromePainter.paint` draws every page with a blur shadow and header/footer text painters, with no culling (`pagination.dart:240-270`).
  - Spec §36 says "pagination runs at most once per 500 ms while typing" in large-document mode. That is not implemented.
- **Recommended change**
  - Measure from the first changed node onward and reuse the earlier offsets above it.
  - Use component `RenderBox` heights instead of text-selection boxes.
  - Skip the measure when only the selection changed.
  - Throttle the measure while typing.
  - Cull the page chrome to the viewport.

#### W-04 · Suggesting mode is O(document) per keystroke
- **Severity** High (for people who review in Suggesting mode) · **Category** perf · **Effort** S–M
- **Evidence.** `_emitAsSuggestion` (`features/editor/controller/write_editor_controller.dart:485-546`) runs a chain of full-document passes on every keystroke:
  1. `mirror.toDelta()` (full)
  2. `after.compose(change.inverse)` (full)
  3. `_rewriter.rewrite(before, …)`, whose `_Cursor` walks the base from offset 0
  4. `change.inverse.compose(rewritten)`
  5. `DeltaOps.invert(rewritten, before)` (full)
- **Recommended change.** Rewrite against `mirror.slice(touchedStart, touchedEnd)` with an offset, the way `DocumentMirror.invert` already works (`mapping/document_mirror.dart:159-190`). Build the inverse from the slice too.

#### W-05 · Images decode at full resolution, and every image in the document is built
- **Severity** High (memory, web) · **Category** perf · **Effort** S
- **Evidence**
  - `Image(image: provider, fit: BoxFit.contain)` is used with no `ResizeImage` or `cacheWidth` (`features/editor/components/wonky_components.dart:334-352`). A repo-wide grep finds no `cacheWidth` or `ResizeImage` in `wonky_write`.
  - `_trackSize` resolves the provider a second time, from `build` (`:233-252`).
  - Spec §36.5 requires decoding at `cacheWidth`, at most 4 concurrent decodes, and offscreen placeholders.
  - There is no viewport virtualisation (W-02), so a document with 40 photos decodes 40 full-size bitmaps when it opens. A 12 MP photo is about 48 MB as RGBA.
- **Recommended change**
  - Wrap providers in `ResizeImage.resizeIfNeeded(cacheWidth: (maxWidth * dpr).round(), …)`.
  - Add a small decode semaphore.
  - Defer decoding offscreen images (a visibility check).

#### W-06 · Core importers have no limit on decompressed size (zip bomb), and the server's timeout does not stop the import
- **Severity** High · **Category** bug/security (DoS) · **Effort** S–M
- **Evidence**
  - `ImportLimits.checkInput` limits only the *compressed* byte length (`import/import_limits.dart:59-67`): 5 MB on the client, 50 MB on the server.
  - `ZipDecoder().decodeBytes(bytes)` followed by `f.readBytes()` / `file.content` decompresses without any cap (`import/xml_support.dart:106-118, 139-147`; `import/wonky_importers.dart:51-59, 145, 189-195`).
  - The server runs these imports in `Isolate.run(...).timeout(conversionTimeout)` (`wonky_server/lib/src/write/export/write_import_service.dart:84-104`). The timeout gives up waiting but does not kill the isolate, and isolates share the process heap. A 50 MB DOCX made mostly of one highly compressible part can therefore exhaust server memory.
- **Recommended change**
  - Before decompressing, check the archive's declared `uncompressedSize`: a per-part cap of about 50 MB, a total cap of about 200 MB, and a cap on the compression ratio.
  - Also stream-limit the actual decompressed bytes.
  - On the server, use `Isolate.spawn` with an `onExit`/`kill` handle so a timeout actually terminates the work.

#### W-07 · Client export on the web blocks the UI and its Cancel button cannot work
- **Severity** High (100-page PDF on the web) · **Category** perf/bug · **Effort** S
- **Evidence**
  - Spec 07 §4.3 says the web "runs on the main isolate in cooperative chunks (`await` a zero-delay future between blocks and pages) behind a progress dialog with *Cancel*".
  - `PdfExporter`'s page loop is synchronous. It calls `input.cancel?.throwIfCancelled()` and `progress` on each page but never yields (`export/pdf/pdf_exporter.dart:1055-1060`), so neither the cancel nor the progress UI can run.
  - The DOCX, ODT, HTML and EPUB exporters likewise only report progress at phase boundaries (`docx_exporter.dart:102-168`, `odt_exporter.dart:316`).
  - `ExportService.export` calls them directly (`wonky_write/lib/features/export/export_service.dart:310`).
- **Recommended change.** Add an `await Future<void>.delayed(Duration.zero)` (or a time-sliced yield helper) every N blocks and pages in each exporter, behind a `yieldEvery` option so server runs stay synchronous. Run them in `Isolate.run` on desktop, as the spec says.

#### W-08 · Two different `SuggestionRewriter` implementations: the editor and AI/MCP produce different suggestions
- **Severity** High · **Category** bug-risk/maintainability · **Effort** M
- **Evidence**
  - The app version is `wonky_write/lib/features/editor/suggesting/suggestion_rewriter.dart` (287 lines, also declares its own `SuggestionContext`). Only the editor uses it (`write_editor_controller.dart:16, 461`).
  - The core version is `packages/wonky_write_core/lib/src/collab/suggestion_rewriter.dart` (251 lines). The AI controller (`features/ai/write_ai_controller.dart:579`) and the server's MCP headless editor (`wonky_server/lib/src/write/mcp/headless_editor.dart:249`) use it.
  - Their semantics differ:
    - The app version extends an adjacent own insertion (`_ownInsertion(previousBaseAttributes)` / `peekAttributes`, `:60-75`) and reorders deletes before inserts (`_deletesFirst`).
    - The core version stamps every insert with the new key and throws on overlong changes (`:61-83`).
  - The app class says "Pure Dart (no Flutter) so it can move to `wonky_write_core`" (`:28`), which suggests a move that was never finished.
  - Only the core version has unit tests (`wonky_write_core/test/collab/collab_test.dart`, `op_shape_validator_test.dart`).
- **Recommended change.** Merge the app behaviour (own-insertion extension, deletes first) into the core rewriter and delete the app copy. Run the table in spec 04 §32.1 as a single test suite against the core version.

### MEDIUM

#### W-09 · Each op, ack and cursor update on the client and server costs a full document pass (sync, perf only)
- **Severity** Med · **Category** perf · **Effort** M–L (coordinate with the sync reviewer)
- **Evidence**
  - `_applyRemote`: `_server = WonkyOt.apply(_server, r)` (`features/sync/document_sync_controller.dart:1087`). `_completeAck` does the same (`:1208`).
  - `WonkyOt.apply` makes four passes over the document: `documentLength`, `baseLength`, `compose` and `canonical` (`wonky_write_core/lib/src/delta/ot.dart:107-116`).
  - `_predictFinal` calls `_normalizer.normalizeChange(_server, op)` on every ack (`:1162`). `normalizeChange` composes, re-parses the whole document into `WonkyDocument` lines and renormalises everything (`delta/normalizer.dart:144-190, 193+`). The server does the same per submitted op.
  - `sendCursor` (up to 10 per second) calls `WonkyOt.invert(pending, _server)`, which walks the server document (`document_sync_controller.dart:615`).
  - `DeltaUtils.canonical` rebuilds every op and concatenates strings (`packages/wonky_rich_text/lib/src/delta_utils.dart:23-67`).
- **Recommended change**
  - Normalise only the lines a change touches, using a window plus the embed-identity index.
  - Keep the client's server document as a line/piece structure, or derive it lazily: `server = local ∘ invert(pending)` is only needed for resync and integrity checks.
  - For cursors, transform offsets through `pending` with `transformPosition` on its inverse built from `mirror.slice`, not from the full server document.

#### W-10 · The undo stack save hashes the whole document after every typing pause
- **Severity** Med · **Category** perf · **Effort** S
- **Evidence**
  - `_onUndoChanged` schedules `_saveUndo` 800 ms after each change (`features/document/write_document_session.dart:1097-1104`).
  - `_saveUndo` serialises up to 500 steps to JSON and calls `documentHash(editor.delta)`: `toDelta` → `canonical` → `toJson` → `canonicalJsonEncode` → `utf8` → SHA-256 in pure Dart (`:1119-1129`; `wonky_write_core/lib/src/delta/hash.dart:13-18`).
  - On the web, SHA-256 over a document of several MB takes tens of ms, so the jank lands right after the user stops typing **(likely; not measured)**.
- **Recommended change.** Key the stored stack by `(revision, pending outbox ids)`, or by a rolling hash kept up to date in `DocumentMirror`. Serialise only the steps that changed.

#### W-11 · Every remote op rebases the whole undo and redo stacks
- **Severity** Med · **Category** perf · **Effort** M
- **Evidence**
  - `_afterRemoteChange` calls `rebaseWriteStacks(undo, redo, change)` (`write_document_session.dart:889-898`). This does two OT transforms per entry across all undo and redo steps (`features/document/write_undo.dart:119-141`), up to `maxSteps = 500` (`packages/wonky_app/lib/src/undo/undo_service.dart:121`).
  - At the 100 ops/s rate the spec benchmarks, that is up to about 100k Delta transforms per second on the UI thread.
- **Recommended change.** Rebase lazily: buffer remote changes, compose them, and rebase only when undo or redo runs, or periodically when idle. Or rebase only the top K steps eagerly and the rest on demand.

#### W-12 · `WonkyTableComponentBuilder` mutates the presenter's view model, so tables are rebuilt on every presenter pass
- **Severity** Med · **Category** bug/perf · **Effort** S
- **Evidence**
  - `if (inline != null) viewModel.selectionColor = const Color(0x00000000);` inside `createComponent` (`components/wonky_components.dart:596-598`). `inlineTableEditing` defaults to `true` (`wonky_editor.dart:67`).
  - The selection styler sets `selectionColor` to a non-transparent value on every `SelectionAwareViewModelMixin` view model in each pass (`third_party/super_editor/.../_styler_user_selection.dart:162-165`).
  - `MarkdownTableViewModel.==` compares `selectionColor` (`third_party/super_editor/lib/src/default_editor/tables/table_markdown.dart:234-245`).
  - The cached old view model has been mutated to transparent, so it never equals the new one, and every table is marked changed and rebuilt on each keystroke **(likely; confirm with a rebuild counter)**.
- **Recommended change.** Make the color transparent with a style phase or a stylesheet rule. If it has to happen in the builder, use `viewModel.copy()` and never mutate the input.

#### W-13 · Find highlights and remote selections are not limited to the viewport
- **Severity** Med · **Category** perf · **Effort** S–M
- **Evidence**
  - `_HighlightLayerState` listens to the controller (every keystroke and selection change) and recomputes `rectsForRange` for up to 2,000 find matches and 50 remote selections (`features/editor/layers/editor_layers.dart:79-80, 121-145`).
  - Each match does line walking plus `getRectForSelection` (`layers/document_geometry.dart:48-86`).
  - Spec §36.2 requires a viewport prefix-offset index and binary search. It also says remote selections are capped at 20; the code allows 50.
- **Recommended change.** Cache component offsets after layout, filter matches to `[scrollTop − 1 screen, scrollBottom + 1 screen]`, and recompute only on layout or scroll.

#### W-14 · Toolbar format state is O(selection length) on every rebuild
- **Severity** Med · **Category** perf · **Effort** S
- **Evidence**
  - `isFormatActive` walks `_pieces(s.start, s.end)`, which calls `substring` and `split('\n')` on every op in the selection (`features/editor/commands/write_editor_commands.dart:174-215`).
  - The toolbar asks for bold, italic, strike and code on each rebuild (W-01). After select-all on a large document, every rebuild therefore walks the whole document four times.
- **Recommended change**
  - Iterate over attribute runs without allocating substrings.
  - Exit on the first non-matching run.
  - Memoise per `(selection, contentVersion)`.

#### W-15 · Platform glue copied between Write, Slides and Sheets
- **Severity** Med · **Category** maintainability · **Effort** S–M
- **Evidence**
  - `features/editor/dnd/external_drop.dart`, `external_drop_web.dart` and `external_drop_io.dart` (237 lines) are identical to `wonky_slides/lib/features/elements/image/external_drop*.dart`, apart from doc comments. `diff` shows only a comment change.
  - `features/print/pdf_view_web.dart` / `pdf_view_io.dart` are near-identical to Slides' versions; Slides adds a `page` parameter.
  - `features/editor/paste/system_clipboard*.dart` exist in Write, Slides and Sheets: 133 / 217 / 154 lines.
  - `print_preview_screen.dart` exists in all three apps.
  - The `printPdf` fallback bug (W-20) is duplicated in both copies.
- **Recommended change.** Move these into `packages/wonky_app` (or a small `wonky_platform` package): external drop, PDF view and print, and the system clipboard with per-app MIME hooks.

#### W-16 · Two `DeltaSelection` types and two undo-stack rebasers
- **Severity** Med · **Category** maintainability · **Effort** M
- **Evidence**
  - The app's `DeltaSelection(base, extent)` is in `features/editor/applier/delta_applier.dart:28-83`. The core's `DeltaSelection(anchor, head)` is in `wonky_write_core/lib/src/delta/ot.dart:22-56`.
  - 20 files in `wonky_write` need `hide DeltaSelection` / `show DeltaSelection` to cope.
  - `WonkyOt.rebaseStack` and `WonkyOt.transformPair` (core) are only referenced by tests. The app reimplements the same algorithm in `rebaseWriteStacks` (`features/document/write_undo.dart:119-141`).
- **Recommended change.** Use the core `DeltaSelection`, adding a `transform` extension for the editor's semantics. Implement `rebaseWriteStacks` with `WonkyOt.rebaseStack`, or delete the unused core API.

#### W-17 · Testing gaps
- **Severity** Med · **Category** testing · **Effort** M–L
- **Evidence**
  - **No tests for:**
    - `features/tables/table_editor.dart` (776 lines) and `editor/tables/inline_table_editing.dart` (559)
    - `features/links` (372)
    - `features/outline` (405)
    - `features/print` (581)
    - `features/word_count` (196)
    - `lib/mcp/ui_write_tools.dart` (330; only the e2e `journey_08`)
    - the app `SuggestionRewriter` (see W-08)
  - The theme editor has 5.7k lines and 3 test files.
  - **Command coverage.** Suite 08 §4 and 04 §43 require execute → undo → redo for *every* command. There is no generic sweep over the catalog: about 268 distinct `'write.*.*'` ids appear in `lib`, and only 52 appear in `test`. The round-trip helper in `write_editor_commands_test.dart:20-35` is used per test.
  - **No goldens.** Zero `matchesGoldenFile` in `wonky_write/test`, while 04 §43 asks for light and dark goldens for components, layers and the Pages/Pageless canvas.
  - **No performance benchmarks** (04 §36).
  - The core property test for the Markdown round-trip is 37 lines (`test/property/markdown_round_trip_test.dart`).
  - No dedicated tests for `InlineMarkdown`, `FrontMatter` or `CssWriter`.
- **Recommended change**
  - Add a catalog-driven command test: for each `write.*` command with a fixture document and selection, execute, undo and redo, then assert structural equality and the selection.
  - Add a `bench_100_pages` profile benchmark covering keystroke, select-all, toggling a format and opening the document.
  - Add a handful of goldens.
  - Add table-editor and link-editor widget tests.

#### W-18 · God files (largest hand-written files)
- **Severity** Med/Low · **Category** maintainability · **Effort** M each

**App** (lines, file, suggested split):

| Lines | File | Suggested split |
|---|---|---|
| 1661 | `features/editor/commands/write_editor_commands.dart` | It already has §-sections (inline formatting 150, blocks/lists 300, links 612, insertions 763, code 949, block ops 1103, images 1305, tables 1362, selection/edit 1411). Make them `part` files or extension mixins on `WriteEditorCommands`. |
| 1560 | `features/sync/document_sync_controller.dart` | Connection/transport, outbox (`_Pending`/chunks/flush), the ordered-apply queue (remote and ack), resync/gap, cursor/presence. |
| 1371 | `commands/screen_commands.dart` | Already one function per menu (`fileCommands` 141, `findCommands` 222, `viewCommands` 417, `insertCommands` 534, `documentCommands` 962, `prefCommands` 1302). One file each. |
| 1296 | `features/theme_editor/theme_editor_screen.dart` | — |
| 1176 | `features/theme_editor/theme_inspector.dart` | Split per inspector section. |
| 1294 | `features/editor/ui/wonky_editor.dart` | Pickers/popovers (slash, mention, emoji, link card), the Pages glue (repagination, padded stylesheet, chrome), the reader/preview path, DnD wiring. |
| 1279 | `features/document/write_document_session.dart` | Undo persistence (`_saveUndo`/`_restoreUndo`/coalescing), offline open/reopen, `_SessionHost`, the sync event handling. |
| 1128 | `features/editor/components/wonky_components.dart` | One file per builder: image, table, paragraph/code chrome, task, embed, rule. |
| 1006 | `features/editor/commands/editor_command_catalog.dart` | — |

**Core:**

| Lines | File | Suggested split |
|---|---|---|
| 1939 | `import/rtf/rtf_importer.dart` | Tokenizer/reader `_RtfReader`, destination state/defs, mapping to IR. |
| 1604 | `export/pdf/pdf_exporter.dart` | Its own sections: runs 340, blocks 417, pagination 850, rendering 1035. |
| 1511 | `import/html/html_importer.dart` | Walker contexts vs inline buffer vs table/list handling. |
| 1476 | `theme/resolve/resolved_theme.dart` | Value classes; acceptable as is. |
| 1447 | `import/odt/odt_importer.dart` | — |
| 1299 | `export/rtf/rtf_exporter.dart` | — |
| 1263 | `import/docx/docx_importer.dart` | — |
| 1111 | `edit/document_edits.dart` | — |

`code_page_tables.dart` (1569) is data and fine as is.

### LOW

#### W-19 · Subscription to `controller.notices` is never cancelled
- **Severity** Low · **Category** bug · **Effort** S
- **Evidence.** `controller.notices.listen(_onNotice)` (`wonky_editor.dart:240`) never stores its subscription, and `_detach`/`dispose` don't cancel it (`:248-259, 270-286`). After a controller swap, the old controller keeps calling the state; only the `mounted` check guards it.
- **Recommended change.** Store the subscription and cancel it in `_detach`.

#### W-20 · Web PDF view and print leak resources
- **Severity** Low · **Category** bug · **Effort** S
- **Evidence**
  - `printPdf`'s hidden-iframe fallback appends an iframe and creates a blob URL, and never removes or revokes either (`features/print/pdf_view_web.dart:92-106`). Slides has the same code.
  - Each new `bytes` registers a fresh platform-view factory, which can never be unregistered (`:44-57, 60-66`).
  - The module-global `_current` is never cleared.
- **Recommended change.** Remove the iframe and revoke the URL on `afterprint` or after a timeout. Fix this once in the shared copy (W-15).

#### W-21 · Highlight cache is never pruned
- **Severity** Low · **Category** perf/memory · **Effort** S
- **Evidence.** `CodeHighlightStylePhase._cache` is keyed by node id and never pruned when nodes are deleted (`style_phases.dart:33, 77-89`). Each entry holds the full code text and token list.
- **Recommended change.** Prune entries whose node is no longer in the document during `style`.

#### W-22 · Debug-mode invariant checks make large documents unusable in debug builds
- **Severity** Low · **Category** DX/perf · **Effort** S
- **Evidence.** `verifyInvariants` defaults to `kDebugMode` (`extractor/change_delta_extractor.dart:88`; `applier/delta_applier.dart:98`). In debug, every transaction re-serialises the whole document three times, composes twice and compares (`change_delta_extractor.dart:185-216`). Agents and users run debug apps through `spawn_flutter_app`.
- **Recommended change.** Turn the checks on only in tests and for documents under about 2k nodes, or sample them (1 in N).

#### W-23 · About 96 hard-coded English strings
- **Severity** Low · **Category** a11y/i18n · **Effort** S–M
- **Evidence.** The strings are in tooltips, semantics labels and undo labels, which are visible in Undo history:
  - `wonky_components.dart:314, 323, 441, 484, 615, 630, 699, 783, 792, 802` ("Image unavailable", "Waiting for upload…", "Retry", "Edit table", "quote", "code block, …", "Copy code")
  - `write_editor_controller.dart:307-309` ("Typing", "Delete", "Edit")
  - `trigger_queries.dart:161`
  - `wonky_editor.dart:363`
  - `write_editor_commands.dart:1187, 1291, 1439`
  - the catalog labels in `editor_command_catalog.dart:514-880`

  The app has full l10n (`write_localizations*.dart`) and a pseudo-locale tool.
- **Recommended change.** Move these strings into the l10n files.

#### W-24 · Link scheme policy differs between modules
- **Severity** Low · **Category** consistency · **Effort** S
- **Evidence.** `LinkUrlPolicy.allowedSchemes` = {http, https, mailto, tel, wonky} (`features/editor/model/link_url_policy.dart:34`). The shared `wonky_rich_text` link rules also allow `ftp` (`packages/wonky_rich_text/lib/src/links.dart:12`). The editor rejects `ftp:` links that import and MCP accept.
- **Recommended change.** Use one shared policy.

#### W-25 · Small hot-path inefficiencies
- **Severity** Low · **Category** perf · **Effort** S
- **Evidence**
  - Three trigger regexes ending in `$` run over the whole paragraph prefix on every controller notify (`plugins/trigger_queries.dart:117-129`). Matching only the last ~48 characters would do.
  - AI streaming builds the text by repeated string concatenation, which is O(n²) (`ai/write_ai_controller.dart:383`). Use a `StringBuffer`.
  - Some `RegExp` objects are built inside per-node loops (`import/html/html_importer.dart:495, 811`; `export/pdf/pdf_text.dart:320`). Hoist them to `static final`.
  - `DocumentMirror.entries` copies the whole list on every call (`mapping/document_mirror.dart:54`). It is currently unused, so delete it.

#### W-26 · Errors are silently swallowed in a few places
- **Severity** Low · **Category** bug-risk · **Effort** S
- **Evidence.** The app has 28 `catch (_)` blocks. Most are documented best-effort, but some swallow programming errors too:
  - `write_document_session.dart:490` (`_refreshItem`)
  - `screen/document_insights.dart:123`
  - `commands/screen_commands.dart:1137`
  - `theme_editor_screen.dart:63, 161`
  - `offline/pending_uploads.dart:258, 268`

  `_onMention` awaits the mention provider without a try (`wonky_editor.dart:288-301`), so a provider error becomes an unhandled async error.
- **Recommended change.** Catch the expected exception types, log the rest through `debugPrint` or a logger, and wrap provider calls.

#### W-27 · Two pagination algorithms
- **Severity** Low · **Category** maintainability · **Effort** S (document and test)
- **Evidence.** The editor pushes whole blocks (`features/editor/pagination/pagination.dart`). PDF, print and server page counts split at line level (`wonky_write_core/lib/src/layout/pagination_engine.dart`). The page count in the status bar can therefore differ from the exported PDF.
- **Recommended change.** Note this in the specs and add a test that bounds the difference for the bench fixture.

---

## Commands and undo compliance (specs/08)
- **Good.** Outside the editor's command, request and reaction layers, the only direct `editor.execute` call is `ClearComposingRegionRequest` in `write_document_controller.dart:533`, which is not a document change. Toolbar buttons call command ids (`write_toolbar.dart:60, 85, 348, 436, 528`).
  - Every local change goes through `localChanges` → `_recordUndo`, coalesced by key (`write_document_session.dart:817-886`).
  - Remote and resync changes go through `applyRemote`/`resetDocument` and rebase the stacks.
  - Meta changes have `WriteMetaUndoEntry`.
  - The super_editor history is disabled (`editor_pipeline.dart:41-42`).
- **Gaps**
  - The table editor keeps its own 200-step undo inside the dialog (`features/tables/table_editor.dart:190`), which the spec allows (§35).
  - The required "every command execute/undo/redo" test sweep is missing (W-17).

## Things done well
- `DocumentMirror` + `DeltaIndex` (a Fenwick tree) give O(log n) offset ⇄ position conversion. `ChangeDeltaExtractor` uses immutable node identity as anchors, a fast path for single text events, and diffs only the touched gaps (`extractor/change_delta_extractor.dart:261-369`). `DeltaApplier` is slice-based. `DocumentMirror.invert` avoids materialising the whole document.
- The stylesheet is memoised so the presenter is not recreated per keystroke (`wonky_editor.dart:752-768`). The reasons are well documented in comments, for example why style phases have no `dispose`.
- The schema guard is incremental, and marked reactions give separate undo steps, as the spec asks.
- Spellcheck is good engineering: incremental, caret block first, time-sliced to 8 ms, with a word cache and correct handling of suggested deletions (`features/spellcheck/write_spellcheck.dart`).
- Debug invariant checks on the extractor and applier, a sync convergence fuzz test and a live-server e2e test catch OT/mapping bugs early.
- Server imports run in an isolate. The HTML importer has a depth limit (`html_importer.dart:411, 561`). Input and result size limits exist (W-06 covers what they miss).
- Web-safe integer handling is called out and applied consistently, for example `0x1FFFFFFFFFFFFF` instead of `1 << 62`.
- The core package has good unit coverage of the normalizer, validator, codec, importers and exporters, and the tests follow Given/when naming.
