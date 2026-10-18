# Code-quality review: wonky_drive, wonky_charts(_flutter), wonky_code(_flutter), wonky_mcp_stdio, third_party

Read-only review (nothing in the repo was modified). Each finding below was verified by reading the code, unless it is marked **(speculative)** or **(from sub-investigation)**. Paths are relative to the repository root.

Slice size (Dart lines, lib / test):

| Package | lib | test |
|---|---|---|
| wonky_drive | 9.5k + 3.3k generated l10n | 5.1k |
| wonky_charts | 19.3k | 4.9k (another ~3.8k in `wonky_sheets_core/test/charts`) |
| wonky_charts_flutter | 3.0k | 0.4k |
| wonky_code | 7.0k | 2.7k |
| wonky_code_flutter | 1.2k | 0.5k |
| wonky_mcp_stdio | 0.5k | 0.6k |
| third_party | super_editor 98.6k, dart_eval 44.8k, serverpod_offline_sync 26.4k, attributed_text 2.5k | |

## Prioritised findings

### High

**TP-1 · `serverpod_offline_sync` fork is behind upstream, has no tests, and its patches are only partly marked** — High · maintainability/testing — Effort: L
- Evidence:
  - The vendored version is 0.0.9 (`third_party/serverpod_offline_sync/pubspec.yaml:2`). Upstream released 0.0.10 and 0.0.11 on 2026-10-09, three days before the copy was vendored. The upstream changelog overlaps OS-1 (Serverpod 4.1 `watch`) and probably OS-2 (web transaction hang). It also adds concurrent-edit, reconnect and unique-conflict fixes that the fork lacks.
  - The hosted `serverpod_offline_sync_server`/`_client` are pinned exactly to 0.0.9 (`wonky_server/pubspec.yaml:25-26`, plus the client pins), so all three packages must move together.
  - The package has no test directory. CI skips it (`.github/workflows/tests.yml:129`).
  - Patches OS-5…OS-9 use bare `// OS-n` comments, not the required `// WONKY PATCH` marker. Examples: `lib/src/database/database.dart:1027` and `merge_utils/foreign_key_projector.dart:435,634`. Only OS-1, OS-2 and OS-4 carry markers (`database.dart`, `merge.dart`).
- Why it matters:
  - This is the data-integrity-critical sync engine for Sheets and Slides.
  - OS-7 (set-based `bulkWrite`) and OS-9 (resumable projection rebuild) are large semantic rewrites.
  - The next re-sync is a three-way merge, and a `WONKY PATCH` search misses half of the patches.
- Recommendation:
  1. Re-mark OS-5…OS-9 now (S).
  2. Add a `test/wonky_patches_test.dart` for OS-4…OS-9, running on SQLite in CI.
  3. Plan a rebase onto 0.0.11, dropping OS-1/OS-2 where upstream covers them.
  4. Upstream OS-4…OS-9. The package is Serverpod-owned, and §2.3 rule 5 says to fix upstream.

**TP-2 · `dart_eval` fork pins the whole workspace to analyzer 8.x** — High · maintainability — Effort: L *(from sub-investigation, spot-checked)*
- Evidence:
  - `third_party/dart_eval/pubspec.yaml:30` requires `analyzer: ^8.2.0`. Newer analyzers (13.x/14.x) are already in the pub cache.
  - 21 interpreter and compiler patches (DE-1…DE-21) are not upstreamed (PATCHES.md).
  - The docs are stale: `specs/01-architecture.md:391` says "DE-0…DE-19", and `packages/wonky_sheets_script/pubspec.yaml:14` says "DE-1..DE-3".
  - There is no upgrade section and no archive SHA in VENDORED.md.
- Why it matters:
  - Upstream has a single maintainer.
  - The analyzer pin drags every workspace member: lints, `analyzer`-based tooling and SDK bumps.
  - Porting to a newer analyzer is roughly 90 call sites (per VENDORED.md).
- Recommendation:
  1. Budget the analyzer port as its own work item.
  2. File the correctness fixes DE-4…DE-20 upstream.
  3. Add the upgrade procedure and archive hash to VENDORED.md.
  4. Fix the two stale references.

**DR-1 · Picked files are read fully into memory before the size, count and quota pre-check** — High · bug/perf — Effort: S
- Evidence:
  - `wonky_drive/lib/features/uploads/drive_upload_handler.dart:31-37` does `bytes: await f.readAsBytes()` for every picked file.
  - Only afterwards does `runUploadBatch` reject files: the batch-count limit (`upload_batch.dart:48`) and `UploadPlan.of(... maxFileBytes ...)` (`upload_batch.dart:58-66`).
  - `UploadFile.bytes` is required (`upload_queue.dart:13-31`).
