# Code-quality review: wonky_sheets_core, wonky_sheets_script, wonky_numfmt

Scope: `packages/wonky_sheets_core` (~96k lines), `packages/wonky_sheets_script` (~19k), `packages/wonky_numfmt` (~4k) and their tests. This was a read-only review: no repo file was changed. Some findings were reproduced with small throw-away scripts run against the workspace packages (not committed).

**Measurement caveat:** the timings come from JIT `dart run` on a Windows dev machine, not AOT. Treat them as relative, roughly 2× worse than AOT. The algorithmic findings (quadratic behaviour, O(n) per edit) do not depend on JIT and AOT. They are backed by the scaling series below.

Measured with the scratch benchmarks:

| Scenario | Result | Spec 05 §21 budget |
|---|---|---|
| `settle()` of 200k simple formulas (`=A1+1` column + `=C1+1` chain, 100k each) | **15.4 s** | 1M formulas full recalc < 20 s |
| same, 10k / 20k / 40k formulas per column | 146 / 270 / 666 ms (superlinear) | |
| edit head of a 100k chain → settle | 4.0 s | 100k dependents < 1 s |
| `SUM(A1:A200000)` over the real `WorkbookModel` | 380 ms (steady) | `SUM(A:A)` over 1M < 10 ms |
| `SUM(A:A)` right after a 1-cell edit (used extent rescanned) | 296 ms | |
| `=ROWS(A1:A200000*1)` (materialize with hints) | 560 ms | |
| Insert one row id into a 200k-row `AxisIndex` and read it | 200 ms | edit → repaint < 16 ms |
| `VLOOKUP(…,FALSE)` per formula, 100k-row table | 14 µs | ≈15 µs (OK) |
| `LinkedHashSet` remove-first loop, 25k / 50k / 100k / 200k | 174 / 670 / 2,738 / 10,568 ms | — |

---

## Prioritised findings

### H1. Recalculation drain is quadratic (`LinkedHashSet.first` with tombstones)
- **Severity:** High · **Category:** perf (bug-level) · **Effort:** S
- **Evidence:**
  - `formula_engine.dart:590-599`: `while (_dirty.isNotEmpty) { final n = _dirty.first; _ensureClean(n); … }`.
  - `_dirty` is a `LinkedHashSet` (line 168), and `_evaluateNode` removes from it (line 1570).
  - Dart's compact linked hash set leaves tombstones on removal. `first` skips them, and the set only compacts on a growing rehash, so each `first` costs O(removed so far).
  - The micro-benchmark shows the textbook n² curve (table above).
  - The engine scaling series (40k → 100k formulas per column: 0.67 s → 15.4 s for 2.5× the work) matches it.
- **Why it matters:**
  - A full recalc of a large sheet, an import, a `recalcAll`, a locale change or `sheetsChanged` dirties everything.
  - Background recalc of 1M formulas becomes effectively unbounded, hours rather than the 20 s budget.
  - The viewport loop (lines 573-579) also iterates the tombstoned set on every slice.
- **Change:** drain from a `Queue<_Node>`/`List` worklist and skip nodes that are no longer dirty, keeping `_dirty` only for membership. The cheapest fix is to take `final batch = _dirty.toList()` per drain call and iterate it. Add a scaling regression test (10k vs 40k must stay close to linear).

### H2. COUNTIF/SUMIF give different answers depending on cache state (index path ignores numeric tolerance)
- **Severity:** High · **Category:** bug · **Effort:** S
- **Evidence:**
  - The scan path, `Criterion.test`, compares numbers with `Numeric.compare` (tolerance 2⁻⁴⁹), at `functions/criteria.dart:151-163`.
  - The indexed path, `_Index.positions`, uses an exact hash `eq[o.v]` and exact binary search on `sortedNum` (`functions/math/conditional.dart:282-318`).
  - The index is built on the second use of the same range and stamp (`conditional.dart:340`, ranges ≥ 256 cells).
