import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../l10n/write_l10n.dart';
import '../document/write_document_session.dart';
import '../editor/controller/editor_types.dart';
import '../screen/write_document_controller.dart';
import 'ai_selection_menu.dart' show aiLanguageLabel, aiToneLabel;
import 'proofread_results.dart';
import 'write_assistant_adapter.dart';

/// What the inline AI preview shows.
enum AiPreviewKind {
  /// The prompt box (Mod+J / `/ai`) before a request.
  prompt,

  /// A rewrite of the selection (Replace / Insert below).
  rewrite,

  /// Text generated at the caret (Insert).
  generate,

  /// Continue writing: ghost text after the caret (Tab / Enter accepts).
  continuation,
}

enum AiPreviewStatus { idle, streaming, done, refused, failed }

/// The inline AI preview (`AiPreviewOverlay`, Write 09 §5.3): not part of
/// the Delta and not synced. The anchored range follows edits by the text
/// it covers; when someone changes it, only Insert below / Copy remain.
class AiPreview {
  AiPreview({
    required this.kind,
    required this.action,
    required this.title,
    required this.start,
    required this.length,
    required this.originalText,
    required this.originalMarkdown,
    this.tone,
    this.language,
    this.instruction,
  });

  final AiPreviewKind kind;

  /// Rewrite action (`improve`, `shorter`, …, `custom`, `continueWriting`).
  String action;
  String title;
  int start;
  int length;

  /// Plain text of the anchored range when the preview opened.
  final String originalText;
  final String originalMarkdown;
  final String? tone;
  final String? language;
  String? instruction;

  final StringBuffer _md = StringBuffer();
  AiPreviewStatus status = AiPreviewStatus.idle;
  String? error;

  /// The anchored text was changed by someone else.
  bool originalChanged = false;

  /// Shows a word diff against the original.
  bool showDiff = false;

  String get markdown => _md.toString();
  set markdown(String v) {
    _md
      ..clear()
      ..write(v);
  }

  bool get canApply =>
      status == AiPreviewStatus.done && markdown.trim().isNotEmpty;

  Map<String, Object?> toJson() => {
    'active': true,
    'kind': kind.name,
    'action': action,
    'range': {'start': start, 'length': length},
    'markdown': markdown,
    'status': status.name,
    'original_changed': originalChanged,
  };
}

/// Inline AI and the assistant panel of one open Write document (Write 09
/// §5): the selection ✨ menu, `/ai` and Mod+J prompt, continue writing,
/// summarize / outline / explain / proofread results in the panel, and the
/// [WriteAssistantAdapter] that specializes the shared panel.
class WriteAiController extends ChangeNotifier {
  WriteAiController({
    required this.services,
    required this.session,
    required this.doc,
    AssistantApi? api,
  }) : _apiOverride = api {
    adapter = WriteAssistantAdapter(this);
    session.contentVersion.addListener(_onContent);
    _byItem[session.itemUuid.uuid] = this;
  }

  static final Map<String, WriteAiController> _byItem = {};

  /// The controller of drive item [itemUuid].
  static WriteAiController? forItem(UuidValue? itemUuid) =>
      itemUuid == null ? null : _byItem[itemUuid.uuid];

  /// The controller of the active document of a command context.
  static WriteAiController? of(CommandContext ctx) {
    final d = ctx.document;
    if (d == null || d.kind != DriveItemKind.document) return null;
    return forItem(d.itemUuid);
  }

  final ShellServices services;
  final WriteDocumentSession session;
  final WriteDocumentController doc;
  final AssistantApi? _apiOverride;
  late final WriteAssistantAdapter adapter;

  bool _disposed = false;

  ShellAssistant? get assistant => ShellAssistant.of(services);

  /// The Write strings in the shell's locale.
  WriteLocalizations get l10n => writeL10nOf(services);

  /// The assistant API (the installed assistant's, or the test override).
  AssistantApi? get api => _apiOverride ?? assistant?.api;

  /// Whether AI requests can be sent (configured, enabled, not opted out).
  bool get available {
    if (!services.prefs.aiEnabled) return false;
    final a = assistant;
    if (a == null) return _apiOverride != null;
    return a.usable;
  }

