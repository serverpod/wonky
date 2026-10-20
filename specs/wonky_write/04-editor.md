# Write 04 · Editor

This spec covers the Wonky Write editing surface. It describes how `super_editor` is integrated
and every editing feature and behaviour: what it does, where it is invoked, its command ids,
shortcuts, undo behaviour, MCP exposure and acceptance criteria. The chrome around the editor
(menubar, toolbar, panels, dialogs) is specified in
[05-screens-menus-toolbar.md](05-screens-menus-toolbar.md). Content semantics come from
[02-document-model.md](02-document-model.md) and sync and undo internals from
[03-sync-protocol.md](03-sync-protocol.md). Both are authoritative; this spec never contradicts
them. Where this spec needs something they do not define, it says so in §44 *Open points*.

## 1. Conventions

- **Shortcuts** use `Mod` = ⌘ on macOS and Ctrl on Windows/Linux, and `Alt` = ⌥ on macOS.
  Where the two platforms differ, the tables have a *macOS* and a *Win/Linux* column. On web,
  browser-reserved chords are never bound: ⌘/Ctrl + W, T, N, L, Shift+T, Shift+N, Tab, and
  Mod+1…9 (tab switching). On Windows, `Ctrl+Alt` equals `AltGr`. If a `Ctrl+Alt+<key>` event
  produces a printable character (`KeyEvent.character != null`), `KeymapService` must **not**
  fire the shortcut, so the character is typed.
- **Command ids** follow `write.<area>.<action>` (lowerCamelCase action), as defined in
  [suite 08](../08-commands-and-undo.md). Commands with arguments list them as
  `write.format.blockType {type}`. A key binding can carry fixed args (suite 08 §1.2).
- **Priority** tags: **P0** (v1 must), **P1** (v1 should), **P2** (later). See
  [01-overview.md](01-overview.md) §3.
- **AC-n.m** marks an acceptance criterion. Each AC must be covered by a widget test or an
  integration test (`flutter-add-integration-test` skill) before the feature counts as done.
- **Role** is the minimum role a command requires (suite 06). `V` = viewer, `C` = commenter,
  `E` = editor.
- "Transaction" means one `editor.execute([...requests])` call. "Undo step" means one
  `UndoStep` on the `UndoService` stack (suite 08 §3).

## 2. Architecture of the editor feature

### 2.1 Runtime objects (one set per open document)

```
WriteDocumentScreen
 └─ WriteDocumentController (ChangeNotifier, provided via Provider)
     ├─ MutableDocument            ← nodes (built by DeltaDocumentMapper)
     ├─ MutableDocumentComposer    ← selection, composingRegion, typing attributes
     ├─ Editor                     ← request handlers, reactions, listeners (history disabled)
     ├─ DeltaIndex                 ← Fenwick tree: Delta offset ⇄ DocumentPosition (02 §4.1)
     ├─ ChangeDeltaExtractor       ← local transactions → change Delta (02 §4.4)
     ├─ DeltaApplier               ← remote/undo/AI/MCP deltas → nodes (03 §3)
     ├─ DocumentSyncController     ← OT state machine, outbox, cursors (03 §3)
     ├─ WriteUndoHandler           ← domain write.content (03 §4)
     ├─ EditorModeController       ← editing | suggesting | viewing (§31)
     ├─ WriteEditorPlugins         ← slash (ActionTagsPlugin), mentions (StableTagPlugin), …
     ├─ Derived services           ← OutlineController, DocumentStatsService, FindController,
     │                                SpellcheckController, PaginationController,
     │                                CommentAnchorIndex, SuggestionIndex, RemotePresenceModel
     └─ EditorViewState            ← zoom, layout mode, scroll anchor
```

- `WriteDocumentController` is the only object commands talk to. `CommandContext.document`
  (suite 08) returns it. Widgets never call `editor.execute` directly. They invoke commands,
  except for raw typing and IME, which `super_editor` routes internally.
- **One `SuperEditor` per screen.** Its `inputRole` is `"write-doc-<documentUuid>"`. Any
  secondary `SuperEditor` (for example the comment composer, if it ever uses `super_editor`)
  must use a different `inputRole`.

### 2.2 `super_editor` configuration

Version: **`super_editor` vendored in `third_party/super_editor`**, based on 0.3.0-dev.52
(suite [01 §2.3](../01-architecture.md) describes the vendoring rules). Requires
`dart_quill_delta ^9.4.1` (the constraint may be relaxed in our copy). The deprecated
`super_editor_markdown` and `super_editor_quill` packages must not be added.

Because we own a local copy, gaps that belong in the library are **fixed in the library**
rather than worked around in app code. Planned patches (tracked in
`third_party/super_editor/PATCHES.md`, each upstreamed where possible):

| Patch | Change | Needed by | Milestone |
|-------|--------|-----------|-----------|
| **SE-1** | Complete Quill serialization: serializers for `HorizontalRuleNode` (`divider` embed), `TableBlockNode` (`table` embed), `BitmapImageNode`; inline `code`; `ListItemNode`/`TaskNode` `indent`; code-block language from node metadata `codeLanguage`. Makes `toQuillDeltas` usable for the mapper and `quillDocumentEquivalentTo` usable in tests. | `DeltaDocumentMapper` ([02 §4](02-document-model.md)) | M2 |
| **SE-2** | Incremental Delta application API: apply a change Delta to a `MutableDocument` by node id/offset **without going through the composer** (non-historical; local selection and composing region preserved and transformed), including attribute-only retains and block-attribute changes. | `DeltaApplier` ([03 §3](03-sync-protocol.md)) | M2 |
| **SE-3** | Detailed change events: block-type, list-type, indent, task-completion and metadata changes emit specific events with before/after values (instead of a bare `NodeChangeEvent`). | `ChangeDeltaExtractor` fast path (no line-diff fallback) ([02 §4.4](02-document-model.md)) | M2 |
| **SE-4** | Editable tables: caret and selection inside `TableBlockNode` cells, inline formatting in cells, Tab/Shift+Tab between cells, add/remove/move rows and columns, column alignment; edits reported as events that map to a `table` embed replacement. | In-place table editing (§18.4) | P1 (M5) |
| **SE-5** | Fixes found by our test suites (IME on web/Windows/Linux, RTL, large-document layout performance, keyboard handling). | All | Ongoing |
| **SE-6** | Content drag delegate: an app may take over a mouse drag that starts on content (drag and drop of the selection) instead of a new drag selection. | Drag and drop (§24) | P1 |
| **SE-7** | List markers (bullets, numerals) keep the first character's font, size, weight and color but not its background or decorations, so a comment highlight or suggestion background/strikethrough at the start of a list item doesn't paint the marker. | Comment highlights (§33), suggestions (§32.2) | done |

**Implementation status (M2)** — see `third_party/super_editor/PATCHES.md`:
- SE-1 done (plus `toQuillDeltas(omitTrailingEmptyParagraph:)`); the mapper serializes through
  `toQuillDeltas` with a Wonky `DeltaSerializer` and parses Delta lines directly (no editor round
  trips) for fast loads.
- SE-2 is a generic node-level primitive, `ApplyDocumentPatchRequest` (replace/insert/delete/move
  nodes, transformed selection + composing region, IME resync, non-historical, reactions
  suppressed). The Delta → node mapping lives in the app's `DeltaApplier`, because it depends on
  the Wonky schema.
- SE-3 done (`BlockTypeChangeEvent`, `ListItemTypeChangeEvent`, `IndentChangeEvent`,
  `TaskCompletionChangeEvent`, `NodeMetadataChangeEvent`, `NodeReplacedEvent`). The extractor
  doesn't depend on it: it re-serializes only the touched nodes (immutable nodes make unchanged
  nodes identical instances) and diffs per gap between untouched anchors, with an event fast path
  for single text insertions/deletions; marked reactions split a transaction by checkpoints
  taken *before* each marked reaction runs.
- SE-4 done as a **cell content builder** (`MarkdownTableComponent.cellBuilder`): the table stays
  one block node (the document caret never enters it); the app's `InlineTableEditing` turns the
  tapped cell into a text field over the cell's inline Markdown source (focus parented outside the
  `SuperEditor`, so its keys and IME never reach the editor) and commits each cell edit as a
  `table` embed replacement (§18.4).
- SE-6 done: `SuperEditor.contentDragDelegate` (§24).
- SE-5: list indent limit 8, list-type change keeps indent, IME resync after patches, typing over
  a selection, undo/redo action exports. `attributed_text` is vendored too
  (`third_party/attributed_text`, patch AT-1: `addAttribution` inside an existing span corrupted
  span markers).

Everything must keep working on the unpatched behavior until each patch lands (the app layers —
mapper, applier, extractor, table popover — are written against our own interfaces), so patches
can be developed in parallel with the app.

```dart
// features/editor/setup/editor_factory.dart  (sketch)
Editor buildWriteEditor(MutableDocument doc, MutableDocumentComposer composer, WriteEditorDeps d) {
  return Editor(
    editables: {Editor.documentKey: doc, Editor.composerKey: composer},
    // Our handlers FIRST so they can intercept (mode guard, suggestion rewrite, schema guard).
    requestHandlers: [
      ...wonkyModeGuardHandlers(d.mode),          // §31: block mutations in Viewing
      ...wonkySuggestionRewriteHandlers(d.mode),  // §32: rewrite requests in Suggesting
      ...wonkyCustomRequestHandlers,              // ApplyRemoteDeltaRequest, ReplaceEmbedRequest, …
      ...defaultRequestHandlers,                  // super_editor built-ins
      ...d.plugins.requestHandlers,               // ActionTags / StableTags handlers
    ],
    reactionPipeline: wonkyReactions(d.prefs),    // §41.2 (replaces defaultEditorReactions)
    listeners: [FunctionalEditListener(d.onTransaction)], // → ChangeDeltaExtractor
    isHistoryEnabled: false,                      // REQUIRED (03 §4)
  );
}
// Equivalent to createDefaultDocumentEditor(document: doc, composer: composer,
// isHistoryEnabled: false) with the handler and reaction lists replaced.
```

```dart
SuperEditor(
  editor: controller.editor,
  focusNode: controller.focusNode,
  inputRole: 'write-doc-${documentUuid}',
  inputSource: TextInputSource.ime,              // IME on every platform (§3)
  scrollController: viewState.scrollController,  // shared with the page canvas (§29)
  documentLayoutKey: controller.layoutKey,       // used by every custom layer
  stylesheet: viewState.stylesheet,              // from the theme × zoom × light/dark (06, §29.1)
  selectionStyles: SelectionStyles(selectionColor: theme.selection),
  customStylePhases: [
    PaginationStylePhase(...),      // §29.3 injected page gaps
    CodeHighlightStylePhase(...),   // §15.4
    SpellingAndGrammarStyler(...),  // §28 (super_editor built-in styler)
    FindHighlightStylePhase(...),   // §25 (text color of active match, optional)
    TextDirectionStylePhase(...),   // §38
  ],
  componentBuilders: [
    WonkyHintComponentBuilder(...),            // placeholder in an empty doc (based on HintComponentBuilder)
    WonkyImageComponentBuilder(...),           // §17 replaces ImageComponentBuilder
    WonkyTableComponentBuilder(...),           // §18 wraps MarkdownTableComponentBuilder
    WonkyCodeBlockComponentBuilder(...),       // §15 adds language chip + copy button overlay
    TaskComponentBuilder(controller.editor),   // REQUIRED when passing custom builders
    MarkdownTableComponentBuilder(),           // fallback, REQUIRED
    ...defaultComponentBuilders,
  ],
  documentUnderlayBuilders: [
    PageChromeLayerBuilder(...),        // §29 page cards, header/footer (Pages mode)
    RemoteSelectionLayerBuilder(...),   // §34
    FindMatchesLayerBuilder(...),       // §25
    MentionChipLayerBuilder(...),       // §19 rounded chip backgrounds
    BlockSelectionLayerBuilder(...),    // §22 block selection ring/fill
  ],
  documentOverlayBuilders: [
    DefaultCaretOverlayBuilder(caretStyle: CaretStyle(width: 2, color: theme.foreground)),
    RemoteCursorLayerBuilder(...),      // §34
    CommentAnchorBoundsOverlay(...),    // §33 (based on AttributedTextBoundsOverlay)
    UploadProgressLayerBuilder(...),    // §17.4
  ],
  keyboardActions: wonkyKeyboardActions(ime: true),      // §41.1
  selectorHandlers: wonkySelectorHandlers,               // macOS selectors minus undo/redo
  contentTapDelegateFactories: [WonkyLinkTapHandler.factory], // §11.6 replaces launch-on-tap
  selectionLayerLinks: controller.selectionLayerLinks,   // floating toolbar anchor (05)
  plugins: {controller.slashPlugin, controller.mentionPlugin, controller.inlineMarkdownPlugin},
)
```

`controller.inlineMarkdownPlugin` is `MarkdownInlineUpstreamSyntaxPlugin` (§7). Read-only
presentation uses `SuperReader` with the same stylesheet, component builders and
underlay/overlay layers, minus the editing layers (§31).

### 2.3 Transaction pipeline

```
 keyboard / IME / gesture / command
        │  EditRequest(s)  (one editor.execute([...]) per command → one transaction)
        ▼
 Mode guard ─► Suggestion rewrite ─► super_editor commands ─► reactions
        │                                                        │ (autoformat, schema guard)
        ▼                                                        ▼
 DocumentChangeLog (List<EditEvent>) ─► FunctionalEditListener
        ▼
 ChangeDeltaExtractor  (fast path: event mapping; fallback: line diff)  02 §4.4
   • filters attributions not in the Wonky schema (§2.5)
   • ignores transactions flagged `fromApplier`
   • splits at TransactionMarkers (§2.6) → 1..n change Deltas
        ▼
 WriteUndoHandler (coalescing §35) ─► DocumentSyncController.submitLocal(delta)  03 §3
```

### 2.4 Schema guard

`WonkySchemaGuardReaction` is the **last** reaction in the pipeline. It keeps the document
inside Wonky Delta Schema v1 ([02](02-document-model.md) §1.4) no matter which `super_editor`
feature produced the change:

| Violation (could come from built-ins or paste) | Guard action |
|---|---|
| `ParagraphNode.indent > 0` (paragraph indentation) | Reset to 0 |
| Disallowed attribution (underline, color, background, font family/size, super/subscript) | Remove |
| Inline `code` overlapping `bold/italic/strike` | Remove `bold/italic/strike` from the code range |
| List/task `indent > 8` | Clamp to 8 |
| Indent jump (item indent > previous list item indent + 1) | Clamp to previous + 1 |
| Tab characters outside code blocks | Replace with 4 spaces |
| Control characters except `\n` (code only) and U+2028 | Remove |
| U+2028 inside a code block | Replace with `\n` (code uses real lines) |
| Unsupported `blockType` attribution on a paragraph | Reset to `paragraphAttribution` |

The guard runs inside the same transaction, so its fixes are part of the same change Delta and
undo step. The server runs `WonkyDeltaNormalizer` as a backstop. The client must never rely on
it, because a server normalisation rewrites the op and costs an extra round-trip.

### 2.5 Attribution whitelist (extractor)

`ChangeDeltaExtractor` maps only these attributions to Delta attributes:
`boldAttribution`, `italicsAttribution`, `strikethroughAttribution`, inline `codeAttribution`,
`LinkAttribution`, `MentionAttribution`, `CommentAttribution`, `SuggestionAttribution`.
Everything else is **presentation-only** and is ignored. This includes ActionTags/StableTags
composing attributions (`actionTagComposingAttribution`, stable-tag composing attributions),
`spellingErrorAttribution`, code-token attributions (§15.4) and find-match attributions. A
transaction that changes only ignored attributions produces no Delta and no undo step.

### 2.6 Commands, requests and transaction markers

- Every mutating command builds a list of `EditRequest`s and executes them in **one**
  transaction. That gives one change Delta and one undo step. Example: `write.list.toggleBulleted`
  over three paragraphs issues three `ConvertParagraphToListItemRequest`s in one `execute`.
- Reactions that transform user input (Markdown autoformat §7, smart typography §8) must form
  a **separate undo step** from the keystroke that triggered them. Then `Mod+Z` right after
  `# ` restores the literal `# `. They are wrapped in `MarkedReaction(inner)`, which records
  the change-list index at which the inner reaction started in a `TransactionMarkers` editable
  (custom `Editable` registered under `"wonkyMarkers"`). The extractor splits the transaction's
  events at the markers and emits several change Deltas. The undo handler records each as its
  own step. The steps are still sent to the server as one composed op.
- Commands that need UI (dialogs, popovers) open the UI and return. The confirming button then
  invokes a second, args-complete command (for example `write.link.insert` opens the popover
  and *Apply* invokes `write.link.set {url, text}`). MCP callers use the args-complete
  variants directly.

### 2.7 Keyboard routing

1. `KeymapService` (suite 08 §1.2) gets the first chance at every key event. The first entry of
   `wonkyKeyboardActions` is `keymapDispatchAction`. It looks up the chord in scope `editor`
   (then `global`). If it finds a binding whose command `isEnabled`, it invokes the command
   with source `shortcut` and returns `ExecutionInstruction.haltExecution`.
2. **Contextual bindings.** Several commands may share a chord in the same scope, for example
   `Mod+Enter` = toggle task (in a task) and exit code block (in a code block). They are tried
   in declared order and the first enabled one runs. This is a required `KeymapService`
   feature (see §44).
3. Open-popover handlers come next (slash menu, mention picker, link popover). They capture
   ↑ ↓ Enter Tab Esc while their popover is open.
4. Then the Wonky structural actions (§41.1), then the retained `super_editor` defaults.

## 3. Typing and IME

### 3.1 Behaviour
- Characters are inserted at the caret through `super_editor`'s IME path
  (`TextInputSource.ime`, `document_ime`) on **all** platforms. This gives dead keys, CJK
  composition, the emoji panel, dictation and OS text replacement.
- New characters take the **typing attributes**: `composer.preferences.currentAttributions`,
  maintained by `WonkyTypingAttributesReaction` (§10.3).
- A non-collapsed selection is replaced by the typed character. All of this is one transaction,
  and it **starts a new** typing undo group.
- In **code blocks**, typed text never receives inline attributions.
- Max document length is 2,000,000 chars ([02](02-document-model.md) §1.4). Within 1 % of the
  limit, a persistent warning toast appears. At the limit, insertions are rejected (the
  request handler returns no command) and the toast says "This document has reached its
  maximum size".

### 3.2 IME composition rules
- The composing region (`composer.composingRegion`) is underlined by `super_editor`. Composing
  text **is** part of the document. Each composition update is a normal `TextInsertionEvent` or
  `TextDeletedEvent`, so collaborators see the in-progress text. All updates of one
  composition coalesce into one undo step.
- If a **remote op** touches the composing region, `DeltaApplier` clears the region and
  re-syncs the IME (03 §3). The user's partial composition is kept as plain committed text.
- **Undo during composition**: `shell.edit.undo` first commits the composition
  (`ChangeComposingRegionRequest(null)`) and then undoes.
- Typing attributes apply to composed text when it is inserted.

### 3.3 Typing undo coalescing
As in 03 §4 and suite 08 §3.1. Consecutive insertions in the **same node** within **1000 ms** of
each other, without a caret jump, form one step labelled "Typing". Deletions coalesce the same
way ("Delete"). A coalesced group also closes at:
- a word boundary after **≥ 50 characters** in the group (so long typing sessions undo by
  sentence-ish chunks);
- Enter (a new node);
- any command;
- a remote op that **intersects** the group's range (non-intersecting remote ops only rebase it).

### 3.4 Platform matrix (QA gate)

