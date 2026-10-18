# RevLog spec 11 · Adopting the spec into `specs/`

When the migration is accepted, the RevLog spec moves into `specs/` and the existing specs are
updated **in the PR that implements each part** (AGENTS.md: "update the spec in the same
change"). This list was produced by searching `specs/` for the old sync vocabulary:
offline-sync, CRDT, reserved spaces, `ChangeLog`, `DeckChangeLog`, `syncTablesHash`,
`SpaceSubscription`, `register*`, commit hints. The count of hits per file is in parentheses.

## 1. New suite spec

**`specs/17-revlog-sync.md`** is the merge of spec files 01–06 and 09 §6 of this folder
(decisions, data model, change sets, protocol, server, client, performance gates).

- `specs/README.md` adds it to the suite table and to the reading order (after 12).
- `12-offline-and-sync.md` §2 is replaced by a pointer to it.

Spec files 07, 08 and 10 become sections of the app specs and the roadmap (below). Spec file 11
(this file) is not adopted.

## 2. Suite specs

| File (hits) | Sections to change | PR |
|-------------|--------------------|----|
| `README.md` (3) | Reading order item 4 ("Write OT vs Sheets/Slides offline-sync"); conventions: `database: sync` in models; the v2-built note (code-quality CQ-65) | R6 |
| `01-architecture.md` (17) | §1 decisions (A10 "Slides reuses the Sheets sync stack" → RevLog for both; add the G1 decision); §2 repository layout (packages: `wonky_revlog`, `wonky_revlog_flutter`; remove `wonky_sync_kit*`; `wonky_sync_models` becomes pure); §2.1 dependency rules; §2.3 vendored packages (remove `serverpod_offline_sync`); §6 configuration (`revlog` section, removed `maxActiveSpacesPerUser`); §7 protocol versioning (`revSchemaHash`, `minClientVersion` 3.0.0, no lock-step releases) | R3, R6, R8 |
| `05-drive-and-files.md` (6) | `createSpreadsheet`/`createPresentation` with `fileUuid`; removal of `registerSpreadsheet`/`registerPresentation`; `PendingDriveOp` kinds; *Make available offline* without membership | R3, R7 |
| `06-sharing-and-permissions.md` (1) | Enforcement for spreadsheets and presentations: ACL checked per submit and on streams (no membership mirroring). §3: protected ranges are **no longer advisory**: they are enforced by the server (RD-19) | R3 |
| `07-collaboration.md` | Latency expectations; version history framework: revision-based windows for Sheets and Slides | R4 |
| `08-commands-and-undo.md` | `sheets.serverChange` / `slides.serverChange` backed by op groups (no inverse files) | R4 |
| `09-mcp.md` | `sync_version` = file revision; server writes through `submitServerChange` | R4 |
| `10-ai-assistant.md` | One op group per assistant run; Suggest shadows copy-on-write | R4 |
| `11-quality-testing-accessibility.md` (2) | Performance budgets: 09 §6 gates | R6 |
| `12-offline-and-sync.md` (23) | Header table (Sheets/Slides rows → RevLog; local stores `sheets_cache_<user>.db`, `slides_cache_<user>.db`). §2 replaced by a pointer to 17 plus a short summary. §2.6 removed. §3 shell: `PendingDriveOp` kinds. §4 upstream requirements table **removed**. §5 staged limits replaced by 17's gates | R6, R7, R8 |
| `13-security-and-operations.md` (1) | Threat model: protected ranges enforced server-side (RD-19). Scheduled jobs (`revlog.pruneOps`, `revlog.hookSweep`, `revlog.repairStats`; removed `evictSpaces` and the change-log prunes); server-side validation of row writes; op-log retention (30 days) as a privacy item | R3, R4 |
| `14-roadmap.md` (5) | New milestone **M13 RevLog** with gates G1–G3 and the PRs of spec file 10 | R0 |
| `15-writing-tests.md` | Test doubles (`FakeRevServer`, `TestRevClient`, device harness); property tests of 09 §2 | R1 |
| `v2-review.md` (2) | Q19 (space filter per endpoint): mark "superseded by RevLog (M13)" | R7 |

## 3. Sheets specs

| File (hits) | Sections to change |
|-------------|--------------------|
| `wonky_sheets/README.md` (3), `01-overview.md` (5) | Sync description (offline-first via RevLog; offline editing unchanged; opening large files) |
| `02-data-model.md` (10) | §1 principles: S1 (one spreadsheet = one **file**), S8 (named columns: now a codec property, the lint test is removed), S10 (op log instead of a synced `ChangeLog`). §2 unchanged (ids). §3 "Synced tables" → "File tables" (server tables with `fileId`, `revision`). §3.7 `ChangeLog` removed. §4 client-only tables → the client cache (17). §5 server-only tables updated (`cell_history`, `server_change_record`, `script_user_property`). §6 ingestion (`Overlay` instead of `RowPatch` and the journal; viewport-first from the server). §7 writes and undo (outbox; chunking into op groups; the OS-7 numbers replaced by the gates). §8 maintenance: `WorkbookMaintenance` now wired |
| `03-grid-and-editing.md` (1) | §2.8 loading UI (no download percentage); §16 protected ranges in the grid (server rejections of offline edits and the copy offer); §20 hints |
| `04-screens-menus-toolbar.md` (4) | Loading and offline strings; Settings › Offline & storage |
| `05-formula-engine.md` (9) | References to the CRDT/offline engine in the reference-token rationale (keep the design; reword "offline-sync" to "concurrent edits") |
| `07-data-tools.md` (1) | §10.3 enforcement: remove the "Advisory" bullet; add server enforcement (05 §3.5), `WriteIntents` in the core, version restore pre-check; writer references |
| `08-charts-and-objects.md` (2), `11-import-export-print.md` (4) | Writer references (`SheetsWriter`/`SheetsBulkWriter` → session / `submitServerChange`) |
| `09-scripting.md` (12) | User properties storage (server table + client cache); trigger offline detection (`op.offline`); compile after `whenSynced` |
| `10-collaboration-history.md` (27) | §2 hints (cell/range removed); §5.1 capture at a revision, revision windows; §5.3 restore via server change (with the protection pre-check); §9 "Rejected protected-range edits (advisory)" replaced by server rejection; §10 add scenarios 23–24; §6 cell history sources; §9 conflict UX per Q1; §10 scenario table → 07 §6; §16 tests |
| `12-mcp-and-ai.md` (11) | Server writer (`submitServerChange`), headless cache leases, `sync_version`, shadows |
| `13-implementation-plan.md` (18) | §7.5 performance suite → 09 §6; risks R2/R3 updated (U1–U5 gone) |
| `STATUS.md` (7) | Sync and data-layer rows rewritten after G2 |

## 4. Slides specs

| File (hits) | Sections to change |
|-------------|--------------------|
| `wonky_slides/README.md` (2), `01-overview.md` (4) | Sync description |
| `02-data-model.md` (24) | Principles (one deck = one file; P9 change log → op log); §3 tables; §4.4–4.5 (LWW by arrival; option C "unblocked by RevLog"); §9 sync, spaces and creation → RevLog creation (no reserved spaces); §9.2 decided Q19 superseded; §10 maintenance (host changes, rules unchanged); §12 undo/server changes; §14 synced-schema releases removed |
| `04-screens-menus-toolbar.md` (2) | Loading/offline strings |
| `08-charts-from-sheets.md` (4) | Linked-chart cache keyed on the spreadsheet revision |
| `09-collaboration-history.md` (17) | §2 hints (unchanged behavior, new transport timing); §4 versions (revision windows); §6.3 overwritten-text review fed by outcomes |
| `11-mcp-and-ai.md` (10) | Writers, `sync_version`, shadows |
| `12-implementation-plan.md` (30) | Historical (M9–M11); add a note pointing to M13 instead of rewriting history |
| `STATUS.md` (9) | Sync rows rewritten after G3 |

## 5. Drive specs

| File (hits) | Sections to change |
|-------------|--------------------|
| `wonky_drive/03-storage-quota.md` (2) | Content size estimators by `fileId` |
| `wonky_drive/04-screens-menus.md` (1) | Offline badges source (`RevOfflineProvider`) |
| `wonky_drive/05-implementation-plan.md` (8), `STATUS.md` (3) | D-4/D-6 notes: "superseded by RevLog (M13)" |

## 6. Write spec

`wonky_write/04-editor.md` (1 hit): wording only. Write's protocol (`03-sync-protocol.md`) is
unchanged, apart from the bus `immediate` flush (R2) and the robustness fixes (CQ-4/5/23), which
are recorded in its §2.

## 7. Repository docs

- `AGENTS.md`:
  - the package table (`wonky_sync_kit*` → `wonky_revlog*`);
  - the Sheets/Slides state paragraphs (the sync description);
  - the browser-check note about "Downloading spreadsheet…" if mentioned;
  - the claim that the Sheets scripting UI isn't built (CQ-65).
- `TODO.md`: remove "Sync / data layer" engine items, the U-requirements and the kit follow-ups; add the RevLog follow-ups:
  - Slides character-level text merge;
  - `cascaded` info toast (P2);
  - optional rename of `wonky_sync_models`.
