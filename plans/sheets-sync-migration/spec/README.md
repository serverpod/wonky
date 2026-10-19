# RevLog implementation specification

**Status:** draft for review (2026-10-18). This specification is meant to be implemented from
directly, assuming the migration is accepted (gate G1 in [10](10-work-breakdown.md)). It builds on the
tech spike ([../01-tech-spike.md](../01-tech-spike.md)) and the target design
([../02-target-design.md](../02-target-design.md)); where they disagree, **this folder wins**.

**What RevLog is.** A server-sequenced, revision-ordered log of row changes, streamed over a
Serverpod stream with a durable client outbox and cache. It is Write's architecture, without
operational transform, because Sheets and Slides address everything by stable id. It replaces
the vendored `serverpod_offline_sync` CRDT engine for Wonky Sheets and Wonky Slides.

| # | File | Contents |
|---|------|----------|
| 01 | [Decisions, terms, limits, configuration](01-decisions.md) | RD-1…RD-22, decided review questions Q1–Q3, limits, config keys |
| 02 | [Data model](02-data-model.md) | `rev_file`, `rev_op`, `rev_hook_state`; domain tables as server tables; removed and changed tables; client cache DDL; `RevSchema` |
| 03 | [Changes, change sets, apply rules, codec](03-change-sets.md) | `RowChange` semantics, `ChangeSet`, wire codec, apply/conflict rules, validation, repairs, overlay |
| 04 | [Protocol](04-protocol.md) | Endpoints, stream messages, pages, rejection codes, creation, sequences |
| 05 | [Server](05-server.md) | Binding interface, file state, submit algorithm and SQL, connection, bus, hooks, pages, server changes, headless cache, jobs, access, observability |
| 06 | [Client](06-client.md) | Session contracts, cache store, connection state machine, bootstrap and coverage, conflicts/outcomes, call-site migration, errors, sync status, hints |
| 07 | [Feature impact](07-feature-impact.md) | Every feature touching sync: today vs RevLog; offline scenario table |
| 08 | [Slides binding](08-slides.md) | What differs for Slides |
| 09 | [Tests, gates, acceptance](09-testing-and-acceptance.md) | Property tests, server/client/e2e tests, performance gates P1–P12, acceptance checklist |
| 10 | [Work breakdown](10-work-breakdown.md) | PRs R0–R8 with files, branch strategy, estimates (≈ 22.5 w) |
| 11 | [Spec adoption](11-spec-adoption.md) | Which sections of `specs/` change, in which PR |

## Read before implementing

1. The review questions in [01 §3](01-decisions.md) are decided (2026-10-18):
   - Q1: last arrival wins.
   - Q2: protected ranges are enforced by the server in this migration.
   - Q3: the domain-table classes are server-only.
2. Run R0 (baseline and prototype) and record the G1 decision.
3. Then follow [10](10-work-breakdown.md) PR by PR. Each PR's tests come from [09](09-testing-and-acceptance.md),
   and its spec updates from [11](11-spec-adoption.md).

## Evidence

The facts this spec relies on were gathered read-only from `main` at `bee8c7f`: the synced
models, the server dependents, the Sheets and Slides client dependents, and the Write
infrastructure to reuse. Key file references are inlined where they matter. Open technical questions for R0 are the
bulk-SQL form (05 §3.3) and the measurements of the performance gates (09 §6).
