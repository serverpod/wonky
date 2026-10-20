# 10 · AI Assistant

Every app includes an **Assistant** side panel (v2: Write, Sheets, Slides in their editors;
Drive in its home, P1) powered by a large language model from
**OpenAI, Anthropic or Google Gemini**. All model calls happen on the **server** (API keys
never reach clients). The assistant acts on documents through the **same tool layer as MCP**
([09-mcp.md](09-mcp.md)), so anything it does is permission-checked, attributed
(`actorKind: ai`) and undoable as one step.

> **Bugs & improvements has its own AI** (M12): Jev (decisions: vetting, labels, duplicates) and
> Gemini (writing: titles, summaries, bundles, contributor prompts, PR reviews) run on the
> internal keys `internalJevApiKey` and `internalGeminiApiKey`, with their own usage table
> (`board_ai_usage`) and daily budgets. It never uses the keys, budgets or opt-out of the
> assistant below, and the assistant never uses the internal keys or gets the `board.*` MCP
> tools ([16 §6](16-bugs-and-improvements.md)).

## 1. Model and API usage

- The server talks to the providers through **`package:dartantic_ai`** (3.4.x, pure Dart;
  it wraps `openai_dart` (Chat Completions), `anthropic_sdk_dart` (Messages) and
  `googleai_dart` (Gemini)). Our code depends only on the provider-agnostic
  `AiModelClient` interface (`platform/ai/llm/ai_client.dart`): `DartanticAiClient` in
  production, `FakeAiModelClient` in tests. Messages are dartantic `ChatMessage`s
  (text / tool-call / tool-result parts), which is also the stored history format.
- **Providers and keys.** Server keys are Serverpod passwords: `openaiApiKey`,
  `anthropicApiKey` (unchanged name), `geminiApiKey` (`config/passwords.yaml` or
  `SERVERPOD_PASSWORD_<name>`). `wonky: ai: provider` picks the provider when several keys
  are set; otherwise the first with a key in the order Anthropic → OpenAI → Gemini.
- **User keys** (*Settings › AI providers*). When the server has **no key at all** (and
  `ai.allowUserKeys` is on, the default), each user can add their own key: pick the provider,
  paste the key. Resolution per request: **server key > the user's key > none** (`AiKeys`).
  The key is stored server-side in the `ai_user_key` table (one row per user, a
  `serverOnly` model, so the class does not exist in the client), used only for that user's
  requests, never logged and **never returned** — clients see only the provider and the last
  four characters (`AiProviderKeyView`). It is not encrypted at rest (no encryption helper
  exists; see [13 §2](13-security-and-operations.md)). Users can replace or remove it; a server
  that has its own key refuses personal keys.
- **Models.** "AI quality" maps to a model size and effort:
  | Setting | Model | Effort |
  |---------|-------|--------|
  | Best (default) | `model` | `high` |
  | Balanced | `model` | `medium` |
  | Fast | `fastModel` | `low` |
  Defaults per provider (`AiModels`, the only place with model ids; `ai.models.<provider>`
  overrides them): Anthropic `claude-opus-5-5` / `claude-haiku-5-5`, OpenAI `gpt-5` /
  `gpt-5-mini`, Gemini `gemini-3.1-pro-preview` / `gemini-3.8-flash` (the 2.5 models return 404 for new keys). Inline completions use the fast
  model. Effort is sent to OpenAI as `reasoning_effort`; dartantic has no effort option for
  Anthropic and Gemini, which use their model defaults. No `temperature`/`top_p`.
- **Streaming** for every request; `maxTokens` 64000 (chat), 32000 (inline/proofread),
  8000 (continue). The server accumulates the dartantic stream (`AiStreamAccumulator`: text
  and reasoning deltas, tool calls merged by id, cumulative usage) and relays text deltas and
  tool activity to the client over a Serverpod stream. Reasoning text a provider streams is
  shown as progress notes.
- **Tool use**: tools are generated from the MCP tool registry (same JSON schemas) and passed
  to dartantic as tool definitions, but **never executed by dartantic**: the assistant loop
  executes every call through the `ToolExecutor` (validation, permissions, destructive-change
  confirmation, undo grouping), runs parallel calls concurrently and returns all results in
  one user message. Tool choice is the provider default (auto).