  /// Whether AI UI is shown at all (the assistant is installed and AI is
  /// not switched off on the server or by the user).
  bool get shown =>
      services.prefs.aiEnabled &&
      (assistant?.available ?? _apiOverride != null);

  /// The panel controller of this document.
  AssistantController? get chat => assistant?.controllerFor(adapter);

  /// Whether AI suggestions instead of direct edits (panel toggle; forced
  /// for commenters and in Suggesting mode).
  bool get suggestMode =>
      doc.role < Role.editor ||
      doc.editor.mode == EditorMode.suggesting ||
      (chat?.applyMode == AiApplyMode.suggest);

  // ------------------------------------------------------------- preview

  AiPreview? _preview;

  /// The open preview (null = none).
  AiPreview? get preview => _preview;
  StreamSubscription<InlineAiEvent>? _stream;
  DateTime _lastRepaint = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether the selection allows a rewrite.
  bool get hasSelection {
    final s = doc.editor.selection;
    return s != null && !s.isCollapsed;
  }

  /// Whether the caret is in an empty paragraph (contextual Mod+J).
  bool get caretInEmptyParagraph {
    final s = doc.editor.selection;
    if (s == null || !s.isCollapsed) return false;
    final d = WonkyDocument(doc.editor.delta);
    if (s.start >= d.length) return false;
    final line = d.lineAt(s.start);
    return line.contentLength == 0 && !line.isEmbedLine;
  }

  /// Whether the caret is at the end of a block (continue writing).
  bool get caretAtBlockEnd {
    final s = doc.editor.selection;
    if (s == null || !s.isCollapsed) return false;
    final d = WonkyDocument(doc.editor.delta);
    if (s.start >= d.length) return false;
    final line = d.lineAt(s.start);
    return !line.isEmbedLine && s.start == line.newlineOffset;
  }

  bool get canWrite => doc.isLoaded && doc.role >= Role.commenter;

  /// Markdown of Delta range [start, end) (accepted view).
  String _markdownOf(Delta d, int start, int end) =>
      DocumentReader.renderMarkdown(
        d.slice(start, end),
        SuggestionViewMode.accepted,
      ).trimRight();

  (String, String) _context(Delta d, int start, int end) {
    final w = WonkyDocument(d);
    final first = w.lineAt(start.clamp(0, w.length - 1));
    final last = w.lineAt((end - 1).clamp(0, w.length - 1));
    final lines = w.lines;
    final before = lines.where((l) => l.index < first.index).toList();
    final after = lines.where((l) => l.index > last.index).toList();
    final b = before.length > 2 ? before.sublist(before.length - 2) : before;
    final a = after.length > 2 ? after.sublist(0, 2) : after;
    return (
      b.isEmpty ? '' : _markdownOf(d, b.first.start, first.start),
      a.isEmpty ? '' : _markdownOf(d, last.end, a.last.end),
    );
  }

  /// Opens the rewrite preview for the selection ([range] for agents) and
  /// requests [action] (`improve`, `fixGrammar`, `shorter`, `longer`,
  /// `tone`, `translate`, `custom`).
  Future<bool> rewriteSelection(
    String action, {
    String? tone,
    String? language,
    String? instruction,
    DeltaSelection? range,
  }) async {
    final sel = range ?? doc.editor.selection;
    if (sel == null || sel.isCollapsed || !available) return false;
    final d = doc.editor.delta;
    final text = PlainTextRenderer.render(d.slice(sel.start, sel.end));
    final p = AiPreview(
      kind: AiPreviewKind.rewrite,
      action: action,
      title: rewriteTitle(l10n, action, tone: tone, language: language),
      start: sel.start,
      length: sel.length,
      originalText: WonkyDocument(d).text.substring(
        sel.start,
        sel.end.clamp(sel.start, WonkyDocument(d).text.length),
      ),
      originalMarkdown: _markdownOf(d, sel.start, sel.end),
      tone: tone,
      language: language,
      instruction: instruction,
    );
    if (text.trim().isEmpty) return false;
    _open(p);
    await _request(p);
    return true;
  }

