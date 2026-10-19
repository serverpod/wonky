import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart' show DataPart, StandardPart;
import 'package:image/image.dart' as img;
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope, Role;
import 'package:wonky_slides_core/ai.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_revlog/rows.dart' show RowChange, composeRowChanges;

import '../../platform/ai/ai_call.dart';
import '../../platform/ai/ai_models.dart';
import '../../platform/ai/llm/ai_client.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/isolate_runner.dart';
import '../../platform/common/models.dart';
import '../../platform/files/file_service.dart';
import '../../platform/mcp/mcp_errors.dart';
import '../../platform/mcp/tool_executor.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/mcp/wonky_mcp_server.dart';
import '../mcp/slides_mcp_support.dart';
import '../mcp/slides_input.dart';
import '../mcp/slides_read_handlers.dart';
import '../revlog/slides_server_writes.dart';
import 'slides_context_builder.dart';
import 'slides_prompts.dart';
import 'slides_shadow.dart';

/// The inline AI features of Wonky Slides (Slides 11 §6.4–§6.8): generate
/// a presentation (outline, then a deterministic build), rewrite text,
/// speaker notes, alt text, design-idea ranking, and the AI changes preview
/// of Suggest-mode assistant runs (§6.3). Model calls run here with the
/// user's provider ([AiCall]); proposals are returned to the
/// app, which applies them as ordinary commands (one `slides.rows` undo
/// step), except building an outline and applying a preview, which write
/// on the server as one change (`slides.serverChange` undo step).
abstract final class SlidesAiService {
  /// Speaker notes are written for at most this many slides per request.
  static const notesBatch = 10;

  /// Most slides per *Write speaker notes* run.
  static const maxNotesSlides = 200;

  /// Most elements per alt-text request.
  static const maxAltElements = 50;

  /// Images are sent at most this large (11 §6.8).
  static const imageMaxSide = 1024;

  /// Overrides the tool executor (tests).
  static ToolExecutor? executorOverride;

  static ToolExecutor get _executor =>
      executorOverride ?? WonkyMcpServer.executor;

  // --------------------------------------------------------------- shared

  static ToolContext _ctx(Session session, Actor actor) => ToolContext(
    session: session,
    actor: actor.copyWith(kind: ActorKind.ai),
    scopes: {
      McpScope.slidesRead,
      McpScope.slidesEdit,
      McpScope.driveWrite,
      McpScope.sheetsRead,
    },
    clientName: 'Assistant',
  );

  static Future<(SlidesTarget, AiCall)> _open(
    Session session,
    Actor actor,
    UuidValue itemUuid, {
    Role min = Role.editor,
  }) async {
    final ai = await AiCall.open(session, actor);
    final t = await McpErrors.guard(
      () => SlidesMcp.openRef(_ctx(session, actor), itemUuid.uuid, min: min),
    );
    return (t, ai);
  }

  /// The input of the first call of [tool] in [r], or null.
  static Map<String, Object?>? toolInput(AiResponse r, String tool) {
    for (final call in r.toolCalls) {
      if (call.toolName == tool) return call.arguments ?? const {};
    }
    return null;
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  static String _wrap(String s) => SlidesContextBuilder.wrap(s);

  // ------------------------------------------------------- generate deck

  static const proposeOutlineTool = AiToolSpec(
    name: 'propose_outline',
    description:
        'Proposes the outline of the presentation. Call it exactly once.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
        'subtitle': {
          'type': ['string', 'null'],
        },
        'groups': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'title': {
                'type': ['string', 'null'],
              },
              'slides': {
                'type': 'array',
                'items': {
                  'type': 'object',
                  'properties': {
                    'title': {'type': 'string'},
                    'role': {
                      'type': 'string',
                      'enum': [
                        'title',
                        'section',
                        'agenda',
                        'bullets',
                        'twoColumn',
                        'quote',
                        'bigNumber',
                        'imageText',
                        'code',
                        'chartPlaceholder',
                        'closing',
                      ],
                    },
                    'bullets': {
                      'type': 'array',
                      'items': {
                        'anyOf': [
                          {'type': 'string'},
                          {
                            'type': 'object',
                            'properties': {
                              'text': {'type': 'string'},
                              'children': {
                                'type': 'array',
                                'items': {'type': 'string'},
                              },
                            },
                            'required': ['text', 'children'],
                            'additionalProperties': false,
                          },
                        ],
                      },
                    },
                    'notes': {
                      'type': ['string', 'null'],
                    },
                    'code': {
                      'anyOf': [
                        {'type': 'null'},
                        {
                          'type': 'object',
                          'properties': {
                            'language': {'type': 'string'},
                            'code': {'type': 'string'},
                          },
                          'required': ['language', 'code'],
                          'additionalProperties': false,
                        },
                      ],
                    },
                    'emphasis': {
                      'type': ['string', 'null'],
                    },
                  },
                  'required': [
                    'title',
                    'role',
                    'bullets',
                    'notes',
                    'code',
                    'emphasis',
                  ],
                  'additionalProperties': false,
                },
              },
            },
            'required': ['title', 'slides'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['title', 'subtitle', 'groups'],
      'additionalProperties': false,
    },
  );