- **Stop reasons** (normalized, `AiStopReason`): `end_turn`, `tool_use` (loop), `max_tokens`
  (offer "Continue"; a cut-off tool call is never executed), `refusal` (content filter /
  recitation, or an SDK refusal error: "The assistant can't help with that request.").
- **Prompt caching**: the request keeps a stable prefix (tools sorted → frozen system prompt →
  document snapshot → conversation; volatile data at the end of the latest user turn) so
  provider-side automatic caching works; OpenAI gets `prompt_cache_key` = the thread. Explicit
  Anthropic `cache_control` breakpoints are not available through dartantic.
- **History**: transcripts are append-only (never edit earlier turns; provider metadata such
  as Gemini thought signatures is stored with the turn and replayed). New context (the document
  changed) is appended as a new user turn element, not by rewriting history. Threads stored
  before the provider switch (raw Anthropic blocks) are converted on load (`AssistantHistory`);
  their thinking blocks are dropped.
- **Limits & cost control**: per-user daily token budget (config), per-request timeout 10 min
  (3 min idle), concurrency 2 requests per user. Retries (429/5xx/connection) are the provider
  SDKs'. Usage stored in `AiUsage` table (userId, model, input/output/cache tokens, at); cache
  token counts are not reported through dartantic (0). (CQ-31) Today's usage is one `SUM` query
  per check; each assistant run stops before a model request once it used `maxRunTokens`
  (default 600k budget tokens, error code `run_budget`); proofreading checks the daily budget
  and the run cap between sections; the history sent per request is fitted to
  `historyTokenBudget` (default 100k estimated tokens, `AssistantHistory.fit`): tool results
  over 400 characters in exchanges older than the last two are replaced by a note, then the
  oldest exchanges between the first (the document snapshot) and the last are left out; inline
  AI text fields are capped at 50,000 characters (`tooLarge`). Concurrency slots are taken
  last, after everything that can fail, and `beginRun`/`endRun` are paired in `try/finally`.
- **Untrusted text**: document, cell, slide, post and pull request contents are delimited with
  `UntrustedText.wrap`/`escape` (`platform/ai/untrusted_text.dart`): opening and closing tags
  of the delimiter inside the content are defused (`<\/document>`), the same rule in Write,
  Sheets, Slides and the board.
- **Privacy**: AI is opt-out per user (Settings → AI) and can be disabled server-wide
  (`config: ai.enabled`). The panel shows a notice naming the provider content is sent to.

### 1.1 What the Anthropic-only client did that dartantic does not (accepted)

Adaptive thinking with `display: "updates"` progress notes, `output_config.effort` for Claude,
server-side refusal fallbacks (`fallbacks: "default"`) and the `refusal` stop reason (an
Anthropic refusal now arrives as an ordinary, usually empty, answer), explicit
`cache_control` breakpoints and cache token accounting, `strict` / `eager_input_streaming`
tools, `is_error` on tool results (errors are JSON with `code`/`message`), a configurable
Anthropic `baseUrl`, and our own retry policy honouring `retry-after`.

## 2. Server components (`wonky_server/lib/src/platform/ai/`)

| File | Responsibility |
|------|----------------|
| `llm/ai_client.dart`, `llm/dartantic_ai_client.dart` | `AiModelClient` interface and its `dartantic_ai` implementation (OpenAI, Anthropic, Gemini), stream accumulation, error mapping. |
| `ai_config.dart`, `ai_keys.dart` | Config (`wonky: ai:`), server keys, user keys, key resolution (server > user > none). |
| `assistant_service.dart` | Agent loop: build request, stream, execute tools via `ToolExecutor`, loop until `end_turn`. One loop = one undo transaction for the user ("AI: …"). For spreadsheets and decks each mutating call is a recorded RevLog server change (`submitServerChange`, `actorKind: ai`, one op group per call; [17](17-revlog-sync.md) part 5 §8), and the run's records are combined into one composite record (`SheetsChanges.composite`, `SlidesCompositeChanges.composite`), so *Undo* reverts the whole run. Suggest mode plans against a shadow of the leased headless model (`SheetsShadows`, `DeckOverlays`) and records the calls instead of committing them; *Apply* submits the selected calls as server changes. |
| `context_builder.dart` | Builds document context: Write → Markdown of doc (or outline + selected sections if > 200k tokens); Sheets → sheet list, used ranges, headers, sample rows, selection values, named ranges; (v2) Slides → deck outline (groups, slide titles, text, notes, layouts, builds summary) + the current slide's elements ([Slides 11](wonky_slides/11-mcp-and-ai.md)); Drive → the current folder's listing (names, kinds, sizes, dates), the selection, storage usage (§4 Drive). |
| `prompts/` | System prompts per app/mode, versioned constants. |
| `assistant_endpoint.dart` | Endpoint `assistant`: `chat(threadId, message, contextHints)` → `Stream<AssistantEvent>`; `listThreads(itemUuid)`, `getThread`, `deleteThread`, `stop(threadId)`. |

