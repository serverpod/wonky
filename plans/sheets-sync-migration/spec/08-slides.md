# RevLog spec 08 · Slides binding

Slides moves second (PR R7) onto the same packages. This file lists only what differs from
Sheets.

## 1. Schema and server binding

- **`slidesSchema`** (02 §4) has 12 tables: today's 13 minus `deck_change_log`.
- **Server-written tables:** none (`clientWritable` everywhere).
- **Deterministic-id tables:**
  - `slide_table_cell` (`SlidesIds.tableCellId`);
  - `chart_link` (`chartLinkId`);
  - placeholder instances (`placeholderInstanceId`);
  - theme copies and their parts (`themeCopyId`, `themePartId`).
- **`SlidesRevBinding`:**
  - **authorize** checks that exactly one owner FK is set on `slide_element` (there is no server element limit; 50,000 stays a client offline-storage cap).
  - **updateStats** keeps `{slides, elements}`.
  - **summarize** = `SlidesChangeSummary.of(changes, wasDeleted: …, current: …)` (`change_summary.dart:89`), with inserts counted as revivals for undo and restores (as `SlidesWriter.summarize` today).
  - **hooks:** `activity`, `versions`, `driveEdit`, `title`, `modified` (search text from deck titles, slide group titles, element text, table cells, notes), `comments`, `contentSize` (05 §6.2).
- **Plain references that are not cascaded** (03 §4.4; resolved at render time or repaired by the client):
  - `Deck.themeId`, `Slide.groupId`, `Slide.layoutId`;
  - `SlideElement.placeholderOf`;
  - `ChartLink.spreadsheetItemUuid`/`chartObjectId`;
  - `linkJson.slideId`.
- **Optional parents.** `SlideElement`'s optional owners (slide, layout, master, parent) are FK parents in `RevSchema` with `optional: true`. Exactly one owner must be set; this is a binding check in `authorize` (today an invariant in the planner).

## 2. Client binding

| Today (inventory slides-client) | With RevLog |
|---------------------------------|-------------|
| `SyncedDeckSession` (519 lines): subscribe, `waitForSpace`, load every row, journal ingestion, `DeckRemotePatch`, maintenance, membership role | `LoggedDeckSession extends DeckSessionBase`: §5.1 of the client spec with a **single structure page** (decks are small: every table, every row). `DeckReady` after it; then the outbox overlay; remote ops via `Overlay.build` and `applyRemote` (`origin: remote`); maintenance unchanged (§4) |
| `SlidesData.createPresentation` (reserved space, `registerPresentation`) | `SlidesRevLog.createPresentation`: online `drive.createPresentation(fileUuid, …)`; built-in templates and blank decks are created locally as the creation op group (online or offline); non-built-in templates on the server |
| `SlidesSyncController` (50k-element cap, purge, reservations) | `RevLogClient` (availability policy 06 §2.5, element cap without OPFS) |
| `SlidesWriter` (`DeckChangeLog`, `columnsIfVisible`, `summarize` with revivals) | Outbox + codec. Deterministic-id inserts merge per column on the server (03 §4.2), which replaces `columnsIfVisible`. Summaries computed as today, with undo inserts counted as revivals |
| `SlidesReplicaRecovery` (JSON of whole decks) | Outbox export (06 §8) |
| `local_conflicts.dart` (overwritten-text review) | `session.outcomes` (06 §6). Tracking of offline bodies is replaced by `offline: true` ops plus conflicts on `text`/`notes`/`code` columns. `forced` claims mark ops with `offline: true` semantics for review (the client sets a `forced` flag in the change set summary: `sum.forcedBodies`) |
| `mcp/agent_writes.dart` | `session.history` |
| AI "slide arrives by sync" polling | Wait for the `groupId` in `session.history` (06 §7.2) |
| Text editing LWW per body, soft locks, hints | Unchanged. Remote text arrives as a remote batch, and an unwritten local pending text still wins locally until it is committed |

## 3. Text bodies

Whole-body LWW per `text`/`notes`/`code` column is unchanged (Slides 02 §4.4, decision D6). The
sequencer makes the order "last to arrive" (Q1, decided). Because a server-side sequencer now exists,
Slides 02 §4.5 option C (character-level merge of concurrent edits of one body, by rebasing the
Delta against intervening ops) becomes feasible as a **follow-up**. It is not part of this
migration; record it in Slides 02 §4.5 as "unblocked by RevLog".

## 4. Maintenance (unchanged rules, new host)

`LoggedDeckSession.runMaintenance` runs `DeckMaintenance.detect` and `repairOp`:

- 1 s after remote batches and after ready;
- editors only;
- label "Repair presentation", `actorKind: user` with the summary flag `"repair": true` (03 §6), not undoable.

The 12 rules are: `noTheme`, `missingDeckTheme`, `orphanSlide`, `groupCycle`, `foreignParent`,
`missingParent`, `emptyGroup`, `danglingPlaceholder`, `dupPlaceholder`, `mergeOverlap`,
`codeWithoutState`, `orphanBuild` (`core/maintenance/deck_maintenance.dart:62-75`). Server
headless writes keep running the repairs before writing, as today (`ServerHeadlessDeck.writeSteps`).

## 5. Linked charts

`SlidesChartService` (`slides/charts/slides_chart_service.dart`) keys its snapshot and token
caches on the **source spreadsheet's `headRevision`** instead of `_changeLogMarker` (newest
change-log id + `COUNT`). Resolving reads the spreadsheet through
`HeadlessFileCache.sheets.open` (lease) and checks access as today.

## 6. Presenting

Presenter, audience and follower devices open the deck through the normal session. RevLog
changes only the propagation speed: edits during a presentation now reach the audience in about
one round trip instead of 0.2–2.5 s. The presentation session protocol (`slides/present/`) is
untouched.

## 7. Server writers

| Today | With RevLog |
|-------|-------------|
| `ServerSlidesWriter.write/apply/applyRecorded/revert/reapply` | `RevLogService.submitServerChange` / `revert` / `reapply` with `SlidesRevBinding`. `ServerHeadlessDeck.writeSteps` keeps planning, the soft-lock check and the repairs, then submits |
| `DeckFactory.write`, `SlidesTemplateDecks.write`, `DeckCopies.copy` | `…changes()` + `createFile` (05 §8.3) |
| `SlidesVersionProvider.restore` | `submitServerChange(record: true, insertsAreRevivals: true)` |
| `HeadlessDeckCache` | `HeadlessFileCache.slides` (05 §9) |
| `deck_change_log_processor.dart`, `deck_drive_mirror.dart`, `deck_activity.dart`, `deck_comment_orphans.dart`, `DeckStorageSize`, `deck_change_log_pruning.dart` | Hooks (05 §6.2); the pruning job is removed |
| Sheets-internal imports used by Slides (`sync_db.dart`, `SheetsChangeRecords`, `SheetsMergedSignal`, `SpreadsheetFactory.rowCounts`, `ServerChangeRecord.spreadsheetUuid`) | All replaced by `platform/revlog` (neutral names), which removes the layering problem from code-quality slt #7 |
