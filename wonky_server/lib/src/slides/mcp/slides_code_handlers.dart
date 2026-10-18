import 'dart:convert';

import 'package:wonky_slides_core/code.dart' show CodeElementData;
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;

import '../../platform/mcp/tool_support.dart';
import 'slides_content.dart';
import 'slides_input.dart';
import 'slides_mcp_support.dart';
import 'slides_writes.dart';

/// MCP tools for code blocks in decks: add, highlight states and
/// update (Slides 11 §3).
abstract final class SlidesCodeHandlers {
  /// `CodeState` columns of an MCP code state.
  static Map<String, Object?> _stateColumns(
    Map<String, Object?> st,
    String pointer,
  ) {
    final callouts = st['callouts'];
    final arrive = st['arrive'];
    return {
      CodeStateCols.code: '${st['code'] ?? ''}'.replaceAll('\r\n', '\n'),
      if (st['label'] is String) SlidesCols.label: st['label'],
      if (st['title'] is String) SlidesCols.title: st['title'],
      if (st['language'] is String)
        CodeStateCols.language: SlidesContent.normalizeLanguage(
          st['language']! as String,
        ),
      if (st['highlight'] is String) CodeStateCols.highlight: st['highlight'],
      if (callouts is Map && callouts.isNotEmpty)
        CodeStateCols.annotationsJson: jsonEncode({
          'v': 1,
          'steps': {
            for (final e in callouts.entries)
              '${e.key}': e.value is Map ? e.value : {'text': '${e.value}'},
          },
        }),
      if (arrive is Map)
        SlidesCols.transitionJson: jsonEncode({
          'v': 1,
          ...SlidesInput.camel(arrive),
        }),
    };
  }

  static Map<String, Object?> _codeOptions(Map<String, Object?>? o) => {
    if (o != null) ...SlidesInput.camel(o),
  };

  /// The *Build all steps* builds of code element [id] (06 §10, 07 §6;
  /// the app's `BuildRecipes.allSteps` for code): a `codeState` emphasis
  /// per further state and a `codeHighlight` per highlight step, each on
  /// click.
  static List<BuildSpec> codeSteps(DeckModel m, String id) {
    final specs = <BuildSpec>[];
    for (final (i, s) in m.codeStatesOf(id).indexed) {
      if (i > 0) {
        specs.add(
          BuildEdits.spec(
            elementId: id,
            kind: SlideBuildKind.emphasis,
            effect: 'codeState',
            params: {'state': i + 1},
          ),
        );
      }
      for (var k = 1; k <= MotionCodeState.stepsOf(s.highlight); k++) {
        specs.add(
          BuildEdits.spec(
            elementId: id,
            kind: SlideBuildKind.emphasis,
            effect: 'codeHighlight',
            params: {'step': k},
          ),
        );
      }
    }
    return specs;
  }