Models:

```yaml
class: AssistantThread
table: assistant_thread
fields:
  userId: int, relation(parent=user_profile, onDelete=Cascade)
  itemId: int?, relation(parent=drive_item, onDelete=Cascade)
  title: String
  createdAt: DateTime
  updatedAt: DateTime

class: AssistantMessage
table: assistant_message
fields:
  threadId: int, relation(parent=assistant_thread, onDelete=Cascade)
  role: String                 # user | assistant
  contentJson: String          # raw API content blocks (kept verbatim for replay)
  displayText: String          # rendered text for the UI
  toolCallsJson: String?       # summarized tool calls for the UI
  createdAt: DateTime

class: AssistantEvent           # not a table — streamed to client
fields:
  type: AssistantEventType      # textDelta, toolStarted, toolFinished, error, done, usage
  text: String?
  toolName: String?
  toolSummary: String?
  error: String?
```

## 3. UI — Assistant panel (`wonky_app` `AssistantPanel`, specialized per app)

- Not configured: the panel shows "AI isn't configured on this server" and, when the server
  has no key, *Add an API key* (`assistant.addApiKey`), which runs `shell.settings.open
  {section: ai-providers}`. Inline AI entry points stay visible but disabled, with the server's
  message ("… Add your own … API key in Settings › AI providers …") as the reason.
- Toggle: its icon in the side panel rail (there is no title-row or toolbar ✨ button),
  *Tools › Assistant*, *View › Panels › Assistant*, `Mod+J` (contextual binding: in Write, inside
  an empty paragraph `Mod+J` opens the inline AI prompt instead — see suite 08 §1.2). Right side
  panel in the shared panel host (suite 02 §4.5: shared width 300–640 px, collapses to the icon
  rail); the rail shows it only when the assistant is available.
- Header: thread picker (dropdown of threads for this file + "New chat"), ⋮ (Clear, Delete thread,
  Settings).
- Message list: user bubbles, assistant Markdown rendering (code blocks with copy), **tool
  activity chips** ("Edited 3 paragraphs", "Wrote 120 cells to Sheet1!A1:D30") with *Show* (jumps
  to and highlights the change) and *Undo* buttons.
