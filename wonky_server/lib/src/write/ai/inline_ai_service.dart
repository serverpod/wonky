import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/ai/ai_call.dart';
import '../../platform/ai/ai_models.dart';
import '../../platform/ai/llm/ai_client.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../mcp/headless_editor.dart';
import 'write_context_builder.dart';
import 'write_prompts.dart';

/// Inline AI without tools (Write 09 §5.3–5.5): selection rewrites with a
/// preview, continue writing, and summaries / outlines / explanations for
/// the panel. Streams [InlineAiEvent]s.
abstract final class InlineAiService {
  static const rewriteActions = {
    'improve',
    'fixGrammar',
    'shorter',
    'longer',
    'tone',
    'translate',
    'custom',
  };
  static const panelActions = {
    'explain',
    'summarize',
    'summarizeDocument',
    'generateOutline',
  };
  static const continueAction = 'continueWriting';

  /// Words of context before the caret for continue writing.
  static const continueContextWords = 3000;

  /// Most characters of one text field of a request (CQ-31: client text
  /// goes into the prompt, so it is capped on the server).
  static const maxFieldChars = 50000;

  /// Throws `tooLarge` when a text field of [req] is longer than
  /// [maxFieldChars].
  static void checkInputSizes(InlineAiRequest req) {
    for (final (name, value) in [
      ('selectedMarkdown', req.selectedMarkdown),
      ('contextBefore', req.contextBefore),
      ('contextAfter', req.contextAfter),
      ('instruction', req.instruction),
      ('previousOutput', req.previousOutput),
      ('tone', req.tone),
      ('targetLanguage', req.targetLanguage),
    ]) {
      if ((value?.length ?? 0) > maxFieldChars) {
        throw Errors.tooLarge(
          'The text is too long for AI ($name). Select less text.',
        );
      }
    }
  }

  static Future<Stream<InlineAiEvent>> run(
    Session session,
    Actor actor,
    InlineAiRequest req, {
    Future<Session> Function()? runSession,
  }) async {
    final action = req.action;
    final isRewrite = rewriteActions.contains(action);
    final isContinue = action == continueAction;
    if (!isRewrite && !isContinue && !panelActions.contains(action)) {
      throw Errors.invalid('Unknown AI action "$action".');
    }
    checkInputSizes(req);
    final ai = await AiCall.open(session, actor);
    final target = await HeadlessDocumentEditor.resolve(
      session,
      actor,
      req.itemUuid,
      min: isRewrite || isContinue ? Role.commenter : Role.viewer,
    );
    final quality = await ai.quality(session);
    final ctx = await WriteContextBuilder.load(session, target);
    final request = build(
      req,
      ctx,
      quality,
      model: ai.model,
      userId: actor.userId,
    );
    // Last, right before the run starts: the run holds the slot until it
    // ends.
    return ai.stream(
      session,
      runSession: runSession,
      (s, cancel, emit) async {
        final msg = await ai.send(
          s,
          request,
          cancel: cancel,
          onText: (t) =>
              emit(InlineAiEvent(type: InlineAiEventType.textDelta, text: t)),
        );
        emit(
          InlineAiEvent(
            type: InlineAiEventType.done,
            markdown: clean(msg.text, keepLeadingSpace: isContinue),
            errorCode: msg.stopReason == AiStopReason.maxTokens
                ? 'max_tokens'
                : null,
          ),
        );
      },
      onFailure: (f) => f.inlineEvent,
    );
  }