  /// The user message of an outline request.
  static String outlineMessage(SlidesAiOutlineRequest r, {String? deck}) {
    final b = StringBuffer();
    final regenerate = r.slideIndex != null && r.outlineJson != null;
    if (regenerate) {
      b
        ..writeln(
          'Rewrite slide ${r.slideIndex! + 1} of the outline below. Answer '
          'with an outline that contains exactly that one slide (in one '
          'group); keep the title and subtitle.',
        )
        ..writeln(
          r.instruction?.trim().isNotEmpty == true
              ? 'Instruction: ${r.instruction!.trim()}'
              : 'Make it better.',
        )
        ..writeln('<source>')
        ..writeln(SlidesContextBuilder.escape(r.outlineJson!, tag: 'source'))
        ..writeln('</source>');
    } else {
      b.writeln(
        r.source == 'outline'
            ? 'Turn this outline into a presentation'
                  '${r.keepWording ? ', keeping the wording' : ''}:'
            : 'Plan a presentation about this:',
      );
      b
        ..writeln('<source>')
        ..writeln(SlidesContextBuilder.escape(r.text.trim(), tag: 'source'))
        ..writeln('</source>');
    }
    b.writeln(
      'Slides: ${r.slideCount == null ? 'as many as the content needs (usually 6–12)' : '${r.slideCount}'}',
    );
    if (r.audience?.trim().isNotEmpty == true) {
      b.writeln('Audience: ${r.audience!.trim()}');
    }
    if (r.tone?.trim().isNotEmpty == true) b.writeln('Tone: ${r.tone!.trim()}');
    b
      ..writeln(
        'Language: ${r.language?.trim().isNotEmpty == true ? r.language!.trim() : 'the language of the source'}',
      )
      ..writeln('Speaker notes: ${r.speakerNotes ? 'yes' : 'no (null)'}')
      ..writeln(
        'Sections: ${r.groups ? 'group related slides' : 'one group with a null title'}',
      );
    if (deck != null) {
      b
        ..writeln('The slides are added to this presentation:')
        ..writeln(_wrap(deck));
    }
    return b.toString();
  }

