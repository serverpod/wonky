# Code-quality review: wonky_slides + packages/wonky_slides_core

Scope: `wonky_slides/lib` (~101.6k lines excl. generated l10n; +28.8k generated l10n),
`packages/wonky_slides_core/lib` (~60.4k), and their tests (232 test files, ~54k lines).
Read-only review; no files in the repo were changed. The sync protocol was looked at only for
perf and code quality. Every finding below was checked against the code; anything not checked
is marked **(speculative)**.

Severity: High / Med / Low. Effort: S (< 1 day), M (1–3 days), L (> 3 days).

---

## Prioritised findings

### H1 — Scene nodes are rebuilt for every element whenever a slide is re-resolved, so the per-element RepaintBoundaries don't help
- **Severity:** High · **Category:** perf · **Effort:** M
- **Evidence:**
  - `packages/wonky_slides_core/lib/src/model/resolve/slide_resolver.dart:199-206`: the memo is per slide revision. On a miss, `_resolve` (`:336-400`) calls `_resolveTree` for the slide, the layout and the master, which builds **new** `ResolvedElement` objects for every element, including unchanged ones and every master/layout decoration.
  - `packages/wonky_slides_core/lib/src/scene/builder/slide_scene_builder.dart:53,223-238`: the node cache is an `Expando` keyed by the `ResolvedElement` *instance*. Once a slide is resolved again, every lookup misses.
  - `wonky_slides/lib/features/stage/slide_stage.dart:206-207`: `_NodePainter.shouldRepaint` returns true when `!identical(old.node, node)`, so every element layer repaints.
  - The only test of node reuse builds twice from the *same* `ResolvedSlide` (`packages/wonky_slides_core/test/scene/slide_scene_builder_test.dart:65-81`), so the real case is never tested.
- **Why it matters:** any change that bumps the slide revision rebuilds every scene node on the slide and repaints every layer. That covers every 300 ms text commit, every speaker-notes commit (see H2), any remote edit, and any change to one element. Heavy elements are repainted although they did not change (3D GPU charts, images with blur or colour-matrix filters, large tables, code blocks). Spec 03 §2.4 (one RepaintBoundary per element, master/layout layer as a cached picture) is only met for animation frames, not for edits. The "cached picture of the master/layout layer" from §2.4 does not exist: master/layout decorations are re-resolved and rebuilt for every slide.
- **Recommendation:** make resolution reuse its output. Either:
  - (a) memoize `ResolvedElement` per `(SlideElementRec instance, parent frame, theme hash, placeholder chain revision)` in an Expando on the record, so unchanged rows produce the identical `ResolvedElement`; or
  - (b) key the builder cache by content: the record identity plus the identities of dependent rows (cells, code states, chart link) plus the context key.

  Resolve master/layout decorations once per (layout, theme, appearance) and share them across slides. Add a test: edit element B, then assert that A's node is `identical`.

### H2 — Render invalidation is too broad: deck, theme, order and slide-row changes invalidate far more than they affect
- **Severity:** High · **Category:** perf · **Effort:** M
- **Evidence:** `packages/wonky_slides_core/lib/src/model/index/deck_indexes.dart:60-104`
  - `DeckChanged` → `_globalRev++` for **any** deck column (`:66-70`). `DeckCols` (`packages/wonky_slides_core/lib/src/schema/slides_schema.dart:283-298`) includes `title`, `guidesJson`, `presentJson`, `defaultsJson` and `language`. Renaming the deck, dragging a guide or changing a present setting therefore invalidates every slide's resolution, scene and thumbnail.
  - `ThemeChanged` → `_globalRev++` (`:92-98`). This fires for any master/layout row and for any element owned by a layout or master (`deck_model.dart:450-465`). The spec (02 §11) says "a change to a layout bumps every slide **using it**", but here every slide is bumped. In masters mode, each drag commit re-renders every thumbnail.
  - `OrderChanged` → `_globalRev++` (`:79-81`), although slide number and skip are already part of `revision()` (`:167-171`).
  - `SlidesChanged` fires for any slide column, including `notes` (`slides_schema.dart:330`) and `timingsJson`. It drops `_order`, `_themes` and `_placeholders` and bumps the slide's render revision (`:71-78`). `DeckModel._invalidateOrder` also re-flattens and re-sorts all slides (`deck_model.dart:363-371,419`).

  Typing speaker notes commits every 300 ms (`wonky_slides/lib/features/notes/notes_edit_controller.dart:32,96,118`). Each of those commits rebuilds every index, re-records the slide thumbnail and rebuilds and repaints the canvas scene (H1), although notes are not drawn on the slide.
