import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope;
import 'package:wonky_write_core/wonky_write_core.dart'
    show BlockType, Delta, DeltaUtils, WonkyDocument;

import '../../sheets/mcp/sheets_changes.dart';
import '../../slides/mcp/slides_changes.dart';
import '../../write/mcp/headless_editor.dart';
import '../cluster/cluster.dart';
import '../cluster/cluster_bus.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../mcp/tool_executor.dart';
import '../mcp/tool_support.dart';
import '../mcp/wonky_mcp_server.dart';
import 'ai_call.dart';
import 'ai_config.dart';
import 'ai_keys.dart';
import 'ai_models.dart';
import 'ai_usage_service.dart';
import 'assistant_history.dart';

export 'assistant_target.dart' show AssistantToolActivity;
import 'assistant_target.dart';
import 'assistant_tools.dart';
import 'llm/ai_client.dart';

/// A running assistant loop (for `stop` and destructive confirmations).
class AssistantRun {
  AssistantRun(this.runId, this.userId, this.threadId);

  final String runId;
  final int userId;
  final int threadId;
  final AiCancelToken cancel = AiCancelToken();
  final Map<String, Completer<bool>> confirmations = {};

  /// `ui.*` calls waiting for the requesting window (by tool use id).
  final Map<String, Completer<UiBridgeResponse>> uiCalls = {};

  void failPending() {
    for (final c in confirmations.values) {
      if (!c.isCompleted) c.complete(false);
    }
    for (final e in uiCalls.entries) {
      if (!e.value.isCompleted) {
        e.value.complete(
          UiBridgeResponse(
            requestId: e.key,
            ok: false,
            errorCode: 'stopped',
            errorMessage: 'The run stopped.',
          ),
        );
      }
    }
  }
}

/// The assistant agent loop (suite 10 §2): builds the request (tools →
/// frozen system prompt → document snapshot → conversation, a stable
/// prefix for provider-side prompt caches), streams the answer from the
/// user's provider ([AiCall.open]), executes tool calls through the MCP
/// [ToolExecutor] (in parallel, results in one user message), and loops
/// until the model ends its turn. Every op of a run carries the run id as
/// `groupId` and the requesting app session as `onBehalfOfSessionId`, so
/// the run is one undo step "AI: …" on that client (Write 09 §5.2).
abstract final class AssistantService {
  static final Map<String, AssistantRun> _runs = {};

  /// Runs of [userId] (tests).
  static Iterable<AssistantRun> runsOf(int userId) =>
      _runs.values.where((r) => r.userId == userId);

  /// Destructive guard (Write 09 §5.8).
  static const guardChars = 2000;
  static const guardFraction = 0.3;

  /// How long a confirmation waits for the user.
  static Duration confirmationTimeout = const Duration(minutes: 10);

  /// How long a `ui.*` call waits for the requesting window.
  static Duration uiToolTimeout = const Duration(seconds: 30);

  /// The bus channel of a run's `ui.*` results answered on another
  /// instance (specs/13 §4).
  static String uiChannel(String runId) => 'assistant:ui:$runId';

  /// Tool results are capped at this many characters.
  static const maxToolResultChars = 50000;

  static const refusalText = AiFailure.refusalText;

  // ------------------------------------------------------------------ chat

