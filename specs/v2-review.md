# Wonky Work v2 — review decisions

Decision record of the v2 review (2026-10) of the **Wonky Drive** ([wonky_drive/](wonky_drive/README.md)),
**Wonky Slides** ([wonky_slides/](wonky_slides/README.md)) and suite v2 specs (suite specs
marked "(v2)"). All 30 questions are decided; the specs carry each decision as a
**Decided (v2 review, Qn)** line where the question used to be. Nothing of v2 is implemented
yet; the build plan is in [14-roadmap.md](14-roadmap.md) (milestones M8–M11),
[Drive 05](wonky_drive/05-implementation-plan.md) (work packages D-1…D-18) and
[Slides 12](wonky_slides/12-implementation-plan.md) (work packages SL-1…SL-45).

## Summary

The user answered three questions directly and accepted the recommendation for all others:

1. **Name** (Q1): the suite is **Wonky Work** everywhere; the suite settings are *Wonky Work
   settings*.
2. **Landing page** (Q2): the site root `/` redirects to **Wonky Write's home** (`/write/`, the
   page with *Recent* and the templates) — not to Drive and not to the last used app. Wonky
   Drive stays at `/drive/` and is one click away in every home's left menu. *Superseded by
   B4: the landing app is now Wonky Drive.*
3. **Web only for now** (affects Q5, Q9, Q29, Q30): v2 is built, tested and shipped for the web.
   Desktop targets must keep compiling, but desktop-only features are deferred (native
   menubar, four desktop binaries and URL schemes, desktop packaging, multi-window, desktop
   printing extras, OS drag-and-drop in native builds) — suite [01 A13](01-architecture.md).
   Multi-window is off on the web too: **presenting is single-window** — full screen, or the
   presenter view (current/next slide, notes, timer) in this window, with the **audience view on
   another device or browser** joined to a presentation session ([Slides 10 §5.2](wonky_slides/10-presenting-and-pdf.md)).
   A presenting-only second window is recorded as a possible later addition.

Consequences worth knowing before building:

- New shared leaf packages: `wonky_code` + `wonky_code_flutter` (Q3), `wonky_rich_text` (Q4),
  `wonky_numfmt` (Q27), `wonky_sync_kit` + `wonky_sync_kit_flutter`, `wonky_fonts`,
  `wonky_spellcheck` (Q23) — all extracted in M8 without behavior change (suite 01 §2.1).
- The vendored offline-sync patch **OS-8** (space filter per sync endpoint, Q19) lands in M8,
  before the first deck space exists. *Superseded by RevLog (M13), which has no sync
  spaces.*
- Write's exports switch to the shared TextMate tokenizer in M10 (Q17, Q25). Done in SL-35.

## Suite and Drive

| # | Question | Decision | Recorded in |
|---|----------|----------|-------------|
| 1 | Suite name in the UI | **User:** "Wonky Work" everywhere; suite settings = *Wonky Work settings* | [00 §3](00-product-overview.md) |
| 2 | Where `/` lands | **User:** always Wonky Write's home (`/write/`); Drive via the left menu | [01 §2.4](01-architecture.md), [03 §2](03-app-shell-and-navigation.md), [05](05-drive-and-files.md) |
| 3 | Split `wonky_code` into pure-Dart + Flutter packages | Recommendation accepted: `wonky_code` (pure: tokenizers incl. the copied TextMate engine, languages, palettes, code layout) + `wonky_code_flutter` (`CodeView`, `CodeEditorField`) | [01 §2.1](01-architecture.md) |
| 4 | Slides rich text: extract `wonky_rich_text` instead of importing `wonky_write_core` | Recommendation accepted: extract; `wonky_write_core` re-exports | [01 §2.1](01-architecture.md) |
| 5 | Presenter view: single-window exception vs second device only | **User (web only):** no exception in v2 — presenter view in this window, audience on another device or browser; a second window is a possible later addition | [03 §1](03-app-shell-and-navigation.md), [Slides 10 §5.2](wonky_slides/10-presenting-and-pdf.md) |
| 6 | Replace Help › *Report a problem* with *Report a bug* | Recommendation accepted: replace in the Help menu; `shell.help.feedback` stays registered | [03 §3.2](03-app-shell-and-navigation.md) |
| 7 | Folders in app homes | Recommendation accepted: only folders containing the app's kind (`kindMask`) | [03 §3.3](03-app-shell-and-navigation.md), [05 §3.2](05-drive-and-files.md) |
| 8 | *Report a bug* target | Recommendation accepted: prefilled new-issue link (app, version, platform, browser — no user content) | [03 §3.4](03-app-shell-and-navigation.md) |
| 9 | Desktop: one combined binary vs four apps | **User (web only):** desktop deferred; four binaries remain the plan when desktop work resumes | [03 §6](03-app-shell-and-navigation.md), [01 A13](01-architecture.md) |
| 10 | Where *Keyboard shortcuts* settings live | Recommendation accepted: Wonky Work settings, groups *Shared* / *<App>* | [04 §4](04-auth-and-accounts.md) |
| 11 | Malware scanning of uploads | Recommendation accepted: not in M8; revisit before anonymous/public sharing | [13 §6](13-security-and-operations.md) |
| 12 | Chunked resumable uploads | Recommendation accepted: whole-file retry in M8; chunking only if telemetry needs it | [Drive 02 §4.3](wonky_drive/02-files-uploads-previews.md) |
| 13 | Convert uploads (CSV/DOCX…) by default | Recommendation accepted: no; a Drive setting (default off) | [Drive 02 §7.3](wonky_drive/02-files-uploads-previews.md) |
| 14 | Do previous file versions count against the quota | Recommendation accepted: yes | [Drive 02 §9](wonky_drive/02-files-uploads-previews.md) |
| 15 | Grace period for users already over 50 MB | Recommendation accepted: none (non-destructive over-quota state + notice) | [Drive 03 §9](wonky_drive/03-storage-quota.md) |
| 16 | Restore from trash when over quota | Recommendation accepted: never blocked (trash already counts) | [Drive 03 §9](wonky_drive/03-storage-quota.md) |
| 17 | Code tokenization in exports differs from the editor | Recommendation accepted: accepted until the shared tokenizer is used by exports (M10, Q25) | [Write 04 §15.5](wonky_write/04-editor.md) |