- Why it matters: the quota is 50 MB per user, but nothing stops a user from picking a 2 GB video. The browser tab reads all of it into the Wasm/JS heap before showing "too large", which risks an out-of-memory crash. Picking 1,000 files reads them all before the batch-count check.
- Recommendation:
  - Pre-check on `PlatformFile.size` and the file count before reading.
  - Make bytes lazy, e.g. `Future<Uint8List> Function() read`, or read only accepted files.
  - Apply the same fix to the shell's drop path (it also builds `ImportFile` with bytes).

### Medium

**DR-2 · Cancelling an upload while `createFileUpload` is in flight leaks the server reservation** — Med · bug — Effort: S
- Evidence:
  - `UploadQueue.cancel` releases the server side only when `_created.remove(id)` is true (`upload_queue.dart:349-356`).
  - `_created.add(t.id)` happens only after `api.create` returns (`upload_queue.dart:502-514`). The next line sees `!_stillWanted` and returns (`:515`) without cancelling.
  - Result: when cancel lands during `starting`, `api.cancel` is never called and the id stays in `_created` forever.
  - Similarly, cancel during `verifying` (`:538-541`) fires `api.cancel` concurrently with `api.complete`. The item may finish on the server while the row shows "cancelled".
- Why it matters: a pending upload reserves quota and counts toward `drive.maxPendingUploadsPerUser` (`wonky_server/lib/src/platform/files/file_service.dart:544`, `drive_file_service.dart:897`). The user's free space shrinks until the server's 24 h expiry. This is visible on a 50 MB quota.
- Recommendation: after `create` returns, if `abort.aborted`, call `api.cancel(t.itemUuid)` (best effort) before returning. Do the same after `complete` returns for a cancelled task (trash the item, or keep it and mark it done). Add a queue test: "cancel during starting releases the reservation".

**CH-1 · Hovering a 3D chart re-renders it on the GPU on every mouse move and rebuilds all meshes when the hovered bar changes** — Med · perf — Effort: M
- Evidence:
  - Hover calls `setState` for every pointer move while a tooltip shows. It does this in the shared view (`_hoverAt != p`, `packages/wonky_charts_flutter/lib/src/view/chart_view.dart:138-143`) and in Sheets (`wonky_sheets/lib/features/charts/view/chart_view.dart:208-214`).
  - The `CustomPaint` sits in the same `Stack` as the moving `ChartTooltip`, with no `RepaintBoundary` (`chart_view.dart:169-217`, Sheets `:249-326`). The painter therefore runs again.
  - 2D scenes replay a cached `Picture` (`chart_painter.dart:401-425`), but 3D scenes skip that cache and call `gpu.paint` (`:410-418`).
  - On the web, every `gpu.paint` renders the flutter_scene scene (shadow map 2048², AO) and does `picture.toImageSync` (`flutter_scene_renderer.dart:155-171`).
  - `meshHash` includes the hover (`packages/wonky_charts/lib/src/three_d/chart3d_scene.dart:108-111`), so moving to another bar runs `_rebuild`: `scene.removeAll()` plus new geometry for every mesh (`flutter_scene_renderer.dart:211-215, 252-316`).
  - `model.contentHash` is a getter that `toJson()`s every item on every call (`chart3d_model.dart:553-557`). It runs on every GPU frame via `sync()`.
- Why it matters:
  - The 08 §12 performance budget expects hover to be cheap.
  - On the web, each hover move costs a full GPU frame plus readback. Large 3D charts (surfaces, many bars) will stutter.
  - During orbit or animation, the per-frame `contentHash` serialisation adds allocation churn.
- Recommendation:
  1. Wrap the chart `CustomPaint` in a `RepaintBoundary` in both views. The tooltip then repaints alone.
  2. Implement the hover highlight as a material-colour change on the affected node(s) instead of a mesh rebuild: key meshes by (color, part) without hover, and keep a per-chunk node for data items.
  3. Cache `contentHash` (`late final`, since the model is immutable).
- Caveat: the per-move repaint follows from Flutter's paint semantics and was not measured. Confirm it with DevTools "highlight repaints".

