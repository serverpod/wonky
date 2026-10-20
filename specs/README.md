# Wonky Work — Specifications

Specifications for **Wonky Work** (v2: four apps), a collaborative office suite built with
Flutter and Serverpod — **v2 targets the web only** (desktop builds keep compiling, desktop
features are deferred, [01 A13](01-architecture.md)): **Wonky Drive** (the unified drive: all files, uploads,
storage), **Wonky Write** (Markdown-first documents), **Wonky Sheets** (offline-first
spreadsheets) and **Wonky Slides** (presentations with animations, code blocks and linked
charts).

- Suite-level specs (shared by all apps) live here in `/specs`.
- App specs live in [`/specs/wonky_drive`](wonky_drive/README.md),
  [`/specs/wonky_write`](wonky_write/README.md),
  [`/specs/wonky_sheets`](wonky_sheets/README.md) and
  [`/specs/wonky_slides`](wonky_slides/README.md).
- **v2 review**: the decisions on the 30 review questions of the Drive/Slides/suite v2 specs
  are recorded in [v2-review.md](v2-review.md); v2 is specified and planned as work packages
  ([14](14-roadmap.md), [Drive 05](wonky_drive/05-implementation-plan.md),
  [Slides 12](wonky_slides/12-implementation-plan.md)), not implemented.
- Code: `wonky_server` (Serverpod server, also serves all four web apps), `wonky_client`
  (generated), the apps `wonky_drive`, `wonky_write`, `wonky_sheets` and `wonky_slides`, shared
  packages in `packages/`, vendored packages in `third_party/` — see [01 §2](01-architecture.md).
- **v2 changes** (milestones M8–M11, [14](14-roadmap.md)) are marked "(v2)" in the suite
  specs: the unified drive and app homes, the 50 MB storage quota, the settings split, *Report a
  bug*, Wonky Slides, and the shared packages (`wonky_charts*`, `wonky_code*`, `wonky_numfmt`,
  `wonky_rich_text`, `wonky_fonts`, `wonky_spellcheck`, `wonky_sync_kit*`, which M13 replaces
  with `wonky_revlog*`).

## Reading order

1. [00 · Product overview](00-product-overview.md) — vision, scope, glossary.
2. [01 · Architecture](01-architecture.md) — decisions, repo layout (current state and the M0
   steps to the target), package dependency rules, serving the four web apps, shared sign-in,
   server/client structure.
3. [08 · Commands and undo](08-commands-and-undo.md) — the backbone: every action is a command;
   undo for everything; how MCP and AI plug in.
4. [12 · Offline and sync](12-offline-and-sync.md) — Write OT, local storage, offline behavior;
   then [17 · RevLog sync](17-revlog-sync.md), the op log Sheets and Slides sync through.
5. [15 · Writing tests](15-writing-tests.md) — before writing the first test.
6. [05 · Drive & files](05-drive-and-files.md) and [Drive 03 · Storage quota](wonky_drive/03-storage-quota.md)
   (v2) — the unified drive, app homes and the rules every byte-adding feature must follow.
7. Then the app specs, then the remaining suite specs as needed.

## App specs

| App | Folder | Start with |
|-----|--------|-----------|
| Wonky Drive (v2) | [`wonky_drive/`](wonky_drive/README.md) | [01 · Overview](wonky_drive/01-overview.md) |
| Wonky Write | [`wonky_write/`](wonky_write/README.md) | [01 · Overview](wonky_write/01-overview.md) |
| Wonky Sheets | [`wonky_sheets/`](wonky_sheets/README.md) | [01 · Overview](wonky_sheets/01-overview.md), [STATUS](wonky_sheets/STATUS.md) |
| Wonky Slides (v2) | [`wonky_slides/`](wonky_slides/01-overview.md) | [01 · Overview](wonky_slides/01-overview.md) |

## Suite specs

