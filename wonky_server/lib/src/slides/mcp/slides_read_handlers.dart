import 'dart:convert';
import 'dart:io' show gzip;

import 'package:serverpod/serverpod.dart';
import 'package:wonky_slides_core/charts.dart' show ChartElementData;
import 'package:wonky_slides_core/find.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/schema.dart' show DeckThemeCols;
import 'package:wonky_slides_core/themes.dart';

import '../../platform/mcp/drive_tool_handlers.dart';
import '../../platform/mcp/tool_support.dart';
import '../revlog/slides_revlog.dart';
import 'slides_input.dart';
import 'slides_mcp_support.dart';

/// The read tools of Slides 11 §3.4.
abstract final class SlidesReadHandlers {
  /// Output cap (suite 09 §7).
  static const maxChars = 50000;

  static Map<String, Object?>? _json(String? s) {
    if (s == null) return null;
    try {
      final d = jsonDecode(s);
      return d is Map ? d.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }

  /// The browser URL of a presentation.
  static String urlOf(SlidesTarget t) => DriveToolHandlers.webBase
      .replace(path: '/slides/p/${t.item.uuid.uuid}')
      .toString();

  /// The deck's head revision (`sync_version`, RevLog spec 08 §7).
  static Future<String> syncVersion(Session session, SlidesTarget t) async =>
      '${await SlidesRevlog.headRevision(session, t.space)}';

  static String? _transitionType(String? json) {
    final t = _json(json)?['type'];
    return t is String ? t : null;
  }

  static Map<String, Object?> _layoutJson(DeckModel m, SlideLayoutRec? l) => {
    'layout_id': l?.id,
    'key': l?.key,
    'name': l?.name,
  };

  /// The title text of a slide (its title placeholder), plain.
  static String slideTitle(DeckModel m, String slideId) {
    for (final e in m.elementsOf(slideId)) {
      if (e.placeholderType == SlidePlaceholderType.title) {
        return SlidesText.plainText(e.text).trim().replaceAll('\n', ' ');
      }
    }
    return '';
  }

  // ------------------------------------------------------------ get_deck

  static Future<ToolResult> getDeck(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.open(ctx, a);
    final m = t.model;
    final include = {
      for (final x in a.list('include') ?? const ['groups', 'slides']) '$x',
    };
    final json = await deckJson(ctx, t, include: include, args: a);
    return ToolResult(
      json,
      text:
          'Presentation "${json['title']}": ${m.slides.length} slides'
          '${m.groups.isEmpty ? '' : ', ${m.groups.length} groups'}',
    );
  }

  /// The `slides.get_deck` result (also `wonky://deck/<uuid>/meta`).
  static Future<Map<String, Object?>> deckJson(
    ToolContext ctx,
    SlidesTarget t, {
    Set<String> include = const {'groups', 'slides'},
    ToolArgs args = const ToolArgs({}),
  }) async {
    final m = t.model;
    final d = m.deck;
    final theme = d?.themeId == null ? null : m.theme(d!.themeId!);
    final slides = m.slides;
    final out = <String, Object?>{
      'deck_uuid': t.item.uuid.uuid,
      'title': d?.title.isNotEmpty == true ? d!.title : t.item.name,
      'url': urlOf(t),
      'role': t.role.name,
      'size': {
        'width': d?.width ?? 1920,
        'height': d?.height ?? 1080,
        'preset': d?.sizePresetName,
      },
      'appearance': d?.appearance.name ?? 'light',
      'theme': {'theme_id': theme?.id, 'name': theme?.name},
      'sync_version': await syncVersion(ctx.session, t),
      'slide_count': slides.length,
    };
    if (include.contains('groups')) {
      out['groups'] = [
        for (final g in m.groups)
          {
            'group_id': g.id,
            'title': g.title,
            'color': g.color,
            'skipped': g.skipped,
            'slide_ids': [for (final s in m.slidesInGroup(g.id)) s.id],
          },
      ];
    }
    if (include.contains('slides')) {
      final start = int.tryParse(args.string('cursor') ?? '') ?? 0;
      final limit = args.integer('limit') ?? 1000;
      final list = <Map<String, Object?>>[];
      var size = jsonEncode(out).length;
      String? next;
      for (var i = start; i < slides.length; i++) {
        if (list.length >= limit) {
          next = '$i';
          break;
        }
        final s = slides[i];
        final layout = s.layoutId == null ? null : m.layout(s.layoutId!);
        final entry = <String, Object?>{
          'slide_id': s.id,
          'position': i + 1,
          'title': slideTitle(m, s.id),
          'layout': _layoutJson(m, layout),
          'group_id': s.groupId,
          'skipped': s.skipped,
          'element_count': m.allElementsOf(s.id).length,
          'build_count': m.buildsOf(s.id).length,
          'transition': _transitionType(s.transitionJson),
          'has_notes': !SlidesText.isBlank(s.notes),
          if (include.contains('notes_preview') && s.notes != null)
            'notes_preview': _preview(SlidesText.plainText(s.notes)),
          if (include.contains('timings') && s.timingsJson != null)
            'rehearsed_ms': _json(s.timingsJson)?['totalMs'],
        };
        size += jsonEncode(entry).length;
        if (size > maxChars && list.isNotEmpty) {
          next = '$i';
          break;
        }
        list.add(entry);
      }
      out['slides'] = list;
      if (next != null) {
        out['truncated'] = true;
        out['next_cursor'] = next;
      }
    }
    if (include.contains('themes')) {
      out['themes'] = [for (final th in m.themes) _themeJson(th)];
    }
    if (include.contains('layouts')) {
      out['layouts'] = layoutsJson(m, d?.themeId);
    }
    return out;
  }

  static String _preview(String s) {
    final t = s.trim().replaceAll('\n', ' ');
    return t.length <= 140 ? t : '${t.substring(0, 139)}…';
  }

  static Map<String, Object?> _themeJson(DeckThemeRec th) {
    final cols = th.themeColumns;
    return {
      'theme_id': th.id,
      'name': th.name,
      'source': th.sourceKey,
      'fonts': _json(cols[DeckThemeCols.fontsJson]),
      'colors': _json(cols[DeckThemeCols.colorsJson]),
    };
  }

  /// The layouts of [themeId] (default theme) with their placeholders.
  static List<Map<String, Object?>> layoutsJson(DeckModel m, String? themeId) {
    final theme = themeId ?? m.themes.firstOrNull?.id;
    if (theme == null) return const [];
    final out = <Map<String, Object?>>[];
    for (final master in m.mastersOf(theme)) {
      for (final l in m.layoutsOf(master.id)) {
        if (l.hidden) continue;
        final counts = <SlidePlaceholderType, int>{};
        final placeholders = [
          for (final e in m.elementsOf(l.id))
            if (e.placeholderType case final SlidePlaceholderType type)
              if (type.isInstantiated)
                {
                  'type': type.name,
                  'index': counts[type] = (counts[type] ?? 0) + 1,
                  'name': e.name,
                  'frame': _frame(e.frame),
                  'default_text': SlidesText.isBlank(e.text)
                      ? null
                      : SlidesText.plainText(e.text).trim(),
                },
        ];
        out.add({
          'layout_id': l.id,
          'key': l.key,
          'name': l.name,
          'master': master.name,
          'placeholders': placeholders,
        });
      }
    }
    return out;
  }

  static Map<String, Object?>? _frame(SuRect? f, [double rotation = 0]) =>
      f == null
      ? null
      : {
          'x': _r(f.x),
          'y': _r(f.y),
          'w': _r(f.width),
          'h': _r(f.height),
          if (rotation != 0) 'rotation': _r(rotation),
        };

  static num _r(double v) {
    final r = (v * 100).roundToDouble() / 100;
    return r == r.roundToDouble() ? r.round() : r;
  }

  // ----------------------------------------------------------- get_slide

  static Future<ToolResult> getSlide(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.open(ctx, a);
    final id = SlidesMcp.slideId(t.model, a.values['slide']);
    final include = {
      for (final x in a.list('include') ?? const ['elements', 'text', 'notes'])
        '$x',
    };
    final json = slideJson(
      t.model,
      id,
      include: include,
      format: a.string('text_format') ?? 'markdown',
    );
    return ToolResult(
      json,
      text:
          'Slide ${json['position']}: "${json['title']}" '
          '(${(json['elements'] as List?)?.length ?? 0} elements)',
    );
  }

  /// The `slides.get_slide` result.
  static Map<String, Object?> slideJson(
    DeckModel m,
    String slideId, {
    Set<String> include = const {'elements', 'text', 'notes'},
    String format = 'markdown',
  }) {
    final s = m.slide(slideId)!;
    final layout = s.layoutId == null ? null : m.layout(s.layoutId!);
    final resolver = SlideResolver(m);
    final rs = resolver.resolve(slideId);
    final overflow = rs == null ? const <String, (double, bool)>{} : fit(m, rs);
    final out = <String, Object?>{
      'slide_id': s.id,
      'position': SlidesMcp.positionOf(m, s.id),
      'title': slideTitle(m, s.id),
      'layout': _layoutJson(m, layout),
      'group_id': s.groupId,
      'skipped': s.skipped,
      'background': _json(s.backgroundJson),
      'hide_master_elements': s.hideMasterElements,
      'transition': SlidesInput.snake(_json(s.transitionJson)),
      if (include.contains('notes'))
        'notes_markdown': SlidesInput.markdown(m, s.notes),
    };
    if (include.contains('elements') && rs != null) {
      out['elements'] = [
        for (final e in rs.elements)
          elementJson(
            m,
            e,
            include: include,
            format: format,
            overflow: overflow,
          ),
      ];
    }
    if (include.contains('builds')) {
      out['builds'] = [for (final b in m.buildsOf(slideId)) buildJson(b)];
    }
    if (include.contains('timeline')) {
      out['timeline'] = timelineJson(m, slideId, resolved: rs);
    }
    return out;
  }

  /// Text fit per element: (scale, clipped) — the core layout with
  /// approximate metrics (the PDF export uses the TTF metrics).
  static Map<String, (double, bool)> fit(DeckModel m, ResolvedSlide rs) {
    final out = <String, (double, bool)>{};
    try {
      final scene = SlideSceneBuilder().build(
        rs,
        SceneContext(
          theme: rs.theme,
          textLayout: SlideTextLayout(),
          deck: m,
          purpose: ScenePurpose.present,
        ),
      );
      void walk(List<SceneNode> nodes) {
        for (final n in nodes) {
          switch (n) {
            case TextNode(:final layout, :final elementId?):
              if (layout.fitScale < 1 || layout.overflows) {
                out[elementId] = (layout.fitScale, layout.overflows);
              }
            case GroupNode(:final children):
              walk(children);
            default:
          }
        }
      }

      walk(scene.nodes);
    } on Object {
      // Fit is informational.
    }
    return out;
  }

  /// The overflow warnings of [slideIds] (11 §2.2 `text_overflow`).
  static List<Map<String, Object?>> overflowWarnings(
    DeckModel m,
    Iterable<String> slideIds,
  ) {
    final out = <Map<String, Object?>>[];
    final resolver = SlideResolver(m);
    for (final id in slideIds) {
      final rs = resolver.resolve(id);
      if (rs == null) continue;
      for (final MapEntry(key: e, value: (scale, clipped)) in fit(
        m,
        rs,
      ).entries) {
        out.add({
          'code': 'text_overflow',
          'message': clipped
              ? 'Text of slide ${SlidesMcp.positionOf(m, id)} overflows its box.'
              : 'Text of slide ${SlidesMcp.positionOf(m, id)} is shrunk to '
                    '${(scale * 100).round()} %.',
          'element_id': e,
        });
      }
    }
    return out;
  }

  /// One element of `get_slide` / `get_element`.
  static Map<String, Object?> elementJson(
    DeckModel m,
    ResolvedElement e, {
    Set<String> include = const {'text'},
    String format = 'markdown',
    Map<String, (double, bool)> overflow = const {},
    bool fullData = false,
  }) {
    final r = e.record;
    final hasText = switch (r.kind) {
      ElementKind.text || ElementKind.shape => true,
      _ => r.text != null,
    };
    final placeholder = e.placeholderType;
    int? index;
    if (placeholder != null && r.slideId != null) {
      final list = SlidesMcp.placeholders(m, r.slideId!, placeholder);
      final i = list.indexWhere((x) => x.id == r.id);
      if (i >= 0) index = i + 1;
    }
    final fit = overflow[r.id];
    return {
      'element_id': r.id,
      'kind': r.kind.name,
      'name': r.name ?? e.record.name,
      if (placeholder != null)
        'placeholder': {'type': placeholder.name, 'index': ?index},
      'frame': _frame(e.frame, e.rotation),
      'z': r.zKey,
      'locked': r.locked,
      'hidden': r.hidden,
      'match_key': r.matchKey,
      'alt_text': r.altText,
      if (r.decorative) 'decorative': true,
      if (hasText && (include.contains('text') || fullData))
        'text': SlidesInput.textOut(m, r.text, format),
      if (fit != null) 'overflow': {'shrunk_to': _r(fit.$1), 'clipped': fit.$2},
      if (include.contains('style') || fullData) 'style': _style(r),
      'data': dataJson(m, r, full: fullData || include.contains('data')),
      if (r.linkJson != null) 'link': _json(r.linkJson),
      if (e.children.isNotEmpty)
        'children': [
          for (final c in e.children)
            elementJson(
              m,
              c,
              include: include,
              format: format,
              overflow: overflow,
              fullData: fullData,
            ),
        ],
    };
  }

  static Map<String, Object?> _style(SlideElementRec r) => {
    'fill': _json(r.fillJson),
    'stroke': _json(r.strokeJson),
    'effects': _json(r.effectsJson),
    'opacity': r.opacity,
    'text_style': _json(r.textStyleJson),
  };

  /// The kind data of an element (summary, or [full]).
  static Map<String, Object?>? dataJson(
    DeckModel m,
    SlideElementRec r, {
    bool full = false,
  }) {
    final d = _json(r.dataJson);
    switch (r.kind) {
      case ElementKind.image:
        final src = d?['src'];
        return {
          'file_uuid': src is String && src.startsWith('wonky-file://')
              ? src.substring('wonky-file://'.length)
              : null,
          if (src is String && !src.startsWith('wonky-file://')) 'src': src,
          'crop': d?['crop'],
          'mask': d?['mask'],
          if (full) ...{
            'natural_width': d?['naturalWidth'],
            'natural_height': d?['naturalHeight'],
          },
        };
      case ElementKind.code:
        return {
          'language': d?['language'],
          'states': [
            for (final s in m.codeStatesOf(r.id))
              {
                'state_id': s.id,
                'label': s.label,
                'lines': '\n'.allMatches(s.code).length + 1,
                'highlight': s.highlight,
                if (s.language != null) 'language': s.language,
                if (full) 'code': s.code,
              },
          ],
          if (full) 'options': SlidesInput.snake(d),
        };
      case ElementKind.chart:
        final link = m.chartLinkOf(r.id);
        String? source;
        try {
          source = ChartElementData.fromJson(r.dataJson).source.name;
        } on Object {
          source = null;
        }
        Map<String, Object?>? spec;
        if (link != null) {
          try {
            spec = _json(
              ChartSnapshotText.decode(link.sourceSpecJson),
            );
          } on Object {
            spec = null;
          }
        }
        final title = spec?['title'];
        return {
          'source': source,
          if (link != null)
            'link': {
              'spreadsheet_uuid': link.spreadsheetItemUuid,
              'chart_id': link.chartObjectId,
              'updated_at': link.updatedAt.toIso8601String(),
              'auto_update': link.autoUpdate,
            },
          'type': spec?['type'],
          'is_3d': (spec?['threeD'] as Map?)?['enabled'] == true,
          'title': title is Map ? title['text'] : title ?? r.name,
          if (full) 'style': SlidesInput.snake(d?['style']),
          if (full) 'camera': SlidesInput.snake(d?['camera']),
        };
      case ElementKind.table:
        final rows = m.axesOf(r.id, TableAxisDimension.row);
        final cols = m.axesOf(r.id, TableAxisDimension.column);
        final cells = {
          for (final c in m.cellsOf(r.id)) '${c.rowId}|${c.columnId}': c,
        };
        return {
          'rows': rows.length,
          'columns': cols.length,
          if (full)
            'cells': [
              for (final row in rows)
                [
                  for (final col in cols)
                    SlidesInput.markdown(m, cells['${row.id}|${col.id}']?.text),
                ],
            ],
          if (full) 'header_row': rows.isNotEmpty && rows.first.header,
        };
      case ElementKind.line:
        return {
          'routing': d?['routing'],
          'connects': [
            for (final end in ['start', 'end'])
              if ((d?[end] as Map?)?['connect']
                  case final Map<Object?, Object?> c)
                {
                  'end': end,
                  'element_id': _decodeB62(c['elementId']),
                  'site': c['site'],
                },
          ],
        };
      case ElementKind.shape:
        return {'geometry': d?['geometry'], 'adjust': ?d?['adjust']};
      case ElementKind.icon:
        return {'set': d?['set'], 'name': ?d?['name'], 'emoji': ?d?['char']};
      default:
        return null;
    }
  }

  static String? _decodeB62(Object? v) {
    if (v is! String) return null;
    return SlidesMcp.canonicalId(v) ?? v;
  }

  /// A build as the MCP `BuildSpec` (+ `build_id`).
  static Map<String, Object?> buildJson(SlideBuildRec b) {
    final options = _json(b.optionsJson) ?? const {};
    return {
      'build_id': b.id,
      'element': b.elementId,
      'kind': SlidesInput.snakeEnum(b.kind.name),
      'effect': b.effect,
      'trigger': SlidesInput.snakeEnum(b.trigger.name),
      'delay_ms': b.delayMs,
      'duration_ms': b.durationMs,
      'easing': b.easing,
      if (options['params'] case final Map<Object?, Object?> p
          when p.isNotEmpty)
        'params': p,
      if (options['delivery'] case final Map<Object?, Object?> d)
        'delivery': SlidesInput.snake(_snakeValues(d)),
      if (options['afterBuild'] case final Map<Object?, Object?> ab)
        'after_build': SlidesInput.snake(ab),
    };
  }

  static Map<dynamic, dynamic> _snakeValues(Map<dynamic, dynamic> d) => {
    for (final e in d.entries)
      e.key: e.value is String && (e.key == 'by' || e.key == 'partTrigger')
          ? SlidesInput.snakeEnum(e.value as String)
          : e.value,
  };

  /// The timeline summary of a slide: clicks, duration and one line per
  /// step ("Click 1: Title — rise").
  static Map<String, Object?> timelineJson(
    DeckModel m,
    String slideId, {
    ResolvedSlide? resolved,
  }) {
    try {
      final tl = SlideTimelineCompiler.compile(
        SlideMotionInput.fromDeck(m, slideId, resolved: resolved),
      );
      String nameOf(String id) {
        final e = m.element(id);
        if (e == null) return id;
        final n =
            e.name ??
            (e.placeholderOf == null
                ? null
                : m.element(e.placeholderOf!)?.name);
        if (n != null && n.isNotEmpty) return n;
        final text = SlidesText.plainText(e.text).trim();
        if (text.isNotEmpty) {
          final first = text.split('\n').first;
          return first.length > 30 ? '${first.substring(0, 29)}…' : first;
        }
        return e.kind.name;
      }

      final lines = <String>[];
      for (final s in tl.steps) {
        if (s.effects.isEmpty) continue;
        final what = {
          for (final e in s.effects) '${nameOf(e.elementId)} — ${e.effectId}',
        }.join(', ');
        lines.add(
          s.index == 0 ? 'Automatically: $what' : 'Click ${s.index}: $what',
        );
      }
      return {
        'steps': tl.stepCount,
        'total_ms': tl.durationMs,
        'summary': lines,
        if (tl.warnings.isNotEmpty)
          'warnings': [for (final w in tl.warnings) w.toString()],
      };
    } on Object catch (e) {
      return {'steps': 0, 'total_ms': 0, 'summary': const [], 'error': '$e'};
    }
  }

  // --------------------------------------------------------- get_element

  static Future<ToolResult> getElement(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.open(ctx, a);
    final m = t.model;
    final id = SlidesMcp.elementId(m, a.values['element']);
    final rec = m.element(id)!;
    final owner = rec.slideId;
    final rs = owner == null ? null : SlideResolver(m).resolve(owner);
    ResolvedElement? find(List<ResolvedElement> list) {
      for (final e in list) {
        if (e.id == id) return e;
        final c = find(e.children);
        if (c != null) return c;
      }
      return null;
    }

    final resolved = rs == null ? null : find(rs.elements);
    if (resolved == null) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Element $id is not on a slide.',
      );
    }
    final json = {
      ...elementJson(
        m,
        resolved,
        format: a.string('text_format') ?? 'markdown',
        overflow: fit(m, rs!),
        fullData: true,
      ),
      'slide_id': owner,
      'position': SlidesMcp.positionOf(m, owner!),
      'builds': [
        for (final b in m.buildsOf(owner))
          if (b.elementId == id) buildJson(b),
      ],
    };
    return ToolResult(json, text: 'Element $id (${rec.kind.name})');
  }

  // ------------------------------------------------------ layouts/themes

  static Future<ToolResult> listLayouts(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.open(ctx, a);
    final theme = a.string('theme_id');
    if (theme != null && t.model.theme(theme) == null) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Theme "$theme" not found (slides.list_themes).',
      );
    }
    final layouts = layoutsJson(t.model, theme ?? t.model.deck?.themeId);
    return ToolResult({
      'layouts': layouts,
    }, text: '${layouts.length} layouts');
  }

  static Future<ToolResult> listThemes(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.open(ctx, a);
    final m = t.model;
    return ToolResult({
      'deck_themes': [
        for (final th in m.themes)
          {..._themeJson(th), 'is_default': th.id == m.deck?.themeId},
      ],
      if (a.boolean('include_builtin') ?? false)
        'builtin': [
          for (final b in BuiltInThemes.all) {'key': b.key, 'name': b.name},
        ],
    }, text: '${m.themes.length} themes');
  }

  // -------------------------------------------------------------- search

  static Future<ToolResult> search(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.open(ctx, a);
    final m = t.model;
    final query = a.requireString('query');
    final where = {
      for (final x in a.list('in') ?? const ['text', 'notes', 'code']) '$x',
    };
    final limit = a.integer('limit') ?? 100;
    final options = DeckFindOptions(
      matchCase: a.boolean('match_case') ?? false,
      wholeWords: a.boolean('whole_word') ?? false,
      useRegex: a.boolean('regex') ?? false,
      includeNotes: where.contains('notes'),
      includeSkipped: true,
    );
    final matches = <Map<String, Object?>>[];
    var total = 0;
    try {
      if (where.contains('text') || where.contains('notes')) {
        for (final x in DeckFind.search(m, query, options)) {
          final isNotes = x.target is NotesText;
          if (!isNotes && !where.contains('text')) continue;
          total++;
          if (matches.length >= limit) continue;
          final body = switch (x.target) {
            ElementText(:final elementId) => m.element(elementId)?.text,
            CellText(:final elementId, :final rowId, :final columnId) =>
              m
                  .cellsOf(elementId)
                  .where((c) => c.rowId == rowId && c.columnId == columnId)
                  .firstOrNull
                  ?.text,
            NotesText(:final slideId) => m.slide(slideId)?.notes,
          };
          matches.add({
            'slide_id': x.slideId,
            'position': SlidesMcp.positionOf(m, x.slideId),
            'element_id': ?x.elementId,
            'in': isNotes ? 'notes' : 'text',
            'text': x.text,
            'context': _context(
              DeckFind.plainOf(body ?? '[]'),
              x.start,
              x.length,
            ),
          });
        }
      }
      if (where.contains('code')) {
        final re = DeckFind.pattern(query, options);
        if (re != null) {
          for (final s in m.slides) {
            for (final e in m.allElementsOf(s.id)) {
              if (e.kind != ElementKind.code) continue;
              for (final st in m.codeStatesOf(e.id)) {
                for (final hit in re.allMatches(st.code)) {
                  total++;
                  if (matches.length >= limit) continue;
                  matches.add({
                    'slide_id': s.id,
                    'position': SlidesMcp.positionOf(m, s.id),
                    'element_id': e.id,
                    'state_id': st.id,
                    'in': 'code',
                    'text': hit.group(0),
                    'context': _context(
                      st.code,
                      hit.start,
                      hit.end - hit.start,
                    ),
                  });
                }
              }
            }
          }
        }
      }
    } on FormatException catch (e) {
      throw SlidesMcp.invalid('Invalid regular expression: ${e.message}');
    }
    return ToolResult({
      'matches': matches,
      'total': total,
      'truncated': total > matches.length,
    }, text: '$total matches');
  }

  static String _context(String text, int start, int length) {
    final from = (start - 40).clamp(0, text.length);
    final to = (start + length + 40).clamp(0, text.length);
    return '${from > 0 ? '…' : ''}${text.substring(from, to)}'
            '${to < text.length ? '…' : ''}'
        .replaceAll('\n', ' ');
  }

  // --------------------------------------------------------- render_slide

  static Future<ToolResult> renderSlide(ToolContext ctx, ToolArgs a) async {
    await SlidesMcp.open(ctx, a);
    throw McpToolException(
      McpErrorCode.unsupported,
      'Rendering slides on the server is not available yet. Use '
      'ui.slides.screenshot_slide with an open presentation window, or '
      'slides.export_pdf.',
    );
  }
}

/// Reads stored chart snapshot columns (`gz:` compressed or plain JSON,
/// `ChartSnapshotColumns` of `wonky_charts`).
abstract final class ChartSnapshotText {
  static String decode(String column) {
    if (!column.startsWith('gz:')) return column;
    try {
      return utf8.decode(gzip.decode(base64Decode(column.substring(3))));
    } on Object {
      return '{}';
    }
  }
}
