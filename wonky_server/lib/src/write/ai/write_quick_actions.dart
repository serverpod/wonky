import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/ai/ai_models.dart';
import '../../platform/ai/llm/ai_client.dart';
import '../../platform/ai/style_guide_service.dart';
import '../../platform/ai/untrusted_text.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/tool_executor.dart';
import '../../platform/mcp/tool_support.dart';
import '../mcp/headless_editor.dart';
import 'proofread_service.dart';
import 'write_context_builder.dart';
import 'write_prompts.dart';

/// One change a quick action applies (as a suggestion) through the
/// assistant's tool path.
class QuickEdit {
  const QuickEdit(this.toolName, this.args, {this.threadUuid, this.label});

  /// The API tool name (`write_replace_text`, `write_replace_range`,
  /// `comments_reply`).
  final String toolName;
  final Map<String, Object?> args;

  /// Address comments: the comment thread the edit is for.
  final String? threadUuid;

  /// Shown in the result list ("“teh” → “the”").
  final String? label;
}

/// What a quick action gets from the assistant run it is part of.
class QuickActionContext {
  QuickActionContext({
    required this.session,
    required this.actor,
    required this.target,
    required this.executor,
    required this.model,
    required this.send,
    required this.apply,
    required this.progress,
    required this.text,
    required this.isCancelled,
    this.userId,
  });

  final Session session;
  final Actor actor;
  final WriteTarget target;
  final ToolExecutor executor;

  /// The provider's model id of a tier.
  final String Function(AiTier tier) model;

  /// One model turn (usage recorded; provider errors throw).
  final Future<AiResponse> Function(
    AiRequest request, {
    void Function(String delta)? onText,
  })
  send;

  /// Applies [edit] as a suggestion (a tool chip in the panel); true when
  /// it succeeded.
  final Future<bool> Function(QuickEdit edit) apply;

  /// A progress note ("Proofreading 2 of 3 sections…").
  final void Function(String note) progress;

  /// Streams answer text to the panel.
  final void Function(String delta) text;

  final bool Function() isCancelled;
  final int? userId;
}

/// The Write assistant's quick actions (Write 09 §5.5): Summarize,
/// Proofread, Address comments and Apply style. None of them is a chat
/// turn with the agent loop: each makes **one** model round trip (per
/// document section, sections in parallel) on the fast model with low
/// effort, with the document in the request, and the server applies the
/// returned edits as suggestions. Their prompt is not shown in the chat;
/// the panel shows a working indicator, then the result.
abstract final class WriteQuickActions {
  /// The tier of every quick action: the fast model, low effort.
  static const tier = AiTier(AiModelSize.small, AiEffort.low);

  /// Sections of Apply style (a rewrite needs smaller sections than
  /// proofreading for complete answers).
  static const styleSectionWords = 2500;
  static const parallel = 4;

  /// The edit report tool of Proofread and Apply style.
  static const editsTool = 'report_edits';

  /// The tool of Address comments.
  static const commentsTool = 'report_comment_fixes';

  /// The instruction stored in the thread for [action] (the hidden user
  /// turn that keeps the conversation valid for later chat messages).
  static String historyMessage(AssistantQuickAction action) => switch (action) {
    AssistantQuickAction.summarize => 'Summarize the document.',
    AssistantQuickAction.proofread =>
      'Proofread the document and suggest small corrections.',
    AssistantQuickAction.addressComments =>
      'Address the open comments with suggestions.',
    AssistantQuickAction.applyStyle =>
      "Rewrite the document to follow its style guide, as suggestions.",
  };

  /// Runs [action]; returns the result text (also streamed with
  /// [QuickActionContext.text]).
  static Future<String> run(
    AssistantQuickAction action,
    QuickActionContext c,
  ) async {
    final ctx = await WriteContextBuilder.load(c.session, c.target);
    final style = await StyleGuideService.forDocument(
      c.session,
      c.actor.userId,
      c.target.item.id!,
    );
    return switch (action) {
      AssistantQuickAction.summarize => _summarize(c, ctx, style),
      AssistantQuickAction.proofread => _proofread(c, ctx, style),
      AssistantQuickAction.addressComments => _addressComments(c, ctx, style),
      AssistantQuickAction.applyStyle => _applyStyle(c, ctx, style),
    };
  }

