# 03 · App Shell, Navigation and the Single-Window Model

The **app shell** (`packages/wonky_app`) is the shared frame every Flutter app runs inside
(v2: Drive, Write, Sheets, Slides): bootstrapping, auth gate, routing, top-level layout, homes
and their left menu, overlays (dialogs, toasts, command palette), connectivity, presence
plumbing, MCP UI bridge, storage meter and settings. Each app provides a `WonkyAppConfig`
(name, logo — the product icon, [02 §5](02-design-system.md) — primary file kind, routes,
commands, menus, editor screen builder; (v2) `homeScope`, `homeNav`, `appSettingsSections`,
`newItemRoute`/`importRoute` — §3.3, 04 §4).

## 1. Single-window rule

- The app **never** opens a new browser tab/window or OS window: no `window.open`, no
  `url_launcher` with `_blank` for internal content, no multi-window desktop APIs, no Window
  Management API.
- Opening a document replaces the current route in the same window. Switching between the
  apps (Drive, Write, Sheets, Slides — the left menu of every home, §3.3, and the account menu)
  is a same-window navigation (web: same tab, full page load to the other app's base path;
  desktop: see §6).
- External links (in documents, help, the *Report a bug* GitHub fallback §3.4) open in the system browser only
  after a confirm popover ("Open external link? example.com — Open / Copy link"). On desktop
  this launches the OS browser (that's an external app, not a Wonky window); on web it is a new
  browser tab (`url_launcher` with `_blank`, external content only).
- **Exception: Sign in with Google** (web, [04 §1.6](04-auth-and-accounts.md)) runs Google's
  consent page in a short-lived, named OAuth popup that closes itself after `/auth/callback`
  hands the result back. It is Google's page, not Wonky content.
- **(v2) No exception for presenting.** Slides presents in the same window (full screen, or the
  presenter view with current/next slide, notes and timer); the audience view for a projector
  runs on **another device or browser** joined to the deck's presentation session
  ([Slides 10 §5](wonky_slides/10-presenting-and-pdf.md)). Joining a session in a second
  browser is the user's own navigation, not a window the app opens.
- Dialogs, pickers, previews (print preview, export preview, version compare, (v2) Drive file
  previews) are in-app overlays or full-screen in-app routes with a back/close affordance.
  Full-screen pages such as Settings and Bugs & improvements share one page frame
  (`ShellPageFrame`: a 56 px bar with back, the app logo, the title, actions and the account
  menu). A page can put its own navigation in place of back, logo and title: the board shows a
  breadcrumb whose app icon closes it ([16 §4.3](16-bugs-and-improvements.md)).
- **Quick switcher** (`Mod+O`): dialog listing recent files of every kind (v2: incl.
  presentations and uploaded files) + search; Enter opens in the same window (other kinds
  navigate to their app; files open Drive's preview).
- **Back/forward**: browser history (web) and `Mod+[` / `Mod+]` (desktop, deferred) navigate
  between previously opened files and drive locations. Moves that stay at the same depth of a page
  hierarchy (the board's tabs and sibling posts) replace the history entry instead of adding one
  (`ShellServices.goReplacing`).
- Multi-tab browsing of the *same* app is allowed by the browser, but the app itself is designed
  as one window; two windows of the same user simply appear as two sessions (presence shows
  "You (2 tabs)").

**Decided (v2 review, Q5/Q29, D12): no second window in v2.** Presenting is single-window:
(a) *Present* (full screen in this window), (b) *Presenter view* in this window (current/next
slide, notes, timer) and (c) the **audience view on another device or browser** joined to a
**presentation session** relayed by the server (Slides 10 §5.2, §6). The phone-as-remote
(P1) uses the same session. A presenting-only second window (Window Management API on web, a
second OS window on desktop) is recorded as a **possible later addition**; it would be the only
exception and must reuse the presentation-session state model.

## 2. Routing (`go_router`, URL-based for web)

| Route | Screen |
|-------|--------|
| `/signin`, `/signup`, `/signup/verify`, `/reset` | Auth (see 04) |
| `/` | Home (app homes: Recent of the app's kind + template strip; Drive: Home, all kinds) — (v2) §3.3. The site root (`/` of the origin) redirects to Wonky Drive's home (`/drive/`; v2 review B4) |
| `/f/:folderUuid` | Folder (v2; the former `/drive/:folderUuid` redirects) |
| `/my-files` (app homes) · `/my-drive` (Drive) | Root of the user's drive (v2 names; `/my-drive` also redirects to `/my-files` in app homes) |
| `/shared`, `/starred`, `/recent`, `/offline` (app homes), `/trash` | Drive views |
| `/search?q=…` | Search results |
| `/templates` | Template gallery |
| `/new?folder=&template=` (Write, Sheets, Slides; v2) | Creates an item of the app's kind (offline-first where supported) and replaces the route with its editor; used by Drive's *New* menu and *From template* |
| `/import?file=<fileItemUuid>` (Write, Sheets; v2) | Imports an uploaded Drive file with the app's import dialog (Drive 02 §7.2) |
| `/settings/:section` | Wonky Work settings (suite sections, 04 §4) — (v2) |
| `/settings/app`, `/settings/app/:section` | The current app's settings (04 §4) — (v2) |
| Write: `/d/:uuid` (+ `?heading=…`, `?comment=…`, `?version=…`) | Document editor |
| Write: `/d/:uuid/history` | Version history (full-screen compare mode) |
| Write: `/d/:uuid/print` | Print/PDF preview |
| Write: `/themes` and `/themes/:themeUuid` (+ `?doc=<uuid>` to preview/apply to a document) | Theme library & theme editor |
| Sheets: `/s/:uuid` (+ `?sheet=<sheetId>&range=A1:B9`, `?comment=…`) | Spreadsheet editor |
| Sheets: `/s/:uuid/history` | Version history |
| Sheets: `/s/:uuid/print` | Print preview |
| Sheets: `/s/:uuid/script` | Script editor (full-screen) |
| Slides (v2): `/p/:uuid` (+ `?slide=`, `?comment=`) · `/p/:uuid/present` · `/p/:uuid/print` · `/p/:uuid/history` | Deck editor · presenting · PDF/print preview · version history ([Slides 04](wonky_slides/04-screens-menus-toolbar.md)) |
| Drive (v2): `/file/:uuid` · `/storage` | File preview · Storage page ([Drive 04](wonky_drive/04-screens-menus.md)) |
| `/improvements`, `/improvements/bugs`, `/improvements/tasks`, `/improvements/done`, `/improvements/p/:number`, `/improvements/t/:number`, `/improvements/contribute` (M12, **public**) · `/improvements/review` (admins) | Bugs & improvements board pages in every app ([16 §4.3](16-bugs-and-improvements.md)); the server redirects `/improvements/**` to `/drive/improvements/**` |
| `/invite/:token` | Share-link landing (request access / open) |

Auth guard redirects to `/signin?next=…`, except for the auth routes and the `/improvements`
routes, which signed-out visitors can read (M12). The auth screens carry `next` between each other
(*Create account*, *Sign in*, *Forgot password*, `/signup/verify`), and signing in or finishing
sign-up lands on it; only a relative path (`/…`, not `//…`) is followed, anything else goes to
`/`. Unknown/forbidden items show an in-app
**No access** page with *Request access* (sends a request to the owner) and *Switch account*.

Deployment: `wonky_server`'s web server serves the Flutter web builds from one origin:
`/drive/…`, `/write/…`, `/sheets/…`, `/slides/…` (each built with matching `--base-href`);
(v2) the origin's `/` redirects to `/drive/` (Wonky Drive's home, the landing app; v2 review B4;
the editors are reachable from every home's left menu). Routes above are relative to the app's base href. Cross-app
links use the app base URLs from `config.json`; the sign-in session is shared by all apps
(see [01 §2.4–§2.5](01-architecture.md)).

## 3. Shell layout

```
┌───────────────────────────────────────────────────────────────────────────┐
│ Editor header (app-specific: title row, menubar, toolbar)  or  WonkyTopBar │
├───────────────────────────────────────────────────────────────────────────┤
│                                                     │                     │
│                 Main content (route)                │  Side panel host    │
│                                                     │  (WonkySplitView;   │
│                                                     │  icon rail when     │
│                                                     │  collapsed)         │
├───────────────────────────────────────────────────────────────────────────┤
│ StatusBar (editor screens only, optional — only the app's items)          │
└───────────────────────────────────────────────────────────────────────────┘
 Overlays: dialogs · command palette · toasts (bottom-right) · offline banner (top) ·
           MCP control indicator (bottom-left pill when an agent is driving the UI)
```

### 3.1 Editor header (shared structure, app-specific content)

Row 1 (title row, 48 px):
- App icon (the product icon, click → Home; with unsaved-offline badge if relevant).
- `DocumentTitleField`.
- Star toggle, *Move* (folder icon → Move dialog), `SyncStatusIndicator`.
- Spacer.
- `PresenceAvatarStack`.
- (M12, T-5) **Report a bug** and **Suggest an improvement** — outline `sm` buttons with the
  Lucide `bug` and `leaf` icons (`shell.board.report` with kind `bug` / `idea`, so the dialog
  opens on that kind, §3.4; keys `editor.reportBug`, `editor.suggest`); between 640 and 1200 px
  only the icons (tooltips), hidden below 640 px (still in Help).
- Comments button (shows/hides the comments, `shell.comments.togglePanel`; badge with open
  count). Comments show through the app's `CommentsHost` when it sets one
  (`ShellServices.commentsHost`; Write: the margin next to the page), otherwise in the comments
  side panel.
- **Share** button (primary; lock/globe icon by link state).
- Account avatar menu.

There are no History or Assistant buttons in the title row: those panels (and the app's other
panels) are opened from the side panel host's icon rail at the right edge
([02 §4.5](02-design-system.md)), or by their commands and shortcuts (View › Panels). Rail order:
the app's panels first, then History (only for roles that can view history). File › Details
opens the details panel (not in the rail).

Row 2: `WonkyMenubar` (File, Edit, View, Insert, Format, …app menus…, Tools, Extensions (Sheets:
Scripts), Help). Row 3: `WonkyToolbar` in a rounded container (margin 8 px left/right, 6 px above,
8 px below). Everything is always shown: there is no compact mode, full screen or View › Show
submenu — except in the read-only **mobile layout** below 640 px (T-9,
[02 §6.1](02-design-system.md)): a compact title row over the read-only document, without
rows 2 and 3, the side panels and the status bar. The status bar below the content is optional (`EditorScaffold.showStatusBar`) and
contains only what the app passes; the sync status is in the title row and the app theme in
View › App theme.

### 3.2 Shared menus (each app extends)

**File** (shared core): New ▸ (Document, Spreadsheet, Presentation (v2), From template…), Open… (`Mod+O`), Import…,
Make a copy…, Share ▸ (Share with others, Copy link, Publish settings), Download ▸ (formats),
Rename, Move…, Add shortcut to Drive, Move to trash, Version history ▸ (Name current version,
See version history `Mod+Alt+Shift+H`), Make available offline (toggle), Details, app items
(Write: Language, Page setup / Sheets: Settings — locale, time zone, calculation), Print (`Mod+P`).

**Edit**: see [08-commands-and-undo.md](08-commands-and-undo.md) §3.5, plus app items.

**View** (shared core): Mode ▸ (Editing / Suggesting (Write) / Viewing), Zoom ▸, Panels ▸
(Outline, Comments, History, Assistant — Write replaces Comments with a top-level *Comments and
suggestions* toggle for its margin), App theme ▸ (System / Light / Dark).

**Tools**: Assistant, Explore (search drive), (v2) *<App> settings…*
(`shell.settings.openApp`, `Mod+,` on desktop) and *Wonky Work settings…*
(`shell.settings.open`), Keyboard shortcuts (`Mod+/`), Accessibility settings.

**Help**: Keyboard shortcuts, app items (Write: Markdown guide; Sheets: Function list; Slides:
see Slides 04), separator, (M12) **Bugs & improvements…** (`shell.board.report`, opens the
report dialog) and **Browse Bugs & improvements** (`shell.board.open`, §3.4), What's new, About. There is no in-app help center and no menu search (menu commands are found through the
command palette).

**Decided (v2 review, Q6):** *Report a bug* **replaces** *Report a problem* in the Help menu
(one obvious way to report). `shell.help.feedback` (the in-app dialog that posts to the server's
`feedback` endpoint) stays registered for the palette and MCP, and the error boundary keeps
*Copy error details*, which users can paste into the GitHub issue. **M12 replaced both with the
board** ([16](16-bugs-and-improvements.md)): `shell.help.reportBug` (kind Bug) and
`shell.help.feedback` are now aliases of `shell.board.report`, hidden from the palette, and the
error card also offers *Report this bug*.

Only one menu is open at a time: opening a menubar menu, dropdown or context menu closes the
one that was open ([02 §4.2](02-design-system.md)).

### 3.3 Homes and the left menu (v2)

Every app has a **home** (its documents view) built from the shell's drive UI
(`DriveHomeScreen`, `packages/wonky_app/lib/src/drive/`), configured by
`WonkyAppConfig.homeScope`:

| | Wonky Drive (`HomeScope.all`) | App homes — Write, Sheets, Slides (`HomeScope.kind(k)`) |
|-|------------------------------|-----------------------------------------------------------|
| Items listed | every kind | only kind `k` (documents / spreadsheets / presentations), plus folders that contain `k` (suite 05 §3.2) |
| Top bar | Drive logo + "Drive", search across all kinds | app logo + short name, search filtered to `k` with a "Search all of Wonky Drive" row |
| New | folder, document, spreadsheet, presentation, file upload, template | `k` and *From template* |
| Template strip | — | yes (app's templates) |
| Folder management | tree, drag moves, new folder | none — **Open in Wonky Drive** (ghost button with the Drive icon in the header row, opens the same folder in Drive); the per-item *Move to…* dialog stays |
| Upload | arbitrary files (Drive 02) | *Import file…* of the app's convertible types |
| Type filter chip | yes (incl. file subtypes) | — |

The **left menu** (`HomeSidebar`, Drive 04 §2) is the same widget in every home:

1. **App section** — Drive, a divider, then Write, Sheets, Slides (short names, in this order;
   v2 review B4) with their product icons; the current app highlighted; the others switch apps in the same tab
   (`shell.account.switchApp {app}`).
2. **+ New** (Drive only; the app homes create from the template strip's *Blank* card) and the
   app's navigation (`WonkyAppConfig.homeNav`): app homes — *Recent* (`/`),
   *My files*, *Shared with me*, *Starred*, *Offline* (on-device availability, as today),
   *Trash*; Drive — Home, My Drive (+ folder tree), Shared with me, Recent, Starred, Trash,
   Storage.
3. **Bottom section** — *Settings* (the app's settings, `shell.settings.openApp`; Wonky Work
   settings are reached from there), (M12, T-5) *Contribute & build* (Lucide `wrench`,
   `shell.board.open`, the board where people vote and pick up tasks; key
   `home.footer.contribute`), *Report a bug* (`bug`; key `home.footer.reportBug`) and *Suggest an
   improvement* (`leaf`; key `home.footer.suggest`), both `shell.board.report` with their kind
   (they replace *Report a bug*), and the
   storage meter
   ("12.3 MB of 50 MB used", [Drive 03 §6.1](wonky_drive/03-storage-quota.md)).

The account menu (avatar) in homes and editors lists: name and email, *<App> settings*, *Wonky
Work settings*, *Open ▸* Wonky Drive / Write / Sheets / Slides (product icons; replaces the
former single "Open Wonky Sheets/Write" item), *Sign out*.

**Decided (v2 review, Q7, D2):** an app home shows only folders that contain — recursively,
ignoring trashed items — at least one item of the app's kind (maintained as
`DriveItem.kindMask`, suite 05 §3.2); empty folders and folders with only other kinds are
hidden, so an app home never shows dead ends (folders are managed in Wonky Drive).

**As built (D-10):** `HomeSidebar` (`packages/wonky_app/lib/src/drive/home_sidebar.dart`:
`AppLinksSection`, `HomeNewButton`/`homeNewMenuEntries`, `HomeSidebarFooter`,
`StorageMeterSlot` — the placeholder D-11's `StorageMeter` replaces) is the left menu of every
home, also of the v1 homes: while `homeScope` is null (Write and Sheets until D-16) the
navigation is `HomeNavSpec.legacy` (Home, My Drive + tree, Shared, Recent, Starred, Offline,
Trash) and the listing keeps the v1 type filter and every folder. Flipping an app is the one
getter `homeScope => const HomeScope.kind(<kind>)`; `homeNav`, the New menu, the folder rule
(`foldersContaining`), the type chip, drag moves, the search scope, *Open in Wonky Drive* and the
"Recent" title of `/` follow from it. `/my-files` and `/my-drive` both exist and redirect to
`homeNav.myFilesRoute`. Cross-kind *New* (`shell.file.new {kind}` for another app's kind,
templates of another kind) navigates to that app's `/new?folder=&template=` instead of creating
on the server. Below 768 px the left menu is a `ShadSheet` drawer; the template strip is
skipped when the content area is shorter than 560 px.

**As built (D-16):** Write and Sheets are flipped (`HomeScope.kind(document)` /
`HomeScope.kind(spreadsheet)`); their homes' *+ New* listed the kind, *From template…* and
*Import file…* (`shell.drive.upload` with the app's convertible types) — since removed from the
app homes (the template strip's *Blank* card creates; importing stays on `shell.drive.upload`,
⇧U and the command palette); the empty home reads
"Welcome to <App>" / "Create a <kind> or open one shared with you." (Drive: "…document,
spreadsheet or presentation, or upload files."). File › New in every editor has *Presentation*
(`shell.file.new {kind: presentation}` → Slides' `/new`). The `/new` and `/import` route page
replaces itself with the editor; on cancel it goes back in the app, else in the browser
history (`CrossAppNavigator.historyBack`, back to Drive after *Open with*), and after an error
it stays in the app (home) so the toast is seen. Server-built folder links (MCP results,
notification emails) are `/drive/f/<uuid>`.

### 3.4 Report a bug → Bugs & improvements (M12)

M12 replaced *Report a bug* (the GitHub new-issue link, v2) and *Report a problem* with the
in-app board; the specification is [16](16-bugs-and-improvements.md): entry points (§4.1), the
report dialog (§4.2), the board routes and pages (§4.3–§4.6). `shell.board.report {kind?}` opens
the dialog (the board page when signed out), `shell.board.open {tab?}` opens the board, and
`shell.help.reportBug` and `shell.help.feedback` stay registered as aliases.

**GitHub fallback.** When the server's `config.json` says `board: false`, `shell.board.report`
falls back to the former behavior: `BugReportLink` builds the prefilled new-issue link
(`wonky.help.bugReportUrl`, default `https://github.com/serverpod/wonky/issues`; app, build
version, platform and browser family only, no user content; issue form
`.github/ISSUE_TEMPLATE/bug_report.yml`; D-10, v2 review Q8) and opens it as an external link
behind `confirmExternalLink` (§1).

## 4. Global overlays and states

- **Offline banner**: thin top bar "You're offline. Changes are saved on this device and will
  sync when you're back online." with *Retry* (`shell.offlineBanner.retry`, a small ghost
  button tinted with the banner's own colors). Edits remain enabled for offline-capable content.
- **Reconnecting** indicator in `SyncStatusIndicator` with exponential backoff timer.
- **Version mismatch**: if the server's protocol version is newer than the client's
  (`/version` check on connect), show a non-blocking toast "A new version is available —
  Reload"; block only if incompatible.
- **Read-only/permission change**: if your role is downgraded while editing, show a toast and
  switch mode live; pending local changes that are no longer allowed are discarded with a
  notice (and saved as a local "Unsaved changes" export offered for download).
- **Global error boundary**: unexpected exceptions show a recoverable "Something went wrong"
  card with *Reload document* and *Copy error details*; errors are reported to the server log.
- **MCP control pill**: when an MCP client invokes UI-bridge tools, a pill "🤖 Agent is
  controlling this window — Stop" appears; *Stop* disconnects the bridge for this session
  (see [09-mcp.md](09-mcp.md)).
- **(v2) Storage banner and dialog**: at ≥ 90 % of the quota and when over quota, a banner under
  the top bar/editor header; refused byte-adding actions show the *Out of storage* dialog
  ([Drive 03 §6.2–6.3](wonky_drive/03-storage-quota.md)).
  **As built (D-11):** `StorageBanner` is part of `DriveHomeScreen` (below the top bar) and
  `EditorScaffold` (below the toolbar); the `QuotaErrorPresenter` shows the dialog for every
  human-invoked command refused with `quotaExceeded` ([Drive 03 §12](wonky_drive/03-storage-quota.md#12-as-built-d-11)).

## 5. State management and DI

- Follow Flutter's recommended layered architecture (UI → ViewModel/Controller → Repository →
  Service). Controllers are `ChangeNotifier`s; widgets use `ListenableBuilder` /
  `ValueListenableBuilder`. DI via `provider` (`Provider`, `ChangeNotifierProvider`) at shell
  and screen level.
- Repositories wrap the generated Serverpod client and local stores; UI never calls the client
  directly.
- Long-lived services (Connectivity, Presence, UndoService, CommandRegistry, KeymapService,
  McpBridge, Preferences) are created in `WonkyShell` and provided at the top.

## 6. Desktop specifics (deferred in v2)

**v2 is web only** ([01 §1 A13](01-architecture.md)): the desktop targets must keep compiling,
but everything in this section is **deferred** — no native menubar, no desktop binaries with URL
schemes, no desktop packaging, no file associations. On desktop builds the left menu's app links
and *Open in …* fall back to the web URL via `url_launcher` (an external app) or are hidden; no
desktop-only code is written for v2. The rest of this section is the target for a later
iteration.

- One OS window. Native menubar on macOS mirrors `WonkyMenubar` via `PlatformMenuBar` (generated
  from the same `MenuSpec`); in-window menubar hidden on macOS when native menus are active
  (setting).
- Cross-app switch on desktop: each app is a separate desktop binary (built from
  `wonky_drive`, `wonky_write`, `wonky_sheets`, `wonky_slides`; sign-in sharing per
  [01 §2.5](01-architecture.md)); the left menu's app links and "Open in …" launch/activate the
  other app via its custom URL scheme (`wonkydrive://f/<uuid>`, `wonkywrite://d/<uuid>`,
  `wonkysheets://s/<uuid>`, `wonkyslides://p/<uuid>`) — this is another app, consistent with the
  single-window rule — and fall back to the web URL if not installed.
- **Decided (v2 review, Q9):** four binaries (the web build structure maps 1:1; a combined
  binary would also combine the four bundles) — deferred with the rest of this section;
  revisit when desktop work resumes.
- Window title = document title + " — Wonky Write"; dirty marker unused (always saved).
- File associations: `.md` (Write, imports), `.xlsx/.csv` (Sheets, imports); (v2) none for
  Drive or Slides (Slides has no import formats).
- Window size/position persisted.

## 7. Connectivity service

`ConnectivityService` exposes `online` (server reachable via the Serverpod WebSocket,
heartbeat 15 s), `lastConnectedAt`, `reconnect()`. All sync layers listen to it. Streams
(document sessions, presence, drive watch, UI bridge) are re-established on reconnect by a
`StreamSupervisor` with backoff (1 s → 30 s, jitter).