- **Recommendation:**
  - Carry changed columns per row in `SlidesChanged` (as `DeckChanged` already does).
  - Bump render revisions only for render-relevant columns: deck `width/height/appearance/themeId/showSlideNumbers/hideNumberOnTitle/firstSlideNumber/footerText`; slide everything except `notes/timingsJson`.
  - On `ThemeChanged`, bump only the slides whose effective layout/master/theme is affected (ThemeIndex has the usage data).
  - Drop `_order` only when `sortKey/groupId/skipped/layoutId` change.
  - Add tests: thumbnails of other slides survive a deck rename, a guide move and notes typing.

### H3 — Unbounded decoded-image memory: full-resolution decodes, a count-based LRU and a separate cache per renderer
- **Severity:** High (memory on web; the risk of a tab crash is **speculative**, not measured) · **Category:** perf/memory · **Effort:** M
- **Evidence:**
  - `wonky_slides/lib/features/stage/slide_image_cache.dart:20-23,39-44`: `instantiateImageCodec(bytes)` is called without a `targetWidth`. The LRU is bounded by **count** (64), not by bytes. Bitmaps can be up to 40 MP (`features/elements/image/image_rules.dart:39-40`), which is about 160 MB RGBA each.
  - `wonky_slides/lib/features/stage/slide_renderer.dart:42` creates a new `SlideImageCache` per `SlideRenderer`. Extra renderers, each decoding the same images again:
    - one per Design idea (`features/ai/design_ideas_panel.dart:167`), plus a full `copyDeck` each;
    - two in the AI preview (`features/ai/ai_preview_dialog.dart:98,167`);
    - two in the version view (`features/history/slides_version_view.dart:139`);
    - 10 static template renderers that are never disposed (`features/templates/template_preview.dart:26-40`).
  - `wonky_slides/lib/features/uploads/slides_image_service.dart:51,90,226`: `_local` keeps the raw bytes of **every image inserted or copied in the session** and never removes them (only the downloaded LRU is bounded to 64 MB, `:285-292`).
  - Thumbnail pictures retain the images they drew. 400 pictures (`thumbnails/slide_thumbnail_cache.dart:30`) can therefore keep images alive after the image LRU has evicted them **(speculative; depends on engine refcounting)**.
- **Recommendation:**
  - Switch to a byte budget (e.g. 256 MB, smaller on mobile web).
  - Decode at the needed size (`targetWidth` bucketed by frame × zoom × DPR; small decodes for thumbnails).
  - Share one refcounted decoded-image cache per deck/editor across all renderers.
  - Drop `_local` bytes once the upload is complete (the queue or the downloaded LRU then serves them).

### M1 — A failed image load is permanent: offline and transient errors never retry
- **Severity:** Med · **Category:** bug · **Effort:** S
- **Evidence:**
  - `slide_image_cache.dart:105-110,121-126`: any null bytes or exception adds the image to `_failed`, and `imageOf` (`:54`) never retries a failed image.
  - `retry()` (`:130`) and `hasFailed()` (`:59`) have **no callers** in `lib`.
  - The bytes come from `SlidesImageService.bytes`, which returns null on offline/HTTP errors (`slides_image_service.dart:262-266`) and on any non-200 (`:304-305`).
- **Why it matters:** opening a deck offline, or a single 5xx, leaves images blank until the deck is reopened, even after the connection comes back.
- **Recommendation:** tell "not found / no access" apart from transient errors. Retry transient ones with backoff and clear failures on `connectivity` regained (the service already listens to connectivity through its queues), then `notifyListeners`. Add a test.