  /// The `/ai` / Mod+J prompt box at the caret (or for the selection).
  void openPrompt() {
    if (!available || !canWrite) return;
    final sel = doc.editor.selection;
    if (sel == null) return;
    final d = doc.editor.delta;
    final w = WonkyDocument(d);
    final p = AiPreview(
      kind: AiPreviewKind.prompt,
      action: 'custom',
      title: sel.isCollapsed ? l10n.aiAskToWrite : l10n.aiAskToEdit,
      start: sel.start,
      length: sel.length,
      originalText: w.text.substring(
        sel.start,
        sel.end.clamp(sel.start, w.text.length),
      ),
      originalMarkdown: sel.isCollapsed
          ? ''
          : _markdownOf(d, sel.start, sel.end),
    );
    _open(p);
  }

  /// Submits the prompt box.
  Future<void> submitPrompt(String instruction) async {
    final p = _preview;
    if (p == null || p.kind != AiPreviewKind.prompt) return;
    final text = instruction.trim();
    if (text.isEmpty) return;
    if (text.toLowerCase() == 'continue') {
      discard();
      await continueWriting();
      return;
    }
    final next = AiPreview(
      kind: p.length == 0 ? AiPreviewKind.generate : AiPreviewKind.rewrite,
      action: 'custom',
      title: text,
      start: p.start,
      length: p.length,
      originalText: p.originalText,
      originalMarkdown: p.originalMarkdown,
      instruction: p.length == 0
          ? 'Write new content for the empty spot marked as the selection: '
                '$text'
          : text,
    );
    _open(next);
    await _request(next);
  }

  /// Continue writing at the caret (ghost text).
  Future<bool> continueWriting({int? maxWords}) async {
    final sel = doc.editor.selection;
    if (sel == null || !available || !canWrite) return false;
    final p = AiPreview(
      kind: AiPreviewKind.continuation,
      action: 'continueWriting',
      title: l10n.cmdAiContinue,
      start: sel.end,
      length: 0,
      originalText: '',
      originalMarkdown: '',
    );
    _open(p);
    await _request(p, maxWords: maxWords);
    return true;
  }

  void _open(AiPreview p) {
    unawaited(_stream?.cancel());
    _stream = null;
    _preview = p;
    _notifyPreview();
  }

  void _notifyPreview() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> _request(AiPreview p, {int? maxWords, String? previous}) async {
    final a = api;
    if (a == null) return;
    final d = doc.editor.delta;
    final (before, after) = p.length == 0
        ? _context(d, p.start, p.start + 1)
        : _context(d, p.start, p.start + p.length);
    p
      ..status = AiPreviewStatus.streaming
      ..error = null
      ..markdown = '';
    _notifyPreview();
    final req = InlineAiRequest(
      itemUuid: session.itemUuid,
      action: p.action,
      revision: session.revision,
      start: p.start,
      length: p.length,
      selectedMarkdown: p.kind == AiPreviewKind.generate
          ? '(empty — write new content here)'
          : p.originalMarkdown,
      contextBefore: before,
      contextAfter: after,
      instruction: p.instruction,
      tone: p.tone,
      targetLanguage: p.language,
      previousOutput: previous,
      maxWords: maxWords,
    );
    final done = Completer<void>();
    _stream = a
        .inline(req)
        .listen(
          (e) {
            if (_preview != p) return;
            switch (e.type) {
              case InlineAiEventType.textDelta:
                p.markdown = '${p.markdown}${e.text ?? ''}';
                // Re-render at most every 50 ms while streaming.
                final now = DateTime.now();
                if (now.difference(_lastRepaint).inMilliseconds < 50) return;
                _lastRepaint = now;
              case InlineAiEventType.done:
                p
                  ..markdown = e.markdown ?? p.markdown
                  ..status = AiPreviewStatus.done;
              case InlineAiEventType.refusal:
                p
                  ..markdown = ''
                  ..status = AiPreviewStatus.refused
                  ..error = e.error ?? l10n.aiRefusal;
              case InlineAiEventType.error:
                p
                  ..status = AiPreviewStatus.failed
                  ..error = e.error ?? l10n.aiErrorGeneric;
            }
            _notifyPreview();
          },
          onError: (Object e) {
            if (_preview == p) {
              p
                ..status = AiPreviewStatus.failed
                ..error = errorMessage(e);
              _notifyPreview();
            }
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (_preview == p && p.status == AiPreviewStatus.streaming) {
              p.status = AiPreviewStatus.done;
              _notifyPreview();
            }
            assistant?.refreshStatus();
            if (!done.isCompleted) done.complete();
          },
        );
    await done.future;
  }

