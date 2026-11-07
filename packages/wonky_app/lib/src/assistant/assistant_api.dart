import 'package:wonky_client/wonky_client.dart';

/// The `assistant` endpoint (suite 10 §2), behind an interface so widget
/// tests use [FakeAssistantApi] (`package:wonky_app/testing.dart`).
abstract class AssistantApi {
  Future<AssistantStatus> getStatus();
  Future<AssistantStatus> setQuality(AiQuality quality);

  /// Settings › AI providers: stores the user's own key (the server never
  /// returns it).
  Future<AssistantStatus> setProviderKey(AiProvider provider, String apiKey);
  Future<AssistantStatus> removeProviderKey();

  /// Settings › AI providers › organization key: a key shared with every
  /// member of the caller's organization (never returned either).
  Future<AssistantStatus> setOrgProviderKey(AiProvider provider, String apiKey);
  Future<AssistantStatus> removeOrgProviderKey();
  Stream<AssistantEvent> chat({
    required int? threadId,
    required UuidValue itemUuid,
    required String message,
    required AssistantContextHints hints,
  });

  /// A Write quick action (Write 09 §5.5), streamed like [chat].
  Stream<AssistantEvent> quickAction({
    required int? threadId,
    required UuidValue itemUuid,
    required AssistantQuickAction action,
    required AssistantContextHints hints,
  });
  Future<bool> stop({int? threadId, String? runId});
  Future<bool> confirm(String runId, String confirmationId, bool allow);

  /// Answers a `uiToolCall` event of run [runId] (Sheets 12 §6.2).
  Future<bool> uiToolResult(String runId, UiBridgeResponse response);
  Future<List<AssistantThreadView>> listThreads(UuidValue itemUuid);
  Future<AssistantThreadDetail> getThread(int threadId);
  Future<void> deleteThread(int threadId);
  Future<int> clearHistory();
  Future<void> revertChange(String changeId);
  Stream<InlineAiEvent> inline(InlineAiRequest request);
  Stream<ProofreadEvent> proofread(
    UuidValue itemUuid, {
    int? start,
    int? length,
  });

  // Style guides (suite 10 §7; endpoint `styleGuide`).

  /// The user's style guides; with [itemUuid] also that document's choice.
  Future<StyleGuideLibrary> styleGuides({UuidValue? itemUuid});
  Future<StyleGuideView> saveStyleGuide(StyleGuideInput input);
  Future<void> deleteStyleGuide(UuidValue uuid);
  Future<StyleGuideLibrary> setOrgStyleGuide(String? ref);
  Future<StyleGuideLibrary> setDocumentStyleGuide(
    UuidValue itemUuid,
    String? ref,
  );
}

/// [AssistantApi] over the generated client.
class ServerAssistantApi implements AssistantApi {
  ServerAssistantApi(this.client);

  final Client client;

  EndpointAssistant get _a => client.assistant;

  @override
  Future<AssistantStatus> getStatus() => _a.getStatus();

  @override
  Future<AssistantStatus> setQuality(AiQuality quality) =>
      _a.setQuality(quality);

  @override
  Future<AssistantStatus> setProviderKey(AiProvider provider, String apiKey) =>
      _a.setProviderKey(provider, apiKey);

  @override
  Future<AssistantStatus> removeProviderKey() => _a.removeProviderKey();

  @override
  Future<AssistantStatus> setOrgProviderKey(
    AiProvider provider,
    String apiKey,
  ) => _a.setOrganizationProviderKey(provider, apiKey);

  @override
  Future<AssistantStatus> removeOrgProviderKey() =>
      _a.removeOrganizationProviderKey();

  @override
  Stream<AssistantEvent> chat({
    required int? threadId,
    required UuidValue itemUuid,
    required String message,
    required AssistantContextHints hints,
  }) => _a.chat(threadId, itemUuid, message, hints);

  @override
  Stream<AssistantEvent> quickAction({
    required int? threadId,
    required UuidValue itemUuid,
    required AssistantQuickAction action,
    required AssistantContextHints hints,
  }) => _a.quickAction(threadId, itemUuid, action, hints);

  @override
  Future<bool> stop({int? threadId, String? runId}) => _a.stop(threadId, runId);

  @override
  Future<bool> confirm(String runId, String confirmationId, bool allow) =>
      _a.confirm(runId, confirmationId, allow);

  @override
  Future<bool> uiToolResult(String runId, UiBridgeResponse response) =>
      _a.uiToolResult(runId, response);

  @override
  Future<List<AssistantThreadView>> listThreads(UuidValue itemUuid) =>
      _a.listThreads(itemUuid);

  @override
  Future<AssistantThreadDetail> getThread(int threadId) =>
      _a.getThread(threadId);

  @override
  Future<void> deleteThread(int threadId) => _a.deleteThread(threadId);

  @override
  Future<int> clearHistory() => _a.clearHistory();

  @override
  Future<void> revertChange(String changeId) => _a.revertChange(changeId);

  @override
  Stream<InlineAiEvent> inline(InlineAiRequest request) => _a.inline(request);

  @override
  Stream<ProofreadEvent> proofread(
    UuidValue itemUuid, {
    int? start,
    int? length,
  }) => _a.proofread(itemUuid, start, length);

  EndpointStyleGuide get _s => client.styleGuide;

  @override
  Future<StyleGuideLibrary> styleGuides({UuidValue? itemUuid}) =>
      _s.library(itemUuid);

  @override
  Future<StyleGuideView> saveStyleGuide(StyleGuideInput input) =>
      _s.save(input);

  @override
  Future<void> deleteStyleGuide(UuidValue uuid) => _s.delete(uuid);

  @override
  Future<StyleGuideLibrary> setOrgStyleGuide(String? ref) =>
      _s.setOrgDefault(ref);

  @override
  Future<StyleGuideLibrary> setDocumentStyleGuide(
    UuidValue itemUuid,
    String? ref,
  ) => _s.setDocumentStyle(itemUuid, ref);
}
