import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../data/api.dart' show errorMessage;
import '../mcp_bridge/ui_tool.dart';
import 'assistant_adapter.dart';
import 'assistant_api.dart';
import 'assistant_models.dart';

/// State of the assistant panel for one open file: the thread list, the
/// open thread's messages, the streaming run, apply mode and context chips.
class AssistantController extends ChangeNotifier {
  AssistantController({
    required this.api,
    required this.adapter,
    required this.status,
    AiApplyMode initialApplyMode = AiApplyMode.edit,
    this.onApplyModeChanged,
    this.onStatusStale,
  }) : _applyMode = initialApplyMode {
    adapter.addListener(_onAdapter);
    status.addListener(notifyListeners);
  }

  final AssistantApi api;
  final AssistantDocumentAdapter adapter;

  /// Shared availability / quality status.
  final ValueListenable<AssistantStatus?> status;

  /// Persists the apply mode choice.
  final void Function(AiApplyMode mode)? onApplyModeChanged;

  /// Asks the shell to refresh [status] (usage changed, errors).
  final VoidCallback? onStatusStale;

  static const refusalText = "The assistant can't help with that request.";

  bool _disposed = false;
  bool _loaded = false;
  bool loading = false;
  String? loadError;

  List<AssistantThreadView> threads = const [];
  int? threadId;
  final List<AssistantEntry> entries = [];

  StreamSubscription<AssistantEvent>? _run;
  AssistantReplyEntry? _reply;
  int _keys = 0;

  /// Whether a run streams.
  bool get busy => _run != null;

  /// The streaming reply, if any.
  AssistantReplyEntry? get currentReply => _reply;

  AiApplyMode _applyMode;

  /// Commenters can only suggest.
  AiApplyMode get applyMode =>
      adapter.role < Role.editor ? AiApplyMode.suggest : _applyMode;

  bool get canEditDirectly => adapter.role >= Role.editor;

  final Set<String> _removedChips = {};
  List<AssistantContextChip>? _lastChips;

  /// Chips the user did not remove.
  List<AssistantContextChip> get chips => [
    for (final c in adapter.chips)
      if (!_removedChips.contains(c.id)) c,
  ];

  String _key(String p) => '$p-${_keys++}';