- Composer: multiline input (Enter send, Shift+Enter newline), context chips ("Selection: 2
  paragraphs", "Sheet1!B2:F40") that can be removed, *Stop* button while streaming, quick
  prompts row.
- **Apply mode** toggle: *Edit directly* (tools mutate the doc) vs *Suggest* (Write: changes
  arrive as suggestions in suggestion mode; Sheets: changes are previewed in a diff dialog with
  Accept/Reject).

### 3.1 Assistant in Slides and Drive (v2)

- **Slides**: the panel in the editor's side panel rail like Write/Sheets; apply modes *Edit
  directly* / *Suggest* (Slides previews changes as a diff of slides before applying); tools =
  `slides.*` headless tools bound to the open deck. Features (generate a deck from a prompt,
  outline or Write document, rewrite text, design/layout suggestions, speaker notes, alt text,
  "make it a code walkthrough"): [Slides 11](wonky_slides/11-mcp-and-ai.md).
- **Drive (P1)**: the Drive home has no editor rail; the assistant opens in the home's right
  panel host (the one the details panel uses) from a ✨ icon button in the top bar (Drive only),
  `Mod+J` or *Assistant* in the palette (`shell.ai.togglePanel`). Threads are **drive-scoped**
  (`AssistantThread.itemId = null`, one list per user). Tools: `drive.search`,
  `drive.list_folder`, `drive.get_item`, `drive.get_storage`, `drive.download_file` (text
  only), `drive.create_folder`, `drive.move`, `drive.rename`, `drive.star`, `drive.copy`,
  `drive.convert_file`, `drive.create_document` / `create_spreadsheet` / `create_presentation`,
  `drive.trash` (destructive-change confirmation, §1). Never: delete forever, empty trash,
  sharing (13 §1). Quick prompts: "Find my files about …", "Organize this folder by topic",
  "Summarize this file" (text files; PDFs P2 — no server-side PDF text extraction yet), "What
  takes up my storage?", "Make a document from these notes". Each run is one undo step on the
  shell stack (moves/renames/trash/creations undo together).

## 4. Inline AI entry points

### Write
- Selection floating toolbar → ✨ menu: *Improve writing*, *Fix spelling & grammar*, *Make
  shorter*, *Make longer*, *Change tone ▸ (Professional, Casual, Friendly, Confident)*,
  *Summarize*, *Translate ▸*, *Explain*, *Continue writing*, *Custom…*.
- Empty paragraph: type `/ai` (slash menu) or `Mod+J` → inline prompt box under the caret;
  result streams into a preview block with *Insert*, *Replace*, *Try again*, *Discard*.
- *Tools › Summarize document*, *Generate outline*, *Proofread document* (opens results list in
  the panel with per-issue Accept).

### Sheets
- Formula bar ✨ button: "Describe the formula you need" → suggested formula with explanation,
  *Insert*.
- *Explain formula* in cell context menu.
- *Data › Analyze with AI*: opens panel with prompt suggestions ("Summarize this table",
  "Find anomalies", "Create a pivot table of revenue by region", "Make a chart").
- *Fill with AI*: select a column range with some examples → AI fills the rest (preview first).
- Script editor: "Generate script", "Explain script", "Fix error".

### Slides (v2)
Selection toolbar ✨ on text boxes (rewrite, shorten, translate…), *Insert ▸ Generate slides…*,
*Speaker notes ▸ Generate*, *Alt text ▸ Generate*, layout suggestions — specified in
[Slides 11](wonky_slides/11-mcp-and-ai.md).

### Drive (v2, P1)
Item ⋮ ▸ *Ask the assistant about this file* (text files, Wonky items) opens the Drive panel with
the item as a context chip; Storage page ▸ *Ask the assistant how to free up space* (the
assistant lists candidates; it never deletes without confirmation).

## 5. Commands

`shell.ai.togglePanel`, `shell.ai.newThread`, `shell.ai.send`, `shell.ai.stop`,
`write.ai.rewriteSelection(mode)`, `write.ai.continue`, `write.ai.summarizeDocument`,
`sheets.ai.suggestFormula`, `sheets.ai.explainFormula`, `sheets.ai.fillRange`,
`sheets.ai.analyze`, (v2) `slides.ai.*` ([Slides 11](wonky_slides/11-mcp-and-ai.md)),
`drive.ai.askAboutItem {uuid}` (P1).

## 6. Implementation notes (as built)

- **Server** (`wonky_server/lib/src/platform/ai/`): `llm/` (`AiModelClient`, `AiRequest`,
  `AiResponse`, `AiApiException`, `AiCancelToken`; `DartanticAiClient` + `AiStreamAccumulator`;
  `FakeAiModelClient` + `AiScript` replay scripted turns in tests), `ai_models.dart` (the only
  place with model ids; `AiTier` = model size + effort), `ai_config.dart`, `ai_keys.dart`
  (`AiKeys.resolve`, `AiBackend`), `ai_call.dart` (`AiCall.open` = availability, budget and backend; `AiCall.send` = one turn with the concurrency slot, the usage record and refusal/provider errors mapped to `WonkyException`; `AiCall.stream` = a background run holding one slot, cancelled when the client closes the stream, failures emitted as events through `AiFailure`: every AI feature (assistant, Write inline AI and proofreading, Sheets and Slides inline AI) uses it, CQ-51), `assistant_history.dart` (stored turns, legacy
  conversion), `ai_usage_service.dart`, `assistant_tools.dart`, `assistant_service.dart`,
  `assistant_endpoint.dart`. Write parts in `wonky_server/lib/src/write/ai/`
  (`write_prompts.dart`, `write_context_builder.dart`, `inline_ai_service.dart`,
  `proofread_service.dart`).
- **Configuration**: `wonky: features: ai` + `wonky: ai:` (`enabled`, `provider`,
  `allowUserKeys`, `models: {<provider>: {model, fastModel}}`, `dailyTokenBudget`,
  `maxConcurrentRequests`, `requestTimeoutMinutes`, `maxToolRounds`, `historyTokenBudget`,
  `maxRunTokens`) in
  `config/<runMode>.yaml`, env overrides `WONKY_AI_*`; the keys are the passwords
  `anthropicApiKey`, `openaiApiKey`, `geminiApiKey`. Without any key `assistant.getStatus`
  reports `reason: notConfigured` with `userKeysAllowed: true`, and the apps offer *Add an API
  key* (Assistant panel, Settings › AI) leading to Settings › AI providers.
- **Request shape**: system prompt as a dartantic system message, tools as dartantic tools
  (never executed by dartantic), OpenAI: `max_completion_tokens`, `reasoning_effort`,
  `stream_options.include_usage`, `prompt_cache_key`, `safety_identifier`; Anthropic:
  `max_tokens`, `metadata.user_id`; Gemini: `maxOutputTokens`.
- **Tools**: MCP names contain dots, which the providers do not allow: `write.get_document` is
  sent as `write_get_document`. Schemas are the MCP schemas minus the bound keys
  (`document_uuid`, `uuid`, `mode`); the `ToolExecutor` validates every input against the
  original schema. `comments.reply` is checked to target a thread of the open file.
  Accept/reject suggestion tools are only listed for Editors+.
- **Caching**: tools (sorted) → system → the frozen document snapshot in the thread's first
  user turn → conversation, so no stored message is ever edited and provider-side prefix
  caches stay valid. "Document updated" elements carry the changed sections' Markdown.
- **Endpoint** `assistant`: `getStatus`, `setQuality`, `chat(threadId?, itemUuid, message,
  hints)`, `stop(threadId?, runId?)`, `confirm(runId, confirmationId, allow)` (destructive
  guard), `listThreads(itemUuid)`, `getThread`, `deleteThread`, `clearHistory`,
  `revertChange(changeId)` (panel Undo fallback), `inline(InlineAiRequest)`,
  `proofread(itemUuid, start?, length?)`, `setProviderKey(provider, apiKey)` and
  `removeProviderKey()` (Settings › AI providers; both return the status, which carries
  `provider`, `keySource` (`server`/`user`), `userKeysAllowed` and `userKey` = provider + last
  four characters). `AssistantEventType`: `started`, `textDelta`,
  `progress`, `toolStarted`, `toolFinished`, `confirmationRequired`, `usage`, `maxTokens`,
  `refusal`, `error`, `done`. Extra tables: `ai_user_setting` (quality); `assistant_message`
  adds `visible`, `replay`, `runId`, `stopReason` (`contentJson` = a dartantic `ChatMessage`
  JSON object; legacy rows hold Anthropic block arrays); `assistant_thread` adds the last context
  revision/Markdown; `ai_user_key` (server-only: userId unique, provider, apiKey, timestamps).
- **Budget**: input + cache writes + output + cache reads ÷ 10 per UTC day; concurrency per user
  is in memory per server instance. `stop` and `confirm` reach a run on another instance as
  relayed signals ([13 §4](13-security-and-operations.md)).
- **Client**: shared panel in `packages/wonky_app/lib/src/assistant/` (`ShellAssistant`
  implements `AssistantHook`, `AssistantController`, `AssistantPanel`, `AiSettingsSection`,
  `AiProvidersSection` (Settings › AI providers, section id `ai-providers`, opened with
  `shell.settings.open {section: ai-providers}` via `openAiProviderSettings`),
  `AssistantDocumentAdapter` for app specialization, `FakeAssistantApi` in
  `package:wonky_app/testing.dart`). Write: `wonky_write/lib/features/ai/`.
- **Slides (v2, SL-43)**: `SlidesAssistantTarget` (`wonky_server/lib/src/slides/ai/`) for
  presentations; `AssistantToolset.of(bindMode: false, strip: {'force'})` (Slides' `mode`
  arguments are the tools' own), `deck` is a bound key; hints `slidesCurrentSlide`,
  `slidesSelectedSlides`, `slidesSelectedElements`; chips' Show uses `range` = slide id and
  `objectId` = element id. App adapter `wonky_slides/lib/features/ai/slides_assistant_adapter.dart`.
  Details: [Slides 11 §6.12](wonky_slides/11-mcp-and-ai.md). The Drive assistant (§3.1, P1) is not
  built yet (`TODO.md`).