| Platform | IME status in `super_editor` | Release gate |
|----------|------------------------------|--------------|
| Web (Chrome, Edge, Firefox, Safari) | Supported | P0. Manual IME QA: Japanese (Kotoeri/Google), Chinese Pinyin, Korean, dead keys (US-Intl), emoji panel |
| macOS | Supported | P0. Same IME QA plus macOS text substitutions and dictation |
| Windows | Unverified upstream | P1. QA with MS-IME Japanese, Pinyin, Korean. Bugs go upstream; ship with a "known issues" note if needed |
| Linux | Unverified upstream | P1. QA with IBus (Pinyin, Anthy) |

**AC-3.1** Typing "Hello" then `Mod+Z` removes "Hello" in one step and restores the caret.
**AC-3.2** Japanese composition "にほんご" → 日本語 commits as one undo step. A collaborator sees
the final text, and no composing underline is ever sent.
**AC-3.3** A remote insertion before the caret during composition keeps the local caret and
composition visually stable (no character loss).

## 4. Selection

### 4.1 Mouse

| Gesture | Result |
|---------|--------|
| Click in text | Caret at the nearest position. Collapses the selection |
| Click on image, divider or table | Selects the whole block (block selection, §22.3) |
| Click in the empty area below the last block | Caret at the end of the last text block. If the last block is an embed, inserts an empty paragraph after it and puts the caret there (*lazy trailing paragraph*, §6.5) |
| Double-click | Selects the word (`super_editor`). In a link or mention, selects that word or the whole mention |
| Triple-click | Selects the whole paragraph or block text |
| Shift+click | Extends from the selection base to the click position |
| Drag | Selects a range. Dragging across an embed includes it whole. Autoscroll near the viewport edges (32 px zone, speed ∝ distance) |
| Double-click then drag / triple-click then drag | Extends by words / by blocks (P1) |
| Click on a checkbox | Toggles the task (§13.5). Never moves the caret |
| Mod+click on a link | Opens the link (§11.6) |
| Right-click | Moves the caret there unless the click is inside the current selection. Opens the context menu (05 §6) |
| Click in a page margin (Pages mode) | Caret on the nearest line, vertically aligned |

### 4.2 Keyboard
Shift + any caret movement (§5) extends the selection. `Mod+A` (`write.edit.selectAll`):

1. Inside a **code block** that is not already fully selected, the first press selects the code
   block content.
2. Otherwise it selects the whole document.

`Esc` with an expanded selection collapses it to the extent. With a collapsed caret it selects
the current block (§22.3).

### 4.3 Rules
- Selections may span any node types. Mixed selections that contain embeds treat each embed as
  one unit.
- The selection is a **view state**. It is never undoable, but undo and redo restore
  `selectionBefore` and `selectionAfter` (suite 08 §3.1).
- On a remote op, the local selection is transformed (`transformPosition`, 03 §3) and never
  jumps.
- Selection colour is the shad `selection` token. In an unfocused editor it uses the same
  colour at 50 % alpha.

**AC-4.1** Triple-click on a soft-wrapped paragraph selects exactly that paragraph.
**AC-4.2** Shift+click after a drag extends from the original anchor.
**AC-4.3** Clicking an image shows the block-selection ring. Backspace deletes the image in one
undo step.

## 5. Caret navigation

| Action | macOS | Win/Linux |
|--------|-------|-----------|
| Character left/right | ← / → | ← / → |
| Word left/right | ⌥← / ⌥→ | Ctrl+← / Ctrl+→ |
| Line start/end | ⌘← / ⌘→, Home / End, ⌃A / ⌃E | Home / End |
| Paragraph start/end (block) | ⌥↑ / ⌥↓ | Ctrl+↑ / Ctrl+↓ |
| Document start/end | ⌘↑ / ⌘↓, ⌘Home / ⌘End | Ctrl+Home / Ctrl+End |
| Line up/down | ↑ / ↓ (keeps the preferred x across lines) | ↑ / ↓ |
| Page up/down | PageUp / PageDown (moves the caret one viewport and scrolls) | same |
| Next/previous heading | ⌃⌥↓ / ⌃⌥↑ (P1) | Ctrl+Alt+↓ / Ctrl+Alt+↑ (P1) |

- Movement is by **grapheme cluster** (emoji ZWJ sequences, combining marks). The caret is never
  placed inside a surrogate pair or a mention (§19.3).
- **Arrow into an embed**: ↑/↓/←/→ that would enter an image, divider or table *selects the
  block*. The next press in the same direction moves past it to the adjacent text block.
- The caret is kept visible. After every keyboard movement or edit, the scroll view reveals the
  caret rect with a margin of 64 px (Pages mode: also clears the page gap).
- Word boundaries use the `characters` package plus a regex for `\p{L}\p{N}_'’` runs.
  Punctuation runs count as separate stops (Google Docs parity).
- macOS: `super_editor` selector handlers (moveWordLeft:, etc.) are kept, minus undo/redo
  selectors (§41.1).

**AC-5.1** ⌥→ (Ctrl+→) over "don't stop." stops after "don't", then "stop", then ".".
**AC-5.2** ↓ from a paragraph above an image selects the image. ↓ again puts the caret at the
start of the next paragraph.

## 6. Enter, Backspace and Delete

### 6.1 Enter / Shift+Enter by block type

| Block | Enter (caret mid/end) | Enter at start of non-empty block | Enter on empty block | Shift+Enter |
|-------|------------------------|-----------------------------------|----------------------|-------------|
| Normal paragraph | Split. The new block is a paragraph | Inserts an empty paragraph above; caret stays with the text | New empty paragraph | Soft break U+2028 |
| Heading 1–6 | At end: a **Normal** paragraph below. Mid: split, both parts stay headings | Empty **Normal** paragraph above | New Normal paragraph | Soft break |
| Quote line | New quote line (continues the quote) | Empty quote line above | Converts the line to Normal (exits the quote) | Soft break |
| Bulleted/numbered item | New item, same type and indent | Empty item above | Indent > 0: outdent one level. Indent 0: convert to Normal | Soft break inside the item |
| Task | New **unchecked** task, same indent | Empty task above | Same as list items | Soft break |
| Code block | Inserts `\n` with auto-indent (§15.2) | `\n` | Triple-Enter exit rule (§15.3) | `\n` (same as Enter) |
| Embed selected | Inserts an empty paragraph **after** and places the caret | — | — | Inserts an empty paragraph **before** |

All Enter variants are single transactions (`InsertNewlineAtCaretRequest`,
`InsertSoftNewlineAtCaretRequest`, or our custom requests). Enter closes the current typing
group (§3.3) and is its own undo step only when it changes block type (exit list or quote).
Otherwise it joins the next typing group.

### 6.2 Backspace at the start of a block

| Block | Backspace at offset 0 (collapsed caret) |
|-------|-----------------------------------------|
| Normal paragraph after a text block | Merge into the previous block. The previous block's type wins |
| Normal paragraph after an embed | Selects the embed (block selection). A second Backspace deletes it. If the paragraph is empty, the paragraph is deleted and the embed selected |
| Heading / quote line | Converts to Normal (`backspaceToClearParagraphBlockType`). The next Backspace merges |
| List item / task, indent > 0 | Outdent one level |
| List item / task, indent 0 | Converts to Normal paragraph |
| Code block | Converts the whole code block to Normal paragraphs (one per line, one undo step) |
| First block of the document | Normal paragraph: no-op. Other types: convert to Normal |

### 6.3 Delete at the end of a block
Mirrors Backspace. It merges the next text block into the current one, and the current block
type wins. If the next block is an embed, it selects the embed first.

### 6.4 Deleting a selection
`DeleteContentRequest`. The first and last partially selected text blocks merge, and the first
block's type wins. Fully covered blocks, including embeds, are removed. The document always
keeps at least one paragraph. `Mod+A` then Delete leaves one empty Normal paragraph.

Word and line deletion (`super_editor` built-ins, retained):

| Action | macOS | Win/Linux |
|--------|-------|-----------|
| Delete word backward/forward | ⌥⌫ / ⌥⌦ | Ctrl+Backspace / Ctrl+Delete |
| Delete to line start/end | ⌘⌫ / ⌘⌦ (and ⌃K to end) | — |

### 6.5 Lazy trailing paragraph and gaps between embeds
The Delta schema doesn't require the document to end with a paragraph. To avoid concurrent
duplicate insertions, the client **never** adds a trailing paragraph automatically. A paragraph
is created only when the user acts:
- clicks below a final embed;
- presses ↓/→ or Enter while the final embed is selected;
- presses Enter or Shift+Enter on a selected embed that sits between two embeds.

The creation is part of that user's transaction and undo step.

**AC-6.1** Enter on an empty indent-2 bullet makes it indent 1. Two more Enters turn it into a
Normal paragraph. Each step is one undo.
**AC-6.2** Backspace at the start of a paragraph after a table selects the table and deletes
nothing.
**AC-6.3** Selecting from mid heading to mid list item and typing "x" produces one heading
containing the merged text plus "x".

## 7. Markdown autoformat while typing

User setting **Markdown shortcuts** (`UserPreferences.writeDefaults.markdownShortcuts`, default
on; command `write.prefs.setMarkdownShortcuts {enabled}`). Autoformat is disabled inside code
blocks and inline code. Every conversion is its own undo step (§2.6). **Undo right after an
autoformat restores the literal characters** and leaves the caret after them.

### 7.1 Block prefixes (at the start of a Normal paragraph)