  static String _say(QuickActionContext c, String text) {
    c.text(text);
    return text;
  }

  /// The style guide as context for a request (empty without one).
  static String styleContext(ResolvedStyleGuide? style) => style == null
      ? ''
      : '<style_guide name="${UntrustedText.attribute(style.name)}">\n'
            '${UntrustedText.escape(style.markdown, 'style_guide')}\n'
            '</style_guide>\n';

  static AiRequest _request(
    QuickActionContext c, {
    required String system,
    required String user,
    List<AiToolSpec> tools = const [],
    int maxTokens = 16000,
    String feature = 'quick',
  }) => AiRequest(
    model: c.model(tier),
    effort: tier.effort,
    maxTokens: maxTokens,
    system: system,
    tools: tools,
    messages: [ChatMessage.user(user)],
    userId: c.userId == null ? null : 'u${c.userId}',
    feature: feature,
  );

  /// The whole document (or, when large, the part the request can hold).
  static String _documentMarkdown(WriteDocContext ctx) {
    final md = ctx.markdown;
    const max = WriteContextBuilder.largeTokenLimit * 4;
    return md.length <= max ? md : '${md.substring(0, max)}\n…';
  }

  // -------------------------------------------------------------- summarize

  static Future<String> _summarize(
    QuickActionContext c,
    WriteDocContext ctx,
    ResolvedStyleGuide? style,
  ) async {
    if (ctx.markdown.trim().isEmpty) {
      return _say(c, 'The document is empty, so there is nothing to sum up.');
    }
    final out = StringBuffer();
    final r = await c.send(
      _request(
        c,
        system: WritePrompts.quickSummarize,
        maxTokens: 4000,
        feature: 'summarize',
        user:
            '${styleContext(style)}'
            '<document title="${UntrustedText.attribute(ctx.title)}">\n'
            '${UntrustedText.escape(_documentMarkdown(ctx), 'document')}\n'
            '</document>\n'
            'Summarize the document.',
      ),
      onText: (t) {
        out.write(t);
        c.text(t);
      },
    );
    return out.isEmpty ? _say(c, r.text) : out.toString();
  }

  // -------------------------------------------------------------- proofread

  static Future<String> _proofread(
    QuickActionContext c,
    WriteDocContext ctx,
    ResolvedStyleGuide? style,
  ) async {
    final sections = ProofreadService.split(ctx);
    if (sections.isEmpty) {
      return _say(c, 'The document is empty, so there is nothing to check.');
    }
    final issues = <ProofreadIssue>[];
    var done = 0;
    if (sections.length > 1) {
      c.progress('Proofreading 0 of ${sections.length} sections…');
    }
    await _eachParallel(sections, (s, i) async {
      final r = await c.send(
        _request(
          c,
          system: WritePrompts.quickProofread,
          tools: const [ProofreadService.tool],
          feature: 'proofread',
          user:
              '<section>\n${UntrustedText.escape(s.text, 'section')}\n'
              '</section>\nProofread the section and call report_issues once.',
        ),
      );
      issues.addAll(ProofreadService.validate(ctx, s, r, prefix: 's$i'));
      done++;
      if (sections.length > 1) {
        c.progress('Proofreading $done of ${sections.length} sections…');
      }
    }, isCancelled: c.isCancelled);
    // Small corrections only: drop rewrites the model reported anyway.
    final small = [
      for (final i in issues)
        if (_isSmall(i.quote, i.replacement)) i,
    ]..sort((a, b) => a.start.compareTo(b.start));
    if (small.isEmpty) {
      return _say(c, 'No spelling, grammar or punctuation problems found.');
    }
    final applied = <ProofreadIssue>[];
    // Back to front: an earlier suggestion never moves a later quote's
    // occurrence count.
    for (final i in small.reversed) {
      if (c.isCancelled()) break;
      final ok = await c.apply(
        QuickEdit(
          'write_replace_text',
          {
            'find': i.quote,
            'replace': i.replacement,
            'occurrence': i.occurrence,
            'match_case': true,
          },
          label: '“${i.quote}” → “${i.replacement}”',
        ),
      );
      if (ok) applied.add(i);
    }
    if (applied.isEmpty) {
      return _say(
        c,
        'I found ${small.length} possible corrections, but the text changed '
        'before I could suggest them. Try again.',
      );
    }
    final b = StringBuffer(
      'Suggested ${_count(applied.length, 'correction')}. Review them in '
      'the document to accept or reject each one.\n\n',
    );
    for (final i in applied.reversed.take(30)) {
      b.writeln(
        '- ~~${_inline(i.quote)}~~ → ${_inline(i.replacement)}'
        '${i.explanation.isEmpty ? '' : ' — ${_inline(i.explanation)}'}',
      );
    }
    if (applied.length > 30) b.writeln('- …and ${applied.length - 30} more');
    return _say(c, b.toString().trimRight());
  }