- **Reproduced:** A1:A400 numbers with A6 `=0.1+0.2`.
  - `B1 =COUNTIF(A1:A400,0.3)` → **1**.
  - `B2`/`B3`, the identical formula, → **0**.
  - `=A6=0.3` → TRUE.
- **Why it matters:**
  - The results are nondeterministic: they depend on evaluation order and cache state.
  - Clients and the server can disagree, which breaks the determinism goal of 05 §12.
  - It affects every *IFS function (`_single`, and `_multi` at line 494).
- **Change:**
  - Make index answers tolerance-aware. For `eq`, binary-search `sortedNum` for `[x−ε|x|, x+ε|x|]` instead of hashing.
  - For lt/le/gt/ge, adjust the boundaries by the same tolerance, or fall back to the scan when boundary values are within ε.
  - Add a test that evaluates the same criterion three times over ≥ 256 cells containing `0.1+0.2`.

### H3. Range reads over `WorkbookModel` cost about 1–2 µs per cell (budget about 10 ns)
- **Severity:** High · **Category:** perf · **Effort:** M–L
- **Evidence:**
  - `model/cell_store.dart:109-171`: `cellsIn` is a `sync*` generator with nested `yield*`, a record allocation per cell, and 2 string-keyed hash lookups per cell (`_rows[rows.idAt(r)]`, `rowCells[cols.idAt(c)]`). For open ranges it iterates and sorts all row keys (`rowSpan > _rows.length` branch).
  - `engine_bridge/model_workbook_view.dart:88-98,171-174`: an `Expando` lookup per cell to find the cached `CellInput`, plus a closure per cell.
  - `formula_engine.dart:279-295`: `forEachValue` adds another closure and type checks.
  - Measured on 200k cells: raw `cellsIn` 130 ms, `forEachInput` 260 ms, `engine.forEachValue` 340 ms, `SUM(A1:A200000)` 380 ms.
- **Why it matters:**
  - Every aggregate, lookup-vector build, CF stats pass, chart and pivot source read goes through this path.
  - `SUM(A:A)` over 1M rows is about 2 s against the < 10 ms budget.
- **Change:**
  1. Keep a per-sheet, per-column dense cache (`List<CellInput?>` or `Float64List` plus a kind byte) indexed by row index. Invalidate it on `AxisIndex.generation` and per-column content version (the planner already reports touched columns).
  2. Store the decoded `CellInput` as a field on `CellRecord`, which already caches `_decoded`, instead of a global `Expando`.
  3. Replace `sync*` iteration with callback or index loops.
  4. Benchmark before and after (H6).

### H4. Used extent is recomputed over all cells after every edit
- **Severity:** High · **Category:** perf · **Effort:** S–M
- **Evidence:**
  - `model_workbook_view.dart:201-207`: `_computeUsed` re-runs whenever `model.version` changes, and any `applyChanges` call bumps it.
  - `cell_store.dart:175-198`: `usedExtent` walks every row map and column map and runs `.any(content != null)` over each.
  - Open references call `usedRows` (`range_access.dart:58-70`), as do the spill bounds `usedRows`/`usedColumns` (`formula_engine.dart:315-336`) and `_ensureLoaded`/`sheetsChanged`.
  - Measured 70 ms per edit at 200k cells. It grows linearly, so expect ≈ 350 ms at 1M.
- **Why it matters:** any sheet with a whole-column formula (`A:A`, very common) pays a full scan after each keystroke commit, which blows the 16 ms edit budget.
- **Change:**
  - Maintain the max content row and column incrementally in `CellStore` (it already keeps per-row and per-column maps). On put, raise the max if needed.
  - On remove, mark the extent dirty only if the removed cell's row or column was the max, and recompute lazily.
  - Key the cache on content changes, not on the global model version.

