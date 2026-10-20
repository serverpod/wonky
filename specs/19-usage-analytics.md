# 19 · Usage analytics

First-party usage analytics for the Wonky Work team: how many accounts there are, how many people
use the suite (DAU/WAU/MAU), which apps they use, what they create, how they collaborate, AI and
MCP use, and whether new accounts come back. Aggregates only, no per-person list. Shown on an admin-only page in Wonky Drive
(`/drive/analytics`). Built, October 2026.

## 1. Decisions

| # | Decision | Why |
|---|----------|-----|
| U1 | **First-party, in our own Postgres.** No third-party tracker (PostHog, GA, Plausible…) | The source of truth (accounts, sign-ins, items) is already in the database. Client-side trackers are blocked by ad blockers, conflict with the apps' cross-origin isolation (COOP/COEP, 13 §3), and would need consent banners and a new data processor |
| U2 | **Ids and counts only.** One row per person, UTC day and app; no content, no URLs, no events stream | Data minimization (13 §2) |
| U3 | **Admins only**, with the board's admin rule (16 §9.1: account email in `board.adminEmailDomains` / `board.adminEmails`), checked on the server for every call | One admin notion for the suite |
| U4 | **Tracking starts at deploy**, with no backfill. Accounts, content, comments, shares and AI use come from tables that already have history; activity (DAU/WAU/MAU, apps, retention) starts empty | User decision: exact numbers over reconstructed ones |
| U5 | **Active** = used an app while signed in (app start or resume, opening an item, an edit) or an MCP client with the person's token. A second line, **Created or edited**, counts people who created, uploaded, edited or restored something that day | User decision |
| U6 | **Admins are left out of every count by default**; the page has an *Include admins* switch | The team's own use would distort small numbers |
| U7 | **No per-person list.** The page shows aggregates only | User decision |
| U8 | **Custom lightweight charts in `wonky_drive`**, not the shared chart engine (`wonky_charts_flutter`) | The engine pulls `flutter_scene` (environment map, LUTs, shader bundles) into Drive's bundle, the app everyone lands on, for one admin page |

## 2. Recording (server)

`UsageTracker` (`wonky_server/lib/src/platform/analytics/usage_tracker.dart`) writes:

- **`user_activity_day`** (`UserActivityDay`, `serverOnly`): `userId`, `day` (UTC midnight), `app`
  (`UsageApp`: `drive`, `write`, `sheets`, `slides`, `mcp`), `edited` (bool). Unique per
  (user, day, app); upserted with `ON CONFLICT … edited = edited OR EXCLUDED.edited`.
  `userId` has **no foreign key** on purpose: rows are written beside transactions that may
  lock the profile, and past days' counts stay put when an account is deleted (the row keeps
  only the bare id until it is purged).
- **`usage_counter_day`** (`UsageCounterDay`): daily counters by name; today only
  `mcp.calls`.

Sources:

| Source | Hook | App | Edited |
|--------|------|-----|--------|
| App start and resume (at most every 30 min per app) | `analytics.ping(app)` from the shell's `UsagePing` | the app | — |
| Opening an item (Write document stream, RevLog open, `drive.markOpened`) | `DriveUserStates.recordOpen` | by kind: document → Write, spreadsheet → Sheets, presentation → Slides, folder/file → Drive; MCP actors → `mcp` | — |
| Creating, uploading, restoring a version | `ActivityService.log` (`created`, `uploaded`, `restoredVersion`) | by kind | ✓ |
| Edits | `ActivityService.logEdit` | by kind | ✓ |
| MCP tool calls by a person's token (`ActorKind.mcp`, not the assistant) | `McpToolExecutor.call` | `mcp`, plus `mcp.calls` + 1 | — |

- The assistant's edits (`ActorKind.ai`) count for the person who asked; scripts and the system
  don't count.
- The **welcome content** (the welcome document and spreadsheet every account gets,
  `write.welcome` / `sheets.welcome`) is not counted as created and does not make anyone an
  editor.
- Each instance remembers which (user, day, app) keys it wrote (LRU of 50,000), so the hot paths
  cost a map lookup. Pings, opens and MCP calls also refresh `user_profile.lastSeenAt` (at most
  every 15 min per user). Edits don't, because they can run inside a transaction that locks the
  profile.
- Tracking never fails the request that triggers it: database errors are logged at `warning`.
- **Retention**: rows older than 400 days are deleted by the daily job
  `analytics.purgeActivity` (a year-over-year view of the last 30 days). AI usage has its own
  90 days (`AiUsageService.retentionDays`).

### 2.1 Rollup and indexes

- **`usage_day_stats`** (`UsageDayStats`, `serverOnly`): one row per finished UTC day and
  `includeAdmins` (unique), with active, editors, the five apps, weekly and monthly.
  - The overview computes a missing finished day once from `user_activity_day` and inserts it
    (`ON CONFLICT DO NOTHING`), then reads it from there. Only today is computed live.
  - A finished day never changes, because activity is only written for the current day. The
    rows also outlive the 400-day purge.
  - The admin rule is frozen at the time a day was computed: admins added later still count
    in older days.
  - This keeps the rolling `count(DISTINCT)` windows (days × 30 × daily active users) off the
    request path after the first view.