  /// Sends [message] in [threadId] (null = a new thread on [itemUuid]) and
  /// streams the run. Checks run before the stream starts (availability,
  /// budget, concurrency, access).
  static Future<Stream<AssistantEvent>> chat(
    Session session,
    Actor actor, {
    required int? threadId,
    required UuidValue itemUuid,
    required String message,
    required AssistantContextHints hints,
    ToolExecutor? executor,
    Future<Session> Function()? runSession,
  }) async {
    final text = message.trim();
    if (text.isEmpty) throw Errors.invalid('The message is empty.');
    if (text.length > 20000) throw Errors.tooLarge('The message is too long.');
    final ai = await AiCall.open(session, actor);
    final target = await AssistantTarget.resolve(session, actor, itemUuid);
    AssistantThread? existing;
    if (threadId != null) {
      final t = await AssistantThread.db.findById(session, threadId);
      if (t == null || t.userId != actor.userId) {
        throw Errors.notFound('Conversation');
      }
      if (t.itemId != target.item.id) {
        throw Errors.invalid('The conversation belongs to another file.');
      }
      existing = t;
    }
    final quality = await ai.quality(session);
    if (Cluster.distributed) await _listenForRelays(session);
    // Checked after the last await before the run is registered, so two
    // concurrent sends to one chat cannot both start.
    final existingId = existing?.id;
    if (existingId != null &&
        _runs.values.any((r) => r.threadId == existingId)) {
      throw Errors.busy('The assistant is still answering in this chat.');
    }
    // The slot is taken last, and released when anything before the run
    // starts throws (a leaked slot blocks the user until a restart). A new
    // thread is created only once the slot is taken (no empty thread is
    // left behind by a busy error).
    final release = AiUsageService.acquire(actor.userId);
    final AssistantThread thread;
    try {
      thread =
          existing ??
          await AssistantThread.db.insertRow(
            session,
            AssistantThread(
              userId: actor.userId,
              itemId: target.item.id,
              title: _title(text),
              createdAt: nowUtc(),
              updatedAt: nowUtc(),
            ),
          );
    } on Object {
      release();
      rethrow;
    }
    final run = AssistantRun(
      const Uuid().v7(),
      actor.userId,
      thread.id!,
    );
    _runs[run.runId] = run;
    final out = StreamController<AssistantEvent>();
    out.onCancel = run.cancel.cancel;
    Future<void> body() async {
      final s = runSession == null
          ? await session.serverpod.createSession(enableLogging: false)
          : await runSession();
      try {
        await _Loop(
          session: s,
          actor: actor,
          backend: ai.backend,
          ar: run,
          thread: thread,
          target: target,
          message: text,
          hints: hints,
          quality: quality,
          executor: executor ?? WonkyMcpServer.executor,
          emit: (e) {
            if (!out.isClosed) out.add(e);
          },
        ).execute();
      } finally {
        if (runSession == null) await s.close();
      }
    }

    unawaited(
      body()
          .catchError((Object e, StackTrace st) {
            session.serverpod.logVerbose('Assistant run failed: $e\n$st');
            if (!out.isClosed) {
              out.add(
                AssistantEvent(
                  type: AssistantEventType.error,
                  threadId: run.threadId,
                  runId: run.runId,
                  error: 'Something went wrong. Please try again.',
                  errorCode: 'internal',
                ),
              );
            }
          })
          .whenComplete(() {
            release();
            _runs.remove(run.runId);
            run.failPending();
            if (!out.isClosed) unawaited(out.close());
          }),
    );
    return out.stream;
  }

  /// Stops and confirmations arrive as unary calls, which the load
  /// balancer may route to another instance than the one running the chat
  /// stream: those instances relay them as [ClusterSignal]s (specs/13 §4).
  static Future<void> _listenForRelays(Session session) => Future.wait([
    Cluster.on(session, 'assistant.stop', (s) {
      if (s.userId == null) return;
      _stopLocal(s.userId!, runId: s.runId, threadId: s.threadId);
    }),
    Cluster.on(session, 'assistant.confirm', (s) {
      if (s.userId == null || s.runId == null || s.confirmationId == null) {
        return;
      }
      _confirmLocal(
        s.userId!,
        s.runId!,
        s.confirmationId!,
        allow: s.allow ?? false,
      );
    }),
  ]);

  static String _title(String message) {
    final line = message.split('\n').first.trim();
    return line.length <= 60 ? line : '${line.substring(0, 57)}…';
  }

  /// Stops the user's run [runId], or every run in [threadId]. With several
  /// instances the stop is also relayed to the others (best effort; then
  /// true means "requested").
  static Future<bool> stop(
    Session session,
    int userId, {
    String? runId,
    int? threadId,
  }) async {
    final stopped = _stopLocal(userId, runId: runId, threadId: threadId);
    if (stopped && runId != null || !Cluster.distributed) return stopped;
    await Cluster.signal(
      session,
      Cluster.build(
        'assistant.stop',
        userId: userId,
        runId: runId,
        threadId: threadId,
      ),
    );
    return true;
  }