**CD-1 · `CodeView` rebuilds every line span and re-scans every line on each rebuild** — Med · perf — Effort: S
- Evidence:
  - `build()` calls `styler.lineSpans(widget.code, _tokensFor())` (`packages/wonky_code_flutter/lib/src/code_view.dart:210`). This walks the whole text and allocates a substring and `TextSpan`s for every line (`code_text_styler.dart:52-99`).
  - The no-wrap path loops `styler.columnsOf(line)` over every line's runes in each `LayoutBuilder` pass (`code_view.dart:328-331`).
  - `_Metrics.of` lays out a `TextPainter` on each build (`:211, 399-408`).
  - Drive's `TextFileViewer` is a `StatelessWidget` that rebuilds the `CodeView` whenever the preview controller notifies: sibling list loaded, wrap toggle, font registration (`wonky_drive/lib/features/preview/viewers/text_file_viewer.dart:43-77`).
- Why it matters: a 1 MB text preview (~25k lines) pays O(file) allocation on every rebuild and resize. That eats into the "1 MB text highlighted < 300 ms" budget, even though the rows themselves are virtualised.
- Recommendation:
  - Memoise `spans` in state, keyed by (code, tokens identity, palette, tabSize, textStyle).
  - Memoise `columns` per code.
  - Better still, build each line's span lazily in `itemBuilder`, with a binary search into tokens as `CodeEditorField._span` already does.

**CD-2 · The code editor re-tokenises the whole text on every keystroke, synchronously** — Med · perf — Effort: M
- Evidence:
  - `CodeEditorFieldState._ensureTokens` runs on the first span build after each edit (`code_editor_field.dart:282-292`). It rebuilds `_lineStarts` over the full text and calls `tk.tokenize(text, language)` on the whole text.
  - The default tokenizer is TextMate, which the code itself documents as superlinear: about 0.7 s per 100k characters and 19 s per 500k (`text_file_viewer.dart:138-145`).
  - `CachedCodeTokenizer.shared` (64 entries) stores a full copy of the text and its token list per keystroke state (`cached_code_tokenizer.dart:41-61`).
  - `didUpdateWidget` doesn't invalidate the cache when `widget.tokenizer` changes (`:222-229`).
- Why it matters: typing in a long code block (Slides code elements and other `CodeEditorField` users) gets laggy. The cache mostly holds states that are never revisited.
- Recommendation:
  - Debounce re-tokenisation (render with the stale tokens shifted by the edit, then re-tokenise after about 100 ms idle).
  - Or tokenise only from the first changed line, as TextMate supports per-line rule-stack resumption. `SpanParser` is copied in, so expose its line state.
  - Use a non-caching tokenizer for editing.
  - Reset `_tokensFor` when the tokenizer changes.

**DR-3 · Text and CSV previews download the whole file (up to 50 MB) to show the first 1 MB, and cache all of it** — Med · perf — Effort: S
- Evidence:
  - Every non-image preview fetches with `maxBytes: PreviewLimits.maxBytes` (50 MB) (`file_preview_controller.dart:274`) and caches the full body (`:275`).
  - `TextPreview.decode` then truncates to `PreviewLimits.textBytes` (1 MB) (`preview_content.dart:157-176`).
  - The cache budget is 100 MB of in-tab memory (`preview_content.dart:41`, `preview_cache.dart`).
- Why it matters: opening a 40 MB log costs 40 MB of transfer and 40 MB of RAM to display 1 MB. Browsing a few such files fills the 100 MB cache.
- Recommendation:
  - For text and CSV, send `Range: bytes=0-1048575` (signed storage URLs normally honour it), or set `maxBytes` to `textBytes` + 4 and treat overflow as truncated.
  - Consider lowering `cacheBytes` on the web.

**DR-4 · The Storage page fires one request per parent folder on each page load** — Med · perf — Effort: M
- Evidence:
  - `StoragePageController._resolveFolders` (`wonky_drive/lib/features/storage/storage_controller.dart:273-292`) issues `services.drive.get(p)` per distinct parent of the listed rows. Each call is unawaited and calls `_notify()` (a rebuild) when it resolves.
  - Failures are cached as `''` permanently (`onError: (_) => ''`), so a transient offline error leaves blank "Location" cells until a reload.
- Why it matters: one page can mean dozens of concurrent RPCs and rebuilds.
- Recommendation:
  - Return the parent folder name in the storage listing DTO (server join), or add a batch `drive.getMany`.
  - Don't cache failures.
  - Coalesce notifications.