| # | Spec | Summary |
|---|------|---------|
| 00 | [Product overview](00-product-overview.md) | Vision, principles, personas, scope/non-goals, glossary |
| 01 | [Architecture](01-architecture.md) | One server, four Flutter apps served from it, shared sign-in, pure-Dart cores, shared chart/code packages, package layout & rules |
| 02 | [Design system](02-design-system.md) | `shad` usage, tokens, light/dark, custom widgets (`wonky_ui`) |
| 03 | [App shell & navigation](03-app-shell-and-navigation.md) | Single-window model (no presenting exception in v2), routes, homes and the left menu, editor header, shared menus, Bugs & improvements entry (was Report a bug), overlays, desktop specifics |
| 04 | [Auth & accounts](04-auth-and-accounts.md) | Email/password + Google auth, profile, preferences, settings split (Wonky Work vs app settings), access tokens |
| 05 | [Drive & files](05-drive-and-files.md) | Unified drive model (folders, documents, spreadsheets, presentations, files), endpoints, app homes vs Wonky Drive, dialogs, activity |
| 06 | [Sharing & permissions](06-sharing-and-permissions.md) | Roles, ACL, link sharing, enforcement (documents, spreadsheets, presentations, files), share dialog |
| 07 | [Collaboration](07-collaboration.md) | Presence, comments, mentions, notifications, version history framework |
| 08 | [Commands & undo](08-commands-and-undo.md) | Command model, keymap, command palette, undo architecture |
| 09 | [MCP](09-mcp.md) | Server MCP endpoint, auth, headless tools, UI bridge |
| 10 | [AI assistant](10-ai-assistant.md) | Claude integration (server-side), assistant panel, inline AI |
| 11 | [Quality](11-quality-testing-accessibility.md) | Testing, performance budgets, accessibility, i18n, observability |
| 12 | [Offline & sync](12-offline-and-sync.md) | Local stores, Write offline, Sheets/Slides on RevLog (summary), upload queue, scale limits |
| 13 | [Security & operations](13-security-and-operations.md) | Threat model, privacy, deployment, scheduled jobs, arbitrary uploads |
| 14 | [Roadmap](14-roadmap.md) | Milestones M0–M14 (v2: M8 Drive + suite changes, M9–M11 Slides; M12 Bugs & improvements; M13 RevLog; M14 Publications), how parallel agents execute the work packages, shared workstreams, risks |
| 15 | [Writing tests](15-writing-tests.md) | How to write tests: layout, naming, helpers, server/widget/golden/property/E2E patterns, determinism, running |
| 16 | [Bugs & improvements](16-bugs-and-improvements.md) | Public board for bug reports and improvement ideas: report dialog with annotated screenshots, votes, comments, AI triage and moderation, admins, tasks with contributor prompts, claims, GitHub PR rules (M12, built) |
| 17 | [RevLog sync](17-revlog-sync.md) | Server-sequenced op log of Sheets and Slides: decisions, data model, change sets and apply rules, protocol, server (sequencer, hooks, pages, headless cache), client (cache, outbox, bootstrap, conflicts), performance gates, as-built notes (M13) |
| 18 | [Publications & submissions](18-publications-and-submissions.md) | Blogs register a publication; contributors write in Wonky Write and *Submit* to the blog's review queue (signed webhooks, publication API, moderators with comment access, feedback in the document) (M14, built) |

## Conventions used in all specs

- **Command ids**: `shell.<area>.<action>`, `drive.<area>.<action>`, `write.<area>.<action>`,
  `sheets.<area>.<action>`, `slides.<area>.<action>` — stable public API (menus, shortcuts, MCP
  `ui.invoke_command`).
- **MCP tool names**: `namespace.verb_noun` snake_case (`drive.search`, `write.insert_markdown`,
  `sheets.set_values`, `slides.add_slide`, `ui.invoke_command`).
- **Shortcuts**: `Mod` = ⌘ on macOS, Ctrl elsewhere. Browser-reserved shortcuts are never bound.
- **Priorities**: P0 = required for v1, P1 = v1 if possible, P2 = later.
- **Models** are shown as Serverpod `.spy.yaml` sketches. The Sheets and Slides domain tables
  are server tables (`serverOnly: true`) whose rows sync through RevLog ([17](17-revlog-sync.md)).
- **(v2)** marks sections added or changed for the second iteration (Drive, Slides, suite
  changes). **Decided (v2 review, Qn)** marks a choice settled in the [v2 review](v2-review.md).
  New choices that need the user are marked **Open question (for review)**, always with a
  recommendation, and added to the review record.
- Specs describe *what* and *how*; when implementation reveals a better approach, update the
  spec in the same change.