  static Future<ToolResult> addCodeBlock(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final states = [
      for (final (i, x) in a.list('states')!.indexed)
        _stateColumns((x! as Map).cast<String, Object?>(), '/states/$i'),
    ];
    final language = a.requireString('language');
    final options = _codeOptions(a.object('options'));
    String? elementId;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.add_code_block',
      build: (s) {
        final m = s.model;
        final slideId = SlidesMcp.slideId(m, a.values['slide']);
        final frameArg = a.object('frame');
        final placement = a.object('placement');
        if (frameArg == null && placement == null) {
          // An empty code placeholder takes the code (07 §3.6).
          for (final e in SlidesMcp.placeholders(
            m,
            slideId,
            SlidePlaceholderType.code,
          )) {
            if (m.codeStatesOf(e.id).isNotEmpty) continue;
            elementId = e.id;
            s.run(
              SetElementData(
                e.id,
                jsonEncode(
                  CodeElementData.fromJson({
                    'v': 1,
                    ...options,
                    'language': SlidesContent.normalizeLanguage(language),
                  }).toJson(),
                ),
              ),
            );
            s.run(AddCodeStates(e.id, states));
            break;
          }
        }
        if (elementId == null) {
          final (sw, sh) = SlidesInput.slideSize(m);
          final w = (sw * 0.6).roundToDouble(), h = (sh * 0.5).roundToDouble();
          final f = SlidesInput.frame(
            m,
            frame: frameArg,
            placement: placement,
            fallback: SuRect(
              ((sw - w) / 2).roundToDouble(),
              ((sh - h) / 2).roundToDouble(),
              w,
              h,
            ),
            pointer: '/frame',
          );
          final plan = s.run(
            InsertElements(slideId, [
              SlidesContent.codeSpec(
                f,
                language: language,
                states: states,
                options: options,
              ),
            ]),
          );
          elementId = (plan.result['elementIds']! as List).single as String;
        }
        if (a.string('builds') == 'all_steps') {
          final specs = codeSteps(s.model, elementId!);
          if (specs.isNotEmpty) s.run(AddBuilds(slideId, specs));
        }
      },
    );
    return SlidesWrites.result(o, 'Added a ${language.trim()} code block', {
      'element_id': elementId,
    });
  }

  static Future<ToolResult> setCodeStates(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final states = [
      for (final (i, x) in a.list('states')!.indexed)
        _stateColumns((x! as Map).cast<String, Object?>(), '/states/$i'),
    ];
    final builds = a.string('builds') ?? 'keep';
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.set_code_states',
      force: a.boolean('force') ?? false,
      build: (s) {
        final m = s.model;
        final id = SlidesMcp.elementId(m, a.values['element']);
        final rec = SlidesMcp.elementOfKind(m, id, {
          ElementKind.code,
        }, 'a code block');
        final old = m.codeStatesOf(id);
        for (var i = 0; i < states.length && i < old.length; i++) {
          final cols = {...states[i]};
          for (final c in [
            SlidesCols.label,
            SlidesCols.title,
            CodeStateCols.language,
            CodeStateCols.highlight,
            CodeStateCols.annotationsJson,
            SlidesCols.transitionJson,
          ]) {
            cols.putIfAbsent(c, () => null);
          }
          s.run(UpdateCodeState(old[i].id, cols));
        }
        if (states.length > old.length) {
          s.run(
            AddCodeStates(
              id,
              states.sublist(old.length),
              afterStateId: old.isEmpty ? null : old.last.id,
            ),
          );
        } else if (old.length > states.length) {
          s.run(
            DeleteCodeStates([
              for (final st in old.sublist(states.length)) st.id,
            ]),
          );
        }
        final slideId = rec.slideId;
        if (slideId != null && builds != 'keep') {
          final mine = [
            for (final b in s.model.buildsOf(slideId))
              if (b.elementId == id) b.id,
          ];
          if (mine.isNotEmpty) s.run(DeleteBuilds(mine));
          if (builds == 'all_steps') {
            final specs = codeSteps(s.model, id);
            if (specs.isNotEmpty) s.run(AddBuilds(slideId, specs));
          }
        }
      },
    );
    return SlidesWrites.result(
      o,
      'Set ${states.length} code state${states.length == 1 ? '' : 's'}',
    );
  }

  static Future<ToolResult> updateCodeBlock(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.update_code_block',
      build: (s) {
        final m = s.model;
        final id = SlidesMcp.elementId(m, a.values['element']);
        final rec = SlidesMcp.elementOfKind(m, id, {
          ElementKind.code,
        }, 'a code block');
        Map<String, Object?> current = {};
        try {
          final d = jsonDecode(rec.dataJson ?? '{}');
          if (d is Map) current = d.cast<String, Object?>();
        } on FormatException {
          current = {};
        }
        final next = {
          ...current,
          'v': 1,
          ..._codeOptions(a.object('options')),
          if (a.string('language') case final String l)
            'language': SlidesContent.normalizeLanguage(l),
        };
        s.run(
          SetElementData(
            id,
            jsonEncode(CodeElementData.fromJson(next).toJson()),
          ),
        );
      },
    );
    return SlidesWrites.result(o, 'Updated the code block');
  }
}