  /// Try again.
  Future<void> retry() async {
    final p = _preview;
    if (p == null || p.kind == AiPreviewKind.prompt) return;
    await _request(p);
  }

  /// Refines the result ("Make it more formal").
  Future<void> refine(String instruction) async {
    final p = _preview;
    if (p == null || !p.canApply) return;
    final previous = p.markdown;
    p.instruction = instruction;
    await _request(p, previous: previous);
  }

  /// Discards the preview.
  void discard() {
    unawaited(_stream?.cancel());
    _stream = null;
    if (_preview == null) return;
    _preview = null;
    _notifyPreview();
  }

  /// Copies the result.
  Future<void> copy() async {
    final p = _preview;
    if (p == null) return;
    await Clipboard.setData(ClipboardData(text: p.markdown));
    services.toasts.show(l10n.aiCopied);
  }

  void toggleDiff() {
    final p = _preview;
    if (p == null) return;
    p.showDiff = !p.showDiff;
    _notifyPreview();
  }

  /// Follows the anchored text through edits; flags it when it changed.
  void _onContent() {
    final p = _preview;
    if (p == null || p.length == 0) {
      if (p != null && p.kind == AiPreviewKind.continuation) _followCaret(p);
      return;
    }
    final text = WonkyDocument(doc.editor.delta).text;
    final end = p.start + p.length;
    if (end <= text.length && text.substring(p.start, end) == p.originalText) {
      return;
    }
    // Moved: the nearest occurrence of the original text.
    var best = -1;
    var from = 0;
    while (true) {
      final i = text.indexOf(p.originalText, from);
      if (i < 0) break;
      if (best < 0 || (i - p.start).abs() < (best - p.start).abs()) best = i;
      from = i + 1;
    }
    if (best >= 0) {
      p.start = best;
    } else if (!p.originalChanged) {
      p.originalChanged = true;
    }
    _notifyPreview();
  }

  void _followCaret(AiPreview p) {
    final s = doc.editor.selection;
    if (s == null || !s.isCollapsed || s.start != p.start) {
      // Typing elsewhere discards the ghost text.
      discard();
    }
  }

  /// Replaces the anchored range with the result as one undoable change
  /// ("AI: Improve writing"); a suggestion in Suggest mode.
  bool replace() {
    final p = _preview;
    if (p == null || !p.canApply || p.originalChanged) return false;
    if (p.kind != AiPreviewKind.rewrite) return insert();
    final d = doc.editor.delta;
    final EditResult r;
    try {
      r = DocumentEdits().replaceRange(
        d,
        ResolvedRange(p.start, p.length),
        p.markdown,
      );
    } on AddressException {
      return false;
    }
    final ok = applyChange(
      d,
      r.change,
      l10n.aiUndoLabel(p.title),
      r.appliedRange,
    );
    if (ok) discard();
    return ok;
  }