### H5. Structural edits are O(rows) several times over, and the planner scans the whole workbook
- **Severity:** High · **Category:** perf · **Effort:** M
- **Evidence:**
  - `model/axis_index.dart:354-396`: a single insert takes the general path, which rebuilds `keep`/`merged` `_Entry` lists, re-adds all 4 parallel lists, and nulls `_index`. The next `indexOf` rebuilds a full id→index `Map` and the Fenwick tree. Measured 200 ms for one row in 200k.
  - `engine_bridge/engine_binding.dart:132-200`: `_axis` copies all ids, builds `nowIndex` (a map of all ids) and `beforeSet`, and builds survivor lists, all O(n) hashing per structural batch. It also keeps a full id-list copy per axis (`_order`).
  - `formula_engine.dart:787`: `_rangeIndexes[sheetId]?.invalidate()` forces an O(K log K) rebuild with an `indexOf` per key on the next query.
  - Planner:
    - `mutations/handlers/move.dart:590-597` and `structure.dart:345-353` iterate `cells.all` of every sheet.
    - For each formula they call `StoredFormula.mayReference(content, ids)` (`engine_bridge/stored_formula.dart:83-89`). That loops over every moved or deleted id, and for each id runs `Base62Uuid.toToken`, a regex match plus a map lookup, followed by `text.contains`.
    - The cost is O(formulas × moved ids × formula length). Moving 1,000 rows in a workbook with 100k formulas means about 10⁸ token conversions.
  - The engine already has the exact indexes for this: `formulasReferencing`, `formulasWithEndpointsOn` (`formula_engine.dart:2412-2450`). No caller outside the engine uses them (grep).
- **Why it matters:** insert or delete row, cut/paste and sort-with-moves are interactive operations, and they degrade with workbook size, not with edit size.
- **Change:**
  - Planner: compute the token strings once (`Set<String>`). Better, ask `FormulaHooks`/the engine for the referencing formulas when an engine is present, and keep the full scan only for the headless path without an engine.
  - `AxisIndex`: in-place `List.insertAll`/`removeRange` (a memmove, no hashing). Update `_index` lazily only from the first changed position (store `_indexValidUpTo`). Do Fenwick point updates for small batches.
  - Binding: derive insert/delete runs from the `RowChange`s instead of diffing full id lists.

### H6. Spec-mandated benchmarks and compatibility corpora don't exist
- **Severity:** High · **Category:** testing · **Effort:** M
- **Evidence:**
  - 05 §21 requires `wonky_sheets_core/benchmark/` (CI on every PR, >10% regression fails); it does not exist.
  - 05 §22.4 requires golden compatibility vectors in `test/formula/golden/**.yaml` (≥ 5,000, captured from Google Sheets); absent.
  - 05 §22.5 requires a LibreOffice differential (`tool/compat/lo_diff.py`); absent.
  - Only one suite (`charts/three_d/chart3d_preview_test.dart`) is tagged `slow`, and STATUS.md admits "No suite is tagged `slow` yet".
  - No engine test uses a `Stopwatch` or makes perf assertions.
  - XLSX tests use the synthetic `test/io/support/ooxml_builder.dart`; there are no real Excel/LibreOffice-produced `.xlsx`/`.ods` fixtures (only the clipboard HTML has real-app fixtures).
  - Function tests are hand-written vectors (`test/formula/functions/function_vectors.dart`), not captured from Sheets or Excel.
- **Why it matters:**
  - H1, H3, H4 and H5 each violate a §21 budget by 10–1000×, and nothing caught them.
  - STATUS marks the engine "Done and tested" while spec 05 §22's exit checklist ("Performance budgets of §21 are met in CI benchmarks", line 2237) is unmet.