  /// The model request of [req] (pure; tests check prompts and tiers).
  /// [model] maps a tier to the provider's model id.
  static AiRequest build(
    InlineAiRequest req,
    WriteDocContext ctx,
    AiQuality quality, {
    required String Function(AiTier tier) model,
    int? userId,
  }) {
    final action = req.action;
    final outline = WriteContextBuilder.outlineJson(ctx);
    ChatMessage user(String text) => ChatMessage.user(text);
    if (rewriteActions.contains(action)) {
      final tier = AiTier.rewrite(quality);
      final instruction = WritePrompts.rewriteInstruction(
        action,
        tone: req.tone,
        language: req.targetLanguage,
        instruction: req.instruction,
      );
      final first =
          '<document_title>${ctx.title}</document_title>\n'
          '<document_outline>$outline</document_outline>\n'
          '<context_before>${req.contextBefore ?? ''}</context_before>\n'
          '<selection>${req.selectedMarkdown ?? ''}</selection>\n'
          '<context_after>${req.contextAfter ?? ''}</context_after>\n'
          '<action>$instruction</action>\n'
          'Reply with only the replacement Markdown for <selection>.';
      final prev = req.previousOutput;
      final messages = [
        user(first),
        if (prev != null) ...[
          ChatMessage.model(prev.isEmpty ? '(empty)' : prev),
          user(
            'Revise your replacement: '
            '${(req.instruction ?? '').trim().isEmpty ? 'try a different version' : req.instruction!.trim()}. '
            'Reply with only the revised replacement Markdown.',
          ),
        ],
      ];
      return AiRequest(
        model: model(tier),
        effort: tier.effort,
        maxTokens: 32000,
        system: WritePrompts.rewrite,
        messages: messages,
        userId: userId == null ? null : 'u$userId',
        feature: 'rewrite',
      );
    }
    if (action == continueAction) {
      final tier = AiTier.continueWriting(quality);
      final caret = (req.start ?? ctx.doc.length - 1).clamp(
        0,
        ctx.doc.length - 1,
      );
      final before = _lastWords(
        DocumentReader.renderMarkdown(
          ctx.content.slice(0, caret),
          SuggestionViewMode.accepted,
        ),
        continueContextWords,
      );
      final line = ctx.doc.lineAt(caret);
      final emptyLine = line.contentLength == 0;
      final maxWords = (req.maxWords ?? 300).clamp(10, 300);
      return AiRequest(
        model: model(tier),
        effort: tier.effort,
        maxTokens: 8000,
        system: WritePrompts.continueWriting,
        messages: [
          user(
            '<document_title>${ctx.title}</document_title>\n'
            '<document_outline>$outline</document_outline>\n'
            '<text_before_caret>$before</text_before_caret>\n'
            '<caret>${emptyLine ? 'at the start of an empty paragraph' : 'at the end of the text above, inside its last paragraph'}</caret>\n'
            'Continue writing from the caret. At most $maxWords words.'
            '${(req.instruction ?? '').trim().isEmpty ? '' : ' Guidance from the user: ${req.instruction!.trim()}'}',
          ),
        ],
        userId: userId == null ? null : 'u$userId',
        feature: 'continue',
      );
    }
    final tier = AiTier.document(quality);
    String task;
    String body;
    switch (action) {
      case 'explain':
        task =
            'Explain the selected passage in plain words: what it says and '
            'what it means in the context of the document. Be brief.';
        body =
            '<document_outline>$outline</document_outline>\n'
            '<context_before>${req.contextBefore ?? ''}</context_before>\n'
            '<selection>${req.selectedMarkdown ?? ''}</selection>\n'
            '<context_after>${req.contextAfter ?? ''}</context_after>';
      case 'summarize':
        task = 'Summarize the selected passage in a few sentences.';
        body = '<selection>${req.selectedMarkdown ?? ''}</selection>';
      case 'generateOutline':
        final prompt = (req.instruction ?? '').trim();
        final empty = ctx.markdown.trim().isEmpty;
        task = empty || prompt.isNotEmpty
            ? 'Create a document outline as a Markdown list of headings '
                  '(use "#", "##" and "###" headings, one per line, no body '
                  'text)${prompt.isEmpty ? '' : ' for: $prompt'}.'
            : 'Create an outline of this document as Markdown headings '
                  '("#", "##", "###"), one per line, no body text, following '
                  'its actual structure and content.';
        body = empty ? '' : _documentBody(ctx);
      default: // summarizeDocument
        final length = switch (req.summaryLength) {
          'short' => 'in two or three sentences',
          'detailed' =>
            'in detail: a short overview paragraph followed by the key '
                'points of each section as a bullet list',
          _ =>
            'in one paragraph followed by up to five key points as a '
                'bullet list',
        };
        task = 'Summarize the document $length.';
        body = _documentBody(ctx);
    }
    return AiRequest(
      model: model(tier),
      effort: tier.effort,
      maxTokens: 32000,
      system: WritePrompts.documentActions,
      messages: [user('${body.isEmpty ? '' : '$body\n'}<task>$task</task>')],
      userId: userId == null ? null : 'u$userId',
      feature: action == 'generateOutline'
          ? 'outline'
          : action == 'explain'
          ? 'explain'
          : 'summarize',
    );
  }

  static String _documentBody(WriteDocContext ctx) {
    var md = ctx.markdown;
    const limit = WriteContextBuilder.largeTokenLimit * 4;
    var note = '';
    if (md.length > limit) {
      md = md.substring(0, limit);
      note =
          '\n<note>The document was cut off here because it is very long.</note>';
    }
    return '<document title="${ctx.title}">\n$md\n</document>$note';
  }

  static String _lastWords(String text, int words) {
    final parts = text.split(RegExp(r'(?<=\s)'));
    if (parts.length <= words) return text;
    return '…${parts.sublist(parts.length - words).join()}';
  }

  /// Strips an accidental surrounding code fence and trailing whitespace.
  static String clean(String text, {bool keepLeadingSpace = false}) {
    var t = text.trimRight();
    final fence = RegExp(r'^\s*```[a-zA-Z]*\n([\s\S]*?)\n```\s*$');
    final m = fence.firstMatch(t);
    if (m != null) t = m.group(1)!;
    return keepLeadingSpace ? t : t.trimLeft();
  }
}