  /// Inserts the result as blocks below the range (rewrite) or at the
  /// caret (generate, continuation).
  bool insert({bool below = false}) {
    final p = _preview;
    if (p == null || !p.canApply) return false;
    final d = doc.editor.delta;
    final w = WonkyDocument(d);
    var md = p.markdown;
    int at;
    if (p.kind == AiPreviewKind.rewrite || below) {
      final lastLine = w.lineAt(
        (p.start + p.length - 1).clamp(0, w.length - 1),
      );
      at = lastLine.end < w.length ? lastLine.end : lastLine.newlineOffset;
      if (at == lastLine.newlineOffset) md = '\n\n$md';
    } else {
      at = p.start.clamp(0, w.length - 1);
      if (p.kind == AiPreviewKind.continuation &&
          at > 0 &&
          !RegExp(r'^\s').hasMatch(md)) {
        final prev = w.text[at - 1];
        if (prev.trim().isNotEmpty) md = ' $md';
      }
    }
    final EditResult r;
    try {
      r = DocumentEdits().insertMarkdown(d, at, md);
    } on AddressException {
      return false;
    }
    final l = l10n;
    final label = l.aiUndoLabel(
      p.kind == AiPreviewKind.continuation ? l.cmdAiContinue : p.title,
    );
    final ok = applyChange(d, r.change, label, r.appliedRange);
    if (ok) discard();
    return ok;
  }

  /// Applies an AI change locally: one undo step; rewritten into an AI
  /// suggestion (`via: ai`, ✨ badge) in Suggest mode.
  bool applyChange(
    Delta d,
    Delta change,
    String label, [
    ResolvedRange? applied,
  ]) {
    if (DeltaUtils.isNoop(change)) return false;
    var c = change;
    final suggest = suggestMode;
    if (suggest) {
      c = const SuggestionRewriter().rewrite(
        d,
        change,
        SuggestionContext(
          userUuid: session.userUuid,
          nowMs: DateTime.now().millisecondsSinceEpoch,
          suggestionId: services.ids.nextString(),
          via: 'ai',
        ),
      );
    }
    final end = applied == null ? null : applied.start + applied.length;
    return session.applyContentChange(
      c,
      label: label,
      source: LocalChangeSource.agent,
      bypassSuggesting: suggest,
      selectionAfter: end == null ? null : DeltaSelection.collapsed(end),
    );
  }

  /// Inserts [markdown] at the caret (or the document start) as one step.
  bool insertMarkdown(String markdown, {bool atTop = false, String? label}) {
    if (!canWrite || markdown.trim().isEmpty) return false;
    final d = doc.editor.delta;
    final w = WonkyDocument(d);
    final sel = doc.editor.selection;
    var at = atTop ? 0 : (sel?.end ?? w.length - 1);
    at = at.clamp(0, w.length - 1);
    final EditResult r;
    try {
      r = DocumentEdits().insertMarkdown(d, at, markdown);
    } on AddressException {
      return false;
    }
    return applyChange(
      d,
      r.change,
      label ?? l10n.aiUndoLabel(l10n.commonInsert),
      r.appliedRange,
    );
  }

  // ---------------------------------------------------------------- panel

  void _openPanel() {
    final a = assistant;
    if (a == null) return;
    a.openPanel();
  }

  InlineAiRequest _selectionRequest(String action) {
    final sel = doc.editor.selection;
    final d = doc.editor.delta;
    final hasSel = sel != null && !sel.isCollapsed;
    final (before, after) = hasSel ? _context(d, sel.start, sel.end) : ('', '');
    return InlineAiRequest(
      itemUuid: session.itemUuid,
      action: action,
      revision: session.revision,
      start: sel?.start,
      length: sel?.length,
      selectedMarkdown: hasSel ? _markdownOf(d, sel.start, sel.end) : null,
      contextBefore: before,
      contextAfter: after,
    );
  }

  List<AssistantResultAction> _insertActions({bool outline = false}) {
    final l = l10n;
    return [
      AssistantResultAction(
        id: 'insertCursor',
        label: l.aiInsertAtCursor,
        icon: LucideIcons.textCursorInput,
        onPressed: (md) => insertMarkdown(md),
      ),
      AssistantResultAction(
        id: 'insertTop',
        label: l.aiInsertAtTop,
        icon: LucideIcons.arrowUpToLine,
        onPressed: (md) => insertMarkdown(md, atTop: true),
      ),
      if (outline)
        AssistantResultAction(
          id: 'insertList',
          label: l.aiInsertAsList,
          icon: LucideIcons.list,
          onPressed: (md) => insertMarkdown(outlineAsList(md)),
        ),
      AssistantResultAction(
        id: 'copy',
        label: l.commonCopy,
        icon: LucideIcons.copy,
        onPressed: (md) => Clipboard.setData(ClipboardData(text: md)),
      ),
    ];
  }