  /// Step 1 of *Generate presentation* (11 §6.4): streams progress text
  /// and ends with `done` whose `markdown` is the outline JSON
  /// ([AiOutline.encode]). [itemUuid] is the open deck (slides are inserted
  /// there) or null (a new presentation).
  static Future<Stream<InlineAiEvent>> proposeOutline(
    Session session,
    Actor actor,
    UuidValue? itemUuid,
    SlidesAiOutlineRequest request,
  ) async {
    final text = request.text.trim();
    if (text.isEmpty && request.outlineJson == null) {
      throw Errors.invalid('Describe the presentation first.');
    }
    if (text.length > 100000) throw Errors.tooLarge('The text is too long.');
    final ai = await AiCall.open(session, actor);
    String? deck;
    if (itemUuid != null) {
      final t = await McpErrors.guard(
        () => SlidesMcp.openRef(
          _ctx(session, actor),
          itemUuid.uuid,
          min: Role.editor,
        ),
      );
      deck = SlidesContextBuilder.build(t.model, title: t.item.name).summary;
    }
    final previous = AiOutline.tryDecode(request.outlineJson);
    final quality = await ai.quality(session);
    final tier = AiTier.document(quality);
    final aiRequest = AiRequest(
      model: ai.model(tier),
      effort: tier.effort,
      maxTokens: 32000,
      system: SlidesPrompts.outline,
      tools: const [proposeOutlineTool],
      messages: [ChatMessage.user(outlineMessage(request, deck: deck))],
      userId: 'u${actor.userId}',
      feature: 'slides_outline',
    );
    return _stream(session, ai, (s2, cancel, emit) async {
      final r = await ai.send(
        s2,
        aiRequest,
        cancel: cancel,
        onText: (d) => emit(
          InlineAiEvent(type: InlineAiEventType.textDelta, text: d),
        ),
      );
      final input = toolInput(r, proposeOutlineTool.name) ?? _jsonIn(r.text);
      if (input == null) {
        throw WonkyException(
          code: WonkyErrorCode.invalidArgument,
          message: 'The AI did not propose an outline. Try again.',
        );
      }
      var outline = AiOutline.fromJson(input);
      final index = request.slideIndex;
      if (previous != null && index != null) {
        final slides = previous.slides.toList();
        final replacement = outline.slides.firstOrNull;
        if (replacement != null && index >= 0 && index < slides.length) {
          final old = slides[index];
          for (final g in previous.groups) {
            final i = g.slides.indexOf(old);
            if (i >= 0) g.slides[i] = replacement;
          }
        }
        outline = previous;
      }
      if (outline.slideCount == 0) {
        throw WonkyException(
          code: WonkyErrorCode.invalidArgument,
          message: 'The AI proposed no slides. Try again.',
        );
      }
      return InlineAiEvent(
        type: InlineAiEventType.done,
        markdown: outline.encode(),
      );
    });
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

  /// Step 2 (11 §6.4): builds [outlineJson] deterministically — no model
  /// call — into a new presentation ([itemUuid] null; named after the
  /// outline, in [parentUuid]) or into the deck [itemUuid] after
  /// [afterSlideId] (default: at the end) as one server change (one undo
  /// step "AI: Generate slides").
  static Future<SlidesAiBuildResult> buildDeck(
    Session session,
    Actor actor, {
    UuidValue? itemUuid,
    required String outlineJson,
    String? afterSlideId,
    bool notes = true,
    bool groups = true,
    UuidValue? parentUuid,
    String? theme,
  }) async {
    final outline = AiOutline.tryDecode(outlineJson);
    if (outline == null || outline.slideCount == 0) {
      throw Errors.invalid('The outline has no slides.');
    }
    final ctx = _ctx(session, actor);
    final markdown = outline.toDeckMarkdown(
      AiOutlineBuildOptions(
        titleSlide: itemUuid == null,
        groups: groups,
        notes: notes,
      ),
    );
    Future<Map<String, Object?>> call(String tool, Map<String, Object?> a) =>
        McpErrors.guard(() async {
          final out = await _executor.call(ctx, tool, a);
          final err = out.error;
          if (err != null) throw err;
          final r = out.result!.structured;
          return r is Map ? r.cast<String, Object?>() : const {};
        });
    List<String> warnings(Map<String, Object?> r) => [
      for (final w in (r['warnings'] as List?) ?? const [])
        if (w is Map) '${w['message']}',
    ];
    if (itemUuid == null) {
      final name = outline.title.trim().isEmpty
          ? 'Untitled presentation'
          : _clip(outline.title.trim(), 200);
      final r = await call('drive.create_presentation', {
        'name': name,
        'outline_markdown': markdown,
        if (parentUuid != null) 'parent_uuid': parentUuid.uuid,
        'theme': ?theme,
      });
      return SlidesAiBuildResult(
        itemUuid: UuidValue.withValidation('${r['deck_uuid']}'),
        changeId: null,
        slideIds: [for (final id in (r['slide_ids'] as List?) ?? []) '$id'],
        warnings: warnings(r),
      );
    }
    final r = await call('slides.add_slides_from_markdown', {
      'deck': itemUuid.uuid,
      'markdown': markdown,
      'at': afterSlideId == null ? {'end': true} : {'after': afterSlideId},
    });
    return SlidesAiBuildResult(
      itemUuid: itemUuid,
      changeId: r['change_id'] as String?,
      slideIds: [for (final id in (r['slide_ids'] as List?) ?? []) '$id'],
      warnings: warnings(r),
    );
  }

  // ------------------------------------------------------------ rewrite

  static String _task(SlidesAiRewriteRequest r) => switch (r.mode) {
    'shorter' => 'Make it shorter.',
    'longer' => 'Make it longer and more complete.',
    'clearer' => 'Make it clearer and simpler.',
    'formal' => 'Make it more formal.',
    'grammar' => 'Fix spelling and grammar; change nothing else.',
    'punchier' => 'Make it punchier.',
    'bullets' => 'Turn it into a bullet list.',
    'paragraph' => 'Turn it into one short paragraph.',
    'translate' => 'Translate it into ${r.language ?? 'English'}.',
    _ =>
      r.instruction?.trim().isNotEmpty == true
          ? r.instruction!.trim()
          : 'Improve it.',
  };

  /// The user message of a rewrite.
  static String rewriteMessage(SlidesAiRewriteRequest r) {
    final b = StringBuffer('Task: ${_task(r)}\n');
    if (r.mode != 'custom' && r.instruction?.trim().isNotEmpty == true) {
      b.writeln('Also: ${r.instruction!.trim()}');
    }
    if (r.capacityChars != null && r.capacityChars! > 0) {
      final cap = r.mode == 'shorter'
          ? (r.capacityChars! * 0.9).floor()
          : r.capacityChars!;
      b.writeln('Capacity: at most $cap characters.');
    }
    if (r.role != null) b.writeln('The text is the slide\'s ${r.role}.');
    if (r.slideTitle?.trim().isNotEmpty == true) {
      b.writeln('Slide title: ${_clip(r.slideTitle!.trim(), 200)}');
    }
    b.writeln(_wrap(r.markdown));
    if (r.previous?.trim().isNotEmpty == true) {
      b
        ..writeln('Your previous version, to refine:')
        ..writeln(_wrap(r.previous!.trim()));
    }
    return b.toString();
  }

  /// The model's answer cleaned: no code fences or wrapping quotes.
  static String cleanMarkdown(String text) {
    var t = text.trim();
    final fence = RegExp(r'^```[a-zA-Z]*\n([\s\S]*?)\n```$').firstMatch(t);
    if (fence != null) t = fence.group(1)!.trim();
    if (t.length > 1 &&
        ((t.startsWith('"') && t.endsWith('"')) ||
            (t.startsWith('“') && t.endsWith('”')))) {
      t = t.substring(1, t.length - 1).trim();
    }
    return t
        .replaceAll(RegExp(r'</?deck_content>', caseSensitive: false), '')
        .trim();
  }

  /// *Rewrite text* (11 §6.5): streams the rewritten Markdown; `done`
  /// carries the cleaned result. Nothing is written (the app replaces the
  /// text with `slides.ai.previewReplace`).
  static Future<Stream<InlineAiEvent>> rewrite(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    SlidesAiRewriteRequest request,
  ) async {
    if (request.markdown.trim().isEmpty) {
      throw Errors.invalid('The text is empty.');
    }
    if (request.markdown.length > 20000) {
      throw Errors.tooLarge('The text is too long.');
    }
    final (_, ai) = await _open(session, actor, itemUuid);
    final quality = await ai.quality(session);
    final tier = AiTier.rewrite(quality);
    final aiRequest = AiRequest(
      model: ai.model(tier),
      effort: tier.effort,
      maxTokens: 8000,
      system: SlidesPrompts.rewrite,
      messages: [ChatMessage.user(rewriteMessage(request))],
      userId: 'u${actor.userId}',
      feature: 'slides_rewrite',
    );
    return _stream(session, ai, (s2, cancel, emit) async {
      final r = await ai.send(
        s2,
        aiRequest,
        cancel: cancel,
        onText: (d) => emit(
          InlineAiEvent(type: InlineAiEventType.textDelta, text: d),
        ),
      );
      final out = cleanMarkdown(r.text);
      if (out.isEmpty) {
        throw WonkyException(
          code: WonkyErrorCode.invalidArgument,
          message: 'The AI returned no text. Try again.',
        );
      }
      return InlineAiEvent(type: InlineAiEventType.done, markdown: out);
    });
  }

  /// Runs [body] as an [AiCall.stream] run and emits the event it returns;
  /// errors become `error` / `refusal` events.
  static Stream<InlineAiEvent> _stream(
    Session session,
    AiCall ai,
    Future<InlineAiEvent> Function(
      Session s,
      AiCancelToken cancel,
      void Function(InlineAiEvent) emit,
    )
    body,
  ) => ai.stream(
    session,
    (s, cancel, emit) async => emit(await body(s, cancel, emit)),
    onFailure: (f) => f.inlineEvent,
  );

  // ------------------------------------------------------ speaker notes

  static const writeNotesTool = AiToolSpec(
    name: 'write_notes',
    description:
        'Returns the speaker notes of every slide given. Call it exactly '
        'once.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'notes': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'slide_id': {'type': 'string'},
              'markdown': {'type': 'string'},
            },
            'required': ['slide_id', 'markdown'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['notes'],
      'additionalProperties': false,
    },
  );