  static bool _stopLocal(int userId, {String? runId, int? threadId}) {
    var stopped = false;
    for (final r in _runs.values.toList()) {
      if (r.userId != userId) continue;
      if (runId != null && r.runId != runId) continue;
      if (threadId != null && r.threadId != threadId) continue;
      r.cancel.cancel();
      r.failPending();
      stopped = true;
    }
    return stopped;
  }

  /// Answers a destructive-change confirmation (relayed to the instance
  /// running [runId] when it is not this one).
  static Future<bool> confirm(
    Session session,
    int userId,
    String runId,
    String confirmationId, {
    required bool allow,
  }) async {
    if (_runs.containsKey(runId) || !Cluster.distributed) {
      return _confirmLocal(userId, runId, confirmationId, allow: allow);
    }
    await Cluster.signal(
      session,
      Cluster.build(
        'assistant.confirm',
        userId: userId,
        runId: runId,
        confirmationId: confirmationId,
        allow: allow,
      ),
    );
    return true;
  }

  /// The requesting window answers a `uiToolCall` (Sheets 12 §6.2). When
  /// the run lives on another instance, the answer is relayed on the bus.
  static Future<bool> uiToolResult(
    Session session,
    int userId,
    String runId,
    UiBridgeResponse response,
  ) async {
    final r = _runs[runId];
    if (r != null) {
      if (r.userId != userId) return false;
      final c = r.uiCalls[response.requestId];
      if (c == null || c.isCompleted) return false;
      c.complete(response);
      return true;
    }
    if (!Cluster.distributed) return false;
    await ClusterBus.post(session, uiChannel(runId), response);
    return true;
  }

  static bool _confirmLocal(
    int userId,
    String runId,
    String confirmationId, {
    required bool allow,
  }) {
    final r = _runs[runId];
    if (r == null || r.userId != userId) return false;
    final c = r.confirmations[confirmationId];
    if (c == null || c.isCompleted) return false;
    c.complete(allow);
    return true;
  }

  // --------------------------------------------------------------- threads

  static AssistantThreadView _view(AssistantThread t, UuidValue? itemUuid) =>
      AssistantThreadView(
        id: t.id!,
        itemUuid: itemUuid,
        title: t.title,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );

  /// Threads of the user on [itemUuid], newest first.
  static Future<List<AssistantThreadView>> listThreads(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final target = await AssistantTarget.resolve(session, actor, itemUuid);
    final rows = await AssistantThread.db.find(
      session,
      where: (t) =>
          t.userId.equals(actor.userId) & t.itemId.equals(target.item.id),
      orderBy: (t) => t.updatedAt.desc(),
      limit: 100,
    );
    return [for (final r in rows) _view(r, target.item.uuid)];
  }

  static Future<AssistantThread> _own(
    Session session,
    Actor actor,
    int threadId,
  ) async {
    final t = await AssistantThread.db.findById(session, threadId);
    if (t == null || t.userId != actor.userId) {
      throw Errors.notFound('Conversation');
    }
    return t;
  }

  /// A thread with its visible messages.
  static Future<AssistantThreadDetail> getThread(
    Session session,
    Actor actor,
    int threadId,
  ) async {
    final t = await _own(session, actor, threadId);
    final item = t.itemId == null
        ? null
        : await DriveItem.db.findById(session, t.itemId!);
    final rows = await AssistantMessage.db.find(
      session,
      where: (m) => m.threadId.equals(threadId) & m.visible.equals(true),
      orderBy: (m) => m.id,
    );
    return AssistantThreadDetail(
      thread: _view(t, item?.uuid),
      messages: [
        for (final m in rows)
          AssistantMessageView(
            id: m.id!,
            role: m.role,
            displayText: m.displayText,
            toolCallsJson: m.toolCallsJson,
            runId: m.runId,
            stopReason: m.stopReason,
            createdAt: m.createdAt,
          ),
      ],
    );
  }