  /// Explain / Summarize the selection in the panel.
  Future<void> explainSelection({bool summarize = false}) async {
    final c = chat;
    if (c == null || !available || !hasSelection) return;
    _openPanel();
    final r = c.addResult(
      summarize ? l10n.aiResultSelectionSummary : l10n.aiResultExplanation,
      actions: _insertActions(),
    );
    await c.streamInline(
      _selectionRequest(summarize ? 'summarize' : 'explain'),
      r,
    );
  }

  /// Tools › Summarize document.
  Future<void> summarizeDocument({String length = 'medium'}) async {
    final c = chat;
    if (c == null || !available) return;
    _openPanel();
    final r = c.addResult(
      l10n.aiResultDocumentSummary,
      actions: _insertActions(),
    );
    await c.streamInline(
      InlineAiRequest(
        itemUuid: session.itemUuid,
        action: 'summarizeDocument',
        summaryLength: length,
      ),
      r,
    );
  }

  /// Tools › Generate outline.
  Future<void> generateOutline({String? prompt}) async {
    final c = chat;
    if (c == null || !available) return;
    _openPanel();
    final r = c.addResult(
      l10n.aiResultOutline,
      actions: _insertActions(outline: true),
    );
    await c.streamInline(
      InlineAiRequest(
        itemUuid: session.itemUuid,
        action: 'generateOutline',
        instruction: prompt,
      ),
      r,
    );
  }

  /// "# A\n## B" → "- A\n  - B".
  static String outlineAsList(String md) {
    final out = <String>[];
    for (final line in md.split('\n')) {
      final m = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line.trim());
      if (m == null) {
        if (line.trim().isNotEmpty) out.add(line);
        continue;
      }
      out.add('${'  ' * (m.group(1)!.length - 1)}- ${m.group(2)}');
    }
    return out.join('\n');
  }

  ProofreadResults? _proofread;

  /// The latest proofreading results.
  ProofreadResults? get proofreadResults => _proofread;

  /// Tools › Proofread document (issues in the panel, Accept per issue).
  Future<void> proofread() async {
    final c = chat;
    final a = api;
    if (c == null || a == null || !available) return;
    _openPanel();
    final results = ProofreadResults(this);
    _proofread = results;
    final entry = c.addResult(
      l10n.aiResultProofreading,
      builder: (context) => ProofreadIssueList(results: results),
    );
    results.addListener(c.refresh);
    try {
      await for (final e in a.proofread(session.itemUuid)) {
        results.onEvent(e);
      }
    } on Object catch (e) {
      results.fail(errorMessage(e));
    }
    results.finish();
    entry.status = results.error == null
        ? AssistantReplyStatus.done
        : AssistantReplyStatus.failed;
    entry.error = results.error;
    c.refresh();
    unawaited(assistant?.refreshStatus());
  }

  /// The preview title (and undo label) of rewrite [action]; [tone] is a
  /// tone id and [language] an English language name.
  static String rewriteTitle(
    WriteLocalizations l,
    String action, {
    String? tone,
    String? language,
  }) => switch (action) {
    'improve' => l.aiImproveWriting,
    'fixGrammar' => l.aiFixGrammar,
    'shorter' => l.aiMakeShorter,
    'longer' => l.aiMakeLonger,
    'tone' => l.aiTitleChangeTone(aiToneLabel(l, tone ?? 'professional')),
    'translate' => l.aiTitleTranslate(
      aiLanguageLabel(l, language ?? 'English'),
    ),
    _ => l.aiTitleEditWithAi,
  };

  @override
  void dispose() {
    _disposed = true;
    unawaited(_stream?.cancel());
    session.contentVersion.removeListener(_onContent);
    _proofread?.dispose();
    final a = assistant;
    if (a != null) a.release(adapter);
    adapter.dispose();
    if (_byItem[session.itemUuid.uuid] == this) {
      _byItem.remove(session.itemUuid.uuid);
    }
    super.dispose();
  }
}