### M2 — Remote image polling outlives the deck
- **Severity:** Med · **Category:** bug/leak · **Effort:** S
- **Evidence:** `slides_image_service.dart:294-318`: `_remote` polls `getUrl` for up to **1 hour** per image (another user's pending upload) and cannot be cancelled. `SlidesImageService` (Expando per editor, `:34-40`) has no `dispose`, and the loop checks no disposed flag.
- **Recommendation:** add `dispose()` (called from `deck_editor_screen.dart:160-180`) that cancels the polls. Check the flag in the loop, and stop polling while the image is not visible.

### M3 — The canvas rebuilds its whole subtree on every pointer move; the moving element repaints fully instead of re-compositing
- **Severity:** Med · **Category:** perf · **Effort:** M
- **Evidence:**
  - `wonky_slides/lib/features/canvas/slide_canvas.dart:985-993`: one `ListenableBuilder` over `ed`, `c`, the text-editing state, `renderer` and `images`. `c` notifies on every transform update (`slide_canvas.dart:394-397`; `slide_canvas_controller.dart:170-173`), and also on hover handle, tool hover and guide changes.
  - Each rebuild creates:
    - a new `SlideStage` with N `Positioned`/`RepaintBoundary`/`CustomPaint` children (`slide_stage.dart:99-124`);
    - per-element semantics with `ReadingOrder.of` (`slide_canvas.dart:1123-1170`);
    - rulers and scrollbars;
    - a fresh `UserGuides.decode` JSON parse (`slide_canvas.dart:165-166,1094`).
  - `CanvasOverlayPainter.shouldRepaint` compares `old.guides != guides` on a new list each build, so it is always true (`canvas_overlay_painter.dart:473-477`). The painter already has `repaint: c`.
  - The moving element gets its transform through `ElementVisualState` and `_NodePainter` re-executes its whole paint on each move (`slide_stage.dart:178-215`; `slide_canvas_controller.dart:309-332`). Spec 03 §2.4 says "only the moving elements' boundaries repaint (transform layer)".
  - The existing `test/features/canvas/canvas_perf_test.dart:16-64` measures only `previewFrame()`.
- **Recommendation:**
  - Split the listenables: the stage listens to renderer/images and a `ValueListenable<SlideFrame>` for the live preview; the overlay is its own `CustomPaint(repaint: c)` outside the builder; semantics and rulers rebuild only on scene or selection changes.
  - Put the live transform into a `Transform` widget around the moving element's `RepaintBoundary`, so the cached layer is re-composited instead of repainted.
  - Cache the decoded guides per `guidesJson`.
  - Add a widget test that counts node paints during a drag.

### M4 — The editor paints every element twice, through a full-layer `saveLayer`
- **Severity:** Med · **Category:** perf · **Effort:** S
- **Evidence:** `wonky_slides/lib/features/stage/slide_stage.dart:182-198`. With `offSlideOpacity` set (always, on the editor canvas: `slide_canvas.dart:1056-1057`), each node paints once inside an even-odd clip plus `saveLayer(null, …)` and once clipped to the slide. This happens even when the element lies fully inside the slide.
- **Recommendation:** compute the node's bounds (frame plus rotation, stroke and shadow margin; the frames are in `scene.frames` / `ResolvedElement.frame`). Take the dual path only when the bounds cross the slide edge, and pass explicit bounds to `saveLayer`.

### M5 — The thumbnail cache fills with stale pictures and never disposes them
- **Severity:** Med · **Category:** perf/memory · **Effort:** S
- **Evidence:**
  - `slide_renderer.dart:385`: the key includes `revision(slideId)`, so every commit (every 300 ms while typing) adds a new entry for the same slide. The old entries stay until the LRU (400) drops them, which evicts valid thumbnails of other slides.
  - `slide_thumbnail_cache.dart:51-85`: evicted and cleared `ui.Picture`s are never `dispose()`d.
  - `invalidate()` (`:80-82`) has no callers in `lib`.
- **Recommendation:** key by `slideId|width|appearance`, store the revision in the entry, and replace the entry in place. Dispose the replaced picture after the next frame (or refcount it with the painters).

### M6 — The element-kind handler API is dead, and the canvas switches on the element kind, contrary to spec 03 §1.1/§1.3
- **Severity:** Med · **Category:** maintainability · **Effort:** S (delete + update the spec) / L (implement)
- **Evidence:**
  - `wonky_slides/lib/features/elements/element_kind_handler.dart:80-160` (`ElementKindHandler`, `ElementKindRegistry`) and `features/stage/core_scene_handler.dart` (`CoreSceneBuilding`) are referenced only by two tests (`test/features/elements/element_kind_handler_test.dart`, `test/features/stage/core_scene_handler_test.dart`). No handler is registered anywhere.
  - Meanwhile 77 `record.kind` checks spread over 39 files, among them `slide_canvas.dart:569,588,669,777,903`, `slide_canvas_controller.dart:395,523,572,581` and `canvas_tools.dart:339`.
- **Recommendation:** decide. Either delete the API and write the "as built" decision into 03 §1 (AGENTS.md: update the spec in the same change), or move the per-kind behaviour (box hit, aspect lock, activation, extra handles, min size) into registered handlers.

### M7 — Large near-duplicates of Sheets code that belong in shared packages
- **Severity:** Med · **Category:** maintainability · **Effort:** M–L
- **Evidence** (unique non-blank lines after normalising Sheets/Slides names):
  - `wonky_slides/lib/features/uploads/slides_pending_uploads.dart` vs `wonky_sheets/lib/features/import_export/pending_uploads.dart`: 317 of 355 lines in common (~90 %).
  - `features/elements/image/image_clipboard_web.dart` is identical to `wonky_sheets/lib/features/images/image_clipboard_web.dart`, apart from names.
  - `features/history/local_conflicts.dart` (664 lines) shares ~180 lines with Sheets'.
  - `features/history/slides_version_view.dart` shares ~190 lines with `sheets_version_view.dart`.
  - Within Slides, the per-user `_Installation` pattern is duplicated in `features/clipboard/rehome_queue.dart:265-320` and `features/uploads/slides_pending_uploads.dart:425-500`.
- **Recommendation:**
  - Extract a generic `PendingUploadQueue` plus a store interface and a `PerUserInstallation<T>` helper into `wonky_app` (Write's `features/offline/pending_uploads.dart` is a third variant).
  - Move the image clipboard into `wonky_app`.
  - Move the shared conflict-tracking core into `wonky_sync_kit_flutter`.

### M8 — PDF export does heavy image work on the UI isolate, again for every variant
- **Severity:** Med · **Category:** perf · **Effort:** M
- **Evidence:** `packages/wonky_slides_core/lib/src/export/pdf/slides_pdf_exporter.dart:790-858`.
  - `img.decodeImage`, `copyResize`, `_applyMatrix`, `gaussianBlur` and `encodeJpg` run in pure Dart and yield only every 8 images (`:812`).
  - `decoded` caches only the bytes. The `img.Image?` slot of the record is always `null` (`:791-802`), so the same source is decoded once per (matrix, blur) variant.
- **Recommendation:**
  - On native, run image preparation in `Isolate.run`. On web, process in smaller chunks with time-sliced yields, or use a worker.
  - Cache the decoded `img.Image` per source.
  - Skip re-encoding when no transform is needed and the image is already ≤ `maxPx`.

### M9 — Testing gaps around rendering and invalidation
- **Severity:** Med · **Category:** testing · **Effort:** M
- **Evidence:**
  - No golden tests at all: 0 `.png` files and no `matchesGoldenFile` under `wonky_slides/test` or `packages/wonky_slides_core/test`, although the `golden` tag is declared in `wonky_slides/dart_test.yaml`.
  - No test for node identity across re-resolution (H1), for thumbnail survival across unrelated changes (H2/M5), for retrying failed images (M1), or for paint counts during a drag (M3).
  - Feature folders with no or only one test reference: `features/page_setup` (625 lines, 0), `features/transitions` (1,091, 1), `features/masters` (1,457, 1), `features/layouts` (227, 1), `features/toolbar` (437, 1), `features/grid_view` (974, 1).
- **Recommendation:**
  - Add a small set of `golden`-tagged stage, thumbnail and PDF-raster goldens (excluded by default, as in core).
  - Add the regression tests listed above.
  - Add widget tests for page setup (scale content, units) and the transitions/masters inspectors.

### L1 — Dead code and stale placeholders
- **Severity:** Low · **Category:** maintainability · **Effort:** S
- **Evidence:**
  - `wonky_slides/lib/commands/placeholder_commands.dart` (344 lines): 36 of its 43 placeholders have a real command with the same id and are dropped at registration, so they are dead. Only 7 are still in use: `importSlides`, `present.rehearse`, `present.remote`, `toggleSnapGrid`, `insert.chart`, `notifications.openSettings`, `ai.codeWalkthrough`. The file header says the list "only shrinks by deletion", yet it was never pruned.
  - `features/present/broadcast/present_fast_path.dart` (207 lines) is used only by `test/features/present/present_fast_path_test.dart` (SL-41 is on hold).
  - `SlideThumbnailCache.invalidate`, `SlideImageCache.hasFailed` and `retry` are unused.
- **Recommendation:** delete the 36 overridden placeholders. Keep the fast path behind its feature or move it to a branch, and either delete the unused cache APIs or wire them up (M1, M5).

### L2 — Hidden features are still compiled and shipped, and the feature switch is mutable global state
- **Severity:** Low · **Category:** maintainability/DX · **Effort:** S
- **Evidence:**
  - `wonky_slides/lib/config/slides_features.dart:119,135`: `static Set<SlidesFeature> enabled = shipped` is mutable and tests flip it, so a missing `reset()` leaks between tests.
  - Gating happens at runtime (`registers` / `offers` / `prune`), so the code behind off features is shipped and cannot be tree-shaken. That code is small today: the 7 placeholders, the rehearsed-timings readers (`present_controller.dart:541-575`, `presenter_view.dart:698-750`) and the `editorPreferences` settings branch (`features/settings/slides_settings.dart:129,277-286`).
- **Recommendation:** fine as it is for now. Make `enabled` injectable (for example a `SlidesFeatures.override` in a test zone), or add a `tearDown` guard in the test harness.

### L3 — God files (largest files that are not generated or data)

| File | Lines | Suggested split |
|---|---|---|
| `packages/wonky_slides_core/lib/src/export/pdf/slide_pdf_painter.dart` | 1624 | One file per section already marked by `// ----` banners: fonts (`SlidesPdfFonts`), paths/fills, text, images, tables/code/charts, callouts |
| `wonky_slides/lib/features/navigator/slide_navigator.dart` | 1474 | rows (329-885), drag/indicators (885-1176), keyboard (1194-1291), footer and rename field, `DashedBorderBox` into `wonky_ui` |
| `wonky_slides/lib/features/history/slides_version_view.dart` | 1424 | `_VersionBar`, `_AuthorLegend`, `_VersionNavigator` into separate files; share the version bar with Sheets (M7) |
| `wonky_slides/lib/features/themes/editor/theme_editor_sections.dart` | 1414 | one file per section, plus the previews (`_TablePreview`, `_PaletteSwatch`, `_ChartPreview`) |
| `wonky_slides/lib/features/present/present_controller.dart` | 1388 | follower sync (396-516), kiosk/auto-advance (516-610), prefetch (610-826), tools/ink (912-1092) as collaborators |
| `wonky_slides/lib/commands/canvas_commands.dart` | 1364 | by area: zoom/view, selection, transforms, guides |
| `wonky_slides/lib/features/outline_view/outline_view.dart` | 1319 | `_OutlineSlideBlock` (with sync, soft locks, writes, keys) into its own file; `_RunsController` |
| `wonky_slides/lib/features/canvas/slide_canvas.dart` | 1272 | gesture state machine, semantics layer, rulers/scrollbars and build as separate parts (also fixes M3) |
| `wonky_slides/lib/commands/text_commands.dart` / `table_commands.dart` | 1250 / 1247 | by sub-area (format, lists, links / axes, cells, borders) |
| `wonky_slides/lib/commands/navigator_commands.dart` | 1208 | slides vs groups vs notes zoom |
| `packages/wonky_slides_core/lib/src/scene/builder/slide_scene_builder.dart` | 1203 | `_TableLayout`/`_CellText` (855-1203) into `table_scene.dart`; lines/connectors; text/shape |
| `wonky_slides/lib/features/clipboard/deck_clipboard.dart` | 1175 | copy, read, paste targets and file re-homing (sections at 131/278/334/686/1052) |

Data or catalogue files are fine at their size: `lucide_glyphs.g.dart`, `shape_library.dart` (1590), `effect_catalog.dart` (1240), `slides_menu_spec.dart` (1043).

### L4 — Micro-costs on hot paths
- **Severity:** Low · **Category:** perf · **Effort:** S
- **Evidence:**
  - `SlideCanvasController.scene/slide/elements` (`slide_canvas_controller.dart:267-288`) recompute `renderer.scene` keys and the `revision()` string, which calls `order.entry` (`slide_renderer.dart:327-345`; `deck_indexes.dart:167-171`), on every access. They are accessed many times per pointer event: `hitPath`, `frameOf` per element, the overlay paint.
  - `FlutterTextLayoutEngine` builds its key from `'${body.toJson()}…'`, which stringifies the whole delta on every lookup (`features/stage/flutter_text_layout_engine.dart:47-49`). Its 512-entry cache (`:18`) is smaller than one full-deck thumbnail pass on a 100-slide deck.
  - `SlideRenderer._memo` evicts FIFO, not LRU (`slide_renderer.dart:365`).
- **Recommendation:** cache the current scene/slide per renderer notification, key text layouts by body identity plus a hash, raise the cache size or scale it with deck size, and make `_memo` an LRU.

### L5 — The presenter view rebuilds its whole tree every second
- **Severity:** Low · **Category:** perf · **Effort:** S
- **Evidence:** `wonky_slides/lib/features/present/presenter_view.dart:69-71` calls `setState` from a 1 s `Timer.periodic`. That rebuilds the header, both `PresentStage`s, the strip of thumbnails and the notes, only to update the clock and the timers.
- **Recommendation:** move the clock and timers into their own small widget with their own ticker or `ValueListenable`.

### L6 — Smaller risks (mostly speculative)
- **Severity:** Low · **Category:** bug/perf · **Effort:** S each
- The snapshot cache key uses `identityHashCode(frame)` (`features/transitions/slide_snapshots.dart:52-54`). Frames that are equal but are different instances miss the cache, and a hash collision could return the wrong image **(speculative)**. Evicted snapshots are disposed (`:69-71`) while a transition painter may still hold them **(speculative)**.
- `SlideImageCache` may thrash when more than 64 distinct images are needed at once, for example a grid view of image-heavy slides or one slide with more than 64 images. Every decode notifies all painters, the painters request the evicted images again, and the loop repeats **(speculative)**.
- `DeckModel.applyChanges`: a listener that throws stops the remaining listeners and the stream (`packages/wonky_slides_core/lib/src/model/api/deck_model.dart:349-354`), which leaves the indexes or the renderer stale.
- `ChartLinks._maintain` awaits the network and then writes without checking whether the session was disposed (`features/elements/chart/chart_links.dart:276-285,370-376`) **(speculative)**.
- After every merge, maintenance runs `DeckMaintenance.repairOp(model)` over the whole deck, debounced by 1 s (`features/model/synced_deck_session.dart:380-398`). That is O(deck) while collaborating on big decks **(speculative cost)**.

---

## Commands and undo compliance (spec 08)
The code complies. Every user-visible mutation goes through `DeckEditorController.apply(ctx, op)` inside a command transaction (`features/editor_screen/deck_editor_controller.dart:660-674`). Clipboard, find & replace and spelling all pass `ctx`. Typing in text, notes and code is written as coalesced typing steps (`recordTypingStep`). The only writes outside commands are maintenance writes, which the spec intends to be non-undoable: chart token refresh and auto-update (`chart_links.dart:370`) and deck repair (`synced_deck_session.dart:389`). No violations were found. Viewport, zoom and selection are correctly kept out of undo.

## Accessibility
No significant issues found. The canvas exposes one semantics node per element in reading order with selection and lock state (`slide_canvas.dart:1123-1170`). The navigator and grid rows carry slide/group labels (`slide_navigator.dart:429-441,601-605`; `slide_grid_view.dart:307-310,406-410`), and there are 134 `Semantics` sites in total. An accessibility checker ships.

## Things done well
- **A clean split between core and app.** A pure-Dart core (`DeckModel`, resolver, scene builder, planner, PDF) is shared by the editor, presenting, thumbnails, the server/MCP and export, so headless and UI edits use one planner.
- **Selective, lazy index invalidation** with `DeckIndexes`, memoized resolution, and Expando caches for theme data, paths and paragraphs (`scene_painter.dart:63-65`). A seeded property test checks that incremental patching equals a reload.
- **Thumbnails are recorded `ui.Picture`s** in an LRU, re-recorded only when images arrive (the `complete` flag), with benchmark tests (`thumbnail_benchmark_test.dart`, `text_edit_benchmark_test.dart`, `canvas_perf_test.dart`, `magic_move_budget_test.dart`).
- **`FrameDiff`** restricts repaints during animations to elements whose visual state changed (`features/motion/render/frame_diff.dart`).
- **Lazy lists.** The navigator uses `ListView.builder` with `itemExtentBuilder`, and the grid view builds only the visible rows.
- **Disposal discipline is good.** Every `addListener` imbalance found is an app-lifetime singleton (font watchers, per-user queue installers). Timers in present mode are cancelled. Async UI code checks `mounted` and `_disposed` consistently, and no `setState` after `await` without a `mounted` check was found.
- **Feature gating is consistent** across commands, menus, the palette and MCP (`SlidesFeatures.prune/registers`).
- **Tests are broad:** 232 test files (~54k lines), including planner, sync, property and MCP tests.