  static Future<void> deleteThread(
    Session session,
    Actor actor,
    int threadId,
  ) async {
    final t = await _own(session, actor, threadId);
    await stop(session, actor.userId, threadId: threadId);
    await AssistantThread.db.deleteRow(session, t);
  }

  /// Settings › AI › Clear history: deletes every thread of the user.
  static Future<int> clearHistory(Session session, Actor actor) async {
    await stop(session, actor.userId);
    final rows = await AssistantThread.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(actor.userId),
    );
    return rows.length;
  }

  /// Reverts an assistant change (panel Undo when the client's undo step
  /// is gone): `changes.revert` as the assistant.
  static Future<Map<String, Object?>> revertChange(
    Session session,
    Actor actor,
    String changeId,
  ) async {
    final ctx = ToolContext(
      session: session,
      actor: actor.copyWith(kind: ActorKind.ai),
      scopes: {
        McpScope.writeRead,
        McpScope.writeEdit,
        McpScope.sheetsEdit,
        McpScope.slidesEdit,
      },
    );
    // Deck records share the change table: Slides first (11 §1.4).
    return await SlidesChanges.tryRevert(ctx, changeId) ??
        await SheetsChanges.tryRevert(ctx, changeId) ??
        await HeadlessDocumentEditor.revert(ctx, changeId);
  }

  /// The destructive guard of [doc]: refuses a change that deletes more
  /// than [guardChars] characters or [guardFraction] of the document.
  static McpToolException? guardViolation(Delta head, Delta change) {
    var deleted = 0;
    var pos = 0;
    final ranges = <(int, int)>[];
    for (final op in change.toList()) {
      final len = op.length ?? 0;
      if (op.isDelete) {
        deleted += len;
        ranges.add((pos, len));
        pos += len;
      } else if (op.isRetain) {
        pos += len;
      }
    }
    final docLen = DeltaUtils.documentLength(head);
    if (deleted == 0) return null;
    if (deleted <= guardChars &&
        (docLen < 400 || deleted <= docLen * guardFraction)) {
      return null;
    }
    final doc = WonkyDocument(head);
    final headings = <String>{};
    for (final r in ranges) {
      for (final line in doc.linesInRange(r.$1, r.$2)) {
        if (line.format.type == BlockType.heading) {
          headings.add(line.text.trim());
        }
      }
    }
    final paragraphs = ranges.fold<int>(
      0,
      (n, r) => n + doc.linesInRange(r.$1, r.$2).length,
    );
    final pct = (deleted * 100 / (docLen == 0 ? 1 : docLen)).round();
    final what = headings.isEmpty
        ? '$paragraphs paragraph${paragraphs == 1 ? '' : 's'}'
        : '$paragraphs paragraph${paragraphs == 1 ? '' : 's'} '
              '(${headings.take(3).join(', ')}${headings.length > 3 ? '…' : ''})';
    return McpToolException(
      'needs_confirmation',
      'This change deletes $deleted characters ($pct% of the document). '
          'The user must confirm it.',
      details: {
        'deleted_chars': deleted,
        'percent': pct,
        'summary': 'The assistant wants to delete $what',
        'headings': headings.toList(),
      },
    );
  }
}

/// One run of the loop.
class _Loop {
  _Loop({
    required this.session,
    required this.actor,
    required this.backend,
    required this.ar,
    required this.thread,
    required this.target,
    required this.message,
    required this.hints,
    required this.quality,
    required this.executor,
    required this.emit,
  });

  final Session session;
  final Actor actor;
  final AssistantRun ar;
  AssistantThread thread;
  final AssistantTarget target;
  final String message;
  final AssistantContextHints hints;
  final AiQuality quality;
  final AiBackend backend;
  final ToolExecutor executor;
  final void Function(AssistantEvent) emit;

  final List<ChatMessage> _messages = [];
  final StringBuffer _answer = StringBuffer();
  int? _lastAssistantId;

  AssistantEvent _ev(AssistantEventType type, {String? text}) => AssistantEvent(
    type: type,
    threadId: ar.threadId,
    runId: ar.runId,
    text: text,
  );

