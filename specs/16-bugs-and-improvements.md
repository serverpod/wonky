# 16 · Bugs & improvements

**Bugs & improvements** replaces *Report a bug* (the GitHub new-issue link, [03 §3.4](03-app-shell-and-navigation.md))
and *Report a problem* (`shell.help.feedback`) with a public board inside Wonky Work. Users can:

- report bugs and suggest improvements, optionally with an annotated screenshot of the app;
- vote and comment on issues.

Admins pick what gets built and turn it into **tasks**. A task is one improvement, or several small bugs
grouped together, and comes with a ready-made prompt for a coding agent. Anyone can **claim** a task for
48 hours and contribute it as a pull request.

AI sorts every issue by kind, area and size, and checks that it is a genuine report and not offensive.
The decisions are made by [Jev](https://typesafe.ai/) and the writing by Gemini, both with internal keys
separate from the in-app AI (§6).

Status: **built** (milestone M12, [14](14-roadmap.md); work packages in §16, step 2 included). The
open and P1 items are in §17. On GitHub, only PRs linked to a claimed task are accepted, and each
PR gets an AI review against its task (§13). The integration is built and enabled by config
(`board.github.enabled`, default false).

## 1. Goals and principles

- **One obvious place**: a single button in every app, *Bugs & improvements*, opens the report
  dialog. The board is one click away from it.
- **Votes concentrate**: the report dialog shows similar issues while the user types and offers
  *Vote for this instead*. Duplicates are merged and their votes move to the remaining issue.
- **Public by default**: anyone can read the board, signed in or not. Writing needs an account.
- **Vetting at submit time**: AI checks each issue as it arrives. Clean issues go live at once, and
  only flagged issues wait for an admin.
- **Contributing is easy**: a published task holds everything a contributor needs. That is the
  setup steps (in `CONTRIBUTING.md`, versioned with the code), the prompt, the linked issues and
  their screenshots.
- **Suite rules apply** ([08](08-commands-and-undo.md), [03 §1](03-app-shell-and-navigation.md),
  [02](02-design-system.md)):
  - every action is a command, and every state change a user makes is undoable;
  - single window: the board is a page inside the current app;
  - the UI is built with `shad` and `wonky_ui`;
  - everything works in light and dark.

**Decided (with the user, 2026-10-15):**

| # | Question | Decision |
|---|----------|----------|
| B1 | Where the data lives | In Wonky (server tables). No GitHub issues; GitHub only receives PRs (§13) |
| B2 | Who sees the board | Everyone, including signed-out visitors |
| B3 | Screenshots | Opt-in. A warning about privacy, then an annotation editor that can cover sensitive areas. Screenshots are **public** with the issue, because the person fixing the bug needs them |
| B4 | Admins | Users whose (verified) account email is in a configured domain (`serverpod.dev`), via Google or email/password sign-in |
| B5 | Claiming | Only published tasks (selected by admins) can be claimed, for **48 hours**. (T-10) At most **3** claims at a time; 3 expired claims, or 2 issues removed by a moderator, block claiming for **2 weeks** (§8.4) |
| B6 | Comments | Yes, with simple Markdown formatting |
| B7 | Board location | A shared page in `wonky_app`, local to the current app (like Settings) |
| B8 | Task prompts | Written by AI and editable by admins; a written prompt publishes its task unless the lint holds it (T-11, §10.2) |
| B9 | Old *Report a problem* feedback | Folded into the new system (§12) |
| B10 | Grouping bugs | AI suggests bundles and admins confirm them. Admins can also group manually |
| B11 | Ideas accepted | Duplicate check while typing, vetting at submit, separate vote types for bugs and ideas, one status flow, notifications when things ship, contributor guide in the repo |
| B12 | Board AI | **Jev** (TypeSafe) for decisions, **Gemini** for writing. Internal keys `internalJevApiKey` and `internalGeminiApiKey`, kept apart from the in-app AI and its budgets (§6) |
| B13 | License | BSD-3-Clause (`LICENSE` at the repository root). Contributors sign the Serverpod CLA (`CLA.md`, the one serverpod/serverpod uses) through the CLA Assistant workflow (`.github/workflows/cla.yaml`; signatures in `serverpod/cla_signatures`) |
| B14 | Security contact | `security@serverpod.dev`, plus a `SECURITY.md` in the repository |
| G1 | PR gate | A required check plus a bot comment; PRs without a valid task are closed automatically after 7 days |
| G2 | Exempt from the gate | Members of the `serverpod` GitHub organization (for now) |
| G3 | Proving the PR author holds the claim | A per-claim code, shown only to the claimant, in the PR description |
| G4 | Where checks run | A GitHub App whose webhooks go to the Wonky server |
| G5 | Review strictness | Advisory at first (comment plus a neutral check); CI stays the hard gate |
| G6 | Scope per PR | One task per PR (a task may bundle several bugs) |
| G7 | Shipped | Automatic, when the deploy workflow succeeds with the merge commit included |

## 2. Concepts and glossary

| Term | Meaning |
|------|---------|
| **Issue** | A bug report or an improvement idea. Numbered `#123` (the row id). (Decided 2026-10-19.) Called *issue* everywhere users and contributors read it (UI, notifications, emails, MCP tool descriptions, the task prompts); the code, API, data and ids keep the old name *post* (`BoardPost`, `board_post`, `postNumber`, `shell.board.createPost`, `board.list_posts`, `/improvements/p/:number`), since ids never change ([08 §6](08-commands-and-undo.md)). Comments stay *comments* |
| **Kind** | `bug` or `idea` (user-visible: *Bug* / *Improvement*) |
| **Area** | Where the issue belongs: `drive`, `write`, `sheets`, `slides`, `suite` (shell, sign-in, settings, cross-app), `server` (performance, sync, email; not visible UI) |
| **Size** | `small` (one focused change, roughly one agent session), `medium` (one feature area, several files and tests), `large` (cross-package work, or a spec change needed first) |
| **Vote** | Ideas: up (+1) or down (−1). Bugs: up (+1) only — the same ▲ score ▼ control, ▼ disabled |
| **Score** | The sum of votes. The author's own automatic vote counts |
| **Task** | A unit of work an admin selected: one idea, one bug, or a **bundle** of related small bugs. Numbered `T-12`. Holds the contributor prompt and the claim |
| **Claim** | A signed-in user reserving a published task for 48 hours (§8) |
| **Admin** | A user whose account email domain is in `board.adminEmailDomains` (§9) |
| **Triage** | The AI pass over an issue: kind, area, size, verdict, duplicates (§6) |
| **Held** | An issue or comment hidden from the public until an admin reviews it |

## 3. Lifecycle

### 3.1 Issue status (public)

```
            ┌──────────── declined (admin, with reason)
            │
open ──► planned ──► done ──► shipped
  │      (in a task)  (PR merged)  (in a released version)
  └────► duplicate (merged into another post)
```

- `open`: live and votable. New issues start here once they pass moderation (§3.2).
- `planned`: the issue belongs to a published task. Votes stay open, and the issue links to its task.
- `done`: the task's PR is merged (§8.3).
- `shipped`: the deploy that contains the merge succeeded (§13.6). Admins can also mark it by
  hand.
- `declined`: an admin closes the issue with a reason ("Out of scope", "Works as intended", "Won't
  fix", or free text). Voting closes; comments stay open.
- `duplicate`: merged into another issue (§7.4). The page redirects to the target issue with a note.

### 3.2 Moderation state (separate from status)

| State | Who sees the issue | How it gets there |
|-------|-------------------|-------------------|
| `checking` | Author only ("Checking your issue…") | Just submitted, triage running (§6) |
| `visible` | Everyone | Triage passed; an admin approved it; or no AI is configured |
| `held` | Author ("Waiting for review") and admins | Triage flagged it, or community flags reached the threshold (§7.5) |
| `removed` | Admins only; the author sees "Removed by a moderator" with the reason | Admin removal |

Comments use the same states, except `checking`: comments are visible at once and triaged after
they are posted (§6.3).

### 3.3 Task status

```
draft ──► published ──► claimed ──► inReview ──► done ──► shipped
  │           ▲            │ (48 h expiry   │ (PR linked)
  │           └────────────┘  or release)   │
  └──► cancelled ◄──────────────────────────┘ (admin)
```

- `draft`: created by an admin from one or more issues. The AI prompt is generated (§10), and the task
  is visible to admins only. (T-11) There is no manual approval: the prompt job publishes the
  task as soon as it has written a prompt the lint (§10.2) does not flag. A task stays a draft
  only while the prompt is written, when the lint held it, or when the AI could not write it
  (`promptNote` says which); an admin then publishes it by saving the prompt. A published task
  nobody holds also goes back to `draft` while the AI rewrites its prompt after its issues
  changed or tasks were merged into it (§9.3).
- `published`: open for claims and listed under *Up for grabs*. Its issues become `planned`.
- `claimed`: reserved by one user until `claimExpiresAt`, listed under *Claimed* (with
  `inReview`). On expiry it goes back to `published` (§8.2).
- `inReview`: a PR passed the gate (§13.4), or an admin linked one. The claim no longer expires
  while the PR is open.
- `done`, `shipped`: as for issues, and they carry over to all linked issues.
- `cancelled`: the issues return to `open`.

## 4. UI

All UI is in `packages/wonky_app/lib/src/board/`, available in all four apps. Strings are in
`wonky_app_en.arb`; the user-visible name is **Bugs & improvements** for the report dialog, the Help menu, Settings › About and the command category, and **Contribute & build** on the board pages themselves (their breadcrumb root and page title, like the home menu entry; decided 2026-10-19).

### 4.1 Entry points

The *Report a bug* entry points are replaced in place. Each opens the **report dialog** (§4.2)
through `shell.board.report`:

| Where | Today | New |
|-------|-------|-----|
| Help menu ([03 §3.2](03-app-shell-and-navigation.md)) | *Report a bug* | *Bugs & improvements…* (`shell.board.report`) and *Browse Bugs & improvements* (`shell.board.open`) |
| Home left menu footer (`HomeSidebar`) | *Report a bug* | (T-5) *Contribute & build* (Lucide `wrench`, `shell.board.open`, key `home.footer.contribute`), *Report a bug* (`bug`, key `home.footer.reportBug`) and *Suggest an improvement* (`leaf`, key `home.footer.suggest`); the last two are `shell.board.report` with kind `bug` / `idea`, so the dialog opens on that kind |
| Editor title row (`EditorScaffold`, width ≥ 640) | bug icon | (T-5) *Report a bug* (`bug`, key `editor.reportBug`) and *Suggest an improvement* (`leaf`, key `editor.suggest`): `ShadButton.outline` size `sm`, as on the board page; icon buttons with tooltips between 640 and 1200 px. Each is `shell.board.report` with its kind |
| Sign-in screens (`auth_layout.dart`, key `auth.reportBug` → `auth.board`) | link | link that opens the **board page** (§4.4), not the dialog. Signed-out users read; *Report* asks them to sign in |
| Settings › About (`settings.about.reportBug` → `settings.about.board`) | link | button |
| Error card (`ErrorCard`, [03](03-app-shell-and-navigation.md)) | *Copy error details*, *Reload* | adds *Report this bug*: opens the dialog with kind Bug and the error attached (§4.2.4) |

The command ids `shell.help.reportBug` and `shell.help.feedback` keep working, because ids never
change ([08 §6](08-commands-and-undo.md)). Both become aliases: `reportBug` opens the dialog with
kind Bug, and `feedback` with the kind chosen in the dialog. When `board.enabled` is false, the
server's `config.json` sends `board: false`. `shell.board.report` then falls back to today's
GitHub link (`BugReportLink`, kept for that case).

### 4.2 Report dialog

`showBoardReportDialog`, `dialogKey: 'dialog.board.report'`, width 640 (full screen below
600 px). The screenshot is captured **before** the dialog opens (§5.1), so it shows the app as the
user saw it.

```
┌ Bugs & improvements ───────────────────────────────────────────────────┐
│ (•) Report a bug     ( ) Suggest an improvement                        │
│                                                                        │
│ Title  [ Pasting into a merged cell loses the formatting            ]  │
│ ┌ Similar issues ─────────────────────────────────────────────────┐   │
│ │ #412 Paste into merged cells drops styles   ▲ 14   [Vote instead] │   │
│ │ #388 Merged cells: paste behaves oddly       ▲ 3    [Vote instead] │   │
│ └──────────────────────────────────────────────────────────────────┘   │
│ What happened?         [ Markdown text area (B I ` 🔗 • ) ]            │
│ What did you expect?   [                                  ]            │
│ Steps to reproduce     [ 1.                                ] (optional)│
│                                                                        │
│ Screenshot   [thumbnail]  Edit · Remove      or  [+ Add screenshot]    │
│ ⚠ Screenshots are public. Cover names, emails and document content.   │
│                                                                        │
│ ▸ Details that will be included: Sheets 2.3.1 · web · Chrome 131 ·     │
│   dark theme · 1440×900 · /s/:id                                       │
│ [ ] Include the last error (2 min ago)                                 │
│                                                                        │
│ Posts are public and checked automatically by AI (Jev, Gemini).        │
│ Security issue? Don't post it here: email security@… (§11)             │
│                                           [Cancel]  [Post bug]         │
└────────────────────────────────────────────────────────────────────────┘
```

#### 4.2.1 Fields

| Kind | Fields | Stored as |
|------|--------|-----------|
| Bug | Title (required, 8–120 chars), *What happened?* (required), *What did you expect?*, *Steps to reproduce* | `title`, and a Markdown `body` built from `## What happened` / `## Expected` / `## Steps to reproduce` sections (empty sections omitted) |
| Improvement | Title, *What would you like?* (required), *Why would it help?* | `title` and body with `## Idea` / `## Why` |

- **Area** is not asked. Triage sets it, and the current app is a hint (`appHint`).
- Body limit: 10,000 chars (the same as comments, [07 §2](07-collaboration.md)).
- **Draft**: the dialog keeps its state in the user's local store while open, keyed by the app.
  Closing it (*Cancel* or `Esc`; the header has no close button) with content asks *Discard
  draft?*; *Keep draft* keeps it, and the next *Report* reopens it.
- Signed out: the dialog is not offered. `shell.board.report` opens the board page with a
  *Sign in to post* banner; invoked on a board page (the top bar's *Report a bug* / *Suggest an
  improvement*), it goes to sign-in and back to that page.

#### 4.2.2 Similar issues

- Debounced 400 ms after the title or body changes (minimum 3 words): `board.similar(text, kind)` returns up to 5
  visible issues (Postgres full-text search, §6.4). (T-10) Only issues one can still vote for:
  `open` and `planned`. Done and shipped issues are built, so they are not suggested (the client
  drops them too, for older servers).
- Each row has *Vote instead*. It casts the vote (bugs: *I hit this too*), closes the dialog after
  a confirmation toast, and keeps the draft in case the user comes back.
- (T-10) The row's `#412 Title` is a link (underlined on hover, the focus ring, Enter / Space;
  *Show #412 Title* for screen readers; key `dialog.board.report.similar.<n>.open`) that opens
  the issue's details in a dialog over the report dialog (`showBoardSimilarPostDialog`, key
  `dialog.board.similarPost`, max 640 px): the number and title, the kind, area and size chips,
  the status badge and the votes, the author line and the Markdown body (`board.getPost`;
  *Couldn't load this issue.* when it fails), scrolling at most 60 % of the window. Its actions
  are *Close* (and Esc, back to the report with the draft as it was) and *Vote instead* (*Voted*
  when already voted), which closes it and votes like the row's button. The single-window rule
  holds: the issue page is not opened from there.

#### 4.2.3 Screenshot

- *Add screenshot* opens the **screenshot editor** (§5.2) with the image captured at invocation.
  The editor's warning banner cannot be dismissed. There is no "attach without looking" path.
- After the editor's *Done*, the dialog shows a thumbnail with *Edit* (reopens the editor with the
  annotations still editable until posting) and *Remove*.
- The board page's *Report* button has no app state to capture, so it offers *Choose image…*
  instead (P1: an image file from the device, re-encoded on the client, max 5 MB).

#### 4.2.4 Included details (bugs only, shown before posting)

| Detail | Source | Notes |
|--------|--------|-------|
| App and version | `config.app`, `clientVersion` | |
| Platform and browser | `BugReportLink.currentPlatform`, `crossApp.browserLabel()` | Family + major version only |
| Theme, locale, window size | shell services | |
| Route | `router.state.uri.path` | **Ids replaced** by `:id` (UUIDs, numbers), query string dropped |
| Last error (opt-in checkbox, default on if an error happened in the last 10 min) | the error boundary's last report | Message (4,000 chars max) and the top 30 stack frames. Paths only, no values |

The details are public with the issue (`contextJson`) and rendered under *Details* on the issue page.

#### 4.2.5 After posting

- The dialog closes with the toast *Posted. Checking it now…*, with the action *View* (opens the
  issue).
- The issue page shows the `checking` state until the triage result arrives (live, §7.6). The
  result is *Your issue is live* or *Waiting for review: a moderator will look at it*.

**As built (BI-5):** `wonky_app/lib/src/board/report/` (`showBoardReportDialog`,
`BoardReportDraftStore` under `board.reportDraft.<app>` in the user store, `BoardIncludedDetails`
and `stripRouteIds`, `BoardSimilarSearch`, `BoardReportServices` with the last error, the capture,
the finisher and the upload transport as per-shell seams), `board/screenshot/` (the editor,
`flattenScreenshot`, the web JPEG encoder behind a conditional import) and
`board/report_commands.dart` (`shell.board.report {kind?, includeError?}`, `shell.board.open
{tab?}`, the aliases `shell.help.reportBug` / `shell.help.feedback`, hidden from the palette).
*Discard draft?* offers *Keep draft* and *Discard*; `Esc` returns to the dialog. The toast says
*Posted* when the issue is visible at once and *Posted. Waiting for review…* when it is held.
*Vote instead* goes through `shell.board.vote` (undoable) when it is registered. Posting uploads
the screenshot first, then runs `shell.board.createPost` (`report_commands.dart`; undo deletes the
issue, redo restores it) and tells open board pages through `BoardHub.changed`, so the lists,
counts and the Review tab refresh. `config.json` `board` defaults to true when absent.