- **Change:**
  - Add `benchmark/` with the §21 table, run on the real `WorkbookModel` + `ModelEngineBinding`, not `MemorySheet`, with UUID ids (`UuidV7IdGenerator`), as `dart test -P slow` or `dart run benchmark/main.dart`.
  - Add a scaling assertion test (2× n ⇒ < 3× time) that runs by default to catch quadratic regressions cheaply.
  - Commit a small set of real-world xlsx/ods fixtures.
  - Start the golden-vector YAML with the functions most used in templates.
  - Update STATUS.md to reflect what is missing.

---

### M1. Two implementations of the number-format language (TEXT() vs. cell display) disagree
- **Severity:** Med · **Category:** bug / maintainability · **Effort:** M
- **Evidence:**
  - `formula/functions/text/number_text_formatter.dart` (1,132 lines, its own tokenizer, renderer and LCID table at line 367) serves TEXT/TO_TEXT/DOLLAR/FIXED.
  - `wonky_numfmt` (parser + formatter, about 1,300 lines) serves the grid display through `CellTextFormatter`.
  - `FormulaEngine.textFormatter` is never overridden in the app, server or packages (grep).
- **Differential run:** 57 of 490 (pattern, value) pairs differ. Examples:
  - `0.00` with −0.0001: TEXT `0.00`, display `-0.00`.
  - `# ?/?` with 0.3333: TEXT `1/3`, display ` 1/3` (Excel pads).
  - `# ?/?` with 1: TEXT `1`, display `1    `.
  - `h:mm AM/PM` with 1e9: TEXT `1000000000`, display `12:00 AM`.
  - `\-0` with −0.0001: TEXT `-0`, display `--0`.
  - `0.00,,"M"` with −1.5: TEXT `0.00M`, display `-0.00M`.
- **Why it matters:**
  - `=TEXT(A1, "<A1's format>")` doesn't reproduce what the cell shows.
  - Every format bug has to be fixed twice.
  - Locale data is duplicated too: `FormulaLocale` uses intl `STANDALONEMONTHS` while `wonky_numfmt` `LocaleFormatData` has its own months.
- **Change:**
  - Implement `NumberTextFormatter` on `NumberPatternFormatter.instance` (`plainText`, spacer → space, repeat → omitted) and delete the builtin.
  - Keep the 490-pair differential as a regression test while migrating.
  - Decide the correct output with Sheets for the negative-zero and out-of-range-date cases (see L5).

### M2. Two collations: SORT() and Data › Sort order text differently, and SORT allocates per comparison
- **Severity:** Med · **Category:** bug / perf · **Effort:** S
- **Evidence:**
  - `formula/values/compare.dart:61-139` (`_collationKey` with a small `_stripMark` table, no cache) is used by `sortCompare` (line 162), which runs inside `List.sort` in `functions/filter/filter.dart:211-221`.
  - `data_tools/sort/sort_keys.dart:69-130` has a larger fold table (`æ`→`ae`, fullwidth, combining marks), a cache, and precomputed key columns.
- **Verified:** for `æb, af, Ab, ab, ß, ss, st, Ölz, Oz`:
  - Data › Sort gives `Ab, ab, æb, af, …`.
  - `SORT()` gives `Ab, ab, af, Ölz, Oz, ss, ß, st, æb`.
- **Why it matters:**
  - The same data sorts differently through the menu and the function.
  - SORT over 100k strings builds about 3.4M `StringBuffer`s.
- **Change:**
  - Use one `Collation` in `formula/values/` and use it from both.
  - In `_order`, precompute keys per row once, as `SortKeyColumn` does.
  - Replace the global clear-at-50k `_keyCache` with an LRU, or rely on per-sort precomputation.

### M3. Rule formulas (CF/DV/filter custom formulas) re-extract the template for every cell
- **Severity:** Med · **Category:** perf · **Effort:** S
- **Evidence:**
  - `engine_bridge/engine_formula_hooks.dart:408-425` creates a new `CompiledRelative` per call.
  - `CompiledRelative.evaluate` calls `evaluateStored` (`formula_engine.dart:2533-2540`).
  - That calls `compiler.compileStored(stored)` (line 2093), which runs `TemplateKey.extract`: a string scan, `RefToken.decode`, and `split(';')` plus base62 decode per reference, followed by LRU remove and re-insert.
  - The doc comment says "compiled once relative to [anchor]" (line 2176); the code doesn't do that.
  - Callers: `rules/cf/cf_evaluator.dart:548`, `rules/dv/validation_engine.dart:174,287`, `data_tools/filter/filter_engine.dart:242`.
