# RevLog performance baseline (R6)

Measured 2026-10-18 for the performance gates of [spec 17 part 7](../../specs/17-revlog-sync.md#part-7--performance-gates)
(= `spec/09-testing-and-acceptance.md` §6). R0's baseline of the CRDT engine was never recorded;
the "today" reference of P8 (0.55 s for 200k cells) is taken from the gate text.

## Setup

| | |
|---|---|
| Machine | Windows 11 Home (build 26300), 12 logical CPUs, one desktop shared with other agents' work (numbers vary ±20 % between runs) |
| Server | `dart test` (JIT) against the embedded test Postgres (`config/test.yaml`), one instance, no Redis |
| Clients | `flutter test` VM (JIT), real SQLite cache (`sqlite_async`), in-process `FakeRevHub` (real apply rules) with indexed cell pages |
| Data | 200k = 7,700 rows × 26 columns, 1M = 38,461 rows × 26 columns (the grid limit); realistic content: header row, labels, regions, dates, numbers with formats, 3 formula columns, notes. Decks: 500 slides × (title, body, 12 shapes, 2 text boxes, 3 × 3 table) = 16,562 rows |
| Suites | `wonky_server/test/integration/sheets/revlog/revlog_perf_test.dart`, `wonky_sheets/test/revlog/revlog_perf_test.dart`, `wonky_slides/test/revlog/revlog_perf_test.dart` (tag `slow`; `REVLOG_PERF_SCALE=0.1` for a smoke run). Each prints its table |

Run: `dart test -t slow test/integration/sheets/revlog/revlog_perf_test.dart` in `wonky_server`
(one server test process at a time), `flutter test -t slow test/revlog/revlog_perf_test.dart` in
`wonky_sheets` and `wonky_slides`.

## Gates

Final runs after the R6 fixes (before → after where a fix changed the number).

| Gate | Metric | Target | Measured | Result |
|------|--------|--------|----------|--------|
| P1 | Op → applied in another connection's model, one instance (server, 2 connections, 500 single-cell ops on the 200k file) | p95 < 250 ms | p95 4.9 ms (p50 3.9) | pass |
| P1 | Client part: edit → applied in the other client's 1M-cell model (Sheets) / remote op → 500-slide deck (Slides) | p95 < 250 ms | p95 5.6 ms / 0.3 ms | pass |
| P2 | Same across two instances (Redis) | p95 < 400 ms | not measured (no Redis in the test setup) | — |
| P3 | Server commit, 1 change (submit → ack) | p95 < 15 ms | p95 6.5 ms (p50 5.3) | pass |
| P3 | Server commit, 100 changes | p95 < 15 ms | p95 13.5 ms (p50 10.9); before: 19.1 | pass (tight; 22 ms in a run right after the 1M imports while Postgres vacuums). **R7: p95 11.4 ms (p50 8.9)**  |
| P4 | Server commit, 4,992 changes | p95 < 300 ms | p95 288–306 ms (p50 248–280) over three runs; before: 334–495. **R7: p95 250 ms (p50 211); 282 ms while other suites ran** | borderline → **pass (R7)** |
| P5 | DB transactions while idle (31 s, 2 connections open, minus the same window without connections) | 0 | 0 | pass |
| P6 | Cold open of 1M cells → ready, server part (RevInit, structure pages, first cell page, decode, model) | < 1.5 s | 1.07–1.12 s. **R7: 0.45–0.54 s** | pass |
| P6 | Cold open of 1M cells → `WorkbookReady`, client with SQLite | < 1.5 s | 1.44 s (2.0 s in another run); 100k: 1.56 s → 0.55 s. **R7: 0.89–1.12 s** | borderline → **pass (R7)** |
| P6 | Cold open of a 500-slide deck → `DeckReady` | < 1.5 s | 0.70 s; R7: 0.38 s | pass |
| P7 | Complete download of 1M cells, server part (pages + decode + model, no SQLite) | < 15 s | 31.2 s (pages 14.8, decode 6.4, model 9.4); before: 44.1. **R7: 7.1–7.3 s (pages 2.6, decode 0.8–0.9, model 3.4)** | **miss** → **pass (R7)** |
| P7 | Complete download of 1M cells, client with SQLite | < 15 s | 98–101 s; 100k: 17.4 s → 5.2 s. **R7: 13.8–14.5 s**, of which 2.7–2.9 s the in-process page serving; with the wire work of R7: **12.6 s** (2.6 s serving) | **miss** → pass (R7) |
| P8 | Reopen from the cache, 1M cells → `WorkbookReady` | ≤ 2.75 s | 28.6–47.1 s (rows read 13.8–17.7 s, model 8.2–12.1 s); 100k: 4.5 s → 1.9 s. **R7: 0.28–0.43 s** viewport-first; every cell in the model 8.5–10.8 s later (background) | **miss** → **pass (R7)** |
| P8 | Reopen of a 500-slide deck from the cache | ≤ 0.55 s | 0.29 s; R7: 0.22 s | pass |
| P9 | 1M-cell local import into the outbox | < 30 s | 30.2–32.4 s, of which the Sheets planner + model 26.0–26.5 s and the outbox write 4.2–5.9 s. **R7: 17.3–18.6 s** (planner + model 13.3–14.2 s, outbox 3.9–4.4 s) | miss → **pass (R7)** |
| P10 | Server import of 1M cells as a server change (`SheetsServerWrites.apply`, 207 ops) | < 60 s | 57.8 s; before: 83.4 s. **R7: 41.0–42.3 s** | pass |
| P10 | Import of 1M cells as a new file (`createSpreadsheetFromSheets`, one transaction) | < 60 s | 63–69 s; before: 79.3 s. **R7: 37.6–38.0 s** | **miss** → **pass (R7)** |
| P11 | Storage per non-empty cell (`cell` incl. indexes and TOAST) | ≤ 250 B | 210 B (+30 B of `rev_op` payload per imported cell, pruned after 30 days). **R7: 238 B** (`fillfactor = 85`) | pass |
| P12 | Commit on the warm 200k file with 20 protections, editor, 1 / 100 changes | p95 < 30 ms | p95 5.6 / 14.2 ms | pass |
| P12 | Cold headless loads inside the lock while a connection is open | 0 | 0 | pass |

### Other numbers

| Metric | Measured |
|--------|----------|
| Headless cold load, 1M / 200k cells (05 §9) | 22.3 s (rows read 13.5 s, model 8.2 s) / 4.4 s |
| Post-commit hooks of the 1M-cell server change | 7.7 s |
| Op throughput, 2 editors × 250 single-cell ops at once | 135–220 ops/s |
| Single-cell edit → outbox durable in SQLite (1M-cell file), online / offline | p95 4.7 ms / 4.0 ms |
| Outbox drain of a 1M-cell local import to the in-process hub (207 ops) | 200.8 s → 111.6 s (the client handles an ack of 5,000 changes in ~130 ms; the rest is the in-process fake server); R7: 53–57 s |
| Store write of one 13k-cell page (`RevLocalStore.applyPage`) | 145–168 ms; R7: 27–34 ms (p50) |
| SQLite cache size, 1M cells | 695–733 MiB (~700 B per cell); R7: 107–108 MiB (112–113 B per cell) |
| Reopen from the cache: every cell in the model (background after ready, R7) | 8.5–10.8 s |

## Fixes made in R6

| Area | Change | Effect |
|------|--------|--------|
| Server reads (`rev_sql.dart`, `rev_pages.dart`) | Rows are read as `json_strip_nulls(row_to_json(t))` (most cell columns are null); the op's prefetch reads all tables in one statement (CTEs + `UNION ALL`) instead of one per table; the headless load of per-sheet tables keysets along the `(sheetId, rowId)` index instead of sorting the sheet's cells by id for every page | fewer bytes and round trips per commit; P7 server pages 23.4 s → 14.8 s |
| Server writes (`rev_sql.dart`, `rev_log_service.dart`) | Null columns are left out of the `jsonb_to_recordset` JSON; rows that did not exist at the prefetch are inserted without `ON CONFLICT`; the drive item id is kept in `RevFileState` (one query less per submit) | P3 100 changes p95 19 → 13.5 ms |
| Bus (`rev_bus.dart`) | Ops too large to inline are no longer JSON-encoded just to measure them | −15 ms per 5,000-change op |
| Codec (`wonky_revlog`) | `Base62Uuid` converts with 16-bit limbs and division by 62^5 (5 passes instead of 22, no substrings); UUID values are memoized within one payload or page; `RevTable.column` is a map lookup; validation builds error strings only on failure and checks UUIDs without a regex | op encode 41 → 9 ms, decode 27 → 14 ms, page encode 70 → 45 ms, page decode 90 → 57 ms (5,000 / 13,000 cells); P4 and P10 |
| Overlay (`wonky_revlog`) | `RevOverlay` indexes the outbox (key → ops, by op identity): a rebuild or prune touches only the ops that changed instead of every change of the outbox | an ack with 175 queued 5,000-change ops: 490 → 27 ms |
| Client store (`wonky_revlog_flutter`) | Row, delete and coverage writes are batched (`executeBatch`) instead of one statement per row; `_replay` reads the rows its updates need in one query per table; null columns are left out of the stored JSON; `replaceOutbox` keeps the stored ops that did not change (acks remove the oldest, edits append or compose the newest) instead of re-encoding the whole outbox | P6/P7/P8 (100k) 1.56 / 17.4 / 4.5 s → 0.55 / 5.2 / 1.9 s; drain 40 s → 7 s (100k) |

The misses that need larger changes are in `TODO.md` ("RevLog sync — open items"): viewport-first
reopen from the cache (P8), a cheaper page format and pipeline (P7), bulk inserts / `fillfactor`
(P10, P4), the cache layout (size), and the measurements still missing (P2, web/OPFS).

## R7: client (2026-10-19)

The client side of P6–P9 and the cache size, measured with the same suites and machine (three
runs of `wonky_sheets/test/revlog/revlog_perf_test.dart`, one of the Slides suite; the server
work of R7 is recorded separately). Spec 17 As built 1 and 24 describe the result.

| Gate | R6 | R7 | Result |
|------|----|----|--------|
| P6 cold open → ready (client, 1M cells) | 1.44–2.0 s | 0.89–1.12 s | pass |
| P7 complete download (client, 1M cells, incl. in-process page serving) | 98–101 s | 13.8–14.5 s (page serving 2.7–2.9 s) | pass, tight |
| P8 reopen from the cache → ready (1M cells) | 28.6–47.1 s | 0.28–0.43 s | pass |
| P9 local import of 1M cells into the outbox | 30.2–32.4 s | 17.3–18.6 s | pass |
| Cache size, 1M cells | 695–733 MiB | 107–108 MiB | — |
| Decks: cold open / reopen (500 slides) | 0.70 / 0.29 s | 0.38 / 0.22 s | pass |

| Area | Change | Effect |
|------|--------|--------|
| Reopen (`RevFileSync`, `_SheetsPlan`) | Viewport-first from the cache: structure + the plan's first block, outbox on top, ready; the rest streams in through the bootstrap plan with buffered ops replayed on rows read at an older store revision and the overlay re-seeded (06 §5.3) | P8 28.6–47.1 s → 0.28–0.43 s |
| Bootstrap end | `markComplete` stores the bootstrap's revision (files without ops since their download reopened as partial caches and downloaded again) and drops the coverage keys | reopen works after any download |
| Cache layout (`RevDomainRows`) | Integer file ids; cells grouped per sheet row (one record per row); compact binary rows; an id index (`rev_cell_id`) written in one sorted insert when a bootstrap completes | 700 → 112 bytes per cell; reading 1M cells 13.8–17.7 s → 1.4–2.7 s |
| Page writes (`RevFileSync`, `RevLocalStore.applyPages`) | Not awaited by the model or ready; backpressure on the oldest writes beyond 120k rows; adjacent pages in one transaction; new cell rows in one round trip to the database worker | P6 (ready no longer waits for the 38k-row structure write); store write per page 145–168 → 27–34 ms; P7 |
| Planner (`wonky_sheets_core`, `wonky_sync_models`) | One cell id per written cell, `Uuid5` without per-call allocations; row/column number formats once per row/column; rank buckets instead of a comparison sort | P9 planner 12.6 → 5.6 s (benchmark) |
| Model and engine (`wonky_sheets_core`) | Cells out of the owner map; engine cell keys as records; range index pending entries bucketed by row blocks; no per-cell format map for cells without format columns; inserts of loaded rows not copied (`RowChange.loaded`) | P9, P7 |
| Outbox (`wonky_revlog` chunker) | Chunks of one plan that can't fit together are not composed to find out | P9 (each of the 207 chunks of the import composed two full chunks) |
| Plan walk (`_SheetsPlan.nextCells`) | Each row handed out once (no copy of the missing rows per block), so 3 cell pages stay in flight | P7 |


## R7: wire and server (2026-10-19)

The server and wire side of P3–P7, P10 and P11 (spec 17 As built 25), measured with the server
suite at full scale (two runs; the second on a quieter machine) and the Sheets client suite
once more with the new page format.

| Gate | Before (2026-10-18, same machine) | R7 | Result |
|------|-----------------------------------|----|--------|
| P3 server commit, 100 changes, p95 | 13.1 ms | 11.4 ms | pass |
| P4 server commit, 4,992 changes, p95 | 322 ms | 250 ms (282 ms while other suites ran) | pass |
| P6 cold open, server part (1M cells) | 1,131 ms | 453–543 ms | pass |
| P7 complete download, server part (1M cells): pages / decode / model | 31.7 s: 15.2 / 6.8 / 9.1 s | 7.1–7.3 s: 2.6 / 0.8–0.9 / 3.4 s | pass |
| P7 bytes on the wire (1M cells) | 28.7 MiB | 20.7 MiB | — |
| P7 complete download, client with SQLite | 13.8–14.5 s (R7 client) | 12.6 s (in-process page serving 2.6 s) | pass |
| P10 new file of 1M cells (one transaction) | 65.5 s | 37.6–38.0 s | pass |
| P10 server change of 1M cells (207 ops) | 56.0 s | 41.0–42.3 s | pass |
| P11 storage per cell | 210 B | 238 B (`fillfactor = 85`) | pass |

| Area | Change | Effect |
|------|--------|--------|
| Page format (`wonky_revlog` codec) | Version 2: binary, columnar, ids once, per-column blocks (presence bitmap, UUID/string dictionaries, varints, float64, bit-packed booleans, delta-coded times), zlib (level 1) where it saves ≥ 20 %; negotiated with `RevPageRequest.format`, version 1 still served and decoded; null columns left out of decoded rows | 13k-cell page 360 → 250 KB, encode 52 → 4 ms, decode 64 → 13 ms; the model takes the leaner rows faster (P7 model 9.1 → 3.4 s) |
| Server pages (`rev_pages.dart`) | One row of typed arrays per table (`array_agg`, `uuid_send`) into `RevPageBuilder`, no JSON per row; cell pages probe `(sheetId, rowId)` once per sheet row (`LATERAL … OFFSET 0`) | per page ~190 → ~35 ms; with stale statistics `rowId = ANY(…)` went through `cell_col_idx` and read the whole sheet (2.4 s per page) |
| Statistics (`RevAnalyze`) | `ANALYZE cell` in the background after every 100,000 committed cell inserts | big new sheets get sane plans before autovacuum notices |
| Client pages (`RevFileSync`, `RevPageDecoder`) | 3 cell pages in flight, blocks split over free slots, decode in an isolate per page (native) or in 8 ms slices (web) | fetch and decode overlap with applying |
| Prefetch (`RevSql.fetchByIds`) | Typed arrays per table (UUIDs as text), one statement | 5,000 cells 65 → 35 ms (A/B in one process) |
| Writes (`RevSql.upsert`) | One binary array per column (`unnest`); existing rows `UPDATE`d with only their changed columns; `fillfactor = 85` on `cell` (`RevStorage`) | 5,000 updated cells 108 → 55 ms with fillfactor (73 ms without; A/B); inserts 85–92 → ~63 ms per 5,000 |
| Op log (`rev_log_service.dart`) | The applied form is encoded and gzipped once; an all-insert op's view reuses it; file creation builds no views and answers its prefetch from memory (`_CreatedRows`) | ~65 → ~25 ms per 5,000-cell op; creation prefetch 31 → 0–3 ms |

Not measured: the web client (OPFS) with the new format and the sliced decoder, and P2.