**Layout (consistency pass):** the panel has `ShadDialog`'s surface — the theme's
`primaryDialogTheme` (popover color, dialog border, radius and shadow), its `large` title and
24 px side padding. Full screen without border or radius below 600 px. The actions follow
`ShadDialog` / `WonkyFormDialog`: *Cancel* then the primary on one row, stacked full width with
the primary on top below shad's `sm` breakpoint (640 px).

### 4.3 Board routes

The board routes are added to every app by `buildShellRouter`, next to `settingsRoutes()`. They are
**public**: the auth redirect lets `/improvements` and everything below it through when signed out.

| Route | Page |
|-------|------|
| `/improvements` | Board, tab *Improvements* |
| `/improvements/bugs` | Board, tab *Bugs* |
| `/improvements/tasks` | *Up for grabs* (published tasks nobody holds) |
| `/improvements/claimed` | *Claimed* (claimed and in-review tasks) |
| `/improvements/done` | Done and shipped issues (bugs and improvements; T-10: finished tasks are not listed) |
| `/improvements/review` | Admins only: moderation queue, bundles, drafts (§9.2) |
| `/improvements/search?q=…` | Search results across all issues (§4.4); also `closed=1`, `kind=bug` or `kind=idea` |
| `/improvements/p/:number` | Issue page |
| `/improvements/t/:number` | Task page |
| `/improvements/contribute` | How to contribute: renders the repo's `CONTRIBUTING.md` summary (§10.3) |

- **Breadcrumb (as built, `BoardBreadcrumb` in `board/pages/board_chrome.dart`)** instead of a
  back button, on every board page (lists, issue, task, contribute, review): the current app's
  icon (the app logo, 24 px; *Close Contribute & build*: back to the last route outside the
  board, `boardBackTarget`, else home), *Contribute & build* (the root: the Improvements list),
  the list the page belongs to (*Improvements*, *Bugs*, *Up for grabs*, *Claimed*, *Done*,
  *Review*, or *Results for “sort”* for a search of all issues), then
  the task (`T-1 Sorting by name…`) and the issue (`#5 The small Markdown editor…`). Chevron
  separators (Lucide `chevron-right`, 14 px, `mutedForeground`). Crumbs are `small` medium
  weight: links in `mutedForeground`, the foreground and an underline on hover, the focus ring,
  Enter / Space; link crumbs ellipsize at 220 px. The last crumb is the current page in the
  foreground, not a link. Semantics: a navigation landmark named *Breadcrumb*, crumbs are links,
  the current one is `selected` (`aria-current` on the web). When the whole trail does not fit
  (the current crumb keeps at least 120 px), the crumbs between the app icon and the current page
  collapse into a *…* button (*Show the full path*) with a menu of them (`board.crumb.more`,
  `board.crumb.menu.<id>`).
- **Trail rules (`BoardTrail`, `board/pages/board_trail.dart`).** The trail is the board's
  hierarchy, never the browser history: root › list › task › issue at most.
  - A list opens an issue or task under it: root › list › item. A list that cannot hold the item
    (an issue from *Up for grabs* or *Claimed*, a task from *Improvements*, *Bugs*, *Done* or the
    search results) gives the item's own list.
  - *Claimed* is treated like *Up for grabs* (a task list). A task's own list follows its status
    (`BoardTab.ofTask`): *Claimed* while claimed or in review, *Up for grabs* when published (an
    expired claim is published), *Done* when done or shipped (T-10: *Done* lists no tasks, but a
    finished task's crumb still names it, the archive it belongs to).
  - A search belongs to the results view (`BoardTrail.search`; the tabs are never searched): a
    issue opened from search results keeps
    the search in its URL (`/improvements/p/5?list=search&q=sort`), so the list crumb returns to
    the results; a task opened from them goes under its own list.
  - A task opens one of its linked issues under itself: root › *Up for grabs* (or the list the task
    came from) › T-n › #m.
  - An issue opens a task: the trail truncates to the task (root › list › T-n), never issue › task ›
    issue › task; the list stays when it shows tasks (*Up for grabs*, *Claimed*, *Review*),
    else the task's own list.
  - An issue opens another issue (similar issues, merged duplicates, *Duplicate of*, the automatic
    redirect of a merged duplicate): the new issue replaces the current one (siblings, same
    parent).
  - Going to anything already in the trail (a crumb) truncates the trail to it.
  - The trail is in the URL query, so reloads and shared links keep it:
    `/improvements/p/5?list=tasks&task=1`, `/improvements/t/1?list=review`. Without a query (links
    in emails, notifications, *Copy link*) an issue is under its kind's list (*Bugs* or
    *Improvements*; under a `task=`, the task's list, *Up for grabs* while it is unknown), a task
    under its own list (above); the list crumb appears once the item is loaded. Unknown or
    contradictory query values fall back to these defaults.
  - Navigation is `router.go` to the computed location (`boardGo`). Moves at the same depth
    (switching tabs, issue → sibling issue, task → task) replace the current history entry, in the
    shell's history and the browser's (`ShellServices.goReplacing`, `Router.neglect`), so the
    history never fills with loops; the shell's Back (`Mod+[`, the browser's back) still walks
    the real history. Starting, changing or clearing a search is not a sibling move: it pushes,
    so Back returns to the list as it was.
- **Page frame (as built):** every board page uses the settings page frame, `ShellPageFrame`
  (`shell/page_frame.dart`): the 56 px bar with, in its `navigation` slot, the breadcrumb and the
  board's actions (`BoardBar`), then the account menu; signed out, `ShellPageFrame.signedOutAction`
  shows *Sign in* (`board.signIn`) in its place. There is no left menu (the board is not a home
  destination). The content is the settings column: `shellPageMaxWidth` (760 px) centered, 24 px
  gutters (16 px below `shellPageNarrowWidth`, 760 px), 24 px from the top. The issue, task and
  contribute pages scroll in `ShellPageBody` (shared with Settings); the board page aligns its
  tabs bar, filter bar and list to the same column with `shellPageInset`, so the list's
  scrollbar stays at the window edge.
- **Top bar actions (`BoardTopActions`):** *Report a bug* (Lucide `bug`), *Suggest an
  improvement* (`leaf`, the improvement icon everywhere; both `shell.board.report` with their kind) and *How to contribute*
  (`wrench`, like the home menu's *Contribute & build*; not on the contribute page itself), all `ShadButton.outline` size `sm`
  with their icons, after the breadcrumb (keys `board.reportBug`, `board.suggest`,
  `board.howToContribute`). The breadcrumb has priority: the buttons keep their labels only while
  the whole trail fits beside them, else they are outline icon buttons with tooltips; below a
  520 px window they are one *More actions* menu (`board.actions.more`), so the bar never
  overflows at 360 px.
- Shared links use the current app's base (`/sheets/improvements/p/412`). The server's
  `/improvements/*` path redirects to `/drive/improvements/*` for links in emails and PRs.
- **Markdown version (T-10).** `/improvements/p/412.md` on the server (not under an app base) is
  the issue as Markdown, `text/markdown` with `Cache-Control: no-cache`
  (`ImprovementsRedirectRoute`, `BoardMarkdown`): `# #412 Title`, a list of facts (kind, status,
  *Duplicate of* / *Declined*, area and size with *(AI)* while unconfirmed, votes, reporter and
  day, the task, merged duplicates, the page link and the screenshot link), the body, *Included
  details* (pretty JSON) and *Comments (n)* oldest first (`### Name on 2026-10-19`, *(admin)*
  for admins). Only public content, as a signed-out visitor sees it: a missing, deleted,
  checking, held or removed issue answers 404, and only visible comments people wrote are listed.
  Task prompts link the issues there (§10.1), so a coding agent reads them without the web app.

### 4.4 Board page

- **Header**:
  - the breadcrumb and the *Report a bug* / *Suggest an improvement* / *How to contribute*
    buttons are in the page frame's bar (§4.3);
  - for signed-out visitors, *Sign in to vote and report issues*.
- **Tabs bar** (`BoardTabsBar`), styled like the editors' toolbar strip (`muted` at 60 %, 20 px
  radius, the toolbar height of 40 px): the tabs on the left as toolbar toggles (`ShadToggle`,
  28 px, the active one highlighted, `tab` / `tabBar` semantics) and the search button at the end
  (below). Each tab shows its count as a GitHub-like badge after the label (a rounded pill on
  `border`, stronger on the active tab; the figures 11 px semibold in the foreground color — one
  step smaller than the label, at least 4.5:1 contrast in light and dark; screen readers hear
  *Bugs, 3*). The counts come from one
  call, `board.counts()` → `BoardCounts` (the held count from `reviewCounts`), reloaded when a
  board command changes lists and on every `watchTasks` event:
  - *Improvements* (count of open and planned ideas);
  - *Bugs* (count of open and planned bugs);
  - *Up for grabs* (published tasks without a valid claim);
  - *Claimed* (claimed and in-review tasks; in review = a PR is linked);
  - *Done* (no count: it is the archive of finished bugs and improvements, done and shipped;
    T-10: finished tasks are not listed there, their issues are);
  - *Review* (admins only, with the held count as the badge).
  The tabs scroll horizontally when they do not fit. *Up for grabs* and *Claimed* follow
  `watchTasks` live: a claim, release, expiry or linked PR moves a task between them. Each has its
  own empty state (*No tasks up for grabs*; *No claimed tasks*). Admins can select tasks on
  *Up for grabs* and merge them (§9.3).
- **Search** (as built, `board/pages/board_search.dart`): a toolbar icon button (Lucide `search`,
  28 px, tooltip *Search*, key `board.search`) at the end of the tabs strip, highlighted like the
  selected tab while a search is active (a toggle in semantics, named *Search: “sort”*). `/` on a
  board list page opens it (not while a text field has the focus). It opens a `ShadPopover`
  anchored to the button (360 px; on windows below 600 px it spans the page's 16 px gutters) with:
  - the search field (focused; Enter searches; *Search issues*);
  - *Kind*: *All*, *Bugs*, *Improvements*;
  - *Include closed* (done, shipped, declined, duplicates; default off);
  - *Clear* and *Search*. Esc closes the popover; searching with an empty field clears.

  A search always covers all issues, from whichever tab it starts (there is no *Search in*: the
  tab-scoped search was dropped), and opens the **results view** `/improvements/search?q=…`
  (`BoardTab.search`, not a tab): the tabs show no selection, a header names it (*Results for
  “sort”*, also the list crumb), and the rows are issues of both kinds (or the chosen kind) with
  the usual filters and sort; the admin selection mode is off there. Without a `q` the results
  view shows *Search the board* with a button that opens the popover. The active search is the
  first chip of the filter row, *Search: “sort”* with ✕ (`board.filter.search`): pressing it
  clears the search (back to *Improvements*). The search lives in the results view's URL (`q`,
  `closed=1`, `kind=bug|idea`; `BoardSearchQuery`), so it can be shared and survives a reload; a
  `q` on a tab's URL (the old tab search) is ignored and the tab shows unfiltered.
  Empty results: *No issues match your search* with *Try fewer words or part of a word, or include
  closed issues.* Matching and ranking are in §6.4.
- **Filters** (chips): area (multi-select), size, status (default `open` + `planned`) and *Mine*
  (issues I wrote or voted on).
- **Sort**:
  - *Top*: score;
  - *Trending* (default): votes in the last 14 days, ties broken by score;
  - *New*;
  - *Most discussed*.
- **Row**:
  - the vote control, the same for both kinds: ▲ score ▼. Bugs can only be upvoted: their ▼ is
    greyed out and disabled, with the tooltip *Bugs can only be upvoted* (semantics: *Downvote,
    unavailable: bugs can only be upvoted*). The `+1` pill *I hit this too* is gone (it read as
    "+1" next to the count);
  - title;
  - area and size chips, labelled with *AI* until an admin confirms them;
  - a status badge (`planned` links to the task);
  - comment count;
  - author display name and age;
  - a 📷 icon when the issue has a screenshot.
- Paging: 30 rows, *Load more*. Empty states per tab.
- Width < 600: rows stack, and the vote control moves to the row's start.
- **As built (consistency pass):** the filters, below the tabs bar, are the drive's filter bar: outline `sm` buttons with a chevron that open a `WonkyDropdownMenu`, the
  label naming the current value (*Area: Sheets, Write*, *Sort: Trending*), in one horizontally
  scrolling 48 px row (`board.filterBar`). The admin selection bar is the drive's: a
  `secondary` pill that replaces the filter bar in place (*Clear*, *N selected*, *Create task
  from N*, *Add to task…*), so rows never move. Rows (issues, tasks, review items, a task's
  linked issues) are `BoardListTile`s, styled like the drive rows and the notification rows: a
  rounded tile, `accent` on hover, `sidebarAccent` when selected, the focus ring, no dividers;
  titles in `small` medium weight. Loading shows the drive list's `LoadingShimmer`; errors and
  empty tabs are `WonkyEmptyState`s (the offline illustration when offline).

### 4.5 Issue page

