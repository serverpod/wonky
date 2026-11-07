import 'dart:async';

import 'package:wonky_client/wonky_client.dart';

import 'assistant_api.dart';

/// An in-memory [AssistantApi] for widget tests: scripted chat events per
/// message, recorded calls, threads kept in memory.
class FakeAssistantApi implements AssistantApi {
  FakeAssistantApi({AssistantStatus? status})
    : status =
          status ??
          AssistantStatus(
            available: true,
            quality: AiQuality.best,
            tokensUsedToday: 0,
            dailyTokenBudget: 1000000,
          );

  AssistantStatus status;

  /// Events of the next chats, in order (one list per message). A chat
  /// without a script answers "OK".
  final List<List<AssistantEvent>> chatScripts = [];

  /// When set, chats stay open until [releaseChat] (Stop / streaming tests).
  bool holdChats = false;
  StreamController<AssistantEvent>? _held;

  /// Inline scripts (one per request).
  final List<List<InlineAiEvent>> inlineScripts = [];
  final List<List<ProofreadEvent>> proofreadScripts = [];

  final List<String> sent = [];
  final List<AssistantContextHints> sentHints = [];
  final List<InlineAiRequest> inlineRequests = [];
  final List<String> reverted = [];
  final List<(String, bool)> confirmations = [];
  int stops = 0;

  final Map<int, AssistantThreadDetail> threads = {};
  int _nextThread = 1;

  @override
  Future<AssistantStatus> getStatus() async => status;

  @override
  Future<AssistantStatus> setQuality(AiQuality quality) async {
    status = status.copyWith(quality: quality);
    return status;
  }

  /// Keys saved through [setProviderKey] (provider, key), in order.
  final List<(AiProvider, String)> savedKeys = [];

  @override
  Future<AssistantStatus> setProviderKey(
    AiProvider provider,
    String apiKey,
  ) async {
    savedKeys.add((provider, apiKey));
    final k = apiKey.trim();
    status = status.copyWith(
      available: true,
      reason: null,
      message: null,
      provider: provider,
      keySource: 'user',
      userKey: AiProviderKeyView(
        provider: provider,
        last4: k.length <= 4 ? k : k.substring(k.length - 4),
        updatedAt: DateTime.utc(2026),
      ),
    );
    return status;
  }

  /// Keys shared through [setOrgProviderKey] (provider, key), in order.
  final List<(AiProvider, String)> savedOrgKeys = [];

  @override
  Future<AssistantStatus> setOrgProviderKey(
    AiProvider provider,
    String apiKey,
  ) async {
    savedOrgKeys.add((provider, apiKey));
    final k = apiKey.trim();
    final own = status.userKey != null;
    status = status.copyWith(
      available: true,
      reason: null,
      message: null,
      provider: own ? status.provider : provider,
      keySource: own ? 'user' : 'organization',
      orgKey: AiOrgKeyView(
        provider: provider,
        last4: k.length <= 4 ? k : k.substring(k.length - 4),
        updatedAt: DateTime.utc(2026),
        addedBy: 'Me',
      ),
    );
    return status;
  }

  @override
  Future<AssistantStatus> removeOrgProviderKey() async {
    final own = status.userKey != null;
    status = AssistantStatus(
      available: own,
      reason: own ? null : 'notConfigured',
      quality: status.quality,
      tokensUsedToday: status.tokensUsedToday,
      dailyTokenBudget: status.dailyTokenBudget,
      provider: own ? status.provider : null,
      keySource: own ? 'user' : null,
      userKeysAllowed: status.userKeysAllowed,
      userKey: status.userKey,
      organization: status.organization,
    );
    return status;
  }

  @override
  Future<AssistantStatus> removeProviderKey() async {
    final org = status.orgKey;
    status = AssistantStatus(
      available: org != null,
      reason: org != null ? null : 'notConfigured',
      quality: status.quality,
      tokensUsedToday: status.tokensUsedToday,
      dailyTokenBudget: status.dailyTokenBudget,
      provider: org?.provider,
      keySource: org != null ? 'organization' : null,
      userKeysAllowed: status.userKeysAllowed,
      organization: status.organization,
      orgKey: org,
    );
    return status;
  }

