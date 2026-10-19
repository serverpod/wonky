import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../ai/llm/ai_client.dart';
import '../../ai/untrusted_text.dart';
import '../../common/models.dart';
import 'board_ai.dart';
import 'board_ai_ledger.dart';
import 'board_gemini_prompts.dart';
import 'spec_index.g.dart';
import 'task_prompt_template.dart';

/// The writing side of the board AI (specs/16 §6.1): Gemini through a
/// `DartanticAiClient` built directly with `internalGeminiApiKey` (never
/// through `AiKeys`). Every feature is one model turn with a tool the model
/// must call once, read with a JSON fallback. Usage goes to
/// [BoardAiLedger], never to the in-app `ai_usage` table.
class BoardGemini {
  BoardGemini(
    this.client, {
    required this.model,
    required this.fastModel,
  });

  final AiModelClient client;

  /// `board.ai.geminiModel` (bundles, task prompts).
  final String model;

  /// `board.ai.geminiFastModel` (titles and summaries).
  final String fastModel;

  static const maxSummaryChars = 200;
  static const maxTitleChars = 120;
  static const maxBundlePosts = 200;
  static const maxCommentsPerPost = 20;
  static const maxBodyChars = 12000;
  static const maxCommentChars = 2000;

  // ------------------------------------------------------------- features

  Future<({String? title, String summary})> summarize(
    Session session,
    BoardPost post,
  ) async {
    final input = await _callTool(
      session,
      model: fastModel,
      feature: 'summary',
      system: BoardGeminiPrompts.summary,
      tool: BoardGeminiPrompts.summaryTool,
      maxTokens: 4096,
      user:
          'Post kind: ${post.kind.name}\n'
          'App in use: ${post.appHint}\n'
          '${wrap('Title: ${post.title}\n\n${_clip(post.body, maxBodyChars)}')}',
    );
    final summary = _plain(input['summary']);
    if (summary.isEmpty) {
      throw BoardAiException('Gemini returned no summary.');
    }
    var title = _plain(input['title']);
    if (title.endsWith('.')) title = title.substring(0, title.length - 1);
    final same = title.toLowerCase().trim() == post.title.toLowerCase().trim();
    return (
      title: title.isEmpty || same ? null : _clip(title, maxTitleChars),
      summary: _clip(summary, maxSummaryChars),
    );
  }

  Future<List<BoardBundleProposal>> suggestBundles(
    Session session,
    List<BoardPost> posts,
  ) async {
    final input = posts.where((p) => p.id != null).take(maxBundlePosts);
    final byId = {for (final p in input) p.id!: p};
    if (byId.length < 2) return const [];
    final lines = [
      for (final p in byId.values)
        '#${p.id} [${p.kind.name}, ${p.area?.name ?? 'unlabeled'}] '
            '${_oneLine(p.title)} — '
            '${_oneLine(p.summary ?? _clip(p.body, maxSummaryChars))}',
    ];
    final out = await _callTool(
      session,
      model: model,
      feature: 'bundles',
      system: BoardGeminiPrompts.bundles,
      tool: BoardGeminiPrompts.bundlesTool,
      maxTokens: 16000,
      user: 'Posts:\n${wrap(lines.join('\n'))}',
    );
    return parseBundles(out, byId);
  }

  /// Validates the model's bundles: ids from the input only, each post in
  /// at most one bundle, 2–8 posts.
  static List<BoardBundleProposal> parseBundles(
    Map<String, Object?> input,
    Map<int, BoardPost> byId,
  ) {
    final raw = input['bundles'];
    if (raw is! List) return const [];
    final used = <int>{};
    final result = <BoardBundleProposal>[];
    for (final b in raw) {
      if (b is! Map) continue;
      final idsRaw = b['post_ids'] ?? b['postIds'];
      if (idsRaw is! List) continue;
      final ids = <int>[];
      for (final v in idsRaw) {
        final id = v is int ? v : int.tryParse('$v'.replaceAll('#', ''));
        if (id == null || !byId.containsKey(id) || used.contains(id)) continue;
        if (!ids.contains(id)) ids.add(id);
      }
      if (ids.length < 2) continue;
      if (ids.length > 8) ids.removeRange(8, ids.length);
      final areas = {for (final id in ids) byId[id]!.area};
      final area =
          BoardArea.values.where((a) => a.name == b['area']).firstOrNull ??
          (areas.length == 1 ? areas.first : null);
      final title = _plain(b['title']);
      if (title.isEmpty) continue;
      used.addAll(ids);
      result.add(
        BoardBundleProposal(
          title: _clip(title, maxTitleChars),
          rationale: _clip(_plain(b['rationale']), 500),
          postIds: ids,
          area: area,
        ),
      );
    }
    return result;
  }

  Future<String> writeTaskPrompt(
    Session session, {
    required BoardTask task,
    required List<BoardPost> posts,
    required Map<int, List<BoardComment>> comments,
    required Uri webOrigin,
  }) async {
    final out = await _callTool(
      session,
      model: model,
      feature: 'task_prompt',
      system: BoardGeminiPrompts.taskPrompt,
      tool: BoardGeminiPrompts.taskPromptTool,
      maxTokens: 32000,
      user: taskPromptMessage(
        task: task,
        posts: posts,
        comments: comments,
        webOrigin: webOrigin,
      ),
    );
    final body = cleanTaskPromptBody(_text(out['body'] ?? out['markdown']));
    if (body.isEmpty) {
      throw BoardAiException('Gemini returned an empty task prompt.');
    }
    return changesUi(out['changesUi'], task.area)
        ? TaskPromptTemplate.withScreenshotCriterion(body)
        : body;
  }

