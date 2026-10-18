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
| P3 | Server commit, 100 changes | p95 < 15 ms | p95 13.5 ms (p50 10.9); before: 19.1 | pass (tight; 22 ms in a run right after the 1M imports while Postgres vacuums) |
| P4 | Server commit, 4,992 changes | p95 < 300 ms | p95 288–306 ms (p50 248–280) over three runs; before: 334–495 | borderline |
| P5 | DB transactions while idle (31 s, 2 connections open, minus the same window without connections) | 0 | 0 | pass |
| P6 | Cold open of 1M cells → ready, server part (RevInit, structure pages, first cell page, decode, model) | < 1.5 s | 1.07–1.12 s | pass |
| P6 | Cold open of 1M cells → `WorkbookReady`, client with SQLite | < 1.5 s | 1.44 s (2.0 s in another run); 100k: 1.56 s → 0.55 s | borderline |
| P6 | Cold open of a 500-slide deck → `DeckReady` | < 1.5 s | 0.70 s | pass |
| P7 | Complete download of 1M cells, server part (pages + decode + model, no SQLite) | < 15 s | 31.2 s (pages 14.8, decode 6.4, model 9.4); before: 44.1 | **miss** |
| P7 | Complete download of 1M cells, client with SQLite | < 15 s | 98–101 s; 100k: 17.4 s → 5.2 s | **miss** |
| P8 | Reopen from the cache, 1M cells → `WorkbookReady` | ≤ 2.75 s | 28.6–47.1 s (rows read 13.8–17.7 s, model 8.2–12.1 s); 100k: 4.5 s → 1.9 s | **miss** |
| P8 | Reopen of a 500-slide deck from the cache | ≤ 0.55 s | 0.29 s | pass |
| P9 | 1M-cell local import into the outbox | < 30 s | 30.2–32.4 s, of which the Sheets planner + model 26.0–26.5 s and the outbox write 4.2–5.9 s | miss (planner) |
| P10 | Server import of 1M cells as a server change (`SheetsServerWrites.apply`, 207 ops) | < 60 s | 57.8 s; before: 83.4 s | pass (tight) |
| P10 | Import of 1M cells as a new file (`createSpreadsheetFromSheets`, one transaction) | < 60 s | 63–69 s; before: 79.3 s | **miss** |
| P11 | Storage per non-empty cell (`cell` incl. indexes and TOAST) | ≤ 250 B | 210 B (+30 B of `rev_op` payload per imported cell, pruned after 30 days) | pass |
| P12 | Commit on the warm 200k file with 20 protections, editor, 1 / 100 changes | p95 < 30 ms | p95 5.6 / 14.2 ms | pass |
| P12 | Cold headless loads inside the lock while a connection is open | 0 | 0 | pass |

### Other numbers

| Metric | Measured |
|--------|----------|
| Headless cold load, 1M / 200k cells (05 §9) | 22.3 s (rows read 13.5 s, model 8.2 s) / 4.4 s |
| Post-commit hooks of the 1M-cell server change | 7.7 s |
| Op throughput, 2 editors × 250 single-cell ops at once | 135–220 ops/s |
| Single-cell edit → outbox durable in SQLite (1M-cell file), online / offline | p95 4.7 ms / 4.0 ms |
| Outbox drain of a 1M-cell local import to the in-process hub (207 ops) | 200.8 s → 111.6 s (the client handles an ack of 5,000 changes in ~130 ms; the rest is the in-process fake server) |
| Store write of one 13k-cell page (`RevLocalStore.applyPage`) | 145–168 ms |
| SQLite cache size, 1M cells | 695–733 MiB (~700 B per cell) |

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