**DR-5 · The upload and preview transport layers are untested** — Med · testing — Effort: M
- Evidence: there are no tests for:
  - `byte_sender_web.dart` (XHR progress, abort, multipart form)
  - `byte_sender_io.dart`
  - `ServerFilePreviewApi.fetch` (size limit on a declared or streamed body, `preview_api.dart:150-178`)
  - `ServerUploadApi.convert` (trash then delete) and `namesIn` paging
- The queue tests use fakes (`test/support/upload_fakes.dart`). `upload_queue_test.dart` has no case for cancelling during `starting` or `verifying` (see DR-2).
- Recommendation:
  - Unit-test `fetch` with a `MockClient` (oversized declared or streamed body, non-200 response).
  - Test `UploadDescription.parse`.
  - Add the two cancel-race cases.
  - Exercise the XHR sender in a browser integration test (`flutter test --platform chrome`).

**CH-2 · The chart engine's tests live in its consumer; the 3D GPU backend has none** — Med · testing — Effort: M
- Evidence:
  - The biggest layout files have no direct test in `packages/wonky_charts/test`:
    - `layout/layout_cartesian.dart` (2,127 lines)
    - `chart_layout_engine.dart` (944)
    - `layout_3d.dart` (882)
    - `layout_radial.dart`
    - `three_d/chart3d_mesh.dart` and `chart3d_scene.dart`
  - `three_d/` has only `chart3d_view_test.dart`. The pipeline and 3D tests stayed in `packages/wonky_sheets_core/test/charts/` (15 files, ~3.8k lines) after the extraction.
  - `wonky_charts_flutter` has 4 test files and 421 lines for 3k lines of lib. `flutter_scene_renderer.dart` (resource lifetime, LRU of 12 scenes, web image hand-off) is untested apart from `mesh_winding_test.dart`.
- Why it matters:
  - Slides depends on the engine too, so a change made from the Slides side gets no package-level safety net.
  - The GPU backend's dispose and LRU logic is exactly where leaks hide.
- Recommendation:
  - Move the engine-level tests (pipeline, 3D model and mesh, picking) into `wonky_charts/test`.
  - Keep only the Sheets data-resolution tests in `wonky_sheets_core`.
  - Add a unit test for `FlutterSceneChart3DRenderer`'s LRU and release with a fake `_GpuChart` (extract an interface).

**MS-1 · The MCP stdio proxy has no request timeout and gives up on the server stream for good** — Med (DX/robustness) · bug — Effort: S
- Evidence:
  - POSTs have no timeout (`packages/wonky_mcp_stdio/lib/src/stdio_http_proxy.dart:192`).
  - `_shutdown` waits for all in-flight requests (`:377-379`), so one hung request blocks exit forever.
  - After `maxReconnectAttempts` the GET listener returns, but `_listening` stays `true` (`:304-309`), so it never restarts, even after the server recovers.
  - The help text recommends `--token wkpat_…` on the command line (`bin/wonky_mcp_stdio.dart:15,20`), which exposes it in process lists and shell history.
- Recommendation:
  - Add a per-request timeout (or a cap at shutdown).
  - Reset `_listening = false` when giving up, so the next successful POST re-arms the listener.
  - Document `WONKY_TOKEN` via `claude mcp add -e` as the primary path.
  - Warn when a bearer token is sent over plain `http` to a non-localhost host.

**TP-3 · `super_editor` fork: 86 patch sites across a 98.6k-line pre-1.0 package, none upstreamed** — Med · maintainability — Effort: L *(from sub-investigation)*
- Evidence:
  - The fork is at 0.3.0-dev.52, which is current. Patches SE-1…SE-8 are documented in PATCHES.md, with 86 `WONKY PATCH` markers.
  - SE-2 (`ApplyDocumentPatchRequest`), SE-3 (detailed `NodeChangeEvent`s) and SE-6 (`ContentDragDelegate`) add API surface the app relies on.
  - CI runs the suite with `-x golden` (`.github/workflows/tests.yml:137`).
  - VENDORED.md:149-150 wrongly says `attributed_text` is not vendored.
- Recommendation:
  - Propose SE-2, SE-3 and SE-6 upstream first (the API additions are the costliest to carry).
  - Run the super_editor goldens at least nightly.
  - Fix the stale note.

### Low