The breadcrumb (§4.3) ends in `#412 Title` under its list, or under its task when opened from
one (root › list › T-12 › #412). *Part of task T-12* and the status badge's task link truncate
the trail to the task; *Similar issues*, merged duplicates and *Duplicate of* replace the issue.

- **Header**: the vote control (large, ▲ score ▼ for both kinds, as in the rows: on bugs ▼ is
  disabled) at the start; next to it:
  - one line, top-aligned: `#412` (muted, at the title's size), the title (wrapping) and the ⋮
    actions menu at the end (`board.post.header`);
  - below it the kind, area and size chips and the status badge;
  - author (avatar, display name, an *Admin* badge for admins) and time, plus *edited* with the
    time.
  There is no separate *I hit this too* button: a bug is voted with the ▲ of the vote control.
- **Body**: the Markdown body (§7.3 renderer).
  - Screenshot: a thumbnail (max 480 px wide); click opens the **image lightbox**. Write's
    `ImageLightbox` moves to `wonky_app` (`showImageLightbox`).
  - *Details* (collapsed): the included details table.
- **Relations**:
  - *Part of task T-12* (link);
  - *Duplicates merged into this issue: #388, #401*;
  - *Similar issues* (top 3, from §6.4).
- **Comments** (§7.3): a flat list, oldest first, with a composer at the bottom. Signed-out
  visitors see *Sign in to comment*.
- **Admin toolbar (T-10)**, admins only, under the header (`board.post.adminBar`): one row of
  `sm` buttons with icons (keys `board.post.bar.<id>`) and the ⋮ actions menu at its end (for
  admins ⋮ leaves the title row; everyone else keeps it there). The buttons are the common
  actions, most important first — *Approve* (primary, while held or being checked), *Select
  for building* (primary otherwise; while the issue is visible, `open` or `planned` and not in
  a task), *Add to task…*, *Labels…* (`shell.board.admin.setLabels`), *Merge into…* (*Unmerge*
  for a duplicate), *Decline…* (*Reopen* when declined). When the row is too narrow, buttons
  move into ⋮ (above its own entries, `board.post.menu.<id>`), the least important first, as in
  the editors' toolbars (`ToolbarOverflowLayout` of `wonky_ui`; ⋮ is pinned and never moves).
- **Comments for the prompt (T-10):** while *Select for building* is offered, every visible
  comment people wrote has a checkbox before its author (`board.comment.<uuid>.select`, all
  checked; screen readers: *Include the comment by Ada in the task prompt*), with the hint
  *Checked comments go into the task prompt when you select this issue for building.* under the
  *Comments* heading. The admin reads the comments in full on the page and unchecks the ones the
  prompt should not see; *Select for building* sends them as `excludedComments` (§9.3), and the
  task dialog then asks only for the title and labels. The checkboxes come from the shared
  thread widget (`CommentThreadActions.selected` / `select` / `selectLabel`, off for document
  comments).
- **Actions menu (⋮)**:
  - author: *Edit* (while `open` and not in a task), *Delete*;
  - everyone signed in: *Copy link*, *Flag* (§7.5);
  - admins: the less common moderation actions (§9.2): *Apply suggested title*, *Edit* / *Edit
    and approve*, *Hold*, *Looks fine*, *Remove…* / *Restore*, *Block user…*.

### 4.6 Task page

The breadcrumb (§4.3) ends in `T-12 Title` under the list it came from (*Up for grabs*,
*Claimed*, *Review*), else under its own list (*Claimed* while claimed or in review,
*Done* once done or shipped, else *Up for grabs*). Linked issues open under the
task.

- **Header**:
  - `T-12`, title, area and size;
  - status, and the claim state (*Claimed by Ada · 31 h left*, or *Up for grabs*);
  - the buttons *Claim this task* / *Unclaim this task* (Lucide `ban`, also the icon of
    `shell.board.release`; §8); admins also get *Link pull request…*;
  - (T-10) while the caller may not claim (§8.4; `BoardMe.claimBlockedUntil`), *Claim this
    task* is disabled and a warning notice under the buttons gives the server's reason
    (`board.task.notice.claimBlocked`: *You can't claim tasks until November 2, 2026: 3 of your
    claims expired without a pull request or an unclaim.*);
  - for the claimant: the **claim code** (`7Q4F-K2M9`) with *Copy*, and the time left.
- **Linked issues**: one row per issue with its score and its screenshots.
- **How to build it** (always shown, not collapsible; the claimant and admins see every step, others see an outline while the task is up for grabs — "1. Read the contribution guide and set up your development environment", "2. Claim the task to get a prompt" (`board.task.promptLocked`) and "3. Paste the prompt into your AI agent using a frontier model" — and nothing once someone else claimed it):
  1. *Read the contribution guide and set up your development environment*, where *contribution
     guide* (`board.task.setup`) is a link that opens *How to contribute*
     (`/improvements/contribute`, §10.3) in the same tab, under the board's breadcrumb (Back
     returns to the task). The setup commands are only there.
  2. **The prompt** — for the claimant and admins only: the prompt in a monospaced card with
     *Copy prompt*. Everyone else sees *Claim this task to get the prompt.*
     (`board.task.promptLocked`) with *Claim this task* while the task is up for grabs (*Sign in
     to claim* when signed out). The server sends the prompt to the claimant and admins only
     (§8.1), so it is not merely hidden. The claimant's prompt has their claim code in its PR
     lines (§10.1). P1: *Copy setup + prompt* puts the setup steps and the prompt in one
     clipboard text for an agent that starts from an empty folder.
  3. Open a PR: the PR rules (§13.1), with the two lines to put in the description, already
     filled in for the claimant (`Wonky-Task: T-12`, `Wonky-Claim: 7Q4F-K2M9`) and a *Copy*
     button.
- **Pull request** (once linked): the PR link, its state, and the latest task review (§13.5) with
  the per-criterion verdicts.
- **No discussion.** Tasks have no comments or composer: questions go on the issues the task
  comes from. The server refuses comments on tasks (§7.3).
- **Activity** (admins only, under the heading *Activity*): claimed, released, expired, PR
  linked, done, shipped, back to draft for a rewrite, merged into / merged from, unmerged (§9.3)
  — one muted line per row with its age (`board.task.event.<uuid>`), *No
  activity yet* when there is none. These are the system rows of the task (`board_comment` with
  a `taskId`); `listTaskComments` returns them to admins only (empty for everyone else).
- **Merged**: a task merged into another (§9.3) shows *This task was merged into T-3.* with
  *Open T-3* instead of the cancelled notice.
- **Admins**: *Edit prompt* (§10.2), *Regenerate prompt*, *Add/remove issues* (both rewrite the
  prompt, §9.3), *Release claim*,
  *Mark done*, *Mark shipped*, *Cancel task*. (T-11) There is no *Publish* button: a draft shows
  the draft notice ("It is published once the AI has written its prompt, or when you save the
  prompt") and, when held or failed, the `promptNote`; saving the prompt of a draft publishes
  it.

### 4.7 Visual and accessibility notes

- Uses the existing tokens and widgets: label chips are `ShadBadge.secondary` (like the comment
  cards' author badges, also the *Admin* badge), status badges `ShadBadge.outline` with a dot in
  the design system's status color (`info`, `warning`, `success`, `destructive`). Status colors
  are always paired with a text label.
- Notices on issues and tasks (checking, held, removed, declined, merged, draft, prompt pending),
  the moderation panel and the claim code are `ShadAlert`s like the app's other callouts (the
  icon in the status color; `ShadAlert.destructive` for removals). Code (setup commands, PR
  lines, the prompt, the claim code) uses `WonkyTheme.monoFamily` at 12 px on `muted` with a
  6 px radius, the copy icon at the top end as in Markdown code blocks; copying confirms with
  the shell toast. *Details* and *How to build it* are keyboard-operable disclosures
  (`BoardDisclosure`). Section headings are `h4`, page titles (issue, task) `h3`.
- Vote control:
  - two buttons with labels ("Upvote, 14 votes", "Remove upvote") and `aria-pressed`; on bugs the
    down button is disabled ("Downvote, unavailable: bugs can only be upvoted", tooltip *Bugs can
    only be upvoted*);
  - keyboard: `+`/`-` on a focused row (`shell.board.vote` with up/down; `-` on a bug removes
    its upvote).
- The screenshot editor needs a pointer for drawing. Keyboard users can still issue without a
  screenshot. The editor's tool buttons, undo and *Done* are keyboard operable.
- Light and dark are verified with goldens for the dialog, the board row, the issue page and the
  editor (§15).

## 5. Screenshots

### 5.1 Capture

- `McpBridgeScope` already wraps the whole app in a `RepaintBoundary`, the one used by the
  `ui.screenshot` MCP tool. Its key moves to `ShellServices.screenshotBoundary`, and a shared
  `captureAppScreenshot(s, {maxPixels})` helper replaces the private code in
  `SharedUiTools.screenshot`. The MCP tool and the board both use the helper.
- `shell.board.report` captures **before** showing the dialog. That is one
  `RenderRepaintBoundary.toImage` at device pixel ratio, capped at 4 MP and downscaled so the
  longer side is at most 2,560 px. The `ui.Image` is held in memory and disposed when the dialog
  closes. Nothing is encoded or uploaded unless the user adds the screenshot.
- Covered: everything Flutter paints, including open menus, toasts and the shell's dialogs.
  Not covered: browser chrome, and other tabs or windows.
- Failure (for example a renderer error): the dialog opens without a screenshot option and shows
  *Couldn't capture the screen*.

### 5.2 Screenshot editor

`showScreenshotEditor(context, image) → Future<AnnotatedScreenshot?>`, a full-screen dialog
(`dialogKey: 'dialog.board.screenshot'`).

```
┌ Edit screenshot ─────────────────────────────────────────── [Cancel] [Done] ┐
│ ⚠ This screenshot will be public. Cover anything private: names, emails,    │
│   document and spreadsheet content you don't want to share.                 │
│ [■ Cover] [□ Highlight] [↗ Arrow] [✎ Pen]  ● ● ●   [↶] [↷] [Clear]  [Crop]  │
│ ┌──────────────────────────────────────────────────────────────────────┐   │
│ │                       (screenshot, fit to view)                       │   │
│ └──────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────────┘
```

| Tool | Key | Effect |
|------|-----|--------|
| **Cover** (default tool) | `C` | Opaque rectangle, solid fill (black, or the theme's `foreground`). It is never a blur: blurred text can be recovered |
| Highlight | `H` | Rectangle outline, 3 px, accent color (red by default) |
| Arrow | `A` | Straight arrow, accent color |
| Pen | `P` | Freehand stroke, smoothed with `OneEuroFilter` |
| Colors | `1`–`3` | Red, yellow, blue (accent tools only) |
| Undo / redo | `Mod+Z` / `Mod+Shift+Z` | The editor's **local** undo stack. It is a modal editor with its own history, like the Slides presenter's ink ([08 §2](08-commands-and-undo.md)); the shell stack is untouched |
| Select / move / delete | click, drag, `Delete` | Shapes stay editable until *Done* |
| Crop (P1) | `R` | Crop rectangle |

- **Chrome (as built):** the top bar of the full-screen views (the version history's): 56 px with
  a bottom border, the title in `large`, *Cancel* and *Done*. The warning is a `ShadAlert` (not
  dismissible). The tools are a `WonkyToolbar` in the editors' rounded toolbar strip: icon
  toggles with tooltips and shortcuts (`ToolbarToggleButton`), the colors, undo/redo and
  delete/clear in groups split by separators; tools and undo never overflow into "⋯". The area
  around the image is the `canvas` token.
- **Shared ink code**: `InkStroke`, `OneEuroFilter` and the stroke painter move from
  `wonky_slides/lib/features/present/present_ink.dart` into `wonky_ui` (`ink/`: `InkStroke` with
  `InkTool.pen` / `highlighter`, `OneEuroFilter`, `InkStrokePainter` and its static
  `paintStrokes` for flattening). Slides then imports them from there, with no behavior change
  (`PresentTool`, `InkColors` and `InkModel` stay in Slides).
- **Done** flattens the image and the annotations into a new image at the source resolution and
  encodes it as PNG. If the PNG is over 2 MB it becomes JPEG at quality 85, and if that is still
  over 5 MB it is downscaled (`encodeScreenshot` in `wonky_app`). `wonky_app` has no JPEG
  encoder of its own (no `package:image`): `encodeScreenshot` takes an optional `jpegEncoder`;
  without one a PNG over 2 MB is kept up to 5 MB and downscaled beyond. **Only the flattened
  image leaves the device.** The original and the annotation layers are never uploaded, so
  covered pixels are gone for good.
- The annotation layers stay in memory while the dialog is open, so *Edit* can change them before
  posting. After posting, the screenshot can only be removed (by the author or an admin), not
  edited.

### 5.3 Storage

- New `StoredFileKind.boardScreenshot`:
  - private storage, served through 15-minute signed URLs (`board.getScreenshotUrl(postNumber)`,
    callable signed out for visible issues);
  - not counted toward the 50 MB quota (added to the exempt list in
    [Drive 03](wonky_drive/03-storage-quota.md));
  - PNG or JPEG only, max 5 MB, sniffed with `FileService.sniffImage`; stored as a WebP that fits
    2048 × 2048 (`screenshot.webp`, 12 §1.1 *Image optimization*; older screenshots stay PNG/JPEG).
- Upload:
  1. `board.createScreenshotUpload(fileUuid, mimeType, size)` (signed in) returns a
     `FileUploadTicket`; the file has no item and its owner is the user;
  2. upload with `FileUploader`;
  3. `completeUpload`;
  4. `board.createPost(… screenshotFileUuid)` attaches the file.

  Unattached screenshot files are deleted by the hourly `cleanupFiles` after 1 day.
- Removing a screenshot (author or admin) deletes the bytes at once. A removed issue's screenshot
  is deleted with the issue's purge (§11).

## 6. AI triage ("vetting")

The board's AI is **separate from the in-app AI** ([10](10-ai-assistant.md)). It has its own keys,
its own usage accounting and budgets, and its own client code, so in-app usage (which can be much
higher) never starves moderation and the board never spends users' AI budgets. Two models, each
used for what it does best:

| Model | Provider | Used for | Why |
|-------|----------|----------|-----|
| **Jev** (`jev-1.13.0`, pinned) | [TypeSafe](https://typesafe.ai/), `POST https://api.typesafe.ai/v1/systemone` | Every **decision**: moderation, kind, area, size, duplicate checks, comment checks, reranking similar issues | A "System One" model: it returns typed answers (Choice, Score, Noul) with calibrated probabilities in about 0.1 s, at $0.042 per million input tokens. It cannot generate text |
| **Gemini** (`gemini-3.1-pro-preview` and `gemini-3.8-flash` by default; the 2.5 models return 404 for new keys) | Google, through `dartantic_ai` | Everything that **writes**: suggested titles and summaries, bundle suggestions, task prompts, PR reviews (§13.5) | Generation and long context (whole diffs) |

### 6.1 Board AI components (`platform/board/ai/`)

- **Keys** are Serverpod passwords, separate from the in-app ones: `internalJevApiKey` and
  `internalGeminiApiKey`. They are never used by the in-app AI, and the in-app keys
  (`anthropicApiKey`, …, users' own keys) are never used by the board.
- **`JevClient`** is a small HTTP client (`package:http`; TypeSafe has no Dart SDK). It sends
  `Authorization: Bearer <key>`, a pinned model id (`board.ai.jevModel`), and request bodies of
  `state` plus named `questions`. Behavior:
  - It retries `429` and `529` with exponential backoff and honors `retry-after`.
  - It maps `401`, `400` (incl. `max_tokens_exceeded`) and `422` to a `BoardAiException`.
  - The model id is pinned, not `jev-latest`, because the thresholds below are tuned per model
    version. Upgrading means re-running the triage evaluation set (§15) and changing the config.
- **`BoardGemini`** is a `DartanticAiClient` constructed directly with `internalGeminiApiKey`
  (not through `AiKeys`). It uses the same one-shot tool pattern as the Slides AI features (`AiCall.send`): a
  tool the model must call once, read with the `_jsonIn` fallback.
- **`BoardAiUsage`** (table `board_ai_usage`, one row per day, provider, model and feature)
  counts requests and input and output tokens. Global daily budgets
  (`board.ai.jevDailyTokenBudget`, `board.ai.geminiDailyTokenBudget`) are checked before each
  call:
  - when Jev's budget is spent, triage takes the *unchecked* path (§6.3);
  - when Gemini's budget is spent, writing features tell admins *Today's AI budget is used up*,
    and PR reviews wait until the next day.

  Nothing is recorded in the in-app `ai_usage` table.
- **Fakes**: `FakeJevClient` (scripted answers per question id, records requests) and the
  existing `FakeAiModelClient` for Gemini. Both are installed via `BoardAi.override` in tests.
- **No keys**: without `internalJevApiKey` the board runs unchecked (§6.3). Without
  `internalGeminiApiKey`:
  - issues get no suggested title or summary;
  - task prompts start from a fixed template that admins fill in;
  - bundle suggestions and PR reviews are off.
- **Privacy**: both providers process issue text, which is public anyway.
  - TypeSafe does not train on requests.
  - The Gemini key must be a **paid-tier** key: Google may use free-tier API data to improve its
    products.
  - The dialog names both providers. The per-user AI opt-out ([13 §2](13-security-and-operations.md))
    does not apply to public board content. A §13 §2 line is added for this.

### 6.2 What Jev decides

One Jev request per issue, built in `BoardTriageQuestions`. All questions go in one request: Jev
evaluates them in parallel against the same state. Measured on the evaluation set (the `live-ai` run
prints p50 and p95): p50 265 ms, p95 443 ms, about 1.8k input tokens per issue.

**State** (JSON, only what the questions need; Jev loses accuracy with irrelevant detail):

```json
{
  "post": {"kind_chosen_by_author": "bug", "title": "…", "body": "…"},
  "app_in_use": "sheets",
  "product": "Wonky Work: Drive (files), Write (documents), Sheets (spreadsheets), Slides (presentations)"
}
```

The included details are left out, except the app.

| Question id | Type | Instructions and criteria (abridged) | Used for |
|-------------|------|--------------------------------------|----------|
| `kind` | Choice | "Is `post` a report of something that does not work, or a request for new or changed behavior?" `bug`: existing behavior is broken or wrong. `idea`: a new feature or a change to working behavior | Kind correction |
| `area` | Choice | "Which part of Wonky Work is `post` about?" One option per `BoardArea`, each with a description (e.g. `suite`: sign-in, settings, menus shared by all apps, switching apps) | Area label |
| `size` | Choice | "How much work would `post` take for one developer with an AI coding agent?" `small`/`medium`/`large` with the definitions from §2 | Size label |
| `offensive` | Noul | "Does `post` insult, harass or demean a person or group, use slurs, or contain sexual content?" `false` explicitly includes rudeness or frustration about the product | Moderation |
| `spam` | Noul | "Is `post` advertising, link spam, or text unrelated to any software?" | Moderation |
| `not_actionable` | Noul | "Is `post` empty of any report or request (a test like 'asdf', a greeting, a question with nothing to fix)?" | Moderation |
| `off_topic` | Noul | "Is `post` about a product other than Wonky Work?" | Moderation |
| `personal_data` | Noul | "Does `post` contain an email address, phone number, street address, or the name of a person other than its author?" | Moderation |
| `security` | Noul | "Does `post` describe a way to see other users' data, take over an account, run code on the server, or get around permissions?" | Moderation |
| `duplicate_<n>` | Noul (one per candidate, up to 5 from §6.4) | instructions object with `candidate` (title and body excerpt) and the question "Do `post` and `candidate` describe the same problem or the same request?" | Duplicate hint |

**Thresholds** (`board.ai.thresholds`, tuned on the evaluation set, §15). They follow Jev's
confidence-gated routing: three bands per decision. Config keys: `securityHold` 0.5 /
`securityReview` 0.2, `harmHold` 0.7 / `harmReview` 0.5 (`offensive`, `personal_data`),
`junkHold` 0.8 / `junkReview` 0.5 (`spam`, `not_actionable`, `off_topic`), `kindCorrection` 0.8,
`labelConfidence` 0.5, `duplicate` 0.8 and `rerank` 0.3 (`BoardAiThresholds`).

| Decision | Hold (held, admin first) | Review (visible, in the admin *Check* list) | Otherwise |
|----------|-------------------------|---------------------------------------------|-----------|
| `security` | ≥ 0.5 | ≥ 0.2 | visible |
| `offensive`, `personal_data` | ≥ 0.7 | ≥ 0.5 | visible |
| `spam`, `not_actionable`, `off_topic` | ≥ 0.8 | ≥ 0.5 | visible |
| `kind` correction | — | — | applied when the other option wins with confidence ≥ 0.8 |
| `area`, `size` | — | — | set when confidence ≥ 0.5, else left empty (*Needs labels* for admins) |
| `duplicate_<n>` | — | ≥ 0.8: *Possible duplicate of #388* hint for admins (never auto-merged) | — |

**Known Jev limits, and how the design handles them** (from TypeSafe's published jaggedness
notes for 1.13):

- *Literal reading*: every question states its exact condition and boundary cases.
- *Adversarial content*: issues that argue for their own classification. The bands send unsure
  cases to admins; the conservative `security` threshold; community flags.
- *Choice option order bias*: the evaluation set also runs with reversed option order.
- *No generation*: titles and summaries come from Gemini.

**Images** are experimental in Jev ("Dreamer-ready", behind the `TypeSafe-Danger-Zone-Images`
header). P2: once they are production-ready, add `screenshot_personal_data` (Noul over the
flattened screenshot) to catch readable emails, names or document text the author forgot to cover.

### 6.3 Pipeline

1. `createPost` calls Jev **inline** with a 3 s timeout, because the typical answer takes about
   0.1 s. The issue is stored directly as `visible` or `held`, and the author sees the result
   immediately.
   - If the inline call times out or fails, the issue is stored as `checking`, and
     `BoardFutureCall.triage(postId)` (`callWithDelay(Duration.zero)`) takes over.
2. Outcomes:

   | Result | Effect |
   |--------|--------|
   | All moderation scores below *Hold* | `moderation: visible`, `status: open`. Labels set as above, with `aiLabels: true`. Scores in the *Review* band put the issue in the admin *Check* list |
   | Any score in *Hold* | `moderation: held`; the scores are stored for the review queue (`triageJson`, admins only). The author sees *Waiting for review* |
   | No Jev key, or the daily Jev budget spent | `visible`, `triageState: unchecked`. Admins see an *Unchecked* list, and the sweep re-triages unchecked issues when Jev is available again |
   | Error or timeout in the background path | Retried at 1, 5 and 30 min. After the third failure: `visible` + `unchecked` (`board.publishWhenTriageFails: true`, the default); set it to false to hold such issues instead |

3. **Kind correction**: the author's choice is kept in `reportedKind`, and the issue shows *Moved
   to Improvements*.
4. **Writing pass (Gemini fast model, asynchronous, only for visible issues)**:
   `suggest_title_and_summary` writes `suggestedTitle` (only when it differs meaningfully; admins
   apply it, it is never applied automatically) and `summary` (≤ 200 chars, used in prompts,
   bundles and reviews). Without Gemini, `summary` is the first 200 chars of the body.
5. **Edits** by the author re-run Jev inline. A visible issue stays visible unless a score reaches
   *Hold*.
   - **Stale results**: a triage result is stored under a row lock and only into the AI-owned
     columns (moderation, reason, `needsCheck`, labels unless confirmed, duplicate hint,
     `triageState`, `triageJson`), and only when the issue is not deleted, its moderation is
     unchanged (an admin's decision during the AI call wins) and, unless it is still
     `checking`, its title and body are unchanged (an edit runs its own triage). The background
     path's fallbacks (no Jev, final failure) only apply while the issue is still `checking`.
6. **Comments**: one Jev request with only the moderation Nouls (`offensive`, `spam`,
   `personal_data`, `security`), inline at issue time with the same bands. A comment that reaches
   *Hold* is stored `held`, and the author sees it with *Hidden pending review*.
   - With a Jev key but today's budget spent, or when the check fails or times out, the comment
     is stored `visible` with `needsCheck: true` and the reason *Not checked yet.*: it is listed
     under *Check*, and the sweep (`wonky.boardSweep`) checks up to 50 such comments per run
     once Jev is available again (held ones are hidden; a comment edited, moderated or deleted
     meanwhile keeps its state). Without a Jev key comments are simply visible.
   - Comment edits are checked again and stored conditionally (not moderated or deleted while
     the check ran, else `conflict`); a new verdict replaces an earlier *Not checked yet.*

### 6.4 Similar issues and duplicates

- The search document `setweight(to_tsvector('english', title), 'A') ||
  setweight(to_tsvector('english', body), 'B')` is an expression with a GIN index
  (`board_post_search_fts_idx`) and the title has a `pg_trgm` index for the substring match (when
  the extension exists). Serverpod models cannot declare expression indexes and `definition.sql`
  must stay the generated one, so `SearchIndexes` creates them at server start (CQ-25, 13 §3);
  `similar()` and `list(query)` repeat the expression exactly (`BoardSearch.document`).
- **Board search** (`list(query)`, as built in `BoardSearch`): an issue matches when any of these
  holds (OR):
  - **full-text, word prefixes**: the query's words (runs of letters and digits, lowercased,
    one-letter words dropped, at most 16) AND-joined, each word of 3+ characters as a prefix
    (`sort:* & col:*`), through `to_tsquery('english', @sq)`: *sort* finds *sorting* and *sorted*
    (the prefix is stemmed like the document). Every other character, including the tsquery
    operators `& | ! : * ( ) <->` and quotes, only separates words, so the tsquery is always
    valid;
  - **title substring**: `p.title ILIKE @slike` with `%text%` (whitespace collapsed; `\`, `%`
    and `_` escaped): *ort* finds *Sorting*;
  - **issue number**: `12` or `#12` matches issue #12.

  All user text is a query parameter, never spliced into SQL. **Ranking**: the number match, then
  `ts_rank_cd` (title words before body words), then title substring hits, then the list's sort
  (*Trending*, *Top*, *New*, *Most discussed*). The other filters (kind, statuses, area, size,
  *Mine*, visibility) still apply.
- `similar(text, kind)` uses the same words OR-joined as prefixes (`paste:* | cells:*` through
  `to_tsquery`), `ts_rank_cd`, and only `visible` issues in `open`/`planned` (T-10: built issues
  are not suggested in the report dialog; the triage's duplicate candidates still include
  `done`). It returns up to 5.
- **Jev rerank** (when configured): full-text search returns the top 10 candidates, and one Jev
  request with a `same_<n>` Noul per candidate ("Do `draft` and `candidate` describe the same
  problem or request?") reorders them. Only candidates with p ≥ 0.3 are shown, at most 5. This is
  about 0.1 s and a fraction of a cent per call, and it is rate-limited (§11). Without Jev, the
  full-text ranking is used as is.
- `pg_trgm` is optional (only the title substring index needs it). P2: embeddings, if full-text search turns out too weak.

## 7. Issues, votes and comments

### 7.1 Who can do what

| Action | Signed out | Signed in | Author | Admin |
|--------|:---:|:---:|:---:|:---:|
| Read visible issues, comments, tasks, screenshots | ✓ | ✓ | ✓ | ✓ |
| Report an issue, vote, comment, flag | | ✓ | ✓ | ✓ |
| Edit own issue (while `open`, not in a task); delete own issue (soft) | | | ✓ | |
| Edit or delete own comment | | | ✓ | |
| Remove screenshot | | | ✓ | ✓ |
| Moderate, set labels, merge, select, manage tasks, block users | | | | ✓ |
| Claim a published task | | ✓ (max 3 active claims, not blocked, not claim-blocked §8.4) | ✓ | ✓ |

Users blocked from the board (§9.2) can read but not write. Their writing endpoints answer
`forbidden` with *You can't post on Bugs & improvements*.

### 7.2 Votes

- One row per `(postId, userId)` with `value` +1 or −1. Down votes (−1) are allowed on ideas only:
  bugs show the same ▲ score ▼ control with ▼ disabled (§4.4).
- `board.vote(postNumber, value)`, where `value` ∈ {−1, 0, +1} and 0 removes the vote. It is
  idempotent and returns the new score and the caller's vote.
- The author's +1 is added on creation and can be removed like any vote.
- `score` and `voteCount` are denormalized on the issue and updated in the same transaction.
  `trendingScore` is computed in the query (votes with `createdAt` in the last 14 days).
- Votes are allowed while the issue is `open` or `planned` and close with `done`, `declined` and
  `duplicate`.
- Undo: `shell.board.vote` records the previous value; undo sets it back.

### 7.3 Comments and Markdown

**Server.** Board comments are their own table, `board_comment` (§12). Reusing `comment_thread`
does not fit: its `itemId` is a required drive-item FK, and its access checks are drive roles.

- The comments are flat, oldest first, with no resolve, assignment or anchors.
- Comments are on issues only. Tasks have no discussion (§4.6): `addComment` with a `taskNumber`
  answers `invalidArgument` (the parameter stays for older clients), for admins too. A task's
  `board_comment` rows are the system activity rows the server writes itself (claimed,
  released, expired, PR linked, done, shipped …), and `listTaskComments` returns them to admins
  only.
- Reactions use the same JSON shape as document comments (P1).
- Mentions are P2. `@name` is plain text in v1.

**Client widget reuse.** The thread UI is shared with document comments through a small refactor
of `packages/wonky_app/lib/src/comments/`:

- `CommentThreadBody` and the composer get a `CommentThreadActions` interface (reply, edit,
  delete, react, canEdit/canDelete per comment) instead of dispatching `shell.comments.*` and
  reading `services.activeDocument` directly.
- Document comments implement it with the existing commands (no behavior change; the existing
  comments tests stay green). The board implements it with `shell.board.comment.*`.
- The board maps `BoardCommentView` to the same `CommentView`-shaped data the widget renders:
  `ThreadComment` (document comments use `ThreadComment.fromCommentView`), rendered with
  `CommentThreadBody.custom(services, actions, comments)`. Optional features of the interface
  (resolve, reactions, copy link, @mentions) are off unless the implementation enables them; a
  thread without mentions replies and edits in a `MarkdownComposer`.

**Markdown.** Today comments are stored as Markdown but shown as raw text, and issue bodies need a
renderer.

- **Renderer.** `AssistantMarkdown` (`assistant/assistant_markdown.dart`) generalizes into
  `WonkyMarkdown` (`packages/wonky_app/lib/src/markdown/`). It handles headings, lists, quotes,
  fenced code, tables, and inline bold, italic, strike, code and links.
  - `AssistantMarkdown` stays as a thin wrapper.
  - Links open through `confirmExternalLink`. Only `http(s)` and `mailto` are allowed, and other
    schemes render as text.
  - Fenced code is highlighted with `wonky_code`'s `CodeView`, the tokenizer Write and Slides use
    (P1; plain monospace in v1).
- **Profiles.**
  - `MarkdownProfile.post` allows headings (rendered at most at h3 size), lists, code blocks,
    quotes, links and inline styles.
  - `MarkdownProfile.comment` allows inline styles, links, lists and code blocks.
  - Images in Markdown are not rendered (shown as links). Raw HTML is shown as text, except
    HTML comments (invisible); entities (`&amp;`, `&#96;`) are decoded.
- **Composer ↔ renderer (CQ-50).** The composer writes with `MarkdownDocumentCodec`
  (`package:markdown`), the renderer is hand-written; `wonky_app/test/markdown/markdown_round_trip_test.dart`
  writes random composer documents (headings, nested bullet/numbered/task items, quotes, rules,
  styles on whole words, links, Markdown-special characters) and checks that the renderer sees
  the blocks, levels, markers, text, styles and links the composer reads back. It found and fixed:
  escaped delimiters closing emphasis (`*2 \**`), entities the writer emits, `<!-- -->` between
  code spans, `***x***`, escaped brackets in link text, and quote paragraphs separated by `>`.
  Mid-word runs of mixed `*`/`**` can still differ (no CommonMark delimiter algorithm in the
  renderer; a shared grammar is the longer-term fix).
- **Document comments** switch from raw text to `WonkyMarkdown` with the comment profile. This is
  a visible improvement for Write, Sheets and Slides comments and matches what [07 §2](07-collaboration.md)
  already promises.
- **Composer (WYSIWYG).** `MarkdownComposer` is a lightweight WYSIWYG Markdown field:
  `WonkyRichEditor` from the shared package `wonky_rich_editor` (01 §2.1), `super_editor`
  (vendored, as in Write and Slides) configured lightly, in the spirit of Slides' speaker-notes
  editor. *Decided:* the board's text fields show formatting as it will be rendered, so the
  first iteration's `TextField` with a *Write | Preview* toggle is gone.
  - **Markdown in, Markdown out.** The composer keeps its `TextEditingController` API: the
    controller's text is the Markdown. `MarkdownDocumentCodec` reads it into a document and
    writes it back: paragraphs (their lines stay lines, like the renderer's `hardBreaks`),
    headings 1–6 (drawn at most at h3 size, like issues), bullet and numbered items with levels
    (nested items at the parent's content column: 2 spaces under `- `, 3 under `1. `), task
    items (`- [ ]`, `- [x]`, for prompts' acceptance criteria), quotes, rules, and inline bold,
    italic, strikethrough, code and links through `wonky_rich_text`'s inline reader and writer
    (the suite's syntax).
  - **Focus and caret, like a text input.** The caret is painted, and blinks, only while the
    field has focus; the selection outlives the focus (the toolbar acts on it). A press outside
    the field and its toolbar leaves the field, as it does a `ShadInput`; menus and dialogs the
    field opens give it the focus back when they close. (T-2: a field that lost the focus kept
    blinking. super_editor's `ContentLayers` never unmounts layers dropped from the end of
    its overlay list, so an unfocused field keeps an empty layer in the caret's slot.)
  - **No code blocks** (*decided*: editing and removing them broke the field). Inline code
    stays. There is no *Code block* button, no ```` ``` ```` autoformat (typed, a fence is text:
    written escaped, read back as the same paragraph) and no code-block shortcut. Fenced code that
    is set or pasted as Markdown is a *literal* block (below), fences included, so nothing is
    lost and the renderer still shows it as code. The code-block capability is removed from
    `wonky_rich_editor` too (no `BlockFormat.codeBlock`, no fence metadata): no other field
    needed it.
  - **Nothing is lost.** Fenced and indented code, tables, HTML, link reference definitions and
    any block whose inline content the editor can't represent (images, inline HTML, link titles,
    links with other schemes, styles across lines, a quote inside a list item …) become a
    *literal* block, shown as Markdown source in a bordered code box and written back verbatim.
    A literal block is edited and deleted like a paragraph: Backspace at its start makes it a
    paragraph and then joins it to the one before, Delete at the end of the block before (or of
    the literal block) joins the next block, a selection across it deletes or is typed over
    like any other, Enter inserts a line break at the caret (super_editor's code-block newline
    appended it at the block's end; `MarkdownEditingController` handles it), Enter twice at its
    end leaves it, and cut / paste and undo restore it. Every path is covered by
    `wonky_rich_editor/test/widgets/literal_blocks_test.dart` (keys through the hardware
    keyboard and the IME) and none throws.
  - **Untouched text stays as it was.** Until the user edits, the text is exactly what was set;
    afterwards only the edited blocks are rewritten (each block remembers its source and the
    Markdown the codec would write for it). The prompt editor's diff and lint therefore keep
    working on the Markdown and only show real changes.
  - **Profiles.** The `profile` sets the blocks: comments have no headings, quotes or rules
    (those lines stay text, as the comment renderer shows them; no Quote button).
  - **Toolbar** (above the field, wraps at 360 px): Bold, Italic, Strikethrough, Code, Link |
    Bulleted list, Numbered list, Checklist | Quote — `ShadToggle`s like Write's toolbar, checked
    for the selection, tooltips with the shortcut, screen-reader labels.
  - **Typing** follows Write's autoformat (Write 04 §7): `# ` headings, `- ` `* ` `+ ` bullets,
    `1. ` numbers, `[] ` `[x] ` tasks, `> ` quotes, `---` rules; `**b**` `__b__`, `*i*` `_i_`,
    `~~s~~`, `` `c` `` and `[text](url)` convert when the closing delimiter is typed; URLs
    autolink. Not in literal blocks.
  - **Shortcuts:** `Mod+B` / `I` / `E` (code), `Mod+Shift+X` (strikethrough), `Mod+K` (link
    dialog `dialog.markdown.link`: http(s) or mailto only, *Remove link* when editing one),
    `Mod+C` / `Mod+X` (copy and cut as Markdown, below),
    `Mod+Shift+7` / `8` / `9` (numbered, bulleted, checklist), `Mod+Shift+.` (quote), `Tab` /
    `Shift+Tab` (list levels; elsewhere they move the focus like any input), `Mod+Enter` submits,
    `Esc` is left to the dialog or page.
  - **Copy and cut** put the selection on the clipboard as Markdown
    (`MarkdownEditingController.selectedMarkdown`, plain text flavor — Flutter's clipboard has one):
    text inside one block is its inline Markdown (`say **bo**`, escaped where it would read as a
    block), a selection across blocks or a whole block keeps the blocks cut at its ends, untouched
    blocks their exact source; inside a literal block the plain text. Pasting it back gives the
    same content. Cut is one undo step; read-only fields copy.
  - **Paste:** Markdown is converted into blocks and styles (fenced code becomes a literal
    block); `Mod+Shift+V` pastes plain text; a URL pasted over a selection makes it a link;
    literal blocks always take plain text. Plain text from other apps goes through the same path
    (Markdown in it is converted).
  - **Undo:** the field's own history (`Mod+Z`, `Mod+Shift+Z`): typing within a second is one
    step, every format change, autoformat and paste another; the shell's undo stack is not
    involved (08: text fields keep their own local undo). Undo right after an autoformat restores
    exactly what was typed, caret after it, like Write (04 §7): `## ` comes back as the text
    `## `. The Markdown reads `\##` until something follows the space — Markdown has no trailing
    whitespace at the end of a block, for any text.
  - **Focus:** a click anywhere in the field focuses it at once, so the IME connection (the
    browser's hidden textarea) exists before the next key arrives; a click below the text puts
    the caret at the end. (A post-frame focus waited for an unrelated frame — up to a caret blink
    of another field — and the first keys went to the previously focused field or nowhere.)
  - **Look:** the border, radius, padding, focus ring and disabled state of `ShadTextarea`; the
    text in the renderer's styles (`small`, regular weight, 1.45 line height; code in the
    monospace style of `WonkyMarkdown`, quotes muted with a bar, literal blocks in a muted,
    bordered box). A max length counts the Markdown (counter from 80%; typing and pastes past it
    are refused). Placeholders that open into a composer use its corner radius
    (`composerRadius`, the shad input/textarea decoration): the collapsed *Add a comment* /
    *Reply* field of `CommentThreadBody` is no longer a pill (18 px).
  - **Keys:** `<fieldKey>` (the field), `<fieldKey>.bold`, `.italic`, `.strike`, `.code`,
    `.link`, `.bullets`, `.numbers`, `.tasks`, `.quote`, `<fieldKey>.count` (`.codeBlock` is
    gone with code blocks). Removed with the toggle: `<fieldKey>.write`, `.preview`, `.rendered`
    (and `MarkdownEdits`, the plain-text transforms). Tests type with `enterMarkdown` /
    `typeMarkdown` (`package:wonky_app/testing.dart`).
  - **Spelling:** misspelled words get Write's red squiggles (not in literal blocks, links or
    inline code; the word being typed is held back until the caret leaves it), and a
    right-click opens the field's context menu: up to five suggestions (one replaces the word,
    one local undo step), *Ignore* (this session, every composer), *Add to dictionary* (the
    synced personal dictionary shared with Write and Slides), then *Cut*, *Copy*, *Paste*. The
    browser's context menu is off while the pointer is over the field. The composer follows the
    user's settings: off with Write's *Check spelling* off (`writeDefaults.spellcheck`), ALL-CAPS
    words per *Ignore words in UPPERCASE*; the language is the device (browser) locale. The
    super_editor glue is shared with Slides: `DocumentSpelling` (squiggles over a
    `DocumentSpellChecker`) and `spellingMenuEntries` live in `wonky_rich_editor` with the engine
    injected (`RichEditorSpellChecker`); the shell's checker is `ShellSpelling`
    (`wonky_app/spellcheck.dart`, which re-exports the glue); Slides' `EditorSpelling` is a
    `DocumentSpelling` over `SlidesSpelling`. Menu keys: `menu.markdown.spell.suggestion.<i>`,
    `.ignore`, `.add`, `menu.markdown.cut`, `.copy`, `.paste`.
  - **Bundle:** the shell depends on `wonky_rich_editor`, so Drive and Sheets now ship
    `super_editor` too (Write and Slides already did), also to signed-out board visitors.

### 7.4 Duplicates and merging (admin)

`board.merge(sourceNumber, targetNumber)`:

1. The source gets `status: duplicate` and `duplicateOfId`.
2. Its votes move to the target. A user who voted on both keeps the target vote.
3. Its comments stay on the source. The target shows *Merged from #388 (3 comments)* as a link.
4. The source's author and voters get a `boardStatus` notification.

Undo (`shell.board.merge`) is supported while no further vote has hit the target for the moved
voters. The move is recorded (`movedVoteIds`) and reverted.

### 7.5 Community flags

- *Flag* on an issue or comment, with a reason: offensive, spam, personal data, security, other.
  One flag per user per target.
- When **3 distinct users** flag a visible target (`board.flagsToHold`), it becomes `held`
  automatically and goes to the review queue. Admins can see the flags on any target.

### 7.6 Live updates

ClusterBus channels ([07](07-collaboration.md) mechanism):

- `board:post:<id>`: votes, comments, moderation and status changes;
- `board:tasks`: claims and status changes.

| Method | Use |
|--------|-----|
| `board.watchPost(number) → Stream<BoardPostEvent>` | The issue page, including the author's `checking` → `visible`/`held` transition |
| `board.watchTasks() → Stream<BoardTaskEvent>` | The *Up for grabs* and *Claimed* tabs and the tab counts |

The board list itself is not live: it refreshes on focus and on *Load more*.

## 8. Tasks and claiming

### 8.1 Claim

- `board.claimTask(taskNumber)`:
  - only for `published` tasks;
  - fails with `conflict` when the task is already claimed, with `limitExceeded` when the
    caller already has `board.maxActiveClaimsPerUser` (3, T-10) active claims (valid `claimed`
    ones: a task in review no longer counts), and with `forbidden` and the reason while the
    caller is claim-blocked (§8.4);
  - sets `claimedById`, `claimedAt` and `claimExpiresAt = now + board.claimHours` (48), and
    generates a new **claim code** (§13.7). The code is returned only to the claimant (task
    page, `board.getTask`, MCP `board.get_task`) and goes into the PR description (§13.1).
- **The prompt is the claimant's.** `BoardTaskView.prompt` and `promptBody` are empty for
  everyone but the claimant (a valid claim) and admins — in every read (`getTask`, `listTasks`,
  `claimTask`/`releaseTask` results, MCP `board.get_task`), so the prompt is not merely hidden in
  the UI. The claimant's prompt carries their claim code in its PR lines (§10.1); admins see the
  placeholder. After a release or expiry the former claimant gets none either.
- The claimant's GitHub login is learned from the first PR that passes the gate and stored on
  their board profile. It is shown on the task page.
- **Release** (*Unclaim this task* on the task page): `board.releaseTask(taskNumber)`, by the
  claimant or an admin. The task goes back to `published`.
- **Extend**: P1, `board.extendClaim` (+24 h, once, only in the last 12 h, only without a PR).
- Undo: claim ↔ release (`shell.board.claim` / `shell.board.release`), only while still valid.

### 8.2 Expiry

- A claim is **valid while `claimExpiresAt > now`**. Every read computes this, so the board never
  shows an expired claim, even if the job is late.
- `BoardFutureCall.sweep`, a recurring job `wonky.boardSweep` at `*/10 * * * *`, handles stale
  claims:
  - **expired claims** go back to `published`; a system activity row "Claim expired" is added and
    the claimant gets a `boardClaim` notification;
  - **claims with 6 h left** (not yet warned) get a reminder notification (*Your claim on T-12
    expires in 6 hours*), with the actions *Link PR* and *Release*.
  - Expiry and *Release* update the task conditionally (same status, claimant and claim time
    as read; expiry also only while `claimExpiresAt ≤ now`), so a concurrent claim, PR link or
    release is never overwritten with a stale row. A release that lost the race answers
    `conflict` (*This task changed meanwhile*).
- `inReview` tasks (PR linked) don't expire. A closed, unmerged PR releases the task (§13.6);
  admins can also release it by hand.

### 8.3 Linking a PR and finishing

- Linking normally happens through the gate (§13.4). `board.linkPullRequest(taskNumber, url)`
  is the admin fallback. The URL must match `https://github.com/<board.repository>/pull/<n>`. The
  task becomes `inReview`, and the URL is shown on the task and its issues.
- Merging the PR sets the task and its issues to `done` (§13.6; `board.markDone` is the admin
  fallback). Voters get a `boardStatus` notification (*Something you voted for was built*).
- A successful deploy containing the merge sets `shipped` (§13.6; `board.markShipped` is the
  admin fallback) and notifies voters again (*Now live on wonky.work*).

### 8.4 Claim blocks (T-10)

Claiming is blocked for `board.claimBlockDays` (14) days, for non-admins, after either:

- `board.expiredClaimsToBlock` (3) **expired claims**: claims that ran out without a linked pull
  request and without an unclaim (the `expired` activity rows with the claimant as actor, written
  by the sweep, by a claim that finds the claim expired, and by an unclaim after the deadline).
  A release in time is not counted; neither is a release by an admin;
- `board.invalidPostsToBlock` (2) **issues removed by a moderator** (`moderation: removed`, its
  `removedAt`): spam, offensive, personal data and the like. Declined issues are valid reports
  and do not count; neither do issues the author deleted.

The block is computed from the record on every claim and `board.me()` (`BoardTaskClaims.
claimBlock`), not stored: events in time order count per kind, the event that reaches the
threshold starts a block of 14 days from its time, and the count of that kind starts again. So
restoring a removed issue (the undo of *Remove*) lifts the block it caused, and a later
threshold extends a running block. A value of 0 turns that rule off.

- `board.claimTask` answers `forbidden` with the reason, e.g. *You can't claim tasks until
  November 2, 2026: 3 of your claims expired without a pull request or an unclaim.* or *… a
  moderator removed 2 of your issues.*;
- `BoardMe.claimBlockedUntil` and `claimBlockedReason` (and `maxActiveClaims`) tell the client:
  the task page disables *Claim this task* and shows the reason (§4.6);
- the block only concerns claiming: reporting, voting and commenting are unaffected (a board
  block, §9.2, is separate).

## 9. Admins and moderation

### 9.1 Who is an admin

```yaml
wonky:
  board:
    adminEmailDomains: [serverpod.dev]   # case-insensitive, exact domain match (not subdomains)
    adminEmails: []                      # extra individual admins
```

- `BoardAdmins.isAdmin(session)` reads `UserProfile.email` (lowercased) and checks the domain
  and the list. The result is cached per session.
- **Why the profile email is trustworthy**:
  - email/password accounts are created only after the verification code is confirmed;
  - Google sign-in rejects unverified Google emails (`validateGoogleAccountDetails`, the package
    default);
  - there is no email-change endpoint.

  §15 adds a server test that fails if an email-change path is ever added without
  re-verification, or if `validateGoogleAccountDetails` is overridden.
- Admin status is never stored. Removing the domain from the config removes admin rights at the
  next request.
- The same rule decides who sees the usage analytics in Wonky Drive ([19](19-usage-analytics.md)).
- `board.me()` returns `{signedIn, isAdmin, blocked, activeClaims, maxActiveClaims,
  claimBlockedUntil?, claimBlockedReason?, githubLogin?}` for the client.
  It is used to show admin UI only; every admin endpoint checks again on the server.
- Serverpod scopes are not used: they are tied to the auth session and would need a sync job
  when the config changes.

### 9.2 Admin tools

**Review tab** (`/improvements/review`), with these sections:

1. **Held**: flagged issues and comments, oldest first. Each shows the AI flags and reason, the
   community flags, and the author (with their other issues). The AI flags are the moderation
   scores at or above their *Review* band, best first (*AI scores: spam 0.91 · not_actionable
   0.62*), from `BoardPostView.reviewScores` (admins only; the server applies the current
   thresholds to the stored triage). Actions:
   - *Approve* (visible);
   - *Remove* (with a reason: offensive, spam, personal data, security, other, plus optional
     text shown to the author). The reason starts at the one the issue was held for: the highest
     review score (`spam`, `offensive`, `personal_data`, `security`), else the hold reason, else
     the most common community flag, else *Other*;
   - *Edit and approve*: the admin edits out personal data, for example. The issue shows
     *Edited by a moderator*.
2. **Check**: visible issues and comments with a moderation score in the *Review* band (§6.2),
   with *Looks fine* or *Hold*. **Unchecked**: issues that skipped triage.
3. **Possible duplicates**: AI hints with confidence ≥ 0.8. Actions: *Merge* or *Not a
   duplicate*.
4. **Suggested bundles** (§9.3).
5. **Draft tasks**: tasks waiting for prompt review and publishing.
6. **Error reports** (P1): automatic client error reports (§12), grouped by message and top
   stack frame, with counts and the last seen time. Action: *Create bug from this* opens the
   report dialog with the error prefilled as the admin.

**On any issue or comment** (⋮ menu), admins can:

- *Set kind / area / size*: confirms the AI labels, and the *AI* marker disappears;
- *Apply suggested title*;
- *Remove* / *Restore*, and *Remove screenshot*;
- *Decline…*, *Merge into…*;
- *Select for building*, *Add to task…* (§9.3);
- *Block user from the board…*.

**Blocking.** A `board_user_block` row (user, reason, admin, `until?`). Blocked users can read
but not write. Their held content stays held, and nothing else of theirs is hidden automatically.
*Remove all issues by this user* is a separate, confirmed action.

**Audit log.** Every admin action writes a `board_moderation_log` row (admin, action, target,
before/after JSON, reason). It is visible to admins on each target (*History*).

Every admin action is undoable through the shell stack (`board` undo domain) with an inverse
endpoint call:

| Action | Undo |
|--------|------|
| approve | re-hold |
| remove | restore |
| label change | previous labels |
| merge | unmerge (§7.4) |
| decline | reopen |
| block | unblock |
| task changes | previous state |

### 9.3 Selecting and bundling

- **Select one issue**: *Select for building* on an issue creates a draft task (title from the
  issue, area and size from the labels) and generates the prompt (§10). The selection is the
  approval (T-11): the task is published in the background once its prompt is written, also
  when the admin has left the page.
- **Manual bundle**: on the board, admins get checkboxes on rows. With several issues selected,
  the action bar offers *Create task from 4 issues…* (title, area, size), and the draft task
  links all of them. **Comments for the prompt (T-10):** on the issue page the admin checks the
  comments right in the thread (§4.5), and *Select for building* passes the unchecked ones. Where
  the comments are not on screen (*Create task from N issues…* on the board, a suggestion's
  *Edit*), the task dialog lists the visible comments people wrote on the issues, grouped under
  `#412 Title`, one checkbox each
  (`Name: the first 140 characters`, plain text), all checked, in a scrolling box of at most
  240 px (`ChecklistFieldSpec` of `WonkyDialogSpec`, so MCP can tick them too: type
  `checklist`; keys `dialog.board.task.comments` and `dialog.board.task.comments.<uuid>`). The
  unchecked ones go to `createTask(…, excludedComments: [uuid])` and are stored on the task
  (`promptExcludedCommentIds`); every prompt the AI writes for the task (§10.1, *Regenerate*,
  rewrites) leaves them out, while the other comments, also later ones, are included. Merged
  tasks keep each task's left-out comments. `shell.board.admin.createTask` takes
  `excludedComments` (uuids) too (given, even empty, the dialog lists no comments) and redo
  keeps them; a uuid of another issue's comment is an `invalidArgument`. *Add to task…* adds
  selected issues to an existing draft, published or claimed task. The same *Add to task…* is
  in an issue's admin toolbar (open issues not in a task, `board.post.bar.addToTask`, §4.5),
  and the task page has *Add issues…* and a remove button per
  linked issue. All of them are `shell.board.admin.setTaskPosts`.
- **Changing a task's issues rewrites its prompt** (decided 2026-10-19). When `setTaskPosts`
  adds or removes issues (an unchanged set is a no-op), or tasks are merged (below), the AI
  writes the prompt again for all the issues (`BoardTasks._rewritePrompt`, the same background
  pass as §10.1):
  - a published task nobody holds goes **back to draft** until the prompt is written, so nobody
    claims it with the old prompt. It leaves *Up for grabs*, gets an activity row (`rewriting`:
    *changed the issues; the task is a draft until the AI has rewritten the prompt*), and the
    prompt job publishes it again (or holds it, as for a new task, §10.2). Its issues stay
    `planned` meanwhile; when it is published again only the issues that change status (the
    added ones) become `planned` and tell their voters, so nobody hears *Planned* twice;
  - a draft stays a draft; a claimed or in-review task keeps its status and claim, and its
    claimant gets the new prompt (a flagged rewrite is not applied, §10.1);
  - without Gemini the prompt stays as it is and the issues follow the task's status (added
    issues of a published task become `planned` at once); over the budget, `promptNote` says so.
  - Undo of *Add to task…* is `setTaskPosts` with the previous issues, so it rewrites again.
- **Merging tasks** (admins, decided 2026-10-19): on *Up for grabs*, admins get *Select* at the
  end of a 48 px bar above the list (`board.tasks.select`); rows get checkboxes
  (`board.task.<n>.select`), and with tasks selected the bar becomes the drive's selection pill
  (`board.tasks.selectionBar`: *Clear*, *N selected*, *Merge N tasks…*, the last disabled below
  two tasks with the tooltip *Select two tasks or more to merge them*). *Merge N tasks…*
  (`shell.board.admin.mergeTasks {taskNumbers, title?, area?, size?}`, Lucide `merge`) opens the
  task dialog (`dialog.board.task`, titled *Merge N tasks…*, button *Merge*) prefilled from the
  oldest task, then `board.mergeTasks(numbers, title, area, size)`:
  - only tasks nobody holds can be merged (draft, or published without a valid claim): anything
    else is a `conflict`; at most 20 issues in all (`maxPostsPerTask`);
  - the **oldest task (lowest number) remains**: it takes the issues of the others and the
    dialog's title, area and size, and gets a `mergedTasks` activity row (*merged T-5, T-7 into
    this task*);
  - the others are `cancelled` (claims and pending prompts cleared) with a `mergedInto` row
    (body `T-3`). `BoardTaskView.mergedInto` (from the latest such row of a cancelled task) makes
    their task page show *This task was merged into T-3.* with *Open T-3*
    (`board.task.notice.merged`) instead of the cancelled notice;
  - the prompt is rewritten as above (so a published result is a draft until it is written);
  - the client opens the remaining task. Undo (`BoardUndoOp.mergeTasks`) is
    `board.unmergeTasks(number)`: from the last `mergeTasks` row of the moderation log (its
    `before` holds each task's status, title, area, size, prompt body and issues) it gives every
    task its issues, status, labels and prompt back, drops a pending rewrite and adds an
    `unmerged` row; issues added after the merge stay with the remaining task. It is a
    `conflict` when the remaining task was claimed meanwhile, a merged task changed, or the last
    merge was already undone. Redo merges again with the same arguments.
- **AI-suggested bundles**: *Suggest bundles* in the Review tab (admin-triggered, not
  scheduled) does the following:
  1. sends the visible `open` issues of size `small`, with their summaries and labels, up to
     200 issues, to Gemini (`board.ai.geminiModel`) with the tool `propose_bundles`;
  2. the model returns groups of 2–8 issues that share an area and likely touch the same code,
     each with a title and a rationale;
  3. suggestions are stored (`board_bundle_suggestion`) and listed with *Create task*, *Edit*
     (add or remove issues, rename) or *Dismiss*;
  4. an issue already in a task, or in a dismissed suggestion with the same members, is not
     suggested again.
- **Publishing**: the task's issues move to `planned` and their voters get a `boardStatus`
  notification (*Planned: a contributor can now pick this up*).

## 10. Contributor prompt and the contribution kit

### 10.1 Prompt generation

When a draft task is created, on *Regenerate* and when a task's issues change (§9.3), Gemini (`board.ai.geminiModel`) writes the
prompt with the tool `write_task_prompt`. Without Gemini, the editor starts from the template with
empty sections.

Writing takes about a minute, so it never blocks the request: `createTask` stores the draft at once
with the blank template, sets `promptRequestedAt` and schedules `BoardFutureCall.writePrompt`
(`regeneratePrompt` does the same and returns at once). The future call writes the body, sets
`promptGeneratedAt`, clears `promptRequestedAt` and issues `taskChanged` on `board:tasks`, so open
task pages and the prompt editor refresh live. `BoardTaskView.promptPending` is true while a pass
is scheduled (at most 10 minutes, so a lost call never blocks publishing); the task page and the
editor show *Writing the prompt with AI… this takes about a minute* with a spinner, and *Publish*
(and the editor's *Save*, *Regenerate*) stay disabled; `publishTask` answers `conflict` meanwhile.
(T-11) A written body of a draft is linted (§10.2): when the lint finds nothing the job publishes
the task right away with `publishTask`'s side effects (issues `planned`, the *Planned* notification,
the `published` activity row; the moderation log names the admin who created the task, with the
reason "Published when the AI prompt was written."). When it flags something the body is stored,
the task stays a draft and `promptNote` reads "Held for review: line 5 has "curl …" (and 1 more),
which is unusual for a task. Read the prompt, then save it to publish the task." A regenerated body
of a task that is already published is not applied when flagged (the note says so and the
current prompt stays), since contributors would get it unread.
When the daily budget is used up (`BoardAiBudgetException`) or Gemini fails, the body stays and
`promptNote` (admins only) says why; the task page shows it. *Set prompt* (the admin's own text,
or undoing *Regenerate*) cancels a pending pass: its result is dropped when `promptRequestedAt`
changed. The input:

- the task title, area and size;
- for each issue: kind, title, body, included details, the screenshot URL (a stable redirect,
  `/improvements/p/412/screenshot`), and up to 20 visible comments, oldest first, without the
  ones the admin left out when creating the task (T-10, §9.3; all as delimited untrusted
  data);
- the **spec index**: `specs/README.md` tables plus the headings of the area's spec files. The
  server reads them from a generated snapshot (`wonky_server/lib/src/platform/board/ai/spec_index.g.dart`,
  written by `dart run tool/spec_index.dart`; a test fails when it is stale) so it doesn't need a
  checkout.

The output is the **prompt body**: goal, acceptance criteria (a checklist), the specs and sections
to read, likely packages and folders, what is out of scope, and the tests to add.

(T-16) The tool also returns `changesUi` (required): whether the task changes what users see.
For UI tasks the server — not the model — appends the fixed criterion
`- [ ] The pull request description includes a screenshot of the changed UI (light and dark where
both change).` (`TaskPromptTemplate.screenshotCriterion`) as the last item of *Acceptance
criteria* (adding the section after *Goal* when it is missing). When the model leaves the flag
out, every area but `server` counts as UI. Admins may also write their own item: any checklist
item that names a screenshot and the PR (or pull request) description asks for one
(`TaskPromptTemplate.requiresScreenshot`, read by the review, §13.5). The server then
wraps it in a fixed template (`platform/board/prompts/task_prompt_template.md`) that the model
cannot change:

```markdown
# Wonky task T-12: <title>

You are working in a clone of github.com/serverpod/wonky. Read AGENTS.md first and follow
it (specs are the source of truth, every action is a command and undoable, single window,
light and dark, the checklist after changes).

<AI-written body: goal, acceptance criteria, specs to read, likely code, out of scope, tests>

## Reports this task comes from
- #412 Paste into merged cells drops styles — https://wonky.work/improvements/p/412.md (14 votes)
  …

## When you are done
- Run the checklist in AGENTS.md (analyze, format, tests).
- Update the specs if behavior changed.
- Before you open the pull request, stop and ask the user to verify the feature or the fixed bug
  by hand: tell them how to try it (which app to start, where to go, what to do and what they
  should see) and wait for their answer. If they find a problem, fix it, run the checklist again
  and ask again. Do not open the pull request until they confirm that it works.

Once the user has confirmed, open a pull request against `main`. Its description contains these
two lines:

~~~
Wonky-Task: T-12
Wonky-Claim: 7Q4F-K2M9
~~~

and a short summary of how each acceptance criterion is met.
```

(T-10) The links of *Reports this task comes from* are the issues' Markdown versions
(`/improvements/p/412.md`, §4.3: body, details and comments), which a coding agent can read
directly; the page link is in that file.

The "When you are done" part is built in code (`TaskPromptTemplate.wrap`, with the two lines in
a ```` ``` ```` block). For the claimant the server builds it with their actual claim code
(`claimCode:`), as above; admins' views keep the placeholder
`Wonky-Claim: <your claim code from the task page>`. Nobody else gets the prompt (§8.1), so the
claim code still reaches no one but the claimant.

**Manual verification before the pull request.** The frame always tells the agent to stop before
the pull request and have the user try the feature or fix by hand
(`TaskPromptTemplate.manualVerificationStep`), whatever the AI wrote in the body: no pull request
is opened for a change nobody has seen working. The frame is added when the task is shown
(`board_views.dart`), so tasks written before this rule get it too.

### 10.2 Admin review (when the lint flags the prompt)

- **Decided (T-11):** there is no mandatory review. The admin's *Select for building* (or
  *Create task*) approves the task, and a written prompt publishes it (§10.1). The defense
  against prompt injection (§11) — issue content flows through AI into a prompt that contributors
  run in coding agents with repository access — is now the lint below, run by the server
  (`lintTaskPrompt`, `package:wonky_core/board.dart`, shared with the editor): a flagged prompt
  holds its task as a draft until an admin has read it and saved it (*Save* in the editor of a
  draft also publishes; there is no separate *Publish* button). Prompts are still fenced as
  untrusted data (§10.1), and admins can edit, regenerate or cancel a published task.
- The prompt editor is a `MarkdownComposer` with a large preview. It also shows a diff against
  the last generated version after *Regenerate*.
- `promptEditedById` and `promptEditedAt` are stored. Edits are undoable, and the editor has its
  own text undo.
- The prompt editor highlights instructions that are unusual for a task: shell commands
  outside `flutter`/`dart`/`serverpod`/`git`, URLs outside the repo and wonky.work, and "ignore",
  "secret", "token" or "credential" wording. In the editor it is a warning list, not a block;
  on the server it decides whether a written prompt publishes its task (T-11).

### 10.3 Contribution kit

- **`CONTRIBUTING.md`** (new, repository root, linked from the task page and
  `/improvements/contribute`) covers:
  1. Get the tools: Flutter, Serverpod and a frontier coding agent (Codex, Claude Code,
     Antigravity, Cursor; any agent that reads `AGENTS.md` and uses MCP servers), with the
     [Serverpod installation guide](https://docs.serverpod.dev/installation) and Flutter at least
     the CI version.
  2. Get the right version of Serverpod: `dart install serverpod_cli <VERSION>` (the version of
     the CI workflow).
  3. Fork the repository on GitHub (the in-app step links to `https://github.com/<repo>/fork`).
  4. Clone the fork and run `flutter pub get`.
  5. In `wonky_server`, create `config/passwords.yaml` from `passwords.example.yaml` (development
     defaults only; AI keys are optional).
  6. Pick a task: claim it, start the agent with the repository root as its working directory,
     give it the prompt and review the result. There is no step to start the server: since
     Serverpod 4.1.0-rc.1 the agent starts it (and the development database and the apps)
     through the `serverpod` MCP server (`.mcp.json` and the other agents' configs are in the
     repo); `serverpod start` in `wonky_server` attaches to it.
  7. Open a pull request (the agent helps): PR rules (§13.1), one task per PR, the
     `Wonky-Task:` and `Wonky-Claim:` lines, the checks *Wonky task* and *Wonky task review*, and
     auto-close after 7 days without a valid task.
  8. Sign the CLA and follow up (B13): the Serverpod CLA is signed once, on GitHub, on the first
     pull request, by replying to the CLA Assistant bot; then check back once the pull request is
     reviewed and fix what the review points out.
  9. License (BSD-3-Clause) and security issues: email `security@serverpod.dev`, never an issue
     or PR (`SECURITY.md`).
- **In-app page** `/improvements/contribute`: a short version of steps 1–8 with copy buttons and
  a link to the full file on GitHub. Links are small outline buttons under a step's text, through
  the external-link confirmation where they leave the app: step 1 *Serverpod installation guide*,
  step 3 *Fork on GitHub*, step 6 *Up for grabs* (the board's tab), step 7 *View pull requests*
  (`https://github.com/<repo>/pulls`; the step has no PR lines to copy, the agent writes them from
  the prompt). The commands are `boardSetupCommands` (no run or Docker step); step 8 has the CLA
  reply line (`boardClaSignLine`) to copy; under the steps, the license and security lines. The text is part of the app's strings, not fetched, because the board must work
  offline from GitHub.
- **`.github/ISSUE_TEMPLATE/config.yml`** adds a contact link *Report bugs and suggest
  improvements in Wonky Work* (`https://wonky.work/improvements`) and sets
  `blank_issues_enabled: false`. The existing `bug_report.yml` stays for self-hosters.
- **`.github/pull_request_template.md`** has the `Wonky-Task:` and `Wonky-Claim:` lines, a
  summary, an acceptance-criteria checklist and a test plan.
- **`SECURITY.md`**: how to report a vulnerability (`security@serverpod.dev`), what to include,
  and that board issues and PRs are the wrong place.

## 11. Security, privacy and abuse

| Risk | Mitigation |
|------|------------|
| Security vulnerabilities posted publicly | The dialog says to email `security@serverpod.dev` (`board.securityContact`, B14) instead. Jev's `security` Noul holds at ≥ 0.5 and lists for review at ≥ 0.2, and admins see those issues first. Removed security issues are kept for admins only |
| Personal data in issues or screenshots | Warning in the dialog and the editor; cover tool; route ids stripped; Jev's `personal_data` check (§6.2); P2 Jev screenshot check (§6.2); authors can remove screenshots, delete issues and edit until the issue is in a task |
| Offensive content, spam | Triage at submit; community flags (3 → held); admin removal; per-user blocks; rate limits (below) |
| Prompt injection into triage, task prompts or reviews | Jev returns only typed answers (no text that could carry instructions); issues that argue for their own classification are caught by the review band and community flags. Gemini receives issue and PR text as delimited untrusted data and answers through a schema. Task prompts need admin review before publishing (§10.2) and are linted; the fixed template frames the AI text. PR reviews are advisory |
| Forged GitHub webhooks, claim takeover through PRs | HMAC-verified webhooks, delivery dedupe, per-claim codes (§13.7) |
| Vote manipulation | One vote per account; accounts need a verified email; votes from blocked users are excluded from scores (recomputed on block); P2: weight new accounts lower |
| Claim hoarding | 3 active claims per user; 48 h expiry; 3 expired claims or 2 removed issues block claiming for 2 weeks (§8.4); admins release; PRs without a valid task auto-close after 7 days |
| Runaway AI spend | Separate daily token budgets for Jev and Gemini (§6.1), per-PR review limits (§13.5), rate limits below |
| Admin impersonation | Admin rights come only from the server-side domain check (§9.1). *Admin* badges are rendered from the server's flag on each issue or comment, never from the display name |
| Enumeration of private data | Board endpoints return display names and avatars only, never emails or user ids beyond what `CommentView` already exposes |
| XSS through Markdown | The renderer builds widgets (no HTML); links are restricted to `http(s)`/`mailto` |

**Rate limits** (`board.*` config, per user, across instances; admins (§9.1) have none, since they
moderate and post in bulk):

- issues: 5 per hour, 20 per day;
- comments: 30 per hour;
- votes: 300 per hour;
- flags: 30 per day;
- similar-post queries (incl. Jev rerank): 60 per minute;
- edits of issues and comments together (each one is checked by Jev): 30 per hour
  (`editsPerHour`).

Signed out, `similar` and `list` with a query are limited per client address
(`similarPerMinute`) and for all signed-out callers together (`signedOutSearchesPerMinute`,
300 per minute, a bound that holds when addresses are forged or rotated). The search text is
capped at 200 characters (a longer `list` query or `similar` title is cut).

They are implemented with a generic `RateLimiter` extracted from `McpRateLimiter`
(`platform/common/rate_limiter.dart`): Redis-backed with a memory fallback. MCP then reuses it.

**Retention**: removed issues and comments are purged after 90 days (as built, by
`wonky.boardSweep`, not `wonky.daily`), along with
their screenshots. Deleted (by author) issues are purged after 30 days. The moderation log is kept
for 1 year.

**Account deletion** ([13 §2](13-security-and-operations.md)) removes the user's issues that are
not part of a task, their screenshots and their votes. Comments and issues in tasks are anonymized
("Deleted user").

## 12. Data model

All server code is in `wonky_server/lib/src/platform/board/` (endpoint `BoardEndpoint`, service
`BoardService`, `BoardAdmins`, `triage/`, `prompts/`, `BoardFutureCall`). Table names are
prefixed `board_`. Models are sketched below; enums are `serialized: byName`. The public numbers `#123` and `T-12`
are the row ids, so no extra sequences are needed (the API calls them `number`).

```yaml
enum: BoardPostKind        # bug, idea
enum: BoardArea            # drive, write, sheets, slides, suite, server
enum: BoardSize            # small, medium, large
enum: BoardPostStatus      # open, planned, done, shipped, declined, duplicate
enum: BoardModeration      # checking, visible, held, removed
enum: BoardTriageState     # pending, done, unchecked, failed
enum: BoardTaskStatus      # draft, published, claimed, inReview, done, shipped, cancelled

class: BoardPost
table: board_post
fields:
  authorId: int?, relation(parent=user_profile, onDelete=SetNull)
  kind: BoardPostKind
  reportedKind: BoardPostKind          # what the author picked
  area: BoardArea?
  size: BoardSize?
  aiLabels: bool                       # labels come from AI, not yet confirmed by an admin
  title: String
  body: String                         # Markdown
  contextJson: String?                 # included details (§4.2.4)
  appHint: String
  screenshotFileId: int?, relation(parent=stored_file, onDelete=SetNull)
  status: BoardPostStatus
  moderation: BoardModeration
  moderationReason: String?            # shown to the author when removed
  triageState: BoardTriageState
  triageJson: String?, scope=serverOnly   # last TriageResult (admins get it through a view)
  suggestedTitle: String?
  summary: String?
  duplicateOfId: int?                  # self relation
  possibleDuplicateOfId: int?
  declineReason: String?
  taskId: int?, relation(parent=board_task, onDelete=SetNull)
  score: int
  voteCount: int
  commentCount: int
  flagCount: int
  createdAt: DateTime
  editedAt: DateTime?
  deletedAt: DateTime?
indexes:
  board_post_list_idx: { fields: moderation, kind, status, score }
  board_post_author_idx: { fields: authorId }

class: BoardVote
table: board_vote
fields:
  postId: int, relation(parent=board_post, onDelete=Cascade)
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  value: int                           # +1 or -1
  createdAt: DateTime
indexes:
  board_vote_unique_idx: { fields: postId, userId, unique: true }
  board_vote_recent_idx: { fields: postId, createdAt }

class: BoardComment
table: board_comment
fields:
  uuid: UuidValue                      # client-supplied, idempotent create
  postId: int?, relation(parent=board_post, onDelete=Cascade)
  taskId: int?, relation(parent=board_task, onDelete=Cascade)   # task activity (system rows only, admins read them)
  authorId: int?, relation(parent=user_profile, onDelete=SetNull)
  body: String                         # Markdown, ≤ 10,000 chars
  systemEvent: String?                 # claimed, released, expired, prLinked, done, merged, …
  moderation: BoardModeration          # visible | held | removed
  reactions: String                    # P1, JSON {emoji: [userId]}
  createdAt: DateTime
  editedAt: DateTime?
  deletedAt: DateTime?

class: BoardTask
table: board_task
fields:
  title: String
  area: BoardArea
  size: BoardSize
  status: BoardTaskStatus
  promptBody: String                   # AI-written, admin-edited (§10)
  promptGeneratedAt: DateTime?
  promptRequestedAt: DateTime?         # an AI pass is scheduled (§10.1)
  promptNote: String?                  # why the last AI pass left the body (admins)
  promptExcludedCommentIds: List<int>?  # comments left out of the prompt (T-10, §9.3)
  promptEditedById: int?
  promptEditedAt: DateTime?
  createdById: int
  publishedAt: DateTime?
  claimedById: int?, relation(parent=user_profile, onDelete=SetNull)
  claimedAt: DateTime?
  claimExpiresAt: DateTime?
  claimWarnedAt: DateTime?
  claimCode: String?, scope=serverOnly # §13.7; returned to the claimant through views only
  pullRequestUrl: String?
  prNumber: int?
  prAuthorLogin: String?
  mergeCommitSha: String?
  doneAt: DateTime?
  shippedDeploySha: String?
  shippedAt: DateTime?
  createdAt: DateTime

class: BoardFlag
table: board_flag
fields:
  postId: int?, relation(parent=board_post, onDelete=Cascade)
  commentId: int?, relation(parent=board_comment, onDelete=Cascade)
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  reason: String                       # offensive | spam | personalData | security | other
  note: String?
  createdAt: DateTime

class: BoardUserProfile               # board-specific per-user data
table: board_user_profile
fields:
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  githubLogin: String?
  blockedAt: DateTime?
  blockedUntil: DateTime?
  blockedReason: String?
  blockedById: int?

class: BoardBundleSuggestion
table: board_bundle_suggestion
fields:
  title: String
  rationale: String
  postIds: List<int>
  state: String                        # pending | accepted | dismissed
  createdAt: DateTime

class: BoardPullRequest              # every PR the App has seen (§13)
table: board_pull_request
fields:
  prNumber: int
  taskId: int?, relation(parent=board_task, onDelete=SetNull)
  authorLogin: String
  headSha: String
  state: String                        # open | closed | merged
  gateState: String                    # pending | passed | failed | exempt
  gateReason: String?
  gateFirstFailedAt: DateTime?
  gateCommentId: int?
  reviewCommentId: int?
  lastReviewSha: String?
  lastReviewJson: String?
  lastReviewAt: DateTime?
  reviewDay: String?                   # yyyy-mm-dd, with reviewCount for the per-day limit
  reviewCount: int
  mergeCommitSha: String?
  createdAt: DateTime
  updatedAt: DateTime
indexes:
  board_pull_request_number_idx: { fields: prNumber, unique: true }

class: BoardGithubDelivery
table: board_github_delivery
serverOnly: true
fields:
  deliveryId: String
  event: String
  receivedAt: DateTime
indexes:
  board_github_delivery_idx: { fields: deliveryId, unique: true }

class: BoardAiUsage
table: board_ai_usage
serverOnly: true
fields:
  day: String                          # yyyy-mm-dd (UTC)
  provider: String                     # jev | gemini
  model: String
  feature: String                      # triage, commentCheck, rerank, summary, bundles, prompt, prReview
  requests: int
  inputTokens: int
  outputTokens: int
indexes:
  board_ai_usage_idx: { fields: day, provider, model, feature, unique: true }

class: BoardModerationLog
table: board_moderation_log
serverOnly: true
fields:
  adminId: int
  action: String
  targetKind: String                   # post | comment | task | user
  targetId: int
  beforeJson: String?
  afterJson: String?
  reason: String?
  createdAt: DateTime
```

Views sent to clients: `BoardPostView`, `BoardPostListItem`, `BoardCommentView`, `BoardTaskView`,
`BoardMe`, `BoardPage<T>`-style pages with a cursor (`BoardPostPage`, `BoardTaskPage`). They
include the author display name, avatar and an `isAdmin` flag, and never emails.
`BoardTaskView` carries two prompt fields: `promptBody` (the editable AI-written body, §10.2) and
`prompt` (the full prompt: the fixed template around the body, §10.1, which the task page copies
and `board.get_task` returns; the claimant's has their claim code in its PR lines). Both are
empty for everyone but the claimant and admins (§8.1). Plus `promptPending` and, for admins,
`promptNote` (§10.1), `reviewJson` (§13.5) and, for the claimant only, `claimCode`. `BoardPostView.reviewScores` (admins
only) lists the moderation scores at or above their review band (§9.2).

**Feedback fold-in (B9).**

- `FeedbackEndpoint.submit` (the old *Report a problem* dialog) is removed from the client.
  Older clients that still call it get their message stored as before (the endpoint stays, so
  they don't break), and P1 surfaces those rows in the Review tab as *Legacy feedback*. They are
  never made public: they were written as private messages.
- `FeedbackEndpoint.reportError` (automatic client error reports) stays as private telemetry. It
  feeds the admin *Error reports* view (§9.2, P1) and the dialog's *Include the last error*.
- `showFeedbackDialog` is deleted; `shell.help.feedback` becomes the alias from §4.1.
- **As built:** the endpoint and `FeedbackKind.errorReport` are unchanged. The legacy feedback view
  (P1) is not built.

**Endpoint** `BoardEndpoint` (`board`). `requireLogin` is false: read methods work signed out,
and write methods call `BoardService.requireWriter(session)` (signed in, not blocked). **As built**,
the method names differ from the groups below in a few places: `listTaskComments` (a task's
activity rows, admins only; empty for everyone else), `unflag`,
`counts` (the tab badges, `BoardCounts`: open ideas and bugs, *Up for grabs*, *Claimed*),
`reviewCounts`, `listSuggestions` and `dismissDuplicateHint` exist besides the listed ones;
`moderate` is split into `moderatePost` and `moderateComment`; *Edit and approve* is
`adminEditPost`; and `markDone`, `markShipped` and `cancelTask` are one method,
`setTaskStatus(number, status)`.

| Group | Methods |
|-------|---------|
| Read | `me()`, `list(BoardListQuery)` → page, `getPost(number)`, `listComments(postNumber, cursor)`, `similar(text, kind)`, `getScreenshotUrl(postNumber)`, `listTasks(filter, cursor)`, `getTask(number)`, `watchPost(number)`, `watchTasks()` |
| Write | `createScreenshotUpload(…)`, `createPost(BoardPostDraft)`, `editPost(number, title, body)`, `deletePost(number)`, `restorePost(number)` (undo), `removeScreenshot(number)`, `vote(number, value)`, `addComment(uuid, postNumber?, taskNumber?, body)` (issues only: a `taskNumber` is refused), `editComment(uuid, body)`, `deleteComment(uuid)`, `restoreComment(uuid)`, `flag(target, reason, note)`, `claimTask(number)`, `releaseTask(number)` |
| Admin | `reviewQueue(section, cursor)`, `moderate(target, action, reason?)`, `setLabels(number, kind?, area?, size?)`, `applySuggestedTitle(number)`, `merge(source, target)`, `unmerge(source)`, `decline(number, reason)`, `reopen(number)`, `blockUser(userId, reason, until?)`, `unblockUser(userId)`, `createTask(postNumbers, title, area, size, {excludedComments})`, `updateTask(number, …)`, `setTaskPosts(number, postNumbers)`, `mergeTasks(numbers, title, area, size)`, `unmergeTasks(number)`, `regeneratePrompt(number)`, `setPrompt(number, body)`, `publishTask(number)`, `linkPullRequest(number, url)`, `markDone(number)`, `markShipped(number)`, `cancelTask(number)`, `suggestBundles()`, `dismissSuggestion(id)` |

**Config** (`wonky: board:`, parsed in `BoardConfig.fromMap`, env overrides `WONKY_BOARD_*`):

```yaml
wonky:
  board:
    enabled: true
    adminEmailDomains: [serverpod.dev]
    adminEmails: []
    repository: serverpod/wonky        # PR URL check, contribute links
    securityContact: security@serverpod.dev
    claimHours: 48
    claimWarnHours: 6
    maxActiveClaimsPerUser: 3
    expiredClaimsToBlock: 3            # §8.4 (T-10); 0 turns the rule off
    invalidPostsToBlock: 2
    claimBlockDays: 14
    flagsToHold: 3
    publishWhenTriageFails: true
    limits: {postsPerHour: 5, postsPerDay: 20, commentsPerHour: 30, votesPerHour: 300,
             flagsPerDay: 30, similarPerMinute: 60, editsPerHour: 30,
             signedOutSearchesPerMinute: 300}
    ai:                                  # §6; keys: internalJevApiKey, internalGeminiApiKey
      jevModel: jev-1.13.0               # pinned; thresholds are tuned per version
      geminiModel: gemini-3.1-pro-preview  # prompts, bundles, PR reviews
      geminiFastModel: gemini-3.8-flash    # titles and summaries
      jevDailyTokenBudget: 20000000      # ≈ $0.84/day at $0.042 per Mtok
      geminiDailyTokenBudget: 5000000
      thresholds: {…}                    # §6.2 table
    github:                              # §13; passwords: githubAppPrivateKey, githubWebhookSecret
      enabled: false
      appId: 0
      maintainerOrg: serverpod
      autoCloseDays: 7
      reviewBlocking: false
      reviewsPerPrPerDay: 10
      maxDiffTokens: 400000
      deployWorkflow: deploy.yml
```

The client gets `board: {enabled, repository}` through `config.json` (`AppConfigRoute`).

**Notifications** ([07 §4](07-collaboration.md)): new `NotificationKind` values and a settings
category `board` (default: in-app + digest email).

| Kind | Sent to | When |
|------|---------|------|
| `boardReply` | the issue author and earlier commenters | a new comment on the issue |
| `boardStatus` | the author and voters | the issue becomes planned, done, shipped, declined or duplicate; the issue is held or removed (author only, with the reason) |
| `boardClaim` | the claimant | 6 h warning, expiry, an admin released the claim, the linked PR was closed without merge |

The links point at `/drive/improvements/p/<n>` or `/drive/improvements/t/<n>`. `NotificationService.notify`
already accepts notifications without a drive item.

## 13. GitHub integration

Only PRs that implement a claimed task are accepted (maintainers excepted). Each PR gets an AI
review against its task's acceptance criteria. Merging a PR finishes the task, and deploying it
ships it. Decisions G1–G7 are in §1.

```
contributor claims T-12 ──► gets claim code 7Q4F-K2M9 (task page, MCP)
        │
        ▼
opens PR with "Wonky-Task: T-12" + "Wonky-Claim: 7Q4F-K2M9"
        │  pull_request webhook
        ▼
Wonky server (GitHub App) ──► check "Wonky task"         pass ─► task inReview, claim stops expiring
        │                     (gate, §13.4)              fail ─► bot comment; auto-close after 7 days
        ├────────────────────► check "Wonky task review"  (advisory AI review, §13.5)
        │
   merged ──► task done ──► deploy workflow succeeds ──► task shipped (§13.6)
   closed ──► task published again, claim released
```

### 13.1 PR rules (in `CONTRIBUTING.md` and the PR template)

- One task per PR (G6). A task may bundle several bugs (§9.3). The description contains exactly
  one of each line:

  ```
  Wonky-Task: T-12
  Wonky-Claim: 7Q4F-K2M9
  ```

  Parsing is case-insensitive and tolerant of whitespace and Markdown formatting around the
  values.
- The claim code proves the PR comes from the person holding the claim (G3). It is generated per
  claim and shown only to the claimant: on the task page and through MCP `board.get_task`.
- Members of the `serverpod` GitHub organization are exempt (G2). Bots are not exempt; no bots
  open PRs in this repository today.

### 13.2 Build or reuse

| Part | Choice | Why |
|------|--------|-----|
| Gate, task lifecycle, shipped detection | **Build**: a GitHub App whose webhooks go to the Wonky server (G4) | Only the Wonky server knows tasks, claims and codes. One place holds the keys. No secrets in Actions, and no `pull_request_target` workflows that could expose them to fork PRs |
| Task review (does the PR do what the task asks?) | **Build**: one Gemini call in the server (§13.5) | Needs the task's acceptance criteria and issues, which existing review tools don't have. About one tool schema and a prompt on top of the board AI clients (§6.1) |
| General code review (style, bugs, line comments) | **Reuse, optional**: an off-the-shelf reviewer (for example Google's Gemini Code Assist GitHub app, or the Claude Code GitHub Action) can be enabled on the repository independently | Mature, maintained, and not task-specific. Not part of this spec; it neither reads nor writes board data |

### 13.3 GitHub App

- **App**: *Wonky Work bot*, owned by the `serverpod` organization and installed on
  `serverpod/wonky` only.
  - **Permissions**: Checks (read and write), Pull requests (read and write: comments, labels,
    close), Contents (read: diffs, compare), Metadata (read), Organization members (read: the
    exemption check).
  - **Events**: `pull_request`, `check_run` (re-run requests), `workflow_run`.
- **Credentials**: the passwords `githubAppPrivateKey` (PEM) and `githubWebhookSecret`. The
  config holds `board.github.appId`. The server signs an RS256 app JWT and exchanges it for an
  installation token (cached for 50 minutes).
- **Webhook route**: `POST /api/github/webhook`, a Relic route in `wonky_server/lib/src/web/`,
  on the web server: the App's webhook URL is `https://wonky.work/api/github/webhook`
  (`api.wonky.work` is the API server and serves no web routes).
  - Before it reads the body it answers from the headers alone: `202` while the integration is
    disabled, `401` without the webhook secret or a `sha256=` `X-Hub-Signature-256` header,
    `400` without `X-GitHub-Event`/`X-GitHub-Delivery`, `413` for a declared size over 5 MB.
    Bodies are read up to 5 MB (GitHub's events used here are tens of KB).
  - It verifies `X-Hub-Signature-256` (HMAC-SHA256 with the webhook secret, constant-time
    compare) and rejects anything else with `401`.
  - It deduplicates on `X-GitHub-Delivery` (table `board_github_delivery`, purged after 7 days).
  - It answers `202` at once; the work runs in `BoardGithubFutureCall.handle(deliveryId)`. A
    delivery still unhandled after 30 minutes (its scheduling failed, or the instance stopped)
    is scheduled again by the sweep (`BoardGithub.rescheduleLost`; each pass counts as an
    attempt, so a failing one is dropped after 3).
- **Client**: `platform/board/github/github_client.dart`, a small REST client with only the calls
  needed:
  - check runs (create, update);
  - issue comments (create, update by id);
  - labels;
  - close PR;
  - PR files and diff;
  - compare commits;
  - org membership.

  It is rate-limit aware (it honors `x-ratelimit-reset`).

### 13.4 Gate: check "Wonky task"

Runs on `pull_request` `opened`, `edited`, `reopened`, `synchronize` and `ready_for_review`, and on
a check re-run:

| Situation | Conclusion | Effect |
|-----------|-----------|--------|
| Author is a member of `board.github.maintainerOrg` | success, *Maintainer PR* | If a `Wonky-Task` line is present, the task is linked (no claim code needed) |
| No `Wonky-Task` line, or more than one | failure | Bot comment: how to claim a task and add the lines |
| Task doesn't exist, or is `draft`/`cancelled`/`done`/`shipped` | failure | Bot comment names the problem and links *Up for grabs* |
| Task linked to another open PR | failure | Bot comment links that PR |
| Claim code missing, wrong, or the claim expired before this PR passed the gate | failure | Bot comment: claim (or re-claim) the task, then update the code. Codes are compared in constant time and never echoed back |
| Everything matches | success | Task → `inReview`, linked to the PR (`prNumber`, `prAuthorLogin`); the claim stops expiring; the author's login is saved on their `BoardUserProfile`; system activity row *PR #345 opened*; the review starts (§13.5) |

- **One bot comment per PR**, found by a hidden marker (`<!-- wonky-task-gate -->`) and updated
  in place. On success it becomes a one-line confirmation with a link to the task.
- The label `wonky-task-missing` is set while the gate fails.
- **Branch protection**: `Wonky task` is a required check on `main`, so a failing PR cannot be
  merged. Maintainers pass the check, so they are not blocked. The `main` ruleset (repository
  admins bypass it) also requires `analyze`, `format`, `dependencies`, `server` and *All tests*
  (15 §10), allows squash merges only and keeps a linear history; `deploy` has no rules. A PR
  need not be up to date with `main` to merge (many PRs land at once; CI on `main` after each
  merge catches the rare clash). A merge queue would need the workflows on `merge_group` and
  *Wonky task* reported for queued merges.
- **Auto-close (G1)**: the sweep (`wonky.boardSweep`) closes PRs whose gate has failed
  continuously for `board.github.autoCloseDays` (7) days, counted from `gateFirstFailedAt`. It
  issues a closing comment, and reopening the PR re-runs the gate.
- If the description is edited after success so that the lines no longer match, the check fails
  again. The task stays linked until the PR is closed or an admin unlinks it.

### 13.5 Review: check "Wonky task review"

- **When**: after the gate passes (also for maintainer PRs that name a task), and again when the
  head commit changes.
  - Debounced by 2 minutes: the latest SHA wins and superseded runs are cancelled.
  - At most `board.github.reviewsPerPrPerDay` (10) runs per PR per day.
  - Maintainers re-run it from the check's *Re-run* button.
- **Facts computed in code** (not by AI), passed to the model and shown in the comment:
  - changed files with line counts;
  - whether tests changed (`test/`, `integration_test/`);
  - whether `specs/` changed;
  - new or changed dependencies (`pubspec.yaml`);
  - migrations added;
  - workflow or tooling changes (`.github/`, `tool/`);
  - security-sensitive paths (`platform/users`, `sharing`, `files`, `mcp`, `board/github`,
    `server.dart`).
- **Input to Gemini** (`board.ai.geminiModel`, tool `report_review`):
  - the task's published prompt (with the acceptance criteria) and the issue summaries;
  - the PR title and body;
  - the facts;
  - the unified diff without generated and binary files (`wonky_client/**`, `**/generated/**`,
    goldens and images, lockfiles), truncated at `board.github.maxDiffTokens` (400k) with the
    truncated files listed.

  All PR content is delimited untrusted data. The model is told not to follow instructions found
  in it.
- **Output schema**:

  ```yaml
  criteria: [{criterion, verdict: met|partly|notMet|cantTell, evidence: [{path, lines?}], note}]
  unrelatedChanges: [{path, note}]       # scope creep: changes the task didn't ask for
  tests: {verdict: added|missing|notNeeded, note}
  specs: {verdict: updated|missing|notNeeded, note}
  risks: [{kind: security|dataLoss|migration|dependency|workflow, path, note}]
  summary: String
  ```
- **Result**:
  - one review comment per PR (marker `<!-- wonky-task-review -->`), updated in place: a
    criteria table, scope notes, tests and specs, risks, and the reviewed SHA;
  - the check run *Wonky task review* with the summary;
  - the result is also stored on the PR row and shown on the task page.
- **Screenshot (T-16)**: when the task's prompt asks for a screenshot (§10.1), the review checks
  the PR description in code, never with AI: an image is a Markdown `![alt](url)` or
  `![alt][ref]`, or an HTML `<img src=…>` (what GitHub writes for a pasted or dropped image);
  code blocks, inline code and HTML comments don't count, and images are never downloaded or
  analyzed (`PrScreenshot`). Without one the check **fails** (`failure`, title *Screenshot
  missing · …*), whatever the AI found and also when the AI review is postponed, failed or not
  configured, and the review comment starts with "**Screenshot missing.** This task changes the
  UI: add a screenshot of the updated UI to the pull request description…". With one the comment
  notes it and the conclusion is as below. The state (`notRequired`, `present`, `missing`) is
  stored in the review JSON (`screenshot`); editing the description so that it changes reviews
  the same commit again (the gate's `edited` run passes the body to `GithubReview.schedule`), so
  adding the screenshot clears the failure without a new commit.
- **Advisory (G5)**: apart from a missing screenshot, the conclusion is always `neutral` while
  `board.github.reviewBlocking` is false. A later switch to blocking would fail only on a `notMet` criterion or major unrelated
  changes, after a trial period in which admins compare the verdicts with their own reviews.
  - The normal CI (analyze, format, tests) stays the hard gate.
  - The server **never checks out, builds or runs PR code**; it only reads the diff through the
    API.

### 13.6 Lifecycle

| GitHub event | Board effect |
|--------------|--------------|
| PR merged (linked) | Task and its issues → `done`; `mergeCommitSha` stored; voters get `boardStatus` (*Built: …*) |
| PR closed without merge (linked) | Task → `published`; claim and code cleared; the claimant gets `boardClaim` (*Your PR was closed; T-12 is open again*); system activity row |
| PR reopened | The gate re-runs. The old claim code is invalid, so the contributor claims again if the task is still free |
| `workflow_run` completed with success, for `board.github.deployWorkflow` (`deploy.yml`) | **Shipped (G7)**: for each `done` task with a merge SHA, the compare API (`merge…deployed head`) shows whether the deploy contains it. If so: task and issues → `shipped`, `shippedAt` and the deploy SHA stored, and voters get `boardStatus` (*Now live on wonky.work*) |

- `board.linkPullRequest` and `board.markDone` stay as admin actions, for when the App is down or
  a PR was opened before the integration existed.
- `board.markShipped` stays for deploys that don't go through the workflow.

**Implementation notes (BI-11, BI-12; setup steps in
`wonky_server/lib/src/platform/board/github/README.md`):**

- The route stores only the payload fields the handler needs (`board_github_delivery.payload`,
  cleared once handled); failed handling is retried twice.
- The App also needs *Organization → Members: read* for the exemption check.
- Exactly one line of each: two `Wonky-Task` lines fail even when equal. Lines inside HTML
  comments (the PR template's hints) are ignored. A task an admin linked to this PR without a
  claim passes without a code. Draft tasks read as *doesn't exist*.
- Activity rows: `prLinked` (gate link), `done` (merge), `prClosed` (closed unmerged),
  `shipped` (deploy); the body is the PR URL or the deploy SHA.
- Review: pending SHA and due time on the PR row (`reviewPendingSha`, `reviewDueAt`); a
  review over the daily limit or the AI budget is postponed to the next UTC day and run by the
  sweep; draft PRs are reviewed once ready. Blocking mode treats unrelated changes over 200
  changed lines as major. `BoardTaskView.reviewJson` holds the result, the facts and the SHA.

### 13.7 Security notes

- Webhooks are authenticated only by the HMAC signature. Replays are dropped by the delivery id.
- The App has the minimum permissions listed and access to one repository. Its private key is a
  password and never logged.
- A claim code is 8 random characters from the Crockford base32 alphabet (digits and letters
  without I, L, O, U), formatted `XXXX-XXXX` (40 bits).
  It is per claim, stored server-side only (`serverOnly`), returned only to the claimant, and
  rotated on every new claim. Guessing is bounded by the gate's per-PR re-run limit and the
  claim's lifetime.
- PR text and diffs are untrusted in both the gate (parsing only) and the review (delimited data,
  schema output, advisory).

## 14. Commands and MCP

**MCP** ([09](09-mcp.md)): new scope `board` (read and write in one, like `ui:control`), with
tools defined in `packages/wonky_core/lib/mcp/board_tools.dart` and handlers in
`platform/mcp/board_tool_handlers.dart`:

- `board.list_posts` (with a `query` for search), `board.get_post`, `board.list_tasks`;
- `board.get_task`, which returns the issues and the claim state, and for the claimant the full
  prompt (with their claim code in its PR lines), the claim code and the two PR lines, so a
  contributor's agent can claim the task, fetch it by number and fill in the PR description.
  Admins get the prompt with the placeholder; everyone else no `prompt` key (§8.1);
- `board.create_post` (no screenshot), `board.vote`, `board.comment` (issues only:
  `post_number` is required; tasks have no discussion), `board.claim_task`,
  `board.release_task`;
- admin tools (P1, not built): `board.moderate`, `board.create_task`, `board.set_prompt`,
  `board.publish_task`.

The tools are read and write in one scope and are not offered to the in-app assistant
([10](10-ai-assistant.md)). Tests: `wonky_server/test/integration/platform/board/board_mcp_tools_test.dart`.

**Commands** (`shell.board.*`, catalog in [08 §5](08-commands-and-undo.md)):

| Id | Undoable |
|----|----------|
| `report {kind?}` | – (opens the dialog) |
| `open {tab?}` | – |
| `createPost {kind, title, body, contextJson?, appHint?, screenshotFileUuid?}` | ✓ (undo: delete own issue, redo restores it) |
| `editPost` | ✓ |
| `deletePost` | ✓ |
| `vote {postNumber, value}` | ✓ |
| `comment.add` (issues only) / `comment.edit` / `comment.delete` | ✓ |
| `flag` | ✓ |
| `claim` / `release` (*Unclaim this task*, Lucide `ban`) | ✓ |
| `copyClaimCode` | – |
| `copyPrompt` (fails with *Claim this task to get the prompt.* without one) | – |
| `removeScreenshot` | – (the bytes are deleted at once; confirmed) |
| `admin.moderate` / `admin.setLabels` / `admin.editPost` (*Edit and approve*) / `admin.applySuggestedTitle` / `admin.merge` / `admin.unmerge` / `admin.decline` / `admin.reopen` / `admin.block` / `admin.createTask` / `admin.updateTask` / `admin.setTaskPosts` / `admin.mergeTasks` (undo: `unmergeTasks`, §9.3) / `admin.regeneratePrompt` / `admin.setPrompt` / `admin.publishTask` / `admin.linkPullRequest` / `admin.markDone` / `admin.markShipped` / `admin.cancelTask` | ✓ (inverse calls, §9.2) |
| `admin.createTask {postNumbers, title?, area?, size?, excludedComments?}` (T-10: the dialog's unchecked comments, §9.3) | ✓ (undo cancels, redo creates it again with the same comments left out) |
| `admin.suggestBundles` / `admin.dismissSuggestion` / `admin.dismissDuplicate` (*Not a duplicate*) | – (no server inverse) |

**As built (BI-2…BI-6):** all ids above are registered in `board_commands.dart`
(`boardCommands`) and `report_commands.dart` (`report`, `open`, `createPost`; the report dialog
issues through `createPost`).

All have `requiredRole: viewer`, because the board is not a document. Admin commands are
registered for everyone but disabled (`enabled: false`) unless `board.me().isAdmin`.
Admin command ids are `shell.board.admin.<name>`. The undo entries (`BoardUndoEntry`, domain
`board`, shell stack) record what the inverse needs: the previous vote, title and body, labels,
moderation state (approve ↔ hold, remove ↔ restore), prompt body or task status. Undoing
`createTask` cancels the draft; redo creates a new one. Undoing `regeneratePrompt` sets the body
from before (dropping a pending AI pass); redo asks the AI again. Undoing `release` re-claims only the
caller's own claim, and undoing `cancelTask` of a claimed task publishes it (the claim is gone).
A `notFound`/`conflict` answer makes the step partial (`UndoConflict`).

## 15. Testing

Following [15](15-writing-tests.md):

- **As built:** server tests in `wonky_server/test/integration/platform/board/` (pure logic in `test/unit/board/`) (`board_access_test`,
  `board_posts_test`, `board_votes_test`, `board_comments_test`, `board_tasks_test`,
  `board_triage_test`, `board_lifecycle_test`, `board_mcp_tools_test`, `ai/`, `github/`, with
  `support/board_harness.dart` and `support/fake_board_ai.dart`; the live evaluation set is
  `ai/eval/`, tag `live-ai`). Client tests in `packages/wonky_app/test/board/`
  (`commands/`, `pages/`, `report/`, `screenshot/`), `test/markdown/` and
  `test/comments/comment_thread_body_test.dart`. Light/dark goldens of the dialog, row, issue page
  and editor are not written yet, and J-B1 is a browser walkthrough plus these suites (§17).
- **Server** (`wonky_server/test/integration/platform/board/`, `test/unit/board/`, `withServerpod`, `FakeJevClient`,
  `FakeAiModelClient` for Gemini, fixed clock):
  - endpoint access matrix (§7.1) for signed out, signed in, author, admin and blocked users;
  - admin detection (domain, list, case, subdomain rejected), plus the guard test for email
    change and Google verification (§9.1);
  - triage pipeline (bands per decision, kind correction, labels left empty at low confidence,
    inline vs. background path, unchecked, retries then publish or hold, budgets);
  - board AI isolation: no call ever uses in-app keys or writes `ai_usage`, and the in-app AI
    never uses the internal keys;
  - `JevClient` against recorded HTTP fixtures (success, 429 with `retry-after`, 529, 401, 422);
  - similar-post search ranking;
  - votes (idempotency, down votes rejected on bugs, scores, merge vote move and undo);
  - claims (limit, conflict, expiry computed on read, the sweep job, warning once);
  - rate limits;
  - GitHub (`test/integration/platform/board/github/`, `test/unit/board/github/`, recorded webhook payloads in `test/fixtures/github/` and a fake GitHub API):
    signature check, delivery dedupe, every gate row in §13.4, maintainer exemption, bot comment
    updated in place, auto-close after 7 days, review debounce and daily limit, the review comment
    rendered from a fake Gemini result, merged → done, closed → released, deploy → shipped only
    for included commits;
  - screenshot upload (sniffing, size, no quota charge, cleanup of unattached files);
  - notifications per kind;
  - account deletion.
- **wonky_app**:
  - command tests (undo/redo) for every `shell.board.*` command;
  - widget tests for the dialog (similar issues, draft, signed-out redirect), the board list
    (filters, sort, vote control, keyboard), the issue page, the task page (claim states) and the
    review tab;
  - the screenshot editor (tools, local undo, flattening covers pixels: the covered region of
    the output is uniform);
  - `WonkyMarkdown` profiles and link schemes;
  - `CommentThreadBody` with both action implementations;
  - goldens light/dark for the dialog, row, issue page and editor.
- **Router**: `/improvements*` is reachable signed out; other routes still redirect.
- **MCP**: tool tests for `board.*`.
- **Triage evaluation set** (`wonky_server/test/integration/platform/board/ai/eval/`, tag `live-ai`, not in CI):
  about 200 labeled issues (real-looking bugs and ideas, rude-but-fine, offensive, spam, personal
  data, security reports, duplicates, adversarial self-classifying issues). Runs against the pinned
  Jev model, also with reversed Choice option order, and reports precision and recall per
  decision. Used to tune the thresholds and before every model upgrade.
- **E2E journey J-B1**:
  1. sign in;
  2. open the dialog from the Sheets editor;
  3. add a screenshot and cover an area;
  4. see a similar issue and post anyway;
  5. the issue appears as visible (fake triage);
  6. a second user votes and comments;
  7. an admin (`@serverpod.dev` test account in the `e2eSupport` allowlist) selects it, edits
     and publishes the prompt;
  8. the second user claims and sees the claim code;
  9. a recorded `pull_request` webhook with the code links the PR; a recorded merge marks it done;
  10. the voter gets the notification.

## 16. Implementation plan (M12)

**Status:** BI-1…BI-9, BI-11 and BI-12 are built. BI-8 (the contribution kit) is in the
repository root and `.github/`. BI-10 (P1) is not built (§17). Work packages for parallel agents ([14 §1](14-roadmap.md) principles: contract first, ownership by
folder). Package BI-1 lands first; then BI-2…BI-6 run in parallel; BI-7…BI-9 follow. Step 2
(BI-11, BI-12, the GitHub side) starts once the board is live; until then admins link PRs by hand.

| WP | Scope | Main paths | Depends on |
|----|-------|-----------|------------|
| **BI-1 Contract** | Models (§12), migration, `BoardEndpoint` with stub methods, `BoardConfig`, `BoardAdmins`, `config.json` `board` flag, `NotificationKind` values, `StoredFileKind.boardScreenshot`, MCP tool definitions, command ids registered as stubs | `wonky_server/lib/src/platform/board/`, `wonky_core/lib/mcp/board_tools.dart`, `wonky_app/lib/src/board/board_commands.dart` | — |
| **BI-2 Server core** | Issues, votes, comments, flags, similar search, screenshots, rate limiter extraction, blocks, merge, notifications, retention, account deletion, live channels | `platform/board/`, `platform/common/rate_limiter.dart`, `platform/files/` | BI-1 |
| **BI-3 Board AI** | `JevClient`, `BoardGemini`, usage table and budgets, triage questions and bands, inline + background pipeline, comment checks, Jev rerank, summaries, bundle suggestions, task prompt generation + template, spec index generator, evaluation set | `platform/board/ai/`, `platform/board/triage/`, `platform/board/prompts/`, `tool/spec_index.dart` | BI-1 |
| **BI-4 Shared UI pieces** | `WonkyMarkdown` (from `AssistantMarkdown`), `MarkdownComposer`, `CommentThreadActions` refactor (document comments unchanged + Markdown rendering), lightbox move from Write, ink move from Slides to `wonky_ui`, screenshot capture helper | `wonky_app/lib/src/{markdown,comments,assistant,mcp_bridge}/`, `wonky_ui/lib/src/ink/`, `wonky_write/.../lightbox`, `wonky_slides/.../present` | — (parallel with BI-1) |
| **BI-5 Report dialog & editor** | Dialog (§4.2), similar issues, drafts, included details, screenshot editor (§5.2), entry-point replacements (§4.1), alias commands, error card button | `wonky_app/lib/src/board/report/`, `shell/`, `menus/`, `drive/home_sidebar.dart`, `editor/editor_scaffold.dart`, `auth/` | BI-1, BI-4 |
| **BI-6 Board pages** | Routes + public redirect, server route `/improvements/*` → `/drive/improvements/*`, board list, issue page, task page, contribute page, review tab, admin actions, undo for every command | `wonky_app/lib/src/board/pages/`, `routing/router.dart`, `wonky_server/lib/src/web/` | BI-1, BI-4 |
| **BI-7 Tasks & claims** | Claim/release/extend, expiry sweep job, PR linking, done/shipped, task notifications | `platform/board/tasks/`, `platform/jobs/`, `server.dart` `_jobs` | BI-2 |
| **BI-8 Contribution kit** | `CONTRIBUTING.md`, `passwords.example.yaml`, PR template, issue template `config.yml`, `SECURITY.md` (`LICENSE` is already added), (P1) embedded development database | repo root, `.github/`, `wonky_server/config/` | — |
| **BI-9 MCP, E2E, specs** | `board.*` MCP handlers, J-B1, spec updates listed below, fold-in of feedback (§12) | `platform/mcp/`, `wonky_server/test/e2e/`, `specs/` | BI-2…BI-7 |
| **BI-10 (P1)** | Image file attachment, error reports view, legacy feedback view, claim extension, reactions, `CodeView` in Markdown; P2: Jev screenshot check once Jev images are production-ready | various | BI-9 |
| **BI-11 GitHub gate & lifecycle** (step 2) | GitHub App setup (documented in `platform/board/github/README.md`), webhook route + signature + dedupe, `GithubClient`, gate check and bot comment, branch protection, auto-close in the sweep, merged/closed/reopened handling, shipped on deploy, claim codes in UI and MCP | `platform/board/github/`, `wonky_server/lib/src/web/`, `wonky_app/lib/src/board/pages/` | BI-7 |
| **BI-12 PR review** (step 2) | Facts in code, diff filtering and truncation, Gemini `report_review`, review comment and check, debounce and limits, review on the task page | `platform/board/github/review/` | BI-3, BI-11 |

**Spec updates when built (BI-9):**

- [03](03-app-shell-and-navigation.md) §3.2, §3.3 (left menu), §3.4 (replaced by a pointer to
  this spec), and the public routes in the routing section;
- [04](04-auth-and-accounts.md): the About section;
- [07](07-collaboration.md) §2.3 (Markdown rendering, `CommentThreadActions`) and §4 (notification
  kinds and the `board` category);
- [08](08-commands-and-undo.md) §5 (the `shell.board.*` row; `reportBug`/`feedback` as aliases);
- [09](09-mcp.md) (the `board` scope and tools);
- [10](10-ai-assistant.md) (a pointer to the board AI: separate keys and budgets, Jev and Gemini);
- [11](11-quality-testing-accessibility.md) (J-B1; error reports);
- [13](13-security-and-operations.md) §1 and §2 (rows from §11 above; the GitHub webhook route; the new passwords);
- [Drive 03](wonky_drive/03-storage-quota.md) (the exempt kind);
- the app specs' Help menu rows (Write 05, Sheets 04, Slides 04, Drive 04).

**Exit criteria**: J-B1 green; the server access matrix fully tested; document comments
unchanged apart from Markdown rendering (existing suites green); light/dark goldens; the
signed-out board loads in the release build; `CONTRIBUTING.md` verified by a fresh-clone dry run
on a clean machine (an agent following it end to end); the triage evaluation set meets the agreed
precision for `offensive` and `security`. Step 2 (BI-11, BI-12): a real PR from a non-member fork
passes the gate with a claim code and gets a review; a PR without one fails and is auto-closed in
a time-shifted test.

## 17. Open items after M12

Built but not complete, found in the code:

- **Admin: *Remove all issues by this user*** (§9.2) is not built. *Block user* is.
- **`board.extendClaim`** (§8.1, P1) is not built; a claim cannot be extended.
- **Flagging a comment** (§7.5): the endpoint (`flag`, `unflag`) and `shell.board.flag` (`commentUuid`) accept a
  comment target, but the comment thread UI has no *Flag* action yet. Issues can be flagged from
  the issue page.
- **`reviewQueue(section)` has no paging**: it returns a whole section.
- **`similar()` is not rate-limited for signed-out callers** (§11 limit applies to signed-in
  users only).
- **Gemini thinking tokens** are not counted in `board_ai_usage` or the daily budget (only the
  reported input and output tokens are).
- **P1 from BI-10:** image file attachment, the *Error reports* and *Legacy feedback* views,
  reactions, `CodeView` in Markdown, *Copy setup + prompt*, admin MCP tools (`board.moderate`,
  `board.create_task`, `board.set_prompt`, `board.publish_task`) and a `board.search` tool (search
  is the `query` of `board.list_posts`). P2: the Jev screenshot check.
- **Markdown composer** (§7.3): spelling, copy and cut as Markdown and the focus fix are built
  and covered by widget tests, but not yet checked in the browser (release builds: the first keys
  after a click, IME typing, paste, copy, the spelling menu, the link dialog). A code block's
  language can only be set while typing the fence. The spelling language is the device locale.
- **Goldens** for the dialog, row, issue page and editor, and the fresh-clone dry run of
  `CONTRIBUTING.md`, are not done; the browser walkthrough of J-B1 is tracked in
  [14 §2.1a](14-roadmap.md).