  @override
  Stream<AssistantEvent> chat({
    required int? threadId,
    required UuidValue itemUuid,
    required String message,
    required AssistantContextHints hints,
  }) {
    sent.add(message);
    sentHints.add(hints);
    final id = threadId ?? _nextThread++;
    threads.putIfAbsent(
      id,
      () => AssistantThreadDetail(
        thread: AssistantThreadView(
          id: id,
          itemUuid: itemUuid,
          title: message,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        messages: [],
      ),
    );
    final script = chatScripts.isEmpty
        ? [
            AssistantEvent(type: AssistantEventType.textDelta, text: 'OK'),
            AssistantEvent(type: AssistantEventType.done, text: 'OK'),
          ]
        : chatScripts.removeAt(0);
    final events = [
      AssistantEvent(
        type: AssistantEventType.started,
        threadId: id,
        runId: 'run-$id-${sent.length}',
      ),
      for (final e in script)
        e.copyWith(threadId: id, runId: e.runId ?? 'run-$id-${sent.length}'),
    ];
    if (!holdChats) return Stream.fromIterable(events);
    final c = StreamController<AssistantEvent>();
    _held = c;
    for (final e in events.where((e) => e.type != AssistantEventType.done)) {
      c.add(e);
    }
    return c.stream;
  }

  /// Events of the next quick actions, in order. Without a script the
  /// action answers "Done."
  final List<List<AssistantEvent>> quickScripts = [];

  /// Quick actions run, in order.
  final List<AssistantQuickAction> quickActions = [];

  @override
  Stream<AssistantEvent> quickAction({
    required int? threadId,
    required UuidValue itemUuid,
    required AssistantQuickAction action,
    required AssistantContextHints hints,
  }) {
    quickActions.add(action);
    sentHints.add(hints);
    final id = threadId ?? _nextThread++;
    threads.putIfAbsent(
      id,
      () => AssistantThreadDetail(
        thread: AssistantThreadView(
          id: id,
          itemUuid: itemUuid,
          title: action.name,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        messages: [],
      ),
    );
    final runId = 'quick-$id-${quickActions.length}';
    final script = quickScripts.isEmpty
        ? [
            AssistantEvent(type: AssistantEventType.textDelta, text: 'Done.'),
            AssistantEvent(type: AssistantEventType.done, text: 'Done.'),
          ]
        : quickScripts.removeAt(0);
    final events = [
      AssistantEvent(
        type: AssistantEventType.started,
        threadId: id,
        runId: runId,
      ),
      for (final e in script) e.copyWith(threadId: id, runId: e.runId ?? runId),
    ];
    if (!holdChats) return Stream.fromIterable(events);
    final c = StreamController<AssistantEvent>();
    _held = c;
    for (final e in events.where((e) => e.type != AssistantEventType.done)) {
      c.add(e);
    }
    return c.stream;
  }

  /// Ends a held chat with `done` ([stopped]: as after Stop).
  Future<void> releaseChat({bool stopped = false}) async {
    final c = _held;
    if (c == null) return;
    _held = null;
    c.add(
      AssistantEvent(
        type: AssistantEventType.done,
        errorCode: stopped ? 'stopped' : null,
      ),
    );
    await c.close();
  }

  @override
  Future<bool> stop({int? threadId, String? runId}) async {
    stops++;
    await releaseChat(stopped: true);
    return true;
  }

  @override
  Future<bool> confirm(String runId, String confirmationId, bool allow) async {
    confirmations.add((confirmationId, allow));
    return true;
  }

  /// Answers of `uiToolCall` events, in order.
  final List<UiBridgeResponse> uiResults = [];

  @override
  Future<bool> uiToolResult(String runId, UiBridgeResponse response) async {
    uiResults.add(response);
    return true;
  }

  @override
  Future<List<AssistantThreadView>> listThreads(UuidValue itemUuid) async => [
    for (final t in threads.values) t.thread,
  ];

  @override
  Future<AssistantThreadDetail> getThread(int threadId) async =>
      threads[threadId] ??
      (throw WonkyException(
        code: WonkyErrorCode.notFound,
        message: 'Conversation not found.',
      ));

  @override
  Future<void> deleteThread(int threadId) async => threads.remove(threadId);

  @override
  Future<int> clearHistory() async {
    final n = threads.length;
    threads.clear();
    return n;
  }

  @override
  Future<void> revertChange(String changeId) async => reverted.add(changeId);

  @override
  Stream<InlineAiEvent> inline(InlineAiRequest request) {
    inlineRequests.add(request);
    final script = inlineScripts.isEmpty
        ? [InlineAiEvent(type: InlineAiEventType.done, markdown: 'OK')]
        : inlineScripts.removeAt(0);
    return Stream.fromIterable(script);
  }

  @override
  Stream<ProofreadEvent> proofread(
    UuidValue itemUuid, {
    int? start,
    int? length,
  }) => Stream.fromIterable(
    proofreadScripts.isEmpty
        ? [ProofreadEvent(type: 'done')]
        : proofreadScripts.removeAt(0),
  );

  // ---------------------------------------------------------- style guides

  /// The library: two built-ins plus the guides saved here.
  final List<StyleGuideView> guides = [
    StyleGuideView(
      ref: 'builtin:plain-language',
      name: 'Plain language',
      description: 'Simple words.',
      markdown: '# Plain language',
      source: 'builtIn',
      sharedWithOrg: false,
      editable: false,
    ),
    StyleGuideView(
      ref: 'builtin:technical',
      name: 'Technical documentation',
      description: 'Precise.',
      markdown: '# Technical',
      source: 'builtIn',
      sharedWithOrg: false,
      editable: false,
    ),
  ];
  String? orgKey = 'acme.dev';
  String? orgDefaultRef;
  final Map<String, String> documentRefs = {};
  int _nextGuide = 1;

  /// Style guide calls, in order (`save:<name>`, `delete:<uuid>`,
  /// `document:<ref>`, `org:<ref>`).
  final List<String> styleCalls = [];

  StyleGuideLibrary _library(UuidValue? itemUuid) {
    final doc = itemUuid == null ? null : documentRefs[itemUuid.uuid];
    return StyleGuideLibrary(
      guides: List.of(guides),
      orgKey: orgKey,
      orgDefaultRef: orgDefaultRef,
      documentRef: doc,
      effectiveRef: doc ?? orgDefaultRef,
      canSetDocument: true,
      canSetOrgDefault: orgKey != null,
    );
  }

  @override
  Future<StyleGuideLibrary> styleGuides({UuidValue? itemUuid}) async =>
      _library(itemUuid);

  @override
  Future<StyleGuideView> saveStyleGuide(StyleGuideInput input) async {
    styleCalls.add('save:${input.name}');
    final uuid =
        input.uuid ??
        UuidValue.fromString(
          '00000000-0000-7000-8000-${(_nextGuide++).toString().padLeft(12, '0')}',
        );
    final view = StyleGuideView(
      ref: 'custom:${uuid.uuid}',
      name: input.name,
      description: input.description,
      markdown: input.markdown,
      source: 'mine',
      sharedWithOrg: input.shareWithOrg,
      editable: true,
      updatedAt: DateTime.utc(2026),
    );
    final i = guides.indexWhere((g) => g.ref == view.ref);
    if (i < 0) {
      guides.add(view);
    } else {
      guides[i] = view;
    }
    return view;
  }

  @override
  Future<void> deleteStyleGuide(UuidValue uuid) async {
    styleCalls.add('delete:${uuid.uuid}');
    guides.removeWhere((g) => g.ref == 'custom:${uuid.uuid}');
  }

  @override
  Future<StyleGuideLibrary> setOrgStyleGuide(String? ref) async {
    styleCalls.add('org:$ref');
    orgDefaultRef = ref;
    return _library(null);
  }

  @override
  Future<StyleGuideLibrary> setDocumentStyleGuide(
    UuidValue itemUuid,
    String? ref,
  ) async {
    styleCalls.add('document:$ref');
    if (ref == null) {
      documentRefs.remove(itemUuid.uuid);
    } else {
      documentRefs[itemUuid.uuid] = ref;
    }
    return _library(itemUuid);
  }
}