  /// The user message of one notes batch.
  static String notesMessage(
    DeckModel m,
    String summary,
    List<String> slideIds, {
    required String length,
    required String style,
  }) {
    final b = StringBuffer()
      ..writeln('Length: $length. Style: $style.')
      ..writeln('The presentation:')
      ..writeln(_wrap(summary))
      ..writeln('Write notes for these slides:');
    for (final id in slideIds) {
      final s = m.slide(id)!;
      final pos = m.slides.indexWhere((x) => x.id == id) + 1;
      final content = StringBuffer()
        ..writeln('Slide $pos (slide_id $id)')
        ..writeln('Title: ${SlidesReadHandlers.slideTitle(m, id)}')
        ..writeln(
          'Content: ${_clip(SlidesContextBuilder.slideText(m, id), 1500)}',
        );
      if (!SlidesText.isBlank(s.notes)) {
        content.writeln(
          'Existing notes: ${_clip(SlidesText.plainText(s.notes).trim(), 1500)}',
        );
      }
      b.writeln(_wrap(content.toString().trim()));
    }
    return b.toString();
  }

  /// *Write speaker notes* (11 §6.7): proposals for [slideIds] (batches of
  /// [notesBatch]); [mode] `fillEmpty` skips slides that have notes.
  /// Nothing is written (the app applies the checked notes as one step).
  static Future<List<SlidesAiNote>> writeNotes(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    List<String> slideIds, {
    String length = 'standard',
    String style = 'script',
    String mode = 'fillEmpty',
  }) async {
    final (t, ai) = await _open(session, actor, itemUuid);
    final m = t.model;
    final ids = <String>[
      for (final id
          in slideIds.isEmpty ? [for (final s in m.slides) s.id] : slideIds)
        if (m.slide(id) case final s?)
          if (mode != 'fillEmpty' || SlidesText.isBlank(s.notes)) id,
    ].take(maxNotesSlides).toList();
    if (ids.isEmpty) return const [];
    final summary = SlidesContextBuilder.build(m, title: t.item.name).summary;
    final quality = await ai.quality(session);
    final tier = AiTier.document(quality);
    final out = <SlidesAiNote>[];
    for (var i = 0; i < ids.length; i += notesBatch) {
      final batch = ids.sublist(
        i,
        i + notesBatch > ids.length ? ids.length : i + notesBatch,
      );
      await ai.requireBudget(session);
      final r = await ai.send(
        session,
        AiRequest(
          model: ai.model(tier),
          effort: tier.effort,
          maxTokens: 16000,
          system: SlidesPrompts.notes,
          tools: const [writeNotesTool],
          messages: [
            ChatMessage.user(
              notesMessage(m, summary, batch, length: length, style: style),
            ),
          ],
          userId: 'u${actor.userId}',
          feature: 'slides_notes',
        ),
      );
      final input = toolInput(r, writeNotesTool.name);
      for (final n in (input?['notes'] as List?) ?? const []) {
        if (n is! Map) continue;
        final id = '${n['slide_id']}';
        final md = '${n['markdown'] ?? ''}'.trim();
        // Only the slides asked for (the model can't address others).
        if (!batch.contains(id) || md.isEmpty) continue;
        if (out.any((x) => x.slideId == id)) continue;
        final s = m.slide(id)!;
        out.add(
          SlidesAiNote(
            slideId: id,
            markdown: _clip(md, 20000),
            existing: SlidesText.isBlank(s.notes)
                ? null
                : SlidesInput.markdown(m, s.notes),
          ),
        );
      }
    }
    return out;
  }

