# Sheets sync migration — tech spike and plan

**Status:** proposal (2026-10-17), not a decision. Nothing in `specs/` changes until it is accepted.
**Scope:** Wonky Sheets' sync and offline layer (and Wonky Slides', which shares it).
**Separate from** the code-quality plan in [`plans/code-quality-review/`](../code-quality-review/README.md).
The two can be read, accepted or ignored independently. Where an improvement item only applies
if this migration does *not* happen, the code-quality plan says so.

| Document | Contents |
|----------|----------|
| [01-tech-spike.md](01-tech-spike.md) | How sync works today in Write, Sheets and Slides, where Sheets' sync spends its time (with evidence), the options and the performance comparison |
| [02-target-design.md](02-target-design.md) | The proposed system: a server-sequenced revision log of row changes ("RevLog") for Sheets (and Slides) |
| [03-implementation-plan.md](03-implementation-plan.md) | Phases, work packages, files, tests, gates, estimates, risks, spec updates, and the removal list |
| **[spec/](spec/README.md)** | **The implementation specification** (2026-10-18): decisions (review questions Q1–Q3 decided), exact data model and DDL, change-set codec and apply rules, protocol, server and client algorithms, feature-by-feature impact, the Slides binding, tests and performance gates, PR-by-PR work breakdown, and the list of `specs/` sections to update. Where it differs from 01–03, it wins |

## The short answer

**First, a correction to the premise.** Write and Slides do **not** share a sync system:

| App | Sync today |
|-----|------------|
| Write | Server-authoritative **OT** (Quill Delta) over a Serverpod stream; Postgres op log ordered by revision; local snapshot + outbox |
| Sheets | **CRDT** replication (`serverpod_offline_sync`, vendored), field-level last-writer-wins by HLC; local SQLite replica is the primary store |
| Slides | **The same CRDT engine and the same `wonky_sync_kit` code as Sheets** (`SlidesSyncController extends AppSyncController`, `SlidesReplica extends SyncReplica`, server `SpaceSync.sync(kind: deck)`) |

So "move Sheets to the system Write and Slides use" can only mean **move Sheets onto Write's
architecture**: a server-authoritative, revision-ordered op log over a Serverpod stream, with a
durable outbox and a snapshot+tail cache. This spike evaluates exactly that. Slides would have
to follow, or we would keep the whole CRDT stack alive for Slides alone.

**Would it improve performance? Yes, and by a lot, in everything except the in-memory editing
path** (keystroke → model → recalculation → paint), which doesn't change. The current engine's
costs are structural rather than tuning problems:

- **Polling.** Each connected device runs a lock-step loop: a 1 s idle wait plus a 200 ms sleep.
  Remote edits take 0.2–2.5 s to arrive, hidden today by "commit hints" over presence.
- **Full metadata scans on every sync cycle, on both ends.** With no HLC index, each stream
  rescans all CRDT metadata of the user's spaces about every 1.2 s, even when idle.
- **About 5 database rows per cell.** Each cell has its domain row, one `crdt_data_rows` row and
  three or more `crdt_data_fields` rows. A one-cell edit costs about 8–10 SQLite writes.
- **N+1 cold download.** A new replica costs one `SELECT` per changed row, about 100k point
  queries for a 100k-cell sheet. Both sides also buffer the whole sync cycle in memory.
- **Lock-step synced schema.** Every synced-schema change forces a rebuild of the CRDT
  projection.

A server-sequenced log fixes these by design: edits are pushed (~1 round trip), there are no
per-field metadata rows, cold open reads pages server-side with viewport-first loading, and an
idle server has no per-device work.

**Why the move is cheaper than it sounds:** Sheets was designed for a CRDT, and that design helps
here. Row and column ids are stable, cell ids are deterministic, and formula references are
id-based. Operations therefore barely need transforming: the rebase step reduces to
"last-to-arrive wins per column, deleting a row or column wins". **No spreadsheet OT algebra is
needed.**

The in-memory model, the mutation planner, the formula engine, undo and the MCP planning already
use an engine-neutral `RowChange` format (`WorkbookModel.applyChanges`, `SheetsMutationPlanner`).
The editor sits behind a clean seam (`WorkbookSession`; Slides: `DeckSession`). What changes is
the persistence and replication layer only.

**Recommendation:** run Phase 0 (≈ 1.5 weeks: baseline measurements and a throw-away prototype
of the sequencer). If the prototype meets the gates (§ "Gates" in the plan), migrate Sheets,
then Slides. Then delete the vendored 26k-line CRDT engine, the space machinery (reservations,
subscriptions, the kind filter, purges) and the change-journal triggers. Nobody uses the apps yet,
so there is no data migration and no backward compatibility to keep.

Estimated effort: **≈ 16 engineer-weeks for Sheets, ≈ 5 for Slides, ≈ 2 for removal and specs**
(≈ 23 in total; AI-assisted implementation will likely compress it). Details in the plan.

## Key numbers

| Metric | Today (CRDT) | Expected with RevLog | Basis |
|--------|--------------|----------------------|-------|
| Remote edit visible to collaborators | 0.2–2.5 s (data), hints ~1 RTT | ~1 RTT + commit (≈ 50–150 ms same instance; ≤ 1 s cross-instance until the bus flush is fixed) | engine loop `engine.dart:71,290`; Write's path `ot_service.dart` |
| Server work per idle connected device | metadata scan every ~1.2 s | none | `collectPendingChanges`, no HLC index |
| DB rows per non-empty cell (server) | ~5 (domain + crdt row + ≥3 field rows) | 1 | `definition.sql`, OS-7 notes |
| Local writes per one-cell edit | ~8–10 SQLite row writes | 1 outbox insert (+ apply on ack) | `sync_writer.dart`, journal triggers |
| Cold open of a sheet not on the device | full engine download before ready (N+1 per row); 100k cells ≈ 100k point queries | viewport-first pages from the server; ready after the first page (target < 1 s for any size) | `engine.dart:614,845`; `SpaceOpening.waitForSpace` |
| Cold download, 1M cells | not measured (gate "< 60 s desktop / < 120 s web" never verified) | target < 15 s desktop / < 30 s web (paged, compressed) | Phase 0 measures both |
| Synced-schema change | lock-step hash + projection rebuild (OS-9) | ordinary server migration + client cache migration | suite 12 §4 U10/U12 |
| Code to maintain | vendored engine 26.4k LOC + kit ~3.1k + bindings ~3k | new kit ~4–5k LOC | file counts in 01 §8 |

The "expected" column is an estimate from the design. Phase 0 must measure the "today" column,
and Phase 6 must confirm the "expected" one.