- **Change:**
  - Make `CompiledRelative` hold `(CompiledFormula, slots)` computed in its constructor.
  - Cache `CompiledRelative` per (stored, sheetId, anchor) in the hooks.
  - Evaluate with a reusable `EvalContext`.

### M4. Named ranges are JSON-decoded on every evaluation
- **Severity:** Med · **Category:** perf · **Effort:** S
- **Evidence:**
  - `compiler.dart:675` (`resolveName`) calls `nr.range`.
  - `_NamedView.range` (`model_workbook_view.dart:262-277`) calls `GridRange.tryParse(r.rangeJson)`, which runs `jsonDecode` (`model/grid_range.dart:58-63`).
  - `ModelWorkbookView.namedRanges` allocates new views on every `_refreshNames`.
- **Why it matters:** 10k formulas using `Sales` means 10k `jsonDecode` calls per recalc.
- **Change:** cache the parsed `IdRange` per `NamedRangeRecord` instance (an `Expando` or a lazy field on the record).

### M5. Materializing a range resolves the explicit format chain for every numeric cell
- **Severity:** Med · **Category:** perf · **Effort:** S
- **Evidence:**
  - `formula/eval/range_access.dart:89-93`: `withHints` defaults to true, and none of the 11 callers passes false.
  - It calls `SheetView.numberFormatAt`, then `model.explicitFormatChain` (`workbook_model.dart:348-364`): up to 3 `CellFormat.overlay` calls, each copying the attribute list and hashing for `intern` (`format/attributes.dart:207-213`).
  - `cellHint` does the same for single cells.
  - Measured `=ROWS(A1:A200000*1)`: 560 ms, versus 340 ms for the plain value iteration.
- **Change:**
  - Look up `numberFormat` directly: cell format first, then row, then column, then sheet. Each is a single attribute read, with no overlay allocation.
  - Short-circuit when the sheet has no row or column formats.
  - Pass `withHints: false` where hints are discarded (aggregates, booleans, text functions).

### M6. Viewport prioritisation scans the entire dirty set on every slice
- **Severity:** Med · **Category:** perf · **Effort:** S–M
- **Evidence:** `formula_engine.dart:570-579` calls `for (final n in _dirty)` with two `indexOf` calls per node in the viewport's sheet, on every `drain()` call, which the app runs every 2–16 ms.
- **Why it matters:** with 1M dirty nodes the scan alone costs tens of milliseconds per slice, so the background recalc can starve the frame budget (05 §10.2: "no frame > 20 ms").
- **Change:**
  - Recompute the in-view list only when the viewport changes or new nodes are dirtied (generation counter).
  - Alternatively, look up the formula nodes inside the viewport rect directly through `sheet.forEachInput(rect)` plus `engineData`, which is O(visible cells).

### M7. Per-cell memory and string-key overhead (partly speculative on magnitude)
- **Severity:** Med · **Category:** perf / memory · **Effort:** M
- **Evidence:**
  - Every cell lives in 3 maps in `CellStore` (`_byId`, `_rows[rowId][colId]`, `_cols[colId][rowId]`, `cell_store.dart:7-9,47-55`).
  - It also has a global `_ruleOwner['cell:<uuid>']` entry with a freshly concatenated key string (`workbook_model.dart:491`), plus an `Expando` entry for its input.
  - Formula nodes are keyed by `'$sheetId\u0001$rowId\u0001$colId'` strings that are rebuilt on every lookup (`formula_engine.dart:490, 707-708, 734, 932-933, 1041-1042, 1390, 1407-1408, 1727-1728, 2374`).
  - Every edit dirties all volatile nodes (`formula_engine.dart:678, 1023-1029`); that is by design but worth benchmarking.