- **Indexes** for the date-range scans:
  - `user_activity_day` (`day`), and the unique (`userId`, `day`, `app`) for cohorts.
  - `activity_event` (`type`, `at`).
  - `comment` (`createdAt`).
  - `drive_item_permission` (`grantedAt`).
  - `ai_usage` (`at`), which also serves the daily purge.
  - `user_profile` (`createdAt`).
  - `usage_counter_day` (`day`, `name`).
- **Full scans** remain for the "now" totals (items by kind, storage, sign-in methods, shared
  items). They are bounded by the table sizes and covered by the overview cache.

## 3. Dashboard

`AnalyticsEndpoint` (`analytics.*`, sign-in required):

| Method | Who | What |
|--------|-----|------|
| `ping(UsageApp app)` | anyone signed in | records activity (§2) |
| `overview(int days, bool includeAdmins)` | admins | `AnalyticsOverview` for 7, 30, 90 or 365 days ending today (UTC); other periods are `invalidArgument`. Cached for 1 minute per (days, includeAdmins) |

Non-admins get `forbidden`. Aggregates are computed in SQL (`AnalyticsService`).

### 3.1 Page (`/drive/analytics[?days=…&admins=1]`)

- **Access.** An admin-only left-menu destination *Analytics* (`HomeNavItem(adminOnly: true)`)
  below *Storage*, shown when `BoardHub.me.isAdmin`. The command `drive.analytics.show
  {days?, includeAdmins?}` (category *Analytics*) is enabled for admins only. Opened directly by
  someone else, the page shows *Analytics are for admins*.
- **Frame and controls.** The Storage page's frame (top bar, left menu, content card). The header
  has the period (7/30/90/365 days, as tabs; a select below 600 px), *Include admins* and
  *Refresh*, plus the note *Updated hh:mm*, and *Activity recorded since …* when tracking
  started inside the period.
- **Sections:**
  1. **KPIs**: accounts (+ new in period), active today (and how many created or edited),
     weekly active, monthly active, stickiness (average daily active users of the last 30 days
     ÷ MAU) and items created. Sparklines where the measure has a trend.
  2. **Active users**: Daily (Active + *Created or edited*), Weekly and Monthly tabs.
  3. **Active users by app**: Drive, Write, Sheets, Slides and MCP clients (dashed).
  4. **Sign-ups** (bars) beside **Content now** (items by kind, storage) and **Sign-in
     methods** (email / Google).
  5. **Content created**: stacked bars by kind (documents, spreadsheets, presentations, files).
     Counts creations and uploads by people, the assistant and MCP.
  6. **Collaboration**: items shared now, items co-edited by 2+ people in the period,
     commenters, and a chart of comments and shares per day.
  7. **AI assistant**: requests per day, and by feature and by model (requests and tokens).
  8. **MCP tool calls** per day. Admins are always included here, because the counter is not
     per person.
  9. **Retention**: weekly sign-up cohorts (Monday, UTC, last 12 weeks), one cell per week
     since sign-up with the share still active, shaded with the ink. Weeks before tracking
     started are blank.

### 3.2 Charts

`analytics_charts.dart` holds the line chart (crosshair, dots, tooltip), the stacked bars (2 px
gaps, rounded tops, highlight band, tooltip with total), the rank bars, the sparklines and the
legend (a click hides a series). Charts follow the dataviz rules:

- 2 px lines and 4 px rounded data ends.
- Recessive gridlines.
- Text in text tokens.
- A legend for two or more series.
- Bars daily up to 90 days, weekly beyond (the last bar ends today).
- Every card can switch to a **table view**.

Colors (`AnalyticsColors`):

- The apps keep the drive kind colors: Write blue `#2563eb`, Sheets green `#16a34a`, Slides
  amber `#d97706`.
- Drive is pink (`#db2777` / dark `#ec4899`) and MCP cyan `#0891b2`. Drive's violet can't be
  told from blue with deuteranopia.
- Other measures use the ink and violet (`#7c3aed` / `#a78bfa`).

The palette was validated for color vision deficiency in light and dark. The worst pair is
ΔE 6.1, in the floor band, so series are always named in legends and tooltips.

## 4. Privacy

13 §2 lists it: activity rows hold a user id, a day, an app and a flag, kept 400 days. The page
shows aggregates only. The privacy policy (`/privacy`)
names it under *What we collect › Usage data* and *How we use it* (aggregate statistics for the
team).

## 5. Tests

- **Server** (`test/integration/platform/analytics/analytics_endpoint_test.dart`):
  - Permissions and period validation.
  - Ping dedupe, per-app counts and admins left out or included.
  - Creation makes an editor, and the welcome content is excluded.
  - Rolling 7/30-day windows, MCP calls, shares and cohorts.
  - Finished days read from the rollup, purge after 400 days, scripts not counting.
  - The test database is shared and not rolled back. Each test therefore works under a fixed
    clock in a far-future 500-day window of its own, and clears that window first. People are
    created with the real clock (unique emails) and then signed up inside the window.
- **Drive** (`test/features/analytics/`):
  - Left menu for admins and non-admins, the forbidden state.
  - Period and switch through the command and route.
  - Hover tooltip, table view and the Monthly tab.
  - Dark, 360 px and the pseudo-locale.
  - The bucketing helpers.

## 6. Later

- MCP calls per person, so *Include admins* applies to them too.
- Funnels (signed up → created → shared) and per-command feature usage: commands are the one
  place every action passes (08), so counting command ids per day would need no client tracker.
- Rollups for the other per-day series (sign-ups, content, comments, shares, AI) if their
  indexed range scans get slow.