  /// A correction, not a rewrite: at most a few words changed.
  static bool _isSmall(String quote, String replacement) {
    if (quote.length > 160 || replacement.length > 200) return false;
    final a = quote.split(RegExp(r'\s+')).length;
    final b = replacement.split(RegExp(r'\s+')).length;
    return (a - b).abs() <= 3 && a <= 12;
  }

  // ------------------------------------------------------------ apply style

  static const _editsSpec = AiToolSpec(
    name: editsTool,
    description:
        'Reports the edits for the section. Call it exactly once, with an '
        'empty list when the section already follows the style guide.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'edits': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'quote': {
                'type': 'string',
                'description':
                    'The exact plain text (no Markdown markers) of the '
                    'passage to rewrite, copied from the section: a '
                    'sentence or a paragraph.',
              },
              'occurrence': {
                'type': 'integer',
                'description': '1-based occurrence of quote in the section.',
              },
              'replacement': {
                'type': 'string',
                'description':
                    'The rewritten passage as inline Markdown (keep bold, '
                    'italic, code and links).',
              },
              'reason': {
                'type': 'string',
                'description': 'The style rule, in a few words.',
              },
            },
            'required': ['quote', 'occurrence', 'replacement', 'reason'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['edits'],
      'additionalProperties': false,
    },
  );

  static Future<String> _applyStyle(
    QuickActionContext c,
    WriteDocContext ctx,
    ResolvedStyleGuide? style,
  ) async {
    if (style == null) {
      throw const QuickActionException(
        'no_style',
        'This document has no style guide yet. Choose one, then run Apply '
            'style again.',
      );
    }
    final sections = ProofreadService.split(ctx, limit: styleSectionWords);
    if (sections.isEmpty) {
      return _say(c, 'The document is empty, so there is nothing to restyle.');
    }
    final edits = <_LocatedEdit>[];
    var done = 0;
    c.progress('Applying “${style.name}”…');
    await _eachParallel(sections, (s, i) async {
      final markdown = _sectionMarkdown(ctx, s);
      final r = await c.send(
        _request(
          c,
          system: WritePrompts.quickApplyStyle,
          tools: const [_editsSpec],
          feature: 'apply_style',
          user:
              '${styleContext(style)}'
              '<section>\n${UntrustedText.escape(markdown, 'section')}\n'
              '</section>\n'
              'Rewrite the passages of the section that do not follow the '
              'style guide and call $editsTool once.',
        ),
      );
      edits.addAll(_locate(ctx, s, r, editsTool));
      done++;
      if (sections.length > 1) {
        c.progress(
          'Applying “${style.name}”: $done of ${sections.length} sections…',
        );
      }
    }, isCancelled: c.isCancelled);
    if (edits.isEmpty) {
      return _say(c, 'The document already follows “${style.name}”.');
    }
    final applied = await _applyEdits(c, edits);
    if (applied.isEmpty) {
      return _say(
        c,
        'The text changed before I could suggest the edits. Try again.',
      );
    }
    final b = StringBuffer(
      'Suggested ${_count(applied.length, 'edit')} to follow “${style.name}”. '
      'Review them in the document to accept or reject each one.\n\n',
    );
    final reasons = <String, int>{};
    for (final e in applied) {
      if (e.reason.isEmpty) continue;
      reasons[e.reason] = (reasons[e.reason] ?? 0) + 1;
    }
    for (final r in reasons.entries.take(8)) {
      b.writeln('- ${_inline(r.key)}${r.value > 1 ? ' (${r.value})' : ''}');
    }
    return _say(c, b.toString().trimRight());
  }

  // ------------------------------------------------------- address comments

  static const _commentsSpec = AiToolSpec(
    name: commentsTool,
    description:
        'Reports the fixes for the open comments. Call it exactly once; '
        'leave out comments you cannot address with an edit.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'fixes': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'thread_uuid': {'type': 'string'},
              'edits': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'quote': {
                      'type': 'string',
                      'description':
                          'The exact plain text (no Markdown markers) to '
                          'replace, copied from the document.',
                    },
                    'occurrence': {
                      'type': 'integer',
                      'description': '1-based occurrence in the document.',
                    },
                    'replacement': {
                      'type': 'string',
                      'description':
                          'The new text as inline Markdown ("" deletes).',
                    },
                  },
                  'required': ['quote', 'occurrence', 'replacement'],
                  'additionalProperties': false,
                },
              },
              'reply': {
                'type': 'string',
                'description':
                    'One short sentence for the comment thread saying what '
                    'the suggestion changes.',
              },
            },
            'required': ['thread_uuid', 'edits', 'reply'],
            'additionalProperties': false,
          },
        },
        'skipped': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'thread_uuid': {'type': 'string'},
              'reason': {'type': 'string'},
            },
            'required': ['thread_uuid', 'reason'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['fixes'],
      'additionalProperties': false,
    },
  );

  static Future<String> _addressComments(
    QuickActionContext c,
    WriteDocContext ctx,
    ResolvedStyleGuide? style,
  ) async {
    final out = await c.executor.call(
      ToolContext(
        session: c.session,
        actor: c.actor.copyWith(kind: ActorKind.ai),
        scopes: {McpScope.writeRead},
      ),
      'comments.list',
      {'uuid': c.target.item.uuid.uuid, 'status': 'open'},
    );
    final structured = out.result?.structured;
    final raw = structured is Map ? structured['threads'] : null;
    final threads = <Map<String, Object?>>[
      if (raw is List)
        for (final t in raw)
          // Suggestion discussions are not comments to address.
          if (t is Map && t['suggestion_id'] == null) t.cast<String, Object?>(),
    ];
    if (threads.isEmpty) {
      return _say(c, 'There are no open comments to address.');
    }
    final byUuid = {for (final t in threads) '${t['thread_uuid']}': t};
    final compact = [
      for (final t in threads)
        {
          'thread_uuid': t['thread_uuid'],
          'quoted_text': (t['anchor'] as Map?)?['quote'] ?? t['quoted_text'],
          'comments': [
            for (final m in (t['comments'] as List? ?? const []))
              if (m is Map) {'author': m['author'], 'body': m['body']},
          ],
        },
    ];
    final r = await c.send(
      _request(
        c,
        system: WritePrompts.quickAddressComments,
        tools: const [_commentsSpec],
        feature: 'address_comments',
        user:
            '${styleContext(style)}'
            '<document title="${UntrustedText.attribute(ctx.title)}">\n'
            '${UntrustedText.escape(_documentMarkdown(ctx), 'document')}\n'
            '</document>\n'
            '<open_comments>\n'
            '${UntrustedText.escape(jsonEncode(compact), 'open_comments')}\n'
            '</open_comments>\n'
            'Address the open comments and call $commentsTool once.',
      ),
    );
    final whole = ProofreadSection(0, ctx.doc.length, ctx.doc.text);
    final fixed = <String, (List<_LocatedEdit>, String)>{};
    final skipped = <String, String>{};
    for (final call in r.toolCalls) {
      if (call.toolName != commentsTool) continue;
      final fixes = call.arguments?['fixes'];
      if (fixes is List) {
        for (final f in fixes) {
          if (f is! Map) continue;
          final id = '${f['thread_uuid']}';
          if (!byUuid.containsKey(id)) continue;
          final located = _locateList(ctx, whole, f['edits']);
          if (located.isEmpty) continue;
          fixed[id] = (located, '${f['reply'] ?? ''}'.trim());
        }
      }
      final skips = call.arguments?['skipped'];
      if (skips is List) {
        for (final s in skips) {
          if (s is! Map) continue;
          final id = '${s['thread_uuid']}';
          if (byUuid.containsKey(id) && !fixed.containsKey(id)) {
            skipped[id] = '${s['reason'] ?? ''}'.trim();
          }
        }
      }
    }
    // Every comment the model did not fix is listed as needing the user.
    for (final id in byUuid.keys) {
      if (!fixed.containsKey(id)) skipped.putIfAbsent(id, () => '');
    }
    var addressed = 0;
    for (final e in fixed.entries) {
      if (c.isCancelled()) break;
      final applied = await _applyEdits(c, e.value.$1, threadUuid: e.key);
      if (applied.isEmpty) {
        skipped[e.key] = 'the text changed before the suggestion was made';
        continue;
      }
      addressed++;
      // A short reply on the thread points to the suggestion; the thread
      // stays open until the suggestion is accepted.
      final reply = e.value.$2.isEmpty
          ? 'Suggested a change for this comment.'
          : e.value.$2;
      await c.apply(
        QuickEdit(
          'comments_reply',
          {
            'thread_uuid': e.key,
            'body':
                '$reply\n\n_Suggested by the assistant: accept or reject the '
                'suggestion in the document._',
          },
          threadUuid: e.key,
        ),
      );
    }
    final b = StringBuffer();
    if (addressed == 0) {
      b.write(
        'I could not address any of the ${_count(threads.length, 'open comment')} '
        'with an edit.',
      );
    } else {
      b.write(
        'Suggested changes for $addressed of '
        '${_count(threads.length, 'open comment')} and replied in '
        '${addressed == 1 ? 'that thread' : 'those threads'} with what changed. '
        'The threads stay open until you accept the suggestions.',
      );
    }
    if (skipped.isNotEmpty) {
      b.write('\n\nNeeds your input:\n');
      for (final s in skipped.entries) {
        final t = byUuid[s.key]!;
        final first = (t['comments'] as List?)
            ?.whereType<Map<Object?, Object?>>()
            .firstOrNull;
        final who = first?['author'] ?? 'Someone';
        final body = _clip('${first?['body'] ?? ''}', 80);
        b.writeln(
          '- $who: “${_inline(body)}”'
          '${s.value.isEmpty ? '' : ' — ${_inline(s.value)}'}',
        );
      }
    }
    return _say(c, b.toString().trimRight());
  }

  // ---------------------------------------------------------------- helpers

  static String _sectionMarkdown(WriteDocContext ctx, ProofreadSection s) {
    final end = (s.start + s.length).clamp(0, ctx.doc.length);
    return DocumentReader.renderMarkdown(
      ctx.content.slice(s.start, end),
      SuggestionViewMode.accepted,
      flavor: ctx.flavor,
    );
  }

  static List<_LocatedEdit> _locate(
    WriteDocContext ctx,
    ProofreadSection section,
    AiResponse r,
    String tool,
  ) => [
    for (final call in r.toolCalls)
      if (call.toolName == tool)
        ..._locateList(ctx, section, call.arguments?['edits']),
  ];

  /// The model's edits located in the head: the quote's occurrence within
  /// [section] becomes the document-wide occurrence. Edits whose quote is
  /// not found, unchanged ones and overlapping ones are dropped.
  static List<_LocatedEdit> _locateList(
    WriteDocContext ctx,
    ProofreadSection section,
    Object? raw,
  ) {
    if (raw is! List) return const [];
    final resolver = AddressResolver.of(ctx.doc);
    final out = <_LocatedEdit>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final quote = e['quote'];
      final replacement = e['replacement'];
      if (quote is! String || quote.trim().isEmpty || replacement is! String) {
        continue;
      }
      if (quote.trim() == replacement.trim()) continue;
      final all = resolver.findQuote(quote);
      final inSection = [
        for (var i = 0; i < all.length; i++)
          if (all[i].start >= section.start &&
              all[i].start + quote.length <= section.start + section.length)
            i,
      ];
      if (inSection.isEmpty) continue;
      final occ = ((e['occurrence'] as num?)?.toInt() ?? 1) - 1;
      final pick = inSection[occ.clamp(0, inSection.length - 1)];
      final start = all[pick].start;
      if (out.any(
        (o) =>
            start < o.start + o.quote.length && o.start < start + quote.length,
      )) {
        continue;
      }
      out.add(
        _LocatedEdit(
          quote,
          pick + 1,
          start,
          replacement,
          '${e['reason'] ?? ''}'.trim(),
        ),
      );
    }
    return out;
  }

  /// Applies [edits] as suggestions, back to front; returns the applied
  /// ones.
  static Future<List<_LocatedEdit>> _applyEdits(
    QuickActionContext c,
    List<_LocatedEdit> edits, {
    String? threadUuid,
  }) async {
    final sorted = [...edits]..sort((a, b) => b.start.compareTo(a.start));
    final applied = <_LocatedEdit>[];
    for (final e in sorted) {
      if (c.isCancelled()) break;
      final ok = await c.apply(
        QuickEdit(
          'write_replace_range',
          {
            'range': {
              'type': 'quote',
              'quote': e.quote,
              'occurrence': e.occurrence,
            },
            'markdown': e.replacement,
          },
          threadUuid: threadUuid,
        ),
      );
      if (ok) applied.add(e);
    }
    return applied;
  }

  static Future<void> _eachParallel<T>(
    List<T> items,
    Future<void> Function(T item, int index) body, {
    required bool Function() isCancelled,
  }) async {
    var next = 0;
    Future<void> worker() async {
      while (next < items.length && !isCancelled()) {
        final i = next++;
        await body(items[i], i);
      }
    }

    await Future.wait([
      for (var w = 0; w < parallel && w < items.length; w++) worker(),
    ]);
  }

  static String _count(int n, String noun) => '$n $noun${n == 1 ? '' : 's'}';

  static String _clip(String s, int max) {
    final one = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return one.length <= max ? one : '${one.substring(0, max - 1)}…';
  }

  /// [s] on one line, safe inside the Markdown result list.
  static String _inline(String s) => _clip(
    s.replaceAllMapped(RegExp(r'[`*_~\[\]<>]'), (m) => '\\${m[0]}'),
    160,
  );
}

class _LocatedEdit {
  const _LocatedEdit(
    this.quote,
    this.occurrence,
    this.start,
    this.replacement,
    this.reason,
  );

  final String quote;
  final int occurrence;
  final int start;
  final String replacement;
  final String reason;
}

/// A quick action that cannot run (e.g. `no_style`: the document has no
/// style guide); shown in the panel with [code] for the app's follow-up.
class QuickActionException implements Exception {
  const QuickActionException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'QuickActionException($code: $message)';
}