- **Why it matters:** the spec budget is ≤ 200 MB of engine overhead for 1M formula cells (05 §11.3). With 36-char UUID ids, the duplicated maps and key strings plausibly exceed that. This is not measured: add a memory benchmark (H6).
- **Change:**
  - Don't track cells in `_ruleOwner`; cell rows carry `sheetId`, so resolve the owner via a per-sheet `byId`.
  - Use `input.engineData` (already set) or `(row, col)` id records instead of concatenated keys in hot paths.
  - Consider interning row and column ids to ints per sheet.

### M8. Base62 id codec: regex per call, BigInt math, and a duplicate of `wonky_sync_models`
- **Severity:** Med · **Category:** perf / maintainability · **Effort:** S
- **Evidence:**
  - `addressing/base62_uuid.dart:11-72`: `toToken` runs a 36-char regex on every call; `encode`/`decode` use `BigInt` (slow on the web JS target).
  - It has a global 200k-entry cache that clears wholesale, which thrashes past 200k distinct row ids.
  - It is called for every reference of every formula compile (`ref_token.dart:96-132` via `TemplateKey.extract`) and from `mayReference` (H5).
  - The header says it "lives here so the formula engine has no dependency on the synced models". That is stale: `wonky_sheets_core` depends on `wonky_sync_models` (pubspec, and `model/axis_index.dart:4` imports `package:wonky_sync_models/ids.dart`), which has its own byte-based base-62 (`wonky_sync_models/lib/src/ids/base62.dart`).
- **Change:**
  - Reuse the sync_models encoder, or encode with two 64-bit halves and no `BigInt`.
  - Replace the regex with a length and hyphen-position check.
  - Use a bounded LRU.

### M9. God files and splits
- **Severity:** Med · **Category:** maintainability · **Effort:** M

Largest files in the three packages:

| Lines | File | Suggested split |
|---|---|---|
| 4,282 | `wonky_sheets_script/lib/src/api/api_index_data.dart` | Generated (freshness test exists); fine |
| 2,552 | `core/lib/src/formula/recalc/formula_engine.dart` | `_Dep`/registration/range indexes → `graph/dependency_graph.dart`; spills (`_SpillTable`, `_applyResult`, overlays) → `recalc/spills.dart`; cycles (Tarjan, Gauss–Seidel) → `recalc/cycles.dart`; detached/bound/relative evaluation → `recalc/detached_eval.dart`; introspection → `services/` |
| 2,251 | `script/lib/src/api/api_source.dart` | The whole script API is Dart source inside a raw string, so it gets no analyzer or format checks. Keep it as real `.dart` files (e.g. `lib/src/api/wonky/*.dart`, excluded from the package's analysis via `analysis_options`, or a `tool/` asset) and generate the const |
| 2,057 | `core/lib/src/io/write/ir_to_rows_planner.dart` | Sinks/targets, cell writer, and per-feature planners (formats, rules, objects, pivots) already exist as `// ---` sections → separate files |
| 1,968 | `script/lib/src/host/script_host.dart` | Stringly-typed `switch (method)` dispatch over about 150 methods (`case 'ss.getRange':` …); split per target (`app`, `spreadsheet`, `sheet`, `range`, `ui`, `properties`) and add a contract test that every `wonkyHostCall` method name in `api_source` has a handler |
| 1,462 | `core/lib/src/io/xlsx/xlsx_importer.dart` | Split into styles, shared strings, sheet SAX reader, and rules |
| 1,404 | `core/lib/src/io/print/pdf_renderer.dart` | — |
| 1,287 | `core/lib/src/mutations/operations.dart` | Operation classes grouped by area |
| 1,132 | `core/lib/src/formula/functions/text/number_text_formatter.dart` | Delete per M1 |
| 1,067 | `core/lib/src/model/records.dart` | One file per record family |

### M10. Heavy work on the UI thread (web scripts; desktop isolate opportunities)
- **Severity:** Med · **Category:** perf / UX · **Effort:** M–L
- **Evidence:**
  - `script/lib/src/runner/inline_runner.dart:1-17,76-80`: on the web, scripts and custom functions run on the main thread (no SharedArrayBuffer without COOP/COEP), and `Utilities.sleep` busy-waits.
  - Custom-function batches may run up to 30 s (`custom_functions.dart:86`).
  - In the app, only CF stats sorting uses `compute` (`wonky_sheets/lib/features/conditional_format/cf_controller.dart:126`).
  - Sort-key building, pivot computation, CSV planning, chart scene building and PDF pagination are pure Dart over plain data, but run on the UI isolate. They are time-sliced (pivots yield every 0x7ff rows), not offloaded.
- **Change:**
  - Custom functions are pure, so their inputs can be serialized. Run them in a Web Worker / `Isolate.run` with an async protocol, without the synchronous bridge.
  - On desktop, offload pivot `compute` over a column snapshot (`SourceTable` is plain data) and the PDF render with `Isolate.run`. This is in line with 05 §10.3, "offload of bulk pure jobs".
  - Replace the busy-wait sleep with a `UiUnavailableException`-style error on the web.

---

### L1. Test helpers are exported from the production barrel
- **Severity:** Low · **Category:** DX / API surface · **Effort:** S
- **Evidence:** `lib/formula.dart:24,33` exports `MemoryWorkbook` and `FormulaTestBench`. `model_testing.dart` exists precisely for this purpose.
- **Change:** move both to `lib/formula_testing.dart`.

### L2. Lookup cache allocates strings per call; capacity is small
- **Severity:** Low · **Category:** perf
- **Evidence:**
  - Key and stamp strings are built on every VLOOKUP/COUNTIF (`functions/lookup/lookup.dart:526-528`, `recalc/lookup_cache.dart:48-58`).
  - `capacity = 128` LRU, which thrashes with many distinct relative ranges.
- **Current state:** measured at 14 µs per VLOOKUP, which is within budget.
- **Change:** record keys and an int stamp would remove the allocations.

### L3. Wildcard lookups compile a regex on every call
- **Severity:** Low · **Category:** perf · **Effort:** S
- **Evidence:** `lookup.dart:588-589` calls `Criterion.wildcardRegExp(pattern)` with no cache, whereas `Criterion.of` has an LRU.
- **Change:** reuse the `Criterion` cache.

### L4. XLSX import holds 3–4× the file size in memory
- **Severity:** Low · **Category:** perf / memory · **Effort:** M
- **Evidence:**
  - The whole zip is decoded up front (`io/xlsx/ooxml.dart:212`).
  - Each sheet part is decoded to a full `String`, then `sheetData` is substring-copied and `rest` is concatenated (`xlsx_importer.dart:666-687`).
  - The sheetData itself is parsed with SAX events (good).
  - This runs server-side, so the priority is lower.
- **Change:** decompress per part on demand, and SAX-parse the whole part instead of splitting strings.

### L5. Out-of-range date serials format as times
- **Severity:** Low · **Category:** bug · **Effort:** S
- **Evidence:** `wonky_numfmt` renders 1e9 with `h:mm AM/PM` as `12:00 AM` and `[mm]` as `1440000000000`. Excel shows `#####` for dates beyond 9999-12-31. Not verified against Sheets.
- **Change:** decide the behaviour against Sheets and add vectors.

### L6. Thin tests in `wonky_numfmt`
- **Severity:** Low · **Category:** testing · **Effort:** S
- **Evidence:** 306 lines of tests for 4k lines of code. More format tests live in core (`test/format/number_format`, about 1.1k lines, plus a property test).
- **Change:** move the format tests next to the package and add the TEXT-vs-display differential from M1.

### L7. Low test ratio in `wonky_sheets_script`
- **Severity:** Low · **Category:** testing · **Effort:** S–M
- **Evidence:** 2.1k test lines against 18.7k lib lines. `script_host` is exercised mostly through the conformance corpus (`test/conformance/conformance_test.dart`, run on both runners, which is good).
- **Change:**
  - Add the method-contract test from M9.
  - Add per-scope and quota tests for write paths (`_requireWrite`, `_requireScope`, `script_host.dart:365-431`).

### L8. `stabilize` round-trips through strings
- **Severity:** Low · **Category:** perf · **Effort:** S
- **Evidence:** `Numeric.stabilize` / `roundSignificant` (`values/numeric.dart:153-160`) uses `toStringAsPrecision` plus `double.parse` on every transcendental result, which is costly over large arrays.
- **Change:** compute with `pow10` scaling plus a correction step, or leave it as is if benchmarks show it doesn't matter.

---

## Verified correct or deliberately designed (no action)
- **ROUND family:** decimal-correct on the 15-significant-digit representation (`values/numeric.dart:5-151`), half away from zero, which matches Excel and Sheets.
- **Date systems:** the epoch is 1899-12-30 (Sheets).
  - XLSX import shifts 1904 workbooks (+1462).
  - It corrects the 1900 leap-year bug (serials 1–59 +1), and maps serial 60 to `#VALUE!` with a warning (`xlsx_importer.dart:974-984`).
  - `DateSerial` is shared between the engine and numfmt (`formula/values/dates.dart:1-5`), so there is no duplication.
- **SORT() stability:** guaranteed by the index tie-break (`filter.dart:213-219`).
- **Integer key packing:** (`r * 0x100000 + c`, pivot stride `0x4000000`) is within 2⁵³ for the supported grid sizes, so it is safe on JS.

## Things done well
- **Formula compiler:** an AST → closure compiler with a template cache keyed by the slot-normalised stored formula (`eval/compiler.dart:142-163`). Filled-down formulas share one compiled closure. References are id-based, so row and column inserts never rewrite formula text.
- **Incremental recalculation:**
  - Static dependencies come from slots; dynamic dependencies are recorded only for OFFSET/INDIRECT.
  - Dirty propagation is transitive, and evaluation is pull-based with an explicit wait stack, so long chains cannot overflow the stack (`formula_engine.dart:1460-1502`).
  - Cycles are handled with Tarjan SCC and a Gauss–Seidel iterative calculation from seed values (`:1582-1719`).
  - An interval index over range dependencies shares one entry per identical range (`graph/range_index.dart`).
- **Lookup acceleration:** column-generation-stamped vector caches, an exact-match hash index built on second use, and a criteria index with sorted numbers for *IFS (H2 aside). VLOOKUP runs within budget.
- **Data tools:**
  - Sort uses typed key columns (`Float64List`/`Uint8List`), a stable merge sort with cancellation, and cached collation keys (`data_tools/sort/*`).
  - The pivot engine is a single pass with ancestor-pair caching, written as a cancellable generator (`pivot/pivot_engine.dart:601-641`).
- **AxisIndex:** buffers mutations and uses a Fenwick tree for pixel ↔ index lookups (`model/axis_index.dart`). Only the single-insert path (H5) is weak.
- **Import parsing:** XLSX sheetData and shared strings are parsed with SAX events; CSV parsing streams in chunks.
- **Tests:**
  - Property tests for the codec, planner op sequences, CSV round-trips and number formats.
  - Script sandbox escape tests, a conformance corpus run on both runners, and an `api_index` freshness test.
  - Test names follow the given/when/then convention.
- **Numeric accuracy:** tolerant equality (2⁻⁴⁹), cancellation snapping, and Kahan-style compensation in the conditional aggregates.
