# 04 · Authentication, Accounts and Preferences

One account works in every app (v2: Drive, Write, Sheets, Slides). Auth is implemented with **Serverpod's built-in IDP**
(`serverpod_auth_idp_server` / `serverpod_auth_idp_flutter`, 4.1.x): email + password, and
**Sign in with Google** on web (§1.6).
The scaffolded `JwtConfigFromPasswords()` token manager and `ServerpodCloudEmailIdpConfig` (or
`EmailIdpConfigFromPasswords` when self-hosting mail) in `wonky_server/lib/server.dart` are
kept. **One sign-in covers all apps**: on web the session lives in Serverpod's httpOnly auth
cookie on the shared origin; desktop details in [01 §2.5](01-architecture.md).

## 1. Flows

### 1.1 Sign up
1. **Sign-up screen**: *Continue with Google* (web, §1.6; a line below it says continuing
   accepts the terms and the privacy policy), an "or" divider, then display name, email, password (+ strength meter), "I agree to the terms"
   checkbox with *Terms of service* · *Privacy policy* links below it (the web server's `/terms`
   and `/privacy` pages, suite 13 §5; opened like external links, `AppUrls.page`), *Create
   account* button, link to *Sign in*.
2. Server sends a verification code (development: logged to console).
3. **Verify email screen**: 6-digit code input (`ShadInputOTP`), *Resend code* (60 s cooldown),
   *Change email*.
4. On success → create `UserProfile` (see §3), set `writeDefaults.defaultThemeId` to the
   built-in default theme (built-in themes are global rows, see Write 06), create a welcome
   document (from the `write.welcome` template; small and counted in the new user's 50 MB,
   Drive 03). Only Write gets starter content: no welcome spreadsheet or presentation is
   created (T-19; the `sheets.welcome` template stays for spreadsheets older accounts got
   from it) → land on **Wonky
   Write's home** (v2; `/` redirects there, 01 §2.4, v2 review Q2) — or on the app the sign-up
   started from when `next` points into it.

### 1.2 Sign in
- *Continue with Google* (web, §1.6) and an "or" divider above the form.
- Email, password, *Remember me* (keeps the session across restarts: on web via the shared
  httpOnly auth cookie, on desktop via secure storage), *Forgot password?*, *Create account*.
- Errors inline under fields; rate limited server-side (IDP default) with a friendly message.

### 1.3 Password reset
Request (email) → code screen → new password + confirm → signed in.

### 1.4 Sign out
Account menu → *Sign out*. Signs out of **all** apps (shared session). Clears tokens, local caches marked user-scoped (Write offline cache,
Sheets sync DB is **kept** but locked to that user id; signing in as a different user uses a
different DB file — see offline spec), and in-memory undo stacks.

### 1.5 Session expiry
JWT refresh is automatic. If refresh fails (revoked/expired), show a blocking
**"Session expired"** dialog over the current screen (state preserved) with a sign-in form;
after re-auth the user continues where they were. Pending offline changes are kept.

### 1.6 Sign in with Google (web)
Serverpod's Google IDP ([Serverpod docs](https://docs.serverpod.dev/concepts/authentication/providers/google/setup)),
OAuth2 authorization code + PKCE in a popup (the single-window exception of
[03 §1](03-app-shell-and-navigation.md)). Desktop doesn't offer it yet.

- **Server** (`platform/users/google_idp.dart`): enabled only when the `googleClientSecret`
  password holds a valid client JSON (the Google Cloud console's *Web application* client,
  `{"web": {"client_id", "client_secret", …}}`; on Serverpod Cloud a password secret).
  `redirect_uris` is optional: Google's download only has it when the client had redirect
  URIs at download time, Serverpod requires the key but doesn't use it, and Google validates
  the redirect URI against the console. A missing or invalid secret turns Google sign-in off with a warning on stderr; it
  never stops the server. `GoogleIdpEndpoint` (`googleIdp`) extends `GoogleIdpBaseEndpoint`;
  `FlutterWebAuth2CallbackRoute` serves `/auth/callback`, the page that posts the code back to
  the app (same origin as `/write/` and `/sheets/`). `AppConfigRoute` adds `google: {clientId,
  redirectUri}` to `config.json`, with `redirectUri` = the public web origin + `/auth/callback`
  ([01 §2.4](01-architecture.md)).