  void _onAdapter() {
    final now = adapter.chips;
    final before = _lastChips;
    _lastChips = now;
    // A new selection brings removed chips back.
    if (before != null &&
        (before.length != now.length ||
            [
              for (var i = 0; i < now.length; i++)
                now[i].label != before[i].label,
            ].any((x) => x))) {
      _removedChips.clear();
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void removeChip(String id) {
    _removedChips.add(id);
    _notify();
  }

  void setApplyMode(AiApplyMode mode) {
    if (_applyMode == mode) return;
    _applyMode = mode;
    onApplyModeChanged?.call(mode);
    _notify();
  }

  /// Loads the threads and opens the most recent one (once).
  Future<void> ensureLoaded() async {
    if (_loaded || loading) return;
    await reload();
  }

  Future<void> reload() async {
    loading = true;
    loadError = null;
    _notify();
    try {
      threads = await api.listThreads(adapter.itemUuid);
      _loaded = true;
      if (threadId == null && threads.isNotEmpty && entries.isEmpty) {
        await _openThread(threads.first.id);
      }
    } on Object catch (e) {
      loadError = errorMessage(e);
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> _openThread(int id) async {
    final detail = await api.getThread(id);
    threadId = id;
    entries
      ..clear()
      ..addAll(entriesOf(detail.messages));
  }

  /// Converts stored messages into entries (assistant rounds of one run
  /// join into one reply).
  List<AssistantEntry> entriesOf(List<AssistantMessageView> messages) {
    final out = <AssistantEntry>[];
    AssistantReplyEntry? reply;
    for (final m in messages) {
      if (m.role == 'user') {
        reply = null;
        out.add(AssistantUserEntry(_key('u${m.id}'), m.displayText));
        continue;
      }
      if (reply == null || reply.runId != m.runId) {
        reply = AssistantReplyEntry(
          _key('a${m.id}'),
          runId: m.runId,
          status: AssistantReplyStatus.done,
        );
        out.add(reply);
      }
      if (m.stopReason == 'refusal') {
        reply.status = AssistantReplyStatus.refused;
        reply.error = refusalText;
        continue;
      }
      if (m.displayText.trim().isNotEmpty) {
        reply
          ..paragraphBreak()
          ..append(m.displayText);
      }
      reply.activities.addAll(decodeActivities(m.toolCallsJson));
      if (m.stopReason == 'max_tokens') {
        reply.status = AssistantReplyStatus.cutOff;
      }
    }
    return out;
  }

  /// Opens thread [id] (null = a new, empty chat).
  Future<void> selectThread(int? id) async {
    if (busy) await stop();
    if (id == null) {
      threadId = null;
      entries.clear();
      _notify();
      return;
    }
    try {
      await _openThread(id);
    } on Object catch (e) {
      loadError = errorMessage(e);
    }
    _notify();
  }

  Future<void> newThread() => selectThread(null);

  /// Deletes the open thread.
  Future<void> deleteThread() async {
    final id = threadId;
    if (id == null) {
      entries.clear();
      _notify();
      return;
    }
    if (busy) await stop();
    await api.deleteThread(id);
    threads = [
      for (final t in threads)
        if (t.id != id) t,
    ];
    threadId = null;
    entries.clear();
    _notify();
  }

  /// Sends [text] to the assistant.
  Future<void> send(String text, {bool includeComments = false}) async {
    final message = text.trim();
    if (message.isEmpty || busy) return;
    final s = status.value;
    if (s != null && !s.available) return;
    final hints = adapter.hints(
      applyMode: applyMode,
      chips: {for (final c in chips) c.id},
      includeComments: includeComments,
    );
    entries.add(AssistantUserEntry(_key('u'), message));
    final reply = AssistantReplyEntry(_key('a'));
    entries.add(reply);
    _reply = reply;
    _removedChips.clear();
    _notify();
    await _stream(
      reply,
      api.chat(
        threadId: threadId,
        itemUuid: adapter.itemUuid,
        message: message,
        hints: hints,
      ),
    );
  }

  /// Runs a quick action (Write 09 §5.5): no user bubble, a working
  /// indicator ([workingLabel]) until the result streams in.
  Future<void> runQuickAction(
    AssistantQuickAction action, {
    required String workingLabel,
  }) async {
    if (busy) return;
    final s = status.value;
    if (s != null && !s.available) return;
    final hints = adapter.hints(
      applyMode: applyMode,
      chips: {for (final c in chips) c.id},
    );
    final reply = AssistantReplyEntry(_key('a'))
      ..workingLabel = workingLabel
      ..quickAction = action;
    entries.add(reply);
    _reply = reply;
    _notify();
    await _stream(
      reply,
      api.quickAction(
        threadId: threadId,
        itemUuid: adapter.itemUuid,
        action: action,
        hints: hints,
      ),
    );
  }

  Future<void> _stream(
    AssistantReplyEntry reply,
    Stream<AssistantEvent> events,
  ) async {
    final done = Completer<void>();
    _run = events.listen(
      (e) => _onEvent(reply, e),
      onError: (Object e) {
        reply
          ..status = AssistantReplyStatus.failed
          ..error = errorMessage(e);
        _finishRun(reply);
        if (!done.isCompleted) done.complete();
      },
      onDone: () {
        if (reply.streaming) reply.status = AssistantReplyStatus.done;
        _finishRun(reply);
        if (!done.isCompleted) done.complete();
      },
      cancelOnError: true,
    );
    await done.future;
  }

  void _finishRun(AssistantReplyEntry reply) {
    _run = null;
    if (_reply == reply) _reply = null;
    reply
      ..progress = null
      ..confirmation = null;
    for (final a in reply.activities) {
      a.running = false;
    }
    final runId = reply.runId;
    final hooks = _hooks;
    final changeId = reply.changeId;
    if (hooks != null && changeId != null) {
      hooks.runCommitted(reply, changeId, _summary(reply));
    }
    if (runId != null && reply.hasChanges) {
      adapter.runFinished(runId, _summary(reply));
    }
    onStatusStale?.call();
    _notify();
  }

  /// A short label for the undo step.
  static String _summary(AssistantReplyEntry r) {
    final changed = r.activities.where((a) => a.changed).toList();
    if (changed.length == 1) return changed.single.summary;
    final text = r.markdown.trim().split('\n').first;
    if (text.isNotEmpty && text.length <= 60) return text;
    return '${changed.length} edits';
  }

  void _onEvent(AssistantReplyEntry reply, AssistantEvent e) {
    switch (e.type) {
      case AssistantEventType.started:
        reply.runId = e.runId;
        if (threadId != e.threadId) {
          threadId = e.threadId;
          unawaited(_refreshThreads());
        }
      case AssistantEventType.textDelta:
        reply.progress = null;
        if (_lastWasTool) reply.paragraphBreak();
        _lastWasTool = false;
        reply.append(e.text ?? '');
      case AssistantEventType.progress:
        reply.progress = e.text;
      case AssistantEventType.toolStarted:
        _lastWasTool = true;
        reply.activities.add(
          AssistantActivity(
            toolUseId: e.toolUseId ?? '',
            toolName: e.toolName ?? '',
            summary: e.toolSummary ?? '',
            running: true,
          ),
        );
      case AssistantEventType.toolFinished:
        final a = reply.activities.lastWhere(
          (x) => x.toolUseId == e.toolUseId,
          orElse: () {
            final n = AssistantActivity(
              toolUseId: e.toolUseId ?? '',
              toolName: e.toolName ?? '',
              summary: '',
            );
            reply.activities.add(n);
            return n;
          },
        );
        a
          ..running = false
          ..summary = e.toolSummary ?? a.summary
          ..error = e.toolError ?? false
          ..changeId = e.changeId
          ..rangeStart = e.rangeStart
          ..rangeLength = e.rangeLength
          ..revision = e.revision
          ..range = e.range
          ..objectId = e.objectId;
        _hooks?.toolFinished(a);
      case AssistantEventType.confirmationRequired:
        reply.confirmation = AssistantConfirmation(
          runId: e.runId ?? reply.runId ?? '',
          confirmationId: e.confirmationId ?? '',
          summary: e.toolSummary ?? 'The assistant wants to delete content.',
        );
      case AssistantEventType.usage:
        break;
      // Sheets 12 §6.2: a `ui.*` tool runs in this (the requesting) window.
      case AssistantEventType.uiToolCall:
        unawaited(_runWindowTool(e.runId ?? reply.runId, e));
      // Sheets Suggest-mode previews (Sheets 12 §6.3): the app's
      // [AssistantRunHooks] show the AI changes preview.
      case AssistantEventType.previewReady:
        final id = e.previewId;
        if (id != null && reply.previewId != id) {
          reply.previewId = id;
          _hooks?.previewReady(reply, id);
        }
      case AssistantEventType.maxTokens:
        reply.status = AssistantReplyStatus.cutOff;
      case AssistantEventType.refusal:
        reply
          ..status = AssistantReplyStatus.refused
          ..error = e.text ?? refusalText;
      case AssistantEventType.error:
        reply
          ..status = AssistantReplyStatus.failed
          ..error = e.error
          ..errorCode = e.errorCode;
      case AssistantEventType.done:
        if (e.changeId != null) reply.changeId = e.changeId;
        final preview = e.previewId;
        if (preview != null && reply.previewId == null) {
          reply.previewId = preview;
          _hooks?.previewReady(reply, preview);
        }
        if (e.errorCode == 'stopped') {
          reply.status = AssistantReplyStatus.stopped;
        } else if (reply.streaming) {
          reply.status = AssistantReplyStatus.done;
        }
    }
    _notify();
  }

  bool _lastWasTool = false;

  /// Runs a relayed `ui.*` tool through the adapter's
  /// [AssistantWindowTools] and answers the server.
  Future<void> _runWindowTool(String? runId, AssistantEvent e) async {
    final id = e.toolUseId;
    final tool = e.toolName;
    if (runId == null || id == null || tool == null) return;
    UiBridgeResponse response;
    final a = adapter;
    try {
      if (a is! AssistantWindowTools) {
        throw UiToolException(
          'unsupported',
          'This window does not support $tool.',
        );
      }
      final raw = e.argsJson;
      final args = raw == null
          ? const <String, Object?>{}
          : (jsonDecode(raw) as Map).cast<String, Object?>();
      final r = await (a as AssistantWindowTools).runWindowTool(tool, args);
      response = UiBridgeResponse(
        requestId: id,
        ok: true,
        resultJson: jsonEncode(r.result, toEncodable: (o) => '$o'),
        text: r.text,
      );
    } on UiToolException catch (x) {
      response = UiBridgeResponse(
        requestId: id,
        ok: false,
        errorCode: x.code,
        errorMessage: x.message,
      );
    } catch (x) {
      debugPrint('Assistant window tool $tool failed: $x');
      response = UiBridgeResponse(
        requestId: id,
        ok: false,
        errorCode: 'internal_error',
        errorMessage: '$x',
      );
    }
    try {
      await api.uiToolResult(runId, response);
    } catch (x) {
      debugPrint('Answering the assistant window tool $tool failed: $x');
    }
  }

  /// The adapter's optional server-run hooks (Sheets).
  AssistantRunHooks? get _hooks {
    final a = adapter;
    return a is AssistantRunHooks ? a as AssistantRunHooks : null;
  }

  Future<void> _refreshThreads() async {
    try {
      threads = await api.listThreads(adapter.itemUuid);
      _notify();
    } on Object {
      // The list refreshes on the next load.
    }
  }

  /// Stops the running answer.
  Future<void> stop() async {
    final reply = _reply;
    if (reply == null) return;
    try {
      await api.stop(threadId: threadId, runId: reply.runId);
    } on Object {
      await _run?.cancel();
      reply.status = AssistantReplyStatus.stopped;
      _finishRun(reply);
    }
  }

  /// Answers the pending destructive-change confirmation.
  Future<void> confirm(bool allow) async {
    final reply = _reply;
    final c = reply?.confirmation;
    if (reply == null || c == null) return;
    reply.confirmation = null;
    _notify();
    await api.confirm(c.runId, c.confirmationId, allow);
  }

  /// "Continue" after a cut-off answer.
  Future<void> continueAnswer() => send('Continue');

  /// Undoes the changes of [reply]: the client's undo step when possible,
  /// else `changes.revert` per change (newest first).
  Future<void> undoReply(AssistantReplyEntry reply) async {
    final runId = reply.runId;
    if (runId == null || reply.undone) return;
    var ok = await adapter.undoRun(runId);
    if (!ok) {
      final ids = [
        for (final a in reply.activities.reversed)
          if (a.changeId != null) a.changeId!,
      ];
      for (final id in ids) {
        await api.revertChange(id);
      }
      ok = ids.isNotEmpty;
    }
    if (ok) {
      reply.undone = true;
      _notify();
    }
  }

  /// Reveals a tool change.
  void show(AssistantActivity a) => adapter.show(a);

  // --------------------------------------------------------------- results

  /// Adds a result card and returns it (filled by [streamInline] or the
  /// app).
  AssistantResultEntry addResult(
    String title, {
    List<AssistantResultAction> actions = const [],
    WidgetBuilder? builder,
  }) {
    final r = AssistantResultEntry(
      _key('r'),
      title: title,
      actions: actions,
      builder: builder,
    );
    entries.add(r);
    _notify();
    return r;
  }

  /// Streams an inline AI request into a result card.
  Future<void> streamInline(
    InlineAiRequest request,
    AssistantResultEntry result,
  ) async {
    try {
      await for (final e in api.inline(request)) {
        switch (e.type) {
          case InlineAiEventType.textDelta:
            result.append(e.text ?? '');
          case InlineAiEventType.done:
            result
              ..markdown = e.markdown ?? result.markdown
              ..status = AssistantReplyStatus.done;
          case InlineAiEventType.refusal:
            result
              ..status = AssistantReplyStatus.refused
              ..error = e.error ?? refusalText;
          case InlineAiEventType.error:
            result
              ..status = AssistantReplyStatus.failed
              ..error = e.error;
        }
        _notify();
      }
    } on Object catch (e) {
      result
        ..status = AssistantReplyStatus.failed
        ..error = errorMessage(e);
    }
    if (result.status == AssistantReplyStatus.streaming) {
      result.status = AssistantReplyStatus.done;
    }
    onStatusStale?.call();
    _notify();
  }

  /// Re-renders after an app changed a result (proofreading updates).
  void refresh() => _notify();

  void removeEntry(AssistantEntry e) {
    entries.remove(e);
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    adapter.removeListener(_onAdapter);
    status.removeListener(notifyListeners);
    unawaited(_run?.cancel());
    super.dispose();
  }
}