**CH-3 · Scene caches key on hashes, and the specs hash by serialising** — Low · perf/correctness — Effort: S
- `ChartView._layout` caches the scene by `Object.hash(spec, data, theme, …)` and compares only the hash (`chart_view.dart:92-105`). The same pattern appears in `_GpuChart.sync` with `meshHash`.
- `SpecNode.hashCode` is `DeepCollectionEquality.hash(toJson())` (`packages/wonky_charts/lib/src/spec/spec_json.dart:19-20`), so every hover `setState` re-serialises the spec.
- `ChartTheme` and `ChartData` have identity equality, and Slides' insert dialog builds a new theme on each build (`wonky_slides/lib/features/elements/chart/chart_insert_dialog.dart:755-767`), so every rebuild re-lays out each tile.
- A hash collision would silently show a stale scene or mesh.
- Recommendation:
  - Compare the inputs with `identical` or `==`, and keep the hash only as a fast reject.
  - Cache `toJson`/`hashCode` on immutable spec nodes.
  - Have the dialog memoise `look`.

**CH-4 · The shared `ChartView` is barely shared; Sheets keeps its own 347-line copy** — Low · maintainability — Effort: M
- The package `ChartView` is used once in the repo: the Slides insert dialog (`chart_insert_dialog.dart:761`). Its doc comment still claims Slides present mode uses it (`chart_view.dart:16-18`), but Slides paints through `stage/scene_painter.dart`.
- `wonky_sheets/lib/features/charts/view/chart_view.dart` duplicates the hover, tooltip and GPU wiring (same CH-1 issue in both places).
- `ChartView.didUpdateWidget` doesn't release the old `gpuKey` when it changes.
- Recommendation:
  - Converge on one interactive chart widget with orbit and zoom hooks, or delete the generic one and keep a thin preview widget.
  - Fix the doc comment.

**CH-5 · 3D GPU errors are logged with a stack trace on every frame** — Low · DX — Effort: S
- `FlutterSceneChart3DRenderer.paint` catches, `debugPrint`s the error with its stack, and returns false each frame (`flutter_scene_renderer.dart:179-182`).
- A persistent failure, such as a lost WebGL2 context, floods the console. It also leaves the broken `_GpuChart` in the LRU, so it is retried every frame.
- Recommendation: after N failures for a key, release it and mark the key software-only. Log once.

**CH-6 · Global `FlutterTextMeasurer.instance` holds up to 2,000 laid-out `TextPainter`s for the app's lifetime** — Low · perf — Effort: S
- `chart_painter.dart:68-111`. On the web, each painter holds a native paragraph.
- The `_pictures` Expando (`:383`) keeps one `ui.Picture` per live scene; it is freed only by GC, never disposed.
- *(Speculative)* Memory pressure appears only with many charts. Consider a smaller capacity, or clearing on app background or route pop.

**CD-3 · The TextMate tokenizer swallows every error and returns no tokens** — Low · DX — Effort: S
- `textmate_tokenizer.dart:130-133` and `:170-172` use `catch (_) { return const []; }`. A grammar that fails to parse is cached as `null` forever.
- A broken grammar patch makes code silently plain, with no signal in logs or tests beyond `embedded_grammars_test.dart`.
- Recommendation: `assert`/`debugPrint` in debug mode, and add a test that every embedded grammar parses (verify that `embedded_grammars_test.dart` covers this).

**DR-6 · The preview reloads the folder listing (up to 5×200 items) plus the folder on every next/prev step** — Low · perf — Effort: S
- `_loadSiblings` always refetches (`file_preview_controller.dart:413-440`), even when `host.siblingsOf == parent` already supplied the list (`:416-420`).
- Paging through 50 images costs 50 listings.
- `filesIn` silently stops at 1,000 files (`preview_api.dart:119-139`), and `namesIn` at 2,000 (`upload_api.dart:363`). Beyond that, prev/next and the name-conflict check are quietly incomplete.
- Recommendation: refresh at most once per N seconds per folder, and document the caps or page lazily.

**DR-7 · Error handling in the upload and preview paths relies on `debugPrint`, which is stripped in release** — Low · DX — Effort: S
- Examples: `upload_queue.dart:175, 269, 354, 548, 664, 685`, `upload_api.dart:354` (a failed delete after conversion leaves the original in the trash), and `on Object {}` in `file_preview_controller.dart:364, 408, 426, 437`.
- None of these reach telemetry, so field failures are invisible.
- Recommendation: route them through the shell's logging or observability hook (11 §observability).