- **Accounts**: Google's default validation requires a verified email and a name. A first
  Google sign-in for an email that already has a Wonky account signs in to **that** account
  (the Google account is linked to it and the auth user the IDP just created is deleted;
  the IDP still treats the account as new and creates its Serverpod auth profile, so the
  config passes `LinkedAccountUserProfiles`, which returns the linked account's existing
  auth profile instead of inserting a second one); otherwise a new `UserProfile` is created with Google's full name. Later sign-ins use the
  linked account.
- **Client** (`auth/google_web_flow.dart`, `google_popup_web.dart`): Wonky runs the popup
  itself instead of `GoogleWebSignInService`/`flutter_web_auth_2`. The apps are
  cross-origin isolated (COOP `same-origin`, 13 §3), so the popup has no opener and the app
  can't see it close: the plugin would spin until its 5-minute timeout, and a retry could take
  the earlier attempt's result. `GoogleAuthRequest` builds Google's authorization URL (PKCE
  S256, random `state`, `openid` + email + profile scopes, `prompt=select_account`); the popup
  (`window.open`, one window name, opened in the click's task) returns via `/auth/callback`,
  which leaves the callback URL in `localStorage` (or posts it to the opener); results are
  matched by `state`, and stale ones are dropped. A new click restarts the attempt in the same
  popup, so the button stays enabled while it waits. `access_denied` (the user declined) does
  nothing; a blocked popup says to allow pop-ups. Then `googleIdp.loginWithCode(code,
  codeVerifier, redirectUri)` and `client.auth.updateSignedInUser`. The *Continue with Google* button
  (outline, Google's unaltered multicolor "G" — `GoogleLogo` in `wonky_ui` — in light and
  dark) is shown on web; when the server has no Google client (e.g. local development without
  the callback registered) it shows "Sign in with Google isn't set up on this server." Closing
  the popup does nothing. The button also appears in the session-expired dialog's form.
- **Google Cloud console** (production): authorized JavaScript origin `https://wonky.work`,
  redirect URI `https://wonky.work/auth/callback`, authorized domain `wonky.work`, consent
  screen links `https://wonky.work/privacy` and `https://wonky.work/terms` (13 §5).

## 2. Screens (shared, in `wonky_app`)

| Screen | Route | Notes |
|--------|-------|-------|
| Sign in | `/signin` | Centered card (max 400 px) on branded background; the suite icon (Wonky Work product icon, 56 px, [02 §5](02-design-system.md)) and "Wonky Work" as the headline (no app name, no subheadline), left-aligned with the card: one account covers all apps. |
| Sign up | `/signup` | Same layout. |
| Verify email | `/signup/verify` | |
| Forgot password | `/reset` | |
| Wonky Work settings (v2) | `/settings/:section` (default `/settings/account`) | See §4. |
| App settings (v2) | `/settings/app`, `/settings/app/:section` | See §4. |

All auth screens support light/dark and are keyboard navigable (Enter submits).

## 3. Data model (server, `wonky_server/lib/src/platform/users/`)

```yaml
# user_profile.spy.yaml
class: UserProfile
table: user_profile
fields:
  authUserId: UuidValue          # serverpod auth user id (unique)
  displayName: String
  email: String                  # denormalized for search/mentions (lowercased)
  avatarFileId: UuidValue?       # → StoredFile
  avatarColor: String            # hex, deterministic from id, used for presence/initials
  locale: String?                # BCP-47, null = follow browser/OS
  timeZone: String?              # IANA, null = follow device
  createdAt: DateTime
  lastSeenAt: DateTime?
indexes:
  user_profile_auth_idx: { fields: authUserId, unique: true }
  user_profile_email_idx: { fields: email, unique: true }
```

```yaml
# user_preferences.spy.yaml
class: UserPreferences
table: user_preferences
fields:
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  appTheme: AppThemeMode         # enum: system, light, dark
  accentColor: String?           # optional accent override (one of the design system accents)
  density: UiDensity             # enum: comfortable, compact
  keymapOverrides: String        # JSON {commandId: [binding,…]}
  writeDefaults: String          # JSON: default theme id, spellcheck on, smart quotes, etc.
  sheetsDefaults: String         # JSON: default locale for new sheets, default font, etc.
  slidesDefaults: String         # (v2) JSON: Slides settings (Slides 04: theme, slide size, animation, code; last-used export options under `exportOptions`)
  slidesPresenter: String        # (v2) JSON: presenter preferences (Slides 10 A-10-4)
  driveDefaults: String          # (v2) JSON: Drive settings (Drive 04 §8: layout, sort, extensions, uploads)
  notificationSettings: String   # JSON: email digests on/off, mention emails, etc.
  aiEnabled: bool, default=true
indexes:
  user_preferences_user_idx: { fields: userId, unique: true }
```

`PersonalAccessToken` (for MCP, see [09-mcp.md](09-mcp.md)):

```yaml
class: PersonalAccessToken
table: personal_access_token
fields:
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  name: String
  tokenHash: String              # sha256 of the secret; secret shown once
  prefix: String                 # first 8 chars for display, e.g. "wkpat_ab12…"
  scopes: List<String>           # e.g. ["drive:read","write:edit","sheets:edit","ui:control","board"]
  expiresAt: DateTime?
  lastUsedAt: DateTime?
  createdAt: DateTime
  revokedAt: DateTime?
```

## 4. Settings (v2: split into Wonky Work settings and app settings)

Settings are split in two (decision D4):

- **Wonky Work settings** — suite-level, identical in every app, routes `/settings/:section`
  (`/settings` → `/settings/account`). Everything about the account, the device and the suite.
- **<App> settings** — the current app's own preferences, routes `/settings/app` and
  `/settings/app/:section` (first section by default). *Write settings* in Write, *Sheets
  settings* in Sheets, *Slides settings* in Slides, *Drive settings* in Drive. An app shows only
  its own app settings (to change Sheets defaults, open Sheets settings — the nav has a link
  "Settings of other apps ▸" with the three other apps, cross-app navigation to their
  `/settings/app`).

### 4.1 Where every existing section goes

| Section before v2 (id) | Content | v2 location (id) |
|------------------------|---------|------------------|
| Account (`account`) › Profile | Avatar upload/crop, display name, email (change with verification) | Wonky Work › **Account & profile** (`account`) |
| Account › Security | Password change, sign out | Wonky Work › **Sign-in & security** (`security`, new id) + Google account link status (linked / *Link Google account*, web), *Sign out of all devices* (P2) |
| Account › Delete account | Type-to-confirm delete; transfer or delete owned files | Wonky Work › Account & profile (bottom); transfers respect the new owner's quota (Drive 03 §7.3) |
| Appearance (`appearance`) | App theme (System/Light/Dark with previews), density, reduce motion | Wonky Work › **Appearance** (unchanged; also the target of *Accessibility settings*) |
| Language & region (`language`) | UI language, time zone | Wonky Work › **Language & region** |
| Language & region › default locale for new spreadsheets | Number/date formats of new spreadsheets | Sheets settings › Defaults (it is a Sheets preference, already stored in `sheetsDefaults`) |
| Keyboard shortcuts (`keyboard`) | Searchable command table, record bindings, conflicts, reset | Wonky Work › **Keyboard shortcuts** (decided below): lists the shell commands and the **current app's** commands, grouped "Shared" / "<App>"; overrides of other apps' commands are kept untouched |
| Write (`write`) | Default theme, spellcheck, smart quotes, auto-pair, Markdown shortcuts, pageless, default page setup, default export format | **Write settings** (`/settings/app/…` in Write; sections per Write 05 §13.3: *Editor*, *Page & export*, *Spelling*) |
| Document themes (`themes`, contributed by Write) | Default theme, theme library | **Write settings › Document themes** (`/settings/app/themes`) |
| Sheets (`sheets`) + Sheets' custom body | Default locale/time zone/font/size, Enter starts editing, formula autocomplete, formula help, editor mode in status bar, custom fill lists, enable scripts, reduce grid animations | **Sheets settings › Defaults** (`/settings/app/defaults` in Sheets; Sheets 04 §11.24) |
| Notifications (`notifications`) | Per category in-app / email / off, digest | Wonky Work › **Notifications** (unchanged; categories now cover presentations and files) |
| AI (`ai`) | Enable assistant, model quality, clear AI history, privacy notice | Wonky Work › **AI** (unchanged) |
| AI providers (`ai-providers`) | Server provider; user's own key | Wonky Work › **AI providers** (unchanged id, so `shell.settings.open {section: ai-providers}` keeps working) |
| Developer (`developer`) | Server status (Redis), personal access tokens, MCP connection JSON, UI-bridge switch | Wonky Work › **Developer** (unchanged) |
| Offline & storage (`offline`) | Files on the device, pinned files, pending changes/uploads, local storage used, *Simulate offline*, *Clear local data* | Wonky Work › **Offline & device data** (same id `offline`, renamed so it isn't confused with the quota): the current app's device data in full, plus one summary row per other app on this device ("Wonky Sheets — 120 MB on this device · Manage in Wonky Sheets") |
| — (new) | Storage quota | Wonky Work › **Storage** (`storage`): meter, breakdown by kind, "What counts", *Manage storage in Wonky Drive* (Drive 03 §6.5) |
| About (`about`) | App/server/protocol versions, licenses, links | Wonky Work › **About** (shows the current app's version and the server version; (M12) a *Bugs & improvements* button, `shell.board.report`, [16 §4.1](16-bugs-and-improvements.md), replaces the *Report a bug* link) |
| — (new) | Slides preferences | **Slides settings** (`slidesDefaults`; sections per [Slides 04](wonky_slides/04-screens-menus-toolbar.md)): default theme, slide size, presenter-view preferences, animation defaults (incl. reduced motion while presenting), code font size |
| — (new) | Drive preferences | **Drive settings** (`driveDefaults`; [Drive 04 §8](wonky_drive/04-screens-menus.md)): default layout, sort, folders on top, show file extensions, ask on name conflicts, convert uploads (P1) |

Compatibility: old routes redirect — `/settings/write` and `/settings/themes` in Write →
`/settings/app/editor` and `/settings/app/themes`; `/settings/sheets` in Sheets →
`/settings/app/defaults`; in another app they navigate to that app (`/write/settings/app`).
`shell.settings.open {section: write|sheets|themes}` maps to the same targets, so menu
entries, MCP clients and saved links keep working.

### 4.2 Settings screen

Full-screen in-app page (`SettingsScreen`, shell) with a left nav of **two groups**:

```
┌ ← Settings ──────────────────────────────────────────────────────────────┐
│ [▣] WRITE SETTINGS        │  Editor                                       │
│   Editor                  │  ┌ Typing ─────────────────────────────────┐ │
│   Page & export           │  │ Markdown shortcuts              [on ]   │ │
│   Document themes         │  │ Smart quotes and dashes          [on ]   │ │
│   Spelling                │  └─────────────────────────────────────────┘ │
│   Settings of other apps ▸│                                               │
│ [▣] WONKY WORKS SETTINGS  │                                               │
│   Account & profile       │                                               │
│   Sign-in & security      │                                               │
│   Appearance              │                                               │
│   Language & region       │                                               │
│   Keyboard shortcuts      │                                               │
│   Notifications           │                                               │
│   Storage                 │                                               │
│   Offline & device data   │                                               │
│   AI · AI providers       │                                               │
│   Developer               │                                               │
│   About                   │                                               │
└──────────────────────────────────────────────────────────────────────────┘
```

- Group headers carry the product icon (the app's; the Work icon for Wonky Work) and are
  `Semantics(header: true)`; the page header reads "Write settings" or "Wonky Work settings"
  depending on the open section. Narrow widths: the nav becomes a select above the content.
- Back (←) returns to the previous route (the editor or home the user came from), else home.
- Entry points: account menu (*<App> settings*, *Wonky Work settings*), the left menu's bottom
  section in homes (03 §3.3), Tools menu in editors, command palette:
  `shell.settings.open {section}` (Wonky Work) and **`shell.settings.openApp {section?}`**
  (app settings), `Mod+,` (desktop) = app settings.
- The app's sections come from `WonkyAppConfig.appSettingsSections(services)` (list of
  `SettingsSectionSpec`, replacing `settingsSections` and `sheetsSettings`).

Every setting change is a command (e.g. `shell.settings.setAppTheme`, `write.prefs.*`,
`sheets.prefs.*`, `slides.prefs.*`, `drive.prefs.set`) so it is MCP-controllable; settings are
**not** on the undo stack (they apply immediately and are trivially reversible).

**Decided (v2 review, Q10):** *Keyboard shortcuts* live in **Wonky Work settings** with two
groups — *Shared* (shell commands) and *<App>* (the current app's commands). Overrides are one
JSON (`keymapOverrides`) covering every app's commands; each app lists only its own and keeps the
other apps' overrides untouched. One place to look, and shared shortcuts (palette, undo, quick
switcher) stay consistent across apps.

**As built (D-12).** `SettingsScreen` (`wonky_app/lib/src/settings/`) with `SettingsArea {app,
work}`; routes from `settingsRoutes(services, page)`: `/settings` → `/settings/account`,
`/settings/app` → the first app section (or `/settings/account` when the app has none, e.g. Slides
until SL), `/settings/app/:section` (unknown ids show the first section), `/settings/:section`
(Wonky Work ids `workSettingsSectionIds`: account, security, appearance, language, keyboard,
notifications, storage, offline, ai, ai-providers, developer, about). The v1 ids (`legacySettingsTarget`)
redirect in their own app and show `SettingsHandoffPage` elsewhere, which opens the owning app's
`/settings/app/<section>` (full page load on web); `shell.settings.open {section}` goes through
the same routes. The wide nav has the two group headers (product icon, `Semantics(header)`), the
app's sections, *Settings of other apps* (expands inline to the three other apps; each opens its
`/settings/app` cross-app) and the Wonky Work sections; below 760 px the nav is one select
(groups as headers, other apps as options). The page header names the open group; Back returns to
the last non-settings route of the navigation history, else home. `Mod+,` (desktop) moved from
`shell.settings.open` to `shell.settings.openApp`. Tools menu: `tools.preferences` is now *<App>
settings* (`shell.settings.openApp`) followed by `tools.workSettings` (*Wonky Work settings*);
Write keeps both inside its *Preferences ▸* submenu. Sections: *Account & profile* (profile +
delete account), *Sign-in & security* (password, sign out — Google link status and *Sign out of
all devices* are open, TODO.md), *Keyboard shortcuts* grouped *Shared* (`shell.*`) / *<App>*
(every other registered command), *Reset all* resets only the listed commands
(`KeymapService.resetAll(where:)`) and removed overrides are sent as `null` so the server's
key-by-key merge deletes them; *Storage* (D-11's `StorageMeter`, breakdown by kind incl. trash,
"What counts", *Manage storage in Wonky Drive* = `shell.storage.open`); *Offline & device data*
(renamed; the per-other-app summary rows are open, TODO.md); *About* + *Bugs & improvements* (M12; was *Report a bug*). App
sections: Write (`editor`, `page`, `themes`, `spelling`, Write 05 §13.3), Sheets (`defaults`,
every control through `sheets.prefs.set {key, value}`), Drive (`drive`, a stub until D-17).
`PreferencesController` exposes `driveDefaults`, `slidesDefaults`, `slidesPresenter` with
key-wise setters (`setDriveDefault`, `setSlidesDefault`, `setSlidesPresenter`; null removes).
`WonkyAppConfig.settingsSections` and `sheetsSettings` are removed.

## 5. Endpoints

`UserEndpoint` (`user`): `getMe()`, `updateProfile(displayName, locale, timeZone)`,
`uploadAvatar()` (upload description flow; the avatar is stored as a 256 × 256 WebP, cropped to
fill, 12 §1.1 *Image optimization*), `getPreferences()`, `updatePreferences(patch)`,
`searchUsers(query, limit)` (for share dialog & @mentions; only returns users who share at least
one item with the caller, or exact email matches), `deleteAccount(confirmation)`.

`GoogleIdpEndpoint` (`googleIdp`): Serverpod's `GoogleIdpBaseEndpoint` (`loginWithCode`, §1.6).

`AccessTokenEndpoint` (`accessToken`): `list()`, `create(name, scopes, expiresAt)` →
`{token, secret}`, `revoke(id)`. (M12) The scope **`board`** (read and write in one, like
`ui:control`) allows the `board.*` MCP tools of Bugs & improvements ([09](09-mcp.md),
[16 §14](16-bugs-and-improvements.md)); it never grants admin rights, which come from the
account's email domain ([16 §9.1](16-bugs-and-improvements.md)).