  Future<void> execute() async {
    final applyMode = target.applyMode(hints.applyMode);
    final ui = target.uiTools(hints);
    _uiTools = {for (final d in ui) d.name};
    final toolset = target.toolset(executor).plus(ui);
    final runner = AssistantToolRunner(
      executor: executor,
      toolset: toolset,
      itemUuid: target.item.uuid,
      itemId: target.item.id!,
    );

    await _loadHistory();
    final userMessageId = await _appendUserTurn(applyMode);
    emit(_ev(AssistantEventType.started)..messageId = userMessageId);
    // From beginRun on, endRun always runs (suggest-mode shadows and
    // previews are per run and kept until then) and the `ui.*` listener is
    // always removed, also when the run throws.
    var ended = false;
    try {
      await target.beginRun(
        session,
        actor,
        runId: ar.runId,
        applyMode: applyMode,
      );
      final done = await _rounds(applyMode, runner, toolset, backend);
      ended = true;
      await target.endRun(
        session,
        actor,
        runId: ar.runId,
        changeIds: _changeIds,
        title: thread.title,
        done: done,
        emit: emit,
      );
      emit(done);
    } finally {
      if (!ended) {
        try {
          await target.endRun(
            session,
            actor,
            runId: ar.runId,
            changeIds: _changeIds,
            title: thread.title,
            done: _ev(AssistantEventType.done, text: _answer.toString())
              ..messageId = _lastAssistantId
              ..errorCode = 'internal',
            emit: emit,
          );
        } on Object catch (e, st) {
          session.log(
            'Assistant run ${ar.runId}: cleanup after a failure failed: $e',
            level: LogLevel.warning,
            stackTrace: st,
          );
        }
      }
      if (_uiListening) {
        _uiListening = false;
        session.messages.removeListener(
          AssistantService.uiChannel(ar.runId),
          _onUiReply,
        );
      }
    }
  }