**DR-8 · Drive's specs are stale** — Low · maintainability — Effort: S
- `specs/wonky_drive/README.md` says "Nothing in this folder is built yet". It also says the site root opens Wonky Write's home, but `wonky_server/lib/src/web/web_apps.dart:11` redirects to `/drive/` (01 A2, B4).
- `specs/README.md` says v2 is "not implemented".
- Fix them in the next Drive change.

**MISC-1 · Hand-rolled LRU caches are duplicated across the repo** — Low · maintainability — Effort: S
- About 15 `LinkedHashMap`-based LRUs exist, each with its own eviction loop. Examples: `wonky_drive/.../preview_cache.dart`, `wonky_charts_flutter/.../chart_painter.dart:86`, `flutter_scene_renderer.dart:107`, `wonky_code/.../cached_code_tokenizer.dart`, `wonky_numfmt/lib/src/cache.dart`, and several in Sheets and Slides.
- Two of these hold disposable resources (`TextPainter`, `fs.Scene`) and need an on-evict hook.
- Recommendation: add a small `LruCache<K, V>` with byte- or count-weighting and an `onEvict` callback to `wonky_core`.

**TP-4 · Minor vendoring hygiene** — Low *(from sub-investigation)*
- `attributed_text` 0.4.7 has one well-tested patch (AT-1). It is current and low risk; file it upstream.
- None of the 39 patches across `third_party/` has an upstream PR link.
- Only super_editor documents a re-sync procedure.

## Not issues (checked)
- **Drive list and grid virtualisation:**
  - The grid uses `GridView.builder` (`packages/wonky_app/lib/src/drive/item_list.dart:266`).
  - The list uses `ListView(children: rows)` (`:240`). It eagerly constructs row widgets, which is O(n) widget allocation per rebuild, but builds and lays out elements lazily. Paging limits n.
  - There are no thumbnails in the drive grid (kind icons only), so no thumbnail loading issue.
  - The Storage table uses `SliverList.builder` with keyset paging.
- **Upload memory:** whole-file bytes are held in `_memory` even when they are persisted (`upload_queue.dart:264`). The 50 MB quota pre-check bounds this once DR-1 is fixed. There is no chunking, by design (v2 review Q12).
- **Upload panel:** `ListView.builder`. Progress notifications are throttled to 1 % steps (`upload_queue.dart:527-534`).
- **Disposal:**
  - `UploadQueue.dispose` cancels its timer, aborts transfers, and closes its stream and store.
  - `FilePreviewController.dispose` cancels polling.
  - `CodeView` disposes its three scroll controllers.
  - `ChartView` releases its GPU key.
  - The web 3D image is disposed when replaced (`setImage`).
  - The chart editor's text and popover controllers are disposed.

## Things done well
- **Upload queue design:** persisted state machine, idempotent client-generated ids, id rotation on server-refused restarts, exponential backoff with jitter, and offline waiting. It is well tested (`upload_queue_test.dart`, 20+ scenarios with fake clock and random).
- **The web upload sender uses XHR** for real progress (spike S-D2), and its comments explain why.
- **Image previews are safe:**
  - Image size comes from the header via `ImageDimensions`, without decoding.
  - Huge images are never decoded on the client; the server preview image is used instead.
  - Preview loads are guarded by `_loadId` against stale responses.
- **Charts:**
  - A pure-Dart engine with a scene graph, consumed by Flutter, SVG, PDF and raster renderers. This keeps exports pixel-consistent and server-renderable.
  - The 2D `Picture` cache is a cheap, effective repaint optimisation.
  - The `FlutterTextMeasurer` LRU is shared by layout and paint, so metrics always agree.
- **3D backend:** loaded lazily (`Chart3DBackends.ensureStarted`), falls back to software rendering, has an LRU of GPU scenes, and works around the web image lifetime with a clear explanation.
- **Code highlighting:**
  - A pure-Dart tokenizer facade (TextMate first, then highlight.js).
  - Measured perf notes, and a highlight.js switch plus a highlight cap for large files.
  - `CodeView` uses fixed-extent virtualised lines for the no-wrap case.
  - A `test/perf/budgets_test.dart` exists.
- **MCP stdio proxy:**
  - Careful protocol handling: init gating, a single `add` per output line, SSE parsing, session expiry, DELETE on shutdown, and diagnostics only on stderr.
  - Its test suite (377 lines plus a fake server) is larger than the library.
- **Vendoring policy:** VENDORED.md and PATCHES.md per package, patch markers, patch tests for super_editor, attributed_text and dart_eval, and vendored suites run in CI.