| Typed | Result | Implementation |
|-------|--------|----------------|
| `# `…`###### ` | Heading 1–6 | `HeaderConversionReaction` (built-in) |
| `- ` `* ` `+ ` | Bulleted item | `UnorderedListItemConversionReaction` |
| `1. ` `1) ` (any number) | Numbered item (numbering always starts at 1, see [01](01-overview.md) §4) | `OrderedListItemConversionReaction` |
| `> ` | Quote | `BlockquoteConversionReaction` |
| `[ ] ` `[] ` `[x] ` `- [ ] ` `- [x] ` | Task (checked for `x`/`X`) | **Custom** `TaskConversionReaction extends ParagraphPrefixConversionReaction` (`pattern: ^(- )?\[( |x|X)?\] $`) |
| ```` ``` ```` + optional language + space, or + **Enter** | Code block, `codeLanguage` = typed language (normalised via the alias table §15.1) | **Custom** `CodeFenceConversionReaction` (space variant) + keyboard action `enterToConvertCodeFence` (Enter variant: paragraph text equals ```` ^```[\w+#.-]*$ ````) |
| `---` `***` `___` + space or Enter | Divider. The caret goes to a new paragraph below | `HorizontalRuleConversionReaction` + custom Enter action |
| `![alt](https://…)` + space (P1) | Image embed (URL) | **Custom** `ImageMarkdownReaction` |

A prefix typed in a **list item** (for example `[ ] ` in a bullet) converts that item to a
task, keeping its indent. A heading prefix inside a list item converts it to a heading.

### 7.2 Inline syntax (upstream of the caret)

| Typed | Result | Implementation |
|-------|--------|----------------|
| `**text**` / `__text__` | **bold** | `MarkdownInlineUpstreamSyntaxPlugin` |
| `*text*` / `_text_` | *italic* (not inside words for `_`) | same |
| `~text~` / `~~text~~` | ~~strike~~ | same (verify `~~` and add a custom reaction if missing) |
| `` `text` `` | inline code | **Custom** `InlineCodeBacktickReaction` (the plugin doesn't cover code) |
| `[text](url)` | link (URL validated per §11.2) | plugin |
| URL followed by space/Enter/punctuation | link | `LinkifyReaction` (also gated by the *Autolink* setting) |

**AC-7.1** Typing `## Title` gives an H2 "Title". `Mod+Z` gives the literal "## Title"
paragraph with the caret at the end.
**AC-7.2** Typing ```` ```dart ```` + Enter gives an empty code block with language `dart`
and the caret inside.
**AC-7.3** With *Markdown shortcuts* off, none of the conversions in §7.1–7.2 happen (except
autolink, which has its own setting).

## 8. Smart typography (P1)

Setting **Smart quotes and dashes** (`writeDefaults.smartTypography`, default on;
`write.prefs.setSmartTypography {enabled}`). Never applied in code blocks or inline code, or
when the previous character is a backslash.

| Typed | Result | Notes |
|-------|--------|-------|
| `"` | “ or ” | Opening after whitespace, start, `(`, `[`, `{`, or an opening quote. Closing otherwise |
| `'` | ‘ or ’ | Apostrophe ’ after a letter or digit |
| `--` | — (em dash) | `DashConversionReaction` (built-in), gated by this setting |
| `...` | … | Custom `EllipsisReaction` |
| `->` `<-` `=>` (P2) | → ← ⇒ | Custom |

Locale-aware quotes (de „…“, fr « … », sv ”…”) follow the document language (P2; v1 uses
English quotes). Each substitution is a separate undo step (§2.6), so `Mod+Z` right after it
restores the straight character.

**AC-8.1** Typing `"Hi," she said` gives `“Hi,” she said`. `Mod+Z` after the closing quote
gives `“Hi,"`.

## 9. Auto-pair brackets and quotes (P1)

Setting **Auto-pair brackets** (`writeDefaults.autoPair`, default on;
`write.prefs.setAutoPair {enabled}`). Implemented by the custom keyboard action `autoPairAction`,
placed before `anyCharacterToInsert…`.

| Situation | Behaviour |
|-----------|-----------|
| Type `(` `[` `{` (and `"` `` ` `` in code blocks) with a collapsed caret and the next char whitespace / end / closing bracket | Inserts the pair, caret between |
| Type the closer when the next char is the same auto-inserted closer | Overtypes (moves the caret) |
| Backspace right after an auto-inserted opener with an empty pair | Deletes both |
| Type an opener with a **non-empty selection** | Wraps the selection: `(` → `(sel)`; `` ` `` → applies **inline code** instead of literal backticks; `*` → italic; `~` → strike (selection-wrap formatting is part of Markdown shortcuts) |
| `'` after a letter | Never paired (apostrophe) |
| `"` outside code with smart quotes on | Paired as “ ” |

**AC-9.1** Selecting "foo" and typing `` ` `` makes "foo" inline code, with no backticks
inserted.

## 10. Inline formatting

### 10.1 Commands

| Command | Title | macOS | Win/Linux | Role |
|---------|-------|-------|-----------|------|
| `write.format.bold` | Bold | ⌘B | Ctrl+B | C* |
| `write.format.italic` | Italic | ⌘I | Ctrl+I | C* |
| `write.format.strikethrough` | Strikethrough | ⌘⇧X | Ctrl+Shift+X | C* |
| `write.format.inlineCode` | Code | ⌘E | Ctrl+E | C* |
| `write.format.clearFormatting` | Clear formatting | ⌘\ | Ctrl+\ | C* |
| `write.format.markdownHint {feature}` | (shows a hint, not undoable) | ⌘U, ⌘⇧E/L/R/J | Ctrl+U, Ctrl+Shift+E/L/R/J | V |

`C*` means commenters can run it only in Suggesting mode, where it produces `fmt` suggestions
(§32). `write.format.markdownHint` shows a one-time-per-session popover near the caret. For
example: "Underline isn't available in Markdown. Use bold or italic, or change how emphasis
looks in **Format › Theme**." The alignment chords show the matching alignment text. This keeps
Google Docs muscle memory from silently doing nothing.

### 10.2 Toggle semantics
- **Expanded selection**: if every eligible character in the selection already has the
  attribute, remove it. Otherwise add it to all eligible characters. Eligible excludes:
  - code-block text (inline formatting is disabled in code blocks);
  - for bold/italic/strike, characters with inline `code` (schema rule 3);
  - embeds.
  
  One transaction, using `AddTextAttributionsRequest`/`RemoveTextAttributionsRequest` per text
  node. `ToggleTextAttributionsRequest` is not used, because its mixed-selection semantics
  differ.
- **Collapsed caret**: toggles the attribute in the **typing attributes** (composer). There is
  no document change and no undo step. The toolbar toggle shows the pending state. Typing
  attributes reset when the caret moves.
- `write.format.inlineCode` on a selection removes bold, italic and strike from it.
- `isChecked` (toolbar/menu state): true when all eligible characters in the selection (or
  the typing attributes, when collapsed) have the attribute.
- `isEnabled`: false in code blocks, false when the selection contains only embeds, false in
  Viewing mode.

### 10.3 Typing attributes (`WonkyTypingAttributesReaction`)
This reaction replaces `UpdateComposerTextStylesReaction`. On every selection change it sets
`currentAttributions` to the **inline formatting** attributions (bold, italic, strike, code) of
the character **upstream** of the caret. At offset 0 it uses the downstream character. It never
carries over:
- `LinkAttribution`: typing at a link's end does not extend it. Typing strictly inside a link
  does extend it.
- `MentionAttribution`.
- `CommentAttribution`, which extends only strictly inside the anchor (§33.3).
- `SuggestionAttribution`. Suggesting mode adds the user's own `ins` attribution fresh (§32).

### 10.4 Clear formatting
Removes bold, italic, strike and code from the selection, or clears the typing attributes when
collapsed. Links, mentions, comment anchors, suggestions and block types are **kept**. One
undo step, "Clear formatting".

**AC-10.1** Selecting "a **b** c" and pressing ⌘B bolds the whole range. Pressing again
un-bolds it all.
**AC-10.2** Selecting text that contains inline code and pressing ⌘B bolds only the non-code
parts. The toolbar shows Bold as checked.
**AC-10.3** ⌘U shows the hint popover and creates no undo step.

## 11. Links

### 11.1 Entry points
- `Mod+K` (editor scope) runs `write.link.insert`. The command palette stays on `Mod+Shift+P`
  while the editor is focused (§44).
- Toolbar link button, Insert › Link, the floating selection toolbar, context menu
  *Insert link* / *Edit link*, and slash `/link`.
- Pasting a URL with a non-empty text selection turns the selection into a link to that URL
  (§23.4).
- Autolink while typing (§7.2) and on paste (§23.4).

### 11.2 Link popover (`LinkEditorPopover`, see 05 §9.1)
Anchored below the selection, or the link under the caret.

| Field | Behaviour |
|-------|-----------|
| **Text** | Prefilled with the selected text or link text. Hidden when the selection spans more than one block (the link applies to each text run) |
| **Link** | `ShadInput` with search: typing shows suggestions from (1) **headings in this document**, (2) **recent and matching Wonky documents** (`drive.search`, kind document and spreadsheet), and (3) "Link to heading in another document…" (P1: pick a doc, then its heading from `wonky://doc/<uuid>/outline`) |
| Buttons | **Apply** (Enter), **Remove link** (only when editing), Esc cancels |

URL normalisation and validation (`LinkUrlPolicy`, `wonky_write_core`):
- Scheme allow-list: `http`, `https`, `mailto`, `tel`, `wonky`. Other schemes are rejected
  inline with "This kind of link isn't allowed"; this covers `javascript:`, `data:`, `file:`
  and `vbscript:`.
- Missing scheme: `foo@bar.com` → `mailto:`. A domain-like string → `https://`. `#slug` →
  `wonky://doc/<thisDoc>#slug`.
- Own-host app URLs (`https://<host>/write/d/<uuid>?heading=<slug>`, `/sheets/s/<uuid>`) are
  converted to `wonky://doc/<uuid>#<slug>` / `wonky://sheet/<uuid>`.
- Max length 2,048.

### 11.3 Internal links
- Format: `wonky://doc/<docUuid>`, `wonky://doc/<docUuid>#<headingSlug>`, `wonky://sheet/<uuid>`.
- Heading slugs follow the GitHub algorithm: lowercase, trim, remove punctuation except `-`
  and spaces, spaces → `-`, then de-duplicate with `-1`, `-2` in document order. Computed by
  `HeadingSlugger` in `wonky_write_core`.
- A missing slug at navigation time (the heading was renamed) triggers a fuzzy match on the
  heading text (Levenshtein ≤ 30 %). If found, the editor jumps there and shows the toast
  "Heading not found — jumped to the closest match". Otherwise it opens at the top.
- Export rewrites internal links ([07](07-import-export-print.md)).

### 11.4 Commands

| Command | Args | Role | Undo |
|---------|------|------|------|
| `write.link.insert` | — (opens popover) | C* | — |
| `write.link.set` | `url`, `text?`, `range?` (Delta `{start,length}`; default = selection) | C* | 1 step "Insert link" |
| `write.link.edit` | — (opens popover for the link at caret) | C* | — |
| `write.link.remove` | `range?` (default: the whole link run at caret) | C* | 1 step "Remove link" |
| `write.link.open` | `url?` (default: the link at caret) | V | not undoable |
| `write.link.copy` | `url?` | V | not undoable |

With a collapsed caret and no link at the caret, `write.link.set` with `text` inserts new
linked text. Without `text`, it inserts the URL as the text.

### 11.5 Hover card (`LinkHoverCard`)
Shown when the pointer rests 400 ms over a link, or when the caret enters a link (keyboard
users). Hidden on pointer leave (after 200 ms grace), on typing and on Esc.

Content:
- **External link**: a globe icon, the domain in bold and the full URL truncated in the
  middle. No remote fetch (privacy and offline).
- **Internal doc link**: the doc icon and title from `drive.get`, cached. "No access" if the
  user has no access. The heading name if a slug is present.
- **Mention**: the user card (§19).
- Buttons: **Open** (↗), **Copy link**, **Edit** (pencil, C*), **Remove** (unlink, C*).

### 11.6 Opening links (`WonkyLinkTapHandler`)
This replaces `superEditorLaunchLinkTapHandlerFactory`.
- In **Editing/Suggesting** mode, a plain click places the caret, and Mod+click opens the link.
  In **Viewing** mode (`SuperReader`), a plain click opens it.
- **Internal links** navigate in the same window (`/d/<uuid>?heading=<slug>`, or the Sheets
  app). A same-document heading scrolls there and pushes a back-history entry.
- **External links** show the shell's "Open external link?" confirm popover
  ([suite 03](../03-app-shell-and-navigation.md) §1) with **Open** and **Copy link**.
  The setting "Don't ask again for this domain" is stored in local prefs. `mailto:`/`tel:` hand
  off to the OS.

**AC-11.1** Selecting "docs" and pasting `https://x.dev` makes "docs" a link. Undo restores
plain "docs".
**AC-11.2** Typing `#intro` in the link field shows the matching heading "Intro" first. Applying
it gives `wonky://doc/<self>#intro`.
**AC-11.3** `javascript:alert(1)` cannot be applied.

## 12. Paragraph styles and headings

### 12.1 Command
`write.format.blockType {type}`. `type` ∈ `paragraph | heading1…heading6 | quote | codeBlock`.
Role C*.

| Style | macOS | Win/Linux |
|-------|-------|-----------|
| Normal text | ⌘⌥0 | Ctrl+Alt+0 |
| Heading 1…6 | ⌘⌥1…⌘⌥6 | Ctrl+Alt+1…6 |
| Quote | ⌘⇧. | Ctrl+Shift+. |
| Code block | ⌘⌥C | Ctrl+Alt+C |

### 12.2 Semantics
- Applies to every text block touched by the selection, as one undo step labelled
  "Heading 2", "Normal text", and so on. Embeds in the range are skipped.
- From a list item or task: the node is replaced with a `ParagraphNode` of the target type,
  and its indent is dropped.
- **To Code block**: consecutive selected text blocks merge into **one** code block.
  - The lines are their plain texts. Inline formatting is dropped. U+2028 becomes `\n`.
  - The language is the user's last-used language (default "", plain).
- **From Code block** to another type: each code line becomes its own block of the target
  type.
- **Quote and Code are toggles.** Applying Quote to a selection that is entirely quote lines
  converts them to Normal. Headings are **not** toggles; applying H2 to an H2 keeps it.
- `isChecked` per type drives the paragraph-style dropdown label (05 §4). A mixed selection
  shows "Mixed" (an empty label).
- The paragraph-style dropdown renders each entry in the current theme's style (font, size,
  weight), clamped to a 13–22 px preview size.

**AC-12.1** Selecting three paragraphs and pressing ⌘⌥C creates one code block with three
lines. One undo restores the three paragraphs with their inline formatting.

## 13. Lists and checklists

### 13.1 Commands

| Command | macOS | Win/Linux | Notes |
|---------|-------|-----------|-------|
| `write.list.toggleBulleted` | ⌘⇧8 | Ctrl+Shift+8 | |
| `write.list.toggleNumbered` | ⌘⇧7 | Ctrl+Shift+7 | |
| `write.list.toggleChecklist` | ⌘⇧9 | Ctrl+Shift+9 | |
| `write.list.indent` | Tab | Tab | Only when the caret or selection is in list/task items |
| `write.list.outdent` | ⇧Tab | Shift+Tab | |
| `write.list.toggleChecked {nodeId?}` | ⌘Enter (contextual §2.7) | Ctrl+Enter | Default: tasks in the selection |

### 13.2 Toggle semantics
- If **every** text block in the selection is already the target list type, all become Normal
  paragraphs. Otherwise all become the target type.
  - List-to-list conversions keep the indent (`ChangeListItemTypeRequest`; task ⇄ list via
    node replacement).
  - Headings and quotes lose their type.
  - Code blocks convert per line.
- New tasks are unchecked. Converting a checked task to a bullet drops its checked state, and
  converting back gives unchecked. Undo restores the state.

### 13.3 Indentation
- Levels 0–8 (Delta `indent` 1–8; 0 = no attribute).
- `Tab` indents each selected list/task item by one level, but never more than one level deeper
  than the previous list item. The first item of a list cannot indent. The command's
  `isEnabled` reflects that. When indent is impossible, the Tab key is consumed as a no-op so
  focus doesn't leave the editor.
- `Shift+Tab` outdents to a minimum of 0. Outdenting at 0 converts to a Normal paragraph
  (Google Docs parity).
- Tab in a Normal paragraph, heading or quote does nothing (consumed). Keyboard users leave the
  editor with `Esc`, then `Tab` (§37.3).
- Indenting or outdenting a parent does **not** move its children (flat model). Children whose
  indent becomes > parent + 1 are clamped by the schema guard.
- Bullet glyphs and number formats per level (1. → a. → i. → 1. …) come from the theme
  (`listNumeralStyle`, `dotShape` via `BlockSelector`, see [06](06-themes.md)).

### 13.4 Numbering
`super_editor` computes ordinals for contiguous `ordered` items. Counting restarts when a
non-list block or an item with a lower indent interrupts the run. There is no "restart
numbering" or "start at N" feature (no start number in the model). After import, numbering
starts at 1 ([02](02-document-model.md) §2.1).

### 13.5 Checkbox interaction
- Clicking a checkbox (component hit target ≥ 24×24 px) runs `write.list.toggleChecked
  {nodeId}`. One undo step, "Check item" or "Uncheck item". The caret does not move.
- Completed tasks are styled by the theme (default: strikethrough and muted color). This is
  rendering only.
- Commenters, or anyone in Suggesting mode, produce an `fmt` suggestion (§32). Viewers see a
  non-interactive checkbox.
- `TaskComponentBuilder(editor)` must be in `componentBuilders` (§2.2).

**AC-13.1** ⌘⇧8 on a mix of a heading and two paragraphs makes three bullets.
**AC-13.2** Tab on the first item of a list is consumed and changes nothing.
**AC-13.3** Clicking a checkbox while a collaborator types in the same item converges on both
clients.

## 14. Blockquote

- Each quote line is its own `ParagraphNode` (blockType `blockquoteAttribution`). Consecutive
  quote nodes render as **one** visual quote. The theme's quote rule uses
  `BlockSelector("blockquote").after("blockquote")` to collapse the vertical padding between
  them and continue the left border.
- Applied with `write.format.blockType {type: quote}` (toggle), `> `, slash `/quote`, or the
  context menu's *Turn into*.
- Enter, Backspace and Shift+Enter work as in §6.
- No nesting. Lists inside quotes are not supported: making a quote line a list removes the
  quote type.

**AC-14.1** Three consecutive quote lines render with one continuous border. Export gives one
`>` block with blank `>` separators ([02](02-document-model.md) §2.2).

## 15. Code blocks

### 15.1 Structure and language
- One `ParagraphNode` with blockType `codeAttribution`, text containing `\n`, and node metadata
  `codeLanguage` (custom). Delta: consecutive `code-block: "<lang>"` lines
  ([02](02-document-model.md) §1.2).
- **Rendered as one box**: the whole block (every line of a ```` ``` ```` fence) sits in a single
  box with the theme's code background, corner radius, border (`codeBlock.border`, top side used
  for all four) and inner padding (`codeBlock.padding`, default 12/16 px), at the full content
  width. `WonkyParagraphComponentBuilder` paints it around the paragraph component: the padding
  is outside the component's render box, so caret, selection and hit-testing stay aligned with
  the text; taps in the padding go to the nearest position. The box and the hover chrome are not
  hit targets (an opaque region in the document layer would hide taps from the interactor).
  The text is set in the theme's `mono` font (JetBrains Mono in every built-in theme).
  super_editor adds a block's type to the attributions of every span it styles; for code blocks
  the component is built without it, so code text never gets the inline-code style.
- **Language picker**: a chip at the top-right of the block (visible on hover or when the caret
  is in the block) opens `ShadSelect.withSearch`.
  - Lists: *Plain text*, then recently used (max 5, per user), then the 15 languages the
    highlighter supports (§15.4), with display names (`CodeLanguages.grammars`).
  - Aliases normalise input: `js`/`jsx`/`mjs`/`cjs`→`javascript`, `ts`/`tsx`→`typescript`,
    `py`/`py3`/`python3`→`python`, `sh`/`shell`/`zsh`→`bash`, `yml`→`yaml`, `md`→`markdown`,
    `c++`→`cpp`, `c#`→`csharp`, `kt`/`kts`→`kotlin`, `rb`→`ruby`, `rs`→`rust`, `golang`→`go`,
    `htm`→`html`, `jsonc`→`json`, `spy`/`serverpod_protocol`→`serverpod`; (v2, shared table of
    Slides 07 §2.4) `h`→`c`, `cc`/`hpp`→`cpp`, `docker`→`dockerfile`, `gql`→`graphql`,
    `patch`→`diff`, `svg`/`plist`→`xml`.
  - Other languages (`bash`, `c`, …, or anything typed) are kept verbatim (lowercased), labelled
    with their display name when known, and rendered without highlighting.
- `write.code.setLanguage {language, nodeId?}`. One undo step, "Set code language". Changes
  the `code-block` attribute of every line.
- **Copy** button next to the chip: `write.code.copy {nodeId?}` copies the code text as
  plain text. Not undoable. Shows the toast "Code copied".

### 15.2 Editing inside code
| Key | Behaviour |
|-----|-----------|
| Enter / Shift+Enter | Inserts `\n` plus the current line's leading whitespace. P1: one extra indent unit after a line ending in `{`, `(`, `[` or `:` |
| Tab | Collapsed caret: inserts spaces up to the next multiple of the indent unit (2 spaces; P2 user setting 2/4/tab). Multi-line selection: indents every touched line |
| Shift+Tab | Removes up to one indent unit from the start of every touched line |
| Backspace in leading whitespace | Deletes back to the previous indent stop (P1) |
| Auto-pair | `( [ { " ' `` ` ``` pair inside code (§9) |
| `Mod+B/I/E…` | No-op (commands disabled in code) |
| Paste | Always plain text. Newlines become code lines. Tabs are kept |

Commands `write.code.indentLines` and `write.code.outdentLines` back Tab and Shift+Tab, so MCP
can invoke them.

### 15.3 Exiting a code block
- `Mod+Enter` (`write.code.exit`, contextual §2.7) creates an empty Normal paragraph after the
  block and moves the caret there. Trailing empty lines are kept.
- **Triple Enter**: pressing Enter at the end of the block when its last two lines are already
  empty removes those two empty lines, creates a Normal paragraph after the block and moves the
  caret there. One undo step, "Exit code block".
- ↓ or → at the very end of a code block that is the last block of the document creates the
  lazy trailing paragraph (§6.5).

### 15.4 Syntax highlighting (P1)
- Library: the shared **`wonky_code`** package (§15.5): `TextMateTokenizer`, the TextMate engine
  of `syntax_highlight` 0.5.0 copied into pure Dart with patches SH-1…SH-5
  (`packages/wonky_code/THIRD_PARTY.md`). Languages and their grammar: CSS, Dart, Go, HTML,
  Java, JavaScript, JSON, Kotlin, Python, Rust, Serverpod models (`serverpod` →
  `serverpod_protocol`), SQL, Swift, TypeScript, YAML. Grammars are embedded Dart strings parsed
  on first use, so a block is highlighted on its first frame (before v2 they loaded from Flutter
  assets and the block showed plain until then). Since M10 (SL-35) the editor tokenizes through
  `DefaultCodeTokenizer`: languages without a grammar (bash, C, Ruby, …) are highlighted by
  highlight.js, exactly like the exports (07) and Wonky Slides. The block's language is
  normalized (`CodeLanguages.normalize`) before tokenizing. The language picker still offers the
  15 TextMate languages (`CodeLanguages.pickerLanguages`: `TODO.md`).
- `CodeHighlightStylePhase extends SingleColumnLayoutStylePhase`:
  - For each code component view model, it overlays **presentation-only**
    `CodeTokenAttribution(tokenClass)` spans on a *copy* of the view-model text. The document
    is never mutated, so no Delta is produced (§2.5).
  - `ScopeClassifier.tokenFor` (`wonky_code`) maps TextMate scopes to token classes: the innermost scope
    with a rule decides (e.g. `comment.*`→`comment`, `string.*`→`string`,
    `keyword.operator`→`operator`, `keyword`/`storage`→`keyword`, `constant.numeric`→`number`,
    `constant`→`literal`, `entity.name.function`→`function`, `entity.name.type`/`support.class`
    →`type`, `entity.name.tag`→`tag`, `entity.other.attribute-name`→`attribute`,
    `support.function`→`built_in`, `variable`→`variable`, annotations/preprocessor→`meta`,
    Rust lifetimes→`literal`);
    punctuation is weak (a surrounding string, comment or tag wins); embedded code
    (`meta.embedded`, template/f-string expressions) does not inherit its string's color.
  - The `inlineTextStyler` maps token classes (`keyword`, `string`, `comment`, `number`,
    `title`/`function`, `built_in`, `literal`, `type`, `attr`/`attribute`, `symbol`, `meta`,
    `regexp`, `deletion`, `addition`, `variable`, `operator`, `punctuation`, `tag`) to the
    theme's code palette ([06](06-themes.md)). Light and dark variants are separate.
  - super_editor disposes style phases when it recreates its presenter and keeps using them, so
    the phase does not cancel work in `dispose`; the editor calls `close()` when it goes away.
- Caching and performance:
  - Results are cached per `(nodeId, textHash, language)`.
  - Re-highlighting is debounced 120 ms after an edit. Until then, stale spans are shifted
    through the edit, so colours don't flash.
  - Blocks over 2,000 lines highlight only the lines visible in the viewport ±200 lines.
- Highlighting never runs in exports that disable it (theme option).

**AC-15.1** Typing in a 500-line Dart block keeps keystroke latency under 16 ms p95. Colours
update within 200 ms.
**AC-15.2** Changing a block from `dart` to `python` re-highlights. One undo restores `dart`.

### 15.5 Shared code packages (v2)

Wonky Slides (code elements with line highlighting and type-in, [Slides 07](../wonky_slides/07-code-blocks.md))
and Wonky Drive (text/code previews, [Drive 02 §6.4](../wonky_drive/02-files-uploads-previews.md))
use the same languages, token classes and palettes as Write. In M8 (Drive 05 work package
D-2) the code moves, **without behavior change**, into two shared leaf packages (suite 01
§2.1); the full move list is [Slides 07 §2.1](../wonky_slides/07-code-blocks.md):

| From | To |
|------|----|
| `wonky_write/lib/features/editor/model/code_languages.dart` (`CodeLanguages`: aliases, grammar map, picker list) | `packages/wonky_code` (pure Dart) |
| Token classes and `CodeHighlighter.tokenForScopes` (scope → class rules) | `wonky_code` (`ScopeClassifier`) |
| The theme code palettes' defaults (light/dark token colors used when a theme doesn't override them, 06) and `SyntaxToken` | `wonky_code` (`SyntaxPalette`, `SyntaxToken`, re-exported by `wonky_write_core`); Write themes keep their per-theme overrides |
| `wonky_write_core/lib/src/highlight/` (pure-Dart `highlight` wrapper used by exports) | `wonky_code` (`HighlightJsTokenizer`) |
| The TextMate engine and grammars of the vendored `syntax_highlight` (patches SH-1…SH-5) | `wonky_code` (`TextMateTokenizer`, grammars embedded as Dart strings — copied, v2 review Q26); `third_party/syntax_highlight` is deleted once Write uses it |
| — (new) | `wonky_code_flutter`: `CodeView` — read-only, highlighted, line numbers, wrap, selection; `CodeTextStyler`; used by Drive previews and Slides; Write keeps its `CodeHighlightStylePhase`, now on top of `DefaultCodeTokenizer` |

`wonky_write_core` then depends on `wonky_code` instead of `highlight`, and `wonky_write` on
`wonky_code` + `wonky_code_flutter`. Line-level diffs for Slides' type-in use
`wonky_core/lib/diff.dart` (`SequenceDiff`).

**Status (D-2, done):** `packages/wonky_code` + `packages/wonky_code_flutter` exist; Write's
`CodeLanguages` (`model/code_languages.dart`) and `wonky_write_core`'s `SyntaxToken`,
`SyntaxHighlighter`/`SyntaxSpan` are re-exports/aliases of `wonky_code`; the editor's
`CodeHighlightStylePhase` uses `TextMateTokenizer` (not yet `DefaultCodeTokenizer`: languages
without a TextMate grammar stay plain in the editor until the exports switch in M10, so M8 has
no visible change) and keeps its class-keyed `EditorTheme.syntax` styling (not `CodeTextStyler`).
The only color difference: Rust lifetimes now use the theme's `literal` color (before: a
`symbol` class that themes could not set; identical in the default themes).

**Decided (v2 review, Q17/Q25):** until the export switch lands, Write's exports (PDF, HTML,
DOCX, …) keep tokenizing with highlight.js while the editor uses TextMate, so colors can differ
slightly between screen and export — accepted. In **M10** Write's exports switch
to `DefaultCodeTokenizer` (TextMate first, highlight.js fallback) with a golden diff review of
the Write export corpus; only token colors change.

**Status (M10, Slides SL-35, done):** the exports (PDF and print, HTML, EPUB, DOCX, ODT, RTF)
and the editor tokenize with `DefaultCodeTokenizer`; `wonky_write_core`'s `SyntaxHighlighter`
is now the exporters' cached front for it (no longer an alias of `HighlightJsTokenizer`).
Screen and export colors match. The diff review is a test
(`wonky_write_core/test/export/code_tokenizer_switch_test.dart`); it led to TextMate patch SH-7
(capture offsets: `function f` had its name scoped on the keyword) and to PDF code lines
wrapping at spaces regardless of token boundaries (07 §5.2).

## 16. Horizontal rule (divider)

`write.insert.divider`. Slash `/divider`, Insert › Horizontal line, or `---` autoformat.
- Inserts a `HorizontalRuleNode` (Delta `divider` embed with a new UUIDv7 `id`) after the
  current block. If the current block is an empty paragraph, the divider replaces it.
- The caret moves to the following text block, which is created if missing.
- It is selected as a block. Backspace or Delete removes it.
- The theme styles it (thickness, colour, margins).
- One undo step, "Insert divider".

## 17. Images

### 17.1 Entry points
| Entry | Command |
|-------|---------|
| Toolbar image button ▾ → *Upload from computer* / *By URL* | `write.insert.image` (file picker) / `write.insert.imageFromUrl` (dialog) |
| Insert › Image ▸ | same |
| Slash `/image`, `/image url` | same |
| Paste image data or image files | `write.insert.imageFiles {files}` (internal; MCP uses `write.insert.imageFromUrl` or headless upload tools) |
| Drag & drop image files onto the canvas | same, at the drop position (§24) |

Picker (`file_picker`): `png, jpg, jpeg, gif, webp`, multi-select up to 20 files. Rejected
inputs and their toasts:
- SVG: "SVG images aren't supported".
- HEIC/TIFF/other formats: "Unsupported image format".
- Files over the size limit (`write.maxImageBytes`, default **20 MB**): "Image is larger than
  20 MB".

### 17.2 Insert flow (works offline)
1. The client generates `fileUuid` (UUIDv7) and the embed id. It immediately inserts the
   **embed** `{id, src: "wonky-file://<fileUuid>", alt: ""}` at the caret, or the drop point:
   - mid-paragraph: the paragraph is split;
   - empty paragraph: the image replaces it;
   - several files: several consecutive images.

   This is one undo step, "Insert image". The image is in the Delta right away, so
   collaborators and offline sync see a consistent document.
2. The bytes go to `ImageUploadQueue`, persisted in a local table `LocalPendingUpload`
   (`fileUuid`, `documentUuid`, `mime`, `bytes` blob, `state`, `attempts`, `createdAt`; see §44).
   The upload uses the platform files service (Serverpod upload description flow, `StoredFile`
   owned by the document item). `fileUuid` is supplied by the client and the upload is
   **idempotent**.
3. Retries use exponential backoff (2 s → 5 min), unlimited while online. After 5 failed
   attempts with a non-retryable error (4xx), the state becomes `failed`.
4. P1: client-side downscale when the long edge is over 4,096 px (re-encode as JPEG q=0.9,
   or PNG with alpha), done in an isolate or worker. EXIF orientation is applied, and EXIF
   metadata (including GPS) is **stripped** before upload.

### 17.3 Rendering (`WonkyImageComponentBuilder`)
- `ImageUrlResolver` maps `wonky-file://` to a signed URL via `FileEndpoint.getUrl`. It caches
  per fileUuid until 60 s before expiry. `https://` sources render directly. `http://` sources
  are rejected at insert time.
- Size:
  - Natural width, capped at the content width.
  - Pages mode: height capped at the page content height (scaled down proportionally).
  - The natural size of every decoded image is kept in `ImageSizeCache` (in memory, keyed by
    src, the 512 most recently used). While an image loads, its placeholder has the cached
    size (capped like the image) to avoid layout jumps and wrong page breaks. Before the first
    load, a 16:9 placeholder is shown at content width (also capped).
- Decoding uses `cacheWidth` = displayed width × devicePixelRatio × zoom (rounded up to a
  256-px bucket).
- States:

  | State | Uploader sees | Others see |
  |-------|---------------|------------|
  | Uploading | Local bytes as preview + `ShadProgress` ring with % + Cancel (×) | Skeleton + "Uploading… (Anna)" |
  | Pending (server knows the uuid, no bytes yet) | — | Skeleton + "Waiting for upload from Anna"; poll `getUrl` with backoff 2 s → 60 s for 24 h |
  | Failed | Red overlay "Upload failed" + **Retry** / **Remove** | "Image unavailable" placeholder with alt text |
  | Loaded | Image | Image |
  | Broken URL | Broken-image icon + alt text + **Retry** | same |
- Alt text is the semantics label. Images without alt show a small "Alt" badge (P1, Editors
  only) that opens the alt dialog.

### 17.4 Image interactions
- Click selects the image (ring) and shows the **image toolbar** (floating, 05 §5.2):
  - Alt text (`write.image.editAlt`)
  - Replace ▸ (Upload / By URL; `write.image.replace`, `write.image.replaceFromUrl {url}`)
  - Download (`write.image.download`)
  - View full size (`write.image.preview`)
  - Comment
  - Delete
- Double-click (or a click in Viewing mode, or *View full size*, `write.image.preview {nodeId?}`)
  opens the **lightbox** (`showImageLightbox` in `wonky_app`, shared with the board): an in-app full-screen overlay with zoom 25–400 %
  of the natural size (buttons, +/−/0 keys, wheel, pinch), pan, a caption with the alt text or
  title, and Esc / the close button / a backdrop click to close. It never opens a new tab.
- **Alt text dialog**: Alt text (textarea, 0–500 chars, with a hint about describing the
  image), Title (optional, shown as a tooltip and exported as the Markdown title), Save and
  Cancel. `write.image.setAlt {nodeId?, alt, title?}`, one undo step.
- Replace keeps the embed `id` and swaps `src` (the upload flow as in §17.2), as one undo step
  "Replace image". Resetting the alt text is not automatic.
- Download:
  - Desktop: `file_saver` with the original filename if known, else `image-<n>.<ext>`.
  - Web: an anchor with the `download` attribute (same tab).
  - Allowed only if the role or share settings allow download (suite 06 §1).
- Copy image (context menu, P1) writes the image bytes plus HTML `<img>` plus Markdown text.
- Cancel upload or Remove (failed): deletes the embed (one undo step) and drops the queue entry.
  Undoing re-inserts the embed and re-queues the bytes if they are still in the local table
  (kept for 24 h after cancel).

**AC-17.1** Pasting a screenshot while offline inserts the image with an upload badge. After
reconnecting, it uploads, and a collaborator sees it appear without a reload.
**AC-17.2** A 30 MB PNG is rejected with the size toast and the document is unchanged.
**AC-17.3** An image's `src` round-trips as `wonky-file://<uuid>` through Markdown export and
import within Wonky (07 handles external rewriting).

## 18. Tables

### 18.1 Model recap
The Delta `table` embed is `{id, align[], rows[][]}`. Row 0 is the header and cells are inline
Markdown. `super_editor` maps it to a **read-only** `TableBlockNode(cells: List<List<TextNode>>)`,
with cell alignment in the cell `TextNode` metadata `TextNodeMetadata.textAlign`. The node is
selectable only as a whole.

### 18.2 Rendering (`WonkyTableComponentBuilder`)
- It wraps `MarkdownTableComponentBuilder` (which must also stay in the list, §2.2). Styling
  comes from `TableStyles` in the theme (borders, header background, cell padding), with
  light and dark variants.
- Wide tables scroll horizontally with the built-in scrollbar. Cells wrap text up to a minimum
  column width of 64 px.
- **Affordances** on hover or selection: an **Edit table** button (pencil, top-right of the
  table, opens the table editor popover). Clicking a cell edits it in place
  (§18.4).

### 18.3 Insert
- `write.insert.table {rows, cols}`. Defaults 3×3 (rows include the header row). Bounds 1–2,000
  rows (header + body) and 1–64 columns.
- UI: the toolbar table button opens `WonkyTableSizePicker` (10×10 growing to 20×20). Insert ›
  Table ▸ has the same picker plus *Custom size…* (a dialog with two `WonkyNumberStepper`s).
  Slash `/table` inserts 3×3.
- Inserts the embed (empty cells, `align` all `null`) after the current block, or replaces an
  empty paragraph. Then it starts **in-place editing** of cell (0,0) (the popover when in-place
  editing is unavailable). The insertion is its own undo step, "Insert table".

### 18.4 Table editor
**In-place editing** (patch **SE-4**, `features/editor/tables/inline_table_editing.dart`,
`write.table.editCell {nodeId?, row?, col?}`): clicking a cell (or Enter / F2 on a selected
table) turns it into a text field holding the cell's **inline Markdown source**; other cells keep
their rendering. While a cell is edited the local selection (presence) is the table embed.
- Tab / Shift+Tab: next / previous cell (Tab selects the cell's text; Tab in the last cell appends
  a row). Enter: cell below; in the last row it appends a row. Shift+Enter: cell above. ↑ ↓: row
  above / below; ← → at the text edges: previous / next cell. Leaving the first or last cell (or
  the top / bottom row) puts the caret before / after the table.
- Mod+B / I / E, Mod+Shift+X wrap the field selection in `**`, `*`, `` ` ``, `~~`; Mod+K wraps it
  as `[text]()`.
- Esc leaves the cell with the table selected; Mod+Enter leaves it with the caret after the table.
- Commits: on leaving the cell, on focus loss, and after 1.5 s without typing (so collaborators
  see the edit). Each commit is one `table` embed replacement and one undo step "Edit cell";
  appended rows are their own step "Insert row". Mod+Z in a field with draft history undoes the
  draft; in a clean field it runs the document undo.
- Concurrency: a remote change to other cells updates the field when it is clean; a dirty draft
  wins when committed (last writer wins, per cell). If the table or the cell disappears, editing
  stops with a notice.

The **`TableEditorPopover`** (below) remains for bulk operations (structure, alignment, paste
grid, sort) and narrow screens.
- an anchored overlay covering the table's on-screen bounds, min 480 px wide, max the canvas
  width, max height 70 % of the viewport, internally scrollable;
- a full-screen dialog below the `md` breakpoint.

It edits a **draft** (`TableDraft`, an immutable model with its own local undo stack).

| Area | Content |
|------|---------|
| Toolbar | Insert row above / below, Insert column left / right, Delete row, Delete column, Move row ↑/↓, Move column ←/→, Column alignment `ShadToggleGroup` (None/Left/Center/Right), inline **B I S `code` link** buttons (they wrap the focused cell's selection in Markdown syntax), Sort column A→Z / Z→A (P2), ⋮ (Copy as Markdown, Delete table) |
| Grid | Row 0 (header, visually bold, sticky) + body rows. Each cell is a single-line `ShadInput`-styled field that edits the **inline Markdown source** of the cell. Unfocused cells show the rendered inline Markdown |
| Row/column headers | Gutter with row numbers and column letters. Click selects the row or column. Drag handles reorder (P1). Right-click opens the row/column menu |
| Footer | Size label "4 × 3", **Cancel**, **Done** (primary); the title bar's X is Cancel |

Keyboard (scope `dialog`):

| Key | Action |
|-----|--------|
| Tab / Shift+Tab | Next / previous cell. Tab in the last cell appends a row |
| Enter / Shift+Enter | Cell below / above (newlines are not allowed in cells) |
| ↑ ↓ | Cell above / below. ← → at text boundaries move to the adjacent cell |
| Mod+Enter | Done |
| Esc | Cancel. Asks "Discard changes to this table?" if the draft is dirty |
| Mod+Z / Mod+Shift+Z | Draft-local undo / redo. Keystrokes in one cell are one step; the first edit after a structural change, an undo or a redo, or in another cell starts a new one |
| Mod+B / I / E, Mod+Shift+X, Mod+K | Wrap the cell selection with `**` `*` `` ` `` `~~`, or open a link mini-field |
| Mod+V | Cell text paste. TSV/CSV/HTML-table clipboard content fills cells from the focused cell and grows the table (P1) |

Commit:
- **Done** runs `write.table.replace {nodeId, table}`. A custom `ReplaceEmbedRequest` keeps the
  embed `id`. This is **one undo step**, "Edit table", and the Delta is delete-old + insert-new
  with the same id.
- An unchanged draft commits nothing.
- Cell sources are validated by parsing them as inline Markdown. Block syntax is escaped (for
  example a leading `#` becomes `\#`). Pipes are escaped by the codec.

Concurrency:
- While the editor is open, the local presence cursor is a selection of the table embed, so
  others see "Anna is editing this table".
- If a remote op **replaces** the table while the draft is open, a banner appears: "Bo changed
  this table while you were editing." with **Discard my changes** (reload the draft) and
  **Keep mine** (Done overwrites, last writer wins per the embed identity rule,
  [02](02-document-model.md) §4.3).
- If a remote op **deletes** the table: "This table was deleted." with **Insert as new table**
  and **Discard**.

Direct commands (no editor UI; for MCP and the context menu). Each is one undo step
that replaces the embed:
`write.table.insertRow {nodeId?, index, position: above|below}`,
`write.table.insertColumn {nodeId?, index, position: left|right}`,
`write.table.deleteRow {nodeId?, index}`, `write.table.deleteColumn {nodeId?, index}`,
`write.table.moveRow {nodeId?, from, to}`, `write.table.moveColumn {nodeId?, from, to}`,
`write.table.setColumnAlignment {nodeId?, index, align}`,
`write.table.setCell {nodeId?, row, col, markdown}`, `write.table.delete {nodeId?}`,
`write.table.edit {nodeId?, row?, col?}` (opens the editor). Deleting the header row is
impossible. The header row can be emptied.

### 18.5 Paste and copy
- Pasting GFM table text, or HTML `<table>`, creates a table embed (§23.3).
- Copying a selected table writes Markdown (text/plain when "copy as Markdown" is on), an HTML
  `<table>`, and the internal Delta.
- `write.table.copyAsTsv` copies tab-separated values, for pasting into Wonky Sheets or a
  spreadsheet.

**AC-18.1** Inserting a 4×3 table from the picker opens the editor. Typing in cells and pressing
Done results in exactly one undo step. Undo restores the empty table, and undo again removes it.
**AC-18.2** A cell containing `a | b` exports as `a \| b` and round-trips.
**AC-18.3** Two users editing the same table concurrently converge on one table (the last Done
wins). The loser sees the banner if their editor was still open.

## 19. Mentions

### 19.1 Trigger and picker
- `StableTagPlugin(tagRule: TagRule(trigger: '@', excludedCharacters: {...whitespace, punctuation}))`
  detects the composing tag. The trigger only fires when `@` follows the start of a block, a
  whitespace character or an opening bracket, so emails like `bob@x.com` never trigger it.
  Disabled in code.
- `MentionPicker` popover anchored at the composing tag's rect:
  - People with access to the document (from sharing), then the user's frequent contacts, then
    `user.searchUsers(query)`, debounced 150 ms, max 8 rows.
  - Each row shows avatar, name, email and role badge.
  - Keys: ↑↓ move, Enter/Tab choose, Esc cancels (keeps the text), Space with no match closes.
- Choosing a user without access opens the suite-07 prompt (*Share & mention* as
  Commenter/Viewer, *Mention without sharing*, *Cancel*).

### 19.2 Commit
`write.insert.mention {userUuid, replaceComposing?: true}` replaces `@query` with
`@Display Name` carrying `MentionAttribution(userUuid)` and `LinkAttribution(mailto:<email>)`,
followed by a plain space. One undo step, "Mention". The server sends a `mention` notification
when it commits an op that **adds** a mention attribute for a user (once per user per document
per 10 min).

### 19.3 Behaviour as an atom
- `MentionAtomicityReaction` keeps the caret and selection edges outside mention runs: a caret
  placed inside snaps to the nearest edge.
- Backspace or Delete next to a mention deletes the whole mention.
- Typing never extends a mention (§10.3).
- Rendering: `MentionChipLayerBuilder` draws a rounded `muted` background behind each mention's
  text bounds (using `AttributedTextBoundsOverlay`-style bounds computation). The text is
  `primary` coloured. Mentions of yourself are highlighted with an accent background.
- Hover or caret shows the **user card** (avatar, name, email, *Copy email*). `mailto:` opens
  only after the external-link confirm.

**AC-19.1** Typing "@an", choosing "Anna Berg" and then Backspace once removes "@Anna Berg"
entirely.

## 20. Emoji and special characters

### 20.1 Emoji picker (P1)
- `WonkyEmojiPicker` (`wonky_write/lib/features/emoji/`; to move to wonky_ui for comment
  reactions once wonky_ui has a small preferences-store interface):
  - search by CLDR short name and keywords;
  - category tabs, recent (per user, max 24), skin-tone selector (stored preference);
  - grid keyboard navigation with arrows and Enter.
- Data: `assets/emoji/emoji.json` of `packages/wonky_app` (v2: the picker, catalog and prefs moved
  to `package:wonky_app/emoji.dart`, Drive 05 D-7) (1,898 emoji, Unicode emoji ≤ 15.1, CLDR names, keywords and
  shortcodes from emojibase-data, MIT), generated by `wonky_write/tool/unicode/gen_emoji.py`; loaded on first
  use, no runtime network.
- Entry points: Insert › Emoji (`write.insert.emoji {emoji?}`; without args the picker opens at
  the caret), slash `/emoji`, the `:` trigger, and the OS emoji panel (works through IME).
- Insert: one undo step, "Insert emoji". Emoji are plain text.
- Fonts on web: configure the Flutter engine's `fontFallbackBaseUrl` to **self-hosted** Noto
  fonts (`/write/assets/fonts/fallback/`), so emoji and CJK fallback never fetch from
  `fonts.gstatic.com` (privacy and offline, suite 02 §2).
- `:` trigger (P1, done): `:` after the block start, whitespace or an opening bracket plus at
  least two characters (`:smi`) opens a suggestion popover (8 matches by shortcode, name and
  keyword, in the user's skin tone); ↑ ↓ Enter/Tab choose (the emoji replaces `:query`, one step
  "Insert emoji"), Esc dismisses. Times (`10:30`) and URLs never trigger it.

### 20.2 Special characters dialog (P1)
Insert › Special characters…: `write.insert.specialCharacter` with no args opens the dialog.
With `{char}` it inserts directly.
- Category select: Punctuation, Arrows, Math, Currency, Latin, Greek, Cyrillic, Symbols,
  Technical, Box drawing.
- Search by Unicode name, from a bundled name table (`packages/wonky_app/assets/unicode/special_chars.json`, shared with Slides since SL-44, 6,365
  characters, generated from Unicode 16 names by `tool/unicode/gen_special_chars.py`). Exact code
  point input (`U+2192` or `2192`) is also accepted.
- A recent row, and a large preview with name and code point on hover or focus.
- Clicking a character inserts it at the caret, as one undo step per insertion. The dialog
  stays open. **Close** button, or Esc.

## 21. Slash command menu

### 21.1 Trigger
- `ActionTagsPlugin(tagRule: TagRule(trigger: '/'))` (`actionTagId: composingActionTag`).
- Active only when `/` is typed at the start of a text block or after whitespace. Not active in
  code, inline code or URLs.
- `composingActionTag` (a ValueListenable) drives the `SlashMenu` popover, anchored at the tag
  rect and flipped above when there is no space below.

### 21.2 Items

| Group | Item (aliases) | Command |
|-------|----------------|---------|
| Basic | Text (`p`, `normal`) | `write.format.blockType {paragraph}` |
| | Heading 1–6 (`h1`…`h6`, `title`) | `write.format.blockType {headingN}` |
| | Bulleted list (`ul`, `bullet`, `-`) | `write.list.toggleBulleted` |
| | Numbered list (`ol`, `1.`) | `write.list.toggleNumbered` |
| | Checklist (`todo`, `task`, `[]`) | `write.list.toggleChecklist` |
| | Quote (`blockquote`, `>`) | `write.format.blockType {quote}` |
| | Code block (`code`, `pre`, ```` ``` ````) | `write.format.blockType {codeBlock}` |
| | Divider (`hr`, `---`, `line`) | `write.insert.divider` |
| Media | Image (`img`, `picture`) | `write.insert.image` |
| | Image from URL | `write.insert.imageFromUrl` |
| | Table (`grid`) | `write.insert.table {3,3}` |
| Insert | Link | `write.link.insert` |
| | Mention person (`@`) | inserts `@` and opens the mention picker |
| | Emoji (P1) | `write.insert.emoji` (picker) |
| | Special character (P1) | `write.insert.specialCharacter` |
| | Date (P2) | `write.insert.date` |
| | Table of contents (P2) | `write.insert.tableOfContents` |
| | Comment | `shell.comments.create` (anchors to the current block) |
| AI (if enabled) | Ask AI… (`ai`) | `write.ai.inline` |
| | Continue writing | `write.ai.continue` |
| | Summarize above | `write.ai.summarizeAbove` |

### 21.3 Behaviour
- Fuzzy filtering on title and aliases, ranked by prefix match, then recent use, then group
  order. Max 10 rows visible, with scrolling. Each row shows the shortcut (`ShadKbd`) on the
  right.
- ↑↓ move, Enter/Tab run, Esc closes and keeps the typed text
  (`CancelComposingActionTagRequest`). Space when nothing matches closes it. Clicking outside
  cancels.
- Running an item calls `SubmitComposingActionTagRequest`, which removes `/query`, then runs
  the command **in the same undo step**. The label is the command's ("Heading 1").
- Commenters and Suggesting mode: only items that make sense as suggestions are enabled (text
  and blocks, not tables). Viewing mode: the menu never opens.

**AC-21.1** Typing `/h2` + Enter in an empty paragraph makes an H2 with no `/h2` text left. One
undo gives back the paragraph containing `/h2`.

## 22. Block commands, block selection and moving blocks

### 22.1 Block handle — removed
There is no block handle (the ⋮ next to the hovered block) and no view pref for it; the
`BlockHandleLayerBuilder` layer, its gutter and the `onBlockHandleTap` callback are gone.

### 22.2 Block menu — removed
There is no block menu. Its commands remain as commands (palette, MCP, shortcuts) and, where
they apply, in the context menu (05 §6: *Turn into*, image/table/code items, Move up/down):
- `write.block.turnInto {type, nodeId?}` (Text, Heading 1–6, Bulleted, Numbered, Checklist,
  Quote, Code block)
- `write.block.duplicate` (embeds get a new id), `write.block.copyLink` (headings only),
  `write.block.copyAsMarkdown`, `write.block.delete`
- `write.block.moveUp` / `write.block.moveDown` (§22.4)

### 22.3 Block selection
- Embeds are selected by click or arrow (§4, §5). For text blocks, `Esc` with a collapsed caret
  enters **block selection** of the current block (P1 for text blocks). Internally this is a
  normal `DocumentSelection` covering the whole node(s) plus the controller flag
  `blockSelection: true`.
- `BlockSelectionLayerBuilder` renders a 2 px `ring` outline and a `selection` fill at 30 %.
- Keys in block selection:
  - ↑/↓ move the block selection; Shift+↑/↓ extend it.
  - Enter puts the caret at the end of the block.
  - Backspace/Delete delete the blocks; Mod+C/X copy or cut them.
  - Esc a second time leaves block selection, so the next Tab moves focus out of the editor
    (§37.3).
  - Typing replaces the block with a paragraph containing the typed character.

### 22.4 Moving blocks
| Command | macOS | Win/Linux |
|---------|-------|-----------|
| `write.block.moveUp` | ⌃⇧↑ | Alt+Shift+↑ |
| `write.block.moveDown` | ⌃⇧↓ | Alt+Shift+↓ |
| `write.block.move {nodeIds, toIndex}` | (MCP) | |

- Moves the blocks touched by the selection.
- A **list item moves with its descendants**: the contiguous following items with greater
  indent. The schema guard re-clamps indents after the move.
- Uses `MoveNodeRequest`s in one transaction, one undo step "Move block". In the Delta this is
  delete + insert. Concurrent remote edits inside a block that is being moved in the same
  instant may be lost (a documented OT limitation of moves). Moves are disabled in Suggesting
  mode.

### 22.5 Drag to reorder — removed
Dragging blocks by the handle was removed (drops landed unreliably), and the handle itself is
gone (§22.1); blocks move with `write.block.moveUp` / `moveDown` (`Alt+Shift+↑/↓`, §22.4) and
the context menu's *Move up* / *Move down* on embeds.

**AC-22.1** *Move down* on a bullet that has two indented children moves all three items. One
undo moves them back.
**AC-22.2** Alt+Shift+↑ on the first block does nothing (the command is disabled).

## 23. Clipboard

### 23.1 Package decision
Use **`super_clipboard` 0.9.1** directly, not `super_editor_clipboard`. Reasons:
- Paste must go through *our* pipeline (HTML/Markdown importers in `wonky_write_core` →
  Wonky Delta → schema-filtered apply). `super_editor_clipboard` converts straight into
  `super_editor` nodes, which bypasses the schema guard, the Delta path and suggestion
  rewriting.
- We need multi-format **write** (plain, HTML, our private Delta) and multi-format **read**
  (HTML, plain, image files, URIs). `super_clipboard` exposes exactly that through
  `SystemClipboard`, `DataReader`, `Formats.*` and `CustomValueFormat`.
- The web paste and copy events are available through `ClipboardEvents`.
- It avoids coupling our clipboard to `super_editor` dev releases.

`super_drag_and_drop` (same family, same native extensions) is used for drag and drop (§24).
Desktop builds need the precompiled `super_native_extensions` binaries (cargokit). Document
this in the build README.

### 23.2 Copy and cut
`write.edit.copy` (Mod+C), `write.edit.cut` (Mod+X, one undo step "Cut"). `ClipboardWriter`
writes:

| Format | Content |
|--------|---------|
| `text/plain` | **Markdown** of the selection (setting *Copy plain text as Markdown*, default on). When off: readable plain text (bullets `• `, numbers `1. `, tasks `☐ `/`☑ `, tables as TSV, images as `[image: alt]`) |
| `text/html` | Semantic HTML from the core `HtmlExporter` (h1–h6, p, ul/ol/li with nested lists, input checkbox, blockquote, pre>code class="language-x", table, img with signed URL, a). The root element carries `data-wonky-delta="<base64 gzip delta JSON>"` |
| Custom `dev.wonky.write.delta` (desktop only) | The Delta JSON of the selection |

- Comment anchors (`cmt_*`) are **never** copied.
- Suggestions are copied in the **accepted** view: pending deletions are omitted, pending
  insertions become normal text.
- Mentions keep `mention` and `link`.
- On **web**, copy and cut are served inside the browser `copy`/`cut` event
  (`ClipboardEvents.registerCopyEventListener`). Mod+C/X therefore let the native event fire,
  and menu or toolbar Copy uses the async Clipboard API (`text/plain` and `text/html` only).
- Extra commands:
  - `write.edit.copyAsMarkdown`: plain text = Markdown, always.
  - `write.edit.copyAsPlainText`.
  - `write.edit.copyAsHtml`: HTML source as plain text.
- Viewers and commenters can copy only if the owner allows ("Viewers and commenters can see
  the option to download, print and copy", suite 06). Otherwise copy is disabled, with a toast
  on the shortcut.

### 23.3 Paste (`write.edit.paste`, Mod+V)
`PastePipeline.run(reader, target)` picks the **first available** representation:

1. **Wonky Delta** (custom format, or `data-wonky-delta` inside HTML). Validate with
   `WonkyDeltaValidator`, strip `cmt_*`/`sug_*`, assign **new ids** to embeds (avoids
   embed-identity collisions), then insert.
2. **Image files / image data** (`Formats.png/jpeg/gif/webp`, file URIs with image MIME):
   upload flow §17.2 at the caret.
3. **`text/html`**: `HtmlImporter` (core, shared with file import) → Delta:
   - `b/strong`/`font-weight≥600` → bold; `i/em`/`font-style:italic` → italic;
     `s/del/strike`/`line-through` → strike; `code`/`kbd`/`samp`/monospace font-family →
     code.
   - `h1–h6` → headers; `p/div` → paragraphs; `br` → U+2028.
   - `ul/ol` nesting → list + indent; `li` with checkbox → task.
   - `blockquote` → quote (nested flattened).
   - `pre` → code block, language from `class="language-x|lang-x"`.
   - `table` → table embed (`th`/first row → header, `colspan` split, block content
     flattened).
   - `img` → image embed: `data:` URIs are uploaded; `https:` is kept as URL (P1: option
     to re-host); `http:` is dropped with a warning.
   - `hr` → divider; `a[href]` → link (URL policy §11.2).
   - Google Docs wrapper `<b id="docs-internal-guid-…" style="font-weight:normal">` is
     ignored. MS Word `mso-list` paragraphs → lists (best-effort).
   - All disallowed styling (underline, color, background, fonts, sizes, alignment,
     sub/sup) is dropped.
4. **`text/plain`**:
   - If `MarkdownDetector.looksLikeMarkdown(text)` → `MarkdownCodec.import`. The detector
     needs ≥ 2 distinct Markdown signals, or one unambiguous block construct (fence,
     table delimiter row, ATX heading at line start, task marker).
   - Else plain: `\r\n`→`\n`, each line → a paragraph, tabs → 4 spaces, control chars
     removed.
   - A single URL → linked text (or link the selection, §23.4).

**Insertion semantics at the target:**
- The first pasted line's inline content merges into the current block. The current block
  type is kept unless the current block is an empty Normal paragraph, in which case the
  pasted type wins.
- The last line merges with the text after the caret.
- A non-empty selection is deleted first, in the same transaction.
- **In a code block**: always plain text (format 4, no Markdown detection). Newlines stay
  newlines.
- **In a heading**: multi-block content splits the heading as above.

**Undo and modes:**
- One paste = one undo step, "Paste".
- In Suggesting mode, everything inserted gets `sug ins` (§32).

**Size and feedback:**
- Pastes over 1,000,000 chars, or that would exceed the document limit, are refused with a
  toast.
- If anything was dropped, a toast says "Some formatting wasn't kept — Markdown supports
  bold, italic, strikethrough, code and links" with *Learn more* and *Don't show again*.
- Import warnings (flattened quotes, list starts) use the same toast.

**Web specifics:**
- Mod+V is served by the browser `paste` event
  (`ClipboardEvents.registerPasteEventListener`).
- Menu or toolbar Paste uses the async Clipboard API. Where it is unavailable or denied
  (Firefox HTML, Safari prompts), a toast says "Use ⌘V to paste" (Google Docs parity).

### 23.4 Paste variants
| Command | macOS | Win/Linux | Behaviour |
|---------|-------|-----------|-----------|
| `write.edit.pasteWithoutFormatting` | ⌘⇧V, ⌘⌥⇧V | Ctrl+Shift+V | `text/plain` only, no Markdown detection, no autolink. Lines → paragraphs in the current block type |
| `write.edit.pasteAsMarkdown` (P1) | — | — | Forces Markdown parsing of `text/plain` |
| URL over a selection | (Mod+V) | | If the clipboard is exactly one URL and the selection is non-empty text within one block, the selection becomes a link (setting-independent) |
| Autolink on paste | | | Bare URLs inside pasted plain text become links (setting *Autolink*, default on) |

**AC-23.1** Copying a range with a heading, list and table from Write and pasting it into
another Write document reproduces it exactly (ids differ).
**AC-23.2** Pasting from Google Docs keeps bold, italic, links, headings and lists, and drops
underline and colors with the toast.
**AC-23.3** Pasting into a code block never creates formatting or new blocks.

### 23.5 Edit commands summary
`write.edit.selectAll` (Mod+A), `write.edit.delete` (Del with a selection; menu *Delete*),
`write.edit.insertText {text}`, `write.edit.insertMarkdown {markdown, position?: caret|
{offset}}`, `write.edit.replaceRange {start, length, markdown | text}`,
`write.edit.selectRange {anchor, head}` (not undoable, V). The last four are mainly for MCP and
AI. They run through the same pipeline as paste (§23.3, format 1 or 4).

## 24. Drag and drop (P1)

| Source → target | Behaviour |
|-----------------|-----------|
| Selected text inside the editor → elsewhere in the editor | Press on the selection and drag more than 4 px. A drop caret indicator follows. Drop **moves** the content (delete + insert, one undo step "Move text"). Holding Alt/⌥ at drop **copies** |
| Image files from the OS | Upload flow at the drop position (§17.2). The drop indicator is a horizontal line between blocks |
| `.md/.txt/.html/.docx` files from the OS | Popover "Insert contents of *file.md* here?" with **Insert** or **Cancel**. Insert imports via the core importers ([07](07-import-export-print.md)) at the drop position, one undo step |
| Text/HTML from other apps | Paste pipeline at the drop position |
| Other files | Toast "Can't insert this file type" |

- Drops from other applications are placed by a 2 px indicator: a caret for text, a line between
  blocks for files. Images are inserted as whole blocks there (upload flow §17.2), documents after
  the confirmation, as whole blocks.

Implementation: selection drags use patch **SE-6** (`TextDragController`); OS drops `ExternalDropSource` — on the web the browser's
`dragover`/`drop` events on the window (the default, opening the dropped file in the tab, is
always prevented). Native desktop builds have no OS drop channel yet (no drop plugin; a federated
plugin with a web implementation would double-handle web drops). Drops are refused in Viewing
mode and suggestion previews.

## 25. Find and replace

### 25.1 Entry points and commands
| Command | macOS | Win/Linux | Notes |
|---------|-------|-----------|-------|
| `write.find.open` | ⌘F | Ctrl+F | Opens the Find panel (05 §10.5). With a single-block selection, prefills the query |
| `write.find.openReplace` | ⌘⇧H | Ctrl+H | Panel with the replace row expanded (⌘H is reserved by macOS) |
| `write.find.next` | ⌘G, Enter in the field | Ctrl+G, F3, Enter | Wraps around; status text "Wrapped to top" |
| `write.find.previous` | ⌘⇧G, ⇧Enter | Ctrl+Shift+G, Shift+F3 | |
| `write.find.replace` | — (button) | | Replaces the active match and goes to the next. One undo step "Replace" |
| `write.find.replaceAll` | — (button, Mod+Alt+Enter in the replace field) | | **One** transaction and one undo step "Replace all (42)" |
| `write.find.close` | Esc in the panel | | Focus returns to the editor with the active match selected |
| `write.find.setQuery {query, matchCase?, wholeWord?, regex?, replacement?, scope?: document\|selection}` | | | MCP and panel binding (not undoable, V) |

### 25.2 Matching
- `FindController` searches a **plain-text projection** per text node. Matches never span nodes.
- Code blocks are included. P1: table cells (read-only results labelled "in table"; replace
  rewrites the cell via the table embed) and image alt text (P2).
- Options: *Match case*, *Whole word* (Unicode word boundaries), *Regular expression* (Dart
  `RegExp(unicode: true, multiLine: true)`). An invalid regex shows an inline error and no
  matches. Scope: *Whole document* or *Selection* (P1).
- Replacement syntax with regex: `$1`…`$9`, `$<name>`, `$&`, `$$`. Without regex the
  replacement is literal.
- Incremental: debounced 150 ms after query or document changes. Only changed nodes are
  rescanned (cached per `nodeId` + text hash). The scan is chunked (yields every 4 ms of
  work) so typing stays responsive. The count caps at 10,000 ("10,000+").
- Suggestions: matches are found in visible text, including pending insertions and
  deletions. Replacing in Suggesting mode creates suggestions.
- Remote ops: match ranges are transformed and then rescanned (debounced). The active match
  index is kept stable when possible.

### 25.3 Highlighting
- `FindMatchesLayerBuilder` (underlay) paints `findMatch` behind every match **inside the
  viewport** (with 1 viewport of overscan), and `findMatchActive` behind the active one.
- Rects come from `DocumentLayout.getComponentByNodeId(nodeId)` → `TextComposable`
  per-line boxes (falling back to `DocumentLayout.getRectForSelection`).
- The active match scrolls into view, centred vertically if off-screen.
- The panel shows "3 of 42" and a per-block mini-list (P1).

### 25.4 Replace semantics
- Replacing keeps the inline formatting of the first replaced character. The replacement is
  inserted with the attributes of `match.start`.
- Replace-all composes all replacements into a single Delta (back to front), so it is one
  undo step and one op.
- In Suggesting mode, each match becomes del(old) + ins(new) suggestions with one suggestion
  id per match.

**AC-25.1** Replace-all of "colour" → "color" (whole word, 120 matches) is one undo step and
takes < 100 ms on a 100-page document.
**AC-25.2** The regex `(\w+)@(\w+)` → `$2 at $1` swaps groups.
**AC-25.3** A collaborator typing above the active match keeps it highlighted on the same text.

## 26. Outline, headings navigation and internal-link navigation

- `OutlineController` keeps the **outline** (`{level, text, slug, nodeId, deltaOffset}` per
  heading, [02](02-document-model.md) §5) up to date incrementally, by watching only header
  nodes and block-type changes. Empty headings are omitted.
- **Current heading** = the last heading whose top is above `viewportTop + 25 %`. It is shown
  highlighted in the Outline panel (05 §10.1).
- Commands:
  - `write.nav.goToHeading {slug | nodeId | text}`: no args opens the palette in heading mode.
    Shortcut ⌘⌥G / Ctrl+Alt+G. The palette `#` prefix also lists headings.
  - `write.nav.nextHeading` / `write.nav.previousHeading` (§5).
  - `write.nav.documentStart` / `write.nav.documentEnd`.
  - `write.view.toggleOutline` (⌘⌥⇧O / Ctrl+Alt+Shift+O).
- Navigating to a heading:
  - The caret goes to the heading start, and the heading scrolls to 24 px below the viewport
    top (animated 200 ms; instant with reduce motion).
  - A history entry is pushed so **Back** (`Mod+[` on desktop, browser back on web) returns
    to the previous position.
  - The URL `?heading=<slug>` is updated with `replace` semantics.
- Opening `/d/<uuid>?heading=<slug>` scrolls there after the first layout, with the §11.3
  fuzzy fallback.
- `write.block.copyLink` (headings) copies `https://<host>/write/d/<uuid>?heading=<slug>`. Pasting
  that URL into Write converts it to `wonky://` (§11.2).

## 27. Word count and statistics

- `DocumentStatsService` (incremental, per-node cache) computes for the document and for the
  selection:

  | Stat | Definition |
  |------|------------|
  | Words | Matches of `[\p{L}\p{N}]+(?:['’\-][\p{L}\p{N}]+)*`. CJK ideographs/kana/hangul syllables count as one word each (Google Docs parity) |
  | Characters | UTF-16-independent: grapheme clusters, excluding block separators |
  | Characters excluding spaces | Graphemes that are not `\s` |
  | Paragraphs | Non-empty text blocks (code block = 1) |
  | Pages | Pages mode: computed page count (§29.3). Pageless: "—" |
  | Reading time | words / 238 wpm, rounded up to whole minutes |

- Counted text = the **visible accepted view**: pending deletions excluded, insertions
  included. This includes table cell text and code, and excludes image alt text and comments.
- Status bar (05 §11): "1,234 words", or with a selection "56 of 1,234 words". Click → dialog.
  Shown only while *Display word count while typing* is on (checkbox in the word count dialog,
  `write.view.toggleWordCount`, per-user preference, default off).
- Dialog: `write.tools.wordCount` (⌘⇧C / Ctrl+Shift+C), described in 05 §12.
- Live updates are throttled to 250 ms (1 s in large-document mode, §36).

**AC-27.1** "Hello, wörld! 日本語" counts 5 words.

## 28. Spellcheck and document language

### 28.1 Language
- `Document.language` (BCP-47). Defaults to the creator's UI locale at creation.
- Changed in File › Language… or Tools › Language: `write.doc.setLanguage {language}`. This is
  a meta change, undoable in domain `write.meta` (03 §6).
- It drives: the spellcheck dictionary, smart-quote style (P2), word segmentation hints, the
  export `lang` attribute and PDF metadata, and hyphenation in exports
  ([07](07-import-export-print.md)).
- Text direction is **not** set by language. It is detected per paragraph (§38).

### 28.2 Spellcheck (P1)
- **Why custom**: Flutter renders text itself, and the browser only sees the hidden IME
  textarea, so browser spellcheck cannot underline document text.
- **Checker**: pure Dart, Hunspell-compatible (`.aff` + `.dic`), in
  `wonky_write_core/lib/src/spellcheck/` (library `package:wonky_write_core/spellcheck.dart`) so it
  is usable on the server (AI proofread, MCP).
  - Supports PFX/SFX with conditions, compound flags (basic), REP/TRY suggestions, and
    edit-distance-2 suggestions bounded at 50 ms per word.
  - Runs on the UI thread in time slices of at most 8 ms, one slice per frame (post-frame
    callbacks; `Priority.idle` tasks starve while the caret blinks), on all platforms: the
    dictionary parse (en-US ≈ 20 ms in total) and the checking of changed blocks (≈ 2 µs per
    word), 120 ms after the last change, caret block first.
- **Dictionaries**: en-US, en-GB (SCOWL, MIT AND BSD), fr-FR (MPL-2.0), es-ES (LGPL/MPL),
  nl-NL (BSD-3), sv-SE (LGPL-3.0), da-DK (LGPL/MPL) — open-licensed Hunspell dictionaries via the
  `dictionary-*` npm packages; sources and licenses in `packages/wonky_spellcheck/dictionaries/LICENSES.md`.
  GPL-only dictionaries (de, it, nb) are not bundled; pt-BR and pl-PL are deferred for size.
  - Bundled as package assets of `wonky_spellcheck` (`dictionaries/<tag>.aff|.dic`, `index.json`;
    v2, Drive 05 D-7 — the engine is `package:wonky_spellcheck`, the `SpellEngine`, dictionary
    loading and spelling dialogs are `package:wonky_app/spellcheck.dart`) and fetched only
    when a document needs one (the web build downloads assets on demand). Language → dictionary:
    exact tag, en-AU/NZ/IE/ZA/IN → en-GB, other `en` → en-US, then the same primary language.
- **Scope**:
  - Visible blocks first, then the rest at idle. Re-checks changed nodes only.
  - Skipped: code blocks, inline code, links, mentions, URLs, emails, words with digits,
    ALL-CAPS (setting), CamelCase, and words under 2 chars.
  - Suggestions: a block is checked as it reads with its suggestions accepted — suggested
    deletions are left out, so `~~qi~~qu` + `ick` is checked as "quick", and struck text is never
    flagged.
- **Personal dictionary**: `UserPreferences.writeDefaults.personalDictionary` (synced, max
  10,000 words; Tools › Spelling › Personal dictionary… lists and edits it). *Ignore* applies per
  document for the session (in-memory). The word being typed (caret inside or at its end) is
  checked once the caret leaves it.
- **Rendering**: `SpellingAndGrammarStyler` style phase with `spellingErrorAttribution` (red
  wavy underline in the `destructive` token). Presentation-only (§2.5). When a flagged block is
  removed (Backspace merging pasted empty paragraphs, a delete), its underlines are cleared in
  a microtask, not from the document listener: that listener can run before `super_editor`'s
  layout has seen the removal, and a style phase marked dirty then restyles the stale view
  model, which still has the removed block. The layout threw ("No such position in document")
  and stopped updating, so the pasted line breaks stayed visible and couldn't be deleted (#21).
- **Interactions**:
  - Right-click a flagged word: the context-menu top section shows up to 5 suggestions
    (`write.spell.replace {nodeId, range, word}`, one undo step), *Ignore*
    (`write.spell.ignore {word}`) and *Add to dictionary* (`write.spell.addToDictionary
    {word}`).
  - `write.spell.nextError` (⌘' / Ctrl+') selects the next flagged word.
  - Tools › Spelling ▸ *Check spelling…* opens the dialog (05 §12): Change, Change all
    (one undo step), Ignore, Ignore all, Add.
  - Tools › Spelling ▸ *Underline errors* (`write.spell.toggle`, per-user setting
    `writeDefaults.spellcheck`) and *Ignore words in UPPERCASE*
    (`write.spell.toggleIgnoreUppercase`, `writeDefaults.spellcheckIgnoreUppercase`).
  - `write.spell.replace` takes Delta offsets `{start, length, word}`.
- Grammar is not supported (P2 through AI proofread, [suite 10](../10-ai-assistant.md)).

**AC-28.1** Typing "teh " underlines "teh" within 300 ms. Choosing "the" from the context menu
fixes it in one undo step.

## 29. Zoom, layout modes and pagination

### 29.1 Zoom
- Range 50–200 %. Steps: 50, 67, 75, 80, 90, 100, 110, 125, 150, 175, 200. Stored per user and
  document in local view prefs. Not undoable, not synced.
- Commands:
  - `write.view.zoomIn` / `write.view.zoomOut`: ⌘⌥= / ⌘⌥- (web and desktop), plus ⌘= / ⌘-
    on desktop.
  - `write.view.zoomSet {percent}`.
  - `write.view.zoomReset` (100 %; desktop ⌘0).
  - `write.view.zoomFit {mode: width|page}` (Pages: fit page width / whole page; Pageless:
    width only).
- Ctrl/⌘ + mouse wheel and trackpad pinch zoom around the pointer, snapping to steps on gesture
  end.
- **Implementation**: zoom scales the **stylesheet**, not the widget tree.
  `ZoomedStylesheetFactory` multiplies the font sizes, paddings, max widths, page dimensions,
  table and caret metrics and image size caps by `zoom × textScale`, where `textScale` is the
  OS accessibility text scale. The editor's subtree uses `MediaQuery(textScaler:
  TextScaler.noScaling)` so text isn't scaled twice. This keeps glyphs crisp and keeps
  hit-testing and IME rects exact. The stylesheet is memoised per (theme, brightness, zoom,
  layout).

### 29.2 Layout modes
`pageSetup.layout`: `pageless` (default for new documents, T-1; overridable in Settings ›
Write › Page & export › Default layout) or `pages`. The server applies the default when it
creates a document (blank, built-in templates, the welcome document *New here? Read me first*,
Markdown and templates without a page setup; `DriveService.newDocumentPageSetup`: the locale
defaults of 07 §6.1 with the user's layout, `writeDefaults.pageless`, Pageless unless it is
`false`). Copies, imports and user templates keep their own page setup. Phones always show
Pageless (suite 02 §6.1), whatever the setting. Set with `write.doc.setLayout {layout}` (View › Page layout ▸; also in Page setup).
This is a meta change, undoable (`write.meta`). The page setup model is owned by
[07-import-export-print.md](07-import-export-print.md).

| | Pages | Pageless |
|-|-------|----------|
| Canvas | `canvas` token with page cards (`page` token = theme page colour, 1 px border + shadow) | Full-width `page` colour |
| Content width | page width − left/right margins (A4 at 100 % = 794 px wide) | `min(theme.page.pagelessMaxWidth (default 760), viewport − 2×48)`, centred |
| Header/footer | Rendered from page setup in the margins (non-editable here; double-click opens Page setup › Header & footer) | None |
| Page numbers | Via tokens `{page}` / `{pages}` in header/footer | None |
| Images | Capped at content width and content height | Capped at content width |
| Comments margin | Right of the page if it fits beside it, else overlaying the canvas's right edge (05 §10.2) | Same, relative to the column |

### 29.3 Pagination engine (`PaginationController`)
Pages are **computed, never stored**. Manual page breaks are not supported (01 §4).

1. After each layout (post-frame, coalesced to one measure per frame), read every block's
   **natural position**: its laid-out rect (the text box for text blocks, the whole box for
   images, rules and tables) minus the gaps the layout was actually styled with
   (`PaginationStylePhase` reports them), so a measure is correct even before the layout picked
   up newer gaps. `super_editor` lays out all components (§36), so rects are always available.
   A measure runs after every editor rebuild **and after every layout of the document
   content**: the page chrome layer is rebuilt after each content layout and schedules it. So
   heights that change without an editor rebuild (an image that finishes loading, a web font,
   an upload preview replaced by the uploaded file, a collaborator's edit) are re-measured.
   The measure is **incremental** (CQ-42): a block whose node instance and component size are
   unchanged since the last measure keeps its natural rect, shifted by how far the blocks above
   it moved; only changed blocks, and the first unchanged block after them (to learn that
   shift), are measured through the layout. A caret move measures nothing; a keystroke two
   blocks. A new layout, page setup or zoom measures everything again.
2. Walk the blocks and fill pages of height `contentH = pageH − marginTop − marginBottom`:
   - A block that fits on the current page is placed there.
   - A block that would **start** in a page's bottom margin or in the gap between pages (for
     example because of the spacing above it) starts at the next page's content top.
   - **Keep-with-next**: a heading is moved to the next page if the first line of the
     following block (its whole box for an image) doesn't fit after it.
   - A block that doesn't fit but has height ≤ `contentH` is pushed to the next page. Images
     are capped at `contentH` (§17.3), so an image never straddles a page boundary.
   - A block taller than `contentH` (very long paragraph, code block or table) starts at the
     current position and **overflows** across page boundaries (see 4).
3. Gaps are applied by `PaginationStylePhase`. It sets extra top padding on the first block of
   each page: remaining space on the previous page + `marginBottom` + `pageGap` (16 px) +
   `marginTop`. The phase lives as long as the editor: `super_editor` disposes its style
   phases whenever it recreates its layout presenter (on a stylesheet change) and reuses them
   in the new one, so the phase keeps listening to the controller across that. The Pages
   stylesheet is memoized so the presenter is not recreated on every keystroke.
   `PageChromeLayerBuilder` paints the page cards, headers, footers and page numbers in the
   underlay, at offsets computed by the controller.
   The page cards are painted under the document, so the phase also gives the last block
   bottom padding (`tailPadding`): the rest of the last page below it plus the 48 px bottom
   canvas padding (05 §16). The document's scroll extent then reaches the last page's bottom
   edge, also when that page isn't full (#1). It is component padding, outside the measured
   box, so it never feeds back into the measure; the document padding would not do, since
   `super_editor` rebuilds its layout only when a component's view model changes.
4. **Oversized blocks (v1, P0)**: the page boundary inside the block is drawn as a **seam**.
   The two page cards touch, there is a dashed separator line in the margin areas, and the
   page number label sits in the gutter. Content is never hidden. **P1**:
   `PageSplitTextComponent`, a wrapper render box that lays out the inner text component once,
   adds the page gap at a line boundary (from line metrics), paints the child twice with clip
   rects and offsets, and maps hit-testing and `DocumentComponent` geometry (`getRectFor…`,
   `getPositionAtOffset`) across the gap. That gives true line-level splitting for paragraphs
   and code.
5. Repagination repeats until stable: a measure that changes the gaps re-lays out the
   document, which measures again. To avoid oscillation it uses natural positions and is
   frame-coalesced; at most 8 consecutive changing measures run before the next editor
   rebuild. v1 walks all blocks (one rect query per block); starting from the first page whose
   blocks changed height is P1. Budget ≤ 2 ms per edit on 100 pages.
6. **Print and PDF** use the exact line-level paginator in [07](07-import-export-print.md).
   The editor's page breaks are an approximation of those (the status bar only shows the word
   count, so there is no hint when they differ).

**AC-29.1** Switching Pages ⇄ Pageless keeps the caret's block at the same viewport y (±1
line) and is one undo step.
**AC-29.2** At 200 % zoom the caret, selection and remote cursors align pixel-exactly with
text.
**AC-29.3** A heading at the bottom of a page moves to the next page together with its first
paragraph line.

## 30. Focus mode and typewriter scrolling (removed)

Removed from the product: focus mode (`write.view.toggleFocusMode`, `FocusModeStylePhase`,
`FocusModeChrome`) and typewriter scrolling (`write.view.toggleTypewriter`), with their prefs.
The editor chrome is always shown (05 §3.3).

## 31. View modes and read-only rendering

| Mode | Who | Widget | Behaviour |
|------|-----|--------|-----------|
| **Editing** | Editor, Owner | `SuperEditor` | Full editing |
| **Suggesting** | Commenter (default for them), Editor/Owner (opt-in) | `SuperEditor` + suggestion rewrite (§32) | All edits become suggestions |
| **Viewing** | Everyone (default for Viewers) | `SuperReader` | Read-only. Selection, copy (if allowed), find, comment (if role ≥ commenter or viewers-see-comments for reading) |

- Command `write.mode.set {mode}`. Shortcuts: Editing ⌘⌥⇧Z / Ctrl+Alt+Shift+Z, Suggesting ⌘⌥⇧X
  / Ctrl+Alt+Shift+X, Viewing ⌘⌥⇧C / Ctrl+Alt+Shift+C. `isEnabled` depends on the role. Not
  undoable. The mode is remembered per user and document in local prefs. The UI is the mode
  switcher (05 §15).
- Switching widgets (`SuperEditor` ⇄ `SuperReader`) reuses the **same** `MutableDocument`,
  stylesheet and layers. The scroll anchor (top visible node + intra-node offset) and the
  selection are preserved. The editor focus node is released in Viewing mode.
- Viewing mode shows the document without suggestions (a read-only preview document with its
  own layout key); in the Pages layout it is paginated and drawn on pages like the editor
  (the pagination phase and page chrome measure whichever document is shown, §29.3).
- **Mode guard** (`wonkyModeGuardHandlers`): in Viewing mode, every content-mutating
  `EditRequest` (inserts, deletes, attribution changes, node changes) is refused before any
  command runs. Selection and composing requests pass. This is a backstop: commands already
  report `isEnabled == false`.
- **Rendering of suggestions in Viewing mode**: the **original** view by default (pending
  insertions hidden, pending deletions shown as normal text). View › *Preview suggestions ▸
  Show suggestions / Preview accepted / Preview original* (`write.view.suggestionPreview
  {mode}`) applies in all modes. In Editing and Suggesting the default is *Show suggestions*.
  Rendering-only (a style phase hides or shows runs). Hidden runs are excluded from find and
  word count.
- **Role changes live** (`RoleChanged`, 03 §1.2): downgrading to Viewer switches to Viewing
  immediately, with the toast "Your access changed to Viewer". Outbox ops that are no longer
  allowed are handled per suite 03 §4. Downgrading to Commenter switches Editing to
  Suggesting.
- Viewer UI: the mode switcher shows "Viewing" with a *Request edit access* button
  (`shell.sharing.requestAccess {role: editor}`).

**AC-31.1** A Viewer pressing keys in the document changes nothing, and no op is ever sent.
**AC-31.2** Switching Editing → Viewing → Editing at 60 % scroll keeps the same visible text.

## 32. Suggesting mode mechanics

The suggestion data model, accept and reject, and the margin cards are owned by
[08-comments-suggestions-history.md](08-comments-suggestions-history.md). This section defines
only **how editor input turns into `sug_*` attributes**. They are carried by
`SuggestionAttribution(id, type, authorUuid, at, before)` ([02](02-document-model.md) §4.2).

### 32.1 Request rewriting (`wonkySuggestionRewriteHandlers`, active in Suggesting mode)

| Original request(s) | Rewritten effect |
|---------------------|------------------|
| Text insertion (typing, IME, paste, autoformat inline text) | Insert the text with `sug ins` (by = me, at = now, id = current **suggestion group id**) |
| Deletion of text that carries **my own** `ins` suggestion | Real deletion (retracts my suggestion) |
| Deletion of any other text, including others' `ins` | Do **not** delete. Add `sug del` to the range. The caret moves as if deleted (Backspace moves left past it) |
| Deletion across a block boundary (merge) | Mark the `"\n"` with `sug del` (§44) |
| Inline formatting (bold, italic, strike, code, link set/remove) | Apply the change and add `sug fmt` with `before` = the previous inline attrs of each run |
| Block type, list type, indent, task check (line attributes) | Apply the change and add `sug fmt` on the line's `"\n"` with `before` = the previous block attrs (§44) |
| Enter (split) | Insert `"\n"` with `sug ins` (§44) |
| Insert image or divider | Embed insert with `sug ins` on the embed op (§44) |
| Delete image or divider | `sug del` on the embed (§44) |
| Table edit, block move, table insert | **Not suggestable in v1**: commands disabled with the tooltip "Switch to Editing to do this" (Editors) or "Not available in suggestions" (Commenters) |

- **Suggestion grouping**: consecutive insertions and deletions by the same user in the same
  block within 30 s without a caret jump share one suggestion id. They show as one card ("Add
  'quick brown'").
- Typing inside my own suggestion extends it (same id). Typing inside someone else's
  insertion creates a nested insertion with my id.
- Autoformat block prefixes in Suggesting mode produce `del` of nothing (the prefix was my own
  `ins`, so it is really deleted) plus a block `fmt`.
- Undo in Suggesting mode undoes the local op exactly like any other op (inverse Delta). So
  undoing a suggestion retracts it.
- Commenters' ops must satisfy the server's allowed shapes (03 §5). See §44 for the `fmt` gap.

### 32.2 Rendering (style phase + layers)
| Type | Rendering |
|------|-----------|
| `ins` | Text colour = `suggestionInsert` (green), no underline, `suggestionInsert` background tint |
| `del` | Text colour and strikethrough = `suggestionDelete` (red), `suggestionDelete` tint |
| `fmt` | Dotted underline in the author colour. The new formatting is shown, and the margin card describes it ("Formatted: Bold") |
| Block `fmt` | Left gutter bar (3 px) in the author colour next to the block |

Clicking suggested text activates its card (08). Hover shows a small tooltip: author, time,
and Accept/Reject icons (Editors only).

**AC-32.1** In Suggesting mode, selecting "old" and typing "new" produces `del`("old") + `ins`("new")
under one suggestion id. Rejecting restores "old" exactly.

## 33. Comment anchors

- Anchors are inline `cmt_<threadUuid>` attributes ↔ `CommentAttribution(threadUuid)`. The
  thread data comes from the comments service (suite 07).
- Creating a comment (`shell.comments.create`, ⌘⌥M / Ctrl+Alt+M) on a selection:
  1. Records a **local pending range** (tracked through remote ops with `transformPosition`,
     drawn with the `commentHighlightActive` color) — no op is sent yet.
  2. Shows the margin and opens the composer as a card in the margin at the anchor.
  3. On *Comment* (first save): creates the thread (client-supplied `threadUuid`) and, in the
     same undo step, submits the op adding `cmt_<threadUuid>` to the (transformed) range — a
     retain with only `cmt_*` keys (commenter-allowed shape). On cancel, the pending range is
     dropped; collaborators never see anything and no undo step remains. See
     [08 §1.2](08-comments-suggestions-history.md).
  
  With a collapsed caret, the anchor is the word at the caret, or the whole block if it is an
  embed.
- **Highlight**:
  - Open threads: the `inlineTextStyler` gives the `commentHighlight` background. Each extra
    overlapping open thread raises alpha by 15 %, capped at 2 overlaps.
  - The active thread uses `commentHighlightActive`.
  - Resolved or orphaned threads: no highlight.
  - Hidden in Viewing mode unless the role allows comments.
- **Edges (`CommentAnchorEdgeReaction`)**: text typed at the start or end of an anchor is
  **not** included. Text typed strictly inside **is**. Deleting all anchored text makes the
  thread orphaned (08 decides how it is shown).
- **Margin**: `CommentAnchorBoundsOverlay` (based on `AttributedTextBoundsOverlay`) reports
  each thread's first-line rect to `CommentMarginLayout`.
  - That layout stacks cards in the right margin, keeping order by anchor y and avoiding
    overlap. The active card aligns exactly to its anchor and pushes others.
  - Recomputed on layout changes and scroll, for visible threads plus 1 viewport of overscan.
  - The margin is the only place threads and suggestions are shown (05 §10.2): beside the page
    when it fits, otherwise overlaying the canvas's right edge; hidden below 600 px canvas
    width. It is shown/hidden with `shell.comments.togglePanel` (Write's `CommentsHost`).
- Clicking highlighted text activates the thread (the topmost one when overlapping). Keyboard:
  `write.nav.nextComment` / `previousComment` (⌃⌥⇧↓/↑ macOS; Ctrl+Alt+Shift+↓/↑).

## 34. Remote cursors, selections and follow mode

### 34.1 Data
`RemotePresenceModel` combines:
- `RemoteCursor` messages (03 §1.2), which carry Delta offsets at a revision. They are
  transformed through ops since that revision and then mapped to `DocumentPosition`s via
  `DeltaIndex`;
- the shared presence roster (suite 07 §1) for name, colour (`presence1…12` by user-id hash),
  `actorKind` and state.

The user's own other sessions are shown as "You (other tab)".

### 34.2 Rendering
- **Selections** (`RemoteSelectionLayerBuilder`, underlay): per-line boxes in the presence
  colour at 20 % alpha. Embeds get a 2 px outline in the presence colour.
- **Carets** (`RemoteCursorLayerBuilder`, overlay): a 2 px bar in the presence colour with a
  name flag (`RemoteCursorOverlay` primitives from `wonky_ui`).
  - The flag sits above the caret, or below it at the top of the viewport.
  - The flag shows for 3 s after the remote user's last movement and on hover.
  - The flag reads "Anna", or "Claude (via MCP)" with a bot icon for `actorKind` `mcp`/`ai`.
- `focused == false`: the caret is hidden and the selection is drawn at 10 % alpha. Presence
  state idle: caret at 50 % alpha.
- Only cursors within the viewport plus 1 viewport of overscan are laid out. Max 50 painted.
  Geometry is recomputed on document change, layout change and scroll (throttled to one per
  frame).
- Off-screen collaborators: small presence-colour chevrons at the top or bottom edge of the
  canvas with avatar initials. Clicking one scrolls to that cursor.
- Remote cursors are always shown (there is no setting; `write.view.toggleRemoteCursors` was
  removed).

### 34.3 Local cursor broadcast
`CursorUpdate` is sent on selection change, throttled to 10/s (03 §1.1), and on focus change.
In Viewing mode cursors are still sent, so others see where viewers are.

### 34.4 Follow mode (P1)
- Clicking a collaborator's avatar (`PresenceAvatarStack`) runs `write.nav.goToCollaborator
  {sessionId}`: a one-time scroll that centres their caret.
- Avatar menu ⋮ → *Follow* runs `write.nav.follow {sessionId}`. The viewport keeps their caret
  within the middle band (20–80 %) and scrolls smoothly. A chip at the top of the canvas reads
  "Following Anna · Stop".
- Following stops on local scroll input, typing, Esc, *Stop* (`write.nav.stopFollowing`), when
  the followed user leaves, or when they open another document. In the last case a toast
  offers "Anna opened *Q3 notes* — Go there".

## 35. Undo and redo (Write specifics)

`shell.edit.undo` (⌘Z / Ctrl+Z) and `shell.edit.redo` (⌘⇧Z / Ctrl+Shift+Z, Ctrl+Y) run the
suite `UndoService` with the `write.content` handler (03 §4). `super_editor` history is
disabled and its undo and redo key actions and selectors are removed (§41).

| Gesture | Undo step(s) | Label |
|---------|--------------|-------|
| Typing (coalesced, §3.3) | 1 per group | Typing |
| Backspace/Delete runs | 1 per group | Delete |
| Autoformat or smart-typography substitution | 1, separate from the trigger keystroke | Autoformat / Smart quote |
| Any command | 1 | Command title ("Bold", "Heading 2", "Insert table") |
| Paste / Cut / drop | 1 | Paste / Cut / Move text |
| Replace all | 1 | Replace all (n) |
| Table editor Done | 1 | Edit table |
| Slash command | 1 (removal of `/query` + action) | Item title |
| AI or MCP tool call | 1 | AI: … / Agent: … |
| Meta changes (theme, page setup, layout, language, title) | 1 each, domain `write.meta` | Change page setup … |

- Undo restores `selectionBefore` and scrolls it into view. Redo restores `selectionAfter`.
- Remote ops rebase the stacks (03 §4). Partially rebased steps show the suite toast.
- Undo inside open popovers and dialog fields (link field, table editor, alt dialog) is
  handled by those fields (scope `dialog`) and never reaches the document stack.
- Undo history popover (*Edit › Undo history…*, suite 08 §3.5) lists Write step labels.
- Stacks persist in `LocalUndoStack` (suite 12) per document.

**AC-35.1** User A types, user B types above A's text, and A presses ⌘Z three times. Only A's
text disappears and B's text is untouched (property test in 03 §8).

## 36. Performance and large documents

Budgets: [03-sync-protocol.md](03-sync-protocol.md) §7 (keystroke → render < 16 ms p95 on 100
pages; cached open < 300 ms).

**Layout characteristics (`super_editor` 0.3.0-dev.52)**: `SingleColumnDocumentLayout` builds
**every** component in a `Column` (wrapped in a `SliverToBoxAdapter`), with no viewport
virtualisation. The presenter pipeline (`SingleColumnLayoutPresenter` + style phases) rebuilds
only components whose view model changed. Mitigations are mandatory:

1. **Stable stylesheet and phases.** Memoise the stylesheet per (theme, brightness, zoom,
   layout). Style phases must mark *only* affected components dirty (per-node caches in
   highlight, spellcheck, find and pagination phases).
2. **Layers paint only the viewport.** A cached prefix array of component offsets (updated
   post-layout) answers "nodes in [y0, y1]" by binary search. Remote cursors, find highlights,
   and comment bounds use it.
3. **O(log n) index**: `DeltaIndex` (Fenwick) for every offset ⇄ position conversion. The
   extractor's fast path avoids full serialisation.
4. **Debounced derived work**: syntax highlighting 120 ms, find 150 ms, stats 250 ms,
   spellcheck idle, outline incremental, pagination frame-coalesced.
5. **Images**: `cacheWidth` decoding, at most 4 concurrent decodes, offscreen images keep a
   placeholder size from `ImageSizeCache`.
6. **Initial load**: on desktop, Delta → node mapping runs in an isolate (`compute`) for
   documents > 200 KB. On web it runs in 8 ms chunks before first paint, with a progress
   skeleton.

**Large-document mode** applies automatically at > 5,000 nodes or > 500,000 chars. In this mode:
- stats update every 1 s;
- syntax highlighting and spellcheck cover the viewport only;
- remote selections are capped at 20;
- pagination runs at most once per 500 ms while typing.

**Benchmarks (CI perf job, profile mode)**: the fixtures `bench_100_pages.md` (~50k words,
~2,500 nodes, 20 tables, 40 images, 30 code blocks) and `bench_2m_chars.md` measure keystroke
latency, scroll FPS, open time, replace-all, paste of 100 KB, and remote op apply rate (100
ops/s). Regressions over 10 % fail the job.

**As built (CQ-38, CQ-42, CQ-49)**:

- **Perf suite**: `wonky_write/test/perf/` (tag `perf`, skipped by default; `flutter test -t
  perf --run-skipped test/perf`, with `WONKY_PROFILE=1 … --enable-vmservice` it prints the
  VM CPU profile of each scenario). `bench_100_pages` is generated (`BenchDocument`: 50
  sections, 2,355 blocks, 53k words, 420k characters, 20 tables, 40 images, 30 code blocks,
  12 comment anchors, 6 suggestions). `write_perf_test.dart` drives the real document screen in a widget
  test (one action + one 16 ms frame per sample; debug JIT, debug invariant checks and
  semantics off) with median budgets of about twice the measured numbers;
  `sync_perf_test.dart` times the sync client primitives. Not wired into CI yet; profile-mode
  runs and `bench_2m_chars` are open. Medians on a Windows dev machine, before → after:

  | Scenario (100 pages) | Before | After |
  |---|---|---|
  | Keystroke, Pageless, comment margin | 487 ms | 124–134 ms |
  | Keystroke, Pages | 486 ms | 146 ms |
  | Caret move, Pages | 414 ms | 69 ms |
  | Keystroke, Suggesting | 483 ms | 130 ms |
  | Keystroke with 2,000 find matches | 199 ms¹ | 107 ms |
  | Select all / collapse | 824 ms | 440 ms |
  | Keystroke + server ack round trip | 142 ms¹ | 121 ms |
  | Remote op (200 undo steps) | 427 ms | 105 ms |
  | Ack prediction (normalize) | 9.7 ms | 0.3 ms |
  | Remote op on the server document | 0.9 ms | 0.07 ms |

  ¹ measured after the editor changes, before the item's own change (W-13, CQ-49).
  What is left is mostly `super_editor` itself: on every document change its presenter
  creates a view model for every block and runs every style phase over all of them, and the
  layout (a `Column`) relays out and repaints the whole document (no viewport
  virtualisation, P2 below).
- **The editor widget is not rebuilt per keystroke**: `WonkyEditor` reuses its `SuperEditor`
  widget while its inputs are unchanged (a new instance rebuilt `super_editor`'s layout, which
  walks every component); the screen rebuilds the editor only when the comment margin appears
  or disappears, not on every comments/suggestions notify.
- **Comments and suggestions per block**: `MirrorOverlays` keeps the overlay pieces
  (`CommentAnchors.pieces` / `SuggestionIndex.pieces`) of each mirror entry (immutable, per
  node), so a keystroke rescans one block; anchors and pending suggestions are summed from the
  cached pieces instead of serializing and re-parsing the whole document. Suggesting mode
  rewrites a change against a window around it (one character either side), not the whole
  document (a debug assertion compares with the full rewrite).
- **Style phases**: code highlighting returns the same highlighted view model while a block's
  input is equal (no copy and re-attribution of every token per keystroke) and forgets deleted
  blocks; tables no longer mutate the presenter's view model (they were rebuilt on every
  pass). `super_editor` patch SE-9 computes the selected nodes once per pass (select-all was
  O(n²)); `attributed_text` patch AT-2 builds log messages only when logged.
- **Layers**: find matches and collaborators' selections are measured only for the visible
  part of the document plus one screen above and below (a binary search over block tops);
  scrolling past that measures again.
- **Images** decode at the display width (`ResizeImage`, width × device pixel ratio rounded up
  to 256 px; never upscaled). The decode semaphore and offscreen placeholders of point 5 are
  open.
- **Toolbar format state** walks the selection's attribute runs without copying text and stops
  at the first run without the format.
- **Undo persistence** hashes the document only when the stacks are stored: when the app is
  hidden and when the document closes (was: 800 ms after every change).
- Not built yet: large-document mode, chunked/isolate mapping on open, the scroll/open/paste
  benchmarks.

**P2 contingency**: if budgets fail at 2M chars, contribute or fork a sliver-based lazy layout
for `super_editor` (components outside viewport ± N screens use cached heights) behind a
feature flag.

## 37. Accessibility

### 37.1 Semantics
- The editor root is `Semantics(textField: true, multiline: true, label: <doc title>, readOnly:
  viewing)`.
- Each component is wrapped by `SemanticsComponentWrapper`, which adds:
  - headings: `headingLevel: n` and the heading text;
  - list items: "bullet" / "1 of 5" / "checkbox, checked" (Flutter `Semantics(checked:)` for
    tasks);
  - quote: "quote";
  - code: "code block, <language>";
  - image: alt text, or "image, no description";
  - divider: "separator";
  - table: "table, 3 columns, 5 rows", with cells exposed as a semantics table (row/column
    headers).
- Mentions read as "mention Anna Berg". Links read as "link".
- `ui.get_semantics` (MCP) exposes the same tree.

### 37.2 Screen-reader support mode
- Tools › Accessibility › *Screen reader support* (`write.a11y.toggleScreenReaderMode`, ⌘⌥Z /
  Ctrl+Alt+Z, Google Docs parity). Auto-enabled when
  `MediaQuery.accessibleNavigation` is true.
- In this mode, `SemanticsService.announce` (polite) is used for:
  - the line or block text after vertical caret moves, and words after word moves;
  - selected text after selection changes (truncated to 200 chars);
  - formatting at the caret on request (`write.a11y.announceFormatting`, ⌘⌥A / Ctrl+Alt+A):
    "Heading 2, bold, link".
- Always announced, in either mode: formatting toggles ("Bold on"), block type changes
  ("Heading 2"), list level ("Level 3"), undo and redo labels ("Undid Typing"), autoformat
  ("Converted to bulleted list"), find results ("3 of 42"), slash and mention picker
  highlights, comment created, suggestion accepted or rejected, collaborator joined or left
  (suite 07), and upload completed or failed.

### 37.3 Keyboard
- Every popover is reachable and operable by keyboard: slash menu, link popover, mention
  picker, language picker and image toolbar (`Alt+F10` focuses the floating toolbar).
- Shift+F10 or the context-menu key opens the context menu for the caret/selection (05 §6).
- Leaving the editor: `Esc` (collapse the selection or select the block), `Esc` again, then
  `Tab` / `Shift+Tab` move focus to the next or previous region. `F6` / `Shift+F6` cycle
  regions (menubar → toolbar → document → side panel → status bar when shown), owned by 05 §19.
- Drag operations always have keyboard equivalents: move up/down commands, and the table
  editor move buttons.

### 37.4 Visual
- Caret width 2 px. The caret blinks per OS settings (no blink with reduce motion).
- The focus ring uses the `ring` token on block selection. Contrast ≥ 4.5:1 for suggestion and
  comment colours over text in both themes (verified in the theme tests, [06](06-themes.md)).

## 38. RTL and bidirectional text

- Per-paragraph direction is detected by `TextDirectionStylePhase` from the first strong
  character (`intl` `Bidi.estimateDirectionOfText`, falling back to the document language's
  direction). It is applied as `textDirection` in component view models. `super_editor`
  supports RTL layout per text component (see its `demo_rtl` example). Nothing is stored in
  the Delta.
- For RTL blocks: list markers, checkboxes and indentation mirror to the right; quote borders
  mirror.
- Caret movement: ←/→ move **visually**. Word jumps follow the visual direction.
  Home/End use the logical line start/end.
- Mixed-direction runs inside a line rely on Flutter's bidi layout. Selection highlights use
  the per-box rects (possibly several per visual line).
- Table cell alignment `null` means start-aligned per cell direction.
- An RTL application chrome (mirrored menus and panels) is P2 and is not covered by this spec.

**AC-38.1** A paragraph starting with Arabic text renders right-aligned with its bullet on the
right. → moves the caret visually right.

## 39. Robustness and edge cases

| Case | Required behaviour |
|------|--------------------|
| `OpRejected(invalidOp)` | Log with op details. Resync per 03 §3.2 (re-init from snapshot) while preserving the scroll anchor and selection as Delta offsets. Toast "We had to reload this document" |
| Integrity hash mismatch | 03 §3.2. The same UX, plus a recovery file of the local state |
| Permission downgrade with a pending outbox | Suite 03 §4: notice and download of unsaved changes |
| Remote op deletes the block containing the caret | Caret moves to the transformed position (the nearest surviving position). Open popovers anchored to that block close |
| Remote op deletes an image that is uploading locally | The upload continues (bytes kept 24 h) but no embed exists. If the user undoes the remote deletion's effect, nothing happens (it is not their op). The queue entry is dropped after 24 h |
| Huge single paragraph (> 50,000 chars) | Allowed. A paste that would create it shows a "Very long paragraph" performance warning (once). Find and spellcheck chunk inside the node |
| Surrogate pairs / ZWJ emoji | Delta lengths are UTF-16 code units (as in Dart and Quill). The extractor and applier never split a surrogate pair. The caret moves by grapheme |
| CRLF, NUL, BOM in input | Normalised by the paste and IME paths and the schema guard |
| Empty document | Exactly one empty Normal paragraph with the placeholder "Type / for commands, or just start writing" (`WonkyHintComponentBuilder`, only when the document has a single empty block and the editor is focused or the doc is new) |
| Document at max size | §3.1 |
| Offline for days | Outbox composed per 2 s (03 §3.1). `RebaseTooOld` → "Save my offline changes as a copy" (suite 12) |
| Clock skew in suggestion `at` | The server clamps `at` to its own time ±5 min (08) |
| `super_editor` assertion or exception in a command | `CommandDispatcher` rolls back the undo transaction. The editor reloads the document from the last known-good Delta (`fullDelta` cache) without losing the outbox |

## 40. Command catalog (editor and content)

Role: V viewer, C commenter (C* = Suggesting-mode only for commenters), E editor. *U* = creates
an undo step. Shortcuts are listed as macOS / Win-Linux. `—` = none by default (bindable in
Settings → Keyboard).

| Command | Args | Shortcut | Role | U | Enabled when |
|---------|------|----------|------|---|--------------|
| `write.edit.cut` | — | ⌘X / Ctrl+X | C* | ✓ | Non-empty selection, not Viewing |
| `write.edit.copy` | — | ⌘C / Ctrl+C | V | — | Non-empty selection, copy allowed |
| `write.edit.copyAsMarkdown` | — | — | V | — | same |
| `write.edit.copyAsPlainText` | — | — | V | — | same |
| `write.edit.copyAsHtml` | — | — | V | — | same |
| `write.edit.paste` | — | ⌘V / Ctrl+V | C* | ✓ | Editing or Suggesting |
| `write.edit.pasteWithoutFormatting` | — | ⌘⇧V, ⌘⌥⇧V / Ctrl+Shift+V | C* | ✓ | same |
| `write.edit.pasteAsMarkdown` (P1) | — | — | C* | ✓ | same |
| `write.edit.selectAll` | — | ⌘A / Ctrl+A | V | — | always |
| `write.edit.delete` | — | Del (with selection) | C* | ✓ | Non-empty selection |
| `write.edit.insertText` | `text, position?` | — | C* | ✓ | Editing or Suggesting |
| `write.edit.insertMarkdown` | `markdown, position?` | — | C* | ✓ | same |
| `write.edit.replaceRange` | `start, length, markdown\|text` | — | C* | ✓ | same |
| `write.edit.selectRange` | `anchor, head` | — | V | — | always |
| `shell.edit.undo` / `shell.edit.redo` | — | ⌘Z / Ctrl+Z; ⌘⇧Z / Ctrl+Shift+Z, Ctrl+Y | C | (n/a) | Stack non-empty |
| `write.format.bold` | — | ⌘B / Ctrl+B | C* | ✓ | Text selected or caret in text, not code block |
| `write.format.italic` | — | ⌘I / Ctrl+I | C* | ✓ | same |
| `write.format.strikethrough` | — | ⌘⇧X / Ctrl+Shift+X | C* | ✓ | same |
| `write.format.inlineCode` | — | ⌘E / Ctrl+E | C* | ✓ | same |
| `write.format.clearFormatting` | — | ⌘\ / Ctrl+\ | C* | ✓ | same |
| `write.format.blockType` | `type` | ⌘⌥0–6, ⌘⇧., ⌘⌥C / Ctrl+Alt+0–6, Ctrl+Shift+., Ctrl+Alt+C | C* | ✓ | Selection touches a text block |
| `write.format.markdownHint` | `feature` | ⌘U, ⌘⇧E/L/R/J / Ctrl+U, Ctrl+Shift+E/L/R/J | V | — | always |
| `write.list.toggleBulleted` | — | ⌘⇧8 / Ctrl+Shift+8 | C* | ✓ | Text block in selection |
| `write.list.toggleNumbered` | — | ⌘⇧7 / Ctrl+Shift+7 | C* | ✓ | same |
| `write.list.toggleChecklist` | — | ⌘⇧9 / Ctrl+Shift+9 | C* | ✓ | same |
| `write.list.indent` | — | Tab | C* | ✓ | List/task items that can indent |
| `write.list.outdent` | — | ⇧Tab / Shift+Tab | C* | ✓ | List/task items in selection |
| `write.list.toggleChecked` | `nodeId?` | ⌘Enter / Ctrl+Enter (contextual) | C* | ✓ | Task in selection |
| `write.link.insert` | — | ⌘K / Ctrl+K | C* | — | Not code block |
| `write.link.set` | `url, text?, range?` | — | C* | ✓ | same |
| `write.link.edit` | — | — | C* | — | Caret in a link |
| `write.link.remove` | `range?` | — | C* | ✓ | Link in selection |
| `write.link.open` | `url?` | Mod+click, ⌥Enter / Alt+Enter on a link | V | — | Link at caret |
| `write.link.copy` | `url?` | — | V | — | Link at caret |
| `write.insert.image` | — | — | C* | (✓ on insert) | Not code block |
| `write.insert.imageFromUrl` | `url?, alt?` | — | C* | ✓ | same |
| `write.insert.imageFiles` | `files` (internal) | — | C* | ✓ | same |
| `write.insert.table` | `rows, cols` | — | E | ✓ | Editing, not code block |
| `write.insert.divider` | — | — | C* | ✓ | not code block |
| `write.insert.mention` | `userUuid, replaceComposing?` | (`@`) | C* | ✓ | not code |
| `write.insert.emoji` (P1) | `emoji?` | — | C* | ✓ | — |
| `write.insert.specialCharacter` (P1) | `char?` | — | C* | ✓ | — |
| `write.insert.date` (P2) | `format?` | — | C* | ✓ | — |
| `write.insert.tableOfContents` (P2) | — | — | E | ✓ | Editing |
| `write.block.turnInto` | `type, nodeId?` | — | C* | ✓ | Text block |
| `write.block.duplicate` | `nodeId?` | — | E | ✓ | Editing |
| `write.block.delete` | `nodeId?` | — | C* | ✓ | — |
| `write.block.moveUp` / `moveDown` | `nodeId?` | ⌃⇧↑/↓ / Alt+Shift+↑/↓ | E | ✓ | Not first/last, Editing |
| `write.block.move` | `nodeIds, toIndex` | (drag) | E | ✓ | Editing |
| `write.block.select` | `nodeId?` | Esc (collapsed caret) | V | — | — |
| `write.block.openMenu` | `nodeId?` | ⇧F10 on block selection | V | — | — |
| `write.block.copyLink` | `nodeId?` | — | V | — | Heading |
| `write.block.copyAsMarkdown` | `nodeId?` | — | V | — | copy allowed |
| `write.code.setLanguage` | `language, nodeId?` | — | C* | ✓ | Code block |
| `write.code.exit` | — | ⌘Enter / Ctrl+Enter (contextual) | C* | ✓ | Caret in code block |
| `write.code.copy` | `nodeId?` | — | V | — | Code block |
| `write.code.indentLines` / `outdentLines` | — | Tab / ⇧Tab in code | C* | ✓ | Code block |
| `write.image.editAlt` / `setAlt` | `nodeId?, alt, title?` | — | C* | ✓ | Image selected |
| `write.image.replace` / `replaceFromUrl` | `nodeId?, url?` | — | E | ✓ | Image selected, Editing |
| `write.image.download` | `nodeId?` | — | V | — | download allowed |
| `write.image.preview` | `nodeId?` | double-click | V | — | Image |
| `write.image.retryUpload` / `cancelUpload` | `nodeId?` | — | E | — / ✓ | Upload pending or failed |
| `write.table.edit` | `nodeId?, row?, col?` | Enter on a selected table | E | — | Table selected, Editing |
| `write.table.replace` | `nodeId, table` | (Done) | E | ✓ | Editing |
| `write.table.insertRow` / `insertColumn` / `deleteRow` / `deleteColumn` / `moveRow` / `moveColumn` / `setColumnAlignment` / `setCell` / `delete` | see §18.4 | — | E | ✓ | Editing |
| `write.table.copyAsTsv` | `nodeId?` | — | V | — | copy allowed |
| `write.find.open` / `openReplace` / `next` / `previous` / `close` | — | §25.1 | V (replace: C*) | — | — |
| `write.find.replace` / `replaceAll` | — | — | C* | ✓ | Matches exist |
| `write.find.setQuery` | `query, …` | — | V | — | — |
| `write.nav.goToHeading` | `slug\|nodeId\|text?` | ⌘⌥G / Ctrl+Alt+G | V | — | Outline non-empty |
| `write.nav.nextHeading` / `previousHeading` (P1) | — | ⌃⌥↓/↑ / Ctrl+Alt+↓/↑ | V | — | — |
| `write.nav.documentStart` / `documentEnd` | — | ⌘↑/↓ / Ctrl+Home/End | V | — | — |
| `write.nav.nextComment` / `previousComment` | — | ⌃⌥⇧↓/↑ / Ctrl+Alt+Shift+↓/↑ | V | — | Threads exist |
| `write.nav.goToCollaborator` | `sessionId` | — | V | — | Participant present |
| `write.nav.follow` / `stopFollowing` (P1) | `sessionId` | — | V | — | — |
| `write.spell.toggle` (P1) | `enabled?` | — | V | — | — |
| `write.spell.nextError` (P1) | — | ⌘' / Ctrl+' | V | — | Errors exist |
| `write.spell.replace` / `ignore` / `addToDictionary` (P1) | see §28.2 | — | C* / V / V | ✓ / — / — | — |
| `write.tools.wordCount` | — | ⌘⇧C / Ctrl+Shift+C | V | — | — |
| `write.doc.setLanguage` | `language` | — | E | ✓ (meta) | Editing |
| `write.doc.setLayout` | `layout` | — | E | ✓ (meta) | Editing |
| `write.view.zoomIn` / `zoomOut` / `zoomSet` / `zoomReset` / `zoomFit` | §29.1 | §29.1 | V | — | — |
| `write.view.toggleOutline` | — | ⌘⌥⇧O / Ctrl+Alt+Shift+O | V | — | — |
| `write.view.toggleWordCount` | — | — | V | — | — |
| `write.view.suggestionPreview` | `mode` | — | V | — | — |
| `write.mode.set` | `mode` | ⌘⌥⇧Z/X/C / Ctrl+Alt+Shift+Z/X/C | V | — | Role allows the mode |
| `write.prefs.setMarkdownShortcuts` / `setSmartTypography` / `setAutoPair` / `setAutolink` / `setCopyAsMarkdown` | `enabled` | — | V | — | — |
| `write.a11y.toggleScreenReaderMode` | — | ⌘⌥Z / Ctrl+Alt+Z | V | — | — |
| `write.a11y.announceFormatting` | — | ⌘⌥A / Ctrl+Alt+A | V | — | Screen-reader mode |
| `write.ai.inline` | `prompt?` | ⌘J / Ctrl+J (editor scope, contextual: caret in an empty paragraph or non-empty selection; otherwise falls through to `shell.ai.togglePanel`) | E | ✓ (on insert) | AI enabled |
| `write.ai.rewriteSelection` / `continue` / `summarizeDocument` / `summarizeAbove` | suite 10 | — | E | ✓ | AI enabled |
| `shell.comments.create` | anchor from selection | ⌘⌥M / Ctrl+Alt+M | C | ✓ | Selection or caret in text |
| `write.suggestions.*` | 08 | 08 | E | ✓ | 08 |

Menu-, panel- and dialog-level commands (File, View, Tools) are listed in
[05-screens-menus-toolbar.md](05-screens-menus-toolbar.md). MCP tools that wrap these
commands are in [09-mcp-and-ai.md](09-mcp-and-ai.md). Every command above is reachable through
`ui.invoke_command` and `ui.list_commands`.

## 41. `super_editor` keyboard actions and reactions disposition

### 41.1 Keyboard actions
`wonkyKeyboardActions(ime: true)` starts from `defaultImeKeyboardActions` (and the
non-IME list `defaultKeyboardActions` for tests):

| Disposition | Actions |
|-------------|---------|
| **Prepended (ours, in order)** | `keymapDispatchAction` (§2.7) → `openPopoverNavigationAction` (slash, mention, link, language pickers) → `blockSelectionKeysAction` (§22.3) → `codeBlockKeysAction` (Tab/Shift+Tab/Enter/Backspace in code, §15.2–15.3) → `enterToConvertCodeFenceAction` / `enterToConvertDividerAction` (§7.1) → `enterOnSelectedEmbedAction` (§6.1) → `backspaceIntoEmbedSelectsAction` / `deleteIntoEmbedSelectsAction` (§6.2–6.3) → `arrowIntoEmbedSelectsAction` (§5) → `mentionAtomicDeleteAction` (§19.3) → `autoPairAction` (§9) → `escToBlockSelectAction` (§4.2) → `tabConsumeAction` (no-op Tab outside lists/code, §13.3). All of these must sit **before** `sendKeyEventToMacOs` |
| **Removed** | `undoWhenCmdZOrCtrlZIsPressed`, `redoWhenCmdShiftZOrCtrlShiftZIsPressed` (our commands), `cmdBToToggleBold`, `cmdIToToggleItalics` (commands, so the dispatcher, roles and Suggesting mode apply), `pasteWhenCmdVIsPressed`, `copyWhenCmdCIsPressed`, `cutWhenCmdXIsPressed` (our clipboard, §23), `selectAllWhenCmdAIsPressed` (code-first select all), `tabToIndentParagraph`, `shiftTabToUnIndentParagraph`, `backspaceToUnIndentParagraph`, `enterToUnIndentParagraph` (paragraph indent is not in the schema), `collapseSelectionWhenEscIsPressed` (replaced by `escToBlockSelectAction`) |
| **Kept** | Caret movement, deletion (word/line), list and task indent/unindent/backspace actions (they produce `Indent/UnIndentListItemRequest`, `SetTaskIndentRequest`), `backspaceToConvertTaskToParagraph`, `backspaceToClearParagraphBlockType`, `enterToInsertNewTask`, `enterToInsertBlockNewline`, `shiftEnterToInsertNewlineInBlock`, web `doNothing…` actions, `doNothingWithCtrlOrCmdAndZOnWeb` (keeps the browser from running textarea undo; our keymap action runs first), `toggleInteractionModeWhenCmdOrCtrlPressed` (Mod-hover shows the link cursor) |

The macOS `selectorHandlers` are `defaultEditorSelectorHandlers` minus the `undo:` / `redo:`
selectors. Our keymap handles those.

### 41.2 Reactions (`wonkyReactions(prefs)`)
Order: `WonkyTypingAttributesReaction` (replaces `UpdateComposerTextStylesReaction`) →
`Toggleable(LinkifyReaction, autolink)` → `Marked(Toggleable(HeaderConversionReaction,
md))` → `Marked(Toggleable(UnorderedListItemConversionReaction, md))` →
`Marked(Toggleable(OrderedListItemConversionReaction, md))` →
`Marked(Toggleable(BlockquoteConversionReaction, md))` →
`Marked(Toggleable(HorizontalRuleConversionReaction, md))` →
`Marked(Toggleable(TaskConversionReaction, md))` → `Marked(Toggleable(CodeFenceConversionReaction,
md))` → `Marked(Toggleable(InlineCodeBacktickReaction, md))` →
`Marked(Toggleable(ImageMarkdownReaction, md))` (P1) → `Marked(Toggleable(DashConversionReaction,
smart))` → `Marked(Toggleable(EllipsisReaction, smart))` → `Marked(Toggleable(SmartQuotesReaction,
smart))` → `UpdateSubTaskIndentAfterTaskDeletionReaction` → `MentionAtomicityReaction` →
`CommentAnchorEdgeReaction` → plugin reactions (ActionTags, StableTags) →
`WonkySchemaGuardReaction` (**last**).

**Removed**: `ImageUrlConversionReaction`. It fetches arbitrary typed or pasted URLs over the
network to sniff content types, which is a privacy, CORS and offline problem. `![](…)` syntax
and the image dialog replace it.

`MarkdownInlineUpstreamSyntaxPlugin` is installed as a plugin, and its reactions are also
wrapped in `Marked(Toggleable(…, md))`.

## 42. Package and folder layout (`wonky_write/lib/`)

Feature folders are the unit of parallel work (suite 01 §4). The **owner** column is the
suggested work-package split (see [10-implementation-plan.md](10-implementation-plan.md)).

```
lib/
  commands/
    commands.dart                      # registers every Write command (one list per file below)
    edit_commands.dart                 # write.edit.*
    format_commands.dart               # write.format.*
    list_commands.dart                 # write.list.*
    link_commands.dart                 # write.link.*
    insert_commands.dart               # write.insert.*
    block_commands.dart                # write.block.*
    code_commands.dart                 # write.code.*
    image_commands.dart                # write.image.*
    table_commands.dart                # write.table.*
    find_commands.dart                 # write.find.*
    nav_commands.dart                  # write.nav.*
    view_commands.dart                 # write.view.*, write.mode.*
    doc_commands.dart                  # write.doc.*, write.file.* (05/07)
    spell_commands.dart                # write.spell.*
    prefs_commands.dart                # write.prefs.*, write.a11y.*
  features/
    editor/
      controller/                      # WriteDocumentController, EditorModeController, EditorViewState
      setup/                           # editor_factory.dart, super_editor_config.dart, keyboard_actions.dart,
                                       #   reactions.dart, selector_handlers.dart
      mapping/                         # DeltaDocumentMapper, DeltaIndex, attribution_mapping.dart (02 §4)
      applier/                         # DeltaApplier + custom EditCommands (ApplyRemoteDeltaCommand…)
      extractor/                       # ChangeDeltaExtractor, TransactionMarkers, attribution whitelist
      schema_guard/                    # WonkySchemaGuardReaction
      requests/                        # custom EditRequests/Commands (ReplaceEmbedRequest, InsertEmbedRequest…)
      attributions/                    # CommentAttribution, SuggestionAttribution, MentionAttribution,
                                       #   CodeTokenAttribution (presentation)
      reactions/                       # Task/CodeFence/InlineCode/Image/SmartQuotes/Ellipsis/Mention/Comment-edge,
                                       #   MarkedReaction, ToggleableReaction, WonkyTypingAttributesReaction
      keyboard/                        # keymapDispatchAction + every Wonky keyboard action (§41.1)
      components/                      # WonkyImageComponentBuilder, WonkyTableComponentBuilder,
                                       #   WonkyCodeBlockComponentBuilder, WonkyHintComponentBuilder,
                                       #   SemanticsComponentWrapper, PageSplitTextComponent (P1)
      styles/                          # stylesheet_builder.dart (theme→Stylesheet, 06), ZoomedStylesheetFactory,
                                       #   inline_text_styler.dart, style phases (code highlight, direction,
                                       #   suggestion preview)
      layers/                          # page_chrome, remote_selection, remote_cursor, find_matches, mention_chip,
                                       #   block_selection, comment_anchor_bounds, upload_progress,
                                       #   viewport_node_index.dart (offset prefix array)
      plugins/                         # slash (ActionTagsPlugin glue), mentions (StableTagPlugin glue),
                                       #   inline markdown plugin wiring
      paste/                           # PastePipeline, ClipboardWriter, MarkdownDetector, web clipboard events,
                                       #   drag & drop (DropRegion), paste warnings
      popovers/                        # SlashMenu, MentionPicker, LinkEditorPopover, LinkHoverCard,
                                       #   CodeLanguagePicker, ImageToolbar, FloatingSelectionToolbar (05 §5)
      suggesting/                      # suggestion rewrite request handlers, grouping, rendering phase
      read_only/                       # SuperReader configuration, mode guard handlers
      pagination/                      # PaginationController, PaginationStylePhase, page geometry (uses 07 model)
      zoom/                            # zoom controller, gesture handling
      a11y/                            # announcements, screen-reader mode
      rtl/                             # TextDirectionStylePhase
      ui/                              # WriteEditorView (canvas, scroll, layers wiring), DocumentCanvas
    images/                            # ImageUploadQueue, LocalPendingUpload store, ImageUrlResolver,
                                       #   ImageSizeCache, lightbox, alt dialog
    tables/                            # TableEditorPopover, TableDraft (+ local undo), grid widgets, TSV/HTML parse
    find_replace/                      # FindController, FindPanel (05), match index
    outline/                           # OutlineController, OutlinePanel (05), HeadingSlugger usage
    stats/                             # DocumentStatsService, word count dialog
    spellcheck/                        # SpellcheckController, dictionary loader/cache, context-menu glue
    presence/                          # RemotePresenceModel, follow mode, off-screen indicators
    comments/                          # Write anchor provider, CommentMarginLayout, margin cards host (08)
    suggestions/                       # SuggestionsController, suggestion cards (08; no panel)
    sync/                              # DocumentSyncController, outbox, LocalDocument cache (03, suite 12)
    undo/                              # WriteUndoHandler (write.content), WriteMetaUndoHandler (write.meta)
    special_chars/                     # dialog + bundled name table
    document_screen/                   # WriteDocumentScreen, header, menus/toolbar specs (05)
  mcp/                                 # ui.write.* tools (09)
```

`wonky_write_core` (pure Dart) holds `MarkdownCodec`, `HtmlImporter`/`HtmlExporter`,
`WonkyDeltaValidator`/`Normalizer`, `LinkUrlPolicy`, `HeadingSlugger`, `MarkdownDetector`,
the spell checker (`spell/`), word statistics (`stats/`) and the code-language alias table.
These are shared with the server and MCP.

New `wonky_ui` widgets introduced by Write are listed in 05 §21.

## 43. Test plan summary

| Layer | Tests |
|-------|-------|
| Unit (core) | Codec round-trip (02), `HtmlImporter` fixtures (Google Docs, Word, Notion, GitHub HTML), `MarkdownDetector`, `LinkUrlPolicy`, `HeadingSlugger`, word stats, spell checker against Hunspell reference outputs |
| Unit (flutter, no widgets) | Extractor fast path vs line diff, applier vs `compose`, schema guard, every reaction (input → expected document + undo split), suggestion rewrite table §32.1, pagination algorithm with synthetic heights |
| Command tests | Every command: execute → undo → redo, asserting structural document equality and selection (suite 08 §4) |
| Widget tests | Every AC in this spec; popovers keyboard navigation; light and dark goldens for components, layers and the Pages/Pageless canvas at 50/100/200 % |
| Integration (flutter_driver / MCP) | Typing and IME on web (Chrome), paste from fixtures, images offline queue, two-client convergence with cursors, table editor conflict banner |
| Performance | §36 benchmarks |
| Accessibility | Semantics tree snapshots, announcement log assertions, keyboard-only scripts for every popover and dialog |

## 44. Resolved cross-spec decisions

All points raised while writing this spec were resolved in the referenced specs:

1. `sug_*`/`cmt_*` overlay keys are allowed on line-end `"\n"` and on embeds —
   [02 §1.2–1.3](02-document-model.md).
2. Commenters may create `fmt` suggestions (retain with formatting change + `sug_* t:"fmt"` with
   verified `before`) — [03 §5](03-sync-protocol.md).
3. Contextual key bindings (ordered command lists per chord, first enabled wins) —
   [suite 08 §1.2](../08-commands-and-undo.md).
4. The command palette is `Mod+Shift+P`; `Mod+K` is *Insert link* in both apps — suite 08 §1.3.
5. `LocalPendingUpload` and the idempotent `FileEndpoint` with `pending` status —
   [suite 12 §1.1](../12-offline-and-sync.md).
6. Shared edit command ids `shell.edit.undo`, `shell.edit.redo`, … — suite 08 §1.2.