  /// The model rounds of the run; returns its `done` event.
  Future<AssistantEvent> _rounds(
    AiApplyMode applyMode,
    AssistantToolRunner runner,
    AssistantToolset toolset,
    AiBackend backend,
  ) async {
    final tier = AiTier.chat(quality);
    final client = backend.client;
    final config = AiConfig.current;
    var stoppedEarly = true;
    // Budget tokens of this run (CQ-31: one run can't spend the day).
    var runTokens = 0;
    for (var round = 0; round < config.maxToolRounds; round++) {
      if (ar.cancel.isCancelled) break;
      if (runTokens >= config.maxRunTokens) {
        emit(
          _ev(AssistantEventType.error)
            ..error =
                'The assistant stopped: this request used its token limit. '
                'Send a message to let it continue.'
            ..errorCode = 'run_budget',
        );
        stoppedEarly = false;
        break;
      }
      try {
        await AiUsageService.requireBudget(session, actor.userId);
      } on WonkyException catch (e) {
        emit(
          _ev(AssistantEventType.error)
            ..error = e.message
            ..errorCode = 'budget',
        );
        stoppedEarly = false;
        break;
      }
      final request = AiRequest(
        model: backend.model(tier),
        effort: tier.effort,
        system: target.system,
        tools: toolset.apiTools,
        // Older tool results elided, oldest exchanges left out past the
        // history budget (CQ-31).
        messages: AssistantHistory.fit(
          _messages,
          budgetTokens: config.historyTokenBudget,
        ),
        userId: 'u${actor.userId}',
        feature: 'chat',
        cacheKey: 'wonky-thread-${ar.threadId}',
      );
      AiResponse msg;
      final progress = StringBuffer();
      try {
        msg = await client.send(
          request,
          cancel: ar.cancel,
          onText: (t) {
            _answer.write(t);
            emit(_ev(AssistantEventType.textDelta, text: t));
          },
          onThinking: (t) {
            // Reasoning the provider streams (progress notes): the whole
            // note so far.
            progress.write(t);
            final text = progress.toString().trim();
            if (text.isNotEmpty) {
              emit(_ev(AssistantEventType.progress, text: text));
            }
          },
        );
      } on AiCancelledException {
        break;
      } on AiApiException catch (e) {
        if (e.type == 'refusal') {
          await _persistAssistant(
            null,
            AssistantService.refusalText,
            stop: AiStopReason.refusal,
            replay: false,
          );
          emit(
            _ev(
              AssistantEventType.refusal,
              text: AssistantService.refusalText,
            ),
          );
          stoppedEarly = false;
          break;
        }
        emit(
          _ev(AssistantEventType.error)
            ..error = AiFailure.fromApi(e).message
            ..errorCode = AiFailure.fromApi(e).code,
        );
        stoppedEarly = false;
        break;
      }
      await AiUsageService.record(
        session,
        userId: actor.userId,
        model: msg.model ?? request.model,
        feature: 'chat',
        usage: msg.usage,
      );
      runTokens += AiUsageService.budgetTokens(msg.usage);
      emit(
        _ev(AssistantEventType.usage)
          ..inputTokens = msg.usage.inputTokens
          ..outputTokens = msg.usage.outputTokens
          ..cacheReadTokens = msg.usage.cacheReadTokens,
      );

      // Always check stop_reason before using the content.
      final stop = msg.stopReason;
      if (stop == AiStopReason.refusal) {
        await _persistAssistant(
          null,
          AssistantService.refusalText,
          stop: AiStopReason.refusal,
          replay: false,
        );
        emit(
          _ev(AssistantEventType.refusal, text: AssistantService.refusalText),
        );
        stoppedEarly = false;
        break;
      }
      final toolUses = msg.toolCalls;
      final assistantId = await _persistAssistant(
        msg.hasContent ? msg.message : null,
        msg.text,
        stop: stop,
        replay: msg.hasContent,
      );
      if (msg.hasContent) _messages.add(msg.message);

      if (toolUses.isNotEmpty) {
        if (stop == AiStopReason.maxTokens) {
          // A cut-off tool call is never executed; answer it so the
          // history stays valid, then offer "Continue".
          await _appendToolResults([
            for (final t in toolUses)
              _toolResult(
                t.callId,
                t.toolName,
                jsonEncode({
                  'code': 'truncated',
                  'message':
                      'The output was cut off before this call was complete; '
                      'it was not executed.',
                }),
                isError: true,
              ),
          ]);
          emit(_ev(AssistantEventType.maxTokens));
          stoppedEarly = false;
          break;
        }
        final activities = <AssistantToolActivity>[];
        final results = await Future.wait([
          for (final t in toolUses) _execute(runner, t, applyMode, activities),
        ]);
        await _setToolCalls(assistantId, activities);
        await _appendToolResults(results);
        if (ar.cancel.isCancelled) break;
        continue;
      }
      if (stop == AiStopReason.maxTokens) {
        emit(_ev(AssistantEventType.maxTokens));
      }
      stoppedEarly = false;
      break;
    }
    if (stoppedEarly && !ar.cancel.isCancelled) {
      emit(
        _ev(AssistantEventType.error)
          ..error =
              'The assistant stopped after ${config.maxToolRounds} steps. '
              'Send a message to let it continue.'
          ..errorCode = 'max_rounds',
      );
    }
    thread = thread.copyWith(updatedAt: nowUtc());
    await AssistantThread.db.updateRow(session, thread);
    final done = _ev(AssistantEventType.done, text: _answer.toString())
      ..messageId = _lastAssistantId
      ..errorCode = ar.cancel.isCancelled ? 'stopped' : null;
    return done;
  }

  /// `change_id`s of the run's successful tool calls, in order.
  final List<String> _changeIds = [];

  /// `ui.*` tools relayed to the requesting window.
  Set<String> _uiTools = const {};
  bool _uiListening = false;

  void _onUiReply(SerializableModel m) {
    if (m is! UiBridgeResponse) return;
    final c = ar.uiCalls[m.requestId];
    if (c != null && !c.isCompleted) c.complete(m);
  }