  /// Whether a task prompt gets the screenshot criterion (T-16): the
  /// model's `changesUi`, or, when it is missing, every area but `server`
  /// (the only one without visible UI).
  static bool changesUi(Object? flag, BoardArea area) =>
      flag is bool ? flag : area != BoardArea.server;

  /// The user message of [writeTaskPrompt].
  static String taskPromptMessage({
    required BoardTask task,
    required List<BoardPost> posts,
    required Map<int, List<BoardComment>> comments,
    required Uri webOrigin,
  }) {
    final b = StringBuffer()
      ..writeln('# Task')
      ..writeln('Title: ${_oneLine(task.title)}')
      ..writeln('Area: ${task.area.name}')
      ..writeln('Size: ${task.size.name}')
      ..writeln()
      ..writeln('# Issues');
    for (final p in posts) {
      final post = StringBuffer()
        ..writeln('Issue #${p.id} (${p.kind.name})')
        ..writeln('Title: ${p.title}')
        ..writeln()
        ..writeln(_clip(p.body, maxBodyChars));
      final details = p.contextJson;
      if (details != null && details.trim().isNotEmpty) {
        post
          ..writeln()
          ..writeln('Included details: ${_clip(details, 2000)}');
      }
      if (p.screenshotFileId != null && p.id != null) {
        final url = webOrigin.replace(
          path: '/improvements/p/${p.id}/screenshot',
        );
        post
          ..writeln()
          ..writeln('Screenshot: $url');
      }
      final cs = (comments[p.id] ?? const <BoardComment>[])
          .where(
            (c) =>
                c.systemEvent == null &&
                c.deletedAt == null &&
                c.moderation == BoardModeration.visible,
          )
          .take(maxCommentsPerPost)
          .toList();
      if (cs.isNotEmpty) {
        post
          ..writeln()
          ..writeln('Comments:');
        for (final c in cs) {
          post.writeln('- ${_oneLine(_clip(c.body, maxCommentChars))}');
        }
      }
      b.writeln(wrap(post.toString().trim()));
      b.writeln();
    }
    b
      ..writeln('# Repository layout')
      ..writeln(BoardGeminiPrompts.repositoryLayout)
      ..writeln()
      ..writeln('# Spec index')
      ..writeln(specIndexFor(task.area));
    return b.toString();
  }

  /// The spec index of [area]: the README tables and the suite specs,
  /// plus the app's own specs for the four apps.
  static String specIndexFor(BoardArea area) {
    final app = specIndexApps[area.name];
    return [
      specIndexReadme,
      specIndexSuite,
      ?app,
    ].join('\n\n');
  }

  /// Drops what the fixed template owns (an H1, the report and "when you
  /// are done" sections) from a model-written body.
  static String cleanTaskPromptBody(String body) {
    final out = <String>[];
    var skipping = false;
    for (final line in body.replaceAll('\r\n', '\n').split('\n')) {
      final t = line.trim();
      if (t.startsWith('# ')) continue;
      if (t.startsWith('## ')) {
        final h = t.substring(3).trim().toLowerCase();
        skipping =
            h.startsWith('reports this task') || h.startsWith('when you are');
        if (skipping) continue;
      }
      if (!skipping) out.add(line);
    }
    return out.join('\n').trim();
  }

  // ------------------------------------------------------------- plumbing

  /// [s] inside `<board_data>` with closing tags in it defused.
  static String wrap(String s) =>
      UntrustedText.wrap(BoardGeminiPrompts.dataTag, s);

  Future<Map<String, Object?>> _callTool(
    Session session, {
    required String model,
    required String feature,
    required String system,
    required AiToolSpec tool,
    required String user,
    required int maxTokens,
  }) async {
    final request = AiRequest(
      model: model,
      system: system,
      tools: [tool],
      messages: [ChatMessage.user(user)],
      maxTokens: maxTokens,
      feature: 'board_$feature',
    );
    // Fast models sometimes call the tool without arguments: one retry.
    for (var attempt = 0; ; attempt++) {
      final r = await _send(session, request, feature);
      final input = _toolInput(r, tool.name) ?? _jsonIn(r.text);
      if (input != null && input.isNotEmpty) return input;
      if (attempt >= 1) {
        throw BoardAiException('Gemini did not call ${tool.name}.');
      }
    }
  }

  Future<AiResponse> _send(
    Session session,
    AiRequest request,
    String feature,
  ) async {
    final AiResponse r;
    try {
      r = await client.send(request);
    } on AiApiException catch (e) {
      final s = e.statusCode;
      throw BoardAiException(
        'Gemini failed ($s ${e.type}).',
        retryable: e.type != 'refusal' && (s == 0 || s == 429 || s >= 500),
      );
    }
    try {
      await BoardAiLedger.record(
        session,
        provider: BoardAiLedger.gemini,
        model: (r.model ?? request.model).replaceFirst('models/', ''),
        feature: feature,
        inputTokens: r.usage.inputTokens,
        outputTokens: r.usage.outputTokens,
      );
    } on Object catch (e) {
      session.log('Board AI usage not recorded: $e', level: LogLevel.warning);
    }
    if (r.stopReason == AiStopReason.refusal) {
      throw BoardAiException('Gemini declined to answer.', retryable: false);
    }
    return r;
  }

  static Map<String, Object?>? _toolInput(AiResponse r, String tool) {
    for (final call in r.toolCalls) {
      if (call.toolName == tool) return call.arguments ?? const {};
    }
    return null;
  }

  static Map<String, Object?>? _jsonIn(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final j = jsonDecode(text.substring(start, end + 1));
      return j is Map ? j.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? v) => v is String ? v.trim() : '';

  /// One line of plain text.
  static String _plain(Object? v) => _oneLine(_text(v));

  static String _oneLine(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max - 1).trimRight()}…';
}