## Slides

| # | Question | Decision | Recorded in |
|---|----------|----------|-------------|
| 18 | Concurrent text edits in one text box | Recommendation accepted: soft lock + LWW per text body in v1; three-way merge on receive P2 | [02 §4.5](wonky_slides/02-data-model.md) |
| 19 | Every replica downloads every space kind | Recommendation accepted: vendored offline-sync patch OS-8 (space filter per sync endpoint), in M8. **Superseded by RevLog (M13)**: each client loads only the files it opens or keeps offline | [17](17-revlog-sync.md) part 1 (RD-9, RD-13) |
| 20 | Text editor for text boxes | Recommendation accepted: super_editor overlay, confirmed by a week-1 spike of M9 (SL-4) | [03 §6.1](wonky_slides/03-editor-canvas-and-objects.md) |
| 21 | Where the Animate UI lives | Resolved before the review: the inspector's Animate tab; `slides.panel.animate` is an alias | [04 §7.1](wonky_slides/04-screens-menus-toolbar.md) |
| 22 | Nested slide groups | Recommendation accepted: one level in v1; `parentId` reserved | [04 §5.12](wonky_slides/04-screens-menus-toolbar.md) |
| 23 | Shared package names | Recommendation accepted: `wonky_sync_kit` (+ `wonky_sync_kit_flutter`; replaced by `wonky_revlog` + `wonky_revlog_flutter` in M13), `wonky_fonts`, `wonky_spellcheck` (engine; Flutter glue and emoji picker into `wonky_app`) | [01 §2.1](01-architecture.md), [12 §8](wonky_slides/12-implementation-plan.md) |
| 24 | What a printed/thumbnail slide shows when it has builds | Recommendation accepted: authored layout with all content; P1 option *Show final animation state* | [06 §9.6](wonky_slides/06-animations-and-transitions.md) |
| 25 | Write exports switch to the shared TextMate tokenizer | Recommendation accepted: yes, in M10 with a golden diff review (only token colors change) | [07 §2.2](wonky_slides/07-code-blocks.md) |
| 26 | TextMate engine: copy into `wonky_code` vs upstream split | Recommendation accepted: copy now (M8 extraction), propose the upstream split later | [07 §2.2](wonky_slides/07-code-blocks.md) |
| 27 | Number formats for charts outside Sheets | Recommendation accepted: extract `wonky_numfmt` (M8, with `wonky_charts`) | [08 §2.5](wonky_slides/08-charts-from-sheets.md) |
| 28 | Linked chart auto-update | Recommendation accepted: client-side in M10; server reverse index in M11 only if needed | [08 §5.5](wonky_slides/08-charts-from-sheets.md) |
| 29 | Presenter view windows | **User (web only):** single window — presenter view here, audience on another device or browser, one presentation-session state model; no second local window in v2 | [10 §5.2](wonky_slides/10-presenting-and-pdf.md) |
| 30 | Desktop multi-window | **User (web only):** deferred (no spike in v2); recorded with the possible later second window | [10 §5.3](wonky_slides/10-presenting-and-pdf.md) |

## Decisions during the build

Decided by the user after the M8 check (D-18), while building M9–M11.

| # | Question | Decision | Recorded in |
|---|----------|----------|-------------|
| B1 | Fetch and self-host pdf.js (~4 MB) for Drive's PDF preview | **User:** "No need for previews" — no PDF previews in v2. PDFs show the *Download* card like every other non-previewable file; the PDF viewer, `tool/fetch_pdfjs.sh`, `dartPdfJsBaseUrl` and `printing` in `wonky_drive` were removed | [Drive 02 §6.3](wonky_drive/02-files-uploads-previews.md), [Drive 05 S-D1](wonky_drive/05-implementation-plan.md) |
| B2 | Spreadsheet size for the quota: exact stored bytes vs a content estimate | **User:** "an estimate is ok" — count content (non-empty cells, rows/columns with non-default properties, objects at a fixed cost, a small base), not stored rows; a new empty spreadsheet costs a few KB instead of ~80 KB | [Drive 03 §11](wonky_drive/03-storage-quota.md) |
| B4 | Landing app and the left menu's app order | **User:** Drive is the default landing app (`/` → `/drive/`, replacing Q2) and comes first in the left menu, then a divider, then Write, Sheets, Slides (short names, no "Wonky"); app homes have no *+ New* (they create from the template strip), Drive shows *+ New* in the top bar while its menu is collapsed | [suite 01 §2.4](01-architecture.md), [suite 03](03-app-shell-and-navigation.md), [Drive 04 §2](wonky_drive/04-screens-menus.md) |
| B3 | Build the phone remote, rehearse timings and the same-browser fast path (SL-41) for M11 | **User:** on hold — the first iteration of Slides ships without them; the server pairing and the fast-path core stay (tested, not wired), the feature `remoteAndRehearse` stays off; presenter view + audience on another device cover presenting | [Slides 12 SL-41](wonky_slides/12-implementation-plan.md), `TODO.md` "Wonky Slides — later" |