  /// Runs [tool] in the requesting window: a `uiToolCall` event, answered
  /// through `assistant.uiToolResult` (Sheets 12 §6.2).
  Future<ToolOutcome> _uiCall(
    String id,
    String tool,
    Map<String, Object?> input,
  ) async {
    if (Cluster.distributed && !_uiListening) {
      _uiListening = true;
      session.messages.addListener(
        AssistantService.uiChannel(ar.runId),
        _onUiReply,
      );
    }
    final completer = Completer<UiBridgeResponse>();
    ar.uiCalls[id] = completer;
    emit(
      _ev(AssistantEventType.uiToolCall)
        ..toolUseId = id
        ..toolName = tool
        ..argsJson = jsonEncode(input),
    );
    UiBridgeResponse response;
    try {
      response = await completer.future.timeout(AssistantService.uiToolTimeout);
    } on TimeoutException {
      return ToolOutcome.failure(
        McpToolException(
          McpErrorCode.timeout,
          'The window did not answer $tool in time.',
        ),
      );
    } finally {
      ar.uiCalls.remove(id);
    }
    if (!response.ok) {
      return ToolOutcome.failure(
        McpToolException(
          response.errorCode ?? McpErrorCode.internal,
          response.errorMessage ?? '$tool failed in the window.',
        ),
      );
    }
    Object? result;
    final raw = response.resultJson;
    if (raw != null) {
      try {
        result = jsonDecode(raw);
      } on FormatException {
        result = raw;
      }
    }
    return ToolOutcome.success(
      ToolResult(
        result is Map ? result.cast<String, Object?>() : {'result': result},
        text: response.text,
      ),
    );
  }

  Future<void> _loadHistory() async {
    final rows = await AssistantMessage.db.find(
      session,
      where: (m) => m.threadId.equals(ar.threadId) & m.replay.equals(true),
      orderBy: (m) => m.id,
    );
    final toolNames = <String, String>{};
    for (final m in rows) {
      final msg = AssistantHistory.decode(m.role, m.contentJson, toolNames);
      if (msg != null) _messages.add(msg);
    }
  }

  /// Appends the user's turn: the frozen document snapshot (first turn,
  /// cached) or a "document updated" element, then the message with the
  /// volatile context at its end.
  Future<int> _appendUserTurn(AiApplyMode applyMode) async {
    final (blocks, updated) = await target.userTurn(
      session,
      thread: thread,
      first: _messages.isEmpty,
      message: message,
      hints: hints,
      applyMode: applyMode,
      actor: actor,
      executor: executor,
    );
    thread = updated.copyWith(updatedAt: nowUtc());
    await AssistantThread.db.updateRow(session, thread);
    final userTurn = ChatMessage(role: ChatMessageRole.user, parts: blocks);
    final row = await AssistantMessage.db.insertRow(
      session,
      AssistantMessage(
        threadId: ar.threadId,
        role: 'user',
        contentJson: AssistantHistory.encode(userTurn),
        displayText: message,
        runId: ar.runId,
        createdAt: nowUtc(),
      ),
    );
    _messages.add(userTurn);
    return row.id!;
  }

  Future<int> _persistAssistant(
    ChatMessage? content,
    String text, {
    String? stop,
    required bool replay,
  }) async {
    final row = await AssistantMessage.db.insertRow(
      session,
      AssistantMessage(
        threadId: ar.threadId,
        role: 'assistant',
        contentJson: content == null ? '[]' : AssistantHistory.encode(content),
        displayText: text,
        visible: text.trim().isNotEmpty || stop == 'refusal',
        replay: replay,
        runId: ar.runId,
        stopReason: stop,
        createdAt: nowUtc(),
      ),
    );
    if (row.visible) _lastAssistantId = row.id;
    return row.id!;
  }

  Future<void> _setToolCalls(
    int messageId,
    List<AssistantToolActivity> a,
  ) async {
    if (a.isEmpty) return;
    final row = await AssistantMessage.db.findById(session, messageId);
    if (row == null) return;
    await AssistantMessage.db.updateRow(
      session,
      row.copyWith(
        toolCallsJson: jsonEncode([for (final x in a) x.toJson()]),
        visible: true,
      ),
    );
    _lastAssistantId = row.id;
  }

