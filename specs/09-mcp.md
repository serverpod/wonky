# 09 · MCP — Model Context Protocol Integration

Wonky Work is **fully controllable through MCP**. There are two layers, served by **one MCP
endpoint** on the Serverpod server:

1. **Headless tools** — operate on drive items, documents, spreadsheets, (v2) presentations and
   uploaded files directly on the server (no app needs to be open). Namespaces: `drive.*`,
   `write.*`, `sheets.*`, `slides.*` (v2), `comments.*`, `versions.*`.
2. **UI bridge tools** — drive a **live app window** (web or desktop) of the same user:
   navigate, read UI state, invoke any command, operate dialogs, take screenshots. Namespace
   `ui.*`. Tool calls are relayed from the server to the chosen app session over a Serverpod
   stream.

Both layers enforce exactly the same permissions as the human UI, record `actorKind: mcp`, and
land on undo stacks as described in [08-commands-and-undo.md](08-commands-and-undo.md) §3.4.

## 1. Server hosting

- Library: **`mcp_dart`** (latest 2.x; supports MCP 2025-11-25 and 2026-07-28 protocol
  profiles, Streamable HTTP server transport, tools/resources/prompts, auth hooks).
- Endpoint: `POST/GET/DELETE https://<host>/mcp` (Streamable HTTP) on the Serverpod **web
  server** (port 8082 in development; the apps' origin in production).
- **Decision (implemented):** a custom `mcp_dart` `Transport` behind a Relic route —
  `McpRoute` → `McpHttpHandler` → `McpExchangeTransport`
  (`wonky_server/lib/src/platform/mcp/`). `mcp_dart`'s `StreamableHTTPServerTransport`
  needs a `dart:io` `HttpRequest`, which Relic does not expose, so the route parses the
  JSON-RPC body itself and delivers it to an `mcp_dart` `McpServer`; responses are matched
  back by JSON-RPC id. The protocol layer (version negotiation, `initialize`,
  `server/discover`, lists, pings) stays `mcp_dart`'s:
  - **MCP 2026-07-28 (stateless):** a POST without `Mcp-Session-Id` that is not
    `initialize` gets a fresh `McpServer` for that one request.
  - **Initialize-era (2025-11-25 and earlier):** `initialize` creates a session
    (`Mcp-Session-Id` response header, in-memory map, 60 min idle expiry, max 20 per user,
    bound to the token that created it); `DELETE` ends it; `GET` opens an event stream
    (SSE, keep-alive comments) for server notifications. With several instances the
    session is also registered in Redis, so any instance can resume it
    ([13 §4](13-security-and-operations.md)).
  - Responses are `application/json` (SSE only when the client does not accept JSON);
    request-related progress/log notifications are dropped; JSON-RPC batches and
    `subscriptions/listen` are refused.
  - The route runs on an internal Serverpod session (Serverpod's web-call session would
    pass the bearer header to the JWT handler).
- DNS-rebinding protection: `wonky: mcp: allowedHosts` / `allowedOrigins` in
  `config/<runMode>.yaml` (defaults: the configured public hosts + loopback, and
  Serverpod's `allowedOrigins`). Requests without `Origin` (non-browser clients) are
  allowed; browser origins must match (CORS headers only for them).
- A **stdio shim** is also provided for local clients that only support stdio:
  `dart run wonky_mcp_stdio --url https://host/mcp --token $WONKY_TOKEN` (package
  `packages/wonky_mcp_stdio`), which simply proxies stdio ↔ Streamable HTTP.

## 2. Authentication & authorization

- **Personal access tokens** (Settings → Developer/MCP), sent as `Authorization: Bearer
  wkpat_…`. Tokens have scopes:
  | Scope | Grants |
  |-------|--------|
  | `drive:read` / `drive:write` | Drive listing/search, (v2) file downloads and storage usage / create, rename, move, trash, share, (v2) upload and convert files |
  | `write:read` / `write:edit` | Read documents / edit documents & comments |
  | `sheets:read` / `sheets:edit` | Read spreadsheets / edit spreadsheets |
  | `slides:read` / `slides:edit` | (v2) Read presentations / edit presentations ([Slides 11](wonky_slides/11-mcp-and-ai.md)) |
  | `scripts:run` | Run Sheets scripts/macros |
  | `ui:control` | Use `ui.*` bridge tools |
  | `board` | (M12) Use the `board.*` tools of Bugs & improvements: read, post, vote, comment, claim (read and write in one scope; no admin rights, [16 §14](16-bugs-and-improvements.md)) |
- OAuth 2.1 (authorization code + PKCE, with Protected Resource Metadata) is a later milestone;
  `mcp_dart`'s server auth hooks are used so it can be added without changing tools.
- Every tool call resolves the token → user → effective role on the target item; the tool is
  rejected with an MCP error (`isError: true`, code `forbidden`) if insufficient.
- Rate limits: 600 requests/min per token for `tools/call`, `resources/read`,
  `resources/list` and `prompts/get` together (`wonky: mcp: rateLimitPerMinute`; counted in
  Redis across instances, [13 §4](13-security-and-operations.md)); over it, tool calls fail
  with `rate_limited` and the other requests get HTTP 429 with `Retry-After`. Large reads are
  paginated.
- Request size: `McpRoute` answers from the headers alone — MCP disabled, `Host`/`Origin` not
  allowed, no well-formed `Authorization: Bearer …` header, or a declared `Content-Length`
  over 16 MB — before it reads the body, so refused requests never buffer one. Bodies are
  capped at 16 MB while reading (a 10 MB inline `drive.upload_file` as base64 plus the
  JSON-RPC envelope).
- `tools/list` only lists the tools the token's scopes allow; `ToolExecutor` checks scopes
  again on every call. The web apps' auth cookie is never accepted on `/mcp`.

## 3. Package structure

| Package / folder | Content |
|------------------|---------|
| `wonky_core/lib/mcp/` | Tool **definitions** (name, description, JSON schema, result schema) shared by server, apps and the AI assistant. One file per namespace. |
| `wonky_server/lib/src/platform/mcp/` | `McpRoute`/transport, auth, `ToolExecutor` (dispatch by name), `UiBridgeHub` (session registry + relay). |
| `wonky_server/lib/src/write/mcp/`, `…/sheets/mcp/`, (v2) `…/slides/mcp/` | Headless tool **implementations** per app (drive file tools in `platform/mcp/` with the other `drive.*` tools). |
| `wonky_app/lib/mcp_bridge/` | Client side of the UI bridge (shared `ui.*` tools). |
| `wonky_write/lib/mcp/`, `wonky_sheets/lib/mcp/`, (v2) `wonky_drive/lib/mcp/`, `wonky_slides/lib/mcp/` | App-specific `ui.*` extensions (e.g. `ui.write.get_selection`, `ui.drive.get_selection`). |

Tool naming: `namespace.verb_noun` in snake_case (e.g. `sheets.set_values`). Names are part of
the public API — never rename; deprecate instead.

## 4. Shared headless tools

### drive.*
| Tool | Args | Result |
|------|------|--------|
| `drive.search` | `query?, kind?, folder_uuid?, owned_by_me?, shared_with_me?, starred?, modified_after?, limit, cursor`; (v2) `kind` adds `presentation`, `file`; `file_category?` (`image`, `pdf`, `text`, `audio`, `video`, `archive`, `document`, `spreadsheet`, `presentation`, `other`) | items |
| `drive.list_folder` | `folder_uuid?` (null = root), `limit, cursor`; (v2) `kinds?`, `file_category?` | items (v2: files carry `mime_type`, `file_category`, `size_bytes`, `upload_state`) |
| `drive.get_item` | `uuid` | item + role + path + sharing summary |
| `drive.create_folder` | `name, parent_uuid?` | item |
| `drive.create_document` | `name, parent_uuid?, markdown?, template_uuid?` | item |
| `drive.create_spreadsheet` | `name, parent_uuid?, template_uuid?, sheets?: [{name, values?}]` | item |
| `drive.create_presentation` (v2) | `name, parent_uuid?, template_uuid?, outline?` | item ([Slides 11](wonky_slides/11-mcp-and-ai.md)) |
| `drive.rename` · `drive.move` · `drive.copy` · `drive.trash` · `drive.restore` · `drive.star` | … | item |
| `drive.share` | `uuid, email, role, notify?, message?` | permission |
| `drive.unshare` | `uuid, email` | ok |
| `drive.set_link_sharing` | `uuid, mode: off|viewer|commenter|editor` | link |
| `drive.export` | `uuid, format` | `{download_url, expires_at}` (signed, 15 min) — or inline text for md/txt/csv; (v2) presentations: `pdf` |
| `drive.import` | `name, kind, format, content_base64 \| text, parent_uuid?` | item (+ `storage`) |
| `drive.upload_file` (v2) | `name, parent_uuid?, content_base64 \| text, mime_type?` — inline content ≤ 10 MB | file item (+ `storage`); server-sniffed `mime_type` ([Drive 02 §5](wonky_drive/02-files-uploads-previews.md)) |
| `drive.create_upload` (v2) | `name, size_bytes, parent_uuid?, mime_type?` — for larger files (≤ 50 MB) | `{item_uuid, upload_url, method: PUT, headers, expires_at}` (signed, 15 min; the client PUTs the bytes) |
| `drive.complete_upload` (v2) | `item_uuid` | file item (+ `storage`) |
| `drive.download_file` (v2) | `uuid, as?: text \| base64 \| url` (default: `text` for text files ≤ 1 MB, `base64` for other files ≤ 2 MB, else `url`) | `{text}` / `{content_base64, mime_type}` / `{download_url, expires_at}` |
| `drive.convert_file` (v2) | `uuid, target: document \| spreadsheet, options?` | new item ([Drive 02 §7](wonky_drive/02-files-uploads-previews.md)) |
| `drive.get_storage` (v2) | — | `{quota_bytes, used_bytes, reserved_bytes, available_bytes, over_quota, by_kind: {documents, spreadsheets, presentations, files, trash}}` |

(v2) **Quota in results and errors.** Every tool that adds bytes (`drive.upload_file`,
`drive.complete_upload`, `drive.import`, `drive.convert_file`, `drive.copy`, `drive.create_*`
from a template or with content, `write.insert_image`-style tools, `slides.*` image tools)
returns `storage: {used_bytes, quota_bytes, available_bytes}`; a refusal is an error with code
`quota_exceeded` and `details: {needed_bytes, available_bytes, quota_bytes,
charged_user: {id, name}, reason}` ([Drive 03 §7.1](wonky_drive/03-storage-quota.md)). Tool
descriptions tell agents to check `drive.get_storage` before large uploads and never to delete
files to make room without the user asking.

(v2) **As built (D-15).** Definitions in `wonky_core/lib/mcp/drive_tools.dart`, handlers in
`wonky_server/lib/src/platform/mcp/drive_file_tool_handlers.dart` (registered through
`DriveToolHandlers.all`):
- `drive.search` takes `kind` and `kinds` (merged) and `file_category`; `drive.list_folder`
  takes `kinds` and `file_category` (it restricts `file` items only). Items carry
  `counted_bytes`, and files `mime_type`, `file_category`, `upload_state`, `file_meta`.
- `drive.upload_file` runs the app's upload lifecycle on the server (`createFileUpload` →
  store → `completeFileUpload`; sniffing, "Keep both" numbering, rate limits, reservation);
  exactly one of `text` (stored as UTF-8) / `content_base64`; over 10 MB → `too_large`
  (pointing to `create_upload`) before decoding. On any failure the upload is cancelled.
- `drive.create_upload` answers `{item_uuid, item, upload_url, method: PUT, headers:
  {Content-Type: application/octet-stream}, max_bytes, expires_at, storage}`; the URL is the
  token route `PUT /files/upload/<fileUuid>?t=` (Drive 02 §3.3). `drive.complete_upload`
  answers `conflict` (`details.expected_bytes`) when no bytes were received yet, leaving the
  upload open (the endpoint would fail and delete it); only the uploader sees the upload
  (`not_found` for others).
- `drive.download_file` needs Viewer+ and, for viewers/commenters, `nonEditorsCanExport`
  (every `as`, like `drive.export`); text is decoded with the encoding recorded at upload
  (`utf-8`, `utf-16le/be`, `latin1`); documents/spreadsheets → `invalid_args` pointing to
  `drive.export`; uploads in progress → `conflict`. `drive.export` refuses files
  (`invalid_args` → `download_file`) and folders (presentations: `pdf`, `md` since SL-40).
- `drive.convert_file {uuid, target, name?, parent_uuid?, format?, options?}` →
  `{item, warnings, storage}` (Drive 02 §7.2: the file's folder or My Drive).
- `drive.get_storage` → the fields above plus `max_file_upload_bytes`, `calculating` and
  `counts {documents, spreadsheets, presentations, files, folders}`.
- `storage` is `{used_bytes, quota_bytes, available_bytes, over_quota}` of the **caller** (an
  image charged to another owner does not reveal that owner's usage); it is returned by
  `upload_file`, `complete_upload`, `create_upload`, `convert_file`, `import`, `copy`,
  `create_document`, `create_spreadsheet` and `write.insert_image` (when it stores an image).
  `quota_exceeded` details: `{needed_bytes, available_bytes, quota_bytes, charged_user: {id,
  name}, is_caller, reason}` (`McpToolException.quotaDetails`).
- (SL-40) `drive.create_presentation {name, parent_uuid?, template_uuid?, theme?, size?, appearance?,
  outline_markdown?}` → `{item, deck_uuid, url, slide_ids, change_id, sync_version, warnings, storage?}`
  (defined in `wonky_core/lib/mcp/slides_tools.dart`, handled in `wonky_server/lib/src/slides/mcp/`);
  `drive.export` of presentations: `pdf` (as `slides.export_pdf`) and `md` (the deck outline, inline). The
  `slides:read` / `slides:edit` scopes gate the `slides.*` tools ([Slides 11](wonky_slides/11-mcp-and-ai.md)
  §3 as built); `changes.revert` covers deck changes.

### comments.*
`comments.list(uuid, status?)`, `comments.create(uuid, anchor, body)` (anchor formats per app:
Write `{quote, occurrence?}` or `{start, length}`; Sheets `{sheet, a1}`; (v2) Slides `{slide}`
or `{slide, element}`, Slides 11), `comments.reply`,
`comments.resolve`, `comments.reopen`, `comments.delete`.

### versions.*
`versions.list(uuid)`, `versions.name_current(uuid, name)`, `versions.get(uuid, version_id,
format)` (Write: markdown; Sheets: values JSON for a range), `versions.restore(uuid, version_id)`.

### changes.*
`changes.revert(change_id)` — reverts a previous headless tool change (24 h window): only the
token user's own changes, with Editor+ on the item, not reverted yet. Spreadsheets and decks
revert the record's RevLog ops ([17](17-revlog-sync.md) part 5 §8.2).

### board.* (M12)
Scope `board`; definitions in `wonky_core/lib/mcp/board_tools.dart`, handlers in
`wonky_server/lib/src/platform/mcp/board_tool_handlers.dart`. They call the same services as
`BoardEndpoint`, as the token's user, so the board's access rules, blocks, rate limits and AI
vetting apply ([16](16-bugs-and-improvements.md)). Post and comment text is untrusted user
content in results.

`board.list_posts` (filters, `query`, sort, `limit`, `cursor`), `board.get_post(number)`,
`board.list_tasks`, `board.get_task(number)` (the full contributor prompt; for the claimant also
the claim code and the two PR description lines), `board.create_post` (no screenshot; look for
similar posts first), `board.vote`, `board.comment`, `board.claim_task`, `board.release_task`.
Admin tools (`board.moderate`, `board.create_task`, `board.set_prompt`, `board.publish_task`)
are P1 and not built.

The in-app assistant ([10](10-ai-assistant.md)) does not get the `board.*` tools.

App-specific headless tools are listed in each app's MCP spec:
[Write 09 · MCP and AI](wonky_write/09-mcp-and-ai.md),
[Sheets 12 · MCP and AI](wonky_sheets/12-mcp-and-ai.md),
(v2) [Slides 11 · MCP and AI](wonky_slides/11-mcp-and-ai.md) — the `slides.*` namespace
(create decks, add/update slides and elements, set text, insert linked Sheets charts, set
builds and transitions, code states, export PDF, `slides.revert_change`) built on the headless
deck of `wonky_slides_core`. Drive has no namespace of its own beyond `drive.*` above.

## 5. Resources & prompts

- Resources: `wonky://drive/recent`, `wonky://doc/<uuid>` (Markdown, `text/markdown`),
  `wonky://sheet/<uuid>/<sheetName>` (CSV of used range, `text/csv`),
  `wonky://doc/<uuid>/outline`, (v2) `wonky://file/<uuid>` (text files ≤ 1 MB as text, other
  files ≤ 2 MB as blob), `wonky://deck/<uuid>` (outline of a presentation as Markdown, Slides 11),
  `wonky://drive/storage` (usage JSON). Resource templates registered for each. (v2, as built:
  `DriveMcpContent` in `platform/mcp/drive_mcp_content.dart`; files over the limits are refused
  with a pointer to `drive.download_file` `as: url`; the `wonky://file` template lists the 50
  most recently modified files.) Subscriptions emit
  `notifications/resources/updated` when content changes (debounced 2 s) — *not yet
  implemented* (§7).
- Prompts: `summarize_document`, `review_document`, `analyze_sheet`, `build_dashboard` — thin
  templates that reference resources.

## 6. UI bridge

### 6.1 Transport
```
UiBridgeEndpoint.connect(Stream<UiBridgeMessage> fromApp) → Stream<UiBridgeMessage> toApp
```
- Each running app window opens this stream after sign-in **if** the user has enabled
  "Allow MCP to control this window" (Settings → Developer; default **on** in development,
  **off** in production builds; remembered per device).
- On connect the app sends `UiBridgeHello {app, deviceLabel, platform, route,
  openItemUuid, title, focused, tools}` and gets `UiBridgeWelcome {sessionId}`; it reports
  route / open item / window focus changes with `UiBridgeStatus` (debounced 200 ms). The
  `UiBridgeHub` registers windows in memory on the instance serving their stream; with
  several instances `ui.*` calls reach windows on other instances over `session.messages`
  (listing and call relay, [13 §4](13-security-and-operations.md)).
- MCP tool `ui.*` call → hub picks the target session (explicit `session_id` or the user's
  most recently focused window) → sends `UiBridgeRequest {requestId, tool, args}` → app executes
  → returns `UiBridgeResponse {requestId, result | error}`. Timeout 30 s (configurable per tool,
  e.g. 120 s for `ui.wait_for`).
- While any `ui.*` call is active, the app shows the **MCP control pill** with *Stop*.
  *Stop* fails the running calls (`stopped_by_user`) and the hub refuses new calls to that
  window for 30 s (`UiBridgeStop {pauseMs}`); a timed-out call sends `UiBridgeCancel`.
- Errors of `ui.*` calls: `no_session` (no window allows control, or none implements the
  tool), `timeout`, `stopped_by_user`, plus the app's codes (`not_found`, `invalid_args`,
  `forbidden`, `disabled`, `unsupported`, `no_document`, (v2) `quota_exceeded`).

### 6.2 Shared `ui.*` tools

| Tool | Description |
|------|-------------|
| `ui.list_sessions` | Live app windows of the user (id, app, route, open item, focused, last active). |
| `ui.get_state` | Route, open item, mode (edit/suggest/view), selection summary, open dialog/panel, zoom, theme, online status, undo/redo labels. |
| `ui.navigate` | `route` (e.g. `/d/<uuid>`, `/settings/appearance`) or `{open_item_uuid}`. |
| `ui.list_commands` | All commands for the current context with id, title, description, args schema, enabled, checked, shortcut, menu path. |
| `ui.invoke_command` | `command_id, args` → runs via `CommandDispatcher` (source `mcp`). |
| `ui.get_menu_tree` | Full `MenuSpec` tree with enabled/checked states. |
| `ui.undo` / `ui.redo` | Same as Edit menu. |
| `ui.get_dialog` | Describes the open dialog: title, fields (id, label, type, value, options), buttons. |
| `ui.fill_dialog` | `{field_id: value}`; `ui.press_dialog_button(button_id)`. |
| `ui.close_dialog` | Esc. |
| `ui.open_panel` / `ui.close_panel` | `panel_id` (outline, find, history, assistant, …; `comments` in Sheets — Write shows comments in its margin, toggled with `shell.comments.togglePanel` via `ui.invoke_command`). In the editors `ui.close_panel` collapses the panel to the icon rail. |
| `ui.set_app_theme` | system/light/dark. |
| `ui.screenshot` | PNG of the window (`RepaintBoundary.toImage`), optional `region`/`scale`; returned as MCP image content. |
| `ui.get_semantics` | Accessibility tree dump (role, label, value, bounds) for generic inspection. |
| `ui.type_text` / `ui.press_keys` | Synthesized key events into the focused element (last resort; prefer commands). |
| `ui.wait_for` | Wait until a condition (`idle`, `synced`, `dialog_open`, `route_matches`) or timeout. |
| `ui.events` | Returns events since cursor (command invocations, route changes, errors) for polling agents. |

Dialogs are made MCP-operable by building them with a `WonkyDialogSpec` (declarative fields +
buttons) rendered by a shared `WonkyFormDialog`; custom dialogs must implement
`McpDescribableDialog` (`describe()`, `setField()`, `press()`). (v2) A custom dialog's `State`
mixes in `McpDialogRegistration` to register with the window while mounted; a dialog widget that
can't implement the interface (another package's) is shown inside an `McpDialogScope` with an
adapter. The shell's shortcuts help, spelling, personal dictionary, special characters and emoji
dialogs are describable. Side panels are read and operated with `PanelDescriber`
(`wonky_app`, used by `ui.sheets.*_panel` and `ui.slides.*_panel`).

App-specific `ui.*` tools (e.g. `ui.write.get_selection`, `ui.write.select_text`,
`ui.sheets.select_range`, `ui.sheets.get_visible_range`, (v2) `ui.slides.*` in Slides 11,
`ui.drive.*` in [Drive 04 §13](wonky_drive/04-screens-menus.md)) are listed in each app's MCP
spec. (v2: the `ui.drive.*` definitions are `UiDriveTools` in `wonky_core/lib/mcp/ui_drive_tools.dart`,
relayed by the server to windows with `app: drive`; the Drive window implements them in D-17. The
`ui.slides.*` definitions are `UiSlidesTools` in `wonky_core/lib/mcp/ui_slides_tools.dart`, relayed
to windows with `app: slides` and implemented by Slides in SL-42.) `UiBridgeHello.app` takes `drive`, `write`, `sheets`, `slides`.

## 7. Conventions for tool implementations

- Inputs are validated against the JSON schema (the `wonky_core` definitions, by
  `ToolExecutor`, so both protocol eras behave the same); errors use `isError: true` with a
  structured `{code, message, details}` text payload (`invalid_args` details:
  `[{pointer, message}]`).
- Results include machine-readable JSON (`structuredContent`) plus a short human text summary.
- Every mutating tool returns `change_id` and the new `revision`/`sync_version` where relevant.
  For spreadsheets and decks `sync_version` is the file's RevLog head revision (as a string).
  Their headless tools read through leased headless models (`HeadlessFileCache`) and write
  through `RevLogService.submitServerChange` (`actorKind: mcp`, a recorded op group): the same
  validation, protected-range check and fan-out as a client's ops, so open editors see the
  change arrive live ([17](17-revlog-sync.md) part 5 §8–§9). A protected-range rejection is the
  tool error `protected_range`.
- Large outputs are paginated (`cursor`) and capped (default 50k chars) with a `truncated` flag.
- Tool descriptions are written for LLMs: what it does, when to use it, units/addressing
  conventions (A1 notation for Sheets, 0-based Delta offsets vs. Markdown for Write), examples.
- Every tool has an integration test in the server package calling it through
  `ToolExecutor` with a token-resolved user (`test/support/mcp_harness.dart`); the route
  itself is covered end to end over HTTP (raw JSON-RPC, the `mcp_dart` client in both
  protocol profiles, and `wonky_mcp_stdio`).
- Not yet: resource subscriptions (`resources/subscribe`, `notifications/resources/updated`)
  and MCP 2026 `subscriptions/listen`; OAuth 2.1.