  // ------------------------------------------------------------ alt text

  static const describeTool = AiToolSpec(
    name: 'describe',
    description:
        'Returns the alt text of every object given. Call it exactly once.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'descriptions': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'element_id': {'type': 'string'},
              'alt_text': {'type': 'string'},
            },
            'required': ['element_id', 'alt_text'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['descriptions'],
      'additionalProperties': false,
    },
  );

  static const _describable = {
    ElementKind.image,
    ElementKind.chart,
    ElementKind.icon,
    ElementKind.code,
    ElementKind.shape,
    ElementKind.table,
  };

  /// The elements *Generate missing alt text* describes: images, charts,
  /// icons and code without alt text that aren't decorative.
  static List<SlideElementRec> missingAltText(DeckModel m) => [
    for (final s in m.slides)
      for (final e in m.allElementsOf(s.id))
        if (const {
              ElementKind.image,
              ElementKind.chart,
              ElementKind.icon,
              ElementKind.code,
            }.contains(e.kind) &&
            !e.decorative &&
            (e.altText ?? '').trim().isEmpty)
          e,
  ];

  /// *Alt text ▸ Generate* (11 §6.8): proposals for [elementIds] (empty:
  /// every element missing alt text). Images are sent downscaled to
  /// [imageMaxSide] px. Nothing is written (the app accepts them).
  static Future<List<SlidesAiAltText>> describeElements(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    List<String> elementIds,
  ) async {
    final (t, ai) = await _open(session, actor, itemUuid);
    final m = t.model;
    final elements = elementIds.isEmpty
        ? missingAltText(m)
        : [
            for (final id in elementIds) ?m.element(id),
          ];
    final out = <SlidesAiAltText>[];
    final asked = <SlideElementRec>[];
    final parts = <StandardPart>[
      TextPart(
        'Describe these objects (language: the presentation\'s; presentation '
        '"${_clip(t.item.name, 120)}").',
      ),
    ];
    for (final e in elements.take(maxAltElements)) {
      final slideId = e.slideId;
      if (!_describable.contains(e.kind)) {
        out.add(
          SlidesAiAltText(
            elementId: e.id,
            slideId: slideId,
            kind: e.kind.name,
            skipped: 'unsupported',
          ),
        );
        continue;
      }
      final info = StringBuffer()
        ..writeln('element_id ${e.id}: ${e.kind.name}')
        ..writeln(
          'Slide: ${slideId == null ? '' : SlidesReadHandlers.slideTitle(m, slideId)}',
        );
      if (e.name != null) info.writeln('Name: ${_clip(e.name!, 200)}');
      final text = SlidesText.plainText(e.text).trim();
      if (text.isNotEmpty) info.writeln('Text: ${_clip(text, 500)}');
      if (e.kind != ElementKind.image) {
        final data = SlidesReadHandlers.dataJson(m, e, full: true);
        if (data != null) {
          info.writeln('Data: ${_clip(jsonEncode(data), 4000)}');
        }
      }
      parts.add(TextPart(_wrap(info.toString().trim())));
      if (e.kind == ElementKind.image) {
        final image = await _imageOf(session, actor, e);
        if (image != null) parts.add(image);
      }
      asked.add(e);
    }
    if (asked.isEmpty) return out;
    final quality = await ai.quality(session);
    final tier = AiTier.document(quality);
    final r = await ai.send(
      session,
      AiRequest(
        model: ai.model(tier),
        effort: tier.effort,
        maxTokens: 8000,
        system: SlidesPrompts.altText,
        tools: const [describeTool],
        messages: [ChatMessage(role: ChatMessageRole.user, parts: parts)],
        userId: 'u${actor.userId}',
        feature: 'slides_alt_text',
      ),
    );
    final byId = <String, String>{};
    for (final d
        in (toolInput(r, describeTool.name)?['descriptions'] as List?) ??
            const []) {
      if (d is Map) {
        byId['${d['element_id']}'] = _clip(
          '${d['alt_text'] ?? ''}'.trim(),
          2000,
        );
      }
    }
    for (final e in asked) {
      final alt = byId[e.id];
      out.add(
        SlidesAiAltText(
          elementId: e.id,
          slideId: e.slideId,
          kind: e.kind.name,
          altText: alt == null || alt.isEmpty ? null : alt,
          skipped: alt == null || alt.isEmpty ? 'empty' : null,
        ),
      );
    }
    return out;
  }

  /// The image of [e] as a JPEG ≤ [imageMaxSide] px (null when unreadable).
  static Future<DataPart?> _imageOf(
    Session session,
    Actor actor,
    SlideElementRec e,
  ) async {
    try {
      final d = jsonDecode(e.dataJson ?? '{}');
      final src = d is Map ? d['src'] : null;
      if (src is! String || !src.startsWith('wonky-file://')) return null;
      final file = await FileService.byUuid(
        session,
        UuidValue.withValidation(src.substring('wonky-file://'.length)),
      );
      if (file == null || !await FileService.canRead(session, actor, file)) {
        return null;
      }
      final data = await FileService.readBytes(session, file);
      final bytes = Uint8List.view(
        data.buffer,
        data.offsetInBytes,
        data.lengthInBytes,
      );
      if (!imageWithinLimit(bytes)) return null;
      // Off the request isolate (a large image takes a while to decode).
      final jpeg = await _aiJpegInIsolate(bytes);
      return jpeg == null ? null : DataPart(jpeg, mimeType: 'image/jpeg');
    } on Object {
      return null;
    }
  }

  /// Images with more pixels than this are not decoded for the AI (a
  /// small compressed file can expand to gigabytes).
  static const imageMaxPixels = 40 * 1000 * 1000;

  /// Whether [bytes] is an image whose header declares at most
  /// [imageMaxPixels] (read from the header, without decoding).
  static bool imageWithinLimit(Uint8List bytes) {
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null) return false;
    final info = decoder.startDecode(bytes);
    if (info == null || info.width <= 0 || info.height <= 0) return false;
    return info.width * info.height <= imageMaxPixels;
  }

  /// [aiJpeg] in a new isolate (the closure captures only [bytes]).
  static Future<Uint8List?> _aiJpegInIsolate(Uint8List bytes) =>
      IsolateRunner.run(
        () => aiJpeg(bytes),
        name: 'slides-ai-image',
        timeout: const Duration(seconds: 20),
      );

  /// [bytes] as a JPEG ≤ [imageMaxSide] px, or null when it is not an
  /// image within [imageMaxPixels]. Synchronous (run in an isolate).
  static Uint8List? aiJpeg(Uint8List bytes) {
    if (!imageWithinLimit(bytes)) return null;
    final decoder = img.findDecoderForData(bytes);
    var image = decoder?.decode(bytes, frame: 0);
    if (image == null) return null;
    final side = image.width > image.height ? image.width : image.height;
    if (side > imageMaxSide) {
      image = image.width >= image.height
          ? img.copyResize(image, width: imageMaxSide)
          : img.copyResize(image, height: imageMaxSide);
    }
    return img.encodeJpg(image, quality: 85);
  }

  // ------------------------------------------------------- design ideas

  static const rankDesignsTool = AiToolSpec(
    name: 'rank_designs',
    description: 'Ranks every candidate. Call it exactly once.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'ranking': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'candidate_id': {'type': 'string'},
              'score': {'type': 'number'},
              'reason': {'type': 'string'},
            },
            'required': ['candidate_id', 'score', 'reason'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['ranking'],
      'additionalProperties': false,
    },
  );

  /// The fast tier of the ranking (11 §6.1).
  static const rankTier = AiTier(AiModelSize.small, AiEffort.low);

  /// *Design ideas* ranking (11 §6.6): scores for [candidates] (`id:
  /// description` lines from the app's deterministic candidates) of slide
  /// [slideId]. Unknown ids are dropped; the app keeps its own order for
  /// candidates without a score.
  static Future<List<SlidesAiDesignRank>> rankDesigns(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String slideId,
    List<String> candidates,
  ) async {
    final (t, ai) = await _open(
      session,
      actor,
      itemUuid,
      min: Role.viewer,
    );
    final m = t.model;
    if (m.slide(slideId) == null) throw Errors.notFound('Slide');
    final ids = <String>{};
    final lines = <String>[];
    for (final c in candidates.take(40)) {
      final i = c.indexOf(':');
      if (i <= 0) continue;
      ids.add(c.substring(0, i).trim());
      lines.add(_clip(c, 300));
    }
    if (ids.isEmpty) return const [];
    final r = await ai.send(
      session,
      AiRequest(
        model: ai.model(rankTier),
        effort: rankTier.effort,
        maxTokens: 4000,
        system: SlidesPrompts.rankDesigns,
        tools: const [rankDesignsTool],
        messages: [
          ChatMessage.user(
            'The slide:\n${SlidesContextBuilder.currentSlide(m, slideId)}\n'
            'Candidates:\n${lines.join('\n')}',
          ),
        ],
        userId: 'u${actor.userId}',
        feature: 'slides_design_rank',
      ),
    );
    final out = <SlidesAiDesignRank>[];
    for (final x
        in (toolInput(r, rankDesignsTool.name)?['ranking'] as List?) ??
            const []) {
      if (x is! Map) continue;
      final id = '${x['candidate_id']}';
      if (!ids.contains(id) || out.any((o) => o.candidateId == id)) continue;
      final score = (x['score'] as num?)?.toDouble() ?? 0;
      out.add(
        SlidesAiDesignRank(
          candidateId: id,
          score: score.clamp(0, 1).toDouble(),
          reason: _clip('${x['reason'] ?? ''}'.trim(), 200),
        ),
      );
    }
    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  // ------------------------------------------------------------ previews

  static Future<StoredSlidesPreview> _preview(
    Session session,
    Actor actor,
    String previewId,
  ) async {
    final p = await SlidesAiPreviewStore.load(session, previewId);
    if (p == null || p.userId != actor.userId) {
      throw WonkyException(
        code: WonkyErrorCode.expired,
        message: 'These suggestions have expired. Ask the assistant again.',
      );
    }
    return p;
  }

  /// The AI changes preview [previewId] with each call's row changes.
  static Future<SlidesAiPreview> getPreview(
    Session session,
    Actor actor,
    String previewId,
  ) async {
    final p = await _preview(session, actor, previewId);
    return p.preview.copyWith(
      calls: [
        for (final c in p.preview.calls)
          c.copyWith(
            changesJson: jsonEncode([
              for (final x in p.changes[c.callId] ?? const <RowChange>[])
                x.toJson(),
            ]),
          ),
      ],
    );
  }

  /// *Apply selected* (11 §6.3): writes the checked calls ([callIds]; null =
  /// all) as one change, re-validated against the current deck with the
  /// per-column skip rule (values others changed since are kept).
  static Future<SlidesAiApplyResult> applyPreview(
    Session session,
    Actor actor,
    String previewId,
    List<String>? callIds,
  ) async {
    final p = await _preview(session, actor, previewId);
    final item = await DriveItem.db.findFirstRow(
      session,
      where: (t) =>
          t.contentRef.equals(p.space) &
          t.kind.equals(DriveItemKind.presentation),
    );
    if (item == null) throw Errors.notFound('Presentation');
    await McpErrors.guard(
      () => SlidesMcp.openRef(
        _ctx(session, actor),
        item.uuid.uuid,
        min: Role.editor,
      ),
    );
    final selected = [
      for (final c in p.preview.calls)
        if (callIds == null || callIds.contains(c.callId)) c,
    ];
    final label = selected.length == 1
        ? 'AI: ${selected.single.label}'
        : 'AI: Apply ${selected.length} suggestions';
    if (selected.isEmpty) {
      await SlidesAiPreviewStore.delete(session, previewId);
      return SlidesAiApplyResult(label: label, appliedCalls: 0, skipped: 0);
    }
    final changes = composeRowChanges([
      for (final c in selected) ...?p.changes[c.callId],
    ]);
    final write = await SlidesServerWrites.withWriteLock(
      p.space,
      () => SlidesServerWrites.applyRecorded(
        session,
        actor: actor.copyWith(kind: ActorKind.ai),
        item: item,
        changes: changes,
        label: label,
        skipChanged: true,
      ),
    );
    await SlidesAiPreviewStore.delete(session, previewId);
    return SlidesAiApplyResult(
      changeId: write.changeId?.uuid,
      label: label,
      appliedCalls: selected.length,
      skipped: write.result.skipped.length,
    );
  }

  /// *Discard*.
  static Future<void> discardPreview(
    Session session,
    Actor actor,
    String previewId,
  ) async {
    final p = await SlidesAiPreviewStore.load(session, previewId);
    if (p == null || p.userId != actor.userId) return;
    await SlidesAiPreviewStore.delete(session, previewId);
  }
}