  Future<void> _appendToolResults(List<ToolPart> results) async {
    final turn = ChatMessage(role: ChatMessageRole.user, parts: results);
    await AssistantMessage.db.insertRow(
      session,
      AssistantMessage(
        threadId: ar.threadId,
        role: 'user',
        contentJson: AssistantHistory.encode(turn),
        displayText: '',
        visible: false,
        runId: ar.runId,
        createdAt: nowUtc(),
      ),
    );
    _messages.add(turn);
  }

  /// A tool result. Providers have no common error flag: failures are
  /// JSON with `code` and `message` (and the tool chip shows them).
  static ToolPart _toolResult(
    String id,
    String toolName,
    String content, {
    bool isError = false,
  }) => ToolPart.result(callId: id, toolName: toolName, result: content);

  ToolContext _toolContext({bool guarded = true}) => target.toolContext(
    session,
    actor,
    runId: ar.runId,
    hints: hints,
    guarded: guarded,
  );

  Future<ToolPart> _execute(
    AssistantToolRunner runner,
    ToolPart call,
    AiApplyMode applyMode,
    List<AssistantToolActivity> activities,
  ) async {
    final id = call.callId;
    final apiName = call.toolName;
    final tool = runner.toolset.byApiName(apiName);
    final mcpName = tool?.name ?? apiName;
    final activity = AssistantToolActivity(
      toolUseId: id,
      toolName: mcpName,
      summary: target.startLabel(mcpName),
    );
    activities.add(activity);
    emit(
      _ev(AssistantEventType.toolStarted)
        ..toolUseId = id
        ..toolName = mcpName
        ..toolSummary = activity.summary,
    );
    ToolPart finish(String content, {required bool error}) {
      activity.error = error;
      emit(
        _ev(AssistantEventType.toolFinished)
          ..toolUseId = id
          ..toolName = mcpName
          ..toolSummary = activity.summary
          ..toolError = error
          ..changeId = activity.changeId
          ..rangeStart = activity.rangeStart
          ..rangeLength = activity.rangeLength
          ..revision = activity.revision
          ..range = activity.range
          ..objectId = activity.objectId,
      );
      return _toolResult(id, apiName, content, isError: error);
    }

    final input = Map<String, Object?>.of(call.arguments ?? const {});
    var outcome = _uiTools.contains(mcpName)
        ? await _uiCall(id, mcpName, input)
        : await runner.run(
            _toolContext(),
            apiName,
            input,
            applyMode: applyMode,
          );
    if (outcome.error?.code == 'needs_confirmation') {
      final details = outcome.error!.details;
      final summary = details is Map
          ? '${details['summary'] ?? outcome.error!.message}'
          : outcome.error!.message;
      final confirmationId = const Uuid().v4();
      final completer = Completer<bool>();
      ar.confirmations[confirmationId] = completer;
      emit(
        _ev(AssistantEventType.confirmationRequired)
          ..toolUseId = id
          ..toolName = mcpName
          ..toolSummary = summary
          ..confirmationId = confirmationId,
      );
      final allow = await completer.future.timeout(
        AssistantService.confirmationTimeout,
        onTimeout: () => false,
      );
      ar.confirmations.remove(confirmationId);
      if (!allow) {
        activity.summary = 'Change denied';
        return finish(
          jsonEncode({
            'code': 'denied_by_user',
            'message':
                'The user denied this change. Do not try to make it in '
                'another way; ask the user what they want instead.',
          }),
          error: true,
        );
      }
      outcome = await runner.run(
        _toolContext(guarded: false),
        apiName,
        input,
        applyMode: applyMode,
      );
    }
    final err = outcome.error;
    if (err != null) {
      activity.summary = '${activity.summary} failed';
      return finish(jsonEncode(err.toJson()), error: true);
    }
    final r = outcome.result!;
    final structured = r.structured;
    if (structured is Map) target.annotate(activity, structured);
    final change = activity.changeId;
    if (change != null) _changeIds.add(change);
    var text = target.resultText(mcpName, r);
    if (text.length > AssistantService.maxToolResultChars) {
      text =
          '${text.substring(0, AssistantService.maxToolResultChars)}\n'
          '[truncated: the result was longer than '
          '${AssistantService.maxToolResultChars} characters]';
    }
    return finish(text, error: false);
  }
}
